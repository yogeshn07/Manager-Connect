# The Catalysts — Version 2

## Phase 1: Product Vision & Feature Definition

| Field | Value |
|---|---|
| Document | `docs/v2/planning/v2_phase1_product_vision.md` |
| Phase | 1 of 12 — Product Vision & Feature Definition |
| Status | **LOCKED** (scope frozen) |
| Date | 2026-08-06 |
| Applies to | The Catalysts V2 (four flagship features) |
| Authoring panel | Principal Product Architect, Principal Software Architect, Principal UX Architect, Principal Flutter Architect, Principal Backend Architect, Principal AI Systems Architect, Principal Solutions Architect, Engineering Director, Product Manager |
| Contains implementation decisions | **No** — no schema, no API, no UI, no code |

---

## 1. Executive Summary

The Catalysts V1 is complete and production-ready: a private community platform for a closed cohort of managers, built on Flutter + Supabase, covering Managers Feed, Catalyst (GI) Insights, Events, Wellness/Challenges, Games, Analytics, Profile, Authentication, Admin and Notifications. V1 answers the question *"what is my community doing?"*

V2 answers a different question: **"who am I becoming as a leader?"**

V2 adds four flagship features and nothing else:

1. **Leadership Pulse** — short, AI-coached leadership scenarios that build managerial judgement in under two minutes.
2. **Coffee Roulette** — backend-matched small groups (3–4 managers) that meet, take one photo, and share it to the Feed.
3. **Manager DNA** — a private, animated visualisation of the manager's own participation and growth across the whole application.
4. **Catalyst Quest** — a monthly 6×6 quest board with daily unlocks, weekly Golden Quests, Monthly Bingo and Perfect Catalyst Month.

Three of the four features are *inputs*. One of them — Manager DNA — is the *output* that gives every other action a lasting, personal meaning. That asymmetry is the core product idea of V2, and it is the reason V2 increases retention without adding a single competitive or addictive mechanic.

V1 remains untouched. No V1 feature is redesigned, removed, replaced, or degraded. Every V2 feature is additive: new surfaces, new data, new background jobs, and the smallest possible set of touchpoints in existing screens.

**Phase 1 verdict: the V2 product vision is complete, internally consistent, non-overlapping, and ready for Phase 2 planning.**

---

## 2. Version 2 Vision

### 2.1 Vision statement

> The Catalysts V2 turns a manager community app into a private leadership growth companion — where every conversation, every meeting, every reflection and every small monthly act visibly composes one thing that belongs only to you.

### 2.2 What V2 becomes

V1 is a **community layer**: shared feed, shared events, shared challenges, shared insights. It is inherently outward-facing — everything a manager does is visible to the group.

V2 adds a **personal layer** on top of that community layer, without separating the two:

| Layer | V1 | V2 addition |
|---|---|---|
| Community | Feed, Events, Insights, Wellness, Games, Analytics | Coffee Roulette groups and their Feed posts |
| Practice | Challenges, Polls | Leadership Pulse scenarios, Catalyst Quest board |
| Self | Profile, personal stats | **Manager DNA** — private growth visualisation |

The strategic shift: in V1, a manager's reason to return is *external* (something happened in the community). In V2, a manager also has an *internal* reason to return (something of mine is growing). Internal motivation is more durable, survives quiet weeks, and does not require notification pressure.

### 2.3 Why these four, and why together

- **Leadership Pulse alone** would be a quiz app — engaging for two weeks, then abandoned.
- **Coffee Roulette alone** would be a scheduling utility — valuable but episodic.
- **Catalyst Quest alone** would be a checklist — mechanical and eventually gamey.
- **Manager DNA alone** would be a chart — pretty but inert.

Together they form a closed loop: Quest suggests the action → Pulse and Coffee Roulette make the action meaningful → DNA records that it happened and shows the manager who they are becoming. Each feature makes the others matter more. Remove any one and the loop leaks.

### 2.4 Positioning guardrails

V2 is **not**:

- a performance-management or HR-evaluation tool,
- a personality assessment or psychometric instrument,
- a leaderboard, ranking system, or public score,
- a streak-punishment or loss-aversion engine.

V2 **is**: a private, positive, low-pressure, premium companion for managers who already trust this application.

---

## 3. Feature Specifications

### 3.1 Leadership Pulse

#### 3.1.1 Purpose

Deliver short, realistic managerial scenarios, let the manager choose how they would respond, and return an AI leadership-coach analysis of that specific choice. The value is not "right answer / wrong answer" — it is a structured, non-judgemental reflection on the trade-offs the manager just made.

#### 3.1.2 User value

- Practises real leadership judgement in under two minutes, on days when a full training module is impossible.
- Receives personal, specific coaching feedback instead of generic leadership content.
- Builds a private record of reflections, visible only to the manager.
- Feeds the Reflection strand of Manager DNA, so short reflections accumulate into something visible.

#### 3.1.3 Business value

- Highest-frequency return driver in V2 (short, repeatable, low-friction).
- Converts an engagement platform into a leadership-development platform — a materially stronger reason for the organisation to fund and mandate the application.
- Produces anonymised aggregate signal (which leadership dimensions the cohort finds hardest) for future organisational learning, without ever exposing individual answers.

#### 3.1.4 Core functionality

1. A scenario is presented: a short situation (a few sentences) drawn from real managerial life — conflict, delegation, feedback, prioritisation, change, wellbeing, stakeholder pressure.
2. The manager selects **one** of a small set of plausible options. Every option is defensible; none is a trap.
3. On submission, the selected option is analysed by the AI Leadership Coach.
4. The coach returns four elements, always in this order and always in this shape:
   - **Strengths** — what the choice gets right,
   - **Weaknesses** — what it risks or under-weighs,
   - **Suggested improvement** — one concrete adjustment,
   - **Leadership takeaway** — one durable principle.
5. The reflection is stored privately in the manager's Pulse history.
6. Completion contributes to the Reflection strand of Manager DNA.

#### 3.1.5 Product decisions locked in this phase

| Decision | Locked value | Rationale |
|---|---|---|
| Cadence | Up to **3 scenarios per week**, available for the full week; no daily expiry pressure | Frequent enough to build a habit, forgiving enough to survive travel weeks |
| Answer model | Single choice, one submission per scenario, **no re-answer** | Preserves the honesty of the reflection; avoids answer-shopping for a better AI response |
| Feedback tone | Coaching, never grading. No score, no correctness label, no "you failed" | Non-negotiable UX principle; a graded response would make managers optimise for the AI |
| Visibility | **Private to the manager.** Never posted to Feed, never visible to admin, never in Analytics per-person | Psychological safety is the precondition for honest answers |
| AI provider | **Groq**, as directed for V2 | Latency-first choice; user-facing coaching must feel instant |
| Failure behaviour | If AI is unavailable, the answer is still recorded and DNA still grows; coaching is delivered when available | Manager effort must never be lost because of an external dependency |

#### 3.1.6 Success criteria

- ≥ 60% of active managers complete at least one scenario per week.
- ≥ 80% of started scenarios are submitted (low abandonment).
- Median time from submission to coaching displayed: ≤ 3 seconds.
- ≥ 70% of surveyed managers agree the coaching was "specific to my answer, not generic".
- Zero incidents of Pulse content appearing in any shared surface.

#### 3.1.7 Dependencies

- Authentication and profile (V1, unchanged).
- Notification infrastructure (V1) for an optional weekly availability nudge.
- A curated scenario library and its coaching prompt design.
- An external AI provider (Groq) — the first user-facing, latency-sensitive AI dependency in the product. (V1 already uses AI for Insights enrichment, but only in a background pipeline.)
- Manager DNA (for growth contribution).

---

### 3.2 Coffee Roulette

#### 3.2.1 Purpose

Deliberately break the natural clustering of a manager community by randomly grouping 3–4 managers who would not otherwise meet, giving them a light, socially safe reason to sit down together, and turning the outcome into one shared photo.

#### 3.2.2 User value

- Removes the awkwardness of initiating: the system, not the person, made the introduction.
- Meets managers outside their functional silo.
- Produces a memory (photo + caption) rather than a meeting record.
- Contributes to the Connection strand of Manager DNA.

#### 3.2.3 Business value

- Directly targets cross-functional cohesion, the single hardest social outcome to engineer in a manager population.
- Generates authentic, high-quality Feed content with no content-creation effort — the strongest antidote to feed decay.
- Produces a measurable relationship-coverage metric (which pairs of managers have actually met).

#### 3.2.4 Core functionality

1. The backend forms random groups of 3–4 managers from active members for each round.
2. Every member of a group receives an invitation notification and sees the round inside the Coffee Roulette page.
3. The group self-organises the meeting (in person or virtual) — the application does not schedule, book, or track calendars.
4. After meeting, any member of the group can submit the round's completion:
   - **one** group photo (required),
   - **an optional caption**.
5. On submission:
   - the round is saved to the group's Coffee Roulette History,
   - a post is automatically published to the Managers Feed,
   - all members of the group receive Connection growth in Manager DNA.
6. Coffee Roulette History is browsable by the manager: every past round, the people, the photo, the caption, the date.

#### 3.2.5 Product decisions locked in this phase

| Decision | Locked value | Rationale |
|---|---|---|
| Round cadence | **Monthly** | Matches Catalyst Quest's monthly rhythm; a coffee is a real-world commitment and weekly would breed guilt |
| Group size | 3–4 managers, never 2 | Trios are socially safer than pairs and survive one no-show |
| Repeat avoidance | The matcher **must** avoid recently-grouped combinations within a rolling window | With ~20 managers, naive randomness repeats groups quickly and destroys the novelty that is the entire point |
| Submission rights | **Any** member of the group may submit on behalf of the group; one submission per round per group | Removes the coordination deadlock of "who posts it?" |
| Feed post authorship | Attributed to the **group**, not to the submitter alone | The artefact is collective |
| Opt-out | A manager may opt out of a round or of Coffee Roulette entirely, silently | Consent is mandatory for a social feature; silent opt-out avoids social cost |
| Non-completion | A round that is never completed simply expires. **No penalty, no public non-completion signal, no DNA loss** | Stress-free principle |
| Photo handling | Same trust and moderation model as existing Feed images (V1 moderation applies) | No new moderation surface |

#### 3.2.6 Success criteria

- ≥ 70% of formed groups complete and submit their round within the round window.
- ≥ 90% of managers are matched in any given round (excluding opted-out members).
- ≥ 50% of relationship pairs in the cohort have met at least once after six rounds.
- Coffee Roulette Feed posts achieve above-median engagement compared with ordinary posts.
- Zero rounds where the same group composition repeats inside the avoidance window.

#### 3.2.7 Dependencies

- Managers Feed and its image pipeline (V1, unchanged behaviour; new content source only).
- Notification infrastructure (V1) for invitations and gentle reminders.
- Profiles and active-member state (V1).
- A reliable scheduled background execution mechanism for round generation. **This is the single most important infrastructure dependency in V2** — Coffee Roulette rounds, Catalyst Quest boards, daily unlocks and weekly Golden Quests all require dependable scheduling. Phase 2 must confirm the production scheduling mechanism before any of this is planned in detail.
- Manager DNA (for growth contribution).

#### 3.2.8 Relationship to V1's "Connect Buddy"

V1 contains a Connect Buddy system account that posts automated community messages to the Feed (welcomes, reminders, monthly highlights, memories). **Coffee Roulette is a different feature and must not be merged into it**: Connect Buddy is a one-way system voice; Coffee Roulette is a many-to-many human matching mechanism. They may coexist. Phase 2 must ensure Coffee Roulette Feed posts are visually and semantically distinct from Connect Buddy posts so the Feed does not read as "the robot again".

---

### 3.3 Manager DNA

#### 3.3.1 Purpose

Give each manager one private, beautiful, animated representation of their own leadership journey inside The Catalysts — a living artefact that starts faint and becomes vivid as they participate.

#### 3.3.2 User value

- Makes invisible, scattered effort visible in one place.
- Rewards participation without comparison — the manager competes with nobody.
- Provides a genuine emotional payoff: the DNA is *theirs*, and it looks better because of what they did.
- Creates a reason to return even in a quiet week ("has mine changed?").

#### 3.3.3 Business value

- The retention keystone of V2. It converts every other feature's engagement into compounding value.
- The premium signature of the product — the single screen that differentiates The Catalysts from any generic engagement app.
- Safe by construction: private, non-comparative, and therefore immune to the political risk that a visible leadership score would carry inside an organisation.

#### 3.3.4 Core functionality

1. Every manager has exactly one Manager DNA.
2. It begins as a **faint helix** — visible, unmistakably incomplete, and inviting.
3. It grows along **strands**, each fed by a distinct kind of participation:

| Strand | Meaning | Primary sources |
|---|---|---|
| Reflection | Thinking about leadership deliberately | Leadership Pulse |
| Connection | Building relationships across the cohort | Coffee Roulette |
| Consistency | Showing up over time | Catalyst Quest |
| Expression | Contributing your voice to the community | Posts, Comments |
| Presence | Being physically/actually there | Events |
| Wellbeing | Sustaining yourself | Wellness, Games |

4. As strands grow, the helix gains **density, colour, motion and complexity**. Growth is expressed as visual evolution — not as a number the manager is asked to maximise.
5. The manager can inspect what contributed to each strand (their own history only).
6. Manager DNA is **private**. It is never shown to other managers, never shown to admins, never ranked, never exported into Analytics as a per-person figure.

#### 3.3.5 Product decisions locked in this phase

| Decision | Locked value | Rationale |
|---|---|---|
| Privacy | Absolutely private to the manager. No sharing feature in V2 | Sharing would immediately recreate a leaderboard socially, even without one in the product |
| Decay | **No decay in V2.** Growth is never lost | Decay converts a growth artefact into a debt; it contradicts the stress-free principle |
| Score exposure | Strand progress is shown **visually first**. No headline number, no percentage-to-next-level as the primary reading | A prominent number invites optimisation and comparison |
| Level model | Each strand advances through a small number of visible stages; the whole DNA has an overall visual maturity that emerges from the strands | Emergence keeps the artefact feeling organic rather than gauge-like |
| Source of truth | DNA growth is derived from **already-recorded participation events**, not from a separate parallel scoring system managers can game | Prevents a shadow economy of points |
| Retro-credit | V1 historical participation is **not** back-filled into DNA at launch; DNA starts from V2 launch for everyone | Equal start; avoids managers arriving at a pre-grown DNA they don't understand |
| Animation cost | The animation must never degrade application performance or battery on the supported device baseline | Non-negotiable; see Risks |

#### 3.3.6 Success criteria

- ≥ 75% of active managers open Manager DNA at least once per month.
- ≥ 90% of managers reach a visibly non-faint DNA within their first 60 days.
- All six strands are non-zero for ≥ 50% of managers within 90 days (i.e. the growth sources are balanced, not dominated by one feature).
- Manager DNA screen sustains its target frame rate on the baseline device.
- Zero incidents of DNA data appearing in any shared or admin surface.

#### 3.3.7 Dependencies

- Every other feature that emits participation: Leadership Pulse, Coffee Roulette, Catalyst Quest, Feed posts/comments, Events, Wellness, Games (all V1 features are read-only sources — their behaviour does not change).
- Profile surface (V1) as the entry point.
- Flutter animation capability within the existing performance envelope.

---

### 3.4 Catalyst Quest

#### 3.4.1 Purpose

Give the month a shape. A generated board of small, achievable leadership and community actions that a manager can pick up in any order, with a light unlock rhythm and two celebratory completion states.

#### 3.4.2 User value

- Replaces "what should I do in the app today?" with a concrete, small suggestion.
- Rewards breadth of participation rather than grinding one activity.
- Provides a monthly reset — a bad month is over in weeks, not carried forever.
- Feeds the Consistency strand of Manager DNA.

#### 3.4.3 Business value

- The scheduling backbone of V2 engagement: it is the feature that reliably brings managers back on ordinary days.
- Distributes engagement across the whole application (including V1 features) instead of concentrating it in whichever feature is newest.
- Fully automated after launch — the board is backend-generated from a curated library, requiring no monthly admin effort.

#### 3.4.4 Core functionality

1. **Monthly board**: a **6×6 grid** plus **4 additional quest cells** — **40 monthly quests** in total, generated automatically by the backend at the start of each month.
2. **Quest Library**: the curated pool from which the 40 monthly quests are drawn, categorised so that a generated board is always balanced across leadership, community, wellbeing and reflection.
3. **Daily unlocks**: **2 quests unlock per day**, creating a gentle, non-anxious daily reason to open the board. Unlocked quests remain available for the rest of the month.
4. **Weekly Golden Quest**: one higher-value, higher-effort quest per week, drawn from the separate **Golden Quest Library**.
5. **Monthly Bingo**: completing a full line on the 6×6 grid (row, column, or diagonal) is a recognised, celebrated milestone.
6. **Perfect Catalyst Month**: completing all 40 quests in a month is the rarest recognition in the product.
7. All quest completion contributes to the Consistency strand of Manager DNA; quests that are themselves other features (e.g. "complete a Leadership Pulse") also contribute to their own strand.

#### 3.4.5 Product decisions locked in this phase

| Decision | Locked value | Rationale |
|---|---|---|
| Board size | 6×6 grid + 4 extra cells = 40 quests | As specified; the 4 extra cells sit outside the Bingo grid and cannot form Bingo lines |
| Bingo definition | A completed row, column or diagonal of the 6×6 grid | Simple, universally understood, visually obvious |
| Generation | Fully automatic, monthly, per-cohort (all managers see the same board) | Shared board creates natural conversation; per-manager boards would fragment the cohort |
| Golden Quest | One per week, from a separate library, higher DNA contribution | Creates a weekly beat without a weekly obligation |
| Expiry | The board resets monthly. Unfinished quests **do not** carry over and are **not** penalised | Monthly reset is the anti-guilt mechanism |
| Verification | Quests are satisfied by **real recorded participation** wherever the action exists in the product; self-declared quests are limited and clearly framed as honour-system | A quest board that can be tapped-to-complete becomes meaningless, and meaningless quests devalue DNA |
| Competition | No public quest leaderboard, no "X managers finished before you" | No public competition — non-negotiable |

#### 3.4.6 Success criteria

- ≥ 70% of active managers open the board at least twice per week.
- Median quests completed per manager per month: ≥ 15 of 40.
- ≥ 40% of managers achieve at least one Monthly Bingo per month.
- 5–15% of managers achieve a Perfect Catalyst Month (rare enough to matter, achievable enough to chase).
- 100% of monthly boards generate automatically and on time, with zero manual admin intervention.

#### 3.4.7 Dependencies

- Reliable scheduled backend execution (monthly board generation, daily unlocks, weekly Golden Quest) — shared with Coffee Roulette.
- Participation signals from V1 features (Events, Feed, Wellness, Games) and V2 features (Pulse, Coffee Roulette) to satisfy quests automatically.
- Curated Quest Library and Golden Quest Library content.
- Manager DNA (for growth contribution).

---

## 4. User Journeys

### 4.1 Leadership Pulse

**Primary journey — the two-minute reflection**

1. Manager opens the application and sees that a new Pulse scenario is available.
2. Opens Leadership Pulse; reads a short scenario.
3. Weighs the options; selects one.
4. Submits.
5. Within seconds, the AI Leadership Coach returns strengths, weaknesses, a suggested improvement, and a leadership takeaway.
6. Manager reads it; feels seen rather than judged.
7. A subtle confirmation shows the Reflection strand of their DNA has grown.

**Secondary journey — revisiting reflections**

1. Manager opens their Pulse history.
2. Browses past scenarios, their own answers, and the coaching they received.
3. Recognises a pattern in their own decision style over time.
4. Optionally jumps to Manager DNA to see the accumulated Reflection strand.

### 4.2 Coffee Roulette

**Primary journey — the round**

1. A new round begins; the manager is notified that they have been grouped with 2–3 others.
2. Opens Coffee Roulette; sees who is in the group and the round window.
3. The group coordinates a coffee (in the group's own channel — the application does not schedule it).
4. They meet.
5. One member opens Coffee Roulette, uploads the group photo, optionally adds a caption, and submits.
6. The round moves to History; a post appears in the Managers Feed; every member's Connection strand grows.
7. Other managers see the post in the Feed and react — the social proof that makes the next round easier.

**Secondary journey — history and opt-out**

- *History*: manager browses past rounds — who, when, the photo, the caption — as a record of relationships built.
- *Opt-out*: manager who cannot participate this round opts out silently; no notification is sent to anyone, no penalty is recorded, and the matcher excludes them from the round.

### 4.3 Manager DNA

**Primary journey — the check-in**

1. Manager opens Manager DNA from their profile.
2. Sees their helix, animated, in its current state.
3. Notices it is visibly richer than the last time.
4. Explores the strands; sees which kinds of participation drove the change.
5. Notices a faint strand and, unprompted, decides to do something about it.

**Secondary journey — the growth moment**

1. Manager completes any contributing action anywhere in the application.
2. Receives an immediate, subtle acknowledgement that their DNA grew — in place, without leaving the feature they were using.
3. Optionally taps through to Manager DNA to see the change in full.

### 4.4 Catalyst Quest

**Primary journey — the daily board**

1. Manager opens Catalyst Quest.
2. Two new quests have unlocked today.
3. Scans the board: today's unlocks, this week's Golden Quest, and everything still open from earlier in the month.
4. Picks one that fits the day; performs the action (often inside an existing V1 feature).
5. The quest is marked complete; the Consistency strand grows.
6. The board shows the completed cell contributing toward a Bingo line.

**Secondary journey — the milestone**

1. Manager completes the cell that finishes a row.
2. Monthly Bingo is celebrated — visibly, warmly, and privately.
3. Toward month end, a manager close to all 40 sees a clear, achievable path to a Perfect Catalyst Month.
4. On completion, the rarest recognition in the product is awarded, and Manager DNA reflects it distinctly.

### 4.5 Pain points solved

| Pain point (observed in V1-class products) | Solved by |
|---|---|
| "I open the app and there's nothing new for me to do." | Catalyst Quest daily unlocks |
| "The feed goes quiet for a week." | Coffee Roulette rounds generate authentic content |
| "I only know the managers in my own function." | Coffee Roulette random matching with repeat avoidance |
| "My participation disappears — nothing accumulates." | Manager DNA |
| "Leadership training is long, scheduled, and irrelevant to today." | Leadership Pulse — two minutes, situational, personal |
| "Engagement features make me feel watched or ranked." | Private DNA, private Pulse, no leaderboards anywhere in V2 |
| "Missing a day makes me feel guilty and I stop entirely." | No decay, no streak punishment, monthly reset |

---

## 5. Feature Relationships

### 5.1 Flow map

```
Leadership Pulse ──────────────► Manager DNA (Reflection)

Coffee Roulette ──► Managers Feed ──► Manager DNA (Connection)
        │
        └──────────► Coffee Roulette History

Catalyst Quest ────────────────► Manager DNA (Consistency)
        │
        └──► drives participation in ──► Pulse, Coffee Roulette,
                                          Feed, Events, Wellness, Games

V1 participation (Posts, Comments, Events, Wellness, Games)
        └──────────────────────► Manager DNA (Expression, Presence, Wellbeing)

Manager DNA ───────────────────► Personal Growth Visualization
```

### 5.2 Interaction matrix

| From → To | Leadership Pulse | Coffee Roulette | Manager DNA | Catalyst Quest |
|---|---|---|---|---|
| **Leadership Pulse** | — | none | Feeds Reflection strand | Can satisfy Pulse-type quests |
| **Coffee Roulette** | none | — | Feeds Connection strand | Can satisfy Connection-type quests |
| **Manager DNA** | Shows Reflection progress; may motivate a Pulse | Shows Connection progress; may motivate a round | — | Shows Consistency progress |
| **Catalyst Quest** | Directs manager to complete a Pulse | Directs manager to complete a round | Feeds Consistency strand | — |

**Deliberate non-interactions** (to prevent overlap and complexity):

- Leadership Pulse and Coffee Roulette have **no direct relationship**. They meet only through DNA and Quest.
- Manager DNA **never writes** to any other feature. It is a read-and-render surface. This one-directional rule is what keeps DNA from becoming a scoring engine that other features must respect.
- Catalyst Quest **never invents new participation types**. It points at actions that already exist. A quest is a pointer, not a new activity.

### 5.3 Interaction with existing V1 features

| V1 feature | V2 interaction | V1 behaviour change |
|---|---|---|
| Managers Feed | Receives Coffee Roulette posts as a new content source | **None** — existing posting, reactions, comments, moderation unchanged |
| Catalyst / GI Insights | No interaction in V2 | **None** |
| Events | Read-only source for the Presence strand; target of quests | **None** |
| Wellness / Challenges | Read-only source for the Wellbeing strand; target of quests | **None** |
| Games | Read-only source for the Wellbeing strand; target of quests | **None** |
| Analytics | No V2 data enters Analytics; DNA is not an analytics artefact | **None** |
| Profile | Gains an entry point to Manager DNA | Additive only |
| Authentication | No interaction | **None** — explicitly out of scope |
| Admin | Gains operational controls for Coffee Roulette rounds and quest content; **no access to private Pulse or DNA data** | Additive only |
| Notifications | Gains new notification categories for V2 events, within the existing notification model | Additive only |
| Navigation | V2 features are reachable without restructuring the existing tab model | Minimal, additive |

---

## 6. Experience Principles

These principles are binding on every subsequent phase. A design that violates one is rejected, regardless of engagement benefit.

1. **Private by default.** Pulse answers, coaching, and Manager DNA are the manager's alone. Not admin-visible, not analytics-visible, not shareable in V2.
2. **No public competition.** No leaderboard, no ranking, no "ahead of / behind" comparison anywhere in V2.
3. **No addictive mechanics.** No punishing streaks, no loss aversion, no artificial scarcity, no fear-of-missing-out timers.
4. **No decay.** What a manager has grown, they keep.
5. **Short interactions.** Every V2 interaction is completable in under two minutes, except a real coffee.
6. **Meaningful over frequent.** V2 would rather have three genuine interactions a week than fifteen hollow ones.
7. **Stress-free.** Missing a day, a round, or a quest costs nothing and is never surfaced as a failure.
8. **Restrained notifications.** V2 sends notifications only for things that genuinely require a person: a Coffee Roulette invitation, a round about to close, and a small number of gentle availability nudges — all respecting existing user preferences. No daily "you haven't opened the app" messages.
9. **Positive reinforcement only.** Feedback tells a manager what they did and what they could try. It never tells them what they failed to do.
10. **Premium quality.** Animation, typography, motion and copy must match or exceed the V1 bar. A rough V2 feature damages the whole product's perceived quality.
11. **Performance is a feature.** No V2 surface may degrade the application's existing performance characteristics.
12. **Additive, never disruptive.** A V1 user who ignores V2 entirely must experience an application identical to the one they had.

---

## 7. Business Value

### 7.1 Value by feature

| Feature | Primary business outcome | Secondary outcome |
|---|---|---|
| Leadership Pulse | Repositions the product as a leadership-development platform, not an engagement toy | Anonymised cohort insight into leadership development needs |
| Coffee Roulette | Measurable cross-functional relationship coverage | Self-sustaining authentic Feed content |
| Manager DNA | Long-term retention through personal, compounding value | The product's premium differentiator |
| Catalyst Quest | Reliable, automated monthly engagement rhythm | Distributes attention across all V1 features, extending their useful life |

### 7.2 Strategic value of V2 as a whole

- **Retention economics.** V1 retention depends on community activity, which is inherently bursty. V2 adds an individually-owned artefact that gives a reason to return during quiet periods. This flattens the engagement troughs that kill community apps.
- **Defensibility.** Manager DNA accumulates over months and cannot be transferred. Switching cost rises with tenure — ethically, because the value is genuinely the manager's own history.
- **Organisational safety.** Because nothing in V2 is comparative or admin-visible, it cannot be repurposed as a performance signal. That safety is what allows managers to be honest, which is what makes the product valuable.
- **Operating cost.** Catalyst Quest and Coffee Roulette are automated after launch. Ongoing admin effort is content curation, not operations.

---

## 8. Success Metrics

### 8.1 Feature metrics

| Metric | Target | Feature |
|---|---|---|
| Weekly Pulse completion rate | ≥ 60% of active managers | Leadership Pulse |
| Pulse submission rate (started → submitted) | ≥ 80% | Leadership Pulse |
| Coaching latency (median) | ≤ 3s | Leadership Pulse |
| Coffee Roulette round completion rate | ≥ 70% of formed groups | Coffee Roulette |
| Match coverage per round | ≥ 90% of non-opted-out managers | Coffee Roulette |
| Relationship pair coverage after 6 rounds | ≥ 50% of possible pairs | Coffee Roulette |
| Monthly DNA view rate | ≥ 75% of active managers | Manager DNA |
| Managers with visibly grown DNA by day 60 | ≥ 90% | Manager DNA |
| Managers with all six strands non-zero by day 90 | ≥ 50% | Manager DNA |
| Quest board open rate | ≥ 2× per week per active manager | Catalyst Quest |
| Median quests completed per manager per month | ≥ 15 of 40 | Catalyst Quest |
| Monthly Bingo achievement rate | ≥ 40% of managers | Catalyst Quest |
| Perfect Catalyst Month rate | 5–15% of managers | Catalyst Quest |
| Automated generation reliability | 100% on-time board and round generation | Quest + Coffee Roulette |

### 8.2 Product-level metrics

| Metric | Target |
|---|---|
| Weekly active managers | ≥ 80% of the cohort |
| 3-month retention after V2 launch | ≥ 90% |
| Median sessions per manager per week | ≥ 4 |
| Median session length | Unchanged or shorter than V1 (V2 is short-interaction by design) |
| V1 feature usage after V2 launch | No decline in Feed, Events, Wellness or Games usage |
| Application performance (V1 surfaces) | No measurable regression vs. pre-V2 baseline |
| Manager satisfaction with V2 | ≥ 4.2 / 5 |
| Reported discomfort with visibility/privacy | 0 incidents |

### 8.3 Measurement constraint

The cohort is small (~20 managers today; the architecture targets growth to ~100). Percentage metrics on a base of 20 are volatile — a single manager moves a metric by five points. All targets above must be read as **trends over three or more periods**, never as single-period pass/fail gates. Phase 2 must define the measurement window before any target is used as a release criterion.

---

## 9. Risk Assessment

### 9.1 Product risks

| Risk | Impact | Mitigation |
|---|---|---|
| Four features launching at once overwhelm a small cohort | High | Phase the *rollout* even though the *build* is unified; DNA is the last surface to reveal fully, so it already has content when first seen |
| Manager DNA becomes a de-facto competition through social comparison ("what does yours look like?") | High | No sharing feature, no export, no screenshot-friendly score; DNA reads as art, not as a scoreboard |
| Catalyst Quest becomes a chore checklist | High | Small quest count per day, no penalty for skipping, monthly reset, quests point at things the manager would enjoy anyway |
| Leadership Pulse coaching feels generic — the fastest way to lose credibility | High | Coaching must reference the *specific* option chosen; content quality gate before launch; measured explicitly in success criteria |
| Feature overlap confuses managers about where to go | Medium | Strict role separation: Quest = *what to do*, Pulse/Coffee = *doing it*, DNA = *what it became*. DNA never writes; Quest never invents |
| Coffee Roulette groups never actually meet | Medium | The photo is the only proof required; groups self-schedule; no calendar burden; completion celebrated, non-completion silent |

### 9.2 UX risks

| Risk | Impact | Mitigation |
|---|---|---|
| DNA animation is beautiful but unreadable — managers cannot tell what grew | High | Every visual change must be explainable in one sentence in-app; strand inspection view is mandatory, not optional |
| Notification volume rises with four new features | High | Notification budget defined in this phase (Section 6, principle 8) and enforced in Phase 2; V2 must not increase total notification volume beyond an agreed ceiling |
| Navigation bloat from four new destinations | Medium | V2 features attach to existing structure; no new top-level restructuring; entry points must be earned, not assumed |
| A faint DNA feels like a judgement on a new manager | Medium | Copy frames the faint state as "beginning", never "empty"; early growth is deliberately fast so the first week is visibly rewarding |
| Coffee Roulette social pressure on introverted managers | Medium | Silent opt-out, groups of 3–4 rather than pairs, no public non-completion signal |

### 9.3 Technical risks

| Risk | Impact | Mitigation |
|---|---|---|
| **No confirmed production scheduling mechanism.** Coffee Roulette rounds, monthly board generation, daily unlocks and weekly Golden Quests all depend on reliable scheduled execution. The V1 codebase contains scheduled functions, but the production trigger mechanism must be confirmed | **Critical** | **Phase 2 blocking item**: confirm and document the scheduling mechanism, its failure modes, its retry behaviour and its observability before any V2 scheduling design proceeds |
| DNA animation degrades performance or battery on the baseline device | High | Performance budget defined before design; measured on the baseline device; a static fallback rendering path must exist |
| A second AI provider (Groq) alongside the existing insights AI provider increases operational surface | Medium | Treat the coach as a bounded, replaceable dependency; define the failure behaviour (Section 3.1.5) so the product degrades gracefully rather than breaking |
| AI latency or outage makes Pulse feel broken | Medium | Answer is recorded and DNA grows regardless of AI availability; coaching arrives when available |
| DNA aggregation across seven data sources becomes a heavy read path | Medium | DNA is derived from recorded participation; the derivation strategy is a Phase 2/3 decision with an explicit performance requirement |
| Two features (Coffee Roulette, Quest) writing into the Feed and Notifications could regress V1 behaviour | High | V1 regression suite must pass unchanged; V2 uses existing content and notification models rather than modifying them |

### 9.4 Adoption risks

| Risk | Impact | Mitigation |
|---|---|---|
| Managers do not understand what Manager DNA *is* | High | One clear, short first-run explanation; DNA must be self-explanatory within 30 seconds of first view |
| Early Coffee Roulette rounds fail, poisoning the feature's reputation | High | Seed the first round deliberately (timing, framing, leadership participation); one successful round in the Feed makes the second round easy |
| Small cohort makes random matching repetitive within months | Medium | Repeat-avoidance window is a locked requirement, not an optimisation |
| Quest content feels irrelevant to senior managers | Medium | Quest Library curated with the cohort's actual context; library is content, so it can be improved without a release |

### 9.5 Operational risks

| Risk | Impact | Mitigation |
|---|---|---|
| Quest Library exhausts or repeats across months | Medium | Library sized well above 40 with category balance; admin can extend the library without an application release |
| Coffee Roulette photo content requires moderation | Medium | Reuse the V1 moderation model exactly; no new moderation surface, no new policy |
| AI coaching produces inappropriate or off-tone output | High | Bounded prompt design, constrained output shape, content review before launch, and a reporting path for bad output |
| Scheduled job silently fails and a month has no board | High | Observability and alerting on generation jobs is a Phase 2 requirement, not an afterthought |

### 9.6 Maintenance risks

| Risk | Impact | Mitigation |
|---|---|---|
| V2 growth logic becomes entangled with V1 features, making V1 changes risky | High | DNA reads participation; it never requires V1 features to know DNA exists |
| Four new surfaces double the UI maintenance burden | Medium | V2 reuses the existing design system; no parallel component library |
| Quest/DNA content and tuning require engineering time every month | Medium | Content lives in libraries and configuration, not in code |

### 9.7 Scope risks

| Risk | Impact | Mitigation |
|---|---|---|
| Scope creep — DNA sharing, Pulse leaderboards, quest trading, badges | **High** | Section 11 freezes scope; Section 12 lists the deferrals explicitly. Any addition requires a formal re-opening of Phase 1 |
| "Small" additions to V1 features smuggled in under V2 | High | Non-negotiable principle: V1 is untouched. Any V1 change must be justified as strictly required by a V2 feature and approved separately |
| Four flagship features is already an ambitious V2 | Medium | No fifth feature. Phases 2–12 optimise delivery of these four only |

---

## 10. Implementation Readiness

### 10.1 Phase 1 completion checklist

| Requirement | Status |
|---|---|
| All four flagship features fully defined (purpose, value, functionality, journeys, criteria) | ✅ |
| Feature relationships documented in both directions | ✅ |
| Non-interactions defined to prevent overlap | ✅ |
| Interaction with every existing V1 module documented | ✅ |
| Experience principles defined and binding | ✅ |
| Success metrics defined and measurable | ✅ |
| Risks identified across all seven categories with mitigations | ✅ |
| V2 scope frozen | ✅ |
| V3 deferrals listed explicitly | ✅ |
| No implementation decisions made (no schema, API, UI, or code) | ✅ |
| No repository modifications beyond this document | ✅ |
| V1 application untouched | ✅ |

### 10.2 Overlap analysis

No feature overlap exists. Each of the four features owns a distinct role in the loop:

- **Catalyst Quest** — decides *what a manager might do*.
- **Leadership Pulse** — is a *thing to do* that develops judgement.
- **Coffee Roulette** — is a *thing to do* that develops relationships.
- **Manager DNA** — records *what was done* and renders it.

Two features contribute to the Managers Feed (Coffee Roulette directly; Quest indirectly by prompting posts) — this is complementary, not overlapping.

### 10.3 Complexity check

No unnecessary complexity was introduced. Deliberate simplifications made in this phase:

- DNA has **no decay** — removes an entire class of scheduling, recomputation and user-anxiety complexity.
- DNA is **read-only** with respect to other features — removes bidirectional coupling.
- Quest **never invents new activity types** — removes a parallel activity system.
- Pulse is **single-answer, no re-answer** — removes revision state and answer-history complexity.
- Coffee Roulette does **no scheduling or calendar integration** — removes the hardest and least valuable part of a meeting feature.
- V1 historical participation is **not back-filled** into DNA — removes a migration and a fairness argument.

### 10.4 Open items for Phase 2 (planning inputs, not scope changes)

These are planning questions, not undefined scope. None of them changes what V2 is.

1. **Confirm the production scheduling mechanism** and its reliability guarantees. *(Blocking for Coffee Roulette and Catalyst Quest planning.)*
2. Define the notification volume ceiling for V2 and allocate it across the four features.
3. Define the DNA performance budget and the baseline device.
4. Size and categorise the Quest Library and Golden Quest Library.
5. Define the Coffee Roulette repeat-avoidance window length for the current cohort size.
6. Define the measurement window for all Section 8 metrics given the small cohort.
7. Confirm the AI coaching content-safety review process before launch.

### 10.5 Readiness verdict

The V2 product vision is complete, consistent and frozen. All four flagship features have full scope, defined boundaries, defined relationships, and defined success criteria. No implementation decisions have been taken. The V1 application is unmodified.

**Implementation planning (Phase 2) may safely begin,** with item 10.4.1 treated as the first blocking question to resolve.

---

## 11. Scope Definition — In Scope for Version 2

**Feature scope (complete and final):**

1. **Leadership Pulse** — scenario library, single-choice answering, AI Leadership Coach analysis (strengths / weaknesses / suggested improvement / leadership takeaway), private personal history, DNA contribution.
2. **Coffee Roulette** — automatic monthly group formation (3–4 managers) with repeat avoidance, invitations, opt-out, one group photo with optional caption, submission by any group member, Coffee Roulette History, automatic Managers Feed post, DNA contribution.
3. **Manager DNA** — a single private animated helix per manager, six strands, visual evolution from faint to vivid, strand inspection, DNA contribution from all V1 and V2 participation sources, no decay, no sharing.
4. **Catalyst Quest** — automatic monthly generation of a 6×6 board plus 4 additional quest cells (40 quests), Quest Library, 2 daily quest unlocks, weekly Golden Quest from the Golden Quest Library, Monthly Bingo, Perfect Catalyst Month, DNA contribution.

**Supporting scope:**

- Additive entry points to the four features within the existing navigation structure.
- New notification categories for V2 events, within the existing notification model and volume ceiling.
- Admin capability to manage Coffee Roulette rounds and quest/scenario content — with **no access** to private Pulse answers, coaching, or Manager DNA.
- Background generation jobs for Coffee Roulette rounds, monthly quest boards, daily unlocks and weekly Golden Quests, with observability.

**Explicitly preserved:**

- All V1 features, behaviours, data and performance characteristics.
- Existing authentication and navigation model.
- Existing database tables, changed only where strictly required by a V2 feature.

---

## 12. Out of Scope — Deferred to Version 3 or Later

| Deferred item | Reason for deferral |
|---|---|
| Sharing or exporting Manager DNA | Would recreate public comparison socially; needs its own privacy design |
| Team, department or cohort DNA | Aggregation creates a comparative artefact — a different product decision |
| DNA milestones as physical or organisational rewards | Introduces incentive distortion; V2 must first prove intrinsic motivation |
| Multi-turn conversational coaching in Leadership Pulse | Turns a two-minute interaction into an open-ended session; contradicts the short-interaction principle |
| Manager-authored or admin-authored custom Pulse scenarios | Content-quality and safety review burden not justified in V2 |
| Pulse answer analytics at cohort level | Requires a privacy model that guarantees non-identifiability at a cohort of 20 |
| Coffee Roulette calendar integration, scheduling, or venue booking | Highest complexity, lowest incremental value |
| Coffee Roulette video, multi-photo, or long-form write-ups | Raises the effort bar; one photo is deliberately the whole requirement |
| Cross-organisation or external-guest Coffee Roulette | Out of the product's trust boundary |
| Personalised per-manager quest boards | Fragments the shared cohort experience; revisit only if the cohort grows substantially |
| Quest rerolls, swaps, or trading | Adds economy mechanics to a feature deliberately kept simple |
| Quest streaks or penalties for missed days | Directly contradicts the stress-free and no-addictive-mechanics principles |
| Historical back-fill of V1 participation into DNA | Fairness and comprehension cost at launch |
| DNA decay or regression over time | Contradicts the no-decay principle |
| Any leaderboard, ranking, or public score for V2 features | Contradicts the no-public-competition principle |
| Web or desktop surfaces for V2 features | Platform scope unchanged for V2 |
| Localisation of V2 content | Follows the V1 language scope |

---

## 13. Scope Freeze Declaration

The Version 2 scope defined in Section 11 is **frozen** as of this document.

- No feature may be added to V2 without formally re-opening Phase 1.
- No item in Section 12 may be pulled forward without formally re-opening Phase 1.
- No V1 feature may be redesigned, removed, replaced or degraded under any V2 justification.
- Phases 2 through 12 exist to deliver exactly these four features, production-ready, internally tested, stable, and seamlessly integrated into the existing application.
