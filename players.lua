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

function Player:is_ai_player()
    return self.ai
end

function Player:display_hand()
    if self.hand:get_num_cards() == 0 then return end

    self.hand:sort_by_rank()
    self.hand:display_cards()
end


PlayerList = { players = {} }

function PlayerList:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.curr_player = 0

    return o
end

function PlayerList:init_players()
    for i = 1, NUM_PLAYERS do
        player = Player:new{ num = i, ai = false }
        table.insert(players, player)

        for i = 1,num_cards do
            table.insert(player.hidden, deal_card())
            table.insert(player.visible, deal_card())
            table.insert(player.hand, deal_card())
        end

        if i == 1 then
            player.ai = false
        else
            player.ai = true
        end
    
        -- TODO allow human players to swap with visible stack
        if player.ai == true then
            player.visible, player.hand = ai_swap_cards(player.visible, player.hand, num_cards)
        end
    end

    return function()
        if curr_player == 0 then
            curr_player = init_player_num(players)
        else
            curr_player = next_player_num(#players, curr_player, reverse)
        end

        return players[curr_player]
    end
end
