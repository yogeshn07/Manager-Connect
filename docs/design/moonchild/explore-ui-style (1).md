# Manager Connect — UI Style Guide

## Overall impression

Manager Connect is a mobile-first social and productivity platform for people managers. The aesthetic is polished and gamified — rich dark hero gradients anchor key screens while clean white cards carry functional content. The design communicates aspiration and momentum: leaderboards glow with gold, challenge cards pulse with progress bars, and profile heroes unfold like a LinkedIn-meets-fitness-app hybrid. There is genuine warmth here (celebration emojis, recognition walls, streaks) balanced against data-dense information hierarchies. The overall mood is confident and energetic without feeling aggressive — a product that wants managers to feel like winners.

---

## Color

### Palette

| Role | Hex | Usage |
|---|---|---|
| **Primary / brand** | `#c5ff55` (lime 400) | Sidebar active state, toggle on, checkbox, tab indicator |
| **Deep blue** | `#1a2d5a` | Page hero backgrounds, event cards, leaderboard podium |
| **Blue mid** | `#2a4a8f` / `#3b5fd4` | Hero gradients, section heading icons |
| **Blue action** | `#2563eb` / `#1C6DFF` | Primary buttons, RSVP, leaderboard active nav, links |
| **Blue info subtle** | `#eff6ff` / `#dbeafe` | Unread notification tint, tag backgrounds |
| **Emerald / success** | `#10b981` / `#059669` | Challenge CTAs, launch buttons, streak banners, progress fills |
| **Emerald subtle** | `#ecfdf5` / `#d1fae5` | Success chips, completed-check backgrounds |
| **Amber / warning** | `#f59e0b` / `#fbbf24` | Prize badges, XP bars, recognition gold, streak icons |
| **Amber subtle** | `#fffbeb` / `#fef3c7` | Recognition card backgrounds, achievement highlight |
| **Purple accent** | `#8b5cf6` / `#7c3aed` | Mention tags, mindset chips, category icons |
| **Red / error** | `#ef4444` / `#dc2626` | Danger states, notification badge |
| **Neutral-900** | `#1a1a18` | Primary text, headings |
| **Neutral-700** | `#434340` | Secondary strong text |
| **Neutral-500** | `#7c7c72` | Muted/label text |
| **Neutral-400** | `#a8a89e` | Disabled, placeholder text |
| **Neutral-200** | `#e8e8e2` | Default borders |
| **Neutral-150** | `#efefea` | Subtle borders, dividers |
| **Neutral-100** | `#f5f5f0` | Nested surface, chips |
| **White** | `#ffffff` | Card surface |
| **Page background** | `#f0f2f5` / `#F2F2F7` | Screen background |

**Hero/gradient surfaces** combine multiple blue or green stops (e.g., `linear-gradient(135deg, #1a2d5a, #3b5fd4)` for events; `linear-gradient(135deg, #059669, #10b981, #34d399)` for challenge CTAs). Gold/amber accent gradients (`#FFD700 → #FFA500`) mark the #1 leaderboard position.

---

## Typography

### Typefaces
- **Primary sans-serif:** `General Sans` (weights 400, 500, 600, 700) — used throughout all non-Challenge-Creation screens
- **Fallback / Challenge Creation screen:** `Inter` (same weight range via Google Fonts)
- **Monospace:** `JetBrains Mono` / `Fira Code` — referenced but not visibly used in mockups

### Size hierarchy (General Sans / Inter)

| Level | Size | Weight | Usage |
|---|---|---|---|
| Page title | 22–24px | 700 | "Events", "Challenges", "Leaderboard" headers |
| Screen section heading | 17px | 700 | Card section titles like "Recent Badges", "Today" |
| Card title / Post title | 15–16px | 600–700 | Post headings, card names |
| Body / message | 13–15px | 400–500 | Post body, notification messages, description text |
| Label / meta | 12–13px | 500–600 | Tags, timestamps, role subtitles |
| Caption / overline | 10–11px | 600–700 | Section labels (uppercase), badge labels, date chips |
| Stat value | 20–24px | 700 | Leaderboard scores, stat strip numbers |
| Hero title | 22–24px | 700 | Event hero, challenge hero headings on dark backgrounds |
| Input large | 24px | 700 | Challenge name input |
| Input body | 14px | 400–500 | Description textarea, form fields |

### Letter-spacing and line-height
- Headings tighten to `letter-spacing: -0.02em` to `−0.03em`
- Body text uses `line-height: 1.5–1.65`
- Tight display: `line-height: 1.2`

---

## Spacing and layout

### Screen layout
- All screens are **430 px wide** mobile frames with a sticky top nav and a fixed bottom navigation bar.
- Horizontal page padding: **16–20 px** on all scrollable content.
- Top nav height: ~60–64 px; bottom nav: ~56–66 px (accounting for safe-area inset).

### Spacing scale (observed values)
| Token | px equivalent | Common use |
|---|---|---|
| 2xs | 4px | Icon badges, tight gaps |
| xs | 8px | Small gaps between chips, inline elements |
| sm | 12px | Card internal gaps, list item spacing |
| md | 16px | Card padding, section gap |
| lg | 20–24px | Hero card padding, section vertical margins |
| xl | 28–32px | Hero top padding, large section gaps |

### Regions
- **Status bar** — 44–54 px, transparent or matching background
- **Top nav** — sticky; back button left, title center, action(s) right; separated by `1px` border or none
- **Filter chip row** — horizontal scroll, `padding: 12px 20px`, `gap: 8px`, `border-bottom`
- **Hero/banner card** — full-bleed within `16px` margin, `border-radius: 20–24px`, gradient background, `box-shadow` for depth
- **Content sections** — labeled with uppercase overline + divider line, `gap: 12px` between cards
- **Card** — `border-radius: 16–18px`, white `#fff`, `border: 1px solid #e8e8e2` or subtle shadow, `padding: 14–16px`
- **Bottom nav** — 5-item bar, lime pill for active item, 10px icon, 10px label

---

## Components

### Buttons

| Type | Appearance |
|---|---|
| **Primary CTA (launch / confirm)** | Full-width, `height: 52–54px`, `border-radius: 14–16px`, emerald or blue gradient, white bold text, colored `box-shadow` |
| **Pill button (top nav / RSVP)** | `border-radius: 20px`, `padding: 8–10px 18–20px`, gradient or solid blue/white, `font-weight: 600–700`, `box-shadow` |
| **Outline / ghost button** | White background, colored `1.5px border`, matching text color; used for secondary actions beside primary |
| **Small action button (event card)** | `border-radius: 9999px`, `padding: 5–7px 12–13px`, 12px/700 weight; variants: "RSVP" (dark blue), "Going" (green tinted), "Maybe" (amber tinted) |
| **Icon-only round** | `width/height: 36–40px`, `border-radius: 50%` or `12px`, neutral fill `#f5f5f0` or `rgba(0,0,0,0.07)`, hover lightens |

**States:** hover raises `translateY(-1–2px)` and deepens shadow; active scales to `0.95–0.97`; disabled at `opacity: 0.45`.

### Inputs and form controls

| Component | Appearance |
|---|---|
| **Text input** | `background: #f7f7f5`, `border: 1.5px solid #e8e8e2`, `border-radius: 12px`, `padding: 12px 14px`; focus shifts border to the screen's accent color and adds `0 0 0 3px rgba(color, 0.12)` ring |
| **Large name input** | `font-size: 24px`, `font-weight: 700`, transparent background, no border; placeholder in `#d4d4cc` |
| **Textarea** | Same as text input with `resize: none`, `min-height: 72px`, `line-height: 1.55` |
| **Toggle switch** | `51×31px`, `border-radius: 20px`; on = emerald `#10b981`; off = `#d4d4cc`; white thumb with drop shadow, spring animation |
| **Segmented control** | Pill-within-pill; container `background: #efefea`, `border-radius: 12px`; active segment `background: white`, `box-shadow: shadow-sm` |
| **Unit/filter chips** | `border-radius: 20px`, `padding: 6–7px 11–14px`, `font-size: 11.5–13px`, `font-weight: 600`; default = `#f2f2f7` with `#e8e8e2` border; selected = color-specific tint + matching border |
| **Stepper** | Small white buttons inside a bordered `#f7f7f5` pill; `border-radius: 8px`; `font-size: 18px bold` value |

### Cards

| Type | Description |
|---|---|
| **Content card** | White, `border-radius: 16–18px`, subtle shadow, `1px` border; hover: `translateY(-2px)` + deeper shadow |
| **Hero card (dark)** | Gradient background (blue/green), `border-radius: 20–24px`, overflow hidden, decorative radial glow elements, `box-shadow` with color tint |
| **Event list card** | Horizontal flex: colored date-block left (62px wide, color variant per category) + content area right |
| **Challenge card (horizontal scroll)** | 180px fixed width, white, `border-radius: 16px`; icon chip, name, category label, thin progress bar, mini avatar stack |
| **Recognition card** | Amber gradient `#fffbeb→#fde68a`, `border: 1px solid #fcd34d`, large decorative quote mark pseudo-element |
| **Notification card** | White with unread variant: `background: #f0f6ff`, left `4px` blue gradient stripe, blue dot in top-right |
| **Leaderboard row** | Flex row with rank number, gradient avatar, name/role, score; top 3 have metallic ring + crown badge |

### Navigation

**Bottom tab bar (mobile):**
- 5 items, evenly distributed
- Active item: lime pill `#c5ff55` under icon, dark text
- Inactive: muted gray icon `#a8a89e`, small label beneath

**Top navigation:**
- Back button (circle or rounded square), centered title, right action (share / filter / settings)
- Transparent or frosted glass (`backdrop-filter: blur(12px)`) on scroll

**Filter/tab rows:**
- Horizontal scroll, chips or underline tabs
- Active state: solid dark fill (chip) or `2.5px` underline in brand/blue color

### Progress and data

| Component | Appearance |
|---|---|
| **Progress bar** | `height: 4–8px`, `border-radius: 9999px`, track `#f0f2f5` or `rgba(255,255,255,0.2)`; fill is color-matched gradient (emerald for fitness, blue for events, amber for XP) |
| **Progress ring (SVG)** | `88×88px`, 6px stroke; track `rgba(255,255,255,0.15)`; fill emerald `#34d399`; overlaid percentage label |
| **Avatar stack** | Circular avatars with `2px white border`, `margin-left: -6–8px` overlap; gradient fills per person |
| **Section badge** | Small pill `font-size: 10–11px`, colored `background: #dbeafe`, count in blue |

---

## Imagery and iconography

### Icons
All icons are drawn from the **Phosphor Icons** library (`ph` prefix) at sizes 14–24 px. They are used extensively as:
- Navigation icons (house, bell, users, trophy, lightning)
- Card header icons in colored rounded-square containers (36–52 px, `border-radius: 10–16px`, gradient or tinted fill)
- Inline meta icons within text rows (calendar, clock, map-pin, monitor)
- Badge overlays (tiny 8–9 px within 16 px circles)

Icons within colored containers always inherit the container's thematic color (e.g., emerald icon on emerald-tinted background).

### Avatars
- Circular, with colored gradient backgrounds when no photo
- Initials displayed in white, `font-weight: 700`
- Animated gradient ring (conic-gradient) used for featured profiles in "Other Manager Profile"
- Online status dot: `#22c55e`, bottom-right, `border: 2.5px solid` matching background
- PRO badge: amber gradient pill in top-right corner

### Photography / illustrations
- Full-bleed hero images for event detail pages (leadership conference, cityscape map preview)
- Professional headshots for profile pages
- Team collaboration photos within post cards
- All images are `object-fit: cover` within fixed-height containers with rounded corners
- Emoji used liberally as lightweight illustrations (🔥 streak, 👑 leaderboard, 🏆 achievements, ⭐ recognition)

---

## Voice and tone

The copy is **direct, motivating, and warm** — speaking to managers as capable peers who appreciate both data and human encouragement. It avoids corporate jargon in favor of plain language with occasional playfulness. Gamification vocabulary (XP, streaks, ranks, prizes) is used naturally without feeling childish.

**Representative phrases:**
- *"Hit 10,000 steps every day for 30 days. Build the habit, beat the team, and earn your spot on the leaderboard!"*
- *"You're in the top 10% on 30-Day Wellness Challenge — keep the streak going! 🔥"*
- *"Log 2 more sessions today to move into the top 10 this week."*
- *"480 XP until PLATINUM"*
- *"Let the organizer know if you're coming. You can update your response up until 48 hours before the event."*

Formality is semi-casual. Second person ("you", "your") is used throughout. Action verbs lead most CTAs ("Launch Challenge", "Confirm RSVP", "Log Progress", "Join Challenge"). Urgency is created through time and scarcity signals ("23 spots left", "18 days left") without pressure-selling language.