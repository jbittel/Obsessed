
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
NUM_PLAYERS = 5

players = {}
cards = {}

function init_game()
    cards = build_decks(NUM_DECKS)

    math.randomseed(os.time())
    shuffle(cards)

    deal_cards(cards, NUM_PLAYERS)
end

function game_loop()
    local game_over = false
    local draw_pile = cards
    local discard = {}

    while not game_over do
        for _,player in ipairs(players) do
            local turn_over = true
            local card_num = nil

            repeat
                print('*** '..#draw_pile..' card(s) left in draw pile')
                display_pile(discard)
                display_hand(player.num, player.hand)

                -- If no valid moves, pick up pile and lose turn
                if not has_valid_action(discard, player.hand) then
                    print('*** No valid moves available')
                    -- TODO this count is wrong because of 3 cards being removed
                    print('*** Player '..player.num..' picked up '..#discard..' cards')
                    pick_up_pile(discard, player.hand)
                    break
                end

                play = get_cards(discard, player.hand)
      
                -- Apply appropriate game actions
                active_face = player.hand[card_num].face
                if active_face == '8' then
                    discard_card(discard, player.hand, card_num)
                    turn_over = false
                elseif active_face == '10' then
                    discard_card(discard, player.hand, card_num)
                    discard = {}
                    turn_over = false
                else
                    discard_card(discard, player.hand, card_num)
                    turn_over = true
                end

                -- Kill discard pile if 4+ top cards match
                if #discard > 4 then
                    if discard[1].face == discard[2].face and
                       discard[1].face == discard[3].face and
                       discard[1].face == discard[4].face then
                        discard = {}
                        turn_over = false
                    end
                end

                -- Draw next card from appropriate pile as necessary
                if #draw_pile > 0 and #player.hand < 3 then
                    while #player.hand < 3 do
                        local card = get_next_card(draw_pile)
                        if card ~= nil then
                            table.insert(player.hand, card)
                        end
                    end
                elseif #draw_pile == 0 and #player.hand == 0 then
                    -- TODO allow player to select card
                    print('*** Draw pile empty, using visible cards')
                    local card = get_next_card(player.visible)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                elseif #draw_pile == 0 and #player.hand == 0 and
                       #player.visible == 0 then
                    -- TODO allow player to select card
                    print('*** Draw pile and visible cards empty, using hidden cards')
                    local card = get_next_card(player.hidden)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                elseif #draw_pile == 0 and #player.hand == 0 and
                       #player.visible == 0 and #player.hidden == 0 then
                    game_over = true
                end
            until turn_over
        end
    end
end

function display_pile(pile)
    if #pile == 0 then
        print('*** The discard pile is empty')
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
    print('*** Discard pile: '..table.concat(t, ' ')..'\t['..#pile..' card(s) total]')
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
    local num = {}
    -- TODO allow multiple cards to be played

    repeat
        repeat
            io.write('Enter card number(s): ')
            local str = io.stdin:read'*l'
            for n in string.gmatch(str, "%d+") do
                num[#num + 1] = n
            end
        until is_valid_card(hand, num)
        print('got valid card')
        -- TODO tell the user what/if invalid action was encountered
        -- TODO build play list of cards?
    until is_valid_action(pile, hand, num)
end

function is_valid_card(hand, num)
    -- TODO fix this mess
    if type(num) == 'table' then
        for _, n in ipairs(num) do
            local i = tonumber(n)
            if i < 1 or type(hand[i]) == 'nil' then
                return false
            end
        end
    elseif type(num) == 'number' then
        if num < 1 or type(hand[num]) == 'nil' then
            return false
        end
    else
        return false
    end

    return true
end

function has_valid_action(discard, hand)
    for i,card in ipairs(hand) do
        if is_valid_action(discard, hand, i) then
            return true
        end
    end

    return false
end

function is_valid_action(discard, hand, card_num)
    local active_face = hand[card_num].face

    -- TODO test for table or single list
    -- TODO if multiple cards: ensure same face and treat as one

    if #discard == 0 then
        return true
    end
 
    -- TODO in some cases, look deeper into discard pile
    --  what cases? Joker
    local base_face = discard[1].face

    -- Cards can always be played onto themselves
    if base_face == active_face then
        return true
    end

    for face,moves in pairs(INVALID_MOVES) do
        if face == base_face then
            for _,move in ipairs(moves) do
                if move == active_face then
                    return false
                end
            end
        end
    end

    return true
end

function pick_up_pile(pile, hand)
    for i,card in ipairs(pile) do
        if card.face ~= '3' then
            table.insert(hand, card)
        end
        pile[i] = nil
    end
end

function discard_card(discard, hand, card_num)
    -- TODO test for table or single list
    local card = table.remove(hand, card_num)
    table.insert(discard, 1, card)
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
                card.rank  = rank + 1
                card.deck = deck
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
