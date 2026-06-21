import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateCreatePoll } from '../_shared/validators/events.validators.ts';

export async function handleCreatePoll(body: unknown, creatorId: string) {
  const input = validateCreatePoll(body);
  const adminClient = createAdminClient();

  // Verify creator is active
  const { data: creator } = await adminClient
    .from('profiles')
    .select('id, is_active')
    .eq('id', creatorId)
    .single();

  if (!creator || !creator.is_active) {
    throw new AppError('FORBIDDEN', 'Your account is not active');
  }

  // If linked to an activity, verify it exists and is not cancelled
  if (input.activity_id) {
    const { data: activity } = await adminClient
      .from('activities')
      .select('id, status')
      .eq('id', input.activity_id)
      .single();

    if (!activity) {
      throw new AppError('NOT_FOUND', 'Activity not found');
    }
    if (activity.status === 'cancelled') {
      throw new AppError('CONFLICT', 'Cannot create poll for a cancelled activity');
    }
  }

  // Atomically insert poll + options
  const { data: poll, error: pollError } = await adminClient
    .from('polls')
    .insert({
      activity_id: input.activity_id,
      created_by: creatorId,
      question: input.question,
      closes_at: input.closes_at,
    })
    .select('id, created_at')
    .single();

  if (pollError || !poll) {
    throw new AppError('SERVER_ERROR', 'Failed to create poll');
  }

  // Insert options
  const optionRows = input.options.map((text, i) => ({
    poll_id: poll.id,
    option_text: text,
    display_order: i,
  }));

  const { error: optionsError } = await adminClient
    .from('poll_options')
    .insert(optionRows);

  if (optionsError) {
    // Rollback: delete the poll if options fail
    await adminClient.from('polls').delete().eq('id', poll.id);
    throw new AppError('SERVER_ERROR', 'Failed to create poll options');
  }

  return { poll_id: poll.id, created_at: poll.created_at };
}
