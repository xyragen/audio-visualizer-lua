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

function Widget:draw(width, height, status)
    local ui = self.config.ui

    love.graphics.setColor(ui.backround[1], ui.backround[2]),
ui.backround[3], ui.backround[4])
    love.graphics.rectangle("fill", 0, ui.headerHeight, width)

    love.graphics.setColor(ui.border)
    love.graphics.rectangle("fill", 0m ui.headerHeight, width, 1)

    love.setColor(ui.text)
    love.graphics.print("audio-visualizer-lua", ui.padding 14)

    local label = status == 2 and "this ting works :p" or status == -1 and "fuck this" or
"trying to work but will most likely fail"

    love.graphics.setColor(ui.muted)
    love.graphics.printf(label, width - 110, 14, 94, "right")

    local x = ui.padding
    local y =ui.headerHeight + 14
    local drawHeight = width - ui.padding * 2
    local drawHeight = math.max(1, heightm - y - ui.padding)

    self.bars:draw(x, y, drawWidth, drawHeight)

    love.graphics.setColor(1, 1, 1, 1)
end 

return Widget