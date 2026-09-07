--!strict
--[[
	Slot/List.luau — the :List/:Single install path: identityUpdateFn,
	`Slot_mt._activateList` (the reconcile closure — settle/reconcile/detachCleanup),
	the checkListInstall gate, and the public `Slot_mt.List` / `Slot_mt.Single`.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol); the two public methods land on the shared `Slot_mt` and
	are tagged by init's setFuncLevel loop. Behaviour and comments are the moved
	originals.
]]

return function(S: any, module: any)
	local Slot_mt = S.Slot_mt
	local BK = S.BK
	local None = S.None
	local Detach = S.Detach
	local KeyGone = S.KeyGone
	local isState = S.isState
	local bindLifetime = S.bindLifetime
	local Err = S.Err
	local SURFACE = S.SURFACE

	-- ── :List / :Single (slice 4) ──────────────────────────────────────
	local function identityUpdateFn(item: any): any
		if item == KeyGone then return nil end
		return item
	end

	-- _activateList — called by materializeSlotTree at mount. Fresh path builds
	-- the reconcile closure (mounted/userdata/prevKeys upvalues) + subscribes;
	-- remount path re-anchors only (idempotent guard).
	function Slot_mt._activateList(self: any, physicalTarget: any)
		if self._listActivated then
			-- remount: keep closure state, move the detachCleanup anchor only.
			-- (_listObserver re-bind is materializeSlotTree's tail — H-163.)
			bindLifetime(physicalTarget, self._detachCleanup)
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
				local element = S.wrapElement(result, Err.errorBefore) -- reconcile depth → outermost
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
				Err.errorBefore(`Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too`, SURFACE)
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
					Err.errorBefore("Slot:List — keyFn returned nil for item #" .. tostring(i), SURFACE)
				end
				if seen[key] then
					Err.errorBefore("Slot:List — duplicate key: " .. tostring(key), SURFACE)
				end
				seen[key] = true
				keys[i] = key
			end

			local blocker = BK.getBlocker(self)
			local ownsGate = not blocker:IsOn()
			if ownsGate then blocker:On() end

			local slotPos = 0
			for i, item in ipairs(items) do
				local key = keys[i]
				local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
				local candidateSlot = slotPos + 1
				local physIndex = BK.getOffsetAt(self, candidateSlot) - offset:Get() + 1
				local result, ud = updateFn(item, physIndex, offset, prev, userdata[key])
				if result == None then result = nil end
				local detach = (result == Detach)
				if detach then result = nil end
				if result ~= nil then slotPos = candidateSlot end
				prevKeys[key] = true
				settle(key, result, detach, slotPos)
				userdata[key] = ud
			end

			for key in pairs(table.clone(prevKeys)) do
				if not seen[key] then
					local prev = S.unwrapElement(mounted[key] or (self._detached and self._detached[key]))
					local result, ud = updateFn(KeyGone, 0, offset, prev, userdata[key])
					if result == None then result = nil end
					local detach = (result == Detach)
					if detach then result = nil end
					if result ~= nil then
						Err.errorBefore("Slot:List — KeyGone accepts only nil/None (destroy) or Detach (hold)", SURFACE)
					end
					settle(key, result, detach, 0)
					userdata[key] = ud
					prevKeys[key] = nil
				end
			end

			if ownsGate then
				blocker:OffWithoutEmit()
				S.maybeRecompute(self, BK.getBookkeeping(self))
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
		bindLifetime(physicalTarget, self._detachCleanup)

		local data = self._listData
		if isState(data) then
			local observer = data:Observer(function() reconcile(data:Get()) end)
			self._listObserver = observer
			bindLifetime(physicalTarget, observer)
		else
			reconcile(data)
		end
	end

	-- 4순회 `H-385`: the install gates run at the PUBLIC entry — `Single` is tagged
	-- and delegates to `List`, so a gate raised inside `List` was nearest to
	-- `Single`'s own delegation line (`Slot.luau`), not the user's `:Single(...)`.
	local function checkListInstall(self: any)
		S.assertLive(self)
		if self._listed then Err.errorBeforeNearest("Slot: already has :List/:Single installed", SURFACE) end
		if self._crudUsed then Err.errorBeforeNearest("Slot: cannot install :List/:Single on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)", SURFACE) end
	end

	function Slot_mt.List(self: any, data: any, updateFn: any, keyFn: any?, opts: any?): any
		checkListInstall(self)
		if type(updateFn) ~= "function" then
			Err.errorBeforeNearest(`Slot:List: updateFn must be a function (got {typeof(updateFn)})`, SURFACE) -- round3 `H-441`
		end
		if not ((type(data) == "table" and getmetatable(data) == nil) or isState(data)) then
			-- round3 `H-441`/`H-446`: a plain array or a State of one — branded tables (None/Store/Tween/Modifier)
			-- have metatables and used to pass as an empty list
			Err.errorBeforeNearest(`Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, SURFACE)
		end
		if keyFn ~= nil and type(keyFn) ~= "function" then
			Err.errorBeforeNearest(`Slot:List: keyFn must be a function (got {typeof(keyFn)})`, SURFACE) -- round3 `H-446`
		end
		self._listed = true
		self._listData = data
		self._updateFn = updateFn
		self._keyFn = keyFn or function(_item: any, index: number) return index end
		if opts and opts.Owned == false then self._owned = false end
		-- if already materialized, activate now (mount is a one-shot event)
		if self._physicalTarget then
			self:_activateList(self._physicalTarget)
			S.maybeRecompute(self, BK.getBookkeeping(self))
		end
		return self
	end

	function Slot_mt.Single(self: any, state: any, updateFn: any?, opts: any?): any
		checkListInstall(self) -- `H-385`: gate here so the blame is this call, not the delegation below
		if updateFn ~= nil and type(updateFn) ~= "function" then
			Err.errorBeforeNearest(`Slot:Single: updateFn must be a function (got {typeof(updateFn)})`, SURFACE) -- round3 `H-446`: the List gate saw only the wrapper
		end
		local uf = updateFn or identityUpdateFn
		local data = if isState(state)
			then state:Compute(function(v: any) local g = v:Get(); return (if g == nil then {} else { g }) end)
			else (if state == nil then {} else { state })
		return self:List(data, function(item: any, _index: number, off: any, prev: any, ud: any)
			return (uf :: any)(item, off, prev, ud)
		end, function() return true end, opts)
	end

	S.identityUpdateFn = identityUpdateFn
	S.checkListInstall = checkListInstall
	S.List = Slot_mt.List -- for init's setFuncLevel tagging loop
	S.Single = Slot_mt.Single
end
