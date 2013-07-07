--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = class('Player')

function Player:initialize(num)
    self.num = num
    self.hand = PlayerHand:new('Hand')
    self.visible = PlayerVisible:new('Visible')
    self.hidden = PlayerHidden:new('Hidden')
--  TODO self:swapCards()
end

function Player:__tostring()
    return 'P'..tostring(self.num)
end

function Player:isAi()
    if self.class.name == 'AIPlayer' then
        return true
    else
        return false
    end
end

function Player:getNumCards()
    return self.hand:getNumCards() + self.visible:getNumCards() + self.hidden:getNumCards()
end

function Player:getNumHandCards()
    return self.hand:getNumCards()
end

function Player:getNumVisibleCards()
    return self.visible:getNumCards()
end

function Player:getNumHiddenCards()
    return self.hidden:getNumCards()
end

function Player:addToHand(cards, num)
    local card = cards:removeCard(num)
    if card ~= nil then self.hand:addCard(card) end
end

function Player:addToHandFromHidden(num)
    local card = self.hidden:removeCard(num)
    if card ~= nil then
        card:setSelected()
        self.hand:addCard(card)
    end
end

function Player:pickUpPile()
    local count = 0
    for _, card in ipairs(discard_pile:getCards()) do
        if card.face ~= '3' then
            self.hand:addCard(card)
            count = count + 1
        end
    end
    discard_pile:removeCards()
    logger('picked up '..count..' cards')
end

function Player:selectInitialCard()
    local initial_face = nil
    for _,face in ipairs(Card.START_ORDER) do
        if self.hand:hasCard(face) then
            initial_face = face
            break
        end
    end
    for _, card in ipairs(self.hand.cards) do
        if initial_face == card.face then
            card:setSelected()
        end
    end
end

function Player:getActivePile()
    local active_pile = nil

    if self:getNumHandCards() > 0 then
        active_pile = self.hand
    elseif self:getNumVisibleCards() > 0 then
        active_pile = self.visible
    elseif self:getNumHiddenCards() > 0 then
        active_pile = self.hidden
    end
    return active_pile
end

function Player:getActiveCards()
    local active_pile = self:getActivePile()
    if active_pile then
        return active_pile:getCards()
    end
    return {}
end

function Player:executeTurn()
    local next_player = true
    local active_pile = self:getActivePile()
    local player = player_list:getCurrentPlayer()

    if active_pile:isValidPlay() then
        active_pile:playCards()
    else
        player:pickUpPile()
    end

    -- Apply card face rules
    local top_face = discard_pile:getTopFace()
    if top_face == '8' then
        next_player = false
    elseif top_face == '10' then
        discard_pile:killPile()
        next_player = false
    elseif top_face == 'R' then
        player_list:reverseDirection()
    end

    -- Kill pile if 4+ top cards match
    if discard_pile:getRunLength() >= KILL_RUN_LEN then
        discard_pile:killPile()
        next_player = false
    end

    -- Keep player's hand at the minimum number of cards,
    -- as long as there's cards to draw
    while player:getNumHandCards() < PlayerHand.SIZE and
          draw_pile:getNumCards() > 0 do
        player:addToHand(draw_pile)
    end

    -- TODO do we want to stop when a player wins,
    -- make it a binary win/loss condition?
    -- Test for win condition
    if player:getNumCards() == 0 then
        logger('wins!')
        player_list:addWinner()
        next_player = true
        -- Test for game over condition
        if player_list:getNumPlayers() == 1 then
            require 'game_over'
            player_list:addWinner(player_list:nextPlayerNum())
            scene = GameOver:new(player_list.winners)
        end
    end

    if next_player == true then
        player_list:advancePlayer()
    else
        player_list:advanceTurn()
    end
end


HumanPlayer = class('HumanPlayer', Player)

function HumanPlayer:initialize(num)
    Player.initialize(self, num)
    self.hand:sortByRank()
end

function HumanPlayer:addToHand(cards, num)
    Player.addToHand(self, cards, num)
    self.hand:sortByRank()
end

function HumanPlayer:addToHandFromHidden(num)
    Player.addToHandFromHidden(self, num)
    self.hand:sortByRank()
end

function HumanPlayer:pickUpPile()
    Player.pickUpPile(self)
    self.hand:sortByRank()
end


PlayerList = class('PlayerList')

function PlayerList:initialize()
    self.players = {}
    self.winners = {}
    self.curr_player = 0
    self.reverse = false
    self.turn = 1

    for i = 1,NUM_PLAYERS do
        if i == 1 then
            player = HumanPlayer:new(i)
        else
            player = AIPlayer:new(i)
        end

        table.insert(self.players, player)
    end

    self.curr_player = self:initPlayerNum()
end

function PlayerList:getCurrentPlayer()
    return self.players[self.curr_player]
end

function PlayerList:getNextPlayer()
    return self.players[self:nextPlayerNum()]
end

function PlayerList:getHumanPlayer()
    -- TODO make this less brittle
    return self.players[1]
end

function PlayerList:advancePlayer()
    self:advanceTurn()
    self.curr_player = self:nextPlayerNum()
end

function PlayerList:advanceTurn()
    self.turn = self.turn + 1
end

function PlayerList:getNumPlayers()
    return #self.players
end

function PlayerList:reverseDirection()
    logger('reversed the direction')
    self.reverse = not self.reverse
end

function PlayerList:getTurn()
    return self.turn
end

function PlayerList:nextPlayerNum()
    local num_players = #self.players
    local curr_player = self.curr_player

    if not self.reverse then
        curr_player = curr_player + 1
    else
        curr_player = curr_player - 1
    end

    if curr_player > num_players then curr_player = 1 end
    if curr_player < 1 then curr_player = num_players end

    return curr_player
end

-- Pick starting player by matching the first instance of
-- a non-special face with a card in a player's hand
function PlayerList:initPlayerNum()
    for _,face in ipairs(Card.START_ORDER) do
        for _,player in ipairs(self.players) do
            if player.hand:hasCard(face) then
                return player.num
            end
        end
    end
    return 1
end

function PlayerList:addWinner(num)
    local player_num = num or self.curr_player
    local player = table.remove(self.players, player_num)
    table.insert(self.winners, player)
end
