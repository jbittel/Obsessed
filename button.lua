--[[

  ----------------------------------------------------
  obsessed - a card game of mystery and intrigue
  ----------------------------------------------------

  Copyright (c) 2013 Jason Bittel <jason.bittel@gmail.com>

--]]

Button = class('Button')

function Button:initialize(text, x, y)
    self.text = text
    self.img = love.graphics.newImage(img_filename(text))
    self.width = self.img:getWidth()
    self.height = self.img:getHeight()
    self.x = x
    self.y = y
end

function Button:draw()
    love.graphics.draw(self.img, self.x, self.y)
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
