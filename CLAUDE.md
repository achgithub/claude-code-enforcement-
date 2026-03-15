# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

**Claude Code Enforcement System** - A hook-based system that blocks Claude Code from violating project standards BEFORE code is written, not after.

**Core Concept**: Hooks run during Claude Code operations, receiving tool use data via stdin, and can block operations by exiting with code 2.

## Repository Architecture

### Three-Layer Structure

1. **Bootstrap Script** (`bootstrap-enforcement.sh`)
   - Universal installer that works in ANY project
   - Creates `.claude/` directory with settings.json and hook scripts
   - Copies template hooks OR generates them inline as fallback
   - Must be run from the target project directory

2. **Template Hooks** (`templates/*.sh`)
   - Stub implementations with placeholder comments
   - Used as starting point for new projects
   - Copied by bootstrap script into `.claude/hooks/`
   - Include all 4 hook types: pre-write, post-write, pre-stop, session-start

3. **Example Rules** (`examples/*.sh`)
   - Real-world rule implementations ready to copy-paste
   - Categories: TypeScript, CSS, workflow, security
   - **NOTE**: Some examples use old argument-style (`$1 $2`) and need updating to JSON stdin format

### Hook Data Flow (CRITICAL)

**Hooks receive JSON via stdin, NOT command-line arguments.**

```bash
# CORRECT (current implementation):
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# WRONG (old approach, still in some examples):
TOOL_NAME="$1"
FILE_PATH="$2"
```

**JSON Structure:**
```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.tsx",
    "content": "..."
  }
}
```

### Exit Codes

- **Exit 0**: Allow operation (continue)
- **Exit 2**: Block operation (Claude receives stderr output as feedback)
- **DO NOT use Exit 1** (reserved by system)

### Hook Types

| Hook | When | Purpose | Can Block? | Output Handling |
|------|------|---------|------------|----------------|
| **PreToolUse** | BEFORE Write/Edit | Prevent violations proactively | ✅ Yes | stderr → Claude sees it |
| **PostToolUse** | AFTER Write/Edit | Validate result, can undo | ✅ Yes | stderr → Claude sees it |
| **Stop** | When Claude stops | Final checks before finishing | ✅ Yes | stderr → Claude sees it |
| **SessionStart** | Conversation start | Re-inject rules into context | ❌ No | stdout → Claude context |

**Key Distinction**: SessionStart's stdout goes into Claude's context (for reminders), all others use stderr for user feedback.

## File Structure

```
claude-code-enforcement/
├── bootstrap-enforcement.sh     # Universal installer
├── templates/                   # Template stubs (copied to projects)
│   ├── pre-write.sh            # PreToolUse template
│   ├── post-write.sh           # PostToolUse template
│   ├── pre-stop.sh             # Stop hook template
│   └── session-start.sh        # SessionStart template
├── examples/                    # Real-world implementations
│   ├── typescript-rules.sh     # Enforce .ts/.tsx only
│   ├── css-rules.sh            # Shared CSS enforcement
│   ├── workflow-rules.sh       # Mac/Pi split workflow
│   └── security-quality-rules.sh
├── docs/
│   └── USAGE.md               # Detailed usage guide
├── README.md                   # User-facing documentation
├── NEXT-STEPS.md              # Roadmap and testing plan
└── .claude/                    # THIS REPO's own hooks (dogfooding)
    ├── settings.json
    └── hooks/
        ├── pre-write.sh       # Created by running bootstrap on itself
        ├── post-write.sh
        ├── pre-stop.sh
        └── session-start.sh
```

## Critical Technical Details

### 1. Settings.json Format

Must use `$CLAUDE_PROJECT_DIR` environment variable:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-write.sh"
          }
        ]
      }
    ]
  }
}
```

**Do NOT pass arguments** - hooks read JSON from stdin.

### 2. Hook Script Requirements

- Must be executable: `chmod +x .claude/hooks/*.sh`
- Must read stdin using `cat` and parse with `jq`
- Must write user messages to stderr (not stdout)
- SessionStart is exception: stdout → context, stderr → logs

### 3. Restart Requirement

**CRITICAL**: Claude Code MUST be restarted after:
- Creating/modifying `.claude/settings.json`
- Installing hooks via bootstrap script

Changes to hook scripts (`*.sh` files) do NOT require restart.

## Bootstrap Script Implementation

### What It Does

1. Creates `.claude/` directory in current working directory (pwd)
2. Generates `settings.json` with all 4 hook types configured
3. Copies templates OR creates inline versions (fallback)
4. Makes all hooks executable
5. Creates README and .gitignore

### How to Use

```bash
# From the project you want to enforce:
cd /path/to/my-project

# Run bootstrap (from wherever it lives):
/path/to/claude-code-enforcement/bootstrap-enforcement.sh

# Or add to PATH and run from anywhere:
export PATH="$HOME/Documents/Projects/claude-code-enforcement:$PATH"
cd /path/to/my-project
bootstrap-enforcement.sh
```

### Bootstrap Script Variables

- `PROJECT_ROOT`: `$(pwd)` - where bootstrap is run FROM
- `SCRIPT_DIR`: Where bootstrap script lives (for finding templates)
- `CLAUDE_DIR`: `$PROJECT_ROOT/.claude`
- `TEMPLATES_DIR`: `$SCRIPT_DIR/templates`

**Important**: Bootstrap is location-agnostic. It finds templates relative to itself, installs into current directory.

## Common Development Tasks

### Testing Hooks Manually

```bash
# Test with echo-based mock input:
echo '{"tool_name":"Write","tool_input":{"file_path":"test.css"}}' | \
  .claude/hooks/pre-write.sh

# Check exit code:
echo $?  # 0 = allowed, 2 = blocked

# Test actual hook files in this repo:
cd ~/Documents/Projects/claude-code-enforcement
echo '{"tool_name":"Write","tool_input":{"file_path":"App.css"}}' | \
  .claude/hooks/pre-write.sh
```

### Adding New Rules

Edit `.claude/hooks/pre-write.sh` in the target project:

```bash
# Add before the final "exit 0"
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: Use shared CSS" >&2
  exit 2
fi
```

**No restart needed** - changes to `*.sh` files take effect immediately.

### Combining Multiple Rule Sets

```bash
# In pre-write.sh:
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Source multiple rule files:
source "$(dirname "$0")/rules/typescript.sh"
source "$(dirname "$0")/rules/css.sh"
source "$(dirname "$0")/rules/workflow.sh"

# First exit 2 wins (blocks operation)
echo "✅ All rules passed" >&2
exit 0
```

### Debugging Hook Issues

1. **Check if hooks are firing**:
   - Look for hook messages in Claude Code output
   - Check `/tmp/claude-hook-debug.log` (if enabled)

2. **Test manually** with echo (see above)

3. **Check permissions**: `ls -la .claude/hooks/`

4. **Verify settings.json syntax**: Use `jq . .claude/settings.json`

5. **Remember to restart** if settings.json changed

### Temporarily Disable Hooks

```bash
# Disable all hooks:
mv .claude/settings.json .claude/settings.json.disabled

# Re-enable:
mv .claude/settings.json.disabled .claude/settings.json

# Restart Claude Code after either operation
```

## Development Workflow for This Repo

### When Adding New Examples

1. Create new file in `examples/`
2. Use CORRECT JSON stdin format (not arguments)
3. Include clear comments explaining the use case
4. Make it copy-paste ready
5. Test manually before committing
6. Update README.md to reference new example

### When Modifying Bootstrap Script

1. Test inline template generation (rename templates/ temporarily)
2. Test template copying (with templates/ restored)
3. Test in a throwaway project first
4. Verify `.claude/settings.json` syntax with `jq`
5. Restart Claude Code and test hooks fire

### When Updating Template Files

Keep `templates/*.sh` in sync with inline templates in `bootstrap-enforcement.sh` lines 116-236.

**If you change template format**, update BOTH locations.

### Dogfooding (Testing on This Repo)

This repo can have its own `.claude/` directory created by running bootstrap on itself:

```bash
cd ~/Documents/Projects/claude-code-enforcement
./bootstrap-enforcement.sh
# Restart Claude Code
# Now this repo is enforced by its own system
```

Use this to test that bootstrap works correctly.

## Self-Enforcement (Dogfooding)

This repository enforces its own standards using the enforcement system it provides.

### Enforcement Rules Active

**`.claude/hooks/pre-write.sh` blocks:**

1. **Old hook argument format** in any `.sh` file in:
   - `examples/`
   - `templates/`
   - `.claude/hooks/`

   If you try to write `TOOL_NAME="$1"` or `FILE_PATH="$2"`, you'll get:
   ```
   ❌ BLOCKED: Old hook argument format detected

   ❌ WRONG (old format):
      TOOL_NAME="$1"
      FILE_PATH="$2"

   ✅ CORRECT (JSON stdin format):
      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
      FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
   ```

2. **Documentation referencing old format as correct**
   - Prevents markdown files from showing old format as current best practice

**Result**: Impossible to accidentally create hooks with wrong format in this repo.

### Template Consistency

All templates and examples use consistent JSON stdin format. Bootstrap script's inline templates match `templates/*.sh` files exactly.

## Testing Checklist

When making changes to the enforcement system:

- [ ] Run bootstrap in test project
- [ ] Verify `.claude/settings.json` created
- [ ] Verify hooks are executable
- [ ] Restart Claude Code
- [ ] Ask Claude to edit a file → see hook messages
- [ ] Test blocking: Ask Claude to violate a rule → operation blocked
- [ ] Test allowing: Ask Claude to follow rules → operation allowed
- [ ] Check error messages are clear and actionable

## Important Conventions

### Message Format

Use emoji prefixes for clarity:
- `🔍 [PRE-WRITE]` - Before operation
- `📝 [POST-WRITE]` - After operation
- `🛑 [PRE-STOP]` - Before stopping
- `🚀 [SESSION-START]` - Session initialization
- `❌ BLOCKED:` - Operation prevented
- `✅` - Success/allowed
- `⚠️ WARNING:` - Non-blocking advisory

### Error Messages

When blocking (exit 2), provide:
1. What was blocked
2. Why it was blocked
3. What to do instead

Example:
```bash
echo "❌ BLOCKED: No CSS files allowed" >&2
echo "   Use Activity Hub shared classes (.ah-*)" >&2
echo "   Reference: Component Library (port 5010)" >&2
exit 2
```

## Environment Variables Available

- `$CLAUDE_PROJECT_DIR` - Absolute path to project root (where .claude/ lives)
- Use this in settings.json to reference hooks

## Dependencies

- **bash** - All hooks are bash scripts
- **jq** - Required for parsing JSON input
- **grep, sed, awk** - Common for rule logic (optional)

If `jq` is not installed, hooks will fail. Consider adding check in SessionStart hook.

## Context Switching

When switching between this repo and projects using it:

1. **This repo** (`claude-code-enforcement/`):
   - Contains bootstrap script and templates
   - May have its own `.claude/` (dogfooding)
   - Changes here affect template generation

2. **Target projects** (e.g., `pub-games-v3/`):
   - Have `.claude/` installed via bootstrap
   - Copy rules from `examples/` as starting point
   - Independent hook configurations

Each project's `.claude/` is separate. Hooks run where Claude Code runs (Mac), not on build servers (Pi).

## Relationship to Global CLAUDE.md

This repo documents the enforcement system itself. User's global `~/.claude/CLAUDE.md` defines workflow preferences (Mac/Pi split, no local builds, etc.).

Enforcement hooks can ENFORCE those preferences by blocking violations.

## Version Information

Current version: v1.0.0 (initial release 2026-03-12)

Hooks specification: Claude Code official hooks API
