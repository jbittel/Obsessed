--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = class('Player')

function Player:initialize(num)
    self.num = num
    self.ai = false
    self.hand = PlayerHand:new()
    self.visible = PlayerVisible:new()
    self.hidden = PlayerHidden:new()
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
    self.hand:display_cards('Hand')
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

function Player:draw_card(cards)
    local card = cards:draw_card()
    if card ~= nil then
        self.hand:add_card(card)
    end
end


HumanPlayer = class('HumanPlayer', Player)

function HumanPlayer:initialize(num)
    super.initialize(self, num)
end

function HumanPlayer:swap_cards()
    -- TODO allow human players to swap with visible stack
    return
end

function HumanPlayer:execute_turn()
    local num = {}
    local get_cards = true

    self:display_hand()
    self.visible:display_cards('Visible')
    self.hidden:display_cards('Hidden', 0)

    while get_cards do
        local get_input = true

        while get_input do
            num = {}
            io.write('Enter card number(s): ')
            local str = io.stdin:read'*l'
            for n in string.gmatch(str, "%d+") do
                table.insert(num, tonumber(n))
            end

            -- Ensure the numbers provided are valid indexes
            get_input = false
            for _,n in ipairs(num) do
                if n < 1 or n > self.hand:get_num_cards() then
                    print('!!! Invalid card selection')
                    get_input = true
                    break
                end
            end
        end

        get_cards = false
        local face = nil
        for _,i in ipairs(num) do
            local card = self.hand:get_card(i)
            if face == nil then face = card.face end
            -- Ensure all selected cards are valid plays
            -- and are the same face
            if not self.hand:is_valid_play(card.face) or face ~= card.face then
                print('!!! Invalid play')
                get_cards = true
                break
            end
        end
    end

    self.hand:play_cards(num)
end


PlayerList = class('PlayerList')

function PlayerList:initialize()
    self.players = {}
    self.curr_player = 0
    self.reverse = false
    self.turn_over = true

    for i = 1,NUM_PLAYERS do
        if i == 1 then
            player = HumanPlayer:new(i)
        else
            player = AIPlayer:new(i)
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
    print('*** Direction reversed!')
    self.reverse = not self.reverse
end

function PlayerList:end_turn(b)
    self.turn_over = b
end

function PlayerList:is_turn_over()
    return self.turn_over
end

function PlayerList:next_player_num(curr_player)
    local num_players = #self.players

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
    -- a non-special face with a card in a player's hand
    for _,face in ipairs(NON_SPECIAL_CARDS) do
        for _,player in ipairs(self.players) do
            if player.hand:has_card(face) then
                print('*** Starting with player '..player.num)
                return player.num
            end
        end
    end

    -- Tiebreaker: if a matching non-special card isn't found,
    -- look at special cards also
    for _,face in ipairs(SPECIAL_CARDS) do
        for _,player in ipairs(self.players) do
            if player.hand:has_card(face) then
                print('*** Starting with player '..player.num)
                return player.num
            end
        end
    end

    return 1
end
