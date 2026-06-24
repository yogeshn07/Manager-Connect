# REM-06: Enable Realtime Replication on 8 Tables

## Problem

Supabase Realtime requires explicit replication enablement per table. Currently only 2 channels are active in code (`feed:posts`, `notifications:inbox`). The remaining 5 V2 channels cannot function until replication is enabled on their underlying tables.

## Severity: LOW (V2 feature, not blocking launch)

## Affected Tables

| Table | Channel | Current Status |
|-------|---------|---------------|
| posts | `feed:posts` | Code active, replication status unknown |
| notification_inbox | `notifications:inbox` | Code active, replication status unknown |
| post_reactions | `feed:reactions` | V2 deferred |
| comments | `feed:comments` | V2 deferred |
| activity_rsvps | `activities:rsvps` | V2 deferred |
| poll_votes | `events:poll_votes` | V2 deferred |
| progress_logs | `growth:leaderboard` | V2 deferred |
| recognitions | `recognitions` | V2 deferred |

## Architecture

Enable via Supabase dashboard or SQL:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE notification_inbox;
ALTER PUBLICATION supabase_realtime ADD TABLE post_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_rsvps;
ALTER PUBLICATION supabase_realtime ADD TABLE poll_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE progress_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE recognitions;
```

## Files Impacted

| File | Change |
|------|--------|
| New migration | `20260624000002_enable_realtime_replication.sql` |

## Validation Steps

1. Run migration
2. Verify `feed:posts` channel receives INSERT events
3. Verify `notifications:inbox` channel receives INSERT events

## Estimated Effort: 30 minutes
