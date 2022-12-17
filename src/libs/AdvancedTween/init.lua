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

local script = script
local EasingFunctions = require(script and script.EasingFunctions or "EasingFunctions")
local Stepped = require(script and script.Stepped or "Stepped")

local BindedFunctions = {} -- 애니메이션을 위해 프레임에 연결된 함수들

module.PlayIndex = setmetatable({},{__mode = "k"}) -- 애니메이션 실행 스택 저장하기
-- PlayIndex[Item][Property] = 0 or nil <= 트윈중이지 않은 속성
-- PlayIndex[Item][Property] = 1... <= 트윈중인 속성

------------------------------------
-- Easing 스타일
------------------------------------
module.EasingFunctions = {
	--// for Autocomplete
	Linear = EasingFunctions.Linear; --// 직선
	Circle = EasingFunctions.Circle; --// 사분원
	Exp2 = EasingFunctions.Exp2; --// 덜 가파른 지수 그래프
	Exp4 = EasingFunctions.Exp4; --// 더 가파른 지수 그래프
	Exp2Max4 = EasingFunctions.Exp2Max4; --// 적당히 가파른 지수 그래프
}
for i,v in pairs(EasingFunctions) do
	module.EasingFunctions[i] = v
end

module.EasingDirections = {
	Out = "Out"; -- 반전된 방향
	In  = "In" ; -- 기본방향
}

---@deprecated
module.EasingDirection = module.EasingDirections
---@deprecated
module.EasingFunction = module.EasingFunctions

------------------------------------
-- Lerp 함수
------------------------------------
-- 이중 선형, Alpha 를 받아서 값을 구해옴
function Lerp(start,goal,alpha)
	return start + ((goal - start) * alpha)
end

-- 기본적으로 로블록스에 있는 클래스중, + - * / 과 같은 연산자 처리 메타 인덱스가 있는것들
local DefaultItems = {
	["Vector2"] = true;
	["Vector3"] = true;
	["CFrame" ] = true;
	["number" ] = true;
}

-- 예전 값,목표 값,알파를 주고 각각 해당하는 속성에 입력해줌
-- 기본적으로 모든 속성값 적용은 여기에서 이루워짐
function LerpProperties(Item,Old,New,Alpha)
	for Property,OldValue in pairs(Old) do
		local NewValue = New[Property]
		if NewValue ~= nil then
			local Type = type(OldValue)
			if DefaultItems[Type] then
				Item[Property] = Lerp(OldValue,NewValue,Alpha)
			elseif Type == "UDim2" then
				Item[Property] = UDim2.new(
					Lerp(OldValue.X.Scale ,NewValue.X.Scale ,Alpha),
					Lerp(OldValue.X.Offset,NewValue.X.Offset,Alpha),
					Lerp(OldValue.Y.Scale ,NewValue.Y.Scale ,Alpha),
					Lerp(OldValue.Y.Offset,NewValue.Y.Offset,Alpha)
				)
			elseif Type == "UDim" then
				Item[Property] = UDim.new(
					Lerp(OldValue.Scale ,NewValue.Scale ),
					Lerp(OldValue.Offset,NewValue.Offset)
				)
			elseif Type == "Color3" then
				Item[Property] = Color3.fromRGB(
					Lerp(OldValue.r*255,NewValue.r*255),
					Lerp(OldValue.g*255,NewValue.g*255),
					Lerp(OldValue.b*255,NewValue.b*255)
				)
			end
		end
	end
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
function module.RunTween(Item,Data,Properties,Ended,OnStepped,_)
	-- remove self
	if Item == module then Item = Data; Data = Properties; Properties = Ended; Ended = OnStepped; OnStepped = _; end

	-- 시간 저장
	local Time = Data.Time or 1
	local EndTime = clock() + Time

	-- 플레이 인덱스 저장
	local ThisPlayIndex = module.PlayIndex[Item] or {}
	module.PlayIndex[Item] = ThisPlayIndex

	-- 예전의 트윈을 덮어쓰고 현재 값을 저장함
	local NowAnimationIndex = {}
	local LastProperties = {}
	for Property,_ in pairs(Properties) do
		LastProperties[Property] = Item[Property]
		ThisPlayIndex[Property] = ThisPlayIndex[Property] ~= nil and ThisPlayIndex[Property] + 1 or 1
		NowAnimationIndex[Property] = ThisPlayIndex[Property]
	end

	-- 이징 효과 가져오기
	local Direction = Data.Direction or "Out"
	local Easing do
		local Data_Easing = Data.Easing or EasingFunctions.Exp2
		local Data_EasingType = type(Data_Easing)
		Easing = (Data_EasingType == "function" and Data_Easing) or (Data_EasingType == "table" and Data_Easing.Run)
		if Data_EasingType == "table" and Data_Easing.Reverse then
			Direction = Direction == "Out" and "In" or "Out"
		end
	end

	-- 중간중간 실행되는 함수 확인
	local CallBack = Data.CallBack
	if CallBack then
		for FncIndex,Fnc in pairs(CallBack) do
			if type(Fnc) ~= "function" or (type(tonumber(FncIndex)) ~= "number" and FncIndex ~= "*") then
				warn(("Unprocessable callback function got, Ignored.\n - key: %s value: %s"):format(tostring(Fnc),tostring(FncIndex)))
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

		local Now = clock()
		local Index = 1 - (EndTime - Now) / Time
		local Alpha = Direction == "Out" and Easing(Index) or (1 - Easing(1 - Index))

		-- 속성 Lerp 수행
		LerpProperties(
			Item,
			LastProperties,
			Properties,
			Alpha
		)

		-- 다른 트윈이 속성을 바꾸고 있다면(이후 트윈이) 그 속성을 건들지 않도록 없엠
		local StopByOther = true
		for Property,Index in pairs(NowAnimationIndex) do
			if Index ~= ThisPlayIndex[Property] then
				LastProperties[Property] = nil
				Properties[Property] = nil
				NowAnimationIndex[Property] = nil
			else
				StopByOther = false
			end
		end

		-- 만약 다른 트윈이 지금 트윈하고 있는 속성을 모두 먹은경우 현재 트윈을 삭제함
		if StopByOther then
			remove(BindedFunctions,find(BindedFunctions,Step))
			return
		end

		-- 끝남
		if Now >= EndTime then
			for Property,_ in pairs(Properties) do
				ThisPlayIndex[Property] = 0
			end

			local PlayIndexLen = 0
			for _,_ in pairs(ThisPlayIndex) do
				PlayIndexLen = PlayIndexLen + 1
			end
			if PlayIndexLen == 0 then
				ThisPlayIndex = nil
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
					Fnc(Index,Alpha)
				else
					local num = tonumber(FncIndex)
					if num then
						if num <= Index then
							Fnc(Alpha)
							CallBack[FncIndex] = nil
						end
					else
						local alphaNum = tonumber(FncIndex:match"~([%d.]+)")
						if alphaNum <= Alpha then
							Fnc(Index)
							CallBack[FncIndex] = nil
						end
					end
				end
			end
		end
		if OnStepped then OnStepped(Item,Index,Alpha) end
	end

	-- 스캐줄에 등록
	insert(BindedFunctions,Step)
end

-- 여러개의 개체를 트윈시킴
function module.RunTweens(Items,Data,Properties,Ended,OnStepped,_)
	-- remove self
	if Items == module then Items = Data; Data = Properties; Properties = Ended; Ended = OnStepped; OnStepped = _; end
	for _,Item in pairs(Items) do
		module.RunTween(Item,Data,Properties,Ended,OnStepped)
	end
end

-- 트윈 멈추기
function module.StopTween(Item,_)
	if Item == module then Item = _ end
	module.PlayIndex[Item] = nil
end

-- 해당 개체가 트윈중인지 반환
function module.IsTweening(Item,_)
	if Item == module then Item = _ end

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
	if Item == module then Item = _ end

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
	if not BindedFunctions[1] then
		return;
	end
	for _,Function in ipairs(BindedFunctions) do
		Function()
	end
end
Stepped.BindStep(module.Stepped)

return module
