--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

function love.conf(t)
    t.title = "Obsessed"
    t.author = "Jason Bittel"

    t.version = "0.8.0"

    t.screen.width = 1024
    t.screen.height = 600
    t.screen.fullscreen = false
    t.screen.vsync = true
    t.screen.fsaa = 0

    t.modules.joystick = false
    t.modules.audio = false
    t.modules.sound = false
    t.modules.physics = false
end
