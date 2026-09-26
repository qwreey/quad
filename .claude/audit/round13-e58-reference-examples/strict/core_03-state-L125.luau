--!strict
-- E58 strict (generated) — core_03-state-L125
-- ==== page prologue core/03-state.md (core_03-state-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/03-state.md:125 (line offset marker) ====
local text = q.Source("hello")
local locale = q.Source("ko")

-- text의 값 그대로, 다만 locale이 바뀌어도 다시 흐른다
local shown: q.State<string> = text:Depend(locale)
print(shown:Get()) --> hello
