-- playback.lua
local M = {} -- This MUST be here and must be LOCAL

-- 1. INTERNAL STATE
local sounds = {}
local voices = {} 
local maxVoices = 32
local currentTonic = 60 
local fadeTime = 80    
local activeTimers = {}

-- Note names matching your "piano_40-Cs2.ogg" format
local noteNames = {"C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"}

-- Initialize voice table
for i = 1, maxVoices do voices[i] = 0 end

-- 2. ENGINE NAMESPACE
M.engine = {}

function M.engine.init(prefix)
    for i = 40, 81 do
        local nameIndex = (i % 12) + 1
        local octave = math.floor(i / 12) - 1
        -- Matches your "piano_40-Cs2.ogg" format
        local filename = string.format("%s%02d-%s%d.ogg", prefix, i, noteNames[nameIndex], octave)
        sounds[i] = audio.loadSound(filename)
    end
    print("Solfège Trainer Engine: Initialized")
end

function M.engine.setTonic(midi) currentTonic = midi end
function M.engine.getTonic() return currentTonic end

-- 3. VOICE NAMESPACE
M.voice = {}

function M.voice.on(midi, vol)
    if not sounds[midi] then return nil end
    
    -- Find a free voice (Status 0)
    local vid = nil
    for i = 1, maxVoices do
        if voices[i] == 0 then vid = i; break end
    end
    
    -- If no free voice, force-claim channel 1 (simple stealing)
    if not vid then vid = 1 end
    
    audio.stop(vid) 
    voices[vid] = 1 
    audio.setVolume(vol or 1.0, { channel = vid })
    audio.play(sounds[midi], { channel = vid })
    
    return vid
end

function M.voice.off(vid)
    if not vid or voices[vid] ~= 1 then return end
    
    voices[vid] = 2 
    audio.fadeOut({ channel = vid, time = fadeTime })
    
    timer.performWithDelay(fadeTime + 5, function()
        -- Only clear if another note hasn't already stolen this voice
        if voices[vid] == 2 then
            audio.stop(vid)
            voices[vid] = 0 
        end
    end)
end

function M.voice.panic()
    -- Cancel any staggering timers
    for i = 1, #activeTimers do
        if activeTimers[i] then timer.cancel(activeTimers[i]) end
    end
    activeTimers = {}
    
    for i = 1, maxVoices do
        audio.stop(i)
        voices[i] = 0
    end
end

-- 4. CHORD NAMESPACE
M.chord = {}

function M.chord.on(midiTable, vol)
    local vids = {}
    for i = 1, #midiTable do
        -- Micro-stagger for Tahoe/M4 stability
        local tm = timer.performWithDelay(i * 2, function()
            local id = M.voice.on(midiTable[i], vol)
            if id then table.insert(vids, id) end
        end)
        table.insert(activeTimers, tm)
    end
    return vids
end

function M.chord.off(vids)
    if not vids then return end
    for i = 1, #vids do
        M.voice.off(vids[i])
    end
end

return M -- This MUST be the last line