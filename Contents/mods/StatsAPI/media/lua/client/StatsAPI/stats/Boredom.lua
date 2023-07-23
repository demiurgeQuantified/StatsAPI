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
    
    if self.panic > 5 then
        self.bodyDamage:setBoredomLevel(0)
        return
    end
    
    local boredomChange
    
    if self.character:isInARoom() then
        boredomChange = Boredom.getIdleBoredom()
        if self.character:isSpeaking() then -- and not self.character.callOut -- we need a field api to access this
            boredomChange = boredomChange - Boredom.BoredomDecrease
        end
        
        if self.character:getNumSurvivorsInVicinity() > 0 then
            boredomChange = boredomChange - Boredom.BoredomDecrease * 0.10000000149011612
        end
    elseif self.vehicle then
        if Math.abs(self.vehicle:getCurrentSpeedKmHour() <= 0.1) then
            boredomChange = Boredom.getIdleBoredom()
        else
            boredomChange = -Boredom.BoredomDecrease * 0.5
        end
    else
        boredomChange = -Boredom.BoredomDecrease * 0.10000000149011612
    end
    
    if self.javaStats:getDrunkenness() > 20 then
        boredomChange = boredomChange - Boredom.BoredomDecrease * 2
    end

    boredomChange = boredomChange * Globals.multiplier
    
    self.bodyDamage:setBoredomLevel(Math.clamp(self.bodyDamage:getBoredomLevel() + boredomChange, 0, 100))
end

return Boredom