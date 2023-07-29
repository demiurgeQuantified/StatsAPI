local Globals = require "StatsAPI/Globals"
local Math = require "StatsAPI/lib/Math"

local Boredom = {}

-- these need to be zeroed so that the java boredom update doesn't do anything
-- TODO: these being per-character would be cool
Boredom.BoredomIncrease = ZomboidGlobals.BoredomIncrease
Boredom.BoredomDecrease = ZomboidGlobals.BoredomDecrease
ZomboidGlobals.BoredomIncrease = 0
ZomboidGlobals.BoredomDecrease = 0

---@param self CharacterStats
Boredom.getIdleBoredom = function(self)
    local boredomChange = 0
    
    if self.reading then
        boredomChange = boredomChange + Boredom.BoredomIncrease / 5
    else
        boredomChange = boredomChange + Boredom.BoredomIncrease
    end
    
    return boredomChange
end

---@param self CharacterStats
Boredom.updateBoredom = function(self)
    if self.asleep then return end
    
    if self.stats.panic > 5 then
        self.stats.boredom = 0
        return
    end
    
    local boredomChange
    
    if self.character:isInARoom() then
        boredomChange = self:getIdleBoredom()
        if self.character:isSpeaking() then
            boredomChange = boredomChange - Boredom.BoredomDecrease
        end
        
        if self.character:getNumSurvivorsInVicinity() > 0 then
            boredomChange = boredomChange - Boredom.BoredomDecrease * 0.1
        end
    elseif self.vehicle then
        if Math.abs(self.vehicle:getCurrentSpeedKmHour()) <= 0.1 then
            boredomChange = self:getIdleBoredom()
        else
            boredomChange = -Boredom.BoredomDecrease * 0.5
        end
    else
        boredomChange = -Boredom.BoredomDecrease * 0.1
    end
    
    if self.javaStats:getDrunkenness() > 20 then
        boredomChange = boredomChange - Boredom.BoredomDecrease * 2
    end
    
    self.stats.boredom = self.stats.boredom + boredomChange * Globals.multiplier
end

return Boredom