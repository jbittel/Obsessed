--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

function logger(msg)
    local turn = player_list:getTurn()
    local player = player_list:getCurrentPlayer()
    print(tostring(turn)..': '..tostring(player)..' '..msg)
end

function img_filename(str)
    str = str:gsub(' ', '-')
    return string.lower('images/'..str..'.png')
end

function table_copy(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return t2
end
