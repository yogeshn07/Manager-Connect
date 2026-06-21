import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { hashToken } from '../_shared/crypto.ts';
import { CONNECT_BUDDY_PROFILE_ID } from '../_shared/constants.ts';
import { validateCreateProfile } from '../_shared/validators/auth.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handleCreateProfile(body: unknown, authUserId: string) {
  const input = validateCreateProfile(body);
  const adminClient = createAdminClient();

  // Re-validate invite token
  const tokenHash = await hashToken(input.token);
  const { data: invitation } = await adminClient
    .from('invitations')
    .select('id, status, expires_at')
    .eq('token_hash', tokenHash)
    .single();

  if (!invitation || invitation.status !== 'pending' || new Date(invitation.expires_at) < new Date()) {
    throw new AppError('NOT_FOUND', 'Invalid or expired invitation token');
  }

  // Check profile doesn't already exist
  const { data: existingProfile } = await adminClient
    .from('profiles')
    .select('id')
    .eq('id', authUserId)
    .single();

  if (existingProfile) {
    throw new AppError('CONFLICT', 'Profile already exists for this user');
  }

  // Create profile
  const { error: profileError } = await adminClient.from('profiles').insert({
    id: authUserId,
    full_name: input.full_name,
    title: input.title,
    bio: input.bio,
    avatar_url: input.avatar_storage_path,
    interest_tags: input.interest_tags,
    onboarding_completed: true,
  });

  if (profileError) {
    throw new AppError('SERVER_ERROR', 'Failed to create profile');
  }

  // Mark invitation as accepted
  await adminClient
    .from('invitations')
    .update({ status: 'accepted', accepted_by: authUserId })
    .eq('id', invitation.id);

  // Post Connect Buddy welcome message
  const welcomeContent = `Welcome to the community, ${input.full_name}! 🎉 We're glad to have you here.`;
  await adminClient.from('posts').insert({
    author_id: CONNECT_BUDDY_PROFILE_ID,
    content: welcomeContent,
  });

  // Notify admins of new member registration
  const { data: admins } = await adminClient
    .from('profiles')
    .select('id')
    .eq('app_role', 'admin')
    .eq('is_active', true);

  if (admins && admins.length > 0) {
    await dispatchNotification(adminClient, {
      recipientIds: admins.map((a) => a.id),
      type: 'admin_member_registered',
      title: 'New member joined',
      body: `${input.full_name} has joined the community`,
      referenceType: 'user',
      referenceId: authUserId,
    });
  }

  return { profile_id: authUserId };
}
