---
name: lark-anybase-report
description: Read ANY Lark (Feishu) Base someone hands you, scan the data, and produce an insight report with clear next-step direction — but interview the user FIRST to pin down what they actually need (KPIs, concerns, priorities, which metrics, time window, audience). Never guesses what "good" means: it asks for the goal, maps the ask onto the real schema, confirms the mapping, scans read-only, then delivers a reviewed report either as a new Lark Doc or as a direct Lark message. Bilingual EN/VI; replies in the user's language. Trigger with /lark-anybase-report.
---

# Lark AnyBase Report — from a shared Base to an insight report

> **⚠️ TOOL RULE (mandatory):** Read every Lark resource through `lark-cli` via Bash.
> Never use WebFetch / a browser on a Lark URL — they lack the auth `lark-cli` has and just return
> a login page. All Base/Doc/message operations go through `lark-cli base … / docs … / im …`.

> **⚠️ READ-ONLY on the user's Base.** This Base belongs to whoever shared it. This skill NEVER
> creates, updates, or deletes records, fields, tables, or views in the source Base. It only reads.
> The *only* writes it performs are the final deliverable: a **new** Lark Doc, or a Lark **message**.

`SKILL_DIR` = the folder containing this SKILL.md (usually `~/.claude/skills/lark-anybase-report`,
or `${CLAUDE_PLUGIN_ROOT}/skills/lark-anybase-report` as a plugin). Run scripts from there.

## Language
Reply and write every deliverable in **the language the user is using** — detect it and mirror it.
If unclear, ask once. Internal reasoning and `lark-cli` commands stay as-is. The repo ships bilingual:
`SKILL.md` (English) + `SKILL.vi.md` (Vietnamese, for human readers); at runtime always load
`SKILL.md` and just respond in the user's language.

## Design philosophy (why this skill exists)
1. **Intent before data.** A Base has hundreds of numbers; only a few matter to *this* user right
   now. Do NOT scan-and-dump. Interview first: KPI, worry, priority, focus metrics, time window,
   audience. A report answers a question — get the question first.
2. **Map the ask onto the *real* schema, then confirm.** Field names are the user's, often
   ambiguous or in Vietnamese. Never assume which field is "revenue" or "the date". Read the schema,
   propose the mapping (ask → field), and get a quick yes before computing.
3. **Read-only, always.** You are a guest in someone's Base. Compute in memory; never write back.
4. **Insight, not a data dump.** Every number must carry a "so what": a comparison, a trend, an
   outlier, a risk. End with concrete next-step direction, not just tables.
5. **Show the draft before you publish.** Numbers off a stranger's Base can be wrong (formula
   fields, empty cells, mixed units). Present the draft for approval; only then create the Doc / send
   the message.
6. **Be honest about coverage.** State the row count scanned, the time window applied, and any field
   you couldn't confidently map. A caveats section is mandatory.

---

## Workflow (7 steps)

### Step 0 — Preflight
```bash
bash "$SKILL_DIR/scripts/preflight.sh"
```
Verifies `lark-cli` is installed and `identities.user.tokenStatus == valid`. If it reports "not
logged in / not valid", tell the user to run the **lark-cli-setup** skill, then stop.

### Step 1 — Get the Base and inventory its tables
Ask the user for the **Base link** (or `base_token`). Resolve the token from the URL
(`.../base/<base_token>?table=<table_id>&view=<view_id>` — the `base` segment is the token). Then:
```bash
BASE="<base_token>"
lark-cli base +table-list --base-token "$BASE" --format json \
  --jq '.data.tables[] | {id: (.id // .table_id), name}'   # id key is .id on current CLI
```
Show the table list. If there are several, ask which table(s) are in scope — or infer the obvious
main one and confirm. Capture each `table_id` you'll use.

### Step 2 — INTERVIEW the user (the differentiator — do this BEFORE scanning)
Ask a focused set (use `AskUserQuestion` for the crisp choices; free-text for the rest). Cover:
- **Goal / KPI** — what is the one question this report must answer? What KPI defines success?
- **Concern** — what problem or risk are they worried about right now?
- **Priority** — if only three numbers made it onto one screen, which three?
- **Focus metrics** — revenue, count, conversion, overdue, churn, growth %, averages…?
- **Time window** — all-time, this month/quarter, last N days, a custom range, or period-over-period?
- **Audience & depth** — a quick pulse-check for themselves, or a formal report for their boss/team?
- **Segmentation** — break down by which dimension (region, owner, product, status, month)?
- **Delivery** — a **Lark Doc** (shareable, keeps tables/headings) or a **direct Lark message**
  (fast, lands in chat)? (Decide the exact target in Step 6.)

Do NOT proceed until the goal, focus metrics, and time window are clear. Summarize what you heard in
one or two lines and let the user correct it.

### Step 3 — Read the schema & map the ask onto real fields
For each in-scope table:
```bash
lark-cli base +field-list --base-token "$BASE" --table-id "$TID" --format json \
  --jq '(.data.fields // .data.items)[] | {name, type, ui_type}'   # fields live under .data.fields
```
Classify fields by type (number/currency, select, datetime, checkbox, link, formula, lookup, user,
text). Then build the **mapping table** — for each thing the user asked for, name the exact field
that supplies it, plus the date field for the time window and the field to segment by. Show it:

| User's ask | Source field | Field type | Note |
|---|---|---|---|
| Revenue | `Thành tiền` | formula (number) | computed per row |
| Time window (this quarter) | `Ngày chốt` | datetime | filter applied here |
| Segment by | `Khu vực` | select | 4 options |

Flag anything you couldn't map (no obvious field, or two candidates). **Get a quick confirmation**
before scanning — a wrong field mapping poisons every number. See `references/read-recipes.md` for
field-type gotchas (formula/lookup values, empty cells, currency units).

### Step 4 — Scan the data (read-only, paginated)
Read only the fields you mapped (keep payloads small), and apply the time window as a server-side
filter when the date field allows it:
```bash
# projection + filter + pagination; loop offset until a page returns < limit
# ⚠️ rows come back at .data.data as POSITIONAL arrays in --field-id order (map by index, not name)
# ⚠️ datetime accepts only == > < empty non_empty — build a range with > (day before) and < (day after)
lark-cli base +record-list --base-token "$BASE" --table-id "$TID" \
  --field-id "Thành tiền" --field-id "Khu vực" --field-id "Ngày chốt" --field-id "Trạng thái" \
  --filter-json '{"logic":"and","conditions":[["Ngày chốt",">","ExactDate(2026-03-31)"],["Ngày chốt","<","ExactDate(2026-07-01)"]]}' \
  --format json --limit 200 --offset 0 --jq '.data.data'
```
Paginate with `--offset` in steps of `--limit` (max **200**) until a page returns fewer rows than
the limit. **If a page is empty, suspect the JSON path (`.data.data`) before concluding "no data"** —
a wrong path returns empty and silently poisons the report. See `references/read-recipes.md` for the
exact loop, the positional-row parsing, the datetime operator rule, and when a filter can't be pushed
to the server (formula/lookup date, dynamic "last N days") — then filter in memory.
Compute the metrics the user asked for: totals, averages, counts, rates, the segment breakdown,
period-over-period deltas, and top/bottom outliers. Record the **row count actually scanned**.

**Guardrails:** if the table is very large, cap the scan (e.g. 2–5k rows), tell the user, and offer
to narrow by view or filter. Never modify the Base.

### Step 5 — Build the report and SHOW THE DRAFT (approval gate)
Assemble the report using `references/report-template.md`. Structure:
1. **Executive summary** — 3–5 bullets, each an insight tied to a KPI (number + "so what").
2. **Headline metrics** — a small table (metric · value · vs. target/prior period).
3. **Breakdown** — the segmentation the user asked for.
4. **What stands out** — outliers, anomalies, red flags, notable trends.
5. **Next-step direction** — concrete, prioritized recommendations ("focus here because…").
6. **Caveats & coverage** — rows scanned, time window, any unmapped/low-quality field, formula-field
   note. Never hide uncertainty.

Print the draft in the conversation and ask the user to confirm or adjust **before** publishing.

### Step 6 — Deliver (only after approval)
Ask (or reuse the Step 2 answer) which delivery the user wants, then:

**A) Lark Doc** — shareable, preserves headings/tables:
```bash
lark-cli docs +create --title "<report title>" --markdown @/path/to/report.md \
  [--folder-token <folder_token>] --format json --jq '.data'
```
Write the report to a temp `.md` first, then pass it with `--markdown @file`. Report the Doc URL.

**B) Direct Lark message** — lands in a chat/DM:
```bash
# to a group by name → find the chat_id, then send
lark-cli im +chat-search --query "<group name>" --format json --jq '.data'
lark-cli im +messages-send --chat-id "<oc_...>" --markdown @/path/to/report.md --format json
# or DM a person by open_id
lark-cli im +messages-send --user-id "<ou_...>" --markdown @/path/to/report.md --format json
```
`--markdown` auto-wraps as a Feishu post. If the user wants the message sent to themselves, ask for
the target (their `ou_` open_id, or a group they're in via `+chat-search`) — don't guess a recipient.
For a long report, prefer the Doc and send a short message with the Doc link.

### Step 7 — Wrap up
Give the user: the deliverable link (Doc URL or "sent to <chat>"), the headline numbers, the row
count + time window scanned, and the top next step. Offer a follow-up (deeper cut, another segment,
schedule it weekly via the `schedule` skill).

---

## Guardrails recap
- **Never** write to the source Base. Read-only. The only writes are the Doc / message deliverable.
- **Never** invent field names — always `+field-list` first and map explicitly.
- **Never** use WebFetch/browser on Lark URLs — only `lark-cli`.
- Interview before scanning; map-and-confirm before computing; draft-and-approve before publishing.
- Always state rows scanned, time window, and unmapped fields. Uncertainty is disclosed, not hidden.
