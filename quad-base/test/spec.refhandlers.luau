--!nocheck
--[[
	M8 단위 ② — Ref leaf handler / PreRef·PostRef pre-pass / Processed* / 동적
	경로 가드 (`base/ref-plan.md` "`Ref`의 retract" 절(round18 Q4 순서) / "이중
	배치 방지" 절 / "PreRef" 절 / "`PostRef`" 절, `dispatch-core-plan.md`
	Length/Offset 등록 책임). mock quad 위 CLI — 실물 gcconn·자식 부착은 Studio
	(`audit/m8-unit2-studio-*.md`).
]]

local mock = require("./mock")
local Instance = mock.Instance
local newQuad = mock.newQuad
local assertBlamesUser = mock.assertBlamesUser
local SPEC = "spec.refhandlers.luau"

-- spec 전용: 해시 키(프로퍼티 대역)를 잡아 순서를 기록하는 핸들러
local function installPropRecorder(q, log)
	q.Dispatch.addHandler({
		isHandlable = function(_i, k, _v)
			return type(k) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_i, k, _v, _index)
			table.insert(log, "prop:" .. k)
			return q.Void
		end,
	})
end

print("=== 1. Ref leaf — 배열 자리 바인딩: :Set(inst), H-39 부기(None/0), gchold로 묶임 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local r = q.Ref(nil :: any)
	local seen = {}
	r:Callback(function(v)
		table.insert(seen, v)
	end)
	q.Dispatch.drive(inst, { r })
	assert(r.Value == inst and seen[#seen] == inst, "leaf sets the Ref to the instance and callbacks see it")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "H-39: leaf registered None/0")
	assert(not q.canBound(r), "bound (gchold) — canBound is false while alive here")
	print("PASS")
end

print()
print("=== 2. 이중 배치 방지 — 같은 Ref를 두 인스턴스에 놓으면 두 번째 자리에서 즉시 error(사용자 줄 blame) ===")
do
	local q = newQuad()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	local r = q.Ref(nil :: any)
	q.Dispatch.drive(a, { r })
	local ok, err = pcall(function()
		q.Dispatch.drive(b, { r })
	end)
	assert(not ok, "double placement must error")
	assertBlamesUser(err, SPEC, "double placement")
	assert(r.Value == a, "first binding untouched")
	-- 같은 인스턴스 안의 두 자리도 같은 가드(두 번째 슬롯에서 error)
	local r2 = q.Ref(nil :: any)
	local ok2, err2 = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { r2, r2 })
	end)
	assert(not ok2, "same Ref twice in one children array errors at the second slot")
	assertBlamesUser(err2, SPEC, "same-instance double placement")
	print("PASS")
end

print()
print("=== 3. State<Ref> 재바인드 — retractor가 언바인딩(nil 통지·gchold 해제), process가 새 Ref 바인딩; 같은 Ref 재발행은 둘 다 skip ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local refA, refB = q.Ref(nil :: any), q.Ref(nil :: any)
	local notifyA = 0
	refA:Callback(function()
		notifyA += 1
	end)
	local src = q.Source(refA)
	q.Dispatch.drive(inst, { src })
	assert(refA.Value == inst and notifyA == 2, "bound through StoreBind (registration + inst)")
	src:Set(refA) -- spurious: same Ref again
	assert(notifyA == 2 and refA.Value == inst, "same Ref re-emitted → no re-notify, still bound")
	src:Set(refB)
	assert(refA.Value == nil and notifyA == 3, "old Ref told nil exactly once")
	assert(q.canBound(refA), "old Ref released — may be placed elsewhere")
	assert(refB.Value == inst and not q.canBound(refB), "new Ref bound")
	-- 해제된 refA는 다른 자리에 다시 놓을 수 있다
	local other = Instance.new("Frame")
	q.Dispatch.drive(other, { refA })
	assert(refA.Value == other, "released Ref rebinds elsewhere")
	print("PASS")
end

print()
print("=== 4. [Q4 (a)] 재진입 — 콜백이 같은 자리를 같은 Ref로 재드라이브해도 dedup(SetWeak가 Set 앞) ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local r = q.Ref(nil :: any)
	local src = q.Source(r)
	local reentered = 0
	r:Callback(function(v)
		if v ~= nil and reentered == 0 then
			reentered += 1
			src:Set(r) -- 같은 (inst, k)를 같은 v로 재발행 — 옛 순서면 canBound 크래시
		end
	end)
	q.Dispatch.drive(inst, { src })
	assert(reentered == 1 and r.Value == inst and not q.canBound(r), "re-entrant same-v re-dispatch is a no-op")
	print("PASS")
end

print()
print("=== 5. PreRef — 호이스팅(위치 무관, 프로퍼티보다 먼저), 계열 안 index 순서, 슬롯 소진 부기 None/0 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local log = {}
	installPropRecorder(q, log)
	local gateOnAtPre: any = "unset"
	local p1 = q.PreRef(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "pre1")
			gateOnAtPre = q.Dispatch.getBlocker(v):IsOn() -- ⓪ → (a): 게이트가 켜진 뒤 fire
		end
	end)
	local p2 = q.PreRef(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "pre2")
		end
	end)
	local plain = q.Ref(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "ref")
		end
	end)
	q.Dispatch.drive(inst, { plain, p1, Name = "x", p2 })
	assert(table.concat(log, ",") == "pre1,pre2,ref,prop:Name", "PreRefs fire first in index order, then the body loop: " .. table.concat(log, ","))
	assert(p1.Value == inst and p2.Value == inst, "fired with the instance")
	assert(gateOnAtPre == true, "PreRef fires inside the batch gate (canon ⓪ before (a)) — a callback touching bookkeeping is absorbed")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[2] == 0 and bk.sourceList[2] == q.None and bk.lengthList[3] == 0, "consumed slots registered None/0 (ProcessedPreRefHandler)")
	assert((p1 :: any)._fired == true, "one-shot guard set")
	-- 재사용은 pre-pass에서 즉시 error(사용자 줄)
	local ok, err = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { p1 })
	end)
	assert(not ok and string.find(tostring(err), "one%-shot") ~= nil, "fired PreRef placed again errors: " .. tostring(err))
	assertBlamesUser(err, SPEC, "PreRef reuse")
	print("PASS")
end

print()
print("=== 6. PostRef — 본체 루프·배치 종료 뒤 fire, 계열 안 index 순서, 부모 부착은 무보장(mock: nil), 재사용 error ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local log = {}
	installPropRecorder(q, log)
	local parentAtFire: any = "unset"
	local gateOnAtFire: any = "unset"
	local post1 = q.PostRef(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "post1")
			parentAtFire = v.Parent
			gateOnAtFire = q.Dispatch.getBlocker(v):IsOn() -- H-17: 배치 게이트가 켜진 채로 실행
		end
	end)
	local post2 = q.PostRef(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "post2")
		end
	end)
	local pre = q.PreRef(nil :: any):Callback(function(v)
		if v then
			table.insert(log, "pre")
		end
	end)
	q.Dispatch.drive(inst, { post1, Name = "x", pre, post2 })
	assert(table.concat(log, ",") == "pre,prop:Name,post1,post2", "PostRefs fire last in index order: " .. table.concat(log, ","))
	assert(parentAtFire == nil, "literal path: not yet parented at fire (no guarantee either way — brief Q6)")
	assert(gateOnAtFire == true, "PostRef fires BEFORE the batch closes — gate still on (H-17), one recompute catches up")
	assert(not q.Dispatch.getBlocker(inst):IsOn(), "…and the batch is closed after drive returns")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None and bk.lengthList[3] == 0, "consumed slots registered None/0 (ProcessedPostRefHandler)")
	local ok, err = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { post1 })
	end)
	assert(not ok and string.find(tostring(err), "one%-shot") ~= nil, "fired PostRef placed again errors")
	assertBlamesUser(err, SPEC, "PostRef reuse")
	print("PASS")
end

print()
print("=== 7. 동적 경로 가드 — named 자리의 PreRef/PostRef는 typeof(k)를 실은 error; named 자리의 Ref는 일반 no-match ===")
do
	local q = newQuad()
	for _, mk in { q.PreRef, q.PostRef } do
		local ok, err = pcall(function()
			q.Dispatch.drive(Instance.new("Frame"), { Hook = mk(nil :: any) })
		end)
		assert(not ok and string.find(tostring(err), "must be an array item, not the value of a string key", 1, true) ~= nil, "guard message: " .. tostring(err))
		assertBlamesUser(err, SPEC, "guard blame")
	end
	-- State<PreRef>(Store 경로)도 같은 가드에 닿는다 — 배열 자리라도 pre-pass가 못 보므로
	local ok2, err2 = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { q.Source(q.PreRef(nil :: any)) })
	end)
	assert(not ok2 and string.find(tostring(err2), "through a State/Store value", 1, true) ~= nil, "PreRef through Store hits the guard with the path named, not the key type: " .. tostring(err2))
	local ok2b, err2b = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { q.Source(q.PostRef(nil :: any)) })
	end)
	assert(not ok2b and string.find(tostring(err2b), "PostRef: must be a literal array item", 1, true) ~= nil, "PostRef through Store hits the mirror guard: " .. tostring(err2b))
	local ok3, err3 = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { Hook = q.Ref(nil :: any) })
	end)
	assert(not ok3 and string.find(tostring(err3), "no handler matched", 1, true) ~= nil, "plain Ref at a named key is an ordinary no-match: " .. tostring(err3))
	print("PASS")
end

print()
print("=== 8. Processed* 슬롯의 retract는 Void(no-op) — 소진된 자리를 철거해도 아무 일 없음, Ref leaf 철거는 nil 통지 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local pre, post, r = q.PreRef(nil :: any), q.PostRef(nil :: any), q.Ref(nil :: any)
	q.Dispatch.drive(inst, { pre, post, r })
	q.Dispatch.retractFrom(inst, 1, 1)
	q.Dispatch.retractFrom(inst, 2, 1)
	assert(pre.Value == inst and post.Value == inst, "retracting a consumed slot is a no-op (fire is not undone)")
	q.Dispatch.retractFrom(inst, 3, 1)
	assert(r.Value == nil and q.canBound(r), "plain leaf retract tells nil and releases")
	print("PASS")
end

print()
print("=== ALL PASS ===")
