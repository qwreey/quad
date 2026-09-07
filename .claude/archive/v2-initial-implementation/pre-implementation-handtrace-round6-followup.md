# 6라운드 손 트레이싱 — 처리 결과

**상태**: **[2026-08-24] 전량 처리·반영 완료.** 사용자와 대화형으로 하나씩
결정했고(`H-1`~`H-54`), 그 결정을 각 `base/` 문서에 **전부 반영했다**.
이 문서는 **결정과 근거의 기록**이고, 지금 유효한 설계는 항상 `base/`가 소스다.

원 발견 보고는 `pre-implementation-handtrace-round6.md`.

**반영된 문서**: `slot-plan.md` / `dispatch-core-plan.md` / `source-state-plan.md` /
`effect-plan.md` / `ref-plan.md` / `gate-plan.md` / `blocker-plan.md` /
`debounce-throttle-plan.md` / `tag-plan.md` / `attribute-plan.md` /
`modifier-plan.md` / `onchange-plan.md` / `tween-plan.md` / `typing-limits.md` /
`fallback-plan.md` / `quad-types-plan.md` / `store-plan.md` /
`module-lifecycle-plan.md` / `architecture.md`, 그리고 루트 `ROADMAP.md`와
`.claude/todos.md` / `luau-test/STATUS.md`.

## A. 처리 완료 (결정됨)

### `H-39` — 말단 핸들러 4종의 `setLength`/`setOffsetSource` 미등록
**결정: 넷 다 똑같이 등록**(갈래 1 + 2-(a)). `TagHandler`/
`AttributeGroupHandler`/`RefLeafHandler`/`ObserverEffectLeafHandler`의
`process` 맨 앞에서 `setOffsetSource(inst,k,None)` → `setLength(inst,k,0)`.
`AttributeGroupHandler`도 예외로 두지 않는다 — Tag/Attribute를 "Length/Offset
비참여 카테고리"로 재정의하면 `bk.N`의 의미가 바뀌어 파급이 크다.

### `H-25` — `New(): Quad`가 닫힌 타입
**결정: `quad-types`의 `Quad`를 마일스톤마다 갱신**(갈래 2). M2가
`Dispatch` 필드와 그 타입 재수출을 `quad-types`에 추가하는 걸 `ROADMAP.md`
M2 체크리스트 항목으로 명시한다. quad-roblox(M5)도 같은 경로로 본다.

### `H-1` — `keyIndex`가 사이클 도중 stale
**결정: 사용자 역제안 채택 — 역방향 인덱스 맵을 raw 층에 둔다.**
- `:List`는 `k → realElem`만 들고, 배열 인덱스를 직접 들지 않는다.
- **`slot._elemIndex`** 신설(`realElem → index`), `_elements`와 같은 수명.
  자리를 밀고 당기는 모든 연산(`spliceArraysUp`/`Down`, `rawMove`,
  `rawSwap`, `rawReplace`, `rawAdd`)이 같이 갱신한다. detach된 요소는
  `_elements` 밖이므로 맵에서도 빠진다.
- **raw\*의 index 시그니처는 유지**(5라운드 결정 그대로). 대신
  `indexOfRaw(self, element)`가 선형 탐색이 아니라 이 맵 조회가 되고,
  "폴백이 아니라 기본 경로"로 승격된다.
- 근거: 층 분리가 오히려 깨끗해지고(raw\*가 `:List` 클로저를 안 봄),
  시프트는 이미 O(n)이라 맵 갱신이 점근 비용을 안 올리며, 조회가 O(1)이
  된다. `claimOwnerAt`이 같은 요소의 이중 배치를 이미 error로 막으므로
  키 유일성이 보장된다.
- **부수 효과**: `:List`의 `keyIndex`가 인덱스 맵에서 **단순 키 집합**으로
  내려앉는다(소멸 루프의 "직전 사이클 키" 용도만 남음) → `H-16`이 같이
  사라진다.

### `H-2` — `pos`(리프 카운터)를 배열 인덱스로 겸용
**결정: 카운터를 분리하고, `updateFn`의 `index`는 `getOffsetAt`으로 구한다.**
사용자 원 디자인 초안대로 — activation이 순차이므로 그 시점 length는
확정돼 있다. 이를 성립시키기 위해 초기 population 경로를 같이 고친다:
- **`_mounted`는 "물리 인스턴스가 있는가"만 가리킨다.** `rawAdd`의
  얼리리턴을 **`native*` 호출만 가리는 분기**로 좁히고, 부기
  (`spliceArraysUp`/`setOffsetSource`/`setLength`/중첩이면 실체화)는
  마운트 전에도 수행한다.
- **`slot._physicalTarget` 신설** — `materializeSlotTree` 머리에서 저장.
  `setLength`의 앵커/`bk.observers` 앵커가 마운트 전에도 필요하기 때문.
  `_mountedInst`는 지금대로 "마운트됨"만 뜻한다(미실체화/실체화/마운트 3상태).
- **`_listed`면 `materializeSlotTree`의 자식 실체화 루프를 건너뛴다** —
  `activateList`가 이미 전부 등록하므로 이중 등록이 된다. `:List`와 CRUD가
  상호배타라 정확하다.
- **`blocker:On()`을 `activateList` 앞으로 옮긴다** — 5라운드 `AS-5`의
  근거("그 안에선 게이팅할 recompute 자체가 안 일어난다")가 사라지므로.
  population 중 아이템마다 recompute가 도는 O(n²)를 막는다.
  `_baseObserver` 생성은 여전히 `blocker:On()` 뒤.

### `H-5` — `spliceArraysUp`이 `bk.N`을 먼저 올려 여는 창
**결정: `spliceArraysUp`이 `lengthList[index]`에 자리표시자를 채운다.**
`sourceList`가 `None`으로 채워지는 것과 대칭. 동기 재진입(`ChildAdded`)이
그 창에서 `sum += nil`로 터지던 것이 닫힌다.

### `H-6` — `unmountSlotTree`의 미정의 `physicalTarget` + offset 어긋남
**결정: `physicalTarget`은 `slot._mountedInst`를 로컬로 먼저 뽑아 쓴다**
(지우는 대입보다 위에서 읽는 순서 유지). 곁가지는 **역순 순회로 변경** —
뒤에서부터 빼면 앞쪽 offset이 안 밀려 매번 정확하다. 백엔드 계약을
좁히지 않아도 닫힌다.

### `H-7` — `Effect`의 `Ref` 의존성을 뗄 방법이 없음
**결정: `Ref`에 콜백 해제 경로를 추가**(갈래 a).

### (파생) `Ref.Callbacks`를 해시맵 셋으로
**결정: `{[callback/thread] = true}`로 변경**(사용자 제안). 해제가 O(1)이
되어 `H-7`이 요구하는 연산과 맞고, `type(v) == "thread"` 분기는 키 타입
검사로 그대로 성립한다.
- **같은 콜백/thread의 중복 등록은 dedup을 계약화**(여러 번 등록해도 한 번
  발화). 해제가 `t[fn] = nil` 하나로 끝나야 하기 때문.
- **`ref-plan.md`의 ⚠️ 실측 대상(구멍 있는 테이블에서 `#t` border가 항상
  첫 `nil`인가 — M0/M8 스파이크)이 폐기된다** — 해시맵엔 border 개념이 없다.
- `table.insert` 재사용 근거(`R-11`)와 "`None`이 아니라 `nil`" 논의도 이
  자료구조 변경에 맞춰 다시 쓴다.

### `H-23` — 전파 도중 새 구독자가 붙으면 누락/이중 발화 (실측)
**결정: 순회 전 스냅샷**(갈래 1). State 구독자 집합과 `Ref.Callbacks`
**둘 다** 배열로 복사한 뒤 그 배열을 순회한다. "이번 파동 중에 붙은
구독자는 다음 파동부터 참여"를 계약으로 명시. 스냅샷 사이에 죽은 구독자는
기존 `canExecute` 게이트가 걸러준다.

### `H-11` — `Effect`의 leaf 사망 cleanup을 부르는 배선이 없음
**결정(1번 소항목): `EffectHandle` 쪽이 자기 `bindLifetime` 직후에
`Destroying`을 건다.** `bindLifetime`이 값 타입을 가리지 않는다는 기존
원칙을 유지한다. 2·3번 소항목(=`unbindLifetime`이 cleanup을 부르는가 /
cleanup을 어디 보관하는가)은 아직 미확정.

### `H-12` — `rawRemove`/`rawUnmount`/`rawDetach`에 마운트 전 분기 부재
**결정: `native*` 호출(및 `_mountedInst`를 쓰는 줄)만 `_mounted`로 가드**해
`rawAdd`와 대칭을 맞춘다. `H-2`의 "부기는 마운트 전에도 한다"와 같은 규칙을
네 함수가 공유한다.

### `H-13` — `Effect(fn, ...deps)` 역전이 정본 문서에 미반영
**결정: `Observer`는 기각 유지하되 근거를 새로 쓴다.** `source-state-plan.md`가 승격해둔 일반 원칙(없던 노드를 새로
만들어야 하면 sugar를 안 붙인다)은 **`:Compute` 한정**으로
좁히고, `Effect`의 역전(`C-6`)을 그 문서에 반영한다. `Observer` 기각의 새 근거는
"Observer는 리시버 State 하나에 붙는 구독이고, 여럿을 엮는 건 `Effect`가 대신한다".

### `H-14` — `Effect`의 `fn` 시그니처
**결정: `Effect(fn: (self: Effect) -> (() -> ())?, ...deps)`.**
- `fn`은 **`self`(Effect 핸들) 하나만 받는다.** `...deps`는 **의존성 선언일 뿐
  `fn`에 안 넘어간다** — dep 값은 사용자가 클로저로 직접 읽는다.
- 사용자 논거: *"Observer 처럼 바로 상위 state 가 있는게 아니라 Effect 를 주는게
  맞아보이고, Compute 랑은 완전 다름. 난 그냥 `...deps` 넣는게 compute 처럼
  그냥 넣을 수 있게 하자는거였을 뿐임."*
- 그 따름정리로 **`Ref` dep의 `.Value` vs State dep의 `:Get()` 비대칭 문제가
  사라진다**(아무것도 안 넘기므로). 문서의 *"trailing deps를 lazy 위치 인자로
  콜백에 넘긴다"*와 옛 `fn(state)` 표기는 **둘 다 삭제**.

### `H-17` — `Dispatch.drive`의 Blocker 범위
**결정: "`drive` 전체"로 넓혀 적고 계약화.** `F-4-1`의 단일 일반화 `for`에선
배열 파트 종료 시점이 관측되지 않고 `postRefList` 소비는 애초에 해시 파트보다
뒤이므로, 실제 범위를 문장에 맞춘다. 추가로 **`PostRef` 콜백은 게이트가 켜진
채로 실행되며, 그 안에서 일어난 Length 변화는 직후의 명시적 `recompute` 한
번으로 정리된다**를 계약으로 명시(지금은 우연히 맞고 있을 뿐).

### `H-18` + `H-45` — attribute 이름을 그룹 사이에서 옮길 때 emit 순서 의존
**결정: UB로 못박는다.** 사용자 논거: *"state<attribute> 로 그 경로가 열리는데
어떤 방식으로 process 를 걸어도 외부에 바꿀지 말 지 알 방법이 없음. 외부에서
먼저 retract 가 나도록 유도하는게 아닌 한 알 방법이 없어보임. 애초에 싱크이기도
하고, 또 이걸 허용하면 process/retract 계약의 전체에 대한 예외들이 생기고
오버 엔지니어링으로 보임."* `H-45`(단건 `AttributeKey` ↔ 그룹)도 같은 결정으로
닫힌다.

### `H-19` — `recompute`가 두 번 도는 것
**결정: `setLength`에 일임하고 `rawAdd`/`rawReplace`의 명시 `recompute` 호출을
삭제.** "자리의 길이가 바뀌면 `setLength`가 책임지고 `recompute`를 태운다"로
소스를 하나로 만든다 → `H-3`의 `invalidAfter` 당김도 `setLength` 한 자리에만
두면 된다.

### `H-21` — `unwrapElement`가 Instance에서 크래시
**결정: `isSlot` 가드**(갈래 1). `if isSlot(el) then return el._wrapped or el end
return el`. 래퍼는 항상 Slot이고 `isSlot`은 Brand의 weak-key 조회라
Instance/userdata/number 전부에 안전하다.

### `H-22` — 기본 identity `updateFn`이 `KeyGone`을 되돌려 항상 error
**결정: `identityUpdateFn`이 `KeyGone`을 흡수**(갈래 1) —
`if item == KeyGone then return nil end`. 사용자가 직접 쓴 identity에도 같은
처리가 필요하다는 건 문서로 안내한다.

### `H-24` — `Tween<T>:Mapped`의 재귀 제네릭 타입 누수
**결정: 단순 정정.** `typing-limits.md`의 영향 범위에 `Tween<T>:Mapped` 행을
추가하고, `tween-plan.md`의 `Mapped` 절에 "인라인 제네릭 메소드가 아니라
`typeof(named function)`으로 선언할 것" 각주. 기존 완화책이 그대로 통한다.

### `H-26` — 부분 생성 후 예외로 생긴 Instance가 영구히 안 죽음
**결정: 둘로 나눈다.**
1. **기본 경로(예외가 밖으로 나가 아무것도 안 그려지는 경우)는 서술 정정으로
   끝낸다.** 같이 **`dispatch-core-plan.md`에서 잔여 부기가 인스턴스 GC로
   정리된다고 적은 문장을 고친다** — gcconn 불멸성과 양립하지 않는 **틀린 안전망
   주장**이다.
2. **`Fallback`/`Traceback` 중 생성된 부분 트리는 백로그.** 사용자 판단:
   *"의도적으로 error 를 사용하고자 하는 경우 항상 컴포넌트들이 쌓이거든. 이건
   후행에서 더 다뤄보도록 백로깅해줘. fallback/traceback 자체가 슈거라서, 그
   때 가서 생각해도 될듯."*

### `H-29` — 정의 없는 `raw*` 다섯
**결정: 작성 + `collectLeaves(slot)` 헬퍼 신설.** 재귀 리프 수집 헬퍼를 두고
`Move`/`Swap`/`Extract`/`Splice`가 공유한다(`native*`의 "빠지는 요소는 반드시
elements 배열로" 계약을 그대로 지킴). 작성 시 같이 명시할 것: 함께 치환되는
배열(`lengthList`/`sourceList`/`bk.observers`/`_elemIndex`), `bk.N`은 안 변함,
`recompute`는 `setLength`에 일임(`H-19`).

### `H-32`/`H-33`/`H-49` — `Debounce`/`Throttle`과 `Gate`의 관계
**결정: 정책 합성 구조를 확정.**
- **`Gate` 노드에 `Flush`/`Cancel` 표면을 두지 않는다.** 확정된
  `state:Gate(setup)`(State 하나만 반환)이 그대로 유지된다.
- **`Blocker`가 자기 정책을 값으로 낸다 — `blocker:Policy(emit) -> onUpstreamEmit`.**
  `state:Block(b)`는 그 위의 얇은 래퍼가 된다.
- **`Debounce`/`Throttle`은 emit을 아예 안 쥔다.** 자기 `Blocker`를 사적으로
  갖고 **언제 `On()`/`Off()`할지만** 정하며, 실제 발화/보류는 Blocker에 위임한다:
  ```lua
  state:Gate(function(emit)
      local b = Blocker()
      local pass = b:Policy(emit)
      return function()            -- 상류 emit 도착 (동기)
          ...타이머 리셋 / b:On() / b:Off() 시점 판단만...
          pass()                   -- 그 시점 상태로 Blocker가 판정
      end
  end)
  ```
  동기 실행이라 같은 호출 안에서 정책이 바꾼 Blocker 상태를 `pass()`가 본다.
- **Blocker는 `Debounce` 설정당 하나가 아니라 적용 핸들당 하나**다 — `Debounce{}`
  커링 결과는 여러 곳에 적용될 수 있으므로 Apply 시점에 생성된다.
- **`pending`은 Blocker의 `HasBlockedEmit`으로 흡수**한다(중복 상태를 안 만든다).
  `Trailing=false`는 `OffWithoutEmit()`, `Flush`는 `Off()`로 매핑되어 `H-32`의
  새는 경로가 구조적으로 사라진다.
- 합성 순서(누가 상류인가)는 손으로 중첩해 표현한다 — **`state:Gate(p1, p2, ...)`
  가변인자 슈가는 두지 않는다.**
- **기각된 대안(기록)**: "블로커를 바깥에 중첩"(`blocker:Policy(debounceOnEmit)`)은
  unblock 시 흘러나온 emit이 디바운스 창을 새로 시작시켜 창이 안 끝난다.

### `H-38` — reconcile의 예외 원자성
**결정: 키 집합을 증분적으로 갱신**(마지막 일괄 교체 폐지). `settle` 직후에
키를 넣고 소멸 루프에서 뺀다. 계약은 "reconcile은 원자적이지 않지만 **중단된
지점까지는 정합하다**". `H-31`(duplicate key)의 선행 검증 패스와 함께 그 실패
모양을 닫는다.

### `H-39`~`H-42`, `H-46`, `H-52` (4차)
- **`H-40`** — 빠진 가드 넷을 전부 의사코드에 반영. 타입 검증은 **화이트리스트로
  뒤집되 base가 `T`를 아는 방식이 아니라 백엔드 주입으로** 한다: **`isInst`를
  백엔드 계약(주입 op)에 추가**하고 quad-roblox가 `typeof(v) == "Instance"`로
  채운다. 판정 순서는 `isSlot` → 구조 처리 / `isState` → 래퍼 Slot으로 풀어
  재귀 / 그 외 → `isInst(v)`가 거짓이면 error. **관문은 `wrapElement` 하나**
  (공개 CRUD와 `:List`의 `settle`이 둘 다 통과하므로 State가 나중에 이상한 값이
  되는 경우도 같은 자리에서 걸린다). 사용자 논거: 브랜드 기반 판정은 불가 —
  *"이제 brand 는 각각 따로 생성되어서 있는지 없는지 보는건 결국 전부 봐야한다는
  의미"*.
  - **파생: `Splice`의 `T | {T}` 기각은 유지하되 근거를 정정한다.** *"근거 정정.
    근데 실질적으로 저 splice 는 T 가 slot/state 일 수도 있어서, isSlot/state 도
    봐야함. 당연하게도 `Splice(..., comp())` 패턴은 흔할 수 있어서 그래. 그리고
    여전히 splice 는 소수의 요소를 다루는게 많고, 테이블 생성 비용을 지불할
    의미가 없다는 근거는 여전해."*
- **`H-42`** — **문서만 정정**. "동기 발화"를 `SignalBehavior.Immediate` 조건부로
  명시(Deferred에선 이 레이스가 없고 `PreRef`는 무해하게 불필요). 그 뒤의 큰
  질문(구조 존속)은 **유지**로 결론 — Immediate place가 살아있는 한 필요하고
  불필요해질 때의 비용이 싸다.
- **`H-46`** — **top-level `Slot.luau` 신설**(다른 값 타입과 대칭,
  `slot-plan.md`가 이미 적어둔 파일명과도 일치). `Dispatch/Slot.luau`는
  핸들러/부기만.
- **`H-52`** — **대칭적으로 가드 추가**(`type(k)=="number"` + 동적 경로 가드),
  `RefLeafHandler`가 2026-08-18에 받은 수정과 같은 모양.

### 일괄 단순 정정 (사용자 확인: "전부 그대로 반영")
`H-3`(캐시 무효화 3규칙을 `setLength`/splice/`_baseObserver`에 실제 배치) ·
`H-4`(`bk` 스펙에 `offsetCache`/`invalidAfter` 추가, `0`/`{}` 초기화 명시) ·
`H-8`(`_observers` 배열화 + cascade/Subscribe/Unsubscribe 순회) ·
`H-9`(`withheld` 스왑도 weak-key로) · `H-10`(`sum` 주석 정정) ·
`H-20`(`process(inst, k, v, index)` 표기 통일) · `H-27`(`OnChange`의 `v == nil`
얼리리턴) · `H-28`+`H-43`(`dispose`의 소유권 가드를 `isSlot` 분기 밖으로) ·
`H-30`+`H-31`(선행 일괄 검증 패스) · `H-34`+`H-44`(`native*` 계약 보강 —
Roblox 백엔드는 `nativeMove`/`nativeSwap`을 덮어써야 함, ROADMAP M6 줄 갱신) ·
`H-35`(`ProcessedModifierHandler` 의사코드 + 색인 두 곳) · `H-36` · `H-37` ·
`H-41`(`groupClaimKeys` 배선) · `H-47`~`H-51` · `H-53` · `H-54`.

## B. 답할 게 없는 항목

- **`H-15`** — 2차 패스에서 이미 철회(오탐).
- **`H-16`** — `H-1` 해법의 부수로 소멸(`keyIndex`가 인덱스 맵이 아니게 됨).
- **`H-2`의 크래시 주장 정정** — 3차 패스의 실측(`table.insert(t, 0, x)`는
  Luau에서 안 터짐)대로 "크래시"가 아니라 "조용한 영구 고아"로 본문을 고친다.
  결론과 처방은 그대로.

## C. 백로그로 넘긴 것

- **`H-26`의 2번** — `Fallback`/`Traceback` 중 생성된 부분 트리의 회수.
  그 둘이 슈가라 구현 시점에 다룬다.

## D. 반영 후 `/code-review high` (2026-08-24) — 7건, 전부 유효

반영을 커밋하기 전에 사용자가 `/code-review high`를 돌렸고 **7건이 나왔으며
전부 유효했다.** 그중 셋(1·2·3)은 **이번 반영이 새로 만든 회귀**다 — 감사자가
보는 축(코퍼스 정합성)으로는 안 보이고 diff 자체를 읽어야 보이는 종류였다.

1. **`rawAdd`가 미실체화 가드를 통째로 잃었다**(높음). `H-2` 재작성이
   `if not self._mounted then return index end`를 지우면서 **3상태 중 첫
   경계에 아무것도 안 뒀다.** `Slot { frameA }` 생성자가 `:Add`를 부르는데
   그건 `materializeSlotTree`보다 훨씬 먼저라 `slot.Offset`이 `nil`이고,
   `setLength` → `gatedRecompute` → `getOffsetAt`의 `ownerKey.Offset:Get()`에서
   즉시 죽는다. 중첩이면 `bindLifetime(nil, …)`까지 간다.
   → **`self._physicalTarget == nil`이면 `_elements`/`_elemIndex`만 갱신하고
   리턴**하도록 복원. `rawReplace`의 미마운트 분기에도 같은 가드를 넣었다.
   같이 정리된 것: `_elemIndex` 갱신을 `reindexFrom(self, from)` 헬퍼로 떼어
   **실체화 여부와 무관하게 항상** 돌게 했다(`spliceArrays*`는 부기만 담당).
2. **`rawRemove`가 마운트 전 창에서 요소를 안 죽인다**(높음). `H-12`가
   `nativeRemove`를 `_mounted`로 가렸는데 **`nativeRemove`가 곧 파괴**였다
   (백엔드 융합). `else` 분기가 비어 있어 요소가 `_elements`에서 빠지고
   아무도 안 죽인다 — gcconn 때문에 GC도 안 되므로 **영구 누수**다.
   → `else nativeDispose(element)` 추가(`rawReplace`가 이미 하던 대로).
3. **`_listed` 분기가 포탈 재마운트를 깬다**(중간). 재마운트에선
   `activateList`가 `_listActivated` 멱등 가드에 걸려 앵커만 옮기고 리턴하므로,
   자식 루프까지 건너뛰면 보존된 `_elements` 안의 중첩 Slot이 **다시 실체화되지
   않는다**(`_physicalTarget`이 `nil`인 채 `_mounted`만 켜지고 `_baseObserver`가
   죽은 옛 target에 매달린다). → 조건을
   **`slot._listed and not slot._listActivated`**로 좁히고, `else` 가지에서
   재마운트 시 `activateList`(앵커만)를 부른 뒤 루프를 돌게 했다.
4. **`H-11`의 두 결정이 서로 모순**(중간). "`bindLifetime`은 값 타입을 안
   가린다"를 지키기로 해놓고 "`unbindLifetime`이 `Destroying`을 끊는다"를
   같이 정했는데, 후자는 정확히 그 분기를 요구한다. 게다가 *"`EffectHandle`
   쪽이 자기 `bindLifetime` 직후에 건다"*는 **그 호출부가 실재하지 않는다**
   (핸들은 남이 자기를 bind하는 걸 관측 못 한다). `Effect` 바인드 경로가
   둘이라(leaf 핸들러 / `activateList`의 `_detachCleanup` 직접 바인드) 핸들러
   층에 둬도 안 덮인다.
   → **재결정(사용자, 2026-08-24): `bindLifetime`/`unbindLifetime`이
   `isEffect`를 보고 직접 처리한다.** *"Destroying 자체가 엔진이 아는 요소이기
   때문에, 엔진이 처리하는 곳에 두긴 해야합니다. 옵져버는 바로 생성되기
   때문에, bind 상 옵져버 목록을 가져와 자신이 재귀하고, bindLifetime 이
   처리하는게 나아보입니다."* 근거로 들었던 "게이트는 값 타입을 안 가린다"는
   **인용이 틀렸다** — 그 절은 `canBound` 판정이 두 진입점에서 같다는 얘기지
   부수 배선 얘기가 아니고, 실제로 그 함수는 이미 `_observers`로 cascade한다.
   의사코드는 `base/lifecycle-pattern.md`에 반영.
   - **⭐ 같은 자리에서 사용자가 추가 지적**: `Effect`의 **`Ref` 콜백도
     `canExecute`를 거쳐야 한다.** 해제 경로만으로는 창이 남는다 —
     `unbindLifetime`으로 조용히 끊긴 상태(포탈 언마운트)는 `Destroying`이 안
     도는데도 `canExecute`가 거짓이다. **해제는 누수를, 게이팅은 발화를** 막는다.
     → `Effect`가 거는 `Ref` 콜백은 본문 맨 앞에서 `canExecute(handle)`를
     확인하고 거짓이면 리턴한다. 이로써 두 dep 경로가 같은 게이트를 공유한다.
     (`H-7` 처리 때 "그 대안은 채택하지 않았다"고 적었던 서술을 정정했다 —
     택일이 아니라 둘 다 필요하다.)
5. **`Block`/`Gate` 동치 표기가 호출 불가**(중간). `state:Gate(b:Policy)`는
   문법 오류이고 `state:Gate(b.Policy)`는 언바운드 메소드라 `emit`이 `self`
   자리에 들어가 게이트가 영영 안 열린다.
   → `state:Gate(function(emit) return b:Policy(emit) end)`로 두 문서 정정.
6. **`settle`의 교체 분기가 새 자리로 안 옮긴다**(낮음). `rawReplace`는 자리를
   유지하는데 `slotPos`를 무시해서, 값 교체와 리오더가 같은 사이클에 겹치면 그
   요소만 옛 자리에 남는다. → 교체 후 `idx ~= slotPos`면 `rawMove`.
7. **`prevKeys[key] = true`가 `settle` 뒤에 있어 `H-38` 계약이 약해진다**(낮음).
   `settle`이 커밋 후 던지면 그 키가 집합에 안 들어가 다음 사이클 소멸 루프가
   못 물어 영구 고아가 된다 — `H-38`이 고치려던 바로 그 모양. → `settle` **앞**으로.

**교훈(기록)**: `conventions.md`가 *"`/code-review`는 감사자를 대체하지 않는다"*
라고 적어둔 그대로였다. 이번엔 감사자를 돌리기 **전에** code-review가 먼저
돌았는데, 잡힌 7건 중 셋이 "이번 diff가 만든 새 결함"이라 코퍼스 정합성
각도로는 애초에 안 보이는 것들이었다.

## E. 반영 후 `quad-doc-auditor` 감사 루프 (2026-08-24) — 9라운드, 34건

`/code-review high` 뒤에 감사 루프를 돌렸다. `conventions.md`의 절차대로
**한 턴에 하나씩**(병렬 금지) 돌리고 **라운드마다 각도를 바꿨으며**, 새 발견이
**0건인 라운드가 나올 때까지** 반복했다. 라운드별 발견: **5 → 7 → 2 → 2 → 3 →
9 → 2 → 4 → 0**.

| 라운드 | 각도 | 발견 |
|---|---|---|
| 1 | `base/` 문서들끼리 정합성(옛 주장 잔존) | 5 |
| 2 | 인덱스 레이어(README/ROADMAP/question/todos/STATUS/archive/reference) | 7 |
| 3 | **이번에 새로 쓴 서술 자체**의 내부 모순·인용 검증·정의/사용 일치 | 2 |
| 4 | 이번에 **안 바뀐** 문서가 조용히 틀려졌는가 | 2 |
| 5 | **어휘 추적** — 뜻이 바뀐 낱말을 옛 뜻으로 쓰는 산문 | 3 |
| 6 | `ROADMAP.md`의 **미완료 체크박스**를 구현자 눈으로 | 9 |
| 7 | 6라운드 픽스 검증 + `agents`/`tools`/followup 사각 | 2 |
| 8 | **완결성** — "N개 중 일부만 고친 자리" 세기 | 4 |
| 9 | 수렴 확인 + 전 코퍼스 스윕 | **0** |

**각도를 바꾼 게 실제로 작동했다.** 가장 많이 잡은 6라운드(9건)는 문서
정합성이 아니라 *"이 체크박스로 코드를 짜면 무엇이 나오는가"*를 물은
라운드였고, 그때 `ROADMAP.md`의 미완료 항목들이 대거 stale인 게 드러났다 —
M6엔 폐기된 `pos` 공식이 "확정"으로 남아 있었고, M2엔 접두합 캐시 무효화
계약이 통째로 없었으며, M8은 `bindLifetime`이 *"둘만 한다"*고 적어 `H-11`의
Effect 분기와 직접 모순이었다. 말단 핸들러 4종의 부기 의무(`H-39`)는 어느
체크박스에도 없었다.

**반복해서 드러난 실패 패턴은 하나 — "고쳐야 할 자리가 N개인데 일부만
고쳤다".** 1라운드는 *배너를 달아놓고 그 배너가 부정하는 위쪽 문장을 안 고친*
것(핸드오버 체크리스트 2번), 2라운드는 *`base/` 19개를 바꾸고 `.claude/README.md`를
한 줄도 안 고친* 것(체크리스트 6번), 7·8라운드는 *그 README를 고칠 때 11개 행
중 6개만 고치고 다섯을 빠뜨린* 것이었다. 8라운드를 아예 **완결성 축**(새 이름
하나당 나타나야 할 자리 넷 — 정의 문서/소스 트리/ROADMAP 체크박스/README 행 —
을 열거해 세기)으로 잡은 게 그래서였고, 실제로 4건이 더 나왔다.

**같이 채운 절차적 공백 둘**: `conventions.md`가 요구하는
`session/2026-08-24-01-handtrace-round6-resolution.md` 원문과
`session-summary.md` 항목을 남겼다(설계 결정이 대량으로 오간 세션인데 기록이
없었다). 그리고 이 감사에서 파생된 새 결정이 셋 있어 `base/`에 함께 반영했다 —
**주입 op `onDestroying(inst, fn)` 신설**(`_bindDestroying` 의사코드를 쓰다
드러남, base는 `Instance`를 모르므로), **`EffectHandle`의 필드 다섯**
(`_destroyConn`/`_refDeps`/`_refCallbacks` 등), **`quad-types`의 `Quad` 갱신을
M3/M6/M7/M8/M10에도 항목화**(확정이 "마일스톤마다"였는데 M2에만 있었다).
