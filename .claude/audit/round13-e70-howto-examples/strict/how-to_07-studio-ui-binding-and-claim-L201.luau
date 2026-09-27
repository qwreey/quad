--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L201
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:201 ====
M.Frame("Footer")({})   -- 자리는 채우되, 이 아래로는 내려가지 않는다
