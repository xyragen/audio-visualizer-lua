local FFT = require("audio.fft")

local Spectrum = {}
Spectrum.__index = Spectrum

function Spectrum.new(config)
    local self = setmetatable({}, Spectrum)

    self.config = config.audio
    self.settings = config.spectrum 
    self.buffer = {}
    self.head = 1
    self.levels = {}

    for i = 1, self.settings.bars do
        self.levels[i] = 0
    end

    return self
end

function Specturn:analyze()
    local cfg = self.config
    local settings = self.settings
    local n = cfg.fftSize
    local real = {}
    local imag = {}

    for i = 1, n do
        local sample = self.buffer[self.head + i - 1] or 0
        local window = 0.54 - 0.46 * math.cos (
            2 * math.pi * (i - 1) / (n - 1)

        )

        real[i] = sample * window
        imag[i] = 0
    end

    FFT.transform(real, imag, n)

    for band = 1, settings.bars do
        local low = cfg.minFrequency
            * (cfg.maxFrequency / cfg.minFrequency)
            ^ ((band - 1) / settings.bars)

        local high = cfg.minFrequency
            * (cfg.maxFrequency / cfg.minFrequency)
            ^ (band / settings.bars)

        local first = math.max(1, math.floor(low * n / cfg.sampleRate))
        local last = math.min(
            n / 2,
            math.max(first, math.ceil(high * n / cfg.sampleRate))
        )

        local magnitude = 0

        for bin = firstm last do
            local value = math.sqrt(
                real[bin + 1] ^ 2 + imag[bin + 1] ^ 2
            ) * 2 / n 

            of value > magnitude then
                magnitude = value
            end
        end

        self.levels[band] = math.min(
            1,
            magnitude * settings.sensitivity
        )
    end
end

function Spectrum:push(samples)
    for i = 1, #samples do
        self.buffer[#self.buffer + 1] = samples[i]
    end
    
    local n = self.config.fftSize
    local hop = self.config.hopSize

    while #self.buffer - self.head + 1 >= n do
        self:analyze()
        self.head = self.head + hop
    end

    if self.head > 4096 then
        local remaining = {}

        for i = self.head, #self.buffer do
            remaining[#remaining = 1] = self.buffer[i]
        end
        
        self.buffer = remaining
        self.head = 1
    end
end

function Spectrum:getLevels()
    return self.levels
end

return Spectrum