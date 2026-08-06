# Manager Connect — UI Style Guide

## Overall Impression

Manager Connect presents a polished, professional mobile-first product aimed at executive and management communities. The aesthetic is clean and modern with a warm, approachable edge — white cards layered over warm off-white backgrounds create quiet depth, while vivid accent colors (electric lime, cobalt blue, vivid purple, emerald green) inject energy and delight. The design communicates trust and competence through restrained structure, but avoids feeling corporate or cold by using rounded corners, soft shadows, celebratory micro-animations, and a color-saturated icon system. The overall mood is confident, human, and optimistic — a platform that takes leadership seriously while making participation feel rewarding.

---

## Color

### Primary / Brand
| Role | Value | Usage |
|---|---|---|
| Brand / Lime | `#c5ff55` | Active nav indicator fill, checkbox/radio checked state, primary CTA backgrounds (brand variant), active sidebar pill |
| Brand Strong | `#b0e64d` | Hover state for brand buttons |
| Brand Subtle | `#eeffcc` | Tinted surface on brand-highlighted sections |

### Accent / Secondary
| Role | Value | Usage |
|---|---|---|
| Accent / Purple | `#8b5cf6` | Secondary CTAs (accent buttons), focus rings, link text (`#7c3aed`), active sort indicators |
| Accent Subtle | `#f5f0ff` | Tinted surfaces on accent areas |

### Semantic Colors
| Role | Hex | Usage |
|---|---|---|
| Success | `#10b981` | Success checkmarks, progress fills, RSVP confirmed badges, "good" form feedback |
| Error | `#ef4444` | Error icons, form field border/background in invalid state, error badges |
| Warning | `#f59e0b` | Server error codes, streak badges, calendar pin highlights |
| Info / Blue | `#3b82f6` | Primary action buttons (blue variant), network/connection icons, unread notification dots, loading spinners |
| Deep Navy | `#0f2d5c` → `#2563eb` | Identity banner gradient, app logo, loading ring outer circle |

### Neutral / Surface
| Role | Value | Usage |
|---|---|---|
| Page surface | `#f5f5f0` (warm gray) | Screen background, sticky nav background |
| Card surface | `#ffffff` | All card backgrounds |
| Nested surface | `#fafaf7` | Inset sections, stat blocks, shimmer backgrounds |
| Subtle border | `#efefea` | Card/row dividers |
| Default border | `#e8e8e2` | Input borders, card borders |
| Text primary | `#1a1a18` | Headings, high-emphasis labels |
| Text secondary | `#5c5c54` | Body copy, subtitles |
| Text muted | `#7c7c72` | Captions, metadata, section labels |
| Text disabled | `#a8a89e` | Placeholder text, disabled controls |

### Special Accents (empty/success state illustrations)
- Confetti: amber `#fbbf24`, emerald `#34d399`, red `#f87171`, purple `#a78bfa`, blue `#60a5fa`
- Accent dot in logo SVG: `#c5ff55` (lime)
- Heart icon: `#e11d48`

---

## Typography

**Typeface:** `General Sans` (sans-serif), weights 400, 500, 600, 700. Fallback to `sans-serif`.  
**Monospace:** `JetBrains Mono` / `Fira Code` (used for error codes, e.g., `500` server code pill).

### Size Hierarchy

| Level | Size | Weight | Letter-spacing | Usage |
|---|---|---|---|---|
| Display / Page Title | `20px` | 700 | `−0.02em` | Nav bar title, screen headings |
| Card heading large | `22–24px` | 700 | `−0.025em` | Hero success/recognition card title |
| Card heading mid | `17–18px` | 700 | `−0.015em` | Section card headlines, feature names |
| Body large | `16px` | 600 | `−0.01em` | Sub-headings within cards |
| Body / Label | `14px` | 400–500 | normal | Body copy, list item text |
| Caption / Meta | `13px` | 400–500 | normal | Subtitles, post preview text, helper text |
| Small label | `12px` | 500–600 | `0.01em` | Badge text, meta rows, spinner labels |
| Overline | `11px` | 600 | `0.07–0.08em`, uppercase | Section labels, card-type labels, "RSVP Confirmed" badge |
| Micro caption | `10px` | 600 | `0.06em`, uppercase | Card type corner labels |

**Line-heights:**  
- Tight: `1.2` (display headings)  
- Snug: `1.35` (card sub-headings)  
- Normal: `1.5` (body)  
- Relaxed: `1.65` (body copy, mission text, error descriptions)

---

## Spacing and Layout

**Base unit:** `4px` (0.25rem). Spacing scale: `4 / 8 / 12 / 16 / 24 / 32 / 40 / 48 / 64px`.

### Page Structure
- **Screen width:** 430px (mobile frame)
- **Horizontal padding:** `16–20px` from screen edge to card
- **Vertical gap between cards:** `12–16px`
- **Card internal padding:** `20–28px` horizontal, `20–32px` vertical
- **Sticky nav bar height:** ~64px; uses `backdrop-filter: blur(12px)` on a `rgba(255,255,255,0.92)` background

### Common Patterns
- Feature rows and list rows: `13px` vertical padding, `1px` bottom border separator
- Section labels (overlines): `20px` top margin before first card in section
- Icon circles: `44–56px` square, `border-radius: 12–14px` (for feature icons), `border-radius: 50%` (avatars)
- Inset/nested blocks: `#fafaf7` background, `8–10px` border-radius, `1px` border `#efefea`

---

## Components

### Cards
White (`#fff`) backgrounds, `border-radius: 16–20px`, `1px` border in `#efefea`, light shadow `0 1px 3px rgba(26,26,24,0.06), 0 1px 2px rgba(26,26,24,0.04)`. On hover: `translateY(-1 to -2px)` with slightly elevated shadow. Overflow is hidden on cards with banners.

### Buttons
All buttons use `border-radius: 10–12px`, `font-weight: 600`, `font-size: 14px`, and include left-aligned icons.

| Variant | Background | Border | Text |
|---|---|---|---|
| Primary (blue) | `#3b82f6` | none | white |
| Primary (emerald) | gradient `#10b981→#059669` | none | white |
| Primary (brand/lime) | `#c5ff55` | `#9acc44` | `#1a1a18` |
| Primary (purple) | `#7c3aed` | `#7c3aed` | white |
| Ghost / Outline | transparent | `1.5px #e2e8f0` | `#475569` |
| Accent | `#8b5cf6` | `#7c3aed` | white |
| Secondary / Neutral | `#f5f5f0` | `1.5px #e8e8e2` | `#1a1a18` |
| Disabled | same as primary at `opacity: 0.45` | — | — |
| Link / Text | none | none | `#3b82f6` or `#7c3aed` |

Hover: `translateY(-1px)` + elevated box shadow. Active: `scale(0.97)`.

### Inputs
`border-radius: 12px` (radius-lg), `1px` border `#e8e8e2`, white background, `font-size: 14px`.  
**Error state:** `1.5px #f87171` border, `#fef2f2` background fill, `box-shadow: 0 0 0 3px rgba(239,68,68,0.12)`.  
**Focus state:** border changes to `#8b5cf6` (purple), `box-shadow: 0 0 0 3px rgba(139,92,246,0.35)`.  
Inline error messages appear below inputs in `12px`, `font-weight: 500`, `#dc2626`, preceded by a warning circle icon.

### Navigation Bar
Sticky top bar with back arrow button (36×36px, `border-radius: 50%`, `#f5f5f0` background) + title. Backdrop blur with semi-transparent white. Bottom border `1px #efefea`.

### Badges / Chips
Pill-shaped (`border-radius: 9999px`), padded `4px 10px`. Semantic color variants: amber for premium/warning, green for success/confirmed, blue for info/live, purple for accent. Section label overlines are uppercase, `11px`, `#7c7c72`, `letter-spacing: 0.07–0.08em`.

### Empty State Cards
Centered layout with a custom SVG illustration (160×120px), bold title (`18px`, weight 700), muted description (`14px`, `max-width: ~26ch`), and one primary action button. Illustrations use soft pastel blobs with node/icon motifs in brand colors.

### Skeleton / Loading
Shimmer animation using `linear-gradient(90deg, #E5E7EB 25%, #F3F4F6 50%, #E5E7EB 75%)` on a 936px background, cycling at 1.5s. Applied to rounded bars (height 8–18px) and circles mimicking real content shapes.

### Spinners
Three variants used: (1) ring spinner (`border-top-color: #2563eb`, 0.8s rotate), (2) dot pulse (3 dots, staggered `scale` animation), (3) bar waveform (5 bars, `scaleY` bounce). Full-screen state uses nested counter-rotating rings (navy outer, blue inner).

### Toast
Fixed bottom, `border-radius: 16px`, dark `#2d2d2a` background, white text. Leading emerald pulsing dot, bold colored strong text (`#6ee7b7`), dismiss ×. Enters via `translateY(80px)` spring animation.

### Progress Bar
Track: `#f1f5f9` (`border-radius: full`, `height: 8px`). Fill: `linear-gradient(90deg, #34d399, #10b981)`. Animates from 0 on scroll into view (`1.2s cubic-bezier`).

---

## Imagery and Iconography

**Icon library:** Phosphor Icons (`ph` prefix classes), used at `font-size: 14–24px`. Filled (`ph-fill`) variants used for heart/notification dots. Icons are always paired with a semantic color from the palette — never standalone black.

**Feature icon circles:** Rounded squares (44px, `border-radius: 12px`) with light pastel gradient fills matching each feature's color identity (amber for recognition, blue for events, green for challenges, purple for analytics, pink for community).

**Illustrations:** Custom inline SVGs in empty states and identity banners. Approach is flat, abstract, and geometric — network nodes with connecting lines, calendar grids, magnifier glyphs, sleeping bell with "Zzz". Color palette mirrors brand tokens: blue `#3B82F6`, lime `#c5ff55`, purple `#a78bfa`, green `#34d399`, amber `#fbbf24`. Decorative floating dots and sparkles at corners add playfulness.

**App logomark:** SVG "M" letterform in white strokes on blue gradient, with a lime `#c5ff55` accent dot at the base — the brand signature element, present at multiple sizes.

**Avatars:** Circular, 24–64px, with colorful gradient fallback fills (purple, emerald, blue, amber) showing initials.

---

## Voice and Tone

The copy is warm, direct, and encouraging — professional enough for executives, but human and motivating. It speaks to the user as a capable leader who deserves recognition and community. There is a light celebratory tone on success moments and plain, non-alarming language on errors.

**Representative phrases:**

- *"Leadership is not about being in charge. It's about taking care of those in your charge."* (mission accent quote — aspirational, cited)
- *"Celebrate wins, spotlight achievements, and build a culture of appreciation across your team."* (feature description — action-oriented, benefit-framed)
- *"Every great streak starts with day one. Give your first piece of feedback today to light the flame!"* (challenge motivational copy — warm encouragement, uses metaphor)