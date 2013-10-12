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
    self.ai_face_weight = table_copy(AIPlayer.BASE_AI_FACE_WEIGHT)
    Player.initialize(self, num)
end

function AIPlayer:swapCards()
    local pile = CardPile:new(self.visible, self.hand)
    for _, card in ipairs(pile:getCards()) do
        card.weight = self.ai_face_weight[card:getFace()]
    end
    pile:sortByWeight()

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
            if card:isSpecial() and not self:isLateGame() then break end
        end
    end
end

function AIPlayer:selectFromVisible()
    if not self.visible:hasValidPlay() then return end
    local face = self:selectCardFace(self.visible)
    for _, card in ipairs(self.visible:getCards()) do
        if face == card:getFace() then
            card:setSelected()
        end
    end
end

function AIPlayer:selectFromHidden()
    self:addToHandFromHidden(1)
    logger('drew from hidden cards, '..self:getNumHiddenCards()..' left')
end

function AIPlayer:selectCardFace(pile)
    local valid = pile:getValidPlay()
    self:modifyCardWeights(valid)

    for _, card in ipairs(valid:getCards()) do
        card.weight = self.ai_face_weight[card:getFace()]
    end
    valid:sortByWeight()

    return valid:getCard(biased_random(1, valid:getNumCards())):getFace()
end

function AIPlayer:modifyCardWeights(pile)
    self.ai_face_weight = table_copy(AIPlayer.BASE_AI_FACE_WEIGHT)

    -- Prioritize killing the pile when advisable
    for _, card in ipairs(pile:getCards()) do
        if card:isActiveFace() and not card:isSpecial() and
           (self:isLateGame() or self:isBehind()) then
            if self:canKillPile(pile, card:getFace()) then
                self.ai_face_weight[card:getFace()] = 0
            end
        end
    end

    -- Play aggressively if the next player is close to winning
    if self:isLateGame() and self:nextPlayerWinning() then
        self.ai_face_weight['3'] = 0
        self.ai_face_weight['R'] = 0
        self.ai_face_weight['7'] = 0
    end
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
    -- less than 6 cards total
    local next_player = player_list:getNextPlayer()
    return next_player:getNumCards() < 6
end

function AIPlayer:canKillPile(pile, face)
    local freq = pile:getFrequencies()
    local run = discard_pile:getRunLength()
    return freq[face] + run >= KILL_RUN_LEN
end
