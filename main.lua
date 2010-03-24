
cards = {}
players = {}

FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

NUM_DECKS = 3
NUM_PLAYERS = 5

function init_game()
    build_decks(NUM_DECKS)

    math.randomseed(os.time())
    shuffle(cards)

    deal_cards(NUM_PLAYERS)
end

function build_decks(num)
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
end

function deal_cards(num)
    for i = 1,num do
        local player = {}
        table.insert(players, player)
        player.num = i
        player.hidden = get_cards(cards, 3)
        player.visible = get_cards(cards, 3)
        player.hand = get_cards(cards, 3)
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

function get_cards(cards, num)
    local t = {}
    for i = 1,num do
        local card = table.remove(cards)
        table.insert(t, card)
    end

    return t
end

function get_next_card(cards)
    return table.remove(cards)
end

init_game()

for _,player in ipairs(players) do
    io.write('['..player.num..'] ')
    for _,card in ipairs(player.hand) do
        io.write(card.face..card.suit..' ')
    end
    print('')
end
