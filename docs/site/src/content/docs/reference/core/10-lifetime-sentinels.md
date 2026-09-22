---
title: 생명주기와 센티널
description: None/Detach/KeyGone/Void 센티널, q.dispose, 매퍼 루트, 그리고 quad-base가 백엔드의 hold op 위에 조립하는 생명주기 프리미티브 넷
---
값이 아니라 **뜻**을 나르는 상수들(센티널), 관리 중인 값을 파괴하는 유일한 경로 `q.dispose`, 그리고 quad-base가 구현하고 인스턴스 쪽 부기만 백엔드의 hold op 넷에 맡기는 생명주기 프리미티브 넷을 모읍니다.

센티널은 전부 `table.freeze`된 테이블 하나이고 **판정은 언제나 신원 비교**(`v == q.None`)입니다. 타입에 붙어 있는 마커 필드(`__quadNone` 등)는 유니언 타입을 표현하기 위한 조언층일 뿐, 그걸로 판정하지 않습니다.

이 페이지의 심볼: [q.None](#qnone) · [q.Detach](#qdetach) · [q.KeyGone](#qkeygone) · [q.Void](#qvoid) · [q.dispose(value)](#qdisposevalue) · [q.MapperRoot](#qmapperroot) · [q.newMapperClass(className)](#qnewmapperclassclassname) · [q.Backend.bindLifetime(inst, value)](#qbackendbindlifetimeinst-value) · [q.Backend.unbindLifetime(value)](#qbackendunbindlifetimevalue) · [q.Backend.canBound(value)](#qbackendcanboundvalue) · [q.Backend.canExecute(value)](#qbackendcanexecutevalue)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

## `q.None`

**시그니처**

```luau
None: None
-- export type None = { read __quadNone: true }
```

**동작** — "명시적으로 없음"을 뜻하는 값입니다. `nil`과 달리 **실재하는 값**이라, 숫자 키 자리에 들어가도 구멍(nil-hole)을 만들지 않고 순서가 있는 자리를 그대로 채웁니다. 그래서 조건부 자식·조건부 Modifier를 쓸 때 `props.Modifier or q.None` 관용구가 성립합니다.

디스패치에서의 뜻은 "여기서 아래로는 아무것도 하지 마라"입니다. `None`은 숫자 키든 문자 키든 어느 자리에서나 매치되며, 그 자리의 다음 우선순위 핸들러에게 `nil`을 내려보냅니다. 문자 키에 놓으면 그 키를 담당하는 핸들러가 `nil`을 값으로 받습니다 — 그 `nil`을 어떻게 해석할지는 그 핸들러가 정합니다.

- `tostring(q.None)`은 `"None"`입니다(진단용).
- frozen이라 필드를 덧붙일 수 없습니다.
- 같은 quad-base 사본 안에서는 모든 모듈 인스턴스가 같은 객체를 공유합니다.
- 판정용 술어(`isNone`)는 없습니다 — `v == q.None`으로 비교합니다.

**예제**

```luau
local function Card(props)
	return D.Frame {
		props.Modifier or q.None, -- 숫자 키 자리: nil을 넣으면 뒤 항목이 사라진다
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

**동작** — `Slot:List`/`Slot:Single`의 `updateFn`이 **결과 자리에 반환**하는 센티널입니다. "이 요소를 파괴하지 말고 붙잡아 둬라" — 요소는 물리 트리에서 빠지지만 파괴되지 않고 Slot이 계속 들고 있다가, 같은 키가 다시 나타나면 `ctx.Prev`로 되돌아옵니다(`OwnsElements = false`인 Slot에서는 보관하지 않고 소유만 풉니다 — [Slot](/reference/core/06-slot/#qdetach) 참고). 반환하지 않고 값 자리에 두는 용도가 아닙니다.

같은 자리에서 `nil` 또는 `q.None`을 반환하면 파괴, 요소를 반환하면 그 요소가 그 자리에 놓입니다.

보관·복귀 규칙과 실제 `updateFn` 예제는 [Slot](/reference/core/06-slot/)이 자세합니다.

## `q.KeyGone`

**시그니처**

```luau
KeyGone: KeyGone
-- export type KeyGone = { read __quadKeyGone: true }
```

**동작** — `updateFn`이 받는 **`ctx.Item`으로 들어오는** 센티널입니다(그 호출의 `ctx.Index`는 `0`). 지난 사이클에 있던 키가 이번 데이터에서 사라졌을 때, 그 키를 어떻게 처리할지 묻기 위해 한 번 더 호출하면서 실제 항목 대신 이 값을 줍니다.

이 호출에서 돌려줄 수 있는 것은 `nil`/`q.None`(파괴)과 `q.Detach`(홀드) 둘뿐입니다. 요소를 돌려주면 에러입니다 —

```
Quad0147 Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)
```

재조정 사이클 안에서 언제 이 호출이 오는지는 [Slot](/reference/core/06-slot/)을 보세요.

## `q.Void`

**시그니처**

```luau
Void: (...any) -> ()
```

**동작** — quad가 내보내는 단 하나의 no-op 함수입니다. 어떤 인자를 줘도 아무 일도 하지 않고 **아무것도 반환하지 않습니다**(`select("#", q.Void(1, 2, 3))`은 `0`).

새 클로저를 만들지 않기 위한 공용 값입니다. 디스패치 핸들러가 "무를 것이 없다"는 뜻으로 retractor 자리에 돌려주는 값이 바로 이것이고([`../extend/02-dispatch-handler-contract.md`](/reference/extend/02-dispatch-handler-contract/)), retractor를 아예 생략하는 것은 계약 위반입니다. 모든 모듈 인스턴스가 같은 함수 객체를 공유합니다.

## `q.dispose(value)`

**시그니처**

```luau
dispose: (value: any) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `value` | `any` | 파괴할 값 — Slot이거나, 백엔드가 요소로 인정하는 값(`q.Backend.isInst`가 참) |

**반환** — 없음.

**동작** — quad가 관리하는 값을 파괴하는 **유일한 안전 경로**입니다. Slot이면 그 Slot 트리를 통째로 파괴하고, 백엔드 요소면 주입된 파괴 op를 부릅니다.

누가 들고 있는 값은 파괴하지 않습니다. 어떤 Slot의 원소이거나 마운트된 자리(정적 자식·숏핸드가 만든 관리 자식 포함)를 차지하고 있으면 먼저 그 자리에서 빼야 합니다 — Slot이면 `Extract`/데이터 키 삭제, 숫자 키 자리면 그 자리를 쥔 State를 `:Set(nil)`, 숏핸드 관리 자식이면 그 키를 `nil`로(자식이 같이 갑니다). 검사하는 것은 그것뿐입니다 — "quad가 만든 값인가"는 보지 않으므로, 어느 자리에도 놓이지 않은 `Instance.new`/`:Clone()` 결과도 지웁니다. 다른 quad 인스턴스의 자리에 앉은 Instance는 이쪽 부기에 없어 거부되지 않습니다(인스턴스 간 값 섞기는 정의되지 않은 동작).

에러 문구는 넷입니다.

```
Quad0178 dispose: value must not be nil
Quad0179 dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key) (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
Quad0180 dispose: this backend cannot dispose this value
```

마지막 문구는 "Slot도 아니고 이 백엔드의 요소도 아니다"라는 뜻입니다. 백엔드가 설치되지 않은 모듈에서는 그 전에 `q.Backend.isInst` 스텁이 먼저 던집니다(아래 참고).

**예제**

```luau
local slot = q.Slot()
local child = D.Frame {}
slot:Add(child)

slot:Extract(1) -- 파괴하지 않고 자리에서 뺀다(Remove는 파괴한다)
q.dispose(child) -- 그 다음에 파괴
```

Slot 쪽 맥락(마운트 규칙, 죽은 Slot)은 [Slot](/reference/core/06-slot/)에 함께 있습니다.

## `q.MapperRoot`

**시그니처**

```luau
MapperRoot: MapperRoot
-- export type MapperRoot = { read __quadMapperRoot: true }
```

**동작** — `Claim`의 매퍼 디스크립터에서 "이 노드가 루트다"를 뜻하는 키 센티널. quad-roblox에서는 `D.Mapper.Root`로 다시 노출됩니다. 자세한 사용법은 [`../roblox/04-claim-mapper.md`](/reference/roblox/04-claim-mapper/).

## `q.newMapperClass(className)`

**시그니처**

```luau
newMapperClass: (className: string) -> (key: any) -> (props: any) -> MapperDescriptor
```

**동작** — 클래스 이름 하나를 받아 매퍼 디스크립터 팩토리를 만드는 제네릭 생성자. 백엔드의 `D.Mapper.<Class>` 별칭이 전부 여기서 나옵니다. 결과 디스크립터는 `q.isMapperDescriptor`가 참이고, `q.Claim(inst, desc)`에 넘깁니다 — [`../roblox/04-claim-mapper.md`](/reference/roblox/04-claim-mapper/).

## `q.Backend.bindLifetime(inst, value)`

**시그니처**

```luau
bindLifetime: (inst: any, value: any) -> ()
```

**동작** — 값 하나의 수명을 요소(`inst`)의 수명에 묶습니다. 요소가 죽으면 묶인 값들도 같이 수거되고, 구독은 그때부터 발화하지 않습니다.

**이 네 함수는 quad-base 것입니다.** 값 쪽 지식(nil 게이트, 거부 메시지, `Observer`/`Effect`의 훅, 전역 구독 상태)은 여기 있고, 인스턴스 쪽 부기만 백엔드가 심는 hold op 넷(`holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`)에 맡깁니다. quad-base는 임의의 엔진에서 그 부기의 "옳은" 기본값을 추측할 수 없으므로, 그 넷의 자리엔 조용한 no-op 대신 **크게 우는 스텁**을 둡니다. 프로바이더를 설치하지 않은 `Quad.New()`에서 `bindLifetime`을 부르면 그 스텁에 닿습니다:

```
quad: isHeld is not available — no backend has installed the lifetime primitives / engine ops (install a provider with quad:UseProvider — a bare Quad.New() has none; tests use mock.installLifetime)
```

같은 문구가 이름만 바뀌어 hold op `holdLifetime`·`releaseLifetime`·`isHeldBy`, 엔진 op `onDestroying`·`isInst`·`nativeClaim`·`isClaimed`·`nativeFindChild`·`nativeInsert`·`nativeExtract`·`nativeRemove`·`nativeMove`·`nativeSwap`·`nativeDispose`, 시간 op `setTimeout`·`clearTimeout`에도 걸립니다. 각 슬롯이 무엇을 약속해야 하는지는 [`../extend/01-backend-provider-contract.md`](/reference/extend/01-backend-provider-contract/)가 정본입니다.

## `q.Backend.unbindLifetime(value)`

**시그니처**

```luau
unbindLifetime: (value: any) -> ()
```

**동작** — 묶인 값 하나를 미리 풉니다. 묶여 있지 않은 값이면 no-op이고, `nil`은 에러입니다. `Effect`면 `Destroying` 연결을 끊고 나서 백엔드의 `releaseLifetime`에 맡깁니다 — cleanup은 부르지 않습니다. 백엔드가 없으면 `releaseLifetime` 스텁 에러가 납니다.

## `q.Backend.canBound(value)`

**시그니처**

```luau
canBound: (value: any) -> boolean
```

**동작** — "지금 이 값을 묶어도 되는가" — 어디에도 묶여 있지 않으면 참. quad-base가 구현하고, 인스턴스 쪽 판정만 백엔드의 `isHeld`에 묻습니다 — 백엔드가 없으면 그 스텁 에러가 납니다.

## `q.Backend.canExecute(value)`

**시그니처**

```luau
canExecute: (value: any) -> boolean
```

**동작** — "지금 이 값이 발화해도 되는가" — 전파 게이트가 구독을 통과시킬지 판정할 때 묻습니다. quad-base가 구현하고, 인스턴스 쪽 판정만 백엔드의 `isHeld`에 묻습니다 — 백엔드가 없으면 그 스텁 에러가 납니다.

`canBound(v) == not canExecute(v)`가 계약입니다 — 둘은 quad-base가 가진 하나의 비공개 술어를 서로 반대로 감싼 것이고, 그 술어가 백엔드에 묻는 것은 `isHeld(v)` 하나입니다.

## 관련

- [Slot](/reference/core/06-slot/) — `Detach`/`KeyGone`이 실제로 오가는 `Slot:List`/`Slot:Single`
- [브랜드 술어](/reference/core/11-predicates/) — 센티널에 술어가 없는 이유
- [`../extend/01-backend-provider-contract.md`](/reference/extend/01-backend-provider-contract/) — 주입 슬롯 전체 목록과 계약
- [`../extend/02-dispatch-handler-contract.md`](/reference/extend/02-dispatch-handler-contract/) — `Void`를 retractor로 돌려주는 자리
- [`../../quadnomicon/03-luau-memory-topology.md`](/quadnomicon/03-luau-memory-topology/) — 생명주기 바인딩이 메모리 토폴로지에서 하는 역할
