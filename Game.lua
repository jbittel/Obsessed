--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

require 'MiddleClass'
require 'Cards'
require 'Players'
require 'Ai'

NUM_PLAYERS = 4
HAND_SIZE = 3
VISIBLE_SIZE = 3
HIDDEN_SIZE = 3

KILL_RUN_LEN = 4
if NUM_PLAYERS == 2 then
    KILL_RUN_LEN = 3
end

draw_pile = nil
discard_pile = nil

function game_init()
    print('   ____  _                      _             ')
    print('  / __ \\| |                    (_)            ')
    print(' | |  | | |__  ___  ___ ___ ___ _  ___  _ __  ')
    print(' | |  | | \'_ \\/ __|/ _ | __/ __| |/ _ \\| \'_ \\ ')
    print(' | |__| | |_) \\__ \\  __|__ \\__ \\ | (_) | | | |')
    print('  \\____/|_.__/|___/\\___|___/___/_|\\___/|_| |_|')
    print('')
    print('@@@ Starting a new game with '..NUM_PLAYERS..' players')

    draw_pile = DrawPile:new()
    discard_pile = DiscardPile:new()
end

function game_loop()
    local player_list = PlayerList:new()

    local turn = 1
    local write_log = log_game_state()

    while true do
        local player = player_list:get_next_player()

        repeat
            if turn ~= 1 then
                -- Display game board
                draw_pile:display_cards('Draw', 0)
                discard_pile:display_cards('Discard', 5)
                player:display_hand()
                player.visible:display_cards('Visible')
                player.hidden:display_cards('Hidden', 0)

                write_log(turn, player)

                if player:get_num_hand_cards() == 0 and player:get_num_visible_cards() > 0 then
                    -- Play cards from visible set
                    if player.visible:has_valid_play() then
                        player:play_from_visible()
                    else
                        discard_pile:pick_up_pile(player)
                        break
                    end
                elseif player:get_num_hand_cards() == 0 and player:get_num_hidden_cards() > 0 then
                    -- Play cards from hidden set
                    player:play_from_hidden()
                    -- If the hand isn't empty, the drawn card couldn't be played
                    if player:get_num_hand_cards() ~= 0 then
                        discard_pile:pick_up_pile(player)
                        break
                    end
                else
                    -- Play cards from hand
                    if player.hand:has_valid_play() then
                        player:play_from_hand()
                    else
                        discard_pile:pick_up_pile(player)
                        break
                    end
                end
            else
                write_log(turn, player)
            end
            
            -- Test for game over condition
            if draw_pile:get_num_cards() == 0 and player:get_num_cards() == 0 then
                print('*** Player '..player.num..' wins!')
                return
            end

            -- Apply card face rules
            local top_face = discard_pile:get_top_face()
            if top_face == '8' then
                player_list:end_turn(false)
            elseif top_face == '10' then
                pile = discard_pile:kill_pile()
                player_list:end_turn(false)
            elseif top_face == 'R' then
                player_list:reverse_order()
                player_list:end_turn(true)
            else
                player_list:end_turn(true)
            end

            -- Kill pile if 4+ top cards match
            if discard_pile:get_run_length() >= KILL_RUN_LEN then
                discard_pile:kill_pile()
                player_list:end_turn(false)
            end

            -- Keep player's hand at a minimum of HAND_SIZE cards
            while player:get_num_hand_cards() < HAND_SIZE and draw_pile:get_num_cards() > 0 do
                player:add_to_hand(draw_pile)
            end
        until player_list:is_turn_over()

        turn = turn + 1
    end
end

function game_end()
    print('')
    print('=================')
    print('=== Game Over ===')
    print('=================')
end

function log_game_state()
    local log = io.open('game.log', 'a+')

    log:write('0\tgame\t'..os.date()..' '..NUM_PLAYERS..'\n')

    return function (turn, player)
        log:write(turn..'\tdiscard\t')
        for _,card in ipairs(discard_pile.cards) do log:write(card.face..card.suit..' ') end
        log:write('\n')

        log:write(turn..'\tplayer\t'..player.num..'\t')
        for _,card in ipairs(player.hand.cards) do log:write(card.face..card.suit..' ') end
        log:write('\t')
        for _,card in ipairs(player.visible.cards) do log:write(card.face..card.suit..' ') end
        log:write('\t')
        for _,card in ipairs(player.hidden.cards) do log:write(card.face..card.suit..' ') end
        log:write('\n')

        log:flush()
    end
end

function table.slice(list, start, len)
    local s = {}
    local len = len or (#list - start + 1)
    local stop = start + len - 1
    for i = start,stop do table.insert(s, list[i]) end
    return s
end

function table.set(list)
    local s = {}
    for _,v in ipairs(list) do s[v] = true end
    return s
end

function table.copy(t)
    local t2 = {}
    for k,v in pairs(t) do t2[k] = v end
    return t2
end

-- main

game_init()
game_loop()
game_end()
