#!/usr/bin/env bash
# ASD SDK v3.17.0 — MCP Health Check Hook
# Reads .mcp.json and verifies each MCP server package can be resolved.
# Logs warnings to .claude/observability/events.jsonl
# Non-blocking: always exits 0.

set -euo pipefail

MCP_FILE=".mcp.json"
OBS_DIR=".claude/observability"

mkdir -p "$OBS_DIR"

# Consume stdin (hook protocol requires it)
INPUT=$(cat)

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Extract session_id for per-session event storage
SESSION_ID="unknown"
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
fi

# Per-session event storage
EVENTS_DIR="$OBS_DIR/events"
mkdir -p "$EVENTS_DIR"
EVENTS_FILE="$EVENTS_DIR/${SESSION_ID}.jsonl"

if [ ! -f "$MCP_FILE" ]; then
  echo "{\"ts\":\"$TS\",\"event\":\"mcp_health_check\",\"session\":\"$SESSION_ID\",\"status\":\"skipped\",\"reason\":\"no .mcp.json found\"}" >> "$EVENTS_FILE"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "{\"ts\":\"$TS\",\"event\":\"mcp_health_check\",\"session\":\"$SESSION_ID\",\"status\":\"skipped\",\"reason\":\"jq not available\"}" >> "$EVENTS_FILE"
  exit 0
fi

# Extract MCP server names and their npx packages
SERVERS=$(jq -r '.mcpServers // {} | keys[]' "$MCP_FILE" 2>/dev/null) || true

if [ -z "$SERVERS" ]; then
  echo "{\"ts\":\"$TS\",\"event\":\"mcp_health_check\",\"session\":\"$SESSION_ID\",\"status\":\"ok\",\"servers_checked\":0}" >> "$EVENTS_FILE"
  exit 0
fi

CHECKED=0
WARNINGS=0

for SERVER in $SERVERS; do
  CHECKED=$((CHECKED + 1))

  # Get the args array, extract the package name (first arg that looks like a package)
  PACKAGE=$(jq -r ".mcpServers[\"$SERVER\"].args[]" "$MCP_FILE" 2>/dev/null \
    | grep -v '^-' \
    | grep -v '^\$' \
    | head -1) || true

  if [ -z "$PACKAGE" ]; then
    continue
  fi

  # Check if the package can be resolved via npm
  if ! npm view "$PACKAGE" version &>/dev/null 2>&1; then
    WARNINGS=$((WARNINGS + 1))
    echo "{\"ts\":\"$TS\",\"event\":\"mcp_health_check\",\"session\":\"$SESSION_ID\",\"status\":\"warning\",\"server\":\"$SERVER\",\"package\":\"$PACKAGE\",\"reason\":\"package not resolvable\"}" >> "$EVENTS_FILE"
  fi
done

echo "{\"ts\":\"$TS\",\"event\":\"mcp_health_check\",\"session\":\"$SESSION_ID\",\"status\":\"done\",\"servers_checked\":$CHECKED,\"warnings\":$WARNINGS}" >> "$EVENTS_FILE"

# Always exit 0 — non-blocking
exit 0
