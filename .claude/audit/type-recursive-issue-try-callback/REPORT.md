# 콜백 파라미터 무주석 추론 — 되는 방법이 정말 없는지 전방위 실험

**출발점**: 사용자가 `typing-limits.md` §1의 남은 캐비엇("콜백 파라미터는
여전히 명시 주석 필요")을 직접 손으로 여러 방식을 시도해봤지만 전부
막혔고, "안 된다"는 결론이 나오긴 했지만 확실하다고 보기 어렵다며 —
type function/메타테이블/제네릭/그 외 뭐든 다 엮어서 한 번 더 파보라고
요청. **결론이 다시 "안 된다"로 나와도 그 자체가 원하는 결과물**(여러
각도로 확실히 막혔다는 실측 근거)이라는 전제로 진행.

**이 폴더의 구성**: `REPORT.md`(이 문서) + `spikes/`(재현 스크립트,
`00`~`33`, `20`부터는 후속 조사분). `type-recursion-issue/`/
`type-recursive-issue-with-typeof/`와 같은 이유로 스크립트를 같이 둡니다.

**[2026-08-15 후속 조사 추가]** `/code-review high`가 이 문서(당시
`00`~`19`)를 리뷰하며, 코퍼스에 이미 실사용 중인 **이중 꺾쇠 명시적
제네릭 인스턴스화 문법**(`Foo<<T,U>>(...)`, `base/attribute-plan.md`의
`AttributeKey<<T>>`, `type-recursion-issue/spikes/38/39/41`의
`t:Compute<<StateB<boolean>>>(...)`에서 이미 쓰임)을 단 하나도 시도하지
않았다는 결정적 미검증 각도를 지적함 — 20번부터 이어서 조사, 결과는
아래 11번 절.

**실측 환경**: Luau `0.733`(`mise ls luau`), `luau-analyze`(새 솔버
기본값)와 `luau-analyze --solver=old` 교차검증.

## TL;DR

**"콜백 파라미터를 완전히 무주석으로 자동 추론시키는 방법"은 여전히
없습니다.** 다만 그 과정에서 원래 문제의 성격 자체가 처음 생각했던
것과 다르다는 게 드러났고, **작동은 하지만 quad의 API 모양을 바꿔야만
하는 메커니즘 하나**를 새로 찾았습니다(0번 대전제로 기각).

| 질문 | 답 |
|---|---|
| 콜백 파라미터 무주석 추론이 되는 **새로운** 방법을 찾았는가? | **아니오(암묵 호출 기준) — 단, [2026-08-15 후속] 명시 이중 꺾쇠 인스턴스화(`state:Compute<<T,U>>(fn)`)는 예외.** 여기 정리된 최초 20개 formulation(type function, 메타테이블, 오버로드, 제네릭 디폴트, 테이블 리터럴, 캐스팅)은 전부 암묵 호출만 시도했고 전부 실패. `<<T,U>>`는 후속 조사(11번 절)에서 leaf 호출에 한해 성립·sound함이 확인됐지만 채택은 안 함 — 아래 후속 행 참고. |
| 이 문제가 quad의 **자기 참조(재귀) 타입 특유의** 문제인가? | **아니오 — 근본 원인 재정정.** 재귀 없는 가장 평범한 제네릭 함수(`Map<T,U>(arr: {T}, fn: (T)->U): {U}`)조차 콜백 파라미터가 무주석이면 `unknown`으로 새어나감(00번). **Luau는 제네릭 함수 호출 인자로 넘긴 함수 리터럴에 컨텍스트 타입을 전파하지 않는다**는 게 진짜 원인 — 자기 참조는 이 위에 얹힌 부가 문제일 뿐. |
| 그럼 왜 지금까지 "재귀가 문제"라고 생각했는가? | 비-재귀 제네릭도 원래 안 되지만(00번), quad가 실제로 부딪힌 건 항상 `Compute`(재귀형)였고, 재귀형에서는 실패 양상이 "완전 무주석"이 아니라 "구조적 duck-typing으로 뭉개짐"(06/07번, `{value:unknown}`류)이라 재귀가 원인처럼 보였을 뿐. 근본은 같은 "제네릭 콜백 파라미터는 컨텍스트 전파 안 됨" 문제. |
| **작동하는** 메커니즘을 찾긴 했는가? | **찾았습니다 — 두 개, 둘 다 API 모양을 바꿔야만 씀.** (a) `T`를 별도의 명시 타입 주석이 달린 중간 변수로 먼저 못박으면(`U`만 제네릭으로 남으면) 콜백 파라미터가 정확히 추론됨 — **재귀형에서도** 됨(09번), quad의 실제 계약(self 핸들, 중첩 self 호출)까지 검증(17번). (b) 재사용 가능한 "monomorphize 헬퍼" 함수 하나(`MonomorphicCompute<T>(self: State<T>): (<U>(...)->...)`)를 거치면 **T별로 손으로 다시 쓸 필요 없이** 자동으로 그 특수화가 일어남(18번) — 이게 이번 실험의 가장 흥미로운 발견. |
| 왜 채택 안 하는가? | 둘 다 `state:Compute(fn)` **단일 콜론 호출**을 `무언가(state)를 먼저 호출해 특수화된 함수를 얻고, 그걸 다시 호출하는 2단계 체인`으로 바꿔야만 작동함 — quad의 자연스러운 API 모양(단일 메소드 호출)을 콜백 추론을 위해 비트는 것이라 `typing-limits.md` §0 대전제 위반. |
| `type function`으로 뚫는 방법은? | **막다른 길, 기존 리서치와 같은 결론으로 재확인.** `Compute` 필드 하나만 type function으로 조립해도(12번), type function은 콘크리트 인스턴스화 시점에만 lazy 평가되고(확인됨) 그 안에서 "아직 안 정해진 `Box<U>`"를 참조할 API가 `types` 라이브러리에 없음 — `type-recursive-issue-with-typeof/REPORT.md` 6-2절이 이미 확정한 것과 정확히 같은 벽. |
| 메타테이블 변형은? | 새로 시도 안 함(직전 실험이 이미 솔버 버그로 막다른 길임을 확정해뒀고, 이번 실험이 밝힌 "근본 원인은 재귀 무관"이라는 사실 자체가 메타테이블 경로를 더 팔 이유를 없앰). |
| **[후속, 2026-08-15]** 이중 꺾쇠 명시적 인스턴스화(`Compute<<T,U>>(fn)`)로 콜백 파라미터 무주석 추론이 되는가? | **됩니다 — leaf 호출에서는, 게다가 소음(spurious diagnostic) 없이 완전히 sound하게.** 단 (a) T/U 둘 다 항상 명시해야 함(부분 인스턴스화는 이 재귀형에서 아예 깨짐, 21/21b), (b) 콜백 안에서 self를 또 호출하는 중첩(`:Apply` 패턴)은 여전히 실패(32) — 기존 캐비엇 그대로. **채택 안 함** — 11번 절 참고, §0 대전제 관점에서 순손해로 판단. |
| `base/typing-limits.md`를 고쳐야 하는가? | **원칙 자체는 안 바뀜.** §1의 "콜백 파라미터는 명시 주석 필요"는 여전히 유효 — 이번 실험은 그 옆에 "여러 각도로 재확인, 전부 막힘" 각주만 추가할 근거. 후속 조사(11번)도 같은 결론 — 각주 포인터만 추가, 가이드는 안 바뀜. |

## 검증 방법

`type-recursive-issue-with-typeof/`와 동일하게 매 formulation마다:
1. `luau-analyze --annotate`로 실제 추론된 타입을 눈으로 확인(진단 0건은
   안전의 증거가 아님).
2. **양성 대조군**: 정상 사용이 진짜로 통과하는지.
3. **음성 대조군**: 명백히 틀린 대입/없는 메소드 호출이 진짜로 에러
   나는지.
4. quad의 실제 계약(콜백이 self 핸들을 받고, 콜백 안에서 그 self를 또
   `:Compute`하는 중첩까지)으로 최종 확인해야 "성립"으로 인정 — 장난감
   사례(콜백이 raw 값을 받는 경우)에서만 되는 건 낮은 가치로 별도 표기.
5. 유의미할 때 `--solver=old` 교차검증.

## 1. 근본 원인 재정정 — 재귀와 무관하게, Luau는 제네릭 콜백 인자에 컨텍스트 타입을 안 준다

`spikes/00-sanity-nonrecursive-generic-fails.luau` — **자기 참조가 전혀
없는**, 교과서적인 `Array.map` 모양의 제네릭 함수:

```lua
local function Map<T, U>(arr: {T}, fn: (T) -> U): {U} ... end
local arr: {number} = {1,2,3}
local result = Map(arr, function(a) return tostring(a) end)
```

`--annotate`로 보면 `a`는 `unknown`으로 샙니다(`result`의 타입 자체는
`{string}`으로 정확히 잡히는데도). 대조로 `spikes/01-sanity-concrete-
nongeneric-works.luau`는 **제네릭이 아예 없는** 함수(`(fn: (number) ->
string) -> string`)에 똑같이 무주석 콜백을 넘기면 `a: number`로 정확히
추론됩니다.

**결론**: quad가 지금까지 "재귀 자기 참조 때문에 콜백 파라미터가 안
된다"고 이해하고 있던 것은 절반만 맞았습니다. 진짜 경계선은
**"제네릭이 관여하는 함수 호출 인자로 넘긴 함수 리터럴은 컨텍스트
타입 전파를 못 받는다"**입니다 — `T`가 이미 다른 인자(`arr`)로부터
호출 시점에 완전히 확정된 뒤에도 마찬가지입니다. 자기 참조(`State<T>`가
자기 자신을 언급)는 이 위에 **추가로** 겹쳐 문제를 더 나쁘게 만드는
요인(구조적 duck-typing, 아래 6/7번)일 뿐, 근본 원인이 아닙니다.

## 2. 닫힌 문(구문 자체가 없거나, 전파 경로 자체가 없음)

- **`spikes/02-no-explicit-generic-call-syntax.luau`** — TS의
  `f<number>(x)`류로 호출부에서 제네릭 인자를 못박는 문법이 Luau에
  있는지 확인 — **없음**. `Map::<number,string>(...)`도
  `Map<number,string>(...)`도 전부 `SyntaxError`. 애초에 "T를 호출부에서
  미리 고정"하는 표준 경로 자체가 언어에 없습니다.
- **`spikes/03-cast-whole-function-no-help.luau`** — 함수 리터럴 전체를
  `(function(a) ... end) :: (number) -> string`처럼 캐스팅하면 컨텍스트가
  전파될까 시도 — **안 됨**, `a`는 여전히 `unknown`. 캐스트는 함수 리터럴
  본문이 이미 체크된 뒤에 씌워지는 사후 연산이라 본문 체크 시점의
  파라미터 타입엔 영향을 못 줌.
- **`spikes/13-generic-default-syntax-unsupported.luau`** — TS의
  `<T = number>`류 제네릭 기본값 문법 존재 여부 확인 — **`SyntaxError`,
  Luau 0.733엔 이 문법 자체가 없음.**
- **`spikes/14-read-write-modifiers-exist-irrelevant.luau`** — `read`/
  `write` 프로퍼티 modifier는 **문법으로 존재**(파싱됨)하지만, 이건
  프로퍼티의 가변성(mutability) 표시일 뿐 제네릭 콜백 추론과는 무관 —
  적용할 지점이 없음(참고용으로만 기록).

## 3. 테이블 리터럴 컨텍스트 — 콘크리트 타입에서만 효과, 제네릭 호출 인자로는 안 통함

`spikes/04-table-literal-concrete-context-works.luau`가 처음엔 유망해
보였습니다 — `local t: Handlers = { fn = function(a) ... end }`(`Handlers`가
**이미 콘크리트로 확정된 non-generic 타입**)에서는 `a`가 정확히
추론됩니다. 이게 "테이블 리터럴은 함수 호출 인자와 다른 특별 경로를
타는 게 아닌가"라는 가설을 세우게 했는데, `spikes/05-table-literal-
generic-callarg-fails.luau`로 **같은 콜백을 제네릭 함수의 호출 인자
안에** 테이블로 감싸 넣어보면(`Foo(arr, { fn = function(a) ... end })`,
`Foo<T,U>`가 제네릭) — 다시 `a: unknown`으로 샙니다. **결론: 테이블
리터럴 자체가 특별한 게 아니라, 04번이 통과한 건 그 테이블의 타입이
호출 이전에 이미 명시 주석으로 콘크리트화돼 있었기 때문**입니다(2번
결론과 정확히 같은 근본 원인의 재확인).

## 4. 자기 참조가 얹히면 실패 양상이 "무주석 unknown"에서 "구조적 duck-typing 오염"으로 바뀜

- **`spikes/06-selfref-minimal-duckshape-fails.luau`** — 자기 참조하는
  최소형(`Box<T> = {value:T} & {Compute: typeof(Compute)}` — `Compute`
  선언 자체는 `typeof` 간접참조를 쓰지만, 그 간접참조가 **콜백
  파라미터 추론까지 살려주진 않는다는 걸 보여주는 사례**입니다, 2번
  §5의 `type-recursive-issue-with-typeof/`가 이미 확인한 것과 같은
  한계의 최소 재현)에 무주석 콜백을 넘기면, `a`가 완전한 `unknown`이
  아니라 **`{value:unknown}`**처럼 부분적으로 구조를 추측한 duck
  타입이 됩니다.
- **`spikes/07-inline-recursive-param-breaks-all-calls.luau`** — quad의
  실제 `State<T>` 모양(인라인 재귀 선언, `typeof` 트릭 없이)으로 같은
  실험을 하면 한 단계 더 나쁩니다 — `a`가 `{Get:(<Cycle>)->(unknown)}`류로
  추측되는데, 이 추측된 타입이 원래 `State<T>`와 구조적으로 안 맞아서
  (`Get`이 read-only 프로퍼티로 잡히는 등) **완전히 정상적인 콜백 본문
  (`a:Get()`)에서조차 실제 `TypeError`가 납니다.** 이건
  `type-recursive-issue-with-typeof/REPORT.md` 5-2절이 `setmetatable`
  변형에서 발견했던 "정상/오용 안 가리고 전부 깨짐" 현상과 **완전히
  같은 클래스** — 메타테이블이 원인이 아니라 "무주석 self-참조 파라미터"
  자체가 원인이었다는 뜻입니다.

## 5. ⭐ `T`를 명시 중간 변수로 먼저 못박으면 재귀형에서도 콜백 파라미터가 정확히 추론됨

이번 실험에서 가장 중요한 양성 발견입니다.

`spikes/08-WINNER-partial-fixT-viaannotation.luau`(비재귀 대조군)로
먼저 확인: 제네릭 함수 `Compute<T,U>`를, **T만 명시 타입 주석으로
콘크리트화하고(U는 여전히 제네릭인) 중간 변수**에 담으면:

```lua
local computeForNumber: <U>(self: {value: number}, fn: ({value: number}) -> U) -> {value: U}
    = Compute
local r = computeForNumber(self1, function(a) return tostring(a.value) end)
```

`a`가 정확히 `{value: number}`로 추론됩니다. 그리고
`spikes/09-WINNER-recursive-fixT-viaannotation.luau`로 **자기 참조하는
`Box<T>`**(Compute 필드가 `Box<T>`/`Box<U>`를 직접 언급하는 진짜 재귀형)에
똑같이 적용해도 **여전히 정확합니다** — `a: Box<number>`로 잡히고, 음성
대조군(`wrong: number = r.value`, 실제론 `string`)도 정확히 에러납니다.

**왜 되는가**: 2절/3절의 결론과 일관됩니다. 문제는 "제네릭이 함수 호출
시점에 함께 풀려야 하는 경우" 컨텍스트 전파가 끊기는 것 — `T`를
**호출과 별개의 이전 문장에서 명시 주석으로 이미 확정**해버리면, 그
다음 호출에서는 풀어야 할 제네릭이 `U`(콜백의 반환 타입으로부터
추론되는, 파라미터 타입에 영향 안 주는 방향의 제네릭) 하나뿐이라
컨텍스트 전파가 정상 작동합니다.

## 6. 하지만 자동화가 안 됨 — 필드 추출만으론 같은 이득을 못 받음

`spikes/10-field-extract-noannot-fails.luau` — 5절의 성공이 "그냥 필드를
미리 꺼내놓으면 되는구나"로 오해되지 않도록: `self1.Compute`를 **재주석
없이** 그대로 변수에 담아보면, 그 변수 **자기 자신의 추론된 타입부터**
`Unifiable<Error>`로 새어 있습니다(기존 0-Y와 동일 증상) — 5절의 성공은
`typeof`가 그런 것처럼 "자동으로 얻어지는" 게 아니라, **사용자가 T가
확정된 전체 함수 시그니처를 손으로 다시 써야만** 일어납니다. 즉 이
기법은 콜백 파라미터의 명시 주석 부담을 없애는 대신 **더 큰 시그니처
전체를 다른 곳에서 명시하는 부담으로 옮길 뿐**입니다 — 원래
`function(a: State<number>)` 한 조각 쓰던 걸, 훨씬 긴 함수 타입 전체
(`<U>(self: State<number>, func: (State<number>) -> U) -> State<U>`)로
바꿔 쓰는 셈이라 순수하게 손해입니다.

## 7. `typeof` 대신 평범한 타입 별칭으로 같은 간접참조를 하면 — 아예 거부됨

`spikes/11-alias-indirection-fails.luau` — 5절의 "중간 변수"를 필드
자체에 박아 넣어 자동화해보려고, `Compute` 필드 타입을 별도의 제네릭
별칭(`type FixedComputeOf<T> = <U>(self: Box<T>, ...) -> Box<U>`)으로
간접 참조하게 하면 **`TypeError: Recursive type being used with different
parameters`**로 선언 자체가 거부됩니다. `typeof(namedFn)` 간접참조
(`type-recursive-issue-with-typeof/`가 확정한 그 기법)가 왜 특별한지를
반증하는 대조군 — **일반 타입 별칭 사이의 상호 재귀는 이 우회를 못
받고, 오직 "이름 붙은 *함수*를 `typeof`로 참조"하는 형태만 통합니다.**

## 8. `type function`으로 필드만 조립 — 기존 결론과 같은 벽에서 재확인 종료

`spikes/12-typefunction-field-lazy-deadend.luau` — `Compute` 필드
하나만 `type function`으로 T에 따라 조립하는 안(9번 성공을 자동화하는
또 다른 시도)을 검토. 먼저 type function이 **콘크리트 인스턴스화
시점에만 lazy 평가**된다는 것부터 직접 확인(`error()`를 넣고 `Box<T>`를
쓰지 않으면 안 불림, `Box<number>`를 실제로 쓰면 그 순간 불림 — 확인됨).
하지만 그 안에서 "아직 확정 안 된 `U`에 대한 `Box<U>`"(콜백의 반환
타입으로 만들 리턴 타입)를 표현하려면 `types` 라이브러리에 "이름 붙은
별칭을 지연 적용하는" API가 있어야 하는데 **없습니다** —
`type-recursive-issue-with-typeof/REPORT.md` 6-2절이 재귀 `Compute` 자체를
type function으로 지연시키려다 `stack overflow`로 막혔던 것과 정확히
같은 벽입니다. 필드 하나로 범위를 좁혀도 이 벽 자체는 안 없어지므로,
더 이상 이 방향을 파는 건 낭비로 판단하고 종료.

## 9. 오버로드(교차 타입)로 콘크리트 분기를 얹어보기 — 둘 다 실패

- **`spikes/15-intersection-overload-ambiguous.luau`**(재귀 없는 통제
  버전) — 제네릭 오버로드 하나 + 콘크리트(T=number 고정) 오버로드
  하나를 교차 타입으로 합쳐두면, Luau가 **어느 쪽으로 콜백을 체크해야
  할지 모호하다며 `TypeError: ... is ambiguous`**를 냄 — 오버로드
  분기가 컨텍스트 타입을 좁혀주기는커녕 아예 선택 자체가 막힘.
- **`spikes/16-intersection-overload-recursive-breaks.luau`**(재귀형에
  적용) — 여긴 오버로드 모호성 문제까지 가기도 전에 `Box<T>`와
  `Box<number>`를 같은 재귀 별칭 안에서 같이 쓴 것 자체가 `Recursive
  type being used with different parameters`로 거부됨(7절과 같은 벽).

## 10. ⭐⭐ NEAR-MISS — 재사용 가능한 "monomorphize 헬퍼"는 실제로 작동함(단, API 모양을 바꿔야 함)

`spikes/18-NEARMISS-monomorphize-helper-two-call.luau` — 6절의 "자동화
안 됨" 문제를 다른 각도로 풀어봄: 필드를 그냥 꺼내는 대신, **T에 대해
제네릭인 재사용 가능한 헬퍼 함수를 하나 만들어서** 그 헬퍼의 반환 타입
주석에 5절의 "T 고정, U만 제네릭" 시그니처를 (T가 아니라 그 함수 자신의
제네릭 파라미터로) 써두면:

```lua
local function MonomorphicCompute<T>(self: State<T>)
    : (<U>(self: State<T>, func: (State<T>) -> U) -> State<U>)
    return (self :: any).Compute
end

local computeFor = MonomorphicCompute(test)          -- T=number가 *이 호출에서* 자동 추론됨
local d1 = computeFor(test, function(a) return a:Get() > 0 end)  -- a 무주석, 정확히 추론!
```

`computeFor`의 타입이 `MonomorphicCompute(test)` 호출 한 번만으로
자동으로 `<U>(self:State<number>, func:(State<number>)->U)->State<U>`로
잡히고 — **사용자가 T별로 손으로 시그니처를 다시 쓸 필요가 없습니다.**
이어지는 `computeFor(test, function(a) ...)` 호출에서 `a`는 정확히
`State<number>`로 추론되고, 음성 대조군도 정확히 에러납니다.
`spikes/17-WINNER-realistic-quad-contract-nested.luau`로 quad의 진짜
계약(콜백이 self 핸들을 받고, 콜백 안에서 그 self를 또 `:Compute`하는
중첩)까지 이 "T 고정" 기법 자체를 확인 — 중첩 내부의 `a1`까지 정확히
`State<number>`로 추론되고, 없는 메소드 호출(`a:NoSuchMethod()`)은
"Key 'NoSuchMethod' not found in table 'State<number>'"로 **진짜 타입
기반** 에러가 남(duck-typing 오염이 아님).

**왜 작동하는가**: `MonomorphicCompute(test)` 호출 자체는 1절의 "이미
확정된 T" 상황과 같습니다(`test`의 타입에서 T=number가 바로 추론되고,
이 호출엔 무주석 함수 리터럴 인자가 없으므로 컨텍스트 전파 문제 자체가
안 생김) — 그 결과로 나온 `computeFor`는 **T가 이미 콘크리트로 박힌**
함수 값이라, 5절과 똑같은 이유로 다음 호출에서 컨텍스트가 정상
전파됩니다.

**왜 채택하지 않는가 (0번 대전제)**: 이건 `state:Compute(fn)`이라는
**단일 콜론 호출**을 `MonomorphicCompute(state)(state, fn)`류의
**2단계 체인**으로 바꿔야만 얻어지는 이득입니다. 콜론 호출
`state:Compute(fn)`은 문법적으로 `state.Compute(state, fn)`(필드
접근 + 단일 호출)과 완전히 동일하고, 이건 1절의 실패 케이스와 정확히
같은 모양입니다 — **T와 콜백을 같은 호출 안에서 동시에 풀어야 하는 한**
이 문제를 벗어날 방법이 없다는 뜻입니다. `MonomorphicCompute`를 quad의
공개 API로 노출해 `state:Compute(fn)`을 `Compute(state)(fn)`류로
바꾸는 건, 콜백 추론 하나를 위해 quad 전역의 호출 관례(`:Compute`/
`:With`/`:Apply`/`:Observer` 전부)를 바꾸는 것이라 — 이건 "타입 사정에
맞춰 API를 비트는 것"의 교과서적 사례로 `typing-limits.md` §0을 정면
위반합니다. **기록해두는 가치는 있지만(다음에 누가 또 시도하지 않도록,
그리고 정말 절박해지면 재검토할 수 있도록) 채택은 안 함.**

부수적으로, `spikes/19-oldsolver-crosscheck-rejects-typeof.luau`로
`--solver=old` 교차검증 — `typeof(Get)`/`typeof(Compute)` 선언 자체가
옛 솔버에서 `Recursive type being used with different parameters`로
거부됩니다(`typing-limits.md` §8이 이미 예견한 것과 일치) — 이번
실험에서 찾은 모든 새 기법(08/09/17/18)은 이 `typeof` 패턴 위에 얹혀
있으므로 **전부 새 솔버 전제**라는 기존 제약을 그대로 물려받습니다.
새 결론 아님, 재확인일 뿐.

## 11. `<<T,U>>` 명시적 이중 꺾쇠 인스턴스화 — 후속 조사(2026-08-15)

**출발점**: `/code-review high`가 이 문서(당시 `00`~`19`)를 리뷰하며,
20개 formulation이 전부 **암묵적 추론 호출**(`Map(arr, fn)`)만
시도했고, 코퍼스에 이미 쓰이는 **이중 꺾쇠 명시적 인스턴스화**
(`Foo<<T,U>>(...)`, `base/attribute-plan.md`의 `AttributeKey<<T>>`,
`type-recursion-issue/spikes/38/39/41`의 `t:Compute<<StateB<boolean>>>(...)`)를
단 하나도 안 해봤다고 지적. 스파이크 `20`~`33`으로 이 각도를 전방위로
검증.

### 11-1. 비-재귀 제네릭에서는 완전히 깨끗함 (양성 대조군)

`spikes/20` — 재귀와 무관한 평범한 `Map<T,U>(arr, fn)`에
`Map<<number, string>>(arr, function(a) ... end)`처럼 두 타입 인자를
전부 명시하면, `a`가 무주석인데도 정확히 `number`로 추론되고 음성
대조군(`wrong: number = result[1]`, 실제론 `{string}`)도 정확히
에러납니다. §1의 근본 원인(1절, "제네릭 함수 호출 인자로 넘긴 함수
리터럴엔 컨텍스트 타입이 전파 안 됨")이 정확히 **명시 인스턴스화로
우회 가능한 문제**임을 확인 — 타입 인자를 전부 못박아버리면 그 "제네릭
호출"이 사실상의 콘크리트 호출이 되어 정상적으로 컨텍스트가
전파됩니다.

### 11-2. 부분 인스턴스화 — 이름이 아니라 선언 순서로 바인딩되고, 재귀형에서는 아예 깨짐

`spikes/21`(quad의 실제 `Box<T>` 자기참조형에 `<<string>>` 하나만 줘서
"U=string, T는 self에서 추론"을 의도) — **`<<X>>`는 이름이 아니라
선언 순서의 첫 번째 제네릭(`T`)에 바인딩됩니다.** 즉 `<<string>>`은
"U=string"이 아니라 "T=string"이 되어 실제 `self`(`Box<number>`)와
충돌하고, 그 충돌이 `"Internal error: outstanding free or blocked
type in function call"`이라는 이해하기 힘든 내부 에러로 새어나옵니다.

이게 단순히 "잘못된 슬롯을 줘서" 그런 건지 확인하려고 `spikes/21b`로
**올바른 T만** 주고(`<<number>>`, self와 일치) U를 추론에 맡겨봤지만
**여전히 같은 Internal error**가 나고, 심지어 **양성 대조군까지
깨집니다**(`ok: string = r1:Get()`가 `U`가 `string`으로 완전히
해소되지 않고 `(string <: 'a <: never)`라는 미해소 bounded 타입으로
남아 실패). **결론: 이 재귀형에서 부분 인스턴스화는 어느 방향으로
줘도 깨집니다** — 전부 주거나(11-1/11-3처럼) 전부 안 주거나
(기존 §1①/③) 둘 중 하나만 유효한 선택지이고, "T는 생략하고 U만
준다"는 경로 자체가 없습니다. 별도 파일로 남기진 않았지만 조사 중
비-재귀 `Map`으로도 같은 두 변형을 즉석에서 확인했는데, `<<string>>`이
재귀형과 마찬가지로 항상 첫 번째 선언 순서(`T`)에 바인딩되는 것,
반대로 올바른 `T`만 주고 `U`를 비워두면 `U`가 완전히 해소되지 않는
동일한 미해소 bounded 타입 증상을 보이는 것 둘 다 재현됐습니다
(비-재귀에선 self 충돌이 없어 Internal error까지는 안 가지만,
다운스트림 타입이 진짜 콘크리트가 아니라는 결함은 재귀형과 같습니다).
재귀 유무와 무관하게 Luau의 명시 인스턴스화는 "선언 순서대로, 전부
아니면 없음"에 가깝습니다.

### 11-3. 스퓨리어스(spurious) 진단의 정체 — `read`/`write` 프로퍼티 modifier 불일치, `08-metatable-BUG`와는 다른 문제

`spikes/22` — T, U를 **둘 다** 명시(`n:Compute<<number, string>>(fn)`)하면
`a0`가 무주석인데도 `--annotate`로 정확히 `{Get:(<Cycle>)->(number)}`로
잡히고, 콜백 본문(`check: number = a0:Get()`)도 정상 통과, 다운스트림
음성 대조군(`wrong2: number = r2:Get()`)도 정확히 에러납니다. **그런데
호출 라인 자체에 스퓨리어스 진단이 하나 더 남습니다**:

```
`Get` is a read-only property in the latter type, but the former type
requires a read-write property
```

**원인 규명**: `a0`의 타입은 여전히 usage로부터 duck-typed 추론되고,
이 추론된 shape는 "읽기만 관측됨"이라 Luau가 `Get`을 **read-only**로
표시합니다. 반면 명시 인스턴스화로 확정된 기대 타입(`BoxData<number>`)
쪽의 `Get`은 (기본값이라) **read-write**로 선언돼 있어 둘이 구조적으로
안 맞습니다. `spikes/23`(필드 선언 순서 스왑)은 효과 없음, `spikes/24`
(②쪼개기 패턴만 적용, `read` 없이)도 스퓨리어스 진단을 못 없앱니다
(단 `<Cycle>`이 사라져 메시지가 조금 더 읽기 쉬워질 뿐 — 원인은
그대로).

`spikes/25`(**WINNER**) — ②쪼개기 + `Get` 필드에 명시적 `read`
modifier + 전체 명시 인스턴스화, 셋을 **모두** 적용하면 스퓨리어스
진단이 완전히 사라집니다. `spikes/26`으로 확인한 바 `read` modifier
**단독**(쪼개기 없이)으로는 안 됨 — 쪼개기 없이는 재귀형 `Box<T>`
전체(`Get`+`Compute` 둘 다)를 구조적으로 맞춰야 하는데 usage로부터
추론된 duck shape엔 `Compute` 필드 자체가 없어 다른(더 지저분한)
스퓨리어스 진단으로 바뀔 뿐입니다 — 즉 ②(쪼개기)가 이 수정의 필수
전제입니다.

**`08-metatable-BUG`와의 관계**: 증상은 비슷(정상 사용에도 스퓨리어스/모순
진단)하지만 **원인이 다릅니다**. `08-metatable-BUG`(`type-recursive-issue-with-typeof/`)는
`setmetatable`을 쓸 때만 나타나는, 올바른 대입에도 모순되는 진단
두 개가 동시에 남는 진짜 솔버 버그(재현 불가한 근본 원인)였습니다.
여기서 발견한 건 `setmetatable`을 전혀 안 쓴 순수 `typeof` 선언에서,
**단순한 read/write 프로퍼티 가변성(mutability) 표시 불일치**라는
훨씬 평범하고 고칠 수 있는 원인이었고, 실제로 `read` modifier
하나로 완전히 해소됩니다. **같은 클래스의 버그가 아닙니다** — 이쪽은
"버그"라기보다 Luau의 정상적인 (다만 직관적이지 않은) 가변성 추론
규칙이었습니다.

### 11-4. ⚠️ 함정 — "깨끗해 보이는" 암묵 호출은 sound하지 않음

②쪼개기+`read`를 적용한 채로 **명시 인스턴스화 없이**(암묵 호출) 같은
콜백을 넣어보면(`spikes/27`) — 이것도 스퓨리어스 진단 없이 깨끗해
**보입니다**. 하지만 `spikes/28`로 콜백 본문에 진짜 오용(`local
badType: string = a0:Get()`, 실제론 number / `a0:NoSuchMethod()`,
존재 안 하는 메소드)을 추가해보면 **둘 다 안 잡힙니다** — Luau가
`a0`의 타입을 콜백 **본문의 사용 방식 그 자체로부터** duck-typing해
버려서, 뭘 하든 "일관성"만 있으면 통과합니다(`NoSuchMethod`는 존재하는
필드로 duck-type되고, `Get`의 반환 타입은 `badType`에 맞춰 `string`으로
재추론된 뒤 그 여파로 진짜 실수 위치가 아닌 엉뚱한 곳에서 혼란스러운
에러가 남). 이건 §1 4절(기존 06/07번)이 이미 문서화한 것과 정확히 같은
함정의 재확인입니다 — **명시 인스턴스화 없이는 ②+`read`도 안전판이
못 됩니다.**

`spikes/29`(같은 두 오용을 **명시 인스턴스화와 함께** 넣음)와
`spikes/30`(`NoSuchMethod` 하나만 단독으로)은 둘 다 정확히 잡힙니다 —
명시 인스턴스화가 기대 타입을 콘크리트로 고정해버리므로, `a0`의
duck-typed shape가 그 콘크리트 타입과 구조적으로 안 맞으면 호출 라인
전체가 에러납니다(개별 필드별로 정확히 짚어주진 않고 하나의 뭉뚱그린
shape mismatch로 나오지만, **빠짐없이 잡힙니다**). **결론: 이 기법이
sound하려면 명시 인스턴스화가 필수**이고, 11-3의 "쪼개기+`read`"만으론
부족합니다.

### 11-5. quad 실제 계약 검증 — 체이닝은 완전히 성립, 중첩 self-호출은 여전히 실패

`spikes/31` — WINNER 포뮬레이션으로 깊이 3, 타입이 매번 바뀌는 체인
(`number→boolean→string→number`)을 구성 — **전부 깨끗합니다**: 세
콜백 파라미터 전부 무주석으로 정확히 추론, 스퓨리어스 진단 0건, 양성
대조군 3개 전부 통과, 음성 대조군 3개 전부 정확히 에러. 이번 조사에서
가장 강한 양성 결과입니다.

`spikes/32` — 콜백 안에서 `a0`를 또 `:Compute`하는 중첩(quad의
`:Apply` factory 패턴에 대응, §1②가 이미 "이 방식으론 못 풀림, 파라미터
주석 필요"로 캐비엇 걸어둔 자리) — **여전히 실패**합니다:
`"Too many type parameters passed to function typed as ... Expected at
most 0 type parameters, but 2 provided."` `a0`는 여전히 usage로부터
duck-typing된 shape라, 이 한 번의 호출 지점에서 `a0.Compute`가 이미
비-제네릭(구체) 함수 타입으로 굳어버려 그 위에 `<<...>>`를 얹을 대상
자체가 없어집니다. **바깥 호출의 명시 인스턴스화는 파라미터 자신의
중첩 메소드 호출로 전파되지 않습니다** — §1②의 기존 캐비엇 그대로
유효, 이 조사로 안 풀림.

`spikes/33` — WINNER 포뮬레이션을 `--solver=old`로 교차검증 — 이
조사와 무관한 **기존에 이미 알려진** 이유로 거부됩니다(`read` 키워드
자체가 옛 솔버엔 없음, `typeof(namedFn)` 재귀 선언도 옛 솔버가 거부 —
`typing-limits.md` §8/§1③이 이미 명시한 그대로). 새로운 제약이
추가되는 게 아니라 기존 "새 솔버 전제"를 그대로 물려받을 뿐입니다.

### 11-6. 실용성 판단 — 기술적으로 성립하지만 채택 안 함

**"성립 여부"와 "채택 여부"를 명확히 분리합니다.** leaf(비-중첩)
`:Compute` 호출에 한해 11-1~11-5는 이 기법이 **진짜로 작동하고
sound함**을 보여줍니다 — 이건 "실패"가 아닙니다. 그럼에도 채택하지
않는 이유:

1. **매 호출마다 타입 인자 두 개를 전부 써야 합니다.** `T`는 이미
   `self`(`n`)의 타입에서 100% 결정되는 정보라 **순수 중복**이고,
   `U`는 사용자가 콜백을 **작성하기도 전에** 그 반환 타입을 먼저
   선언해야 한다는 뜻이라, 지금의 "콜백 파라미터 하나에
   `a0: State<number>`처럼 타입 하나만 적어주면 되는" 부담보다
   객관적으로 더 큽니다(적어야 하는 타입 개수도 늘고, 적어야 하는
   시점도 더 이릅니다).
2. **더 어려운 자리(`:Apply` 중첩)는 여전히 못 풉니다**(11-5,
   `spikes/32`). 이 기법을 채택해도 quad는 "leaf 호출은 `<<T,U>>` 필수
   + 파라미터 무주석, 중첩 호출은 파라미터 주석 필수"라는 **두 개의
   서로 다른 규칙**을 사용자에게 동시에 요구하게 되어, 지금의 "콜백
   파라미터엔 항상 타입 주석을 단다"는 단일하고 일관된 규칙보다
   오히려 사용자 부담과 실수 표면이 늘어납니다.
3. **`read` modifier 소급 적용 비용.** 11-3의 수정이 성립하려면 quad
   전역의 자기참조 타입(`State`/`Store`/`Modifier`/`Tag`/`Ref`/`Slot`/
   `Attribute` 등)에서 self를 받아 **호출만 되고 대입되지 않는** 모든
   접근자 필드를 `read`로 명시해야 합니다 — 새 API를 설계할 때마다
   챙겨야 하는 새 관례가 하나 늘어나는 것이고, 지금까지 base
   pseudocode 어디에도 `read`/`write` modifier를 쓴 전례가 없습니다.
4. **`Foo<<T,U>>(...)` 호출부 문법 자체가 지금 quad API 표면 어디에도
   없는 새로운 사용자 대면 관용구입니다.** `AttributeKey<<T>>`처럼
   **선언**에서 제네릭을 명시하는 건 이미 있지만, **매 메소드 호출부**에서
   명시 인스턴스화를 강제하는 패턴은 전례가 없어 `typing-limits.md`
   §0("API의 자연스러운 모양을 타입 사정으로 바꾸지 않는다")이 경계하는
   바로 그 종류의 변화입니다 — 10번 절의 `MonomorphicCompute`처럼
   호출 자체를 2단계로 쪼개는 건 아니지만("`state:Compute(fn)`이라는
   단일 콜론 호출" 모양 자체는 유지됨), 그 대가로 매 호출부에 원래
   없던 타입 인자 보일러플레이트를 강제한다는 점에서 같은 원칙 위반
   스펙트럼 위에 있다고 판단합니다.

**결론: 기술적으로 작동하고 sound한 새 메커니즘을 찾았지만, §0
대전제 관점에서 순손해(더 많이 써야 하고, 더 이른 시점에 써야 하고,
더 넓은 범위의 타입 선언 변경이 필요하고, 어려운 자리는 여전히 못
풀면서 규칙만 두 개로 늘림)로 판단해 **채택하지 않습니다**.** 기록해두는
가치는 있음(다음에 누가 또 시도하지 않도록) — 10번 절의
`MonomorphicCompute`와 같은 취급.

## 무엇이 남는가 — `base/typing-limits.md` 반영

- **§1의 원칙은 바뀌지 않습니다.** "콜백 파라미터는 명시 주석 필요"는
  여전히 유효 — 이 실험은 그 옆에 "여러 각도로 재확인했지만 전부
  막혔다"는 각주를 추가할 근거만 줍니다.
- **작지만 유용한 재정정 하나는 반영할 가치가 있습니다**: 이 문제가
  "재귀 자기 참조 특유의 문제"가 아니라 "제네릭 콜백 인자 전반의 문제
  (재귀가 있으면 실패 양상이 duck-typing 오염으로 악화될 뿐)"라는 게
  이번 실험으로 처음 명확해졌습니다 — §1의 서술을 문자 그대로 반박하는
  건 아니지만("재귀 제네릭이 자기를 다른 타입 인자로 감싸 반환하면"은
  quad가 실제로 겪는 형태에 대한 정확한 설명 그대로 유지), 원인 이해를
  한 단계 더 정확하게 해주는 각주로 추가.
- **`MonomorphicCompute` 2단계 체인 기법은 base에 반영하지 않습니다** —
  §0 대전제상 "찾았지만 채택 안 함"으로 이 REPORT에만 기록.
- 새로 열린 설계 질문 없음. M0/설계 게이트에 영향 없음(사용자가 요청
  시점에 이미 명시).
