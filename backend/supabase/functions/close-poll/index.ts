import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireAuth, requireAdmin, requireServiceRole } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleClosePoll } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    let adminId: string;
    const authHeader = req.headers.get('Authorization') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const token = authHeader.replace('Bearer ', '');
    const isServiceRole = token === serviceRoleKey && serviceRoleKey !== '';

    if (isServiceRole) {
      requireServiceRole(req);
      adminId = 'service_role';
    } else {
      const { userId, client } = await requireAuth(req);
      await requireAdmin(userId, client);
      adminId = userId;
    }

    const body = await req.json();
    const result = await handleClosePoll(body, adminId);
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
