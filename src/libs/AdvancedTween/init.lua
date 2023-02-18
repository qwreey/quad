---@class quad_module_tween
local module = {}

------------------------------------
-- 기본함수, 필요 모듈 가져오기
------------------------------------
local type = typeof or type
local clock = os.clock
local tonumber = tonumber
local remove = table.remove
local insert = table.insert
local find = table.find
local floor = math.floor

if not find then
	find = function (table,item)
		for i,v in pairs(table) do
			if v == item then return i end
		end
		return nil
	end
end

local script = script
local EasingFunctions = require(script and script.EasingFunctions or "EasingFunctions")
local Stepped = require(script and script.Stepped or "Stepped")

local BindedFunctions = {} -- 애니메이션을 위해 프레임에 연결된 함수들
local FunctionTargetItem = setmetatable({},{__mode="kv"}) -- 함수가 타겟으로 하는 아이템

module.PlayIndex = setmetatable({},{__mode = "k"}) -- 애니메이션 실행 스택 저장하기
-- PlayIndex[Item][Property] = 0 or nil <= 트윈중이지 않은 속성
-- PlayIndex[Item][Property] = 1... <= 트윈중인 속성

------------------------------------
-- Easing 스타일
------------------------------------
module.EasingFunctions = {
	Linear = EasingFunctions.Linear; ---직선, Linear. i=x, x=0 ~ 1
	Quint = EasingFunctions.Quint; ---5제곱, Quint. (^5) i=1-(1-x)^5, x=0 ~ 1
	Quart = EasingFunctions.Quart; ---4제곱, Quart. (^4) i=1-(1-x)^4, x=0 ~ 1
	Cubic = EasingFunctions.Cubic; ---3제곱, Cubic. (^3) i=1-(1-x)^3, x=0 ~ 1
	Quad = EasingFunctions.Quad; ---2제곱, Quad. (^2) i=1-(1-x)^2, x=0 ~ 1
	Sin = EasingFunctions.Sin; ---사인파, Sin. i=sin(x*pi/2), x=0 ~ 1
	Circle = EasingFunctions.Circle; ---사분원, Circle. i=sqrt(1-(1-x)^2), x=0 ~ 1
	Expo = EasingFunctions.Expo; ---지수함수, Expo. i=1-2^(-10*x), x=0~1
	Elastic = EasingFunctions.Elastic; ---튀어오름, Elastic.
	Bounce = EasingFunctions.Bounce; ---통통거림, Bounce

	-- Old things
	Exp2 = EasingFunctions.Exp2; ---덜 가파른 지수. i=math.exp(x), x=-4 ~ 2
	Exp4 = EasingFunctions.Exp4; ---더 가파른 지수. i=math.exp(x), x=-4 ~ 4
	Exp2Max4 = EasingFunctions.Exp2; ---@deprecated
}
for i,v in pairs(EasingFunctions) do
	module.EasingFunctions[i] = v
end

module.EasingDirections = {
	Out = "Out"; -- 반전된 방향
	In  = "In" ; -- 기본방향
	InOut = "InOut"; -- 두 방향 모두 가감속
}

---@deprecated
module.EasingDirection = module.EasingDirections
---@deprecated
module.EasingFunction = module.EasingFunctions

------------------------------------
-- Lerp 함수
------------------------------------
-- 이중 선형, Alpha 를 받아서 값을 구해옴
local function Lerp(start,goal,alpha)
	if alpha == 1 then return goal end
	if alpha == 0 then return start end
	return start + ((goal - start) * alpha)
end

-- 기본적으로 로블록스가 Lerp 를 지원하는 Class
local DefaultLerpableItems = {
	["Vector2"] = true;
	["Vector3"] = true;
	["CFrame" ] = true;
}

-- 예전 값,목표 값,알파를 주고 각각 해당하는 속성에 입력해줌
-- 기본적으로 모든 속성값 적용은 여기에서 이루워짐
local function LerpProperties(Item,Old,New,Alpha,Setter)
	for Property,OldValue in pairs(Old) do
		local NewValue = New[Property]
		local Type = type(OldValue)
		local Value
		if Type ~= type(NewValue) then
			error(
				("Unable to lerp property '%s' of '%s' due to type invalid. Old value type is '%s'. but New value type is '%s'")
				:format(
					tostring(Type),
					tostring(type(NewValue))
				)
			)
		elseif DefaultLerpableItems[Type] then
			Value = OldValue:Lerp(NewValue,Alpha)
		elseif Type == "number" then
			Value = Lerp(OldValue,NewValue,Alpha)
		elseif Type == "UDim2" then
			Value = UDim2.new(
				Lerp(OldValue.X.Scale ,NewValue.X.Scale ,Alpha),
				Lerp(OldValue.X.Offset,NewValue.X.Offset,Alpha),
				Lerp(OldValue.Y.Scale ,NewValue.Y.Scale ,Alpha),
				Lerp(OldValue.Y.Offset,NewValue.Y.Offset,Alpha)
			)
		elseif Type == "UDim" then
			Value = UDim.new(
				Lerp(OldValue.Scale ,NewValue.Scale ,Alpha),
				Lerp(OldValue.Offset,NewValue.Offset,Alpha)
			)
		elseif Type == "Color3" then
			Value = Color3.fromRGB(
				Lerp(floor(OldValue.r*255),floor(NewValue.r*255) ,Alpha),
				Lerp(floor(OldValue.g*255),floor(NewValue.g*255),Alpha),
				Lerp(floor(OldValue.b*255),floor(NewValue.b*255) ,Alpha)
			)
		else
			error(
				("Unable to lerp property '%s' of '%s'. Old value type is '%s'. but tweenable types are UDim2, UDim, Color3, Vector2, Vector3, CFrame, number only")
				:format(
					tostring(Property),
					tostring(Item),
					tostring(Type)
				)
			)
		end
		if Setter then
			Setter(Item,Property,Value)
		else
			Item[Property] = Value
		end
	end
end
module.LerpProperties = LerpProperties

-- Easing 값을 계산함
local function CalcEasing(Easing,Direction,Reverse,Index)
	if Index >= 1 then
		return 1
	elseif Direction == "Out" then
		if Reverse then
			return 1 - Easing(1 - Index)
		else
			return Easing(Index)
		end
	elseif Direction == "In" then
		if Reverse then
			return Easing(Index)
		else
			return 1 - Easing(1 - Index)
		end
	elseif Direction == "InOut" then
		if Index<0.5 then
			-- In
			if Reverse then
				return Easing(Index*2)/2
			else
				return 0.5 - Easing(1 - Index*2)/2
			end
		else
			-- Out
			if Reverse then
				return 1 - Easing(2-Index*2)/2
			else
				return Easing(Index*2-1)/2+0.5
			end
		end
	end
end
function module.CalcEasing(Data_Easing,Direction,X)
	local Reverse
	local Easing do
		Data_Easing = Easing or EasingFunctions.Exp2
		local Data_EasingType = type(Data_Easing)
		if Data_EasingType == "string" then
			Data_Easing = EasingFunctions[Data_Easing]
			Data_EasingType = "table"
		end
		Easing = (Data_EasingType == "function" and Data_Easing) or (Data_EasingType == "table" and Data_Easing.Run)
		if Data_EasingType == "table" and Data_Easing.Reverse then
			Reverse = true
		end
	end
	return CalcEasing(Easing,Direction,Reverse,X)
end

------------------------------------
-- 모듈 함수 지정
------------------------------------
-- 트윈 메서드 지정, 트윈을 만들게 됨
-- Item : 트윈할 인스턴트
-- Data : 트윈 정보들 (태이블)
	--Data.Time (in seconds, you can use 0.5 .. etc)
	--Data.Easing (function)
	--Data.Direction ("Out" , "In")
	--Data.CallBack 콜백 함수들(태이블), 예시 :
	--Data.CallBack[0.5] = function() end 다음과 같이 쓰면 인덱스가 정확히 0.5 가 되는 순간(시간이 아니라 이징 함수에 의해 나온 값이 같아지는 순간)
	--해당 함수가 실행됨
--Properties : 트윈할 속성과 목표값 예시 :
--Data.Properties.Position = UDim2.new(1,0,1,0) 처럼 하면 Position 속성의 목표를 1,0,1,0 으로 지정
function module.RunTween(Item,Data,Properties,Ended,OnStepped,Setter,Getter,_)
	OnStepped = OnStepped or Data.OnStepped
	Ended = Ended or Data.Ended
	Setter = Setter or Data.Setter
	Getter = Getter or Data.Getter

	-- remove self
	if Item == module then warn "AdvancedTween:RunTween() is deprecated, Use AdvancedTween.RunTween() instead"; Item = Data; Data = Properties; Properties = Ended; Ended = OnStepped; OnStepped = Setter; Setter = Getter; Getter = _; end

	-- 시간 저장
	local Time = Data.Time or 1
	local EndTime = clock() + Time

	-- 플레이 인덱스 저장
	local ItemPlayIndex = module.PlayIndex[Item]
	if ItemPlayIndex then
		for _,stepFunc in ipairs(BindedFunctions) do
			if FunctionTargetItem[stepFunc] == Item then
				stepFunc() -- 해당 애니메이션을 미리 계산해서 지금 위치를 저장
			end
		end
		ItemPlayIndex = module.PlayIndex[Item]
	end
	if not ItemPlayIndex then
		ItemPlayIndex = {}
		module.PlayIndex[Item] = ItemPlayIndex
	end

	-- 예전의 트윈을 덮어쓰고 현재 값을 저장함 !이전 트윈은 파기됨
	local ThisPlayIndex = {}
	local LastProperties = {}
	for PropertyName,_ in pairs(Properties) do
		if Getter then
			LastProperties[PropertyName] = Getter(Item,PropertyName)
		else
			LastProperties[PropertyName] = Item[PropertyName]
		end
		local PlayIndex = (ItemPlayIndex[PropertyName] or 0) + 1
		ItemPlayIndex[PropertyName] = PlayIndex
		ThisPlayIndex[PropertyName] = PlayIndex
	end

	-- 이징 효과 가져오기
	local Direction = Data.Direction or "Out"
	local Reverse
	local Easing do
		local Data_Easing = Data.Easing or EasingFunctions.Exp2
		local Data_EasingType = type(Data_Easing)
		if Data_EasingType == "string" then
			Data_Easing = EasingFunctions[Data_Easing]
			Data_EasingType = "table"
		end
		Easing = (Data_EasingType == "function" and Data_Easing) or (Data_EasingType == "table" and Data_Easing.Run)
		if Data_EasingType == "table" and Data_Easing.Reverse then
			Reverse = true
		end
	end

	-- 중간중간 실행되는 함수 확인
	local CallBack = Data.CallBack
	if CallBack then
		for FncIndex,Fnc in pairs(CallBack) do
			if type(Fnc) ~= "function" or (type(tonumber(FncIndex)) ~= "number" and FncIndex ~= "*") then
				warn(
					("Unprocessable callback function got, Ignored.\n - key: %s value: %s")
					:format(tostring(Fnc),tostring(FncIndex))
				)
				CallBack[FncIndex] = nil
			end
		end
	end

	-- 스탭핑
	local Step
	Step = function()
		-- 아에 멈추게 되는 경우
		if module.PlayIndex[Item] == nil then
			remove(BindedFunctions,find(BindedFunctions,Step))
			return
		end

		-- 다른 트윈이 속성을 바꾸고 있다면(이후 트윈이) 그 속성을 건들지 않도록 없엠
		local StopByOther = true
		for PropertyName,PlayIndex in pairs(ThisPlayIndex) do
			if PlayIndex ~= ItemPlayIndex[PropertyName] then
				LastProperties[PropertyName] = nil
				Properties[PropertyName] = nil
				ThisPlayIndex[PropertyName] = nil
			else
				StopByOther = false
			end
		end

		local Now = clock()
		local Index = 1 - (EndTime - Now) / Time
		local Alpha
		if Now >= EndTime then
			Index = 1
			Alpha = 1
		else
			Alpha = CalcEasing(Easing,Direction,Reverse,Index)
		end

		-- 속성 Lerp 수행
		LerpProperties(
			Item,
			LastProperties,
			Properties,
			Alpha,
			Setter
		)

		-- 만약 다른 트윈이 지금 트윈하고 있는 속성을 모두 먹은경우 현재 트윈을 삭제함
		if StopByOther then
			remove(BindedFunctions,find(BindedFunctions,Step))
			return
		end

		-- 끝남
		if Index == 1 then
			for Property,_ in pairs(Properties) do
				ItemPlayIndex[Property] = 0
			end

			if next(ItemPlayIndex) then
				module.PlayIndex[Item] = nil
			end

			remove(BindedFunctions,find(BindedFunctions,Step))
			Index = 1
			if Ended then
				Ended(Item)
			end
		end

		-- 중간 중간 함수 배정된것 실행
		if CallBack then
			for FncIndex,Fnc in pairs(CallBack) do
				if FncIndex == "*" then
					Fnc(Item,Index,Alpha)
				else
					local num = tonumber(FncIndex)
					if num and num <= Index then
						Fnc(Alpha,Index,Item)
						CallBack[FncIndex] = nil
					end
				end
			end
		end
		if OnStepped then OnStepped(Item,Index,Alpha) end
	end

	-- 스캐줄에 등록
	insert(BindedFunctions,Step)
	FunctionTargetItem[Step] = Item

	return Step
end

-- 여러개의 개체를 트윈시킴
function module.RunTweens(Items,Data,Properties,Ended,OnStepped,Setter,Getter,_)
	-- remove self
	if Items == module then warn "AdvancedTween:RunTweens() is deprecated, Use AdvancedTween.RunTweens() instead"; Items = Data; Data = Properties; Properties = Ended; Ended = OnStepped; OnStepped = Setter; Setter = Getter; Getter = _; end
	for _,Item in pairs(Items) do
		module.RunTween(Item,Data,Properties,Ended,OnStepped,Setter,Getter)
	end
end

-- 트윈 멈추기
function module.StopTween(ItemOrStep,_)
	if ItemOrStep == module then warn "AdvancedTween:StopTween() is deprecated, Use AdvancedTween.StopTween() instead"; ItemOrStep = _ end
	if type(ItemOrStep) == "function" then
		local pos = find(BindedFunctions,ItemOrStep)
		if not pos then
			warn(("tween %s was not found from AdvancedTween BindedFunctions. ignored call StopTween"):format(tostring(ItemOrStep)))
			return
		end
		remove(BindedFunctions,pos)
		return
	end
	module.PlayIndex[ItemOrStep] = nil
end

function module.StopPropertyTween(Item,PropertyName,_)
	if Item == module then warn "AdvancedTween:StopTween() is deprecated, Use AdvancedTween.StopTween() instead"; Item = _ end
	local ItemPlayIndex = module.PlayIndex[Item]
	if not ItemPlayIndex then return end
	if type(PropertyName) == "table" then
		for _,name in pairs(PropertyName) do
			ItemPlayIndex[name] = (ItemPlayIndex[name] or 0) + 1
		end
	else
		ItemPlayIndex[PropertyName] = (ItemPlayIndex[PropertyName] or 0) + 1
	end
end

-- 해당 개체가 트윈중인지 반환
function module.IsTweening(ItemOrStep,_)
	if Item == module then warn "AdvancedTween:IsTweening() is deprecated, Use AdvancedTween.IsTweening() instead"; Item = _ end

	if type(ItemOrStep) == "function" then
		local pos = find(BindedFunctions,ItemOrStep)
		if pos then
			return true
		else
			return false
		end
	end

	if module.PlayIndex[Item] == nil then
		return false
	end

	for Property,Index in pairs(module.PlayIndex[Item]) do
		if Index ~= 0 then
			return true
		end
	end
	return false
end

-- 해당 개체의 해당 프로퍼티가 트윈중인지 반환
function module.IsPropertyTweening(Item,PropertyName,_)
	if Item == module then warn "AdvancedTween:IsPropertyTweening() is deprecated, Use AdvancedTween.IsPropertyTweening() instead"; Item = _ end

	if module.PlayIndex[Item] == nil then
		return false
	end

	if module.PlayIndex[Item][PropertyName] == nil then
		return false
	end

	return module.PlayIndex[Item][PropertyName] ~= 0
end

------------------------------------
-- 프레임 연결
------------------------------------
-- 1 프레임마다 실행되도록 해야되는 함수
-- ./Stepped.lua 에서 연결점 편집 가능
-- roblox 는 이미 연결되어 있음
function module.Stepped()
	for _,Function in ipairs(BindedFunctions) do
		if not FunctionTargetItem[Function] then
			remove(BindedFunctions,find(BindedFunctions,Function))
		else
			Function()
		end
	end
end
Stepped.BindStep(module.Stepped)
script.Destroying:Connect(function()
	Stepped.UnbindAll()
end)

function module.Destroy()
	Stepped.UnbindAll()
end

return module
