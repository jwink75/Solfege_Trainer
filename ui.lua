-- file: ui.lua
-- version: 12.9
-- status: Option 1 Touch Keypad + Spatialized Vertical Answer Buffer + Kodaly Register Marks

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
    ra  = {1, 0.39, 0},
    re  = {1, 0.58, 0},
    me  = {1, 0.70, 0},
    mi  = {1, 0.80, 0},
    fa  = {0.20, 0.78, 0.35},
    fi  = {0, 0.78, 0.75},
    sol = {0.35, 0.78, 0.98},
    le  = {0.20, 0.65, 0.90},
    la  = {0, 0.48, 1},
    te  = {0.35, 0.34, 0.84},
    ti  = {0.69, 0.32, 0.87}
}

local keyTapCallback = nil
local chromaticGroupObj = nil

local function formatKodalyName(name, midiPitch)
    if not name or name == "" or not midiPitch then return name or "" end
    if midiPitch >= 72 then
        return name .. "′"
    elseif midiPitch < 60 then
        return name .. "ˌ"
    end
    return name
end

local function createTouchKey(keyId, labelText, colorRGB, x, y, kWidth, kHeight, callback)
    local group = display.newGroup()
    
    -- 1. 3D Bottom Bevel / Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 3, kWidth, kHeight, 14)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Main Glass Pill Key Body
    local rect = display.newRoundedRect(group, x, y, kWidth, kHeight, 14)
    rect:setFillColor(unpack(colorRGB))

    -- 3. Top Inner Glass Sheen Highlight
    local sheen = display.newRoundedRect(group, x, y - kHeight * 0.22, kWidth * 0.88, kHeight * 0.38, 10)
    sheen:setFillColor(1, 1, 1, 0.25)

    -- 4. Balanced 1.5px Dark Text Shadow behind Pure White Text
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

function M.init(onKeyTap)
    keyTapCallback = onKeyTap
    levelText = display.newText({ text = "level: 1.1", x = width * 0.5, y = 28, font = native.systemFontBold, fontSize = 16 })
    descText = display.newText({ text = "initializing...", x = width * 0.5, y = 50, font = native.systemFont, fontSize = 14 })
    descText:setFillColor(0.7, 0.7, 0.7)
    feedbackText = display.newText({ text = "press enter to start", x = width * 0.5, y = 105, width = width * 0.9, align = "center", font = native.systemFontBold, fontSize = 20 })
    sessionText = display.newText({ text = "session score: 0", x = width * 0.5, y = 18, font = native.systemFont, fontSize = 13 })
    sessionText:setFillColor(0.6, 0.6, 0.6)
    
    answerGroup = display.newGroup()
    keypadGroup = display.newGroup()

    -- Build Touch Keypad
    M.buildKeypad()
end

function M.buildKeypad()
    if keypadGroup.numChildren then
        for i = keypadGroup.numChildren, 1, -1 do keypadGroup[i]:removeSelf() end
    end

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

    local kW = 42
    local kH = 48
    local spacing = 45
    local startX = width * 0.5 - (3 * spacing)
    local diatonicY = height - 38
    local chromaticY = height - 94

    -- 1. Diatonic Row (Bottom)
    for i, kData in ipairs(diatonicKeys) do
        local posX = startX + (i - 1) * spacing
        local keyObj = createTouchKey(kData.id, kData.label, kData.color, posX, diatonicY, kW, kH, keyTapCallback)
        keypadGroup:insert(keyObj)
    end

    -- 2. Chromatic Row (Staggered Above in Gaps)
    chromaticGroupObj = display.newGroup()
    keypadGroup:insert(chromaticGroupObj)

    for i, cData in ipairs(chromaticKeys) do
        local posX = startX + (cData.posIndex - 1) * spacing
        local keyObj = createTouchKey(cData.id, cData.label, cData.color, posX, chromaticY, kW, kH, keyTapCallback)
        chromaticGroupObj:insert(keyObj)
    end
end

function M.setKeypadMode(hasChromatics)
    if chromaticGroupObj then
        chromaticGroupObj.isVisible = (hasChromatics == true)
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

local function createBox(name, color, x, y, size, isCircle, labelRole)
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

    if labelRole then
        local roleTxt = display.newText({
            parent = group,
            text = tostring(labelRole):lower(),
            x = x - size * 0.65, y = y,
            font = native.systemFont,
            fontSize = 11
        })
        roleTxt:setFillColor(0.6, 0.6, 0.6)
    end

    return group
end

function M.updateAnswerBuffer(userEntries, count, isCircle, isStack, targetPitches)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end

    local boxSize = (count > 4) and 44 or 52
    
    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS (Bass at bottom, Soprano at top)
        local verticalSpacing = (count > 3) and 46 or 54
        local startY = height * 0.44 + ((count - 1) * verticalSpacing * 0.5)
        local roles = {"bass", "tenor", "alto", "soprano"}
        
        for i = 1, count do
            local entry = userEntries[i]
            local rawName = entry and entry.name or ""
            local pitch = (entry and entry.pitch) or (targetPitches and targetPitches[i])
            local displayName = formatKodalyName(rawName, pitch)
            local posY = startY - (i - 1) * verticalSpacing
            local roleLabel = (count > 1) and (roles[i] or ("v" .. i)) or nil
            answerGroup:insert(createBox(displayName, "none", width * 0.5, posY, boxSize, isCircle, roleLabel))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES (Temporal sequence)
        local spacing = (count > 4) and 50 or 62
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local posY = height * 0.34
        for i = 1, count do
            local entry = userEntries[i]
            local rawName = entry and entry.name or ""
            local pitch = (entry and entry.pitch) or (targetPitches and targetPitches[i])
            local displayName = formatKodalyName(rawName, pitch)
            answerGroup:insert(createBox(displayName, "none", startX + (i - 1) * spacing, posY, boxSize, isCircle))
        end
    end
end

function M.updateAnswerBufferFromResults(results, isStack, targetPitches)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end
    local count = #results
    local boxSize = (count > 4) and 44 or 52

    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS
        local verticalSpacing = (count > 3) and 46 or 54
        local startY = height * 0.44 + ((count - 1) * verticalSpacing * 0.5)
        local roles = {"bass", "tenor", "alto", "soprano"}

        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch)
            local posY = startY - (i - 1) * verticalSpacing
            local roleLabel = (count > 1) and (roles[i] or ("v" .. i)) or nil
            answerGroup:insert(createBox(displayName, res.color, width * 0.5, posY, boxSize, false, roleLabel))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES
        local spacing = (count > 4) and 50 or 62
        local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
        local posY = height * 0.34
        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch)
            answerGroup:insert(createBox(displayName, res.color, startX + (i - 1) * spacing, posY, boxSize, false))
        end
    end
end

return M