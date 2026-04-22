#!/usr/bin/env bash
set -e

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_NAME="skill-edit-workaround.sh"
HOOK_SRC="$(dirname "$0")/hooks/$HOOK_NAME"
HOOK_DEST="$HOOK_DIR/$HOOK_NAME"

echo "Installing Claude Code skill-edit workaround..."

# 1. Install hook script
mkdir -p "$HOOK_DIR"
cp "$HOOK_SRC" "$HOOK_DEST"
chmod +x "$HOOK_DEST"
echo "✓ Hook installed to $HOOK_DEST"

# 2. Check jq is available
if ! command -v jq &>/dev/null; then
  echo "✗ jq is required but not installed. Install it first (e.g. brew install jq / apt install jq)"
  exit 1
fi

# 3. Check if settings.json exists
if [ ! -f "$SETTINGS" ]; then
  echo '{"hooks":{}}' > "$SETTINGS"
  echo "✓ Created $SETTINGS"
fi

# 4. Check if hook already registered
if jq -e '.hooks.PreToolUse[]?.hooks[]?.command' "$SETTINGS" 2>/dev/null | grep -q "$HOOK_NAME"; then
  echo "✓ Hook already registered in settings.json — skipping"
else
  # Add to PreToolUse hooks
  python3 - << PYEOF
import json, sys

with open("$SETTINGS", "r") as f:
    settings = json.load(f)

if "hooks" not in settings:
    settings["hooks"] = {}
if "PreToolUse" not in settings["hooks"]:
    settings["hooks"]["PreToolUse"] = []

new_hook = {
    "matcher": "Edit",
    "hooks": [{
        "type": "command",
        "command": "$HOOK_DEST"
    }]
}
settings["hooks"]["PreToolUse"].append(new_hook)

with open("$SETTINGS", "w") as f:
    json.dump(settings, f, indent=2)
print("✓ Hook registered in ~/.claude/settings.json")
PYEOF
fi

echo ""
echo "Done. Restart Claude Code to activate the workaround."
echo "The hook will intercept Edit calls on .claude/skills/ paths and"
echo "inject Python-based workaround instructions into the model context."
