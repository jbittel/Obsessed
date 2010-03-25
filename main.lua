
-- TODO add Joker as a playable card
FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

NUM_DECKS = 2
NUM_PLAYERS = 2

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
                print('Discard pile: ')
                display_cards(discard, 5)
                print('Player '..player.num..' hand: ')
                display_cards(player.hand)

                -- TODO if no valid moves, pick up discard pile and lose turn

                repeat
                    repeat
                        io.write('Enter card number(s): ')
                        card_num = io.stdin:read'*n'
                    until is_valid_card(player.hand, card_num)
                    -- TODO allow multiple cards to be played
                    -- TODO pass all cards to be played to this function
                until is_valid_action(discard, player.hand, card_num)
      
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

                if #discard > 4 then
                    --  TODO kill pile if top four are identical
                    --turn_over = false
                end

                -- Draw next card from appropriate pile as necessary
                if #draw_pile > 0 and #player.hand < 3 then
                    -- TODO draw multiple cards to fill hand
                    local card = get_next_card(draw_pile)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                elseif #draw_pile == 0 and #player.hand == 0 then
                    -- TODO allow player to select card
                    local card = get_next_card(player.visible)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                elseif #draw_pile == 0 and #player.hand == 0 and
                       #player.visible == 0 then
                    -- TODO allow player to select card
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

-- TODO split out display_hand() that:
--  * displays index numbers
--  * displays cards in rank order
--  * displays visible cards
function display_cards(cards, num)
    if #cards == 0 then
        return
    end

    if num == nil or num > #cards then
        num = #cards
    end

    for i = 1,num do
        local face = cards[i].face
        local suit = cards[i].suit
        io.write('('..i..') '..face..suit..' ')
    end
    print('')
end

function is_valid_card(hand, card_num)
    return hand[card_num]
end

function is_valid_action(discard, hand, card_num)
    local active_face = hand[card_num].face
    local invalid_moves = {}
 
    if #discard == 0 then
        return true
    end
 
    -- TODO multiple cards: ensure consistency and treat them as a stack
    -- TODO in some cases, look deeper into discard pile

    local base_face = discard[#discard].face

    -- Cards can always be played onto themselves
    if base_face == active_face then
        return true
    end

    invalid_moves['3'] = { '2', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
    invalid_moves['5'] = { '4' }
    invalid_moves['6'] = { '4', '5' }
    invalid_moves['7'] = { '8', '9', 'J', 'Q', 'K', 'A' }
    invalid_moves['9'] = { '4', '5', '6' }
    invalid_moves['J'] = { '4', '5', '6', '9' }
    invalid_moves['Q'] = { '4', '5', '6', '9', 'J' }
    invalid_moves['K'] = { '4', '5', '6', '9', 'J', 'Q' }
    invalid_moves['A'] = { '4', '5', '6', '9', 'J', 'Q', 'K' }

    for face,moves in pairs(invalid_moves) do
        if face == base_face then
            for _,move in ipairs(moves) do
                if move == active_face then
                    print('You cannot play a '..active_face..' onto a '..base_face)
                    return false
                end
            end
        end
    end

    return true
end

function discard_card(discard, hand, card_num)
    -- TODO push discarded cards onto top of stack
    local card = table.remove(hand, card_num)
    table.insert(discard, card)
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

function get_next_card(cards)
    if #cards > 0 then
        return table.remove(cards)
    else
        return nil
    end
end

function table.find(f, l)
    for _,v in ipairs(l) do
        if f(v) then
            return v
        end
    end
    return nil
end

-- main

init_game()
game_loop()
