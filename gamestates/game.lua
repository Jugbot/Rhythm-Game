game = {}
local Midi = require ('lib.MIDI')
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

function game:init() 

end

function game:enter(previous, songname)
  if not songname then
    songname = "PrototypeRaptor"
  end
  -- print(io.open(SONGDIR .. songname .. ".mid"):read("*a"))
  source = love.audio.newSource(SONGDIR .. songname .. ".mp3", "stream")
  channel = Midi.grep(Midi.midi2score(io.open(SONGDIR .. songname .. ".mid", "rb"):read("*a")), {0}) -- channel 0
  ticks = channel[1]
  print(ticks)
  notes = channel[2]
  table.sort(notes, function (e1,e2) return e1[2]<e2[2] end) -- sort by start time
  -- print(inspect(notes))
  source:play()
  -- print(inspect(Midi.score2stats(notes)))
  current_song = songname
  duration = 0
  current_note = 1
  start = love.timer.getTime()
end

local beatEffects = {}
local BEAT_EFFECT_DURATION = 0.5
local current_note = 1
function game:update(dt)
  duration = source:tell()
  if current_note < #notes then
    -- {'note', start_time, duration, channel, pitch, velocity}
    -- local note = notes[current_note]
    -- print(inspect(note))
    while current_note < #notes and notes[current_note][2] / ticks < duration - BEAT_EFFECT_DURATION do
      if notes[current_note][1] == 'note' then
        -- add effect to signify upcoming note
        local begin = { radius=100, opacity=0.0 } 
        table.insert(beatEffects, {val=begin, tween=tween.new(BEAT_EFFECT_DURATION, begin, { radius = RADIUS, opacity=1.0 }, tween.easing.outSine)})
      end
      current_note = current_note + 1
    end
  end
  for i, v in ipairs(beatEffects) do
    if v.tween:update(dt) then
      beatEffects[i] = nil
    end
  end
end

function game:mousepressed(x,y, mouse_btn)
  mouseEvents.insert({x, y, love.timer.getTime()})
end

function game:draw(dt)
  love.graphics.print("duration: " .. duration)
  camera:attach()
  for i, v in ipairs(beatEffects) do
    love.graphics.setColor(1,1,1,v.val.opacity)
    love.graphics.circle("line", 0, 0, v.val.radius)
  end
  love.graphics.circle("fill", 0, 0, RADIUS)
  camera:detach()
end
