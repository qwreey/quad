--!strict
--[[
	Slot/List.luau — the :List/:Single install path: identityUpdateFn,
	`Slot_mt._activateList` (the reconcile closure — settle/reconcile/detachCleanup),
	the checkListInstall gate, and the public `Slot_mt.List` / `Slot_mt.Single`.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol); the two public methods land on the shared `Slot_mt` and
	are tagged by init's setFuncLevel call. Behaviour and comments are the moved
	originals.
]]

local Types = require("./types")
local ModuleIdentity = require("../ModuleIdentity")
local StateHandler = require("../StateHandler") -- round13 Q113 (a): the shared Quad0070 chain walk

-- `H-571` data-key gate: the one Quad0143 literal — reconcile's O(1) check and the debug pass below both raise it.
local function notArrayKey(k: any): boolean
	return type(k) ~= "number" or k % 1 ~= 0 or k < 1
end
local function dataKeyMessage(k: any): string
	return `Quad0143 Slot:List: data must be a plain array - key "{tostring(k)}" is not an array position`
end

return function(S: Types.SlotInternal, module: any)

	-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
	-- [2026-10-01 user decision — "debug 로 내리기에 동의해"] the full key pass over `:List` data: O(N) on
	-- every reconcile, so it runs only with `q.debug` on. What only it catches: an array that ALSO carries
	-- non-array keys (`{ a, b, x = 1 }` — the extra keys are ignored with debug off).
	-- [2026-10-12 user decision, round14 Q125] the same pass also catches a nil HOLE in the middle
	-- (`{ "a", nil, "c" }`): every key is a positive integer by then, so "fewer keys than the highest
	-- key" is a hole — no second pass. With debug off the hole stays undefined: `ipairs` stops there
	-- and the items behind it go down the KeyGone path, their elements DESTROYED, silently. (The usual
	-- path cannot check it: reconcile pays O(1) only, and `#items` may sit at the border before the
	-- hole, so comparing it with the `ipairs` length misses holes.)
	local function checkDataKeys(items: any)
		local count, highest = 0, 0
		for k in pairs(items) do
			if notArrayKey(k) then
				S.Err.errorBefore(dataKeyMessage(k), S.SURFACE) -- error-code: via dataKeyMessage
			end
			count += 1
			if k > highest then highest = k end
		end
		if count ~= highest then
			local hole = 1
			while items[hole] ~= nil do hole += 1 end
			S.Err.errorBefore(`Quad0269 Slot:List: data has a nil hole at index {hole} (the array goes on to index {highest}) - the list would end there and every item behind it would be treated as gone, its element destroyed; remove the nil or put a placeholder value there`, S.SURFACE)
		end
	end
	-- [2026-10-06 user decision, round14 Q173 (a)] the `Quad0070` value-chain walk over an identity
	-- `:Single`/`:List`'s items (round13 Q113 (a)): debug layer — with debug off a State item whose chain
	-- loops wraps itself until a stack overflow (undefined).
	local function checkItemChains(items: any)
		for _, item in ipairs(items) do
			StateHandler.assertAcyclicChain(item, nil, S.Err.errorBefore) -- error-code: via StateHandler.assertAcyclicChain
		end
	end

	-- ── :List / :Single (slice 4) ──────────────────────────────────────
	local function identityUpdateFn(ctx: any): any
		local item = ctx.Item
		if item == S.KeyGone then return nil end
		return item
	end

	-- _activateList — called by materializeSlotTree at mount. Fresh path builds
	-- the reconcile closure (mounted/userdata/prevKeys upvalues) + subscribes;
	-- remount path re-anchors only (idempotent guard).
	function S.Slot_mt._activateList(self: any, physicalTarget: any)
		if self._deferred then
			-- `slot:Defer(fn)` [2026-10-15 user decision]: ONE shot — `fn` runs at this Slot's FIRST mount only and
			-- its one value is the content. A remount walks `_elements` like a manual Slot (`Slot/Tree.luau`
			-- materialize) and nothing runs again; to build again, make a new Slot. No State, no Observer, no
			-- Effect — nothing ever reruns (user: "Effect 가 완전 필요하지 않은 경로"). Marked activated BEFORE
			-- `fn` runs: a raise from `fn` is the user's (no pcall) and is not retried by a later mount.
			if self._listActivated then return end
			self._listActivated = true
			local fn = self._deferFn
			self._deferFn = nil
			local out = table.pack(fn())
			if out.n > 1 then
				S.Err.errorBefore(`Quad0272 Slot:Defer: fn must return one value (got {out.n}) - put several elements in a Slot and return that`, S.SURFACE)
			end
			local result = out[1]
			if result ~= nil and result ~= S.None then
				S.rawAdd(self, S.wrapElement(result, S.Err.errorBefore), 1) -- mount depth → outermost, like reconcile
			end
			return
		end
		if self._listActivated then
			-- remount: keep closure state, move the detachCleanup anchor only.
			-- (_listObserver re-bind is materializeSlotTree's tail — H-163.)
			module.Backend.bindLifetime(physicalTarget, self._detachCleanup)
			return
		end
		self._listActivated = true

		local keyFn, updateFn = self._keyFn, self._updateFn
		local offset = self.Offset
		local mounted, userdata, prevKeys = {}, {}, {}

		local function settle(key: any, result: any, detach: boolean, slotPos: number)
			local wasMounted = mounted[key]
			local detached = self._detached
			local wasDetached = detached and detached[key]
			local prev = wasMounted or wasDetached

			if detach then
				if wasMounted ~= nil then
					local idx = S.indexOfRaw(self, wasMounted) :: number
					if self._owned == false then
						S.rawUnmount(self, idx)
						mounted[key] = nil
					else
						S.rawDetach(self, idx)
						S.getDetached(self)[key], mounted[key] = wasMounted, nil
					end
				end
			elseif result == nil then
				if prev ~= nil then
					local idx = if wasDetached ~= nil then nil else S.indexOfRaw(self, wasMounted)
					S.releaseElement(self, idx, prev, wasDetached ~= nil)
				end
				mounted[key] = nil
				if detached then detached[key] = nil end
			elseif result == S.unwrapElement(prev) then
				if wasDetached ~= nil then
					detached[key] = nil
					S.rawAdd(self, prev, slotPos, true)
					mounted[key] = prev
				else
					local idx = S.indexOfRaw(self, wasMounted) :: number
					if idx ~= slotPos then S.rawMove(self, idx, slotPos) end
				end
			else
				local element = S.wrapElement(result, S.Err.errorBefore) -- reconcile depth → outermost
				if wasDetached ~= nil then
					S.releaseElement(self, nil, prev, true)
					detached[key] = nil
					S.rawAdd(self, element, slotPos)
				elseif wasMounted ~= nil then
					local idx = S.indexOfRaw(self, wasMounted) :: number
					S.rawReplace(self, idx, element, self._owned ~= false)
					if idx ~= slotPos then S.rawMove(self, idx, slotPos) end
				else
					S.rawAdd(self, element, slotPos)
				end
				mounted[key] = element
			end
		end

		local function reconcile(items: any)
			if type(items) ~= "table" or getmetatable(items) ~= nil then
				-- round3 `H-441`/`H-446` (외부 리뷰 G-11): `#items` on nil/non-table was a VM error blaming Slot.luau —
				-- reached from State emit depth too, so outermost; branded tables are not arrays either
				S.Err.errorBefore(`Quad0142 Slot:List: data must be a plain array (got {typeof(items)}) - a data State must hold one too`, S.SURFACE)
			end
			-- round11 `H-571` (탐사 I′ 1, `H-396`의 짝): a dictionary (an id-keyed map, a decoded JSON
			-- object) passed the table check, `ipairs` saw nothing and the KeyGone pass silently
			-- destroyed every element. A nil hole still just stops `ipairs` (documented UB).
			-- [2026-10-01 user decision] every reconcile pays O(1) only: an array part of length 0 with
			-- some first key that is not an array position — exactly that symptom (the map / object
			-- case). The full key pass (an array WITH extra non-array keys) is debug-only.
			if #items == 0 then
				local k = next(items)
				if k ~= nil and notArrayKey(k) then
					S.Err.errorBefore(dataKeyMessage(k), S.SURFACE) -- error-code: via dataKeyMessage
				end
			end
			if module.debug then
				checkDataKeys(items)
			end
			local keys, seen = table.create(#items), {}
			for i, item in ipairs(items) do
				if item == S.KeyGone then
					-- round13 Q134 ③ (user decision 2026-09-30): a data item that IS the marker reached
					-- updateFn as `Item = KeyGone` with a nonzero Index and vanished in the idiom's first
					-- line (no `Quad0147` limit either). Outermost: same depth as the raises below.
					S.Err.errorBefore(`Quad0260 Slot:List: data item #{i} is q.KeyGone - it is the marker updateFn receives when a key disappears, not a data value`, S.SURFACE)
				end
				local key = keyFn(item, i)
				if key == nil or key ~= key then -- [2026-09-16 hunt A] NaN is the same raw "table index is NaN" trap
					-- fail-fast domain error instead of Luau's raw "table index is nil"
					-- at seen[key] (통합 리뷰 발견). errorBefore (outermost), not
					-- Nearest: reconcile runs at dispatch/emission depth (mount or
					-- data:Set), never as a direct user call — `H10-2` reasoning,
					-- same for the duplicate-key raise below
					S.Err.errorBefore(`Quad0144 Slot:List: keyFn returned {if key == nil then "nil" else "NaN"} for item #{i}`, S.SURFACE)
				end
				if seen[key] then
					S.Err.errorBefore(`Quad0145 Slot:List: duplicate key {tostring(key)}`, S.SURFACE)
				end
				seen[key] = true
				keys[i] = key
			end

			-- round13 Q113 (a) (user decision 2026-10-01): an identity :Single/:List (a State element's
			-- wrapper, or `slot:Single(st)` without an updateFn) mounts each item as-is — a State item
			-- whose chain loops (`st:Set(st)` on a State already in a Slot) would wrap itself forever.
			-- Checked BEFORE the batch gate goes On so the raise leaves this Slot showing its previous
			-- element (the State already holds the new value — that write happened before this ran).
			if module.debug and updateFn == identityUpdateFn then checkItemChains(items) end

			local blocker = S.BK._getBlocker(self)
			local ownsGate = not blocker.Blocking
			if ownsGate then blocker:On() end

			-- KeyGone pass FIRST (round13 Q76 A1 + A1b, user decision 2026-10-15): the keys of last cycle that are
			-- gone now are settled before the item loop, the mounted ones from the HIGHEST raw position down. With the
			-- old order (items first, gone keys after, in `pairs` order) a full replace inserted every new element in
			-- front of the N old ones still in the array (each `rawAdd` re-indexes / splices everything behind it) and
			-- then removed the old ones from the middle — O(N^2) (N=5000: ~2.1 s in the CLI mock). Gone first and
			-- descending, each removal is at the tail and every later `rawAdd` appends: O(N). The final state is the
			-- same (differential fuzz, `audit/round13-q76b-proto/`); the ORDER of updateFn calls in a cycle is not a
			-- contract (user: "updateFn 이 불리는 순서는 정함 없음으로 계약"). The gone keys are collected into a list
			-- before any user code runs, so `prevKeys` is not traversed while updateFn executes (`H-480`/`H-486`).
			local gone: { any } = {}
			for key in pairs(prevKeys) do
				if not seen[key] then
					table.insert(gone, key)
				end
			end
			if #gone > 1 then
				local position: { [any]: number } = {}
				for _, key in gone do
					local element = mounted[key]
					position[key] = if element ~= nil then (S.indexOfRaw(self, element) or 0) else 0 -- detached: last
				end
				table.sort(gone, function(a, b)
					return position[a] > position[b]
				end)
			end
			for _, key in gone do
				local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
				local result, ud = updateFn({ Item = S.KeyGone, Index = 0, Offset = offset, Prev = prev, UserData = userdata[key] })
				if result == S.None then result = nil end
				local detach = (result == S.Detach)
				if detach then result = nil end
				if result ~= nil then
					S.Err.errorBefore("Quad0147 Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)", S.SURFACE)
				end
				settle(key, result, detach, 0)
				userdata[key] = ud
			end

			local slotPos = 0
			for i, item in ipairs(items) do
				local key = keys[i]
				local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
				local candidateSlot = slotPos + 1
				local physIndex = S.BK.getOffsetAt(self, candidateSlot) - offset:Get() + 1
				-- 2026-09-15 (user decision): a FRESH context table per call — a reused one would let a closure
				-- made inside updateFn read a later item's fields (cost: audit/updatefn-ctx-table-bench-2026-09-15)
				local result, ud = updateFn({ Item = item, Index = physIndex, Offset = offset, Prev = prev, UserData = userdata[key] })
				if result == S.KeyGone then
					-- round11 탐사 I′ 5: the third sentinel is an INPUT marker, never a return — it used to die as "cannot mount this value"
					S.Err.errorBefore("Quad0146 Slot:List: updateFn returned q.KeyGone - it is the marker updateFn RECEIVES when a key disappears; return nil/q.None to drop the element or q.Detach to hold it", S.SURFACE)
				end
				if result == S.None then result = nil end
				local detach = (result == S.Detach)
				if detach then result = nil end
				if result ~= nil then slotPos = candidateSlot end
				settle(key, result, detach, slotPos)
				userdata[key] = ud
			end

			-- [2026-10-02 user decision, round14] `H-38` reverted to the cycle-end swap (`H-480`): this
			-- cycle's key set becomes the next cycle's "last" set in one write. The old incremental
			-- writes (record before settle, clear after KeyGone) only mattered after an `updateFn` /
			-- settle raise — a state quad does not define (user: "updateFn 자체가 던진 이후 상태를
			-- 우린 정의한 적 없어"); after such a raise this swap does not run, so the keys that cycle
			-- added are not asked about again (observed — not a contract).
			prevKeys = seen

			if ownsGate then
				blocker:OffWithoutEmit()
				S.maybeRecompute(self, S.BK.getBookkeeping(self))
			end
		end

		self._detachCleanup = module.Effect(function()
			return function()
				if not self._detached then return end
				for key, element in pairs(self._detached) do
					S.releaseOwner(element, self)
					S.destroyElement(element)
					self._detached[key] = nil
				end
			end
		end)
		module.Backend.bindLifetime(physicalTarget, self._detachCleanup)

		local data = self._listData
		if S.isState(data) then
			-- quad's own bookkeeping: `_internal` from birth (before the install run), skipped by the Observer
			-- upstream-feedback debug check
			local observer = data:_internalObserver(function()
				reconcile(data:Get())
				if S.pending ~= nil then S.settle() end -- `slot:WhenIdle` requests made inside this reconcile's backend calls
			end)
			self._listObserver = observer
			module.Backend.bindLifetime(physicalTarget, observer)
		else
			reconcile(data)
		end
	end

	-- 4순회 `H-385`: the install gates run at the PUBLIC entry — `Single` is tagged
	-- and delegates to `List`, so a gate raised inside `List` was nearest to
	-- `Single`'s own delegation line (`Slot/List.luau`), not the user's `:Single(...)`.
	-- round13 Q134 ④ (user decision 2026-09-30 — cheap entry gate): only `== false` meant "not owned",
	-- so "false"/0 silently OWNED; the option is a boolean. A helper so `:Single` gates at its own entry
	-- too (code-review 2026-09-30 — `H-385`: blame the user's call and name the surface they called).
	local function checkOwnsElements(opts: any, surface: string)
		if opts ~= nil and opts.OwnsElements ~= nil and type(opts.OwnsElements) ~= "boolean" then
			S.Err.errorBeforeNearest(`Quad0259 {surface}: opts.OwnsElements must be a boolean (got {typeof(opts.OwnsElements)})`, S.SURFACE)
		end
	end

	local function checkListInstall(self: any)
		S.assertLive(self)
		S.assertNotMounting(self) -- round10 Q52 (a)
		if self._listed then S.Err.errorBeforeNearest("Quad0148 Slot: already has :List/:Single/:Defer installed", S.SURFACE) end
		if self._crudUsed then S.Err.errorBeforeNearest("Quad0149 Slot: cannot install :List/:Single/:Defer on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)", S.SURFACE) end
	end

	function S.Slot_mt.List(self: any, data: any, updateFn: any, keyFn: any?, opts: any?): any
		checkListInstall(self)
		if type(updateFn) ~= "function" then
			S.Err.errorBeforeNearest(`Quad0150 Slot:List: updateFn must be a function (got {typeof(updateFn)})`, S.SURFACE) -- round3 `H-441`
		end
		if not ((type(data) == "table" and getmetatable(data) == nil) or S.isState(data)) then
			-- round3 `H-441`/`H-446`: a plain array or a State of one — branded tables (None/Store/Tween/Modifier)
			-- have metatables and used to pass as an empty list
			S.Err.errorBeforeNearest(`Quad0151 Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, S.SURFACE)
		end
		if S.isState(data) then
			ModuleIdentity.assertOwnAtCall(module, data, "Slot:List") -- [2026-09-15] a data State from another instance
		end
		if keyFn ~= nil and type(keyFn) ~= "function" then
			S.Err.errorBeforeNearest(`Quad0152 Slot:List: keyFn must be a function (got {typeof(keyFn)})`, S.SURFACE) -- round3 `H-446`
		end
		-- [2026-09-16 hunt F] the option bag was the one unchecked argument — gated BEFORE `_listed` (a rejected call must not half-install, code-review) (`H-441`/`H-446` closed the
		-- others): a number died on `opts.OwnsElements` with this file on the blame line, a string
		-- indexed to nil and silently dropped the option.
		if opts ~= nil and type(opts) ~= "table" then
			S.Err.errorBeforeNearest(`Quad0153 Slot:List: opts must be a table (got {typeof(opts)})`, S.SURFACE)
		end
		checkOwnsElements(opts, "Slot:List") -- round13 Q134 ④
		self._listed = true
		self._listData = data
		self._updateFn = updateFn
		self._keyFn = keyFn or function(_item: any, index: number) return index end
		if opts and opts.OwnsElements == false then self._owned = false end
		if module.debug and type(opts) == "table" then
			-- [2026-09-15 사용자 결정] unknown option keys (typos, the pre-rename `Owned`) are reported
			-- only under `q.debug`; execution continues
			for key in opts do
				if key ~= "OwnsElements" then
					print(`Slot:List/:Single: unknown option "{tostring(key)}" is ignored (known: OwnsElements)`)
				end
			end
		end
		-- if already materialized, activate now (mount is a one-shot event)
		if self._physicalTarget then
			self:_activateList(self._physicalTarget)
			S.maybeRecompute(self, S.BK.getBookkeeping(self))
			if S.pending ~= nil then S.settle() end -- `slot:WhenIdle`: an install on a mounted Slot is an operation entry
		end
		return self
	end

	function S.Slot_mt.Single(self: any, state: any, updateFn: any?, opts: any?): any
		checkListInstall(self) -- `H-385`: gate here so the blame is this call, not the delegation below
		if updateFn ~= nil and type(updateFn) ~= "function" then
			S.Err.errorBeforeNearest(`Quad0154 Slot:Single: updateFn must be a function (got {typeof(updateFn)})`, S.SURFACE) -- round3 `H-446`: the List gate saw only the wrapper
		end
		if opts ~= nil and type(opts) ~= "table" then -- [2026-09-16 hunt F] same gate at this entry so the blame is this call
			S.Err.errorBeforeNearest(`Quad0155 Slot:Single: opts must be a table (got {typeof(opts)})`, S.SURFACE)
		end
		checkOwnsElements(opts, "Slot:Single") -- round13 Q134 ④ at this entry too (code-review 2026-09-30)
		if S.isState(state) then
			-- [2026-09-15 code-review] cross-instance gate at the PUBLIC entry (`H-385` reasoning): inside `List`
			-- it would name "Slot:List" and blame this file's delegation line, not the user's `:Single(...)`
			ModuleIdentity.assertOwnAtCall(module, state, "Slot:Single")
		end
		local uf = updateFn or identityUpdateFn
		-- `H-467` (Gemini 5차 G-16, 사용자 Q30 "의미론적으로 None == nil"): None is the
		-- absent element too — `{ None }` used to reach updateFn as an item and never KeyGone
		local None = S.None
		local data = if S.isState(state)
			then state:Compute(function(v: any) local g = v:Get(); return (if g == nil or g == None then {} else { g }) end)
			else (if state == nil or state == None then {} else { state })
		-- same context shape as :List (Index included — one updateFn works for both)
		return self:List(data, uf, function() return true end, opts)
	end

	-- `slot:Defer(fn)` [2026-10-15 user decision]: install a one-shot builder — `fn()` runs when this Slot is first
	-- mounted (inside its mount walk, after whatever filled a Context / PreRef above it), never at install
	-- unless the Slot is already mounted. Same install rules and CRUD lock as :List/:Single (`_listed`).
	function S.Slot_mt.Defer(self: any, fn: any): any
		checkListInstall(self)
		if type(fn) ~= "function" then
			S.Err.errorBeforeNearest(`Quad0271 Slot:Defer: fn must be a function (got {typeof(fn)})`, S.SURFACE)
		end
		self._listed = true
		self._deferred = true
		self._deferFn = fn
		if self._physicalTarget then -- already mounted: build now (mount is a one-shot event, as :List)
			self:_activateList(self._physicalTarget)
			S.maybeRecompute(self, S.BK.getBookkeeping(self))
			if S.pending ~= nil then S.settle() end -- `slot:WhenIdle`: an install on a mounted Slot is an operation entry
		end
		return self
	end

	S.List = S.Slot_mt.List -- for init's setFuncLevel tagging call
	S.Single = S.Slot_mt.Single
	S.Defer = S.Slot_mt.Defer
end
