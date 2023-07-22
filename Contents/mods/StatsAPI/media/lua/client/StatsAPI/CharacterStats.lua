local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Thirst = require "StatsAPI/stats/Thirst"
local Hunger = require "StatsAPI/stats/Hunger"
local Panic = require "StatsAPI/stats/Panic"
local Stress = require "StatsAPI/stats/Stress"
local Fatigue = require "StatsAPI/stats/Fatigue"

-- TODO: character trait modifiers should be cached here, as they don't change very often

---@class CharacterStats
--TODO: caching all the stats like this would be future proof, as we'll likely need it for performance later on
---@field fatigue number The character's fatigue at the end of the last stats calculation
---@field character IsoGameCharacter The character this StatsData belongs to
---@field playerNum int The character's playerNum
---@field javaStats Stats The character's Stats object
---@field moodles Moodles The character's Moodles object
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
---@field insideVehicle boolean Is the character in a vehicle?
local CharacterStats = {}
CharacterStats.panicIncrease = 7
CharacterStats.panicReduction = 0.06
CharacterStats.oldNumZombiesVisible = 0
CharacterStats.forceWakeUp = false
CharacterStats.asleep = false

CharacterStats.persistentStats = {forceWakeUpTime = true}
---@param self CharacterStats
---@param key any
CharacterStats.__index = function(self, key)
    if CharacterStats.persistentStats[key] then
        return self.modData[key]
    end
    return CharacterStats[key]
end

---@param self CharacterStats
---@param key any
---@param value any
CharacterStats.__newindex = function(self, key, value)
    if CharacterStats.persistentStats[key] then
        self.modData[key] = value
    else
        rawset(self, key, value)
    end
end

---@param self CharacterStats
---@param character IsoPlayer
CharacterStats.new = function(self, character)
    local o = {}
    setmetatable(o, self)
    
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.moodles = character:getMoodles()
    o.javaStats = character:getStats()
    
    local modData = character:getModData()
    modData.StatsAPI = modData.StatsAPI or {}
    modData.StatsAPI.StatsData = modData.StatsAPI.StatsData or {}
    o.modData = modData.StatsAPI.StatsData
    
    return o
end

---@param self CharacterStats
CharacterStats.updateEndurance = function(self)
    if self.character:isUnlimitedEndurance() then
        self.javaStats:setEndurance(1)
        return
    end
    
    local endurance = self.javaStats:getEndurance()
    
    if self.asleep then
        local enduranceMultiplier = 2
        if IsoPlayer.allPlayersAsleep() then
            enduranceMultiplier = enduranceMultiplier * Globals.deltaMinutesPerDay
        end
        endurance = endurance + ZomboidGlobals.ImobileEnduranceIncrease * Globals.sandboxOptions:getEnduranceRegenMultiplier() * self.character:getRecoveryMod() * Globals.multiplier * enduranceMultiplier
    end
    
    self.javaStats:setEndurance(Math.clamp(endurance, 0, 1))
end

---@param self CharacterStats
CharacterStats.updateFitness = function(self)
    self.javaStats:setFitness(self.character:getPerkLevel(Perks.Fitness) / 5 - 1)
end

CharacterStats.updateThirst = Thirst.updateThirst
CharacterStats.updateHunger = Hunger.updateHunger
CharacterStats.updatePanic = Panic.updatePanic
CharacterStats.updateStress = Stress.updateStress
CharacterStats.updateFatigue = Fatigue.updateFatigue
CharacterStats.updateSleep = Fatigue.updateSleep

---@param self CharacterStats
CharacterStats.CalculateStats = function(self)
    self.asleep = self.character:isAsleep()
    self.insideVehicle = self.character:getVehicle() ~= nil
    
    self:updateStress()
    self:updateEndurance()
    self:updateThirst()
    self:updateFatigue()
    self:updateHunger()
    self:updatePanic()
    self:updateFitness()
    
    if self.asleep then
        self:updateSleep()
    end
end

---@type table<IsoGameCharacter, CharacterStats>
local CharacterDataMap = {}

---@param character IsoGameCharacter
---@return CharacterStats
CharacterStats.getOrCreate = function(character)
    local data = CharacterDataMap[character]
    if not data then
        data = CharacterStats:new(character)
        CharacterDataMap[character] = data
    end
    return data
end

---@param character IsoGameCharacter
---@return CharacterStats|nil
CharacterStats.get = function(character)
    return CharacterDataMap[character]
end



---@param player int
---@param bed IsoObject|nil
ISWorldObjectContextMenu.onSleepWalkToComplete = function(player, bed)
    Fatigue.trySleep(CharacterStats.get(getSpecificPlayer(player)), bed)
end

local isoPlayer = __classmetatables[IsoPlayer.class].__index

---@type fun(self:IsoGameCharacter, ForceWakeUpTime:float)
local old_setForceWakeUpTime = isoPlayer.setForceWakeUpTime
---@param self IsoGameCharacter
---@param ForceWakeUpTime float
isoPlayer.setForceWakeUpTime = function(self, ForceWakeUpTime)
    CharacterStats.getOrCreate(self).forceWakeUpTime = ForceWakeUpTime
    old_setForceWakeUpTime(self, ForceWakeUpTime)
end

---@type fun(self:IsoGameCharacter)
local old_forceAwake = isoPlayer.forceAwake
---@param self IsoGameCharacter
isoPlayer.forceAwake = function(self)
    if self:isAsleep() then
        CharacterStats.getOrCreate(self).forceWakeUp = true
    end
    old_forceAwake(self)
end

local bodyDamage = __classmetatables[BodyDamage.class].__index

---@param self BodyDamage
---@param PanicIncreaseValue number
bodyDamage.setPanicIncreaseValue = function(self, PanicIncreaseValue)
    CharacterStats.getOrCreate(self:getParentChar()).panicIncrease = PanicIncreaseValue
end

---@param self BodyDamage
---@param PanicReductionValue number
bodyDamage.setPanicReductionValue = function(self, PanicReductionValue)
    CharacterStats.getOrCreate(self:getParentChar()).panicReduction = PanicReductionValue
end

return CharacterStats