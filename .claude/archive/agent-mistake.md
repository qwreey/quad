# [에이전트 실수] 에이전트 실수 기록

CLAUDE.md 세션 로그 안에 흩어져 있던 "에이전트가 같은 세션 안에서 스스로
정정한 실수" 서술을 여기로 모음 — 최종 결론은 이미 각 `base/` 문서에
정확히 반영돼 있어서 CLAUDE.md에 전체 문단을 남겨둘 필요는 없지만(중복),
같은 실수를 반복하지 않기 위한 기록 자체는 남겨둘 가치가 있음. 다른 archive
문서(`*-reversed.md`/`*-rejected.md`)와 달리 이건 "설계 결정의 반전"이
아니라 "에이전트가 문서를 쓰다가 실제로 개념을 혼동했던 사례" 전용.

## 1. `canExecute`와 `isHandlable`을 같은 개념으로 혼동 (2026-08-07 여덟 번째 세션)

**실수**: `NoneHandler`(값을 `None`에서 `nil`로 바꿔 재디스패치하는 base
내장 핸들러)를 설계하며 그 매치 조건을 `canExecute`로 잘못 서술함.

**정정**: 둘은 완전히 다른 계층 — `isHandlable(k,v)`는 KV 매치
predicate(핸들러가 이 키/값을 담당하는지 판단, 핸들러 계약 4종 중 하나),
`canExecute(handle)`는 특정 바인딩 하나가 "지금 살아있어 실행돼도
되는가"만 보는 별개의 라이프타임 게이트(`base/lifecycle-pattern.md`).
`NoneHandler`가 구현해야 하는 건 `isHandlable`이지 `canExecute`가 아님.

**현재 유효한 설계**: `base/bind-system-plan.md`의 `None` 센티널 절과
"매치 predicate는 `isHandlable`" 절이 최종 소스.

## 2. `isSource`가 불필요하다고 잘못 판단 (다섯 번째 세션 → 여덟 번째 세션에서 정정)

**실수**: 2026-08-07 다섯 번째 세션에서 `isState`/`isSource` predicate를
설계하며 "State면 충분한 용도만 있으니 `isSource`는 따로 안 만들어도
된다"고 서술. 이때 `base/component-composition-plan.md` 4번 절은 이미
`isSource`가 존재한다고 가정하고 쓰여 있었는데, 그 모순을 그때는 못
찾아냄.

**정정**: `Source`는 `State`보다 실제로 더 많은 능력(`:Set`/`:Emit`)을
가진 서브타입이라, "쓰기도 되는 원천인가"를 알아야 하는 코드는
`isState`만으론 부족함 — `isSource`를 별도로 제공해야 함. `isState`는
여전히 `{State, Source}` 둘 다 통과시킴(상위집합 판별 유지).

**현재 유효한 설계**: `base/bind-system-plan.md`의 `Brand` 절
(`isState`/`isSource`가 둘 다 존재, 전자는 집합 멤버십, 후자는 단순 항등)이
최종 소스.
