local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Hunger = {}
Hunger.appetiteMultipliers = {}

---@param character IsoGameCharacter
---@return number
Hunger.getAppetiteMultiplier = function(character)
    local appetite = 1
    
    for trait, multiplier in pairs(Hunger.appetiteMultipliers) do
        if character:HasTrait(trait) then
            appetite = appetite * multiplier
        end
    end
    
    return appetite
end

---@param self CharacterStats
Hunger.updateHunger = function(self)
    local hunger = self.javaStats:getHunger()
    local appetiteMultiplier = (1 - hunger) * self.hungerMultiplier
    local hungerChange = 0
    
    if not self.asleep then
        if not (self.character:isRunning() or self.character:isPlayerMoving()) and not self.character:isCurrentState(SwipeStatePlayer.instance()) then
            if self.wellFed then
                hungerChange = ZomboidGlobals.HungerIncreaseWhenWellFed
            else
                hungerChange = ZomboidGlobals.HungerIncrease * appetiteMultiplier
            end
        elseif self.wellFed then
            hungerChange = ZomboidGlobals.HungerIncreaseWhenExercise / 3 * appetiteMultiplier
        else
            hungerChange = ZomboidGlobals.HungerIncreaseWhenExercise * appetiteMultiplier
        end
        hungerChange = hungerChange * Globals.statsDecreaseMultiplier * self.character:getHungerMultiplier() * Globals.delta
    else
        hungerChange = ZomboidGlobals.HungerIncreaseWhileAsleep * Globals.statsDecreaseMultiplier * self.character:getHungerMultiplier() * Globals.delta
        if self.wellFed then
            hungerChange = hungerChange * appetiteMultiplier
        else
            -- the stats decrease multiplier getting added twice is probably a mistake, but i don't want to change vanilla behaviour
            -- plus this multiplies by zero by default anyway
            hungerChange = hungerChange * ZomboidGlobals.HungerIncreaseWhenWellFed * Globals.statsDecreaseMultiplier
        end
    end
    
    self.javaStats:setHunger(Math.min(hunger + hungerChange, 1))
end

return Hunger