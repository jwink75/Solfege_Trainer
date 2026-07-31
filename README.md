# 🎵 Solfège Trainer (v12.4)

> A gamified, high-performance ear training application built in **Solar2D (Lua)** that trains the ear to hear **functional tonal tendencies** rather than raw interval distances.

---

## 🌟 Pedagogical Philosophy

Most ear training apps focus on **interval recognition** (e.g., identifying a "Major 3rd" or "Perfect 5th"). However, human musical perception is inherently **functional**: we hear scale degrees in relation to a tonal center and feel their magnetic attraction toward resolution.

The **Solfège Trainer** trains students to instantly identify pitches by their functional role within a key center:
- **`ti` (7)** has a strong magnetic pull resolving **upward** to **`do` (1/Tonic)**.
- **`fa` (4)** pulls **downward** to **`mi` (3)**.
- **`re` (2)** pulls **downward** to **`do` (1)** or resolves through **`m-r-d`**.
- **`fi` (#4)** resolves **upward** to **`sol` (5)**.
- **`le` (b6)** resolves **downward** to **`sol` (5)**.
- **`ra` (b2)** resolves **downward** to **`do` (1)**.

---

## 🏗️ Architecture & Module Roles

The codebase adheres strictly to a **Master/Worker Separation** to avoid circular dependency crashes:

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

| Module | Role & Responsibility |
| :--- | :--- |
| **`main.lua`** | **The Director**: Manages app state machine (`menu`, `quiz`, `result`), orchestrates timing, handles keyboard/input events, evaluates user submissions, and tracks session scores. |
| **`engine.lua`** | **The Brain**: Generates procedural melodies, enforces leap limiters ($\le 12$ semitones), guards against duplicate consecutive notes, clamps pitch bounds ($45 \le \text{MIDI} \le 80$), and computes directional enharmonic spelling. |
| **`playback.lua`** | **The Voice**: Zero-dependency audio manager. Manages 32 voice channels, loads high-quality piano samples (`piano_40-C2.ogg` to `81-A5.ogg`), executes the legato protocol (100ms fade overlap), and plays I-IV-V-I cadences. |
| **`ui.lua`** | **The Visuals**: Renders auto-scaling visual boxes (shrinks 10% for 5+ note dictations), dynamic feedback headers, decayed score displays, and yellow enharmonic correction highlights. |
| **`progression.lua`**| **The Syllabus**: Defines level curriculum, unit definitions, and rule parameters for Phase 1 through Phase 5. |
| **`definitions.lua`**| **Legacy Reference**: Holds semitone mapping arrays and resolution target references. |

---

## 🎹 Music Theory Rules & Enharmonic Engine

1. **Strict Lowercase Formatting**: Solfège syllables are strictly lowercase (`do`, `ra`, `re`, `me`, `mi`, `fa`, `fi`, `sol`, `le`, `la`, `te`, `ti`). The 5th scale degree is strictly `sol` (3 letters).
2. **Semitone Mapping (Tonic = 0)**:
   - `do`=0, `ra`=1, `re`=2, `me`=3, `mi`=4, `fa`=5, `fi`=6, `sol`=7, `le`=8, `la`=9, `te`=10, `ti`=11.
3. **Key Center & Cadence Protocol**:
   - Every key change plays a 4-chord **I-IV-V-I Cadence** with a Soprano Anchor (`do4` = MIDI 72).
   - Pulse: 800ms per chord, 1.2s hold on final chord, followed by a mandatory **1.6s "Breath"** silence before the question plays.
4. **Directional Enharmonic Spelling Engine**:
   Enharmonic spelling for chromatic notes is determined dynamically based on leading-tone direction:
   - **`1` (b2 / #1)**: `ra` by default (e.g. `fa ra ti do`); `di` ONLY for ascending stepwise $0 \to 1 \to 2$ (`do di re`).
   - **`3` (b3 / #2)**: `me` by default (e.g. `me le` for P4); `ri` ONLY for ascending stepwise $2 \to 3 \to 4$ (`re ri mi`).
   - **`6` (#4 / b5)**: `fi` when resolving up to `sol` (7); `se` when resolving down to `fa` (5).
   - **`8` (b6 / #5)**: `le` when resolving down to `sol` (7); `si` when resolving up to `la` (9).
   - **`10` (b7 / #6)**: `te` by default (e.g. `te do`); `li` ONLY for ascending stepwise $9 \to 10 \to 11$ (`la li ti`).

---

## 🎮 Gamification & Evaluation Logic

- **5-Strike Decayed Potential**: Each note slot begins with a maximum potential of **10 points**. Every incorrect submission decays the potential for that slot by 2 points ($10 \to 8 \to 6 \to 4 \to 2 \to 0$).
- **Partial Credit**: Users earn the current decayed value for any note they get right, even if they miss other notes in the sequence.
- **Near-Miss System (9 Points)**: Submitting the correct pitch with an incorrect enharmonic spelling (e.g., typing `ra` when preferred is `di`) awards 9 points and displays a **Yellow Correction** box.
- **Forced Reveal**: If any slot hits 0 potential, the correct answer is revealed automatically (Green = Correct, Red = Missed).
- **Weighted Spiral Learning**: In Level $X.Y$, exercises are drawn from all unlocked levels in group $X$, with a **40% weight boost** given to the current newest unlocked level ($X.Y$) to reinforce new concepts.

---

## 📚 Curriculum Syllabus

### Phase 1: Diatonic Melodic Expansion (Levels 1–6)
- **Level 1**: Diatonic Tendencies ID Mode (1.1: `d-s`, `t-d`, `f-m`; 1.2: `r-d`, `l-s`; 1.3: 3-note resolutions `m-r-d`, `l-t-d`).
- **Level 2**: Single Diatonic Note ID Mode (2.1: Unstable `t`, `f`; 2.2: Moderate `r`, `l`; 2.3: Stable `d`, `m`, `s`).
- **Level 3**: 2-Note Diatonic Melodies (3.1: Tendency pairs; 3.2: Anchor melodies; 3.3: 2-note random).
- **Level 4**: 3-Note Diatonic Melodies (4.1: Tendency/random mix; 4.2: Root position triads; 4.3: Inverted triads; 4.4: 3-note Boss).
- **Level 5**: 4-Note Diatonic Melodies (5.1: 2 pairs; 5.2: 1 pair + 2 random; 5.3: 4-note Boss).
- **Level 6**: 5-Note Diatonic Melodies (6.1–6.3: Mixed rules; 6.4: 5-note Boss).

### Phase 2: Chromatic Melodic Expansion (Levels 7–12)
- **Level 7**: Chromatic Tendencies ID Mode (7.1: `fi-s`, `le-s`, `ra-d`, `te-d`; 7.2: 3-note pathway `me-r-d`).
- **Level 8**: Single Chromatic Note ID Mode (8.1: `ra`, `me`, `fi`; 8.2: `le`, `te`; 8.3: All chromatics).
- **Levels 9–12**: 2-note to 5-note dictations featuring controlled chromatic insertion rules.

### Phase 3–5: Dyads & Harmonic Stacks (Future Roadmap)
- **Levels 13–14**: Diatonic & Chromatic Dyads (2-note stacks).
- **Levels 15–18**: 3-Note Stacks (Triads/Clusters, max interval Maj 10th).
- **Levels 19–21**: 4-Note Stacks (7th Chords, max interval Perf 12th).

---

## ⌨️ Controls & Input Mapping

| Action | Primary Key | Secondary Key |
| :--- | :---: | :---: |
| **Replay Cadence** | `C` | `K` |
| **Replay Question** | `Q` | — |
| **Delete Last Note** | `BACKSPACE` | `DELETE` |
| **Reset Session Score** | `0` | — |
| **Panic / Menu Return** | `ESC` | — |
| **Change Level** | `Up` / `Right` | `Down` / `Left` |
| **Submit Answer** | `ENTER` / `RETURN` | — |

### Solfège Keyboard Mapping (Home Row)
- **`d`** = `do` (Shift = `di`, Alt/Cmd = `ti`)
- **`r`** = `re` (Shift = `ri`, Alt/Cmd = `ra`)
- **`m`** = `mi` (Shift = `fa`, Alt/Cmd = `me`)
- **`f`** = `fa` (Shift = `fi`, Alt/Cmd = `mi`)
- **`s`** = `sol` (Shift = `si`, Alt/Cmd = `se`)
- **`l`** = `la` (Shift = `li`, Alt/Cmd = `le`)
- **`t`** = `ti` (Shift = `do`, Alt/Cmd = `te`)

*(Caps Lock state is ignored automatically so typing remains effortless).*

---

## 🚀 Running the Project

1. Install **[Solar2D Simulator](https://solar2d.com/)** (macOS or Windows).
2. Clone or download this repository.
3. Open Solar2D Simulator, select **Open Project**, and navigate to `main.lua`.

---

## 🤝 Peer Review & Feedback Context

If you are reviewing this project via **ChatGPT**, **Claude**, or GitHub Issues, we welcome feedback on:
1. **Enharmonic Engine Mechanics**: Are there edge-case melodic pathways where our directional spelling hierarchy (`ra`, `me`, `te` defaults with ascending stepwise sharp exceptions) could produce questionable theoretical spellings?
2. **Procedural Block Shuffling**: How can we optimize rule-based random melody block shuffling in `engine.lua` to balance strict pedagogical constraints with organic melodic flow?
3. **Harmonic Extension Architecture**: Recommendations for extending `playback.lua` and `ui.lua` to support simultaneous 2-note, 3-note, and 4-note chord stacks (Phases 3–5).
4. **Touch Device UI Design**: Best practices for implementing responsive on-screen touch keypads in Solar2D for mobile deployment.
