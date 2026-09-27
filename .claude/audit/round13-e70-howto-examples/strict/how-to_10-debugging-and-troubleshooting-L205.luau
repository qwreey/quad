--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L205
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local items = q.Source({ "a", "b" })
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:205 ====
-- ❌ 수동으로 시작했다가 나중에 :List로 갈아타기
local s = q.Slot()
s:Add(D.Frame {})
s:List(items, function(ctx) return D.Frame { Text = ctx.Item } end) -- 에러

-- ✅ 데이터 배열이 있다면 처음부터 :List
local s2 = q.Slot()
s2:List(items, function(ctx) return D.Frame { Text = ctx.Item } end)
