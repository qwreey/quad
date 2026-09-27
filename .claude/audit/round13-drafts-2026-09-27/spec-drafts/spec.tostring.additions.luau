-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.

print()
print("=== 5. 구독을 푼 Observer는 Observer(unsubscribed) — 강한 구독을 :Unsubscribe로, 약한 구독을 :WeakUnsubscribe로 풀었든 ===")
-- 계약: .claude/base/architecture.md `__tostring` 목록(`Observer(subscribed|weak|unsubscribed)`).
-- 변이: E69 OB06(Observer:Unsubscribe의 `WeakSubscribed[self] = nil` 삭제 → 강한 구독을 푼 뒤 `Observer(weak)`).
do
	local q = newQuad()
	local s = q.Source(0)
	local weak = s:Observer(function() end)
	weak:WeakSubscribe()
	weak:WeakUnsubscribe()
	assert(tostring(weak) == "Observer(unsubscribed)", "after WeakSubscribe → WeakUnsubscribe: " .. tostring(weak))
	local strong = s:Observer(function() end)
	strong:Subscribe()
	strong:Unsubscribe()
	assert(tostring(strong) == "Observer(unsubscribed)", "after Subscribe → Unsubscribe: " .. tostring(strong))
	print("PASS")
end
