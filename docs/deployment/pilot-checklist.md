# Pilot Deployment Checklist

## Release Target

**Pilot:** 10-50 managers for internal beta testing
**Current Readiness:** 86% (post-remediation)
**Estimated Hours to Pilot:** 30 hours

---

## Phase 1: Infrastructure Setup (8 hours)

### 1.1 Supabase Production (4 hours)

- [ ] Create Supabase cloud project (`manager-connect-prod`)
- [ ] Record Project URL, Anon Key, Service Role Key, JWT Secret
- [ ] Store database password in password manager
- [ ] Configure Auth settings:
  - [ ] Enable Email provider
  - [ ] Disable public sign-up (invite-only)
  - [ ] Set Site URL to production domain
  - [ ] Add redirect URLs
  - [ ] Customize OTP email template
- [ ] Push all 74 migrations (`supabase db push`)
- [ ] Verify: 26 tables exist
- [ ] Verify: 122 RLS policies (114 public + 8 storage)
- [ ] Verify: 8 tables in realtime publication
- [ ] Verify: 2 storage buckets (avatars, post-images)
- [ ] Apply seed data (Connect Buddy system account)
- [ ] Deploy all 21 Edge Functions
- [ ] Set Edge Function secrets (service role key, FCM key)
- [ ] Test: call one Edge Function via curl

### 1.2 Domain & Hosting (2 hours)

- [ ] Register or configure domain/subdomain
- [ ] Set up hosting provider (Vercel / Firebase Hosting / Netlify)
- [ ] Configure SPA rewrite rules (all routes → index.html)
- [ ] Configure SSL (auto via hosting provider)
- [ ] Test: access domain in browser → shows loading indicator

### 1.3 Firebase Project (2 hours)

- [ ] Create Firebase project (`manager-connect-prod`)
- [ ] Add Web app, copy config values
- [ ] Enable Cloud Messaging API (V1)
- [ ] Create `firebase-messaging-sw.js` service worker
- [ ] Store FCM Server Key in Supabase secrets
- [ ] Store Firebase config values in CI/CD secrets

---

## Phase 2: Build & Deploy (4 hours)

### 2.1 First Production Build (2 hours)

- [ ] Build with all dart-defines:
  ```
  flutter build web --release --no-web-resources-cdn \
    --dart-define=SUPABASE_URL=... \
    --dart-define=SUPABASE_ANON_KEY=... \
    --dart-define=FIREBASE_API_KEY=... \
    --dart-define=FIREBASE_AUTH_DOMAIN=... \
    --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=FIREBASE_STORAGE_BUCKET=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
    --dart-define=FIREBASE_APP_ID=...
  ```
- [ ] Verify build completes without errors
- [ ] Deploy to hosting provider
- [ ] Verify: site loads at production URL
- [ ] Verify: loading indicator appears during CanvasKit init

### 2.2 Smoke Test on Production (2 hours)

- [ ] **Auth:** Request OTP → receive email → verify code → logged in
- [ ] **Profile:** Create profile → displays correctly
- [ ] **Feed:** Create post → appears in feed
- [ ] **Feed:** Add comment → appears inline
- [ ] **Feed:** Add reaction → toggles correctly
- [ ] **Events:** Create event → RSVP → confirmed
- [ ] **Polls:** Create poll → vote → results display
- [ ] **Challenges:** Create challenge → join → log progress
- [ ] **Recognition:** Send recognition → appears in feed
- [ ] **Notifications:** Receive notification → badge updates → deep link works
- [ ] **Admin:** Access dashboard → invite user → manage members
- [ ] **Logout:** Sign out → redirected to welcome screen

---

## Phase 3: Monitoring & Safety (4 hours)

### 3.1 Error Monitoring (2 hours)

- [ ] Create Sentry project
- [ ] Add `sentry_flutter` to dependencies
- [ ] Wrap `main()` with `SentryFlutter.init`
- [ ] Add SENTRY_DSN to build dart-defines
- [ ] Add SENTRY_DSN to Edge Function secrets
- [ ] Configure alert rules (new error, spike, unhandled)
- [ ] Test: trigger error → verify Sentry captures it

### 3.2 Uptime & Backups (2 hours)

- [ ] Set up uptime monitor (UptimeRobot or equivalent)
- [ ] Verify Supabase PITR is enabled
- [ ] Run first manual database export (`supabase db dump`)
- [ ] Store backup in separate location
- [ ] Set up weekly backup GitHub Action (optional)

---

## Phase 4: User Onboarding (4 hours)

### 4.1 Admin Setup (1 hour)

- [ ] Create admin account via OTP
- [ ] Create admin profile
- [ ] Verify admin role assigned (database: `profiles.role = 'admin'`)
- [ ] Test all admin actions from production

### 4.2 Pilot User Invitations (2 hours)

- [ ] Prepare list of pilot users (email addresses)
- [ ] Send invitations via Admin → Invitation Management
- [ ] Verify invitation emails delivered
- [ ] Test: pilot user accepts invitation → creates profile → sees feed

### 4.3 Seed Content (1 hour)

- [ ] Create welcome post from admin account
- [ ] Create first event (e.g., "Manager Connect Kickoff")
- [ ] Create first poll (e.g., "What topics interest you most?")
- [ ] Create first challenge (e.g., "1:1 Meeting Streak")
- [ ] Send first recognition (welcome message)

---

## Phase 5: CI/CD Setup (4 hours)

### 5.1 GitHub Actions (4 hours)

- [ ] Add all secrets to GitHub repository
- [ ] Create `.github/workflows/ci.yml` (PR checks)
- [ ] Create `.github/workflows/deploy-web.yml` (web deploy)
- [ ] Create `.github/workflows/deploy-functions.yml` (EF deploy)
- [ ] Create `.github/workflows/deploy-migrations.yml` (DB migrations)
- [ ] Test: push to main → verify auto-deploy works

---

## Known Limitations (Accepted for Pilot)

| Limitation | Impact | Workaround |
|-----------|--------|-----------|
| No image upload UI | Profiles show default avatars | Upload via Supabase dashboard |
| No @mention UI | Cannot tag users in posts | Use display names in text |
| No other-user profile view | Cannot click to see colleagues | View in member list (admin) |
| Web first-load ~15-20s | Slow initial experience | Loading indicator in place |
| OTP may arrive as magic link | Auth UX not ideal | Configure email template |
| Stories rail is static | Not connected to data | Cosmetic, acceptable |

---

## Go / No-Go Decision

### Go Criteria (all must be true)

| Criteria | Status |
|----------|--------|
| Production Supabase running with all migrations | [ ] |
| Site accessible via HTTPS on production domain | [ ] |
| Auth flow works end-to-end (OTP → profile → feed) | [ ] |
| All 21 Edge Functions responding | [ ] |
| Admin can invite and manage users | [ ] |
| Error monitoring active (Sentry) | [ ] |
| At least 1 backup completed | [ ] |
| Smoke test passed (12/12 checks) | [ ] |

### No-Go Conditions

- Any of the Go criteria not met
- RLS policy count < 122 (security gap)
- Edge Functions returning 500 errors
- OTP emails not delivering
- No error monitoring in place

---

## Post-Launch (First 2 Weeks)

- [ ] Monitor Sentry daily for new errors
- [ ] Check Supabase metrics daily (connections, API calls, errors)
- [ ] Collect user feedback (Slack channel or in-app)
- [ ] Fix any critical bugs within 24 hours
- [ ] Run first database backup verification
- [ ] Review pilot metrics (DAU, posts/day, feature usage)
- [ ] Decide: expand pilot or address feedback first

---

## Estimated Total: 24-30 hours

| Phase | Hours | Dependency |
|-------|-------|-----------|
| Infrastructure Setup | 8 | None |
| Build & Deploy | 4 | Phase 1 |
| Monitoring & Safety | 4 | Phase 2 |
| User Onboarding | 4 | Phase 2 |
| CI/CD Setup | 4 | Phase 1 |
| Buffer / issues | 6 | — |
| **Total** | **30** | — |

Phases 3, 4, and 5 can run in parallel after Phase 2 completes.
