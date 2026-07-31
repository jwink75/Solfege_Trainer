# The Solfège Trainer Bible (v12.5)
**Status:** Production - Phases 1–5 Complete | **Last Updated:** July 31, 2026
**Note on Documentation:** This Bible is a living technical specification and must always be rendered and provided using Markdown.

## I. Executive Summary & Vision
The Solfège Trainer is a gamified, high-performance ear training application designed to move students from simple diatonic pitches to complex chords. It focuses on functional tendencies—the magnetic pull of specific scale degrees toward resolution.
* **Game Mode:** Algorithmic level progression with a manual Level Browser.
* **Practice Mode:** Customizable sandbox for Melodic/Harmonic parameters.
* **The Vibe:** A professional, strictly lowercase, responsive tool with human-like musical "ring-outs."

## II. Intended Platforms & Environment
* **Platform:** Solar2D (Lua).
* **Architecture:** Master/Worker separation. `main.lua` (Director) manages `ui`, `playback`, `engine`, `progression`, and `definitions`. Workers are independent to prevent circular dependencies.

## III. Core Conventions & Math
* **Solfège Formatting:** **STRICT LOWERCASE** (do, di, ra, re, me, mi, fa, fi, sol, le, la, te, ti).
* **Semitone Mapping (Tonic = 0):** do=0, ra=1, re=2, me=3, mi=4, fa=5, fi=6, sol=7, le=8, la=9, te=10, ti=11.
* **Resolution Direction:** ti must resolve upward to do (11 → 12).
* **Key Rotation:** 50% chance to stay in the same key. If the key repeats, the melody **must** change.
* **Tonic Range:** MIDI 52 (E3) to 64 (E4).
* **Sample Audio Clamping:** Strict octave bounds clamping ($40 \le \text{MIDI} \le 81$) prevents silent audio failures.
* **UI Nomenclature:** Flat-dominant (C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B).
* **The Global Octave Ban:** Never play the same solfège note in different octaves simultaneously.

## IV. Harmonic Foundation: The Cadence Engine
A new key is always established by a I-IV-V-I Cadence.
* **The Soprano Anchor:** do4 (MIDI 72) is maintained as a common tone during I-IV.
* **Bass Foundation:** Literal root (do-fa-sol-do) exactly one octave below the tonic reference.
* **Standardized Voicing (Example in C):**
    * Chord 1 (I): `{48, 64, 67, 72}` (do2, mi3, sol3, do4)
    * Chord 2 (IV): `{53, 65, 69, 72}` (fa2, fa3, la3, do4)
    * Chord 3 (V): `{55, 62, 67, 71}` (sol2, re3, sol3, ti3)
    * Chord 4 (I): `{48, 64, 67, 72}` (do2, mi3, sol3, do4)
* **Timing:** $BP$ = 800ms. Cadence pulse: 1.0x → 1.0x → 1.0x → 1.5x (1200ms ring-out).
* **The Breath:** Mandatory 1600ms (2.0x) silence after cadence before the question.

## V. Audio Execution & Playback Mechanics
* **The Legato Protocol:** Sequential melody notes overlap by 100ms for a resonant, human feel.
* **Simultaneous Stack Audio:** Dyads, Triads, and 7th Chords (`isStack = true`) sound simultaneously via `playback.chord.on(...)` with a 1.4s hold and 500ms fade release.
* **The Panic Protocol (Esc / Level Switch):** Calls `globalPanic()`, canceling all timers and stopping all audio immediately.
* **Safe-Stop:** Every `audio.stop` call verifies `audio.isChannelActive` to prevent console errors.
* **Resonance Multipliers:**
    * Standard Note: 1.0x (800ms).
    * Final Question Note: 1.5x (1200ms) for natural decay.

## VI. UX, Input & Evaluation Logic
* **Keybinds:** ENTER (Submit), C/K (Cadence Replay), Q (Replay Question), 0 (Reset Score), BACKSPACE/DELETE (Sequential Delete), ESC (Panic/Menu).
* **Caps Lock Ignore:** Inputs lowercased automatically to allow uninterrupted typing.
* **Input States:**
    * **Identification (Levels 1, 2, 7, 8):** Single-input. Reveal on keypress.
    * **Sequential Transcription (Levels 3–6, 9–12):** Sequential placeholders (`__ __`). Requires ENTER to submit.
    * **Harmonic Stack Dictation (Levels 13–21):** Simultaneous chord audio. **Students MUST enter notes from the bottom up** (Bass $\to$ Soprano).
* **The 5-Strike Decay System:**
    * Note slots start at 10 points. 
    * Errors drop potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
    * **Partial Credit:** Users earn the current decayed value for any note they get right, even if they fail the overall sequence.
    * **Forced Reveal:** If potential hits 0, answer is revealed (Green = Correct, Red = Missed).
* **Resolution Expansion:** Correct answers in single-input resolution levels reveal full resolution paths (e.g. `ti` reveals `ti do`; `fi` reveals `fi sol`).

## VII. Level Architecture & Algorithmic Progression
### Phase 1: Diatonic Melodic Expansion (Complete)
* **Level 1: Diatonic Tendencies (ID Mode)** (1.1: `d-s`, `t-d`, `f-m`; 1.2: `r-d`, `l-s`; 1.3: `m-r-d`, `l-t-d`).
* **Level 2: Single Diatonic Notes (ID Mode)** (2.1: Unstable `t`, `f`; 2.2: Moderate `r`, `l`; 2.3: Stable `d`, `m`, `s`).
* **Level 3: 2-Note Diatonic Melodies** (3.1: Tendency pairs; 3.2: Anchors; 3.3: 2-note random).
* **Level 4: 3-Note Diatonic Melodies** (4.1: Mix; 4.2: Root triads; 4.3: Inverted triads; 4.4: 3-note Boss).
* **Level 5: 4-Note Diatonic Melodies** (5.1: 2 pairs; 5.2: Pair + 2 random; 5.3: 4-note Boss).
* **Level 6: 5-Note Diatonic Melodies** (6.1–6.3: Mixed rules; 6.4: 5-note Boss).

### Phase 2: Chromatic Melodic Expansion (Complete)
* **Level 7: Chromatic Tendencies (ID Mode)** (7.1: `fi-s`, `le-s`, `ra-d`, `te-d`; 7.2: 3-note pathway `me-r-d`).
* **Level 8: Single Chromatic Notes (ID Mode)** (8.1: `ra`, `me`, `fi`; 8.2: `le`, `te`; 8.3: All chromatics).
* **Level 9: 2-Note Chromatic Melodies** (9.1: Chromatic pairs; 9.2: Diatonic/chromatic mix; 9.3: Random chromatic).
* **Level 10: 3-Note Chromatic Melodies** (10.1: Chromatic pathway; 10.2: Mix; 10.3: Random chromatic; 10.4: Chromatic Boss).
* **Level 11: 4-Note Chromatic Melodies** (11.1: Chromatic pair + diatonic pair; 11.2: Chromatic pair + 2 random; 11.3: Chromatic Boss).
* **Level 12: 5-Note Chromatic Melodies** (12.1: Chromatic pathway + diatonic pair; 12.2: Chromatic pair + 3 random; 12.3: 2 Chromatic pairs + 1 random; 12.4: Chromatic Boss).

### Phase 3: Dyads (2-Note Stacks) (Complete)
* **Level 13: Diatonic Dyads** (13.1: 3rds & 6ths; 13.2: 4ths & 5ths; 13.3: 2nds & 7ths; 13.4: All diatonic dyads).
* **Level 14: Chromatic Dyads** (14.1: 3rds & 6ths; 14.2: 4ths & 5ths; 14.3: All chromatic dyads).

### Phase 4: 3-Note Stacks (Triads & Clusters) (Complete)
* **Level 15: Major & Minor Triads (Root Position)** (15.1: Major; 15.2: Minor; 15.3: All root triads).
* **Level 16: Triad Inversions** (16.1: 1st Inversion `i-6`; 16.2: 2nd Inversion `i-64`; 16.3: All inversions).
* **Level 17: Diminished & Augmented Triads** (17.1: Diminished `vii-o`; 17.2: Augmented `iii+`; 17.3: Mix).
* **Level 18: 3-Note Open Voicings** (18.1: Max outer interval Maj 10th).

### Phase 5: 4-Note Stacks (7th Chords & Clusters) (Complete)
* **Level 19: 4-Note 7th Chords** (19.1: Dominant 7th `V7`; 19.2: Major/Minor 7th `maj7`/`min7`; 19.3: All 7th chords).
* **Level 20: Diminished 7th Chords** (20.1: Half-Diminished `vii-o7`; 20.2: Fully Diminished `dim7`; 20.3: Mix).
* **Level 21: 4-Note Open Voicings & Clusters** (21.1: Max outer interval Perf 12th).

## VIII. Enharmonic Spelling & Functional Notation
### 1. Functional Enharmonic Priority Hierarchy
1. **Diatonic Defaults:** `0`=do, `2`=re, `4`=mi, `5`=fa, `7`=sol, `9`=la, `11`=ti.
2. **`1` (b2 / #1):** `ra` by default (e.g. `fa ra ti do`); `di` ONLY for ascending $0 \to 1 \to 2$ (`do di re`).
3. **`3` (b3 / #2):** `me` by default (e.g. `me le`); `ri` ONLY for ascending $2 \to 3 \to 4$ (`re ri mi`).
4. **`6` (#4 / b5):** `fi` resolving up to `sol` (7); `se` resolving down to `fa` (5).
5. **`8` (b6 / #5):** `le` resolving down to `sol` (7); `si` resolving up to `la` (9).
6. **`10` (b7 / #6):** `te` by default (e.g. `te do`); `li` ONLY for ascending $9 \to 10 \to 11$ (`la li ti`).

### 2. Scoring & Yellow Correction
* **Perfect (10 pts):** Correct pitch + Correct functional spelling.
* **Near-Miss (9 pts):** Correct pitch + Incorrect spelling.
* **Yellow Correction:** "Near-Miss" entries convert to Preferred Spelling and highlight in yellow upon submission.

***

**July 31 Release Notes (v12.5):**
* **Phases 3–5 Complete:** Implemented Dyads (Levels 13–14), Triads & Inversions (Levels 15–18), and 4-Note 7th Chords (Levels 19–21).
* **Simultaneous Stack Audio Engine:** Added simultaneous chord playback (`item.isStack = true`) via `playback.chord.on(...)`.
* **Strict Bottom-Up Note Entry:** Enforced strict bottom-to-top note evaluation (Bass $\to$ Soprano) for all stack dictations.
* **UI Feedback:** Added stack feedback instruction (`"enter notes from bottom up, submit with enter"`).
