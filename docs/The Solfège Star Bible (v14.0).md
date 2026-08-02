# The Solfège Star Bible (v14.0)
**Status:** Production - Solfège Star Release | Bidirectional Enharmonic Equivalence, PIN Ring-Buffer Overwrite, Onscreen Backspace, Tap-to-Start Level Switching, iPad 4:3 Layout Math & Kodály Octave Vertical Lines Complete | **Last Updated:** August 1, 2026
**Note on Documentation:** This Bible is a living technical specification and must always be rendered and provided using Markdown.

## I. Executive Summary & Vision
**Solfège Star** is a gamified, high-performance ear training application built in Solar2D (Lua) designed to train students to recognize **functional tonal tendencies**—the magnetic pull of specific scale degrees toward resolution within an established key.
* **Game Mode:** Algorithmic level progression with a manual Level Browser.
* **Practice Mode:** Customizable sandbox for Melodic/Harmonic parameters.
* **Theme & Progression:** "Musical Constellation" unlocks and celestial progress tracking.
* **The Vibe:** A professional, strictly lowercase, responsive tool with human-like musical "ring-outs."

## II. Intended Platforms & Environment
* **Platform:** Solar2D (Lua).
* **Architecture:** Master/Worker separation. `main.lua` (Director) manages `ui`, `playback`, `engine`, `progression`, and `definitions`. Workers are independent to prevent circular dependencies.

## III. Core Conventions & Math
* **Solfège Formatting:** **STRICT LOWERCASE** (`do`, `di`, `ra`, `re`, `me`, `mi`, `fa`, `fi`, `sol`, `le`, `la`, `te`, `ti`). Note: `sol` is strictly 3 letters.
* **Semitone Mapping (Tonic = 0):** `do`=0, `ra`=1, `re`=2, `me`=3, `mi`=4, `fa`=5, `fi`=6, `sol`=7, `le`=8, `la`=9, `te`=10, `ti`=11.
* **Resolution Direction:** `ti` must resolve upward to `do` (11 → 12).
* **Key Rotation:** 50% chance to stay in the same key. If the key repeats, the melody **must** change.
* **Tonic Range:** MIDI 52 (E3) to 64 (E4).
* **Sample Audio Clamping:** Strict octave bounds clamping ($40 \le \text{MIDI} \le 81$) prevents silent audio failures.
* **UI Nomenclature:** Flat-dominant (C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B).
* **The Global Octave Ban:** Never play the same solfège note in different octaves simultaneously.

## IV. Harmonic Foundation: The Cadence Engine
A new key is always established by a I-IV-V-I Cadence.
* **The Soprano Anchor:** `do4` (MIDI 72) is maintained as a common tone during I-IV.
* **Bass Foundation:** Literal root (`do`-`fa`-`sol`-`do`) exactly one octave below the tonic reference.
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
* **Keybinds & Touch Targets:**
    * `ENTER` / `↵ submit`: Submit multi-note answer.
    * `BACKSPACE` / `⌫ del`: Sequential delete / backspace note input.
    * `C` / `k` / `[ cadence ]`: Replay key cadence.
    * `Q` / `[ replay ]`: Replay exercise melody.
    * `ARROW KEYS` / `« ◀ ▶ »`: Level navigation.
    * `SHIFT + ARROWS` / `« »`: Major level jump.
* **PIN-Style Ring-Buffer Overwriting:** Tapping a key when the answer buffer is full automatically shifts out the oldest answer (slot 1) and appends the new note to the end (e.g. typing `d r m` then `f` yields `r m f`). Single-note exercises immediately overwrite slot 1.
* **Tap-To-Start Level Switching:** Navigating to a new level updates status to `"tap here to start exercise"`, sets state to `"idle"`, and waits for user tap or Enter/Space without auto-playing the cadence.
* **Input States:**
    * **Identification (Levels 1, 2, 3):** Single-input. Immediate reveal on keypress.
    * **Sequential Transcription (Levels 4, 6, 7, 10, 11, 14, 16, 18):** Sequential placeholders (`__ __`). Requires ENTER or `↵ submit` to evaluate. Rendered in a horizontal left-to-right temporal buffer.
    * **Harmonic Stack Dictation (Levels 5, 8, 9, 12, 13, 15, 17, 19):** Simultaneous chord audio. **Students MUST enter notes from the bottom up** (Bass $\to$ Soprano). Rendered in a spatialized vertical answer buffer with feedback displayed cleanly on the right side (`x = screenW * 0.74`) to eliminate visual overlap.
* **The 5-Strike Decay System:**
    * Note slots start at 10 points. 
    * Errors drop potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
    * **Partial Credit:** Users earn the current decayed value for any note they get right.
* **Kodály Octave Vertical Line Rules:**
    * **Base Octave** ($\text{tonicMIDI} \le \text{MIDI} < \text{tonicMIDI} + 12$): Clean solfège syllable with **NO MARK** (`do`, `re`, `mi`, `fa`, `sol`, `la`, `ti`).
    * **Upper Octave** ($\text{MIDI} \ge \text{tonicMIDI} + 12$): Uses High Vertical Line **`ˈ`** (`U+02C8`), e.g. `doˈ`, `reˈ`.
    * **Lower Octave** ($\text{MIDI} < \text{tonicMIDI}$): Uses Low Vertical Line **`ˌ`** (`U+02CC`), e.g. `solˌ`, `laˌ`, `tiˌ` (formatted in answers as `tˌ r` or `tˌ rˌ`).
* **Bidirectional Enharmonic Equivalence Matching (`isNameEquivalent`):**
    * Automatically accepts all enharmonic pairs as 100% correct regardless of expected spelling:
        * `di` $\leftrightarrow$ `ra` (Pitch Class 1)
        * `ri` $\leftrightarrow$ `me` (Pitch Class 3)
        * `fi` $\leftrightarrow$ `se` (Pitch Class 6)
        * `si` $\leftrightarrow$ `le` (Pitch Class 8)
        * `li` $\leftrightarrow$ `te` (Pitch Class 10)
    * Solves chorister feedback (e.g. `d m si` vs `d m le`).

## VII. Level Architecture & Algorithmic Progression (v14.0 Syllabus)

| Level | Content | Track | Sub-Levels & Rules |
| :--- | :--- | :---: | :--- |
| **1.x** | Diatonic tendencies ID | Melodic (ID) | 1.1: `d-s`, `f-m`, `t-d`; 1.2: `r-d`, `l-s`; 1.3: `m-r-d`, `l-t-d` |
| **2.x** | Diatonic singles ID | Melodic (ID) | 2.1: `t`, `f`; 2.2: `r`, `l`; 2.3: `d`, `m`, `s` |
| **3.x** | Chromatic tendencies + singles ID | Melodic (ID) | 3.1: Chromatic pairs (`fi-s`, `le-s`, `ra-d`, `te-d`); 3.2: 3-note pathway `me-r-d`; 3.3: Full chromatic keyboard |
| **4.x** | 2-note diatonic melodies | Melodic | 4.1: Tendency pairs; 4.2: Anchors; 4.3: 2-note random |
| **5.x** | Diatonic dyads — 3rds & 6ths only | Harmonic | 5.1: 3rds & 6ths (including straddling high `do`) |
| **6.x** | 2-note chromatic melodies | Melodic | 6.1: 2-note chromatic resolutions; 6.2: Mix; 6.3: Random chromatic |
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

## VIII. Enharmonic Spelling & Agnostic Pitch Class Scoring Paradigm Shift

### 1. The Touch Screen Paradigm Shift (Agnostic Pitch Class Scoring)
* **Aural Ear-Training Focus:** Because mobile and tablet keypads present single combined chromatic touch targets (`le / si`, `ra / di`, `me / ri`, `fi / se`, `te / li`), students cannot specify whether they intend `#` vs `b`.
* **Zero Spelling Penalties:** Submitting any chromatic key matching the target pitch class awards **100% full credit (10/10 points)** with **zero spelling deductions or near-miss penalties**.
* **Theoretical Auto-Correction Feedback:** Upon answer evaluation, the answer buffer automatically converts the display text to the music-theoretically preferred spelling (`engine.getPreferredName`), passively teaching students correct music theory without penalizing touch input.

### 2. Functional Music Theory Rules for Auto-Correction (`getPreferredName`)
1. **Rule A — Avoid Augmented Primes:** Avoid spelling chromatic inflections on the same letter base as preceding notes unless moving by step (e.g. prefer `sol` $\to$ `le` $G \to A\flat$ over `sol` $\to$ `si` $G \to G\sharp$).
2. **Rule B — Melodic Contours:**
   - **Ascending Minor Seconds:** Sharp inflections (`di`, `ri`, `fi`, `si`, `li`).
   - **Descending Minor Seconds:** Flat inflections (`ra`, `me`, `se`, `le`, `te`).
3. **Rule C — Chords & Harmonics:** Augmented triads (`do mi si`) use `si`; harmonic minor / scale degree 6 (`s le t d`) uses `le`.

## IX. Touch Keypad Architecture & Responsive Layout
* **Proportional Aspect Ratio Scaling (iPad 4:3 vs iPhone 19.5:9):**
    * Re-architected vertical offset math using relative `screenH` percentages (`math.max(..., screenH * fraction)`).
    * Prevents header/banner/keypad overlap on 4:3 iPad displays while maintaining widescreen elegance.
* **Oblong Landscape Stadium Pill Geometry:**
    * Stadium pill geometry (`pillRadius = kH * 0.5`) with 3D bottom drop shadow and glass border frame.
* **Concentric Glass Sheen Highlight:**
    * Concentric 4px inset stadium pill glass sheen fading from 28% white opacity down to 0% transparency.
* **5-Piece 3-Note Tendency Gradient Algorithm:**
    * Continuous 3-stop gradient across 3-note tendency buttons (`basePill` + `leftCap` $c_1 \to c_2$ + `rightCap` $c_2 \to c_3$ + `midLeft` $m_{12} \to c_2$ + `midRight` $c_2 \to m_{23}$).
* **Uniform Tendency Button Width:** Standardized `maxKW = 130px` across all 2-note and 3-note tendency pills (`me-r-d`, `l-t-d`, `fi-s`, etc.).

***

**August 1 Release Notes (v14.0):**
* **Rebranded to Solfège Star!**
* **Agnostic Pitch Class Scoring & Theoretical Auto-Correction:** Eliminated spelling penalties/deductions; correct pitch classes award 100% full credit while feedback auto-corrects to proper theory spelling.
* **Bidirectional Enharmonic Equivalence:** `isNameEquivalent` accepts all enharmonic pairs (`si` $\leftrightarrow$ `le`, `di` $\leftrightarrow$ `ra`, etc.).
* **Music Theory Spelling Engine:** Upgraded `getPreferredName` to avoid augmented primes and enforce melodic contours.
* **PIN Ring-Buffer Overwriting:** Full answer buffers automatically shift out oldest note when tapping new keys.
* **Onscreen `⌫ del` Touch Button:** Added mobile backspace target next to answer boxes.
* **Tap-To-Start Level Switching:** Changing levels sets state to `"idle"` without auto-playing cadence.
* **Responsive iPad 4:3 Scaling:** Dynamic vertical layout math prevents UI element overlap across all screen aspect ratios.
