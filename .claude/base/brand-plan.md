# `Brand` — 런타임 nominal 타입 판별 통합 메커니즘

> **[2026-08-13 아홉 번째 세션] `bind-system-plan.md`에서 분리됨.**
> 자기 완결적인 유틸이라 디스패치 코어와 같은 파일에 있을 이유가 없었음.
>
> **[2026-08-21 전면 재작성] 공유 레지스트리 + `Brand.get(x) -> tag`(객체당
> 태그 하나)에서 **인스턴스 브랜드**(`Brand()` + `:Register`/`:Is` — **[2026-09-15] 옛 소문자
> `:register`/`:is`에서 개명**, 아래 "메소드 이름" 문단, 다중 태깅
> 허용)로 바뀜.** 역전 원문은 `archive/brand-shared-registry-reversed.md`,
> 근거 기록은 `reference/epoch-brand-composition.md`. **뒤집힌 건 API 표면
> 하나뿐**이고 weak-key 레지스트리·테이블 아이덴티티·duck-typing 기각 근거·
> predicate 합성은 전부 그대로다.

**상태**: base — 동작/구현 방식은 확정, ~~**이름 `Brand` 자체만 용어 정리~~ **[2026-09-16 해소 — 이름 `Brand` 유지, 사용자 결정(`question.md` 1번)]** ~~정리
대기**(`question.md` 1번).

## `Brand` — 런타임 nominal 타입 판별 통합 메커니즘, `isState`를 일반화 (2026-08-07 여덟 번째 세션)

**배경**: `isState`(2026-08-07 다섯 번째 세션 확정, `:Peek<<T>>(key):
T|State<T>|nil`가 돌려주는 raw union을 사용자 코드가 분기하려면 판별
수단이 필요했음)와 똑같은 필요가 quad의 다른 branded 타입에도 전부
적용됨 — `Observer`/`Effect`/`Tag`/`Attr`/`Tween`/`Blocker`/`Store`/
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

**⭐ [2026-09-07 사용자 결정 — 팩토리의 자리] `Brand()` 팩토리는 `quad-types`에 산다
(`QuadTypes.Brand`, 런타임 값), 브랜드 *인스턴스*와 `isX` 술어는 패키지마다 자기 `Brand.luau`가
만든다** — quad-base(`State`/`Slot`/`Tag`/… 전부), quad-roblox(`TweenBrand`/`isTween`, Tween과
함께 이동), 장래 quad-spring(`SpringBrand`). 사용자 원문: *"Brand 에 대한 구현은 types 로 빼고싶어.
실제로 타이핑을 하는데 있어서 필요한 요소이고, 노미널타이핑을 돕는다 이외의 동작이 없어서 enum 과
비슷하게 특수 런타임 객체로 types 안에 실어두는게 좋아보여. 실제로 20줄도 되지 않거든 … quad-spring
같은 곳에서도 SpringBrand 를 만들려면 선재로 미리 처놔야하는 것으로 보여"*. quad-types의 "런타임
로직 0" 서술(`quad-types-plan.md`)은 이 팩토리 하나만큼 예외다. 아래 의미론(weak 집합·자기 등록·
다중 태깅·역조회 없음·무의존)은 그대로이고, 아래 코드 블록의 `TweenBrand`는 이제 quad-roblox 것.

**[2026-09-08 사용자 결정 — 프로바이더 브랜드의 계약(round3 §4 Q27)]** 프로바이더·플러그인은 자기
브랜드 술어를 **모듈 최상위 `is<Brand>` 필드**로 설치한다(`quad.isTween`, 장래 `quad.isSpring`). 그
필드가 곧 등록이다 **[2026-09-28 Q106 정정 — 필드는 계약 그대로이되 "무엇이 브랜드 술어인가"의 표시는 아래 배너의 `BrandPredicates` 등록이 한다]** — quad-base의 무매치 진단(`Dispatch/init.luau` `brandNameOf`)은 모듈에서 `is*`
함수 필드를 스캔해 ~~base 목록보다 먼저 시도하고~~(**[2026-10-01]** base 목록은 없어졌다 — 아래 2026-10-01 배너), 이름의 `is` 뒤를 브랜드 이름으로 쓴다. 별도 등록
op(`Dispatch.addBrandProbe` 류 — **Dispatch** 쪽 op)는 두지 않는다(사용자: *"저런 헬퍼를 만들 이유는 못 느끼는중 …
Dispatch 에 오는게 맞는지 모르겠음"*). 하위 모듈이 base를 require하지 못하고 런타임 주입으로 받는
구조라 `module.isX` 조회가 유일한 길이라는 점도 사용자 진단.
**[2026-09-28 round13 Q106 — 사용자 제안·결정, 이름 `BrandPredicates`]** 필드 계약은 그대로 두고 **무엇이 브랜드
술어인가**를 표시로 정한다 — **모듈 인스턴스**가 등록 집합 `q.BrandPredicates = Brand()`를 갖고(`New()`마다),
프로바이더가 설치 때 자기 술어를 `quad.BrandPredicates:Register(isX)`한다(quad-roblox `RobloxFactory.luau`의 `isTween`).
~~base 브랜드는 `BRAND_PROBES` 이름 목록으로 닿으므로 등록하지 않는다~~(**[2026-10-01 역전]** base 술어도 등록하고 그 목록은 지웠다 — 아래 배너). `brandNameOf`는
`is*` 필드 중 `BrandPredicates:Is(fn)`인 것만 스캔한다 — 옛 `{}`/`0` 시험 호출(`H-563`)은 삭제됐고, 그것이
못 거르던 `isNonEmptyList`·필드를 보는 헬퍼(`H-698`)도 이제 무시된다. Q27이 기각한 것(Dispatch 등록 op —
"필드가 계약", "하위 모듈은 런타임 주입")과 부딪히지 않는다: 필드는 계약 그대로이고 표시는 모든 패키지가
모듈 인스턴스(프로바이더가 설치 때 받는 바로 그것)에 둔다. **[같은 날 code-review 뒤 사용자 결정]** 처음엔
quad-types 전역(`QuadTypes.BrandPredicates`)에 두고 base 열여덟도 등록했으나 — quad-types는 구조적으로 사본이 여럿일
수 있어(서브모듈 등) 원천이 하나가 아니게 된다(사용자: *"런타임 모듈 하나가 원천이다로 보면 깔끔하게 떨어져"*,
에러 네임스페이스를 모듈로 건넨 `H-231`과 같은 결), base 등록은 Dispatch가 읽지 않는 넷째 목록이었다 → 모듈 인스턴스로
옮기고 base 등록을 뺐다. 이름은 sonnet 외부자·내부자 명명 판정 뒤 사용자 결정 — `<X>Brand`
("X 값의 집합") 꼴의 `PredicateBrand`는 "Predicate라는 값의 브랜드"로 읽혀 모호했다.
**[2026-10-01 사용자 결정 — base 술어도 같은 경로, 손 목록 `BRAND_PROBES` 삭제]** quad-base가 `q.isX` 필드를 모듈에
다는 바로 그 자리(`init.luau` 모듈 리터럴의 `brandPredicate(...)`, `Slot/init.luau`의 `module.isSlot`)에서 같은
`module.BrandPredicates`에 `:Register`한다 — **공개된 `is*` 술어 = 등록된 브랜드 술어**(열여덟, `spec.dispatch` 2절이
"새 `q`의 `is*` 필드는 전부 등록돼 있다"로 지킨다). Dispatch는 base 브랜드를 이름으로 알지 않는다(`H-278` — 같은 날
`None`/`StoreBind`를 Dispatch 밖으로 옮긴 것과 같은 방향): `brandNameOf`는 등록된 `is*` 필드를 전부 `pcall`로 묻고
**걸린 이름을 전부 이름순으로** 모은다(`Epoch, PreRef, Ref` — 옛 most-specific-first 순서 `H-220`은 첫 하나만 고르던
때의 규칙이라 필요 없어졌다). 무매치 힌트도 등록이 가른다 — 하나라도 걸리면 그 브랜드의 주인이 설치됐다는 뜻이라
quad 값 힌트(`Store`/`Context`/`Provider` 전용 힌트는 이름이 목록에 있으면), 아무것도 안 걸리면 오타·프로바이더 미설치
힌트; 그래서 Tween 같은 프로바이더 브랜드에 붙던 "provider not initialized" 힌트도 바로잡혔다. 사용자: *"어차피 에러
보여주기 경로라면 isRef 와 isPreRef 는 상관이 없는것 같음. 그냥 T 인데 A, B, C 를 impl하는 요소라고 알려주는게 문제가
없는것 같음 … 프로바이더가 등록되었다는 말은 … 존재하는 impl 경로를 해결(리졸브) 하는게 있다면 닫아져. 따라서 에러가 더
정보성 있으려면 전부 보여주는게 문제는 없는것 같아."* 위 2026-09-28 code-review 뒤 결정이 base 등록을 뺀 이유("Dispatch가
읽지 않는 넷째 목록")는 Dispatch가 이제 그 등록만 읽으므로 사라졌다 — 목록이 넷에서 하나 줄었다.

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
local ObserverBrand, EffectBrand, TagBrand, AttrBrand, TweenBrand,
      BlockerBrand, StateBrand, SourceBrand, StoreBrand, SlotBrand,
      RefBrand, PreRefBrand, PostRefBrand, ModifierBrand, EpochBrand =
      Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand(),
      Brand(), Brand(), Brand(), Brand(), Brand(), Brand(), Brand()

-- 각 타입의 모든 생성 지점(Observer(...), Source(...), :With(...), Tag(...) 등)에서:
ObserverBrand:Register(newHandle)
```

**⭐ 다중 태깅이 이 설계의 존재 이유다.** 한 값이 **여러 브랜드에 동시에**
속할 수 있다 — 실제로 그게 필요한 자리가 있다:

```lua
-- Source는 Source이면서 동시에 Epoch다 (base/state-epoch-plan.md)
SourceBrand:Register(source)
EpochBrand:Register(source)
```

옛 모양(`Brand.get(x) -> tag`, 객체당 태그 하나)으로는 이걸 표현할 수 없었고,
그게 재작성의 직접 발단이다 — `archive/brand-shared-registry-reversed.md`.

**부수 이득 — 외부 확장이 열린다.** `Source`가 아닌 원천(외부 시계 등)이
`Epoch`로 참여하고 싶으면 `EpochBrand:Register(self)` 한 줄이면 되고,
`isEpoch` 구현을 고칠 필요가 없다. 사용자 논거: *"본인이 거기 속하면, 본인이
직접 해당 브랜드를 가져와 등록하면 … `isXXXX`에서 각각의 구현을 넣을 필요가
없어짐. 따라서 외부 확장도 쉬워진다."*

**[2026-10-01 내부 정리 — 사용자 결정] 두 번째 능력 브랜드 `BindableBrand`**(`EpochBrand`처럼 여러 타입이 자기
브랜드 옆에서 같이 등록 — 지금은 Observer/Effect). `bindLifetime`/`unbindLifetime`/`canExecute`가 타입 분기 대신
이 멤버십 하나만 보고, 회원의 훅(`_assertBindable`/`_afterBind`/`_beforeUnbind`)과 계약 필드 `Subscribed`를 쓴다
(`base/lifecycle-pattern.md`의 "(0.5)" 절 배너). **내부 전용이라 `isX` wrapper도 `q.` 재노출도 없다** — 아래
"`isX` wrapper" 절의 예외이고, 쓰는 자리가 `LifetimeHandle.luau` 하나라 `:Is`를 직접 부른다. 공개 등록 표면은
백로그(`research/bindable-hooks-plan.md`).

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

**메소드 이름은 PascalCase `:Register`/`:Is`다 — [2026-09-15 사용자 결정, 옛 소문자에서 개명].**
옛 소문자 `:register`/`:is`는 `Brand.set`/`Brand.get` 관례를 이은 것이었고, 근거는 "사용자가 직접
부르는 프리미티브가 아니라 base 내부 유틸"이었다. 2026-09-07에 팩토리가 quad-types로 옮겨 서드파티
백엔드(장래 quad-spring 등)가 자기 브랜드를 만드는 **공개 표면**이 되면서 그 근거가 소멸했고,
`research/public-surface-pre-adoption-review.md` (13)번 권고에 사용자가 동의했다(*"13번 Brand 메소드를
대문자로 바꾼다 -> 동의"*). 사용자 코드가 보는 건 여전히 `isX` wrapper들이라 소비자 코드는 안 바뀐다.
`Brand`라는 **이름 자체**는 ~~여전히 `question.md` 1번의 용어 정리 대기 항목이다~~ **[2026-09-16 해소 — 유지]**(`question.md` 1번).

## `isX` wrapper — 포함 관계는 predicate 합성으로 (2026-08-09 열한 번째 세션)

**`isX`는 브랜드를 직접 노출 안 하고 각자 얇은 wrapper로 감쌈** — 단순
항등인 경우(`isObserver(x) = ObserverBrand:Is(x)`)와, 상위 관계(subtype)가
있어 **더 구체적인 브랜드 체크 위에 OR로 얹는** 경우(`isState`/`isRef`)로
갈림. **[정정, 2026-08-09 열한 번째 세션]** 후자를 "집합 멤버십"(플랫한 셋
체크)으로 구현하던 방식을 "더 구체적인 predicate를 먼저 정의하고 그 위에
얹는" 합성 방식으로 재정리 — 동작은 동일하지만, 어느 predicate가 다른
predicate를 내포하는지(포함 관계의 방향)가 코드 모양 자체에 드러나게 함:

```lua
local function isSource(x)
  return SourceBrand:Is(x)
end
local function isState(x)
  return isSource(x) or StateBrand:Is(x)  -- Source가 State를 구조적으로 만족
end

local function isPreRef(x)
  return PreRefBrand:Is(x)
end
local function isPostRef(x)                     -- [2026-08-14 아홉 번째 세션] PostRef 확정
  return PostRefBrand:Is(x)
end
local function isRef(x)
  -- PreRef/PostRef가 Ref 런타임을 재사용 = 둘 다 Ref의 한 종류
  return isPreRef(x) or isPostRef(x) or RefBrand:Is(x)
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

- **`isPreRef(x)`가 가장 구체적인 항등 체크**(`PreRefBrand:Is(x)`),
  **`isRef(x)`는 그 위에 `RefBrand:Is(x)`를 OR로 얹은 상위 개념** — 즉
  **`isRef(preRefInstance)`는 `true`.**
- **`(v=Ref)` children 배열 leaf 매치 핸들러(M8 — `H-278`로 `Ref/init.luau` 소유)는
  이제 `isHandlable`을 `isRef(v) and not isPreRef(v) and not isPostRef(v)`로
  명시적으로 좁혀야 함**(**[2026-08-14 아홉 번째 세션]** `PostRef` 확정으로
  제외 항이 하나 늘어남) — 예전처럼 `isRef` 자체가 배타적이라 저절로
  걸러지는 게 아니라, "Ref이긴 한데 그 중 Pre/Post는 아니다"를 호출부가
  명시적으로 말해야 하는 모양으로 바뀜(두 pre-pass 소진이 이미 걸러줘
  정상 경로에선 거의 안 걸리지만, `base/ref-plan.md`의 두 동적 경로 가드
  Handler와 이 조합이 같이 "일반 Ref 경로를 절대 타면 안 됨"을 보장).
  `isModifier`도 같은 단순 항등(`ModifierBrand:Is(x)`, 상위 개념 없음).
- **`PostRef`도 `PreRef`와 완전히 같은 포함 방향** — `Ref` 런타임을 그대로
  재사용하고 브랜드만 다르므로 `isRef(postRefInstance)`도 `true`.
  즉 `isRef`는 이제 `{Ref, PreRef, PostRef}` 셋을 통과시키는 상위 개념이고,
  `isPreRef`/`isPostRef`가 각각 가장 구체적인 항등 — `PreRef`/`PostRef`
  사이엔 포함 관계가 없음(서로 배타적인 형제).

**같은 이유로 `isSlot`/`isEffect`도 명시(2026-08-09 세션)** —
`SlotBrand:Is(x)`/`EffectBrand:Is(x)`인 단순 항등 predicate, 브랜드
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
  효용은 `NoneBrand:Is(x)`뿐이고, 그건 `v == None`이 더 싸다. 어느 쪽이든
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
