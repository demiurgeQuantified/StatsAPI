local Globals = require "StatsAPI/Globals"
local Math = require "StatsAPI/lib/Math"

local Stress = {}

Stress.injuryStress = true
Stress.infectionStress = true

---@type table<string, table<function,number>>
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
---@param data StatsData
Stress.getModdedStressChange = function(data)
    local stressChange = 0
    for _, modChange in pairs(Stress.modChanges) do
        stressChange = stressChange + modChange[1](data) * modChange[2]
    end
    return stressChange * Globals.gameWorldSecondsSinceLastUpdate
end

---@param character IsoPlayer
---@param stats Stats
---@param asleep boolean
Stress.updateStress = function(character, stats, asleep)
    local stress = stats:getStress()
    stress = stress + worldSoundManager:getStressFromSounds(character:getX(), character:getY(), character:getZ()) * ZomboidGlobals.StressFromSoundsMultiplier
    stress = stress + Stress.getHealthStress(character)
    stress = stress + Stress.getTraitStress(character)
    stress = stress + Stress.getModdedStressChange()
    if not asleep then
        stress = stress - ZomboidGlobals.StressDecrease * Globals.delta
    end
    
    stats:setStress(Math.clamp(stress, 0, 1))
end

return Stress