#!/usr/bin/env bash
# ASD SDK v3.17.0 — CLAUDE.md Budget Enforcement Hook (PreToolUse matcher: Edit|Write)
# Monitors CLAUDE.md size to prevent token budget overflow.
#
# Behavior:
#   - tokens < WARNING (2500)  → allow silently (exit 0)
#   - tokens >= WARNING (2500) → allow + log warning to events
#   - tokens >= CRITICAL (3000) → DENY with JSON reason
#
# Token estimation: word_count * 1.3 (conservative approximation)

set -euo pipefail

OBS_DIR=".claude/observability"
CLAUDE_MD=".claude/CLAUDE.md"
EVENTS_FILE="$OBS_DIR/events.jsonl"
WARNING_THRESHOLD=2500
CRITICAL_THRESHOLD=3000

mkdir -p "$OBS_DIR"

# ─── Read stdin (PreToolUse payload) ─────────────────────────────────────────
INPUT=$(cat 2>/dev/null || echo "{}")

# ─── Extract file_path from tool input ───────────────────────────────────────
# Graceful fallback: if jq not available, allow silently
if ! command -v jq &>/dev/null; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

# ─── Only apply to CLAUDE.md edits ───────────────────────────────────────────
if [[ "$FILE_PATH" != *"CLAUDE.md"* ]]; then
  exit 0
fi

# ─── Graceful fallback: if CLAUDE.md does not exist, allow ───────────────────
if [ ! -f "$CLAUDE_MD" ]; then
  exit 0
fi

# ─── Count words and estimate tokens ─────────────────────────────────────────
WORD_COUNT=$(wc -w < "$CLAUDE_MD" 2>/dev/null || echo "0")
# Trim any leading whitespace from wc output
WORD_COUNT=$(echo "$WORD_COUNT" | tr -d ' ')

# Estimate tokens: words * 1.3 using integer math (words * 13 / 10)
ESTIMATED_TOKENS=$(( WORD_COUNT * 13 / 10 ))

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Evaluate against thresholds ─────────────────────────────────────────────
if [ "$ESTIMATED_TOKENS" -ge "$CRITICAL_THRESHOLD" ]; then
  # CRITICAL: deny
  echo "{\"ts\":\"$TS\",\"event\":\"claudemd_budget_critical\",\"estimated_tokens\":$ESTIMATED_TOKENS,\"threshold\":$CRITICAL_THRESHOLD}" >> "$EVENTS_FILE"

  cat <<HOOK_OUTPUT
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "CLAUDE.md budget exceeded: ~${ESTIMATED_TOKENS} tokens (limit: ${CRITICAL_THRESHOLD}). Externalize sections to .claude/docs/ before adding content."
  }
}
HOOK_OUTPUT

elif [ "$ESTIMATED_TOKENS" -ge "$WARNING_THRESHOLD" ]; then
  # WARNING: allow + log
  echo "{\"ts\":\"$TS\",\"event\":\"claudemd_budget_warning\",\"estimated_tokens\":$ESTIMATED_TOKENS,\"threshold\":$WARNING_THRESHOLD}" >> "$EVENTS_FILE"
fi

# GREEN zone or WARNING zone (allow)
exit 0
