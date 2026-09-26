--!nocheck
-- E52 reference model for q.Operator — written from docs/reference/sugar/02-operator.md, NOT from Operator.luau.
-- Rule ids (R*) cite the doc line; "U*" marks cells the doc does not fix (actual result is recorded).
local M = {}
local TWO32 = 2 ^ 32

-- R-bit (sugar/02:175): "소수는 잘리고(1.5→1), 음수는 2^32 모듈로(-1→4294967295), 2^32 이상은 접히며(2^53+2→2),
-- NaN·±inf는 0". Truncation toward zero, then mod 2^32. U1: |x| >= 2^63 (doc says "접힘"; the math fold is NOT
-- what happens — C cast UB, x86 gives 0). U2: ±inf (doc: 0; C cast UB, x86 only).
local function isnan(x) return x ~= x end
local function trunc(x) if x >= 0 then return math.floor(x) else return math.ceil(x) end end
function M.u32(x)
	if isnan(x) or x == math.huge or x == -math.huge then return 0 end
	if math.abs(x) >= 2 ^ 63 then return 0 end -- U1 (x86 measured value; see REPORT)
	return trunc(x) % TWO32
end
local function bitwise(a, b, f)
	a, b = M.u32(a), M.u32(b)
	local r, p = 0, 1
	for _ = 1, 32 do
		local x, y = a % 2, b % 2
		if f(x, y) == 1 then r += p end
		a, b, p = (a - x) / 2, (b - y) / 2, p * 2
	end
	return r
end
M.band = function(a, b) return bitwise(a, b, function(x, y) return if x == 1 and y == 1 then 1 else 0 end) end
M.bor = function(a, b) return bitwise(a, b, function(x, y) return if x == 1 or y == 1 then 1 else 0 end) end
M.bxor = function(a, b) return bitwise(a, b, function(x, y) return if x ~= y then 1 else 0 end) end
M.bnot = function(a) return TWO32 - 1 - M.u32(a) end
-- R-shift (sugar/02:175 "이동량이 32 이상이면 0, 음수 이동량은 방향이 뒤집힙니다"). U4: non-integer / NaN / inf amount.
local function shiftAmt(d)
	if isnan(d) or d == math.huge or d == -math.huge then return nil end
	return trunc(d)
end
function M.lshift(x, d)
	local t = shiftAmt(d)
	if t == nil or t >= 32 or t <= -32 then return 0 end
	if t < 0 then return math.floor(M.u32(x) / 2 ^ -t) end
	return (M.u32(x) * 2 ^ t) % TWO32
end
function M.rshift(x, d)
	local t = shiftAmt(d)
	if t == nil or t >= 32 or t <= -32 then return 0 end
	if t < 0 then return (M.u32(x) * 2 ^ -t) % TWO32 end
	return math.floor(M.u32(x) / 2 ^ t)
end

-- R-fold (sugar/02:112,128,138,148,173,190,200): self first, then args in order, pairwise.
M.FOLD = {
	Sum = function(a, b) return a + b end,
	Product = function(a, b) return a * b end,
	Min = function(a, b) return if b < a then b else a end, -- math.min: keeps the earlier on ties/NaN (sugar/02:175 NaN rule)
	Max = function(a, b) return if b > a then b else a end,
	Band = M.band, Bor = M.bor, Bxor = M.bxor,
}
M.SHIFT = { Shl = M.lshift, Shr = M.rshift }

-- Factory-time check (sugar/02:58 — "인자 타입·nil 인자 → 팩토리를 부르는 줄").
-- args: array of {k="lit"|"state"|"nil", v=...}; n = argument count as passed.
function M.factory(op, args, n)
	if op == "Not" or op == "Bnot" then return nil end
	if op == "Indexed" then
		local a = args[1]
		if n < 1 or a.k == "nil" then return "Quad0125" end
		if a.k == "state" then return "Quad0126" end
		return nil
	end
	if op == "Alternative" then
		local a = args[1]
		if n < 1 or a.k == "nil" then return "Quad0128" end
		return nil
	end
	local want = if op == "Clamp" then 2 elseif M.SHIFT[op] then 1 else n
	for i = 1, want do
		local a = args[i]
		if a == nil or a.k == "nil" then return "Quad0118" end
		if a.k == "lit" and type(a.v) ~= "number" then return "Quad0119" end
	end
	return nil
end

-- Read-time value. tv = target's current value (already resolved), args with current State values in .cur.
-- Returns ok, valueOrErrId.
local function readArg(a)
	if a.k == "state" then
		if a.cur == nil then return false, "Quad0120" end -- sugar/02:62
		if type(a.cur) ~= "number" then return false, "Quad0121" end -- sugar/02:62 "… must be a number (got string)"
		return true, a.cur
	end
	return true, a.v
end
function M.eval(op, args, n, tv)
	if op == "Not" then return true, not tv end -- sugar/02:97
	if op == "Bnot" then
		if type(tv) ~= "number" then return false, "Quad0122" end -- sugar/02:62,64 (target checked too)
		return true, M.bnot(tv)
	end
	if op == "Indexed" then
		if type(tv) ~= "table" then return false, "Quad0127" end -- sugar/02:286
		return true, tv[args[1].v] -- sugar/02:268 (None: sugar/02:249 "조용히 nil")
	end
	if op == "Alternative" then
		if tv ~= nil then return true, tv end -- sugar/02:245,249 (None passes)
		local a = args[1]
		if a.k == "state" then
			if a.cur == nil then return false, "Quad0129" end -- sugar/02:247
			return true, a.cur
		end
		return true, a.v
	end
	if op == "Clamp" then
		-- implementation order (not fixed by doc): bounds read, bound check, then target check
		local ok1, lo = readArg(args[1]); if not ok1 then return false, lo end
		local ok2, hi = readArg(args[2]); if not ok2 then return false, hi end
		if lo ~= lo or hi ~= hi or lo > hi then return false, "Quad0124" end -- sugar/02:158
		if type(tv) ~= "number" then return false, "Quad0122" end
		if tv < lo then return true, lo elseif tv > hi then return true, hi else return true, tv end -- math.clamp (NaN target → NaN, sugar/02:175)
	end
	if type(tv) ~= "number" then return false, "Quad0122" end
	if M.SHIFT[op] then
		local ok, d = readArg(args[1]); if not ok then return false, d end
		return true, M.SHIFT[op](tv, d)
	end
	local f = M.FOLD[op]
	local acc = tv
	for i = 1, n do
		local ok, v = readArg(args[i]); if not ok then return false, v end
		acc = f(acc, v)
	end
	return true, acc
end

-- Cells the doc leaves open ("U*"): returns a list of tags for this evaluation.
function M.undecided(op, args, n, tv)
	local tags = {}
	local function nums()
		local out = { tv }
		for i = 1, n do local a = args[i]; if a then out[#out + 1] = if a.k == "state" then a.cur else a.v end end
		return out
	end
	local isBit = op == "Band" or op == "Bor" or op == "Bxor" or op == "Bnot" or op == "Shl" or op == "Shr"
	if isBit then
		for _, x in nums() do
			if type(x) == "number" and x == x and math.abs(x) ~= math.huge and math.abs(x) >= 2 ^ 63 then tags.U1 = true end
			if x == math.huge or x == -math.huge then tags.U2 = true end
		end
		if n == 0 and (op == "Band" or op == "Bor" or op == "Bxor") and type(tv) == "number" and M.u32(tv) ~= tv then tags.U3 = true end
		if M.SHIFT[op] and args[1] then
			local d = if args[1].k == "state" then args[1].cur else args[1].v
			if type(d) == "number" and (d ~= d or math.abs(d) == math.huge or d % 1 ~= 0) then tags.U4 = true end
		end
	end
	if (op == "Min" or op == "Max" or op == "Clamp") then
		for _, x in nums() do if x == 0 and 1 / x < 0 then tags.U5 = true end end
	end
	if op == "Sum" or op == "Product" then
		for _, x in nums() do if type(x) == "number" and (x ~= x or math.abs(x) == math.huge) then tags.U6 = true end end
	end
	return tags
end

function M.same(a, b)
	if type(a) == "number" and type(b) == "number" then
		if a ~= a then return b ~= b end
		if a == 0 and b == 0 then return 1 / a == 1 / b end
		return a == b
	end
	return rawequal(a, b)
end
return M
