# The Solfège Trainer Bible (v12.6)
**Status:** Production - Re-Sequenced Curriculum & Checkpoints Complete | **Last Updated:** August 1, 2026
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
* **Keybinds:** ENTER (Submit), C/K (Cadence Replay), Q (Replay Question), 0 (Reset Score), BACKSPACE/DELETE (Sequential Delete), ESC (Panic/Menu), ARROW KEYS (Level Navigate), SHIFT+ARROW (Major Level Jump).
* **Caps Lock Ignore:** Inputs lowercased automatically to allow uninterrupted typing.
* **Input States:**
    * **Identification (Levels 1, 2, 3):** Single-input. Immediate reveal on keypress.
    * **Sequential Transcription (Levels 4, 6, 7, 10, 11, 14, 16, 18):** Sequential placeholders (`__ __`). Requires ENTER to submit.
    * **Harmonic Stack Dictation (Levels 5, 8, 9, 12, 13, 15, 17, 19):** Simultaneous chord audio. **Students MUST enter notes from the bottom up** (Bass $\to$ Soprano).
    * **Checkpoints (Levels 10.9 & 19.9):** Cumulative review levels drawing uniformly across unlocked material.
* **The 5-Strike Decay System:**
    * Note slots start at 10 points. 
    * Errors drop potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
    * **Partial Credit:** Users earn the current decayed value for any note they get right, even if they fail the overall sequence.
    * **Forced Reveal:** If potential hits 0, answer is revealed (Green = Correct, Red = Missed).
* **Resolution Expansion:** Correct answers in single-input resolution levels (Levels 1 & 3) reveal full resolution paths (e.g. `ti` reveals `ti do`; `fi` reveals `fi sol`).

## VII. Level Architecture & Algorithmic Progression (v13.0 Syllabus)

| Level | Content | Track | Sub-Levels & Rules |
| :--- | :--- | :---: | :--- |
| **1.x** | Diatonic tendencies ID | Melodic (ID) | 1.1: `d-s`, `t-d`, `f-m`; 1.2: `r-d`, `l-s`; 1.3: `m-r-d`, `l-t-d` |
| **2.x** | Diatonic singles ID | Melodic (ID) | 2.1: `t`, `f`; 2.2: `r`, `l`; 2.3: `d`, `m`, `s` |
| **3.x** | Chromatic tendencies + singles ID | Melodic (ID) | 3.1: Chromatic pairs (`fi-s`, `le-s`, `ra-d`, `te-d`); 3.2: 3-note pathway `me-r-d`; 3.3: Chromatic singles (`ra`, `me`, `fi`, `le`, `te`) |
| **4.x** | 2-note diatonic melodies | Melodic | 4.1: Tendency pairs; 4.2: Anchors; 4.3: 2-note random |
| **5.x** | Diatonic dyads — 3rds & 6ths only | Harmonic | 5.1: 3rds & 6ths (including straddling high `do`) |
| **6.x** | 2-note chromatic melodies | Melodic | 6.1: Chromatic pairs; 6.2: Mix; 6.3: Random chromatic |
| **7.x** | 3-note diatonic melodies | Melodic | 7.1: Tendency/random mix; 7.2: Root triads; 7.3: Inversions; 7.4: 3-note random boss |
| **8.x** | Diatonic triads, root position | Harmonic | 8.1: Major; 8.2: Minor; 8.3: All root triads |
| **9.x** | Chromatic dyads — 3rds & 6ths only | Harmonic | 9.1: Chromatic 3rds & 6ths |
| **10.x** | 3-note chromatic melodies | Melodic | 10.1: Chromatic pathway; 10.2: Mix; 10.3: Random chromatic; 10.4: 3-note chromatic boss |
| **10.9** | **CHECKPOINT 1: Mid-Term Review** | Cumulative | **Uniform draw from all unlocked levels (1.1 through 10.4)** |
| **11.x** | 4-note diatonic melodies | Melodic | 11.1: 2 pairs; 11.2: Pair + 2 random; 11.3: 4-note boss |
| **12.x** | Dyads remainder (4ths/5ths/2nds/7ths) | Harmonic | 12.1: Diatonic 4ths/5ths; 12.2: Chromatic 4ths/5ths; 12.3: 2nds/7ths; 12.4: All remaining dyads |
| **13.x** | Triad inversions | Harmonic | 13.1: 1st Inversion `i-6`; 13.2: 2nd Inversion `i-64`; 13.3: All inversions |
| **14.x** | 4-note chromatic melodies | Melodic | 14.1: Chromatic pair + diatonic pair; 14.2: Chromatic pair + 2 random; 14.3: 4-note chromatic boss |
| **15.x** | Dim/aug triads + open voicings | Harmonic | 15.1: Diminished; 15.2: Augmented; 15.3: 3-note open voicings |
| **16.x** | 5-note diatonic melodies | Melodic | 16.1: 2 pairs + 1 random; 16.2: Tendency + chain; 16.3: 5-note boss |
| **17.x** | 7th chords (dominant, maj7, min7) | Harmonic | 17.1: Dominant 7ths & secondary dominants; 17.2: Major/Minor 7ths; 17.3: All 7th chords |
| **18.x** | 5-note chromatic melodies | Melodic | 18.1: Chromatic pathway + diatonic pair; 18.2: Chromatic pair + 3 random; 18.3: 5-note chromatic boss |
| **19.x** | Dim7 chords + 4-note open voicings | Harmonic | 19.1: Half-diminished 7th; 19.2: Fully diminished 7th; 19.3: 4-note open voicings & clusters |
| **19.9** | **CHECKPOINT 2: Comprehensive Final** | Cumulative | **Uniform draw from all unlocked levels (1.1 through 19.3)** |

## VIII. Enharmonic Spelling & Functional Notation
### 1. Functional Enharmonic Priority Hierarchy
1. **Diatonic Defaults:** `0`=do, `2`=re, `4`=mi, `5`=fa, `7`=sol, `9`=la, `11`=ti.
2. **`1` (b2 / #1):** `ra` by default (e.g. `fa ra ti do`); `di` ONLY for ascending $0 \to 1 \to 2$ (`do di re`).
3. **`3` (b3 / #2):** `me` by default (e.g. `me le`); `ri` ONLY for ascending $2 \to 3 \to 4$ (`re ri mi`).
4. **`6` (#4 / b5):** `fi` resolving up to `sol` (7); `se` resolving down to `fa` (5).
5. **`8` (b6 / #5):** `si` in augmented triads / ascending motion (`do mi si`); `le` resolving down to `sol` (7).
6. **`10` (b7 / #6):** `te` by default (e.g. `te do`); `li` ONLY for ascending $9 \to 10 \to 11$ (`la li ti`).

### 2. Scoring & Yellow Correction
* **Perfect (10 pts):** Correct pitch + Correct functional spelling.
* **Near-Miss (9 pts):** Correct pitch + Incorrect spelling.
* **Yellow Correction:** "Near-Miss" entries convert to Preferred Spelling and highlight in yellow upon submission.

***

**August 1 Release Notes (v12.6):**
* **Curriculum Re-Sequenced (v13.0):** Integrated peer review syllabus re-mapping chromatic ID to Level 3.x, early dyad 3rds/6ths to Level 5.x and 9.x, and pacing chromatic melodies alongside diatonic counterparts.
* **Cumulative Checkpoints Added:** Implemented CHECKPOINT 1 (Level 10.9) and CHECKPOINT 2 (Level 19.9) for comprehensive review.
* **Code Remapping:** Re-aligned `isSingleInput`, resolution expansion, and level navigation in `main.lua`.
