local Math = require "StatsAPI/lib/Math"

local Globals = require "StatsAPI/Globals"
local Panic = {}

Panic.traitMultipliers = {}

---@param character IsoGameCharacter
Panic.getPanicMultiplier = function(character)
    local multiplier = 1
    
    if character:getBetaEffect() > 0 then
        multiplier = Math.clamp(multiplier - character:getBetaDelta(), 0, 1)
    end
    
    if character:getVehicle() then
        multiplier = multiplier * 0.5
    end
    
    return multiplier
end

---@param character IsoGameCharacter
---@return number
Panic.getTraitMultiplier = function(character)
    local panicMultiplier = 1
    
    for trait, multiplier in pairs(Panic.traitMultipliers) do
        if character:HasTrait(trait) then
            panicMultiplier = panicMultiplier * multiplier
        end
    end
    
    return panicMultiplier
end

---@param stats CharacterStats
Panic.getPanicReductionModifier = function(stats)
    return stats.asleep and 2 or 1
end

---@param stats CharacterStats
---@return number
Panic.getSurvivalReduction = function(stats)
    local panicReduction = stats.panicReduction
    local monthsSurvived = Math.floor(Globals.gameTime:getNightsSurvived() / 30)
    return panicReduction * Math.min(monthsSurvived, 5)
end

---@param self CharacterStats
Panic.updatePanic = function(self)
    local visibleZombies = self.javaStats:getNumVisibleZombies()
    local zombieChange = visibleZombies - self.oldNumZombiesVisible
    if zombieChange > 0 then
        Panic.increasePanic(self, zombieChange)
    else
        Panic.reducePanic(self)
    end
    
    self.oldNumZombiesVisible = visibleZombies
end

---@param self CharacterStats
---@param zombies int
Panic.increasePanic = function(self, zombies)
    local panicChange = self.panicIncrease * Panic.getPanicMultiplier(self.character) * zombies
    
    self.javaStats:setPanic(Math.min(self.javaStats:getPanic() + panicChange, 100))
end

---@param self CharacterStats
Panic.reducePanic = function(self)
    local panic = self.javaStats:getPanic()
    if panic > 0 then
        local panicReduction = self.panicReduction
        
        local panicChange = panicReduction * Globals.multiplier / 1.6 + Panic.getSurvivalReduction(self)
        panicChange = panicChange * Panic.getPanicReductionModifier(self)
    
        self.javaStats:setPanic(Math.max(panic - panicChange, 0))
    end
end

-- these will get overwritten by CharacterStats, so we need to cache the original values now
local bodyDamage = __classmetatables[BodyDamage.class].__index
local setPanicIncreaseValue = bodyDamage.setPanicIncreaseValue
local setPanicDecreaseValue = bodyDamage.setPanicReductionValue

---@param player IsoPlayer
Panic.disableVanillaPanic = function(player)
    local bodyDamage = player:getBodyDamage()
    setPanicIncreaseValue(bodyDamage, 0)
    setPanicDecreaseValue(bodyDamage, 0)
end

return Panic