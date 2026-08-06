# Monitoring & Error Reporting

## 1. Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│ Flutter Web  │───▶│  Sentry SDK │───▶│  Sentry Cloud   │
│  (Client)    │    │  (Dart)     │    │  (Alerts/Dash)  │
└─────────────┘    └─────────────┘    └─────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│ Edge Funcs   │───▶│ Sentry SDK  │───▶│  Sentry Cloud   │
│ (Deno)       │    │ (Deno)      │    │  (same project) │
└─────────────┘    └─────────────┘    └─────────────────┘

┌─────────────┐    ┌─────────────────────────────────────┐
│  Supabase    │───▶│ Supabase Dashboard (built-in)       │
│  (Database)  │    │ Logs, Metrics, API usage             │
└─────────────┘    └─────────────────────────────────────┘
```

## 2. Sentry Integration (Flutter Client)

### Setup

```bash
cd frontend
flutter pub add sentry_flutter
```

### Configuration

In `main.dart`, wrap the app initialization:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment(
        'SENTRY_ENV',
        defaultValue: 'development',
      );
      options.tracesSampleRate = 0.2; // 20% of transactions
      options.attachScreenshot = true;
    },
    appRunner: () => runApp(
      const ProviderScope(child: ManagerConnectApp()),
    ),
  );
}
```

### Build with Sentry

```bash
flutter build web --release --no-web-resources-cdn \
  --dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy \
  --dart-define=SENTRY_ENV=production \
  # ... other dart-defines
```

### Custom Error Capture

For repository-level errors:

```dart
try {
  final response = await supabase.from('posts').select();
  return response;
} catch (e, stackTrace) {
  await Sentry.captureException(e, stackTrace: stackTrace);
  rethrow;
}
```

## 3. Sentry Integration (Edge Functions)

### Setup in shared handler

In `backend/supabase/functions/_shared/sentry.ts`:

```typescript
import * as Sentry from "https://deno.land/x/sentry/index.mjs";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  environment: Deno.env.get("SENTRY_ENV") || "production",
  tracesSampleRate: 0.5,
});

export { Sentry };
```

### Usage in Edge Functions

```typescript
import { Sentry } from "../_shared/sentry.ts";

try {
  // function logic
} catch (error) {
  Sentry.captureException(error);
  return new Response(JSON.stringify({ error: "Internal error" }), {
    status: 500,
  });
}
```

### Deploy secret

```bash
supabase secrets set SENTRY_DSN=https://xxx@sentry.io/yyy --project-ref <ref>
supabase secrets set SENTRY_ENV=production --project-ref <ref>
```

## 4. Supabase Built-in Monitoring

### Database Metrics (Dashboard → Reports)

| Metric | What to Watch | Alert Threshold |
|--------|--------------|-----------------|
| Active connections | Concurrent DB connections | > 50 (Pro plan limit: 60) |
| Database size | Storage usage | > 4 GB (Pro plan: 8 GB) |
| API request count | Edge Function invocations | > 10K/day for pilot |

### Edge Function Logs (Dashboard → Edge Functions → Logs)

- View invocation logs per function
- Filter by status code (watch for 4xx/5xx spikes)
- Check execution time (watch for > 5s)

### Auth Metrics (Dashboard → Authentication)

- Daily active users
- Sign-in attempts / failures
- OTP email send rate

## 5. Uptime Monitoring

### Option A: UptimeRobot (Free tier)

1. Create account at [uptimerobot.com](https://uptimerobot.com)
2. Add monitor:
   - **Type:** HTTP(S)
   - **URL:** `https://your-domain.com`
   - **Interval:** 5 minutes
3. Add alert contact (email / Slack webhook)

### Option B: Supabase Health Check

Monitor the Supabase API:

- **URL:** `https://xxx.supabase.co/rest/v1/` with anon key header
- Expected: 200 OK

## 6. Alerting Rules

### Sentry Alerts

Configure in Sentry → Alerts → Create Alert Rule:

| Alert | Condition | Action |
|-------|-----------|--------|
| New error | First occurrence of any issue | Email immediately |
| Error spike | > 10 events in 1 hour | Email + Slack |
| Edge Function failure | Issue tagged `edge-function` | Email immediately |
| Unhandled exception | `handled: false` | Email immediately |

### Supabase Alerts

Configure in Supabase Dashboard → Settings → Notifications:

- Database approaching size limit
- High API error rate
- Auth rate limit approaching

## 7. Key Metrics Dashboard

### Pilot Phase (10-50 users)

Track weekly:

| Metric | Source | Target |
|--------|--------|--------|
| Daily Active Users | Supabase Auth | Growing |
| Posts per day | `SELECT count(*) FROM posts WHERE created_at > now() - interval '1 day'` | > 5 |
| Error rate | Sentry | < 1% of sessions |
| Edge Function P95 latency | Supabase logs | < 2s |
| Web first-load time | Browser DevTools / Sentry Performance | < 20s |
| Auth success rate | Supabase Auth metrics | > 95% |
| Push notification delivery | FCM console | > 90% |

### SQL Queries for Pilot Metrics

```sql
-- Active users (last 7 days)
SELECT count(DISTINCT id) FROM profiles
WHERE last_active_at > now() - interval '7 days';

-- Posts per day
SELECT date_trunc('day', created_at) as day, count(*)
FROM posts
GROUP BY day ORDER BY day DESC LIMIT 7;

-- Most active users
SELECT p.display_name, count(*) as posts
FROM posts po JOIN profiles p ON po.author_id = p.id
GROUP BY p.display_name ORDER BY posts DESC LIMIT 10;

-- Feature usage
SELECT
  (SELECT count(*) FROM posts) as total_posts,
  (SELECT count(*) FROM comments) as total_comments,
  (SELECT count(*) FROM post_reactions) as total_reactions,
  (SELECT count(*) FROM recognitions) as total_recognitions,
  (SELECT count(*) FROM activities WHERE type = 'event') as total_events,
  (SELECT count(*) FROM activities WHERE type = 'poll') as total_polls,
  (SELECT count(*) FROM challenges) as total_challenges;
```

## 8. Logging Strategy

### Current State

- Flutter: `dart:developer` `log()` — visible in browser DevTools console
- Edge Functions: `console.log()` — visible in Supabase dashboard logs

### Production Enhancement

No code changes needed for pilot. The existing logging is sufficient:
- Client errors → Sentry captures automatically
- Edge Function errors → Supabase logs retain for 7 days (Pro plan)
- Database queries → Supabase query performance advisor

### Future: Structured Logging

For production scale, consider migrating to structured JSON logs with correlation IDs. Not needed for pilot.

## 9. Setup Checklist

- [ ] Create Sentry project (Flutter + Deno)
- [ ] Get Sentry DSN
- [ ] Add `sentry_flutter` to pubspec.yaml
- [ ] Wrap main() with SentryFlutter.init
- [ ] Add SENTRY_DSN to build dart-defines
- [ ] Add SENTRY_DSN to Supabase Edge Function secrets
- [ ] Configure Sentry alert rules (new error, spike, unhandled)
- [ ] Set up uptime monitoring (UptimeRobot or equivalent)
- [ ] Verify Supabase dashboard metrics are accessible
- [ ] Test: throw test exception → verify it appears in Sentry
