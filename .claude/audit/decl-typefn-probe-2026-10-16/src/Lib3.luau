--!strict
--[[
	Lib3 — [2026-10-19] M3 follow-up copy of `Lib2.luau` (Lib2 left untouched). Probe choices, not decisions.
	Added against Lib2:
	  * (다) Policy.AsTargets = { [Class]: { [Desc]: true } } — when the field is present, `modOf` builds the
	    checked down-cast `As<Desc>` only for listed descendants (unlisted classes: identity only). Absent = Lib2 tree.
	    Policies PolicyT2/T4/T7/T10/T13/T13n below (GuiObject list sizes; ancestors GuiBase2d/GuiBase/Instance → GuiObject).
	  * (라) thin Into: `{ read __quadModifier: "C" | <ancestor names>, As<C>: (self: any) -> Modifier<C> }`
	      IntoThinP<C, P>      self-built (Build "intothin": the method's Modifier<C> is a copy built in that call)
	      IntoThinWithP<C, P>  IntoThinWith<C, Modifier<C>> — takes the already-built Modifier as an argument
	  * policy-parameterised aliases ModP / IntoP (= Lib2 IntoWith form) so one template runs against every policy.
	  * Deny/DenyWrite/DenyIn/Inject exported (use files may compose policies).

	Lib2 header follows.

	What changed against Lib (all probe choices, not decisions):
	  * Policy splits the write-only denial out of `Deny`:
	      Deny        names denied on BOTH surfaces (Deprecated/NotScriptable/Hidden/security — dump dropped)
	      DenyWrite   names denied on the WRITE surface only (dump ReadOnly ∪ Parent — readProps)
	      DenyIn      per-class (owner-keyed) both-surface denials
	      DenyWriteIn per-class (owner-keyed) write-only denials (M4 full-dump policy fills these)
	    `readmap` (OnChange/Out) walks with forRead=true → ReadOnly props appear there (M2), while
	    `props` / `modifier` keep denying them.
	  * Shorthand (policy data, per class, walks the chain): the four GuiObject convenience keys
	    (`UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale`) on the props table AND as Modifier setters (M3 d).
	  * Modifier<C> now carries the generated-D reserved methods (M3): `Overridden(self, ...any) -> any`,
	    unchecked `As<<T>>(name?)`, and the checked down-casts `As<Desc>()` for every class in
	    `Policy.Classes` whose chain contains C (identity `As<C>` included) — built in the same call,
	    memoised per class.
	  * ModifierInto<C> = IntoWith<C, Modifier<C>> — `{ As<C>: (self: any) -> Modifier<C> }` (M3 b).
	  * Descriptors per the 2026-10-19 decision: OnChangeDescriptor<K> / OnEventDescriptor<K> (read fields, K = name).
	  * `rwreport` mode: one-line print of how the checker exposes a property's read/write halves (M2).
]]

-- ── markers (subset of quad-types; same field names) ─────────────────────
export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }
export type None = { read __quadNone: true }
export type TweenData<T> = { read __quadTween: true, read Value: T }
export type ModifierMarker = { read __quadModifier: true }
export type NewChild = Instance | StateMarker<Instance?> | None | ModifierMarker

-- ── policy data ────────────────────────────────────────────────────────────
-- dump readProps (ReadOnly) + Parent — write surface only
export type DenyWrite = {
	AbsoluteCanvasSize: true, AbsoluteCellCount: true, AbsoluteCellSize: true, AbsoluteContentSize: true,
	AbsolutePosition: true, AbsoluteRotation: true, AbsoluteSize: true, AbsoluteWindowSize: true,
	ClassName: true, ContentText: true, CurrentDistance: true, CurrentPage: true, GuiState: true,
	IsLoaded: true, NearPlaneZ: true, OpenTypeFeaturesError: true, Parent: true, Resolution: true,
	TextBounds: true, TextFits: true, TimeLength: true, ViewportSize: true,
}
-- dump dropped (Deprecated/NotScriptable/Hidden/security, incl. Hidden∧ReadOnly twins), minus Scale — both surfaces
export type Deny = {
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
	DragBegin: true, DragStopped: true, FirstPersonTransition: true, childAdded: true,
}
export type DenyIn = {
	WorldModel: { Scale: true },
}
export type Inject = {
	GuiObject: { Transparency: number },
	TextLabel: { FontSize: Enum.FontSize, TextWrap: boolean },
	TextButton: { FontSize: Enum.FontSize, TextWrap: boolean },
	TextBox: { FontSize: Enum.FontSize, TextWrap: boolean },
}
-- ui-shorthand-plan keys (generated D puts them on GuiObject and every descendant)
export type Shorthand = {
	GuiObject: { UICorner: number | UDim, UIPadding: UDim, UIPaddingOffset: number, UIScale: number },
}
-- scope 31 + their abstract ancestors = the 47 classes generated D emits a `<Class>Modifier` for
export type ModClassMap = {
	BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame,
	GuiBase: GuiBase, GuiBase2d: GuiBase2d, GuiButton: GuiButton, GuiLabel: GuiLabel, GuiObject: GuiObject,
	ImageButton: ImageButton, ImageLabel: ImageLabel, Instance: Instance, LayerCollector: LayerCollector, Model: Model,
	PVInstance: PVInstance, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui,
	SurfaceGuiBase: SurfaceGuiBase, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel,
	UIAspectRatioConstraint: UIAspectRatioConstraint, UIBase: UIBase, UIComponent: UIComponent, UIConstraint: UIConstraint,
	UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient,
	UIGridLayout: UIGridLayout, UIGridStyleLayout: UIGridStyleLayout, UILayout: UILayout, UIListLayout: UIListLayout,
	UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow,
	UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout,
	UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame,
	WorldModel: WorldModel, WorldRoot: WorldRoot,
}
export type CreatableMap = {
	BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame,
	ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame,
	SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel,
	UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector,
	UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout,
	UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow,
	UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout,
	UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame,
	WorldModel: WorldModel,
}
export type Policy = {
	Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap,
}
export type MapperDescriptor = { read _mapper: true }
export type MapperRootKey = { read __quadMapperRoot: true }
export type MapperPolicy = {
	Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild | MapperDescriptor, Classes: ModClassMap,
}

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
	local function chainOf(c: type): { type }
		local out = {}
		local cur: type? = c
		local d = 0
		while cur ~= nil and d < 16 do
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
	local denyWrite = nameset(sub(policy, "DenyWrite"))
	local denyIn = sub(policy, "DenyIn")
	local denyWriteIn = sub(policy, "DenyWriteIn")
	local inject = sub(policy, "Inject")
	local shorthand = sub(policy, "Shorthand")
	local classesT = sub(policy, "Classes")

	type Info = { kind: string, ty: type, injected: boolean }
	local collectCache: { [string]: { any } } = {}
	local function collect(c: type, forRead: boolean): ({ string }, { [string]: Info }, { type })
		local ck = tostring(c) .. (if forRead then "/r" else "/w")
		local hit = collectCache[ck]
		if hit ~= nil then
			return hit[1], hit[2], hit[3]
		end
		local names: { string } = {}
		local info: { [string]: Info } = {}
		local chain = chainOf(c)
		local denyHere: { [string]: boolean } = {}
		for _, k in chain do
			local kn = tostring(k)
			for n in nameset(sub(denyIn, kn)) do
				denyHere[n] = true
			end
			if not forRead then
				for n in nameset(sub(denyWriteIn, kn)) do
					denyHere[n] = true
				end
			end
		end
		local function denied(n: string): boolean
			return deny[n] == true or denyHere[n] == true or ((not forRead) and denyWrite[n] == true)
		end
		for _, k in chain do
			for key, v in k:properties() do
				local n = key:value()
				if type(n) == "string" and info[n] == nil and not denied(n) then
					local ty = v.read or v.write
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
					if type(n) == "string" and ty ~= nil and info[n] == nil and not denied(n) then
						info[n] = { kind = "prop", ty = ty, injected = true }
						names[#names + 1] = n
					end
				end
			end
			if not forRead then
				local sh = sub(shorthand, tostring(k))
				if sh ~= nil and sh.tag == "table" then
					for key, v in sh:properties() do
						local n = key:value()
						local ty = v.read or v.write
						if type(n) == "string" and ty ~= nil and info[n] == nil then
							info[n] = { kind = "shorthand", ty = ty, injected = true }
							names[#names + 1] = n
						end
					end
				end
			end
		end
		table.sort(names)
		collectCache[ck] = { names, info, chain }
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
		local names, info, chain = collect(c, false)
		local events: { string } = {}
		for _, n in names do
			if info[n].kind == "event" then
				events[#events + 1] = n
			end
		end
		local rnames, rinfo = collect(c, true)
		local readable: { string } = {}
		for _, n in rnames do
			if rinfo[n].kind == "prop" then
				readable[#readable + 1] = n
			end
		end
		local tags = chainNames(chain)
		local child = sub(policy, "Child") or types.unknown
		return types.unionof(
			child,
			rotbl({ __quadModifier = tags }),
			rotbl({ __quadSpread = tags }),
			rotbl({ __quadEvent = singletonUnion(events) }),
			rotbl({ __quadChange = singletonUnion(readable) })
		)
	end
	-- value arms of a writable slot (props key / Modifier setter)
	local function slotArms(i: Info): type
		local arms: { type } = { i.ty }
		if tweenable[tostring(i.ty)] then
			arms[#arms + 1] = rotbl({ __quadTween = TRUE, Value = i.ty })
		end
		if i.kind == "shorthand" then
			arms[#arms + 1] = stateOf(types.unionof(i.ty, NONE, NIL)) -- nil/None destroys the managed child
		else
			arms[#arms + 1] = stateOf(i.ty)
		end
		arms[#arms + 1] = NONE
		arms[#arms + 1] = NIL
		return types.unionof(table.unpack(arms))
	end
	-- classes of Policy.Classes whose chain contains c (c itself included when it is in the map)
	local function descendantsOf(c: type): { type }
		local out: { type } = {}
		local cn = tostring(c)
		if classesT ~= nil and classesT.tag == "table" then
			for _, v in classesT:properties() do
				local x = v.read or v.write
				local cur: type? = x
				local d = 0
				while cur ~= nil and d < 16 do
					if tostring(cur) == cn then
						out[#out + 1] = x :: type
						break
					end
					cur = cur:readparent()
					d += 1
				end
			end
		end
		return out
	end
	local modCache: { [string]: type } = {}
	-- Policy.AsDepth (probe knob, M3): absent = full checked down-cast tree; 0 = identity only;
	-- 1 = down-casts whose results carry only their identity cast (no second hop)
	local asTargetsT = sub(policy, "AsTargets") -- (다) probe knob: per-class down-cast allow list
	local asDepthT = sub(policy, "AsDepth")
	local asDepth: number = if asDepthT ~= nil and asDepthT.tag == "singleton" then (tonumber(asDepthT:value()) or 99) else 99
	local function modOf(c: type, depth: number?): type
		local dp: number = depth or asDepth
		local key = tostring(c)
		local mk = key .. "#" .. tostring(dp)
		local hit = modCache[mk]
		if hit ~= nil then
			return hit
		end
		local names, info = collect(c, false)
		local t = types.newtable()
		modCache[mk] = t
		t:setreadproperty(types.singleton("__quadModifier"), types.singleton(key))
		local T = types.generic("T")
		t:setproperty(types.singleton("Peek"),
			types.newfunction({ head = { t, types.string } }, { head = { types.unionof(T, NIL) } }, { T }))
		local U = types.generic("U")
		t:setproperty(types.singleton("Apply"),
			types.newfunction({ head = { types.any, types.newfunction({ head = { types.any } }, { head = { U } }) } },
				{ head = { U } }, { U }))
		t:setproperty(types.singleton("Overridden"),
			types.newfunction({ head = { t }, tail = types.any }, { head = { types.any } }))
		local AT = types.generic("T")
		t:setproperty(types.singleton("As"),
			types.newfunction({ head = { t, types.optional(types.string) } }, { head = { AT } }, { AT }))
		t:setproperty(types.singleton("As" .. key), types.newfunction({ head = { t } }, { head = { t } }))
		if dp > 0 then
			local allow: { [string]: boolean }? = if asTargetsT ~= nil then nameset(sub(asTargetsT, key)) else nil
			for _, d in descendantsOf(c) do
				if tostring(d) ~= key and (allow == nil or allow[tostring(d)] == true) then
					t:setproperty(types.singleton("As" .. tostring(d)), types.newfunction({ head = { t } }, { head = { modOf(d, dp - 1) } }))
				end
			end
		end
		for _, n in names do
			local i = info[n]
			if i.kind == "prop" or i.kind == "shorthand" then
				local v = slotArms(i)
				local transform = types.newfunction({ head = { types.unionof(i.ty, NIL) } }, { head = { v } })
				t:setproperty(types.singleton(n),
					types.newfunction({ head = { t, types.unionof(v, transform) } }, { head = { t } }))
			end
		end
		return t
	end

	if M == "classname" then
		return types.singleton(tostring(cls))
	elseif M == "spreadmarker" then
		return rotbl({ __quadSpread = types.singleton(tostring(cls)) })
	elseif M == "elem" then
		return elemOf(cls)
	elseif M == "props" then
		local names, info = collect(cls, false)
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in names do
			local i = info[n]
			local u: type
			if i.kind == "event" then
				u = types.unionof(i.ty, stateOf(types.unionof(i.ty, NONE, NIL)), NONE, NIL)
			else
				u = slotArms(i)
			end
			props[types.singleton(n)] = { read = u, write = u }
		end
		local elem = elemOf(cls)
		return types.newtable(props, { index = types.number, readresult = elem, writeresult = elem })
	elseif M == "modifier" then
		return modOf(cls)
	elseif M == "intothin" then
		-- (라) thin Into, self-built: tag (C and its ancestors) + one checked As<C>
		local t = types.newtable()
		t:setreadproperty(types.singleton("__quadModifier"), chainNames(chainOf(cls)))
		t:setproperty(types.singleton("As" .. tostring(cls)), types.newfunction({ head = { types.any } }, { head = { modOf(cls) } }))
		return t
	elseif M == "into" then
		-- self-built variant (the IntoWith alias below reuses an already-built Modifier<C> instead)
		local t = types.newtable()
		t:setproperty(types.singleton("As" .. tostring(cls)), types.newfunction({ head = { types.any } }, { head = { modOf(cls) } }))
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
			local names, info = collect(c, false)
			for _, n in names do
				local i = info[n]
				if i.kind == "event" then
					local prev = map[n]
					if prev == nil then
						map[n] = i.ty
						order[#order + 1] = n
					elseif tostring(prev) ~= tostring(i.ty) then
						map[n] = types.any
					end
				end
			end
		end
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in order do
			props[types.singleton(n)] = { read = map[n] }
		end
		return types.newtable(props)
	elseif M == "propmap" then
		-- WRITE surface name -> value type (ReadOnly denied)
		local names, info = collect(cls, false)
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in names do
			local i = info[n]
			if i.kind == "prop" then
				props[types.singleton(n)] = { read = i.ty }
			end
		end
		return types.newtable(props)
	elseif M == "readmap" then
		-- READ surface (OnChange/Out): ReadOnly kept (forRead), Q127 (a) rule — Instance-class property reads as `T?`
		local function isInstance(t: type): boolean
			local cur: type? = t
			while cur ~= nil and cur.tag == "extern" do
				if tostring(cur) == "Instance" then
					return true
				end
				cur = cur:readparent()
			end
			return false
		end
		local names, info = collect(cls, true)
		local props: { [type]: { read: type?, write: type? } } = {}
		for _, n in names do
			local i = info[n]
			if i.kind == "prop" then
				local ty = i.ty
				if isInstance(ty) then
					ty = types.optional(ty)
				end
				props[types.singleton(n)] = { read = ty }
			end
		end
		return types.newtable(props)
	elseif M == "rwreport" then
		-- M2: how does THIS checker expose ReadOnly vs writable props? One line per class.
		local list: { type } = if cls.tag == "union" then cls:components() else { cls }
		local watch = { "AbsoluteSize", "AbsolutePosition", "TextBounds", "ClassName", "Parent", "Size", "Text", "Visible" }
		local out: { string } = {}
		for _, c in list do
			local parts: { string } = {}
			for _, n in watch do
				local found = "-"
				for _, k in chainOf(c) do
					for key, v in k:properties() do
						if key:value() == n then
							found = (if v.read ~= nil then "r" else "") .. (if v.write ~= nil then "w" else "")
								.. (if v.read ~= nil and v.write ~= nil and v.read ~= v.write then "≠" else "")
							break
						end
					end
					if found ~= "-" then
						break
					end
				end
				parts[#parts + 1] = n .. "=" .. found
			end
			local w, r = 0, 0
			local wn, wi = collect(c, false)
			for _, n in wn do
				if wi[n].kind == "prop" then
					w += 1
				end
			end
			local rn, ri = collect(c, true)
			for _, n in rn do
				if ri[n].kind == "prop" then
					r += 1
				end
			end
			out[#out + 1] = tostring(c) .. " " .. table.concat(parts, ",") .. " write=" .. w .. " readProps=" .. r
		end
		print("[RW] " .. table.concat(out, "; "))
		return types.string
	elseif M == "brief" then
		local list: { type } = if cls.tag == "union" then cls:components() else { cls }
		local out: { string } = {}
		for _, c in list do
			local names, info = collect(c, false)
			local np, ne, ns = 0, 0, 0
			for _, n in names do
				local k = info[n].kind
				if k == "event" then ne += 1 elseif k == "shorthand" then ns += 1 else np += 1 end
			end
			local rn, ri = collect(c, true)
			local nr = 0
			for _, n in rn do
				if ri[n].kind == "prop" then nr += 1 end
			end
			out[#out + 1] = tostring(c) .. " " .. np .. "/" .. ne .. "/" .. ns .. " r" .. nr
		end
		print("[BRIEF2] " .. table.concat(out, "; "))
		return types.string
	end
	print("Build: unknown mode " .. tostring(M))
	return types.never
end

-- `{ As<C>: (self: any) -> M }` where M is an already-built Modifier<C> (no second build)
export type function IntoWith(cls: type, mod: type)
	local t = types.newtable()
	t:setproperty(types.singleton("As" .. tostring(cls)), types.newfunction({ head = { types.any } }, { head = { mod } }))
	return t
end

-- (라) thin Into taking an already-built Modifier<C>: tag (C and ancestors up to Instance) + As<C>
export type function IntoThinWith(cls: type, mod: type)
	local parts: { type } = {}
	local cur: type? = cls
	local d = 0
	while cur ~= nil and d < 16 do
		parts[#parts + 1] = types.singleton(tostring(cur))
		if tostring(cur) == "Instance" then
			break
		end
		cur = cur:readparent()
		d += 1
	end
	local t = types.newtable()
	t:setreadproperty(types.singleton("__quadModifier"), if #parts == 1 then parts[1] else types.unionof(table.unpack(parts)))
	t:setproperty(types.singleton("As" .. tostring(cls)), types.newfunction({ head = { types.any } }, { head = { mod } }))
	return t
end

-- ── public aliases ─────────────────────────────────────────────────────────
export type Props<C> = Build<"props", C, Policy>
export type MapperProps<C> = Build<"props", C, MapperPolicy>
export type Modifier<C> = Build<"modifier", C, Policy>
-- M3 variants (Policy.AsDepth knob)
export type PolicyAs0 = {
	Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsDepth: "0",
}
export type PolicyAs1 = {
	Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsDepth: "1",
}
export type ModifierAs0<C> = Build<"modifier", C, PolicyAs0>
export type ModifierAs1<C> = Build<"modifier", C, PolicyAs1>
export type ModifierIntoAs0<C> = IntoWith<C, ModifierAs0<C>>
export type ModifierIntoAs1<C> = IntoWith<C, ModifierAs1<C>>
export type ModifierInto<C> = IntoWith<C, Modifier<C>>
export type ModifierIntoSelfBuilt<C> = Build<"into", C, Policy>
export type PropsArrayItem<C> = Build<"elem", C, Policy>
export type Spread<C> = Build<"spreadmarker", C, Policy>
export type Events<C> = Build<"events", C, Policy>
export type WriteMap<C> = Build<"propmap", C, Policy>
export type ReadMap<C> = Build<"readmap", C, Policy>
export type RWReport<C> = Build<"rwreport", C, Policy>
export type Brief2<C> = Build<"brief", C, Policy>
-- K = the name (2026-10-19 decision: read fields); the name doubles as the tag the element's array part checks
export type OnChangeDescriptor<K> = { read __quadChange: K }
export type OnEventDescriptor<K> = { read __quadEvent: K }
export type ElemCtor<C> = (Props<C>) -> C

-- ── Lib3 (M3 follow-up) policies and policy-parameterised aliases ─────────────
-- ancestors of GuiObject (GuiBase2d/GuiBase/Instance) get GuiObject as their only checked down-cast, so those Modifiers still satisfy Into<GuiObject>
export type AsT2 = { GuiObject: { Frame: true, TextButton: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT4 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT3 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT5 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT6 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true, ImageLabel: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
-- T2 with the two biggest-surface GUI leaves instead (size vs count): TextBox + ScrollingFrame
export type AsT2big = { GuiObject: { TextBox: true, ScrollingFrame: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT7 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true, ImageLabel: true,
	ScrollingFrame: true }, GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type AsT10 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true, ImageLabel: true,
	ScrollingFrame: true, CanvasGroup: true, VideoFrame: true, ViewportFrame: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
-- all 12 GuiObject descendants of the 47 map, flat (GuiButton/GuiLabel themselves identity only)
export type AsT13 = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true, ImageLabel: true,
	ScrollingFrame: true, CanvasGroup: true, VideoFrame: true, ViewportFrame: true, GuiButton: true, GuiLabel: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
-- T13 + the second hop GuiButton/GuiLabel → their leaves (= Lib2's GuiObject subtree; ancestors still narrowed)
export type AsT13n = { GuiObject: { Frame: true, TextButton: true, TextLabel: true, TextBox: true, ImageButton: true, ImageLabel: true,
	ScrollingFrame: true, CanvasGroup: true, VideoFrame: true, ViewportFrame: true, GuiButton: true, GuiLabel: true },
	GuiButton: { TextButton: true, ImageButton: true }, GuiLabel: { TextLabel: true, ImageLabel: true },
	GuiBase2d: { GuiObject: true }, GuiBase: { GuiObject: true }, Instance: { GuiObject: true } }
export type PolicyFull = Policy
export type PolicyT2 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT2 }
export type PolicyT4 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT4 }
export type PolicyT3 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT3 }
export type PolicyT5 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT5 }
export type PolicyT6 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT6 }
export type PolicyT2big = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT2big }
export type PolicyT7 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT7 }
export type PolicyT10 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT10 }
export type PolicyT13 = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT13 }
export type PolicyT13n = { Deny: Deny, DenyWrite: DenyWrite, DenyIn: DenyIn, DenyWriteIn: {}, Inject: Inject, Shorthand: Shorthand,
	Child: NewChild, Classes: ModClassMap, AsTargets: AsT13n }
export type ModP<C, P> = Build<"modifier", C, P>
export type IntoP<C, P> = IntoWith<C, Build<"modifier", C, P>>
export type IntoThinP<C, P> = Build<"intothin", C, P>
export type IntoThinWithP<C, P> = IntoThinWith<C, Build<"modifier", C, P>>

type _Prime = Build<"classname", Frame, Policy>

return {}
