# Backup & Disaster Recovery

## 1. RPO / RTO Targets

| Tier | RPO (data loss tolerance) | RTO (downtime tolerance) |
|------|--------------------------|--------------------------|
| Pilot (10-50 users) | 24 hours | 4 hours |
| Production (100+ users) | 1 hour | 1 hour |

Current infrastructure (Supabase Pro plan) supports:
- **RPO: ~1 minute** (point-in-time recovery)
- **RTO: ~30 minutes** (restore from backup)

## 2. What Gets Backed Up

### Automatic (Supabase Pro Plan)

| Component | Backup Method | Frequency | Retention |
|-----------|--------------|-----------|-----------|
| PostgreSQL database | Point-in-time recovery (PITR) | Continuous WAL archival | 7 days |
| Database schema | Included in PITR | Continuous | 7 days |
| Storage objects (avatars, post-images) | S3-compatible replication | Automatic | Retained until deleted |
| Auth users | Part of database backup | Continuous | 7 days |

### Manual (Your Responsibility)

| Component | Backup Method | Frequency | Storage |
|-----------|--------------|-----------|---------|
| Edge Functions source | Git repository | Every commit | GitHub |
| Migrations | Git repository | Every commit | GitHub |
| Frontend source | Git repository | Every commit | GitHub |
| Supabase secrets | Password manager | On change | 1Password / Bitwarden |
| Environment variables | Password manager | On change | 1Password / Bitwarden |
| Firebase config | Password manager | On change | 1Password / Bitwarden |

### Not Backed Up (Ephemeral)

| Component | Why | Impact if Lost |
|-----------|-----|---------------|
| Supabase Edge Function logs | 7-day rolling window | Lose debug history |
| Realtime channel state | In-memory | Clients reconnect automatically |
| Browser local storage | Client-side only | User re-authenticates |

## 3. Database Backup Procedures

### Automatic PITR (Supabase Pro)

Enabled by default. No configuration needed.

To restore:
1. Dashboard → Settings → Database → Point in Time Recovery
2. Select timestamp to restore to
3. Confirm restore

**Warning:** PITR restore replaces the entire database. All data after the restore point is lost.

### Manual Database Export

For additional safety, export weekly:

```bash
# Export full database
supabase db dump --project-ref <ref> > backup_$(date +%Y%m%d).sql

# Export data only (no schema)
supabase db dump --project-ref <ref> --data-only > data_$(date +%Y%m%d).sql
```

Store exports in a separate location (e.g., encrypted cloud storage, not the same Supabase project).

### Automated Weekly Export (GitHub Actions)

```yaml
name: Weekly DB Backup

on:
  schedule:
    - cron: '0 2 * * 0'  # Sunday 2 AM UTC

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: supabase/setup-cli@v1

      - name: Export database
        run: |
          supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
          supabase db dump --project-ref ${{ secrets.SUPABASE_PROJECT_REF }} > backup.sql
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Upload backup artifact
        uses: actions/upload-artifact@v4
        with:
          name: db-backup-${{ github.run_id }}
          path: backup.sql
          retention-days: 30
```

## 4. Disaster Scenarios & Recovery

### Scenario 1: Accidental Data Deletion

**Example:** Admin accidentally deletes user records.

**Recovery:**
1. Use PITR to identify the timestamp before deletion
2. Restore database to that point
3. Alternatively: export the specific table from a backup and re-import

**Prevention:**
- RLS policies prevent unauthorized deletion
- Admin `remove-user` Edge Function soft-deletes (sets `is_active = false`)
- Add `ON DELETE RESTRICT` constraints for critical foreign keys

### Scenario 2: Bad Migration Deployed

**Example:** Migration drops a column or corrupts data.

**Recovery:**
1. Write a reversal migration immediately
2. Push reversal: `supabase db push`
3. If data was lost: restore from PITR to pre-migration point

**Prevention:**
- Always test migrations locally (`supabase db reset`) before pushing
- Review migration SQL in PR before merging
- Keep reversal migration ready for risky changes

### Scenario 3: Edge Function Crashes

**Example:** All Edge Functions return 500.

**Recovery:**
1. Check Supabase Edge Function logs for error
2. If code bug: revert in git, redeploy previous version
3. If Supabase outage: wait for [status.supabase.com](https://status.supabase.com)

```bash
git checkout <last-working-commit> -- backend/supabase/functions/
supabase functions deploy --project-ref <ref>
```

**Prevention:**
- Edge Functions have try/catch with structured error responses
- Each function is independently deployable

### Scenario 4: Supabase Service Outage

**Example:** Supabase region goes down.

**Recovery:**
1. Check [status.supabase.com](https://status.supabase.com)
2. Wait for resolution (Supabase manages infrastructure)
3. App shows error states gracefully (network error handling in repositories)

**Prevention (Production scale):**
- Consider multi-region setup
- Cache critical data client-side
- Display maintenance page if API unreachable

### Scenario 5: Compromised Credentials

**Example:** Service role key or database password leaked.

**Recovery:**
1. **Immediately** rotate the compromised key in Supabase Dashboard
2. Update all systems using that key:
   - CI/CD secrets (GitHub)
   - Edge Function secrets (`supabase secrets set`)
   - Any local .env files
3. Audit logs for unauthorized access
4. If data breach suspected: notify affected users

```bash
# Rotate Edge Function secrets
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<new-key> --project-ref <ref>

# Redeploy all functions to pick up new secret
supabase functions deploy --project-ref <ref>

# Rebuild and redeploy web (if anon key changed)
flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_ANON_KEY=<new-key> ...
```

### Scenario 6: Domain/Hosting Goes Down

**Example:** Vercel/Firebase Hosting is unreachable.

**Recovery:**
1. Deploy to alternative hosting provider
2. Update DNS to point to new host
3. The Flutter web build is a static site — any static host works

**Quick fallback:**
```bash
# Deploy to a different provider immediately
npx serve -s frontend/build/web -l 4200
# or deploy to any CDN/static host
```

## 5. Recovery Testing

### Quarterly Drill (Pilot Phase: do once before launch)

| Test | Steps | Pass Criteria |
|------|-------|---------------|
| PITR restore | Restore to 1 hour ago in a test project | Data matches expected state |
| Edge Function rollback | Deploy previous git commit's functions | Functions return 200 |
| Secret rotation | Rotate anon key, rebuild, redeploy | App works with new key |
| Manual backup restore | Import `backup.sql` into fresh project | Schema + data intact |

### Test Restore Procedure

```bash
# 1. Create a test project on Supabase
# 2. Import backup
supabase link --project-ref <test-project-ref>
psql <test-database-url> < backup.sql

# 3. Verify key tables
psql <test-database-url> -c "SELECT count(*) FROM profiles;"
psql <test-database-url> -c "SELECT count(*) FROM posts;"
psql <test-database-url> -c "SELECT count(*) FROM pg_policies;"
```

## 6. Contact & Escalation

| Issue | First Response | Escalation |
|-------|---------------|------------|
| App error | Check Sentry → fix and deploy | Roll back to last working version |
| Database issue | Check Supabase dashboard | PITR restore |
| Supabase outage | Check status.supabase.com | Supabase support (Pro plan) |
| Security incident | Rotate credentials immediately | Audit + notify users |

## 7. Checklist

- [ ] Verify PITR is enabled on Supabase Pro plan
- [ ] Set up weekly manual backup export (or GitHub Action)
- [ ] Store all secrets in password manager
- [ ] Document secret rotation procedure
- [ ] Test PITR restore once (on test project)
- [ ] Verify Edge Function rollback works
- [ ] Bookmark [status.supabase.com](https://status.supabase.com)
