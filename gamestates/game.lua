game = {}
local Midi = require ('lib.MIDI')
local deque = require 'lib.deque'
local SONGDIR = "songs/"
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

function game:init()

end

function game:enter(previous, songname)
  print(songname)
  midiFile = io.open(SONGDIR .. songname .. ".mid", "rb")
  soundFile = SONGDIR .. songname .. ".mp3"
  if io.open(soundFile) == nil then soundFile = SONGDIR .. songname .. ".mid" end
  source = love.audio.newSource(soundFile, "stream")
  midi_score = Midi.midi2ms_score(midiFile:read("*a"))
  -- print(inspect(midi_score))
  -- print(inspect(Midi.score2stats(midi_score)))
  ticks = midi_score[1]
  print(ticks)
  notes = midi_score[3]
  table.sort(notes, function (e1,e2) return e1[2]<e2[2] end) -- sort by start time
  -- print(inspect(notes))
  source:play()
  current_song = songname
  duration = 0
  current_note = 1
  start = love.timer.getTime()
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
local drumEffect = {val=drumeEffectVal, tween=tween.new(1, drumeEffectVal, drumeEffectVal)}
function game:update(dt)
  duration = source:tell()
  if current_note < #notes then
    -- {'note', start_time, duration, channel, pitch, velocity}
    -- local note = notes[current_note]
    -- print(inspect(note))
    while current_note < #notes and notes[current_note][2] / ticks * current_tempo < duration + BEAT_EFFECT_DURATION do
      local event_type = notes[current_note][1]
      -- print(inspect(notes[current_note]))
      if event_type == 'note' then --and notes[current_note][5] <= 52 then
        -- add effect to signify upcoming note
        local begin = { radius=30, opacity=0.0, timestamp=duration + BEAT_EFFECT_DURATION }
        -- table.insert(beatEffects, {val=begin, tween=tween.new(BEAT_EFFECT_DURATION, begin, { radius = RADIUS, opacity=1.0 }, tween.easing.outSine)})
        -- effect_pool_index = (effect_pool_index) % EFFECT_POOL_SIZE + 1
        beatEffects:push_right({
          val=begin,
          tween=tween.new(BEAT_EFFECT_DURATION, begin, { radius = RADIUS, opacity=1.0 }, tween.easing.outSine)
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
    end
  end
  clickEffect.tween:update(dt)
  drumEffect.tween:update(-dt)
  -- print(inspect(drumEffect.val.color))
end

function game:mousepressed(x,y, mouse_btn)
  -- table.insert(mouseEvents, {x, y, duration})
  local greenThresh = 0.1
  local yellowThresh = 0.2
  if beatEffects:length() ~= 0 then
    next_note = beatEffects:pop_left().val
    if duration > next_note.timestamp - greenThresh then
      drumEffect.tween = greenEffect
    elseif duration > next_note.timestamp - yellowThresh then
      drumEffect.tween = yellowEffect
    else
      drumEffect.tween = redEffect
    end
    drumEffect.tween:set(DRUM_EFFECT_DURATION) --plays backwards
  end
  clickEffect.tween:reset()
end

function game:draw(dt)
  love.graphics.print("duration: " .. duration)
  -- love.graphics.print("duration: " .. duration)
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
