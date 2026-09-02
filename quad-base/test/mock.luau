--[[
	quad-base용 최소 mock — Vide `test/mock.luau` 선례를 따르되 범위를 더
	좁힘(`.claude/base/architecture.md` "테스트 전략" 절): parent/children
	트리 + 타입 검증 없는 property bag + property별 변경 시그널만. `IsA()`/
	클래스별 프로퍼티 스키마/`WaitForChild`/`DataModel`은 만들지 않는다 —
	quad-base 코어는 `inst`를 `any`로 취급하고 Instance 특정 동작을 참조하지
	않으므로 mock이 실제 Roblox 충실도를 가질 이유가 없다(같은 절).

	Vide의 mock과 달리 GC-독립 userdata 프록시 트릭을 안 씀 — 그건 Roblox
	엔진 userdata가 Lua 참조와 무관하게 회수·재생성되는 **엔진 GC 동일성**을
	흉내내려는 것이고, 그건 quad-roblox의 `nativeClaim`이 실기기에서 다루는
	자리라 mock 범위 밖. 반면 **생명주기 계약 로직**(`bindLifetime`/`canBound`/
	`canExecute`/`unbindLifetime`이 gcconn의 `.Connected`로 판정하는 것)은
	mock 시그널 위에서 그대로 재현한다 — 아래 `installLifetime`.

	**[2026-08-28 M2, ROADMAP `H-97`] `installLifetime(quad)`** — 생명주기 4종
	(`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`)의 mock 백엔드.
	quad-roblox가 할 모듈 뮤테이션을 그대로 흉내내며, 본문은
	`.claude/base/lifecycle-pattern.md` (0)/(1)의 실 구현 스케치를 그대로 옮긴
	것(gcconn = 절대 안 발화하는 `ClassName` 변경 시그널의 Connection,
	gchold = inst에 매달린 값들의 강참조 홀더, `InstData`/`BindData` 두 Relate).
	이걸 위해 `Destroy`가 Roblox처럼 동작한다 — Destroying 발화 → Parent nil →
	**자손까지 Destroy** → **그 인스턴스의 모든 Connection을 끊는다**(`Connected =
	false`), 두 번째 Destroy는 no-op. gcconn의 `.Connected`가 곧 생존 판정이라서.
	Roblox와 다른 점 하나: gcconn/gchold 셋업(`nativeClaim`)은 quad가 Instance를
	만들 때 하는 일인데 mock Instance는 quad 밖에서 만들어지므로 여기선
	`bindLifetime` 첫 호출에 lazy로 한다 — quad-roblox는 그러면 안 된다
	(userdata 동일성 구멍, 같은 문서 (0) 절).
]]

export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	DisconnectAll: (self: Signal) -> (),
}

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

local Signal = {}
Signal.__index = Signal

local function newSignal(): Signal
	return (setmetatable({ connections = {} }, Signal) :: any) :: Signal
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local connections = (self :: any).connections
	local conn = { Connected = true, fn = fn }
	function conn.Disconnect(self2)
		if not self2.Connected then
			return
		end
		self2.Connected = false
		local i = table.find(connections, conn)
		if i then
			table.remove(connections, i)
		end
	end
	table.insert(connections, conn)
	return (conn :: any) :: Connection
end

-- Destroy가 부른다 — Roblox는 Destroy 시 그 인스턴스의 모든 연결을 끊는다.
function Signal:DisconnectAll()
	local connections = (self :: any).connections
	for i = #connections, 1, -1 do
		connections[i].Connected = false
		connections[i] = nil
	end
end

function Signal:Fire(...: any)
	-- 발화 도중 연결이 끊기는 경우를 대비해 스냅샷을 뜬 뒤 순회(Vide 선례)
	local snapshot = table.clone((self :: any).connections)
	for i = #snapshot, 1, -1 do
		local conn = snapshot[i]
		if conn.Connected then
			conn.fn(...)
		end
	end
end

export type MockInstance = {
	ClassName: string,
	Name: string,
	Parent: MockInstance?,
	Destroying: Signal,
	GetPropertyChangedSignal: (self: MockInstance, property: string) -> Signal,
	GetChildren: (self: MockInstance) -> { MockInstance },
	FindFirstChild: (self: MockInstance, name: string) -> MockInstance?,
	Destroy: (self: MockInstance) -> (),
	[string]: any, -- 타입 검증 없는 property bag
}

type Data = {
	className: string,
	name: string,
	parent: Data?,
	children: { Data },
	changed: { [any]: Signal },
	properties: { [any]: any },
	destroying: Signal,
	destroyed: boolean,
}

local dataOf = setmetatable({}, { __mode = "k" }) :: { [any]: Data }
local proxyOf = setmetatable({}, { __mode = "v" }) :: { [Data]: any }

local methods = {}

local function fireChanged(data: Data, key: any)
	local sig = data.changed[key]
	if sig then
		sig:Fire()
	end
end

local function getData(inst: any): Data
	local data = dataOf[inst]
	if data == nil then
		error("not a mock instance", 2)
	end
	return data
end

local function getProxy(data: Data): any
	local existing = proxyOf[data]
	if existing then
		return existing
	end

	local proxy = setmetatable({}, {
		__index = function(_, key)
			if methods[key] then
				return methods[key]
			elseif key == "Name" then
				return data.name
			elseif key == "ClassName" then
				return data.className
			elseif key == "Parent" then
				if data.parent == nil then
					return nil
				end
				return getProxy(data.parent)
			elseif key == "Destroying" then
				return data.destroying
			else
				return data.properties[key]
			end
		end,
		__newindex = function(_, key, value)
			if key == "Name" then
				if type(value) ~= "string" then
					error("Name must be a string", 2)
				end
				data.name = value
			elseif key == "Parent" then
				assert(value == nil or dataOf[value] ~= nil, "attempt to set non-instance as Parent")
				if data.parent then
					local siblings = data.parent.children
					local i = table.find(siblings, data)
					if i then
						table.remove(siblings, i)
					end
				end
				if value == nil then
					data.parent = nil
				else
					local newParentData = getData(value)
					data.parent = newParentData
					table.insert(newParentData.children, data)
				end
			else
				data.properties[key] = value
			end
			fireChanged(data, key)
		end,
	})

	dataOf[proxy] = data
	proxyOf[data] = proxy
	return proxy
end

local Instance = {}

function Instance.new(className: string): MockInstance
	local data: Data = {
		className = className,
		name = className,
		parent = nil,
		children = {},
		changed = {},
		properties = {},
		destroying = newSignal(),
		destroyed = false,
	}
	return (getProxy(data) :: any) :: MockInstance
end

function methods.GetPropertyChangedSignal(inst: any, property: string): Signal
	local data = getData(inst)
	local sig = data.changed[property]
	if sig == nil then
		sig = newSignal()
		data.changed[property] = sig
	end
	return sig
end

function methods.GetChildren(inst: any): { any }
	local data = getData(inst)
	local out = table.create(#data.children)
	for i, childData in data.children do
		out[i] = getProxy(childData)
	end
	return out
end

function methods.FindFirstChild(inst: any, name: string): any?
	local data = getData(inst)
	for _, childData in data.children do
		if childData.name == name then
			return getProxy(childData)
		end
	end
	return nil
end

function methods.Destroy(inst: any)
	local data = getData(inst)
	if data.destroyed then
		return -- Roblox처럼 두 번째 Destroy는 no-op (Destroying 핸들러 안의 재귀 Destroy 포함)
	end
	data.destroyed = true
	-- Roblox 순서: Destroying 발화 → Parent = nil(변경 시그널 관측 가능) → 자손 Destroy
	-- → 이 인스턴스의 모든 연결 해제. gcconn(`ClassName` 변경 시그널)의 `.Connected`가
	-- 생존 판정의 근거라 마지막 단계가 곧 canExecute의 전환이다.
	data.destroying:Fire()
	if data.parent then
		local siblings = data.parent.children
		local i = table.find(siblings, data)
		if i then
			table.remove(siblings, i)
		end
		data.parent = nil
		fireChanged(data, "Parent")
	end
	for _, childData in table.clone(data.children) do
		methods.Destroy(getProxy(childData))
	end
	data.destroying:DisconnectAll()
	for _, sig in data.changed do
		sig:DisconnectAll()
	end
end

local function isMockInstance(value: any): boolean
	return dataOf[value] ~= nil
end

--[[
	installLifetime(quad) — `.claude/base/lifecycle-pattern.md` (0)/(1) 스케치를
	mock 시그널 위에 그대로 옮김. quad 모듈 인스턴스를 뮤테이션한다(quad-roblox와
	같은 경로). 반환값은 없고, 같은 quad에 두 번 부르면 두 번째는 무시된다.
]]
local Relate = require("../src/Relate")
local QuadTypes = require("../luau_packages/quad_types")

local function installLifetime(quad: any)
	-- `H-294` (a, 사용자 확정: "mock 또한 하나의 백엔드이다") — mock도 실
	-- 백엔드와 같은 `_initializedBy` 3분기 계약을 지킨다. 이게 없으면 실
	-- 백엔드 위에 mock이 조용히 덮이거나(혼합 백엔드) 그 반대가 조용히
	-- 성공해, 기존 바인딩 전량이 소리 없이 침묵한다(탐사자 스파이크 실측).
	-- 옛 `installed` weak 테이블 가드는 이 마커가 대체.
	if quad._initializedBy == "mock" then
		return -- 같은 백엔드 재설치 = no-op
	end
	if quad._initializedBy ~= nil then
		error(`Quad module already initialized by '{quad._initializedBy}'`, 2)
	end
	quad._initializedBy = "mock"

	local isObserver, isEffect = quad.isObserver, quad.isEffect
	-- `H-272`: 백엔드 교체 함수의 사용자 오용 error도 워커 경유 — 단위 4 이후
	-- bindLifetime의 주 호출부가 디스패치 깊이(Leaf.process)라 리터럴 level 2는
	-- quad 내부를 blame했다. errorBefore(최외곽)면 직접 호출·디스패치 경유
	-- 양쪽에서 사용자 줄에 닿는다(`lifecycle-pattern.md` 스케치도 같이 정정).
	local Err = quad.errorNamespace
	local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

	local InstData = Relate() -- inst  -> gchold/gcconn ((0)에서 채움)
	local BindData = Relate() -- value -> gchold/gcconn (bindLifetime이 채움)

	-- `false or`: local 함수가 상수 접힘/인라인되면 아래 클로저의 업밸류 캡처가 사라진다
	local nop = (false or function(...: any) end) :: (...any) -> ()

	-- (0) nativeClaim 상당 — mock에선 lazy(헤더 주석 참고)
	local function claim(inst: any)
		if InstData:GetWeak(inst, "gchold") ~= nil then
			return
		end
		local gchold = {}
		local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
			nop(gchold, inst) -- 절대 발화 안 함. 클로저가 gchold와 inst를 업밸류로 붙잡는 게 전부
		end)
		gchold[1] = gcconn -- 배열 자리 1번은 gcconn 전용(값들은 해시 자리에)
		if getData(inst).destroyed then
			-- lazy claim의 구멍(리뷰 `H-171`): 이미 Destroy된 인스턴스의 옛 gcconn은 연결이
			-- 끊겨 GC되므로 여기로 다시 들어오는데, 새 gcconn이 Connected=true면 그 값은
			-- 영원히 산다. Roblox에선 nativeClaim이 생성 시 1회라 이 경로 자체가 없다 —
			-- 죽은 인스턴스에 묶인 값은 즉시 죽은 상태로 시작하게 맞춘다.
			gcconn:Disconnect()
		end
		InstData:SetWeak(inst, "gchold", gchold)
		InstData:SetWeak(inst, "gcconn", gcconn)
	end

	-- 비공개 — canBound/canExecute가 공유하는 실제 판정.
	local function isBoundAlive(value: any): boolean
		-- (a) inst-scoped 경로: bindLifetime이 복사해둔 gcconn을 value 자신에게서 찾음
		local gcconn = BindData:GetWeak(value, "gcconn")
		if gcconn ~= nil and gcconn.Connected then
			return true
		end
		-- (b) 전역 경로: 구독 경로(강/약)가 세운 것. Observer/Effect에만 있는 필드.
		if isObserver(value) or isEffect(value) then
			return value.Subscribed == true
		end
		return false
	end

	local function canBound(value: any): boolean
		return not isBoundAlive(value)
	end

	local function canExecute(value: any): boolean
		return isBoundAlive(value)
	end

	local function bindLifetime(inst: any, value: any)
		if not isMockInstance(inst) then
			Err.errorBefore("bindLifetime: inst is not a mock instance", SURFACE)
		end
		if not canBound(value) then
			-- 어느 경로로 묶여있는지만 메시지에 실어줌. `.Subscribed`를 무조건
			-- 인덱싱하면 안 됨 — value가 평범한 클로저일 수도 있음.
			local isGlobal = isObserver(value) or isEffect(value)
			if isGlobal then
				isGlobal = value.Subscribed == true
			end
			Err.errorBefore(
				if isGlobal
					then "bindLifetime: value is already subscribed"
					else "bindLifetime: value is already bound to another Instance",
				SURFACE
			)
		end
		-- [H-184] 훅 가드를 커밋 **전에** 묻는다 — 가드가 거부해도 반쯤 묶인 핸들
		-- (묶였는데 Destroying 연결 없음)이 남지 않는다. 값이 훅을 안 가지면(평범한
		-- 클로저 등) 물을 것이 없다. quad-roblox의 bindLifetime도 같은 순서여야 한다.
		if type(value) == "table" and (value :: any)._assertBindable ~= nil then
			(value :: any):_assertBindable()
		end
		claim(inst)

		local gchold = InstData:GetWeak(inst, "gchold")
		gchold[value] = true -- 강참조: inst가 사는 동안 value 생존 보장(계약 1)
		-- value가 자기 홀더/생존 판정 근거를 직접 들고 있게 함(계약 2). 둘 다 weak.
		BindData:SetWeak(value, "gchold", gchold)
		BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))

		if isObserver(value) then
			value:_catchUp() -- [H-159] 묶이기 전 홀드된 emit 1회 (단위 3에서 합류)
		end
		if isEffect(value) then
			value:_bindDestroying(inst) -- Destroying 연결 + 홀드 캐치업 1회 (단위 3)
		end
	end

	local function unbindLifetime(value: any)
		-- bind의 대칭 — cleanup은 부르지 않고, Ref 콜백/내부 Observer도 안 뗀다.
		if isEffect(value) then
			value:_unbindDestroying() -- Destroying 연결만 끊는다 (단위 3)
		end
		local gchold = BindData:GetWeak(value, "gchold")
		if gchold then
			gchold[value] = nil -- inst는 안 건드림, 이 value 하나만 조기 해제
		end
		BindData:SetWeak(value, "gchold", nil)
		BindData:SetWeak(value, "gcconn", nil)
	end

	-- 주입 op `onDestroying(inst, fn): Connection` — quad-roblox는 `inst.Destroying:Connect(fn)`
	-- 한 줄(`architecture.md` EngineOps). mock은 그 시그널을 그대로 쓴다.
	local function onDestroying(inst: any, fn: () -> ()): any
		if not isMockInstance(inst) then
			Err.errorBefore("onDestroying: inst is not a mock instance", SURFACE)
		end
		return inst.Destroying:Connect(fn)
	end

	quad.bindLifetime = bindLifetime
	quad.unbindLifetime = unbindLifetime
	quad.canBound = canBound
	quad.canExecute = canExecute
	quad.onDestroying = onDestroying

	-- `H-238`: 백엔드는 자기 교체 함수들을 공유 에러 네임스페이스에 태그한다
	-- (`LifetimeHandle.luau` 계약 — 안 하면 이 경로 아래의 errorBeforeNearest가
	-- 표면 프레임을 못 찾아 blame이 엉뚱한 바깥/raise 자리로 간다).
	for _, fn in { bindLifetime, unbindLifetime, canBound, canExecute, onDestroying } :: { any } do
		quad.errorNamespace.setFuncLevel(fn, QuadTypes.ERROR_LEVEL_SURFACE)
	end
end

-- `H-261`: 세 spec이 같은 헬퍼를 그대로 복사하고 있었다(`H-206` 선례 —
-- 3벌 복사가 추출 트리거). mock이 install 표면의 소유자라 여기가 집이다.
local Quad = require("../src")
local function newQuad(): any
	local q = Quad.New()
	installLifetime(q)
	return q
end

-- `H-271`: spec-로컬 문자열 leaf 핸들러(자리 기여 1, 재사용 Source memo,
-- 등록 순서 setOffsetSource → setLength)도 두 spec이 복사하고 있었다 —
-- H-263이 spec.nonenil 안에서 접은 걸 spec.integration이 한 파일 건너 다시
-- 벌렸다. 같은 근거(공유 헬퍼는 mock 소유)로 여기로. log가 있으면 retractor가
-- 기록한다.
local function addSpecLeaf(q: any, sources: { any }, log: { string }?)
	q.Dispatch.addHandler({
		name = "SpecLeaf",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			local src = sources[k] or q.Source(-1)
			sources[k] = src
			q.Dispatch.setOffsetSource(inst, k, src)
			q.Dispatch.setLength(inst, k, 1)
			if log ~= nil then
				local logList: { string } = log
				return function(hint: any?, retracting: boolean)
					-- `H-258` 플래그까지 기록 — 공유 헬퍼가 관측을 막으면
					-- 어떤 spec도 이 계약을 검증할 수 없다 (`H-281`)
					table.insert(logList, `leaf:retract:{k}:{tostring(hint)}:{tostring(retracting)}`)
				end
			end
			return Quad.Void
		end,
	} :: QuadTypes.Handler)
end

-- `H-282`: blame 단언 관용구(사용자 파일을 찍고 quad 내부는 안 찍는다)가
-- spec들에 여러 벌 복사되며 내부-제외 검사가 한 곳에서 드리프트했다 — 한
-- 헬퍼로. `/src/`는 quad-base/src·quad-error/src 둘 다 걸린다(테스트 경로엔 없음).
local function assertBlamesUser(err: any, wantFile: string, label: string?)
	local msg = tostring(err)
	assert(string.find(msg, wantFile, 1, true) ~= nil, `{label or "blame"}: expected {wantFile} in: {msg}`)
	assert(string.find(msg, "/src/", 1, true) == nil, `{label or "blame"}: must not blame quad internals: {msg}`)
end

return {
	Instance = Instance,
	newSignal = newSignal,
	isMockInstance = isMockInstance,
	installLifetime = installLifetime,
	newQuad = newQuad,
	addSpecLeaf = addSpecLeaf,
	assertBlamesUser = assertBlamesUser,
}
