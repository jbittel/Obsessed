--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }
NON_SPECIAL_CARDS = { '4', '5', '6', '9', 'J', 'Q', 'K', 'A' }

INVALID_MOVES = {
    ['3'] = { '2', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' },
    ['5'] = { '4' },
    ['6'] = { '4', '5' },
    ['7'] = { '8', '9', 'J', 'Q', 'K', 'A' },
    ['9'] = { '4', '5', '6' },
    ['J'] = { '4', '5', '6', '9' },
    ['Q'] = { '4', '5', '6', '9', 'J' },
    ['K'] = { '4', '5', '6', '9', 'J', 'Q' },
    ['A'] = { '4', '5', '6', '9', 'J', 'Q', 'K' },
}

AI_FACE_WEIGHT = {
    ['2']  = 8,
    ['3']  = 12,
    ['4']  = 1,
    ['5']  = 2,
    ['6']  = 3,
    ['7']  = 9,
    ['8']  = 10,
    ['9']  = 3,
    ['10'] = 11,
    ['J']  = 4,
    ['Q']  = 5,
    ['K']  = 6,
    ['A']  = 7,
    ['R']  = 12
}


Card = class('Card')

function Card:initialize(face, suit, rank)
    self.face = face
    self.suit = suit
    self.rank = rank
    self.weight = AI_FACE_WEIGHT[face]
end

function Card:is_special_card()
    for _,card in ipairs(SPECIAL_CARDS) do
        if card == self.face then return true end
    end
    return false
end


CardPile = class('CardPile')

function CardPile:initialize()
    self.cards = {}
end

function CardPile:get_num_cards()
    return #self.cards
end

function CardPile:display_cards(prefix, limit)
    local limit = limit or -1
    io.write('### '..prefix..':\t'..#self.cards..' cards\t')
    for i,card in ipairs(self.cards) do
        if limit ~= -1 and i > limit then break end
        io.write(i..':'..card.face..card.suit..' ')
    end
    io.write('\n')
end

function CardPile:sort_by_rank()
    table.sort(self.cards, function(a, b) return a.rank < b.rank end)
end

function CardPile:add_card(card)
    table.insert(self.cards, 1, card)
end

function CardPile:draw_card()
    if #self.cards > 0 then
        return table.remove(self.cards, 1)
    else
        return nil
    end
end


DrawPile = class('DrawPile', CardPile)

function DrawPile:initialize()
    super.initialize(self)
    local num_decks = math.ceil(NUM_PLAYERS / 2)

    for deck = 1,num_decks do
        for _,suit in ipairs(SUITS) do
            for rank,face in ipairs(FACES) do
                local card = Card:new(face, suit, rank + 1)
                table.insert(self.cards, card)
            end
        end

        if NUM_PLAYERS > 2 then
            -- Add two Jokers to each deck
            for i=1,2 do
                local card = Card:new('R', '', #FACES + 2)
                table.insert(self.cards, card)
            end
        end
    end

    self:shuffle()
end

-- Implementation of the Knuth shuffle
function DrawPile:shuffle()
    local n = #self.cards
    math.randomseed(os.time())
    while n > 1 do
        local k = math.random(n)
        self.cards[n], self.cards[k] = self.cards[k], self.cards[n]
        n = n - 1
    end
end


DiscardPile = class('DiscardPile', CardPile)

function DiscardPile:initialize()
    super.initialize(self)
end

function DiscardPile:kill_pile()
    self.cards = {}
    print('*** Killed pile')
end

function DiscardPile:get_top_face()
    if #self.cards == 0 then return nil end
    return self.cards[1].face
end

function DiscardPile:get_active_face()
    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then return card.face end
    end
    return nil
end

function DiscardPile:get_run_length()
    local active_face = self:get_active_face()
    local run = 0

    if active_face == nil then return 0 end

    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then
            if active_face == card.face then
                run = run + 1
            else
                break
            end
        end
    end

    return run
end

function DiscardPile:pick_up_pile(player)
    local count = 0
    for _,card in ipairs(self.cards) do
        if card.face ~= '3' then
            player.hand:add_card(card)
            count = count + 1
        end
    end
    self.cards = {}
    print('*** No valid moves, picked up '..count..' cards')
end


PlayerHand = class('PlayerHand', CardPile)

function PlayerHand:initialize()
    super.initialize(self)
    for i = 1,HAND_SIZE do
        self:add_card(draw_pile:draw_card())
    end
end

function PlayerHand:has_valid_play()
    for _,card in ipairs(self.cards) do
        if self:is_valid_play(card.face) then return true end
    end
    return false
end

function PlayerHand:get_valid_play()
    local valid = {}
    for _,card in ipairs(self.cards) do
        if self:is_valid_play(card.face) then
            table.insert(valid, card)
        end
    end
    return valid
end

function PlayerHand:is_valid_play(face)
    local active_face = discard_pile:get_active_face()
    if active_face == nil then return true end
    if active_face == face then return true end
    if INVALID_MOVES[active_face] ~= nil then
        for _,move in ipairs(INVALID_MOVES[active_face]) do
            if move == face then return false end
        end
    end
    return true
end

function PlayerHand:has_card(face)
    for _,card in ipairs(self.cards) do
        if card.face == face then return true end
    end
    return false
end

function PlayerHand:play_cards(cards)
    local hand = {}
    local set = table.set(cards)
    for i,card in ipairs(self.cards) do
        if set[i] then
            print('*** Playing a '..card.face..card.suit)
            discard_pile:add_card(card)
        else
            table.insert(hand, card)
        end
    end
    self.cards = hand
end


PlayerVisible = class('PlayerVisible', CardPile)

function PlayerVisible:initialize()
    super.initialize(self)
    for i = 1,HAND_SIZE do
        self:add_card(draw_pile:draw_card())
    end
end


PlayerHidden = class('PlayerHidden', CardPile)

function PlayerHidden:initialize()
    super.initialize(self)
    for i = 1,HAND_SIZE do
        self:add_card(draw_pile:draw_card())
    end
end
