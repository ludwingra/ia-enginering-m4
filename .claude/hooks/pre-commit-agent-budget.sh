#!/usr/bin/env bash
# ASD SDK v3.16.0 — Agent Description Budget Hook
# Validates agent description lengths before commits touching agents/
# Checks both .claude/agents/ and templates/agents/ directories
# Blocks if per-agent >300 chars or cumulative >12,000 tokens
# Bypass: SKIP_AGENT_BUDGET=1 git commit ...

set -euo pipefail

if [ "${SKIP_AGENT_BUDGET:-0}" = "1" ]; then
  echo "[agent-budget] Skipped (SKIP_AGENT_BUDGET=1)"
  exit 0
fi

PER_AGENT_LIMIT=300
CUMULATIVE_TOKEN_LIMIT=12000

# check_dir <directory> <label>
# Returns 0 on pass, 1 on fail. Prints results to stdout.
check_dir() {
  local dir="$1"
  local label="$2"
  local total_chars=0
  local over_limit=()
  local errors=0

  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue

    local desc=""
    local in_frontmatter=0
    local found_desc=0

    while IFS= read -r line; do
      if [ "$in_frontmatter" -eq 0 ] && [ "$line" = "---" ]; then
        in_frontmatter=1
        continue
      fi
      if [ "$in_frontmatter" -eq 1 ] && [ "$line" = "---" ]; then
        break
      fi
      if [ "$in_frontmatter" -eq 1 ] && [ "$found_desc" -eq 0 ]; then
        case "$line" in
          description:*)
            desc="${line#description:}"
            desc="${desc# }"
            desc="${desc#\"}"
            desc="${desc%\"}"
            found_desc=1
            ;;
        esac
      fi
    done < "$f"

    local chars=${#desc}
    total_chars=$((total_chars + chars))

    if [ "$chars" -gt "$PER_AGENT_LIMIT" ]; then
      local agent_name
      agent_name=$(basename "$f" .md)
      over_limit+=("$agent_name ($chars chars)")
    fi
  done

  local total_tokens=$((total_chars / 4))

  if [ ${#over_limit[@]} -gt 0 ]; then
    echo "[agent-budget] FAIL ($label): ${#over_limit[@]} agent(s) exceed ${PER_AGENT_LIMIT} char limit:"
    for item in "${over_limit[@]}"; do
      echo "  - $item"
    done
    errors=1
  fi

  if [ "$total_tokens" -gt "$CUMULATIVE_TOKEN_LIMIT" ]; then
    echo "[agent-budget] FAIL ($label): Cumulative tokens ${total_tokens} exceed limit ${CUMULATIVE_TOKEN_LIMIT}"
    errors=1
  fi

  if [ "$errors" -eq 0 ]; then
    echo "[agent-budget] PASS ($label): ${total_tokens} tokens (limit: ${CUMULATIVE_TOKEN_LIMIT})"
  fi

  return "$errors"
}

global_errors=0

# Check .claude/agents/ (project agents)
if [ -d ".claude/agents" ]; then
  if ! check_dir ".claude/agents" ".claude/agents"; then
    global_errors=1
  fi
fi

# Check templates/agents/ (SDK template agents)
if [ -d "templates/agents" ]; then
  if ! check_dir "templates/agents" "templates/agents"; then
    global_errors=1
  fi
fi

# If neither directory exists, nothing to check
if [ ! -d ".claude/agents" ] && [ ! -d "templates/agents" ]; then
  exit 0
fi

if [ "$global_errors" -gt 0 ]; then
  echo "[agent-budget] Fix descriptions or bypass with: SKIP_AGENT_BUDGET=1 git commit ..."
  exit 1
fi

exit 0
