--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2011 Jason Bittel <jason.bittel@gmail.com>

--]]

Game = class('Game')

NUM_PLAYERS = 4
HAND_SIZE = 3
VISIBLE_SIZE = 3
HIDDEN_SIZE = 3

KILL_RUN_LEN = 4
if NUM_PLAYERS == 2 then
    KILL_RUN_LEN = 3
end

function Game:initialize()
    require 'cards'
    require 'players'
    require 'ai'

    print('   ____  _                      _             ')
    print('  / __ \\| |                    (_)            ')
    print(' | |  | | |__  ___  ___ ___ ___ _  ___  _ __  ')
    print(' | |  | | \'_ \\/ __|/ _ | __/ __| |/ _ \\| \'_ \\ ')
    print(' | |__| | |_) \\__ \\  __|__ \\__ \\ | (_) | | | |')
    print('  \\____/|_.__/|___/\\___|___/___/_|\\___/|_| |_|')
    print('')
    print('@@@ Starting a new game with '..NUM_PLAYERS..' players')

    draw_pile = DrawPile:new('Draw')
    discard_pile = DiscardPile:new('Discard')
    player_list = PlayerList:new()
end

function Game:update()
    local turn = 1

    self:draw()

--    while true do
        local player = player_list:advance_next_player()
        print('\n=== '..string.upper(tostring(player)))

--        repeat
            if turn == 1 then
                player:play_initial_card()
            elseif player:get_num_hand_cards() == 0 and player:get_num_visible_cards() > 0 then
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

            -- Test for win conditions
            if draw_pile:get_num_cards() == 0 and player:get_num_cards() == 0 then
                print('*** '..tostring(player)..' wins!')
                player_list:add_winner()
                -- Test for game over condition
                if player_list:get_num_players() == 1 then
                    player_list:add_winner(player_list:next_player_num())
                    return
                end
            end
--        until player_list:is_turn_over()

        turn = turn + 1
--    end
end

function Game:draw()
    love.graphics.print('Obsessed', 100, 100)
    -- Display game board
--    draw_pile:display_cards(0)
--    discard_pile:display_cards(5)
--    player:display_hand()
--    player.visible:display_cards()
--    player.hidden:display_cards(0)
end

function Game:keypressed(key, unicode)
    if key == 'q' or key == 'escape' then
        love.event.push('q')
    end
end

--[[
function love.quit()
    print('')
    print('=================')
    player_list:display_winners()
    print('=================')
    print('=== Game Over ===')
    print('=================')
end
--]]
function log_game_state()
    local log = io.open('game.log', 'a+')

    log:write('0\tgame\t'..os.date()..' '..NUM_PLAYERS..'\n')

    return function (turn, player)
        log:write(turn..'\tdiscard\t')
        for _,card in ipairs(discard_pile.cards) do log:write(tostring(card)..' ') end
        log:write('\n')

        log:write(turn..'\tplayer\t'..player.num..'\t')
        for _,card in ipairs(player.hand.cards) do log:write(tostring(card)..' ') end
        log:write('\t')
        for _,card in ipairs(player.visible.cards) do log:write(tostring(card)..' ') end
        log:write('\t')
        for _,card in ipairs(player.hidden.cards) do log:write(tostring(card)..' ') end
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

--game_init()
--game_loop()
--game_end()
