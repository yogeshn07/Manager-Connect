# Manager Connect — Design System
> Version 1.0 · Phase 8 Approved · Production Ready

---

## 1. Colors

### 1.1 Brand Primary Ramp

| Token | Hex | Usage |
|---|---|---|
| `brand-900` | `#042C53` | Darkest text on brand surfaces |
| `brand-800` | `#0C447C` | Logo gem, hero banners, primary buttons, active nav dot |
| `brand-700` | `#185FA5` | Links, active chip fills, secondary CTAs, inset hero panels |
| `brand-400` | `#378ADD` | Mid-tone accent (charts, decorative) |
| `brand-200` | `#85B7EB` | Hero sub-labels, unread card borders |
| `brand-100` | `#B5D4F4` | Reaction cluster border, hero metadata text |
| `brand-50` | `#E6F1FB` | Active chip fill, unread card background tint, KPI icon tiles |
| `brand-whisper` | `#F5F9FF` | "You" row in leaderboards, featured comments, selected RSVP card bg |

### 1.2 Semantic Color Ramps

All ramps follow the same 7-stop convention: `50 → 100 → 200 → 400 → 600 → 800 → 900`

#### Teal (Success / Wellness / Confirmed)
| Token | Hex | Usage |
|---|---|---|
| `teal-50` | `#E1F5EE` | Wellness icon tile fill, confirmed card bg, achievement tile fill |
| `teal-100` | `#9FE1CB` | Wellness hero text, live step fills |
| `teal-400` | `#1D9E75` | Streak fills, done day pips, avatar bg option, wellness hero, confirmed CTA |
| `teal-600` | `#0F6E56` | Wellness module body text on teal-50 |
| `teal-800` | `#085041` | Wellness hero banner bg, deep confirmed state |
| `teal-border` | `#5DCAA5` | Teal icon tile border, platinum achievement border |

#### Amber (Recognition / Gold / Achievements)
| Token | Hex | Usage |
|---|---|---|
| `amber-50` | `#FAEEDA` | Recognition icon tile fill, gold badge bg, reward card bg |
| `amber-100` | `#FAC775` | Streak flame icon, logo gem accent in admin, hero score border |
| `amber-400` | `#BA7517` | Recognition stars, flame icon, gold-tier text, streak number |
| `amber-600` | `#854F0B` | Recognition pill text on amber-50 |
| `amber-800` | `#633806` | Darkest amber body text |
| `amber-border` | `#EF9F27` | Gold achievement tile border, recognition featured card border |

#### Coral (Sports / Events / Urgency)
| Token | Hex | Usage |
|---|---|---|
| `coral-50` | `#FAECE7` | Event type pill bg, sports category chip |
| `coral-400` | `#D85A30` | Coral mid |
| `coral-600` | `#993C1D` | Coral text on coral-50 |
| `coral-800` | `#712B13` | Sports event hero bg, badminton challenge strip |

#### Purple (Mindset / Mentions / Wellness Hub)
| Token | Hex | Usage |
|---|---|---|
| `purple-50` | `#EEEDFE` | Mindset chip bg, mention pill bg, meditation card bg |
| `purple-200` | `#AFA9EC` | Purple icon tile border |
| `purple-400` | `#7F77DD` | Purple mid |
| `purple-600` | `#534AB7` | Wellness hub hero, mention badge bg, meditation session icon |
| `purple-800` | `#3C3489` | Poll card banner bg, wellness hero bg, deep mindset |
| `purple-900` | `#26215C` | Darkest purple text |

#### Red (Urgent / Unread / Error)
| Token | Hex | Usage |
|---|---|---|
| `red-50` | `#FCEBEB` | Error card bg, missed day pip |
| `red-100` | `#F7C1C1` | Light red borders |
| `red-200` | `#F09595` | Urgent notification border, moderation card border |
| `red-400` | `#E24B4A` | Notification dot, LIVE pill bg, "seats remaining" urgency text |
| `red-600` | `#A32D2D` | Moderation hero bg, danger action text |
| `red-800` | `#791F1F` | Darkest red text |

#### Gray (Neutral / Structural)
| Token | Hex | Usage |
|---|---|---|
| `gray-50` | `#F1EFE8` | Silver achievement tile fill |
| `gray-100` | `#D3D1C7` | Inactive story ring bg |
| `gray-200` | `#B4B2A9` | Silver icon tile border, inactive status dot |
| `gray-400` | `#888780` | Mid-gray avatar bg for "you" / unassigned |
| `gray-600` | `#5F5E5A` | Secondary body text |
| `gray-800` | `#444441` | Deep secondary |
| `gray-900` | `#2C2C2A` | Primary text |

#### Green (Achievement / Unlocked)
| Token | Hex | Usage |
|---|---|---|
| `green-50` | `#EAF3DE` | Light achievement fill |
| `green-400` | `#639922` | Mid green |
| `green-600` | `#3B6D11` | Dark green text |

### 1.3 Background Colors

| Token | Hex | Usage |
|---|---|---|
| `bg-app` | `#F4F5F7` | Universal app background — all screens |
| `bg-card` | `#FFFFFF` | All card surfaces, bottom nav, top bar, composer |
| `bg-input` | `#F4F5F7` | Input fields, search bars, inactive chips |
| `bg-hero-primary` | `#0C447C` | Primary module hero banners |
| `bg-hero-wellness` | `#085041` | Wellness and nature module heroes |
| `bg-hero-challenge` | `#1D9E75` | Challenge confirmation heroes |
| `bg-hero-admin-mod` | `#A32D2D` | Moderation admin hero only |

### 1.4 Border Colors

| Token | Value | Usage |
|---|---|---|
| `border-default` | `0.5px solid rgba(0,0,0,0.10)` | All default card borders |
| `border-hover` | `0.5px solid rgba(0,0,0,0.20)` | Hover/focus state |
| `border-unread` | `0.5px solid #B5D4F4` | Unread notification cards |
| `border-celebrate` | `1px solid #EF9F27` | Recognition and achievement featured cards |
| `border-accent` | `1–1.5px [category-color]` | Category-accented tiles and achievement emblems |
| `border-stripe` | `3px solid #0C447C` | Left-stripe accent (Announcements, "You" rows, Inbox unread) |

### 1.5 Gradients

The product uses **no CSS gradients on surfaces**. All hero backgrounds are flat solid fills. The only gradient-adjacent effect is the story ring active state using a blue-to-blue range which may be implemented as a solid `#0C447C` ring (preferred) or a subtle linear gradient from `#0C447C` to `#185FA5` (acceptable alternative).

---

## 2. Typography

### 2.1 Font Families

```
--font-primary: var(--font-sans);        /* Anthropic Sans or Inter */
--font-editorial: var(--font-serif);     /* Serif — reserved use only */
--font-code: var(--font-mono);           /* Not used in UI */
```

**Rules:**
- `font-sans` is used for all UI text.
- `font-serif` is used **only** for: recognition quote blocks, wellness reflection prompts, monthly review hero headlines. Maximum 2 instances per screen.
- No bold (600/700) weights. Only 400 (regular) and 500 (medium).

### 2.2 Type Scale

| Level | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `display` | 22px | 500 | 1.3 | Screen-level title (Analytics hero, Review hero) |
| `h1` | 18–20px | 500 | 1.25–1.3 | Module hero titles, onboarding headings |
| `h2` | 16–17px | 500 | 1.3 | Feed hero greeting, streak hero |
| `h3` | 14–15px | 500 | 1.3–1.35 | Card section titles, post titles |
| `h4` | 13–14px | 500 | 1.35 | Card names, content titles |
| `body-lg` | 13px | 400 | 1.6–1.65 | Post body text, comment text, quote blocks |
| `body` | 12px | 400 | 1.55–1.6 | Standard card body, notification sub-text |
| `body-sm` | 11px | 400 | 1.45–1.5 | Secondary card content, event metadata |
| `caption` | 10–11px | 400 | 1.4 | Timestamps, role labels, metadata rows |
| `label` | 9–10px | 500 | 1.3 | Section headers (uppercase), card sub-labels |
| `pill` | 8–9px | 500 | 1.0 | Type pills, badges, category chips |
| `kpi` | 17–28px | 500 | 1.0 | KPI numbers, streak counts, health scores |
| `rank` | 36–42px | 500 | 1.0 | Streak hero number, rank highlight |

### 2.3 Typography Rules

1. **Uppercase** is used only for: section header labels, pill text, module eyebrow labels. Never for body content.
2. **Letter-spacing** on uppercase labels: `0.06–0.09em`.
3. **Minimum font size**: 9px for pill text, 10px for all body-facing text, 11px for any text requiring reading (not just recognition).
4. Enforce minimum 9px for all pill labels that convey status — 8px is acceptable only in admin-context dense tables.

---

## 3. Spacing System

### 3.1 Base Unit
All spacing derives from a **4px base unit**.

### 3.2 Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `space-1` | 4px | Micro gaps, icon-to-text |
| `space-2` | 8px | Internal component gaps |
| `space-3` | 12px | Card internal sections |
| `space-4` | 14–16px | Card padding (horizontal), section padding |
| `space-5` | 20px | Between card and next card |
| `space-6` | 24px | Section-to-section |
| `space-7` | 28–32px | Major section breaks |

### 3.3 Card Padding

| Context | Horizontal | Vertical |
|---|---|---|
| Standard card body | 13–14px | 11–13px |
| Hero banner | 16px | 16–20px |
| Stat strip cells | auto (flex) | 8–10px |
| Section header | 14px | 12–14px top, 6–8px bottom |
| Bottom nav | 0 | 8px top, 14px bottom |

### 3.4 List Spacing
- Between cards in a list: `margin-bottom: 7–10px`
- Between sections on a screen: `10–14px` padding-top on section header
- Horizontal page margins: `12–14px` (cards), `14–16px` (section headers)

---

## 4. Corner Radius

| Element | Radius | Notes |
|---|---|---|
| Cards (standard) | `13–14px` | Feed cards, notification cards, admin cards |
| Cards (featured/hero) | `16px` | Featured event card, recognition hero within card |
| Cards (small) | `11–12px` | Mini cards, rank highlight, activity timeline cards |
| Buttons (pill) | `20–22px` | Primary CTA, RSVP button, confirm button |
| Buttons (secondary) | `16–20px` | Secondary pill buttons, category chips |
| Icon tiles (large) | `10–11px` | 38–42px tiles |
| Icon tiles (medium) | `8–9px` | 28–34px tiles |
| Icon tiles (small) | `6–7px` | 22–26px tiles |
| Avatars | `50%` | All circular avatars, all sizes |
| Chips | `14–20px` | Filter chips, trending chips, type chips |
| Input fields | `18–22px` | Search bars, composer inputs |
| Badge pills | `5–8px` | Type badges, status chips |
| Calendar day pips | `6px` | Daily activity dots in streak calendar |
| Progress bar track | `2–4px` | All horizontal progress tracks |
| Progress bar fill | Same as track | Fill inherits track radius |

---

## 5. Elevation

### 5.1 Philosophy
**Manager Connect uses zero box shadows.** All visual depth is achieved through:

1. **Background contrast**: white card on `#F4F5F7` page background
2. **Border presence**: `0.5px solid` border at 10% black opacity
3. **Color differentiation**: hero banners use saturated brand colors that naturally recede from white cards above them

### 5.2 Visual Depth Rules

| Depth Level | Implementation | Example |
|---|---|---|
| Level 0 — Page | `#F4F5F7` background | App background |
| Level 1 — Card | White + `0.5px border-default` | All content cards |
| Level 2 — Accented card | White + `0.5px border-accent` (category color) | Featured comments, selected states |
| Level 3 — Celebration card | `#FFFBF4` + `1px border #EF9F27` | Recognition featured, achievement unlocked |
| Hero — Module | Solid brand color, full-width, no border | All module hero banners |

**Never add `box-shadow` to any element.** If a designer or developer wants "more depth," the answer is to increase border opacity or add a category accent border — not a shadow.

---

## 6. Icons

### 6.1 Icon Library
**Tabler Icons (outline variant only)** — `ti ti-[name]`

Never use filled variants (e.g. `ti-heart-filled` is not loaded and will render blank).

### 6.2 Icon Sizing

| Context | Size | Notes |
|---|---|---|
| Bottom nav | `21px` | All nav icons |
| Card body — inline | `13–14px` | Next to text labels |
| Action row | `14px` | Reaction, Comment, Repost, Share |
| Icon tile contents | `13–20px` | Proportional to tile size |
| Hero accent icons | `24–32px` | Decorative in card headers |
| Background icon (hero) | `64–110px` | Opacity 10–15%, decorative only |
| Notification badge overlay | `8–9px` | Inside 16–18px circular badge |
| Section header icon | `12px` | Left of section title |

### 6.3 Icon Rules

1. All decorative icons: `aria-hidden="true"`
2. All interactive icon-only elements: `aria-label="[action description]"`
3. Icons are always `color: currentColor` — color set on parent
4. Icons in icon tiles: always use the `800-stop` color from the tile's ramp
5. Nav active state: icon inherits `color: #0C447C`
6. Nav inactive state: icon inherits `color: var(--color-text-tertiary)`

---

## 7. Design Principles

### 7.1 Visual Philosophy

**1. Borders over shadows.** Depth is created through border contrast and background layering, never drop shadows. This creates a clean, flat-premium aesthetic consistent with Linear and Notion.

**2. Color encodes meaning, not decoration.** Every use of color maps to a semantic category:
- Blue = brand / informational / active
- Teal = success / wellness / confirmed
- Amber = recognition / gold / achievement
- Red = urgent / error / unread
- Purple = mindset / mentions / wellness hub
- Coral = sports / energy / events
- Gray = neutral / structural / inactive

Never use a color because it "looks good here." Color must carry meaning.

**3. Insights before data.** Every analytics or notification screen leads with a sentence (status), then the number (evidence). Never lead with a raw metric.

**4. No bold weights.** Hierarchy is achieved through size, color, and spacing — never by switching to 600 or 700 weight. Two weights only: 400 body, 500 medium.

**5. Zero gradients on surfaces.** All backgrounds are flat. Depth comes from contrast, not blending.

### 7.2 Interaction Philosophy

**1. State-aware actions.** The available actions shown to a user should reflect their current state. A manager who has joined a challenge sees "Log today" not "Join." An admin with a flagged user sees "Suspend" — a standard user does not.

**2. Social proof before CTA.** Show who else is participating (stacked avatars + names) before asking the user to act. This is applied consistently in: Event RSVP, Challenge join, Recognition detail, Notification detail.

**3. Progress is always visible.** Any ongoing activity (challenge, streak, event capacity) shows a progress indicator — bar, ring, or day-pip calendar. Users should always know where they stand without navigating away.

**4. Urgency is honest.** Red text and urgent labels are used only for genuinely time-sensitive information (seats remaining, invitation expiry, moderation queue age). Never use urgency language for promotional purposes.

**5. Celebration is proportional.** Achievement moments (badge unlock, streak milestone, recognition received) get elevated visual treatment. Routine events (new comment, leaderboard update) do not. The product should reserve its celebratory register for genuinely meaningful moments.
