--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

Card = class('Card')

Card.static.FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
Card.static.SUITS = { 'C', 'D', 'H', 'S' }
Card.static.SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }
Card.static.NON_SPECIAL_CARDS = { '4', '5', '6', '9', 'J', 'Q', 'K', 'A' }
Card.static.START_ORDER = { '4', '5', '6', '9', 'J', 'Q', 'K', 'A', '2', '3', '7', '8', '10', 'R' }
Card.static.INVALID_MOVES = {
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

function Card:initialize(face, suit, rank)
    self.face = face
    self.suit = suit
    self.rank = rank
end

function Card:is_special()
    for _,card in ipairs(Card.SPECIAL_CARDS) do
        if card == self.face then return true end
    end
    return false
end

function Card:is_active_face()
    return self.face == discard_pile:get_active_face()
end

function Card:is_valid_play()
    local active_face = discard_pile:get_active_face()
    if active_face == nil then return true end
    if active_face == self.face then return true end
    if Card.INVALID_MOVES[active_face] ~= nil then
        for _,move in ipairs(Card.INVALID_MOVES[active_face]) do
            if move == self.face then return false end
        end
    end
    return true
end


CardPile = class('CardPile')

function CardPile:initialize(...)
    self.cards = {}
    local arg = {n = select('#', ...), ...}
    for i = 1,arg.n do
        local pile = arg[i]
        for _,card in ipairs(pile.cards) do
            table.insert(self.cards, card)
        end
    end
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

function CardPile:remove_card(num)
    if #self.cards == 0 then return nil end
    local num = num or 1
    return table.remove(self.cards, num)
end

function CardPile:remove_cards()
    self.cards = {}
end

function CardPile:get_card(num)
    if #self.cards == 0 then return nil end
    local num = num or 1
    return self.cards[num]
end

function CardPile:split_pile(a, b, idx)
    local set = table.set(idx)
    a:remove_cards()
    b:remove_cards()
    for i,card in ipairs(self.cards) do
        if set[i] then
            a:add_card(card)
        else
            b:add_card(card)
        end
    end
end

function CardPile:has_valid_play()
    for _,card in ipairs(self.cards) do
        if card:is_valid_play() then return true end
    end
    return false
end

function CardPile:get_valid_play()
    local valid = {}
    local face = nil
    self:sort_by_rank()
    for _,card in ipairs(self.cards) do
        if face ~= card.face and card:is_valid_play() then
            face = card.face
            table.insert(valid, card)
        end
    end
    return valid
end

function CardPile:has_card(face)
    for i,card in ipairs(self.cards) do
        if card.face == face then return i end
    end
    return nil
end

function CardPile:play_cards(num)
    local cards = {}
    local set = table.set(num)
    for i,card in ipairs(self.cards) do
        if set[i] then
            print('*** Played a '..card.face..card.suit)
            discard_pile:add_card(card)
        else
            table.insert(cards, card)
        end
    end
    self.cards = cards
end


DrawPile = class('DrawPile', CardPile)

function DrawPile:initialize()
    CardPile.initialize(self)
    local num_decks = math.ceil(NUM_PLAYERS / 2)

    for deck = 1,num_decks do
        for _,suit in ipairs(Card.SUITS) do
            for rank,face in ipairs(Card.FACES) do
                local card = Card:new(face, suit, rank + 1)
                table.insert(self.cards, card)
            end
        end

        -- Add two Jokers to each deck
        for i=1,2 do
            local card = Card:new('R', '', #Card.FACES + 2)
            table.insert(self.cards, card)
        end
    end

    self:shuffle()
end

-- Implementation of the Fisher-Yates shuffle
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

function DiscardPile:kill_pile()
    self:remove_cards()
    print('*** Killed pile')
end

function DiscardPile:get_top_face()
    local card = self:get_card()
    if not card then return nil end
    return card.face
end

function DiscardPile:get_active_face()
    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then return card.face end
    end
    return nil
end

function DiscardPile:get_run_length()
    local run = 0
    local top_face = self:get_top_face()
    if not top_face then return 0 end
    for _,card in ipairs(self.cards) do
        if card.face == top_face then
            run = run + 1
        else
            break
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
    self:remove_cards()
    print('*** No valid moves, picked up '..count..' cards')
end


PlayerHand = class('PlayerHand', CardPile)

function PlayerHand:initialize()
    CardPile.initialize(self)
    for i = 1,HAND_SIZE do self:add_card(draw_pile:remove_card()) end
end


PlayerVisible = class('PlayerVisible', CardPile)

function PlayerVisible:initialize()
    CardPile.initialize(self)
    for i = 1,VISIBLE_SIZE do self:add_card(draw_pile:remove_card()) end
end


PlayerHidden = class('PlayerHidden', CardPile)

function PlayerHidden:initialize()
    CardPile.initialize(self)
    for i = 1,HIDDEN_SIZE do self:add_card(draw_pile:remove_card()) end
end
