--------------------------------------------------------------------------------
--! PsuedoRandom Arp
--! Author : Roy Klein
--! Date : 26/01/2023
--------------------------------------------------------------------------------
randomMapInitiated = false
randomMap = {}
randomMapIndex = 1
melody = {}
melodyIndex = 1
melodyLength = 0
setSeed = false
time = Knob("Time", 1, 1, 8, true)
chance = Knob{"Chance", 10, 1, 10, true}
chance.changed = function(self) 
    resetSeed()
end
seed = Knob{"Seed", 10, 1, 10, true}
seed.changed = function(self) 
    resetSeed()
end
maxMelodyLength = Knob{"Melody_Length", 2, 2, 8, true, displayName = "Melody L."}
maxMelodyLength.changed = function(self) 
    resetSeed()
end

b1 = OnOffButton("b1", false)
b1.backgroundColourOff = "darkgrey"
b1.backgroundColourOn = "darkred"
b1.textColourOff = "white"
b1.textColourOn = "white"
b1.bounds = {500,10,10,10}

b2 = OnOffButton("b2", false)
b2.backgroundColourOff = "darkgrey"
b2.backgroundColourOn = "darkred"
b2.textColourOff = "white"
b2.textColourOn = "white"
b2.bounds = {515,10,10,10}

b3 = OnOffButton("b3", false)
b3.backgroundColourOff = "darkgrey"
b3.backgroundColourOn = "darkred"
b3.textColourOff = "white"
b3.textColourOn = "white"
b3.bounds = {530,10,10,10}

b4 = OnOffButton("b4", false)
b4.backgroundColourOff = "darkgrey"
b4.backgroundColourOn = "darkred"
b4.textColourOff = "white"
b4.textColourOn = "white"
b4.bounds = {545,10,10,10}

isEventPlaying = {}

function resetSeed() 
    if (randomMapInitiated==false) then
        initiateRandomMap()
    end
    setSeed = true
    print("setting seed", seed.value)
    melody = {}
    melodyLength = 0
    melodyIndex = 1
    randomMapIndex = 1;
end

function initiateRandomMap()
    randomMapInitiated = true
    math.randomseed(1)
    for i = 1,100,1 do
        table.insert(randomMap, math.random(1, 10))
    end
end

function getRandom()
    local pos = (randomMapIndex*seed.value)%100+1
    local val = randomMap[pos]
    randomMapIndex = randomMapIndex + 1

    return val
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local arpLaunched
function arp()
    while true do
        local len = tableLength(isEventPlaying)
        if (len == 0) then break end
        noteToPlay = 1
        if (melodyLength<maxMelodyLength.value) then
            if (setSeed==true) then
                print(math.randomseed(seed.value, 1))
                setSeed = false
            end
            noteToPlay = getRandom()
            local skip = getRandom()
            print("note",noteToPlay, skip) 
            if (skip > chance.value) then
                noteToPlay = 0
            end
            table.insert(melody, noteToPlay)
            melodyLength = melodyLength +1
        else
            noteToPlay = melody[melodyIndex]
            melodyIndex = melodyIndex+1
            if (melodyIndex>melodyLength) then
                melodyIndex = 1
            end
        end 
        
        local notes = {};
        for k, e in pairs(isEventPlaying) do
            table.insert(notes, e)
        end
        table.sort(notes, function(a,b) return a.note<b.note end)
        --print(melodyIndex, noteToPlay)
        local beat = time.value / 8;
        if (noteToPlay==0) then
            waitBeat(beat)
        else
	        local i = 1
            local note = (noteToPlay % len) + 1
	        for k, e in pairs(notes) do
	            if (i == note) then
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
    if not arpLaunched then
        resetSeed()
        arpLaunched = true
        run(arp)
    end
end

function onRelease(e)
    isEventPlaying[e.id] = nil
end

