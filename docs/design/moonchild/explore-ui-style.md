# Manager Connect — UI Style Guide

## Overall Impression

Manager Connect presents as a premium, mobile-first leadership networking application with a confident, professional character. The design draws heavily from Apple's Human Interface sensibilities — generous use of white card surfaces against slightly warmed off-white page backgrounds, soft layered shadows, and substantial corner radii that feel polished without being childish. The splash and auth screens use a rich deep navy gradient (#1A3A6B → #0F2D5E) as a signature hero surface, while the in-app screens shift to clean light chrome. A warm amber (#FFB840) accent applied sparingly to recognition flows and the brand logomark creates warmth and celebration against the otherwise reserved corporate palette. The overall mood is: trustworthy, modern, and built for people who take leadership seriously but also want to enjoy the product.

---

## Color

### Core Palette

| Role | Hex | Usage |
|---|---|---|
| **Primary / Brand Blue** | `#1A3A6B` | Splash background, primary CTA buttons, deep nav elements, announcement left-border accents |
| **Brand Blue Mid** | `#2451A3` | Topbar wordmarks, link text in some screens, button hover states |
| **Brand Blue Light** | `#3B6FD4` | Story ring gradient, active navigation items on Home Feed, RSVP button gradient |
| **Brand Blue Pale** | `#EEF2FA` | Icon chip backgrounds, hover tints on date chips and category chips |
| **Amber Accent** | `#FFB840` | Recognition card shimmer strip, logomark "C" stroke, OTP countdown timer (default state), celebration chip gradient, recognition send button |
| **Amber Dark** | `#D97706` / `#E8A020` | Amber progress fill start, badge text on OTP countdown |
| **Amber Light** | `#FEF3C7` | Recognition card hero background, recognition icon wrap |
| **Amber Pale** | `#FFFBEB` | OTP countdown chip background |
| **Violet** | `#7C3AED` | Poll accent color: left-border, icon wrap, bar fill, post button, vote button |
| **Violet Light** | `#EDE9FE` | Poll icon background, AI Assist button tint |
| **Success Green** | `#10B981` / `#2BD394` | OTP verified badge, engagement score stat chip, success confirmation on send buttons |
| **Error Red** | `#EF4444` | Notification badge, unread dot, comment input error state, timer expiry |
| **Page Background** | `#F4F5F7` / `#F2F3F7` / `#F0F2F5` | App-level background on all interior screens |
| **Card Surface** | `#FFFFFF` | Every card, input, and elevated component |
| **Primary Text** | `#111827` / `#14213D` | Headings, card titles, primary labels |
| **Secondary Text** | `#6B7280` / `#64748B` | Subtitles, metadata, helper copy |
| **Muted / Disabled Text** | `#9CA3AF` / `#94A3B8` | Timestamps, placeholders, tab labels |
| **Border Default** | `#E5E7EB` / `#DDE3EC` | Card borders, input borders |
| **Border Light** | `#F3F4F6` | Dividers, bottom-nav top border |

**Semantic status colors** (pills, progress bars, alerts):
- Success: `#10B981` on `#D1FAE5` / `#ECFDF5`
- Warning: `#D97706` on `#FDE68A` / `#FEF3C7`
- Error: `#EF4444` on `#FEF2F2`
- Info: `#3B82F6` on `#DBEAFE` / `#EFF6FF`

---

## Typography

**Primary typeface:** `General Sans` (custom-loaded, weights 400 / 500 / 600 / 700). The Home Feed and Post Detail screens additionally pull in `Inter` for body copy variety in some contexts.

### Size & Weight Hierarchy

| Level | Size | Weight | Letter-spacing | Usage |
|---|---|---|---|---|
| App name / display | 28–30px | 700 | −0.4px | Splash wordmark, login wordmark |
| Page heading | 24–26px | 700 | −0.3px | Onboarding heading, card heading in login, OTP heading |
| Post headline | 21–22px | 800 | −0.3px | Post detail h1, poll question input (17px bold) |
| Card title | 18–20px | 700–800 | −0.3px | Event card name, recognition hero heading |
| Section heading | 16–18px | 700 | −0.2px | Top-bar titles, "New Post", "Create Event" |
| Body / post text | 15–17px | 400 | −0.05px | Post detail body copy (line-height 1.72), descriptions |
| UI label / button | 13–15px | 500–700 | 0.01em | Form labels, button text, author names |
| Caption / meta | 11–13px | 400–600 | 0.01–0.05em | Timestamps, source labels, char counters |
| Overline / tag | 10–12px | 600–700 | 0.05–0.08em | Section labels (uppercase), category chips, status pills |
| Version / hint | 11px | 400 | 0.04em | Splash version text, input hints |

**Line heights:** tight `1.1–1.25` for large headings; `1.45–1.55` for UI text; `1.6–1.72` for editorial body copy; `1.5` for standard body.

**Heading letter-spacing:** consistently negative (−0.01em to −0.025em) on headings 18px+, giving a condensed editorial quality.

**Taglines / overlines:** uppercase, `letter-spacing: 0.06–0.08em`, weight 600–700, muted color (`rgba(255,255,255,0.5)` on dark, `#9CA3AF` on light).

---

## Spacing and Layout

All screens are fixed at **430 × 932 px** (iPhone-sized frame).

### Spacing Scale (observed values)
| Token | Value | Common use |
|---|---|---|
| 2xs | 4px | Gap between badge elements, tight inline gaps |
| xs | 8px | Icon-to-text gap, chip internal padding |
| sm | 12px | Section internal gaps, avatar-to-text |
| md | 16px | Card padding, section horizontal padding |
| lg | 20–24px | Section vertical padding, form row padding |
| xl | 28–32px | Card padding on modals, bottom sheet padding |
| 2xl | 48px | Bottom safe-area padding |

### Layout Patterns
- **Sticky top bar:** 58–60px tall, white background with `backdrop-filter: blur(12px)`, 1px bottom border. Contains back/close, centered title, and a right action (post/publish button).
- **Hero-to-card layout (Login):** Full-bleed navy panel (~310px) overlaps a white bottom sheet that slides up with `border-radius: 28px 28px 0 0` and negative `margin-top: -24px`.
- **Scroll + fixed bottom (feed, composer, post detail):** Content scrolls within a fixed viewport, with a pinned bottom bar (nav, composer, or send button).
- **Card stack:** Cards in a vertical list have `border-radius: 16px` (feed) or `20px` (creation screens), `margin-bottom: 12px`, and subtle `box-shadow: 0 1px 3px rgba(0,0,0,0.06)`.
- **Onboarding:** Top ~45% is an illustration card; bottom ~55% is a white bottom sheet with dot indicators, heading, body copy, and a pinned CTA at the bottom 48px above safe area.
- **Horizontal scroll rows:** Stories, trending chips, and duration chips use `overflow-x: auto; scrollbar-width: none` with 16px left padding and 7–10px gaps.

---

## Components

### Buttons

**Primary / brand (dark navy):**
- Background: `linear-gradient(135deg, #1E4585, #1A3A6B, #0F2D5E)`
- Height: 52–56px, `border-radius: 12–16px`
- Text: white, 15–16px, weight 700
- Shadow: `0 4px 16px rgba(15,45,94,0.3)`
- Hover: `translateY(-1px)`, deeper shadow
- Disabled: background `#CBD5E1`, text `#94A3B8`

**Amber recognition CTA:**
- Background: `linear-gradient(135deg, #F59E0B, #FBBF24)`
- Same size and radius conventions as primary
- Shadow glows amber

**Pill / rounded buttons (post, publish, follow):**
- `border-radius: 999px`, compact padding `7–9px 16–18px`
- "Post" in header: blue `#2563EB` or `#1A3A6B`

**Ghost / secondary:**
- White background, `1.5px` border `#DDE3EC`
- Used for Microsoft SSO button, back/close buttons

**Icon-only circle buttons:**
- 36–44px diameter, `border-radius: 50%`
- Background: `#F3F4F6` (close/back); transparent with hover fill

### Inputs

- Height: 48–52px
- `border-radius: 12px`
- Border: `1.5px solid #E2E8F0` (default) → `#1A3A6B` with focus glow `0 0 0 3px rgba(26,58,107,0.12)` on dark-themed screens; `#8B5CF6 / #2563EB` on poll/event screens
- Background: `#F8FAFC` → `#FFFFFF` on focus
- Left icon at 14px from edge, 17px icon size, `#94A3B8` → brand color on focus
- Password toggle on right, `18px` icon, same tint behavior

**OTP boxes:** 52×60px individual tiles, `border-radius: 12px`, 22px bold centered digit; filled state gets `#F5F8FF` background and navy border.

**Textarea (post composer):** Borderless, transparent, `17px` bold, expands; surrounded by a card container that focuses as a unit.

### Cards

- `border-radius: 16px` (feed) / `20px` (creation / recognition)
- Background: `#FFFFFF`
- Border: `1px solid #E5E7EB` or `rgba(0,0,0,0.04–0.05)`
- Shadow: `0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)` (shadow-sm)
- Active press: `transform: scale(0.99)`

**Announcement cards** have a colored `4px left border` (navy, green) and a category tag + "Read more" footer row.

**Recognition cards** have a `6px amber shimmer gradient top strip` with `animation: shimmer 2.5s infinite` and a reaction row with emoji pills at the bottom.

**Event cards** have a full-bleed navy-gradient header strip with a floating date box.

**Poll cards** use a 4px violet left border, labeled percentage bars with a glowing "leading" fill, and a vote button.

### Navigation

**Bottom nav (Home Feed):**
- 72px tall, white, 1px top border
- Active tab: icon wrapper pill (`48×28px, border-radius: 9999px`) gets `background: #EEF2FA`, label turns `#2451A3` bold
- Inactive: `#9CA3AF` icons and labels

**Stories row:** Circular avatars with gradient ring (`#3B6FD4 → #60A5FA` for unread, `#D1D5DB` for viewed). 56px diameter, 68px item width with label underneath.

**Filter chips / trending chips:** Pill-shaped, `border-radius: 999px`, active state fills to `#1B3A6B` with white text.

### Toggles

Custom toggle switches: 44–48px wide × 26–27px tall, `border-radius: 9999px`. Off: `#E5E7EB` track. On: amber `#F59E0B` (recognition screen) or violet `#8B5CF6` (poll settings) or blue `#2563EB` (event). Thumb: white circle, `box-shadow: 0 1px 4px rgba(0,0,0,0.2)`, spring-like translate transition.

### Avatars

- Circular, sizes xs (24px) → xl (64–68px)
- Photo avatars: `object-fit: cover`, `border: 2px solid` (border color matches context — amber for recognition, blue-pale for standard)
- Fallback initials: gradient fill (purple, blue, green per person), white bold initials
- Status dot: 25% of avatar size, bottom-right, 2px white border

### Progress / bars

- **Splash progress bar:** 200px wide, 3px tall, `border-radius: 999px`, amber gradient fill with amber glow
- **Poll bars:** 8px tall, `border-radius: 99px`, violet fill with subtle shadow on the leading option
- **Reaction bars:** inline thin pills below reaction buttons

### OTP / PIN input

Six individual boxes (3+separator+3 arrangement), `gap: 10px`, small circle dot separator. Focus-within ring in navy, filled state highlighted in pale blue.

---

## Imagery and Iconography

### Icons

All icons are from the **Phosphor Icons** set (`ph ph-*` classes), used throughout at sizes 14–38px. Usage is extensive — every list row, action button, toolbar item, and category chip has a Phosphor icon. Line weight is consistent with the "regular" Phosphor style. Notable uses: `ph-trophy` (recognition), `ph-chart-bar` (polls), `ph-calendar-check` (events), `ph-shield-check` (OTP), `ph-megaphone` (announcements).

### Logomark

A custom SVG: a stylized **"M"** shape in white strokes (3.2px, rounded caps) overlaid with a partial **"C"** arc in amber (`#FFB840`), sharing a center connection point. Set in a 96×96px frosted-glass tile with `border-radius: 28px` and an animated amber radial glow ring. The mark directly encodes the product name.

### Illustrations

The Onboarding screen uses an SVG network diagram: deep navy node clusters connected by animated dashed lines, with an amber highlight node and floating diamond accents on a near-white (#FAFBFF) background. The style is flat vector with subtle radial gradients — minimal, editorial, inspired by Apple-tier abstract product illustration.

### Photography

Placeholder images use professional executive headshots (diverse, business-casual) as avatars and a team-in-boardroom editorial photo in the Post Detail. All images are circular-cropped for avatars or `border-radius: 12–14px` with `object-fit: cover` for inline embeds.

---

## Voice and Tone

The copy is **direct, warm, and peer-to-peer** — it speaks to managers as capable adults who value efficiency and recognition. There is no corporate stiffness; the language is encouraging and occasionally celebratory without feeling forced.

- **"Built for leaders"** — the tagline is confident and pithy, not explanatory.
- **"Good morning, Alex 👋 — Thursday, Jan 16 · 3 things need your attention"** — personalized, time-aware, gently urgent without alarm.
- **"Celebrate someone who made a difference"** — recognition framing is emotionally warm and action-oriented.
- **"Never share this code with anyone. Manager Connect will never ask for it via phone or email."** — security copy is direct and builds trust without being bureaucratic.
- **"Who would you like to recognize today?"** — placeholder copy is inviting and implies a daily habit.
- **"Relationships precede results."** — editorial body copy in posts uses short, memorable formulations to convey leadership wisdom.

Overall register: **semi-formal to conversational**, first-name personal, action-verb forward ("Get Started", "Verify & Continue", "Post Event", "Send Recognition"). Emojis are used contextually and sparingly (greeting, celebration) rather than decoratively throughout UI.