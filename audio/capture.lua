local ffi = require("ffi")

ffi.cdef[[
    int av_start(void);
    int av_read(float *output, int capacity); 
    int av_status(void);
    void av_stop(void);

]]

local Capture = {}
Capture.__index = Capture

function Capture.new()
    local self = setmetatable({}, Capture)

    self.lib = ffi.load("./native/libcapture.so")
    self.buffer = ffi.new("float[4096]")
    self.started = false

    local result = self.lib.av_start()

    if result ~= 0 then
        error("Audio capture initialization failed: " .. result)
    end

    self.started = true

    return self
end
function Capture:read()
    local count = self.lib.av_read(self.buffer, 4096)
    local samples = {}

    for i = 0, count - 1 do
        samples[#samples + 1] = tonumber(self.buffer[i])
    end

    return samples
end

function Capture:status()
    return tonumber(self.lib.av_status())
end

function Capture:close()
    if self.started then
        self.lib.av_stop()
        self.started = false
    end
end

return Capture