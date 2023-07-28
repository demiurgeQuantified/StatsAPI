local Math = require "StatsAPI/lib/Math"
local bClient = isClient()

local Globals = require "StatsAPI/Globals"
local Fatigue = {}


Fatigue.bedEfficiency = {goodBed = 1.1, badBed = 0.9, floor = 0.6}
Fatigue.fatigueRate = {awake = {}, asleep = {}}
Fatigue.sleepEfficiency = {}
Fatigue.sleepLength = {}

---@param character IsoGameCharacter
---@return number, number
Fatigue.getFatigueRates = function(character)
    local fatigueRateAwake = 1
    
    for trait, multiplier in pairs(Fatigue.fatigueRate.awake) do
        if character:HasTrait(trait) then
            fatigueRateAwake = fatigueRateAwake * multiplier
        end
    end
    
    local fatigueRateAsleep = 1
    
    for trait, multiplier in pairs(Fatigue.fatigueRate.asleep) do
        if character:HasTrait(trait) then
            fatigueRateAsleep = fatigueRateAsleep * multiplier
        end
    end
    
    return fatigueRateAwake, fatigueRateAsleep
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

---@param self CharacterStats
---@param bedType string
---@return number
Fatigue.getSleepDuration = function(self, bedType)
    local sleepLength = ZombRand(self.stats.fatigue * 10, self.stats.fatigue * 13) + 1;
    
    if bedType == "goodBed" then
        sleepLength = sleepLength -1;
    elseif bedType == "badBed" then
        sleepLength = sleepLength +1;
    elseif bedType == "floor" then
        sleepLength = sleepLength * 0.7;
    end
    
    for trait, multiplier in pairs(Fatigue.sleepLength) do
        if self.character:HasTrait(trait) then
            sleepLength = sleepLength * multiplier
        end
    end
    
    sleepLength = Math.clamp(sleepLength, 3, 16)
    
    return sleepLength
end

---@param character IsoGameCharacter
---@param bed IsoObject|nil
---@return string
Fatigue.getBedType = function(character, bed)
    local bedType = "badBed";
    
    if bed then
        bedType = bed:getProperties():Val("BedType") or "averageBed";
    elseif character:getVehicle() then
        bedType = "averageBed";
    else
        bedType = "floor";
    end
    
    return bedType
end

---@param self CharacterStats
Fatigue.updateFatigue = function(self)
    if self.asleep then
        if self.stats.fatigue > 0 and Globals.timeOfDay > self.delayToSleep then
            local bedMultiplier = Fatigue.bedEfficiency[self.character:getBedType()] or 1
            local fatigueDelta = Globals.timeOfDay - Globals.lastTimeOfDay
    
            local fatigueDecrease = 0
            if self.stats.fatigue <= 0.3 then
                fatigueDecrease = fatigueDelta / (self.fatigueMultiplierAsleep * 7) * 0.3
            else
                fatigueDecrease = fatigueDelta / (self.fatigueMultiplierAsleep * 5) * 0.7
            end
            self.stats.fatigue = self.stats.fatigue - fatigueDecrease * self.sleepEfficiency * bedMultiplier
        end
    else
        local enduranceMultiplier = Math.max(1 - self.stats.endurance, 0.3)
        self.stats.fatigue = self.stats.fatigue + ZomboidGlobals.FatigueIncrease * Globals.statsDecreaseMultiplier * enduranceMultiplier * Globals.delta * self.fatigueMultiplierAwake * self.character:getFatiqueMultiplier()
    end
end

---@param self CharacterStats
Fatigue.updateSleep = function(self)
    if Fatigue.shouldWakeUp(self) then
        self.forceWakeUp = false
        getSoundManager():setMusicWakeState(self.character, "WakeNormal")
        getSleepingEvent():wakeUp(self.character)
        self.character:setForceWakeUpTime(-1)
        if bClient then
            -- hack to call sendCharacter, is it needed?
            self.character:setIgnoreMovement(true)
            self.character:setIgnoreMovement(false)
        end
        -- this.dirtyRecalcGridStackTime = 20.0F; can't really be reimplemented, hope it's not important
    end
end

---@param self CharacterStats
---@return boolean
Fatigue.shouldWakeUp = function(self)
    if self.forceWakeUp then
        return true
    elseif self.character:getAsleepTime() > 16 then
        return true
    elseif bClient or getNumActivePlayers() > 1 then
        if self.character:pressedAim() or self.character:pressedMovement(false) then
            return true
        end
    end
    
    local forceWakeUpTime = self.forceWakeUpTime or 9
    
    local time = Globals.timeOfDay
    local lastTime = Globals.lastTimeOfDay
    if lastTime > time then
        if lastTime < forceWakeUpTime then
            time = time + 24
        else
            lastTime = lastTime - 24
        end
    end
    
    if time >= forceWakeUpTime and lastTime < forceWakeUpTime then
        return true
    end
    
    return false
end

---@param self CharacterStats
---@return boolean, string|nil
Fatigue.canSleep = function(self)
    local zombiesNearby = self.oldNumZombiesVisible > 0 or self.javaStats:getNumChasingZombies() > 0 or self.javaStats:getNumVeryCloseZombies() > 0
    if zombiesNearby then
        return false, getText("IGUI_Sleep_NotSafe")
    end
    
    if self.character:getSleepingTabletEffect() < 2000 then
        if self.luaMoodles.moodles.pain.level >= 2 and self.stats.fatigue <= 0.85 then
            return false, getText("ContextMenu_PainNoSleep")
        end
        if self.luaMoodles.moodles.panic.level >= 1 then
            return false, getText("ContextMenu_PanicNoSleep")
        end
    end
    
    if (self.character:getVariableBoolean("ExerciseEnded") == false) then
        return false
    end
    
    return true
end

---@param self CharacterStats
---@param bed IsoObject|nil
Fatigue.trySleep = function(self, bed)
    local canSleep, reason = Fatigue.canSleep(self)
    if not canSleep then
        if reason then
            self.character:Say(reason)
        end
        return
    end
    
    ISTimedActionQueue.clear(self.character)
    local bedType = Fatigue.getBedType(self, bed)
    
    if bClient and getServerOptions():getBoolean("SleepAllowed") then
        self.character:setAsleepTime(0.0)
        self.character:setAsleep(true)
        UIManager.setFadeBeforeUI(self.playerNum, true)
        UIManager.FadeOut(self.playerNum, 1)
        return
    end
    
    self.character:setBed(bed);
    self.character:setBedType(bedType);
    
    local sleepFor = Fatigue.getSleepDuration(self, bedType)
    
    local sleepHours = (sleepFor + Globals.timeOfDay) % 24
    
    self.character:setForceWakeUpTime(sleepHours)
    self.character:setAsleepTime(0.0)
    self.character:setAsleep(true)
    
    getSleepingEvent():setPlayerFallAsleep(self.character, sleepFor);
    Fatigue.doDelayToSleep(self, bedType)
    
    UIManager.setFadeBeforeUI(self.playerNum, true)
    UIManager.FadeOut(self.playerNum, 1)
    
    if IsoPlayer.allPlayersAsleep() then
        UIManager.getSpeedControls():SetCurrentGameSpeed(3)
        save(true)
    end
end

---@param self CharacterStats
---@param bedType string
Fatigue.doDelayToSleep = function(self, bedType)
    local delayToSleep
    
    if self.character:getSleepingTabletEffect() > 1000 then
        delayToSleep = 0.1
    else
        delayToSleep = self.character:HasTrait("Insomniac") and 1 or 0.3
        
        local painLevel = self.luaMoodles.moodles.pain.level
        if painLevel > 0 then
            delayToSleep = delayToSleep + 1 + painLevel * 0.2
        end
        
        if self.luaMoodles.moodles.stress.level > 0 then
            delayToSleep = delayToSleep * 1.2
        end
    
        local bedTypeSleepDelay = {
            badBed = 1.3,
            goodBed = 0.8,
            floor = 1.6
        }
        
        local bedDelay = bedTypeSleepDelay[bedType]
        if bedDelay then
            delayToSleep = delayToSleep * bedDelay
        end
        
        if self.character:HasTrait("NightOwl") then
            delayToSleep = delayToSleep * 0.5
        end
    end
    
    delayToSleep = ZombRandFloat(0, Math.min(delayToSleep, 2))
    
    self.delayToSleep = Globals.timeOfDay + delayToSleep
end

return Fatigue