local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local StatsData = require "StatsAPI/StatsData"

local Hunger = {}
Hunger.appetiteMultipliers = {}

---@param character IsoGameCharacter
---@return number
Hunger.getAppetiteMultiplier = function(character)
    local appetite = 1 - StatsData.getPlayerData(character).stats:getHunger()
    
    for trait, multiplier in pairs(Hunger.appetiteMultipliers) do
        if character:HasTrait(trait) then
            appetite = appetite * multiplier
        end
    end
    
    return appetite
end

---@param character IsoPlayer
Hunger.updateHunger = function(character)
    local playerData = StatsData.getPlayerData(character)
    local stats = playerData.stats
    
    local appetiteMultiplier = Hunger.getAppetiteMultiplier(character)
    local wellFed = character:getMoodleLevel(MoodleType.FoodEaten) ~= 0
    local hungerChange = 0
    
    if not playerData.asleep then
        if not (character:isRunning() or character:isPlayerMoving()) and not character:isCurrentState(SwipeStatePlayer.instance()) then
            if wellFed then
                hungerChange = ZomboidGlobals.HungerIncreaseWhenWellFed
            else
                hungerChange = ZomboidGlobals.HungerIncrease * appetiteMultiplier
            end
        elseif wellFed then
            hungerChange = ZomboidGlobals.HungerIncreaseWhenExercise / 3 * appetiteMultiplier
        else
            hungerChange = ZomboidGlobals.HungerIncreaseWhenExercise * appetiteMultiplier
        end
        hungerChange = hungerChange * Globals.statsDecreaseMultiplier * character:getHungerMultiplier() * Globals.delta
    else
        hungerChange = ZomboidGlobals.HungerIncreaseWhileAsleep * Globals.statsDecreaseMultiplier * character:getHungerMultiplier() * Globals.delta
        if wellFed then
            hungerChange = hungerChange * appetiteMultiplier
        else
            -- the stats decrease multiplier getting added twice is probably a mistake, but i don't want to change vanilla behaviour
            -- plus this multiplies by zero by default anyway
            hungerChange = hungerChange * ZomboidGlobals.HungerIncreaseWhenWellFed * Globals.statsDecreaseMultiplier
        end
    end
    
    stats:setHunger(Math.min(stats:getHunger() + hungerChange, 1))
end

return Hunger