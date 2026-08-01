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
    -- Pitch classes (0..11) belong to the primary octave -> no octave mark
    if midiPitch >= 0 and midiPitch < 12 then
        return name
    end
    local lowBound = tonicMIDI or 60
    local highBound = lowBound + 12
    if midiPitch >= highBound then
        return name .. "ˈ"
    elseif midiPitch < lowBound then
        return name .. ","
    end
    return name
end

local function getSyllableColor(syl)
    syl = string.lower(syl or "")
    return boomwhackerColors[syl] or {0.5, 0.5, 0.5}
end

local function createGlassSheen(group, x, y, kW, kH, pillRadius)
    local inset = 4.0 -- 4px inset on all 4 sides (8px smaller overall)
    local sheenW = kW - (inset * 2)
    local sheenH = kH - (inset * 2)
    local sheenRadius = math.floor(sheenH * 0.5) -- Verified Concentric Stadium Pill Radius

    -- 100% Verified Concentric Stadium Pill Shape
    local sheen = display.newRoundedRect(group, x, y, sheenW, sheenH, sheenRadius)
    
    -- Vertical gradient fill: 25% white opacity at top edge dropping to 0% opacity at 33% down
    sheen.fill = {
        type = "gradient",
        color1 = { 1, 1, 1, 0.25 },
        color2 = { 1, 1, 1, 0.00 },
        direction = "down"
    }
    sheen.fill.scaleY = 0.33
    sheen.fill.y = -0.335

    return sheen
end

local function createTouchKey(keyId, labelText, colorRGB, x, y, kWidth, kHeight, callback)
    local group = display.newGroup()
    local pillRadius = math.floor(kHeight * 0.5) -- True stadium/pill geometry
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 3.0, kWidth, kHeight, pillRadius)
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

    -- 5. Balanced Dark Text Shadow behind Pure White Text (50% Larger Typography)
    local fontSize = (string.len(labelText) > 5) and 16 or ((string.len(labelText) > 2) and 18 or 20)
    
    local txtShadow = display.newText({
        parent = group,
        text = tostring(labelText):lower(),
        x = x + 1, y = y + 1.5,
        font = native.systemFontBold,
        fontSize = fontSize
    })
    txtShadow:setFillColor(0, 0, 0, 0.6)

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
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            if isPressed then
                group.y = 0
                isPressed = false
                if callback then callback(keyId) end
            end
            return true
        end
        return false
    end)

    return group
end
local function createTendencyTouchKey(tendencyId, labelText, syllables, x, y, kW, kH, callback)
    local group = display.newGroup()
    local pillRadius = math.floor(kH * 0.5)

    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(group, x, y + 3.0, kW, kH, pillRadius)
    shadow:setFillColor(0, 0, 0, 0.4)

    -- 2. Multi-segment Gradient Fill (2-note or 3-note)
    if #syllables == 2 then
        local c1 = getSyllableColor(syllables[1])
        local c2 = getSyllableColor(syllables[2])
        local rect = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        rect:setFillColor(graphics.newGradient(c1, c2, "right"))
    elseif #syllables == 3 then
        local c1 = getSyllableColor(syllables[1])
        local c2 = getSyllableColor(syllables[2])
        local c3 = getSyllableColor(syllables[3])

        local m12 = { (c1[1] + c2[1]) * 0.5, (c1[2] + c2[2]) * 0.5, (c1[3] + c2[3]) * 0.5 }
        local m23 = { (c2[1] + c3[1]) * 0.5, (c2[2] + c3[2]) * 0.5, (c2[3] + c3[3]) * 0.5 }

        -- 1. Outer Base Pill (filled with c2 color)
        local basePill = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        basePill:setFillColor(unpack(c2))

        -- 2. Left End Cap (c1 -> c2, direction "right")
        local leftCap = display.newRoundedRect(group, x - kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        leftCap:setFillColor(graphics.newGradient(c1, c2, "right"))

        -- 3. Right End Cap (c2 -> c3, direction "right")
        local rightCap = display.newRoundedRect(group, x + kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        rightCap:setFillColor(graphics.newGradient(c2, c3, "right"))

        -- 4. Middle Transition Rects (Starts at midpoint of left cap to midpoint of right cap)
        local midLeft = display.newRect(group, x - kW * 0.125, y, kW * 0.25, kH - 2)
        midLeft:setFillColor(graphics.newGradient(m12, c2, "right"))

        local midRight = display.newRect(group, x + kW * 0.125, y, kW * 0.25, kH - 2)
        midRight:setFillColor(graphics.newGradient(c2, m23, "right"))
    end

    -- 3. Glass Border Frame Overlay
    local border = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
    border.strokeWidth = 2
    border:setStrokeColor(1, 1, 1, 0.45)
    border:setFillColor(0, 0, 0, 0)

    -- 4. Top Concentric Glass Sheen Highlight
    createGlassSheen(group, x, y, kW, kH, pillRadius)

    -- 5. Text Shadow & Pure White Text (50% Larger Typography)
    local fontSize = (string.len(labelText) > 6) and 15 or 17
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

local navCallbacks = {}
local headerGroup = nil

local function createPillButton(parent, labelText, x, y, width, height, colorRGB, fontSZ, callback)
    local grp = display.newGroup()
    local radius = math.floor(height * 0.5)
    
    local bg = display.newRoundedRect(grp, x, y, width, height, radius)
    bg:setFillColor(unpack(colorRGB))
    
    local border = display.newRoundedRect(grp, x, y, width, height, radius)
    border.strokeWidth = 1.5
    border:setStrokeColor(1, 1, 1, 0.4)
    border:setFillColor(0, 0, 0, 0)
    
    local txt = display.newText({
        parent = grp,
        text = labelText,
        x = x, y = y,
        font = native.systemFontBold,
        fontSize = fontSZ or 14
    })
    txt:setFillColor(1, 1, 1, 1)

    grp:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(grp)
            grp.y = 1.5
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            grp.y = 0
            if callback then callback() end
            return true
        end
        return false
    end)

    if parent then parent:insert(grp) end
    return grp
end

function M.init(onKeyTap, callbacks)
    keyTapCallback = onKeyTap
    navCallbacks = callbacks or {}
    
    if headerGroup and headerGroup.removeSelf then headerGroup:removeSelf() end
    headerGroup = display.newGroup()

    -- 1. Top Left: Session Score (Bold Gold Typography)
    sessionText = display.newText({
        parent = headerGroup,
        text = "score: 0",
        x = screenOriginX + 70,
        y = screenOriginY + 24,
        font = native.systemFontBold,
        fontSize = 22
    })
    sessionText:setFillColor(1, 0.85, 0.3)

    -- 2. Top Center: Level Navigation (« ◀ level 1.1 ▶ »)
    createPillButton(headerGroup, "«", centerX - 132, screenOriginY + 24, 38, 36, {0.2, 0.2, 0.25}, 18, function()
        if navCallbacks.onPrevMajorLevel then navCallbacks.onPrevMajorLevel() end
    end)

    createPillButton(headerGroup, "◀", centerX - 88, screenOriginY + 24, 38, 36, {0.25, 0.25, 0.3}, 18, function()
        if navCallbacks.onPrevLevel then navCallbacks.onPrevLevel() end
    end)
    
    levelText = display.newText({
        parent = headerGroup,
        text = "level: 1.1",
        x = centerX,
        y = screenOriginY + 24,
        font = native.systemFontBold,
        fontSize = 25
    })
    
    createPillButton(headerGroup, "▶", centerX + 88, screenOriginY + 24, 38, 36, {0.25, 0.25, 0.3}, 18, function()
        if navCallbacks.onNextLevel then navCallbacks.onNextLevel() end
    end)

    createPillButton(headerGroup, "»", centerX + 132, screenOriginY + 24, 38, 36, {0.2, 0.2, 0.25}, 18, function()
        if navCallbacks.onNextMajorLevel then navCallbacks.onNextMajorLevel() end
    end)

    descText = display.newText({
        parent = headerGroup,
        text = "initializing...",
        x = centerX,
        y = screenOriginY + 52,
        font = native.systemFont,
        fontSize = 18
    })
    descText:setFillColor(0.75, 0.75, 0.75)

    -- 3. Top Right: Audio Touch Controls (Cadence & Replay)
    createPillButton(headerGroup, "cadence", screenOriginX + screenW - 155, screenOriginY + 24, 82, 36, {0.15, 0.35, 0.6}, 14, function()
        if navCallbacks.onCadence then navCallbacks.onCadence() end
    end)
    createPillButton(headerGroup, "replay", screenOriginX + screenW - 68, screenOriginY + 24, 72, 36, {0.2, 0.45, 0.2}, 14, function()
        if navCallbacks.onReplay then navCallbacks.onReplay() end
    end)

    -- 4. Feedback / Start Banner
    feedbackText = display.newText({
        parent = headerGroup,
        text = "tap here to start exercise",
        x = centerX,
        y = screenOriginY + 84,
        width = screenW * 0.9,
        align = "center",
        font = native.systemFontBold,
        fontSize = 28
    })
    
    -- Interactive Banner Touch Listener
    feedbackText:addEventListener("touch", function(event)
        if event.phase == "ended" then
            if navCallbacks.onPrimaryAction then navCallbacks.onPrimaryAction() end
        end
        return true
    end)
    
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

    -- 3. Compute exact pixel widths with Maximum Width Caps (prevents massive keys on 3-item rows)
    local keyWidths = {}
    local totalRowWidth = 0
    for i = 1, count do
        local rawKw = math.floor((availableWidthForKeys * weights[i]) / totalWeight)
        local item = items[i]
        local maxKW = item.isTendency and 130 or 96
        local kw = math.min(rawKw, maxKW)
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

function M.setKeypadMode(levelId)
    if keypadGroup.numChildren then
        for i = keypadGroup.numChildren, 1, -1 do keypadGroup[i]:removeSelf() end
    end

    local lvl = tonumber(levelId) or 1.1
    local major = math.floor(lvl)

    -- 1. LEVEL 1: DIATONIC TENDENCY BUTTONS (SUB-LEVEL FILTERED)
    if major == 1 then
        local tendList = {}
        if lvl == 1.1 then tendList = { "d-s", "f-m", "t-d" }
        elseif lvl == 1.2 then tendList = { "d-s", "f-m", "t-d", "r-d", "l-s" }
        else tendList = { "d-s", "f-m", "t-d", "r-d", "l-s", "l-t-d", "m-r-d" }
        end

        local items = {}
        for _, tid in ipairs(tendList) do
            table.insert(items, { isTendency = true, data = allTendencies[tid] })
        end

        local btnY = screenOriginY + screenH - 36
        layoutRow(items, btnY, 48)

    -- 2. LEVEL 3: CHROMATIC TENDENCIES (SUB-LEVEL FILTERED)
    elseif major == 3 and lvl ~= 3.3 then
        local btnY = screenOriginY + screenH - 36
        if lvl == 3.1 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, btnY, 48)
        elseif lvl == 3.2 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d", "me-r-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, btnY, 48)
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

        layoutRow(items, screenOriginY + screenH - 36, 48)

    -- 4. GENERAL LEVELS (3.3 & 4-19): FULL SCREEN DYNAMIC PILL KEYPAD
    else
        local hasChromatics = (lvl == 3.3 or major == 6 or major == 9 or major == 10 or major == 12 or major == 14 or major == 15 or major == 17 or major == 18 or major == 19 or lvl == 10.9 or lvl == 19.9)

        local diatonicOrder = { "d", "r", "m", "f", "s", "l", "t" }
        local chromaticOrder = { "ra", "me", "fi", "le", "te" }

        local kH = hasChromatics and 42 or 48
        local diatonicY = screenOriginY + screenH - 32
        local chromaticY = screenOriginY + screenH - 80

        -- 1. Calculate Diatonic Geometry First (Screen-Proportional Math)
        local availableWidthForKeys = maxUsableWidth - (6 * minGap)
        local rawKw = math.floor(availableWidthForKeys / 7)
        local diatonicKW = math.min(rawKw, 96)
        local diatonicRowWidth = 7 * diatonicKW + 6 * minGap
        local diatonicStartX = screenOriginX + (screenW - diatonicRowWidth) * 0.5 + diatonicKW * 0.5
        local diatonicSpacing = diatonicKW + minGap

        -- 2. Draw Diatonic Row
        for i, keyId in ipairs(diatonicOrder) do
            local posX = diatonicStartX + (i - 1) * diatonicSpacing
            local dData = allDiatonicKeys[keyId]
            local keyObj = createTouchKey(dData.id, dData.label, dData.color, posX, diatonicY, diatonicKW, kH, keyTapCallback)
            keypadGroup:insert(keyObj)
        end

        -- 3. Draw Chromatic Row (Proportionally sized & positioned directly above diatonic gaps)
        if hasChromatics then
            local chromaticKW = math.floor(diatonicKW * 0.92)
            for i, keyId in ipairs(chromaticOrder) do
                local cData = allChromaticKeys[keyId]
                local targetX = diatonicStartX + (cData.posIndex - 1) * diatonicSpacing
                local keyObj = createTouchKey(cData.id, cData.label, cData.color, targetX, chromaticY, chromaticKW, kH, keyTapCallback)
                keypadGroup:insert(keyObj)
            end
        end
    end
end

function M.updateStatus(lvl, desc)
    if levelText then levelText.text = "level: " .. tostring(lvl) end
    if descText then descText.text = tostring(desc):lower() end
    M.setKeypadMode(lvl)
end

local currentExerciseIsStack = false

function M.showFeedback(msg, statusType, isStack)
    if isStack ~= nil then currentExerciseIsStack = isStack end
    if feedbackText then
        feedbackText.text = tostring(msg):lower()
        if currentExerciseIsStack then
            -- Position cleanly on the right side of vertical stack boxes
            feedbackText.x = screenOriginX + screenW * 0.74
            feedbackText.y = screenOriginY + screenH * 0.36
            feedbackText.width = screenW * 0.38
        else
            -- Center position for horizontal melodies
            feedbackText.x = centerX
            feedbackText.y = screenOriginY + 84
            feedbackText.width = screenW * 0.9
        end

        if statusType == "correct" then
            feedbackText:setFillColor(0.3, 0.95, 0.4)
        elseif statusType == "wrong" then
            feedbackText:setFillColor(1, 0.35, 0.35)
        elseif statusType == "correction" then
            feedbackText:setFillColor(1, 0.85, 0.25)
        else
            feedbackText:setFillColor(1, 1, 1)
        end
    end
end

function M.updateSessionScore(score)
    if sessionText then
        sessionText.text = "score: " .. tostring(score)
    end
end

local function createBox(name, color, x, y, size, isCircle)
    local group = display.newGroup()
    local rect
    if isCircle then
        rect = display.newCircle(group, x, y, size * 0.48)
    else
        rect = display.newRoundedRect(group, x, y, size, size, size * 0.16)
    end
    rect.strokeWidth = 3.5
    rect:setStrokeColor(unpack(colors[color]))
    rect:setFillColor(0, 0, 0, 0.35)

    local txt = display.newText({
        parent = group,
        text = tostring(name):lower(),
        x = x, y = y,
        font = native.systemFontBold, 
        fontSize = size * 0.38
    })
    txt:setFillColor(unpack(colors[color]))

    return group
end

function M.updateAnswerBuffer(userEntries, count, isCircle, isStack, targetPitches, tonicMIDI)
    currentExerciseIsStack = (isStack == true)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end

    local boxSize = (count > 4) and 56 or 68
    
    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS (Bass at bottom, Soprano at top)
        local verticalSpacing = (count > 3) and 60 or 70
        local startY = screenOriginY + screenH * 0.44 + ((count - 1) * verticalSpacing * 0.5)
        
        for i = 1, count do
            local entry = userEntries[i]
            local displayName = entry and entry.name or ""
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, "none", centerX, posY, boxSize, isCircle))
        end

        -- Mobile SUBMIT touch button for multi-note stacks
        if not isCircle and #userEntries == count and count > 1 then
            createPillButton(answerGroup, "↵ submit", centerX + boxSize + 48, startY - ((count - 1) * verticalSpacing * 0.5), 84, 38, {0.2, 0.7, 0.3}, 15, function()
                if navCallbacks.onPrimaryAction then navCallbacks.onPrimaryAction() end
            end)
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES (Temporal sequence)
        local spacing = (count > 4) and 66 or 82
        local startX = centerX - ((count - 1) * spacing * 0.5)
        local posY = screenOriginY + screenH * 0.36
        for i = 1, count do
            local entry = userEntries[i]
            local displayName = entry and entry.name or ""
            answerGroup:insert(createBox(displayName, "none", startX + (i - 1) * spacing, posY, boxSize, isCircle))
        end

        -- Mobile SUBMIT touch button for multi-note melodies
        if not isCircle and count > 1 then
            local submitX = startX + (count - 1) * spacing + boxSize * 0.5 + 56
            createPillButton(answerGroup, "↵ submit", math.min(screenOriginX + maxUsableWidth - 45, submitX), posY, 84, 38, {0.2, 0.7, 0.3}, 15, function()
                if navCallbacks.onPrimaryAction then navCallbacks.onPrimaryAction() end
            end)
        end
    end
end

function M.updateAnswerBufferFromResults(results, isStack, targetPitches, tonicMIDI)
    currentExerciseIsStack = (isStack == true)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end
    local count = #results
    local boxSize = (count > 4) and 56 or 68

    if isStack then
        -- SPATIALIZED VERTICAL BUFFER FOR STACKS
        local verticalSpacing = (count > 3) and 60 or 70
        local startY = screenOriginY + screenH * 0.44 + ((count - 1) * verticalSpacing * 0.5)

        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            local posY = startY - (i - 1) * verticalSpacing
            answerGroup:insert(createBox(displayName, res.color, centerX, posY, boxSize, false))
        end
    else
        -- HORIZONTAL BUFFER FOR MELODIES
        local spacing = (count > 4) and 66 or 82
        local startX = centerX - ((count - 1) * spacing * 0.5)
        local posY = screenOriginY + screenH * 0.36
        for i = 1, count do
            local res = results[i]
            local pitch = targetPitches and targetPitches[i]
            local displayName = formatKodalyName(res.name, pitch, tonicMIDI)
            answerGroup:insert(createBox(displayName, res.color, startX + (i - 1) * spacing, posY, boxSize, false))
        end
    end
end

return M