--[[
	InstanceChildHandler — static child Instance at a NUMBER key
	(`Frame { Frame {} }`). Canon: `dispatch-core-plan.md`의 `H-134` 블록
	(다섯째 — 의사코드가 없던 핸들러를 사용자 확정으로 채운 자리)과
	`ROADMAP.md` M5 체크박스 — 이 파일은 그 두 줄의 1:1 전사다.

	Terminal handler ⇒ registers its array position without exception
	(`H-39`): constant length 1, no offset source, no 5th `element` argument
	(`H-145` — no persistent closure ever needs the lookup).

	process order (H-134 정정 (2) — 물리 먼저, `setLength` 나중):
	  setOffsetSource(inst, k, None) → v.Parent = inst → setLength(inst, k, 1, inst)
	retractor (release-order contract — offsetSource first so the recompute
	setLength's tail triggers cannot reach a dying source):
	  dedup guard (`H-154`) → v.Parent = nil → setOffsetSource(inst, k, None)
	  → setLength(inst, k, 0)
	The dedup guard (`if nextValue == v then return end`) folds
	`store.child:Set(store.child:Get())` from two physical detach/attach
	rounds into one engine no-op write — same shape as SlotHandler's
	early-return. The old child is DEMOTED, not destroyed
	(`slot-plan.md`의 "`State<Slot>` 교체는 파괴가 아니라 언마운트").

	`isInst`는 주입 술어(H-40 화이트리스트) — quad-roblox 실물은
	`typeof == "Instance"`, mock 환경의 spec은 그 술어 자리를 갈아 끼운다
	(그게 이 술어가 주입식인 이유 그 자체).
]]

local QuadTypes = require("../../luau_packages/quad_types")

local function install(quad: any)
	local dispatch = quad.Dispatch
	local None = quad.None

	dispatch.addHandler({
		name = "InstanceChild",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and quad.isInst(v) -- 늦은 읽기(H-174) — 술어는 갈아끼울 수 있는 주입면
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			dispatch.setOffsetSource(inst, k, None)
			v.Parent = inst -- 물리 먼저(H-134 정정 (2)) — setLength 꼬리의 recompute가 부착 후에 돌게
			dispatch.setLength(inst, k, 1, inst)
			return function(nextValue: any?, _retracting: boolean)
				if nextValue == v then
					return -- `H-154` 같은 값 재발행 dedup — 물리 detach/attach와 recompute 1회를 접는다
				end
				v.Parent = nil -- 내림(파괴 아님)
				dispatch.setOffsetSource(inst, k, None)
				dispatch.setLength(inst, k, 0)
			end
		end,
	} :: QuadTypes.Handler)
end

return install
