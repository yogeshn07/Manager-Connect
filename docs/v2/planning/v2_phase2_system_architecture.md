# The Catalysts — Version 2

## Phase 2: System Architecture & Engineering Blueprint

| Field | Value |
|---|---|
| Document | `docs/v2/planning/v2_phase2_system_architecture.md` |
| Phase | 2 of 12 — System Architecture & Engineering Blueprint |
| Status | **LOCKED** (architecture frozen) |
| Date | 2026-08-06 |
| Predecessor | `docs/v2/planning/v2_phase1_product_vision.md` (LOCKED) |
| Scope | Architecture only — no code, no SQL, no table design, no API design, no packages |
| Authoring panel | Principal Software Architect, Principal Solutions Architect, Principal Backend Architect, Principal Flutter Architect, Principal AI Systems Architect, Principal Database Architect, Principal Cloud Architect, Principal DevOps Architect, Principal Product Architect, Engineering Director |

---

## 1. Executive Summary

Phase 1 froze *what* V2 is. Phase 2 freezes *how it is built*, without building it.

The architecture rests on five decisions, each of which removes a category of ambiguity from every later phase:

1. **Scheduling is resolved.** V2 adopts an in-database scheduler (`pg_cron`) that invokes existing-style Edge Functions over HTTP (`pg_net`), backed by a **job-run ledger** that makes every scheduled execution idempotent, observable, retryable and self-healing. This closes the single blocking risk from Phase 1. V1 has no scheduled jobs today, so nothing existing is disturbed.

2. **Manager DNA is a read model, never a write path.** DNA is built from an append-only **contribution ledger** plus a **per-manager snapshot**. The rendering surface reads exactly one snapshot. DNA never calls another feature, and no feature has to know DNA exists.

3. **V1 write paths are not instrumented.** V2 features emit contributions directly. V1 participation (posts, comments, events, wellness, games) is picked up by a **scheduled reconciler** that reads V1 data and derives contributions. This is the design choice that makes "V1 remains untouched" literally true at the code level — no triggers, no hooks, no modified V1 functions on V1 tables.

4. **AI is a bounded, replaceable, provider-neutral module.** V2 introduces a `groq` provider behind the same provider-neutral contract already proven by the Insights pipeline's AI client. V2 gets its **own** AI module; the V1 Insights AI client is not refactored, not shared, and not touched. A Leadership Pulse answer is persisted **before** any AI call, so an AI outage can never cost a manager their reflection or their DNA growth.

5. **Catalyst Quest has no counters of its own.** Quest completion is evaluated by the same reconciler against the same participation signals that feed DNA. There is exactly one source of truth for "did this happen", which prevents the classic drift between a quest board and reality.

Everything else follows from these five. The feature-first Clean Architecture used by V1 on the Flutter side (data / domain / presentation with Riverpod code generation) and the use-case-per-function structure used by V1 Edge Functions (`index.ts` transport + `use-case.ts` logic + `_shared/` services) are adopted unchanged for V2, so V2 code will look like V1 code to any engineer already on the project.

**Phase 2 verdict: architecture complete, scheduling resolved, boundaries frozen, ready for implementation planning (Phase 3).**

---

## 2. Overall Architecture

### 2.1 Existing V1 architecture (context, unchanged)

| Layer | V1 reality that V2 must conform to |
|---|---|
| Client | Flutter, feature-first Clean Architecture: `features/<name>/{data,domain,presentation}`; `data/repositories` own Supabase access; `presentation/providers` are Riverpod (code-generated `.g.dart`); routing centralised in `core/router` with named routes in `core/constants/route_names.dart` |
| Read path | Client repositories query PostgREST directly, protected by RLS |
| Write path | Privileged or multi-step writes go through Edge Functions, invoked from repositories via the Supabase client's function invocation |
| Edge Function shape | `index.ts` = transport, auth guard, error mapping; `use-case.ts` = business logic; cross-cutting concerns live in `_shared/` (`auth`, `cors`, `errors`, `response`, `supabase-client`, `constants`, `validators/*`, `services/notification.service`, `services/audit.service`) |
| Privileged jobs | Functions that must not be caller-driven require the service role at the transport boundary (the pattern used by the existing `scheduled-*` functions) |
| Data | PostgreSQL with RLS on every table; append-only notification inbox; monthly analytics computed by a batch function |
| Realtime | Explicit publication membership per table; V1 currently publishes 8 tables |
| Storage | Bucket-scoped policies; `avatars` and `post-images` buckets exist |
| AI | Background-only today: the Insights pipeline uses a provider-neutral AI client with timeout, bounded retry with jitter, retryable/non-retryable classification, and prompts owned by the caller |
| Notifications | One inbox model plus a dispatch service; notification types are a closed set |

### 2.2 V2 architecture at a glance

```
┌──────────────────────────── FLUTTER CLIENT ────────────────────────────┐
│  V1 features (untouched)          V2 features (new)                    │
│  feed / events / growth /         leadership_pulse                     │
│  analytics / profile /            coffee_roulette                      │
│  insights / admin / …             manager_dna                          │
│                                   catalyst_quest                       │
│  ── shared: core/router, core/network, design system, Riverpod ──      │
└───────────────┬──────────────────────────────────┬─────────────────────┘
        reads (PostgREST + RLS)            writes (Edge Functions)
                │                                  │
┌───────────────▼──────────────────────────────────▼─────────────────────┐
│                          SUPABASE PLATFORM                             │
│                                                                        │
│  Edge Functions (V2 set)          _shared (V1, extended additively)    │
│   pulse-*                          auth / cors / errors / response      │
│   coffee-*                         supabase-client / constants          │
│   quest-*                          validators/* (+ v2 validators)       │
│   dna-*                            services/notification, audit         │
│   scheduler-*                      + services/v2 domain services        │
│                                    + ai/ (new, V2-owned)                │
│                                                                        │
│  PostgreSQL                                                            │
│   V1 domain tables (read-only to V2)                                   │
│   V2 domain data (owned by V2 only)                                    │
│   contribution ledger + DNA snapshot (V2)                              │
│   job-run ledger (V2, shared by all scheduled work)                    │
│   pg_cron  ──HTTP via pg_net──►  scheduler entry functions             │
│                                                                        │
│  Storage: post-images (reused by Coffee Roulette)                      │
│  Realtime: V1 publication + a minimal V2 addition                      │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │ outbound, server-side only
                    ┌──────────▼──────────┐
                    │  AI providers       │
                    │  OpenAI  (V1, bg)   │
                    │  Groq    (V2, live) │
                    └─────────────────────┘
```

### 2.3 Architectural invariants (binding on all later phases)

| # | Invariant | Consequence if broken |
|---|---|---|
| INV-1 | V2 never modifies V1 tables, V1 Edge Functions, V1 repositories, or V1 providers | V1 regression risk becomes unbounded |
| INV-2 | V2 reads V1 data; it never writes into V1 domain data — with exactly one authorised exception: Coffee Roulette publishes a Feed post through the existing post-creation path | Feed is the only intentional cross-boundary write |
| INV-3 | Manager DNA is a pure read model. It has no outbound dependency on any feature | DNA becomes a coupling hub and freezes the codebase |
| INV-4 | Catalyst Quest owns no participation counters. It evaluates rules over the contribution ledger | Board and reality drift apart |
| INV-5 | Every scheduled job is idempotent and recorded in the job-run ledger before it acts | Duplicate boards, duplicate rounds, duplicate notifications |
| INV-6 | Manager effort is persisted before any external (AI) call | A provider outage destroys user work |
| INV-7 | Private V2 data (Pulse answers, coaching, DNA) is unreachable by any other manager and by admin surfaces, at the RLS layer, not the UI layer | Privacy promise of Phase 1 is unenforceable |
| INV-8 | No V2 surface adds a synchronous fan-out query over V1 tables on a hot path | Performance regression on V1 screens |

---

## 3. Feature Architectures

### 3.1 Leadership Pulse

#### 3.1.1 Overall architecture

Three separable concerns, deliberately split so that AI availability never blocks the product:

| Concern | Owner | Nature |
|---|---|---|
| **Scenario delivery** | Pulse content module | Read-only, cacheable, cohort-wide |
| **Answer capture** | Pulse answer module | Durable, private, one-shot per scenario |
| **Coaching production** | Pulse coaching module | External, latency-bound, retryable, non-blocking |

Answer capture is the transaction. Coaching is a *derivative* of it, produced afterwards — even when it appears to happen instantly.

#### 3.1.2 Feature boundaries

- Pulse owns: scenario content lifecycle, answer records, coaching records, personal history.
- Pulse does **not** own: DNA growth (it emits a contribution), notification scheduling (it uses the shared notification service), or AI transport (it uses the shared V2 AI module).
- Pulse is invisible to every other feature except through the contribution ledger and the Quest rule evaluator (which sees "a pulse was completed", never the answer or the coaching).

#### 3.1.3 Module ownership

| Module | Side | Responsibility |
|---|---|---|
| `pulse-content` | Backend | Determines which scenarios are available to the cohort this week; serves scenario bodies |
| `pulse-submit` | Backend | Validates the answer, persists it durably, emits the DNA contribution, then attempts coaching |
| `pulse-coach` | Backend | Builds the coaching prompt, calls the AI module, validates the shape of the response, persists it |
| `pulse-retry` (scheduled) | Backend | Sweeps answers with missing coaching and retries them |
| `_shared/ai` | Backend, shared | Provider-neutral AI transport (Section 6) |
| `features/leadership_pulse/data` | Client | Repository: scenario reads (PostgREST), submission (Edge Function invoke) |
| `features/leadership_pulse/domain` | Client | Scenario, answer, coaching entities; submission use case |
| `features/leadership_pulse/presentation` | Client | Riverpod providers, scenario screen, coaching screen, history screen |

#### 3.1.4 AI interaction flow

```
Manager selects an option
        │
        ▼
pulse-submit  ──(1)──► persist answer            [DURABLE POINT — never lost]
        │      ──(2)──► emit DNA contribution    [growth is now guaranteed]
        │      ──(3)──► call pulse-coach with a hard timeout
        │                     │
        │                     ├─ success ─► persist coaching ─► return coaching
        │                     └─ timeout / error ─► mark coaching pending ─► return "pending"
        ▼
Client shows coaching, or a calm "your coach is thinking" state
        │
        └─ pending case: coaching arrives later via realtime or on next open
```

Rules that make this safe:

- The answer write and the contribution emission complete **before** any outbound call.
- The coaching call has a hard wall-clock budget; exceeding it is a normal outcome, not an error state shown as a failure.
- Coaching is produced **at most once** per answer; the retry sweeper claims work by state transition so two workers cannot double-produce.
- Prompt content carries **no manager identity** (Section 9.4).

#### 3.1.5 Scenario lifecycle

```
authored ─► reviewed (content + safety gate) ─► published ─► scheduled for a week
   ─► available to cohort ─► answerable ─► archived (still readable in history)
```

- Scenarios are cohort-wide, not per-manager: everyone sees the same set in a given week. This keeps the content pipeline simple and makes the cohort's shared context possible without exposing anyone's answer.
- "Available this week" is a scheduled state transition, owned by the scheduler (Section 5), not by client-side date logic.
- Archiving never deletes: history must remain readable forever.

#### 3.1.6 Coaching lifecycle

```
pending ─► generating ─► ready
   │            │
   │            └─ failed(transient) ─► pending (bounded retries, backoff)
   └─ failed(permanent) ─► unavailable (answer + DNA growth intact, coaching absent)
```

`unavailable` is a designed, displayable end state — the product degrades to "your reflection was recorded" rather than to an error.

#### 3.1.7 History architecture

- History is a private, chronological read of the manager's own answers joined to their coaching.
- It is paginated and read directly through PostgREST under an owner-only RLS boundary.
- No aggregate is computed at read time; nothing about history is exposed to Analytics.

#### 3.1.8 Dependency map

```
leadership_pulse
 ├─ depends on: auth/profile (V1), notification service (V1), _shared/ai (V2), scheduler (V2)
 ├─ emits to:   contribution ledger (V2)
 └─ consumed by: Manager DNA (Reflection strand), Catalyst Quest (rule evaluation, completion fact only)
```

#### 3.1.9 Integration with Manager DNA

Pulse emits one contribution per completed scenario, carrying: manager, source = pulse, strand = Reflection, occurrence identity. It does not compute levels, does not read DNA state, and does not care whether DNA exists.

---

### 3.2 Coffee Roulette

#### 3.2.1 Group generation architecture

Matching is a **pure, deterministic function** of (active opted-in members, pair-history matrix, round seed). Purity is what makes the job safely re-runnable.

```
round trigger (scheduler)
   ─► load eligible members (active, not opted out)
   ─► load pair-history matrix (who has met whom, and when)
   ─► score candidate groupings against the repeat-avoidance objective
   ─► select grouping; handle remainder (N mod 3/4) by widening one group to 4
   ─► persist round + groups atomically, keyed by round identity   [IDEMPOTENT POINT]
   ─► dispatch invitations
```

- The round identity (cohort + period) is unique. A re-run finds the round already generated and exits without side effects.
- Notifications are dispatched only on the transition that created the round, never on a re-run.
- Remainder handling is deterministic, so a re-run of a failed dispatch cannot reshuffle groups.

#### 3.2.2 Repeat avoidance strategy

- A **pair-history matrix** records, for every ordered pair of managers, the last period in which they shared a group.
- The matcher maximises "time since last met" across the grouping, subject to group-size constraints.
- A hard constraint forbids re-pairing inside a rolling avoidance window; a soft objective spreads the rest.
- If the constraint is unsatisfiable (small cohort, many opt-outs), the matcher relaxes the window by one step at a time and records the relaxation in the job-run ledger — it never fails the round.

At cohort size ~20 the pair space is trivial (190 pairs); at 1000 it is ~500k pairs, still tractable as a batch job (Section 12).

#### 3.2.3 Scheduling architecture

Monthly round creation, mid-round reminder, and round closing are three scheduled transitions, all owned by the scheduler in Section 5, all idempotent, all recorded.

#### 3.2.4 Invitation lifecycle

```
group created ─► invited ─► (accepted | opted-out | silent)
                    └─► reminded (once, mid-window)
                    └─► round closes ─► completed | expired
```

- Opt-out is silent: no notification to other members, no visible marker, no penalty.
- Expiry is a terminal, consequence-free state. It emits no contribution and no negative signal anywhere.

#### 3.2.5 Completion lifecycle and photo workflow

```
member picks photo
   ─► client uploads image to storage under a round-scoped path
   ─► client invokes coffee-complete with the storage reference + optional caption
        ─► validate: round open, caller is a member, not already completed  [ONE-SHOT GUARD]
        ─► persist completion (photo reference, caption, submitter, timestamp)
        ─► publish Feed post through the existing post-creation path
        ─► emit one Connection contribution per group member
        ─► notify group members that the round is recorded
```

- **Upload before submit**: the image lands in storage first, so a failed submission never loses the photo; an orphaned upload is swept by the existing cleanup job pattern.
- **One-shot guard**: completion is a single state transition on the round; concurrent submissions from two members resolve to exactly one winner.
- **Bucket decision**: reuse the existing public `post-images` bucket. The photo is destined for the Feed in the same transaction, so a separate private bucket would add a moderation and access model for data that becomes Feed content moments later. Privacy consequence is stated explicitly in Section 9.6.
- **Feed integration**: the post is created through the existing creation path with a distinct post type, so Feed rendering, reactions, comments, moderation and reporting all work unchanged. Coffee Roulette does not write to Feed tables directly and does not modify Feed behaviour.

#### 3.2.6 History architecture

History is a per-manager read of the rounds they belonged to, ordered by period, resolving group members and the photo reference. It is a read-only projection of round data — Coffee Roulette keeps no second copy of history.

#### 3.2.7 Dependency map

```
coffee_roulette
 ├─ depends on: profiles/active state (V1, read), storage (V1), notification service (V1),
 │              feed post-creation path (V1, invoked not modified), scheduler (V2)
 ├─ emits to:   contribution ledger (V2), Managers Feed (authorised exception INV-2)
 └─ consumed by: Manager DNA (Connection strand), Catalyst Quest (completion fact only)
```

#### 3.2.8 Coexistence with V1 Connect Buddy

Connect Buddy is a V1 system account that authors automated Feed posts. Coffee Roulette posts are authored on behalf of a **group of real managers** and use a different post type. The two systems share the Feed and nothing else: no shared code path beyond the existing post-creation path, no shared notification type, no shared scheduling entry.

---

### 3.3 Manager DNA

#### 3.3.1 Architecture

DNA is a two-tier read model:

```
   feature events + V1 participation
                │
        ┌───────▼────────┐
        │  CONTRIBUTION  │  append-only, one row per meaningful act,
        │     LEDGER     │  uniquely keyed by (manager, source, occurrence)
        └───────┬────────┘
                │  growth engine (deterministic fold)
        ┌───────▼────────┐
        │  DNA SNAPSHOT  │  one per manager: six strand values + visual stage
        └───────┬────────┘
                │  single read
        ┌───────▼────────┐
        │   RENDERER     │  Flutter animation over the snapshot only
        └────────────────┘
```

Why two tiers: the ledger gives auditability, replayability and exactly-once semantics; the snapshot gives O(1) reads on the most-visited personal screen in V2. Recomputing six strands over seven sources at read time would be the single worst performance decision available, so it is explicitly rejected.

#### 3.3.2 Growth engine

- **Input**: contribution ledger entries.
- **Rule**: each contribution maps to (strand, weight). Weights are **configuration**, not code, so tuning does not require a release.
- **Exactly-once**: the occurrence identity on each contribution makes duplicate emission a no-op. Re-running the reconciler is always safe.
- **Monotonic**: the fold only adds. There is no decay path in V2 (Phase 1 locked decision), which removes an entire class of scheduled recomputation.
- **Replayable**: the snapshot can be rebuilt from the ledger at any time. This is the recovery mechanism for every DNA bug.

#### 3.3.3 DNA evolution engine

- Strand values map to **stages** through a threshold table (configuration).
- Overall DNA maturity is **emergent**: derived from the strand stages, not stored as an independent score.
- Stage transitions are computed when the snapshot is updated, and the *fact* of a transition is recorded so the client can celebrate it once, in place, without polling.

#### 3.3.4 Strand architecture

| Strand | Sources | Emission mechanism |
|---|---|---|
| Reflection | Leadership Pulse | Direct emission at submission (V2-owned) |
| Connection | Coffee Roulette | Direct emission at round completion (V2-owned) |
| Consistency | Catalyst Quest | Direct emission at quest completion (V2-owned) |
| Expression | Posts, Comments | **Reconciler** derives from V1 data |
| Presence | Events attendance | **Reconciler** derives from V1 data |
| Wellbeing | Wellness/Challenges, Games | **Reconciler** derives from V1 data |

The split is the core of INV-3 and INV-1: V2-owned features emit synchronously; V1 features are observed asynchronously and are never instrumented.

#### 3.3.5 Event aggregation architecture (the reconciler)

A single scheduled worker performs a **watermark scan**: for each V1 source, it reads rows created since the last processed watermark, maps them to contributions, and advances the watermark — all recorded in the job-run ledger.

- Late data is handled by a small overlap window on the watermark; duplicates are absorbed by the occurrence key.
- The reconciler is the *only* component that reads V1 tables for DNA purposes, so the V1 read surface used by V2 is one auditable module.
- The reconciler also feeds Quest evaluation (Section 3.4.7) — one scan, two consumers.

#### 3.3.6 Rendering and animation architecture

| Layer | Responsibility |
|---|---|
| Snapshot provider | Single Riverpod read of the manager's snapshot; cached; refreshed on screen focus and after a known growth event |
| Model layer | Converts strand values/stages into pure render parameters (density, palette, motion intensity, complexity) — no I/O, fully unit-testable |
| Render layer | Custom-painted helix driven by an animation controller bound to render parameters |
| Fallback layer | A static, non-animated rendering used when reduced-motion is requested by the OS, on low-end devices, or when the animation budget is exceeded |

Binding constraints: the animation runs only while the DNA screen is visible; controllers are disposed on navigation away; no animation work occurs on any other screen; growth acknowledgements elsewhere in the app are lightweight, non-helix visuals.

#### 3.3.7 Dependency graph

```
manager_dna
 ├─ reads:   DNA snapshot (own), contribution ledger (own, for strand inspection)
 ├─ depends on: profile (V1, entry point only)
 ├─ writes:  nothing outside its own tier
 └─ consumers: none — DNA is a leaf node by design (INV-3)
```

#### 3.3.8 Interaction with every feature

| Feature | Relationship to DNA | Direction |
|---|---|---|
| Leadership Pulse | Emits Reflection contributions | in |
| Coffee Roulette | Emits Connection contributions | in |
| Catalyst Quest | Emits Consistency contributions | in |
| Feed (posts, comments) | Observed by reconciler → Expression | in (read-only) |
| Events | Observed by reconciler → Presence | in (read-only) |
| Wellness / Games | Observed by reconciler → Wellbeing | in (read-only) |
| Profile | Hosts the entry point | in (navigation only) |
| Analytics | **No relationship.** DNA never enters Analytics | none |
| Admin | **No relationship.** No admin surface reads DNA | none |
| Notifications | DNA sends no notifications of its own | none |

---

### 3.4 Catalyst Quest

#### 3.4.1 Quest generation architecture

```
monthly trigger (scheduler)
   ─► resolve board identity (cohort + month)              [IDEMPOTENT POINT]
   ─► if board exists → exit
   ─► draw 36 grid quests + 4 extra-cell quests from the Quest Library,
      honouring category balance and a recent-use exclusion window
   ─► persist board + cell assignments atomically
   ─► seed unlock plan for the month (2 per day)
   ─► record generation in the job-run ledger
```

The board is **cohort-wide**: one board per month for everyone (Phase 1 decision). This makes generation a single job, not an N-manager fan-out, and keeps generation cost independent of cohort size.

#### 3.4.2 Quest library architecture

- The library is **content**, versioned and editable without a release.
- Each library entry declares: category, effort weight, and a **completion rule reference** — the rule that decides whether the quest is satisfied.
- Rules are of two kinds:
  - **derived** — satisfied by real participation observed in the contribution ledger (the default),
  - **attested** — satisfied by an explicit honour-system confirmation, used only where no digital signal exists, and clearly framed as such in the product.
- A recent-use exclusion window prevents the same quests appearing month after month.

#### 3.4.3 Golden Quest architecture

- A separate Golden Quest Library with the same rule model and a higher effort weight.
- One Golden Quest per week, selected by the weekly scheduled job, keyed by (board, week) for idempotency.
- Golden Quests sit outside the 6×6 Bingo grid and therefore cannot form Bingo lines, matching the Phase 1 board definition.

#### 3.4.4 Unlock architecture

- The month's unlock plan is computed **at generation time**, not daily. The daily job only advances a pointer and reveals the already-planned pair.
- Consequence: a missed daily run causes a late reveal, never a wrong board. A catch-up run reveals everything that should already be visible, in one pass, and never double-reveals.
- Unlocked quests stay available for the rest of the month (no expiry pressure).

#### 3.4.5 Monthly board lifecycle

```
generating ─► active ─► closing (last day) ─► closed (read-only, archived)
                 │
                 ├─ daily unlock (×2/day)
                 └─ weekly golden quest (×1/week)
```

Closure is archival only: closed boards remain readable in the manager's own history. Unfinished quests carry no penalty and do not carry over.

#### 3.4.6 Bingo evaluation

- Evaluated **incrementally** at completion time: only the row, column and (if applicable) diagonals containing the completed cell are re-checked.
- Bingo achievement is recorded once per line per manager, so celebration is exactly-once even if evaluation re-runs.
- Perfect Catalyst Month is evaluated on the same path when the completion count reaches 40, and again defensively at board close so a missed evaluation cannot silently deny a manager the milestone.

#### 3.4.7 Completion pipeline

```
contribution ledger (from V2 emissions and the V1 reconciler)
        │
        ▼
quest rule evaluator (scheduled, plus opportunistic evaluation after a V2 emission)
        │
        ├─ mark cell complete (idempotent per manager+cell)
        ├─ emit Consistency contribution
        ├─ evaluate Bingo lines touched
        └─ evaluate Perfect Catalyst Month
```

Attested quests enter the same pipeline through an explicit confirmation action, producing an attestation record that the evaluator treats as a satisfying signal. There is still no independent counter (INV-4).

Latency note: derived completions are eventually consistent, bounded by the reconciler's cadence. The product must therefore never claim instant completion for a derived quest performed in a V1 feature; it acknowledges "counted shortly". V2-native actions (Pulse, Coffee Roulette) can be evaluated opportunistically and feel immediate.

#### 3.4.8 DNA integration

Quest emits Consistency contributions on completion, with Golden Quests carrying a higher weight. Quest never reads DNA state and never adjusts it directly.

---

## 4. Data Flow

For each feature: input → processing → business logic → output → persistence boundary → consumers → upstream / downstream.

### 4.1 Leadership Pulse

| Aspect | Definition |
|---|---|
| Input | Manager's single option selection for an available scenario |
| Processing | Validate availability + one-shot rule; persist answer; emit contribution; attempt coaching within a bounded budget |
| Business logic | One answer per scenario per manager; no re-answer; coaching is derived and optional; effort persisted before external call |
| Output | Coaching in four fixed parts (strengths, weaknesses, suggested improvement, leadership takeaway), or a pending/unavailable state |
| Persistence boundary | Pulse-owned private data: answers, coaching, scenario content. Nothing written to V1 |
| Consumers | The manager (only); contribution ledger; Quest evaluator (completion fact only) |
| Upstream | Auth/profile; scenario schedule; AI provider |
| Downstream | Manager DNA (Reflection); Catalyst Quest |

### 4.2 Coffee Roulette

| Aspect | Definition |
|---|---|
| Input | Scheduler tick (round creation); manager photo + optional caption (completion); opt-out signal |
| Processing | Deterministic matching under repeat-avoidance; invitation dispatch; upload-then-submit completion with one-shot guard; Feed publication; per-member contribution emission |
| Business logic | Groups of 3–4; silent opt-out; any member may submit; one completion per round; expiry is consequence-free |
| Output | Round + groups; invitations; Feed post; history entry; Connection growth for every member |
| Persistence boundary | Coffee-owned data: rounds, groups, memberships, completions, pair history. Storage object in the existing image bucket. One authorised write into Feed via the existing creation path |
| Consumers | Group members; the whole cohort (via Feed); contribution ledger; Quest evaluator |
| Upstream | Profiles/active state; scheduler; storage; notification service |
| Downstream | Managers Feed; Manager DNA (Connection); Catalyst Quest |

### 4.3 Manager DNA

| Aspect | Definition |
|---|---|
| Input | Contribution ledger entries (direct emissions + reconciler-derived) |
| Processing | Deterministic, monotonic fold into six strand values; stage evaluation; snapshot update; transition recording |
| Business logic | Exactly-once per occurrence; weights and thresholds are configuration; no decay; no back-fill of pre-launch V1 history |
| Output | One snapshot per manager + strand inspection detail |
| Persistence boundary | DNA-owned: ledger + snapshot. Reads V1 only through the reconciler |
| Consumers | The manager (only) |
| Upstream | Every V2 feature; V1 participation via the reconciler |
| Downstream | **None.** DNA is terminal |

### 4.4 Catalyst Quest

| Aspect | Definition |
|---|---|
| Input | Scheduler ticks (monthly generation, daily unlock, weekly Golden Quest); contribution ledger; attestations |
| Processing | Library draw with balance + exclusion; unlock plan advance; rule evaluation; incremental Bingo check; milestone evaluation |
| Business logic | 36 grid + 4 extra = 40; 2 unlocks/day; 1 Golden Quest/week; Bingo on grid lines only; monthly reset; no carry-over; no penalty |
| Output | Monthly board; unlocked quests; completions; Bingo and Perfect Month milestones; Consistency growth |
| Persistence boundary | Quest-owned: boards, cell assignments, unlock plan, completions, milestones, attestations, library content |
| Consumers | Every manager; contribution ledger |
| Upstream | Scheduler; Quest libraries; contribution ledger |
| Downstream | Manager DNA (Consistency) |

---

## 5. Scheduling Architecture

**This section closes the Phase 1 blocker.**

### 5.1 Decision

**In-database scheduling: `pg_cron` schedules jobs; `pg_net` invokes scheduler Edge Functions over HTTP; a job-run ledger provides idempotency, observability and recovery.**

### 5.2 Why this, and what was rejected

| Option | Verdict | Reasoning |
|---|---|---|
| **pg_cron + pg_net → Edge Functions** | **Chosen** | Runs inside the platform that already holds the data; no new vendor, no new credential surface outside the database; survives client and CI outages; business logic stays in Edge Functions where V1 already puts privileged logic, so nothing is written twice |
| pg_cron executing SQL logic directly | Rejected | Would push business logic into the database, splitting V2 logic across two runtimes and defeating the existing use-case module pattern |
| External CI scheduler (e.g. a scheduled CI workflow) | Rejected as primary, retained as documented manual fallback | Couples production timing to a code-hosting product, adds a long-lived production secret outside the platform, and has no visibility into database state |
| Client-triggered generation ("first manager to open the app generates the board") | Rejected outright | Non-deterministic timing, thundering herd, and it makes correctness depend on user behaviour |

### 5.3 Job inventory

| Job | Cadence | Feature | Nature |
|---|---|---|---|
| Coffee round generation | Monthly | Coffee Roulette | Create round, match groups, invite |
| Coffee round reminder | Monthly (mid-window) | Coffee Roulette | One gentle reminder to incomplete groups |
| Coffee round close | Monthly (window end) | Coffee Roulette | Expire incomplete rounds silently |
| Quest board generation | Monthly | Catalyst Quest | Draw 40 quests, seed unlock plan |
| Quest daily unlock | Daily | Catalyst Quest | Advance unlock pointer by 2 |
| Golden Quest selection | Weekly | Catalyst Quest | Select and publish the week's Golden Quest |
| Quest board close | Monthly | Catalyst Quest | Archive board, defensive milestone evaluation |
| Pulse weekly publication | Weekly | Leadership Pulse | Make the week's scenarios available |
| Pulse coaching retry sweep | Frequent | Leadership Pulse | Retry pending coaching with backoff |
| Contribution reconciler | Frequent | DNA + Quest | Watermark scan of V1 participation |
| Quest rule evaluation | Frequent | Catalyst Quest | Evaluate derived completions |
| Orphan sweep | Daily | Coffee Roulette | Remove unreferenced uploaded images |
| Scheduler self-check | Daily | Platform | Detect missed or stuck runs and alert |

"Frequent" cadences are a Phase 3 tuning parameter, bounded by the product requirement that a derived quest completion is acknowledged within the same session where practical.

### 5.4 Execution model

```
pg_cron (schedule)
   └─► pg_net HTTP call ─► scheduler entry function (service-role guarded, V1 pattern)
            └─► claim job run  ─── already claimed? ──► exit cleanly (no side effects)
                    │
                    ▼
              execute use case (idempotent by domain key)
                    │
            ┌───────┴────────┐
         success           failure
            │                │
      mark succeeded    mark failed + classify (transient | permanent)
                             │
                    transient ─► eligible for retry with backoff
                    permanent ─► alert, no auto-retry
```

- **Credential handling**: the service-role credential used by `pg_net` is held in the database's secret store, never inline in a job definition, never in application code, never in the client.
- **Transport guard**: every scheduler entry function requires the service role at the boundary — the same guard the existing `scheduled-*` functions already use. No scheduled job is reachable by an authenticated manager.
- **Single writer**: a job run is claimed by a state transition before work begins, so overlapping ticks cannot double-execute.

### 5.5 Idempotency model

Every scheduled job has a **domain identity key** independent of the job-run record:

| Job | Domain key |
|---|---|
| Coffee round generation | cohort + period |
| Quest board generation | cohort + month |
| Golden Quest selection | board + week |
| Daily unlock | board + day index |
| Pulse weekly publication | cohort + week |
| Reconciler | source + watermark range |

The rule: **the job checks the domain key first and exits cleanly if the work already exists.** The job-run ledger is for observability and retry accounting; the domain key is what actually guarantees correctness. Both must exist — a ledger alone would not survive a partial failure that occurred after the work but before the ledger update.

### 5.6 Retry strategy

| Failure class | Behaviour |
|---|---|
| Transient (network, upstream 5xx, rate limit, timeout) | Bounded retries with exponential backoff and jitter — the pattern already proven in the V1 AI client — then park as failed and alert |
| Permanent (validation, configuration, contract error) | No retry; alert immediately; the job stays failed until fixed |
| Partial success (e.g. round created, some notifications failed) | The already-done part is protected by the domain key; the retry resumes the remaining work only |

### 5.7 Failure recovery

- **Missed run** (scheduler down): catch-up semantics are built into each job. Daily unlock reveals everything that should already be visible; monthly generation runs late but produces the correct board; the reconciler simply scans a wider window.
- **Stuck run** (claimed but never completed): the self-check job detects claims older than a threshold, releases them, and alerts.
- **Bad run** (wrong output): DNA is rebuildable from the ledger; a quest board can be regenerated by clearing the domain key under an explicit operational procedure; a coffee round can be re-matched only before invitations are dispatched — after dispatch, the round is immutable by design.

### 5.8 Monitoring, observability, logging

| Signal | Content |
|---|---|
| Job-run ledger | job name, domain key, claim time, finish time, outcome, attempt number, error classification, summary counters (groups formed, quests drawn, contributions written) |
| Structured logs | one structured line per job start / retry / recovery / failure, following the V1 pipeline logger convention |
| Alerting | any permanent failure; any job that has not succeeded within its expected window; any stuck claim; scheduler self-check failure |
| Operational read surface | an admin-visible job health view, read-only, mirroring the existing pipeline-health/diagnostics convention already used by the Insights pipeline |

### 5.9 Operational safety

- Scheduled jobs are **disabled by default in non-production environments** and enabled explicitly, so a staging environment cannot notify real managers.
- A global kill switch (configuration flag) stops all V2 scheduled work without a deploy.
- No scheduled job touches V1 tables in write mode. The reconciler holds a read-only relationship with V1 data.
- Notification-emitting jobs are the highest blast-radius jobs and are therefore the ones with the strictest domain keys.

---

## 6. AI Architecture

### 6.1 Provider landscape

| Provider | Used by | Nature | Introduced |
|---|---|---|---|
| OpenAI | V1 Insights enrichment pipeline | Background, batch, latency-tolerant | V1 |
| Groq | V2 Leadership Pulse coaching | User-facing, latency-critical | V2 |

### 6.2 Isolation decision

**V2 gets its own AI module. The V1 Insights AI client is not refactored, not generalised, and not shared.**

Rationale: the V1 client is production-proven inside a pipeline with its own error taxonomy, logger and config loader. Generalising it would mean editing a V1 code path to serve V2 — a direct violation of the "V1 untouched" rule and an unnecessary regression risk in the highest-value V1 subsystem. The cost is a small amount of duplicated transport logic; the benefit is complete blast-radius isolation. If consolidation is ever wanted, it is a V3 refactor with V2 already stable.

### 6.3 Provider abstraction

The V2 AI module exposes a provider-neutral contract, mirroring the shape already validated in V1:

- **Request contract**: messages, sampling parameters, response-shape constraint, per-request timeout budget.
- **Response contract**: raw structured content (validated as parseable before returning), usage metadata, model identifier, provider discriminant.
- **Provider adapters**: one adapter per provider behind the same contract. Adding or swapping a provider is an adapter plus a configuration change — no caller changes.
- **Prompt ownership**: prompts belong to the **calling use case** (`pulse-coach`), never to the transport module. This is the V1 convention and it is retained.

### 6.4 Failure isolation

| Boundary | Guarantee |
|---|---|
| AI ⟂ persistence | The answer and the DNA contribution are committed before any provider call |
| AI ⟂ scheduling | A coaching failure never fails a scheduled job; it parks work for the retry sweeper |
| AI ⟂ V1 | A Groq outage cannot affect the Insights pipeline; a Groq configuration error cannot alter OpenAI behaviour — separate module, separate config keys, separate error taxonomy |
| AI ⟂ UI | The client never calls a provider. All provider traffic is server-side |

### 6.5 Timeout and retry handling

- A **hard per-request wall-clock budget** with client-side abort, sized so the user-visible path stays within the Phase 1 latency target.
- **Bounded retries with exponential backoff and jitter**, restricted to genuinely transient statuses (rate limit and upstream 5xx classes). Non-retryable statuses fail fast.
- Retries inside the synchronous path are capped tightly; anything longer is handed to the asynchronous sweeper rather than making the manager wait.

### 6.6 Fallback strategy

```
attempt (Groq, sync, bounded)
   └─ fail ─► mark pending ─► sweeper retries (backoff, bounded attempts)
                  └─ exhausted ─► coaching unavailable
                                   (answer intact, DNA intact, product still coherent)
```

A cross-provider failover (Groq → OpenAI) is architecturally possible because of the adapter contract, but it is **not enabled in V2**: two providers producing subtly different coaching voices would damage the consistency of the coaching experience. This is recorded as a deliberate decision, not an oversight.

### 6.7 Security boundaries

| Rule | Enforcement |
|---|---|
| No provider key ever reaches the client | Keys are server-side environment configuration only |
| No manager identity in prompts | The coaching prompt carries the scenario, the selected option, and nothing that identifies a person — no name, no email, no profile data, no identifier |
| No free-text injection surface in V2 | The manager submits a *choice*, not prose. This eliminates prompt injection through user input on the Pulse path |
| Output is shape-validated before persistence | The four-part structure is validated; malformed output is treated as a failed attempt, never rendered raw |
| Provider responses are never trusted as markup | Rendered as text content only |
| Configuration is fail-fast | Missing provider configuration fails at function start with a clear error, following the V1 config convention |

### 6.8 Future provider replacement

Replacing Groq requires: a new adapter implementing the same contract, a configuration switch, and a coaching-quality evaluation pass against a fixed scenario set. No change to `pulse-submit`, no change to persistence, no change to the client, no data migration.

---

## 7. Module Architecture

### 7.1 Backend modules

| Module | Owner feature | Responsibility | Depends on |
|---|---|---|---|
| `pulse-content` | Pulse | Weekly scenario availability, scenario serving | scheduler |
| `pulse-submit` | Pulse | Answer validation, durable capture, contribution emission, coaching orchestration | contribution service, `_shared/ai` |
| `pulse-coach` | Pulse | Prompt construction, provider call, response validation, coaching persistence | `_shared/ai` |
| `pulse-retry` | Pulse | Sweep and retry pending coaching | job ledger, `pulse-coach` |
| `coffee-round-generate` | Coffee | Deterministic matching, round persistence, invitations | matching service, notification service |
| `coffee-complete` | Coffee | Completion guard, Feed publication, contribution fan-out | feed post-creation path, contribution service |
| `coffee-lifecycle` | Coffee | Reminders, closing, expiry | notification service, job ledger |
| `quest-board-generate` | Quest | Library draw, board persistence, unlock plan seeding | quest library, job ledger |
| `quest-unlock` | Quest | Daily unlock pointer advance with catch-up | job ledger |
| `quest-golden` | Quest | Weekly Golden Quest selection | golden library, job ledger |
| `quest-evaluate` | Quest | Rule evaluation, completion, Bingo, milestones, contribution emission | contribution ledger, contribution service |
| `dna-reconciler` | DNA | Watermark scan of V1 participation → contributions | V1 data (read-only), job ledger |
| `dna-snapshot` | DNA | Deterministic fold, stage evaluation, snapshot update | contribution ledger |
| `dna-rebuild` | DNA | Operational full replay from ledger | contribution ledger |
| `scheduler-entry` | Platform | Single guarded entry surface for scheduled invocations | job ledger, all scheduled use cases |

### 7.2 Shared services (V2 additions to `_shared`, additive only)

| Shared module | Responsibility | Notes |
|---|---|---|
| `services/contribution.service` | The **only** writer to the contribution ledger; enforces occurrence-key exactly-once | Every feature emits through it; nobody writes the ledger directly |
| `services/job-ledger.service` | Claim, complete, fail, classify, and query job runs | Used by every scheduled job |
| `services/matching.service` | Pure grouping algorithm and pair-history scoring | Pure function; unit-testable without a database |
| `services/quest-rule.service` | Rule interpretation over contributions | Shared by evaluation and by any diagnostic surface |
| `ai/` | Provider-neutral AI transport + Groq adapter | V2-owned; V1 Insights AI client untouched |
| `validators/v2.*` | Input validation for V2 functions | Follows the existing per-domain validator convention |

Reused unchanged from V1: `auth`, `cors`, `errors`, `response`, `supabase-client`, `constants`, `services/notification.service`, `services/audit.service`.

### 7.3 Client modules

Each V2 feature follows the existing V1 feature-first structure exactly:

```
features/<v2_feature>/
  data/         models (DTOs), repositories (PostgREST reads + function invokes)
  domain/       entities, use cases
  presentation/ providers (Riverpod, code-generated), screens, widgets
```

| Client module | Notable responsibility |
|---|---|
| `features/leadership_pulse` | Scenario screen, coaching screen with pending state, private history |
| `features/coffee_roulette` | Round screen, group view, photo capture + upload, caption, history |
| `features/manager_dna` | Snapshot provider, pure render-parameter mapper, animated renderer, static fallback, strand inspection |
| `features/catalyst_quest` | Board screen, cell detail, unlock indicator, Golden Quest surface, Bingo and milestone celebration |
| `core/router` (extended) | New named routes added additively; the existing tab structure is not restructured |

### 7.4 Isolation boundaries

| Boundary | Rule |
|---|---|
| V2 ⟂ V1 code | No V2 module edits a V1 module. V2 may *invoke* the existing post-creation path and the existing notification service |
| Feature ⟂ feature | V2 features never call each other. They meet only at the contribution ledger |
| DNA ⟂ everything | DNA has no outbound dependency (INV-3) |
| Client ⟂ AI | The client never talks to a provider |
| Ledger writers | Exactly one writer module for contributions; exactly one writer module for job runs |
| Scheduled ⟂ interactive | Scheduled entry points are service-role only and are never reachable from the client |

---

## 8. Feature Interaction Matrix

### 8.1 Required interaction map (all arrows from the phase brief, resolved)

| # | Interaction | Mechanism | Coupling | Sync |
|---|---|---|---|---|
| 1 | Leadership Pulse → Manager DNA | Direct contribution emission at submission | Ledger only | Immediate |
| 2 | Coffee Roulette → Feed | Invocation of the existing post-creation path with a distinct post type | Invocation, no schema or behaviour change | Immediate |
| 3 | Feed → Manager DNA | Reconciler observes posts/comments → Expression | Read-only observation | Eventual |
| 4 | Coffee Roulette → Manager DNA | Direct contribution emission per group member at completion | Ledger only | Immediate |
| 5 | Catalyst Quest → Manager DNA | Direct contribution emission at quest completion | Ledger only | Immediate |
| 6 | Feed → Catalyst Quest | Rule evaluation over reconciled Feed contributions | Ledger only | Eventual |
| 7 | Events → Catalyst Quest | Rule evaluation over reconciled attendance contributions | Ledger only | Eventual |
| 8 | Games → Catalyst Quest | Rule evaluation over reconciled game contributions | Ledger only | Eventual |
| 9 | Wellness → Catalyst Quest | Rule evaluation over reconciled wellness contributions | Ledger only | Eventual |
| 10 | Profile → Manager DNA | Navigation entry point only | Route only | Immediate |
| 11 | Catalyst Quest → Pulse / Coffee | Referential only: a quest points at a feature; it never invokes it | None (UI navigation) | n/a |
| 12 | Events / Games / Wellness → Manager DNA | Reconciler → Presence / Wellbeing strands | Read-only observation | Eventual |
| 13 | Scheduler → Coffee / Quest / Pulse | Guarded scheduled invocation | Service-role entry | Scheduled |
| 14 | Any V2 feature → Notifications | Existing notification service with new types | Additive type set | Immediate |
| 15 | Admin → Coffee / Quest content | Operational surfaces only | No access to Pulse or DNA data | Immediate |

### 8.2 Frozen non-interactions

| Non-interaction | Reason |
|---|---|
| Manager DNA → anything | DNA is terminal (INV-3) |
| Leadership Pulse ↔ Coffee Roulette | No product need; would create needless coupling |
| Analytics ↔ any V2 data | Phase 1 privacy decision; DNA and Pulse never become analytics artefacts |
| Admin → Pulse answers / coaching / DNA | Phase 1 privacy decision, enforced at RLS |
| V2 → Insights pipeline | No relationship in V2 |
| V2 → Authentication | Explicitly out of scope |
| Client → AI provider | Server-side only |
| Quest → its own counters | INV-4 |

---

## 9. Security Architecture

### 9.1 Authorization boundaries

| Data | Manager (self) | Other managers | Admin | Service role |
|---|---|---|---|---|
| Pulse scenarios (content) | read | read | manage | full |
| Pulse answers | read own | **none** | **none** | full |
| Pulse coaching | read own | **none** | **none** | full |
| DNA snapshot | read own | **none** | **none** | full |
| Contribution ledger | read own | **none** | **none** | full |
| Coffee round membership | read own rounds | own rounds only | operational read | full |
| Coffee photo + caption | read | read (it is Feed content) | moderate (existing model) | full |
| Quest board + cells | read | read | manage content | full |
| Quest completions | read own | **none** | **none** | full |
| Milestones (Bingo, Perfect Month) | read own | **none** | **none** | full |
| Job-run ledger | none | none | read (health view) | full |

### 9.2 Enforcement principle

Every boundary above is enforced by **row-level security in the database**, not by client-side filtering and not by an Edge Function's good intentions. The UI hiding data is a convenience; RLS is the control. Any V2 surface that requires elevated access goes through a service-role Edge Function with an explicit guard at the transport boundary, matching V1's existing pattern.

### 9.3 Private-by-construction data

Pulse answers, Pulse coaching, contribution entries and DNA snapshots are **owner-only for their entire lifetime**. There is no sharing feature, no export path, no admin view and no analytics ingestion in V2. Because there is no such path in the architecture, a UI bug cannot create one.

### 9.4 AI privacy

- Prompts contain the scenario and the chosen option. They contain **no** name, email, identifier, profile attribute, or any other manager data.
- Coaching output is stored against the answer inside the owner-only boundary.
- No provider is given bulk access to any dataset; each call is a single, minimal, self-contained request.
- Provider credentials exist only as server-side configuration.

### 9.5 Admin visibility

Admin gains: Coffee Roulette round operations, quest and scenario content management, and the job-health view. Admin gains **nothing** about any individual's reflections, coaching, contributions, strands or DNA. Admin actions that affect managers follow the existing audit-logging service.

### 9.6 Photo privacy (explicit trade-off)

The Coffee Roulette photo is stored in the existing public image bucket because it is published to the Feed as part of the same completion. Consequences, accepted deliberately:

- The object is reachable by URL, exactly like any existing Feed image. Path unguessability is a property of the storage path, not an access control.
- Moderation and removal use the existing Feed moderation model — no new policy, no second moderation surface.
- The product must therefore never imply that a Coffee Roulette photo is private. It is community content by design.

### 9.7 DNA privacy

DNA is owner-only, non-shareable, non-exportable and absent from every aggregate surface in V2. This is what allows the product to reward participation without creating a covert performance signal inside the organisation.

---

## 10. Performance Architecture

### 10.1 Critical paths (user-visible)

| Path | Target shape | Design guarantee |
|---|---|---|
| Open Manager DNA | One snapshot read + local render-parameter computation | No cross-source aggregation at read time; O(1) in participation volume |
| Open Quest board | One board read + one completion-set read for the manager | Board is immutable for the month → highly cacheable |
| Open Pulse scenario | One content read | Content is cohort-wide and cacheable |
| Submit Pulse answer | One write + one contribution + bounded AI attempt | Persistence completes before the external call; the UI is never blocked on the provider beyond the budget |
| Open Coffee round | One round read with membership resolution | Small, bounded result set |
| Submit Coffee completion | Upload (client → storage) then one function call | Upload is the heavy part and is separated from the transaction |
| All V1 screens | **Unchanged** | V2 adds no query, no listener and no work to any V1 path (INV-8) |

### 10.2 Background work

| Work | Cost driver | Containment |
|---|---|---|
| Reconciler scan | Rows created since watermark | Watermark + narrow overlap window; never a full-table scan |
| Snapshot fold | Contributions since last fold | Incremental; full replay is an operational tool only |
| Quest evaluation | Open cells × active managers | Incremental, triggered by new contributions rather than by polling every cell |
| Coffee matching | Pairs (n²) | Monthly, batch, off the user path |
| Board generation | Fixed 40 draws | Constant cost regardless of cohort size (cohort-wide board) |
| Notification dispatch | Recipients per event | Batched at the service level; the largest fan-out is round invitations |

### 10.3 Caching strategy

| Cached item | Where | Invalidated by |
|---|---|---|
| DNA snapshot | Client (Riverpod), short TTL | Known growth event, screen focus |
| Render parameters | Client, in-memory | Snapshot change |
| Quest board + cell content | Client, month-scoped | Month rollover |
| Pulse scenario content | Client, week-scoped | Weekly publication |
| Pair-history matrix | Server, job-local | Each generation run |
| Job health view | Server, short TTL | Next run |

### 10.4 Expected bottlenecks (ranked)

1. **DNA animation on low-end devices** — the only real client-side risk in V2. Contained by the pure render-parameter layer, the visibility-scoped controller, and the mandatory static fallback.
2. **AI latency on the Pulse path** — contained by the hard budget and the pending state; it degrades the *experience*, never the *data*.
3. **Reconciler cadence vs. perceived immediacy** — a slow reconciler makes derived quest completions feel late. Contained by opportunistic evaluation for V2-native actions and honest product copy for V1-derived ones.
4. **Notification fan-out at larger cohorts** — batching required beyond ~250 managers (Section 12).
5. **Contribution ledger growth** — append-only volume grows linearly with participation; retention and partitioning become a consideration at the 1000-manager scale, not before.

---

## 11. Failure Recovery

### 11.1 Per-feature failure analysis

**Leadership Pulse**

| Failure point | Behaviour | Recovery |
|---|---|---|
| AI provider timeout / outage | Answer + DNA growth already committed; coaching marked pending | Sweeper retries with backoff; UI shows a calm pending state |
| Malformed AI output | Treated as a failed attempt; never rendered | Retry; after exhaustion, coaching unavailable |
| Duplicate submission (double tap, retry) | One-shot rule rejects the second | No duplicate answer, no duplicate contribution |
| Scenario publication job missed | Last week's scenarios remain; no crash | Catch-up publication on next run |
| Client loses connection mid-submit | Either the write happened (idempotent retry finds it) or it did not | Safe retry; no partial state |

**Coffee Roulette**

| Failure point | Behaviour | Recovery |
|---|---|---|
| Generation job fails mid-way | Domain key prevents a second round; partial work is resumable | Retry resumes remaining steps only |
| Invitation dispatch partially fails | Round exists; some members uninformed | Retry dispatches only to un-notified members |
| Photo upload fails | Nothing is submitted; the round stays open | User retries; orphan objects swept daily |
| Submission succeeds, Feed publication fails | Completion is the source of truth; Feed post is retried | Bounded retry; if permanently failed, the round is still complete and history is intact |
| Two members submit simultaneously | One-shot guard resolves a single winner | Loser sees the completed state |
| Nobody submits | Round expires silently | No penalty, no notification, no contribution |

**Manager DNA**

| Failure point | Behaviour | Recovery |
|---|---|---|
| Reconciler fails | Contributions lag; snapshot is stale but correct | Next run scans a wider window; no data loss |
| Duplicate contribution emission | Absorbed by the occurrence key | No inflation |
| Snapshot corruption or a weighting bug | Ledger is intact | Full deterministic rebuild from the ledger |
| Animation failure on device | Static fallback renders | No blank screen, no crash |
| Snapshot read fails | Cached snapshot renders with a staleness indicator | Refresh on reconnect |

**Catalyst Quest**

| Failure point | Behaviour | Recovery |
|---|---|---|
| Board generation missed | No board at month start | Catch-up run generates the correct board; unlock catch-up reveals what should already be visible |
| Daily unlock missed | Fewer quests visible than expected | Next run reveals all due quests in one pass, never double-revealing |
| Golden Quest job missed | Week has no Golden Quest yet | Catch-up selection keyed to that week |
| Evaluation lag | Completion appears late | Bounded by reconciler cadence; defensive re-evaluation at board close |
| Bingo evaluated twice | Milestone recorded once | Exactly-once milestone record |
| Library exhaustion | Draw cannot honour the exclusion window | Window relaxes stepwise and the relaxation is logged for content-team action |

### 11.2 Offline behaviour (client)

- **Reads**: last cached DNA snapshot, quest board and scenario content remain viewable with a clear staleness indicator.
- **Writes**: V2 performs **no offline write queueing**. Pulse submissions, coffee completions and attestations require connectivity and present an explicit offline state. Rationale: a queued Pulse answer submitted days later would produce coaching detached from its moment and would corrupt the honesty of the reflection; queued coffee completions would race the round-close job. This is a deliberate simplification, not an omission.
- The existing connectivity capability in the client is reused; no new offline infrastructure is introduced.

### 11.3 Data consistency model

| Guarantee | Where it applies |
|---|---|
| Strong, transactional | Pulse answer capture; coffee completion guard; board generation; contribution writes |
| Exactly-once (by key) | Contributions, quest completions, milestones, job runs |
| Eventually consistent | V1-derived contributions, derived quest completions, DNA strands sourced from V1 |
| Monotonic | DNA growth (no decay path exists) |
| Rebuildable | DNA snapshot (from the ledger); quest milestone state (from completions) |

The bounded staleness of V1-derived data is an accepted product property and is reflected in the product copy, not hidden.

---

## 12. Scalability Review

| Dimension | 20 managers | 100 | 250 | 1000 |
|---|---|---|---|---|
| Coffee pair space (n²/2) | 190 | 4,950 | 31k | ~500k |
| Matching cost | Trivial | Trivial | Batch, seconds | Batch job; heuristic matching instead of exhaustive scoring |
| Coffee groups per round | 5–7 | ~28 | ~70 | ~280 |
| Invitation fan-out | Trivial | Trivial | Batch dispatch advised | **Batched dispatch required** |
| Quest board generation | Constant (cohort-wide) | Constant | Constant | Constant |
| Quest evaluation | Cells × managers, trivial | Fine | Fine | Chunked/paged evaluation required |
| Reconciler volume | Trivial | Fine | Fine | Windowed + chunked; possibly parallel per source |
| Contribution ledger growth | Negligible | Small | Moderate | Retention/partitioning policy needed |
| DNA snapshot reads | O(1) per manager at every scale | O(1) | O(1) | O(1) |
| AI call volume (Pulse) | ≤3/manager/week | Linear | Linear | Linear — cost, not architecture, is the constraint |
| Realtime channels | Minimal | Fine | Fine | Review per-connection channel count |

**Verdict:** no architectural change is required up to ~250 managers. Between 250 and 1000, three *implementation* changes are needed — batched notification dispatch, chunked quest evaluation, and a heuristic (rather than exhaustive) matcher — none of which alters a boundary, a module ownership, or a data flow defined in this document. The architecture therefore satisfies the existing non-functional requirement of scaling well beyond the current cohort without redesign.

---

## 13. Risk Assessment

### 13.1 Architecture risks

| Risk | Impact | Mitigation |
|---|---|---|
| Contribution ledger becomes a de-facto god table every feature writes to arbitrarily | High | Exactly one writer module (`contribution.service`) with a fixed emission contract; no direct writes permitted |
| DNA acquires outbound dependencies over time ("DNA sends a notification", "DNA unlocks a quest") | High | INV-3 is stated as an invariant, not a preference; any proposal to break it re-opens Phase 2 |
| Quest grows its own counters for convenience | Medium | INV-4; rule evaluation is the only completion path |
| V2 slowly leaks into V1 modules through "tiny" edits | High | INV-1; the only authorised cross-boundary write is the Feed publication, named explicitly |

### 13.2 Scheduling risks

| Risk | Impact | Mitigation |
|---|---|---|
| Scheduler silently stops and nobody notices for weeks | **Critical** | Self-check job + alerting on expected-window misses; job health view; the absence of a board is itself detectable |
| Duplicate execution creates duplicate rounds, boards or notifications | High | Domain identity keys checked before work + claim-based job runs |
| A retry storm hammers the platform | Medium | Bounded retries, exponential backoff with jitter, permanent-failure classification that stops retrying |
| Staging environment notifies real managers | High | Scheduled jobs disabled by default outside production; explicit enablement; global kill switch |
| Secret used by the scheduler leaks into a job definition or a log | High | Secret held in the database secret store; never logged; transport guard requires it rather than echoing it |

### 13.3 AI risks

| Risk | Impact | Mitigation |
|---|---|---|
| Provider outage during a launch week | High | Persistence-before-call; pending state; sweeper; the product remains coherent without coaching |
| Latency makes the flagship interaction feel slow | High | Hard budget; asynchronous handoff instead of waiting; provider chosen for latency |
| Model produces off-tone or inappropriate coaching | High | Constrained output shape, validation before persistence, content review before launch, reporting path |
| Prompt injection | Low by construction | The user submits a choice, not free text |
| Provider cost grows unexpectedly | Medium | Bounded output size, single call per answer, no multi-turn coaching in V2 |
| Two AI providers double the operational surface | Medium | Full module isolation; separate configuration; V1 pipeline untouched and independently diagnosable |

### 13.4 Data risks

| Risk | Impact | Mitigation |
|---|---|---|
| Double counting inflates DNA and devalues it | High | Occurrence-key exactly-once at the single ledger writer |
| Weight tuning corrupts existing DNA | Medium | Weights are configuration; the snapshot is rebuildable from the ledger; tuning is a replay, not a migration |
| Private data accidentally exposed through a join or a view | **Critical** | RLS at the row level for every private table; no admin or analytics path exists to expose |
| Reconciler misses V1 rows at a boundary | Medium | Watermark overlap window + duplicate absorption |
| Ledger growth degrades queries | Low near-term | Indexing by manager and occurrence; retention policy revisited at the 1000-manager scale |

### 13.5 Operational risks

| Risk | Impact | Mitigation |
|---|---|---|
| No visibility into whether V2 is working | High | Job-run ledger + structured logs + admin health view + alerting, mirroring the Insights pipeline's proven diagnostics convention |
| Quest library exhaustion produces repetitive months | Medium | Exclusion window with logged relaxation as an early warning to the content team |
| Orphaned uploads accumulate in storage | Low | Daily orphan sweep |
| An incident requires a fast stop | Medium | Global kill switch for scheduled work without a deploy |

### 13.6 Maintainability risks

| Risk | Impact | Mitigation |
|---|---|---|
| Duplicated AI transport between V1 and V2 drifts | Medium | Accepted trade-off, documented as a V3 consolidation candidate; V2 module is small and self-contained |
| Four new features double the surface to maintain | Medium | Identical structural conventions to V1 (feature-first client modules, `index`/`use-case`/`_shared` functions), so no new mental model |
| Business rules hidden in code make tuning a release event | Medium | Weights, thresholds, cadences, libraries and windows are configuration/content |

### 13.7 Integration risks

| Risk | Impact | Mitigation |
|---|---|---|
| Coffee Roulette posts regress Feed behaviour | High | Publication through the existing creation path with a distinct post type; V1 regression suite must pass unchanged |
| New notification types overwhelm the inbox | Medium | Additive type set inside the existing model; Phase 1 volume ceiling enforced in design review |
| Realtime additions increase client connection load | Medium | Minimal publication additions; realtime used only where a pending-to-ready transition genuinely benefits |
| New routes disturb existing navigation | Low | Additive named routes only; no restructuring of the existing tab model |

---

## 14. Engineering Decisions (ADR summary)

| ID | Decision | Alternatives rejected | Consequence |
|---|---|---|---|
| ADR-01 | Scheduling via in-database cron invoking guarded Edge Functions, with a job-run ledger | SQL-only jobs; external CI scheduler; client-triggered generation | Phase 1 blocker resolved; logic stays in the existing function pattern |
| ADR-02 | Domain identity keys are the correctness mechanism; the job ledger is for observability and retries | Ledger-only idempotency | Survives partial failures between work and bookkeeping |
| ADR-03 | DNA = append-only contribution ledger + per-manager snapshot | Read-time aggregation; counters per feature | O(1) reads, rebuildable state, exactly-once growth |
| ADR-04 | V1 participation is observed by a scheduled reconciler, never by triggers or V1 code changes | Database triggers on V1 tables; editing V1 functions | "V1 untouched" is literally true; cost is bounded staleness |
| ADR-05 | Quest owns no counters; completion is rule evaluation over the ledger | Per-quest counters | One source of truth; board and reality cannot drift |
| ADR-06 | V2 gets its own AI module; the V1 Insights AI client is untouched | Generalising the V1 client for both | Full blast-radius isolation; accepted small duplication |
| ADR-07 | Pulse persists the answer and the contribution before any AI call; coaching is derived and retryable | Synchronous coaching as part of the submission transaction | An AI outage can never destroy manager effort |
| ADR-08 | No cross-provider AI failover in V2 | Groq → OpenAI fallback | Consistent coaching voice; failover remains architecturally possible |
| ADR-09 | Coffee photos reuse the existing public image bucket and the existing moderation model | New private bucket with a bespoke access model | No second moderation surface; privacy implication stated explicitly |
| ADR-10 | Coffee Roulette publishes to the Feed through the existing creation path only | Direct writes to Feed data | Feed behaviour, moderation and rendering remain unchanged |
| ADR-11 | Quest boards are cohort-wide, generated once per month | Per-manager boards | Generation cost independent of cohort size; shared context preserved |
| ADR-12 | The month's unlock plan is computed at generation time; the daily job only advances a pointer | Daily random draw | A missed day is a late reveal, never a wrong board |
| ADR-13 | No offline write queue in V2 | Offline queueing for submissions | Avoids stale reflections and round-close races |
| ADR-14 | DNA rendering separates pure render parameters from the animated painter, with a mandatory static fallback | Animation driven directly from data models | Testable, and safe on low-end devices and reduced-motion settings |
| ADR-15 | Weights, thresholds, cadences, libraries and avoidance windows are configuration/content, not code | Hard-coded tuning | Tuning without a release |

---

## 15. Open Questions (Phase 3 inputs — none blocking)

| # | Question | Owner | Needed by |
|---|---|---|---|
| 1 | Exact cadence values for the "frequent" jobs (reconciler, quest evaluation, coaching sweep) | Backend + Product | Phase 3 |
| 2 | Coaching wall-clock budget and retry caps on the synchronous path | AI + UX | Phase 3 |
| 3 | Repeat-avoidance window length for the current cohort, and the relaxation ladder | Product + Backend | Phase 3 |
| 4 | Initial strand weights and stage thresholds (configuration values, not architecture) | Product | Phase 4 |
| 5 | Quest and Golden Quest library sizes, category taxonomy, and the derived/attested split per entry | Product + Content | Phase 3 |
| 6 | Which V2 state (if any) justifies realtime publication beyond coaching readiness | Flutter + Backend | Phase 3 |
| 7 | DNA performance budget expressed against a named baseline device | Flutter | Phase 3 |
| 8 | Notification volume ceiling allocation across the four features | Product + UX | Phase 3 |
| 9 | Retention policy for the contribution ledger at larger cohorts | Database | Deferred (not needed for launch scale) |

None of these changes a boundary, a module ownership, a data flow or an interaction defined above.

---

## 16. Implementation Readiness

### 16.1 Success-condition checklist

| Condition | Status | Evidence |
|---|---|---|
| All four features have a complete engineering architecture | ✅ | Sections 3.1–3.4 |
| Scheduling architecture fully resolved | ✅ | Section 5 — execution model, idempotency, retries, recovery, monitoring, operational safety |
| Feature interactions frozen | ✅ | Section 8, including explicit non-interactions |
| AI architecture defined | ✅ | Section 6 — providers, isolation, abstraction, timeouts, fallback, security, replacement |
| Module ownership clear | ✅ | Section 7 |
| Data flows documented end to end | ✅ | Section 4 |
| Failure and recovery defined per feature | ✅ | Section 11 |
| Scalability evaluated to 1000 managers | ✅ | Section 12 |
| Security boundaries defined and enforceable | ✅ | Section 9 |
| No implementation decisions made (no code, SQL, tables, APIs, packages) | ✅ | Architecture-level only throughout |
| V1 remains untouched | ✅ | INV-1, ADR-04, ADR-06, ADR-10 |

### 16.2 Dependency completeness

All V2 dependencies are known and available: the existing auth/profile model, the existing notification service and inbox model, the existing storage buckets and moderation model, the existing Feed post-creation path, the existing Edge Function and validator conventions, the newly-specified in-database scheduler, and one new AI provider behind a replaceable adapter.

### 16.3 Isolation verification

- Every V2 module has a named owner and an explicit dependency list (Section 7).
- The only V2 → V1 write is the Feed publication (INV-2, ADR-10).
- The only V2 → V1 read surface is the reconciler (ADR-04).
- DNA is a leaf node (INV-3).
- Exactly one writer exists for the contribution ledger and for the job-run ledger.

### 16.4 Verdict

The V2 engineering architecture is complete, internally consistent, and frozen. The Phase 1 scheduling blocker is fully resolved. Feature boundaries, module ownership, data flows, interactions, failure behaviour, security boundaries and scaling limits are all defined. No implementation decisions have been taken, and the V1 application is unmodified.

**Implementation planning (Phase 3) may begin.**

---

## 17. Architecture Freeze Declaration

The architecture defined in this document is **frozen**.

- No module may take a dependency not listed in Section 7.
- No interaction may be added that is not in Section 8, and no frozen non-interaction may be broken.
- No invariant in Section 2.3 may be violated.
- Any change to an ADR in Section 14 requires formally re-opening Phase 2.
- Phases 3 through 12 implement exactly this architecture.
