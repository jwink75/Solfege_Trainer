-- file: progression.lua
-- version: 12.9
-- status: expanded level 4 (root vs inversions) + full diatonic triads

local m = {}

m.levels = {
    [1.1] = { description = "diatonic tendency pairs", units = { {notes={0,7}, name="d-s"}, {notes={11,12}, name="t-d"}, {notes={5,4}, name="f-m"} } },
    [1.2] = { description = "diatonic stepwise down", units = { {notes={2,0}, name="r-d"}, {notes={9,7}, name="l-s"} } },
    [1.3] = { description = "3-note diatonic resolution", units = { {notes={4,2,0}, name="m-r-d"}, {notes={9,11,12}, name="l-t-d"} } },

    [2.1] = { description = "id: t and f", units = { 11, 5 } },
    [2.2] = { description = "id: r and l", units = { 2, 9 } },
    [2.3] = { description = "id: d, m, s", units = { 0, 4, 7 } },

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
    [9.2] = { description = "2-note diatonic + chromatic mix", rule = { tendencies = 1, chromatics = 1 } },
    [9.3] = { description = "2-note random chromatic", rule = { chromatics = 2 } },

    -- LEVEL 10: 3-NOTE CHROMATIC MELODIES
    [10.1] = { description = "3-note chromatic pathway + random", rule = { chromaticTendencies = 1, randoms = 1 } },
    [10.2] = { description = "3-note diatonic/chromatic mix", rule = { tendencies = 1, chromatics = 1, randoms = 1 } },
    [10.3] = { description = "3-note chromatic random", rule = { chromatics = 3 } },
    [10.4] = { description = "3-note chromatic boss", rule = { chromaticTendencies = 1, chromatics = 2 } },

    -- LEVEL 11: 4-NOTE CHROMATIC MELODIES
    [11.1] = { description = "4-note: 1 chromatic pair + diatonic pair", rule = { chromaticTendencies = 1, tendencies = 1 } },
    [11.2] = { description = "4-note: chromatic pair + 2 random", rule = { chromaticTendencies = 1, randoms = 2 } },
    [11.3] = { description = "4-note chromatic boss", rule = { chromaticTendencies = 1, chromatics = 3 } },

    -- LEVEL 12: 5-NOTE CHROMATIC MELODIES
    [12.1] = { description = "5-note: chromatic pair + diatonic pair + 1 random", rule = { chromaticTendencies = 1, tendencies = 1, randoms = 1 } },
    [12.2] = { description = "5-note: 1 chromatic pair + 3 random", rule = { chromaticTendencies = 1, randoms = 3 } },
    [12.3] = { description = "5-note: 2 chromatic pairs + 1 random", rule = { chromaticTendencies = 2, randoms = 1 } },
    [12.4] = { description = "5-note chromatic boss", rule = { chromaticTendencies = 1, chromatics = 4 } }
}

return m