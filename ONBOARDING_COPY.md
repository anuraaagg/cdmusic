# Onboarding — Copy reference
**Edit this file, then update `FigmaOnboardingScreen.swift` and `FigmaOnboardingMarquee.swift` to match.**

Asset slots: `onboarding_s1` … `onboarding_s6` in `Assets.xcassets/figma/` (static images, no video).

---

## Global (every page)

| Element | Current copy | Notes |
|---------|--------------|-------|
| **Skip** (header, top-right) | `SKIP` | Plain button label |
| **CTA** (primary button) | `GET STARTED` | Completes onboarding |
| **Footer** | `No sign-up required unless you want to`<br>`store your library preferences.` | Centered, mono 13pt, 65% white |

**Header:** Press wordmark image (`crates_logo`) — no text.

---

## Page 0 — Flip-phone / local library

| Element | Current copy |
|---------|--------------|
| **Headline** (bold phrases in markdown) | **Flip-phone** playback<br>for your **local library.** |
| **Subtitle** (mono, 70% white) | No streaming. No accounts.<br>Your Music app, your crate. |
| **Carousel cards** | S1 · S2 · S3 (see below) |

---

## Page 1 — Crate carousel

| Element | Current copy |
|---------|--------------|
| **Headline** | Browse **vinyl & CDs**<br>in the **crate carousel.** |
| **Subtitle** | Swipe the panel. Pick a disc. Press play. |
| **Carousel cards** | S4 · S5 · S6 (see below) |

---

## Page 2 — Mechanical feel

| Element | Current copy |
|---------|--------------|
| **Headline** | **Mechanical controls.**<br>**Real haptics.** |
| **Subtitle** | Scratch the disc. Feel every key. |
| **Carousel** | Feature chip marquee (no static cards) |

### Marquee chips (page 2 only)

**Row 1** (scrolls one direction):
- SCRATCH DISC
- JOG WHEEL
- HAPTICS
- UI SOUND
- DRAWER PHYSICS
- KEY PRESS

**Row 2**:
- LOCAL LIBRARY
- NO ACCOUNTS
- SHUFFLE
- REPEAT
- PREV
- NEXT

**Row 3**:
- SAVE TO CRATE
- LONG PRESS
- 3D CRATE
- SHARE MOMENT
- VINYL RIPPLE

**Row 4**:
- CD CASE OPEN
- HERO ARTWORK
- DEMO CRATE
- CLEAR QUEUE
- VOLUME

---

## Carousel card slots (images)

Replace PNGs in Xcode; safe area inside card chrome ≈ **240 × 140** @1x reference.

| Asset | Figma frame | Suggested subject (for your art) |
|-------|-------------|----------------------------------|
| `onboarding_s1` | OB/Card/S1 — PlayerOverview | Full player: CD hero + bottom panel |
| `onboarding_s2` | OB/Card/S2 — CaseOpen | Jewel case sliding open, disc exposed |
| `onboarding_s3` | OB/Card/S3 — LibraryPeek | Library sheet / track list |
| `onboarding_s4` | OB/Card/S4 — DrawerSwipe | Control panel pulled down, crate visible |
| `onboarding_s5` | OB/Card/S5 — VinylPick | Horizontal vinyl carousel, one disc selected |
| `onboarding_s6` | OB/Card/S6 — PressPlay | JAM strip + play controls / now playing |

**Page → cards shown in carousel**

| Onboarding page | Cards visible |
|-----------------|---------------|
| 0 | s1, s2, s3 |
| 1 | s4, s5, s6 |
| 2 | Marquee only |

---

## Swift locations (after copy edits)

| Copy | File |
|------|------|
| Headlines, subtitles, footer | `musicapp/FigmaOnboardingScreen.swift` |
| Marquee chips | `musicapp/FigmaOnboardingMarquee.swift` |
| Card images | `Assets.xcassets/figma/onboarding_s1.imageset` … `s6` |
| Image names helper | `musicapp/FigmaAssets.swift` → `onboardingScreen(_:)` |

---

## Draft alternatives (optional)

Use or mix as needed:

**Page 0 headline:** Your music. Your phone. / A flip-phone player for Apple Music.

**Page 0 subtitle:** Nothing to stream. Nothing to sign in. / Just the songs already on your device.

**Page 1 headline:** Dig through your crate. / Vinyl-style browsing for every track.

**Page 1 subtitle:** Pull the panel down. Tap a record. Hit play.

**Page 2 headline:** Built like hardware. / Touches that click, spin, and scratch.

**Page 2 subtitle:** Drag the case. Spin the disc. Every control has weight.

**Footer:** Preferences stay on your device. / Optional account only if you save crates to the cloud.

**CTA:** `OPEN PLAYER` · `START LISTENING` · `ENTER CRATES`
