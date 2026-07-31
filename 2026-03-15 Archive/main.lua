-- main.lua
local playback = require("playback")
local builder = require("builder")
local manifesto = require("level_manifesto")

playback.engine.init("piano_")
playback.engine.setTonic(60)

local currentLevel = 1
local activeItem = nil
local isRunning = false
local timers = {}
local activeVids = {} 

local feedback = display.newText({
    text = "Level " .. currentLevel .. " Ready", 
    x = display.contentCenterX, y = 200, 
    font = native.systemFontBold, fontSize = 30, align = "center"
})

local function playLegato(notes, volume)
    for i=#activeVids, 1, -1 do playback.voice.off(activeVids[i]) end
    activeVids = {}
    if type(notes) == "table" then
        for _, n in ipairs(notes) do
            local vid = playback.voice.on(n, volume or 0.8)
            if vid then table.insert(activeVids, vid) end
        end
    else
        local vid = playback.voice.on(notes, volume or 0.8)
        if vid then table.insert(activeVids, vid) end
    end
end

local function stop()
    for i=#timers, 1, -1 do timer.cancel(timers[i]) end
    timers = {}
    for i=#activeVids, 1, -1 do playback.voice.off(activeVids[i]) end
    activeVids = {}
    playback.voice.panic()
    isRunning = false
end

local function playItem()
    stop()
    isRunning = true
    
    local levelData = manifesto.levels[currentLevel]
    if not levelData then return end

    local t = playback.engine.getTonic()
    local beat = 800

    -- 1. Assemble Content
    if levelData.type == "melody" then
        -- Force standard rhythm only for composite levels (5)
        local forceStandard = (currentLevel >= 5)
        activeItem = builder.generateMelody(levelData.recipe, forceStandard, levelData.targetNotes)
    else
        activeItem = builder.generateStack(levelData.notes, levelData.chromatics)
    end
    
    -- 2. Cadence (I-IV-V-I with Bass)
    local cadence = {
        { notes = {t-12, t, t+4, t+7, t+12},   dur = beat },
        { notes = {t-7, t, t+5, t+9, t+12},    dur = beat },
        { notes = {t-5, t-1, t+2, t+7, t+11},  dur = beat },
        { notes = {t-12, t, t+4, t+7, t+12},   dur = beat * 2 }
    }

    local currentTimeline = 0
    for i, chord in ipairs(cadence) do
        local ct = timer.performWithDelay(currentTimeline, function()
            playLegato(chord.notes, 0.5)
        end)
        table.insert(timers, ct)
        currentTimeline = currentTimeline + chord.dur
    end

    local exerciseStartTime = currentTimeline + 1600
    
    -- 3. Exercise Playback
    if levelData.type == "stack" then
        local sTimer = timer.performWithDelay(exerciseStartTime, function()
            local corrected = {}
            for i=1, #activeItem.notes do table.insert(corrected, t + activeItem.notes[i]) end
            playLegato(corrected, 0.8)
            table.insert(timers, timer.performWithDelay(5000, stop))
        end)
        table.insert(timers, sTimer)
    else
        local playTime = exerciseStartTime
        for i=1, #activeItem.notes do
            local nTimer = timer.performWithDelay(playTime, function()
                playLegato(t + activeItem.notes[i], 0.8)
                
                if i == #activeItem.notes then
                    -- 5s ring for single units (L1, L2), 1.5s for melodies (L5)
                    local ring = (#activeItem.notes <= 3) and 5000 or 1500
                    table.insert(timers, timer.performWithDelay(ring, stop))
                end
            end)
            table.insert(timers, nTimer)
            playTime = playTime + (activeItem.rhythms[i] * beat)
        end
    end
end

Runtime:addEventListener("key", function(event)
    if event.phase == "down" then
        local n = tonumber(event.keyName)
        if n and manifesto.levels[n] then 
            currentLevel = n 
            feedback.text = "Level " .. n .. " Ready"
            stop()
        elseif event.keyName == "space" then 
            playItem() 
        end
    end
end)