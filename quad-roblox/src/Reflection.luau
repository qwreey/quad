--!strict
--[[
	`memberSet(fetch, accept?)` — the className → { [memberName]: true } cache
	both Reflection-backed handlers keep (`Handlers/Property.luau`
	GetPropertiesOfClass, `Handlers/Event.luau` GetEventsOfClass): one
	Reflection call per class, cached for the module's lifetime, inherited
	members included. One body for the two hand copies (post-implementation
	review Q3 ④, user: "공통으로 두는건 아주 싸긴 해서 … 딱히 부작용도 없을듯").

	`fetch(className)` is a caller closure ON PURPOSE: the `game` read stays in
	the handler's own chunk, so the CLI specs' `getfenv(install<Handler>).game`
	shim seam (spec.claim etc.) keeps working — this module never touches
	`game`. `accept(descriptor)` filters (Property: `H-302` write surface only).
]]

local function memberSet(fetch: (string) -> { any }, accept: ((any) -> boolean)?): (string, string) -> boolean
	local sets: { [string]: { [string]: boolean } } = {}
	local acceptFn: (any) -> boolean = accept or function(_: any): boolean
		return true
	end
	return function(className: string, key: string): boolean
		local set = sets[className]
		if set == nil then
			set = {}
			for _, d in fetch(className) do
				if acceptFn(d) then
					set[d.Name] = true
				end
			end
			sets[className] = set
		end
		return set[key] == true
	end
end

return { memberSet = memberSet }
