<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-11 세션 — `:Compute(fn, ...)` trailing-args sugar 확정,
`Effect`/`Observer`는 의도적으로 제외

사용자가 Vide의 암묵적 추적과 React 훅 규칙의 차이를 짚는 질문에서 출발해,
"React의 `useMemo(fn, deps)`처럼 `:With(...)` 없이 `:Compute(fn, a, b, c)`로
바로 추가 의존성을 선언하면 더 편하지 않냐"는 제안으로 이어진 짧은 세션.
검토 끝에 확정, `base/bind-system-plan.md`(`:Compute` 절 신규 소절)/
`base/effect-plan.md`/`ROADMAP.md`(M3)/`research/documentation-content-map.md`
(quadnomicon 후보 7번)에 반영 완료:

- **`:Compute(fn, ...)`는 채택 — 진짜 공짜 sugar라는 게 사용자가 직접 밝힌
  핵심 근거.** `:Compute` 호출은 원래도 결과를 담을 새 State 노드를 만들어야
  하므로, 그 노드에 `self` 말고 `a,b,c`까지 구독(무효화 엣지)을 추가로 거는
  건 이미 생기는 노드에 엣지만 얹는 것 — `:With(a,b,c):Compute(fn)`(노드
  2개)보다 싼 노드 1개로 끝남. 이전에 기각됐던 `Store.Combine({a,b},
  function(av,bv)...)`(포지셔널 값 언랩이라 타입 표기가 꼬였던 안)과는
  달리 `fn(self)` lazy 핸들 시그니처를 그대로 유지하는 제안이라 그 기각
  사유가 안 걸림.
- **`Effect(fn, ...)`/`state:Observer(fn, ...)`류 동일 sugar는 기각 —
  사용자가 직접 구분.** Effect/Observer는 Compute와 달리 자기 자신이
  결과를 담는 State 노드가 아닌 순수 leaf 소비자라, 의존성이 둘 이상이면
  그걸 하나로 합칠 **새 노드**(`:With`가 만드는 것)가 실제로 필요함 —
  이건 진짜 비용이 드는 지점이라, trailing args로 감추면 "이 줄이 새
  노드/구독을 만든다"는 걸 코드만 보고 알 수 없게 됨. `:With`가 clone
  빌더가 아니라 진짜 노드로 확정됐던 이유(2026-08-07 세 번째 세션,
  "코드상의 호출 체인이 그래프 엣지와 1:1 대응돼야 quad-debug 그래프가
  안 꼬임")와 정확히 같은 원칙 — 다중 의존성 Effect/Observer는
  `Effect(fn, state:With(a,b,c))`처럼 `:With` 호출을 코드에 그대로 노출.
- **일반 원칙**: "trailing args sugar는 그게 정말 무료일 때만 붙인다" —
  호출부가 이미 만들어야 하는 노드에 엣지만 얹는 경우(Compute)엔 sugar,
  없던 노드를 새로 만들어야 하는 경우(Effect/Observer의 다중 의존성
  병합)엔 sugar 없이 `:With`를 명시적으로 남긴다. `Compute`만 편해지고
  `Effect`/`Observer`는 안 그런 게 겉보기엔 비일관적으로 보이지만 실은
  이 하나의 원칙에서 나온 것이라는 게 quadnomicon 에세이 소재로 채택
  (사용자 제안).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.

