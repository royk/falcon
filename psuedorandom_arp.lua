--------------------------------------------------------------------------------
--! PsuedoRandom Arp
--! Author : Roy Klein/Memento Eternum (based on work by Louis Couka)
--! Date : 26/01/2023
--------------------------------------------------------------------------------
randomMapInitiated = false
recorder = {}
recording = false
playing = false
playLaunched = false
playIndex = 0
randomMelody = {}
randomGate = {}
randomMapIndex = 1
melody = {}
pattern = {}
melodyIndex = 1
melodyLength = 0
arpLaunched = false
time = Knob("Beat", 4, 1, 8, true)
time.changed = function(self) 
    arpLaunched = false
end
maxMelodyLength = Knob{"Melody_Length", 4, 2, 8, true, displayName = "Length"}
maxMelodyLength.changed = function(self) 
    resetSeed()
end
chance = Knob{"OffChance", 3, 1, 10, true}
melodySelector = Knob{"Melody", 10, 1, 10, true}
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
        recorder = {}
        recording = true
        print("Recording")
    else
        saveData(recorder, 'd:/record.json')
        print(recorder)
    end
end
rec.bounds = {0,60,50,20}
load = Button("Load")
load.changed = function() 
    browseForFile('open', 'Load recording', '', '*.json', function(task)
        loadData(task.result, function (data)
            recorder = data
        end)
    end)
end
load.bounds = {60,60,50,20}
play = OnOffButton{"Replay", false}
play.changed = function(self)
    if (self.value==true) then 
        playing = true
        playIndex = 1
        arpLaunched = false
    else
        playing = false
    end
end
play.bounds = {120,60,50,20}
sequencer = {}
for i = 1,8,1 do
    sequencer[i] = OnOffButton("sequencer"..tostring(i), false)
    sequencer[i].backgroundColourOff = "darkgrey"
    sequencer[i].backgroundColourOn = "darkred"
    sequencer[i].textColourOff = "white"
    sequencer[i].textColourOn = "white"
    local y = 15
    local x = i-1
    if i>4 then
        y = y+15
        x = x-4
    end
    sequencer[i].bounds = {600+15*x,y,10,10}
end
 

isEventPlaying = {}

function resetSeed() 
    if (randomMapInitiated==false) then
        initiateRandomMap()
    end
    melodyLength = 0
    melody = {}
    pattern = {}
    randomMapIndex = 1;
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
    math.randomseed(seed.value)
    -- 80 = (number of melodies) * max length of a melody (10 * 8 )
    for i = 1,80,1 do
        table.insert(randomMelody, math.random(1, 100))
        table.insert(randomGate, math.random(1, 10))
    end
end

function getRandom(randomMap)
    local pos = ((melodySelector.value-1)*8+randomMapIndex-1)%80+1
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
        print(playIndex,' ',len)
        if (playIndex>=len) then
            playIndex = 0
        end
        if (type(e)=="number") then
            waitBeat(e)
        else
            playNote(e.note, e.velocity, 10 , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
        end        

        playIndex = playIndex+1
    end
    playing = false
end

function arp()
    arpLaunched = false
    while arpLaunched do
        local len = tableLength(isEventPlaying)
        if (len == 0) then break end
        
        local noteToPlay = melody[(melodyIndex % melodyLength) + 1]
        local notePattern = pattern[(melodyIndex  % melodyLength) + 1]
        local currentIndex = melodyIndex
        melodyIndex = melodyIndex+1
        if (melodyIndex>melodyLength) then
            melodyIndex = 1 
        end
        --print(currentIndex,notePattern)
        local notes = {};
        for k, e in pairs(isEventPlaying) do
            table.insert(notes, e) 
        end
        table.sort(notes, function(a,b) return a.note<b.note end)
         
        local beat = 1/time.value;
        local maybeSkip = false
        for i = 1,8,1 do
            if (currentIndex==i and sequencer[i].value==false) then
                maybeSkip = true
            end 
        end
        if (maybeSkip==true and notePattern<=chance.value) then
            if (recording) then
                table.insert(recorder, beat);
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
                    end
	                playNote(e.note, e.velocity, 10 , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
	                waitBeat(beat)
	                break
	            end
	            i = i + 1
	        end
        end

    end
    timeFoo = nil
    arpLaunched = false
end

-- CALLBACKS

local idsPlaying
function onNote(e)
    isEventPlaying[e.id] = e
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
    isEventPlaying[e.id] = nil
end

