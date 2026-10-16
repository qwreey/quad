--!strict
-- [P5b] CLI 전용(Studio에 올리지 않음 — ProbeButton은 shim.d.luau에만 있다). Studio처럼 이벤트가 extern
-- 시그널일 때 Lib의 callbackOf()가 properties() 경로로 콜백을 꺼내는지.
-- 실행: harness/run-cli.sh vsc --definitions=@shim=harness/extern-shim/shim.d.luau harness/extern-shim/05b-extern-events.luau
local L = require("../../src/Lib")

type R = L.Report<ProbeButton>
local PB = L.New<<ProbeButton>>("ProbeButton")
local ok = PB({ Label = "x", Clicked = function(n, s) end, Activated = function(input, count) end })
local bad = PB({ Clicked = function(n: string) end }) -- 에러여야 정상(콜백 1번 인자 number)
local ev = L.OnEventIn<<ProbeButton>>("Clicked", function(n, s)
	local _: string = n -- 에러여야 정상(n은 number로 추론)
end)
return { ok, bad, ev }
