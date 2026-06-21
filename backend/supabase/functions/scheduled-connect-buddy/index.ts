import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleScheduledConnectBuddy } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    requireServiceRole(req);
    const body = await req.json();
    const result = await handleScheduledConnectBuddy(body);
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
