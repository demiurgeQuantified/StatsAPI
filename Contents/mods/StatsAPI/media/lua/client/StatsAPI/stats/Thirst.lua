local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Thirst = {}
Thirst.thirstMultipliers = {}

---@type table<string, table<function,number>>
Thirst.modChanges = {}

---@param data StatsData
Thirst.getModdedThirstChange = function(data)
    local thirstChange = 0
    for _, modChange in pairs(Thirst.modChanges) do
        thirstChange = thirstChange + modChange[1](data) * modChange[2]
    end
    return thirstChange * Globals.gameWorldSecondsSinceLastUpdate
end

---@param character IsoGameCharacter
Thirst.getThirstMultiplier = function(character)
    local thirstMultiplier = 1
    
    for trait, multiplier in pairs(Thirst.thirstMultipliers) do
        if character:HasTrait(trait) then
            thirstMultiplier = thirstMultiplier * multiplier
        end
    end
    
    return thirstMultiplier
end

---@param self CharacterStats
Thirst.updateThirst = function(self)
    if not self.character:isGhostMode() then
        local thirstMultiplier = self.thirstMultiplier * Globals.statsDecreaseMultiplier * Globals.delta
        if not self.asleep then
            if self.character:isRunning() then
                thirstMultiplier = thirstMultiplier * 1.2
            end
            self.stats.thirst = self.stats.thirst + ZomboidGlobals.ThirstIncrease * self.character:getThirstMultiplier() * thirstMultiplier
        else
            self.stats.thirst = self.stats.thirst + ZomboidGlobals.ThirstSleepingIncrease * thirstMultiplier
        end
        self.stats.thirst = self.stats.thirst + Thirst.getModdedThirstChange() * self.character:getThirstMultiplier() * thirstMultiplier
    end
    self.character:autoDrink()
end

return Thirst