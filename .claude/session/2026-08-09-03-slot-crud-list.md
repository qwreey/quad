<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 세 번째 세션 — Slot CRUD 완전 확정, 키 기반 동적 컬렉션
재조정이 `Slot:List(...)` 메소드로 통합·승격

위에서 예고된 "다음 세션 주제"(Slot과 키 기반 동적 컬렉션 재조정)를
실제로 다룬 세션. `pre-implementation-audit.md` 1-7/1-8과
`research/additional-primitives-plan.md`의 마지막 열린 항목이 전부
`base/slot-plan.md`에 흡수·확정됐음 — 상세는 그 문서 본문이 소스,
여기는 요지만:

- **Slot CRUD 최종 확정**: `Add(element, index?)`/`Remove(element)`(제거+파괴)/
  `Extract(element)`(제거, 파괴 안 함)/`Clear()`(전체 `Remove`) — `get`/`set`은
  드롭(YAGNI). 식별은 항상 element 레퍼런스 기준(인덱스 아님). 에러 조건
  전부 즉시 `error()`(이미 다른 곳에 마운트된 element를 `Add`, 멤버 아닌
  element를 `Remove`/`Extract`) — fail-fast 톤 유지. 재진입성은 별도 가드
  불필요(기존 "무한루프 방어 안 함" 원칙 재사용). `Slot()`은 인자 없는
  빈 생성자로 확정.
- **`isMounted` 이중 추적 분리(1-8 해소)**: Slot 컨테이너 자신은
  `self._mounted`(트리거는 `Dispatch.process`가 이 Slot 객체에 실제로
  호출된 시점 — 다른 모든 "마운트됨" 판정과 동일하게 dispatch-process
  기준), 개별 element는 전역 weak-set(라이브러리 전역 다중 마운트 금지
  불변식이라 특정 Slot에 안 묶임).
- **`Extract` 후 portal 범위 — 임의의 다른 Slot으로 자유 이동 확정.**
  기존 "retract되는 slot은 폐기되지 옮겨지지 않는다"는 확정은 **프레임워크가
  store-bind 재실행으로 값을 통째로 갈아치우는 시나리오**에만 해당하고,
  사용자가 명시적으로 `Extract`→`Add` 두 번 호출해서 옮기는 것과는 다른
  얘기라는 걸 명확히 구분(사용자 확인).
- **키 기반 동적 컬렉션 재조정 — `Slot:List(data, keyFn, renderFn) -> Slot`로
  확정, 자유 함수/새 타입 둘 다 기각.** 처음엔 `List(...) -> Slot` 자유
  함수를 검토했으나, "타입 이름=반환 타입"이라는 `Source(default)`류
  팩토리 컨벤션이 깨진다는 문제를 사용자가 직접 지적 — Source⊇State식
  구조적 서브타입도 검토했으나 List가 Slot 위에 새 공개 메소드를 안
  얹으므로(그냥 "자동으로 채워지는 Slot") 별도 타입일 근거가 약해 기각.
  최종적으로 "원천에 종속된 파생 데이터는 메소드로만 얻어진다"(State/
  Observer와 같은 원칙, 여기 원천은 Slot 자신)로 수렴 — `Ref():Callback(fn)`
  체이닝과 같은 패턴. Fusion `ForPairs`/`ForKeys`/`ForValues` 3분할도
  단일 `:List`로 통합 확정.
- **구현 메커니즘은 전부 기존 프리미티브 재사용, 새 개념 없음** — 사용자가
  "너무 마법같다"고 지적해 의사코드까지 구체화해서 검증: `data:Observer(fn)`
  (2026-08-07 확정된 "등록 즉시 1회 실행"), `Source(item)`, 방금 확정한
  Slot CRUD의 비공개(가드 안 거치는) 버전 세 개의 조합일 뿐. `itemSources`/
  `elements`/`order`는 Slot 인스턴스의 평범한 클로저 업밸류(별도 전역
  저장소 불필요). 리오더는 `Extract`+`Add(index)` 조합, 최소-이동
  알고리즘 자체는 구현 시점 최적화로 미룸.
- **`renderFn(key, itemState)`의 `itemState`는 내부 `Source`를 그냥
  `State`로 다운캐스트해서 넘김 — 별도 `ReadOnlySource` 타입 안 만듦**
  (사용자 확인: "그걸 위해 ReadOnlySource 같은 걸 만들 이유가 있냐 하면
  아니다, 이미 그게 State다"). 타입 레벨 힌트만, 런타임 강제 없음(`Peek`/
  Modifier UB와 같은 "규율 위반은 방어 안 함" 기조) — 나중에 진짜
  런타임 강제가 필요해지면 `src:Compute(function(v) return v end)`(항등
  함수 Compute)로 `:Set` 없는 State를 만드는 가벼운 대안이 있다는 것만
  메모.
- **백로그, 착수 안 함(연구만) — reconcile의 무조건 `:Set()` 재전파.**
  `data`가 테이블 뮤테이션+`:Emit()`으로 오는 경로도 지원해야 해서 이전
  값과 동등성 비교를 할 방법이 없고, 그래서 값이 실제로 안 바뀐 item도
  매 재계산마다 재전파됨 — 사용자 판단: "이 재계산 비용은 우리가 핸들해야
  할 부분은 아닌 것 같다", `Blocker`류 값-동등성 기반 전파 억제도 검토했으나
  "확정 안 하면 이전 값 자체가 없어서 비교가 안 된다"는 근본적 어려움이
  있어 기술적으로 더 논의해볼 만한 주제로만 `research/
  additional-primitives-plan.md`에 백로깅.
- **`research/additional-primitives-plan.md` 사실상 전부 해소** — 마지막
  열린 항목(키 기반 컬렉션)까지 없어져서, 이 문서엔 이제 새로 열린 설계
  질문이 없음(배경 자료로만 유지). `question.md`/`ROADMAP.md`(M6 체크박스)/
  `README.md` 전부 동기화 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — Slot/키 기반 컬렉션
재조정이 이번 세션에서 완결됐으므로 더 이상 "다음 세션 예고" 대상 아님.
남은 열린 것은 여전히 `question.md`의 `DI`→`D`/`canExecute`→`isAlive`/
`Brand` 이름, `pre-implementation-audit.md` 1-3(우선순위 스캔 동률 처리),
"여러 Slot이 형제로 섞일 때 순서 보장"(Roblox 단일 백엔드론 급하지 않음)
정도.

**같은 세션 후속 — quad-roblox 구현 관점에서 재검토, `Move`/`Swap` 공개
CRUD로 추가(원시 최소화 원칙 뒤집음), `renderFn`에 `indexState` 추가.**
사용자가 "Slot 값 변경을 quad-roblox가 실제로 어떻게 따라가나"를 구체적으로
캐물으며 세 가지가 드러남:
- **`renderFn(key, itemState) -> element`에 위치 정보가 빠져있었음** —
  Roblox는 순서를 `LayoutOrder`로 표현하므로 `renderFn`이 그걸 반응형으로
  바인딩하려면 위치도 State로 받아야 함. `itemState`와 독립된
  `indexState: State<number>`를 추가(`renderFn(key, itemState,
  indexState)`) — 값 변경/위치 변경은 서로 독립 신호라는 게 근거, Slot이
  `LayoutOrder`를 대신 관리해주는 마법은 안 둠.
- **`Extract`+`Add(index)`로 리오더를 구현하면 백엔드에서 진짜 Parent
  조작이 두 번(detach+reattach) 일어난다는 게 드러남** — Roblox
  `AncestryChanged` 발화, 잠재적 깜빡임, 불필요한 재바인딩 비용까지
  딸려올 수 있어 매 `:List` 재계산마다 흔한 케이스치고 과함.
  **`Move`(O(n), 배열 splice 의미)/`Swap`(O(1), 순수 페어 교환)을 공개
  CRUD로 추가** — 둘 다 Parent를 안 건드림. `:List` 없이 수동으로 Slot을
  구성하는 사용자에게 애초에 리오더 수단이 아예 없었다는 것도 같이
  드러난 공백 — "원시 연산 최소화" 원칙보다 이 두 실사용 공백이 우선한다고
  판단해 뒤집음(같은 세션 내 정정이라 별도 archive 없이 `slot-plan.md`
  본문에 "원시 최소화 원칙 정정" 절로 직접 반영).
- **base/roblox 패키지 경계에 mount/unmount 둘로는 부족, reposition
  훅이 세 번째로 필요함** — `Dispatch/Slot.luau`/`Handlers/Slot.luau`가
  이제 "Parent 조작(mount/unmount)"뿐 아니라 "Parent 안 건드리는 재배치
  (reposition, `Move`/`Swap`)"까지 계약해야 함. quad-roblox가 이걸
  `SetSiblingIndex`로 구현할지, `LayoutOrder` 기반 정렬이라 사실상 no-op
  으로 둘지는 구현 선택으로 열어둠.
- **item 값 전파(무조건, 백로그)와 index 전파(실제 변경시만)가 비대칭인
  이유도 명확해짐** — item 값은 외부 뮤테이션+`Emit()` 경로 때문에 "이전
  값"을 비교할 방법이 없지만, `:List`가 전적으로 소유하는 `keyIndex`는
  "실제로 위치가 바뀌었는지"를 정확히 알 수 있어 index 쪽엔 같은 문제가
  없음 — 그래서 index 전파는 처음부터 조건부로 구현.

전부 `base/slot-plan.md`(CRUD 표, "원시 최소화 원칙 정정" 신규 절, `:List`
구현 스케치·설명 갱신)/`ROADMAP.md`(M6)/`README.md` 반영 완료. `question.md`엔
새로 열린 항목 없음 — 이번 후속도 순수 확정/구현 세부 명확화.

**같은 세션 두 번째 후속 — `Swap`을 element 레퍼런스가 아니라 인덱스
기준으로 정정, "공개 CRUD는 가드+`raw*` 위임" 구조 명문화.** 사용자가
`Swap(elementA, elementB)`를 바로 잡음 — element 레퍼런스로 받으면 Slot이
element→index 역방향 맵을 안 갖고 있는 이상 두 element의 현재 위치를 각각
찾는 데 O(n)씩(총 2n) 들어서, `Swap`이 약속한 O(1)이 그 자리에서 깨짐.
`Move`는 시프트 자체가 O(n)이라 조회 비용이 묻히지만 `Swap`은 조회 비용이
곧 전체 비용이라 이 차이가 그대로 드러남 — `Slot:Swap(indexA, indexB)`로
정정(호출부가 이미 "몇 번째와 몇 번째를 바꿀지"를 아는 상황, 예: 드래그
리오더 UI, 이라는 것도 자연스러움의 근거). 이어서 사용자가 "`Slot:Move`
구현은 결국 락(`_listed`) 확인만 하고 실제 로직은 `rawMove`류에 다 있는
구조 아니냐"고 확인 요청 — 맞다고 답하며 이걸 여섯 CRUD 전체에 적용되는
일반 구조로 명문화: `Add`/`Remove`/`Extract`/`Clear`/`Move`/`Swap` 전부
"`self._listed` 확인 + `raw*` 위임"뿐인 얇은 wrapper, 실제 로직은 전부
`raw*` 함수 세트 하나에 있고 `:List`의 reconcile도 그 세트를 가드 없이
직접 호출. 전부 `base/slot-plan.md`/`ROADMAP.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 세 번째 후속 — Slot 요소 타입 제약 신설: `nil` 금지/`None`
허용/핸들러 계층 값(Ref/PreRef/Observer/Effect/Modifier) 금지, `Slot<T>()`
제네릭화.** 사용자가 "Slot 안에 뭐가 들어갈 수 있는지 정해진 바 없다"고
지적하며 시작 — 처음엔 제가 "Ref/Observer/PreRef도 Slot 요소로 허용,
`D.InstSlot = Slot<<Instance>>`류 백엔드 별칭으로 좁히자"고 제안했으나,
사용자가 바로 반박: Slot이 동적으로 다뤄지는데 그 안에 Ref/Observer가
들어가면 quad-roblox가 그걸 처리할 방법이 없고(특수 대응을 새로 만들어야
해서 오버엔지니어링),애초에 왜 필요한지도 불명확하다는 지적 — 검증해보니
정확히 맞았음:
- `Dispatch/Leaf.luau`가 처리하는 "children 배열에 Ref/Observer/PreRef가
  직접 놓이는" 케이스는 **그 컴포넌트가 지금 만들고 있는 Instance 자기
  자신을 가리키는 self-ref 캡처**라(`Frame { PreRef():Callback(fn) }`가
  그 Frame 자신을 잡음), `inst`가 "지금 생성 중인 바로 그 하나의 Instance"로
  고정돼 있어야 의미가 성립함. Slot은 특정 컴포넌트 호출 하나에 안 묶이고
  이미 존재하는 부모에 나중에 독립적으로 붙는 동적 리스트라 이 전제
  자체가 없음 — Slot 안의 Ref가 "무엇"을 가리켜야 하는지 정의가 안 됨.
- 대체 경로가 이미 있어 능력 손실도 없음 — 특정 child에 ref가 필요하면
  그 child를 만드는 컴포넌트 호출 자체에 Ref를 넘기면 됨
  (`slot:Add(Frame { Ref = myRef })`).
- 사용자가 직접 대비시킨 반례도 정확함: `State<Slot>`(Slot 자체가 State의
  값)은 retract 시 통째로 버려지고 다시 채워지는 굵은 단위 교체라 이미
  확정된 모델(폐기, 재구성)과 맞지만, Slot **요소 하나하나**로
  Ref/Observer가 들어가는 건 그런 굵은 단위 교체가 아니라 세밀한 CRUD
  대상이라 성격이 다름.
- **결론**: `Modifier` 필드가 핸들러 계층 값을 담으면 즉시 `error`로
  확정했던 것과 같은 판별 메커니즘(`isRef`/`isPreRef`/`isObserver`/
  `isEffect`/`isModifier` Brand predicate)을 Slot에도 재사용 — 새
  메커니즘 없이 그대로 막음. 덕분에 `Slot<T>`의 `T`도 "실제로 마운트
  가능한 최종 값의 타입"으로 단순해짐 — quad-roblox엔 사실상 `T =
  Instance` 하나뿐이라 `D.InstSlot = Slot<<Instance>>`가 사실상 "그"
  Slot 타입. `nil`은 기존 배열 파트 `None` 원칙을 그대로 적용해 금지,
  `None`은 `:List`의 `renderFn`이 "이 item은 이번엔 스킵"을 표현하는
  용도로 허용 — `renderFn`의 반환 타입도 `T | None`으로 갱신.
- `Slot<T>()`가 무인자 생성자라 `T` 추론이 안 되므로 tbox 명시적 제네릭
  적용(`Slot<<Instance>>()`)이 필요하다는 것도 같이 반영 — 정확한 문법은
  "자식으로 넘기는 클래스 스토어" 절의 기존 tbox 참고 미결과 같은 갈래로
  묶어 열어둠.

전부 `base/slot-plan.md`(신규 "요소 타입 제약" 절, CRUD 에러 조건,
`renderFn` 반환 타입) 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 네 번째 후속 — `Slot:List`의 `renderFn`을 "1회 호출"에서
"매 사이클 호출 + `before` 재사용"으로 재설계, filter/toggle 문제 해결.**
사용자가 두 가지를 연달아 제기: (1) `renderFn`이 `None`을 반환해 "지연
렌더"를 표현하는 아이디어는 좋지만, State 변경으로 이미 렌더된 필드를
나중에 다시 지워야 하는 경우(filter)는 기존 "1회만 호출" 모델로 안 풀림.
(2) filter/sort를 Slot에서 어떻게 구현할지가 문제 — 흔한 회피책인
"`Visible`만 토글"은 필터링된 item도 여전히 완전히 살아있는 Instance로
남겨서(애니메이션/이벤트 연결 계속 돎) 200개+ 리스트에서 lazy하지 않다는
실질적 비용이 됨.

**해법 — 사용자가 직접 제시**: `renderFn(itemState, before: inst?): inst?`
모양으로 바꿔 **매 reconcile 사이클마다 호출**하되, 이전에 마운트된
element(`before`, 없으면 `nil`)를 받아서 `if before then return before
end`(바꿀 거 없으면 그대로 반환, 값 갱신은 이미 물려있는 반응형 바인딩이
자동으로 함)로 저비용 재사용 경로를 만듦 — filter 탈락 시엔 `nil` 반환으로
**진짜 파괴**(Visible 토글 아님). 편의상 `renderFn`이 raw `nil`을
던지는 게(Lua에서 자연스러운 관용구) `None`보다 편하다는 것도 사용자가
지적 — 검토 결과 `renderFn`의 반환값은 raw Slot 요소로 직접 들어가는
게 아니라 `:List`의 reconcile이 해석만 하는 것이라, `nil`을 받아도 위
"요소 타입 제약"(raw Slot 요소는 `nil` 금지)과 전혀 안 부딪힘 — `nil`/
`None` 둘 다 "스킵" 신호로 동일하게 받아들이기로 정리.

**부수적으로 드러난 것 — "이전 상태를 다음 렌더에 어떻게 넘기냐" 문제는
이미 해소돼 있었음.** 사용자가 "item이 보통 plain table이라 매 렌더마다
Source/Store를 새로 안 만들려면 이전 상태를 어딘가 저장해야 하는데 그게
어렵다"고 우려했으나, 확인해보니 `itemSources[key]`/`indexSources[key]`가
`renderFn` 호출 여부와 무관하게 **처음부터 `:List` 자신이 계속 소유**하고
있어서(원래 설계 그대로) — `renderFn`이 매 사이클 불려도 이 부분은 전혀
안 바뀜, item이 filter 탈락 후 재등장해 Instance가 파괴됐다 새로 만들어져도
반응형 Source는 안 끊기고 그대로 이어짐. 이 부분은 재설계가 아니라 기존
설계가 이미 답이었다는 걸 확인한 것.

**sort는 이번 재설계와 무관** — 호출부가 `data` 순서를 바꾸면 기존
`keyIndex`/`Move` 메커니즘이 이미 처리, 새로 손댈 것 없음(사용자가 filter와
같이 물었던 것 중 이건 원래도 문제 없었음).

전부 `base/slot-plan.md`(요소 타입 제약 절 "None 허용" → "nil/None 둘 다
금지"로 정정, `:List`의 `renderFn` 시그니처·구현 스케치·"왜 매 사이클
호출로 바뀌었는가" 신규 절)/`ROADMAP.md`(M6)/`README.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 다섯 번째 후속 — `renderFn` → `updateFn` 개명, `:List`가
`Source` 생성을 그만두고 `userdata`로 그 권한을 통째로 넘김.** 사용자가
"`renderFn`이 아니라 `updateFn`이 맞고, `itemState`도 `:List`가 강제로
만들지 말고 원문 item + `userdata: UD?` + `prev: T?`를 주는 게 낫다"고
제안 — 검토 후 채택, 근거:
- **`itemState`/`indexState`를 `:List`가 강제로 만드는 건 불필요한 강요였음**
  — 반응형이 필요 없는 단순한 행까지 전부 `Source` 생성 비용을 지게
  했음. `userdata`로 권한을 넘기면 필요한 item만 자기 `Source`를 만들어
  `userdata`에 담고, 나머지는 매번 raw `item`에서 다시 계산해도 됨 —
  `:List`가 미리 정할 이유가 없는 선택.
- **"이전 상태를 다음 호출에 넘기는" 문제, 원래 걱정했던 것과 달리
  `userdata`라는 명시적 채널로 완전히 해소됨** — item이 plain table이라
  매번 `Source`를 새로 안 만들려면 어딘가 저장해야 한다는 우려가 있었는데,
  `userdata`가 정확히 그 저장소.
- **`prev`(구 `before`)와 `userdata`가 원래 비일관적이었음** — 사용자가
  직접 지적: 하나(`prev`)는 `:List`가 자동 관리하는데 다른
  하나(`userdata`)만 수동 반환을 요구했음. 해법은 **둘 사이 커플링을
  완전히 제거** — `result`가 `nil`이라고 `:List`가 `userdata`를 자동으로
  안 지움, 그대로 기록만 함. 흔한 경우(둘 다 리셋)는 `return nil` 하나로
  Lua가 나머지 반환 슬롯을 알아서 `nil`로 채워주고, "파괴하되 캐시는
  남기고 싶다"는 정당한 패턴은 `return nil, ud`로 명시적으로 표현
  가능해짐 — 이전 설계(result nil이면 userdata 자동 삭제)로는 이 패턴이
  원천 봉쇄돼 있었음.
- **제가 놓칠 뻔한 버그를 사용자와의 논의 과정에서 직접 잡음**: `userdata`가
  이제 `mounted`(실제 element)보다 오래 살 수 있게 되므로, 정리 루프가
  `pairs(mounted)`만 순회하면 "필터 탈락 상태(mounted=nil)로 `userdata`만
  살아있던 key가 `data`에서 완전히 사라지는" 케이스를 못 잡고 새서
  — 직전 사이클의 전체 key 집합(`keyIndex`, 매 사이클 모든 key에 대해
  채워짐)을 순회하도록 정정.
- **부수 효과 — "item 값 무조건 재전파" 백로그가 사라짐**: `:List`가
  더 이상 `Source`를 안 만드므로 그 문제 자체가 `:List` 소관이 아니게
  됨, `updateFn` 작성자의 선택으로 넘어감.
- `userdata = userdata or {}`류 lazy-init 관용구가 `UD`가 자유 제네릭인
  채로 Luau 타입 시스템에서 잘 좁혀지는지는 실측 필요 항목으로 명시적으로
  남김(사용자가 직접 이 불확실성을 짚음) — M0/M6 착수 시 확인.

전부 `base/slot-plan.md`(`:List` 절 전면 재작성 — `updateFn` 시그니처/구현/
"왜 `Source`를 `:List`가 안 만드는가" 신규 절)/`ROADMAP.md`(M6)/
`README.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 여섯 번째 후속 — `keyFn` 선택 인자화(파라미터 순서 정정),
`userdata` cleanup 훅 검토 후 기각·GC-native 제약 명문화, 문서화 순서
질문은 백로그로 이관.** 사용자가 세 가지를 짧게 제기:

1. **`Slot:List(data, keyFn, updateFn)` → `Slot:List(data, updateFn,
   keyFn?)`로 파라미터 순서 정정, `keyFn` 선택 인자화.** 실사용 대부분
   (사용자 추정 80%)이 item identity 추적 없이 순번을 key로 써도 충분한
   단순 목록이라 매번 `keyFn`을 명시하게 하는 게 불필요한 보일러플레이트 —
   생략 시 `function(item, index) return index end` 기본값. tradeoff(중간
   삽입/삭제 시 그 뒤 항목들이 "다른 item인데 같은 key"로 오인돼 캐스케이드
   갱신 — identity 보존 없음, 파괴/재생성 자체는 없음)는 React `key` 생략
   시 index 기본값 등 업계 흔한 관행과 같은 결이라 새로 설명할 개념 아님.
2. **`updateFn(item?, ...)`로 바꿔 최종 제거 시 "정리용 1회 추가 호출"을
   주는 안 — 검토 후 기각, 사용자가 직접 반례를 찾음.** 이 훅은 `data`에서
   key가 빠져 `reconcile`이 다시 도는 정상 경로에서만 발화하는데, **Slot을
   담은 부모 Instance 자체가 `Destroy`되는(가장 흔한) 경로는
   `reconcile`이 다시 안 돌아서 이 훅이 전혀 안 불림** — 절반만 동작하는
   정리 메커니즘은 없는 것보다 위험(사용자가 "정리가 보장된다"고 오해하고
   `Subscribe`류를 `userdata`에 넣었다가 Destroy 경로에서 조용히 샘).
   `retract`가 Destroy 시 절대 안 불린다는 기존 원칙(`lifecycle-pattern.md`
   "quad는 라이프사이클 중간에 있지 않다")과 정확히 같은 이유로 기각.
   **대신 `userdata`엔 GC-native 값만 담고, `:Subscribe()`한 Observer류처럼
   명시적 cleanup이 필요한 값을 담는 건 UB로 명문화** — quad 전역
   GC-native 원칙을 `:List`라는 구체 지점에 그대로 적용한 것뿐, 새 원칙
   아님.
3. **문서화 순서(getting-started에서 단순 버전만 가르치고 나중에
   `prev`/`userdata` 최적화를 알려줄지, 아니면 Slot이 학습 순서상 후반부라
   처음부터 완전한 형태로 가르칠지)는 결정 안 함** — `research/
   documentation-content-map.md`의 modifier/slot 절에 백로그로 추가,
   제 의견(후자 쪽으로 기욺)만 메모, 실제 콘텐츠 작성 시점 결정 사항이라
   지금 확정 안 함.

전부 `base/slot-plan.md`(`:List` 시그니처/코드 재정렬, `keyFn` 기본값
설명, "`userdata`의 생명주기 제약" 신규 절)/`ROADMAP.md`(M6)/`README.md`/
`research/documentation-content-map.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

