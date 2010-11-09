--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

AIPlayer = class('AIPlayer', Player)

function AIPlayer:initialize(num)
    super.initialize(self, num)
    self.ai = true
end

function AIPlayer:display_hand()
    self.hand:display_cards('Hand', 0)
end

function AIPlayer:swap_cards()
    local t = {}

    for _,card in ipairs(self.visible.cards) do
        card.weight = AI_FACE_WEIGHT[card.face]
        table.insert(t, card)
    end

    for _,card in ipairs(self.hand.cards) do
        card.weight = AI_FACE_WEIGHT[card.face]
        table.insert(t, card)
    end

    table.sort(t, function(a, b) return a.weight > b.weight end)

    self.visible.cards = table.slice(t, 1, HAND_SIZE)
    self.hand.cards = table.slice(t, HAND_SIZE + 1, HAND_SIZE)
end

function AIPlayer:draw_visible_card()
    -- TODO sort by valid cards and card weight before selecting
    self:draw_card(self.visible, self:fuzzy_select(1, self:get_num_visible_cards()))
end

function AIPlayer:draw_hidden_card()
    self:draw_card(self.hidden)
end

function AIPlayer:execute_turn()
    local active_face = discard_pile:get_active_face()
    local valid = self.hand:get_valid_play()
    local freq = self:get_frequencies(self.hand.cards)
    local run = discard_pile:get_run_length()

    -- Tweak card weights as necessary
    for _,card in ipairs(valid) do
        -- Prioritize killing the pile when possible
        if not card:is_special_card() then
            if card.face == active_face and freq[card.face] + run >= 4 then
                card.weight = card.weight - 1
            elseif freq[card.face] >= 4 then
                card.weight = card.weight - 2
            end
        end
    end

    local face = self:select_card(valid)

    -- Select indices of cards to play
    -- TODO prioritize longer runs?
    local num = {}
    for i,card in ipairs(self.hand.cards) do
        if face == card.face then
            table.insert(num, i)
            -- TODO there are times we want to play multiple special cards
            if card:is_special_card() then break end
        end
    end
    self.hand:play_cards(num)
end

function AIPlayer:get_frequencies(cards)
    local freq = {}
    for _,card in ipairs(cards) do freq[card.face] = (freq[card.face] or 0) + 1 end
    return freq
end

function AIPlayer:select_card(cards)
    local faces = {}
    local face = nil

    -- Extract a list of unique card faces
    table.sort(cards, function(a, b) return a.rank < b.rank end)
    for _,card in ipairs(cards) do
        if face ~= card.face then
            face = card.face
            table.insert(faces, card)
        end
    end

    -- Sort card faces by associated weight
    table.sort(faces, function(a, b) return a.weight < b.weight end)
 
    return faces[self:fuzzy_select(1, #faces)].face
end

function AIPlayer:fuzzy_select(min, max)
    if min == max or min > max then return min end
    local diff = (max - min) + 1

    local a = {}
    local pos = 1
    local step = diff ^ 2
    local num = step

    for i = min, max do
        while pos < num do
            table.insert(a, i)
            pos = pos + 1
        end

        step = math.floor(step / 4)
        if step < 1 then break end
        pos = num + 1
        num = num + step
    end

    return a[math.random(#a)]
end
