--!strict
-- E58 strict (generated) — roblox_02-d-L287
-- ==== page prologue roblox/02-d.md (roblox_02-d-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block roblox/02-d.md:287 (line offset marker) ====
local frameRef = q.Ref<<Frame?>>(nil)
local labelRef = q.Ref<<TextLabel?>>(nil)

D.Frame({ frameRef })  -- OK
D.Frame({ labelRef })  -- 타입 에러: 형제 클래스의 Ref는 거부된다
