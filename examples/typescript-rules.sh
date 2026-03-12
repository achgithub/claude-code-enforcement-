#!/bin/bash
# Example: TypeScript Enforcement Rules
#
# Purpose: Enforce TypeScript (.ts/.tsx) instead of JavaScript (.js/.jsx)
# Usage: Copy these rules into your .claude/hooks/pre-write.sh

TOOL_NAME="$1"
FILE_PATH="$2"

echo "🔍 [PRE-WRITE] TypeScript enforcement checking: $FILE_PATH" >&2

# Block .js and .jsx files in src/ directory
if [[ "$FILE_PATH" =~ ^src/.*\.jsx?$ ]]; then
  echo "❌ BLOCKED: JavaScript files not allowed in src/" >&2
  echo "   Use TypeScript instead:" >&2
  echo "   - .js → .ts" >&2
  echo "   - .jsx → .tsx" >&2
  exit 2
fi

# Warn if .js/.jsx exists anywhere (non-blocking)
if [[ "$FILE_PATH" =~ \.jsx?$ ]]; then
  echo "⚠️  WARNING: JavaScript file detected. Consider using TypeScript." >&2
fi

echo "✅ [PRE-WRITE] TypeScript rules passed" >&2
exit 0
