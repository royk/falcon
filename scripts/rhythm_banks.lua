--------------------------------------------------------------------------------
--! Rhythm Banks
--! Author : Roy Klein/Memento Eternum - For more works visit https://meternum.com/lab
--! URL: https://github.com/royk/falcon
--! Date : 01/01/2024
--------------------------------------------------------------------------------

patternMaxLength = 16
maxPatterns = 8;
pattern = {}
beatPos = 0
patternPosition = 0
patternShiftAmount = 0
customUIXPosition = 490
randomizeButton = Button("Randomize", false)
randomizeButton.changed = function(self)
  randomize(getTime())
end

randomizeButton.bounds = {customUIXPosition+120, 5, 110, 20}
notesInStep = {}
stepInProgress = false
sequencerRunning = false

patternSelector = Knob{"Pattern", 1, 1, 8, true}
patternSelector.changed = function(self) 
  patternShiftAmount = 0
  patternShift.value = 0
  for i = 1,patternMaxLength,1 do
    index = getSequencerStepIndex(i)
    pattern[i] = sequencer[index].value and 1 or 0
  end
  redrawControls()
  drawSequencer()
end
beatsSelectors = {}
for i= 1, maxPatterns,1  do
  beatsSelectors[i] = Knob{"Beats"..tostring(i), 4, 1, 8, true, displayName="Beats Reset"}
  beatsSelectors[i].changed = function(self)
    updatePatternDisplay()
  end
  beatsSelectors[i].width = i==1 and 110 or 0
  beatsSelectors[i].visible = false
end
patternLengthSelectors = {}
for i= 1, maxPatterns,1  do
  patternLengthSelectors[i] = Knob{"Pattern_Length"..tostring(i), maxPatterns, 1, patternMaxLength, true}
  patternLengthSelectors[i].changed = function(self)
    updatePatternDisplay()
  end
  patternLengthSelectors[i].width = i==1 and 110 or 0
  patternLengthSelectors[i].visible = false
end


patternShift = Knob{"Pattern_Shift", 0, patternMaxLength/-2, patternMaxLength/2-1, true}
patternShift.changed = function(self)
  if patternShiftAmount==patternShift.value then 
    return
  end
  if patternShiftAmount > patternShift.value then
    shiftLeft(patternShiftAmount - patternShift.value)
  else
    shiftRight(patternShift.value - patternShiftAmount)
  end
  patternShiftAmount = patternShift.value
  updatePatternDisplay()
end

function redrawControls()
  for i= 1, maxPatterns,1  do
    if i==patternSelector.value then
      patternLengthSelectors[i].visible = true
      patternLengthSelectors[i].width = 110
      patternLengthSelectors[i].x = 245
      patternLengthSelectors[i].y = 5
      beatsSelectors[i].visible = true
      beatsSelectors[i].width = 110
      beatsSelectors[i].x = 135
      beatsSelectors[i].y = 5
    else
      patternLengthSelectors[i].visible = false
      patternLengthSelectors[i].width = 0
      beatsSelectors[i].visible = false
      beatsSelectors[i].width = 0
      
    end
  end
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

function getSequencerStepIndex(i)
  return (patternSelector.value-1)*patternMaxLength+i;
end

function updatePatternDisplay() 
  for i = 1,patternMaxLength,1 do
    index = getSequencerStepIndex(i)
    sequencer[index].enabled = i<=patternLengthSelectors[patternSelector.value].value
    sequencer[index].value = pattern[i]==1
  end
end

sequencer = {}
for j= 1, maxPatterns,1  do
  for i = 1,patternMaxLength,1 do
      index = (j-1)*patternMaxLength+i ;
      sequencer[index] = OnOffButton("sequencer"..tostring(index), false)
      sequencer[index].backgroundColourOff = "darkgrey"
      sequencer[index].backgroundColourOn = "darkred"
      sequencer[index].textColourOff = "white"
      sequencer[index].textColourOn = "white"
      local row = math.floor((i-1)/8)+1
      local y = (20*row)-10
      local x = (i-1)%8
      sequencer[index].bounds = {customUIXPosition+15*x,y,10,10}
      sequencer[index].enabled = i<=8
      sequencer[index].changed = function(self)
        pattern[i] = sequencer[getSequencerStepIndex(i)].value and 1 or 0
      end
      sequencer[index].visible = j==1
  end
end

redrawControls()

function drawSequencer()
  for j= 1, maxPatterns,1  do
    for i = 1,patternMaxLength,1 do
      index = (j-1)*patternMaxLength+i ;
      sequencer[index].visible = j==patternSelector.value
    end
  end
end

function randomize(seed) 
  pattern = {}
  math.randomseed(seed) 
  for i = 1, patternMaxLength, 1 do
    local val = math.random(0,1)
    sequencer[getSequencerStepIndex(i)].value = val==1
  end
end

function noteStep()
  local len = tableLength(notesInStep)
  if (len == 0) then return end
      
  if stepInProgress==false then
    stepInProgress = true
    updatePatternDisplay()
    beatPos = beatPos + 1
    runSequencer()
    stepInProgress = false
    notesInStep = {}
  end
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count 
end

function runSequencer() 
  updatePatternDisplay()
  local beat = math.floor((getRunningBeatTime() * 4 ) % (patternMaxLength*beatsSelectors[patternSelector.value].value))
  if beat==0 then 
    beatPos = 0
  end
  patternPosition = beatPos  % patternLengthSelectors[patternSelector.value].value + 1
  index = getSequencerStepIndex(patternPosition)
  sequencer[index].enabled = false
  if sequencer[index].value == true then
    for k, e in pairs(notesInStep) do
      playNote(e.note, e.velocity, e.duration, e.layer, e.channel, e.input, e.vol, e.pan, e.tune, e.slice)
    end
  end
  patternPosition = patternPosition + 1 
  if patternPosition > patternLengthSelectors[patternSelector.value].value then 
    patternPosition = 1
  end
end

function onNote(e)
  notesInStep[e.id] = e
  wait(1)
  noteStep()
end 

function onEvent(e)
  if e.type == Event.NoteOn then
    onNote(e)
  else if e.type == Event.NoteOff then
      notesInStep[e.id] = nil
    end
  end
end