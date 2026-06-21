import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleCreatePoll } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    const { userId } = await requireAuth(req);
    const body = await req.json();
    const result = await handleCreatePoll(body, userId);
    return jsonResponse(result, 201);
  } catch (error) {
    return toErrorResponse(error);
  }
});
