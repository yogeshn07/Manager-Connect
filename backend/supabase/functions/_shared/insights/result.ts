// Catalyst Insights Pipeline — Result<T, E> type
// Railway-oriented error handling for pipeline stages.
// Each stage returns Result<T, PipelineError> instead of throwing,
// allowing callers to pattern-match on ok/error without try/catch boilerplate.
//
// Usage:
//   const result = await validateDomain(url, source);
//   if (!result.ok) {
//     logger.warn('Domain mismatch', { url, code: result.error.code });
//     return err(result.error);
//   }
//   const { value } = result; // type narrowed to T

export type Ok<T>  = { readonly ok: true;  readonly value: T };
export type Err<E> = { readonly ok: false; readonly error: E };
export type Result<T, E = Error> = Ok<T> | Err<E>;

export function ok<T>(value: T): Ok<T> {
  return { ok: true, value };
}

export function err<E>(error: E): Err<E> {
  return { ok: false, error };
}

export function isOk<T, E>(result: Result<T, E>): result is Ok<T> {
  return result.ok === true;
}

export function isErr<T, E>(result: Result<T, E>): result is Err<E> {
  return result.ok === false;
}

// Unwraps a Result or throws its error. Use only at pipeline boundaries
// where the caller cannot meaningfully recover from the failure.
export function unwrap<T, E extends Error>(result: Result<T, E>): T {
  if (result.ok) return result.value;
  throw result.error;
}
