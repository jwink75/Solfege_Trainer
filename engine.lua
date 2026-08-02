-- file: engine.lua
-- version: 10.40
-- status: fixed accidental chromaticism (le) caused by +4 shift logic

local M = {}

-- All values here are strictly diatonic (modulo 12: 0, 2, 4, 5, 7, 9, 11)
local diatonicPitches = {0, 2, 4, 5, 7, 9, 11, 12, 14, -1, -3, -5, -7, -8, -12, 16}
local chromaticPitches = {1, 3, 6, 8, 10}

local tendencyPairs = { 
    {notes = {11, 12}, id = "t-ti"}, 
    {notes = {5, 4},   id = "t-fa"}, 
    {notes = {2, 0},   id = "t-re"} 
}

local chromaticPairs2 = {
    {notes = {6, 7},   id = "t-fi-s"},
    {notes = {8, 7},   id = "t-le-s"},
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

    local prevPitch = context and context.prevNote
    local nextPitch = context and context.nextNote
    local isAug = context and context.isAugmented

    -- Determine melodic motion vector (ascending vs descending)
    local isAscending = false
    local isDescending = false

    if prevPitch and nextPitch then
        isAscending = (prevPitch < pitch) and (pitch <= nextPitch)
        isDescending = (prevPitch > pitch) and (pitch >= nextPitch)
    elseif nextPitch then
        isAscending = (pitch < nextPitch)
        isDescending = (pitch > nextPitch)
    elseif prevPitch then
        isAscending = (prevPitch < pitch)
        isDescending = (prevPitch > pitch)
    end

    if pc == 1 then
        -- ra (Db) vs di (C#)
        -- Prefer ra (minor 2nd from re) unless ascending step do -> di -> re
        if isAscending and prevPitch and (prevPitch % 12 == 0) then
            return "di"
        end
        return "ra"
    elseif pc == 3 then
        -- me (Eb) vs ri (D#)
        -- Prefer me (minor 2nd from mi) unless ascending step re -> ri -> mi
        if isAscending and prevPitch and (prevPitch % 12 == 2) then
            return "ri"
        end
        return "me"
    elseif pc == 6 then
        -- fi (F#) vs se (Gb)
        -- Prefer fi when resolving/ascending to sol, se when descending to fa/sol
        if isDescending or (nextPitch and (nextPitch % 12 == 5)) then
            return "se"
        end
        return "fi"
    elseif pc == 8 then
        -- le (Ab) vs si (G#)
        -- Explicit augmented triad context (e.g. do mi si)
        if isAug then return "si" end
        -- Avoid augmented prime (sol -> si); prefer minor 2nd (sol -> le)
        -- Prefer si ONLY when ascending step la -> si -> do
        if isAscending and prevPitch and (prevPitch % 12 == 9) then
            return "si"
        end
        return "le"
    elseif pc == 10 then
        -- te (Bb) vs li (A#)
        -- Prefer te (minor 2nd from ti/la) unless ascending step la -> li -> ti
        if isAscending and prevPitch and (prevPitch % 12 == 9) then
            return "li"
        end
        return "te"
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

        for i = 1, (levelData.rule.chromaticPairs2 or levelData.rule.chromaticTendencies or 0) do
            local selection
            local attempts = 0
            repeat
                selection = chromaticPairs2[math.random(#chromaticPairs2)]
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
        
        -- 2. Flatten and enforce Leap Limiter + Anti-Repetition + Octave Bounds (-8 to +16)
        local finalNotes = {}
        local nameStr = "proc-"
        local lastMIDI = nil 
        
        for _, b in ipairs(blocks) do
            for _, note in ipairs(b.notes) do
                local pitch = note
                
                -- Clamp initial pitch bounds relative to tonic
                while pitch > 16 do pitch = pitch - 12 end
                while pitch < -8 do pitch = pitch + 12 end
                
                if lastMIDI then
                    local attempts = 0
                    while (pitch == lastMIDI or math.abs(pitch - lastMIDI) > 12) and attempts < 15 do
                        if pitch == lastMIDI then
                            pitch = diatonicPitches[math.random(#diatonicPitches)]
                        else
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
        
        local isStack = levelData.isStack or (levelData.rule and levelData.rule.isStack)
        if isStack then table.sort(finalNotes) end
        return { notes = finalNotes, name = nameStr, isStack = isStack }
    end

    if levelData.units then
        local unit = levelData.units[math.random(#levelData.units)]
        if type(unit) == "number" then return { notes = {unit}, name = "id-" .. unit } end
        
        local notesCopy = {}
        for _, v in ipairs(unit.notes) do table.insert(notesCopy, v) end
        local isStack = levelData.isStack or unit.isStack
        if isStack then table.sort(notesCopy) end
        return { notes = notesCopy, name = unit.name or "unit", isStack = isStack }
    end
    
    return { notes = {0, 4, 7}, name = "fallback", isStack = levelData.isStack }
end

return M