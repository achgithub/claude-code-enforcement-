#!/bin/bash
# Example: Security & Code Quality Rules
#
# Purpose: Prevent common security issues and code quality problems
# Usage: Copy these rules into your .claude/hooks/pre-write.sh or post-write.sh

TOOL_NAME="$1"
FILE_PATH="$2"

echo "🔍 [SECURITY] Checking: $FILE_PATH" >&2

# Only check file content if file exists (post-write)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Block files containing common secrets/credentials patterns
if grep -E "(password|secret|api[_-]?key|private[_-]?key|token)\s*=\s*['\"][^'\"]{8,}" "$FILE_PATH" 2>/dev/null | grep -v "^#\|^//\|^\*" > /dev/null; then
  echo "⚠️  WARNING: Possible hardcoded credentials in $FILE_PATH" >&2
  echo "   Use environment variables instead" >&2
  # Uncomment to block:
  # exit 2
fi

# Block common dangerous patterns in code
if [[ "$FILE_PATH" =~ \.(go|ts|tsx|js|jsx|py)$ ]]; then

  # Detect eval() usage (security risk)
  if grep -E '\beval\(' "$FILE_PATH" 2>/dev/null | grep -v "^#\|^//\|^\*" > /dev/null; then
    echo "❌ BLOCKED: eval() usage detected - security risk" >&2
    echo "   File: $FILE_PATH" >&2
    exit 2
  fi

  # Detect TODO/FIXME in critical files (warning only)
  if grep -iE '\b(TODO|FIXME|HACK|XXX)\b' "$FILE_PATH" 2>/dev/null > /dev/null; then
    TODO_COUNT=$(grep -icE '\b(TODO|FIXME|HACK|XXX)\b' "$FILE_PATH")
    echo "⚠️  WARNING: $TODO_COUNT TODO/FIXME comment(s) in $FILE_PATH" >&2
  fi

  # Detect console.log in production code (TypeScript/JavaScript)
  if [[ "$FILE_PATH" =~ \.(tsx?|jsx?)$ ]] && [[ ! "$FILE_PATH" =~ (test|spec)\. ]]; then
    if grep -E 'console\.(log|debug|info)' "$FILE_PATH" 2>/dev/null | grep -v "^#\|^//\|^\*" > /dev/null; then
      echo "⚠️  WARNING: console.log detected in $FILE_PATH" >&2
      echo "   Remove before production or use proper logger" >&2
    fi
  fi
fi

# Check file size (warn if too large)
if [ -f "$FILE_PATH" ]; then
  LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 500 ]; then
    echo "⚠️  WARNING: File is $LINE_COUNT lines (>500)" >&2
    echo "   Consider refactoring: $FILE_PATH" >&2
  fi
fi

# Block .env files with real values (should be .env.example)
if [[ "$FILE_PATH" == ".env" ]]; then
  echo "❌ BLOCKED: Do not commit .env files" >&2
  echo "   Use .env.example with placeholder values" >&2
  exit 2
fi

echo "✅ [SECURITY] Checks passed" >&2
exit 0
