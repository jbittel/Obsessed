--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

GameOver = class('GameOver')

function GameOver:initialize(winners)
    self.buttons = {
        quit = Button:new('Quit', screen.width - 160, 10)
        restart = Button:new('Restart', screen.width - 160, 70),
    }

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

    for name, button in pairs(self.buttons) do
        button:draw()
    end
end

function GameOver:mousepressed(x, y, button)
    for name, button in pairs(self.buttons) do
        if button:mousepressed(x, y, button) then
            if name == 'restart' then
                scene = Game:new()
            elseif name == 'quit' then
                love.event.push('quit')
            end
        end
    end
end

function GameOver:keypressed(key, unicode)
    if key == 'q' or key == 'escape' then
        love.event.push('quit')
    elseif key == 'r' then
        scene = Game:new()
    end
end
