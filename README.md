# Claude Code Enforcement System

**Systematic enforcement of project standards in Claude Code conversations**

## The Problem

When working with Claude Code:
- Documentation gets ignored as conversations grow
- Context compaction loses critical standards
- Claude makes assumptions instead of following rules
- Violations caught by Git hooks are too late (code already written)
- Time/money wasted rewriting non-compliant code

## The Solution

**Hooks** that run BEFORE Claude writes code:
- ✅ Block violations before they happen
- ✅ Persist across conversations (not in context)
- ✅ Survive context compaction
- ✅ Force compliance or operations fail
- ✅ Save time by preventing bad code, not fixing it

## Quick Start

### 1. Install in Your Project

```bash
cd /path/to/your/project
~/Documents/Projects/claude-code-enforcement/bootstrap-enforcement.sh
```

Or add to PATH:
```bash
# Add to ~/.zshrc or ~/.bashrc:
export PATH="$HOME/Documents/Projects/claude-code-enforcement:$PATH"

# Then from any project:
cd /path/to/your/project
bootstrap-enforcement.sh
```

### 2. Restart Claude Code

**Required** - Claude Code must restart to load `.claude/settings.json`

### 3. Test It Works

Ask Claude to edit a file. You should see:
```
🔍 [PRE-WRITE] Claude wants to Edit: some-file.tsx
✅ [PRE-WRITE] No violations detected - allowing operation
📝 [POST-WRITE] Claude completed Edit: some-file.tsx
```

If you see these messages → hooks are working!

### 4. Add Your Rules

Edit `.claude/hooks/*.sh` to add project-specific enforcement:

```bash
# Example: Block CSS files
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: Use shared styles" >&2
  exit 2
fi
```

See `examples/` directory for complete rule implementations.

---

## How It Works

### The Hook Types

| Hook | When It Runs | Purpose | Can Block? |
|------|-------------|---------|-----------|
| **PreToolUse** | BEFORE Write/Edit | Prevent violations | ✅ Yes |
| **PostToolUse** | AFTER Write/Edit | Validate/undo | ✅ Yes |
| **Stop** | When Claude stops | Final checks | ✅ Yes |
| **SessionStart** | Conversation start | Re-inject rules | ❌ No |

### Exit Codes

| Code | Meaning | Result |
|------|---------|--------|
| `0` | Success | Operation allowed/continues |
| `2` | Block | Operation blocked, Claude gets feedback |

### Example: Blocking a Violation

**Claude tries:**
```
Write file: src/App.css
```

**Your pre-write.sh hook:**
```bash
if [[ "$FILE_PATH" =~ \.css$ ]]; then
  echo "❌ BLOCKED: No CSS files" >&2
  exit 2
fi
```

**Result:**
- Write is blocked
- Claude sees: "❌ BLOCKED: No CSS files"
- Claude adjusts approach
- **No time wasted writing bad code**

---

## Project Structure

```
claude-code-enforcement/
├── README.md                    # This file
├── bootstrap-enforcement.sh     # Universal installer
├── templates/                   # Template hooks (stubs)
│   ├── pre-write.sh            # BEFORE write/edit
│   ├── post-write.sh           # AFTER write/edit
│   ├── pre-stop.sh             # Before stopping
│   └── session-start.sh        # Session initialization
├── examples/                    # Example rule implementations
│   ├── typescript-rules.sh     # Enforce TypeScript
│   ├── css-rules.sh            # Enforce shared CSS
│   ├── workflow-rules.sh       # Mac/Pi workflow
│   └── security-quality-rules.sh # Security checks
└── docs/
    └── USAGE.md                # Detailed usage guide
```

---

## Example Rules

### 1. Enforce TypeScript (No .js files)

```bash
# .claude/hooks/pre-write.sh
if [[ "$FILE_PATH" =~ ^src/.*\.jsx?$ ]]; then
  echo "❌ BLOCKED: Use .tsx not .js" >&2
  exit 2
fi
```

### 2. Enforce Shared CSS (No app CSS)

```bash
# .claude/hooks/pre-write.sh
if [[ "$FILE_PATH" =~ (App|index|styles)\.css$ ]]; then
  echo "❌ BLOCKED: Use shared CSS classes" >&2
  exit 2
fi
```

### 3. Block Localhost in Config

```bash
# .claude/hooks/pre-write.sh
if [[ "$FILE_PATH" =~ \.(sql|json)$ ]]; then
  if grep -q "localhost" "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: Use {host} placeholder" >&2
    exit 2
  fi
fi
```

### 4. Require Tests to Pass Before Stopping

```bash
# .claude/hooks/pre-stop.sh
if ! npm test --silent 2>/dev/null; then
  echo "❌ BLOCKED: Fix failing tests" >&2
  exit 2
fi
```

**See `examples/` directory for complete, copy-paste ready implementations.**

---

## Two-Phase Approach

### Phase 1: Install Template (Prove It Works)

1. Run `bootstrap-enforcement.sh`
2. Restart Claude Code
3. Edit a file → see hook messages
4. **Success: Hooks are working!**

### Phase 2: Add Rules (Incremental)

1. Start with 1-2 critical rules
2. Test by triggering violations
3. Verify Claude is blocked
4. Add more rules as needed

**Don't over-engineer Phase 1** - just prove hooks work, then build incrementally.

---

## Real-World Use Cases

### Solo Developer with Mac/Pi Split

**Problem**: Claude suggests `npm build` on Mac (doesn't have npm)

**Solution**:
```bash
# .claude/hooks/session-start.sh
echo "⚠️ Mac = Code only. Pi = Build/test."
```

### Microservices with Shared Design System

**Problem**: Developers create app-specific CSS instead of using shared classes

**Solution**:
```bash
# .claude/hooks/pre-write.sh
# Block CSS files, enforce shared classes
# See examples/css-rules.sh
```

### TypeScript Migration

**Problem**: Claude creates .js files instead of .ts

**Solution**:
```bash
# .claude/hooks/pre-write.sh
# Block .js/.jsx, require .ts/.tsx
# See examples/typescript-rules.sh
```

---

## Advanced Usage

### Combining Multiple Rule Sets

```bash
# .claude/hooks/pre-write.sh
#!/bin/bash
TOOL_NAME="$1"
FILE_PATH="$2"

# Source multiple rule sets
source "$(dirname "$0")/rules/typescript.sh"
source "$(dirname "$0")/rules/css.sh"
source "$(dirname "$0")/rules/workflow.sh"

# All rules run, first exit 2 blocks the operation
```

### Environment-Specific Rules

```bash
# .claude/hooks/pre-write.sh
if [[ "$(uname)" == "Darwin" ]]; then
  # Mac-specific rules
  # Block build artifacts
fi

if [[ -f /.dockerenv ]]; then
  # Container-specific rules
  # Allow build artifacts
fi
```

### Testing Hooks Manually

```bash
# Test pre-write hook
bash .claude/hooks/pre-write.sh Write src/App.css
echo $?  # 0 = allowed, 2 = blocked

# Test with real file
touch /tmp/test.css
bash .claude/hooks/pre-write.sh Write /tmp/test.css
```

---

## FAQ

**Q: Do hooks run on my build server?**
A: No. Hooks run where Claude Code runs (your editing machine).

**Q: Can I use this with a team?**
A: Yes! Commit `.claude/` to your repo. Everyone gets same enforcement.

**Q: What if I need to violate a rule temporarily?**
A: Disable hooks: `mv .claude/settings.json .claude/settings.json.disabled`

**Q: Do other projects get these hooks?**
A: No. Each project needs its own `.claude/` directory (project-scoped).

**Q: Can hooks prevent Claude from suggesting bad code?**
A: No. Hooks block execution, not suggestions. You may still need to interrupt Claude.

**Q: What about context compaction?**
A: Hooks persist in settings (not context). SessionStart hook can re-inject rules post-compaction.

**Q: Are hooks committed to Git?**
A: Your choice. Commit to share with team, or add `.claude/` to `.gitignore`.

---

## Troubleshooting

### Hooks Not Firing

1. **Restart Claude Code** (required after installing)
2. Check `.claude/settings.json` exists
3. Check hooks are executable: `chmod +x .claude/hooks/*.sh`
4. Test manually: `bash .claude/hooks/pre-write.sh Write test.txt`

### Hook Blocks Incorrectly

1. Edit `.claude/hooks/pre-write.sh`
2. Fix the rule logic
3. Save and try again (no restart needed)

### Need to Bypass Hook Temporarily

```bash
# Disable all hooks
mv .claude/settings.json .claude/settings.json.disabled

# Re-enable
mv .claude/settings.json.disabled .claude/settings.json
```

Restart Claude Code after changing settings.

---

## Benefits

### For Solo Developers
- ✅ Catches violations BEFORE code is written
- ✅ Saves time/money (no rewriting)
- ✅ Enforces consistency across conversations
- ✅ Survives context compaction
- ✅ Reusable across projects

### For Teams
- ✅ Same standards for everyone
- ✅ Self-documenting (rules are code)
- ✅ No manual enforcement needed
- ✅ Works with CI/CD

---

## Contributing

This is a personal project, but ideas welcome!

**To add your own examples:**
1. Create rule file in `examples/`
2. Document the use case
3. Make it copy-paste ready

---

## License

MIT License - Use freely in your projects

---

## References

- [Official Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [Claude Code CLI Documentation](https://docs.anthropic.com/claude-code)

---

## Version

v1.0.0 - Initial release (2026-03-12)

---

## Author

Created for use with Claude Code - helping AI assistants follow project standards consistently.
