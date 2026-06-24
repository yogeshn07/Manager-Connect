# Feed Rebuild Analysis — V0 Screenshots

## Screenshot Inventory

| # | File | Content |
|---|------|---------|
| 1 | 072603.png | Top bar + Stories rail + Composer + Trending header + Recognition card (top half) |
| 2 | 072610.png | Poll card (full) + Achievement card (top half) |
| 3 | 072615.png | Achievement card (bottom) + Event card (top half) |
| 4 | 072622.png | Event card (bottom) + Plain post + End-of-feed + Bottom nav |

## Layout Hierarchy (top to bottom)

1. **Top Bar** — logo gem + title/subtitle + search + bell
2. **Stories Rail** — horizontal scroll, 6 circular photo avatars, LIVE badges
3. **Composer** — photo avatar + rounded pill input + 4 quick-action icons with labels
4. **Section Header** — fire icon + "Trending in your org" + "Recent"
5. **Recognition Card** — dark banner + recognized person inset + body text
6. **Poll Card** — author row with POLL pill + question + 4 option rows + stats + engagement + action row
7. **Achievement Card** — author row with ACHIEVEMENT pill + bold title + body + metric inset (99.99%) + engagement + action row
8. **Event Card** — author row with EVENT pill + hero image strip (dark bg + photo + date badge + title) + meta + avatar stack + capacity bar + RSVP button + engagement + action row
9. **Plain Post** — author row + body text + engagement + action row
10. **End Indicator** — "You're all caught up · 5 of 5 posts"
11. **Bottom Nav** — 5 tabs with labels: Home, Explore, center trophy, Events, Profile

## Key Visual Observations

### Top Bar
- Teal/dark-green rounded-square gem icon (~33px)
- "Manager Connect" in medium weight (~15px)
- "Leadership community" in light gray (~10px)
- Search icon + Bell icon (right side)
- White background, thin bottom border

### Stories Rail
- Real circular photos (~52px outer), not initials
- 2.5px colored ring (active = dark teal, inactive = gray)
- LIVE badge: red pill, white text, positioned at bottom of circle
- "You" avatar has gray ring + white "+" circle overlay bottom-right
- Name label below each (~10px, gray)
- Horizontal scrollable, ~8px gap between items

### Composer
- White card, rounded corners (~14px)
- Row 1: circular photo avatar (~36px) + pill-shaped input field (#F4F5F7 bg, ~22px radius)
- Row 2: 4 action buttons evenly spaced
  - Each: colored square icon tile (~32px, ~9px radius) + label below (~9px)
  - Colors: teal (Share Update), amber (Recognition), purple (Poll), coral/teal (Event)

### Post Card Shared Structure
- White card, ~14px radius, thin border
- Author row: ~44px circular photo + name (medium ~14px) + optional TYPE PILL + role (~11px gray) + timestamp (~10px gray + globe icon) + "..." menu
- Body text: ~13px regular weight, good line height
- Engagement row: stacked reaction circles (3 types, ~20px, overlapping) + count + "N comments · N reposts"
- Action row: 4 equal columns with thin vertical dividers — sparkle icon, comment icon, repost icon, send icon

### Recognition Card Specific
- Dark teal banner header (#085041 or similar): trophy icon (amber) + "LEADER OF THE MONTH" (small caps white)
- Gray inset box (#F4F5F7): ~44px avatar + "RECOGNIZED" label (small caps) + Name (~16px medium) + Role (~11px) 
- Body text below inset

### Poll Card Specific
- "POLL" pill (teal fill, dark text)
- Question text bold/medium (~15px)
- 4 option rows: rounded rectangles with thin border, text left-aligned (~13px)
- Stats row: people icon + "895 votes" + clock icon + "2 days left"

### Achievement Card Specific
- "ACHIEVEMENT" pill (teal fill)
- Bold title (~15-16px medium)
- Body text
- Metric inset: teal circular ring (~54px) with "99.99%" center + "Uptime · 6 months" label + green "Verified" badge

### Event Card Specific
- "EVENT" pill (teal fill)
- Hero image strip (~110px): dark photo overlay, date badge top-left (red month + large day), title white text bottom
- Meta below: calendar + "Thu, Jul 9 · 10:00 AM" + location pin + venue
- Avatar stack (overlapping circular photos) + green count badge + "184/250 going"
- Green progress bar (capacity)
- Full-width teal "RSVP — Save my spot" button (pill shape)

### Bottom Navigation
- 5 tabs WITH text labels: Home, Explore, center raised trophy icon, Events, Profile
- Active: teal color, filled icon
- Inactive: gray
- Center tab has elevated circular background (trophy/challenges)
- White background, thin top border

### Colors Observed
- Primary brand: dark teal (#0C447C or #085041 range)
- Active/CTA: teal-green
- Recognition: amber/gold accents
- LIVE badge: red
- Background: light gray (#F4F5F7)
- Cards: white
- Text primary: near-black
- Text secondary: medium gray
- Text tertiary: light gray

### Typography
- Weights appear to be regular (400) and medium (500) only
- No bold/heavy weights visible
- Clean sans-serif (Inter-like)
