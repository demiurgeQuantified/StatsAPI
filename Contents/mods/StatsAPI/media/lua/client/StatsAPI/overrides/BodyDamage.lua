local CharacterStats = require "StatsAPI/CharacterStats"

local bodyDamage = __classmetatables[BodyDamage.class].__index

---@param self BodyDamage
---@param PanicIncreaseValue number
bodyDamage.setPanicIncreaseValue = function(self, PanicIncreaseValue)
    CharacterStats.getOrCreate(self:getParentChar()).panicIncrease = PanicIncreaseValue
end

---@param self BodyDamage
---@param PanicReductionValue number
bodyDamage.setPanicReductionValue = function(self, PanicReductionValue)
    CharacterStats.getOrCreate(self:getParentChar()).panicReduction = PanicReductionValue
end