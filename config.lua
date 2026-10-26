return {
    ui = {
        background = {0.035, 0.035, 0.04, 1},
        border = {0.18, 0.18, 0.20, 1},
        text = {0.92, 0.92, 0.94, 1},
        muted = {0.5, 0.5, 0.53, 1},
        padding = 16,
        headerHeight = 44
    },

    spectrum = {
        bars = 48,
        width = 9,
        gap = 2,
        minHeight = 3,

        colorMode = "gradient",

        gradient = {
            {0.2, 1, 0.4},
            {0, 0.85, 1},
            {0.45, 0.3, 1}

        },

        colors = {
            {1, 1, 1},
            {0.7, 0.7, 0.7}
        },

        attack = 32,
        release = 8,
        sensitivity = 3.5,
        noiseFloor = 0.005,
        peakEnabled = true,
        peakDecay = 0.8
    },

    audio = {
        sampleRate = 48000,
        fftSize = 2048,
        hopSize = 512,
        minFrequency = 40,
        maxFrequency = 16000
    }
}