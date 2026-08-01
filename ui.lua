-- file: ui.lua
-- version: 13.2
-- status: Sub-level relevant button filtering + Full-screen real estate scaling for touch keypad

local M = {}

local levelText, descText, feedbackText, sessionText
local answerGroup, keypadGroup
local width = display.contentWidth
local height = display.contentHeight

local colors = {
    correct = {0, 0.8, 0.4},
    wrong = {0.9, 0.2, 0.2},
    correction = {0.9, 0.7, 0},
    none = {1, 1, 1}
}

local boomwhackerColors = {
    do_ = {1, 0.23, 0.19},
    d   = {1, 0.23, 0.19},
    ra  = {1, 0.39, 0},
    re  = {1, 0.58, 0},
    r   = {1, 0.58, 0},
    me  = {1, 0.70, 0},
    mi  = {1, 0.80, 0},
    m   = {1, 0.80, 0},
    fa  = {0.20, 0.78, 0.35},
    f   = {0.20, 0.78, 0.35},
    fi  = {0, 0.78, 0.75},
    sol = {0.35, 0.78, 0.98},
    s   = {0.35, 0.78, 0.98},
    le  = {0.20, 0.65, 0.90},
    la  = {0, 0.48, 1},
    l   = {0, 0.48, 1},
    te  = {0.35, 0.34, 0.84},
    ti  = {0.69, 0.32, 0.87},
    t   = {0.69, 0.32, 0.87}
}

local keyTapCallback = nil

local function formatKodalyName(name, midiPitch, tonicMIDI)
    if not name or name == "" or not midiPitch then return name or "" end
    local lowBound = tonicMIDI or 60
    local highBound = lowBound + 12
    if midiPitch >= highBound then
        return name .. "ˈ"
    elseif midiPitch < lowBound then
        return name .. "ˌ"
    end
    return name
end

local function getSyllableColor(syl)
    syl = string.lower(syl or "")
    return boomwhackerColors[syl] or {0.5, 0.5, 0.5}
endlocal function createTouchKey(keyId, labelText, colorRGB, x, y, kWidth, kHeight, callback)
    local group = display.newGroup()
    local pillRadius = math.floor(kHeight * 0.5) -- True stadium/pill geometry
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 2.5, kWidth, kHeight, pillRadius)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Main Stadium Glass Pill Key Body
    local rect = display.newRoundedRect(group, x, y, kWidth, kHeight, pillRadius)
    rect:setFillColor(unpack(colorRGB))

    -- 3. Top Inner Glass Sheen Highlight
    local sheen = display.newRoundedRect(group, x, y - kHeight * 0.22, kWidth * 0.84, kHeight * 0.36, math.floor(kHeight * 0.25))
    sheen:setFillColor(1, 1, 1, 0.25)

    -- 4. Balanced Dark Text Shadow behind Pure White Text
    local fontSize = (string.len(labelText) > 4) and 11 or ((string.len(labelText) > 2) and 12 or 15)
    
    local txtShadow = display.newText({
        parent = group,
        text = tostring(labelText):lower(),
        x = x + 1, y = y + 1.5,
        font = native.systemFontBold,
        fontSize = fontSize
    })
    txtShadow:setFillColor(0, 0, 0, 0.55)

    local txt = display.newText({
        parent = group,
        text = tostring(labelText):lower(),
        x = x, y = y,
        font = native.systemFontBold,
        fontSize = fontSize
    })
    txt:setFillColor(1, 1, 1, 1)

    -- Touch interaction
    local isPressed = false
    group:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(group)
            isPressed = true
            group.y = 2
            rect:setFillColor(colorRGB[1] * 0.85, colorRGB[2] * 0.85, colorRGB[3] * 0.85)
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            if isPressed then
                group.y = 0
                rect:setFillColor(unpack(colorRGB))
                isPressed = false
                if callback then callback(keyId) end
            end
            return true
        end
        return false
    end)

    return group
end

local function createTendencyTouchKey(tendencyId, labelText, sylList, x, y, kW, kH, callback)
    local group = display.newGroup()
    local pillRadius = math.floor(kH * 0.5) -- True stadium/pill geometry
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 2.5, kW, kH, pillRadius)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Oblong Landscape Gradient Pill (Zero square corner peeking)
    local numNotes = #sylList
    if numNotes <= 2 then
        local c1 = getSyllableColor(sylList[1])
        local c2 = getSyllableColor(sylList[2])
        local mainPill = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        mainPill:setFillColor(graphics.newGradient(c1, c2, "left"))
    else
        -- 3-note tendency button (e.g. m-r-d, l-t-d, me-r-d): rounded end caps eliminate square corners
        local c1 = getSyllableColor(sylList[1])
        local c2 = getSyllableColor(sylList[2])
        local c3 = getSyllableColor(sylList[3])
        
        local leftCap = display.newRoundedRect(group, x - kW * 0.25, y, kW * 0.52, kH, pillRadius)
        leftCap:setFillColor(graphics.newGradient(c1, c2, "left"))

        local rightCap = display.newRoundedRect(group, x + kW * 0.25, y, kW * 0.52, kH, pillRadius)
        rightCap:setFillColor(graphics.newGradient(c2, c3, "left"))

        local border = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        border.strokeWidth = 2
        border:setStrokeColor(1, 1, 1, 0.4)
        border:setFillColor(0, 0, 0, 0)
    end

    -- 3. Top Inner Glass Sheen Highlight
    local sheen = display.newRoundedRect(group, x, y - kH * 0.22, kW * 0.88, kH * 0.36, math.floor(kH * 0.25))
    sheen:setFillColor(1, 1, 1, 0.25)

    -- 4. Text Shadow & Pure White Text
    local fontSize = (string.len(labelText) > 6) and 12 or 13
    local txtShadow = display.newText({
        parent = group,
        text = labelText,
        x = x + 1, y = y + 1.5,
        font = native.systemFontBold,
        fontSize = fontSize
    })
    txtShadow:setFillColor(0, 0, 0, 0.6)

    local txt = display.newText({
        parent = group,
        text = labelText,
        x = x, y = y,
        font = native.systemFontBold,
        fontSize = fontSize
    })
    txt:setFillColor(1, 1, 1, 1)

    -- Touch interaction
    local isPressed = false
    group:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(group)
            isPressed = true
            group.y = 2
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            if isPressed then
                group.y = 0
                isPressed = false
                if callback then callback(tendencyId) end
            end
            return true
        end
        return false
    end)

    return group
end

function M.init(onKeyTap)
    keyTapCallback = onKeyTap
    
    if levelText and levelText.removeSelf then levelText:removeSelf() end
    if descText and descText.removeSelf then descText:removeSelf() end
    if feedbackText and feedbackText.removeSelf then feedbackText:removeSelf() end
    if sessionText and sessionText.removeSelf then sessionText:removeSelf() end

    levelText = display.newText({ text = "level: 1.1", x = width * 0.5, y = 22, font = native.systemFontBold, fontSize = 15 })
    descText = display.newText({ text = "initializing...", x = width * 0.5, y = 40, font = native.systemFont, fontSize = 13 })
    descText:setFillColor(0.7, 0.7, 0.7)
    feedbackText = display.newText({ text = "press enter to start", x = width * 0.5, y = 82, width = width * 0.9, align = "center", font = native.systemFontBold, fontSize = 18 })
    sessionText = display.newText({ text = "session score: 0", x = width * 0.5, y = 12, font = native.systemFont, fontSize = 12 })
    sessionText:setFillColor(0.6, 0.6, 0.6)
    
    if not answerGroup then answerGroup = display.newGroup() end
    if not keypadGroup then keypadGroup = display.newGroup() end

    M.setKeypadMode(1.1)
end

local allDiatonicKeys = {
    d = { id = "d", label = "do", color = boomwhackerColors.do_ },
    r = { id = "r", label = "re", color = boomwhackerColors.re },
    m = { id = "m", label = "mi", color = boomwhackerColors.mi },
    f = { id = "f", label = "fa", color = boomwhackerColors.fa },
    s = { id = "s", label = "sol", color = boomwhackerColors.sol },
    l = { id = "l", label = "la", color = boomwhackerColors.la },
    t = { id = "t", label = "ti", color = boomwhackerColors.ti }
}

local allChromaticKeys = {
    ra = { id = "ra", label = "ra / di", color = boomwhackerColors.ra, posIndex = 1.5 },
    me = { id = "me", label = "me / ri", color = boomwhackerColors.me, posIndex = 2.5 },
    fi = { id = "fi", label = "fi / se", color = boomwhackerColors.fi, posIndex = 4.5 },
    le = { id = "le", label = "le / si", color = boomwhackerColors.le, posIndex = 5.5 },
    te = { id = "te", label = "te / li", color = boomwhackerColors.te, posIndex = 6.5 }
}

local allTendencies = {
    ["d-s"] = { id = "d-s", label = "d-s", syls = {"d", "s"} },
    ["f-m"] = { id = "f-m", label = "f-m", syls = {"f", "m"} },
    ["t-d"] = { id = "t-d", label = "t-d", syls = {"t", "d"} },
    ["r-d"] = { id = "r-d", label = "r-d", syls = {"r", "d"} },
    ["l-s"] = { id = "l-s", label = "l-s", syls = {"l", "s"} },
    ["l-t-d"] = { id = "l-t-d", label = "l-t-d", syls = {"l", "t", "d"} },
    ["m-r-d"] = { id = "m-r-d", label = "m-r-d", syls = {"m", "r", "d"} },
    ["fi-s"] = { id = "fi-s", label = "fi-s", syls = {"fi", "s"} },
    ["me-r-d"] = { id = "me-r-d", label = "me-r-d", syls = {"me", "r", "d"} },
    ["le-s"] = { id = "le-s", label = "le-s", syls = {"le", "s"} },
    ["te-d"] = { id = "te-d", label = "te-d", syls = {"te", "d"} },
    ["ra-d"] = { id = "ra-d", label = "ra-d", syls = {"ra", "d"} }
}

function M.setKeypadMode(currentLevel)
    lvl = currentLevel or 1.1
    if keypadGroup.numChildren then
        for i = keypadGroup.numChildren, 1, -1 do keypadGroup[i]:removeSelf() end
    end

    local major = math.floor(lvl)

    -- 1. LEVEL 1: DIATONIC TENDENCY BUTTONS (Oblong Landscape Pills)
    if major == 1 then
        local tendList = {}
        if lvl == 1.1 then
            tendList = { "d-s", "f-m", "t-d" }
        elseif lvl == 1.2 then
            tendList = { "d-s", "f-m", "t-d", "r-d", "l-s" }
        else
            tendList = { "d-s", "f-m", "t-d", "r-d", "l-s", "l-t-d", "m-r-d" }
        end

        local count = #tendList
        local spacing = (count > 5) and math.floor(width * 0.135) or math.floor(width * 0.18)
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local btnY = height - 30

        for i, tid in ipairs(tendList) do
            local tData = allTendencies[tid]
            if tData then
                local kW = (#tData.syls > 2) and math.floor(spacing * 1.25) or math.floor(spacing * 0.90)
                local posX = startX + (i - 1) * spacing
                local keyObj = createTendencyTouchKey(tData.id, tData.label, tData.syls, posX, btnY, kW, 36, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        end

    -- 2. LEVEL 3: CHROMATIC TENDENCY & SINGLE BUTTONS
    elseif major == 3 then
        if lvl == 3.1 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d" }
            local spacing = math.floor(width * 0.20)
            local startX = width * 0.5 - ((#tendList - 1) * spacing * 0.5)
            local btnY = height - 30
            for i, tid in ipairs(tendList) do
                local tData = allTendencies[tid]
                local keyObj = createTendencyTouchKey(tData.id, tData.label, tData.syls, startX + (i - 1) * spacing, btnY, 82, 36, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        elseif lvl == 3.2 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d", "me-r-d" }
            local spacing = math.floor(width * 0.17)
            local startX = width * 0.5 - ((#tendList - 1) * spacing * 0.5)
            local btnY = height - 30
            for i, tid in ipairs(tendList) do
                local tData = allTendencies[tid]
                local kW = (#tData.syls > 2) and 96 or 74
                local keyObj = createTendencyTouchKey(tData.id, tData.label, tData.syls, startX + (i - 1) * spacing, btnY, kW, 36, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        else -- 3.3 Chromatic Singles ID
            local singles = { "ra", "me", "fi", "le", "te" }
            local spacing = math.floor(width * 0.17)
            local startX = width * 0.5 - ((#singles - 1) * spacing * 0.5)
            local btnY = height - 30
            for i, keyId in ipairs(singles) do
                local kData = allChromaticKeys[keyId]
                local keyObj = createTouchKey(kData.id, kData.label, kData.color, startX + (i - 1) * spacing, btnY, 72, 36, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        end

    -- 3. LEVEL 2: SINGLE DIATONIC NOTE ID (SUB-LEVEL FILTERED)
    elseif major == 2 then
        local activeSingles = {}
        if lvl == 2.1 then activeSingles = { "t", "f" }
        elseif lvl == 2.2 then activeSingles = { "t", "f", "r", "l" }
        else activeSingles = { "d", "r", "m", "f", "s", "l", "t" }
        end

        local count = #activeSingles
        local spacing = (count > 4) and math.floor(width * 0.135) or math.floor(width * 0.20)
        local kW = (count > 4) and math.floor(spacing * 0.88) or math.floor(spacing * 0.75)
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local btnY = height - 30

        for i, keyId in ipairs(activeSingles) do
            local kData = allDiatonicKeys[keyId]
            if kData then
                local keyObj = createTouchKey(kData.id, kData.label, kData.color, startX + (i - 1) * spacing, btnY, kW, 36, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        end

    -- 4. GENERAL LEVELS (4-19): OBLONG LANDSCAPE PILL KEYPAD
    else
        local hasChromatics = (major == 6 or major == 9 or major == 10 or major == 12 or major == 14 or major == 15 or major == 17 or major == 18 or major == 19 or lvl == 10.9 or lvl == 19.9)

        local diatonicOrder = { "d", "r", "m", "f", "s", "l", "t" }
        local chromaticOrder = { "ra", "me", "fi", "le", "te" }

        -- Wide oblong landscape pills (kW = 56px, kH = 34px -> 1.65 : 1 aspect ratio!)
        local spacing = math.floor(width * 0.132)
        local kW = math.floor(spacing * 0.88)
        local kH = hasChromatics and 32 or 36
        local startX = width * 0.5 - (3 * spacing)
        local diatonicY = height - 26
        local chromaticY = height - 68

        -- Diatonic Row (Bottom)
        for i, keyId in ipairs(diatonicOrder) do
            local kData = allDiatonicKeys[keyId]
            local posX = startX + (i - 1) * spacing
            local keyObj = createTouchKey(kData.id, kData.label, kData.color, posX, diatonicY, kW, kH, keyTapCallback)
            keypadGroup:insert(keyObj)
        end

        -- Chromatic Row (Staggered Above in Gaps if Level has Chromatics)
        if hasChromatics then
            for i, keyId in ipairs(chromaticOrder) do
                local cData = allChromaticKeys[keyId]
                local posX = startX + (cData.posIndex - 1) * spacing
                local keyObj = createTouchKey(cData.id, cData.label, cData.color, posX, chromaticY, kW, kH, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        end
    end
end

function M.updateStatus(lvl, desc)
    levelText.text = "level: " .. string.format("%0.1f", lvl)
    descText.text = tostring(desc):lower()
end

function M.showFeedback(msg, type)
    feedbackText.text = tostring(msg):lower()
    feedbackText:setFillColor(unpack(colors[type or "none"]))
end

function M.updateSessionScore(score)
    sessionText.text = "session score: " .. score
end

local function createBox(name, color, x, y, size, isCircle)
    local group = display.newGroup()
    local rect
    if isCircle then
        rect = display.newCircle(group, x, y, size * 0.45)
    else
        rect = display.newRoundedRect(group, x, y, size, size, size * 0.15)
    end
    rect.strokeWidth = 3
    rect:setStrokeColor(unpack(colors[color]))
    rect:setFillColor(0, 0, 0, 0.3)

    local txt = display.newText({
        parent = group,
        text = tostring(name):lower(),
        x = x, y = y,
        font = native.systemFontBold, 
        fontSize = size * 0.28
    })
    txt:setFillColor(unpack(colors[color]))

    return group
end

function M.updateAnswerBuffer(userEntries, count, isCircle, isStack, targetPitches, tonicMIDI)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end

    local boxSize = (count > 4) and 44 or 52
    
    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS (Bass at bottom, Soprano at top)
        local verticalSpacing = (count > 3) and 46 or 54
        local startY = height * 0.42 + ((count - 1) * verticalSpacing * 0.5)
        
        for i = 1, count do
            local entry = userEntries[i]
            local rawName = entry and entry.name or ""
            local pitch = (targetPitches and targetPitches[i]) or (entry and entry.pitch)
            local displayName = formatKodalyName(rawName, pitch, tonicMIDI)
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, "none", width * 0.5, posY, boxSize, isCircle))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES (Temporal sequence)
        local spacing = (count > 4) and 52 or 66
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local posY = height * 0.34
        for i = 1, count do
            local entry = userEntries[i]
            local rawName = entry and entry.name or ""
            local pitch = (targetPitches and targetPitches[i]) or (entry and entry.pitch)
            local displayName = formatKodalyName(rawName, pitch, tonicMIDI)
            answerGroup:insert(createBox(displayName, "none", startX + (i - 1) * spacing, posY, boxSize, isCircle))
        end
    end
end

function M.updateAnswerBufferFromResults(results, isStack, targetPitches, tonicMIDI)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end
    local count = #results
    local boxSize = (count > 4) and 44 or 52

    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS
        local verticalSpacing = (count > 3) and 46 or 54
        local startY = height * 0.42 + ((count - 1) * verticalSpacing * 0.5)

        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, res.color, width * 0.5, posY, boxSize, false))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES
        local spacing = (count > 4) and 52 or 66
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local posY = height * 0.34
        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            answerGroup:insert(createBox(displayName, res.color, startX + (i - 1) * spacing, posY, boxSize, false))
        end
    end
end

return M