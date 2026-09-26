--!strict
-- GS 12#4 → 12#6 → 13#5 → 14 Main → 15#2 → 16#1/#4/#7 — E56 주석판
local Players = game:GetService("Players")
const q = require("./Quad")
const D = q.Declaration
const playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
const screen = D.ScreenGui { ResetOnSpawn = false }
do -- 12 row + 12#9 + 13#5
    const Counter = require("./Counter13")
    const row = D.Frame {
        D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },
        Counter { Label = "왼쪽", Start = 0,
            Watch = function(count: q.State<number>): q.Effect -- [§6 콜백 파라미터 — 핸들 타입; 13장 strict 판 "넘겨받는 핸들의 타입"]
                return q.Effect(function()
                    print("왼쪽 카운터:", count:Get())
                    return function() print("왼쪽 카운터 정리") end
                end, count)
            end,
        },
        Counter {
            Label = "오른쪽",
            Start = 10,
            Children = q.Slot<<Instance>>({ -- [08§7 / GS11 strict 접이]
                D.TextLabel { Text = "덤으로 붙는 자식", TextSize = 12 },
            }),
        },
    }
    row.Parent = screen
    const Counter12 = require("./Counter12")
    const row12 = D.Frame { Counter12 { Label = "왼쪽", Start = 0 }, Counter12 { Label = "오른쪽", Start = 10 } }
    print(row12)
end
do -- 12#6/#7
    const Checkbox = require("./Checkbox")
    const agreed = q.Source(false)
    const statusText: q.State<string> = agreed:Compute(function(c: q.StateData<boolean>): string return if c:Get() then "켜짐" else "꺼짐" end) -- [§6]
    const panel = D.Frame {
        D.UIListLayout { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4) },
        Checkbox { Label = "약관에 동의합니다", Value = agreed },
        D.TextLabel { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180, 180, 190), Text = statusText },
    }
    panel.Parent = screen
    const readOnly: q.State<boolean> = agreed:Compute(function(c: q.StateData<boolean>): boolean return c:Get() end) -- [§6]
    print(readOnly)
end
do -- 14~16 Main
    const rows = q.Source({
        { Id = "a", Label = "왼쪽", Start = 0 },
        { Id = "b", Label = "오른쪽", Start = 10 },
    })
    const settings = q.Store({ Step = q.Source(1) })
    print(settings.Step:Get())
    settings.Step:Set(5)
    const Theme = require("./Theme")
    const Settings = require("./Settings")
    const ctx = q.Context()
        :Set(Theme.Provider, { Accent = Color3.fromRGB(0, 162, 255) })
        :Set(Settings.Provider, settings)
    const CounterBoard = require("./CounterBoard")
    const board = CounterBoard { Rows = rows, Ctx = ctx }
    board.Parent = screen
    const stepButton = D.TextButton {
        Size = UDim2.fromOffset(120, 32),
        Text = settings.Step:Compute(function(s: q.StateData<number>)
            return `보폭: {s:Get()}`
        end),
        Activated = function()
            settings.Step:Set(settings.Step:Get() % 5 + 1)
        end,
    }
    stepButton.Parent = screen
    const Counter17b = require("./Counter17b")
    const Counter18 = require("./Counter18")
    print(Counter17b { Label = "x", Start = 0 }, Counter18())
    const ThemeTyped = require("./ThemeTyped")
    const tctx = q.Context():Set(ThemeTyped.Provider, { Accent = Color3.fromRGB(1, 2, 3) })
    const accent: Color3 = tctx:Get(ThemeTyped.Provider).Accent
    print(accent)
end
screen.Parent = playerGui
