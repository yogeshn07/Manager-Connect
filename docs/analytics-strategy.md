# Analytics Strategy

## Philosophy

Manager Connect is a private, trust-based community. Analytics must serve the platform admin's ability to keep the community healthy — not to surveil members or track individual behavior in invasive ways. Analytics is a tool for community health, not management intelligence.

**What analytics is for:**
- Understanding which features drive engagement
- Helping the admin see if the community is thriving or declining
- Identifying technical issues (crashes, slow loads)

**What analytics is not for:**
- Tracking individual member behavior for HR purposes
- Comparing individual manager participation for performance
- Sharing data outside the platform

---

## Analytics Tool

**PostHog** (cloud-hosted, EU region preferred for data residency)

| Why PostHog |
|-------------|
| Open-source and auditable |
| Self-host option available if required |
| Event-based, not session-recording-based |
| No third-party ad network integrations |
| Privacy-first configuration supported |
| Free tier sufficient for 20 users |

---

## Privacy Configuration

- **No PII in event properties.** User IDs are included (anonymized internal IDs only — not names or emails).
- **No session replay.** PostHog session recording is disabled.
- **No heatmaps.** Not applicable to mobile and not desired.
- **IP masking enabled.** User IP addresses are not stored.
- **Data stored in EU region** (or self-hosted) to meet organizational data residency expectations.

---

## Events Tracked

### Feature Engagement Events

| Event | Properties |
|-------|------------|
| `post_created` | post_type (text/photo) |
| `post_reacted` | emoji_type |
| `comment_added` | — |
| `activity_created` | — |
| `activity_rsvp_submitted` | rsvp_status (going/not_going/maybe) |
| `challenge_joined` | goal_type |
| `challenge_progress_logged` | — |
| `recognition_given` | category_tag |
| `dm_sent` | — |
| `group_message_sent` | — |

### Navigation Events

| Event | Properties |
|-------|------------|
| `screen_viewed` | screen_name |
| `tab_tapped` | tab_name |

### Notification Events

| Event | Properties |
|-------|------------|
| `notification_tapped` | notification_type |
| `notification_permission_granted` | — |
| `notification_permission_denied` | — |

### Technical Events

| Event | Properties |
|-------|------------|
| `app_opened` | cold_start (boolean) |
| `api_error` | error_code, screen_name |
| `image_upload_failed` | — |

---

## Community Health Metrics (Admin Dashboard)

These are lightweight metrics surfaced to the admin within the Admin Panel (not in PostHog directly). They are computed from the Supabase database, not the analytics tool.

| Metric | Definition |
|--------|------------|
| Monthly Active Users (MAU) | Members who opened the app at least once in the past 30 days |
| Posts This Month | Total posts created in the current calendar month |
| Activities Created This Month | Total activities posted in the current month |
| Recognition Wall Posts This Month | Total recognitions posted this month |
| Challenge Participation Rate | Percentage of members who joined at least one active challenge |

These metrics reset monthly and are stored as materialized views or computed on query.

---

## What Is Not Tracked

- Individual member's session duration or time-in-app
- Which specific members viewed which posts
- Message content (zero analytics on message bodies)
- Challenge progress values of specific users (leaderboard is sufficient)
- Scroll depth or tap coordinates

---

## Analytics Review Cadence

- **Admin:** Reviews community health metrics monthly.
- **Platform owner:** Reviews PostHog event data quarterly to inform feature roadmap.
- **No automated reporting emails** in V1. Admin visits admin panel manually.

---

## Future Analytics (V2+)

- Weekly digest to admin: active users, top activity, new members
- Trend view: engagement over last 3 months
- Export to CSV for offline analysis (with PII stripped)
