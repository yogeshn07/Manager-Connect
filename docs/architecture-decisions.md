# Architecture Decisions

## Overview

This document records the significant architecture decisions made for Manager Connect V1. Each decision includes context, the choice made, the rationale, and the consequences.

---

## ADR-001: Use BaaS (Supabase) Instead of Custom Backend

**Date:** 2026-06-19  
**Status:** Accepted

### Context
Manager Connect serves 15–20 users with a small development team. Building and operating a custom API server (authentication, database, real-time, file storage, and notifications) would require significant ongoing infrastructure effort disproportionate to the application's scale and user base.

### Decision
Use Supabase as the primary backend platform, providing PostgreSQL, Auth (OTP), Realtime, Storage, and Edge Functions from a single managed service.

### Rationale
- Eliminates custom server development for standard backend capabilities.
- RLS (Row-Level Security) at the database layer provides enterprise-grade authorization without application-layer middleware.
- Supabase is open-source: self-hosting migration is possible if organizational policy requires it.
- Pro plan provides SLA-backed uptime and automated backups appropriate for a production community platform.

### Consequences
- **Easier:** Faster time to production; no server DevOps; auth is handled out of the box.
- **Harder:** Vendor dependency on Supabase. Complex server-side business logic must be expressed as Edge Functions (Deno) rather than a familiar Node.js runtime.
- **Accepted risk:** If Supabase's pricing or service model changes unfavorably, migration cost is non-trivial but manageable (it's standard PostgreSQL + Deno).

---

## ADR-002: Use React Native (Expo) for Cross-Platform Mobile

**Date:** 2026-06-19  
**Status:** Accepted

### Context
The platform must run on both iOS and Android. The team has TypeScript expertise. The goal is to ship V1 in 10 weeks with a small team.

### Decision
Build with React Native via the Expo SDK and Expo Router. Use EAS Build and EAS Submit for the build pipeline.

### Rationale
- Single codebase for iOS and Android reduces development effort by ~40–60% compared to native.
- Expo SDK provides managed native modules (camera, notifications, secure storage) that would otherwise require custom native configuration.
- Expo Router provides file-based navigation with type safety analogous to Next.js, reducing navigation boilerplate.
- EAS manages iOS code signing and Android keystores, removing one of the most friction-heavy aspects of mobile deployment.

### Consequences
- **Easier:** Cross-platform delivery; no native Xcode/Gradle expertise required; EAS handles build pipeline.
- **Harder:** Expo SDK update cycle must be followed for new native features. Some very platform-specific UX polish is harder than in native.
- **Accepted risk:** For a community app with standard UI patterns, React Native's trade-offs are well within acceptable bounds.

---

## ADR-003: Invite-Only Registration with OTP Authentication

**Date:** 2026-06-19  
**Status:** Accepted

### Context
Manager Connect is a private community. The user base is strictly defined (specific organization managers). Any form of self-registration would compromise the exclusivity and trust of the platform.

### Decision
Implement invite-only registration (admin sends invite via email or SMS) with OTP-based, passwordless authentication.

### Rationale
- **Invite-only** ensures only approved managers join. No public registration path exists.
- **OTP / passwordless** eliminates password management, credential stuffing risk, and "forgot password" support burden.
- Supabase Auth provides OTP support natively for both email and SMS (via Twilio integration).
- Invite tokens are UUID v4, single-use, and expire after 72 hours — prevents link forwarding abuse.

### Consequences
- **Easier:** No password policy management; no password reset flow; strong identity assurance per invite.
- **Harder:** Requires SMS gateway configuration (Twilio or equivalent) for SMS OTP delivery; phone number becomes a required field.
- **Accepted risk:** If a manager does not have a valid email or phone number, they cannot access the platform. This is acceptable given the organizational context.

---

## ADR-004: Row-Level Security as the Authorization Layer

**Date:** 2026-06-19  
**Status:** Accepted

### Context
The application has differentiated access: members see community data; DMs are private; admins have elevated permissions. This could be enforced in application code or at the database layer.

### Decision
Enforce all data access policies via PostgreSQL Row-Level Security (RLS) policies on every table. Application code does not re-implement access control.

### Rationale
- RLS is enforced at the database layer, making it impossible to bypass from client code regardless of how requests are crafted.
- Centralizes authorization logic in one place (database), reducing the risk of missing a check in application code.
- RLS policies are testable independently of the application.
- Supabase auto-generates the REST API from the schema, and RLS applies automatically to all generated endpoints.

### Consequences
- **Easier:** Authorization cannot be bypassed by client bugs; all API access is implicitly governed.
- **Harder:** RLS policies require careful PostgreSQL knowledge to write correctly; complex policies can be harder to debug than application-layer code.
- **Accepted risk:** Policy testing must be part of the integration test suite. Every table must have RLS enabled — this is enforced by the pre-launch security checklist.

---

## ADR-005: Realtime via Supabase WebSocket Subscriptions

**Date:** 2026-06-19  
**Status:** Accepted

### Context
Several features require live updates without polling: community feed, group chat, direct messages, RSVP counts, and leaderboard updates.

### Decision
Use Supabase Realtime (WebSocket-based) for all live data updates. Polling is not used.

### Rationale
- Supabase Realtime is built into the platform — no additional infrastructure or service.
- WebSocket connections deliver updates instantly (sub-second) vs. polling (5–30 second delays).
- For a community/social app, real-time updates are a core UX expectation (messages, reactions, RSVP counts).
- Connection management (subscribe on mount, unsubscribe on unmount) is well-documented in the Supabase React Native SDK.

### Consequences
- **Easier:** No polling timers to manage; instant updates feel more social and alive.
- **Harder:** WebSocket connections must be managed carefully (subscribe/unsubscribe lifecycle) to prevent memory leaks and battery drain.
- **Mitigation:** Subscribe to only the minimal data change events needed per screen. Unsubscribe on screen unmount is enforced in the module coding standards.

---

## ADR-006: File-Based Routing with Expo Router

**Date:** 2026-06-19  
**Status:** Accepted

### Context
React Native navigation has historically been implemented with React Navigation (imperative, config-based). Expo Router provides a file-system-based alternative analogous to Next.js App Router.

### Decision
Use Expo Router (v4+) as the navigation system for Manager Connect.

### Rationale
- File-based routing removes navigation configuration boilerplate.
- Route groups (`(auth)/`, `(app)/`) provide clean separation between authenticated and unauthenticated screens.
- Deep links are automatically handled by the file structure.
- Type-safe navigation (typed route params) reduces runtime navigation errors.
- First-party Expo tool — maintained by the same team as the SDK and EAS.

### Consequences
- **Easier:** Navigation structure is self-documenting via folder structure; deep links work automatically; typed routes.
- **Harder:** Some advanced React Navigation patterns (nested tab + stack combinations) require understanding Expo Router's layout conventions.
- **Accepted risk:** Expo Router is newer than React Navigation but is now the recommended approach for all new Expo projects as of Expo SDK 50+.

---

## ADR-007: Zustand for Global State, TanStack Query for Server State

**Date:** 2026-06-19  
**Status:** Accepted

### Context
State management in React Native apps typically involves a mix of UI state, server-fetched data, and cross-screen shared state. Options range from Context API to Redux to newer lightweight alternatives.

### Decision
Use Zustand for global application state (auth session, user profile, notification preferences) and TanStack Query for all server-fetched data (feed, activities, challenges, messages).

### Rationale
- **Zustand:** Minimal boilerplate, no provider nesting hell, simple selectors. Sufficient for the complexity level of this app.
- **TanStack Query:** Automatic caching, background refresh, stale-while-revalidate, and optimistic updates are essential for a responsive social app UX. Re-implementing these patterns manually would add significant complexity.
- The separation is clean: Zustand owns app-level state; TanStack Query owns data-fetching state.

### Consequences
- **Easier:** Server state caching is handled automatically; no manual cache invalidation for most cases.
- **Harder:** Developers must understand the distinction between server state (TanStack Query) and UI state (Zustand) and not mix the two.
- **Accepted risk:** Two state libraries to understand. Mitigated by clear conventions in `coding-standards.md`.

---

## ADR-008: PostHog for Privacy-First Analytics

**Date:** 2026-06-19  
**Status:** Accepted

### Context
The platform must understand feature adoption and community health, but cannot use analytics that expose individual behavior to third parties or feel surveillance-like to members.

### Decision
Use PostHog (EU cloud or self-hosted) with strict privacy configuration: no PII in event properties, no session recording, IP masking enabled.

### Rationale
- Open-source: auditable and self-hostable if needed.
- Privacy controls are first-class features, not afterthoughts.
- EU region cloud hosting addresses data residency concerns.
- Event-based (not session-recording-based) analytics align with the platform's trust model.
- Free tier is sufficient for 20 users with low event volume.

### Consequences
- **Easier:** Privacy compliance; no risk of analytics accidentally exposing sensitive behavioral data.
- **Harder:** Cannot use session replay for UX debugging (accepted — alternative: direct user feedback).
- **Accepted risk:** If PostHog SaaS is unavailable or organizationally blocked, the self-hosted version can be deployed with minimal code change (just the host URL).
