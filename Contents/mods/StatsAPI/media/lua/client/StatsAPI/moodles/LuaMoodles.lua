local core = getCore()

local MoodleTemplate = require "StatsAPI/moodles/MoodleTemplate"
local LuaMoodle = require "StatsAPI/moodles/LuaMoodle"

---@class LuaMoodles
---@field playerNum int
---@field stats CharacterStats
---@field moodles table<string, LuaMoodle>
---@field showingMoodles table<LuaMoodle>
local LuaMoodles = {}
---@type table<LuaMoodles>
LuaMoodles.instanceMap = {}
LuaMoodles.scale = 1
LuaMoodles.spacing = 36
LuaMoodles.rightOffset = 50
LuaMoodles.topOffset = 100

---@private
---@param self LuaMoodles
---@param playerNum int
LuaMoodles.new = function(self, playerNum)
    local o = {}
    setmetatable(o, self)
    
    o.playerNum = playerNum
    o.showingMoodles = {}
    o.moodles = {}
    for i = 1, #MoodleTemplate.templates do
        ---@type MoodleTemplate
        local template = MoodleTemplate.templates[i]
        local moodle = LuaMoodle:new(core:getScreenWidth() - LuaMoodles.rightOffset, LuaMoodles.topOffset, template, o)
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

---@param self LuaMoodles
LuaMoodles.adjustPosition = function(self)
    local x = core:getScreenWidth()
    if self.playerNum == 0 or self.playerNum == 2 then
        x = x / 2
    end
    x = x - LuaMoodles.rightOffset
    
    local y = LuaMoodles.topOffset
    if self.playerNum >= 2 then
        y = core:getScreenHeight() + y
    end
    
    for _, moodle in pairs(self.moodles) do
        moodle:setX(x)
        moodle.baseY = y
    end
    self:sortMoodles()
end

---@param playerNum int
LuaMoodles.create = function(playerNum)
    local moodles = LuaMoodles:new(playerNum)
    LuaMoodles.instanceMap[playerNum] = moodles
    for i = 0, 3 do
        ---@type LuaMoodles
        local instance = LuaMoodles.instanceMap[i]
        if instance then
            instance:adjustPosition()
        end
    end
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