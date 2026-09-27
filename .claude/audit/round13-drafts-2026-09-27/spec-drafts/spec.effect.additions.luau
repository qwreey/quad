-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `mock`만 쓰고, 디스패치가 필요해 절마다 `mock.newQuad()`로 따로 만든다.

print()
print("=== 13. 같은 Effect(와 Observer)를 같은 인스턴스의 같은 자리로 다시 drive하면 접힌다 — 에러·cleanup·재실행 없음 ===")
-- 계약: .claude/base/source-state-plan.md "Observer/Effect Leaf dedup"(`H-266` — `old ~= v` dedup은 load-bearing),
-- docs/reference/extend/02-dispatch-handler-contract.md(같은 핸들러가 같은 자리를 계속 맡으면 앉은 retractor에 새 값을 넘김).
-- 변이: E69 EF17(Effect.luau `if old ~= v` 항상 참 → Quad0232), EF18(retractor의 `nextValue ~= v` 항상 참 → cleanup+재실행).
do
	local q = mock.newQuad()
	local inst = mock.Instance.new("Frame")
	local s = q.Source(0)
	local runs, cleans = 0, 0
	local e = q.Effect(function()
		runs += 1
		return function()
			cleans += 1
		end
	end, s)
	local o = s:Observer(function() end)
	q.Dispatch.drive(inst, { e, o })
	local r0 = runs
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { e, o })
	end)
	assert(ok, "re-drive of the same Effect/Observer raised: " .. tostring(err))
	assert(cleans == 0 and runs == r0, "re-drive ran cleanup/fn: cleans " .. cleans .. ", runs " .. runs - r0)
	assert(not q.Backend.canBound(e) and not q.Backend.canBound(o), "still bound after the re-drive")
	s:Set(1)
	assert(runs == r0 + 1 and cleans == 1, "one normal rerun after a dep change")
	print("PASS")
end

print()
print("=== 14. Effect:WeakSubscribe를 두 번 부르면 Quad0089 ===")
-- 계약: docs/reference/errors/04-ref-observer-effect.md Quad0089("`:WeakSubscribe()`를 두 번 불러도 이 에러").
-- 변이: E69 EF11(Effect.luau `canBound` 게이트 삭제).
do
	local q = mock.newQuad()
	local e = q.Effect(function() end)
	e:WeakSubscribe()
	local ok, err = pcall(function()
		e:WeakSubscribe()
	end)
	assert(not ok and string.find(tostring(err), "Quad0089", 1, true) ~= nil, "double WeakSubscribe: " .. tostring(err))
	e:WeakUnsubscribe()
	print("PASS")
end
