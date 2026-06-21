import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateResolveFlag } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleResolveFlag(body: unknown, adminId: string) {
  const input = validateResolveFlag(body);
  const adminClient = createAdminClient();

  const { data: flag } = await adminClient
    .from('flagged_content')
    .select('id, content_type, content_id, status')
    .eq('id', input.flag_id)
    .single();

  if (!flag) {
    throw new AppError('NOT_FOUND', 'Flag not found');
  }
  if (flag.status !== 'pending') {
    throw new AppError('CONFLICT', 'Flag is already resolved');
  }

  if (input.action === 'delete') {
    const table = flag.content_type === 'post' ? 'posts' : 'comments';

    const { error: deleteError } = await adminClient
      .from(table)
      .update({
        is_deleted: true,
        deleted_by: adminId,
        deleted_at: new Date().toISOString(),
      })
      .eq('id', flag.content_id);

    if (deleteError) {
      throw new AppError('SERVER_ERROR', `Failed to delete ${flag.content_type}`);
    }

    await adminClient
      .from('flagged_content')
      .update({
        status: 'resolved_deleted',
        resolved_by: adminId,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', input.flag_id);

    const deleteActionType = flag.content_type === 'post' ? 'post_deleted' : 'comment_deleted';
    await writeAuditLog(adminClient, {
      adminId,
      actionType: deleteActionType as 'post_deleted' | 'comment_deleted',
      targetType: flag.content_type as 'post' | 'comment',
      targetId: flag.content_id,
    });

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'flag_resolved_deleted',
      targetType: 'flag',
      targetId: input.flag_id,
    });
  } else {
    await adminClient
      .from('flagged_content')
      .update({
        status: 'resolved_dismissed',
        resolved_by: adminId,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', input.flag_id);

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'flag_resolved_dismissed',
      targetType: 'flag',
      targetId: input.flag_id,
    });
  }

  return { resolved: true, action_taken: input.action };
}
