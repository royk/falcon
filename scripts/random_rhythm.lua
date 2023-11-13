--------------------------------------------------------------------------------
--! Random Rhythm
--! Author : Roy Klein/Memento Eternum - https://meternum.com
--! URL: https://github.com/royk/falcon
--! Date : 01/01/2024
--------------------------------------------------------------------------------

beats = 4
patternMaxLength = 16
maxPatterns = 8;
pattern = {}
patterns = {}
patternLengths = {}
patternPosition = 0

randomizeButton = Button("Randomize", false)
randomizeButton.changed = function(self)
  randomize(getTime())
end
randomizeButton.bounds = {400, 5, 110, 20}
saveButton = Button("Save", false)
saveButton.changed = function(self)
  patterns[patternSelector.value] = pattern
  patternLengths[patternSelector.value] = patternLengthSelector.value
end
saveButton.bounds = {400, 30, 110, 20}
patternSelector = Knob{"Pattern", 1, 1, 8, true}
patternSelector.changed = function(self) 
    pattern = patterns[patternSelector.value]
    patternLengthSelector.value = patternLengths[patternSelector.value]
    updatePatternDisplay()
end

patternLengthSelector = Knob{"Pattern_Length", maxPatterns, 1, patternMaxLength, true}
patternLengthSelector.changed = function(self)
  updatePatternDisplay()
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
    sequencer[i].bounds = {250+15*x,y,10,10}
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
  patternLengths[i] = 8;
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
  local beatPos = math.floor((getRunningBeatTime() % beats) *4)
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