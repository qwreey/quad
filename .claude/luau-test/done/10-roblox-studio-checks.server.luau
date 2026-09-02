--[[
	⭐ [2026-09-01 재작성 + 같은 날 Studio MCP 실측 완주 — 전 항목 PASS]
	결과 전문은 `audit/spike10-full-run-2026-09-01.md`(A 26건 PASS + B/C,
	GC 관찰 실패 0, ClassName 발화 0). 굵은 발견 둘: (1) claim 없는 inst의
	userdata는 트리에 살아있어도 1 GC 사이클 만에 수거됨 — nativeClaim의
	존재 이유(userdata 동일성 고정)가 실증. (2) Attribute의 Instance 참조는
	**`InstanceHandle`로 감싸 저장**됨 — `GetAttribute` 반환을 원본과 `==`
	비교하면 false고 `handle:Get()`으로 언랩해야 원본(rawequal). 아래 B
	섹션이 그 실측 모양으로 다시 쓰여 있다. **`InstanceHandle`의 정체는
	같은 날 사용자가 설명**(미문서화 Studio Beta, devforum 4753441): 서버가
	세팅한 참조가 클라이언트로 복제될 때 대상 Instance가 아직 스트리밍 안
	됐을 수 있어(StreamingEnabled) 이를 푸는 간접 참조 — `:Get()`은 단순
	얻기라 **nil일 수 있고**, `:Wait()`은 실체화까지 대기 후 반환,
	`InstanceHandle.new(inst)`로 직접 만들어 remote로도 보낼 수 있다.
	SetAttribute는 Instance/핸들 둘 다 받고 Instance는 자동 랩. 상세와
	ObjectValue 관측(이번 Edit 모드에선 Instance 직접 왕복)은 audit 파일.

	A 섹션은 현행 모델로 재작성 완료 — 폐기 모델
	(2-인자 canExecute, bindLifetime의 `.Subscribed` 세팅)을 걷어내고
	`base/lifecycle-pattern.md`의 "(0)"(nativeClaim — gcconn이 gchold와
	**inst까지** 캡처) / "(1)"(bindLifetime/unbindLifetime/isBoundAlive —
	BindData 쪽 복사 gcconn만으로 판정) / "(3)"(canBound vs canExecute,
	서로의 부정) 절의 스케치를 그대로 이식했다. 옛 A 섹션 원문은 git
	히스토리(이 파일의 2026-08-14 이전 리비전).

	검증 대상 (Roblox Studio 전용 — 실제 Instance/Connection/
	CollectionService/Attribute가 필요, 순수 luau CLI 불가):

	A) gcconn 트릭 위의 현행 생명주기 프리미티브 전량 —
	   `audit/gcconn-trick-verification.md`의 "아직 확인 안 된 것" 절이
	   이 재작성의 요구 명세다:
	   - A-0: ClassName 신호 미발화(전 구간 카운터) + Destroy 시
	     gcconn.Connected 동기 전환(기확인 항목이지만 반드시 남길 것 —
	     canExecute의 유일 근거).
	   - A-1: canBound 게이트 (a) — 살아있는 바인딩 재-bindLifetime은 error.
	   - A-2: canBound 게이트 (b) — unbindLifetime 후 재바인드 통과 +
	     같은 inst의 다른 값에 영향 없음(O(1) 개별 해제).
	   - A-3: canBound 게이트 (c) — inst Destroy 후 같은 값을 **다른**
	     inst에 재바인드 통과(모델이 명시 허용: "바인딩이 죽은 뒤의
	     재사용은 허용").
	   - A-4: canExecute가 inst 없이 BindData 쪽 복사 gcconn만으로 판정
	     성립(살아있을 때 true / Destroy 직후 동기 false).
	   - A-5: Destroy + GC 후 weak 릴레이션 항목이 스스로 비워지고
	     (BindData의 gcconn/gchold), gchold에만 매달린 value가 실제로
	     수거됨(누수 없음).
	   - A-6: Instance userdata 동일성 — X1) nativeClaim된 inst는 강참조를
	     안 들어도 GC를 견디고 재조회 결과가 rawequal / X2) claim 없는
	     inst는 워크스페이스에 살아있어도 userdata가 수거될 수 있는지 관찰
	     (수거된다면 "재조회 시 다른 userdata" 전제가 실증되는 것).
	   - A-7: Instance를 `__mode="k"` weak key로 쓰는 경로 — Destroy로
	     gcconn 순환이 끊긴 뒤 GC가 항목을 치우는지(plain table과 동일
	     동작인지, `07`이 CLI에서 확인한 것의 Instance판).
	B) Attribute가 Instance 참조 타입을 실제로 지원하는가(ObjectValue
	   없이 Ref 용도로 쓸 수 있다는 .claude/session-summary.md 서술의 실측)
	   — [2026-09-01 실측] 지원하되 읽기는 InstanceHandle 언랩 경유(머리말).
	C) CollectionService 태그 + GetTagged 왕복이 quad-debug가 기대하는
	   대로 동작하는가(태그 추가/제거, GetTagged로 조회).

	배경: base/lifecycle-pattern.md의 위 세 절 + audit/
	gcconn-trick-verification.md(부분 실측과 미확인 목록),
	base/relate-plan.md(weak 릴레이션), research/debug-tooling-plan.md
	(CollectionService 노출 방식).

	실행 방법 (2026-09-01부터 둘 다 가능):
	1. Studio MCP: `execute_luau`(Edit datamodel)로 이 파일 내용을 실행 —
	   GC 대기 구간이 있어 섹션별로 나눠 돌려도 됨(각 do 블록은 프렐류드만
	   있으면 자기완결). SAFETY.md의 별도 계정 게이트 확인 후.
	2. 수동: ServerScriptService에 붙여넣고 Run(F8) — Output 확인.
	마지막 줄 마커가 판정: "10-A/B/C ALL PASS" 또는 "10 FAIL: <n>건".

	주의: waitForGC는 간접 관찰(정확 트리거 아님, gc-trigger-helper 참고)
	이라 60초 상한을 두고 미완료는 관찰 실패로 따로 센다.
]]

-- ═══════════════════════════════════════════════════════════════
-- 공용 프렐류드 — base/lifecycle-pattern.md (0)/(1)/(3)의 최소 이식
-- ═══════════════════════════════════════════════════════════════

local PASS, FAIL, GCFAIL = 0, 0, 0
local function check(cond: boolean, label: string)
	if cond then
		PASS += 1
		print(`  PASS  {label}`)
	else
		FAIL += 1
		warn(`  FAIL  {label}`)
	end
end

-- Relate의 최소 대역: 바깥은 weak key(값/inst), 레코드는 weak value —
-- SetWeak("다른 곳에서 안전하게 유지되는 것은 항상 weak로") 재현.
local function newRelate()
	local store = setmetatable({} :: { [any]: any }, { __mode = "k" })
	return {
		store = store, -- 관찰용(A-5/A-7)
		SetWeak = function(key: any, field: string, v: any)
			local rec = store[key]
			if rec == nil then
				rec = setmetatable({}, { __mode = "v" })
				store[key] = rec
			end
			rec[field] = v
		end,
		GetWeak = function(key: any, field: string): any
			local rec = store[key]
			return if rec ~= nil then rec[field] else nil
		end,
	}
end

local InstData = newRelate() -- inst  -> gchold/gcconn (nativeClaim이 채움)
local BindData = newRelate() -- value -> gchold/gcconn (bindLifetime이 채움)

local unexpectedFires = 0 -- ClassName 신호가 발화하면 증가 — 항상 0이어야 함

local nop = false or function(...) end -- 상수 접힘/인라인 방지(정본 스케치 그대로)

-- (0) nativeClaim — Instance 생성/claim 직후 정확히 한 번.
-- 클로저가 gchold뿐 아니라 **inst까지** 캡처하는 게 핵심(userdata 동일성 고정).
local function nativeClaim(inst: Instance)
	local gchold: { [any]: any } = {}
	local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
		unexpectedFires += 1
		warn("[예상 밖] ClassName Changed 발화! gcconn 트릭 전제 붕괴:", inst:GetFullName())
		nop(gchold, inst)
	end)
	gchold[1] = gcconn -- 배열 자리 1번은 gcconn 전용(값들은 해시 자리에)
	InstData.SetWeak(inst, "gchold", gchold)
	InstData.SetWeak(inst, "gcconn", gcconn)
end

-- (1) 비공개 판정 — 이 스파이크엔 Observer/Effect가 없으므로 (b) 전역
-- 구독 경로(`.Subscribed`)는 스코프 밖. (a) inst-scoped 경로만 이식.
local function isBoundAlive(value: any): boolean
	local gcconn = BindData.GetWeak(value, "gcconn")
	return gcconn ~= nil and gcconn.Connected
end

-- (3) 두 진입점 — 같은 판정을 서로 반대 방향으로 감쌈
local function canBound(value: any): boolean
	return not isBoundAlive(value)
end
local function canExecute(value: any): boolean
	return isBoundAlive(value)
end

local function bindLifetime(inst: Instance, value: any)
	if not canBound(value) then
		error("bindLifetime: value is already bound to another Instance", 2)
	end
	local gchold = InstData.GetWeak(inst, "gchold")
	gchold[value] = true -- 강참조: inst가 사는 동안 value 생존 보장(계약 1)
	BindData.SetWeak(value, "gchold", gchold)
	BindData.SetWeak(value, "gcconn", InstData.GetWeak(inst, "gcconn")) -- 계약 2
end

local function unbindLifetime(value: any)
	local gchold = BindData.GetWeak(value, "gchold")
	if gchold ~= nil then
		gchold[value] = nil -- inst는 안 건드림, 이 value 하나만 O(1) 해제
	end
	BindData.SetWeak(value, "gchold", nil)
	BindData.SetWeak(value, "gcconn", nil)
end

-- GC 완료 간접 관찰(gc-trigger-helper.server.luau) + 60초 상한
local function waitForGC(label: string): boolean
	local canary = setmetatable({ {} }, { __mode = "v" })
	local epoch = 0
	while canary[1] ~= nil do
		task.wait(0.1)
		local _ = table.create(5000, true) -- 할당 압력 — incremental GC 강제
		epoch += 1
		if epoch >= 600 then
			GCFAIL += 1
			warn(`[GC] {label}: 60초 내 미완료 — 관찰 실패(판정 불가로 별도 계수)`)
			return false
		end
	end
	print(`[GC] {label}: 완료 추정(epoch {epoch})`)
	return true
end

-- ═══════════════════════════════════════════════════════════════
print("== A-0) ClassName 미발화 + Destroy 시 Connected 동기 전환 ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A0"
	inst.Parent = workspace
	nativeClaim(inst)
	local gcconn: RBXScriptConnection = InstData.GetWeak(inst, "gcconn")
	check(gcconn.Connected == true, "A-0a claim 직후 gcconn.Connected == true")
	inst:Destroy()
	-- GC도 task.wait도 없이 같은 줄기에서 즉시 — "동기 전환"이 명제
	check(gcconn.Connected == false, "A-0b Destroy 직후(동기) gcconn.Connected == false")
end

print("== A-1) canBound 게이트 (a): 살아있는 바인딩 재-bind는 error ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A1"
	inst.Parent = workspace
	nativeClaim(inst)
	local v = { tag = "A1" }
	bindLifetime(inst, v)
	check(canExecute(v) == true, "A-1a bind 직후 canExecute == true")
	local ok = pcall(bindLifetime, inst, v)
	check(ok == false, "A-1b 같은 값 재-bindLifetime은 error")
	local inst2 = Instance.new("Folder")
	inst2.Name = "QuadSpike10_A1b"
	inst2.Parent = workspace
	nativeClaim(inst2)
	local ok2 = pcall(bindLifetime, inst2, v)
	check(ok2 == false, "A-1c 다른 inst로의 재-bindLifetime도 error(살아있는 한)")
	inst:Destroy()
	inst2:Destroy()
end

print("== A-2) canBound 게이트 (b): unbind 후 재바인드 + 개별 해제 ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A2"
	inst.Parent = workspace
	nativeClaim(inst)
	local v1, v2 = { tag = "A2v1" }, { tag = "A2v2" }
	bindLifetime(inst, v1)
	bindLifetime(inst, v2)
	unbindLifetime(v2)
	check(canExecute(v2) == false, "A-2a unbind된 값은 canExecute == false")
	check(canExecute(v1) == true, "A-2b 같은 inst의 다른 값은 영향 없음(canExecute 유지)")
	local ok = pcall(bindLifetime, inst, v2)
	check(ok == true, "A-2c unbind 후 같은 값 재-bindLifetime 통과")
	check(canExecute(v2) == true, "A-2d 재바인드 후 canExecute == true")
	unbindLifetime({ never = "bound" }) -- 안 걸린 값에 불러도 안전한 no-op 계약
	check(true, "A-2e 안 걸린 값 unbindLifetime은 no-op(위 줄이 error 안 남)")
	inst:Destroy()
end

print("== A-3) canBound 게이트 (c): Destroy 후 다른 inst로 재바인드 허용 ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A3"
	inst.Parent = workspace
	nativeClaim(inst)
	local v = { tag = "A3" }
	bindLifetime(inst, v)
	inst:Destroy()
	check(canBound(v) == true, "A-3a Destroy 직후 canBound == true(GC 안 기다림)")
	local inst2 = Instance.new("Folder")
	inst2.Name = "QuadSpike10_A3b"
	inst2.Parent = workspace
	nativeClaim(inst2)
	local ok = pcall(bindLifetime, inst2, v)
	check(ok == true, "A-3b 죽은 바인딩의 값을 새 inst에 재바인드 통과")
	check(canExecute(v) == true, "A-3c 재바인드 후 canExecute == true(새 gcconn 기준)")
	inst2:Destroy()
end

print("== A-4) canExecute는 inst 없이 BindData 복사 gcconn만으로 판정 ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A4"
	inst.Parent = workspace
	nativeClaim(inst)
	local v = { tag = "A4" }
	bindLifetime(inst, v)
	-- isBoundAlive 구현이 InstData/inst를 아예 안 읽는 건 코드 형태로 보장 —
	-- 여기선 그 판정이 실제 Connection 상태를 정확히 따라가는지만 실측.
	check(canExecute(v) == true, "A-4a 살아있는 동안 true")
	inst:Destroy()
	check(canExecute(v) == false, "A-4b Destroy 직후(동기·GC 무관) false")
end

print("== A-5) Destroy + GC 후 weak 릴레이션 자기 정리 + value 수거 ==")
do
	local inst = Instance.new("Folder")
	inst.Name = "QuadSpike10_A5"
	inst.Parent = workspace
	nativeClaim(inst)
	local held = { tag = "A5held" } -- 테스트가 강참조를 유지하는 값
	bindLifetime(inst, held)
	local leaked = setmetatable({ { tag = "A5leaked" } }, { __mode = "v" })
	bindLifetime(inst, leaked[1]) -- gchold에만 매달린 값(외부 강참조 없음)
	check(BindData.GetWeak(held, "gcconn") ~= nil, "A-5a 살아있는 동안 BindData 항목 존재")
	inst:Destroy()
	if waitForGC("A-5 릴레이션 정리") then
		check(
			BindData.GetWeak(held, "gcconn") == nil and BindData.GetWeak(held, "gchold") == nil,
			"A-5b GC 후 BindData의 gcconn/gchold 항목이 스스로 비워짐"
		)
		check(isBoundAlive(held) == false, "A-5c 비워진 뒤에도 isBoundAlive는 nil 분기로 false")
		check(leaked[1] == nil, "A-5d gchold에만 매달렸던 value가 실제로 수거됨(누수 없음)")
	end
end

print("== A-6) Instance userdata 동일성 ==")
do
	-- X1: nativeClaim된 inst — 강참조를 안 들어도 userdata가 고정되는가
	do
		local weak = setmetatable({}, { __mode = "v" })
		do
			local inst = Instance.new("Folder")
			inst.Name = "QuadSpike10_A6_X1"
			inst.Parent = workspace
			nativeClaim(inst)
			weak[1] = inst
		end -- 스코프 밖 — Lua 쪽 강참조는 gcconn 클로저뿐
		if waitForGC("A-6 X1 생존 확인") then
			check(weak[1] ~= nil, "A-6a claim된 inst는 강참조 없이도 GC를 견딤(클로저가 캡처)")
			local refetched = workspace:FindFirstChild("QuadSpike10_A6_X1")
			check(refetched ~= nil and rawequal(refetched, weak[1]), "A-6b 재조회 결과가 rawequal(동일 userdata)")
		end
		local found = workspace:FindFirstChild("QuadSpike10_A6_X1")
		if found then
			found:Destroy()
		end
	end
	-- X2: claim 없는 inst — 엔진 트리에 살아있어도 userdata가 수거되는가.
	-- 수거되면 "재조회 시 다른 userdata" 전제(nativeClaim의 존재 이유)가 실증됨.
	-- 안 수거되면 그것대로 관측 기록(설계엔 무해 — claim이 불필요했을 뿐).
	do
		local weak = setmetatable({}, { __mode = "v" })
		do
			local inst = Instance.new("Folder")
			inst.Name = "QuadSpike10_A6_X2"
			inst.Parent = workspace
			weak[1] = inst -- claim 안 함, 강참조도 이 스코프가 끝나면 없음
		end
		local cycles = 0
		while weak[1] ~= nil and cycles < 3 do -- 최대 3사이클 관찰(실측은 1사이클에 수거됨)
			if not waitForGC(`A-6 X2 사이클 {cycles + 1}`) then
				break
			end
			cycles += 1
		end
		if weak[1] == nil then
			print(`  OBSERVE A-6c claim 없는 inst의 userdata는 수거됨({cycles}사이클) — 재조회는 다른 userdata (전제 실증)`)
		else
			print(`  OBSERVE A-6c claim 없는 inst의 userdata가 {cycles}사이클 뒤에도 생존 — 전제 미재현(관측 기록)`)
		end
		local found = workspace:FindFirstChild("QuadSpike10_A6_X2")
		if found then
			found:Destroy()
		end
	end
end

print("== A-7) Instance를 __mode=k weak key로: Destroy 후 항목 소멸 ==")
do
	local weakKeyed = setmetatable({} :: { [Instance]: string }, { __mode = "k" })
	do
		local inst = Instance.new("Folder")
		inst.Name = "QuadSpike10_A7"
		inst.Parent = workspace
		nativeClaim(inst)
		weakKeyed[inst] = "entry"
		inst:Destroy() -- 엔진이 커넥션을 끊어 gcconn 순환 절단 — 유일한 절단면
	end
	if waitForGC("A-7 weak key 정리") then
		check(next(weakKeyed) == nil, "A-7a Destroy+GC 후 weak-key 항목이 치워짐(plain table과 동일)")
	end
end

print("== A 마무리) ClassName 신호 전 구간 미발화 ==")
check(unexpectedFires == 0, `A-8a unexpectedFires == 0 (실측 {unexpectedFires})`)

-- ═══════════════════════════════════════════════════════════════
print("== B) Attribute의 Instance 참조 타입 지원 여부 ==")
do
	local target = Instance.new("Folder")
	target.Name = "QuadSpike10_B_Target"
	target.Parent = workspace
	local holder = Instance.new("Folder")
	holder.Name = "QuadSpike10_B_Holder"
	holder.Parent = workspace

	local ok, err = pcall(function()
		holder:SetAttribute("RefToTarget", target)
	end)
	check(ok, `B-1 SetAttribute(Instance) 성공 여부{if ok then "" else ` — {tostring(err)}`}`)
	if ok then
		-- [2026-09-01 실측] 반환은 Instance가 아니라 InstanceHandle(미문서화
		-- Studio Beta) — 원본과 ==/rawequal 모두 false, :Get() 언랩이 왕복 경로.
		local rb = holder:GetAttribute("RefToTarget")
		check(typeof(rb) == "InstanceHandle", `B-2 반환 타입 InstanceHandle(실측 {typeof(rb)})`)
		check(rawequal((rb :: any):Get(), target), "B-3 handle:Get()이 원본과 rawequal(왕복은 언랩 필요)")
		target:Destroy()
		task.wait()
		local after = holder:GetAttribute("RefToTarget")
		check(typeof(after) == "InstanceHandle", "B-4 target Destroy 후에도 핸들은 남음(nil로 안 풀림)")
		local got = (after :: any):Get()
		check(
			typeof(got) == "Instance" and got.Parent == nil,
			"B-5 죽은 뒤 :Get()은 죽은 Instance(Parent=nil)를 그대로 줌 — 생존 판정은 소비자 몫"
		)
	else
		target:Destroy()
	end
	holder:Destroy()
end

-- ═══════════════════════════════════════════════════════════════
print("== C) CollectionService 태그 + GetTagged 왕복 ==")
do
	local CollectionService = game:GetService("CollectionService")
	local TAG = "QuadDebugSpikeTag"
	local a = Instance.new("Folder")
	a.Name = "QuadSpike10_C_A"
	a.Parent = workspace
	local b = Instance.new("Folder")
	b.Name = "QuadSpike10_C_B"
	b.Parent = workspace

	CollectionService:AddTag(a, TAG)
	CollectionService:AddTag(b, TAG)
	check(#CollectionService:GetTagged(TAG) == 2, "C-1 AddTag ×2 후 GetTagged 개수 == 2")
	CollectionService:RemoveTag(a, TAG)
	check(#CollectionService:GetTagged(TAG) == 1, "C-2 RemoveTag 후 GetTagged 개수 == 1")
	a:Destroy()
	b:Destroy()
	check(#CollectionService:GetTagged(TAG) == 0, "C-3 Destroy 후 태그가 엔진에 의해 정리됨(개수 0)")
end

-- ═══════════════════════════════════════════════════════════════
print("========================================")
if FAIL == 0 and GCFAIL == 0 then
	print(`10-A/B/C ALL PASS ({PASS}건)`)
elseif FAIL == 0 then
	print(`10 부분 통과: PASS {PASS} / GC 관찰 실패 {GCFAIL} (판정 불가 항목 있음)`)
else
	print(`10 FAIL: {FAIL}건 (PASS {PASS}, GC 관찰 실패 {GCFAIL})`)
end
