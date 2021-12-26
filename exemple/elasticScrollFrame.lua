local Quad = require(game.ReplicatedStorage:WaitForChild "Quad"); ---@module Quad.src
local _ = Quad.init "IosUI"; local round,class,mount,store,event,advancedTween = _.round,_.class,_.mount,_.store,_.event,_.advancedTween;

-- init quad
local scrollFrame = class.extend();
local connection = event.new;

-- const
local white = Color3.fromRGB(255,255,255);
local scrollMut = 100;
local elasticMut = 20;
local fitTime = 0.22;
local tweenTime = 0.63;
local mouseUpMut = 42;
local max = math.max;
local min = math.min;
local abs = math.abs;

-- base objects
local frame = class "Frame";
frame.BorderSizePixel = 0;
local button = class "TextButton";
button.BorderSizePixel = 0;
button.Text = nil;
local image = class "ImageLabel";

-- tween for moving
local out = advancedTween.EasingDirections.Out;
local exp2 = advancedTween.EasingFunctions.Exp2;
local tweenData = {
    Time = tweenTime;
    Direction = out;
    EasingFunction = exp2;
};
local runTween = advancedTween.RunTween;

-- user input service
local userInputService = game:GetService "UserInputService";
local inputEnded = userInputService.InputEnded;
local inputChanged = userInputService.InputChanged;
local mouseMovement = Enum.UserInputType.MouseMovement;
local mouseWheel = Enum.UserInputType.MouseWheel;
local shiftModifier = Enum.ModifierKey.Shift;
local mouseButton1 = Enum.UserInputType.MouseButton1;
local touch = Enum.UserInputType.Touch;

-- Calc Elastic
local calcElastic do
    local maxLogX = 32;
    local mlog = math.log;
    local maxlog = mlog(maxLogX+1,2);
    local function log(x)
        return min(mlog(x*maxLogX+1,2),maxlog)/maxlog;
    end
    function calcElastic (elastic,pos,max)
        if pos < 0 then
            return - (log(abs(pos)/scrollMut*elasticMut/elastic)*elastic);
        elseif pos > max then
            return max + (log((pos-max)/scrollMut*elasticMut/elastic)*elastic);
        end
        return pos;
    end
end

-- Init class
function scrollFrame:init(props)
    local CanvasPosition = props.CanvasPosition or Vector2.new(0,0);
    self._targetX = CanvasPosition.X;
    self._targetY = CanvasPosition.Y;
    props.CanvasPosition = CanvasPosition;
    self._inputIndex = -20000000;
    self._mouseConnection = connection();
    props:default("CanvasPosition",CanvasPosition);
    props:default("CanvasSize",UDim2.fromScale(1,2));
    props:default("Size",UDim2.new(1,0,1,0));
    props:default("Position",UDim2.new(0,0,0,0));
    props:default("Elastic",122);
    props:default("OverscrollX",false);
    props:default("OverscrollY",true);
    props:default("BackgroundTransparency",1);
    props:default("ZIndex",1);
    props:default("BackgroundColor3",white);
    props:default("ScrollbarSizeX",2);
    props:default("ScrollbarVisibleY",false);
    props:default("ScrollbarSizeX",2);
    props:default("ScrollbarVisibleX",true);
    props:default("ScrollbarPadding",2);
    props:default("ScrollbarColor3",Color3.fromRGB(172, 172, 172));
    props:default("ScrollbarTransparency",0.5);
end

-- Render objects
function scrollFrame:render(props)
    return button {
        Size = props "Size";
        Position = props "Position";
        BackgroundTransparency = props "BackgroundTransparency";
        BackgroundColor3 = props "BackgroundColor3";
        ZIndex = props "ZIndex";
        ClipsDescendants = true;
        [event.createdSync] = function (this)
            this.InputChanged:Connect(function (input)
                if self._mouseDown or self._scrollbarDown then
                    return;
                end
                local inputType = input.UserInputType;
                if inputType == mouseWheel then
                    local x,y = 0,1;
                    if input:IsModifierKeyDown(shiftModifier) then
                        x,y = 1,0;
                    end
                    local scroll = input.Position.Z * scrollMut;
                    local inputIndex = self:update(self._targetX + x*scroll,self._targetY - y*scroll);
                    delay(fitTime,function ()
                        if inputIndex == self._inputIndex then
                            self:fit();
                        end
                    end);
                end
            end);
        end;
        [event "MouseButton1Down"] = function (this,downX,downY)
            self._mouseDown = true;
            local mouseConnection = self._mouseConnection;
            mouseConnection:disconnect();
            mouseConnection:add(inputEnded:Connect(function (input)
                self._mouseDown = false;
                local inputType = input.UserInputType;
                if inputType == mouseButton1 or inputType == touch then
                    local position = input.Position;
                    local x = position.X;
                    local y = position.Y;
                    self:update(self._targetX + ((x - downX) * mouseUpMut),self._targetY + ((- y + downY)*mouseUpMut));
                    mouseConnection:disconnect();
                    self:fit();
                end
            end));
            mouseConnection:add(inputChanged:Connect(function (input)
                if input.UserInputType == mouseMovement then
                    local position = input.Position;
                    local x = position.X;
                    local y = position.Y;
                    local inputIndex = self:update(self._targetX + x - downX,self._targetY - y + downY);
                    delay(fitTime,function ()
                        if inputIndex == self._inputIndex then
                            self:fit();
                        end
                    end);
                    downX,downY = x,y;
                end
            end));
        end;
        frame {
            [event.prop "AbsoluteSize"] = function ()
                self:fit();
            end;
            BackgroundTransparency = 1;
            Size = props "CanvasSize";
            ZIndex = props "ZIndex";
            Position = UDim2.fromOffset(self._targetX,self._targetY);
            [event.createdSync] = function (this)
                self._holder = this;
            end;
        };
        button {
            Visible = props "ScrollbarVisibleY";
            Size = props "ScrollbarPadding,ScrollbarSizeX":with(function (store)
                self:fit();
            end);
            image {
                roundSize = 2000;
                ImageColor3 = props "ScrollbarColor3";
                ImageTransparency = props "ScrollbarTransparency";
                Size = props "ScrollbarSizeX,ScrollbarPadding":with(function (store)
                    return UDim2.new(0,store.ScrollbarSizeX,1,store.ScrollbarPadding * 2);
                end);
                Position = UDim2.fromScale(0.5,0.5);
                AnchorPoint = Vector2.new(0.5,0.5);
            };
        }
    };
end

-- Set scroll position with allowing overflow
function scrollFrame:update(x,y)
    x,y = x or self._targetX,y or self._targetY;
    local inputIndex = self._inputIndex + 1;
    self._inputIndex = inputIndex;

    local holder = self._holder;
    local holderAbsSize = holder.AbsoluteSize;
    local objectAbsSize = self.__object.AbsoluteSize;
    local maxX = holderAbsSize.X - objectAbsSize.X;
    local maxY = holderAbsSize.Y - objectAbsSize.Y;

    local elastic = self.Elastic;
    x = self.OverscrollX and calcElastic(elastic,x,maxX) or max(min(maxX,x),0);
    y = self.OverscrollY and calcElastic(elastic,y,maxY) or max(min(maxY,y),0);

    runTween(self._holder,tweenData,{
        Position = UDim2.fromOffset(x,-y);
    });
    self._targetX,self._targetY = x,y;
    self:updateScrollbar(x,y);
    return inputIndex;
end

-- Get canvas position
function scrollFrame.getter:CanvasPosition()
    return Vector2.new(self._targetX,self._targetY);
end

-- Set canvas postion
function scrollFrame.setter:CanvasPosition(pos)
    local inputIndex = self:update(pos.X,pos.Y);
    delay(fitTime,function ()
        if inputIndex == self._inputIndex then
            self:fit();
        end
    end);
end

-- Fit position (remove overflow)
function scrollFrame:fit()
    local targetY = self._targetY;
    local targetX = self._targetX;
    local holder = self._holder;
    local holderAbsoluteSize = holder.AbsoluteSize;
    local objectAbsSize = self.__object.AbsoluteSize;
    local maxX = holderAbsoluteSize.X - objectAbsSize.X;
    local maxY = holderAbsoluteSize.Y - objectAbsSize.Y;
    if targetX<0 or targetY<0 or targetX>maxX or targetY>maxY then
        self:update(
            max(min(targetX,maxX),0),
            max(min(targetY,maxY),0)
        );
    else
        self:updateScrollbar(targetX,targetY);
    end
end

return scrollFrame;
