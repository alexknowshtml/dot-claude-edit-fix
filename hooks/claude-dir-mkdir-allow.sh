#!/usr/bin/env bash
# PreToolUse hook: auto-approve mkdir commands targeting .claude/ paths
# Fixes the gap where the Edit/Write hook catches file writes but Bash mkdir
# to .claude/ still triggers a permission prompt (different code path).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$COMMAND" | grep -qE 'mkdir.*\.claude/'; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow", "permissionDecisionReason": "Auto-approving mkdir for .claude/ paths"}}'
fi
