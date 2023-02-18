
local module = {}

local IsTestMode = script.Name:match("testing_")

local function SetTheme(global)
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
    ---@module Quad.src.types
    local types = require(script.Quad.types)
    local quad = (require(script.Quad) :: types.module).Init("ui")
    local Round,Class,Mount,Store,Event,Tween,Style,Signal
    = quad.Round,quad.Class,quad.Mount,quad.Store,quad.Event,quad.Tween,quad.Style,quad.Signal

    local Frame = Class "Frame"
    local Gui = Class "ScreenGui"

    local Global = Store.GetStore "global"
    local TweenTest = Class(script.tween)
    local LangTest = Class(script.lang)

    Signal.

    SetTheme(Global)

    Gui "MainGui" {
        Frame "Main" {
            Size = UDim2.fromOffset(400,640);
            Position = UDim2.fromScale(0.5,0.5);
            AnchorPoint = Vector2.new(0.5,0.5);
            -- TweenTest{};
            LangTest{};
        }
    }
    Mount(game.StarterGui,Store.GetObject "MainGui")
    _G.uiinstance = Store.GetObject "MainGui"
end

function module.deinit()
    if IsTestMode then
        local lastInstance = _G.uiinstance
        require(script.Parent.Quad).Uninit("ui")
        if lastInstance then
            lastInstance:Destroy()
        end
        _G.uiinstance = nil
        return
    end
    require(script.Parent.Quad).Uninit("ui")
end

return module
