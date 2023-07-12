local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"
local StatsData = require "StatsAPI/StatsData"

local StatsAPI = {}
StatsAPI.Fatigue = require "StatsAPI/stats/Fatigue"
StatsAPI.Hunger = require "StatsAPI/stats/Hunger"
StatsAPI.Thirst = require "StatsAPI/stats/Thirst"
StatsAPI.Stress = require "StatsAPI/stats/Stress"
StatsAPI.Panic = require "StatsAPI/stats/Panic"

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
    
    if asleep then
        StatsAPI.Fatigue.updateSleep(character, stats)
    end
end

Hook.CalculateStats.Add(StatsAPI.CalculateStats)

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

---Adds a panic multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The panic multiplier to give characters with the trait
StatsAPI.addTraitPanicModifier = function(trait, modifier)
    StatsAPI.Panic.traitMultipliers[trait] = modifier
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

---Adds a function that has to return a change in stress, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addStressChangeDaily = function(sourceName, dailyChange)
    StatsAPI.Stress.modChanges[sourceName] = {dailyChange,1 / 86400 / 100}
end

---Adds a function that has to return a change in stress, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addStressChangeHourly = function(sourceName, hourlyChange)
    StatsAPI.Stress.modChanges[sourceName] = {hourlyChange,1 / 86400 / 100}
end

---Removes a previously added change to stress
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeStressChange = function(sourceName)
    StatsAPI.Stress.modChanges[sourceName] = nil
end

---Adds a function that has to return a change in hunger, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addHungerChangeDaily = function(sourceName, dailyChange)
    StatsAPI.Hunger.modChanges[sourceName] = {dailyChange, 1 / 86400 / 100}
end

---Adds a function that has to return a change in hunger, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addHungerChangeHourly = function(sourceName, hourlyChange)
    StatsAPI.Hunger.modChanges[sourceName] = {hourlyChange, 1/ 3600 / 100}
end

---Removes a previously added change to hunger
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeHungerChange = function(sourceName)
    StatsAPI.Hunger.modChanges[sourceName] = nil
end

---Adds a function that has to return a change in thurst, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addThirstChangeDaily = function(sourceName, dailyChange)
    StatsAPI.Thirst.modChanges[sourceName] = {dailyChange, 1 / 86400 / 100}
end

---Adds a function that has to return a change in thirst, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addThirstChangeHourly = function(sourceName, hourlyChange)
    StatsAPI.Thirst.modChanges[sourceName] = {hourlyChange, 1/ 3600 / 100}
end

---Removes a previously added change to fatigue
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeThirstChange = function(sourceName)
    StatsAPI.Thirst.modChanges[sourceName] = nil
end

---Prevents the vanilla trait effects from being added. Must be called before OnGameBoot or it will have no effect.
StatsAPI.disableVanillaTraits = function()
    local Vanilla = require "StatsAPI/vanilla/VanillaTraits"
    Vanilla.wantVanilla = false
end

return StatsAPI