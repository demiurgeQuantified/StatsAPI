-- because of the cost of calling java functions, reimplementing the math functions in lua is much more performant
-- e.g. this module's min runs ~9x faster than math.min
local Math = {}

---Returns the largest of two arguments.
---@param a number
---@param b number
---@return number
---@see math.max
Math.max = function(a, b)
    if a > b then
        return a
    end
    return b
end

---Returns the smallest of two arguments.
---@param a number
---@param b number
---@return number
---@see math.min
Math.min = function(a, b)
    if a < b then
        return a
    end
    return b
end

---Returns num if it is between min and max, otherwise returns min if it is too low or max if it is too high.
---@param num number
---@param min number
---@param max number
---@return number
Math.clamp = function(num, min, max)
    if num < min then
        return min
    elseif num > max then
        return max
    end
    return num
end

---Returns the nearest integer less than/equal to num (rounds it down).
---@param num number
---@return number
Math.floor = function(num)
    return num - num % 1
end

return Math