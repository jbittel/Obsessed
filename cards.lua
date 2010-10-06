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


Card = { suit = '', face = '', rank = -1, play = false }

function Card:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function Card:is_special_card()
    for _,card in ipairs(SPECIAL_CARDS) do
        if card == self.face then
            return true
        end
    end

    return false
end


CardPile = {}

function CardPile:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.cards = {}
    return o
end

function CardPile:get_num_cards()
    return #self.cards
end

function CardPile:display_cards(limit)
    limit = limit or 0

    if self:get_num_cards() == 0 then
        print('*** No cards to display')
        return
    end

    io.write('*** '..self:get_num_cards()..' cards: ')
    for i,card in ipairs(self.cards) do
        if limit ~= 0 and i > limit then break end
        io.write(i..':'..card.face..card.suit..' ')
    end
    io.write('\n')
end

function CardPile:sort_by_rank()
    table.sort(self.cards, function(a, b) return a.rank < b.rank end)
end

function CardPile:clear_play()
    for _,card in ipairs(self.cards) do
        card.play = false
    end
end


DrawPile = CardPile:new()

function DrawPile:init_cards()
    local num_decks = math.ceil(NUM_PLAYERS / 2)

    for deck = 1,num_decks do
        for _,suit in ipairs(SUITS) do
            for rank,face in ipairs(FACES) do
                local card = Card:new{suit = suit, face = face, rank = rank + 1}
                table.insert(self.cards, card)
            end
        end

        if NUM_PLAYERS > 2 then
            -- Add two Jokers to each deck
            for i=1,2 do
                local card = Card:new{suit = '', face = 'R', rank = #FACES + 2}
                table.insert(self.cards, card)
            end
        end
    end

    self:shuffle()
end

function DrawPile:shuffle()
    local n = self:get_num_cards()

    math.randomseed(os.time())

    -- Implementation of the Knuth shuffle
    while n > 1 do
        local k = math.random(n)
        self.cards[n], self.cards[k] = self.cards[k], self.cards[n]
        n = n - 1
    end
end

function DrawPile:draw_card()
    if self:get_num_cards() > 0 then
        return table.remove(self.cards, 1)
    else
        return nil
    end
end


DiscardPile = CardPile:new()

function DiscardPile:kill_pile()
    print('*** Killed pile')
    self.cards = {}
end

function DiscardPile:get_top_face()
    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then
            return card.face
        end
    end

    return nil
end

function DiscardPile:get_run_length()
    local top_face = self:get_top_face()
    local run = 0

    if top_face == nil then return 0 end

    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then
            if top_face == card.face then
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
            table.insert(player.hand, card)
            count = count + 1
        end
    end

    self.cards = {}
    print('*** No valid moves, picked up '..count..' cards')
end


PlayerHand = CardPile:new()

function PlayerHand:get_active_face()
    local active_face = nil

    for _,card in ipairs(self.cards) do
        if card.play == true then
            if active_face == nil then
                active_face = card.face
            else
                if active_face ~= card.face then
                    return nil 
                end
            end
        end
    end

    return active_face
end

function PlayerHand:has_valid_play(discard_pile)
    for i,_ in ipairs(self.cards) do
        self.cards[i].play = true
        if self:is_valid_play(discard_pile) then
            self.cards[i].play = false
            return true
        end
        self.cards[i].play = false
    end

    return false
end

function PlayerHand:is_valid_play(discard_pile)
    local active_face = self:get_active_face()
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


PlayerVisible = CardPile:new()


PlayerHidden = CardPile:new()