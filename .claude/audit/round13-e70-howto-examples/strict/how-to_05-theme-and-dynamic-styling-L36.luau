--!strict
-- E70 strict (generated) — how-to_05-theme-and-dynamic-styling-L36
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_05-theme-and-dynamic-styling-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoTextButton` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/05-theme-and-dynamic-styling.md:36 ====
-- (가방으로 내리는 모양 — 이 문서의 나머지 절은 층이 얕아 모듈을 직접 참조합니다)
local Theme = require("./Theme")
local ThemeProvider = q.Context.Provider<<typeof(Theme)>>("Theme") -- 타입 인자를 주면 :Get 결과에 타입이 붙는다

-- 앱 진입점에서 한 번(Theme은 §2에서 만드는 토큰 모듈)
local ctx = q.Context():Set(ThemeProvider, Theme)

-- 아래 어딘가에서
local theme = ctx:Get(ThemeProvider)   -- 없으면 에러
local maybe = ctx:Peek(ThemeProvider)  -- 없으면 nil
