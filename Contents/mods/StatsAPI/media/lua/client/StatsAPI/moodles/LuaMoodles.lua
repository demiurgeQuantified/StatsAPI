local MoodleTemplate = require "StatsAPI/moodles/MoodleTemplate"
local LuaMoodle = require "StatsAPI/moodles/LuaMoodle"

---@class LuaMoodles
---@field stats CharacterStats
---@field moodles table<string, LuaMoodle>
---@field showingMoodles table<LuaMoodle>
local LuaMoodles = {}
---@type table<LuaMoodles>
LuaMoodles.instanceMap = {}
LuaMoodles.scale = 1
LuaMoodles.gap = 36

---@private
---@param self LuaMoodles
LuaMoodles.new = function(self)
    local o = {}
    setmetatable(o, self)
    
    o.showingMoodles = {}
    o.moodles = {}
    for i = 1, #MoodleTemplate.templates do
        ---@type MoodleTemplate
        local template = MoodleTemplate.templates[i]
        local moodle = LuaMoodle:new(template, o)
        o.moodles[template.type] = moodle
    end
    
    return o
end

---@param self LuaMoodles
---@param moodle LuaMoodle
LuaMoodles.showMoodle = function(self, moodle)
    table.insert(self.showingMoodles, moodle)
    self:sortMoodles()
end

---@param self LuaMoodles
---@param moodle LuaMoodle
LuaMoodles.hideMoodle = function(self, moodle)
    for i = 1, #self.showingMoodles do
        if self.showingMoodles[i] == moodle then
            table.remove(self.showingMoodles, i)
            break
        end
    end
    self:sortMoodles()
end

---@param self LuaMoodles
LuaMoodles.sortMoodles = function(self)
    for i = 1, #self.showingMoodles do
        self.showingMoodles[i]:setRenderIndex(i)
    end
end

---@param playerNum int
LuaMoodles.create = function(playerNum)
    local moodles = LuaMoodles:new()
    LuaMoodles.instanceMap[playerNum] = moodles
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