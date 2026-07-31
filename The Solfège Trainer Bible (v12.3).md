# The Solfège Trainer Bible (v12.3)
**Status:** Production Refinement - Phase 1 Complete | **Last Updated:** March 20, 2026
**Note on Documentation:** This Bible is a living technical specification and must always be rendered and provided using Markdown.

## I. Executive Summary & Vision
The Solfège Trainer is a gamified, high-performance ear training application designed to move students from simple diatonic pitches to complex chords. It focuses on functional tendencies—the magnetic pull of specific scale degrees toward resolution.
* **Game Mode:** Algorithmic level progression with a manual Level Browser.
* **Practice Mode:** Customizable sandbox for Melodic/Harmonic parameters.
* **The Vibe:** A professional, strictly lowercase, responsive tool with human-like musical "ring-outs."

## II. Intended Platforms & Environment
* **Platform:** Solar2D (Lua).
* **Architecture:** Master/Worker separation. `main.lua` (Director) manages `ui`, `playback`, and `engine`. Workers are independent to prevent circular dependencies.

## III. Core Conventions & Math
* **Solfège Formatting:** **STRICT LOWERCASE** (do, di, ra, re, me, mi, fa, fi, sol, le, la, te, ti).
* **Semitone Mapping (Tonic = 0):** do=0, ra=1, re=2, me=3, mi=4, fa=5, fi=6, sol=7, le=8, la=9, te=10, ti=11.
* **Resolution Direction:** ti must resolve upward to do (11 → 12).
* **Key Rotation:** 50% chance to stay in the same key. If the key repeats, the melody **must** change.
* **Tonic Range:** MIDI 52 (E3) to 64 (E4).
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
* **The Legato Protocol:** Notes overlap by 100ms for a resonant, human feel.
* **The Panic Protocol (Esc):** Calls `globalPanic()`, canceling all timers and stopping all audio immediately.
* **Safe-Stop:** Every `audio.stop` call verifies `audio.isChannelActive` to prevent console errors.
* **Resonance Multipliers:** * Standard Note: 1.0x (800ms).
    * Final Question Note: 1.5x (1200ms) for natural decay.

## VI. UX, Input & Evaluation Logic
* **Keybinds:** ENTER (Submit), C (Cadence), Q (Question), 0 (Reset Score), BACKSPACE (Sequential Delete).
* **Input States:** * **Identification (Levels 1, 2, 7):** Single-input. Reveal on keypress.
    * **Transcription (Levels 3+):** Sequential placeholders (`__ __`). Requires ENTER to submit.
* **The 5-Strike Decay System:** * Note slots start at 10 points. 
    * Errors drop potential by 2 points (10 → 8 → 6 → 4 → 2 → 0).
    * **Partial Credit:** Users earn the current decayed value for any note they get right, even if they fail the overall sequence.
    * **Forced Reveal:** If potential hits 0, answer is revealed (Green = Correct, Red = Missed).
* **Level 1 Expansion:** Correct answers reveal the full resolution (e.g., `ti` reveals `ti do`).

## VII. Level Architecture & Algorithmic Progression
### Phase 1: Diatonic Melodic Expansion
* **Level 1: Diatonic Tendencies (ID Mode)**
    * 1.1: Anchor resolutions (d-s, t-d, f-m).
    * 1.2: Outer step resolutions (r-d, l-s).
    * 1.3: 3-note pathways (m-r-d, l-t-d).
* **Level 2: Single Diatonic Notes (ID Mode)**
    * 2.1: Unstable (t, f); 2.2: Moderate (r, l); 2.3: Stable (d, m, s).
* **Level 3: 2-Note Diatonic Melodies**
    * 3.1: Tendency pairs; 3.2: Note + anchor (d, s, m); 3.3: 2-note random.
* **Level 4: 3-Note Diatonic Melodies**
    * 4.1: Tendency/Random mix (e.g. r-d-sol or sol-t-d).
    * 4.2: Diatonic triads (Root position).
    * 4.3: Diatonic triads (Inversions).
    * 4.4: 3 random diatonic notes (The 3-note Boss).
* **Level 5: 4-Note Diatonic Melodies**
    * 5.1: 2 pairs OR 3-note tendency + 1 random.
    * 5.2: Tendency pair + 2 random notes.
    * 5.3: 4 random diatonic notes (The 4-note Boss).
* **Level 6: 5-Note Diatonic Melodies**
    * 6.1: 2 pairs + 1 random; 6.2: 1 tendency + triad; 6.3: 1 tendency + 3 random; 6.4: 5 random notes (The 5-note Boss).

### Phase 2: Chromatic Melodic Expansion (Future)
* **Level 7: Chromatic Tendencies (ID Mode):** fi-s, le-s, me-r-d, te-d, ra-d.
* **Level 8: Single Chromatic Notes:** Mixed with diatonic.
* **Level 9-12:** Scaled complexity (2-note to 5-note) incorporating up to 3 chromatics.

### Phase 3-5: Dyads & Stacks (Future)
* **Level 13-14:** Diatonic/Chromatic Dyads (2-note stacks).
* **Level 15-18:** 3-Note Stacks (Triads/Clusters). Max Outer Interval = Maj 10th.
* **Level 19-21:** 4-Note Stacks (7th Chords). Max Outer Interval = Perf 12th.

## VIII. Enharmonic Spelling & Functional Notation
### 1. The Functional Priority Stack
Spelling assigned based on hierarchy:
1.  **Tertiary Principle (Stacks):** Form recognizable triads (e.g., [1, 4, 7] = di-mi-sol).
2.  **Chromatic Variety (Clusters):** Avoid same-name succession (Favor re-me over re-ri).
3.  **Leading Tone Principle (Melodic Direction):**
    * Upward: Sharp (di, ri, fi, si, li).
    * Downward: Flat (ra, me, se, le, te).
4.  **Arbitrary Default:** Standard Five (ra, me, fi, le, te).

### 2. Scoring & Yellow Correction
* **Perfect (10 pts):** Correct pitch + Correct functional spelling.
* **Near-Miss (9 pts):** Correct pitch + Incorrect spelling.
* **Yellow Correction:** "Near-Miss" entries convert to Preferred Spelling and highlight in yellow upon submission.

## IX. Implementation Standard
* **main.lua (v13.35):** RNG seeding, Backspace logic, Flat-random cumulative selection.
* **engine.lua (v10.34):** Procedural Generator. 70/30 weight favoring rules over units. Block-shuffling logic.
* **ui.lua (v11.15):** Stacked feedback header. Dynamic box scaling (Size -10% for 5+ notes).
* **playback.lua (v11.20):** Standalone audio engine. Legato Protocol.

***

**March 30 Release Notes:**
* **The Scaler:** UI now auto-shrinks to fit 5+ note dictations.
* **The Spiral Fix:** Cumulative logic now uses a flat-random probability across all unlocked levels in a major group.
* **The Decay Engine:** Implemented 10/8/6/4/2/0 scoring per note slot with partial credit and forced reveals.
* **Quality of Life:** Integrated Backspace/Delete functionality for sequential note corrections.

***
