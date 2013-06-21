--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

GameOver = class('GameOver')

function GameOver:initialize(winners)
    self.winners = winners
end

function GameOver:update(dt) end

function GameOver:draw()
    love.graphics.print('Game Over', 100, 100)
    local vpos = 200
    for i,player in ipairs(self.winners) do
        love.graphics.print(i..'. '..tostring(player), 100, vpos)
        vpos = vpos + 50
    end
end

function GameOver:keypressed(key, unicode)
    if key == 'q' or key == 'escape' then
        love.event.push('quit')
    elseif key == 'r' then
        scene = Game:new()
    end
end
