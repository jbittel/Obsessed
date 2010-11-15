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

    self:swap_cards()
end

function Player:is_ai_player()
    return self.ai
end

function Player:get_player_num()
    return self.num
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
    local card = cards:get_card(num)
    if card ~= nil then self.hand:add_card(card) end
end


HumanPlayer = class('HumanPlayer', Player)

function HumanPlayer:initialize(num)
    super.initialize(self, num)
end

function HumanPlayer:swap_cards()
    local cards = {}
    for _,card in ipairs(self.hand.cards) do table.insert(cards, card) end
    for _,card in ipairs(self.visible.cards) do table.insert(cards, card) end
    self.hand.cards = {}
    self.visible.cards = {}
 
    print('Select your VISIBLE cards')
    io.write('### Starting cards:\t')
    for i,card in ipairs(cards) do io.write(i..':'..card.face..card.suit..' ') end
    io.write('\n')

    local num = self:get_card_input(1, #cards, 3)
    local set = table.set(num)
    for i,card in ipairs(cards) do
        if set[i] then
            table.insert(self.visible.cards, card)
        else
            table.insert(self.hand.cards, card)
        end
    end
end

function HumanPlayer:execute_turn()
    local num = {}
    while true do
        num = self:get_card_input(1, self.hand:get_num_cards())
        if self:validate_card_input(self.hand, num) then
            break
        else
            print('!!! Invalid play')
        end
    end
    self.hand:play_cards(num)
end

function HumanPlayer:get_card_input(min, max, total)
    local get_input = true
    local total = total or 0
    local num = {}

    while get_input do
        num = {}
        io.write('Enter card number(s): ')
        local str = io.stdin:read'*l'
        for n in string.gmatch(str, "%d+") do table.insert(num, tonumber(n)) end

        -- Ensure the numbers provided are valid indexes
        get_input = false
        for _,n in ipairs(num) do
            if n < min or n > max then
                print('!!! Invalid card selection')
                get_input = true
                break
            elseif total ~= 0 and #num > total then
                print('!!! Limited to '..total..' cards')
                get_input = true
                break
            end
        end
        if #num == 0 then get_input = true end
    end

    return num
end

function HumanPlayer:validate_card_input(cards, num)
    local face = nil
    for _,i in ipairs(num) do
        local card = cards:show_card(i)
        if face == nil then face = card.face end
        -- Ensure all selected cards are valid plays and are the same face
        if not cards:is_valid_play(card.face) or face ~= card.face then return false end
    end
    return true
end

function HumanPlayer:display_hand()
    self.hand:sort_by_rank()
    self.hand:display_cards('Hand')
end

function HumanPlayer:draw_visible_card()
    local num = {}
    print('Select a visible card')
    while true do
        num = self:get_card_input(1, self.visible:get_num_cards())
        if self:validate_card_input(self.visible, num) then
            break
        else
            print('!!! Invalid draw')
        end
    end

    -- TODO force drawn cards to be played
    local set = table.set(num)
    local v = {}
    for i,card in ipairs(self.visible.cards) do
        if set[i] then
            self.hand:add_card(card)
        else
            table.insert(v, card)
        end
    end
    self.visible.cards = v
end

function HumanPlayer:draw_hidden_card()
    print('Select a hidden card')
    local num = self:get_card_input(1, self.hidden:get_num_cards(), 1)
    for _,n in ipairs(num) do self:add_to_hand(self.hidden, n) end
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
