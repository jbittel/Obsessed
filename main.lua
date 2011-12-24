--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

require 'middleclass'

function love.load()
    love.graphics.setCaption('Obsessed')
    love.graphics.setBackgroundColor(0, 79, 0)
    love.graphics.setColor(255, 255, 255)

    local f = love.graphics.newFont(24)
    love.graphics.setFont(f)

    require 'game'
    scene = Game:new()
end

function love.update(dt)
    scene:update(dt)
end

function love.draw()
    scene:draw()
end

function love.keypressed(key, unicode)
    scene:keypressed(key, unicode)
end
