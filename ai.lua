-- TODO play cards according to an assigned value
-- TODO prioritize 4+ stacks of non-special cards
-- TODO only(?) play stacks of non-special cards
function play_ai(pile, hand)
    local num = #hand
    for i=1,num do
        clear_play(hand)
        hand[i].play = true
    
        if is_valid_play(pile, hand) then
            -- Play all cards of the selected face
            for j=1,num do
                if hand[j].face == hand[i].face then
                    hand[j].play = true
                end
            end
            return
        end
    end
end
