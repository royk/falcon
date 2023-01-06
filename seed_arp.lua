--------------------------------------------------------------------------------
--! PsuedoRandom Arp
--! Author : Roy Klein
--! Date : 26/01/2023
--------------------------------------------------------------------------------
randomMapInitiated = false
randomMap = {}
randomMapIndex = 1
melody = {}
pattern = {}
melodyIndex = 1
melodyLength = 0
arpLaunched = false
time = Knob("Time", 4, 1, 8, true)
time.changed = function(self) 
    arpLaunched = false
end
seed = Knob{"Seed", 10, 1, 10, true}
seed.changed = function(self) 
    resetSeed()
end
maxMelodyLength = Knob{"Melody_Length", 4, 2, 8, true, displayName = "Melody L."}
maxMelodyLength.changed = function(self) 
    resetSeed()
end
chance = Knob{"OffChance", 10, 1, 10, true}

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

b5 = OnOffButton("b5", true)
b5.backgroundColourOff = "darkgrey"
b5.backgroundColourOn = "darkred"
b5.textColourOff = "white"
b5.textColourOn = "white"
b5.bounds = {500,25,10,10}

b6 = OnOffButton("b6", true)
b6.backgroundColourOff = "darkgrey"
b6.backgroundColourOn = "darkred"
b6.textColourOff = "white"
b6.textColourOn = "white"
b6.bounds = {515,25,10,10}

b7 = OnOffButton("b7", true)
b7.backgroundColourOff = "darkgrey"
b7.backgroundColourOn = "darkred"
b7.textColourOff = "white"
b7.textColourOn = "white"
b7.bounds = {530,25,10,10}

b8 = OnOffButton("b8", true)
b8.backgroundColourOff = "darkgrey"
b8.backgroundColourOn = "darkred"
b8.textColourOff = "white"
b8.textColourOn = "white"
b8.bounds = {545,25,10,10}

isEventPlaying = {}

function resetSeed() 
    if (randomMapInitiated==false) then
        initiateRandomMap()
    end
    melodyLength = 0
    melody = {}
    pattern = {}
    randomMapIndex = 1;
    print("--generating melody")
    while melodyLength<maxMelodyLength.value do
        math.randomseed(seed.value, 1)
        local noteToPlay = getRandom()
        local skip = getRandom()
        table.insert(pattern, skip)
        table.insert(melody, noteToPlay)
        print(noteToPlay,skip)
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

function arp()
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
        print(currentIndex,notePattern)
        local notes = {};
        for k, e in pairs(isEventPlaying) do
            table.insert(notes, e) 
        end
        table.sort(notes, function(a,b) return a.note<b.note end)
         
        local beat = 1/time.value;
        local maybeSkip = false
        if (currentIndex==1 and b1.value==false) then
            maybeSkip = true
        elseif (currentIndex==2 and b2.value==false) then
            maybeSkip = true
        elseif (currentIndex==3 and b3.value==false) then
            maybeSkip = true
        elseif (currentIndex==4 and b4.value==false) then            
            maybeSkip = true
        elseif (currentIndex==5 and b5.value==false) then
            maybeSkip = true
        elseif (currentIndex==6 and b6.value==false) then
            maybeSkip = true
        elseif (currentIndex==7 and b7.value==false) then
            maybeSkip = true
        elseif (currentIndex==8 and b8.value==false) then            
            maybeSkip = true
        end
        if (maybeSkip==true and notePattern<=chance.value) then
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
        melodyIndex = 1
        resetSeed()
        arpLaunched = true
        run(arp)
    end
end

function onRelease(e)
    isEventPlaying[e.id] = nil
end

