-- ── round13 Q154 (a) 초안 — E73 변이 공백(quad-roblox `LifetimeHandle.luau` hold op). 대상 파일 끝의
-- `print("=== ALL PASS ===")` 바로 앞에 넣는다. 대상 파일의 지역 이름 `q`(any), `Instance`를 쓴다.

print()
print("=== 9. hold op·isClaimed는 순수 술어 — nil에는 던지지 않고 거짓, 한 번도 묶이지 않은 값과 claim 안 된 인스턴스의 isHeldBy도 거짓 ===")
-- 계약: docs/reference/extend/01-backend-provider-contract.md §4 `isHeld`("순수 술어입니다: 던지지 말고, `nil`에는 거짓"),
-- `isHeldBy`("`value`를 쥔 것이 바로 이 `inst`인가"), §3 표의 `isClaimed (inst: any) -> boolean`(nil 게이트는
-- `LifetimeHandle.luau` isClaimed 머리 — `H-444` 계열; 문서가 nil을 따로 적지는 않는다). 변이: E73 LR03(isClaimed의 nil 게이트
-- 삭제 → Relate Quad0138), LR06(isHeld의 nil 게이트 삭제 → Quad0138), LR08(isHeldBy의 `held ~= nil and ` 제거 → nil == nil로 참).
do
	local ok1, v1 = pcall(function()
		return q.Backend.isClaimed(nil)
	end)
	assert(ok1 and v1 == false, "isClaimed(nil) is false, not a raise: " .. tostring(v1))
	local ok2, v2 = pcall(function()
		return q.Backend.isHeld(nil)
	end)
	assert(ok2 and v2 == false, "isHeld(nil) is false, not a raise: " .. tostring(v2))
	local unclaimed = Instance.new("Folder") -- never nativeClaim'd under the real provider
	assert(q.Backend.isHeldBy({}, unclaimed) == false, "never-bound value vs unclaimed inst: false")
	print("PASS")
end

print()
print("=== 10. bindLifetime은 값을 인스턴스만큼 살린다(GC 뒤에도 발화); unbindLifetime은 즉시 놓는다(isHeldBy 거짓, 인스턴스가 살아 있어도 수거 가능) ===")
-- 계약: docs/reference/extend/01-backend-provider-contract.md §4 `holdLifetime`("`inst`가 사는 동안 `value`가 GC되지 않게"),
-- `releaseLifetime`("홀더에서 `value`를 빼고 남긴 근거를 지웁니다"). 변이: E73 LR10(`gchold[value] = true` 삭제 → 묶인 Observer가
-- GC로 사라져 무발화), LR12(`gchold[value] = nil` 삭제 → 인스턴스가 죽을 때까지 붙잡힘), LR13(근거 `gchold` 삭제 누락 → isHeldBy 참).
do
	local gcFull = (_G :: any).collectgarbage :: (string) -> ()
	local inst = Instance.new("Folder")
	q.Backend.nativeClaim(inst)
	local src = q.Source(0)
	local fired = 0
	do
		local o = src:Observer(function()
			fired += 1
		end)
		q.Backend.bindLifetime(inst, o)
	end
	gcFull("collect")
	gcFull("collect")
	local f0 = fired
	src:Set(1)
	assert(fired == f0 + 1, "the bound Observer survived GC (held by the inst) and fired: " .. (fired - f0))

	local weak = setmetatable({}, { __mode = "v" }) :: any
	do
		local o2 = src:Observer(function() end)
		q.Backend.bindLifetime(inst, o2)
		assert(q.Backend.isHeldBy(o2, inst), "held by this inst after bind")
		q.Backend.unbindLifetime(o2)
		assert(not q.Backend.isHeldBy(o2, inst), "no longer held by this inst after unbind")
		weak[1] = o2
	end
	gcFull("collect")
	gcFull("collect")
	assert(weak[1] == nil, "an unbound value is collectible while the inst lives (early release)")
	inst:Destroy()
	print("PASS")
end
