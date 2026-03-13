---
name: forbear-code-style
description: Applies Forbear's Zig code style: import ordering, naming, module structure, explicit ownership, cleanup patterns, comments, and formatting. Use for any Zig change in the repo.
---

# Forbear Code Style

## Use This Skill When

- Editing any Zig file in the repo
- Reviewing whether new code matches the surrounding Forbear style
- Cleaning up a diff so it reads like the existing codebase

## Primary Source

Use `AGENTS.md` as the authoritative source for repo conventions. This skill is the short operational checklist.

## Style Checklist

### Imports

Group imports in this order with blank lines between groups:

1. Standard library
2. Built-ins
3. External dependencies
4. Internal modules

### Naming

- PascalCase for types
- camelCase for functions, variables, and constants
- `snake_case.zig` for file names
- Preserve C names for direct interop

### Module shape

- Use `@This()` for self-referential struct methods.
- Keep vector aliases, error sets, and key types near the top.
- In files centered on one main type, put public surface before private helpers.
- Prefer small structs or tagged unions over long positional parameters.

### Control flow and comments

- Prefer direct control flow: local `if`/`switch`, early return, early assertion.
- Comments should explain a non-obvious invariant, lifecycle rule, or implementation choice.
- Do not add comments that merely narrate obvious code.

### Ownership and cleanup

- Pass allocators explicitly when ownership is real.
- Put allocator parameters first.
- Use `errdefer` on fallible initialization paths.
- Keep `init` / `deinit` pairs easy to match.
- Do not hide long-lived allocation behind convenience helpers.

### C interop and platform code

- Keep C imports centralized in `src/c.zig` when adding shared interop.
- Branch on `builtin.os.tag` for platform-specific behavior.
- Prefer `std.fs.File` for cross-platform file I/O.

### Zig footgun to remember

Zig inner functions do not capture outer locals. Pass values explicitly, and do not shadow the outer variable name in the inner function parameter.

## Validation

- Run `zig fmt` on touched Zig files.
- If the change is non-trivial, pair formatting with at least one relevant build or test command.
