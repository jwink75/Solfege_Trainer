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

    [7.0] = { description = "test: chromatic tendencies", units = { {notes={1, 0}, name="ra-d"}, {notes={6, 7}, name="fi-s"} } }
}

return m