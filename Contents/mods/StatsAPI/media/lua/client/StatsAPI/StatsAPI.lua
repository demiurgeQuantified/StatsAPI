local CharacterStats = require "StatsAPI/CharacterStats"
local OverTimeEffects = require "StatsAPI/OverTimeEffects"

local StatsAPI = {}
StatsAPI.Fatigue = require "StatsAPI/stats/Fatigue"
StatsAPI.Hunger = require "StatsAPI/stats/Hunger"
StatsAPI.Thirst = require "StatsAPI/stats/Thirst"
StatsAPI.Stress = require "StatsAPI/stats/Stress"
StatsAPI.Panic = require "StatsAPI/stats/Panic"

---@param character IsoPlayer
StatsAPI.CalculateStats = function(character)
    CharacterStats.getOrCreate(character):CalculateStats()
end

Hook.CalculateStats.Add(StatsAPI.CalculateStats)

---@param playerIndex int
---@param player IsoPlayer
StatsAPI.preparePlayer = function(playerIndex, player)
    StatsAPI.Panic.disableVanillaPanic(player)
end

Events.OnCreatePlayer.Add(StatsAPI.preparePlayer)


---Adds a fatigue multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param awakeModifier number|nil The fatigue multiplier to give characters with the trait while they are awake
---@param asleepModifier number|nil The fatigue multiplier to give characters with the trait while they are asleep
StatsAPI.addTraitFatigueModifier = function(trait, awakeModifier, asleepModifier)
    StatsAPI.Fatigue.fatigueRate.awake[trait] = awakeModifier
    StatsAPI.Fatigue.fatigueRate.asleep[trait] = asleepModifier
end

---Adds a sleeping efficiency multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The sleeping efficiency multiplier to give characters with the trait
StatsAPI.addTraitSleepModifier = function(trait, modifier)
    StatsAPI.Fatigue.sleepEfficiency[trait] = modifier
end

---Adds a sleep duration multiplier to apply to characters who have the given trait.
StatsAPI.addTraitSleepDurationModifier = function(trait, modifier)
    StatsAPI.Fatigue.sleepLength[trait] = modifier
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


--TODO: add a bunch of these for different time formats
---@param character IsoGameCharacter
---@param stat string
---@param total number
---@param time number
StatsAPI.addStatOverTime = function(character, stat, total, time)
    local effect = OverTimeEffects.create(character, stat, total / time, time)
    if not effect then
        error("StatsAPI: Attempted to create OverTimeEffect for unknown stat " .. tostring(stat), 2)
    end
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

---Adds a constant change to stress
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addStressChangeDaily = function(sourceName, dailyChange)
    StatsAPI.Stress.modChanges[sourceName] = dailyChange / 86400 / 100
end

---Adds a constant change to stress
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addStressChangeHourly = function(sourceName, hourlyChange)
    StatsAPI.Stress.modChanges[sourceName] = hourlyChange / 3600 / 100
end

---Adds a constant change to stress, the cause being whichever the mod maker wishes
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeStressChange = function(sourceName)
    StatsAPI.Stress.modChanges[sourceName] = nil
end

---Prevents the vanilla trait effects from being added. Must be called before OnGameBoot or it will have no effect.
StatsAPI.disableVanillaTraits = function()
    local Vanilla = require "StatsAPI/vanilla/VanillaTraits"
    Vanilla.wantVanilla = false
end

---Returns the CharacterStats object for a character
---@param character IsoGameCharacter
---@return CharacterStats|nil
StatsAPI.getCharacterStats = function(character)
    return CharacterStats.get(character)
end

---Returns the CharacterStats object for the local player index
---@param playerNum int
---@return CharacterStats|nil
StatsAPI.getPlayerStats = function(playerNum)
    local player = getSpecificPlayer(playerNum)
    return CharacterStats.get(player)
end

return StatsAPI