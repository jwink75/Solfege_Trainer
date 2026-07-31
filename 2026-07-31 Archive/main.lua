-- file: main.lua
-- version: 13.35
-- status: full feature integration (rng seed, backspace, balanced cumulative, partial credit)

local playback = require("playback")
local engine = require("engine")
local progression = require("progression")
local ui = require("ui")

-- seed rng so every session is unique
math.randomseed(os.time())

---------------------------------------------------------
-- 1. initialization & state
---------------------------------------------------------
playback.engine.init("piano_")
ui.init()

local levelList = {}
for k, _ in pairs(progression.levels) do table.insert(levelList, k) end
table.sort(levelList)

local levelIndex = 1
local currentLevel = levelList[levelIndex]
local lastLevel = nil
local appState = "menu" 
local isSequencePlaying = false 
local activeItem = nil
local userAnswers = {} 
local maxTargetNotes = 0
local sessionScore = 0
local currentSlotMax = {} -- tracks 10 -> 8 -> 6 -> 4 -> 2 -> 0 per note
local isAnsweringAllowed = false
local isSingleInput = false 
local baseDuration = 800 
local lastTonic = -1
local lastMelodyName = ""
local mainTimers = {}

ui.updateSessionScore(0)

---------------------------------------------------------
-- 2. core logic
---------------------------------------------------------

local function globalPanic()
    isAnsweringAllowed = false
    isSequencePlaying = false
    for i = #mainTimers, 1, -1 do
        if mainTimers[i] then timer.cancel(mainTimers[i]) end
        table.remove(mainTimers, i)
    end
    playback.voice.panic()
end

local function playQuestion(useBreath)
    if not useBreath then globalPanic() end 
    isSequencePlaying = true
    local delay = useBreath and (baseDuration * 1.0) or 100
    local qTimer = timer.performWithDelay(delay, function()
        ui.showFeedback("your turn...", "none")
        playback.engine.playMelody(activeItem)
        isAnsweringAllowed = true
        isSequencePlaying = false 
    end)
    table.insert(mainTimers, qTimer)
end

local function playFullSequence()
    globalPanic()
    isSequencePlaying = true
    ui.showFeedback("listening...", "none")
    playback.engine.playCadence()
    local seqTimer = timer.performWithDelay(baseDuration * 5.2, function()
        playQuestion(true)
    end)
    table.insert(mainTimers, seqTimer)
end

local function generateNewExercise()
    local currentLevelData = progression.levels[currentLevel]
    if not currentLevelData then return end
    
    appState = "quiz" 
    local majorLevel = math.floor(currentLevel)
    isSingleInput = (majorLevel == 1 or majorLevel == 2 or majorLevel == 7)

    -- 1. build cumulative pool (all unlocked levels in this major group)
    local unlockedLevels = {}
    for i = 1, #levelList do
        local lv = levelList[i]
        if math.floor(lv) == majorLevel and lv <= currentLevel then
            table.insert(unlockedLevels, lv)
        end
    end

    -- 2. flat random selection: every level has an equal shot
    local pick = unlockedLevels[math.random(#unlockedLevels)]
    local levelToUse = progression.levels[pick]
    print("exercise gen: level " .. pick .. " selected.")

    local newTonic, newMelody
    local attempts = 0
    repeat
        attempts = attempts + 1
        newTonic = (lastTonic == -1 or math.random() > 0.5) and math.random(52, 64) or lastTonic
        newMelody = engine.generateMelody(levelToUse)
    until not (newTonic == lastTonic and newMelody.name == lastMelodyName) or attempts > 10

    activeItem = newMelody
    lastMelodyName = newMelody.name
    local forceCadence = (newTonic ~= lastTonic) or (currentLevel ~= lastLevel)
    lastTonic = newTonic
    lastLevel = currentLevel
    playback.engine.setTonic(newTonic)
    
    maxTargetNotes = isSingleInput and 1 or #activeItem.notes
    userAnswers = {}
    
    -- reset point caps
    currentSlotMax = {}
    for i = 1, maxTargetNotes do currentSlotMax[i] = 10 end

    ui.updateStatus(currentLevel, currentLevelData.description or "")
    ui.updateAnswerBuffer({}, maxTargetNotes, isSingleInput)
    if forceCadence then playFullSequence() else playQuestion(true) end
end

---------------------------------------------------------
-- 3. evaluation
---------------------------------------------------------

local function evaluateSubmission()
    isAnsweringAllowed = false
    local turnScore = 0
    local displayResults = {}
    local isPitchError = false
    local forceReveal = false
    local majorLevel = math.floor(currentLevel)
    local maxPossible = maxTargetNotes * 10
    
    -- a. decay and reveal check
    for i = 1, maxTargetNotes do
        local targetPitch = (activeItem.notes[i] % 12 + 12) % 12
        local userEntry = userAnswers[i]
        local isNoteCorrect = false
        if userEntry and (userEntry.pitch % 12 + 12) % 12 == targetPitch then isNoteCorrect = true end

        if not isNoteCorrect then
            isPitchError = true
            currentSlotMax[i] = currentSlotMax[i] - 2 
            if currentSlotMax[i] <= 0 then forceReveal = true end
        end
    end

    -- b. process final state
    if not isPitchError or forceReveal then
        for i = 1, maxTargetNotes do
            local targetPitch = (activeItem.notes[i] % 12 + 12) % 12
            local context = { nextNote = activeItem.notes[i+1] }
            local preferred = engine.getPreferredName(targetPitch, context)
            local userEntry = userAnswers[i]
            
            if userEntry and (userEntry.pitch % 12 + 12) % 12 == targetPitch then
                local slotPoints = (userEntry.name == preferred) and currentSlotMax[i] or math.max(0, currentSlotMax[i] - 1)
                turnScore = turnScore + slotPoints
                table.insert(displayResults, { 
                    name = preferred, 
                    color = (userEntry.name == preferred) and "correct" or "correction" 
                })
            else
                table.insert(displayResults, { name = preferred, color = "wrong" })
            end
        end

        sessionScore = sessionScore + turnScore
        ui.updateSessionScore(sessionScore)

        if majorLevel == 1 and not forceReveal then
            displayResults = {}
            for i = 1, #activeItem.notes do
                local p = (activeItem.notes[i] % 12 + 12) % 12
                local n = engine.getPreferredName(p, { nextNote = activeItem.notes[i+1] })
                local color = (i == 1 and userAnswers[1].name ~= n) and "correction" or "correct"
                table.insert(displayResults, { name = n, color = color })
            end
        end

        local scoreString = turnScore .. " / " .. maxPossible
        if forceReveal then
            ui.showFeedback("sorry! the answer was:\n" .. scoreString, "wrong")
        else
            local header = (turnScore < maxPossible) and "correct" or "correct!"
            ui.showFeedback(header .. "\n" .. scoreString, (turnScore < maxPossible) and "correction" or "correct")
        end
        
        ui.updateAnswerBufferFromResults(displayResults)
        appState = "result"
        timer.performWithDelay(forceReveal and 2500 or 1500, function() 
            if appState == "result" then generateNewExercise() end 
        end)
    else
        -- c. try again loop
        ui.showFeedback("try again!", "wrong")
        userAnswers = {}
        ui.updateAnswerBuffer({}, maxTargetNotes, isSingleInput)
        isAnsweringAllowed = true
    end
end

---------------------------------------------------------
-- 4. input
---------------------------------------------------------

local function onKeyEvent(event)
    if event.phase ~= "down" then return false end
    local key = event.keyName
    if isSequencePlaying and key ~= "escape" then return true end
    
    if key == "0" then 
        sessionScore = 0
        ui.updateSessionScore(sessionScore)
        return true 
    end

    if key == "escape" then
        globalPanic(); appState = "menu"
        ui.updateStatus(currentLevel, progression.levels[currentLevel].description or "")
        ui.showFeedback("press enter to start", "none")
        return true
    end
    
    if appState == "menu" then
        if key == "up" or key == "right" then levelIndex = math.min(#levelList, levelIndex + 1)
        elseif key == "down" or key == "left" then levelIndex = math.max(1, levelIndex - 1) end
        currentLevel = levelList[levelIndex]
        ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "")
        if key == "enter" or key == "return" then generateNewExercise() end
        return true
    end
    
    local isDeleteKey = (key == "backspace" or key == "delete" or key == "deleteBack")
    if isDeleteKey and isAnsweringAllowed and appState == "quiz" then
        if #userAnswers > 0 then
            table.remove(userAnswers)
            local displayNames = {}
            for _, v in ipairs(userAnswers) do table.insert(displayNames, v.name) end
            ui.updateAnswerBuffer(displayNames, maxTargetNotes, isSingleInput)
        end
        return true
    end

    if key == "enter" or key == "return" then
        if appState == "result" then 
            generateNewExercise()
        elseif appState == "quiz" and not isSingleInput then
            if #userAnswers == maxTargetNotes then evaluateSubmission() end
        end
        return true
    elseif key == "c" then playFullSequence(); return true
    elseif key == "q" then playQuestion(false); return true
    end
    
    local homeRow = {d=0, r=2, m=4, f=5, s=7, l=9, t=11}
    if homeRow[key] and isAnsweringAllowed then
        local mod = event.isShiftDown and 1 or ((event.isAltDown or event.isCommandDown) and -1 or 0)
        if #userAnswers < maxTargetNotes then
            table.insert(userAnswers, { pitch = (homeRow[key] + mod + 12) % 12, name = engine.getNameFromInput(key, mod) })
            local displayNames = {}
            for _, v in ipairs(userAnswers) do table.insert(displayNames, v.name) end
            ui.updateAnswerBuffer(displayNames, maxTargetNotes, isSingleInput)
            if isSingleInput then evaluateSubmission() end
        end
        return true
    end
    return false
end

Runtime:addEventListener("key", onKeyEvent)
ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "select level")