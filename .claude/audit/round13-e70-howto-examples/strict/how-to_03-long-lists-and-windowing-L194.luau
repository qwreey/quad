--!strict
-- E70 strict (generated) — how-to_03-long-lists-and-windowing-L194
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_03-long-lists-and-windowing-L24) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local viewportHeight = q.Source(600)
-- ==== doc block how-to/03-long-lists-and-windowing.md:194 ====
-- §4의 VirtualList 안에서 바뀌는 두 곳
local scrollY = q.Source(0)                                    -- OnChange 콜백은 그대로 이걸 :Set 한다
local gatedScrollY: q.State<number> = scrollY:Apply(q.Throttle { Time = 0.1 })  -- 0.1초 창마다 한 번 통지 — 결과 타입은 호출부가 명시(레퍼런스 sugar/03)

local window = gatedScrollY:Compute(function(y, _previous, height)
    -- …§4 본문 그대로…
end, viewportHeight)
