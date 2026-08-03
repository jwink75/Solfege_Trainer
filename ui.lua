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
local centerY = screenOriginY + screenH * 0.5

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
    if not name or name == "" then return "" end
    if not midiPitch then return name end
    
    local tonic = tonicMIDI or 60
    -- Convert relative pitch offset (-2, 0, 7, 14, etc.) to absolute MIDI pitch
    local absPitch = (midiPitch < 30) and (tonic + midiPitch) or midiPitch

    local lowBound = tonic
    local highBound = tonic + 12

    if absPitch >= highBound then
        return name .. "ˈ" -- High vertical line U+02C8
    elseif absPitch < lowBound then
        return name .. "ˌ" -- Low vertical line U+02CC
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
        color1 = {1, 1, 1, 0.25},
        color2 = {1, 1, 1, 0.0},
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

    -- 2. Base Colored Rounded Rect Pill
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
            display.getCurrentStage():setFocus(event.target)
            isPressed = true
            group.y = 2
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            group.y = 0
            if isPressed then
                isPressed = false
                if keyTapCallback then
                    timer.performWithDelay(1, function()
                        keyTapCallback(keyId)
                    end)
                end
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

        local basePill = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
        basePill:setFillColor(unpack(c2))

        local leftCap = display.newRoundedRect(group, x - kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        leftCap:setFillColor(graphics.newGradient(c1, c2, "right"))

        local rightCap = display.newRoundedRect(group, x + kW * 0.25, y, kW * 0.50, kH - 2, pillRadius - 1)
        rightCap:setFillColor(graphics.newGradient(c2, c3, "right"))

        local midLeft = display.newRect(group, x - kW * 0.125, y, kW * 0.25, kH - 2)
        midLeft:setFillColor(graphics.newGradient(m12, c2, "right"))

        local midRight = display.newRect(group, x + kW * 0.125, y, kW * 0.25, kH - 2)
        midRight:setFillColor(graphics.newGradient(c2, m23, "right"))
    end

    local border = display.newRoundedRect(group, x, y, kW, kH, pillRadius)
    border.strokeWidth = 2
    border:setStrokeColor(1, 1, 1, 0.45)
    border:setFillColor(0, 0, 0, 0)

    createGlassSheen(group, x, y, kW, kH, pillRadius)

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

    local isPressed = false
    group:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(event.target)
            isPressed = true
            group.y = 2
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            group.y = 0
            if isPressed then
                isPressed = false
                if callback then
                    timer.performWithDelay(1, function()
                        callback(tendencyId)
                    end)
                end
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
    
    -- 1. 3D Bottom Drop Shadow
    local shadow = display.newRoundedRect(grp, x, y + 2.0, width, height, radius)
    shadow:setFillColor(0, 0, 0, 0.35)

    -- 2. Base Colored Rounded Rect Pill
    local bg = display.newRoundedRect(grp, x, y, width, height, radius)
    bg:setFillColor(unpack(colorRGB))
    bg.isHitTestable = true
    
    -- 3. Glass Border Frame Overlay
    local border = display.newRoundedRect(grp, x, y, width, height, radius)
    border.strokeWidth = 1.5
    border:setStrokeColor(1, 1, 1, 0.45)
    border:setFillColor(0, 0, 0, 0)
    
    -- 4. Concentric Glass Sheen Overlay
    createGlassSheen(grp, x, y, width, height, radius)

    -- 5. Text Shadow & Pure White Text
    local txtShadow = display.newText({
        parent = grp,
        text = labelText,
        x = x + 1, y = y + 1.2,
        font = native.systemFontBold,
        fontSize = fontSZ or 14
    })
    txtShadow:setFillColor(0, 0, 0, 0.55)

    local txt = display.newText({
        parent = grp,
        text = labelText,
        x = x, y = y,
        font = native.systemFontBold,
        fontSize = fontSZ or 14
    })
    txt:setFillColor(1, 1, 1, 1)

    bg:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(event.target)
            transition.to(grp, { time=50, xScale=0.95, yScale=0.95 })
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            transition.to(grp, { time=60, xScale=1.0, yScale=1.0 })
            if callback then
                timer.performWithDelay(1, function()
                    callback()
                end)
            end
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

    local headerY = screenOriginY + math.max(22, screenH * 0.05)
    local subY = screenOriginY + math.max(48, screenH * 0.11)
    local statusY = screenOriginY + math.max(78, screenH * 0.18)

    -- 3. Left Edge: Audio Touch Controls (Play Key & Question) - Centered Vertically
    local leftAudioX = screenOriginX + math.max(52, screenW * 0.08)
    local audioY = screenOriginY + screenH * 0.36

    -- 1. Top Left: User Profile Control & Session Score (aligned to left edge of play key/question buttons)
    local userBtnW = 118
    local userBtnX = (leftAudioX - 43) + userBtnW * 0.5
    local activeName = (navCallbacks and navCallbacks.getActiveUserName) and navCallbacks.getActiveUserName() or "Sign In"
    
    createPillButton(headerGroup, "👤 " .. activeName, userBtnX, headerY, userBtnW, 34, {0.2, 0.3, 0.45}, 13, function()
        if navCallbacks.onUserMenu then navCallbacks.onUserMenu() end
    end)

    sessionText = display.newText({
        parent = headerGroup,
        text = "score: 0",
        x = userBtnX,
        y = headerY + 26,
        font = native.systemFontBold,
        fontSize = 15
    })
    sessionText:setFillColor(1, 0.85, 0.3)
    
    createPillButton(headerGroup, "play key", leftAudioX, audioY - 23, 86, 38, {0.15, 0.35, 0.6}, 14, function()
        if navCallbacks.onCadence then navCallbacks.onCadence() end
    end)
    createPillButton(headerGroup, "question", leftAudioX, audioY + 23, 86, 38, {0.2, 0.45, 0.2}, 14, function()
        if navCallbacks.onReplay then navCallbacks.onReplay() end
    end)
    createPillButton(headerGroup, "«", centerX - 132, headerY, 38, 36, {0.2, 0.2, 0.25}, 18, function()
        if navCallbacks.onPrevMajorLevel then navCallbacks.onPrevMajorLevel() end
    end)

    createPillButton(headerGroup, "◀", centerX - 88, headerY, 38, 36, {0.25, 0.25, 0.3}, 18, function()
        if navCallbacks.onPrevLevel then navCallbacks.onPrevLevel() end
    end)
    
    levelText = display.newText({
        parent = headerGroup,
        text = "level: 1.1",
        x = centerX,
        y = headerY,
        font = native.systemFontBold,
        fontSize = 25
    })
    
    createPillButton(headerGroup, "▶", centerX + 88, headerY, 38, 36, {0.25, 0.25, 0.3}, 18, function()
        if navCallbacks.onNextLevel then navCallbacks.onNextLevel() end
    end)

    createPillButton(headerGroup, "»", centerX + 132, headerY, 38, 36, {0.2, 0.2, 0.25}, 18, function()
        if navCallbacks.onNextMajorLevel then navCallbacks.onNextMajorLevel() end
    end)

    descText = display.newText({
        parent = headerGroup,
        text = "initializing...",
        x = centerX,
        y = subY,
        font = native.systemFont,
        fontSize = 18
    })
    descText:setFillColor(0.75, 0.75, 0.75)

    -- 4. Feedback / Start Banner
    feedbackText = display.newText({
        parent = headerGroup,
        text = "tap here to start exercise",
        x = centerX,
        y = statusY,
        width = screenW * 0.9,
        align = "center",
        font = native.systemFontBold,
        fontSize = 28
    })
    
    -- Interactive Banner Touch Listener
    feedbackText:addEventListener("touch", function(event)
        if event.phase == "ended" then
            if navCallbacks.onPrimaryAction then
                timer.performWithDelay(1, function()
                    navCallbacks.onPrimaryAction()
                end)
            end
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

    local homeRowY = screenOriginY + screenH - math.max(32, screenH * 0.08)
    local chromaticY = screenOriginY + screenH - math.max(78, screenH * 0.21)
    local kH = 42 -- Uniform shorter height requested across all levels

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

        layoutRow(items, homeRowY, kH)

    -- 2. LEVEL 5: CHROMATIC TENDENCIES (SUB-LEVEL FILTERED)
    elseif major == 5 and lvl ~= 5.3 then
        if lvl == 5.1 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, homeRowY, kH)
        elseif lvl == 5.2 then
            local tendList = { "fi-s", "le-s", "ra-d", "te-d", "me-r-d" }
            local items = {}
            for _, tid in ipairs(tendList) do
                table.insert(items, { isTendency = true, data = allTendencies[tid] })
            end
            layoutRow(items, homeRowY, kH)
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

        layoutRow(items, homeRowY, kH)

    -- 4. GENERAL LEVELS (3.x & 4-19): FULL SCREEN DYNAMIC PILL KEYPAD
    else
        local hasChromatics = (lvl == 5.3 or major == 6 or major == 9 or major == 10 or major == 12 or major == 14 or major == 15 or major == 17 or major == 18 or major == 19 or lvl == 10.9 or lvl == 19.9)

        local diatonicOrder = { "d", "r", "m", "f", "s", "l", "t" }
        local chromaticOrder = { "ra", "me", "fi", "le", "te" }

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
            local keyObj = createTouchKey(dData.id, dData.label, dData.color, posX, homeRowY, diatonicKW, kH, keyTapCallback)
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
            feedbackText.y = screenOriginY + math.max(78, screenH * 0.18)
            feedbackText.width = screenW * 0.9
        end

        if statusType == "correct" then
            feedbackText:setFillColor(0.3, 0.95, 0.4)
        elseif statusType == "wrong" then
            feedbackText:setFillColor(1, 0.35, 0.35)
            local origX = feedbackText.x
            transition.to(feedbackText, { time=30, x=origX - 6, onComplete=function()
                transition.to(feedbackText, { time=30, x=origX + 6, onComplete=function()
                    transition.to(feedbackText, { time=30, x=origX - 4, onComplete=function()
                        transition.to(feedbackText, { time=30, x=origX })
                    end })
                end })
            end })
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

        -- Far-Right Side Action Buttons (Delete above Submit), perfectly mirroring Left Audio Pair
        local rightActionX = screenOriginX + screenW - math.max(52, screenW * 0.08)
        local midY = screenOriginY + screenH * 0.36

        if not isCircle and #userEntries > 0 then
            createPillButton(answerGroup, "⌫ del", rightActionX, midY - 23, 86, 38, {0.6, 0.25, 0.25}, 15, function()
                if navCallbacks.onDeleteAction then navCallbacks.onDeleteAction() end
            end)
        end

        if not isCircle and #userEntries == count and count > 1 then
            createPillButton(answerGroup, "↵ submit", rightActionX, midY + 23, 86, 38, {0.2, 0.7, 0.3}, 15, function()
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

        -- Far-Right Side Action Buttons (Delete above Submit), perfectly mirroring Left Audio Pair
        local rightActionX = screenOriginX + screenW - math.max(52, screenW * 0.08)

        if not isCircle and #userEntries > 0 then
            createPillButton(answerGroup, "⌫ del", rightActionX, posY - 23, 86, 38, {0.6, 0.25, 0.25}, 15, function()
                if navCallbacks.onDeleteAction then navCallbacks.onDeleteAction() end
            end)
        end

        if not isCircle and count > 1 then
            createPillButton(answerGroup, "↵ submit", rightActionX, posY + 23, 86, 38, {0.2, 0.7, 0.3}, 15, function()
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

---------------------------------------------------------
-- MODAL & USER PROFILE DIALOG INFRASTRUCTURE
---------------------------------------------------------
local currentModalGroup = nil
local nativeInput = nil

local currentPitchDetailGroup = nil

local function closePitchDetailModal()
    if currentPitchDetailGroup then
        if currentPitchDetailGroup.removeSelf then currentPitchDetailGroup:removeSelf() end
        currentPitchDetailGroup = nil
    end
end

local function closeModal()
    closePitchDetailModal()
    if nativeInput and nativeInput.removeSelf then
        nativeInput:removeSelf()
        nativeInput = nil
    end
    if currentModalGroup and currentModalGroup.removeSelf then
        currentModalGroup:removeSelf()
        currentModalGroup = nil
    end
end

function M.closeModal()
    closeModal()
end

function M.isModalActive()
    return (currentPitchDetailGroup ~= nil) or (currentModalGroup ~= nil)
end

function M.closeActiveModal()
    if currentPitchDetailGroup then
        closePitchDetailModal()
        return true
    elseif currentModalGroup then
        closeModal()
        return true
    end
    return false
end

local function createModalBackdrop(parentGroup)
    local backdrop = display.newRect(parentGroup, centerX, centerY, screenW * 2, screenH * 2)
    backdrop:setFillColor(0, 0, 0, 0.65)
    backdrop.isHitTestable = true
    backdrop:addEventListener("touch", function(event)
        if event.phase == "ended" then
            timer.performWithDelay(1, function()
                closeModal()
            end)
        end
        return true
    end)
    return backdrop
end

local function createModalCard(parentGroup, width, height, titleText)
    local grp = display.newGroup()
    parentGroup:insert(grp)

    local cardShadow = display.newRoundedRect(grp, centerX, centerY + 3, width, height, 18)
    cardShadow:setFillColor(0, 0, 0, 0.4)

    local cardBg = display.newRoundedRect(grp, centerX, centerY, width, height, 18)
    cardBg:setFillColor(0.12, 0.14, 0.18, 0.96)
    cardBg.isHitTestable = true
    cardBg:addEventListener("touch", function(event)
        return true -- Absorb touch inside modal card so clicking inside stats display does NOT close it!
    end)

    local cardBorder = display.newRoundedRect(grp, centerX, centerY, width, height, 18)
    cardBorder.strokeWidth = 2
    cardBorder:setStrokeColor(0.3, 0.45, 0.65, 0.8)
    cardBorder:setFillColor(0, 0, 0, 0)

    if titleText then
        local title = display.newText({
            parent = grp,
            text = titleText:lower(),
            x = centerX,
            y = centerY - height * 0.5 + 28,
            font = native.systemFontBold,
            fontSize = 20
        })
        title:setFillColor(1, 0.85, 0.3)
    end

    -- Close [ X ] Target (Bright Red)
    local closeBtnX = centerX + width * 0.5 - 24
    local closeBtnY = centerY - height * 0.5 + 24
    createPillButton(grp, "✕", closeBtnX, closeBtnY, 32, 32, {0.9, 0.18, 0.22}, 16, function()
        closeModal()
    end)

    return grp
end

function M.showUserMenu(userName, isSignedIn, callbacks)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = 240
    local cardH = isSignedIn and 220 or 150
    local card = createModalCard(currentModalGroup, cardW, cardH, "User Menu")

    local startY = centerY - (isSignedIn and 30 or 10)

    if isSignedIn then
        createPillButton(card, "stats", centerX, startY, 180, 38, {0.2, 0.45, 0.65}, 15, function()
            closeModal()
            if callbacks.onStats then callbacks.onStats() end
        end)

        createPillButton(card, "settings", centerX, startY + 48, 180, 38, {0.3, 0.3, 0.4}, 15, function()
            closeModal()
            if callbacks.onSettings then callbacks.onSettings() end
        end)

        createPillButton(card, "sign out", centerX, startY + 96, 180, 38, {0.55, 0.25, 0.25}, 15, function()
            closeModal()
            if callbacks.onSignOut then callbacks.onSignOut() end
        end)
    else
        createPillButton(card, "sign in", centerX, startY + 20, 180, 42, {0.2, 0.55, 0.35}, 16, function()
            closeModal()
            if callbacks.onSignIn then callbacks.onSignIn() end
        end)
    end
end

function M.showSignInModal(profiles, onSelectProfile, onNewUser)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local count = #profiles
    local cardW = 340
    local cardH = math.min(screenH * 0.8, 140 + count * 44)
    local card = createModalCard(currentModalGroup, cardW, cardH, "Select User Profile")

    local startY = centerY - cardH * 0.5 + 75

    for i, prof in ipairs(profiles) do
        local posY = startY + (i - 1) * 44
        local btnColor = prof.isActive and {0.2, 0.55, 0.35} or {0.2, 0.25, 0.35}
        local label = prof.name .. (prof.isActive and "  ✓" or "")
        createPillButton(card, label, centerX, posY, 260, 36, btnColor, 14, function()
            closeModal()
            if onSelectProfile then onSelectProfile(prof.id) end
        end)
    end

    local newUserY = startY + count * 44 + 8
    createPillButton(card, "+ new user", centerX, newUserY, 260, 38, {0.15, 0.4, 0.65}, 15, function()
        closeModal()
        if onNewUser then onNewUser() end
    end)
end

function M.showNewUserModal(onCreateProfile)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = 360
    local cardH = 220
    local card = createModalCard(currentModalGroup, cardW, cardH, "Create New User")

    local prompt = display.newText({
        parent = card,
        text = "enter profile name (max 16 chars):",
        x = centerX,
        y = centerY - 35,
        font = native.systemFont,
        fontSize = 14
    })
    prompt:setFillColor(0.8, 0.8, 0.8)

    nativeInput = native.newTextField(centerX, centerY, 240, 36)
    nativeInput.font = native.newFont(native.systemFontBold, 16)
    nativeInput.placeholder = "Student Name"
    nativeInput:addEventListener("userInput", function(event)
        if event.phase == "editing" then
            if #event.text > 16 then
                nativeInput.text = string.sub(event.text, 1, 16)
            end
        end
    end)

    createPillButton(card, "create profile", centerX - 65, centerY + 52, 130, 38, {0.2, 0.55, 0.35}, 14, function()
        local nameStr = nativeInput and nativeInput.text or ""
        closeModal()
        if onCreateProfile then onCreateProfile(nameStr) end
    end)

    createPillButton(card, "cancel", centerX + 65, centerY + 52, 110, 38, {0.4, 0.25, 0.25}, 14, function()
        closeModal()
    end)
end

function M.showSettingsModal(profileName, onDeleteProfile)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = 320
    local cardH = 200
    local card = createModalCard(currentModalGroup, cardW, cardH, "Profile Settings")

    local info = display.newText({
        parent = card,
        text = "active user: " .. tostring(profileName),
        x = centerX,
        y = centerY - 20,
        font = native.systemFontBold,
        fontSize = 16
    })
    info:setFillColor(0.9, 0.9, 0.9)

    createPillButton(card, "delete profile", centerX, centerY + 30, 200, 38, {0.6, 0.2, 0.2}, 14, function()
        closeModal()
        if onDeleteProfile then onDeleteProfile() end
    end)
end

function M.showDeleteConfirmModal(profileName, onConfirmDelete)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = 360
    local cardH = 200
    local card = createModalCard(currentModalGroup, cardW, cardH, "Confirm Deletion")

    local warnMsg = display.newText({
        parent = card,
        text = "are you sure you want to delete profile\n'" .. tostring(profileName) .. "'?",
        x = centerX,
        y = centerY - 25,
        width = 300,
        align = "center",
        font = native.systemFontBold,
        fontSize = 15
    })
    warnMsg:setFillColor(1, 0.4, 0.4)

    createPillButton(card, "yes, delete", centerX - 70, centerY + 42, 130, 38, {0.65, 0.2, 0.2}, 14, function()
        closeModal()
        if onConfirmDelete then onConfirmDelete() end
    end)

    createPillButton(card, "cancel", centerX + 70, centerY + 42, 110, 38, {0.3, 0.35, 0.4}, 14, function()
        closeModal()
    end)
end

function M.showResetStatsConfirmModal(profileName, onConfirmReset)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = 360
    local cardH = 180
    local card = createModalCard(currentModalGroup, cardW, cardH, "Confirm Reset Stats")

    local warnMsg = display.newText({
        parent = card,
        text = "are you sure you want to reset all stats for\nprofile '" .. tostring(profileName) .. "'?",
        x = centerX,
        y = centerY - 25,
        width = 320,
        align = "center",
        font = native.systemFontBold,
        fontSize = 15
    })
    warnMsg:setFillColor(1, 0.4, 0.4)

    createPillButton(card, "yes, reset stats", centerX - 80, centerY + 38, 140, 36, {0.9, 0.18, 0.22}, 13, function()
        closeModal()
        if onConfirmReset then onConfirmReset() end
    end)

    createPillButton(card, "cancel", centerX + 80, centerY + 38, 100, 36, {0.3, 0.35, 0.4}, 14, function()
        closeModal()
    end)
end

local currentGraphViewMode = "total"

function M.showStatsModal(statsSummary, diatonicStats, chromaticStats, graphData)
    closeModal()
    currentModalGroup = display.newGroup()
    createModalBackdrop(currentModalGroup)

    local cardW = math.min(screenW * 0.94, 760)
    local cardH = math.min(screenH * 0.90, 460)
    local card = createModalCard(currentModalGroup, cardW, cardH, "Ear Training Stats")

    -- 1. Summary Cards Row (5 metrics: Total Points, Total Accuracy, Longest Streak, Diatonic, Chromatic)
    local cardTopY = centerY - cardH * 0.5 + 82
    local statBoxes = {
        { label = "Total Points", val = tostring(statsSummary.totalPoints or 0) .. " pts" },
        { label = "Total Accuracy", val = statsSummary.correct .. "/" .. statsSummary.questions .. " (" .. statsSummary.accuracy .. "%)" },
        { label = "Longest Streak", val = tostring(statsSummary.bestStreak) },
        { label = "Diatonic", val = diatonicStats.correct .. "/" .. diatonicStats.attempts .. " (" .. diatonicStats.percentage .. "%)" },
        { label = "Chromatic", val = chromaticStats.correct .. "/" .. chromaticStats.attempts .. " (" .. chromaticStats.percentage .. "%)" }
    }

    local colW = (cardW - 40) / 5
    for i, sb in ipairs(statBoxes) do
        local boxX = centerX - cardW * 0.5 + 20 + (i - 0.5) * colW
        
        local bg = display.newRoundedRect(card, boxX, cardTopY, colW - 10, 48, 8)
        bg:setFillColor(0.18, 0.2, 0.26)

        local lbl = display.newText({ parent = card, text = sb.label:lower(), x = boxX, y = cardTopY - 10, font = native.systemFont, fontSize = 11 })
        lbl:setFillColor(0.7, 0.75, 0.85)

        local val = display.newText({ parent = card, text = sb.val, x = boxX, y = cardTopY + 10, font = native.systemFontBold, fontSize = 13 })
        val:setFillColor(1, 0.85, 0.3)
    end

    -- 2. 12-Pitch Dual-Bar & Accuracy Overlay Graph (shifted down 20px below title)
    local graphY = centerY + 78
    local graphW = cardW - 60
    local graphH = 140
    local maxAtt = (graphData.maxAttempts and graphData.maxAttempts > 0) and graphData.maxAttempts or 1

    -- Graph Background Grid
    local graphBg = display.newRect(card, centerX, graphY - graphH * 0.5, graphW, graphH)
    graphBg:setFillColor(0.08, 0.09, 0.12, 0.8)

    local graphBorder = display.newRect(card, centerX, graphY - graphH * 0.5, graphW, graphH)
    graphBorder.strokeWidth = 1
    graphBorder:setStrokeColor(0.25, 0.3, 0.4)
    graphBorder:setFillColor(0, 0, 0, 0)

    -- Graph Axis Line
    local baseline = display.newLine(card, centerX - graphW * 0.5, graphY, centerX + graphW * 0.5, graphY)
    baseline:setStrokeColor(0.4, 0.45, 0.55)

    -- Render 12 Pitch Columns
    local numPitches = 12
    local colSpacing = graphW / numPitches
    local statsModule = require("stats")

    for i, pInfo in ipairs(graphData.pitches) do
        local colX = centerX - graphW * 0.5 + (i - 0.5) * colSpacing

        -- a. Translucent Blue Overlay (Total Accuracy % or Mastery Index)
        local masteryVal = statsModule.getMasteryIndex(pInfo.pitchClass)
        local accPct = (currentGraphViewMode == "total") and ((pInfo.accuracyPct or 0) * 0.01) or masteryVal
        if (pInfo.attempts > 0 or masteryVal > 0) and accPct > 0 then
            local accH = graphH * accPct
            local accOverlay = display.newRect(card, colX, graphY - accH * 0.5, colSpacing - 6, accH)
            accOverlay:setFillColor(0.2, 0.55, 0.95, 0.25)
        end

        -- b. Orange Bar (Right Answers) - Scaled against maxAttempts across all 12 pitches
        if pInfo.correct > 0 then
            local rRatio = pInfo.correct / maxAtt
            local rH = math.max(2, graphH * rRatio)
            local rightBar = display.newRect(card, colX - 4, graphY - rH * 0.5, 5, rH)
            rightBar:setFillColor(1, 0.55, 0)
        end

        -- c. Green Bar (Total Attempts) - Scaled against maxAttempts across all 12 pitches
        if pInfo.attempts > 0 then
            local aRatio = pInfo.attempts / maxAtt
            local aH = math.max(2, graphH * aRatio)
            local attBar = display.newRect(card, colX + 4, graphY - aH * 0.5, 5, aH)
            attBar:setFillColor(0.2, 0.8, 0.35)
        end

        -- d. Solfège Pitch Label under X-axis
        local pitchLbl = display.newText({
            parent = card,
            text = pInfo.label,
            x = colX,
            y = graphY + 16,
            font = native.systemFontBold,
            fontSize = 12
        })
        pitchLbl:setFillColor(0.85, 0.85, 0.85)

        -- e. Floating Text Label clearly above bar (Accuracy % or 2-decimal Mastery Index)
        local pctStr = (currentGraphViewMode == "total") and ((pInfo.attempts > 0) and (pInfo.accuracyPct .. "%") or "-") or ((pInfo.attempts > 0) and string.format("%.2f", masteryVal) or "-")
        local pctLbl = display.newText({
            parent = card,
            text = pctStr,
            x = colX,
            y = graphY - graphH - 12,
            font = native.systemFontBold,
            fontSize = 10
        })
        pctLbl:setFillColor(0.65, 0.82, 1)

        -- f. Interactive Touch Area for Pitch Details Tooltip Popup
        local touchArea = display.newRect(card, colX, graphY - graphH * 0.5, colSpacing - 2, graphH + 36)
        touchArea:setFillColor(0, 0, 0, 0.001)
        touchArea.isHitTestable = true

        local pClass = pInfo.pitchClass
        touchArea:addEventListener("touch", function(event)
            if event.phase == "began" then
                display.getCurrentStage():setFocus(event.target)
                return true
            elseif event.phase == "ended" or event.phase == "cancelled" then
                display.getCurrentStage():setFocus(nil)
                timer.performWithDelay(1, function()
                    local details = statsModule.getPitchDetails(pClass)
                    M.showPitchDetailModal(details)
                end)
                return true
            end
            return false
        end)
    end

    -- Graph Legend
    local legendY = graphY + 38
    local leg1 = display.newRect(card, centerX - 180, legendY, 8, 8)
    leg1:setFillColor(0.95, 0.55, 0.15)
    local leg1Txt = display.newText({ parent = card, text = "correct answers", x = centerX - 130, y = legendY, font = native.systemFont, fontSize = 11 })
    leg1Txt:setFillColor(0.75, 0.75, 0.75)

    local leg2 = display.newRect(card, centerX - 50, legendY, 8, 8)
    leg2:setFillColor(0.2, 0.8, 0.35)
    local leg2Txt = display.newText({ parent = card, text = "total attempts", x = centerX, y = legendY, font = native.systemFont, fontSize = 11 })
    leg2Txt:setFillColor(0.75, 0.75, 0.75)

    local leg3 = display.newRect(card, centerX + 60, legendY, 8, 8)
    leg3:setFillColor(0.2, 0.55, 0.95, 0.5)
    local leg3Txt = display.newText({ parent = card, text = (currentGraphViewMode == "total") and "accuracy %" or "mastery index", x = centerX + 115, y = legendY, font = native.systemFont, fontSize = 11 })
    leg3Txt:setFillColor(0.75, 0.75, 0.75)

    -- Bottom Action Row (View Toggle & Reset All Stats)
    local actionY = graphY + 68
    local toggleTxt = (currentGraphViewMode == "total") and "view: total %" or "view: mastery index"
    createPillButton(card, toggleTxt, centerX - 75, actionY, 130, 26, {0.25, 0.35, 0.5}, 11, function()
        currentGraphViewMode = (currentGraphViewMode == "total") and "mastery" or "total"
        local statsModule = require("stats")
        M.showStatsModal(statsModule.getSummary(), statsModule.getDiatonicStats(), statsModule.getChromaticStats(), statsModule.getPitchGraphData())
    end)

    createPillButton(card, "reset all stats", centerX + 75, actionY, 110, 26, {0.6, 0.2, 0.2}, 11, function()
        local activeProf = statsModule.getActiveProfile()
        local profName = activeProf and activeProf.name or "User"
        M.showResetStatsConfirmModal(profName, function()
            statsModule.resetProfileStats()
            M.showStatsModal(statsModule.getSummary(), statsModule.getDiatonicStats(), statsModule.getChromaticStats(), statsModule.getPitchGraphData())
        end)
    end)
end

function M.showPitchDetailModal(details)
    closePitchDetailModal()
    currentPitchDetailGroup = display.newGroup()
    if currentModalGroup then currentModalGroup:insert(currentPitchDetailGroup) end

    -- 1. Dim Backdrop over open Stats Modal
    local backdrop = display.newRect(currentPitchDetailGroup, centerX, centerY, screenW * 2, screenH * 2)
    backdrop:setFillColor(0, 0, 0, 0.45)
    backdrop.isHitTestable = true
    backdrop:addEventListener("touch", function(event)
        if event.phase == "ended" then
            timer.performWithDelay(1, function()
                closePitchDetailModal()
            end)
        end
        return true
    end)

    -- 2. Compact Popover Card
    local cardW = 320
    local cardH = 200
    local cardShadow = display.newRoundedRect(currentPitchDetailGroup, centerX, centerY + 3, cardW, cardH, 16)
    cardShadow:setFillColor(0, 0, 0, 0.5)

    local cardBg = display.newRoundedRect(currentPitchDetailGroup, centerX, centerY, cardW, cardH, 16)
    cardBg:setFillColor(0.12, 0.15, 0.22, 0.98)

    local cardBorder = display.newRoundedRect(currentPitchDetailGroup, centerX, centerY, cardW, cardH, 16)
    cardBorder.strokeWidth = 2
    cardBorder:setStrokeColor(0.4, 0.6, 0.85, 0.9)
    cardBorder:setFillColor(0, 0, 0, 0)

    -- Title
    local title = display.newText({
        parent = currentPitchDetailGroup,
        text = "pitch: " .. string.lower(details.label),
        x = centerX,
        y = centerY - cardH * 0.5 + 24,
        font = native.systemFontBold,
        fontSize = 18
    })
    title:setFillColor(1, 0.85, 0.3)

    -- Close [ ✕ ] Button (Bright Red)
    local closeBtnX = centerX + cardW * 0.5 - 20
    local closeBtnY = centerY - cardH * 0.5 + 22
    createPillButton(currentPitchDetailGroup, "✕", closeBtnX, closeBtnY, 28, 28, {0.9, 0.18, 0.22}, 14, function()
        closePitchDetailModal()
    end)

    local startY = centerY - 25

    -- Overall Readout Banner
    local totalStr = details.totalCorrect .. " / " .. details.totalAttempts .. " (" .. details.accuracyPct .. "%)"
    local totalLbl = display.newText({
        parent = currentPitchDetailGroup,
        text = "overall: " .. totalStr,
        x = centerX,
        y = startY,
        font = native.systemFontBold,
        fontSize = 15
    })
    totalLbl:setFillColor(0.2, 0.8, 0.4)

    -- Modes Breakdown
    local modes = {
        { name = "single notes", data = details.breakdown.single },
        { name = "melodies", data = details.breakdown.melody },
        { name = "dyad / triad stacks", data = details.breakdown.stack }
    }

    for i, m in ipairs(modes) do
        local modeY = startY + 28 + (i - 1) * 24
        local mStr = m.data.correct .. " / " .. m.data.attempts .. " (" .. m.data.pct .. "%)"
        
        local modeLbl = display.newText({
            parent = currentPitchDetailGroup,
            text = m.name .. ": " .. mStr,
            x = centerX,
            y = modeY,
            font = native.systemFont,
            fontSize = 13
        })
        modeLbl:setFillColor(0.85, 0.88, 0.95)
    end

    if details.topConfusedLabel and details.topConfusedCount > 0 then
        local confLbl = display.newText({
            parent = currentPitchDetailGroup,
            text = "most mistaken for: " .. string.lower(details.topConfusedLabel) .. " (" .. details.topConfusedCount .. "x)",
            x = centerX,
            y = startY + 104,
            font = native.systemFontBold,
            fontSize = 11
        })
        confLbl:setFillColor(1, 0.5, 0.4)
    end
end

return M