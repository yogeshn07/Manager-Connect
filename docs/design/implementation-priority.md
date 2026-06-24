# Manager Connect — Implementation Priority
> Version 1.0 · Recommended build order

---

## Strategy: Reusable Components First

Before building any screen, implement the complete component library. Every major screen reuses 6–10 components. Building screens before components guarantees duplication and inconsistency.

**Build order principle:** Infrastructure → Tokens → Components → Core Screens → Secondary Screens → Admin

---

## Phase 0: Foundation (Week 1–2)
> Must complete before writing any screen code.

### 0.1 Design tokens
- Import all color variables from `design-system.md`
- Set up CSS custom properties or theme provider
- Configure font families (sans, serif)
- Verify all color values match approved hex codes exactly

### 0.2 Base components (no business logic)
Build these as pure UI components with no API dependencies:

| Component | Priority |
|---|---|
| Avatar (all size variants + status dot) | Critical |
| Icon tile (all size variants) | Critical |
| Type pill / badge (all color variants) | Critical |
| Bottom navigation (member + admin) | Critical |
| Top bar (Type A logo, Type B back, Type C transparent) | Critical |
| Section header | High |
| Filter chip strip | High |
| Progress bar (track + fill) | High |
| Progress ring (SVG, 54px + 130px) | High |
| Action row (4-button) | High |
| Hero banner (all color variants) | High |
| Bottom sheet / modal | High |
| Empty state template | Medium |
| Error state template | Medium |

### 0.3 Auth screens
- Sign In
- Onboarding steps 1–3
- Session expiry handler
- Role-based routing guard

---

## Phase 1: Core Experience (Weeks 3–6)
> Must be working before any other module ships.

### 1.1 Feed module
**Why first:** The feed is the app's home screen and primary engagement surface. Every other module has a presence in the feed.

| Screen | Dependencies |
|---|---|
| Feed Home | Posts API, Users API, Stories API |
| Post Detail | Comments API, Reactions API |
| Post Composer (Update type only) | Posts API |

**Acceptance criteria:**
- Feed loads paginated post list
- All 5 post card types render correctly
- Post Detail shows full comment thread
- Reactions record and update in real time
- New comment appears immediately (optimistic update)

### 1.2 Profile — My Profile
**Why:** Identity is established in Phase 1. Every subsequent module references the profile.

| Screen | Dependencies |
|---|---|
| My Profile | Users API, Stats API |
| Activity Timeline | Activity API |

**Defer to Phase 2:** Recognition History, Achievement Gallery (require Challenges and Recognition APIs)

### 1.3 Notification Center (read-only)
**Why:** Notifications are required to drive return engagement from Phase 1 onward.

| Screen | Dependencies |
|---|---|
| Notification Center | Notifications API, Realtime channel |
| Recognition Alert Detail | Recognition API |

---

## Phase 2: Recognition & Events (Weeks 7–10)

### 2.1 Recognition system
**Build order:**
1. Recognition composer (in feed) — POST /recognitions
2. Recognition post card type (extends existing feed card)
3. Recognition History screen
4. Recognition notification deep link

**Key dependency:** Recognition is required before Achievement Gallery (achievements unlock via recognitions).

### 2.2 Events module
**Build order:**
1. Events Hub
2. Event Detail
3. RSVP Experience + RSVP API
4. Event Attendees
5. Past Events Archive

**Defer to Phase 3:** Event Gallery (requires media storage setup)

### 2.3 Profile completion
- Achievement Gallery (requires achievement API from Challenges)
- Manager Profile (other user view)

---

## Phase 3: Challenges & Gamification (Weeks 11–14)

### 3.1 Challenges core
**Build order:**
1. Challenges Home
2. Challenge Detail (with progress ring and day-pip calendar)
3. Log activity flow (bottom sheet + API)
4. Streak Center
5. Challenge Leaderboard

### 3.2 Wellness Hub
**Why after core challenges:** Wellness uses the same challenge infrastructure — reuses challenge cards, streak API, progress components.

### 3.3 Gamification layer
1. Achievement badges (requires challenge completion events)
2. Milestones & Rewards
3. Personal Growth Dashboard
4. Monthly Community Challenge

### 3.4 Advanced feed post types
- Poll card (requires polling API)
- Event card in feed (requires event module from Phase 2)
- Achievement post card

---

## Phase 4: Notifications & Analytics (Weeks 15–18)

### 4.1 Full notifications
| Screen | Priority |
|---|---|
| Activity Inbox | High |
| Mentions Hub | High |
| Event Updates | Medium |
| Challenge Updates | Medium |
| Digest Summary | Medium |

**Note:** Digest requires a server-side aggregation job. Build the API endpoint first, then the screen.

### 4.2 Analytics
**Build order:**
1. Analytics Home (uses existing KPI data from other modules)
2. Personal Insights
3. Community Health
4. Recognition Insights
5. Rankings (uses leaderboard data from Challenges)
6. Monthly Review
7. Executive Summary (senior_leader role gate + PDF export)

---

## Phase 5: Admin Module (Weeks 19–22)

**Build order:**
1. Admin Home
2. User Management + Invitation Management
3. Content Moderation (highest priority — safety feature)
4. Event Administration (organizer-facing)
5. Challenge Administration
6. Recognition Management
7. Community Overview
8. Community Health Review + Analytics Administration

---

## Phase 6: Polish & Pre-Launch (Weeks 23–24)

| Task | Notes |
|---|---|
| Event Gallery | Media upload/display, S3 integration |
| Post Composer — all types | Poll, Event, Recognition composers |
| Onboarding flow | All 3 steps with skip logic |
| Empty states | All modules (see empty-states.md) |
| Error states | All scenarios (see error-states.md) |
| Push notification integration | Deep link routing for all notification types |
| Accessibility audit | Contrast fixes, touch targets (see design-system.md audit) |
| Performance | Pagination, lazy loading, image optimization |
| LIVE pill fix | Increase contrast to pass WCAG AA |
| Admin touch targets | Increase action button height to 32px minimum |

---

## Dependency Graph

```
Phase 0 (tokens + base components)
    ↓
Phase 1 (Feed + basic Profile + Notifications)
    ↓
Phase 2 (Recognition + Events + Profile completion)
    ↓
Phase 3 (Challenges + Wellness + Gamification)
    ↓
Phase 4 (Full Notifications + Analytics)
    ↓
Phase 5 (Admin)
    ↓
Phase 6 (Polish + Launch)
```

**Critical path:** `Auth → Feed → Profile → Recognition → Challenges → Admin`

Any delay in Auth or Feed blocks everything downstream.

---

## Risk Areas

| Risk | Severity | Mitigation |
|---|---|---|
| Progress ring SVG performance on low-end devices | Medium | Use CSS animation instead of JS for dashoffset animation |
| Realtime leaderboard updates causing excessive re-renders | Medium | Debounce leaderboard updates — batch at 5s intervals |
| PDF generation for Executive Summary | Medium | Use server-side rendering (puppeteer/playwright) not client-side — PDFs with charts must be pixel-accurate |
| Event Gallery media storage costs | Low | Implement image compression on upload, limit to 5MB per photo |
| Digest aggregation query performance | High | Pre-compute digest snapshots via scheduled job (nightly), not on-demand |
| Admin moderation realtime queue | Medium | Pessimistic locking on moderation actions — two admins cannot act on same item simultaneously |
| RSVP race condition (last few seats) | High | Use database-level capacity counter with atomic decrement, not application-level check |
| Notification delivery at scale | Medium | Use dedicated notification queue (not inline API call) — fire-and-forget pattern |

---

## Reusable Component Reuse Map

Components used across 4+ modules (build these first, invest in quality):

| Component | Used in |
|---|---|
| Avatar + status dot | Feed, Profile, Events, Challenges, Notifications, Admin |
| Type pill / badge | All modules |
| Icon tile | All modules |
| Progress bar | Events, Challenges, Wellness, Admin |
| Section header | All modules |
| Action row | Feed, Post Detail |
| Hero banner | All primary screens |
| KPI card | Analytics, Admin, Profile |
| Leaderboard row | Challenges, Analytics |
| Bottom sheet | Feed, Events, Challenges, Admin |
| Social proof row | Feed, Events, Notifications |
| Filter chip strip | Feed, Events, Challenges, Notifications, Admin |
