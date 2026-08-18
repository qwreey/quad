# 구현 전 QA **1라운드** — 사용자 심사에서 "아니오"가 나온 항목

**상태**: **1라운드 완료 + `base/` 반영 완료(2026-08-18)**. 이 파일은
`.claude/qa-request/`에 라운드별로 쌓인다 — **2라운드는 새 파일**
(`pre-implementation-qa-round2.md`)로 만들 것이고, 이 문서를 이어 쓰지 않는다.
2라운드 대상은 맨 아래 "진행 로그" 절의 "아직 안 본 것" 목록.

**1라운드 범위**(2026-08-18 세션에 시작). `.claude/base/` 확정 문서를 의존성
순서로 훑으며 **표면 타입계약 / 내부 구현 메커니즘 / 동작 원리·불변식** 세
층위로 "예가 나와야 정상인 주장"을 사용자에게 확인받는 작업의 산출물.

**이 문서의 용도**: 사용자가 "아니오" 또는 "부분적으로 틀림"으로 판정한
항목만 모은다. **[2026-08-18 갱신] 반영 완료 — 이 문서는 이제 "무엇이 왜
틀렸었나"의 근거 기록이고, 지금 유효한 설계는 항상 `base/`가 소스다.**
같은 날 세션에서 아래 항목 전부를 `base/`(+`ROADMAP.md`/`question.md`/
`archive/`)에 반영했고, 반영 과정에서 판단이 갈리던 네 건(SL-3의 `PopOnly`,
D-7의 재역전 여부, N-4의 `NoneHandler`/`NilHandler` 역할 분담, ST-2의 동적
키 경로)은 그 자리에서 사용자에게 물어 확정했다 — 그 답변도 각 항목에
반영돼 있다.

**아직 안 닫힌 것**(결론 전에 해당 마일스톤 착수 금지)은 `question.md` 3번과
`.claude/todos.md` 00번이 소스 — 여기서 다시 나열하지 않는다.

**표기**: `X-N`의 `X`는 문서 코드(A=architecture, S=source-state, …),
`N`은 그 문서 안 질문 순번. 사용자 답변 원문은 그대로 인용한다(`conventions.md`의
"사용자 발언을 근거로 인용할 때" 관례).

**진행 현황의 소스는 이 문서 맨 아래 "진행 로그" 절** — 어느 문서까지
심사했는지는 거기가 소스이고, 다른 곳에 개수를 적지 않는다.

## 먼저 볼 것 — 파급이 큰 순서

목록 전체를 순서대로 읽기 전에, **다른 항목의 전제가 되거나 코드가 반대로
도는** 것부터 보는 게 효율적이다. 아래 분류는 심사한 에이전트의 판단이고
확정이 아니다 — 회신 시 우선순위가 다르면 그대로 알려주면 된다.

**1. 구현하면 반대로 도는 것**
- `S-1` — `canBound` 게이트 호출부 반전. 지금 문서대로 짜면 **정상 첫
  바인드가 전부 에러나고 이중 바인드는 통과**한다. `lifecycle-pattern.md`가
  진원지이고 `source-state-plan.md`/`ref-plan.md`가 전부 이걸 인용한다.
- `RE-1` — gcconn/gchold를 `SetStrong`으로 적은 두 곳. 그대로 구현하면 같은
  문서가 경고하는 **두-`Relate` 상호 강참조 누수**에 정확히 걸린다.

**2. 설계 자체가 바뀌는 것**
- `RF-4` + `N-4` — `drive`의 `None` 스킵 제거, `NoneHandler`가 `k=number`를
  직접 처리, `NilHandler` 신설. `D-6`의 열린 갭이 여기서 닫힌다.
- `EV-1` — 이벤트 disconnect 센티널 `false` → `None`/`nil`.
- `BS-2` — "이벤트 콜백은 타입 검증 못 한다"가 거짓. `onchange-plan.md`의
  근거까지 같이 무너진다.
- `R-1` — `Ref`의 내부 구조(`.Callbacks` 분리 + `.Value`를 평범한 필드로).
- `SL-3` — `:List` reconcile의 `nil` 리턴을 파괴로 되돌릴지 + `PopOnly`.

**3. 아직 답이 없는 것 (착수 전 결론 필요)**
- `S-12` — 중간 State가 GC되는지 **미검증**. M3 착수 전 실측 필요.
- `AT-1` — `Frame{a, a}`(같은 그룹 객체 이중 배치)를 UB로 둘지 error로 잡을지.
- `D-7` — base Fallback Handler 등록 주체가 다시 뒤집힐 가능성.

**4. 이름·표면 확정 (같이 처리하면 효율적)**
- `N-8` — **`DI` → `D` 리네임 확정**(2026-08-18, `question.md` 1순위였던
  항목). 라이브 문서 19개 파일에 걸쳐 있고, **헤딩 1개와 그걸 절 인용하는
  곳 1개가 짝으로 묶여** 있어 한쪽만 고치면 `doc-check.py` ERROR가 난다.
  반영 대상 전수 목록이 그 항목에 표로 들어있다.
- `N-9` — **`New` 커링 + `D`는 전량 코드 생성** (2026-08-18에 열린 항목 전부 확정됨).
  N-8과 **같은 줄들을 건드리므로 한 번에 처리할 것**(`architecture.md`
  소스 트리 주석, `ROADMAP.md` 체크박스). **`BS-2`와는 같은 문제의 양면**이라
  (인덱싱으로는 이벤트 콜백 타입이 안 나온다는 것) 반드시 묶어서 볼 것.
  부수적으로 `bind-system-plan.md`의 **PA님 시그니처 인용**과 **"알려진/모르는
  타입을 전부 커버"** 서술 두 곳이 더 이상 정확하지 않게 됨.

**5. 나머지** — `A-3`, `ST-2`, `D-1`, `D-5`, `M-3`, `R-3`, `B-1`, `SL-1`,
`E-2`, 그리고 `N-1`~`N-7`(신규 요구사항).

---

## A. `base/architecture.md`

### A-3 — `New()` 도입 시 "자동으로 테이블별 스코핑"된다는 서술

- **판정**: 부분적으로 틀림 (사용자 답변: "이해가 잘 안가나, …")
- **문서 위치**: `base/architecture.md`의 "확정된 결정" 13번 항목
  (`base/dispatch-core-plan.md`의 "Dispatch는 프리미티브가 아니다" 절도
  같은 주장을 근거로 인용함 — 같이 확인 필요).
- **문서가 주장하는 것**: `New()`가 생기면 매번 새 `BaseModule` 테이블을
  만들어 팩토리로 채우는 것뿐이고, 그러면 Dispatch 핸들러 레지스트리와
  `_initializedBy` 마커 등 지금 module-level state로 사는 모든 것이
  **자동으로** 테이블별 스코핑된다.
- **사용자 답변 원문**:
  > 이해가 잘 안가나, 모듈이 하나의 인스턴스(dispatch 레지스트리 하나,
  > canExecute 등 계약 필드 하나) 만 가지고 있다면 예. 단, 나중에 모듈이
  > 여러 인스턴스를 지원해, quad-roblox, quad-mock 등을 같이 굴리고 싶어지는
  > 시점이 올 때는 v1 처럼 Init() 수행 가능하도록 두는데, require 를 감싸지는
  > 않고 단순히 InitModule(module) 등을 받도록 각 코드들을 약간 고쳐서 이것을
  > 해결함. Quad() 하면 새로운 quad 가 나오는 식. 단 지금은 단순 싱글톤으로
  > 구현해 Quad() 안하고 Quad.Dispatch 접근 가능.
- **어긋나는 지점**: 문서는 "코드 변경 없이 자동으로 스코핑됨"을 주장하지만,
  사용자는 **"각 코드들을 약간 고쳐서"** 해결한다고 봄 — 즉 module-level
  state를 참조하는 코드들이 `InitModule(module)` 같은 걸 받도록 손을 대야
  한다는 것. 또 미래 API 이름도 문서의 `New()`가 아니라 **`Quad()`** 로
  언급됨(현재는 싱글톤이라 `Quad()` 없이 `Quad.Dispatch` 직접 접근).
- **파급**: 실제 코드 배치에 영향 — module-level upvalue로 레지스트리를 잡아두면
  나중 다중 인스턴스화 때 전면 수정이 되므로, 지금부터 그 참조 형태를
  정해둘지 여부가 M0 스캐폴딩 결정이 됨.
- **⚠️ [후속 정정, 2026-08-19] 위 "어긋나는 지점"의 이름 해석이 부정확했음
  — `New()`를 통째로 `Quad()`로 바꾸는 건 사용자 의도가 아니었다.** 이
  판정을 그대로 `base/architecture.md`에 반영했다가(2026-08-18) 여러 파일에
  `New()`→`Quad()` 전면 치환이 퍼졌었는데, 사용자가 직접 바로잡음 —
  *"New 와 Quad 가 이름 모순은 아닐꺼야... Quad 는 기본적으로 생성된걸
  리턴하긴 하는데, Quad.New() 도 제공하는거 어떻냐는거였음, 즉 New() 는
  존재하고 기본 리턴은 New() 해서 주는건데, 리턴 안에 New 필드가 있고
  그 함수를 쓰면 하나의 새로운 Quad 네임스페이스가 만들어지는식."*
  실제 의미: `Quad`(`require`의 반환값)는 이미 만들어진 기본 인스턴스이고,
  `New()`는 그 안에 있는 **명시적 opt-in 필드**(호출하면 별도의 새
  네임스페이스 생성) — "그냥 `Quad()`를 부르면 매번 새 인스턴스"가 아님.
  컴포넌트를 여러 모듈로 쪼갠 앱에서 각자 `Quad()`를 불러 인스턴스를
  "얻어야" 하는 모델이면 실수로 서로 다른 인스턴스가 생겨버리는 게
  진짜 문제였음. 지금 유효한 서술은 `base/architecture.md` "확정된 결정"
  13번의 재정정이 소스.

---

## S. `base/source-state-plan.md`

### S-1 — `canBound` 게이트 호출부가 뒤집혀 있음 ⚠️ 파급 큼

- **판정**: 아니오 — **호출부가 잘못됨**(이름 `canBound`는 맞음).
- **문서 위치**: `base/source-state-plan.md`의 "이중 바인딩 금지" 절의 게이트
  스케치와, 같은 문서 "`bindLifetime`이 이 게이트의 두 번째" 절의
  `bindLifetime` 의사코드. **`base/lifecycle-pattern.md`의 "`canBound` vs
  `canExecute`" 절이 이 판정의 소스라고 선언돼 있으므로 거기가 진짜
  진원지** — 정정 시 그 문서부터 볼 것.
- **문서가 주장하는 것**:
  ```lua
  if canBound(self) then
    error("이미 :Subscribe()로 전역 바인딩된 값" / "이미 다른 Instance에 바인딩된 값")
  end
  ```
  즉 `canBound == true`가 "이미 살아있게 묶여 있다 = 더 못 묶는다"는 뜻으로
  쓰이고 있음.
- **사용자 판정**: 이름이 아니라 **호출부가 잘못됐다** — `canBound`는 이름
  그대로 "지금 묶을 수 있는가"(true = 묶어도 됨)여야 하고, 게이트는
  `if not canBound(value) then error(...) end` 형태가 돼야 한다.
- **연쇄로 같이 무너지는 서술 (정정 시 반드시 함께 볼 것)**:
  1. **"`canBound`와 `canExecute`는 판정 로직이 같아서 값이 항상 같다"** —
     `base/source-state-plan.md` "이중 바인딩 금지" 절과
     `base/lifecycle-pattern.md`가 둘 다 "비공개 헬퍼 `isBoundAlive`를 그대로
     부른다"고 서술함. 그런데 `canExecute`는 true=살아있음이고 `canBound`는
     true=아직 안 묶임이므로, 올바른 관계는 **동치가 아니라 부정**
     (`canBound(v) == not isBoundAlive(v)`)이다. "값은 항상 같지만 호출부의
     질문이 달라 이름만 분리했다"는 근거 서술 자체가 성립하지 않게 됨 —
     실제로는 **반대 방향을 묻는 두 predicate**임.
  2. **`bindLifetime` 의사코드의 `if canBound(value) then error("이미
     바인딩된 값") end`** — 같은 이유로 뒤집혀 있음. 이 줄엔
     `[정정, 2026-08-14 열두 번째 세션]` 배너까지 붙어 "게이트는 canBound가
     맞다"고 못박아 뒀는데, 정작 방향이 틀린 채로 확정된 것.
  3. **"죽은 바인딩의 재사용은 허용 — `canBound`가 거짓이라 게이트를
     통과함"** — 방향이 뒤집히면 이 문장도 뒤집혀야 함(죽은 바인딩은
     `canBound`가 **참**이라 통과).
- **파급**: M8(`Ref`/`PreRef`/`PostRef`)과 M3(Observer/Effect) 양쪽의 진입
  게이트가 전부 이 predicate를 쓴다. 지금 문서대로 구현하면 **정상적인 첫
  바인드가 전부 에러나고 이중 바인드는 무사통과**하는, 정확히 반대로 도는
  게이트가 된다.
- **정정해야 할 정확한 위치 (`base/lifecycle-pattern.md` 확인 후 확정)**:
  1. **`canBound`의 구현 자체** — `(1)` 코드 블록:
     ```lua
     function canBound(value)
         return isBoundAlive(value)   -- ← 이름대로면 not isBoundAlive(value) 여야 함
     end
     ```
     `canExecute`는 `return isBoundAlive(value)`가 맞으므로, **둘은 서로의
     부정**이 된다. 같은 블록의 주석("어느 쪽 진입점에서 물어도 항상 같은
     값이라")과 `(3)` 절의 "오늘 두 문맥의 판정값은 우연히 같다"도 함께
     틀리게 됨.
  2. **`bindLifetime`의 가드** — `if canBound(value) then error(...)`
     (`(1)` 코드 블록).
  3. **`Observer:Subscribe()`의 가드** — `if canBound(self) then error(...)`
     (`(2)` 코드 블록).
  4. **`(3)` 절 끝의 "죽은 바인딩 재사용" 서술** — "`canBound`가 **거짓**이라
     게이트를 통과함" → 방향이 뒤집히면 "**참**이라 통과함"이 됨.
  5. `base/source-state-plan.md`의 "이중 바인딩 금지" 절 게이트 스케치와
     `bindLifetime` 의사코드(앞서 적은 것).
  6. `base/ref-plan.md`의 "이중 배치 방지" 절 — 같은 게이트를 쓴다고
     선언돼 있으므로 같은 방향 오류가 있는지 확인 필요.
- **⚠️ 함께 재검토할 것**: 이 정정이 들어가면 `(3)` 절이 두 이름을 나눈
  근거였던 *"판정 로직은 하나(`isBoundAlive`)를 공유하고 값도 항상 같다"*가
  깨진다. **부정 관계라면 오히려 이름 분리의 명분은 더 강해지지만**, 그
  절의 서술은 통째로 다시 써야 함.

### S-12 — 중간 State가 GC되지 않고 살아남는지 미검증 ⚠️ 미해결

- **판정**: 결론 보류 — 사용자가 **검증 필요**로 지목(틀렸다고 확정한 게
  아니라, 문서가 이 케이스를 다룬 적이 없음).
- **문서 위치**: `base/source-state-plan.md`의 "`state:Observer(fn)`" 절
  (구독자를 weak로 담는 근거 서술), 같은 문서 "왜 State 체인을 Modifier처럼
  플래튼하지 않는가" 절("각 노드가 자기 구독자 목록 + 자기 캐시만 가지면
  된다"), `base/lifecycle-pattern.md`(gchold/gcconn).
- **사용자 답변 원문**:
  > 확인해봐야 하는게 State -> State -> State -> Observer Leaf Bind 에서 중간
  > State 는 참조되지 않아도 사라지지 않음이 명확해야함. 물론 compute 등의
  > callback 상 가져서 안전할 수 있지만, With 등이 있는 경우 parent 와 연결된
  > 상대를 자기 자신에 가지고 있어야 할것임. 이게 되는지는 더 알아봐야할
  > 필요가 있음.
- **문제의 구조**: 확정된 두 서술을 겹치면 체인이 끊길 수 있음 —
  - State는 자기 **구독자(하류)를 weak로** 담는다(S-12에서 확인된 서술).
  - Observer는 `gchold`(leaf) 또는 전역 레지스트리가 살려준다.
  - 그러면 `A → B → C → Observer` 체인에서 **중간 노드 `B`/`C`를 강하게
    붙잡는 주체가 문서 어디에도 명시돼 있지 않다.** 아무도 `B`/`C`를 로컬
    변수로 안 들고 있으면(체이닝 한 줄로 쓰는 흔한 형태), 하류 weak 링크만
    으로는 생존이 보장되지 않아 중간 State가 수거되고 전파가 조용히 끊길 수
    있음.
- **사용자가 지목한 해법 방향**: 각 노드가 **자기 parent(상류)를 강참조로
  들고 있어야** 한다 — `:Compute`는 콜백 클로저가 상류를 캡처해 우연히
  안전할 수 있지만, **`:With`가 만드는 pass-through 노드는 계산 함수가
  없어서** 그런 우연한 캡처가 없다. 즉 "구독 엣지는 하류로 weak, 상류로
  strong"이라는 방향성이 명시돼야 함.
- **해야 할 일**: (a) `base/source-state-plan.md`에 이 방향성(상류 strong /
  하류 weak)을 불변식으로 명문화할지 결정, (b) `luau-test`에 실측 스파이크
  추가(`07`이 연쇄 GC를 이미 다루므로 그 옆에). **미검증 상태로 M3에 착수하면
  안 되는 항목.**

---

## ST. `base/store-plan.md`

### ST-2 — `store "key"` 문자열 커링은 **폐기됐는데** 문서엔 "동적 키 폴백으로 유지"로 남아 있음

- **판정**: 아니오 — 틀림. (사용자 재확인 완료)
- **사용자 답변 원문**:
  > store "a" 식으로 문자열 호출하는것 또한 기각된 바임. 저러면 "a" 가 string
  > 으로 들어가서, Source<T> 의 타입을 모르기도 하고, 우린 더이상 필요하지
  > 않게 된 요소임.
- **문서가 주장하는 것**: dot-access를 1급으로 확정하면서 `store "key"`는
  폐기가 아니라 **동적 키용 미타입 폴백(`Source<any>`)으로 격하해 유지**한다.
- **실제로 맞는 것**: 문자열 커링 호출 자체가 **기각**. 근거는 (a) `"a"`가
  그냥 `string`으로 들어가 `Source<T>`의 `T`를 알 수 없고, (b) dot-access +
  `type function` 타이핑(ST-4)이 자리잡아 **더 이상 필요 없는 요소**가 됨.
- **정정해야 할 위치(grep 결과 — 전수)**:
  - `base/store-plan.md:119` — "…`store "key"`(문자열 커링)로 `state<T>`를
    오버로드 함수 타입으로 정확히 추론하려는 시도는 포기하고…"
  - `base/store-plan.md:128` — "`store "key"` 문자열 커링은 동적 키가 필요할
    때 쓰는 미타입(`Source<any>`) 폴백으로 격하."
  - `base/store-plan.md` "남는 것" 문단 — "`myStore "key"`(문자열 커링)는 …
    그대로 유지"
  - `base/bind-system-plan.md:157` — "`store "key"`(문자열 커링, 동적 키
    폴백)는 이벤트와 달리 …"
  - `base/source-state-plan.md:101` — "동적 키 폴백(`store "key"`)은 이제
    `State<any>`가 아니라 `Source<any>`를 반환"
  - `base/source-state-plan.md:465` — **예시 코드 자체가 폐기된 문법으로
    쓰여 있음**: `store "key1":With(store "key2"):Compute(...)`. 이건 서술이
    아니라 예제라 그대로 베껴 쓰일 위험이 큼 — `store.key1:With(store.key2)`
    로 고쳐야 함.
- **파급**: 폐기 사실이 반영되면 "동적 키를 어떻게 다루는가"라는 질문이
  **다시 열린다** — dot-access만 남으면 런타임에 키 이름이 정해지는 경우의
  정식 경로가 없음. ST-1 답변("타입 시간에 Source가 없는 것으로 나와 타입
  에러만 나면 됨")과 합치면 "동적 키는 아예 지원 안 함"이 의도로 보이나,
  **명시적으로 확인받지는 않았음**.

---

## D. `base/dispatch-core-plan.md`

### D-1 — "`isX(hint)` 방어 가드는 죽은 코드"는 **과장**이다 (한 핸들러가 여러 값 모양을 받는 경우 여전히 필요)

- **판정**: 큰 틀은 맞으나 **일반화가 과함** — 사용자가 단서를 붙임.
- **사용자 답변 원문**:
  > 맞습니다. 더 정확히 표현하자면, State<T> 에 대해 process 하면 후행 처리가
  > 생길텐데, state 의 새로운 값이 나오면 get 을 통해 얻어진 것으로 다시
  > process 가 수행됩니다. 여기서 이전의 프로세스 슬롯/인덱스와 비교해서
  > 정확히 자신이 만들어낸 것이라면, 단순 retract 처리가 발생하고, 아니라면
  > retractUnder 로 전부 제거되어 nil 이 됩니다. 즉 process 가 retract 를
  > 담당한다가 성립하므로 위는 옳은 표현입니다. **다만, 처음부터 한 핸들러가
  > 여러 값을 가질 수 있어 is 처리가 필요한건, 그 핸들러의 몫입니다.**
- **문서가 (너무 강하게) 주장하는 것** — 두 군데:
  1. "핸들러 계약" 절: *"방어 가드를 남겨둬도 무해하지만 **죽은 코드**이고,
     반대로 **그 가드가 있어야만 정확한 코드는 이제 없음**."*
  2. "Handler 작성 체크리스트" 3번: *"`isTag(...)` 같은 **방어 가드는 이제
     불필요**(넣어도 무해하지만 죽은 코드)."*
- **왜 과한가**: 하강 diff가 보장하는 것은 **"넘어온 값이 그 핸들러의
  `isHandlable`을 만족한다"**까지다. `isHandlable`이 **여러 모양의 값**을
  받아들이는 핸들러에서는, 그 안에서 어느 모양인지 가르는 `is` 판별이
  **여전히 필수**다 — 보장은 "같은 핸들러"까지지 "같은 값 모양"까지가
  아니기 때문. 실제 사례가 이미 코퍼스에 있음: `PropertyHandler`는 평범한
  값과 `Tween<T>` 래퍼를 **둘 다** 받아 `isTween(realv)`로 분기함
  (`base/tween-plan.md`의 3-상태 릴레이션 슬롯). 즉 "그 가드가 있어야만
  정확한 코드"가 지금도 존재한다.
- **정정 방향**: "옛 모델이 요구하던 *타입 미보장을 메우는* 방어 가드는
  불필요"와 "한 핸들러가 여러 값 모양을 다루면 그 판별은 **핸들러 자신의
  책임**"을 나눠 쓸 것. 지금 문장은 앞의 것만 말하면서 뒤의 것까지 부정한다.
- **파급**: 체크리스트 3번은 "새 Handler 짜기 전에 훑을 목록"으로 지정된
  곳이라, 이 상태로 두면 다중 모양 핸들러 작성자가 필요한 판별을 **빼도록
  유도**한다.

### D-5 — `PreRef`/`PostRef`는 "배열 먼저" 보장 *위에* 성립하는 게 아니라 **더 위 루프**에서 처리된다

- **판정**: 구조는 맞으나 **문서가 근거로 든 관계가 부정확** — 그 가정 위에
  쓰인 서술은 재검토 필요.
- **사용자 답변 원문**:
  > preref 랑 postref 는 정확히는 다른, 더 위에 있는 for 문에서 처리되고
  > flattened 에는 처리됨을 나타내는 값만 놔두는 구현. 이를 위해
  > Processed*Ref 와 ProcessedRefHandler(nop) 가 존재한다. PreRef 는 해당
  > 보장 아래 성립하는게 아니라, 먼저 처리되는 것. 구조 자체는 틀린것이
  > 없으나 가정을 그렇게 하였다면 재검토가 필요할 수 있음
- **문서가 주장하는 것**: `dispatch-core-plan.md`의 "props 순회 순서는 base
  디스패치 드라이버가 명시적으로 두 단계로 고정한다" 절 끝 —
  *"결과적으로 배열 슬롯에 놓인 어떤 값(Ref 포함)이든 모든 프로퍼티/이벤트
  세팅보다 항상 먼저 처리된다는 게 base 자체의 보장이 됨 — `ref-plan.md`의
  … "PreRef" 절이 **이 보장 위에서 성립**."*
- **실제로 맞는 것**: `PreRef`/`PostRef`는 두 패스 순회의 **배열 파트 패스에
  얹혀 있는 게 아니라, 그보다 위의 별도 pre-pass for 문**에서 처리되고,
  `flattened`에는 소진 마커(`ProcessedPreRef`/`ProcessedPostRef`)만 남는다.
  즉 "배열 먼저"라는 보장에 **의존하지 않는다** — 독립적으로 더 먼저 돈다.
- **정정 방향**: `PreRef` 성립 근거를 "배열 파트 우선 보장"에서 떼어낼 것.
  두 보장이 서로 독립임을 명시하고, `ref-plan.md`가 이 문장을 인용하고
  있다면 거기도 같이 볼 것.
- **부수**: 사용자는 nop 핸들러를 `ProcessedRefHandler`로 통칭했는데 문서는
  `ProcessedPreRefHandler`/`ProcessedPostRefHandler` 둘로 나눠 부름 — 하나로
  합칠지 여부는 확인 안 됨.

### D-6 — `setLength`/`setOffsetSource` 호출 책임자가 **미결정**이다 ⚠️ 열린 설계 질문

- **판정**: 아니오 — "그 위치를 처음 매치한 Handler"라는 문서의 규정이
  **부정확**하고, 아직 **정해지지 않은 케이스**가 있음.
- **사용자 답변 원문**:
  > 그 위치를 처음 매치한 핸들러는 약간 부정확함. State<Slot> 등 일 수 있음.
  > 최종 말단 요소가 이를 처리하는게 더 올바른것으로 보이는데, Slot 의
  > retract 처리가 비록 setOffset/Length 를 잘 stale 되지 않도록 처리는
  > 해주지만, 처음부터 State<Slot|None> 에서 None 이 오는 경우는 생각이
  > 필요한듯 보임. 0 으로 채워지는걸 누가 하냐를 지금 정해져있지 않을텐데.
  > 어디 쪽에서 하는게 맞는지 확인해야함. None 처리자는 그 자체로 리프연산이라
  > 볼 수 있느냐 하면 아니란것도 문제. 단순히 모든 핸들러가 k=number 일 때
  > 처리하도록 두는게 맞는지 검토해보고 싶음
- **문서가 주장하는 것**: `dispatch-core-plan.md`의 "Length/Offset" 절 —
  *"호출 책임은 `Slot` 자신의 `:List`/CRUD가 아니라 **그 위치를 처음 매치한
  Handler**(`Dispatch/Slot.luau`)"*, 그리고 "둘 다 array part의 모든 number
  인덱스에 대해 반드시 호출 — 생략은 UB".
- **문제 1 — "처음 매치한 Handler"는 중간 노드일 수 있다**: 배열 위치에
  `State<Slot>`이 오면 그 위치를 **처음** 매치하는 건 `StoreBind`(중간
  노드)다. 그런데 D-3에서 확정된 계약은 **중간 노드가 `inst`에 부작용을
  가하지 않는다**는 것 — `setLength`/`setOffsetSource` 등록이 그 계약과
  어떻게 양립하는지가 서술돼 있지 않다. 사용자 판단은 **"최종 말단 요소가
  처리하는 게 더 올바르다"** 쪽.
- **문제 2 — `State<Slot|None>`에서 `None`이 올 때 누가 `0`을 채우는가가
  미정**: `Slot`의 retract는 stale을 막아주지만, **처음부터** `None`이
  흘러오는 경로가 열려 있다. 그리고 `None` 처리자(`NoneHandler`)는
  **중간 노드라 말단(leaf) 연산으로 볼 수도 없어서** "말단이 등록한다"는
  규칙으로도 안 덮인다.
- **사용자가 검토하고 싶어하는 대안**: *"단순히 모든 핸들러가 `k=number`일
  때 처리하도록 두는 게 맞는지"* — 즉 "위치를 매치한 특정 한 핸들러의
  책임"이 아니라 "숫자 키를 다루는 모든 핸들러의 공통 의무"로 재규정하는 안.
- **파급**: `Length`/`Offset`은 형제 순서 보장의 유일한 메커니즘이라, 이
  갭이 남으면 `State<Slot|None>`이 섞인 배열에서 **형제 순서가 조용히
  어긋난다**(문서 스스로 이 상태를 UB로 규정). M3(Slot) 착수 전에 결론이
  필요한 항목.

### D-7 — base 소유 Fallback Handler의 등록 주체가 다시 뒤집힐 수 있음 ✅ 해소(같은 세션 내 재역전)

- **판정**: 아니오(잠정) — 사용자는 **quad-base 로드 시 등록이 맞다고 했었다**고
  기억하며, 문서의 현재 확정과 반대. 다만 사용자도 "더 확인이 필요"라고 함.
- **사용자 답변 원문**:
  > fallback 들은 quad-base 로드 시가 맞다고 했었음. - 안 그러면 quad-roblox
  > 를 로드하지 않았을 때 로드했는지 물어보는 요소가 처리가 안 된다고 했는데,
  > 이것도 더 확인이 필요한 부분으로 보임.
- **문서의 현재 확정**: `dispatch-core-plan.md`의 "base가 소유하는 핸들러와
  주입되는 엔진 op" 절 — **[재정정, 2026-08-14 열두 번째 세션]** 으로
  *"등록 주체는 quad-base 모듈 자체가 아니라 필요한 엔진(백엔드 팩토리)"* 로
  확정했고, 반대 모델("quad-base가 자기 모듈 로드 시점에 스스로 등록")을
  `archive/tag-attribute-load-time-registration-reversed.md`로 **역전 처리까지
  마쳤음**. 근거는 "`lifecycle-pattern.md`가 이미 거부한 `InitNamespace`류
  top-level 부작용 패턴과 같은 클래스".
- **사용자가 든 반대 근거**: 백엔드 팩토리가 등록 주체라면, **quad-roblox를
  아예 로드하지 않은 상태**에서는 그 Fallback Handler들도 없으므로
  "provider가 초기화됐는지 물어보는" 안내 경로 자체가 동작하지 않는다.
- **⚠️ 이건 "역전을 다시 역전"하는 판단이라 특히 신중해야 함** — 정정
  회신에 (a) 어느 쪽이 최종인지, (b) 최종이 "로드 시 등록"이면
  `archive/tag-attribute-load-time-registration-reversed.md`를 되살릴지
  아니면 새로 쓸지, (c) `InitNamespace` 거부 원칙과 어떻게 양립시킬지를
  같이 적어주시면 좋겠음.
- **해소(같은 세션 내, 2026-08-18) — (a)/(b)/(c) 전부 답변됨**:
  (a) **최종은 로드 시 등록** — "등록 주체는 다시 quad-base 자신이다
  (모듈이 자기 레지스트리를 구성하는 시점)"으로 재역전 확정. (b) 새로
  안 쓰고 **기존 `archive/tag-attribute-load-time-registration-reversed.md`에
  재역전 배너만 추가**(그 문서 자체가 "이번에 재역전됐다"는 걸 스스로
  알림 — 새 archive 문서 생성 없음). (c) `InitNamespace` 거부 원칙과의
  양립: 그 원칙이 금지한 건 "사용자가 수동으로 init을 호출하게 만드는
  것"과 "모듈 로드 시 *남의* 상태를 건드리는 것" 둘인데, base가 **자기
  모듈 안의 자기 레지스트리**를 자기가 채우는 건 그 어느 쪽도 아니므로
  충돌 없음. 지금 유효한 설계는 `base/dispatch-core-plan.md`의 "base가
  소유하는 핸들러와 주입되는 엔진 op" 절의 "[재역전, 2026-08-18 구현 전
  QA — 사용자 확정]" 배너가 소스.

---

## RE. `base/relate-plan.md`

### RE-1 — gcconn/gchold 보관이 `SetStrong`이라고 적힌 두 곳이 틀림 (정답은 `SetWeak`)

- **판정**: 아니오 — **`SetWeak`이 맞음**(사용자 확정).
- **틀린 위치 2곳**:
  1. `base/relate-plan.md`의 "대체하는 것" 절 — *"`bindLifetime`/`canExecute`
     — gcconn/gchold를 `Relate`의 `SetStrong`으로 저장(둘 다 존재 이유가
     '안 죽는 것'이므로 strong)"*. **괄호 안 근거까지 통째로 틀림** — 둘의
     생존은 gcconn 클로저 upvalue와 `gchold[1]`이 이미 보장하므로, 같은
     문서의 "다른 곳에서 안전하게 유지되는 것은 항상 `SetWeak`" 절 규칙에
     따라 weak가 맞다.
  2. `base/architecture.md` 소스 트리의 `quad-roblox/src/LifetimeHandle.luau`
     행 주석 — *"`Relate:SetStrong`으로 gcconn/gchold 저장"*.
- **맞는 서술(그대로 두면 됨)**: `relate-plan.md`의 "다른 곳에서 안전하게
  유지되는 것은 항상 `SetWeak`" 절, 그리고 `base/lifecycle-pattern.md`의
  구현 스케치(`InstData:SetWeak`/`BindData:SetWeak` 전부 weak).
- **왜 그냥 오탈자가 아닌가**: 1번은 **근거 문장까지 딸려 있어** 읽는 쪽이
  "strong이어야 하는 이유가 있구나"로 납득하게 만든다. 실제로 이 서술을
  따라 `SetStrong`으로 구현하면 `relate-plan.md`가 경고하는 **두-`Relate`
  상호 강참조 순환**(RE-2, Luau에 ephemeron이 없어 실제 누수)에 정확히
  걸린다 — `gchold`가 `value`를 강하게 잡고 `BindData`가 `value`를 키로
  `gchold`를 강하게 잡는 모양이 되기 때문. 같은 문서가 "이 규칙을 지키면 그
  위험이 구조적으로 안 생긴다"고 자랑하는 바로 그 사례를 반대로 적어둔 셈.

---

## M. `base/modifier-plan.md`

### M-3 — 예약 필드 이름이 `Apply` 하나가 아니라 **셋**이고, `Overridden`은 콜론 메소드로도 쓸 수 있다

- **판정**: 아니오 — 문서 두 곳이 틀림.
- **사용자 답변 원문**:
  > 전부 가능한게 맞음. Overridden 도 편의 상 A: 체인으로 제공 가능함. 밖에서
  > 직접 (A, B) 해주어도 좋고. 콜론과 닷 둘다 가능함
- **틀린 곳 1 — `modifier-plan.md` 8번 절 "구현 시 주의"**: *"`__index`가
  고정 메소드 테이블(**현재는 `Apply` 하나**)을 먼저 확인하고 … 따라서
  **`Apply`는 Modifier 필드 이름으로 예약됨**"*.
  → 9번 절이 `:Peek(key)`를 추가했고 `Overridden`도 콜론 호출을 지원하므로,
  고정 메소드는 **`Apply` / `Peek` / `Overridden` 셋**이고 **셋 다 필드
  이름으로 예약**된다. "현재는 `Apply` 하나"는 `Peek`이 생기던 시점에
  갱신되지 않은 stale.
- **틀린 곳 2 — `base/architecture.md` "코드 스타일 — 네이밍 케이싱" 절**:
  대문자 3번 항목이 `Modifier.Overridden`을 *"**콜론 메서드는 아니지만**
  (여러 Modifier를 동등한 인자로 받아야 해서 self 하나로 안 됨)"* 이라고
  단정하며, 이를 "정적 결합 함수"라는 **세 번째 하위 분류를 새로 만든
  유일한 근거**로 든다.
  → 실제로는 콜론 호출도 지원하므로 그 괄호 안 근거("self 하나로 안 됨")가
  성립하지 않는다. 정정 시 이 세 번째 분류를 유지할지(다른 근거로) 아니면
  2번 항목(콜론 메서드)에 흡수할지 판단 필요.
- **파급**: 예약 필드 이름은 **Roblox 프로퍼티 이름과 충돌하면 안 되는**
  목록이라, 셋으로 늘어난 사실이 `FrameModifier`류 타입 생성 스크립트의
  제외 목록에 반영돼야 함(M7).

---

## R. `base/ref-plan.md`

### R-1 — "Ref 객체 자신이 곧 콜백/대기자 배열" 구조를 재고할 것 (사용자: 별도 `.Callbacks` 테이블 + `.Value`는 평범한 해시 필드)

- **판정**: 아니오 — 사용자가 **더 단순한 대안**을 제시.
- **사용자 답변 원문**:
  > 단순히 .Callbacks: {fun, thread} 등이 있는게 맞지 않나라는 생각임. .Value
  > 는 단순 해시필드로 주는게 더 간단해보임. 엔지니어링 난이도구 단순 테이블
  > 하나 더 만드는게 쉽고, 크게 비싸지도 않다고 생각됨.
- **문서가 주장하는 것**(2026-08-09 열한 번째 세션 보강): Ref 객체 **자신이
  곧 콜백/대기자 배열**(숫자 키 색인)이고, 그래서 `.Value`를 `self.Value = v`
  로 얹으면 `T`가 함수/스레드일 때 `for i,v in self do` 순회가 hash 파트까지
  훑어 오분류되므로 **`.Value`를 `__index` 메타메소드로** 구현해 저장 위치를
  배열과 분리해야 한다.
- **사용자 대안**: 콜백/대기자를 **별도 필드 `.Callbacks`** 에 담고, `.Value`는
  그냥 **평범한 해시 필드**로 둔다. 근거는 "테이블 하나 더 만드는 게 쉽고
  크게 비싸지도 않다" — 즉 `__index` 우회 기법을 쓸 이유 자체를 없앤다.
- **이 정정이 무효화하는 서술들 (같이 볼 것)**:
  1. `.Value`의 `__index` 구현 근거 문단 전체(위 인용) — 대안에서는
     hash 파트 충돌 자체가 안 생기므로 불필요해짐.
  2. "구현 디테일" 문단의 **`for i, v in <배열> do` 단일 순회로 `type(v)`
     분기**(thread=대기자 / function=콜백) — 별도 `.Callbacks` 테이블이
     생기면 순회 대상이 `self`가 아니라 그 테이블이 된다. `type(v)` 분기
     자체는 유지 가능하나 서술 위치가 바뀜.
  3. 아래 R-3의 `nil` 소진/빈 슬롯 재사용 결정 — 배열이 어디 있든 논리는
     그대로 유효하지만, 서술이 "Ref 객체 자신"을 전제로 쓰여 있어 같이
     고쳐야 함.
- **파급**: `base/architecture.md` 소스 트리의 `Ref.luau` 주석
  (`범용 값 박스(.Value 읽기 + :Set()/:Callback()/:Wait() 셋)`)은 그대로 둬도
  되지만, 구현 구조를 서술한 곳은 전부 갱신 필요.

### R-3 — `PreRef` pre-pass 소진 슬롯을 `None`으로 채운다는 서술이 stale

- **판정**: 아니오 — 틀림(이미 2026-08-14에 정정된 내용이 이 문서에 반영 안 됨).
- **사용자 답변 원문**:
  > PreRef, PostRef 는 ProcessedPreRef 등의 nop 핸들러가 캐치하는걸로 자리를
  > 채우지 None 으로 채우진 않았던것 같음 sourceList 는 정확. 단, length 는
  > 0 을 넣는게 옳다. length: number|state<number> 와 offset:
  > state<number>|None 차이라고 생각함
- **틀린 위치**: `base/ref-plan.md`의 "왜 `None`이 아니라 `nil`인가" 절 결론
  문장 — *"순서가 중요한 배열(**`PreRef` pre-pass 소진 슬롯**, Length/Offset
  `sourceList`)은 계속 `None`"*.
- **실제로 맞는 것**: pre-pass가 소진시킨 자리는 `None`이 아니라 **전용 센티널
  `ProcessedPreRef`/`ProcessedPostRef`** 로 채워지고, 전용 nop 핸들러
  (`ProcessedPreRefHandler`/`ProcessedPostRefHandler`)가 정상 `Dispatch.process`
  경로에서 그걸 캐치한다. `dispatch-core-plan.md`는 이미 이렇게 정정돼
  있음(**[정정, 2026-08-14 두 번째 세션]**) — `ref-plan.md`만 갱신에서 빠짐.
  `sourceList`가 `None`인 것은 맞음.
- **부수 확인(정정 아님)**: 해제 시 `setLength`엔 **숫자 `0`**, `setOffsetSource`엔
  **`None`** 이 들어가는 비대칭이 의도된 것 — 타입이 각각
  `number | State<number>` 와 `Source<number> | None` 이라서. 두 문서 모두
  이미 이렇게 적혀 있어 고칠 것 없음.

### RF-4 — `drive`가 `None`을 건너뛰는 특수 분기를 **없애야** 함 ⚠️ 설계 변경, D-6과 연결

- **판정**: 아니오 — 전제("배열 파트의 `None`은 `Dispatch.process`를 절대 안
  탄다")가 **거짓**이고, 그 위에 세운 설계도 같이 바뀜.
- **사용자 답변 원문**:
  > 직접적으로 Frame{None} 이면 맞긴한데, Frame{Store<Slot|None>} 이면 탈 수
  > 있음. 무엇이냐 상관 없이 탈 수 있는게 맞긴 하고, 그 경우도 k=number 이면
  > 단순 넘어가기를 해야함. 또한, 이 경우 setLength/OffsetSource 를 여기서
  > 처리하는게 맞다고 보임. 즉, drive 는 v == None 인지 확인 안하고 그냥
  > 프로세스 태우는게 가장 적절한 처리로 보임. NoneHandler 의 retract 는 Nop
  > 일 수 있어보이나, process 자체가 이전걸 retract 하는건 필요(Tag -> None).
- **깨진 전제**: 리터럴 `Frame{None}`만 생각하면 두 패스 루프가 걸러내면
  그만이지만, **`Frame{ State<Slot|None> }`** 처럼 반응형 값이 `None`을
  내놓으면 그 `None`은 `StoreBind`의 재귀를 타고 **`Dispatch.process`에 그대로
  도착**한다. 즉 "배열 파트의 `None`은 `process`를 안 탄다"는 보장이 애초에
  성립하지 않는다.
- **틀린 위치**:
  - `base/ref-plan.md`의 옛 `명확화(2026-08-09 열한 번째 세션, 확인 질문에 답변)` 항목 전체(2026-08-18에 전면 정정됨) —
    *"배열 파트의 `None`은 **애초에 `Dispatch.process` 자체를 절대 안
    탄다**"*, *"`k=number` 조합으로 `NoneHandler`가 실제로 매치되는 경우는
    없음"*.
  - `base/dispatch-core-plan.md`의 "`None` 센티널" 절 — *"`Dispatch.drive`의
    두 패스 루프 자신이 `NoneHandler`/`Dispatch.process`를 거치지 않고 바로
    건너뜀"*, 그리고 "정말 빈 자리인 `None`만 두 패스 루프가 직접 건너뜀"이라는
    후속 서술.
  - 같은 문서 "Length/Offset" 절이 `None` 슬롯의 등록 책임을 서술한 부분.
  - `base/component-composition-plan.md`의 "필수 관용구" 문단 — *"`props.Modifier
    or None`이 최종적으로 배열 파트에 `None`인 채로 남으면 **두 패스 루프
    자신의 array-part `None`-스킵 규칙**이 그대로 적용돼 아무 일도 안
    일어남"*. 스킵 규칙이 사라지면 이 근거가 바뀐다(`NoneHandler`가 매치돼
    `setLength(0)`/`setOffsetSource(None)`을 등록하는 경로가 됨).
    **결론(`or None`을 쓰는 것)은 안 바뀜** — CC-3에서 관용구 자체는
    "맞음"으로 확인됐으므로 근거 문장만 갱신.
- **사용자가 지시한 새 설계**:
  1. **`Dispatch.drive`는 `v == None`을 확인하지 않고 전부 `Dispatch.process`에
     태운다** — 특수 분기 제거. (이게 "가장 적절한 처리"라는 판단.)
  2. **`NoneHandler`가 `k == number`인 경우를 스스로 처리**한다 — 실제 값
     세팅은 하지 않고 넘어가되, 그 자리의 **`setLength(0)` /
     `setOffsetSource(None)` 등록을 여기서** 한다.
  3. `NoneHandler`가 **반환하는 retractor**는 no-op이어도 되지만,
     **`process` 자체는 이전 것을 retract시키는 역할을 해야 한다** —
     `Tag` → `None` 전환에서 이전 Tag 기여가 실제로 걷혀야 하기 때문.
- **⚠️ D-6과의 관계**: D-6이 *"`State<Slot|None>`에서 `None`이 올 때 누가
  `0`을 채우는가가 미정, 그리고 `None` 처리자는 말단이 아니라 중간 노드라
  '말단이 등록한다' 규칙으로도 안 덮인다"* 고 남겨둔 갭의 **답이 여기 나옴** —
  `NoneHandler`가 `k=number`일 때 직접 등록한다. 다만 이러면 `NoneHandler`가
  "중간(래핑) 노드"이면서도 등록 책임을 지게 되므로, **D-3의 "중간 노드는
  `inst`에 부작용을 가하지 않는다" 계약과의 관계를 정리해야 함**
  (`setLength`/`setOffsetSource`는 `inst`의 프로퍼티를 건드리는 게 아니라
  Dispatch 부기라 계약 위반이 아니라고 볼 여지가 크지만, 문서가 그렇게
  명시하고 있지는 않음).
- **정정 시 같이 확인할 것**: 3번의 "`process`가 이전 것을 retract"가
  하강 diff 모델에서 **자동으로 성립하는지**(핸들러가 `TagHandler` →
  `NoneHandler`로 바뀌므로 (B) 분기가 `retractFrom`을 부름) 아니면 **별도
  코드가 필요한지**. 자동이면 문서에 그 경로를 명시만 하면 되고, 아니라면
  `NoneHandler.process`에 명시적 정리가 들어가야 함.

---

## B. `base/brand-plan.md`

### B-1 — `Brand.get`이 `None`을 특수 분기하는 설계는 **의존성을 만들므로 기각**

- **판정**: 부분적으로 틀림 — 포함 관계(`isRef(preRef)==true`)와 테이블
  아이덴티티 태그는 맞으나, **`None` 처리 방식이 틀림**.
- **사용자 답변 원문**:
  > 맞음. 그런데 Brand 는 None 을 참조할 필요는 없음. Brand 자체는 아에
  > 의존성 없고, None 도 테깅되는건 맞으나, isNone 대신 필요한 곳에서 v ==
  > None 하면 되는 일, 혹은 isNone 구현 자체를 그렇게 해주면 되는 일.
- **문서가 주장하는 것**: `brand-plan.md`의 옛 `None은 이 레지스트리에 안 들어감` 문단(2026-08-18에 정정됨) — *"`Brand.get(x)`가 … 범용 introspection 창구 역할까지
  겸하게 하려면 `None`도 빠지면 안 되므로, **`Brand.get`이 내부적으로
  `x == None`을 먼저 확인하는 특수 분기를 하나 두고** 그 뒤에 일반 레지스트리
  조회로 폴백 — `isNone`은 바로 이 특수 분기의 실제 구현체가 됨"*.
- **실제로 맞는 것**: **`Brand` 모듈은 아무 의존성도 갖지 않아야 한다** —
  `None`을 참조하는 특수 분기를 넣으면 `Brand → None` 의존이 생긴다.
  `isNone`은 **필요한 곳에서 `v == None`** 으로 하면 되고, `isNone`이라는
  이름의 함수를 두더라도 그 구현이 그냥 `v == None`이면 된다. `None` 자체를
  레지스트리에 태깅하는 것 자체는 무방.
- **파급**: "`Brand.get`이 quad가 아는 모든 값을 답해주는 단일 introspection
  창구"라는 서술도 같이 재검토 필요 — `None`이 그 창구에서 빠지는 걸
  받아들일지, 아니면 `None`도 평범하게 레지스트리에 등록해 특수 분기 없이
  답이 나오게 할지(사용자 답변은 후자를 허용함).

---

## AT. `base/attribute-plan.md`

### AT-1 — 같은 그룹 객체를 두 위치에 놓는 경우(`Frame{a, a}`)가 미검토 ⚠️ 열린 항목

- **판정**: 확정 내용 자체는 맞음. 다만 사용자가 **새 검토 항목**을 제기.
- **사용자 답변 원문**:
  > 맞음. 이러면 a=Attribute() Frame{a,a} 가 되어도 이미 문제가 안 나는것으로
  > 보이긴 하는데, UB로 둘지 에러를 쉽게 낼 수 있는지는 확인이 필요해보임.
- **왜 검토가 필요한가 (문서 의사코드 기준 손 트레이싱)**: `groupKey(v, name)`이
  **그룹 값 객체별·이름별 메모이즈**이므로, 같은 객체 `a`가 `k=1`과 `k=2`에
  놓이면 **양쪽이 완전히 같은 키 객체**로 위임한다. 그러면:
  - `nameClaims` 체크는 `cur == k`라 **통과**한다(에러가 안 남).
  - 그런데 두 위치가 `(inst, 같은 key)`라는 **하나의 체인을 공유**하게 된다 —
    `k=1`의 `process`가 `Dispatch.process(inst, key, source, 1)`을 부르고,
    `k=2`도 **같은 인자로 같은 체인**을 다시 부른다.
  - 더 중요한 건 철거: `k=1`이 retract되면 그 클로저가
    `Dispatch.retractFrom(inst, key, 1)`을 불러 **`k=2`가 아직 쓰고 있는
    바인딩까지 통째로 철거**한다.
  - 이건 `Ref`의 "이중 배치 방지"(`base/ref-plan.md`)가 막은 것과 **정확히
    같은 클래스의 문제**로 보인다 — 다만 `Ref`는 `bindLifetime` 게이트로
    잡히는데 그룹 `Attribute`엔 대응 게이트가 없다.
- **✅ 후속 답변으로 결론 나옴 (SL-1 답변에 덧붙여짐)** — **위치별 claim을
  하나 두는 쪽**으로:
  > 이전 답변에 대해 diff 를 보다 더 생각이 나서 말하자면, Attribute 는
  > bindLifetime 를 못함. Ref 와 다르게 여기저기서 사용 가능하기 때문. 한
  > 곳에서 바운딩 했다고 다시 바운딩 못할 순 없음. 따라서 위치별 claim 을
  > 하나 두어야한다고 생각함.

  즉 `Ref`처럼 `bindLifetime`을 재사용하는 방식은 **쓸 수 없다** — `Ref`는
  "한 곳에만 배치"가 규칙이지만 `Attribute` 그룹 값은 **여러 곳에서 쓸 수
  있어야** 하므로, 한 번 바인딩했다고 다시 못 하게 만들면 안 된다. 대신
  **위치별 claim 레지스트리를 하나 추가**해서 같은 그룹 객체가 같은
  위치 집합을 이중 점유하는 것만 잡는다.
- **정정 시 설계할 것**: 그 위치별 claim이 무엇을 키로 하는지
  (`(inst, groupValue) → k` 인지, `groupKey` 단위인지), 그리고 기존
  `nameClaims`와 어떻게 공존하는지.
- **같이 볼 것**: `Tag`는 같은 객체를 여러 위치에서 재사용하는 게 **정상
  관례**로 확정돼 있고(T-1) 위치(`k`) 기준 참조 카운트로 안전하다 — 그룹
  `Attribute`만 왜 다른지(자원이 "값 하나"라 겹침=충돌)가 정정 시 같이
  서술되면 좋겠음.

---

## SL. `base/slot-plan.md`

### SL-1 — `Ref`의 leaf 바인딩은 **배열(숫자 키) 전용**이고, `RefLeafHandler`에 `k` 체크가 빠져 있음

- **판정**: 아니오 — "배열 전용"이 맞고, 이를 부정하는 서술과 구현이 틀림.
- **사용자 답변 원문**:
  > 배열 전용이 맞음. 컴포넌트 일 때는 함수의 인자에 맞게 위처럼 보낼 수
  > 있겠으나, 기본 의도는 리프에선 숫자 바인딩임. 이유는 Ref끼리는 순서가
  > 통하므로, 다른 Ref처리를 먼저 해야하는 순서 의존이 있을 때에도 가능하게
  > 하고자였음.
- **고쳐야 할 곳**:
  1. **`base/ref-plan.md`의 `RefLeafHandler.isHandlable`** —
     `isRef(v) and not isPreRef(v) and not isPostRef(v)` 로만 적혀 있어
     **`type(k) == "number"` 체크가 빠졌다.** 짝인
     `ObserverEffectLeafHandler`엔 그 체크가 **필수**라고 명시돼 있고
     (S-8에서 확인), 빠지면 named 자리로 흘러온 값을 잡으려는 FALLBACK
     가드가 죽은 코드가 된다 — 같은 이유가 `Ref`에도 그대로 적용된다.
  2. **`base/ref-plan.md`의 옛 `일반 Ref는 계속 Modifier/Store 어디든 자유롭게 들어감` 항목**(2026-08-18에 한정 서술 추가) — 이 문장이 "named 해시 키에 놓아도 leaf 바인딩이
     된다"로 읽힌다. 실제 의미는 "Modifier 필드나 Store 값으로 **전달**될
     수 있다"(=값으로서 어디든 흘러갈 수 있다)이지 "leaf 바인딩 자리가
     아무 데나 된다"가 아니므로, 오해가 없게 다시 써야 한다.
  3. **`base/slot-plan.md`의 예시 `slot:Add(Frame { Ref = myRef })`** —
     여기 `Frame`이 **컴포넌트 함수**라서 `Ref`가 그 함수의 named
     파라미터인 경우에만 성립한다. 실제 Instance 리터럴로 읽히면 위 1번
     규칙과 정면으로 어긋나므로, 예시에 그 전제를 명시해야 한다.
- **배열 전용인 이유(사용자 논거, 문서에 없던 것)**: `Ref`끼리는 **배열
  index 순서가 통하므로**, "다른 Ref 처리를 먼저 해야 하는 순서 의존"이
  있을 때도 표현이 가능하게 하려는 것. (`PreRef`/`PostRef`의 "계열 안
  순서 보장"과 같은 결의 근거인데, 일반 `Ref`에 대해서는 어디에도 안
  적혀 있었음.)

### SL-3 — `:List` reconcile의 `nil` 리턴을 비파괴로 확정한 것을 **재검토해야 함** ⚠️ 확정 뒤집기 후보

- **판정**: 부분적으로 틀림 — 사용자는 **파괴가 기본이 맞다**고 보며,
  현재 문서 확정(비파괴)과 어긋남.
- **사용자 답변 원문**:
  > List reconcile 에서 nil 리턴으로 지워지길 요구하는 경우는 비파괴일지,
  > 파괴일지 생각해보아야할 것이 많은듯. 기본적으로 파괴가 맞기는 한데,
  > Instance.new Destroy 비용을 아끼고 싶은, filter 부분에 있어서는 단순
  > Parent = nil 로 두고 싶을수도 있음. 이를 위해 특정 리턴 등은 Parent = nil
  > 로 만들고 홀드해둔 다음, 나중에 prev 상 이를 사용할 수 있게 두는 방법이
  > 가능한가 모색해보고 싶음. 아마 ud 는 명시적으로 nil 안 하면 안 지워지니,
  > PopOnly 등을 만들어 PopOnly, { old = ..., source... } 등을 하면 Parent 를
  > 빼고 slot 에서 적절히 빼주는게 방법으로 보임.
- **문서의 현재 확정**: `slot-plan.md`의 "구현상 바뀌어야 하는 것" 절 2번 —
  *"**`:List`의 `reconcile`** — 교체/소멸 시 `rawRemove`(파괴) 대신 같은
  비파괴 경로. 데이터에서 빠진 아이템도 파괴되지 않고 언마운트만 되며,
  아무도 안 들고 있으면 GC"*. 그리고 "자동 경로는 언마운트, 명시적으로
  지우라고 한 것만 파괴"라는 일반 규칙.
- **어긋나는 지점**: 사용자는 `:List` reconcile의 `nil` 리턴에 한해
  **파괴가 기본**이라고 봄. 즉 "자동 경로 = 전부 언마운트"라는 일반화가
  `:List`에는 안 맞을 수 있다. (`State<Slot>` 교체가 언마운트인 것은
  SL-3 질문에서 별도로 부정되지 않았으므로 그대로 유효해 보임 — 두 경로를
  분리해서 정할 필요.)
- **사용자가 원하는 추가 기능 — 재사용을 위한 `PopOnly`(가칭)**:
  `filter` 용도에서 `Instance.new`/`Destroy` 비용을 아끼려면, 파괴하지 않고
  **`Parent = nil`로만 두고 홀드**해뒀다가 나중에 `prev`(`:Compute`의
  `previous`와 같은 자리)로 **재사용**할 수 있어야 함. 구체안:
  `updateFn`이 `PopOnly, { old = ..., source = ... }` 같은 걸 반환하면
  reconcile이 `Parent`만 빼고 Slot에서 적절히 제거하는 방식.
  - 참고로 사용자가 짚은 전제: userdata는 **명시적으로 `nil`을 안 하면
    안 지워지므로** 홀드만 해두면 살아있다.
- **결정해야 할 것**: (a) `:List` reconcile `nil` 리턴의 기본을 파괴로
  되돌릴지, (b) `PopOnly`를 이번 설계에 넣을지 백로그로 뺄지, (c) 넣는다면
  `updateFn` 반환 규약(현재는 "반환값을 해석하는 `:List` 내부 로직")이
  어떻게 확장되는지.

---

## E. `base/effect-plan.md`

### E-2 — `:Unsubscribe()`가 leaf 바인딩에도 cleanup을 부르게 한 건 틀림 (`Subscribe`의 짝으로 좁혀야 함)

- **판정**: 아니오 — 계약을 **축소**해야 함.
- **사용자 답변 원문**:
  > 표면적으로 맞아보이긴 하나, subscribe 한게 아니면 unsubscribe 는 지원하면
  > 안 되거나, 적어도 리프 바운딩에선 그래선 안 됨. leaf 에 바운딩 된 경우,
  > 특히 state<effect> 또는 observer 가 들어갈 때, 단순 emit 에서 최적화로
  > 인해 이전과 동등이라 retract 가 아무 일을 하지 않음. (그런데, 별개로,
  > retract 가 아무것도 안 하고 나서, process 쪽에서도 아무것도 안 하는지는
  > 확인이 필요해보임) 그래서 다시 바운딩 안 먹는것이라 의도한 바가 아님.
  > subscribe 는 unsubscribe 의 짝이라고 생각함.
- **문서가 주장하는 것**: `effect-plan.md`의 "`EffectHandle:Subscribe()`/
  `:Unsubscribe()`" 절 — *"`:Unsubscribe()`는 Observer의 것을 그냥 위임하지
  않는다 — Effect 계층에서 의미가 확장됨 … **직전(또는 유일한) cleanup을
  정확히 1회 호출** — leaf가 죽을 때 하던 것과 정확히 같은 이벤트를 수동으로
  앞당기는 것"*.
- **실제로 맞는 것**: **`:Unsubscribe()`는 `:Subscribe()`의 짝**이다 —
  `:Subscribe()`로 등록하지 않은 핸들(=leaf 바인딩된 핸들)에는 지원하지
  않거나, 최소한 leaf 바인딩 경로에서는 cleanup을 앞당기면 안 된다.
- **왜 위험한가 (사용자 논거)**: leaf 바인딩 + `State<Effect>`/`State<Observer>`
  조합에서, **값이 실제로 안 바뀌면 dedup 최적화 때문에 retract가 아무 일도
  안 한다**(S-8의 `old ~= v` dedup). 그런데 `:Unsubscribe()`가 cleanup을
  미리 실행해버리면, 뒤이은 재-dispatch에서 **dedup 때문에 재바인딩이 안
  일어나** 그 Effect가 조용히 죽은 채로 남는다 — 의도한 동작이 아님.
- **⚠️ 함께 확인해야 할 별건(사용자가 괄호로 남긴 것)**: dedup 경로에서
  **retract가 아무것도 안 한 뒤 `process` 쪽도 정말 아무것도 안 하는지**
  대칭이 실제로 성립하는지 확인 필요. `ObserverEffectLeafHandler` 의사코드
  기준으론 `process`의 `if old ~= v then bindLifetime(...) end`와 클로저의
  `if nextValue ~= v then unbindLifetime(...) end`가 짝을 이루지만,
  **`EffectHandle`은 내부 Observer로 cascade까지 해야 하므로**(E-2의 (2)번,
  그 자체는 "맞음"으로 확인됨) 그 cascade가 dedup 분기 안에 제대로 들어가
  있는지가 별도 확인 대상.
- **정정 범위**: `base/effect-plan.md`의 해당 절, 그리고 같은 논리가 적용되는
  `base/source-state-plan.md`의 Observer `:Unsubscribe()` 서술(거기는 이미
  "전역 경로 전용"으로 좁혀져 있어 괜찮아 보이나 같이 확인).

---

## EV. `base/event-plan.md`

### EV-1 — 이벤트 disconnect 센티널을 `false`에서 `None`/`nil`로 바꿀 것

- **판정**: 아니오 — 센티널 선택이 이제 낡음.
- **사용자 답변 원문**:
  > 다만, 이젠 None 이 있어서 false 을 사용해야할 이유가 없어졌다고 봄. false
  > 대신 None/nil 을 사용하지 말아야할 이유가 없다면 일관적이게 None/nil 을
  > 주는게 맞다는 생각
- **문서가 주장하는 것**: `event-plan.md`의 "이벤트도 store-bind 가능" 절(제목의 센티널 표기는 2026-08-18에 `None`/`nil`로 갱신됨) — *"**`false`로 disconnect, `nil` 아님.** `nil`은
  Lua 테이블에서 '키가 아예 없음'과 구별이 안 됨 … 대신 `false`(Luau에서
  실재하는 싱글톤 타입)를 '연결 없음' 센티널로 씀"*.
- **왜 낡았나**: 그 결정(2026-08-06)은 **`None` 센티널이 확정되기 전**에
  "테이블에 실재하는 값으로 표현 가능한 것"이 필요해서 `false`를 고른 것인데,
  이후 `None`이 정확히 그 역할로 도입됐다(`base/modifier-plan.md` 2-1,
  `base/dispatch-core-plan.md` "`None` 센티널"). 지금은 **같은 문제를 푸는
  센티널이 두 개** 있는 셈이고, 이벤트만 다른 걸 쓸 이유가 없음.
- **정정 시 같이 설계해야 할 것**:
  - `None`으로 바꾸면 **`NoneHandler`가 매우 높은 우선순위로 먼저 매치**해서
    `nil`로 재귀시킨다 — 그러면 `EventHandler`가 **`(k=이벤트키, v=nil)`을
    받아 disconnect로 처리**할 수 있어야 한다. `isHandlable`이 `nil` 값에도
    매치되도록 규정이 필요.
  - 문서의 기존 근거였던 *"이벤트인지 여부는 값이 아니라 키(리플렉션)로
    결정되므로 다른 boolean 프로퍼티 핸들러와 `(k, false)` 매칭이 겹칠 위험
    없음"* 은 `false`를 안 쓰면 아예 불필요해지므로 삭제 대상.
  - N-4(`NilHandler` 신설)와 상호작용 — `k`가 숫자가 아닌 이벤트 키에서
    `nil`이 어느 핸들러에 가야 하는지 같이 정할 것.

---

## BS. `base/bind-system-plan.md`

### BS-2 — "이벤트 콜백 시그니처는 Luau가 검증 못 한다"는 전제가 **거짓** ⚠️ 두 문서의 근거가 무너짐

- **판정**: 아니오 — 사용자가 **반례 코드를 직접 작성해 제시**.
- **사용자 답변 원문**:
  > ReflectionService 사용은 맞음. 단 새로 프로젝트 루트에 생성된 test.luau 를
  > 보면 알 수 있지만, 이벤트의 콜백 또한 타입을 지정해주는게 가능함. D가
  > 만들어지는 제네레이터 상에서 타입을 적절히 제공하면 콜백 시그니처는 충분히
  > 처리 가능한것으로 보임. 이는 OnChange 와 다르게, 필드이기 때문에 타이핑이
  > 가능함.
- **반례 (2026-08-18 사용자가 직접 작성해 보여준 코드 — 당시 프로젝트 루트에
  `test.luau`로 뒀다가 이후 삭제, 아래가 그 전문)**:
  ```luau
  function Frame (prop: {MouseButton1Click: ((a: number)->())?})
  end

  Frame{
      MouseButton1Click = function(a) -- a: number
      end
  }
  ```
  props 테이블 **타입에 필드로 선언돼 있으면 콜백 파라미터가 그대로
  추론된다** — 런타임 판별을 `ReflectionService`로 하는 것과 **타입을 생성기가
  제공하는 것은 완전히 별개 축**인데, 문서가 둘을 묶어버렸다.
- **틀린 위치 1 — `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍
  인체공학" 절**: *"이건 타입 안전성을 어느 정도 포기하는 대가지만(**콜백
  시그니처까지 Luau가 검증 못 함** — `apply<T,U>(instance: T, properties: U):
  T & U`가 스키마 검증 없이 구조적으로만 merge), 이미 UB로 남긴 … 와 같은
  급의 한계라 손해가 크지 않고"*.
  → `D` 생성기가 클래스별 props 타입에 **이벤트 필드까지 정확한 콜백 타입으로
  포함**시키면 검증된다. "감수하는 대가"가 아니라 **생성기가 챙겨야 하는
  구현 체크리스트 항목**이다(`ui-shorthand-plan.md`가 `UICorner`/`UIPadding`/
  `UIScale`을 Modifier 타입 메소드 목록에 끼워 넣으라고 한 것과 같은 성격).
- **틀린 위치 2 — `base/onchange-plan.md`의 "확정" 절**: `OnChange<<T>>`
  제네릭을 안 만드는 근거로 *"이미 확정된 '이벤트 바인딩은 콜백 시그니처를
  Luau가 검증 못 하는 대가를 받아들인다'는 결정 … 과 같은 급의 트레이드오프라
  새로 정당화할 것 없음"* 을 듦.
  → **그 전제가 거짓이므로 이 근거는 통째로 무효.** 다만 사용자 답변에 따르면
  **결론(제네릭 없음)은 유지되고 근거만 바뀐다** — 이벤트는 **필드**라
  타이핑이 되지만 `OnChange(name)`은 **이름을 인자로 받는 팩토리**라 그
  경로가 없다는 것이 진짜 이유.
- **파급**:
  - `base/architecture.md`의 소스 트리 `DI/init.luau` 주석("제네릭 생성자 +
    ~25개 정적 필드")과 `D`/`DI` 생성기 설계에 **"이벤트 필드의 콜백 타입도
    생성한다"**가 추가돼야 함.
  - `base/store-plan.md`의 "타입 추론 문제" 절이 *"이벤트는 이 관습의
    **유일한 예외**"* 라고 서술하는데, 예외의 성격이 바뀐다 — "타입을
    포기하는 예외"가 아니라 "**이름 지정 방식만** 문자열 키인 예외"다.
  - **이벤트가 store-bind될 때**(`State<function>`/`false`→EV-1에 따라
    `None`/`nil`)의 타입은 어떻게 되는지도 같이 정해야 함 — 필드 타입이
    `((a: number)->())?` 뿐이면 `State<...>`나 센티널을 못 받는다.

---

## 추가 요구사항 — 심사 중 사용자가 새로 지시한 것

기존 서술이 틀려서가 아니라, 확인 과정에서 사용자가 **새로 요구한 사항**.
정정이 아니라 설계 추가라 위 결함 목록과 분리해 둔다.

### N-1 — FALLBACK 가드의 에러 메시지에 실제 `k` 타입을 실어줄 것

- **출처**: S-8 답변("정확함. 다만 …").
- **사용자 답변 원문**:
  > 정확함. 다만 Priority Fallback 이 type(k) == "string" 인 상황에서는 가장
  > 위에 Ref/Observer binding should be array index item, but got typeof k 처럼
  > 알려줄 필요는 있는듯 - 안 그러면 핸들러 미등록 이슈인지, MyRef = Ref 같이
  > 아에 잘못 쓴 이슈인지 분간이 안가서 최종 유저에게 혼선을 줄 여지가
  > 존재하는듯.
- **요구 내용**: `HANDLER_PRIORITY_FALLBACK` 가드(`Observer`/`Ref`/`PreRef`/
  `PostRef`의 동적 경로 가드)가 에러를 낼 때, 단순히 "배열 리터럴에만 놓을 수
  있음"이 아니라 **실제로 들어온 `k`의 타입을 메시지에 포함**할 것 —
  `Ref/Observer binding should be array index item, but got <typeof k>` 형태.
- **근거(사용자 논거)**: 메시지에 `k` 타입이 없으면 사용자가 두 원인을 구분할
  수 없다 — (a) 핸들러가 등록이 안 된 것인지, (b) `MyRef = Ref(...)`처럼
  named 자리에 잘못 쓴 것인지. 최종 사용자에게 혼선을 줌.
- **반영할 곳**: `base/source-state-plan.md` "동적 경로 가드" 절의 가드
  스케치, `base/ref-plan.md`의 `PreRef`/`PostRef` 동적 경로 가드, 그리고
  `base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op"
  절(FALLBACK 자리 서술).

### N-2 — 없는 Store 키는 "타입 에러"로 잡히면 충분 (구현 시 확인)

- **출처**: ST-1 답변.
- **사용자 답변 원문**:
  > 네, 맞고, Store<{ field: type }> 상 없는 네임에는 타입 시간에 Source 가
  > 없는것으로 나와 타입 에러만 나면 됩니다. 아마 지금 설계가 그럴것이예요
- **내용**: lazy `__index` 생성이 오타/동적 키로 Source를 무한정 누적하는
  트레이드오프는 **그대로 수용**. 방어선은 런타임이 아니라 타입 —
  `Store<{field: T}>`로 선언된 Store에 없는 이름을 쓰면 `type function`이
  합성한 결과 타입에 그 프로퍼티가 없어 **타입 에러**가 나야 한다.
- **확인 필요**: 사용자도 "아마 지금 설계가 그럴 것"이라며 단정하지 않았음 —
  `type function`으로 합성한 테이블 타입이 **미선언 프로퍼티 접근을 실제로
  거부하는지**(인덱서를 안 붙였을 때 Luau가 에러를 내는지) M0에서 확인할 것.
  ST-4의 스파이크(`luau-test/done/16-...`)에 이 음성 대조군이 있는지도 같이
  볼 것.

### N-3 — 동률 경고 print는 전역 디버그 플래그 `Quad.debug`로 게이팅

- **출처**: D-8 답변.
- **사용자 답변 원문**:
  > 동률 print 는 라이브러리가 debug 모드일 때만. (Quad.debug: boolean =
  > default false) 식이고, true 로 하면 디버깅 가능. 다른건 OK
- **내용**: `dispatch-core-plan.md`의 "디버그 모드 — 핸들러 등록/정렬 시점에
  동률 감지 시 print 경고" 항목은 무조건 찍는 게 아니라 **모듈 표면의
  불리언 플래그 `Quad.debug`(기본 `false`)가 `true`일 때만** 찍는다.
- **파급**: `Quad.debug`는 지금 어느 문서에도 없는 **새 공개 API 표면**이다 —
  `base/module-lifecycle-plan.md`(모듈 표면)와 `base/architecture.md`의 소스
  트리에 반영이 필요하고, `New()`/`Quad()` 다중 인스턴스화(A-3) 시 이 플래그가
  인스턴스별인지 전역인지도 같이 정해야 함. `Dispatch.listHandlers()`도 같은
  디버그 표면에 속하는지 확인 필요.

### N-4 — `NilHandler` 신설 요구 (`State<Slot|nil>`도 동작해야 함)

- **출처**: B-1 답변에 덧붙인 별건("이 답과는 연관 없는 말을 하자면").
- **사용자 답변 원문**:
  > State<Slot|None> 일 수도 있지만, State<Slot|nil> 이여도 작동은 함. 이것도
  > NoneHandler 유사하게 NilHandler 가 필요함. 오직 k=number v=nil 일 때만
  > 받고, NoneHandler 와 유사하게 retract 처리를 담당. 단, 재귀만 안 할 뿐임.
  > 혹은, NoneHandler 가 다시 NilHandler 가 불리도록 하는게 더 나을수도
  > 있겠다는 생각(단순 재귀로 NoneHandler 는 재귀처리만 담당함).
- **요구 내용**: 반응형 값이 `None`이 아니라 **진짜 `nil`** 을 내놓는 경우
  (`State<Slot|nil>`)도 정상 동작해야 하므로, **`NilHandler`를 신설**한다.
  - `isHandlable`: **`k == number` 이고 `v == nil` 일 때만** 매치.
  - 역할: `NoneHandler`와 마찬가지로 **retract 처리 담당**. 단 **재귀는 하지
    않음**(`NoneHandler`는 `nil`로 바꿔 재귀하는 게 일이지만, `NilHandler`는
    이미 `nil`이라 더 내려보낼 곳이 없음).
  - **사용자가 선호한 대안 구조**: `NoneHandler`는 **재귀 처리만** 담당하게
    두고, 그 재귀가 결국 `NilHandler`를 부르게 만드는 쪽이 더 깔끔할 수
    있음 — 즉 실질 정리 로직을 `NilHandler` 한 곳에 모으는 구성.
- **RF-4와 함께 봐야 함**: RF-4가 "`drive`는 `None` 스킵을 없애고 전부
  `process`에 태운다 + `NoneHandler`가 `k=number`에서 `setLength(0)`/
  `setOffsetSource(None)`을 등록한다"였는데, 여기에 `NilHandler`가 들어오면
  **그 등록 책임이 둘 중 어디에 있는지**를 같이 정해야 함(재귀 구조를
  택하면 자연히 `NilHandler` 쪽으로 모임).
- **반영할 곳**: `base/dispatch-core-plan.md`의 "`None` 센티널" 절(핸들러
  목록과 재귀 구조), `base/architecture.md` 소스 트리(`Dispatch/` 아래 파일
  목록), `base/dispatch-core-plan.md` "Length/Offset" 절의 등록 책임 규정.

### N-5 — `Attribute.Merged`와 `Attribute.Overridden`을 **둘 다** 제공 (열려 있던 결정 해소)

- **출처**: AT-4. `question.md` 3번에 "사용자 확인 대기"로 열려 있던 항목의
  답이며, **선택지 둘 중 하나가 아니라 제3안**이 채택됨.
- **사용자 답변 원문**:
  > 차라리 Merged, Overridden 을 제공하면 될것 같음. 전자는 에러를 내주고,
  > 후자는 그냥 조용히 덮어써주는것. 사용자 의도에 따라 달라질 부분이라
  > 분리해주는것이 이로워보임.
- **결정**: 이름 겹침의 처리 방식을 **API로 분리**한다.
  - `Attribute.Merged(a, b, ...)` — 같은 이름이 겹치면 **error**.
  - `Attribute.Overridden(a, b, ...)` — 겹치면 **조용히 뒤가 이김**(덮어쓰기).
  - 근거: 어느 쪽이 맞는지는 **사용자 의도에 달린 문제**라 프레임워크가
    하나로 정하지 말고 골라 쓰게 한다.
- **파급 / 정리할 것**:
  - `base/attribute-plan.md`의 "채택안 — `Tag`와 동형인 array-part 값 객체"
    API 목록에 `Attribute.Overridden` 추가, "열린 질문" 절의 해당 항목 해소
    처리, `.claude/question.md` 3번에서 제거.
  - **`Merged`/`Overridden`이라는 이름 쌍의 의미가 코퍼스 전체에서
    재정렬됨** — 지금까지는 `Merged`=무손실 합집합(`Tag`),
    `Overridden`=필드 단위 덮어쓰기(`Modifier`)로 **연산의 종류**를
    가르는 이름이었는데, `Attribute`에선 **충돌 시 정책**(error냐
    덮어쓰기냐)을 가르는 이름이 된다. `base/tag-plan.md`가 `Tag.Merged` 코드 주석에서 `Merged`를
    집합 합치기, `Overridden`을 이미 계산된 것 합치기로 대조해둔 서술과
    같이 볼 것.
  - **`Tag`에도 `Overridden`이 필요한가**는 자동으로 따라오지 않음 —
    `Tag`는 합집합이라 애초에 충돌 개념이 없음. 확인 불필요해 보이나
    정정 시 한 줄 명시해두면 좋겠음.

### N-6 — `SetAndDispose` 류 편의 콤비네이터 검토 (백로그 후보)

- **출처**: SL-2 답변.
- **사용자 답변 원문**:
  > 정확하나, source:apply(SetAndDispose( new )) 같은걸 구현해줄까는
  > 생각해보았음(단 여기서의 apply 는 source 를 넘겨주는 함수가 되어야함.).
  > Get해놓고 Set 이후 나중에 지우는게 편의성이 떨어지기 때문. 아니면 그냥
  > source 자체에 :콜론 메서드로 가능하게 하는걸 넣어줄까 생각은 하고 있음.
- **문제**: `dispose`는 "`Set`(언마운트) → 그 다음 `dispose`" 순서를
  요구하는데(SL-2), 그러려면 호출부가 **`Get()`으로 이전 값을 미리
  잡아두고 → `Set(new)` → 잡아둔 옛 값을 `dispose`** 하는 3단계를 매번
  손으로 써야 해서 편의성이 떨어진다.
- **후보 두 가지**:
  1. `source:Apply(SetAndDispose(new))` — 콤비네이터. **단 여기서의
     `Apply`는 `State`가 아니라 `Source`를 넘겨주는 함수여야 함**(사용자
     명시) — 지금 확정된 `state:Apply(factory)`는 `factory(self)`에
     `State`를 넘기므로, `Source` 전용 변형이 필요한지 같이 정해야 함.
  2. `Source`에 **콜론 메서드**로 직접 얹기(예: `source:SetAndDispose(new)`).
- **미결**: 어느 쪽을 택할지, 그리고 애초에 이번 범위에 넣을지 백로그로
  뺄지. `state:Apply`의 시그니처(`(State<T>) -> U`)에 영향이 갈 수 있으므로
  M3 착수 전에 방향만이라도 정해두는 게 좋음.

### N-7 — UI 숏핸드가 만든 자식을 `FindFirstChild` 대신 `Relate`로 기억할 것

- **출처**: UI-1 답변.
- **사용자 답변 원문**:
  > 다만, FindFirstChild 는 비용이 ref 저장보단 비쌈. spring 등으로 움직일
  > 수도 있다 생각하면 릴레이션으로 저장하는것도 좋은 생각. 각 숏핸드가
  > 만들어낸 요소의 프로퍼티 세팅은 새로운 dispatch.process(target,k,v) 로
  > 위임해 tween 등이 자연스럽게 가능.
- **문서가 주장하는 것**: `base/ui-shorthand-plan.md`는 재사용 대상을
  **"quad가 이전에 만든 고정 이름(`_quad_corner`류) 자식"**으로 한정하는데,
  그 "찾기"를 어떻게 하는지는 v1처럼 **이름으로 조회**(`FindFirstChild`)하는
  것으로 읽힌다.
- **요구 내용**: 이름 조회 대신 **`Relate`에 `(inst, 숏핸드키) → child`로
  저장**해서 다시 찾을 것. 근거는 (a) `FindFirstChild`가 참조 저장보다
  비싸고, (b) **spring 등으로 자식이 계속 움직이는** 상황이면 그 조회가
  반복 비용이 됨.
- **주의 — 고정 이름 규약을 없애자는 뜻은 아님**: 이름(`_quad_corner`류)은
  디버깅 가시성(`research/debug-tooling-plan.md` 9번)과 "사용자가 만든
  `UICorner`를 건드리지 않는다"는 판정에 여전히 필요해 보임. `Relate`는
  **조회 경로**를 대체하는 것이고, 두 가지가 어떤 관계인지(이름은 표시용,
  릴레이션은 조회용) 정정 시 명시할 것.
- **주의 — `Relate` 키 전제**: `inst`-키 `Relate`는 gcconn 셋업 위에서만
  성립하는데(RE-1/L-1), 숏핸드가 만드는 **자식**도 quad가 만든 Instance라
  그 셋업을 거치는지 확인 필요.

### N-8 — `DI` → `D` 리네임 **확정** (2026-08-18) + 전수 반영 목록

- **출처**: 사용자가 이 QA 라운드 중 직접 확정("이거 하면서 DI => D 확정하자").
  2026-08-08 용어 정리 라운드부터 `question.md` **1순위**로 열려 있던 항목.
- **확정 내용 두 갈래** (사용자 판정):
  1. **네임스페이스/모듈 자체는 `DI` → `D`.** `D.Frame` / `D/init.luau` /
     `D.InstSlot` / `D.FrameModifier`.
  2. **"특수 DI 키"라는 설명용 표현은 `D`로 바꾸지 않고 "특수 키"로
     단순화.** (사용자 선택: `"특수 키"로 단순화`) — "특수 D 키"라고 쓰지
     않는다. 수식어 자체를 빼도 문맥상 통한다는 판단.
- **`D`로 가는 근거(이미 기록돼 있던 것)**: (1) "Instance" 전용 개념이 아니라
  quad-* 전반의 declare 요소로 확장 가능한 이름, (2) 엔진 종속 없이 다른
  백엔드에서도 재사용 가능, (3) `D.FrameModifier`류 타입 프리픽스가 짧아야
  한다는 실용적 제약. 원래 이름 `DI`의 문제는 **"Dependency Injection"과
  완전히 겹쳐 실제로 오해가 있었던 전례**가 있다는 것.
- **⚠️ 같이 정해야 할 것 — 한 글자 식별자의 검색성/자기설명력 보완책**
  (사용자 선택: `예, 같이 넣어둘 것`). 2026-08-08에 `D`를 확정 못 하고 미룬
  **유일한 사유**가 이거였음 — `D` 한 글자는 grep도 어렵고 이름만으로
  뜻이 안 드러난다. 정정 시 아래를 같이 정할 것:
  - 문서에서 `D`가 처음 나올 때 **항상 "Declarative"로 풀어쓰는** 규약을
    둘지(예: "`D`(Declarative) 네임스페이스").
  - `conventions.md`의 "문서 표기 규약"에 넣을지, 아니면 `base/architecture.md`
    "코드 스타일 — 네이밍 케이싱" 절에 넣을지.

#### 반영 대상 — 전수 (2026-08-18 기준 grep, `session/`·`session-summary.md`·`initreq/` 제외)

**갈래 ① `DI` → `D` (네임스페이스/모듈)**

| 파일 | 줄 | 무엇 |
|---|---|---|
| `base/architecture.md` | 195 | 소스 트리의 `DI/` 디렉토리 + 그 아래 `init.luau` 주석 |
| `base/slot-plan.md` | 98 | `DI.InstSlot = Slot<<Instance>>` — **"(`DI` 네임스페이스 이름 자체는 `question.md` 1번 용어정리 대기 중…)" 괄호도 삭제** |
| `base/bind-system-plan.md` | 126 | *"**"DI"는 Dependency Injection이 아니라 "Declarative Instance"**"* — 이 문단이 개명의 근거 자체이므로 **재작성**(왜 `D`가 됐는지로) |
| `base/bind-system-plan.md` | 130 | `DI.Frame` vs `DI.New<<Frame>> "Frame"` |
| `base/bind-system-plan.md` | 199 | 열린 질문 *"**`DI`(또는 다른 이름) 등 정확한 모듈 이름**"* — **항목째 삭제**(해소됨) |
| `base/modifier-plan.md` | 313 | "DI 쪽 '제네릭 생성자 함수 하나 + …' 패턴 재사용" |
| `base/ui-shorthand-plan.md` | 74 | "quad-roblox의 각종 타입(DI 인스턴스 타입, Modifier 타입 등)" |
| `base/attribute-plan.md` | 66 | "이미 확정된 DI 인스턴스 생성 패턴" |
| `base/attribute-plan.md` | 449 | 표의 `백엔드(quad-roblox의 `D`/`DI` 층)` — **이미 병기 중**, `D`로 단일화 |
| `base/attribute-plan.md` | 492 | "최종 이름은 다른 가칭들(`DI`→`D`/…)과 함께 대기열" — 목록에서 제거 |
| `base/dispatch-core-plan.md` | 628 | `그 백엔드(quad-roblox의 `D`/`DI` 층)` — **이미 병기 중**, `D`로 단일화 |
| `ROADMAP.md` | 333 | 체크박스 `DI/init.luau`(제네릭 생성자 + ~25개 정적 필드) |
| `ROADMAP.md` | 429–430 | `DI.InstSlot` + "`DI` 네임스페이스 이름 자체는 `question.md` 1번" 대기 문구 |
| `ROADMAP.md` | 726 | `quad-roblox의 `D`/`DI` 층` — `D`로 단일화 |
| `ROADMAP.md` | 825 | 용어 정리 스윕 체크박스의 `State`/`DI`/`Slot` 목록 — `DI` 제거 |
| `question.md` | 43, 46, 47 | **`DI` 항목 자체** — 해소 처리해 `archive/question-resolved.md`로 이전(`Merge`→`Overridden` 등 기존 해소 항목과 같은 방식). 46–47행의 파급(`DI.FrameModifier`류 타입 프리픽스)은 **이번 리네임에 실제로 포함**되므로 반영 목록에 흡수 |
| `question.md` | 183 | "M3 Source/M5 DI 생성자" |
| `todos.md` | 95 | 용어 정리 목록의 "`DI`→`D`(1순위)" — 해소로 제거 |
| `research/additional-primitives-plan.md` | 21 | 프리미티브 나열 `.../`Slot`/`DI`)` |
| `research/debug-tooling-plan.md` | 5, 126, 379, 460, 479 | "Source/DI 생성자", `DI/init.luau`, "DI 제네릭 생성자", "Dispatch/DI", "M5(quad-roblox DI 제네릭 생성자)" |
| `research/pre-implementation-audit.md` | 537, 538, 541 | "DI 쪽 패턴 재사용", "DI 타입 생성 계층(M5)", "M5 DI 체크리스트" |
| 이 문서 자신 | BS-2의 파급 문단 | `DI/init.luau` 주석과 `D`/`DI` 생성기 언급 |

**갈래 ② "DI 키" → "특수 키" (설명용 표현)**

| 파일 | 줄 |
|---|---|
| `base/architecture.md` | 37, 42, 191 |
| `base/onchange-plan.md` | 20, **76(헤딩 — 아래 ⚠️)** |
| `base/attribute-plan.md` | 33, 74 |
| `base/lifecycle-hooks-plan.md` | 28, 82, 83, 106, 111, 186, 294, 296, 300, 303 |
| `base/dispatch-core-plan.md` | 315 |
| `base/bind-system-plan.md` | 164 |
| `base/ref-plan.md` | 637 |
| `ROADMAP.md` | 135, 711 |
| `.claude/README.md` | 64 |
| `luau-test/README.md` | 81, 117 |

- **⚠️ 헤딩 1개 + 그 헤딩을 절 인용하는 곳 1개가 짝으로 묶여 있음 — 반드시
  같은 커밋에서 함께 고칠 것.**
  - `base/onchange-plan.md:76` 의 `## 다른 특수 DI 키와의 대조` (헤딩)
  - `base/lifecycle-hooks-plan.md:300` 이 그 절을 `"다른 특수 DI 키와의 대조"`
    로 **절 인용**하고 있음.
  - 한쪽만 고치면 `doc-check.py`가 **절 참조 불일치 ERROR**로 잡아 커밋이
    막힌다(`conventions.md`의 "절 인용 규약"이 ERROR로 승격돼 있음).
- **`base/ref-plan.md:637` / `base/lifecycle-hooks-plan.md:106` 은 같은 문장의
  원문·인용 관계** — `lifecycle-hooks-plan.md`가 `ref-plan.md`의 문장을
  blockquote로 그대로 옮겨 적었으므로 **문구가 계속 일치해야** 함.
- **archive/·session/·session-summary.md 는 건드리지 말 것** — 히스토리
  문서라 당시 표기 그대로 두는 게 `conventions.md` 관례
  (`archive/tag-hash-key-model-reversed.md` 제목의 "DI 키" 등).

#### 반영 후 확인

- `python3 .claude/tools/doc-check.py` → **ERROR 0**(특히 위 절 인용 짝).
- `grep -rn '\bDI\b' --include='*.md' . | grep -v '/initreq/\|/session/\|session-summary.md\|/archive/'` → **0건**이어야 함.
- 인덱스 3층 갱신: `.claude/README.md`, `question.md`(항목 이전),
  루트 `ROADMAP.md` — `conventions.md`의 중대 변경 핸드오버 체크리스트 6번.

### N-9 — `New`를 커링으로 명시하고 `D`를 "처리 없는 별칭 테이블"로 규정 (사용자 제안)

- **출처**: 사용자 제안(2026-08-18, N-8 확정 직후).
- **사용자 발언 원문**:
  > D.Frame 같은건 New 에서 커링되어, New 함수는 New(name)({}) 되는게 이롭다
  > 생각하는데 어떰? 실제 사용 상 New<<Frame>> "Frame" {...} 로도 쓸 수 있고,
  > D 에선 별다른 처리 없이 D.Frame = New<<Frame>> "Frame" :: (({...타입명시})
  > -> Frame) 으로 쉽게 만들 수 있다는게 내 생각임.
- **제안 내용**:
  1. **`New`는 커링** — `New(name)`이 생성자 함수를 반환하고, 그걸 다시
     props 테이블로 호출: `New(name)({...})`.
  2. **직접 사용도 같은 모양** — `New<<Frame>> "Frame" {...}`
     (Lua 문법상 `New("Frame")({...})`).
  3. **`D`는 별다른 처리가 없다** — 필드마다
     `D.Frame = New<<Frame>> "Frame" :: (({...타입명시}) -> Frame)` 로
     캐스팅만 얹은 **순수 별칭 테이블**.
- **지금 문서와의 관계 — 뒤집는 게 아니라 명시화**:
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절이
  인용한 PA님 패턴이 이미 `constructor.Frame = new("Frame")` 이라 **사실상
  커링이었음** — 다만 (a) "커링이다"라는 것과 (b) 2단계 호출 계약과
  (c) `New(name)({...})` / `New "Name" {...}` 라는 **직접 호출 형태**가
  문서에 명시된 적이 없다. BS-1에서 "eager 정적 테이블"은 이미 확인됐으므로
  이 제안은 그 위에 "그 정적 필드가 정확히 무엇인가"를 채우는 것.
- **BS-2와 정합적** — 필드별 `::` 캐스트로 타입을 주는 방식은, `D` 생성기가
  어차피 클래스별 props 타입(이벤트 콜백 시그니처 포함)을 뽑아야 한다는
  BS-2의 결론과 맞물린다. 기존에 인용돼 있던
  `new<ClassName>(className): from<index<UIInstances, ClassName>>`
  (타입 레벨 인덱싱)보다 생성기 입장에서 단순함.
- **기각된 "2트랙"과 혼동하지 말 것** — 같은 절이 기각한 건
  *"필드=1급 타입 경로, 문자열=폴백"* 이라는 **능력 차이**였지 `New`라는
  이름이나 문자열 호출 자체가 아니었다. 이 제안은 오히려 **두 형태가 완전히
  같은 것**(하나가 다른 하나의 미리 적용된 결과)임을 못박는다.

#### 후속 확정 (2026-08-18, 같은 대화에서 1~4번 전부 확정)

**2. 이름은 대문자 `New`로 확정.** 사용자 답변: *"2. New입니다."*
지금 코퍼스는 둘 다 씀 — `bind-system-plan.md`가 PA님 코드를 인용할 땐
소문자 `new(className)`, 같은 절의 (기각된) 2트랙 구상엔 대문자
`DI.New<<Frame>> "Frame"`. **대문자로 통일**하고, `base/architecture.md`의
"코드 스타일 — 네이밍 케이싱" 절에 `D.New`가 어느 부류로 들어가는지도
같이 적을 것.

**3. `D`는 전부 코드 자동 생성이 맞음 — `New` 호출문까지 생성기가 찍는다.**
- **사용자 답변 원문**:
  > 3. 코드로 자동 생성되는것이 맞는게, index 가지고만 하면
  > MouseButton1Click 이 RBXScriptConnection 이 되어버림. 처리하기 힘들다
  > 생각하는게, lsp 마다 Frame 타입을 어떻게 다루냐 다를 수 있음. 게다가
  > T|State<T> 같은것 또한 처리해야하는데, 이걸 타입 함수로 다 처리하게
  > 만드는것 보다 단순히 D 파일이 자동 생성되는게 좋다고 생각함. 그리고
  > 코드 생성 산출물인가는 맞음, 전부 코드 생성이나, New 같은것도 생성기에서
  > 같이 적어주어야할 부분.
- **⚠️ 이건 단순 확인이 아니라 `bind-system-plan.md`가 인용한 시그니처를
  부정한다.** 그 문서는 PA님 코드를 그대로 인용해
  `new<ClassName>(className): from<index<UIInstances, ClassName>>` —
  즉 **타입 레벨 인덱싱**으로 클래스 타입을 뽑는 모양인데, 사용자가 든
  세 가지 이유로 그 방식만으로는 부족하다:
  1. **이벤트 필드가 콜백 타입이 안 된다.** Roblox 타입 정의에서
     `MouseButton1Click`은 시그널 계열 타입이라, 인덱싱으로 뽑으면 그
     타입이 그대로 나와버리고 quad가 원하는
     `((...) -> ())?` 콜백 시그니처가 안 나옴. **이게 곧 `BS-2`가 요구한
     "생성기가 이벤트 필드의 콜백 타입까지 만들어야 한다"의 직접적 근거** —
     두 항목은 같은 문제의 양면이므로 반드시 같이 처리할 것.
  2. **LSP마다 `Frame` 타입을 다루는 방식이 다를 수 있어** 타입 함수/인덱싱에
     의존하는 게 위험하다.
  3. **`T | State<T>`(그리고 `T | Tween<T>`, `None` 등)까지 타입 함수로
     조립해야 하는데**, 그럴 바엔 `D` 파일을 통째로 생성하는 쪽이 단순하다.
- **따라서**: `D`는 타입뿐 아니라 **`D.Frame = New<<Frame>> "Frame" :: (...)`
  라는 값 선언까지 생성기가 찍어내는 파일**이다. 손으로 쓰지 않는다.
- **반영**: `base/bind-system-plan.md`의 PA님 시그니처 인용을 이 결론에 맞게
  다시 쓸 것 — "PA님 코드 그대로 채택"이라는 프레이밍 자체가
  **타입 조립 방식에 한해서는 더 이상 정확하지 않음**(호출 모양은 그대로
  채택, 타입은 생성으로 감).

**4. 생성 범위는 "GUI에 쓰이는 모든 인스턴스" — 전량은 부적합.**
- **사용자 답변 원문**:
  > 4. 는 모든 인스턴스를 넣기는 부적합함. GUI에 쓰이는 모든 인스턴스를 자동
  > 생성한다로 잡아줘도 좋을것으로 보임. 안 그럼 D 파일이 너무 커짐.
- 즉 기존 **"자주 쓰는 ~25개"** 도 아니고 **Roblox 전체 클래스**도 아닌,
  **"GUI에 쓰이는 것 전부"** 가 기준. 근거는 파일 크기 — 전량 생성하면
  `D` 파일이 너무 커진다.
- **반영**: `base/bind-system-plan.md`가 생성 대상을 `~25개`(자주 쓰는
  `Frame`/`TextButton`/`UICorner` 등, `UIInstances` 타입 테이블 등록분)로
  적어둔 서술과, `base/architecture.md` 소스 트리의
  `# 제네릭 생성자 + ~25개 정적 필드(UIInstances)` 주석을 이 기준으로 교체. **"GUI에 쓰이는"의 정확한 판정
  기준**(Roblox API 덤프에서 무엇을 GUI로 볼 것인가 — `GuiObject` 하위 +
  `UIComponent` 하위 + `LayerCollector`류 등)은 생성기 구현 시점에 정할
  것으로 남김.

**1. `D`에 없는 클래스는 느슨하게 `any` — 필요하면 사용자가 직접 채운다.**
- **사용자 답변 원문**:
  > a. 느슨하게 any 로 하고, 필요하면 이를 직접 구현 가능하게 둡니다. cast 를
  > 하든, 유저의 자유
- **내용**: `D`가 커버하는 범위(위 4번의 "GUI에 쓰이는 모든 인스턴스") **밖**의
  클래스를 `New<<X>> "X" {...}` 로 직접 쓰면 props 타입은 **느슨하게 `any`**.
  quad는 그 자리에서 타입 안전성을 보장하지 않고, 필요하면 **사용자가 직접
  좁힌다** — `::` 캐스트를 쓰든 자기 래퍼를 만들든 자유.
- **왜 이게 자연스러운가**: `D.Frame` 자체가 애초에
  `New<<Frame>> "Frame" :: (({...}) -> Frame)` — **캐스트 한 줄**이다(위 N-9
  본문). 즉 생성기 산출물이 특권적인 게 아니라, **사용자가 임의 클래스에
  대해 똑같은 한 줄을 직접 쓸 수 있다.** "직접 구현 가능하게 둔다"가 새 확장
  지점을 만든다는 뜻이 아니라, 이미 있는 패턴을 그대로 쓰면 된다는 뜻.
- **파급 — BS-1의 서술 수정 필요**: `base/bind-system-plan.md`가 확정해둔
  *"제네릭 생성자 함수 하나가 알려진 타입과 모르는 타입을 **전부 커버**"* 는
  이제 정확하지 않다. **런타임은 여전히 전부 커버하지만 타입은 아니다** —
  `D` 범위 안은 생성된 정확한 타입, 밖은 `any`. 그 문장을 이 구분이 드러나게
  다시 쓸 것.
- **이걸로 N-9의 열린 항목은 전부 닫힘** — [2026-08-18 기준] 반영도 같은 날 완료.

#### 반영할 곳

- `base/bind-system-plan.md` "인스턴스 생성 / 이벤트 네이밍 인체공학" 절 —
  커링 계약과 두 호출 형태를 본문에 추가, PA님 시그니처 인용을 이 결론에
  맞춰 갱신.
- `base/architecture.md` 소스 트리의 `D/init.luau` 주석(현
  `DI/init.luau # 제네릭 생성자 + ~25개 정적 필드(UIInstances)`) — N-8과
  같은 줄이라 **한 번에 같이 고칠 것**.
- `ROADMAP.md`의 `D/init.luau` 체크박스(현 333행) 및 M5 관련 항목.
- `base/slot-plan.md`의 `D.InstSlot = Slot<<Instance>>` — 이것도 같은
  "별칭 테이블" 패턴인지(즉 `D`가 인스턴스 생성자 말고 타입 별칭도 담는지)
  확인 필요.

---

## 부수 발견 — 오탈자/표기 불일치 (사용자 판정 불필요, 확인만 됨)

여기 있는 것은 설계 오류가 아니라 **문서 표기 실수**다. 위 절들과 달리
사용자 회신을 기다릴 필요 없이 정정 라운드 때 같이 고치면 된다.

- **`architecture.md` "Store/State/Source 온톨로지 — 확정됨" 절의 `.value`
  (소문자)** — A-6에서 **`ref.Value`(대문자)가 맞음**으로 확인됨. 같은 문서
  소스 트리 주석(`Ref.luau` 행)은 `.Value`로 맞게 적혀 있어 한 문서 안에서
  두 표기가 섞여 있음. 다른 문서에도 `.value`가 퍼져 있는지 정정 시 grep
  필요.
- **`source-state-plan.md` "`:Compute(fn)`의 선택적 두 번째 인자" 절의
  `fn(value, previous)`** — S-2에서 최종 시그니처가
  **`fn(self, previous?, ...deps)`** 로 확인됨. 그 절만 `self`가 lazy 핸들로
  통일되기 전의 구 표기(`value`)로 남아 있어, 그 절만 읽으면 첫 인자가 raw
  값인 줄 오해하게 됨.

---

## 진행 로그

**1라운드(2026-08-18) 완료.** `base/` 25개 문서를 의존성 순서로 훑으며
`AskUserQuestion`으로 확인. 문서당 3~4개 주장씩, 총 22배치.

| 문서 | 결함/열린 항목 | 신규 요구 |
|---|---|---|
| `architecture.md` | A-3 | — |
| `source-state-plan.md` | S-1, S-12 | N-1 |
| `store-plan.md` | ST-2 | N-2 |
| `lifecycle-pattern.md` | (S-1의 진원지) | — |
| `dispatch-core-plan.md` | D-1, D-5, D-6, D-7 | N-3 |
| `relate-plan.md` | RE-1 | — |
| `modifier-plan.md` | M-3 | — |
| `ref-plan.md` | R-1, R-3, RF-4 | N-4 |
| `brand-plan.md` | B-1 | — |
| `attribute-plan.md` | AT-1 | N-5 |
| `slot-plan.md` | SL-1, SL-3 | N-6 |
| `effect-plan.md` | E-2 | — |
| `event-plan.md` | EV-1 | — |
| `bind-system-plan.md` | BS-2 | — |
| `ui-shorthand-plan.md` | — | N-7 |
| (전역 이름·표면) | — | **N-8 `DI`→`D`**, **N-9 `New` 커링** |
| `blocker-plan.md` / `tag-plan.md` / `tween-plan.md` / `typing-limits.md` / `component-composition-plan.md` / `module-lifecycle-plan.md` / `onchange-plan.md` / `purity-and-effects-plan.md` / `fallback-plan.md` / `lifecycle-hooks-plan.md` | **전부 통과** | — |

**아직 안 본 것 (2라운드 대상 — 새 파일 `pre-implementation-qa-round2.md`에 쓸 것)**:
- `slot-plan.md`의 `:List` 내부(`reconcile` 구현, `keyFn`, `userdata`
  생명주기, 구독 시점, Slot-in-Slot 재귀)와 `dispatch-core-plan.md`의
  `recompute`를 **손으로 트레이싱**하는 검증 — 이번 라운드는 "확정된 주장이
  맞는가"를 물었지 의사코드를 실행해보진 않았다.
- `reference/` (v1 스냅샷, 프레임워크 비교) — 확정 문서가 아니라 제외했으나,
  `base/`가 근거로 인용하는 사실들이라 인용이 정확한지는 미검증.
- `research/` 11개 — 확정 전이라 제외.
- 루트 `ROADMAP.md`의 마일스톤 분할이 이번 발견들과 맞는지.
