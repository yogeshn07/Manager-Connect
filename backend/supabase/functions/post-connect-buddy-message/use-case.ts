import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { CONNECT_BUDDY_PROFILE_ID } from '../_shared/constants.ts';
import { validateConnectBuddyPost } from '../_shared/validators/feed.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handlePostConnectBuddyMessage(body: unknown) {
  const input = validateConnectBuddyPost(body);
  const adminClient = createAdminClient();

  // Verify Connect Buddy profile exists
  const { data: cbProfile } = await adminClient
    .from('profiles')
    .select('id')
    .eq('id', CONNECT_BUDDY_PROFILE_ID)
    .single();

  if (!cbProfile) {
    throw new AppError('SERVER_ERROR', 'Connect Buddy system profile not found');
  }

  // Insert post as Connect Buddy
  const { data: post, error: postError } = await adminClient
    .from('posts')
    .insert({ author_id: CONNECT_BUDDY_PROFILE_ID, content: input.content })
    .select('id')
    .single();

  if (postError || !post) {
    throw new AppError('SERVER_ERROR', 'Failed to create Connect Buddy post');
  }

  // Insert images if provided
  if (input.image_storage_paths.length > 0) {
    const imageRows = input.image_storage_paths.map((path, i) => ({
      post_id: post.id,
      storage_path: path,
      display_order: i,
    }));
    await adminClient.from('post_images').insert(imageRows);
  }

  // Notify all members if requested
  if (input.notify_all && input.notification_title && input.notification_body) {
    const { data: members } = await adminClient
      .from('profiles')
      .select('id')
      .eq('is_active', true)
      .eq('is_system_account', false);

    if (members && members.length > 0) {
      await dispatchNotification(adminClient, {
        recipientIds: members.map((m) => m.id),
        type: 'connect_buddy_update',
        title: input.notification_title,
        body: input.notification_body,
        referenceType: 'post',
        referenceId: post.id,
      });
    }
  }

  return { post_id: post.id };
}
