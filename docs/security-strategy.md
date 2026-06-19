# Security Strategy

## Security Philosophy

Manager Connect is a private community platform holding personal data and social content for organization managers. Security is non-negotiable. The principle of least privilege is applied everywhere: users and systems access only what they need, nothing more.

---

## 1. Authentication

### Mechanism: OTP-Based, Passwordless

- Users authenticate via one-time password (OTP) sent to their registered email or mobile number.
- No passwords are stored. Eliminates credential stuffing and brute-force attack surfaces.
- OTPs expire after 10 minutes and are single-use.
- Sessions are JWT-based, issued by Supabase Auth.

### Session Management

- JWTs have a 1-hour access token lifespan and a 7-day refresh token lifespan.
- Refresh tokens are rotated on use (single-use rotation).
- Access tokens and refresh tokens are stored in **Expo SecureStore** (iOS Keychain / Android Keystore), not AsyncStorage.
- On logout, both tokens are invalidated server-side.
- Suspicious session anomalies (e.g., concurrent sessions from two countries) trigger forced logout.

### Invite-Only Registration

- Registration is only possible via a valid, unexpired, single-use invite token.
- Invite tokens are UUID v4, generated server-side, and stored hashed in the database.
- Tokens expire after 72 hours if unused.
- Admin can revoke pending invitations at any time.

---

## 2. Authorization

### Role-Based Access Control

| Role | Capabilities |
|------|-------------|
| `member` | Read community data, write own content, send DMs |
| `admin` | All member capabilities + user management, moderation, admin panel |

### Row-Level Security (RLS)

- Every database table has RLS enabled.
- Policies are evaluated at the PostgreSQL level — not in application code.
- RLS cannot be bypassed by client requests, regardless of what the client sends.
- Admin operations that modify other users' data are executed via Supabase Edge Functions (server-side, not client-callable without valid auth).

---

## 3. Data Protection

### Data in Transit

- All client-to-Supabase communication is over HTTPS (TLS 1.2+).
- WebSocket connections (Supabase Realtime) use WSS (TLS).
- Certificate pinning is evaluated for V2 given the small user base and managed infrastructure.

### Data at Rest

- Supabase encrypts all data at rest using AES-256.
- Supabase Storage (for images) encrypts objects at rest.
- No unencrypted backups or exports are permitted.

### PII Handling

| Data | Classification | Access |
|------|----------------|--------|
| Full name | PII | Member-visible (community members only) |
| Profile photo | PII | Member-visible |
| Email / mobile | Sensitive PII | Auth system only; not exposed in API or UI |
| Bio and interests | Semi-public | Member-visible |
| Progress logs | Semi-private | Leaderboard view (aggregated); full log private |
| Poll votes | Semi-public | Vote count visible to all; individual vote visible to voter only |
| Attendance records | Semi-private | Admin records; aggregate count visible to members |

---

## 4. Privacy

- The platform does not collect behavioral analytics (screen time, scroll depth, keystroke logging).
- No third-party advertising or tracking SDKs are installed.
- Analytics tooling (PostHog) is configured to exclude any PII from event properties.
- On user removal or account deletion: PII is soft-deleted within 24 hours, hard-deleted within 30 days. Content remains but is anonymized (author shown as "Removed Member").

---

## 5. Content Security

- Users can flag posts and comments as inappropriate.
- Admin reviews flagged content within 24 hours.
- Admin can delete any post or comment.
- Deleted content is soft-deleted (hidden from view) and hard-deleted after 30 days.
- Moderation actions are recorded in the admin audit log.

---

## 6. Mobile Security

- The app does not jailbreak-detect or root-detect in V1. This is reviewed for V2.
- Deep links from push notifications use `expo-linking` with validated URL schemes, not arbitrary URL opens.
- No sensitive data is stored in the device clipboard programmatically.
- App follows OWASP Mobile Security Top 10 guidelines as a pre-launch checklist.

---

## 7. Infrastructure Security

- Supabase project is in a dedicated environment (not shared with other projects).
- Database is not publicly accessible; all access goes through Supabase's API layer with RLS.
- Edge Functions are deployed in Supabase's managed Deno runtime — no direct server access.
- Environment secrets (Supabase keys, push credentials) are stored in EAS Secrets and CI environment variables, never in the repository.
- Supabase service role key (bypasses RLS) is never used in client code — only in CI/CD scripts where necessary.

---

## 8. Audit and Monitoring

| Event | Logged |
|-------|--------|
| User invited | Yes (admin audit log) |
| User deactivated / removed | Yes |
| Post or comment deleted by admin | Yes |
| Flagged content resolved | Yes |
| Admin panel access | Yes |
| Failed OTP attempts | Supabase Auth logs |
| Edge Function invocations | Supabase Edge logs |

Audit logs are retained for 1 year and are not editable by any user, including admins.

---

## 9. Security Review Checklist (Pre-Launch)

- [ ] OTP expiry and single-use enforcement verified
- [ ] All database tables have RLS enabled and tested with non-admin session
- [ ] Supabase service role key not present in client bundle
- [ ] Secure token storage verified on both iOS and Android
- [ ] Deep link URL validation tested for open-redirect scenarios
- [ ] Image upload size and type validation enforced server-side
- [ ] Admin audit log writes verified for all admin actions
- [ ] Privacy data deletion flow tested end-to-end
- [ ] OWASP Mobile Top 10 review completed
