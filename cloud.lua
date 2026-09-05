-- file: cloud.lua
-- status: Supabase Client Module for Solfège Star

local M = {}
local json = require("json")

-- Supabase configuration credentials
local SUPABASE_URL = "https://mshaveldjmtnxhimfkiy.supabase.co"
local SUPABASE_ANON_KEY = "sb_publishable_VLvb3zLl9twwEELumiKkjw_ifiZpghd"

local function makePostRequest(url, bodyTable, onComplete)
    local headers = {
        ["apikey"] = SUPABASE_ANON_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
        ["Content-Type"] = "application/json"
    }

    local params = {
        headers = headers,
        body = json.encode(bodyTable)
    }

    network.request(url, "POST", function(event)
        if event.isError then
            onComplete(false, "Network error: check internet connection.")
        else
            local success, decoded = pcall(json.decode, event.response)
            if success and decoded then
                if event.status >= 200 and event.status < 300 then
                    onComplete(true, decoded)
                else
                    onComplete(false, decoded.error or decoded.message or ("Server error: " .. event.status))
                end
            else
                onComplete(false, "Server error: invalid response.")
            end
        end
    end, params)
end

-- 1. Create anonymous auth user in Supabase
function M.registerAnonymousProfile(onComplete)
    local url = SUPABASE_URL .. "/auth/v1/signup"
    
    -- In GoTrue, signing up with an empty JSON object registers an anonymous user
    -- if anonymous sign-ins are enabled.
    local headers = {
        ["apikey"] = SUPABASE_ANON_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
        ["Content-Type"] = "application/json"
    }

    local params = {
        headers = headers,
        body = "{}"
    }

    network.request(url, "POST", function(event)
        if event.isError then
            onComplete(false, "Network error: check internet connection.")
        else
            local success, decoded = pcall(json.decode, event.response)
            if success and decoded then
                if event.status >= 200 and event.status < 300 then
                    if decoded.user and decoded.user.id then
                        onComplete(true, decoded.user.id)
                    else
                        onComplete(false, "Authentication succeeded but no user ID returned.")
                    end
                else
                    onComplete(false, decoded.error_description or decoded.msg or decoded.error or ("Auth error: " .. event.status))
                end
            else
                onComplete(false, "Authentication failed: invalid response.")
            end
        end
    end, params)
end

-- 2. Submit score to the Edge Function
function M.submitScore(profileCloudId, displayName, boardId, score, onComplete)
    local url = SUPABASE_URL .. "/functions/v1/submit-score"
    local body = {
        profile_cloud_id = profileCloudId,
        display_name = displayName,
        board_id = boardId,
        score = score,
        app_version = "1.0.0"
    }
    makePostRequest(url, body, onComplete)
end

-- 3. Fetch top N scores for a board (uses direct REST select API)
function M.fetchTopScores(boardId, limit, onComplete)
    local queryUrl = SUPABASE_URL .. "/rest/v1/leaderboard_scores?board_id=eq." .. boardId .. "&order=score.desc,achieved_at.asc&limit=" .. limit
    
    local headers = {
        ["apikey"] = SUPABASE_ANON_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY
    }

    local params = {
        headers = headers
    }

    network.request(queryUrl, "GET", function(event)
        if event.isError then
            onComplete(false, "Network error: check internet connection.")
        else
            local success, decoded = pcall(json.decode, event.response)
            if success and decoded then
                if event.status >= 200 and event.status < 300 then
                    onComplete(true, decoded)
                else
                    onComplete(false, decoded.error or decoded.message or ("Query error: " .. event.status))
                end
            else
                onComplete(false, "Query failed: invalid response.")
            end
        end
    end, params)
end

-- 4. Fetch the rank of a specific user on a board
function M.fetchUserRank(boardId, profileCloudId, onComplete)
    local url = SUPABASE_URL .. "/rest/v1/rpc/get_user_rank"
    local body = {
        p_board_id = boardId,
        p_profile_cloud_id = profileCloudId
    }
    
    makePostRequest(url, body, function(success, data)
        if success then
            if type(data) == "table" and #data > 0 then
                local userRow = data[1]
                onComplete(true, tonumber(userRow.rank), tonumber(userRow.score))
            else
                onComplete(true, nil, nil) -- User has no score submitted for this board yet
            end
        else
            onComplete(false, data)
        end
    end)
end

return M
