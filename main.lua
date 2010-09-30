--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

require "ai"

FACES = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SUITS = { 'C', 'D', 'H', 'S' }

SPECIAL_CARDS = { '2', '3', '7', '8', '10', 'R' }
NON_SPECIAL_CARDS = { '4', '5', '6', '9', 'J', 'Q', 'K', 'A' }

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

NUM_PLAYERS = 2
HAND_SIZE = 3

function game_loop()
    local pile = {}
    local turn = 1
    local reverse = player_order()
    local deal_card, num_cards = init_cards(NUM_PLAYERS)
    local next_player = init_players(NUM_PLAYERS, HAND_SIZE, reverse, deal_card)
    local write_log = log_game_state()

    while true do
        local turn_over = end_turn()
        local player = next_player()

        repeat
            print('================')
            print('=== PLAYER '..player.num..' ===')
            print('================')
            print('*** '..num_cards()..' card(s) left to draw')
            display_pile(pile)

            -- If first turn, the card to play has been
            -- set by init_player_num()
            if turn ~= 1 then
                -- If no valid moves, pick up pile and lose turn
                if not has_valid_play(pile, player.hand) then
                    write_log(turn, pile, player)
                    pile, player.hand = pick_up_pile(pile, player.hand)
                    write_log(turn, pile, player)
                    break
                end

                if player.ai == true then
                    ai_play(pile, player.hand)
                else
                    display_hand(player.hand)
                    get_cards(pile, player.hand)
                end
            end
  
            write_log(turn, pile, player)
            pile, player.hand = play_cards(pile, player.hand, turn_over, reverse)

            -- Kill pile if 4+ top cards match
            if get_pile_run(pile) >= 4 then
                pile = kill_pile()
                turn_over(false)
            end

            -- Draw next card from appropriate pile as necessary
            if #player.hand < HAND_SIZE then
                if num_cards() > 0 then
                    while #player.hand < HAND_SIZE and num_cards() > 0 do
                        local card = deal_card()
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
                    -- TODO allow player to select card?
                    local card = get_next_card(player.hidden)
                    if card ~= nil then
                        table.insert(player.hand, card)
                    end
                    print('*** Drawing from hidden cards ('..#player.hidden..' left)')
                end
            end

            write_log(turn, pile, player)

            -- Test for game over condition
            if num_cards() == 0 and #player.hand == 0 and
                #player.visible == 0 and #player.hidden == 0 then
                print('*** Player '..player.num..' wins!')
                return
            end
        until turn_over()

        turn = turn + 1
    end
end

function log_game_state()
    local log = io.open('game.log', 'a+')

    log:write('game\t'..os.date()..' '..NUM_PLAYERS..'\n')

    return function (turn, pile, player)
        log:write('pile\t'..turn..'\t')
        for _,card in ipairs(pile) do
            log:write(card.face..card.suit..' ')
        end
        log:write('\n')

        log:write('player\t'..turn..'\t'..player.num..'\t')
        for _,card in ipairs(player.hand) do
            if card.play == true then
                log:write(card.face..card.suit..'* ')
            else
                log:write(card.face..card.suit..' ')
            end
        end
        log:write('\t')
        for _,card in ipairs(player.visible) do
            log:write(card.face..card.suit..' ')
        end
        log:write('\t')
        for _,card in ipairs(player.hidden) do
            log:write(card.face..card.suit..' ')
        end
        log:write('\n')

        log:flush()
    end
end

function player_order(b)
    local reverse = false

    return function(b)
        if b == true then
            reverse = not reverse
            print('*** Direction reversed!')
        end
        return reverse
    end
end

function end_turn(b)
    local turn_over = true

    return function(b)
        if b ~= nil then turn_over = b end
        return turn_over
    end
end

function display_pile(pile)
    if #pile == 0 then
        print('*** The pile is empty')
        return
    end

    io.write('*** Pile: ')
    for i,card in ipairs(pile) do
        if i > 5 then break end
        io.write(card.face..card.suit..' ')
    end
    print('\t['..#pile..' card(s) total]')
end

function get_pile_top(pile)
    for _,card in ipairs(pile) do
        if card.face ~= 'R' then
            return card.face
        end
    end

    return nil
end

function get_pile_run(pile)
    local top_face = get_pile_top(pile)
    local run = 0

    if top_face == nil then return 0 end

    for _,card in ipairs(pile) do
        if card.face ~= 'R' then
            if top_face == card.face then
                run = run + 1
            else
                break
            end
        end
    end

    return run
end

function display_hand(hand)
    if #hand == 0 then return end

    -- TODO display visible cards also?
    print('Current hand:')
    table.sort(hand, function(a, b) return a.rank < b.rank end)
    for i,card in ipairs(hand) do
        print('  '..i..': '..card.face..card.suit)
    end
end

function get_cards(pile, hand)
    while true do
        local num = {}

        clear_play(hand)

        while true do
            num = {}
            io.write('Enter card number(s): ')
            local str = io.stdin:read'*l'
            for n in string.gmatch(str, "%d+") do
                table.insert(num, tonumber(n))
            end
        
            if is_valid_cards(hand, num) then
                break
            else
                print('!!! Invalid card number')
            end
        end

        for _,n in ipairs(num) do
            hand[n].play = true
        end
    
        if is_valid_play(pile, hand) then
            return
        else
            print('!!! Invalid play')
        end
    end
end

function is_valid_cards(hand, num)
    for _,n in ipairs(num) do
        if hand[n] == nil then
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
    local top_face = get_pile_top(pile)

    if active_face == nil then return false end
    if top_face == nil then return true end
    if top_face == active_face then return true end

    if INVALID_MOVES[top_face] ~= nil then
        for _,move in ipairs(INVALID_MOVES[top_face]) do
            if move == active_face then
                return false
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
    local count = 0

    for _,card in ipairs(pile) do
        if card.face ~= '3' then
            table.insert(hand, card)
            count = count + 1
        end
    end
    print('*** No valid moves, picked up '..count..' cards')

    return {}, hand
end

function kill_pile()
    print('*** Killed pile')
    -- TODO store discard pile?
    return {}
end

function clear_play(cards)
    for _,card in ipairs(cards) do
        card.play = false
    end
end

function play_cards(pile, hand, turn_over, reverse)
    local h = {}
    local active_face = get_active_face(hand)

    for _,card in ipairs(hand) do
        if card.play == true then
            print('+++ Played a '..card.face)
            table.insert(pile, 1, card)
        else
            table.insert(h, card)
        end
    end

    clear_play(pile)

    if active_face == '8' then
        turn_over(false)
    elseif active_face == '10' then
        pile = kill_pile()
        turn_over(false)
    elseif active_face == 'R' then
        reverse(true)
        turn_over(true)
    else
        turn_over(true)
    end

    return pile, h
end

function init_cards(num_players)
    local cards = {}
    local num_decks = math.ceil(num_players / 2)

    for deck = 1,num_decks do
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

        if num_players > 2 then
            -- Add two Jokers to each deck
            for i=1,2 do
                local card = {}
                table.insert(cards, card)
                card.suit = ''
                card.face = 'R'
                card.rank = #FACES + 2
                card.play = false
            end
        end
    end

    math.randomseed(os.time())
    shuffle(cards)

    return function()
        return get_next_card(cards)
    end, function()
        return #cards
    end
end

function get_next_card(cards)
    if #cards > 0 then
        return table.remove(cards)
    else
        return nil
    end
end

function init_players(num_players, num_cards, reverse, deal_card)
    local players = {}
    local curr_player = 0

    for i = 1,num_players do
        local player = {}
        table.insert(players, player)
        player.num = i
        player.hidden = {}
        player.visible = {}
        player.hand = {}

        for i = 1,num_cards do
            table.insert(player.hidden, deal_card())
            table.insert(player.visible, deal_card())
            table.insert(player.hand, deal_card())
        end

        if i == 1 then
            player.ai = false
        else
            player.ai = true
        end
    
        -- TODO allow human players to swap with visible stack
        if player.ai == true then
            player.visible, player.hand = ai_swap_cards(player.visible, player.hand, num_cards)
        end
    end

    return function()
        if curr_player == 0 then
            curr_player = init_player_num(players)
        else
            curr_player = next_player_num(#players, curr_player, reverse)
        end

        return players[curr_player]
    end
end

function init_player_num(players)
    -- Pick starting player by matching the first instance of
    -- a non-special face with a card in a player's hand and
    -- marking that card for play
    for _,face in ipairs(NON_SPECIAL_CARDS) do
        for _,player in ipairs(players) do
            for _,card in ipairs(player.hand) do
                if face == card.face then
                    card.play = true
                    return player.num
                end
            end
        end
    end

    -- Tiebreaker: if a matching non-special card isn't found,
    -- look at special cards also
    for _,face in ipairs(SPECIAL_CARDS) do
        for _,player in ipairs(players) do
            for _,card in ipairs(player.hand) do
                if face == card.face then
                    card.play = true
                    return player.num
                end
            end
        end
    end

    return 1
end

function next_player_num(num_players, curr_player, reverse)
    if not reverse() then
        num = curr_player + 1
    else
        num = curr_player - 1
    end

    if num > num_players then num = 1 end
    if num < 1 then num = num_players end

    return num
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

function slice(list, start, len)
    local t = {}
    local len = len or (#list - start + 1)
    local stop = start + len - 1
  
    for i = start,stop do
        table.insert(t, list[i])
    end
  
    return t
end

-- main

print('   ____  _                      _             ')
print('  / __ \\| |                    (_)            ')
print(' | |  | | |__  ___  ___ ___ ___ _  ___  _ __  ')
print(' | |  | | \'_ \\/ __|/ _ | __/ __| |/ _ \\| \'_ \\ ')
print(' | |__| | |_) \\__ \\  __|__ \\__ \\ | (_) | | | |')
print('  \\____/|_.__/|___/\\___|___/___/_|\\___/|_| |_|')
print('')
print('@@@ Starting a new game with '..NUM_PLAYERS..' players')

game_loop()

print('=================')
print('=== Game Over ===')
print('=================')
