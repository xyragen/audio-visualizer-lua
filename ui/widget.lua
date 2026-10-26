
local Bars = require("ui.bars")

local Widget = {}
Widget.__index = Widget

local labels = {
    [0] = "Stopped",
    [1] = "Connecting...",
    [2] = "Audio connected",
    [-1] = "Audio error",
    [-2] = "Stopping..."
}

function Widget.new(config)
    return setmetatable({
        config = config,
        bars = Bars.new(config)
    }, Widget)
end

function Widget:update(dt, levels)
    self.bars:update(dt, levels)
end

function Widget:draw(width, height, status, errorMessage)
    local ui = self.config.ui

    love.graphics.clear(
        ui.background[1], ui.background[2],
        ui.background[3], ui.background[4] or 1
    )

    love.graphics.setColor(
        ui.border[1], ui.border[2], ui.border[3],
        ui.border[4] or 1
    )
    love.graphics.rectangle("fill", 0, ui.headerHeight, width, 1)

    love.graphics.setColor(
        ui.text[1], ui.text[2], ui.text[3], ui.text[4] or 1
    )
    love.graphics.print("Audio Visualizer Lua", ui.padding, 14)

    local color = status == 2
        and {0.3, 1, 0.5, 1}
        or {ui.muted[1], ui.muted[2], ui.muted[3], 1}

    love.graphics.setColor(color)
    love.graphics.printf(
        labels[status] or "Unknown status",
        0, 14, math.max(0, width - ui.padding), "right"
    )

    local x, y = ui.padding, ui.headerHeight + 14
    local drawWidth = math.max(0, width - 2 * ui.padding)
    local drawHeight = math.max(0, height - y - ui.padding)

    if errorMessage then
        love.graphics.setColor(1, 0.4, 0.4, 1)
        love.graphics.printf(errorMessage, x, y, drawWidth, "left")
    end

    self.bars:draw(x, y, drawWidth, drawHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

return Widget
