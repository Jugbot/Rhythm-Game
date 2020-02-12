local Midi = require ('lib.MIDI')
local deque = require 'lib.deque'
local current_song
local duration
local lastNote
local start
local mouseEvents = {}
local source
local notes
local RADIUS = 10
local radius = RADIUS
local ticks
local score = 0
local note_count

local game = {}

function game:init()
  
end

local function flattenTrack(track)
  local last_time = -1
  -- {'note', start_time, duration, channel, pitch, velocity}
  for i, t in ipairs(track) do
    -- print(inspect(t))
    if t[1] == 'note' then
      local _start = t[2]
      local _end = t[3] + _start
      if _start <= last_time then
        t[1] = '' -- dont read
      else
        last_time = _end
      end
    end
  end

  return track
end

function game:enter(previous, songname)
  if not songname then return end
  print(songname)
  game.previous = previous
  local midiFile = love.filesystem.newFile(SONGDIR .. songname .. ".mid", "r")
  local soundFilePath = SONGDIR .. songname .. ".mp3"
  local soundFile
  -- play midi if mp3 not available
  if love.filesystem.getInfo(soundFilePath) then 
    soundFile = love.filesystem.newFile(soundFilePath, "r")
  else
    soundFile = midiFile
  end
  source = love.audio.newSource(soundFile, "stream")
  -- print(midiFile:getFilename())
  midi_score = Midi.midi2ms_score(midiFile:read())
  -- midi_score = Midi.midi2opus(midiFile:read())
  -- midi_score = Midi.midi2score(midiFile:read())
  -- for i=-18, 18 do
  --   print(inspect(midi_score[i]))
  -- end
  -- print(inspect(midi_score))
  -- print(inspect(Midi.score2stats(midi_score)))
  ticks = midi_score[1]
  -- print(ticks)
  notes = flattenTrack(midi_score[#midi_score])
  note_count = 0 -- for scoring
  for i, v in ipairs(notes) do
    if v[1] == "note" then
      note_count = note_count + 1
    end
  end
  -- print(note_count)
  table.sort(notes, function (e1,e2) return e1[2]<e2[2] end) -- sort by start time
  print(inspect(notes))
  source:play()
  current_song = songname
  duration = 0
  current_note = 1
  start = love.timer.getTime()
end

function game:leave()
  if source and source:isPlaying() then
    source:stop()
  end
end

local beatEffects = deque.new()
local CLICK_EFFECT_DURATION = 0.25
local circleTweenSize = {radius=RADIUS*7/8}
local clickEffect = {val=circleTweenSize, tween=tween.new(CLICK_EFFECT_DURATION, circleTweenSize, {radius=RADIUS}, tween.easing.outBounce)}
local EFFECT_POOL_SIZE = 10
local effect_pool_index = 1
local BEAT_EFFECT_DURATION = 0.5
local current_note = 1
local current_tempo = 1.0
-- Color effect for tapping note
local drumeEffectVal = { color= {1,1,1} }
local DRUM_EFFECT_DURATION = 0.2
local greenEffect = tween.new(DRUM_EFFECT_DURATION, drumeEffectVal, {color={0.5,1,0.5}}, tween.easing.linear)
local yellowEffect = tween.new(DRUM_EFFECT_DURATION, drumeEffectVal, {color={0.5,1,1}}, tween.easing.linear)
local redEffect = tween.new(DRUM_EFFECT_DURATION, drumeEffectVal, {color= {1,0.5,0.5}}, tween.easing.linear) 
local drumEffect = { val=drumeEffectVal, tween=tween.new(1, drumeEffectVal, drumeEffectVal) }
function game:update(dt)
  if not source:isPlaying() then
    Gamestate.switch(game.previous)
  end
  duration = source:tell()
  if current_note < #notes then
    -- {'note', start_time, duration, channel, pitch, velocity}
    -- print(inspect(note))
    while current_note < #notes and notes[current_note][2] / ticks * current_tempo < duration + BEAT_EFFECT_DURATION do
      local event_type = notes[current_note][1]
      -- print(inspect(notes[current_note]))
      if event_type == 'note' then
        -- add effect to signify upcoming note
        local begin = { radius=30, opacity=0.0, timestamp=duration + BEAT_EFFECT_DURATION }
        beatEffects:push_right({
          val=begin,
          tween=tween.new(BEAT_EFFECT_DURATION + 0.1, begin, { radius = RADIUS-1, opacity=1.0 }, tween.easing.linear) -- I tweaked some values here to make it look better
        })
        -- print(inspect(notes[current_note]))
      elseif event_type == "set_tempo" then
        current_tempo = notes[current_note][3] / 1000000.0
        -- print(current_tempo)
      end
      current_note = current_note + 1
    end

  end
  for v in beatEffects:iter_right() do
    if v.tween:update(dt) then
      -- assumes all effects will end in order
      beatEffects:pop_left()
      -- counts as a missed note in addition to hitting early
      drumEffect.tween = redEffect
      drumEffect.tween:set(DRUM_EFFECT_DURATION)
    end
  end
  clickEffect.tween:update(dt)
  drumEffect.tween:update(-dt)
end

function game:mousepressed(x,y, mouse_btn)
  local greenThresh = 0.1
  local yellowThresh = 0.2
  local redThresh = 0.3 -- if tap should count
  if beatEffects:length() ~= 0 and duration > beatEffects:peek_left().val.timestamp - redThresh then
    next_note = beatEffects:pop_left().val
    if duration > next_note.timestamp - greenThresh then
      drumEffect.tween = greenEffect
      score = score + 1 / note_count * 100000.0
    elseif duration > next_note.timestamp - yellowThresh then
      drumEffect.tween = yellowEffect
      score = score + 0.5 / note_count * 100000.0
    else
      drumEffect.tween = redEffect
    end
    drumEffect.tween:set(DRUM_EFFECT_DURATION) --plays backwards
  end
  clickEffect.tween:reset()
end

function game:draw(dt)
  love.graphics.print(duration .. "s")
  score_int = math.floor(score)
  score_str = string.rep('0', 7 - string.len(score_int)) .. score_int
  love.graphics.printf(score_str,0,0,love.graphics.getWidth(),"right")
  camera:attach()
  for v in beatEffects:iter_right() do
    if v.tween.clock < v.tween.duration then
      love.graphics.setColor(1, 1, 1, v.val.opacity)
      love.graphics.circle("line", 0, 0, v.val.radius)
    end
  end
  love.graphics.setColor(drumEffect.val.color)
  love.graphics.circle("fill", 0, 0, clickEffect.val.radius)
  camera:detach()
end

return game