-- builder.lua
local defs = require("definitions")
local M = {}

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function M.generateMelody(recipe, forceStandardRhythm, targetNotes)
    local melody = { notes = {}, rhythms = {}, keys = {}, names = {}, answerKey = "" }
    local pool = {}

    -- Build the unit pool from the recipe definitions
    for _, unitType in ipairs(recipe) do
        if unitType == "diatonic_tendency" then
            for _, tnd in ipairs(defs.tendencies.diatonic) do table.insert(pool, tnd) end
        elseif unitType == "chromatic_tendency" then
            -- FIXED: Correctly accessing the chromatic sub-table
            for _, tnd in ipairs(defs.tendencies.chromatic) do table.insert(pool, tnd) end
        elseif unitType == "random_diatonic" then
            for _, note in ipairs(defs.diatonic) do
                table.insert(pool, { notes = {note}, rhythm = {1}, name = "none", key = "none" })
            end
        end
    end

    local selectedUnits = {}
    
    if targetNotes then
        -- Hunt for a combination that hits the exact note count
        for i=1, 100 do
            shuffle(pool)
            local trialUnits = {}
            local trialCount = 0
            for j=1, #pool do
                if trialCount + #pool[j].notes <= targetNotes then
                    table.insert(trialUnits, pool[j])
                    trialCount = trialCount + #pool[j].notes
                end
                if trialCount == targetNotes then break end
            end
            if trialCount == targetNotes then
                selectedUnits = trialUnits
                break
            end
        end
    else
        -- Fallback: Just grab one unit
        shuffle(pool)
        table.insert(selectedUnits, pool[1])
    end

    -- Safety: if pool was empty or search failed, don't crash
    if #selectedUnits == 0 and #pool > 0 then table.insert(selectedUnits, pool[1]) end

    local lastPitchClass = nil
    for _, comp in ipairs(selectedUnits) do
        for i=1, #comp.notes do
            local currentNote = comp.notes[i]
            local currentPitchClass = currentNote % 12
            
            if currentPitchClass == lastPitchClass then
                currentNote = currentNote + 2
                currentPitchClass = currentNote % 12
            end

            table.insert(melody.notes, currentNote)
            table.insert(melody.rhythms, forceStandardRhythm and 1 or comp.rhythm[i])
            lastPitchClass = currentPitchClass
        end
        if melody.answerKey == "" and comp.key ~= "none" then 
            melody.answerKey = comp.key 
        end
    end
    return melody
end

-- M.generateStack remains the same (audited/safe)
function M.generateStack(numNotes, maxChromatics)
    local stack = { notes = { math.random(0, 11) }, rhythms = {1} }
    for i = 2, numNotes do
        for attempt = 1, 20 do
            local nextNote = stack.notes[#stack.notes] + math.random(1, 11)
            local pc = nextNote % 12
            local rangeOk = (nextNote - stack.notes[1]) <= 16
            local dupOk = true
            for _, v in ipairs(stack.notes) do if (v % 12) == pc then dupOk = false break end end
            if rangeOk and dupOk then
                table.insert(stack.notes, nextNote)
                table.insert(stack.rhythms, 1)
                break
            end
        end
    end
    return stack
end

return M