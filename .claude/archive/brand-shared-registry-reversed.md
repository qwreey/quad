# [역전됨] `Brand` — 공유 레지스트리 + `Brand.get(x) -> tag` (객체당 태그 하나)

> **역전일**: 2026-08-21. **대체된 곳**: `base/brand-plan.md`(인스턴스 브랜드로
> 전면 재작성). **역전 근거 원문**: `reference/epoch-brand-composition.md` §1의
> 6번 / §3.
>
> **뒤집힌 것은 API 표면 하나뿐이다** — weak-key 레지스트리를 쓴다는 것,
> 태그가 문자열이 아니라 테이블 아이덴티티라는 것, duck-typing을 안 쓰는
> 두 근거, 포함 관계를 predicate 합성으로 표현한다는 것은 **전부 그대로
> 살아 있다**(`base/brand-plan.md`가 소스). 아래는 그 표면의 옛 모양만
> 보존한 것.

## 무엇이 뒤집혔나

**옛 모양** — 모듈 하나가 공유 레지스트리 하나를 들고, 객체마다 태그를
**정확히 하나** 붙인다. 판별은 그 태그를 되읽어 비교한다.

```lua
local Brand = {}
local registry = setmetatable({}, {__mode = "k"})

function Brand.set(x, tag) registry[x] = tag end
function Brand.get(x) return registry[x] end -- nil이면 quad가 모르는 값

-- 각 브랜드는 고유 테이블(빈 테이블이어도 됨) — 문자열 리터럴 아님
local ObserverTag, EffectTag, TagTag, AttributeTag, TweenTag, BlockerTag,
      StateTag, SourceTag, StoreTag, SlotTag, RefTag, PreRefTag, PostRefTag,
      ModifierTag =
      {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}

-- 각 타입의 모든 생성 지점(Observer(...), Source(...), :With(...), Tag(...) 등)에서:
Brand.set(newHandle, ObserverTag)
```

`isX`는 그 위에 얇게 얹혔다:

```lua
local function isSource(x)
  return Brand.get(x) == SourceTag
end
local function isState(x)
  return isSource(x) or Brand.get(x) == StateTag  -- Source가 State를 구조적으로 만족
end

local function isPreRef(x)
  return Brand.get(x) == PreRefTag
end
local function isPostRef(x)
  return Brand.get(x) == PostRefTag
end
local function isRef(x)
  -- PreRef/PostRef가 Ref 런타임을 재사용 = 둘 다 Ref의 한 종류
  return isPreRef(x) or isPostRef(x) or Brand.get(x) == RefTag
end
```

`None` 처리도 이 모양에 묶여 있었다 — *"`None` 자체를 레지스트리에
평범하게 태깅하는 건 무방(사용자가 허용) — 그러면 특수 분기 없이도
`Brand.get(None)`이 답을 준다. 즉 '범용 introspection 창구'를 지키고
싶으면 특수 분기가 아니라 평범한 등록으로 지킨다."*

## 왜 뒤집혔나

**표현할 수 없는 관계가 실재했다.** `Epoch` 인터페이스가 도입되면서
`Source`는 `SourceBrand`이면서 **동시에** `EpochBrand`여야 하는데,
"객체당 태그 하나" 모델로는 이걸 못 적는다. `Source`가 아닌 원천(외부
시계 등)이 `Epoch`로 참여하려면 다중 태깅이 필수다.

사용자 제안(2026-08-21): *"본인이 거기 속하면, 본인이 직접 해당 브랜드를
가져와 등록하면 … `isXXXX`에서 각각의 구현을 넣을 필요가 없어짐. 따라서
외부 확장도 쉬워진다."*

## 같이 버려진 것 — `Brand.get`의 역조회

옛 모양은 "이 값이 대체 무엇인가"를 되묻는 **범용 introspection 창구**를
겸했다. 새 모양엔 그게 없다(브랜드마다 자기 집합만 안다).

**대가가 아니었다** — 사용자 확인: *"확실히 의미가 없어진것 같습니다
필요하진 않아요."* 코퍼스가 실제로 쓰는 건 전부 `isX` 형태의 **멤버십
질문**이고, 역조회를 하는 자리는 전수 조사에서 하나도 없었다.

## 같이 검토됐다 철회된 우려 — "포함 관계가 코드에 드러난다"는 성질

에이전트가 "자기 등록 방식이면 `isRef`/`isState` 같은 포함 관계가 흩어진다"고
대가로 짚었으나 **착오였고 철회됐다.** 사용자 지적: *"여전합니다.
`PreRefBrand` 가 존재할테니. 거기에 `is()` 를 해서, 코드에 전부 드러나는거
똑같습니다."* — 자기 등록이 **여러 브랜드에 등록하기를 강제하는 게 아니므로**,
각 타입은 자기 브랜드에만 등록하고 포함 관계는 지금처럼 predicate 합성으로
한 곳에 쓰면 된다. 2026-08-09에 세운 성질이 그대로 유지된다.
