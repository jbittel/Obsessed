--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

function love.load()
    love.graphics.setCaption('Obsessed')
    love.graphics.setBackgroundColor(0, 79, 0)
    love.graphics.setColor(255, 255, 255)

    local f = love.graphics.newFont(24)
    love.graphics.setFont(f)
end

function love.draw()
    love.graphics.print('Obsessed', 100, 100)
end

function love.keyreleased(key)
    if key == 'q' or key == 'escape' then
        os.exit()
    end
end
