
cards = {}

FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }
NUMDECKS = 2

function build_decks(num)
    for deck = 1,num do
        for _,suit in ipairs(SUITS) do
            for rank,face in ipairs(FACES) do
                local card = {}
                table.insert(cards,card)
                card.suit = suit
                card.face = face
                card.rank  = rank + 1
                card.deck = deck
            end
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

build_decks(NUMDECKS)

math.randomseed(os.time())
shuffle(cards)

for _,card in ipairs(cards) do
    print(card.face..card.suit..' ['..card.rank..']')
end

print('Total cards: '..#cards)
