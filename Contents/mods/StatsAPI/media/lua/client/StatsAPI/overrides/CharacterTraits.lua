local CharacterStats = require "StatsAPI/CharacterStats"

---@type TraitCollection
local traitCollection = __classmetatables[CharacterTraits.class].__index

---@param traits TraitCollection
local refreshTraits = function(traits)
    for i = 0, getNumActivePlayers() do
        local player = getSpecificPlayer(i)
        if player and player:getTraits() == traits then
            local stats = CharacterStats.get(player)
            if stats then
                stats:refreshTraits()
            end
            break
        end
    end
end

local old_add = traitCollection.add
---@generic o
---@param self TraitCollection
---@param trait o
traitCollection.add = function(self, trait)
    old_add(self, trait)
    refreshTraits(self)
end

local old_remove = traitCollection.remove
---@generic o
---@param self TraitCollection
---@param trait o
traitCollection.remove = function(self, trait)
    old_remove(self, trait)
    refreshTraits(self)
end