local Quad = require(game.ReplicatedStorage:WaitForChild "Quad"); ---@module "Quad.src"
local _ = Quad.init "components"; local round,class,mount,store,event,tween = _.round,_.class,_.mount,_.store,_.event,_.tween;
local RunService = game:GetService"RunService";
local IsRunning = RunService:IsRunning();
local max = math.max;
local min = math.min;
local abs = math.abs;

-- init quad
local scrollFrame = class.extend();
local connection = event.new;
local frame = class "Frame";
frame.BorderSizePixel = 0;
local button = class "TextButton";
button.BorderSizePixel = 0;
button.Text = "";
button.AutoButtonColor = false;
local image = class "ImageLabel";
image.BackgroundTransparency = 1;

-- const
local white            = Color3.fromRGB(255,255,255);
local scrollMut        = 100;  -- Used for multiply input when using mosue scroll
local elasticMut       = 18;   -- Used for multiply input when overscrolling
local fitTime          = 0.26; -- Used for reset overscroll when mouse scroll
local tweenTime        = 0.71; -- Used for tween time
local mouseUpMut       = 6;   -- Used for multiply input when drag input ended
local scrollbarOverMut = 0.18; -- Used for multiply size of scrollbar when overscrolling

-- tween for moving
local out = tween.EasingDirections.Out;
local exp2 = tween.EasingFunctions.Exp2;
local tweenData = {
	Time = tweenTime;
	Direction = out;
	EasingFunction = exp2;
};
local runTween = tween.RunTween;
local stopTween = tween.StopTween;

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
	local maxLogX = 30;
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
	self._overscrollX = false;
	self._overscrollY = false;
	props:default("CanvasPosition",CanvasPosition);
	props:default("CanvasSize",UDim2.fromScale(1,2));
	props:default("Size",UDim2.new(1,0,1,0));
	props:default("Position",UDim2.new(0,0,0,0));
	props:default("Elastic",142);
	props:default("OverscrollX",false);
	props:default("OverscrollY",true);
	props:default("BackgroundTransparency",0);
	props:default("ZIndex",1);
	props:default("BackgroundColor3",white);
	props:default("ScrollbarSizeX",2);
	props:default("ScrollbarPositionY","Right");
	props:default("ScrollbarPositionX","Bottom");
	props:default("ScrollbarVisibleY",true);
	props:default("ScrollbarSizeY",2);
	props:default("ScrollbarVisibleX",true);
	props:default("ScrollbarPadding",2);
	props:default("ScrollbarColor3",Color3.fromRGB(145, 145, 145));
	props:default("ScrollbarTransparency",0.3);
	-- props "ScrollbarPadding":register(function ()
	--	 self:fit();
	--	 self.__prop
	-- end);
	-- props "ScrollbarPadding":register(function ()
	--	 self:fit();
	--	 self.__prop
	-- end);
	-- ScrollbarSizeX
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
		[event.created] = function (this)
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
			local lastX,lastY = self._targetX,self._targetY;
			local upX,upY = downX,downY;
			self._mouseDown = true;
			local mouseConnection = self._mouseConnection;
			mouseConnection:disconnect();
			mouseConnection:add(inputEnded:Connect(function (input)
				self._mouseDown = false;
				local inputType = input.UserInputType;
				if inputType == mouseButton1 or inputType == touch then
					local position = input.Position;
					local x = position.X;
					local y = position.Y + (IsRunning and 36 or 0);
					self:update(self._targetX + ((x - upX) * mouseUpMut),self._targetY + ((- y + upY)*mouseUpMut));
					mouseConnection:disconnect();
					self:fit();
				end
			end));
			mouseConnection:add(inputChanged:Connect(function (input)
				if input.UserInputType == mouseMovement then
					local position = input.Position;
					local x,y = position.X,position.Y + (IsRunning and 36 or 0);

					self:update(lastX + (downX - x),lastY + (downY - y));
					upX,upY = x,y;
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
			[event.created] = function (this)
				self._holder = this;
			end;
		};
		button {
			AnchorPoint = props "ScrollbarPositionY":with(function (_,value)
				return value == "Right" and Vector2.new(1,0) or Vector2.new(0,0);
			end);
			[event.created] = function (this)
				self._scrollbarY = this;
			end;
			Position = props.ScrollbarPositionY == "Right" and UDim2.new(1,0,0,0) or UDim2.new(0,0,0,0);
			BackgroundTransparency = 1;
			Visible = props "ScrollbarVisibleY";
			image {
				roundSize = 2000;
				ImageColor3 = props "ScrollbarColor3";
				ImageTransparency = props "ScrollbarTransparency";
				Size = props "ScrollbarSizeY,ScrollbarPadding":with(function (store)
					return UDim2.new(0,store.ScrollbarSizeY,1,store.ScrollbarPadding * -2);
				end);
				Position = UDim2.fromScale(0.5,0.5);
				AnchorPoint = Vector2.new(0.5,0.5);
			};
		};
		button {
			AnchorPoint = props "ScrollbarPositionX":with(function (_,value)
				return value == "Top" and Vector2.new(0,0) or Vector2.new(0,1);
			end);
			[event.created] = function (this)
				self._scrollbarX = this;
			end;
			Position = props.ScrollbarPositionX == "Top" and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,0);
			BackgroundTransparency = 1;
			Visible = props "ScrollbarVisibleX";
			image {
				roundSize = 2000;
				ImageColor3 = props "ScrollbarColor3";
				ImageTransparency = props "ScrollbarTransparency";
				Size = props "ScrollbarSizeX,ScrollbarPadding":with(function (store)
					return UDim2.new(1,store.ScrollbarPadding * -2,0,store.ScrollbarSizeX);
				end);
				Position = UDim2.fromScale(0.5,0.5);
				AnchorPoint = Vector2.new(0.5,0.5);
			};
		};
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
	local holderX,holderY = holderAbsSize.X,holderAbsSize.Y;
	local objectX,objectY = objectAbsSize.X,objectAbsSize.Y;
	holderX,holderY = max(holderX,objectX),max(holderY,objectY);
	local maxX = holderX - objectX;
	local maxY = holderY - objectY;

	local elastic = self.Elastic;
	x = self.OverscrollX and calcElastic(elastic,x,maxX) or max(min(maxX,x),0);
	y = self.OverscrollY and calcElastic(elastic,y,maxY) or max(min(maxY,y),0);

	local overflowX = (x<0 and -1) or (x>maxX and 1);
	local overflowY = (y<0 and -1) or (y>maxY and 1);
	self._overscrollX = overflowX;
	self._overscrollY = overflowY;

	runTween(holder,tweenData,{
		Position = UDim2.fromOffset(-x,-y);
	});
	self._targetX,self._targetY = x,y;
	self:updateScrollbar(
		x,y,objectX,objectY,holderX,holderY,elastic,
		(overflowX == -1 and abs(x)) or (overflowX == 1 and x-maxX),
		(overflowY == -1 and abs(y)) or (overflowY == 1 and y-maxY)
	);
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
	local objectX,objectY = objectAbsSize.X,objectAbsSize.Y;
	local maxX = max(holderAbsoluteSize.X,objectX) - objectX;
	local maxY = max(holderAbsoluteSize.Y,objectY) - objectY;
	if targetX<0 or targetY<0 or targetX>maxX or targetY>maxY then
		self:update(
			max(min(targetX,maxX),0),
			max(min(targetY,maxY),0)
		);
	else
		self:updateScrollbar(targetX,targetY);
	end
end

-- update scrollbar
function scrollFrame:updateScrollbar(x,y,objectX,objectY,holderX,holderY,elastic,overflowX,overflowY)
	local scrollbarY = self._scrollbarY;
	local scrollbarX = self._scrollbarX;

	local objectSize;
	if not objectY then
		objectSize = self.__object.AbsoluteSize;
		objectY = objectSize.Y;
	end
	if not objectX then
		if not objectSize then
			objectSize = self.__object.AbsoluteSize;
		end
		objectX = objectSize.X;
	end

	local holderSize;
	if not holderY then
		holderSize = self._holder.AbsoluteSize;
		holderY = max(holderSize.Y,objectY);
	end
	if not holderX then
		if not holderSize then
			holderSize = self._holder.AbsoluteSize;
		end
		holderX = max(holderSize.X,objectX);
	end

	elastic = elastic or self.Elastic;
	if scrollbarY then
		local size;
		if objectY >= holderY then
			size = 0;
		else
			size = objectY / holderY;
			if overflowY then
				size = size * (1-overflowY/elastic) * scrollbarOverMut;
			end
		end
		local sizeUdim = UDim2.new(0,self.ScrollbarSizeY+(self.ScrollbarPadding*2),size,0);
		local pos = 0;
		if size ~= 0 then
			pos = (1-size)*(min(max(y/(holderY-objectY),0),1));
		end
		local posUdim = UDim2.new(self.ScrollbarPositionY == "Right" and 1 or 0,0,pos,0);
		if self._mouseDown then
			stopTween(scrollbarY);
			scrollbarY.Position = posUdim;
			scrollbarY.Size = sizeUdim;
		else
			runTween(scrollbarY,tweenData,{
				Position = posUdim;
				Size = sizeUdim;
			});
		end
	end
	if scrollbarX then
		local size;
		if objectX >= holderX then
			size = 0;
		else
			size = objectX / holderX;
			if overflowX then
				size = size * (1-overflowX/elastic) * scrollbarOverMut;
			end
		end
		local sizeUdim = UDim2.new(size,0,0,self.ScrollbarSizeX+(self.ScrollbarPadding*2));
		local pos = 0;
		if size ~= 0 then
			pos = (1-size)*(min(max(x/(holderX-objectX),0),1));
		end
		local posUdim = UDim2.new(pos,0,self.ScrollbarPositionX == "Top" and 0 or 1,0);
		if self._mouseDown then
			stopTween(scrollbarX);
			scrollbarX.Position = posUdim;
			scrollbarX.Size = sizeUdim;
		else
			runTween(scrollbarX,tweenData,{
				Position = posUdim;
				Size = sizeUdim;
			});
		end
	end
end

return scrollFrame;
