# Manager Connect (The Catalysts)

A private manager engagement platform for a closed community of managers within an organization.

Purpose:
- Strengthen manager relationships
- Organize activities and outings
- Encourage wellness and fitness
- Provide a private social community
- Increase participation and engagement

Target users: 15–20 managers (architecture supports growth to 100+)
Platform: Flutter mobile application (Android / iOS, web build supported)

## Status

- **V1** — production-ready, internal beta.
- **V2** — planning. Four flagship features: Leadership Pulse, Coffee Roulette, Manager DNA, Catalyst Quest. Phases 1–2 complete (product vision + system architecture).

## Repository structure

| Path | Contents |
|---|---|
| `frontend/` | Flutter app — feature-first Clean Architecture (`lib/features/<name>/{data,domain,presentation}`), Riverpod state management, `go_router` navigation, shared `mc_*` design system in `lib/shared/widgets/mc/` |
| `backend/supabase/` | Supabase project — 93 SQL migrations, 31 Edge Functions (`index.ts` transport + `use-case.ts` logic, shared code in `functions/_shared/`), storage and RLS policies |
| `docs/` | Architecture, database, API, design, deployment and audit documentation |
| `docs/v2/planning/` | Version 2 phase documents |
| `infrastructure/`, `scripts/`, `testing/` | Supporting tooling |

## Tech stack

- Flutter (Dart 3.9+), Riverpod, go_router, freezed, fpdart
- Supabase — PostgreSQL with row-level security, Auth (OTP), Realtime, Storage, Edge Functions (Deno)
- Firebase Cloud Messaging for push notifications
- OpenAI (Catalyst Insights enrichment pipeline)

## Running locally

Configuration is supplied at build time — **no credentials are committed to this repository**.

1. Copy the example config and fill in your values:

   ```bash
   cp frontend/env.example.json frontend/env.json
   ```

   `frontend/env.json` is gitignored.

2. Run the app:

   ```bash
   cd frontend
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```

   In VS Code, use the bundled **Manager Connect (device)** or **Manager Connect (Chrome)** launch configuration — both pass the file automatically.

3. CI and release builds pass the same keys individually via `--dart-define` (see `docs/deployment/cicd.md`).

## Tests

```bash
cd frontend
flutter test
```

## Documentation entry points

| Topic | Document |
|---|---|
| Product vision (V1) | `docs/product-vision.md` |
| Database schema | `docs/database-schema-design.md` |
| Backend architecture | `docs/backend-architecture.md` |
| Flutter architecture | `docs/flutter-architecture.md` |
| Design system | `docs/design-system.md` |
| Deployment | `docs/deployment/` |
| V2 product vision | `docs/v2/planning/v2_phase1_product_vision.md` |
| V2 system architecture | `docs/v2/planning/v2_phase2_system_architecture.md` |

## Related repositories

- UI design reference (Next.js): [yogeshn07/manager-connect-ui](https://github.com/yogeshn07/manager-connect-ui) — kept as a separate repository, not vendored here.
