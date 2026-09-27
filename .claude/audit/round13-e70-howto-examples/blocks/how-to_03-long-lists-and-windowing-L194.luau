-- §4의 VirtualList 안에서 바뀌는 두 곳
local scrollY = q.Source(0)                                    -- OnChange 콜백은 그대로 이걸 :Set 한다
local gatedScrollY: q.State<number> = scrollY:Apply(q.Throttle { Time = 0.1 })  -- 0.1초 창마다 한 번 통지 — 결과 타입은 호출부가 명시(레퍼런스 sugar/03)

local window = gatedScrollY:Compute(function(y, _previous, height)
    -- …§4 본문 그대로…
end, viewportHeight)
