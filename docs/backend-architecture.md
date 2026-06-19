# Backend Architecture

## Overview

Manager Connect's backend is **not** a traditional REST API server. It is a **BaaS-first architecture** where the database (PostgreSQL with RLS) and the platform layer (Supabase) handle the majority of data operations directly. A thin **Edge Function compute layer** (Deno) handles only the operations that require server-side trust, atomicity across tables, or third-party integration.

This document defines the layers, module boundaries, principles, and testability strategy. For the folder structure, see `backend-folder-structure.md`. For the full Edge Function and API operation catalogue, see `backend-api-contracts.md`.

---

## Backend Topology

```
┌─────────────────────────────────────────────────────────────┐
│              Mobile Client (Flutter + Riverpod)              │
│                                                             │
│   ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│   │  Riverpod    │  │   GoRouter   │  │  Firebase       │  │
│   │  Providers   │  │  (navigation)│  │  Messaging      │  │
│   │  (state +    │  └──────────────┘  │  (push token)   │  │
│   │   server)    │                    └─────────────────┘  │
│   └──────┬───────┘                                          │
│          │                                                   │
│   ┌──────▼───────────────────────────────────────────────┐  │
│   │     Data Layer (features/*/data/datasources/)        │  │
│   │   auth │ feed │ events │ growth │ analytics          │  │
│   │   profile │ notifications │ admin                    │  │
│   └──────┬───────────────────────┬──────────────────────┘  │
│          │                       │                           │
└──────────┼───────────────────────┼───────────────────────────┘
           │                       │
           ▼ REST / Realtime        ▼ HTTPS invoke
┌──────────────────────┐   ┌────────────────────────────────┐
│   Supabase Platform  │   │   Edge Functions (Deno)        │
│                      │   │                                │
│  ┌────────────────┐  │   │  ┌──────────┐  ┌───────────┐  │
│  │  PostgreSQL    │  │   │  │  Handler │  │  Handler  │  │
│  │  + RLS         │◄─┼───┼─►│  (Adap-  │  │  (Adap-  │  │
│  └────────────────┘  │   │  │  ter)    │  │  ter)     │  │
│  ┌────────────────┐  │   │  └────┬─────┘  └─────┬─────┘  │
│  │  Auth (OTP)    │  │   │       │               │        │
│  └────────────────┘  │   │  ┌────▼─────┐  ┌─────▼─────┐  │
│  ┌────────────────┐  │   │  │ Use Case │  │ Use Case  │  │
│  │  Realtime      │  │   │  │ (App)    │  │ (App)     │  │
│  │  (WebSocket)   │  │   │  └────┬─────┘  └─────┬─────┘  │
│  └────────────────┘  │   │       │               │        │
│  ┌────────────────┐  │   │  ┌────▼───────────────▼─────┐  │
│  │  Storage       │  │   │  │  _shared/                 │  │
│  │  (CDN)         │  │   │  │  repositories/ services/  │  │
│  └────────────────┘  │   │  │  validators/ errors/      │  │
└──────────────────────┘   │  └───────────────────────────┘  │
           ▲               └────────────────────────────────┘
           │                           │
           └───────────────────────────┘
              Edge Functions write to DB
              via service-role Supabase client
```

---

## Architectural Layers

### Layer 1: Database Layer (Supabase / PostgreSQL)

**What it is:** The primary data store. 26 PostgreSQL tables with RLS policies enforcing all access control at the database level.

**What it owns:**
- All data persistence
- Authorization enforcement (RLS policies — the only guaranteed access gate)
- Data integrity (FK constraints, UNIQUE constraints, CHECK constraints)
- Soft delete state
- Timestamps via triggers

**What it does NOT own:**
- Business logic (no stored procedures or triggers that encode business rules)
- Notification dispatch
- Third-party integrations

**Access by:**
- Client via Supabase PostgREST (REST API, JWT-authenticated)
- Edge Functions via service-role client (bypasses RLS where needed for atomic operations)
- Supabase Realtime (change data capture → WebSocket push)

**Rule:** RLS is the final authority on data access. No code in any other layer substitutes for or skips RLS.

---

### Layer 2: Platform Services Layer (Supabase)

**What it is:** The Supabase-provided managed services that sit above the database.

**Components:**

| Service | Role |
|---------|------|
| **PostgREST** | Auto-generates REST API from schema; all CRUD goes here |
| **Auth** | OTP issuance, JWT minting, session management, token rotation |
| **Realtime** | WebSocket change streams for feed, polls, RSVPs, leaderboard |
| **Storage** | CDN-backed blob storage for avatars and post images |

**What it owns:**
- Session lifecycle (issue, refresh, revoke tokens)
- HTTP-to-SQL translation (PostgREST)
- Change event broadcasting (Realtime)
- File upload and CDN delivery (Storage)

**What it does NOT own:**
- Business logic that spans multiple tables
- Notification dispatch
- Invitation token generation and validation

---

### Layer 3: Edge Function Layer (Deno / Supabase Edge Functions)

**What it is:** Stateless, globally deployed Deno serverless functions that handle server-side business logic that cannot be expressed in RLS or handled safely client-side.

**When to use Edge Functions (not PostgREST):**
1. **Server-side trust required** — Admin actions writing to `admin_audit_log` or `invitations` must not be callable with a client JWT alone
2. **Multi-table atomic operations** — Create a post + extract mentions + write `post_mentions` + dispatch notifications must be one operation
3. **Third-party integration** — Email/SMS dispatch, Expo Push API calls, cannot come from the client
4. **Sensitive computation** — Token hashing, invite token validation
5. **Scheduled work** — Challenge closure, monthly stats computation, notification pruning, Connect Buddy content generation

**Internal sub-layers within each Edge Function:**

```
┌─────────────────────────────────────────────────────────────┐
│                     Edge Function                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Handler (index.ts) — Adapters Layer                 │   │
│  │  • Parse HTTP method, headers, body                 │   │
│  │  • Extract and verify JWT (if required)             │   │
│  │  • Validate input with validator                    │   │
│  │  • Map output to HTTP response                      │   │
│  │  • Attach CORS headers                              │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │                               │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │ Use Case (use-case.ts) — Application Layer          │   │
│  │  • Orchestrates the operation                       │   │
│  │  • Calls repositories (data reads/writes)           │   │
│  │  • Calls services (notifications, audit, email)     │   │
│  │  • Enforces business rules (not RLS — those are DB) │   │
│  │  • Throws domain errors on violations               │   │
│  └───────────┬──────────────────────────┬──────────────┘   │
│              │                          │                   │
│  ┌───────────▼──────────┐  ┌────────────▼─────────────┐    │
│  │ Repository           │  │ Services                 │    │
│  │ (_shared/repos/)     │  │ (_shared/services/)      │    │
│  │  • Supabase queries  │  │  • notification.service  │    │
│  │  • Error wrapping    │  │  • audit.service         │    │
│  │  • Typed returns     │  │  • email.service         │    │
│  └───────────┬──────────┘  │  • sms.service           │    │
│              │             └────────────┬─────────────┘    │
│              │                          │                   │
│  ┌───────────▼──────────────────────────▼─────────────┐    │
│  │ Infrastructure (_shared/)                          │    │
│  │  • supabase-client.ts (service role)               │    │
│  │  • errors.ts (AppError, HTTP error factory)        │    │
│  │  • cors.ts (CORS headers)                          │    │
│  │  • crypto.ts (SHA-256 token hashing)               │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Rule:** Use cases may call repositories and services. Repositories and services never call each other. The handler never calls repositories directly.

---

### Layer 4: Client Application Layer (Flutter — lib/features/)

**What it is:** The Flutter mobile app's structured access layer to the Supabase backend. Implements Clean Architecture with Riverpod for state management and GoRouter for navigation.

**Internal sub-layers:**

```
┌─────────────────────────────────────────────────────────────┐
│               Flutter Mobile Application                     │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Presentation (features/*/presentation/)              │   │
│  │  • Screens — full-page widgets routed by GoRouter   │   │
│  │  • Widgets — feature-specific reusable components   │   │
│  │  • Providers — Riverpod Notifiers, AsyncNotifiers,  │   │
│  │    StreamProviders for Realtime subscriptions        │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │ calls Use Cases                │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │ Domain (features/*/domain/)                         │   │
│  │  • Use Cases — single-responsibility callable classes│   │
│  │  • Entities — immutable Dart data classes           │   │
│  │  • Repository Interfaces — abstract contracts       │   │
│  │  • Failures — sealed class (Either<Failure, T>)     │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │ implemented by                 │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │ Data (features/*/data/)                             │   │
│  │  • Remote Datasources — supabase_flutter SDK calls  │   │
│  │  • Models — Freezed + JsonSerializable DTOs         │   │
│  │  • Repository Implementations — Either<Failure, T>  │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │                               │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │ Infrastructure (lib/core/ + lib/shared/)            │   │
│  │  • supabase_provider.dart — SupabaseClient singleton│   │
│  │  • notification_service.dart — FCM + push handling  │   │
│  │  • app_router.dart — GoRouter route tree            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Strict rules:**
- Screens read state via Riverpod providers — never call datasources directly
- Feature modules never import from other feature modules
- `supabase_flutter` SDK is called only in `data/datasources/` — single Supabase access point per module
- All Edge Function calls go through a datasource, not directly from a Notifier
- Dependency direction: Screens → Providers → Use Cases → Repositories (no layer skips another)

---

## Module Boundaries

Nine feature modules. Each module is a self-contained vertical slice. Messaging has been removed; analytics is a new first-class module.

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│   auth   │  │ profiles │  │   feed   │  │  events  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  growth  │  │recogniti-│  │analytics │  │  admin   │
│          │  │on        │  │          │  │          │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
                              ▲
                    ┌─────────┴────────┐
                    │  notifications   │  ← shared infrastructure
                    │  (cross-cutting) │
                    └──────────────────┘
```

### Module Ownership

Each module owns its:
- Database tables (see entity catalogue)
- Edge Functions
- Client datasource files
- Riverpod providers
- Riverpod provider cache keys

| Module | Owned Tables | Notes |
|--------|-------------|-------|
| `auth` | `invitations` | OTP flow via Supabase Auth platform |
| `profiles` | `profiles` | Includes Connect Buddy system account |
| `feed` | `posts`, `post_images`, `post_reactions`, `comments`, `post_mentions` | Connect Buddy posts authored via `post-connect-buddy-message` Edge Fn |
| `events` | `activities`, `activity_rsvps`, `activity_updates`, `polls`, `poll_options`, `poll_votes`, `event_attendance` | Games, outings, social connect, polls, attendance |
| `growth` | `challenges`, `challenge_participants`, `progress_logs` | Fitness and wellness challenges |
| `recognition` | `recognitions`, `recognition_recipients`, `recognition_reactions` | Feeds into analytics |
| `analytics` | `member_monthly_stats`, `community_health_scores` | Plus read access to recognition tables |
| `notifications` | `notification_inbox` | Cross-cutting shared service |
| `admin` | `flagged_content`, `pinned_announcements`, `admin_audit_log` | Consumer of all modules |

### Dependency Rules

| Rule | Detail |
|------|--------|
| Modules do not import from each other | Feed module never imports from Events module |
| `notifications` is the only shared module | All modules call `send-notification` Edge Function; the Notification service is in `_shared/` |
| `admin` is a consumer of all modules | Admin operations (delete post, deactivate user, record attendance) touch any module's tables, always via Edge Function |
| `_shared/` is readable by all Edge Functions | Repositories, services, validators are all in `_shared/` |
| Types are defined once, shared everywhere | `src/types/database.ts` and `supabase/functions/_shared/types.ts` are single sources of truth |

### Cross-Module Operations

Some operations span module boundaries. These are always handled by an **Edge Function**, which acts as the orchestrator:

| Operation | Modules Crossed | Edge Function |
|-----------|----------------|---------------|
| Create post with @ mention | feed + notifications | `create-post` |
| Create recognition | recognition + notifications + analytics | `create-recognition` |
| Cancel activity | events + notifications | `cancel-activity` |
| Post activity update | events + notifications | `post-activity-update` |
| Close challenge | growth + notifications | `close-challenge` |
| Create poll | events + notifications | `create-poll` |
| Close poll + notify participants | events + notifications | `close-poll` |
| Record event attendance (batch) | events + analytics | `record-attendance` |
| Compute monthly stats + health score | analytics + events + growth + recognition + feed | `compute-monthly-stats` |
| Post Connect Buddy message | feed + notifications | `post-connect-buddy-message` |
| Scheduled Connect Buddy content | feed + events + notifications | `scheduled-connect-buddy` |
| Resolve flagged content | admin + feed | `resolve-flag` |
| Remove user | admin + profiles + storage | `remove-user` |
| Create profile after invite | auth + profiles + notifications | `create-profile` |

---

## Realtime Architecture

Realtime subscriptions are established by the client directly on Supabase channels. They are NOT routed through Edge Functions.

```
Client mounts screen
       ↓
Subscribe to Supabase Realtime channel
       ↓
Database INSERT/UPDATE triggers broadcast event
       ↓
Client receives event over WebSocket
       ↓
Riverpod provider is invalidated or state updated
       ↓
UI re-renders
```

### Realtime Channel Catalogue

| Channel Name | Event | Triggers |
|---|---|---|
| `feed:posts` | INSERT on `posts` | Feed screen refresh (includes Connect Buddy posts) |
| `feed:reactions:{post_id}` | INSERT/UPDATE/DELETE on `post_reactions` | Post card reaction count |
| `feed:comments:{post_id}` | INSERT on `comments` | Comment count badge |
| `activities:rsvps:{activity_id}` | INSERT/UPDATE/DELETE on `activity_rsvps` | RSVP attendee list |
| `events:poll_votes:{poll_id}` | INSERT on `poll_votes` | Live poll result percentages |
| `growth:leaderboard:{challenge_id}` | INSERT on `progress_logs` | Leaderboard position |
| `recognition:wall` | INSERT on `recognitions` | Recognition wall refresh |
| `notifications:inbox:{user_id}` | INSERT on `notification_inbox` | Notification badge count |

**Rules:**
- Subscribe on screen mount, unsubscribe on screen unmount
- Subscribe to the minimum scope (by ID, not full table)
- Handle reconnection: re-fetch stale data on WebSocket reconnect
- Never store raw Realtime payloads in widget state — use them to trigger Riverpod provider invalidation only

---

## Security Architecture at the Backend Layer

### Trust Boundaries

```
Internet (Untrusted)
       │
       ▼
Supabase API Gateway
       │
   JWT Verify
       │
       ├──► PostgREST → RLS Policy Evaluation → PostgreSQL
       │                   (trust boundary #1: database layer)
       │
       └──► Edge Function → Handler JWT Verify → Use Case
                              (trust boundary #2: function layer)
                                    │
                                    └──► Service-Role Supabase Client
                                         (bypasses RLS — only for
                                          trusted server-side operations)
```

### Key Security Contracts

| Contract | Implementation |
|----------|---------------|
| Client cannot write to admin_audit_log | RLS: INSERT = none. Only service-role Edge Functions can write |
| Client cannot write to invitations | RLS: INSERT = none. Only `send-invitation` function writes |
| Client cannot write to notification_inbox | RLS: INSERT = none. Only `send-notification` function writes |
| Client cannot write to post_mentions | RLS: INSERT = none. Only `create-post` function writes |
| Client cannot write to poll_options | RLS: INSERT = none. Only `create-poll` function writes atomically |
| Client cannot write to event_attendance | RLS: INSERT = none. Only `record-attendance` function writes (admin-only) |
| Client cannot write to member_monthly_stats | RLS: INSERT = none. Only `compute-monthly-stats` scheduled function writes |
| Client cannot write to community_health_scores | RLS: INSERT = none. Only `compute-monthly-stats` scheduled function writes |
| Connect Buddy posts authored by system profile | `post-connect-buddy-message` Edge Fn uses service-role client; system profile's `is_system_account = true` prevents client impersonation |
| Invite tokens are never stored in plaintext | Edge Function hashes token before INSERT; only hash stored in DB |
| Admin actions always produce an audit log entry | Use case layer writes to admin_audit_log atomically with the action |

---

## Testability Strategy

### Edge Functions — Unit Testable

Each Edge Function's `use-case.ts` is a pure TypeScript function that receives repository instances as dependencies. Repositories are interfaces — they can be replaced with mocks in tests.

```
Use Case receives:
  - ProfileRepository (interface)
  - NotificationService (interface)
  - AuditService (interface)

In tests: inject mock implementations
In production: inject real Supabase-backed implementations
```

This is dependency injection without a DI container — constructor injection via factory functions.

### Edge Functions — Integration Testable

The full function (handler → use case → repository) is tested against a local Supabase instance:
- `supabase start` brings up local Postgres + Auth + Storage
- Test seed populates fixture data
- Jest calls the function handler directly (no HTTP needed)
- Assert final database state

### Client Datasources — Unit Testable

Client datasources are pure async classes. They receive a SupabaseClient via Riverpod provider injection. Tests override the provider with a mock client returning fixture data.

### Client Widgets — Integration Testable

Riverpod providers are tested with Flutter widget testing:
- Wrap in `ProviderScope` with overrides for mock notifiers
- Assert loading → success → rendered states via `AsyncValue.when`

### What is NOT unit tested

- RLS policies — tested via integration tests with real Supabase local instance using non-admin sessions
- Supabase client calls themselves — vendor code, not ours to test
- FCM push dispatch — tested via E2E with a test device

---

## Architecture Decision: Where Business Logic Lives

Clear rules on where each type of logic belongs:

| Logic Type | Location |
|-----------|---------|
| Access control (who can read/write a row) | RLS policy on the table |
| Input validation (required fields, formats, ranges) | `_shared/validators/` in Edge Functions; client service validates before calling |
| Atomic multi-table writes | Edge Function use case |
| Business rules (e.g., one RSVP per user per activity) | UNIQUE constraint at DB layer; Edge Function validates if RLS can't |
| Notification dispatch logic | `_shared/services/notification.service.ts` |
| Audit log writing | `_shared/services/audit.service.ts` |
| Connect Buddy post authoring | `_shared/repositories/connect-buddy.repository.ts` called by Edge Functions |
| Monthly stats computation | `compute-monthly-stats` Edge Function use case (scheduled) |
| UI/UX state logic | Riverpod Notifiers and providers |
| Data fetching and caching | Riverpod AsyncNotifiers and FutureProviders |
| Push token lifecycle | `lib/shared/services/notification_service.dart` |

**Core principle:** Push logic DOWN as close to the database as possible. RLS at the DB level > Edge Function > Client service. Never duplicate a business rule across multiple layers.
