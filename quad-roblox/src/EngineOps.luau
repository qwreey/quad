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

	NOT here (stubs/absent stay, owned by later milestones): addTag/removeTag/
	setAttribute (M10), setTimeout/clearTimeout (Debounce/Throttle backlog).

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

	quad.nativeInsert = nativeInsert
	quad.nativeExtract = nativeExtract
	quad.nativeRemove = nativeRemove
	quad.nativeMove = nativeMove
	quad.nativeSwap = nativeSwap
	quad.nativeDispose = nativeDispose
	quad.isInst = isInst
	quad.onDestroying = onDestroying
	quad.nativeFindChild = nativeFindChild

	-- `H-238`: tag everything the backend installs (see LifetimeHandle.luau)
	for _, fn in
		{ nativeInsert, nativeExtract, nativeRemove, nativeMove, nativeSwap, nativeDispose, isInst, onDestroying, nativeFindChild } :: { any }
	do
		Err.setFuncLevel(fn, SURFACE)
	end
end

return install
