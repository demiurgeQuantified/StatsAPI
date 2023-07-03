local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"
local StatsData = require "StatsAPI/StatsData"

local StatsAPI = {}
StatsAPI.Fatigue = require "StatsAPI/Fatigue"
StatsAPI.Hunger = require "StatsAPI/Hunger"
StatsAPI.Thirst = require "StatsAPI/Thirst"
StatsAPI.Stress = require "StatsAPI/Stress"
StatsAPI.Panic = require "StatsAPI/Panic"

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
    
    StatsAPI.Stress.updateStress(character, stats, asleep)
    StatsAPI.updateEndurance(character, stats, asleep)
    StatsAPI.Thirst.updateThirst(character, stats, asleep)
    StatsAPI.Fatigue.updateFatigue(character, stats, asleep)
    StatsAPI.Hunger.updateHunger(character, stats, asleep)
    StatsAPI.Panic.updatePanic(character, stats, asleep)
    StatsAPI.updateFitness(character, stats)
    
    if not asleep then
        StatsAPI.updateBoredom(character, stats)
    else
        StatsAPI.Fatigue.updateSleep(character, stats)
    end
end

---@param playerIndex int
---@param player IsoPlayer
StatsAPI.preparePlayer = function(playerIndex, player)
    StatsData.createPlayerData(player)
    StatsAPI.Panic.disableVanillaPanic(player)
end

Events.OnCreatePlayer.Add(StatsAPI.preparePlayer)


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

---Toggles whether being injured causes characters to gain stress.
---@param injuryStress boolean Should injuries cause stress?
StatsAPI.setStressFromInjuries = function(injuryStress)
    StatsAPI.Stress.injuryStress = injuryStress
end

---Toggles whether being infected with the Knox virus causes characters to gain stress.
---@param infectionStress boolean Should infection cause stress?
StatsAPI.setStressFromInfection = function(infectionStress)
    StatsAPI.Stress.infectionStress = infectionStress
end

Hook.CalculateStats.Add(StatsAPI.CalculateStats)

return StatsAPI