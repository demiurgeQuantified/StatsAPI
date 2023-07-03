local Math = require "StatsAPI/lib/Math"

local Globals = require "StatsAPI/Globals"
local StatsData = require "StatsAPI/StatsData"
local Panic = {}

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
    local panicChange = 1
    
    if character:getVehicle() then
        panicChange = panicChange * 0.5
    end
    
    if character:getBetaEffect() > 0 then
        panicChange = Math.clamp(panicChange - character:getBetaDelta(), 0, 1)
    end
    
    -- TODO: this should obviously be done with a table
    if character:HasTrait("Cowardly") then
        panicChange = panicChange * 2
    end
    if character:HasTrait("Brave") then
        panicChange = panicChange * 0.3
    end
    if character:HasTrait("Desensitized") then
        panicChange = 0
    end
    
    panicChange = panicChange * StatsData.getPlayerData(character).panicIncrease * zombies
    
    stats:setPanic(Math.min(stats:getPanic() + panicChange, 100))
end

---@param character IsoPlayer
---@param stats Stats
---@param asleep boolean
Panic.reducePanic = function(character, stats, asleep)
    local panic = stats:getPanic()
    if panic > 0 then
        local panicReduction = StatsData.getPlayerData(character).panicReduction
        local monthsSurvived = Math.min(Math.floor(Globals.gameTime:getNightsSurvived() / 30), 5)
        
        local panicChange = panicReduction * Globals.multiplier / 1.6 + panicReduction * monthsSurvived
        if asleep then panicChange = panicChange * 2 end
    
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