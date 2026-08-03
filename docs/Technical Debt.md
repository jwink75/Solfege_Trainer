# Technical Debt & Refactoring Roadmap

This document captures architectural refactoring ideas, technical debt items, and future optimization opportunities for **Solfège Star**.

---

## I. Architecture & Event Pipeline
- [ ] **`QuestionResult` Event Data Object**: Replace scattered inline logging parameters in `main.lua` with a unified `QuestionResult` payload containing `questionId`, `timestamp`, `exerciseType`, `expectedAnswer`, `userAnswer`, `isCorrect`, `responseTimeMs`, and `conceptsObserved`.
- [ ] **Dedicated `Session` Manager**: Group scattered session state variables (`currentQuestion`, `correctCount`, `score`, `streak`) into a dedicated `Session` module instance.

---

## II. Algorithmic Melodic Brain (`engine.lua`)
- [ ] **Leap-Limiter Octave-Shift Fallback**: When an interval leap collision occurs during random generation, prefer an octave transposition before falling back to a fully random pitch re-roll.

---

## III. Keypad & UI Layer (`ui.lua`)
- [ ] **Answer Buffer Expressiveness**: Add subtle visual animations to the answer buffer for octave shifts, tendency movements, and theoretical enharmonic auto-corrections.

---

## IV. Telemetry & Analytics (`stats.lua`)
- [ ] **Position Performance Visualization**: Expose per-note position accuracy (1st note, 2nd note, 3rd note) in the UI to help users diagnose whether errors stem from pitch hearing vs. working memory capacity.
