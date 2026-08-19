--[[
	quad-base용 최소 mock — Vide `test/mock.luau` 선례를 따르되 범위를 더
	좁힘(`.claude/base/architecture.md` "테스트 전략" 절): parent/children
	트리 + 타입 검증 없는 property bag + property별 변경 시그널만. `IsA()`/
	클래스별 프로퍼티 스키마/`WaitForChild`/`DataModel`은 만들지 않는다 —
	quad-base 코어는 `inst`를 `any`로 취급하고 Instance 특정 동작을 참조하지
	않으므로 mock이 실제 Roblox 충실도를 가질 이유가 없다(같은 절).

	Vide의 mock과 달리 GC-독립 userdata 프록시 트릭을 안 씀 — 그건 Roblox
	엔진 userdata의 GC 동일성을 흉내내려는 것이고, 그 동일성 문제는
	quad-roblox의 LifetimeHandle(gcconn 트릭)이 다루는 자리라 quad-base
	정적 스냅샷 테스트 범위 밖.
]]

export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
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
end

local function isMockInstance(value: any): boolean
	return dataOf[value] ~= nil
end

return {
	Instance = Instance,
	newSignal = newSignal,
	isMockInstance = isMockInstance,
}
