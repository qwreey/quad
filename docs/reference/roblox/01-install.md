---
title: "설치와 프로바이더"
description: "QuadRoblox 프로바이더 함수, UseProvider 계약, RobloxExtension 다섯 키, 타입 검사 플래그"
---
# Roblox 백엔드 설치

`quad-base`는 엔진을 모릅니다. Roblox Instance를 만들고 프로퍼티를 쓰고 이벤트에 붙는 일은
**`quad-roblox` 백엔드**가 하고, 그 백엔드는 `UseProvider` 한 줄로 설치됩니다.

이 페이지의 심볼: [`QuadRoblox`](#quadroblox) · [`Quad:UseProvider(QuadRoblox)`](#quaduseproviderquadroblox) ·
[`RobloxExtension`](#robloxextension)

:::note
이 폴더(`reference/roblox/`)의 모든 것은 **`quad-roblox` 백엔드를 설치한 뒤에만** 존재합니다.
`quad-base`만 require한 모듈에서 `q.D`/`q.Tween`/`q.Animate`/`q.OnChange`/`q.isTween`는 전부 `nil`입니다.
:::

이 문서의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## `QuadRoblox`

**시그니처**

```luau
-- require(<quad-roblox 모듈 경로>) 가 돌려주는 테이블의 유일한 값 필드
QuadRoblox: <T>(quad: T) -> RobloxExtension
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `quad` | 모듈 인스턴스 | 백엔드를 설치할 `quad-base` 모듈. 보통 `UseProvider`가 `self`로 넘겨준다 |

**반환** — `RobloxExtension`(아래). `UseProvider`가 이 테이블을 모듈에 병합합니다.

**동작**

`QuadRoblox`는 **프로바이더 함수**이지 모듈이 아닙니다 — 직접 부르지 말고 `UseProvider`에 넘기세요.
호출되면 순서대로 이렇게 합니다.

1. **버전 게이트** — 받은 모듈의 `Version`이 이 패키지가 요구하는 패턴과 맞는지 런타임에 검사합니다.
   맞지 않으면 소비자의 `UseProvider` 줄을 blame하며 던집니다.

   ```
   quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')
   ```

   `{VERSION_PATTERN}`은 이 패키지에 박힌 상수이고 저장소 현재 값은 `"0.0.0"`, `{tostring(q.Version)}`은
   넘어온 모듈의 `Version` 필드입니다. 모노레포는 정확한 버전을 핀으로 잡고, 독립 게시 백엔드라면
   더 느슨한 패턴을 쓰게 됩니다.
2. **모듈 뮤테이션** — 생명주기 프리미티브(`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`)와
   `nativeClaim`, 엔진 op 일습을 모듈에 심고, 백엔드가 소유한 핸들러 넷(Property / InstanceChild /
   Event / InstanceShorthand)과 OnChange 핸들러를 디스패치에 등록합니다. 주입 슬롯의 전체 목록과
   계약은 [백엔드 프로바이더 규약](../extend/01-backend-provider-contract.md)이 소스입니다.
3. **확장 반환** — `RobloxExtension` 테이블을 돌려줍니다.

---

## `Quad:UseProvider(QuadRoblox)`

**시그니처**

```luau
UseProvider: <Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P
```

**반환** — 같은 모듈 인스턴스. 다만 타입은 `Self & P` 교집합이라, 반환값을 받아 쓰면 `q.D`가 캐스트
없이 그대로 타입드입니다.

```luau
local q = Quad:UseProvider(QuadRoblox)
local D = q.D -- 병합된 확장. `Quad.D`로도 같은 값에 닿는다
```

**동작 — 모듈당 프로바이더 하나**

`UseProvider`는 **모듈당 한 슬롯**이고, 잠금은 프로바이더 **함수의 identity**로 겁니다.

- 같은 함수로 다시 부르면 아무 일도 일어나지 않습니다(멱등). `require` 캐시가 같은 모듈에 같은
  identity를 주므로 보통은 자연히 통과합니다.
- 다른 identity로 부르면 — 다른 백엔드든, 같은 백엔드의 **다른 사본/버전**이든 — 던집니다.

  ```
  UseProvider: this Quad module already has a provider — a module cannot serve two backends
  ```

  메시지가 점유자를 이름으로 짚지 않는 것은 identity 잠금에 이름이 없기 때문입니다.
- 잠금이 `quad-base` 쪽에 사는 이유는 프로바이더 작성자가 가드를 빠뜨려도 구조적으로 막히게 하려는
  것입니다. 그래서 `RobloxFactory`를 직접 부르거나 `AddPlugin`으로 우회하면 이 잠금과 확장 병합을
  둘 다 건너뛰게 됩니다 — 지원 대상이 아닙니다.

두 모듈 인스턴스가 필요하면 `Quad.New()`로 격리된 인스턴스를 만들어 각각 설치하세요.

---

## `RobloxExtension`

`QuadRoblox`가 돌려주고 `UseProvider`가 모듈에 병합하는 확장 표면입니다. 다섯 키가 전부입니다.

```luau
export type RobloxExtension = {
	D: DModule.D,
	OnChange: OnChangeFn,
	Animate: AnimateFn,
	Tween: Types.TweenConstructor,
	isTween: (x: any) -> boolean,
}
```

| 키 | 무엇 | 상세 |
|---|---|---|
| `D` | Instance 생성기 네임스페이스 — 클래스별 별칭 + `New`/`Mapper`/`Modifier` | [D — Instance 생성](./02-d.md), [D.Modifier](./03-d-modifier.md), [Claim과 D.Mapper](./04-claim-mapper.md) |
| `OnChange` | 프로퍼티 변경 신호 디스크립터 팩토리 | [q.OnChange](./05-onchange.md) |
| `Animate` | `state:Apply`용 트윈 콤비네이터 | [Tween과 Animate](./06-tween-animate.md) |
| `Tween` | 값-레벨 트윈 래퍼 생성자 | [Tween과 Animate](./06-tween-animate.md) |
| `isTween` | 그 값이 `Tween`인지 판정하는 술어 | [Tween과 Animate](./06-tween-animate.md) |

`Tween`/`isTween`은 모듈에도 직접 놓입니다 — 형제 설치자(Property 핸들러, 숏핸드 핸들러, `Animate`)와
`quad-base`의 브랜드 진단 프로브가 그 자리를 보기 때문입니다. 사용자 입장에서는 `q.Tween` 하나로 같습니다.

**타입 재익스포트** — `quad-roblox` 모듈 자체는 값 표면 외에 타입도 내보냅니다.
`Tween<T>` / `TweenData<T>` / `TweenOptions<T>` / `TweenOverride` / `TweenConstructor` / `NewChild` /
`OnChangeDescriptor` / `AnimateInfo` / `AnimateFn`과, 생성 모듈에서 온 `D` / `DMapper` / `PropTypes` /
`OnChangeFn`입니다.

```luau
local RobloxModule = require(<quad-roblox 모듈 경로>)
local fade: RobloxModule.Tween<number> = q.Tween({ Value = 0, Time = 0.2 })
```

클래스별 타입(`FrameModifier`, `IntoTextButton`, `FrameParam<E>` 등)은 재익스포트 목록에 없고
**생성 모듈**(`quad-roblox/src/D`)에서 직접 가져갑니다 — 손으로 나열하면 "전량 생성" 계약과 어긋나기
때문입니다.

---

## 타입 검사 설정

`quad-roblox`는 Roblox 전역 타입(`Instance`/`Enum`/`TweenInfo`/`UDim2` …)을 쓰고, 생성된 `D` 타입은
대형 유니언·교집합 덩어리입니다. 그래서 **새 솔버(Solver V2)**와 한도 플래그 셋이 필요합니다.
저장소가 자기 코드를 검사할 때 쓰는 명령이 그대로 참고 형태입니다.

```sh
luau-lsp analyze --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<globalTypes.d.luau 경로> \
  <검사할 경로>
```

| 플래그 | 없으면 생기는 일 |
|---|---|
| `LuauSolverV2=true` | `quad-types`의 타입 함수가 "syntax not supported"로 죽는다 |
| `LuauTarjanChildLimit` | 클래스별 `Param`·`Modifier`를 인스턴스화하는 `D`/`DModifier` 선언이 "Code is too complex" |
| `LuauSubtypingIterationLimit` | 클래스별 `OnChange` 유니언에 멤버 많은 콜백을 대조할 때 "Code is too complex" |
| `LuauTypeInferIterationLimit` | 조상 클래스 Modifier(`As<Class>` 메소드가 수십 개)의 캐스트·`Apply` 자리가 "too complex" |

값은 저장소가 실측으로 고른 것이고, 여러분의 코드가 더 크면 더 올려야 할 수 있습니다.
`--definitions`는 `luau-analyze`가 아니라 **`luau-lsp`의 기능**입니다.

---

**관련**

- [00. 설치 및 환경 구축](../../getting-started/00-installation.md) — 패키지 배치와 Rojo 매핑
- [백엔드 프로바이더 규약](../extend/01-backend-provider-contract.md) — 주입 슬롯 전수와 포팅 계약
- [Quadnomicon Vol. 10 — 다중 백엔드 추상 기계](../../quadnomicon/10-multi-backend-abstract-machine.md)
