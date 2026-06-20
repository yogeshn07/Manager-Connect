import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { AppError } from './errors.ts';
import { createUserClient } from './supabase-client.ts';

interface AuthResult {
  userId: string;
  jwt: string;
  client: SupabaseClient;
}

export async function requireAuth(req: Request): Promise<AuthResult> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new AppError('UNAUTHORIZED', 'Missing authorization header');
  }

  const client = createUserClient(authHeader);
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new AppError('UNAUTHORIZED', 'Invalid or expired token');
  }

  return { userId: user.id, jwt: authHeader, client };
}

export async function requireAdmin(
  userId: string,
  client: SupabaseClient,
): Promise<void> {
  const { data: profile } = await client
    .from('profiles')
    .select('app_role, is_active')
    .eq('id', userId)
    .single();

  if (!profile || profile.app_role !== 'admin' || !profile.is_active) {
    throw new AppError('FORBIDDEN', 'Admin access required');
  }
}

export function requireServiceRole(req: Request): void {
  const authHeader = req.headers.get('Authorization');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!authHeader || !serviceRoleKey) {
    throw new AppError('UNAUTHORIZED', 'Service role key required');
  }

  const token = authHeader.replace('Bearer ', '');
  if (token !== serviceRoleKey) {
    throw new AppError('UNAUTHORIZED', 'Invalid service role key');
  }
}
