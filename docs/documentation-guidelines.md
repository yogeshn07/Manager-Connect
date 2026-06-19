# Documentation Guidelines

## Principles

1. **Documentation lives in the repository.** All project docs are Markdown files under `docs/`. No wikis, Google Docs, or Notion pages for primary project documentation.
2. **Docs are code.** They are reviewed in PRs, versioned in git, and updated alongside the code they describe.
3. **Write for your future self.** A doc is useful if someone new to the project can onboard from it six months from now.
4. **Concise over comprehensive.** A short, accurate doc is better than an exhaustive, stale one.

---

## Document Types

| Type | Location | Purpose |
|------|----------|---------|
| Product docs | `docs/` | Vision, requirements, personas — the "why" |
| Architecture docs | `docs/` | System design decisions — the "how at scale" |
| Strategy docs | `docs/` | Feature-specific implementation approach |
| Developer guides | `docs/` | Process — branching, commits, coding standards |
| API types | `src/types/database.ts` | Auto-generated; do not document manually |
| Inline comments | Source files | Logic that isn't self-evident |

---

## Markdown Conventions

### Document Structure

Every document in `docs/` follows this structure:

```markdown
# Document Title

## Overview
Brief statement of purpose (2–4 sentences).

## Section 1
...

## Section 2
...
```

### Headings
- `#` — Document title only. One per file.
- `##` — Major sections.
- `###` — Sub-sections within a section.
- `####` — Use sparingly. Restructure if nesting goes deeper.

### Tables
Prefer tables over long bullet lists when presenting structured information with multiple attributes (e.g., requirements, risks, API fields).

### Code Blocks
Use fenced code blocks with a language specifier:
- ` ```typescript ` for TypeScript
- ` ```sql ` for SQL
- ` ```bash ` for shell commands
- ` ```json ` for JSON examples

### Links
- Internal doc links use relative paths: `[API Strategy](./api-strategy.md)`
- External links use full URLs with descriptive text.
- Do not link to internal ticket systems (URLs rot).

---

## When to Update Documentation

| Trigger | Required Update |
|---------|----------------|
| New feature merged | Update `functional-requirements.md` and `module-breakdown.md` if the feature is new |
| Architecture decision made | Update relevant strategy doc or create new ADR |
| Process change | Update the relevant process doc (branching, commits, deployment) |
| Deprecated behavior | Strike through or remove the old section with a note |
| New team member | Verify onboarding flow works end-to-end with the new person |

Documentation updates are part of the Definition of Done for any feature PR.

---

## Architecture Decision Records (ADRs)

Significant technical decisions are recorded as ADRs in `docs/decisions/`.

### ADR Format

```markdown
# ADR-NNN: Title of Decision

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN

## Context
What situation led to this decision?

## Decision
What was decided?

## Rationale
Why this option over alternatives?

## Consequences
What becomes easier? What becomes harder?
```

ADRs are immutable once accepted. If a decision is reversed, a new ADR is created that supersedes the old one. The old ADR is not deleted or modified.

---

## Inline Code Documentation

- **Do** comment: complex algorithms, non-obvious side effects, workarounds with ticket references.
- **Don't** comment: self-evident code, restating what the code does.
- Service functions: JSDoc with `@param`, `@returns`, and `@throws` for exported functions.
- Utility functions: JSDoc if the function name alone does not fully communicate behavior.

---

## Keeping Docs Fresh

- Documentation staleness is a bug. Treat it as one.
- If you find a doc that contradicts current behavior, fix it in the same PR as the code change.
- Quarterly: team reviews all docs in `docs/` for accuracy. Out-of-date sections are updated or removed.
- Auto-generated docs (Supabase types) are regenerated in CI — never manually edited.
