-- Imports the API module into a local variable so that we can call its functions from outside of it.
local StatsAPI = require "StatsAPI/StatsAPI"

-- Create our module.
-- You don't need to use modules in your own mod, but modules are the industry standard way of writing lua.
local VanillaTraits = {}

VanillaTraits.wantVanilla = true

-- Creates a function that adds our modifiers when it's called
VanillaTraits.addTraitModifiers = function()
    if VanillaTraits.wantVanilla then -- Checks if the Vanilla traits have been disabled by another mod before running.
        -- Add our trait modifiers. You can do this alongside the creation of your traits.
        StatsAPI.addTraitHungerModifier("HeartyAppitite", 1.5)
        StatsAPI.addTraitHungerModifier("LightEater", 0.75)
        
        StatsAPI.addTraitThirstModifier("HighThirst", 2)
        StatsAPI.addTraitThirstModifier("LowThirst", 0.5)
        
        StatsAPI.addTraitFatigueModifier("NeedsLessSleep", 0.7, 0.75)
        StatsAPI.addTraitFatigueModifier("NeedsMoreSleep", 1.3, 1.18)
        
        StatsAPI.addTraitSleepDurationModifier("Insomniac", 0.5)
        StatsAPI.addTraitSleepDurationModifier("NeedsLessSleep", 0.75)
        StatsAPI.addTraitSleepDurationModifier("NeedsMoreSleep", 1.18)
        
        StatsAPI.addTraitSleepModifier("NightOwl", 1.4)
        StatsAPI.addTraitSleepModifier("Insomniac", 0.5)
        
        StatsAPI.addTraitPanicModifier("Cowardly", 2)
        StatsAPI.addTraitPanicModifier("Brave", 0.3)
        StatsAPI.addTraitPanicModifier("Desensitized", 0)
    
        -- while these weight modifiers are technically defined in vanilla, an oversight causes them not to be applied
        --StatsAPI.addCarryWeightModifier("Strong", 1.5)
        --StatsAPI.addCarryWeightModifier("Weak", 0.75)
        --StatsAPI.addCarryWeightModifier("Feeble", 0.9)
        --StatsAPI.addCarryWeightModifier("Stout", 1.25)
    end
end

-- Delays the code until the game has reached the main menu. Not strictly necessary, but traits usually aren't created
-- until then either.
Events.OnGameBoot.Add(VanillaTraits.addTraitModifiers)

return VanillaTraits