#!/bin/bash
# Claude Code Enforcement System Bootstrap
# Version: 1.0.0
#
# Universal installer for Claude Code project enforcement hooks
# Works with ANY project - creates template hooks that you customize
#
# Usage:
#   cd /path/to/your/project
#   /path/to/bootstrap-enforcement.sh
#
# What it does:
#   - Creates .claude/ directory in current project
#   - Installs 4 template hooks (pre-write, post-write, pre-stop, session-start)
#   - Hooks start as stubs (just log, no enforcement)
#   - Add project-specific rules incrementally

set -e

# Determine project root (where script is run from, not where it lives)
PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"

# Get the directory where this script lives (for copying templates)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

echo "═══════════════════════════════════════════════════════════"
echo "  Claude Code Enforcement System Bootstrap"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Project: $PROJECT_ROOT"
echo "  Templates: $TEMPLATES_DIR"
echo ""

# Check if .claude/ already exists
EXISTING_SETUP=false
if [ -d "$CLAUDE_DIR" ]; then
  EXISTING_SETUP=true
  echo "⚠️  EXISTING .claude/ directory detected"
  echo ""
  echo "Options:"
  echo "  1) Add enforcement hooks to existing setup (recommended)"
  echo "  2) Overwrite everything (destroys existing settings)"
  echo "  3) Abort"
  echo ""
  read -p "Choose [1/2/3]: " -n 1 -r
  echo

  case $REPLY in
    1)
      echo "✓ Adding enforcement hooks to existing setup..."
      ;;
    2)
      echo "⚠️  This will DELETE your existing .claude/ directory!"
      read -p "   Are you sure? (y/N): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
      fi
      rm -rf "$CLAUDE_DIR"
      EXISTING_SETUP=false
      ;;
    *)
      echo "❌ Aborted"
      exit 1
      ;;
  esac
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$HOOKS_DIR"
mkdir -p "$CLAUDE_DIR/logs"

# Create or update settings.json
if [ "$EXISTING_SETUP" = true ] && [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "⚙️  Merging enforcement hooks into existing settings.json..."

  # Backup existing settings
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
  echo "   (Backup saved to settings.json.backup)"

  # Check if settings.json already has hooks section
  if grep -q '"hooks"' "$CLAUDE_DIR/settings.json"; then
    echo ""
    echo "⚠️  WARNING: settings.json already has hooks configured"
    echo "   Manual merge required. Enforcement hook templates are in:"
    echo "   $HOOKS_DIR/"
    echo ""
    echo "   Add these to your settings.json hooks section:"
    echo "   - PermissionRequest: permission-request.sh"
    echo "   - PreToolUse: pre-write.sh"
    echo "   - PostToolUse: post-write.sh"
    echo "   - Stop: pre-stop.sh"
    echo "   - SessionStart: session-start.sh"
    echo ""
    SKIP_SETTINGS=true
  else
    # Add hooks section to existing settings.json
    # Remove closing brace, add hooks, add closing brace
    sed -i.tmp '$ s/}$/,/' "$CLAUDE_DIR/settings.json"
    cat >> "$CLAUDE_DIR/settings.json" <<'HOOKS_EOF'
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-write.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/post-write.sh"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/permission-request.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-stop.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  }
}
HOOKS_EOF
    rm -f "$CLAUDE_DIR/settings.json.tmp"
  fi
else
  # Create new settings.json
  echo "⚙️  Creating settings.json..."
  cat > "$CLAUDE_DIR/settings.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-write.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/post-write.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-stop.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/permission-request.sh"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  }
}
EOF
fi

# Copy or create hook templates
echo "🔧 Installing hook templates..."

# Skip copying templates if we're merging and hooks already exist
if [ "$EXISTING_SETUP" = true ] && [ -n "$SKIP_SETTINGS" ]; then
  echo "⚠️  Skipping template installation (manual merge required)"
  echo "   Copy enforcement hooks from: $TEMPLATES_DIR/"
  echo "   To: $HOOKS_DIR/"
  echo ""
  echo "   Then update settings.json to reference them"
  exit 0
fi

if [ -d "$TEMPLATES_DIR" ]; then
  # Copy from templates directory
  cp "$TEMPLATES_DIR/pre-write.sh" "$HOOKS_DIR/"
  cp "$TEMPLATES_DIR/post-write.sh" "$HOOKS_DIR/"
  cp "$TEMPLATES_DIR/pre-stop.sh" "$HOOKS_DIR/"
  cp "$TEMPLATES_DIR/session-start.sh" "$HOOKS_DIR/"
  cp "$TEMPLATES_DIR/permission-request.sh" "$HOOKS_DIR/"
else
  # Fallback: create inline templates
  echo "⚠️  Templates directory not found, creating inline templates"

  cat > "$HOOKS_DIR/pre-write.sh" <<'HOOK_EOF'
#!/bin/bash
# PreToolUse Hook: Runs BEFORE Claude writes/edits files
# Exit 0 = allow operation
# Exit 2 = block operation (Claude gets feedback and must adjust)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🔍 [PRE-WRITE] Claude wants to $TOOL_NAME: $FILE_PATH" >&2

# ============================================================
# ADD YOUR ENFORCEMENT RULES HERE
# ============================================================
#
# Example: Block specific file patterns
# if [[ "$FILE_PATH" =~ forbidden-pattern\.css$ ]]; then
#   echo "❌ BLOCKED: No CSS files allowed" >&2
#   exit 2
# fi
#
# Example: Block specific directories
# if [[ "$FILE_PATH" =~ ^src/forbidden/ ]]; then
#   echo "❌ BLOCKED: Cannot write to src/forbidden/" >&2
#   exit 2
# fi

echo "✅ [PRE-WRITE] No violations detected - allowing operation" >&2
exit 0
HOOK_EOF

  cat > "$HOOKS_DIR/post-write.sh" <<'HOOK_EOF'
#!/bin/bash
# PostToolUse Hook: Runs AFTER Claude writes/edits files
# Exit 0 = keep the write
# Exit 2 = undo the write

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "📝 [POST-WRITE] Claude completed $TOOL_NAME: $FILE_PATH" >&2

# ============================================================
# ADD YOUR VALIDATION RULES HERE
# ============================================================
#
# Example: Check file content
# if grep -q "FORBIDDEN_PATTERN" "$FILE_PATH" 2>/dev/null; then
#   echo "❌ BLOCKED: File contains forbidden pattern" >&2
#   exit 2
# fi
#
# Example: Run linter
# if [[ "$FILE_PATH" =~ \.tsx?$ ]]; then
#   if ! eslint "$FILE_PATH" --quiet 2>/dev/null; then
#     echo "⚠️  WARNING: ESLint errors detected" >&2
#   fi
# fi

echo "✅ [POST-WRITE] Validation passed" >&2
exit 0
HOOK_EOF

  cat > "$HOOKS_DIR/pre-stop.sh" <<'HOOK_EOF'
#!/bin/bash
# Stop Hook: Runs when Claude tries to stop/complete
# Exit 0 = allow stopping
# Exit 2 = block stopping (Claude must continue)

echo "🛑 [PRE-STOP] Claude is trying to stop..." >&2

# ============================================================
# ADD YOUR FINAL VALIDATION HERE
# ============================================================
#
# Example: Check for uncommitted changes
# if ! git diff --quiet 2>/dev/null; then
#   echo "⚠️  WARNING: Uncommitted changes exist" >&2
# fi
#
# Example: Run tests
# if command -v npm &> /dev/null; then
#   if ! npm test --silent 2>/dev/null; then
#     echo "❌ BLOCKED: Tests failing - fix before stopping" >&2
#     exit 2
#   fi
# fi

echo "✅ [PRE-STOP] Validation passed - allowing stop" >&2
exit 0
HOOK_EOF

  cat > "$HOOKS_DIR/session-start.sh" <<'HOOK_EOF'
#!/bin/bash
# SessionStart Hook: Runs when Claude Code session starts
# Output (stdout) gets injected into Claude's context
# stderr goes to logs only

echo "🚀 [SESSION-START] Enforcement system loading..." >&2

# ============================================================
# INJECT ENFORCEMENT RULES INTO CONTEXT
# ============================================================

# Detect platform
IS_MAC=false
if [[ "$(uname)" == "Darwin" ]]; then
  IS_MAC=true
fi

# Output to Claude's context (stdout):
cat <<'EOF'

## 🛡️ Enforcement System Active

**Permission Logging:** All tool uses logged to `.claude/logs/permissions.log`
- Review periodically: `tail -f .claude/logs/permissions.log`
- Learning mode: Starts permissive, add deny rules over time

**Active Blocking Rules:**
EOF

# Platform-specific rules
if $IS_MAC; then
  cat <<'EOF'
- ❌ **git push** blocked on Mac (user pushes manually)

**Mac/Pi Workflow:**
1. Write code on Mac (this machine)
2. Commit locally (Claude does this)
3. User pushes manually
4. Pull on Pi and build/test there
EOF
fi

cat <<'EOF'

**Add Custom Rules:**
- Edit `.claude/hooks/permission-request.sh` for conditional logic
- Or add to `.claude/settings.json` permissions.deny for simple blocks

**Hook files:** `.claude/hooks/*.sh`
EOF
HOOK_EOF

  cat > "$HOOKS_DIR/permission-request.sh" <<'HOOK_EOF'
#!/bin/bash
# PermissionRequest Hook: Runs when Claude requests permission for ANY tool
# This hook LOGS all tool requests and can selectively BLOCK operations
# Exit 0 = allow, Exit 2 = block
#
# LEARNING MODE: This hook logs everything to help you build restrictions over time
# Review the log, then convert frequent violations to deny rules in settings.json

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Extract tool-specific arguments from tool_input
case "$TOOL_NAME" in
  Bash)
    TOOL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    ;;
  Write|Edit)
    TOOL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Read)
    TOOL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  *)
    TOOL_ARGS=$(echo "$INPUT" | jq -r '.tool_input | to_entries | map("\(.key)=\(.value)") | join(", ") // empty')
    ;;
esac

# ============================================================
# LOGGING: Track all tool requests for review
# ============================================================

LOG_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/logs"
LOG_FILE="$LOG_DIR/permissions.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log entry: timestamp | tool | args
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] $TOOL_NAME | $TOOL_ARGS" >> "$LOG_FILE"

# ============================================================
# ENFORCEMENT RULES: Block specific operations
# ============================================================

# Detect if we're on Mac (editing machine)
IS_MAC=false
if [[ "$(uname)" == "Darwin" ]]; then
  IS_MAC=true
fi

# Block git push on Mac (user pushes manually per workflow)
if $IS_MAC && [[ "$TOOL_NAME" == "Bash" ]]; then
  BASH_CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  if [[ "$BASH_CMD" =~ ^git\ push ]]; then
    echo "❌ BLOCKED: git push on Mac" >&2
    echo "   Mac/Pi workflow: User pushes manually" >&2
    echo "   Commit locally, then push when ready" >&2
    exit 2
  fi
fi

# ============================================================
# ADD YOUR ENFORCEMENT RULES HERE
# ============================================================
#
# Example: Block npm on Mac (no npm installed)
# if $IS_MAC && [[ "$TOOL_NAME" == "Bash" ]]; then
#   BASH_CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
#   if [[ "$BASH_CMD" =~ ^npm ]]; then
#     echo "❌ BLOCKED: npm not available on Mac" >&2
#     echo "   Build/test on Pi after push" >&2
#     exit 2
#   fi
# fi
#
# Example: Block go commands on Mac (no Go installed)
# if $IS_MAC && [[ "$TOOL_NAME" == "Bash" ]]; then
#   BASH_CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
#   if [[ "$BASH_CMD" =~ ^go\ ]]; then
#     echo "❌ BLOCKED: Go not available on Mac" >&2
#     echo "   Build/test on Pi after push" >&2
#     exit 2
#   fi
# fi
#
# Review log periodically:
#   tail -f .claude/logs/permissions.log
#
# When you see violations, add rules above OR in settings.json permissions

# Allow by default (learning mode)
exit 0
HOOK_EOF
fi

# Make hooks executable
chmod +x "$HOOKS_DIR"/*.sh

# Create README
echo "📝 Creating README..."
cat > "$CLAUDE_DIR/README.md" <<'EOF'
# Claude Code Enforcement System

Installed by: claude-code-enforcement/bootstrap-enforcement.sh
Installation date: $(date +%Y-%m-%d)

## What This Is

Hooks that run during Claude Code sessions to enforce project standards.

## Hooks Installed

### 1. PreToolUse Hook (`pre-write.sh`)
- **When**: BEFORE Claude writes/edits files
- **Purpose**: Block non-compliant operations before they happen
- **Exit 2**: Blocks the write, Claude gets feedback
- **Exit 0**: Allows the write

### 2. PostToolUse Hook (`post-write.sh`)
- **When**: AFTER Claude writes/edits files
- **Purpose**: Validate written files, can undo if needed
- **Exit 2**: Undoes the write
- **Exit 0**: Keeps the write

### 3. Stop Hook (`pre-stop.sh`)
- **When**: When Claude tries to stop/complete
- **Purpose**: Final validation before finishing
- **Exit 2**: Prevents stopping, Claude continues
- **Exit 0**: Allows stopping

### 4. SessionStart Hook (`session-start.sh`)
- **When**: At start of conversation
- **Purpose**: Initialize environment, inject critical rules
- **Output**: Goes into Claude's context

## Quick Start

1. **Restart Claude Code** (required to load hooks)
2. **Test**: Edit a file - you'll see hook messages
3. **Customize**: Add rules to `.claude/hooks/*.sh`

## Adding Rules

Edit hook scripts to add project-specific validation:

```bash
# Example in pre-write.sh:
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: No CSS files" >&2
  exit 2
fi
```

## Testing Hooks

Test hooks manually:
```bash
bash .claude/hooks/pre-write.sh Write path/to/file.txt
echo $?  # 0 = allowed, 2 = blocked
```

## Debugging

- Hook output appears in Claude Code interface
- Check `~/.claude/logs/` for detailed logs
- Add `echo` statements to hooks for debugging

## Disable Temporarily

Rename `settings.json`:
```bash
mv .claude/settings.json .claude/settings.json.disabled
```

Restart Claude Code to take effect.

## Documentation

Full documentation: https://github.com/YOUR-USERNAME/claude-code-enforcement
EOF

# Create .gitignore
cat > "$CLAUDE_DIR/.gitignore" <<'EOF'
# Logs are local - don't commit
logs/

# Commit hooks to share enforcement with team
# Or uncomment to keep hooks private:
# *
# !.gitignore
# !README.md
EOF

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Installation Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📁 Created:"
echo "   $CLAUDE_DIR/settings.json"
echo "   $CLAUDE_DIR/hooks/pre-write.sh"
echo "   $CLAUDE_DIR/hooks/post-write.sh"
echo "   $CLAUDE_DIR/hooks/pre-stop.sh"
echo "   $CLAUDE_DIR/hooks/session-start.sh"
echo "   $CLAUDE_DIR/README.md"
echo ""
echo "🔄 NEXT STEP: Restart Claude Code to load hooks"
echo ""
echo "🧪 Then test:"
echo "   1. Ask Claude to edit a file"
echo "   2. Watch for hook messages in output"
echo "   3. If you see messages → hooks are working!"
echo ""
echo "📖 Customize:"
echo "   Edit .claude/hooks/*.sh to add project-specific rules"
echo "   See examples: $SCRIPT_DIR/examples/"
echo ""
