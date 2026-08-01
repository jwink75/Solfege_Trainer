-- file: ui.lua
-- version: 13.4
-- status: Full physical screen real-estate math (display.actualContentWidth) + Correct gradient direction ("right") + Zero corner bleed clipping

local M = {}

local levelText, descText, feedbackText, sessionText
local answerGroup, keypadGroup

-- Full physical display bounds (takes advantage of 100% widescreen real-estate on all devices)
local screenW = display.actualContentWidth
local screenH = display.actualContentHeight
local screenOriginX = display.screenOriginX
local screenOriginY = display.screenOriginY
local centerX = screenOriginX + screenW * 0.5

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
end

local function createGlassSheen(group, x, y, kW, kH, pillRadius)
    local topGap = 4.5
    local sideGap = 7.0
    local sheenW = kW - (sideGap * 2)
    local sheenH = math.floor(kH * 0.36)
    local sheenY = y - (kH * 0.5) + (sheenH * 0.5) + topGap
    local sheenRadius = math.floor(sheenH * 0.5)

    local sheenGrad = graphics.newGradient({1, 1, 1, 0.45}, {1, 1, 1, 0.0}, "down")
    local sheen = display.newRoundedRect(group, x, sheenY, sheenW, sheenH, sheenRadius)
    sheen:setFillColor(sheenGrad)
    return sheen
end

local function createTouchKey(keyId, labelText, colorRGB, x, y, kWidth, kHeight, callback)
    local group = display.newGroup()
    local pillRadius = math.floor(kHeight * 0.5) -- True stadium/pill geometry
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 2.5, kWidth, kHeight, pillRadius)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Main Stadium Glass Pill Key Body
    local rect = display.newRoundedRect(group, x, y, kWidth, kHeight, pillRadius)
    rect:setFillColor(unpack(colorRGB))

    -- 3. Glass Border Frame Overlay
    local border = display.newRoundedRect(group, x, y, kWidth, kHeight, pillRadius)
    border.strokeWidth = 2
    border:setStrokeColor(1, 1, 1, 0.45)
    border:setFillColor(0, 0, 0, 0)

    -- 4. Top Concentric Glass Sheen Highlight (Concentric curve following outer pill)
    createGlassSheen(group, x, y, kWidth, kHeight, pillRadius)

    -- 5. Balanced Dark Text Shadow behind Pure White Text
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

    -- 2. Oblong Landscape Gradient Pill Body
    local numNotes = #sylList
    if numNotes <= 2 then
        local c1 = getSyllableColor(sylList[1])
        local c2 = getSyllableColor(sylList[2])
        local mainPill = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        mainPill:setFillColor(graphics.newGradient(c1, c2, "right"))
    else
        -- 3-note tendency button: la=RoyalBlue, ti=Magenta, do=Red
        local c1 = getSyllableColor(sylList[1])
        local c2 = getSyllableColor(sylList[2])
        local c3 = getSyllableColor(sylList[3])
        
        -- Base solid pill (middle note color background)
        local basePill = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        basePill:setFillColor(unpack(c2))

        -- Left gradient cap (c1 -> c2, direction "right": c1 on LEFT, c2 on RIGHT)
        local leftCap = display.newRoundedRect(group, x - kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        leftCap:setFillColor(graphics.newGradient(c1, c2, "right"))

        -- Right gradient cap (c2 -> c3, direction "right": c2 on LEFT, c3 on RIGHT)
        local rightCap = display.newRoundedRect(group, x + kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        rightCap:setFillColor(graphics.newGradient(c2, c3, "right"))
    end

    -- 3. Glass Border Frame Overlay
    local border = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
    border.strokeWidth = 2
    border:setStrokeColor(1, 1, 1, 0.45)
    border:setFillColor(0, 0, 0, 0)

    -- 4. Top Concentric Glass Sheen Highlight (Concentric curve following outer pill)
    createGlassSheen(group, x, y, kW, kH, pillRadius)

    -- 5. Text Shadow & Pure White Text
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

    levelText = display.newText({ text = "level: 1.1", x = centerX, y = screenOriginY + 22, font = native.systemFontBold, fontSize = 15 })
    descText = display.newText({ text = "initializing...", x = centerX, y = screenOriginY + 40, font = native.systemFont, fontSize = 13 })
    descText:setFillColor(0.7, 0.7, 0.7)
    feedbackText = display.newText({ text = "press enter to start", x = centerX, y = screenOriginY + 82, width = screenW * 0.9, align = "center", font = native.systemFontBold, fontSize = 18 })
    sessionText = display.newText({ text = "session score: 0", x = centerX, y = screenOriginY + 12, font = native.systemFont, fontSize = 12 })
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

-- FULL PHYSICAL DISPLAY REAL-ESTATE MATH
local minGap = 10 -- Mandatory minimum gap between buttons to prevent overlapping
local maxUsableWidth = screenW * 0.94 -- Uses 94% of actual physical screen width

local function layoutRow(items, btnY, heightVal, keyWidthMultiplierFunc)
    local count = #items
    if count == 0 then return end

    -- 1. Calculate base available key width across 94% of physical screen width
    local availableWidthForKeys = maxUsableWidth - ((count - 1) * minGap)
    
    -- 2. Determine relative weights
    local totalWeight = 0
    local weights = {}
    for i, item in ipairs(items) do
        local wMult = keyWidthMultiplierFunc and keyWidthMultiplierFunc(item) or 1.0
        weights[i] = wMult
        totalWeight = totalWeight + wMult
    end

    -- 3. Compute exact pixel widths & positions
    local keyWidths = {}
    local totalRowWidth = 0
    for i = 1, count do
        local kw = math.floor((availableWidthForKeys * weights[i]) / totalWeight)
        keyWidths[i] = kw
        totalRowWidth = totalRowWidth + kw
    end
    totalRowWidth = totalRowWidth + (count - 1) * minGap

    -- 4. Center row horizontally across physical screen
    local currentX = screenOriginX + (screenW - totalRowWidth) * 0.5

    for i, item in ipairs(items) do
        local kW = keyWidths[i]
        local posX = currentX + kW * 0.5
        
        if item.isTendency then
            local keyObj = createTendencyTouchKey(item.data.id, item.data.label, item.data.syls, posX, btnY, kW, heightVal, keyTapCallback)
            keypadGroup:insert(keyObj)
        else
            local keyObj = createTouchKey(item.data.id, item.data.label, item.data.color, posX, btnY, kW, heightVal, keyTapCallback)
            keypadGroup:insert(keyObj)
        end
        
        currentX = currentX + kW + minGap
    end
end

function M.setKeypadMode(currentLevel)
    lvl = currentLevel or 1.1
    if keypadGroup.numChildren then
        for i = keypadGroup.numChildren, 1, -1 do keypadGroup[i]:removeSelf() end
    end

    local major = math.floor(lvl)
    local btnY = screenOriginY + screenH - 30

    -- 1. LEVEL 1: DIATONIC TENDENCY BUTTONS
    if major == 1 then
        local tendList = {}
        if lvl == 1.1 then tendList = { "d-s", "f-m", "t-d" }
        elseif lvl == 1.2 then tendList = { "d-s", "f-m", "t-d", "r-d", "l-s" }
        else tendList = { "d-s", "f-m", "t-d", "r-d", "l-s", "l-t-d", "m-r-d" }
        end

        local items = {}
        for _, tid in ipairs(tendList) do
            if allTendencies[tid] then
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
        end

        layoutRow(items, btnY, 36, function(item)
            return (#item.data.syls > 2) and 1.30 or 1.0
        end)

    -- 2. LEVEL 3: CHROMATIC TENDENCY & SINGLE BUTTONS
    elseif major == 3 then
        if lvl == 3.1 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, btnY, 36)
        elseif lvl == 3.2 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d", "me-r-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, btnY, 36, function(item)
                return (#item.data.syls > 2) and 1.30 or 1.0
            end)
        else -- 3.3 Chromatic Singles ID
            local singles = { "ra", "me", "fi", "le", "te" }
            local items = {}
            for _, keyId in ipairs(singles) do
                table.insert(items, { isTendency = false, data = allChromaticKeys[keyId] })
            end
            layoutRow(items, btnY, 36)
        end

    -- 3. LEVEL 2: SINGLE DIATONIC NOTE ID (SUB-LEVEL FILTERED)
    elseif major == 2 then
        local activeSingles = {}
        if lvl == 2.1 then activeSingles = { "t", "f" }
        elseif lvl == 2.2 then activeSingles = { "t", "f", "r", "l" }
        else activeSingles = { "d", "r", "m", "f", "s", "l", "t" }
        end

        local items = {}
        for _, keyId in ipairs(activeSingles) do
            if allDiatonicKeys[keyId] then
                table.insert(items, { isTendency = false, data = allDiatonicKeys[keyId] })
            end
        end

        layoutRow(items, btnY, 36)

    -- 4. GENERAL LEVELS (4-19): FULL SCREEN DYNAMIC PILL KEYPAD
    else
        local hasChromatics = (major == 6 or major == 9 or major == 10 or major == 12 or major == 14 or major == 15 or major == 17 or major == 18 or major == 19 or lvl == 10.9 or lvl == 19.9)

        local diatonicOrder = { "d", "r", "m", "f", "s", "l", "t" }
        local chromaticOrder = { "ra", "me", "fi", "le", "te" }

        local kH = hasChromatics and 32 or 36
        local diatonicY = screenOriginY + screenH - 26
        local chromaticY = screenOriginY + screenH - 68

        -- Diatonic Row
        local dItems = {}
        for _, keyId in ipairs(diatonicOrder) do
            table.insert(dItems, { isTendency = false, data = allDiatonicKeys[keyId] })
        end
        layoutRow(dItems, diatonicY, kH)

        -- Chromatic Row (Staggered Above in Gaps if Level has Chromatics)
        if hasChromatics then
            local availableWidthForKeys = maxUsableWidth - (6 * minGap)
            local kW = math.floor(availableWidthForKeys / 7)
            local spacing = kW + minGap
            local startX = screenOriginX + (screenW - (7 * kW + 6 * minGap)) * 0.5 + kW * 0.5

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
        local startY = screenOriginY + screenH * 0.42 + ((count - 1) * verticalSpacing * 0.5)
        
        for i = 1, count do
            local entry = userEntries[i]
            local rawName = entry and entry.name or ""
            local pitch = (targetPitches and targetPitches[i]) or (entry and entry.pitch)
            local displayName = formatKodalyName(rawName, pitch, tonicMIDI)
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, "none", centerX, posY, boxSize, isCircle))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES (Temporal sequence)
        local spacing = (count > 4) and 52 or 66
        local startX = centerX - ((count - 1) * spacing * 0.5)
        local posY = screenOriginY + screenH * 0.34
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
        local startY = screenOriginY + screenH * 0.42 + ((count - 1) * verticalSpacing * 0.5)

        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, res.color, centerX, posY, boxSize, false))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES
        local spacing = (count > 4) and 52 or 66
        local startX = centerX - ((count - 1) * spacing * 0.5)
        local posY = screenOriginY + screenH * 0.34
        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            answerGroup:insert(createBox(displayName, res.color, startX + (i - 1) * spacing, posY, boxSize, false))
        end
    end
end

return M