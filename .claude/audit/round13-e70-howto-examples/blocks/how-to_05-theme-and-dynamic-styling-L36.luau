-- (가방으로 내리는 모양 — 이 문서의 나머지 절은 층이 얕아 모듈을 직접 참조합니다)
local Theme = require("./Theme")
local ThemeProvider = q.Context.Provider<<typeof(Theme)>>("Theme") -- 타입 인자를 주면 :Get 결과에 타입이 붙는다

-- 앱 진입점에서 한 번(Theme은 §2에서 만드는 토큰 모듈)
local ctx = q.Context():Set(ThemeProvider, Theme)

-- 아래 어딘가에서
local theme = ctx:Get(ThemeProvider)   -- 없으면 에러
local maybe = ctx:Peek(ThemeProvider)  -- 없으면 nil
