#!/usr/bin/env bash
# PreToolUse hook: intercepts Edit/Write tool calls on .claude/ paths
# and injects workaround instructions into the model context.
#
# Workaround for: https://github.com/anthropics/claude-code/issues/51571
# The Edit and Write tools are blocked on ALL .claude/ paths even with
# explicit allow rules in settings.json. Bash is not blocked.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE_PATH" | grep -q '\.claude/'; then
  cat << 'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Edit/Write is blocked on .claude/ paths (Claude Code bug #51571)",
    "additionalContext": "CLAUDE DIR EDIT WORKAROUND (bug #51571): The Edit and Write tools are blocked on ALL .claude/ paths even with explicit allow rules. Use Python for targeted edits:\n\npython3 -c \"\npath = 'FILE_PATH'\ncontent = open(path).read()\ncontent = content.replace('OLD_STRING', 'NEW_STRING')\nopen(path, 'w').write(content)\n\"\n\nFor full rewrites use a bash heredoc:\ncat > FILE_PATH << 'HEREDOC'\n...full content...\nHEREDOC\n\nThis applies to skills/, commands/, agents/, hooks/, includes/, plans/, settings.json — everything under .claude/"
  }
}
JSON
fi
