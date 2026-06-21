import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

type ActionType =
  | 'user_invited'
  | 'user_deactivated'
  | 'user_reactivated'
  | 'user_removed'
  | 'invitation_revoked'
  | 'post_deleted'
  | 'comment_deleted'
  | 'flag_resolved_deleted'
  | 'flag_resolved_dismissed'
  | 'content_pinned'
  | 'content_unpinned'
  | 'attendance_recorded'
  | 'poll_closed';

type TargetType =
  | 'user'
  | 'post'
  | 'comment'
  | 'flag'
  | 'announcement'
  | 'attendance'
  | 'poll'
  | 'invitation';

interface AuditEntry {
  adminId: string;
  actionType: ActionType;
  targetType?: TargetType;
  targetId?: string;
  metadata?: Record<string, unknown>;
}

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function writeAuditLog(
  adminClient: SupabaseClient,
  entry: AuditEntry,
): Promise<void> {
  if (!UUID_REGEX.test(entry.adminId)) {
    return;
  }

  const { error } = await adminClient.from('admin_audit_log').insert({
    admin_id: entry.adminId,
    action_type: entry.actionType,
    target_type: entry.targetType ?? null,
    target_id: entry.targetId ?? null,
    metadata: entry.metadata ?? null,
  });

  if (error) {
    console.error('Failed to write audit log:', error.message);
    throw error;
  }
}
