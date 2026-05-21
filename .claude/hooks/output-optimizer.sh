#!/usr/bin/env bash
# ASD SDK — Output Optimizer Hook (PreToolUse matcher: Bash)
# Wraps safe verbose commands with asd-optimize to compress output and save tokens.
#
# Behavior:
#   - SAFE commands (ls, find, tree, etc.) → wrap with asd-optimize
#   - CRITICAL commands (git, npm test, tsc, etc.) → passthrough silently
#   - Already wrapped with asd-optimize → skip (no double-wrap)
#   - Unknown commands → passthrough silently (conservative)
#
# This hook NEVER blocks (exit 0 always). It only modifies input for safe commands.

set -euo pipefail

OBS_DIR=".claude/observability"
EVENTS_FILE="$OBS_DIR/events.jsonl"

mkdir -p "$OBS_DIR"

# ─── Read stdin ───────────────────────────────────────────────────────────────
INPUT=$(cat)

# ─── Graceful fallback if jq not available ────────────────────────────────────
if ! command -v jq &>/dev/null; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$TS\",\"event\":\"output_optimizer\",\"status\":\"skip_no_jq\"}" >> "$EVENTS_FILE"
  exit 0
fi

# ─── Extract command from tool_input ──────────────────────────────────────────
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# ─── Skip if already wrapped with asd-optimize ───────────────────────────────
if echo "$COMMAND" | grep -q '^asd-optimize\b\|^npx ts-node bin/asd-optimize.ts\b'; then
  exit 0
fi

# ─── Extract the base command (first word, handle env vars and paths) ─────────
# Strip leading env assignments (VAR=val), sudo, and get the actual command
BASE_CMD=$(echo "$COMMAND" | sed 's/^[A-Z_]*=[^ ]* *//g' | sed 's/^sudo *//' | awk '{print $1}')
# Get just the basename in case of full path
BASE_CMD=$(basename "$BASE_CMD" 2>/dev/null || echo "$BASE_CMD")

# ─── Classification ──────────────────────────────────────────────────────────

# CRITICAL: never wrap these — output format matters or command is destructive
# Check full command string for multi-word critical patterns first
CRITICAL_PATTERNS="npm test|npx vitest|npx jest|npx ts-node|ts-node|--json"
if echo "$COMMAND" | grep -qE "(${CRITICAL_PATTERNS})"; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$TS\",\"event\":\"output_optimizer\",\"status\":\"critical_skip\",\"base_cmd\":\"$BASE_CMD\"}" >> "$EVENTS_FILE"
  exit 0
fi

# CRITICAL single-word commands
case "$BASE_CMD" in
  git|npm|npx|tsc|eslint|prettier|jq|node|ts-node)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "{\"ts\":\"$TS\",\"event\":\"output_optimizer\",\"status\":\"critical_skip\",\"base_cmd\":\"$BASE_CMD\"}" >> "$EVENTS_FILE"
    exit 0
    ;;
esac

# SAFE: commands that produce verbose, compressible output
case "$BASE_CMD" in
  ls|find|tree|cat|head|tail|grep|rg|ag|docker|kubectl|aws)
    # For docker/kubectl, only optimize read-only subcommands
    case "$BASE_CMD" in
      docker)
        SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
        case "$SUBCMD" in
          ps|images|logs|inspect) ;; # safe
          *) exit 0 ;; # not safe, passthrough
        esac
        ;;
      kubectl)
        SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
        case "$SUBCMD" in
          get|describe|logs) ;; # safe
          *) exit 0 ;; # not safe, passthrough
        esac
        ;;
    esac

    # ─── Wrap with asd-optimize ─────────────────────────────────────────────
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "{\"ts\":\"$TS\",\"event\":\"output_optimizer\",\"status\":\"wrapped\",\"base_cmd\":\"$BASE_CMD\"}" >> "$EVENTS_FILE"

    # Escape command for JSON
    ESCAPED_CMD=$(echo "$COMMAND" | jq -Rs .)
    # Remove surrounding quotes from jq output for embedding
    ESCAPED_CMD=${ESCAPED_CMD:1:${#ESCAPED_CMD}-2}

    cat <<HOOK_OUTPUT
{
  "decision": "allow",
  "updatedInput": {
    "command": "npx ts-node bin/asd-optimize.ts ${ESCAPED_CMD}"
  }
}
HOOK_OUTPUT
    exit 0
    ;;
esac

# ─── UNKNOWN: passthrough silently ────────────────────────────────────────────
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"event\":\"output_optimizer\",\"status\":\"unknown_skip\",\"base_cmd\":\"$BASE_CMD\"}" >> "$EVENTS_FILE"
exit 0
