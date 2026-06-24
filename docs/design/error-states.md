# Manager Connect — Error States
> Version 1.0 · All failure scenarios defined

---

## Visual Specification (All Error States)

Error states follow a consistent visual pattern:

```
Container: centered, padding: 40px 24px
Icon: 56px icon tile (category-appropriate or red-50 for critical errors)
Heading: 16px / 500, primary, centered
Description: 13px / 400, secondary, centered, max-width: 260px
Primary recovery CTA: full-pill primary button, centered, max-width: 200px
Secondary link (optional): ghost link, 12px / 500, brand blue
```

**Error severity color coding:**
- **Critical** (auth, session, permission): red icon tile (#FCEBEB fill, #F09595 border, #A32D2D icon)
- **Recoverable** (network, API): amber icon tile (#FAEEDA fill, #EF9F27 border, #BA7517 icon)
- **Informational** (missing/deleted content, expired): blue icon tile (brand-50 fill)

---

## 1. Network Failure

**When:** Device has no internet connection or request timed out.

| | |
|---|---|
| **Icon** | `ti-wifi-off` — amber icon tile |
| **Title** | "No internet connection" |
| **Description** | "Check your connection and try again. Your progress is saved locally." |
| **Primary CTA** | "Try again" → retry last request |
| **Secondary link** | None |
| **Behavior** | Retry button triggers a network check. On success, reload the current screen. On failure, show again. |
| **Toast variant** | For inline failures on a loaded screen: bottom toast bar `#FAEEDA` with amber icon + "No connection · Retry" link. Dismiss after 8s or on tap. |

---

## 2. API / Server Failure

**When:** Network is available but the server returned a 5xx error.

| | |
|---|---|
| **Icon** | `ti-server-off` — amber icon tile |
| **Title** | "Something went wrong" |
| **Description** | "We couldn't load this right now. It's not you — we're working on it." |
| **Primary CTA** | "Try again" → retry the failed request |
| **Secondary link** | "Go to feed" → /feed (safe fallback) |
| **Behavior** | Exponential backoff on retry (1s, 2s, 4s max 3 attempts before showing this full-screen state). |

---

## 3. Permission Failure

**When:** User attempts to access a screen they don't have role access for (e.g., member accessing `/admin`).

| | |
|---|---|
| **Icon** | `ti-lock` — red icon tile |
| **Title** | "Access restricted" |
| **Description** | "You don't have permission to view this page. Contact your community admin if you think this is an error." |
| **Primary CTA** | "Go to feed" → /feed |
| **Secondary link** | None |
| **Behavior** | This state is shown instead of a redirect to prevent auth loops. Never show admin content partially — gate entirely. |

---

## 4. Authentication Failure (Login error)

**When:** Incorrect credentials, OAuth failure, or account not found.

| | |
|---|---|
| **Context** | Shown inline on login screen, not full-screen |
| **Display** | Inline error below input fields |
| **Text** | "Incorrect email or password. Please try again." |
| **Style** | Red-50 bg inline block, red-400 text, 12px, `ti-alert-circle` icon left |
| **Behavior** | Input fields clear password only. Email retained. |

**Account not found variant:**
| | |
|---|---|
| **Text** | "No account found with this email. Check the spelling or ask your admin to send you an invite." |

---

## 5. Expired Session

**When:** Auth token has expired (typically after 30+ days inactive).

| | |
|---|---|
| **Trigger** | Any API call returns 401 |
| **Behavior** | Immediately redirect to `/auth/login` |
| **Toast** | Bottom toast "Your session expired — please sign in again" (amber, 3s) |
| **After login** | Redirect to the route the user was on when session expired (deep link preserved) |
| **Data** | Draft posts and locally-saved progress are preserved in local storage during session refresh |

---

## 6. Missing Content (404)

**When:** A post, event, or profile that used to exist can no longer be found by ID.

| | |
|---|---|
| **Icon** | `ti-file-unknown` — blue icon tile |
| **Title** | "Content not found" |
| **Description** | "This post, event, or profile may have been removed or the link may be incorrect." |
| **Primary CTA** | "Go to feed" → /feed |
| **Secondary link** | "Go back" → previous screen |
| **When reached via deep link** | Show this state with "Go to feed" as the only option |

---

## 7. Deleted Content

**When:** Content that was loaded is subsequently deleted (realtime update).

| | |
|---|---|
| **Trigger** | Realtime channel notifies that the viewed content was deleted |
| **Behavior** | Current screen fades out and shows this state in-place (no route change) |
| **Icon** | `ti-trash` — blue icon tile |
| **Title** | "This has been removed" |
| **Description** | "This post was removed from the community." |
| **Primary CTA** | "Go to feed" |
| **Note** | Never show "who removed it" in the error — this is intentionally anonymous to members |

---

## 8. Event Closed / Sold Out

**When:** User taps RSVP on an event that has reached capacity or been closed.

| | |
|---|---|
| **Context** | Shown inline on Event Detail / RSVP screen — not full-screen |
| **Display** | RSVP button replaced with a disabled state + message |
| **Button state** | Gray pill, "Event is full" label, cursor disabled |
| **Message** | "This event has reached capacity. Add yourself to the waitlist to be notified if spots open." |
| **CTA** | "Join waitlist" (if waitlist feature exists) OR "Get notified" → saves interest flag |
| **Notification** | When a spot opens: push notification "A spot opened at [Event] — RSVP now" |

**Event cancelled variant:**
| | |
|---|---|
| **Display** | Full-screen overlay on Event Detail |
| **Icon** | `ti-calendar-x` — red icon tile |
| **Title** | "This event has been cancelled" |
| **Description** | "The organizer has cancelled this event. Your RSVP has been removed." |
| **CTA** | "Browse other events" → /events |

---

## 9. Challenge Expired

**When:** User taps into a challenge that has ended.

| | |
|---|---|
| **Context** | Shown on Challenge Detail for expired challenges |
| **Icon** | `ti-clock-off` — amber icon tile |
| **Title** | "This challenge has ended" |
| **Description** | "The [Challenge Name] ended on [date]. Check the final leaderboard to see the results." |
| **Primary CTA** | "See final leaderboard" → /challenges/:id/leaderboard (read-only) |
| **Secondary link** | "Browse active challenges" → /challenges |
| **Behavior** | Log activity button is hidden. Leaderboard is still accessible in read-only mode. |

**Challenge not yet started variant:**
| | |
|---|---|
| **Title** | "Challenge starts [date]" |
| **Description** | "You can join now and be ready when it begins." |
| **CTA** | "Join early" |

---

## 10. Notification Delivery Failure

**When:** A push notification tapped leads to content that cannot be loaded (network failure on deep link).

| | |
|---|---|
| **Behavior** | App opens to the intended route, but shows a loading skeleton → then network error state |
| **Icon** | `ti-bell-off` — amber icon tile |
| **Title** | "Couldn't load this notification" |
| **Description** | "We couldn't load the content from this notification. Check your connection and try again." |
| **Primary CTA** | "Try again" → retry |
| **Secondary link** | "Go to notifications" → /notifications |

---

## 11. Form Validation Errors

**Inline validation (not full-screen):**

| Scenario | Message |
|---|---|
| Empty required field | "[Field name] is required" — red-50 inline below field |
| Comment too short | "Comments must be at least 3 characters" |
| Poll with no options | "Add at least 2 poll options" |
| Recognition with no reason | "Please add a reason for this recognition" |
| Recognition reason too short | "Recognition reason must be at least 10 characters" |

**Style:**
```
Inline error: 11px / 400, red-400 text (#E24B4A)
Icon: ti-alert-circle, 12px, red-400, left of text
Spacing: 4px below the input field
Input border: changes to red-200 (#F09595) on error
```

---

## 12. Rate Limit / Too Many Requests (429)

**When:** User has hit an API rate limit (e.g., too many recognition submissions).

| | |
|---|---|
| **Context** | Inline toast, not full-screen |
| **Toast** | Amber bottom toast: "Slow down — you're doing a lot at once. Try again in a moment." |
| **Duration** | 6 seconds |
| **Behavior** | The action that triggered the rate limit is queued and retried automatically after 5s |

---

## 13. Admin — Bulk Action Failure

**When:** An admin bulk action (e.g., sending nudge to 163 managers) partially fails.

| | |
|---|---|
| **Context** | Shown as inline result within admin screen |
| **Style** | Amber info card: `ti-alert-triangle` + "Sent to 148 of 163 managers. 15 failed. Retry failed sends?" |
| **CTA** | "Retry failed" → retries only the failed subset |
