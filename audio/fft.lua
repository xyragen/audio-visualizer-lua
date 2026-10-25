
local FFT = {}

function FFT.transform(real, imag, n)
    assert(type(n) == "number" and n >= 2,
        "FFT size must be at least 2")
    assert(n % 1 == 0, "FFT size must be an integer")
    assert(#real >= n and #imag >= n,
        "FFT arrays are too small")

    local size = n
    while size > 1 do
        if size % 2 ~= 0 then
            error("FFT size must be a power of two")
        end
        size = size / 2
    end

    local j = 0

    for i = 0, n - 1 do
        if i < j then
            real[i + 1], real[j + 1] =
                real[j + 1], real[i + 1]

            imag[i + 1], imag[j + 1] =
                imag[j + 1], imag[i + 1]
        end

        local bit = n / 2

        while bit >= 1 and j >= bit do
            j = j - bit
            bit = bit / 2
        end

        j = j + bit
    end

    local length = 2

    while length <= n do
        local angle = -2 * math.pi / length
        local stepReal = math.cos(angle)
        local stepImag = math.sin(angle)
        local half = length / 2

        for start = 1, n, length do
            local wr, wi = 1, 0

            for offset = 0, half - 1 do
                local even = start + offset
                local odd = even + half

                local tr =
                    real[odd] * wr - imag[odd] * wi
                local ti =
                    real[odd] * wi + imag[odd] * wr

                local er, ei = real[even], imag[even]

                real[even] = er + tr
                imag[even] = ei + ti
                real[odd] = er - tr
                imag[odd] = ei - ti

                local nextWr =
                    wr * stepReal - wi * stepImag
                wi = wr * stepImag + wi * stepReal
                wr = nextWr
            end
        end

        length = length * 2
    end

    return real, imag
end

return FFT
