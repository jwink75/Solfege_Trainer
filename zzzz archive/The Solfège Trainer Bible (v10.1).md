# The Solfège Trainer Bible (v10.1)
Status: Deep Audit Completed - Production Environment
Last Updated: March 17, 2026

## I. Executive Summary & Vision
The Solfège Trainer is a gamified, high-performance ear training application designed to move students from simple diatonic pitches to complex chords. It focuses on functional tendencies—the magnetic pull of specific scale degrees toward resolution—rather than isolated interval recognition.

* Game Mode: Features an algorithmic, automatic level progression. Future implementation will include rewards for milestones met and leaderboards.
* Practice Mode: A customizable sandbox where users can specify their exact parameters:
* Delivery: Melodic (sequential) vs. Harmonic (simultaneous).
* Density: Number of notes played simultaneously.
* Content: Diatonic-only vs. Chromatic inclusion.

## II. Intended Platforms & Environment
* Platform: Solar2D 
* Target OS: iOS, Android, Windows, Mac, Web
* Environment: Solar2D (Corona), Zerobrane
* Language: Lua.
* Developer Support Context: Developer is fluent in Lua (RGP Lua for Finale) but requires thorough, step-by-step guidance for deployment, stack setup, and platform-specific architecture.

## III. Core Conventions & Math
* Solfège Formatting: STRICT LOWERCASE must be used for all solfège notation (do, di, ra, re...).
* Spreadsheet / Data Cleanliness: Never use "N/A" in data tables or spreadsheets. Always use blank cells.
* Semitone Mapping (Tonic = 0): do=0, di/ra=1, re=2, ri/me=3, mi=4, fa=5, fi/se=6, sol=7, si/le=8, la=9, li/te=10, ti=11
* (Note: Tendencies that resolve upward to the tonic use negative integers, e.g., ti to do is mapped as -1, 0).
* Key Rotation (The 30% Rule): The tonic changes approximately 30% of the time (or every 3-5 items) to prevent absolute pitch reliance.
* Tonic Range: The MIDI tonic must remain between 52 (E2) and 64 (E3).
* UI Nomenclature: The user interface relies on a flat-dominant naming convention for readability (C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B).
* The Global Octave Ban: The app must NEVER play the same solfège note in different octaves simultaneously (due to poor translation on mobile/small speakers). This is an absolute constraint across all levels.

## IV. Harmonic Foundation: The Cadence Engine
The cadence is the pedagogical "anchor." It establishes the key and the functional "pull" of the tendencies. A new key is always established by playing a I-IV-V-I Cadence.

1. Voice Leading Logic (Smooth Transitions)
The cadence must follow strict choral voice-leading principles to avoid jarring jumps that distract the ear.
The Soprano Anchor (Levels 1-6): For the first six levels (all diatonic melodies), the cadence must be voiced with do in the soprano (top voice) to strongly anchor the student's ear. From Level 7 onwards, this constraint is lifted, allowing for variable voicings (e.g., mi or sol in the soprano) to increase difficulty.
* Tonic (do) Stability: The do (e.g., MIDI 72 in the top voice for C) must be maintained as a common tone during the I-IV transition (Levels 1-6).
* Stepwise Resolution: Inner voices move by the smallest possible intervals (major/minor seconds or thirds).
* Bass Foundation: The bass voice must play the literal root of each chord (do - fa - sol - do) exactly one octave below the tonic reference.
	* Standardized Voicing (Example in C for Levels 1-6):
		* Chord 1 (I): {48, 64, 67, 72} (do {2}, mi 3}, sol {3}, do {4})
		* Chord 2 (IV): {53, 65, 69, 72} (fa {2}, fa {3}, la {3}, do {4})
		* Chord 3 (V): {55, 62, 67, 71} (sol {2}, re {3}, sol {3}, ti {3})
		* Chord 4 (I): {48, 64, 67, 72} (do {2}, mi {3}, sol_ 3}, do {4})
2. The Unified Timing Protocol
All audio playback math is derived from a single global variable to prevent timing drift and allow easy global adjustment.
Base Duration: baseDuration = 800 (milliseconds).
Cadence Pulse: I (1.0x)  to IV (1.0x) to V (1.0x) to I (2.0x).
* The Breath (Silence): A mandatory 2.0x duration (1600ms) of silence must follow the final I chord before the exercise question begins.

## V. Audio Execution & Playback Mechanics
1. The Legato (Voice-Off) Protocol
* Active Voice Management: All active voices must be tracked in a table (activeVids). Maximum of 32 voices.
* The Kill Command: Before any new note or chord triggers, playback.voice.off must be called for every ID in activeVids.
* Stack/Dyad Integrity: For simultaneous notes, the "Kill Command" must execute before the stack triggers so the notes sustain together without interference from previous sounds.
2. Durations and Resonance Multipliers
* Exercise timings are strictly calculated as multipliers of the baseDuration.
* Standard Melody Notes: 1.0x (800ms).
* Final Melody Notes: 2.0x (1600ms) to provide a natural musical decay.
* Fast Tendencies: 0.5x (400ms) - EXCLUSIVE to 3-note tendencies in early levels (e.g., m-r-d, l-t-d).
* Single Notes & Stacks (Harmonic): 4.0x (3200ms) to allow the student to "lock in" their singing voice to the pitch.

## VI. UX, Input & Evaluation Logic
* Administrative Keybinds: SPACE (New Exercise), c (Replay Cadence), q (Replay Question). These are strictly isolated from the QWERTY evaluation inputs.
* Quiz Input Standard: "Home Row" mapping (d, r, m, f, s, l, t) for ergonomic musical responses. Input keys are silent (no audio playback upon pressing).
	* Later in development phase: Shift and Opt/Alt will be used as modifier keys for sharps and flats. Example: ra = Opt+r, ri = Shift+r
* Early Answering: The user keyboard is unlocked the exact moment the question begins playing, allowing immediate evaluation.
* Modulo Evaluation: To ensure answers are octave-agnostic, user input evaluation must use modulo 12 (userNote % 12 == targetNote % 12).
* Tendency Target: In early levels, pressing the key corresponding to the first note of a multi-note tendency registers as a correct answer.

## VII. The Global Builder Guardrails
* Anti-Repetition Rule: No identical pitch classes back-to-back. If a unit ends on mi and the next starts on mi, the second note must shift +2 semitones.
* Double-Chromatic Ban: Consecutive half-steps (e.g., f-fi-s played as a cluster or sequential run) are strictly forbidden in generation logic.
* Target Note Math: Composite melodic levels use a trial-and-success loop to shuffle units until total notes strictly equal the required target.
* Anti-Repetition Memory: The engine stores the lastTonic and lastNotesString to ensure the exact same question is never asked twice in a row, unless the key has also rotated.
* The Cumulative Sublevel Rule: Sublevels must always incorporate the pedagogical dictionaries of their preceding sublevels to ensure continuous spaced repetition (e.g., Level 1.3 pulls randomly from the 1.1, 1.2, and 1.3 dictionaries).

## VIII. Level Architecture & Algorithmic Progression
### Phase 1: Diatonic Melodic Expansion
* Level 1: Diatonic Tendencies
	* Level 1.1: do-sol, ti-do, fa-mi
	* Level 1.2: re-do, la-sol
	* Level 1.3: mi-re-do, la-ti-do
* Level 2: Single Diatonic Notes
	* Level 2.1: Unstable notes (hearing the tendency pull): t, f.
	* Level 2.2: Moderately stable: r, l.
	* Level 2.3: Stable notes: d, m, s.
* Level 3: 2-Note Diatonic Melodies
	* Constraint: Never greater than 1 octave apart.
	* Level 3.1: Tendency pairs (2-note tendencies)
	* Level 3.2: Any diatonic note + stable anchor (d, s, or m)
	* Level 3.3: Any two diatonic notes
* Level 4: 3-Note Diatonic Melodies
	* Level 4.1: Tendency pair + random single OR single + tendency pair.
	* Level 4.2: 3-note tendencies (l-t-d, m-r-d).
	* Level 4.3: Diatonic triads (I, ii, iii, IV, V, vi, vii) in any inversion.
	* Level 4.4: 3 random diatonic notes.
* Level 5: 4-Note Diatonic Melodies
	* Level 5.1: Two sequential tendency pairs.
	* Level 5.2 One tendency pair + 2 random notes (any permutation of sequence).
	* Level 5.3: One 3-note tendency/triad + 1 random note (any permutation).
	* Level 5.4: Four random diatonic notes.
* Level 6: 5-Note Diatonic Melodies
	* Level 6.1: Two tendency pairs + 1 random diatonic (any permutation).
	* Level 6.2: One 2-note tendency + 3-note tendency/triad (any permutation).
	* Level 6.3: 3-note tendency/triad + 2 random diatonic notes.

### Phase 2: Chromatic Melodic Expansion
* Level 7: Chromatic Tendencies
	* Introduced iteratively (one at a time, cumulatively tested against previous diatonic tendencies).
	* Dictionary: fi-s, le-s, me-r-d, te-d, ra-d.
* Level 8: Single Chromatic Notes
	* Mixed dynamically with single diatonic notes.
* Level 9: 2-Note Melodies (Diatonic + Chromatic)
	* Constraint: At least one note must ALWAYS be diatonic.
* Level 10: 3-Note Melodies (1 Chromatic Max)
	* Level 10.1: Tendency pair + single note (chromatic note can be inside the tendency or the single note). Examples: fi-s + r, m + le-s, r-d + le.
	* Level 10.2: 3-note chromatic tendencies (me-r-d).
* Level 11: 4-Note Melodies (Up to 2 Chromatics)
	* Level 11.1: Two tendency pairs (one diatonic, one chromatic/diatonic).
	* Level 11.2: One tendency pair + 2 random notes OR 3-note tendency + random note.
	* Level 11.3: 4 random notes (1 chromatic max).
	* Level 11.4: 4 random notes (2 chromatics, non-adjacent).
	* Level 11.5: 4 random notes (2 chromatics, adjacent permitted).
* Level 12: 5-Note Melodies (Up to 3 Chromatics)
* Logic: Permutations of two-tendencies + randoms, 2-note + 3-note blocks, or 1 tendency + 3 randoms (capped at 2 or 3 total chromatics respectively).

### Phase 3: Dyads (2-Note Stacks)
* All stacks are named algorithmically from bottom up, answered via solfège input. No octaves.
* Level 13: Diatonic Dyads
	* (continue level numbering scheme...)
	* Tritones: t-f (inward resolution implied), f-t (outward resolution implied).
	* Thirds / Sixths (Consonant).
	* Perfect Fifths (d-s anchor) / Perfect Fourths.
	* Seconds / Sevenths (Clusters / wide dissonance).
* Level 14: Chromatic Dyads (1 Chromatic Max)
	* Thirds: r-fi, me-s, f-le.
	* Sixths: d-le, fi-r, te-s.
	* Fourths: f-te, me-l.
	* Seconds: r-me, fi-s.
	* Sevenths: d-te, f-me.

### Phase 4: 3-Note Stacks
* Stack Constraints: Max Outer Interval = Major 10th (16 semitones). Max Inner Interval = Major 7th (11 semitones).
* Level 15: Diatonic 3-Note Stacks
	* Diatonic triads (any inversion).
	* Wider interval stacks: r-f-d, t-m-l.
	* Cluster + Wider Interval: t-d-s, s-l-d, f-s-r.
	* 3-note Clusters: d-r-m, m-f-s.
* Level 16: See phase 5...
* Level 17: 3-Note Stacks (1 Chromatic)
	* Major/Minor triads with diatonic roots: r-fi-l, f-le-d, te-r-f (bVII).
	* Augmented/Diminished triads with diatonic roots: d-m-si, r-f-le.
	* Triads using 1 chromatic (root acceptable): fi-l-d.
	* Wider intervals: r-fi-d, te-m-l.
	* Cluster + Wider: te-d-s, s-le-d, s-di-r, d-m-fi.
	* 3-Note Clusters: Must avoid "double chromatics" (r-m-fi is OK; f-fi-s is NOT OK).
* Level 18: 3-Note Stacks (Up to 2 Chromatics)
	* Major/Minor triads with chromatic roots: ra-f-le (bII), me-s-te (bIII), le-d-me (bVI).
	* Augmented/Diminished with diatonic roots requiring 2 chromatics: r-fi-li, d-me-se.
	* Wider intervals: d-me-te.
	* Cluster + Wider (1 note of cluster MUST remain diatonic): te-d-le, r-me-le.

### Phase 5: 4-Note Stacks
* Stack Constraints: Max Outer Interval = Perfect 12th (19 semitones). Max Inner Interval = Major 7th (11 semitones).
* Level 16: Diatonic 4-Note Stacks
	* Diatonic 7th chords (root position).
	* Triad + wider interval: d-m-s-r, d-s-t-r.
	* Triad + cluster on top (incl. 1st inv 7ths): m-s-d-r, d-f-l-t.
	* Triad + cluster on bottom (incl. 3rd inv 7ths): r-m-s-d.
	* Random + 1 cluster (top/bottom/middle).
	* Random + 2 non-adjacent clusters: r-m-s-l.
* Level 19: 4-Note Stacks (1 Chromatic)
	* Maj7, min7, half-dim7 with diatonic/chromatic roots (avoid interior clusters in early testing).
	* Triad + wider 'random' note: r-fi-l-m.
	* Random 4 notes with 2 clusters (top & bottom, wider center): r-m-si-l, te-d-f-s.
	* Random 4 notes with 2 consecutive clusters (No double chromatics): d-r-m-si, te-f-s-l.
* Level 20: 4-Note Stacks (Up to 2 Chromatics)
	* 7th chords with diatonic/chromatic roots: me-s-te-r, te-r-f-le, ri-fi-l-d.
* Level 21: 4-Note Stacks (Up to 3 Chromatics)
	* Algorithmic expansion following established cluster and interval boundary limits.

### Phase 6: 5-Note Stacks
* Algorithmic expansion based on development of 4-note stacks. Start with all diatonic, increase number of clusters and chromatics gradually over sublevels.

## IX. Code Implementation & Standardized Architecture
* `main.lua`: The Solar2D orchestrator. Handles UI (flat nomenclature), cadence timing, "The Breath", key rotation logic, and global keyboard listeners (spacebar, numerical input).
* `engine.lua`: Handles the generation of melodies/stacks (generateMelody, generateStack), note-count math, anti-repetition guards, user input mapping (d, r, m, f, s, l, t), and visual Green/Red feedback.
* `definitions.lua`: The syllabus. Houses the raw semitone arrays, rhythms, and keys for the diatonic and chromatic tendency dictionaries.
* `playback.lua`: The Dynamic Voice Allocation Engine. Handles .ogg soundbank loading, polyphony management, the Legato/Voice-Off protocol, and timer panics.
	* The voice allocation engine MUST be named playback.lua. The filename audio.lua is strictly forbidden due to namespace collisions with Solar2D's native audio library.
* `progression.lua`: Defines the level "recipes" (diatonic\_tendency, chromatic\_tendency), target counts, and tracks progression.
* File paths and asset loaders must strictly use Sharp ('s') notation; UI elements must strictly use Flat ('b') notation.
* Since 'do' is a reserved keyword in Lua, it cannot be used as a variable name for 'do' the solfege note.
* Maintain an iterative version number in the header for each lua file.

## X. Next Steps (Session Start Point) (New Section)
* Level 2 Implementation: Expand definitions.lua and progression.lua to fully map the sub-tiers of Level 2 (Single Diatonic Notes).
* Algorithm Adjustments: Ensure engine.lua handles Level 2 correctly by generating single notes categorized into Unstable (t, f), Moderately Stable (r, l), and Stable (d, m, s) tiers.
* Evaluation Tuning: Verify that the QWERTY quiz loop in main.lua correctly handles these single-note inputs compared to the tendency evaluations of Level 1.


