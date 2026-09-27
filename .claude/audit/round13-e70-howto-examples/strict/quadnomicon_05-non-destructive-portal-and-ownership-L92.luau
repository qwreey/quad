--!strict
-- E70 strict (generated) — quadnomicon_05-non-destructive-portal-and-ownership-L92
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (quadnomicon_05-non-destructive-portal-and-ownership-L34) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local myInstanceState = q.Source<<Instance?>>(nil)
-- ==== doc block quadnomicon/05-non-destructive-portal-and-ownership.md:92 ====
D.Frame {
    q.Slot<<Instance>> { myInstanceState }, -- 맨 State 요소는 Slot():Single(state, nil, { OwnsElements = false })로 감싸진다
}
