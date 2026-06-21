import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireAuth, requireAdmin } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleRecordAttendance } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    const { userId, client } = await requireAuth(req);
    await requireAdmin(userId, client);
    const body = await req.json();
    const result = await handleRecordAttendance(body, userId);
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
