#!/bin/bash
# Script to sync Spec Kit from prevance_health to workspace root
# Run this if you update Spec Kit files in prevance_health

SOURCE="/workspace/development/frappe-bench/apps/prevance_health"
DEST="/workspace"

echo "Syncing Spec Kit from prevance_health to workspace root..."
echo ""

if [ ! -d "$SOURCE/.claude" ]; then
    echo "❌ Error: $SOURCE/.claude not found"
    exit 1
fi

# Remove old copies
rm -rf "$DEST/.claude" "$DEST/.specify"

# Copy fresh versions
cp -r "$SOURCE/.claude" "$DEST/"
cp -r "$SOURCE/.specify" "$DEST/"

echo "✅ Synced:"
echo "   - .claude/commands/ ($(ls $DEST/.claude/commands/ | wc -l) commands)"
echo "   - .specify/ (memory, scripts, templates)"
echo ""
echo "Now reload Cursor: Cmd+Shift+P → 'Developer: Reload Window'"
