--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Game = class('Game')

NUM_PLAYERS = 4

KILL_RUN_LEN = 4
if NUM_PLAYERS == 2 then
    KILL_RUN_LEN = 3
end

function Game:initialize()
    require 'cards'
    require 'players'
    require 'ai'

    self.logo = love.graphics.newImage(img_filename('obsessed'))

    self.buttons = {
        quit = Button:new('Quit', screen.width - 160, 10),
        play = Button:new('Play', screen.width - 160, screen.height - 60),
        pickup = Button:new('Pick Up', screen.width - 160, screen.height - 60),
    }

    draw_pile = DrawPile:new()
    discard_pile = DiscardPile:new()
    player_list = PlayerList:new()
    dtotal = 0
end

function Game:update(dt)
    local player = player_list:getCurrentPlayer()

    if player_list:isFirstTurn() then
        player:selectInitialCard()
        player:executeTurn()
        return
    end

    dtotal = dtotal + dt
    if dtotal >= 0.5 then
        dtotal = dtotal - 0.5
        if player:isAi() and not player_list:isGameOver() then
            player:selectCards()
            player:executeTurn()
        end
    end

    if player_list:isGameOver() then
        require 'game_over'
        scene = GameOver:new(player_list:getWinners())
    end
end

function Game:draw()
    love.graphics.draw(self.logo, screen.width / 2 - self.logo:getWidth() / 2, 5)

    draw_pile:draw(50, 200)
    discard_pile:draw(150, 200)

    self.buttons['quit']:draw()

    local human = player_list:getHumanPlayer()
    if not human then return end

    human.hand:draw(50, 350, 10)
    human.hidden:draw(54, 476, 10)
    human.visible:draw(50, 470, 10)

    if human:isCurrentPlayer() then
        local active_pile = human:getActivePile()
        if not active_pile:isHidden() and active_pile:hasValidPlay() then
            self.buttons['play']:draw()
        end
        if not active_pile:isHidden() and not active_pile:hasValidPlay() then
            self.buttons['pickup']:draw()
        end
    end
end

function Game:mousepressed(x, y, button)
    local player = player_list:getCurrentPlayer()
    if player:isAi() then return end

    for name, b in pairs(self.buttons) do
        if b:mousepressed(x, y, button) then
            if name == 'play' or name == 'pickup' then
                player:executeTurn()
            elseif name == 'quit' then
                love.event.push('quit')
            end
            return
        end
    end

    local active_pile = player:getActivePile()
    for i, card in ipairs(active_pile:getCards()) do
        if card:mousepressed(x, y, button) then
            if active_pile == player.hidden then
                player:addToHandFromHidden(i)
            else
                card:toggleSelected()
            end
            return
        end
    end
end

function Game:keypressed(key, unicode)
    local player = player_list:getCurrentPlayer()
    if player:isAi() then return end

    local active_pile = player:getActivePile()
    if key == 'p' or key == 'u' then
        player:executeTurn()
    elseif key == 'q' or key == 'escape' then
        love.event.push('quit')
    elseif key:match('[1-9]') then
        active_pile:toggleSelected(tonumber(key))
    end
end
