local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local Thirst = require "StatsAPI/stats/Thirst"
local Hunger = require "StatsAPI/stats/Hunger"
local Panic = require "StatsAPI/stats/Panic"
local Stress = require "StatsAPI/stats/Stress"
local Fatigue = require "StatsAPI/stats/Fatigue"

---@class CharacterStats
---@field character IsoGameCharacter The character this StatsData belongs to
---@field javaStats Stats The character's Stats object
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
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
---@param character IsoGameCharacter
CharacterStats.new = function(self, character)
    local o = {}
    setmetatable(o, self)
    
    o.character = character
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

return CharacterStats