# Claude Code Skill Edit Workaround

A hook that lets Claude autonomously self-edit `.claude/skills/` files despite a Claude Code bug blocking it.

## The Problem

The `Edit` and `Write` tools are blocked on `.claude/skills/` paths even when you have explicit allow rules in `settings.json`:

```json
"Edit(.claude/skills/**)"
"Write(.claude/skills/**)"
```

This happens because Claude Code's `.claude/` directory safeguard evaluates *before* any allowlist check — so your allow rules are silently ignored.

This is a known bug: [anthropics/claude-code#51571](https://github.com/anthropics/claude-code/issues/51571), also tracked in [#49573](https://github.com/anthropics/claude-code/issues/49573) and [#36497](https://github.com/anthropics/claude-code/issues/36497). It affects macOS, Linux, and WSL. The `Bash` tool is not blocked.

## The Fix

A `PreToolUse` hook intercepts `Edit` calls on `.claude/skills/` paths *before* they hit the safeguard. It:

1. **Denies the Edit** (cleanly, before the safeguard error)
2. **Injects `additionalContext`** into the model explaining the bug and providing a Python-based workaround

The model receives the workaround instructions automatically and retries using `python3` via Bash — no user intervention needed.

## Install

```bash
git clone https://github.com/alexknowshtml/claude-skill-edit-fix
cd claude-skill-edit-fix
./install.sh
```

Then restart Claude Code.

## Requirements

- Claude Code 2.1.x+
- `jq` (for the hook to parse stdin)
- `python3` (for the workaround the model uses)

## How It Works

When the model tries `Edit` on a skill file, the hook fires and returns:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Edit is blocked on .claude/skills/ paths (Claude Code bug #51571)",
    "additionalContext": "SKILL EDIT WORKAROUND: use python3 to modify the file..."
  }
}
```

The model reads the `additionalContext`, understands what happened, and uses Python to make the edit instead.

## Uninstall

Remove the hook entry from `~/.claude/settings.json` under `hooks.PreToolUse`, and delete `~/.claude/hooks/skill-edit-workaround.sh`.

## Status

This is a temporary workaround. Once Anthropic ships a fix for [#51571](https://github.com/anthropics/claude-code/issues/51571), this repo will be archived.
