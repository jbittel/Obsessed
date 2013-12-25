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
    self.weight = 0
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

function Card:draw(front, active)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(255, 255, 255, 255)
    if front then
        love.graphics.draw(self.front, self.x, self.y)
    else
        love.graphics.draw(self.back, self.x, self.y)
    end
    if self:isSelected() then
        love.graphics.setColor(255, 0, 255, 190)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    elseif active and self:hover() then
        love.graphics.setColor(255, 255, 255, 190)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    end
    love.graphics.setColor(r, g, b, a)
end

function Card:isSpecial()
    for _, face in ipairs(Card.SPECIAL_CARDS) do
        if face == self.face then return true end
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

function Card:toggleSelected()
    if self:isSelected() then
        self:clearSelected()
    else
        self:setSelected()
    end
end

function Card:clearSelected()
    self.selected = false
end

function Card:getFace()
    return self.face
end

function Card:getPosition()
    return self.x, self.y
end

function Card:setPosition(x, y)
    self.x = x
    self.y = y
end

function Card:getHeight()
    return self.height
end

function Card:getWidth()
    return self.width
end

function Card:getWeight()
    return self.weight
end

function Card:setWeight(weight)
    self.weight = weight
end

function Card:getRank()
    return self.rank
end

function Card:isActiveFace()
    return self.face == discard_pile:getActiveFace()
end

function Card:isValidPlay()
    local active_face = discard_pile:getActiveFace()
    if active_face == nil then return true end
    if active_face == self.face then return true end
    if Card.INVALID_MOVES[active_face] ~= nil then
        for _, move in ipairs(Card.INVALID_MOVES[active_face]) do
            if move == self.face then return false end
        end
    end
    return true
end


CardPile = class('CardPile')

function CardPile:initialize(...)
    self.cards = {}
    local arg = {n = select('#', ...), ...}
    for i = 1, arg.n do
        local pile = arg[i]
        for _, card in ipairs(pile:getCards()) do
            table.insert(self.cards, card)
        end
    end
end

function CardPile:__tostring()
    card_list = ''
    for _, card in ipairs(self.cards) do
        card_list = card_list..tostring(card)..', '
    end
    return '['..string.sub(card_list, 1, -3)..']'
end

function CardPile:getNumCards()
    return #self.cards
end

function CardPile:sortByRank()
    table.sort(self.cards, function(a, b) return a:getRank() < b:getRank() end)
end

function CardPile:sortByWeight()
    table.sort(self.cards, function(a, b) return a:getWeight() < b:getWeight() end)
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

function CardPile:getUniqueCards()
    local unique = {}
    local face = nil
    self:sortByRank()
    for _, card in ipairs(self.cards) do
        if face ~= card:getFace() then
            face = card:getFace()
            table.insert(unique, card)
        end
    end
    return unique
end

function CardPile:slice(start, len)
    local pile = CardPile:new()
    local len = len or (#self.cards - start + 1)
    local stop = start + len - 1
    for i = start, stop do pile:addCard(self.cards[i]) end
    return pile
end

function CardPile:isActivePile()
    local player = player_list:getCurrentPlayer()
    return self == player:getActivePile()
end

function CardPile:setSelected(num)
    if #self.cards < num then return end
    self.cards[num]:setSelected()
end

function CardPile:setSelectedFace(face)
    for _, card in ipairs(self.cards) do
        if face == card:getFace() then
            card:setSelected()
        end
    end
end

function CardPile:toggleSelected(num)
    if #self.cards < num then return end
    self.cards[num]:toggleSelected()
end

function CardPile:clearSelected()
    for _, card in ipairs(self.cards) do
        card:clearSelected()
    end
end

function CardPile:getFrequencies()
    local freq = {}
    for _, card in ipairs(self.cards) do
        freq[card:getFace()] = (freq[card:getFace()] or 0) + 1
    end
    return freq
end

function CardPile:hasValidPlay()
    for _, card in ipairs(self.cards) do
        if card:isValidPlay() then return true end
    end
    return false
end

function CardPile:isValidPlay()
    if not self:hasValidPlay() or not self:hasSelected() then
        return false
    end

    local face = nil
    for _, card in ipairs(self.cards) do
        if card:isSelected() then
            if not card:isValidPlay() then
                return false
            else
                if face == nil then
                    face = card:getFace()
                elseif face ~= card:getFace() then
                    return false
                end
            end
        end
    end
    return true
end

function CardPile:getValidPlay()
    local valid = CardPile:new()
    for _, card in ipairs(self:getUniqueCards()) do
        if card:isValidPlay() then
            valid:addCard(card)
        end
    end
    return valid
end

function CardPile:hasCard(face)
    for _, card in ipairs(self.cards) do
        if card:getFace() == face then
            return true
        end
    end
    return false
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
    -- Move selected cards to discard pile
    for _, card in ipairs(self.cards) do
        if card:isSelected() then
            card:clearSelected()
            discard_pile:addCard(card)
            logger("plays a "..tostring(card))
        else
            table.insert(cards, card)
        end
    end
    self.cards = cards
end

function CardPile:isHidden(pile)
    return self.class.name == 'PlayerHidden'
end


DrawPile = class('DrawPile', CardPile)

function DrawPile:initialize()
    CardPile.initialize(self)
    local num_decks = math.ceil(Game.NUM_PLAYERS / 2)

    for deck = 1, num_decks do
        for _, suit in ipairs(Card.SUITS) do
            for rank, face in ipairs(Card.FACES) do
                table.insert(self.cards, Card:new(face, suit, rank + 1))
            end
        end

        -- Add two Jokers to each deck
        for i = 1, 2 do
            table.insert(self.cards, Card:new('R', '', #Card.FACES + 2))
        end
    end

    self:shuffle()
end

function DrawPile:draw(x, y)
    local card = self:getCard()
    if card then
        card:setPosition(x, y)
        card:draw(false, false)
        love.graphics.print(self:getNumCards(), x, y + card:getHeight())
    end
end

-- Implementation of the Fisher-Yates shuffle
function DrawPile:shuffle()
    local n = #self.cards
    -- TODO switch to lrandom for better random numbers
    -- http://lua-users.org/lists/lua-l/2007-03/msg00564.html 
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
    while n > 1 do
        local k = math.random(n)
        self.cards[n], self.cards[k] = self.cards[k], self.cards[n]
        n = n - 1
    end
end


DiscardPile = class('DiscardPile', CardPile)

function DiscardPile:draw(x, y)
    for _, card in ipairs(self.cards) do
        if card:getFace() == 'R' then
            card:setPosition(x + 10, y)
            card:draw(true, false)
        else
            card:setPosition(x, y)
            card:draw(true, false)
            love.graphics.print(self:getNumCards(), x, y + card:getHeight())
            break
        end
    end
end

function DiscardPile:killPile()
    self:removeCards()
    logger('killed the discard pile')
end

function DiscardPile:getTopFace()
    local card = self:getCard()
    if not card then return nil end
    return card:getFace()
end

function DiscardPile:getActiveFace()
    for _, card in ipairs(self.cards) do
        local face = card:getFace()
        if face ~= 'R' then return face end
    end
    return nil
end

function DiscardPile:getRunLength()
    local top_face = self:getTopFace()
    local run = 0
    if not top_face then return run end
    for _, card in ipairs(self.cards) do
        if card:getFace() == top_face then
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

function PlayerHand:draw(x, y, spacing, active)
    active = active or self:isActivePile()
    local screen_width = love.graphics.getWidth()
    local displayed = 0

    for _, card in ipairs(self:getCards()) do
        card:setPosition(x, y)
        card:draw(true, active)
        displayed = displayed + 1
        x = x + card:getWidth() + spacing
        if x + card:getWidth() + spacing > screen_width then break end
    end

    -- If not all cards fit on screen, show remaining count
    local r, g, b, a = love.graphics.getColor()
    local not_displayed = self:getNumCards() - displayed
    if not_displayed > 0 then
        local card = self:getCard()
        local count = '+'..not_displayed..' cards'
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(count, screen.width - (font.default:getWidth(count) + spacing), y + card:getHeight())
    end
    love.graphics.setColor(r, g, b, a)
end


PlayerVisible = class('PlayerVisible', CardPile)

PlayerVisible.static.SIZE = 3

function PlayerVisible:initialize()
    CardPile.initialize(self)
    for i = 1, PlayerVisible.SIZE do self:addCard(draw_pile:removeCard()) end
end

function PlayerVisible:draw(x, y, spacing, active)
    active = active or self:isActivePile()
    for _, card in ipairs(self:getCards()) do
        if card:getPosition() == 0 then
            card:setPosition(x, y)
        end
        card:draw(true, active)
        x = x + card:getWidth() + spacing
    end
end


PlayerHidden = class('PlayerHidden', CardPile)

PlayerHidden.static.SIZE = 3

function PlayerHidden:initialize()
    CardPile.initialize(self)
    for i = 1, PlayerHidden.SIZE do self:addCard(draw_pile:removeCard()) end
end

function PlayerHidden:draw(x, y, spacing)
    for _, card in ipairs(self:getCards()) do
        if card:getPosition() == 0 then
            card:setPosition(x, y)
        end
        card:draw(false, self:isActivePile())
        x = x + card:getWidth() + spacing
    end
end

function PlayerHidden:toggleSelected(num)
    CardPile.toggleSelected(self, num)
    player_list:getCurrentPlayer():addToHand(self, num)
end
