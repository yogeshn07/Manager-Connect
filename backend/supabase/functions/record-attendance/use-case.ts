import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateRecordAttendance } from '../_shared/validators/admin.validators.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleRecordAttendance(
  body: unknown,
  adminId: string,
) {
  const input = validateRecordAttendance(body);
  const adminClient = createAdminClient();

  const { data: activity } = await adminClient
    .from('activities')
    .select('id, event_date')
    .eq('id', input.activity_id)
    .single();

  if (!activity) {
    throw new AppError('NOT_FOUND', 'Activity not found');
  }

  if (new Date(activity.event_date) > new Date()) {
    throw new AppError(
      'CONFLICT',
      'Cannot record attendance before the event date',
    );
  }

  const userIds = input.records.map((r) => r.user_id);
  const { data: validProfiles } = await adminClient
    .from('profiles')
    .select('id')
    .in('id', userIds)
    .eq('is_active', true)
    .eq('is_system_account', false);

  const validIds = new Set(validProfiles?.map((p) => p.id) ?? []);
  const invalidIds = userIds.filter((id) => !validIds.has(id));
  if (invalidIds.length > 0) {
    throw new AppError(
      'VALIDATION_ERROR',
      `User IDs not found in active profiles: ${invalidIds.join(', ')}`,
    );
  }

  const upsertRows = input.records.map((r) => ({
    activity_id: input.activity_id,
    user_id: r.user_id,
    status: r.status,
    recorded_by: adminId,
    recorded_at: new Date().toISOString(),
  }));

  const { error } = await adminClient
    .from('event_attendance')
    .upsert(upsertRows, { onConflict: 'activity_id,user_id' });

  if (error) {
    throw new AppError('SERVER_ERROR', 'Failed to record attendance');
  }

  await writeAuditLog(adminClient, {
    adminId,
    actionType: 'attendance_recorded',
    targetType: 'attendance',
    targetId: input.activity_id,
    metadata: {
      activity_id: input.activity_id,
      record_count: input.records.length,
    },
  });

  return { recorded_count: input.records.length };
}
