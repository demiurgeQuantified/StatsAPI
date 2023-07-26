local Stats = require("StatsAPI/Globals").Stats

local OverTimeEffects = {}

---@type table<StatIdentifier, fun(stats:CharacterStats, amount:number)>
OverTimeEffects.statSetters = {}
OverTimeEffects.statSetters[Stats.Thirst] = function(stats, amount)
    stats.javaStats:setThirst(stats.javaStats:getThirst() + amount)
end
OverTimeEffects.statSetters[Stats.Hunger] = function(stats, amount)
    stats.javaStats:setHunger(stats.javaStats:getHunger() + amount)
end
OverTimeEffects.statSetters[Stats.Panic] = function(stats, amount)
    stats.javaStats:setPanic(stats.javaStats:getPanic() + amount)
end
OverTimeEffects.statSetters[Stats.Stress] = function(stats, amount)
    stats.javaStats:setStress(stats.javaStats.stress + amount)
end
OverTimeEffects.statSetters[Stats.Fatigue] = function(stats, amount)
    stats.javaStats:setFatigue(stats.javaStats:getFatigue() + amount)
end
OverTimeEffects.statSetters[Stats.Boredom] = function(stats, amount)
    stats.bodyDamage:setBoredomLevel(stats.bodyDamage:getBoredomLevel() + amount)
end
OverTimeEffects.statSetters[Stats.Sadness] = function(stats, amount)
    stats.bodyDamage:setUnhappynessLevel(stats.bodyDamage:getUnhappynessLevel() + amount)
end

---@param stats CharacterStats
---@param stat StatIdentifier
---@param amount number
---@param duration number
OverTimeEffects.create = function(stats, stat, amount, duration)
    if not OverTimeEffects.statSetters[stat] then error("StatsAPI: Invalid stat identifier for OverTimeEffect") end
    
    ---@type OverTimeEffect
    local overTimeEffect = {}
    overTimeEffect.stat = stat
    overTimeEffect.timeRemaining = duration
    overTimeEffect.amount = amount
    
    table.insert(stats.overTimeEffects, overTimeEffect)
    return overTimeEffect
end

return OverTimeEffects