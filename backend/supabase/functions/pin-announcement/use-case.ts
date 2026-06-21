import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validatePinAnnouncement } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handlePinAnnouncement(
  body: unknown,
  adminId: string,
) {
  const input = validatePinAnnouncement(body);
  const adminClient = createAdminClient();

  if (input.action === 'pin') {
    const { data: post } = await adminClient
      .from('posts')
      .select('id, is_deleted')
      .eq('id', input.post_id!)
      .single();

    if (!post) {
      throw new AppError('NOT_FOUND', 'Post not found');
    }
    if (post.is_deleted) {
      throw new AppError('CONFLICT', 'Cannot pin a deleted post');
    }

    await adminClient
      .from('pinned_announcements')
      .update({ is_active: false })
      .eq('is_active', true);

    const { error } = await adminClient
      .from('pinned_announcements')
      .insert({
        post_id: input.post_id!,
        pinned_by: adminId,
        is_active: true,
      });

    if (error) {
      throw new AppError('SERVER_ERROR', 'Failed to pin announcement');
    }

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'content_pinned',
      targetType: 'announcement',
      targetId: input.post_id!,
    });
  } else {
    await adminClient
      .from('pinned_announcements')
      .update({ is_active: false })
      .eq('is_active', true);

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'content_unpinned',
      targetType: 'announcement',
    });
  }

  return { success: true };
}
