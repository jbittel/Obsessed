--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

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
    player = player_list:advance_next_player()
end

function Game:update()
--    print('=== '..tostring(player))

    if self.turn == 1 then
        player:play_initial_card()
        self.turn = self.turn + 1
        return
    end

    if not player:is_ai() then
        return
    end

    if player:get_num_hand_cards() == 0 and
           player:get_num_visible_cards() > 0 then
        -- Play cards from visible set
        if player.visible:has_valid_play() then
            player:play_from_visible()
        else
            discard_pile:pick_up_pile(player)
            player_list:end_turn(true)
        end
    elseif player:get_num_hand_cards() == 0 and
           player:get_num_hidden_cards() > 0 then
        -- Play cards from hidden set
        player:play_from_hidden()
        -- If the hand isn't empty, the drawn card couldn't be played
        if player:get_num_hand_cards() ~= 0 then
            discard_pile:pick_up_pile(player)
            player_list:end_turn(true)
        end
    else
        -- Play cards from hand
        if player.hand:has_valid_play() then
            player:play_from_hand()
        else
            discard_pile:pick_up_pile(player)
            player_list:end_turn(true)
        end
    end

    -- TODO do we want to stop when a player wins,
    -- make it a binary win/loss condition?
    -- Test for win condition
    if player:get_num_cards() == 0 then
        print('*** '..tostring(player)..' wins!')
        player_list:add_winner()
        -- Test for game over condition
        if player_list:get_num_players() == 1 then
            require 'game_over'
            player_list:add_winner(player_list:next_player_num())
            scene = GameOver:new(player_list.winners)
        end
    end

    -- TODO refactor 'turn' nomenclature:
    -- a turn is technically one play, so it's
    -- really more about getting another turn,
    -- not continuing the same one
    if player_list:is_turn_over() then
        player = player_list:advance_next_player()
    end
    self.turn = self.turn + 1
end

function Game:draw()
    love.graphics.printf('Obsessed', 0, 50, screen.width, "center")
    if player:is_ai() == true then
        love.graphics.print(tostring(player)..' (AI)', 50, 75)
    else
        love.graphics.print(tostring(player)..' (Human)', 50, 75)
    end
    love.graphics.print(self.turn, 50, 100)

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

    -- TODO check intersection of appropriate card pile
    local mx, my = love.mouse.getPosition()
    local r, g, b, a = love.graphics.getColor()
    for _,card in ipairs(human.hand.cards) do
        if card.selected then
            love.graphics.setColor(0, 0, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
            love.graphics.setColor(r, g, b, a)
        end
        if card:mouse_intersects(mx, my) then
            love.graphics.setColor(255, 255, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
            love.graphics.setColor(r, g, b, a)
        end
    end
end

function Game:mousepressed(x, y, button)
    local mx, my = love.mouse.getPosition()
    for _,card in ipairs(human.hand.cards) do
        if card:mouse_intersects(mx, my) then
            if card.selected then
                card.selected = false
            else
                card.selected = true
            end
            return
        end
    end
    -- TODO check for click on Play button
end

function Game:keypressed(key, unicode)
    if key == 'p' and not player:is_ai() then
        -- Play cards
        player.hand:play_cards()
        if player_list:is_turn_over() then
            player = player_list:advance_next_player()
        end
    end
end
