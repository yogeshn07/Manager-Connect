import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateDeactivateUser } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleDeactivateUser(body: unknown, adminId: string) {
  const input = validateDeactivateUser(body);
  const adminClient = createAdminClient();

  const { data: profile } = await adminClient
    .from('profiles')
    .select('id, is_active, is_system_account')
    .eq('id', input.user_id)
    .single();

  if (!profile) {
    throw new AppError('NOT_FOUND', 'User not found');
  }
  if (profile.is_system_account) {
    throw new AppError(
      'VALIDATION_ERROR',
      'Cannot deactivate or reactivate a system account',
    );
  }

  if (input.reactivate) {
    if (profile.is_active) {
      throw new AppError('CONFLICT', 'User is already active');
    }

    await adminClient
      .from('profiles')
      .update({ is_active: true })
      .eq('id', input.user_id);

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'user_reactivated',
      targetType: 'user',
      targetId: input.user_id,
    });

    return { success: true, user_id: input.user_id, is_active: true };
  } else {
    if (!profile.is_active) {
      throw new AppError('CONFLICT', 'User is already deactivated');
    }

    await adminClient
      .from('profiles')
      .update({ is_active: false, push_token: null })
      .eq('id', input.user_id);

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'user_deactivated',
      targetType: 'user',
      targetId: input.user_id,
    });

    return { success: true, user_id: input.user_id, is_active: false };
  }
}
