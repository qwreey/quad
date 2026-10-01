---
title: 브랜드 술어
description: 값이 어떤 quad 타입인지 판정하는 is* 술어 표 — 참인 값, 포함 관계, 신원 판정의 예외
---
# 브랜드 술어 (`is*`)

quad의 값 타입은 **브랜드**로 표시됩니다 — 생성 시점에 자기 브랜드(weak-key 집합)에 스스로 등록하고, `is*` 술어가 그 집합에 있는지 묻습니다. 구조(필드 모양)를 보지 않으므로 흉내낸 테이블은 통과하지 못하고, 역조회(값 → 브랜드 이름)는 없습니다.

이 페이지의 심볼: [술어 표](#술어-표) · [포함 관계](#포함-관계) · [브랜드가 없는 값](#브랜드가-없는-값) · [`q.BrandPredicates`](#qbrandpredicates) · [사본 경계](#사본-경계)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

## 술어 표

전부 `(x: any) -> boolean` 한 모양입니다(`q.Backend.isInst`만 파라미터 이름이 `value`). 부작용이 없고, 어떤 값을 줘도 던지지 않습니다 — 등록되지 않은 테이블·`nil`·숫자에는 그냥 `false`.

| 이름 | 참인 값 | 어디서 |
|---|---|---|
| `q.isEpoch(x)` | `q.Source(v)`, `q.Ref(v)`/`q.PreRef(v)`/`q.PostRef(v)` — `Revision`을 가진 값 | quad-base 기본 표면 |
| `q.isSource(x)` | `q.Source(v)` | quad-base 기본 표면 |
| `q.isState(x)` | `q.Source(v)`, `:Compute`/`:Depend`가 만든 파생 State, `:Gate`가 끼운 게이트 노드 | quad-base 기본 표면 |
| `q.isStore(x)` | `q.Store(defaults?)` | quad-base 기본 표면 |
| `q.isObserver(x)` | `state:Observer(fn)`이 돌려준 핸들 | quad-base 기본 표면 |
| `q.isEffect(x)` | `q.Effect(fn, ...deps)`가 돌려준 `Effect` | quad-base 기본 표면 |
| `q.isBlocker(x)` | `q.Blocker()` | quad-base 기본 표면 |
| `q.isContext(x)` | `q.Context()` | quad-base 기본 표면 |
| `q.isProvider(x)` | `q.Context.Provider(name?)` | quad-base 기본 표면 |
| `q.isModifier(x)` | `q.Modifier(...)`, `D.Modifier.<Class>(...)`, `Modifier.TypedFactory`로 만든 생성자의 결과 — 타입드든 아니든 전부 | quad-base 기본 표면 |
| `q.isRef(x)` | `q.Ref(v)`, `q.PreRef(v)`, `q.PostRef(v)` | quad-base 기본 표면 |
| `q.isPreRef(x)` | `q.PreRef(v)` | quad-base 기본 표면 |
| `q.isPostRef(x)` | `q.PostRef(v)` | quad-base 기본 표면 |
| `q.isMapperDescriptor(x)` | `D.Mapper.<Class>(key)(props)`, `q.newMapperClass(name)(key)(props)` | quad-base 기본 표면 |
| `q.isSlot(x)` | `q.Slot(initial?)`, 그리고 반응형 요소를 감싸며 내부적으로 만들어지는 래퍼 Slot | quad-base 기본 표면 |
| `q.isTag(x)` | `q.Tag(...)`, `Tag.Merged(...)`, `tag:Added(...)`/`:Removed(...)`의 결과 | quad-base 기본 표면 |
| `q.isAttr(x)` | `q.Attr(...)`, `q.StringAttr`/`q.NumberAttr`/`q.BooleanAttr`가 만든 단일 항목 그룹 | quad-base 기본 표면 |
| `q.isAttrKey(x)` | `q.AttrKey(name)`, 그리고 `Attr` 그룹이 이름마다 내부로 쓰는 키 객체 | quad-base 기본 표면 |
| `q.Backend.isInst(value)` | 백엔드가 "요소"로 인정하는 값 — quad-roblox면 실제 `Instance` | **백엔드 주입** (미설치면 에러) |
| `q.isTween(x)` | `q.Tween{ ... }` | **quad-roblox 확장** |

시그니처의 정본은 `quad-types/src/init.luau`의 `Quad` 레코드입니다. 한 묶음에 몰려 있지는 않습니다 — `isEpoch`부터 `isMapperDescriptor`까지는 브랜드 술어 묶음에, `isSlot`은 `Slot` 표면과 함께, `isTag`/`isAttr`/`isAttrKey`는 Tag/Attr 표면과 함께, `isInst`는 주입 슬롯 묶음에 선언돼 있습니다. `isTween`은 `quad-roblox/src/init.luau`의 `RobloxExtension`에 있습니다 — 백엔드 값의 브랜드는 백엔드 표면이 싣습니다.

## 포함 관계

세 술어는 다른 술어의 상위 집합입니다. 값을 분기할 때 좁은 쪽을 먼저 물어야 합니다.

- `q.isState(x)`는 `q.isSource(x)`를 포함합니다 — `Source`는 구조적으로 `State`입니다.
- `q.isRef(x)`는 `q.isPreRef(x)`와 `q.isPostRef(x)`를 포함합니다 — 셋은 같은 런타임을 쓰고 브랜드만 다릅니다. `PreRef`와 `PostRef`는 서로 배타입니다.
- `q.isEpoch(x)`는 가장 넓습니다 — `Source`와 세 종류의 `Ref`가 전부 참입니다.

한 값이 여러 브랜드를 동시에 가질 수 있다는 뜻이기도 합니다. `q.PreRef(nil)` 하나에 대해 `isEpoch`/`isRef`/`isPreRef`가 전부 참입니다. 디스패치의 진단 메시지도 그 값이 답하는 브랜드를 전부 이름순으로 싣습니다 — `brand: Epoch, PreRef, Ref`([`Quad0076`](../errors/02-dispatch-bookkeeping.md#quad0076)).

## 브랜드가 없는 값

- **센티널** — `q.None`/`q.Detach`/`q.KeyGone`/`q.MapperRoot`에는 브랜드가 없고 술어도 없습니다. 판정은 언제나 신원 비교입니다: `v == q.None`. (`isNone`이라는 함수는 없습니다.)
- **`q.Relate()`가 돌려주는 릴레이션**, `q.Void` 같은 잎 유틸도 브랜드 대상이 아닙니다.
- 프로바이더가 자기 값 타입을 추가할 때는 모듈 표면에 `is<Brand>` 필드를 얹고, 그 술어를 [`q.BrandPredicates`](#qbrandpredicates)에 **등록**합니다 — 디스패치가 매치 실패 진단과 props 검사에서 값의 브랜드 이름을 찾을 때 모듈의 `is*` 필드 중 **등록된 함수만** 봅니다(`quad-base/src/Dispatch/init.luau`). `q.isTween`이 그 첫 사례입니다. 그래서 모듈에 `is`로 시작하는 평범한 헬퍼(`isEmpty`, `isNonEmptyList`, 인자를 무시하는 `isMobile`)를 붙여도 등록되지 않았으니 스캔이 무시합니다.

## `q.BrandPredicates`

**시그니처**

```luau
BrandPredicates: Brand -- QuadTypes.Brand() 인스턴스 하나, 모듈 인스턴스(q.New())마다
```

**브랜드 술어의 등록 집합**입니다. 프로바이더가 자기 값 타입의 `is<Brand>` 술어를 모듈에 얹을 때 여기에도 등록합니다 — 설치 함수가 받은 모듈로 `quad.BrandPredicates:Register(isX)`. 디스패치가 매치 실패 진단(메시지의 `brand: …`)과 props 검사(중괄호를 빠뜨린 `D.Frame(value)` 거부)에서 값의 브랜드를 찾을 때, 모듈의 `is*` 필드 중 **이 집합에 등록된 함수만** 브랜드 술어로 봅니다 — 사용자가 모듈에 붙인 `is*` 헬퍼는 등록되지 않았으니 무시됩니다. quad-base 자신의 브랜드 술어(위 표의 `q.isX`)도 `q.New()`가 모듈을 만들면서 **같은 집합에 등록합니다** — 모듈의 공개 `is*` 술어는 곧 등록된 브랜드 술어이고, 디스패치는 quad-base 브랜드라고 따로 아는 목록을 두지 않습니다. 진단은 등록된 술어 가운데 걸린 것을 **전부, 이름순으로** 싣고, 하나라도 걸리면 그 브랜드의 주인이 설치돼 있다는 뜻이라 "프로바이더가 설치됐는지 확인하라"는 꼬리 대신 quad 값용 꼬리를 답니다.

- 등록을 빠뜨려도 동작은 그대로이고, 그 브랜드의 진단만 약해집니다(브랜드 이름이 메시지에 안 실리고 꼬리가 "프로바이더 미설치" 쪽으로 나가며, 중괄호를 빠뜨린 호출을 못 막음).
- 집합은 모듈 인스턴스에 있습니다 — `quad_types` 사본이 여럿이어도 원천이 하나로 떨어지도록([사본 경계](#사본-경계)).

## 사본 경계

브랜드 집합은 **quad-base 사본마다** 따로 삽니다. 같은 프로젝트에 quad-base가 두 벌 설치돼 있으면 A 사본이 만든 `Source`는 B 사본의 `q.isSource`에서 `false`입니다 — 술어가 구조가 아니라 등록 여부를 보기 때문입니다. 같은 이유로 프로바이더 신원(`q.Context.Provider`)도 사본을 넘지 못합니다.

`q.New()`로 인스턴스를 여러 개 만드는 것은 여기 해당하지 않습니다 — 브랜드는 모듈 인스턴스가 아니라 **파일(사본)** 단위라, 한 사본에서 만든 인스턴스들은 서로의 값을 알아봅니다.

## 관련

- [생명주기와 센티널](./10-lifetime-sentinels.md) — 술어가 없는 센티널들과 주입 op
- [Quad 모듈](./01-quad-module.md) — 모듈 인스턴스와 프로바이더 설치
- [`../extend/01-backend-provider-contract.md`](../extend/01-backend-provider-contract.md) — `isInst` 등 주입 슬롯의 계약
- [`../../quadnomicon/04-covariant-markers.md`](../../quadnomicon/04-covariant-markers.md) — 브랜드(런타임 판정)와 마커 필드(타입 조언층)가 왜 둘 다 있는가
