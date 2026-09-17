--!strict
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
	    DFS (a Modifier is a property bag — a descriptor in a field is a
	    misuse, and flatten only merges fields into the hash part);
	  - [2026-09-04 M7 단위 ② — seam closed] flatten is owned by
	    `Dispatch.drive` (round17 §0 Q4 (a)), so this path gets Modifier
	    consumption for free by calling `drive` — nothing Claim-specific;
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
				Brand.MapperBrand:Register(desc)
				return desc
			end
			Err.setFuncLevel(SURFACE, staged)
			return staged
		end
		Err.setFuncLevel(SURFACE, keyed)
		return keyed
	end

	-- DFS 해석 + bottom-up drive (claim-plan §4) — TWO passes (round11 `H-539`, the residue
	-- round10 §5 carried over): pass 1 resolves the whole tree WITHOUT touching anything
	-- (`_fired`/props/`nativeFindChild` checks only — the `H-30`/`H-31` pre-pass rule: a
	-- multi-element op validates everything before it mutates), pass 2 claims + drives
	-- bottom-up. Before, `nativeClaim(root)` ran before its children were even looked up, so
	-- a missing/wrong-class child left root (and every earlier sibling) claimed and a fixed
	-- retry died on "already claimed" instead of the real cause — the very shape `H-425`/
	-- `H-471` had already fixed for the props gate. What remains non-atomic is the drive
	-- itself (a handler throw mid-tree): that is the Declaration's general mid-throw UB.
	type Step = { inst: any, desc: any, children: { [number]: any } }
	local function resolve(inst: any, desc: any, plan: { Step }, seen: { [any]: boolean })
		if desc._fired or seen[desc] then -- `seen`: the same descriptor at two slots of one tree
			Err.errorBefore("Claim: mapper descriptor was already used (descriptors are one-shot)", SURFACE)
		end
		seen[desc] = true
		-- 7순회 `H-425` (`H-256` (a) third site): a non-table props used to die in the
		-- `for` below AFTER `nativeClaim`/`_fired` were committed — a fixed retry then
		-- hit "already claimed". `drive`'s own gate (`H-419`) comes too late for Claim.
		if type(desc._props) ~= "table" then
			Err.errorBefore(`Claim: mapper props must be a table (got {typeof(desc._props)})`, SURFACE)
		end
		-- `drive`와 같은 일반화 순회(H-304) — `ipairs`는 nil 구멍에서 멈춰
		-- 구멍 뒤의 디스크립터가 미해석으로 drive에 새는 순회 불일치를 만든다
		-- (감사 발견). 구멍 자체는 기존 관용구(`or None`)의 몫 — 여기선
		-- drive가 보는 모든 배열 자리를 똑같이 본다.
		local children: { [number]: any } = {}
		for i, v in desc._props :: { [any]: any } do
			if type(i) == "number" and Brand.isMapperDescriptor(v) then
				-- 이름 중복은 UB(§3 — debug 검사는 debug 도구 몫). 부재는 [2026-09-16 hunt C] fail-fast:
				-- 옛 "자연 크래시"는 `LifetimeHandle.luau:59: Relate:GetWeak: inst must not be nil`로 죽어
				-- 키도 주체도 안 보였다(`H-418`/`H-442`/`H-504`와 같은 leaf-message 부류).
				-- round10 G-5 (§7-1 debug check): a non-string key (M.Root in a child slot, a number) is
				-- backend-defined — Roblox's FindFirstChild raises its own error on it
				if module.debug and type(v._key) ~= "string" then
					print(`Claim: child descriptor key is a {typeof(v._key)} — M.Root is only for the root descriptor; a child key is a name`)
				end
				-- round10 Q49 (a) (user decision 2026-09-17): the descriptor's class goes to the backend —
				-- a same-name child of another class is "not matched" (Roblox: `IsA`; mock: ClassName)
				local child = module.Backend.nativeFindChild(inst, v._key, v._className)
				if child == nil then
					Err.errorBefore(`Claim: no child matched key {tostring(v._key)} under {tostring(inst)} (mapper {tostring(v._className)}) — a child with that name must also be a {tostring(v._className)}`, SURFACE)
				end
				resolve(child, v, plan, seen)
				children[i] = child
			end
		end
		table.insert(plan, { inst = inst, desc = desc, children = children }) -- children first: the drive order is bottom-up
	end

	local function commit(plan: { Step })
		for _, step in plan do
			local inst, desc = step.inst, step.desc
			module.Backend.nativeClaim(inst) -- 소유 먼저 — 이 아래부터 inst-키 Relate가 생긴다(§7-9)
			-- `H-471` (탐사 A, `H-425`의 잔여): consume the descriptor only once the claim is ours —
			-- a nativeClaim raise (already claimed) used to burn it first, so the retry reported
			-- "already used" instead of the real cause
			desc._fired = true
			local props = desc._props
			for i, child in step.children do
				-- 해석된 Instance로 교체 — InstanceChildHandler가 그대로 받는다(§2/§4). The child was
				-- claimed and driven by an earlier step (bottom-up).
				props[i] = child
			end
			module.Dispatch.drive(inst, props)
		end
	end

	local function Claim(inst: any, desc: any): any
		-- `H-418` (외부 리뷰 G-06): the first argument was never checked — a nil or
		-- non-Instance reached the backend's `nativeClaim`, whose first line indexes
		-- it (raw VM error blaming `LifetimeHandle.luau`). `isInst` is the backend's
		-- own predicate (the base stub raises a clear "not installed" error).
		if not module.Backend.isInst(inst) then
			Err.errorBefore(`Claim: first argument must be an Instance of the installed backend (got {typeof(inst)})`, SURFACE)
		end
		if not Brand.isMapperDescriptor(desc) then
			Err.errorBefore("Claim: second argument must be a D.Mapper descriptor", SURFACE)
		end
		-- round10 G-4 (claim-plan §7-1: a DEBUG check, not a runtime guard — §3 principle): the root
		-- descriptor's key is never read, so `M.Frame("SomeName")` at the root claims `inst` itself
		if module.debug and desc._key ~= MapperRoot then
			print(`Claim: the root descriptor's key {tostring(desc._key)} is ignored — the root takes M.Root; put a keyed descriptor in the root's props instead`)
		end
		local plan: { Step } = {}
		resolve(inst, desc, plan, {})
		commit(plan)
		return inst
	end

	module.Claim = Claim
	module.MapperRoot = MapperRoot
	module.newMapperClass = newMapperClass
	-- isMapperDescriptor는 init.luau 리터럴이 단일 소유(리뷰 — 이중 대입 제거)
	Err.setFuncLevel(SURFACE, Claim, newMapperClass)
end

return Init
