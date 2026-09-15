---
title: Quad 모듈
description: require 결과가 곧 기본 인스턴스 — New/RunInit/AddPlugin/UseProvider와 모듈 표면 필드
---
`require(quad-base)`가 돌려주는 것은 클래스나 팩토리가 아니라 **이미 만들어진 quad 모듈 인스턴스**입니다. 바로 `q.Source(...)`를 부를 수 있고, 백엔드는 그 인스턴스에 `UseProvider`로 설치합니다. 여러 개의 독립 인스턴스가 필요한 드문 경우에만 `q.New()`를 씁니다.

한 인스턴스는 자기만의 디스패치 핸들러 레지스트리, 부기(bookkeeping), 프로바이더 슬롯을 가집니다. `Void`/`Ref`/`Relate`/`Blocker` 같은 의존 없는 잎 모듈은 인스턴스끼리 공유되지만, `Source`/`Effect`처럼 인스턴스 상태를 닫아 쥐는 팩토리는 인스턴스마다 다른 함수입니다.

이 페이지의 심볼: [q.New()](#qnew) · [q:RunInit(initFn)](#qruninitinitfn) · [q:AddPlugin(pluginFn)](#qaddpluginpluginfn) · [q:UseProvider(providerFn)](#quseproviderproviderfn) · [q.Version](#qversion) · [q.debug](#qdebug) · [q.errorNamespace](#qerrornamespace) · [q.moduleIdentity](#qmoduleidentity) · [q.Relate()](#qrelate)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
local QuadRoblox = require("@game/ReplicatedStorage/roblox_packages/quad_roblox").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
```

## `q.New()`

**시그니처**

```luau
New: () -> Quad
```

**반환** — 새 `Quad` 모듈 인스턴스.

**동작** — 완전히 독립적인 모듈 인스턴스를 만듭니다. 서브시스템(디버그 표면, 생명주기 스텁, 반응형 코어, 디스패치, Ref, Claim, Slot, Tag/Attr, 시간 게이트, 생명주기 훅)이 그 자리에서 설치됩니다.

- **프로바이더는 들어 있지 않습니다.** `Quad.New()`로 만든 인스턴스는 백엔드가 없어서 `bindLifetime`·`isInst` 같은 슬롯이 안내 스텁 상태입니다 — [생명주기와 센티널](/reference/core/10-lifetime-sentinels/) 참고.
- 인스턴스는 참조를 놓으면 수거됩니다. 모듈을 키로 삼는 전역 맵이 인스턴스를 붙잡지 않습니다.
- 잎 모듈은 공유됩니다: `Quad.New().Void == Quad.Void`, `Quad.New().Ref == Quad.Ref`. 반면 `Quad.New().Source ~= Quad.Source`입니다.
- **인스턴스끼리 값을 섞지 마세요.** 한 인스턴스가 만든 Observer·Effect·Slot·State를 다른 인스턴스의 트리 자리(숫자 키, 프로퍼티 값, `:List`의 데이터)에 놓으면 그 자리에서 `…: this value was made by another quad module instance …`를 던집니다 — 생명주기 기록이 인스턴스마다 따로라, 막지 않으면 에러 없이 그 값이 돌지 않기 때문입니다. 소비자 프로젝트에 `quad_base` 사본이 둘 생겨도 같은 일이 납니다. 공유 잎 모듈의 값(`Ref`·`Blocker` 등)은 주인 인스턴스가 없어 검사하지 않으며, 그것을 두 인스턴스에 걸쳐 쓰는 것은 정의되지 않은 동작입니다. 의존성으로만 잇는 것(`q.Effect(fn, 다른 인스턴스의 Source)`)은 생명주기가 없어 그대로 됩니다.

**예제**

```luau
local isolated = Quad.New() -- 테스트나 격리된 서브시스템용
```

## `q:RunInit(initFn)`

**시그니처**

```luau
RunInit: (self: Quad, initFn: (Quad) -> any) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `initFn` | `(Quad) -> any` | 이 모듈 인스턴스를 받아 뮤테이션으로 무언가를 설치하는 함수 |

**반환** — 없음. 확장 테이블을 병합하지 않습니다(그건 `AddPlugin`의 일입니다).

**동작** — 서브시스템 설치 함수를 이 인스턴스에서 **한 번만** 실행합니다. `(모듈, initFn)` 쌍을 키로 기록하므로 같은 함수를 다시 넘기면 no-op이고, 다른 인스턴스에서는 다시 실행됩니다. 표시는 실행 **전에** 찍습니다 — 서로를 당겨오는 Init들이 순환해도 무한 재귀에 빠지지 않습니다.

그래서 서브시스템 모듈은 자기 의존성을 `module:RunInit(InitOther)`로 직접 당겨오면 되고, 설치 순서를 신경 쓸 필요가 없습니다.

**예제**

```luau
local runs = 0
local function InitCounter(_module)
	runs += 1
end

local m = Quad.New()
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

**동작** — `pluginFn(self)`가 돌려준 테이블의 필드를 모듈에 얕게 병합합니다. 새 인스턴스를 만들지 않고 받은 모듈을 그 자리에서 뮤테이션합니다 — `RunInit` 기록이 identity에 의존하기 때문입니다. 슬롯 락이 없으므로 같은 필드를 나중 플러그인이 덮어씁니다. **같은 `pluginFn`을 다시 넘기면 아무것도 하지 않습니다** — `RunInit`과 같은 identity 기준이라 여러 스크립트가 각자 설치해도 한 번만 돕니다. 설치 표시는 `pluginFn`이 끝까지 돈 뒤에 하므로, 도중에 던진 플러그인은 다시 부르면 처음부터 돕니다. 플러그인이 안에서 다른 플러그인을 설치하는 한 방향 의존은 괜찮지만, **서로를 설치하는 순환**(A가 B를, B가 A를)은 정의되지 않은 동작입니다. 백엔드 설치에는 이걸 쓰지 말고 `UseProvider`를 쓰세요.

**이미 있는 필드를 덮을 때** — 막지 않습니다. 코어 부품을 일부러 갈아 끼우는 플러그인도 쓸 수 있어야 하기 때문입니다. 다만 `q.Source` 같은 코어 필드가 남의 것으로 바뀌면 원인을 찾기 어려우므로, [`q.debug`](#qdebug)가 켜져 있으면 설치 시점에 한 줄을 출력합니다. 검사 대상은 `pluginFn`이 **돌려준 테이블**이 덮는 필드뿐이고, `pluginFn` 안에서 모듈에 직접 대입한 필드는 알리지 않습니다. 검사는 `AddPlugin`을 부를 때 한 번만 돌고, `q.debug`는 그보다 **먼저** 켜 두어야 합니다.

- `AddPlugin: plugin overwrites existing module field "{k}" — intended if the plugin extends a core part on purpose; otherwise rename the plugin's field`

**`_`로 시작하는 필드는 공개 표면이 아닙니다.** 모듈에 런타임으로 존재하더라도(`_bookkeeping` 등) 내부 계약이며 예고 없이 바뀝니다 — 읽거나 덮어쓰는 코드에 기대지 마세요.

**예제**

```luau
local function doublePlugin(_self)
	return {
		Double = function(_selfArg, v: number)
			return v * 2
		end,
	}
end

local m = Quad.New():AddPlugin(doublePlugin)
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

**반환** — 같은 모듈. 타입은 `Self & P`이므로 여기서부터 `q.Declaration`/`q.Tween` 같은 백엔드 표면이 타입에 실립니다.

**동작** — 병합 자체는 `AddPlugin`과 같지만 계약이 다릅니다: **모듈당 프로바이더는 하나**이고, 잠금은 프로바이더 함수의 identity로 겁니다.

- 같은 함수로 다시 부르면 멱등 no-op입니다. 같은 모듈을 `require`하면 캐시가 같은 함수를 주므로 일반적인 재호출은 그대로 통과합니다.
- 다른 identity면 던집니다 — 다른 백엔드든, 같은 백엔드의 **다른 사본/버전**이든 마찬가지입니다.

  ```
  UseProvider: this Quad module already has a provider — a module cannot serve two backends
  ```

- 슬롯 표시는 **성공한 뒤에** 찍습니다. `providerFn`이 도중에 던지면 슬롯은 비어 있는 채로 남아 다시 시도할 수 있습니다(표시를 먼저 찍었다면 재시도가 멱등 no-op에 삼켜져 확장이 영영 병합되지 않는 좀비가 됩니다).

quad-roblox는 설치 시점에 quad-base 버전을 확인하고, 맞지 않으면 호출한 줄을 blame하며 던집니다 —

```
quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')
```

`{VERSION_PATTERN}` 자리에는 그 quad-roblox가 요구하는 패턴이 들어갑니다(이 저장소의 현재 값은 `3.2^.0^` — 같은 메이저 안에서 3.2.0 이상).

**예제**

```luau
local q = Quad:UseProvider(QuadRoblox)
local q2 = q:UseProvider(QuadRoblox) -- 같은 함수 — 멱등 no-op
print(q2 == q) --> true
```

## `q.Version`

**시그니처**

```luau
Version: "3.2.0"
```

**동작** — 이 quad-base 사본의 버전 문자열. 타입이 싱글톤 문자열이라 타입 층에서도 값이 그대로 보입니다. 백엔드는 `UseProvider` 시점에 이 값을 자기 패턴과 대조하는 데 씁니다(위 참고).

중간 빌드는 `3.1.0-rc.1`이나 `3.0.1-dev.3+build.7`처럼 SemVer 프리릴리즈·빌드 꼬리를 달 수 있습니다. 대조할 때 `+` 뒤 빌드 메타데이터는 양쪽 다 무시하고, 프리릴리즈 꼬리는 **있고 없음이 양쪽에서 같아야** 합니다 — 꼬리 없는 패턴은 rc 빌드를 받지 않고, 꼬리 있는 패턴은 릴리즈를 받지 않습니다. 둘 다 받으려면 `|`로 대안을 나열합니다(`"3.3.0|3.3.0-rc.1^"`). 패턴 문법 전체는 [백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/)에 있습니다.

## `q.debug`

**시그니처**

```luau
debug: boolean
```

**동작** — 기본값 `false`. 진단 줄을 켜는 플래그입니다 — 켜도 동작은 바뀌지 않고, 치명적이지 않은 실수를 한 줄씩 출력한 뒤 **실행을 그대로 계속합니다**. 지금 이 플래그를 읽는 자리는 셋입니다.

- `q.Dispatch.addHandler`가 등록 시점에 같은 우선순위의 핸들러를 발견할 때([`../extend/02-dispatch-handler-contract.md`](/reference/extend/02-dispatch-handler-contract/)).
- [`q:AddPlugin`](#qaddpluginpluginfn)이 기존 필드를 덮을 때.
- 옵션 테이블에 모르는 키(오타·옛 이름)가 있을 때 — `q.Debounce`/`q.Throttle`, `slot:List`/`slot:Single`의 `opts`, `q.Tween`, `q.Animate`. 모르는 키는 꺼져 있을 때와 똑같이 무시됩니다.

셋 다 그 호출 시점에 한 번 보므로 `q.debug`는 먼저 켜 두세요.

```luau
q.debug = true -- 동률·덮어쓰기·모르는 옵션 키 진단을 켠다
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

자세한 사용법은 [`../extend/01-backend-provider-contract.md`](/reference/extend/01-backend-provider-contract/).

## `q.moduleIdentity`

**시그니처**

```luau
read moduleIdentity: {}
```

**동작** — 이 모듈 인스턴스의 identity 토큰입니다. 내용이 없는 빈 테이블이고 모듈을 붙잡지 않으며, 계약은 "인스턴스마다 하나, 서로 다름"뿐입니다.

- quad-base는 Observer·Effect·Slot·State가 자기 인스턴스의 것인지 이 토큰으로 판정합니다(위 `q.New()`의 "인스턴스끼리 값을 섞지 마세요").
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
local host = D.Frame {}

rel:SetStrong(host, "meta", { label = "hello" })
print(rel:GetStrong(host, "meta").label) --> hello
```

`q.Void`(공용 no-op 함수)도 같은 잎 계열로 모듈 표면에 실려 있습니다 — [생명주기와 센티널](/reference/core/10-lifetime-sentinels/#qvoid).

## 관련

- [`../../getting-started/00-installation.md`](/getting-started/00-installation/) — 두 패키지를 require하고 백엔드를 설치하기까지
- [생명주기와 센티널](/reference/core/10-lifetime-sentinels/) — 백엔드가 없는 모듈에서 나는 스텁 에러
- [`../extend/01-backend-provider-contract.md`](/reference/extend/01-backend-provider-contract/) — 프로바이더가 채워야 하는 슬롯 전체
- [`../roblox/01-install.md`](/reference/roblox/01-install/) — `QuadRoblox`가 싣는 표면
