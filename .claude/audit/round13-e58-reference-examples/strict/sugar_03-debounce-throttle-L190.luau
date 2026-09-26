--!strict
-- E58 strict (generated) — sugar_03-debounce-throttle-L190
-- ==== page prologue sugar/03-debounce-throttle.md (sugar_03-debounce-throttle-L21.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.GateHandle` 등)
type State<T> = q.State<T>
-- ==== doc block sugar/03-debounce-throttle.md:190 (line offset marker) ====
-- 검색창 디바운스(0.3초, 1초마다는 강제 통과) + 수동 제어 핸들
local searchInput = q.Source("")
local handle = q.Ref<<QuadTypes.GateHandle?>>(nil)
local debounced: State<string> = searchInput:Apply(q.Debounce {
    Time = 0.3,
    MaxTime = 1.0,
    Handle = handle,
})

-- Observer 콜백은 값이 아니라 대상 State 핸들을 받는다 — 값은 :Get()으로 읽는다.
-- 구독을 유지하려면 :Subscribe()(또는 숫자 키 자리에 넣어 인스턴스에 바인딩)해야 한다.
debounced:Observer(function(target)
    print("API 검색 실행:", target:Get())
end):Subscribe()

searchInput:Set("a")
searchInput:Set("ab") -- 창 안이라 통지 없음. 다만 debounced:Get()은 이미 "ab"
-- 0.3초 뒤 "ab"가 통지된다

handle:Unwrap():Flush() -- 기다리지 않고 지금 내보낸다(보류분이 없으면 no-op)
handle:Unwrap():Cancel() -- 보류분을 버린다(통지 없음)
