# Solfège Star — System Architecture & Technical Specification

## Overview & Vision
**Solfège Star** is a gamified ear-training application built in Solar2D (Lua). It trains the human ear to recognize **functional tonal tendencies** (the magnetic pull of scale degrees toward resolution within an established key) rather than raw interval distances, featuring celestial constellation progression.

---

## 1. System Architecture & Master/Worker Pattern
To prevent circular dependency crashes, the project follows a strict **Master/Worker Separation**:

```
                  ┌──────────────┐
                  │   main.lua   │ (Director & State Machine)
                  └──────┬───────┘
         ┌───────────────┼───────────────┬───────────────┐
         ▼               ▼               ▼               ▼
  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
  │ engine.lua │  │  ui.lua    │  │playback.lua│  │progression.│
  │ (The Brain)│  │(Visuals)   │  │(The Voice) │  │    lua     │
  └────────────┘  └────────────┘  └────────────┘  └────────────┘
```

- **`main.lua` (Director & State Machine)**: Holds app state (`idle`, `quiz`, `result`), listens for hardware/keyboard/touch input, orchestrates timers, evaluates user submissions via bidirectional enharmonic equivalence, and manages session scoring.
- **`engine.lua` (Procedural Brain & Enharmonic Engine)**: Generates random melodies adhering to interval leap limits, anti-repetition rules, diatonic guards, avoiding augmented primes, and enforcing context-aware directional enharmonic spelling (`getPreferredName`).
- **`playback.lua` (Standalone Audio Engine)**: Zero-dependency voice channel manager (32 channels), native `.wav` sample player (`piano_40-C2.wav` through `81-A5.wav`), legato overlap (100ms fade), and panic audio stops. iOS CoreAudio session property configured (`audio.MediaPlayback`) for background playback.
- **`ui.lua` (Visual Layer)**: Manages physical widescreen real-estate math (`display.actualContentWidth`), oblong landscape stadium pill buttons, 5-piece 3-note tendency gradient transitions, answer buffers (temporal horizontal & spatial vertical stacks), status banners, and dynamic 4:3 / 19.5:9 proportional iPad scaling.
- **`progression.lua` (Syllabus & Curriculum)**: Defines level definitions, unit lists, and rule parameters for Phase 1 (Diatonic) through Phase 5 (Chords).
- **`definitions.lua` (Legacy Reference)**: Standard semitone maps and resolution arrays.

---

## 2. Core Principles & Math

- **Strict Lowercase Solfège**: All UI strings and inputs strictly use lowercase (`do`, `ra`, `re`, `me`, `mi`, `fa`, `fi`, `sol`, `le`, `la`, `te`, `ti`). Note: `sol` is strictly 3 letters.
- **Semitone Mapping (Tonic = 0)**:
  `do`=0, `ra`=1, `re`=2, `me`=3, `mi`=4, `fa`=5, `fi`=6, `sol`=7, `le`=8, `la`=9, `te`=10, `ti`=11.
- **Tonic Range**: Randomly assigned per key change between MIDI 52 (E3) and 64 (E4).
- **Cadence Protocol**: Establishes key center via a 4-chord I-IV-V-I sequence with soprano anchor `do4` (MIDI 72). Cadence pulse: 800ms per chord, final chord 1.2s (1.5x), followed by a mandatory 1.6s (2.0x) "Breath" silence before the exercise plays.

---

## 3. Directional Enharmonic Spelling & Bidirectional Equivalence
Spelling for chromatic pitches is dynamically assigned in `engine.getPreferredName(pitch, context)` based on music theory rules:
- **Avoid Augmented Primes**: Prefers minor 2nd step intervals over augmented primes (e.g. `sol` $\to$ `le` $G \to A\flat$ instead of `sol` $\to$ `si` $G \to G\sharp$).
- **Melodic Contours**:
  - Ascending minor seconds: Sharp spelling (`di`, `ri`, `fi`, `si`, `li`).
  - Descending minor seconds: Flat spelling (`ra`, `me`, `se`, `le`, `te`).
- **Bidirectional Equivalence Matching (`isNameEquivalent`)**:
  - Automatically matches all enharmonic pairs as 100% correct (`si` $\leftrightarrow$ `le`, `di` $\leftrightarrow$ `ra`, `ri` $\leftrightarrow$ `me`, `fi` $\leftrightarrow$ `se`, `li` $\leftrightarrow$ `te`), solving chorister input feedback.

---

## 4. Scoring Decay & Evaluation Logic

- **5-Strike Potential Decay**: Each note slot begins with a maximum potential of 10 points. Every incorrect guess decays potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
- **Partial Credit**: Submitting a correct pitch earns its current decayed value.
- **Forced Reveal**: Reaching 0 potential in any slot triggers an automatic reveal.

---

## 5. Mobile & iPad UX Infrastructure

- **PIN Ring-Buffer Overwriting**: Full answer buffers shift out oldest answer (slot 1) when tapping new keys.
- **Onscreen `⌫ del` Touch Target**: Discrete backspace touch button for touch devices.
- **Tap-To-Start Level Switching**: Navigating levels updates state to `"idle"` without auto-playing cadences.
- **Responsive Layout Math**: Dynamic vertical height offsets prevent overlapping headers, banners, answer boxes, and keypads across iPad 4:3 and iPhone 19.5:9 displays.
