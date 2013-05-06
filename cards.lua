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
    self.front = love.graphics.newImage('images/'..tostring(self)..'.png')
    self.back = love.graphics.newImage('images/b1fv.png')
    self.height = self.front:getHeight()
    self.width = self.front:getWidth()
    self.x = 0
    self.y = 0
    self.selected = false
end

function Card:__tostring()
    return tostring(self.face)..tostring(self.suit)
end

function Card:mouse_intersects(mx, my)
    if mx > self.x and mx < self.x + self.width and
       my > self.y and my < self.y + self.height then
        return true
    end
    return false
end

function Card:is_special()
    for _,card in ipairs(Card.SPECIAL_CARDS) do
        if card == self.face then return true end
    end
    return false
end

function Card:is_selected()
    return self.selected
end

function Card:setSelected()
    self.selected = true
end

function Card:clearSelected()
    self.selected = false
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

function CardPile:initialize(name, ...)
    self.name = name
    self.cards = {}
    local arg = {n = select('#', ...), ...}
    for i = 1,arg.n do
        local pile = arg[i]
        for _,card in ipairs(pile.cards) do
            table.insert(self.cards, card)
        end
    end
end

function CardPile:__tostring()
    return 'the '..string.lower(self.name)..' pile'
end

function CardPile:get_num_cards()
    return #self.cards
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

function CardPile:getCards()
    return self.cards
end

function CardPile:getSelectedSet()
    local idx = {}
    for i, card in ipairs(self.cards) do
        if card:is_selected() then
            card:clearSelected()
            table.insert(idx, i)
        end
    end
    return table.set(idx)
end

function CardPile:split_pile(a, b, idx)
    local set = table.set(idx)
    a:remove_cards()
    b:remove_cards()
    for i, card in ipairs(self.cards) do
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

function CardPile:has_selected()
    for _, card in ipairs(self.cards) do
        if card.selected then
            return true
        end
    end
    return false
end

function CardPile:play_cards()
    local cards = {}
    local set = self:getSelectedSet()
    -- Move selected cards to discard pile
    for i, card in ipairs(self.cards) do
        if set[i] then
            print("playing "..tostring(card))
            discard_pile:add_card(card)
        else
            table.insert(cards, card)
        end
    end
    self.cards = cards
end


DrawPile = class('DrawPile', CardPile)

function DrawPile:initialize(name)
    CardPile.initialize(self, name)
    local num_decks = math.ceil(NUM_PLAYERS / 2)

    for deck = 1, num_decks do
        for _,suit in ipairs(Card.SUITS) do
            for rank,face in ipairs(Card.FACES) do
                local card = Card:new(face, suit, rank + 1)
                table.insert(self.cards, card)
            end
        end

        -- Add two Jokers to each deck
        for i = 1, 2 do
            local card = Card:new('R', '', #Card.FACES + 2)
            table.insert(self.cards, card)
        end
    end

    self:shuffle()
end

function DrawPile:display()
    local n = #self.cards
    if n > 0 then
        local img = self.cards[n].front
        love.graphics.draw(img, 50, 200)
    end
    love.graphics.print(n, 50, 300)
end

-- Implementation of the Fisher-Yates shuffle
function DrawPile:shuffle()
    local n = #self.cards
    -- TODO switch to lrandom for better random numbers
    -- http://lua-users.org/lists/lua-l/2007-03/msg00564.html 
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
    -- math.randomseed(os.time())
    -- math.random()
    -- math.random()
    -- math.random()
    while n > 1 do
        local k = math.random(n)
        self.cards[n], self.cards[k] = self.cards[k], self.cards[n]
        n = n - 1
    end
end


DiscardPile = class('DiscardPile', CardPile)

function DiscardPile:display()
    for _, card in ipairs(self.cards) do
        if card.face == 'R' then
            love.graphics.draw(card.front, 175, 200)
        else
            love.graphics.draw(card.front, 150, 200)
            break
        end
    end
    love.graphics.print(#self.cards, 150, 300)
end

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
            card.visible = true
            player.hand:add_card(card)
            count = count + 1
        end
    end
    self:remove_cards()
    print('*** No valid moves, picked up '..count..' cards')
    player_list:endTurn()
    player_list:advanceNextPlayer()
end


PlayerHand = class('PlayerHand', CardPile)

function PlayerHand:initialize(name)
    CardPile.initialize(self, name)
    for i = 1,HAND_SIZE do self:add_card(draw_pile:remove_card()) end
end

function PlayerHand:__tostring()
    return 'your '..string.lower(self.name)
end

function PlayerHand:display()
    local hpos = 50
    for i = 1, #self.cards do
        love.graphics.draw(self.cards[i].front, hpos, 350)
        self.cards[i].x = hpos
        self.cards[i].y = 350
        hpos = hpos + 75
    end
end


PlayerVisible = class('PlayerVisible', CardPile)

function PlayerVisible:initialize(name)
    CardPile.initialize(self, name)
    for i = 1,VISIBLE_SIZE do self:add_card(draw_pile:remove_card()) end
end

function PlayerVisible:__tostring()
    return 'your '..string.lower(self.name)..' cards'
end

function PlayerVisible:display()
    local hpos = 60
    for i = 1, #self.cards do
        love.graphics.draw(self.cards[i].front, hpos, 480)
        self.cards[i].x = hpos
        self.cards[i].y = 480
        hpos = hpos + 100
    end
end


PlayerHidden = class('PlayerHidden', CardPile)

function PlayerHidden:initialize(name)
    CardPile.initialize(self, name)
    for i = 1,HIDDEN_SIZE do self:add_card(draw_pile:remove_card()) end
end

function PlayerHidden:__tostring()
    return 'your '..string.lower(self.name)..' cards'
end

function PlayerHidden:display()
    local hpos = 50
    for i = 1, #self.cards do
        love.graphics.draw(self.cards[i].back, hpos, 480)
        self.cards[i].x = hpos
        self.cards[i].y = 480
        hpos = hpos + 100
    end
end
