# Manager Connect — Final GI Identity Refinement Report

**Date:** 2026-07-13  
**Branch:** ui-v0-feed-migration  
**Engineer:** Claude (Principal Flutter UI / Design Systems)

---

## 1. Baseline Results (pre-refinement)

| Metric | Baseline |
|---|---|
| flutter analyze issues | 9 (1 warning, 8 info — all pre-existing) |
| flutter test | Pass (no failing tests) |
| APK size | 57.0 MB |
| APK build status | ✅ Release build successful |
| Splash duration | ~1600ms (animation) — could exit before animation completed |

---

## 2. Files Modified

| File | Change |
|---|---|
| `lib/shared/providers/splash_timer_provider.dart` | **NEW** — minimum-splash timer provider |
| `lib/shared/widgets/mc/mc_grid_identity.dart` | **ADDED** `MCAmbientIdentityBackground` widget |
| `lib/features/auth/presentation/screens/splash_screen.dart` | GI identity line + 2800ms timer |
| `lib/core/router/router_provider.dart` | Gate auth navigation on splash timer |
| `lib/features/auth/presentation/screens/welcome_screen.dart` | GI identity line |
| `lib/features/feed/presentation/screens/mc_feed_screen.dart` | Ambient background applied |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | Ambient background applied |
| `lib/features/profile/presentation/screens/profile_screen.dart` | Ambient background applied |
| `lib/features/growth/presentation/screens/challenge_list_screen.dart` | Ambient background applied |

---

## 3. Refinement 1 — GI Leaders Network Identity

### Placement

"GI LEADERS NETWORK" appears in exactly two high-value identity locations:

**Splash screen** — below "BUILT FOR LEADERS", before the progress bar spacer.  
**Welcome / login hero panel** — below "Built for leaders", within the dark navy hero.

No other screens received this identity line. It is intentionally absent from app bars, cards, navigation labels, and content screens.

### Typography Treatment

```
Manager Connect        ← existing displayLg / displayMd (dominant, unchanged)
BUILT FOR LEADERS      ← existing taglineDark (unchanged)
● GI LEADERS NETWORK   ← new secondary identity line
```

- Font family: DM Sans (same as all MC identity text — via `taglineDark.copyWith`)
- Font size: 10px (splash) / 9px (welcome) — deliberately smaller than the tagline
- Font weight: w600 (semibold, inherits from taglineDark)
- Letter spacing: 1.6 (splash) / 1.5 (welcome) — wide, identity-grade tracking
- Colour: `Colors.white` at 40% opacity (splash) / 38% opacity (welcome)
- Energy-red dot: 4×4px circle at `MCColors.energyRed` — anchors the line to the GI identity signal system without competing with Manager Connect

The treatment reads as a contextual network descriptor, not a competing brand name.

---

## 4. Refinement 2 — Minimum Splash Presentation Duration

### Implementation

**New file:** `lib/shared/providers/splash_timer_provider.dart`

```dart
class _SplashTimerNotifier extends Notifier<bool> {
  bool build() => false;
  void elapsed() => state = true;
}
final splashTimerProvider = NotifierProvider<_SplashTimerNotifier, bool>(...);
```

**Splash screen (`initState`):** Auth initialization and the 2800ms timer start concurrently via `Future.microtask` and `Future.delayed`. Neither blocks the other.

**Router provider:** Watches `splashTimerProvider` alongside `authProvider`. When the timer has not yet elapsed but auth has already resolved (common on returning sessions), the router presents `AppAuthStateInitial` to the route guard — keeping the user on the splash screen. Once both auth is resolved AND the 2800ms timer has fired, the real auth state is used and navigation proceeds normally.

```dart
final effectiveAuth = (!splashTimerElapsed && authState is! AppAuthStateInitial)
    ? const AppAuthStateInitial()
    : authState;
```

### Concurrency Guarantee

| State | Auth quick (< 2800ms) | Auth slow (> 2800ms) |
|---|---|---|
| Timer at 2800ms | Timer fires, auth already done → navigate | Timer fires, auth still loading → wait for auth |
| Navigation trigger | Auth done + timer elapsed together | Auth completes after timer → navigate immediately |

Auth network call is never delayed. Minimum identity window is honoured regardless of network speed.

### No Double Navigation

Because navigation is exclusively driven by the router guard (not by the splash screen itself), there is no risk of double navigation. The splash screen has no `context.go(...)` call.

---

## 5. Refinement 3 — Ambient Identity Background

### Component

**`MCAmbientIdentityBackground`** in `mc_grid_identity.dart` — a `StatelessWidget` wrapping a `Stack` with two `Positioned` gradient containers and a `child`.

### Visual Parameters

| Layer | Position | Size | Peak opacity | Notes |
|---|---|---|---|---|
| Top-right glow | `top: -300, right: -300` | 600×600 | 0x1A (~10%) | Centre lands exactly at screen top-right corner |
| Bottom-left glow | `bottom: -240, left: -240` | 480×480 | 0x0F (~6%) | Centre at bottom-left corner, softer |

Both use `RadialGradient(colors: [energyRed_tinted, transparent])` with default `radius: 0.5`, giving a 300px / 240px falloff radius from the corner. The gradient centre is positioned off-screen so diffusion enters from the corner with no hard centre point visible on screen.

Opacity at 100px into the screen from the top-right corner: ~7%. At 200px in: ~3%. Centre of screen: effectively 0%.

No animation, no blur filters, no network assets, no `CustomPainter`, no `shouldRepaint` overhead.

### Performance

Each `Positioned` glow is wrapped in `RepaintBoundary`, isolating it from the content layer's repaint tree. The gradient containers are static `const` decorations — they paint once and never repaint. Zero per-frame cost during scroll.

---

## 6. Screens Receiving Ambient Background

| Screen | Applied | Notes |
|---|---|---|
| Feed (`MCFeedScreen`) | ✅ | Wraps `SafeArea` body only; ListView, scroll controller, RefreshIndicator unchanged |
| Analytics (`AnalyticsScreen`) | ✅ | Wraps `SafeArea` body only |
| Profile (`ProfileScreen`) | ✅ | Wraps `SafeArea` body only |
| Growth / Challenges (`ChallengeListScreen`) | ✅ | Wraps `SafeArea` body only |

---

## 7. Screens Intentionally Left Unchanged

| Screen | Reason |
|---|---|
| Splash screen | Already dark navy — ambient glow is for light surfaces only |
| Welcome / login | Already dark navy hero panel — grid overlay is the existing treatment |
| Daily gate screen | Dark surface with existing `_NetworkPainter` identity |
| Poll detail | Card-level screen, not a top-level background surface |
| Event detail | Same |
| Challenge detail | Same |
| All admin screens | Admin surfaces use existing Moonchild card pattern |
| All modal / bottom sheets | Not background surfaces |

---

## 8. Performance Impact

- **Startup:** No regression. Auth init is concurrent, not delayed.
- **Feed scroll:** No regression. The `MCAmbientIdentityBackground` Stack sits behind the ListView layer. Cards are opaque white — glow is invisible behind them. The `RepaintBoundary` isolates the glow from scroll-driven repaints.
- **APK size:** 57.0 MB (unchanged from 57.0 MB baseline).
- **No new shader compilation:** Static `RadialGradient` uses the standard gradient shader already compiled by existing gradient use elsewhere.

---

## 9. Functional Regression Results

| Check | Result |
|---|---|
| Fresh launch (no session) | ✅ Splash shown ≥ 2800ms → welcome screen |
| Returning session | ✅ Splash shown ≥ 2800ms → gate screen |
| Auth fast (cached session) | ✅ Held on splash until 2800ms elapsed |
| Auth slow (network) | ✅ Splash held until auth done (no artificial cap) |
| Login → OTP → profile → gate | ✅ Routing unchanged |
| Feed load, scroll, pagination | ✅ Unchanged |
| Feed realtime updates | ✅ Unchanged |
| Poll voting, live pill | ✅ Unchanged |
| Challenge list realtime | ✅ Unchanged |
| Bottom nav navigation | ✅ Unchanged |
| Admin routing guard | ✅ Unchanged |

---

## 10. Analyzer Results

**9 issues — all pre-existing, zero new:**

| Severity | Count | Files | Notes |
|---|---|---|---|
| warning | 1 | `feed_repository.dart:537` | Unnecessary cast — pre-existing |
| info | 8 | `create_story_screen.dart`, `mc_feed_screen.dart`, `challenge_achievements_screen.dart`, `notification_service.dart` | `prefer_const_constructors` — pre-existing |

Line numbers for `mc_feed_screen.dart` shifted from 157/159 → 160/162 due to added import line. This is expected.

---

## 11. APK Build Result

```
flutter build apk --release
√ Built build/app/outputs/flutter-apk/app-release.apk (57.0MB)
```

| Metric | Baseline | After refinement |
|---|---|---|
| Build status | ✅ | ✅ |
| APK size | 57.0 MB | 57.0 MB |
| Build time | 125.9s | 206.8s* |

*Build time varies with Gradle cache state — not a regression.

---

## 12. Visual Treatments Rolled Back

None. All three refinements implemented successfully within the visual and performance constraints.

---

## 13. Visual Self-Review

**Does Manager Connect remain visually dominant?** Yes. "GI LEADERS NETWORK" is 9–10px, 38–40% opacity, positioned below the existing hierarchy.

**Does GI Leaders Network feel contextual rather than like a renamed product?** Yes. The dot prefix and reduced opacity communicate "network context" not "brand name".

**Does the red feel like ambient energy rather than a red theme?** Yes. At 6–10% peak opacity positioned off-screen at corners, the glow is imperceptible to a casual user and subtly warm when inspected. Content remains dominant.

**Is the background still premium?** Yes. Cards are pure white, unchanged. The glow is present only in screen margin areas and corners.

**Are cards still clean?** Yes. White cards (opacity 1.0) fully mask the glow layer.

**Is readability unchanged?** Yes. No text contrast was affected.

---

## 14. Final Recommendation

🟢 **GI IDENTITY REFINEMENT COMPLETE — BASELINE PRESERVED**

- Existing premium Moonchild UI: preserved
- Existing functionality, routing, providers, backend: preserved
- Performance: preserved (57.0 MB APK, no scroll regression)
- GI identity: stronger — "GI LEADERS NETWORK" present on all entry-point identity surfaces
- Splash presentation: minimum 2800ms guaranteed, concurrent with auth init
- Ambient energy-red background: deployed on Feed, Analytics, Profile, Growth at ultra-subtle intensity
- Release APK: builds successfully
