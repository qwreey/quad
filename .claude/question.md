# 확인/결정 필요 목록

**이 문서는 사용자가 답해야 할 것만 담습니다.** 이미 결정이 끝난 항목은
2026-08-13 아홉 번째 세션에 `archive/question-resolved.md`로 옮겼음 —
"해결된 게 너무 많아 필요한 부분만 읽기 어렵다"는 사용자 지적에 따른 것.
결정 내용은 안 바뀌었고 읽는 자리만 옮겼으니, 어떤 항목이 왜 그렇게
정해졌는지 되짚고 싶으면 그 문서를 볼 것(지금 유효한 설계 자체는 항상
`base/`가 소스).

**항목을 해소하면**: 여기서 지우고 `archive/question-resolved.md`에
근거와 함께 옮길 것 — 다시 쌓이면 같은 문제가 반복됨.

---

## ⭐ 최우선 — **없음** (2026-08-14 열한 번째 세션 기준)

> **M0 착수를 막던 항목이 전부 해소됐습니다.** `0-Y`(`:Compute(fn)`의
> lazy 핸들 계약)는 열세 번째 세션에, `0-Z`(Attribute 이름 소유권)와
> `0-A`(재디스패치 하강 diff)는 열네 번째 세션에, **`0-W`(`Ref` 이중
> 배치 방지)는 2026-08-14 열한 번째 세션에 확정·`base/` 반영 완료** —
> 그래서 이 문서엔 이제 "결정 대기" 절 자체가 없음(비어서 헤딩째로
> 삭제). 해소 전 원문과 결론은
> `archive/question-resolved.md`, 뒤집힌 옛 재디스패치 모델은
> `archive/dispatch-hintvalue-model-reversed.md`.
>
> **M0 착수 전 읽을 것**: `base/typing-limits.md`(0-Y가 남긴 구현 규약),
> `base/dispatch-core-plan.md`(0-A/0-Z가 반영된 디스패치 코어 — 열네 번째
> 세션에 `bind-system-plan.md`에서 분리 신설).

## 1. 용어 정리 — 아직 안 정해진 것만 (사용자 요청, 진행 중)

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." **이미 확정된 이름**(`State`/`Relate`/`List`/`canBound`/`Ref`/
`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/`Handler`)의 근거는
`archive/question-resolved.md`. (`canBound`는 2026-08-14 다섯 번째 세션에
폐기돼 `canExecute`로 통합됐다가 **같은 날 열한 번째 세션에 별도 진입점으로
재도입**되어 여전히 이 목록에 있음 — 이중 바인딩 가드 전용이고 `canExecute`
(emit 게이팅 전용)와는 판정 로직만 공유. 아래 3번 `canExecute` 항목과
`base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절,
`archive/canexecute-inst-arg-reversed.md` 하단 addendum 참고.)

- **[해소됨, 2026-08-18] `DI` → `D`(Declarative) 확정** — 원문과 근거는
  `archive/question-resolved.md`. 요지: `DI`가 "Dependency Injection"과
  완전히 겹쳐 실제 오해 전례가 있었고, `D`는 Instance 전용이 아닌 declare
  요소 전반으로 확장 가능하며 `D.FrameModifier`류 타입 프리픽스도 짧게
  유지된다. 미뤄뒀던 유일한 사유(한 글자 식별자의 검색성/자기설명력)는
  "문서에서 처음 나올 때 항상 `D`(Declarative)로 풀어쓴다"는 표기 규약으로
  보완하기로 같이 확정. 코퍼스 반영 완료 —
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절.
- **[해소됨, 2026-08-19] `PopOnly` → `Detach` 확정** — 원문과 근거는
  `archive/question-resolved.md`. 요지: 이미 있는
  `Extract`(호출자가 직접 부르는 명령형 추출)와 동사가 겹치면 헷갈리는데,
  `Detach`는 "화면(부모 계층)에서만 떼어낼 뿐 관리 주체는 여전히
  reconcile"이라는 뜻이라 `Extract`의 "소유권을 통째로 넘긴다"와 자연스럽게
  구분되고, `nil`(파괴)과의 대비도 더 직접적으로 드러남. 공개 표면 위치도
  같이 확정 — `Slot`이 함수(팩토리)라 `Slot.Detach`처럼 붙이려면
  callable-table+메타테이블이 새로 필요해서 과함, `None`과 같은 선례를 따라
  **패키지 최상위 export**로. 코퍼스 반영 완료 — `base/slot-plan.md`의
  "`nil` 리턴은 파괴가 기본" 절.
- **`Gate`(2순위, 2026-08-21 신설)**: `Blocker`/`Debounce`/`Throttle` 아래의
  공용 게이트 노드 이름. 사용자 지적 — *"프리미티브 명을 Gater? 뭔가 이상하게
  들어간다는게 약간의 문제"* — 코퍼스가 `Blocker`/`Modifier`/`Observer`처럼
  `-er`를 많이 쓰는데 `Gater`는 영어로 어색하다. 에이전트 권고는 **`Gate`
  그대로**(`gate`는 이미 행위자가 아니라 **장치**를 가리키는 명사라 `-er`가
  불필요 — `Source`/`Ref`/`Slot`/`Tween`도 같은 계열), 대안 후보는
  `Valve`/`Relay`. **[2026-08-21 해소] `Gate`로 확정**(탑레벨 생성자를 안
  만들고 `state:Gate(setup)` 메소드로 가면서 `Gater` 문제 자체가 사라짐 —
  메소드 자리에서는 `:With`/`:Compute`와 나란히 자연스럽다). 노드 타입 이름은
  `GateNode`. `base/gate-plan.md`의 1번이 소스.
- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`Owned`(3순위, 2026-08-21 신설)**: `:List`/`:Single`의 설치 시점
  플래그(기본 `true`, `false`면 어떤 경로로도 파괴 안 함).
  `elementOwner`/`claimOwner`/`releaseOwner`와 같은 뿌리라 골랐지만
  **잠정 이름**이다 — 형용사라 옵션 테이블 키로는 자연스러운데, 실제로
  묻는 건 "이 Slot이 요소의 수명을 책임지는가"라서 `OwnsElements`처럼
  주어를 드러내는 쪽이 나을 수도 있음. `base/slot-plan.md`의
  "소유권은 설치 시점에 정해진다" 절.
- **`canExecute`(3순위, 사소함)**: 실제로 "이 값이 아직 살아있나" 확인인데
  이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적이라는 제안이
  있었으나, **(2026-08-08 재검토)** `isAlive`는 top-level `isX` 계열
  (`isState`/`isRef`/`isPreRef`/`isModifier`/`isObserver`류 — 전부 타입
  판별자)과 접두어가 겹쳐 "이것도 타입 체크인가" 오해를 유발할 수 있다는
  점이 지적됨. `canExecute`는 타입이 아니라 liveness(생존 여부)를 묻는
  질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽이 낫다는 방향으로 사용자가
  기욺 — 여전히 미확정, 다음에 `can`으로 시작하는 구체 대안(예: `canRun`)을
  같이 검토할 것. **[2026-08-14 다섯 번째 세션] 시그니처는
  `canExecute(value): boolean` 1-인자로 확정**(옛 `(inst, value)` 2-인자는
  폐기, `base/lifecycle-pattern.md`, `archive/canexecute-inst-arg-reversed.md`).
  **[2026-08-14 열한 번째 세션 정정]** 당시엔 `canBound`가 폐기돼
  `canExecute` 하나가 두 역할을 겸했으나, 이후 `canBound`가 별도
  진입점으로 재도입되며 다시 갈라짐(같은 문서의 "`canBound` vs
  `canExecute`" 절) — 이 이름 정리 항목은 이제 `canExecute`(emit 게이팅
  전용)에만 적용되고, `canBound`(이중 바인딩 가드 전용)는 별개 이름으로
  유지됨. 둘 다 판정 로직은 비공개 헬퍼 하나를 공유.
- **클로저 인자 이름 `hintValue`(3순위, 사소함, 2026-08-13 열네 번째
  세션 신설)**: 하강 diff 재디스패치에서 이 인자는 더 이상 "힌트"가
  아니라 **`nil`이거나 같은 핸들러가 곧 처리할 새 값**임이 계약으로
  보장됨(`base/dispatch-core-plan.md`) — 이름이 옛 모델의 잔재라
  `nextValue`류가 더 정확함. 코퍼스에 이미 널리 쓰인 이름이라 이번엔
  안 바꾸고 대기열에만 올림(의사코드는 새로 쓰는 자리부터 `nextValue`를
  쓰기 시작했음).
- **`Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`, `isState`를
  branded 타입 전부로 일반화) — `brand-plan.md`의 `Brand`
  절에서 동작/구현 방식은 확정, "OOP 인스턴스의 클래스명을 얻는 느낌"을
  전달할 더 나은 이름이 있는지가 열린 질문(사용자가 직접 제기) — `Tag`는
  이미 quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
- **`Tag`/`Added`/`Removed`/`Merged`(3순위, 사소함, 2026-08-08 세 번째
  세션 array-part 값 객체 재설계 때 확정된 API 표면)**: `base/tag-plan.md`가
  "열린 질문 없음, 값 모양/메커니즘/retract/패키지 배치 전부 확정, 이름
  자체만 용어 정리 대상"이라고 명시해뒀으나 이 목록에 반영이 안 돼 있던
  누락 — 이번에 추가. `Tag`는 Roblox `CollectionService`가 쓰는 용어와
  1:1 대응이라 그 자체로는 무난해 보이지만, 위 `Brand` 항목(97-99행)에서
  "`Tag`가 이미 이 뜻으로 쓰이고 있어서 충돌"이라는 이유로 `Brand`의
  대안 이름 후보에서 제외됐다는 점은 참고할 것 — 두 이름이 같은 코퍼스
  안에서 공존 가능한지도 같이 검토 대상.
- **`Attribute`/`AttributeKey`(3순위, 사소함, 2026-08-11 아홉 번째 세션
  추가)**: 여러 Store를 한 번에 attribute로 묶는 그룹 프리미티브
  (`Attribute(store1, store2, ...)`, `Tag`와 동형)가 신설되면서, 기존
  단일 키 생성자 `Attribute<<T>>("name")`를 이름 충돌 방지를 위해
  `AttributeKey<<T>>`로 잠정 리네임함(`OnChange`/`OnChangeKey`처럼 함수
  이름과 반환 타입 이름이 분리된 기존 전례와 대칭) — 해석 모호성 자체는
  이미 없앴으니 급하지 않지만, 최종 이름은 여전히 이 목록의 다른
  가칭들과 함께 검토 대상. `base/attribute-plan.md` "그룹 `Attribute(...)`"
  절 참고.
- **참고 — 이미 지나간 사례**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`process`/`retract`/`isHandlable`은 업계
  선례와 잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.

## 3. 낮은 우선순위 — 열려 있지만 급하지 않음

- **[해소, 2026-08-21 구현 전 QA 5라운드 `CR-3`] M2가 M3의 `Blocker.luau`에
  구조적으로 의존하던 순서 문제 — "게이팅 먼저"로 결정.** 사용자 판정:
  *"게이팅 먼저. 게이팅을 base 에 만들 준비를 해야한다. 실질적 모양 정의가
  필요함."* 즉 로드맵 순서를 유지하지 않고 게이팅을 M2로 앞당긴다. **다만
  앞당기는 대상이 `Blocker` 그 자체가 아니라 그 아래의 공용 `Gate` 노드로
  바뀌었고**(같은 라운드 `DT-4`), 그 표면/이름이 미정이라 **새 열린 항목으로
  이어진다 — 바로 아래 `Gate` 항목.** 아래는 해소 전 서술: 이대로 각주만 두고
  로드맵 순서를 유지할지,
  `Blocker.luau`(또는 최소 표면 `On`/`Off`/`IsOn`/`OffWithoutEmit`)를 M2로
  앞당길지, M2/M3 경계 자체를 재검토할지.** `RC-1`의 Blocker 게이팅 해법
  때문에 `ROADMAP.md` M2의 `Dispatch.setLength`/`setOffsetSource` 체크박스가
  `getBlocker`/`:On()`/`:IsOn()`/`:OffWithoutEmit()`을 호출하는데, 정작
  `Blocker.luau` 자체는 M3 체크박스에 있다 — 로드맵 순서대로면 M2가 아직
  없는 걸 참조하게 된다. 지금은 M2 체크박스에 이 사실만 각주로 남겨둔
  임시 조치(가장 보수적인 선택, 마일스톤 재편은 안 함) — **M2 착수 전
  필요**. 상세는 `qa-request/pre-implementation-qa-round3.md`의
  "ROADMAP.md 마일스톤 정합성" 절.
- **[해소, 2026-08-21 구현 전 QA 5라운드 H절] `mountInst`의 삽입 위치 + 중첩
  offset 결함 — `Dispatch.getOffsetAt(ownerKey, i)` 신설로 확정.**
  `setOffsetSource(None)`은 얼리 리턴하고, 숫자가 필요한 쪽이 `getOffsetAt`을
  직접 부른다(사용자안 — 병렬 배열을 안 늘리는 pull 방식). 베이스는 `isSlot`
  분기의 정체가 "베이스가 있나"임을 명확히 했고(베이스는 따로 저장하지 않고
  Slot의 `.Offset`을 그대로 읽는다 — 최상위 물리 inst는 항상 0), 중첩 Slot은
  자기 `Offset`을 관측해 깊은 전파를 한다. 반영하다 **재마운트가 `Offset` Source를 새로 만들던 결함**도
  같이 잡았다(identity 재사용). 상세는
  `qa-request/pre-implementation-qa-round5-followup.md`의 H절.
  아래는 열려 있던 시점의 서술: 둘이 한 덩어리다:
  (a) `setOffsetSource`의 `None`이 "아무것도 안 차지함"과 "발행 채널 없음"
  두 뜻을 겸하고 있어 **plain 요소의 offset 숫자가 계산조차 안 된다**(그래서
  DOM류 백엔드가 삽입 위치를 알 방법이 없다 — 사용자 지적), (b) `recompute`가
  `sum = 0`에서 시작해 `ownerKey.Offset`을 안 읽으므로 **depth ≥ 2에서 중첩
  Slot의 자식 offset이 부모 베이스만큼 어긋난다**(이번에 발견, 지금까지 depth 1만
  써서 안 드러났음). 제안은 `bk.offsetList` 신설(항상 숫자 계산) +
  `mountInst(target, element, index)` + `recompute`의 `base` 시드 + 중첩 Slot이
  자기 `Offset`을 관측해 재계산하는 구독 하나 —
  `qa-request/pre-implementation-qa-round5-followup.md`의 G절이 소스.
- **[해소, 2026-08-21] offset이 바뀌면 이미 배치된 물리 노드를 옮겨야 하는가 —
  아니오.** **사용자 확정**: *"애초에 offset 바뀌여도 상관 없는게 위에서 넣고
  빼면 insert 같은거로 일어나서 뒤로 밀린다는거였긴함"* — DOM류는 삽입/삭제
  자체가 뒤 형제를 물리적으로 밀고 당기므로, **이미 놓인 노드를 다시 옮길 일이
  없다.** offset 숫자는 그 자리가 **다음에** insert/remove할 때 쓰는 것뿐이라는
  기존 서술이 그대로 맞다. 이게 성립하려면 백엔드 op이 **아토믹한 최소 단위**
  (`mountInst`/`unmountInst`/reposition)여야 한다는 게 같이 확인된 요구사항.
  아래는 열려 있던 시점의 서술: `mountInst(target, element,
  index)`가 **삽입 시점의 위치만** 받는 일회성 호출이라, 이미 마운트된 요소의
  물리 위치는 offset이 바뀌어도 갱신되지 않는다. Roblox는 `LayoutOrder`가
  프로퍼티라 `updateFn`이 반응형으로 처리하면 되지만 **DOM은 물리 순서 자체가
  배치**다. `dispatch-core-plan.md`는 "quad-web의 offset 핸들러는 no-op이고 숫자는
  *다음에* 스스로 insert/remove할 때만 쓴다"고 적어뒀는데, 앞 형제의 길이가 변해
  뒤 형제들의 offset이 밀리는 흔한 경우에 **이미 놓인 노드를 옮길지**가 그 서술만
  으론 안 갈린다. 선택지는 (a) 옮긴다(백엔드가 offset 변경을 관측해 재배치),
  (b) 안 옮긴다(그러면 DOM에선 순서가 실제로 어긋남), (c) `:List`가 재조정 때
  필요한 것만 명시적으로 다시 `mountInst`. quad-web이 실제로 생길 때까지 미룰 수
  있으나, **계약을 지금 정해두지 않으면 M6 구현이 (b)를 전제로 굳는다.**
- **[해소, 2026-08-21] `:List` 재조정의 `getOffsetAt` 비용 — 접두합 캐시로.**
  **사용자 제안 채택**: *"getOffsetAt 은 compute 된걸 캐시해도 될듯. length
  변경되는 뒤는 캐시가 무효화되도록 shouldRecomputeAfter 등을 둬서 특정 인덱스
  초과부는 offset 다시 계산하고, 해당 값 위치 자체는 유효하므로 그것을 통해 더
  length 를 이어붙이면 될듯."* → `bk.offsetCache` + **`bk.invalidAfter`**("여기까지는 유효")로 반영
  (`base/dispatch-core-plan.md`). **무효화 규칙은 하나** —
  `invalidAfter = min(invalidAfter, i)`(`setLength`도 splice도 자기 인덱스까지,
  베이스 변경만 `0`). `recompute`도 이 캐시 위에 얹혀 O(N)이라
  **"캐시를 누가 채우나"라는 갈래가 없어졌다**(사용자 정정: 함수를 나눌 이유가
  없다). 아래는 열려 있던 시점의 서술:
  `settle`이 키마다 `rawAdd`/`rawReplace`를 부르고 그 각각이 `getOffsetAt`(O(i))을
  부르므로, 이미 마운트된 리스트의 데이터가 통째로 바뀌면 **O(N²)**다(최초 마운트는
  `_mounted == false`라 얼리 리턴이 막아준다). `DC-9`에서 `setOffsetSource`의 즉시
  계산이 O(N²)인 걸 "배치 등록 1회니 감수"로 판단했지만 **이건 매 reconcile이라
  빈도가 다르다.** 해법은 있다 — reconcile이 `pos`처럼 **절대 offset도 러닝
  누적**으로 들고 다니면 O(n)(그게 `mountSlotTree`가 이미 하는 방식). 그렇게
  할지, 아니면 실측 전엔 그냥 둘지 판단 필요.
- **[해소, 2026-08-21 같은 날] 게이트가 유보했다 내보내는 emit이 싣는 출처 —
  `emit(self)` + 흡수 집합.** `GateNode`가 흡수한 소스를 `withheld` 집합에
  들고 있다가, 풀 때 **자기를 출처로** 하류에 emit 하고 (동기 전파라) 반환 뒤
  `table.clear`한다. 하류는 출처가 게이트면 그 집합의 소스들에 평소 규칙을
  적용한다. **`setup` 시그니처는 안 바뀐다** — 집합을 채우는 건 정책이 아니라
  노드이기 때문. `base/gate-plan.md`의 4번, `base/state-epoch-plan.md` §2.
- **[해소, 2026-08-21 같은 날] State 에포크 — 새 노드의 두 맵 초기값과
  `:With` 병합.** `sourceEmitMap`은 **비우고**(어떤 emit이 와도 "처음 보는
  것"으로 걸리는 게 맞다 — 새 노드는 개념적으로 emit을 받아본 적이 없다),
  `sourceCountMap`은 **전부 끌어와 실제 count로 채운 뒤 `rawInvalid = true`**
  (비워두면 순회가 훑을 목록 자체가 없어 "유효하다"로 오판한다 — *"'내가 뭘
  추적하고 있나' 가 필요하죠"*). 그래서 `:With` 병합 규칙은 **필요 없어졌다.**
  재계산 시 갱신 범위(전부 갱신)도 확정. `base/state-epoch-plan.md`의 §2·§5 7번.
- **[해소, 2026-08-21] 공용 게이트 노드의 이름과 표면 — `state:Gate(setup)`
  메소드 + `GateNode`로 확정.** 탑레벨 프리미티브는 안 만들고, `Blocker`는
  `state:Block(blocker)` 안에서 그 배선을 쓴다(사용자: *"Gate 는 따로
  프리미티브 없이 state:Gate( (emit) -> ()->() ) 처럼 선언되고 마치 Compute
  처럼 GateNode(ComputeNode 처럼) 생성된다"*). `Get()`엔 영향 없음(통지만
  막음)까지 확정. **[2026-08-21 정정]** 여기 "남은 것은 사용자 판단이 아니라
  구현 시 정할 것들"이라 적었으나, 두 번째 `/code-review high`가 **재진입
  계약과 빈 배치 emit을 사용자 판단 항목으로 되돌렸다**(바로 위 항목). 구현 시
  정하면 되는 건 생명주기와 M2 범위뿐 — `base/gate-plan.md`가
  소스. 아래는 열려 있던 시점의 서술: 위 항목의 결정("게이팅 먼저")에 따라 base에 만들 것이
  `Blocker`가 아니라 **상류 emit을 가로채 정책이 통과 여부를 정하는 공용 게이트
  노드**로 확정됐다(`Blocker`/`Debounce`/`Throttle`이 그 위의 정책). 사용자
  스케치는 `Gate(function(emit) return function() ... end end)` 2단 구조이고,
  **공개 API로 낸다**(사용자: *"이 API가 비공개일 이유는 없어보인다"*). 남은 것 —
  (a) **이름**(사용자: *"프리미티브 명을 Gater? 뭔가 이상하게 들어간다는게 약간의
  문제"*, 에이전트 권고는 `Gate` 그대로 — `gate`는 이미 장치를 가리키는 명사),
  (b) M2에 `Gate`만 넣을지 `Blocker`까지 넣을지, 그리고 생명주기/재진입 계약.
  **[2026-08-21 해소]** 여기 있던 "`:Apply` 팩토리인가"와 "`Blocker`가 그 위에
  어떻게 얹히는가"는 닫혔다 — **사용자 확정으로 `Gate`는 `:Apply`가 아니라
  `:With`류 State 메소드**(*"state 의 전파를 손대는 작업이라 with 처럼 다른
  노드가 나는게 맞음"*)이고, 그러면 `Blocker`는 이미 확정된
  `state:Block(blocker)` 메소드가 내부에서 그걸 부르면 되므로 배선 문제 자체가
  없어진다. 상세는 `base/gate-plan.md`.
- **[해소, 2026-08-21] State 재계산/전파 판정을 "소스 에포크 비교"로 바꿀지 —
  채택 확정**(사용자: *"gate 와 epoch 가 제가 만족할만한 정도로 올라왔습니다.
  채택하면 될것 같아요."*). 규칙 전량은 `base/state-epoch-plan.md`, 구현은 M3.
  아래는 열려 있던 시점의 서술: 사용자 제안: 각 State가 자기 상류 루트
  `Source`들의 카운트를 들고 있다가 `Get()` 때 비교해 재계산 여부를 정한다.
  동기는 성능이 아니라 **정확성** — DFS 전파 도중 Observer가 `Get()`을 부르면
  아직 신호를 못 받은 다른 가지의 옛 캐시가 섞여 들어가는 glitch가 지금 모델에
  실재한다. 에이전트 분석 결과 진단·방향 모두 타당하고 선례도 있다
  (MobX/Adapton류 버전 검증). **[2026-08-21 갱신 — 여기 있던 "중복 통지는 안
  고쳐지고 선언 안 된 의존성을 UB로 명문화해야 한다"는 서술은 같은 날 둘 다
  뒤집혔다]**: 중복 통지도 **같은 장치로 접고**, UB 조항은 사용자 기각으로
  빠졌다. 이어진 3·4차 정정으로 **기제는 사실상 다 정해졌다** — 순회는
  `rawInvalid`가 **false**일 때만 돌고(목적은 "못 받은 emit 받기"), emit은
  count 없이 **발행 source만** 싣고, 순회가 발견한 변경은 **테이블 둘**로
  처분한다(`sourceCountMap`은 순회가 앞당겨 올리고, `sourceEmitMap`은 상류의
  진짜 emit을 기다림 — *"emit 바로 안하고 상류가 emit 해줄 때 까지
  기다립니다"*). 그래서 통지가 죽지도 게이트를 새지도 않아 `source = nil`
  규약도 필요 없어졌다. **남은 판단은 채택 여부 자체 하나**이고, State 내부 표현을
  바꾸는 결정이라 M3 뒤로 미루면 되돌리는 비용이 크다. 상세는
  `base/state-epoch-plan.md`.
- **[해소, 2026-08-21 구현 전 QA 5라운드 `C-4`] `Dispatch.setLength`의 Observer
  앵커 — 물리 target으로 확정(4라운드 `D-56` 역전).** `setLength`가
  `(ownerKey, i, len, anchor)`로 4번째 인자를 받아 **부기 키와 생명주기 앵커를
  분리**한다. 그래서 `bindLifetime`은 항상 물리 Instance만 상대하고,
  `isBoundAlive`의 세 번째 분기(형태 미정으로 열려 있던 것)도 **필요 자체가
  없어졌다.** 역전 원문은 `archive/bindlifetime-slot-owner-reversed.md`, 지금
  결론은 `base/dispatch-core-plan.md`의 "`setLength` 구현" 절 뒤 문단. 아래는
  열려 있던 시점의 서술: 그때 확정(4라운드 `D-56`)은
  "`bindLifetime`의 첫 인자가 Slot일 수 있으니 백엔드가 그 경우를 핸들링하라"인데,
  사용자가 그 전제 자체에 의문을 제기했다: *"애초에 Slot 이 effect 나 다른
  요소들을 소유할 수가 없다 … 실제 observer/effect 는 실제 inst 에 불림 …
  우리가 왜 slot 을 소유 대상으로 둘 수 있게 한거였는지 다시 생각해봐야할
  부분."* 대안은 **부기 키(`ownerKey`)와 생명주기 앵커(물리 `physicalTarget`)를
  분리**하는 것 — 그러면 `bindLifetime`은 항상 Instance만 받고,
  `isBoundAlive`의 세 번째 분기(지금 ⚠️ 미정)도 통째로 불필요해진다. 상세와
  트레이싱은 `qa-request/pre-implementation-qa-round5-followup.md`.
- **`Operator` 콤비네이터 슈가 네임스페이스 이름+포함 범위(2026-08-12 신설,
  같은 날 후속으로 외부 리서치 완료)** — `Sum`/`Product`/`Not`/비트연산 등
  `:Compute`/`:Apply`용 슈가 함수 모음의 이름. 흔한 단어라 top-level
  노출은 위험, 후보는 `Operator`/`Op`/`Ops`(`Combinator`는 코퍼스 전반에서
  이미 일반명사로 쓰여서 제외) — **서브 에이전트 외부 리서치 결과 `Operator`가
  가장 선례가 강함**(Python `operator` 모듈)이나 최종 확정은 여전히 사용자
  몫. 같은 리서치에서 포함 범위도 새로 갈렸음 — 비트/비교 연산자 그룹과
  `Sub`/`Div`는 리액티브 콤비네이터로서 선례가 전혀 없어 드랍 후보로,
  `Clamp`/`Min`/`Max`는 선례가 강해 추가 후보로, Debounce/Throttle은
  업계에 흔하지만 `Blocker`와는 다른 시간 기반 메커니즘이라 이 카탈로그
  밖 별개 질문으로 분리됐었음 — **[2026-08-19 해소]** 그 별개 질문은
  `base/debounce-throttle-plan.md`로 전부 해소·승격 완료, 더 이상 판단
  대기 아님. **[2026-08-13 세션 신설]** `Alternative`(nil 대체값, coalesce/`??`/
  엘비스 연산자류) 후보 추가 — Haskell 비교 리서치 중 나옴, 카탈로그 확정
  규칙에 그대로 맞아 포함 근거는 있음. 상세는 `research/operator-sugar-plan.md`.
  구현 자체는 맨 마지막 우선순위(순수 슈가, 없어도 무방) — 여전함.
- **중첩 State 평탄화 `State<State<T>>` → `State<T>`(2026-08-13 여섯 번째
  세션 신설, 백로그)** — **[근거 축소, 열네 번째 세션]** 원래 이 항목의
  주 근거는 "깊은 체인에선 힌트가 `nil`로 전달돼 깜빡임 방지가 꺼진다"는
  실제 기능 손실이었는데, **하강 diff 재디스패치로 각 레벨이 자기 값을
  받게 되면서 그 손실 자체가 없어졌음**(`base/dispatch-core-plan.md`).
  남은 근거는 편의성과 Slot offset이 밀리고 당겨지는 케이스뿐이라
  우선순위가 더 내려감 — `state:Flatten()`류 콤비네이터 아이디어는
  그대로 백로그. 상세는 `research/operator-sugar-plan.md` 마지막 절.
- **[신설, 2026-08-18 커밋 전 `/code-review high`] `store:GetDynamic`을
  콜론 메소드로 둘지, 탑레벨 함수로 둘지** — 콜론 메소드로 두면 Store의
  lazy `__index`(없는 키를 인덱싱하면 그 자리에서 `Source`를 만들어 저장)와
  부딪혀서, `__index`가 고정 메소드 테이블을 먼저 확인해야 하고 그 결과
  **`GetDynamic`이 모든 Store의 예약 키 이름**이 된다(그 이름의 Source는
  dot-access로 못 만듦). Store 키는 사용자 도메인 데이터 이름이라 충돌
  확률이 `Modifier`의 예약 이름들보다 높다. 대안은 탑레벨
  `getDynamic(store, name)` — "특정 프리미티브에 안 묶인 범용 유틸은 소문자
  탑레벨"이라는 기존 네이밍 규칙에는 오히려 더 맞는다. **M3/M4 착수 전
  필요**, `base/store-plan.md`의 "타입 추론 문제" 절.
- **[해소, 2026-08-21] `Detach` 홀드 중 키가 사라졌을 때의 처분** —
  선택지 (c)로 확정: `updateFn`을 **`KeyGone`으로 한 번 더 불러 처분을
  묻는다**. 같이 확정된 것 — detach된 요소는 `userdata`가 아니라
  **`slot._detached` 필드**가 보유하고(그래야 `destroySlotTree` walk가
  닿고 소유권도 유지됨), owner가 죽으면 `activateList`가 설치한 `Effect`가
  정리한다. 원래 갭이
  치명적이었던 이유는 gcconn 트릭 때문에 detach된 quad-제작 Instance가
  **GC 폴백조차 없이 영구히 남기** 때문. 상세는 `base/slot-plan.md`의
  "Detach된 요소는 `slot._detached`가 보유한다"/"`KeyGone`" 절.
- **[해소, 2026-08-21] `attachSlot` 책임 분해** — **(B) 분해 채택으로 확정**,
  `base/slot-plan.md`에 반영 완료(`materializeSlotTree`/`mountSlotTree`/얇은
  `attachSlot`). 근거 기록은 `research/slot-attach-decomposition.md`.
  아래는 그 열려 있던 시점의 서술: 한
  함수가 부모 등록(offset/length) / `:List` 실체화 / 마운트 상태 전이 / 배치
  게이팅 / 자식 배치 / 재귀를 다 지고 있어서, **"부모에게 알리는 길이의
  최종값은 flush가 끝나야 정해진다"와 "부기가 물리 조작보다 먼저"가 동시에
  만족되지 않는다**(지금은 후자를 지키고 전자를 포기 — 부모 `recompute`가
  1회 헛돎). 사용자 판단으로 확장 논의 대기 — 책임 목록/순서 제약 출처/분해
  후보 넷은 `research/slot-attach-decomposition.md`. **M6(`:List`) 착수 전
  필요**, 선행으로 아래 `Detach` 보관 위치가 먼저 닫히는 게 나음.
- **[신설, 2026-08-18 구현 전 QA] 그룹 `Attribute`의 위치별 claim 설계** —
  같은 그룹 객체를 두 위치에 놓는 경우(`Frame { a, a }`)를 잡으려면 위치별
  claim 레지스트리가 하나 필요하다는 **방향은 확정**됐고(`Ref`처럼
  `bindLifetime`을 재사용할 수는 없음 — 그룹 값은 여러 곳에서 쓸 수 있어야
  하므로), **[2026-08-20 QA 4라운드] 이름도 `groupClaimKeys`로 확정**.
  **[해소, 2026-08-21 QA 5라운드 `AT-1`] 키도 `(inst, groupValue) → k`로 확정**
  (사용자: *"group 에 따라 key 가 따로 생성되므로 다른 그룹에 대해서는 잡을
  필요가 없고, 그건 key->name 이 유일성을 검증해준다"*), `nameClaims`보다
  **위치 claim을 먼저** 본다 — `base/attribute-plan.md`의 "이름 소유권" 절.
  **이 항목은 닫혔다.**
- **[신설, 2026-08-18 구현 전 QA] 중간 State GC 미검증** — `State → State →
  State → Observer` 체인에서 중간 노드를 강하게 붙잡는 주체가 문서 어디에도
  없어 전파가 조용히 끊길 수 있음. 방향(상류 strong / 하류 weak)은 사용자가
  지목했고, **명문화 여부 결정 + `luau-test` 실측이 M3 착수 전에 필요** —
  `base/source-state-plan.md`의 "미해결 — 중간 State가 살아남는가" 절.
- **[신설, 2026-08-14 리뷰] `AttributeGroupHandler.process`의 부분 실패
  롤백** — 이름 순회 도중 소유권 충돌 error가 나면 그 전에 등록된 이름들이
  이 사이클엔 회수되지 않음(클로저가 안 만들어짐). 피해는 그 인스턴스
  수명으로 한정되고 재현도 시끄럽게 반복돼서 **지금은 별도 장치 없이
  문서화만** 했는데(`base/attribute-plan.md` "메커니즘" 절), 원자적
  롤백(그룹 `process`에만 국소적인 unwind)을 넣을지는 열어둠. 지금 결정
  불필요 — M10 구현 시점에 판단.
- **[해소됨, 2026-08-18] `Attribute.Merged`의 이름 중복** — `Merged`(겹치면
  error)와 `Overridden`(겹치면 뒤가 이김)을 **둘 다 제공**하는 것으로 확정
  (제3안). 근거·파급은 `base/attribute-plan.md`의 "채택안 — `Tag`와 동형인
  array-part 값 객체" 절.
- **`quad-debug` 세부 API 이름** — `research/debug-tooling-plan.md` 참고.
  채널 실현 가능성(BindableEvent/Function이 플러그인↔Play 중 게임 경계를
  넘는지)까지 사용자가 Studio에서 직접 실측 검증 완료 — 기술적 불확실성은
  다 해소됨, 남은 건 세부 API 이름뿐("이벤트 함수가 self로 instance를
  읽는 게 quad 관습"이라는 언급은 2026-08-06 후속 세션에서 해소 —
  채택 안 함으로 확정, `base/event-plan.md` "이벤트 핸들러는
  self(Instance)를 받지 않는다" 절 참고). 사용자가 "quad 개발 완료 전엔
  착수 못 함"으로 직접 후순위 지정한 건 여전함 — base 설계(M2 Dispatch/
  M3 Source/M5 `D` 생성자) 시점에 훅 확장 지점만 고려해두면 됨.
- **문서화 전략(UI 네이밍 컨벤션, Store 부작용을 게임 시스템에서 쓰는
  패턴)** — `research/documentation-plan.md`(뼈대만). 정식 백로그 항목으로
  올릴지, 착수 시점을 언제로 볼지 사용자 판단 필요.
- **v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat`** —
  `research/v1-compat-plan.md`(신규, 2026-08-06, 두 차례 후속 논의로 수렴).
  방향 확정: v1을 그대로 병행 실행 + 경계에서만 `state:Observer()`(lazy
  포기)로 값을 리졸브해 v1 프로퍼티에 재대입하는 브리지, v2→v1 단방향만
  (양방향 불필요로 확정), 패키지명 `quad-roblox-v1-compat`으로 확정(소스
  트리에 세 번째 패키지로 추가될 예정). v2-in-v1/v1-in-v2 두 임베딩 방향
  모두 기술적 근거와 안전 규칙까지 정리됐으나(문서 7번), **Slot이 foreign
  Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 결정 불가로 남음**
  (위 "여러 Slot이 형제로 섞일 때 순서 보장" 항목과 같은 시점에 확인).
  그 외 §8의 세부 항목(v1 자기 루트의 `Destroying` 자기청소 여부,
  `registerClass` 체이닝 기능 브릿징 필요성)은 문서 자체가 "지금 결정
  불필요"로 표시해둠 — 위 Slot 항목과 별도로, 실제 compat 레이어 구현
  시점에 `research/v1-compat-plan.md` §8을 다시 열어 확인.
- **Slot이 quad 밖에서 만들어진 임의 Instance를 받을 수 있는가**
  (2026-08-06 추가, 아직 안 풀림) — v1 compat 등에서 넘어온 foreign
  Instance를 동적 배열 원소로 받을 수 있는지, retract 시 어떻게 다루는지.
  **Slot 코어 구현(M6) 시점에 확인** — `research/v1-compat-plan.md` 7-3.

> **없어진 번호에 대해**: 예전 "0번(추가 프리미티브)"과 "2번(구현 착수
> 직전 감사 결과)"은 전원 해소되어 통째로 `archive/question-resolved.md`로
> 갔음. 우선순위1 11개의 개별 상태가 궁금하면
> `research/pre-implementation-audit.md`가 원본이자 최신.

---
전체 순서/우선순위는 `.claude/todos.md`가 최종 소스. 확정된 것들의 문서
색인은 `.claude/README.md`의 `base/` 표(예전에 이 문서 맨 아래에 있던
요약표는 그것과 중복이라 archive로 옮김).
