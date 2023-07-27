local Math = require "StatsAPI/lib/Math"

local CarryWeight = {}

CarryWeight.maxWeightMultipliers = {}

---@param character IsoGameCharacter
---@return number
CarryWeight.getMaxWeightDelta = function(character)
    local maxWeightDelta = 1
    
    for trait, multiplier in pairs(CarryWeight.maxWeightMultipliers) do
        if character:HasTrait(trait) then
            maxWeightDelta = maxWeightDelta * multiplier
        end
    end
    
    return maxWeightDelta
end

---@param stats CharacterStats
---@return number
CarryWeight.getCarryWeightModifier = function(stats)
    local carryModifier = stats.staticCarryMod
    
    local hungryLevel = stats.moodles:getMoodleLevel(MoodleType.Hungry)
    if hungryLevel >= 2 then
        carryModifier = carryModifier - 1
        if hungryLevel >= 3 then
            carryModifier = carryModifier - 1
        end
    end
    
    local thirstLevel = stats.moodles:getMoodleLevel(MoodleType.Thirst)
    if thirstLevel >= 2 then
        carryModifier = carryModifier - 1
        if thirstLevel >= 3 then
            carryModifier = carryModifier - 1
        end
    end
    
    local sicknessLevel = stats.moodles:getMoodleLevel(MoodleType.Sick)
    if sicknessLevel >= 2 then
        carryModifier = carryModifier - (sicknessLevel - 1)
    end
    
    if stats.moodles:getMoodleLevel(MoodleType.Bleeding) >= 2 then
        carryModifier = carryModifier - 1
    end
    
    local injuredLevel = stats.moodles:getMoodleLevel(MoodleType.Injured)
    if injuredLevel >= 2 then
        carryModifier = carryModifier - (injuredLevel - 1)
    end
    
    if stats.wellFed then
        carryModifier = carryModifier + 2
    end
    
    return carryModifier
end

---@param self CharacterStats
CarryWeight.updateCarryWeight = function(self)
    -- TODO: caching these would be much cheaper, they don't even change in vanilla
    local carryWeight = self.character:getMaxWeightBase() * self.character:getWeightMod() + CarryWeight.getCarryWeightModifier(self)
    carryWeight = carryWeight * self.maxWeightDelta
    
    self.carryWeight = Math.max(carryWeight, 0)
    self.character:setMaxWeight(self.carryWeight)
end

return CarryWeight