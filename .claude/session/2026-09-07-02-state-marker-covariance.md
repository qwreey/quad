# 2026-09-07 (02) — 입력 자리의 State/Slot 팔을 공변 마커로 (Q1 결정 실행)

> 앞 세션 `session/2026-09-07-01-post-review-reply1-q1-q3.md`가 Q1을 "사고 중 + 스파이크 34"로
> 열어 뒀고, 사용자가 *"그럼 공변성/불변성 문제를 해결하기 위한 작업을 시작해볼래? 내 노트는 다
> 반영 되었다면 지워도 좋아. 이해한건 맞아보여"*로 착수를 지시했다. 결정의 소스는 원장
> `qa-request/post-implementation-review-round1.md` §16, 규칙은 `typing-limits.md` 8.11.

## 1. 순서 — 작은 실측을 하나 더 하고 실물로

스파이크 34는 최소형이었다. 실물엔 `Tween<T>`(교집합)·유니언 T·변환 함수·호출 인자 자리(gen-d
주석의 "setter는 데이터부 TweenData가 교집합 값을 못 받았다" 관측)가 얽히므로 **`35`**로 생성 D 슬롯
모양을 그대로 흉내 내 재봤다 — `PV = T | TweenData<T> | StateMarker<T | Tween<T>> | None` 한 벌이
멤버 State·`State<Tween<m>>`·정직한 `State<T | Tween<T>>`·교집합 Tween 값을 전부 받고 음성 넷만
거부. 그 다음 quad-types(마커 둘 + `StateData`/`Slot`에 필드) → 런타임 브랜드 필드 → `NewChild` →
gen-d(`PV`/`Field`/`Elem`/이벤트) → 재생성 → test.sh.

## 2. 판단한 것(사용자 사후 확인 대상)

- **순수 팬텀 필드** `__quadStateValue: T` / `__quadSlotValue: T` — 런타임에 T 값을 둘 수 없어
  값이 없다. H-300 "타입이 약속하면 값에도"의 첫 예외(`__quadRefAccepts`는 `Void`를 뒀다). 브랜드
  쪽 `__quadState`/`__quadSlot`은 `true`를 둔다. 읽는 코드가 없어야 한다는 규칙을 주석에 박았다.
  → **사용자 확정(같은 날)**: *"런타임 값에 없는 팬텀 괜찮아. 실제로 그래도 되는 부분은, 값이 싸다면
  그래도 좋아"* — 팬텀 허용, 값이 싸면 두는 것도 좋다. 지금 값 필드는 T라 둘 수 없어 팬텀 그대로.
- **입력/출력 별칭 분리** — Slot의 `SlotElement<T>`(입력 마커)와 새 `SlotItem<T>`(출력 전체형),
  Modifier의 `FieldV<T>`(입력)와 새 `FieldOut<T>`(변환 함수 `old`). 같은 값의 두 역할이라 두 이름.
- **`NewChild`의 State 팔 하나** `StateMarker<(Instance | SlotMarker<Instance> | Tag | Attribute |
  None)?>` — `nil`을 넣은 건 NilHandler 계약(`State<Slot|nil>`)이 정본이기 때문. Observer/
  EffectHandle의 State 형·`State<Modifier>`는 정본에 없어 안 넣음.
- **`LuauSolverConstraintLimit` 제거** — 없이 클린이고 시간이 4.96s → 3.41s. 다시 나면 되살린다.
- 8.9 setter 이름 게이트는 그대로(넓은 쪽이 안전), `H-354` 캐스트 관용구는 별개 문제라 그대로.

## 3. 결과

`PV73` 11팔 → 4팔, `SHF0` 소멸, 캐스트 관용구 둘(`:: FrameRefMarker`, `:: FrameOnChange`) 불필요,
`H-334` (1)의 "정직한 Animate 타입은 too complex" 소멸. 음성 아홉(tmp 프로브) 전부 거부. test.sh
exit 0(스펙 49), doc-check ERROR 0. 정본 배너 아홉 자리(원장 §16 목록). 단위 끝 절차(감사자 1패스 →
`/code-review` opus 지정)는 원장 round3 새 파일의 첫 항목.

## 4. 단위 끝 절차 결과 (같은 날 저녁)

감사자 1패스 4건(ui-shorthand 배너 누락·onchange Elem 정의·README §범위·팬텀 문항) 반영 뒤 커밋 `8b4748a`;
사용자가 팬텀을 확정(`d07aab0`). `/code-review high`(파인더·검증자 opus, 미완 0)가 10건 — 원장 **round3**
신설(`H-431`~`H-439`, Q22~Q24). HIGH 하나는 첫 마커 팔이 `State<Observer?>` 종료 관용구(slot-plan)를 빠뜨린
것으로 내 주석 "정본에 없다"가 틀렸다 — 정본을 grep하지 않고 단정한 실수. Slot의 입력 공변 + 가변 출력(Q22)과
`FieldOut` 모양(Q23)은 승인 범위 밖의 새 결과·새 모양이라 문항으로, 이름·팔 모양·플래그 제거(Q24)는 승인과
제안을 갈라 적었다(8.11 배너). 타입 검사 2.95s.
