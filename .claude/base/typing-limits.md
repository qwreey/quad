# 타입 시스템의 한계와 그 대응 — quad 전역 규약

**이 문서는 "Luau 타입 시스템이 quad 설계에 대해 못 해주는 것"을 한
군데 모은 확정 문서입니다.** 각 한계마다 (a) 정확히 무엇이 안 되는가,
(b) 그래서 우리가 코드/문서에서 뭘 해야 하는가, (c) 언제/어떻게 풀릴
전망인가를 적습니다.

**왜 따로 모으는가**: 이 한계들은 여러 `base/` 문서에 흩어져 각자
캐비엇으로 붙어 있었고, 그러다 보니 (1) 새 API를 설계할 때 같은 벽에
매번 새로 부딪히고, (2) "이건 우리 설계 문제인가 Luau 문제인가"를
매번 다시 판정하고, (3) 나중에 Luau가 고쳐줬을 때 **어디를 되돌려야
하는지** 알 수 없었습니다. 2026-08-13 열세 번째 세션에 가장 큰 한 건
(아래 1번)이 확정되면서 같이 정리했습니다.

---

## 0. 대전제 — Luau의 한계를 우회하려고 타입/API를 비틀지 않는다

**[2026-08-13 확정, 사용자]**

> "지금으로써 quad 프로젝트가 타입을 비틀어 해당 시도를 하는 건 전혀
> 적합하지 않고, 이것은 상위의 Luau의 현 한계다. RFC와 해당 이슈
> 해결의 수혜를 받게 될 때 해결될 이슈로써, 당장 우리가 할 수 있는
> 바 없다."

이 원칙이 아래 모든 항목에 우선합니다. 구체적으로:

- **API의 자연스러운 모양을 타입 사정으로 바꾸지 않는다.** 리액티브
  파생값 API가 `Compute<U>(...) -> State<U>` 모양인 건 본질이고,
  Luau가 지금 그걸 못 다룬다고 해서 반환 타입을 `any`로 열거나,
  API를 다른 모양으로 재설계하거나, 제네릭을 포기하고 타입별 코드를
  생성하는 건 **전부 하지 않습니다.**
- **이유는 "게을러서"가 아니라 "그게 더 비싸서"입니다.** 지금 비틀어
  놓으면 (a) 비튼 만큼 복잡도와 사용자 인체공학 손해가 영구히
  남고, (b) Luau가 고쳐졌을 때 자동으로 수혜를 받는 게 아니라 비튼
  걸 되돌리는 별도 마이그레이션이 필요해집니다. 아래 1번의 실측이
  이걸 구체적으로 보여줍니다 — **지금 그대로 두면 Luau 쪽 수정만으로
  코드 변경 없이 풀립니다.**
- **대신 반드시 하는 것**: (1) 한계를 이 문서에 명시, (2) 사용자
  코드가 취해야 하는 관례를 명시, (3) 추적 링크(RFC/이슈)를 남겨
  나중에 되돌릴 지점을 알 수 있게 함.

**예외**: 그 한계를 우회하는 방법이 *비트는 게 아니라 그냥 더 나은
설계*인 경우엔 당연히 채택합니다(아래 1번의 "쪼개기"가 실제로 그런
사례 — 코드 생성 없이 타입 선언 두 개로 끝나고, 나중에 Luau가
고쳐져도 손해가 없음).

### ⭐⭐ [2026-08-25 신설, 사용자] 타입 함수는 **진단을 띄우는 데까지만** 쓴다

**사용자 확정**: *"어쩌면 타입함수는 타입이 못 잡는 문제를 에러로 띄우기
위한 정도 이상으로 가지 않는게 이로울 수도 있습니다."*

- **허용**: 타입이 못 잡는 오용을 **컴파일 타임 에러로 만드는** 용도.
  `type-version-check`의 `CheckVersion`(버전 불일치를 사람이 읽을
  메시지로), Store의 `CheckReservedKeys`(예약 키 충돌)가 그 사례다
  (**[2026-08-26 이름·인자 정정, 8라운드 `H-112`]** 옛 이름은 `CheckReserved`
  였고 `T`를 통째로 받았는데, 그 배선은 실사용 `T`에서 아예 안 돈다 — `T`에
  실리는 `Source<T>`가 §1 누수로 `*error-type*`을 품기 때문. 지금은
  `keyof<T>`만 받는다). 둘 다 **검증만 하고 결과 타입을 만들지 않는다**
  (**[2026-08-26 재정정, `/code-review high`]** 여기 *"둘 다 `T`를 검증만 하고
  그대로 통과시키고"*라고 이어졌는데, `CheckReservedKeys`에 대해선 **양쪽 다
  거짓**이다 — `T`가 아니라 `keyof<T>`를 받고, `T`를 통과시키는 게 아니라
  `types.singleton(true)`를 팬텀 필드에 돌려준다. 이 §0이 "무엇이 합법적인
  타입 함수인가"의 소스라, 그대로 읽으면 `H-112`가 **유효한 Store 전부에
  스퓨리어스 에러**를 낸다고 실측한 그 `CheckReserved<T>` 배선을 다시
  도출하게 된다).
  `error()`가 아니라 `print(...)` + `return types.never`를 쓴다.
- **안 함**: **접근 타입/결과 타입을 합성**하는 용도.
- **왜**: 그 선을 넘으면 §6이 실측한 함정(합성을 거친 값은 이후 제네릭
  self 체이닝이 조용히 깨짐)과 §5가 폐기한 한계(바깥 별칭 참조 불가,
  메소드 self 파라미터 불변)를 그대로 떠안는다.
- **⚠️ `index<>`/`keyof<>`도 타입 함수다** — Luau가 predefine해둔 것일
  뿐 성질은 같다(**사용자 지적**: *"구현을 뜯어보면, 루아우에서
  프리디파이닝한 타입함수임. 타입함수가 가지는 고질적 문제를 그대로
  가져요."*). 실제로 2026-08-25에 `WrapStore`를 버리고 그쪽으로 갈아탔다가
  **같은 날 철회**했다 — 그 조합의 `Self` 제네릭을 거치면 **콜백 파라미터
  추론이 깨진다**(평범한 레코드 필드에선 정상, 실측 대조).
  경위는 `archive/store-value-field-redesign-withdrawn.md`.

---

## 1. ⭐ 재귀 제네릭이 다른 타입 인자로 자기를 반환하면 타입 안전성이 조용히 사라짐

**실측 근거: `audit/type-recursion-issue/`**(REPORT.md + `spikes/`의 재현
스파이크 — 개수는 폴더가 소스). 이게 이 문서에서 가장 크고, 가장 넓게
영향을 주는 항목입니다.

### 무엇이 안 되는가

`Compute<U>(self: State<T>, fn) -> State<U>`처럼 **자기 자신과 같은
이름의 재귀 타입을, 자기 타입 파라미터(`T`)와 다른 인자(`U`)로 다시
감싸서 반환**하면, 반환 타입이 실제로는 해소되지 않고 Luau 내부의
`Unifiable<Error>`로 **조용히** 샙니다.

**"조용히"가 핵심입니다** — 컴파일 에러가 나서 막히는 게 아니라,
진단 0건으로 통과한 뒤 그 결과에 대한 타입 체크만 사라집니다:

```lua
local s = n:Compute(function(x) return tostring(x:Get()) end) -- s는 State<string>이어야 함
local wrong: number = s:Get()   -- ❌이어야 하는데 에러 안 남
```

`luau-analyze` / `luau-analyze --annotate` / `luau-lsp`(새 솔버)
세 경로 전부 동일 — 도구 문제가 아니라 Luau 자체의 현 한계입니다.

### 정확한 경계 (오해 방지 — 이것들은 멀쩡함)

실측으로 좁힌 결과 **"제네릭을 감싸서 반환하는 것" 자체는 문제가
아닙니다.** 아래는 전부 정상 작동합니다:

| 패턴 | 상태 |
|---|---|
| 같은 인자로만 재귀(`-> State<T>`, `U` 없음) | ✅ 정상 |
| 재귀 아닌 컨테이너에 담아 반환(`-> Box<U>`) | ✅ 정상 |
| 감싸지 않고 그대로 반환(`-> U`) | ✅ 정상 |
| 콜백 **파라미터**의 타입 추론 | ✅ 정상(아래 "쪼개기" 적용 시) |
| 콜백 **안**의 로직(원본 값을 어떻게 다루는지) | ✅ 정상 |
| 명시 주석 **이후** 다운스트림 전체 | ✅ 정상 |
| **자기 이름을 다른 인자로 감싸 반환**(`State<T>` → `State<U>`) | ❌ **이것만** |

즉 구멍은 정확히 **"그 한 줄이 진짜 그 타입을 만드는가"** 하나로
좁혀집니다.

### 그래서 우리가 하는 것 — ① 명시적 타입 바인딩 강제

**파생 State를 만드는 자리마다 결과 타입을 `:` 주석으로 명시합니다.**

```lua
-- ✅ 이렇게
local label: State<string> = count:Compute(function(c) return tostring(c:Get()) end)

-- ❌ 이렇게 두면 이후 코드 전체의 타입 체크가 사라짐
local label = count:Compute(function(c) return tostring(c:Get()) end)
```

주석이 그 한 줄의 RHS를 검증해주진 않지만(그게 위의 구멍),
**다운스트림에는 정확히 바인딩됩니다** — 실측으로 확인:
잘못된 사용(`local bad: number = label:Get()`)도, 없는 메소드
호출(`label:NoSuchMethod()`)도 정상적으로 에러가 납니다. 그래서
"한 줄만 못 믿고 나머지 코드베이스 전체는 안전"한 상태가 됩니다.

이건 **API 문서/예제/튜토리얼에도 그대로 반영해야 하는 관례**입니다
(사용자가 무주석으로 쓰면 조용히 타입 안전성을 잃으므로) —
`research/documentation-plan.md`/`documentation-content-map.md`가
문서 작성에 들어갈 때 이 관례를 초심자 트랙에 넣을 것.

### 그래서 우리가 하는 것 — ② 타입 선언은 "데이터부/메소드부" 쪼개기

위 1번과 별개로, **콜백 파라미터가 무주석일 때 추론이 안 되는 문제**는
진짜로 풀립니다. 원인은 "로컬 제네릭 `U`를 가진 메소드가 자기를
재귀 참조하는 타입의 필드로 선언돼 있다"는 것이고, 그 필드가 참조하는
self 타입에서 자기 자신(`Compute`)을 빼면 됩니다:

```lua
export type StateData<T> = {
	Get: (self: StateData<T>) -> T,   -- 자기 자신만 재참조(Compute를 모름)
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
	-- self / 콜백 파라미터 둘 다 StateData<T>를 가리킴
}
```

- 이러면 `state:Compute(function(s) return s:Get() * 2 end)`가
  **무주석으로 통과**하고, `s`에 대한 타입 체크도 진짜로 살아있습니다
  (없는 필드 접근하면 정상적으로 에러남).
- **코드 생성이 필요 없습니다.** `State<T>`는 여전히 진짜 제네릭이고,
  손으로 쓰는 타입 선언이 하나 늘 뿐입니다. (한때 검토했던 "T별로
  구워서 인라이닝"은 채택 안 함 — 0번 대전제 위반이고, 제네릭을
  없애버려서 나중에 Luau가 고쳐져도 수혜를 못 받음.)
- **[2026-08-29 M2 단위 4 실측] `:Apply`의 파라미터는 교집합 오버로드로 선언한다** —
  `(<U>(self, fn: (State<T>) -> U) -> U) & ((self, obj: { __apply: (any, any) -> any }) -> any)`.
  유니온 하나(`((State<T>) -> U) | { __apply: … -> U }`)로 두면 `Blocker`처럼 필드가
  더 있는 객체가 제네릭 `U` 자리에서 너비 서브타이핑을 못 받아 `state:Apply(blocker)`가
  strict에서 막힌다(인덱서 `[string]: any`로 열어도 같다 — `luau-test/done/26-*`).
  객체 쪽 반환이 `any`라 결과는 명시 주석(①과 같은 관례). `qa-request/m2-implementation-round11.md` `H-179`.
- **캐비엇**: 콜백이 받는 `s`는 `StateData<T>`라 `Compute`/`With`가
  없습니다. 콜백 안에서 다시 `s:Compute(...)`를 부르는 자리
  (`:Apply`의 factory가 대표적)는 이 방식으로 못 풀고
  `function(self: State<T>)`처럼 파라미터 주석이 필요합니다 —
  다만 `:Apply`는 이미 "이름 붙인 재사용 팩토리"를 권장하는 자리라
  (`tween-plan.md`의 `Animate`, `research/operator-sugar-plan.md`의
  `Sum`류) 그런 팩토리는 최상위 함수 선언이라 자연히 주석을 답니다.

### 그래서 우리가 하는 것 — ③ 선언 스타일: 인라인 대신 `typeof(named function)`

**[2026-08-15 추가, 근거: `audit/type-recursive-issue-with-typeof/REPORT.md`]**
①②와 별개로 추가 검증된 **선언 스타일 규약**입니다 — ①의 "명시 바인딩
강제" 원칙을 대체하지 않고, 그 위에 얹히는 보강입니다.

재귀 메소드(`Compute` 등)를 타입 안에 **인라인 제네릭 시그니처로 직접
쓰지 않고**, 이름 붙은 top-level 함수로 선언한 뒤 `typeof(그함수)`로
필드 타입만 참조하면:

```lua
-- ✅ 이렇게 (인라인 대신 이름 붙은 함수 + typeof)
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U>
	return nil :: any
end
type State<T> = {
	Get: typeof(Get),
	Compute: typeof(Compute),
}

-- ❌ 이렇게 두면 반환 타입이 `Unifiable<Error>`로 샘(①이 다루는 원래 문제)
type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, func: (State<T>) -> U) -> State<U>,
}
```

**LHS 명시 주석 없이도 다운스트림이 정확히 타이핑됩니다** — 체이닝
깊이 50, 타입이 바뀌는 체이닝(number→boolean→string→number), 콜백
안에서 self를 다시 호출하는 중첩까지 전부 실측 확인(위 REPORT `2`~`3`절).
비용 없음(50단 체이닝 `luau-analyze` 0.02초 안팎, hover 타입 크기도
깊이와 무관하게 일정).

**바뀌지 않는 것**:
- **콜백 파라미터는 여전히 명시 주석 필요**(`function(a0: State<T>)`) —
  ②의 "쪼개기"가 다루던 문제는 별개이고, `typeof`가 대신 풀어주지
  않습니다. 무주석이면 자유 타입 변수(`a0: unknown`에 가까움).
  **[2026-08-15 추가 확인, `audit/type-recursive-issue-try-callback/`]**
  사용자 요청으로 이 캐비엇을 뚫을 방법이 있는지 type function/메타테이블/
  오버로드/제네릭 디폴트 등 20개 formulation으로 재시도했으나 quad의
  `state:Compute(fn)` 단일 호출 모양을 유지한 채로는 여전히 못 뚫음(REPORT
  TL;DR 참고). 부수적으로 원인 이해가 한 단계 더 정확해짐 — 이 실패는
  "재귀 자기참조 특유의 문제"가 아니라 **"제네릭이 관여하는 함수 호출의
  인자로 넘긴 함수 리터럴엔 Luau가 컨텍스트 타입을 전파하지 않는다"**는
  더 일반적인 한계임(재귀가 전혀 없는 `Map<T,U>(arr:{T}, fn:(T)->U)`류
  콜백도 무주석이면 동일하게 샘). 재귀는 이 위에 얹혀 실패 양상을
  "완전 무주석"에서 "구조적 duck-typing 오염"(정상 호출조차 타입에러)으로
  악화시키는 부가 요인. `T`를 명시 중간 변수로 먼저 고정하거나 재사용
  가능한 monomorphize 헬퍼 함수를 거치면 실제로 추론이 살아나는 것도
  확인했지만(재귀형·quad 실제 계약·중첩 self 호출까지 검증), 둘 다
  `state:Compute(fn)`(콜론 호출 = `state.Compute(state, fn)` 단일 호출)을
  "먼저 특수화된 함수를 얻고 그걸 다시 호출하는" 2단계 체인으로 바꿔야만
  작동해 0번 대전제로 채택 안 함.
  **[2026-08-15 후속 조사, 같은 폴더 REPORT 11번 절]** `/code-review`
  지적으로 이중 꺾쇠 명시 인스턴스화(`state:Compute<<T,U>>(fn)`, 코퍼스에
  이미 `AttributeKey<<T>>`류로 존재하는 문법)도 재검토 — **leaf(비-중첩)
  호출에 한해 콜백 파라미터 무주석 추론이 실제로 성립하고 sound함을
  확인**(②쪼개기 + `Get` 필드의 명시 `read` modifier + 매 호출 T·U 전부
  명시가 함께 필요, 셋 중 하나라도 빠지면 스퓨리어스 진단이나 duck-typing
  함정으로 되돌아감). 이 역시 **채택 안 함** — 매 호출마다 이미 self로부터
  결정되는 `T`까지 중복 명시해야 하고 `U`(콜백을 쓰기도 전에 그 반환
  타입)를 미리 선언해야 하는 부담이 지금의 "파라미터에 타입 하나만
  주석" 관례보다 크고, `:Apply` 중첩 자기호출(§1②가 이미 캐비엇 건 자리)엔
  여전히 안 통해 규칙이 하나로 안 줄고 오히려 둘로 늘어나며, 부분
  인스턴스화(`<<U만>>`)는 이름이 아니라 선언 순서로 바인딩돼 이 재귀형에서
  아예 내부 에러로 깨짐. 상세 근거·모든 formulation은 REPORT 11번 절.
- **명시 LHS 오타입 그 줄 자체는 여전히 못 잡습니다**(`wrong: State<boolean>
  = test:Compute(...)`처럼 대입 줄 자체에 틀린 타입을 달면 그 줄은
  통과 — 다운스트림에서만 잡힘). ①이 이미 명시한 구멍과 정확히 같은
  종류로, **이 규약이 그 구멍을 메워주지 않습니다** — "명시 바인딩
  관례를 완화할 수 있다"는 뜻이 절대 아닙니다.
- **옛 솔버는 ③의 `typeof(Compute)` 선언 자체를 거부합니다**(①이 이미
  겪는 것과 같은 문제 — `--solver=old`에서 "Recursive type being used
  with different parameters"로 선언 시점에 막힘, 실측:
  `type-recursive-issue-with-typeof/spikes/
  19-oldsolver-crosscheck-rejects-typeof.luau`). ③을 관례로 채택해도
  §9의 "M0 실착수 때 실제 에디터 환경(`luau-lsp`)에서 새 솔버 확정"
  전제는 그대로 유효 — ③이 이 요구사항을 없애주지 않습니다.

**시도했지만 채택 안 함 — `setmetatable<{...}, {__index: typeof(...)}>`**:
콜백 파라미터 자동 추론까지 노리고 `Modifier`의 `__index`+`table.clone`
체이닝(§7)과 같은 계열로 확장을 시도했으나, quad의 실제 계약(콜백이
self 핸들 자체를 받음)에서 **콜백 반환 타입이 self의 원래 T와 다르면
(= `Compute`가 존재하는 이유 그 자체) 올바른 대입에도 모순되는 진단
두 개가 동시에 남는 Luau 0.733 솔버 버그**를 만남 — `setmetatable`
없이 순수 `typeof`만 쓰면 같은 시나리오가 깨끗이 통과하므로, `typeof`
자체가 아니라 `setmetatable` 경로 특정 문제로 좁혀짐. 최소 재현
9줄: REPORT 5-3절.

### 영향 범위

| API | 선언 스타일 | 파라미터 추론 | 반환 타입 안전성(LHS 무주석 시) |
|---|---|---|---|
| `state:Compute(fn)` | 인라인 + 쪼개기 | 쪼개기로 자동 해결 | ❌ 명시 바인딩 필요 |
| `state:Compute(fn)` | `typeof(named fn)`(③) | 콜백 파라미터 명시 주석 필요 | ✅ 무주석이어도 안전(다운스트림) |
| `state:With(...)` | 인라인 + 쪼개기 | 쪼개기로 해결(이형 dep 포함) | ❌ 명시 바인딩 필요 |
| `state:Apply(factory)` | 인라인 | factory 파라미터 주석 필요 | ❌ 명시 바인딩 필요 |
| `Effect(fn, ...deps)` | — | 해당 없음(자유 함수) | 해당 없음(반환이 재귀 타입 아님) |
| `state:Observer(fn)` | — | 해당 없음(로컬 제네릭 없음) | 해당 없음(`Observer` 반환) |
| `tween:Mapped(fn)` | 인라인 제네릭 메소드 | — | ❌ **조용히 통과**(아래 `H-24`) |
| `tween:Mapped(fn)` | `typeof(named fn)`(③) | 콜백 파라미터 명시 주석 필요 | ✅ 안전 |

**⭐ [2026-08-24 추가, 6라운드 손 트레이싱 `H-24` — 실측] `Tween<T>:Mapped`가
이 표에서 빠져 있었다.** 확정된 시그니처 `tween:Mapped(fn: (T) -> U): Tween<U>`는
위 1번이 *"이것만"* 문제라고 못박은 모양(`Foo<T>` 안에서 `-> Foo<U>`)과 **글자
그대로 같은데**, 이 문서도 `base/tween-plan.md`도 그 사실을 몰랐다(양쪽 grep 0건).

실측:
```lua
--!strict
export type Tween<T> = { Value: T, Mapped: <U>(self: Tween<T>, fn: (T) -> U) -> Tween<U> }
local t = (nil :: any) :: Tween<number>
local mapped = t:Mapped(function(x: number) return tostring(x) end)
local wrong: number = mapped.Value   -- Tween<string>.Value는 string → 에러여야 정상
```
`luau-analyze` → **진단 0건**(조용히 통과). 같은 검사를 ③(`typeof(named function)`
선언)으로 바꾸면 `TypeError: Expected this to be 'number', but got 'string'`으로
**정상적으로 잡힌다** — 즉 **기존 완화책이 그대로 통하는데 아무도 적용을
지시하지 않고 있었다.** 새 설계 결정은 필요 없다.

(§6의 `type function`을 거친 값과는 다른 문제다 — `Mapped`는 `type function`을
안 거치는 순수 제네릭 메소드다. 같은 각도로 최근 확정 표면을 훑어봤고
`state:Gate(setup)`/`EpochMap`/`Effect`는 **전부 이 패턴이 아니라 무관**했다 —
셋 다 제네릭 self를 다른 타입 인자로 반환하지 않는다.)

`state:With(...)`/`state:Apply(factory)`도 원리상 ③으로 같은 이득을
받을 것으로 예상되나(둘 다 `Compute`와 같은 "재귀 자기 반환" 모양),
**아직 개별 실측은 안 함** — 실제로 base pseudocode에 ③을 반영할 때
같이 확인할 것.

**`Effect`/`Observer`는 이 문제와 무관합니다** — 한때 0-Y가 "같은
lazy 핸들 계약을 공유하니 같이 걸린다"고 서술했으나 실측 결과 아니었음
(각각 자유 함수라서, 그리고 로컬 제네릭 반환이 없어서).

### 언제 풀리는가 — 지금 그대로 두면 자동으로 풀림

- **Luau RFC**: [`relax-recursive-type-restriction`](https://rfcs.luau.org/relax-recursive-type-restriction.html)
  — 완화 근거로 "This pays for itself in the considerable gain in
  expressivity gained for users of the type system"을 명시. RFC가
  직접 드는 "지금은 거부되는" 예시가 `Promise<T>.andThen:
  <U>(self: Promise<T>, callback: (T) -> Promise<U>) -> Promise<U>`로,
  **우리 `Compute`와 글자 그대로 같은 모양**입니다.
- **완화 메커니즘은 순수 내부 변경**("타입 별칭을 진짜 type function처럼
  취급해 lazy expansion") — **사용자 문법 변경 없음.** 즉 지금 우리가
  쓰는 선언 그대로 두면, Luau 쪽이 고쳐지는 순간 **코드 변경 없이**
  올바르게 풀립니다.
- **추적**: [`luau-lang/luau#2380`](https://github.com/luau-lang/luau/issues/2380)
  ("Allow recursive generic types to differ", 2026-08-13 기준 열려
  있음). 이게 닫히면 이 절의 ①(명시 바인딩 강제)을 재검증하고,
  불필요해지면 관례를 풀 것.
- **참고 — 옛 솔버는 이 패턴을 선언 시점에 거부**했습니다(`--solver=old`).
  새 솔버는 선언을 받아주지만 위처럼 조용히 새는 중간 상태입니다.
  즉 RFC의 완화가 **선언 검사까지는 들어왔고 인스턴스화까지는 아직**인
  것으로 보입니다.

### 미리 대비해 둘 것 — 없음

RFC가 순수 내부 변경이고 우리 선언이 이미 그 대상 모양이므로,
"미래에 자연히 등록되도록 플레이스홀더를 심어두는" 종류의 작업은
**필요 없다는 게 실측 결론**입니다. 오히려 지금 뭔가 심어두는 게
0번 대전제 위반입니다.

---

## 2. `Modifier.Overridden`의 서브타입 합성은 정적 체크 포기

**근거: `luau-test/done/09-type-modifier-overridden-subtype.luau`**

`FrameModifier`가 `GuiObjectModifier`의 서브타입이어야 자연스러운데,
필드 setter 메소드의 반환 타입이 각각 자기 자신이라 같은 이름 필드끼리
반환 타입이 갈려 구조적 서브타이핑이 깨집니다 — 실측으로 재현 확인.

**우리가 하는 것**: `Modifier.Overridden`의 시그니처를 `(...: any): any`류로
느슨하게 열어 정적 체크를 포기(fallback이 정상 작동함도 같이 확인됨).
상세는 `base/modifier-plan.md` 9-2번 절.

---

## 3. `AttributeKey<<T>>` 제네릭 키의 값 타입 narrowing은 안 됨

**근거: `luau-test/done/12-type-attribute-generic-key-narrowing.luau`**

`[AttributeKey<<T>> "name"] = value`에서 `T`가 이름별로 고정되지 않고
호출마다 독립 추론돼 narrowing이 전혀 강제되지 않음 — 실측으로 "안 됨"
확정.

**우리가 하는 것**: `base/attribute-plan.md`가 이미 예비해둔 fallback을
채택 — 정적 체크가 필요하면 `BooleanAttribute` 같은 **타입 패밀리**가
유일하게 믿을 수 있는 경로.

---

## 4. `Source(default)`/`Ref(default)`의 nilable 캐비엇은 타입으로 못 막음

**근거: `luau-test/done/14-type-nilable-default-overload.luau`**

`default` 생략이 `T`가 nilable일 때만 안전하다는 캐비엇을 함수
오버로드(교차 타입)로 막으려던 스케치는, 의도한 오용은 정확히 막지만
**정상 nilable 사용례까지 같이 막아** 채택 불가.

**우리가 하는 것**: 타입으로 강제하지 않고 문서 경고(UB)로 유지 —
`base/bind-system-plan.md`의 해당 절. 새 설계 결정이 필요한 항목은
아님(대안이 이미 존재).

---

## 5. `store.key` 레코드 필드 타이핑 — ⛔ 이 접근은 폐기됨 (2026-08-25)

> **⭐⭐ [2026-08-25 폐기] `WrapStore`/`ProcessStoreType`로 결과 타입을
> **합성**하는 접근 자체가 사라졌습니다.** 지금 Store는 **타입 함수를 안
> 쓰고** 타입 인자에 `Source<T>`를 직접 써서 **평범한 레코드**로
> 타이핑합니다(같은 날 `index<>`/`keyof<>` + 팬텀 필드로 가는 안을
> 넣었다가 위 §0 원칙에 따라 철회했습니다 —
> `archive/store-value-field-redesign-withdrawn.md`) —
> `base/store-plan.md`의 "`store.key` 레코드 필드 타이핑" 절이 소스,
> 뒤집힌 원문은 `archive/store-value-field-redesign-withdrawn.md`.
> 아래는 그 접근이 살아 있던 동안의 실측 기록이고, **`type function`
> 자체의 성질**(API 시그니처, 재귀 호출 한계)은 여전히 유효합니다.
>
> **왜 폐기됐나**(7라운드 `H-75`/`H-76` 실측): (1) 합성 결과가 **평평하면**
> `store.key:Compute(무주석 콜백)`이 깨진다 — 아래 1번의 ②쪼개기를
> `type function` **안에서도** 해야 한다는 뜻인데 그게 문서 어디에도
> 없었다. (2) `type function`은 **바깥 타입 별칭을 참조하지 못해**
> `Source<T>` 전 표면을 구조적으로 중복 작성해야 하고, **메소드 self
> 파라미터가 불변**이라 필드 하나만 어긋나도 `store.key`가 `State<T>`
> 파라미터 자리에 안 들어간다. 스파이크 `16`은 그 대입을 한 번도
> 해보지 않았다.

**[2026-08-15 확정, 근거: `luau-test/rewrite-required/16-type-store-key-typefunction.luau`,
`audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절 — 폐기 전 기록]**

`Store<T>` → `{[K]: Source<V>}` 합성을 Luau `type function`으로 하는
설계(`pre-implementation-audit.md` 1-10)는 그 시점 **설계와 실측 둘 다
확정**이었습니다. 원래 스파이크가 깨졌던 이유는 설계 문제가 아니라
**`types.newfunction`의 API 버전 드리프트**였습니다 — 시그니처가
`(parameters: {head: {type}?, tail: type?}, returns: {head: {type}?,
tail: type?}?, generics: {type}?): type`로 parameters/returns 둘 다
**레코드**를 받는데, 원래 스파이크는 배열(`{ ty }`)을 그대로 넘기고
있었습니다. self 파라미터는 `types.newtable()`이 돌려주는 **뮤터블
핸들 자기 자신**을 그대로 참조하면 됩니다(나중에 `setproperty`로
채워도 핸들이라 소급 반영됨).

수정 후 `ProcessStoreType<{ty:string, count:number}>`가 정확히
`{ty: Source<string>, count: Source<number>}` 구조를 만족하고, 음성
대조군(틀린 타입 `Get`/`Set`, 존재하지 않는 메소드) 전부 정확히
에러납니다. 에러 메시지도 `t1 where t1 = { Get: (t1) -> string, ... }`처럼
`<Cycle>` 없이 한 단계로 표기돼 아래 1번의 `typeof` 간접참조보다
오히려 읽기 쉽습니다.

**참고 — 1번(재귀 제네릭 반환 leak)과의 관계**: `type function`으로
`Compute<U>: State<U>`처럼 **자기 자신을 재귀 호출**하는 것(1번 문제
자체를 이 메커니즘으로 우회하는 것)은 별도로 시도해봤으나 막다른
길이었습니다 — 제네릭 인자가 아직 구체화되지 않은 채로 type function이
자기 자신을 호출하면 `stack overflow`로 즉시 크래시합니다(type
function은 구체 타입에 대해서만 동작하는 실행 모델이라, RFC가 별칭에
주려는 "진짜 lazy expansion"과 다름 — `types` 라이브러리에 지연 적용을
표현하는 API 자체가 없음). 이 항목(레코드 필드 합성)과 1번은 **서로
다른 문제**이고, `type function`이 도와주는 건 이쪽뿐입니다. 상세는
`audit/type-recursive-issue-with-typeof/REPORT.md` 6-2절.

---

## 6. `type function`을 거친 값은 이후 제네릭 self 메소드 체이닝이 조용히 깨짐

**[2026-08-19 신설, 근거: `quad-types-plan.md`, 실측 `luau-test/23`]**

### 무엇이 안 되는가

값의 **정적 타입**이 한 번이라도 `type function`을 거치면(설령 그
`type function`이 입력을 그대로 반환하는 순수 패스스루라도), 그 뒤
그 값에 **제네릭 self 파라미터를 쓰는 메소드**(`<Self, P>(self: Self,
...) -> Self & P`류, `AddPlugin`이 실제 사례)를 부르면 진단이 조용히
깨집니다:

```lua
type function CheckVersion(t: type): type
	return t -- 순수 패스스루 — 재구성 없음
end

local checked: CheckVersion<Quad> = ... -- 여기까진 정상
local extended = checked:AddPlugin(somePlugin) -- 여기서 깨짐:
-- TypeError: Expected this to be exactly 'P & Self', but got 'P & Self'
-- (양쪽이 글자 그대로 같은, 의미 없는 진단)
```

**핵심은 "재구성"이 아니라 "이력"입니다** — `types.newtable()`로 새로
조립한 타입만 문제인 게 아니라, `return t`로 원본을 그대로 돌려줘도
똑같이 깨집니다. 값이 `type function` 호출을 거쳤다는 사실 자체가
이후 제네릭 self 추론을 방해하는 것으로 보입니다(정확한 내부 메커니즘은
미상 — 솔버가 type function 출력을 "불투명한" 타입으로 취급해 self
단일화에 필요한 정보를 잃는 것으로 추정됨).

### 그래서 우리가 하는 것

검증/변형용 `type function`은 **원본 타입을 절대 반환하지 않는다** —
성공 시에도 트리비얼한 마커(`types.singleton(true)` 등)만 반환하고,
그 결과를 원본과 **완전히 격리된 별도 필드**로만 노출합니다:

```lua
-- ✅ 원본 T는 type function을 한 번도 안 거침
type CheckedQuad<T, Pattern> = T & { __versionCheck: CheckVersion<T, Pattern> }

local checked: CheckedQuad<Quad, "0.0.0"> = ...
local _ = checked.__versionCheck -- 강제 평가(아래 캐비엇 참고)
local extended = checked:AddPlugin(somePlugin) -- 안 깨짐 — checked의 T 부분은 순수함
```

`quad-types-plan.md`의 "`CheckedQuad<T, Pattern>`" 절에 전체 배선과 실측
과정이 있습니다 — ①`error()` 대신 `print`+`types.never`, ②검증은 함수
본문 로컬 타입 별칭이 아니라 리턴/필드 타입 표현식 자체에 박아 넣어야
호출부마다 재평가됨, ③(이 항목) 원본을 절대 반환하지 않고 별도 필드로
격리, 세 가지가 함께 필요합니다. **[2026-08-19 후속]** 실제 버전 매칭
로직(`CheckVersion`)은 quad에 종속되지 않은 별도 패키지
`type-version-check`로 분리됐지만, 이 항목이 다루는 "패스스루도 이력만으로
오염된다" 함정과 그 회피(별도 가상 필드 격리)는 그대로 유효합니다.

### 언제 마주치는가

`AddPlugin`처럼 **제네릭 self 파라미터**를 쓰는 메소드가 있는 타입에,
`type function` 기반 검사/변형을 적용하려는 모든 자리 — quad에서는
지금 `quad-types`의 `CheckedQuad<T, Pattern>`이 유일한 실사례지만, 앞으로
비슷한 "타입 레벨 게이트 + 체이닝 가능한 API" 조합을 설계할 때마다 재발할
수 있는 일반 패턴입니다. 아래 §8 체크리스트에 항목 추가.

---

## 7. 성립이 확인된 것 (안심해도 되는 것)

한계만 모아두면 "타입이 다 안 되는구나"로 오독되기 쉬워서 같이 적습니다.
아래는 **실측으로 통과 확인**된 것들이라 다시 의심하지 말 것:

- **`Source<T>`가 `State<T>`를 구조적으로 만족**(서브타입으로 그대로
  넘길 수 있음) — `luau-test/done/08`. 단 **단방향 의존을
  유지해야 함**(`State<T>`가 `Source`를 참조하면 안 됨 — 두 제네릭
  별칭의 상호 재귀는 솔버가 취약한 패턴).
- **`PreRef<T>`가 `Ref<T>` 자리에 대입 가능** — `luau-test/13` A섹션.
  **[2026-08-14 아홉 번째 세션] `PostRef<T>`도 완전히 같은 관계**(같은
  `Ref` 런타임 재사용, 브랜드 태그만 다름 — `base/ref-plan.md`의
  "`PostRef`" 절) — `13`은 지금 `rewrite-required/`라 재작성할 때
  `PostRef`도 같이 커버할 것.
- **Modifier의 제네릭 `__index` + `table.clone` 체이닝** — `luau-test/done/17`.
- **콜백 파라미터/본문의 타입 체크**(1번의 쪼개기 적용 시) — 진짜
  살아있음. **⚠️ [2026-08-25 경계 명시, 7라운드 `H-96`] 단 trailing deps가
  붙으면 dep 파라미터엔 주석이 필요하다** — deps가 0개면 콜백 파라미터가
  무주석으로 추론되지만, `:Compute(fn, a, b)`처럼 trailing deps가 붙는
  순간 그 dep 파라미터들은 해소되지 않아 `Consider annotating the return`이
  뜬다. ②쪼개기가 푸는 범위 **밖**이다.
- **명시적 제네릭 인스턴스화 `f<<T>>(...)`가 값 호출부에서 동작**한다
  — 콜론 메소드에서도 된다(**[2026-08-25 실측]**, 7라운드 `H-73`이
  "문법이 없다"고 단정했던 것을 뒤집음). 자세한 건
  `base/store-plan.md`의 "타입 추론 문제" 절.
- **⭐ [2026-08-25 실측] 싱글톤 보존 — 타입 후보 중에 싱글톤이 있으면
  `string`으로 안 뭉개진다.** `index<>`/`keyof<>` 기반 키 타이핑 전체가
  이 성질에 기대고 있어서 따로 확인했다:

  | 선언 | `f("bbb")`의 `T` | 진단 |
  |---|---|---|
  | `f<T>(input: T): T` | `string` ❌ 뭉개짐 | 없음 |
  | `f<T>(input: T & string): T` | `unknown` ❌ | 없음 |
  | `f<T>(input: T & ""): T` | `"bbb"` ✅ | **에러**(교집합이 빔) |
  | **`f<T>(input: T \| "" \| string): T`** | `"bbb"` ✅ | **없음** ✅ |
  | **`f<T>(input: T & ("A" \| "B")): T`** | `"B"` ✅ | 범위 밖이면 정확히 걸림 ✅ |

  **[2026-08-25] 다만 quad는 이 성질에 기대는 설계를 채택하지 않았다** —
  `K & keyof<...>` 기반 Store 타이핑은 같은 날 철회됐다(위 §0). 아래는
  Luau 자체의 성질로만 기록해둔다. 사용자 관찰:
  *"K& 를 걸고 유니온 스트링을 걸면, K 가 싱글톤으로써, string 으로
  뭉개지지 않고 전해진다."* 대조 전량은
  `audit/type-store-index-keyof/REPORT.md`.
- **⛔ 타입 레벨 `__call`은 죽은 경로다**(**[2026-08-25 실측]**) — `self`를
  못 받고(`Argument count mismatch`), `typeof(f<<T>>)`로 타입 인자를
  실어 나르는 것도 실패한다. 그래서 콜러블 팩토리는 `__call`이 아니라
  **지정된 필드**로 자기를 노출한다(`base/source-state-plan.md`의
  "`state:Apply(factory)`" 절).

---

## 8. 새 타입/API를 설계할 때 체크리스트

1. **자기 이름을 다른 타입 인자로 감싸 반환하는가?**(`Foo<T>` 안에서
   `-> Foo<U>`) → 1번 한계에 걸림. 설계를 바꾸지 말고(0번 대전제),
   메소드를 인라인 대신 이름 붙은 함수 + `typeof`로 선언(1번 ③)하고,
   그래도 명시 바인딩 관례는 그대로 문서에 같이 적을 것 — ③은 ①을
   대체하지 않음. **⚠️ ③은 반환 타입 안전성(LHS 무주석 다운스트림)만
   고쳐줍니다 — 콜백 파라미터 자동 추론이 같이 필요하면 이것만으론
   부족하니 바로 아래 2번도 같이 볼 것.**
2. **로컬 제네릭을 가진 메소드가 재귀 타입의 필드인가?** → 콜백
   파라미터 자동 추론이 필요하면 1번의 "쪼개기"(`XxxData<T>` /
   `Xxx<T>` 분리)를, 반환 타입 안전성이 우선이면 1번 ③(`typeof`)을
   적용할 것 — 필요하면 병행 가능(개별 검증은 아직 안 됨, 위 "영향
   범위" 표 참고). **`setmetatable<{...}, {__index: typeof(...)}>`로
   확장해 두 이득을 한 번에 얻으려 하지 말 것** — quad의 self-핸들
   콜백 계약에서 솔버 버그를 만남(1번 ③의 "시도했지만 채택 안 함"
   참고). **콜백 파라미터 무주석 자동 추론 자체가 필요하면**(쪼개기로
   해결 안 되는 자리, 예: `:Apply`의 factory) `audit/
   type-recursive-issue-try-callback/`이 전방위로 재시도했지만
   quad가 채택할 만한 방법은 못 찾음(REPORT 결론) — 지금은 명시 주석
   관례를 유지할 것.
3. **제네릭 키로 값 타입을 좁히려 하는가?** → 3번, 안 됨. 타입
   패밀리를 쓸 것.
4. **서브타입 관계인 두 타입을 합성하려 하는가?** → 2번, 메소드 반환
   타입이 갈리면 깨짐.
5. **타입으로 오용을 막으려 하는가?** → 4번 사례처럼 정상 사용례까지
   막는 경우가 흔함. 막기 전에 정상 사용례를 반드시 같이 테스트할 것.
6. **위 어디에도 안 걸리는데 안 되는 것 같다** → `luau-test/`에
   스파이크를 추가하고 실측할 것. **추론만으로 "된다/안 된다"를
   확정하지 말 것** — 이 문서의 항목 중 여러 개가 "된다고 믿었다가
   실측에서 뒤집힌" 것들입니다.
7. **`type function`으로 검사/변형한 값에 제네릭 self 메소드
   (`<Self,P>(self:Self,...)`류)를 나중에 부를 계획인가?** → 6번 한계에
   걸림. 그 `type function`이 원본 타입을 조금이라도 반환하면(패스스루
   포함) 안 됨 — 검사 결과는 원본과 절대 안 섞이는 별도 필드로 격리하고,
   원본 타입 자체는 `type function`을 아예 거치지 않게 할 것.

> **실측 방법 주의**: `luau-analyze`가 진단 0건이어도 타입이 제대로
> 해소됐다는 뜻이 아닙니다(1번이 정확히 그 사례). **`luau-analyze
> --annotate`로 추론된 실제 타입을 눈으로 확인**하고, 가능하면
> "일부러 틀린 타입에 대입해서 진짜 에러가 나는지" 음성 대조군을
> 같이 둘 것.

---

## 8.5. 대형 생성 타입은 체커의 `LuauTarjanChildLimit`(기본 10000)을 넘는다

**[2026-09-02 실측, `H-305` (d′) 반영 중]** 생성된 `export type D`/
`DMapper`(31클래스 × `<Class>Param<E>` 인스턴스화, 클래스당 필드 40~60개 ×
4-유니언)는 **별칭 선언이 존재하는 것만으로**(참조 안 해도) luau-lsp/새
솔버가 `Internal error: Code is too complex to typecheck!`를 낸다. 이분
실측: 별칭을 클래스별 소형 별칭으로 쪼개 합성해도 **무효**(총 정규화
작업량 동일), 한도 플래그 중 **`LuauTarjanChildLimit`만이 유효 레버**
(`LuauTypeInferRecursionLimit`/`IterationLimit`/`NormalizeCacheLimit`은
무효). `scripts/test.sh`가 quad-roblox 그룹에 `40000`을 실어 전 그룹
클린·1.2s대(성능 무해). 부수 관측 하나: 그 교집합 결과 타입
(`Quad & RobloxExtension`)을 `any` 파라미터로 흘리는 클로저 추론은
한도를 더 올려도(200000) 안 풀린다 — 경계에서 `:: any` 캐스트 한 번이
정답(`spec.robloxfactory.luau`의 주석 달린 자리). 에디터(luau-lsp) 쪽도
같은 한도를 쓰므로 증상이 나면 `.vscode/settings.json`의 fflags에 같은
키를 얹을 것(9번의 솔버 설정 항목과 같은 자리 — **[2026-09-02 기준]
아직 안 얹음**, 에디터에서 실제로 아픈지 확인 후).

---

## 8.6. 콜러블 테이블은 함수∩테이블 교집합이 아니라 `setmetatable<A, B>`로 선언한다

**[2026-09-02 실측·사용자 확정(`H10-3`/`H10-4` (d)), 2026-09-03 통합 반영]**
`__call` 메타테이블 기반 콜러블 네임스페이스(`Tag(...)` + `Tag.Merged`)를
`((...string) -> Tag) & { Merged: … }` **교집합**으로 선언하면 두 가지가
깨진다 — Luau 값 모델에서 함수∩테이블은 **무거주**(값의 원시 타입은
하나뿐이고 콜러블 테이블은 어디까지나 테이블)라서다:

1. **값 캐스트 붕괴**(`H10-4`) — 실값의 `:: Quad` 리터럴 캐스트가
   `"because the types are unrelated"`로 실패.
2. **제네릭 추론 오염**(`H10-3`) — 그 필드를 실은 `T`가 제네릭 이중
   통과(`QuadRoblox(QuadRoblox(...))`류)를 거치면 `q` 전체가
   `Type 'nil' does not have key`로 무너짐(재현 조건이 좁아 워크트리
   4패키지 오버레이 A/B로만 격리됨 — 내부 인과는 미규명, 격리만 완료).

**처방**: 솔버의 자기 표기 **`setmetatable<{Merged: …}, {__call: …}>`**
(또는 판정 동일한 `typeof(setmetatable(...))`) — 참인 주장(메타테이블
달린 테이블)이라 값이 거주하고, 캐스트·제네릭 통과 전부 클린(오버레이
A/B 실측). 실사용은 `quad-types`의 `TagConstructor`/`AttributeConstructor`.
**잔여 구멍 하나**: `__call` 경유 **호출의 인자 타입만 무검사**
(`q.Tag(123)` 조용히 통과 — 반환 타입·필드 오타는 검사됨, luau-lsp
1.69.0·luau-analyze 판정 일치). 옛 `@metatable` 표기는 소스 문법이
아니다(SyntaxError — 프린터 전용). 결정 경위·사용자 인용은
`session/2026-09-02-03-h10-3-setmetatable-decision.md`.

---

## 9. 미해결 / 추적 중

- **[2026-08-19 설정 완료]** 에디터(`luau-lsp`)의 솔버 설정 — `luau-analyze`
  CLI는 새 솔버가 기본값이지만 `luau-lsp`는 **옛 솔버가 기본값**
  (`LuauSolverV2=false`)이라 같은 코드에 다른 진단이 남. `luau-lsp`
  바이너리(1.69.0)를 직접 설치해 `luau-lsp analyze
  --flag:LuauSolverV2=true/false`로 실측 — 새 솔버가 필요하다는 결론
  재확인, `quad/.vscode/settings.json`에 `"luau-lsp.fflags.enableNewSolver":
  true`를 반영·커밋 완료(`tbox`도 같은 설정 확인). 실제 VSCode 세션에서
  이 설정이 반영되는지 육안 확인만 사람 몫으로 남음(`HUMAN_TODO.md` 6번).
- **`luau-lang/luau#2380`** — 닫히면 1번 관례 재검증(③ 포함).
- **`state:With(...)`/`state:Apply(factory)`에 1번 ③(`typeof`) 개별
  실측** — `Compute`에서만 확인됐고, base pseudocode에 실제로 반영할
  때 같이 확인할 것.
- **`setmetatable`+`typeof(genericFn<<T>>())` 조합의 모순 진단
  버그**(1번 ③ "시도했지만 채택 안 함") — quad는 이 formulation을
  안 쓰기로 해서 quad 쪽에서 더 팔 필요는 없지만, Luau 0.733의 실제
  솔버 버그로 보이므로 이미 알려진 이슈인지 확인 후 업스트림 제보
  검토(최소 재현 9줄, `audit/type-recursive-issue-with-typeof/spikes/
  08-metatable-BUG-contradictory-diagnostics.luau`).
