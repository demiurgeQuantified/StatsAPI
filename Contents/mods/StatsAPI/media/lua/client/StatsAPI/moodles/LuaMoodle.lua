local Globals = require "StatsAPI/Globals"
local Math = require "StatsAPI/lib/Math"

local textManager = getTextManager()
local FONT_HGT_SMALL = textManager:getFontHeight(UIFont.Small)

local chevronTextures = {up = {getTexture("media/ui/Moodle_chevron_up.png"), getTexture("media/ui/Moodle_chevron_up_border.png")},
                         down = {getTexture("media/ui/Moodle_chevron_down.png"), getTexture("media/ui/Moodle_chevron_down_border.png")}}

---@class LuaMoodle : ISUIElement
---@field baseY number
---@field template MoodleTemplate
---@field texture Texture
---@field backgrounds table<Texture>
---@field level int
---@field renderIndex int
---@field parent LuaMoodles
---@field oscillationLevel number
---@field chevronCount number
---@field chevronUp boolean
---@field chevronColor table<float>
local LuaMoodle = ISUIElement:derive("LuaMoodle")
LuaMoodle.oscillator = 0
LuaMoodle.oscillatorStep = 0

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
    o.parent = parent
    
    o.level = 0
    o.chevronCount = 0
    o.chevronUp = true
    o.chevronColor = {1, 1, 1, 1}
    
    o.renderIndex = 1
    o.oscillationLevel = 0
    
    return o
end

---@param self LuaMoodle
LuaMoodle.show = function(self)
    self:addToUIManager()
    self.parent:showMoodle(self)
end

---@param self LuaMoodle
LuaMoodle.hide = function(self)
    self:removeFromUIManager()
    self.parent:hideMoodle(self)
end

---@param self LuaMoodle
---@param level int
LuaMoodle.setLevel = function(self, level)
    local showing = self.level > 0
    if not showing then
        if level > 0 then
            self:show()
        end
    else
        if level <= 0 then
            self:hide()
        else
            self:wiggle()
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
LuaMoodle.updateOscillationLevel = function(self)
    if self.oscillationLevel > 0 then
        self.oscillationLevel = self.oscillationLevel - self.oscillationLevel * 0.04 / Globals.FPSMultiplier
        if self.oscillationLevel < 0.01 then
            self.oscillationLevel = 0
        end
    end
end

---@param self LuaMoodle
LuaMoodle.render = function(self)
    local x = LuaMoodle.oscillator * self.oscillationLevel
    
    self:drawTextureScaledUniform(self.backgrounds[self.level] or self.backgrounds[1], x, 0, self.parent.scale, 1, 1, 1, 1)
    self:drawTextureScaledUniform(self.texture, x, 0, self.parent.scale, 1, 1, 1, 1)
    
    if self.chevronCount > 0 then
        local tex = chevronTextures[self.chevronUp and "up" or "down"]
        for i = 1, self.chevronCount do
            local y = 24 - i * 4
            self:drawTextureScaledUniform(tex[1], x + 16, y, self.parent.scale, unpack(self.chevronColor))
            self:drawTextureScaledUniform(tex[2], x + 16, y, self.parent.scale, unpack(self.chevronColor))
        end
    end
    
    if self:isMouseOver() then
        local translation = self.template.text[self.level] or self.template.text[1]
        local name = translation.name
        local desc = translation.desc
        local length = Math.max(textManager:MeasureStringX(UIFont.Small, name), textManager:MeasureStringX(UIFont.Small, desc))
        self:drawTextureScaled(nil, -16 - length, -1, length + 12, (2 + FONT_HGT_SMALL) * 2, 0.6, 0, 0, 0)
        self:drawTextRight(name, -10, 1, 1, 1, 1, 1, UIFont.Small)
        self:drawTextRight(desc, -10, FONT_HGT_SMALL + 1, 0.8, 0.8, 0.8, 1.0, UIFont.Small)
    end
end

---@param self LuaMoodle
LuaMoodle.wiggle = function(self)
    self.oscillationLevel = 1
end

---@param self LuaMoodle
LuaMoodle.cleanup = function(self)
    self:removeFromUIManager()
    self.javaObject:setTable(nil)
    self.javaObject = nil
end

LuaMoodle.updateOscillator = function()
    LuaMoodle.oscillatorStep = LuaMoodle.oscillatorStep + 0.4 * UIManager.getMillisSinceLastRender() / 33.3
    LuaMoodle.oscillator = math.sin(LuaMoodle.oscillatorStep) * 15.6
end

Events.OnPreUIDraw.Add(LuaMoodle.updateOscillator)

return LuaMoodle