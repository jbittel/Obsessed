function play_ai(pile, hand)
    local num = #hand
    for i=1,num do
        clear_play(hand)
        hand[i].play = true
    
        if is_valid_play(pile, hand) then
            return
        end
    end
end
