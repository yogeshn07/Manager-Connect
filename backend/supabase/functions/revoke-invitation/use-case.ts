import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateRevokeInvitation } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleRevokeInvitation(
  body: unknown,
  adminId: string,
) {
  const input = validateRevokeInvitation(body);
  const adminClient = createAdminClient();

  const { data: invitation } = await adminClient
    .from('invitations')
    .select('id, status')
    .eq('id', input.invitation_id)
    .single();

  if (!invitation) {
    throw new AppError('NOT_FOUND', 'Invitation not found');
  }
  if (invitation.status !== 'pending') {
    throw new AppError(
      'CONFLICT',
      `Invitation is not pending (current status: ${invitation.status})`,
    );
  }

  const { error } = await adminClient
    .from('invitations')
    .update({ status: 'revoked' })
    .eq('id', input.invitation_id);

  if (error) {
    throw new AppError('SERVER_ERROR', 'Failed to revoke invitation');
  }

  await writeAuditLog(adminClient, {
    adminId,
    actionType: 'invitation_revoked',
    targetType: 'invitation',
    targetId: input.invitation_id,
  });

  return { success: true };
}
