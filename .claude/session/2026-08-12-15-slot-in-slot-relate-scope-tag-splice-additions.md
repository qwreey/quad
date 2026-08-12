# 2026-08-12 열다섯 번째 세션 — Slot-in-Slot relate 범위 확인, `Tag:Added` vararg, `Slot:Splice` 신설

사용자가 지난 며칠간 확정한 설계를 4개 항목으로 재확인, 1개는 문서 불일치를
발견해 수정, 2개는 새 CRUD/API를 추가.

## 확인만 하고 넘어간 것 (문서와 일치, 변경 없음)

1. **Slot-in-Slot의 `slotOwner`/`kSlotMap` relate는 최상위 마운트에만
   걸림.** `attachSlot`의 중첩 재귀(`slot-plan.md` "Slot-in-Slot 중첩" 절)는
   `Dispatch.process`를 다시 안 타고 직접 재귀 호출되므로, `SlotHandler.process`
   안에서만 세팅되는 이 relate는 중첩 자식 Slot엔 전혀 안 걸림 — 완전히
   별개 처리 확인(중첩 Slot의 중복마운트 방지는 별도의 전역 element
   weak-set이 담당, 서로 안 얽힘).
2. **`Animate`의 실제 반환 타입은 `State<Tween<T> | T>`.** `CanAnimate`가
   거짓이면 `Tween`으로 안 감싸고 plain `v`를 그대로 반환하는 분기가 이미
   `tween-plan.md`에 있음 — 확인만.
3. **Slot의 retract는 전부 파괴, 포탈 없음.** `Extract`/`ExtractAll`로
   미리 빼낸 것만 예외 — 이미 확정된 그대로.

## 수정한 것

4. **`Tag:Added`/`:Removed`가 문서상 단일 `name`만 받고 있었음 —
   `string | {string}`으로 정정(같은 세션 두 단계로 수렴).** 원래
   `Tag(a,b)`를 `Tag():Added(a):Added(b)`(clone 2회)의 sugar로 서술했는데,
   사용자가 태그 여러 개를 한 번에 걸 때 이름 개수만큼 clone+해싱이
   반복되는 손해를 지적. **1차 정정**: `Added(name, ...)`로 vararg 지원.
   **2차 정정(같은 세션 후속)**: 사용자가 실사용 패턴 지적 — 조건절로
   이름 목록을 동적으로 조립하는 경우(`if cond then table.insert(names,
   "x") end`)엔 결국 `Added(table.unpack(names))`로 풀어야 해서 vararg가
   더 번거로움, 차라리 `string | {string}`을 받아 내부에서
   `type(v) == "table"`이면 순회(flatten)하는 게 더 단순 — 최종 채택.
   self-return 최적화(이미 걸려있으면 그냥 self 반환)도 검토했으나 매번
   먼저 멤버십을 읽어야 해서 오히려 더 비싸 기각(`tag-plan.md`).

## 추가한 것

5. **`Slot:Splice(index, removeCount, ...newElements): {T}` 신설.**
   `ExtractAll`은 이미 있었지만, 한 구간만 비파괴 제거+삽입하는 배치
   연산은 없어서 `Extract`/`Add`를 요소 수만큼 반복하면 그때마다 개별
   shift+`recompute`가 돌아 비용이 곱으로 커지는 문제가 있었음 — 시프트
   1회+recompute 1회로 묶는 순수 최적화로 추가(새 능력이 아니라 기존
   CRUD 반복으로도 재현 가능한 결과, 비용만 다름). 비파괴(제거분은 파괴
   안 하고 반환) — 실제 물리 detach/reattach는 기존 base/roblox 패키지
   경계 그대로 backend Handler 몫(`slot-plan.md`).

## 후속 — `Tag:Added` 재정 근거 보강, `Slot:Splice`는 vararg로 확정

`Tag:Added`가 `string | {string}`로 간 진짜 이유를 사용자가 더 정확히
짚음: 단순 번거로움이 아니라 **Lua `table.unpack(t)`가 인자 목록의 tail
위치에 있을 때만 완전히 펼쳐지고, 그 뒤에 다른 인자/다른 `unpack`이 오면
첫 값 하나로 잘리는 문법적 한계** — 조건절로 조립한 여러 개의 독립된
동적 이름 테이블을 한 `Added` 호출로 합치는 게 vararg로는 애초에 표현이
안 됨(`tag-plan.md`에 이 설명으로 보강). 이 논거가 `Slot:Splice`의
`newElements`에도 적용되는지 검토했으나 **기각, vararg 유지** — (1)
한 번에 갈아끼우는 요소 수는 호출부가 아는 소수인 경우가 대부분이고
정말 동적이면 Slot-in-Slot으로 흡수 가능해 `Splice` 자체가 그 케이스를
떠받칠 이유가 없음, (2) `T | {T}`는 `Slot`의 `T`(`Instance | Slot`)가
이미 테이블이라 "단일 T(마침 테이블)"와 "{T} 배열"을 구분 못 해 오히려
틀림 — `Tag`의 `T=string`(항상 non-table)이라 안전했던 것과 다름
(`slot-plan.md`에 반영).
