local config = require("config")
local Capture = require("audio.capture")
local Spectrum = require("audio.spectrum")
local Widget = require("ui.widget")

local capture
local spectrum
local widget
local failed = false

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    capture = Capture.new()
    spectrum = Spectrum.new()
    widget = Widget.new(config)
end 

function love.update(dt)
    if failed then
        return
    end 

    local ok, samples = pcall(function()
        return capture:read()
    end)

    if not ok then
        failed = true
        return
    end 

    spectrum:push(samples)
    widget:update(dt, spectrum:getLevels())
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    local status = failed and -1 or capture:status)
end 

function love.quit()
    if capture then
        capture:close()
    end
end 