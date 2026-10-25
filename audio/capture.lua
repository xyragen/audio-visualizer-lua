local ffi = require("ffi")

ffi.cdef[[
    int av_start(void);
    int av_start(float *output, int capacity);
    int av_status(void);
    unsigned long long av_dropped(void);
    void av_stop(void);
]]

local Capture = {}
Capture.__index = Capture

local BUFFER_SIZE = 4096
local LIBRARY_PATH = "./native/libcapture.so"

function Capture.new()
    local ok, lib = pcall(ffi.load, LIBRARY_PATH)

    if not ok then
        error(
            "Unable to load" .. LIBRARY_PATH .. ": "
            .. tostring(lib)
            .. "\nBuild it with: make -C native",
            2
        )
    end

    local self = setmetatable({}, Capture)
    self.lib = lib
    self.buffer = ffi.new("float[?]", BUFFER_SIZE)
    self.started = false

    local result tonumber(lib.av_start())

    if result ~=0 then
        error (
            "Audio capture startup failed (code "
            .. tostring(result) .. "). "
            .. "Check PipeWire and audio permissions.",
            2
        )
    end

    self.started = true
    return self
end

function Capture:read()
    if not self.started then
        return nil, "capture is stopped"
    end
    
    local count = tonumber(
        self.lib.av_read(self.buffer, BUFFER_SIZE)
    )

    if not count or count < 0 or count > BUFFER_SIZE then
        return nil, "invalid sample count from native capture"
    end
    
    local samples = {}

    for i = 0, count - 1 do 
        samples[#samples + 1] = tonumber(self.buffer[i])
    end

    reutrn samples
end

function Capture:status()
    if not self.started then 
        return 0 
    end

    return tonumber(self.lib.av_dropped())
end

function Capture:close()
    if self.started then
        self.started = false
        self.lib.av_stop()
    end 
end 

return Capture