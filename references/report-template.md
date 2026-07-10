# Report template

Fill this in the user's language. Keep it tight — insight over volume. Drop sections that don't
apply, but **never** drop "Caveats & coverage".

---

# <Base / topic> — Insight Report
*<time window> · <N> records scanned · generated <date>*

## 1. Executive summary
- **<KPI 1>:** <number> — <so what: comparison / trend / risk>.
- **<KPI 2>:** <number> — <so what>.
- **<KPI 3>:** <number> — <so what>.
- *(3–5 bullets max. Each = a number + why it matters. Lead with the answer to the user's question.)*

## 2. Headline metrics
| Metric | Value | vs. target / prior period | Note |
|---|---:|---:|---|
| <e.g. Revenue> | <value> | <+/- %> | |
| <e.g. Deals closed> | <value> | <+/- %> | |
| <e.g. Avg deal size> | <value> | | |

## 3. Breakdown — by <segment dimension>
| <Segment> | <Metric> | Share | <Metric 2> |
|---|---:|---:|---:|
| <A> | | | |
| <B> | | | |
| **Total** | | 100% | |

## 4. What stands out
- **Outlier:** <the one row / segment far from the rest>.
- **Trend:** <up/down over the window>.
- **Red flag:** <overdue / churn / stalled / data gap>.

## 5. Next-step direction
1. **<Do this first>** — <why, tied to the KPI / risk above>.
2. **<Then this>** — <why>.
3. **<Watch / investigate>** — <the thing that needs a human decision>.

## 6. Caveats & coverage
- **Scanned:** <N> records from table `<name>`; time window **<window>**.
- **Field mapping:** <KPI> ← `<field>`; date ← `<field>`; segment ← `<field>`.
- **Unmapped / uncertain:** <any ask with no clean field, or low fill-rate column>.
- **Formula/lookup fields:** values read as computed; not independently recomputed.
- **Units:** <currency / percent assumptions>.
