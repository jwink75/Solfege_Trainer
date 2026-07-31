I hear you loud and clear, and I sincerely apologize. I failed to maintain the full detail of the level hierarchy, which was a direct violation of your "do not remove" constraint. By summarizing those sections, I **eliminated** the specific pedagogical data you spent time refining.

I understand the word **remove** perfectly: to take away or eliminate. In the previous version, I took away the specific sub-bullet details for Levels 5 through 21. That was a mistake, and I am restoring them in full now.

Regarding my ability to follow these corrections: Gemini will occasionally get things wrong, but I am always learning. I encourage you to continue correcting me directly in the conversation whenever my logic or output drifts from your specific constraints, as you just did.

Here is the **Project Bible: Version 12.1**. It restores every single detail from the v10.1/11.1 source and integrates the new Enharmonic and UI logic.

---

# # The Solfège Trainer Bible (v12.1)
**Status:** Phase 1 Stable / Theory Expansion  
**Last Updated:** March 24, 2026

> **Note on Documentation:** This Bible is a living technical specification and must always be rendered and provided using **Markdown** to ensure cross-platform readability and structural integrity.

---

## I. Executive Summary & Vision
The Solfège Trainer is a gamified, high-performance ear training application designed to move students from simple diatonic pitches to complex chords. It focuses on functional tendencies—the magnetic pull of specific scale degrees toward resolution—rather than isolated interval recognition.

* **Game Mode:** Features an algorithmic, automatic level progression. Includes the "Level Browser" for manual navigation during the menu state.
* **Practice Mode:** A customizable sandbox where users can specify parameters: Melodic vs. Harmonic, Density, and Content.
* **The Vibe:** A professional, responsive tool with musical "ring-outs" and a logic-driven RNG that prevents repetitive frustration.

---

## II. Intended Platforms & Environment
* **Platform:** Solar2D  
* **Target OS:** iOS, Android, Windows, Mac, Web
* **Environment:** Solar2D (Corona), Zerobrane
* **Language:** Lua.
* **Architecture:** Modular separation between **Engine** (generation), **Definitions** (data), and **Playback** (audio).

---

## III. Core Conventions & Math
* **Solfège Formatting:** STRICT LOWERCASE (do, di, ra, re...).
* **Data Cleanliness:** Never use "N/A" in tables; use blank cells.
* **Semitone Mapping (Tonic = 0):** do=0, di/ra=1, re=2, ri/me=3, mi=4, fa=5, fi/se=6, sol=7, si/le=8, la=9, li/te=10, ti=11.
* **Resolution Direction:** Tendencies must resolve in their intended direction. Specifically, **ti** must always resolve **upward** to **do** (mapped as 11 → 12 or -1 → 0).
* **Key Rotation (The 50% Rule):** The app has a 50% chance to stay in the same key.
    * **Enforced Variety:** If staying in the same key, the engine is **forbidden** from picking the same melody unit twice in a row.
* **Tonic Range:** The MIDI tonic must remain between **52 (E3)** and **64 (E4)**.
* **UI Nomenclature:** Flat-dominant naming (C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B).
* **The Global Octave Ban:** The app must NEVER play the same solfège note in different octaves simultaneously.

---

## IV. Harmonic Foundation: The Cadence Engine
The cadence is the pedagogical "anchor." A new key is always established by a I-IV-V-I Cadence.

1.  **Voice Leading Logic**
    * **The Soprano Anchor (Levels 1-6):** Cadence voiced with **do** in the soprano. Tonic (do) is maintained as a common tone during I-IV.
    * **Bass Foundation:** Literal root (do - fa - sol - do) exactly one octave below the tonic reference.
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
    * **The Panic Protocol (Esc):** Calls `globalPanic()`, which cancels all registered timers and stops all audio channels immediately.
    * **Safety Check:** Every `audio.stop` call must verify `audio.isChannelActive(id)` to prevent console errors.
2.  **Durations and Resonance Multipliers**
    * **Standard Melody Notes:** 1.0x (800ms).
    * **Final Question Note:** **1.5x (1200ms)** for a natural musical decay.
    * **Auto-Advance Delay:** Correct answers trigger a **1600ms** (2-pulse) delay.
    * **Fast Tendencies:** 0.5x (400ms) for specific 3-note units (e.g., m-r-d).
    * **Harmonic Stacks:** 4.0x (3200ms) to allow for "vocal locking."

---

## VI. UX, Input & Evaluation Logic
* **Administrative Keybinds:** **ENTER** (Start/Submit), **c** (Replay Cadence), **q** (Replay Question), **ARROW KEYS** (Level Navigation).
* **The "Total Panic" Key:** **ESCAPE** resets all state and returns to Menu.
* **Input State Machine:**
    * **Identification Mode (Levels 1, 2, 7):** Single-input. Correct key reveals the answer instantly.
    * **Transcription Mode (Levels 3+):** Sequential entry with placeholders (`__ __`). Requires **ENTER** to submit.
* **Evaluation:** Octave-agnostic modulo 12 (`userNote % 12 == targetNote % 12`).
* **Early Answering:** Keyboard unlocks the moment the question begins.

---

## VII. The Global Builder Guardrails
* **Anti-Repetition Rule:** No identical pitch classes back-to-back within a sequence.
* **Double-Chromatic Ban:** Consecutive half-steps (e.g., f-fi-s) are strictly forbidden.
* **Composite Pool Lookup:** Engine searches `definitions.lua` root first, then sub-tables (`tendencies`, `single_diatonic`).
* **Variety Lock:** If a tonic is repeated, the melody unit MUST change.

---

## VIII. Level Architecture & Algorithmic Progression

### Phase 1: Diatonic Melodic Expansion
* **Level 1: Diatonic Tendencies (ID Mode)**
    * 1.1: Anchor resolutions (d-s, t-d, f-m).
    * 1.2: Outer step resolutions (r-d, l-s).
    * 1.3: 3-note pathways (m-r-d, la-ti-do).
* **Level 2: Single Diatonic Notes (ID Mode)**
    * 2.1: Unstable notes (hearing the tendency pull): t, f.
    * 2.2: Moderately stable: r, l.
    * 2.3: Stable notes: d, m, s.
* **Level 3: 2-Note Diatonic Melodies (Transcription Mode)**
    * *Constraint: Never greater than 1 octave apart.*
    * 3.1: Tendency pairs (2-note resolutions).
    * 3.2: Any diatonic note + stable anchor (d, s, or m) in any order.
    * 3.3: Any two diatonic notes.
* **Level 4: 3-Note Diatonic Melodies**
    * 4.1: Tendency pair + random single OR single + tendency pair.
    * 4.2: 3-note tendencies (l-t-d, m-r-d).
    * 4.3: Diatonic triads (I, ii, iii, IV, V, vi, vii) in any inversion.
    * 4.4: 3 random diatonic notes.
* **Level 5: 4-Note Diatonic Melodies**
    * 5.1: Two sequential tendency pairs.
    * 5.2: One tendency pair + 2 random notes (any permutation of sequence).
    * 5.3: One 3-note tendency/triad + 1 random note (any permutation).
    * 5.4: Four random diatonic notes.
* **Level 6: 5-Note Diatonic Melodies**
    * 6.1: Two tendency pairs + 1 random diatonic (any permutation).
    * 6.2: One 2-note tendency + 3-note tendency/triad (any permutation).
    * 6.3: 3-note tendency/triad + 2 random diatonic notes.

### Phase 2: Chromatic Melodic Expansion
* **Level 7: Chromatic Tendencies (ID Mode)**
    * Introduced iteratively, cumulatively tested against diatonic tendencies.
    * Dictionary: fi-s, le-s, me-r-d, te-d, ra-d.
* **Level 8: Single Chromatic Notes**
    * Mixed dynamically with single diatonic notes.
* **Level 9: 2-Note Melodies (Diatonic + Chromatic)**
    * Constraint: At least one note must ALWAYS be diatonic.
* **Level 10: 3-Note Melodies (1 Chromatic Max)**
    * 10.1: Tendency pair + single note (chromatic note can be inside the tendency or the single note). Examples: fi-s + r, m + le-s, r-d + le.
    * 10.2: 3-note chromatic tendencies (me-r-d).
* **Level 11: 4-Note Melodies (Up to 2 Chromatics)**
    * 11.1: Two tendency pairs (one diatonic, one chromatic/diatonic).
    * 11.2: One tendency pair + 2 random notes OR 3-note tendency + random note.
    * 11.3: 4 random notes (1 chromatic max).
    * 11.4: 4 random notes (2 chromatics, non-adjacent).
    * 11.5: 4 random notes (2 chromatics, adjacent permitted).
* **Level 12: 5-Note Melodies (Up to 3 Chromatics)**
    * Logic: Permutations of two-tendencies + randoms, 2-note + 3-note blocks, or 1 tendency + 3 randoms (capped at 2 or 3 total chromatics respectively).

### Phase 3: Dyads (2-Note Stacks)
* **Level 13: Diatonic Dyads**
    * Tritones: t-f (inward resolution implied), f-t (outward resolution implied).
    * Thirds / Sixths (Consonant).
    * Perfect Fifths (d-s anchor) / Perfect Fourths.
    * Seconds / Sevenths (Clusters / wide dissonance).
* **Level 14: Chromatic Dyads (1 Chromatic Max)**
    * Thirds: r-fi, me-s, f-le.
    * Sixths: d-le, fi-r, te-s.
    * Fourths: f-te, me-l.
    * Seconds: r-me, fi-s.
    * Sevenths: d-te, f-me.

### Phase 4: 3-Note Stacks
* **Constraint:** Max Outer Interval = Major 10th (16 semitones). Max Inner Interval = Major 7th (11 semitones).
* **Level 15: Diatonic 3-Note Stacks**
    * Diatonic triads (any inversion).
    * Wider interval stacks: r-f-d, t-m-l.
    * Cluster + Wider Interval: t-d-s, s-l-d, f-s-r.
    * 3-note Clusters: d-r-m, m-f-s.
* **Level 17: 3-Note Stacks (1 Chromatic)**
    * Major/Minor triads with diatonic roots: r-fi-l, f-le-d, te-r-f (bVII).
    * Augmented/Diminished triads with diatonic roots: d-m-si, r-f-le.
    * Triads using 1 chromatic (root acceptable): fi-l-d.
    * Wider intervals: r-fi-d, te-m-l.
    * Cluster + Wider: te-d-s, s-le-d, s-di-r, d-m-fi.
    * 3-Note Clusters: Must avoid "double chromatics" (r-m-fi is OK; f-fi-s is NOT OK).
* **Level 18: 3-Note Stacks (Up to 2 Chromatics)**
    * Major/Minor with chromatic roots: ra-f-le (bII), me-s-te (bIII), le-d-me (bVI).
    * Augmented/Diminished with diatonic roots requiring 2 chromatics: r-fi-li, d-me-se.
    * Wider intervals: d-me-te.
    * Cluster + Wider (1 note of cluster MUST remain diatonic): te-d-le, r-me-le.

### Phase 5: 4-Note Stacks
* **Constraint:** Max Outer Interval = Perfect 12th (19 semitones). Max Inner Interval = Major 7th (11 semitones).
* **Level 16: Diatonic 4-Note Stacks**
    * Diatonic 7th chords (root position).
    * Triad + wider interval: d-m-s-r, d-s-t-r.
    * Triad + cluster on top (incl. 1st inv 7ths): m-s-d-r, d-f-l-t.
    * Triad + cluster on bottom (incl. 3rd inv 7ths): r-m-s-d.
    * Random + 1 cluster (top/bottom/middle).
    * Random + 2 non-adjacent clusters: r-m-s-l.
* **Level 19: 4-Note Stacks (1 Chromatic)**
    * Maj7, min7, half-dim7 with diatonic/chromatic roots.
    * Triad + wider 'random' note: r-fi-l-m.
    * Random 4 notes with 2 clusters (top & bottom, wider center): r-m-si-l, te-d-f-s.
    * Random 4 notes with 2 consecutive clusters (No double chromatics): d-r-m-si, te-f-s-l.
* **Level 20: 4-Note Stacks (Up to 2 Chromatics)**
    * 7th chords with diatonic/chromatic roots: me-s-te-r, te-r-f-le, ri-fi-l-d.
* **Level 21: 4-Note Stacks (Up to 3 Chromatics)**
    * Algorithmic expansion following established cluster and interval boundary limits.

---

## IX. Enharmonic Spelling & Functional Notation

### 1. The Functional Priority Stack
In an environment without external musical context, the application must assign a **Preferred Spelling** to chromatic pitches based on the following hierarchy. If a higher rule applies, it overrides those below it.

1.  **The Tertiary Principle (Chords/Stacks):** If a group of notes forms a recognizable triad or 7th chord (regardless of inversion), the spelling must preserve the interval of a **third**. 
    * `[1, 4, 7]` → **di-mi-sol** (Diminished triad; preserves the minor 3rd $di \to mi$).
    * `[0, 4, 8]` → **do-mi-si** (Augmented triad; preserves the major 3rd $mi \to si$).
    * `[0, 5, 8]` → **do-fa-le** (Minor triad, 2nd inversion; preserves the minor 3rd $fa \to le$).
    * `[0, 4, 5, 8]` → **do-mi-fa-le** (Minor-Major 7th, 2nd inversion).

2.  **The Chromatic Variety Principle (Clusters):** Avoid using two versions of the same scale degree name in immediate succession.
    * *Example:* Favor **re - me** over **re - ri**.
    * *Example:* Favor **si - la** over **le - la**.

3.  **The Leading Tone Principle (Melodic Direction):** In sequential melodies, chromatic notes act as "tendency notes" defined by their resolution.
    * **Upward Resolution:** Use a sharp (**di, ri, fi, si, li**).
    * **Downward Resolution:** Use a flat (**ra, me, se, le, te**).

4.  **The Arbitrary Default:** In the absence of context, the system defaults to the **Standard Five**: **ra, me, fi, le, te**.

### 2. UI, Scoring, and Correction Protocol
* **Point Valuation:**
    * **Perfect (10 pts):** Correct semitone + Correct functional spelling.
    * **Near-Miss (9 pts):** Correct semitone + Incorrect enharmonic spelling. Corrected to **Yellow** text upon submission.
    * **Incorrect (0 pts):** Wrong semitone.
* **UI Persistence:** Submitted answers remain visible until the cadence for the next exercise begins. Feedback text is moved to peripheral screen locations (top/bottom).

---

## X. Code Implementation & Standardized Architecture
* **main.lua (v13.5):** Orchestrator. Manages `mainTimers`, UI feedback, and dual-mode input.
* **engine.lua (v11.0):** Algorithmic generator. Features root-level unit lookup and safe-type wrapping.
* **definitions.lua (v10.1):** The syllabus. Houses semitone arrays and resolution directions.
* **playback.lua (v11.5):** Audio engine. Implements Legato Protocol and **Safe-Stop** logic.
* **ui.lua (v2.0):** Visual layer. Renders slate-grey background and dynamic input slots.

---

## XI. Current Stopping Point & Next Steps
* **Phase 1 Status:** Levels 1-6 melodic dictation functionally complete and tested.
* **Theory Framework:** **Functional Priority Stack** (Enharmonic Spelling) logic defined.
* **Next Session:**
    1.  Implementation of **Level 4 (Diatonic Chains)**.
    2.  Development of the **Harmonic Dyad (Level 13)** engine.
    3.  **Enharmonic Logic Integration:** Implement the `engine.determinePreferredSpelling` helper and the "Yellow Correction" UI system.

