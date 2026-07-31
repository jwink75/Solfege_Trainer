-- file: ui.lua
-- version: 11.15
-- status: dynamic box scaling for 5+ notes

local M = {}

local levelText, descText, feedbackText, sessionText
local answerGroup
local width = display.contentWidth
local height = display.contentHeight

local colors = {
    correct = {0, 0.8, 0.4},
    wrong = {0.9, 0.2, 0.2},
    correction = {0.9, 0.7, 0},
    none = {1, 1, 1}
}

function M.init()
    levelText = display.newText({ text = "level: 1.1", x = width * 0.5, y = 30, font = native.systemFontBold, fontSize = 16 })
    descText = display.newText({ text = "initializing...", x = width * 0.5, y = 55, font = native.systemFont, fontSize = 14 })
    descText:setFillColor(0.7, 0.7, 0.7)
    feedbackText = display.newText({ text = "press enter to start", x = width * 0.5, y = 120, width = width * 0.9, align = "center", font = native.systemFontBold, fontSize = 22 })
    sessionText = display.newText({ text = "session score: 0", x = width * 0.5, y = height - 40, font = native.systemFontBold, fontSize = 16 })
    answerGroup = display.newGroup()
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
    rect:setFillColor(0, 0, 0, 0)

    local txt = display.newText({
        parent = group,
        text = tostring(name):lower(),
        x = x, y = y,
        font = native.systemFontBold, 
        fontSize = size * 0.28 -- Slightly smaller to accommodate "sol"
    })
    txt:setFillColor(unpack(colors[color]))
    return group
end



function M.updateAnswerBuffer(names, count, isCircle)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end
    -- SCALE LOGIC: Shrink if more than 4 notes
    local boxSize = (count > 4) and 50 or 60
    local spacing = (count > 4) and 58 or 70
    
    local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
    for i = 1, count do
        local name = names[i] or ""
        answerGroup:insert(createBox(name, "none", startX + (i - 1) * spacing, height * 0.5, boxSize, isCircle))
    end
end

function M.updateAnswerBufferFromResults(results)
    if answerGroup.numChildren then
        for i = answerGroup.numChildren, 1, -1 do answerGroup[i]:removeSelf() end
    end
    local count = #results
    local boxSize = (count > 4) and 50 or 60
    local spacing = (count > 4) and 58 or 70
    
    local startX = width * 0.5 - ((count - 1) * spacing * 0.5)
    for i = 1, count do
        answerGroup:insert(createBox(results[i].name, results[i].color, startX + (i - 1) * spacing, height * 0.5, boxSize, false))
    end
end

return M