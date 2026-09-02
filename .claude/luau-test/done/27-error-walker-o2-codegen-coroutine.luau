--[[
	Spike 27 — quad-error walker vs optimization levels & coroutines (`H-250`).

	What it verifies: the layer-tag stack walker (`quad-error`) relies on
	`debug.info(i, "f")` returning the *tagged function object* for live
	frames. Round12 `H-231` adopted two premises by reasoning only; this spike
	measures them:
	  (1) -O2 inlining / native codegen vs frame visibility. FIRST RUN RESULT
	      (2026-09-01): -O2 DOES inline a *local, directly-called* tagged
	      function — the walk finds no tag and the raise-site fallback fires
	      (section 1 observes both outcomes and prints which). But every
	      tagged function in quad is stored in and called through a TABLE
	      field (`q.Dispatch.drive`, `h.process`, `quad.bindLifetime`, the
	      ns.error* themselves) — a dynamic callee the inliner cannot resolve
	      — and section 2 asserts that shape stays visible under every flag.
	      ⇒ Load-bearing rule: ONLY table-called functions may carry tags.
	  (2) a raise inside a coroutine sees only that coroutine's own stack —
	      tags on the resumer's stack cannot match, and the documented
	      fallback (raise site) must hold (section 4).

	How to run (all four must print ALL PASS; section 1's observation line
	may differ by flag — that difference is the finding, not a failure):
	  luau .claude/luau-test/done/27-error-walker-o2-codegen-coroutine.luau
	  luau -O2 .claude/luau-test/27-error-walker-o2-codegen-coroutine.luau
	  luau --codegen .claude/luau-test/27-error-walker-o2-codegen-coroutine.luau
	  luau -O2 --codegen .claude/luau-test/27-error-walker-o2-codegen-coroutine.luau

	Requires the real artifact (not a copy): quad-error has no dependencies,
	so the relative require works from the repo checkout. Expected lines are
	captured with debug.info at runtime — no hardcoded line numbers.
]]

local QuadError = require("../../../quad-error/src")

local SURFACE = 1

local function blameLine(err: any): number?
	local line = string.match(tostring(err), "27%-error%-walker%-o2%-codegen%-coroutine%.luau:(%d+):")
	return if line then tonumber(line) else nil
end


print("=== 1. 로컬 직접 호출 — -O2 인라이닝이 태그 프레임을 지울 수 있다(양쪽 다 관측 대상) ===")
do
	local Err = QuadError.new()
	-- ⚠️ both functions must stay PLAIN (no debug.info inside their bodies) —
	-- an in-body probe suppresses the very inlining this section observes
	-- (measured: adding one turned -O2's "INLINED" back into "visible").
	-- Expected lines come from the definition line instead (body = next line).
	local function localSurface(fn: () -> ())
		fn()
	end
	Err.setFuncLevel(localSurface, SURFACE)
	local lineAt = (debug.info(localSurface, "l") :: number) + 1

	local function raiser()
		Err.errorAt("at-probe", SURFACE)
	end
	local raiseLine = (debug.info(raiser, "l") :: number) + 1
	-- direct call inside the closure — passing localSurface to pcall as a
	-- VALUE would remove the inlinable call site and hide the observation
	local ok, err = pcall(function()
		localSurface(raiser)
	end)
	assert(not ok, "raised")
	local got = blameLine(err)
	if got == lineAt then
		print("observed: frame visible (no inlining) — tag matched")
	elseif got == raiseLine then
		print("observed: INLINED — tag invisible, raise-site fallback fired (-O2 behavior)")
	else
		error(`unexpected blame line {tostring(got)} (frame {lineAt} / fallback {raiseLine}): {tostring(err)}`)
	end
	print("PASS")
end

print()
print("=== 2. 테이블 경유 호출(quad의 실제 모양) — 어느 플래그에서도 태그가 보여야 한다 ===")
do
	local Err = QuadError.new()
	local T = {
		lineAt = 0,
		surface = function(self: any, fn: () -> ())
			self.lineAt = (debug.info(1, "l") :: number) + 1
			fn()
		end,
	}
	Err.setFuncLevel(T.surface, SURFACE)

	local function raiser()
		Err.errorAt("table-probe", SURFACE)
	end
	local ok, err = pcall(function()
		T:surface(raiser)
	end)
	assert(not ok, "raised")
	assert(
		blameLine(err) == T.lineAt,
		`table-called tagged frame must stay visible under every flag, got {tostring(err)}`
	)

	-- errorBefore: the tagged frame's caller (the single-line call below)
	local function raiserBefore()
		Err.errorBefore("table-before-probe", SURFACE)
	end
	local callLine = 0
	local ok2, err2 = pcall(function()
		callLine = debug.info(1, "l") :: number -- ⚠️ the call is the NEXT line:
		T:surface(raiserBefore)
	end)
	-- (the capture sits on its own line; the call is the NEXT line)
	callLine += 1
	assert(not ok2, "raised")
	assert(
		blameLine(err2) == callLine,
		`errorBefore blames the table call site, got {tostring(err2)} (want {callLine})`
	)
	print("PASS")
end

print()
print("=== 3. Nearest 쌍 — 테이블 경유 안쪽 태그 프레임 ===")
do
	local Err = QuadError.new()
	local T = {} :: any
	T.lineAt = 0
	T.inner = function(fn: () -> ())
		T.lineAt = (debug.info(1, "l") :: number) + 1
		fn()
	end
	T.outer = function(fn: () -> ())
		T.inner(fn)
	end
	Err.setFuncLevel(T.inner, SURFACE)
	Err.setFuncLevel(T.outer, SURFACE)

	local function raiser()
		Err.errorAtNearest("near-probe", SURFACE)
	end
	local ok, err = pcall(function()
		T.outer(raiser)
	end)
	assert(not ok, "raised")
	assert(blameLine(err) == T.lineAt, `errorAtNearest picks the INNER tagged frame: {tostring(err)}`)
	print("PASS")
end

print()
print("=== 4. 코루틴 — 안쪽 태그는 정상, 리주머의 태그는 안 보이고 raise 자리 폴백 ===")
do
	local Err = QuadError.new()

	-- (a) tags INSIDE the coroutine's own stack: normal behavior
	local T = {} :: any
	T.lineAt = 0
	T.surface = function(fn: () -> ())
		T.lineAt = (debug.info(1, "l") :: number) + 1
		fn()
	end
	Err.setFuncLevel(T.surface, SURFACE)
	local co = coroutine.create(function()
		T.surface(function()
			Err.errorAt("co-probe", SURFACE)
		end)
	end)
	local ok, err = coroutine.resume(co)
	assert(not ok, "raised inside coroutine")
	assert(blameLine(err) == T.lineAt, `tagged frame inside the coroutine stack is walked: {tostring(err)}`)

	-- (b) tags only on the RESUMER's stack: the coroutine's walk cannot see
	-- them — documented fallback = the raise site (H-250 explorer data)
	local Err2 = QuadError.new()
	local R = {} :: any
	R.surface = function(fn: () -> ())
		fn()
	end
	Err2.setFuncLevel(R.surface, SURFACE)
	local raiseLine = 0
	local ok2, err2
	R.surface(function()
		local co2 = coroutine.create(function()
			raiseLine = (debug.info(1, "l") :: number) + 1
			Err2.errorAt("cross-probe", SURFACE)
		end)
		ok2, err2 = coroutine.resume(co2)
	end)
	assert(not ok2, "raised across the boundary")
	assert(
		blameLine(err2) == raiseLine,
		`resumer tags invisible -> fallback blames the raise site: {tostring(err2)}`
	)
	print("PASS")
end

print()
print("=== ALL PASS ===")
