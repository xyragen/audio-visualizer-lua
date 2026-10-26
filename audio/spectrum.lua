
local FFT = require("audio.fft")

local Spectrum = {}
Spectrum.__index = Spectrum

function Spectrum.new(config)
    assert(config and config.audio and config.spectrum,
        "Spectrum.new requires the application config")

    local audio = config.audio
    local settings = config.spectrum

    assert(audio.fftSize >= 2
        and audio.fftSize % 1 == 0,
        "fftSize must be an integer >= 2")
    assert(audio.hopSize >= 1,
        "hopSize must be positive")
    assert(audio.sampleRate > 0,
        "sampleRate must be positive")
    assert(audio.minFrequency > 0,
        "minFrequency must be positive")
    assert(audio.maxFrequency > audio.minFrequency,
        "maxFrequency must exceed minFrequency")

    local self = setmetatable({}, Spectrum)

    self.config = audio
    self.settings = settings
    self.buffer = {}
    self.head = 1
    self.levels = {}

    for i = 1, settings.bars do
        self.levels[i] = 0
    end

    return self
end

function Spectrum:analyze()
    local cfg = self.config
    local settings = self.settings
    local n = cfg.fftSize

    local real, imag = {}, {}

    for i = 1, n do
        local sample = self.buffer[self.head + i - 1] or 0
        local window = 0.5 - 0.5 *
            math.cos(2 * math.pi * (i - 1) / (n - 1))

        real[i] = sample * window
        imag[i] = 0
    end

    FFT.transform(real, imag, n)

    local nyquist = cfg.sampleRate / 2
    local maxFreq = math.min(cfg.maxFrequency, nyquist)
    local minFreq = math.min(cfg.minFrequency, maxFreq)
    local bars = settings.bars

    for band = 1, bars do
        local ratio = maxFreq / minFreq

        local low = minFreq *
            ratio ^ ((band - 1) / bars)
        local high = minFreq *
            ratio ^ (band / bars)

        local first = math.max(
            1, math.floor(low * n / cfg.sampleRate)
        )
        local last = math.min(
            n / 2,
            math.ceil(high * n / cfg.sampleRate)
        )

        local magnitude = 0

        for bin = first, last do
            local re, im = real[bin + 1], imag[bin + 1]
            local value = math.sqrt(re * re + im * im) * 2 / n

            if value > magnitude then
                magnitude = value
            end
        end

        self.levels[band] = math.min(
            1, magnitude * settings.sensitivity
        )
    end
end

function Spectrum:push(samples)
    for i = 1, #samples do
        local value = samples[i]

        if type(value) == "number"
            and value == value
            and value ~= math.huge
            and value ~= -math.huge then
            self.buffer[#self.buffer + 1] =
                math.max(-1, math.min(1, value))
        else
            self.buffer[#self.buffer + 1] = 0
        end
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
            remaining[#remaining + 1] = self.buffer[i]
        end

        self.buffer = remaining
        self.head = 1
    end
end

function Spectrum:getLevels()
    return self.levels
end

return Spectrum
