-- 스크롤 위치 스로틀(0.1초 고정 창) — 팩토리 브로드캐스트로 한꺼번에 제어
local scrollGate = q.Throttle { Time = 0.1 }
local scrollRaw = q.Source(0)
local scrollPos: State<number> = scrollRaw:Apply(scrollGate)

scrollGate:Flush() -- 이 팩토리가 만든 게이트 전부
scrollGate:Cancel()
