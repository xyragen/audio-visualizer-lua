
local Theme = {}

local function interpolate(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t
    }
end

function Theme.color(config, index, count)
    local spectrum = config.spectrum

    if spectrum.colorMode == "monochrome" then
        local colors = spectrum.colors
        return colors[((index - 1) % #colors) + 1]
    end

    local colors = spectrum.gradient

    if #colors == 0 then
        return {1, 1, 1}
    end

    if #colors == 1 then
        return colors[1]
    end

    local position = (index - 1) / math.max(1, count - 1)
    local scaled = position * (#colors - 1)
    local leftIndex = math.floor(scaled) + 1
    local rightIndex = math.min(leftIndex + 1, #colors)
    local t = scaled - math.floor(scaled)

    return interpolate(colors[leftIndex], colors[rightIndex], t)
end

return Theme