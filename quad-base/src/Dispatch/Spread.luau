--!strict
--[[
	Spread — the one-shot, mutable bag of anything an element table can hold (3.4.0). Canon:
	`.claude/research/component-flatten-sugar-plan.md` 5절 (2026-10-16 회신 + 2026-10-20 Add·CRUD 정의);
	runtime plan `.claude/research/release-3.4.0-plan.md` 단위 3.

	  Spread(t) -> spread            -- t is written like an element table: hash keys + array values.
	                                 --   Spreads met in t's array part are flattened HERE (a Spread is
	                                 --   always one level deep) and locked.
	  spread:Append(other) -> ()     -- other must be a Spread; flattened into the end and locked. Returns
	                                 --   NOTHING — a Spread is mutable (a Modifier is the immutable one).
	  placed in an element's array part -> its keys and array values are spread into the element as if
	                                 --   written there, at its position; the Spread is locked.

	Precedence everywhere is "the first one in place wins": inline keys are the first layer (a Luau table
	constructor keeps no order between hash keys and array values, so inline keys can only consistently be
	the top layer — user, 2026-10-20), then the Spreads in order. Array values always append. A locked Spread
	refuses `:Append` (it was already copied somewhere — a later Append would not show there); reading,
	nesting and placing it again stay allowed (reuse is not refused here: a Ref inside refuses itself).
	No read/remove methods (user, 2026-10-20: add only when a need shows — adding a method later is not
	BREAKING because a Spread has no `__index` setters).

	A function value dropped because an EARLIER Spread already set the key is the silent hazard (two hooks
	both writing `MouseLeave`): `q.debug` reports it when the losing Spread is placed in an element. A key the
	element (or the Spread's own constructor) wrote inline wins silently — that is an explicit override.

	Runtime tag `__quadSpread = true` only — the class name lives in the type (user: not needed at runtime).
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local SpreadBrand = Brand.SpreadBrand
local isSpread = Brand.isSpread
local isPlainBranded = Brand.isPlainBranded

-- private state, never a literal key of the value (same idiom as Modifier's FieldsKey)
local StateKey = table.freeze({})

type SpreadState = {
	keys: { [any]: any }, -- key -> value (first one in place)
	direct: { [any]: boolean }, -- keys written inline in the constructor (win silently)
	array: { any }, -- array values in order
	locked: boolean,
	dropped: { string }?, -- function-valued keys this Spread lost to an earlier Spread (reported under q.debug)
}

local SpreadMT = {}
SpreadMT.__index = SpreadMT

function SpreadMT.__tostring(_self: any): string
	return "Spread"
end

local function stateOf(s: any): SpreadState
	return s[StateKey]
end

-- merge `from` into `into`: first one in place wins; a function `from` loses to a non-direct winner is noted
local function mergeInto(into: SpreadState, from: SpreadState)
	for k, v in from.keys do
		if into.keys[k] == nil then
			into.keys[k] = v
		elseif type(v) == "function" and not into.direct[k] then
			local d = into.dropped or {}
			d[#d + 1] = tostring(k)
			into.dropped = d
		end
	end
	if from.dropped then
		local d = into.dropped or {}
		table.move(from.dropped, 1, #from.dropped, #d + 1, d)
		into.dropped = d
	end
	table.move(from.array, 1, #from.array, #into.array + 1, into.array)
end

local function Spread(t: any): any
	if type(t) ~= "table" or getmetatable(t) ~= nil or isPlainBranded(t) then
		Err.errorBeforeNearest(`Quad0273 Spread: the argument must be a plain table written like an element table (got {typeof(t)})`, SURFACE)
	end
	local state: SpreadState = { keys = {}, direct = {}, array = {}, locked = false, dropped = nil }
	local n = #t
	for k, v in t do
		if type(k) == "number" and k >= 1 and k <= n and k % 1 == 0 then
			continue
		end
		if type(v) == "table" and isSpread(v) then
			Err.errorBeforeNearest(`Quad0274 Spread: a Spread cannot be the value of key "{tostring(k)}" - place it in the array part`, SURFACE)
		end
		state.keys[k] = v
		state.direct[k] = true
	end
	for i = 1, n do
		local v = t[i]
		if type(v) == "table" and isSpread(v) then
			local inner = stateOf(v)
			inner.locked = true
			mergeInto(state, inner)
		else
			state.array[#state.array + 1] = v
		end
	end
	local s = setmetatable({ [StateKey] = state, __quadSpread = true }, SpreadMT)
	SpreadBrand:Register(s)
	return table.freeze(s)
end

function SpreadMT.Append(self: any, other: any)
	local state = stateOf(self)
	if type(other) ~= "table" or not isSpread(other) then
		Err.errorBeforeNearest(`Quad0276 Spread:Append: the argument must be a Spread (got {typeof(other)})`, SURFACE)
	end
	-- `s:Append(s)` counts as locked: appending would lock the argument, which is the receiver
	if state.locked or rawequal(other, self) then
		Err.errorBeforeNearest("Quad0275 Spread:Append: this Spread is locked - it was already placed in an element or spread into another Spread (a Spread cannot be appended to itself)", SURFACE)
	end
	local inner = stateOf(other)
	inner.locked = true
	mergeInto(state, inner)
end

-- the first pre-pass of `Dispatch.drive` (before Modifier `flatten`): every Spread in the array part is
-- replaced by its array values at its position and its keys fill keys the element does not have yet.
-- Mutates and returns `input`. `debug`: report dropped function values (q.debug).
local function expand(input: { [any]: any }, debug: boolean?): { [any]: any }
	local n = #input
	local first = 0
	for i = 1, n do
		local v = input[i]
		if type(v) == "table" and isSpread(v) then
			first = i
			break
		end
	end
	if first == 0 then
		return input
	end
	local fromSpread: { [any]: boolean } = {}
	local out: { any } = table.move(input, 1, first - 1, 1, {})
	for i = first, n do
		local v = input[i]
		if type(v) == "table" and isSpread(v) then
			local st = stateOf(v)
			st.locked = true
			for k, val in st.keys do
				if input[k] == nil then
					input[k] = val
					fromSpread[k] = true
				elseif debug and type(val) == "function" and fromSpread[k] then
					print(`Spread: key "{tostring(k)}" (a function) was dropped - an earlier Spread on this element already set it (the first one in place wins); handlers that must all run belong in OnEvent descriptors`)
				end
			end
			if debug and st.dropped then
				for _, k in st.dropped do
					print(`Spread: key "{k}" (a function) was dropped while building this Spread - an earlier Spread already set it (the first one in place wins); handlers that must all run belong in OnEvent descriptors`)
				end
			end
			table.move(st.array, 1, #st.array, #out + 1, out)
		else
			out[#out + 1] = v
		end
	end
	local m = #out
	table.move(out, 1, m, 1, input)
	for i = m + 1, n do
		input[i] = nil
	end
	return input
end

Err.setFuncLevel(SURFACE, Spread, SpreadMT.Append)

return {
	Spread = Spread,
	expand = expand,
	_StateKey = StateKey, -- specs only (private)
}
