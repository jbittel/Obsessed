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
}

SPECIAL_CARDS = { '2', '3', '7', '8', '10' } 

-- TODO tweak weights for specific game scenarios:
--      * killing the pile with 4+ stacks
--      * playing 3 when next player is near winning
function play_ai(pile, hand)
    local num = #hand
    local valid = {}

    -- Copy all valid cards in hand
    for i,_ in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            local card = hand[i]
            table.insert(valid, card)
            card.weight = FACE_WEIGHT[card.face]
        end
        hand[i].play = false
    end

    -- Sort ascending by weight and take top face
    table.sort(valid, function(a, b) return a.weight < b.weight end)
    -- TODO add fuzzy logic when selecting active face
    active_face = valid[1].face

    -- Mark selected face as in play
    for i=1,num do
        local face = hand[i].face

        if active_face == face then
            hand[i].play = true
            -- If non-special, flag all matching faces
            if is_special_card(face) then return end
        end
    end
end

function is_special_card(face)
    for _,card in ipairs(SPECIAL_CARDS) do
        if card == face then
            return true
        end
    end

    return false
end
