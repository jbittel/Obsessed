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

    self.hand = PlayerHand:new()
    self.visible = PlayerVisible:new()
    self.hidden = PlayerHidden:new()

    return o
end

function Player:swap_cards()
    -- TODO allow human players to swap with visible stack
    return
end

function Player:play_turn()
    self:display_hand()
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
    return #self.hand + #self.visible + #self.hidden
end

function Player:has_valid_play(discard_pile)
    for i,_ in ipairs(self.hand) do
        hand[i].play = true
        if self:is_valid_play(discard_pile) then
            hand[i].play = false
            return true
        end
        hand[i].play = false
    end

    return false
end

function Player:is_valid_play(discard_pile)
    local active_face = self.hand:get_active_face()
    local top_face = discard_pile:get_top_face()

    if active_face == nil then return false end
    if top_face == nil then return true end
    if top_face == active_face then return true end

    if INVALID_MOVES[top_face] ~= nil then
        for _,move in ipairs(INVALID_MOVES[top_face]) do
            if move == active_face then
                return false
            end
        end
    end

    return true
end


PlayerList = { players = {} }

function PlayerList:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.curr_player = 0
    self.reverse = false

    return o
end

function PlayerList:init_players(draw_pile)
    for i = 1, NUM_PLAYERS do
        if i == 1 then
            player = Player:new{ num = i }
        else
            player = AIPlayer:new{ num = i }
        end
        table.insert(self.players, player)

        for i = 1,HAND_SIZE do
            table.insert(player.hidden, draw_pile:draw_card())
            table.insert(player.visible, draw_pile:draw_card())
            table.insert(player.hand, draw_pile:draw_card())
        end

        player:swap_cards()
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

function PlayerList:init_player_num()
    -- Pick starting player by matching the first instance of
    -- a non-special face with a card in a player's hand and
    -- marking that card for play
    for _,face in ipairs(NON_SPECIAL_CARDS) do
        for _,player in ipairs(self.players) do
            for _,card in ipairs(player.hand) do
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
            for _,card in ipairs(player.hand) do
                if face == card.face then
                    card.play = true
                    return player.num
                end
            end
        end
    end

    return 1
end

function PlayerList:next_player_num(curr_player)
    local num_players = self:get_num_players()

    if not self.reverse then
        self.curr_player = self.curr_player + 1
    else
        self.curr_player = self.curr_player - 1
    end

    if self.curr_player > num_players then self.curr_player = 1 end
    if self.curr_player < 1 then self.curr_player = num_players end
end
