# Solfège Trainer — System Architecture & Technical Specification

## Overview & Vision
The **Solfège Trainer** is a gamified ear-training application built in Solar2D (Lua). It trains the human ear to recognize **functional tonal tendencies** (the magnetic pull of scale degrees toward resolution within an established key) rather than raw interval distances.

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

- **`main.lua` (Director & State Machine)**: Holds app state (`menu`, `quiz`, `result`), listens for hardware/keyboard input, orchestrates timers, evaluates user submissions, and manages session scoring.
- **`engine.lua` (Procedural Brain & Enharmonic Engine)**: Generates random melodies adhering to interval leap limits, anti-repetition rules, diatonic guards, and context-aware directional enharmonic spelling (`getPreferredName`).
- **`playback.lua` (Standalone Audio Engine)**: Zero-dependency voice channel manager (32 channels), sample player (`piano_40-C2.ogg` through `81-A5.ogg`), legato overlap (100ms fade), and panic audio stops.
- **`ui.lua` (Visual Layer)**: Manages dynamic display auto-scaling (10% auto-shrink for 5+ note dictations), answer buffers, decay feedback headers, and score displays.
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

## 3. Directional Enharmonic Spelling Engine
Spelling for chromatic pitches is dynamically assigned in `engine.getPreferredName(pitch, context)` based on resolution direction:
- **Upward leading tones (`nextNote > pitch`)**: Sharp spelling (`di`, `ri`, `fi`, `si`, `li`).
- **Downward leading tones (`nextNote < pitch`)**: Flat spelling (`ra`, `me`, `se`, `le`, `te`).
- **Default/Static**: Standard flat priority (`ra`, `me`, `fi`, `le`, `te`).

---

## 4. Scoring Decay & Evaluation Logic

- **5-Strike Potential Decay**: Each note slot begins with a maximum potential of 10 points. Every incorrect guess decays potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
- **Partial Credit**: Submitting a correct pitch earns its current decayed value.
- **Near-Miss System (9 Points)**: Correct pitch with incorrect enharmonic spelling awards 9 points and displays a **Yellow Correction** box.
- **Forced Reveal**: Reaching 0 potential in any slot triggers an automatic reveal.

---

## 5. Roadmap & Future Features

### Phase 1: Diatonic Melodic Expansion (Complete)
- Levels 1–6: 1-note to 5-note dictations, diatonic tendencies, and random bosses.

### Phase 2: Chromatic Melodic Expansion (Complete)
- Level 7: Chromatic Tendencies ID Mode (`fi-s`, `le-s`, `ra-d`, `te-d`, `me-r-d`).
- Level 8: Single Chromatic Note ID Mode.
- Levels 9–12: 2-note to 5-note dictations incorporating controlled chromaticism.

### Phase 3–5: Dyads & Harmonic Stacks (Future)
- Levels 13–14: Diatonic/Chromatic Dyads (2-note stacks).
- Levels 15–18: 3-Note Stacks (Triads/Clusters, max interval Maj 10th).
- Levels 19–21: 4-Note Stacks (7th Chords, max interval Perf 12th).

### Touch Device UI Layout & On-Screen Keypad (To-Do)
- Implement interactive touch pads/buttons for mobile/tablet devices (iOS & Android).
- Layout: 2-tier circular/grid keypad representing the 12 chromatic scale degrees mapped to Solfège syllables, with dedicated `Submit`, `Backspace`, `Cadence (C)`, and `Replay (Q)` touch targets.
