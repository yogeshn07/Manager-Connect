import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { hashToken } from '../_shared/crypto.ts';
import { INVITE_TOKEN_EXPIRY_HOURS } from '../_shared/constants.ts';
import { validateSendInvitation } from '../_shared/validators/auth.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleSendInvitation(body: unknown, adminId: string) {
  const input = validateSendInvitation(body);
  const adminClient = createAdminClient();

  const { data: existing } = await adminClient
    .from('invitations')
    .select('id')
    .eq('status', 'pending')
    .or(
      [
        input.invitee_email ? `invitee_email.eq.${input.invitee_email}` : '',
        input.invitee_phone ? `invitee_phone.eq.${input.invitee_phone}` : '',
      ]
        .filter(Boolean)
        .join(','),
    )
    .limit(1);

  if (existing && existing.length > 0) {
    throw new AppError('CONFLICT', 'A pending invitation already exists for this contact');
  }

  const rawToken = crypto.randomUUID();
  const tokenHash = await hashToken(rawToken);
  const expiresAt = new Date(Date.now() + INVITE_TOKEN_EXPIRY_HOURS * 60 * 60 * 1000).toISOString();

  const { data: invitation, error } = await adminClient
    .from('invitations')
    .insert({
      invitee_name: input.invitee_name,
      invitee_email: input.invitee_email,
      invitee_phone: input.invitee_phone,
      token_hash: tokenHash,
      status: 'pending',
      invited_by: adminId,
      expires_at: expiresAt,
    })
    .select('id')
    .single();

  if (error || !invitation) {
    throw new AppError('SERVER_ERROR', 'Failed to create invitation');
  }

  await writeAuditLog(adminClient, {
    adminId,
    actionType: 'user_invited',
    targetType: 'invitation',
    targetId: invitation.id,
  });

  const inviteUrl = `managerconnect://invite?token=${rawToken}`;

  return {
    invitation_id: invitation.id,
    invite_url: inviteUrl,
    status: 'pending',
    expires_at: expiresAt,
  };
}
