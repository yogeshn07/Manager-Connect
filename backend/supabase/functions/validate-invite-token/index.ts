import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { handleValidateInviteToken } from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    const body = await req.json();
    const result = await handleValidateInviteToken(body);
    return jsonResponse(result);
  } catch (error) {
    return toErrorResponse(error);
  }
});
