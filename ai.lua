--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

FACE_WEIGHT = {
    ['2']  = 8,
    ['3']  = 11,
    ['4']  = 1,
    ['5']  = 2,
    ['6']  = 3,
    ['7']  = 9,
    ['8']  = 10,
    ['9']  = 3,
    ['10'] = 10,
    ['J']  = 4,
    ['Q']  = 5,
    ['K']  = 6,
    ['A']  = 7,
    ['R']  = 11
}

SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }

function play_ai(pile, hand)
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
    local freq = get_frequencies(hand)
    local top_face = get_pile_top(pile)
    local run = get_pile_run(pile)

    for _,card in ipairs(valid) do
        card.weight = FACE_WEIGHT[card.face]

        -- Prioritize killing the pile when possible
        if not is_special_card(card.face) then
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
            if is_special_card(active_face) then break end
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
