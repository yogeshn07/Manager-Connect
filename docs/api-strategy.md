# API Strategy

## Approach: Backend-as-a-Service (BaaS) with Supabase

Manager Connect uses **Supabase** as its primary backend. This eliminates the need to build and maintain a custom API server for V1, while still providing a production-grade, scalable foundation.

### Why Supabase

| Capability | How Supabase Provides It |
|------------|--------------------------|
| Database | PostgreSQL — mature, relational, indexed |
| Authentication | Built-in OTP auth (email/SMS), JWT-based sessions |
| REST API | Auto-generated from database schema |
| Real-time | WebSocket subscriptions via Supabase Realtime |
| File Storage | Supabase Storage with CDN delivery |
| Server-side logic | Supabase Edge Functions (Deno-based, globally deployed) |
| Row-Level Security | Native PostgreSQL RLS policies — enforced at DB layer |

### Trade-offs Accepted

| Trade-off | Rationale |
|-----------|-----------|
| Vendor dependency on Supabase | Acceptable for V1 at this user scale. Supabase is open-source; self-host migration is viable if needed. |
| Less flexibility than custom API | Not needed. All required features fit the BaaS model. |
| Supabase auto-generated REST may expose schema hints | Mitigated by strict RLS policies and no direct public access. |

---

## API Layers

### Layer 1: Auto-Generated REST (Supabase PostgREST)

Used for standard CRUD operations on all resource types:
- Profiles
- Posts and comments
- Activities and RSVPs
- Challenges and progress logs
- Recognitions
- Messages

All requests authenticated via `Authorization: Bearer <JWT>` header. RLS enforces what each user can read or write.

### Layer 2: Supabase Realtime

Used for live data updates without polling:
- Community feed (new posts)
- Group chat and direct messages
- RSVP count updates on activity detail
- Leaderboard position updates

WebSocket connection established on app load, subscriptions added per-screen as needed. Connections released on screen unmount.

### Layer 3: Supabase Edge Functions

Used for operations that require server-side logic not expressible in RLS:
- **Send invitation:** Dispatch email or SMS invitation with unique token
- **Validate invite token:** Verify token is valid, unexpired, and unused before allowing registration
- **Push notification dispatch:** Trigger FCM/APNs push via Expo Push API
- **Admin audit logging:** Write audit entries atomically with admin actions
- **Challenge end processing:** Mark ended challenges and send completion notifications

Edge Functions run at the edge (globally distributed), are stateless, and authenticate callers via the Supabase JWT.

### Layer 4: Supabase Storage

Used for binary assets:
- User profile photos (`avatars/` bucket — public CDN read, authenticated write)
- Post images (`post-images/` bucket — member-read, authenticated write)

---

## API Security Principles

1. **No unauthenticated access.** Every API call requires a valid JWT. Anonymous endpoints are not exposed.
2. **RLS enforces data isolation.** All data access policies are defined at the database layer, not in application code.
3. **Admin operations use Edge Functions.** Direct database writes for sensitive admin actions are not permitted from the client.
4. **Invite tokens are single-use and time-limited.** Expired or used tokens are rejected at the Edge Function level.
5. **Storage buckets have scoped policies.** Only the owning user can write their own profile photo. Admin can delete any stored object.

---

## Rate Limiting and Quotas

| Concern | Approach |
|---------|----------|
| Supabase free/pro tier limits | Monitor and upgrade tier as usage grows. At 20 users, no limits will be reached. |
| Image upload frequency | Client-side: debounce upload button. Server-side: Supabase Storage limits enforced. |
| Push notification volume | Expo Push API: 1,000 notifications/request, batched by module. |

---

## API Versioning

V1 does not implement API versioning — Supabase auto-generated endpoints are schema-versioned implicitly. If a breaking change is needed, it is managed via database migration with backward-compatible transitions (new column, deprecate old, remove in next release).
