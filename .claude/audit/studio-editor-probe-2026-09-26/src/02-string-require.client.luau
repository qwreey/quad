-- 02-string-require — 문서가 권하는 문자열 require(`@game/…`)가 Studio 기본 편집기·런타임에서 되는가
-- 볼 것(README 표 6): 편집기에서 require 줄이 해석되는지(밑줄 유무), Play 뒤 출력 창에 아래 print가 찍히는지.
-- 실패하면 에러 문구를 그대로 적어 주세요 — 문서(시작하기 01)의 권장 경로를 이 결과로 확정합니다.
local Quad = require("@game/ReplicatedStorage/quad-base/src")
local QuadRoblox = require("@game/ReplicatedStorage/quad-roblox/src").QuadRoblox
local q = Quad:UseProvider(QuadRoblox)
print("[editor-probe 02] string require ok; Declaration =", typeof(q.Declaration))
