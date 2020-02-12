Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"

local game = require "gamestates/game"
local menu = require "gamestates/menu"

mainFont = love.graphics.newFont("assets/NovaMono-Regular.ttf", 20) 
camera = Camera(0, 0)
camera.scale = 10

SONGDIR = "songs/"

function love.load()
  print(_VERSION)
  love.graphics.setFont(mainFont)
  Gamestate.registerEvents()
  Gamestate.switch(game)
  Gamestate.switch(menu, game)
end
