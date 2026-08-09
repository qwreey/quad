# [기각됨] `Observer` 자체에 React `useEffect`식 cleanup 반환 계약 추가

**기각 일시**: 2026-08-07 여섯 번째 세션. **현재 유효한 설계**: `base/
effect-plan.md` "Effect와 Observer의 관계" 절 — `Observer`의 기본 계약은
재실행 신호만 주고 cleanup은 클로저로 직접 처리, 자동 cleanup 배선이
필요하면 opt-in 상위 계층인 `Effect(fn, state?)`를 쓸 것. 이 파일은 더
이상 능동적으로 참고할 필요 없음(구현에 안 씀) — "왜 Observer 자체에
cleanup 계약을 안 넣었는가"가 `quadnomicon`(프레임워크 설계자용 심화
콘텐츠) 소재로 가치 있어서 사유를 보존해둔 것.

## 무엇을 검토했었나

React `useEffect`류 패턴 — `state:Observer(fn)`의 `fn`이 `nil | () -> ()`를
반환하면, 다음 재실행 직전에 quad가 그 반환값을 자동으로 호출해주는 안.

## 기각 이유

클로저 업밸류로 이미 쉽게 되고 잘 작동함:

```lua
local lastConn
state:Observer(function()
  if lastConn then lastConn:Disconnect() end
  lastConn = ...
end)
```

**Observer 자체**가 이걸 대신 배선해줘야 할 이유가 약함 — 반환값을 잡아뒀다가
다음 실행 전에 불러주는 기능을 Observer 코어에 넣으면, 그 계약을 안 쓰는
대다수 사용처까지 복잡도가 늘어나는데 클로저로 이미 공짜로 되는 걸 다시
API 표면으로 만드는 셈.

## 왜 완전히 헛수고는 아니었나 — Effect 설계와 상충하지 않음

이 기각과 이후 확정된 `Effect(fn, state?)` 설계는 상충하지 않는다 — 그때
기각한 건 "Observer 자체에 이 복잡도를 넣지 말자"였지 "이 패턴 자체가
무용하다"가 아니었음. 자동 cleanup 배선이 필요한 사람만 opt-in으로 쓰는
별도 계층(`Effect`)으로 분리해 얹었을 뿐, `Observer`의 기본 계약(재실행
신호만, cleanup은 클로저로 직접)은 그대로 가볍게 유지됨 — `Effect`가
내부적으로 `state:Observer(...)`를 조합해 이 패턴을 상위 계층에서 정확히
구현한다(`base/effect-plan.md` 참고).
