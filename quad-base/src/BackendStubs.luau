--!strict
--[[
	BackendStubs — the inventory of names a backend must install, and the one loop that puts a loud
	`Quad0108` stub on each until a provider overwrites it (round15 `H-929`, user 2026-10-20: "표에 추가만
	해두고 나중에 다루는거도 동의"). Started with the 3.4.0 top-level backend contract (`q.Elem` and friends —
	`.claude/research/declaration-surface-plan.md` 5절 "백엔드 계약"): base declares these names in no type
	(the backend's extension type carries them), only this runtime stub. The `Backend.*` ops still install their
	stubs in `LifetimeHandle.luau`/`Tag.luau`/`Attr/Key.luau`; moving them here is deferred (no BREAKING either way).
]]

local NotInstalled = require("./NotInstalled")

-- name -> what the stub says is missing
local TOP_LEVEL: { { name: string, what: string } } = {
	{ name = "Elem", what = "the element constructors (q.Elem)" },
	{ name = "Modifier", what = "the typed Modifier constructors (q.Modifier - the untyped one is q.Raw.Modifier)" },
	{ name = "Spread", what = "the typed Spread (q.Spread - the untyped one is q.Raw.Spread)" },
	{ name = "Mapper", what = "the typed mapper descriptors (q.Mapper - the untyped one is q.Raw.Mapper)" },
	{ name = "OnChange", what = "property-change descriptors (q.OnChange)" },
	{ name = "OnEvent", what = "event descriptors (q.OnEvent)" },
	{ name = "Out", what = "property write-back descriptors (q.Out)" },
	{ name = "ForClasses", what = "the typed surface over your own class map (q.ForClasses)" },
}

local function Init(module: any)
	for _, entry in TOP_LEVEL do
		if module[entry.name] == nil then -- a provider installed before Init keeps its value
			module[entry.name] = NotInstalled(entry.name, entry.what)
		end
	end
end

return Init
