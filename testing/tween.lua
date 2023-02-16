
local module = {}

---@module Quad.src.types
local types = require(script.Parent.Quad.types)
local quad = (require(script.Parent.Quad) :: types.module).init("ui")
local round,class,mount,store,event,tween,style
= quad.round,quad.class,quad.mount,quad.store,quad.event,quad.tween,quad.style

local global = store.getStore "global"

-- Import classes
local frame = class "Frame"
frame.BorderSizePixel = 0
frame.BackgroundColor3 = global "backgroundColor"
local textLabel = class "TextLabel"
textLabel.BackgroundTransparency = 1
textLabel.BorderSizePixel = 0
textLabel.Font = Enum.Font.Gotham;
textLabel.TextColor3 = global "textColor"
textLabel.TextSize = 16;

local tweenTestFrameStyle = style "tweenTestFrame" {
    BackgroundTransparency = 0;
    Size = UDim2.fromOffset(60,30);
    BackgroundColor3 = Color3.fromRGB(0, 0, 0);
};

-- Create GUI
local tweenTest = class.extend()

function tweenTest:init(prop)
    prop:default("tweenTest",UDim2.fromOffset(50,0))
    local on = false
    task.spawn(function()
        while wait(2) do
            on = not on
            prop.tweenTest = on and UDim2.new(1,-50-60,0,0) or UDim2.fromOffset(50,0)
        end
    end)
end

function tweenTest:render(prop)
    return frame {
        Size = UDim2.fromScale(1,1);
        textLabel "tweenTestFrame" {
            Text = "Linear";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,80)):tween{Direction = "InOut",Time = 2,Easing = "Linear"};
        };
        textLabel "tweenTestFrame" {
            Text = "Expo";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,120)):tween{Direction = "InOut",Time = 2,Easing = "Expo"};
        };
        textLabel "tweenTestFrame" {
            Text = "Quint";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,160)):tween{Direction = "InOut",Time = 2,Easing = "Quint"};
        };
        textLabel "tweenTestFrame" {
            Text = "Quart";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,200)):tween{Direction = "InOut",Time = 2,Easing = "Quart"};
        };
        textLabel "tweenTestFrame" {
            Text = "Cubic";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,240)):tween{Direction = "InOut",Time = 2,Easing = "Cubic"};
        };
        textLabel "tweenTestFrame" {
            Text = "Quad";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,280)):tween{Direction = "InOut",Time = 2,Easing = "Quad"};
        };
        textLabel "tweenTestFrame" {
            Text = "Sin";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,320)):tween{Direction = "InOut",Time = 2,Easing = "Sin"};
        };
        textLabel "tweenTestFrame" {
            Text = "Circle";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,360)):tween{Direction = "InOut",Time = 2,Easing = "Circle"};
        };
        textLabel "tweenTestFrame" {
            Text = "Exp2";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,400)):tween{Direction = "InOut",Time = 2,Easing = "Exp2"};
        };
        textLabel "tweenTestFrame" {
            Text = "Exp4";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,440)):tween{Direction = "InOut",Time = 2,Easing = "Exp4"};
        };
        textLabel "tweenTestFrame" {
            Text = "Elastic";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,480)):tween{Direction = "InOut",Time = 2,Easing = "Elastic"};
        };
        textLabel "tweenTestFrame" {
            Text = "Bounce";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,520)):tween{Direction = "InOut",Time = 2,Easing = "Bounce"};
        };
        textLabel "tweenTestFrame" {
            Text = "Back";
            Position = prop "tweenTest":add(UDim2.fromOffset(0,560)):tween{Direction = "InOut",Time = 2,Easing = "Back"};
        };
        -- frame {
        --     Size = UDim2.new(100,100);
        --     [event.created] = function(self)
        --         for i = 1,100 do
        --             mount(self,frame{
        --                 Size = UDim2.fromOffset(3,3);
        --                 AnchorPoint = Vector2.new(0.5,0.5);
        --                 Position = UDim2.fromOffset(100-i,tween.CalcEasing(tween.EasingFunctions.Circle,tween.EasingDirections.InOut,i/100)*100);
        --                 BackgroundColor3 = Color3.fromRGB(110, 110, 255);
        --             })
        --         end
        --     end;
        --     BackgroundColor3 = Color3.fromRGB(0,0,0);
        -- };
    }
end

return tweenTest
