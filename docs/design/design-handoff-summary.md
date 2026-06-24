# Manager Connect — Design Handoff Summary
> Primary onboarding guide for implementation · Version 1.0

---

## 1. Product Overview

**Manager Connect** is a private community platform for Engineering Managers, Delivery Managers, Team Leads, and Senior Leaders. It is a mobile-first application built as a premium professional social network with embedded gamification, wellness, events, and community management.

**The product serves two distinct user types:**
- **Members** — managers who participate in the community (feed, recognition, events, challenges, wellness)
- **Admins** — community administrators, HR coordinators, and event organizers who manage the platform

**Scale:** Designed for organizations of 100–1000 managers. The reference implementation targets 500 active users.

**Platform:** Mobile-first (360px primary viewport). All screens are designed at 360px width with 36px border-radius device shell in mockups. Real implementation targets iOS and Android native (or React Native / Flutter) and a responsive web app.

---

## 2. Design Philosophy

### The four non-negotiables

**1. Borders over shadows — always.**
There are zero box-shadows in this product. Every element uses a `0.5px solid` border at ~10% black opacity to create separation. A white card on a `#F4F5F7` background with a thin border is already visually distinct — no elevation needed. If you find yourself reaching for a shadow, you are doing something wrong.

**2. Two font weights — no exceptions.**
`font-weight: 400` for body text. `font-weight: 500` for headings, names, labels, numbers. That's it. Never use 600, 700, or bold. If you need more hierarchy, use size or color — not weight.

**3. Color carries meaning — never decorate with it.**
Every color maps to a category:
- Blue (#0C447C / #185FA5) = brand / informational / active
- Teal (#1D9E75 / #085041) = success / wellness / confirmed
- Amber (#BA7517 / #FAC775) = recognition / gold / achievement
- Red (#E24B4A / #A32D2D) = urgent / error / unread
- Purple (#534AB7 / #3C3489) = mindset / mentions / wellness hub
- Coral (#712B13 / #993C1D) = sports / energy

If you want to use teal "because it looks nice here," don't. Teal means confirmed or wellness. Using it elsewhere breaks the semantic encoding the product depends on.

**4. Insights before data.**
Analytics and notification screens lead with a complete sentence that states the condition ("Community is healthy. One area needs attention."), followed by the numbers as evidence. Never show a raw number as the headline of an analytics screen.

---

## 3. Key UX Principles

### P1: Social proof before CTA
Always show who else is participating before asking the user to act. Stacked avatar strip + "Name, Name and N others [verb]" appears before every RSVP button, every join button, and every recognition share CTA.

### P2: Progress is always visible
Any ongoing activity (challenge, streak, event capacity) shows a progress indicator. Ring, bar, or day-pip calendar. Users should always know where they stand.

### P3: The "you" row always stands out
In every leaderboard, ranking list, or admin table, the authenticated user's own row gets: `border-left: 3px solid #0C447C` + `background: #F5F9FF`. No exceptions. This is the product's universal "this is you" signal.

### P4: State-aware actions
The actions available to a user reflect their current state. A joined challenge shows "Log today" not "Join." A flagged user in admin shows "Suspend" that a standard user does not see. Never show actions that are contextually inappropriate.

### P5: Urgency is honest
Red text and urgent labels are used only for genuinely time-sensitive, real information. "16 seats left," "Expires in 1 day," "3 urgent" — these are factual counts. Never use urgency language for engagement manipulation.

### P6: Celebration is proportional
Badge unlocks, streak milestones, and recognition receipts get elevated visual treatment. Routine events (new comment, leaderboard update) do not. Reserve the celebratory register for moments that genuinely deserve it.

---

## 4. Component Strategy

### Build the component library before any screens

The 28 components in `component-library.md` are the product. Screens are compositions of these components. Build all components first, then assemble screens.

**The 10 most critical components to build first (in order):**
1. Avatar (with status dot and badge variants)
2. Icon tile (with all size/color variants)
3. Type pill / badge (all 40+ color combinations)
4. Bottom navigation (member + admin separately)
5. Top bar (all 3 variants)
6. Hero banner (all color variants)
7. Section header
8. Progress bar (track + fill, color-coded states)
9. Filter chip strip
10. Action row (4-button)

These 10 components appear on virtually every screen. Everything else is built on top of them.

### Component reuse creates visual consistency
When a leaderboard row looks the same in the Challenge Detail, the Analytics Rankings screen, and the Admin view — that is the design working correctly. Do not customize components for specific screens. If a screen requires a variation, define it as a named variant in the component spec.

---

## 5. Implementation Strategy

Refer to `implementation-priority.md` for the complete phased build plan. Summary:

**Phase 0:** Design tokens + 14 base components — no screens
**Phase 1:** Feed + basic Profile + Notification Center
**Phase 2:** Recognition + Events
**Phase 3:** Challenges + Wellness + Gamification
**Phase 4:** Full Notifications + Analytics
**Phase 5:** Admin module
**Phase 6:** Polish, empty states, error states, push notifications

**Never skip Phase 0.** Teams that skip the component foundation spend 3× longer fixing visual inconsistencies in later phases.

---

## 6. Critical Rules — Do Not Break These

### Visual rules

```
RULE 1: No box-shadow on any element. Ever.
RULE 2: Only font-weight 400 and 500. Never bold or heavy.
RULE 3: App background is always #F4F5F7. Never white.
RULE 4: Card background is always #FFFFFF. Never tinted unless accented.
RULE 5: Corner radius on cards: 13–16px. Never 0, never 50%.
RULE 6: All avatars are circular (border-radius: 50%). Never rectangles.
RULE 7: Icon library is Tabler outline ONLY. No filled variants. No other icon library.
RULE 8: All icon tiles must have a 1–1.5px colored border. Never flat fill without border.
RULE 9: The "you" row in any ranked list always gets blue left-stripe + #F5F9FF bg.
RULE 10: Serif font (font-serif) is only used for recognition quote blocks and wellness reflections.
```

### Interaction rules

```
RULE 11: Back labels always use parent screen name, never generic "Back".
RULE 12: Bottom nav is NEVER shown on detail screens. Root screens only.
RULE 13: Admin navigation is completely separate from member navigation.
RULE 14: Progress bar fill color encodes status: teal = healthy, amber = expiring, red = admin-health-below-threshold only.
RULE 15: Minimum touch target: 44px height for primary actions, 34px for secondary.
RULE 16: Color never conveys meaning alone — always pair with text or icon.
```

### Accessibility rules

```
RULE 17: All decorative icons: aria-hidden="true"
RULE 18: All interactive icons: aria-label="[description]"
RULE 19: Minimum text size for all body-facing text: 10px. For pills: 9px.
RULE 20: LIVE pill on story rings: must achieve 4.5:1 contrast on red background. Use 9px+ text.
```

---

## 7. Things Developers Must Not Change

The following design decisions are final and must not be altered during implementation, even if a developer believes a different approach is technically simpler or visually "better":

| Decision | Rationale |
|---|---|
| Zero box-shadows | The entire visual language is border-based. Adding shadows breaks the system. |
| #F4F5F7 app background | This exact warm off-white creates the card-on-background separation. Pure gray or pure white will look wrong. |
| Tabler outline icons only | The product's visual language uses outline icons exclusively. Mixing with filled icons or other libraries destroys icon consistency. |
| No font-weight above 500 | Heavy weights look aggressive and corporate. The product's premium feel depends on lightness. |
| Amber FAC775 reserved for logo gem + achievement gold only | Using amber elsewhere dilutes the recognition/achievement signal. |
| Red reserved for urgent/error only | Using red for decorative purposes trains users to ignore urgent states. |
| Social proof rows before CTAs | User research supports this as a conversion pattern. It is not decorative. |
| "You" row left-stripe always blue | This is the product's universal identity marker. Changing the color for specific screens breaks the pattern. |
| Bottom nav hidden on detail screens | This is a deliberate navigation model. Detail screens should feel focused, not navigable-away-from-via-tabs. |
| Serif font on recognition quotes only | The serif creates a premium "award" register. Using it elsewhere dilutes the significance. |

---

## 8. Document Index

| Document | Purpose |
|---|---|
| `design-system.md` | All design tokens: colors, typography, spacing, radius, elevation, icons |
| `screen-inventory.md` | Every screen with route, purpose, dependencies, entry/exit points |
| `user-flows.md` | Complete user journey maps for all primary flows |
| `component-library.md` | 28 reusable components with anatomy, variants, states, usage rules |
| `navigation-architecture.md` | Route tree, navigation types, deep links, back navigation rules |
| `empty-states.md` | Empty state copy, icons, and CTAs for all modules |
| `error-states.md` | Error state designs for all failure scenarios |
| `screen-to-backend-mapping.md` | API dependencies, database tables, realtime channels per screen |
| `implementation-priority.md` | Phased build order with dependencies and risk areas |
| `design-handoff-summary.md` | This document — start here |

---

## 9. Quality Bar

The design target for Manager Connect is described as a premium blend of:
- **LinkedIn Premium** — professional identity, recognition, networking
- **Microsoft Viva Engage** — enterprise community, announcements, analytics
- **Strava** — streak gamification, leaderboards, activity tracking
- **Apple Fitness / Health** — progress rings, wellness, clean visualization
- **Linear** — structured admin, precise hierarchy, no clutter
- **Airbnb Experiences** — event discovery, desire-creation, immersive detail screens

Every screen, every component, every interaction should be evaluated against this bar. If a screen looks like enterprise HR software or a generic CRUD interface, it has not reached the quality standard.

**A manager should open this app and immediately feel: "This is premium. This is built for people like me."**

That is the only acceptance criterion that matters.
