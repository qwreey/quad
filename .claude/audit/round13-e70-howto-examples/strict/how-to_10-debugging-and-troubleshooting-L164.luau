--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L164
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:164 ====
local theme = q.Source({ Primary = "red", Size = 10 })
local primary: q.State<string> = theme:Apply(q.Operator.Indexed<<string>>("Primary"))
-- theme:Set({ Primary = "blue", Size = 12 }) → primary:Get() == "blue"
