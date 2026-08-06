// Catalyst Insights Pipeline — AI client abstraction (S3-BE-003)
// Provider-independent HTTP transport for AI chat completions.
//
// Responsibilities:
//   • OpenAI request builder (model, messages, response_format, temperature, max_tokens)
//   • Per-request timeout via AbortController
//   • Retry with exponential backoff (up to MAX_RETRIES attempts)
//   • Precise retryable vs. non-retryable error classification by HTTP status
//   • JSON content validation (verified parseable before returning to caller)
//   • Usage metadata extraction (prompt / completion / total tokens)
//   • Provider-independent response model (discriminant field: provider: 'openai')
//   • Structured logging on every retry and on retry recovery
//
// Callers: enrich_insight use-case.ts (step 7–8)
// Does NOT contain prompt engineering — prompts are owned by the caller.

import { PipelineError } from './errors.ts';
import { logger } from './logger.ts';

// ─── Provider-independent types ───────────────────────────────────────────────

export interface AiChatMessage {
  role:    'system' | 'user' | 'assistant';
  content: string;
}

// Input contract — caller supplies messages and sampling parameters.
// json_object response_format is always enforced by this module for pipeline safety.
export interface AiChatRequest {
  messages:    AiChatMessage[];
  temperature: number;
  max_tokens:  number;
}

export interface AiUsageMetadata {
  prompt_tokens:     number;
  completion_tokens: number;
  total_tokens:      number;
}

// Output contract — provider-independent.
// `content` is a raw JSON string, verified parseable but not yet typed.
// Caller is responsible for domain-specific validation (parseAndValidateAiResponse).
export interface AiChatResponse {
  content:  string;          // raw JSON string from the model (guaranteed parseable)
  usage:    AiUsageMetadata | null;
  model:    string;          // model identifier echoed from API response
  provider: 'openai';        // discriminant for future provider union
}

// ─── OpenAI config (private to module) ───────────────────────────────────────

const OPENAI_CHAT_URL = 'https://api.openai.com/v1/chat/completions';
// gpt-4o-mini: cost-effective for a high-volume content pipeline while
// delivering sufficient quality for the 6-category classification task.
const OPENAI_MODEL    = 'gpt-4o-mini';

// ─── Retry config ─────────────────────────────────────────────────────────────

const MAX_RETRIES        = 3;      // up to 4 total attempts (initial + 3 retries)
const INITIAL_BACKOFF_MS = 1_000;  // 1 s → 2 s → 4 s
const BACKOFF_MULTIPLIER = 2;
const BACKOFF_JITTER_MS  = 200;    // ±200 ms per attempt to spread thundering-herd retries

// HTTP status codes from OpenAI that indicate a transient failure worth retrying.
// 4xx errors (except 429 rate-limit) are NOT retried — the request itself is invalid.
const RETRYABLE_HTTP_STATUSES = new Set<number>([429, 500, 502, 503, 504]);

const FN = 'ai_client';

// ─── Single attempt ───────────────────────────────────────────────────────────
// Fires one HTTP request to OpenAI.
// Throws PipelineError(AI_ENRICHMENT_FAILED, retryable=true)  for transient failures.
// Throws PipelineError(AI_ENRICHMENT_FAILED, retryable=false) for permanent failures.

async function callOnce(
  request:   AiChatRequest,
  apiKey:    string,
  timeoutMs: number,
): Promise<AiChatResponse> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(OPENAI_CHAT_URL, {
      method:  'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({
        model:           OPENAI_MODEL,
        messages:        request.messages,
        response_format: { type: 'json_object' },
        temperature:     request.temperature,
        max_tokens:      request.max_tokens,
      }),
      signal: controller.signal,
    });

    // HTTP-level error — classify by status code
    if (!response.ok) {
      const retryable = RETRYABLE_HTTP_STATUSES.has(response.status);
      const excerpt   = await response.text().catch(() => '<unreadable>');
      throw new PipelineError(
        'AI_ENRICHMENT_FAILED',
        `OpenAI HTTP ${response.status}: ${excerpt.slice(0, 200)}`,
        retryable,
      );
    }

    // Parse completion envelope
    const completion = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>;
      usage?:   {
        prompt_tokens?:     number;
        completion_tokens?: number;
        total_tokens?:      number;
      };
      model?: string;
    };

    const content = completion?.choices?.[0]?.message?.content;
    if (!content?.trim()) {
      // Empty content is not retryable — same prompt would yield the same result
      throw new PipelineError('AI_ENRICHMENT_FAILED', 'OpenAI returned empty content', false);
    }

    // Verify JSON parseability before returning to caller — caller does typed validation
    try {
      JSON.parse(content);
    } catch {
      throw new PipelineError(
        'AI_ENRICHMENT_FAILED',
        `OpenAI response is not valid JSON: ${content.slice(0, 200)}`,
        false, // malformed JSON is not retryable without changing the prompt
      );
    }

    return {
      content,
      usage: completion.usage
        ? {
            prompt_tokens:     completion.usage.prompt_tokens     ?? 0,
            completion_tokens: completion.usage.completion_tokens ?? 0,
            total_tokens:      completion.usage.total_tokens      ?? 0,
          }
        : null,
      model:    completion.model ?? OPENAI_MODEL,
      provider: 'openai',
    };
  } catch (e) {
    // Re-throw PipelineErrors as-is (retryable flag is already set correctly above)
    if (e instanceof PipelineError) throw e;

    // AbortController fired → timeout
    if (e instanceof Error && e.name === 'AbortError') {
      throw new PipelineError(
        'AI_ENRICHMENT_FAILED',
        `OpenAI request timed out after ${timeoutMs}ms`,
        true, // timeouts are always retryable
      );
    }

    // Network-level error (DNS, TLS, connection refused, etc.)
    throw new PipelineError(
      'AI_ENRICHMENT_FAILED',
      `OpenAI network error: ${String(e)}`,
      true, // network errors are retryable
    );
  } finally {
    clearTimeout(timer);
  }
}

// ─── Exported client function ─────────────────────────────────────────────────

// Calls OpenAI with retry and exponential backoff.
//
// Retry policy:
//   • Non-retryable failures (4xx except 429, empty content, invalid JSON) → fail immediately
//   • Retryable failures (429, 5xx, timeout, network error) → retry up to MAX_RETRIES times
//   • Backoff: INITIAL_BACKOFF_MS × BACKOFF_MULTIPLIER^(attempt-1) ± BACKOFF_JITTER_MS
//     Sequence: ~1 s, ~2 s, ~4 s (plus jitter)
//
// Worst-case wall time: 4 × timeoutMs + 7 s backoff
// With timeoutMs = AI_TIMEOUT_MS (30 s): ~127 s — within Supabase's 150 s Edge limit.
export async function callAi(
  request:   AiChatRequest,
  apiKey:    string,
  timeoutMs: number,
): Promise<AiChatResponse> {
  let lastError: PipelineError | null = null;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    if (attempt > 0) {
      const backoffMs = INITIAL_BACKOFF_MS * Math.pow(BACKOFF_MULTIPLIER, attempt - 1);
      const jitter    = (Math.random() * 2 - 1) * BACKOFF_JITTER_MS;
      const delayMs   = Math.max(0, Math.round(backoffMs + jitter));

      logger.warn('AI request retrying with backoff', {
        fn:          FN,
        attempt,
        max_retries: MAX_RETRIES,
        delay_ms:    delayMs,
        reason:      lastError?.message,
      });

      await new Promise<void>((resolve) => setTimeout(resolve, delayMs));
    }

    try {
      const result = await callOnce(request, apiKey, timeoutMs);

      if (attempt > 0) {
        logger.info('AI request succeeded after retry', {
          fn:      FN,
          attempt,
          model:   result.model,
          tokens:  result.usage?.total_tokens ?? null,
        });
      }

      return result;
    } catch (e) {
      if (e instanceof PipelineError) {
        lastError = e;
        if (!e.retryable) {
          // Non-retryable: propagate immediately without consuming remaining attempts
          throw e;
        }
        // Retryable: loop continues to next attempt
      } else {
        // Unexpected non-PipelineError (should not reach here given callOnce's catch)
        throw new PipelineError(
          'AI_ENRICHMENT_FAILED',
          `Unexpected AI client error: ${String(e)}`,
          false,
        );
      }
    }
  }

  // All attempts exhausted — propagate the last retryable error
  throw lastError ?? new PipelineError(
    'AI_ENRICHMENT_FAILED',
    'All AI retry attempts exhausted with no captured error',
    false,
  );
}
