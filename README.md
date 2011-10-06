Obsessed
--------

Obsessed is an implementation of the card game Obsession. For an explanation of the game's rules, see below. This is a command line application so to play the game, enter this at a command prompt:

    $ lua game.lua

During play, the game will look something like this:

    === PLAYER 2
    ### Draw:       63 cards
    ### Discard:    4 cards 1:2S 2:R 3:KH 4:KC 
    ### Hand:       3 cards
    ### Visible:    3 cards 1:10D 2:8D 3:AC 
    ### Hidden:     3 cards
    *** Played a 9H
    
    === PLAYER 1
    ### Draw:       62 cards
    ### Discard:    5 cards 1:9H 2:2S 3:R 4:KH 5:KC 
    ### Hand:       8 cards 1:6H 2:6H 3:6S 4:JH 5:JC 6:QS 7:QD 8:KS 
    ### Visible:    3 cards 1:KS 2:KD 3:R 
    ### Hidden:     3 cards
    +++ Select cards from your hand
    +++ Enter card number(s):

When prompted to enter card numbers, it will tell you what stack to draw cards from (hand, visible or hidden). The selection numbers are printed next to each card in the stack. Multiple cards can be played at a time by separating the numbers with a delimiter, which can be any non-numeric character. For example:

    +++ Enter card number(s): 4,5

Play will continue until one of the players wins.

Obsession
---------

Obsession is a card climbing game focusing on discarding cards according to a set of rules. For the purposes of this game, suits have no meaning and aces are high.

### STARTING THE GAME ###

Each player is dealt three cards that become their hand. Additionally, each player receives 6 cards that are placed in front of them, three of which are hidden face-down and three of which are face-up and visible to all other players. The remaining cards are placed in a central draw pile.

### PLAYING THE GAME ###

Play begins with the player who has the lowest available non-special card, which they play into a discard pile. After playing a card, the player draws the top card from the draw stack to ensure they maintain a minimum of 3 cards. If they have more than three cards, they do not draw any cards on their turn. Play continues clockwise to the next player, who either plays a non-special card equal to or greater in face value to the top card on the discard pile, or a special card which operate according to a set of rules listed below. If a player has a valid move they must take it, and if they do not have a valid move, then the current discard pile is picked up and becomes part of their hand. If a player has more than one identical face value card, they can choose to play the entire set as a stack on their turn. Any run of 4 or more cards on the discard pile kills it, and the current player's turn continues.

If the discard pile is killed, either through a run of 4+ cards or by playing a 10 special card, all cards in the discard pile are "killed" and removed entirely from play. The player who killed the pile continues their turn and can play anything on the now empty pile. A player can kill the pile multiple times on a single turn.

Play continues until the entire draw stack is gone. Once that occurs and the player's hand is depleted, they begin drawing cards one at a time from their visible set and adding them to their hand. The next visible card cannot be added to one's hand or played until their hand is empty again. Once all three visible cards are played and their hand is empty, they can begin drawing cards from their hidden set following the same rules as the visible set, with the notable exception that they cannot look at the cards until drawn.

The first player to discard all of their cards is the winner.

### SPECIAL CARDS AND ADDITIONAL RULES ###

Non-special cards: 4 5 6 9 J Q K A

Special cards: 2 3 7 8 10 R

Special card rules:

* 2: Next player plays anything
* 3: Next player must play a 3 or R, or pick up the pile
* 7: Next player must play under a 7 or a special card (no 8)
* 8: Current player can play anything, turn continues
* 10: Kills the pile, turn continues
* R: (Joker) Reverses the current direction of play

Additional rules:

* Any number of identical face value cards can be played simultaneously
* Any run of 4 or more cards kills the discard pile
* An 8 cannot be played on a 7
* If a valid move is present, it must be played
* If you have no valid moves, pick up the discard pile
* If the pile is empty, anything can be played
