local getStats = __classmetatables[IsoGameCharacter.class].__index.getStats


local StatsData = require "StatsAPI/StatsData"
local OverTimeEffects = {}

---@type table<string, fun(character:IsoGameCharacter, amount:number)>
OverTimeEffects.statSetters = {}
OverTimeEffects.statSetters.stress = function(character, amount)
    local stats = getStats(character)
    stats:setStress(stats:getStress() + amount)
end

---@param character IsoPlayer
---@param stat string
---@param amount number
---@param duration number
OverTimeEffects.create = function(character, stat, amount, duration)
    if not OverTimeEffects.statSetters[stat] then return end
    
    local time = getTimestampMs()
    ---@type OverTimeEffect
    local overTimeEffect = {}
    overTimeEffect.start = time
    overTimeEffect.endTime = time + duration
    overTimeEffect.amount = amount / 0.8
    overTimeEffect.stat = stat
    
    --TODO: there isn't any loading logic for these yet
    table.insert(StatsData.getPlayerData(character).overTimeEffects, overTimeEffect)
    return overTimeEffect
end

OverTimeEffects.OnTick = function()
    local time = getTimestampMs()
    for i = 0, 3 do
        local player = getSpecificPlayer(i)
        if player then
            local effects = StatsData.getPlayerData(player).overTimeEffects
            for j = 1, #effects do
                local effect = effects[j]
                OverTimeEffects.statSetters[effect.stat](player, effect.amount * GameTime:getMultiplier())
                if time > effect.endTime then
                    table.remove(effects, j)
                end
            end
        end
    end
end

Events.OnTick.Add(OverTimeEffects.OnTick)

return OverTimeEffects