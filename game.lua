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

    self.turn = 1

    draw_pile = DrawPile:new('Draw')
    discard_pile = DiscardPile:new('Discard')
    player_list = PlayerList:new()
end

function Game:update()
    local player = player_list:getCurrentPlayer()
--    print("Current player: "..tostring(player))
--    print("Current turn: "..tostring(player_list:getTurn()))

    if player_list:getTurn() == 1 then
        player:playInitialCard()
        return
    end

    -- TODO check has_valid_play
    if player:is_ai() then
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
    love.graphics.print(player_list:getTurn(), 50, 100)

    -- Display game board
    draw_pile:display()
    discard_pile:display()

    -- TODO if human, display Play button

    -- TODO blows up when the human has won and
    -- is pulled out of the active player list
    human = player_list:get_human()
    human.hand:display()
    human.hidden:display()
    human.visible:display()

    -- TODO deselect cards each play

    local mx, my = love.mouse.getPosition()
    local r, g, b, a = love.graphics.getColor()
    for _, card in ipairs(human:getActiveCards()) do
        if card.selected then
            love.graphics.setColor(255, 0, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
            love.graphics.setColor(r, g, b, a)
        end
        if card:mouse_intersects(mx, my) and
           card:is_valid_play() then
            love.graphics.setColor(255, 255, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
            love.graphics.setColor(r, g, b, a)
        end
    end
end

function Game:mousepressed(x, y, button)
    local player = player_list:getCurrentPlayer()
    if not player:is_ai() then
        local mx, my = love.mouse.getPosition()
        for _, card in ipairs(player:getActiveCards()) do
            if card:mouse_intersects(mx, my) and
               card:is_valid_play() then
                if card.selected then
                    card.selected = false
                else
                    card.selected = true
                end
                return
            end
        end
    end
end

function Game:keypressed(key, unicode)
    local player = player_list:getCurrentPlayer()
    if not player:is_ai() then
        local active_pile = player:getActivePile()
        if key == 'p' and active_pile:has_selected() then
            player:executeTurn()
        elseif key == 'u' and not active_pile:has_valid_play() then
            discard_pile:pick_up_pile(player)
        elseif key == 'q' or key == 'escape' then
            love.event.push('quit')
        end
    end
end
