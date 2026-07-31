-- level_manifesto.lua
local M = {}

M.levels = {
    [1] = { type = "melody", recipe = {"diatonic_tendency"} }, -- Single Unit (2-3 notes)
    [2] = { type = "melody", recipe = {"chromatic_tendency"} }, -- Single Unit (2-3 notes)
    [5] = { type = "melody", recipe = {"diatonic_tendency", "random_diatonic"}, targetNotes = 5 },
    [9] = { type = "stack", notes = 2, chromatics = 0 }
}

return M