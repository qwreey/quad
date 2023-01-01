local quad = require(script.Parent.quad);
local render = quad.init();
local class = render.class;
local event = render.event;

local myButton = class.extend(); -- 클래스 만들기
local imageButton = class.import "ImageButton"; -- 로블 인스턴스 클래스화
local textLabel = class.import "TextLabel";
local textButton = class.import "TextButton";

-- 인스턴스의 기본값 설정
imageButton.BackgroundTransparency = 1;
textButton.BorderSizePixel = 0;
textLabel.Size = UDim2.fromScale(1,1);
textLabel.BackgroundTransparency = 1;

-- 기본 값 설정
function myButton:init(props)
    props.style = props.style or "round"; -- flat ...
    props.roundSize = props.roundSize or 12;
    props.Text = props.Text or "Button Text";
    props.Size = props.Size or UDim2.fromOffset(120,32);
end

-- 렌더링
function myButton:render(props)
    if props.style == "round" then
        return imageButton {
            Size = props "Size";
            Image = "http://www.roblox.com/asset/?id=4668069300";
            ScaleType = Enum.ScaleType.Slice;
            SliceCenter = Rect.new(Vector2.new(516,516),Vector2.new(516,516));
            SliceScale = props "roundSize":with(function (value)
                return 0.0019166666666667 * props.roundSize;
            end);
            [event "MouseButton1Click"] = {
                self = self;
                func = props.MouseButton1Click;
            };
            textLabel {
                Text = props "Text";
            };
        };
    elseif props.style == "flat" then
        return textButton {
            Size = props "Size";
            BorderSizePixel = 2;
        }
    else error ("unknown style " .. props.style);
    end
end

myButton.updateTriggers.style = true;

return myButton
