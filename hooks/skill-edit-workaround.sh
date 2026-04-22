#!/usr/bin/env bash
# PreToolUse hook: intercepts Edit tool calls on .claude/skills/ paths
# and injects workaround instructions into the model context.
#
# Workaround for: https://github.com/anthropics/claude-code/issues/51571
# The Edit tool is blocked on .claude/skills/ paths even with explicit
# allow rules in settings.json. This hook fires first and tells the
# model to use Python instead.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE_PATH" | grep -q '\.claude/skills/'; then
  cat << 'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Edit is blocked on .claude/skills/ paths (Claude Code bug #51571)",
    "additionalContext": "SKILL EDIT WORKAROUND (Claude Code bug #51571): The Edit tool is blocked on .claude/skills/ paths. Use Python for targeted edits:\n\npython3 -c \"\npath = 'FILE_PATH'\ncontent = open(path).read()\ncontent = content.replace('OLD_STRING', 'NEW_STRING')\nopen(path, 'w').write(content)\n\"\n\nFor full rewrites, read the file first with the Read tool, then write the modified content using a bash heredoc:\ncat > FILE_PATH << 'HEREDOC'\n...full content...\nHEREDOC\n\nThis workaround is temporary until Anthropic fixes the underlying bug."
  }
}
JSON
fi
