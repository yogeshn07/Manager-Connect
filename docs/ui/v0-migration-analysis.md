# V0 → Flutter Migration Analysis

## Repository Structure

```
manager-connect-ui/
├── app/
│   ├── globals.css          ← Design tokens (oklch colors, radii, animations)
│   ├── layout.tsx           ← Fonts: Plus Jakarta Sans (heading), Geist (body)
│   ├── page.tsx             ← Feed page (SpotlightRail → Composer → Posts)
│   └── post/[id]/page.tsx   ← Post detail page
├── components/
│   ├── mc/
│   │   ├── app-shell.tsx         ← AppShell + TopBar + BottomNav
│   │   ├── spotlight-rail.tsx    ← Stories/spotlight horizontal scroll
│   │   ├── composer.tsx          ← Create post composer card
│   │   ├── post-card.tsx         ← Feed post card (dispatches by type)
│   │   ├── post-header.tsx       ← Author row with verified badge + type pill
│   │   ├── engagement-bar.tsx    ← ReactionSummary + ActionRow
│   │   ├── poll-block.tsx        ← Interactive poll options with bar fill
│   │   ├── avatar-stack.tsx      ← Overlapping avatar circles
│   │   ├── event-card.tsx        ← Standalone event card (events page)
│   │   ├── detail-chrome.tsx     ← Detail header + CommentComposer
│   │   ├── post-detail-content.tsx ← Full post content (all types)
│   │   ├── comment-thread.tsx    ← Nested comment display
│   │   └── reaction-breakdown.tsx ← Reaction chips with counts
│   └── ui/
│       └── button.tsx            ← shadcn button (not used in feed)
└── lib/
    ├── feed-data.ts              ← Post types + demo data
    ├── events-data.ts            ← Event types + demo data
    └── utils.ts                  ← cn() utility
```

## Design System Extraction

### Colors (oklch → Flutter hex approximations)

| Token | oklch Value | Hex Approx | Flutter |
|-------|------------|------------|---------|
| background | oklch(0.975 0.005 220) | #F5F6F8 | Color(0xFFF5F6F8) |
| foreground | oklch(0.21 0.03 230) | #1A2332 | Color(0xFF1A2332) |
| card | oklch(1 0 0) | #FFFFFF | Colors.white |
| primary | oklch(0.46 0.08 195) | #1B6B6E | Color(0xFF1B6B6E) |
| primary-foreground | oklch(0.99 0.01 200) | #F5FFFD | Color(0xFFF5FFFD) |
| secondary | oklch(0.95 0.012 210) | #ECF0F3 | Color(0xFFECF0F3) |
| secondary-foreground | oklch(0.3 0.04 220) | #2D3A47 | Color(0xFF2D3A47) |
| muted | oklch(0.955 0.008 220) | #EEF1F4 | Color(0xFFEEF1F4) |
| muted-foreground | oklch(0.52 0.02 225) | #6B7A88 | Color(0xFF6B7A88) |
| accent (amber) | oklch(0.81 0.15 78) | #D4A034 | Color(0xFFD4A034) |
| accent-foreground | oklch(0.3 0.06 60) | #4A3218 | Color(0xFF4A3218) |
| destructive | oklch(0.6 0.22 25) | #D93636 | Color(0xFFD93636) |
| border | oklch(0.92 0.008 220) | #E2E6EA | Color(0xFFE2E6EA) |
| amber | oklch(0.81 0.15 78) | #D4A034 | Color(0xFFD4A034) |
| amber-foreground | oklch(0.34 0.07 62) | #5C3D12 | Color(0xFF5C3D12) |
| emerald | oklch(0.66 0.14 162) | #22956B | Color(0xFF22956B) |
| emerald-foreground | oklch(0.99 0.01 160) | #F5FFF8 | Color(0xFFF5FFF8) |
| indigo | oklch(0.52 0.16 268) | #5B4DC9 | Color(0xFF5B4DC9) |
| indigo-foreground | oklch(0.99 0.01 270) | #F5F4FF | Color(0xFFF5F4FF) |
| teal-soft | oklch(0.93 0.03 195) | #DDF0ED | Color(0xFFDDF0ED) |

### Typography

| Style | Font | Size | Weight |
|-------|------|------|--------|
| Heading (h1-h3) | Plus Jakarta Sans | 15-22px | 700-800 (extrabold/bold) |
| Body | Geist Sans | 13-15px | 400-500 |
| Caption | Geist Sans | 10-12.5px | 400-600 |
| Label/Pill | Geist Sans | 8-11px | 500-700 (uppercase) |

### Radii

| Token | Value |
|-------|-------|
| base radius | 22px (1.375rem) |
| card | 24px (rounded-3xl) |
| pill/button | 16px (rounded-2xl) |
| icon tile | 12px (rounded-xl) |
| full | 9999px (rounded-full) |

### Animations

| Name | Duration | Curve | Effect |
|------|----------|-------|--------|
| float-up | 500ms | cubic-bezier(0.22,1,0.36,1) | translateY(8px→0) + scale(0.96→1) |
| pop-in | 400ms | cubic-bezier(0.34,1.56,0.64,1) | scale(0.6→1.15→1) |
| shimmer | 3s linear | infinite | background-position sweep |
| pulse-ring | 2.4s ease-out | infinite | box-shadow ring expand |

## Component Mapping: React → Flutter

| React Component | Flutter Widget | Notes |
|----------------|----------------|-------|
| AppShell | (keep MainScaffold) | Phone-frame wrapper; use existing scaffold |
| TopBar | V0TopBar | Sparkles icon, blurred bg, notification dot |
| BottomNav | V0BottomNav | 5 tabs, center "Recognize" elevated button |
| SpotlightRail | V0SpotlightRail | Gradient ring for live, avatar images |
| Composer | V0Composer | Avatar + input pill + 4 quick-action grid |
| PostCard | V0PostCard | Dispatches to sub-content by type |
| PostHeader | V0PostHeader | Avatar, name, verified badge, type pill, time+globe |
| ReactionSummary | V0ReactionSummary | Overlapping colored reaction icons + counts |
| ActionRow | V0ActionRow | React/Comment/Repost/Send with active state |
| PollBlock | V0PollBlock | Animated bar fill on vote |
| AvatarStack | V0AvatarStack | Overlapping circular images |
| RecognitionContent | V0RecognitionContent | Gradient banner + card overlay |
| AchievementContent | V0AchievementContent | Metric card with emerald theme |
| EventContent | V0EventContent | Cover image + date badge + progress bar |
| DetailHeader | V0DetailHeader | Back arrow + "Post" + bookmark |
| CommentComposer | V0CommentComposer | Avatar + input + emoji/image + send |
| CommentThread | V0CommentThread | Nested comments with like/reply |
| ReactionBreakdown | V0ReactionBreakdown | Reaction chips grid |
| PostDetailContent | V0PostDetailContent | Full post variants for detail page |

## Migration Risks

1. **oklch colors**: Flutter doesn't support oklch natively. Must convert to hex/sRGB.
2. **Fonts**: V0 uses Plus Jakarta Sans (headings) + Geist (body). Must add to pubspec and bundle.
3. **color-mix()**: CSS function used for tinted backgrounds. Must compute equivalent Colors in Dart.
4. **backdrop-blur**: Flutter supports ImageFilter.blur but performance differs on web.
5. **Gradient overlays on images**: Need Stack + gradient Container positioned.
6. **Demo data vs real data**: V0 uses hardcoded demo data; Flutter currently uses FeedItem sealed class for demo + PostDto for real Supabase data. Keep both paths.

## Reusable Widget Inventory (new V0 design system)

### Core Design Tokens
- `V0Colors` — all oklch-derived hex constants
- `V0Typography` — Plus Jakarta Sans headings, Geist body
- `V0Spacing` — radius, padding values matching V0

### Feed Widgets (16 widgets)
- V0TopBar, V0BottomNav, V0SpotlightRail, V0Composer
- V0PostCard, V0PostHeader, V0ReactionSummary, V0ActionRow
- V0PollBlock, V0AvatarStack
- V0RecognitionContent, V0AchievementContent, V0EventContent
- V0DetailHeader, V0CommentComposer, V0CommentThread, V0ReactionBreakdown
