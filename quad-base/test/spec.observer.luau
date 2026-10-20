--[[
	Observer 계약 — `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드"(`_receive`/`_catchUp`/
	생성자 순서) / "`state:Observer(fn)`" 절(등록 즉시 1회, `fn(targetState, self, emitFrom?)`, `nil` 계약),
	`.claude/base/lifecycle-pattern.md` "(2) 전역 경로"(네 진입점, `H-183` `_running`) / "(1)"(`bindLifetime`의
	커밋 전 `_assertBindable` 문의 — `H-184`) / "(4) 실제 호출부"(`canExecute` 게이팅).
]]

local Quad = require("../src")
local mock = require("./mock")
local QuadTypes = require("../luau_packages/quad_types")

type Observer = QuadTypes.Observer

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local quad = Quad.NewModule()
mock.installLifetime(quad)
local Source = quad.Source
local Instance = mock.Instance

print("=== 1. 생성 — 등록 즉시 1회(emitFrom = nil), _state 강참조, 브랜드, 순서(_subs 합류 → 설치 실행 — round13 3′ Q73 (a)) ===")
do
	local s = Source(1)
	local calls: { any } = {}
	local o = s:Observer(function(target, self, from)
		table.insert(calls, { target = target, self = self, from = from })
	end)
	assert(#calls == 1 and calls[1].target == s and calls[1].self == o and calls[1].from == nil, "install fire: (state, observer, nil)")
	assert(quad.isObserver(o) and not quad.isState(o) and not quad.isEpoch(o), "brand")
	assert((o :: any).__quadObserver == true, "ObserverMarker field readable (H-300, 2026-09-07 마커 전면화)")
	assert((o :: any)._state == s, "observer holds its State strongly")
	assert((s :: any)._subs[o] == true, "joined the subscriber set (before the install run — round13 3′)")
	assert((o :: any)._rerunRequired == false, "no hold after the install run (seeded false — one meaning: a change while unexecutable)")
	assert(o.Subscribed == false, "Subscribed starts false (shared flag, same as Effect — H-189)")
	-- 설치 발화 도중 온 변경은 그 자리에서 다시 돌지 않고 보류된다(2026-10-01 사용자 결정 "설치 중 즉시 도는거 아님") —
	-- 세부는 10절. 여기선 보류 장치가 Effect의 `_pending`을 따로 두지 않는다는 것만(하나의 뜻: `_rerunRequired`)
	assert((o :: any)._pending == nil, "no `_pending` field — the install window holds through `_rerunRequired`")
	print("PASS")
end

print()
print("=== 2. _receive — canExecute 게이팅: 안 묶이면 홀드, 묶이면 fn(state, self, from) ===")
do
	local s = Source(1)
	local calls: { { from: any } } = {} -- `table.insert(t, nil)`은 길이를 안 늘리므로 래퍼로 기록
	local o = s:Observer(function(_, _, from)
		table.insert(calls, { from = from })
	end)
	s:Set(2)
	assert(#calls == 1, "unbound observer does not fire")
	assert((o :: any)._rerunRequired == true, "…the change is held (H-159)")
	local inst = Instance.new("Frame")
	quad.Backend.bindLifetime(inst, o)
	assert(#calls == 2 and calls[2].from == nil, "bind replays the held change once, with no source (H-164)")
	assert((o :: any)._rerunRequired == false, "flag lowered")
	s:Set(3)
	assert(#calls == 3 and calls[3].from == s, "bound: fires with the source epoch")
	inst:Destroy()
	s:Set(4)
	assert(#calls == 3 and (o :: any)._rerunRequired == true, "dead inst: held again, not fired")
	print("PASS")
end

print()
print("=== 3. 무인자 state:Observer() — 항상 관측 유틸(호출 즉시 Get) ===")
do
	local runs = 0
	local s = Source(1)
	local d = s:Compute(function(x): number
		runs += 1
		return x:Get()
	end)
	local o = d:Observer()
	assert(runs == 1, "install fire observed (computed) once")
	o:Subscribe()
	s:Set(2)
	assert(runs == 2, "each change re-observes")
	o:Unsubscribe()
	print("PASS")
end

print()
print("=== 4. WeakSubscribe(프리미티브) — .Subscribed=true, 약한 등록, 캐치업; canExecute true ===")
do
	local s = Source(1)
	local calls = 0
	local o = s:Observer(function()
		calls += 1
	end)
	s:Set(2) -- held
	assert(o:WeakSubscribe() == o, "returns self")
	assert(o.Subscribed == true and quad.Backend.canExecute(o) == true, "flag + gate")
	assert(calls == 2, "WeakSubscribe replayed the held change once")
	s:Set(3)
	assert(calls == 3, "fires while weakly subscribed")
	local ok, err = pcall(function()
		o:WeakSubscribe()
	end)
	assert(not ok and string.find(tostring(err), "already subscribed", 1, true) ~= nil, "double subscribe: " .. tostring(err))
	assert(string.find(tostring(err), "spec.observer.luau", 1, true) ~= nil, "level 2")
	local ok2, err2 = pcall(function()
		quad.Backend.bindLifetime(Instance.new("Frame"), o)
	end)
	assert(not ok2 and string.find(tostring(err2), "already subscribed", 1, true) ~= nil, "bindLifetime shares the gate: " .. tostring(err2))
	print("PASS")
end

print()
print("=== 5. WeakUnsubscribe — 관대(H-133), 단 강한 킵이 있으면 error ===")
do
	local s = Source(1)
	local o = s:Observer(function() end)
	o:WeakUnsubscribe() -- never subscribed: silent
	o:WeakSubscribe():WeakUnsubscribe()
	assert((o :: any).Subscribed == false and quad.Backend.canExecute(o) == false, "released")
	o:WeakUnsubscribe() -- already released: silent
	o:Subscribe()
	local ok, err = pcall(function()
		o:WeakUnsubscribe()
	end)
	assert(not ok and string.find(tostring(err), "use :Unsubscribe()", 1, true) ~= nil, "strong keep present: " .. tostring(err))
	assert(o.Subscribed == true, "…and nothing was changed")
	o:Unsubscribe()
	print("PASS")
end

print()
print("=== 6. Subscribe/Unsubscribe — 인라인 게이트(H-149), 강한 킵, 엄격 해제 ===")
do
	local s = Source(1)
	local calls = 0
	local o = s:Observer(function()
		calls += 1
	end)
	s:Set(2)
	assert(o:Subscribe() == o and calls == 2, "Subscribe replays the held change once")
	local ok, err = pcall(function()
		o:Subscribe()
	end)
	assert(not ok and string.find(tostring(err), "spec.observer.luau", 1, true) ~= nil, "double subscribe points at the caller: " .. tostring(err))
	local w = s:Observer(function() end):WeakSubscribe()
	local ok2, err2 = pcall(function()
		w:Unsubscribe()
	end)
	assert(not ok2 and string.find(tostring(err2), "released with :WeakUnsubscribe()", 1, true) ~= nil, "strict: weakly subscribed → error: " .. tostring(err2))
	assert(w.Subscribed == true, "…untouched")
	assert(o:Unsubscribe() == o and o.Subscribed == false and quad.Backend.canExecute(o) == false, "released both tables")
	local ok3 = pcall(function()
		o:Unsubscribe()
	end)
	assert(not ok3, "second Unsubscribe errors (strict)")
	s:Set(3)
	assert(calls == 2, "released observer is silent")
	print("PASS")
end

print()
print("=== 7. GC — 강한 구독은 참조를 안 들어도 산다, 약한 구독은 놓으면 수거 ===")
do
	local s = Source(1)
	local strongCalls, weakCalls = 0, 0
	local function make()
		s:Observer(function()
			strongCalls += 1
		end):Subscribe()
		s:Observer(function()
			weakCalls += 1
		end):WeakSubscribe()
	end
	make()
	collectgarbage()
	collectgarbage()
	strongCalls, weakCalls = 0, 0
	s:Set(2)
	assert(strongCalls == 1, "strongly subscribed observer survives with no references")
	assert(weakCalls == 0, "weakly subscribed observer was collected")
	print("PASS")
end

print()
print("=== 8. 파동 중 새 구독자 — 스냅샷 계약(다음 파동부터) + 인스턴스별 레지스트리 ===")
do
	local s = Source(1)
	local late: any = nil
	local lateCalls = 0
	s:Observer(function(_, _, from)
		if from ~= nil and late == nil then
			late = s:Observer(function(_, _, f)
				if f ~= nil then
					lateCalls += 1
				end
			end):Subscribe()
		end
	end):Subscribe()
	s:Set(2)
	assert(late ~= nil and lateCalls == 0, "subscriber added mid-wave is not visited in that wave")
	s:Set(3)
	assert(lateCalls == 1, "…but from the next wave")
	local other = Quad.NewModule()
	mock.installLifetime(other)
	local oo = other.Source(0):Observer(function() end)
	assert(getmetatable(oo :: any) ~= getmetatable(late :: any), "each quad instance has its own Observer impl (H-174)")
	print("PASS")
end

print()
print("=== 9a. H-332 — 재진입 파동(fn 안에서 자기 Source를 Set)이 바깥 fn 꼬리의 _running 가드를 풀지 않는다 — 관측, 계약 아님 ===")
do
	-- [2026-10-01] Observer가 자기 상류를 되먹이는 것은 UB(레퍼런스 core/05). 저장/복원(H-332)은 비용이 0이라 남긴
	-- 내부 동작이고, 이 절은 그 회귀 검사일 뿐 사용자에게 약속하는 동작이 아니다.
	local s = Source(1)
	local n = 0
	local tailErr: any = nil
	local o = s:Observer(function(_, self)
		n += 1
		if n == 2 then -- inside a real wave (the install fire is n = 1, before subscription)
			s:Set(3) -- reentrant wave: the nested _receive runs fn (n = 3) and returns
			local ok, err = pcall(function()
				(self :: any):Subscribe() -- outer fn's tail — the guard must still be up
			end)
			tailErr = if ok then "no error" else tostring(err)
		end
	end)
	o:Subscribe()
	s:Set(2)
	assert(n == 3, "reentrant wave ran the fn once more: " .. n)
	assert(string.find(tailErr, "inside its own fn", 1, true) ~= nil, "guard still up in the outer tail: " .. tostring(tailErr))
	print("PASS")
end

print()
print("=== 9. H-183 — fn은 자기 생명주기를 못 바꾼다(_running 가드, H-147 대칭); H-184 — 거부돼도 반쯤 묶이지 않음 ===")
do
	local s = Source(1)
	local inst = Instance.new("Frame")
	local subErr: any, bindErr: any = nil, nil
	local o = s:Observer(function(_, self)
		local ok, err = pcall(function()
			(self :: any):Subscribe()
		end)
		if not ok then
			subErr = tostring(err)
		end
		local ok2, err2 = pcall(function()
			quad.Backend.bindLifetime(inst, self)
		end)
		if not ok2 then
			bindErr = tostring(err2)
		end
	end)
	assert(subErr ~= nil and string.find(subErr, "inside its own fn", 1, true) ~= nil, "Subscribe inside the install fire errors: " .. tostring(subErr))
	assert(bindErr ~= nil and string.find(bindErr, "inside its own fn", 1, true) ~= nil, "bindLifetime inside the install fire errors: " .. tostring(bindErr))
	-- H-184: the refused bind committed NOTHING — the handle binds cleanly afterwards
	assert(quad.Backend.canBound(o), "not half-bound after the refusal")
	quad.Backend.bindLifetime(inst, o)
	assert(quad.Backend.canExecute(o), "binds cleanly after construction")
	-- _receive-time fn runs are guarded the same way
	local recvErr: any = nil
	local s3 = Source(0)
	local o3: any
	o3 = s3:Observer(function(_, self, from)
		if from ~= nil then
			local ok, err = pcall(function()
				(self :: any):WeakSubscribe()
			end)
			if not ok then
				recvErr = tostring(err)
			end
		end
	end)
	quad.Backend.bindLifetime(Instance.new("Frame"), o3)
	s3:Set(1)
	assert(recvErr ~= nil and string.find(recvErr, "inside its own fn", 1, true) ~= nil, "entry point inside a _receive fn errors: " .. tostring(recvErr))
	-- fn이 error로 죽으면 _running이 선 채 남는다 — 진입점은 막히지만 발화는 계속
	-- (오류 시 구조 깨짐은 설계상 인정 — 사용자 확정 2026-08-31)
	local s4 = Source(0)
	local fires = 0
	local o4: any = s4:Observer(function(_, _, from)
		fires += 1
		if from ~= nil then
			error("observer fn boom")
		end
	end)
	quad.Backend.bindLifetime(Instance.new("Frame"), o4)
	assert(not pcall(function()
		s4:Set(1)
	end), "the fn error propagates out of Set")
	assert(o4._running == true, "the flag stays up after an error")
	assert(not pcall(function()
		o4:Subscribe()
	end), "(re)subscribing refuses while the flag is up")
	-- round11 Q63 (b): releasing is NOT gated — a thrown-and-stuck handle can still be unsubscribed
	local s5 = Source(0)
	local o5: any = s5:Observer(function(_, _, from) if from ~= nil then error("boom") end end):Subscribe()
	assert(not pcall(function() s5:Set(1) end), "propagates")
	assert(o5._running == true, "stuck")
	o5:Unsubscribe()
	assert(o5.Subscribed == false, "released despite the stuck flag")
	local okAfter = pcall(function()
		s4:Set(2)
	end)
	assert(not okAfter and fires == 3, "firing itself is not gated by the flag (next Set still runs fn)")
	print("PASS")
end

print()
print()
print("=== 4순회 H-384 — fn 안에서 자기 자신을 drive로 바인드하려는 오용(H-147 (A)) — blame은 사용자의 Observer 생성 줄 (process → bindLifetime → _assertBindable, 최외곽) ===")
do
	local inst = mock.Instance.new("Frame")
	local ok, err = pcall(function()
		quad.Source(1):Observer(function(_, self)
			quad.Dispatch.drive(inst, { self })
		end)
	end)
	assert(not ok and string.find(tostring(err), "cannot bind an Observer from inside its own fn", 1, true) ~= nil, "guard fires: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.observer.luau", "drive-depth _assertBindable blames the user, not Observer.luau")
	print("PASS")
end

print()
print("=== 10. 설치 창 — 합류가 먼저라 설치 fn 도중 온 변경은 유실되지 않고 보류된다(그 자리에서 다시 돌지 않음); 묶이거나 구독될 때 한 번 반영 (round13 3′ Q73 + 2026-10-01) ===")
do
	-- 관측 — 계약 아님(트리거 쪽): 설치 창에 변경을 들이는 길은 그 fn 자신(이나 그 fn이 깨운 핸들)이 자기 상류를
	-- 되먹이는 것뿐이고 그건 Observer에게 UB다. 보류 자체는 "실행할 수 없을 때 온 변경은 보류, 묶일 때 한 번"
	-- (H-159)이고, 사용자 결정(2026-10-01): "설치 발화 중에 변경을 계속 받을 필요 없고 … pending 으로 끝날 수 있음.
	-- 설치 중 즉시 도는거 아님".
	-- (1) the install fn clamps its own target: fn runs once, the change is held, the bind replays it once
	local s = Source(50)
	local seen: { number } = {}
	local o = s:Observer(function(target)
		table.insert(seen, target:Get())
		if target:Get() > 10 then
			(target :: any):Set(10)
		end
	end)
	assert(table.concat(seen, ",") == "50", "the install run did not re-run in place: " .. table.concat(seen, ","))
	assert((o :: any)._rerunRequired == true, "the change is held")
	quad.Backend.bindLifetime(Instance.new("Frame"), o)
	assert(table.concat(seen, ",") == "50,10", "bind replays it once with the current value: " .. table.concat(seen, ","))
	assert((o :: any)._rerunRequired == false, "nothing held after the catch-up")
	-- …and Subscribe replays the same way
	local s1 = Source(0)
	local seen1: { number } = {}
	local o1 = s1:Observer(function(target)
		table.insert(seen1, target:Get())
		if target:Get() == 0 then
			(target :: any):Set(1)
		end
	end)
	assert(table.concat(seen1, ",") == "0", "install ran once: " .. table.concat(seen1, ","))
	o1:Subscribe()
	assert(table.concat(seen1, ",") == "0,1", "Subscribe replays the held change once: " .. table.concat(seen1, ","))
	o1:Unsubscribe()
	-- (2) ANOTHER handle Sets the target during the install run (the fn's side effect wakes a subscribed
	-- Observer on a different Source that writes back) — the old order (fire → join) lost it; now held
	local t, other = Source(0), Source(0)
	local back = other:Observer(function(_, _, from)
		if from ~= nil then
			t:Set(t:Get() + 1)
		end
	end):Subscribe()
	local seenT: { number } = {}
	local ot = t:Observer(function(target)
		table.insert(seenT, target:Get())
		if #seenT == 1 then
			other:Set(1)
		end
	end)
	assert(table.concat(seenT, ",") == "0" and t:Get() == 1, "a foreign Set during the install run did not re-run fn: " .. table.concat(seenT, ","))
	assert((ot :: any)._rerunRequired == true, "…it is held, not lost")
	ot:Subscribe()
	assert(table.concat(seenT, ",") == "0,1", "the first subscribe replays it: " .. table.concat(seenT, ","))
	ot:Unsubscribe()
	back:Unsubscribe()
	-- (3) an install fn that throws leaves the handle in `_subs` (weak-keyed): it keeps receiving but never
	-- runs — the throw left `_running` up (no pcall), so it is a thrown handle like any other: the
	-- subscribe entries refuse it; releasing it is dropping the reference
	local u = Source(0)
	local runs = 0
	local ou: any = nil
	local ok = pcall(function()
		ou = u:Observer(function()
			runs += 1
			if runs == 1 then
				error("install boom")
			end
		end)
	end)
	assert(not ok and runs == 1 and ou == nil, "the install throw propagates out of the constructor")
	local members = 0
	for h in (u :: any)._subs do
		members += 1
		ou = h
	end
	assert(members == 1, "the thrown handle stays in the subscriber set")
	u:Set(1)
	assert(runs == 1, "a change reaches it but does not run fn")
	assert(not pcall(function()
		ou:Subscribe()
	end), "a thrown install stays thrown: (re)subscribing refuses")
	print("PASS")
end

print()
print("=== 11. round13 3′ C6 (2026-09-30) — Source를 직접 보는 Observer는 중첩 파동에서 같은 리비전을 두 번 돌지 않는다(_seenRevision); 순서 의존이라 해시 순서를 흔들어 반복 ===")
do
	-- 2026-10-01: the nested wave comes from an Effect setting its own dep (defined — its re-run is deferred);
	-- an Observer feeding its own target is undefined, so that shape is not pinned here
	local twice = 0
	for trial = 1, 100 do
		local s = Source(0)
		local pad = {}
		for i = 1, trial % 7 do
			pad[i] = s:Observer(function() end):Subscribe()
		end
		local seen: { number } = {}
		local a = quad.Effect(function()
			if s:Get() == 1 then
				s:Set(2) -- nested wave inside the outer one
			end
		end, s):Subscribe()
		local b = s:Observer(function(target, _, from)
			if from ~= nil then
				table.insert(seen, target:Get())
			end
		end):Subscribe()
		s:Set(1)
		local count2 = 0
		for _, v in seen do
			if v == 2 then
				count2 += 1
			end
		end
		if count2 ~= 1 then
			twice += 1
		end
		a:Unsubscribe()
		b:Unsubscribe()
		for _, p in pad do
			p:Unsubscribe()
		end
	end
	assert(twice == 0, "the sibling saw revision 2 exactly once in every trial; failing trials: " .. twice)
	print("PASS")
end

print()
print("=== 12. round13 3′ Q109 (2026-09-30) — 파동 도중 형제 fn이 되살린 핸들(Observer·Effect, Source dep)은 같은 파동을 두 번 처리하지 않는다 ===")
do
	for _, kind in { "Observer", "Effect" } do
		for _, revive in { "Subscribe", "drive" } do
			local bad = 0
			for trial = 1, 200 do
				local src = Source(0)
				local pad = {}
				for i = 1, trial % 7 do
					pad[i] = src:Observer(function() end):Subscribe()
				end
				local runs = 0
				local sib: any
				if kind == "Observer" then
					sib = src:Observer(function()
						runs += 1
					end)
				else
					sib = quad.Effect(function()
						runs += 1
					end, src)
				end
				src:Set(1) -- held (the sibling is not alive yet)
				local host: any = nil
				local a = src:Observer(function(_, _, from)
					if from ~= nil and src:Get() == 2 and runs == 0 then
						if revive == "drive" then
							host = Instance.new("Frame")
							quad.Dispatch.drive(host, { sib })
						else
							sib:Subscribe()
						end
					end
				end):Subscribe()
				runs = 0
				src:Set(2)
				if runs ~= 1 then
					bad += 1
				end
				a:Unsubscribe()
				for _, p in pad do
					p:Unsubscribe()
				end
				if host ~= nil then
					host:Destroy()
				elseif (sib :: any).Subscribed then
					(sib :: any):Unsubscribe()
				end
			end
			assert(bad == 0, `{kind} revived by {revive}: ran once per wave in every trial; failing trials: {bad}`)
		end
	end
	print("PASS")
end

print()
print("=== 13. round13 3′ (2026-09-30) — 두 기록 규약(Observer의 _seenRevision 숫자 / Effect의 _epochs 맵 항목)은 같은 뜻: 같은 Source, 같은 시나리오에서 실행 횟수·본 값이 같다 ===")
do
	-- one builder per kind; `body(read)` is the shared fn body (reads the Source, may write it)
	local function make(kind: string, src: any, body: (number) -> ()): any
		if kind == "Observer" then
			return src:Observer(function(target)
				body(target:Get())
			end)
		end
		return quad.Effect(function()
			body(src:Get())
		end, src)
	end
	local function scenario(kind: string, name: string): string
		local seen: { number } = {}
		if name == "install" then -- the install run Sets its own dep once
			local src = Source(0)
			make(kind, src, function(v)
				table.insert(seen, v)
				if v == 0 then
					src:Set(1)
				end
			end)
		elseif name == "clamp" then -- subscribed; a Set that the fn clamps back (converging self-write)
			local src = Source(0)
			local h = make(kind, src, function(v)
				table.insert(seen, v)
				if v > 10 then
					src:Set(10)
				end
			end):Subscribe()
			src:Set(50)
			h:Unsubscribe()
		elseif name == "held" then -- two changes while unexecutable, then Subscribe outside any wave
			local src = Source(0)
			local h = make(kind, src, function(v)
				table.insert(seen, v)
			end)
			src:Set(1)
			src:Set(2)
			h:Subscribe()
			src:Set(3)
			h:Unsubscribe()
		elseif name == "revive" then -- revived mid-wave by a sibling (hash order varies per trial):
			-- the number of trials whose wave did not run fn exactly once with the new value
			local bad = 0
			for trial = 1, 100 do
				local src = Source(0)
				local pad = {}
				for i = 1, trial % 7 do
					pad[i] = src:Observer(function() end):Subscribe()
				end
				local wave: { number } = {}
				local h = make(kind, src, function(v)
					table.insert(wave, v)
				end)
				src:Set(1)
				local a = src:Observer(function(_, _, from)
					if from ~= nil and not h.Subscribed then
						h:Subscribe()
					end
				end):Subscribe()
				table.clear(wave)
				src:Set(2)
				if table.concat(wave, ",") ~= "2" then
					bad += 1
				end
				a:Unsubscribe()
				h:Unsubscribe()
				for _, p in pad do
					p:Unsubscribe()
				end
			end
			table.insert(seen, bad)
		end
		return table.concat(seen, ",")
	end
	-- 2026-10-01: "install"/"clamp" are an fn writing its own dep — defined for an Effect (deferred re-run),
	-- undefined for an Observer (own-upstream feedback). Compared on the defined scenarios only; the
	-- Effect side of the other two is pinned, the Observer side is not
	local expected = { held = "0,2,3", revive = "0" }
	for _, name in { "held", "revive" } do
		local o, e = scenario("Observer", name), scenario("Effect", name)
		assert(o == e, `{name}: Observer saw [{o}] but Effect saw [{e}]`)
		assert(o == expected[name], `{name}: both saw [{o}], expected [{expected[name]}]`)
	end
	assert(scenario("Effect", "install") == "0,1", "Effect install: the own-dep Set re-runs (deferred)")
	assert(scenario("Effect", "clamp") == "0,50,10", "Effect clamp: deferred re-run settles")
	print("PASS")
end

print("=== 14. 2026-10-01 — Observer 자기 상류 되먹임 debug 감지기: q.debug일 때만 Observer마다 한 줄(던지지 않음); 정상 경로·내부 Observer는 0줄 ===")
do
	local LINE = "Observer: a change reached this Observer while its own fn was running"
	local lines: { string } = {}
	local dq = mock.newQuad()
	-- every `q.debug` line leaves through DebugPrint.luau — capture that module's env
	local env: any = getfenv(dq._debugPrint)
	local function capture(f: () -> ())
		table.clear(lines)
		local old = rawget(env, "print")
		env.print = function(...: any)
			table.insert(lines, table.concat({ ... }, " "))
		end
		local ok, err = pcall(f)
		env.print = old
		assert(ok, tostring(err))
	end
	local function countOf(needle: string): number
		local n = 0
		for _, l in lines do
			if string.find(l, needle, 1, true) ~= nil then
				n += 1
			end
		end
		return n
	end
	local function feedback(qq: any): any
		-- a subscribed Observer that clamps its own target on every change: a nested run (UB)
		local s = qq.Source(0)
		local o = s:Observer(function(target)
			if target:Get() > 3 then
				(target :: any):Set(3)
			end
		end):Subscribe()
		s:Set(5)
		s:Set(7)
		o:Unsubscribe()
		return s
	end
	-- off: zero lines (the run itself is unchanged — not asserted beyond "no line")
	capture(function()
		feedback(dq)
	end)
	assert(countOf(LINE) == 0, "debug off: no line")
	-- on: one line per Observer, though it nested twice
	dq.debug = true
	capture(function()
		feedback(dq)
	end)
	assert(countOf(LINE) == 1, "debug on: one line per Observer: " .. table.concat(lines, " | "))
	-- normal paths stay silent: setting OTHER targets, an Effect downstream writing its upstream, a thrown
	-- fn's stuck `_running` on the next change (the `q.Out`/`OnChange` round trip involves no user Observer — the property
	-- binding's handle is StateHandler's, marked `_internal`; a debug-forced test.sh run on 2026-10-01 printed no line for it)
	capture(function()
		local a, b = dq.Source(0), dq.Source(0)
		local oa = a:Observer(function(target)
			b:Set((target:Get() :: number) * 2) -- another target: normal
		end):Subscribe()
		local ob = b:Observer(function() end):Subscribe()
		a:Set(1)
		a:Set(2)
		oa:Unsubscribe()
		ob:Unsubscribe()
		-- Effect downstream writes its own upstream (defined — deferred re-run)
		local c = dq.Source(5)
		local e = dq.Effect(function()
			if c:Get() > 3 then
				c:Set(3)
			end
		end, c):Subscribe()
		c:Set(9)
		e:Unsubscribe()
		-- a thrown fn leaves `_running` up; the next change runs it again (self-healing) — not a nested run
		local d = dq.Source(0)
		local od = d:Observer(function(_, _, from)
			if from ~= nil and d:Get() == 1 then
				error("boom")
			end
		end):Subscribe()
		assert(not pcall(function()
			d:Set(1)
		end))
		d:Set(2)
		od:Unsubscribe()
	end)
	assert(countOf(LINE) == 0, "normal paths: no line: " .. table.concat(lines, " | "))
	-- quad's own Observers (`_internal`) are skipped: the same feedback shape on a marked handle is silent
	capture(function()
		local s = dq.Source(0)
		local o = s:Observer(function(target)
			if target:Get() > 3 then
				(target :: any):Set(3)
			end
		end)
		;(o :: any)._internal = true
		o:Subscribe()
		s:Set(5)
		o:Unsubscribe()
	end)
	assert(countOf(LINE) == 0, "an `_internal` handle is skipped")
	-- 2026-10-01 (user decision): a callback on a Slot's `Length`/`Offset` that CRUDs a Slot so the value
	-- moves again goes through the bookkeeping recompute (the Slot settles it) — defined, no line. Both
	-- shapes nest this handle's run (measured: each printed before the bookkeeping skip existed).
	capture(function()
		local Instance = mock.Instance
		-- (1) Length of sB, CRUD inside it (a header that depends on the list's length)
		local p1 = Instance.new("Frame")
		local sB, sA = dq.Slot(), dq.Slot()
		sB:Add(sA)
		dq.Dispatch.drive(p1, { sB })
		local o1 = sB.Length:Observer(function(len)
			if (len:Get() :: number) < 3 then
				sA:Add(Instance.new("Frame"))
			end
		end)
		dq.Backend.bindLifetime(p1, o1)
		sA:Add(Instance.new("Frame"))
		assert(sB.Length:Get() >= 3, "the Length loop settled")
		-- (2) Offset of sB, CRUD on the sibling before it (a heading / grid cell)
		local p2 = Instance.new("Frame")
		local hA, hB = dq.Slot(), dq.Slot()
		hB:Add(Instance.new("Frame"))
		dq.Dispatch.drive(p2, { hA, hB })
		local o2 = hB.Offset:Observer(function(off)
			if (off:Get() :: number) < 2 then
				hA:Add(Instance.new("Frame"))
			end
		end)
		dq.Backend.bindLifetime(p2, o2)
		hA:Add(Instance.new("Frame"))
		assert(hB.Offset:Get() >= 2, "the Offset loop settled")
		dq.Backend.unbindLifetime(o1)
		dq.Backend.unbindLifetime(o2)
		p1:Destroy()
		p2:Destroy()
	end)
	assert(countOf(LINE) == 0, "a loop routed through the Slot bookkeeping is skipped: " .. table.concat(lines, " | "))
	-- round14 `H-886`: the same rule for the mount/re-seat write — an Offset callback that re-seats its own
	-- Slot (Extract + Add) reaches the Offset Source through `setOffsetSource`, not `recompute`; skipped too
	capture(function()
		local Instance = mock.Instance
		local host = Instance.new("Frame")
		local I = dq.Slot({ Instance.new("Frame") })
		local S = dq.Slot({ Instance.new("Frame"), Instance.new("Frame"), I })
		dq.Dispatch.drive(host, { S })
		local depth, nested = 0, 0
		local o = I.Offset:Observer(function(off)
			depth += 1
			if depth > 1 then
				nested += 1
			end
			if off:Get() == 1 then
				S:Extract(S:IndexOf(I) :: number)
				S:Add(I)
			end
			depth -= 1
		end):Subscribe()
		S:Move(S:IndexOf(I) :: number, 2)
		assert(nested > 0, "the scene really nests this handle's run (else it proves nothing)")
		o:Unsubscribe()
		host:Destroy()
	end)
	assert(countOf(LINE) == 0, "a re-seat through setOffsetSource is skipped: " .. table.concat(lines, " | "))
	print("PASS")
end

print()
print("=== 14b. round14 (2026-10-06) — 되먹임 감지기를 보류 갈래(설치 창)에도; quad 내부 Observer는 설치 전부터 `_internal`; StateHandler의 Observer는 내부 아님(Q174) ===")
do
	local LINE = "Observer: a change reached this Observer while its own fn was running"
	local lines: { string } = {}
	local dq = mock.newQuad()
	local env: any = getfenv(dq._debugPrint)
	local function capture(f: () -> ())
		table.clear(lines)
		local old = rawget(env, "print")
		env.print = function(...: any)
			table.insert(lines, table.concat({ ... }, " "))
		end
		local ok, err = pcall(f)
		env.print = old
		assert(ok, tostring(err))
	end
	local function countOf(needle: string): number
		local n = 0
		for _, l in lines do
			if string.find(l, needle, 1, true) ~= nil then
				n += 1
			end
		end
		return n
	end
	local function clampOnce(target: any)
		if (target:Get() :: number) > 10 then
			target:Set(10) -- the install fn writes its own target once and stops (a clamp)
		end
	end
	-- the install window: the change is held (no nested run), still a feedback — one line with debug on
	dq.debug = false
	capture(function()
		local s = dq.Source(20)
		local o = s:Observer(clampOnce)
		o:Subscribe() -- replays the held change once
		assert(s:Get() == 10)
		o:Unsubscribe()
	end)
	assert(countOf(LINE) == 0, "debug off: no line")
	dq.debug = true
	capture(function()
		local s = dq.Source(20)
		local o = s:Observer(clampOnce)
		o:Subscribe()
		o:Unsubscribe()
	end)
	assert(countOf(LINE) == 1, "install-window feedback: one line: " .. table.concat(lines, " | "))
	-- quad's own handles are marked before their install run — the same shape is silent
	capture(function()
		local s = dq.Source(20)
		local o = (s :: any):_internalObserver(clampOnce)
		o:Subscribe()
		o:Unsubscribe()
	end)
	assert(countOf(LINE) == 0, "an internal handle's install window is skipped: " .. table.concat(lines, " | "))
	-- Q174: a State placed in props — its handler's Observer is not internal; a Ref callback its dispatch
	-- set off writes the State back during the install (Q5 — undefined): one line
	capture(function()
		local inst = mock.Instance.new("Frame")
		local r = dq.Ref(nil :: any)
		local src = dq.Source(r)
		local once = true
		r:Callback(function(v)
			if v ~= nil and once then
				once = false
				src:Set(r)
			end
		end)
		dq.Dispatch.drive(inst, { src })
		inst:Destroy()
	end)
	assert(countOf(LINE) == 1, "StateHandler's Observer is checked: " .. table.concat(lines, " | "))
	-- a `:List` over a State data and a Slot's Length/Offset plumbing mount silently (internal from birth)
	capture(function()
		local Instance = mock.Instance
		local host = Instance.new("Frame")
		local data = dq.Source({ 1, 2 })
		local sl = dq.Slot()
		sl:List(data, function(ctx)
			return if ctx.Item == dq.KeyGone then nil else Instance.new("Frame")
		end, function(item)
			return item
		end)
		local inner = dq.Slot({ Instance.new("Frame") })
		dq.Dispatch.drive(host, { sl, inner })
		data:Set({ 1, 2, 3 })
		host:Destroy()
	end)
	assert(countOf(LINE) == 0, "quad's own Observers stay silent: " .. table.concat(lines, " | "))
	print("PASS")
end

print()
print("=== 15. round14 Q154 — 게이트 아래의 Observer는 flush 통지를 받는다(Q109의 건너뜀은 Source가 직접 보낸 통지에만 적용): Gate 바로 아래 / 그 아래 Compute / Blocker 아래 ===")
-- Contract: a gate holds emits and hands them on at flush (core/03 `state:Gate`, sugar/06 Blocker) — an
-- Observer subscribed below it runs on every flush. Q109's "already ran on this revision" skip is for a
-- delivery a Source makes itself (`Observer.luau` `_receive`). Mutant (round14 explore E, O03): the
-- `from == self._state` half of that test dropped — every flush below a gate was discarded.
do
	-- a gate that passes while `open`, holds otherwise; `flush()` hands on what it held
	local function switchGate(upstream: any): (any, { open: boolean, flush: () -> () })
		local ctl = { open = true, flush = function() end }
		local gated = upstream:Gate(function(emit: (boolean?) -> boolean): () -> ()
			ctl.flush = function()
				emit()
			end
			return function()
				if ctl.open then
					emit()
				end
			end
		end)
		return gated, ctl
	end
	-- directly below the gate, and one Compute further down
	local s = Source(10)
	local gated, ctl = switchGate(s)
	local doubled = gated:Compute(function(self: any): number
		return self:Get() * 2
	end)
	local direct: { number } = {}
	local derived: { number } = {}
	local o1 = gated:Observer(function(target: any)
		table.insert(direct, target:Get() :: number)
	end):Subscribe()
	local o2 = doubled:Observer(function(target: any)
		table.insert(derived, target:Get() :: number)
	end):Subscribe()
	ctl.open = false
	s:Set(20)
	assert(#direct == 1 and #derived == 1, "held: nothing ran while the gate was closed")
	ctl.flush()
	assert(table.concat(direct, ",") == "10,20", "the flush reached the Observer below the gate: " .. table.concat(direct, ","))
	assert(table.concat(derived, ",") == "20,40", "…and the one below a Compute of it: " .. table.concat(derived, ","))
	ctl.open = true
	s:Set(30)
	assert(table.concat(direct, ",") == "10,20,30" and table.concat(derived, ",") == "20,40,60", "an open gate passes each change on: " .. table.concat(direct, ",") .. " / " .. table.concat(derived, ","))
	o1:Unsubscribe()
	o2:Unsubscribe()
	-- the Blocker sugar: On holds, Off flushes once, then it passes again
	local src = Source(1)
	local blocker = quad.Blocker()
	local seen: { number } = {}
	local o3 = src:Apply(blocker):Observer(function(target: any)
		table.insert(seen, target:Get() :: number)
	end):Subscribe()
	blocker:On()
	src:Set(4)
	src:Set(5)
	assert(#seen == 1, "blocked: nothing ran")
	blocker:Off()
	assert(table.concat(seen, ",") == "1,5", "Off flushed once, with the latest value: " .. table.concat(seen, ","))
	src:Set(6)
	assert(table.concat(seen, ",") == "1,5,6", "passes again: " .. table.concat(seen, ","))
	o3:Unsubscribe()
	print("PASS")
end

print()
print("=== ALL PASS ===")
