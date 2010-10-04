--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

require "cards"
require "players"
require "ai"

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

NUM_PLAYERS = 4
HAND_SIZE = 3

function game_loop()
    local draw_pile = DrawPile:new()
    local discard_pile = DiscardPile:new()

    local player_list = PlayerList:new()

    local turn = 1
--    local write_log = log_game_state()

    draw_pile:init_cards()
    player_list:init_players(draw_pile)

    while true do
        local turn_over = end_turn()
        local player = player_list:get_next_player()

        repeat
            print('================')
            print('=== PLAYER '..player.num..' ===')
            print('================')
            print('*** '..draw_pile:get_num_cards()..' card(s) left to draw')
            discard_pile:display_cards(5)

            -- If first turn, the card to play has been
            -- set by init_player_num()
            if turn ~= 1 then
                -- If no valid moves, pick up pile and lose turn
                if not player:has_valid_play(discard_pile) then
--                    write_log(turn, pile, player)
                    discard_pile:pick_up_pile(player)
--                    write_log(turn, pile, player)
                    break
                end

                player:play_turn()
            end
  
--            write_log(turn, pile, player)
            -- TODO make this into a generic execute_turn() function
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
                        local card = draw_pile:deal_card()
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

--            write_log(turn, pile, player)

            -- Test for game over condition
            if draw_pile:get_num_cards() == 0 and player:get_num_cards() == 0 then
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

function end_turn(b)
    local turn_over = true

    return function(b)
        if b ~= nil then turn_over = b end
        return turn_over
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
