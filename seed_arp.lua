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
time = Knob("Time", 4, 1, 8, true)
seed = Knob{"Seed", 10, 1, 10, true}
seed.changed = function(self) 
    resetSeed()
end
maxMelodyLength = Knob{"Melody_Length", 4, 2, 8, true, displayName = "Melody L."}
maxMelodyLength.changed = function(self) 
    resetSeed()
end

b1 = OnOffButton("b1", true)
b1.backgroundColourOff = "darkgrey"
b1.backgroundColourOn = "darkred"
b1.textColourOff = "white"
b1.textColourOn = "white"
b1.bounds = {500,10,10,10}

b2 = OnOffButton("b2", true)
b2.backgroundColourOff = "darkgrey"
b2.backgroundColourOn = "darkred"
b2.textColourOff = "white"
b2.textColourOn = "white"
b2.bounds = {515,10,10,10}

b3 = OnOffButton("b3", true)
b3.backgroundColourOff = "darkgrey"
b3.backgroundColourOn = "darkred"
b3.textColourOff = "white"
b3.textColourOn = "white"
b3.bounds = {530,10,10,10}

b4 = OnOffButton("b4", true)
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
    melodyLength = 0
    melody = {}
    randomMapIndex = 1;
    print("--generating melody")
    while melodyLength<maxMelodyLength.value do
        math.randomseed(seed.value, 1)
        noteToPlay = getRandom()
        local skip = getRandom()
        table.insert(melody, noteToPlay)
        melodyLength = melodyLength +1
    end
    print("--done",melodyLength)
    
    
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
        local noteToPlay = melody[melodyIndex]
        
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
         
        local beat = 1/time.value;
        print(melodyIndex, currentIndex)
        if (melodyIndex==1 and b1.value==false) then
            waitBeat(beat)
        elseif (melodyIndex==2 and b2.value==false) then
            waitBeat(beat);
        elseif (melodyIndex==3 and b3.value==false) then
            waitBeat(beat);
        elseif (melodyIndex==4 and b4.value==false) then            
            waitBeat(beat);
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
    melodyIndex = 1
    if not arpLaunched then
        resetSeed()
        arpLaunched = true
        run(arp)
    end
end

function onRelease(e)
    isEventPlaying[e.id] = nil
end

