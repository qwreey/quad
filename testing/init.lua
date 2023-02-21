
local module = {}

local IsTestMode = script.Name:match("_TESTING")

local Quad = require(script.Quad).Init()
local LocalPlayer = game.Players.LocalPlayer
local ScreenGUI = Instance.new("ScreenGui",
    LocalPlayer and LocalPlayer.PlayerGui or game.StarterGui)
ScreenGUI.Name = "MyGUI"
ScreenGUI.ResetOnSpawn = false

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

---@module src.types
local types = require(script.Quad.types)
local quad = (require(script.Quad) :: types.module).Init("ui")
local Round,Class,Mount,Store,Event,Tween,Style,Signal
= quad.Round,quad.Class,quad.Mount,quad.Store,quad.Event,quad.Tween,quad.Style,quad.Signal

local Frame = Class "Frame"
local Gui = Class "ScreenGui"

local Global = Store.GetStore "global"
local TweenTest = Class(script.tween)
-- local LangTest = Class(script.lang)

SetTheme(Global)

local mainMount = Mount(ScreenGUI,Frame "Main" {
    Size = UDim2.fromOffset(400,640);
    Position = UDim2.fromScale(0.5,0.5);
    AnchorPoint = Vector2.new(0.5,0.5);
    TweenTest{};
    -- LangTest{};
})

return function()
    -- 테스트가 끝나 만든걸 지워야 할 때 사용됩니다.
    -- 추후 설명될 Unmount() 를 이용하세요.
    mainMount:Unmount()
    ScreenGUI:Destroy()
end
