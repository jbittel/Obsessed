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
--    self:swap_cards()
end

function Player:__tostring()
    return 'Player '..tostring(self.num)
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

function Player:add_to_hand(cards, num)
    local card = cards:remove_card(num)
    if card ~= nil then self.hand:add_card(card) end
    return card
end

function Player:playInitialCard()
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
    self.hand:play_cards()
    self:executeTurn()
end

function Player:getActivePile()
    local active_pile = nil

    if self:get_num_hand_cards() > 0 then
        active_pile = self.hand
    else
        if self:get_num_visible_cards() > 0 then
            -- Play cards from visible set
            active_pile = self.visible
        elseif self:get_num_hidden_cards() > 0 then
            -- Play cards from hidden set
            active_pile = self.hidden
        end
    end
    return active_pile
end

function Player:getActiveCards()
    return self:getActivePile():getCards()
end

function Player:executeTurn()
    print("player:executeturn")
    -- Apply card face rules
    local top_face = discard_pile:get_top_face()
    if top_face == '8' then
        player_list:continueTurn()
    elseif top_face == '10' then
        discard_pile:kill_pile()
        player_list:continueTurn()
    elseif top_face == 'R' then
        player_list:reverseDirection()
        player_list:endTurn()
    else
        player_list:endTurn()
    end

    -- Kill pile if 4+ top cards match
    if discard_pile:get_run_length() >= KILL_RUN_LEN then
        discard_pile:kill_pile()
        player_list:continueTurn()
    end

    -- Keep player's hand at a minimum of HAND_SIZE cards
    -- as long as there's cards to draw
    local player = player_list:getCurrentPlayer()
    while player:get_num_hand_cards() < HAND_SIZE and
          draw_pile:get_num_cards() > 0 do
        player:add_to_hand(draw_pile)
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

--    player_list:advanceNextPlayer()
end


HumanPlayer = class('HumanPlayer', Player)

function HumanPlayer:executeTurn()
    -- TODO check for valid play

    print("humanplayer:executeturn")
    local active_pile = player:getActivePile()
    active_pile:play_cards()

    Player:executeTurn()
    player_list:advanceNextPlayer()
end


PlayerList = class('PlayerList')

function PlayerList:initialize()
    self.players = {}
    self.winners = {}
    self.curr_player = 0
    self.reverse = false
    self.turn_over = true
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

function PlayerList:advanceNextPlayer()
    if self.turn_over == true then
        self.curr_player = self:next_player_num()
        self.turn = self.turn + 1
    end
end

function PlayerList:get_num_players()
    return #self.players
end

function PlayerList:reverseDirection()
    print('*** Direction reversed!')
    self.reverse = not self.reverse
end

function PlayerList:continueTurn()
    self.turn_over = false
end

function PlayerList:endTurn()
    self.turn_over = true
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
                print('\n*** Starting with '..tostring(player))
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
    self:endTurn()
end
