--!strict
--[[
	Debug-only string-key filter factory (round13 Q135 follow-up, user decision 2026-10-01 —
	field name `debugOnly`; prototype and measurements in `.claude/audit/round13-fordebug-proto/`).

	Round13 Q135: an array-only quad value (Ref family, Observer, Effect, Slot, Tag, Attr) placed at a
	string key that names a real property is taken by the NORMAL Property handler (or the NORMAL + 1
	shorthand) before its own FALLBACK guard can see it — silently assigned, or an engine error.
	Strict typing is the first defense (round1 Q4 (a)); this is the debug layer
	(`architecture.md` "debug 층"): a `debugOnly` handler between NORMAL + 1 and HIGH that prints one
	line and answers `false`, so the scan goes on exactly as without it — behavior and the FALLBACK
	override contract unchanged, and production never scans it (Dispatch keeps it out of the
	production buckets).

	Brand knowledge stays with each owning module (`H-278`): the caller passes `kindOf(v)` — the
	subject name to print, or nil when the value is not its kind. This file only shapes the handler.

	`isHandlable` is NOT pure here (it prints) — the one exception `debugOnly` handlers get.
	Repeat suppression: once per (inst, key) per filter (weak on inst) — an emitting State would
	otherwise print on every emit.
]]

local QuadTypes = require("../luau_packages/quad_types")
local Void = require("./Void")

-- the tight lower bound: above Property (NORMAL) and InstanceShorthand (NORMAL + 1), the two
-- built-in handlers that swallow a quad value at a property-name key; Event (NORMAL - 1) is below
local PRIORITY_OFFSET = 2

local function register(dispatch: QuadTypes.Dispatch, name: string, kindOf: (v: any) -> string?)
	local warned: { [any]: { [string]: true } } = setmetatable({}, { __mode = "k" }) :: any
	dispatch.addHandler({
		name = name,
		debugOnly = true,
		keyType = "string", -- number keys are where these values belong; never inspected
		priority = dispatch.HANDLER_PRIORITY_NORMAL + PRIORITY_OFFSET,
		isHandlable = function(inst: any, k: any, v: any): boolean
			if type(v) ~= "table" then
				return false -- every kind checked here is a table; most property values are not
			end
			local kind = kindOf(v)
			if kind == nil then
				return false
			end
			local seen = warned[inst]
			if seen == nil then
				seen = {}
				warned[inst] = seen
			end
			if seen[k] == nil then
				seen[k] = true
				print(`{kind}: found at string key "{k}" - must be an array item (a string key hands it to whichever handler takes that key, usually the property of that name)`)
			end
			return false -- never selected: the dispatch continues as if this handler did not exist
		end,
		process = function(_inst: any, _k: any, _v: any, _index: number): (any?, boolean) -> ()
			return Void -- unreachable (isHandlable is always false)
		end,
	})
end

return { register = register }
