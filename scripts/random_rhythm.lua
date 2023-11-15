--------------------------------------------------------------------------------
--! Random Rhythm
--! Author : Roy Klein/Memento Eternum - For more works visit https://meternum.com/lab
--! URL: https://github.com/royk/falcon
--! Date : 01/01/2024
--------------------------------------------------------------------------------

patternMaxLength = 16
maxPatterns = 8;
pattern = {}
patterns = {}
patternLengths = {}
patternBeats = {}
patternPosition = 0
patternShiftAmount = 0
customUIXPosition = 490
randomizeButton = Button("Randomize", false)
randomizeButton.changed = function(self)
  randomize(getTime())
end
randomizeButton.bounds = {customUIXPosition+120, 5, 110, 20}
saveButton = Button("Save", false)
saveButton.changed = function(self)
  patternShiftAmount = 0
  patternShift.value = 0
  patterns[patternSelector.value] = cloneArray(pattern)
  patternLengths[patternSelector.value] = patternLengthSelector.value
  patternBeats[patternSelector.value] = beatsSelector.value
end
saveButton.bounds = {customUIXPosition+120, 30, 110, 20}

patternSelector = Knob{"Pattern", 1, 1, 8, true}
patternSelector.changed = function(self) 
  if patternShiftAmount > 0 then
    shiftLeft(patternShiftAmount)
  elseif patternShiftAmount < 0 then
    shiftRight(patternShiftAmount)
  end
  patternShiftAmount = 0
  patternShift.value = 0
  pattern = patterns[patternSelector.value]
  patternLengthSelector.value = patternLengths[patternSelector.value]
  beatsSelector.value = patternBeats[patternSelector.value]
  updatePatternDisplay()
end

beatsSelector = Knob{"Beats", 4, 1, 8, true}

patternLengthSelector = Knob{"Pattern_Length", maxPatterns, 1, patternMaxLength, true}
patternLengthSelector.changed = function(self)
  updatePatternDisplay()
end

patternShift = Knob{"Pattern_Shift", 0, patternMaxLength/-2, patternMaxLength/2-1, true}
patternShift.changed = function(self)
  -- shift sequencer positions based on value of patternShift
  if patternShiftAmount > patternShift.value then
    shiftLeft(patternShiftAmount - patternShift.value)
  else
    shiftRight(patternShift.value - patternShiftAmount)
  end
  patternShiftAmount = patternShift.value
  updatePatternDisplay()
end

function cloneArray(arr)
  local new = {}
  for i = 1, patternMaxLength do
    new[i] = arr[i]
  end
  return new
end

function shiftLeft(amount)
  for i = 1, amount, 1 do
    local temp = pattern[1]
    for j = 1, patternMaxLength-1, 1 do
      pattern[j] = pattern[j+1]
    end
    pattern[patternMaxLength] = temp
  end
end

function shiftRight(amount)
  for i = 1, amount, 1 do
    local temp = pattern[patternMaxLength]
    for j = patternMaxLength, 2, -1 do
      pattern[j] = pattern[j-1]
    end
    pattern[1] = temp
  end
end

function updatePatternDisplay() 
  for i = 1,patternMaxLength,1 do
      sequencer[i].enabled = i<=patternLengthSelector.value
      sequencer[i].value = pattern[i]==1
  end
end

sequencer = {}
for i = 1,patternMaxLength,1 do
    sequencer[i] = OnOffButton("sequencer"..tostring(i), false)
    sequencer[i].backgroundColourOff = "darkgrey"
    sequencer[i].backgroundColourOn = "darkred"
    sequencer[i].textColourOff = "white"
    sequencer[i].textColourOn = "white"
    local row = math.floor((i-1)/8)+1
    local y = (20*row)-10
    local x = (i-1)%8
    sequencer[i].bounds = {customUIXPosition+15*x,y,10,10}
    sequencer[i].enabled = i<=8
    sequencer[i].changed = function(self)
      pattern[i] = sequencer[i].value and 1 or 0
    end
end

for i = 1, maxPatterns, 1 do 
  patterns[i] = {}
  for j = 1, patternMaxLength, 1 do
    patterns[i][j] = false
  end
  patternLengths[i] = 8
  patternBeats[i] = 4
end

function randomize(seed) 
  pattern = {}
  math.randomseed(seed)
  for i = 1, patternMaxLength, 1 do
    local val = math.random(0,1)
    table.insert(pattern, val)
    sequencer[i].value = val==1
  end
end

function onNote(e)
  updatePatternDisplay()
  local beatPos = math.floor((getRunningBeatTime() * beatsSelector.value ) % patternMaxLength)
  patternPosition = beatPos  % patternLengthSelector.value + 1
  sequencer[patternPosition].enabled = false
  if sequencer[patternPosition].value == true then
    playNote(e.note, e.velocity, e.duration , e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
  end
  patternPosition = patternPosition + 1 
  if patternPosition > patternLengthSelector.value then 
    patternPosition = 1
  end
  
end 