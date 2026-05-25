# Music Player — UI Design Document

---

## Concept

A music player styled as a **flip phone with two panels**, inspired by the Samsung Z Flip / MIST app aesthetic.
The phone is split horizontally by a visible hinge. Top half is a dark display screen.
Bottom half is a physical control pad. Everything is dark, uses vertical CRT scanline texture,
and monospaced fonts throughout.

---

## Overall Layout

```
┌─────────────────────────────────┐
│                                 │  ← Status bar (system)
│        TOP PANEL (54%)          │
│         — CD Display —          │
│                                 │
│          [ CD DISC ]            │
│                                 │
│      Song Title (text)          │
│    Artist  •  Album (text)      │
│                                 │
├═════════════════════════════════╡  ← Hinge divider
│        BOTTOM PANEL (46%)       │
│                                 │
│  ─────── Seek bar ───────────   │
│                                 │
│  [ D-PAD ]    [ ▶ ] [ ⏭ ]      │
│               [ ⇄ ] [ ↺ ]      │
│                                 │
│  0:47   [🔊 ──────]  [Library]  │
│                                 │
│  [AirPlay]  ● ● ● ● ●  [⚙ ]   │
└─────────────────────────────────┘
```

---

## Top Panel — CD Display

**Background:** Pure black  
**Texture:** Vertical CRT scanlines at 4% opacity (every 4px: 2px black stripe, 2px gap)

### The CD Disc

Centered in the top panel. Size: approximately 218×218pt.

The CD has these layers stacked:
1. **Base circle** — very dark grey fill
2. **Iridescent layer** — rotating angular gradient (rainbow hue sweep), blended with `.screen`
3. **Glint layer** — counter-rotating white spoke gradient, blended with `.overlay`, ~55% opacity
4. **Specular highlight** — off-center radial gradient (top-left), simulates a single light source
5. **Track rings** — 6 concentric circle strokes at 4.5% white opacity (radii: 94%, 87%, 80%, 73%, 65%, 57%)
6. **Center label** — 76pt circle with dark purple radial gradient (or album artwork if available)
7. **Center hole** — 13pt black circle with thin stroke

When playing: CD rotates continuously (0.35°/frame), hue drifts (0.7°/frame).  
When paused: rotation and hue drift freeze at current position.  
Glow shadow intensifies when playing (purple, radius 32pt).

### 4 CD Skins

Toggled from the Settings panel. The skin changes the visual style of the disc only — layout is identical.

| Skin | Visual Description |
|------|--------------------|
| **NORMAL** | Full-spectrum iridescent rainbow angular gradient rotating on the disc surface |
| **LED** | 8 neon arc segments around the outer ring, each a different hue. Segments have strong glow/bloom. The hue of each segment shifts over time. Dark between segments. Inner glow bloom in the centre. |
| **CRT** | Green phosphor tint overall. Horizontal scanlines drawn across the disc face. Monochromatic green angular gradient. Slight bloom. Entire disc has a green colour multiply. |
| **VINYL** | Matte black record. Dense concentric groove rings (every 2.5% of radius). No rainbow shimmer. Subtle single rotating glint. Large 90pt center label showing album artwork. |

### Song Info (below CD)

Two lines of text, centred, monospaced font:
- **Line 1:** Track title — 14pt medium white
- **Line 2:** Artist • Album — 11pt grey (42% white)
- When playing: a small animated equaliser icon (3 bars bouncing) appears to the left of the artist name

---

## Hinge Divider

10pt tall horizontal bar between the two panels.  
Dark grey fill with a thin 2pt gradient stripe running through the centre (light grey → dark → light grey top to bottom), simulating a physical hinge reflection.

---

## Bottom Panel — Controls

**Background:** Near-black (5.5% white)  
**Texture:** Vertical scanlines at 2.5% opacity

### 1. Seek Bar (top of panel)

Full-width horizontal scrubber.

- **Track:** 3pt tall, dark grey rounded rectangle
- **Fill:** Purple → cyan gradient from left to progress point
- **Thumb:** 12pt white circle with soft white glow shadow
- **Interaction:** Drag anywhere on the bar to seek. Tap to jump.

---

### 2. Main Control Row

Split into two zones side by side:

#### Left: D-Pad

A dark circular area (~100×100pt) with a faint border ring.  
Four tap zones arranged in a cross, each with a chevron arrow icon.  
A small 14pt dot in the very centre (purely decorative — indicates the "joystick" position).

| Direction | Action |
|-----------|--------|
| ▲ Up | Volume up (+10%) |
| ▼ Down | Volume down (−10%) |
| ◄ Left | Previous track (or restart if >3s in) |
| ► Right | Skip to next track |

---

#### Right: 2×2 Pill Buttons

Four rounded-rectangle pill buttons in a 2-column, 2-row grid.  
Each pill is 50pt tall. Equal width. 9pt gap between them.

Each pill has:
- Solid colour fill (dimmed to 28% when feature is inactive)
- Subtle white top-sheen gradient
- Vertical scanline texture at 6% opacity clipped to shape
- SF Symbol icon centred
- Spring press animation (scales to 92% on tap)
- Coloured glow shadow when active

| Position | Colour | Icon | Action | Active State |
|----------|--------|------|--------|--------------|
| Top-left | **Orange** `#C77920` | `play.fill` / `pause.fill` | Play / Pause | Always active |
| Top-right | **Red** `#B81F24` | `forward.end.fill` | Skip next track | Always active |
| Bottom-left | **Blue** `#1F45B8` | `shuffle` | Toggle shuffle | Lit when shuffle is ON |
| Bottom-right | **Green** `#147028` | `repeat` / `repeat.1` | Cycle repeat mode | Lit when repeat ≠ off |

Repeat cycles: **Off → Repeat All → Repeat One → Off**

---

### 3. Middle Row

Three elements in a horizontal row below the main controls:

| Zone | Content |
|------|---------|
| Left | Current playback time — e.g. `0:47` in monospaced grey text |
| Centre | Volume indicator — speaker icons + a thin horizontal progress bar showing current system volume |
| Right | **Library chip** — small pill button with a music list icon and "Library" label. Opens the library sheet. |

---

### 4. Bottom Navigation Bar

Mirrors the `• • •   6   ⌨` row from the MIST app.

| Zone | Content |
|------|---------|
| Left | **AirPlay button** — AVRoutePickerView, grey tint, lights up when routing to external device |
| Centre | **5 track dots** — capsule shapes. Active track is white and wider (16pt). Others are grey (5pt). Animated expand/collapse on track change. |
| Right | **Settings button** — horizontal sliders icon. Tap opens the settings sheet sliding up from the bottom. |

---

## Settings Sheet

Slides up from the bottom, overlaying the control panel. The CD display remains visible above.  
Semi-transparent dark backdrop behind it. Tap backdrop to dismiss.

Structure (top to bottom):

```
──────  (drag handle capsule)

Skin
[ NORMAL ] [ LED ] [ CRT ] [ VINYL ]

Sound        Haptic
  [✓]          [✓]

[ Clear Queue ]

────────────────────────────────────
MusicPlayer 1.0        Terms  Privacy
```

### Skin Buttons
Four equal-width rounded-rectangle buttons in a row.  
**Selected skin** gets a **gold/yellow** fill (`#D99A1A`) with black text — identical to MIST's active NORMAL button.  
Unselected skins are dark grey with muted text.  
Scanline texture on all of them.

### Sound / Haptic Toggles
Each is a 52×38pt rounded square.  
Active: medium grey fill with a checkmark icon.  
Inactive: dark fill with an × icon.

### Clear Queue Button
Full-width dark rounded rectangle, 44pt tall. Labelled "Clear Queue" in monospaced text.

### Footer Bar
Thin dark bar at the very bottom of the sheet (matches MIST's `MIST 2.0.0  Terms  Privacy` footer).  
Left: app version. Right: Terms · Privacy links in muted text.

---

## Library Sheet

Opens as a system sheet (slides up from bottom of screen, detent: half or full).

```
Library                    [Songs▾]  [✕]
[🔍 Search songs, artists, albums…   ]
─────────────────────────────────────
[artwork]  Track Title              3:42
           Artist Name

[artwork]  Track Title              4:11
           Artist Name
...
```

### Header
- "Library" title (monospaced, 16pt semibold white)
- Sort toggle button: switches between **Songs** view and **Albums** grouped view
- Close button (× in a dark circle)

### Search Bar
Full-width dark rounded rectangle.  
Magnifying glass icon on the left.  
Clear button (×) appears when text is entered.  
Filters the list live as you type (matches title, artist, album).

### Songs View
Scrollable list. Each row:
- **44×44pt thumbnail** — album artwork, rounded 6pt corners. Music note placeholder if no art.
- **Track title** — 13pt monospaced. Bold white if currently playing.
- **Artist name** — 11pt monospaced grey below title.
- **Duration** — 11pt grey, right-aligned.
- **Playing indicator** — replaces duration with animated 3-bar equaliser when this track is active.
- Tap row → starts playing immediately and dismisses the sheet.

### Albums View
Same rows, grouped by album title. Section headers in small monospaced grey text.

---

## Colour Palette

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#000000` | Top panel, app background |
| Surface | `#0E0E0E` | Bottom panel |
| Hinge | `#1A1A1A` | Divider bar |
| Text Primary | `#FFFFFF` | Track title, active labels |
| Text Secondary | `rgba(255,255,255,0.42)` | Artist, album, time labels |
| Text Muted | `rgba(255,255,255,0.30)` | Footer, inactive controls |
| Orange | `#C77920` | Play/Pause pill |
| Red | `#B81F24` | Skip pill |
| Blue | `#1F45B8` | Shuffle pill |
| Green | `#147028` | Repeat pill |
| Gold/Active | `#D99A1A` | Active skin chip in Settings |
| Seek gradient start | `hsl(266, 82%, 90%)` | Purple end of seek fill |
| Seek gradient end | `hsl(173, 70%, 95%)` | Cyan end of seek fill |

---

## Typography

All text uses **monospaced** font (SF Mono / system monospaced).  
No serif or sans-serif anywhere — the retro CRT character is entirely in the mono font.

| Role | Size | Weight |
|------|------|--------|
| Track title | 14pt | Medium |
| Artist / album | 11pt | Regular |
| Time stamps | 12–13pt | Medium |
| Button labels | 12pt | Semibold |
| Section headers | 11pt | Semibold |
| Footer | 11pt | Regular |

---

## Interactions & Animations

| Interaction | Animation |
|-------------|-----------|
| Tap any pill button | Spring scale to 92%, brightness −6%, spring back (response 0.16s) |
| Play starts | CD begins rotating, glow shadow fades in (0.6s ease-in-out) |
| Play pauses | CD stops rotating, glow fades out (0.6s ease-in-out) |
| Skin change | CD visual cross-fades (0.4s ease-in-out) |
| Settings open | Sheet slides up from bottom (spring response 0.38s) |
| Settings close | Sheet slides back down |
| Track changes | Track dots animate (active dot expands, spring 0.28s) |
| Drag seek bar | Thumb follows finger in real time, fill updates live |
| D-pad tap | System volume HUD appears (handled by iOS), CD glow pulses once |
| Volume change | Volume bar width animates to new level |

---

## Permissions Required

| Permission | Reason |
|------------|--------|
| `NSAppleMusicUsageDescription` | Access iTunes/Music library to browse and play tracks |
| MediaPlayer framework | Required for `MPMusicPlayerController` and `MPMediaQuery` |

---

## What the App Does NOT Have (intentional omissions)

- No album art fullscreen view (kept minimal)
- No lyrics panel  
- No equaliser
- No playlist creation (library is browse + play only)
- No light mode (dark only, always)
