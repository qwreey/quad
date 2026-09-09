---
title: 생명주기와 센티널
description: None/Detach/KeyGone/Void 센티널, q.dispose, 매퍼 루트, 그리고 백엔드가 심는 생명주기 프리미티브 넷
---
값이 아니라 **뜻**을 나르는 상수들(센티널), 관리 중인 값을 파괴하는 유일한 경로 `q.dispose`, 그리고 quad-base가 인터페이스만 두고 백엔드가 실제 구현을 심는 생명주기 프리미티브 넷을 모읍니다.

센티널은 전부 `table.freeze`된 테이블 하나이고 **판정은 언제나 신원 비교**(`v == q.None`)입니다. 타입에 붙어 있는 마커 필드(`__quadNone` 등)는 유니언 타입을 표현하기 위한 조언층일 뿐, 그걸로 판정하지 않습니다.

이 페이지의 심볼: [q.None](#qnone) · [q.Detach](#qdetach) · [q.KeyGone](#qkeygone) · [q.Void](#qvoid) · [q.dispose(value)](#qdisposevalue) · [q.MapperRoot](#qmapperroot) · [q.newMapperClass(className)](#qnewmapperclassclassname) · [q.bindLifetime(inst, value)](#qbindlifetimeinst-value) · [q.unbindLifetime(value)](#qunbindlifetimevalue) · [q.canBound(value)](#qcanboundvalue) · [q.canExecute(value)](#qcanexecutevalue)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

## `q.None`

**시그니처**

```luau
None: None
-- export type None = { read __quadNone: true }
```

**동작** — "명시적으로 없음"을 뜻하는 값입니다. `nil`과 달리 **실재하는 값**이라, 배열 부분에 들어가도 구멍(nil-hole)을 만들지 않고 순서가 있는 자리를 그대로 채웁니다. 그래서 조건부 자식·조건부 Modifier를 쓸 때 `props.Modifier or q.None` 관용구가 성립합니다.

디스패치에서의 뜻은 "여기서 아래로는 아무것도 하지 마라"입니다. `None`은 배열이든 해시든 어느 자리에서나 매치되며, 그 자리의 다음 우선순위 핸들러에게 `nil`을 내려보냅니다. 해시 키에 놓으면 그 키를 담당하는 핸들러가 `nil`을 값으로 받습니다 — 그 `nil`을 어떻게 해석할지는 그 핸들러가 정합니다.

- `tostring(q.None)`은 `"None"`입니다(진단용).
- frozen이라 필드를 덧붙일 수 없습니다.
- 같은 quad-base 사본 안에서는 모든 모듈 인스턴스가 같은 객체를 공유합니다.
- 판정용 술어(`isNone`)는 없습니다 — `v == q.None`으로 비교합니다.

**예제**

```luau
local function Card(props)
	return D.Frame {
		props.Modifier or q.None, -- 배열 부분: nil을 넣으면 뒤 항목이 사라진다
		D.TextLabel { Text = props.Title },
	}
end
```

## `q.Detach`

**시그니처**

```luau
Detach: Detach
-- export type Detach = { read __quadDetach: true }
```

**동작** — `Slot:List`/`Slot:Single`의 `updateFn`이 **결과 자리에 반환**하는 센티널입니다. "이 요소를 파괴하지 말고 붙잡아 둬라" — 요소는 물리 트리에서 빠지지만 파괴되지 않고 Slot이 계속 들고 있다가, 같은 키가 다시 나타나면 `prev`로 되돌아옵니다. 반환하지 않고 값 자리에 두는 용도가 아닙니다.

같은 자리에서 `nil` 또는 `q.None`을 반환하면 파괴, 요소를 반환하면 그 요소가 그 자리에 놓입니다.

보관·복귀 규칙과 실제 `updateFn` 예제는 [Slot](/quad/ko/reference/core/07-slot/)이 자세합니다.

## `q.KeyGone`

**시그니처**

```luau
KeyGone: KeyGone
-- export type KeyGone = { read __quadKeyGone: true }
```

**동작** — `updateFn`의 **`item` 자리로 들어오는** 센티널입니다. 지난 사이클에 있던 키가 이번 데이터에서 사라졌을 때, 그 키를 어떻게 처리할지 묻기 위해 한 번 더 호출하면서 실제 항목 대신 이 값을 줍니다.

이 호출에서 돌려줄 수 있는 것은 `nil`/`q.None`(파괴)과 `q.Detach`(홀드) 둘뿐입니다. 요소를 돌려주면 에러입니다 —

```
Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)
```

재조정 사이클 안에서 언제 이 호출이 오는지는 [Slot](/quad/ko/reference/core/07-slot/)을 보세요.

## `q.Void`

**시그니처**

```luau
Void: (...any) -> ()
```

**동작** — quad가 내보내는 단 하나의 no-op 함수입니다. 어떤 인자를 줘도 아무 일도 하지 않고 **아무것도 반환하지 않습니다**(`select("#", q.Void(1, 2, 3))`은 `0`).

새 클로저를 만들지 않기 위한 공용 값입니다. 디스패치 핸들러가 "무를 것이 없다"는 뜻으로 retractor 자리에 돌려주는 값이 바로 이것이고([`../extend/02-dispatch-handler-contract.md`](/quad/ko/reference/extend/02-dispatch-handler-contract/)), retractor를 아예 생략하는 것은 계약 위반입니다. 모든 모듈 인스턴스가 같은 함수 객체를 공유합니다.

## `q.dispose(value)`

**시그니처**

```luau
dispose: (value: any) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `value` | `any` | 파괴할 값 — Slot이거나, 백엔드가 요소로 인정하는 값(`q.isInst`가 참) |

**반환** — 없음.

**동작** — quad가 관리하는 값을 파괴하는 **유일한 안전 경로**입니다. Slot이면 그 Slot 트리를 통째로 파괴하고, 백엔드 요소면 주입된 파괴 op를 부릅니다.

누가 들고 있는 값은 파괴하지 않습니다. 어떤 Slot의 원소이거나 마운트된 자리를 차지하고 있으면 먼저 그 자리에서 빼야 합니다.

에러 문구는 셋입니다.

```
dispose: value must not be nil
dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, or destroy the owner Slot (a detached element goes with its owner) (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
dispose: this backend cannot dispose this value
```

마지막 문구는 "Slot도 아니고 이 백엔드의 요소도 아니다"라는 뜻입니다. 백엔드가 설치되지 않은 모듈에서는 그 전에 `q.isInst` 스텁이 먼저 던집니다(아래 참고).

**예제**

```luau
local slot = q.Slot()
local child = D.Frame {}
slot:Add(child)

slot:Extract(1) -- 파괴하지 않고 자리에서 뺀다(Remove는 파괴한다)
q.dispose(child) -- 그 다음에 파괴
```

Slot 쪽 맥락(마운트 규칙, 죽은 Slot)은 [Slot](/quad/ko/reference/core/07-slot/)에 함께 있습니다.

## `q.MapperRoot`

**시그니처**

```luau
MapperRoot: MapperRoot
-- export type MapperRoot = { read __quadMapperRoot: true }
```

**동작** — `Claim`의 매퍼 디스크립터에서 "이 노드가 루트다"를 뜻하는 키 센티널. quad-roblox에서는 `D.Mapper.Root`로 다시 노출됩니다. 자세한 사용법은 [`../roblox/04-claim-mapper.md`](/quad/ko/reference/roblox/04-claim-mapper/).

## `q.newMapperClass(className)`

**시그니처**

```luau
newMapperClass: (className: string) -> (key: any) -> (props: any) -> MapperDescriptor
```

**동작** — 클래스 이름 하나를 받아 매퍼 디스크립터 팩토리를 만드는 제네릭 생성자. 백엔드의 `D.Mapper.<Class>` 별칭이 전부 여기서 나옵니다. 결과 디스크립터는 `q.isMapperDescriptor`가 참이고, `q.Claim(inst, desc)`에 넘깁니다 — [`../roblox/04-claim-mapper.md`](/quad/ko/reference/roblox/04-claim-mapper/).

## `q.bindLifetime(inst, value)`

**시그니처**

```luau
bindLifetime: (inst: any, value: any) -> ()
```

**동작** — 값 하나의 수명을 요소(`inst`)의 수명에 묶습니다. 요소가 죽으면 묶인 값들도 같이 수거되고, 구독은 그때부터 발화하지 않습니다.

**⚠️ quad-base에는 구현이 없습니다.** 이 네 함수와 엔진 op들은 백엔드가 모듈 인스턴스에 뮤테이션으로 심습니다 — quad-base는 임의의 엔진에서 "옳은" 기본값을 추측할 수 없으므로, 조용한 no-op 대신 **크게 우는 스텁**을 둡니다. 프로바이더를 설치하지 않은 `Quad.New()`에서 부르면:

```
quad: bindLifetime is not available — no backend has installed the lifetime primitives / engine ops (install a provider with quad:UseProvider — a bare Quad.New() has none; tests use mock.installLifetime)
```

같은 문구가 이름만 바뀌어 `unbindLifetime`/`canBound`/`canExecute`, 엔진 op `onDestroying`·`isInst`·`nativeClaim`·`nativeFindChild`·`nativeInsert`·`nativeExtract`·`nativeRemove`·`nativeMove`·`nativeSwap`·`nativeDispose`, 시간 op `setTimeout`·`clearTimeout`에도 걸립니다. 각 슬롯이 무엇을 약속해야 하는지는 [`../extend/01-backend-provider-contract.md`](/quad/ko/reference/extend/01-backend-provider-contract/)가 정본입니다.

## `q.unbindLifetime(value)`

**시그니처**

```luau
unbindLifetime: (value: any) -> ()
```

**동작** — 묶인 값 하나를 미리 풉니다. 묶여 있지 않은 값이면 no-op이고, `nil`은 에러입니다. 나머지는 `q.bindLifetime`과 같습니다 — 백엔드가 심고, 미설치면 같은 모양의 스텁 에러가 납니다.

## `q.canBound(value)`

**시그니처**

```luau
canBound: (value: any) -> boolean
```

**동작** — "지금 이 값을 묶어도 되는가" — 어디에도 묶여 있지 않으면 참. 백엔드가 심고, 미설치면 스텁 에러.

## `q.canExecute(value)`

**시그니처**

```luau
canExecute: (value: any) -> boolean
```

**동작** — "지금 이 값이 발화해도 되는가" — 전파 게이트가 구독을 통과시킬지 판정할 때 묻습니다. 백엔드가 심고, 미설치면 스텁 에러.

`canBound(v) == not canExecute(v)`가 계약입니다 — 둘은 백엔드가 가진 하나의 비공개 술어를 서로 반대로 감싼 것입니다.

## 관련

- [Slot](/quad/ko/reference/core/07-slot/) — `Detach`/`KeyGone`이 실제로 오가는 `Slot:List`/`Slot:Single`
- [브랜드 술어](/quad/ko/reference/core/12-predicates/) — 센티널에 술어가 없는 이유
- [`../extend/01-backend-provider-contract.md`](/quad/ko/reference/extend/01-backend-provider-contract/) — 주입 슬롯 전체 목록과 계약
- [`../extend/02-dispatch-handler-contract.md`](/quad/ko/reference/extend/02-dispatch-handler-contract/) — `Void`를 retractor로 돌려주는 자리
- [`../../quadnomicon/03-luau-memory-topology.md`](/quad/ko/quadnomicon/03-luau-memory-topology/) — 생명주기 바인딩이 메모리 토폴로지에서 하는 역할
