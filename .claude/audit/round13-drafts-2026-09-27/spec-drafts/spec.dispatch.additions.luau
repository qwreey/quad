-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `newQuad`, `Instance`를 쓴다.

print()
print("=== 22. process의 index가 체인의 다음 깊이(#list + 1)를 넘으면 Quad0075 ===")
-- 계약: docs/reference/errors/02-dispatch-bookkeeping.md Quad0075, docs/reference/extend/02-dispatch-handler-contract.md
-- `q.Dispatch.process(inst, key, value, index)`. 변이: E69 DI07(`index > #list + 1` → `+ 2`, 빈 체인에 구멍).
do
	local q = newQuad()
	local ok, err = pcall(function()
		q.Dispatch.process(Instance.new("Frame"), 1, q.Tag("a"), 2)
	end)
	assert(not ok and string.find(tostring(err), "Quad0075", 1, true) ~= nil, "gap in the chain: " .. tostring(err))
	print("PASS")
end

print()
print("=== 23. 같은 핸들러 재처리에서 process가 던지면 그 자리는 no-op 표식으로 남는다 — 이후 철거가 옛 retractor를 다시 부르지 않는다 ===")
-- 계약: docs/reference/extend/02-dispatch-handler-contract.md "한계와 주의"(`process`가 던지면 "그 자리의 슬롯은 no-op 표식을 단 채 남고,
-- 명시적 철거로도 복구되지 않습니다"). 변이: E69 DI10(`slot.retractor = NOOP` 삭제 → 옛 retractor 두 번).
do
	local q = newQuad()
	local calls = 0
	local fail = false
	q.Dispatch.addHandler({
		name = "SpecE69DI10",
		keyType = "string",
		priority = q.Dispatch.HANDLER_PRIORITY_HIGH + 7,
		isHandlable = function(_i: any, k: any): boolean
			return k == "SpecE69DI10"
		end,
		process = function(_i: any, _k: any, _v: any, _idx: number): any
			if fail then
				error("boom")
			end
			return function()
				calls += 1
			end
		end,
	})
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "SpecE69DI10", 1, 1)
	fail = true
	assert(not pcall(function()
		q.Dispatch.process(inst, "SpecE69DI10", 2, 1)
	end), "the second process throws")
	assert(calls == 1, "the seated retractor got the new value once before process ran: " .. calls)
	q.Dispatch.retractFrom(inst, "SpecE69DI10", 1)
	assert(calls == 1, "explicit retract must not call the consumed retractor again: " .. calls)
	print("PASS")
end
