--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = { num = 0, ai = false }

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.num = num
    self.ai = ai
    self.hand = PlayerHand:new()
    self.visible = PlayerVisible:new()
    self.hidden = PlayerHidden:new()

    return o
end

function Player:is_ai_player()
    return self.ai
end

function Player:get_player_num()
    return self.num
end

function Player:display_hand()
    if self.hand:get_num_cards() == 0 then return end

    self.hand:sort_by_rank()
    self.hand:display_cards()
end

function Player:get_num_cards()
    return self.hand:get_num_cards() + self.visible:get_num_cards() + self.hidden:get_num_cards()
end


HumanPlayer = Player:new{ ai = false }

function HumanPlayer:swap_cards()
    -- TODO allow human players to swap with visible stack
    return
end

function HumanPlayer:play_turn()
    self:display_hand()
end


PlayerList = { players = {} }

function PlayerList:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.curr_player = 0
    self.reverse = false
    self.turn_over = true

    return o
end

function PlayerList:init_players(draw_pile)
    for i = 1,NUM_PLAYERS do
        if i == 1 then
            player = HumanPlayer:new{ num = i }
        else
            player = AIPlayer:new{ num = i }
        end

        for i = 1,HAND_SIZE do
            table.insert(player.hidden.cards, draw_pile:draw_card())
            table.insert(player.visible.cards, draw_pile:draw_card())
            table.insert(player.hand.cards, draw_pile:draw_card())
        end

        player:swap_cards()
        table.insert(self.players, player)
    end
end

function PlayerList:get_next_player()
    self:next_player_num()
    return self.players[self.curr_player]
end

function PlayerList:get_num_players()
    return #self.players
end

function PlayerList:reverse_order()
    self.reverse = not self.reverse
end

function PlayerList:end_turn(b)
    self.turn_over = b
end

function PlayerList:is_turn_over()
    return self.turn_over
end

function PlayerList:next_player_num(curr_player)
    local num_players = self:get_num_players()

    if self.curr_player == 0 then
        self.curr_player = self:init_player_num()
        return
    end

    if not self.reverse then
        self.curr_player = self.curr_player + 1
    else
        self.curr_player = self.curr_player - 1
    end

    if self.curr_player > num_players then self.curr_player = 1 end
    if self.curr_player < 1 then self.curr_player = num_players end
end

function PlayerList:init_player_num()
    -- Pick starting player by matching the first instance of
    -- a non-special face with a card in a player's hand and
    -- marking that card for play
    for _,face in ipairs(NON_SPECIAL_CARDS) do
        for _,player in ipairs(self.players) do
            for _,card in ipairs(player.hand.cards) do
                if face == card.face then
                    card.play = true
                    return player.num
                end
            end
        end
    end

    -- Tiebreaker: if a matching non-special card isn't found,
    -- look at special cards also
    for _,face in ipairs(SPECIAL_CARDS) do
        for _,player in ipairs(self.players) do
            for _,card in ipairs(player.hand.cards) do
                if face == card.face then
                    card.play = true
                    return player.num
                end
            end
        end
    end

    return 1
end
