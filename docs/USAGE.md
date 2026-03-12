# Detailed Usage Guide

## Installation

### Standard Installation

```bash
# Navigate to your project
cd /path/to/your/project

# Run bootstrap script
~/Documents/Projects/claude-code-enforcement/bootstrap-enforcement.sh
```

### Add to PATH (Recommended)

```bash
# Add to ~/.zshrc or ~/.bashrc:
export PATH="$HOME/Documents/Projects/claude-code-enforcement:$PATH"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc

# Now from any project:
bootstrap-enforcement.sh
```

### What Gets Created

```
your-project/
└── .claude/
    ├── settings.json          # Hook configuration
    ├── hooks/
    │   ├── pre-write.sh      # Template (customize this)
    │   ├── post-write.sh     # Template (customize this)
    │   ├── pre-stop.sh       # Template (customize this)
    │   └── session-start.sh  # Template (customize this)
    ├── README.md              # Local documentation
    └── .gitignore            # Optional (keep hooks private)
```

---

## Hook Types Explained

### 1. PreToolUse Hook (`pre-write.sh`)

**When**: BEFORE Claude executes Write or Edit tool

**Arguments**:
- `$1` = Tool name ("Write" or "Edit")
- `$2` = File path Claude wants to write/edit

**Purpose**: Block non-compliant operations before they happen

**Example Use Cases**:
- Block forbidden file types (CSS, .js, etc.)
- Validate file naming conventions
- Check directory restrictions
- Prevent writes to protected files

**Exit Codes**:
- `0` = Allow the write
- `2` = Block the write (Claude gets your error message)

**Example**:
```bash
#!/bin/bash
TOOL_NAME="$1"
FILE_PATH="$2"

# Block .css files
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: CSS files forbidden" >&2
  echo "   Use shared CSS classes instead" >&2
  exit 2
fi

exit 0  # Allow if no violations
```

### 2. PostToolUse Hook (`post-write.sh`)

**When**: AFTER Claude executes Write or Edit tool (file already written)

**Arguments**:
- `$1` = Tool name ("Write" or "Edit")
- `$2` = File path that was written/edited

**Purpose**: Validate file content, run linters, can undo bad writes

**Example Use Cases**:
- Check file content for forbidden patterns
- Run linters/formatters
- Validate syntax
- Check file size
- Undo writes that violate rules

**Exit Codes**:
- `0` = Keep the write
- `2` = Undo the write

**Example**:
```bash
#!/bin/bash
TOOL_NAME="$1"
FILE_PATH="$2"

# Check for console.log in production code
if [[ "$FILE_PATH" =~ \.tsx$ ]]; then
  if grep -q "console\.log" "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: console.log found" >&2
    echo "   Remove before committing" >&2
    exit 2  # Undo the write
  fi
fi

exit 0  # Keep the write
```

### 3. Stop Hook (`pre-stop.sh`)

**When**: Claude tries to stop/complete the conversation

**Arguments**: None

**Purpose**: Final validation before finishing

**Example Use Cases**:
- Run tests
- Check for uncommitted changes
- Verify build passes
- Check linter passes
- Ensure documentation updated

**Exit Codes**:
- `0` = Allow stopping
- `2` = Block stopping (Claude must continue)

**Example**:
```bash
#!/bin/bash

# Check for uncommitted changes
if ! git diff --quiet 2>/dev/null; then
  echo "❌ BLOCKED: Uncommitted changes exist" >&2
  echo "   Commit changes before stopping" >&2
  exit 2
fi

# Run tests
if command -v npm &> /dev/null; then
  if ! npm test --silent 2>/dev/null; then
    echo "❌ BLOCKED: Tests failing" >&2
    exit 2
  fi
fi

exit 0  # Allow stopping
```

### 4. SessionStart Hook (`session-start.sh`)

**When**: Conversation starts (or after context compaction)

**Arguments**: None

**Purpose**: Re-inject critical rules into Claude's context

**Output**:
- **stdout** → Goes into Claude's context
- **stderr** → Goes to logs only

**Example Use Cases**:
- Display critical rules
- Check environment
- Show git branch
- Remind about workflow
- Display warnings

**Exit Codes**: Ignored (always continues)

**Example**:
```bash
#!/bin/bash

# This goes to logs only (stderr)
echo "🚀 [SESSION-START] Loading rules..." >&2

# This goes into Claude's context (stdout)
cat <<'EOF'
⚠️ CRITICAL PROJECT STANDARDS:
1. TypeScript only - no .js files
2. Shared CSS only - no app CSS
3. Mac = code only, Pi = build
EOF

# Check environment (stderr only)
if ! command -v node &> /dev/null; then
  echo "⚠️  WARNING: Node.js not found" >&2
fi
```

---

## Writing Effective Rules

### Pattern: File Extension Checks

```bash
# Block specific extensions
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: No CSS files" >&2
  exit 2
fi

# Block multiple extensions
if [[ "$FILE_PATH" =~ \.(css|scss|sass)$ ]]; then
  echo "❌ BLOCKED: No style files" >&2
  exit 2
fi
```

### Pattern: Directory Restrictions

```bash
# Block files in specific directory
if [[ "$FILE_PATH" =~ ^src/forbidden/ ]]; then
  echo "❌ BLOCKED: Cannot write to src/forbidden/" >&2
  exit 2
fi

# Block with exceptions
if [[ "$FILE_PATH" =~ ^src/components/.*\.css$ ]]; then
  # Allow *-board.css
  if [[ ! "$FILE_PATH" =~ -board\.css$ ]]; then
    echo "❌ BLOCKED: No CSS except *-board.css" >&2
    exit 2
  fi
fi
```

### Pattern: Content Checks (PostToolUse)

```bash
# Only check if file exists (already written)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check for forbidden patterns
if grep -q "FORBIDDEN_PATTERN" "$FILE_PATH" 2>/dev/null; then
  echo "❌ BLOCKED: Contains forbidden pattern" >&2
  exit 2
fi

# Check for missing patterns
if ! grep -q "REQUIRED_PATTERN" "$FILE_PATH" 2>/dev/null; then
  echo "❌ BLOCKED: Missing required pattern" >&2
  exit 2
fi
```

### Pattern: Warnings vs. Errors

```bash
# Warning (don't block)
if [[ "$FILE_PATH" =~ \.js$ ]]; then
  echo "⚠️  WARNING: Consider using TypeScript" >&2
  exit 0  # Allow but warn
fi

# Error (block)
if [[ "$FILE_PATH" =~ \.js$ ]]; then
  echo "❌ BLOCKED: Use TypeScript" >&2
  exit 2  # Block
fi
```

### Pattern: Environment-Specific Rules

```bash
# Detect Mac
if [[ "$(uname)" == "Darwin" ]]; then
  # Mac-specific rules
  if [[ "$FILE_PATH" =~ ^build/ ]]; then
    echo "❌ BLOCKED: Don't build on Mac" >&2
    exit 2
  fi
fi

# Detect Linux
if [[ "$(uname)" == "Linux" ]]; then
  # Linux-specific rules
fi

# Detect container
if [[ -f /.dockerenv ]]; then
  # Container-specific rules
fi
```

---

## Testing Your Rules

### Test Manually

```bash
# Test pre-write hook
cd /path/to/your/project
bash .claude/hooks/pre-write.sh Write src/App.css
echo $?  # 0 = allowed, 2 = blocked

# Test with real file
touch /tmp/test.css
bash .claude/hooks/pre-write.sh Write /tmp/test.css

# Test post-write hook (file must exist)
echo "console.log('test')" > /tmp/test.tsx
bash .claude/hooks/post-write.sh Write /tmp/test.tsx

# Test stop hook
bash .claude/hooks/pre-stop.sh
```

### Test with Claude

**Phase 1: Verify hooks fire**
1. Restart Claude Code
2. Ask Claude to edit ANY file
3. Look for hook messages in output
4. If you see messages → hooks working!

**Phase 2: Test blocking**
1. Add a blocking rule to pre-write.sh
2. Ask Claude to violate that rule
3. Watch Claude get blocked
4. Verify Claude adjusts approach
5. Success!

### Example Test Session

**You**: "Create a file called App.css"

**Claude**: *Tries to write App.css*

**Hook Output**:
```
🔍 [PRE-WRITE] Claude wants to Write: src/App.css
❌ BLOCKED: CSS files forbidden
   Use shared CSS classes instead
```

**Claude**: "I cannot create App.css due to project standards. I'll use shared CSS classes instead..."

---

## Common Patterns

### Copy-Paste Ready Examples

**1. Enforce TypeScript**
```bash
# In pre-write.sh
if [[ "$FILE_PATH" =~ ^src/.*\.jsx?$ ]]; then
  echo "❌ BLOCKED: Use .tsx not .js" >&2
  exit 2
fi
```

**2. Enforce Shared CSS**
```bash
# In pre-write.sh
if [[ "$FILE_PATH" =~ (App|index|styles)\.css$ ]]; then
  echo "❌ BLOCKED: Use shared CSS" >&2
  exit 2
fi
```

**3. Block Localhost**
```bash
# In pre-write.sh
if [[ "$FILE_PATH" =~ \.(sql|json)$ ]] && [ -f "$FILE_PATH" ]; then
  if grep -q "localhost" "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: Use placeholder not localhost" >&2
    exit 2
  fi
fi
```

**4. Require Tests Pass**
```bash
# In pre-stop.sh
if ! npm test --silent 2>/dev/null; then
  echo "❌ BLOCKED: Tests must pass" >&2
  exit 2
fi
```

**5. Warn About TODOs**
```bash
# In post-write.sh
if [ -f "$FILE_PATH" ]; then
  TODO_COUNT=$(grep -c "TODO" "$FILE_PATH" 2>/dev/null || echo 0)
  if [ "$TODO_COUNT" -gt 0 ]; then
    echo "⚠️  WARNING: $TODO_COUNT TODO(s) in file" >&2
  fi
fi
```

---

## Debugging

### Enable Verbose Output

```bash
# Add to top of any hook
set -x  # Print commands as they execute
```

### Check Hook Execution

```bash
# Run hook manually with debug output
bash -x .claude/hooks/pre-write.sh Write test.txt
```

### View Claude Code Logs

```bash
# Check Claude Code logs
tail -f ~/.claude/logs/claude-code.log
```

### Test Regex Patterns

```bash
# Test file path matching
FILE_PATH="src/App.css"
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "Match!"
fi

# Test with real files
for file in src/*.tsx; do
  if [[ "$file" =~ \.tsx$ ]]; then
    echo "$file matches"
  fi
done
```

---

## Best Practices

### 1. Start Small
- Install template first (Phase 1)
- Verify hooks work
- Add 1-2 critical rules
- Test thoroughly
- Add more rules incrementally

### 2. Be Clear with Messages
```bash
# ❌ Bad: Vague
echo "Not allowed" >&2

# ✅ Good: Specific
echo "❌ BLOCKED: CSS files forbidden" >&2
echo "   Use shared CSS classes instead" >&2
echo "   Reference: Component Library" >&2
```

### 3. Use Exit Codes Correctly
- `exit 0` = Success, allow/continue
- `exit 2` = Block operation
- **Don't use**: `exit 1` (undefined behavior)

### 4. Check File Exists for Content Checks
```bash
# Always check file exists first
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Now safe to read file
grep "pattern" "$FILE_PATH"
```

### 5. Make Hooks Portable
```bash
# ✅ Good: Use $FILE_PATH variable
if [[ "$FILE_PATH" =~ \.css$ ]]; then

# ❌ Bad: Hardcode paths
if [[ "$2" =~ \.css$ ]]; then
```

### 6. Document Your Rules
```bash
# In each hook, explain what it does
# ============================================================
# PROJECT RULES:
# 1. No CSS files (use shared classes)
# 2. TypeScript only (no .js)
# 3. Mac = code only (no builds)
# ============================================================
```

---

## Migration Guide

### From Git Pre-commit Hooks

**Old (Git hook)**:
- Runs AFTER code is written
- Catches violations too late
- Claude already spent time writing bad code

**New (Claude Code hook)**:
- Runs BEFORE code is written
- Prevents violations
- Saves time/money

**Keep both**:
```
Claude Code Hook → Prevents bad code
        ↓
   (Code written)
        ↓
Git Pre-commit → Last line of defense
```

### From Documentation Only

**Before**: CLAUDE.md says "No CSS files"
- Claude forgets mid-conversation
- Context compaction loses rules
- Manual enforcement required

**After**: Hook blocks CSS files
- Claude physically cannot create CSS
- Persists across conversations
- Automatic enforcement

---

## Sharing with Team

### Commit Hooks to Repo

```bash
# Keep .claude/ in Git
git add .claude/
git commit -m "Add Claude Code enforcement hooks"
git push
```

**Team members**:
1. Pull repo
2. Restart Claude Code
3. Hooks automatically active

### Keep Hooks Private

```bash
# Add to .gitignore
echo ".claude/" >> .gitignore
```

**Team members**:
- Each runs `bootstrap-enforcement.sh` independently
- Customize hooks locally

---

## FAQ

**Q: Can I have different rules for different directories?**
```bash
if [[ "$FILE_PATH" =~ ^src/legacy/ ]]; then
  # Legacy code: relaxed rules
  exit 0
elif [[ "$FILE_PATH" =~ ^src/new/ ]]; then
  # New code: strict rules
  # ... strict checks ...
fi
```

**Q: Can hooks run other scripts?**
```bash
# In pre-write.sh
bash "$(dirname "$0")/rules/typescript.sh" "$@"
bash "$(dirname "$0")/rules/css.sh" "$@"
```

**Q: Can hooks modify files?**
No - hooks should only check and block/allow. Use linters/formatters separately.

**Q: Do hooks slow down Claude?**
Minimal - simple checks take <10ms. Keep hooks fast.

**Q: Can I disable hooks temporarily?**
```bash
mv .claude/settings.json .claude/settings.json.disabled
# Restart Claude Code
```

---

## Examples from Real Projects

See `examples/` directory for complete, tested rule implementations:
- `typescript-rules.sh` - Enforce TypeScript
- `css-rules.sh` - Enforce shared CSS
- `workflow-rules.sh` - Mac/Pi split workflow
- `security-quality-rules.sh` - Security checks

---

## Version History

- v1.0.0 (2026-03-12) - Initial release

---

## Support

For issues or questions:
1. Check this guide
2. Review examples in `examples/`
3. Test hooks manually
4. Check Claude Code logs

---

## Next Steps

1. ✅ Install hooks in your project
2. ✅ Restart Claude Code
3. ✅ Test hooks fire
4. ✅ Add 1-2 critical rules
5. ✅ Test blocking works
6. ✅ Add more rules as needed
7. ✅ Share with team (optional)

**Remember**: Start simple, prove it works, then build incrementally.
