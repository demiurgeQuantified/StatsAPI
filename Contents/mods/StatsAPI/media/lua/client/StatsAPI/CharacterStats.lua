local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Thirst = require "StatsAPI/stats/Thirst"
local Hunger = require "StatsAPI/stats/Hunger"
local Panic = require "StatsAPI/stats/Panic"
local Stress = require "StatsAPI/stats/Stress"
local Fatigue = require "StatsAPI/stats/Fatigue"
local Boredom = require "StatsAPI/stats/Boredom"
local Sadness = require "StatsAPI/stats/Sadness"
local CarryWeight = require "StatsAPI/stats/CarryWeight"

local OverTimeEffects = require "StatsAPI/OverTimeEffects"

-- TODO: character trait modifiers should be cached here, as they don't change very often
-- TODO: cache all the stats after they're applied so that we don't need to get them again for OverTimeEffects
---@class CharacterStats
---@field fatigue number The character's fatigue at the end of the last stats calculation
---@field panic number The character's panic at the end of the last stats calculation
---@field character IsoGameCharacter The character this StatsData belongs to
---@field playerNum int The character's playerNum
---@field bodyDamage BodyDamage The character's BodyDamage object
---@field javaStats Stats The character's Stats object
---@field moodles Moodles The character's Moodles object
---@field wellFed boolean Does the character have a food buff active?
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
---@field vehicle BaseVehicle|nil The character's current vehicle
---@field reading boolean Is the character currently reading?
---@field overTimeEffects table<int, OverTimeEffect> The character's active OverTimeEffects
local CharacterStats = {}
CharacterStats.panicIncrease = 7
CharacterStats.panicReduction = 0.06
CharacterStats.oldNumZombiesVisible = 0
CharacterStats.forceWakeUp = false
CharacterStats.asleep = false
CharacterStats.staticCarryMod = 0

CharacterStats.persistentStats = {forceWakeUpTime = true, overTimeEffects = true}
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
    o.bodyDamage = character:getBodyDamage()
    o.moodles = character:getMoodles()
    o.javaStats = character:getStats()
    
    local modData = character:getModData()
    modData.StatsAPI = modData.StatsAPI or {}
    modData.StatsAPI.StatsData = modData.StatsAPI.StatsData or {}
    o.modData = modData.StatsAPI.StatsData
    
    o.modData.overTimeEffects = o.modData.overTimeEffects or {}
    
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
CharacterStats.updateBoredom = Boredom.updateBoredom
CharacterStats.getIdleBoredom = Boredom.getIdleBoredom
CharacterStats.updateSadness = Sadness.updateSadness
CharacterStats.updateCarryWeight = CarryWeight.updateCarryWeight

---@param self CharacterStats
CharacterStats.updateCache = function(self)
    self.asleep = self.character:isAsleep()
    self.vehicle = self.character:getVehicle()
    self.reading = self.character:isReading()
    self.wellFed = self.moodles:getMoodleLevel(MoodleType.FoodEaten) ~= 0
end

---@param self CharacterStats
CharacterStats.CalculateStats = function(self)
    self:updateCache()

    -- Stats stats
    self:updateStress()
    self:updateEndurance()
    self:updateThirst()
    self:updateFatigue()
    self:updateHunger()
    self:updateFitness()
    
    -- BodyDamage stats
    self:updatePanic()
    self:updateBoredom()
    self:updateSadness()
    
    if self.asleep then
        self:updateSleep()
    end
    
    self:applyOverTimeEffects()
    
    self:updateCarryWeight()
end

---@param self CharacterStats
CharacterStats.applyOverTimeEffects = function(self)
    -- TODO: cache all the changes to each stat instead of applying them immediately, so if multiple effects are active it won't waste performance applying multiple times
    for j = 1, #self.overTimeEffects do
        local effect = self.overTimeEffects[j]
        local delta = Globals.delta
        effect.timeRemaining = effect.timeRemaining - delta
        if effect.timeRemaining <= 0 then
            table.remove(self.overTimeEffects, j)
            delta = delta + effect.timeRemaining
        end
        OverTimeEffects.statSetters[effect.stat](self, effect.amount * delta)
    end
end

---@type table<IsoGameCharacter, CharacterStats>
local CharacterStatsMap = {}

---@param character IsoGameCharacter
---@return CharacterStats
CharacterStats.getOrCreate = function(character)
    local data = CharacterStatsMap[character]
    if not data then
        data = CharacterStats:new(character)
        CharacterStatsMap[character] = data
    end
    return data
end

---@param character IsoGameCharacter
---@return CharacterStats|nil
CharacterStats.get = function(character)
    return CharacterStatsMap[character]
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