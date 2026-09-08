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

return function(S: Types.SlotInternal, module: any)

	-- ── :List / :Single (slice 4) ──────────────────────────────────────
	local function identityUpdateFn(item: any): any
		if item == S.KeyGone then return nil end
		return item
	end

	-- _activateList — called by materializeSlotTree at mount. Fresh path builds
	-- the reconcile closure (mounted/userdata/prevKeys upvalues) + subscribes;
	-- remount path re-anchors only (idempotent guard).
	function S.Slot_mt._activateList(self: any, physicalTarget: any)
		if self._listActivated then
			-- remount: keep closure state, move the detachCleanup anchor only.
			-- (_listObserver re-bind is materializeSlotTree's tail — H-163.)
			module.bindLifetime(physicalTarget, self._detachCleanup)
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
				S.Err.errorBefore(`Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too`, S.SURFACE)
			end
			local keys, seen = table.create(#items), {}
			for i, item in ipairs(items) do
				local key = keyFn(item, i)
				if key == nil then
					-- fail-fast domain error instead of Luau's raw "table index is nil"
					-- at seen[key] (통합 리뷰 발견). errorBefore (outermost), not
					-- Nearest: reconcile runs at dispatch/emission depth (mount or
					-- data:Set), never as a direct user call — `H10-2` reasoning,
					-- same for the duplicate-key raise below
					S.Err.errorBefore(`Slot:List: keyFn returned nil for item #{i}`, S.SURFACE)
				end
				if seen[key] then
					S.Err.errorBefore(`Slot:List: duplicate key {tostring(key)}`, S.SURFACE)
				end
				seen[key] = true
				keys[i] = key
			end

			local blocker = S.BK.getBlocker(self)
			local ownsGate = not blocker:IsOn()
			if ownsGate then blocker:On() end

			local slotPos = 0
			for i, item in ipairs(items) do
				local key = keys[i]
				local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
				local candidateSlot = slotPos + 1
				local physIndex = S.BK.getOffsetAt(self, candidateSlot) - offset:Get() + 1
				local result, ud = updateFn(item, physIndex, offset, prev, userdata[key])
				if result == S.None then result = nil end
				local detach = (result == S.Detach)
				if detach then result = nil end
				if result ~= nil then slotPos = candidateSlot end
				settle(key, result, detach, slotPos)
				userdata[key] = ud
			end

			-- KeyGone pass over LAST cycle's key set, read-only — `seen` already holds
			-- every key of this cycle (the pre-pass fills it before any settle, the
			-- `H-38` reason), so `prevKeys` is neither written in the loop above nor
			-- cleared here: it is simply replaced by `seen` at the tail (2026-09-08
			-- advisory RFC, `H-480` — the old per-cycle `table.clone` snapshot existed
			-- only to survive those two writes).
			for key in pairs(prevKeys) do
				if not seen[key] then
					local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
					local result, ud = updateFn(S.KeyGone, 0, offset, prev, userdata[key])
					if result == S.None then result = nil end
					local detach = (result == S.Detach)
					if detach then result = nil end
					if result ~= nil then
						S.Err.errorBefore("Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)", S.SURFACE)
					end
					settle(key, result, detach, 0)
					userdata[key] = ud
				end
			end
			prevKeys = seen -- this cycle's key set becomes the next cycle's "previous"

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
		module.bindLifetime(physicalTarget, self._detachCleanup)

		local data = self._listData
		if S.isState(data) then
			local observer = data:Observer(function() reconcile(data:Get()) end)
			self._listObserver = observer
			module.bindLifetime(physicalTarget, observer)
		else
			reconcile(data)
		end
	end

	-- 4순회 `H-385`: the install gates run at the PUBLIC entry — `Single` is tagged
	-- and delegates to `List`, so a gate raised inside `List` was nearest to
	-- `Single`'s own delegation line (`Slot/List.luau`), not the user's `:Single(...)`.
	local function checkListInstall(self: any)
		S.assertLive(self)
		if self._listed then S.Err.errorBeforeNearest("Slot: already has :List/:Single installed", S.SURFACE) end
		if self._crudUsed then S.Err.errorBeforeNearest("Slot: cannot install :List/:Single on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)", S.SURFACE) end
	end

	function S.Slot_mt.List(self: any, data: any, updateFn: any, keyFn: any?, opts: any?): any
		checkListInstall(self)
		if type(updateFn) ~= "function" then
			S.Err.errorBeforeNearest(`Slot:List: updateFn must be a function (got {typeof(updateFn)})`, S.SURFACE) -- round3 `H-441`
		end
		if not ((type(data) == "table" and getmetatable(data) == nil) or S.isState(data)) then
			-- round3 `H-441`/`H-446`: a plain array or a State of one — branded tables (None/Store/Tween/Modifier)
			-- have metatables and used to pass as an empty list
			S.Err.errorBeforeNearest(`Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, S.SURFACE)
		end
		if keyFn ~= nil and type(keyFn) ~= "function" then
			S.Err.errorBeforeNearest(`Slot:List: keyFn must be a function (got {typeof(keyFn)})`, S.SURFACE) -- round3 `H-446`
		end
		self._listed = true
		self._listData = data
		self._updateFn = updateFn
		self._keyFn = keyFn or function(_item: any, index: number) return index end
		if opts and opts.Owned == false then self._owned = false end
		-- if already materialized, activate now (mount is a one-shot event)
		if self._physicalTarget then
			self:_activateList(self._physicalTarget)
			S.maybeRecompute(self, S.BK.getBookkeeping(self))
		end
		return self
	end

	function S.Slot_mt.Single(self: any, state: any, updateFn: any?, opts: any?): any
		checkListInstall(self) -- `H-385`: gate here so the blame is this call, not the delegation below
		if updateFn ~= nil and type(updateFn) ~= "function" then
			S.Err.errorBeforeNearest(`Slot:Single: updateFn must be a function (got {typeof(updateFn)})`, S.SURFACE) -- round3 `H-446`: the List gate saw only the wrapper
		end
		local uf = updateFn or identityUpdateFn
		-- `H-467` (Gemini 5차 G-16, 사용자 Q30 "의미론적으로 None == nil"): None is the
		-- absent element too — `{ None }` used to reach updateFn as an item and never KeyGone
		local None = S.None
		local data = if S.isState(state)
			then state:Compute(function(v: any) local g = v:Get(); return (if g == nil or g == None then {} else { g }) end)
			else (if state == nil or state == None then {} else { state })
		return self:List(data, function(item: any, _index: number, off: any, prev: any, ud: any)
			return (uf :: any)(item, off, prev, ud)
		end, function() return true end, opts)
	end

	S.List = S.Slot_mt.List -- for init's setFuncLevel tagging call
	S.Single = S.Slot_mt.Single
end
