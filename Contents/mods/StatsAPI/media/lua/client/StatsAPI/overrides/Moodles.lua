local CharacterStats = require "StatsAPI/CharacterStats"

local moodleTypeToLuaMoodle = {
    [MoodleType.Endurance] = "endurance",
    [MoodleType.Tired] = "tired",
    [MoodleType.Hungry] = "hungry",
    [MoodleType.Panic] = "panic",
    [MoodleType.Sick] = "sick",
    [MoodleType.Bored] = "bored",
    [MoodleType.Unhappy] = "unhappy",
    [MoodleType.Bleeding] = "bleeding",
    [MoodleType.Wet] = "wet",
    [MoodleType.HasACold] = "hasacold",
    --[MoodleType.Angry] = "angry",
    [MoodleType.Stress] = "stress",
    [MoodleType.Thirst] = "thirst",
    [MoodleType.Injured] = "injured",
    [MoodleType.Pain] = "pain",
    [MoodleType.HeavyLoad] = "heavyload",
    [MoodleType.Drunk] = "drunk",
    [MoodleType.Dead] = "dead",
    [MoodleType.Zombie] = "zombie",
    [MoodleType.Hyperthermia] = "hyperthermia",
    [MoodleType.Hypothermia] = "hypothermia",
    [MoodleType.Windchill] = "windchill",
    [MoodleType.CantSprint] = "CantSprint",
    [MoodleType.FoodEaten] = "foodeaten"
}

---@type Moodles
local moodles = __classmetatables[Moodles.class].__index

local old_getMoodleLevel = moodles.getMoodleLevel
---@param self Moodles
---@param moodleType MoodleType|int
moodles.getMoodleLevel = function(self, moodleType)
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