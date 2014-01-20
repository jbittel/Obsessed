--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2014 Jason Bittel <jason.bittel@gmail.com>

--]]

function love.conf(t)
    t.title = "Obsessed"
    t.author = "Jason Bittel"

    t.version = "0.9.0"

    t.window.width = 1024
    t.window.height = 600
    t.window.fullwindow = false
    t.window.vsync = true
    t.window.fsaa = 0

    t.modules.joystick = false
    t.modules.audio = false
    t.modules.sound = false
    t.modules.physics = false
end
