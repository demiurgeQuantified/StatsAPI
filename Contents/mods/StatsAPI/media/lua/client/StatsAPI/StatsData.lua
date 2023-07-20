---@class StatsData
---@field character IsoGameCharacter The character this StatsData belongs to
---@field stats Stats The character's Stats object
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
local StatsData = {}
StatsData.panicIncrease = 7
StatsData.panicReduction = 0.06
StatsData.oldNumZombiesVisible = 0
StatsData.forceWakeUp = false
StatsData.asleep = false

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
    o.stats = character:getStats()
    
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