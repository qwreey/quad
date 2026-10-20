--!strict
--[[
	InitBookkeeping(module) — the Length/Offset bookkeeping subsystem,
	installed as the `module.Bookkeeping` namespace (`H-277`,
	user-directed split: Dispatch's mandate is process/handler matching, and
	this half — prefix sums, cursors, batch Blockers — is a separate concern
	that Slot must reach WITHOUT going through Dispatch). Dependency direction
	is {Slot, Dispatch} -> Bookkeeping: this module requires neither. It does
	know the Slot owner's shape — a Slot keeps its bk as `ownerKey._bk`
	(getBookkeeping) and its Offset/Length are Sources read and set here
	(getOffsetAt, recompute) — and Slot in turn installs two functions on this
	namespace after the fact (`claimOwnerAt`/`releaseOwner`, Slot/init.luau),
	so `QuadTypes.Bookkeeping` is filled from both files.

	[2026-09-15 공개 표면 (30) 사용자 결정] The public calling surface is this namespace itself —
	`quad.Bookkeeping.setLength` etc., typed `QuadTypes.Bookkeeping`. Before, the six were re-exported
	on the Dispatch table and this table was the private `_bookkeeping`. Slot captures it directly
	(`H6-2`); `_recompute` stays internal (`_` prefix).

	Sources, as-is: `dispatch-core-plan.md` "Length/Offset" / "두 필드" /
	"배치 등록을 안전하게 만드는 Blocker 게이팅". The one user-code window the
	pass defends is the Offset `:Set` (a subscriber's CRUD lowers the cursor and
	the pass rewinds — a defined path, capped by `Quad0267`). The `:Get()` read
	windows (a Compute length's fn) are not defended: a fn that lowers a cursor
	breaks Compute purity (undefined) — the 2026-09-01 `H-240` (a) checks and
	getOffsetAt's restart branch were removed (round14 Q171 (a), user decision
	2026-10-06).
]]

local Relate = require("./Relate")
local Brand = require("./Brand")
local Blocker = require("./Blocker")
local Err = require("./ErrorNamespace")
local QuadTypes = require("../luau_packages/quad_types")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- ── rewind limit (always on — not a debug-layer check) ──
-- 2026-10-02 (user decision — *"부기 되감기에 상한 두는거, effect 랑 동일하게 일관적이게 둬도 될 것
-- 같아. 같은 한도로."*): `recompute`'s rewinds are capped like `Effect.luau`'s deferred re-run loop
-- (`RERUN_LIMIT`, `Quad0263`). The Slot `Offset`/`Length` CRUD loop is a defined path because the
-- rewind converges it; a subscriber that flips a length before the cursor on every value it sees
-- never converges, and the rewind is a `continue` in one `while` — no stack overflow would ever stop
-- it. The pass counts REWINDS, not iterations: an ordinary pass over a long list (any N) rewinds 0
-- times. Its own constant with the same number (`B2` — two different loops, no shared body): keep the
-- two in step by hand.
local REWIND_LIMIT = 10000

-- One rewind more; raises past `REWIND_LIMIT`. Outermost blame: the user's line that started the pass
-- (the CRUD / `:Set` / `setLength` that reached `recompute`). Raised inside the
-- `recomputeBlocker:On`/`Off` window, so the owner stays frozen afterwards — like any throw there
-- (`architecture.md` "예외 안전성 계약": no integrity after a throw).
local function countRewind(rewinds: number): number
	rewinds += 1
	if rewinds > REWIND_LIMIT then
		Err.errorBefore(
			`Quad0267 Bookkeeping.recompute: rewound {REWIND_LIMIT} times in one pass - a subscriber keeps changing a length before the position it is told about (a Slot Offset callback that adds and removes on every value never settles)`,
			SURFACE
		)
	end
	return rewinds
end

local function Init(module: any)
	local None = module.None -- sentinel set by the top-level entry before Inits run

	-- ownerKey(weak) -> bk. Weak VALUE + gchold anchor (`H-229` pattern): the
	-- observers stored in bk hold gatedRecompute closures that capture
	-- ownerKey, so a strong Relate value would back-reference its own weak key
	-- (`H-71` — the exact chains leak, one shelf over).
	-- Only claimable insts use this weak map: a Slot ownerKey keeps its bk
	-- strongly as `slot._bk` (getBookkeeping's SlotBrand branch, `H-232` (a)).
	local bookkeeping = Relate()
	-- ownerKey(weak) -> batch Blocker. Strong is fine here: a Blocker holds no
	-- reference back to the ownerKey, so the weak key still collects.
	local blockers = Relate()

	-- `H-256` (a): the one validation gate for array positions entering the
	-- bookkeeping arithmetic — a fractional/negative/zero/NaN position poisons
	-- the prefix sums and can freeze recomputeBlocker permanently (silent
	-- worst-case UB), so both entry points reject it up front. Sparse positive
	-- integers stay legal here; recompute's existing sourceList nil error owns
	-- contiguity. User-input class -> nearest blame (the handler that called).
	local function checkPosition(fnName: string, i: any)
		if type(i) ~= "number" or i % 1 ~= 0 or i <= 0 then
			Err.errorBeforeNearest(`Quad0019 Bookkeeping.{fnName}: position must be a positive integer (got {tostring(i)})`, SURFACE)
		end
	end
	-- `H-504` (2026-09-08 round8 K-2): every public bookkeeping entry with a nil owner died in
	-- Relate (`Relate:GetWeak: inst must not be nil` on a Bookkeeping.luau line) — the leaf
	-- module's name, not the surface the user called. `H-447`'s gate had reached `bindLifetime`
	-- only. Nearest: these are direct-call surfaces.
	local function checkOwner(fnName: string, ownerKey: any)
		if ownerKey == nil then
			Err.errorBeforeNearest(`Quad0020 Bookkeeping.{fnName}: ownerKey must not be nil`, SURFACE)
		end
	end

	local function getBlocker(ownerKey: any): any
		checkOwner("getBlocker", ownerKey) -- `H-499`/`H-504`
		local blocker = blockers:GetStrong(ownerKey, "blocker")
		if blocker == nil then
			blocker = Blocker()
			blockers:SetStrong(ownerKey, "blocker", blocker)
		end
		return blocker
	end

	-- Never returns nil — lazy creation ("`getBookkeeping(ownerKey)`은 절대
	-- `nil`을 돌려주지 않는다"; callers must not re-guard). Initial values are
	-- contract (`H-4`): the two cursors start at 0, only `N` stays nil ("아직
	-- 아무 자리도 등록 안 됨"과 "0번까지 유효"는 다른 뜻).
	local function newBk(): any
		return {
			lengthList = {},
			sourceList = {},
			observers = {},
			N = nil,
			offsetCache = {},
			offsetCacheValidUpTo = 0,
			offsetSetUpTo = 0,
			recomputeBlocker = Blocker(),
			-- element(inst|slot) -> position. Weak keys (`H-145`): the
			-- top-level release setLength(…, 0) carries no element arg, so
			-- stale keys must fall out on their own. Alive-while-mounted is
			-- guaranteed elsewhere (slot._elements / gatedRecompute capture).
			indexOfElement = setmetatable({}, { __mode = "k" }),
		}
	end

	-- `H6-1` (M6 fork, `H-232` (a)): a Slot ownerKey cannot be bindLifetime'd
	-- (not claimable — mock's isMockInstance / the roblox H-290 fail-fast both
	-- reject it) and its bk must survive unmounts, so the Slot owns its bk
	-- STRONGLY as `slot._bk` (Slot constructor seeds it nil; this fills it
	-- lazily). Physical-inst owners keep the weak Relate + gchold anchor path.
	local function getBookkeeping(ownerKey: any): any
		checkOwner("getBookkeeping", ownerKey)
		if Brand.isSlot(ownerKey) then
			local bk = ownerKey._bk
			if bk == nil then
				bk = newBk()
				ownerKey._bk = bk -- strong; lives exactly as long as the Slot
			end
			return bk
		end
		local bk = bookkeeping:GetWeak(ownerKey, "bk")
		if bk == nil then
			bk = newBk()
			module.Backend.bindLifetime(ownerKey, bk)
			bookkeeping:SetWeak(ownerKey, "bk", bk)
		end
		return bk
	end


	-- Q15 (a) (사용자 결정 2026-09-07): the length domain is the non-negative integers — a
	-- negative/fractional length used to flow into `nativeInsert(target, 음수)` silently and a
	-- non-number State value died in recompute's arithmetic with the blocker locked (`H-394`).
	-- Constants are checked at registration; a State's value is checked in ITS OBSERVER, which
	-- runs before gatedRecompute — round3 `H-445`: checking inside `contribution` threw inside
	-- the recomputeBlocker On/Off window and left the owner frozen for good (the very failure
	-- `checkPosition`'s header says to keep out of the window).
	local function checkLengthValue(fnName: string, n: any)
		if type(n) ~= "number" or n % 1 ~= 0 or n < 0 then
			Err.errorBeforeNearest(`Quad0021 Bookkeeping.{fnName}: length must be a non-negative integer (got {tostring(n)})`, SURFACE)
		end
	end

	local function contribution(bk: any, i: number): number
		local v = bk.lengthList[i]
		return if Brand.isState(v) then v:Get() else v -- validated by the observer (`H-445`), never here
	end

	-- Absolute offset (0-based count) of position `at` — single function with
	-- a prefix-sum cache. A length's `:Get()` may run a Compute fn (pure by
	-- contract, C2); user code there that changes this owner's bookkeeping is
	-- undefined — not detected, not restarted (round14 Q171 (a), user decision
	-- 2026-10-06: the `H-240` (a) restart branch and the incremental cursor it
	-- relied on were removed; the cursor is written once after the fill). The
	-- original repro (a fn touching its own owner) raises State's re-entry
	-- error first (round10 Q50 (a)) and, unwinding through recompute's On/Off
	-- window, leaves the owner frozen like any throw there (spec.lengthoffset 10).
	-- bootstrap: position 1's offset is this owner's base itself — a Slot's own
	-- .Offset, or 0 for a physical inst (no base concept). A base change lowers
	-- both cursors to 0 (Slot `_baseObserver`, `H-350`), so the next query
	-- re-reads it here. Init-scope like `contribution` (0순회 `H-365`: a
	-- per-call closure was allocated N times per recompute).
	local function ensureBase(bk: any, ownerKey: any)
		if bk.offsetCacheValidUpTo == 0 then
			bk.offsetCache[1] = if Brand.isSlot(ownerKey) then ownerKey.Offset:Get() else 0
			bk.offsetCacheValidUpTo = 1
		end
	end

	local function getOffsetAt(ownerKey: any, at: number): number
		checkOwner("getOffsetAt", ownerKey)
		checkPosition("getOffsetAt", at) -- 공개 표면 셋 중 하나 (`H-256`/`H-280`)
		local bk = getBookkeeping(ownerKey)
		ensureBase(bk, ownerKey)
		if at <= bk.offsetCacheValidUpTo then
			return bk.offsetCache[at]
		end
		local i = bk.offsetCacheValidUpTo
		local cur = bk.offsetCache[i]
		while i < at do
			if bk.lengthList[i] == nil then
				-- 5순회 `H-397` / 6순회 `H-408`: a missing position has TWO causes and
				-- this line cannot tell them apart — a query past N+1 (user input) or
				-- a leaf handler that skipped its `H-39` registration (a hole that,
				-- because registration is ascending, also looks like a tail). Say
				-- both. Outermost blame: this runs under the sibling surface
				-- `setOffsetSource` and at dispatch depth (materialize), where
				-- nearest landed on `Bookkeeping.luau` itself (`H-378` lesson).
				-- `bk.N` is the max registered position by contract (grows in
				-- setLength, shifts in splice, reset with the list).
				local last = bk.N or 0
				-- 7순회 `H-427`: name the range cause only when the query IS past N+1 —
				-- with a hole below N the range clause called a legal query illegal
				Err.errorBefore( -- error-code: inline if
					if at > last + 1
						then `Quad0022 Bookkeeping.getOffsetAt: position {at} is past N+1 (N = {last}, at most {last + 1} may be queried) - or a leaf handler skipped its position registration: position {i} is not registered`
						else `Quad0229 Bookkeeping.getOffsetAt: position {at} needs positions 1..{at - 1} registered but {i} is not - a leaf handler skipped its position registration`,
					SURFACE
				)
			end
			cur += contribution(bk, i) -- a Compute length's fn runs here (pure by contract)
			bk.offsetCache[i + 1] = cur -- this slot's length decides the NEXT slot's offset
			i += 1
		end
		bk.offsetCacheValidUpTo = at
		return cur
	end

	-- Full pass: reentry blocked by bk.recomputeBlocker, upper bound re-read
	-- every iteration, rewind when a subscriber of an Offset `:Set` lowered
	-- offsetSetUpTo mid-pass (`H-101`/`H-113`/`H-124`; at most `REWIND_LIMIT`
	-- rewinds per pass — `Quad0267`, 2026-10-02). The `:Get()` read windows
	-- (getOffsetAt above, contribution below) are not checked: a Compute length's
	-- fn that lowers a cursor is undefined (round14 Q171 (a), 2026-10-06 — the
	-- `H-240` (a) checks ① ② were removed), so the Set window is the one rewind
	-- point and the one place `countRewind` runs.
	local function recompute(ownerKey: any, bk: any)
		local sum = 0
		bk.recomputeBlocker:On()
		local prefix, i = {} :: { number }, 1
		local rewinds = 0 -- this pass's rewind count (`REWIND_LIMIT`)
		while i <= (bk.N or 0) do
			prefix[i] = sum
			local offset = bk.sourceList[i]
			-- None is truthy — must be excluded explicitly; nil means broken
			-- bookkeeping (`C-6`: the contract says None), never skip quietly.
			if offset == nil then
				error(`Quad0023 Bookkeeping.recompute: sourceList[{i}] is nil - a nil hole in the numeric-key part of props (\{ a, nil, b })? fill the optional slot with q.None (the children placed before this raise stay seated in the half-built Instance, reachable as child.Parent - q.dispose that Instance to clean up; it takes those children with it, so build the retry with new ones); if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)`, 1) -- `H-472`: name the mirror of the lengthList check below
			end
			if offset == None then
				-- No publish channel (a leaf) — nothing to Set, so no `abs` is needed and
				-- no user code ran since the entry snapshot: advance the cursor directly
				-- (2026-09-08 advisory RFC, user decision `H-483`). The prefix cache is NOT
				-- warmed here any more — `getOffsetAt` fills it on demand where a number is
				-- actually pulled (`nativeInsert` offsets, List's physIndex), which used to
				-- duplicate this pass one-for-one on a flat list.
				bk.offsetSetUpTo = i
			else
				local abs = getOffsetAt(ownerKey, i)
				bk.offsetSetUpTo = i -- Set done up to here
				if offset:Get() ~= abs then
					offset:Set(abs) -- ← user code can run here
				end
			end
			-- `H-124`: rewind check BEFORE reading lengthList[i] — user code in
			-- the Get/Set above may have removed slots past the cursor, and dying
			-- between recomputeBlocker:On/Off would freeze this owner forever.
			if bk.offsetSetUpTo < i then
				-- resume AT the lowered slot (`+1` was wrong: prefix[j+1] was
				-- accumulated with the OLD lengthList[j]); clamp to 1 —
				-- offsetSetUpTo can legally be 0 ("1번부터 전부 다시").
				rewinds = countRewind(rewinds)
				i = math.max(bk.offsetSetUpTo, 1)
				sum = prefix[i]
				continue
			end
			-- `H-244`: same single coercion as getOffsetAt's cache fill — two
			-- inline copies would drift when the coercion gains a case (M6).
			-- 7순회 `H-427`: C-6's sibling — a `lengthList` hole (a provider that called
			-- setOffsetSource without setLength) died as an anonymous arithmetic error
			-- inside recomputeBlocker:On, freezing the owner. Internal invariant.
			if bk.lengthList[i] == nil then
				error(`Quad0024 Bookkeeping.recompute: lengthList[{i}] is nil - bookkeeping is broken (setOffsetSource without setLength?)`, 1)
			end
			sum += contribution(bk, i)
			i += 1
		end
		bk.offsetSetUpTo = bk.N or 0
		bk.recomputeBlocker:OffWithoutEmit()
		if Brand.isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
			ownerKey.Length:Set(sum) -- Length carries no base — length is position-free
		end
	end

	-- `setLength(ownerKey, i, len, anchor?, element?)` — the one place that
	-- owns calling recompute for length changes (`H-19`). `anchor` is the
	-- lifetime anchor (physical Instance; defaults to ownerKey — only Slot
	-- owners pass it explicitly, `C-4`). `element` is the registered occupant
	-- for the position (`H-141`/Q3): the persistent closure captures it and
	-- looks the current index up in bk.indexOfElement instead of freezing `i`;
	-- constant-length slots omit it.
	-- Init-scope (4순회 `H-390`, the `H-365` family): a per-call closure was built
	-- for every constant-length element too (N per mount) and thrown away after one
	-- call. Current position by element lookup, not captured index (`H-102`).
	local function gatedRecompute(bk: any, blocker: any, ownerKey: any, element: any, i: number)
		local cur = if element ~= nil then bk.indexOfElement[element] else i
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, cur)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, cur)
		if blocker.Blocking then
			return -- batch registration in progress
		end
		if bk.recomputeBlocker.Blocking then
			return -- recompute reentry — the outer pass's rewind picks it up
		end
		recompute(ownerKey, bk)
	end

	local function setLength(ownerKey: any, i: number, len: any, anchor: any?, element: any?)
		checkOwner("setLength", ownerKey)
		checkPosition("setLength", i)
		if not Brand.isState(len) then
			checkLengthValue("setLength", len) -- a State's value is checked in its Observer callback below, outside the blocker window (`H-445`) — never in `contribution`
		else
			-- round13 Q151 (가) (user decision 2026-10-01): the State's CURRENT value too, BEFORE any
			-- bookkeeping write (`H-256` (a)'s promise) — an invalid initial value used to raise only in
			-- the observer's install run, after `lengthList[i]`/`N` were written: offsets silently wrong
			-- and that position never moved again. A Compute is computed here (one read earlier than
			-- the install run, which follows synchronously). Later values: the observer below, as before.
			checkLengthValue("setLength", len:Get())
		end
		anchor = anchor or ownerKey
		local bk = getBookkeeping(ownerKey)
		local blocker = getBlocker(ownerKey)

		local oldObserver = bk.observers[i]
		if oldObserver then
			module.Backend.unbindLifetime(oldObserver) -- no need to know gchold internals or which inst
			bk.observers[i] = nil
		end

		bk.lengthList[i] = len
		bk.N = math.max(bk.N or 0, i) -- N lifecycle: grows here only ("저장 위치" 절)
		if element ~= nil then
			bk.indexOfElement[element] = i -- splice-time rewrites are the Slot layer's job (reindexFrom)
		end
		-- invalidation pulls BOTH cursors to `i` — position i's own offset is
		-- the sum of 1..i-1 and does not change; everything AFTER it does.
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, i)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, i)

		if Brand.isState(len) then
			local observer = len:_internalObserver(function() -- quad's own: `_internal` from birth (Observer debug check skips it)
				checkLengthValue("setLength", len:Get()) -- `H-445`: outside the blocker window; nearest = the `:Set` line
				gatedRecompute(bk, blocker, ownerKey, element, i)
			end) -- immediate first run is gated too
			module.Backend.bindLifetime(anchor, observer) -- physical target's lifetime, not :Subscribe()
			bk.observers[i] = observer
		else
			gatedRecompute(bk, blocker, ownerKey, element, i) -- constants go through the same gate, no closure (4순회 `H-390`)
		end
	end

	-- Registration + (if there is a publish channel) one immediate Set — the
	-- batch is processed in order so 1..i-1 are always already registered.
	-- None means "no publish channel", NOT "not participating" (that is
	-- lengthList's answer); pull the number via getOffsetAt when needed.
	local function setOffsetSource(ownerKey: any, i: number, source: any)
		checkOwner("setOffsetSource", ownerKey)
		checkPosition("setOffsetSource", i)
		if source ~= None and not Brand.isSource(source) then
			-- Q13 (b) (사용자 결정 2026-09-07): `checkPosition`'s sibling — a wrong `source` used to
			-- die at `:Get()` with a Bookkeeping.luau line
			Err.errorBeforeNearest(`Quad0025 Bookkeeping.setOffsetSource: source must be a Source<number> or None (got {typeof(source)})`, SURFACE)
		end
		local bk = getBookkeeping(ownerKey)
		if source == None then
			bk.sourceList[i] = None
			return
		end
		-- 5순회 `H-392`: read the source BEFORE writing bookkeeping — a wrong
		-- `source` (a plain table, say) used to raise on `:Get()` with
		-- `sourceList[i]` already written, and the next unrelated `setLength`
		-- then died inside `recomputeBlocker:On()`, freezing this owner's offset
		-- arithmetic for good (`dispatch-core-plan.md` `H-256` (a): "부기를 하나라도
		-- 만지기 전에 검사한다"). A type gate on `source` itself is §4 Q13.
		local offset = getOffsetAt(ownerKey, i)
		local current = source:Get()
		bk.sourceList[i] = source
		if current ~= offset then
			source:Set(offset)
		end
	end

	-- The terminal "empty slot" registration every nop/leaf handler does:
	-- offsetSource FIRST, then length 0 — the release-order contract (`H-39`,
	-- setLength ends in gatedRecompute). One body so the order cannot drift
	-- between the terminal sites; on the Dispatch surface (not a quad-base
	-- module helper) so quad-roblox handlers (`OnChange`, `InstanceChild`)
	-- reach it too — post-implementation review Q3 ③, user-approved name
	-- (2026-09-07: "setEmpty 같은걸 넣어도 큰 문제는 없어보이겠다"). `anchor`
	-- is setLength's 4th argument (`inst`, `H-35`); NilHandler passes none.
	local function setEmpty(ownerKey: any, i: number, anchor: any?)
		checkOwner("setEmpty", ownerKey)
		-- [round3 `H-434`] validate HERE: this function sits on the Dispatch table, so the
		-- `H-242` loop tags it SURFACE — if the inner (also tagged) setOffsetSource raised,
		-- nearest+1 would be this body, not the handler that called setEmpty.
		checkPosition("setEmpty", i)
		setOffsetSource(ownerKey, i, None)
		setLength(ownerKey, i, 0, anchor)
	end

	module.Bookkeeping = {
		-- 2026-10-01 (user decision, round13 Q152 follow-up): the batch Blocker is internal — `drive` and
		-- the Slot layer own its On/close-with-recompute; a public `getBlocker` let a handler open a batch
		-- it could not close correctly (the closing recompute is private). Diagnostics read `getBookkeeping`.
		_getBlocker = getBlocker, -- internal (Slot/Dispatch only)
		getBookkeeping = getBookkeeping,
		getOffsetAt = getOffsetAt,
		_recompute = recompute, -- internal (Slot/Dispatch only)
		setLength = setLength,
		setOffsetSource = setOffsetSource,
		setEmpty = setEmpty,
	}
	-- the public six join the error tag layer here now that they are off the Dispatch table (its `H-242`
	-- loop used to tag them) — handler-depth raises keep blaming the handler author's call
	for key, v in module.Bookkeeping :: { [string]: any } do
		if type(v) == "function" and string.sub(key, 1, 1) ~= "_" then
			Err.setFuncLevel(SURFACE, v)
		end
	end
end

return Init
