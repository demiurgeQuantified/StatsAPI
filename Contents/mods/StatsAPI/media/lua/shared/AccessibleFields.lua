-- this is added to the same directory as in the main mod so that it doesn't matter which one overrides the other
local bannedClasses = {ArrayList.class, Stack.class}

local getNumClassFields = getNumClassFields
local getClassField = getClassField
local getClassFieldVal = getClassFieldVal
local setmetatable = setmetatable
local match = string.match
local tostring = tostring
local pairs = pairs
local __classmetatables = __classmetatables

for i = 1, #bannedClasses do
    bannedClasses[bannedClasses[i]] = true
    bannedClasses[i] = nil
end

for class, metatable in pairs(__classmetatables) do
    if not bannedClasses[class] and metatable.__index and type(metatable.__index) == "table" then -- something weird in here breaks it, Vector's exposure seems to be bugged?
        local metaMetatable = {}
        
        local getField = function(self, key)
            local fieldGetter = metaMetatable.fieldGetters[key]
            if fieldGetter then
                return fieldGetter(self)
            end
        end
        
        metaMetatable.__index = function(self, key)
            local fieldGetters = {}
            for i = 0, getNumClassFields(self)-1 do
                local field = getClassField(self, i)
                local fieldName = match(tostring(field), "([^%.]+)$")
                fieldGetters[fieldName] = function(self) return getClassFieldVal(self, field) end
            end
            metaMetatable.fieldGetters = fieldGetters
            metaMetatable.__index = getField
            return self[key]
        end
        
        setmetatable(metatable.__index, metaMetatable)
    end
end