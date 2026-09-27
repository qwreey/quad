--!nocheck
-- E70 probe: how-to 06 §2 산문 "프로바이더가 아예 없는 채로 그 원천에 다시 :Set을 부르면 … Quad0108 … 그 자리에서 던집니다"
local H = require("../harness")
local Quad = H.Quad.New() -- 프로바이더 없는 새 인스턴스(문서의 require(quad_base) 기본 인스턴스 대역)
local hp = Quad.Source(100)
local runs = 0
local ok0, e0 = pcall(function() return hp:Observer(function() runs += 1 end) end)
print("register ok", ok0, "runs", runs)
local ok, e = pcall(function() hp:Set(90) end)
print("Set ok", ok, (tostring(e):gsub("\n.*", "")))
print("value after throw", hp:Get(), "runs", runs)
-- 대조: Observer 없는 원천의 Set은 문제 없다
local s = Quad.Source(1); s:Set(2); print("plain set", s:Get())
