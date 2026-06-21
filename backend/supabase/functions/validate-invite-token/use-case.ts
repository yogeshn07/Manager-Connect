import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { hashToken } from '../_shared/crypto.ts';
import { validateInviteToken } from '../_shared/validators/auth.validators.ts';

export async function handleValidateInviteToken(body: unknown) {
  const input = validateInviteToken(body);
  const tokenHash = await hashToken(input.token);
  const adminClient = createAdminClient();

  const { data: invitation, error } = await adminClient
    .from('invitations')
    .select('id, invitee_name, invitee_email, invitee_phone, status, expires_at')
    .eq('token_hash', tokenHash)
    .single();

  if (error || !invitation) {
    throw new AppError('NOT_FOUND', 'Invalid invitation token');
  }

  if (invitation.status !== 'pending') {
    throw new AppError('CONFLICT', `Invitation has already been ${invitation.status}`);
  }

  if (new Date(invitation.expires_at) < new Date()) {
    throw new AppError('CONFLICT', 'Invitation has expired');
  }

  return {
    valid: true,
    invitation_id: invitation.id,
    invitee_name: invitation.invitee_name,
    invitee_email: invitation.invitee_email,
    invitee_phone: invitation.invitee_phone,
  };
}
