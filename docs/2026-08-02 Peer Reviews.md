## 2026-08-02

#### ChatGPT:

I spent some time looking through the current state of the project (README, `main.lua`, `ui.lua`, `stats.lua`, and the overall structure). My overall impression is that **this has crossed the line from "experiment" into "application."** The architecture is noticeably more disciplined than the last version I reviewed, and the recent additions (touch UI, persistent profiles, telemetry) are heading in the right direction.

That said, I think you're approaching another architectural inflection point. Nothing feels broken, but there are a few places where I'd make adjustments **before** adding much more functionality.

------

# Overall Assessment

I'd score the project approximately:

| Area               | Rating                         |
| ------------------ | ------------------------------ |
| Educational Design | A+                             |
| Architecture       | A-                             |
| UI Implementation  | B+                             |
| Extensibility      | A-                             |
| Technical Risk     | Low                            |
| Maintainability    | B+ (becoming the next concern) |

The most encouraging thing is that **I don't see any obvious dead ends.**

------

# What impressed me

## 1. The architecture has matured

Your README now describes the project almost exactly the way I would.

```
main
engine
playback
ui
progression
stats
```

Those are sensible module boundaries.

Compare this with the earlier versions, where `main.lua` was beginning to absorb everything.

Now it feels like a coordinator.

That's a big improvement.

------

## 2. The statistics system

This is probably my favorite recent addition.

I especially liked that you separated things into categories like

```lua
pitches

tendencies

melodyLengths

positionInSequence

stacks

chordQualities
```

This is exactly the sort of data model that will support adaptive learning later.

------

## 3. You store attempts and correct separately

Excellent decision.

I was happy to see

```lua
attempts

correct
```

instead of

```lua
accuracy = 0.92
```

That's absolutely the right foundation.

------

## 4. Multiple users

Good decision to implement this now.

You did it before achievements.

Exactly the order I would have recommended.

------

# The biggest red flag

Ironically…

It's **main.lua**.

Not because it's poorly written.

Because it's becoming the conductor of absolutely everything.

I can already see

- timers
- playback
- progression
- scoring
- state machine
- answer evaluation
- UI updates
- exercise generation

all flowing through one file.

That's manageable today.

I'm not convinced it'll still be manageable after another six months.

------

## I'd start thinking about an Application Controller

Instead of

```
main.lua

    evaluates

    updates score

    records stats

    changes state

    updates UI
```

I'd like to eventually see

```
main

↓

GameController

↓

ExerciseController

↓

StatsController

↓

UI
```

Not today.

Not next week.

But I'd put that on your roadmap.

------

# The stats system needs one more abstraction

Right now it feels like

```
stats.lua

stores statistics
```

I'd like it to become

```
stats.lua

stores events
```

That sounds subtle, but it's huge.

Instead of

```lua
stats.recordPitch(...)
```

I'd rather see something like

```lua
stats.recordQuestion(question, answer)
```

Then Stats decides

- which pitches appeared
- which tendencies occurred
- melody length
- stack size
- chord quality
- streak
- etc.

That keeps the recording logic in one place instead of scattered through the codebase.

------

# I'd add Question IDs

Every generated exercise should receive

```lua
question.id
```

Even if it's just

```
1729421
```

That opens the door to:

- replaying questions
- exporting sessions
- debugging
- adaptive review
- "You missed this yesterday."

It's a tiny addition with a lot of future value.

------

# UI observations

I actually like the direction.

Especially:

- Boomwhacker colors
- Rounded pills
- Dynamic sizing
- Kodály octave marks

Those are all tasteful.

------

## But…

The UI is still mostly **functional** rather than **delightful**.

That's perfectly okay.

I'd actually freeze aesthetics for a while.

Instead I'd focus on interaction.

Questions like:

- How does entering an answer feel?
- Is replay obvious?
- Is deleting easy?
- Can one thumb reach everything?

Those are worth much more than gradients.

------

# I think you're ready for animations

Not flashy animations.

Tiny ones.

For example

Correct answer

```
tap

↓

button compresses

↓

slot fills

↓

tiny pop
```

Wrong answer

```
shake

↓

red flash

↓

correction fades in
```

These add far more polish than redesigning the graphics.

------

# Profiles

I think you're storing enough information.

I would add:

```
lastPlayed

favoriteMode

preferredInputMethod
```

Those become useful later.

------

# Statistics

Here's what I'd still add.

------

## Response time

Quietly record

```
milliseconds
```

Never show it.

Use it later.

------

## Error pairs

This is probably the biggest omission.

Instead of only knowing

```
fi

82%
```

know

```
fi mistaken as sol

17 times

fi mistaken as fa

3 times
```

That's educational gold.

Eventually you can say

> "Students who confuse fi and sol often benefit from…"

No other ear-training app does that.

------

## Confidence

Still my favorite future feature.

Even if you never implement the UI,

leave room in the data model.

------

# One architectural suggestion

I'd create

```
analytics.lua
```

Not now.

Eventually.

Stats are

```
raw data
```

Analytics are

```
interpretation
```

Example

Stats

```
fi

92%
```

Analytics

```
Mastery: 81

Trending upward

Recommended review: low
```

Those are different jobs.

------

# Documentation

Your README has become excellent.

I'd add one more document.

```
docs/

Architecture.md
```

Describe:

- state transitions
- data flow
- module ownership

Future-you will thank present-you.

------

# My biggest recommendation

I would **stop adding musical content** for a while.

Seriously.

Instead I'd spend the next several iterations building infrastructure.

Specifically, I'd work on these in order:

1. **Finish the user/profile system.**
   - Profile selection at launch.
   - Create, rename, and delete profiles.
   - Persist preferences (last level, input settings, etc.).
2. **Turn statistics into a first-class feature.**
   - Build a simple stats viewer.
   - Verify that every exercise records data correctly.
   - Add error-pair tracking and response times.
3. **Polish the interaction loop.**
   - Touch animations.
   - Immediate feedback.
   - Better transitions.
   - Refined answer entry.
4. **Only then begin gamification.**
   - Constellations.
   - Mastery maps.
   - Achievements.
   - Adaptive review.

That sequence builds each layer on a solid foundation instead of forcing you to retrofit systems later.

## The one thing I'd change before anything else

If I could ask Antigravity to do just **one** refactor next, it would be this:

> **Move all post-question processing into a single `QuestionResult` pipeline.**

Right now, after a user submits an answer, several things happen:

- the answer is evaluated,
- the score changes,
- the UI updates,
- the streak changes,
- statistics are recorded,
- progression may change,
- the next exercise is prepared.

Those all conceptually belong to one event: **"a question has been completed."**

I'd create a single object (or table) representing that result and pass it through one processing function. That makes it much easier to add future features like achievements ("10 perfect answers in a row"), adaptive review ("student missed fi again"), daily goals, session summaries, or constellation progression without sprinkling hooks throughout `main.lua`.

## To me, that's the architectural change with the highest long-term payoff before you begin building the game's reward systems.

#### Claude:

Dug through all of it — good news first: the git/icon build issues are fully resolved, and the augmented-triad enharmonic bug from last time is properly fixed (default correctly reverted to `le`, `isAugmented` is now genuinely wired from `main.lua` by checking for `"+"` in the unit name, and I confirmed `iii+`/`i+` are the only units that match, so it's scoped correctly). The stats architecture itself is well-designed — attribute-tagged rather than level-ID-anchored, raw counts not percentages, clean multi-profile CRUD. But the wiring between `main.lua` and `stats.lua` has real gaps, and there's one significant data-durability risk. Going in severity order.

## Critical — the flagship feature you asked for isn't actually running

**Tendency-context tracking (explicit/procedural/accidental) is dead code end-to-end.** In `main.lua`, `tendInfo` is built as `(activeItem and activeItem.id) and { id = activeItem.id } or nil` — but `engine.generateMelody` never returns an `.id` field on `activeItem`, only `.name`. So `activeItem.id` is always `nil`, `tendInfo` is always `nil`, and every single tendency-tagged attempt in `stats.lua`'s `logAttempt` silently skips the entire tendency-recording branch. This was the specific feature you named first and we spent the most design time on — right now it's recording nothing.

It's worse than a one-line fix, too: even if you swap `.id` for `.name`, the vocabularies don't match. `engine.lua`'s internal tendency IDs are `"t-ti"`, `"t-fa"`, `"t-re"`, `"t-fi-s"`, `"t-le-s"`, etc., while `stats.lua`'s `canonicalTendencies` list expects `"t-d"`, `"f-m"`, `"r-d"`, `"fi-s"`, `"le-s"`. Two different naming conventions grew up in the two files independently. And there's no `source` field ever set in `tendInfo` at all, so even a correctly-matched tendency would always log as `"explicit"` — there's no logic anywhere in `main.lua` that distinguishes an ID-mode drill from a rule-inserted tendency from an incidental match in random generation. That three-way split needs to actually be built; right now the schema exists in `stats.lua` but nothing populates it.

**Chord-quality tracking is similarly dead.** `stats.lua`'s `logAttempt` has a full branch for `event.chordQuality`, and the default profile has buckets for `major_triad`, `minor_triad`, `diminished_triad`, `augmented_triad`, `dominant_7th`, `major_7th`, `minor_7th` — but `main.lua`'s actual call to `stats.logAttempt({…})` never includes a `chordQuality` field at all. Zero chord-quality data is being recorded right now, for any stack level. Separately, even once that's wired up, `half_diminished_7th` and `diminished_7th` aren't in `stats.lua`'s default table at all, despite levels 19.1/19.2 (`vii-o7`, `dim7`) already existing in `progression.lua` — those two levels will silently fail to record even after the wiring is fixed, since `if event.chordQuality and prof.chordQualities[event.chordQuality] then` will just skip on a missing key.

**A phantom "incorrect" is logged for the resolution note on every single-input question.** For ID-mode levels (1.x, 3.x — `isSingleInput = true`), `numNotesInExercise` is computed as `#activeItem.notes`, which is 2 for a tendency pair like `t-d`, even though the UI only collects one answer. The scoring loop then iterates `i = 1, numNotesInExercise`, and for `i = 2` there's no `userAnswers[2]` (never entered), so `hasFailedFirstTry[2]` gets set true unconditionally. That flows straight into the stats-logging loop at the bottom, which logs `isCorrect = not hasFailedFirstTry[i]` for every `i` up to `numNotesInExercise` — meaning **every ID-mode question logs a false "wrong" attempt for the resolution note's pitch class**, tagged into the `single` bucket specifically. Since resolution notes skew toward stable tones (`do`, `sol`, `mi`), this is quietly deflating exactly the "single-note ID accuracy" numbers for those pitches, every time these levels are played. This one's subtle but real — worth fixing before you trust any pitch-accuracy number the app shows you.

## High — data durability

`stats.logAttempt` calls `M.save()` unconditionally at the end of every single note evaluated — not once per question, once per *note*. Two problems stack here: it's wasteful I/O (a full JSON encode + write of the entire multi-profile blob on every note, mid-quiz), and it's a non-atomic write (`io.open(filePath, "w")` truncates and rewrites in place). If the app gets killed mid-write — plausible on iOS, where the OS can terminate backgrounded apps without warning — you're left with a truncated JSON file. Compounding that, `M.load()` never wraps `json.decode` in `pcall`; a corrupted file will throw on the next launch with nothing catching it. Put together, that's a real path to "app won't open and all profile data is gone," triggered by something as mundane as a phone call arriving mid-quiz. I'd fix both ends: batch saves to question-end (you already have `event.isQuestionEnd` available) rather than every note, and wrap the load-decode in `pcall` so a corrupt file degrades to "start fresh" instead of crashing.

## Medium

- **Switching profiles mid-session doesn't reset session stats.** `M.setActiveProfile` only updates `lastActive` and the active pointer — session reset (`questions`, `currentStreak`, etc.) only happens in `M.init()` at app launch. Switch to a different user without restarting the app, and their `session` table shows whatever was left over from their last run, not a fresh session.
- **The Mastery Index — the single idea everyone agreed was the best one — isn't used anywhere.** `getMasteryIndex` exists and is implemented, but nothing in `main.lua` or `ui.lua` ever calls it. And when you do wire it up, it's currently missing the recency component: the formula is just `accuracy × log-scaled-volume`, even though `recentAttempts` (a 20-entry rolling buffer) is already being collected on every pitch specifically for this purpose — it's written on every attempt and never read anywhere.
- `logAttempt`'s mode-bucket lookup (`prof.pitches[pcStr][modeStr] or prof.pitches[pcStr].single`) silently falls back to "single" if `modeStr` is ever something unexpected, which would mask a caller bug rather than surfacing it.

## Low / hygiene

- `File Renamer.app` is still tracked in git (moved into `docs/`, excluded from the *build* via `excludeFiles`, but it shouldn't be a tracked file at all — an Automator app isn't documentation).
- The leap-limiter's fallback-to-fully-random-pitch on collision (flagged in the first audit) is still there, unaddressed.
- One item I can't fully confirm either way: several core interactions (`createTouchKey`, pill buttons) attach `"touch"` listeners directly to a bare `display.newGroup()` rather than to a hit-testable rect within it. Solar2D's own tutorials generally attach a dedicated invisible `isHitTestable` rect for this pattern rather than listening on the group directly — it's a known gray area. Given you've said the UI is "more or less working," this is probably fine in practice, but worth specifically testing tap-accuracy at the very edges of each pill (not just the center) on the physical device, since a hit-test issue here would manifest as edge-taps missing rather than total failure.

## Suggested order of fixes

1. Fix the `activeItem.id`/tendency-ID mismatch and add real `source` classification (explicit/procedural/accidental) — this is the core feature.
2. Wire `chordQuality` through from `main.lua`, add the missing dim7/half-dim7 keys.
3. Fix the phantom-incorrect logging for unanswered slots in single-input mode.
4. Batch `M.save()` to question-end, add `pcall` around load.
5. Reset session on profile switch.