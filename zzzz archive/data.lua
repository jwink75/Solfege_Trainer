-- data.lua
-- Solfège Trainer: Level & Sequence Definitions
local data = {
    version = "1.1.0",
    last_updated = "2026-03-17",
    
    -- Level indexing uses the decimal system (e.g., [1.1])
    level_definitions = {
        [1.1] = {
            name = "introductory tendencies",
            sequences = {
                { semitones = {0, 7}, solfege = {"do", "sol"} },
                { semitones = {11, 0}, solfege = {"ti", "do"} },
                { semitones = {5, 4}, solfege = {"fa", "mi"} }
            }
        },
        [1.2] = {
            name = "extended tendencies",
            sequences = {
                { semitones = {2, 0}, solfege = {"re", "do"} },
                { semitones = {9, 7}, solfege = {"la", "sol"} }
            }
        },
        [1.3] = {
            name = "three-note progressions",
            sequences = {
                { semitones = {4, 2, 0}, solfege = {"mi", "re", "do"} },
                { semitones = {9, 11, 0}, solfege = {"la", "ti", "do"} }
            }
        }
    }
}

return data