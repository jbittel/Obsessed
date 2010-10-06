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

    self.visible.cards = slice(t, 1, HAND_SIZE)
    self.hand.cards = slice(t, HAND_SIZE + 1, HAND_SIZE)
end

function AIPlayer:execute_turn(discard_pile)
    local valid = {}
    local freq = self:get_frequencies(self.hand.cards)
    local top_face = discard_pile:get_top_face()
    local run = discard_pile:get_run_length()
 
    -- Copy all valid cards in hand
    for i,_ in ipairs(self.hand.cards) do
        self.hand.cards[i].play = true
        if self.hand:is_valid_play(discard_pile) then
            table.insert(valid, self.hand.cards[i])
        end
        self.hand.cards[i].play = false
    end

    -- Tweak card weights as necessary
    for _,card in ipairs(valid) do
--        card.weight = AI_FACE_WEIGHT[card.face]

        -- Prioritize killing the pile when possible
        if not card:is_special_card() then
            if card.face == top_face and
               (freq[card.face] + run >= 4) then
                card.weight = card.weight - 1
            elseif freq[card.face] >= 4 then
                card.weight = card.weight - 2
            end
        end
    end

    local active_face = self:select_card(valid)

    -- Mark selected face as in play
    -- TODO prioritize longer runs?
    -- TODO skip the play flag and play these cards directly
    for i,card in ipairs(self.hand.cards) do
        if active_face == card.face then
            self.hand.cards[i].play = true
            -- If non-special, flag all matching faces
            -- TODO there are times we want to play multiple special cards
            if card:is_special_card() then break end
        end
    end
end

function AIPlayer:get_frequencies(cards)
    local freq = {}

    for _,card in ipairs(cards) do
        freq[card.face] = (freq[card.face] or 0) + 1
    end

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

function AIPlayer:fuzzy_select(first, last)
    local diff = (last - first) + 1
    if diff <= 1 then return 1 end

    local a = {}
    local pos = 1
    local step = diff ^ 2
    local num = step

    for i = first, last do
        for j = pos, num do
            table.insert(a, i)
        end

        step = math.floor(step / 4)
        if step < 1 then break end
        pos = num + 1
        num = num + step
    end

    return a[math.random(#a)]
end
