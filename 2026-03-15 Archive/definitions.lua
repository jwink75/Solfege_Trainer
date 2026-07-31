-- definitions.lua
local M = {}

M.diatonic = {0, 2, 4, 5, 7, 9, 11}
M.chromatic = {1, 3, 6, 8, 10}

M.tendencies = {
    diatonic = {
        { name = "d-s",   notes = {0, 7},       rhythm = {1, 1},       key = "d" },
        { name = "f-m",   notes = {5, 4},       rhythm = {1, 1},       key = "f" },
        { name = "t-d",   notes = {-1, 0},      rhythm = {1, 1},       key = "t" },
        { name = "r-d",   notes = {2, 0},       rhythm = {1, 1},       key = "r" },
        { name = "l-s",   notes = {9, 7},       rhythm = {1, 1},       key = "l" },
        { name = "l-t-d", notes = {-3, -1, 0},  rhythm = {0.5, 0.5, 1}, key = "l" },
        { name = "m-r-d", notes = {4, 2, 0},    rhythm = {0.5, 0.5, 1}, key = "m" }
    },
    chromatic = {
        { name = "fi-s",  notes = {6, 7},       rhythm = {1, 1},       key = "f" },
        { name = "le-s",  notes = {8, 7},       rhythm = {1, 1},       key = "l" },
        { name = "me-r-d",notes = {3, 2, 0},    rhythm = {0.5, 0.5, 1}, key = "m" },
        { name = "te-d",  notes = {-2, 0},      rhythm = {1, 1},       key = "t" },
        { name = "ra-d",  notes = {1, 0},       rhythm = {1, 1},       key = "r" }
    }
}

return M -- CRITICAL: Must return the table