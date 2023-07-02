local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

---@type WorldSoundManager
local worldSoundManager
Events.OnGameStart.Add(function()
    worldSoundManager = getWorldSoundManager()
end)

local StatsAPI = {}
StatsAPI.Fatigue = require "StatsAPI/Fatigue"
StatsAPI.Hunger = require "StatsAPI/Hunger"
StatsAPI.Thirst = require "StatsAPI/Thirst"

---@param character IsoGameCharacter
---@param stats Stats
---@param asleep boolean
StatsAPI.updateEndurance = function(character, stats, asleep)
    if character:isUnlimitedEndurance() then
        stats:setEndurance(1)
        return
    end
    
    local endurance = stats:getEndurance()
    
    if asleep then
        local enduranceMultiplier = 2
        if IsoPlayer.allPlayersAsleep() then
            enduranceMultiplier = enduranceMultiplier * Globals.deltaMinutesPerDay
        end
        endurance = endurance + ZomboidGlobals.ImobileEnduranceIncrease * Globals.sandboxOptions:getEnduranceRegenMultiplier() * character:getRecoveryMod() * Globals.multiplier * enduranceMultiplier
    end
    
    stats:setEndurance(Math.clamp(endurance, 0, 1))
end

---@param character IsoPlayer
---@param stats Stats
---@param asleep boolean
StatsAPI.updateStress = function(character, stats, asleep)
    if stats:getPanic() > 100 then
        stats:setPanic(100)
    end
    
    local stress = stats:getStress()
    stress = stress + worldSoundManager:getStressFromSounds(character:getX(), character:getY(), character:getZ()) * ZomboidGlobals.StressFromSoundsMultiplier
    
    local bodyDamage = character:getBodyDamage()
    if bodyDamage:getNumPartsBitten() > 0 then
        stress = stress + ZomboidGlobals.StressFromBiteOrScratch * Globals.delta
    end
    if bodyDamage:getNumPartsScratched() > 0 then
        stress = stress + ZomboidGlobals.StressFromBiteOrScratch * Globals.delta
    end
    if bodyDamage:isInfected() or bodyDamage:isIsFakeInfected() then
        stress = stress + ZomboidGlobals.StressFromBiteOrScratch * Globals.delta
    end
    
    if character:HasTrait("Hemophobic") then
        stress = stress + character:getTotalBlood() * ZomboidGlobals.StressFromHemophobic * (Globals.multiplier / 0.8) * Globals.deltaMinutesPerDay
    end
    
    if not asleep then
        stress = stress - ZomboidGlobals.StressDecrease * Globals.delta
    end
    
    stats:setStress(Math.clamp(stress, 0, 1))
end

---@param character IsoPlayer
---@param stats Stats
StatsAPI.updateFitness = function(character, stats)
    stats:setFitness(character:getPerkLevel(Perks.Fitness) / 5 - 1)
end

---@param character IsoGameCharacter
---@param stats Stats
StatsAPI.updateBoredom = function(character, stats)
    if not character:isReading() then
        local boredomChange = 0
        local square = character:getSquare()
        local lastSquare = character:getLastSquare()
        if square == lastSquare then
            boredomChange = boredomChange + 0.0013
        end
        if square and lastSquare then -- squares can be nil while falling
            local room = square:getRoom()
            if room and room == lastSquare:getRoom() then
                boredomChange = boredomChange + 0.00135
            end
        end
        stats:setBoredom(Math.min(stats:getBoredom() + boredomChange * Globals.delta, 1))
    end
end

---@param character IsoPlayer
StatsAPI.CalculateStats = function(character)
    local stats = character:getStats()
    local asleep = character:isAsleep()
    
    StatsAPI.updateStress(character, stats, asleep)
    StatsAPI.updateEndurance(character, stats, asleep)
    StatsAPI.Thirst.updateThirst(character, stats, asleep)
    StatsAPI.Fatigue.updateFatigue(character, stats, asleep)
    StatsAPI.Hunger.updateHunger(character, stats, asleep)
    StatsAPI.updateFitness(character, stats)
    
    if not asleep then
        StatsAPI.updateBoredom(character, stats)
    else
        StatsAPI.Fatigue.updateSleep(character, stats)
    end
end



---Adds a fatigue multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param awakeModifier number|nil The fatigue multiplier to give characters with the trait while they are awake
---@param asleepModifier number|nil The fatigue multiplier to give characters with the trait while they are asleep
StatsAPI.addTraitFatigueModifier = function(trait, awakeModifier, asleepModifier)
    StatsAPI.Fatigue.fatigueRate.asleep[trait] = awakeModifier
    StatsAPI.Fatigue.fatigueRate.asleep[trait] = asleepModifier
end

---Adds a sleeping efficiency multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The sleeping efficiency multiplier to give characters with the trait
StatsAPI.addTraitSleepModifier = function(trait, modifier)
    StatsAPI.Fatigue.sleepEfficiency[trait] = modifier
end

---Adds a hunger multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The hunger multiplier to give characters with the trait
StatsAPI.addTraitHungerModifier = function(trait, modifier)
    StatsAPI.Hunger.appetiteMultipliers[trait] = modifier
end

---Adds a thirst multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The thirst multiplier to give characters with the trait
StatsAPI.addTraitThirstModifier = function(trait, modifier)
    StatsAPI.Thirst.thirstMultipliers[trait] = modifier
end

Hook.CalculateStats.Add(StatsAPI.CalculateStats)

return StatsAPI