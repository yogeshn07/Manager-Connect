# Commit Conventions

## Standard: Conventional Commits

Manager Connect follows the **Conventional Commits** specification (v1.0.0). This enables automated changelog generation, clear PR history, and consistent communication across the team.

Reference: https://www.conventionalcommits.org/

---

## Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

### Rules
- Type and scope: **lowercase**
- Description: **imperative mood** — "add" not "adds" or "added"
- Description: **no period** at the end
- Max line length: **72 characters** for the summary line
- Body: wrapped at 100 characters, explains *why* not *what*

---

## Types

| Type | Use When |
|------|----------|
| `feat` | A new user-facing feature is added |
| `fix` | A bug fix that corrects existing behavior |
| `chore` | Build process, dependency updates, config changes |
| `docs` | Documentation changes only |
| `style` | Formatting, whitespace, no logic change |
| `refactor` | Code restructuring with no behavior change |
| `test` | Adding or correcting tests |
| `perf` | A change that improves performance |
| `ci` | Changes to CI/CD configuration or scripts |
| `revert` | Reverts a previous commit |

---

## Scopes

Scopes map to feature modules:

| Scope | Module |
|-------|--------|
| `auth` | Authentication module |
| `profile` | User profile module |
| `feed` | Community feed module |
| `activities` | Activities module |
| `wellness` | Wellness challenges module |
| `recognition` | Recognition wall module |
| `messages` | Messaging module |
| `admin` | Admin panel module |
| `notifications` | Push notifications |
| `db` | Database migrations |
| `ci` | CI/CD pipeline |
| `deps` | Dependencies |

---

## Examples

### Feature commit
```
feat(activities): add calendar toggle view to activities list
```

### Bug fix
```
fix(notifications): correct push token not refreshing on re-login
```

### Database migration
```
chore(db): add index on messages.conversation_id for performance
```

### Dependency update
```
chore(deps): upgrade expo-notifications to v0.28.0
```

### Breaking change (with footer)
```
feat(auth)!: switch OTP delivery from email to mobile-first

BREAKING CHANGE: Users previously registered with email-only
must update their profile with a mobile number before next login.
```

### Test addition
```
test(wellness): add unit tests for leaderboard ranking calculation
```

### Documentation
```
docs: update api-guidelines with file upload path conventions
```

---

## Enforcement

- **Husky** + **commitlint** enforce the format on every commit.
- Config: `@commitlint/config-conventional` in `commitlint.config.js`.
- Invalid commit messages are rejected before the commit is created.
- Developers are prompted to fix the message before proceeding.

---

## PR Title Convention

Pull Request titles must also follow the conventional commit format. The PR title becomes the squash merge commit message on `main`. Example:

```
feat(recognition): add emoji reactions to recognition wall
```

GitHub branch protection rule enforces this via PR title lint in CI.

---

## Changelog Generation

- A `CHANGELOG.md` is generated automatically from commit history on each release tag.
- Tool: `conventional-changelog-cli` or `release-it`.
- Only `feat`, `fix`, and `perf` commits appear in the user-facing changelog.
- Breaking changes are prominently listed at the top.
