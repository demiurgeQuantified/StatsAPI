local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local StatsData = require "StatsAPI/StatsData"

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

---@param character IsoPlayer
Thirst.updateThirst = function(character)
    local playerData = StatsData.getPlayerData(character)
    local stats = playerData.stats
    
    if not character:isGhostMode() then
        local thirstMultiplier = Thirst.getThirstMultiplier(character) * Globals.statsDecreaseMultiplier * Globals.delta
        local thirst = stats:getThirst()
        if not playerData.asleep then
            if character:isRunning() then
                thirstMultiplier = thirstMultiplier * 1.2
            end
            thirst = thirst + ZomboidGlobals.ThirstIncrease * character:getThirstMultiplier() * thirstMultiplier
        else
            thirst = thirst + ZomboidGlobals.ThirstSleepingIncrease * thirstMultiplier
        end
        stats:setThirst(Math.min(thirst, 1))
    end
    character:autoDrink()
end

return Thirst