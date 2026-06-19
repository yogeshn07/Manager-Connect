# Production Readiness Checklist

## Purpose

This checklist must be completed and signed off before every production release. No release proceeds unless all P0 items are checked. P1 items should be checked or have an accepted exception documented.

**Release Version:** ___________  
**Reviewed By:** ___________  
**Date:** ___________

---

## 1. Functionality

### P0 — Must Pass

- [ ] All V1 functional requirements implemented (see `functional-requirements.md`)
- [ ] Invite flow: admin can invite a user, user can register via invite link
- [ ] OTP authentication works on iOS and Android with email and SMS
- [ ] User can complete profile creation after first login
- [ ] Community feed loads, posts display, reactions and comments work
- [ ] Activity can be created, RSVPed to, and cancelled
- [ ] Activity reminder push notifications fire at 24h and 1h
- [ ] Wellness challenge can be created, joined, and progress logged
- [ ] Leaderboard reflects correct cumulative totals
- [ ] Recognition can be posted; recipient receives push notification
- [ ] Admin can invite, deactivate, and remove members
- [ ] Admin can view and resolve flagged content
- [ ] Push notification taps deep-link to correct screen
- [ ] Notification preferences can be configured per category
- [ ] Session persists across app restarts and background/foreground cycles

### P1 — Should Pass

- [ ] Empty states displayed correctly for all list screens
- [ ] Loading skeletons shown while data is fetching
- [ ] Error states shown with retry option on API failure
- [ ] Offline banner appears when device has no network connection
- [ ] Cached content visible when offline
- [ ] Past activities appear in archive view
- [ ] Ended challenges appear in completed challenges view

---

## 2. Performance

### P0

- [ ] Feed loads first 20 posts in under 1.5 seconds on 4G
- [ ] App cold start to usable screen in under 3 seconds (mid-range Android device)
- [ ] Image uploads complete in under 5 seconds for a 4 MB photo

### P1

- [ ] No visible jank (dropped frames) during tab switching
- [ ] Realtime subscriptions reconnect automatically after network loss

---

## 3. Security

### P0

- [ ] No Supabase service role key present in the app bundle (verify with `strings` or bundle analysis)
- [ ] All database tables have RLS enabled — verified with non-admin session API calls
- [ ] Auth tokens stored in Expo SecureStore (not AsyncStorage) — verified on iOS and Android
- [ ] Invite tokens are single-use: second use of same token is rejected
- [ ] Invite tokens expire after 72 hours: expired token is rejected
- [ ] Admin actions are recorded in the audit log: verify 5 different action types
- [ ] DM conversations: verified admin cannot access via direct API call
- [ ] User removed: verify their session is immediately invalidated
- [ ] Image upload: verify only accepted MIME types (jpg, png, webp) are accepted

### P1

- [ ] OWASP Mobile Top 10 review document completed
- [ ] Push notification deep links do not allow open redirect (malformed URLs rejected)
- [ ] API rate limiting reviewed (Supabase quota headroom confirmed)

---

## 4. Device Testing

### P0 — Test on Each Device

| Test Scenario | iPhone (Latest) | iPhone (n–1 iOS) | Android Flagship | Android Mid-Range |
|--------------|----------------|------------------|------------------|-------------------|
| Onboarding (invite → profile) | [ ] | [ ] | [ ] | [ ] |
| Create activity + RSVP | [ ] | [ ] | [ ] | [ ] |
| Post recognition + notification | [ ] | [ ] | [ ] | [ ] |
| Send DM | [ ] | [ ] | [ ] | [ ] |
| Log challenge progress | [ ] | [ ] | [ ] | [ ] |
| Notification tap → deep link | [ ] | [ ] | [ ] | [ ] |
| App background/foreground session | [ ] | [ ] | [ ] | [ ] |
| Offline mode (airplane mode) | [ ] | [ ] | [ ] | [ ] |

---

## 5. Deployment Infrastructure

### P0

- [ ] Production Supabase project provisioned (separate from staging)
- [ ] All DB migrations applied to production and verified
- [ ] All Edge Functions deployed to production
- [ ] Environment variables confirmed in EAS Secrets (production profile)
- [ ] PostHog production project configured with correct API key
- [ ] EAS Build (production profile) completed without errors — iOS
- [ ] EAS Build (production profile) completed without errors — Android
- [ ] App Store Connect: app metadata, screenshots, and privacy policy submitted
- [ ] Google Play Console: app metadata and screenshots submitted
- [ ] App Store review approved
- [ ] Google Play review approved

### P1

- [ ] Supabase automated backups confirmed active on production project
- [ ] GitHub Actions CI pipeline passing on latest main commit
- [ ] EAS Update (OTA) tested: push a test update, confirm it appears on device

---

## 6. Admin Readiness

### P0

- [ ] Admin user created and verified in production
- [ ] Admin can access admin panel and all sections are functional
- [ ] Admin briefing completed: user invite flow, moderation, pinned announcements
- [ ] At least 3 members invited and onboarded successfully in production
- [ ] Admin has documented process for inviting remaining members

---

## 7. Monitoring

### P0

- [ ] Expo error logs accessible for production builds
- [ ] Supabase logs accessible (Edge Function logs, Auth logs)
- [ ] PostHog events visible: `app_opened`, `post_created`, `activity_rsvp_submitted`

### P1

- [ ] Alerting configured for Edge Function errors (Supabase or external alert)

---

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Developer | | | |
| Admin / Platform Owner | | | |

**Release approved:** Yes / No  
**Notes / Exceptions:**
