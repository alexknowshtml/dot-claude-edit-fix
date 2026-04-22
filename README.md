# Claude Code .claude/ Edit Workaround

A hook that lets Claude autonomously edit files in the `.claude/` directory despite a bug blocking it.

## The Problem

The `Edit` and `Write` tools are blocked on **all** `.claude/` paths — including `skills/`, `commands/`, `agents/`, `hooks/`, `includes/`, `plans/`, and `settings.json` — even when you have explicit allow rules:

```json
"Edit(.claude/skills/**)"
"Write(.claude/skills/**)"
```

Claude Code's `.claude/` directory safeguard evaluates *before* any allowlist check — so your allow rules are silently ignored. The `Bash` tool is not blocked.

**Known bugs:**
- [#51571](https://github.com/anthropics/claude-code/issues/51571) — Edit tool not covered by .claude/skills/ exemption + session allows ignored
- [#49573](https://github.com/anthropics/claude-code/issues/49573) — Edit/Write guardrail blocks .claude/ anywhere in path
- [#36497](https://github.com/anthropics/claude-code/issues/36497) — .claude/skills/ edits prompt despite being documented as exempt

Affects macOS, Linux, and WSL across multiple Claude Code versions.

## The Fix

A `PreToolUse` hook intercepts `Edit` calls on `.claude/` paths *before* they hit the safeguard. It:

1. **Denies the Edit** cleanly (before the confusing safeguard error)
2. **Injects `additionalContext`** into the model explaining the bug and a Python-based workaround

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

When Claude tries `Edit` on any `.claude/` file, the hook fires and returns:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Edit/Write is blocked on .claude/ paths (Claude Code bug #51571)",
    "additionalContext": "CLAUDE DIR EDIT WORKAROUND: use python3..."
  }
}
```

The model reads the `additionalContext` and uses Python to make the edit instead.

## Uninstall

Remove the hook entry from `~/.claude/settings.json` under `hooks.PreToolUse`, and delete `~/.claude/hooks/skill-edit-workaround.sh`.

## Status

Temporary workaround. Will be archived once Anthropic fixes [#51571](https://github.com/anthropics/claude-code/issues/51571).
