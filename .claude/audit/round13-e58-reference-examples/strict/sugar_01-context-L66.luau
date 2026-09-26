--!strict
-- E58 strict (generated) — sugar_01-context-L66
-- ==== page prologue sugar/01-context.md (sugar_01-context-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block sugar/01-context.md:66 (line offset marker) ====
type Theme = { ButtonBg: Color3 }

-- (1) 캐스트
local ThemeProvider = q.Context.Provider("Theme") :: q.Provider<Theme>
-- (2) 명시적 타입 인자
local UserProvider = q.Context.Provider<<{ Name: string }>>("User")
