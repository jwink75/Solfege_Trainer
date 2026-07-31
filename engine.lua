-- file: engine.lua
-- version: 10.40
-- status: fixed accidental chromaticism (le) caused by +4 shift logic

local M = {}

-- All values here are strictly diatonic (modulo 12: 0, 2, 4, 5, 7, 9, 11)
local diatonicPitches = {0, 2, 4, 5, 7, 9, 11, 12, 14, -1, -3, -5, -8, -12, 16, 17, 19}
local chromaticPitches = {1, 3, 6, 8, 10}

local tendencyPairs = { 
    {notes = {11, 12}, id = "t-ti"}, 
    {notes = {5, 4},   id = "t-fa"}, 
    {notes = {2, 0},   id = "t-re"} 
}

local chromaticTendencyPairs = {
    {notes = {6, 7},   id = "t-fi-s"},
    {notes = {8, 7},   id = "t-le-s"},
    {notes = {3, 2, 0}, id = "t-me-r-d"},
    {notes = {10, 12}, id = "t-te-d"},
    {notes = {1, 0},   id = "t-ra-d"}
}

local chromaticMap = {
    d = { [-1] = "ti",  [0] = "do",  [1] = "di" },
    r = { [-1] = "ra",  [0] = "re",  [1] = "ri" },
    m = { [-1] = "me",  [0] = "mi",  [1] = "fa" },
    f = { [-1] = "mi",  [0] = "fa",  [1] = "fi" },
    s = { [-1] = "se",  [0] = "sol", [1] = "si" },
    l = { [-1] = "le",  [0] = "la",  [1] = "li" },
    t = { [-1] = "te",  [0] = "ti",  [1] = "do" }
}

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function M.getNameFromInput(key, mod)
    if chromaticMap[key] then
        return chromaticMap[key][mod] or "???"
    end
    return "???"
end

function M.getPreferredName(pitch, context)
    local pc = (pitch % 12 + 12) % 12
    local diatonicMap = { [0]="do", [2]="re", [4]="mi", [5]="fa", [7]="sol", [9]="la", [11]="ti" }
    if diatonicMap[pc] then return diatonicMap[pc] end

    local nextPitch = context and context.nextNote
    local isUpward = nextPitch and (nextPitch > pitch)
    local isDownward = nextPitch and (nextPitch < pitch)

    if pc == 1 then
        return isUpward and "di" or "ra"
    elseif pc == 3 then
        return isUpward and "ri" or "me"
    elseif pc == 6 then
        return isDownward and "se" or "fi"
    elseif pc == 8 then
        return isUpward and "si" or "le"
    elseif pc == 10 then
        return isUpward and "li" or "te"
    end

    return "???"
end

function M.generateMelody(levelData)
    local mode = "units"
    if levelData.units and levelData.rule then
        mode = (math.random() > 0.3) and "rule" or "units"
    elseif levelData.rule then
        mode = "rule"
    end

    if mode == "rule" then
        local blocks = {}
        local lastID = ""

        -- 1. Create blocks with block-repetition guard
        for i = 1, (levelData.rule.tendencies or 0) do
            local selection
            local attempts = 0
            repeat
                selection = tendencyPairs[math.random(#tendencyPairs)]
                attempts = attempts + 1
            until selection.id ~= lastID or attempts > 10
            
            table.insert(blocks, { notes = selection.notes, id = selection.id })
            lastID = selection.id
        end

        for i = 1, (levelData.rule.chromaticTendencies or 0) do
            local selection
            local attempts = 0
            repeat
                selection = chromaticTendencyPairs[math.random(#chromaticTendencyPairs)]
                attempts = attempts + 1
            until selection.id ~= lastID or attempts > 10
            
            table.insert(blocks, { notes = selection.notes, id = selection.id })
            lastID = selection.id
        end

        for i = 1, (levelData.rule.chromatics or 0) do
            local p
            local attempts = 0
            repeat
                p = chromaticPitches[math.random(#chromaticPitches)]
                attempts = attempts + 1
            until "c-"..p ~= lastID or attempts > 10
            
            table.insert(blocks, { notes = {p}, id = "c-"..p })
            lastID = "c-"..p
        end

        for i = 1, (levelData.rule.randoms or 0) do
            local p
            local attempts = 0
            repeat
                p = diatonicPitches[math.random(#diatonicPitches)]
                attempts = attempts + 1
            until "r-"..p ~= lastID or attempts > 10
            
            table.insert(blocks, { notes = {p}, id = "r-"..p })
            lastID = "r-"..p
        end
        
        if #blocks > 2 then shuffle(blocks) end
        
        -- 2. Flatten and enforce Leap Limiter + Anti-Repetition
        local finalNotes = {}
        local nameStr = "proc-"
        local lastMIDI = nil 
        
        for _, b in ipairs(blocks) do
            for _, note in ipairs(b.notes) do
                local pitch = note
                
                if lastMIDI then
                    local attempts = 0
                    -- LOOP: Continue adjusting until the note is NOT a duplicate 
                    -- AND the leap is within one octave (12 semitones).
                    while (pitch == lastMIDI or math.abs(pitch - lastMIDI) > 12) and attempts < 15 do
                        if pitch == lastMIDI then
                            -- It's a duplicate. Re-roll.
                            if levelData.rule.chromatics and math.random() > 0.5 then
                                pitch = chromaticPitches[math.random(#chromaticPitches)]
                            else
                                pitch = diatonicPitches[math.random(#diatonicPitches)]
                            end
                        else
                            -- It's a giant leap. Move it by octaves.
                            pitch = (pitch > lastMIDI) and (pitch - 12) or (pitch + 12)
                        end
                        attempts = attempts + 1
                    end
                end
                
                table.insert(finalNotes, pitch)
                nameStr = nameStr .. pitch .. "-"
                lastMIDI = pitch
            end
        end
        
        return { notes = finalNotes, name = nameStr }
    end

    if levelData.units then
        local unit = levelData.units[math.random(#levelData.units)]
        if type(unit) == "number" then return { notes = {unit}, name = "id-" .. unit } end
        return unit
    end
    
    return { notes = {0, 4, 7}, name = "fallback" }
end

return M