local Bars = require("ui.bars")

local Widget = {}
Widget.__index = Widget

function Widget.new(config)
    local self = setmetatable({}, Widget)
    self.config = config 
    self.bars = Bars.new(config)
    return self 
end

function Widget:update(dt, levels)
    self.bars:update(dt, levels)
end 

function Widget:draw(width, height, status, errorMessage)
    local ui = self.config.ui 
    
    love.graphics.clear(ui.backround)

    love.graphics.setcolor(ui.border)
    love.graphics.rectangle(
        "fill", 0, ui.headerHeight, width, 1
    )

    love.graphics.printf(label, 0, 14, width - ui.padding, "right")

    local x = ui.padding 
    local y = ui.headerHeight + 14 
    local drawWidth = math.max(0, width - ui.padding * 2)
    local drawHeight = math.max(0, height - y - ui.padding)

    if errorMessage then
        love.graphics.setColor(1, 0.4, 0.4, 1)
        love.graphics.printf(
            errorMessage, x, y, drawWidth, "left"
        )
    end

    self.bars:draw(x, y, drawWidth, drawHeight)
    love.graphics.setColor(1, 1, 1, 1)
end 

return Widget 