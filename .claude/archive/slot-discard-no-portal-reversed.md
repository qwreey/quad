# [역전됨] Slot의 "retract = 폐기, 옮기지 않음" + "포탈은 오버엔지니어링" 결정

**역전 시점**: 2026-08-13 여섯 번째 세션(사용자 결정).
**원 결정 시점**: 2026-08-04 검증 라운드(폐기/no-portal), 2026-08-09 세 번째
세션(범위 명확화), 2026-08-13 여섯 번째 세션 전반부(파생 분석 두 절).
**현재 유효한 설계**: `base/slot-plan.md`의
"`State<Slot>` 교체는 파괴가 아니라 언마운트" 절 + `unmountSlotTree`/
`rawUnmount`. 시그니처가 열려 있는 `dispose(value)`는 `question.md` 0-B.

이 문서는 CLAUDE.md가 2026-08-06 세 번째 세션부터 정한 archive 용법
("완전히 뒤집힌 설계 결정을 원문 + 역전 이유와 함께 보존", 나중
`quadnomicon` 콘텐츠 소재)에 따라, `base/slot-plan.md` 본문에서 히스토리로만
남아 있던 세 덩어리를 원문 그대로 옮겨온 것이다. base 문서가 1982줄까지
불어나 **구현자가 앞에서부터 읽다가 뒤집힌 "확정"을 그대로 믿는 위험**이
같은 세션 감사에서 반복 지적됐던 게 이전 사유.

---

## 1. 무엇이 뒤집혔나 (요약)

| | 옛 결정 | 현재 |
|---|---|---|
| `State<Slot>` 교체 시 이전 Slot | **파괴**(`rawRemove`→`destroySlotTree`) | **언마운트만**(`rawUnmount`→`unmountSlotTree`), 안 죽음 |
| 포탈(살아있는 Slot을 다른 곳으로) | "오버엔지니어링, 이번 마일스톤에서 안 함" | **별도 기능이 아니라 위 결정의 자연스러운 귀결** — 기본 동작 |
| 명시적 파괴 | reconcile이 알아서 해줌 | 탑레벨 `dispose(value)` — 트리가 아직 그 값을 요구하면 **거부하고 error** |
| `reconcile`이 부르는 것 | `rawAdd`/`rawRemove`/`rawMove` | `rawAdd`/**`rawUnmount`**/`rawMove` |

**역전 근거(사용자)**: `state<Frame>`가 이미 그렇게 동작함 —
`store.child:Set(otherFrame)`을 해도 quad가 이전 `Frame`을 `Destroy()`해주지
않고 그냥 트리에서 내려올 뿐인데, `State<Slot>`만 다르게(파괴로) 동작할
이유가 없음. **"이전 값을 지울지는 그 값을 만든 쪽이 정한다"**는
`Ref`("Destroy와 무관")/`Attribute`("명시적 `None`으로만 지움")에서 이미
확정돼 있던 quad 전역 철학과도 같은 결.

주목할 점: 아래 3번 원문이 스스로 **"막는 게 소유권 규칙이 아니라 '제거 =
파괴'라는 reconcile의 선택 하나뿐"**이라고 짚어냈고, 그 한 줄이 곧바로
역전으로 이어졌다. 필요한 부품(`Extract`/`ExtractAll`/`Splice`의 비파괴
제거, `claimOwner`/`releaseOwner`의 소유권 이양, `attachSlot`의 재마운트
지원)은 이미 전부 확정돼 있었고, 포탈은 그것들 위에 아무것도 더 얹지 않아도
나왔다.

---

## 2. 원문 — "폐기, 옮기지 않음" 확정 (`slot-plan.md` "Slot과 Store 바인드의 관계" 절)

> **확정(2026-08-04 검증 라운드, 메커니즘은 2026-08-12 아홉 번째 세션에
> 정정): retract/재바인드되는 slot은 옮겨지지 않고 그냥 폐기된다.**
> Slot은 바인딩되는 순간 그 안의 요소를 전부 own해버리는 데이터형 — 새 slot
> 상태로 교체될 때 이전 slot의 내용을 다른 곳으로 옮기는 경로는 없음, 그냥
> 버림. React의 portal(`<></>`)류로 나중에 옮길 수 있게 하는 것도
> 검토됐으나 **이번 마일스톤에서는 오버엔지니어링으로 판단, 하지 않음** —
> 필요성이 명확해지면 그때 별도로 다시 논의.

> **범위 명확화(2026-08-09 세 번째 세션)**: 위 "폐기, 옮기지 않음"은
> **프레임워크가 store-bind 재실행으로 Slot 값 전체를 통째로 갈아치울
> 때**(retract)만의 얘기 — **사용자가 직접 `Slot:Extract(element)`를
> 부르는 CRUD 경로는 이것과 다른 시나리오**다. Extract로 뺀 element는
> 파괴되지 않고 호출부가 소유권을 되찾으며, **임의의 다른 Slot으로
> 자유롭게 다시 `Add`할 수 있다** — retract가 "옮기지 않는다"고 확정한 건
> 프레임워크가 알아서 옮겨주는 자동 portal을 안 만든다는 뜻이지, 사용자가
> 명시적으로 두 번 호출(`Extract` 후 `Add`)해서 옮기는 것 자체를 막는 게
> 아니다.

**이 "범위 명확화"가 사실상 역전의 예고편이었다** — 비파괴 이동 경로가
공개 API에 이미 있다는 걸 명시해뒀으므로, 남은 건 "프레임워크 자동 경로도
같은 시맨틱을 쓸 것인가" 하나였다.

---

## 3. 원문 — `State<Slot?>`가 `nil`이 됐다 돌아오는 경우 (2026-08-13 여섯 번째 세션, 사용자 질문)

원 제목: "소유권은 정상, 단 **Slot은 파괴된다**".

> **질문**:
> ```lua
> local stateSlot: State<Slot?> = Source()
> Frame { Slot { stateSlot } }
> ```
> 에서 `stateSlot`이 `nil`로 지워졌다 다시 나타나도 문제 없는가.
>
> **소유권 bookkeeping은 정상** — `:Single`이 감싼 `:List`의 `reconcile`이
> `data`가 빈 배열이 되면 직전 사이클 key(`true`)가 `seen`에 없으므로
> `rawRemove(sub, prev)`를 부르고(→ `releaseOwner`), 다시 값이 오면
> `rawAdd`(→ `claimOwner`)를 부름. 감사 수정(=`rawRemove`가 실제로
> `releaseOwner`를 부르고, `destroySlotTree`가 `_mounted`/`_mountedInst`도
> 되돌림) 이후로는 재클레임이 깨끗하게 됨.
>
> **하지만 그 사이에 Slot 자체가 파괴됨 — 이게 실질적인 답이다.**
> `reconcile`이 쓰는 건 `rawRemove`(= 제거 **+ 파괴**)이지 `rawExtract`(=
> 비파괴)가 아님("제거는 항상 파괴 확정이라 `Extract` 아닌 `Remove` 경로").
> 그래서 `nil`이 된 순간 `destroySlotTree(slotA)`가 돌아 **slotA의 자식
> Instance들이 `:Destroy()`됨**. 다시 나타날 때 같은 `slotA` 객체를 넣으면
> `_elements`엔 이미 죽은 Instance 참조가 남아있는 상태로 재마운트되는 것 —
> 껍데기만 살아있다. 이건 이미 확정된 정책("retract/재바인드되는 slot은
> 옮겨지지 않고 그냥 폐기된다")의 직접적인 귀결이고 이번 감사로 바뀐 게 아님.
>
> **따라서 실용적 관용구는 "Slot을 껐다 켜는" 게 아니라, Slot은 계속 두고
> 그 *내용*을 비우는 것**(`Slot:Clear()`, 또는 `:List`의 `data`를 빈
> 배열로) — 또는 매번 새로 만든 Slot을 `Set`하는 것. 같은 Slot 객체를
> `nil`↔`slotA`로 왕복시키는 코드는 두 번째 등장부터 조용히 빈/깨진
> 서브트리를 냄.

**지금은**: 언마운트 전환으로 이 문제 자체가 사라짐 — `nil`↔`slotA` 왕복이
정상 동작한다. 위 "실용적 관용구" 권고(같은 Slot 왕복 금지)도 함께 폐기.
단 **`Set`으로 덮어쓰기 *전에* 이전 값을 직접 `Destroy()`하는 건 여전히
UB**(`state<Frame>`에서 먼저 `frame:Destroy()`하고 `Set`하는 것과 같은
문제) — 순서는 항상 `Set`(언마운트) → 그 다음 정리.

---

## 4. 원문 — 포탈 검토 (2026-08-13 여섯 번째 세션, 사용자 질문)

> **질문**: `stateSlot:Get()`으로 Slot을 뽑아두고 → `Set()`으로 다른 Slot을
> 넣고 → 뽑아둔 Slot을 다른 곳에 넣을 수 있는가. 가능하다면 "포탈"이
> 이걸로 해결됨.
>
> **현재 설계로는 불가** — 위 절과 같은 이유 하나 때문임: `reconcile`이
> 교체 시 `rawRemove`(파괴)를 부르므로, `Get()`으로 뽑아둔 레퍼런스는
> `Set()` 직후 **이미 파괴된 Slot**이 됨. 막는 게 소유권 규칙이 아니라
> "제거 = 파괴"라는 reconcile의 선택 하나라는 점이 중요함.
>
> **그런데 나머지 부품은 이미 다 있음** — 그래서 사용자 지적대로 이
> 방향은 실현 가능성이 높음:
> - `Extract`/`ExtractAll`/`Splice`가 이미 **비파괴 제거**로 확정돼 있음 —
>   필요한 시맨틱이 이미 공개 API에 존재.
> - `claimOwner`/`releaseOwner`가 이미 소유권을 정확히 이양함 — 뽑힌
>   Slot은 owner 없는 상태가 되고, 다른 곳에서 `Add`하면 깨끗이 클레임됨.
> - `attachSlot`은 **재마운트를 구조적으로 이미 지원** — `_mounted`/
>   `_mountedInst`를 새 target으로 세팅하고 `_elements`를 새 물리 부모로
>   flush하는 순수 구조 로직이라, 자식이 파괴만 안 됐다면 그대로 옮겨감.
>
> **남는 숙제(그래서 지금 확정 안 하고 열어둠)**:
> 1. **어느 경로가 비파괴가 되어야 하는가** — `reconcile` 전체를
>    `rawExtract`로 바꾸면 "안 쓰는 서브트리가 조용히 안 죽는" 누수가 되기
>    쉬움. 사용자가 명시적으로 고르는 opt-in이 맞아 보임.
> 2. **`destroySlotTree`가 하는 나머지 일들의 짝** — 자식 observer
>    `unbindLifetime`, `Dispatch.setLength`/`setOffsetSource`로 옛 owner에
>    등록해둔 항목 정리. 비파괴 경로는 이것들을 "해제 후 새 owner에 재등록"
>    해야 하는데, 지금 `attachSlot`은 등록만 하고 해제하는 짝이 없음.
> 3. **`Extract` 후 재마운트 전까지의 중간 상태** — 소유자 없이 물리
>    트리에서도 떨어진 Slot이 얼마나 오래 떠 있어도 되는지.

**세 숙제의 결말**(전부 같은 세션에 해소):
1. **사라짐** — opt-in이 아니라 기본 동작이 됐으므로 "어디에 opt-in할지"라는
   질문 자체가 없어짐.
2. **해소** — 새 API 필요 없음(사용자 지적). 옛 owner에 대해
   `setOffsetSource(ownerKey, position, None)` **다음에**
   `setLength(ownerKey, position, 0)`을 부르면 됨(이미 확정된 "마운트 안
   하는 위치는 `0`/`None` 등록" 관용구 그대로). **순서가 중요** —
   `setLength`가 끝에서 `recompute`를 돌리므로 먼저 부르면 아직 남아있는
   옛 `Source`에 헛된 `:Set()`이 날아감(`base/slot-plan.md`의 ⚠️ 절).
3. **해소** — "아무도 안 들고 있으면 GC, 지금 죽이려면 `dispose`".

`state<state<Frame>>`류로 offset이 밀리는 문제는 `state<state<Tag>>`와 같은
범주로 **"그냥 확인된 것"으로 수용**(평탄화 도구가 처리, 케이스 드묾).

---

## 5. 파급 — 이 역전이 건드린 곳

- `base/slot-plan.md` — `rawUnmount`/`unmountSlotTree` 신설,
  `reconcile`이 부르는 함수 교체, 문서 앞부분 "상태" 줄의 "retract=폐기"
  표기 정정(2026-08-13 감사에서 뒤늦게 발견된 잔존).
- `.claude/question.md` — 0-B(`dispose`)/0-C(포탈) 신설, 확정 요약표의
  Slot 행 정정.
- `.claude/README.md` — `slot-plan.md` 행에 이 역전 반영.
- `ROADMAP.md` — 비파괴 경로 `unmountSlotTree`를 별도 구현 항목으로 추가.
- `research/documentation-content-map.md` — "retract=폐기 확정 히스토리
  (portal 검토 후 기각)"를 심화 문서 소재에서 **"왜 한때 destroy+no-portal로
  결정했었는가"라는 히스토리 소재**로 격하.
