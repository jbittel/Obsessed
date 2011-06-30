--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

AIPlayer = class('AIPlayer', Player)

function AIPlayer:initialize(num)
    Player.initialize(self, num)
    self.face_weight = table.copy(BASE_AI_FACE_WEIGHT)
end

function AIPlayer:display_hand()
    self.hand:display_cards('Hand', 0)
end

function AIPlayer:swap_cards()
    local t = {}

    for _,card in ipairs(self.visible.cards) do table.insert(t, card) end
    for _,card in ipairs(self.hand.cards) do table.insert(t, card) end

    table.sort(t, function(a, b) return a.weight > b.weight end)

    self.visible.cards = table.slice(t, 1, VISIBLE_SIZE)
    self.hand.cards = table.slice(t, VISIBLE_SIZE + 1, HAND_SIZE)
end

function AIPlayer:play_from_hand()
    local face = self:select_card_face(self.hand)
    local num = {}
    for i,card in ipairs(self.hand.cards) do
        if face == card.face then
            table.insert(num, i)
            if card:is_special_card() then break end
        end
    end
    self.hand:play_cards(num)
end

function AIPlayer:play_from_visible()
    local face = self:select_card_face(self.visible)
    local num = {}
    for i,card in ipairs(self.visible.cards) do
        if face == card.face then table.insert(num, i) end
    end
    self.visible:play_cards(num)
    print('*** Drawing from visible cards ('..self:get_num_visible_cards()..' left)')
end

function AIPlayer:play_from_hidden()
    self:add_to_hand(self.hidden)
    print('*** Drawing from hidden cards ('..self:get_num_hidden_cards()..' left)')
    if self.hand:has_valid_play() then self.hand:play_cards({1}) end
end

function AIPlayer:select_card_face(cardpile)
    local active_face = discard_pile:get_active_face()
    local valid = cardpile:get_valid_play()
    local freq = self:get_frequencies(cardpile.cards)
    local run = discard_pile:get_run_length()

    -- Apply current card weights
    for _,card in ipairs(valid) do
        card.weight = self.face_weight[card.face]
        -- Prioritize killing the pile when possible
        if not card:is_special_card() then
            if card.face == active_face and freq[card.face] + run >= KILL_RUN_LEN then
                card.weight = card.weight - 1
            elseif freq[card.face] >= KILL_RUN_LEN then
                card.weight = card.weight - 2
            end
        end
    end

    table.sort(valid, function(a, b) return a.weight < b.weight end)
    return valid[self:biased_rand(1, #valid)].face
end

function AIPlayer:get_frequencies(cards)
    local freq = {}
    for _,card in ipairs(cards) do freq[card.face] = (freq[card.face] or 0) + 1 end
    return freq
end

function AIPlayer:biased_rand(min, max)
    if min == max then return min end
    local r = math.floor(min + (max - min) * math.random() ^ 10)
    if r > max then r = max end
    if r < min then r = min end
    return r
end


AIPlayerDev = class('AIPlayerDev', AIPlayer)

function AIPlayerDev:select_card_face(cardpile)
    -- TODO Modify card weights as necessary
    self.face_weight['3'] = 0
    return AIPlayer.select_card_face(self, cardpile)
end
