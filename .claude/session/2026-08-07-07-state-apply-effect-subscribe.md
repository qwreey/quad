<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 일곱 번째 세션 — `:Compute` 커링, `state:Apply` 확정(백로그안 기각), Effect `:Subscribe`/`:Unsubscribe` 신설, 이중 바인딩 금지

짧은 대화형 세션, 네 가지를 순서대로 처리 — 전부 `base/bind-system-plan.md`/
`base/effect-plan.md`/`ROADMAP.md`/`question.md`에 반영 완료:

1. **`:Compute(fn)`에도 커링 권장 노트 추가.** 여섯 번째 세션에서 Observer/
   Effect의 `fn`에만 문서화됐던 "팩토리가 실제 `fn`을 만들어 반환하는
   커링 스타일 권장"이 `:Compute`엔 빠져 있었음 — 같은 결이라 자연스럽게
   확장, `bind-system-plan.md` "`:With`+`:Compute`" 절에 추가.
2. **`state:Apply(factory)` 확정 — 원래 백로그였던 "`:With`/`:Compute`
   등록을 커링으로 자동화하는 조합기" 방향은 기각.** 사용자가 재확인한
   실제 의도는 훨씬 단순함: `Modifier:Apply`와 똑같이 `factory(self)`를
   체이닝 문법으로 부르는 순수 설탕(`function(self, factory) return
   factory(self) end`) — `fnb(c,d)(fn(a,b)(state))`처럼 팩토리를 안에서
   밖으로 겹쳐 읽어야 하는 중첩을 `state:With(a,b):Compute(fn(a,b))
   :Apply(fnb(c,d))`로 펴는 게 유일한 목적. 구현 비용 거의 0(State는
   Modifier와 달리 제네릭 `__index` 필드 setter 합성이 없어 이름 예약
   충돌도 없음), 타입은 `factory: (State<T>) -> U): U`로 Modifier보다
   더 열어둠(팩토리가 State 밖 plain 값을 반환해 반응형 그래프를 벗어나는
   것도 허용). Source는 기존 `:With`/`:Compute` 델리게이션에 얹혀 자동
   포함. `bind-system-plan.md` "`state:Apply(factory)`" 절, 구체 전/후
   코드 예시까지 반영. 부수적으로 같은 헤더 아래 잘못 걸려 있던 Observer
   `:Subscribe`/`:Unsubscribe` 내용(무관한 주제)을 별도 절로 분리하는
   문서 버그도 수정.
3. **`EffectHandle:Subscribe()`/`:Unsubscribe()` 신설.** 지금까지 Effect의
   유일한 생애주기 경로는 children 배열 leaf 부착뿐이라, leaf 없이 쓰는
   모듈/스크립트 레벨 사이드 이펙트(백그라운드 시스템 등)엔 반환된
   `EffectHandle`이 막다른 길이었음 — Observer가 이미 가진 `:Subscribe`/
   `:Unsubscribe`와 같은 결로 확정. **핵심 주의점**: Effect의
   `:Unsubscribe()`는 Observer의 것을 그냥 위임하면 안 됨 — Observer의
   계약은 "미래 재실행만 끊는다"로 충분하지만, Effect의 계약은 "생애주기가
   끝나는 시점에 마지막 cleanup이 정확히 1회 호출된다"이고 leaf 사망은
   그 "끝"의 신호 중 하나일 뿐이라, `:Unsubscribe()`도 동일하게 "지금
   끝났다"는 신호로 취급해 마지막 cleanup을 트리거해야 계약이 일관됨(leaf
   가 살아있어도 마찬가지). idempotent 보장은 기존 `Subscribed` 필드
   liveness 체크 재사용으로 공짜. `base/effect-plan.md` 신규 절.
4. **Observer/Effect 이중 바인딩 금지 — `Bound`(가칭) 플래그로 즉시
   `error`.** 처음엔 "leaf 부착과 `:Subscribe()`를 동시에 써도 같은
   liveness 게이트를 공유하니 안전"이라고 적었으나, 사용자가 애초에 한
   핸들은 라이프사이클 바인딩 경로를 하나만 가져야 한다고 정정 — 동시
   바인딩은 UB로 확정하되, 판별 비용이 사실상 0(불리언 필드 하나)이라
   조용한 오동작 대신 그 자리에서 `error`를 던지는 쪽으로 결정
   (엔지니어링 비용 대비 디버깅 이득이 명확). 두 진입점(`:Subscribe()`
   호출부, children 배열 leaf 부착부)이 똑같이 확인/설정하는 대칭적 게이트
   — 순서 무관. `bind-system-plan.md` "이중 바인딩 금지" 절 신설,
   `effect-plan.md`의 3번 항목 서술은 이 규칙으로 대체(정정 표시 남김).

**부수 정리**: `ROADMAP.md` M3에 `state:Apply`/Effect `:Subscribe`·
`:Unsubscribe`/이중 바인딩 금지 체크박스 추가. `question.md`에 `Bound`
이름을 용어 정리 대상(3순위)으로 추가.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

