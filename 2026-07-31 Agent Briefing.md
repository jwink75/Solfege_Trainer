Here is a comprehensive summary and state-of-the-project brief designed to get another LLM instance (like Gemini in Google Antigravity CLI) instantly synced on the codebase, design decisions, architectural rules, and immediate roadmap.

Solfège Trainer — Comprehensive Project Sync & Brief

1. Executive Summary & Vision

The Solfège Trainer is a gamified, high-performance ear training application built in Solar2D (Lua). Unlike standard interval-recognition apps, it trains the ear to hear functional tendencies—the magnetic pull of scale degrees toward resolution within a established tonal center.

The app features algorithmic, automatic exercise generation, cumulative "spiral learning," and a procedural engine that balances hardcoded pedagogical units with rule-based random melodies.

1. Architecture & File Structure

The codebase uses a strict Master/Worker Separation to prevent circular dependency crashes.

├── config.lua         -- Window view dimensions (320x480)[span_6](start_span)[span_6](end_span)

├── build.settings   -- Solar2D display/scaling configuration (letterbox)[span_7](start_span)[span_7](end_span)

├── main.lua         -- v13.35: Director/State Machine & Input Orchestration[span_8](start_span)[span_8](end_span)[span_9](start_span)[span_9](end_span)

├── engine.lua         -- v10.40: Procedural Melody Generator & Chromatic Spelling[span_10](start_span)[span_10](end_span)[span_11](start_span)[span_11](end_span)

├── progression.lua   -- v12.9: Syllabus, Level Curriculum & Rules[span_12](start_span)[span_12](end_span)

├── playback.lua       -- v11.20: Standalone Audio Engine & Sample Player[span_13](start_span)[span_13](end_span)[span_14](start_span)[span_14](end_span)

├── ui.lua             -- v11.15: Dynamic Auto-Scaling Visual Layer[span_15](start_span)[span_15](end_span)[span_16](start_span)[span_16](end_span)

└── definitions.lua   -- v10.1: Legacy semitone arrays & resolution references[span_17](start_span)[span_17](end_span)

Module Roles & Rules:

- main.lua (The Director): Holds state (appState, userAnswers, sessionScore), handles key input (onKeyEvent), evaluates answers (evaluateSubmission), and coordinates timing.
- engine.lua (The Brain): Contains procedural rules, block-shuffling, interval constraints, and functional chromatic lookup tables.
- playback.lua (The Voice): Zero-dependency audio manager. Manages 32 voice channels, sample loading (piano_40-C2.ogg through 81-A5.ogg), legato overlaps, panic stops, and cadence execution.
- ui.lua (The Visuals): Renders dynamic answer boxes, feedback, status headers, and session score. Automatically scales UI boxes down by 10% when dictations exceed 4 notes.

1. Core Conventions & Music Theory Constraints

- Strict Lowercase: Solfège syllables must ALWAYS be rendered in lowercase (do, re, mi, fa, sol, la, ti).
- The "Sol" Rule: The 5th scale degree is strictly sol (3 letters).
- Semitone Mapping (Tonic = 0): do=0, ra=1, re=2, me=3, mi=4, fa=5, fi=6, sol=7, le=8, la=9, te=10, ti=11.
- Tonic MIDI Range: 52 (E3) to 64 (E4).
- Cadence Protocol: Key established via four-note I \to IV \to V \to I cadence with Soprano Anchor: do is in top voice (for now). Follows smooth voice leading rules, including IV V top three notes in different inversions to avoid parallel fifths.
- Cadence pulse = 800ms per chord. Final chord holds for 1.2s (1.5x).
- Mandatory "Breath" (1.6s / 2.0x silence) after cadence before question starts.
- Key Rotation: 50% chance to remain in the same key between exercises. If key repeats, melody unit must change.
- Melodic Constraints:
- Leap Limiter: Maximum interval of 12 semitones (1 octave) between consecutive notes.
- No Exact Duplicate MIDI Notes: Sequential repeat of exact same note triggers a re-roll.
- Diatonic Guard: All procedural adjustments in Phase 1 use modulo-12 checks against the strictly diatonic pool (0, 2, 4, 5, 7, 9, 11) to prevent accidental chromatics like le from spawning in Phase 1.

1. Key Algorithmic & UX Features Implemented
2. Procedural Block Generator & De-Clumping:

- Generates melodies from "blocks" (tendency pairs + random single notes).
- Shuffles blocks and runs a repetition guard to prevent duplicate block patterns (e.g., prevents fa-mi-fa-mi back-to-back).

1. Flat-Random Cumulative Selection:

- When on Level X.Y, the engine builds an unlocked pool of all sub-levels in that major group (X.1 \dots X.Y) and picks with flat probability.

1. 5-Strike Scoring Decay & Partial Credit:

- Each note slot starts with a max potential of 10 points.
- An incorrect submission decays the potential for that slot by 2 points (10 \to 8 \to 6 \to 4 \to 2 \to 0).
- Submitting a correct note awards its current decayed value.
- If any slot hits 0 points, a Forced Reveal triggers (shows correct answer: green for right, red for missed).

1. 9-Point "Near-Miss" Enharmonic System:

- Correct pitch + correct functional spelling = 10 pts.
- Correct pitch + incorrect enharmonic spelling (e.g., typing ra when preferred is di) = 9 pts + Yellow Correction.

1. Legato Audio Protocol:

- Audio notes overlap by 100ms with a smooth fade-out to emulate human piano playing.

1. Input & QoL Controls:

- ENTER / RETURN: Start / Submit.
- BACKSPACE / DELETE / DELETEBACK: Removes last note from answer buffer.
- C: Replay Cadence; Q: Replay Question; 0: Reset Session Score; ESC: Global Panic / Reset.
- Home row mappings: d=do, r=re, m=mi, f=fa, s=sol, l=la, t=ti. Modifiers (Shift = +1 semitone / sharp, Alt/Cmd = -1 semitone / flat).

1. Curriculum Overview (Syllabus)

- Phase 1: Diatonic Melodic Expansion (Complete & Tested)
- Level 1: Single-note ID for resolutions (d-s, t-d, f-m, r-d, l-s, m-r-d, l-t-d).
- Level 2: Single Diatonic Note ID (Unstable, Moderate, Stable).
- Level 3: 2-Note Diatonic Melodies (Tendencies, Anchors, 2-Note Random).
- Level 4: 3-Note Diatonic Melodies (4.1: Mix; 4.2: Root Triads; 4.3: Inverted Triads; 4.4: 3-Note Random Boss).
- Level 5: 4-Note Diatonic Melodies (5.1: 2 Pairs; 5.2: 1 Pair + 2 Random; 5.3: 4-Note Random Boss).
- Level 6: 5-Note Diatonic Melodies (6.1–6.3: Mixed rules; 6.4: 5-Note Random Boss with wide leaps).
- Phase 2: Chromatic Melodic Expansion (Planned Next Step)
- Level 7: Chromatic Tendencies ID (fi-s, le-s, me-r-d, te-d, ra-d).
- Levels 8–12: 1-note to 5-note dictations introducing up to 3 chromatics.
- Phases 3–5: Dyads & Harmonic Stacks (Future)
- Levels 13–14: Diatonic/Chromatic Dyads (2-note stacks).
- Levels 15–21: 3-Note and 4-Note Stacks (Triads, Clusters, 7th Chords).

1. Immediate Next Steps for the New Agent
2. Verify Phase 1 Polish: Ensure all Phase 1 levels (1.1 through 6.4) run smoothly with zero Lua errors or unintentional chromatics.
3. Begin Phase 2 Implementation:

- Build out Level 7 (Chromatic Tendencies single-input mode).
- Extend engine.lua rules to handle controlled chromatic insertion probabilities for Levels 8 through 12.

1. Enharmonic Spelling Engine Refinement: Expand context-aware spelling functions in engine.getPreferredName() to apply directional leading-tone principles (upward = sharp, downward = flat).