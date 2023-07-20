local Math = require "StatsAPI/lib/Math"
local bClient = isClient()

local Globals = require "StatsAPI/Globals"
local StatsData = require "StatsAPI/StatsData"
local Fatigue = {}


Fatigue.bedEfficiency = {goodBed = 1.1, badBed = 0.9, floor = 0.6}
Fatigue.fatigueRate = {awake = {}, asleep = {}}
Fatigue.sleepEfficiency = {}

---@param character IsoGameCharacter
---@return number
Fatigue.getFatigueRate = function(character)
    local fatigueRates = StatsData.getPlayerData(character) and Fatigue.fatigueRate.asleep or Fatigue.fatigueRate.awake
    
    local fatigueRate = 1
    for trait, multiplier in pairs(fatigueRates) do
        if character:HasTrait(trait) then
            fatigueRate = fatigueRate * multiplier
        end
    end
    
    return fatigueRate
end

---@param character IsoGameCharacter
---@return number
Fatigue.getSleepEfficiency = function(character)
    local sleepEfficiency = 1
    
    for trait, multiplier in pairs(Fatigue.sleepEfficiency) do
        if character:HasTrait(trait) then
            sleepEfficiency = sleepEfficiency * multiplier
        end
    end
    
    return sleepEfficiency
end

---@param character IsoPlayer
Fatigue.updateFatigue = function(character)
    local playerData = StatsData.getPlayerData(character)
    local stats = playerData.stats
    
    if playerData.asleep then
        local fatigue = stats:getFatigue()
        if fatigue > 0 then
            local bedMultiplier = Fatigue.bedEfficiency[character:getBedType()] or 1
        
            local fatigueDelta = 1 / Globals.gameTime:getMinutesPerDay() / 60 * Globals.multiplier / 2
            local fatigueRate = Fatigue.getFatigueRate(character)
        
            local fatigueDecrease = 0
            if fatigue <= 0.3 then
                fatigueDecrease = fatigueDelta / (fatigueRate * 7) * 0.3
            else
                fatigueDecrease = fatigueDelta / (fatigueRate * 5) * 0.7
            end
            fatigueDecrease = fatigueDecrease * Fatigue.getSleepEfficiency(character) * bedMultiplier
            stats:setFatigue(Math.max(fatigue - fatigueDecrease, 0))
        end
    else
        local tirednessRate = Fatigue.getFatigueRate(character)
        local enduranceMultiplier = Math.max(1 - stats:getEndurance(), 0.3)
        local fatigueChange = ZomboidGlobals.FatigueIncrease * Globals.statsDecreaseMultiplier * enduranceMultiplier * Globals.delta * tirednessRate * character:getFatiqueMultiplier()
        
        stats:setFatigue(Math.min(stats:getFatigue() + fatigueChange, 1))
    end
end

---@param character IsoPlayer
Fatigue.updateSleep = function(character)
    local statsData = StatsData.getPlayerData(character)
    local forceWakeUpTime = statsData.forceWakeUpTime or 9
    
    local time = Globals.gameTime:getTimeOfDay()
    local lastTime = Globals.gameTime:getLastTimeOfDay()
    if lastTime > time then
        if lastTime < forceWakeUpTime then
            time = time + 24
        else
            lastTime = lastTime - 24
        end
    end
    
    local shouldWakeUp = false
    if time >= forceWakeUpTime and lastTime < forceWakeUpTime then
        shouldWakeUp = true
    elseif character:getAsleepTime() > 16 then
        shouldWakeUp = true
    elseif bClient or getNumActivePlayers() > 1 then
        shouldWakeUp = shouldWakeUp or character:pressedAim() or character:pressedMovement(false)
    elseif statsData.forceWakeUp then
        shouldWakeUp = true
    end
    
    if shouldWakeUp then
        statsData.forceWakeUp = false
        getSoundManager():setMusicWakeState(character, "WakeNormal")
        getSleepingEvent():wakeUp(character)
        character:setForceWakeUpTime(-1)
        if bClient then
            -- hack to call sendCharacter, is it needed?
            character:setIgnoreMovement(true)
            character:setIgnoreMovement(false)
        end
        -- this.dirtyRecalcGridStackTime = 20.0F; can't really be reimplemented, hope it's not important
    end
end

local isoGameCharacter = __classmetatables[IsoGameCharacter.class].__index

---@type fun(self:IsoGameCharacter, ForceWakeUpTime:float)
local old_setForceWakeUpTime = isoGameCharacter.setForceWakeUpTime
---@param self IsoGameCharacter
---@param ForceWakeUpTime float
isoGameCharacter.setForceWakeUpTime = function(self, ForceWakeUpTime)
    StatsData.getPlayerData(self).forceWakeUpTime = ForceWakeUpTime
    old_setForceWakeUpTime(self, ForceWakeUpTime)
end

---@type fun(self:IsoGameCharacter)
local old_forceAwake = isoGameCharacter.forceAwake
---@param self IsoGameCharacter
isoGameCharacter.forceAwake = function(self)
    if self:isAsleep() then
        StatsData.getPlayerData(self).forceWakeUp = true
    end
    old_forceAwake(self)
end

return Fatigue