# API Guidelines

## Overview

These guidelines govern how the Manager Connect client application interacts with Supabase and Edge Functions. They ensure consistency, security, and maintainability across all modules.

---

## 1. Client Initialization

- A single Supabase client instance is initialized at app startup and shared via a context provider.
- The client is initialized with the Supabase project URL and anon public key (safe to expose on client).
- The JWT session is automatically injected into all requests by the client.
- Never create multiple Supabase client instances.

---

## 2. Data Fetching Conventions

### Select Only What You Need
Always specify a column select list. Never use `select('*')` in production code.

```
// Correct
supabase.from('profiles').select('id, full_name, avatar_url, role')

// Avoid
supabase.from('profiles').select('*')
```

### Pagination Is Mandatory for List Views
All list queries must include `.range(from, to)` or `.limit(n)`. Default page size: 20 items.

### Order Consistently
- Feeds, recognitions, messages: `order('created_at', { ascending: false })`
- Activities: `order('event_date', { ascending: true })`
- Leaderboards: `order('total_progress', { ascending: false })`

### Filter at the Database, Not in JavaScript
Apply `.eq()`, `.gte()`, `.lte()`, `.in()` filters in the query, not after fetching. Never fetch a full table to filter client-side.

---

## 3. Mutations

- All INSERT, UPDATE, and DELETE operations must check the returned error before proceeding.
- On error, display a user-facing toast with a friendly message. Log the full error to the console (not to analytics).
- Use `.select()` after mutations to retrieve the created/updated record rather than making a separate fetch.

```
// Correct
const { data, error } = await supabase
  .from('activities')
  .insert({ title, event_date, location })
  .select('id, title, event_date')
  .single()
```

---

## 4. Real-time Subscriptions

- Subscribe to real-time channels only on screen mount. Unsubscribe on screen unmount.
- Use channel names that are descriptive and scoped: `messages:conversation:{id}`, `activities:rsvp:{id}`.
- Do not subscribe to full-table changes. Always filter by a specific record or user ID.
- Handle reconnection gracefully: refresh data on reconnect.

---

## 5. Edge Function Calls

- Call Edge Functions via `supabase.functions.invoke('function-name', { body: payload })`.
- Edge Functions are used for: invitations, push notification dispatch, audit logging, and challenge closure.
- Always await and check the result for errors before assuming success.
- Never call Edge Functions from background threads or fire-and-forget without error handling.

---

## 6. File Uploads

- Compress images client-side before upload. Target: under 1 MB per image.
- Use structured storage paths: `avatars/{user_id}/profile.jpg`, `post-images/{user_id}/{uuid}.jpg`.
- After upload, store only the storage path in the database — not the full signed URL. Generate URLs on the fly using `supabase.storage.from(bucket).getPublicUrl(path)`.
- Delete old files from storage when a user replaces their profile photo.

---

## 7. Error Handling

| Error Type | Client Response |
|------------|----------------|
| Network error (offline) | Show offline banner; queue mutation for retry |
| 401 Unauthorized | Force logout and redirect to auth screen |
| 403 Forbidden | Show "You don't have permission" toast |
| 404 Not Found | Show "Content not found" with a back button |
| 500 Server Error | Show "Something went wrong. Please try again." toast |

Never expose raw Supabase error messages to the user. Always map to friendly strings.

---

## 8. Environment Configuration

- All Supabase keys and URLs are stored in environment variables, never hardcoded.
- Use `expo-constants` or `@env` to access environment variables at runtime.
- `.env` files are never committed to the repository.
- CI/CD pipeline injects environment variables at build time via EAS Secrets.

---

## 9. Naming Conventions for Database Tables and Columns

| Convention | Example |
|------------|---------|
| Table names: snake_case, plural | `activity_rsvps`, `progress_logs` |
| Column names: snake_case | `created_at`, `user_id`, `event_date` |
| Foreign keys: `{table}_id` | `activity_id`, `creator_id` |
| Boolean columns: prefixed with `is_` | `is_active`, `is_deleted` |
| Timestamp columns: `{action}_at` | `created_at`, `updated_at`, `deleted_at` |

---

## 10. Type Safety

- Use Supabase CLI to generate TypeScript types from the database schema.
- All database query results must be typed. Never use `any` for Supabase return types.
- Regenerate types after every database schema migration: `supabase gen types typescript`.
