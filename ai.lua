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

function ai_play(pile, hand)
    local valid = {}
    local freq = ai_get_frequencies(hand)
    local top_face = get_pile_top(pile)
    local run = get_pile_run(pile)
 
    -- Copy all valid cards in hand
    for i,_ in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            table.insert(valid, hand[i])
        end
        hand[i].play = false
    end

    -- Tweak card weights as necessary
    for _,card in ipairs(valid) do
        card.weight = AI_FACE_WEIGHT[card.face]

        -- Prioritize killing the pile when possible
        if not ai_is_special_card(card.face) then
            if card.face == top_face and
               (freq[card.face] + run >= 4) then
                card.weight = card.weight - 1
            elseif freq[card.face] >= 4 then
                card.weight = card.weight - 2
            end
        end
    end

    local active_face = ai_select_card(valid)

    -- Mark selected face as in play
    -- TODO prioritize longer runs?
    for i,card in ipairs(hand) do
        if active_face == card.face then
            hand[i].play = true
            -- If non-special, flag all matching faces
            -- TODO there are times we want to play multiple special cards
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

function ai_select_card(cards)
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
 
    return faces[ai_fuzzy_select(1, #faces)].face
end

function ai_fuzzy_select(first, last)
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
