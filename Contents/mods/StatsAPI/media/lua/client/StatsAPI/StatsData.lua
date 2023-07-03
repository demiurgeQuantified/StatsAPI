---@class StatsData
---@field character IsoGameCharacter
---@field panicIncrease number
---@field panicReduction number
---@field oldNumZombiesVisible number
---@field forceWakeUp boolean
---@field forceWakeUpTime number
local StatsData = {}
StatsData.panicIncrease = 7
StatsData.panicReduction = 0.06
StatsData.oldNumZombiesVisible = 0
StatsData.forceWakeUp = false

StatsData.persistentStats = {forceWakeUpTime = true}
---@param self StatsData
---@param key any
StatsData.__index = function(self, key)
    if StatsData.persistentStats[key] then
        return self.modData[key]
    end
    return StatsData[key]
end

---@param self StatsData
---@param key any
---@param value any
StatsData.__newindex = function(self, key, value)
    if StatsData.persistentStats[key] then
        self.modData[key] = value
    else
        rawset(self, key, value)
    end
end

---@param self StatsData
---@param character IsoGameCharacter
StatsData.new = function(self, character)
    local o = {}
    setmetatable(o, self)
    
    o.character = character
    
    local modData = character:getModData()
    modData.StatsAPI = modData.StatsAPI or {}
    modData.StatsAPI.StatsData = modData.StatsAPI.StatsData or {}
    o.modData = modData.StatsAPI.StatsData
    
    return o
end

---@type table<int, StatsData>
---@see StatsData#createPlayerData
---@see StatsData#getPlayerData
local PlayerData = {}

---Creates StatsData for the passed player and adds it to the table.
---@param player IsoPlayer
---@return StatsData
StatsData.createPlayerData = function(player)
    local statsData = StatsData:new(player)
    PlayerData[player:getPlayerNum()] = statsData
    return statsData
end

---Returns the player's StatsData.
---@param player IsoPlayer
---@return StatsData
StatsData.getPlayerData = function(player)
    return PlayerData[player:getPlayerNum()]
end

return StatsData