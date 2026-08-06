# Manager Connect — Style Guide

## Overall Impression

Manager Connect is a polished, feature-rich mobile-first social platform aimed at professional managers. The aesthetic is clean, approachable, and data-forward — somewhere between a modern social network and a productivity tool. Light surfaces dominate, with warm off-white backgrounds giving the UI a softer, less sterile feel than pure white. Color is used purposefully and semantically: blue anchors primary actions, purple signals links and accents, lime green signals active navigation states, and contextual semantic colors (amber, green, red) communicate status clearly. The overall mood is professional but human — capable of displaying dense information without ever feeling clinical. Micro-interactions (spring-based animations, hover lifts, tap feedback) give the product a sense of quality and responsiveness throughout.

---

## Color

### Palette

| Role | Hex | Used For |
|---|---|---|
| **Primary/action** | `#2563eb` | Search bar focus ring, connect buttons, search scope active chip, blue interactive elements |
| **Active nav (brand)** | `#c5ff55` | Active bottom-nav pill background (lime/yellow-green), active sidebar items; dark text `#1a1a18` is used on top |
| **Accent/purple** | `#7c3aed` / `#8b5cf6` | Link text, card "more" actions, analytics section labels, comment role tags |
| **Page background** | `#f0f2f5` / `#f2f2f7` | App background behind all cards |
| **Card/surface** | `#ffffff` | All card and panel surfaces |
| **Nested surface** | `#f8fafc` / `#f5f5f0` / `#fafaf7` | Slightly off-white nested surfaces, input backgrounds, row hovers |
| **Primary text** | `#1a1a18` / `#0f172a` | All primary labels and headings |
| **Secondary text** | `#5c5c54` / `#475569` | Subtitles, metadata, secondary copy |
| **Muted text** | `#7c7c72` / `#94a3b8` | Timestamps, captions, placeholders |
| **Border default** | `#e8e8e2` / `#e2e8f0` | Card borders, input borders, dividers |
| **Success/green** | `#059669` / `#10b981` | "Connected" state, positive deltas, online status dots, approve buttons |
| **Warning/amber** | `#d97706` / `#f59e0b` | Pending states, urgency badges, bar chart fill, analytics warm accents |
| **Error/red** | `#ef4444` / `#dc2626` | Alert badges, flagged content accents, notification dots, deny buttons |
| **Blue info** | `#3b82f6` / `#1d4ed8` | Line charts, unread notification tints (`#eff6ff`), heatmap fills, user list invite buttons |
| **Dark overlay (fullscreen)** | `#000000` with gradient overlays | Media viewer background |

Avatar fallbacks use a consistent set of gradient pairs: blue–indigo, amber–yellow, green–emerald, purple–violet, rose–red, cyan–teal.

---

## Typography

**Typeface:** *General Sans* (weights 400, 500, 600, 700), with system sans-serif fallback (`-apple-system`, `BlinkMacSystemFont`).

### Size Hierarchy

| Level | Size | Weight | Use |
|---|---|---|---|
| Page title / screen heading | `22–22px` | 700 | Screen headers ("Search", "Analytics") |
| Card / section title | `15–16px` | 600–700 | White card titles, card section labels |
| Body copy | `14–15px` | 400 | Post body, comment text, manager descriptions |
| Secondary/meta | `12–13px` | 400–500 | Timestamps, sub-labels, role metadata |
| Overline / section label | `11–13px` | 600–700, uppercase, `letter-spacing: 0.06–0.08em` | "RECENT", "TRENDING MANAGERS", section dividers |
| Caption / badge | `10–11px` | 600 | Status pills, role chips, nav labels, change deltas |
| Large metric | `26–28px` | 700 | KPI values on analytics cards |
| Small nav label | `10px` | 500–600 | Bottom navigation labels |

**Letter-spacing:** Headings use `letter-spacing: -0.02em` to `-0.03em` (slightly tight). Labels and overlines use `+0.04em` to `+0.08em` (slightly loose). Body text is untracked.

**Line heights:** Body text ~1.4–1.6; headings ~1.2.

---

## Spacing and Layout

All screens are designed at **430 × 932px** (iPhone-class mobile viewport). Horizontal padding is consistently **16–20px**.

### Spacing Scale (observed)

| Step | Value |
|---|---|
| Micro | `4px` |
| XS | `6–8px` |
| SM | `10–12px` |
| MD | `14–16px` |
| LG | `18–20px` |
| XL | `24px` |
| 2XL | `32px` |

### Layout Patterns

- **Top chrome:** Status bar (44px) → Header with title + action buttons → Filter/scope chip row → Divider; all sticky.
- **Scrollable content:** `padding-bottom: 100px` to ensure content clears the fixed bottom nav.
- **Bottom nav:** Fixed, 5-item tab bar with icon + label. Active item uses a pill-shaped `#c5ff55` background container (48×28px, full-radius) around the icon; the label turns bold and darkens.
- **Cards:** White rounded cards on a gray background, `border-radius: 12–16px`, `border: 1px solid #efefea`, `box-shadow: 0 1px 3px rgba(26,26,24,0.06)`. Card headers have a paired title + small action link ("See all", "Detail") on the same row.
- **Lists:** Row items use `padding: 11–14px 16–20px`, separated by 1px borders or grouped into white cards.
- **Grids:** 2-column metric grids on analytics screens (gap ~10–12px); 4-column quick action grids; 2-column type-selector grids.

---

## Components

### Bottom Navigation
Five tabs, uniformly spaced. Inactive: icon in `#a8a89e`, label in `#a8a89e` at 10px. Active: icon inside a pill (`background: #c5ff55`, 48×28px, border-radius: 999px), label becomes bold near-black. A red dot `#ef4444` (7–8px, white border) appears on the Alerts icon when unread.

### Search Bar
Rounded input (border-radius: 12px) with leading magnifying-glass icon. Default: `background: #f8fafc`, `border: 1.5px solid #e2e8f0`. Focused: white background, `border-color: #2563eb`, `box-shadow: 0 0 0 3px rgba(37,99,235,0.2)`. Icon tints blue on focus. Includes a circular clear button (20px, dark gray background, white × icon) that appears only when there is input.

### Filter/Scope Chips
Pill-shaped (`border-radius: 999px`), `padding: 7–8px 14–16px`. Default: white background, `#e2e8f0` border, `#475569` text. Active: solid `#2563eb` background, white text. Hover: blue border, blue text. Used for scoping search results and filtering activity history.

### Manager/Person Row
Three-column layout: avatar (44px circle, 2px border) → info column (name semibold 15px, meta 12px muted, mutual connections 11px muted with icon) → trailing action button. The trailing button is either a hollow "Connect" pill (`border: 1.5px solid #2563eb`, blue text) or a filled "Connected" pill (gray background, gray text, green check-circle icon).

### Cards
- **White card (analytics/admin):** `border-radius: 16–20px`, white, subtle border, light shadow. Header: title (15px, bold) + small purple link ("See all", "Detail").
- **Event card:** Two-column layout with a calendar block (month in blue header, day number 18px bold) and event info. Status pills embedded: virtual (green), attending (blue), upcoming (amber).
- **Activity/timeline card:** Left-side 3px colored accent bar (color coded by type), icon badge (36×36px rounded square), description text, mini linked card, emoji reaction strip, timestamp.
- **Metric card:** Icon badge (tinted square, 38px) + change delta badge (green/red with trend icon) + large number + label.

### Toggle Switches
Native-style toggle: 44–51px wide, 26–31px tall, `border-radius: 999px`. Off: gray track `rgba(120,120,128,0.3)`. On: `#2563eb` (main app) or `#34c759` (iOS Settings screen). Thumb: white circle with shadow, spring-animated translate.

### Buttons — Primary CTA
Full-width pill or rect buttons at the bottom of form screens: `height: 48–52px`, `border-radius: 14px`, dark navy/blue fill (`#1e3a8a` or `#2563eb`), white text, 16px semibold. Hover lifts (`translateY(-2px)`) with enhanced box-shadow.

### Status Pills / Badges
Small inline pills: `border-radius: 999px`, `padding: 2–4px 7–9px`, `font-size: 10–12px`, `font-weight: 600–700`. Color variants: green (`#ecfdf5` bg, `#059669` text), blue (`#eff6ff` bg, `#2563eb` text), amber (`#fef3c7` bg, `#d97706` text), red (`#fee2e2` bg, `#dc2626` text), gray (neutral bg).

### Segmented Controls
Small pill-within-pill: outer container is `rgba(120,120,128,0.12)` background with `border-radius: 9–10px`, inner active segment is white with `box-shadow: 0 1px 3–4px rgba(0,0,0,0.1–0.12)`. Used for theme selection (Light / System / Dark) and comment sorting (Top / Recent).

### Context Menu
White card, `border-radius: 16–20px`, `box-shadow: 0 20–25px rgba(0,0,0,0.08)`, appears with a scale + translateY entrance animation. Items: icon + label, 13px medium, 13px padding. Danger actions use red text and red icon. Separated by 1px hairline dividers.

### iOS Settings Rows
Standard grouped list rows: 54px minimum height, `padding: 0 16px`. Leading colored icon (30×30px, `border-radius: 8px`) + label (17px regular) + trailing value (15px muted) or toggle + chevron. Inter-row separator starts at `left: 52px` (icon width + gap), creating the standard indented iOS appearance.

---

## Imagery and Iconography

**Iconography:** Phosphor Icons (`ph` class prefix) throughout — a consistent outlined/filled icon library. Common icons: `ph-magnifying-glass`, `ph-users`, `ph-bell`, `ph-house`, `ph-chart-line`, `ph-caret-right`, `ph-star`, `ph-trophy`, `ph-calendar-blank`, `ph-hand-heart`, `ph-check-circle`. Icon sizes range from 10px (inline badges) to 22px (navigation), with 18–20px most common for actions. Icons in buttons and badges are colored to match the component's theme (white on solid fills, tinted on subtle backgrounds).

**Avatar imagery:** Circular crops at 28–44px. Real photos used for specific named profiles. Fallback initials avatars use diagonal gradient fills with two-letter monograms in white, 600 weight. A green/gray/red presence dot appears at bottom-right for online/offline/busy states.

**Photography (Media Viewer):** Full-bleed editorial imagery covers the entire viewport with top and bottom gradient overlays for legibility. Photos convey professional, social, and editorial contexts.

**Charts:** D3-rendered SVGs — smooth Catmull-Rom curves for line charts, grouped bars, heatmap grid cells (square, `border-radius: 5px`), horizontal bar fills with gradient (amber, blue, purple, orange, green). All charts use the same warm-gray grid lines (`#efefea`) and warm-muted axis labels (`#a8a89e`).

---

## Voice and Tone

The copy is confident, direct, and human — professional without being stiff. It uses action-first phrasing, brief descriptions, and specific numbers to establish trust and orient users quickly. Emojis appear occasionally in user-generated content to signal warmth. Admin-facing copy adopts a more formal, action-oriented register.

**Representative phrases:**

- *"Search managers, posts, events…"* — inviting, concrete, no friction
- *"Outstanding leadership on Sprint 12"* — specific, celebratory, colleague-to-colleague warmth
- *"Unlock advanced analytics & AI insights"* — aspirational, benefit-forward, mild urgency without hype
- *"Will be delivered immediately upon publishing"* — clear, transactional, no ambiguity about what happens next