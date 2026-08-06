# CI/CD Pipeline

## Overview

GitHub Actions pipeline for Manager Connect with three workflows:
1. **CI** — runs on every PR (lint, analyze, test, build)
2. **Deploy Edge Functions** — deploys Supabase functions on merge to main
3. **Deploy Web** — builds Flutter web and deploys to hosting on merge to main

## Prerequisites

### GitHub Repository Secrets

Configure these in Settings → Secrets and variables → Actions:

| Secret | Description |
|--------|-------------|
| `SUPABASE_URL` | Production project URL |
| `SUPABASE_ANON_KEY` | Production anon/public key |
| `SUPABASE_SERVICE_ROLE_KEY` | Production service role key |
| `SUPABASE_PROJECT_REF` | Project reference ID (from URL) |
| `SUPABASE_ACCESS_TOKEN` | Personal access token for CLI |
| `FIREBASE_API_KEY` | Firebase web API key |
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender ID |
| `FIREBASE_APP_ID` | Firebase app ID |

### Generate Supabase Access Token

1. Go to [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)
2. Generate new token: `github-actions-deploy`
3. Save as `SUPABASE_ACCESS_TOKEN` secret

---

## Workflow 1: CI (Pull Requests)

**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.7'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --no-fatal-infos

      - name: Run tests
        run: flutter test

      - name: Build web (verify compilation)
        run: |
          flutter build web --no-web-resources-cdn \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

---

## Workflow 2: Deploy Edge Functions

**File:** `.github/workflows/deploy-functions.yml`

```yaml
name: Deploy Edge Functions

on:
  push:
    branches: [main]
    paths:
      - 'backend/supabase/functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Deploy all functions
        run: supabase functions deploy --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
        working-directory: backend
```

---

## Workflow 3: Deploy Web

**File:** `.github/workflows/deploy-web.yml`

```yaml
name: Deploy Web

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.7'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: |
          flutter build web --release --no-web-resources-cdn \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
            --dart-define=FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }} \
            --dart-define=FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }} \
            --dart-define=FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }} \
            --dart-define=FIREBASE_STORAGE_BUCKET=${{ secrets.FIREBASE_STORAGE_BUCKET }} \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }} \
            --dart-define=FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }}

      # Option A: Deploy to Vercel
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: frontend/build/web
          vercel-args: '--prod'

      # Option B: Deploy to Firebase Hosting (alternative)
      # - name: Deploy to Firebase Hosting
      #   uses: FirebaseExtended/action-hosting-deploy@v0
      #   with:
      #     repoToken: ${{ secrets.GITHUB_TOKEN }}
      #     firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
      #     projectId: ${{ secrets.FIREBASE_PROJECT_ID }}
      #     channelId: live
```

---

## Workflow 4: Deploy Migrations

**File:** `.github/workflows/deploy-migrations.yml`

```yaml
name: Deploy Migrations

on:
  push:
    branches: [main]
    paths:
      - 'backend/supabase/migrations/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Push migrations
        run: supabase db push --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
        working-directory: backend
```

---

## Hosting Options

### Option A: Vercel (Recommended for pilot)

1. Create Vercel account
2. Import project → set output directory to `frontend/build/web`
3. Configure SPA: add `vercel.json` with rewrite rules

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

4. Get token + org ID + project ID → add to GitHub secrets

### Option B: Firebase Hosting

1. `firebase init hosting` → public directory: `frontend/build/web`
2. Configure as SPA: Yes
3. `firebase.json`:

```json
{
  "hosting": {
    "public": "frontend/build/web",
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      {
        "source": "**/*.@(js|css|wasm)",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      }
    ]
  }
}
```

### Option C: Supabase Hosting (if available in your region)

```bash
supabase hosting deploy --project-ref <ref> frontend/build/web
```

---

## Branch Strategy

| Branch | Purpose | Deploys To |
|--------|---------|-----------|
| `main` | Production | Production hosting + Supabase cloud |
| `develop` | Integration | N/A (local testing) |
| `feature/*` | Feature branches | N/A (CI only) |

For pilot, a single `main` branch with direct pushes is sufficient. Add branch protection rules when the team grows.

---

## Manual Deployment (Pilot Fallback)

If CI/CD is not set up yet, deploy manually:

```bash
# 1. Build
cd frontend
flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=FIREBASE_API_KEY=AIza... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_APP_ID=...

# 2. Deploy web
npx vercel frontend/build/web --prod
# or
firebase deploy --only hosting

# 3. Deploy Edge Functions
cd ../backend
supabase functions deploy --project-ref <ref>

# 4. Push migrations (if any)
supabase db push --project-ref <ref>
```
