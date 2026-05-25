# Music Player — Final Interaction & Visual Spec

*Version 2.0 — Handoff document. Feed this to Cursor / any LLM to rebuild from scratch.*

---

## 1. Concept

A music player that looks and feels like a **Samsung Z Flip / MIST-style flip phone**, held vertically.
The device is a white/silver physical shell split into two halves by a visible hinge.
- **Top half** — dark OLED screen showing the spinning CD disc
- **Bottom half** — dark control pad with physical-feeling buttons

The bottom control half can **physically slide down** (drag-gesture) to reveal a record crate underneath, where you scroll horizontally through discs and pick one. Selecting a disc loads it onto the top panel and starts playback.

---

## 2. Device Shell

### Visual

| Property | Value |
|----------|-------|
| Outer shape | Rounded rectangle, `border-radius: 52px` |
| Shell background | White-silver gradient: `linear-gradient(165deg, #F0F0F0, #D0D0D0)` |
| Shell shadow | Multi-layer box-shadow simulating physical depth |
| Overall size | `min(390px, 100vw)` × `min(844px, 100dvh)` |

### Structural zones

```
┌─────────────────────────────────────────────────────┐
│  [pill notch — 50px tall, centred, grey pill]       │ ← phone top area (white)
├──────────────────────────────────────────────┐      │
│  TOP PANEL (54% of inner height)             │  9px │ ← side bezel (white shows)
│  dark screen, border-radius: 24px top        │ side │
│                                              │      │
├─────────────────── HINGE (12px) ─────────────┤      │
│  BOTTOM WRAPPER (remaining height)           │      │
│  border-radius: 4px top, 20px bottom         │      │
└──────────────────────────────────────────────┘      │
│  [18px white home indicator area at bottom]         │
└─────────────────────────────────────────────────────┘
```

### Layout implementation note

Use a `#device-shell` (white gradient, full dimensions, `overflow: hidden`) containing a `#device-inner` that is `calc(100% - 18px)` wide and `calc(100% - 68px)` tall (50px notch zone at top + 18px home area at bottom). The `#device-inner` is a vertical flexbox holding `#top-panel` (54%), `#hinge` (12px), and `#bottom-wrapper` (remaining). The 9px side margins of `#device-inner` let the white shell show through on both sides.

---

## 3. Top Panel — CD Display

### Background
- Pure black (`#000`)
- Vertical CRT scanline overlay: `repeating-linear-gradient(90deg, transparent 0 2px, rgba(0,0,0,0.10) 2px 4px)` at 100% opacity, `pointer-events: none`, z-index 2

### Brand strip
- 26px tall bar at top of panel
- Background: `#0a0a0a`, border-bottom: 1px `#1e1e1e`
- Left: app name in `8px, letter-spacing: 0.28em, color: #444, uppercase`
- Right: 5×5px status LED dot (`#2a2a2a` idle → `#e05a00` glow when playing)

### The CD Disc

Centred in the panel. The disc is **180–210pt in diameter**. A plain dark disc placeholder is used in code; the developer will swap it for the final SVG or PNG art.

**Placeholder disc layers (bottom to top):**

1. Base circle — `#0e0e0e` fill
2. 6 concentric track rings — `rgba(255,255,255,0.04)` stroke, 0.5pt wide, at radii 94%, 87%, 80%, 73%, 65%, 57% of disc radius
3. Center label — 38pt radius circle, dark purple radial gradient (`#1a0f35 → #0a0518`), 1px `rgba(255,255,255,0.08)` stroke
4. Specular highlight — off-center radial gradient (`rgba(255,255,255,0.22) → transparent`) centred at 35%/30%
5. Rim stroke — `rgba(255,255,255,0.18)`, 1.5pt
6. Center spindle hole — 6.5pt radius, `#000`, `rgba(255,255,255,0.18)` stroke

**The entire disc element rotates** via CSS `transform: rotate(Ndeg)` (updated in rAF loop).

When playing: rotation increments +0.35°/frame.
When paused: rotation stops at current angle.
Glow shadow on the disc intensifies when playing: `0 0 32px rgba(100,50,150,0.3)`.

**Swapping in custom disc art:** The developer sets the disc to `background-image: url('disc.svg')` or replaces the placeholder SVG node with a custom one. No code change needed.

### CD Skins

Four visual modes, selected from the bottom panel skin buttons. The skin only affects the disc face appearance — structure and interaction are identical.

| Skin | Visual |
|------|--------|
| **NORMAL** | Iridescent rotating rainbow (conic gradient approximated with arc segments), counter-rotating white glint overlay |
| **LED** | 8 neon arc segments around outer ring, each a different hue with bloom/glow. Hues shift over time. Dark inner with bloom at centre |
| **CRT** | Green phosphor tint, horizontal scanlines drawn across disc face, monochrome green angular gradient |
| **VINYL** | Matte black. Dense concentric groove rings (every 2.5% of radius). No rainbow. Subtle single rotating glint. Large 44pt center label |

Skin change triggers a brief white-flash overlay (0.4s fade) on the top panel to simulate a "disc swap."

### Scratch Interaction

The disc is the scratcher. The user drags on it to spin it manually.

**How it works:**
1. On touch/pointer down: record `atan2(clientY - discCenterY, clientX - discCenterX)` as `startAngle`
2. On move: compute new angle, delta = `newAngle - prevAngle` (wrap ±180°). Add delta to `discRotation`
3. Track angular velocity: `velocity = delta / dt * 16`
4. On release: if playing, transfer `velocity` to the auto-rotation velocity, then decay back to `0.35°/frame` over ~60 frames

**Visual feedback:**
- `cursor: grabbing` during scratch
- "SCRATCH" label (bottom-right of top panel) turns orange (`#e05a00`) while active
- Ripple rings (`border: 1px solid rgba(224,90,0,0.5)`) spawn at disc centre and pulse outward if `|delta| > 4°`
- Shimmer phase accelerates proportional to `|delta|` (disc looks more alive when scratched fast)

### Tonearm

SVG positioned top-right of screen, pivoting from top-right corner.
- Resting angle: −8°
- Playing: rotates from −8° to +14° over full track (maps to `progress * 22deg`)
- During scratch: angle nudges by `scratchVel * 0.5`
- When crate is open: tonearm rotates to ~35° and fades to 25% opacity
- Transition: `0.4s ease`

### Track info

Two text lines centred below the disc:
- Title: `13px, weight 500, #d8d8d8, letter-spacing 0.02em`, truncated with ellipsis
- Meta (Artist · Album): `10px, #484848, letter-spacing 0.04em`
- When playing: an animated 3-bar EQ icon (bars bounce up/down alternately) appears left of the title

---

## 4. Hinge

12px tall full-width bar between the two panels.

- Background: `linear-gradient(to bottom, #B0B0B0, #C4C4C4, #B8B8B8)`
- Top edge: subtle light line `rgba(255,255,255,0.5)` for reflection
- Bottom edge: subtle shadow line `rgba(0,0,0,0.08)`
- Two thin horizontal highlight lines run across the middle, inset 10% from each side, simulating machined metal

---

## 5. Bottom Wrapper

The `#bottom-wrapper` is the container that holds both the **control panel** and the **crate section**. It has `overflow: hidden` and `position: relative`.

- Background: `#0e0e0e` (slightly darker than control panel so the crate is visible behind it as a different tone)
- `border-radius: 4px 4px 20px 20px`

Inside it are two **absolutely positioned** layers:
1. `#crate-section` — z-index 1, always present behind
2. `#bottom-panel` — z-index 2, slides DOWN when crate opens

---

## 6. Bottom Panel — Controls

### Drag Handle

- 20px tall strip at the very top of the bottom panel
- Background: `#181818`, border-bottom: `1px solid #242424`
- A centred 34×3px dark grey capsule (`#383838`) visually indicates "drag me"
- `cursor: grab`

**Gesture:** Touch/mouse down on handle + drag downward. Panel follows finger live. Release above 55px threshold → snaps back. Release below 55px threshold → panel slides fully down, revealing crate. Transition on snap: `0.45s cubic-bezier(0.34, 1.15, 0.64, 1)` (spring-like).

### 1. Seek Bar

Full-width horizontal scrubber, 3px tall track.

- Track: `#2a2a2a` rounded
- Fill: gradient `#6030d0 → #30a0d0` (purple → cyan) from left to progress point
- Thumb: 10pt white circle with soft glow shadow
- Drag anywhere on bar to seek. `pointermove` while `buttons > 0` for live drag.

### 2. Main Control Row

D-pad on the left, 2×2 pill buttons on the right, in a horizontal flex row.

#### D-pad (left)

92×92pt circular dark button cluster.

- Circle background: `#141414`, border: `1px solid #262626`, inset shadow for depth
- Four directional buttons in a cross: ▲ ▼ ◄ ►
- Centre decorative dot: 11pt, `#242424`
- A volume arc (SVG circle stroke) traces the perimeter, fill proportion = current volume, orange `#e05a00`

| Direction | Action |
|-----------|--------|
| ▲ Up | Volume +10% |
| ▼ Down | Volume −10% |
| ◄ Left | Restart track (or prev if < 3s played) |
| ► Right | Skip to next track |

#### 2×2 Pill Buttons (right)

Four `border-radius: 20px` rounded buttons, each 44pt tall, in a 2-col 2-row grid with 7px gap.

Each pill has:
- Solid colour fill
- Vertical scanline texture overlay (6%)
- Top-edge white sheen gradient (0% → 40% height)
- Spring press: `scale(0.92)` on active, `filter: brightness(0.86)`
- Coloured glow box-shadow when active; `filter: brightness(0.32)` when inactive (shuffle/repeat only)

| Position | Colour | Hex | Icon | Action |
|----------|--------|-----|------|--------|
| Top-left | Orange | `#c77a1a` | ▶ / ⏸ | Play / Pause |
| Top-right | Red | `#b81f24` | ⏭ | Skip next |
| Bottom-left | Blue | `#1f45b8` | ⇄ | Toggle shuffle |
| Bottom-right | Green | `#147028` | ↺ / ➀ | Cycle repeat (off → all → one) |

### 3. Info Row

Three elements in a horizontal row below the main controls:

| Zone | Content |
|------|---------|
| Left | Current playback time `M:SS`, `11px, tabular-nums, #484848` |
| Centre | Volume indicator: small ◁ icon + thin 2px bar (fill `#444`, track `#242424`) + ▷ icon |
| Right | "Library" chip: small pill button `⊞ Library`, opens library sheet |

### 4. Skin Selector

Four equal-width rounded-rectangle tab buttons in a row (30px tall, `border-radius: 7px`):

`NORMAL` · `LED` · `CRT` · `VINYL`

- Inactive: `background: #1e1e1e`, `color: #484848`, `border: 1px solid #282828`
- Active: `background: #d99a1a` (gold/yellow), `color: #1a0f00`, matching glow shadow

Tapping a skin button immediately updates the disc visual with the shimmer-boost + white-flash transition.

### 5. Bottom Navigation Bar

Three zones in a flex row, `border-top: 1px solid #202020`, 14px bottom padding:

| Zone | Content |
|------|---------|
| Left | AirPlay button (`⊞ AirPlay`, `8px uppercase grey`) |
| Centre | 5 track position dots — active dot is white and 14px wide, others grey 5px wide; spring-animates on track change |
| Right | Settings trigger (`⚙ Settings`) |

---

## 7. Crate — Horizontal Disc Scroll

The crate fills the same space as the bottom panel (`#bottom-wrapper`, `position: absolute, inset: 0`). It is always rendered behind the bottom panel and revealed when the panel slides down.

### Opening

1. User grabs the drag handle and pulls down past 55px threshold
2. Bottom panel animates `translateY(100%)` with spring easing
3. Crate becomes visible — the tonearm on the top panel tilts away (35°, 25% opacity)

### Layout

```
┌──────────────────────────────────────────────────────┐
│  CRATE  [label]                              [✕]     │  ← 32px header
├──────────────────────────────────────────────────────┤
│                                                      │
│  ← scroll  [ disc ]  [ disc ]  [ disc ]  [ disc ] →  │  ← horizontal scroll row
│            [title ]  [title ]  [title ]  [title ]    │
│            [artist]  [artist]  [artist]  [artist]    │
│                                                      │
├──────────────────────────────────────────────────────┤
│  Currently selected: Title  ·  SKIN                  │  ← info strip
│  Tap active disc to load ↑                           │  ← hint
└──────────────────────────────────────────────────────┘
```

### Disc Cards

Each card is `flex-shrink: 0`, approximately `90px` wide, in a horizontal `overflow-x: scroll` row.

Each card contains:
- A 74×74pt disc circle (same placeholder style as the main disc, or custom art)
- Title text: `10px, weight 600, white, truncated`
- Artist text: `9px, #555`

**States:**

| State | Visual |
|-------|--------|
| Default | Dark disc, grey text |
| Active (selected) | Disc scales up 1.08×, coloured ring border matching album accent colour, title bold white |
| Tap (first tap) | Navigates to card (makes it active) |
| Tap (on active) | Loads disc onto top panel + starts playback + closes crate |

**Active card ring:** `box-shadow: 0 0 0 2px {albumColour}, 0 4px 16px rgba(0,0,0,0.5)` on the disc circle.

### Disc Card → Top Panel Animation

When a disc is selected (double-tap on active card):
1. Active card scales up to `scale(1.15)` with coloured glow (0.18s spring)
2. White flash fires on top panel canvas (0.4s fade)
3. Disc skin changes to the album's associated skin
4. Track info updates (title + artist)
5. Tonearm swings back to rest position (0.4s)
6. Bottom panel slides back up (`translateY(0)`, spring)
7. Playback starts

### Closing without selecting

- Tap the ✕ button in the crate header
- OR swipe up on the crate area (touch upward > 40px)
- Either closes by sliding the bottom panel back up

### Horizontal scrolling

Native `overflow-x: scroll` with `-webkit-overflow-scrolling: touch`. No snap points — free scroll. No scroll bar visible (`scrollbar-width: none`). Padding `20px` on both sides so first and last cards don't flush against the edge.

---

## 8. Volume HUD

A temporary overlay that appears in the centre of the top panel when volume changes.

- Container: `background: rgba(0,0,0,0.88)`, `border-radius: 14px`, `backdrop-filter: blur(8px)`, `border: 1px solid #2a2a2a`
- Contents: "VOLUME" label (8px uppercase grey) + large number (28px weight 300 `#e0e0e0`) + thin progress bar
- Appears for 1.5s then fades out
- Triggered by: D-pad up/down AND hardware volume button presses (via `volumechange` event on a silent `<audio>` element — iOS only)

---

## 9. Settings Sheet (not yet implemented in HTML prototype)

Slides up from the bottom, over the control panel. CD display remains visible above.

```
─── (drag handle capsule)

Skin
[ NORMAL ] [ LED ] [ CRT ] [ VINYL ]   ← gold = active

Sound      Haptic
 [✓]        [✓]

[ Clear Queue ]

──────────────────────────────────
Player 1.0                Terms  Privacy
```

- Backdrop: semi-transparent dark overlay, tap to dismiss
- Skin buttons: identical style to bottom-panel skin row
- Sound/Haptic: 52×38pt rounded squares, checkmark = active, × = inactive
- Footer: full-width `#0d0d0d` bar, app version left, links right

---

## 10. Library Sheet (not yet implemented in HTML prototype)

System-style bottom sheet (iOS detent: half or full).

```
Library                  [Songs ▾]  [✕]
[ 🔍 Search songs, artists, albums… ]
──────────────────────────────────────
[art]  Track Title                3:42
       Artist Name

[art]  Track Title                4:11
       Artist Name
```

- Rows: 44×44pt thumbnail + title (bold if playing) + artist + duration right
- Playing row: duration replaced by animated 3-bar EQ icon
- Tap row → loads track, dismisses sheet

---

## 11. Physical Interactions

| Trigger | Effect |
|---------|--------|
| Hardware volume buttons (iOS) | `volumechange` fires on silent `<audio>` probe. Captures new value, updates volume bar + shows HUD |
| Device tilt (DeviceOrientation API) | `gamma` (left/right tilt −30° to +30°) shifts `shimmerPhase` by ±0.8/frame, making the disc shimmer in response to the angle of light |
| Power-LED brightness | When tilted, power LED glow radius scales proportionally |

---

## 12. Animation Summary

| Interaction | Animation |
|-------------|-----------|
| Play starts | CD rotates, glow shadow fades in (0.6s ease-in-out), power LED glows |
| Play pauses | CD freezes, glow fades out |
| Skin change | White flash on top panel (0.4s fade), shimmer phase boost +60° |
| Pill button tap | `scale(0.92)` + `brightness(0.86)` spring back (0.12s) |
| Drag handle pull | Panel `translateY` follows finger in real-time (`transition: none`) |
| Panel open | `translateY(100%)` with spring `cubic-bezier(0.34, 1.15, 0.64, 1)`, 0.45s |
| Panel close | Same spring back to `translateY(0)` |
| Tonearm (playing) | Rotates from −8° to +14° proportional to progress |
| Tonearm (crate open) | Rotates to 35° and fades to 25% opacity (0.4s) |
| Track dots | Active dot expands to 14px, spring 0.3s |
| Card select | `scale(1.15)` + glow, 0.18s spring |
| Scratch ripple | Circle spawns at disc centre, scales to 1.4× and fades (0.4s) |

---

## 13. Colour Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Shell Light | `#F0F0F0` | Device shell top |
| Shell Mid | `#D0D0D0` | Device shell gradient end |
| Notch | `#C4C4C4` | Pill notch |
| Screen BG | `#000000` | Top panel background |
| Surface | `#1c1c1c` | Bottom panel background |
| Crate BG | `#0c0c0c` | Crate section background |
| Hinge | `#B8B8B8` | Hinge bar |
| Text Primary | `#D8D8D8` | Track title |
| Text Secondary | `#484848` | Artist, time labels |
| Text Muted | `#383838` | Nav bar items |
| Orange | `#C77A1A` | Play/Pause pill |
| Red | `#B81F24` | Skip pill |
| Blue | `#1F45B8` | Shuffle pill |
| Green | `#147028` | Repeat pill |
| Gold Active | `#D99A1A` | Active skin chip |
| Seek Start | `hsl(266,82%,40%)` | Purple end of seek gradient |
| Seek End | `hsl(200,70%,42%)` | Cyan end of seek gradient |
| Accent Orange | `#E05A00` | D-pad active, vol arc, scratch label |

---

## 14. Typography

All text uses **system monospaced** font (`'Helvetica Neue', Helvetica, Arial, sans-serif` as fallback; use `font-family: 'SF Mono', ui-monospace, monospace` in the Swift app).

| Role | Size | Weight | Colour |
|------|------|--------|--------|
| Track title | 13px | 500 | `#D8D8D8` |
| Artist / album | 10px | 400 | `#484848` |
| Time stamps | 10–11px | 400 tabular | `#484848` |
| Skin buttons | 8px | 700 | `#484848` / `#1a0f00` |
| Nav bar | 8px | 400 | `#383838` |
| Brand strip | 8px | 700 | `#444` |
| Crate header | 7px | 700 | `#555` |
| Crate card title | 10px | 600 | `rgba(255,255,255,0.85)` |
| Crate card artist | 9px | 400 | `#555` |

---

## 15. What This App Does NOT Have (intentional)

- No light mode
- No lyrics panel
- No equaliser
- No playlist creation (library is browse + play only)
- No album art fullscreen view
- No lock screen artwork (no `MPNowPlayingInfoCenter` implementation in prototype)
- No cross-fade between tracks

---

## 16. Custom Disc Art Integration

The placeholder disc is an SVG or `<div>` with CSS. To swap in real art:

**HTML approach:** Replace the `<svg id="disc">` element with your custom SVG. The element must:
- Be `210×210px`
- Have `border-radius: 50%` (or be a circle shape)
- Be able to receive `transform: rotate(Ndeg)` CSS (set by the rAF loop)
- Have `touch-action: none` and `cursor: grab` for scratch interaction
- Have `pointer-events: all`

**iOS Swift approach:** Set `CDDiscView` to render the custom image as the `centerLabel` artwork layer (76pt circle), keeping all the skin overlays on top.

---

## 17. File Structure (HTML prototype)

```
player.html           — single self-contained file
  ├─ <style>          — all CSS (device shell, panels, crate, animations)
  ├─ <body>
  │   ├─ #device-shell        — white outer frame
  │   │   ├─ #phone-pill      — notch overlay
  │   │   └─ #device-inner    — flex column content area
  │   │       ├─ #top-panel   — CD display
  │   │       ├─ #hinge       — separator
  │   │       └─ #bottom-wrapper — overflow:hidden container
  │   │           ├─ #crate-section  — z:1, always present
  │   │           └─ #bottom-panel   — z:2, slides down
  └─ <script>
      ├─ state {}               — all player state
      ├─ drawDisc()             — canvas / SVG disc rendering
      ├─ loop()                 — rAF animation loop
      ├─ scratch handlers       — pointer/touch events on disc
      ├─ seek bar handlers
      ├─ playback controls
      ├─ volume + HUD
      ├─ skin selector
      ├─ device orientation
      ├─ drag handle → open/close crate
      └─ crate: build / navigate / select
```
