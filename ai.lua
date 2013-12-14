--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

AIPlayer = class('AIPlayer', Player)

AIPlayer.static.BASE_AI_FACE_WEIGHT = {
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

function AIPlayer:initialize(num)
    Player.initialize(self, num)
    self:swapCards()
end

function AIPlayer:swapCards()
    local pile = CardPile:new(self.visible, self.hand)
    self:modifyCardWeights(pile)
    self.visible = pile:slice(1, PlayerVisible.SIZE)
    self.hand = pile:slice(PlayerVisible.SIZE + 1, PlayerHand.SIZE)
end

function AIPlayer:selectCards()
    if self:getNumHandCards() > 0 then
        self:selectFromHand()
    elseif self:getNumVisibleCards() > 0 then
         self:selectFromVisible()
    elseif self:getNumHiddenCards() > 0 then
        self:selectFromHidden()
    end
end

function AIPlayer:selectFromHand()
    if not self.hand:hasValidPlay() then return end
    local face = self:selectCardFace(self.hand)
    for _, card in ipairs(self.hand:getCards()) do
        if face == card:getFace() then
            card:setSelected()
            if card:isSpecial() and not self:isLateGame()
               and not self:isBehind() then break end
        end
    end
end

function AIPlayer:selectFromVisible()
    if not self.visible:hasValidPlay() then return end
    local face = self:selectCardFace(self.visible)
    self.visible:setSelectedFace(face)
end

function AIPlayer:selectFromHidden()
    self.hidden:toggleSelected(1)
    logger('drew from hidden cards, '..self:getNumHiddenCards()..' left')
end

function AIPlayer:selectCardFace(pile)
    local valid = pile:getValidPlay()
    if valid:getNumCards() == 1 then return valid:getCard():getFace() end
    self:modifyCardWeights(valid)
    return valid:getCard(biased_random(1, valid:getNumCards())):getFace()
end

function AIPlayer:modifyCardWeights(pile)
    local face_weight = table_copy(AIPlayer.BASE_AI_FACE_WEIGHT)
    local sort_descending = false

    -- Prioritize killing the pile when advisable
    for _, card in ipairs(pile:getCards()) do
        if card:isActiveFace() and not card:isSpecial() and
           (self:isLateGame() or self:isBehind()) then
            if self:canKillPile(pile, card:getFace()) then
                face_weight[card:getFace()] = 0
            end
        end
    end

    if self:isLateGame() and self:nextPlayerWinning() then
        -- If the next player is close to winning, invert the pile
        -- sort order so more aggressive cards are played
        face_weight['2'] = 0
        sort_descending = true
    end

    for _, card in ipairs(pile:getCards()) do
        card:setWeight(face_weight[card:getFace()])
    end
    pile:sortByWeight(sort_descending)
end

function AIPlayer:isLateGame()
    -- Consider it "late game" when there's no cards to draw
    return draw_pile:getNumCards() == 0
end

function AIPlayer:isBehind()
    -- Consider it "behind" when there are more cards in hand
    -- then are in the draw pile
    return self.hand:getNumCards() > draw_pile:getNumCards()
end

function AIPlayer:nextPlayerWinning()
    -- Consider the next player close to winning when they have
    -- less than the visible and hidden cards left
    local next_player = player_list:getNextPlayer()
    return next_player:getNumCards() < PlayerVisible.SIZE + PlayerHidden.SIZE
end

function AIPlayer:canKillPile(pile, face)
    local freq = pile:getFrequencies()
    local run = discard_pile:getRunLength()
    return freq[face] + run >= Game.KILL_RUN_LENGTH
end
