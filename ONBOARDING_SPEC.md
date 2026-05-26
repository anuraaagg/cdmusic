# Onboarding — Interaction & UI Specification
**Version 1.0 — cdmusic first-launch intro**

---

## 1. Concept

A **3-page first-launch onboarding** that introduces the flip-phone music player. Ported from `Onboarding2022View` interaction mechanics; UI uses **system colors** (`.primary`, `.secondary`, `Color.accentColor`, `Color(.systemBackground)`) and **standard SwiftUI buttons** (`.borderedProminent`, plain Skip).

Shows **once per user** by default. Can be **disabled entirely from code** via `OnboardingConfig.isEnabled`.

---

## 2. Feature flag & persistence

### Toggle from code

File: [`musicapp/OnboardingConfig.swift`](musicapp/OnboardingConfig.swift)

```swift
enum OnboardingConfig {
    /// Flip to `false` to disable onboarding app-wide.
    static var isEnabled = true

    static let completionStorageKey = "figma.hasCompletedOnboarding"

    static var shouldPresent: Bool {
        isEnabled && !UserDefaults.standard.bool(forKey: completionStorageKey)
    }

    static func markCompleted() { ... }
    static func resetCompletion() { ... }  // testing only
}
```

| Flag / key | Purpose |
|------------|---------|
| `OnboardingConfig.isEnabled` | **Master switch.** `false` → player always opens, no sheet |
| `figma.hasCompletedOnboarding` | UserDefaults — set `true` after Skip or Get Started |
| `OnboardingConfig.resetCompletion()` | Clears completion for QA (only works when `isEnabled == true`) |

### ContentView gate

```swift
@AppStorage(OnboardingConfig.completionStorageKey) private var hasCompletedOnboarding = false

private var showOnboarding: Bool {
    OnboardingConfig.isEnabled && !hasCompletedOnboarding
}

// In body ZStack, zIndex(20):
if showOnboarding {
    FigmaOnboardingScreen(onComplete: { hasCompletedOnboarding = true })
}
```

---

## 3. Overall layout

```
┌──────────────────────────────────────┐
│  [crates_logo]              SKIP   │
│                                      │
│  **Headline** (page 0–2)             │
│  Subtitle (mono, 70% white)          │
│                                      │
│  ┌────┐ ┌────┐ ┌────┐               │
│  │ S1 │ │ S2 │ │ S3 │  ← carousel   │
│  └────┘ └────┘ └────┘               │
│                                      │
│  [ GET STARTED ]  (.borderedProminent) │
│  Footer note (14pt, 70%)             │
└──────────────────────────────────────┘
     ↑ animated gradient blobs + noise
```

---

## 4. Interactions

### User-initiated

| Element | Gesture | Behavior |
|---------|---------|----------|
| **Skip** (top-right) | Tap | `markCompleted()` → dismiss sheet |
| **Get Started** | Tap | Haptic + `markCompleted()` → dismiss |
| **Carousel** | Horizontal drag | Live offset; `dragging = true`; pauses auto-timer |
| **Carousel release** | Drag end | Snap to nearest page (clamped ±1); spring `response: 0.6` |

### Automatic

| Element | Trigger | Behavior |
|---------|---------|----------|
| Auto-advance | Every 4s | `pageIdx = (pageIdx + 1) % 3` |
| Timer | `dragging` | Pause on true, restart on false |
| Background | `pageIdx` | Cross-fade 3 gradient palettes, 1.5s easeInOut |
| Gradient blobs | `onAppear` | 10 ellipses/layer, forever easeInOut ~5–10s |
| Headline / subtitle | `pageIdx` | Blur 8→0 + opacity + scale 0.9→1, spring 0.38/0.82 |
| Feature marquee | `pageIdx == 2` | 4 rows, 20s linear infinite scroll, alternating direction |
| Carousel parallax | Scroll | `scaleEffect` from global minX; offset `pow(x/w, 2) * -60` |

### Three pages → carousel offsets

| pageIdx | Centered content | offset |
|---------|------------------|--------|
| 0 | Screens 1–3 | `0` |
| 1 | Screens 4–6 | `secondPageOffset` |
| 2 | Feature chip marquee | `thirdPageOffset` |

---

## 5. Copy (cdmusic)

| Page | Headline | Subtitle |
|------|----------|----------|
| 0 | **Flip-phone** playback / for your **local library.** | No streaming. No accounts. / Your Music app, your crate. |
| 1 | Browse **vinyl & CDs** / in the crate carousel. | Swipe the panel. Pick a disc. Press play. |
| 2 | **Mechanical controls.** / **Real haptics.** | Scratch the disc. Feel every key. |

Footer: `No sign-up required unless you want to / store your library preferences.`

---

## 6. Animations summary

| Element | Trigger | Animation |
|---------|---------|-----------|
| Gradient blobs | Appear | easeInOut forever, per-blob duration |
| Page background | pageIdx | Cross-fade 1.5s |
| Headline / subtitle | pageIdx | Blur + opacity + scale, spring 0.38/0.82 |
| Carousel drag | Finger | Live offset |
| Carousel snap | Release | interactiveSpring 0.6 |
| Carousel parallax | Position | scale + pow offset |
| Marquee rows | Appear | linear 20s repeatForever |
| Auto-advance | Timer | pageIdx cycle every 4s |

---

## 7. Files to create

| File | Role |
|------|------|
| `OnboardingConfig.swift` | Feature flag + persistence helpers |
| `FigmaOnboardingGradient.swift` | Animated blob backgrounds |
| `FigmaOnboardingMarquee.swift` | InfiniteScroller + feature chips |
| `FigmaOnboardingCarousel.swift` | Drag carousel + parallax cards |
| `FigmaOnboardingScreen.swift` | Root layout, timer, CTAs |

### Modified

| File | Change |
|------|--------|
| `ContentView.swift` | `@AppStorage` gate + full-screen overlay |
| `FigmaAssets.swift` | Optional `onboardingScreen(_:)` asset names |

No `pbxproj` edits needed — project uses synchronized `musicapp/` folder.

---

## 8. Intentional omissions

- No Sign In / account flow
- No storyboard dependency
- No bundled MP4 in v1 — carousel uses SwiftUI looping previews (`OnboardingCardPreviews`)
- No noise texture in v1 (optional add later)
