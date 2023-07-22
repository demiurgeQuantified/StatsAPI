local Stats = require("StatsAPI/Globals").Stats

local OverTimeEffects = {}

---@type table<StatIdentifier, fun(stats:CharacterStats, amount:number)>
OverTimeEffects.statSetters = {}
OverTimeEffects.statSetters[Stats.Stress] = function(stats, amount)
    stats.javaStats:setStress(stats.javaStats:getStress() + amount)
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