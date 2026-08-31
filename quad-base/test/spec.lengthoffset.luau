--[[
	Length/Offset bookkeeping — `.claude/base/dispatch-core-plan.md`
	"Length/Offset" / "두 필드" / "배치 등록을 안전하게 만드는 Blocker 게이팅"
	sections (M3 unit 2). Handlers don't exist yet, so registrations are called
	directly the way leaf handlers will call them; `inst` is a mock Instance
	(the bk itself is gchold-anchored — `H-229` pattern).
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

local Instance = mock.Instance
-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local newQuad = mock.newQuad -- `H-261`: 공용 헬퍼는 mock이 소유

-- 값 변경을 세는 프로브 — Source에 Observer를 달아 Set 횟수를 센다
local function probe(q: QuadTypes.Quad, src: any): () -> number
	local count = 0
	-- 등록만으로는 발화하지 않는다(canExecute 게이트) — 강한 구독을 세운다
	local obs = (src :: any):Observer(function()
		count += 1
	end):Subscribe()
	local _ = obs -- 강참조 유지(테스트 스코프)
	return function()
		return count - 1 -- 등록 즉시 1회 실행은 세지 않는다
	end
end

print("=== 1. 등록 + 즉시 계산 — 배치 밖 순차 등록에서 각 자리 offset이 그 자리에서 맞는다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s1, s2, s3 = q.Source(-1), q.Source(-1), q.Source(-1)
	q.Dispatch.setOffsetSource(inst, 1, s1)
	q.Dispatch.setLength(inst, 1, 2)
	q.Dispatch.setOffsetSource(inst, 2, s2)
	q.Dispatch.setLength(inst, 2, 3)
	q.Dispatch.setOffsetSource(inst, 3, s3)
	q.Dispatch.setLength(inst, 3, 1)
	assert(s1:Get() == 0, "position 1 offset = base(0) for a physical inst")
	assert(s2:Get() == 2, "position 2 offset = length of 1")
	assert(s3:Get() == 5, "position 3 offset = lengths of 1..2")
	assert(q.Dispatch.getOffsetAt(inst, 3) == 5, "getOffsetAt agrees with the published Source")
	print("PASS")
end

print()
print("=== 2. None 자리 — 발행 채널 없음일 뿐 참여는 setLength가 답, 숫자는 pull ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	q.Dispatch.setOffsetSource(inst, 1, q.None) -- 얼리 리턴(계산 없음)
	q.Dispatch.setLength(inst, 1, 4)
	local s2 = q.Source(-1)
	q.Dispatch.setOffsetSource(inst, 2, s2)
	q.Dispatch.setLength(inst, 2, 1)
	assert(s2:Get() == 4, "a None neighbor still contributes its length")
	assert(q.Dispatch.getOffsetAt(inst, 1) == 0, "the None position's own number is pullable")
	print("PASS")
end

print()
print("=== 3. State 길이 — Observer가 recompute를 몰고, 뒤 형제 offset만 갱신된다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local len1 = q.Source(2)
	local s1, s2, s3 = q.Source(-1), q.Source(-1), q.Source(-1)
	local elem1 = Instance.new("Frame") -- 그 자리 요소(H-141: gatedRecompute가 조회할 키)
	q.Dispatch.setOffsetSource(inst, 1, s1)
	q.Dispatch.setLength(inst, 1, len1, inst, elem1)
	q.Dispatch.setOffsetSource(inst, 2, s2)
	q.Dispatch.setLength(inst, 2, 1)
	q.Dispatch.setOffsetSource(inst, 3, s3)
	q.Dispatch.setLength(inst, 3, 1)
	assert(s2:Get() == 2 and s3:Get() == 3, "initial offsets")

	local s1Sets = probe(q, s1)
	len1:Set(5)
	assert(s2:Get() == 5 and s3:Get() == 6, "trailing offsets follow the State length")
	assert(s1:Get() == 0 and s1Sets() == 0, "positions at or before the change don't re-Set")

	-- 같은 값 재-Set: Source는 항상 emit(H-68)하지만 recompute의 ~= 가드가 offset 쓰기를 거른다
	local s3Sets = probe(q, s3)
	len1:Set(5)
	assert(s3Sets() == 0, "unchanged offsets are not re-Set (Get ~= abs guard)")
	print("PASS")
end

print()
print("=== 4. drive 배치 게이팅 — 등록 중 recompute 0회, 닫힌 뒤 한 번(offset은 즉시 계산이 이미 정확) ===")
do
	local q = newQuad()
	local sources: { any } = {}
	local setCounts: { number } = {}
	q.Dispatch.addHandler({
		name = "SpecLeaf",
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			return type(k) == "number"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?) -> ()
			local src = q.Source(-1)
			sources[k] = src
			-- 프로브를 **등록 전에** 설치해야 배치 중의 모든 Set이 세어진다 —
			-- drive가 끝난 뒤 달면 vacuous(리뷰 지적, `H-239`)
			setCounts[k] = 0
			local obs = (src :: any):Observer(function()
				setCounts[k] += 1
			end):Subscribe()
			local _ = obs
			setCounts[k] = 0 -- 등록 즉시 1회 실행 보정
			q.Dispatch.setOffsetSource(inst, k, src)
			q.Dispatch.setLength(inst, k, v) -- v = 이 자리의 기여도(숫자)
			return q.Void
		end,
	} :: QuadTypes.Handler)
	q.Dispatch.addHandler({
		name = "SpecHash",
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			return type(k) ~= "number"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_LOW,
		process = function(_inst: any, _k: any, _v: any, _index: number): (any?) -> ()
			return q.Void
		end,
	} :: QuadTypes.Handler)

	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { 2, 3, 1, Size = "s" })
	assert(sources[1]:Get() == 0 and sources[2]:Get() == 2 and sources[3]:Get() == 5, "immediate calc filled offsets in order")
	assert(q.Dispatch.getBlocker(inst):IsOn() == false, "batch blocker closed after drive")
	assert(q.Dispatch.getBookkeeping(inst).N == 3, "bk.N = registered array positions")

	-- 배치 중 각 Source가 정확히 1회만 Set을 받았다 — 즉시 계산 1회, 배치 중
	-- gatedRecompute는 전부 스킵, 마지막 recompute는 ~= 가드로 no-op(검증 패스)
	for k = 1, 3 do
		assert(setCounts[k] == 1, `source {k} received exactly one Set during the batch (got {setCounts[k]})`)
	end
	print("PASS")
end

print()
print("=== 5. 되감기 + 재진입 게이트 — offset:Set 콜백이 앞자리를 바꾸면 그 자리부터 다시 돈다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s1, s2, s3 = q.Source(-1), q.Source(-1), q.Source(-1)
	q.Dispatch.setOffsetSource(inst, 1, s1)
	q.Dispatch.setLength(inst, 1, 1)
	q.Dispatch.setOffsetSource(inst, 2, s2)
	q.Dispatch.setLength(inst, 2, 1)
	q.Dispatch.setOffsetSource(inst, 3, s3)
	q.Dispatch.setLength(inst, 3, 1)
	assert(s2:Get() == 1 and s3:Get() == 2, "steady state")

	-- s2가 다음으로 Set되는 순간(= recompute 커서가 2일 때) 앞자리 1의 길이를
	-- 바꾼다 — 중첩 gatedRecompute는 recomputeBlocker에 막히고, 바깥 루프가
	-- offsetSetUpTo(1)로 되감아 2·3을 새 베이스로 다시 Set해야 한다.
	local once = false
	local obs = (s2 :: any):Observer(function()
		if not once and s2:Get() == 2 then
			once = true
			q.Dispatch.setLength(inst, 1, 5) -- 콜백 안 재진입 — 게이트 + 되감기 경로
		end
	end):Subscribe()
	local _ = obs

	q.Dispatch.setLength(inst, 1, 2) -- 트리거: s2가 2로 Set되는 recompute
	assert(once, "the reentrant callback actually ran")
	assert(s2:Get() == 5, "position 2 rewound to the new base")
	assert(s3:Get() == 6, "position 3 followed")
	assert(q.Dispatch.getBookkeeping(inst).recomputeBlocker:IsOn() == false, "reentry blocker released")
	print("PASS")
end

print()
print("=== 6. 캐시 무효화 — setLength(i)는 i까지 당기고, i 이전 캐시는 산다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	for i = 1, 4 do
		q.Dispatch.setOffsetSource(inst, i, q.None)
		q.Dispatch.setLength(inst, i, 1)
	end
	assert(q.Dispatch.getOffsetAt(inst, 4) == 3, "prefix cache built")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.offsetCacheValidUpTo == 4, "cache valid to the pulled position")
	q.Dispatch.setLength(inst, 3, 7)
	-- 무효화(둘 다 i까지)는 setLength 꼬리의 동기 recompute가 곧바로 캐시를
	-- 재구축하므로 중간 상태로는 관측 불가 — 값으로 확인한다: 뒤 자리는 새
	-- 길이를 반영하고, i 이전 접두는 살아남은 캐시 그대로다.
	assert(bk.offsetCacheValidUpTo == 4, "the tail recompute rebuilt the cache")
	assert(q.Dispatch.getOffsetAt(inst, 4) == 9, "positions after i reflect the new length")
	assert(q.Dispatch.getOffsetAt(inst, 2) == 1, "positions before i kept their prefix")
	print("PASS")
end

print()
print("=== 7. H-229 패턴 — bk도 gchold 앵커: Destroy 후 부기 그래프 전체가 회수된다 ===")
do
	local q = newQuad()
	local weakProbe: { [number]: any } = setmetatable({}, { __mode = "v" }) :: any
	local function build(): any
		local inst = Instance.new("Frame")
		local len = q.Source(1)
		q.Dispatch.setOffsetSource(inst, 1, q.Source(-1))
		q.Dispatch.setLength(inst, 1, len, inst, Instance.new("Frame"))
		weakProbe[1] = q.Dispatch.getBookkeeping(inst)
		return inst
	end
	local inst = build()
	collectgarbage()
	collectgarbage()
	assert(weakProbe[1] ~= nil, "bk lives while the inst lives (gchold anchor)")
	inst:Destroy()
	inst = nil
	collectgarbage()
	collectgarbage()
	assert(weakProbe[1] == nil, "after Destroy the whole bookkeeping graph is collectable")
	print("PASS")
end

print()
print("=== 8. anchor 인자 — 길이 Observer의 생명주기는 부기 키가 아니라 앵커를 따른다 ===")
do
	local q = newQuad()
	local owner = Instance.new("Frame")
	local anchor = Instance.new("Frame")
	local len = q.Source(1)
	local s1, s2 = q.Source(-1), q.Source(-1)
	q.Dispatch.setOffsetSource(owner, 1, s1)
	q.Dispatch.setLength(owner, 1, len, anchor, anchor)
	q.Dispatch.setOffsetSource(owner, 2, s2)
	q.Dispatch.setLength(owner, 2, 1)
	len:Set(3)
	assert(s2:Get() == 3, "anchored observer drives recompute while the anchor lives")
	anchor:Destroy()
	len:Set(7)
	assert(s2:Get() == 3, "after the anchor dies the length observer no longer fires (canExecute gate)")
	print("PASS")
end

print()
print("=== ALL PASS ===")
