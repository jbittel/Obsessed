--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Player = class('Player')

function Player:initialize(num)
    self.num = num
    self.hand = PlayerHand:new()
    self.visible = PlayerVisible:new()
    self.hidden = PlayerHidden:new()
end

function Player:__tostring()
    return 'P'..tostring(self.num)
end

function Player:isAi()
    return self.class.name == 'AIPlayer'
end

function Player:getNum()
    return self.num
end

function Player:getHand()
    return self.hand
end

function Player:isCurrentPlayer()
    return self.num == player_list:getCurrentPlayerNum()
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

function Player:addToHand(pile, num)
    local card = pile:removeCard(num)
    if card ~= nil then self.hand:addCard(card) end
end

function Player:pickUpPile()
    local count = 0
    for _, card in ipairs(discard_pile:getCards()) do
        if card:getFace() ~= '3' then
            self.hand:addCard(card)
            count = count + 1
        end
    end
    discard_pile:removeCards()
    logger('picked up '..count..' cards')
end

function Player:selectInitialCard()
    local initial_face = nil
    for _, face in ipairs(Card.START_ORDER) do
        if self.hand:hasCard(face) then
            initial_face = face
            break
        end
    end
    self.hand:setSelectedFace(initial_face)
end

function Player:getActivePile()
    if self:getNumHandCards() > 0 then
        return self.hand
    elseif self:getNumVisibleCards() > 0 then
        return self.visible
    elseif self:getNumHiddenCards() > 0 then
        return self.hidden
    end
    return nil
end

function Player:executeTurn()
    local next_player = true
    local active_pile = self:getActivePile()
    local player = player_list:getCurrentPlayer()

    if active_pile:isValidPlay() then
        active_pile:playCards()
    elseif not active_pile:hasValidPlay() then
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
    if discard_pile:getRunLength() >= Game.KILL_RUN_LENGTH then
        discard_pile:killPile()
        next_player = false
    end

    -- Keep player's hand at the minimum number of cards,
    -- as long as there's cards to draw
    while player:getNumHandCards() < PlayerHand.SIZE and
          draw_pile:getNumCards() > 0 do
        player:addToHand(draw_pile)
    end

    -- Test for win condition
    if player:getNumCards() == 0 then
        logger('wins!')
        player_list:addWinner()
        next_player = true
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

function HumanPlayer:addToHand(pile, num)
    Player.addToHand(self, pile, num)
    self.hand:sortByRank()
end

function HumanPlayer:pickUpPile()
    Player.pickUpPile(self)
    self.hand:sortByRank()
end

function HumanPlayer:executeTurn()
    local active_pile = self:getActivePile()
    if active_pile then
        if active_pile:hasValidPlay() and not active_pile:isValidPlay() then
            return
        end
    end
    Player.executeTurn(self)
end


PlayerList = class('PlayerList')

function PlayerList:initialize()
    self.players = {}
    self.winners = {}
    self.reverse = false
    self.turn = 1

    for i = 1, Game.NUM_PLAYERS do
        if i == 1 then
            table.insert(self.players, HumanPlayer:new(i))
        else
            table.insert(self.players, AIPlayer:new(i))
        end
    end

    self.curr_player = self:initPlayerNum()
end

function PlayerList:getPlayers()
    return self.players
end

function PlayerList:getWinners()
    self:addWinners()
    return self.winners
end

function PlayerList:getCurrentPlayer()
    return self.players[self.curr_player]
end

function PlayerList:getCurrentPlayerNum()
    return self.curr_player
end

function PlayerList:getNextPlayer()
    return self.players[self:nextPlayerNum()]
end

function PlayerList:getHumanPlayer()
    for i, player in ipairs(self.players) do
        if  player.class.name == 'HumanPlayer' then
            return self.players[i]
        end
    end
    return nil
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

function PlayerList:isFirstTurn()
    return self:getTurn() == 1
end

function PlayerList:nextPlayerNum()
    local num_players = #self.players
    local next_player = self.curr_player

    if not self.reverse then
        next_player = next_player + 1
    else
        next_player = next_player - 1
    end

    if next_player > num_players then next_player = 1 end
    if next_player < 1 then next_player = num_players end

    return next_player
end

-- Pick starting player by matching the first instance of
-- a non-special face with a card in a player's hand
function PlayerList:initPlayerNum()
    for _, face in ipairs(Card.START_ORDER) do
        for _, player in ipairs(self.players) do
            if player:getHand():hasCard(face) then
                return player:getNum()
            end
        end
    end
    return 1
end

function PlayerList:isGameOver()
    return #self.players <= 1
end

function PlayerList:addWinner(num)
    local player_num = num or self.curr_player
    local player = table.remove(self.players, player_num)
    table.insert(self.winners, player)
end

function PlayerList:addWinners()
    for i, _ in ipairs(self.players) do
        self:addWinner(i)
    end
end
