# Branching Strategy

## Model: GitHub Flow (Simplified)

Manager Connect uses **GitHub Flow** — a lightweight branching model appropriate for a small team shipping to a managed app platform. It avoids the overhead of Gitflow while maintaining a clean, deployable `main` branch at all times.

---

## Branch Structure

```
main                    ← Always production-ready; protected
  └── feature/xxx       ← Feature development
  └── fix/xxx           ← Bug fixes
  └── chore/xxx         ← Non-functional changes (deps, config, docs)
  └── hotfix/xxx        ← Emergency production fixes
```

---

## Branch Descriptions

### `main`
- The single source of truth.
- Always represents the last released (or release-ready) state.
- **Protected:** No direct pushes. All changes via Pull Request with at least 1 reviewer approval.
- CI must pass before merge.
- Tagged on every release: `v1.0.0`, `v1.1.0`, etc.

### `feature/xxx`
- Created from `main` for all new feature work.
- Naming: `feature/activity-rsvp`, `feature/recognition-wall`.
- Short-lived: merged back to `main` when feature is complete and reviewed.
- Delete after merge.

### `fix/xxx`
- Created from `main` for non-emergency bug fixes.
- Naming: `fix/notification-token-refresh`, `fix/leaderboard-sort`.
- Merged via PR with review.

### `chore/xxx`
- For dependency upgrades, configuration changes, documentation updates.
- Naming: `chore/upgrade-expo-52`, `chore/update-api-guidelines`.
- Lighter review requirement (1 reviewer).

### `hotfix/xxx`
- **Rare.** Only for critical production bugs requiring immediate release.
- Created from the latest release tag on `main`.
- After merge, tag a new patch release immediately.
- Naming: `hotfix/auth-session-bug`.

---

## Pull Request Rules

1. Every change to `main` goes through a PR.
2. PR title follows commit convention: `feat: add wellness challenge leaderboard`.
3. PR description includes: what changed, why, how to test.
4. Minimum 1 reviewer approval required before merge.
5. All CI checks must pass (lint, type-check, unit tests, integration tests).
6. Branch must be up-to-date with `main` before merge (rebase or merge).
7. Squash merge is preferred for feature branches to keep `main` history clean.
8. Delete branch after merge.

---

## Merge Strategy

| Branch Type | Merge Strategy | Reason |
|-------------|----------------|--------|
| `feature/` | Squash merge | Clean linear history on main |
| `fix/` | Squash merge | Same |
| `chore/` | Squash merge | Same |
| `hotfix/` | Merge commit | Preserve hotfix context |

---

## Release Tagging

Every production build corresponds to a Git tag on `main`:

```
main
  ├── v1.0.0   ← Initial release
  ├── v1.0.1   ← Hotfix
  ├── v1.1.0   ← First feature update
  └── v1.2.0   ← Next feature update
```

Tags follow semantic versioning: `MAJOR.MINOR.PATCH`
- `MAJOR`: Breaking architecture or UX overhaul
- `MINOR`: New features added
- `PATCH`: Bug fixes, non-breaking updates

---

## CI Triggers

| Event | CI Action |
|-------|-----------|
| PR opened or updated | Run lint, type-check, unit + integration tests |
| Merge to `main` | Run full test suite + build preview (EAS) |
| Tag `v*.*.*` | Run full test suite + production build (EAS Submit) |

---

## Branch Lifecycle

1. Create branch from `main`: `git checkout -b feature/my-feature main`
2. Work, commit frequently with conventional commits.
3. Push and open PR.
4. Address review feedback.
5. Merge via squash.
6. Delete branch.
7. Pull latest `main` for your next branch.
