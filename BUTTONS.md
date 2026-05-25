# Button Catalog (by color)

Quick reference for Figma `buttonHalf` keys in this app.  
Each button is implemented in `FigmaButtonHalf.swift` and wired through `FigmaControlPanel`.

**Figma file:** [testtingclaudexfigma](https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7/testtingclaudexfigma)

**Control card shell:** `305:3451` — 402 × 452 pt, `#D7D9D9`, corner 40 pt.

---

## Orange — `#F3490E`

| | |
|---|---|
| **Figma component** | `buttonHalf/Type7` |
| **Figma node** | `310:3460` |
| **Default label** | `PREV` |
| **Typical action** | Skip to previous track |
| **Native size** | 176 × 48 pt |
| **Corner radius** | **12 pt** (not a full pill) |
| **Border** | 2 pt solid white |
| **Shadow** | 16 pt offset, 32 pt blur, 48% black |
| **Text** | White, monospaced, ~20.3 pt |

### Call it

```swift
// Short form (recommended)
FigmaButtonHalf.orange(scale: vm.figmaLayoutScale) {
    vm.skipPrevious()
}

// Explicit form
FigmaButtonHalf(
    label: "PREV",
    variant: .orange,
    flex: true,
    scale: vm.figmaLayoutScale
) {
    vm.skipPrevious()
}
```

### Already used in

- `FigmaControlPanel.swift` — transport row, left slot

---

## Cream — `#D7D2D0`

| | |
|---|---|
| **Figma component** | `buttonHalf/Type6` |
| **Figma node** | `310:3461` |
| **Default label** | `NEXT` |
| **Typical action** | Skip to next track |
| **Native size** | 176 × 48 pt |
| **Corner radius** | **20 pt** |
| **Border** | 3 pt solid white |
| **Shadow** | 16 pt offset, 32 pt blur, 48% black |
| **Text** | Dark grey `#313131`, monospaced, ~20.3 pt |

### Call it

```swift
// Short form (recommended)
FigmaButtonHalf.cream(scale: vm.figmaLayoutScale) {
    vm.skipNext()
}

// Explicit form
FigmaButtonHalf(
    label: "NEXT",
    variant: .cream,
    flex: true,
    scale: vm.figmaLayoutScale
) {
    vm.skipNext()
}
```

### Already used in

- `FigmaControlPanel.swift` — transport row, right slot

---

## Mid Grey — `#B1AEAD`

| | |
|---|---|
| **Figma component** | `buttonHalf/Type5` |
| **Figma node** | `310:3463` (row `310:3462`) |
| **Default label** | `SHUFFLE` |
| **Typical action** | Toggle shuffle mode |
| **Native size** | 176 × 48 pt (cap seated in black well) |
| **Well** | Black tray, **2 pt** corner |
| **Cap inset** | **2.25%** on all sides |
| **Corner radius** | **20 pt** |
| **Border** | 1.618 pt solid white |
| **Shadow** | 8.6 pt offset, 17.3 pt blur, 48% black |
| **Text** | White, monospaced, ~10.5 pt |
| **Active state** | Cap fills orange `#F3490E` |

### Call it

```swift
FigmaButtonHalf.midGrey(isActive: vm.isShuffle, scale: vm.figmaLayoutScale) {
    vm.toggleShuffle()
}
```

### Already used in

- `FigmaControlPanel.swift` — toggle row, left slot

---

## Dark — `#242323`

| | |
|---|---|
| **Figma component** | `buttonHalf` |
| **Figma node** | `310:3464` (row `310:3462`) |
| **Default label** | `REPEAT` (also `REPEAT ONE` / `REPEAT ALL`) |
| **Typical action** | Cycle repeat mode |
| **Native size** | 176 × 48 pt (cap seated in black well) |
| **Well** | Black tray, **2 pt** corner |
| **Cap inset** | **2.25%** on all sides |
| **Corner radius** | **20 pt** |
| **Border** | 1.618 pt solid white |
| **Shadow** | 8.6 pt offset, 17.3 pt blur, 48% black |
| **Text** | White, monospaced, ~10.5 pt |
| **Active state** | Cap fills orange `#F3490E` |

### Call it

```swift
FigmaButtonHalf.dark(
    label: repeatCaption,
    isActive: vm.repeatMode != .none,
    scale: vm.figmaLayoutScale
) {
    vm.toggleRepeat()
}
```

### Already used in

- `FigmaControlPanel.swift` — toggle row, right slot

---

## Square keys (PLAY / PAUSE)

Column node `310:3476` — 54.34 × 119.321 pt, vstack gap **11.321 pt**.

| | PLAY | PAUSE |
|---|---|---|
| **Figma node** | `310:3477` | `310:3478` |
| **Cap master** | `298:13917` | `298:13937` |
| **Size** | 54 × 54 pt | 54 × 54 pt |
| **Well** | Black tray, **2 pt** corner | Black tray, **2 pt** corner |
| **Cap inset** | **2.25 %** on all sides | **2.25 %** on all sides |
| **Cap corner** | 20 pt | 20 pt |
| **Border** | 0.91 pt solid white | 0.91 pt solid white |
| **Drop shadow** | 4.854 / 4.854 / 9.708, 73 % black | 4.854 / 4.854 / 9.708, 73 % black |
| **Inner shadow** | 0.607 / 0.607 / 9.708, 10 % black | 0.607 / 0.607 / 9.708, 10 % black |
| **Fill** | `#535150` (bgmidgrey) | `#242323` (bgdarkgrey) |
| **Label** | `PLAY`, Sometype Mono 10.92 pt | `PAUSE`, Sometype Mono 10.92 pt |
| **Label position** | top 6.74 %, centered | top 6.74 %, centered |
| **Extra glyph** | — | `*`, Red Hat Mono 17.6 pt, left 15.73 %, bottom 3.75 % |

```swift
VStack(spacing: FigmaTheme.playPauseGap * scale) {
    FigmaSquareButton.play(scale: scale) { vm.togglePlay() }
    FigmaSquareButton.pause(scale: scale) { vm.togglePlay() }
}
.frame(
    width: FigmaTheme.playPauseColumnWidth * scale,
    height: FigmaTheme.playPauseColumnHeight * scale,
    alignment: .leading
)
```

---

## Adding the next button

1. Open the Figma node in Dev Mode.
2. Update the matching `Variant` spec in `FigmaButtonHalf.swift`.
3. Add a colour-named static helper (e.g. `FigmaButtonHalf.cream(...)`).
4. Document it in this file under the colour name.
5. Wire it in `FigmaControlPanel`.
