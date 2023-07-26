local Math = require "StatsAPI/lib/Math"

local textManager = getTextManager()
local FONT_HGT_SMALL = textManager:getFontHeight(UIFont.Small)

---@class LuaMoodle : ISUIElement
---@field template MoodleTemplate
---@field texture Texture
---@field backgrounds table<Texture>
---@field level int
local LuaMoodle = ISUIElement:derive("LuaMoodle")

---@param self LuaMoodle
---@param template MoodleTemplate
LuaMoodle.new = function(self, template)
    local o = ISUIElement:new(getCore():getScreenWidth() - 46, 100, 32, 32)
    setmetatable(o, self)
    
    o.template = template
    o.texture = template.texture
    o.backgrounds = template.backgrounds
    o.level = 1
    
    return o
end

---@param self LuaMoodle
LuaMoodle.initialise = function(self)
    ISUIElement.initialise(self)
end

---@param self LuaMoodle
LuaMoodle.render = function(self)
    self:drawTexture(self.backgrounds[self.level], 0, 0, 1, 1, 1, 1)
    self:drawTexture(self.texture, 0, 0, 1, 1, 1, 1)
    if self:isMouseOver() then
        local name = self.template.text[self.level].name
        local desc = self.template.text[self.level].desc
        local length = Math.max(textManager:MeasureStringX(UIFont.Small, name), textManager:MeasureStringX(UIFont.Small, desc))
        self:drawTextureScaled(nil, -16 - length, -1, length + 12, (2 + FONT_HGT_SMALL) * 2, 0.6, 0, 0, 0)
        self:drawTextRight(name, -10, 1, 1, 1, 1, 1)
        self:drawTextRight(desc, -10, FONT_HGT_SMALL + 1, 0.8, 0.8, 0.8, 1.0)
    end
end

return LuaMoodle