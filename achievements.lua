-- file: achievements.lua
-- status: Central declarative Achievements & Titles system for Solfège Star

local M = {}

-- 1. Mastery Ranks & Thresholds (Generic naming per user request)
M.ranks = {
    { id = "rank_1", title = "Mastery Level 1", points = 0, badge = "🌱" },
    { id = "rank_2", title = "Mastery Level 2", points = 500, badge = "⭐" },
    { id = "rank_3", title = "Mastery Level 3", points = 1500, badge = "🌟" },
    { id = "rank_4", title = "Mastery Level 4", points = 3500, badge = "🎖️" },
    { id = "rank_5", title = "Mastery Level 5", points = 7000, badge = "🏅" },
    { id = "rank_6", title = "Mastery Level 6", points = 12000, badge = "👑" },
    { id = "rank_7", title = "Mastery Level 7", points = 25000, badge = "🏆" }
}

function M.getRankForPoints(pts)
    pts = pts or 0
    local currentRank = M.ranks[1]
    for _, r in ipairs(M.ranks) do
        if pts >= r.points then
            currentRank = r
        end
    end
    return currentRank
end

-- 2. Declarative Achievement Registry
M.registry = {
    -- Level Milestones
    {
        id = "milestone_lvl1",
        name = "Level 1 Milestone",
        description = "Answered 20 questions in Level 1",
        badge = "🎵",
        category = "milestone",
        check = function(profile, data)
            local count = profile.levelCounts and profile.levelCounts[1] or 0
            return count >= 20
        end
    },
    {
        id = "milestone_lvl2",
        name = "Level 2 Milestone",
        description = "Answered 20 questions in Level 2",
        badge = "🎶",
        category = "milestone",
        check = function(profile, data)
            local count = profile.levelCounts and profile.levelCounts[2] or 0
            return count >= 20
        end
    },
    {
        id = "milestone_lvl3",
        name = "Level 3 Milestone",
        description = "Answered 20 questions in Level 3",
        badge = "🎼",
        category = "milestone",
        check = function(profile, data)
            local count = profile.levelCounts and profile.levelCounts[3] or 0
            return count >= 20
        end
    },
    {
        id = "milestone_lvl5",
        name = "Level 5 Milestone",
        description = "Answered 20 questions in Level 5",
        badge = "✨",
        category = "milestone",
        check = function(profile, data)
            local count = profile.levelCounts and profile.levelCounts[5] or 0
            return count >= 20
        end
    },
    {
        id = "milestone_lvl8",
        name = "Level 8 Milestone",
        description = "Answered 20 questions in Level 8",
        badge = "🎹",
        category = "milestone",
        check = function(profile, data)
            local count = profile.levelCounts and profile.levelCounts[8] or 0
            return count >= 20
        end
    },
    {
        id = "milestone_checkpoint1",
        name = "Checkpoint 1 Milestone",
        description = "Completed the Phase 1 Checkpoint Challenge",
        badge = "🏁",
        category = "milestone",
        check = function(profile, data)
            return data and data.checkpointBoard == "checkpoint_1"
        end
    },
    {
        id = "milestone_checkpoint2",
        name = "Checkpoint 2 Milestone",
        description = "Completed the Phase 2 Final Checkpoint",
        badge = "🏆",
        category = "milestone",
        check = function(profile, data)
            return data and data.checkpointBoard == "checkpoint_2"
        end
    },

    -- Note & Day Streaks
    {
        id = "streak_10",
        name = "10 Note Streak",
        description = "10 consecutive correct notes",
        badge = "🔥",
        category = "streak",
        check = function(profile, data)
            local streak = profile.lifetime and profile.lifetime.bestStreak or 0
            return streak >= 10
        end
    },
    {
        id = "streak_25",
        name = "25 Note Streak",
        description = "25 consecutive correct notes",
        badge = "⚡",
        category = "streak",
        check = function(profile, data)
            local streak = profile.lifetime and profile.lifetime.bestStreak or 0
            return streak >= 25
        end
    },
    {
        id = "streak_50",
        name = "50 Note Streak",
        description = "50 consecutive correct notes",
        badge = "💫",
        category = "streak",
        check = function(profile, data)
            local streak = profile.lifetime and profile.lifetime.bestStreak or 0
            return streak >= 50
        end
    },
    {
        id = "streak_3day",
        name = "3 Day Streak",
        description = "Practiced on 3 distinct calendar days",
        badge = "📅",
        category = "streak",
        check = function(profile, data)
            local history = profile.dailyHistory or {}
            local count = 0
            for _ in pairs(history) do count = count + 1 end
            return count >= 3
        end
    },
    {
        id = "streak_7day",
        name = "7 Day Streak",
        description = "Practiced on 7 distinct calendar days",
        badge = "🌟",
        category = "streak",
        check = function(profile, data)
            local history = profile.dailyHistory or {}
            local count = 0
            for _ in pairs(history) do count = count + 1 end
            return count >= 7
        end
    },

    -- Hot Seat Milestones
    {
        id = "hotseat_first",
        name = "Hot Seat Milestone 1",
        description = "Completed your first Hot Seat match",
        badge = "🤝",
        category = "hotseat",
        check = function(profile, data)
            local matches = profile.lifetime and profile.lifetime.hotSeatMatches or 0
            return matches >= 1
        end
    },
    {
        id = "hotseat_wins_5",
        name = "Hot Seat Milestone 2",
        description = "Won 5 Hot Seat matches",
        badge = "🥇",
        category = "hotseat",
        check = function(profile, data)
            local wins = profile.lifetime and profile.lifetime.hotSeatWins or 0
            return wins >= 5
        end
    },
    {
        id = "hotseat_overtime",
        name = "Overtime Milestone",
        description = "Won a match in sudden death overtime",
        badge = "⚡",
        category = "hotseat",
        check = function(profile, data)
            return data and data.isOvertimeWin == true
        end
    }
}

-- 3. Evaluation & Notification Dispatcher
function M.checkEvent(eventName, eventData, targetProfileId)
    local stats = require("stats")
    local prof = targetProfileId and stats.getProfile(targetProfileId) or stats.getActiveProfile()
    if not prof then return end

    prof.achievements = prof.achievements or {}
    prof.unlockedTitles = prof.unlockedTitles or { "Mastery Level 1" }
    prof.levelCounts = prof.levelCounts or {}

    -- Update question count per major level if this is an exercise completed event
    if eventName == "exercise_completed" and eventData and eventData.majorLevel then
        local ml = eventData.majorLevel
        prof.levelCounts[ml] = (prof.levelCounts[ml] or 0) + 1
    end

    -- Check Mastery Rank progression
    local currentPts = prof.lifetime and prof.lifetime.totalPoints or 0
    local earnedRank = M.getRankForPoints(currentPts)
    if earnedRank and earnedRank.title then
        local hasTitle = false
        for _, t in ipairs(prof.unlockedTitles) do
            if t == earnedRank.title then hasTitle = true; break end
        end
        if not hasTitle then
            table.insert(prof.unlockedTitles, earnedRank.title)
            -- Auto-upgrade active title if currently on a default Mastery Level
            if string.sub(prof.equippedTitle or "", 1, 13) == "Mastery Level" then
                prof.equippedTitle = earnedRank.title
            end
            local ui = require("ui")
            if ui and ui.showAchievementToast then
                ui.showAchievementToast("Rank Up!", earnedRank.title, earnedRank.badge)
            end
        end
    end

    -- Check all registry achievements
    for _, ach in ipairs(M.registry) do
        if not prof.achievements[ach.id] then
            local unlocked = false
            local success, res = pcall(ach.check, prof, eventData)
            if success and res then
                unlocked = true
            end

            if unlocked then
                prof.achievements[ach.id] = os.time()
                if ach.rewardTitle then
                    local exists = false
                    for _, t in ipairs(prof.unlockedTitles) do
                        if t == ach.rewardTitle then exists = true; break end
                    end
                    if not exists then table.insert(prof.unlockedTitles, ach.rewardTitle) end
                end

                local ui = require("ui")
                if ui and ui.showAchievementToast then
                    ui.showAchievementToast("Achievement Unlocked!", ach.name, ach.badge)
                end
            end
        end
    end

    stats.save()
end

return M
