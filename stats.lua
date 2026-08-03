-- file: stats.lua
-- version: 16.0
-- status: User Telemetry & Multi-Profile Storage Engine for Solfège Star

local M = {}
local json = require("json")

local fileName = "solfege_star_profiles.json"
local filePath = system.pathForFile(fileName, system.DocumentsDirectory)

local data = {
    activeProfileId = "user_default",
    profiles = {}
}

local diatonicPitches = { 0, 2, 4, 5, 7, 9, 11 }
local chromaticPitches = { 1, 3, 6, 8, 10 }
local pitchLabels = {
    [0] = "do",  [1] = "ra", [2] = "re", [3] = "me", [4] = "mi", [5] = "fa",
    [6] = "fi",  [7] = "sol",[8] = "le", [9] = "la", [10] = "te",[11] = "ti"
}

local function createDefaultProfile(profileId, name)
    local pitches = {}
    for pc = 0, 11 do
        pitches[tostring(pc)] = {
            single = { attempts = 0, correct = 0 },
            melody = { attempts = 0, correct = 0 },
            stack  = { attempts = 0, correct = 0 },
            recentAttempts = {},
            confusions = {}
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
        major_triad          = { attempts = 0, correct = 0 },
        minor_triad          = { attempts = 0, correct = 0 },
        diminished_triad     = { attempts = 0, correct = 0 },
        augmented_triad      = { attempts = 0, correct = 0 },
        dominant_7th         = { attempts = 0, correct = 0 },
        major_7th            = { attempts = 0, correct = 0 },
        minor_7th            = { attempts = 0, correct = 0 },
        half_diminished_7th = { attempts = 0, correct = 0 },
        diminished_7th      = { attempts = 0, correct = 0 }
    }

    return {
        id = profileId or "user_default",
        name = name or "Default Student",
        createdAt = os.time(),
        lastActive = os.time(),
        meta = {
            lastPlayed = os.time(),
            favoriteMode = "single",
            preferredInputMethod = "touch"
        },
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
            local success, decoded = pcall(json.decode, contents)
            if success and decoded and type(decoded) == "table" and decoded.profiles and decoded.activeProfileId then
                data = decoded
                return
            end
        end
    end

    data = {
        activeProfileId = "user_default",
        profiles = {
            user_default = createDefaultProfile("user_default", "Default Student")
        }
    }
    M.save()
end

function M.signOut()
    data.activeProfileId = "user_default"
    M.save()
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

function M.getAllProfiles()
    local list = {}
    for id, p in pairs(data.profiles) do
        table.insert(list, {
            id = id,
            name = p.name or "Student",
            createdAt = p.createdAt or 0,
            lastActive = p.lastActive or 0,
            isActive = (id == data.activeProfileId)
        })
    end
    table.sort(list, function(a, b) return (a.lastActive or 0) > (b.lastActive or 0) end)
    return list
end

function M.createProfile(name)
    local cleanName = string.sub(tostring(name or "New Student"):gsub("^%s*(.-)%s*$", "%1"), 1, 16)
    if #cleanName == 0 then cleanName = "New Student" end

    local newId = "user_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local prof = createDefaultProfile(newId, cleanName)

    data.profiles[newId] = prof
    data.activeProfileId = newId
    M.save()
    return prof
end

function M.setActiveProfile(id)
    if data.profiles[id] then
        data.activeProfileId = id
        data.profiles[id].lastActive = os.time()
        if data.profiles[id].meta then
            data.profiles[id].meta.lastPlayed = os.time()
        end
        -- Reset session stats on profile switch so stats don't bleed across users
        data.profiles[id].session = {
            questions = 0,
            correct = 0,
            currentStreak = 0,
            bestStreak = 0
        }
        M.save()
        return true
    end
    return false
end

function M.deleteProfile(id)
    if data.profiles[id] then
        data.profiles[id] = nil
        if data.activeProfileId == id then
            -- Switch to next remaining profile or recreate default
            local remaining = M.getAllProfiles()
            if #remaining > 0 then
                data.activeProfileId = remaining[1].id
            else
                local def = createDefaultProfile("user_default", "Default Student")
                data.profiles["user_default"] = def
                data.activeProfileId = "user_default"
            end
        end
        M.save()
        return true
    end
    return false
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
        if isCorr then
            pBucket.correct = pBucket.correct + 1
        elseif event.userPitchClass and event.userPitchClass >= 0 then
            local uPcStr = tostring(event.userPitchClass)
            prof.pitches[pcStr].confusions = prof.pitches[pcStr].confusions or {}
            prof.pitches[pcStr].confusions[uPcStr] = (prof.pitches[pcStr].confusions[uPcStr] or 0) + 1
        end

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

function M.getDiatonicStats()
    local prof = M.getActiveProfile()
    if not prof then return { attempts = 0, correct = 0, percentage = 0 } end

    local totalAtt = 0
    local totalCorr = 0

    for _, pc in ipairs(diatonicPitches) do
        local pData = prof.pitches[tostring(pc)]
        if pData then
            for _, bName in ipairs({ "single", "melody", "stack" }) do
                if pData[bName] then
                    totalAtt = totalAtt + (pData[bName].attempts or 0)
                    totalCorr = totalCorr + (pData[bName].correct or 0)
                end
            end
        end
    end

    local pct = (totalAtt > 0) and math.floor((totalCorr / totalAtt) * 100) or 0
    return { attempts = totalAtt, correct = totalCorr, percentage = pct }
end

function M.getChromaticStats()
    local prof = M.getActiveProfile()
    if not prof then return { attempts = 0, correct = 0, percentage = 0 } end

    local totalAtt = 0
    local totalCorr = 0

    for _, pc in ipairs(chromaticPitches) do
        local pData = prof.pitches[tostring(pc)]
        if pData then
            for _, bName in ipairs({ "single", "melody", "stack" }) do
                if pData[bName] then
                    totalAtt = totalAtt + (pData[bName].attempts or 0)
                    totalCorr = totalCorr + (pData[bName].correct or 0)
                end
            end
        end
    end

    local pct = (totalAtt > 0) and math.floor((totalCorr / totalAtt) * 100) or 0
    return { attempts = totalAtt, correct = totalCorr, percentage = pct }
end

function M.getPitchGraphData()
    local prof = M.getActiveProfile()
    local result = { maxAttempts = 10, pitches = {} }

    local maxAtt = 0

    for pc = 0, 11 do
        local pcStr = tostring(pc)
        local att = 0
        local corr = 0

        if prof and prof.pitches[pcStr] then
            for _, bName in ipairs({ "single", "melody", "stack" }) do
                if prof.pitches[pcStr][bName] then
                    att = att + (prof.pitches[pcStr][bName].attempts or 0)
                    corr = corr + (prof.pitches[pcStr][bName].correct or 0)
                end
            end
        end

        if att > maxAtt then maxAtt = att end

        local pct = (att > 0) and math.floor((corr / att) * 100) or 0
        table.insert(result.pitches, {
            pitchClass = pc,
            label = pitchLabels[pc] or "note",
            attempts = att,
            correct = corr,
            accuracyPct = pct
        })
    end

    result.maxAttempts = math.max(1, maxAtt)
    return result
end

function M.getPitchDetails(pitchClass)
    local prof = M.getActiveProfile()
    local pcStr = tostring(pitchClass or 0)
    local label = pitchLabels[pitchClass] or "note"

    local totalAtt = 0
    local totalCorr = 0
    local breakdown = {
        single = { attempts = 0, correct = 0, pct = 0 },
        melody = { attempts = 0, correct = 0, pct = 0 },
        stack = { attempts = 0, correct = 0, pct = 0 }
    }

    if prof and prof.pitches[pcStr] then
        for _, bName in ipairs({ "single", "melody", "stack" }) do
            if prof.pitches[pcStr][bName] then
                local a = prof.pitches[pcStr][bName].attempts or 0
                local c = prof.pitches[pcStr][bName].correct or 0
                totalAtt = totalAtt + a
                totalCorr = totalCorr + c
                breakdown[bName].attempts = a
                breakdown[bName].correct = c
                breakdown[bName].pct = (a > 0) and math.floor((c / a) * 100) or 0
            end
        end
    end

    local pct = (totalAtt > 0) and math.floor((totalCorr / totalAtt) * 100) or 0

    local topConfusedLabel = nil
    local topConfusedCount = 0
    if prof and prof.pitches[pcStr] and prof.pitches[pcStr].confusions then
        for uPcStr, count in pairs(prof.pitches[pcStr].confusions) do
            local uPc = tonumber(uPcStr)
            if uPc and count > topConfusedCount then
                topConfusedCount = count
                topConfusedLabel = pitchLabels[uPc] or "note"
            end
        end
    end

    return {
        pitchClass = pitchClass,
        label = label,
        totalAttempts = totalAtt,
        totalCorrect = totalCorr,
        accuracyPct = pct,
        breakdown = breakdown,
        topConfusedLabel = topConfusedLabel,
        topConfusedCount = topConfusedCount
    }
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

function M.addPoints(pts)
    local prof = M.getActiveProfile()
    if prof and pts and pts > 0 then
        prof.lifetime.totalPoints = (prof.lifetime.totalPoints or 0) + pts
        M.save()
    end
end

function M.getLifetimePoints()
    local prof = M.getActiveProfile()
    return prof and (prof.lifetime.totalPoints or 0) or 0
end

function M.getSummary()
    local prof = M.getActiveProfile()
    if not prof then
        return { questions = 0, correct = 0, accuracy = 0, streak = 0, bestStreak = 0, totalPoints = 0 }
    end

    local q = prof.session.questions
    local c = prof.session.correct
    local acc = (q > 0) and math.floor((c / q) * 100) or 0

    return {
        questions = q,
        correct = c,
        accuracy = acc,
        streak = prof.session.currentStreak,
        bestStreak = prof.lifetime.bestStreak or prof.session.bestStreak,
        totalPoints = prof.lifetime.totalPoints or 0
    }
end

function M.resetProfileStats(profileId)
    local targetId = profileId or data.activeProfileId
    if targetId and data.profiles[targetId] then
        local name = data.profiles[targetId].name
        data.profiles[targetId] = createDefaultProfile(targetId, name)
        M.save()
    end
end

return M
