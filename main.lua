
local config = require("config")
local Capture = require("audio.capture")
local Spectrum = require("audio.spectrum")
local Widget = require("ui.widget")

local capture
local spectrum
local widget
local startupError
local captureError

function love.load()
    local ok, result = pcall(function()
        capture = Capture.new()
        spectrum = Spectrum.new(config)
        widget = Widget.new(config)
    end)

    if not ok then
        startupError = tostring(result)

        if capture then
            pcall(function()
                capture:close()
            end)
            capture = nil
        end
    end
end

function love.update(dt)
    if not capture or not spectrum or not widget or captureError then
        return
    end

    local ok, samples, readError = pcall(function()
        return capture:read()
    end)

    if not ok then
        captureError = tostring(samples)
        return
    end

    if not samples then
        captureError = tostring(readError or "Audio read failed, lol ur shits broken")
        return
    end

    spectrum:push(samples)
    widget:update(dt, spectrum:getLevels())
end

function love.draw()
    local width, height = love.graphics.getDimensions()

    if not widget then
        love.graphics.clear(0.035, 0.035, 0.04, 1)
        love.graphics.setColor(1, 0.4, 0.4, 1)
        love.graphics.printf(
            startupError or "Initializing...",
            24, 24, math.max(1, width - 48), "left"
        )
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    local status = captureError and -1 or capture:status()
    widget:draw(width, height, status, captureError)
end

function love.quit()
    if capture then
        pcall(function()
            capture:close()
        end)
        capture = nil
    end
end