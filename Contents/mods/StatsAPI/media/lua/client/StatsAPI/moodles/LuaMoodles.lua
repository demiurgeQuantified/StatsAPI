local MoodleTemplate = require "StatsAPI/moodles/MoodleTemplate"
local LuaMoodle = require "StatsAPI/moodles/LuaMoodle"

---@class LuaMoodles
---@field stats CharacterStats
---@field moodles table<LuaMoodle>
local LuaMoodles = {}
LuaMoodles.instanceMap = {}
LuaMoodles.scale = 2
LuaMoodles.gap = 16

---@private
---@param self LuaMoodles
---@param stats CharacterStats
LuaMoodles.new = function(self, stats)
    local o = {}
    setmetatable(o, self)
    
    o.stats = stats
    o.moodles = {}
    for i = 1, #MoodleTemplate.templates do
        local moodle = LuaMoodle:new(MoodleTemplate.templates[i])
        o.moodles[i] = moodle
        moodle:initialise()
        moodle:addToUIManager()
    end
    
    return o
end

---@param stats CharacterStats
LuaMoodles.create = function(stats)
    local moodles = LuaMoodles:new()
    LuaMoodles.instanceMap[stats.playerNum] = moodles
    return moodles
end

LuaMoodles.disableVanillaMoodles = function()
    local ui = UIManager.getUI()
    for i = 0, 3 do
        ui:remove(UIManager.getMoodleUI(i))
    end
end

Events.OnGameStart.Add(LuaMoodles.disableVanillaMoodles)

return LuaMoodles