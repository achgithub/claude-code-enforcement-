#!/bin/bash
# Example: Shared CSS Enforcement Rules
#
# Purpose: Prevent app-specific CSS, enforce shared CSS classes
# Use case: Microservices/micro-frontends with shared design system
# Usage: Copy these rules into your .claude/hooks/pre-write.sh

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🔍 [PRE-WRITE] CSS enforcement checking: $FILE_PATH" >&2

# Block common CSS file names (App.css, index.css, styles.css, etc.)
if [[ "$FILE_PATH" =~ (App|index|styles?|main)\.css$ ]]; then
  echo "❌ BLOCKED: App-specific CSS files forbidden" >&2
  echo "   Forbidden: App.css, index.css, styles.css, main.css" >&2
  echo "   Use: Shared CSS classes from design system" >&2
  echo "   Reference: Component library or style guide" >&2
  exit 2
fi

# Block CSS files in specific directories (with exceptions)
if [[ "$FILE_PATH" =~ ^(src|components|pages)/.*\.css$ ]]; then
  # Allow exceptions: *-board.css, *-game.css (game-specific rendering)
  if [[ ! "$FILE_PATH" =~ -(board|game)\.css$ ]]; then
    echo "❌ BLOCKED: CSS files not allowed in $FILE_PATH" >&2
    echo "   Exception: Only *-board.css or *-game.css allowed" >&2
    echo "   Use shared CSS classes instead" >&2
    exit 2
  fi
fi

# Block CSS imports in TypeScript/JavaScript files
if [[ "$FILE_PATH" =~ \.(tsx?|jsx?)$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    if grep -q "^import.*\.css['\"]" "$FILE_PATH" 2>/dev/null; then
      echo "❌ BLOCKED: CSS imports forbidden in TypeScript files" >&2
      echo "   Found: import './something.css'" >&2
      echo "   Use: Shared CSS loaded globally" >&2
      exit 2
    fi
  fi
fi

echo "✅ [PRE-WRITE] CSS rules passed" >&2
exit 0
