--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

FACE_WEIGHT = {
    ['2']  = 9,
    ['3']  = 11,
    ['4']  = 1,
    ['5']  = 2,
    ['6']  = 3,
    ['7']  = 10,
    ['8']  = 10,
    ['9']  = 3,
    ['10'] = 4,
    ['J']  = 5,
    ['Q']  = 6,
    ['K']  = 7,
    ['A']  = 8,
    ['R']  = 11,
}

SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }

function play_ai(pile, hand)
    local valid = {}

    -- Copy all valid cards in hand
    for i,card in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            table.insert(valid, card)
        end
        hand[i].play = false
    end

    -- Add and tweak card weights as necessary
    local freq = get_frequencies(hand)
    local top_face, run = get_pile_info(pile)

    for _,card in ipairs(valid) do
        card.weight = FACE_WEIGHT[card.face]

        -- Prioritize killing the pile when possible
        if not is_special_card(card.face) then
            if freq[card.face] >= 4 then
                card.weight = 0
            elseif card.face == top_face and
                   (freq[card.face] + run >= 4) then
                card.weight = 0
            end
        end
    end

    -- TODO add fuzzy logic when selecting active face
    -- Sort ascending by weight and take top face
    table.sort(valid, function(a, b) return a.weight < b.weight end)
    active_face = valid[1].face

    -- Mark selected face as in play
    for i,card in ipairs(hand) do
        if active_face == card.face then
            hand[i].play = true
            -- If non-special, flag all matching faces
            if is_special_card(card.face) then return end
        end
    end
end

function get_frequencies(cards)
    local freq = {}

    for _,card in ipairs(cards) do
        freq[card.face] = (freq[card.face] or 0) + 1
    end

    return freq
end

function is_special_card(face)
    for _,card in ipairs(SPECIAL_CARDS) do
        if card == face then
            return true
        end
    end

    return false
end
