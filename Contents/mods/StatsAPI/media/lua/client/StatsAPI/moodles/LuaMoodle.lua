local Math = require "StatsAPI/lib/Math"

local textManager = getTextManager()
local FONT_HGT_SMALL = textManager:getFontHeight(UIFont.Small)

---@class LuaMoodle : ISUIElement
---@field baseY number
---@field template MoodleTemplate
---@field texture Texture
---@field backgrounds table<Texture>
---@field level int
---@field renderIndex int
---@field parent LuaMoodles
local LuaMoodle = ISUIElement:derive("LuaMoodle")

---@param self LuaMoodle
---@param x number
---@param y number
---@param template MoodleTemplate
---@param parent LuaMoodles
LuaMoodle.new = function(self, x, y, template, parent)
    local o = ISUIElement:new(x, y, 32 * parent.scale, 32 * parent.scale)
    setmetatable(o, self)
    
    o.baseY = y
    o.template = template
    o.texture = template.texture
    o.backgrounds = template.backgrounds
    o.renderIndex = 1
    o.level = 0
    o.parent = parent
    
    return o
end

---@param self LuaMoodle
---@param level int
LuaMoodle.setLevel = function(self, level)
    local showing = self.level > 0
    if not showing then
        if level > 0 then
            self:addToUIManager()
            self.parent:showMoodle(self)
        end
    else
        if level <= 0 then
            self:removeFromUIManager()
            self.parent:hideMoodle(self)
        end
    end
    self.level = level
end

---@param self LuaMoodle
---@param renderIndex int
LuaMoodle.setRenderIndex = function(self, renderIndex)
    self:setY(self.baseY + self.parent.spacing * self.parent.scale * (renderIndex - 1))
end

---@param self LuaMoodle
LuaMoodle.render = function(self)
    self:drawTextureScaledUniform(self.backgrounds[self.level], 0, 0, self.parent.scale, 1, 1, 1, 1)
    self:drawTextureScaledUniform(self.texture, 0, 0, self.parent.scale, 1, 1, 1, 1)
    if self:isMouseOver() then
        local name = self.template.text[self.level].name
        local desc = self.template.text[self.level].desc
        local length = Math.max(textManager:MeasureStringX(UIFont.Small, name), textManager:MeasureStringX(UIFont.Small, desc))
        self:drawTextureScaled(nil, -16 - length, -1, length + 12, (2 + FONT_HGT_SMALL) * 2, 0.6, 0, 0, 0)
        self:drawTextRight(name, -10, 1, 1, 1, 1, 1, UIFont.Small)
        self:drawTextRight(desc, -10, FONT_HGT_SMALL + 1, 0.8, 0.8, 0.8, 1.0, UIFont.Small)
    end
end

return LuaMoodle