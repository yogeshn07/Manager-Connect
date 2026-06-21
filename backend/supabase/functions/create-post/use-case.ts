import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateCreatePost } from '../_shared/validators/feed.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

const MENTION_PATTERN = /@([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})/gi;

function extractMentions(content: string): string[] {
  const matches = content.matchAll(MENTION_PATTERN);
  const ids = new Set<string>();
  for (const match of matches) {
    ids.add(match[1].toLowerCase());
  }
  return Array.from(ids);
}

export async function handleCreatePost(body: unknown, authorId: string) {
  const input = validateCreatePost(body);
  const adminClient = createAdminClient();

  // Verify author is active
  const { data: author } = await adminClient
    .from('profiles')
    .select('id, is_active')
    .eq('id', authorId)
    .single();

  if (!author || !author.is_active) {
    throw new AppError('FORBIDDEN', 'Your account is not active');
  }

  // Insert post
  const { data: post, error: postError } = await adminClient
    .from('posts')
    .insert({ author_id: authorId, content: input.content })
    .select('id, created_at')
    .single();

  if (postError || !post) {
    throw new AppError('SERVER_ERROR', 'Failed to create post');
  }

  // Insert images
  if (input.image_storage_paths.length > 0) {
    const imageRows = input.image_storage_paths.map((path, i) => ({
      post_id: post.id,
      storage_path: path,
      display_order: i,
    }));
    await adminClient.from('post_images').insert(imageRows);
  }

  // Parse and insert mentions
  const mentionedIds = extractMentions(input.content);
  if (mentionedIds.length > 0) {
    // Verify mentioned users exist
    const { data: validUsers } = await adminClient
      .from('profiles')
      .select('id')
      .in('id', mentionedIds)
      .eq('is_active', true)
      .eq('is_system_account', false);

    const validIds = validUsers?.map((u) => u.id) ?? [];

    if (validIds.length > 0) {
      const mentionRows = validIds.map((uid) => ({
        post_id: post.id,
        mentioned_user_id: uid,
      }));
      await adminClient.from('post_mentions').insert(mentionRows);

      // Notify mentioned users
      await dispatchNotification(adminClient, {
        recipientIds: validIds,
        type: 'mention',
        title: 'You were mentioned',
        body: 'Someone mentioned you in a post',
        referenceType: 'post',
        referenceId: post.id,
      });
    }
  }

  return { post_id: post.id, created_at: post.created_at };
}
