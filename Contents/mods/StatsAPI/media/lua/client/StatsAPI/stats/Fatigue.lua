local Math = require "StatsAPI/lib/Math"
local bClient = isClient()

local Globals = require "StatsAPI/Globals"
local Fatigue = {}


Fatigue.bedEfficiency = {goodBed = 1.1, badBed = 0.9, floor = 0.6}
Fatigue.fatigueRate = {awake = {}, asleep = {}}
Fatigue.sleepEfficiency = {}
Fatigue.sleepLength = {}

---@param stats CharacterStats
---@return number
Fatigue.getFatigueRate = function(stats)
    local fatigueRates = stats.asleep and Fatigue.fatigueRate.asleep or Fatigue.fatigueRate.awake
    
    local fatigueRate = 1
    for trait, multiplier in pairs(fatigueRates) do
        if stats.character:HasTrait(trait) then
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

---@param self CharacterStats
---@param bedType string
---@return number
Fatigue.getSleepDuration = function(self, bedType)
    local sleepLength = ZombRand(self.fatigue * 10, self.fatigue * 13) + 1;
    
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
    local fatigue = self.javaStats:getFatigue()
    if self.asleep then
        if fatigue > 0 then
            local bedMultiplier = Fatigue.bedEfficiency[self.character:getBedType()] or 1
        
            local fatigueDelta = 1 / Globals.gameTime:getMinutesPerDay() / 60 * Globals.multiplier / 2
            local fatigueRate = Fatigue.getFatigueRate(self)
        
            local fatigueDecrease = 0
            if fatigue <= 0.3 then
                fatigueDecrease = fatigueDelta / (fatigueRate * 7) * 0.3
            else
                fatigueDecrease = fatigueDelta / (fatigueRate * 5) * 0.7
            end
            fatigueDecrease = fatigueDecrease * Fatigue.getSleepEfficiency(self.character) * bedMultiplier
            self.fatigue = Math.max(fatigue - fatigueDecrease, 0)
        else
            self.fatigue = fatigue
            return
        end
    else
        local tirednessRate = Fatigue.getFatigueRate(self)
        local enduranceMultiplier = Math.max(1 - self.javaStats:getEndurance(), 0.3)
        local fatigueChange = ZomboidGlobals.FatigueIncrease * Globals.statsDecreaseMultiplier * enduranceMultiplier * Globals.delta * tirednessRate * self.character:getFatiqueMultiplier()
    
        self.fatigue = Math.min(fatigue + fatigueChange, 1)
    end
    self.javaStats:setFatigue(self.fatigue)
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
    
    local time = Globals.gameTime:getTimeOfDay()
    local lastTime = Globals.gameTime:getLastTimeOfDay()
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
        if self.moodles:getMoodleLevel(MoodleType.Pain) >= 2 and self.fatigue <= 0.85 then
            return false, getText("ContextMenu_PainNoSleep")
        end
        if self.moodles:getMoodleLevel(MoodleType.Panic) >= 1 then
            return false, getText("ContextMenu_PanicNoSleep")
        end
    end
    
    if (self.character:getVariableBoolean("ExerciseEnded") == false) then
        return false
    end
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
    
    local sleepHours = (sleepFor + Globals.gameTime:getTimeOfDay()) % 24
    
    self.character:setForceWakeUpTime(sleepHours)
    self.character:setAsleepTime(0.0)
    self.character:setAsleep(true)
    getSleepingEvent():setPlayerFallAsleep(self.character, sleepFor);
    
    UIManager.setFadeBeforeUI(self.playerNum, true)
    UIManager.FadeOut(self.playerNum, 1)
    
    if IsoPlayer.allPlayersAsleep() then
        UIManager.getSpeedControls():SetCurrentGameSpeed(3)
        save(true)
    end
end

return Fatigue