---
title: "백엔드 프로바이더 규약"
description: "quad-base가 백엔드에 요구하는 주입 op 전체와 UseProvider 설치 계약 — 새 백엔드를 포팅하는 사람을 위한 규약"
---
# 백엔드 프로바이더 규약

> **대상 독자**: Quad를 Roblox 외 플랫폼으로 포팅하거나 커스텀 백엔드를 작성하려는 엔지니어
> **정본 소스**: 주입 슬롯의 타입 정의는 `quad-types/src/init.luau`, Roblox 구현은 `quad-roblox/src/EngineOps.luau`와 `quad-roblox/src/LifetimeHandle.luau`, 미설치 스텁은 `quad-base/src/LifetimeHandle.luau`

이 페이지의 심볼: 주입 슬롯 19개를 [다섯 묶음](#1-아키텍처-개요-base와-provider의-분리)으로 —
[물리 트리 조작 `native*`](#2-물리-트리-조작-native) · [판정·훅·조회 op](#3-판정훅조회-op) ·
[생명주기 프리미티브](#4-생명주기-프리미티브) ·
[메타데이터 op와 시간 op](#5-메타데이터-op와-시간-op). 그 위의 설치 계약은
[프로바이더 설치와 1슬롯 identity 락](#6-프로바이더-설치와-1슬롯-identity-락), 빠진 슬롯의 동작은
[슬롯이 비어 있으면 어떻게 되나](#7-슬롯이-비어-있으면-어떻게-되나)에 있습니다.

---

## 1. 아키텍처 개요: Base와 Provider의 분리

`quad-base`는 상태 그래프, 의존성 전파, 슬롯 트리, 디스패치 체인, 에러 블레임을 소유합니다. 엔진에 대해서는 아무것도 모릅니다 — 요소(element)의 실제 타입이 무엇인지조차 모르고, 판정이 필요하면 **주입된 술어**를 부릅니다.

백엔드는 `quad:UseProvider(providerFn)`으로 설치되며, 프로바이더 함수는 두 가지 일을 합니다.

1. 모듈 인스턴스를 **뮤테이션**해서 아래 주입 슬롯들을 채웁니다.
2. 백엔드 고유 표면(Roblox라면 `D`/`OnChange`/`Animate`/`Tween`/`isTween`)을 담은 **확장 테이블**을 반환합니다. `UseProvider`가 이걸 모듈에 병합합니다.

주입 슬롯은 전부 19개이고, 성격에 따라 다섯 묶음으로 나뉩니다. 이 목록의 단일 소스는 `quad-types/src/init.luau`의 `Quad` 레코드입니다.

| 묶음 | 슬롯 |
|---|---|
| 물리 트리 조작 (`native*`) | `nativeInsert` `nativeExtract` `nativeRemove` `nativeMove` `nativeSwap` `nativeDispose` |
| 판정·훅·조회 op | `isInst` `onDestroying` `nativeClaim` `nativeFindChild` |
| 생명주기 프리미티브 | `bindLifetime` `unbindLifetime` `canBound` `canExecute` |
| 메타데이터 op | `addTag` `removeTag` `setAttr` |
| 시간 op | `setTimeout` `clearTimeout` |

두 번째 백엔드가 이미 존재합니다 — 테스트용 mock(`quad-base/test/mock.luau`)이 같은 계약을 전부 구현하고, 같은 `UseProvider` 경로로 설치됩니다. 계약이 실제로 어떻게 읽히는지 확인하고 싶다면 그 파일이 가장 정확한 참고 구현입니다.

---

## 2. 물리 트리 조작 (`native*`)

슬롯 트리가 요소를 삽입·추출·제거·재배치할 때 부르는 저수준 연산입니다.

```
nativeInsert  (target: any, offset: number, elements: { any }) -> ()
nativeExtract (target: any, offset: number, elements: { any }, newElements: { any }?) -> ()
nativeRemove  (target: any, offset: number, elements: { any }, newElements: { any }?) -> ()
nativeMove    (target: any, fromOffset: number, elements: { any }, toOffset: number) -> ()
nativeSwap    (target: any, offsetA: number, elementsA: { any }, offsetB: number, elementsB: { any }) -> ()
nativeDispose (element: any) -> ()
```

**공통 규약 세 가지**를 먼저 알아야 시그니처가 읽힙니다.

- **대상은 언제나 요소 배열입니다.** `(target, offset, count)`만으로 대상을 역으로 찾을 수 있는 건 DOM처럼 자식이 순서 있는 컬렉션인 플랫폼뿐입니다. Roblox에서 자식은 순서 없는 집합이고 quad의 offset은 순전히 논리값이라, 백엔드가 offset으로 인스턴스를 되찾을 수 없습니다. 그래서 빠지거나 들어가는 요소를 배열로 직접 넘깁니다. 개수는 `#elements`로 따라옵니다.
- **`offset`은 전부 0-based 절대 offset입니다.** 평탄화된 리프 좌표계의 값이고, `Slot` 스코프 안의 인덱스가 아닙니다.
- **Replace와 Splice는 별도 op이 아닙니다.** `newElements`를 가진 `nativeRemove`(파괴하며 교체) 또는 `nativeExtract`(살려두고 교체)가 그 역할을 합니다. 제거와 삽입을 한 호출로 합치는 이유는 리플로우가 두 번 일어나고 그 사이 인덱스가 어긋나는 창을 없애기 위함입니다.

각 op의 뜻:

| op | 뜻 | Roblox 구현 |
|---|---|---|
| `nativeInsert` | `elements`를 `target` 아래로 넣는다 | `element.Parent = target` 반복 |
| `nativeExtract` | `elements`를 트리에서 빼되 **살려둔다**(+ `newElements`를 그 자리에 넣는다) | `element.Parent = nil` 반복 |
| `nativeRemove` | `elements`를 트리에서 빼면서 **파괴한다**(+ `newElements` 삽입) | `element:Destroy()` 반복 |
| `nativeMove` | 블록을 `fromOffset`에서 `toOffset`으로 옮긴다 | **의도된 no-op** (아래) |
| `nativeSwap` | 두 블록을 맞교환한다 | **의도된 no-op** (아래) |
| `nativeDispose` | 트리 **밖**에 있는 값 하나를 파괴한다 | `element:Destroy()` |

`nativeMove`의 `toOffset`은 "이동 **후** 블록 첫 리프의 절대 offset"이고 `fromOffset`은 이동 전 값입니다. `nativeSwap`의 두 offset은 둘 다 교환 **전** 값입니다 — 두 블록의 리프 수가 다르면 사이 요소가 그 차이만큼 밀립니다.

### 2.1 Roblox에서 `nativeMove`/`nativeSwap`이 no-op인 이유

Roblox 백엔드는 `offset` 인자를 전부 무시합니다. 자식의 배치 순서는 `LayoutOrder`가 정하지 `Parent`에 붙은 순서가 정하지 않기 때문에, **순서는 quad 쪽 장부일 뿐 물리적인 성질이 아닙니다.**

그래서 `nativeMove`/`nativeSwap`은 quad-roblox에서 빈 함수로 **일부러 덮어씁니다**. 그냥 두면 "떼었다 다시 붙이기"로 재배치를 흉내내게 되는데, 그건 `.Parent` 쓰기 두 번(따라서 `AncestryChanged` 재발화와 깜빡임)을 치르고도 Roblox에서는 물리적으로 아무것도 바꾸지 않습니다. mock 백엔드도 같은 이유로 같은 선택을 합니다.

DOM처럼 자식 순서가 실제 물리 성질인 플랫폼을 쓴다면 이 둘을 진짜로 구현해야 하고, 그때 `offset` 인자들이 의미를 갖습니다.

---

## 3. 판정·훅·조회 op

`native*`와 달리 이 넷은 조작이 아니라 **판정·훅·조회**입니다.

```
isInst          (value: any) -> boolean
onDestroying    (inst: any, fn: () -> ()) -> { Connected: boolean, Disconnect: (self: any) -> () }
nativeClaim     (inst: any) -> ()
nativeFindChild (inst: any, key: any) -> any
```

- **`isInst(value)`** — "이 값이 이 백엔드의 마운트 가능한 요소인가". quad-base는 `T`가 무엇인지 모르므로 요소 타입 검증을 이 화이트리스트 술어에 전부 위임합니다. quad-roblox 구현은 `typeof(value) == "Instance"` 한 줄이고, mock은 "이게 mock 인스턴스인가"입니다.
- **`onDestroying(inst, fn)`** — 요소가 파괴될 때 `fn`을 부르는 훅. 반환값은 **Connection 모양**(`Connected` 필드와 `Disconnect` 메소드를 가진 값)이어야 합니다 — `Effect`가 바인딩을 풀 때 이걸 끊습니다. quad-roblox 구현은 `inst.Destroying:Connect(fn)`입니다.
- **`nativeClaim(inst)`** — 요소 하나를 quad 소유로 등록하는 셋업. quad-roblox에서는 여기서 GC 앵커(`gchold`)와 절대 발화하지 않는 시그널 연결(`gcconn`)을 만듭니다. `New`가 인스턴스를 만든 직후, 그리고 `Claim`이 기존 트리를 흡수할 때 요소마다 정확히 한 번 불립니다. **같은 요소를 두 번 claim하면 에러**(`nativeClaim: Instance is already claimed by quad`)이고, 이미 파괴된 요소를 claim하는 것은 정의되지 않은 동작입니다(가드하지 않습니다).
- **`nativeFindChild(inst, key)`** — 매퍼 디스크립터의 키로 직계 자식을 찾는 조회 op. 키가 무슨 뜻인지는 백엔드가 정합니다(Roblox는 `Name`, web이라면 id나 selector). quad-roblox 구현은 `inst:FindFirstChild(key)`입니다.

---

## 4. 생명주기 프리미티브

Luau에는 ephemeron이 없어서, "이 값이 저 요소가 사는 동안 살아 있게 하라"와 "이 값이 지금 발화해도 되는가"를 백엔드가 직접 구현해야 합니다.

```
bindLifetime   (inst: any, value: any) -> ()
unbindLifetime (value: any) -> ()
canBound       (value: any) -> boolean
canExecute     (value: any) -> boolean
```

- **`bindLifetime(inst, value)`** — `inst`가 사는 동안 `value`가 살아 있도록 강참조로 묶고, `value` 쪽에는 자기 생존 판정 근거를 약참조로 남깁니다. `inst`를 필요로 하는 건 이 하나뿐입니다.
- **`unbindLifetime(value)`** — **인자 하나**. 이 값 하나만 조기 해제하며, `inst`는 건드리지 않습니다. cleanup을 부르지도, 안쪽 Observer를 떼지도 않습니다(대칭적 해제일 뿐). 안 묶인 값에 부르면 no-op이지만 `nil`은 에러입니다 — 인자가 빠진 것이지 "안 묶인 값"이 아니기 때문입니다.
- **`canBound(value)`** — "지금 이 값을 묶어도 되는가". 아직 아무 데도 안 묶여 있거나, 묶였던 인스턴스가 이미 파괴됐으면(연결이 끊겼으면) 참 — 즉 죽은 뒤 재사용은 허용됩니다.
- **`canExecute(value)`** — "이 값이 지금 발화해도 되는가". **묶인 채 살아 있으면 참**입니다. State 전파가 이 게이트로 죽은 요소에 매달린 Observer/Effect를 걸러냅니다.

**`canBound(v) == not canExecute(v)`** — 둘은 백엔드 비공개 술어 하나(`isBoundAlive`)를 공유하는 얇은 진입점이어야 합니다. quad-roblox와 mock 모두 그 술어가 보는 것은 둘뿐입니다: (a) `bindLifetime`이 값에 복사해 둔 gcconn의 `.Connected`, (b) 값이 `Observer`/`Effect`라면 전역 구독 상태(`.Subscribed`).

네 함수는 `module.canExecute(v)`처럼 **모듈 인스턴스의 필드로** 읽어야 합니다. `Init` 시점에 지역 변수로 캡처해 두면 백엔드가 나중에 덮어쓴 실 구현이 아니라 스텁을 계속 부르게 됩니다.

### 4.1 Roblox의 파괴 동작

Roblox에서 부모에 `:Destroy()`를 부르면 엔진이 자손까지 파괴하고 각각의 `Destroying`을 발화시킵니다. quad가 그 사실을 관측하는 통로는 `onDestroying` 하나이고, 서브트리의 `Effect` cleanup은 그 발화를 타고 돕니다.

이건 **Roblox 엔진이 그렇게 동작한다는 서술이지, 백엔드에 부과된 계약이 아닙니다.** 위 §1의 슬롯 목록이 주입 계약의 전부이고, 거기에 "재귀 파괴를 직접 구현하라"는 항목은 없습니다. 자기 플랫폼의 파괴 동작이 다르다면 `onDestroying`이 언제 불리는지가 그만큼 달라질 뿐입니다.

---

## 5. 메타데이터 op와 시간 op

### 5.1 `Tag`/`Attr`

```
addTag    (inst: any, names: { string }) -> ()
removeTag (inst: any, names: { string }) -> ()
setAttr   (inst: any, name: string, v: any) -> ()
```

- **태그 op는 이름 하나가 아니라 이름 배열을 받습니다.** 배치가 계약인 이유는 웹 백엔드라면 `className`을 한 번에 다시 쓰는 게 자연스럽기 때문입니다. Roblox에는 배치 API가 없으므로 루프가 백엔드 쪽에 있습니다(`CollectionService:AddTag` / `:RemoveTag`).
- **`setAttr(inst, name, nil)`은 삭제입니다.** Roblox는 `inst:SetAttribute(name, nil)`이 네이티브로 삭제라 그대로 위임합니다. 다른 플랫폼이라면 `nil` 분기를 직접 써야 합니다.

### 5.2 시간 op

```
setTimeout   (func: () -> (), delay: number) -> Timeout
clearTimeout (timeout: Timeout) -> ()
```

`Debounce`/`Throttle`이 이 둘 위에 얹힙니다. `Timeout`은 `{ __quadTimeout = true, _native = ... }` 모양이고 `_native`는 백엔드만 읽습니다 — 마커 필드 덕분에 `clearTimeout`이 남의 값을 받으면 바로 걸러집니다.

**⚠️ `task.delay`와 인자 순서가 반대입니다.** quad는 `setTimeout(func, delay)`이고 Roblox는 `task.delay(delay, func)`라, quad-roblox의 구현은 `task.delay(delay, func)`로 뒤집어 부릅니다.

이미 발화했거나 취소된 핸들에 `clearTimeout`을 부르는 것은 no-op입니다(Roblox `task.cancel`이 죽은 스레드에 조용히 no-op인 것과 같게 맞춰져 있습니다).

---

## 6. 프로바이더 설치와 1슬롯 identity 락

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

커스텀 백엔드를 쓴다면 프로바이더 함수의 모양은 이렇습니다.

```luau
-- `Quad`는 위 프롤로그에서 require한 quad-base 모듈
local customWidgetNamespace = { -- 이 백엔드가 얹는 고유 표면
    Button = function(props: any): any
        return props
    end,
}

local function CustomProvider(quad: any)
    -- [1] 주입 슬롯을 채운다(§2~§5 전부 — 하나라도 빠지면 그 op는 안내 스텁 에러로 남는다)
    quad.nativeInsert = function(target: any, _offset: number, elements: { any })
        for _, element in elements do
            element.Parent = target
        end
    end
    -- ... 나머지 18개 슬롯 ...

    -- [2] 백엔드 고유 표면을 확장 테이블로 반환한다
    return {
        Widget = customWidgetNamespace,
    }
end

local q = Quad.New():UseProvider(CustomProvider)
```

계약 넷:

1. **모듈 인스턴스당 프로바이더는 하나**입니다. 슬롯을 점유하는 키는 **프로바이더 함수의 identity**입니다.
2. **같은 함수를 다시 넘기면 멱등 no-op**입니다. 일반적인 경우엔 require 캐시가 같은 함수 identity를 주므로 자연히 통과합니다.
3. **다른 identity를 넘기면 에러**입니다 — 다른 백엔드든, 같은 백엔드의 다른 사본/버전이든 똑같이 막힙니다:
   `UseProvider: this Quad module already has a provider — a module cannot serve two backends`
4. **슬롯 마킹은 프로바이더 함수가 성공적으로 반환한 뒤**에 일어납니다. 설치 도중 던지면 슬롯이 점유되지 않으므로, 원인을 고치고 다시 부를 수 있습니다.

반환된 확장 테이블은 모듈에 키 단위로 병합됩니다(얕은 복사). quad-roblox가 반환하는 확장(`RobloxExtension`)은 다섯 개 키입니다 — `D`(생성된 클래스 네임스페이스), `OnChange`, `Animate`, `Tween`, `isTween`. 병합 뒤에는 `q.D`처럼 모듈에서 바로 꺼내 쓰면 되고, 반환 타입이 교집합으로 합쳐지므로 캐스트가 필요 없습니다.

`QuadRoblox`는 설치 시점에 받은 quad-base 인스턴스의 `Version`을 자기 패턴과 대조하고, 안 맞으면 그 자리에서 던집니다. 패턴은 `.`로 나뉜 자리마다 `*`(뭐든) / `N^`(N 이상) / 정확 일치로 읽히며, `3.1.0-rc.1` 같은 프리릴리즈 꼬리는 패턴에 프리릴리즈가 있을 때만 정확 일치를 요구하고(`"3.*.*"`류 느슨한 패턴은 rc 빌드도 통과) `+` 뒤 빌드 메타데이터는 양쪽 다 무시합니다. 락은 프로바이더가 아니라 `UseProvider` 안에 있으므로, 프로바이더 작성자가 가드를 빠뜨려도 구조적으로 막힙니다. `AddPlugin`은 같은 병합을 하되 락이 없습니다 — 백엔드 팩토리를 `AddPlugin`으로 넘기는 것은 지원 대상이 아닙니다.

---

## 7. 슬롯이 비어 있으면 어떻게 되나

quad-base는 위 19슬롯 전부에 **안내 스텁**을 깔아둡니다. 백엔드 없이 부르면 nil 호출 크래시가 아니라 이름이 박힌 에러가 호출자 줄에서 납니다.

```
quad: nativeInsert is not available — no backend has installed the lifetime primitives / engine ops (install a provider with quad:UseProvider — a bare Quad.New() has none; tests use mock.installLifetime)
```

이 스텁은 프로바이더가 덮어쓸 때까지만 공개 표면에 앉아 있습니다. 즉 **백엔드가 슬롯 하나를 빠뜨리면 그 op를 처음 쓰는 순간 그 이름이 그대로 에러 메시지에 나옵니다** — 조합으로 대신 만들어 주는 폴백은 없습니다.

---

## 관련

- [core/10 — 생명주기와 센티널](../core/10-lifetime-sentinels.md) — 여기 주입되는 `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`의 사용자 표면
- [extend/02 — 디스패치 핸들러 계약](./02-dispatch-handler-contract.md) — 이 op들을 실제로 부르는 핸들러 쪽 계약
- [Quadnomicon Vol. 10 — 다중 백엔드 추상 기계](../../quadnomicon/10-multi-backend-abstract-machine.md) — 이 경계가 왜 이렇게 그어졌는가
