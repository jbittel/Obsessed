--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = class('Player')

function Player:initialize(num)
    self.num = num
    self.hand = PlayerHand:new()
    self.visible = PlayerVisible:new()
    self.hidden = PlayerHidden:new()
    self:swap_cards()
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

function Player:play_initial_card(face)
    local num = {}
    for i,card in ipairs(self.hand.cards) do
        if face == card.face then
            table.insert(num, i)
            break
        end
    end
    self.hand:play_cards(num)
end


HumanPlayer = class('HumanPlayer', Player)

function HumanPlayer:swap_cards()
    local cards = {}
    for _,card in ipairs(self.hand.cards) do table.insert(cards, card) end
    for _,card in ipairs(self.visible.cards) do table.insert(cards, card) end
    self.hand.cards = {}
    self.visible.cards = {}
 
    print('\n+++ Select your '..VISIBLE_SIZE..' VISIBLE cards')
    io.write('### Starting cards:\t')
    for i,card in ipairs(cards) do io.write(i..':'..card.face..card.suit..' ') end
    io.write('\n')

    local num = self:get_card_input(1, #cards, VISIBLE_SIZE) 
    local set = table.set(num)
    for i,card in ipairs(cards) do
        if set[i] then
            table.insert(self.visible.cards, card)
        else
            table.insert(self.hand.cards, card)
        end
    end
end

function HumanPlayer:play_from_hand()
    local num = {}
    print('+++ Select cards from your hand')
    while true do
        num = self:get_card_input(1, self.hand:get_num_cards())
        if self:validate_card_input(self.hand, num) then
            break
        else
            print('!!! Invalid selection')
        end
    end
    self.hand:play_cards(num)
end

function HumanPlayer:play_from_visible()
    local num = {}
    print('+++ Select cards from your visible set')
    while true do
        num = self:get_card_input(1, self.visible:get_num_cards())
        if self:validate_card_input(self.visible, num) then
            break
        else
            print('!!! Invalid selection')
        end
    end
    self.visible:play_cards(num)
end

function HumanPlayer:play_from_hidden()
    print('+++ Select a card from your hidden set')
    local num = self:get_card_input(1, self.hidden:get_num_cards(), 1)
    for _,n in ipairs(num) do self:add_to_hand(self.hidden, n) end
    if self.hand:has_valid_play() then self.hand:play_cards({1}) end
end

function HumanPlayer:get_card_input(min, max, total)
    local total = total or 0
    local num = {}
    local get_input = true

    while get_input do
        num = {}
        io.write('+++ Enter card number(s): ')
        local str = io.stdin:read'*l'
        for n in string.gmatch(str, "%d+") do table.insert(num, tonumber(n)) end

        -- Ensure the numbers provided are valid indexes
        get_input = false
        for _,n in ipairs(num) do
            if n < min or n > max then
                print('!!! Invalid card selection')
                get_input = true
                break
            elseif total ~= 0 and #num ~= total then
                print('!!! You must select '..total..' cards')
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
    self.curr_player = self:next_player_num()
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

function PlayerList:next_player_num()
    local num_players = #self.players
    local curr_player = self.curr_player

    if curr_player == 0 then return self:init_player_num() end

    if not self.reverse then
        curr_player = curr_player + 1
    else
        curr_player = curr_player - 1
    end

    if curr_player > num_players then curr_player = 1 end
    if curr_player < 1 then curr_player = num_players end

    print('\n=== PLAYER '..curr_player)
    return curr_player
end

-- Pick starting player by matching the first instance of
-- a non-special face with a card in a player's hand
function PlayerList:init_player_num()
    local start_order = {}

    for _,face in ipairs(Card.NON_SPECIAL_CARDS) do table.insert(start_order, face) end
    for _,face in ipairs(Card.SPECIAL_CARDS) do table.insert(start_order, face) end
 
    for _,face in ipairs(start_order) do
        for _,player in ipairs(self.players) do
            if player.hand:has_card(face) then
                print('\n=== PLAYER '..player.num)
                player:play_initial_card(face)
                return player.num
            end
        end
    end
end
