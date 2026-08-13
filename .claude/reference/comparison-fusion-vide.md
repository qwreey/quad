# Fusion / Vide 아키텍처 비교 — quad-v2 설계 근거

**상태**: reference — 온디맨드 참고 자료, "완료" 개념 없음. **[2026-08-07
문서 정리에서 `base/`→`reference/`로 이동]** quad에 관한 결정 자체가 아니라
Fusion/Vide 리서치 스냅샷이라 항상 읽어야 하는 base 컨텍스트는 아님 —
`quadnomicon`(프레임워크 설계자용 심화 콘텐츠) 소재 후보이기도 함. quad-v2의
Store/Slot/Tween/bind-dispatch 설계 결정에 근거로 인용될 때만 열어볼 것,
실제 확정 사항은 인용하는 쪽 `base/` 문서가 소스.

## Fusion (`.claude/initreq/fusion/`)

- **반응 그래프**: push(무효화) + pull(재계산) 하이브리드. `Value:set()`이 `change()`를
  통해 `dependentSet`을 BFS로 훑으며 `invalid`로 마킹하지만, 실제 재계산은
  `timeliness="eager"`인 노드(Observer/Tween/Spring)만 즉시 동기 실행 — `Computed`/
  `Value`는 `use()`될 때만 lazy하게 재계산. 글리치 방지를 위해 eager 집합을
  `createdAt` 순으로 정렬 후 처리.
- **Scope 정리 모델**: `Scope`는 사실 그냥 배열 + 메타테이블로 생성자들을 주입한
  것. 생성자마다 자기 destroy 클로저를 배열에 `insert`. `doCleanup`은 다형적
  (Instance→Destroy, Connection→Disconnect, 함수→호출, 테이블→역순 순회) 티어다운.
  **완전히 eager/수동 — GC에 의존하지 않음.**
- **프로퍼티/자식/이벤트 디스패치**: `SpecialKey`라는 열린 "모양"(shape)은
  누구나 만들 수 있지만, 우선순위 축이 `self/descendants/ancestor/observer` 4단계로
  하드코딩되어 있어 5번째 우선순위 도입이 불가능 — quad가 원하는 완전 개방형
  priority 레지스트리보다 약함.
- **Tween/Spring이 State그래프 안의 1급 노드** — 매 프레임 틱하는 외부
  Stopwatch/ExternalTime 소스에 의존, 애니메이션-입력 간 별도 lifetime 체크
  기계장치 필요. **quad가 Tween을 반응 그래프의 1급 노드로 만들지 않은
  이유의 반면교사**: Fusion처럼 그래프 안에 넣으면 Computed의 입력으로
  자유롭게 합성 가능해지지만, 그 대가로 프레임 클럭 통합 + eager 노드 +
  교차 lifetime 체크 3중 복잡도를 떠안음. **[2026-08-13 정정] "Store 밖
  특수 bind key" 표현은 2026-08-10 폐기된 quad 구모델(
  `archive/tween-special-bind-key-reversed.md`) 서술 — 현재 quad의 실제
  결론은 Tween을 별도 bind key가 아니라 `Tween(opts) -> Tween<T>`
  값-레벨 래퍼로 만들어 Property 타입 자리(`T|Tween<T>`)에 꽂는 것.
  이 문단의 Fusion 반면교사 논리(그래프 1급 노드화의 3중 복잡도) 자체는
  두 모델 다에 여전히 유효, 인용하는 결론 쪽 이름만 stale했던 것.

## Vide (`.claude/initreq/vide/`)

- **반응 그래프**: SolidJS류 순수 push. `source()`를 쓰면 즉시, 동기적으로,
  깊이우선으로 모든 의존 노드를 재평가(lazy/pull 경로 없음). **저자들 스스로
  `todo.md`에 "복잡한 다이아몬드 그래프에서 중복 재평가 방지" 를 미해결로 남겨둠**
  — quad Store가 이 naive BFS 방식을 그대로 베끼면 안 되는 이유.
- **정리 모델**: 의존성 엣지(`parents`)와 구조적 소유(`owner`/`owned`)를 같은
  `Node`에서 두 개의 별도 관계로 분리 — CHANGELOG 0.2.0에서 "destroy가 더 이상
  reactive dependent까지 타고 내려가지 않고 owned만" 으로 명시적으로 고침(초기
  설계 실수를 나중에 수정한 이력). 0.4.0에서 "활성 스코프는 destroy 불가" 하드
  가드 추가. **역시 완전 eager/수동 — GC 의존 없음**(오히려 `root.luau`가 GC로부터
  루트를 보호하는 `refs` 테이블까지 둠).
- **디스패치**: 대부분 Luau 키 타입으로 닫힌 하드코딩. 유일한 열린 확장점은
  `action(callback, priority)` — 등록 없이 private 메타테이블 태그로 인식되는
  값을 던지면 우선순위 순으로 실행. 단 key/value 쌍이 아니라 콜백+우선순위만
  전달 — quad가 원하는 "key와 value를 함께 받는 핸들러"보다 좁음.
- **`mount()`에 단일-마운트 가드가 전혀 없음** — 같은 target에 두 번 mount하면
  독립된 두 루트가 생겨 자식이 중복됨. **quad의 Slot "엄격한 단일 마운트
  소유권"이 두 라이브러리 어디에도 없는 진짜 개선점**이라는 근거.

## 종합 비교표

| 축 | Fusion | Vide | quad-v2 시사점 |
|---|---|---|---|
| 전파 모델 | push+pull 하이브리드, eager 집합만 즉시 재계산, 생성순 정렬로 글리치 방지 | 순수 push, 즉시 동기 재평가, 다이아몬드 중복 재평가 미해결(저자 인정) | ⚠️ **[정정] 아래 서술은 리서치 당시(2026-08-03 이전) 검토 방향이며 이후 뒤집힘 — 최종 확정은 `base/bind-system-plan.md`의 "전파 모델 확정" 절 참고**(push-invalidate는 신호만 쏘고 값은 안 실음, 재계산은 `Get()` 시점 pull-recompute로만, Fusion식 eager 노드·생성순 정렬은 아예 채택 안 함 — quad엔 그런 다단계 즉시 재계산이 필요한 소비자가 없다는 판단). 당시 스냅샷 원문: "Store는 값 자체에 항상 eager 발화, retract(구 cleanup)가 key/value를 먼저 확인" 요구사항은 Vide의 push 모델 + eval-전-retract 패턴에 더 가까움. 단 Vide의 naive BFS 대신 Fusion의 생성순 정렬 글리치 방지 규율은 채택할 것. |
| 정리/스코프 | 배열+메타테이블, dependency-agnostic, bind 시점에만 lifetime soft-check | dependency edge와 구조적 owner를 분리한 2중 관계, destroy는 owned만 cascade, 활성 스코프 destroy 하드 가드 | 둘 다 GC 비의존 eager 수동 정리 — rbvm의 Connected+GC 관용구와 정반대 축. quad의 Slot은 Vide처럼 "마운트 소유권"과 "반응 의존성"을 별개 관계로 분리하는 게 안전해 보임(`base/lifecycle-pattern.md`의 rbvm 패턴과는 다른 층위 — rbvm은 인스턴스 파괴 감지, 이건 Slot 내부 소유권 모델). |
| 키/값 디스패치 개방성 | SpecialKey 모양은 열려있으나 우선순위 4단계 하드고정 | action()은 등록 없는 태그 인식 방식이지만 key/value 버림, 콜백+우선순위만 | quad는 Fusion의 "디스패처가 key+value+target을 다 받는" 풍부함과 Vide의 "등록 없이 태그로 인식" 인체공학을 합치되, 우선순위 축은 열린 숫자 공간으로 일반화해야 함(`base/bind-system-plan.md`). |

## 추가로 기록해둘 것

- Vide의 암묵적(ambient stack) 의존성 추적 vs Fusion의 명시적 `use()` 축은
  push/pull 축과 독립적인 별개 결정. **[정정] 리서치 당시(2026-08-03 이전)엔
  "quad는 아직 미정"이었으나, `base/bind-system-plan.md`의 "여러 Store 값을
  묶어 파생값 만들기 — `:With` + `:Compute`" 절에서 이미 명시적 모델로
  확정됨** — Vide식 암묵적 ambient stack 추적은 "함수 실행 중과 끝 사이를
  확인하고 부작용이 필요"한 방식이라 Lua에서 깔끔하지 않다는 이유로 기각,
  `:With(...)` + `:Compute(fn)`(클로저로 직접 읽는 명시적 방식)를 채택.
  Fusion의 명시적 `use()`는 `checkLifetime` 같은 bind-time 체크를 가능하게
  하는 부수 효과가 있음.
- 두 라이브러리 다 mount 시 단일 소유권 가드가 없다는 것 자체가 quad Slot의
  차별점이라는 근거로 재사용 가능.
