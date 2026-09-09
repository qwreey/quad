---
title: Quad 모듈
description: require 결과가 곧 기본 인스턴스 — New/RunInit/AddPlugin/UseProvider와 모듈 표면 필드
---
`require(quad-base)`가 돌려주는 것은 클래스나 팩토리가 아니라 **이미 만들어진 quad 모듈 인스턴스**다. 바로 `q.Source(...)`를 부를 수 있고, 백엔드는 그 인스턴스에 `UseProvider`로 설치한다. 여러 개의 독립 인스턴스가 필요한 드문 경우에만 `q.New()`를 쓴다.

한 인스턴스는 자기만의 디스패치 핸들러 레지스트리, 부기(bookkeeping), 프로바이더 슬롯을 갖는다. `Void`/`Ref`/`Relate`/`Blocker` 같은 의존 없는 잎 모듈은 인스턴스끼리 공유되지만, `Source`/`Effect`처럼 인스턴스 상태를 닫아 쥐는 팩토리는 인스턴스마다 다른 함수다.

이 페이지의 심볼: [q.New()](#qnew) · [q:RunInit(initFn)](#qruninitinitfn) · [q:AddPlugin(pluginFn)](#qaddpluginpluginfn) · [q:UseProvider(providerFn)](#quseproviderproviderfn) · [q.Version](#qversion) · [q.debug](#qdebug) · [q.errorNamespace](#qerrornamespace) · [q.Relate()](#qrelate)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

## `q.New()`

**시그니처**

```luau
New: () -> Quad
```

**반환** — 새 `Quad` 모듈 인스턴스.

**동작** — 완전히 독립적인 모듈 인스턴스를 만든다. 서브시스템(디버그 표면, 생명주기 스텁, 반응형 코어, 디스패치, Ref, Claim, Slot, Tag/Attr, 시간 게이트, 생명주기 훅)이 그 자리에서 설치된다.

- **프로바이더는 들어 있지 않다.** `Quad.New()`로 만든 인스턴스는 백엔드가 없어서 `bindLifetime`·`isInst` 같은 슬롯이 안내 스텁 상태다 — [`../core/11-lifetime-sentinels.md`](/quad/ko/reference/core/11-lifetime-sentinels/) 참고.
- 인스턴스는 참조를 놓으면 수거된다. 모듈을 키로 삼는 전역 맵이 인스턴스를 붙잡지 않는다.
- 잎 모듈은 공유된다: `Quad.New().Void == Quad.Void`, `Quad.New().Ref == Quad.Ref`. 반면 `Quad.New().Source ~= Quad.Source`다.

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

**반환** — 없음. 확장 테이블을 병합하지 않는다(그건 `AddPlugin`의 일이다).

**동작** — 서브시스템 설치 함수를 이 인스턴스에서 **한 번만** 실행한다. `(모듈, initFn)` 쌍을 키로 기록하므로 같은 함수를 다시 넘기면 no-op이고, 다른 인스턴스에서는 다시 실행된다. 표시는 실행 **전에** 찍는다 — 서로를 당겨오는 Init들이 순환해도 무한 재귀에 빠지지 않는다.

그래서 서브시스템 모듈은 자기 의존성을 `module:RunInit(InitOther)`로 직접 당겨오면 되고, 설치 순서를 신경 쓸 필요가 없다.

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

**반환** — 같은 모듈(identity 그대로). 타입은 원래 표면과 확장의 교집합 `Self & P`라 체이닝이 그대로 이어진다.

**동작** — `pluginFn(self)`가 돌려준 테이블의 필드를 모듈에 얕게 병합한다. 새 인스턴스를 만들지 않고 받은 모듈을 그 자리에서 뮤테이션한다 — `RunInit` 기록이 identity에 의존하기 때문이다. 슬롯 락이 없으므로 같은 필드를 나중 플러그인이 덮어쓴다. 백엔드 설치에는 이걸 쓰지 말고 `UseProvider`를 쓸 것.

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
| `providerFn` | `(Self) -> P` | 백엔드 프로바이더 함수 — 모듈의 주입 슬롯을 채우고 백엔드 고유 표면을 돌려준다 |

**반환** — 같은 모듈. 타입은 `Self & P`이므로 여기서부터 `q.D`/`q.Tween` 같은 백엔드 표면이 타입에 실린다.

**동작** — 병합 자체는 `AddPlugin`과 같지만 계약이 다르다: **모듈당 프로바이더는 하나**이고, 잠금은 프로바이더 함수의 identity로 건다.

- 같은 함수로 다시 부르면 멱등 no-op이다. 같은 모듈을 `require`하면 캐시가 같은 함수를 주므로 일반적인 재호출은 그대로 통과한다.
- 다른 identity면 던진다 — 다른 백엔드든, 같은 백엔드의 **다른 사본/버전**이든 마찬가지다.

  ```
  UseProvider: this Quad module already has a provider — a module cannot serve two backends
  ```

- 슬롯 표시는 **성공한 뒤에** 찍는다. `providerFn`이 도중에 던지면 슬롯은 비어 있는 채로 남아 다시 시도할 수 있다(표시를 먼저 찍었다면 재시도가 멱등 no-op에 삼켜져 확장이 영영 병합되지 않는 좀비가 된다).

quad-roblox는 설치 시점에 quad-base 버전을 확인하고, 맞지 않으면 호출한 줄을 blame하며 던진다 —

```
quad-roblox: requires a quad-base matching version pattern '0.0.0' (got '{q.Version}')
```

**예제**

```luau
local q = Quad:UseProvider(QuadRoblox)
local q2 = q:UseProvider(QuadRoblox) -- 같은 함수 — 멱등 no-op
print(q2 == q) --> true
```

## `q.Version`

**시그니처**

```luau
Version: "0.0.0"
```

**동작** — 이 quad-base 사본의 버전 문자열. 타입이 싱글톤 문자열이라 타입 층에서도 값이 그대로 보인다. 백엔드는 `UseProvider` 시점에 이 값을 자기 패턴과 대조하는 데 쓴다(위 참고).

## `q.debug`

**시그니처**

```luau
debug: boolean
```

**동작** — 기본값 `false`. 지금 이 플래그를 읽는 자리는 **하나** — `q.Dispatch.addHandler`가 등록 시점에 같은 우선순위의 핸들러를 발견하면 진단 줄을 출력할지 결정할 때다([`../extend/02-dispatch-handler-contract.md`](/quad/ko/reference/extend/02-dispatch-handler-contract/)). 그 외의 동작에는 영향이 없다.

```luau
q.debug = true -- 핸들러 우선순위 동률 경고를 켠다
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

**동작** — quad-base 전체가 공유하는 **하나의** 에러 네임스페이스다. 공개 표면 함수들이 여기에 자기를 등록해 두고, 에러를 던질 때 그 등록을 이용해 스택에서 "quad 기계"와 "사용자 코드"의 경계를 찾아 사용자의 줄을 blame한다.

백엔드와 플러그인은 자기 quad-error 사본으로 새 네임스페이스를 만들지 말고 **이 값을 받아** 자기 표면을 태깅해야 한다 — 사본마다 태그 맵이 갈리면 경계 탐색이 끊긴다. 같은 사본 안의 모든 모듈 인스턴스가 같은 네임스페이스를 공유한다.

자세한 사용법은 [`../extend/01-backend-provider-contract.md`](/quad/ko/reference/extend/01-backend-provider-contract/).

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

**동작** — `(inst, key) -> value` 릴레이션을 만든다. **`inst`는 언제나 weak 키**이고(요소가 죽으면 그 요소의 항목 전체가 같이 사라진다), `Strong`/`Weak`는 **값**을 어떻게 보관할지만 가리킨다. quad 내부가 인스턴스별 부속 상태를 매다는 데 쓰는 프리미티브이고, 같은 필요가 있는 확장에서도 쓸 수 있다.

`inst`나 `key`가 `nil`이면 던진다 — `Relate:SetStrong: inst must not be nil`처럼 메소드 이름과 어느 인자인지를 밝힌다.

**예제**

```luau
local rel = q.Relate()
local host = D.Frame {}

rel:SetStrong(host, "meta", { label = "hello" })
print(rel:GetStrong(host, "meta").label) --> hello
```

`q.Void`(공용 no-op 함수)도 같은 잎 계열로 모듈 표면에 실려 있다 — [`../core/11-lifetime-sentinels.md`](/quad/ko/reference/core/11-lifetime-sentinels/#qvoid).

## 관련

- [`../../getting-started/00-installation.md`](/quad/ko/getting-started/00-installation/) — 두 패키지를 require하고 백엔드를 설치하기까지
- [`../core/11-lifetime-sentinels.md`](/quad/ko/reference/core/11-lifetime-sentinels/) — 백엔드가 없는 모듈에서 나는 스텁 에러
- [`../extend/01-backend-provider-contract.md`](/quad/ko/reference/extend/01-backend-provider-contract/) — 프로바이더가 채워야 하는 슬롯 전체
- [`../roblox/01-install.md`](/quad/ko/reference/roblox/01-install/) — `QuadRoblox`가 싣는 표면
