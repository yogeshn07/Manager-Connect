# UI Replication Plan

## 1. Design Token Mapping → Flutter

### Colors (from design-system.md)

| Design Token | Hex | Flutter Constant |
|---|---|---|
| `bg-app` | `#F4F5F7` | `McColors.bgApp` |
| `bg-card` | `#FFFFFF` | `McColors.bgCard` |
| `bg-input` | `#F4F5F7` | `McColors.bgInput` |
| `brand-800` | `#0C447C` | `McColors.brand800` |
| `brand-700` | `#185FA5` | `McColors.brand700` |
| `brand-400` | `#378ADD` | `McColors.brand400` |
| `brand-200` | `#85B7EB` | `McColors.brand200` |
| `brand-100` | `#B5D4F4` | `McColors.brand100` |
| `brand-50` | `#E6F1FB` | `McColors.brand50` |
| `brand-whisper` | `#F5F9FF` | `McColors.brandWhisper` |
| `teal-50` | `#E1F5EE` | `McColors.teal50` |
| `teal-400` | `#1D9E75` | `McColors.teal400` |
| `teal-800` | `#085041` | `McColors.teal800` |
| `teal-border` | `#5DCAA5` | `McColors.tealBorder` |
| `amber-50` | `#FAEEDA` | `McColors.amber50` |
| `amber-400` | `#BA7517` | `McColors.amber400` |
| `amber-800` | `#633806` | `McColors.amber800` |
| `amber-border` | `#EF9F27` | `McColors.amberBorder` |
| `coral-50` | `#FAECE7` | `McColors.coral50` |
| `coral-600` | `#993C1D` | `McColors.coral600` |
| `coral-800` | `#712B13` | `McColors.coral800` |
| `purple-50` | `#EEEDFE` | `McColors.purple50` |
| `purple-600` | `#534AB7` | `McColors.purple600` |
| `purple-800` | `#3C3489` | `McColors.purple800` |
| `red-50` | `#FCEBEB` | `McColors.red50` |
| `red-400` | `#E24B4A` | `McColors.red400` |
| `red-600` | `#A32D2D` | `McColors.red600` |
| `gray-100` | `#D3D1C7` | `McColors.gray100` |
| `gray-400` | `#888780` | `McColors.gray400` |
| `gray-600` | `#5F5E5A` | `McColors.gray600` |
| `gray-900` | `#2C2C2A` | `McColors.gray900` |
| `border-default` | `rgba(0,0,0,0.10)` | `McColors.borderDefault` |

### Typography Rules

- Font: Inter (sans-serif only, serif reserved for recognition quotes)
- Weight 400 (regular) and 500 (medium) ONLY — no bold/600/700
- Sizes per design-system.md type scale

### Spacing (4px base)

| Token | Value |
|---|---|
| `space-1` | 4px |
| `space-2` | 8px |
| `space-3` | 12px |
| `space-4` | 16px |
| `space-5` | 20px |
| `space-6` | 24px |
| `space-7` | 32px |

### Elevation: ZERO shadows. Border-only depth.

| Level | Implementation |
|---|---|
| L0 Page | `#F4F5F7` background |
| L1 Card | White + `0.5px border @ 10% black` |
| L2 Accented | White + category-colored border |
| L3 Celebration | `#FFFBF4` + `1px #EF9F27` border |

### Corner Radius

| Element | Radius |
|---|---|
| Standard card | 13-14px |
| Featured card | 16px |
| Small card | 11-12px |
| Pill button | 20-22px |
| Icon tile lg | 10-11px |
| Icon tile md | 8-9px |
| Avatar | 50% |
| Chip | 14-20px |

---

## 2. Component Build Order (22 components)

| # | Component | File | Priority |
|---|---|---|---|
| 1 | Design Tokens | `mc_colors.dart`, `mc_spacing.dart`, `mc_typography.dart` | Critical |
| 2 | Theme System | `mc_theme.dart` | Critical |
| 3 | McAvatar | `mc_avatar.dart` | Critical |
| 4 | McIconTile | `mc_icon_tile.dart` | Critical |
| 5 | McTypePill | `mc_type_pill.dart` | Critical |
| 6 | McTopBar | `mc_top_bar.dart` | Critical |
| 7 | McBottomNav | `mc_bottom_nav.dart` | Critical |
| 8 | McSectionHeader | `mc_section_header.dart` | High |
| 9 | McFilterChipStrip | `mc_filter_chip_strip.dart` | High |
| 10 | McProgressBar | `mc_progress_bar.dart` | High |
| 11 | McProgressRing | `mc_progress_ring.dart` | High |
| 12 | McActionRow | `mc_action_row.dart` | High |
| 13 | McHeroBanner | `mc_hero_banner.dart` | High |
| 14 | McSocialProofRow | `mc_social_proof_row.dart` | High |
| 15 | McEngagementCluster | `mc_engagement_cluster.dart` | High |
| 16 | McFeedPostCard | `mc_feed_post_card.dart` | High |
| 17 | McEventCard | `mc_event_card.dart` | Medium |
| 18 | McChallengeCard | `mc_challenge_card.dart` | Medium |
| 19 | McNotificationCard | `mc_notification_card.dart` | Medium |
| 20 | McLeaderboardRow | `mc_leaderboard_row.dart` | Medium |
| 21 | McAdminCard | `mc_admin_card.dart` | Low |
| 22 | McBottomSheet | `mc_bottom_sheet.dart` | Medium |

All components in: `frontend/lib/shared/widgets/mc/`

---

## 3. Screen Implementation Order

### Phase 1: Feed (highest visibility)

| Screen | Route | Components Used |
|---|---|---|
| Feed Home | `/feed` | TopBar(A), StoryRing, Composer, FeedPostCard(all 5 types), SectionHeader, ActionRow, EngagementCluster, SocialProofRow |
| Post Detail | `/feed/post/:id` | TopBar(B), FeedPostCard, ActionRow, Comment thread |

### Phase 2: Profile

| Screen | Route |
|---|---|
| My Profile | `/profile` |
| Recognition History | `/profile/recognitions` |
| Achievement Gallery | `/profile/achievements` |

### Phase 3: Events

| Screen | Route |
|---|---|
| Events Hub | `/events` |
| Event Detail | `/events/:id` |

### Phase 4: Challenges

| Screen | Route |
|---|---|
| Challenges Home | `/challenges` |
| Challenge Detail | `/challenges/:id` |

### Phase 5: Notifications + Analytics

| Screen | Route |
|---|---|
| Notification Center | `/notifications` |
| Analytics Home | `/analytics` |

### Phase 6: Admin

| Screen | Route |
|---|---|
| Admin Home | `/admin` |
| User Management | `/admin/users` |
| Moderation | `/admin/moderation` |

---

## 4. Riverpod Integration

Existing providers are KEPT. Only the presentation layer (widgets) is replaced.

| Provider | Used By |
|---|---|
| `feedProvider` | Feed Home |
| `postDetailProvider` | Post Detail |
| `activitiesProvider` | Events Hub |
| `activityDetailProvider` | Event Detail |
| `challengeListProvider` | Challenges Home |
| `challengeDetailProvider` | Challenge Detail |
| `notificationProvider` | Notification Center |
| `analyticsProvider` | Analytics Home |
| `rankingsProvider` | Rankings |
| `profileProvider` | My Profile |
| `adminDashboardProvider` | Admin Home |
| `memberManagementProvider` | User Management |
| `moderationProvider` | Moderation |

---

## 5. Navigation Mapping

### Bottom Nav (Member — icon-only, no labels)

| Tab | Icon | Route |
|---|---|---|
| Home | home outline | `/feed` |
| Events | calendar outline | `/events` |
| Challenges | trophy outline | `/challenges` |
| Notifications | bell outline | `/notifications` |
| Profile | user outline | `/profile` |

Active: icon `#0C447C` + 4px dot below
Inactive: icon tertiary gray, no dot
No text labels — icon + dot only

---

## 6. Critical Rules Checklist

- [ ] Zero box-shadow on any element
- [ ] font-weight 400 and 500 only
- [ ] App background `#F4F5F7` always
- [ ] Card background `#FFFFFF`
- [ ] Card radius 13-16px
- [ ] All avatars circular (50%)
- [ ] Border-based depth only: `0.5px solid rgba(0,0,0,0.10)`
- [ ] "You" row: `3px left border #0C447C` + `#F5F9FF` bg
- [ ] Icon tiles always have colored border (never flat fill alone)
- [ ] Serif font only for recognition quotes
- [ ] No gradients on surfaces
- [ ] Uppercase only for section labels and pills
- [ ] Letter-spacing 0.06-0.09em on uppercase text
