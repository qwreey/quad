--[[
	Per-instance implementation registry access (`H-174`/`H-181`) — the one
	copy of `implsOf`, shared by `State.luau`/`Observer.luau`/`Effect.luau`
	(`H-206`: three verbatim copies risked forking the registry scheme).
	Dependency-free LEAF module, shared across quad instances like `Ref`: it
	holds no state of its own — pure access to the `module` it is handed (the
	sharing `conventions.md`'s heterogeneous-bodies principle explicitly
	permits; bodies with per-type tails stay separate).

	Impls live ON the module instance (`module._impl`, private — the `H-174`
	(a) form: "RunInit 뒤의 비공개 필드로 형제 Init에 넘김"). A weak-key map
	keyed by `module` would never collect: the impl's closures capture
	`module`, and Luau has no ephemerons (`relate-plan.md`), so every
	`Quad.New()` would be pinned (`H-181`).
]]

local function implsOf(module: any): { [string]: any }
	local impls = rawget(module, "_impl")
	if impls == nil then
		impls = {}
		rawset(module, "_impl", impls)
	end
	return impls
end

return {
	implsOf = implsOf,
}
