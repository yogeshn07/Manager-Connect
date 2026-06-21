import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateCreateRecognition } from '../_shared/validators/recognition.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handleCreateRecognition(body: unknown, giverId: string) {
  const input = validateCreateRecognition(body);
  const adminClient = createAdminClient();

  // Verify giver is active
  const { data: giver } = await adminClient
    .from('profiles')
    .select('id, is_active, full_name')
    .eq('id', giverId)
    .single();

  if (!giver || !giver.is_active) {
    throw new AppError('FORBIDDEN', 'Your account is not active');
  }

  // Verify all recipients exist and are active (non-system)
  const { data: validRecipients } = await adminClient
    .from('profiles')
    .select('id')
    .in('id', input.recipient_ids)
    .eq('is_active', true)
    .eq('is_system_account', false);

  const validIds = validRecipients?.map((r) => r.id) ?? [];
  if (validIds.length === 0) {
    throw new AppError('NOT_FOUND', 'No valid active recipients found');
  }

  // Insert recognition
  const { data: recognition, error: recogError } = await adminClient
    .from('recognitions')
    .insert({
      giver_id: giverId,
      category_tag: input.category_tag,
      message: input.message,
    })
    .select('id, created_at')
    .single();

  if (recogError || !recognition) {
    throw new AppError('SERVER_ERROR', 'Failed to create recognition');
  }

  // Insert recipients
  const recipientRows = validIds.map((recipientId) => ({
    recognition_id: recognition.id,
    recipient_id: recipientId,
  }));

  const { error: recipientsError } = await adminClient
    .from('recognition_recipients')
    .insert(recipientRows);

  if (recipientsError) {
    await adminClient.from('recognitions').delete().eq('id', recognition.id);
    throw new AppError('SERVER_ERROR', 'Failed to add recognition recipients');
  }

  // Notify recipients
  await dispatchNotification(adminClient, {
    recipientIds: validIds,
    type: 'recognition_received',
    title: `${giver.full_name} recognized you!`,
    body: input.message.substring(0, 60),
    referenceType: 'recognition',
    referenceId: recognition.id,
  });

  return { recognition_id: recognition.id, created_at: recognition.created_at };
}
