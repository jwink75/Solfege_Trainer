-- file: progression.lua
-- version: 13.0
-- status: Re-sequenced curriculum syllabus (Levels 1.x - 19.x) with Checkpoints

local m = {}

m.levels = {
    -- LEVEL 1: DIATONIC TENDENCIES (ID MODE)
    [1.1] = { description = "diatonic tendency pairs", units = { {notes={0,7}, name="d-s"}, {notes={11,12}, name="t-d"}, {notes={5,4}, name="f-m"} } },
    [1.2] = { description = "diatonic stepwise down", units = { {notes={2,0}, name="r-d"}, {notes={9,7}, name="l-s"} } },
    [1.3] = { description = "adding 3-note diatonic resolutions", units = { {notes={4,2,0}, name="m-r-d"}, {notes={9,11,12}, name="l-t-d"} } },

    -- LEVEL 2: SINGLE DIATONIC NOTES (ID MODE)
    [2.1] = { description = "id: unstable notes (t, f)", units = { 11, 5 } },
    [2.2] = { description = "adding r and l", units = { 2, 9 } },
    [2.3] = { description = "adding d, m, s", units = { 0, 4, 7 } },

    -- LEVEL 3: CHROMATIC TENDENCIES + SINGLES (ID MODE)
    [3.1] = { description = "chromatic tendency pairs", units = { {notes={6,7}, name="fi-s"}, {notes={8,7}, name="le-s"}, {notes={1,0}, name="ra-d"}, {notes={10,12}, name="te-d"} } },
    [3.2] = { description = "3-note chromatic resolution", units = { {notes={3,2,0}, name="me-r-d"} } },
    [3.3] = { description = "id: chromatic singles (ra, me, fi, le, te)", units = { 1, 3, 6, 8, 10 } },

    -- LEVEL 4: 2-NOTE DIATONIC MELODIES
    [4.1] = { description = "2-note tendency pairs", units = { {notes={11,12}, name="t-d"}, {notes={5,4}, name="f-m"}, {notes={2,0}, name="r-d"} } },
    [4.2] = { description = "2-note anchor melodies", units = { {notes={2,0}, name="r-anchor"}, {notes={0,7}, name="d-anchor"}, {notes={5,7}, name="f-anchor"}, {notes={4,0}, name="m-anchor"} } },
    [4.3] = { description = "2-note random diatonic", units = { {notes={0,4}, name="d-m"}, {notes={4,7}, name="m-s"}, {notes={7,9}, name="s-l"}, {notes={9,5}, name="l-f"} } },

    -- LEVEL 5: DIATONIC DYADS — 3RDS & 6THS ONLY
    [5.1] = { isStack = true, description = "diatonic dyads: 3rds & 6ths", units = { 
        {notes={0,4}, name="d-m"}, {notes={2,5}, name="r-f"}, {notes={4,7}, name="m-s"}, {notes={5,9}, name="f-l"}, {notes={7,11}, name="s-t"}, {notes={9,12}, name="l-d"}, {notes={11,14}, name="t-r"},
        {notes={0,9}, name="d-l"}, {notes={2,11}, name="r-t"}, {notes={4,12}, name="m-d"}, {notes={5,14}, name="f-r"}, {notes={7,16}, name="s-m"}, {notes={9,17}, name="l-f"}, {notes={11,19}, name="t-s"}
    } },

    -- LEVEL 6: 2-NOTE CHROMATIC MELODIES
    [6.1] = { description = "2-note chromatic resolutions", units = { {notes={6,7}, name="fi-s"}, {notes={8,7}, name="le-s"}, {notes={1,0}, name="ra-d"}, {notes={10,12}, name="te-d"} } },
    [6.2] = { description = "2-note diatonic/chromatic mix", rule = { chromatics = 1, randoms = 1 } },
    [6.3] = { description = "2-note random chromatic (1 chromatic max)", rule = { chromatics = 1, randoms = 1 } },

    -- LEVEL 7: 3-NOTE DIATONIC MELODIES
    [7.1] = { description = "tendency/random mix", rule = { tendencies = 1, randoms = 1 } },
    [7.2] = { description = "diatonic triads (root position)", units = { {notes={0,4,7}, name="i"}, {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"}, {notes={9,12,16}, name="vi"}, {notes={11,14,17}, name="vii-o"} } },
    [7.3] = { description = "diatonic triads (inversions)", units = { {notes={4,7,12}, name="i-6"}, {notes={7,12,16}, name="i-64"}, {notes={9,12,17}, name="iv-6"}, {notes={12,17,21}, name="iv-64"}, {notes={11,14,19}, name="v-6"}, {notes={14,19,23}, name="v-64"} } },
    [7.4] = { description = "3 random diatonic notes", rule = { randoms = 3 } },

    -- LEVEL 8: DIATONIC TRIADS (ROOT POSITION) STACKS
    [8.1] = { isStack = true, description = "major triads (root position)", units = { {notes={0,4,7}, name="i"}, {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"} } },
    [8.2] = { isStack = true, description = "minor triads (root position)", units = { {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, {notes={9,12,16}, name="vi"} } },
    [8.3] = { isStack = true, description = "all root triads", units = { {notes={0,4,7}, name="i"}, {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"}, {notes={9,12,16}, name="vi"}, {notes={11,14,17}, name="vii-o"} } },

    -- LEVEL 9: CHROMATIC DYADS — 3RDS & 6THS ONLY
    [9.1] = { isStack = true, description = "chromatic dyads: 3rds & 6ths", units = { {notes={0,3}, name="d-me"}, {notes={2,6}, name="r-fi"}, {notes={4,6}, name="m-fi"}, {notes={7,10}, name="s-te"}, {notes={11,15}, name="t-ri"}, {notes={8,15}, name="le-m"} } },

    -- LEVEL 10: 3-NOTE CHROMATIC MELODIES (1 CHROMATIC MAX)
    [10.1] = { description = "3-note chromatic pathway", rule = { chromaticPathways3 = 1 } },
    [10.2] = { description = "3-note diatonic/chromatic mix", rule = { chromaticPairs2 = 1, randoms = 1 } },
    [10.3] = { description = "3-note chromatic random (1 chromatic max)", rule = { chromatics = 1, randoms = 2 } },
    [10.4] = { description = "3-note chromatic boss", rule = { chromaticPairs2 = 1, randoms = 1 } },

    -- CHECKPOINT 1
    [10.9] = { description = "CHECKPOINT 1: Cumulative Mid-Term Review", isCheckpoint = true },

    -- LEVEL 11: 4-NOTE DIATONIC MELODIES
    [11.1] = { description = "4-note: 2 tendency pairs", rule = { tendencies = 2 } },
    [11.2] = { description = "4-note: tendency pair + 2 random", rule = { tendencies = 1, randoms = 2 } },
    [11.3] = { description = "4-note diatonic boss", rule = { randoms = 4 } },

    -- LEVEL 12: DYADS REMAINDER (4THS/5THS/2NDS/7THS, DIATONIC + CHROMATIC)
    [12.1] = { isStack = true, description = "diatonic dyads: 4ths & 5ths", units = { 
        {notes={0,5}, name="d-f"}, {notes={2,7}, name="r-s"}, {notes={4,9}, name="m-l"}, {notes={5,11}, name="f-t"}, {notes={7,12}, name="s-d"}, {notes={9,14}, name="l-r"}, {notes={11,16}, name="t-m"},
        {notes={0,7}, name="d-s"}, {notes={2,9}, name="r-l"}, {notes={4,11}, name="m-t"}, {notes={5,12}, name="f-d"}, {notes={7,14}, name="s-r"}, {notes={9,16}, name="l-m"}, {notes={11,17}, name="t-f"}
    } },
    [12.2] = { isStack = true, description = "chromatic dyads: 4ths & 5ths", units = { {notes={0,6}, name="d-fi"}, {notes={6,11}, name="fi-t"}, {notes={8,14}, name="le-r"}, {notes={10,16}, name="te-m"} } },
    [12.3] = { isStack = true, description = "diatonic dyads: 2nds & 7ths", units = { 
        {notes={0,2}, name="d-r"}, {notes={2,4}, name="r-m"}, {notes={4,5}, name="m-f"}, {notes={5,7}, name="f-s"}, {notes={7,9}, name="s-l"}, {notes={9,11}, name="l-t"}, {notes={11,12}, name="t-d"},
        {notes={0,11}, name="d-t"}, {notes={2,12}, name="r-d"}, {notes={4,14}, name="m-r"}, {notes={5,16}, name="f-m"}, {notes={7,17}, name="s-f"}, {notes={9,19}, name="l-s"}, {notes={11,21}, name="t-l"}
    } },
    [12.4] = { isStack = true, description = "all remaining dyads", units = { 
        {notes={0,5}, name="d-f"}, {notes={0,6}, name="d-fi"}, {notes={0,7}, name="d-s"}, {notes={2,7}, name="r-s"}, {notes={5,11}, name="f-t"}, {notes={6,11}, name="fi-t"}, {notes={0,2}, name="d-r"}, {notes={0,11}, name="d-t"}
    } },

    -- LEVEL 13: TRIAD INVERSIONS
    [13.1] = { isStack = true, description = "triads (1st inversion)", units = { {notes={4,7,12}, name="i-6"}, {notes={9,12,17}, name="iv-6"}, {notes={11,14,19}, name="v-6"} } },
    [13.2] = { isStack = true, description = "triads (2nd inversion)", units = { {notes={7,12,16}, name="i-64"}, {notes={12,17,21}, name="iv-64"}, {notes={14,19,23}, name="v-64"} } },
    [13.3] = { isStack = true, description = "all inverted triads", units = { {notes={4,7,12}, name="i-6"}, {notes={7,12,16}, name="i-64"}, {notes={9,12,17}, name="iv-6"}, {notes={12,17,21}, name="iv-64"}, {notes={11,14,19}, name="v-6"}, {notes={14,19,23}, name="v-64"} } },

    -- LEVEL 14: 4-NOTE CHROMATIC MELODIES
    [14.1] = { description = "4-note: 1 chromatic pair + diatonic pair", rule = { chromaticPairs2 = 1, tendencies = 1 } },
    [14.2] = { description = "4-note: chromatic pair + 2 random", rule = { chromaticPairs2 = 1, randoms = 2 } },
    [14.3] = { description = "4-note chromatic boss", rule = { chromaticPairs2 = 1, chromatics = 2 } },

    -- LEVEL 15: DIM/AUG TRIADS + OPEN VOICINGS
    [15.1] = { isStack = true, description = "diminished triads", units = { {notes={11,14,17}, name="vii-o"}, {notes={2,5,8}, name="ii-o"} } },
    [15.2] = { isStack = true, description = "augmented triads", units = { {notes={4,8,12}, name="iii+"}, {notes={0,4,8}, name="i+"} } },
    [15.3] = { isStack = true, description = "3-note open voicings (max maj 10th)", units = { {notes={0,7,16}, name="open-1"}, {notes={2,9,16}, name="open-2"}, {notes={5,12,21}, name="open-3"} } },

    -- LEVEL 16: 5-NOTE DIATONIC MELODIES
    [16.1] = { description = "5-note: 2 pairs + 1 random", rule = { tendencies = 2, randoms = 1 } },
    [16.2] = { description = "5-note: 1 tendency + 3-note chain/triad", rule = { tendencies = 1, randoms = 3 } },
    [16.3] = { description = "5-note diatonic boss", rule = { randoms = 5 } },

    -- LEVEL 17: 7TH CHORDS (DOMINANT, MAJ7, MIN7)
    [17.1] = { isStack = true, description = "dominant 7th chords", units = { 
        {notes={7,11,14,17}, name="v7"}, {notes={0,4,7,10}, name="v7/iv"}, {notes={2,6,9,12}, name="v7/v"}, 
        {notes={4,8,11,14}, name="v7/vi"}, {notes={11,14,17,19}, name="v7-65"}, {notes={14,17,19,23}, name="v7-43"} 
    } },
    [17.2] = { isStack = true, description = "major & minor 7th chords", units = { {notes={0,4,7,11}, name="i-maj7"}, {notes={5,9,12,16}, name="iv-maj7"}, {notes={2,5,9,12}, name="ii7"}, {notes={9,12,16,19}, name="vi7"} } },
    [17.3] = { isStack = true, description = "all 7th chords", units = { {notes={0,4,7,11}, name="i-maj7"}, {notes={2,5,9,12}, name="ii7"}, {notes={5,9,12,16}, name="iv-maj7"}, {notes={7,11,14,17}, name="v7"}, {notes={9,12,16,19}, name="vi7"} } },

    -- LEVEL 18: 5-NOTE CHROMATIC MELODIES
    [18.1] = { description = "5-note: chromatic pathway + diatonic pair", rule = { chromaticPathways3 = 1, tendencies = 1 } },
    [18.2] = { description = "5-note: 1 chromatic pair + 3 random", rule = { chromaticPairs2 = 1, randoms = 3 } },
    [18.3] = { description = "5-note chromatic boss", rule = { chromaticPairs2 = 1, chromatics = 3 } },

    -- LEVEL 19: DIM7 CHORDS + 4-NOTE OPEN VOICINGS
    [19.1] = { isStack = true, description = "half-diminished 7th", units = { {notes={11,14,17,21}, name="vii-o7"} } },
    [19.2] = { isStack = true, description = "fully diminished 7th", units = { {notes={11,14,17,20}, name="dim7"} } },
    [19.3] = { isStack = true, description = "4-note open voicings & clusters", units = { {notes={0,7,12,16}, name="stack-1"}, {notes={5,12,16,21}, name="stack-2"}, {notes={7,14,17,23}, name="stack-3"} } },

    -- CHECKPOINT 2
    [19.9] = { description = "CHECKPOINT 2: Comprehensive Final Review", isCheckpoint = true }
}

return m