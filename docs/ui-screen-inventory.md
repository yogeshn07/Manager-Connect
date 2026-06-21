# UI Screen Inventory

**Date:** 2026-06-21

---

## Summary

| Category | Screens | Modals/Sheets | Placeholders | Total UI |
|----------|---------|---------------|-------------|----------|
| Authentication | 4 | 0 | 0 | 4 |
| Community Feed | 2 | 1 | 0 | 3 |
| Activities | 2 | 1 | 0 | 3 |
| Polls | 1 | 1 | 0 | 2 |
| Recognition | 1 | 1 | 0 | 2 |
| Growth (Challenges) | 2 | 0 | 1 (Create Challenge) | 3 |
| Notifications | 1 | 0 | 0 | 1 |
| Analytics | 2 | 0 | 0 | 2 |
| Profile | 1 | 1 | 0 | 2 |
| Admin | 4 | 0 | 1 (Attendance) | 5 |
| **Total** | **20** | **5** | **2** | **27** |

---

## Screen Details

### Authentication (4 screens)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 1 | Splash | `/` | `splash_screen.dart` | Session check + auth initialization | App launch |
| 2 | Welcome / Login | `/welcome` | `welcome_screen.dart` | Email input, invite code validation, OTP send | Route guard redirect |
| 3 | Verify OTP | `/verify-otp` | `verify_otp_screen.dart` | 6-digit OTP entry + verification | Welcome screen push |
| 4 | Create Profile | `/create-profile` | `create_profile_screen.dart` | Name, title, bio, interest tags | Route guard redirect |

**Layout:** Full screen, centered content, no bottom nav.
**Key widgets:** TextField, FilledButton, FilterChip (interest tags).

---

### Community Feed (2 screens + 1 modal)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 5 | Feed | `/feed` | `feed_screen.dart` | Paginated post list, pinned post banner, realtime | Tab root (Feed) |
| 6 | Post Detail | `/post/:id` | `post_detail_screen.dart` | Post + reactions + comments + comment input | Feed card tap |
| 7 | Create Post | *modal* | `create_post_screen.dart` | Text input, character limit | Feed FAB |

**Layout:** Feed = ListView with PostCard items. Detail = post + reaction chips + comment list + input bar.
**Key widgets:** PostCard, ActionChip (reactions), ListTile (comments), RefreshIndicator.
**Realtime:** `feed:posts` channel — new posts prepended automatically.

---

### Activities (2 screens + 1 modal)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 8 | Activities List | `/events` | `activities_list_screen.dart` | Upcoming/past toggle, category filter | Tab root (Events) |
| 9 | Activity Detail | `/event/:id` | `activity_detail_screen.dart` | Info, RSVP buttons, attendees, updates | Activity card tap |
| 10 | Create Activity | *modal* | `create_activity_screen.dart` | Title, category, type, date, location | Events FAB |

**Layout:** List = filtered ListView with ActivityCard items. Detail = info rows + SegmentedButton RSVP + attendee list + update cards.
**Key widgets:** ActivityCard, SegmentedButton, DropdownMenu, FilterChip, ListTile.

---

### Polls (1 screen + 1 modal)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 11 | Poll Detail | `/poll/:id` | `poll_detail_screen.dart` | Question, vote options with progress bars, results | Activity detail or direct link |
| 12 | Create Poll | *modal* | `create_poll_screen.dart` | Question, dynamic options (2-10), closing date | Events context |

**Layout:** Detail = question + option tiles with FractionallySizedBox vote bars.
**Key widgets:** Material InkWell option tiles, LinearProgressIndicator-style bars.

---

### Recognition (1 screen + 1 modal)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 13 | Recognition Feed | *via Growth tab* | `recognition_feed_screen.dart` | Recognition wall with category badges | Growth app bar action |
| 14 | Create Recognition | *modal* | `create_recognition_screen.dart` | Category chips, member picker, message | Recognition FAB |

**Layout:** Feed = ListView of recognition cards. Create = category ChoiceChip + member FilterChips + TextField.
**Key widgets:** Card, Chip, ChoiceChip, FilterChip.

---

### Growth / Challenges (2 screens + 1 placeholder)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 15 | Challenge List | `/growth` | `challenge_list_screen.dart` | Active/completed challenges, Recognition nav | Tab root (Growth) |
| 16 | Challenge Detail | `/challenge/:id` | `challenge_detail_screen.dart` | Info, join/leave, leaderboard, log progress sheet | Challenge card tap |
| P1 | Create Challenge | *modal placeholder* | inline `_CreateChallengePlaceholder` | Coming soon | Growth FAB |

**Layout:** List = active/completed toggle with challenge cards. Detail = info + join button + leaderboard tiles + bottom sheet for progress.
**Key widgets:** Card, Chip, ListTile, BottomSheet (log progress).

---

### Notifications (1 screen)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 17 | Notification Center | `/notifications` | `notification_center_screen.dart` | Inbox, mark read, mark all read | App bar bell icon |

**Layout:** ListView of notification tiles with type icons, bold/normal read state.
**Key widgets:** ListTile, CircleAvatar (type icon), RefreshIndicator.
**Realtime:** `notifications:inbox:{userId}` channel — unread badge + inbox refresh.

---

### Analytics (2 screens)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 18 | Analytics | `/analytics` | `analytics_screen.dart` | Personal/community toggle, stats cards, health score | Tab root (Analytics) |
| 19 | Rankings | `/analytics/ranking` | `rankings_screen.dart` | Monthly/all-time leaderboard | Analytics screen button |

**Layout:** Analytics = SegmentedButton toggle + stat cards grid + health score card. Rankings = ranked list tiles.
**Key widgets:** SegmentedButton, Card, GridView, ListTile.

---

### Profile (1 screen + 1 modal)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 20 | Profile | `/profile` | `profile_screen.dart` | Avatar, info, interests, notification prefs, logout | Tab root (Profile) |
| 21 | Edit Profile | *modal* | `edit_profile_screen.dart` | Update name, title, bio, interest tags | Profile edit icon |

**Layout:** Profile = header + bio + interest chips + notification SwitchListTiles + logout button. Edit = form fields + FilterChips.
**Key widgets:** CircleAvatar, Chip, SwitchListTile, FilterChip, OutlinedButton.

---

### Admin (4 screens + 1 placeholder)

| # | Screen | Route | File | Purpose | Entry Point |
|---|--------|-------|------|---------|-------------|
| 22 | Admin Dashboard | `/admin` | `admin_dashboard_screen.dart` | System counts, navigation to sub-screens | App bar admin icon |
| 23 | Member Management | `/admin/members` | `member_management_screen.dart` | Member list, deactivate/reactivate | Dashboard nav |
| 24 | Invitation Management | `/admin/invitations` | `invitation_management_screen.dart` | Invitation list, send, revoke | Dashboard nav |
| 25 | Moderation Queue | `/admin/flagged` | `moderation_queue_screen.dart` | Pending flags, delete/dismiss | Dashboard nav |
| P2 | Record Attendance | `/admin/attendance` | `PlaceholderScreen` | Coming soon | Dashboard nav |

**Layout:** Dashboard = count cards + ListTile navigation. Sub-screens = action-oriented lists with confirmation dialogs.
**Key widgets:** Card, ListTile, AlertDialog, FilledButton.
**Protection:** Route guard blocks non-admin users, EFs enforce `requireAdmin()`.

---

## Reusable Widgets (7)

| Widget | File | Used By |
|--------|------|---------|
| `PostCard` | `feed/widgets/post_card.dart` | Feed, Post Detail |
| `ActivityCard` | `events/widgets/activity_card.dart` | Activities List |
| `MainScaffold` | `shared/widgets/bottom_nav/main_scaffold.dart` | All tab screens |
| `LoadingState` | `shared/widgets/loading_state.dart` | All async screens |
| `ErrorState` | `shared/widgets/error_state.dart` | All async screens |
| `Toast` | `shared/widgets/toast.dart` | All action screens |
| `PlaceholderScreen` | `shared/widgets/placeholders/placeholder_screen.dart` | Record Attendance |

---

## Route Definitions Not Wired (defined in RouteNames but unused)

| Route Constant | Reason |
|---------------|--------|
| `pollDetail` (`/event/:id/poll/:pollId`) | Router uses `/poll/:id` instead (polls have unique IDs) |
| `recognitionDetail` (`/recognition/:id`) | Recognitions viewed inline in feed, no detail route needed |
| `memberProfile` (`/profile/:id`) | Member profile merged into ProfileScreen (scope optimization) |
| `adminAnnouncements` (`/admin/announcements`) | Pin management merged into admin dashboard |
| `adminConnectBuddy` (`/admin/connect-buddy`) | Connect Buddy is fully automated |

---

## Placeholders Remaining (2)

| # | Location | Type | What's Missing |
|---|----------|------|---------------|
| P1 | Create Challenge | Inline `_CreateChallengePlaceholder` in `challenge_list_screen.dart` | Full create-challenge form (title, type, goal, dates) |
| P2 | Record Attendance | `PlaceholderScreen` at `/admin/attendance` | Batch attendance recording grid using `record-attendance` EF |

Both are functional gaps, not structural issues. The backend APIs exist (`POST /challenges` for create, `record-attendance` EF for attendance). The frontend screens need implementation.
