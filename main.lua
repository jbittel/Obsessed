
require "ai"

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

NUM_DECKS = 2
NUM_PLAYERS = 4
HAND_SIZE = 3

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
    local reverse = false
    -- TODO choose player start, low to high beginning with 4
    local player = players[1]

    while true do
        local end_turn = true

        repeat
            print('*** '..#draw_pile..' card(s) left')
            display_pile(pile)

            -- If no valid moves, pick up pile and lose turn
            if not has_valid_play(pile, player.hand) then
                print('*** Player '..player.num..' has no valid moves!')
                pile, hand = pick_up_pile(pile, player.hand)
                break
            end

            if player.ai == true then
                play_ai(pile, player.hand)
            else
                display_hand(player.num, player.hand)
                get_cards(pile, player.hand)
            end
  
            -- Apply appropriate game actions
            active_face = get_active_face(player.hand)
            player.hand = play_cards(pile, player.hand)
            print('+++ Player '..player.num..' played a '..active_face)
            if active_face == '8' then
                end_turn = false
            elseif active_face == '10' then
                pile = kill_pile()
                end_turn = false
            elseif active_face == 'R' then
                reverse = not reverse
                end_turn = true
            else
                end_turn = true
            end

            -- Kill pile if 4+ top cards match
            -- TODO should four 3s kill the pile?
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
                    while #player.hand < 3 and #draw_pile > 0 do
                        local card = draw_next_card(draw_pile)
                        if card ~= nil then
                            table.insert(player.hand, card)
                        end
                    end
                elseif #player.hand == 0 and #player.visible > 0 then
                    -- TODO allow player to select card
                    local card = draw_next_card(player.visible)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                    print('*** Drawing from visible cards ('..#player.visible..' left)')
                elseif #player.hand == 0 and #player.hidden > 0 then
                    -- TODO allow player to select card?
                    local card = draw_next_card(player.hidden)
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

        player = players[next_player(player.num, reverse)]
    end
end

function next_player(num, reverse)
    local i = num

    if not reverse then
        i = i + 1
    else
        i = i - 1
    end

    if i > #players then i = 1 end
    if i < 1 then i = #players end

    return i
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
    if #hand == 0 then return end

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
        clear_play(hand)

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
    for i,_ in ipairs(hand) do
        hand[i].play = true
        if is_valid_play(pile, hand) then
            hand[i].play = false
            return true
        end
        hand[i].play = false
    end

    return false
end

function is_valid_play(pile, hand)
    local active_face = get_active_face(hand)
    local base_face = nil

    if active_face == nil then return false end
    if #pile == 0 then return true end

    -- If Joker, look deeper into pile
    local i = 1
    while pile[i].face == 'R' and i < #pile do
        i = i + 1
    end
    base_face = pile[i].face

    -- Cards can always be played onto themselves
    if base_face == active_face then
        return true
    end

    for face,moves in pairs(INVALID_MOVES) do
        if face == base_face then
            for _,move in ipairs(moves) do
                if move == active_face then
--                    print('--- Cannot play a '..active_face..' on a '..base_face)
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
    for _,card in ipairs(pile) do
        if card.face ~= '3' then
            table.insert(hand, card)
            count = count + 1
        end
    end
    print('*** Picked up '..count..' cards')

    return {}, hand
end

function kill_pile()
    print('*** Killed pile')
    return {}
end

function clear_play(cards)
    for _,card in ipairs(cards) do
        card.play = false
    end
end

function play_cards(pile, hand)
    local t = {}
    for _,card in ipairs(hand) do
        if card.play == true then
            table.insert(pile, 1, card)
        else
            table.insert(t, card)
        end
    end
    clear_play(pile)

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

        -- Add two Jokers to each deck
        if NUM_PLAYERS > 2 then
            for i=1,2 do
                local card = {}
                table.insert(cards, card)
                card.suit = ''
                card.face = 'R'
                card.rank = #FACES + 1
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
        player.hidden = {}
        player.visible = {}
        player.hand = {}

        for i = 1,HAND_SIZE do
            table.insert(player.hidden, draw_next_card(cards))
            table.insert(player.visible, draw_next_card(cards))
            table.insert(player.hand, draw_next_card(cards))
        end

        if i == 1 then
            player.ai = false
        else
            player.ai = true
        end
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

function draw_next_card(cards)
    if #cards > 0 then
        return table.remove(cards)
    else
        return nil
    end
end

-- main

init_game()
game_loop()

print('---------')
print('Game Over')
print('---------')
