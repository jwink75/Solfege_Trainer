-- file: main.lua
-- version: 13.35
-- status: full feature integration (rng seed, backspace, balanced cumulative, partial credit)

local playback = require("playback")
local engine = require("engine")
local progression = require("progression")
local ui = require("ui")
local stats = require("stats")
stats.init()

-- seed rng so every session is unique
math.randomseed(os.time())
math.random(); math.random(); math.random()

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
local exerciseStartTime = 0

-- Hot Seat Multiplayer state
local isHotSeatActive = false
local hotSeatAllowTies = true
local hotSeatGuestModeOnly = false
local hotSeatPlayers = {}
local hotSeatTurnInRound = 1
local hotSeatCurrentRound = 1
local hotSeatTotalRounds = 1
local hotSeatRoundNotesCount = 0
local hotSeatRoundMajorLevel = 0
local advanceHotSeatTurn
local startHotSeatMatch

-- Checkpoint Challenge state
local checkpointRunActive = false
local checkpointQuestionsPlayed = 0
local checkpointRunScore = 0
local checkpointMaxPossibleScore = 0

local function getHotSeatCurrentPlayerIdx()
    local N = #hotSeatPlayers
    if N == 0 then return 1 end
    local leaderIdx = ((hotSeatCurrentRound - 1) % N) + 1
    return ((leaderIdx - 1 + (hotSeatTurnInRound - 1)) % N) + 1
end

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
    exerciseStartTime = system.getTimer()
    local delay = useBreath and (baseDuration * 1.0) or 100
    local qTimer = timer.performWithDelay(delay, function()
        ui.showFeedback("enter your answer:", "none")
        playback.engine.playMelody(activeItem)
        isAnsweringAllowed = true
        isSequencePlaying = false 
    end)
    table.insert(mainTimers, qTimer)
end

local function playFullSequence()
    globalPanic()
    isSequencePlaying = true
    ui.showFeedback("establishing key...", "none")
    playback.engine.playCadence()
    local seqTimer = timer.performWithDelay(baseDuration * 5.2, function()
        playQuestion(true)
    end)
    table.insert(mainTimers, seqTimer)
end

local function playCadenceOnly()
    globalPanic()
    isSequencePlaying = true
    ui.showFeedback("establishing key...", "none")
    playback.engine.playCadence()
    local seqTimer = timer.performWithDelay(baseDuration * 5.2, function()
        ui.showFeedback("enter your answer:", "none")
        isAnsweringAllowed = true
        isSequencePlaying = false
    end)
    table.insert(mainTimers, seqTimer)
end

local lastNotesKey = ""

local function generateNewExercise()
    local currentLevelData = progression.levels[currentLevel]
    if not currentLevelData then return end
    
    appState = "quiz" 
    local majorLevel = math.floor(currentLevel)
    isSingleInput = (majorLevel == 1 or majorLevel == 2 or majorLevel == 5)

    if currentLevelData.isCheckpoint and not isHotSeatActive then
        if not checkpointRunActive then
            checkpointRunActive = true
            checkpointQuestionsPlayed = 0
            checkpointRunScore = 0
            checkpointMaxPossibleScore = 0
        end
    else
        checkpointRunActive = false
    end

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
    local pick, levelToUse
    if isHotSeatActive and hotSeatTurnInRound > 1 then
        local matchingLevels = {}
        for _, lv in ipairs(unlockedLevels) do
            if math.floor(lv) == hotSeatRoundMajorLevel then
                table.insert(matchingLevels, lv)
            end
        end
        if #matchingLevels > 0 then
            pick = matchingLevels[math.random(#matchingLevels)]
        else
            pick = unlockedLevels[math.random(#unlockedLevels)]
        end
    else
        pick = unlockedLevels[math.random(#unlockedLevels)]
    end
    levelToUse = progression.levels[pick]
    print("exercise gen: level " .. pick .. " selected.")

    local newTonic, newMelody, melodyNotesKey
    local attempts = 0
    repeat
        attempts = attempts + 1
        newTonic = (lastTonic == -1 or math.random() > 0.5) and math.random(52, 64) or lastTonic
        newMelody = engine.generateMelody(levelToUse)
        melodyNotesKey = table.concat(newMelody.notes, ",")
        
        local matchesGuardrail = true
        if isHotSeatActive and hotSeatTurnInRound > 1 then
            if #newMelody.notes ~= hotSeatRoundNotesCount then
                matchesGuardrail = false
            end
        end
    until (matchesGuardrail and not (newTonic == lastTonic and (newMelody.name == lastMelodyName or melodyNotesKey == lastNotesKey))) or attempts > 50

    activeItem = newMelody
    lastMelodyName = newMelody.name
    lastNotesKey = melodyNotesKey

    if isHotSeatActive and hotSeatTurnInRound == 1 then
        hotSeatRoundNotesCount = #activeItem.notes
        hotSeatRoundMajorLevel = math.floor(pick)
        print("Hot Seat Round Info: Major Level " .. hotSeatRoundMajorLevel .. ", Notes Count " .. hotSeatRoundNotesCount)
    end
    local forceCadence = (newTonic ~= lastTonic) or (currentLevel ~= lastLevel) or isHotSeatActive
    lastTonic = newTonic
    lastLevel = currentLevel
    playback.engine.setTonic(newTonic)
    
    maxTargetNotes = isSingleInput and 1 or #activeItem.notes
    userAnswers = {}
    inputCursor = 1
    local numNotes = (activeItem and activeItem.notes) and #activeItem.notes or maxTargetNotes
    hasFailedFirstTry = {}
    currentSlotMax = {}
    for i = 1, numNotes do
        hasFailedFirstTry[i] = false
        currentSlotMax[i] = 10
    end

    -- Set adaptive keypad mode (sub-level relevant button filtering)
    ui.setKeypadMode(currentLevel)

    if checkpointRunActive then
        ui.updateStatus(currentLevel, "Challenge: Question " .. (checkpointQuestionsPlayed + 1) .. "/10")
    else
        ui.updateStatus(currentLevel, currentLevelData.description or "")
    end
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

local inputCursor = 1

local function handleNoteInput(keyStr, mod)
    if not isAnsweringAllowed or appState ~= "quiz" or isSequencePlaying then return end
    mod = mod or 0

    -- Handle Single-Tap Tendency Action Buttons (Level 1 & Level 3)
    if tendencySyllableMap[keyStr] then
        userAnswers = {}
        inputCursor = 1
        local syls = tendencySyllableMap[keyStr]
        for _, syl in ipairs(syls) do
            local p = notePitchMap[syl] or 0
            table.insert(userAnswers, { pitch = (p + mod + 12) % 12, name = syl })
        end
        if isSingleInput then
            local fullMap = {
                ["d-s"] = "do sol",
                ["f-m"] = "fa mi",
                ["t-d"] = "ti do",
                ["r-d"] = "re do",
                ["l-s"] = "la sol",
                ["l-t-d"] = "la ti do",
                ["m-r-d"] = "mi re do",
                ["fi-s"] = "fi sol",
                ["me-r-d"] = "me re do",
                ["le-s"] = "le sol",
                ["te-d"] = "te do",
                ["ra-d"] = "ra do"
            }
            userAnswers[1].displayName = fullMap[keyStr] or table.concat(syls, " ")
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

        if isSingleInput then
            userAnswers = { { pitch = targetPitch, name = nameStr } }
            inputCursor = 1

            -- Look up the matching tendency unit in the current level definition to display the full tendency name
            local currentLevelData = progression.levels[currentLevel]
            if currentLevelData and currentLevelData.units then
                for _, unit in ipairs(currentLevelData.units) do
                    if type(unit) == "table" and unit.notes and #unit.notes > 0 then
                        local firstPitch = (unit.notes[1] % 12 + 12) % 12
                        if firstPitch == targetPitch then
                            local fullMap = {
                                ["d-s"] = "do sol",
                                ["f-m"] = "fa mi",
                                ["t-d"] = "ti do",
                                ["r-d"] = "re do",
                                ["l-s"] = "la sol",
                                ["l-t-d"] = "la ti do",
                                ["m-r-d"] = "mi re do",
                                ["fi-s"] = "fi sol",
                                ["me-r-d"] = "me re do",
                                ["le-s"] = "le sol",
                                ["te-d"] = "te do",
                                ["ra-d"] = "ra do"
                            }
                            if unit.name then
                                userAnswers[1].displayName = fullMap[unit.name] or string.gsub(unit.name, "%-", " ")
                            end
                            break
                        end
                    end
                end
            end

            ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
            evaluateSubmission()
        else
            userAnswers[inputCursor] = { pitch = targetPitch, name = nameStr }
            inputCursor = (inputCursor % maxTargetNotes) + 1
            ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        end
    end
end

local shortSyllableMap = {
    d = "do", r = "re", m = "mi", f = "fa", s = "sol", l = "la", t = "ti",
    fi = "fi", me = "me", le = "le", te = "te", ra = "ra",
    di = "di", ri = "ri", se = "se", si = "si", li = "li"
}

local enharmonicPairs = {
    di = "ra", ra = "di",
    ri = "me", me = "ri",
    fi = "se", se = "fi",
    si = "le", le = "si",
    li = "te", te = "li"
}

local function normalizeSyllable(syl)
    if not syl then return "" end
    syl = string.lower(syl)
    if shortSyllableMap[syl] then
        return shortSyllableMap[syl]
    end
    return syl
end

local function isNameEquivalent(uName, pName)
    if not uName or not pName then return false end
    local normU = normalizeSyllable(uName)
    local normP = normalizeSyllable(pName)

    if normU == normP then return true end
    if enharmonicPairs[normU] == normP then return true end
    return false
end

evaluateSubmission = function()
    isAnsweringAllowed = false
    local majorLevel = math.floor(currentLevel)
    local pointsPerNote = 10 + (majorLevel - 1)
    local turnScore = 0
    local displayResults = {}
    local isPitchError = false
    local forceReveal = false
    local numNotesInExercise = isSingleInput and 1 or ((activeItem and activeItem.notes) and #activeItem.notes or maxTargetNotes)
    local maxPossible = numNotesInExercise * pointsPerNote
    
    -- a. decay and reveal check across all notes in exercise independently
    for i = 1, numNotesInExercise do
        local targetPitch = (activeItem.notes[i] % 12 + 12) % 12
        local userEntry = userAnswers[i]
        local isNoteCorrect = false
        if userEntry and (userEntry.pitch % 12 + 12) % 12 == targetPitch then isNoteCorrect = true end

        if not isNoteCorrect then
            isPitchError = true
            hasFailedFirstTry[i] = true
            currentSlotMax[i] = (currentSlotMax[i] or 10) - 2 
            if currentSlotMax[i] <= 0 then forceReveal = true end
        end
    end

    -- b. process final state
    if not isPitchError or forceReveal then
        local isAug = (activeItem.name and string.find(activeItem.name, "+") ~= nil) or 
                      (progression.levels[currentLevel] and progression.levels[currentLevel].description and string.find(progression.levels[currentLevel].description, "augmented") ~= nil)
        
        for i = 1, numNotesInExercise do
            local targetPitch = (activeItem.notes[i] % 12 + 12) % 12
            local userEntry = userAnswers[i]
            local userPitch = userEntry and userEntry.pitch or 0
            local rawNoteScore = currentSlotMax[i] or 10
            local noteScore = math.floor(rawNoteScore / 10 * pointsPerNote + 0.5)
            if (userPitch % 12 + 12) % 12 == targetPitch then
                turnScore = turnScore + noteScore
            end

            local n = engine.getPreferredName(targetPitch, { prevNote = activeItem.notes[i-1], nextNote = activeItem.notes[i+1], isAugmented = isAug })
            local isMatch = userEntry and ((userEntry.pitch % 12 + 12) % 12 == targetPitch or isNameEquivalent(userEntry.name, n))
            local color = isMatch and "correct" or "wrong"
            table.insert(displayResults, { name = n, color = color })
        end

        sessionScore = sessionScore + turnScore
        ui.updateSessionScore(sessionScore)

        -- Log attempt data & lifetime points into stats module for EACH pitch independently
        local modeStr = isSingleInput and "single" or (activeItem.isStack and "stack" or "melody")
        local isFullCorrect = true
        for i = 1, numNotesInExercise do
            if hasFailedFirstTry[i] then isFullCorrect = false end
        end

        -- Harmonize tendency key and classify source (explicit / procedural / accidental)
        local canonicalTendencies = {
            ["t-d"] = "t-d", ["t-ti-d"] = "t-d",
            ["f-m"] = "f-m", ["t-fa-m"] = "f-m",
            ["r-d"] = "r-d", ["t-re-d"] = "r-d",
            ["l-s"] = "l-s", ["t-la-s"] = "l-s",
            ["d-s"] = "d-s", ["t-do-s"] = "d-s",
            ["fi-s"] = "fi-s", ["t-fi-s"] = "fi-s",
            ["le-s"] = "le-s", ["t-le-s"] = "le-s",
            ["ra-d"] = "ra-d", ["t-ra-d"] = "ra-d",
            ["te-d"] = "te-d", ["t-te-d"] = "te-d",
            ["me-r-d"] = "me-r-d", ["t-me-r-d"] = "me-r-d",
            ["l-t-d"] = "l-t-d"
        }

        local tendInfo = nil
        if activeItem and activeItem.name then
            local tendKey = canonicalTendencies[activeItem.name]
            if tendKey then
                local tendSource = (majorLevel == 1 or majorLevel == 5) and "explicit" or "procedural"
                tendInfo = { id = tendKey, source = tendSource }
            end
        end

        local canonicalChordQualities = {
            ["i"] = "major_triad", ["iv"] = "major_triad", ["v"] = "major_triad",
            ["ii"] = "minor_triad", ["iii"] = "minor_triad", ["vi"] = "minor_triad",
            ["vii-o"] = "diminished_triad", ["ii-o"] = "diminished_triad",
            ["iii+"] = "augmented_triad", ["i+"] = "augmented_triad",
            ["v7"] = "dominant_7th", ["v7/iv"] = "dominant_7th", ["v7/v"] = "dominant_7th", ["v7/vi"] = "dominant_7th", ["v7-65"] = "dominant_7th", ["v7-43"] = "dominant_7th",
            ["i-maj7"] = "major_7th", ["iv-maj7"] = "major_7th",
            ["ii7"] = "minor_7th", ["vi7"] = "minor_7th",
            ["vii-o7"] = "half_diminished_7th",
            ["dim7"] = "diminished_7th"
        }

        local chordQual = nil
        if activeItem and activeItem.isStack and activeItem.name then
            chordQual = activeItem.chordQuality or canonicalChordQualities[activeItem.name] or activeItem.name
        end

        local playerIdx = isHotSeatActive and getHotSeatCurrentPlayerIdx() or 1
        local currentTurnPlayer = isHotSeatActive and hotSeatPlayers[playerIdx] or nil
        local targetProfId = nil
        local isGuestTurn = false

        if isHotSeatActive then
            if hotSeatGuestModeOnly or not currentTurnPlayer or currentTurnPlayer.isGuest or not currentTurnPlayer.id then
                isGuestTurn = true
            else
                targetProfId = currentTurnPlayer.id
            end
        end

        if activeItem and activeItem.notes and not isGuestTurn then
            for i = 1, numNotesInExercise do
                local noteVal = activeItem.notes[i]
                if noteVal then
                    local targetPitch = (noteVal % 12 + 12) % 12
                    local isNoteStatsCorrect = not hasFailedFirstTry[i]
                    local userEntry = userAnswers[i]
                    local userPitchClass = (userEntry and userEntry.pitch) and ((userEntry.pitch % 12 + 12) % 12) or -1
                    local responseTimeMs = exerciseStartTime and math.max(0, math.floor(system.getTimer() - exerciseStartTime)) or 0

                    stats.logAttempt({
                        profileId = targetProfId,
                        pitchClass = targetPitch,
                        userPitchClass = userPitchClass,
                        isCorrect = isNoteStatsCorrect,
                        mode = modeStr,
                        noteCount = numNotesInExercise,
                        position = i,
                        tendencyInfo = tendInfo,
                        chordQuality = chordQual,
                        keyCenter = lastTonic,
                        responseTimeMs = responseTimeMs,
                        isQuestionEnd = (i == numNotesInExercise),
                        questionFullCorrect = isFullCorrect
                    })
                end
            end
        end

        if turnScore > 0 then
            if isHotSeatActive and hotSeatPlayers[playerIdx] then
                local curP = hotSeatPlayers[playerIdx]
                curP.score = (curP.score or 0) + turnScore
                ui.showHotSeatBanner(hotSeatCurrentRound, hotSeatTotalRounds, curP.name, currentLevel, hotSeatPlayers)
            else
                stats.addPoints(turnScore)
            end
        end

        if checkpointRunActive then
            checkpointQuestionsPlayed = checkpointQuestionsPlayed + 1
            checkpointRunScore = checkpointRunScore + turnScore
            checkpointMaxPossibleScore = checkpointMaxPossibleScore + maxPossible
        end

        if (majorLevel == 1 or majorLevel == 5) and not forceReveal then
            displayResults = {}
            for i = 1, #activeItem.notes do
                local p = (activeItem.notes[i] % 12 + 12) % 12
                local n = engine.getPreferredName(p, { prevNote = activeItem.notes[i-1], nextNote = activeItem.notes[i+1], isAugmented = isAug })
                table.insert(displayResults, { name = n, color = "correct" })
            end
        end

        local correctNames = {}
        local totalNotes = (activeItem and activeItem.notes) and #activeItem.notes or numNotesInExercise
        for i = 1, totalNotes do
            local p = (activeItem.notes[i] % 12 + 12) % 12
            local n = engine.getPreferredName(p, { prevNote = activeItem.notes[i-1], nextNote = activeItem.notes[i+1], isAugmented = isAug })
            table.insert(correctNames, n)
        end
        local correctAnswersString = table.concat(correctNames, " ")

        local otherInfo = ""
        if activeItem and activeItem.name and not string.match(activeItem.name, "^id%-") and not string.match(activeItem.name, "^proc%-") and activeItem.name ~= "fallback" and activeItem.name ~= "unit" then
            local romanMap = {
                ["i"] = "I",
                ["ii"] = "ii",
                ["iii"] = "iii",
                ["iv"] = "IV",
                ["v"] = "V",
                ["vi"] = "vi",
                ["vii-o"] = "vii°",
                ["ii-o"] = "ii°",
                ["i+"] = "I+",
                ["iii+"] = "III+",
                ["v7"] = "V7",
                ["v7/iv"] = "V7/IV",
                ["v7/v"] = "V7/V",
                ["v7/vi"] = "V7/VI",
                ["v7-65"] = "V65",
                ["v7-43"] = "V43",
                ["i-maj7"] = "Imaj7",
                ["iv-maj7"] = "IVmaj7",
                ["ii7"] = "ii7",
                ["vi7"] = "vi7",
                ["vii-o7"] = "viiø7",
                ["dim7"] = "vii°7",
                ["i-6"] = "I6",
                ["i-64"] = "I64",
                ["iv-6"] = "IV6",
                ["iv-64"] = "IV64",
                ["v-6"] = "V6",
                ["v-64"] = "V64"
            }
            local cleanName = string.lower(activeItem.name)
            if activeItem.isStack and romanMap[cleanName] then
                otherInfo = romanMap[cleanName]
            else
                otherInfo = activeItem.name:lower()
            end
        end

        local scoreString = turnScore .. " / " .. maxPossible
        if forceReveal then
            local msg = "sorry! the answer was: " .. correctAnswersString
            if otherInfo ~= "" then
                msg = msg .. "\n(" .. otherInfo .. ")"
            end
            msg = msg .. "\n" .. scoreString
            ui.showFeedback(msg, "wrong", activeItem and activeItem.isStack)
        else
            local header = (turnScore < maxPossible) and "correct" or "correct!"
            local msg = header .. " (" .. correctAnswersString .. ")"
            if otherInfo ~= "" then
                msg = msg .. "\n(" .. otherInfo .. ")"
            end
            msg = msg .. "\n" .. scoreString
            ui.showFeedback(msg, (turnScore < maxPossible) and "correction" or "correct", activeItem and activeItem.isStack)
        end
        
        ui.updateAnswerBufferFromResults(displayResults, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        appState = "result"
        timer.performWithDelay(forceReveal and 2500 or 1500, function() 
            if appState == "result" then
                if isHotSeatActive then
                    advanceHotSeatTurn()
                elseif checkpointRunActive and checkpointQuestionsPlayed >= 10 then
                    checkpointRunActive = false
                    appState = "idle"
                    local boardId = (currentLevel == 10.9) and "checkpoint_1" or "checkpoint_2"
                    ui.showChallengeCompleteModal(checkpointRunScore, checkpointMaxPossibleScore, boardId,
                        function(onComplete)
                            local prof = stats.getActiveProfile()
                            if prof and prof.profile_cloud_id then
                                local cloud = require("cloud")
                                cloud.submitScore(prof.profile_cloud_id, prof.name, boardId, checkpointRunScore, function(success, res)
                                    if success then
                                        onComplete(true, res.isNewHigh)
                                    else
                                        onComplete(false, res)
                                    end
                                end)
                            else
                                onComplete(false, "No cloud ID found")
                            end
                        end,
                        function()
                            generateNewExercise()
                        end,
                        function()
                            switchLevelTo(currentLevel)
                        end
                    )
                else
                    generateNewExercise()
                end
            end 
        end)
    else
        -- c. try again loop
        ui.showFeedback("try again!", "wrong", activeItem and activeItem.isStack)
        userAnswers = {}
        inputCursor = 1
        ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        isAnsweringAllowed = true
    end
end

---------------------------------------------------------
-- 4. input & level navigation
---------------------------------------------------------

local function levelToBoardId(lvl)
    if lvl >= 10.9 then
        return "checkpoint_2"
    else
        return "checkpoint_1"
    end
end

local function switchLevelTo(newLevel)
    if currentLevel and currentLevel ~= newLevel then
        stats.submitLifetimeScoreIfNeeded(levelToBoardId(currentLevel))
    end
    currentLevel = newLevel
    globalPanic()
    appState = "idle"
    isAnsweringAllowed = false
    isSequencePlaying = false
    userAnswers = {}
    inputCursor = 1
    
    checkpointRunActive = false
    checkpointQuestionsPlayed = 0
    checkpointRunScore = 0
    checkpointMaxPossibleScore = 0
    
    local currentLevelData = progression.levels[currentLevel]
    ui.setKeypadMode(currentLevel)
    ui.updateStatus(currentLevel, (currentLevelData and currentLevelData.description) or "")
    ui.updateAnswerBuffer(userAnswers, 1, false, false, nil, lastTonic)
    ui.showFeedback("tap here to start exercise", "none")
end

local function prevLevel()
    local levelIndex = 1
    for i, lvl in ipairs(levelList) do
        if lvl == currentLevel then levelIndex = i; break end
    end
    levelIndex = math.max(1, levelIndex - 1)
    switchLevelTo(levelList[levelIndex])
end

local function nextLevel()
    local levelIndex = 1
    for i, lvl in ipairs(levelList) do
        if lvl == currentLevel then levelIndex = i; break end
    end
    levelIndex = math.min(#levelList, levelIndex + 1)
    switchLevelTo(levelList[levelIndex])
end

local function prevMajorLevel()
    local targetMajor = math.floor(currentLevel) - 1
    local levelIndex = 1
    for i = #levelList, 1, -1 do
        if math.floor(levelList[i]) <= targetMajor then
            levelIndex = i
        end
    end
    switchLevelTo(levelList[levelIndex])
end

local function nextMajorLevel()
    local targetMajor = math.floor(currentLevel) + 1
    local levelIndex = 1
    for i, lvl in ipairs(levelList) do
        if math.floor(lvl) >= targetMajor then
            levelIndex = i
            break
        end
    end
    switchLevelTo(levelList[levelIndex])
end

local function onKey(event)
    if event.phase ~= "down" then return false end
    local key = string.lower(event.keyName or "")
    
    if ui.isModalActive() then
        if key == "escape" or key == "esc" then
            ui.closeActiveModal()
            return true
        elseif key == "enter" or key == "return" or key == "space" then
            if ui.handleModalConfirm() then
                return true
            end
        end
        return true -- Block underlying key events while a modal is active
    end

    if key == "deleteback" or key == "backspace" or key == "delete" then
        if #userAnswers > 0 then
            table.remove(userAnswers)
            inputCursor = math.max(1, #userAnswers + 1)
            ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
        end
        return true
    end

    if key == "enter" or key == "return" or key == "space" then
        if appState == "idle" or appState == "result" or appState == "menu" then 
            generateNewExercise()
        elseif appState == "quiz" and not isSingleInput then
            if #userAnswers == maxTargetNotes then evaluateSubmission() end
        end
        return true
    elseif key == "c" or key == "k" then
        if appState == "quiz" then
            playCadenceOnly()
        else
            playFullSequence()
        end
        return true
    elseif key == "q" then playQuestion(false); return true
    end

    if key == "up" or key == "right" then
        if event.isShiftDown then nextMajorLevel() else nextLevel() end
        return true
    elseif key == "down" or key == "left" then
        if event.isShiftDown then prevMajorLevel() else prevLevel() end
        return true
    end
    
    if notePitchMap[key] and isAnsweringAllowed then
        local mod = event.isShiftDown and 1 or ((event.isAltDown or event.isCommandDown) and -1 or 0)
        handleNoteInput(key, mod)
        return true
    end
    return false
end

local hotSeatBaseRounds = 1

showRoundLeaderModal = function()
    local playerIdx = getHotSeatCurrentPlayerIdx()
    local curP = hotSeatPlayers[playerIdx]
    local isOvertime = (hotSeatCurrentRound > hotSeatBaseRounds)
    ui.showPassDeviceModal(curP.name, hotSeatCurrentRound, hotSeatTotalRounds, true, currentLevel, function()
        ui.showLevelSelectorModal(levelList, currentLevel, function(selectedLvl)
            switchLevelTo(selectedLvl)
            showRoundLeaderModal()
        end, true)
    end, function()
        ui.showHotSeatBanner(hotSeatCurrentRound, hotSeatTotalRounds, curP.name, currentLevel, hotSeatPlayers)
        generateNewExercise()
    end, isOvertime)
end

advanceHotSeatTurn = function()
    if not isHotSeatActive then
        generateNewExercise()
        return
    end

    local isOvertime = (hotSeatCurrentRound > hotSeatBaseRounds)

    if hotSeatTurnInRound < #hotSeatPlayers then
        hotSeatTurnInRound = hotSeatTurnInRound + 1
        local playerIdx = getHotSeatCurrentPlayerIdx()
        local nextP = hotSeatPlayers[playerIdx]
        ui.showPassDeviceModal(nextP.name, hotSeatCurrentRound, hotSeatTotalRounds, false, currentLevel, nil, function()
            ui.showHotSeatBanner(hotSeatCurrentRound, hotSeatTotalRounds, nextP.name, currentLevel, hotSeatPlayers)
            generateNewExercise()
        end, isOvertime)
    else
        if hotSeatCurrentRound < hotSeatTotalRounds then
            hotSeatCurrentRound = hotSeatCurrentRound + 1
            hotSeatTurnInRound = 1
            showRoundLeaderModal()
        else
            local matchResults = {}
            for _, p in ipairs(hotSeatPlayers) do
                table.insert(matchResults, { id = p.id, name = p.name, score = p.score or 0, isGuest = p.isGuest })
            end
            table.sort(matchResults, function(a, b) return a.score > b.score end)

            local topScore = matchResults[1] and matchResults[1].score or 0
            local topTied = {}
            for _, p in ipairs(matchResults) do
                if p.score == topScore then table.insert(topTied, p) end
            end

            local isTie = (#topTied > 1)

            if isTie and not hotSeatAllowTies then
                -- Sudden Death Overtime: Extend match by 1 full round for all players!
                hotSeatTotalRounds = hotSeatTotalRounds + 1
                hotSeatCurrentRound = hotSeatCurrentRound + 1
                hotSeatTurnInRound = 1
                showRoundLeaderModal()
            else
                -- Match Finished! Record results for all tied winners or single winner.
                if isTie then
                    for _, p in ipairs(topTied) do
                        if not p.isGuest and p.id then
                            stats.recordHotSeatMatch(p.id, matchResults)
                        end
                    end
                else
                    local winner = matchResults[1]
                    local winnerId = winner and (not winner.isGuest) and winner.id or nil
                    stats.recordHotSeatMatch(winnerId, matchResults)
                end

                ui.hideHotSeatBanner()
                isHotSeatActive = false

                local winnerName = isTie and "Tie" or matchResults[1].name
                ui.showHotSeatVictoryModal(winnerName, topScore, matchResults, isTie, function()
                    startHotSeatMatch({
                        players = matchResults,
                        roundsPerPlayer = math.floor(hotSeatTotalRounds / math.max(1, #matchResults)),
                        allowTies = hotSeatAllowTies,
                        guestModeOnly = hotSeatGuestModeOnly
                    })
                end, function()
                    reinitUI()
                end)
            end
        end
    end
end

startHotSeatMatch = function(setupData)
    if not setupData or not setupData.players or #setupData.players == 0 then return end
    isHotSeatActive = true
    hotSeatAllowTies = (setupData and setupData.allowTies ~= false)
    hotSeatGuestModeOnly = (setupData and setupData.guestModeOnly == true)
    hotSeatPlayers = {}
    for _, p in ipairs(setupData.players) do
        table.insert(hotSeatPlayers, { id = p.id, name = p.name, score = 0, isGuest = p.isGuest })
    end
    hotSeatTurnInRound = 1
    hotSeatCurrentRound = 1
    hotSeatRoundNotesCount = 0
    hotSeatRoundMajorLevel = 0
    hotSeatBaseRounds = #hotSeatPlayers * (setupData.roundsPerPlayer or 1)
    hotSeatTotalRounds = hotSeatBaseRounds

    showRoundLeaderModal()
end

local handleSignInFlow

local function handleUserMenu()
    local activeProf = stats.getActiveProfile()
    local isSignedIn = (activeProf and activeProf.id ~= "user_default")
    local activeName = activeProf and activeProf.name or "Sign In"

    ui.showUserMenu(activeName, isSignedIn, {
        onStats = function()
            ui.showStatsModal(stats.getSummary(), stats.getDiatonicStats(), stats.getChromaticStats(), stats.getPitchGraphData())
        end,
        onHotSeat = function()
            local profiles = stats.getAllProfiles()
            ui.showHotSeatSetupModal(profiles, function(setupData)
                startHotSeatMatch(setupData)
            end)
        end,
        onLeaderboard = function()
            ui.showLeaderboardModal()
        end,
        onPitchSelect = function(pClass)
            local details = stats.getPitchDetails(pClass)
            ui.showPitchDetailModal(details, function()
                ui.showStatsModal(stats.getSummary(), stats.getDiatonicStats(), stats.getChromaticStats(), stats.getPitchGraphData())
            end)
        end,
        onSettings = function()
            ui.showSettingsModal(activeName, function()
                ui.showDeleteConfirmModal(activeName, function()
                    stats.deleteProfile(activeProf.id)
                    reinitUI()
                    handleSignInFlow()
                end)
            end)
        end,
        onSignOut = function()
            local boardId = levelToBoardId(currentLevel)
            stats.signOut(boardId)
            sessionScore = 0
            reinitUI()
            handleSignInFlow()
        end,
        onSignIn = function()
            handleSignInFlow()
        end
    })
end

handleSignInFlow = function()
    local profiles = stats.getAllProfiles()
    ui.showSignInModal(profiles, function(selectedId)
        stats.setActiveProfile(selectedId)
        reinitUI()
    end, function()
        ui.showNewUserModal(function(newName)
            if newName and #newName > 0 then
                stats.createProfile(newName)
                reinitUI()
            end
        end)
    end)
end

function reinitUI()
    ui.init(
        function(touchKeyId)
            handleNoteInput(touchKeyId, 0)
        end,
        {
            getActiveUserName = function()
                local prof = stats.getActiveProfile()
                return prof and prof.name or "Sign In"
            end,
            onUserMenu = handleUserMenu,
            onPrevLevel = prevLevel,
            onNextLevel = nextLevel,
            onPrevMajorLevel = prevMajorLevel,
            onNextMajorLevel = nextMajorLevel,
            onCadence = function()
                if appState == "quiz" then
                    playCadenceOnly()
                else
                    playFullSequence()
                end
            end,
            onReplay = function() playQuestion(false) end,
            onDeleteAction = function()
                if isAnsweringAllowed and appState == "quiz" and #userAnswers > 0 then
                    table.remove(userAnswers)
                    inputCursor = math.max(1, #userAnswers + 1)
                    ui.updateAnswerBuffer(userAnswers, maxTargetNotes, isSingleInput, activeItem and activeItem.isStack, activeItem and activeItem.notes, lastTonic)
                end
            end,
            onPrimaryAction = function()
                if isSequencePlaying then return end
                if appState == "menu" or appState == "result" or appState == "idle" then
                    generateNewExercise()
                elseif appState == "quiz" and not isSingleInput then
                    if #userAnswers == maxTargetNotes then evaluateSubmission() end
                end
            end
        }
    )
end

reinitUI()

Runtime:addEventListener("key", onKey)
ui.updateStatus(currentLevel, (progression.levels[currentLevel] and progression.levels[currentLevel].description) or "select level")