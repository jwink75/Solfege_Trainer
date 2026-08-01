-- file: ui.lua
-- version: 13.1
-- status: Option 1 Touch Keypad + Gradient Tendency Buttons for L1/L3 + Anti-Ghosting Text Fix

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
local currentKeypadMode = nil

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
end

local function createTouchKey(keyId, labelText, colorRGB, x, y, kWidth, kHeight, callback)
    local group = display.newGroup()
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 3, kWidth, kHeight, 14)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Main Glass Pill Key Body
    local rect = display.newRoundedRect(group, x, y, kWidth, kHeight, 14)
    rect:setFillColor(unpack(colorRGB))

    -- 3. Top Inner Glass Sheen Highlight
    local sheen = display.newRoundedRect(group, x, y - kHeight * 0.22, kWidth * 0.88, kHeight * 0.38, 10)
    sheen:setFillColor(1, 1, 1, 0.25)

    -- 4. Balanced Dark Text Shadow behind Pure White Text
    local fontSize = (string.len(labelText) > 4) and 11 or ((string.len(labelText) > 2) and 13 or 16)
    
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

    -- Touch interaction (depress button on tap)
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
    
    -- 1. 3D Bottom Shadow
    local shadow = display.newRoundedRect(group, x, y + 3, kW, kH, 14)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Multi-segment gradient background
    local numNotes = #sylList
    local segWidth = kW / numNotes
    
    for i = 1, numNotes do
        local c1 = getSyllableColor(sylList[i])
        local segX = x - (kW * 0.5) + (i - 0.5) * segWidth
        local segRect = display.newRect(group, segX, y, segWidth, kH)
        segRect:setFillColor(unpack(c1))
        
        -- Gradient blend transition between adjacent colors (center 10%)
        if i < numNotes then
            local c2 = getSyllableColor(sylList[i+1])
            local gradX = x - (kW * 0.5) + i * segWidth
            local gradRect = display.newRect(group, gradX, y, kW * 0.12, kH)
            local g = graphics.newGradient(c1, c2, "left")
            gradRect:setFillColor(g)
        end
    end

    -- 3. Glass Overlay & Border Frame
    local frame = display.newRoundedRect(group, x, y, kW, kH, 14)
    frame.strokeWidth = 2
    frame:setStrokeColor(1, 1, 1, 0.35)
    frame:setFillColor(0, 0, 0, 0)

    -- 4. Top Inner Glass Sheen Highlight
    local sheen = display.newRoundedRect(group, x, y - kH * 0.22, kW * 0.90, kH * 0.38, 10)
    sheen:setFillColor(1, 1, 1, 0.22)

    -- 5. Text Shadow & Pure White Text
    local fontSize = (string.len(labelText) > 6) and 11 or 13
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
    
    -- Anti-ghosting: Remove previous text objects if re-initialized
    if levelText and levelText.removeSelf then levelText:removeSelf() end
    if descText and descText.removeSelf then descText:removeSelf() end
    if feedbackText and feedbackText.removeSelf then feedbackText:removeSelf() end
    if sessionText and sessionText.removeSelf then sessionText:removeSelf() end

    levelText = display.newText({ text = "level: 1.1", x = width * 0.5, y = 26, font = native.systemFontBold, fontSize = 16 })
    descText = display.newText({ text = "initializing...", x = width * 0.5, y = 48, font = native.systemFont, fontSize = 14 })
    descText:setFillColor(0.7, 0.7, 0.7)
    feedbackText = display.newText({ text = "press enter to start", x = width * 0.5, y = 92, width = width * 0.9, align = "center", font = native.systemFontBold, fontSize = 18 })
    sessionText = display.newText({ text = "session score: 0", x = width * 0.5, y = 16, font = native.systemFont, fontSize = 13 })
    sessionText:setFillColor(0.6, 0.6, 0.6)
    
    if not answerGroup then answerGroup = display.newGroup() end
    if not keypadGroup then keypadGroup = display.newGroup() end

    M.buildKeypad("standard")
end

function M.buildKeypad(mode)
    currentKeypadMode = mode or "standard"
    if keypadGroup.numChildren then
        for i = keypadGroup.numChildren, 1, -1 do keypadGroup[i]:removeSelf() end
    end

    if mode == "tendency_diatonic" then
        -- LEVEL 1: Single-tap Diatonic Tendency Buttons
        local tendencies = {
            { id = "d-s", label = "d-s", syls = {"d", "s"} },
            { id = "f-m", label = "f-m", syls = {"f", "m"} },
            { id = "t-d", label = "t-d", syls = {"t", "d"} },
            { id = "r-d", label = "r-d", syls = {"r", "d"} },
            { id = "l-s", label = "l-s", syls = {"l", "s"} },
            { id = "l-t-d", label = "l-t-d", syls = {"l", "t", "d"} },
            { id = "m-r-d", label = "m-r-d", syls = {"m", "r", "d"} }
        }
        local spacing = 64
        local startX = width * 0.5 - ((#tendencies - 1) * spacing * 0.5)
        local btnY = height - 44
        
        for i, tData in ipairs(tendencies) do
            local kW = (#tData.syls > 2) and 74 or 56
            local posX = startX + (i - 1) * spacing
            local keyObj = createTendencyTouchKey(tData.id, tData.label, tData.syls, posX, btnY, kW, 46, keyTapCallback)
            keypadGroup:insert(keyObj)
        end

    elseif mode == "tendency_chromatic" then
        -- LEVEL 3: Single-tap Chromatic & Diatonic Tendency Buttons
        local tendencies = {
            { id = "fi-s", label = "fi-s", syls = {"fi", "s"} },
            { id = "me-r-d", label = "me-r-d", syls = {"me", "r", "d"} },
            { id = "le-s", label = "le-s", syls = {"le", "s"} },
            { id = "te-d", label = "te-d", syls = {"te", "d"} },
            { id = "ra-d", label = "ra-d", syls = {"ra", "d"} }
        }
        local spacing = 86
        local startX = width * 0.5 - ((#tendencies - 1) * spacing * 0.5)
        local btnY = height - 44
        
        for i, tData in ipairs(tendencies) do
            local kW = (#tData.syls > 2) and 88 or 68
            local posX = startX + (i - 1) * spacing
            local keyObj = createTendencyTouchKey(tData.id, tData.label, tData.syls, posX, btnY, kW, 46, keyTapCallback)
            keypadGroup:insert(keyObj)
        end

    else
        -- STANDARD KEYPAD (Levels 2, 4-19): 7 Diatonic Keys + 5 Staggered Chromatic Keys
        local diatonicKeys = {
            { id = "d", label = "do", color = boomwhackerColors.do_ },
            { id = "r", label = "re", color = boomwhackerColors.re },
            { id = "m", label = "mi", color = boomwhackerColors.mi },
            { id = "f", label = "fa", color = boomwhackerColors.fa },
            { id = "s", label = "sol", color = boomwhackerColors.sol },
            { id = "l", label = "la", color = boomwhackerColors.la },
            { id = "t", label = "ti", color = boomwhackerColors.ti }
        }

        local chromaticKeys = {
            { id = "ra", label = "ra / di", color = boomwhackerColors.ra, posIndex = 1.5 },
            { id = "me", label = "me / ri", color = boomwhackerColors.me, posIndex = 2.5 },
            { id = "fi", label = "fi / se", color = boomwhackerColors.fi, posIndex = 4.5 },
            { id = "le", label = "le / si", color = boomwhackerColors.le, posIndex = 5.5 },
            { id = "te", label = "te / li", color = boomwhackerColors.te, posIndex = 6.5 }
        }

        local kW = 58
        local kH = 46
        local spacing = 62
        local startX = width * 0.5 - (3 * spacing)
        local diatonicY = height - 34
        local chromaticY = height - 88

        -- 1. Diatonic Row (Bottom)
        for i, kData in ipairs(diatonicKeys) do
            local posX = startX + (i - 1) * spacing
            local keyObj = createTouchKey(kData.id, kData.label, kData.color, posX, diatonicY, kW, kH, keyTapCallback)
            keypadGroup:insert(keyObj)
        end

        -- 2. Chromatic Row (Staggered Above in Gaps)
        local chromaticGroup = display.newGroup()
        keypadGroup:insert(chromaticGroup)

        for i, cData in ipairs(chromaticKeys) do
            local posX = startX + (cData.posIndex - 1) * spacing
            local keyObj = createTouchKey(cData.id, cData.label, cData.color, posX, chromaticY, kW, kH, keyTapCallback)
            chromaticGroup:insert(keyObj)
        end
    end
end

function M.setKeypadMode(majorLevel, hasChromatics)
    if majorLevel == 1 then
        M.buildKeypad("tendency_diatonic")
    elseif majorLevel == 3 then
        M.buildKeypad("tendency_chromatic")
    else
        M.buildKeypad("standard")
        -- If level has no chromatics, hide top chromatic row
        if keypadGroup.numChildren and keypadGroup.numChildren >= 2 then
            keypadGroup[keypadGroup.numChildren].isVisible = (hasChromatics == true)
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