--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L141
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:141 ====
local themeColor = q.Source(Color3.fromRGB(255, 0, 0))

-- 빌더 체인
local dynamicStyle = D.Modifier.Frame():BackgroundColor3(themeColor)

-- 초기 필드 테이블도 같은 값
local dynamicStyle2 = D.Modifier.Frame { BackgroundColor3 = themeColor }
