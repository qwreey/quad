--!strict
-- [2026-10-20 kit trial] q = Omit<Quad, "Modifier"> & Ext4 — the backend contract (Elem·Spread·Modifier·Mapper·OnChange·
-- OnEvent·Out) typed by Lib4, plus the non-Declaration members of today's `RobloxExtension` (Animate·Tween·isTween).
-- Same merge as round 1 `qmerge/Ext.luau` / round 2 `qtypeof/Ext2.luau`; differences:
--   * base `Modifier` would be dropped from the Quad half (2026-10-16 decision) — see the note at `Q`: not possible from
--     outside quad-types, so the intersection keeps both (`q.Raw` is out of this trial);
--   * quad_types is the copy the kits use (`quad-roblox/luau_packages/quad_types`), so `q.State`/`q.Source` keep one identity;
--   * classes first everywhere: `Elem "Frame"`, `Modifier "Frame"`, `Spread "Frame"`, `Mapper "Frame"`,
--     `OnChange "Frame" "Visible" (fn)`, `OnEvent "Frame" "MouseEnter" (fn)`, `Out "Frame" "AbsoluteSize" (src)`.
-- Path layout: this file sits at the same relative place in the scratch mirror (`kit-trial/new/…`) as in the repo.
local QT = require("../../../../../../quad-roblox/luau_packages/quad_types")
local RT = require("../../../../../../quad-roblox/src/types")
local L = require("../../../src/Lib4")

type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>

-- table copy without the named keys (read/write halves kept)
type function OmitKeys(t: type, keys: type)
	local drop: { [any]: boolean } = {}
	if keys.tag == "singleton" then
		drop[keys:value()] = true
	elseif keys.tag == "union" then
		for _, c in keys:components() do
			drop[c:value()] = true
		end
	end
	local out = types.newtable()
	for k, v in t:properties() do
		if not drop[k:value()] then
			if v.read ~= nil and v.write ~= nil and v.read == v.write then
				out:setproperty(k, v.read)
			else
				if v.read ~= nil then
					out:setreadproperty(k, v.read)
				end
				if v.write ~= nil then
					out:setwriteproperty(k, v.write)
				end
			end
		end
	end
	return out
end

-- full Spread value (`:Add` accumulates); elements take it through the `__quadSpread` tag arm
export type Spread<C> = { read __quadSpread: L.Build<"classname", C, L.Policy>, Add: (self: Spread<C>, props: L.Props<C>) -> Spread<C> }

export type Ext = {
	Elem: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>,
	Spread: <K>(name: K & keyof<L.ModClassMap>) -> (L.Props<CM<K>>) -> Spread<CM<K>>,
	Modifier: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.Modifier<CM<K>>,
	Mapper: <K>(name: K & keyof<L.CreatableMap>) -> (key: string | QT.MapperRoot) -> (L.MapperProps<EM<K>>) -> L.MapperDescriptor,
	OnChange: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (fn: (index<L.ReadMap<CM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>,
	OnEvent: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.Events<CM<C0>>>) -> (fn: index<L.Events<CM<C0>>, K>) -> L.OnEventDescriptor<K>,
	Out: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (src: QT.Source<index<L.ReadMap<CM<C0>>, K>>) -> L.OnChangeDescriptor<K>,
	-- today's RobloxExtension members outside Declaration
	Animate: RT.AnimateFn,
	Tween: RT.TweenConstructor,
	isTween: (x: any) -> boolean,
}
-- [measured 2026-10-20] `OmitKeys<QT.Quad, "Modifier">` cannot run: a Quad member's type has the form
-- `CheckReservedKeys<keyof<T>>`, which type functions cannot take ("Type functions do not currently support types of
-- the form …") — q collapses. So the round-1 plain intersection stays: `q.Modifier` is base & typed (round 1 showed
-- `q.Modifier "Frame"` resolves to the typed member). Removing base `Modifier` is a quad-types edit (3.4.0 itself).
export type Q = QT.Quad & Ext

-- type surface re-exported by the kit setup module (`Quad.luau`)
export type Modifier<C> = L.Modifier<C>
export type ModifierInto<C> = L.ModifierInto<C>
export type Props<C> = L.Props<C>
export type PropsArrayItem<C> = L.PropsArrayItem<C>
export type ElemCtor<C> = L.ElemCtor<C>
export type MapperProps<C> = L.MapperProps<C>
export type OnChangeDescriptor<K> = L.OnChangeDescriptor<K>
export type OnEventDescriptor<K> = L.OnEventDescriptor<K>
return {}
