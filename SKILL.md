---
name: forbear-patterns
description: Coding patterns and workflows extracted from forbear UI framework
version: 1.0.0
source: local-git-analysis
analyzed_commits: 279
repository: forbear
language: Zig
---

# Forbear Development Patterns

Generated from analysis of 279 commits in the forbear repository.

## Commit Conventions

Forbear uses **conventional commits** with platform-specific scopes:

### Commit Prefixes (by frequency)
- `fix:` - Bug fixes (75% of conventional commits)
- `feat:` - New features (20% of conventional commits)
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

### Commit Message Patterns

```bash
# Feature commits with PR numbers
feat: text shape caching with an LRU (#9)
feat: manual element placement (#8)
feat: text wrapping (#7)

# Platform-specific fixes
fix(linux): high CPU usage due to event message processing (#10)

# Standard fixes
fix: handle hovering out when there's no hovering in another element

# Chore commits
chore: improve hook error messages
```

### Guidelines
- Always include PR number in merge commits: `(#N)`
- Use platform scopes when applicable: `fix(linux):`, `fix(macos):`, `fix(windows):`
- Keep subjects concise and descriptive
- Lowercase after prefix (except proper nouns)

## Project Architecture

### Core File Structure

```
forbear/
├── src/
│   ├── graphics.zig         # Most frequently modified (92 changes)
│   ├── root.zig              # Public API exports (31 changes)
│   ├── layouting.zig         # Layout algorithm (24 changes)
│   ├── node.zig              # UI node types (22 changes)
│   ├── font.zig              # FreeType font handling (11 changes)
│   ├── components.zig        # Component system
│   ├── c.zig                 # Centralized C imports (14 changes)
│   └── window/
│       ├── root.zig          # Platform abstraction
│       ├── linux.zig         # Wayland implementation
│       ├── macos.zig         # macOS implementation
│       └── windows.zig       # Windows implementation
├── shaders/
│   ├── element/              # UI element shaders (vertex/fragment)
│   ├── shadow/               # Shadow rendering shaders
│   └── text/                 # Text rendering shaders
├── playground.zig            # Primary test/example app (47 changes)
├── build.zig                 # Build configuration
└── CLAUDE.md → AGENTS.md     # Agent instructions (symlinked)
```

### Key Insights
- **graphics.zig** is the most active file (92 changes) - changes here often indicate rendering work
- **playground.zig** (47 changes) is the primary testing ground - features are tested here
- Platform-specific code is isolated in `src/window/` subdirectories
- Shaders are organized by functionality (element, shadow, text)

## Development Workflows

### Adding a New Feature

Based on commit patterns, feature development follows this workflow:

1. **Implement Core Logic**
   - Primary changes in `src/graphics.zig`, `src/node.zig`, or `src/layouting.zig`
   - Add new style properties to style structs
   - Update rendering pipeline if needed

2. **Update Shaders (if needed)**
   - Modify shaders in `shaders/element/`, `shaders/shadow/`, or `shaders/text/`
   - Both vertex and fragment shaders often change together
   - Build system auto-compiles GLSL to SPIR-V

3. **Test in Playground**
   - Update `playground.zig` to demonstrate the feature
   - Run with `zig build run`

4. **Create PR with Descriptive Commit**
   ```bash
   git commit -m "feat: descriptive feature name (#PR_NUMBER)"
   ```

### Platform-Specific Fixes

Pattern observed: `fix(platform):` commits target specific window implementations

1. **Identify Platform Issue**
   - Linux issues → `src/window/linux.zig`
   - macOS issues → `src/window/macos.zig`
   - Windows issues → `src/window/windows.zig`

2. **Implement Fix**
   - Make minimal changes to platform-specific file
   - Test on target platform
   - Verify no regressions on other platforms

3. **Commit with Platform Scope**
   ```bash
   git commit -m "fix(linux): description of the fix"
   ```

### Common Co-Change Patterns

Files that frequently change together:

- **graphics.zig + playground.zig** (rendering changes + testing)
- **graphics.zig + shaders/** (rendering pipeline + shader updates)
- **node.zig + layouting.zig** (node structure + layout algorithm)
- **window/root.zig + window/{platform}.zig** (platform abstraction + implementation)

## Code Style Patterns (from git history)

### Naming Conventions

```zig
// Hook-based APIs (recent pattern)
useFont()          // Font loading hook
useImage()         // Image loading hook
useTransition()    // Animation hook

// Style properties (camelCase)
fontWeight         // Font weight for variable fonts
translate          // Element translation

// Functions (camelCase)
ensureNoError()
findMemoryType()
```

### Common Commit Subjects

- "update {file/dependency}" - Dependency or configuration updates
- "add {feature}" - New functionality without formal feat: prefix
- "fix {specific issue}" - Targeted bug fixes
- "optimize {component}" - Performance improvements
- "missing {fix}" - Quick fixes for omissions
- "use {pattern}" - Refactoring to use a pattern

### Error Handling Patterns

From commit messages:
- "fix error" - Resolving compilation or runtime errors
- "fix missing parameter" - API signature fixes
- "improve error handling" - Better error messages

## Testing and Verification

### Build Verification Commands

```bash
# Standard build
zig build

# Run playground (primary test application)
zig build run

# Run all tests
zig build test

# Verify all code compiles (includes examples)
zig build check

# Release build
zig build --release=fast
```

### Testing Pattern
- Changes are tested in `playground.zig` (47 changes indicate active use)
- No dedicated test file structure detected in git history
- `zig build check` verifies all examples compile

## Recent Development Trends

### Feature Additions (Last 30 Days)
1. **Text shape caching with LRU** - Performance optimization
2. **Manual element placement** - Layout flexibility
3. **Text wrapping** - Text rendering improvement
4. **Font weight support** - Variable fonts
5. **Animations** - Transition support
6. **Component system** - Compositional UI
7. **Event handling** - Hover and interaction
8. **Shadow rendering** - Visual effects

### Performance Focus
- "optimize spirv" - Shader optimization
- "fix(linux): high CPU usage" - Platform performance
- "use a more performant event" - Windows optimization
- Text shape caching - Rendering optimization

### Code Quality Patterns
- "format" commits indicate manual formatting runs
- "code improvements" - Regular refactoring
- "standardize" - Consistency improvements
- Arena allocator pattern emphasized in recent commits

## Dependencies and Build

### External Dependencies
- **FreeType** - Font rendering
- **kb_text_shape** - Text shaping (frequently updated)
- **zmath** - Math library
- **stb_image** - Image loading
- **Vulkan** - Graphics API

### Platform Requirements
- **Linux**: Wayland support
- **macOS**: MoltenVK for Vulkan
- **Windows**: Win32 API

## Documentation Pattern

### In-Repository Documentation
- `CLAUDE.md` (symlinked to `AGENTS.md`) - Agent/developer guidelines
- `TODO.md` - Task tracking (5 changes, actively maintained)
- `notes/` directory:
  - `open-questions.md` - Design decisions
  - `text-selection.md` - Implementation notes

### Documentation Update Pattern
Commits like "add more open questions", "update todo" indicate:
- Active planning in TODO.md
- Design decisions tracked in notes/
- Questions documented before implementation

## Anti-Patterns to Avoid

Based on fix commits:
1. **"fix typo"** - Careful with documentation/comments
2. **"fix missing parameter"** - Verify function signatures
3. **"missing arena reset"** - Remember to reset arena allocators
4. **"removeu useless comment"** - Clean up as you go
5. **"fix the size of"** - Double-check dimensions and calculations

## Success Patterns

Commit messages indicating good practices:
- "always pass allocators as the first parameter" - Consistency rule
- "use defer for X so it runs in errors too" - Proper cleanup
- "add the timeout to X again" - Reverting problematic changes
- "have the same behavior as the browser" - Parity with expectations

---

## Quick Reference

### When Making Changes

1. **Read before modifying**: Check existing patterns in target files
2. **Test in playground**: Verify changes in `playground.zig`
3. **Platform-specific**: Isolate to `src/window/{platform}.zig`
4. **Shader changes**: Update both vertex and fragment together
5. **Use conventional commits**: `feat:`, `fix:`, with optional scope

### Most Critical Files

| File | Purpose | Change Frequency |
|------|---------|------------------|
| src/graphics.zig | Vulkan rendering | Very High (92) |
| playground.zig | Testing & examples | High (47) |
| src/root.zig | Public API | High (31) |
| src/layouting.zig | Layout algorithm | Medium (24) |
| src/node.zig | UI node types | Medium (22) |

### Common Commands

```bash
zig build run              # Test changes in playground
zig build check            # Verify all examples compile
zig build test             # Run test suite
zig fmt src/              # Format code
git commit -m "feat: X"   # Commit with convention
```
