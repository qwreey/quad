--!strict
-- E58 strict (generated) — sugar_03-debounce-throttle-L214
-- ==== page prologue sugar/03-debounce-throttle.md (sugar_03-debounce-throttle-L21.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.GateHandle` 등)
type State<T> = q.State<T>
-- ==== doc block sugar/03-debounce-throttle.md:214 (line offset marker) ====
-- 스크롤 위치 스로틀(0.1초 고정 창) — 팩토리 브로드캐스트로 한꺼번에 제어
local scrollGate = q.Throttle { Time = 0.1 }
local scrollRaw = q.Source(0)
local scrollPos: State<number> = scrollRaw:Apply(scrollGate)

scrollGate:Flush() -- 이 팩토리가 만든 게이트 전부
scrollGate:Cancel()
