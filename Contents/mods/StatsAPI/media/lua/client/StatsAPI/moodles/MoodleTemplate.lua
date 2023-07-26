---@class MoodleTemplate
---@field type string
---@field texture Texture
---@field text table<int<string,string>>
---@field backgrounds table<int,string>
local MoodleTemplate = {}
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
---@param texture string
---@param backgrounds table<Texture>
---@param text table<table<string, string>>
MoodleTemplate.new = function(self, type, texture, backgrounds, text)
    local o = {}
    setmetatable(o, self)

    o.type = type
    o.texture = getTexture(texture)
    o.backgrounds = backgrounds
    o.text = text
    
    table.insert(MoodleTemplate.templates, o)
    return o
end

-- TODO: when this is more complete, an API should be created and this should be moved to VanillaMoodles.lua
MoodleTemplate:new("stress", "media/ui/Moodles/Moodle_Icon_Stressed.png", MoodleTemplate.Backgrounds.Negative,
                   {{name=getText("Moodles_stress_lvl1"), desc=getText("Moodles_stress_desc_lvl1")}})

return MoodleTemplate