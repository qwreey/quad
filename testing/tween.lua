
local module = {}

---@module Quad.src.types
local types = require(script.Parent.Quad.types)
local quad = (require(script.Parent.Quad) :: types.module).Init("ui")
local Round,Class,Mount,Store,Event,Tween,Style,Lang
= quad.Round,quad.Class,quad.Mount,quad.Store,quad.Event,quad.Tween,quad.Style,quad.Lang

local Global = Store.GetStore "global"

-- Import classes
local Frame = Class "Frame"
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Global "backgroundColor"
local TextLabel = Class "TextLabel"
TextLabel.BackgroundTransparency = 1
TextLabel.BorderSizePixel = 0
TextLabel.Font = Enum.Font.Gotham;
TextLabel.TextColor3 = Global "textColor"
TextLabel.TextSize = 16;

Style "tweenTestFrame" {
    BackgroundTransparency = 0;
    Size = UDim2.fromOffset(60,30);
    BackgroundColor3 = Color3.fromRGB(0, 0, 0);
}

Lang.New("tweenCount",{
    [Lang.Locales.Korean] = "{count}번 실행했어요";
    [Lang.Locales.Default] = "Ran {count} times";
})

-- Create GUI
local tweenTest = Class.Extend()

function tweenTest:Init(Prop)
    Prop:Default("Count",0)
    Prop:Default("Position",UDim2.fromOffset(50,0))
    local on = false
    task.spawn(function()
        while task.wait(2) do
            on = not on
            Prop.Count = Prop.Count + 1
            Prop.Position = on and UDim2.new(1,-50-60,0,0) or UDim2.fromOffset(50,0)
        end
    end)
end

function tweenTest:Render(Prop)
    return Frame {
        TextLabel {
            Size = UDim2.new(1,0,0,30);
            Text = Lang "tweenCount" {
                count = Prop "Count";
            };
        };
        Size = UDim2.fromScale(1,1);
        TextLabel "tweenTestFrame" {
            Text = "Linear";
            Position = Prop "Position":Add(UDim2.fromOffset(0,80)):Tween{Direction = "InOut",Time = 2,Easing = "Linear"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Expo";
            Position = Prop "Position":Add(UDim2.fromOffset(0,120)):Tween{Direction = "InOut",Time = 2,Easing = "Expo"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Quint";
            Position = Prop "Position":Add(UDim2.fromOffset(0,160)):Tween{Direction = "InOut",Time = 2,Easing = "Quint"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Quart";
            Position = Prop "Position":Add(UDim2.fromOffset(0,200)):Tween{Direction = "InOut",Time = 2,Easing = "Quart"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Cubic";
            Position = Prop "Position":Add(UDim2.fromOffset(0,240)):Tween{Direction = "InOut",Time = 2,Easing = "Cubic"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Quad";
            Position = Prop "Position":Add(UDim2.fromOffset(0,280)):Tween{Direction = "InOut",Time = 2,Easing = "Quad"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Sin";
            Position = Prop "Position":Add(UDim2.fromOffset(0,320)):Tween{Direction = "InOut",Time = 2,Easing = "Sin"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Circle";
            Position = Prop "Position":Add(UDim2.fromOffset(0,360)):Tween{Direction = "InOut",Time = 2,Easing = "Circle"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Exp2";
            Position = Prop "Position":Add(UDim2.fromOffset(0,400)):Tween{Direction = "InOut",Time = 2,Easing = "Exp2"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Exp4";
            Position = Prop "Position":Add(UDim2.fromOffset(0,440)):Tween{Direction = "InOut",Time = 2,Easing = "Exp4"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Elastic";
            Position = Prop "Position":Add(UDim2.fromOffset(0,480)):Tween{Direction = "InOut",Time = 2,Easing = "Elastic"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Bounce";
            Position = Prop "Position":Add(UDim2.fromOffset(0,520)):Tween{Direction = "InOut",Time = 2,Easing = "Bounce"};
        };
        TextLabel "tweenTestFrame" {
            Text = "Back";
            Position = Prop "Position":Add(UDim2.fromOffset(0,560)):Tween{Direction = "InOut",Time = 2,Easing = "Back"};
        };
        Frame {
            Size = UDim2.new(100,100);
            [Event.Created] = function(self)
                for j = 1,25 do
                    local i = j*4
                    Mount(self,Frame{
                        Size = UDim2.fromOffset(3,3);
                        AnchorPoint = Vector2.new(0.5,0.5);
                        Position = UDim2.fromOffset(100-i,Tween.CalcEasing(Tween.EasingFunctions.Circle,Tween.EasingDirections.InOut,i/100)*100);
                        BackgroundColor3 = Color3.fromRGB(110, 110, 255);
                    })
                end
            end;
            BackgroundColor3 = Color3.fromRGB(0,0,0);
        };
    }
end

return tweenTest
