#!/usr/bin/env bash
# Preflight for lark-anybase-report: verify lark-cli is installed and the user identity is valid.
# Read-only skill — this only checks auth; it never touches the source Base.
# Exits 0 when ready, non-zero otherwise (with an actionable message).
set -euo pipefail

# --- locate lark-cli ---------------------------------------------------------
CLI="$(command -v lark-cli || true)"
if [[ -z "$CLI" ]]; then
  for c in "$HOME/bin/lark-cli" "$HOME/.local/bin/lark-cli" lark larksuite; do
    if command -v "$c" >/dev/null 2>&1; then CLI="$(command -v "$c")"; break; fi
    [[ -x "$c" ]] && { CLI="$c"; break; }
  done
fi
if [[ -z "$CLI" ]]; then
  echo "✗ lark-cli not found. Install it and run the lark-cli-setup skill first." >&2
  exit 1
fi
echo "• lark-cli: $CLI ($($CLI --version 2>/dev/null | head -1))"

# --- auth status -------------------------------------------------------------
STATUS_JSON="$("$CLI" auth status --format json 2>/dev/null || "$CLI" auth status 2>/dev/null || true)"
if [[ -z "$STATUS_JSON" ]]; then
  echo "✗ Could not read auth status. Run the lark-cli-setup skill to log in." >&2
  exit 2
fi

token_status=""
user_name=""
if command -v jq >/dev/null 2>&1; then
  token_status="$(printf '%s' "$STATUS_JSON" | jq -r '.identities.user.tokenStatus // empty' 2>/dev/null || true)"
  user_name="$(printf '%s' "$STATUS_JSON" | jq -r '.identities.user.userName // empty' 2>/dev/null || true)"
else
  token_status="$(printf '%s' "$STATUS_JSON" | grep -o '"tokenStatus"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
  user_name="$(printf '%s' "$STATUS_JSON" | grep -o '"userName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
fi

if [[ "$token_status" == "valid" ]]; then
  echo "• user identity: valid${user_name:+ ($user_name)}"
  echo "✓ Preflight OK — ready to read a Base and build the report."
  echo "  Next: ask the user for the Base link, then follow SKILL.md Step 1 (read-only)."
  exit 0
else
  echo "✗ User identity not valid (tokenStatus='${token_status:-unknown}')." >&2
  echo "  Run the lark-cli-setup skill to (re)authenticate, then retry." >&2
  exit 3
fi
