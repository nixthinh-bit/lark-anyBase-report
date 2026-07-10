# Install

## As a personal Claude Code skill

```bash
git clone https://github.com/nixthinh-bit/lark-anyBase-report.git
mkdir -p ~/.claude/skills
cp -R lark-anyBase-report ~/.claude/skills/lark-anybase-report
chmod +x ~/.claude/skills/lark-anybase-report/scripts/preflight.sh
```

Then in Claude Code:

```
/lark-anybase-report
```

## As part of a plugin

Drop this folder under your plugin's `skills/` directory:

```
your-plugin/
  skills/
    lark-anybase-report/
      SKILL.md
      references/
      scripts/
```

At runtime the skill resolves `SKILL_DIR` to its own folder
(`${CLAUDE_PLUGIN_ROOT}/skills/lark-anybase-report`), so the scripts and references are found either
way.

## Prerequisites

- **lark-cli** installed and logged in (user identity). If `scripts/preflight.sh` reports "not valid",
  run the **lark-cli-setup** skill to authenticate.
- **jq** recommended (the preflight and read loops degrade gracefully without it, but jq makes
  parsing record output much easier).

## Verify

```bash
bash ~/.claude/skills/lark-anybase-report/scripts/preflight.sh
```

Expected: `✓ Preflight OK — ready to read a Base and build the report.`
