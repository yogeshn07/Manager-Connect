# Technology Stack

## Recommended Production Stack for Manager Connect V1

---

## Summary Table

| Layer | Technology | Version / Tier |
|-------|------------|----------------|
| Mobile Framework | React Native via Expo SDK | Expo SDK 52+ (latest stable) |
| Language | TypeScript | 5.x (strict mode) |
| Navigation | Expo Router | v4+ (file-based routing) |
| State Management | Zustand + TanStack Query | Latest stable |
| Backend (BaaS) | Supabase | Pro plan |
| Database | PostgreSQL (via Supabase) | Managed, v15+ |
| Auth | Supabase Auth (OTP — email + SMS) | Built-in |
| Real-time | Supabase Realtime | Built-in (WebSocket) |
| File Storage | Supabase Storage | Built-in (CDN-backed) |
| Server Logic | Supabase Edge Functions | Deno runtime |
| Push Notifications | Expo Notifications + FCM + APNs | Managed via EAS |
| Analytics | PostHog | Cloud (EU region) |
| CI/CD | GitHub Actions | Free tier |
| Build and Distribution | EAS Build + EAS Submit | Expo Application Services |
| OTA Updates | EAS Update | Expo Application Services |
| Code Quality | ESLint + Prettier + Husky | Latest stable |
| Testing: Unit | Jest + React Native Testing Library | Latest stable |
| Testing: Integration | Jest + Supabase local emulator | Latest stable |
| Testing: E2E | Maestro | Latest stable |

---

## Layer-by-Layer Rationale

### React Native + Expo

**Why:** Single codebase for iOS and Android. Expo SDK removes most native configuration burden. EAS provides managed build and submission pipeline. Expo Router brings type-safe, file-based navigation analogous to Next.js — lower cognitive overhead than React Navigation.

**Why not Flutter:** TypeScript expertise is more widely available; React Native ecosystem is larger. Supabase has a first-class JS/TS client.

**Why not native (Swift/Kotlin):** Two separate codebases for 20 users is disproportionate cost.

---

### Supabase (BaaS)

**Why:** Supabase provides PostgreSQL + Auth + Realtime + Storage + Edge Functions in a single managed platform. For V1 at 20 users, building a custom API server would introduce unnecessary infrastructure complexity. Supabase's RLS enforces security at the database layer — reliable and auditable.

**Why not Firebase:** Firebase's Firestore is a NoSQL document store. The relational data model (activities + RSVPs, challenges + participants + logs) maps cleanly to PostgreSQL. Firebase Realtime Database is a poorer fit for this data shape. Supabase open-source nature also means self-hosting is viable later.

**Why not custom Express/Node backend:** Premature complexity for this user scale and team size. Supabase Edge Functions cover the few cases where server-side logic is needed.

**Supabase Plan:** **Pro plan** (not free tier) for production. Pro provides:
- Daily automated backups
- No pausing of inactive projects
- Higher rate limits
- Priority support SLA

---

### Zustand + TanStack Query

**Why Zustand over Redux:** Dramatically less boilerplate. Simple API. Sufficient for the state complexity of this application. No need for Redux middleware, sagas, or complex reducers.

**Why TanStack Query:** Server state (Supabase data) is separate from UI state (Zustand). TanStack Query handles caching, background refresh, stale-while-revalidate, and optimistic updates — patterns that would require significant manual work otherwise.

---

### Expo Notifications + FCM + APNs

**Why:** Expo abstracts the complexity of managing FCM (Android) and APNs (iOS) credentials, token registration, and payload delivery into a single SDK. EAS Credentials manages signing certificates automatically. For 20 users, the Expo Push API (free tier) is more than sufficient.

**Why not a dedicated notification platform (OneSignal, Braze):** Over-engineered for this scale. Supabase Edge Functions calling the Expo Push API directly is simpler, cheaper, and easier to maintain.

---

### PostHog

**Why:** Open-source, privacy-first, self-hostable. EU cloud region available for data residency. No advertising network integrations. Free tier covers this user base. Supports event-based analytics without PII exposure.

**Why not Firebase Analytics:** Google's data sharing model is not aligned with the privacy-first positioning of this platform.

**Why not Mixpanel / Amplitude:** Paid tiers, more complex than needed, third-party data processors.

---

### EAS Build and Submit

**Why:** First-party Expo tooling. Manages iOS code signing (certificates, provisioning profiles) and Android keystores in a secure credential vault. Fully automated pipeline from code to App Store. No Mac required to build iOS (cloud build).

---

## What Was Deliberately Not Chosen

| Option | Rejected Because |
|--------|----------------|
| Custom REST API (Node/Express) | Unnecessary complexity at this user scale |
| GraphQL | Overkill; Supabase PostgREST is sufficient |
| React Navigation (standalone) | Expo Router supersedes it with file-based routing |
| Redux | Too much boilerplate; Zustand is sufficient |
| Firebase | NoSQL mismatch for relational data; Google data policy concerns |
| OneSignal | Additional vendor and cost not justified for 20 users |
| AWS / GCP (raw) | High ops burden for a small team; BaaS is the right abstraction level |
| Fastlane | Superseded by EAS for Expo projects |

---

## Dependency Policy

- All dependencies must have active maintenance (last commit within 6 months).
- No dependencies with known CVEs in the published npm audit.
- Prefer Expo-first packages when an Expo-compatible alternative exists.
- Minimize dependencies: three similar lines of code is better than adding a new library.
- All dependency changes go through PR review.
