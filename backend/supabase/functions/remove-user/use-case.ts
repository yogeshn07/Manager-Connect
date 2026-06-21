import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateRemoveUser } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleRemoveUser(body: unknown, adminId: string) {
  const input = validateRemoveUser(body);
  const adminClient = createAdminClient();

  const { data: profile } = await adminClient
    .from('profiles')
    .select('id, is_system_account, avatar_url')
    .eq('id', input.user_id)
    .single();

  if (!profile) {
    throw new AppError('NOT_FOUND', 'User not found');
  }
  if (profile.is_system_account) {
    throw new AppError(
      'VALIDATION_ERROR',
      'Cannot remove a system account',
    );
  }

  await adminClient
    .from('profiles')
    .update({
      full_name: 'Removed Member',
      avatar_url: null,
      bio: null,
      title: null,
      interest_tags: [],
      push_token: null,
      is_active: false,
    })
    .eq('id', input.user_id);

  if (profile.avatar_url) {
    const avatarPath = `avatars/${input.user_id}/profile.jpg`;
    await adminClient.storage.from('avatars').remove([avatarPath]);
  }

  await writeAuditLog(adminClient, {
    adminId,
    actionType: 'user_removed',
    targetType: 'user',
    targetId: input.user_id,
  });

  return { success: true };
}
