--[[
	Context / Provider 계약 — `.claude/base/context-plan.md`: 명시적 값 컨테이너(트리 탐색 없음), Provider는 테이블 신원 키,
	`Get`은 없으면 에러(사용자 결정), `Peek`은 nil, `Set`은 자기 가방을 변경하고 self 반환, nil 값 거부. 타입은 `Provider<T>`의
	팬텀 `T`로 `Get`이 추론된다(strict 검사 자체가 단언).
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

type Store<T> = QuadTypes.Store<T>

local SPEC_FILE = "spec.context.luau"
local Context = Quad.Context

print("=== 1. 생성·브랜드·tostring — Context()는 콜러블 네임스페이스, Provider는 frozen 신원 키(이름은 선택) ===")
do
	local ctx = Context()
	local p = Context.Provider()
	local named = Context.Provider("Inventory" :: string?) :: QuadTypes.Provider<string>
	assert(Quad.isContext(ctx) and not Quad.isProvider(ctx), "Context brand")
	assert(Quad.isProvider(p) and Quad.isProvider(named) and not Quad.isContext(p), "Provider brand")
	assert(p ~= Context.Provider(), "every Provider() is a distinct identity")
	assert(table.isfrozen(p :: any), "frozen")
	assert(tostring(named) == "Provider(Inventory)" and tostring(p) == "Provider", "tostring")
	assert(tostring(ctx) == "Context(0)", tostring(ctx))
	local ok, err = pcall(function()
		return Context.Provider(5 :: any)
	end)
	assert(not ok and string.find(tostring(err), "name must be a string", 1, true), tostring(err))
	print("PASS")
end

print()
print("=== 2. Set/Get/Peek — 타입은 Provider<T>의 팬텀 T로 추론; Get은 없으면 에러(호출 줄 blame), Peek은 nil ===")
do
	type Inv = { Items: QuadTypes.Source<number> } -- Store defaults are Sources
	local InventoryProvider = Context.Provider("Inventory") :: QuadTypes.Provider<Store<Inv>>
	local CountProvider = Context.Provider() :: QuadTypes.Provider<number>
	local inv = Quad.Store({ Items = Quad.Source(3) })
	local ctx = Context():Set(InventoryProvider, inv):Set(CountProvider, 7)
	assert(Quad.isContext(ctx), "Set returns self (chaining)")
	local got: Store<Inv> = ctx:Get(InventoryProvider) -- typed by the Provider's phantom T
	assert(got == inv, "identity preserved")
	local n: number = ctx:Get(CountProvider)
	assert(n == 7, "plain values too")
	local Missing = Context.Provider("Theme") :: QuadTypes.Provider<string>
	assert(ctx:Peek(Missing) == nil and ctx:Peek(CountProvider) == 7, "Peek: nil when absent")
	local ok, err = pcall(function()
		return ctx:Get(Missing)
	end)
	assert(not ok and string.find(tostring(err), "no value for Provider(Theme)", 1, true), tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "Get blame")
	assert(tostring(ctx) == "Context(2)", "count")
	print("PASS")
end

print()
print("=== 3. 게이트 — 키는 Provider만, nil 값 거부; Set은 덮어쓰기 ===")
do
	local ctx = Context()
	local P = Context.Provider() :: QuadTypes.Provider<number>
	for _, fnName in { "Set", "Get", "Peek" } do
		local ok, err = pcall(function()
			return (ctx :: any)[fnName](ctx, {}, 1)
		end)
		assert(not ok and string.find(tostring(err), `Context:{fnName}: key must be a Provider`, 1, true), tostring(err))
	end
	local ok, err = pcall(function()
		return ctx:Set(P, nil :: any)
	end)
	assert(not ok and string.find(tostring(err), "must not be nil", 1, true), tostring(err))
	ctx:Set(P, 1):Set(P, 2)
	assert(ctx:Get(P) == 2, "later Set wins")
	local B = Context.Provider() :: QuadTypes.Provider<boolean>
	ctx:Set(B, false)
	assert(ctx:Get(B) == false and ctx:Peek(B) == false and ctx:Peek(B) ~= nil, "false is a value (only nil is absence)")
	print("PASS")
end

print()
print("=== 4. 중간 계층 — 스키마를 모르는 셸이 가방을 그대로 내리고, 깊은 자식이 자기 키만 읽는다 ===")
do
	local ThemeProvider = Context.Provider("Theme") :: QuadTypes.Provider<string>
	local UserProvider = Context.Provider("User") :: QuadTypes.Provider<{ Name: string }>
	local function DeepChild(props: { Context: QuadTypes.Context }): string
		return props.Context:Get(ThemeProvider) .. "/" .. props.Context:Get(UserProvider).Name
	end
	local function Shell(props: { Context: QuadTypes.Context }): string -- knows nothing about Theme/User
		return DeepChild({ Context = props.Context })
	end
	local ctx = Context():Set(ThemeProvider, "dark"):Set(UserProvider, { Name = "q" })
	assert(Shell({ Context = ctx }) == "dark/q", "forwarded untouched")
	print("PASS")
end

print()
print("ALL PASS")
