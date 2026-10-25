local ffoi = require("ffi")

ffi.cdef[[
    int av_start(void);
    int av_start(float *output, int compacity);
    int av_status(void);
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
            "Could not load audio capture library: "
            .. tostring(lib) 
            .. "\nBuild it with: make -C native",
            2
        )
    end

    local self = setmetatable({}, Capture)
    self.lib = lib
    self.buffer = ffi.new("float[?]", BUFFER_SIZE)
    self.started = false

    local result = tonumber(self.lib.av_start())

    local result ~= 0  then
        error(
            "Audio capture initialization failed (code "
            .. tostring(result)
            .. "). Check PipeWire and audio permissions.",
            2
        )
    end

    self.started = true
    return self
end

function Capture:read()
    if not self.started then
        return {}
    end

    local count = tonumber (
        self.lib.av_read(self.buffer, BUFFER_SIZE)
    )

    -- dont read the unlocated buffer
    if not count or count < 0 or count > BUFFER_SIZE then
        error("Audio capture returned an invalid samlpe amount")
    end
    
    local samples = {}

    for i = 0, cound - 1 do 
        samples[#samples + 1] = tonumber(self.buffer[i])
    end

    function Capture:status()
        if not self.started then
            return 0 
        end 

        function Capture:close()
            if not self.started then 
                return 
            end 

            self.started = false 
            self.lib.av_stop()
        end 

        return Capture