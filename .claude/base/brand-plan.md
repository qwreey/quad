# `Brand` — 런타임 nominal 타입 판별 통합 메커니즘

> **[2026-08-13 아홉 번째 세션] `bind-system-plan.md`에서 분리됨.**
> 자기 완결적인 유틸이라 디스패치 코어와 같은 파일에 있을 이유가 없었음.
>
> **[2026-08-21 전면 재작성] 공유 레지스트리 + `Brand.get(x) -> tag`(객체당
> 태그 하나)에서 **인스턴스 브랜드**(`Brand()` + `:register`/`:is`, 다중 태깅
> 허용)로 바뀜.** 역전 원문은 `archive/brand-shared-registry-reversed.md`,
> 근거 기록은 `reference/epoch-brand-composition.md`. **뒤집힌 건 API 표면
> 하나뿐**이고 weak-key 레지스트리·테이블 아이덴티티·duck-typing 기각 근거·
> predicate 합성은 전부 그대로다.

**상태**: base — 동작/구현 방식은 확정, **이름 `Brand` 자체만 용어 정리
대기**(`question.md` 1번).

## `Brand` — 런타임 nominal 타입 판별 통합 메커니즘, `isState`를 일반화 (2026-08-07 여덟 번째 세션)

**배경**: `isState`(2026-08-07 다섯 번째 세션 확정, `:Peek<<T>>(key):
T|State<T>|nil`가 돌려주는 raw union을 사용자 코드가 분기하려면 판별
수단이 필요했음)와 똑같은 필요가 quad의 다른 branded 타입에도 전부
적용됨 — `Observer`/`Effect`/`Tag`/`Attribute`/`Tween`/`Blocker`/`Store`/
`Source`/`Slot`/`None`까지, Handler 구현(`isHandlable`에서 "이 값이
Store인가/Tag인가" 판별, 또는 PropertyHandler의 `process` 내부에서
"이 값이 Tween인가" 판별 — 2026-08-10 세션부터 `isTween`은 `isHandlable`이
아니라 값-레벨 분기에서만 쓰임, `base/tween-plan.md` 참고)과 사용자
코드 양쪽에서 반복적으로 필요해질 수단이라 `isState` 하나만 만들고
끝내지 않고 전체를 일관된 메커니즘으로
통합(component-composition-plan.md 4번 절이 이미 "`isSource`류 판별자로
(`isObserver`와 동일한 패턴)"라고 이 방향을 예견해뒀던 것과 맞아떨어짐).

**존재 이유 한 줄(2026-08-20 구현 전 QA 4라운드 `B-4`, 사용자 정리)**:
**`Brand`는 데이터 타입에 부작용을 남기지 않고 런타임 명시 타이핑을 하기
위한 것이다.** 값 자체엔 아무것도 안 심고(외부 weak 레지스트리), 판별이
읽기 부작용도 안 만든다 — 아래 duck-typing 기각 근거 두 개가 정확히 이
한 줄에서 나온다.

## ⭐ 구현 — 인스턴스 브랜드, 브랜드마다 자기 weak 집합 하나 (2026-08-21 확정)

**`Brand()`가 브랜드 객체 하나를 만든다.** 그 객체가 weak-key 집합 하나를
들고, 값은 **자기가 속한 브랜드에 스스로 등록**한다.

```lua
local function Brand()
    local members = setmetatable({}, {__mode = "k"})
    return {
        register = function(self, x) members[x] = true end,
        is       = function(self, x) return members[x] == true end,
    }
end

-- 각 타입이 자기 브랜드를 하나씩 소유
local ObserverBrand, EffectBrand, TagBrand, AttributeBrand, TweenBrand,
      BlockerBrand, StateBrand, SourceBrand, StoreBrand, SlotBrand,
      RefBrand, PreRefBrand, PostRefBrand, ModifierBrand, EpochBrand =
      Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand(),
      Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand()

-- 각 타입의 모든 생성 지점(Observer(...), Source(...), :With(...), Tag(...) 등)에서:
ObserverBrand:register(newHandle)
```

**⭐ 다중 태깅이 이 설계의 존재 이유다.** 한 값이 **여러 브랜드에 동시에**
속할 수 있다 — 실제로 그게 필요한 자리가 있다:

```lua
-- Source는 Source이면서 동시에 Epoch다 (base/state-epoch-plan.md)
SourceBrand:register(source)
EpochBrand:register(source)
```

옛 모양(`Brand.get(x) -> tag`, 객체당 태그 하나)으로는 이걸 표현할 수 없었고,
그게 재작성의 직접 발단이다 — `archive/brand-shared-registry-reversed.md`.

**부수 이득 — 외부 확장이 열린다.** `Source`가 아닌 원천(외부 시계 등)이
`Epoch`로 참여하고 싶으면 `EpochBrand:register(self)` 한 줄이면 되고,
`isEpoch` 구현을 고칠 필요가 없다. 사용자 논거: *"본인이 거기 속하면, 본인이
직접 해당 브랜드를 가져와 등록하면 … `isXXXX`에서 각각의 구현을 넣을 필요가
없어짐. 따라서 외부 확장도 쉬워진다."*

**역조회는 없다** — "이 값이 대체 무엇인가"를 되묻는 창구는 제공하지 않는다.
코퍼스가 실제로 쓰는 건 전부 `isX` 형태의 **멤버십 질문**뿐이고, 역조회를 하는
자리는 전수 조사에서 하나도 없었다(사용자 확인: *"확실히 의미가 없어진것 같습니다
필요하진 않아요."*).

**브랜드 아이덴티티가 곧 테이블 레퍼런스다 — 문자열 태그를 안 쓰는 이유는
그대로 유효(사용자 제안)**: Luau의 인터닝된 문자열 비교도 이미 사실상 O(1)
포인터 비교라 성능 차는 무시할 만하지만, **오타 안전성**이 실질적 이득 —
태그가 오타난 문자열 리터럴("Oberver")이면 등록/조회 양쪽이 조용히 어긋나는데,
잘못된 브랜드 **변수**를 참조하면 즉시 드러나거나 최소한 진짜 다른 집합이
되어 헷갈릴 여지가 없음. 새 모양에선 이게 더 강해진다 — 브랜드가 값이라
`nil`을 인덱싱하면 그 자리에서 에러가 난다.

**메소드 이름이 소문자인 건 이 유틸의 기존 관례를 잇는 것**(`Brand.set`/
`Brand.get`이 그랬다). quad 공개 표면의 PascalCase 메소드 관례(`:Get`/`:Set`/
`:With`)와 다른데, `Brand`는 사용자가 직접 부르는 프리미티브가 아니라 base
내부 유틸이고 사용자에게 노출되는 건 `isX` wrapper들이다 — 이름 자체가
용어 정리 대기 항목이므로 케이싱도 그때 같이 본다(`question.md` 1번).

## `isX` wrapper — 포함 관계는 predicate 합성으로 (2026-08-09 열한 번째 세션)

**`isX`는 브랜드를 직접 노출 안 하고 각자 얇은 wrapper로 감쌈** — 단순
항등인 경우(`isObserver(x) = ObserverBrand:is(x)`)와, 상위 관계(subtype)가
있어 **더 구체적인 브랜드 체크 위에 OR로 얹는** 경우(`isState`/`isRef`)로
갈림. **[정정, 2026-08-09 열한 번째 세션]** 후자를 "집합 멤버십"(플랫한 셋
체크)으로 구현하던 방식을 "더 구체적인 predicate를 먼저 정의하고 그 위에
얹는" 합성 방식으로 재정리 — 동작은 동일하지만, 어느 predicate가 다른
predicate를 내포하는지(포함 관계의 방향)가 코드 모양 자체에 드러나게 함:

```lua
local function isSource(x)
  return SourceBrand:is(x)
end
local function isState(x)
  return isSource(x) or StateBrand:is(x)  -- Source가 State를 구조적으로 만족
end

local function isPreRef(x)
  return PreRefBrand:is(x)
end
local function isPostRef(x)                     -- [2026-08-14 아홉 번째 세션] PostRef 확정
  return PostRefBrand:is(x)
end
local function isRef(x)
  -- PreRef/PostRef가 Ref 런타임을 재사용 = 둘 다 Ref의 한 종류
  return isPreRef(x) or isPostRef(x) or RefBrand:is(x)
end
```

**⭐ 다중 태깅이 가능해져도 포함 관계는 계속 이 합성으로 쓴다.** *"`Source`를
`StateBrand`에도 같이 등록하면 `isState`가 한 줄이 되지 않나"*는 하지 않는다 —
등록 지점이 여러 곳에 흩어지면 "어느 브랜드에 등록하는 걸 빠뜨렸나"가 조용한
버그가 되고, 포함 관계가 코드 모양에서 사라진다. **각 타입은 자기 브랜드에만
등록하고, 포함 관계는 predicate 한 곳에 쓴다.** 사용자 확인: *"여전합니다.
`PreRefBrand` 가 존재할테니. 거기에 `is()` 를 해서, 코드에 전부 드러나는거
똑같습니다."*

- **예외는 "구조적 인터페이스"뿐** — `Source`를 `EpochBrand`에 같이 등록하는
  건 포함 관계가 아니라 **서로 다른 축의 계약을 동시에 만족**하는 것이라
  합성으로 표현할 수가 없다(`isEpoch`가 `isSource`를 알아야 할 이유가 없고,
  `Source`가 아닌 원천도 참여해야 한다). 이게 다중 등록의 정당한 용례다.

**정정 — `isSource`는 별도로 필요함, 다섯 번째 세션의 "불필요" 서술을
뒤집음(2026-08-07 여덟 번째 세션).** 그때는 "State면 충분한 용도"만
염두에 뒀지만, `Source`는 State보다 진짜로 더 많은 능력(`:Set`/`:Emit`)을
가진 진짜 서브타입이라 "이 값이 (읽기 전용이 아니라) 쓰기도 되는
원천인가"를 알아야 하는 코드는 `isState`만으론 부족함 — `isSource`를
별도로 제공, `isState`는 여전히 `{State, Source}` 둘 다 통과시킴(상위
개념이니까 당연히). `component-composition-plan.md` 4번 절이 이미
`isSource`가 존재한다고 가정하고 있었던 것과도 이걸로 정합됨(그동안 두
문서가 서로 모순돼 있었음). `base/modifier-plan.md`의 "`isState(x): boolean` 필요" 절에 있던 "별도 `isSource` 불필요" 서술은
`session/2026-08-07-08-none-sentinel-dispatch-brand.md`에서 이미 정정됨.

**갭 보강 — `isRef`/`isPreRef`/`isModifier`가 목록에서 빠져있던 것
추가(2026-08-07 열 번째 세션), 이후 `isRef`/`isPreRef` 관계 자체가
재정정됨(2026-08-09 열한 번째 세션).** 처음엔 `isRef`/`isPreRef`를
`isObserver`와 같은 단순 항등으로 두고 서로 배타적인 형제 브랜드로
취급(`isRef(preRefInstance)`가 `false`)했으나, 이건 `isState`/`isSource`
쌍과 비일관적이었음 — `Source`가 State를 구조적으로 만족하듯,
**`PreRef`도 "Ref 런타임을 그대로 재사용하는" 관계라 같은 포함
방향(상위=Ref, 하위=PreRef)으로 다뤄야 일관적**이라는 지적으로 뒤집힘.

- **`isPreRef(x)`가 가장 구체적인 항등 체크**(`PreRefBrand:is(x)`),
  **`isRef(x)`는 그 위에 `RefBrand:is(x)`를 OR로 얹은 상위 개념** — 즉
  **`isRef(preRefInstance)`는 `true`.**
- **`(v=Ref)` children 배열 leaf 매치 핸들러(`Dispatch/Leaf.luau`)는
  이제 `isHandlable`을 `isRef(v) and not isPreRef(v) and not isPostRef(v)`로
  명시적으로 좁혀야 함**(**[2026-08-14 아홉 번째 세션]** `PostRef` 확정으로
  제외 항이 하나 늘어남) — 예전처럼 `isRef` 자체가 배타적이라 저절로
  걸러지는 게 아니라, "Ref이긴 한데 그 중 Pre/Post는 아니다"를 호출부가
  명시적으로 말해야 하는 모양으로 바뀜(두 pre-pass 소진이 이미 걸러줘
  정상 경로에선 거의 안 걸리지만, `base/ref-plan.md`의 두 동적 경로 가드
  Handler와 이 조합이 같이 "일반 Ref 경로를 절대 타면 안 됨"을 보장).
  `isModifier`도 같은 단순 항등(`ModifierBrand:is(x)`, 상위 개념 없음).
- **`PostRef`도 `PreRef`와 완전히 같은 포함 방향** — `Ref` 런타임을 그대로
  재사용하고 브랜드만 다르므로 `isRef(postRefInstance)`도 `true`.
  즉 `isRef`는 이제 `{Ref, PreRef, PostRef}` 셋을 통과시키는 상위 개념이고,
  `isPreRef`/`isPostRef`가 각각 가장 구체적인 항등 — `PreRef`/`PostRef`
  사이엔 포함 관계가 없음(서로 배타적인 형제).

**같은 이유로 `isSlot`/`isEffect`도 명시(2026-08-09 세션)** —
`SlotBrand:is(x)`/`EffectBrand:is(x)`인 단순 항등 predicate, 브랜드
자체는 원래부터 목록에 있었지만 `isX` wrapper로 명시적으로 안 적혀 있던
것을 `base/modifier-plan.md`의
"Modifier 필드에 핸들러 계층 값(Ref/PreRef/PostRef/Observer/Effect/Slot/Modifier)이
들어오면 즉시 error" 절이 필요로 해서 이번에
같이 적음.

**[정정, 2026-08-18 구현 전 QA] `Brand`는 아무 의존성도 갖지 않는다 —
`None`을 위한 특수 분기를 두지 않는다.** 옛 서술은 판별 창구가 범용
introspection을 겸하려면 `None`도 빠지면 안 되므로 *"내부적으로 `x == None`을
먼저 확인하는 특수 분기를 하나 두고"* 그 뒤에 레지스트리 조회로 폴백하며,
`isNone`이 그 특수 분기의 구현체가 된다고 했다. 사용자 판정: *"Brand 는 None 을
참조할 필요는 없음. Brand 자체는 아에 의존성 없고, None 도 테깅되는건 맞으나,
isNone 대신 필요한 곳에서 v == None 하면 되는 일, 혹은 isNone 구현 자체를
그렇게 해주면 되는 일."*

- **`Brand → None` 의존을 만들지 않는다** — 특수 분기를 넣는 순간 가장
  밑바닥 유틸이어야 할 `Brand`가 다른 프리미티브를 참조하게 된다.
- **`isNone`은 그냥 `v == None`** — 그런 이름의 함수를 두더라도 구현이
  레퍼런스 비교 한 줄이면 된다. 싱글턴이라 그게 제일 싸고 정확하다는 판단
  자체는 그대로 유효.
- **`None`을 `NoneBrand`에 평범하게 등록하는 것 자체는 무방**(사용자가
  허용) — 다만 **[2026-08-21]** 역조회 창구가 없어졌으므로 등록의 유일한
  효용은 `NoneBrand:is(x)`뿐이고, 그건 `v == None`이 더 싸다. 어느 쪽이든
  `Brand` 쪽 코드는 그대로다.

**duck-typing(예: `type(x) == "table" and x.Compute ~= nil`)을 쓰지 않는
이유 — 서로 독립된 두 가지(2026-08-20 `B-4`에서 분리 명시)**:

1. **정확성: false positive.** `Peek`가 돌려주는 `T`는 Modifier 필드에 들어갈
   수 있는 **임의의 사용자 값**이다. 사용자가 우연히 `Compute`라는 필드를 가진
   테이블을 넣으면 quad가 그걸 `State`로 오인한다. 브랜드는 quad가 만든 값에만
   찍히므로 이 오인이 원천적으로 없다.
2. **안전성/비용: 인덱싱 자체가 터질 수 있음.** 일부 Roblox userdata는 **정의
   안 된 키를 인덱싱하는 것만으로 에러를 던진다** — duck-typing을 하려면 판별
   코드를 전부 `pcall`로 감싸야 하고, 그건 "판별은 부작용 없이 빠르게"라는
   `isHandlable` 계약(`base/dispatch-core-plan.md`의 "핸들러 계약" 절)과
   정면으로 부딪힌다. 최악의 경우 엔진이 죽는 상황까지 있다.

weak-key 조회는 포인터 해싱 한 번이라 `pcall`도, 오인도 없다. 브랜드마다
집합이 갈려도 **조회 비용은 그대로 한 번**이고, `isState`처럼 OR로 합성된
predicate만 최대 브랜드 수만큼 조회한다(전부 2~3개).
weak-key 레지스트리는 rbvm 네임스페이스 추적(`base/lifecycle-pattern.md`)과
같은 이미 확정된 패턴 재사용이라 새 아이디어 아님 — weak 키라 등록된 값이
GC되면 엔트리도 자동으로 사라짐(살려두는 목적의 강참조 레지스트리인
Observer의 `:Subscribe` 레지스트리와는 반대 성격).

**Luau 타입 narrowing은 자동으로 안 됨 — 명시적 `::` 캐스팅 필요(사용자
확인, Luau가 원래 그렇게 동작함).** `isX(v)`가 참이어도 Luau 컴파일러가
`v`의 정적 타입을 알아서 좁혀주진 않음(TypeScript의 `x is T`류 사용자
정의 타입 가드를 Luau가 지원 안 함) — `if isState(v) then local s = v ::
State<any> ... end`처럼 런타임 검증 뒤 명시적 캐스팅을 붙이는 게 실제
패턴. 여전히 duck-typing/`pcall`보다 훨씬 안전하니 가치는 있음, 다만
"자동 narrowing"을 기대하면 안 됨.

**마일스톤**: **커밋된 M1 코드는 아직 `Brand`를 안 쓴다**(`quad-base/src`는
`init.luau`/`Relate.luau`/`Debug`뿐, 2026-08-21 확인) — 이 재작성의 전환
비용은 문서뿐이었다. 실제 구현은 각 프리미티브가 만들어지는 마일스톤에서
같이 간다.

**이름은 전부 가칭 — `Brand`/`ObserverBrand`류 포함 용어 정리 대상,
`.claude/question.md`에 반영.**
