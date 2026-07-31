-- file: progression.lua
-- version: 12.9
-- status: expanded level 4 (root vs inversions) + full diatonic triads

local m = {}

m.levels = {
    [1.1] = { description = "diatonic tendency pairs", units = { {notes={0,7}, name="d-s"}, {notes={11,12}, name="t-d"}, {notes={5,4}, name="f-m"} } },
    [1.2] = { description = "diatonic stepwise down", units = { {notes={2,0}, name="r-d"}, {notes={9,7}, name="l-s"} } },
    [1.3] = { description = "adding 3-note diatonic resolutions", units = { {notes={4,2,0}, name="m-r-d"}, {notes={9,11,12}, name="l-t-d"} } },

    [2.1] = { description = "id: unstable notes (t, f)", units = { 11, 5 } },
    [2.2] = { description = "adding r and l", units = { 2, 9 } },
    [2.3] = { description = "adding d, m, s", units = { 0, 4, 7 } },

    [3.1] = { description = "2-note tendency pairs", units = { {notes={11,12}, name="t-d"}, {notes={5,4}, name="f-m"}, {notes={2,0}, name="r-d"} } },
    [3.2] = { description = "2-note anchor melodies", units = { {notes={2,0}, name="r-anchor"}, {notes={0,7}, name="d-anchor"}, {notes={5,7}, name="f-anchor"}, {notes={4,0}, name="m-anchor"} } },
    [3.3] = { description = "2-note random diatonic", units = { {notes={0,4}, name="d-m"}, {notes={4,7}, name="m-s"}, {notes={7,9}, name="s-l"}, {notes={9,5}, name="l-f"} } },

    -- LEVEL 4: 3-NOTE MELODIES
    [4.1] = { 
        description = "tendency/random mix + chains", 
        units = { {notes={9,11,12}, name="l-t-d"}, {notes={4,2,0}, name="m-r-d"} },
        rule = { tendencies = 1, randoms = 1 } 
    },
    [4.2] = { 
        description = "diatonic triads (root position)", 
        units = { 
            {notes={0,4,7}, name="i"}, {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, 
            {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"}, {notes={9,12,16}, name="vi"}, {notes={11,14,17}, name="vii-o"} 
        } 
    },
    [4.3] = { 
        description = "diatonic triads (inversions)", 
        units = { 
            {notes={4,7,12}, name="i-6"}, {notes={7,12,16}, name="i-64"},
            {notes={9,12,17}, name="iv-6"}, {notes={12,17,21}, name="iv-64"},
            {notes={11,14,19}, name="v-6"}, {notes={14,19,23}, name="v-64"} 
        } 
    },
    [4.4] = { description = "3 random diatonic notes", rule = { randoms = 3 } },

    -- LEVEL 5 & 6 (Keeping the rules as defined in your amendment)
    [5.1] = { description = "2 pairs or 3-note tendency + random", rule = { tendencies = 2 } }, -- Engine handles the mix
    [5.2] = { description = "tendency pair + 2 random", rule = { tendencies = 1, randoms = 2 } },
    [5.3] = { description = "4 random diatonic notes", rule = { randoms = 4 } },

    [6.1] = { description = "2 pairs + 1 random", rule = { tendencies = 2, randoms = 1 } },
    [6.2] = { description = "1 tendency + 3-note chain/triad", rule = { tendencies = 1, randoms = 3 } },
    [6.3] = { description = "tendency + 3 random notes", rule = { tendencies = 1, randoms = 3 } },
    [6.4] = { description = "5 random notes", rule = { randoms = 5 } },

    -- PHASE 2: CHROMATIC MELODIC EXPANSION
    -- LEVEL 7: CHROMATIC TENDENCIES (ID MODE)
    [7.1] = { description = "chromatic tendency pairs", units = { {notes={6,7}, name="fi-s"}, {notes={8,7}, name="le-s"}, {notes={1,0}, name="ra-d"}, {notes={10,12}, name="te-d"} } },
    [7.2] = { description = "3-note chromatic resolution", units = { {notes={3,2,0}, name="me-r-d"} } },

    -- LEVEL 8: SINGLE CHROMATIC NOTES (ID MODE)
    [8.1] = { description = "id: ra, me, fi", units = { 1, 3, 6 } },
    [8.2] = { description = "id: le, te", units = { 8, 10 } },
    [8.3] = { description = "id: all chromatic notes", units = { 1, 3, 6, 8, 10 } },

    -- LEVEL 9: 2-NOTE CHROMATIC MELODIES
    [9.1] = { description = "2-note chromatic tendency pairs", units = { {notes={6,7}, name="fi-s"}, {notes={8,7}, name="le-s"}, {notes={1,0}, name="ra-d"}, {notes={10,12}, name="te-d"} } },
    [9.2] = { description = "2-note diatonic/chromatic mix", rule = { chromatics = 2 } },
    [9.3] = { description = "2-note random chromatic", rule = { chromatics = 2 } },

    -- LEVEL 10: 3-NOTE CHROMATIC MELODIES
    [10.1] = { description = "3-note chromatic pathway", rule = { chromaticPathways3 = 1 } },
    [10.2] = { description = "3-note diatonic/chromatic mix", rule = { chromaticPairs2 = 1, randoms = 1 } },
    [10.3] = { description = "3-note chromatic random", rule = { chromatics = 3 } },
    [10.4] = { description = "3-note chromatic boss", rule = { chromaticPairs2 = 1, chromatics = 1 } },

    -- LEVEL 11: 4-NOTE CHROMATIC MELODIES
    [11.1] = { description = "4-note: 1 chromatic pair + diatonic pair", rule = { chromaticPairs2 = 1, tendencies = 1 } },
    [11.2] = { description = "4-note: chromatic pair + 2 random", rule = { chromaticPairs2 = 1, randoms = 2 } },
    [11.3] = { description = "4-note chromatic boss", rule = { chromaticPairs2 = 1, chromatics = 2 } },

    -- LEVEL 12: 5-NOTE CHROMATIC MELODIES
    [12.1] = { description = "5-note: chromatic pathway + diatonic pair", rule = { chromaticPathways3 = 1, tendencies = 1 } },
    [12.2] = { description = "5-note: 1 chromatic pair + 3 random", rule = { chromaticPairs2 = 1, randoms = 3 } },
    [12.3] = { description = "5-note: 2 chromatic pairs + 1 random", rule = { chromaticPairs2 = 2, randoms = 1 } },
    [12.4] = { description = "5-note chromatic boss", rule = { chromaticPairs2 = 1, chromatics = 3 } },

    -- PHASE 3: DYADS (2-NOTE STACKS)
    [13.1] = { isStack = true, description = "dyads: 3rds & 6ths", units = { 
        {notes={0,4}, name="d-m"}, {notes={2,5}, name="r-f"}, {notes={4,7}, name="m-s"}, {notes={5,9}, name="f-l"}, {notes={7,11}, name="s-t"}, {notes={9,12}, name="l-d"}, {notes={11,14}, name="t-r"},
        {notes={0,9}, name="d-l"}, {notes={2,11}, name="r-t"}, {notes={4,12}, name="m-d"}, {notes={5,14}, name="f-r"}, {notes={7,16}, name="s-m"}, {notes={9,17}, name="l-f"}, {notes={11,19}, name="t-s"}
    } },
    [13.2] = { isStack = true, description = "dyads: 4ths & 5ths", units = { 
        {notes={0,5}, name="d-f"}, {notes={2,7}, name="r-s"}, {notes={4,9}, name="m-l"}, {notes={5,11}, name="f-t"}, {notes={7,12}, name="s-d"}, {notes={9,14}, name="l-r"}, {notes={11,16}, name="t-m"},
        {notes={0,7}, name="d-s"}, {notes={2,9}, name="r-l"}, {notes={4,11}, name="m-t"}, {notes={5,12}, name="f-d"}, {notes={7,14}, name="s-r"}, {notes={9,16}, name="l-m"}, {notes={11,17}, name="t-f"}
    } },
    [13.3] = { isStack = true, description = "dyads: 2nds & 7ths", units = { 
        {notes={0,2}, name="d-r"}, {notes={2,4}, name="r-m"}, {notes={4,5}, name="m-f"}, {notes={5,7}, name="f-s"}, {notes={7,9}, name="s-l"}, {notes={9,11}, name="l-t"}, {notes={11,12}, name="t-d"},
        {notes={0,11}, name="d-t"}, {notes={2,12}, name="r-d"}, {notes={4,14}, name="m-r"}, {notes={5,16}, name="f-m"}, {notes={7,17}, name="s-f"}, {notes={9,19}, name="l-s"}, {notes={11,21}, name="t-l"}
    } },
    [13.4] = { isStack = true, description = "all diatonic dyads", units = { 
        {notes={0,4}, name="d-m"}, {notes={0,7}, name="d-s"}, {notes={2,5}, name="r-f"}, {notes={4,7}, name="m-s"}, {notes={5,9}, name="f-l"}, {notes={7,11}, name="s-t"}, {notes={9,12}, name="l-d"}, {notes={11,14}, name="t-r"}, {notes={9,17}, name="l-f"}, {notes={7,16}, name="s-m"}, {notes={7,17}, name="s-f"}
    } },

    [14.1] = { isStack = true, description = "chromatic dyads: 3rds & 6ths", units = { {notes={0,3}, name="d-me"}, {notes={2,6}, name="r-fi"}, {notes={4,6}, name="m-fi"}, {notes={7,10}, name="s-te"}, {notes={11,15}, name="t-ri"}, {notes={8,15}, name="le-m"} } },
    [14.2] = { isStack = true, description = "chromatic dyads: 4ths & 5ths", units = { {notes={0,6}, name="d-fi"}, {notes={6,11}, name="fi-t"}, {notes={8,14}, name="le-r"}, {notes={10,16}, name="te-m"} } },
    [14.3] = { isStack = true, description = "all chromatic dyads", units = { {notes={0,3}, name="d-me"}, {notes={0,6}, name="d-fi"}, {notes={2,6}, name="r-fi"}, {notes={7,10}, name="s-te"}, {notes={8,12}, name="le-d"}, {notes={11,15}, name="t-ri"}, {notes={8,15}, name="le-m"} } },

    -- PHASE 4: 3-NOTE STACKS (TRIADS & CLUSTERS)
    [15.1] = { isStack = true, description = "major triads (root position)", units = { {notes={0,4,7}, name="i"}, {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"} } },
    [15.2] = { isStack = true, description = "minor triads (root position)", units = { {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, {notes={9,12,16}, name="vi"} } },
    [15.3] = { isStack = true, description = "all root triads", units = { {notes={0,4,7}, name="i"}, {notes={2,5,9}, name="ii"}, {notes={4,7,11}, name="iii"}, {notes={5,9,12}, name="iv"}, {notes={7,11,14}, name="v"}, {notes={9,12,16}, name="vi"}, {notes={11,14,17}, name="vii-o"} } },

    [16.1] = { isStack = true, description = "triads (1st inversion)", units = { {notes={4,7,12}, name="i-6"}, {notes={9,12,17}, name="iv-6"}, {notes={11,14,19}, name="v-6"} } },
    [16.2] = { isStack = true, description = "triads (2nd inversion)", units = { {notes={7,12,16}, name="i-64"}, {notes={12,17,21}, name="iv-64"}, {notes={14,19,23}, name="v-64"} } },
    [16.3] = { isStack = true, description = "all inverted triads", units = { {notes={4,7,12}, name="i-6"}, {notes={7,12,16}, name="i-64"}, {notes={9,12,17}, name="iv-6"}, {notes={12,17,21}, name="iv-64"}, {notes={11,14,19}, name="v-6"}, {notes={14,19,23}, name="v-64"} } },

    [17.1] = { isStack = true, description = "diminished triads", units = { {notes={11,14,17}, name="vii-o"}, {notes={2,5,8}, name="ii-o"} } },
    [17.2] = { isStack = true, description = "augmented triads", units = { {notes={4,8,12}, name="iii+"}, {notes={0,4,8}, name="i+"} } },
    [17.3] = { isStack = true, description = "diminished & augmented mix", units = { {notes={11,14,17}, name="vii-o"}, {notes={2,5,8}, name="ii-o"}, {notes={4,8,12}, name="iii+"}, {notes={0,4,8}, name="i+"} } },

    [18.1] = { isStack = true, description = "3-note open voicings (max maj 10th)", units = { {notes={0,7,16}, name="open-1"}, {notes={2,9,16}, name="open-2"}, {notes={5,12,21}, name="open-3"} } },

    -- PHASE 5: 4-NOTE STACKS (7TH CHORDS & CLUSTERS)
    [19.1] = { isStack = true, description = "dominant 7th chords", units = { 
        {notes={7,11,14,17}, name="v7"}, {notes={0,4,7,10}, name="v7/iv"}, {notes={2,6,9,12}, name="v7/v"}, 
        {notes={4,8,11,14}, name="v7/vi"}, {notes={11,14,17,19}, name="v7-65"}, {notes={14,17,19,23}, name="v7-43"} 
    } },
    [19.2] = { isStack = true, description = "major & minor 7th chords", units = { {notes={0,4,7,11}, name="i-maj7"}, {notes={5,9,12,16}, name="iv-maj7"}, {notes={2,5,9,12}, name="ii7"}, {notes={9,12,16,19}, name="vi7"} } },
    [19.3] = { isStack = true, description = "all 7th chords", units = { {notes={0,4,7,11}, name="i-maj7"}, {notes={2,5,9,12}, name="ii7"}, {notes={5,9,12,16}, name="iv-maj7"}, {notes={7,11,14,17}, name="v7"}, {notes={9,12,16,19}, name="vi7"} } },

    [20.1] = { isStack = true, description = "half-diminished 7th", units = { {notes={11,14,17,21}, name="vii-o7"} } },
    [20.2] = { isStack = true, description = "fully diminished 7th", units = { {notes={11,14,17,20}, name="dim7"} } },
    [20.3] = { isStack = true, description = "all diminished 7th types", units = { {notes={11,14,17,21}, name="vii-o7"}, {notes={11,14,17,20}, name="dim7"} } },

    [21.1] = { isStack = true, description = "4-note open voicings & clusters", units = { {notes={0,7,12,16}, name="stack-1"}, {notes={5,12,16,21}, name="stack-2"}, {notes={7,14,17,23}, name="stack-3"} } }
}

return m