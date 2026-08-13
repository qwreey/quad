# 2026-08-13 여섯 번째 세션 — c33ae04 커밋 전체 감사, 인덱스 재설계 의사코드의 실제 버그 4건 + 전파 누락 정리

사용자 요청: "c33ae04 커밋이 정확한지 봐줘. 많은게 바뀌여서 정확한지 검토해야함.
너가 직접 봐야할듯. 전체 문서에 잘못된 부분이 있는지, 로직이 이상한게 있는지.
더 나은 로직이 있는지 전체 감사 처리를 해줘" — 서브에이전트 위임이 아니라
메인 컨텍스트에서 직접 읽으라는 명시적 지시라 그렇게 진행.

## 총평

재설계 **방향 자체는 옳음** — 인덱스 기반 재추적, `State<State<T>>` UB 해소,
`retractUnder`/`retractSelfAndUnder` 통합, 체크포인트 패턴 철회, `Relate`
대량 정리 전부 근거가 맞고 `archive/checkpoint-handler-pattern-reversed.md`도
정확함. 문제는 **그 결정에 맞춰 새로 쓴 의사코드들이 손 트레이싱을 안
거쳤다는 것** — 네 번째 세션이 "합성 시나리오를 pseudocode에 손으로 대입해
버그 찾기" 라운드였는데, 정작 그 결과로 다섯 번째 세션이 새로 쓴 코드에는
같은 방법을 안 돌린 채 커밋됨.

## 발견된 실제 버그 4건

### 1. `Dispatch.process`가 하위 위임 retractor를 통째로 유실 (치명)

`bind-system-plan.md`의 `chains` 의사코드가 `chains:SetStrong(inst,k,list)`를
`h.process` **뒤**에 두고 있었고, list 확보도 `chains:GetStrong(...) or {}`
였음. `h.process`가 내부에서 재귀 `Dispatch.process(...,index+1)`을 부르는 게
정상 경로(StoreBind/NoneHandler)인데, 최초 마운트 시점엔 chains에 아직
아무것도 없어 **재귀 호출이 `or {}`로 자기만의 새 테이블을 만들어 저장한 뒤
바깥이 그걸 덮어씀.**

`Frame { Text = state }` 트레이싱:

| 단계 | chains |
|---|---|
| process(idx1) StoreBind 진입, list={} (미저장) | 없음 |
| ㄴ observer 즉시 1회 → process(idx2) Property | `{[2]=noop}` (별도 테이블) |
| StoreBind 반환, `list[1]=r1`, SetStrong(list) | **`{[1]=r1}`** — 앞의 것 유실 |

증상: 이후 첫 재발행에서 `retractFrom(inst,k,2,...)`가 `#list==1`이라 아무것도
안 부름. Property(no-op)면 무해하지만 **인덱스 2가 Slot이면 이전 서브트리가
파괴 안 된 채 새 서브트리가 마운트(자식 중복)**, Ref면 이전 Ref가 stale하게
남음. 즉 이 재설계의 핵심인 다단 체인 정리가 최초 마운트 경로에서 통째로
깨져 있었음.

수정: `SetStrong`을 `h.process` 위로 hoist. 추가로 `h.process` 호출 전에
no-op 점유 마커를 박도록 함 — 재귀 중 list에 구멍이 생기면 `#list`가
Lua에서 미정의이고(hole 있는 테이블), 같은 index 재진입 버그도 가드에
안 걸리기 때문.

### 2. Attribute 그룹의 소유권 충돌 감지가 실제로는 절대 안 걸림 (치명)

`attribute-plan.md` "이름 소유권" 절은 "점유 체크가 소유권 충돌 감지를
그대로 대신함"을 이번 재설계의 핵심 근거로 선언하는데, 정작 "메커니즘"
절 코드가

```lua
Dispatch.retractFrom(inst, key, 1, source)  -- 인덱스 1을 무조건 비움
Dispatch.process(inst, key, source, 1)      -- → 점유 error가 날 수가 없음
```

이라 **그룹↔그룹 사이에서 조용한 last-write-wins가 그대로 남아 있었음**
(그룹 B가 그룹 A의 바인딩을 파괴하고 이김, 나중에 A의 클로저가 돌면 B의
바인딩을 대신 철거). 이 절이 없앴다고 선언한 바로 그 문제.

(그룹↔직접 리터럴 쓰기 방향은 정상 작동했음 — 배열파트가 먼저라 그룹이
점유하고, 해시파트 직접 쓰기는 `retractFrom` 없이 `process`만 부르므로.)

수정: `retractFrom`을 `process`에서 빼고 **반환 클로저가 자기가 등록한 이름
전부를 철거**하도록 이동. 생존 이름도 매 사이클 철거→재등록되는 비용이
생기지만(구독 해제+재구독, 같은 값 `SetAttribute` 1회) 이 문서가 이미
"값 비교는 안 함"을 확정해둬서 결이 같음. **`Tag`식 `hintValue == v` 조기
반환을 여기 넣으면 안 됨** — 클로저가 아무것도 안 걷어낸 채 다음 `process`가
같은 인덱스를 잡으려 들어 자기 자신에게 점유 error를 냄.

### 3. `SlotHandler`가 claim 실패에도 파괴적 클로저를 반환 (치명)

`claimOwner`의 `current == ownerKey → return false` 분기가 **두 개의 서로 다른
상황을 구분 못 함**:
- 같은 `(inst,k)`의 spurious 재발행 (정상, no-op이어야)
- **같은 `inst`의 다른 위치** (`Frame { slot, slot }`) — error여야 하는데 false

후자에서 attach는 건너뛰면서 파괴적 클로저는 그대로 반환해서, 철거 시
`destroySlotTree` 두 번 + `unbindLifetime` 짝 어긋남 + `releaseOwner`가
(이번 세션에 새로 넣은 엄격 버전이라) error로 터짐. 구 설계는 `kSlotMap`에
안 적힌 자리의 `retract`가 자연히 no-op이라 우연히 막혀 있었고, `kSlotMap`
제거가 그 방어를 같이 걷어낸 회귀.

**감사 중 오답 하나 — 기록해둠**: 처음엔 "claim 실패 시 no-op 클로저를
반환"으로 고치려 했는데 이건 더 나쁨 — `retractFrom`은 클로저가
early-return하든 말든 체인에서 **항상 소비**하므로, spurious 사이클에서
no-op을 심으면 다음 진짜 교체 때 이전 서브트리를 정리할 주체가 사라짐.
원래의 단일 파괴적 클로저 구조가 맞고, 고칠 곳은 `claimOwner`뿐이었음.

### 4. `Ref` retractor가 자기 dedup을 스스로 무력화

```lua
if hintValue ~= v then v:Set(nil) end
if relate:GetStrong(inst, k) == v then relate:SetStrong(inst, k, nil) end  -- 무조건
```

spurious 재발행에서 `Set(nil)`은 건너뛰지만 relate를 지워서, 이어지는
`process`의 `old ~= v`가 항상 참 → `v:Set(inst)` 재실행 → 콜백 헛 재통지.
바로 아래 산문이 약속한 "spurious면 둘 다 스킵"이 성립을 안 했음.
사용자가 이 건은 즉시 확인해줌("4. 는 확인했어요 맞습니다").
수정: relate 정리를 `if hintValue ~= v` 블록 안으로.

## 사용자 제기 — Slot-in-Slot / `state<Slot>` 소유권

> "slot in slot 을 생각해보면 a=Slot {}; Slot{a,a} 도 UB 여야할텐데,
> Slot{state<Slot>} 또한 가능합니다. ... Slot in slot 도 안전해야하는데,
> 저는 후자가 맞는듯 합니다."

조사 결과 **후자가 맞고 실제로 성립하지만, 추가 수정 셋이 필요했음**:

- **N1**: `rawAdd`가 `claimOwner`의 반환값을 아예 안 봄 → `Slot { a, a }`가
  조용히 통과해 `_elements={a,a}`, `attachSlot`이 두 번 불려 부모
  `lengthList`에 같은 Slot이 두 번 계산되고 `slot.Offset`도 두 번째가
  덮어써 첫 `Source`가 고아가 됨.
  → **nested엔 "재클레임"이라는 개념이 애초에 없음**(reconcile은 항상
  `rawRemove`→`rawAdd` 순서, `rawMove`/`rawSwap`은 클레임 미접촉)이라
  엄격 error가 맞음. top-level만 `claimOwnerAt(element,inst,k)`으로 위치까지
  봐서 spurious를 구분.
- **N2 (위치 키잉이 안전한 이유, 사용자 확인)**: "바깥 slot 안에서의 인덱스는
  여전할거예요. 오직, flatten 되어진 상태에서의 위치만 달라질 뿐이고 ...
  offset/index 구현이 그걸 증명해요" — 물리 배치 변동은 전부 `offset`이
  흡수하도록 설계돼 있고, top-level의 `k`는 props 배열 리터럴 위치라 더욱
  고정. nested는 `Move`/`Swap`/`Splice`가 인덱스를 밀지만 위 결론대로
  위치를 안 쓰므로 무관.
- **N3**: `rawRemove` 의사코드에 `releaseOwner`가 아예 없었음(산문 쪽은
  있다고 명시 — 코드/산문 불일치).
- **N4**: `destroySlotTree`가 자식 `releaseOwner`를 안 하고 `_mounted`/
  `_mountedInst`도 안 되돌림 → `elementOwner` 값이 weak라 "언젠간 사라지지만
  **언제인지가 GC 타이밍에 달려서**" 그 전에 같은 element를 재사용하면
  "이미 마운트됨" error가 비결정적으로 터짐.

`state<Slot>` 자체는 구조가 `outer._elements[i] = sub`(래퍼 Slot, 영구 고정)
→ `sub:Single(state)` → `:List` reconcile이 안쪽만 교체이고, reconcile이
`rawRemove(prev)` 다음 `rawAdd(result)` 순서라 소유권이 release→claim으로
정확히 갈림. **즉 "래퍼가 불변이라 괜찮다"가 아니라 nested CRUD의
release→claim 규율 자체가 안전성을 만듦** — 그래서 손으로 중첩한
`Slot{Slot{Slot}}`도 같은 규칙 하나로 동작. 이 결론을 `slot-plan.md`에
표와 함께 별도 절로 기록.

## 그 외 수정

- `AttributeGroupHandler.process(inst, index, v)` — 코퍼스에서 유일하게 계약
  (`process(inst,k,v,index)` 4-인자)과 안 맞던 시그니처. 배열 위치를 하필
  `index`로 불러 새 `index` 파라미터와 충돌하기까지 했음.
- `Dispatch.drive`의 진입 인덱스(`1`)가 어디에도 안 적혀 있었음.
- retractor 안에서 **같은 키**에 `retractFrom`을 부르는 것도 `process`처럼
  금지(진행 중인 루프가 `#list`를 이미 캡처)임을 명문화 — 원래는 "다른
  키에 대해서는 문제없음"이라는 괄호로만 암시됐음.
- 깊은 체인에서 hint 유실: `retractFrom`은 `v`를 `i == index`에만 넘기므로
  `State<State<Tag>>`의 바깥 재발행에선 TagHandler가 `nil` 힌트를 받아
  RemoveTag→AddTag 깜빡임. 구조상 불가피(바깥은 안쪽 값을 모름)해서
  `tag-plan.md`의 깜빡임 방지 주장을 "직속 위임 1단계 한정"으로 범위 축소.
- 미문서화 접근자 `Tag:Names()`/`Attribute:NameMap()`을 각 API 절에 추가.

## 전파 누락 정리 (커밋이 안 건드린 것들)

- **`ROADMAP.md`가 전혀 갱신 안 됨** — CLAUDE.md가 "구현 순서의 소스"라고
  못박은 문서인데 M2 `Dispatch/init.luau` 항목이 아예 2026-08-08 이전 모델
  ("이전 담당자와 다르면 그 `retract`")이었고, `chains`도 핸들러 배열,
  `retractUnder`도 그대로. M2/M4/M7 전부 새 모델로 갱신 + 위 버그 1을 다시
  내지 않도록 "구현 시 반드시 지킬 것" 체크리스트 추가.
- **base 안에서 계약 개수가 모순** — `store-semantics.md`는 이번에 3종으로
  고쳤는데 `module-lifecycle-plan.md`/`component-composition-plan.md`는
  4종, `ui-shorthand-plan.md`/`onchange-plan.md`/`tween-plan.md`/
  `lifecycle-pattern.md`는 별도 `retract` 필드 전제. 전부 갱신
  (`onchange-plan.md`는 단순 이름이 아니라 Connection Disconnect 로직이
  반환 클로저로 이동해야 하는 실질 변경이었음).
- `luau-test/04`가 **설계와 정반대를 검증 중**이었음 — 파일명부터
  `retractUnder`이고, 다섯 번째 세션이 **없앤** "중복 핸들러 즉시 error"
  가드를 테스트하는데 `luau-test/README.md`는 "[2026-08-13 재작성] 신규
  가드가 즉시 error하는지"라고 최신인 척 적어놨음. `04-dispatch-chain-
  retractFrom.luau`로 전면 재작성 — 인덱스 기반 3단 체인, 깊은 쪽부터
  정리, hint 전달 범위 + **버그 1을 재현하는 음성 대조군**(`SetStrong`을
  `process` 뒤로 옮기면 체인 깊이가 1로 무너지는지)을 포함. 옛 04의
  no-op retract 스텁이 사각지대였던 전례를 반복하지 않도록 이번엔
  retractor가 실제로 구독을 끊음.
- `luau-test/19` B/C 섹션이 폐기된 설계(`rawNew`+`owners`, 3분기
  `claimOwner`)를 검증 중 — 파일 헤더에 무엇을 어떻게 다시 써야 하는지
  배너로 명시(재작성 자체는 미착수).
- `slot-plan.md`의 GC 주의 문단/`relate-plan.md`가 `kSlotMap`/`slotOwner`를
  현재 설계처럼 서술하던 것을 역사 표시로 정정(둘 다 지금은 없음 — 일반
  규칙은 계속 유효).
- `.claude/README.md`의 `SlotHandler.retract` 언급 제거 + 세 행에 이번
  감사 결과 반영.

## 남은 것

- `luau-test/19` B/C 섹션 재작성(헤더에 지시만 남김).
- 스파이크 실측 자체는 여전히 미실행(이 환경에 `luau` 바이너리 없음) —
  새로 쓴 `04`의 음성 대조군이 실제로 깊이 1로 무너지는지 확인하면
  버그 1의 재현·수정이 실측으로 닫힘.

## 후속 라운드 (같은 세션, 사용자 추가 질문)

### `State<Slot?>`의 사라짐/재등장, 그리고 포탈

사용자 질문: `stateSlot: State<Slot?>`를 `Slot { stateSlot }`에 넣고
지웠다 나타나게 하면 문제 없는가. 그리고 `Get()`으로 뽑아두고 `Set()`으로
갈아끼운 뒤 뽑은 걸 다른 데 넣을 수 있는가 — 되면 포탈이 해결됨.

- **소유권 bookkeeping은 정상**(이번 감사 수정 이후) — reconcile이
  `rawRemove`(→`releaseOwner`) / `rawAdd`(→`claimOwner`)로 깨끗이 갈림.
- **그러나 Slot 자체가 파괴됨** — reconcile이 쓰는 게 `rawRemove`(제거
  **+ 파괴**)라 `nil`이 되는 순간 `destroySlotTree`가 자식 Instance를
  `:Destroy()`함. 같은 Slot 객체를 `nil`↔`slotA`로 왕복시키면 두 번째
  등장부터 껍데기만 재마운트됨. 기존 "폐기, 옮기지 않음" 정책의 직접
  귀결이지 이번 감사로 바뀐 게 아님.
- **포탈은 현재 불가, 그러나 부품은 이미 다 있음** — 막는 건 소유권
  규칙이 아니라 "제거 = 파괴"라는 reconcile의 선택 하나뿐이고,
  `Extract`/`ExtractAll`/`Splice`가 이미 비파괴로 확정돼 있고
  `attachSlot`이 재마운트를 구조적으로 이미 지원함(이번에 넣은
  `destroySlotTree`의 `_mounted` 복원이 마침 그 전제 조건이기도 함).
  **"포탈은 별도 메커니즘이 필요하다"는 기존 전제가 틀렸을 가능성이
  큼** — 남는 실제 작업은 (1) 비파괴를 어디에 opt-in으로 열지, (2)
  `attachSlot`의 등록(`setLength`/`setOffsetSource`/자식 observer)에
  대응하는 **해제 짝**이 지금 없다는 것. 확정은 사용자 몫이라
  `question.md` 0-A로 올리고 `slot-plan.md`에 상세 기록.

### `State<Tag>`는 힌트를 확실히 받는가 — 받음

`retractFrom`은 힌트를 `i == index` 자리에만 넘김. 한 겹
(`StoreBind@1` → `TagHandler@2`)에서는 StoreBind가
`retractFrom(inst,k,2,realv)`를 부르므로 정확히 그 핸들러에 걸림 —
**유실 없음**. 두 겹 이상에서 바깥이 재발행할 때만 안쪽이 `nil`을 받음.
이 계약을 `bind-system-plan.md`에 명시적으로 못박음(원래는 의사코드에만
있었음).

### 사용자 제안 — 핸들러 identity를 저장해두고 값을 한 겹 풀어 내려보내기

기각. 사용자 스스로 지적한 이유(=`process`와 retractor가 1:1이 아니고
retract만 나는 경로가 정상적으로 존재해서 내려보낼 "새 값"이 없는
경우가 있음)에 더해, 더 근본적인 이유가 있음: 값을 한 겹 풀려면
teardown 도중 `innerState:Get()`을 **투기적으로** 호출해야 하는데,
State는 pull-recompute라 실제 재계산을 유발하고 곧이어 `process`가 다시
`:Get()`을 불러 같은 사이클에 이중 계산이 됨. 게다가 그렇게 얻은 값은
추정이라 실제 `process` 시점 값과 다를 수 있음("값 비교/캐싱 금지"
원칙과 충돌).

**대신 채택 방향(사용자 제시)**: 값 층에서의 평탄화
(`State<State<T>>` → `State<T>`). 체인이 한 겹으로 유지되면 위 보장이
그대로 적용되므로 Dispatch에 특수 배관이 필요 없어짐. 백로그로만 등록
(`research/operator-sugar-plan.md`) — 2026-08-13 두 번째 세션의 Haskell
비교가 이미 "Monad join이 미일반화 후보"로 짚어둔 자리에 구체적 동기가
붙은 것. `State<State<T>>`는 UB는 아니지만 권장 방향도 아니라는 사용자
판단을 그 문서에 명시.

### 재발 방지 조치 (사용자 요청)

"새로운 모델로 인해 생겨날 수 있는 흔한 실수들이 재발하지 않도록 잘
정리해주세요. Relate 나 Dispatch/Handler 전반에서 더 실수가 나오지
않도록 조치가 필요해보여요."

- `bind-system-plan.md`에 **"Handler 작성 체크리스트 — 새 모델에서 실제로
  반복된 실수들"** 절 신설(7항목). 이번 세션 버그 4건이 서로 다른 문서에
  있으면서도 같은 종류의 착각에서 나왔다는 관찰이 출발점 — 특히 (1)
  "클로저는 early-return해도 체인에서 소비된다"(no-op 반환 유혹), (2)
  "다른 키로 위임하며 그 키를 미리 `retractFrom`하지 말 것"(점유 체크
  무력화), (3) `hintValue`의 세 가지 함정(nil 아님/타입 미보장/깊은
  인덱스엔 안 옴)이 실제로 밟힌 것들.
- `relate-plan.md`에 **"언제 `Relate`를 쓰고 언제 쓰면 안 되는가"** 절
  신설 — 클로저 캡처로 충분한 경우 vs 진짜 필요한 경우의 경계, 그리고
  "정리 조건을 실제 정리와 묶을 것"(Ref 버그), "weak라고 GC에 기대지
  말 것"(Slot 버그) 두 규칙.

## 세 번째 라운드 (같은 세션) — 사용자 설계 결정 3건

### A. `State<Slot>` 교체는 파괴가 아니라 **언마운트** (확정, 앞 라운드 결론을 뒤집음)

앞 라운드에서 "reconcile이 `rawRemove`(파괴)를 쓰므로 포탈 불가"라고
보고했더니, 사용자가 **설계 자체를 뒤집음**: "state에서 slot 빼내면 빠질
수 있는게 나은듯. 애초에 스플라이싱을 지원하는데?"

근거:
- **`state<Frame>`가 이미 그렇게 동작함** — 다른 값으로 바꿔도 이전
  Frame을 quad가 지우지 않고 unmount만 함. `State<Slot>`만 다를 이유가
  없음. `Ref`("Destroy 무관")/`Attribute`("명시적 `None`으로만") 철학과도
  같은 결.
- 비파괴 추출(`Extract`/`ExtractAll`/`Splice`)은 **이미 지원되는 개념**.
- "뽑아냈으면 리프의 소유가 아닌 게 맞아보임. 명시 `:Destroy()`를 하도록
  유도하는 게 이로운 것 같음."
- "슬롯은 '들고 있다 죽으면' 같이 소멸한다" — GC-native 그대로.

부수 효과(사용자 지적): 하위 요소까지 `bindLifetime`하고 `canExecute`를
확인하게 하면, "nested로 마운트 후 Instance를 제거하고 그 Slot을 뽑아
쓰려는" 경로가 **별도 방어 없이 자연히 막힘** — 기존 게이트를 한 층 더
촘촘히 적용하는 것뿐.

**그래서 포탈은 별도 기능이 아니라 이 결정의 귀결이 됨** — 앞 라운드에서
"opt-in으로 열지"를 열린 질문으로 뒀는데, 기본 동작이 되면서 그 질문
자체가 사라짐. **남은 실제 작업은 하나**: `attachSlot`이 등록하는 것들
(자식 observer `bindLifetime`, 옛 owner의 `setLength`/`setOffsetSource`)에
대응하는 **해제 짝이 지금 없음**.

곁들여 확정된 UB: **`Set`으로 덮어쓰기 *전에* 이전 값을 직접
`Destroy()`하는 것**(= `state<Frame>`에서 먼저 `frame:Destroy()`하고
`Set`하는 것과 같은 문제). 순서는 항상 `Set`(언마운트) → 그 다음 정리.

### B. `dispose(any)` 신설 방향 (사용자 제안)

위 UB를 "조심하세요"로만 두지 않기 위해, base 탑레벨 `dispose(value)`를
제공 — "이 값을 지금 확실히 없앤다, 아직 마운트돼 있으면 먼저 안전하게
떼어낸 뒤 파괴". 사용자 논증이 깔끔했음: **"이미 `a=Frame{}; Frame{a}
Frame{a}`가 에러나도록 하기로 했으니, 어디 마운트되었냐가 따져지고,
그래서 이미 가능한 일"** — `elementOwner`를 거꾸로 읽으면 되므로 새
부기가 필요 없음. 시그니처/대상 범위/`unbindLifetime`과의 분담은
`question.md` 0-B로.

### C. `hintValue` 폐기 제안 — 검토 결과 **사용자 지적이 맞음**

사용자 제기: "process 상 newv(hint) 처리가 단일 네스팅이면
None -> AttributeKey 같은걸 탄다던가 하면 머리아픈데. 괜찮은게 진짜
맞나 검토가 필요해."

**재현됨.** `[AttributeKey "foo"] = state`가 `5` ↔ `None`을 오갈 때
체인 모양이 `StoreBind→NoneHandler→AttributeKey`(None) ↔
`StoreBind→AttributeKey`(5)로 바뀌고, `5 → None` 전이에서 인덱스 2의
`AttributeKeyHandler` retractor가 **`hintValue = None`** 을 받음.
Attribute는 no-op이라 무해하지만 `TagHandler`였다면 `isTag(None)`이
거짓이라 이름 전부를 `RemoveTag`함.

**진짜 문제는 깊이가 아니라 "힌트의 타입이 계약으로 정해져 있지
않다"는 것**이었음 — 앞 라운드에서 문서화한 "깊이 2 이상에선 `nil`"은
이 결함의 한 특수 케이스일 뿐이었다는 게 이번에 드러남. 힌트가 `None`/
`State`/`Tween` 등 래퍼일 수 있어서, `Tag`의 `Contains` skip과
`Ref`/`Slot`의 identity 비교가 **정확성은 유지한 채 조용히 꺼짐**(그래서
지금까지 안 드러났음). `Slot`은 "가드 없으면 서브트리 전체 파괴 후
재생성"이라 파급이 큼.

**사용자 제안 방향**: 철거 후 힌트와 재구축 대신, process를 쭉 진행하며
각 자리에서 "이전 핸들러 vs 새 값에 매치될 핸들러"를 비교 — 다르면
그 아래 전부 죽이고, 같으면 값을 계속 전파하며 자기 인덱스에 대해서만
후처리. 전제 계약: **"`inst`에 실질적 처리를 가하는 건 항상 말단 핸들러,
중간 노드는 언워랩만"**. 결론적으로 **"새 프로세싱으로 인한 retract와
단순 retract는 다르다"**.

**검토 결과**:
- 전제 계약은 **기존 핸들러 9개 전부에서 이미 성립**(표로 확인) — 새
  제약이 아니라 이미 있는 성질의 승격이라 채택 비용이 낮음.
- 단, **"같은 핸들러면 유지"는 `StoreBind`에 그대로는 틀림** — 인덱스 2가
  `StoreBind`인 채 바깥이 새 inner State를 내놓으면 "같은 핸들러"지만
  옛 State에 구독돼 있어 갈아타야 함. → "유지"가 아니라 **"그 인덱스에
  `process`를 다시 호출(retractor는 안 부름)"** 이어야 함.
- 그러면 핸들러가 이전 값을 알아야 하는데 → **힌트 대신 `oldValue`를
  넘기자**는 보완 제안. `chains`가 retractor 옆에 `(handler, value)`를
  같이 저장하면 됨. `oldValue`는 *그 핸들러가 직전에 실제로 매치한*
  값이라 **타입이 구조적으로 보장**되어 `None`/래퍼 오염이 원천 차단되고,
  방향도 맞아서(`hintValue`는 "다음", `oldValue`는 "이전")
  `RefLeafHandler`의 dedup용 `Relate`도 없앨 수 있음. `isX(v)` 방어
  가드 규칙 자체가 힌트의 타입 미보장을 메우던 임시방편이었음이 드러남.
- **주의**: 같은 인덱스 재프로세싱을 허용하려면 점유 체크를 갈라야 하는데,
  **그 가드가 곧 Attribute 그룹의 소유권 충돌 감지**라 약해지지 않는지
  반드시 같이 확인해야 함(이번 감사에서 정확히 그 지점이 한 번 무너진
  전례가 있음).

**실행은 보류** — `base/` 4개 문서 의사코드 전면 재작성 규모라, 같은 날
두 차례 급하게 쓴 의사코드에서 버그가 나온 전례를 감안해
`research/dispatch-hint-to-oldvalue-plan.md`로 먼저 정리하고 확정 대기
(`question.md` 0-A). 그때까지 `base/`의 현행 `hintValue` 서술이 유효.

### D. 평탄화 백로그 상세화 (사용자: "백로그에서 더 자세히 다루도록 업데이트만 하자")

`state:Flatten()`/`Flat()` — `Operator.*` 자유 함수가 아니라 **State의
메소드**로 제공되어야 함(특정 노드를 따라가는 새 노드를 만드는 것이라
`:Compute`/`:With`와 같은 층위). 대상은 `State<State<T> | T>`(섞인
경우까지 흡수). **핵심 난점(사용자 지적): 반환 노드가 동적 의존성을
가짐** — quad가 암묵적 자동 추적을 기각했고 "동적 `:With` 미지원"을
2026-08-12 열여덟 번째 세션에 의도된 트레이드오프로 확정해뒀는데, 이
도구는 그 유일한 정당한 예외를 요구함. 확정 전 답할 것: 동적 의존성을
노드 내부에 가둬 바깥에선 평범한 `State<T>` 하나로 보이게 할 수 있는가,
옛 구독 해제 타이밍과 `bindLifetime` 귀속, 그래서 순수 슈가가 아니라
진짜 새 프리미티브인지(현재 판단은 후자). 착수 안 함.

## 네 번째 라운드 (같은 세션) — 사용자 반문으로 모델 확정, 내 제안 두 개 철회

### `dispose`는 "떼어낸 뒤 파괴"가 아니라 **"거부하고 error"**

> "dispose 는 정확히 Frame 이든, slot이든 어느 트리에 의해 살아 있는게
> 요구된다면 Destroy 거부한다, 에러를 낸다고 보면 되겠네요. 실제로
> 클리어 하거나 Destroy 해도 그냥 로블록스엔 에러 안 나는데, quad에선
> 데이터 구조가 깨지는 일이니까요."

내가 쓴 "먼저 안전하게 떼어낸 뒤 파괴"보다 훨씬 단순하고 맞음 — 떼어내는
건 `Set`(언마운트)의 몫이고 `dispose`는 그 뒤에 부르는 것. 이걸로
"`Set` 전에 직접 `Destroy()`"가 UB에서 **명확한 에러**로 바뀜.

### Slot의 "해제 짝"은 애초에 필요 없었음

> "옛 오너가 setLength/setOffsetSource 를 그냥 실행해도 된다는 생각.
> retract에서 hint 를 보고 Slot이 아니면 그냥 setLength(...0...)
> setOffsetSource(...None...) 될 수 있어요."

맞음 — 이미 확정된 "마운트 안 하는 위치는 `0`/`None` 등록" 관용구 그대로라
**해제 = 0/`None`으로 재등록**이고 새 API가 필요 없음. 앞 라운드에서
"이게 언마운트 전환의 실제 작업량"이라고 꼽은 판단은 과했음.
`state<state<Frame>>`류 offset 밀림은 `state<state<Tag>>`와 같은 범주로
**"그냥 확인된 것"으로 수용**(평탄화 도구가 처리, 케이스 드묾).

### 디스패치 모델 확정 — 내 반론 두 개가 다 틀렸음

**(1) "같은 핸들러면 `StoreBind`가 구독을 못 갈아탄다"** — 내가 사용자
제안을 "같으면 **유지**"로 잘못 읽은 데서 나온 반론이었음. 실제 제안은
"같으면 **내가 처리**"(= 그 자리 클로저 호출 → 자기 `process` 재호출)라
옛 구독 해제와 새 구독이 그 안에서 끝남. 사용자: "다만 뭐가 문제인지
모르겠어요" — 문제 없었음.

**(2) `oldValue`를 따로 넘기자는 보완안** — 사용자: "이전 값인 oldValue 는
처음부터 클로저라 이미 본인이 알지 않아요?" 맞음. 클로저는 자기 `v`를
캡처하고 힌트로 새 값을 받으므로 old/new를 이미 둘 다 갖고 있음. 진짜
문제였던 힌트의 **타입 보장**은 "핸들러 비교를 클로저 호출 *앞*에 둔다"는
것만으로 해결됨(같은 핸들러일 때만 값이 넘어가고, 그 값은 정의상
`isHandlable`을 만족) — `chains`에 추가할 건 비교용 `handler` 하나뿐.

**부수 발견**: 이 모델이면 **깊은 체인의 힌트 유실도 같이 사라짐.** 힌트를
위에서 아래로 전파하는 게 아니라 각 레벨이 자기 재프로세스에서 자기
힌트를 받으므로, `State<State<Tag>>`에서 바깥이 새 inner를 내놔도 index 3의
TagHandler가 **진짜 `Tag`를 힌트로 받아** `Contains` skip이 살아남. 앞
라운드에 "구조상 불가피"라고 적었던 건 철거-선행 모델에서만 참이었음.
`HandlerChanged` 마커도 불필요(핸들러가 바뀐 건 retractor가 `nil` 힌트로
불린다는 사실로 이미 표현됨).

### 유일하게 이견 — Attribute 소유권은 "자연히" 처리되지 않음

사용자는 "이 방식으로 가면 자연히 Attribute 의 소유권 충돌은 처리되네요"
라고 봤으나, 추적 결과 **그렇지 않음**: 그룹 A가 잡아둔 이름에 그룹 B가
들어오면 인덱스 1의 핸들러가 양쪽 다 `StoreBind`라 "같은 핸들러"로 판정돼
조용히 갈아타고, 나중에 A의 클로저가 B의 바인딩을 대신 철거함(교차 오염) —
이번 감사에서 고친 바로 그 증상이 되돌아옴. 다만 사용자의 나머지 절반
("오류 처리가 필요한 곳이면 직접 처리하면 되니까요")은 맞고, 그 '직접
처리'를 뭘로 할지가 유일한 결정 사항. **권고: 이름별 claimant `Relate`를
Attribute 쪽에 국소적으로 둠** — 네 번째 세션에 `owners`로 만들었다
기각됐던 그것인데, **당시 기각 사유("소유권 반납이 `v==nil` 분기에만 있어
안 지워짐")가 새 모델에선 구조적으로 소멸**(클로저가 항상 불리고 거기서
반납). 문서: `research/dispatch-redispatch-diff-plan.md`(파일명도
`dispatch-hint-to-oldvalue-plan.md`에서 바꿈, `oldValue`가 철회됐으므로).

## 다섯 번째 라운드 (같은 세션, 마무리) — 해제 순서 주의 + Attribute 이관

### `setOffsetSource(None)` → `setLength(0)` 순서 고정 (사용자 지적)

> "setLength 먼저 수행하고 setOffsetSource 수행하기 보단 setOffsetSource 를
> 먼저 날려야할듯 합니다 - 물론 별 상관 없어요. 자기 자신의 length 가
> 줄어든다는 의미는, 자기 자신 offset은 여전하다는건데, 그래서 업데이트
> 될 일이 없긴합니다. 다만, 여전히 setLength 로 인해 다시 slot 들의
> offset들이 재계산 될 때 invalid 한 offset source 자체가 있다는것 부터
> 위험합니다. 방어적으로 처리하세요."

`setLength`는 끝에서 `recompute`를 돌리고 `recompute`는 `sourceList`를
순회하며 `offset:Set(sum)`을 호출함 — 그래서 **`setLength(0)`을 먼저
부르면 그 시점에 해제 중인 자리의 `sourceList[i]`엔 아직 옛 Slot의 offset
`Source`가 남아 있어**, 지금 막 떼어내는 서브트리의 Source에 `:Set()`이
날아가고 그걸 구독하던 (곧 없어질) 자식들의 `LayoutOrder` 계산이 헛되이
캐스케이드됨. `setOffsetSource(None)`을 먼저 하면 `recompute`의
`offset ~= None` 가드에 바로 걸려 그 Source를 아예 안 건드림.

값이 틀려지는 문제는 아님(자기 length가 줄어도 **자기 앞 형제들의
누적합은 그대로**라 자기 offset은 갱신될 일 자체가 없음) — 위험한 건
"invalid한 Source가 순회 대상에 남아있다"는 것 자체. 방어적으로 순서를
계약으로 고정하고, 추가 조치 둘을 같이 넣음:
- 해제 시 `slot.Offset = nil`(이 문서의 "마운트 전엔 `nil`" 규칙과 짝),
- `recompute`가 `sourceList[i]`의 `nil`도 `None`과 똑같이 skip(전이
  구간에서 관측돼도 크래시 대신 넘어가도록 — 등록 쪽의 "반드시 `None`"
  의무는 그대로).

`base/bind-system-plan.md`(Length/Offset 절, `recompute` 의사코드)와
`base/slot-plan.md`(언마운트 절) 양쪽에 반영.

### Attribute 소유권 — 다음 세션 심층 분석으로 명시 이관

> "Attribute 소유권은 아마 이전 결정을 다시 가져오는게 맞아보이긴 하네요.
> 막 깊게 Key -> Group 필요한것 같지는 않고, 본인 retract 처리를 수행할 때
> 무언가 하면 될듯 한데. 이 부분은 나중에 제가 물리적으로 스케치 해보며
> 심층 분석해보겠습니다. 당장은 이 세션 중 나온 내용, 지식이 누락 없게
> stale 없게 처리해주시고. ... 이미 세션이 길고, 이 부분을 더 깊게 파기엔
> 다른 부분을 누락할 위험이 있어요."

방향은 이미 잡혀 있음(이름별 claimant `Relate` 부활, 단방향이면 충분,
반납은 클로저 안에서) — 다만 확정은 사용자가 직접 스케치한 뒤로.
`question.md`에 **0-Z(최우선)** 로 분리하고, CLAUDE.md "지금 할 일"에
0번 항목으로 올려 핸드오버.

**핸드오버에서 가장 중요한 한 가지**: **`base/`의 현행 `hintValue` 서술은
아직 옛 모델(철거 선행)이고, 새 모델은 `research/
dispatch-redispatch-diff-plan.md`에만 있음** — base만 읽고 구현하면 옛
모델로 짜게 됨. 0-Z가 정해지면 그 문서 6절의 파일별 목록대로 4개 base
문서를 한 번에 옮길 것. 반대로 **Slot의 언마운트/`dispose`/해제 순서는
이미 base에 확정 반영됨**(재디스패치 모델과 독립적인 결정이라 먼저 들어감)
— 이 비대칭을 헷갈리지 말 것.

## 여섯 번째 라운드 (같은 세션, 마무리) — 첫 실측 + 코퍼스 전반 감사

### 스파이크 첫 실측

`luau`/`luau-analyze`가 사용 가능해져 2026-08-09 이래 처음으로 돌림.
런타임 12개 전원 통과. 상세는 `audit/luau-test-first-run-2026-08-13.md`,
상태 분류는 신설한 `luau-test/STATUS.md`(사용자 요청: "사람이 보기엔 뭐를
바로 봐야하는지 눈에 안 띄어서").

핵심 셋: `04`가 이번 세션 감사의 버그를 음성 대조군으로 재현(체인 깊이
3→1, 죽은 store가 UI를 덮어씀), `07`은 보강해야 실제 검증이 됐고(연쇄 GC
미검증 상태였음 + "weak 엔트리를 셀 방법 없다"는 자기 전제가 틀렸음),
`18`이 `Relate` 상호 순환 경고를 실증.

타입에서 진짜 이슈 하나 — `:Compute(fn)`의 lazy 핸들 계약이 Luau 양방향
추론과 충돌. 최소 재현으로 직접 좁힘(에이전트 보고를 액면 그대로 안 받음):
`read`/`self` 표기 조정으로는 안 풀리고 콜백이 raw 값을 받으면 완전 클린 —
즉 계약 자체가 원인. `question.md` **0-Y** 신설. 사용자 방향은 "순환 타입을
만들기보다 `State` 타입을 구울 때 인라이닝"(`Modifier` flat 타입 생성과
같은 결)이고, 사람이 직접 확인할 부분이라 0-Z와 함께 사용자 판단 목록.

부수 수확: `17` 크래시의 원인이 실은 `modifier-plan.md`의 문서 결함이었음
— "데이터를 테이블에 직접 두고"가 "self 최상위 리터럴 키"로 읽히는데,
그러면 `__index`가 `rawget` 성공 시 안 불려 **같은 필드 재호출이 죽음**.
그 재호출 패턴이 문서 3·4절의 대표 용례라 실사용에서 즉시 터지는 경로.

### 코퍼스 전반 모순·stale 감사 (사용자 요청)

에이전트 둘로 base 내부 / base↔바깥 정합성을 나눠 감사. **오탐 방지를 위해
"의도적으로 미반영인 것"(⚠️ 배너가 예고하는 `hintValue` 건, `research/`의
미래 설계안, `archive/`·`session/`의 원문 보존)은 보고 대상에서 제외**하도록
지시. 보고받은 것은 전부 직접 사실 확인 후 수정:

**가장 위험했던 것 — `ROADMAP.md`가 최우선 게이트를 전혀 안 짚고 있었음.**
base 4개 문서엔 ⚠️ 배너를 달아뒀는데 정작 **구현 순서의 소스**인 ROADMAP엔
없어서, M2/M4/M10 담당자가 그대로 옛 모델로 구현할 위험이 실재했음 — 세
마일스톤 전부에 배너/포인터 추가.

**두 번째 — `slot-plan.md` 앞부분이 뒤집힌 결정을 "확정"으로 자칭.**
487-495행("폐기, 옮기지 않음, portal은 오버엔지니어링")과 "열린 질문" 절이
역전 표시 없이 남아 있어, 문서를 앞에서부터 읽는 구현자가 구 모델로 짤
위험. 🔄 역전 배너 추가. 더 심각하게 **`reconcile` 의사코드가 여전히
`rawRemove`(파괴)를 부르고 있었음** — 같은 문서가 "[반영 완료]"라 태그해둔
것과 정면 모순이라 `rawUnmount`를 신설해 교체. filter/toggle 근거 절도
"제거=파괴" 전제 위에 서 있어 캐비엇 추가(결론 자체는 언마운트로도 유효).

**그 외**: `ROADMAP.md` M11 Tween이 이미 확정된 결정 넷을 미결로 두고
있던 것(override 정책/옵션 값 모양/`Animate` 시그니처/`initValue`)과 죽은
링크 4곳, `bind-system-plan.md`/`architecture.md`의 "4종 계약" 잔여,
`store-semantics.md`의 "`State`는 가칭" stale(2026-08-12에 확정됨),
`luau-test/README.md`의 `04`/`19` 판정 기준이 재작성된 파일을 못 따라간 것
(**`19` C섹션 기준이 정상 동작을 실패로 오판하게 돼 있었음**),
`documentation-content-map.md`의 4종 계약/`Attribute<T>` 옛 이름,
`modifier-plan.md`의 "정정이 원문에 소급 안 됨" 패턴.

**판단해서 안 고친 것**: `effect-plan.md`의 "cleanup" 14곳 —
Handler `retract`(내부 배관)와 달리 **`Effect(fn)`에서 사용자가 작성한
`fn`이 반환하는 React식 콜백**이라 다른 층위. 매 감사마다 재지적되므로
`lifecycle-pattern.md`에 "확인 완료, 의도된 별개 개념"으로 못박아 둠.

