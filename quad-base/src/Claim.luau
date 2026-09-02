--[[
	`Claim(inst, descriptor) -> inst` — take ownership of an EXISTING tree
	(PlayerGui children, `template:Clone()` copies, Studio-authored GUI) and
	drive it like a quad-made one. Canon: `.claude/base/claim-plan.md` §2~§6
	verbatim; quad-base owns the traversal/bookkeeping and the provider hands
	only two ops (`nativeClaim`, `nativeFindChild` — user: "quad-base 에서
	전반을 구현해주고 필요 핸들을 구현하라고 남기는건 괜찮은 생각").

	Shape (§4 — a layer ON TOP of drive, handlers unchanged):
	  DFS down resolving mapper descriptors by key (`nativeFindChild`),
	  claim each resolved inst (`nativeClaim`, BEFORE its drive — same
	  reason `New`'s ② precedes ③④), drive children bottom-up, then the
	  parent. A resolved child's array slot is REPLACED by its Instance so
	  `InstanceChildHandler` sees a plain static child (§2 — the PreRef
	  "Processed sentinel" half of the idiom is deliberately NOT taken).

	Descriptors are one-shot (`_fired`, PreRef idiom) — reuse errors.
	Double claim = `nativeClaim`'s own setup-presence error (§7-10, no
	registry here). Name absence/duplication is UB (§3 — debug-mode checks
	are the debug tooling plan's, not ours).

	Agent-latitude picks recorded in round14 `H-303` (§9 said "구현 시 정할
	것" — all vetoable):
	  - user table mutated IN PLACE (a fresh table would shift
	    ProcessedModifier slots/indices away from `New`'s — the §2 caveat
	    that motivated the choice);
	  - descriptors hidden inside Modifier FIELDS are not visited by the
	    DFS (flatten-consumed fields don't exist before M7 anyway — M7's
	    flatten integration owns that seam, see also the flatten note);
	  - `flatten` is D-internal (provider) so this path calls `drive`
	    directly — identical while flatten is the identity (M5); wiring
	    Modifier consumption into the Claim path is M7's seam;
	  - generic descriptor factory `newMapperClass(className)` + root
	    sentinel `MapperRoot` live HERE (base) and `D.Mapper` re-exposes
	    them as cast aliases / `D.Mapper.Root` (the confirmed user surface).
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- root key sentinel — the value; `D.Mapper.Root` re-exposes it (claim-plan §7-1)
local MapperRoot = table.freeze(setmetatable({ __quadMapperRoot = true :: true }, {
	__tostring = function()
		return "MapperRoot"
	end,
}))

local function Init(module: any)
	local Err = module.errorNamespace

	-- (className)(key)(props) -> descriptor. `D.Mapper.<Class>`는 이 커링에
	-- 캐스트만 얹은 생성기 산출물(별칭) — `D.<Class>`와 `New`의 관계 동형.
	local function newMapperClass(className: string): (key: any) -> (props: any) -> any
		local function keyed(key: any): (props: any) -> any
			local function staged(props: any): any
				local desc = {
					_mapper = true :: true, -- 타입 마커(H-300 (a) 선례 — 판별은 브랜드)
					_className = className,
					_key = key,
					_props = props,
					_fired = false,
				}
				Brand.MapperBrand:register(desc)
				return desc
			end
			Err.setFuncLevel(staged, SURFACE)
			return staged
		end
		Err.setFuncLevel(keyed, SURFACE)
		return keyed
	end

	-- DFS 해석 + bottom-up drive (claim-plan §4)
	local function resolve(inst: any, desc: any)
		if desc._fired then
			Err.errorBefore("Claim: mapper descriptor was already used (descriptors are one-shot)", SURFACE)
		end
		desc._fired = true
		module.nativeClaim(inst) -- 소유 먼저 — 이 아래부터 inst-키 Relate가 생긴다(§7-9)
		local props = desc._props
		-- `drive`와 같은 일반화 순회(H-304) — `ipairs`는 nil 구멍에서 멈춰
		-- 구멍 뒤의 디스크립터가 미해석으로 drive에 새는 순회 불일치를 만든다
		-- (감사 발견). 구멍 자체는 기존 관용구(`or None`)의 몫 — 여기선
		-- drive가 보는 모든 배열 자리를 똑같이 본다.
		for i, v in props :: { [any]: any } do
			if type(i) == "number" and Brand.isMapperDescriptor(v) then
				-- 이름 부재·중복은 UB(§3 — debug 검사는 debug 도구 몫):
				-- nativeFindChild가 nil을 주면 아래 재귀가 자연 크래시한다
				local child = module.nativeFindChild(inst, v._key)
				resolve(child, v)
				props[i] = child -- 해석된 Instance로 교체 — InstanceChildHandler가 그대로 받는다(§2/§4)
			end
		end
		module.Dispatch.drive(inst, props)
	end

	local function Claim(inst: any, desc: any): any
		if not Brand.isMapperDescriptor(desc) then
			Err.errorBefore("Claim: second argument must be a D.Mapper descriptor", SURFACE)
		end
		resolve(inst, desc)
		return inst
	end

	module.Claim = Claim
	module.MapperRoot = MapperRoot
	module.newMapperClass = newMapperClass
	-- isMapperDescriptor는 init.luau 리터럴이 단일 소유(리뷰 — 이중 대입 제거)
	for _, fn in { Claim, newMapperClass } :: { any } do
		Err.setFuncLevel(fn, SURFACE)
	end
end

return Init
