--!strict
-- E58 strict (generated) — roblox_02-d-L261
-- ==== page prologue roblox/02-d.md (roblox_02-d-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E58 보강 pre]]
local props: { Modifier: any?, Child: Instance? } = {}
-- ==== doc block roblox/02-d.md:261 (line offset marker) ====
D.Frame({
	props.Modifier or q.None,
	props.Child or q.None,
})
