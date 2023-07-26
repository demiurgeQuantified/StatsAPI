local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local OverTimeEffects = require "StatsAPI/OverTimeEffects"
local LuaMoodles = require "StatsAPI/moodles/LuaMoodles"

local Thirst = require "StatsAPI/stats/Thirst"
local Hunger = require "StatsAPI/stats/Hunger"
local Panic = require "StatsAPI/stats/Panic"
local Stress = require "StatsAPI/stats/Stress"
local Fatigue = require "StatsAPI/stats/Fatigue"
local Boredom = require "StatsAPI/stats/Boredom"
local Sadness = require "StatsAPI/stats/Sadness"
local CarryWeight = require "StatsAPI/stats/CarryWeight"

-- TODO: cache all the stats after they're applied so that we don't need to get them again for OverTimeEffects
---@class CharacterStats
---@field fatigue number The character's fatigue at the end of the last stats calculation
---@field panic number The character's panic at the end of the last stats calculation
---
---@field character IsoGameCharacter The character this StatsData belongs to
---@field playerNum int The character's playerNum
---@field bodyDamage BodyDamage The character's BodyDamage object
---@field javaStats Stats The character's Stats object
---@field moodles Moodles The character's Moodles object
---@field luaMoodles LuaMoodles The character's LuaMoodles object
---
---@field maxWeightDelta number The character's carry weight multiplier from traits
---@field panicMultiplier number The character's panic multiplier from traits
---@field thirstMultiplier number The character's thirst multiplier from traits
---@field hungerMultiplier number The character's hunger multiplier from traits
---@field sleepEfficiency number The character's sleeping efficiency
---@field fatigueMultiplierAwake number The character's fatigue multiplier from traits while awake
---@field fatigueMultiplierAsleep number The character's fatigue multiplier from traits while asleep
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
---
---@field wellFed boolean Does the character have a food buff active?
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
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

---@private
---@param self CharacterStats
---@param character IsoPlayer
---@return CharacterStats
CharacterStats.new = function(self, character)
    ---@type CharacterStats
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
    
    o:refreshTraits()
    
    o.modData.overTimeEffects = o.modData.overTimeEffects or {}
    
    return o
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

---@param self CharacterStats
CharacterStats.updateCache = function(self)
    self.asleep = self.character:isAsleep()
    self.vehicle = self.character:getVehicle()
    self.reading = self.character:isReading()
    self.wellFed = self.moodles:getMoodleLevel(MoodleType.FoodEaten) ~= 0
end

-- TODO: this isn't called when the player's weight changes
-- TODO: check java for other possible unhandled trait changes
---@param self CharacterStats
CharacterStats.refreshTraits = function(self)
    self.maxWeightDelta = CarryWeight.getMaxWeightDelta(self.character)
    self.panicMultiplier = Panic.getTraitMultiplier(self.character)
    self.thirstMultiplier = Thirst.getThirstMultiplier(self.character)
    self.hungerMultiplier = Hunger.getAppetiteMultiplier(self.character)
    self.sleepEfficiency = Fatigue.getSleepEfficiency(self.character)
    self.fatigueMultiplierAwake, self.fatigueMultiplierAsleep = Fatigue.getFatigueRates(self.character)
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
CharacterStats.create = function(character)
    local stats = CharacterStats:new(character)
    CharacterStatsMap[character] = stats
    return stats
end

---@param character IsoGameCharacter
---@return CharacterStats
CharacterStats.getOrCreate = function(character)
    local stats = CharacterStatsMap[character]
    if not stats then
        stats = CharacterStats:new(character)
        CharacterStatsMap[character] = stats
    end
    return stats
end

---@param character IsoGameCharacter
---@return CharacterStats|nil
CharacterStats.get = function(character)
    return CharacterStatsMap[character]
end



---@param character IsoPlayer
CharacterStats.OnCalculateStats = function(character)
    CharacterStats.get(character):CalculateStats()
end

Hook.CalculateStats.Add(CharacterStats.OnCalculateStats)

---@param playerIndex int
---@param player IsoPlayer
CharacterStats.preparePlayer = function(playerIndex, player)
    local stats = CharacterStats.create(player)
    CharacterStats.luaMoodles = LuaMoodles.create(stats)
    Panic.disableVanillaPanic(player)
end

Events.OnCreatePlayer.Add(CharacterStats.preparePlayer)

---@param player IsoPlayer
CharacterStats.cleanupPlayer = function(player)
    CharacterStats[player] = nil
end
Events.OnPlayerDeath.Add(CharacterStats.cleanupPlayer)

return CharacterStats