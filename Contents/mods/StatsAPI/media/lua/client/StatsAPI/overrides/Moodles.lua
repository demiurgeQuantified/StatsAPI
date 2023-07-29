local CharacterStats = require "StatsAPI/CharacterStats"

local moodleTypeToLuaMoodle = {
    [0] = "endurance",
    [1] = "tired",
    [2] = "hungry",
    [3] = "panic",
    [4] = "sick",
    [5] = "bored",
    [6] = "unhappy",
    [7] = "bleeding",
    [8] = "wet",
    [9] = "hasacold",
    --[10] = "angry",
    [11] = "stress",
    [12] = "thirst",
    [13] = "injured",
    [14] = "pain",
    [15] = "heavyload",
    [16] = "drunk",
    [17] = "dead",
    [18] = "zombie",
    [19] = "hyperthermia",
    [20] = "hypothermia",
    [21] = "windchill",
    [22] = "CantSprint",
    [23] = "foodeaten"
}

---@type Moodles
local moodles = __classmetatables[Moodles.class].__index

local old_getMoodleLevel = moodles.getMoodleLevel
---@param self Moodles
---@param moodleType MoodleType|int
moodles.getMoodleLevel = function(self, moodleType)
    if instanceof(moodleType, "MoodleType") then
        moodleType = MoodleType.ToIndex(moodleType)
    end
    local luaType = moodleTypeToLuaMoodle[moodleType]
    if not luaType then
        return old_getMoodleLevel(self, moodleType)
    end
    
    for _,stats in pairs(CharacterStats.CharacterStatsMap) do
        if stats.moodles == self then
            return stats.luaMoodles.moodles[luaType].level
        end
    end
end