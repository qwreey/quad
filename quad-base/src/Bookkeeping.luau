--[[
	InitBookkeeping(module) — the Length/Offset bookkeeping subsystem,
	installed as the private `module._bookkeeping` namespace (`H-277`,
	user-directed split: Dispatch's mandate is process/handler matching, and
	this half — prefix sums, cursors, batch Blockers — is a separate concern
	that M6's Slot must reach WITHOUT going through Dispatch. Dependency
	direction is {Slot, Dispatch} -> Bookkeeping: this module knows neither;
	the SlotBrand probe below is brand-leaf discrimination, not a Slot
	dependency).

	The PUBLIC calling surface stays `quad.Dispatch.setLength` etc. — the
	terminal-handler contract (H-39/H-25) is written against those names, so
	InitDispatch re-exports these same function objects (no wrappers). Slot
	wiring landed (M6 편입, 2026-09-03) without renaming — Slot captures
	`module._bookkeeping` directly (`H6-2`), the public names are untouched.

	Sources, as-is: `dispatch-core-plan.md` "Length/Offset" / "두 필드" /
	"배치 등록을 안전하게 만드는 Blocker 게이팅" — plus the `H-240` (a)
	reinforcement (2026-09-01, user-confirmed): cursor writes never stomp a
	rewind signal raised in a `:Get()` read window — checks sit before every
	write, and getOffsetAt self-heals by restarting from a lowered cache
	cursor.
]]

local Relate = require("./Relate")
local Brand = require("./Brand")
local Blocker = require("./Blocker")
local Err = require("./ErrorNamespace")
local QuadTypes = require("../luau_packages/quad_types")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function Init(module: any)
	local None = module.None -- sentinel set by the top-level entry before Inits run

	-- ownerKey(weak) -> bk. Weak VALUE + gchold anchor (`H-229` pattern): the
	-- observers stored in bk hold gatedRecompute closures that capture
	-- ownerKey, so a strong Relate value would back-reference its own weak key
	-- (`H-71` — the exact chains leak, one shelf over).
	-- M6 note (`H-232` (a), user-confirmed): a Slot ownerKey cannot be
	-- bindLifetime'd (not claimable) and its bk must outlive unmounts, so the
	-- SLOT owns its bk strongly as `slot._bk` — getBookkeeping branches on
	-- SlotBrand when M6 lands. Until then only claimable insts reach this path.
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
			Err.errorBeforeNearest(`quad.Dispatch.{fnName}: position must be a positive integer, got {tostring(i)}`, SURFACE)
		end
	end

	local function getBlocker(ownerKey: any): any
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
	-- The header predicted this branch "when M6 lands" — this is that.
	local function getBookkeeping(ownerKey: any): any
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
			module.bindLifetime(ownerKey, bk)
			bookkeeping:SetWeak(ownerKey, "bk", bk)
		end
		return bk
	end


	local function contribution(bk: any, i: number): number
		local v = bk.lengthList[i]
		return if Brand.isState(v) then v:Get() else v
	end

	-- Absolute offset (0-based count) of position `at` — single function with
	-- a prefix-sum cache. `H-240` (a): the cache cursor now advances
	-- INCREMENTALLY as entries are written (invariant: cursor == i at the top
	-- of each fill step), so a lowering raised by user code inside a length's
	-- `:Get()` is detectable against it, and the fill RESTARTS from the
	-- lowered point instead of a tail write stomping the signal. Safe to
	-- restart freely — this is a pure cache fill, no Sets.
	-- Recognized UB boundary (documented, not defended): user code inside
	-- position i's own `:Get()` REPLACING that same position's length entry
	-- (`setLength(owner, i, …)` mid-read) — a lowering exactly TO the cursor
	-- is indistinguishable from the no-op baseline, kin to the standing
	-- "재진입/자기 재정의 무방어" family.
	-- bootstrap: position 1's offset is this owner's base itself — a Slot's own
	-- .Offset, or 0 for a physical inst (no base concept). Also re-run when a
	-- restart lands on 0 (`H-350`): a base change lowers both cursors to 0 (Slot
	-- `_baseObserver`), and restarting from the stale `offsetCache[1]` would
	-- rebuild the whole cache on the old base. Init-scope like `contribution`
	-- (0순회 `H-365`: a per-call closure was allocated N times per recompute).
	local function ensureBase(bk: any, ownerKey: any)
		if bk.offsetCacheValidUpTo == 0 then
			bk.offsetCache[1] = if Brand.isSlot(ownerKey) then ownerKey.Offset:Get() else 0
			bk.offsetCacheValidUpTo = 1
		end
	end

	local function getOffsetAt(ownerKey: any, at: number): number
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
				Err.errorBefore(
					if at > last + 1
						then `Dispatch.getOffsetAt: position {at} is past N+1 (N = {last}, at most {last + 1} may be queried) — or a leaf handler skipped its position registration (H-39): position {i} is not registered`
						else `Dispatch.getOffsetAt: position {at} needs positions 1..{at - 1} registered but {i} is not — a leaf handler skipped its position registration (H-39)`,
					SURFACE
				)
			end
			cur += contribution(bk, i) -- ← a State length's Get can run user code
			if bk.offsetCacheValidUpTo < i then
				-- `H-240`: that user code invalidated below us — entries past
				-- the lowered cursor were built on stale lengths; restart there.
				-- A lowering to 0 (M6: splice's j-1 = 0, or the owner's base
				-- moved) re-reads the base first — `ensureBase` leaves the
				-- cursor at 1 on a fresh `offsetCache[1]`.
				ensureBase(bk, ownerKey)
				i = bk.offsetCacheValidUpTo
				cur = bk.offsetCache[i]
				continue
			end
			bk.offsetCache[i + 1] = cur -- this slot's length decides the NEXT slot's offset
			bk.offsetCacheValidUpTo = i + 1 -- incremental — never past what was just written
			i += 1
		end
		return cur
	end

	-- Full pass: reentry blocked by bk.recomputeBlocker, upper bound re-read
	-- every iteration, rewind when someone lowered offsetSetUpTo mid-pass.
	-- `H-240` (a) reinforcement (2026-09-01): the ORIGINAL check guarded only
	-- the offset:Set window (`H-101`/`H-113`/`H-124`); user code can also run
	-- inside the `:Get()` reads (getOffsetAt above, contribution below), and
	-- the unconditional cursor writes right after those reads erased the
	-- signal. Now every cursor write is preceded by its own check — and loop
	-- exit therefore implies "no user code since the last check", making the
	-- two tail writes safe by construction.
	local function recompute(ownerKey: any, bk: any)
		local sum = 0
		bk.recomputeBlocker:On()
		local prefix, i = {} :: { number }, 1
		while i <= (bk.N or 0) do
			prefix[i] = sum
			-- entry snapshot: the read window below may lower the cursor; the
			-- baseline differs by path (i-1 normally, i right after a rewind),
			-- so compare against what we actually entered with.
			local entryCursor = bk.offsetSetUpTo
			local offset = bk.sourceList[i]
			-- None is truthy — must be excluded explicitly; nil means broken
			-- bookkeeping (`C-6`: the contract says None), never skip quietly.
			if offset == nil then
				error(`Dispatch.recompute: sourceList[{i}] is nil — bookkeeping is broken (the contract says None)`, 1)
			end
			local abs = getOffsetAt(ownerKey, i)
			-- `H-240` check ① — BEFORE the write below stomps the signal
			if bk.offsetSetUpTo < entryCursor then
				i = math.max(bk.offsetSetUpTo, 1)
				sum = prefix[i]
				continue
			end
			bk.offsetSetUpTo = i -- Set done up to here
			if offset ~= None and offset:Get() ~= abs then
				offset:Set(abs) -- ← user code can run here
			end
			-- `H-124`: rewind check BEFORE reading lengthList[i] — user code in
			-- the Get/Set above may have removed slots past the cursor, and dying
			-- between recomputeBlocker:On/Off would freeze this owner forever.
			if bk.offsetSetUpTo < i then
				-- resume AT the lowered slot (`+1` was wrong: prefix[j+1] was
				-- accumulated with the OLD lengthList[j]); clamp to 1 —
				-- offsetSetUpTo can legally be 0 ("1번부터 전부 다시").
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
				error(`Dispatch.recompute: lengthList[{i}] is nil — bookkeeping is broken (setOffsetSource without setLength?)`, 1)
			end
			sum += contribution(bk, i)
			-- `H-240` check ② — contribution's own Get window; the possibly
			-- stale += above is discarded by the rewind's prefix restore.
			if bk.offsetSetUpTo < i then
				i = math.max(bk.offsetSetUpTo, 1)
				sum = prefix[i]
				continue
			end
			i += 1
		end
		-- Tail writes are safe: the loop only exits right after a passed check
		-- with no user-code window in between (`H-240`).
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
		if blocker:IsOn() then
			return -- batch registration in progress
		end
		if bk.recomputeBlocker:IsOn() then
			return -- recompute reentry — the outer pass's rewind picks it up
		end
		recompute(ownerKey, bk)
	end

	local function setLength(ownerKey: any, i: number, len: any, anchor: any?, element: any?)
		checkPosition("setLength", i)
		anchor = anchor or ownerKey
		local bk = getBookkeeping(ownerKey)
		local blocker = getBlocker(ownerKey)

		local oldObserver = bk.observers[i]
		if oldObserver then
			module.unbindLifetime(oldObserver) -- no need to know gchold internals or which inst
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
			local observer = len:Observer(function()
				gatedRecompute(bk, blocker, ownerKey, element, i)
			end) -- immediate first run is gated too
			module.bindLifetime(anchor, observer) -- physical target's lifetime, not :Subscribe()
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
		checkPosition("setOffsetSource", i)
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
		setOffsetSource(ownerKey, i, None)
		setLength(ownerKey, i, 0, anchor)
	end

	module._bookkeeping = {
		getBlocker = getBlocker,
		getBookkeeping = getBookkeeping,
		getOffsetAt = getOffsetAt,
		recompute = recompute,
		setLength = setLength,
		setOffsetSource = setOffsetSource,
		setEmpty = setEmpty,
	}
end

return Init
