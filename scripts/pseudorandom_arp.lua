--------------------------------------------------------------------------------
--! PseudoRandom Arp
--! Author : Roy Klein/Memento Eternum (based on work by Louis Couka)
--! URL: https://github.com/royk/falcon
--! Date : 26/01/2023
--------------------------------------------------------------------------------

melodyMaximumLength = 16

maxTable = 10 * melodyMaximumLength
randomMapInitiated = false
recorder = {}
-- two variables to deal with edge case where recording starting on first note doens't work the same as recording starting later
recordingStartBeat = 0
recordArm = "" -- schedules recording start/stop for next note in
recording = false -- indicates recording is in progress
recordIndex = 1 -- keep track of how long the recording is to avoid out of memory issues
playing = false -- playback is in progress
playLaunched = false -- playback loop control
playbackArm = "" -- schedule playback start/stop for next note in
playIndex = 0 -- the playback playhead
randomMelody = {}
randomGate = {}
randomMapIndex = 1
melody = {}
pattern = {}
melodyIndex = 1
resetMelodyIndex = false
melodyLength = 0
arpLaunched = false
actualTime = 4  -- updates to time.value only when on full beat, so the melody never gets out of sync
time = Knob("Beat", 4, 1, 8, true)
maxMelodyLength = Knob{"Melody_Length", 8, 2, melodyMaximumLength, true, displayName = "Length"}
maxMelodyLength.changed = function(self) 
    resetSeed()
    enableSequencerByMelodyLength()
end
chance = Knob{"OffChance", 3, 1, 20, true}
melodySelector = Knob{"Melody", 1, 1, 10, true}
melodySelector.changed = function(self) 
    resetSeed()
    
end

seed = Knob{"Seed", 1, 1, 100, true}
seed.changed = function(self)
    randomMapInitiated = false
    resetSeed()
end

rec = OnOffButton{"Rec", false}
rec.backgroundColourOn = "darkred"
rec.changed = function(self)
    if (self.value==true) then
        recordArm = "start"
    else
        recordArm = "stop"
    end
end
rec.bounds = {0,60,50,20}
play = OnOffButton{"Replay", false}
play.changed = function(self)
    if (self.value==true) then 
        playbackArm = "start"
    else
        playbackArm = "stop"
        playLaunched = false
    end
end
play.bounds = {60,60,50,20}
load = Button("Load")
load.changed = function() 
    browseForFile('open', 'Load recording', '', '*.json', function(task)
        loadData(task.result, function (data)
            recorder = data
            play.enabled = true
        end)
    end)
end
load.bounds = {120,60,50,20}
save = Button("Save")
save.changed = function()
    browseForFile('save', 'Save recording', '', '*.json', function(task)
        saveData(recorder, task.result)
    end)    
end
save.bounds = {180,60,50,20}
save.enabled = false

sequencer = {}
for i = 1,melodyMaximumLength,1 do
    sequencer[i] = OnOffButton("sequencer"..tostring(i), false)
    sequencer[i].backgroundColourOff = "darkgrey"
    sequencer[i].backgroundColourOn = "darkred"
    sequencer[i].textColourOff = "white"
    sequencer[i].textColourOn = "white"
    local row = math.floor((i-1)/8)+1
    local y = 15*row
    local x = (i-1)%8
    sequencer[i].bounds = {600+15*x,y,10,10}
    sequencer[i].enabled = i<=8
end
 

isEventPlaying = {}

function enableSequencerByMelodyLength() 
    for i = 1,melodyMaximumLength,1 do
        sequencer[i].enabled = i<=maxMelodyLength.value
    end
end

function endRecording()
    --edge cases: recoding on first beat records an extra wait
    -- otherwise, it records the first wait as the last - so move it to the front
    if (recordingStartBeat==0) then
        table.remove(recorder)
    else
        local tempTable = {}
        local a = table.remove(recorder)
        table.insert(tempTable, a)
        for i= 1, tableLength(recorder), 1 do
            table.insert(tempTable, recorder[i])
        end
         recorder = tempTable

        
    end
    print("Recording stopped. Length:", tableLength(recorder))

    play.enabled = true
    save.enabled = true
    recording = false
end


function resetSeed() 
    if (randomMapInitiated==false) then
        initiateRandomMap()
    end
    melodyLength = 0
    melody = {}
    pattern = {}
    randomMapIndex = 1;
    resetMelodyIndex = true
    --print("--generating melody")
    while melodyLength<maxMelodyLength.value do
        local noteToPlay = getRandom(randomMelody)
        local skip = getRandom(randomGate)
        randomMapIndex = randomMapIndex + 1
        table.insert(pattern, skip)
        table.insert(melody, noteToPlay)
        --print(noteToPlay,skip)
        melodyLength = melodyLength +1
    end
    --print("--done",melodyLength)
    
    
end

function initiateRandomMap()
    randomMapInitiated = true
    randomMelody = {}
    randomGate = {}
    math.randomseed(seed.value*1000)
    for i = 1,maxTable,1 do
        table.insert(randomMelody, math.random(1, 100))
        table.insert(randomGate, math.random(1, 20))
    end
end

function getRandom(randomMap)  
    --local pos = ((melodySelector.value-1)*8+randomMapIndex-1)%80+1
    --local pos = randomMapIndex*melodySelector.value%80+1
    local pos = ((randomMapIndex-1)*10+melodySelector.value-1)%maxTable+1
    --print('Accessing',pos)
    local val = randomMap[pos]
    return val
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count 
end

function replay()
    local len = tableLength(recorder)
    if (len==0) then
        return
    end
    while playing do
        local e = recorder[playIndex]
        if (e==nil) then
            playIndex = 1
            e = recorder[playIndex]
        end
        -- print(playIndex,'\t',len, type(e))
        if (type(e)=="number") then
            --print(playIndex,'\t',e,len)
            waitBeat(e)
            
        else
            --print(playIndex,'\t',e.note, len)
            playNote(e.note, e.velocity, 10 , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
            
        end        

        playIndex = playIndex+1
    end
    playing = false
end

function arp()
    while arpLaunched do
        -- only update beat division on beat, to avoid getting out of sync
        if (actualTime~=time.value) then
            local waitForBeat = getRunningBeatTime()-math.floor(getRunningBeatTime())
            waitForBeat = 1 - waitForBeat
            --print('resetting beat',getRunningBeatTime(), waitForBeat)
            waitBeat(waitForBeat)
            --print('time:',getRunningBeatTime())
            actualTime = time.value
        end
        local len = tableLength(isEventPlaying)
        if (len == 0) then break end
        local idx = melodyIndex
        if (melodyIndex>melodyLength) then
            melodyIndex = 1 
        end
        local noteToPlay = melody[melodyIndex]
        local notePattern = pattern[melodyIndex]
        local currentIndex = melodyIndex
        melodyIndex = melodyIndex+1
        if (melodyIndex>melodyLength) then
            melodyIndex = 1 
        end
         local notes = {};
        for k, e in pairs(isEventPlaying) do
            table.insert(notes, e) 
        end
        table.sort(notes, function(a,b) return a.note<b.note end)
        local beat = 1/actualTime;
        local maybeSkip = false
        for i = 1,maxMelodyLength.value,1 do
            if (currentIndex==i and sequencer[i].value==false) then
                maybeSkip = true
            end 
        end
        if (maybeSkip==true and notePattern<=chance.value) then
            if (recording) then
                table.insert(recorder, beat);
                --print(recordIndex,'\t',beat)
                recordIndex = recordIndex +1
            end
            waitBeat(beat)
        else
            local i = 1
            local note = (noteToPlay % len) + 1
            for k, e in pairs(notes) do
                if (i == note) then
                    if (recording) then
                        table.insert(recorder, e);
                        table.insert(recorder, beat);
                        --print(recordIndex,'\t',e.note, getRunningBeatTime())
                        recordIndex = recordIndex + 1
                        --print(recordIndex,'\t',beat)
                        recordIndex = recordIndex + 1
                        
                    end
                    playNote(e.note, e.velocity, 10 , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
                    waitBeat(beat)
                    break
                end
                i = i + 1
            end
        end
        --print(tableLength(recorder))
        if (recordIndex>5000) then
            -- protect from a too long recording
            endRecording()
        end
        

    end
    timeFoo = nil
    arpLaunched = false
end

-- CALLBACKS 

local idsPlaying
function onNote(e)
    isEventPlaying[e.id] = e
    
    if resetMelodyIndex==true then
        resetMelodyIndex = false;
        melodyIndex = 1
    end
    if recordArm~="" then
        if playing==false then 
            if recordArm=="start" then
                recording = true
                recorder = {}
                recordIndex = 1
                recordingStartBeat = getRunningBeatTime()
                print("Recording started")
                recordArm = ""
            end
        end
    end
    if playbackArm~="" then
        if playbackArm=="pause" then
            playing = true;
            playbackArm = "";
        elseif recording==false then
            if playbackArm=="start" then
                playing = true
                playIndex = 1
                arpLaunched = false
                print("Playback started. Length:", tableLength(recorder))
                playbackArm = ""
            end
        end
    end
    if playing then
        if not playLaunched then
            playIndex = 1
            run(replay)
            playLaunched = true
        end
    elseif not arpLaunched then
        melodyIndex = 1
        resetSeed()
        arpLaunched = true
        run(arp)
    end
end

function onRelease(e)
    if recordArm~="" then
        if playing==false then 
            if recordArm~="start" then
                endRecording()
                recordArm = "" 
            end
        end
    end
    if playbackArm~="" then
        if recording==false then
            if playbackArm=="stop" then
                playing = false
                print("Playback ended")
                playbackArm = ""
            end
        end
    else
        -- if song playback is stop, dont keep running the replay
        if playing==true then
            playbackArm = "pause"
            playing = false
        end
    end
    isEventPlaying[e.id] = nil
end