--!strict
--[[
	InstanceShorthandHandler — the UI convenience keys `UICorner` /
	`UIPadding` / `UIPaddingOffset` / `UIScale` (M10 remainder, round20).
	Canon: `.claude/base/ui-shorthand-plan.md` — "메커니즘" (special-key handler
	that finds-or-makes a MANAGED child and delegates the child's property
	writes to `Dispatch.process(child, prop, v, 1)`), "Tween 지원" (pseudocode
	as-is: `v == nil` destroys the managed child after `retractFrom` — `H-218`;
	the retractor is `Void` — `H-135`; Tween values are mapped with
	`:Mapped(wrap)` so the Tween wrapper survives and PropertyHandler stays
	the only Tween interpreter), "결론" (`UI` prefix — keys never collide with
	real properties, `H-138`).

	One lookup table drives all four keys (the canon's "단순화 후보", round20
	Q2 (a)): `{ class, childName, props, wrap }`. `UIPadding` and
	`UIPaddingOffset` SHARE the managed `_quad_padding` child (v1 did too —
	`class.lua` PaddingAll/PaddingAllOffset): both delegate to the same four
	`(child, PaddingX)` chains at index 1, so the last written key wins per
	property, and `nil` on either key destroys the shared child (`H-335`).

	Priority: `HANDLER_PRIORITY_NORMAL + 1` (Q4 (a)) — above PropertyHandler
	by priority, not by Reflection rejection (`H-138`: the lower layer must
	not know the shorthand key set); below the HIGH band so `key = None`
	still reaches this handler as nil through NoneHandler's recursion.

	Managed child: created through the module's own instance path
	(`quad.D.New(class)({ Name = childName })` — `Instance.new` → `nativeClaim`
	→ drive, so gcconn/gchold are set up exactly like any quad instance,
	`UI-5`), parented by this handler (physical attach — the same place
	InstanceChildHandler does it), and remembered in a `Relate` keyed by
	childName (lookup by reference, never `FindFirstChild` — user requirement).
	The name is display/judgement only ("quad's own child"); a user-made
	`UICorner` is never touched. A managed child the user destroyed or
	re-parented is out of contract (Q5 (a)) — the delegated write then raises
	the engine's own error (`H-103` NOOP-marker caveat).

	Hash keys ⇒ no Length/Offset bookkeeping (`H-39` is array-only).
	No validation raises of its own since Q17 (2026-09-07) — see the process body.
]]

local QuadTypes = require("../../luau_packages/quad_types")

local PADDING_PROPS = { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" }

local function identity(v: any): any
	return v
end

local function offsetUDim(v: any): any
	return UDim.new(0, v)
end

-- number → offset UDim; a UDim (or anything else — engine validates) passes through
local function numberOrUDim(v: any): any
	if type(v) == "number" then
		return UDim.new(0, v)
	end
	return v
end

local TABLE: { [string]: { class: string, childName: string, props: { string }, wrap: (any) -> any } } = {
	UICorner = { class = "UICorner", childName = "_quad_round", props = { "CornerRadius" }, wrap = numberOrUDim },
	UIPadding = { class = "UIPadding", childName = "_quad_padding", props = PADDING_PROPS, wrap = identity },
	UIPaddingOffset = { class = "UIPadding", childName = "_quad_padding", props = PADDING_PROPS, wrap = offsetUDim },
	UIScale = { class = "UIScale", childName = "_quad_scale", props = { "Scale" }, wrap = identity },
}

local function install(quad: any)
	local dispatch = quad.Dispatch
	local Void = quad.Void
	local isTween = quad.isTween

	-- (inst, childName) -> managed child (weak-keyed by inst)
	local managed = quad.Relate()

	local function ensureManagedChild(inst: any, entry: any): any
		local child = managed:GetStrong(inst, entry.childName)
		if child == nil then
			-- late read: `quad.D` is merged by UseProvider after this install ran (`H-174`)
			child = quad.D.New(entry.class)({ Name = entry.childName })
			child.Parent = inst
			managed:SetStrong(inst, entry.childName, child)
		end
		return child
	end

	local function destroyManagedChild(inst: any, entry: any)
		local child = managed:GetStrong(inst, entry.childName)
		if child == nil then
			return
		end
		-- `H-218`: retract the delegated chains BEFORE destroying — a reactive
		-- shorthand value's StoreBind subscription would otherwise pile up per
		-- destroy/recreate cycle (static values: no-op retractor, ~free)
		for _, prop in entry.props do
			dispatch.retractFrom(child, prop, 1)
		end
		managed:SetStrong(inst, entry.childName, nil)
		child:Destroy()
	end

	dispatch.addHandler({
		name = "InstanceShorthand",
		keyType = "string", -- `H-484`: only string keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			return type(k) == "string" and TABLE[k] ~= nil
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL + 1,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			local entry = TABLE[k]
			if v == nil then
				destroyManagedChild(inst, entry) -- "`v`가 `nil`인 경우" 절 — process's own job
				return Void
			end
			local tweenIn = isTween(v)
			-- Q17 (a) (사용자 결정 2026-09-07): no value gate here — the type surface is the first
			-- defense; a wrong value raises where it is first used (`UDim.new` inside `offsetUDim`
			-- for UIPaddingOffset, or the delegated property write for the others — `numberOnly`
			-- was an unapproved fifth field, `H-402`). round3 `H-449`: the wrap runs BEFORE the
			-- managed child is created, so such a raise leaves no half-made child behind.
			-- Tween stays a Tween — only `.Value` is wrapped (`UI-8`, `Tween:Mapped`). The
			-- fresh object per emit is harmless: the Property handler dedups by target VALUE
			-- (round3 Q25, 2026-09-08 — the old object-identity check broke exactly here)
			-- identity wrap (UIPadding/UIScale): pass the Tween through — `Mapped`
			-- would clone+re-validate+re-freeze an identical value per emit (2차 리뷰)
			local mapped = if entry.wrap == identity then v elseif tweenIn then v:Mapped(entry.wrap) else entry.wrap(v)
			local child = ensureManagedChild(inst, entry)
			for _, prop in entry.props do
				dispatch.process(child, prop, mapped, 1) -- new chain per (child, prop), index 1
			end
			return Void -- `H-135`: nothing to undo — destruction is the `v == nil` path
		end,
	} :: QuadTypes.Handler)
end

return install
