#!/bin/bash
# SessionStart Hook: Runs when Claude Code session starts
# Output (stdout) gets injected into Claude's context
# stderr goes to logs only

echo "🚀 [SESSION-START] Enforcement system loading..." >&2

# ============================================================
# ADD CONTEXT INJECTION HERE
# ============================================================
#
# Example: Display critical rules (stdout → Claude's context)
# cat <<'EOF'
# ⚠️ CRITICAL PROJECT STANDARDS:
# 1. No CSS files in src/ - use shared styles
# 2. TypeScript only - no .js files
# 3. Run tests before committing
# EOF
#
# Example: Check environment dependencies
# if ! command -v node &> /dev/null; then
#   echo "⚠️  WARNING: Node.js not installed" >&2
# fi
#
# Example: Display git branch info
# if git rev-parse --git-dir > /dev/null 2>&1; then
#   BRANCH=$(git branch --show-current 2>/dev/null)
#   echo "📍 Current branch: $BRANCH" >&2
# fi

# Output to Claude's context (stdout):
echo "Enforcement hooks are active."
echo "Customize rules in .claude/hooks/*.sh"
