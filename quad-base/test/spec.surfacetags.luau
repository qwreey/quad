--!strict
--[[
	Public-surface tagging (round15 `H-905`): every public function of the module and of its values carries the
	SURFACE tag (`Err.setFuncLevel`), so a raise inside it blames the user's line. The tags are hand-listed in
	about forty places; a new method that forgets its tag fails nothing else — blame just lands in a quad file.
	The walk is over the live tables (a hand list here would drift the same way). Exempt, with why:
	  - `q.is*` predicates and the brand sets' `Is`/`Register` (quad-types' factory): pure, they never raise.
	  - `q.errorNamespace`: the tagging mechanism itself.
	  - `q.Relate`: a dependency-free leaf whose plain errors blame the caller by level (`Relate.luau` `checkArgs`: no quad-error tag).
	  - `q.Void`: a no-op.
	  - `q.NewModule`: makes a module, raises nothing.
	  - `Observer:new`: the internal constructor sitting on the method table; users reach it only through the
	    tagged `state:Observer(fn)`, which is where a raise inside it blames.
	quad-roblox's own surface: `quad-roblox/test/spec.surfacetags.luau`.
]]

local mock = require("./mock")

local q: any = mock.newQuad()

local exempt: { [string]: boolean } = {
	["q.Relate"] = true,
	["q.Void"] = true,
	["q.NewModule"] = true,
	["q.BrandPredicates.Is"] = true,
	["q.BrandPredicates.Register"] = true,
	["q.Protocols.DispatchHint.Is"] = true,
	["q.Protocols.DispatchHint.Register"] = true,
	["q.errorNamespace"] = true,
	["q.Backend"] = true, -- the provider's ops, tagged by whoever installs them (the mock here)
	["Observer:new"] = true,
}
for k in next, q do
	if type(k) == "string" and string.sub(k, 1, 2) == "is" then
		exempt["q." .. k] = true
	end
end

print("=== 1. 모듈 표면과 값의 메소드가 전부 SURFACE 태그 ===")
do
	local source = q.Source(1)
	local values: { [string]: any } = {
		Source = source,
		State = source:Compute(function(self: any)
			return 1
		end),
		Slot = q.Slot(),
		Effect = q.Effect(function() end),
		Observer = source:Observer(function() end),
		Ref = q.Ref(),
		Tag = q.Tag("a"),
		Attr = q.Attr({}),
		Spread = q.Raw.Spread({}),
		Context = q.Context(),
		Store = q.Store({ a = q.Source(1) }),
		Blocker = q.Blocker(),
	}
	local untagged = mock.untaggedSurface(q, values, exempt)
	assert(#untagged == 0, "untagged public functions (add them to their setFuncLevel call): " .. table.concat(untagged, ", "))
	print("PASS")
end

print()
print("=== 2. 검사기 자체 — 태그를 빠뜨린 함수를 실제로 잡는다 ===")
do
	local probe: any = { Fresh = function() end }
	local untagged = mock.untaggedSurface({ errorNamespace = q.errorNamespace, Probe = probe }, {}, { ["q.errorNamespace"] = true })
	assert(#untagged == 1 and untagged[1] == "q.Probe.Fresh", "an untagged function is reported: " .. table.concat(untagged, ", "))
	print("PASS")
end
