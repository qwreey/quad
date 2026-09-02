--[[
	PropertyHandler — the plain-property terminal handler (backend-owned:
	Reflection is an engine concept, `dispatch-core-plan.md` "base가 소유하는
	핸들러와 주입되는 엔진 op" 절).

	Match rule: string key ∧ key ~= "Parent" (`H-142` — the rejection IS the
	runtime guard: no handler matches, so `Dispatch.process` raises its
	regular no-match error; no special wording, `H-148`) ∧ the key is a real
	property of `inst.ClassName` per `ReflectionService:GetPropertiesOfClass`
	(descriptor array with `.Name`, inherited included — Studio-measured
	2026-09-02). Event keys are NOT properties in that API, so they fall
	through — their handler arrives in M10 (`Handlers/Event.luau`); until
	then an event key raises the regular no-match error instead of silently
	assigning a callback onto a signal.

	process is one line (`inst[k] = v`) — hash keys touch no Length/Offset
	bookkeeping (`H-39` is about ARRAY positions only). The retractor is
	`Void`: a property cannot be "unset", and a descending-diff replacement
	simply writes the next value. Deferred by canon:
	  - `v == nil` skip-defense — `dispatch-core-plan.md` explicitly defers
	    it to M9/M10 ("PropertyHandler 구현 디테일, M9/M10로 미룸").
	  - `isTween(realv)` branch + 3-state relation slot — M11
	    (`tween-plan.md`); this file grows that branch then.

	The `game` global is read lazily inside the cache miss path so the CLI
	spec can substitute a Reflection shim via `getfenv` (same seam the D
	pipeline spec uses for `Instance`).
]]

local QuadTypes = require("../../luau_packages/quad_types")

local function install(quad: any)
	local dispatch = quad.Dispatch
	local Void = quad.Void

	-- className -> { [propName]: true } (inherited included — one Reflection
	-- call per class, cached for the module's lifetime)
	local propsOf: { [string]: { [string]: boolean } } = {}

	local function isPropertyOf(className: string, key: string): boolean
		local set = propsOf[className]
		if set == nil then
			set = {}
			local descriptors = game:GetService("ReflectionService"):GetPropertiesOfClass(className)
			for _, d in descriptors :: { any } do
				-- `H-302`(리뷰 발견, `H-297` (a)의 런타임판): 쓰기 표면만 매치 —
				-- 읽기 전용(AbsoluteSize 등)은 `Permits.Write` 키 자체가 없다
				-- (Studio 실측 2026-09-02). 걸러두지 않으면 대입이 h.process
				-- 한가운데서 엔진 원시 에러를 내고 `H-103` NOOP 마커가 고착된다.
				if d.Permits ~= nil and d.Permits.Write ~= nil then
					set[d.Name] = true
				end
			end
			propsOf[className] = set
		end
		return set[key] == true
	end

	dispatch.addHandler({
		name = "Property",
		isHandlable = function(inst: any, k: any, _v: any): boolean
			return type(k) == "string" and k ~= "Parent" and isPropertyOf(inst.ClassName, k)
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			inst[k] = v
			return Void
		end,
	} :: QuadTypes.Handler)
end

return install
