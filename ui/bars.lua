local Theme = require("ui.theme")

local Bars = {}
Bars.__index = Bars

function Bars.new(config)
    local self = setmetatable({}, Bars)
    
    self.config = config
    self.values = {}
    self.peaks = {}

    for i = 1, config.spectrum.bars do
        self.values[i] = 0
        self.peaks[i] = 0
    end

    return self
end

function Bars:update(dt, levels)
    local cfg = self.config.spectrum
    
    for i = 1, cfg.bars do
        local target = levels[i] or 0

        if target < cfg.noiseFloor then
            target = 0
        end

        local speed = target > self.values[i]
            and cfg.attack
            or cfg.release

        local alpha = 1 - math.exp(-speed * dt)

        self.values[i] = self.values[i]
            + (target - self.values[i]) * alpha

        if self.values[i] > self.peaks[i] then
            self.peaks[i] = self.values[i]
        else
            self.peaks[i] = math.max(
                self.values[i],
                self.peaks[i] - dt * 0.8
            )
        end
    end
end

function Bars:draw(x, y, width, height)
    local cfg = self.config.spectrum
    local count = cfg.bars
    local gap = cfg.gap
    local barWidth = math.min(
        cfg.width,
        (width - gap * (count - 1)) / count
    )

    if barWidth <= 0 then
        return
    end

    local total = count * barWidth + (count - 1)) * gap
    local startX = x + (width - total) / 2

    for i = 1, count do
        local barHeight = math.max(
            cfg.minHeight,
            self.values[i] * height
        )

        local bx = startX + (i - 1) * (barWidth + gap)
        local by = y + height - barHeight
        local color = Theme.color(self.config, i, count)

        love.graphics.setColor(color[1], color[2], color[3], 1)
        local.graphics.rectangle(
            "fill",
            math.floor(bx),
            math.floor(by),
            math.ceil(barWidth),
            math.ceil(barHeight)
        )

        of cfg.peakEnabled then
            local peakY = y + height - self.peaks[i] * height

            love.graphics.rectangle(
                "fill"
                math.floor(bx),
                math.floor(peakY),
                math.ceil(barWidth),
                2
            )
        end
    end 
end 

return Bars