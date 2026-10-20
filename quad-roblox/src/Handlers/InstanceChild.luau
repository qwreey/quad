--!strict
--[[
	InstanceChildHandler — static child Instance at a NUMBER key
	(`Frame { Frame {} }`). Canon: `dispatch-core-plan.md`의 `H-134` 블록
	(다섯째 — 의사코드가 없던 핸들러를 사용자 확정으로 채운 자리)과
	`ROADMAP.md` M5 체크박스에서 출발했고, 그 뒤 결정(ownership seat 등록,
	이미 부모가 있는 Instance 거부 등)이 아래에 붙었다.

	Terminal handler ⇒ registers its array position without exception
	(`H-39`): constant length 1, no offset source, no 5th `element` argument
	(`H-145` — no persistent closure ever needs the lookup).

	process order (H-134 정정 (2) — 물리 먼저, `setLength` 나중):
	  setOffsetSource(inst, k, None) → v.Parent = inst → setLength(inst, k, 1, inst)
	retractor (release-order contract — offsetSource first so the recompute
	setLength's tail triggers cannot reach a dying source):
	  dedup guard (`H-154`) → v.Parent = nil → setEmpty(inst, k)
	  (= setOffsetSource(inst, k, None) → setLength(inst, k, 0), one body)
	The dedup guard (`if nextValue == v then return end`) folds
	`store.child:Set(store.child:Get())` from two physical detach/attach
	rounds into one engine no-op write — same shape as SlotHandler's
	early-return. The old child is DEMOTED, not destroyed
	(`slot-plan.md`의 "`State<Slot>` 교체는 파괴가 아니라 언마운트").

	[2026-09-16] `isClaimed` gate before the bookkeeping — same rule as the Slot element
	gate (`claim-plan.md` 14번): a static child must already be quad-owned.
	[2026-09-17 round10 Q48 (a) — user decision] ownership seat in the SAME registry the
	Slot paths use: `Bookkeeping.claimOwnerAt(v, inst, k)` before the bookkeeping,
	`releaseOwner(v, inst)` in the retractor. A child already held elsewhere (another
	static seat, a Slot, `q.Elem "Frame" { c, c }`) is refused instead of silently re-parented,
	and `q.dispose(c)` refuses it while it sits here. `claimOwnerAt` returning false means
	exactly this seat already holds it — only reachable through the `H-154` dedup path,
	which returns before releasing, so the physical attach is skipped too.

	`isInst`는 주입 술어(H-40 화이트리스트) — quad-roblox 실물은
	`typeof == "Instance"`, mock 환경의 spec은 그 술어 자리를 갈아 끼운다
	(그게 이 술어가 주입식인 이유 그 자체).
]]

local QuadTypes = require("../../luau_packages/quad_types")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- ── debug-only checks (quad-base `architecture.md` "debug 층"; kept out of the logic below) ──
-- round11 `H-545` (탐사 A′): the static seat's twin of Slot's `H-500` cycle guard — `src:Set(host)`
-- would make `host.Parent == host`. Walk the ancestor chain: O(1) on the element-constructor path (Parent is
-- nil at creation), O(D) on a State swap with `inst` at depth D (round11 L′ 5: +17µs at D=256).
-- [2026-10-01 user decision — "순환 가드는 … 같은 결정을 따라가자. debug 로 내리기에 동의해"] the walk runs
-- only with `q.debug` on. With it off the engine's own "circular reference" raise at `v.Parent = inst`
-- stops the cycle, AFTER the seat / offset commit — bookkeeping integrity after a throw is not
-- promised (architecture "예외 안전성 계약", round3 Q18 (c)). errorBefore blames the user's line.
local function checkNotOwnAncestor(Err: any, inst: any, v: any)
	local ancestor = inst
	while ancestor ~= nil do
		if ancestor == v then
			Err.errorBefore("Quad0220 Dispatch: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)", SURFACE)
		end
		ancestor = ancestor.Parent
	end
end

local function install(quad: any)
	local dispatch = quad.Dispatch
	local None = quad.None
	local Err = quad.errorNamespace

	dispatch.addHandler({
		name = "InstanceChild",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- positive integer only (checkpoint code-review, `H-52` family): `drive` already rejects
			-- other keys, but the public `Dispatch.process(inst, 0, v, 1)` does not — the seat
			-- (`claimOwnerAt`) committed before `checkPosition` threw and stayed for good
			return type(k) == "number" and k >= 1 and k % 1 == 0 and quad.Backend.isInst(v) -- 늦은 읽기(H-174) — 술어는 갈아끼울 수 있는 주입면
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- [2026-09-16 사용자 결정 — question.md §2, Slot 게이트와 대칭] a child quad does not own
			-- (never claimed: `Instance.new`, another library's tree) is rejected before any
			-- bookkeeping — otherwise its death outside quad leaves a length-1 entry pointing at a
			-- corpse. Ownership starts explicitly: `Claim` or `q.Elem`. errorBefore so the
			-- blame lands on the user's `D.<Class> { … }` line (dispatch depth, `H-330`).
			-- round13 Q90 ① (user decision 2026-09-28): subject `Dispatch:` for 0219/0220, as `Quad0076` —
			-- the handler name is not a user surface and the entry (`D.<Class>{…}`, `drive`, `Claim`, a seat
			-- State) is unknown here; the blame line says where the user entered (round8 O-1).
			if not quad.Backend.isClaimed(v) then
				Err.errorBefore("Quad0219 Dispatch: this Instance is not claimed by quad - build it with q.Elem or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)", SURFACE)
			end
			if quad.debug then
				checkNotOwnAncestor(Err, inst, v) -- `H-545` cycle guard (debug-only, see above)
			end
			if quad.Bookkeeping.claimOwnerAt(v, inst, k) then -- Q48 (a): one seat per value — raises if held elsewhere
				quad.Bookkeeping.setOffsetSource(inst, k, None)
				v.Parent = inst -- 물리 먼저(H-134 정정 (2)) — setLength 꼬리의 recompute가 부착 후에 돌게
				quad.Bookkeeping.setLength(inst, k, 1, inst)
			end
			return function(nextValue: any?, _retracting: boolean)
				if nextValue == v then
					return -- `H-154` 같은 값 재발행 dedup — 물리 detach/attach와 recompute 1회를 접는다
				end
				v.Parent = nil -- 내림(파괴 아님)
				quad.Bookkeeping.setEmpty(inst, k)
				quad.Bookkeeping.releaseOwner(v, inst) -- Q48 (a): seat freed last (SlotHandler order)
			end
		end,
	} :: QuadTypes.Handler)
end

return install
