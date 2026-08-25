# 컴포넌트화 (Roblox 기본 오브젝트 이외의 사용자 정의 컴포넌트)

**상태**: base — 2026-08-04 세션(6차 라운드 이후) 채팅 논의로 핵심 골격 +
modifier/Ref 컴포넌트 경계 통과 문제까지 전부 확정. 사용자가 "지금 quad에서
가장 문제되는 부분"으로 직접 지목했던 주제였으나 이번 라운드에서 수렴 완료.
[2026-08-04 기준] 남은 건 API 이름뿐(아래 "남은 열린 질문" 참고). `base/bind-system-plan.md`의
Store/State/Source 온톨로지가 먼저 확정된 뒤에야 이 논의가 열림 — 그
문서가 선행 컨텍스트.

## 문제

v1의 `Class.Extend()`(Init/Render/AfterRender/Getter/Setter/UpdateTriggers,
`reference/quad-v1-architecture.md` 참고)는 이미 OOP 상속 스타일이라 폐기
방향이지만, 그게 제공하던 실제 편의 기능(컴포넌트가 자기 store를 자동으로
가짐, props로 넘어온 State를 자동 흡수, `self:Default`/`self "key"`로
기본값·바인딩)까지 같이 버려도 되는지가 미결이었음. `MyComp {...}` 형태로
호출되는 사용자 정의 컴포넌트를 v2에서 어떤 모양으로 작성하게 할지가 핵심
질문.

## v1 실제 메커니즘 (조사 완료, `quad.qwreey.kr` 튜토리얼 + `initreq/quad/src/` 소스로 교차검증)

- `myStore "key"` → register(현재 State에 해당) 반환. `:Default(v)`/
  `:With(fn)`/`:Add(v)`/`:Tween(opts)` 체이닝 가능(`store.lua:433-457`).
- `Class.Extend()`의 `:Init(props)`에서 `props:Default("Size", v)`로 기본값
  설정, props 테이블 자체가 store 인스턴스로 변신(`class.lua:365-379`,
  `storeNew(prop,nil)`).
- props로 넘어온 값이 State(`quad_register`)면 `initStoreRegisterBinding`
  (`store.lua:394-431`)이 자동으로 감지해 컴포넌트 자신의 store 키에 재귀
  연결 — **자동 흡수 매직**이 실제로 존재했음.
- `self(name)` linker가 **두 가지 역할**을 겸함: (1) `self "_button"`을
  자식 자리에 넣으면 렌더링된 인스턴스를 `self._button`에 즉시 잡아둠(Ref
  역할) (2) `[Event.Prop "Text"] = self "Text"`로 인스턴스 프로퍼티 변경을
  다시 컴포넌트 store로 역방향 전파(양방향 바인딩, `EmitPropertyChangedSignal`
  자동 연결과 동일) — quad.qwreey.kr 튜토리얼 `11_extend/` 문서 원문 확인.

이 두 역할이 v2 온톨로지에서는 이미 갈라져 있음: (1)은 확정된 **Ref**가
대체, (2)는 아래 "4. Source 직접 전달" 절이 대체(폐기된 `StoreSource`
프록시와는 다른 개념 — 혼동 방지용으로 명명을 맞춤).

## 수렴된 결론

### 1. 컴포넌트 = 그냥 함수, "자기 store 자동 소유" 매직은 폐기

`MyComp = function(props) return Frame {...} end`, 호출 규약은
`Frame{...}`와 동일(`MyComp{...}` → `MyComp(propsTable)`). v1의 Extend
자동-store-생성+자동-흡수 매직은 재현하지 않음 — 대신 React식으로 호출부가
State/raw/Source/콜백 중 뭘 넘길지 명시적으로 고름. 이유: 자동 흡수는
매 컴포넌트 호출마다 "이 prop이 State인가?" 타입 분기를 프레임워크가
암묵적으로 수행해야 하는 매직이고, 명시적 전달이 더 단순·예측 가능(React가
Vue/Svelte 대비 내세우는 강점과 동일 논리) — **사용자 확정**("마법 안쓴다
그것도 동의함").

### 2. State/Source 경계 규칙: 파생이면 읽기전용, 원본이면 쓰기 가능

State는 `:With`/`:Compute`로 만들어진 파생값일 수 있어 쓰기가 정의 자체가
안 됨. Source는 파생이 아니라 항상 원본 슬롯 하나를 직접 가리키므로 쓰기가
의미 있음 — **사용자 확정**("맞음. 확실해"). 이 원칙 자체는 그대로 유지되고,
아래 3번의 구체적 메커니즘만 2026-08-06 후속 세션에서 더 단순하게 갱신됨.

### 3. Store는 내부 Source를 `store:Of(key)`로 준다 — Source가 State를 구조적으로 만족

> **[2026-08-25] 이 절의 결론은 유지된다.** 같은 날 오전에
> "`store.key`가 값이고 `store:Of(k)`가 프리미티브"라는 재설계를 넣었다가
> **같은 날 철회**했다 — `archive/store-value-field-redesign-withdrawn.md`.
> 바뀐 것은 **생성이 명시적 초기화가 됐다는 것 하나**다(아래 ⭐).

**확정**: `Source<T>`가 구조적으로 `State<T>`를 만족하므로(단방향 호환,
Svelte `Writable<T> extends Readable<T>`와 같은 모양), **`store.key`는
진짜 Source 객체를 그대로 반환하는 평범한 레코드 필드다** — 별도 프록시
타입도, 별도 캐싱 계층도, **타입 함수도** 없다(Source 자체가 이미 State의
읽기 계약을 전부 만족하고 거기에 `:Set(value)`/`:Emit()`이 추가로 있을
뿐이라 "원본이라 쓰기 가능"이라는 위 2번 규칙과도 자연히 맞아떨어짐).
쓰기는 `store.key = v`가 아니라 `store.key:Set(v)`
(`base/store-plan.md`의 "Store 값 설정 문법" 절).

- **⭐ [2026-08-25] 생성은 명시적 초기화다** — 타입 인자에 `Source<T>`를
  직접 쓰고 `defaults`에도 `Source(v)`를 직접 넣는다. 옛 lazy `__index`
  (없는 키를 그 자리에서 만들어 저장)는 폐기됐고, 그래서 **선언 키 집합의
  런타임 소스가 하나**가 된다. 부모가 값을 다 안 넘겨도 되게 하려면
  **컴포넌트가 자기 `DEFAULTS`로 채워** 넘긴다.
- 동적 키는 `store:Of<<T>>(name)` 하나다(옛 `GetDynamic` 흡수).

상세 근거·타입 설계는 `base/source-state-plan.md`의
"Source가 State를 만족함" 절과 `base/store-plan.md`가 최종 소스.

**[이전에 확정했다가 폐기된 `StoreSource` 프록시 설계는 이 결론으로
완전히 대체됨 — 원문·역전 이유·신구 비교표는
`archive/store-source-proxy-reversed.md` 참고, 여기서는 반복하지 않음.]**

### 4. Source 직접 전달 — 타입 유니온 불필요, 서브타입 호환으로 자동 통과

핸들러는 `State<T>` 하나만 받아도 Source 인스턴스가 서브타입 호환으로
자동 통과된다(`Source<T> | State<T>` 유니온 불필요, `isHandlable`/
`priority`/`process` 3종 계약에 항목 추가 불필요 — 2026-08-13 다섯 번째
세션에 `retract`가 `process` 반환값으로 합쳐지기 전엔 4종이라 적혀
있었음). 런타임에
"이게 Source면 역방향 쓰기까지 걸고 싶다"처럼 구분하고 싶은 경우는
`isSource`류 판별자로(`isObserver`와 동일한 패턴).

- **실사용 범위가 좁다는 판단은 그대로 유지**: `isEnabled`처럼 여러 조건에
  영향받는(=파생된) 값은 애초에 State지 Source가 아니므로 이 경로로 못
  넘김. Source 직접 전달이 통하는 건 진짜 단순한 1:1 원본-토글 케이스뿐이고,
  일반적인 경우엔 React식 `value(State) + onChange(callback)` 패턴이 기본
  — **사용자 확정**("isenabled가 여러 조건에 영향 받으면 바로 문제가
  생기는거지. 따라서 실제 사용은 제한적일듯. callback을 쓰는게
  일반적이여 보이긴 해. 타입으로도 편하기도 하고 디버깅도 편함").

### 5. 리프(Roblox 프로퍼티) 바인딩 — Source 직접 바인딩도 정상 경로,
"좁은 예외"라는 표현이 오해를 유발해 정정함(2026-08-09 열한 번째 세션)

**[정정] 이전 서술("Source는 리프 바인딩용 프리미티브가 아니라 좁은
용도의 예외")은 부정확했음 — 사용자가 직접 반례를 제시:
`local a = Source(true); Frame { Visible = a }; a:Set(false)`처럼
Source를 리프 프로퍼티에 곧바로 물리는 건 **막힐 이유가 전혀 없고
흔한 정상 패턴**(단순 토글/가시성 같은 값은 오히려 이 모양이 자연스러움)
— 4번 절이 이미 확정해둔 "Source가 State를 구조적으로 만족해서
핸들러가 서브타입 호환으로 자동 통과시킨다"가 정확히 이 케이스를
커버함, 별도 제약이 있었던 적이 없음.**

바로잡은 원칙: **"State가 일반 경로"라는 말은 Source를 못 쓴다는 뜻이
아니라, 리프에 물리는 값이 "여러 소스에서 파생된 계산 결과"인 경우
(`:With`/`:Compute`로 조합된 값)엔 그 결과가 State이지 Source가 아니기
때문에 자연히 State가 더 자주 보인다는, **결과의 통계적 경향에 대한
서술**일 뿐이다.** 원본 값 하나를 그대로(가공 없이) 리프에 물리는
경우(`Visible`/`Enabled`류 단순 불리언 토글이 가장 흔한 예)엔 Source
직접 바인딩이 오히려 첫 번째로 권할 만한 관용구 — `isEnabled`처럼
여러 조건에 영향받는(파생된) 값만 원천적으로 Source가 될 수 없는
경우(그런 값은 애초에 `:Compute`로 만들어진 State일 수밖에 없어서),
그 경우에 한해 "State/콜백 패턴이 기본"이라는 4번 절 서술은 그대로
유효.

## 프레임워크 사례 조사 (2026-08-04, modifier/Ref 경계 통과 문제 관련)

병렬 리서치로 4개 소스(Compose 공식 문서, Fusion/Vide 소스, quad v1 +
PA artworks)를 확인. **결론: 조사한 어떤 선례도 "컴포넌트 경계에서 modifier/Ref
전달" 문제를 완전히 풀어놓지 않음** — 심지어 quad가 이미 많이 참고한 Fusion도
multi-root를 지원은 하지만 그 상태에서 외부 ref/props를 특정 root에 연결하는
관례는 자체 문서에도 없음.

### Compose의 Modifier는 애초에 flat property bag이 아님 — 순서 의존적 wrapper 체인

`modifier-plan.md`가 이미 확정한 "필드 단위 flatten, 나중 게 이김" 모델과
Compose의 실제 메커니즘은 근본적으로 다른 종류임. Compose `Modifier`는
`CombinedModifier`(2-노드 연결 리스트)로 순서대로 이어붙는 wrapper 체인 —
`Modifier.padding(16.dp).clickable(onClick)` vs
`Modifier.clickable(onClick).padding(16.dp)`가 실제로 다르게 동작함(패딩
영역이 클릭 가능한지 여부가 순서에 따라 갈림, 공식 문서 예시).
`.then()`/`+`는 "같은 프로퍼티면 덮어쓰기"가 아니라 순수 **연결(concatenation)**.
→ **quad의 "필드명 기준 last-wins" 모델은 Compose를 그대로 벤치마킹한 게
아니라 독자 설계임을 확인** — Compose와의 유사성은 "관례로 경계를 넘긴다"는
아이디어 수준에서만 성립, merge 의미론까지 가져올 근거는 아님.

공식 API 가이드라인(`compose-api-guidelines.md`,
`compose-component-api-guidelines.md`, `mrmans0n/compose-rules` 린트)이
명시하는 규칙:
- `modifier` 파라미터는 이름 고정, 타입 `Modifier`, 기본값 `Modifier`, 첫 번째
  optional 파라미터여야 함.
- 받은 modifier는 컴포저블이 만드는 루트 레이아웃 노드에 **체인의 맨 앞**에
  적용, 필요하면 뒤쪽에 이어붙이는 것만 허용(앞에 붙이는 것 금지).
- 같은 modifier 인스턴스를 여러 노드에 나눠 쓰지 말 것(단일 소비 전제).

**Multi-root(루트가 여럿인 컴포저블)에 대한 공식 답은 없음** — 오히려
가이드라인은 `CheckboxRow(rowModifier, checkboxModifier)`처럼 파트별
modifier 파라미터를 두는 패턴을 명시적으로 **반례(DON'T)**로 제시하며
"modifier는 컴포넌트 자체의 외부 동작을 위한 것이지 하위 파츠용이 아님,
대신 슬롯(자식 컴포저블 람다)으로 만들어라"라고 함. 즉 Compose는 이 문제를
**풀지 않고 애초에 안 생기게 architecture로 피함**(multi-root 자체를 권장하지
않고 slot 패턴으로 유도).

### Fusion — modifier 개념 자체가 없음, multi-root는 있지만 ref 전달 관례 없음

- `merge.luau`(`src/Utility/merge.luau:13-33`)는 scope 메소드 테이블 병합용이지
  props 병합용이 아님 — quad Modifier에 대응하는 게 Fusion엔 없음.
- prop 전달 관례는 전부 **named table**(`props.Layout.Size`,
  `props[Children]`) — 배열 아이템으로 뭔가를 넘기는 관례 자체가 없음.
  Children도 예약된 `[Children]` 키로 감, 포지셔널 아님.
- `New()`/`Hydrate()`는 raw Instance 리턴(quad와 동일 지점).
- **Multi-root 컴포넌트는 실제로 지원**(`docs/tutorials/best-practices/
  instance-handling.md:17-61` — "Instance 배열 리턴, 여러 값 리턴 대신 배열로
  감싸라"), 하지만 **외부에서 넘어온 ref/props를 그중 특정 root에 연결하는
  예시나 관례는 문서에 없음** — quad가 지금 맞닥뜨린 것과 완전히 같은 질문이
  Fusion 자체 문서에서도 답이 안 나가 있음.

### Vide — modifier도, 배열 기반 전달 관례도, multi-root 사례도 전무

`src/`/`docs/` 전체에 `modifier`/`merge`/`combine`/`spread` 매칭 0건. 모든
컴포넌트 예제가 named+typed `props` 테이블을 필드별로 직접 옮겨씀. 인스턴스
생성자는 raw Instance 리턴. multi-root 예제/개념 자체가 문서에 존재하지 않음.

### quad v1 — 배열 아이템 구분은 항상 런타임 `__type` 태그로 함

`ProcessQuadProperty`(`class.lua:134-213`)는 배열 위치의 모든 아이템을
`__type`으로 검사(`quad_linker`/`quad_register`/`quad_style` 중 하나면 그
용도로, 아니면 무조건 자식으로 마운트) — v2의 "리프 레벨에서 타입으로
Modifier/Ref/자식을 구분"이 이미 v1의 유일한 해법이었던 패턴 그대로임을
확인. 단 v1도 multi-root 사례가 전혀 없어서, "컴포넌트가 여러 루트를 반환할
때"는 v1도 답을 준 적이 없음. PA artworks에도 컴포넌트 추상화/multi-root
사례 없음(재사용 가능한 컴포넌트 함수 자체가 아직 코드로 존재하지 않음).

### 종합

| | Modifier-equiv 있음? | 전달 관례 | multi-root 지원 | multi-root 시 ref/modifier 전달 관례 |
|---|---|---|---|---|
| Compose | O(순서의존 체인) | named 파라미터 강제(린트) | 사실상 비권장, slot으로 유도 | 없음(애초에 안 만듦) |
| Fusion | X | named table | O(배열 리턴) | **없음(미해결로 확인)** |
| Vide | X | named table | 사례 없음 | 해당 없음 |
| quad v1 | X(런타임 태그로 대체) | 태그 기반 배열 아이템 | 없음 | 없음 |

시사점: (1) "배열 아이템을 타입으로 구분"은 quad v1 고유 패턴이자 quad-v2
리프 레벨이 이미 계승한 것 — 그런데 이 문서 위쪽에서 지적했듯 컴포넌트
함수 경계에서는 타입 스니핑을 자동으로 해줄 디스패처가 없어서 저작자가 직접
루프를 돌려야 함(v1도 이 경계에서 실제로 쓰인 적이 없어 검증 안 된 채로
남음). (2) named-key 전달(Fusion/Vide/Compose 공통)이 "함수 호출만으로
경계를 넘는" 상황에서 유일하게 실제로 쓰이고 있는 관례. (3) multi-root +
외부 ref/modifier 전달은 **조사한 4개 선례 중 어느 것도 실제로 풀어놓지
않음** — Compose는 회피, Fusion은 미해결로 방치, Vide/v1은 애초에 안 함.
즉 이 지점은 quad가 진짜 새로 설계해야 하는 부분이지, 어딘가에 있는 답을
못 찾은 게 아님.

## 최종 결론: 컴포넌트 경계 modifier/Ref 전달 (2026-08-04, 확정)

### 1. Named parameter로 경계를 넘김 — 리프 레벨과는 다른 계약

컴포넌트 함수(`function(props) return Frame{...} end`)는 `Frame{...}`처럼
배열 아이템 + 런타임 타입 스니핑으로 modifier/Ref를 받지 않음 — 함수 호출로
경계를 넘는 순간부터는 자동으로 타입을 스니핑해줄 디스패처가 없기 때문(리프
레벨의 `ProcessQuadProperty`류 디스패치는 `Frame{...}` 호출 내부에서만
동작하고 컴포넌트 함수 몸통엔 적용되지 않음). 대신 caller는 named key(가칭
`props.Modifier`/`props.Ref`)로 넘기고, 컴포넌트 저작자가 자기 코드 안에서
명시적으로 원하는 내부 `Frame{...}` 호출의 배열 자리에 다시 꽂아넣음
(`return Frame { props.Modifier, props.Ref, ... }`) — **사용자 확정**
("결과적으로 함수 구현에선 타입을 멀쩡히 지정하는게 더 중요하니 네임드가
맞는듯").

**⚠️ 필수 관용구 — `props.Modifier or None`/`props.Ref or None`으로
써야 함, 맨 리터럴로 꽂으면 안 됨(2026-08-07 열 번째 세션, `nil`-hole
버그 실측 후 확정).** caller가 `props.Modifier`/`props.Ref`를 안 넘기면
`nil`인데, `{nil, props.Ref, child}`처럼 Lua 배열 리터럴에 `nil`이 그대로
들어가면 그 순간 테이블의 배열 파트 전체가 순회 순서 보장을 잃을 위험이
있음(`base/ref-plan.md`의 PreRef pre-pass 절이 다루는 것과 같은
부류의 문제 — Luau REPL 실측으로 확인된 실제 버그, 국소적 피해가 아니라
테이블 전체에 영향. **[주의]** 순서가 안 중요한 Ref 자신의 콜백/대기자
집합은 반대로 `nil` 소진이 맞다는 정정이 따로 있음(**[2026-08-24 어휘 정정]**
한때 "배열"이라 적었으나 6라운드 `H-7`로 `.Callbacks`는 **해시맵 셋**이 됐다 —
`t[k] = nil` 해제라 결론은 같고 이름만 바뀌었다) — 여기서 다루는 건
컴포넌트가 넘기는 **리터럴 children 배열**(순서가 중요한 배열)이라
그 정정과 무관하고 `None` 관용구가 계속 맞음).
그래서 **컴포넌트 저작자는 항상 `or None`으로 감싸서 넘겨야 함**:
```luau
return Frame { props.Modifier or None, props.Ref or None, child }
```
- **왜 `Modifier()`(빈 modifier 생성)가 아니라 `None`인가**: 별도 할당이
  필요 없고, 기존 메커니즘을 그대로 재사용함 — `flatten` 단계는 애초에
  `isModifier(v)`가 거짓인 값은 그냥 건드리지 않고 통과시키므로
  (`None`은 Modifier가 아니라서 자동으로 이 경로), `props.Modifier or
  None`이 최종적으로 배열 파트에 `None`인 채로 남으면 **그 자리는 기여
  0으로 정상 처리된다** — 새 특수 케이스 코드가 하나도 안 늘어남.
  **[근거 정정, 2026-08-18 구현 전 QA]** 예전엔 근거를 "두 패스 루프
  자신의 array-part `None`-스킵 규칙"으로 적었는데, 그 스킵 규칙 자체가
  폐기됐다(반응형 값이 내놓는 `None`은 어차피 `Dispatch.process`에
  도착하므로 — `base/dispatch-core-plan.md`의 "`None` 센티널" 절). 지금은
  `NoneHandler`가 매치돼 `nil`로 재귀하고 `NilHandler`가 `setLength(0)`/
  `setOffsetSource(None)`을 등록한다. **결론(`or None`을 쓰는 것)은 안
  바뀜** — 여전히 "아무것도 안 놓은 것과 같은 효과"이고, 오히려 리터럴
  경로와 반응형 경로가 같은 핸들러로 수렴해 더 단순해졌다.
- 이 관용구는 컴포넌트 저작자가 **직접 챙겨야 하는 규율**(base가 강제로
  검증해줄 방법은 없음, Lua는 이런 걸 린트로만 잡을 수 있음) — quad
  문서화(초심자 가이드/`props.Modifier`/`props.Ref` 절)에 필수 패턴으로
  명시할 것, `research/documentation-content-map.md`에 반영 필요.

Compose(named `modifier` 파라미터 강제, 린트로 감시)와
Fusion/Vide(named prop 전달, `[Children]`류 예약 키)가 서로 다른 이유로 전부
같은 결론에 도달한 유일한 실용적 패턴 — quad가 발명한 게 아니라 선례가
수렴하는 지점(위 "프레임워크 사례 조사" 절 참고).

### 2. "다중 루트로 반환" 자체를 컴포넌트 개념에서 제거

기존에 "컴포넌트가 여러 루트를 반환하면 모호해짐"이라던 프레이밍이 서로
다른 두 가지를 하나로 섞은 것이었음이 드러나 재정리:

- **정적으로 고정된 여러 형제 Instance를 한 함수 호출이 그대로 반환**(React
  Fragment류) — **불필요로 폐기**. 근거 셋: (1) Luau가 tail position 밖에서
  다중 리턴을 지원 안 함 — `return a, b`는 `Frame{ MyComp{...}, other }`처럼
  배열 중간에 놓이는 순간 첫 값만 살아남으므로, 언어 차원에서 이 패턴이
  애초에 자연스럽게 지원되지 않음(**사용자 확인**). (2) 필요하면 호출부에서
  그냥 여러 컴포넌트를 나란히 쓰면 됨(`Frame{ IconA{...}, LabelB{...} }`) —
  한 컴포넌트 호출이 몰래 여러 형제를 뿜어낼 이유가 없음. (3) 프레임워크
  조사에서도 진짜 수요가 있어 제대로 지원된 사례가 없음(Fusion은 "된다"고만
  하고 ref 연결 관례는 미해결로 방치, Compose는 아예 안 만들도록 가이드) —
  어려워서 방치된 게 아니라 실제 수요가 없어서 아무도 안 만든 것 —
  **사용자 확정**("그럴 필요가 있나 싶네... 애초에 다중 리턴이 될 이유가
  없는듯").
- **컴포넌트가 Slot을 반환**(개수가 가변적인 자식 묶음을 부모의 형제 레벨에
  래퍼 없이 그대로 펼침 — 예: `ItemList{items=state}`가 `UIListLayout` 밑에서
  래퍼 Frame 없이 `Header{}`/`Footer{}`와 같은 레벨로 항목들을 끼워넣는 경우)
  — **이미 있는 별개 메커니즘**(`base/slot-plan.md`), 새 설계 불필요. Slot은
  단일 Instance 정체성이 없으므로, 이런 컴포넌트는 애초에 `Modifier`/`Ref`
  파라미터를 선언하지 않으면 그만 — 타입 시그니처 자체가 "나는 단일 대상에게
  적용할 modifier/Ref가 없다"를 표현. 별도 조율 메커니즘 불필요 — **사용자
  확정**("불가능하진 않고 기술적으로도 충분히 되는 일... 엄청 집중해야할
  일은 아니지 않을까"). **[재확인, 2026-08-09 열한 번째 세션]** 새 배선
  없이 그대로 작동함을 재확인 — `Frame { Comp{} }`에서 `Comp`가 `Slot`을
  반환하면, 그 반환값이 그냥 children 배열의 한 항목(값)이 되고
  `Dispatch/Slot.luau`의 기존 Slot 매치 핸들러가 평소처럼 처리(값이
  컴포넌트 호출로 왔든 리터럴로 직접 놓였든 디스패치 입장에선 구분이
  없음) — 이 경로 전용 특수 취급이 전혀 필요 없다는 뜻.

이 정리로 원래의 "모호해지는 케이스"는 사라짐: 컴포넌트가 단일 root를 갖는
한 named parameter로 명확히 전달되고, 단일 root가 없는 컴포넌트(Slot 반환)는
애초에 그 파라미터를 안 받으므로 모호함이 생길 지점 자체가 없음. 반환값에
"사후적으로" 뭔가를 꽂아넣는다는 그림 자체가 틀렸던 것 — forwarding은 항상
컴포넌트가 반환하기 *전에*, 저작자 코드 안에서 일어나는 일이라 어느 root로
가야 하는지는 저작자가 자기 코드에 뭐라고 쓰느냐로 완전히 결정됨(자동 전파가
없기 때문에 성립하는 단순함).

### 3. 여러 modifier를 하나로 합치는 공개 유틸 필요 — `Modifier.Overridden`(2026-08-07 다섯 번째 세션에서 `Merge`→`Override`로 개명, 동작 확정; 2026-08-08 세션에서 `Overridden`으로 이름 확정)

caller가 named parameter 하나에 여러 modifier를 몰아넣고 싶을 때
(`Frame{modifier1, modifier2}`의 컴포넌트판)를 위해, 기존 flatten 규칙(배열
순서상 나중 것이 필드 단위로 이김, `modifier-plan.md` 2번)을 그대로 재사용하는
결합 함수를 공개 API로 노출: `Modifier.Overridden(mod1, mod2, ...) -> Modifier`.
새 병합 규칙이 아니라 이미 확정된 flatten을 함수로 한 번 더 꺼내 쓸 수 있게
하는 것뿐 — **사용자 요청**("modifier를 합칠 방법도 존재한다면 좋을것
같아"). `MyComp { Modifier = Modifier.Overridden(theme, override) }` → 컴포넌트
내부는 항상 이미 합쳐진 단일 값만 받으므로 컴포넌트 저작자가 배열 처리를
신경 쓸 필요 없음. Ref는 필드 충돌 개념이 없어 이 문제 자체가 없음(여러
Ref를 받으면 그냥 전부 실행하면 됨 — Ref 콜백 리스트는 애초에 여러 등록을
누적하도록 설계돼 있음, `ref-plan.md`의 Ref 콜백/대기자 절) — 별도
결합 유틸 불필요. **정확한 동작(baked 값 교체 경고, 순서 의존성, `Apply`와의
역할 구분, `:Peek`/`isState`)은 `base/modifier-plan.md` 9번 절이 최종
소스** — `Merge`로 전부 대체해 `Apply`만 강제하는 방안도 이번에 검토했으나,
이 3번 절에서 확정한 실사용 니즈(단일 named parameter 슬롯에 독립적으로
만들어진 modifier 값들을 밀어넣는 경우)를 못 풀어서 기각됨.

## 남은 열린 질문 (`.claude/question.md`에도 취합, 전부 후순위 — 이름만 남음)

- **정확한 API 이름**: `Component`(플레인 함수 규약이라 별도 래퍼가 필요한지
  자체도 불확실 — 아마 불필요), `Source`/`State` 독립 생성자·타입 이름,
  컴포넌트 경계용 `props.Modifier`/`props.Ref` 필드명은 전부 가칭
  (`Modifier.Overridden`은 2026-08-08 세션에서 이름 확정, 이 목록에서
  빠짐). (`GetSource` 계열 접근자는 위 3번 정정으로 아예
  불필요해짐 — `store.key`가 직접 Source를 반환하므로 별도 접근자 자체가
  없음. **[2026-08-25]** 단 **동적 키** 전용 창구 `store:Of<<T>>(name)`은
  있다 — 옛 이름은 `GetDynamic`이었다.) `base/bind-system-plan.md`의 "남은 열린 질문" 절(정확한 함수/
  생성자 이름 미정)과 같은 급의 후순위 항목 — 구현 단계에서 다른
  이름들과 함께 확정.
- **`quad2-try`는 확인 불필요로 재확인** — 진행이 중단된 상태라 이 논의와
  무관.
