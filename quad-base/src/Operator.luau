--!strict
--[[
	Operator — named combinators over `:Compute`, applied with `state:Apply`
	(`research/operator-sugar-plan.md` "메커니즘", "왜 `:Apply`인가"; scope fixed by the
	user 2026-09-08: arithmetic, bitwise, unary `Not`, plus the strong-precedent
	`Min`/`Max`/`Clamp` and nil-coalescing `Alternative`. NOT included on purpose:
	`And`/`Or` (user: "결합은 비추 — if/else를 쓰던 이유와 부딪힘"), comparisons
	(`Eq`/`Lt`/… — meaningless without a branch to feed; an `IfElse` is an open
	item), `Sub`/`Div`/`Xor` (no precedent as named combinators)).

	Every entry is `factory(self) -> State<U>`; N-ary ones curry:
	  reduceMotion:Apply(Operator.Not)
	  price:Apply(Operator.Sum(tax, shipping))     -- self + deps
	  value:Apply(Operator.Clamp(0, max))          -- args may be plain numbers or State<number>
	  maybe:Apply(Operator.Alternative(default))   -- nil → default (plain or State)
	The factory captures its State deps and passes them to `self:Compute` itself
	— that is the whole reason for `:Apply` over `:Compute` (a reusable name can
	never drift from its deps). Plain (non-State) arguments are captured as
	constants. Dependency-free leaf, shared across quad instances.
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
local isState = Brand.isState

-- args: numbers or States. Returns the State deps (for Compute) and a reader
-- that yields each arg's current value given the handles Compute passes.
local function splitArgs(name: string, args: { any }, n: number, kind: string): ({ any }, (...any) -> { any })
	local deps = {}
	local isDep = {}
	for i = 1, n do -- `n` from select("#") — a nil argument must error, not vanish and shift the rest (`H-199` idiom)
		local a = args[i]
		if a == nil then
			Err.errorBeforeNearest(`Operator.{name}: argument #{i} is nil`, SURFACE)
		end
		if isState(a) then
			deps[#deps + 1] = a
			isDep[i] = true
		elseif type(a) ~= kind then
			Err.errorBeforeNearest(`Operator.{name}: argument #{i} must be a {kind} or a State<{kind}> (got {typeof(a)})`, SURFACE)
		end
	end
	local function read(...: any): { any }
		local handles = { ... }
		local out = table.create(n)
		local d = 0
		for i = 1, n do
			if isDep[i] then
				d += 1
				out[i] = handles[d]:Get()
			else
				out[i] = args[i]
			end
		end
		return out
	end
	return deps, read
end

local function checkSelf(name: string, self: any)
	if not isState(self) then
		Err.errorBeforeNearest(`Operator.{name}: Apply target must be a State (got {typeof(self)})`, SURFACE)
	end
end

-- N-ary numeric fold: self first, then the args in order.
local function fold(name: string, op: (number, number) -> number): (...any) -> (any) -> any
	return function(...: any)
		local deps, read = splitArgs(name, { ... }, select("#", ...), "number")
		return function(self: any): any
			checkSelf(name, self)
			return self:Compute(function(h: any, _prev: any, ...: any)
				local acc = h:Get()
				for _, v in read(...) do
					acc = op(acc, v)
				end
				return acc
			end, table.unpack(deps))
		end
	end
end

-- unary: self only
local function unary(name: string, op: (any) -> any): (any) -> any
	return function(self: any): any
		checkSelf(name, self)
		return self:Compute(function(h: any)
			return op(h:Get())
		end)
	end
end

-- unary with one numeric argument (shift amounts): `Shl(n)`
local function withArg(name: string, op: (number, number) -> number): (any) -> (any) -> any
	return function(n: any)
		local deps, read = splitArgs(name, { n }, 1, "number")
		return function(self: any): any
			checkSelf(name, self)
			return self:Compute(function(h: any, _prev: any, ...: any)
				return op(h:Get(), read(...)[1])
			end, table.unpack(deps))
		end
	end
end

local Operator = {
	-- logic (unary only — see header)
	Not = unary("Not", function(v: any): boolean
		return not v
	end),
	-- arithmetic
	Sum = fold("Sum", function(a, b)
		return a + b
	end),
	Product = fold("Product", function(a, b)
		return a * b
	end),
	Min = fold("Min", math.min),
	Max = fold("Max", math.max),
	-- bitwise (Luau has no operators — `bit32`)
	Band = fold("Band", bit32.band),
	Bor = fold("Bor", bit32.bor),
	Bxor = fold("Bxor", bit32.bxor),
	Bnot = unary("Bnot", function(v: any): number
		return bit32.bnot(v)
	end),
	Shl = withArg("Shl", bit32.lshift),
	Shr = withArg("Shr", bit32.rshift),
}

-- Clamp(lo, hi): both may be numbers or States
function Operator.Clamp(lo: any, hi: any): (any) -> any
	local deps, read = splitArgs("Clamp", { lo, hi }, 2, "number")
	return function(self: any): any
		checkSelf("Clamp", self)
		return self:Compute(function(h: any, _prev: any, ...: any)
			local r = read(...)
			return math.clamp(h:Get(), r[1], r[2])
		end, table.unpack(deps))
	end
end

-- Index<<V>>(key): reactive field read — `theme:Apply(Operator.Index<<string>>("Primary"))`.
-- The VALUE type is given explicitly (user, 2026-09-08: "실제 인덱스 결과에 해당하는걸
-- Index<T>(k) 에 넣게" — inference from the key is out of reach for now, `typing-limits.md`
-- 8.15; revisit when unannotated inference works). Runtime is `h:Get()[key]`; a non-table
-- value is the user's error (raised at emit depth → outermost).
function Operator.Index(key: any): (any) -> any
	if key == nil then
		Err.errorBeforeNearest("Operator.Index: key must not be nil", SURFACE)
	end
	return function(self: any): any
		checkSelf("Index", self)
		return self:Compute(function(h: any)
			local t = h:Get()
			if type(t) ~= "table" then
				Err.errorBefore(`Operator.Index: value is not a table (got {typeof(t)}) — cannot read [{tostring(key)}]`, SURFACE)
			end
			return t[key]
		end)
	end
end

-- Alternative(default): nil-coalescing — `State<T?>` → `State<T>`; default may be a State
function Operator.Alternative(default: any): (any) -> any
	if default == nil then
		Err.errorBeforeNearest("Operator.Alternative: default must not be nil", SURFACE)
	end
	local deps = if isState(default) then { default } else {}
	return function(self: any): any
		checkSelf("Alternative", self)
		return self:Compute(function(h: any, _prev: any, d: any)
			local v = h:Get()
			if v ~= nil then
				return v
			end
			return if d ~= nil then d:Get() else default
		end, table.unpack(deps))
	end
end

Err.setFuncLevel(SURFACE, Operator.Not, Operator.Sum, Operator.Product, Operator.Min, Operator.Max, Operator.Band, Operator.Bor, Operator.Bxor, Operator.Bnot, Operator.Shl, Operator.Shr, Operator.Clamp, Operator.Index, Operator.Alternative) -- `H-231`: the curried entries (`Sum`…`Clamp`, `Alternative`) tag the OUTER call — their inner `factory(self)` runs inside `State.Apply`, itself tagged; the unary entries (`Not`/`Bnot`) ARE the factory, so the tag lands on the factory itself (a direct `Operator.Not(x)` call blames the caller)

return { Operator = Operator }
