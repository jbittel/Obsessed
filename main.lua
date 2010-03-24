

FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

NUM_DECKS = 2
NUM_PLAYERS = 2

players = {}
cards = {}
draw_pile = {}
discard_pile = {}

function init_game()
    local cards = {}
    
    cards = build_decks(NUM_DECKS)

    math.randomseed(os.time())
    shuffle(cards)

    deal_cards(cards, NUM_PLAYERS)

    draw_pile = cards
end

function game_loop()
    local game_over = false
    local card_num = nil

    while not game_over do
        for _,player in ipairs(players) do
            print('Discard pile: ')
            display_cards(discard_pile, 5)
            print('Player '..player.num..' hand: ')
            display_cards(player.hand)

            -- TODO repeat until turn done
            repeat
                io.write('Enter card: ')
                card_num = io.stdin:read'*n'
            until is_valid_card(player.hand, card_num)
            -- TODO validate against game rules
            -- TODO no valid moves, pick up discard

            -- Discard selected card
            local card = table.remove(player.hand, card_num)
            table.insert(discard_pile, card)

            -- TODO kill discard pile if necessary

            -- Draw next card from appropriate pile as necessary
            if #draw_pile > 0 and #player.hand < 3 then
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
        end
    end
end

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
