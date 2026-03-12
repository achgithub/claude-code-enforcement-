# Next Steps for Claude Code Enforcement System

**Created**: 2026-03-12
**Status**: Ready for testing and pub-games-v3 rule examples

---

## What Was Just Completed

✅ Standalone Git repository created
✅ Bootstrap script with template hooks
✅ Example rules (TypeScript, CSS, workflow, security)
✅ Comprehensive documentation (README + USAGE guide)
✅ Pushed to GitHub: https://github.com/achgithub/claude-code-enforcement-

---

## Current State

- **Working directory**: Should be `~/Documents/Projects/claude-code-enforcement/`
- **Git status**: Clean, pushed to GitHub
- **Ready for**: Testing and adding pub-games-v3 examples

---

## Phase 1: Test Bootstrap Script Works

### Test in This Repo (Dogfooding)

**Goal**: Prove bootstrap script works by running it in its own repo

**Steps**:
1. Run bootstrap script in this directory:
   ```bash
   cd ~/Documents/Projects/claude-code-enforcement
   ./bootstrap-enforcement.sh
   ```

2. This creates `.claude/` directory with template hooks

3. **Restart Claude Code** (CRITICAL - hooks won't work until restart)

4. After restart, ask Claude to edit a file

5. **Expected output**:
   ```
   🔍 [PRE-WRITE] Claude wants to Edit: some-file.md
   ✅ [PRE-WRITE] No violations detected - allowing operation
   📝 [POST-WRITE] Claude completed Edit: some-file.md
   ```

6. **Success criteria**: If you see hook messages → Phase 1 complete!

---

## Phase 2: Add Pub-Games-v3 Example Rules

### Create Comprehensive Pub-Games Example

**File**: `examples/pub-games-rules.sh`

**Purpose**: Complete, copy-paste ready rules for pub-games-v3 project

**Rules to include**:

#### 1. CSS Architecture Rules
```bash
# Block app-specific CSS files
if [[ "$FILE_PATH" =~ games/.*/frontend/.*\.css$ ]]; then
  # Allow ONLY *-board.css (game rendering)
  if [[ ! "$FILE_PATH" =~ -board\.css$ ]]; then
    echo "❌ BLOCKED: App CSS forbidden" >&2
    echo "   Use Activity Hub classes (.ah-*)" >&2
    echo "   Reference: Component Library (port 5010)" >&2
    echo "   Exception: Only *-board.css allowed for game rendering" >&2
    exit 2
  fi
fi

# Block common CSS file names
if [[ "$FILE_PATH" =~ (App|index|styles?|main)\.css$ ]]; then
  echo "❌ BLOCKED: Use Activity Hub shared CSS" >&2
  exit 2
fi
```

#### 2. TypeScript Rules
```bash
# Block .js/.jsx in frontend/src (must be .tsx)
if [[ "$FILE_PATH" =~ games/.*/frontend/src/.*\.jsx?$ ]]; then
  echo "❌ BLOCKED: JavaScript forbidden in src/" >&2
  echo "   Use TypeScript: .tsx not .js/.jsx" >&2
  exit 2
fi
```

#### 3. Workflow Rules (Mac/Pi Split)
```bash
# Detect Mac
if [[ "$(uname)" == "Darwin" ]]; then
  # Block build artifacts on Mac
  if [[ "$FILE_PATH" =~ ^(games/.*/frontend/build|games/.*/backend/static)/.*\.(js|css)$ ]]; then
    echo "❌ BLOCKED: Do not commit build artifacts from Mac" >&2
    echo "   Mac: Code + commit ONLY" >&2
    echo "   Pi: Build + test (user does this)" >&2
    exit 2
  fi
fi
```

#### 4. SQL Migration Rules
```bash
# Block localhost in SQL files
if [[ "$FILE_PATH" =~ \.sql$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    if grep -q "localhost" "$FILE_PATH" 2>/dev/null; then
      echo "❌ BLOCKED: 'localhost' in SQL migration" >&2
      echo "   Use {host} placeholder instead" >&2
      exit 2
    fi
  fi
fi
```

#### 5. Shared CSS Loading Check (PostToolUse)
```bash
# Verify index.tsx loads shared CSS
if [[ "$FILE_PATH" =~ games/.*/frontend/src/index\.tsx$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    if ! grep -q "activity-hub.css" "$FILE_PATH" 2>/dev/null; then
      echo "⚠️  WARNING: index.tsx should load Activity Hub CSS" >&2
      echo "   Expected: link.href = 'http://\${window.location.hostname}:3001/shared/activity-hub.css'" >&2
    fi
  fi
fi
```

### SessionStart Hook Content
```bash
# Display pub-games-v3 standards
cat <<'EOF'

⚠️ PUB-GAMES-V3 STANDARDS (Enforced by Hooks):

1. CSS ARCHITECTURE:
   - NO app CSS files (App.css, index.css, styles.css)
   - Use Activity Hub shared classes (.ah-*)
   - ONLY exception: *-board.css for game rendering
   - Reference: Component Library (port 5010)

2. TYPESCRIPT REQUIRED:
   - NO .js or .jsx in games/*/frontend/src/
   - Must use .tsx

3. MAC/PI WORKFLOW:
   - Mac: Write code + commit ONLY
   - Pi: Build + test (user does it, not Claude)
   - NO npm/go commands on Mac

4. SQL MIGRATIONS:
   - NO localhost in URLs
   - Use {host} placeholder

5. SHARED CSS LOADING:
   - index.tsx must load from identity-shell:3001

These rules are ENFORCED. Violations will be blocked.
EOF
```

---

## Phase 3: Update Documentation

### Add Pub-Games Example to README

**In `README.md`**, add section:

```markdown
## Real-World Example: Pub-Games-v3

See `examples/pub-games-rules.sh` for a complete implementation enforcing:
- Shared CSS architecture (no app-specific CSS)
- TypeScript only (no .js files)
- Mac/Pi split workflow (no builds on Mac)
- SQL migration standards (no localhost)

This example shows how to combine multiple rule sets for a microservices platform.
```

### Update USAGE.md

Add pub-games as a detailed case study showing multi-rule enforcement.

---

## Phase 4: Test with Real Violations

### Create Test Violations

**In this repo**, try to trigger each rule:

1. **CSS violation**: Ask Claude to create `App.css`
   - Expected: Blocked with message

2. **TypeScript violation**: Ask Claude to create `test.js`
   - Expected: Blocked with message

3. **Localhost violation**: Ask Claude to create SQL with localhost
   - Expected: Blocked with message

4. **Success case**: Ask Claude to create `test.tsx`
   - Expected: Allowed

---

## Phase 5: Commit and Push

Once pub-games examples are added and tested:

```bash
git add examples/pub-games-rules.sh
git add README.md
git add USAGE.md
git commit -m "feat: add pub-games-v3 comprehensive rule examples"
git push
```

---

## Phase 6: Use in Pub-Games-v3

**Back in pub-games-v3**:

```bash
cd ~/Documents/Projects/pub-games-v3

# Run bootstrap
~/Documents/Projects/claude-code-enforcement/bootstrap-enforcement.sh

# Copy pub-games rules
cp ~/Documents/Projects/claude-code-enforcement/examples/pub-games-rules.sh .claude/hooks/pre-write.sh

# Restart Claude Code

# Test violations get blocked
```

---

## Important Notes

### Do NOT Forget

- **Always restart Claude Code** after changing `.claude/settings.json`
- **Test in this repo first** before using in pub-games-v3
- **Hooks run on Mac only** (where Claude Code runs, not on Pi)
- **Exit 0 = allow, Exit 2 = block** (don't use exit 1)

### Key Files

- `bootstrap-enforcement.sh` - The installer
- `templates/*.sh` - Template hooks (copied to projects)
- `examples/pub-games-rules.sh` - TO BE CREATED (pub-games specific)
- `.claude/hooks/*.sh` - TO BE CREATED (when testing dogfooding)

### Context Switches

When switching between enforcement repo and pub-games-v3:
- Each project has its own `.claude/` directory
- Enforcement repo: Add pub-games rules as examples
- Pub-games-v3: Use enforcement repo's bootstrap to install hooks

---

## Questions to Answer During Testing

1. ✅ Do hooks fire correctly? (messages appear)
2. ✅ Do blocks work? (exit 2 prevents operation)
3. ✅ Are error messages clear and actionable?
4. ✅ Do SessionStart hooks re-inject rules into context?
5. ✅ Can rules be combined (multiple checks in one hook)?

---

## Success Criteria

**Phase 1 Complete When**:
- Bootstrap script runs without errors
- `.claude/` directory created
- Hook messages appear when editing files

**Phase 2 Complete When**:
- `examples/pub-games-rules.sh` exists
- All 5 rule types implemented
- SessionStart hook has pub-games standards

**Phase 3 Complete When**:
- Documentation updated with pub-games example
- README shows real-world case study

**Phase 4 Complete When**:
- Test violations successfully blocked
- Test valid operations allowed
- Error messages verified as helpful

**Phase 5 Complete When**:
- Changes committed to Git
- Pushed to GitHub

**Phase 6 Complete When**:
- Pub-games-v3 has hooks installed
- Pub-games rules actively enforcing
- Claude blocked from violating standards

---

## GitHub Repository

**URL**: https://github.com/achgithub/claude-code-enforcement-

**Current status**: Initial commit pushed

**Next commit**: Add pub-games-v3 comprehensive examples

---

## When You Return to This Context

**Start here**:
1. Read this file (NEXT-STEPS.md)
2. Run Phase 1 (test bootstrap)
3. After restart, continue with Phase 2 (add pub-games rules)
4. Work through phases sequentially

**Don't skip Phase 1 testing** - prove it works before adding complex rules.

---

*This document ensures nothing is forgotten across context switches.*
