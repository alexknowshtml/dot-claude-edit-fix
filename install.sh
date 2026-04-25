#!/usr/bin/env bash
set -e

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_NAME="skill-edit-workaround.sh"
HOOK_SRC="$(dirname "$0")/hooks/$HOOK_NAME"
HOOK_DEST="$HOOK_DIR/$HOOK_NAME"

MKDIR_HOOK_NAME="claude-dir-mkdir-allow.sh"
MKDIR_HOOK_SRC="$(dirname "$0")/hooks/$MKDIR_HOOK_NAME"
MKDIR_HOOK_DEST="$HOOK_DIR/$MKDIR_HOOK_NAME"

echo "Installing Claude Code skill-edit workaround..."

# 1. Install hook scripts
mkdir -p "$HOOK_DIR"
cp "$HOOK_SRC" "$HOOK_DEST"
chmod +x "$HOOK_DEST"
echo "✓ Hook installed to $HOOK_DEST"

cp "$MKDIR_HOOK_SRC" "$MKDIR_HOOK_DEST"
chmod +x "$MKDIR_HOOK_DEST"
echo "✓ Hook installed to $MKDIR_HOOK_DEST"

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

# 4. Check if Edit/Write hook already registered
if jq -e '.hooks.PreToolUse[]?.hooks[]?.command' "$SETTINGS" 2>/dev/null | grep -q "$HOOK_NAME"; then
  echo "✓ Edit/Write hook already registered in settings.json — skipping"
else
  # Add Edit/Write hook to PreToolUse hooks
  python3 - << PYEOF
import json, sys

with open("$SETTINGS", "r") as f:
    settings = json.load(f)

if "hooks" not in settings:
    settings["hooks"] = {}
if "PreToolUse" not in settings["hooks"]:
    settings["hooks"]["PreToolUse"] = []

new_hook = {
    "matcher": "Edit|Write",
    "hooks": [{
        "type": "command",
        "command": "$HOOK_DEST"
    }]
}
settings["hooks"]["PreToolUse"].append(new_hook)

with open("$SETTINGS", "w") as f:
    json.dump(settings, f, indent=2)
print("✓ Edit/Write hook registered in ~/.claude/settings.json")
PYEOF
fi

# 5. Check if mkdir hook already registered
if jq -e '.hooks.PreToolUse[]?.hooks[]?.command' "$SETTINGS" 2>/dev/null | grep -q "$MKDIR_HOOK_NAME"; then
  echo "✓ mkdir hook already registered in settings.json — skipping"
else
  # Add mkdir hook to PreToolUse hooks
  python3 - << PYEOF
import json, sys

with open("$SETTINGS", "r") as f:
    settings = json.load(f)

new_hook = {
    "matcher": "Bash",
    "hooks": [{
        "type": "command",
        "command": "$MKDIR_HOOK_DEST"
    }]
}
settings["hooks"]["PreToolUse"].append(new_hook)

with open("$SETTINGS", "w") as f:
    json.dump(settings, f, indent=2)
print("✓ mkdir hook registered in ~/.claude/settings.json")
PYEOF
fi

echo ""
echo "Done. Restart Claude Code to activate the workaround."
echo "The hooks will intercept Edit/Write calls on .claude/ paths and"
echo "auto-approve mkdir commands targeting .claude/ paths."
