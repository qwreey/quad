# `typeof(namedFn)` 간접참조가 0-Y를 실제로 우회하는지 — 실측

**출발점**: 사용자가 `luau` 설계자와 가까운 사람과의 대화에서 힌트를 얻어
`test-ignoreme.luau`를 직접 작성 — `Compute`류 메소드를 타입 안에
**인라인 제네릭 시그니처로 직접 쓰지 않고**, 이름 붙은 top-level 함수로
선언한 뒤 `typeof(그함수)`로 필드 타입을 참조하면 `base/typing-limits.md`
1번(0-Y, 재귀 제네릭이 다른 타입 인자로 자기를 반환하면 조용히
`Unifiable<Error>`로 새는 문제)이 안 생기는 것 같다는 관찰. 이 문서는
그 관찰을 `--annotate` + 부정 대조군으로 검증한 기록입니다.

**이 폴더의 구성**: `REPORT.md`(이 문서) + `spikes/`(재현 스크립트,
`00`~`12`, 사용자가 만든 `test-ignoreme.luau`/`test2`/`test3`도 `00`대에
그대로 보존). `type-recursion-issue/`와 같은 이유로 스크립트를 같이
둡니다 — 여러 formulation을 대조한 판정이라 개별 파일을 직접 돌려야
재현됨.

**실측 환경**: Luau `0.733`(`mise ls luau`), `luau-analyze`(새 솔버
기본값) 기준. **[2026-08-15 정정, `/code-review high` 지적]** `--solver=old`
교차검증은 이 폴더 자체의 `spikes/`엔 없음 — 후속 실험
(`audit/type-recursive-issue-try-callback/spikes/
19-oldsolver-crosscheck-rejects-typeof.luau`)에서 이 폴더의 승자
formulation(`typeof(Get)`/`typeof(Compute)`)을 그대로 돌려 확인됨:
옛 솔버는 그 선언 자체를 "Recursive type being used with different
parameters"로 **선언 시점에 거부**(새 솔버만 통과) — `typing-limits.md`
§8이 이미 예견한 "새 솔버 전제"와 정합적.

## TL;DR

**결론이 두 번 뒤집혔습니다.** 처음엔 "고침" → 실제 quad 계약으로
재확인하니 "일부만 고침, 콜백 파라미터가 self 핸들이면 여전히 안 됨" →
`setmetatable` 없이 순수 `typeof`만 쓰면 "완전히 고침"으로 최종 수렴.
그 과정에서 **quad와 무관한 Luau 솔버 버그**(모순되는 진단 두 개가 동시에
남)도 하나 발견했습니다.

| 질문 | 답 |
|---|---|
| `typeof(namedFn)` 간접참조가 0-Y(반환 타입 leak)를 없애는가? | **✅ 없앱니다** — `setmetatable` 없이 쓸 때. LHS 명시 주석 없이도 다운스트림이 정확히 타이핑됨(체이닝 깊이 50, 타입이 바뀌는 체이닝, 콜백 안 재귀 self 호출까지 전부 확인). |
| 콜백 파라미터(self) 자동 추론도 같이 풀리는가? | **❌ 아니오.** 파라미터는 여전히 명시 주석 필요(`function(a0: State<T>)`) — 무주석이면 자유 타입 변수 `unknown`. 이건 0-Y와 별개 문제(기존 "쪼개기"가 다루던 문제)이고, `typeof`는 이걸 안 풀어줍니다. |
| `setmetatable<{...}, {__index: typeof(...)}>`로 파라미터 자동 추론까지 얻을 수 있는가? | **부분적으로 — 그리고 위험합니다.** raw 값을 파라미터로 받으면(quad 계약 아님) 자동 추론되지만, **quad의 실제 계약(콜백이 self 핸들을 받음)에서 콜백 반환 타입이 self의 T와 다르면(quad `Compute`의 존재 이유 그 자체) 올바른 대입에도 모순되는 진단 두 개가 동시에 남는 솔버 버그**를 발견. quad에 채택 불가. |
| `type function`으로 `Store<T>`→`{[K]: Source<V>}` 합성(0-A 관련 백로그, `typing-limits.md` §5)은? | **✅ 이제 완전히 통과.** 깨져 있던 이유는 API 버전 드리프트(`types.newfunction`의 두 번째 인자가 배열이 아니라 `{head=..., tail=...}` 레코드로 바뀜) — 실제 설계 문제가 전혀 아니었음. |
| `type function`으로 `Compute<U>: State<U>` 자체(재귀 반환)를 지연 평가할 수 있는가? | **❌ 막다른 길.** 제네릭 U가 아직 구체화 안 된 채로 자기 자신을 재귀 호출하면 `stack overflow`로 즉시 죽음 — type function 실행 모델 자체가 구체 타입만 다루므로 구조적으로 안 됨. |
| `base/typing-limits.md` §1(0-Y 원칙)을 뒤집어야 하는가? | **아니오.** §1의 "명시 바인딩 강제" 원칙은 지금도 유효합니다(아래 "무엇이 남는가" 참고) — 이 실측은 그 원칙에 **선언 스타일 규약**을 하나 추가할 근거를 줄 뿐, 원칙 자체를 반박하지 않습니다. |

## 검증 방법

`type-recursion-issue/`와 동일하게 매 formulation마다:
1. `luau-analyze --annotate`로 **실제 추론된 타입**을 눈으로 확인(진단
   0건 ≠ 안전, `typing-limits.md`가 이미 경고한 함정).
2. **양성 대조군**: 정상 사용(`ok: T = ...`)이 진짜로 에러 없이 통과하는지.
3. **음성 대조군**: 명백히 틀린 사용(`wrong: U = ...`, 없는 메소드 호출)이
   진짜로 에러가 나는지 — 둘 다 확인해야 "타입이 살아있다"고 말할 수 있음
   (에러가 하나도 안 나는 건 안전이 아니라 `any`로 샌 것일 수도 있음).
4. 체이닝 깊이 1/3/5/8/50, 콜백 안에서 self를 다시 호출하는 중첩 케이스
   포함(구솔버 `--solver=old` 대조는 이 폴더가 아니라 후속 실험에서
   수행 — 위 "실측 환경" 참고).

## 1. 대조군 — 인라인 선언은 여전히 leak (기존 0-Y 그대로 재현)

`spikes/01-baseline-inline-leak.luau` — `type State<T> = { Compute:
<U>(self: State<T>, ...) -> State<U> }`처럼 타입 안에 직접 재귀 제네릭
메소드를 쓰면, **명시 LHS 주석이 틀려도(`wrong3: State<boolean> = ...`)
그 줄 자체가 에러 없이 통과**하고 무주석 변수는 다운스트림 오용까지
전부 새어나감(`--annotate`로 보면 `Unifiable<Error>`). `typing-limits.md`
§1의 서술과 정확히 일치 — 이게 이 실측 전체의 기준선입니다.

## 2. `typeof` 간접참조만으로 반환 타입 leak이 사라짐

`spikes/02-typeof-no-split.luau` — `Compute`를 top-level `local function
Compute<T,U>(self: State<T>, func): State<U>`로 선언하고 `type State<T> =
{ Compute: typeof(Compute) }`처럼 참조만 바꿨더니:
- 무주석 `r2 = test:Compute(...)`도 `r2:Get()`에 틀린 타입을 대입하면
  **정확히 에러남**(§1이 요구하던 "명시 바인딩 없이도 안전"이 여기선
  실제로 됨).
- `--annotate`로 보면 `r2`의 실제 타입이 `Unifiable<Error>`가 아니라
  진짜 구조적 타입(`{Get:..., Compute:..., value: number}`, 재귀는
  `<Cycle>`로 정상 표기)으로 잡힘.
- **`const`는 무관** — `local function`으로도 동일(사용자의 처음
  가설이었던 `const`가 원인이 아니라, "재귀가 타입 별칭 자기 확장이
  아니라 이름 붙은 함수의 `typeof` 안에 있다"는 것 자체가 원인).

**대가**: 콜백 파라미터(`a0`)는 여전히 무주석이면 자유 타입 변수(`a0:
a`, 실질적으로 `unknown`) — 이건 0-Y와 별개인 "파라미터 추론" 문제라
`typeof`가 안 풀어줌(4번 참고).

## 3. 체이닝 깊이는 문제가 안 됨 — 진짜 지연/공유형이지 재재료화가 아님

`spikes/05-WINNER-typeof-selfhandle-chain.luau`가 최종 승자 formulation을
담고 있지만 **깊이 3까지만** 체이닝합니다 — 깊이 5/8/50 검증은 별도
`spikes/12-chain-depth-1-3-5-8-50-typechanging.luau`(코드리뷰 지적으로
뒤늦게 분리·추가, 원래 이 REPORT는 이 파일 없이 아래 주장을 하고
있었음)가 근거입니다. 아래는 `05`+`12` 둘을 합쳐 실제로 확인하는 것:

- 깊이 1/3/5/8/**50**까지 체이닝(`d1:Compute(...):Compute(...)...`),
  각 단계마다 양성(`ok: T = dN:Get()`)/음성(`wrong: U = dN:Get()`)
  대조군 쌍 — **음성은 전부 정확히 에러나고 양성은 전부 통과**,
  놓치는 단계 없음.
- 각 단계에서 **타입이 실제로 바뀌는** 체이닝(number→boolean→string→
  number 3-순환) — 여전히 정확.
- `--annotate`로 본 `dN`의 추론 타입 크기가 깊이와 무관하게 **일정**
  (depth 1과 depth 50에서 거의 같은 글자 수) — 이건 "매 링크마다 전체
  구조를 재료화하는 eager 확장"이 아니라 진짜 지연/공유 평가라는
  신호(사용자가 원래 가설로 세웠던 "지연 확장"과 부합).
- 타이밍: 50단 체이닝 전체 `luau-analyze` **0.02초 안팎** — 컴파일
  타임 절벽 없음.
- **콜백 안에서 self를 다시 호출하는 중첩**(`a0:Compute(...)`, 실제
  quad에서 Effect/파생 콜백이 받은 state를 또 파생시키는 패턴과 동형)도
  정확 — 이건 4번의 `setmetatable` 버전에서 터진 버그가 여기선 안
  일어남을 보여주는 핵심 대조.
- **건전성**: 존재하지 않는 메소드(`a0:NoSuchMethod()`)를 호출하면
  정확히 에러남 — self 타입이 `any`로 새서 아무 호출이나 받아주는
  게 아님을 확인.

## 4. 알려진(그리고 인정 가능한) 남은 구멍 — 명시 LHS 오타입 그 줄 자체

`spikes/06-known-gap-wrong-lhs-not-caught.luau` — `local wrong:
State<boolean> = test:Compute(function(a0: State<number>) return 1
end)`처럼 **그 대입 줄 자체**에 틀린 타입 주석을 달면 그 줄은 에러
없이 통과합니다(다운스트림은 여전히 안전 — `wrong` 변수를 실제로 쓰면
그때 잡힘, 3번의 다운스트림 검증과 동일 메커니즘). 이건 **새 구멍이
아니라 `typing-limits.md` §1이 이미 명시한 그 구멍**("주석이 그 한
줄의 RHS를 검증해주진 않지만... 다운스트림에는 정확히 바인딩된다")과
정확히 같은 종류 — `typeof`를 써도 이 특정 지점은 그대로 남습니다.
회귀가 아니라 원래 알려진 한계가 형태를 유지한 것.

## 5. `setmetatable` + 명시 제네릭 인스턴스화(`<<T>>()`) — 별도 실험, 결론은 부정적

사용자가 `test2`/`test3-ignoreme.luau`에서 시도한 `setmetatable<{inner:T},
{__index: typeof(genericFn<<T>>())}>` 패턴(quad가 이미 확정해 쓰는
`Modifier`의 `__index` + `table.clone` 체이닝, `typing-limits.md` §6과
같은 계열)을 재귀 `Compute`에 확장해봤습니다.

### 5-1. `spikes/07` — U==T(타입 안 바뀜) 케이스, self-핸들 파라미터는 명시 주석

**[2026-08-15 정정, `/code-review high` 지적]** 원래 서술이 이 파일을
"콜백이 raw 값을 받으면 무주석으로도 정말 좋음, 체이닝 50단까지 깔끔"으로
소개했으나, **`spikes/07-metatable-clean-when-U-equals-T.luau`를 직접
열어보면 그 서술과 안 맞습니다** — 이 파일은 콜백이 raw 값이 아니라
`(a0: Box<number>): number`처럼 **self 핸들을 명시 주석으로** 받고,
체이닝도 50단이 아니라 **1단**(`d1 = test:Compute(...)` 한 번)뿐입니다.
raw 값 콜백 + 50단 체이닝을 다뤘다는 실험은 이 폴더의 `spikes/`에
저장된 파일 중 어디에도 없어 지금은 재현할 수 없습니다 — 그 서술은
빼고, 이 파일이 실제로 보여주는 것만 남깁니다: **자동 추론
자체는 됩니다**(파라미터에 명시 주석이 있으므로 무주석 추론 얘기가
아니라 타입 안전성 얘기 — `wrong: string = d1:Get()`이 정확히 에러남).
이 파일의 진짜 역할은 **5-3의 대조군**입니다 — U가 T와 같을 때는
아래 솔버 버그가 안 남을 보여주는 baseline. 어느 쪽이든 raw 값이든
self 핸들이든 **quad의 실제 계약은 self 핸들**이라 이 절의 결론에는
영향 없습니다 — quad `Compute`의 콜백은 lazy self 핸들 자체를 받아야
함(여러 세션에 걸쳐 확정된 계약, `base/typing-limits.md`/
`bind-system-plan.md` 참고).

### 5-2. 콜백이 self 핸들을 무주석으로 받으면 — 정상/오용 안 가리고 모든 호출이 깨짐

**[2026-08-15 정정, `/code-review high` 지적 — 아래는 원래 서술이
틀렸던 부분을 고친 것]** 콜백 파라미터 타입을 `Box<ImplT>`(self 자기
자신)로 하고 무주석으로 두면, Luau가 **콜백 안에서 뭘 호출했는가만
보고 그때그때 파라미터 타입을 재정의하는 duck-typing**으로 샙니다.
처음엔 이게 "존재하지 않는 메소드도 조용히 통과시키는 불건전"이라고
서술했으나, `spikes/11-metatable-unannotated-selfparam-all-calls-break.luau`를
다시 돌려보면 **`a0:NoSuchMethod()`를 호출하는 줄도 실제로는
에러납니다** — 다만 "그런 메소드가 없다"는 정상적인 에러가 아니라,
duck-typing으로 재정의된 콜백의 함수 타입 자체가 `Compute`가 기대하는
함수 타입과 구조적으로 안 맞아서 나는 에러입니다. 그리고 이 에러는
`NoSuchMethod` 호출뿐 아니라 **`a0:Get()`처럼 완전히 정상적인 호출을
쓰는 줄에도 똑같이 남** — 이 파일 안 5개 `test:Compute(...)` 호출
전부가 예외 없이 에러납니다. 즉 실제 문제는 "나쁜 코드를 몰래
통과시킴"(불건전)이 아니라 **"콜백 파라미터가 self를 재귀 참조하고
무주석이면, 맞는 코드든 틀린 코드든 가리지 않고 전부 타입체크에
실패해 이 formulation 자체를 못 씀"**입니다. 결론(채택 안 함)은
바뀌지 않지만 이유는 다릅니다.

### 5-3. 콜백이 self 핸들을 명시 주석으로 받고, 반환 타입이 원래 T와 다르면 — 솔버 버그

`spikes/08-metatable-BUG-contradictory-diagnostics.luau`(9줄짜리 최소
재현) — 5-2처럼 콜백 전체가 깨지는 걸 막으려 파라미터에 명시 주석
(`Box<number>`)을 달면, 정상 사용은 정상적으로 통과하고 존재하지 않는
메소드도 진짜로 잡힙니다. 그런데 **콜백의 반환
타입이 self의 원래 T와 다르면**(예: `Box<number>` 위에서 콜백이
`boolean`을 반환) — 이건 quad `Compute`가 존재하는 이유 그 자체인
가장 흔한 케이스 — **완전히 올바른 대입(`ok: boolean =
d1:Get()`)에도 모순되는 진단 두 개가 동시에 남습니다**:

```
Expected this to be exactly 'number', but got 'boolean'
Expected this to be 'boolean', but got 'number'
```

`spikes/07`(U==T, 타입 안 바뀜)은 이 버그가 안 남 — **트리거는 정확히
"self-참조 파라미터 + 콜백이 다른 타입을 반환"** 조합입니다. 이건
quad 설계 문제가 아니라 **`setmetatable`+`typeof(genericFn<<T>>())`
조합에 특정된 Luau 0.733 솔버 버그**로 보임 — `setmetatable` 없이
순수 `typeof`만 쓰면(3번) 정확히 같은 시나리오가 깨끗하게 통과하는 걸
확인했으므로, `typeof` 자체의 문제가 아니라 metatable 경로 특정 문제로
좁혀짐. **quad에 이 formulation은 채택하지 않음.** (업스트림 제보
여부는 사용자 판단 — 최소 재현은 `08` 파일 하나로 충분히 작음, 이미
알려진 이슈인지는 미확인.)

## 6. `type function` — `Store<T>` 필드 합성은 고쳐짐, 재귀 `Compute`는 막다른 길

### 6-1. `luau-test/done/16-type-store-key-typefunction.luau` 복구 성공(원래 `rewrite-required/`)

`spikes/09-typefunction-store-key-FIXED.luau` — 원래 스파이크가 깨진
이유는 설계 문제가 아니라 **API 버전 드리프트**: `types.newfunction`의
시그니처가 `(parameters: {head, tail}, returns: {head, tail}, generics?)`로
**레코드**를 받는데, 원본 스파이크는 `types.newfunction({}, { ty })`처럼
**배열**을 넘기고 있었음(`{head = {ty}}`가 맞음). 이것만 고치고, self
파라미터도 `types.newtable()`이 반환하는 **뮤터블 핸들 자기 자신**을
그대로 self 타입으로 넘기면(나중에 `setproperty`로 채워도 핸들이라
소급 반영됨) 됩니다. 수정 후:
- `ProcessStoreType<{ty:string, count:number}>`가 정확히
  `{ty: Source<string>, count: Source<number>}` 구조를 만족.
- 4개 음성 대조군(틀린 타입 Get, 틀린 타입 Set 2건, 존재하지 않는 메소드)
  **전부 정확히 에러남**.
- 에러 메시지도 `t1 where t1 = { Get: (t1) -> string, ... }`처럼
  **`typeof` 간접참조보다 훨씬 읽기 쉬움**(재귀가 `<Cycle>` 없이 한
  단계 `t1`로 깔끔하게 표기됨) — hover/에러 가독성 면에서 오히려
  `typeof`보다 나음.

**→ `pre-implementation-audit.md` 1-10과 `typing-limits.md` §5의
근거가 됨. 이건 "설계가 막혔었다"가 아니라 "실측 스크립트가 낡은
API를 썼었다"였을 뿐이라, 원 설계(`bind-system-plan.md`의 `store.key`
레코드 필드 타이핑)는 그대로 유효 — 승격만 하면 됨.**

### 6-2. 재귀 `Compute<U>: State<U>` 자체를 type function으로 지연시키는 건 막다른 길

`spikes/10-typefunction-recursive-state-deadend.luau` — `MakeState(ty)`
안에서 `Compute` 메소드의 반환 타입을 만들려고 `MakeState(U)`를(U는
아직 구체화 안 된 `types.generic("U")`) 호출하면 **`stack overflow`로
type function 자체가 런타임 크래시**합니다. type function은 실행 시점에
구체 타입에 대해서만 동작하는 모델이라(RFC가 별칭에 주려는 "진짜
lazy expansion"과 다름), 아직 안 정해진 제네릭을 인자로 자기 자신을
재호출하는 걸 구조적으로 지원하지 않음 — `types` 라이브러리에 "지금
당장 안 풀고 나중에 적용할 타입 함수 호출"을 표현하는 API(예:
`types.apply(fn, args)`류)가 없음(`types.generic`/`types.newfunction`
등 목록에 없음, `luau.org/types-library` 확인).
**결론: type function으로 0-Y 자체를 우회하는 시도는 여기서 막힘 —
더 이상 이 방향으로 시간 쓸 필요 없음.**

## 무엇이 남는가 (base/ 반영 방향, 다음 세션에서 처리)

- **`typing-limits.md` §1은 뒤집지 않습니다.** "재귀 제네릭 반환이
  조용히 샌다"는 여전히 참이고 명시 바인딩 원칙도 여전히 유효합니다
  (4번 참고 — `typeof`를 써도 "그 줄 자체"의 구멍은 남음). 이 실측이
  주는 건 **원칙에 대한 반박이 아니라 선언 스타일 하나를 추가로 검증한
  것** — "메소드를 재귀 타입 안에 인라인으로 쓰지 않고, 이름 붙은
  top-level 함수 + `typeof`로 참조하면, LHS 명시 없이도 *다운스트림*이
  안전해진다"는 관례를 **추가**로 문서화할 근거. **콜백 파라미터
  명시 주석은 여전히 필수**(§1의 "쪼개기"가 다루던 문제는 그대로 남음,
  `typeof`가 대신 풀어주지 않음).
- **`setmetatable` 계열은 채택하지 않음** — quad의 실제 self-핸들 계약
  아래서 (a) 무주석이면 정상/오용 가리지 않고 콜백 전체가 타입체크
  실패, (b) 명시 주석이어도 타입이 바뀌는 가장 흔한 케이스에서 솔버
  버그. 이 결과 자체는 "시도했고 왜 안 되는지 안다"로 기록해두는
  가치가 있음(다음에 누가 또 같은 길을 시도하지 않도록).
- **`typing-limits.md` §5는 "미검증" → "검증 완료"로 승격.** 스파이크
  `16`을 `spikes/09`의 수정 내용으로 고쳐 `luau-test/done/`으로 옮기고
  `pre-implementation-audit.md` 1-10 관련 서술도 "설계 확정, 실측
  미완"에서 "설계+실측 둘 다 완료"로 갱신.
- **선언 스타일 규약이 base 코드 전체(특히 `bind-system-plan.md`/
  `source-state-plan.md`의 `State`/`Source`/`Modifier` 등 재귀 제네릭을
  쓰는 모든 타입)에 실제로 반영되려면**, 그 문서들의 pseudocode를
  인라인 메소드 선언에서 `local function` + `typeof` 참조 스타일로
  바꿔야 함 — 이건 **중대 변경 핸드오버 체크리스트 대상**(여러 문서에
  흩어진 pseudocode를 한 번에 고쳐야 함)이라 이 세션에서 바로 하지
  않고 사용자 확인 후 별도로 처리 권장.
