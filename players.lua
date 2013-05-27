--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = class('Player')

function Player:initialize(num)
    self.num = num
    self.hand = PlayerHand:new('Hand')
    self.visible = PlayerVisible:new('Visible')
    self.hidden = PlayerHidden:new('Hidden')
--  TODO self:swap_cards()
end

function Player:__tostring()
    return 'P'..tostring(self.num)
end

function Player:is_ai()
    if self.class.name == 'AIPlayer' then
        return true
    else
        return false
    end
end

function Player:get_num_cards()
    return self.hand:get_num_cards() + self.visible:get_num_cards() + self.hidden:get_num_cards()
end

function Player:get_num_hand_cards()
    return self.hand:get_num_cards()
end

function Player:get_num_visible_cards()
    return self.visible:get_num_cards()
end

function Player:get_num_hidden_cards()
    return self.hidden:get_num_cards()
end

function Player:addToHand(cards, num)
    local card = cards:remove_card(num)
    if card ~= nil then self.hand:add_card(card) end
end

function Player:addToHandFromHidden(num)
    local card = self.hidden:remove_card(num)
    if card ~= nil then
        card:setSelected()
        self.hand:add_card(card)
    end
end

function Player:selectInitialCard()
    local initial_face = nil
    for _,face in ipairs(Card.START_ORDER) do
        if self.hand:has_card(face) then
            initial_face = face
            break
        end
    end
    for _, card in ipairs(self.hand.cards) do
        if initial_face == card.face then
            card:setSelected()
        end
    end
end

function Player:getActivePile()
    local active_pile = nil

    if self:get_num_hand_cards() > 0 then
        active_pile = self.hand
    elseif self:get_num_visible_cards() > 0 then
        active_pile = self.visible
    elseif self:get_num_hidden_cards() > 0 then
        active_pile = self.hidden
    end
    return active_pile
end

function Player:getActiveCards()
    return self:getActivePile():getCards()
end

function Player:executeTurn()
    local next_player = true
    local active_pile = self:getActivePile()
    local player = player_list:getCurrentPlayer()

    if active_pile:isValidPlay() then
        active_pile:playCards()
    else
        discard_pile:pick_up_pile(player)
    end

    -- Apply card face rules
    local top_face = discard_pile:get_top_face()
    if top_face == '8' then
        next_player = false
    elseif top_face == '10' then
        discard_pile:kill_pile()
        next_player = false
    elseif top_face == 'R' then
        player_list:reverseDirection()
    end

    -- Kill pile if 4+ top cards match
    if discard_pile:get_run_length() >= KILL_RUN_LEN then
        discard_pile:kill_pile()
        next_player = false
    end

    -- Keep player's hand at a minimum of HAND_SIZE cards
    -- as long as there's cards to draw
    while player:get_num_hand_cards() < HAND_SIZE and
          draw_pile:get_num_cards() > 0 do
        player:addToHand(draw_pile)
    end

    -- TODO do we want to stop when a player wins,
    -- make it a binary win/loss condition?
    -- Test for win condition
    if player:get_num_cards() == 0 then
        logger('wins!')
        player_list:add_winner()
        next_player = true
        -- Test for game over condition
        if player_list:get_num_players() == 1 then
            require 'game_over'
            player_list:add_winner(player_list:next_player_num())
            scene = GameOver:new(player_list.winners)
        end
    end

    if next_player == true then
        player_list:advancePlayer()
    else
        player_list:advanceTurn()
    end
end


HumanPlayer = class('HumanPlayer', Player)


PlayerList = class('PlayerList')

function PlayerList:initialize()
    self.players = {}
    self.winners = {}
    self.curr_player = 0
    self.reverse = false
    self.turn = 1

    for i = 1,NUM_PLAYERS do
        if i == 1 then
            player = HumanPlayer:new(i)
        else
            player = AIPlayer:new(i)
        end

        table.insert(self.players, player)
    end

    self.curr_player = self:init_player_num()
end

function PlayerList:getCurrentPlayer()
    return self.players[self.curr_player]
end

function PlayerList:get_next_player()
    return self.players[self:next_player_num()]
end

function PlayerList:get_human()
    -- TODO make this less brittle
    return self.players[1]
end

function PlayerList:advancePlayer()
    self:advanceTurn()
    self.curr_player = self:next_player_num()
end

function PlayerList:advanceTurn()
    self.turn = self.turn + 1
end

function PlayerList:get_num_players()
    return #self.players
end

function PlayerList:reverseDirection()
    logger('reversed the direction')
    self.reverse = not self.reverse
end

function PlayerList:getTurn()
    return self.turn
end

function PlayerList:next_player_num()
    local num_players = #self.players
    local curr_player = self.curr_player

    if not self.reverse then
        curr_player = curr_player + 1
    else
        curr_player = curr_player - 1
    end

    if curr_player > num_players then curr_player = 1 end
    if curr_player < 1 then curr_player = num_players end

    return curr_player
end

-- Pick starting player by matching the first instance of
-- a non-special face with a card in a player's hand
function PlayerList:init_player_num()
    for _,face in ipairs(Card.START_ORDER) do
        for _,player in ipairs(self.players) do
            if player.hand:has_card(face) then
                return player.num
            end
        end
    end
    return 1
end

function PlayerList:add_winner(num)
    local player_num = num or self.curr_player
    local player = table.remove(self.players, player_num)
    table.insert(self.winners, player)
end
