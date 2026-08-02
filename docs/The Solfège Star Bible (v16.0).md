# The Solfège Star Bible (v16.0)
**Status:** Production - User Menu, Profile Management & 12-Pitch Telemetry Graph Complete | Multi-Profile Switcher, Delete Confirmation, Diatonic/Chromatic Aggregates & Dual-Bar Pitch Visualization | **Last Updated:** August 2, 2026

> **Note on Documentation:** This Bible is a living technical specification and must always be rendered and provided using **Markdown** to ensure cross-platform readability and structural integrity. Every detail written into this specification is permanently preserved and expanded as the project evolves.

---

## I. Executive Summary & Vision
**Solfège Star** is a gamified, high-performance ear training application built in Solar2D (Lua). It trains the human ear to recognize **functional tonal tendencies** (the magnetic pull of scale degrees toward resolution within an established key) rather than raw interval distances.

* **Game Mode:** Features an algorithmic level progression with a manual Level Browser, telemetry-driven adaptive review, and celestial "Musical Constellation" progress unlocks.
* **Practice Mode:** A customizable sandbox where users can specify parameters: Melodic vs. Harmonic, Density, and Content.
* **The Vibe:** A professional, responsive tool with musical "ring-outs", logic-driven RNG preventing repetitive frustration, and strictly lowercase solfège typography.

---

## II. Intended Platforms & Environment
* **Platform:** Solar2D (Lua).
* **Target OS:** iOS, Android, macOS, Windows, Web.
* **Architecture:** Master/Worker separation. `main.lua` (Director & State Machine) manages worker modules (`ui`, `playback`, `engine`, `progression`, `stats`, `definitions`). Workers operate independently to prevent circular dependency crashes.

```
                  ┌──────────────┐
                  │   main.lua   │ (Director & State Machine)
                  └──────┬───────┘
         ┌───────────────┼───────────────┬───────────────┬───────────────┬───────────────┐
         ▼               ▼               ▼               ▼               ▼               ▼
  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
  │ engine.lua │  │  ui.lua    │  │playback.lua│  │progression.│  │ stats.lua  │  │definitions.│
  │ (The Brain)│  │(Visuals)   │  │(The Voice) │  │    lua     │  │ (Telemetry)│  │    lua     │
  └────────────┘  └────────────┘  └────────────┘  └────────────┘  └────────────┘  └────────────┘
```

- **`main.lua` (Director & State Machine)**: Manages app state (`idle`, `quiz`, `result`), listens for hardware/keyboard/touch input, orchestrates timers, evaluates user submissions via agnostic pitch class matching, logs attribute-tagged telemetry to `stats.lua`, and manages session scoring.
- **`engine.lua` (Procedural Brain & Enharmonic Engine)**: Generates random melodies adhering to interval leap limits, anti-repetition rules, diatonic guards, avoiding augmented primes, enforcing context-aware directional enharmonic spelling (`getPreferredName`), and detecting incidental tendencies via `engine.detectTendencies(notes)`.
- **`playback.lua` (Standalone Audio Engine)**: Zero-dependency voice channel manager (32 channels), native `.wav` sample player (`piano_40-C2.wav` through `81-A5.wav`), legato overlap (100ms fade), and panic audio stops.
- **`ui.lua` (Visual Layer)**: Manages physical widescreen real-estate math (`display.actualContentWidth`), oblong landscape stadium pill buttons, 5-piece 3-note tendency gradient transitions, answer buffers (temporal horizontal & spatial vertical stacks), status banners, dynamic 4:3 / 19.5:9 proportional iPad scaling, and user profile / stats / settings modal overlays.
- **`progression.lua` (Syllabus & Curriculum)**: Defines level definitions, unit lists, and rule parameters for Phase 1 (Diatonic) through Phase 5 (Chords).
- **`stats.lua` (Telemetry & Profile Engine)**: Manages multi-user profile storage (`solfege_star_profiles.json` in `system.DocumentsDirectory`), logs attribute-tagged note attempt data, maintains raw counts (no percentage drift), and computes the unified Mastery Index.
- **`definitions.lua` (Legacy Reference)**: Standard semitone maps and resolution arrays.

---

## III. Core Conventions & Math
* **Solfège Formatting:** **STRICT LOWERCASE** (`do`, `di`, `ra`, `re`, `me`, `mi`, `fa`, `fi`, `sol`, `le`, `la`, `te`, `ti`). Note: `sol` is strictly 3 letters.
* **Semitone Mapping (Tonic = 0):** `do`=0, `ra`=1, `re`=2, `me`=3, `mi`=4, `fa`=5, `fi`=6, `sol`=7, `le`=8, `la`=9, `te`=10, `ti`=11.
* **Resolution Direction:** `ti` must resolve upward to `do` (11 → 12 or -1 → 0).
* **Key Rotation (The 50% Rule):** The app has a 50% chance to stay in the same key.
    * **Enforced Variety:** If staying in the same key, the engine is **forbidden** from picking the same melody unit twice in a row.
* **Tonic Range:** The MIDI tonic reference is randomly assigned between **MIDI 52 (E3)** and **64 (E4)**.
* **Sample Audio Clamping:** Strict octave bounds clamping ($40 \le \text{MIDI} \le 81$) prevents silent audio failures.
* **UI Nomenclature:** Flat-dominant naming (C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B).
* **The Global Octave Ban:** The app must NEVER play the same solfège note in different octaves simultaneously (Absolute constraint).

---

## IV. Harmonic Foundation: The Cadence Engine
The cadence is the pedagogical "anchor." A new key is always established by a I-IV-V-I Cadence.

1.  **Voice Leading Logic**
    * **The Soprano Anchor (Levels 1-6):** Cadence voiced with **do4** (MIDI 72) in the soprano. Tonic (`do`) is maintained as a common tone during I-IV.
    * **Bass Foundation:** Literal root (`do`-`fa`-`sol`-`do`) exactly one octave below the tonic reference.
    * **Standardized Voicing (Example in C):**
        * Chord 1 (I): `{48, 64, 67, 72}` (do2, mi3, sol3, do4)
        * Chord 2 (IV): `{53, 65, 69, 72}` (fa2, fa3, la3, do4)
        * Chord 3 (V): `{55, 62, 67, 71}` (sol2, re3, sol3, ti3)
        * Chord 4 (I): `{48, 64, 67, 72}` (do2, mi3, sol3, do4)
2.  **Unified Timing Protocol**
    * **Base Duration ($BP$):** 800ms.
    * **Cadence Pulse:** 1.0x → 1.0x → 1.0x → **1.5x**.
    * **The Final Ring-out:** The final chord holds for **1.5x** duration (1200ms) to blend into "The Breath."
    * **The Breath (Silence):** A mandatory 2.0x (1600ms) wait after the cadence before the question begins.

---

## V. Audio Execution & Playback Mechanics
1.  **The Legato (Voice-Off) Protocol**
    * **Voice Management:** Max 32 voices tracked in a registry.
    * **The Panic Protocol (Esc / Level Switch):** Calls `globalPanic()`, which cancels all registered timers and stops all audio channels immediately.
    * **Safety Check:** Every `audio.stop` call verifies `audio.isChannelActive(id)` to prevent console errors.
2.  **Durations and Resonance Multipliers**
    * **Standard Melody Notes:** 1.0x (800ms).
    * **Final Question Note:** **1.5x (1200ms)** for a natural musical decay.
    * **Auto-Advance Delay:** Correct answers trigger a **1600ms** (2-pulse) delay.
    * **Fast Tendencies:** 0.5x (400ms) for specific 3-note units (e.g., `m-r-d`).
    * **Harmonic Stacks:** 4.0x (3200ms) to allow for vocal locking.

---

## VI. Global Builder Guardrails
* **Anti-Repetition Rule:** No identical pitch classes back-to-back within a sequence.
* **Double-Chromatic Ban:** Consecutive half-steps (e.g., `f-fi-s`) are strictly forbidden in low/mid levels.
* **Chromatic Limits:**
  * **Level 6.x (2-Note Chromatic Melodies):** **Strict 1 Chromatic Max** (1 chromatic + 1 diatonic). Never generates two chromatics (e.g. `fi di`).
  * **Level 10.x (3-Note Chromatic Melodies):** **Strict 1 Chromatic Max**.
  * **Level 14.x (4-Note Chromatic Melodies):** **Up to 2 Chromatics Max**.
  * **Level 18.x (5-Note Chromatic Melodies):** **Up to 3 Chromatics Max**.
* **Composite Pool Lookup:** Engine searches `definitions.lua` root first, then sub-tables (`tendencies`, `single_diatonic`).
* **Variety Lock:** If a tonic is repeated, the melody unit MUST change.

---

## VII. UX, Touch Keypad Architecture & Responsive Layout
* **Keybinds & Touch Targets:**
    * `ENTER` / `↵ submit`: Submit multi-note answer.
    * `BACKSPACE` / `⌫ del`: Sequential delete / backspace note input.
    * `C` / `k` / `play key`: Replay key cadence.
    * `Q` / `question`: Replay exercise melody.
    * `ARROW KEYS` / `« ◀ ▶ »`: Level navigation.
    * `SHIFT + ARROWS` / `« »`: Major level jump.
* **Symmetrical Edge Action Button Pairs:**
    * **Left Edge**: `play key` (top, blue) and `question` (bottom, green) anchored at `leftEdgeX = screenOriginX + math.max(52, screenW * 0.08)`.
    * **Far-Right Edge**: `⌫ del` (top, crimson) and `↵ submit` (bottom, emerald green) anchored at `rightEdgeX = screenOriginX + screenW - math.max(52, screenW * 0.08)`, perfectly mirroring the left pair.
    * **Vertical Alignment**: Both button pairs share identical $86 \times 38$ stadium pill dimensions and are centered vertically on the answer plane (`screenOriginY + screenH * 0.38`).
* **PIN Cursor-Pointer Ring-Buffer Overwriting:**
    * Inputs use a wrap-around cursor pointer ($1 \to 2 \to 3 \to \dots \to 1$).
    * Tapping a key when the answer buffer is full overwrites the active cursor slot and advances to the next slot (e.g. for a 3-note box A, B, C: typing `1 2 3` gives A=1, B=2, C=3; typing `4` gives A=4, B=5, C=3; typing `5` gives A=4, B=5, C=3). Single-note exercises immediately overwrite slot 1.
* **Tap-To-Start Level Switching:** Navigating to a new level updates status to `"tap here to start exercise"`, sets state to `"idle"`, and waits for user tap or Enter/Space without auto-playing the cadence.
* **Input States:**
    * **Identification (Levels 1, 2, 3):** Single-input. Immediate reveal on keypress.
    * **Sequential Transcription (Levels 4, 6, 7, 10, 11, 14, 16, 18):** Sequential placeholders (`__ __`). Requires ENTER or `↵ submit` to evaluate. Rendered in a horizontal left-to-right temporal buffer.
    * **Harmonic Stack Dictation (Levels 5, 8, 9, 12, 13, 15, 17, 19):** Simultaneous chord audio. **Students MUST enter notes from the bottom up** (Bass $\to$ Soprano). Rendered in a spatialized vertical answer buffer with feedback displayed cleanly on the right side (`x = screenW * 0.74`) to eliminate visual overlap.
* **Proportional Aspect Ratio Scaling (iPad 4:3 vs iPhone 19.5:9):**
    * Re-architected vertical offset math using relative `screenH` percentages (`math.max(..., screenH * fraction)`).
    * Prevents header/banner/keypad overlap on 4:3 iPad displays while maintaining widescreen elegance.
* **Oblong Landscape Stadium Pill Geometry:**
    * Stadium pill geometry (`pillRadius = kH * 0.5`) with 3D bottom drop shadow and glass border frame.
* **Concentric Glass Sheen Highlight:**
    * Concentric 4px inset stadium pill glass sheen fading from 25% white opacity at top edge down to 0% transparency at 33% of the way down (`scaleY = 0.33`, `fill.y = -0.335`), leaving the bottom 67% completely clear.
* **5-Piece 3-Note Tendency Gradient Algorithm:**
    * Continuous 3-stop gradient across 3-note tendency buttons (`basePill` + `leftCap` $c_1 \to c_2$ + `rightCap` $c_2 \to c_3$ + `midLeft` $m_{12} \to c_2$ + `midRight` $c_2 \to m_{23}$).
* **Uniform Tendency Button Width:** Standardized `maxKW = 130px` across all 2-note and 3-note tendency pills (`me-r-d`, `l-t-d`, `fi-s`, etc.).
* **Kodály Octave Vertical Line Rules:**
    * **Base Octave** ($\text{tonicMIDI} \le \text{MIDI} < \text{tonicMIDI} + 12$): Clean solfège syllable with **NO MARK** (`do`, `re`, `mi`, `fa`, `sol`, `la`, `ti`).
    * **Upper Octave** ($\text{MIDI} \ge \text{tonicMIDI} + 12$): Uses High Vertical Line **`ˈ`** (`U+02C8`), e.g. `doˈ`, `reˈ`.
    * **Lower Octave** ($\text{MIDI} < \text{tonicMIDI}$): Uses Low Vertical Line **`ˌ`** (`U+02CC`), e.g. `solˌ`, `laˌ`, `tiˌ` (formatted in answers as `tˌ r` or `tˌ rˌ`).

---

## VIII. Enharmonic Spelling & Agnostic Pitch Class Scoring Paradigm Shift
* **Aural Ear-Training Focus:** Because mobile and tablet keypads present single combined chromatic touch targets (`le / si`, `ra / di`, `me / ri`, `fi / se`, `te / li`), students cannot specify whether they intend `#` vs `b`.
* **Zero Spelling Penalties:** Submitting any chromatic key matching the target pitch class awards **100% full credit (10/10 points)** with **zero spelling deductions or near-miss penalties**.
* **Theoretical Auto-Correction Feedback:** Upon answer evaluation, the answer buffer automatically converts the display text to the music-theoretically preferred spelling (`engine.getPreferredName`), passively teaching students correct music theory without penalizing touch input.

---

## IX. Directional Enharmonic Priority Hierarchy
1. **Rule A — Avoid Augmented Primes:** Avoid spelling chromatic inflections on the same letter base as preceding notes unless moving by step (e.g. prefer `sol` $\to$ `le` $G \to A\flat$ over `sol` $\to$ `si` $G \to G\sharp$).
2. **Rule B — Melodic Contours:**
   - **Ascending Minor Seconds:** Sharp inflections (`di`, `ri`, `fi`, `si`, `li`).
   - **Descending Minor Seconds:** Flat inflections (`ra`, `me`, `se`, `le`, `te`).
3. **Rule C — Chords & Harmonics:** Augmented triads (`do mi si`) use `si`; harmonic minor / scale degree 6 (`s le t d`) uses `le`.

---

## X. Master Level Architecture & Algorithmic Progression

### Phase 1: Diatonic Melodic Expansion
* **Level 1: Diatonic Tendencies (ID Mode)**
  * 1.1: Anchor resolutions (`d-s`, `t-d`, `f-m`).
  * 1.2: Outer step resolutions (`r-d`, `l-s`).
  * 1.3: 3-note pathways (`m-r-d`, `l-t-d`).
* **Level 2: Single Diatonic Notes (ID Mode)**
  * 2.1: Unstable (`t`, `f`).
  * 2.2: Moderately stable (`r`, `l`).
  * 2.3: Stable (`d`, `m`, `s`).
* **Level 3: Chromatic Tendencies + Singles (ID Mode)**
  * 3.1: Chromatic pairs (`fi-s`, `le-s`, `ra-d`, `te-d`).
  * 3.2: 3-note chromatic pathway (`me-r-d`).
  * 3.3: Full chromatic keyboard (`ra`, `me`, `fi`, `le`, `te`).
* **Level 4: 2-Note Diatonic Melodies (Transcription Mode)**
  * *Constraint: Never greater than 1 octave apart.*
  * 4.1: Tendency pairs (2-note resolutions like `t-d`, `f-m`, `r-d`).
  * 4.2: Any diatonic note + stable anchor (`d`, `s`, `m`, `f`) in any order.
  * 4.3: Any two diatonic notes (Fully randomized pairs).
* **Level 5: Diatonic Dyads — 3rds & 6ths Only (Harmonic Stack)**
  * 5.1: Consonant 3rds & 6ths (including straddling high `do`).
* **Level 6: 2-Note Chromatic Melodies (Transcription Mode)**
  * *Constraint: EXACTLY 1 Chromatic Note Max (1 chromatic + 1 diatonic). Never generates 2 chromatics.*
  * 6.1: 2-note chromatic resolutions (`fi-s`, `le-s`, `ra-d`, `te-d`).
  * 6.2: 2-note diatonic/chromatic mix (1 chromatic + 1 diatonic).
  * 6.3: 2-note random chromatic (1 chromatic max).
* **Level 7: 3-Note Diatonic Melodies**
  * 7.1: Tendency pair + random single OR single + tendency pair.
  * 7.2: Diatonic triads (root position).
  * 7.3: Diatonic triads (any inversion).
  * 7.4: 3 random diatonic notes.
* **Level 8: Diatonic Triads (Root Position) Stacks**
  * 8.1: Major triads (`i`, `iv`, `v`).
  * 8.2: Minor triads (`ii`, `iii`, `vi`).
  * 8.3: All root triads (including `vii-o`).

### Phase 2: Chromatic Melodic Expansion
* **Level 9: Chromatic Dyads — 3rds & 6ths Only (Harmonic Stack)**
  * *Constraint: 1 Chromatic Max per dyad.*
  * 9.1: Chromatic 3rds (`d-me`, `r-fi`, `m-fi`, `s-te`, `t-ri`) and 6ths (`le-m`).
* **Level 10: 3-Note Chromatic Melodies (Transcription Mode)**
  * *Constraint: STRICT 1 Chromatic Max per melody.*
  * 10.1: 3-note chromatic pathways & mix (Procedurally generates 1 chromatic tendency pair + 1 diatonic note in any position, e.g. `fi-s + d`, `le-s + m`, `me-r + d`).
  * 10.2: 3-note chromatic random (1 chromatic + 2 diatonic notes).
  * 10.3: 3-note chromatic boss (1 chromatic pair + 1 diatonic).
* **Level 10.9: CHECKPOINT 1: Mid-Term Review**
  * *Cumulative Review: Uniform draw across all unlocked levels (1.1 through 10.4).*
* **Level 11: 4-Note Diatonic Melodies**
  * 11.1: Two sequential tendency pairs.
  * 11.2: One tendency pair + 2 random diatonic notes.
  * 11.3: Four random diatonic notes (4-note diatonic boss).
* **Level 12: Dyads Remainder (4ths/5ths/2nds/7ths, Diatonic + Chromatic)**
  * 12.1: Diatonic 4ths & 5ths.
  * 12.2: Chromatic 4ths & 5ths.
  * 12.3: Diatonic 2nds & 7ths.
  * 12.4: All remaining dyads.

### Phase 3: Inversions & 4-Note Chromatics
* **Level 13: Triad Inversions (Harmonic Stack)**
  * 13.1: 1st Inversion (`i-6`, `iv-6`, `v-6`).
  * 13.2: 2nd Inversion (`i-64`, `iv-64`, `v-64`).
  * 13.3: All inverted triads.
* **Level 14: 4-Note Chromatic Melodies (Transcription Mode)**
  * *Constraint: Up to 2 Chromatics Max.*
  * 14.1: 1 chromatic pair + 1 diatonic pair.
  * 14.2: 1 chromatic pair + 2 random notes.
  * 14.3: 4-note chromatic boss (up to 2 chromatics).

### Phase 4: Complex Triads & 5-Note Melodies
* **Level 15: Diminished/Augmented Triads & Open Voicings (Harmonic Stack)**
  * *Constraint: Max Outer Interval = Major 10th (16 semitones).*
  * 15.1: Diminished triads (`vii-o`, `ii-o`).
  * 15.2: Augmented triads (`iii+`, `i+`).
  * 15.3: 3-note open voicings.
* **Level 16: 5-Note Diatonic Melodies**
  * 16.1: Two tendency pairs + 1 random diatonic.
  * 16.2: One tendency pair + 3-note chain/triad.
  * 16.3: Five random diatonic notes (5-note diatonic boss).
* **Level 17: 7th Chords (Harmonic Stack)**
  * 17.1: Dominant 7ths & secondary dominants (`v7`, `v7/iv`, `v7/v`, `v7/vi`, `v7-65`, `v7-43`).
  * 17.2: Major & Minor 7th chords (`i-maj7`, `iv-maj7`, `ii7`, `vi7`).
  * 17.3: All 7th chords.

### Phase 5: 5-Note Chromatic Melodies & Advanced 4-Note Stacks
* **Level 18: 5-Note Chromatic Melodies**
  * *Constraint: Up to 3 Chromatics Max.*
  * 18.1: Chromatic pathway + diatonic pair.
  * 18.2: 1 chromatic pair + 3 random notes.
  * 18.3: 5-note chromatic boss (up to 3 chromatics).
* **Level 19: Dim7 Chords & 4-Note Open Voicings (Harmonic Stack)**
  * *Constraint: Max Outer Interval = Perfect 12th (19 semitones). Max Inner Interval = Major 7th (11 semitones).*
  * 19.1: Half-diminished 7th (`vii-o7`).
  * 19.2: Fully diminished 7th (`dim7`).
  * 19.3: 4-note open voicings & clusters.
* **Level 19.9: CHECKPOINT 2: Comprehensive Final Review**
  * *Cumulative Review: Uniform draw across all unlocked levels (1.1 through 19.3).*

---

## XI. User Telemetry & Multi-Profile Engine (`stats.lua`)

### 1. Architectural Philosophy
Telemetry in **Solfège Star** is governed by three foundational principles:
1. **Raw Attempt Counts (No Percentage Drift)**: Only raw `attempts` and `correct` tallies are saved. All percentages, averages, and mastery levels are computed dynamically on demand.
2. **Attribute-Based Tagging (Syllabus Resilience)**: Note attempt events are tagged by musical attributes (`pitchClass`, `mode`, `noteCount`, `positionInSequence`, `tendencyID` + `contextSource`, `chordQuality`, `keyCenter`) rather than fixed Level IDs. If the curriculum is reordered or renumbered in future releases, student progress history remains 100% un-corrupted.
3. **Three-Audience Framing**: Rich diagnostic metrics (context-crossed pitch accuracy, position-in-sequence fatigue, key-center cross-checks) are gathered internally for the app's engine, while a clean, motivational subset (streaks, overall pitch mastery) is displayed to the student.

### 2. The Unified Mastery Index Algorithm
The **Mastery Index** is a single scalar $[0.0 \dots 1.0]$ driving gamification, constellation brightness, adaptive review, and level unlocks. It combines three weighted factors:

$$\text{MasteryIndex} = w_a \cdot \text{Accuracy} + w_v \cdot \text{VolumeFactor} + w_r \cdot \text{RecencyFactor}$$

- **Accuracy**: $\frac{\text{correct}}{\text{attempts}}$.
- **Volume Factor**: $\min\left(1.0, \frac{\ln(1 + \text{attempts})}{\ln(1 + N_{\text{target}})}\right)$, where $N_{\text{target}} = 50$ attempts. (Prevents $1/1 = 100\%$ from declaring a concept "mastered").
- **Recency Factor**: Exponential decay over unpracticed days: $e^{-\lambda \cdot t_{\text{idle}}}$.

### 3. Telemetry Event Schema (`stats.logAttempt`)
Every evaluated note attempt passes a structured event to `stats.logAttempt(event)`:
- `pitchClass`: $[0 \dots 11]$
- `isCorrect`: boolean
- `mode`: `"single" | "melody" | "stack"`
- `noteCount`: integer ($1 \dots 5$)
- `position`: integer ($1 \dots N$)
- `tendencyInfo`: `{ id = "t-d", source = "explicit" | "procedural" | "accidental" }` (optional)
- `chordQuality`: string (optional)
- `keyCenter`: integer (MIDI tonic reference)

---

## XII. User Menu, Profile System & 12-Pitch Graphing Telemetry

### 1. Top-Left Header User Anchor & Session Score
The top-left header features a responsive **User Control Pill** (`x = screenOriginX + math.max(72, screenW * 0.085)`, `y = headerY`) with the active **Session Score** stacked directly underneath:
- Displays `👤 Sign In` when no user is signed in.
- Displays `👤 <Name>` (e.g. `👤 Alex`) when an active user profile is loaded.
- Tapping the pill triggers the popover **User Menu**.
- **Session Score (`score: <N>`)**: Displays points earned during the active practice session. Resets or increments as exercises are completed in the current session.

### 2. User Menu Popover & Navigation
A sleek glassmorphic popover menu providing context-sensitive navigation:
- **Unauthenticated State**: Displays a single action: **`Sign In`**.
- **Authenticated State**: Displays three actions: **`Stats`**, **`Settings`**, **`Sign Out`**.
  - **`Sign Out`**: Resets active profile state and returns user to the unauthenticated `👤 Sign In` state.

### 3. Sign In & New User Creation Modals
- **Sign In Modal**: Displays a scrollable list of all registered student profiles saved in `solfege_star_profiles.json`. Tapping any profile sets it as the active user. A **`+ New User`** button sits at the bottom.
- **New User Dialog**: An input dialog featuring a native text field (`maxChars = 16`). Allows letters, numbers, spaces, and special characters. Tapping `[Create Profile]` creates the profile, sets it active, and auto-saves to JSON.

### 4. Settings & Profile Deletion Safety
- **Settings Modal**: Displays current profile metadata and a **`Delete Profile`** button.
- **Safety Confirmation Dialog**: Tapping `Delete Profile` triggers an explicit confirmation overlay: `"Are you sure you want to delete profile '<Name>'?"` with `[Yes, Delete]` (crimson) and `[Cancel]` (glass grey). Deleting a profile removes it from local JSON and returns to the initial state.

### 5. Telemetry Stats Modal & 12-Pitch Dual-Bar Graph
The **Stats Modal** displays comprehensive ear-training performance analytics:
1. **Summary Cards Row (5 Metrics)**:
   - **Total Points**: Lifetime cumulative points earned across all sessions (`prof.lifetime.totalPoints`). Format: `<N> pts`.
   - **Total Accuracy**: `Right / Total (%)` (e.g. `60/80 (75%)`).
   - **Longest Streak**: All-time longest streak of consecutive correct answers.
   - **Diatonic Accuracy**: Cumulative accuracy across all 7 diatonic pitches (`do`, `re`, `mi`, `fa`, `sol`, `la`, `ti`). Format: `Right / Total (%)`.
   - **Chromatic Accuracy**: Cumulative accuracy across all 5 chromatic pitches (`ra/di`, `me/ri`, `fi/se`, `le/si`, `te/li`). Format: `Right / Total (%)`.
2. **12-Pitch Dual-Bar & Accuracy Overlay Visualization Graph**:
   - **Dynamic Y-Axis Scaling**: The Y-axis max scale is determined by `maxAttemptsAcrossAll12Pitches` (minimum 10 attempts).
   - **12 Column Layout ($X_0 \dots X_{11}$)**:
     - **Orange Bar (Left, 4px wide)**: Number of **Right Answers** for that pitch, scaled against `maxAttempts`.
     - **Green Bar (Right, 4px wide, 8px offset)**: Total **Attempts** for that pitch, scaled against `maxAttempts`.
     - **Translucent Blue Overlay**: Translucent blue column (`alpha = 0.25`) representing Accuracy % ($0\% \dots 100\%$ scaling full height of Y-axis).
     - **X-Axis Solfège Labels**: Strictly lowercase pitch labels (`do`, `ra`, `re`, `me`, `mi`, `fa`, `fi`, `sol`, `le`, `la`, `te`, `ti`).

***

**August 2 Release Notes (v16.0):**
* **Master Version Upgrade (v16.0):** Created master Bible v16.0 adding Section XII detailing User Menu, Profile Management, Settings, Lifetime Total Points, and 12-Pitch Telemetry Graphing.
* **Archive Policy Enforced:** Saved historical Bible v15.0 to `zzzz archives/The Solfège Star Bible (v15.0).md`.
* **Live Telemetry & Total Points Integration:** Wired `stats.logAttempt()` and `stats.addPoints()` into `evaluateSubmission()` in `main.lua` to track live per-pitch performance and accumulate lifetime total points.
* **User Profile & Modal System:** Implemented top-left `👤 User` header control, popover menu, Sign-In modal, New User creation dialog (max 16 chars), and Settings deletion confirmation dialog.
* **12-Pitch Dual-Bar & Accuracy Graphing:** Implemented 12-column visualization displaying Right Answers (Orange), Total Attempts (Green), and Accuracy % (Translucent Blue) scaled against `maxAttempts`.
