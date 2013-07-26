--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

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
    self.front = love.graphics.newImage(img_filename(tostring(self)))
    self.back = love.graphics.newImage(img_filename('b1fv'))
    self.height = self.front:getHeight()
    self.width = self.front:getWidth()
    self.x = 0
    self.y = 0
    self.selected = false
end

function Card:__tostring()
    return tostring(self.face)..tostring(self.suit)
end

function Card:hover()
    local mx, my = love.mouse.getPosition()
    if mx > self.x and mx < self.x + self.width and
       my > self.y and my < self.y + self.height then
        return true
    end
    return false
end

function Card:mousepressed(x, y, button)
    if self:hover() then return true end
    return false
end

function Card:isSpecial()
    for _,card in ipairs(Card.SPECIAL_CARDS) do
        if card == self.face then return true end
    end
    return false
end

function Card:isSelected()
    return self.selected
end

function Card:setSelected()
    if self:isValidPlay() then
        self.selected = true
    end
end

function Card:clearSelected()
    self.selected = false
end

function Card:isActiveFace()
    return self.face == discard_pile:getActiveFace()
end

function Card:isValidPlay()
    local active_face = discard_pile:getActiveFace()
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

function CardPile:getNumCards()
    return #self.cards
end

function CardPile:sortByRank()
    table.sort(self.cards, function(a, b) return a.rank < b.rank end)
end

function CardPile:addCard(card)
    table.insert(self.cards, 1, card)
end

function CardPile:removeCard(num)
    if #self.cards == 0 then return nil end
    local num = num or 1
    return table.remove(self.cards, num)
end

function CardPile:removeCards()
    self.cards = {}
end

function CardPile:getCard(num)
    if #self.cards == 0 then return nil end
    local num = num or 1
    return self.cards[num]
end

function CardPile:getCards()
    return self.cards
end

function CardPile:isActivePile()
    local player = player_list:getCurrentPlayer()
    return self == player:getActivePile()
end

function CardPile:setSelected(num)
    if #self.cards < num then return end
    self.cards[num]:setSelected()
end

function CardPile:toggleSelected(num)
    if #self.cards < num then return end
    card = self.cards[num]
    if card:isSelected() then
        card:clearSelected()
    else
        card:setSelected()
    end
end

function CardPile:getSelectedSet()
    local idx = {}
    for i, card in ipairs(self.cards) do
        if card:isSelected() then
            card:clearSelected()
            table.insert(idx, i)
        end
    end
    return table.set(idx)
end

function CardPile:clearSelected()
    for _, card in ipairs(self.cards) do
        card:clearSelected()
    end
end

function CardPile:splitPile(a, b, idx)
    local set = table.set(idx)
    a:removeCards()
    b:removeCards()
    for i, card in ipairs(self.cards) do
        if set[i] then
            a:addCard(card)
        else
            b:addCard(card)
        end
    end
end

function CardPile:hasValidPlay()
    for _,card in ipairs(self.cards) do
        if card:isValidPlay() then return true end
    end
    return false
end

function CardPile:isValidPlay()
    local face = nil

    if not self:hasValidPlay() or not self:hasSelected() then
        return false
    end

    for _, card in ipairs(self.cards) do
        if card:isSelected() then
            if not card:isValidPlay() then
                return false
            else
                if face == nil then
                    face = card.face
                elseif face ~= card.face then
                    return false
                end
            end
        end
    end
    return true
end

function CardPile:getValidPlay()
    local valid = {}
    local face = nil
    self:sortByRank()
    for _,card in ipairs(self.cards) do
        if face ~= card.face and card:isValidPlay() then
            face = card.face
            table.insert(valid, card)
        end
    end
    return valid
end

function CardPile:hasCard(face)
    for i,card in ipairs(self.cards) do
        if card.face == face then return i end
    end
    return nil
end

function CardPile:hasSelected()
    for _, card in ipairs(self.cards) do
        if card:isSelected() then
            return true
        end
    end
    return false
end

function CardPile:playCards()
    local cards = {}
    local set = self:getSelectedSet()
    local player = player_list:getCurrentPlayer()
    -- Move selected cards to discard pile
    for i, card in ipairs(self.cards) do
        if set[i] then
            logger("plays a "..tostring(card))
            discard_pile:addCard(card)
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

function DrawPile:draw()
    local n = #self.cards
    if n > 0 then
        local img = self.cards[n].back
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

function DiscardPile:draw()
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

function DiscardPile:killPile()
    self:removeCards()
    logger('killed the discard pile')
end

function DiscardPile:getTopFace()
    local card = self:getCard()
    if not card then return nil end
    return card.face
end

function DiscardPile:getActiveFace()
    for _,card in ipairs(self.cards) do
        if card.face ~= 'R' then return card.face end
    end
    return nil
end

function DiscardPile:getRunLength()
    local run = 0
    local top_face = self:getTopFace()
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


PlayerHand = class('PlayerHand', CardPile)

PlayerHand.static.SIZE = 3

function PlayerHand:initialize()
    CardPile.initialize(self)
    for i = 1, PlayerHand.SIZE do self:addCard(draw_pile:removeCard()) end
end

function PlayerHand:draw()
    local hpos = 50
    local r, g, b, a = love.graphics.getColor()
    for _, card in ipairs(self:getCards()) do
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(card.front, hpos, 350)
        card.x = hpos
        card.y = 350
        if card:isSelected() then
            love.graphics.setColor(255, 0, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
        elseif card:hover() and card:isValidPlay() then
            love.graphics.setColor(255, 255, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
        end
        hpos = hpos + 75
    end
    love.graphics.setColor(r, g, b, a)
end


PlayerVisible = class('PlayerVisible', CardPile)

PlayerVisible.static.SIZE = 3

function PlayerVisible:initialize()
    CardPile.initialize(self)
    for i = 1, PlayerVisible.SIZE do self:addCard(draw_pile:removeCard()) end
end

function PlayerVisible:draw()
    local hpos = 60
    local r, g, b, a = love.graphics.getColor()
    for _, card in ipairs(self:getCards()) do
        love.graphics.setColor(255, 255, 255, 255)
        if card.x == 0 then
            card.x = hpos
            card.y = 480
        end
        hpos = hpos + 100
        love.graphics.draw(card.front, card.x, card.y)
        if card:isSelected() then
            love.graphics.setColor(255, 0, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
        elseif self:isActivePile() and card:hover() and card:isValidPlay() then
            love.graphics.setColor(255, 255, 255, 190)
            love.graphics.rectangle('line', card.x, card.y, card.width, card.height)
        end
    end
    love.graphics.setColor(r, g, b, a)
end


PlayerHidden = class('PlayerHidden', CardPile)

PlayerHidden.static.SIZE = 3

function PlayerHidden:initialize()
    CardPile.initialize(self)
    for i = 1, PlayerHidden.SIZE do self:addCard(draw_pile:removeCard()) end
end

function PlayerHidden:draw()
    local hpos = 50
    for _, card in ipairs(self:getCards()) do
        if card.x == 0 then
            card.x = hpos
            card.y = 480
        end
        hpos = hpos + 100
        love.graphics.draw(card.back, card.x, card.y)
    end
end
