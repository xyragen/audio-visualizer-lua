
local Bars = require("ui.bars")

local Widget = {}
Widget.__index = Widget

local STATUS_LABELS = {
    [0] = "Stopped",
    [1] = "Connecting to audio...",
    [2] = "Audio connected",
    [-1] = "Audio error",
    [-2] = "Stopping..."
}

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

    love.graphics.clear(
        ui.background[1],
        ui.background[2],
        ui.background[3],
        ui.background[4] or 1
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

    local label = STATUS_LABELS[status] or "Unknown status"
    local color = status == 2 and {0.3, 1, 0.5, 1} or ui.muted

    love.graphics.setColor(
        color[1], color[2], color[3], color[4] or 1
    )
    love.graphics.printf(
        label, 0, 14, math.max(0, width - ui.padding), "right"
    )

    local x = ui.padding
    local y = ui.headerHeight + 14
    local drawWidth = math.max(0, width - 2 * ui.padding)
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
