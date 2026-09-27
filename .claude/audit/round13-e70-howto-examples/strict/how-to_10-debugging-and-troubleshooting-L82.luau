--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L82
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local myRef = q.PreRef<<Frame?>>(nil)
local __host = D.Frame { myRef }
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:82 ====
-- ✅ 이미 있으면 즉시, 없으면 다음 채워짐을 대기
local inst = if myRef.Value then myRef.Value else myRef:Wait().Value
