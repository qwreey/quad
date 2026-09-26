--!strict
-- E58 strict (generated) — core_03-state-L162
-- ==== page prologue core/03-state.md (core_03-state-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/03-state.md:162 (line offset marker) ====
local raw = q.Source(0)
local blocker = q.Blocker()
local gated: q.State<number> = raw:Apply(blocker)
