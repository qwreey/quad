---
title: Quad 모듈
description: require 결과가 곧 기본 인스턴스 — NewModule/Raw/RunInit/AddPlugin/UseProvider와 모듈 표면 필드
---
# Quad 모듈

`require(quad-base)`가 돌려주는 것은 클래스나 팩토리가 아니라 **이미 만들어진 quad 모듈 인스턴스**입니다. 바로 `q.Source(...)`를 부를 수 있고, 백엔드는 그 인스턴스에 `UseProvider`로 설치합니다. 여러 개의 독립 인스턴스가 필요한 드문 경우에만 `q.NewModule()`을 씁니다.

한 인스턴스는 자기만의 디스패치 핸들러 레지스트리, 부기(bookkeeping), 프로바이더 슬롯을 가집니다. `Void`/`Ref`/`Relate`/`Blocker` 같은 의존 없는 잎 모듈은 인스턴스끼리 공유되지만, `Source`/`Effect`처럼 인스턴스 상태를 닫아 쥐는 팩토리는 인스턴스마다 다른 함수입니다.

이 페이지의 심볼: [q.NewModule()](#qnewmodule) · [q.Raw](#qraw) · [q:RunInit(initFn)](#qruninitinitfn) · [q:AddPlugin(pluginFn)](#qaddpluginpluginfn) · [q:UseProvider(providerFn)](#quseproviderproviderfn) · [q.Version](#qversion) · [q.debug](#qdebug) · [q.errorNamespace](#qerrornamespace) · [q.moduleIdentity](#qmoduleidentity) · [q.Relate()](#qrelate)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
local QuadRoblox = require("@game/ReplicatedStorage/roblox_packages/quad_roblox").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: q.Elem 등과 Tween/Animate가 생긴다
```

## `q.NewModule()`

**시그니처**

```luau
NewModule: () -> Quad
```

**반환** — 새 `Quad` 모듈 인스턴스.

**동작** — 완전히 독립적인 모듈 인스턴스를 만듭니다. 서브시스템(디버그 표면, 생명주기 스텁, 반응형 코어, 디스패치, Ref, Claim, Slot, Tag/Attr, 시간 게이트, 생명주기 훅)이 그 자리에서 설치됩니다.

- **[3.4.0]** 3.3까지의 이름은 `q.New()`였습니다. 무엇을 만드는지가 이름에 드러나도록 바꿨고, 옛 이름은 없습니다.
- **프로바이더는 들어 있지 않습니다.** `Quad.NewModule()`로 만든 인스턴스는 백엔드가 없어서 `holdLifetime`·`isInst` 같은 슬롯이 안내 스텁 상태이고, `bindLifetime`을 부르면 그 스텁에 닿습니다 — [생명주기와 센티널](./10-lifetime-sentinels.md) 참고.
- 인스턴스는 참조를 놓으면 수거됩니다. 모듈을 키로 삼는 전역 맵이 인스턴스를 붙잡지 않습니다 — 단 그 인스턴스가 만든 Instance를 `Destroy` 하지 않은 채 참조만 놓으면 그 Instance의 체인이 모듈의 클로저를 붙들어 둘 다 남습니다("quad가 만든 Instance는 `Destroy`로만 회수" 계약의 귀결 — [2026-09-27 mock 실측]; `Destroy`하면 둘 다 수거).
- 잎 모듈은 공유됩니다: `Quad.NewModule().Void == Quad.Void`, `Quad.NewModule().Ref == Quad.Ref`. 반면 `Quad.NewModule().Source ~= Quad.Source`입니다. 능력(프로토콜) 브랜드도 사본 단위라 공유됩니다 — `Quad.NewModule().Protocols.DispatchHint == Quad.Protocols.DispatchHint`([`q.Protocols.DispatchHint`](../extend/02-dispatch-handler-contract.md#qprotocolsdispatchhint), 3.3.0부터).
- **인스턴스끼리 값을 섞지 마세요.** 한 인스턴스가 만든 Observer·Effect·Slot·State를 다른 인스턴스의 트리 자리(숫자 키, 프로퍼티 값, `:List`의 데이터, `Slot`의 원소 자리 — `Add`/생성자/`Replace`/`Extract`/`Splice`, `State`에 담아서도)에 놓거나 `q.dispose`에 넘기면 그 자리에서 `…: this value was made by another quad module instance …`를 던집니다 — 생명주기 기록이 인스턴스마다 따로라, 막지 않으면 에러 없이 그 값이 돌지 않기 때문입니다. 소비자 프로젝트에 `quad_base` **사본이 둘** 생긴 경우는 다릅니다 — 브랜드 집합이 사본마다 따로라 다른 사본의 값은 이쪽의 `isState`류가 전부 거짓이고 이 가드까지 오지 못합니다. 그때 보이는 것은 `Quad0076 … check that the provider … is initialized`(원인과 무관한 안내)·`Quad0240`·`Quad0151`·`Quad0198`류이며, 프로퍼티 자리에선 그 테이블이 날값으로 엔진까지 갑니다([술어 레퍼런스](./11-predicates.md)의 사본 경계). 사본이 둘인지 먼저 의심하세요. **팩토리도 섞지 마세요** — `A.Source(0):Apply(Bare.Debounce{…})`처럼 다른 인스턴스의 `Debounce`/`Throttle`을 쓰면 가드는 지나지만 시간 op를 팩토리를 만든 인스턴스의 `Backend`에서 읽어 `Quad0108 … setTimeout is not available`이 나거나 남의 시계로 돕니다. 공유 잎 모듈의 값(`Ref`·`Blocker` 등)은 주인 인스턴스가 없어 검사하지 않으며, 그것을 두 인스턴스에 걸쳐 쓰는 것은 정의되지 않은 동작입니다. 의존성으로만 잇는 것(`q.Effect(fn, 다른 인스턴스의 Source)`)은 생명주기가 없어 검사하지 않지만, 그쪽도 **정의되지 않은 동작**입니다 — 막지 않을 뿐 보장하지 않습니다.

**예제**

```luau
local isolated = Quad.NewModule() -- 테스트나 격리된 서브시스템용
```

## `q.Raw`

**시그니처**

```luau
Raw: {
	Modifier: ModifierConstructor,
	Spread: (t: { [any]: any }) -> { read __quadSpread: true, Append: (self: any, other: any) -> () },
	Mapper: (className: string) -> (key: any) -> (props: any) -> MapperDescriptor,
}
```

**동작** — 백엔드가 자기 타입드 표면(`q.Modifier "Frame"`, `q.Spread "Frame" {…}`, `q.Mapper "Frame"`)을 짓는 base의 원재료입니다. 셋 다 클래스를 모르고 타입도 붙지 않습니다. 앱 코드는 보통 백엔드가 주는 타입드 쪽을 씁니다 — `q.Raw`는 백엔드·플러그인 작성자, 그리고 자기 Modifier 클래스를 정의하는 사람의 자리입니다.

- **`q.Raw.Modifier`** — base의 Modifier 생성자 묶음(`Overridden`·`TypedFactory`·`DefineSubtype` 포함). 3.4.0 전까지 `q.Modifier`였던 것입니다(그 이름은 이제 백엔드의 타입드 생성자 `q.Modifier "Frame"`입니다 — [Modifier와 Spread](../roblox/03-modifier-spread.md)).
- **`q.Raw.Spread(t)`** — 요소 테이블처럼 쓴 테이블로 Spread를 만듭니다. 안에 놓인 Spread는 그 자리에서 펴지고(깊이 1), 같은 키는 먼저 자리 잡은 쪽이 이깁니다(인라인 키가 첫 층). `spread:Append(other)`는 다른 Spread만 받아 끝에 펴 넣고 아무것도 돌려주지 않습니다. 요소에 놓이거나 다른 Spread에 펴진 Spread는 잠겨 `:Append`가 [`Quad0275`](../errors/02-dispatch-bookkeeping.md#quad0275)이 됩니다.
- **`q.Raw.Mapper(className)`** — Claim 매퍼 디스크립터의 클래스별 팩토리. 3.4.0 전까지 `q.newMapperClass`였던 것입니다.

## `q:RunInit(initFn)`

**시그니처**

```luau
RunInit: (self: Quad, initFn: (Quad) -> any) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `initFn` | `(Quad) -> any` | 이 모듈 인스턴스를 받아 뮤테이션으로 무언가를 설치하는 함수 |

**반환** — 없음. 확장 테이블을 병합하지 않습니다(그건 `AddPlugin`의 일입니다).

**동작** — 서브시스템 설치 함수를 이 인스턴스에서 **한 번만** 실행합니다. `(모듈, initFn)` 쌍을 키로 기록하므로 같은 함수를 다시 넘기면 no-op이고, 다른 인스턴스에서는 다시 실행됩니다. 표시는 실행 **전에** 찍습니다 — 서로를 당겨오는 Init들이 순환해도 무한 재귀에 빠지지 않습니다. 그 대가로, `initFn`이 도중에 던지면 그 쌍은 이미 표시돼 있어 **같은 함수로 다시 불러도 no-op**입니다(반쯤 설치된 서브시스템이 남음) — `AddPlugin`은 성공 뒤에 표시하므로 반대입니다. 던진 Init은 그 모듈 인스턴스를 버리고 새로 만드세요.

그래서 서브시스템 모듈은 자기 의존성을 `module:RunInit(InitOther)`로 직접 당겨오면 되고, 설치 순서를 신경 쓸 필요가 없습니다.

**예제**

```luau
local runs = 0
local function InitCounter(_module)
	runs += 1
end

local m = Quad.NewModule()
m:RunInit(InitCounter)
m:RunInit(InitCounter) -- no-op
print(runs) --> 1
```

## `q:AddPlugin(pluginFn)`

**시그니처**

```luau
AddPlugin: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `pluginFn` | `(Self) -> P` | 모듈을 받아 **확장 테이블**을 돌려주는 함수 |

**반환** — 같은 모듈(identity 그대로). 타입은 원래 표면과 확장의 교집합 `Self & P`라 체이닝이 그대로 이어집니다.

같은 `pluginFn`은 한 번만 병합됩니다(dedup) — 그 기록은 모듈을 약한 키로 하는 테이블에 함수 객체를 내부 키로 들어가므로, `pluginFn`이 그 모듈(`q`) 자체를 캡처한 인라인 클로저면 모듈이 수거되지 않습니다. 모듈은 보통 프로세스 수명이라 문제가 되지 않지만, 모듈을 만들고 버리는 코드(테스트 하네스)에서는 플러그인을 인자로 받는 `quad`만 쓰는 최상위 함수로 두세요(`RunInit`의 `initFn`과 같은 규칙).

**동작** — `pluginFn(self)`가 돌려준 테이블의 필드를 모듈에 얕게 병합합니다. 새 인스턴스를 만들지 않고 받은 모듈을 그 자리에서 뮤테이션합니다 — `RunInit` 기록이 identity에 의존하기 때문입니다. 슬롯 락이 없으므로 같은 필드를 나중 플러그인이 덮어씁니다. **같은 `pluginFn`을 다시 넘기면 아무것도 하지 않습니다** — `RunInit`과 같은 identity 기준이라 여러 스크립트가 각자 설치해도 한 번만 돕니다. 설치 표시는 `pluginFn`이 끝까지 돈 뒤에 하므로, 도중에 던진 플러그인은 다시 부르면 처음부터 돕니다. 플러그인이 안에서 다른 플러그인을 설치하는 한 방향 의존은 괜찮지만, **서로를 설치하는 순환**(A가 B를, B가 A를)은 정의되지 않은 동작입니다. 백엔드 설치에는 이걸 쓰지 말고 `UseProvider`를 쓰세요.

**이미 있는 필드를 덮을 때** — 막지 않습니다. 코어 부품을 일부러 갈아 끼우는 플러그인도 쓸 수 있어야 하기 때문입니다. 다만 `q.Source` 같은 코어 필드가 남의 것으로 바뀌면 원인을 찾기 어려우므로, [`q.debug`](#qdebug)가 켜져 있으면 설치 시점에 한 줄을 출력합니다. 검사 대상은 `pluginFn`이 **돌려준 테이블**이 덮는 필드뿐이고, `pluginFn` 안에서 모듈에 직접 대입한 필드는 알리지 않습니다. 검사는 `AddPlugin`을 부를 때 한 번만 돌고, `q.debug`는 그보다 **먼저** 켜 두어야 합니다.

- `AddPlugin: plugin overwrites existing module field "{k}" - intended if the plugin extends a core part on purpose; otherwise rename the plugin's field`(이건 `error`가 아니라 `q.debug`일 때만 찍는 안내 `print`라 QuadNNNN이 없습니다)
- `Quad0210 AddPlugin: plugin must be a function (got {typeof(pluginFn)})`
- `Quad0211 AddPlugin: the function must return its extension table (got {typeof(extension)} - return an empty table if it adds nothing)` — 모듈을 고쳐 쓰기만 하고 아무것도 돌려주지 않는 플러그인이 흔한 실수입니다.

**`_`로 시작하는 필드는 공개 표면이 아닙니다.** 모듈에 런타임으로 존재하더라도(`_slotInternal` 등) 내부 계약이며 예고 없이 바뀝니다 — 읽거나 덮어쓰는 코드에 기대지 마세요.

**예제**

```luau
local function doublePlugin(_self)
	return {
		Double = function(_selfArg, v: number)
			return v * 2
		end,
	}
end

local m = Quad.NewModule():AddPlugin(doublePlugin)
print(m:Double(21)) --> 42
```

## `q:UseProvider(providerFn)`

**시그니처**

```luau
UseProvider: <Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `providerFn` | `(Self) -> P` | 백엔드 프로바이더 함수 — 모듈의 주입 슬롯을 채우고 백엔드 고유 표면을 돌려줍니다 |

**반환** — 같은 모듈. 타입은 `Self & P`이므로 여기서부터 `q.Elem`/`q.Tween` 같은 백엔드 표면이 타입에 실립니다.

**동작** — 병합 자체는 `AddPlugin`과 같지만 계약이 다릅니다: **모듈당 프로바이더는 하나**이고, 잠금은 프로바이더 함수의 identity로 겁니다.

- 같은 함수로 다시 부르면 멱등 no-op입니다. 같은 모듈을 `require`하면 캐시가 같은 함수를 주므로 일반적인 재호출은 그대로 통과합니다.
- 다른 identity면 던집니다 — 다른 백엔드든, 같은 백엔드의 **다른 사본/버전**이든 마찬가지입니다.

  ```
  Quad0213 UseProvider: this Quad module already has a provider - a module cannot serve two backends
  ```

- 프로바이더 함수는 모듈을 약한 키로 하는 테이블에 값으로 남습니다 — `AddPlugin`과 같은 이유로, `providerFn`이 그 모듈(`q`) 자체를 캡처한 인라인 클로저면 모듈이 수거되지 않습니다(Luau에는 키가 죽으면 값도 놓는 ephemeron 테이블이 없어 순환이 끊기지 않습니다 — [2026-09-27 mock 실측]은 `AddPlugin` 쪽이고, 프로바이더는 같은 저장 모양입니다). 모듈을 만들고 버리는 코드(테스트 하네스)에서는 인자로 받는 모듈만 쓰는 최상위 함수로 두세요.
- 슬롯 표시는 **성공한 뒤에** 찍습니다. `providerFn`이 도중에 던지면 슬롯은 비어 있는 채로 남아 다시 시도할 수 있습니다(표시를 먼저 찍었다면 재시도가 멱등 no-op에 삼켜져 확장이 영영 병합되지 않는 좀비가 됩니다).
- 인자 모양은 먼저 검사합니다 — `Quad0212 UseProvider: provider must be a function (got {typeof(providerFn)})`(`UseProvider(nil)`은 전에 조용히 통과했습니다), 프로바이더가 확장 테이블을 돌려주지 않으면 `Quad0209 UseProvider: the function must return its extension table (got {typeof(extension)} - return an empty table if it adds nothing)`.

quad-roblox는 설치 시점에 quad-base 버전을 확인하고, 맞지 않으면 호출한 줄을 blame하며 던집니다 —

```
quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')
```

`{VERSION_PATTERN}` 자리에는 그 quad-roblox가 요구하는 패턴이 들어갑니다(이 저장소의 현재 값은 `3.4^.0^` — 같은 메이저 안에서 3.4.0 이상).

**예제**

```luau
local q = Quad:UseProvider(QuadRoblox)
local q2 = q:UseProvider(QuadRoblox) -- 같은 함수 — 멱등 no-op
print(q2 == q) --> true
```

## `q.Version`

**시그니처**

```luau
Version: "3.4.0"
```

**동작** — 이 quad-base 사본의 버전 문자열. 타입이 싱글톤 문자열이라 타입 층에서도 값이 그대로 보입니다. 백엔드는 `UseProvider` 시점에 이 값을 자기 패턴과 대조하는 데 씁니다(위 참고).

중간 빌드는 `3.1.0-rc.1`이나 `3.0.1-dev.3+build.7`처럼 SemVer 프리릴리즈·빌드 꼬리를 달 수 있습니다. 대조할 때 `+` 뒤 빌드 메타데이터는 양쪽 다 무시하고, 프리릴리즈 꼬리는 **있고 없음이 양쪽에서 같아야** 합니다 — 꼬리 없는 패턴은 rc 빌드를 받지 않고, 꼬리 있는 패턴은 릴리즈를 받지 않습니다. 둘 다 받으려면 `|`로 대안을 나열합니다(`"3.4.0|3.4.0-rc.1^"`). 패턴 문법 전체는 [백엔드 프로바이더 규약](../extend/01-backend-provider-contract.md)에 있습니다.

## `q.debug`

**시그니처**

```luau
debug: boolean
```

**동작** — 기본값 `false`. 개발 중에 켜 두는 진단 플래그입니다. 읽는 자리는 두 묶음입니다.

**진단 줄** — 치명적이지 않은 실수를 한 줄씩 출력한 뒤 **실행을 그대로 계속합니다**(켜도 동작은 바뀌지 않습니다).

- `q.Dispatch.addHandler`가 등록 시점에 같은 우선순위의 핸들러를 발견할 때([`../extend/02-dispatch-handler-contract.md`](../extend/02-dispatch-handler-contract.md)).
- [`q:AddPlugin`](#qaddpluginpluginfn)이 기존 필드를 덮을 때.
- 옵션 테이블에 모르는 키(오타·옛 이름)가 있을 때 — `q.Debounce`/`q.Throttle`, `slot:List`/`slot:Single`의 `opts`, `q.Tween`, `q.Animate`. 모르는 키는 꺼져 있을 때와 똑같이 무시됩니다. `q.Tween`/`q.Animate`는 `Info`와 편의 필드(`Time`·`Style`·`Direction`·`RepeatCount`·`Reverses`·`DelayTime`)를 함께 줬을 때도 알립니다 — `Info`가 이기므로 그 필드들은 무시됩니다(`q.Animate`의 `Info`가 `State`면 "그 `State`가 값을 가진 동안 무시"로 알립니다 — `nil`을 쥐는 동안은 편의 필드가 쓰입니다; **[3.3.0부터]**).
- [`q.Claim`](../roblox/04-claim-mapper.md)의 디스크립터가 이상할 때 — 자식 디스크립터의 키가 문자열이 아니거나, 루트 디스크립터에 키를 적어 무시될 때.

위 넷은 그 호출 시점에 한 번 보므로 `q.debug`는 먼저 켜 두세요. 아래 일곱은 값이 처리되거나 쓰일 때마다 보므로 켜는 시점은 상관없습니다(켠 뒤의 실행부터 봅니다).

- 배열 원소로만 쓰이는 quad 값(`Ref`/`PreRef`/`PostRef`·`Observer`·`Effect`·`Slot`·`Tag`·`Attr`)이 props의 **문자 키**에 놓였을 때(어느 문자 키든 — 특히 반영 프로퍼티·이벤트 이름이면 거절되지 않고 프로퍼티·이벤트 핸들러가 그 값을 받아 가던 자리입니다). 같은 요소·키는 한 번만 알립니다. quad가 등록한 [`debugOnly`](../extend/02-dispatch-handler-contract.md#handler-레코드) 진단 필터가 찍습니다.
- `:Compute` 계산 함수가 도는 도중(그 함수가 부른 것 안 포함) `Source:Set`/`:Emit`이 불렸을 때(`:SetIfChanged`는 실제로 쓸 때) — `Source: Set/Emit inside a Compute fn - …`. 같은 `Source`는 한 번만 알립니다(계약은 [`state:Compute`](./03-state.md#statecomputefn-deps) — 계산 함수는 읽어서 조합할 뿐 아무것도 `:Set`하지 않습니다).
- 같은 노드의 앞선 계산이 다른 코루틴에서 멈춘 채(계산 함수 안 yield) 새 계산이 시작될 때 — `State: Compute fn entered while an earlier run of this node has not returned - …`. 던져서 끝난 계산은 지금 구현상 새 세대에 다시 도는 경로(관측 — 계약 아님)라 알리지 않습니다.
- `state:Observer(fn)`의 콜백이 도는 도중 같은 핸들에 변경이 다시 도착했을 때 — 콜백이 자기 상류를 되먹였다는 뜻입니다: `Observer: a change reached this Observer while its own fn was running - …`. 첫 발화(설치) 도중에 와서 보류되는 변경도 알립니다. props 자리에 놓인 `State`도 대상입니다 — 그 값을 처리하는 동안 불린 콜백(`Ref`·`Tween` 콜백, 이벤트 연결 등)이 그 `State`를 되쓰면 알립니다 — 단 정의된 경로 둘은 알리지 않습니다: `q.Out`·`OnChange` 엔진 왕복(엔진이 바뀐 프로퍼티를 그 콜백으로 다시 올려 보내는 것 — 신호가 즉시 배달되면 처리 도중 동기로 돌아와도)과 `Tween`의 `Completed`에서 다음 트윈을 잇는 것(스냅이면 동기로 불려도; `Started`·`Cancelled`에서의 되쓰기는 알립니다). 이 둘이 빼 주는 것은 그 `State`의 처리뿐이라, 바깥의 사용자 `Observer`가 그 `State`를 `:Set`해 시작된 연쇄가 그 `Observer`의 상류를 되쓰면 알립니다. 핸들마다 한 번만 알립니다. 규칙과 정의된 예외는 [`state:Observer`](./05-observer-effect.md#stateobserverfn)의 "Observer는 최종 소비자" 문단 — Slot 자리 계산을 거친 고리(마운트·다시 앉히기 포함)와 quad가 자리 계산·목록에 내부로 쓰는 Observer는 알리지 않습니다.
- [`q.Debounce`/`q.Throttle`](../sugar/03-debounce-throttle.md#handlecancel) 게이트가 값을 내보내는 도중(창 끝·`MaxTime`·`handle:Flush()`·leading 통과) 그 통지를 받은 하류 콜백 안에서 같은 게이트의 `handle:Cancel()`이나 `handle:Flush()`가 불렸을 때(정의되지 않은 동작) — `Debounce: handle:Cancel() was called from a callback this gate's own flush reached …`(`Flush`면 `handle:Flush()`). 부를 때마다 알립니다(호출 스택을 걸어 봅니다).
- quad가 claim하지 않은 인스턴스 — 파괴됐거나(`q.dispose`든 quad 밖이든) quad가 만들지 않은 것 — 에 디스패치가 돌 때(정의되지 않은 동작 — 핸들러가 그 시체 위에서 돌 수 있습니다, 예: 짝이 오지 않는 `Tween`의 `Started`) — `Dispatch: process on an instance that is not claimed by quad … at key {k} …`. `q.Elem "Class" { … }`·`q.Dispatch.drive`·`q.Dispatch.process` 모두 이 한 자리를 지나며, 키마다 알립니다.
- 마운트 대상 인스턴스가 더는 claim돼 있지 않은 `Slot`(호스트를 `q.dispose`했거나 quad 밖에서 파괴)에 CRUD를 부를 때(정의되지 않은 동작 — [06-slot](./06-slot.md#죽은-slot과-마운트-규칙)의 "마운트 대상이 파괴된 Slot") — `Slot: CRUD on a Slot whose host Instance is no longer claimed by quad …`. 부를 때마다 알립니다.

이 일곱도 켜도 동작은 바뀌지 않습니다(정의되지 않은 동작을 정의된 동작으로 바꾸지 않습니다 — 보여 줄 뿐입니다). 진단 줄은 `print`이고 `QuadNNNN` 번호가 없습니다(에러가 아니라서 — 번호는 에러에만 붙습니다). **[2026-10-01 기준]** 3.2.0에는 첫 항목(우선순위 동률)만 있고 나머지는 3.3.0부터입니다([변경 이력](../../../CHANGELOG.md) `[3.3.0]`).

**비용이 드는 검사** — 평소 경로에 두기엔 자주 도는 자리라 꺼 두면 검사하지 않고, 켜면 그 자리에서 **에러로 멈춥니다**(꺼진 채로는 정지하거나 나중에 엉뚱한 자리에서 죽는 실수들입니다). **[2026-10-06 기준]** 전부 3.3.0부터입니다 — `Quad0083`·`Quad0173`·`Quad0171`은 3.2.0까지 늘 돌던 검사를 이 층으로 내린 것이고, `Quad0220`과 `Quad0143`의 "배열에 키가 덧붙은 데이터" 갈래는 새로 넣은 검사입니다(꺼 두면 3.2.0과 같습니다).

- 디스패치 핸들러의 `process`가 함수가 아닌 retractor(`true`·숫자·테이블)를 돌려줄 때 — `Quad0077`([핸들러 계약](../extend/02-dispatch-handler-contract.md#handler-레코드); 꺼져 있어도 `nil`은 늘 검사합니다).
- `State`의 값 사슬이 자기에게 돌아올 때(`a:Set(b); b:Set(a)`, `s:Set(s)`) — `Quad0070`(props 자리에 놓인 `State`를 벗길 때와 Slot에 넣은 `State` 원소; 사슬을 끝까지 따라가는 검사; 꺼져 있으면 스택 오버플로로 끝나는 정의되지 않은 동작).
- 중괄호를 잊은 `q.Elem "Frame" (value)`에서 그 값이 메타테이블 없는 **프로바이더 브랜드** 값일 때 — `Quad0083`(모듈에 등록된 브랜드 술어를 전부 훑는 검사; 메타테이블이 있는 값과 quad-base 값은 꺼져 있어도 늘 잡습니다 — [핸들러 계약](../extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened)).
- `slot:List`의 `data` 배열에 배열이 아닌 키가 **덧붙어** 있을 때 — `Quad0143`(재조정마다 키 전수 검사; 배열 부분이 비어 있는 딕셔너리는 꺼져 있어도 늘 잡습니다 — [06-slot](./06-slot.md#slotlistdata-updatefn-keyfn-opts)).
- `slot:List`의 `data` 배열이나 `q.Slot({ … })`의 `initial` 배열 **중간에 `nil` 구멍**이 있을 때 — `Quad0269`(`:List`)·`Quad0270`(`initial`). 위 `Quad0143` 검사가 이미 도는 키 훑기에 얹은 검사입니다(키 개수와 가장 큰 키가 다르면 구멍). 꺼져 있으면 정의되지 않은 동작 그대로입니다 — 목록이 구멍에서 끝나고, `:List`는 구멍 뒤 항목의 원소를 파괴합니다([06-slot](./06-slot.md#slotlistdata-updatefn-keyfn-opts)).
- `Slot`을 자기 자신이나 조상 Slot에 원소로 넣을 때 — `Quad0173`(원소 관계를 따라 올라가는 검사; 꺼져 있으면 넣는 줄은 통과하고 그 순환은 정의되지 않은 동작입니다 — 관측(계약 아님): 그 순환 트리의 다음 CRUD나 해체가 스택 오버플로나 내부 불변식 에러로 죽고(어느 쪽인지는 연산마다 다릅니다), 그 뒤의 부기 무결은 약속하지 않습니다).
- `Slot` CRUD 한 호출(생성자 `initial`·`Splice`) 안에 같은 값이 두 번 있을 때 — `Quad0171`(원소를 넣기 전에 받은 값 그대로 비교 — `State`의 값은 읽지 않습니다; 꺼져 있으면 둘째 값이 자리에 들어가는 순간 `Quad0170`이 나고 앞 원소는 이미 들어가 있습니다).
- (quad-roblox) Instance를 자기 자신이나 자기 자손의 숫자 키 자리에 자식으로 놓을 때 — `Quad0220`(조상 사슬 걷기; 꺼져 있으면 엔진의 circular reference 에러가 대신 멈추되, quad가 자리를 잡은 뒤라 그 요소의 부기는 믿을 수 없습니다).

이 검사들은 매번 그 자리에서 보므로 켜는 시점은 상관없습니다(켠 뒤의 실행부터 검사합니다).

```luau
q.debug = true -- 위 진단 줄과 비용이 드는 검사를 켠다
```

## `q.errorNamespace`

**시그니처**

```luau
errorNamespace: ErrorNamespace
-- Namespace = {
--   setFuncLevel: (level: number, ...any) -> (),
--   getFuncLevel: (func: any) -> number,
--   getFirstMatch: (level: number) -> number,
--   getNearestMatch: (level: number) -> number,
--   errorAt: (content: any, level: number) -> never,
--   errorBefore: (content: any, level: number) -> never,
--   errorAtNearest: (content: any, level: number) -> never,
--   errorBeforeNearest: (content: any, level: number) -> never,
-- }
```

**동작** — quad-base 전체가 공유하는 **하나의** 에러 네임스페이스입니다. 공개 표면 함수들이 여기에 자기를 등록해 두고, 에러를 던질 때 그 등록을 이용해 스택에서 "quad 기계"와 "사용자 코드"의 경계를 찾아 사용자의 줄을 blame합니다.

백엔드와 플러그인은 자기 quad-error 사본으로 새 네임스페이스를 만들지 말고 **이 값을 받아** 자기 표면을 태깅해야 합니다 — 사본마다 태그 맵이 갈리면 경계 탐색이 끊깁니다. 같은 사본 안의 모든 모듈 인스턴스가 같은 네임스페이스를 공유합니다.

**에러 메시지는 사람이 읽는 진단이지 API가 아닙니다.** 문구는 예고 없이 다듬어질 수 있으니 코드가 문구로 분기하지 마세요(`string.find(err, "...")` 금지) — 실패를 코드에서 가르려면 호출 전에 조건을 확인하세요. 레퍼런스가 문구를 그대로 싣는 것은 검색해서 원인을 찾으라는 뜻입니다.

자세한 사용법은 [`../extend/01-backend-provider-contract.md`](../extend/01-backend-provider-contract.md).

## `q.moduleIdentity`

**시그니처**

```luau
read moduleIdentity: {}
```

**동작** — 이 모듈 인스턴스의 identity 토큰입니다. 내용이 없는 빈 테이블이고 모듈을 붙잡지 않으며, 계약은 "인스턴스마다 하나, 서로 다름"뿐입니다.

- quad-base는 Observer·Effect·Slot·State가 자기 인스턴스의 것인지 이 토큰으로 판정합니다(위 `q.NewModule()`의 "인스턴스끼리 값을 섞지 마세요").
- **백엔드·플러그인이 자기 값에 같은 검사를 하고 싶다면** 이 토큰을 값이 사는 곳에 붙여 두고 비교하세요. 어디에 둘지는 구현자 몫입니다 — 평범한 테이블이면 필드(메타테이블 쪽에 두면 값마다 칸이 들지 않음), userdata처럼 필드를 못 붙이는 값이면 [`q.Relate()`](#qrelate) 같은 약한 관계로.

**예제**

```luau
local Impl = {}
Impl.__index = Impl
Impl._moduleIdentity = q.moduleIdentity -- 값마다가 아니라 메타테이블에 한 번

local function assertOwn(value)
	if value._moduleIdentity ~= q.moduleIdentity then
		error("MyPlugin: value belongs to another quad instance", 2)
	end
end
```

---

## `q.Relate()`

**시그니처**

```luau
Relate: () -> Relate
-- Relate = {
--   SetStrong: (self: Relate, inst: any, key: any, value: any) -> (),
--   GetStrong: (self: Relate, inst: any, key: any) -> any?,
--   SetWeak:   (self: Relate, inst: any, key: any, value: any) -> (),
--   GetWeak:   (self: Relate, inst: any, key: any) -> any?,
-- }
```

**동작** — `(inst, key) -> value` 릴레이션을 만듭니다. **`inst`는 언제나 weak 키**이고(요소가 죽으면 그 요소의 항목 전체가 같이 사라집니다), `Strong`/`Weak`는 **값**을 어떻게 보관할지만 가리킵니다. quad 내부가 인스턴스별 부속 상태를 매다는 데 쓰는 프리미티브이고, 같은 필요가 있는 확장에서도 쓸 수 있습니다.

`inst`나 `key`가 `nil`이면 던집니다 — `Relate:SetStrong: inst must not be nil`처럼 메소드 이름과 어느 인자인지를 밝힙니다.

**예제**

```luau
local rel = q.Relate()
local host = q.Elem "Frame" {}

rel:SetStrong(host, "meta", { label = "hello" })
print(rel:GetStrong(host, "meta").label) --> hello
```

`q.Void`(공용 no-op 함수)도 같은 잎 계열로 모듈 표면에 실려 있습니다 — [생명주기와 센티널](./10-lifetime-sentinels.md#qvoid).

## 관련

- [`../../getting-started/00-installation.md`](../../getting-started/00-installation.md) — 두 패키지를 require하고 백엔드를 설치하기까지
- [생명주기와 센티널](./10-lifetime-sentinels.md) — 백엔드가 없는 모듈에서 나는 스텁 에러
- [`../extend/01-backend-provider-contract.md`](../extend/01-backend-provider-contract.md) — 프로바이더가 채워야 하는 슬롯 전체
- [`../roblox/01-install.md`](../roblox/01-install.md) — `QuadRoblox`가 싣는 표면
