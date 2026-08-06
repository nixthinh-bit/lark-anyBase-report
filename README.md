# lark-anyBase-report

## 🚀 Install — paste this one line into Claude Code

**English:**
```
Install the lark-anybase-report skill from https://github.com/nixthinh-bit/lark-anyBase-report — clone it to ~/.claude/skills/lark-anybase-report, confirm SKILL.md exists, then remind me to restart the session. It's triggered with /lark-anybase-report.
```

**Tiếng Việt:**
```
Cài skill lark-anybase-report từ https://github.com/nixthinh-bit/lark-anyBase-report vào ~/.claude/skills/lark-anybase-report giúp mình, kiểm tra SKILL.md đã có chưa rồi nhắc mình khởi động lại phiên. Kích hoạt bằng /lark-anybase-report.
```

Restart the session after it's done, then run `/lark-anybase-report`. Requires `lark-cli` installed
and authenticated (user identity) — see [Requirements](#requirements) below if you don't have it yet.

---

A Claude Code skill that turns **any Lark (Feishu) Base someone hands you** into a focused **insight
report** — but interviews you first so it reports on what *you* actually care about, not a generic
data dump.

> Trigger: **`/lark-anybase-report`** · Bilingual EN/VI · Read-only on the source Base

## What it does

1. **Preflight** — checks your `lark-cli` login.
2. **Inventory** — you paste a Base link; it lists the tables.
3. **Interview** — it asks the questions that shape a report: your **KPI/goal**, the **concern**
   you're worried about, your **priorities**, which **metrics** to focus on, the **time window**, how
   to **segment**, the **audience/depth**, and how you want it **delivered**.
4. **Map & confirm** — reads the real schema and shows you which field feeds each number, so a wrong
   guess ("which column is revenue?") gets caught before any math.
5. **Scan** — reads the data **read-only**, paginated, with your time filter applied.
6. **Draft & approve** — shows the report (summary → headline metrics → breakdown → what stands out
   → next steps → caveats) for your review.
7. **Deliver** — publishes as a **new Lark Doc** or sends a **direct Lark message**.

## Why "interview first"

A Base holds hundreds of numbers; only a few answer your question this week. Most reporting tools
scan-and-dump. This one gets the question first, maps it onto your real fields, confirms, then
computes — and every number in the output carries a "so what" plus a concrete next step.

## Safety

- **Read-only on the source Base.** It never creates, edits, or deletes anything in the Base you
  share. The only things it writes are the deliverable: a new Doc, or a message.
- **Lark access only via `lark-cli`.** No browser scraping of Lark URLs.
- It always tells you how many rows it scanned, the time window it used, and any field it couldn't
  confidently map.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- `lark-cli` installed and authenticated. First time? Run the **lark-cli-setup** skill.

## Install

Easiest: use the one-line Claude Code message at the top of this README. To run it yourself in a
terminal instead:
```bash
git clone https://github.com/nixthinh-bit/lark-anyBase-report.git ~/.claude/skills/lark-anybase-report
```
Restart the Claude Code session, then run `/lark-anybase-report`. Full details (plugin install,
verify script) in [INSTALL.md](INSTALL.md).

## Repo layout

```
SKILL.md                       the skill (English; loaded at runtime)
SKILL.vi.md                    Vietnamese mirror for human readers
references/read-recipes.md     verified lark-cli read patterns + field-type gotchas
references/report-template.md  the report structure it fills
scripts/preflight.sh           auth check
```

## License

MIT — see [LICENSE](LICENSE).
