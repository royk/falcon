--------------------------------------------------------------------------------
--! PseudoRandom Arp
--! Author : Roy Klein/Memento Eternum (based on work by Louis Couka)
--! URL: https://github.com/royk/falcon
--! Date : 26/01/2023
--------------------------------------------------------------------------------

melodyMaximumLength = 16

maxTable = 10 * melodyMaximumLength
randomMapInitiated = false
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
noteLengthKnob = Knob{"Note_Length", 2, 0, 4, true, displayName="Note Length"}
noteLength = 0.25
noteLengthKnob.displayText = "1/4"
noteLengthKnob.changed = function(self)
    -- 0: 16th note
    -- 1: 8th note
    -- 2: 4th note
    -- 3: half onte
    -- 4: whole note
    -- switch case returning a label based on the value of the knob
    local noteLengthLabels = {"1/16", "1/8", "1/4", "1/2", "1"}
    noteLengthKnob.displayText = noteLengthLabels[self.value + 1] or ""
    local noteLengthValues = {0.0625, 0.125, 0.25, 0.5, 1}
    noteLength = noteLengthValues[self.value + 1] or 0.25
end

time = Knob("Beat", 4, 1, 8, true)
maxMelodyLength = Knob{"Melody_Length", 8, 2, melodyMaximumLength, true, displayName = "Length"}
maxMelodyLength.changed = function(self) 
    resetSeed()
end
melodySelector = Knob{"Melody", 1, 1, 10, true}
melodySelector.changed = function(self) 
    resetSeed()
    
end

seed = Knob{"Seed", 1, 1, 100, true}
seed.changed = function(self)
    randomMapInitiated = false
    resetSeed()
end

legato = OnOffButton{"Legato", false}
 

isEventPlaying = {}



function resetSeed() 

    if (randomMapInitiated==false) then
        initiateRandomMap()
    end
    melodyLength = 0
    melody = {}
    pattern = {}
    randomMapIndex = 1;
    resetMelodyIndex = true
    while melodyLength<maxMelodyLength.value do
        local noteToPlay = getRandom(randomMelody)
        local skip = getRandom(randomGate)
        randomMapIndex = randomMapIndex + 1
        table.insert(pattern, skip)
        table.insert(melody, noteToPlay)
        melodyLength = melodyLength +1
    end
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

function printMelody(melodyIndex, len)
    local str = "";
    for i=1,melodyLength,1 do
        if melodyIndex==i then
            str = str .. ">" .. tostring( (melody[i] % len ) + 1)
        else
            str = str .. " " .. tostring( (melody[i] % len ) + 1)
        end
        
    end
    print(str)
    return
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
        local findEndNote = true
        local noteCount = 1
        if (melodyIndex>melodyLength) then
            melodyIndex = 1 
        end
        local startIndex = melodyIndex
        local noteToPlay = (melody[melodyIndex] % len ) + 1
        if legato.value then
            repeat 
                local idx = melodyIndex + noteCount
                if noteCount>1 then
                end
                if idx>melodyLength then 
                    findEndNote = false
                else 
                    local currentNote = (melody[idx] % len ) + 1
                    if (currentNote==noteToPlay) then
                        noteCount = noteCount + 1
                    else
                        findEndNote = false
                    end
                end
            until findEndNote == false
        end
        
        local notePattern = pattern[melodyIndex]
        local currentIndex = melodyIndex
        melodyIndex = melodyIndex+noteCount
        if (melodyIndex>melodyLength) then
            melodyIndex = 1 
        end
        local notes = {};
        for k, e in pairs(isEventPlaying) do
            table.insert(notes, e) 
        end
        table.sort(notes, function(a,b) return a.note<b.note end)
        local beat = 1/actualTime;
        
        local i = 1
        local note = noteToPlay
        for k, e in pairs(notes) do
            if (i == note) then
                printMelody(currentIndex, len)
                local totalNoteLength = getBeatDuration() * noteLength
                if legato.value then
                    totalNoteLength = totalNoteLength * noteCount
                end
                playNote(e.note, e.velocity, totalNoteLength , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
                waitBeat(beat*noteCount)
                break
            end
            i = i + 1
        end
    end
    arpLaunched = false
end

-- CALLBACKS 

function onNote(e)
    isEventPlaying[e.id] = e
    
    if resetMelodyIndex==true then
        resetMelodyIndex = false;
        melodyIndex = 1
    end
    wait(1)
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