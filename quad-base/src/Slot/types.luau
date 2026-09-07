--!strict
--[[
	Slot internal surface type — the shape of the table `S` that `Slot/init.luau` builds and
	passes to every sibling (`function(S, module)`). Internal implementation type, so it lives
	here in quad-base (user decision 2026-09-07, round3 §9 Q29: *"내부 구현은 quad-base 에 두고,
	외부로 나가는 구현만 types 에 있는거 끌어다 쓰는게 내 생각"*) — quad-types carries only the
	public contract. Siblings read `S.x` directly everywhere (no per-file re-captures), so a
	typo'd name or a wrong arity is a type error instead of a nil call at runtime.

	Prelude values are set by init BEFORE any sibling is installed. Function fields are
	published by the sibling that defines them (`S.name = name` at its end); two are
	published by init AFTER the installs (`assertLive`, `Slot`) — a sibling may call them
	inside a function body, never read them at install time. Backend-injected primitives
	(`bindLifetime`/`unbindLifetime`/`isInst`, `native*`) are NOT on `S`: they are read
	off `module` at call time (`H-174` — no wrapper, no capture; a hashed field read is
	cheap and every other module already does it inline).
]]

export type SlotInternal = {
	-- prelude (init, before installs)
	Slot_mt: any,
	BK: any,
	None: any,
	isState: (any) -> boolean,
	isSlot: (any) -> boolean,
	elementOwner: any,
	OWNER: string,
	OWNER_POS: string,
	ZOMBIE_NOTE: string,
	Err: any,
	SURFACE: number,
	Detach: any,
	KeyGone: any,
	-- Owner.luau
	claimOwner: (element: any, ownerKey: any, fromDetached: boolean?) -> (),
	claimOwnerAt: (element: any, inst: any, k: any) -> boolean,
	releaseOwner: (element: any, ownerKey: any) -> (),
	-- Elements.luau
	destroyElement: (element: any) -> (),
	wrapElement: (v: any, raise: (string, any) -> ()) -> any,
	unwrapElement: (el: any) -> any,
	collectLeaves: (slot: any, out: { any }?) -> { any },
	leavesOf: (element: any) -> { any },
	-- Raw.luau
	maybeRecompute: (self: any, bk: any) -> (),
	rawAdd: (self: any, element: any, index: number?, fromDetached: boolean?, deferPhysical: boolean?) -> number,
	rawRemove: (self: any, index: number) -> (),
	rawUnmount: (self: any, index: number, deferPhysical: boolean?) -> (),
	rawDetach: (self: any, index: number) -> (),
	rawReplace: (self: any, index: number, newElement: any, destroyOld: boolean) -> (),
	rawMove: (self: any, fromIndex: number, toIndex: number) -> (),
	rawSwap: (self: any, indexA: number, indexB: number) -> (),
	rawSplice: (self: any, index: number, removeCount: number, newElements: { any }) -> { any },
	releaseElement: (self: any, index: number?, element: any, wasDetached: boolean) -> (),
	indexOfRaw: (self: any, element: any) -> number?,
	getDetached: (self: any) -> any,
	-- Tree.luau
	makeBaseObserver: (slot: any) -> any,
	markMountedTree: (slot: any, physicalTarget: any) -> (),
	attachSlot: (slot: any, physicalTarget: any, ownerKey: any, position: number, mount: boolean?) -> (),
	releaseSugarWrapper: (wrapper: any) -> (),
	teardownTree: (slot: any) -> (),
	unmountSlotTree: (slot: any) -> (),
	destroySlotTree: (slot: any) -> (),
	-- List.luau
	List: (self: any, data: any, updateFn: any, keyFn: any?, opts: any?) -> any,
	Single: (self: any, state: any, updateFn: any?, opts: any?) -> any,
	-- init.luau (published AFTER the installs)
	assertLive: (self: any) -> (),
	Slot: (initial: { any }?) -> any,
}

return {}
