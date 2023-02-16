
local module = {}

local Quad = require(script.Quad)

local isTestMode = script.Name:match("testing_")

function module.setTheme(global)
    local isDark
    local hasPermissionToGetSettings = pcall(function()
        isDark = tostring(settings().Studio.Theme) == "Dark"
    end)
    if isDark == nil then isDark = true end

    -- topbar
    global.topbarColor = isDark
        and Color3.fromRGB(142, 21, 255)
        or Color3.fromRGB(163, 65, 255)
    global.topbarTextColor = isDark
        and Color3.fromRGB(255, 255, 255)
        or Color3.fromRGB(0, 0, 0)

    -- background
    global.backgroundColor = isDark
        and Color3.fromRGB(32, 32, 32)
        or Color3.fromRGB(255, 255, 255)

    -- texts
    global.textColor = isDark
        and Color3.fromRGB(255, 255, 255)
        or Color3.fromRGB(0, 0, 0)
    global.editableTextColor = isDark
        and Color3.fromRGB(240, 240, 240)
        or Color3.fromRGB(25, 25, 25)
    global.placeholderTextColor = isDark
        and Color3.fromRGB(170, 170, 170)
        or Color3.fromRGB(124, 124, 124)

    -- init theme chnaged handler
    if hasPermissionToGetSettings and (not global.themeConnection) then
        global.themeConnection = settings().Studio.ThemeChanged:Connect(function()
            module.setTheme(global)
        end)
    end
end

function module.init()
    local quad = Quad.init("ui")
    local round,class,mount,store,event,tween,style
    = quad.round,quad.class,quad.mount,quad.store,quad.event,quad.tween,quad.style

    local frame = class "Frame"
    local gui = class "ScreenGui"

    local global = store.getStore "global"
    local tweenTest = class(script.tween)

    module.setTheme(global)

    gui "MainGui" {
        frame "Main" {
            Size = UDim2.fromOffset(400,640);
            Position = UDim2.fromScale(0.5,0.5);
            AnchorPoint = Vector2.new(0.5,0.5);
            tweenTest{};
        }
    }
    mount(game.StarterGui,store.getObject "MainGui")
    _G.uiinstance = store.getObject "MainGui"
end

function module.deinit()
    if isTestMode then
        local lastInstance = _G.uiinstance
        Quad.uninit("ui")
        if lastInstance then
            lastInstance:Destroy()
        end
        _G.uiinstance = nil
        return
    end
    Quad.uninit("ui")
end

return module
