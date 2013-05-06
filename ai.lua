--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

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
    self.ai_face_weight = table.copy(AIPlayer.BASE_AI_FACE_WEIGHT)
    Player.initialize(self, num)
end

function AIPlayer:swap_cards()
    local t = {}

    for _,card in ipairs(self.visible.cards) do
        card.weight = self.ai_face_weight[card.face]
        table.insert(t, card)
    end
    for _,card in ipairs(self.hand.cards) do
        card.weight = self.ai_face_weight[card.face]
        table.insert(t, card)
    end

    table.sort(t, function(a, b) return a.weight > b.weight end)

    self.visible.cards = table.slice(t, 1, VISIBLE_SIZE)
    self.hand.cards = table.slice(t, VISIBLE_SIZE + 1, HAND_SIZE)
end

function AIPlayer:executeTurn()
    if self:get_num_hand_cards() == 0 and
       self:get_num_visible_cards() > 0 then
        -- Play cards from visible set
        if self.visible:has_valid_play() then
            self:play_from_visible()
            Player:executeTurn()
            player_list:advanceNextPlayer()
        else
            discard_pile:pick_up_pile(player)
            player_list:endTurn()
        end
    elseif self:get_num_hand_cards() == 0 and
           self:get_num_hidden_cards() > 0 then
        -- Play cards from hidden set
        self:play_from_hidden()
        Player:executeTurn()
        player_list:advanceNextPlayer()
        -- If the hand isn't empty, the drawn card couldn't be played
        if self:get_num_hand_cards() ~= 0 then
            discard_pile:pick_up_pile(player)
            player_list:endTurn()
        end
    else
        -- Play cards from hand
        if self.hand:has_valid_play() then
            self:play_from_hand()
            Player:executeTurn()
            player_list:advanceNextPlayer()
        else
            discard_pile:pick_up_pile(player)
            player_list:endTurn()
        end
    end
end

function AIPlayer:play_from_hand()
    local face = self:select_card_face(self.hand)
    for _, card in ipairs(self.hand.cards) do
        if face == card.face then
            card:setSelected()
            if card:is_special() and not self:is_late_game() then break end
        end
    end
    self.hand:play_cards()
end

function AIPlayer:play_from_visible()
    local face = self:select_card_face(self.visible)
    for _, card in ipairs(self.visible.cards) do
        if face == card.face then
            card:setSelected()
        end
    end
    self.visible:play_cards()
end

function AIPlayer:play_from_hidden()
    self:add_to_hand(self.hidden)
    print('*** Drawing from hidden cards ('..self:get_num_hidden_cards()..' left)')
    if self.hand:has_valid_play() then
        self.hand.cards[1]:setSelected()
        self.hand:play_cards()
    end
end

function AIPlayer:select_card_face(cardpile)
    local valid = cardpile:get_valid_play()

    self:modify_card_weights(cardpile, valid)
    for _,card in ipairs(valid) do card.weight = self.ai_face_weight[card.face] end
    table.sort(valid, function(a, b) return a.weight < b.weight end)

    return valid[self:biased_rand(1, #valid)].face
end

function AIPlayer:get_frequencies(cards)
    local freq = {}
    for _,card in ipairs(cards) do freq[card.face] = (freq[card.face] or 0) + 1 end
    return freq
end

function AIPlayer:modify_card_weights(cardpile, valid)
    local freq = self:get_frequencies(cardpile.cards)
    local run = discard_pile:get_run_length()
    local next_player = player_list:get_next_player()

    self.ai_face_weight = table.copy(AIPlayer.BASE_AI_FACE_WEIGHT)

    for _,card in ipairs(valid) do
        -- Prioritize killing the pile when advisable
        if card:is_active_face() and not card:is_special() and
           (self:is_late_game() or self:is_behind()) then
            if freq[card.face] + run >= KILL_RUN_LEN or
               freq[card.face] >= KILL_RUN_LEN then
                self.ai_face_weight[card.face] = 0
            end
        end
    end

    if self:is_late_game() and next_player:get_num_hand_cards() == 0 then
        -- Aggressively play if the next player is close to winning
        self.ai_face_weight['3'] = 0
        self.ai_face_weight['R'] = 0
        self.ai_face_weight['7'] = 0
    end
end

function AIPlayer:is_late_game()
    -- Consider it "late game" when there's no cards to draw
    return draw_pile:get_num_cards() == 0
end

function AIPlayer:is_behind()
    return self.hand:get_num_cards() > draw_pile:get_num_cards()
end

function AIPlayer:biased_rand(min, max)
    if min == max then return min end
    local r = math.floor(min + (max - min) * math.random() ^ 10)
    if r > max then r = max end
    if r < min then r = min end
    return r
end
