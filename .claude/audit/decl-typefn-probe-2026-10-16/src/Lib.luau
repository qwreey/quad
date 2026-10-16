--!strict
--[[
	Lib — stand-in for a quad-roblox module that would ship the TYPE-FUNCTION surface
	(declaration-surface-plan.md). Type-level only: every runtime value is a `nil :: any`
	stub, the probe asks only the checker (Studio / VSCode luau-lsp / CLI).

	One dispatcher type function `Build<Mode, C, Policy>` builds every axis from the engine
	class type `C` (walks `C:properties()` / `C:readparent()`), so the helpers live in one
	body (no type-function-to-type-function calls — kept out on purpose so a Studio failure
	of that feature cannot take the whole pack down). Public aliases below are what a user
	would touch:

	  Props<C>          props table of an element constructor (keys + array part `Elem<C>`)
	  Modifier<C>       Modifier with chained setters (replaces generated `<Class>Modifier`)
	  Elem<C>           array-part value union for class C
	  SpreadMarker<C>   content-less result of `Spread<<C>>({...})`
	  EventMap          scope-wide event name -> callback map (for `OnEvent(name, fn)`)
	  Events<C>         class-bound event map (for the class-bound OnEvent variants)

	Policy (the "exceptions inside the type function" — user hypothesis, Q5) is DATA passed as
	a table type, not generator branches:
	  Deny    names never offered as props/Modifier keys (dump ReadOnly ∪ dump dropped props/events −
	          {Scale}; from quad-roblox/dump/api-surface.json readProps + dropped, 2026-10-16)
	  DenyIn  per-class denials (WorldModel.Scale is NotScriptable but UIScale.Scale is not)
	  Inject  per-class names ADDED when the checker's class data lacks them (only if missing):
	          Hidden `Transparency` (missing in the extension's PluginSecurity defs) and
	          Deprecated `FontSize`/`TextWrap` (in no luau-lsp defs; Studio has them) — these are
	          gen-d.py's HIDDEN_NAME_KEEP / DEPRECATED_NAME_KEEP
	  Child   backend-agnostic children union (NewChild stand-in)
]]

-- ── markers (subset of quad-types; same field names) ─────────────────────
export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }
export type None = { read __quadNone: true }
export type TweenData<T> = { read __quadTween: true, read Value: T }
export type ModifierMarker = { read __quadModifier: true }
export type NewChild = Instance | StateMarker<Instance?> | None | ModifierMarker

-- ── policy data ────────────────────────────────────────────────────────────
type Deny = {
	-- ReadOnly (dump readProps)
	AbsoluteCanvasSize: true, AbsoluteCellCount: true, AbsoluteCellSize: true, AbsoluteContentSize: true,
	AbsolutePosition: true, AbsoluteRotation: true, AbsoluteSize: true, AbsoluteWindowSize: true,
	ClassName: true, ContentText: true, CurrentDistance: true, CurrentPage: true, GuiState: true,
	IsLoaded: true, NearPlaneZ: true, OpenTypeFeaturesError: true, Parent: true, Resolution: true,
	TextBounds: true, TextFits: true, TimeLength: true, ViewportSize: true,
	-- dump dropped (ReadOnly/Deprecated/NotScriptable/Hidden/security), minus Scale
	BackgroundColor: true, BorderColor: true, ClippedRect: true, ContentImageSize: true, CoordinateFrame: true,
	DataCost: true, DistanceLowerLimit: true, DistanceUpperLimit: true, Draggable: true, DraggingScrollBar: true,
	HorizontalBarRect: true, HorizontalCurvature: true, IgnoresTitleBarReservation: true, InternalVideoUsage: true,
	IsInSandbox: true, IsMirrored: true, IsNotOccluded: true, LevelOfDetail: true, LocalizationMatchIdentifier: true,
	LocalizationMatchedSourceText: true, Localize: true, LocalizedImageContent: true, LocalizedText: true,
	ManualFocusRelease: true, MaxCanvasPosition: true, MaximumResolution: true, Mode: true, OnTopOfCoreBlur: true,
	Origin: true, OverlayNativeInput: true, PhysicsStepTime: true, PredictionMode: true, RawRect2D: true,
	ResolutionScale: true, ReturnKeyType: true, RobloxLocked: true, ScrollRate: true, ScrollVelocity: true,
	SelectionRect2D: true, Shape: true, ShouldEmitReturnEvents: true, ShouldEmitTabEvents: true,
	ShouldEmitUpAndDownArrowEvents: true, SmoothScroll: true, SourceAssetId: true, TabKeyboardNavigation: true,
	TextColor: true, TextInputType: true, TotalGroupScale: true, UniqueId: true, VerticalBarRect: true,
	archivable: true, className: true, focus: true,
	-- dump dropped events (Deprecated / security)
	DragBegin: true, DragStopped: true, FirstPersonTransition: true, childAdded: true,
}
type DenyIn = {
	WorldModel: { Scale: true },
}
type Inject = {
	GuiObject: { Transparency: number },
	TextLabel: { FontSize: Enum.FontSize, TextWrap: boolean },
	TextButton: { FontSize: Enum.FontSize, TextWrap: boolean },
	TextBox: { FontSize: Enum.FontSize, TextWrap: boolean },
}
export type Policy = { Deny: Deny, DenyIn: DenyIn, Inject: Inject, Child: NewChild }
-- [2026-10-16] Mapper axis: same props, plus child descriptors in the array part (generated `<Class>MapperElem = <Class>Elem | MapperDescriptor`)
export type MapperDescriptor = { read _mapper: true }
export type MapperRootKey = { read __quadMapperRoot: true }
export type MapperPolicy = { Deny: Deny, DenyIn: DenyIn, Inject: Inject, Child: NewChild | MapperDescriptor }

-- scope = the 31 classes the generated Declaration covers today (gen-d.py H-296)
export type Scope = BillboardGui | Camera | CanvasGroup | Folder | Frame | ImageButton | ImageLabel | ScreenGui
	| ScrollingFrame | SurfaceGui | TextBox | TextButton | TextLabel | UIAspectRatioConstraint | UICorner
	| UIDragDetector | UIFlexItem | UIGradient | UIGridLayout | UIListLayout | UIPadding | UIPageLayout | UIScale
	| UIShadow | UISizeConstraint | UIStroke | UITableLayout | UITextSizeConstraint | VideoFrame | ViewportFrame
	| WorldModel

export type function Build(mode: type, cls: type, policy: type)
	local M = mode:value()
	local NIL = types.singleton(nil)
	local TRUE = types.singleton(true)

	local function rotbl(fields: { [string]: type }): type
		local m: { [type]: { read: type?, write: type? } } = {}
		for k, v in fields do
			m[types.singleton(k)] = { read = v }
		end
		return types.newtable(m)
	end
	local function sub(t: type?, name: string): type?
		if t == nil or t.tag ~= "table" then
			return nil
		end
		for k, v in t:properties() do
			if k:value() == name then
				return v.read or v.write
			end
		end
		return nil
	end
	local function nameset(t: type?): { [string]: boolean }
		local s: { [string]: boolean } = {}
		if t ~= nil and t.tag == "table" then
			for k, _ in t:properties() do
				local n = k:value()
				if type(n) == "string" then
					s[n] = true
				end
			end
		end
		return s
	end
	-- event: defs give a table with `Connect`; Studio gives extern RBXScriptSignal (readproperty is
	-- table-only there — 2026-09-16 [P6]), so look `Connect` up through properties() for externs.
	local function callbackOf(ty: type): type?
		local conn: type? = nil
		if ty.tag == "table" then
			conn = ty:readproperty(types.singleton("Connect"))
		elseif ty.tag == "extern" then
			for k, v in ty:properties() do
				if k:value() == "Connect" then
					conn = v.read or v.write
					break
				end
			end
		end
		if conn ~= nil and conn.tag == "function" then
			local head = conn:parameters().head
			if head ~= nil and head[2] ~= nil then
				return head[2]
			end
		end
		return nil
	end
	-- full chain up to the root (Object carries `Changed`); readparent() of the root is nil.
	-- Tag names (`__quadModifier`/`__quadSpread`) stop at Instance — see chainNames.
	local function chainOf(c: type): { type }
		local out = {}
		local cur: type? = c
		local d = 0
		while cur ~= nil and d < 12 do
			out[#out + 1] = cur
			cur = cur:readparent()
			d += 1
		end
		return out
	end
	local tweenable = {
		number = true, boolean = true, CFrame = true, Rect = true, Color3 = true,
		UDim = true, UDim2 = true, Vector2 = true, Vector2int16 = true, Vector3 = true,
	}
	local deny = nameset(sub(policy, "Deny"))
	local denyIn = sub(policy, "DenyIn")
	local inject = sub(policy, "Inject")

	type Info = { kind: string, ty: type, injected: boolean }
	local function collect(c: type): ({ string }, { [string]: Info }, { type })
		local names: { string } = {}
		local info: { [string]: Info } = {}
		local chain = chainOf(c)
		local denyHere: { [string]: boolean } = {}
		for _, k in chain do
			for n in nameset(sub(denyIn, tostring(k))) do
				denyHere[n] = true
			end
		end
		for _, k in chain do
			for key, v in k:properties() do
				local n = key:value()
				if type(n) == "string" and info[n] == nil and not deny[n] and not denyHere[n] then
					local ty = v.read or v.write
					-- methods: `function` (one signature) or `intersection` (overloads, e.g. WaitForChild)
					if ty ~= nil and ty.tag ~= "function" and ty.tag ~= "intersection" then
						local cb = callbackOf(ty)
						if cb ~= nil then
							info[n] = { kind = "event", ty = cb, injected = false }
						else
							info[n] = { kind = "prop", ty = ty, injected = false }
						end
						names[#names + 1] = n
					end
				end
			end
		end
		for _, k in chain do
			local inj = sub(inject, tostring(k))
			if inj ~= nil and inj.tag == "table" then
				for key, v in inj:properties() do
					local n = key:value()
					local ty = v.read or v.write
					if type(n) == "string" and ty ~= nil and info[n] == nil and not deny[n] and not denyHere[n] then
						info[n] = { kind = "prop", ty = ty, injected = true }
						names[#names + 1] = n
					end
				end
			end
		end
		table.sort(names)
		return names, info, chain
	end
	local function stateOf(t: type): type
		return rotbl({ __quadState = TRUE, __quadStateValue = t })
	end
	local NONE = rotbl({ __quadNone = TRUE })
	local function chainNames(chain: { type }): type
		local parts: { type } = {}
		for _, k in chain do
			parts[#parts + 1] = types.singleton(tostring(k))
			if tostring(k) == "Instance" then
				break
			end
		end
		if #parts == 1 then
			return parts[1]
		end
		return types.unionof(table.unpack(parts))
	end
	local function singletonUnion(list: { string }): type
		if #list == 0 then
			return types.never
		end
		local parts: { type } = {}
		for _, n in list do
			parts[#parts + 1] = types.singleton(n)
		end
		if #parts == 1 then
			return parts[1]
		end
		return types.unionof(table.unpack(parts))
	end
	local function elemOf(c: type): type
		local names, info, chain = collect(c)
		local events: { string } = {}
		for _, n in names do
			if info[n].kind == "event" then
				events[#events + 1] = n
			end
		end
		local tags = chainNames(chain)
		local child = sub(policy, "Child") or types.unknown
		return types.unionof(
			child,
			rotbl({ __quadModifier = tags }),
			rotbl({ __quadSpread = tags }),
			rotbl({ __quadEvent = singletonUnion(events) })
		)
	end

	if M == "classname" then
		return types.singleton(tostring(cls))
	elseif M == "spreadmarker" then
		return rotbl({ __quadSpread = types.singleton(tostring(cls)) })
	elseif M == "elem" then
		return elemOf(cls)
	elseif M == "props" then
		local names, info = collect(cls)
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in names do
			local i = info[n]
			local arms: { type } = {}
			if i.kind == "event" then
				arms = { i.ty, stateOf(types.unionof(i.ty, NONE, NIL)), NONE, NIL }
			else
				arms = { i.ty }
				if tweenable[tostring(i.ty)] then
					arms[#arms + 1] = rotbl({ __quadTween = TRUE, Value = i.ty })
				end
				arms[#arms + 1] = stateOf(i.ty)
				arms[#arms + 1] = NONE
				arms[#arms + 1] = NIL
			end
			local u = types.unionof(table.unpack(arms))
			props[types.singleton(n)] = { read = u, write = u }
		end
		local elem = elemOf(cls)
		return types.newtable(props, { index = types.number, readresult = elem, writeresult = elem })
	elseif M == "modifier" then
		local names, info = collect(cls)
		local t = types.newtable()
		t:setreadproperty(types.singleton("__quadModifier"), types.singleton(tostring(cls)))
		-- reserved generic methods (8.29/§6 — does a type-function-built table keep them usable?)
		local T = types.generic("T")
		t:setproperty(types.singleton("Peek"),
			types.newfunction({ head = { t, types.string } }, { head = { types.unionof(T, NIL) } }, { T }))
		local U = types.generic("U")
		t:setproperty(types.singleton("Apply"),
			types.newfunction({ head = { types.any, types.newfunction({ head = { types.any } }, { head = { U } }) } },
				{ head = { U } }, { U }))
		for _, n in names do
			local i = info[n]
			if i.kind == "prop" then
				local arms: { type } = { i.ty }
				if tweenable[tostring(i.ty)] then
					arms[#arms + 1] = rotbl({ __quadTween = TRUE, Value = i.ty })
				end
				arms[#arms + 1] = stateOf(i.ty)
				arms[#arms + 1] = NONE
				arms[#arms + 1] = NIL
				local v = types.unionof(table.unpack(arms))
				local transform = types.newfunction({ head = { types.unionof(i.ty, NIL) } }, { head = { v } })
				t:setproperty(types.singleton(n),
					types.newfunction({ head = { t, types.unionof(v, transform) } }, { head = { t } }))
			end
		end
		return t
	elseif M == "events" then
		local classes: { type } = {}
		if cls.tag == "union" then
			for _, c in cls:components() do
				classes[#classes + 1] = c
			end
		else
			classes = { cls }
		end
		local map: { [string]: type } = {}
		local order: { string } = {}
		for _, c in classes do
			local names, info = collect(c)
			for _, n in names do
				local i = info[n]
				if i.kind == "event" then
					local prev = map[n]
					if prev == nil then
						map[n] = i.ty
						order[#order + 1] = n
					elseif tostring(prev) ~= tostring(i.ty) then
						map[n] = types.any -- same event name, different callback across classes
					end
				end
			end
		end
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in order do
			props[types.singleton(n)] = { read = map[n] }
		end
		return types.newtable(props)
	elseif M == "eventargs" then
		-- like "events", but each entry is a fixed-arity record { a1..a4 } of the callback's parameters
		-- (missing → nil), so OnEventP can spell the callback as an explicit 4-parameter function type —
		-- a bare `fn: index<EventMap, K>` gives the lambda NO contextual type (params stay unknown).
		local classes: { type } = {}
		if cls.tag == "union" then
			for _, c in cls:components() do
				classes[#classes + 1] = c
			end
		else
			classes = { cls }
		end
		local map: { [string]: { type } } = {}
		local sig: { [string]: string } = {}
		local order: { string } = {}
		for _, c in classes do
			local names, info = collect(c)
			for _, n in names do
				local i = info[n]
				if i.kind == "event" and i.ty.tag == "function" then
					local head = i.ty:parameters().head or {}
					local args: { type } = {}
					for k = 1, 4 do
						args[k] = head[k] or NIL
					end
					if map[n] == nil then
						map[n] = args
						sig[n] = tostring(i.ty)
						order[#order + 1] = n
					elseif sig[n] ~= tostring(i.ty) then
						map[n] = { types.any, types.any, types.any, types.any }
					end
				end
			end
		end
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in order do
			local a = map[n]
			props[types.singleton(n)] = { read = rotbl({ a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4] }) }
		end
		return types.newtable(props)
	elseif M == "report" then
		-- Q5: print what the policy-applied surface looks like in THIS checker
		local names, info, chain = collect(cls)
		local np, ne = 0, 0
		local injected: { string } = {}
		for _, n in names do
			if info[n].kind == "event" then
				ne += 1
			else
				np += 1
			end
			if info[n].injected then
				injected[#injected + 1] = n
			end
		end
		local chainStr: { string } = {}
		for _, k in chain do
			chainStr[#chainStr + 1] = tostring(k)
		end
		print("[R] " .. tostring(cls) .. " chain=" .. table.concat(chainStr, ">") .. " props=" .. np
			.. " events=" .. ne .. " injected={" .. table.concat(injected, ",") .. "}")
		local watch = { "Transparency", "FontSize", "TextWrap", "Font", "FontFace", "BackgroundColor", "DataCost",
			"AbsoluteSize", "ClassName", "Parent", "MouseEnter", "Activated", "Text", "Style" }
		local parts: { string } = {}
		for _, n in watch do
			local i = info[n]
			parts[#parts + 1] = n .. "=" .. (if i == nil then "-" else (i.kind .. ":" .. string.sub(tostring(i.ty), 1, 40)))
		end
		print("[R] " .. tostring(cls) .. " :: " .. table.concat(parts, " | "))
		return types.string
	elseif M == "brief" then
		-- Studio check (2026-10-16): the whole Q5 report as ONE diagnostic — Studio has no way to copy many diagnostics at once.
		-- `cls` may be a union; one line per class joined with " ;; ".
		local list: { type } = if cls.tag == "union" then cls:components() else { cls }
		local out: { string } = {}
		for _, c in list do
			local names, info = collect(c)
			local np, ne = 0, 0
			local injected: { string } = {}
			for _, n in names do
				if info[n].kind == "event" then ne += 1 else np += 1 end
				if info[n].injected then injected[#injected + 1] = n end
			end
			-- compact: "Frame 38/26 +Transparency" ; flags only when something is off from the Linux expectation
			local me = info["MouseEnter"]
			local flags = ""
			if info["BackgroundColor"] then flags ..= " !BgColor" end
			if info["DataCost"] then flags ..= " !DataCost" end
			if me ~= nil and tostring(me.ty) ~= "(number, number) -> ()" then flags ..= " ME=" .. string.sub(tostring(me.ty), 1, 30) end
			out[#out + 1] = tostring(c) .. " " .. np .. "/" .. ne .. (if #injected > 0 then " +" .. table.concat(injected, ",") else "") .. flags
		end
		print("[BRIEF] " .. table.concat(out, "; "))
		return types.string
	elseif M == "names" then
		-- Q5: the full policy-applied key list (props then events), for line-by-line diffing across checkers
		local names, info = collect(cls)
		local ps: { string } = {}
		local es: { string } = {}
		for _, n in names do
			if info[n].kind == "event" then
				es[#es + 1] = n
			else
				ps[#ps + 1] = n .. (if info[n].injected then "+" else "")
			end
		end
		print("[N] " .. tostring(cls) .. " props(" .. #ps .. "): " .. table.concat(ps, " "))
		print("[N] " .. tostring(cls) .. " events(" .. #es .. "): " .. table.concat(es, " "))
		return types.string
	end
	print("Build: unknown mode " .. tostring(M))
	return types.never
end

-- ── public aliases ─────────────────────────────────────────────────────────
export type Props<C> = Build<"props", C, Policy>
export type MapperProps<C> = Build<"props", C, MapperPolicy>
export type Modifier<C> = Build<"modifier", C, Policy>
export type Elem<C> = Build<"elem", C, Policy>
export type SpreadMarker<C> = Build<"spreadmarker", C, Policy>
export type ClassName<C> = Build<"classname", C, Policy>
export type Events<C> = Build<"events", C, Policy>
export type EventMap = Build<"events", Scope, Policy>
export type Report<C> = Build<"report", C, Policy>
export type Brief<C> = Build<"brief", C, Policy>
export type Names<C> = Build<"names", C, Policy>
export type EventArgs = Build<"eventargs", Scope, Policy>
export type EventDesc<K> = { read __quadEvent: K }
export type Ctor<C> = (Props<C>) -> C

-- priming (8.22) — the defining module instantiates the exported type function once
type _Prime = Build<"classname", Frame, Policy>

local Lib = {}
-- element constructor factory: `New<<Frame>>("Frame")` -> (Props<Frame>) -> Frame
Lib.New = (nil :: any) :: <C>(className: ClassName<C>) -> (Props<C>) -> C
-- same, without the class-name check (string)
Lib.NewLoose = (nil :: any) :: <C>(className: string) -> (Props<C>) -> C
-- Spread<<C>>({...}) -> SpreadMarker<C> (content-less)
Lib.Spread = (nil :: any) :: <C>(props: Props<C>) -> SpreadMarker<C>
-- Modifier<<C>>() -> Modifier<C>
Lib.Modifier = (nil :: any) :: <C>(...any) -> Modifier<C>
-- OnEvent(name, fn): scope-wide name map (like OnChange's PropTypesRead)
Lib.OnEvent = (nil :: any) :: <K>(name: K & keyof<EventMap>, fn: index<EventMap, K>) -> EventDesc<K>
-- curried OnEvent: K is fixed by the first call, so the second call's parameter is a CONCRETE function type
-- and an unannotated lambda gets contextual parameter types (hover/completion inside the body)
Lib.OnEventC = (nil :: any) :: <K>(name: K & keyof<EventMap>) -> (fn: index<EventMap, K>) -> EventDesc<K>
-- OnEvent with an explicit 4-parameter callback type (contextual typing for unannotated lambdas)
Lib.OnEventP = (nil :: any) :: <K>(
	name: K & keyof<EventArgs>,
	fn: (index<index<EventArgs, K>, "a1">, index<index<EventArgs, K>, "a2">, index<index<EventArgs, K>, "a3">, index<index<EventArgs, K>, "a4">) -> ()
) -> EventDesc<K>
-- class-bound variants (Q4 alternatives)
Lib.OnEventIn = (nil :: any) :: <C, K>(name: K & keyof<Events<C>>, fn: index<Events<C>, K>) -> EventDesc<K>
Lib.OnEventFor = (nil :: any) :: <C>() -> <K>(name: K & keyof<Events<C>>, fn: index<Events<C>, K>) -> EventDesc<K>
-- Tween stand-in
Lib.Tween = (nil :: any) :: <T>(value: T) -> TweenData<T>
Lib.None = (nil :: any) :: None
return Lib
