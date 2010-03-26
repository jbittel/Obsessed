
-- TODO add Joker as a playable card
FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

INVALID_MOVES = {
    ['3'] = { '2', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' },
    ['5'] = { '4' },
    ['6'] = { '4', '5' },
    ['7'] = { '8', '9', 'J', 'Q', 'K', 'A' },
    ['9'] = { '4', '5', '6' },
    ['J'] = { '4', '5', '6', '9' },
    ['Q'] = { '4', '5', '6', '9', 'J' },
    ['K'] = { '4', '5', '6', '9', 'J', 'Q' },
    ['A'] = { '4', '5', '6', '9', 'J', 'Q', 'K' },
}

NUM_DECKS = 1
NUM_PLAYERS = 2

players = {}
cards = {}

function init_game()
    cards = build_decks(NUM_DECKS)

    math.randomseed(os.time())
    shuffle(cards)

    deal_cards(cards, NUM_PLAYERS)
    -- TODO allow player to swap with visible stack
end

function game_loop()
    local draw_pile = cards
    local pile = {}

    while true do
        -- TODO allow player order to be reversed for Joker
        for _,player in ipairs(players) do
            local end_turn = true
            local card_num = nil

            repeat
                print('*** '..#draw_pile..' card(s) left')
                display_pile(pile)
                display_hand(player.num, player.hand)

                -- If no valid moves, pick up pile and lose turn
                if not has_valid_play(pile, player.hand) then
                    print('*** Player '..player.num..' has no valid moves!')
                    pile, hand = pick_up_pile(pile, player.hand)
                    break
                end

                get_cards(pile, player.hand)
      
                -- Apply appropriate game actions
                active_face = get_active_face(player.hand)
                if active_face == '8' then
                    player.hand = play_cards(pile, player.hand)
                    end_turn = false
                elseif active_face == '10' then
                    player.hand = play_cards(pile, player.hand)
                    pile = {}
                    end_turn = false
                else
                    player.hand = play_cards(pile, player.hand)
                    end_turn = true
                end

                -- Kill pile if 4+ top cards match
                if #pile >= 4 then
                    if pile[1].face == pile[2].face and
                       pile[1].face == pile[3].face and
                       pile[1].face == pile[4].face then
                        pile = kill_pile()
                        end_turn = false
                    end
                end

                -- Draw next card from appropriate pile as necessary
                if #player.hand < 3 then
                    if #draw_pile > 0 then
                        while #player.hand < 3 do
                            local card = get_next_card(draw_pile)
                            if card ~= nil then
                                table.insert(player.hand, card)
                            end
                        end
                    elseif #player.hand == 0 and #player.visible > 0 then
                        -- TODO allow player to select card
                        local card = get_next_card(player.visible)
                        if card ~= nil then
                            table.insert(player.hand, card)
                        end
                        print('*** Drawing from visible cards ('..#player.visible..' left)')
                    elseif #player.hand == 0 and #player.hidden > 0 then
                        -- TODO allow player to select card
                        local card = get_next_card(player.hidden)
                        if card ~= nil then
                            table.insert(player.hand, card)
                        end
                        print('*** Drawing from hidden cards ('..#player.hidden..' left)')
                    end
                end

                -- Test for game over condition
                if #draw_pile == 0 and #player.hand == 0 and
                   #player.visible == 0 and #player.hidden == 0 then
                   print('+++ Player '..player.num..' wins!')
                   return
                end
            until end_turn
        end
    end
end

function display_pile(pile)
    if #pile == 0 then
        print('*** The pile is empty')
        return
    end

    local num = 0
    if #pile < 5 then
        num = #pile
    else
        num = 5
    end
    local t = {}
    for i = 1,num do
        table.insert(t, pile[i].face..pile[i].suit)
    end
    print('*** Pile: '..table.concat(t, ' ')..'\t['..#pile..' card(s) total]')
end

function display_hand(num, hand)
    if #hand == 0 then
        return
    end

    -- TODO display visible cards also?
    print('Player '..num..' hand:')
    table.sort(hand, function(a, b) return a.rank < b.rank end)
    for i,card in ipairs(hand) do
        print('  '..i..': '..card.face..card.suit)
    end
end

function get_cards(pile, hand)
    repeat
        local num = {}
        abort_play(hand)

        repeat
            num = {}
            io.write('Enter card number(s): ')
            local str = io.stdin:read'*l'
            for n in string.gmatch(str, "%d+") do
                table.insert(num, tonumber(n))
            end
        until is_valid_card(hand, num)

        for _,n in ipairs(num) do
            hand[n].play = true
        end
    until is_valid_play(pile, hand)
end

function is_valid_card(hand, num)
    for _,n in ipairs(num) do
        if n < 1 or type(hand[n]) == 'nil' then
            return false
        end
    end

    return true
end

function has_valid_play(pile, hand)
    -- TODO this is going wrong at times where not
    -- all cards are getting checked
    for i,_ in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            abort_play(hand)
            return true
        end
        hand[i].play = false
    end
    abort_play(hand)

    return false
end

function is_valid_play(pile, hand)
    local active_face = get_active_face(hand)

    if active_face == nil then
        return false
    end

    if #pile == 0 then
        return true
    end

    -- TODO if Joker, look deeper into pile
    local base_face = pile[1].face

    -- Cards can always be played onto themselves
    if base_face == active_face then
        return true
    end

    for face,moves in pairs(INVALID_MOVES) do
        if face == base_face then
            for _,move in ipairs(moves) do
                if move == active_face then
                    print('--- Cannot play a '..active_face..' on a '..base_face)
                    return false
                end
            end
        end
    end

    return true
end

function get_active_face(hand)
    local active_face = nil

    for _,card in ipairs(hand) do
        if card.play == true then
            if active_face == nil then
                active_face = card.face
            else
                if active_face ~= card.face then
                    return nil 
                end
            end
        end
    end

    return active_face
end

function pick_up_pile(pile, hand)
    count = 0
    for i,card in ipairs(pile) do
        if card.face ~= '3' then
            table.insert(hand, card)
            count = count + 1
        end
        pile[i] = nil
    end
    print('*** Picked up '..count..' cards')

    return {}, hand
end

function kill_pile()
    print('*** Killed pile')
    return {}
end

function abort_play(hand)
    for _,card in ipairs(hand) do
        card.play = false
    end

    return hand
end

function play_cards(pile, hand)
    local t = {}
    for i,card in ipairs(hand) do
        if card.play == true then
            table.insert(pile, 1, card)
        else
            table.insert(t, card)
        end
    end

    return t
end

function build_decks(num)
    local cards = {}
    for deck = 1,num do
        for _,suit in ipairs(SUITS) do
            for rank,face in ipairs(FACES) do
                local card = {}
                table.insert(cards, card)
                card.suit = suit
                card.face = face
                card.rank = rank + 1
                card.play = false
            end
        end
    end

    return cards
end

function deal_cards(cards, num)
    for i = 1,num do
        local player = {}
        table.insert(players, player)
        player.num = i
        player.hidden = get_num_cards(cards, 3)
        player.visible = get_num_cards(cards, 3)
        player.hand = get_num_cards(cards, 3)
    end
end

-- Implementation of the Knuth shuffle
function shuffle(cards)
    local n = #cards
    while n > 1 do
        local k = math.random(n)
        cards[n], cards[k] = cards[k], cards[n]
        n = n - 1
    end
end

function get_num_cards(cards, num)
    local t = {}
    for i = 1,num do
        local card = table.remove(cards)
        table.insert(t, card)
    end
    return t
end
-- TODO merge these two functions? (i.e. call get_next_card three times?)
function get_next_card(cards)
    if #cards > 0 then
        return table.remove(cards)
    else
        return nil
    end
end

-- main

init_game()
game_loop()

print('')
print('---------')
print('Game Over')
print('---------')
