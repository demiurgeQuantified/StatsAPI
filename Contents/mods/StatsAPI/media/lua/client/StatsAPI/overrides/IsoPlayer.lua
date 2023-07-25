local CharacterStats = require "StatsAPI/CharacterStats"

local isoPlayer = __classmetatables[IsoPlayer.class].__index

---@type fun(self:IsoGameCharacter, ForceWakeUpTime:float)
local old_setForceWakeUpTime = isoPlayer.setForceWakeUpTime
---@param self IsoGameCharacter
---@param ForceWakeUpTime float
isoPlayer.setForceWakeUpTime = function(self, ForceWakeUpTime)
    CharacterStats.getOrCreate(self).forceWakeUpTime = ForceWakeUpTime
    old_setForceWakeUpTime(self, ForceWakeUpTime)
end

---@type fun(self:IsoGameCharacter)
local old_forceAwake = isoPlayer.forceAwake
---@param self IsoGameCharacter
isoPlayer.forceAwake = function(self)
    if self:isAsleep() then
        CharacterStats.getOrCreate(self).forceWakeUp = true
    end
    old_forceAwake(self)
end

---@type fun(self:IsoPlayer, maxWeightDelta:float)
local old_setMaxWeightDelta = isoPlayer.setMaxWeightDelta
---@param self IsoPlayer
---@param maxWeightDelta float
isoPlayer.setMaxWeightDelta = function(self, maxWeightDelta)
    CharacterStats.getOrCreate(self).maxWeightDelta = maxWeightDelta
    old_setMaxWeightDelta(self, maxWeightDelta)
end