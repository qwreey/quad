# 2026-08-12 여덟 번째 세션 — `Ref`의 retract, `TagHandler`와 같은 패턴으로 확정

## 배경

직전 세션(일곱 번째, PreRef 1회용/재사용 error 확정)에서 "일반 `Ref`는
계속 Modifier/Store 어디든 자유롭게 들어감"이라는 기존 확정 사항을 다시
짚다가, 사용자가 `Ref`의 취소(retract)도 확인이 필요하다고 지적함 —
"retract 시 `.Value`가 `nil`이 된다"가 실제로 문서화돼 있는지부터 확인
요청.

## 1차 확인 (이번 세션 전반부)

`bind-system-plan.md` 전체를 훑었으나 `Ref` leaf handler의 `retract`
구체 구현은 어디에도 없었음 — Handler가 `Dispatch/Leaf.luau`에
등록된다는 사실과 `isHandlable` 좁히기 규칙만 확정돼 있었고, 실제
`process`/`retract` 바디는 미정. 일반 프로퍼티 핸들러 패턴(재-render 없어
retract 호출 경로 자체가 없음)을 대입하면 리터럴 children 배열 슬롯의
`Ref`는 구조적으로 retract가 안 불릴 걸로 보였으나, "Ref는 Store/Modifier
어디든 들어간다"는 이미 확정된 사실을 놓치고 있었음을 사용자가 짚음 —
`State<Ref>`가 실제로 가능하면, Store 값이 `refA→refB`로 바뀌는 시나리오가
있고 이땐 `refA`가 stale하게 남아있으면 조용한 버그가 됨. 사용자 제안:
retract 시 `nil`로 덮어쓰는 게 적절해 보인다.

## 2차 확인 — 메커니즘 정정 (Tag 선례와의 충돌 발견)

처음엔 "`retract(inst,k,oldRef) = oldRef:Set(nil)`"로 단순하게 답했으나,
`Dispatch`의 일반 retract 계약(`bind-system-plan.md` 118-136행: "retract가
의미 있는 유일한 패턴은 매치되는 핸들러 *타입*이 바뀔 때뿐, 같은 핸들러가
계속 매치되면 diff는 `process` 자신이 담당")과 `tag-plan.md`의 실제
구현(`Tag(A)→Tag(B)`는 `retract` 안 불림, `TagHandler.process`가 `Relate`로
이전 값을 기억해뒀다가 직접 diff)을 대조하니 모순이 발견됨 — `refA→refB`도
둘 다 같은 "Ref-leaf handler"가 매치하는 경우라, `retract`가 아니라
`process`가 diff를 담당해야 하는 케이스였음. 이전 답변을 정정.

## 결정 (이번 세션 후반부, 사용자 확인)

1. **메커니즘은 `TagHandler`와 완전히 동형** — Ref-leaf handler가 자기
   전용 `Relate()`로 `(inst,k)`별 마지막 바인딩 `Ref`를 기억. `process`가
   이전 값과 다르면 `old:Set(nil)`로 언바인딩 후 `v:Set(inst)`. `retract`는
   그 자리가 아예 Ref이길 그만둘 때만 불리고, 역시 `old:Set(nil)` 하나로
   귀결. 리터럴 children 배열 슬롯도 같은 코드 경로를 타되 `old`가 항상
   없어서 자연히 1회성으로 동작 — 케이스 분기 불필요.
2. **비-nilable `T`도 정당한 용도(사용자 확인)** — Ref는 "채워지길 기다리는
   박스"뿐 아니라 "확정값을 부작용 없이 읽기"용으로도 쓰이므로 non-nilable
   `Ref<T>`를 계속 지원할 이유가 있음. 언바인딩이 실제로 발생하는
   Store/Modifier 자리에 놓을 땐 **호출자가 직접 `Ref<<T?>>(...)`로 명시**할
   것 — 이미 있는 "초기값이 nil이면 명시적 제네릭 적용" 관용구를 그대로
   재사용, 새 타입 규칙 아님. 프레임워크가 자동으로 감지/차단하지 않음 —
   어기면 caller 책임의 UB(다른 UB 케이스들과 같은 결).
3. **Destroy와 무관(사용자 확정)** — Ref의 언바인딩은 오직 재바인드/retract
   경로에서만 일어남, Instance `Destroy()`와는 별개. `Ref<Frame?>`가 이미
   Destroy된 Frame을 계속 들고 있는 채로 남는 건 정상, 이후 읽고 쓰는 건
   UB(방어 안 함). Destroy 시점 정리가 필요하면 `Effect`(`bindLifetime`/
   `Observer` 기반, 또는 Roblox가 알아서 Disconnect해주는 이벤트 안에 로직
   두기)를 쓰도록 문서가 유도 — Ref 자신에 Destroy-awareness를 얹는 건
   오버엔지니어링으로 기각.

## 반영

- `base/bind-system-plan.md` — "Ref 일반화" 절 바로 뒤에 "`Ref`의 retract"
  새 절 추가(메커니즘 pseudocode, T? 관용구, Destroy 무관 명시 전부 포함).
  118-136행 일반 retract 계약 절에도 Ref를 Tag와 같은 예시로 짧게 추가
  (교차 참조 누락 방지).
