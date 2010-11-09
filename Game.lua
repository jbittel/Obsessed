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
--    local write_log = log_game_state()

    while true do
        local player = player_list:get_next_player()

        print('')
        print('=== PLAYER '..player.num)

        repeat
            -- Display game board
            draw_pile:display_cards('Draw Pile', 0)
            discard_pile:display_cards('Discard', 5)
            player.visible:display_cards('Visible')
            player.hidden:display_cards('Hidden', 0)

            -- Draw cards from visible/hidden piles if necessary
            if player:get_num_hand_cards() == 0 and player:get_num_visible_cards() > 0 then
                if player.visible:has_valid_play() then
                    player:draw_visible_card()
                    print('*** Drawing from visible cards ('..player:get_num_visible_cards()..' left)')
                else
                    discard_pile:pick_up_pile(player)
                    break
                end
            elseif player:get_num_hand_cards() == 0 and player:get_num_hidden_cards() > 0 then
                player:draw_hidden_card()
                print('*** Drawing from hidden cards ('..player:get_num_hidden_cards()..' left)')
            end

            player:display_hand()

            -- TODO force starting player to play card
            -- If no valid moves, pick up pile and lose turn
            if not player.hand:has_valid_play() then
                discard_pile:pick_up_pile(player)
                break
            end

            player:execute_turn()
  
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
            if discard_pile:get_run_length() >= 4 then
                discard_pile:kill_pile()
                player_list:end_turn(false)
            end

            -- Keep player's hand at a minimum of 3 cards
            while player:get_num_hand_cards() < HAND_SIZE and draw_pile:get_num_cards() > 0 do
                player:draw_card(draw_pile)
            end

            -- Test for game over condition
            if draw_pile:get_num_cards() == 0 and player:get_num_cards() == 0 then
                print('*** Player '..player.num..' wins!')
                return
            end
        until player_list:is_turn_over()

        turn = turn + 1
    end
end

function game_end()
    print('=================')
    print('=== Game Over ===')
    print('=================')
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

-- main

game_init()
game_loop()
game_end()
