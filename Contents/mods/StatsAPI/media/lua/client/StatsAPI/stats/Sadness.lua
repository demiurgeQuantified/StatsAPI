local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

-- Unhappyness will be referred to as Sadness in the API
local Sadness = {}

-- these need to be zeroed so that the java sadness update doesn't do anything
-- TODO: these being per-character would be cool
Sadness.SadnessIncrease = ZomboidGlobals.UnhappinessIncrease
ZomboidGlobals.UnhappinessIncrease = 0

---@param self CharacterStats
Sadness.updateSadness = function(self)
    if self.reading then return end
    
    local sadnessChange = 0
    
    local boredLevel = self.luaMoodles.moodles.bored.level
    if boredLevel > 1 then
        sadnessChange = Sadness.SadnessIncrease * boredLevel
    end
    
    local stressLevel = self.luaMoodles.moodles.stress.level
    if stressLevel > 1 then
        sadnessChange = sadnessChange + Sadness.SadnessIncrease / 2 * stressLevel
    end
    
    if sadnessChange == 0 then return end
    
    sadnessChange = sadnessChange * Globals.multiplier
    
    self.bodyDamage:setUnhappynessLevel(Math.clamp(self.bodyDamage:getUnhappynessLevel() + sadnessChange, 0, 100))
end

return Sadness