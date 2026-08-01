# Solfège Trainer — UI & UX Ideas & Design Roadmap

This document captures user interface, visual design, and interaction ideas gathered from peer reviews (ChatGPT & Claude) and pedagogical design discussions.

---

## 📱 1. On-Screen Touch Keypad & Layout (Mobile & Tablet)
- **2-Tier Radial or Grid Solfège Keypad**:
  - Main Tier (Diatonic): Large touch targets for `do`, `re`, `mi`, `fa`, `sol`, `la`, `ti`.
  - Secondary Tier (Chromatic): Flanking chromatic buttons (`ra`, `di`, `me`, `ri`, `fi`, `se`, `le`, `si`, `te`, `li`) that dynamically light up or reveal only when enabled in the level.
- **Dedicated Touch Action Targets**:
  - Clean, prominent touch targets for `Submit` (ENTER), `Delete` (Backspace), `Cadence` (C/K), and `Replay` (Q).

---

## 🎨 2. Functional Color System
- **Scale Degree Functional Color Palette**:
  - Instead of static box colors, color-code scale degrees by functional stability:
    - **Stable Tones (`do`, `mi`, `sol`)**: Warm, grounding colors (e.g. Amber/Gold, Soft Warm Blue).
    - **Unstable/Tonal Tendency Tones (`ti`, `fa`, `re`)**: High-contrast, magnetic accent colors (e.g. Crimson for `ti`, Coral for `fa`).
    - **Chromatics (`fi`, `le`, `ra`, etc.)**: Electric / vibrant accent hues.
  - Apply colors consistently across answer boxes, level browser cards, and touch keypads.

---

## 🎹 3. Visual Cadence & Playback Indicators
- **Visual Cadence Chord Display**:
  - Display active chord labels (`I`, `IV`, `V`, `I`) above the header during cadence playback, lighting up each chord in sync with audio.
- **Melodic Playback Step Indicator**:
  - Render progress dots/squares (`■ □ □ □ □`) showing the current playing position in real-time as notes ring out.

---

## 📊 4. Live Decayed Potential Meter ("Slot Health Bars")
- **Live Visual Slot Decay**:
  - Render a small 5-segment potential bar (10 -> 8 -> 6 -> 4 -> 2 -> 0) above each note slot during dictation.
  - As incorrect attempts occur, the potential meter visually ticks down, making the 5-strike decay system clear and engaging in real time.

---

## 🎯 5. Confidence Meter (Meta-Cognitive Analytics)
- **Post-Answer Confidence Rating**:
  - After submitting an answer (or per note), provide quick 1-tap confidence ratings:
    - `Certain` / `Pretty Sure` / `Guessing`
  - Allows the app's student model to differentiate between *accurate & confident* vs. *accurate & guessing* vs. *confidently incorrect* misconceptions.

---

## 🏆 6. Conservatory Progress & Mastery Rings
- **Mastery Rings per Syllable**:
  - Circular progress rings for each scale degree (`do` 100%, `ti` 85%, `fi` 40%) displayed on the main menu or profile screen.
- **Visual Conservatory Title Header**:
  - Header badge reflecting student title (*Chorister*, *Section Leader*, *Soloist*, *Maestro*).
