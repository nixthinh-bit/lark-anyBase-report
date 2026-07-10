# Read recipes — verified lark-cli patterns for scanning a Base (read-only)

All commands are `lark-cli …` via Bash. These READ a Base someone shared. **Never** run a
create/update/delete against the source Base — the only writes this skill makes are the final
Doc/message deliverable.

## 0. Resolve the base_token from a URL
A Base URL looks like `https://<tenant>.larksuite.com/base/<base_token>?table=<table_id>&view=<view_id>`.
The segment after `/base/` is the `base_token` (a.k.a. `app_token`). `table=` gives you a starting
`table_id`; still run `+table-list` to see everything.

## 1. Inventory tables
```bash
lark-cli base +table-list --base-token "$BASE" --format json --jq '.data.tables[] | {table_id, name}'
```

## 2. Read the schema of a table
```bash
lark-cli base +field-list --base-token "$BASE" --table-id "$TID" --format json \
  --jq '.data.items[] | {name, type, ui_type}'
```
Field-type cheatsheet you'll see:
- `number` — may be currency/percent; **the unit is not in the value**. Check the field's `ui_type`
  / property for currency & precision, and ask the user the unit if it matters.
- `formula` / `lookup` — the record output already contains the **computed value**, so you can read
  it directly. BUT a filter on a formula/lookup **date** often can't be pushed to the server (see §4);
  filter those in memory.
- `datetime` — value is an epoch **milliseconds** integer in JSON. Convert before comparing.
- `select` / `multiSelect` — option name(s); good for segmentation.
- `link` — array of linked record ids/names; count them or look up across if needed.
- `user` — array of {id, name}; use `.name` for "by owner" breakdowns.
- `checkbox` — boolean.

## 3. List records — projection + pagination (the core loop)
Project only the fields you mapped to keep output small and aligned:
```bash
lark-cli base +record-list --base-token "$BASE" --table-id "$TID" \
  --field-id "Revenue" --field-id "Region" --field-id "Close Date" --field-id "Status" \
  --format json --limit 200 --offset 0 --jq '.data'
```
- `--limit` max is **200**. There is no `--page-all` for record-list — loop yourself:
  set `--offset 0`, then `200`, then `400`… stop when a page returns **fewer** than `--limit` rows.
- `--field-id` takes a field **name or id**; repeat it per field.
- Default output is `markdown`; always pass `--format json` for parsing. The JSON envelope puts rows
  under `.data.data` (or `.data.items` depending on CLI version — check both) and may include a
  truncated `.data.fields`. Use `--jq` to grab exactly the rows.

Pagination loop (bash sketch):
```bash
OFFSET=0; LIMIT=200
while :; do
  PAGE="$(lark-cli base +record-list --base-token "$BASE" --table-id "$TID" \
      --field-id Revenue --field-id Region --field-id "Close Date" \
      --format json --limit $LIMIT --offset $OFFSET --jq '.data.records // .data.items // .data.data')"
  N="$(printf '%s' "$PAGE" | jq 'length')"
  # …accumulate PAGE…
  [ "$N" -lt "$LIMIT" ] && break
  OFFSET=$((OFFSET+LIMIT))
done
```
(Confirm the actual rows path from a first `--jq '.data'` dump; CLI versions differ.)

## 4. Filtering by time window (server-side when possible)
Push the date filter to the server when the date field is a real `datetime` (not a formula/lookup):
```bash
--filter-json '{"logic":"and","conditions":[
  ["Close Date",">=","ExactDate(2026-04-01)"],
  ["Close Date","<=","ExactDate(2026-06-30)"]]}'
```
Filter shapes (from record-list help):
- Text equals: `["Title","==","Launch plan"]`
- Text contains: `["Title","intersects","urgent"]`
- Number: `["Score","==",95]` (also `>`, `>=`, `<`, `<=`)
- Date exact: `["Due","==","ExactDate(2026-06-02)"]`
- Option in set: `["Tags","intersects",["P0","Blocked"]]`

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
