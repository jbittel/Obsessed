--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

AI_FACE_WEIGHT = {
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

AI_SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }

function ai_play(pile, hand)
    local valid = {}

    -- Copy all valid cards in hand
    for i,_ in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            table.insert(valid, hand[i])
        end
        hand[i].play = false
    end

    -- Tweak card weights as necessary
    local freq = ai_get_frequencies(hand)
    local top_face = get_pile_top(pile)
    local run = get_pile_run(pile)

    for _,card in ipairs(valid) do
        card.weight = AI_FACE_WEIGHT[card.face]

        -- Prioritize killing the pile when possible
        if not ai_is_special_card(card.face) then
            if card.face == top_face and
               (freq[card.face] + run >= 4) then
                card.weight = 0
            elseif freq[card.face] >= 4 then
                card.weight = 0
            end
        end
    end

    -- TODO add fuzzy logic when selecting active face
    -- Sort ascending by weight and take top face
    table.sort(valid, function(a, b) return a.weight < b.weight end)
    local active_face = valid[1].face

    -- Mark selected face as in play
    for i,card in ipairs(hand) do
        if active_face == card.face then
            hand[i].play = true
            -- If non-special, flag all matching faces
            if ai_is_special_card(active_face) then break end
        end
    end
end

function ai_get_frequencies(cards)
    local freq = {}

    for _,card in ipairs(cards) do
        freq[card.face] = (freq[card.face] or 0) + 1
    end

    return freq
end

function ai_is_special_card(face)
    for _,card in ipairs(AI_SPECIAL_CARDS) do
        if card == face then
            return true
        end
    end

    return false
end

function ai_swap_cards(visible, hand, num)
    local t = {}

    for _,card in ipairs(visible) do
        card.weight = AI_FACE_WEIGHT[card.face]
        table.insert(t, card)
    end

    for _,card in ipairs(hand) do
        card.weight = AI_FACE_WEIGHT[card.face]
        table.insert(t, card)
    end

    table.sort(t, function(a, b) return a.weight > b.weight end)

    return slice(t, 1, num), slice(t, num + 1, num)
end
