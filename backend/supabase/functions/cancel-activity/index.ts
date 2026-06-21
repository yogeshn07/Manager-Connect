import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleCancelActivity } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    const { userId, client } = await requireAuth(req);
    const body = await req.json();
    const result = await handleCancelActivity(body, userId, client);
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
