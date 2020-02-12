local Layout = require 'lib.luigi.layout'
local Widget = require 'lib.luigi.widget'

local layout = Layout({ id = 'window',
  {
    align = "top center",
    text = "Rhythm Game",
    padding = 10,
    size = 24,
    color = {1,1,1},
    background = {0,0,0},
    height = 50
  },
  {
    id = 'songList',
    flow = 'y',
    padding = 30,
    scroll = true
    -- { stuff }
  },
  {
    background = {0,0,0},
    height = 50
  }
})

local menu = { 
  previous = nil 
}

function menu:init(gamestate)
  for i, f in ipairs(love.filesystem.getDirectoryItems(SONGDIR)) do
    if f:sub(-4) == ".mid" then
      local name = f:sub(0, -5)
      local button = layout.songList:addChild({
        type = 'button',
        text = name
      })

      button:onPress(function (e)
        Gamestate.switch(menu.previous, name)
      end)
    end
  end

  -- layout.songList:WheelMove(function (e)
  --   layout.songList.
  -- end) 


end

function menu:enter(previous)
  menu.previous = previous
  layout:show()
end

function menu:leave()
  layout:hide()
end


return menu