# Coding Standards

## Language and Framework

- **Language:** TypeScript (strict mode). No plain JavaScript files in the codebase.
- **Framework:** React Native via Expo SDK (latest stable).
- **Navigation:** Expo Router (file-based routing).
- **State Management:** Zustand for global state; React Query (TanStack Query) for server state and caching.
- **Styling:** StyleSheet API (React Native native). No third-party CSS-in-JS in V1.

---

## TypeScript Configuration

- `"strict": true` in `tsconfig.json`. No exceptions.
- No use of `any` type. Use `unknown` with narrowing or define proper types.
- All Supabase table types are auto-generated via `supabase gen types typescript` and imported from `src/types/database.ts`.
- All component props are explicitly typed with interfaces or type aliases.

---

## Project Structure

```
src/
├── app/                    # Expo Router file-based screens
│   ├── (auth)/             # Auth screens
│   └── (app)/              # Authenticated app screens
├── components/             # Shared UI components
│   ├── ui/                 # Primitive UI elements (Button, Avatar, Card)
│   └── modules/            # Feature-specific composite components
├── hooks/                  # Custom React hooks
├── stores/                 # Zustand stores (one file per domain)
├── services/               # Supabase query functions (one file per module)
├── utils/                  # Pure utility functions
├── types/                  # TypeScript types and interfaces
│   ├── database.ts         # Auto-generated Supabase types (do not edit manually)
│   └── app.ts              # Application-level type definitions
├── constants/              # App-wide constants (colors, sizes, routes)
└── assets/                 # Static assets (fonts, images)
```

---

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `ActivityCard.tsx` |
| Screens (Expo Router) | kebab-case | `activity/[id].tsx` |
| Hooks | camelCase prefixed with `use` | `useActivityList.ts` |
| Stores | camelCase suffixed with `Store` | `activityStore.ts` |
| Services | camelCase suffixed with `Service` | `activityService.ts` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_BIO_LENGTH` |
| Types/Interfaces | PascalCase | `ActivityRsvp`, `UserProfile` |
| CSS/Style objects | camelCase | `styles.containerView` |

---

## Component Rules

1. **One component per file.** No multi-export component files.
2. **Functional components only.** No class components.
3. **Props interface at the top of the file**, above the component definition.
4. **Destructure props** in the function signature, not inside the function body.
5. **No inline styles on JSX** unless it is a single, trivial value. Use `StyleSheet.create()`.
6. **Keys on lists** must be stable unique IDs, never array indices.
7. **Memoization:** Use `React.memo` only when there is a measured performance problem. Do not memo preemptively.

---

## Hooks Rules

- Custom hooks must start with `use`.
- Hooks must not be called conditionally.
- Data-fetching hooks use React Query (`useQuery`, `useMutation`).
- Side effects in hooks are wrapped in `useEffect` with proper dependency arrays.
- Avoid storing derived state in `useState` — compute it from source state.

---

## Service Layer Rules

- All Supabase calls live in `src/services/`, not in components or hooks.
- Service functions are plain async functions that return typed data or throw errors.
- Services handle Supabase error unpacking and throw normalized `AppError` objects.
- Components and hooks never import `supabase` client directly — they call service functions.

---

## Error Handling

- All async operations are wrapped in try/catch.
- User-facing errors show a toast with a friendly message.
- Developer-facing errors are console-logged in development, never in production.
- The global error boundary catches uncaught render errors and shows a fallback screen.
- Network errors trigger offline handling (read from cache; queue writes).

---

## State Management Rules (Zustand)

- One store per feature domain: `authStore`, `feedStore`, `activityStore`, etc.
- Stores hold only global state that multiple screens need. Local UI state stays in `useState`.
- Do not put Supabase calls inside store actions. Call the service, then update the store.
- Selectors are used to subscribe to specific slices, not the whole store.

---

## Code Quality Tools

| Tool | Purpose | Config |
|------|---------|--------|
| ESLint | Linting | `eslint-config-expo` + custom rules |
| Prettier | Formatting | 2-space indent, single quotes, 100 char line length |
| TypeScript | Type checking | `strict: true` |
| Husky | Pre-commit hooks | Runs lint and type-check before commit |
| lint-staged | Staged file linting | Only lints changed files |

All tools run automatically on commit via Husky. CI re-runs them to catch bypasses.

---

## Import Order

Enforce with ESLint `import/order` rule:
1. React and React Native
2. Expo libraries
3. Third-party libraries
4. Internal aliases (`@/components`, `@/services`)
5. Relative imports

---

## Comments and Documentation

- Code should be self-documenting. Comments explain *why*, not *what*.
- JSDoc on exported service functions and utility functions.
- No commented-out dead code. Delete it; git history preserves it.
- No `TODO` comments in production code. Open a ticket instead.
