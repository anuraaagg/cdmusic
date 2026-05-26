# Live Activity & Widget — Figma Design Spec
**File:** [testtingclaudexfigma](https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7/testtingclaudexfigma)  
**Build from existing components — do not redraw from scratch**

> **Auto-build:** Run the Figma plugin at [`figma/plugins/live-activity-builder/`](figma/plugins/live-activity-builder/) — see [Run the builder plugin](#run-the-builder-plugin) below.

### Run the builder plugin

1. Open [testtingclaudexfigma](https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7/testtingclaudexfigma?node-id=360-2854) in **Figma desktop** (logged in as `anurag.s@cred.club`).
2. **Plugins → Development → Import plugin from manifest…**
3. Select [`figma/plugins/live-activity-builder/manifest.json`](figma/plugins/live-activity-builder/manifest.json)
4. **Plugins → Development → cdmusic Live Activity Builder → Run**
5. Frames appear in a **Live Activity & Widgets** section to the right of node `360:2854`.

Creates: `LA/Banner` (playing / paused / longTitle), Lock Screen mock, Dynamic Island expanded, Home widget medium.

---

## Page structure (create in Figma)

```
📄 Live Activity & Widgets
  ├── 00 — Component map (instances only)
  ├── 01 — Lock Screen Live Activity
  ├── 02 — Dynamic Island
  ├── 03 — Home Screen Widgets
  └── 04 — Onboarding teaser (optional)
```

Place all frames **to the right** of node `360:2854` (CD slide tray) so they sit near the player artboard.

---

## Reuse map — existing Figma components

| Widget zone | Reuse from file | Node / code ref | How to use |
|-------------|-----------------|-----------------|------------|
| Logo | `crates_logo` | `305:2745` | Scale to 28×28 in banner header |
| Status + counter pills | JAM status cluster | `332:4653`–`332:4657` | Instance at **~35% scale** → status `PLAYING` / `PAUSED`, counter `03/12` |
| Track title typography | Hero meta strip cell 2 | `305:3037` | Copy text style: Helvetica 12→15 semibold for widget title |
| Time / counter mono | JAM counter pill | `332:4657` | Roboto Mono 10–11 for `1:42 / 3:58` |
| Play accent | VOL orange | `#EA2B07` / `305:2700` | 28×28 circle for play/pause |
| Transport icons | Cream panel PREV/NEXT | `332:4662` grid | Use icon glyphs only, 18×18 inside 44×44 hits |
| Disc thumbnail | CD disc mask | `305:2722` / `cd_disc` | 52×52 circle; fill with album art or crate vinyl |
| Progress track | VOL slider track | `305:3441` | Recolor track `#D7D9D9`, fill `#EA2B07`, height 6 |
| Banner surface | JAM pill fill | `#F8F7F4` | Full banner background |
| Hairline | Meta strip border | `#222220` | Disc ring, optional pill separation |

---

## 01 — Lock Screen Live Activity

### Context frame (design review only)

| Property | Value |
|----------|-------|
| Frame name | `Lock Screen — iPhone 15 Pro` |
| Size | **393 × 852** |
| Background | `#000000` or iOS lock wallpaper placeholder |

Drop a **361 × 84** banner instance at **x:16, y:120** (approximate system placement).

### Banner component — `LA/Banner`

**Base size:** 361 × 84 · corner radius **22** · fill `#F8F7F4`

#### Auto-layout structure

```
LA/Banner [VERTICAL, pad 10×12, gap 6]
├── Row/Header [HORIZONTAL, gap 8, align center]
│   ├── crates_logo (28×28)
│   └── Pills [HORIZONTAL, spacing −16]
│       ├── StatusPill → instance 332:4654 "PLAYING"
│       └── CounterPill → instance 332:4657 "03/12"
├── Row/Main [HORIZONTAL, gap 8, align center]
│   ├── DiscThumb (52×52, ellipse clip + hairline)
│   ├── TextColumn [VERTICAL, gap 2, FILL width]
│   │   ├── Title "Track Title Goes Here…"
│   │   └── Artist "Artist Name" @ 55% opacity
│   └── Transport [HORIZONTAL, gap 0]
│       ├── SkipPrev 44×44
│       ├── PlayBtn 44×44 (28 orange circle)
│       └── SkipNext 44×44
└── Row/Progress [HORIZONTAL, gap 8, align center]
    ├── ProgressBar 180×6 (FILL)
    └── TimeLabel "1:42 / 3:58" mono
```

#### Variants (component set)

| Variant property | Values |
|------------------|--------|
| `State` | `playing` · `paused` · `longTitle` |
| `Artwork` | `yes` · `placeholder` |

| State | Status pill | Play icon | Progress |
|-------|-------------|-----------|----------|
| playing | PLAYING | Pause ❚❚ white on orange | 42% fill |
| paused | PAUSED | ▶ white on orange | 18% fill @ 50% opacity |
| longTitle | PLAYING | Pause | Title ellipsis demo |

**Sample copy:** Title *Snoopy for President* · Artist *Vince Guaraldi Trio*

---

## 02 — Dynamic Island

Create component set **`LA/DynamicIsland`** with property `Presentation`:

### minimal (126 × 37 safe area)

- Orange dot 10×10 `#EA2B07`, centered trailing when playing
- Empty when paused

### compact (expanded pill ~360 × 37)

```
[disc 20×20 circle]  ·····spacer·····  [orange play 20×20]
```

### expanded (~360 × 80)

Reuse **`LA/Banner`** inner rows **without** logo + pills:

```
[disc 28]  Title + Artist (stack)     [⏮][▶][⏭]  (36 pt hits)
           ▓▓▓▓▓▓▓▓░░░░ progress
           1:42 / 3:58
```

Frame on dark `#000000` pill background with 44 pt corner radius (system approximation).

---

## 03 — Home Screen Widgets

These are **WidgetKit home screen** sizes (optional v2 — design now for consistency).

### Small — `LA/Widget/Small` (158 × 158)

```
┌─────────────┐
│ [logo 24]   │
│             │
│  ┌───────┐  │
│  │ disc  │  │  72×72
│  └───────┘  │
│ Track Title │
│   ▶  PLAY   │  orange pill button
└─────────────┘
```

- Background: `#F8F7F4`
- Corner: 22 (iOS widget default)
- Tap opens app to now playing

### Medium — `LA/Widget/Medium` (338 × 158)

```
┌──────────────────────────────────────────┐
│ [logo] PLAYING · 03/12                   │
│ [disc 52]  Track Title          [▶][⏭]   │
│            Artist                        │
│            ▓▓▓▓▓▓▓▓░░░░  1:42 / 3:58     │
└──────────────────────────────────────────┘
```

Essentially **`LA/Banner`** at 338×158 with slightly tighter padding (10).

### Large — `LA/Widget/Large` (338 × 354)

```
┌──────────────────────────────────────────┐
│ [logo]                    PLAYING 03/12  │
│                                          │
│         ┌──────────────┐                 │
│         │   disc 140   │                 │
│         └──────────────┘                 │
│         Track Title                      │
│         Artist Name                      │
│         ▓▓▓▓▓▓▓▓▓▓░░░░░░░░               │
│         1:42 / 3:58                      │
│                                          │
│      [ ⏮ ]    [ ▶ ]    [ ⏭ ]            │
│      PREV     PLAY     NEXT              │
└──────────────────────────────────────────┘
```

- Reuse **`FigmaSquareButton`** / half-button styling from `305:3416` for bottom transport row
- Large disc: clone `305:2722` disc layer scaled to 140 pt (no jewel case)

---

## 04 — Screen size matrix (instances to place)

Duplicate context frames for QA — banner component stays fixed width; system scales on device.

| Device frame | Viewport | Banner inset | Notes |
|--------------|----------|--------------|-------|
| iPhone SE | 375 × 667 | 16 H | Banner 343 effective |
| iPhone 15 | 393 × 852 | 16 H | **Primary** — 361 banner |
| iPhone 15 Pro Max | 430 × 932 | 16 H | Banner 398 effective |
| iPhone 16 Pro | 402 × 874 | 16 H | Matches app `designWidth` |

For each device frame, place:
1. `LA/Banner` instance — `playing`
2. `LA/Banner` instance — `paused` (below, 24 pt gap)
3. `LA/DynamicIsland` — `expanded` mock

---

## 05 — Parts library (local components)

Build once, reference everywhere:

| Component | Size | Source |
|-----------|------|--------|
| `LA/Logo` | 28 | `305:2745` |
| `LA/DiscThumb` | 52 / 72 / 140 | `cd_disc` mask |
| `LA/StatusPill` | hug × 22 | clone `332:4654` |
| `LA/CounterPill` | hug × 22 | clone `332:4657` |
| `LA/PlayButton` | 44 hit / 28 fill | orange `#EA2B07` |
| `LA/SkipButton` | 44 | from `332:4662` icons |
| `LA/ProgressBar` | 180 × 6 | from `305:3441` |
| `LA/TimeLabel` | hug | mono from counter pill |

---

## 06 — Build order in Figma

1. **Parts** — extract pills, play button, progress from existing nodes
2. **`LA/Banner`** — assemble + 3 state variants
3. **Lock context** — 393×852 with banner instances
4. **`LA/DynamicIsland`** — minimal / compact / expanded
5. **Home widgets** — S / M / L using banner parts
6. **Device matrix** — SE, 15, 15 Pro Max, 16 Pro
7. **Export** — PNG @2x for onboarding carousel card (optional)

---

## 07 — Token table (bind if variables exist)

| Role | Hex | Swift token |
|------|-----|-------------|
| Surface | `#F8F7F4` | `jamPillFill` |
| Text | `#0D0C0A` | `textDark` |
| Muted text | `#0D0C0A` 55% | — |
| Accent | `#EA2B07` | `orangeAccent` |
| Progress track | `#D7D9D9` | `panelGrey` |
| Hairline | `#222220` | `hairlineBorder` |

Search file variables: `search_design_system` query `"surface"`, `"orange"`, `"primary"`.

---

## 08 — Handoff → Swift

| Figma component | Swift target |
|-----------------|--------------|
| `LA/Banner` | `PlaybackLiveActivityWidget` lock screen region |
| `LA/DynamicIsland` expanded | ActivityKit `dynamicIsland` expanded |
| `LA/DynamicIsland` compact | ActivityKit compact leading/trailing |
| `LA/Widget/Medium` | WidgetKit `systemMedium` (future) |

See [`LIVE_ACTIVITY_WIREFRAME.md`](LIVE_ACTIVITY_WIREFRAME.md) for pt specs and [`lock_screen_live_activity` plan](.cursor/plans/lock_screen_live_activity_b6ffda05.plan.md) for implementation.

---

## Unblock MCP access (optional)

To let the agent build these frames automatically:

1. Open the file in Figma desktop with the file **open and focused**
2. Ensure your MCP account (`anurag.singh@airtribe.live`) has **Edit** access on Team Airtribe file, or duplicate the file to your personal team (Full seat)
3. Re-run: *"build Live Activity frames in Figma"*
