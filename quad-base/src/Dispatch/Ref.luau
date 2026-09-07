--[[
	PreRef/PostRef pre-pass + `Processed*Ref` sentinels/handlers (M8 단위 ②).
	Canon: `.claude/base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현, `PreRef`
	신설" 절 (pre-pass, hoisting, `ProcessedPreRef`), "`PostRef`" 절 (one sweep
	collects both, `postRefList` drained after the body loop) — as-is.

	Lives under Dispatch/ for the same reason as Dispatch/Modifier.luau: the
	pre-pass is `drive`'s own stage (a)/(c) and the sentinels are Dispatch's
	concept (a consumed slot), so Dispatch can require this file without a
	cycle (`Ref.luau` requires Dispatch for its `H-278` handler registration).
	The leaf handler and the two dynamic-path guards stay in `Ref.luau`.

	  prePass(inst, flattened) -> postRefList?
	      one index-order walk of the array part:
	        isPreRef(v)  → one-shot guard, `v:Set(inst)` NOW, slot := ProcessedPreRef
	        isPostRef(v) → one-shot guard, push, slot := ProcessedPostRef
	      (`flatten` has already run — Modifier fields are hash keys by now,
	       so a PreRef hidden in a Modifier field never reaches here: the
	       FALLBACK guard in Ref.luau catches it as a named-key misuse)
	  firePostRefs(inst, list)
	      `v:Set(inst)` in push (= array index) order — called by `drive` after
	      the body loop and BEFORE the batch closes (`H-17`: the gate is still
	      on, one recompute catches up whatever a callback mutates). Every
	      child is placed physically by then; parent attachment is not part of
	      the contract either way (brief Q6).
	  register(dispatch) — ProcessedPreRefHandler / ProcessedPostRefHandler:
	      HIGH, `v == sentinel`, offsetSource None → length 0 → Void (the
	      `ProcessedModifierHandler` shape, one letter apart by canon).

	One-shot: a fired PreRef/PostRef placed again is an error at the pre-pass
	(stale `.Value` would silently re-fire callbacks). `errorBefore`: the
	pre-pass runs inside the tagged `drive`, so the outermost surface's caller
	(the user's `D.Frame{}` line) is blamed (`H-272` reasoning, same as the
	flatten `H-312` rejection).
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local NoneModule = require("./None")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local isPreRef = Brand.isPreRef
local isPostRef = Brand.isPostRef

local ProcessedPreRef = NoneModule.sentinel("ProcessedPreRef")
local ProcessedPostRef = NoneModule.sentinel("ProcessedPostRef")

local function fireOnce(v: any, kind: string)
	if v._fired then
		Err.errorBefore(`{kind}: already fired — a {kind} is one-shot, make a new one for each instance`, SURFACE)
	end
	v._fired = true
end

local function prePass(inst: any, flattened: { [any]: any }): { any }?
	local postRefList: { any }? = nil
	for i = 1, #flattened do
		-- consumed IN PLACE (`ProcessedPreRef`/`PostRef` replace the slot) — the same
		-- contract as Modifier `flatten`: a props table belongs to one drive; driving
		-- the same table again sees sentinels, not the one-shot values (1차 리뷰, `H-339`)
		local v = flattened[i]
		if isPreRef(v) then
			fireOnce(v, "PreRef")
			v:Set(inst) -- fire, then consume (canon order — bind-system pipeline (a))
			flattened[i] = ProcessedPreRef
		elseif isPostRef(v) then
			fireOnce(v, "PostRef")
			if postRefList == nil then
				postRefList = {}
			end
			table.insert(postRefList :: { any }, v) -- push, then consume (canon order)
			flattened[i] = ProcessedPostRef
		end
	end
	return postRefList
end

local function firePostRefs(inst: any, list: { any })
	for _, v in list do
		v:Set(inst)
	end
end

local module = {
	ProcessedPreRef = ProcessedPreRef,
	ProcessedPostRef = ProcessedPostRef,
	prePass = prePass,
	firePostRefs = firePostRefs,
}

function module.register(dispatch: QuadTypes.Dispatch)
	-- canon `ProcessedPreRefHandler` block — the shared nop-terminal factory (Q3 ⑤)
	NoneModule.addProcessedHandler(dispatch, "ProcessedPreRefHandler", ProcessedPreRef)
	NoneModule.addProcessedHandler(dispatch, "ProcessedPostRefHandler", ProcessedPostRef)
end

return module
