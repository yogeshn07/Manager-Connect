# Release Plan

## Release Philosophy

Manager Connect follows a staged release approach. Each release is validated on staging with real testers before promotion to production. The user base is small (15–20 managers), so personal communication accompanies every release.

---

## Version Scheme

Semantic versioning: `MAJOR.MINOR.PATCH`

| Component | When to increment |
|-----------|-------------------|
| MAJOR | Breaking UX change or complete architecture overhaul |
| MINOR | New feature or module released |
| PATCH | Bug fix, performance improvement, copy change |

---

## V1.0.0 — Foundation Release (Initial Launch)

**Target:** Week 10 from kickoff  
**Status:** Planned

### Included Features
- Invite-only registration and OTP authentication
- User profiles with interest tags
- Community feed (posts, photos, reactions, comments)
- Activities and outings (create, RSVP, reminders)
- Wellness challenges (create, join, log progress, leaderboard)
- Recognition wall (give and receive shout-outs)
- Direct messages and community group chat
- Push notifications for all feature categories
- Admin panel (user management, moderation, pinned announcements)

### Launch Criteria
- All V1 functional requirements implemented and tested
- Production readiness checklist completed
- Internal team testing completed on iOS and Android
- Admin briefing completed (how to manage users, moderate content)
- App Store and Google Play submissions approved
- Supabase production project provisioned and migrated
- 3 founding members (including admin) onboarded and verified

### Launch Communication
- Admin sends personalized invite to each of the 15-20 managers
- Brief Slack/email announcement: what Manager Connect is, how to join, what to expect
- Short 2-minute walkthrough video recorded by admin (optional)

---

## V1.1.0 — Engagement Boost

**Target:** 4–6 weeks after V1.0.0 launch  
**Status:** Planned (pending V1.0 learnings)

### Candidate Features
- Event calendar view (monthly/weekly) for activities
- Interest-based member search / discovery
- Profile view: recognitions received and given history
- Notification batching (reduce noise for group chat)
- OTA performance improvements based on V1.0 metrics

### Trigger
Released based on user feedback collected in the first month. Features deprioritized if usage shows different priorities.

---

## V1.2.0 — Enrichment

**Target:** 8–10 weeks after V1.0.0 launch  
**Status:** Conceptual

### Candidate Features
- Polls for activity decisions ("Where should we go this Saturday?")
- Reaction analytics: most recognized member this month (admin view)
- Anonymous suggestion box
- Challenge category tags (Running / Cycling / General Wellness)

---

## V2.0.0 — Platform Maturity

**Target:** 6 months post-launch  
**Status:** Vision (see future-enhancements.md)

### Candidate Features
- Health platform integration (Apple Health, Google Fit) for automatic step syncing
- Achievements and badges system
- Web dashboard for admin (read-only companion)
- Expanded user base (up to 50 managers or cross-department rollout)

---

## Release Process (Per Version)

```
Feature complete on staging
       ↓
Internal QA (team tests on devices — iOS and Android)
       ↓
Fix any blocking bugs
       ↓
Production readiness checklist passed
       ↓
Apply DB migrations to production
       ↓
Deploy Edge Functions to production
       ↓
Submit app build via EAS Submit
       ↓
App Store / Play Store review (1–3 business days)
       ↓
Version approved — release to users
       ↓
Admin notifies members of new version
       ↓
Monitor for 48 hours: crash reports, user feedback
```

---

## Hotfix Process

For critical bugs discovered post-release:
1. Create `hotfix/` branch from the release tag.
2. Apply fix, test locally.
3. Tag `v*.*.X+1`.
4. Submit via EAS Submit (expedited review if needed for iOS).
5. For JS-only bugs: deploy OTA update via `eas update --channel production`.

---

## App Store Metadata

| Field | Value |
|-------|-------|
| App Name | Manager Connect |
| Category | Business / Productivity (Social) |
| Age Rating | 4+ (no user-generated public content) |
| Distribution | Private / Invite-only (no public search visibility) |
| Localization | English (V1) |
| Privacy Policy | Required — internal org policy URL |

---

## Release Notes Template

```
Version X.X.X — [Month Year]

What's new:
- [Feature 1 in plain language]
- [Feature 2 in plain language]

Improvements:
- [Fix or improvement]

How to update: Your app updates automatically. Open the app to get the latest version.
```
