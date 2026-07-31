-- File: definitions.lua
-- Version: 10.1
-- Status: Production - Bible v10.1 Corrected
-- Fix: Fixed resolution directions (ti-do resolve up) and typo

local M = {}

M.diatonic = {0, 2, 4, 5, 7, 9, 11}
M.stable_anchor_notes = {0, 4, 7}

M.tendencies = {
    level_1_1 = {
        { name = "d-s",   notes = {0, 7},      rhythms = {1.0, 2.0} },
        { name = "t-d",   notes = {-1, 0},     rhythms = {1.0, 2.0} }, -- Fixed typo 'rhythos'
        { name = "f-m",   notes = {5, 4},      rhythms = {1.0, 2.0} }
    },
    level_1_2 = {
        { name = "r-d",   notes = {2, 0},      rhythms = {1.0, 2.0} },
        { name = "l-s",   notes = {9, 7},      rhythms = {1.0, 2.0} }
    },
    level_1_3 = {
        { name = "m-r-d", notes = {4, 2, 0},   rhythms = {0.5, 0.5, 2.0} },
        { name = "s-l-s", notes = {7, 9, 7},   rhythms = {0.5, 0.5, 2.0} },
        { name = "f-s-l", notes = {5, 7, 9},   rhythms = {0.5, 0.5, 2.0} }
    }
}

M.single_diatonic = {
    unstable = { { name = "ti", notes = {11}, rhythms = {2.0} }, { name = "fa", notes = {5}, rhythms = {2.0} } },
    moderate = { { name = "re", notes = {2}, rhythms = {2.0} }, { name = "la", notes = {9}, rhythms = {2.0} } },
    stable =   { { name = "do", notes = {0}, rhythms = {2.0} }, { name = "mi", notes = {4}, rhythms = {2.0} }, { name = "sol", notes = {7}, rhythms = {2.0} } }
}

M.tendency_pairs = {
    { name = "t-d", notes = {11, 12}, rhythms = {1, 1} }, -- FIXED: Now resolves UP
    { name = "r-d", notes = {2, 0},   rhythms = {1, 1} }, -- Resolves down
    { name = "f-m", notes = {5, 4},   rhythms = {1, 1} }, -- Resolves down
    { name = "l-s", notes = {9, 7},   rhythms = {1, 1} }, -- Resolves down
    { name = "d-s", notes = {0, 7},   rhythms = {1, 1} }
}

M.stable_anchors = {
    { name = "do",  notes = {0}, rhythms = {1.0} },
    { name = "mi",  notes = {4}, rhythms = {1.0} },
    { name = "sol", notes = {7}, rhythms = {1.0} }
}

return M