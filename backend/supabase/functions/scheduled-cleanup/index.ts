import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleScheduledCleanup } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    requireServiceRole(req);
    const result = await handleScheduledCleanup();
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
