--[[
	Operator 계약 — `.claude/research/operator-sugar-plan.md` "메커니즘"(전부 `factory(self)` + `:Apply`, 커링 팩토리는 자기 deps를
	스스로 `:Compute`에 넘겨 재사용해도 드리프트 없음 — "왜 `:Apply`인가" 1번), 범위는 사용자 확정(2026-09-08: 산술·비트·단항 Not·
	Min/Max/Clamp·Alternative; And/Or·비교·Sub/Div 제외). 숫자 인자는 plain이거나 State<number>.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

type State<T> = QuadTypes.State<T>

local SPEC_FILE = "spec.operator.luau"
local Source, Operator = Quad.Source, Quad.Operator

print("=== 1. Not — 0항 팩토리 그 자체를 :Apply; 파생 State, 반응 ===")
do
	local reduceMotion = Source(false)
	local animate: State<boolean> = reduceMotion:Apply(Operator.Not)
	assert(Quad.isState(animate) and animate:Get() == true, "not false")
	reduceMotion:Set(true)
	assert(animate:Get() == false, "reactive")
	print("PASS")
end

print()
print("=== 2. Sum/Product — self + deps(State), 이름 붙여 재사용해도 deps가 따라간다(왜 :Apply인가 1번); plain 숫자 혼용 ===")
do
	local tax, shipping = Source(2), Source(3)
	local addTaxAndShipping = Operator.Sum(tax, shipping)
	local a, b = Source(10), Source(100)
	local ta: State<number> = a:Apply(addTaxAndShipping)
	local tb: State<number> = b:Apply(addTaxAndShipping)
	assert(ta:Get() == 15 and tb:Get() == 105, "self + deps")
	tax:Set(5)
	assert(ta:Get() == 18 and tb:Get() == 108, "a reused factory's deps are subscribed at every Apply")
	local doubledPlus: State<number> = a:Apply(Operator.Product(2, Source(1)))
	assert(doubledPlus:Get() == 20, "plain numbers mixed with States")
	a:Set(1)
	assert(doubledPlus:Get() == 2, "reactive")
	print("PASS")
end

print()
print("=== 3. Min/Max/Clamp/비트 — bit32 위의 얇은 층, Shl/Shr는 인자 하나 ===")
do
	local v = Source(150)
	local clamped: State<number> = v:Apply(Operator.Clamp(0, Source(100)))
	assert(clamped:Get() == 100, "clamp hi")
	v:Set(-5)
	assert(clamped:Get() == 0, "clamp lo")
	local mn: State<number> = v:Apply(Operator.Min(3))
	local mx: State<number> = v:Apply(Operator.Max(3, Source(10)))
	assert(mn:Get() == -5 and mx:Get() == 10, "min/max")
	local bits = Source(0b1100)
	assert((bits:Apply(Operator.Band(0b1010)) :: State<number>):Get() == 0b1000, "band")
	assert((bits:Apply(Operator.Bor(0b0001)) :: State<number>):Get() == 0b1101, "bor")
	assert((bits:Apply(Operator.Bxor(0b1111)) :: State<number>):Get() == 0b0011, "bxor")
	assert((bits:Apply(Operator.Bnot) :: State<number>):Get() == bit32.bnot(0b1100), "bnot")
	assert((bits:Apply(Operator.Shl(2)) :: State<number>):Get() == 0b110000, "shl")
	assert((bits:Apply(Operator.Shr(Source(2))) :: State<number>):Get() == 0b11, "shr with a State amount")
	print("PASS")
end

print()
print("=== 4. Alternative — nil이면 default(plain 또는 State), 아니면 값 ===")
do
	local maybe = Source(nil :: string?)
	local fallback = Source("default")
	local resolved: State<string> = maybe:Apply(Operator.Alternative(fallback))
	assert(resolved:Get() == "default", "nil → default State")
	maybe:Set("x")
	assert(resolved:Get() == "x", "value wins")
	fallback:Set("other")
	maybe:Set(nil)
	assert(resolved:Get() == "other", "default State is a dep")
	local plain: State<string> = maybe:Apply(Operator.Alternative("p"))
	assert(plain:Get() == "p", "plain default")
	print("PASS")
end

print()
print("=== 4b. Indexed<<V>>(key) — 반응형 필드 읽기, 결과 타입은 호출자가 직접 지정; 테이블이 아니면 에러 ===")
do
	type Theme = { Primary: string, Size: number }
	local theme = Source({ Primary = "red", Size = 10 } :: Theme)
	local primary: State<string> = theme:Apply(Operator.Indexed<<string>>("Primary"))
	local size: State<number> = theme:Apply(Operator.Indexed<<number>>("Size"))
	assert(primary:Get() == "red" and size:Get() == 10, "reads")
	theme:Set({ Primary = "blue", Size = 12 })
	assert(primary:Get() == "blue" and size:Get() == 12, "reactive on the whole-table State")
	local missing: State<string?> = theme:Apply(Operator.Indexed<<string?>>("Nope"))
	assert(missing:Get() == nil, "absent key → nil (no gate — the caller typed it)")
	local ok, err = pcall(function()
		return Operator.Indexed(nil :: any)
	end)
	assert(not ok and string.find(tostring(err), "key must not be nil", 1, true), tostring(err))
	local notTable = Source(5 :: any)
	local bad: State<any> = notTable:Apply(Operator.Indexed<<any>>("x"))
	ok, err = pcall(function()
		return bad:Get()
	end)
	assert(not ok and string.find(tostring(err), "Operator.Indexed: value is not a table (got number)", 1, true), tostring(err))
	print("PASS")
end

print()
print("=== 5. 게이트 — 인자 타입·nil 인자(H-199 관용구)는 팩토리 호출 즉시 에러(blame은 그 줄), Apply 대상 State(직접 호출 폴백), Alternative nil default ===")
do
	local ok, err = pcall(function()
		return Operator.Sum("3" :: any)
	end)
	assert(not ok and string.find(tostring(err), "Operator.Sum: argument #1 must be a number or a State<number>", 1, true), tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "arg blame")
	ok, err = pcall(function()
		return (Operator.Sum :: any)(1, nil, 2)
	end)
	assert(not ok and string.find(tostring(err), "Operator.Sum: argument #2 is nil", 1, true), tostring(err))
	ok, err = pcall(function()
		return (Operator.Clamp :: any)(0)
	end)
	assert(not ok and string.find(tostring(err), "Operator.Clamp: argument #2 is nil", 1, true), tostring(err))
	ok, err = pcall(function()
		return Operator.Sum(1)({} :: any)
	end)
	assert(not ok and string.find(tostring(err), "Apply target must be a State", 1, true), tostring(err))
	ok, err = pcall(function()
		return Operator.Alternative(nil :: any)
	end)
	assert(not ok and string.find(tostring(err), "default must not be nil", 1, true), tostring(err))
	print("PASS")
end

print()
print("=== 6. round10 H-1 — 인자 State의 현재값이 nil/비숫자면 조용히 건너뛰지 않고 읽는 줄을 blame ===")
do
	local price, tax, ship = Source(1000), Source(100 :: any), Source(50)
	local total = price:Apply(Operator.Sum(tax, ship))
	assert(total:Get() == 1150, "sanity")
	tax:Set(nil)
	local ok, err = pcall(function() return total:Get() end)
	assert(not ok and string.find(tostring(err), "Operator.Sum: argument #1 is a State whose current value is nil", 1, true) ~= nil, "nil current value is an error, not a skipped term: " .. tostring(err))
	assert(string.find(tostring(err), "Operator.luau", 1, true) == nil, "no quad file on the blame line: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.operator.luau", "nil-value error blames the reading line")
	tax:Set("x")
	local ok2, err2 = pcall(function() return total:Get() end)
	assert(not ok2 and string.find(tostring(err2), "current value must be a number (got string)", 1, true) ~= nil, "wrong-type current value: " .. tostring(err2))
	local mask = Source(0xFF)
	local band = mask:Apply(Operator.Band(Source(nil :: any)))
	local ok3, err3 = pcall(function() return band:Get() end)
	assert(not ok3 and string.find(tostring(err3), "Operator.Band: argument #1 is a State whose current value is nil", 1, true) ~= nil, "bitwise too: " .. tostring(err3))
	local selfNil = (Source(nil :: any) :: any):Apply(Operator.Sum(1))
	local ok4, err4 = pcall(function() return selfNil:Get() end)
	assert(not ok4 and string.find(tostring(err4), "the Apply target's current value must be a number (got nil)", 1, true) ~= nil, "target's own value checked: " .. tostring(err4))
	-- code-review: the same check for the non-fold operators (Clamp/Shl/Shr/Bnot) — no raw VM error blaming Operator.luau
	local ops: { [string]: any } = { Clamp = Operator.Clamp(0, 10), Shl = Operator.Shl(1), Bnot = Operator.Bnot }
	for label, f in ops do
		local node = (Source(nil :: any) :: any):Apply(f)
		local okN, errN = pcall(function() return node:Get() end)
		assert(not okN and string.find(tostring(errN), "the Apply target's current value must be a number (got nil)", 1, true) ~= nil, label .. ": " .. tostring(errN))
		assert(string.find(tostring(errN), "Operator.luau", 1, true) == nil, label .. " blames the user: " .. tostring(errN))
	end
	-- Alternative: a default State whose current value is nil is an error, like a plain nil default at the factory
	local alt = (Source(nil :: any) :: any):Apply(Operator.Alternative(Source(nil :: any)))
	local okA, errA = pcall(function() return alt:Get() end)
	assert(not okA and string.find(tostring(errA), "Operator.Alternative: the default State's current value is nil", 1, true) ~= nil, "Alternative default nil: " .. tostring(errA))
	print("PASS")
end

print()
print("ALL PASS")
