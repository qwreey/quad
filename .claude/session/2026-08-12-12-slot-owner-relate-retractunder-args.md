# 2026-08-12 열두 번째 세션 — Slot의 `slot→inst` 소유권 relate, `retractUnder` 4-인자 이유

## 배경

직전 세션(열한 번째, "retract는 항상 불림" 전면 정정)에서 고친 `Slot`의
`retract`/`process` 의사코드를 사용자가 검토하다가 두 가지를 짚음.

## 1. Slot의 "같은 값인가" 판정 — 위치 비교 대신 `slot→inst` 소유권 추적

기존 의사코드는 `(inst,k)`별 relate로 "이 위치에 이전에 뭐가 있었나"만
비교했음 — 사용자 지적: Slot은 이미 "한 element가 어디에도 중복 마운트
안 됨"이 전역 불변식인데, 위치 비교로는 "이 Slot이 지금 *다른* 위치에도
동시에 마운트돼 있는가"를 못 잡음(같은 Slot 객체를 실수로 두 군데
`Frame`에 넣는 경우 등). 대신 `Relate<slot → inst>`로 각 Slot 자신이
지금 어느 `inst`에 바인딩됐는지 직접 추적하면: `owner == inst`(같은
자리로의 단순 emit 전파)면 무시, `owner`가 다른 inst면 즉시 error(다중
마운트), `owner`가 없으면 정상 바인딩. `attachSlot`이 이미 quad-roblox
소속이라 `inst`를 아는 것 자체는 자연스럽고, 몰라도 무관하게 동작함.

**반영**: `base/slot-plan.md` "Slot과 Store 바인드의 관계" 절 의사코드를
`kSlotMap`(위치별, retract가 뭘 지울지 알기 위한 용도로 존속)+`slotOwner`
(Slot별, 소유권 판정용 신설) 두 릴레이션으로 재작성.

## 2. `Dispatch.retractUnder(inst, k, keep, v)`가 왜 4-인자인가

사용자 질문: 설계상 `(inst, key, newValue)` 3개면 되고 `oldValue`는
각 핸들러가 자기 `Relate`로 직접 저장하기로 한 거 아니었나(Dispatch가
일괄 저장하면 "저장할지 말지 모르는" 부작용이 생겨 처리 함수가 담당하기로
했던 결정) — 그런데 왜 4번째 인자가 있는지.

**답**: `keep`과 `v`는 서로 다른 문제를 풂. `keep`은 "체인의 어느
항목이 호출자 자신이라 retract하면 안 되는지"를 정하는 구조적 파라미터
(StoreBind 같은 래핑 핸들러가 자기 자신은 안 지우고 그 아래로 위임된
것만 지우기 위해 필요, `keep=nil`이면 전체 체인 청소). `v`는 old value
저장이 **아니라** — 이번 대화 전체에서 만든 메커니즘(Tag의 `Contains`
힌트, Ref/Slot의 identity 비교, Attribute의 `v==nil` 게이트) 자체가
`retract`가 "새로 들어올 값"을 미리 아는 것에 의존하고 있어서, 그
힌트를 실어나르는 용도. `cutoff+1`(직접 대체되는 항목)만 진짜 `v`를
받고 그보다 깊은 항목은 `nil`을 받음 — "무엇으로 대체됐는지"가 유의미한
건 바로 다음 항목뿐이라서. old value를 각 핸들러가 자기 `Relate`로
저장한다는 원래 결정은 전혀 안 바뀜 — `retractUnder`는 old를 옮긴 적이
없고, 지금도 없음.

## 반영

- `base/slot-plan.md` — 위 1번 의사코드 정정.
- 2번은 순수 설명(질문에 답변) — 문서 반영 대상 없음, 기존 `retractUnder`
  시그니처/동작이 이미 정확했음을 확인만 함.
