# Music Player — Full Interaction & UI Specification
**Version 1.0 — Feed this to your builder**

---

## 1. Concept

A music player styled as a **Samsung Z Flip-style flip phone**, split into two physical panels by a visible hinge. The aesthetic is **Braun / Dieter Rams** — dark anthracite, functional typography, no decoration that isn't also a control. It behaves like a physical object you're holding, not a software screen.

The top panel is a display screen. The bottom panel is a hardware control surface. They feel like different materials.

---

## 2. Overall Layout

```
┌──────────────────────────────────────┐
│  [brand strip — 28px tall]           │
│                                      │
│         [ CD DISC ]                  │  ← top panel: 54% of screen height
│                                      │
│      Track Title                     │
│      Artist  ·  Album                │
│                                      │
│  ↓↓↓  (swipe-down hint)              │
├══════════════════════════════════════╡  ← hinge: 10px
│  ──────── seek bar ────────────      │
│                                      │
│  [ D-PAD ]    [ ▶ ]  [ ⏭ ]          │  ← bottom panel: 46% minus hinge
│               [ ⇄ ]  [ ↺ ]          │
│                                      │
│  0:47  [vol bar]  [Library]          │
│                                      │
│  [NORMAL] [LED] [CRT] [VINYL]        │
│                                      │
│  [AirPlay]  ●●●●●  [Settings]        │
└──────────────────────────────────────┘
```

**Device shell**: dark anthracite `#1C1C1C`, border-radius 20px, drop shadow.  
**Screen width**: 390px max (phone-width). Full viewport height.

---

## 3. Top Panel

### 3a. Brand Strip
- **Height**: 28px. Always visible at top of device.
- **Background**: `#161616`
- **Border-bottom**: 1px `#2A2A2A`
- **Left**: Text label `"Player"` — 9px, weight 700, letter-spacing 0.25em, uppercase, color `#555`
- **Right**: Power LED — 5px circle
  - Off state: `#333` (dim grey)
  - Playing state: `#E05A00` orange with glow shadow `0 0 6px #E05A00, 0 0 12px rgba(224,90,0,0.4)`
  - Transitions smoothly between states over 0.4s

### 3b. Tonearm
- Positioned absolute: top-right of display area
- SVG drawing: a curved line from a pivot point (top-right) sweeping down-left toward the CD edge
- Has an orange dot at the needle tip
- **At rest**: rotated ~−8deg from vertical
- **During playback**: sweeps inward as progress increases — at 100% it's ~14deg further inward
- **During scratch**: jitters ±2–3deg based on scratch velocity
- **Crate open**: rotates far out (35deg) and fades to 30% opacity, as if lifting away
- Transition: 0.3s ease (0s during scratch — instant response)

### 3c. CD Disc
**Size**: 218 × 218pt, circular canvas element. Centered horizontally in the panel.  
**Touch target**: the canvas itself. Touching the canvas = scratch interaction (see §7).  
**Glow shadow** when playing: `0 0 32px rgba(112,48,176,0.45)` — colour varies by skin.

The disc has these layers (bottom to top):

| Layer | Description |
|-------|-------------|
| Base | Near-black circle fill |
| Iridescent | Rotating conic gradient, full rainbow spectrum — blended `screen` |
| Glint | Counter-rotating white spoke gradient — blended `overlay`, 55% opacity |
| Specular | Off-centre radial gradient (top-left), single bright reflection point |
| Track rings | 6 concentric strokes at radii 94%, 87%, 80%, 73%, 65%, 57% — white 4.5% opacity |
| Center label | 76pt circle — dark purple gradient or album artwork if available |
| Spindle hole | 13pt black circle, thin stroke |
| Rim | Full-circle stroke, white 20% opacity |

**Rotation during playback**: +0.35° per animation frame (60fps).  
**Shimmer phase during playback**: +0.7 units per frame (shifts the rainbow hue continuously).  
**When paused**: rotation and shimmer freeze at their current values.  
**Skin changes**: cross-fade over 0.4s ease-in-out.  
**Glow intensity**: animates between dim (paused) and bright (playing) over 0.6s ease-in-out.

---

## 4. CD Skins (4 total)

Switching skin changes only the visual rendering of the disc. Layout, size, and interactions are identical across all skins.

### NORMAL
- Full-spectrum iridescent rainbow conic gradient.
- 48 arc segments each filled with `hsl(phase + n/48 * 360, 88%, 52%)`.
- Blended `screen` over dark base.
- Counter-rotating white glint spokes (6 segments, alternating 55%/18% opacity).
- Off-centre specular highlight (top-left zone, radial gradient).
- Glow shadow: purple `rgba(112,48,176,0.45)`.

### LED
- Dark black base.
- 8 neon arc segments around the outer ring (like RGB LEDs).
- Each segment: arc from `R−7`, lineWidth 9, rounded linecap.
- Each segment's hue: `(shimmerPhase + i/8 * 360) % 360`.
- Heavy glow/bloom: `shadowBlur 14`, shadow colour matches segment hue.
- Segments rotate with playback at half the CD rotation speed.
- Inner radial bloom glow in center (screen blend).
- Glow shadow: cyan `rgba(0,200,220,0.45)`.

### CRT
- Dark green-black base `#030A03`.
- Green phosphor glow: angular gradient of green shades rotating with disc.
- **Horizontal scanlines** drawn across the disc face: 1.5px black stripes every 3px, 40% opacity.
- Off-centre specular but green-tinted `rgba(100,255,120,0.28)`.
- Entire disc gets a green colour multiply.
- Track rings tinted green `rgba(0,255,50,0.07)`.
- Glow shadow: green `rgba(0,200,50,0.45)`.

### VINYL
- Matte near-black base `#080808`.
- **Dense groove rings**: concentric circles from radius 42% to 96%, stepping every 2.5%, stroke 0.4px white 9% opacity.
- No rainbow shimmer.
- Subtle rotating glint: 4 thin white arc spokes (screen blend).
- **Large center label** (44pt radius instead of 38pt) for more prominent label area.
- Label background: dark purple gradient.
- Album artwork fills the center if available.
- Glow shadow: dim grey, very subtle.

---

## 5. Track Info

Below the CD disc, centred, padding 0 28px.

- **Line 1 — Track title**: 14px, weight 500, `#D8D8D8`, truncate with ellipsis.
  - When playing: a small animated EQ indicator (3 bars bouncing) appears to the left.
  - The 3 bars animate independently with slight delays (0s, 0.15s, 0.08s).
  - Each bar oscillates between 3px and 10px height, duration 0.5s, alternate direction.
- **Line 2 — Artist · Album**: 10px, `#555`, letter-spacing 0.04em.

### Swipe-Down Hint
Three short horizontal lines stacked vertically, centered at the bottom of the top panel.
- Sizes (top to bottom): 20px wide, 14px wide, 9px wide.
- Opacity increasing downward (50%, 75%, 100%).
- Entire group: 28% opacity, animated bobbing (0→4px→0 translateY, 2.8s ease-in-out infinite).
- Hidden (opacity 0) when crate is open.

### CRT Scanline Overlay
A CSS `repeating-linear-gradient` of vertical stripes sits over the entire top panel:  
`repeating-linear-gradient(90deg, transparent 0px, transparent 2px, rgba(0,0,0,0.12) 2px, rgba(0,0,0,0.12) 4px)`  
pointer-events: none. Always on.

---

## 6. Hinge

10px tall bar between panels.

- Background: `#181818`
- Top pseudo-element: 1px line, `linear-gradient(90deg, transparent, #3A3A3A 20%, #3A3A3A 80%, transparent)`, 3px from top
- Bottom pseudo-element: 1px line, `#262626`, 3px from bottom
- Together these simulate a physical hinge reflection catching light

---

## 7. Scratch Interaction

**Touch/drag directly on the CD canvas.**

**How it works:**
1. `pointerdown` on canvas → record the angle of the touch relative to the disc center `atan2(y - cy, x - cx)`.
2. `pointermove` → calculate delta angle from last position. Apply delta directly to `state.rotation`. Also increment shimmer phase by `abs(delta) * 1.5` (shimmer intensifies when scratching fast).
3. `pointerup` or `pointerleave` → end scratch. Hand off momentum: set playback velocity to the calculated scratch velocity, then decay it back to normal (0.35°/frame) over ~60 frames using lerp factor 0.04.
4. Scratch velocity = `angleDelta / timeDelta * 16` (normalised to per-frame units).

**Visual feedback during scratch:**
- **Scratch ring**: when `abs(angleDelta) > 4°`, spawn a `div` positioned at the disc center. Animate it from `scale(0)` to `scale(1.4)` while fading to opacity 0, over 0.4s. Border: 1px solid `rgba(224,90,0,0.5)`. Remove on animation end. Multiple rings can stack.
- **Scratch label**: text `"SCRATCH"` in the bottom-right of the display — glows orange `#E05A00` during active scratch, grey `#333` at rest.
- **Tonearm**: jitters ±2–3deg based on `scratchVelocity * 0.5`.

**Angle delta wrap-around correction**: if delta > 180°, subtract 360°. If delta < −180°, add 360°. This prevents the disc from spinning wildly when crossing the ±180° boundary.

---

## 8. Record Crate

### Opening
**Gesture**: swipe downward on the top panel (outside the canvas).  
- Use `touchstart` on `#top-panel` to record start position.
- Use `touchend` on `document` (not the panel) to check the release — this catches releases even if the finger drifted over the canvas.
- Threshold: `deltaY > 28px` AND `abs(deltaX) < 80px`.
- Also works with mouse: `mousedown` on panel, `mouseup` on `document`.

**Opening animation**:
1. The crate overlay (`position: absolute`, covers the display area below the brand strip) slides up from `translateY(108%)` to `translateY(0)`.
2. Spring easing: `cubic-bezier(0.34, 1.4, 0.64, 1)` — has a slight overshoot bounce. Duration 0.52s.
3. Tonearm rotates to 35deg and fades to 30% opacity simultaneously.
4. Swipe-down hint fades out.

### The Crate Panel Structure (top to bottom)

**Wood-edge strip** (14px tall, top of crate):
- Background: `linear-gradient(to bottom, #2A1F0E, #1A1208)` — warm dark wood tone.
- Border-bottom: 1px `#3A2A14`.
- Left: text `"CRATE"` — 7px, weight 700, letter-spacing 0.22em, uppercase, `#6A4F28`.
- Right: ✕ close button — 11px, `#555`, tapping closes crate with reverse spring animation.

**Carousel stage** (flex: 1, takes remaining space):
- `perspective: 700px` for 3D card depth effect.
- `overflow: hidden` — cards outside the viewport are clipped.
- Cards are draggable left/right (see §8b).

**Now-playing info strip** (below stage):
- Title: 12px, weight 500, `#CCC`.
- Artist: 10px, `#555`.
- Updates immediately when navigating to a different record.

**"Tap record to play"** hint: 8px, letter-spacing 0.18em, uppercase, `#2E2E2E`. Subtle, not loud.

**Drag handle bar** (20px, bottom of crate): a 32×3px capsule `#2A2A2A` centred horizontally. Swiping up here closes the crate.

### Carousel Record Cards

9 records are shown. Each card is 138×148px with 6px gap on each side.

**Card anatomy:**
- **Background**: `#141414`, border-radius 3px, border 1px `#252525`.
- **Vinyl disc peeking above sleeve** (CSS `::before` pseudo-element): an 88px circle positioned `top: −18px`, `left: 50%`. Dark radial gradient `#1E1E1E` → `#080808`. Visible above the sleeve top edge.
- **Sleeve artwork** (fills the card): a unique geometric pattern per record — three styles:
  - *Circles*: 3 concentric ring strokes in the album accent colour, decreasing opacity.
  - *Lines*: 5 horizontal lines at varying widths and opacities.
  - *Grid*: 4 rectangles in a 2×2 arrangement.
  All rendered as inline SVG, very subtle (opacity 10–25%).
- **Vinyl label circle**: 64px circle centred on the sleeve, radial gradient of the album colour at low opacity (18–27%). Has a small 8px centre hole.
- **Track info** at the bottom of the sleeve: gradient fade from transparent to `rgba(0,0,0,0.85)`. Title 9px weight 700, artist 8px `#666`. Both truncate.

**Card classes & 3D positions:**

| Class | Transform | Opacity |
|-------|-----------|---------|
| `rc-active` | `translateY(−10px) scale(1.07)` | 1.0 |
| `rc-adj-l` (−1) | `scale(0.90) rotateY(18deg)` | 0.62 |
| `rc-adj-r` (+1) | `scale(0.90) rotateY(−18deg)` | 0.62 |
| `rc-far-l` (−2) | `translateY(4px) scale(0.78) rotateY(30deg)` | 0.32 |
| `rc-far-r` (+2) | `translateY(4px) scale(0.78) rotateY(−30deg)` | 0.32 |
| `rc-hidden` (±3+) | `scale(0.6)` | 0 |

Active card: vinyl disc pseudo-element shifts to `top: −30px` (rises higher out of sleeve).  
Box shadow on active: `0 12px 40px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.06)`.

**Transition for class changes**: `transform 0.35s cubic-bezier(0.34,1.3,0.64,1), opacity 0.35s ease`.

### Carousel Drag Interaction

Use `touchstart` / `touchmove` / `touchend` on the stage. Mouse events on `document` as desktop fallback.

1. `touchstart`: record `dragStartX`, `dragLastX`. Remove `snapping` class from carousel.
2. `touchmove`: calculate `dx = currentX − lastX`. Add `dx` to `dragOffset`. Set `dragVelocity = dx`. Apply `carousel.style.transform = translateX(dragOffset * 0.55)` — the 0.55 factor gives a rubber-band resistance feel.
3. `touchend`: add `snapping` class back (re-enables CSS transition). Clear inline transform. Evaluate:
   - If `totalDx < −36` OR `dragVelocity < −5` → navigate to `crateIndex + 1`
   - If `totalDx > 36` OR `dragVelocity > 5` → navigate to `crateIndex − 1`
   - Otherwise → snap back to current (just re-layout)

**`snapping` class** adds: `transition: transform 0.38s cubic-bezier(0.34,1.4,0.64,1)`.

### Tapping a Card

- **Tap a non-active card** → navigate to it (sets it as active, re-positions all cards).
- **Tap the active card** → `selectAndClose(index)`:
  1. Active card briefly lifts higher: `translateY(−22px) scale(1.12)` with a coloured glow shadow matching the album accent colour.
  2. After 280ms, crate slides back down with reverse spring.
  3. Track title and artist on the main display update.
  4. If not already playing, playback starts.
  5. Seek resets to 0:00.

### Closing

Three ways to close:
1. Tap ✕ in the wood-edge strip.
2. Swipe up on the crate stage (`deltaY < −40px` on touch).
3. Selecting a record (auto-closes after 280ms).

**Closing animation**: `translateY(0)` → `translateY(108%)`, same spring easing as open. Duration 0.52s.  
Tonearm returns to playing position. Swipe hint fades back in.

---

## 9. Bottom Panel

Background: `#1C1C1C`. Subtle vertical CRT scanlines at 2.5% opacity (same pattern as top panel).  
Internal padding: 12px sides, 0 top.

### 9a. Seek Bar

Full-width row. Left and right labels show `currentTime` and `duration`.

- **Track**: 3px tall, `#2E2E2E`, border-radius 2px.
- **Fill**: gradient left→right: purple `hsl(266,82%,90%)` → cyan `hsl(173,70%,95%)`.
- **Thumb**: 12px white circle, `box-shadow: 0 0 4px rgba(255,255,255,0.5)`.
- **Time labels**: 10px, tabular-nums, monospace, `#555`. Min-width 30px.

**Interaction**: `pointerdown` / `pointermove` on the track.  
`fraction = (event.clientX − rect.left) / rect.width`  
Clamp to [0, 1]. Update `currentTime = fraction × duration` immediately.  
Thumb and fill update in real time while dragging.

### 9b. Main Control Row

Two zones side-by-side with 14px gap.

---

#### D-Pad (left zone, 96×96px)

A dark circle: `#161616` background, 1px border `#2A2A2A`, inset shadow `0 2px 6px rgba(0,0,0,0.6)`.

**Orange arc indicator**: SVG circle behind the buttons. Stroke-dasharray technique: circumference = 226px. Stroke-dashoffset = `226 − (226 × volume)`. Stroke: `#E05A00` at 60% opacity. Updates as volume changes.

**4 arrow buttons** at N/S/E/W positions (28px circle each, absolutely positioned):

| Arrow | Position | Action |
|-------|----------|--------|
| ▲ | top centre | Volume up (+10%) |
| ▼ | bottom centre | Volume down (−10%) |
| ◄ | left centre | Previous track (or restart if >3s in) |
| ► | right centre | Skip to next track |

Button style: no background normally, colour `#555`. On `:active`: colour `#E05A00`, background `rgba(224,90,0,0.08)`.

**Centre dot**: 12px decorative circle, `#2A2A2A` with `#383838` border. Not interactive.

---

#### 2×2 Pill Buttons (right zone)

Grid: 2 columns × 2 rows, 8px gap. Each pill 46px tall.

Each pill has:
- Solid colour fill (see table). Dimmed to 28% when feature is inactive.
- Top-sheen: `linear-gradient(to bottom, rgba(255,255,255,0.14), transparent)` covering top 40%.
- Vertical scanline texture (same repeating-gradient pattern) at 6% opacity, clipped to shape.
- SF Symbol icon centred at 15px weight semibold.
- Box shadow when active: `0 4px 14px [colour at 35–48% opacity]`.

| Position | Colour (hex) | Icon | Action | Active condition |
|----------|-------------|------|--------|-----------------|
| Top-left | `#C77A1A` orange | `play.fill` / `pause.fill` | Toggle play/pause | Always active (never dims) |
| Top-right | `#B81F24` red | `forward.end.fill` | Skip next | Always active |
| Bottom-left | `#1F45B8` blue | `shuffle` | Toggle shuffle | Lit when shuffle ON |
| Bottom-right | `#147028` green | `repeat` / `repeat.1` | Cycle repeat | Lit when repeat ≠ off |

**Repeat cycle**: off → repeat-all (`repeat`) → repeat-one (`repeat.1`) → off.

**Press animation**: `scale(0.92)` + `brightness(0.88)` with spring `response: 0.16s, damping: 0.60`. Returns to 1.0 on release.

---

### 9c. Info Row

Three zones in a horizontal bar:

- **Left**: Current playback time. 11px monospace, `#555`. Min-width 32px.
- **Centre**: Volume indicator. Speaker icons + a 2px-tall fill bar showing current system volume. Fill colour `#484848`. Updates in real time.
- **Right**: Library chip. Small rounded button, `#252525` background, 1px border `#333`. Icon + "Library" label. 10px uppercase letter-spaced text. Tap → opens library sheet.

---

### 9d. Skin Selector Row

Four equal-width buttons in a row, 6px gap.

Labels: `NORMAL`, `LED`, `CRT`, `VINYL`.

Style per button:
- Height: 32px, border-radius 8px.
- Inactive: `#242424` background, 1px border `#2E2E2E`, colour `#555`, weight 700.
- Active: `#D99A1A` gold background, border matches, colour `#1A0F00` (near-black).
- Active glow: `0 2px 10px rgba(217,154,26,0.45)`.
- Press: scale 0.92.
- The gold active style is a direct reference to MIST app's active skin button.

On tap: immediately re-renders the CD canvas in the new skin. Brief shimmer phase boost (+60 units) gives a flash of transition.

---

### 9e. Bottom Navigation Bar

Thin bar at the very bottom. Border-top: 1px `#242424`.

Three equal zones:

| Zone | Content | Action |
|------|---------|--------|
| Left | "⊞ AirPlay" — 9px uppercase, `#404040` | Opens system AirPlay/route picker (`AVRoutePickerView`) |
| Centre | 5 track-position dots | Visual only — shows current track position in queue |
| Right | "⚙ Settings" — 9px uppercase, `#404040` | Opens settings sheet |

**Track dots**: each dot is a `Capsule` shape, 4px tall. Active dot is white, 14px wide. Inactive dots are `#303030`, 5px wide. Width animates (spring 0.28s) when active dot changes.

---

## 10. Settings Sheet

Slides up over the control panel. Does NOT cover the top panel — only covers the bottom half.

**Backdrop**: `rgba(0,0,0,0.50)` over the bottom panel. Tap backdrop to dismiss.

**Sheet panel**: `#090909` background, border-radius 22px on top corners.

**Opening**: slides from `translateY(100%)` to `translateY(0)`, spring `response: 0.38s, damping: 0.82`.

### Contents (top to bottom):

**Drag handle**: 36×4px capsule, `#2A2A2A`, centred, 10px top padding.

**Skin section**:
- Label: `"Skin"` — 11px monospace, `#424242`, 14px top padding, 20px left.
- 4 skin buttons in a row (same NORMAL/LED/CRT/VINYL as main selector).
- Gold active state identical to the main selector.
- Tapping a skin here also changes the main selector and re-renders the CD.

**Toggles** (Sound + Haptic side by side):
- Each has a label above (11px monospaced grey) and a 52×38px toggle button below.
- Toggle ON: `#222` background, white checkmark icon.
- Toggle OFF: dark `#0F0F0F` background, `#383838` × icon.

**Clear Queue button**:
- Full-width, height 44px, `#121212` background, border-radius 12px.
- Label: `"Clear Queue"` — 14px monospaced, `#656565`.
- Press: scale 0.92.

**Footer bar** (very bottom of sheet):
- Background: `#070707`.
- Left: `"MusicPlayer 1.0"` — 11px, `#303030`.
- Right: `"Terms · Privacy"` — 11px, `#303030`.
- This directly mirrors the `"MIST 2.0.0  Terms  Privacy"` footer bar in the original MIST app.

---

## 11. Library Sheet

System bottom sheet (modal). Detents: half and full screen. Drag indicator visible.

Background: `#0F0F0F`.

### Header (top of sheet):
- **Left**: `"Library"` — 16px weight semibold monospaced, white.
- **Right (sort toggle)**: small rounded chip showing current sort. Two modes: `"Songs"` (music note icon) and `"Albums"` (stack icon). Tap to toggle. `#252525` background, `#666` text.
- **Far right**: ✕ button in a dark circle. Closes sheet.

### Search Bar:
- Dark `#111` rounded rectangle, 10px vertical padding.
- Magnifying glass icon left, `#404040`.
- Placeholder text: `"Search songs, artists, albums…"`.
- Clear (×) button appears when text is entered.
- Filters list live — matches title, artist, AND album simultaneously.

### Divider: 1px `#141414`.

### Songs View (default):
Scrollable list. Each row:
- **44×44px thumbnail**: album artwork, 6px corner radius. Music-note placeholder if no art.
- **Title**: 13px monospaced. White weight semibold if currently playing, normal otherwise.
- **Artist**: 11px monospaced `#424242`. Below title.
- **Right-side duration**: 11px `#323232`.
- **Currently playing indicator**: replaces duration with 3-bar animated EQ (same as in track info).
- Row vertical padding: 8px each side.
- **Tap** → starts playing immediately → sheet dismisses.

### Albums View:
Groups rows by album. Section headers: 11px weight semibold monospaced, `#383838`. Same row design inside.

---

## 12. Volume HUD

Appears whenever volume changes (hardware buttons, D-pad, or system change).

**Position**: centred over the top panel (absolute, z-index 20).  
**Background**: `rgba(0,0,0,0.85)` with `backdrop-filter: blur(8px)`. Border: 1px `#333`. Border-radius 12px.  
**Contents**:
- Label: `"VOLUME"` — 9px uppercase, letter-spaced, `#666`.
- Value: current volume as integer 0–100 — 28px weight 300, `#E0E0E0`.
- Bar: 100px wide, 3px tall. Fill: `#E05A00` (Braun orange). Animates to new width over 0.15s.

**Appears on**: any volume change.  
**Auto-dismiss**: after 1500ms of no volume change.  
**Transition**: `display: none` ↔ `display: block` (no animation — appears and disappears instantly to feel like a hardware overlay).

---

## 13. Physical Device Interactions

### Hardware Volume Buttons (iOS)
- Requires an `<audio>` element present in the DOM (even silent/empty).
- On first user interaction, call `audioElement.play()` to initialise the audio context (iOS requirement — autoplay is blocked until gesture).
- Listen for `volumechange` event on the audio element.
- When fired: read `audioElement.volume` → call `setVolume(v)` → show Volume HUD → update D-pad arc indicator.

### Device Tilt (DeviceOrientation API)
- Listen for `deviceorientation` events.
- `e.gamma`: left/right tilt (−90 to +90). Normalise to −1…+1 by clamping to ±30 and dividing by 30.
- `e.beta`: forward/back tilt. Normalise similarly (target ~20deg as neutral).
- **Effect on shimmer**: `shimmerPhase += tiltX * 0.8` per event — the rainbow colours on the CD drift as you tilt the phone, like light catching a real disc.
- **Effect on power LED** (if playing): glow intensity scales with `abs(tiltX)`.

---

## 14. Animations Summary

| Element | Trigger | Animation |
|---------|---------|-----------|
| CD rotation | Playing | +0.35°/frame, continuous |
| CD shimmer | Playing | +0.70 units/frame hue drift |
| CD rotation | Scratch | Immediate, finger-angle-driven |
| CD glow | Play/pause | Opacity/radius ease-in-out 0.6s |
| CD skin | Skin change | Cross-fade 0.4s, shimmer boost +60 |
| Tonearm | Progress | Slow linear sweep |
| Tonearm | Scratch | Instant jitter proportional to velocity |
| Tonearm | Crate open | Rotate+fade 0.3s ease |
| Pill press | Tap | scale 0.92 + brightness −0.06, spring 0.16s |
| Crate open | Swipe down | Slide up spring cubic-bezier(0.34,1.4,0.64,1) 0.52s |
| Crate close | Gesture | Same spring reversed |
| Record card | Navigate | Transform + opacity 0.35s spring |
| Record card active | Select | Lifts 22px + glow → auto-closes 280ms later |
| Carousel drag | Touch/mouse | Live rubber-band at 0.55× input delta |
| Carousel snap | Release | Spring 0.38s |
| Track dot | Track change | Width 5px↔14px spring 0.28s |
| Power LED | Play state | Background + glow 0.4s |
| EQ bars | Playing | Height oscillation 0.5s alternate, staggered |
| Swipe hint | Idle | Bob 0→4px→0 2.8s loop |
| Settings sheet | Open | Slide up spring 0.38s |
| Vol HUD | Volume change | Instant appear, auto-dismiss 1.5s |

---

## 15. Colour Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Device body | `#1C1C1C` | App background, bottom panel |
| Display | `#0D0D0D` | Top panel background |
| Surface | `#141414` | Record card background |
| Panel | `#090909` | Settings sheet |
| Brand strip | `#161616` | Top header bar |
| Hinge | `#181818` | Divider bar |
| Border | `#2A2A2A` | Most borders |
| Text primary | `#D8D8D8` | Track title |
| Text secondary | `#555555` | Artist, labels, time |
| Text muted | `#303030` | Inactive UI, footer |
| Orange (Braun accent) | `#E05A00` | Power LED, scratch rings, vol HUD bar, D-pad active |
| Gold (active skin) | `#D99A1A` | Active skin chip |
| Pill orange | `#C77A1A` | Play/pause button |
| Pill red | `#B81F24` | Skip button |
| Pill blue | `#1F45B8` | Shuffle button |
| Pill green | `#147028` | Repeat button |
| Wood brown | `#2A1F0E` | Crate top edge |
| Seek fill start | `hsl(266,82%,90%)` | Purple end |
| Seek fill end | `hsl(173,70%,95%)` | Cyan end |

---

## 16. Typography

All text: `'Helvetica Neue', Helvetica, Arial, sans-serif`.  
Monospace elements (time, labels): use system monospaced stack or letter-spacing to simulate tabular spacing.  
No serifs. No rounded fonts. Clean, tight, functional — Braun rule.

| Role | Size | Weight | Colour | Other |
|------|------|--------|--------|-------|
| Brand name | 9px | 700 | `#555` | uppercase, ls 0.25em |
| Track title | 14px | 500 | `#D8D8D8` | truncate |
| Artist / meta | 10px | 400 | `#555` | ls 0.04em |
| Skin buttons | 9px | 700 | see above | uppercase, ls 0.14em |
| Button labels | 8–9px | 700 | see above | uppercase |
| Library title | 16px | 600 | `#FFF` | monospaced |
| Song title | 13px | 400/600 | `#E0E0E0` | monospaced |
| Time stamps | 10–11px | 400 | `#555` | monospaced, tabular |
| Settings labels | 11px | 400 | `#424242` | monospaced |
| Footer | 11px | 400 | `#303030` | — |

---

## 17. What Intentionally Does NOT Exist

- No light mode. Dark only, always.
- No lyrics panel.
- No equaliser visualiser.
- No playlist creation.
- No album art fullscreen view.
- No onboarding or splash screen.
- No animations that use bounce on productive actions (only on playful ones like crate open).
- No colour outside the defined palette (no gradients introduced in UI chrome).
- No rounded display font — Helvetica Neue only.
