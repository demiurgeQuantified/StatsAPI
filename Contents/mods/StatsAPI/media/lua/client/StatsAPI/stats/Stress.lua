local Globals = require "StatsAPI/Globals"
local Math = require "StatsAPI/lib/Math"

local Stress = {}

Stress.injuryStress = true
Stress.infectionStress = true

---@type table<string, number>
Stress.modChanges = {}

---@type WorldSoundManager
local worldSoundManager
Events.OnGameStart.Add(function()
    worldSoundManager = getWorldSoundManager()
end)

---@param character IsoGameCharacter
---@return number
Stress.getHealthStress = function(character)
    local stressChange = 0
    local bodyDamage = character:getBodyDamage()
    if Stress.injuryStress then
        if bodyDamage:getNumPartsBitten() > 0 then
            stressChange = stressChange + ZomboidGlobals.StressFromBiteOrScratch
        end
        if bodyDamage:getNumPartsScratched() > 0 then
            stressChange = stressChange + ZomboidGlobals.StressFromBiteOrScratch
        end
    end
    if Stress.infectionStress then
        if bodyDamage:isInfected() or bodyDamage:isIsFakeInfected() then
            stressChange = stressChange + ZomboidGlobals.StressFromBiteOrScratch
        end
    end
    return stressChange * Globals.delta
end

---@param character IsoGameCharacter
Stress.getTraitStress = function(character)
    local stressChange = 0
    if character:HasTrait("Hemophobic") then
        stressChange = stressChange + character:getTotalBlood() * ZomboidGlobals.StressFromHemophobic * (Globals.multiplier / 0.8) * Globals.deltaMinutesPerDay
    end
    return stressChange
end

Stress.getModdedStressChange = function()
    local stressChange = 0
    for _, modChange in pairs(Stress.modChanges) do
        stressChange = stressChange + modChange
    end
    return stressChange * Globals.gameWorldSecondsSinceLastUpdate
end

---@param self CharacterStats
Stress.updateStress = function(self)
    local stress = self.javaStats:getStress()
    stress = stress + worldSoundManager:getStressFromSounds(self.character:getX(), self.character:getY(), self.character:getZ()) * ZomboidGlobals.StressFromSoundsMultiplier
    stress = stress + Stress.getHealthStress(self.character)
    stress = stress + Stress.getTraitStress(self.character)
    stress = stress + Stress.getModdedStressChange()
    if not self.asleep then
        stress = stress - ZomboidGlobals.StressDecrease * Globals.delta
    end
    
    self.javaStats:setStress(Math.clamp(stress, 0, 1))
end

return Stress