--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Button = class('Button')

function Button:initialize(text, x, y)
    self.text = text
    self.width = font.default:getWidth(text)
    self.height = font.default:getHeight()
    self.x = x - (self.width / 2)
    self.y = y
end

function Button:draw()
    local r, g, b, a = love.graphics.getColor()
    if self:hover() then
        love.graphics.setColor(255, 0, 255, 190)
    end

    love.graphics.setFont(font.default)
    love.graphics.print(self.text, self.x, self.y - self.height)

    love.graphics.setColor(r, g, b, a)
end

function Button:hover()
    local mx, my = love.mouse.getPosition()
    if mx > self.x and mx < self.x + self.width and
       my > self.y and my < self.y + self.height then
        return true
    end
    return false
end

function Button:mousepressed(x, y, button)
    if self:hover() then return true end
    return false
end
