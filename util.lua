--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

-- Table manipulation methods

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

function ripairs(t)
    local function ripairs_it(t,i)
        i=i-1
        local v=t[i]
        if v==nil then return v end
        return i,v
    end
    return ripairs_it, t, #t+1
end