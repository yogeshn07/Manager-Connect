-- REM-06: Enable Realtime Replication on 8 Tables
-- Supabase Realtime requires explicit publication membership.

ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE notification_inbox;
ALTER PUBLICATION supabase_realtime ADD TABLE post_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_rsvps;
ALTER PUBLICATION supabase_realtime ADD TABLE poll_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE progress_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE recognitions;
