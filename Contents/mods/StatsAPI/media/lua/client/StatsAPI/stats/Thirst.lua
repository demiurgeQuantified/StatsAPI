local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Thirst = {}
Thirst.thirstMultipliers = {}

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
        local thirst = self.javaStats:getThirst()
        if not self.asleep then
            if self.character:isRunning() then
                thirstMultiplier = thirstMultiplier * 1.2
            end
            thirst = thirst + ZomboidGlobals.ThirstIncrease * self.character:getThirstMultiplier() * thirstMultiplier
        else
            thirst = thirst + ZomboidGlobals.ThirstSleepingIncrease * thirstMultiplier
        end
        self.javaStats:setThirst(Math.min(thirst, 1))
    end
    self.character:autoDrink()
end

return Thirst