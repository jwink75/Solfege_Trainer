-- File: playback.lua
-- Version: 11.20
-- Status: Standalone (No Circular Dependencies)
-- Fix: Re-implemented full init and play logic with debug heartbeats.

local M = {} 

M.engine = {}
M.voice = {}
M.chord = {}

local sounds = {}
local voices = {} 
local maxVoices = 32
local currentTonic = 60 
local activeTimers = {}
local baseDuration = 800 
local nextChannel = 1 

local noteNames = {"C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"}

for i = 1, maxVoices do voices[i] = 0 end

---------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------

function M.engine.init(prefix)
    audio.reserveChannels(maxVoices)
    local loadedCount = 0
    for i = 40, 81 do
        local nameIndex = (i % 12) + 1
        local octave = math.floor(i / 12) - 1
        -- Matches: soundbanks/piano/piano_40-C2.ogg
        local filename = string.format("soundbanks/piano/%s%02d-%s%d.ogg", prefix, i, noteNames[nameIndex], octave)
        sounds[i] = audio.loadSound(filename)
        if sounds[i] then loadedCount = loadedCount + 1 end
    end
    print("Audio: Initialized. Loaded " .. loadedCount .. " piano samples.")
end

function M.engine.setTonic(midi) currentTonic = midi end

function M.voice.panic()
    for i = #activeTimers, 1, -1 do
        if activeTimers[i] then timer.cancel(activeTimers[i]) end
        table.remove(activeTimers, i)
    end
    pcall(function() audio.stop() end)
    for i = 1, maxVoices do 
        audio.setVolume(1.0, { channel = i })
        voices[i] = 0 
    end
    print("Audio: Panic/Reset")
end

---------------------------------------------------------
-- PLAYBACK LOGIC
---------------------------------------------------------

function M.voice.on(midi, vol)
    if not midi or midi < 40 or midi > 81 or not sounds[midi] then return nil end
    
    local vid = nextChannel
    pcall(function()
        audio.stop(vid) -- Clean the channel
        audio.setVolume(1.0, { channel = vid }) -- Anti-poison
        audio.play(sounds[midi], { channel = vid, volume = vol or 0.6 })
    end)
    
    voices[vid] = midi
    nextChannel = (nextChannel % maxVoices) + 1
    return vid
end

function M.voice.off(vid, fadeTime)
    if vid and vid > 0 then
        pcall(function()
            if fadeTime and fadeTime > 0 then
                audio.fadeOut({ channel = vid, time = fadeTime })
            else
                audio.stop(vid)
            end
        end)
        voices[vid] = 0
    end
end

function M.chord.on(midiTable, vol)
    local vids = {}
    for i = 1, #midiTable do
        local vid = M.voice.on(midiTable[i], vol)
        if vid then table.insert(vids, vid) end
    end
    return vids
end

function M.chord.off(vidsTable, fadeTime)
    if not vidsTable then return end
    for i = 1, #vidsTable do M.voice.off(vidsTable[i], fadeTime) end
end

---------------------------------------------------------
-- SEQUENCES
---------------------------------------------------------

function M.engine.playMelody(item)
    if not item or not item.notes then return end
    local t = currentTonic
    local cumulativeTime = 0
    local lastVid = nil
    
    for i = 1, #item.notes do
        local isLastNote = (i == #item.notes)
        local noteTimer = timer.performWithDelay(cumulativeTime, function()
            local currentVid = M.voice.on(t + item.notes[i], 0.75)
            if lastVid then
                local vidToFade = lastVid
                table.insert(activeTimers, timer.performWithDelay(100, function() 
                    M.voice.off(vidToFade, 100) 
                end))
            end
            lastVid = currentVid
        end)
        table.insert(activeTimers, noteTimer)
        
        local duration = (item.rhythms and item.rhythms[i] or 1) * baseDuration
        cumulativeTime = cumulativeTime + duration

        if isLastNote then
            table.insert(activeTimers, timer.performWithDelay(cumulativeTime + 300, function()
                if lastVid then M.voice.off(lastVid, 500) end
            end))
        end
    end
end

function M.engine.playCadence()
    local t = currentTonic
    local p = baseDuration
    local chords = {
        {t-12, t+4, t+7, t+12}, {t-7, t+5, t+9, t+12}, 
        {t-5, t+2, t+7, t+11}, {t-12, t+4, t+7, t+12}
    }
    local cadenceVids = {}

    local function step(idx, delay)
        local tID = timer.performWithDelay(delay, function()
            M.chord.off(cadenceVids) 
            cadenceVids = M.chord.on(chords[idx], 0.5)
        end)
        table.insert(activeTimers, tID)
    end

    step(1, 0)
    step(2, p)
    step(3, p*2)
    step(4, p*3)
    
    -- 1200ms hold + 300ms natural release
    table.insert(activeTimers, timer.performWithDelay(p*3 + 1200, function()
        M.chord.off(cadenceVids, 300) 
    end))
end

return M