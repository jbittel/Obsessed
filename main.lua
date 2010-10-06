--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2010 Jason Bittel <jason.bittel@gmail.com>

--]]

require 'MiddleClass'
require 'cards'
require 'players'
require 'ai'

NUM_PLAYERS = 4
HAND_SIZE = 3

function game_loop()
    local draw_pile = DrawPile:new()
    local discard_pile = DiscardPile:new()
    local player_list = PlayerList:new(draw_pile)

    local turn = 1
--    local write_log = log_game_state()

    while true do
        local player = player_list:get_next_player()

        print('================')
        print('=== PLAYER '..player.num..' ===')
        print('================')

        repeat
            print('*** '..draw_pile:get_num_cards()..' cards left')
            discard_pile:display_cards(5)

            -- If first turn, the card to play has been
            -- set by init_player_num()
--            if turn ~= 1 then
                -- If no valid moves, pick up pile and lose turn
                if not player.hand:has_valid_play(discard_pile) then
--                    write_log(turn, pile, player)
                    discard_pile:pick_up_pile(player)
--                    write_log(turn, pile, player)
                    break
                end

                player:execute_turn(discard_pile)
--            end
  
--            write_log(turn, pile, player)
            play_cards(discard_pile, player)

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

            -- Draw next card from appropriate pile as necessary
            if #player.hand.cards < HAND_SIZE then
                if draw_pile:get_num_cards() > 0 then
                    while #player.hand.cards < HAND_SIZE and draw_pile:get_num_cards() > 0 do
                        local card = draw_pile:draw_card()
                        if card ~= nil then
                            table.insert(player.hand.cards, card)
                        end
                    end
                elseif #player.hand.cards == 0 and #player.visible.cards > 0 then
                    -- TODO allow player to select card
                    local card = player.visible:get_next_card()
                    if card ~= nil then
                        table.insert(player.hand.cards, card)
                    end
                    print('*** Drawing from visible cards ('..#player.visible.cards..' left)')
                elseif #player.hand.cards == 0 and #player.hidden.cards > 0 then
                    -- TODO allow player to select card?
                    local card = player.hidden:get_next_card()
                    if card ~= nil then
                        table.insert(player.hand.cards, card)
                    end
                    print('*** Drawing from hidden cards ('..#player.hidden.cards..' left)')
                end
            end

--            write_log(turn, pile, player)

            -- Test for game over condition
            if draw_pile:get_num_cards() == 0 and player:get_num_cards() == 0 then
                print('*** Player '..player.num..' wins!')
                return
            end
        until player_list:is_turn_over()

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

function play_cards(discard_pile, player)
    local h = {}

    -- TODO move this logic into the individual play(execute?)_card functions
    for _,card in ipairs(player.hand.cards) do
        if card.play == true then
            print('+++ Played a '..card.face)
            table.insert(discard_pile.cards, 1, card)
        else
            table.insert(h, card)
        end
    end

    player.hand.cards = h
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
