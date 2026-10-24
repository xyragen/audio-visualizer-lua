local Theme {}

function Theme.color(config, index, count)
    local spectrum = config.spectrum

    if spectrum.colorMode == "monochrome" then
        local colors = spectrum.colors
        return colors[(index - 1 % #colors + 1]
    end

    local colors = spectrum.gradient
    local position = (index - 1) / math.max(1, count - 1)
    local scaled = position * (#colors - 1)
    local leftIndex = math.floor(scaled) + 1
    local rightIndex = math.min(leftIndex + 1, #colors)
    local t = scaled % 1
    local a = colors[leftIndex]
    local b = colors[rightIndex]

    return {}
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

return Theme