-- file: stats.lua
-- version: 15.0
-- status: User Telemetry & Multi-Profile Storage Engine for Solfège Star

local M = {}
local json = require("json")

local fileName = "solfege_star_profiles.json"
local filePath = system.pathForFile(fileName, system.DocumentsDirectory)

local data = {
    activeProfileId = "user_default",
    profiles = {}
}

local function createDefaultProfile(profileId, name)
    local pitches = {}
    for pc = 0, 11 do
        pitches[tostring(pc)] = {
            single = { attempts = 0, correct = 0 },
            melody = { attempts = 0, correct = 0 },
            stack  = { attempts = 0, correct = 0 },
            recentAttempts = {}
        }
    end

    local tendencies = {}
    local canonicalTendencies = { "t-d", "f-m", "r-d", "l-s", "fi-s", "le-s", "ra-d", "te-d", "me-r-d" }
    for _, tid in ipairs(canonicalTendencies) do
        tendencies[tid] = {
            explicit   = { attempts = 0, correct = 0 },
            procedural = { attempts = 0, correct = 0 },
            accidental = { attempts = 0, correct = 0 }
        }
    end

    local melodyLengths = {}
    for len = 1, 5 do
        melodyLengths[tostring(len)] = { attempts = 0, correct = 0 }
    end

    local positionInSequence = {}
    for pos = 1, 5 do
        positionInSequence[tostring(pos)] = { attempts = 0, correct = 0 }
    end

    local stacks = {}
    for sz = 2, 4 do
        stacks[tostring(sz)] = { attempts = 0, correct = 0 }
    end

    local chordQualities = {
        major_triad       = { attempts = 0, correct = 0 },
        minor_triad       = { attempts = 0, correct = 0 },
        diminished_triad  = { attempts = 0, correct = 0 },
        augmented_triad   = { attempts = 0, correct = 0 },
        dominant_7th      = { attempts = 0, correct = 0 },
        major_7th         = { attempts = 0, correct = 0 },
        minor_7th         = { attempts = 0, correct = 0 }
    }

    return {
        id = profileId or "user_default",
        name = name or "Default Student",
        createdAt = os.time(),
        lastActive = os.time(),
        session = {
            questions = 0,
            correct = 0,
            currentStreak = 0,
            bestStreak = 0
        },
        lifetime = {
            totalQuestions = 0,
            totalNotesHeard = 0,
            correctNotes = 0,
            bestStreak = 0,
            sessionsCompleted = 1
        },
        pitches = pitches,
        tendencies = tendencies,
        melodyLengths = melodyLengths,
        positionInSequence = positionInSequence,
        stacks = stacks,
        chordQualities = chordQualities
    }
end

function M.save()
    local file, err = io.open(filePath, "w")
    if file then
        local encoded = json.encode(data)
        file:write(encoded)
        io.close(file)
    else
        print("[stats.lua] Error saving profile data: " .. tostring(err))
    end
end

function M.load()
    local file, err = io.open(filePath, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        if contents and #contents > 0 then
            local decoded = json.decode(contents)
            if decoded and decoded.profiles and decoded.activeProfileId then
                data = decoded
            end
        end
    end

    if not data.profiles[data.activeProfileId] then
        data.profiles[data.activeProfileId] = createDefaultProfile(data.activeProfileId, "Default Student")
        M.save()
    end
end

function M.init()
    M.load()
    local prof = M.getActiveProfile()
    if prof then
        prof.session.questions = 0
        prof.session.correct = 0
        prof.session.currentStreak = 0
        prof.session.bestStreak = 0
        prof.lastActive = os.time()
    end
end

function M.getActiveProfile()
    return data.profiles[data.activeProfileId]
end

function M.logAttempt(event)
    local prof = M.getActiveProfile()
    if not prof or not event then return end

    local pcStr = tostring(event.pitchClass or 0)
    local modeStr = event.mode or "single"
    local lenStr = tostring(event.noteCount or 1)
    local posStr = tostring(event.position or 1)
    local isCorr = event.isCorrect == true

    if prof.pitches[pcStr] then
        local pBucket = prof.pitches[pcStr][modeStr] or prof.pitches[pcStr].single
        pBucket.attempts = pBucket.attempts + 1
        if isCorr then pBucket.correct = pBucket.correct + 1 end

        local rec = prof.pitches[pcStr].recentAttempts or {}
        table.insert(rec, isCorr and 1 or 0)
        if #rec > 20 then table.remove(rec, 1) end
        prof.pitches[pcStr].recentAttempts = rec
    end

    if modeStr == "melody" then
        if prof.melodyLengths[lenStr] then
            prof.melodyLengths[lenStr].attempts = prof.melodyLengths[lenStr].attempts + 1
            if isCorr then prof.melodyLengths[lenStr].correct = prof.melodyLengths[lenStr].correct + 1 end
        end
        if prof.positionInSequence[posStr] then
            prof.positionInSequence[posStr].attempts = prof.positionInSequence[posStr].attempts + 1
            if isCorr then prof.positionInSequence[posStr].correct = prof.positionInSequence[posStr].correct + 1 end
        end
    elseif modeStr == "stack" then
        if prof.stacks[lenStr] then
            prof.stacks[lenStr].attempts = prof.stacks[lenStr].attempts + 1
            if isCorr then prof.stacks[lenStr].correct = prof.stacks[lenStr].correct + 1 end
        end
        if event.chordQuality and prof.chordQualities[event.chordQuality] then
            prof.chordQualities[event.chordQuality].attempts = prof.chordQualities[event.chordQuality].attempts + 1
            if isCorr then prof.chordQualities[event.chordQuality].correct = prof.chordQualities[event.chordQuality].correct + 1 end
        end
    end

    if event.tendencyInfo and event.tendencyInfo.id then
        local tID = event.tendencyInfo.id
        local tSrc = event.tendencyInfo.source or "explicit"
        if prof.tendencies[tID] and prof.tendencies[tID][tSrc] then
            prof.tendencies[tID][tSrc].attempts = prof.tendencies[tID][tSrc].attempts + 1
            if isCorr then prof.tendencies[tID][tSrc].correct = prof.tendencies[tID][tSrc].correct + 1 end
        end
    end

    prof.lifetime.totalNotesHeard = prof.lifetime.totalNotesHeard + 1
    if isCorr then prof.lifetime.correctNotes = prof.lifetime.correctNotes + 1 end

    if event.isQuestionEnd then
        prof.session.questions = prof.session.questions + 1
        prof.lifetime.totalQuestions = prof.lifetime.totalQuestions + 1

        if event.questionFullCorrect then
            prof.session.correct = prof.session.correct + 1
            prof.session.currentStreak = prof.session.currentStreak + 1
            if prof.session.currentStreak > prof.session.bestStreak then
                prof.session.bestStreak = prof.session.currentStreak
            end
            if prof.session.currentStreak > prof.lifetime.bestStreak then
                prof.lifetime.bestStreak = prof.session.currentStreak
            end
        else
            prof.session.currentStreak = 0
        end
    end

    M.save()
end

function M.getMasteryIndex(pitchClass, mode)
    local prof = M.getActiveProfile()
    if not prof then return 0.0 end

    local pcStr = tostring(pitchClass or 0)
    local pData = prof.pitches[pcStr]
    if not pData then return 0.0 end

    local bucket = mode and pData[mode] or nil
    local attempts = 0
    local correct = 0

    if bucket then
        attempts = bucket.attempts
        correct = bucket.correct
    else
        for _, bName in ipairs({ "single", "melody", "stack" }) do
            if pData[bName] then
                attempts = attempts + pData[bName].attempts
                correct = correct + pData[bName].correct
            end
        end
    end

    if attempts == 0 then return 0.0 end

    local rawAcc = correct / attempts
    local volFactor = math.min(1.0, math.log(1 + attempts) / math.log(1 + 50))
    
    return math.max(0.0, math.min(1.0, rawAcc * volFactor))
end

function M.getSummary()
    local prof = M.getActiveProfile()
    if not prof then
        return { questions = 0, correct = 0, accuracy = 0, streak = 0, bestStreak = 0 }
    end

    local q = prof.session.questions
    local c = prof.session.correct
    local acc = (q > 0) and math.floor((c / q) * 100) or 0

    return {
        questions = q,
        correct = c,
        accuracy = acc,
        streak = prof.session.currentStreak,
        bestStreak = prof.session.bestStreak
    }
end

return M
