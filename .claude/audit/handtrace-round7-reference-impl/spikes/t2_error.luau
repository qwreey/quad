--!nocheck
local q = require("./core")
local A = q.Source(1)
local B = q.State(function(self, prev, a) return a:Get() end, {A}, "B")
local C = q.State(function(self, prev, a) return a:Get() end, {A}, "C")
-- B 아래에 터지는 Observer, C 아래에 멀쩡한 Observer
local bad = q.Observer(B, function() error("사용자 콜백 실패") end, "O_bad")
local goodSeen = {}
local good = q.Observer(C, function() table.insert(goodSeen, C:Get()) end, "O_good")

print("-- A:Set(2) (전파 중 O_bad가 error) --")
local ok, err = pcall(function() A:Set(2) end)
print("Set이 던졌는가:", not ok, "|", err)
print("O_bad 발화:", bad.fires, "| O_good 발화:", good.fires, "| 관측:", table.concat(goodSeen, ","))
print("C의 값은 자가치유되는가: C:Get() =", C:Get(), "(정상)")
print("하지만 O_good은 이 변경에 대해 영원히 안 울었다:", good.fires)

print("-- 이후 A:Set(3)은 정상인가 --")
local ok2 = pcall(function() A:Set(3) end)
print("두 번째 Set도 같은 자리에서 던짐:", not ok2, "| O_good 발화:", good.fires)

print("-- O_bad를 제거하고(구독 해제 없이 새 파동) --")
B.subs[bad] = nil
A:Set(4)
print("O_good 발화:", good.fires, "| 관측:", table.concat(goodSeen, ","))
print("→ 2와 3에 대한 통지는 영영 오지 않았다. 마지막 값만 보임")
