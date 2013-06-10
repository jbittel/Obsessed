--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Game = class('Game')

NUM_PLAYERS = 4
HAND_SIZE = 3
VISIBLE_SIZE = 3
HIDDEN_SIZE = 3

KILL_RUN_LEN = 4
if NUM_PLAYERS == 2 then
    KILL_RUN_LEN = 3
end

function Game:initialize()
    require 'cards'
    require 'players'
    require 'ai'

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

    if player:is_ai() then
        player:selectCards()
        player:executeTurn()
    end
end

function Game:draw()
    love.graphics.printf('Obsessed', 0, 50, screen.width, "center")
    if player:is_ai() == true then
        love.graphics.print(tostring(player)..' (AI)', 50, 75)
    else
        love.graphics.print(tostring(player)..' (Human)', 50, 75)
    end
    love.graphics.print('Turn '..player_list:getTurn(), 50, 100)

    -- Display game board
    draw_pile:draw()
    discard_pile:draw()

    human = player_list:get_human()
    human.hand:draw()
    human.hidden:draw()
    human.visible:draw()
end

function Game:mousepressed(x, y, button)
    local player = player_list:getCurrentPlayer()
    if player:is_ai() then return end

    local active_pile = player:getActivePile()
    for i, card in ipairs(player:getActiveCards()) do
        if card:mousepressed() then
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
    if player:is_ai() then return end

    local active_pile = player:getActivePile()
    if key == 'p' and active_pile:isValidPlay() then
        player:executeTurn()
    elseif key == 'u' and not active_pile:has_valid_play() then
        player:executeTurn()
    elseif key == 'q' or key == 'escape' then
        love.event.push('quit')
    elseif key == '1' or key == '2' or key == '3' then
        active_pile:toggleSelected(tonumber(key))
    end
end
