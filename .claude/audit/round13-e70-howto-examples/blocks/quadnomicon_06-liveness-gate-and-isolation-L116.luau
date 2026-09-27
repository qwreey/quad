-- 백엔드: isHeld
local function isHeld(value: any): boolean
    local gcconn = BindData:GetWeak(value, "gcconn")
    return gcconn ~= nil and gcconn.Connected == true
end

-- quad-base: isBoundAlive (비공개), canBound, canExecute
local function isBoundAlive(value: any): boolean
    if value == nil then
        return false
    end
    if Backend.isHeld(value) then
        return true
    end
    if isObserver(value) or isEffect(value) then
        return value.Subscribed == true
    end
    return false
end

local function canBound(value: any): boolean
    return not isBoundAlive(value)
end

local function canExecute(value: any): boolean
    return isBoundAlive(value)
end
