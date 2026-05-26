# Onboarding — Figma Design Spec
**File:** [testtingclaudexfigma](https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7/testtingclaudexfigma)  
**Figma page:** `Onboarding — First Launch`  
**Placement:** Right of node `360:2854` (~x 23850)

Rough wireframes for Procreate hand-art slots. Skins (NORMAL/LED/CRT/VINYL) are **not** shown — no skin UI in the app.

---

## Page structure

```
📄 Onboarding — First Launch
├── 00 — Component map
├── 01 — Full screens
│   ├── OB/Screen/Page0 — FlipPhone
│   ├── OB/Screen/Page1 — CrateCarousel
│   └── OB/Screen/Page2 — MechanicalFeel
├── 02 — Carousel cards
│   ├── OB/Card/S1 — PlayerOverview
│   ├── OB/Card/S2 — CaseOpen
│   ├── OB/Card/S3 — LibraryPeek
│   ├── OB/Card/S4 — DrawerSwipe
│   ├── OB/Card/S5 — VinylPick
│   └── OB/Card/S6 — PressPlay
├── 03 — Marquee
│   ├── OB/Marquee/Row1 — ControlsFeel
│   ├── OB/Marquee/Row2 — LibraryTransport
│   ├── OB/Marquee/Row3 — SavedCrate
│   └── OB/Marquee/Row4 — HeroMisc
└── 04 — Procreate export guide
```

**Deep link (Page 0):** [OB/Screen/Page0](https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7/testtingclaudexfigma?node-id=407-809)

---

## Copy (screens)

| Screen | Headline | Subtitle |
|--------|----------|----------|
| Page0 | Flip-phone playback / for your local library. | No streaming. No accounts. / Your Music app, your crate. |
| Page1 | Browse vinyl & CDs / in the crate carousel. | Swipe the panel. Pick a disc. Press play. |
| Page2 | Mechanical controls. / Real haptics. | Scratch the disc. Feel every key. |

Footer (all pages): `No sign-up required unless you want to / store your library preferences.`

---

## Card → Xcode export

| Figma frame | Asset name | Hand-art layer |
|-------------|------------|----------------|
| `OB/Card/S1 — PlayerOverview` | `onboarding_s1` | `HandArt/Placeholder` |
| `OB/Card/S2 — CaseOpen` | `onboarding_s2` | `HandArt/Placeholder` |
| `OB/Card/S3 — LibraryPeek` | `onboarding_s3` | `HandArt/Placeholder` |
| `OB/Card/S4 — DrawerSwipe` | `onboarding_s4` | `HandArt/Placeholder` |
| `OB/Card/S5 — VinylPick` | `onboarding_s5` | `HandArt/Placeholder` |
| `OB/Card/S6 — PressPlay` | `onboarding_s6` | `HandArt/Placeholder` |

Safe zone inside each card: **240 × 140** (dashed `HandArt/Placeholder`).

---

## Marquee chips (Page 2)

| Row | Direction | Chips |
|-----|-----------|-------|
| `OB/Marquee/Row1 — ControlsFeel` | LTR | SCRATCH DISC · JOG WHEEL · HAPTICS · UI SOUND · DRAWER PHYSICS · KEY PRESS |
| `OB/Marquee/Row2 — LibraryTransport` | RTL | LOCAL LIBRARY · NO ACCOUNTS · SHUFFLE · REPEAT · PREV · NEXT |
| `OB/Marquee/Row3 — SavedCrate` | LTR | SAVE TO CRATE · LONG PRESS · 3D CRATE · SHARE MOMENT · VINYL RIPPLE |
| `OB/Marquee/Row4 — HeroMisc` | RTL | CD CASE OPEN · HERO ARTWORK · DEMO CRATE · CLEAR QUEUE · VOLUME |

Each row includes duplicated chips for seamless scroll in Swift.

---

## Procreate workflow

1. Open card frame in Figma (section **02 — Carousel cards**).
2. Export wireframe @1x as reference.
3. Draw in **240 × 140** safe area; rough pencil style.
4. Place PNG in Figma over `HandArt/Placeholder` → rename `HandArt/Procreate_v1`.
5. Export card @2x → `Assets.xcassets/onboarding_sN`.

---

## Swift handoff

See [`ONBOARDING_SPEC.md`](ONBOARDING_SPEC.md) for interaction spec. When implementing, add:

```swift
// FigmaAssets.swift
static func onboardingScreen(_ index: Int) -> String { "onboarding_s\(index)" }
```
