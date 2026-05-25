# Live Activity Wireframe — cdmusic Lock Screen Strip
**Version 0.1 — design reference only (not final UI)**

Use this doc to build Figma frames before Swift implementation. All sizes are **logical pt** at @1x unless noted.

---

## Figma setup

| Setting | Value |
|---------|-------|
| Primary frame | **393 × 852** (iPhone 15 Pro lock screen mock) |
| Live Activity artboard | **361 × 84** (banner content area — see below) |
| Corner radius (banner) | **22** (iOS system Live Activity default) |
| Grid | 4 pt |
| Tokens | Map to [`FigmaTheme.swift`](musicapp/FigmaTheme.swift) |

### Color tokens

| Token | Hex | Use |
|-------|-----|-----|
| `surface/primary` | `#F8F7F4` | Banner background (`jamPillFill`) |
| `text/primary` | `#0D0C0A` | Title, artist (`textDark`) |
| `text/muted` | `#0D0C0A` @ 55% | Elapsed/total time |
| `accent/play` | `#EA2B07` | Play button fill, progress fill (`orangeAccent`) |
| `border/hairline` | `#222220` | Disc ring, progress track border |
| `progress/track` | `#D7D9D9` | Unfilled progress bar (`panelGrey`) |
| `icon/secondary` | `#0D0C0A` @ 70% | Skip prev/next glyphs |

### Typography

| Role | Font | Size | Weight | Case | Tracking |
|------|------|------|--------|------|----------|
| Track title | Helvetica | 15 | Semibold | Sentence | −0.4 |
| Artist | Helvetica | 13 | Regular | Sentence | 0 |
| Status pill | Status (app) | 11 | Semibold | UPPER | 0 |
| Counter pill | Roboto Mono | 10 | Medium | UPPER | 0 |
| Time | Roboto Mono | 11 | Medium | — | 0 |

*(Match `FigmaFont.status` / `FigmaFont.counter` where possible.)*

---

## 1. Lock Screen context frame

Place the Live Activity banner **above** the system torch/camera shortcuts.

```
┌──────────────────────────────────────────── 393
│ 9:41                              🔋 📶      │  ← status bar (system)
│                                              │
│           Tuesday, May 26                    │  ← date (system)
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │                                        │  │
│  │     LIVE ACTIVITY BANNER  (361×84)     │  │  ← YOU DESIGN THIS
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│              12 : 45                         │  ← lock clock (system)
│                                              │
│         [flashlight]    [camera]             │  ← system shortcuts
└──────────────────────────────────────────────
```

**Banner placement:** 16 pt horizontal inset → content width **361 pt**. Top of banner ~**120 pt** from screen top (approximate; system positions it).

---

## 2. Lock Screen banner — wireframe (361 × 84)

### Layout grid

```
┌─────────────────────────────────────────────────────────────────┐ 84
│ 12 │ LOGO │ 8 │ STATUS PILL │−16│ COUNTER │     SPACER     │12│
│    │ 28×  │   │   PLAYING   │   │  03/12  │                  │  │
│    │ 28   │   └─────────────┘   └─────────┘                  │  │
│    │      │                                                    │  │
│    │      │  ┌────────┐  8   Track Title Goes Here…    44 44 44│  │
│    │      │  │        │      Artist Name                  ⏮ ▶ ⏭│  │
│    │      │  │  DISC  │  8                                      │  │
│    │      │  │  52×52 │      ▓▓▓▓▓▓▓▓▓▓░░░░░░  1:42 / 3:58   │  │
│    │      │  └────────┘                                        │  │
└─────────────────────────────────────────────────────────────────┘ 361
```

### Zone spec

| Zone | X | Y | W × H | Notes |
|------|---|---|-------|-------|
| Banner padding | 12 | 10 | — | All sides: 12 H, 10 V |
| **Logo** | 12 | 12 | 28 × 28 | `crates_logo`, aspect fit |
| **Status pill** | 48 | 10 | hug × 22 | Min width 72; pad H12 V4; radius 11 |
| **Counter pill** | overlap −16 | 10 | hug × 22 | Overlaps status; pad H10 V4; radius 11 |
| **Disc thumbnail** | 12 | 38 | 52 × 52 | Circle clip; 1 pt hairline ring |
| **Text column** | 72 | 38 | flex | Title + artist stacked |
| **Transport cluster** | right−12 | 38 | 132 × 44 | 3 buttons, 44 pt touch each |
| **Progress row** | 72 | 68 | 277 × 6 | Bar + time label |

### Row A — header (y: 10–32)

```
[logo 28] —8— [ PLAYING          ]←16 overlap→[ 03/12 ]
               status pill 192 max              counter hug
```

- Status text: `PLAYING` or `PAUSED`
- Counter: `{index}/{total}` e.g. `03/12`
- Pills: fill `#F8F7F4` on banner (same fill — use **subtle shadow** or **hairline** to separate from banner if needed)
- Optional: pills sit on a **1 pt lighter inset** `#FFFFFF` @ 40% strip behind header only

### Row B — main (y: 38–62)

```
┌──────────┐   Track Title (1 line, tail truncate)
│  album   │   Artist Name (1 line, tail truncate)
│   art    │
│  52×52   │
└──────────┘                    [ ⏮ ]  [ ▶ ]  [ ⏭ ]
                                 44     44     44
```

| Element | Spec |
|---------|------|
| Disc | 52 × 52 circle; artwork cover; 1 pt stroke `#222220` @ 25% |
| Title | Max width = banner − disc − transport − gaps ≈ **165 pt** |
| Artist | Same width; 55% opacity |
| Prev / Next | 44 × 44 hit; 18 × 18 icon; no fill |
| **Play** | 44 × 44 hit; **28 × 28** orange circle `#EA2B07`; white ▶ / ❚❚ icon 12 pt |

### Row C — progress (y: 68–78)

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░   1:42 / 3:58
└─ fill orange ─┘└── track grey #D7D9D9 ──┘   mono 11pt muted
     progress bar: 180 × 6, radius 3
```

| State | Progress fill |
|-------|----------------|
| Playing | Orange fill, width = `(current/duration) × 180` |
| Paused | Fill frozen; optional 50% opacity |

---

## 3. Banner states (Figma variants)

Create a component **`LiveActivityBanner`** with variants:

| Variant | Status pill | Play icon | Progress |
|---------|-------------|-----------|----------|
| `playing` | PLAYING | Pause (two bars) | Animated fill (mock 45%) |
| `paused` | PAUSED | Play triangle | Frozen fill |
| `longTitle` | PLAYING | Play | Title = "Song Name That Keeps Going And Going…" |
| `noArt` | PLAYING | Play | Disc = tinted placeholder (crate accent) |

---

## 4. Dynamic Island wireframes

Apple constrains DI layouts. Design at these approximate sizes:

### 4a. Minimal (Dynamic Island collapsed pill)

```
┌──────────────────────────────────────┐
│  ●                                   │  ← 10 pt orange dot when playing
└──────────────────────────────────────┘
```

- Dot: `#EA2B07`, 10 × 10
- Hidden when paused (empty minimal)

### 4b. Compact (leading + trailing)

```
┌────────────────────────────────────────────────┐
│ (●disc 20)  ·····················  ( ▶ orange )│
└────────────────────────────────────────────────┘
```

| Zone | Size | Content |
|------|------|---------|
| Leading | 20 × 20 | Circular disc thumb |
| Trailing | 20 × 20 | Orange play/pause glyph |

### 4c. Expanded (tap/hold island)

```
┌──────────────────────────────────────────────────────────┐
│  (disc 28)   Track Title                    ⏮   ▶   ⏭   │
│              Artist · 1:42 / 3:58                         │
│              ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
└──────────────────────────────────────────────────────────┘
```

Approx frame: **360 × 80**. Same hierarchy as lock banner but:
- No logo row (space constrained)
- No status pills (optional: tiny `PLAYING` mono label under artist)
- Transport icons slightly smaller (36 pt hits)

Create Figma component **`DynamicIslandExpanded`** separate from lock banner.

---

## 5. Component parts to export

Design these as **reusable Figma components** for the app + marketing:

| Component | Size | Notes |
|-----------|------|-------|
| `LA/Logo` | 28 × 28 | crates_logo |
| `LA/DiscThumb` | 52 × 52 | + ring variant |
| `LA/StatusPill` | hug × 22 | PLAYING / PAUSED |
| `LA/CounterPill` | hug × 22 | 03/12 |
| `LA/PlayButton` | 44 hit / 28 fill | orange circle |
| `LA/SkipButton` | 44 × 44 | prev + next |
| `LA/ProgressBar` | 180 × 6 | track + fill |
| `LA/TimeLabel` | hug | 1:42 / 3:58 |

---

## 6. Spacing cheat sheet

```
Banner outer padding     12 H · 10 V
Logo → pills gap         8
Pills overlap            −16 (status under counter)
Disc → text column       8
Title → artist           2
Text → transport gap     auto (spacer)
Progress top margin      6 below artist
Progress → time label    8 gap
Button spacing           0 (44 pt boxes abut)
```

---

## 7. Sample content (use in Figma)

| Field | Sample A | Sample B |
|-------|----------|----------|
| Title | Snoopy for President | Bohemian Rhapsody |
| Artist | Vince Guaraldi Trio | Queen |
| Status | PLAYING | PAUSED |
| Counter | 03/12 | 01/08 |
| Time | 1:42 / 3:58 | 0:00 / 5:54 |
| Progress | 42% | 0% |

---

## 8. What NOT to design (v1)

- Full CD jewel case / slide tray
- CRT scanlines, LED glow, vinyl grooves
- Crate carousel thumbnail
- Scrubbing on progress bar
- Settings / skin picker on lock screen

---

## 9. Figma file structure (suggested)

```
📁 Live Activity
  📄 00 — Tokens (colors + type)
  📄 01 — Lock Screen context (393×852)
  📄 02 — Banner component (361×84) + variants
  📄 03 — Dynamic Island — minimal / compact / expanded
  📄 04 — Parts library (buttons, pills, progress)
  📄 05 — Onboarding mock (optional card 393×200 crop of banner)
```

---

## 10. Handoff checklist

Before implementation, confirm in Figma:

- [ ] Banner reads at arm's length on lock screen mock
- [ ] Play button meets 44 pt touch target
- [ ] Title truncates cleanly (long variant)
- [ ] Paused vs playing variants defined
- [ ] Dynamic Island expanded fits without clipping transport
- [ ] Colors match `FigmaTheme` hex values above
- [ ] Export `crates_logo` + sample disc art for preview

---

## Next step

Once Figma frames are approved, implementation follows [`lock_screen_live_activity` plan](.cursor/plans/lock_screen_live_activity_b6ffda05.plan.md) Phase 2–3.
