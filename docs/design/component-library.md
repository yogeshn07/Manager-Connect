# Manager Connect — Component Library
> Version 1.0 · 28 components defined

All components use: `font-family: var(--font-sans)`, border-based depth (no shadows), and the semantic color system from `design-system.md`.

---

## 1. Bottom Navigation Bar

**Purpose:** Primary navigation between top-level modules.

**Variants:**
- Member nav (5 tabs): Home · Events · Challenges · Notifications · Profile
- Admin nav (5 tabs): Home · Users · Moderation · Events · Settings

**Anatomy:**
```
Height: auto (padding: 8px top, 14px bottom)
Background: #FFFFFF
Border: 0.5px solid border-default (top only)
Tab width: flex: 1 (equal)
Tab layout: flex column, center-aligned
Icon: 21px Tabler outline
Active dot: 4px circle, #0C447C, below icon
Active icon color: #0C447C
Inactive icon color: var(--color-text-tertiary)
No visible labels (icon + aria-label only)
```

**States:** Active (icon blue + dot visible), Inactive (tertiary gray, no dot)

**Usage rules:**
- Always present on all primary screens
- Never present on detail/modal screens
- Admin nav is completely separate from member nav — never render both

---

## 2. Top Bar

**Purpose:** Screen-level navigation header.

**Variants:**
- Type A — Logo + title (home screens): logo gem left, title, actions right
- Type B — Back + title (detail screens): back link left, title center, optional actions right
- Type C — Transparent (hero overlap): floating buttons over hero image (Events only)

**Anatomy (Type A):**
```
Height: auto (13px top, 11px bottom padding)
Background: #FFFFFF
Border: 0.5px solid border-default (bottom)
Logo gem: 33px, 9px radius, #0C447C bg, white icon 16px
App name: 14-15px / 500, var(--color-text-primary)
Sub-label: 10px / 400, var(--color-text-tertiary)
Right actions: flex row, gap 11-14px, icons 19-20px
```

**Anatomy (Type B — Back):**
```
Back link: left-aligned, 13px / 500, #185FA5, arrow icon 17px + parent name
Title: center or left, 14px / 500
Right action: margin-left: auto
```

**States:** Default only. No collapsed state.

---

## 3. Avatar

**Purpose:** User identity representation.

**Variants:** Initials-based (primary), Status-dot overlay, Badge overlay (notification badge), Crown overlay (leaderboard #1), Add overlay (story "you" tile)

**Size scale:**
```
xs:  16px — RSVP stack, stacked avatars in cards
sm:  20px — Attendee strips
md:  24px — Nested reply, inline mentions
lg:  28–30px — Comment header, story inner
xl:  32–34px — Leaderboard row, inbox item
2xl: 36–38px — Card post header, feed author
3xl: 42–44px — Recognition subject, featured attendee
4xl: 48–52px — Event organizer, Manager Profile sub-element
5xl: 56–70px — Profile hero, streak hero icon (circular)
```

**Colors:** Role-mapped, from the 6 non-gray ramp options (teal, blue, purple, coral, amber, pink-fuchsia). Fallback: `gray-400 (#888780)` for "You"/"anonymous".

**Status dot positions:** `bottom: 0; right: 0` of avatar wrapper
- Active: `#1D9E75` (teal)
- Inactive: `#B4B2A9` (gray)
- Warned: `#BA7517` (amber)
- Dot size: 9–10px with 2px white border

**Badge overlay positions:** `bottom: -2px; right: -2px`
- Badge size: 16–18px circle with 2px white border
- Category-colored fill with white icon

**Usage rules:**
- Always circular (`border-radius: 50%`)
- Never rectangular crop
- Never placeholder silhouette — always show initials
- Stacked avatars: `-4 to -6px margin-left`, `1.5px white border`

---

## 4. Type Pill / Badge

**Purpose:** Categorize content type, status, tier, or priority at a glance.

**Variants:**
- Content type (Recognition, Achievement, Poll, Event, Announcement)
- Status (Going, Interested, Active, Expiring, Confirmed, Locked)
- Tier (Gold, Silver, Platinum, Bronze)
- Priority (Urgent, Monitor, Record high, Trend)
- Admin (Active, Pending, Suspended, High, Medium)

**Anatomy:**
```
Font: 8–9px / 500
Text transform: uppercase
Letter spacing: 0.05–0.07em
Padding: 2px 7px
Border radius: 5–6px
Fill: [category]-50
Text color: [category]-800 (darkest readable stop on fill)
No border on standard pills
```

**States:** Default only. Pills do not change state — they represent a fixed classification.

**Usage rules:**
- Never use black text on colored pill fills — always use the ramp's darkest stop
- Pills must appear at the boundary between card sections (top-right of card header, adjacent to metadata)
- "Featured" pill on recognition cards: amber fill, 1px border (#EF9F27)
- Minimum 9px text — do not go to 8px except in admin dense contexts

---

## 5. Icon Tile

**Purpose:** Categorized visual anchor for list items, section headers, notification types, session types.

**Sizes:**
```
sm:  22–26px — Section header, dense admin rows
md:  28–32px — KPI card icon, quick action secondary
lg:  34–38px — Notification card icon, section leader
xl:  40–44px — Achievement emblem preview, organizer card
2xl: 52–56px — Achievement gallery emblem
```

**Anatomy:**
```
Shape: square, rounded corners proportional to size
  (sm: 6-7px, md: 7-8px, lg: 9px, xl: 10-11px, 2xl: 13-14px)
Fill: [category]-50
Border: 1–1.5px solid [category]-border stop
Icon: Tabler outline, proportional size (see design-system.md)
Icon color: [category]-800 (always — never 400 stop on icon tile icons)
```

**States:** Default, Locked (gray-50 fill, dashed border, reduced opacity 50%)

**Usage rules:**
- Never use flat fill without the 1px category border
- In-progress achievements use 1.5px dashed border
- Icon tiles NEVER have shadows

---

## 6. Feed Post Card

**Purpose:** Core content unit — all community posts.

**Variants (5):**
1. Recognition post
2. Achievement post
3. Poll post
4. Event post
5. Announcement post

**Shared anatomy:**
```
Background: #FFFFFF
Border: 0.5px border-default
Border radius: 14–16px
Margin: 0 12px, margin-bottom: 9–10px
Overflow: hidden (for banner header)
```

**Recognition post specific:**
- Banner header: `#0C447C` bg, trophy icon amber, "Leader of the month" label
- Recognition subject box: `#F4F5F7` inset, 44px avatar, name 16px, role 10px, 5 amber stars
- Post body: 12-13px / 400 body text
- Social proof row: stacked avatars + "Name, Name and N others reacted"
- Engagement row: reaction cluster + comment/repost counts
- Action row: 4-button row (React, Comment, Repost, Share)

**Achievement post specific:**
- Banner: `#085041` teal bg, rocket icon
- Metric pills: 3-cell row, teal-50 fill, big number + small label
- Same action row

**Poll post specific:**
- Banner: `#3C3489` purple bg
- Poll question: 14px / 500
- Option rows: relative-width fill bars, crown on leader option
- Footer: vote count + time remaining
- Same action row

**Event post specific:**
- Hero image strip: 100–110px tall, brand-family color, date badge top-left, title bottom
- Below: organizer row, calendar + location meta, RSVP button
- Same action row

**Announcement post specific:**
- No banner — left-border stripe: 3px solid `#0C447C`
- "Org update" uppercase label
- Title, body, "Read full announcement →" link
- Same action row

---

## 7. Action Row

**Purpose:** Post-level engagement actions — React, Comment, Repost, Share.

**Anatomy:**
```
Height: flex row, 10px vertical padding per button
Border top: 0.5px solid border-default
4 items: flex:1 each
Inter-item dividers: 0.5px solid border-default (left border on non-first items)
Font: 10px / 500, var(--color-text-secondary)
Icon: 14px, left of label, gap: 4px
```

**States:**
- Default: secondary text + tertiary icon
- Reacted/active: `#185FA5` text (brand blue)
- Disabled: not applicable (actions always available)

**Usage rules:**
- Appears on ALL feed card types
- Appears on Post Detail (same spec)
- Never appears in admin views (admins don't engage with content as participants)

---

## 8. Engagement Cluster

**Purpose:** Visual representation of reaction count with stacked category icons.

**Anatomy:**
```
3 reaction circles: 20–22px diameter
  - Overlap: margin-left: -4 to -5px
  - Border: 2px white
  - Fill: [category]-50 of each reaction type
  - Icon: 10–11px, [category]-600
Circle order (left to right): sparkle, trophy, flame
Count text: 11px / 500, var(--color-text-primary)
Label text: 10px / 400, var(--color-text-tertiary)
Gap between circles and count: 5–6px
```

**States:** Shows top 3 reaction types. If only 1 type, show 1 circle.

**Usage rules:**
- Used on: Feed cards, Post Detail engagement bar, Notification cards, Digest items
- Always paired with count number
- Minimum 1 circle shown (never show 0-circle empty state in this component — use "0 reactions" text instead)

---

## 9. Social Proof Row

**Purpose:** "Who else is participating" — names the people reacting/attending before a CTA.

**Anatomy:**
```
Stacked avatar strip: max 4 avatars, 20px each, 1.5px white border, -4px overlap
Text: 11px / 400
Pattern: "[Name], [Name] and N others [verb]"
Bold names: 500 weight on the 2 named people
Container: flex row, gap: 6–8px, padding: 9–10px, border-radius: 10px, bg: #F4F5F7
```

**Usage contexts:**
- Feed recognition card (before engagement row)
- Notification recognition detail (before action buttons)
- RSVP screen (colleague context)
- Event Detail (attendee momentum context)

**Rules:**
- Always show 2 named people maximum in text (even if more avatars shown)
- Never show more than 4 avatar circles
- Verb changes by context: "reacted to this" / "celebrated this" / "are going"

---

## 10. Story Ring

**Purpose:** Community presence strip — active/live status of colleagues.

**Anatomy:**
```
Outer ring: 52px, border-radius: 50%
Ring width: ~2.5px padding (as colored wrapper)
Inner circle: width/height 100%, border-radius: 50%, border: 2.5px white
Avatar initials: 12px / 500, white
States:
  - None: gray-100 ring (#D3D1C7)
  - New post: brand-800 ring (#0C447C)
  - Live: red-600 ring (#A32D2D)
  - You (add): gray ring + plus badge overlay
Name label: 10px, var(--color-text-secondary), below ring, max-width: 52px
```

**LIVE pill:**
```
Position: absolute, bottom: -3px, left: 50%, translateX(-50%)
Background: #E24B4A
Font: 9px / 500, white, uppercase
Padding: 1px 5px, border-radius: 4px
Border: 1.5px solid #F4F5F7 (against ring/background)
```

**ACCESSIBILITY FIX REQUIRED:** Increase LIVE pill text to 9px minimum and ensure contrast ≥ 4.5:1 on the red background.

---

## 11. Composer

**Purpose:** Post creation entry point.

**Anatomy:**
```
Container: White card, 14px radius, 0.5px border, 11–13px padding
Row 1: User avatar (36px) + text input pill
Input: flex:1, #F4F5F7 bg, 22px radius, 8–9px padding, 12–13px placeholder text
Row 2 (below divider): 4 action buttons
Action icons: colored 32px tiles (9px radius), 9px label below
  Update: blue-50, speakerphone icon, blue-700 text
  Recognize: amber-50, award icon, amber-800 text
  Poll: purple-50, chart-bar icon, purple-800 text
  Event: coral-50, calendar-event icon, coral-600 text
```

---

## 12. Section Header

**Purpose:** Module-level content groupings.

**Anatomy:**
```
Container: flex row, align-items: center, justify-content: space-between
Padding: 12–14px top, 6–8px bottom, 14px horizontal
Left: flex row, gap: 5px
  Icon: 12px Tabler, [category] color
  Label: 11px / 500, var(--color-text-secondary), uppercase, letter-spacing: 0.07em
Right: "See all" or "Recent" — 11px / 500, #185FA5
```

---

## 13. Filter / Category Chip Strip

**Purpose:** Horizontal scrollable filter row.

**Anatomy:**
```
Container: white bg, 9–10px vertical padding, 14px left padding, flex row, gap: 6–8px
Overflow: scroll horizontal, scrollbar hidden
Chip:
  Padding: 5–6px 10–12px
  Border-radius: 14–20px
  Font: 10–11px / 500
  Default: 0.5px border-secondary, secondary text, white or bg-app fill
  Active: #0C447C fill, white text, brand border
  Category variants: sport (coral), wellness (teal), mindset (purple)
  Icon optional: 12–13px left of label
```

---

## 14. KPI Card

**Purpose:** Analytics and admin metric display.

**Anatomy:**
```
Container: white card, 12px radius, 0.5px border, 11–12px padding
Icon tile: 28–30px, 7–8px radius, category fill + border (top of card)
Number: 20–24px / 500, var(--color-text-primary)
Label: 10px / 400, var(--color-text-tertiary)
Delta row: 9–10px / 400, flex row, gap: 2–3px
  Up: trending-up icon + teal-400 text
  Down: trending-down icon + red-400 text
  Stable: minus icon + tertiary text
Bar track: 3px height, #F4F5F7, 2px radius, margin-top: 6px
Bar fill: category color, same radius
```

**Grid:** Always 2-column. `grid-template-columns: repeat(2, minmax(0, 1fr))`, `gap: 7–8px`

---

## 15. Leaderboard Row

**Purpose:** Ranked participant display in challenges and analytics.

**Anatomy:**
```
Container: flex row, 9px padding vertical, 14px horizontal, border-bottom: 0.5px
Rank: 24px width, center, 13px / 500
  Gold (#1): #BA7517
  Silver (#2): #5F5E5A
  Bronze (#3): #712B13
  Other: var(--color-text-secondary)
Avatar: 32px circle
Name: 12px / 500
Role: 9px / 400, tertiary
Right: score 11px / 500, delta below (9px, flex row)
Trophy emoji: 14px, next to rank for top 3 (optional)

"You" row:
  border-left: 3px solid #0C447C
  background: #F5F9FF
  rank color: #0C447C, font-weight: 500
  role replaced with: "↑ Up N positions" in #185FA5
```

---

## 16. Event Card (Hub/Feed)

**Purpose:** Event discovery card with date, capacity, and RSVP affordance.

**Variants:**
- Featured card (horizontal scroll, 220×180px)
- List card (full-width, horizontal strip+body layout)

**Featured card anatomy:**
```
Image strip: 110–120px, solid brand-family color, icon bg 15% opacity
Date badge: white pill, top-left, month 8px red, day 16px primary
Status pill: top-right (Selling fast / Ends soon / New)
Title: 13px / 500, white, bottom of strip
Body: venue + time meta, attendee stack, going count, seats-left urgency
```

**List card anatomy:**
```
Strip: 76–80px wide, event color, icon + date corner badge
Body: type pill, title 13px, meta row (venue + time), footer (attendees + RSVP link)
```

---

## 17. Challenge Card

**Purpose:** Challenge discovery and status in Challenges Home.

**Variants:**
- Featured (horizontal scroll, ~200px wide)
- List (full-width, strip+body)

**List card anatomy:**
```
Strip: 72px, challenge color, icon
Body: type pill, title, meta row (streak/participants), footer
Footer: progress bar (4px) + progress text + action (Log today / Join / Joined chip)
```

**Progress bar color logic:**
- On track / healthy: teal (#1D9E75)
- Ending soon: amber (#BA7517)
- Admin health view only: red for below-threshold

---

## 18. Recognition Card (History)

**Purpose:** Collectible award card in Recognition History.

**Anatomy:**
```
Container: white card, 14–15px radius, category-colored border (1px)
Top section: padding 12px 13px, flex row
  Icon tile: 46px, category fill + 2px category border
  Category label: 9px / 500, uppercase, category text color
  Title: 13px / 500, primary
  Date: 10px, tertiary
  "Featured" pill (optional): amber
Quote section: padding 11px 13px, border-bottom
  Left border: 3px solid border-default
  Text: 12–13px / 400, serif font, secondary color
  Highlighted phrases: #185FA5, sans-serif, 500
Footer: padding 9px 13px, flex row, justify: space-between
  Giver: 26px avatar + "Recognized by" label (9px) + name (11px / 500)
  Share: 11px / 500, #185FA5, share icon 13px
```

---

## 19. Progress Ring

**Purpose:** Challenge completion visualization.

**Sizes:**
- `sm` (54px): Used in notification/challenge update cards
- `lg` (130px): Used in Challenge Detail as primary visualization

**Anatomy:**
```
SVG viewBox: [size] × [size]
Background circle: stroke #F4F5F7, stroke-width 7 (sm) or 14 (lg), fill none
Fill circle: stroke #1D9E75, same width, stroke-linecap: round
  stroke-dasharray: circumference = 2π × radius
  stroke-dashoffset: circumference × (1 - percentage)
  transform: rotate(-90deg) from center (start from top)
Center text (absolute overlay):
  Percentage: 13px / 500 (sm) or 26px / 500 (lg)
  Label: 9–10px / 400, tertiary, margin-top: 1px
```

---

## 20. Day-Pip Calendar

**Purpose:** Daily activity visualization in challenges and streak center.

**Variants:**
- Horizontal strip (10 days, in Challenge Detail card)
- Full monthly grid (7×5, in Streak Center)

**States:**
```
Done (past, completed): bg #E1F5EE, border #5DCAA5, check icon, text #085041
Today (current): bg #0C447C, white text, optional flame icon
Missed (past, not completed): bg #FCEBEB, border #F09595, × icon, text #A32D2D
Future (upcoming): bg #F4F5F7, border-default, — text, tertiary
Fire day (notable streak day): bg #1D9E75, white, filled
```

**Strip dimensions:** 26×26px pips, border-radius: 6px, gap: 3–4px
**Grid dimensions:** Same pip size, `grid-template-columns: repeat(7, 1fr)`, gap: 3px

---

## 21. Milestone Dot Row

**Purpose:** Challenge journey checkpoints (Week 1 → Week 2 → Week 3 → Week 4 → Complete).

**Anatomy:**
```
Container: flex row, gap: 0
Items: alternating dot + line
Dot: 28px circle
  Done: #FAEEDA bg, #EF9F27 border, check icon, amber
  Current: #FAEEDA bg, amber border, flame icon
  Next: #F4F5F7 bg, border-default, lock icon, tertiary
Line: flex:1, height: 1.5px
  Done-done: #EF9F27
  Any-next: var(--color-border-tertiary)
Labels: 8–9px, centered below each dot
```

---

## 22. Notification Card

**Purpose:** Single notification item in Notification Center and Activity Inbox.

**States:**
- Unread: `#F9FCFF` bg, `#B5D4F4` border, 7px cobalt dot top-right
- Celebration (recognition/achievement): `#FFFBF4` bg, `#EF9F27` border
- Milestone (streak): `#F4FCF9` bg, `#5DCAA5` border
- Read/default: white bg, border-default

**Anatomy:**
```
Container: white card, 13px radius, 0.5px border, 11px padding, flex row, gap: 10px
Icon wrap: avatar (38px) + badge overlay (18px, -2px bottom-right, 2px white border)
OR: solo icon circle (38px) for system notifications
Body: flex:1
  Title: 12px / 500, primary, line-height: 1.4
  Sub: 11px / 400, secondary
  Preview (optional): #F4F5F7 bg, 8px radius, 7–8px padding, italic 11px serif
  Meta row: time (10px tertiary) + pill + action link (10px / 500 blue)
Unread dot: 7px circle, #0C447C, absolute top: 14px right: 13px
```

---

## 23. Admin Action Card

**Purpose:** Priority item requiring admin attention.

**Anatomy:**
```
Same base as notification card + left-stripe variants:
  Urgent: 3px solid #E24B4A + #FEFAF9 bg + red icon tile
  Warning: 3px solid #BA7517 + #FFFBF4 bg + amber icon tile
  Info: 3px solid #185FA5 + white bg + blue icon tile
  Teal: 3px solid #1D9E75 + bg unchanged + teal icon tile
```

---

## 24. Moderation Card

**Purpose:** Reported content review card.

**Anatomy:**
```
Container: white card + optional red border on "high" priority
Top: author avatar (32px) + name + meta + priority pill
Preview: #FEFAF9 bg, 11px italic, border-bottom
Report info: red flag icon + reporter count text, border-bottom
Action row: 3 columns (Keep post / Warn user / Remove)
  Keep: teal text
  Warn: amber text
  Remove: red text
  Dividers: 0.5px between columns
```

---

## 25. Bottom Sheet / Modal

**Purpose:** Confirmation overlays, action sheets, contextual menus.

**Anatomy:**
```
Backdrop: rgba(0,0,0,0.45) full-screen overlay
Sheet: white bg, top border-radius: 20px (top corners only), bottom: 0
Handle: 4×32px gray-200 pill, centered, 8px from top
Content: padding 16–20px
```

**Instances in product:**
- RSVP confirmation (Confirm — I'm going)
- Moderation remove confirmation
- User management inline status expansion
- Challenge nudge compose sheet
- Session type selector (Wellness)

---

## 26. Hero Banner

**Purpose:** Full-width module context anchor.

**Variants:**
- Primary blue (`#0C447C`) — Feed, Profile, Analytics
- Teal (`#085041`) — Wellness, Events (cricket/nature)
- Challenge green (`#1D9E75`) — Active challenge confirmation
- Monthly event (`#712B13`) — Cricket/sports monthly challenge
- Admin moderation (`#A32D2D`) — Moderation queue only
- Wellness hub (`#3C3489`) — Deep purple, wellness mindset

**Anatomy:**
```
Width: 100%
Padding: 14–20px horizontal, 16–20px top, 18–22px bottom
No border, no radius (full bleed)
Background icon (optional): 64–110px, Tabler icon, opacity: 10–15%
All text: white or ramp-100 for sub-labels
Stat strip (when included): slightly lighter bg panel, rounded, stat cells
```

---

## 27. Streak Hero

**Purpose:** Streak Center screen's primary identity block.

**Anatomy:**
```
Background: #0C447C (blue hero)
Flame circle: 64px circle, #185FA5 bg, flame icon 30px, #FAC775 (amber)
Number: 42px / 500, white
Label: 13px / 400, #B5D4F4
Stat badges: 3-cell flex row, #185FA5 bg, rounded 10px
  Number: 15px / 500, white
  Label: 9px, #85B7EB
```

---

## 28. Bar Chart (Simple)

**Purpose:** Engagement and analytics trend visualization.

**Anatomy:**
```
Container: flex row, align-items: flex-end, height: 50–60px, gap: 4–5px
Column: flex:1, flex column, align-items: center, gap: 3px
Bar: width 100%, border-radius: 3px 3px 0 0, min-height: 4px
Label: 8px, var(--color-text-tertiary)
Colors:
  Current month/highlighted: #185FA5
  Previous periods: #1D9E75 (teal) for comparison lines
  Inactive/no data: #D3D1C7 (gray-100)
Legend: flex row, gap: 10px, 9px text, 8px dot circles
```

**Multi-bar variant (Executive Summary):**
```
Groups: 4 bars per period, gap: 2px within group, gap: 4px between groups
Colors: blue, teal, amber, purple (one per metric, consistent)
```
