--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L64
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local RobloxModule = require("../../../../quad-roblox/src")
local props: { Modifier: RobloxModule.FrameModifier?, Ref: q.Ref<Frame?>? } = {}
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:64 ====
-- ❌ props.Modifier가 nil이면 배열에 구멍이 생긴다
D.Frame { props.Modifier, props.Ref, Size = UDim2.new() }

-- ✅
D.Frame { props.Modifier or q.None, props.Ref or q.None, Size = UDim2.new() }
