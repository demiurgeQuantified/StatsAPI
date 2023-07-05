local Math = require "StatsAPI/lib/Math"

local Globals = require "StatsAPI/Globals"
local StatsData = require "StatsAPI/StatsData"
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

Panic.getPanicReductionModifier = function(character, asleep)
    local modifier = 1
    
    if asleep then
        modifier = 2
    end
    
    return modifier
end

---@param character IsoPlayer
---@return number
Panic.getSurvivalReduction = function(character)
    local panicReduction = StatsData.getPlayerData(character).panicReduction
    local monthsSurvived = Math.floor(Globals.gameTime:getNightsSurvived() / 30)
    return panicReduction * Math.min(monthsSurvived, 5)
end

---@param character IsoPlayer
---@param stats Stats
---@param asleep boolean
Panic.updatePanic = function(character, stats, asleep)
    local statsData = StatsData.getPlayerData(character)
    
    local visibleZombies = stats:getNumVisibleZombies()
    local zombieChange = visibleZombies - statsData.oldNumZombiesVisible
    if zombieChange > 0 then
        Panic.increasePanic(character, stats, zombieChange)
    else
        Panic.reducePanic(character, stats, asleep)
    end
    
    statsData.oldNumZombiesVisible = visibleZombies
end

---@param character IsoPlayer
---@param stats Stats
---@param zombies int
Panic.increasePanic = function(character, stats, zombies)
    local panicChange = StatsData.getPlayerData(character).panicIncrease * Panic.getPanicMultiplier(character) * zombies
    
    stats:setPanic(Math.min(stats:getPanic() + panicChange, 100))
end

---@param character IsoPlayer
---@param stats Stats
---@param asleep boolean
Panic.reducePanic = function(character, stats, asleep)
    local panic = stats:getPanic()
    if panic > 0 then
        local panicReduction = StatsData.getPlayerData(character).panicReduction
        
        local panicChange = panicReduction * Globals.multiplier / 1.6 + Panic.getSurvivalReduction(character)
        panicChange = panicChange * Panic.getPanicReductionModifier(character)
    
        stats:setPanic(Math.max(panic - panicChange, 0))
    end
end

local bodyDamage = __classmetatables[BodyDamage.class].__index
local old_setPanicIncreaseValue = bodyDamage.setPanicIncreaseValue
local old_setPanicReductionValue = bodyDamage.setPanicReductionValue

---@param player IsoPlayer
Panic.disableVanillaPanic = function(player)
    local bodyDamage = player:getBodyDamage()
    old_setPanicIncreaseValue(bodyDamage, 0)
    old_setPanicReductionValue(bodyDamage, 0)
end

---@param self BodyDamage
---@param PanicIncreaseValue number
bodyDamage.setPanicIncreaseValue = function(self, PanicIncreaseValue)
    StatsData.getPlayerData(self:getParentChar()).panicIncrease = PanicIncreaseValue
end

---@param self BodyDamage
---@param PanicReductionValue number
bodyDamage.setPanicReductionValue = function(self, PanicReductionValue)
    StatsData.getPlayerData(self:getParentChar()).panicReduction = PanicReductionValue
end

return Panic