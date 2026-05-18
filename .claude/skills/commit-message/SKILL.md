---
name: commit-message
description: Use this skill whenever writing or revising a git commit message — normal commits, fix-up commits, version-bump commits, or PR title generation. Provides the `[type][Module]` format used across all projects under this config.
user-invocable: true
---

# Commit Message Format

Used for every git commit produced in this project.

## Format

```
[type][Module] Description (English, imperative mood)
```

- **type** is lowercase
- **Module** is PascalCase, project-specific — reuse a bracket that already appears in `git log`
- Description is **English**, imperative (`Add`, `Fix`, `Move`), no trailing period

## Allowed types

| Type | Use for |
|------|---------|
| `feat` | New user-visible feature |
| `fix` | Bug fix |
| `refactor` | Internal restructuring, no behavior change |
| `style` | Formatting only (whitespace, SwiftFormat output) |
| `docs` | Doc / comment / CLAUDE.md / spec change |
| `test` | Add or adjust tests |
| `chore` | Build, deps, tooling, release plumbing, internal config |
| `perf` | Performance change |
| `ci` | CI / CD config |

## Examples

```
[feat][Booking] Add designer filter to calendar day view
[fix][Printer] Keep thermal target when device name is empty
[refactor][Checkout] Split payment view controller into flow and view model
[test][API] Cover AutoDecode default values for optional fields
[chore][Deps] Bump Alamofire to 5.9.1
```

## Version-bump commit

Bump-version commits are prefixed with the rocket emoji and use module `[Release]`:

```
🚀 [chore][Release] Bump version to {version}+{build}
```

The 🚀 makes bump commits easy to spot in `git log` and is a stable anchor for changelog range queries.

## Hard rules

- **English subject only** — no Chinese subject lines
- **Imperative mood** — `Add X`, not `Added X` / `Adds X`
- **No trailing period**
- **Module bracket** — must match a module already used in the repo; don't invent. Run `git log --oneline -50` and reuse an existing bracket pattern.
- **Bump commits** — always use 🚀 prefix and `[chore][Release]`
