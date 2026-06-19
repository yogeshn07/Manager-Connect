# Deployment Strategy

## Overview

Manager Connect is a React Native (Expo) mobile application deployed to the Apple App Store and Google Play Store. The backend is Supabase (managed cloud). Deployment is fully automated via **EAS (Expo Application Services)** for the mobile app and **Supabase CLI** for backend changes.

---

## Environments

| Environment | Purpose | Access |
|-------------|---------|--------|
| Development | Local development on simulators and personal devices | Developers only |
| Staging | Integration testing and pre-release validation | Team + internal testers |
| Production | Live app for 15–20 managers | Invited members only |

### Environment Separation

- Development: `supabase start` (local Supabase instance via Docker)
- Staging: Dedicated Supabase project (`manager-connect-staging`)
- Production: Dedicated Supabase project (`manager-connect-prod`)

Each environment has its own set of keys stored in EAS Secrets and CI environment variables. No environment shares credentials with another.

---

## Mobile App Build: EAS Build

**Tool:** Expo Application Services (EAS Build)  
**Config:** `eas.json`

### Build Profiles

```json
{
  "build": {
    "development": {
      "distribution": "internal",
      "developmentClient": true
    },
    "staging": {
      "distribution": "internal",
      "channel": "staging"
    },
    "production": {
      "distribution": "store",
      "channel": "production"
    }
  }
}
```

### Build Triggers

| Trigger | Build Profile | Distribution |
|---------|---------------|--------------|
| Push to `develop` | `staging` | Internal (TestFlight + Internal Play Track) |
| Tag `v*.*.*` on `main` | `production` | App Store + Google Play |
| Manual trigger | `development` | Developer device via QR code |

---

## OTA Updates: EAS Update

For non-native changes (JS bundle, assets), use **EAS Update** to push updates without a full App Store submission:

- OTA updates deploy to the `staging` or `production` channel immediately.
- Users receive the update on next app open (background download).
- OTA is used for: bug fixes, UI copy changes, configuration updates.
- OTA is NOT used for: new native modules, permission changes, Expo SDK upgrades.

OTA update command:
```bash
eas update --channel production --message "fix: correct activity time display"
```

---

## App Store Submission: EAS Submit

Automated via EAS Submit for both platforms:

```bash
eas submit --platform all --profile production
```

**iOS (Apple App Store):**
- App Connect API key stored in EAS Secrets.
- Build submitted to App Store Review.
- Private/internal app (invite-only download via TestFlight or org-managed enterprise distribution).

**Android (Google Play):**
- Service account JSON stored in EAS Secrets.
- Build submitted to Internal Testing Track first, then promoted to Production Track.

---

## Backend Deployment: Supabase

### Database Migrations

- Migrations are SQL files in `supabase/migrations/` and version-controlled.
- Apply to staging: `supabase db push --project-ref <staging-ref>`
- Apply to production: `supabase db push --project-ref <prod-ref>` (run after staging validation)
- Migrations are applied before the new mobile app build is submitted.
- Never apply a migration to production without first applying and validating on staging.

### Edge Functions

- Functions in `supabase/functions/`.
- Deploy to staging: `supabase functions deploy --project-ref <staging-ref>`
- Deploy to production: `supabase functions deploy --project-ref <prod-ref>`
- Functions are deployed atomically (new version replaces old immediately).

### Storage Bucket Configuration

- Bucket policies are managed via migration scripts.
- CDN configuration is set in the Supabase dashboard and documented in `docs/database-strategy.md`.

---

## CI/CD Pipeline

**Tool:** GitHub Actions

### Workflow: PR Validation
Triggers on: PR opened or updated against `main`
Steps:
1. Install dependencies
2. Run TypeScript type-check
3. Run ESLint
4. Run unit tests (Jest)
5. Run integration tests (Supabase local)

### Workflow: Staging Deployment
Triggers on: merge to `main` or `develop`
Steps:
1. All PR validation steps
2. Apply DB migrations to staging
3. Deploy Edge Functions to staging
4. Trigger EAS Build (staging profile)
5. Distribute to internal testers (TestFlight / Play Internal)

### Workflow: Production Release
Triggers on: new `v*.*.*` tag on `main`
Steps:
1. All PR validation steps
2. Apply DB migrations to production
3. Deploy Edge Functions to production
4. Trigger EAS Build (production profile)
5. EAS Submit to App Store and Google Play

---

## Rollback Procedures

| Scenario | Rollback Approach |
|----------|-------------------|
| OTA update causes regression | Push a new OTA update reverting the change (instant) |
| Native app regression | Submit a patch release `v*.*.X+1` via full App Store submission |
| DB migration regression | Apply a reverse migration SQL manually via Supabase dashboard |
| Edge Function regression | Redeploy previous function version from git history |

---

## Secrets Management

| Secret | Storage |
|--------|---------|
| Supabase URL + anon key (all envs) | EAS Secrets per environment profile |
| Supabase service role key (CI only) | GitHub Actions Secrets — never in app bundle |
| Apple App Store Connect API key | EAS Secrets |
| Google Play service account JSON | EAS Secrets |
| Expo push notification credentials | EAS managed (automatic via EAS credentials) |
| PostHog API key | EAS Secrets per environment |

No secrets are committed to the repository. `.env` is in `.gitignore`.
