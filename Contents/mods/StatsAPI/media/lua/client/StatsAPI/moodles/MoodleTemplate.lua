local Moodles = require("StatsAPI/Globals").Moodles

---@class MoodleTemplate
---@field type string
---@field texture Texture
---@field text table<int<string,string>>
---@field backgrounds table<int,string>
local MoodleTemplate = {}
---@type table<MoodleTemplate>
MoodleTemplate.templates = {}
MoodleTemplate.Backgrounds = {
    Positive = {
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_1.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_2.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_3.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
    },
    Negative = {
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_1.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_2.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_3.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_4.png")
    }
}

---@param self MoodleTemplate
---@param type string
---@param texture Texture
---@param backgrounds table<Texture>
---@param text table<table<string, string>>
MoodleTemplate.new = function(self, type, texture, backgrounds, text)
    local o = {}
    setmetatable(o, self)

    o.type = type
    o.texture = texture
    o.backgrounds = backgrounds
    o.text = text
    
    table.insert(MoodleTemplate.templates, o)
    return o
end

-- these are needed for the mod to function
MoodleTemplate:new(Moodles.Dead, getTexture("media/ui/Moodles/Moodle_Icon_Dead.png"), MoodleTemplate.Backgrounds.Negative,
                   {{name=getText("Moodles_dead_lvl1"), desc=getText("Moodles_dead_desc_lvl1")}})

MoodleTemplate:new(Moodles.Zombie, getTexture("media/ui/Moodles/Moodle_Icon_Zombie.png"), MoodleTemplate.Backgrounds.Negative,
                   {{name=getText("Moodles_zombie_lvl1"), desc=getText("Moodles_zombified_desc_lvl1")}})


return MoodleTemplate