Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"
require "gamestates/game"

mainFont = love.graphics.newFont("assets/Delicious.ttf", 20) 
camera = Camera(0, 0)
camera.scale = 10

function love.load()
  print(_VERSION)
  love.graphics.setFont(mainFont)
  Gamestate.registerEvents()
  Gamestate.switch(game, "Beethoven-Moonlight-Sonata")
end
