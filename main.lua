--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

package.path = 'lib/?.lua;' .. package.path

require 'middleclass'
require 'util'

function love.load()
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        halfWidth = love.graphics.getWidth() / 2,
        halfHeight = love.graphics.getHeight() / 2,
    }

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
    if scene.keypressed then
        scene:keypressed(key, unicode)
    end
end

function love.mousepressed(x, y, button)
    if scene.mousepressed then
        scene:mousepressed(x, y, button)
    end
end
