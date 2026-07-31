# Solfège Trainer — Gamification & Pedagogical Feature Ideas

---

## 🏛️ 1. Conservatory Progression & Ranks
Instead of abstract level numbers, students progress through musical ranks:
1. **Preparatory Student**
2. **Chorister**
3. **Section Leader**
4. **Soloist**
5. **Assistant Conductor**
6. **Conductor**
7. **Maestro**

---

## 🎯 2. Specialized Functional Game Modes

### A. Tendency & Resolution Trainer
- **Directional Hearing**: Play a note (e.g. `fa` or `ti`) and ask: *"What does this note want to do?"* -> Options: `Up`, `Down`, `Stay`.
- **Resolution Sizer**: Play an unstable note (`ti`); user sings or selects the target resolution (`do`).

### B. Solfège "Name That Tune"
- Play the opening solfège pattern of well-known melodies (folk tunes, anthems, classical themes); users identify the tune by ear and solfège structure.

### C. Solfège Bee & Choir Mode
- **Solfège Bee**: Hot-seat elimination mode for individuals or small groups using single-note/tendency ID banks.
- **Choir Mode / Teacher Room Codes**: Real-time group dictation where a room code lets students take the same exercise simultaneously and view live class results.

### D. Internal Audiation Mode
- Silent mode: Display a starting note (`do`) and ask *"What does ti sound like?"*. Student internalizes the sound before hearing playback to check accuracy.

---

## ⚡ 3. Boss Levels & Daily Challenges

- **Boss Level Modifiers**:
  - Modifiers: *No hints*, *No replay*, *Strict timer*, *No forced reveal (sudden death)*.
  - Passing unlocks the next major Conservatory chapter.
- **Daily Challenge**:
  - Seeded exercise generator (`math.randomseed` derived from current date) so all users tackle the exact same daily 6-note / 2-chromatic challenge.

---

## 📊 4. Student Analytics & Adaptive Mastery

- **Per-Degree Mastery Statistics**:
  - Track accuracy and speed for every scale degree independently (`ti`: 82%, `fi`: 41%, `le`: 95%, `ascending ti`: 90%, `descending ti`: 58%).
- **Adaptive Spaced Repetition**:
  - Automatically inject scale degrees with lower accuracy into the cumulative review pool.

---

## 🏅 5. Social & Metagame Features

- **Streaks & Consistency**:
  - Reward accurate singing and daily practice streaks rather than raw log-in frequency.
- **In-Game Currency & Shop**:
  - Earn currency through accuracy to unlock new sample soundbanks (Grand Piano, Harpsichord, Choir Aahs), UI themes, and genre packs.
