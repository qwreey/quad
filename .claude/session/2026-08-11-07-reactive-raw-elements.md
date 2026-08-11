<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-11 일곱 번째 세션 — 반응형 raw 요소: Slot이 `State<T>`/`Source<T>`도
요소로 허용(`:Single` sugar로), `:List`의 index-스킵 보강

짧은 세션. 사용자가 "Slot이 `state<slot>`/`state<frame>`을 안 받는데,
`setLength`/`setOffsetSource`를 재사용하면 쉽게 구현 가능하지 않냐"고
제기하며 시작 — 최초 검토안이 사용자의 즉각적인 반례로 기각되고 훨씬
단순한 최종안으로 수렴한 단일 스레드라, 시행착오 없이 최종 확정만
정리(경위는 아래 "기각된 최초안" 절에 압축 보존).

**확정**: `Slot:Add`(및 `Slot(initial)` 생성자 sugar)가 받는 `element`의
타입이 `T | State<T> | Source<T>`(`T = Instance | Slot<Instance>`, 여섯
번째 세션에 확정된 자기 참조 제네릭과 합성)로 확장 — 임의 깊이 nesting
가능(사용자: "이게 얼마나 nesting되는지는 유저 마음, 다 처리가 가능함").
**구현은 새 메커니즘이 아니라 순수 `:Single` sugar**: `isState(element)`면
그 자리에 내부적으로 `Slot():Single(element)`(nested Slot, `updateFn`
생략 시 identity 기본값)를 대신 삽입 —

```lua
function Slot:Add(element, index)
    if isState(element) then
        local sub = Slot()
        sub:Single(element)   -- updateFn 생략 → identity 기본값
        element = sub
    end
    return rawAdd(self, element, index)
end
```

이 sugar가 성립하도록 `Slot:Single(state, updateFn?)`도 같이 확정 —
`updateFn`을 선택 인자로 완화(기본값 `function(item) return item end`).

**기각된 최초안 — position-keyed StoreBind 구독 + `state:Compute`로
파생한 Length.** 처음엔 `rawAdd`가 그 위치에 대해 별도 재-dispatch
구독을 걸고 Length 기여도도 `state:Compute(...)`로 파생시켜 `setLength`에
넘기는 방식을 검토했으나, **사용자가 즉시 반례를 제시해 기각**: "state
언랩 시에 None 되는게 복잡함. 그럼 slot 사이에 None이 존재할 수 있게
되는 거 아님? Length 계산도 달라져야 하고, Add/Remove 동작성이 문제가
됨 — 사실상 Slot:Single이랑 정확히 같은 구현이 돼야 함." 검증 결과
정확함 — (1) `State<T?>`(nilable)를 지원하려면 `_elements`에 `None`을
다시 끌어들여야 함, (2) Length 계산에 예외가 생김, (3) `Move`/`Swap`이
인덱스를 옮길 때마다 그 위치의 구독도 같이 옮겨야 하는 인덱스-구독
동기화 부담이 생김 — **정확히 `:List`가 element가 아니라 `key` 기준으로
설계된 이유와 정면 충돌하는 회귀**였음.

**위 확정된 sugar가 이 세 문제를 전부 없애는 이유**: 바깥 `_elements`엔
항상 안정적인 `sub` Slot 레퍼런스만 있어 `None`이 안 들어가고, `sub`가
비어있는 것 자체가 이미 지원되는 정상 상태(Length 0 자동 기여)이며,
Remove/Move/Swap도 그 `sub` 레퍼런스 하나만 다루면 끝이라 인덱스-구독
동기화가 필요 없음. raw `State<T>` 요소는 결국 "`updateFn` 생략한
`:Single`"일 뿐이고, `:Single`에 `updateFn`을 직접 주면 `prev`/`userdata`
patch-reuse + `offset` 접근이 되는 상위 호환 — 둘은 대체 관계가 아니라
같은 메커니즘의 다른 `updateFn`.

**`:Single`이 애초에 생긴 이유가 정확히 이 offset 접근**(사용자 직접
확인): "`Single`은 정확히는 `updateFn`에서 렌더할 때 `offset`이 필요해서
만들어진 것" — raw `State<T>` 요소(identity `updateFn`)는 값이 바뀔
때마다 이전 mount를 통째로 버리고 새로 만드는 coarse swap(quad가 `prev`
재사용을 안 해줌)인 반면, `updateFn`을 직접 지정한 `:Single`은 같은
Instance를 유지하며 속성만 patch하는 fine-grained 갱신 + `offset`을
`updateFn`에 직접 전달. 사용자가 제시한 조합 예시(`Slot{ State<Frame>
--[[리스트헤더]], Slot():List() --[[아이템]] }`)를 문서에 그대로 반영 —
LayoutOrder(offset) 참여가 필요 없는 요소는 raw `State<T>`로 가볍게,
개수/순서가 동적이라 offset이 필요한 그룹은 `Slot():List(...)`로
감싸는 식으로 한 Slot 안에서 자유롭게 섞어 씀.

**부수 발견(사용자) — nested-Slot 결과를 반환하는 `:List` 아이템의
`index` 스킵.** "상위 입장에서의 인덱스는, Slot이 있으면 크게 건너뛰겠네
아마 의도된 동작이긴 할듯"라는 지적 — 검증 결과 맞음: `updateFn`이
nested Slot(멀티루트 컴포넌트 결과 등, Length=N)을 반환하면 그 아이템은
물리적으로 1개가 아니라 N개를 차지하므로, `reconcile`의 `pos` 커밋이
고정 `+1`이 아니라 `+result.Length`여야 다음 형제의 `index`가 LayoutOrder
계산에서 안 겹침 — `pos = candidateIndex - 1 + (isSlot(result) and
result.Length:Get() or 1)`로 수정, 의도된 동작으로 확정. 남는 캐비엇(그
Length가 outer `:List`의 reconcile 없이 나중에 바뀌면 `index`가 스냅샷인
채로 안 갱신됨)은 이미 확정된 "`index`는 raw, 실시간 반응은 `updateFn`
몫" 원칙의 당연한 연장이라 새 문제로 취급 안 함.

**반영된 파일**: `base/slot-plan.md`(요소 타입 제약 절 갱신, "반응형 raw
요소" 신규 절, `:Single`의 `updateFn` 선택 인자화, `reconcile`의 `pos`
커밋 공식 수정)/`ROADMAP.md`(M6)/`.claude/README.md`/`.claude/question.md`.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.
