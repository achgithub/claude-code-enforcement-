#!/bin/bash
# PreToolUse Hook: Runs BEFORE Claude writes/edits files
# Exit 0 = allow operation
# Exit 2 = block operation (Claude gets feedback and must adjust)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🔍 [PRE-WRITE] Claude wants to $TOOL_NAME: $FILE_PATH" >&2

# ============================================================
# ENFORCEMENT RULES FOR THIS PROJECT
# ============================================================

# Block old hook argument format in hook files
if [[ "$FILE_PATH" =~ (examples|templates|\.claude/hooks)/.*\.sh$ ]]; then
  # Get the content that's about to be written
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

  # Check for old argument format (TOOL_NAME="$1" or FILE_PATH="$2")
  if echo "$CONTENT" | grep -qE '(TOOL_NAME|FILE_PATH)="\$[12]"'; then
    echo "❌ BLOCKED: Old hook argument format detected" >&2
    echo "   File: $FILE_PATH" >&2
    echo "" >&2
    echo "   ❌ WRONG (old format):" >&2
    echo "      TOOL_NAME=\"\$1\"" >&2
    echo "      FILE_PATH=\"\$2\"" >&2
    echo "" >&2
    echo "   ✅ CORRECT (JSON stdin format):" >&2
    echo "      INPUT=\$(cat)" >&2
    echo "      TOOL_NAME=\$(echo \"\$INPUT\" | jq -r '.tool_name')" >&2
    echo "      FILE_PATH=\$(echo \"\$INPUT\" | jq -r '.tool_input.file_path // empty')" >&2
    exit 2
  fi
fi

# Block documentation that references the old format as current
if [[ "$FILE_PATH" =~ \.(md|txt)$ ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

  # Look for patterns that suggest teaching the old format
  if echo "$CONTENT" | grep -qE 'TOOL_NAME="\$1".*# CORRECT|FILE_PATH="\$2".*# CORRECT'; then
    echo "❌ BLOCKED: Documentation references old argument format as correct" >&2
    echo "   File: $FILE_PATH" >&2
    echo "   Use JSON stdin format in all examples" >&2
    exit 2
  fi
fi

# DEBUG: Log to file to see if hook is running
echo "[$(date)] PRE-WRITE: $TOOL_NAME $FILE_PATH" >> /tmp/claude-hook-debug.log

echo "✅ [PRE-WRITE] No violations detected - allowing operation" >&2
exit 0
