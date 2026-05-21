#!/usr/bin/env bash
# probe-payload.sh — Diagnostic hook (NOT registered by default)
# Dumps PreToolUse stdin to .claude/observability/probe-payload.jsonl for schema discovery.
# Wire manually into settings.json hooks.PreToolUse when needed.
# ASD SDK — Diagnostic, exit 0 always.
set -euo pipefail
mkdir -p .claude/observability
INPUT=$(cat)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"raw\":$(echo "$INPUT" | jq -Rs . 2>/dev/null || echo '"jq_error"')}" >> .claude/observability/probe-payload.jsonl
exit 0
