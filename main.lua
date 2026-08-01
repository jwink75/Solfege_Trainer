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

local lastNotesKey = ""

local function generateNewExercise()
    local currentLevelData = progression.levels[currentLevel]
    if not currentLevelData then return end
    
    appState = "quiz" 
    local majorLevel = math.floor(currentLevel)
    isSingleInput = (majorLevel == 1 or majorLevel == 2 or majorLevel == 3)

    -- 1. build weighted cumulative pool (current level has 40% weight boost)
    local unlockedLevels = {}
    if currentLevelData.isCheckpoint then
        for i = 1, #levelList do
            local lv = levelList[i]
            if lv < currentLevel and not (progression.levels[lv] and progression.levels[lv].isCheckpoint) then
                table.insert(unlockedLevels, lv)
            end
        end
    else
        for i = 1, #levelList do
            local lv = levelList[i]
            if math.floor(lv) == majorLevel and lv <= currentLevel then
                table.insert(unlockedLevels, lv)
                if lv == currentLevel then
                    table.insert(unlockedLevels, lv)
                    table.insert(unlockedLevels, lv)
                end
            end
        end
    end

    -- 2. random selection from weighted pool
    local pick = unlockedLevels[math.random(#unlockedLevels)]
    local levelToUse = progression.levels[pick]
    print("exercise gen: level " .. pick .. " selected.")

    local newTonic, newMelody, melodyNotesKey
    local attempts = 0
    repeat
        attempts = attempts + 1
        newTonic = (lastTonic == -1 or math.random() > 0.5) and math.random(52, 64) or lastTonic
        newMelody = engine.generateMelody(levelToUse)
        melodyNotesKey = table.concat(newMelody.notes, ",")
    until not (newTonic == lastTonic and (newMelody.name == lastMelodyName or melodyNotesKey == lastNotesKey)) or attempts > 10

    activeItem = newMelody
    lastMelodyName = newMelody.name
    lastNotesKey = melodyNotesKey
    local forceCadence = (newTonic ~= lastTonic) or (currentLevel ~= lastLevel)
    lastTonic = newTonic
    lastLevel = currentLevel
    playback.engine.setTonic(newTonic)
    
    maxTargetNotes = isSingleInput and 1 or #activeItem.notes
    userAnswers = {}
    
    -- reset point caps
    currentSlotMax = {}
    for i = 1, maxTargetNotes do currentSlotMax[i] = 10 end

    -- Set adaptive keypad mode (sub-level relevant button filtering)
    ui.setKeypadMode(currentLevel)

    ui.updateStatus(currentLevel, currentLevelData.description or "")
    ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem.isStack, activeItem.notes, lastTonic)
    if activeItem.isStack then
        ui.showFeedback("enter notes from bottom up, submit with enter", "none")
    elseif not isSingleInput then 
        ui.showFeedback("enter notes, submit with enter", "none") 
    end
    if forceCadence then playFullSequence() else playQuestion(true) end
end

---------------------------------------------------------
-- 3. evaluation & input logic
---------------------------------------------------------

local notePitchMap = {
    d=0, r=2, m=4, f=5, s=7, l=9, t=11,
    ra=1, me=3, fi=6, le=8, te=10,
    di=1, ri=3, se=6, si=8, li=10
}

local tendencySyllableMap = {
    ["d-s"] = {"d", "s"},
    ["f-m"] = {"f", "m"},
    ["t-d"] = {"t", "d"},
    ["r-d"] = {"r", "d"},
    ["l-s"] = {"l", "s"},
    ["l-t-d"] = {"l", "t", "d"},
    ["m-r-d"] = {"m", "r", "d"},
    ["fi-s"] = {"fi", "s"},
    ["me-r-d"] = {"me", "r", "d"},
    ["le-s"] = {"le", "s"},
    ["te-d"] = {"te", "d"},
    ["ra-d"] = {"ra", "d"}
}

local evaluateSubmission

local function handleNoteInput(keyStr, mod)
    if not isAnsweringAllowed or appState ~= "quiz" or isSequencePlaying then return end
    mod = mod or 0

    -- Handle Single-Tap Tendency Action Buttons (Level 1 & Level 3)
    if tendencySyllableMap[keyStr] then
        userAnswers = {}
        local syls = tendencySyllableMap[keyStr]
        for _, syl in ipairs(syls) do
            local p = notePitchMap[syl] or 0
            table.insert(userAnswers, { pitch = (p + mod + 12) % 12, name = syl })
        end
        ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        evaluateSubmission()
        return
    end

    local pitchVal = notePitchMap[keyStr]
    if pitchVal ~= nil then
        local targetPitch = (pitchVal + mod + 12) % 12
        local nameStr = keyStr
        if mod == 1 then
            nameStr = engine.getNameFromInput(keyStr, 1)
        elseif mod == -1 then
            nameStr = engine.getNameFromInput(keyStr, -1)
        end
        if #userAnswers < maxTargetNotes then
            table.insert(userAnswers, { pitch = targetPitch, name = nameStr })
            ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
            if isSingleInput then evaluateSubmission() end
        end
    end
end

local shortSyllableMap = {
    d = "do", r = "re", m = "mi", f = "fa", s = "sol", l = "la", t = "ti",
    fi = "fi", me = "me", le = "le", te = "te", ra = "ra"
}

local function isNameEquivalent(uName, pName)
    if not uName or not pName then return false end
    uName = uName:lower()
    pName = pName:lower()
    if uName == pName then return true end
    if shortSyllableMap[uName] and shortSyllableMap[uName] == pName then
        return true
    end
    return false
end

evaluateSubmission = function()
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
        local isAug = (activeItem.name and string.find(activeItem.name, "+") ~= nil) or 
                      (progression.levels[currentLevel] and progression.levels[currentLevel].description and string.find(progression.levels[currentLevel].description, "augmented") ~= nil)
        
        for i = 1, maxTargetNotes do
            local targetPitch = (activeItem.notes[i] % 12 + 12) % 12
            local context = { prevNote = activeItem.notes[i-1], nextNote = activeItem.notes[i+1], isAugmented = isAug }
            local preferred = engine.getPreferredName(targetPitch, context)
            local userEntry = userAnswers[i]
            
            if userEntry and (userEntry.pitch % 12 + 12) % 12 == targetPitch then
                local isMatch = isNameEquivalent(userEntry.name, preferred)
                local slotPoints = isMatch and currentSlotMax[i] or math.max(0, currentSlotMax[i] - 1)
                turnScore = turnScore + slotPoints
                table.insert(displayResults, { 
                    name = preferred, 
                    color = isMatch and "correct" or "correction" 
                })
            else
                table.insert(displayResults, { name = preferred, color = "wrong" })
            end
        end

        sessionScore = sessionScore + turnScore
        ui.updateSessionScore(sessionScore)

        if (majorLevel == 1 or majorLevel == 3) and not forceReveal then
            displayResults = {}
            for i = 1, #activeItem.notes do
                local p = (activeItem.notes[i] % 12 + 12) % 12
                local n = engine.getPreferredName(p, { prevNote = activeItem.notes[i-1], nextNote = activeItem.notes[i+1], isAugmented = isAug })
                local color = (i == 1 and not isNameEquivalent(userAnswers[1].name, n)) and "correction" or "correct"
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
        
        ui.updateAnswerBufferFromResults(displayResults, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        appState = "result"
        timer.performWithDelay(forceReveal and 2500 or 1500, function() 
            if appState == "result" then generateNewExercise() end 
        end)
    else
        -- c. try again loop
        ui.showFeedback("try again!", "wrong")
        userAnswers = {}
        ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        isAnsweringAllowed = true
    end
end

---------------------------------------------------------
-- 4. input
---------------------------------------------------------

local function onKeyEvent(event)
    if event.phase ~= "down" then return false end
    local key = string.lower(event.keyName or "")
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
    
    local isArrow = (key == "up" or key == "right" or key == "down" or key == "left")
    if isArrow then
        globalPanic()
        isSequencePlaying = false
        if event.isShiftDown then
            local currentMajor = math.floor(currentLevel)
            local targetMajor = (key == "up" or key == "right") and (currentMajor + 1) or (currentMajor - 1)
            local newIdx = levelIndex
            if key == "up" or key == "right" then
                for i = levelIndex + 1, #levelList do
                    if math.floor(levelList[i]) >= targetMajor then
                        newIdx = i; break
                    end
                end
            else
                for i = levelIndex - 1, 1, -1 do
                    if math.floor(levelList[i]) <= targetMajor then
                        newIdx = i; break
                    end
                end
            end
            levelIndex = newIdx
        else
            if key == "up" or key == "right" then 
                levelIndex = math.min(#levelList, levelIndex + 1)
            else 
                levelIndex = math.max(1, levelIndex - 1) 
            end
        end
        currentLevel = levelList[levelIndex]
        ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "")
        if appState ~= "menu" then
            generateNewExercise()
        end
        return true
    end

    if isSequencePlaying then return true end

    if appState == "menu" then
        if key == "enter" or key == "return" then generateNewExercise() end
        return true
    end
    
    local isDeleteKey = (key == "backspace" or key == "delete" or key == "deleteback")
    if isDeleteKey and isAnsweringAllowed and appState == "quiz" then
        if #userAnswers > 0 then
            table.remove(userAnswers)
            ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes)
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
    elseif key == "c" or key == "k" then playFullSequence(); return true
    elseif key == "q" then playQuestion(false); return true
    end
    
    if notePitchMap[key] and isAnsweringAllowed then
        local mod = event.isShiftDown and 1 or ((event.isAltDown or event.isCommandDown) and -1 or 0)
        handleNoteInput(key, mod)
        return true
    end
    return false
end
    local levelList = progression.levelOrder
    local levelIndex = 1
    for i, lvl in ipairs(levelList) do
        if lvl == currentLevel then levelIndex = i; break end
    end
    levelIndex = math.max(1, levelIndex - 1)
    currentLevel = levelList[levelIndex]
    ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "")
    if appState ~= "menu" then
        generateNewExercise()
    end
end

local function nextLevel()
    local levelList = progression.levelOrder
    local levelIndex = 1
    for i, lvl in ipairs(levelList) do
        if lvl == currentLevel then levelIndex = i; break end
    end
    levelIndex = math.min(#levelList, levelIndex + 1)
    currentLevel = levelList[levelIndex]
    ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "")
    if appState ~= "menu" then
        generateNewExercise()
    end
end

ui.init(
    function(touchKeyId)
        handleNoteInput(touchKeyId, 0)
    end,
    {
        onPrevLevel = prevLevel,
        onNextLevel = nextLevel,
        onCadence = function() playFullSequence() end,
        onReplay = function() playQuestion(false) end,
        onPrimaryAction = function()
            if isSequencePlaying then return end
            if appState == "menu" or appState == "result" then
                generateNewExercise()
            elseif appState == "quiz" and not isSingleInput then
                if #userAnswers == maxTargetNotes then evaluateSubmission() end
            end
        end
    }
)

Runtime:addEventListener("key", onKeyEvent)
ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "select level")