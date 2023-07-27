local Math = require("StatsAPI/lib/Math")

---@class StatsContainer
---@field stress number
---@field endurance number
---@field thirst number
---@field fatigue number
---@field hunger number
---@field panic number
---@field boredom number
---@field sadness number
---
---@field javaStats Stats
---@field bodyDamage BodyDamage
local StatsContainer = {}

---@param self StatsContainer
---@param javaStats Stats
---@param bodyDamage BodyDamage
StatsContainer.new = function(self, javaStats, bodyDamage)
    local o = {}
    setmetatable(o, self)
    
    o.javaStats = javaStats
    o.bodyDamage = bodyDamage
    o.stress = 0
    o.endurance = 0
    o.thirst = 0
    o.fatigue = 0
    o.hunger = 0
    o.panic = 0
    o.boredom = 0
    o.sadness = 0
    
    return o
end

---@param self StatsContainer
StatsContainer.fromJava = function(self)
    self.stress = self.javaStats.stress
    self.endurance = self.javaStats:getEndurance()
    self.thirst = self.javaStats:getThirst()
    self.fatigue = self.javaStats:getFatigue()
    self.hunger = self.javaStats:getHunger()
    self.panic = self.javaStats:getPanic()
    
    self.boredom = self.bodyDamage:getBoredomLevel()
    self.sadness = self.bodyDamage:getUnhappynessLevel()
end

---@param self StatsContainer
StatsContainer.toJava = function(self)
    self.javaStats:setStress(Math.clamp(self.stress, 0, 1))
    self.javaStats:setEndurance(Math.clamp(self.endurance, 0, 1))
    self.javaStats:setThirst(Math.clamp(self.thirst, 0, 1))
    self.javaStats:setFatigue(Math.clamp(self.fatigue, 0, 1))
    self.javaStats:setHunger(Math.clamp(self.hunger, 0, 1))
    self.javaStats:setPanic(Math.clamp(self.panic, 0, 100))
    
    self.bodyDamage:setBoredomLevel(Math.clamp(self.boredom, 0, 100))
    self.bodyDamage:setUnhappynessLevel(Math.clamp(self.sadness, 0, 100))
end

return StatsContainer