# Read recipes — verified lark-cli patterns for scanning a Base (read-only)

All commands are `lark-cli …` via Bash. These READ a Base someone shared. **Never** run a
create/update/delete against the source Base — the only writes this skill makes are the final
Doc/message deliverable.

## 0. Resolve the base_token from a URL
A Base URL looks like `https://<tenant>.larksuite.com/base/<base_token>?table=<table_id>&view=<view_id>`.
The segment after `/base/` is the `base_token` (a.k.a. `app_token`). `table=` gives you a starting
`table_id`; still run `+table-list` to see everything.

> **⚠️ JSON paths differ by CLI version — verify before trusting a count.** The paths below are
> confirmed on the current CLI. If a projection/aggregate returns **empty or 0 rows, suspect the
> path first** — do NOT conclude "no data" until you've dumped the raw envelope keys
> (`--jq '.data | keys'` / `--jq '.data | keys'`) and confirmed. An empty result from a wrong path
> looks identical to a genuinely empty table and will silently poison the report. Prefer the
> defensive fallbacks shown here.

## 1. Inventory tables
```bash
lark-cli base +table-list --base-token "$BASE" --format json \
  --jq '.data.tables[] | {id: (.id // .table_id), name}'
```
- The id key is **`.id`** on the current CLI (older docs say `.table_id`). Fallback covers both.

## 2. Read the schema of a table
```bash
lark-cli base +field-list --base-token "$BASE" --table-id "$TID" --format json \
  --jq '(.data.fields // .data.items)[] | {name, type, ui_type}'
```
- Fields live under **`.data.fields[]`** (not `.data.items[]`). Each item: `{id, name, type, ui_type?, options?}`.
- If unsure, dump keys first: `--jq '.data | keys'`.

Field-type cheatsheet you'll see (**note: record values are positional — see §3**):
- `number` — may be currency/percent; **the unit is not in the value**. Check the field's `ui_type`
  / property for currency & precision, and ask the user the unit if it matters.
- `formula` / `lookup` — the record output already contains the **computed value**, so you can read
  it directly. BUT a filter on a formula/lookup **date** often can't be pushed to the server (see §4);
  filter those in memory.
- `datetime` — value is a **string** like `"2026-06-01 13:00:00"` (NOT an epoch integer on this CLI).
  Compare as a date string, or slice the `YYYY-MM-DD` prefix. Filter operators are restricted (§4).
- `select` / `multiSelect` — value is an **array** of option name(s), e.g. `["Active"]`; take `.[0]`
  (or join for multi). Good for segmentation.
- `link` — array of `{id}` objects (linked record ids); count them or resolve across if needed.
- `user` — array of `{id, name}`; use `.name` for "by owner" breakdowns.
- `checkbox` — boolean.

## 3. List records — projection + pagination (the core loop)
> **⚠️ Rows are POSITIONAL arrays, not named objects.** `record-list` returns rows under
> **`.data.data[]`**, and each row is an **array of values in the exact order you passed `--field-id`**
> (or the `.field_id_list` / `.fields` order when you don't project). There are no field names on the
> values — you map by **index**. This is the single biggest footgun: always pass `--field-id` in a
> known order and read by position.

Project only the fields you mapped, in a fixed order, to keep output small and aligned:
```bash
lark-cli base +record-list --base-token "$BASE" --table-id "$TID" \
  --field-id "Revenue" --field-id "Region" --field-id "Close Date" --field-id "Status" \
  --format json --limit 200 --offset 0 --jq '.data.data'
# → [ [<Revenue>, ["<Region>"], "<Close Date>", ["<Status>"]], ... ]   (index 0..3 = the order above)
```
- Rows path is **`.data.data`** (defensive: `.data.data // .data.records // .data.items`). The
  envelope also has `.data.has_more` (bool) and `.fields` (column meta) but **no `.data.total`** —
  don't count with `.data.total` (it's null); count with `(.data.data|length)`.
- `--limit` max is **200**. No `--page-all` — loop `--offset` in steps of `--limit` until a page
  returns **fewer** than `--limit` rows (or `.data.has_more == false`).
- `--field-id` takes a field **name or id**; repeat it per field, and remember the order = the index.

Pagination loop (bash sketch):
```bash
OFFSET=0; LIMIT=200
while :; do
  PAGE="$(lark-cli base +record-list --base-token "$BASE" --table-id "$TID" \
      --field-id Revenue --field-id Region --field-id "Close Date" \
      --format json --limit $LIMIT --offset $OFFSET --jq '.data.data // .data.records // .data.items')"
  N="$(printf '%s' "$PAGE" | jq 'length')"
  # …accumulate PAGE… (parse each row by index: .[0]=Revenue, .[1]=Region, …)
  [ "$N" -lt "$LIMIT" ] && break
  OFFSET=$((OFFSET+LIMIT))
done
```
If the very first page is empty, re-check the rows path (`--jq '.data | keys'`) before assuming the
table is empty (see the warning at the top of this file).

## 4. Filtering by time window (server-side when possible)
> **⚠️ `datetime` fields accept ONLY these operators: `==`, `>`, `<`, `empty`, `non_empty`.**
> `>=` / `<=` return API error `800010506` ("Use one of these operators: ==, >, <, empty, non_empty").
> Build an inclusive range with the **exclusive** operators on the boundary days:
```bash
# Q3 2026 = 2026-07-01 .. 2026-09-30 inclusive  →  > the day BEFORE, < the day AFTER
--filter-json '{"logic":"and","conditions":[
  ["Close Date",">","ExactDate(2026-06-30)"],
  ["Close Date","<","ExactDate(2026-10-01)"]]}'
```
Filter shapes (from record-list help):
- Text equals: `["Title","==","Launch plan"]`
- Text contains: `["Title","intersects","urgent"]`
- Number: `["Score","==",95]` (numbers DO support `>`, `>=`, `<`, `<=`)
- Date exact: `["Due","==","ExactDate(2026-06-02)"]` · Date range: use `>` / `<` only (see above)
- Option in set: `["Tags","intersects",["P0","Blocked"]]`

> **Tip:** when a genuine range returns 0 rows, the data may simply be outside the window (e.g. an
> actuals/snapshot table that stops at last month). Confirm by dumping the field's min/max
> (`--jq '[.data.data[][<idx>]] | {min:min, max:max}'`) before reporting "nothing in the period".

**When you CANNOT push to the server** — filter in memory after fetching:
- The date lives in a **formula/lookup** field (server filter/sort on those is unreliable).
- A **dynamic** window like "last 30 days" relative to today — fetch, then compare epochs in code.
- Cross-field or computed conditions the filter grammar can't express.

## 5. Optional: read a user-defined view instead of the whole table
If the shared link points at a filtered/sorted view and the user wants exactly that slice:
```bash
lark-cli base +record-list --base-token "$BASE" --table-id "$TID" --view-id "$VIEW" --format json --jq '.data'
```
`--filter-json` / `--sort-json` override the view's own filter/sort if you also pass them.

## 6. Sorting (for top/bottom outliers)
```bash
--sort-json '[{"field":"Revenue","desc":true}]'   # priority follows array order; max 10
```

## 7. Sanity checks before you trust a number
- Count empty cells in each mapped field (`null`/`""`) — report the fill rate if it's low.
- Watch mixed units / currencies in one number column.
- A `formula` that aggregates across a link can be stale or return list-like values — spot-check a
  couple of rows against the Base UI if a number looks off.
- Record the exact **row count scanned** and the **time window applied**; both go in the caveats.
