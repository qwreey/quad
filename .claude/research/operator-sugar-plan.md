# Operator 콤비네이터 슈가 — Sum/Product/Not/비트연산 등

**상태**: research — 사용자 요청(2026-08-12 세션)으로 신설, 같은 세션
후속 논의에서 `:Apply` 경유로 확정(아래 "왜 `:Apply`인가" 절). **구현은
맨 마지막으로 미룸(사용자 본인이 명시)**: 순수 슈가라 없어도 quad 기능상
문제없고, 각 함수가 서로 의존이 없어 나중에 통째로 추가하거나 개별
함수를 지우고 고쳐도 안전 — 우선순위가 낮은 이유. **지금 이 문서를 쓰는
목적은 구현 착수가 아니라 설계/네이밍 논의를 미리 남겨두는 것뿐.**

> **[2026-08-13 열세 번째 세션, 해소]** 아래 모든 `Operator.*` 예시가
> 의존하는 `h:Get()`(self-lazy-핸들 계약)은 **그대로 유지로 확정**됨
> (구 `question.md` 0-Y) — 예시를 고칠 필요 없음. 나중에 착수할 때는
> `base/typing-limits.md`(특히 7번 "새 타입/API를 설계할 때 체크리스트")를
> 먼저 볼 것 — `Operator.*`가 반환하는 파생 State도 사용처에서 명시
> 주석 바인딩이 필요한 대상임.

## 동기

`:Compute`/`:Apply`는 `fn(self, ...)` 람다를 요구하는데, `not self:Get()`처럼
정말 단순한 연산에도 매번 `function(self) return not self:Get() end`를
쓰는 건 번거롭고, 같은 패턴이 코드 여기저기 반복되면 가독성도 떨어짐.
기본 연산(산술/논리/비트)을 미리 만들어둔 콤비네이터로 표현하면 보기도
간결해지고 유지보수도 쉬워짐 — 예:

```lua
-- 지금(람다 매번 작성)
reduceMotion:Compute(function(self) return not self:Get() end)

-- 슈가로
reduceMotion:Apply(Operator.Not)  -- 네임스페이스 이름은 미정, 아래 참고
```

## 메커니즘 — 새 프리미티브 아님, `:Apply(factory)` 위의 순수 함수

**모든 `Operator.*`는 항상 `factory(self) -> State<U>` 모양이고 항상
`:Apply`로 붙인다** — 인자 없는 것(`Not`)과 커링되는 것(`Sum(a,b,c)`)을
구분하지 않고 하나의 규칙으로 통일(아래 "왜 `:Apply`인가" 절 근거).
내부적으로는 `self:Compute(...)`를 호출해 실제 반응형 노드를 만드는
것뿐 — 새 State/Handler 카테고리 불필요.

```lua
-- 0항(자기 자신만 변환) — 그 자체로 이미 factory(self) 모양
Operator.Not = function(self)
    return self:Compute(function(h)
        return not h:Get()
    end)
end

-- 사용
reduceMotion:Apply(Operator.Not)
```

```lua
-- N항(self + 다른 state들을 결합) — 커링: Sum(a,b,...)가 factory를 반환
function Operator.Sum(...: State<number>)
    local deps = {...}
    return function(self: State<number>)
        return self:Compute(function(selfH, previous, ...)
            local total = selfH:Get()
            for _, h in {...} do
                total += h:Get()
            end
            return total
        end, table.unpack(deps))
    end
end

-- 사용 — 한 번 만들어 이름 붙여 재사용 가능
local addTaxAndShipping = Operator.Sum(tax, shipping)
price:Apply(addTaxAndShipping)
```

`Product`/`And`/`Or`/`Xor`/`Band`/`Bor`/`Bxor`/`Bnot`/`Shl`/`Shr` 등도 전부
같은 두 형태(0항은 그 자체가 `factory(self)`, N항은 커링해서 `factory(self)`를
반환) — 어느 쪽이든 항상 `:Apply`로 붙임. 비트 연산은 Luau에 연산자가
없어 `bit32` 라이브러리 위에 얇게 얹는 형태가 됨.

## 왜 `:Apply`인가 — 스타일이 아니라 정합성 문제 (2026-08-12 세션, 후속 논의)

**처음엔 "0항은 `:Compute`에 바로, N항만 `:Apply`"로 나눠 썼으나 사용자가
일관성 문제로 재검토를 요청, 논의 중 실제 정합성 문제까지 발견되어
`:Apply` 통일로 확정.**

1. **재사용 가능한 커링 팩토리는 `:Compute`로는 안전하게 못 만든다 —
   진짜 버그 가능성.** quad는 Vide식 암묵적 자동 추적을 이미 기각했음
   (`bind-system-plan.md` "암묵적 자동 추적 기각") — 의존성은 오직
   `:With`/`:Compute`의 **그 호출문 자체**에 나열된 trailing args로만
   등록됨. 그래서 `local addTax = Sum(tax, shipping)`처럼 한 번 만들어
   재사용하고 싶은 값을 `price:Compute(addTax)`처럼 바로 꽂으면,
   `addTax` 내부에서 클로저로 캡처한 `tax`/`shipping`을 아무리 `:Get()`
   해도 **`:Compute`의 구독 목록엔 안 걸림** — `tax`/`shipping`이
   바뀌어도 조용히 재계산이 안 일어나는 버그가 됨. 이걸 피하려면
   `price:Compute(addTax, tax, shipping)`처럼 이미 `Sum(...)`에 넘긴
   deps를 호출부에서 또 나열해야 하는데, 이게 바로 2026-08-11 세션에서
   "trailing deps를 fn 위치 인자로 노출"하게 만든 그 중복/드리프트
   위험(`bind-system-plan.md` 해당 절)과 완전히 같은 클래스의 문제 —
   재사용 가능한 이름을 만드는 의미 자체가 없어짐.
   **`:Apply`는 이 문제가 원천적으로 없음**: factory가 내부에서
   `self:Compute(fn, tax, shipping)`을 직접 호출해 자기가 캡처한 deps를
   스스로 다시 넘기므로(호출자가 재입력하는 게 아니라 factory 자신이
   한 번 캡처한 값을 그대로 전달), 중복 없이 안전하게 재사용됨 —
   `price:Apply(addTax)`, `otherPrice:Apply(addTax)` 둘 다 안전.
2. **기존 문서 관용구와 일치.** `bind-system-plan.md`의 `:Apply` 절이
   이미 `state:Apply(makeFormatter("ko-KR"))`를 "커링 팩토리 + `:Apply`"의
   정석 예시로 들어둠 — `Operator.*`/`Animate`가 이 관용구를 따르는 게
   자연스러움. `Animate`가 `:Compute`를 골랐던 건 오히려 이 기존
   관용구에서 벗어난 예외였다는 게 이번 논의에서 드러남(`research/
   tween-plan.md` "왜 `:Apply`인가로 정정" 절 참고).
3. **일관성 — 0항/N항을 나누지 않음.** `Not`은 deps가 없어서 위 1번
   문제와 무관하지만, "이 라이브러리의 콤비네이터는 항상 `:Apply`로
   붙인다"는 단일 규칙을 지키는 게 "0항만 예외적으로 `:Compute`에
   바로 꽂는다"는 케이스 분기를 사용자가 매번 기억해야 하는 것보다
   낫다는 게 사용자 판단. 비용은 `Not`이 내부적으로 `self:Compute(...)`
   한 겹을 더 감싸는 것뿐 — 무시할 만한 오버헤드.
4. **의미론도 더 맞음.** "값에 연산자를 적용한다"는 게 "값으로부터
   완전히 새로운 파생값을 계산한다"보다 더 정확한 표현 — `:Compute`가
   v1/Fusion류 "매 스텝 능동적으로 값을 갱신"하는 것처럼 읽힐 수 있다는
   우려도 사용자가 제기(오해일 뿐 실제 동작은 pull-recompute지만, 읽는
   사람에게 주는 인상까지 고려).

**`:Compute`의 역할 재확인**: 이걸로 `:Compute`가 필요 없어지는 게
아니라, 역할이 명확해짐 — `:Compute(fn, ...deps)`는 **그 자리에서 한 번
쓰고 마는 인라인 람다**(deps도 그 호출문에 바로 나열) 전용 저수준
프리미티브로 남고, **이름 붙여 재사용하는 콤비네이터**(라이브러리가
제공하는 것이든 사용자가 직접 만드는 것이든)는 전부 `factory(self)` 모양
+ `:Apply`로 통일. `Operator.*`/`Animate`의 내부 구현은 여전히
`:Compute`를 쓴다 — 사용자에게 노출되는 표면만 `:Apply`.

## 미래 고려사항 (보류) — 중첩 결합 `Sum(a, b, Sum(c, d))` flatten 최적화

**사용자 제기(2026-08-12 세션), 지금은 착수 안 함 — 실사용 사례가 나오면
재검토.** `Sum(a, b, Sum(c, d))`처럼 콤비네이터를 중첩하는 것 자체는
**지금 설계로도 이미 가능** — `Sum(c, d)`를 먼저 실제 `self`에 적용해
구체적인 `State<number>`로 만든 뒤(`c:Apply(Operator.Sum(d))`), 그 결과를
바깥 `Sum`의 평범한 operand로 넘기면 됨. 다만 이러면 안쪽 `Sum(c,d)`가
독립된 State 노드를 하나 더 만들어서(중첩 `:Compute`), 바깥 `Sum`이
`a+b+c+d`를 한 번에 계산하는 것보다 그래프 레이어가 한 겹 더 생김.

사용자가 제안한 최적화 방향: `Sum(...)`이 리턴하는 클로저가 자기가
캡처한 operand 목록(`local keep = {c, d}`)을 **약한 릴레이션**(`Relate`,
`base/relate-plan.md`)으로 그 클로저 자신에 붙여두면, 나중에 다른 `Sum`
호출이 자신의 operand 중 하나가 "이미 Operator 콤비네이터가 만든
클로저"임을 감지해서 그 안에 보관된 operand들을 꺼내 자기 자신의 operand
목록에 합쳐 넣을 수 있음(`Sum(a, b, Sum(c, d))` → 실질적으로 `Sum(a, b, c,
d)`와 동일한 단일 `:Compute` 노드로 flatten) — 클로저가 GC되면 약한
릴레이션도 같이 사라지므로 메모리 누수 없음.

**보류 이유**: 순수 최적화(그래프 노드 한 겹 줄이기)일 뿐 기능 격차가
아님 — 지금도 위 방법으로 중첩 자체는 문제없이 됨. `Sum`류 생성 팩토리에
introspection 로직을 추가하는 거라 라이브러리 복잡도가 늘어남 — 사용자
본인이 "실제 사용사례를 보고 필요한지 나중에 검토"로 명시적으로 유보.
나중에 착수하게 되면 `Sum`/`Product` 등 각 생성 팩토리를 개별적으로 살짝
고치면 되는 수준이라, 지금 다른 설계에 영향 주지 않음.

## 패키지 배치

`quad-base` — Store/State 계층 위에서만 동작하는 순수 함수라 엔진 종속
없음(`quad-roblox` 아님). `Animate`가 `Tween`과 함께 어디에 배치됐는지와
같은 결로 맞추면 됨(`base/tween-plan.md` 참고, 단 `Animate` 자체는
`Tween`이 quad-roblox 개념(`PropertyHandler`)에 연결되므로 quad-roblox
배치 — Operator 슈가는 그런 엔진 종속이 없다는 점이 다름).

## 열린 질문 — 네임스페이스 이름 (미정)

`Not`/`Sum`/`And`/`Or` 같은 이름은 흔한 단어라 top-level에 그냥 두면
충돌 위험이 큼 — `Tag`/`Attribute`처럼 네임스페이스로 묶여야 함
(`Operator.Not`처럼). 문제는 **짧으면서 "이 연산자 콤비네이터 슈가
모음"이라는 목적을 잘 담는 이름을 아직 못 찾음** — 사용자가 직접 이
문제를 제기(2026-08-12 세션). 코퍼스 전체에 `Operator`/`Op` 이름 충돌은
없음을 확인함(grep 결과 없음), 아래는 후보:

- **`Operator`** — 의미는 제일 정확(산술/논리/비트 전부 "연산자"로
  포괄). 다만 다소 길어서 `Operator.Sum(a, b)`처럼 매번 타이핑하기엔
  무거울 수 있음.
- **`Op`** — 짧지만 무엇의 축약인지 처음 보면 바로 안 와닿을 수 있음.
- **`Ops`** — `Op`의 복수형, 뉘앙스는 비슷.
- ~~`Combinator`~~ — 코퍼스 전반에서 `:Apply`/`Animate` 같은 패턴을
  설명할 때 이미 일반명사로 "콤비네이터"라는 말을 자주 써서(예:
  `modifier-plan.md` 8번 절), 네임스페이스 이름으로 쓰면 "이 특정
  모듈"과 "패턴을 가리키는 일반 용어"가 헷갈릴 수 있어 후보에서 제외.

`.claude/question.md` 3번(낮은 우선순위)에도 반영. 용어 정리 라운드
(`question.md` 1번, `Brand`/`Tag`류)와 같은 카테고리로 나중에 같이
검토해도 됨 — 급하지 않음.

**[2026-08-12 추가]** 서브 에이전트 외부 리서치(아래 "외부 리서치 결과"
절) 결과, `Operator`가 가장 강한 실제 선례를 가짐 — Python 표준 라이브러리
`operator` 모듈(`operator.add`/`operator.and_`/`operator.lt` 등)이 quad의
정확히 같은 동기(연산자를 `map`/`reduce` 등에 넘길 수 있는 이름 붙은
함수로 만드는 것, quad에선 `:Apply`가 그 자리)로 존재하는 직접 선례.
`Ops`는 Rust `std::ops`가 근거이나 그건 연산자 오버로딩용 trait 네임스페이스라
"콤비네이터 함수 모음"이라는 quad의 용도와는 결이 다름(약한 선례). `Op`
(단수)는 오히려 Slate.js `Op`/Immer patch처럼 "낱개 연산 객체 하나"를
가리키는 데 더 흔히 쓰여 네임스페이스 이름으로는 가장 약한 후보 — 최종
결정은 여전히 사용자 몫이지만, 후보 중 고르라면 `Operator`가 근거가 가장
탄탄함.

## 열린 질문 — 포함 범위

- 산술(`Sum`/`Product`/`Sub`/`Div`?)·논리(`Not`/`And`/`Or`/`Xor`)·비트
  (`Band`/`Bor`/`Bxor`/`Bnot`/`Shl`/`Shr`)까지는 비교적 명확한데, 비교
  연산자(`Eq`/`Lt`/`Gt`/`Lte`/`Gte`)까지 포함할지는 미정 — 포함해도 같은
  패턴(커링 팩토리 + `:Apply`)으로 자연스럽게 들어감. **[2026-08-12 외부
  리서치로 갱신, 아래 절 참고]** 비트/비교 그룹은 "리액티브 파생값
  콤비네이터"로서의 실제 선례가 전혀 없는 것으로 확인됨(양쪽 다 다른
  라이브러리에서 인라인 연산자로만 쓰임) — 포함하더라도 업계 관행을 따르는
  게 아니라 quad가 처음 시도하는 조합이라는 점을 인지하고 판단할 것.
  `Sub`/`Div`도 명명된 콤비네이터로서의 선례가 전혀 없어(어디서든 인라인
  `-`/`/`만 씀) 드랍 후보. `Xor`도 VueUse가 `And`/`Or`/`Not`은 다 갖췄으면서
  의도적으로 뺀 것으로 보여 약한 후보.
- `Sum(a, b, ...)`가 self까지 포함해서 더하는 형태(위 예시)로 확정 —
  사용자 원 예시(`:Apply(Sum(state, state...))`)와 일치. self 없이 여러
  state를 독립적으로 합치는 형태가 따로 필요한지는 실사용 사례가 나오면
  재검토(지금은 `Store.Combine`류로 이미 커버된다고 봄).
- **[2026-08-12 외부 리서치로 신설]** `Clamp`/`Min`/`Max` — VueUse
  `useClamp`/`useMax`/`useMin`, Ramda `R.clamp` 등 리액티브 파생값
  콤비네이터로서의 선례가 뚜렷함. 기존 "산술" 뭉치보다 오히려 이쪽이
  선례가 강해 별도 그룹으로 추가할 후보.
- **[2026-08-13 세션 신설]** `Alternative`(nil 대체값 — Haskell
  `Alternative`/`<|>`, 흔히 coalesce/`??`/엘비스 연산자라고도 부름) —
  `State<T?>:Apply(Alternative(default))`처럼 값이 nil이면 기본값으로
  치환하는 콤비네이터. 지금까지 카탈로그에 없던 게 확인됨(전수 grep 결과).
  확정 규칙(모든 `Operator.*`는 `factory(self) -> State<U>` + `:Apply`)과
  그대로 맞음 — `default`가 상수면 deps 없이 클로저 캡처만으로 충분,
  `default`가 State면 trailing arg로 구독(위 `Sum` 패턴과 동일). 업계
  선례로 RxJS `defaultIfEmpty`, Kotlin 엘비스 연산자(`?:`), VueUse
  대부분 유틸의 기본값 인자 등 흔한 연산이라 포함 근거는 있음 — 이름/최종
  포함 여부는 다른 항목과 동률로 사용자 판단 대기.
- **[2026-08-12 외부 리서치로 신설, 별도 검토 필요 — Operator 카탈로그와
  성격이 다름]** Debounce/Throttle — RxJS `debounceTime`/`throttleTime`,
  VueUse `useDebounce`/`useThrottle` 등 업계 전반에서 가장 흔한 리액티브
  콤비네이터 카테고리 중 하나라 부재가 눈에 띔. 단, **quad의 `Blocker`
  (`base/blocker-plan.md`)와는 다른 메커니즘** — `Blocker`는 유저 코드가
  직접 `:On()`/`:Off()`로 여닫는 값 기반 게이트(타이머 없음)라 시간 기반
  지연/합치기가 아님. 실제 debounce/throttle을 만들려면 타이머(엔진 종속,
  Roblox `task.delay` 등)가 필요해 `factory(self) -> State<U>` 순수 함수
  모양을 벗어남 — `Operator.*`(quad-base, 엔진 무종속)에 넣을 수 있는 게
  아니라 quad-roblox 쪽 별도 프리미티브(Tween과 비슷한 위치)로 다뤄야 할
  가능성이 큼. 이 문서 범위 밖의 별도 설계 질문으로 분리해서 판단 필요 —
  지금 착수 안 함, 사용자 판단 대기.

## 열린 질문 — 컬렉션 계열 후보: `Concat`/`Sorted`/`Filtered`

사용자 제안(2026-08-12 세션). 위 산술/논리/비트 스칼라 연산과 달리 문자열
결합·테이블 정렬·필터링이라 범주가 다름 — 별도로 정리:

- **`Concat(state<any>, ...)`** — 각 operand를 `tostring`으로 변환한 뒤
  `..`으로 이어붙임. `Sum`과 완전히 같은 N항 커링 shape(`self` 포함해서
  전부 이어붙임)이라 이 카탈로그에 무리 없이 들어감.
- **`Sorted(diffFn)`** — `self`가 들고 있는 테이블을 `table.clone`한 뒤
  `table.sort(clone, diffFn)`로 정렬해 새 State로 반환. `-ed` 어미는
  기존 `Tag.Added`/`Removed`, `Overridden`과 같은 관례(뮤테이션이 아니라
  계산되어 반환되는 새 값임을 신호)와 일치해 이름도 자연스러움. `diffFn`은
  `table.sort`의 비교 함수와 동일한 시그니처(`(a, b) -> boolean`)로 두면
  됨. 구조적으로 문제없어 보임.
- **`Filtered`** — 반쯤 기각. 원소 개수 자체가 바뀌는 연산이라 `Slot`의
  인덱스 기반 조정 모델(`Length`/`Offset`/`bindLifetime`/`unbindLifetime`,
  `base/slot-plan.md`)과 정면으로 부딪힘 — Slot이 관리하는 리스트에 이걸
  직접 꽂으면 "원소가 사라졌다 다시 들어옴" 문제가 생겨서, 단순 Operator
  슈가가 아니라 Slot 쪽 조정 로직과 맞물리는 별도 메커니즘이 필요할 가능성이
  큼. Slot을 거치지 않는 순수 `State<table> -> State<table>` 값 변환
  용도라면 문제없이 들어갈 수 있음 — 실사용 사례가 나오면 재검토.
  **[2026-08-12 외부 리서치로 이 판단이 실제 선례로 뒷받침됨]** ReactiveUI의
  `IReactiveDerivedList`/`CreateDerivedCollection`은 필터링을 "일반 파생값"이
  아니라 아예 별도의, 변경분만 증분 반영하는 전용 컬렉션 타입으로 다룸 —
  즉 quad의 `Slot`과 같은 결의 "더 무거운 전용 프리미티브가 필요하다"는
  판단과 정확히 같은 결론. 반대로 SolidJS의 `createMemo(() => items.filter(...))`
  를 `<For>`에 바로 먹이는 흔한 패턴은 문제없이 동작하는데, 이건 memo
  자신이 아니라 `<For>`가 내부적으로 keyed reconciliation을 따로 하기
  때문 — memo의 identity 처리와 무관하게 하위 컴포넌트가 스스로
  재조정한다는 뜻. 이 대조가 quad의 결론을 그대로 뒷받침: **원소 identity
  보존이 필요 없는 자리(Slot을 안 거치는 순수 값 변환)라면 `Filtered`를
  plain value transform으로 둬도 되지만, identity를 보존해야 하는 자리는
  이미 `Slot`이라는 별도 무거운 프리미티브가 담당해야 하는 영역** — 어중간한
  타협이 아니라 정확한 경계선.

## 열린 질문 — Attribute 그룹 명시적 unset 유틸 (2026-08-12 세션 후속, 신설)

**배경**: `base/attribute-plan.md`가 "그룹에서 이름이 사라져도(diff든
통째 언마운트든) 프레임워크가 자동으로 `SetAttribute(name,nil)`을
안 해준다 — 지울 거면 명시적으로 `None`을 써라"로 확정됨(사용자 결정,
Ref의 "Destroy 무관, 정리 필요하면 Effect" 철학과 통일). 이유는 diff로
조용히 빠지는 것과 통째 소멸을 다르게 취급하면 오히려 모호해지고,
Attribute는 이미 "겹치면 error"로 소유 코드가 명확히 갈리는 설계라
프레임워크가 대신 판단할 근거가 불투명하기 때문(상세는 해당 문서
"그룹 `Attribute(...)`" 절).

**아이디어(사용자 제시, 착수 안 함)**: 그래도 자동 unset이 갖고 싶으면,
`Animate`와 같은 모양의 `:Apply` 팩토리로 **명시적 opt-in 유틸**을 나중에
추가하면 됨 — `State<data> -> State<Attribute>`를 만들면서 내부적으로
이전 이름 집합과 비교해 사라진 이름을 자동으로 `None`으로 채워 넣어주는
콤비네이터. 이 카탈로그의 다른 항목들(`Sum`/`Concat`/`Sorted`)과 같은
성격 — 순수 슈가, 없어도 기능 격차 없음, 사용자가 명시적으로 골라야만
동작(자동/암묵적이 아님이 핵심 — 그래야 "프레임워크가 대신 판단"이라는
모호함 문제 자체가 안 생김).

**우선순위**: 이 문서 전체와 동급으로 맨 마지막, 실사용 사례가 나오면
재검토. 지금은 이름도 모양도 구체화 안 함 — 착수 시점에 이 문서의
`Animate`/`Sum` 패턴을 그대로 참고.

## 열린 질문 — 중첩 State 평탄화 `State<State<T>>` → `State<T>` (2026-08-13 여섯 번째 세션, 사용자 제시, 백로그)

**배경**: 2026-08-13 다섯 번째 세션의 인덱스 기반 `Dispatch` 재설계로
`State<State<T>>`가 UB에서 **정상 지원 대상**이 됐음(각 재귀 단계가
다른 인덱스를 써서 슬롯 충돌이 없어짐, `base/bind-system-plan.md`
"Dispatch 체인" 절). 하지만 **동작한다고 해서 권장 방향인 건 아님**
(사용자 판단: "UB는 아니지만 우리가 원치 않는 방향인건 맞습니다").

**[근거 축소, 2026-08-13 열네 번째 세션] 원래 이 항목의 주 근거였던
"깊은 체인에선 힌트가 사라져 깜빡임 방지가 꺼진다"는 손실은 없어졌음.**
당시 서술: 옛 `Dispatch.retractFrom(inst,k,index,v)`가 힌트 `v`를 정확히
`index` 자리에만 넘기고 더 깊은 인덱스엔 `nil`을 넘겼기 때문에
`State<State<Tag>>`에서 바깥이 재발행하면 TagHandler가 `nil`을 받아
`RemoveTag`→`AddTag` 왕복이 일어났음. **하강 diff 재디스패치**에선 각
레벨이 자기 재프로세스에서 자기 값을 받으므로 깊이와 무관하게 진짜
`Tag` 객체가 전달됨(`base/dispatch-core-plan.md` "Dispatch 체인" 절).
남은 근거는 (a) 편의성/의도 표현, (b) `state<state<Frame>>`류에서 Slot
offset이 밀리고 당겨지는 케이스(이건 이미 "그냥 확인된 것"으로 수용)
정도라 **우선순위가 더 내려감**.

**아이디어(착수 안 함)**: 중첩을 Dispatch 층에서 감내하는 대신, 값
층에서 **평탄화하는 콤비네이터**를 제공 — `State<State<T>>`를 받아
`State<T>`를 돌려주는 join/flatten(하스켈 모나드 `join`, RxJS
`switchAll`/`switchMap`에 대응). 그러면 체인이 항상 한 겹으로 유지돼
힌트도 안 잃고, 사용자 의도("안쪽 값이 바뀌면 그걸 따라간다")도 더
직접적으로 표현됨.

- 2026-08-13 두 번째 세션의 Haskell 비교에서 이미 **"Monad bind/join이
  `StoreBind`/`Slot:Single`/`NoneHandler`에 각자 따로 재구현돼 있는
  미일반화 후보"**로 식별해뒀던 것과 같은 자리 — 그 세션은 "착수 안 함"
  으로 남겼고, 이번에 구체적 동기(힌트 유실)가 붙은 것.
**모양(2026-08-13 여섯 번째 세션 후속, 사용자 구체화)**: 이 카탈로그의
다른 항목들과 달리 **`Operator.*` 네임스페이스가 아니라 `State`의
메소드로 제공되어야 할 것으로 보임** — `state:Flatten()` 또는
`state:Flat()`(이름 미정). 이유: `Sum`/`Not`류는 인자를 받아 값을 만드는
순수 함수라 자유 함수가 자연스럽지만, 평탄화는 **특정 State 노드 하나를
받아 그것을 따라가는 새 노드**를 만드는 것이라 `:Compute`/`:With`와
같은 층위의 체이닝 메소드가 맞음.

- 대상 타입은 `State<State<T> | T>` — 즉 **안쪽이 State일 수도, 그냥 값일
  수도 있는 섞인 경우까지 흡수**해야 함(사용자 명시). 동작: 바깥 State의
  변경을 리슨하다가, 흘러나온 값이 `T`면 그대로 `State<T>`로 내보내고,
  `State<T>`면 그 안쪽을 따라가는 `State<T>`를 내보냄.

**⚠️ 핵심 난점 — 반환 노드가 동적 의존성을 가짐(사용자 지적).**
이게 이 항목을 단순 슈가로 못 만드는 이유이자, 백로그에서 따로 더
파야 하는 지점:

- quad는 **암묵적 자동 추적을 기각**했고(`base/bind-system-plan.md`),
  의존성은 `:With`로 **정적으로** 선언하게 돼 있음. 게다가 "`:With`의
  동적 의존성 미지원"은 2026-08-12 열여덟 번째 세션에 **의도된
  트레이드오프로 확정**됨(`research/framework-comparison-findings.md`) —
  State immutable 가정과 정면으로 부딪힌다는 이유.
- 그런데 평탄화 노드는 본질적으로 **안쪽 State가 바뀔 때마다 구독
  대상을 갈아타야** 함 = 의존성 집합이 런타임에 변함. 즉 이 도구는
  방금 그 "의도적 비지원" 결정의 **유일한 정당한 예외**를 요구함.
- 그래서 확정 전에 답해야 할 것:
  1. 동적 의존성을 **이 노드 안에만 가둘 수 있는가** — 바깥에서 보면
     여전히 평범한 `State<T>` 하나(정적 의존성 1개)이고, 구독 갈아타기는
     노드 내부 구현 디테일로 숨겨지는가? 숨겨진다면 "동적 With 미지원"
     결정과 실제로는 안 부딪힘(그 결정은 *사용자가 선언하는* 의존성
     목록에 대한 것이므로).
  2. 안쪽 State 교체 시 **옛 구독 해제 타이밍**과 `bindLifetime` 귀속 —
     이 노드는 `inst`에 안 묶인 순수 값 계층이라 `:Subscribe()` 계열
     규칙을 따라야 하는지, 아니면 다운스트림이 살아있는 동안만 유지되는
     별도 규칙이 필요한지.
  3. 그래서 결국 **`:Apply` 위의 순수 슈가가 아니라 진짜 새 프리미티브**
     인지 — 지금 판단으로는 상태를 갖는 노드라 후자에 가까움. 그렇다면
     이 문서(순수 슈가 카탈로그)가 최종 거처가 아닐 수도 있음.

**우선순위**: 백로그. `State<State<T>>`가 이제 정상 동작하므로 이게
없다고 막히는 건 없고, 힌트 유실도 흔한 경로(한 겹)엔 영향이 없음.
다만 위 난점 때문에 **다른 카탈로그 항목들보다 설계 비용이 확실히 큼** —
착수 시 "슈가 하나 추가"로 접근하지 말 것.

## 우선순위

**맨 마지막.** 없어도 quad는 기능상 완전하고, 함수 간 의존이 없어 나중에
일부만 먼저 만들거나 전부 미뤄도 리스크가 없음. 지금은 이 문서로
동기/모양/열린 질문만 남겨두고, 실제 구현은 다른 마일스톤이 다 끝난 뒤로
미룸.
