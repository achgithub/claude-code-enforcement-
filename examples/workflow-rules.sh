#!/bin/bash
# Example: Development Workflow Enforcement
#
# Purpose: Enforce specific development workflows (e.g., Mac/Pi split)
# Use case: Solo developer with editing machine + build server
# Usage: Copy these rules into your .claude/hooks/pre-write.sh

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🔍 [PRE-WRITE] Workflow enforcement checking: $FILE_PATH" >&2

# Detect if we're on the "editing" machine (Mac)
# Adjust detection logic for your environment
IS_MAC=false
if [[ "$(uname)" == "Darwin" ]]; then
  IS_MAC=true
fi

# Block build artifacts from being committed on Mac
if $IS_MAC; then
  # Block common build output directories
  if [[ "$FILE_PATH" =~ ^(dist|build|out|target)/ ]]; then
    echo "❌ BLOCKED: Do not commit build artifacts from Mac" >&2
    echo "   Build artifacts should be generated on build server" >&2
    echo "   File: $FILE_PATH" >&2
    exit 2
  fi

  # Block compiled binaries
  if [[ "$FILE_PATH" =~ \.(o|exe|bin|so|dylib)$ ]]; then
    echo "❌ BLOCKED: Do not commit compiled binaries from Mac" >&2
    echo "   Compile on build server" >&2
    exit 2
  fi
fi

# Block localhost URLs in configuration files
if [[ "$FILE_PATH" =~ \.(sql|json|yaml|yml|toml|env)$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    if grep -i "localhost" "$FILE_PATH" 2>/dev/null | grep -v "^#" | grep -v "^//" > /dev/null; then
      echo "❌ BLOCKED: 'localhost' found in $FILE_PATH" >&2
      echo "   Use environment variables or placeholders instead" >&2
      echo "   Example: \${HOST}, {host}, or \$DB_HOST" >&2
      exit 2
    fi
  fi
fi

# Block hardcoded IP addresses (except comments)
if [[ "$FILE_PATH" =~ \.(go|ts|tsx|js|jsx|py|rb)$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    if grep -E '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$FILE_PATH" 2>/dev/null | grep -v "^#\|^//\|^\*" | grep -v "0.0.0.0\|127.0.0.1" > /dev/null; then
      echo "⚠️  WARNING: Hardcoded IP address detected in $FILE_PATH" >&2
      echo "   Consider using environment variables" >&2
      # Uncomment to block:
      # exit 2
    fi
  fi
fi

echo "✅ [PRE-WRITE] Workflow rules passed" >&2
exit 0
