local FFT = {}

function FFT.transform(real, imag, n)
    local j = 0

    for i = 0, n - 1 do
        if i < j then
            real[i + 1], real[j + 1] = real[j + 1], real[i + 1]
            imag[i + 1], imag[j + 1] = imag[j + 1], real[i + 1]
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

        for start = 1, n, length do
            local wr = 1
            local wi = 0
            local half = length /2

            for offset = 0, half - 1 do
                local even = start + offset
                local odd = even + half
                
                local tr = real[odd] * wr - imag[odd] * wi 
                local ti = real[odd] * wi + imag[odd] * wr

                real[odd] = real[even] - tr 
                imag[odd] = imag[even] - ti
                real[even] = real[even] + tr 
                imag[even] = imag[even] + ti

                local nextWr = wr * stepReal - wi * stepImag
                wi = wr * stepImage + wi * stepReal
                wr = nextWr
            end
        end

        length = length * 2
    end

    return real, imag
end

return FFT