Obsessed
--------

Obsessed is an implementation of the card game Obsession. For an explanation of the game's rules, see below. It is built using the [LOVE game engine](http://love2d.org/). To play, first change to the game's root directory and enter::

    $ love .

Naturally, you will need a copy of LOVE 0.9.1+ installed.

Obsession
---------

Obsession is a card climbing game focusing on discarding cards according to a set of rules. The recommended setup is one full deck of cards (including both Jokers) for every two players, rounding the decks up as necessary (e.g. use two decks for four players and three decks for five). For the purposes of this game, suits have no meaning and aces are high.

### STARTING THE GAME ###

Each player is dealt three cards that become their hand. Additionally, each player receives six cards that are placed in front of them, three of which are hidden face-down and three of which are face-up and visible to all other players. The remaining cards are placed in a central draw pile.

### PLAYING THE GAME ###

Play begins with the player who has the lowest available non-special card, which they play into a central discard pile. After playing a card, the player draws the top card from the draw stack to ensure they maintain a minimum of three cards. If they have more than three cards, they do not draw any cards on their turn. Play continues clockwise to the next player, who either plays a non-special card equal to or greater in face value to the top card on the discard pile, or a special card which operates according to unique rules listed below. If a player has a valid move they must take it, and if they do not have a valid move, then the current discard pile is picked up and becomes part of their hand. If a player has more than one identical face value card, they can choose to play any number of them as a set on their turn. Any run of four or more cards on the discard pile, including cards played by other players, kills it and the current player gets another turn.


If the discard pile is killed, either through a run of four or more cards or by playing a 10 special card, all cards in the discard pile are "killed" and removed entirely from play. The player who killed the pile gets another turn and can play anything on the now empty pile. A player can kill the pile multiple times in a row.

Play continues until the entire draw stack is gone. Once that occurs and the player's hand is depleted, they begin drawing cards one at a time from their visible set and adding them to their hand. The next visible card cannot be added to one's hand or played until their hand is empty again. Once all three visible cards are played and their hand is empty, they can begin drawing cards from their hidden set following the same rules as the visible set, with the notable exception that they cannot look at each card until drawn.

The first player to discard all of their cards is the winner.

### SPECIAL CARDS AND ADDITIONAL RULES ###

Non-special cards: 4 5 6 9 J Q K A

Special cards: 2 3 7 8 10 R

Special card rules:

* 2: Next player plays anything
* 3: Next player must play a 3 or R, or pick up the pile
* 7: Next player must play under a 7 or any special card except for an 8
* 8: Current player gets another turn, can play anything
* 10: Kills the pile, current player gets another turn
* R: (Joker) Reverses the current direction of play

Additional rules:

* Any number of identical face value cards can be played simultaneously
* A run of four or more cards kills the discard pile
* An 8 cannot be played on a 7
* If a valid move is present, it must be played
* If you have no valid moves, add the current discard pile to your hand
* If the pile is empty, anything can be played
* When the discard pile is picked up, any 3s in it are removed and killed
