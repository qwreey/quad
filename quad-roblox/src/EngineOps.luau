--[[
	quad-roblox EngineOps — the injected engine ops this backend implements
	in M5. The op *inventory* source is the `architecture.md` EngineOps line;
	this file carries the M5 share only (round14 Q4 (a)):

	  native* physical-tree layer (signatures: `base/slot-plan.md` "native*"):
	    nativeInsert (target, offset, elements)
	    nativeExtract(target, offset, elements, newElements?)  -- keep alive
	    nativeRemove (target, offset, elements, newElements?)  -- destroy
	    nativeMove   (target, fromOffset, elements, toOffset)
	    nativeSwap   (target, offsetA, elementsA, offsetB, elementsB)
	    nativeDispose(element)
	  judgement/hook ops (no composition fallback — absent means error):
	    isInst(value) / onDestroying(inst, fn) / nativeFindChild(inst, key)
	  (`nativeClaim` also belongs to this inventory but is implemented in
	   LifetimeHandle.luau — it shares InstData with isBoundAlive.)

	  [M10 engine axis, 2026-09-03] base-owned handlers' injected ops
	  (`dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op"):
	    addTag(inst, {string}) / removeTag(inst, {string})  -- CollectionService
	    setAttr(inst, name, v)                           -- v == nil deletes
	  `game` is read at CALL time (not install time) so CLI specs can shim it
	  through this installer's environment (the Property-handler idiom).

	  [2026-09-08] the two time ops (`debounce-throttle-plan.md` 6절):
	    setTimeout(func, delay) -> Timeout   -- task.delay(delay, func) — ARGUMENT ORDER FLIPS
	    clearTimeout(timeout)                -- task.cancel(timeout._native)
	  `task` is read at CALL time (same seam as `game`) so CLI specs can shim it.

	Roblox ignores `offset` — child order is not a physical property here, so
	positional args exist only to satisfy the injected-op contract shared with
	offset-using backends (DOM). That is also why `nativeMove`/`nativeSwap`
	are deliberate no-op OVERRIDES rather than left to the composition
	fallback: the fallback would detach+reattach (two `.Parent` writes →
	AncestryChanged refires, flicker) to achieve a reorder that changes
	nothing physical on Roblox (`ROADMAP.md` M5 banner, `H-34`/`H-44`).
]]

local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function install(quad: any)
	local Err = quad.errorNamespace

	local function nativeInsert(target: any, _offset: number, elements: { any })
		for _, element in elements do
			element.Parent = target
		end
	end

	local function nativeExtract(target: any, _offset: number, elements: { any }, newElements: { any }?)
		for _, element in elements do
			element.Parent = nil -- keep alive, out of the tree
		end
		if newElements ~= nil then
			for _, element in newElements do
				element.Parent = target
			end
		end
	end

	local function nativeRemove(target: any, _offset: number, elements: { any }, newElements: { any }?)
		for _, element in elements do
			element:Destroy()
		end
		if newElements ~= nil then
			for _, element in newElements do
				element.Parent = target
			end
		end
	end

	local function nativeMove(_target: any, _fromOffset: number, _elements: { any }, _toOffset: number)
		-- no-op on purpose (see header) — order is bookkeeping, not physical, on Roblox
	end

	local function nativeSwap(_target: any, _offsetA: number, _elementsA: { any }, _offsetB: number, _elementsB: { any })
		-- no-op on purpose (see header)
	end

	local function nativeDispose(element: any)
		element:Destroy()
	end

	local function isInst(value: any): boolean
		-- `H-292` (b, 사용자 확정): the cast defeats typeof-narrowing's lookup
		-- of the (CLI-unknown) `Instance` type so analyze output stays clean —
		-- identical behavior at runtime
		return (typeof(value) :: string) == "Instance"
	end

	local function onDestroying(inst: any, fn: () -> ()): any
		return inst.Destroying:Connect(fn)
	end

	local function nativeFindChild(inst: any, key: any): any?
		return inst:FindFirstChild(key)
	end

	-- Tag/Attr ops (M10 engine axis). Batched `{string}` is the contract
	-- (a web backend rewrites className once); Roblox has no batch API, so
	-- the loop is here rather than in the base handler.
	-- `H-465`: fetched lazily at first use and memoized — the same seam as
	-- `Property.luau`'s `getTweenService` (call-time read keeps the getfenv shim
	-- usable; one GetService per module instance, not per tag diff batch)
	local collectionService: any = nil
	local function getCollectionService(): any
		if collectionService == nil then
			collectionService = game:GetService("CollectionService")
		end
		return collectionService
	end

	local function addTag(inst: any, names: { string })
		local cs = getCollectionService()
		for _, name in names do
			cs:AddTag(inst, name)
		end
	end

	local function removeTag(inst: any, names: { string })
		local cs = getCollectionService()
		for _, name in names do
			cs:RemoveTag(inst, name)
		end
	end

	local function setAttr(inst: any, name: string, v: any)
		inst:SetAttribute(name, v) -- nil deletes natively
	end

	-- Time ops. `Timeout` = `{ __quadTimeout = true, _native = <thread> }` — the
	-- marker makes the handle nominal for `clearTimeout` (plan 6절); base never
	-- reads `_native`. Gates here: these are the backend's public surface too.
	local function setTimeout(func: () -> (), delay: number): QuadTypes.Timeout
		if type(func) ~= "function" then
			Err.errorBefore(`setTimeout: func must be a function (got {typeof(func)})`, SURFACE)
		end
		if type(delay) ~= "number" or delay ~= delay or delay < 0 then
			Err.errorBefore(`setTimeout: delay must be a non-negative number (got {typeof(delay)})`, SURFACE)
		end
		return { __quadTimeout = true :: true, _native = task.delay(delay, func) } -- ⚠️ order flipped vs the op
	end

	local function clearTimeout(timeout: any)
		if type(timeout) ~= "table" or timeout.__quadTimeout ~= true then
			Err.errorBefore(`clearTimeout: expected a Timeout from setTimeout (got {typeof(timeout)})`, SURFACE)
		end
		-- Studio 2026-09-08 실측: `task.cancel` on an already-fired (dead) thread is a
		-- silent no-op — a late cancel by a user holding the handle needs no guard.
		task.cancel(timeout._native)
	end

	quad.nativeInsert = nativeInsert
	quad.nativeExtract = nativeExtract
	quad.nativeRemove = nativeRemove
	quad.nativeMove = nativeMove
	quad.nativeSwap = nativeSwap
	quad.nativeDispose = nativeDispose
	quad.isInst = isInst
	quad.onDestroying = onDestroying
	quad.nativeFindChild = nativeFindChild
	quad.addTag = addTag
	quad.removeTag = removeTag
	quad.setAttr = setAttr
	quad.setTimeout = setTimeout
	quad.clearTimeout = clearTimeout

	-- `H-238`: tag everything the backend installs (see LifetimeHandle.luau)
	Err.setFuncLevel(SURFACE, nativeInsert, nativeExtract, nativeRemove, nativeMove, nativeSwap, nativeDispose, isInst, onDestroying, nativeFindChild, addTag, removeTag, setAttr, setTimeout, clearTimeout)
end

return install
