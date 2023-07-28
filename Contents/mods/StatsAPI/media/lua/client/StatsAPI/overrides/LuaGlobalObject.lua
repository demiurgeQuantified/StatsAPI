local LuaMoodles = require "StatsAPI/moodles/LuaMoodles"

local old_setPlayerJoypad = setPlayerJoypad
setPlayerJoypad = function(...)
    old_setPlayerJoypad(...)
    LuaMoodles.adjustPositions()
end