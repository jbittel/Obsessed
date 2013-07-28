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

    self.buttons = {
        quit = Button:new('Quit', screen.width - 160, 10),
        play = Button:new('Play', screen.width - 160, screen.height - 60),
        pickup = Button:new('Pick Up', screen.width - 160, screen.height - 60),
    }

    draw_pile = DrawPile:new()
    discard_pile = DiscardPile:new()
    player_list = PlayerList:new()
end

function Game:update()
    local player = player_list:getCurrentPlayer()

    if player_list:getTurn() == 1 then
        player:selectInitialCard()
        player:executeTurn()
        return
    end

    if player:isAi() then
        player:selectCards()
        player:executeTurn()
    end
end

function Game:draw()
    love.graphics.printf('Obsessed', 0, 50, screen.width, "center")

    local player = player_list:getCurrentPlayer()
    if player:isAi() == true then
        love.graphics.print(tostring(player)..' (AI)', 50, 75)
    else
        love.graphics.print(tostring(player)..' (Human)', 50, 75)
    end
    love.graphics.print('Turn '..player_list:getTurn(), 50, 100)

    draw_pile:draw(50, 200)
    discard_pile:draw(150, 200)

    if player:isAi() then return end

    local human = player_list:getHumanPlayer()
    local active_pile = human:getActivePile()
    for name, button in pairs(self.buttons) do
        if name == 'play' then
            if active_pile ~= human.hidden and active_pile:hasValidPlay() then
                button:draw()
            end
        elseif name == 'pickup' then
            if active_pile ~= human.hidden and not active_pile:hasValidPlay() then
                button:draw()
            end
        else
            button:draw()
        end
    end

    human.hand:draw(50, 350)
    human.hidden:draw(60, 480)
    human.visible:draw(50, 470)
end

function Game:mousepressed(x, y, button)
    local player = player_list:getCurrentPlayer()
    if player:isAi() then return end
    local active_pile = player:getActivePile()

    for name, button in pairs(self.buttons) do
        if button:mousepressed(x, y, button) then
            if name == 'play' then
                if active_pile:hasValidPlay() then player:executeTurn() end
            elseif  name == 'pickup' then
                if not active_pile:hasValidPlay() then player:executeTurn() end
            elseif name == 'quit' then
                love.event.push('quit')
            end
        end
    end

    for i, card in ipairs(player:getActiveCards()) do
        if card:mousepressed(x, y, button) then
            if active_pile == player.hidden then
                player:addToHandFromHidden(i)
            else
                active_pile:toggleSelected(i)
            end
            return
        end
    end
end

function Game:keypressed(key, unicode)
    local player = player_list:getCurrentPlayer()
    if player:isAi() then return end

    local active_pile = player:getActivePile()
    if key == 'p' and active_pile:isValidPlay() then
        player:executeTurn()
    elseif key == 'u' and not active_pile:hasValidPlay() then
        player:executeTurn()
    elseif key == 'q' or key == 'escape' then
        love.event.push('quit')
    elseif key:match('[1-9]') then
        active_pile:toggleSelected(tonumber(key))
    end
end
