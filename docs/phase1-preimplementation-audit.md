# Phase 1 Pre-Implementation Audit

## Cross-Reference Summary

| Artifact | profiles | invitations |
|----------|----------|-------------|
| Columns (schema design) | 15 | 11 |
| PK | `id` (uuid, FK→auth.users) | `id` (uuid, gen_random_uuid) |
| FKs | `id`→`auth.users.id` | `invited_by`→`profiles.id`, `accepted_by`→`profiles.id` |
| CHECK constraints | `app_role IN (member,admin,system)` | `status IN (pending,accepted,expired,revoked)` |
| UNIQUE constraints | PK only | `token_hash` |
| Indexes | 3 (active partial, role, system partial) | 2 (token_hash, status partial) |
| updated_at trigger | Yes | Yes |
| RLS policies | 5 | 5 |

## Conflicts Found

### CONFLICT-01: RLS column name mismatch — `used_by` vs `accepted_by`

**rls-security-policies.md** line 84:
```
invitations_select_own | SELECT | Member | [active-user-guard] AND used_by = auth.uid()
```

**database-schema-design.md** line 130:
```
accepted_by | uuid | NULL | — | FK → profiles.id | Profile created upon acceptance
```

The column is named `accepted_by` in the schema. The RLS policy references `used_by` which does not exist.

**Resolution:** Use `accepted_by` in the RLS policy SQL (schema design is the source of truth).

### CONFLICT-02: Migration plan #8 references `used_by`

**database-migrations-plan.md** line 93:
```
member (own used_by row only)
```

Same documentation mismatch. The SQL will use `accepted_by` (the actual column name).

## Verdict

Both conflicts are documentation-level name mismatches. The column is `accepted_by` per the authoritative schema design. The RLS SQL will use `accepted_by`. No structural or architectural conflicts.

**AUDIT PASSES — proceed with implementation.**
