import { corsHeaders } from './cors.ts';

export type ErrorCode =
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'VALIDATION_ERROR'
  | 'SERVER_ERROR';

const STATUS_MAP: Record<ErrorCode, number> = {
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  VALIDATION_ERROR: 422,
  SERVER_ERROR: 500,
};

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly httpStatus: number;

  constructor(code: ErrorCode, message: string) {
    super(message);
    this.code = code;
    this.httpStatus = STATUS_MAP[code];
  }
}

export function toErrorResponse(error: unknown): Response {
  if (error instanceof AppError) {
    return new Response(
      JSON.stringify({ error: { code: error.code, message: error.message } }),
      {
        status: error.httpStatus,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }

  console.error('Unhandled error:', error);
  return new Response(
    JSON.stringify({
      error: { code: 'SERVER_ERROR', message: 'Internal server error' },
    }),
    {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    },
  );
}
