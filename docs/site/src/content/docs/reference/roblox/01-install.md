---
title: "설치와 프로바이더"
description: "QuadRoblox 프로바이더 함수, UseProvider 계약, RobloxExtension의 키, 타입 검사 설정"
---
`quad-base`는 엔진을 모릅니다. Roblox Instance를 만들고 프로퍼티를 쓰고 이벤트에 붙는 일은
**`quad-roblox` 백엔드**가 하고, 그 백엔드는 `UseProvider` 한 줄로 설치됩니다.

이 페이지의 심볼: [`QuadRoblox`](#quadroblox) · [`Quad:UseProvider(QuadRoblox)`](#quaduseproviderquadroblox) ·
[`RobloxExtension`](#robloxextension)

:::note
이 폴더(`reference/roblox/`)의 모든 것은 **`quad-roblox` 백엔드를 설치한 뒤에만** 존재합니다.
`quad-base`만 require한 모듈에서 `q.Elem`·`q.Modifier`·`q.Spread`·`q.Mapper`·`q.OnChange`·`q.OnEvent`·`q.Out`·`q.ForClasses`는 `Quad0108` 안내 스텁이고, `q.Tween`/`q.Animate`/`q.isTween`는 `nil`입니다.
:::

이 문서의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
local QuadRoblox = require("@game/ReplicatedStorage/roblox_packages/quad_roblox").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: q.Elem 등과 Tween/Animate가 생긴다
local Frame = q.Elem "Frame"
```

---

## `QuadRoblox`

**시그니처**

```luau
-- require("@game/ReplicatedStorage/roblox_packages/quad_roblox") 가 돌려주는 테이블의 유일한 값 필드
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

1. **버전 게이트** — 받은 모듈의 [`Version`](/reference/core/01-quad-module/)이 이 패키지가 요구하는 패턴과
   맞는지 런타임에 검사합니다.
   맞지 않으면 소비자의 `UseProvider` 줄을 blame하며 던집니다.

   ```
   Quad0228 quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')
   ```

   `{VERSION_PATTERN}`은 이 패키지에 박힌 상수이고 저장소 현재 값은 `"3.3^.0^"`(같은 메이저 안에서 3.3.0 이상), `{tostring(q.Version)}`은
   넘어온 모듈의 `Version` 필드입니다. 하한은 릴리즈마다 그 릴리즈 버전으로 올라가고, 메이저 자리는
   정확 일치라 메이저가 바뀌면 통과하지 않습니다. 프리릴리즈 빌드는 그 빌드를 정확히 적은 패턴(`"3.4.0-rc.2"`)을 써서
   같은 프리릴리즈의 quad-base만 받습니다 — 중간 빌드끼리 섞지 않기 위해서입니다.

   패턴은 `|`로 나뉜 대안 중 하나라도 맞으면 통과합니다. 대안마다 `+` 뒤 빌드 메타데이터를 버리고 첫 `-`에서
   core와 프리릴리즈 꼬리로 나눠 **따로** 판정하며(자리 개수가 다르면 불일치), 각 구간의 `.`로 나뉜 자리를
   `*`(뭐든 통과) / `N^`(숫자로 N 이상 — N보다 크면 **그 구간의** 뒤 자리는 보지 않는 사전식 하한) / 그 외(정확
   일치)로 읽습니다. `3.1.0-rc.1` 같은 꼬리는 **있고 없음이 양쪽에서 같아야** 합니다(꼬리 없는 패턴은 rc 빌드를
   받지 않음 — 예: `"3.4.0-rc.0"`은 `"3.3^.0^-rc.1^"`에 맞지 않지만 `"3.0.0-rc.1"`은 `"3.0.*-rc.1"`에 맞습니다). 전체 문법은
   [백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/)에 있습니다.
2. **모듈 뮤테이션** — 생명주기 hold op 넷(`holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy` — 그 위의
   `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`는 quad-base 것)과
   `nativeClaim`, 엔진 op 일습을 [모듈 인스턴스](/reference/core/01-quad-module/)에 심고, 백엔드가 소유한
   핸들러 넷(Property / InstanceChild / Event / InstanceShorthand)과 OnChange 핸들러를 디스패치에
   등록합니다. 주입 슬롯의 전체 목록과
   계약은 [백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/)이 소스입니다.
3. **확장 반환** — `RobloxExtension` 테이블을 돌려줍니다.

---

## `Quad:UseProvider(QuadRoblox)`

`UseProvider` 자체의 정본은 [core/01 — Quad 모듈](/reference/core/01-quad-module/)입니다. 여기서는
`QuadRoblox`를 넘겼을 때 무엇이 생기는지만 봅니다.

**시그니처**

```luau
UseProvider: <Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P
```

**반환** — 같은 모듈 인스턴스. 다만 타입은 `Self & P` 교집합이라, 반환값을 받아 쓰면 `q.Elem`이 캐스트
없이 그대로 타입드입니다.

```luau
local q = Quad:UseProvider(QuadRoblox)
local Frame = q.Elem "Frame" -- 병합된 확장. `Quad.Elem`으로도 같은 값에 닿는다(타입은 반환값 쪽에만 붙는다)
```

**동작 — 모듈당 프로바이더 하나**

`UseProvider`는 **모듈당 한 슬롯**이고, 잠금은 프로바이더 **함수의 identity**로 겁니다.

- 같은 함수로 다시 부르면 아무 일도 일어나지 않습니다(멱등). `require` 캐시가 같은 모듈에 같은
  identity를 주므로 보통은 자연히 통과합니다.
- 다른 identity로 부르면 — 다른 백엔드든, 같은 백엔드의 **다른 사본/버전**이든 — 던집니다.

  ```
  UseProvider: this Quad module already has a provider - a module cannot serve two backends
  ```

  메시지가 점유자를 이름으로 짚지 않는 것은 identity 잠금에 이름이 없기 때문입니다.
- 잠금이 `quad-base` 쪽에 사는 이유는 프로바이더 작성자가 가드를 빠뜨려도 구조적으로 막히게 하려는
  것입니다. 그래서 `RobloxFactory`를 직접 부르면 이 잠금도 확장 병합도 거치지 않고, `AddPlugin`으로
  우회하면 확장 병합은 되지만 1슬롯 identity 보호가 없습니다 — 둘 다 지원 대상이 아닙니다.

두 모듈 인스턴스가 필요하면 `Quad.NewModule()`로 격리된 인스턴스를 만들어 각각 설치하세요.

---

## `RobloxExtension`

`QuadRoblox`가 돌려주고 `UseProvider`가 모듈에 병합하는 확장 표면입니다.

```luau
export type RobloxExtension = {
	Elem: …, Modifier: …, Spread: …, Mapper: …,       -- 클래스를 먼저 받는 생성자(타입 함수가 계산)
	OnChange: …, OnEvent: …, Out: …,                 -- 숫자 키 자리 디스크립터
	ForClasses: <M>() -> …,                          -- 같은 표면을 여러분의 클래스 맵으로
	Animate: AnimateFn,
	Tween: Types.TweenConstructor,
	isTween: (x: any) -> boolean,
}
```

| 키 | 무엇 | 상세 |
|---|---|---|
| `Elem` | Instance 생성자 — `q.Elem "Frame" {…}` | [Elem — Instance 생성](/reference/roblox/02-elem/) |
| `Modifier` | 클래스별 타입드 Modifier 생성자 | [Modifier와 Spread](/reference/roblox/03-modifier-spread/) |
| `Spread` | 요소 테이블 조각 묶음 | [Modifier와 Spread](/reference/roblox/03-modifier-spread/#qspread-class-props) |
| `Mapper` | `Claim`용 매퍼 디스크립터 | [Claim과 Mapper](/reference/roblox/04-claim-mapper/) |
| `OnChange` / `OnEvent` / `Out` | 프로퍼티 변경·이벤트·되쓰기 디스크립터 | [OnChange·OnEvent·Out](/reference/roblox/05-onchange/) |
| `ForClasses` | 위 일곱을 여러분의 클래스 맵으로 | [Elem — q.ForClasses](/reference/roblox/02-elem/#qforclassesmap) |
| `Animate` | `state:Apply`용 트윈 콤비네이터 | [Tween과 Animate](/reference/roblox/06-tween-animate/) |
| `Tween` | 값-레벨 트윈 래퍼 생성자 | [Tween과 Animate](/reference/roblox/06-tween-animate/) |
| `isTween` | 그 값이 `Tween`인지 판정하는 술어 | [Tween과 Animate](/reference/roblox/06-tween-animate/) |

`Tween`/`isTween`은 모듈에도 직접 놓입니다 — 형제 설치자(Property 핸들러, 숏핸드 핸들러, `Animate`)와
`quad-base`의 브랜드 진단 프로브가 그 자리를 보기 때문입니다. 사용자 입장에서는 `q.Tween` 하나로 같습니다.

**타입 이름** — `quad-roblox` 모듈은 값 표면 외에 타입도 내보냅니다.

- 클래스를 인자로 받는 이름: `Props<C>` / `PropsHashPart<C>` / `PropsArrayItem<C>` / `MapperProps<C>` / `ElemCtor<C>` /
  `PropertyMap<C>`([02-elem](/reference/roblox/02-elem/#타입-이름--propsc--elemctorc--propertymapc)), `Modifier<C>` / `ModifierInto<C>` /
  `Spread<C>` / `SpreadInto<C>`([03-modifier-spread](/reference/roblox/03-modifier-spread/#modifierc--modifierintoc--spreadc--spreadintoc))
- 디스크립터: `OnChangeDescriptor<K>` / `OnEventDescriptor<K>`
- Modifier 필드 값: `ModifierField<T>` / `ModifierFieldOut<T>`
- 값 층: `Tween<T>` / `TweenData<T>` / `TweenOptions<T>` / `TweenOverride` / `TweenConstructor` / `AnimateInfo` / `AnimateFn`
- 위 키들의 모양인 `RobloxExtension`

```luau
local RobloxModule = require("@game/ReplicatedStorage/roblox_packages/quad_roblox")
local fade: RobloxModule.Tween<number> = q.Tween({ Value = 0, Time = 0.2 })
local function Button(props: { read Modifier: RobloxModule.ModifierInto<TextButton>? }): TextButton
```

**[3.4.0]** 3.3의 클래스별 이름(`FrameModifier`·`IntoFrame`·`FrameElem`)과 생성 모듈의 이름(`Declaration`·`DeclarationMapper`·
`PropTypes`·`OnChangeFn`·`OutFn`·`Field<T>`·`FieldOut<T>`)은 없어졌습니다 — 위의 클래스를 인자로 받는 이름이 그 자리입니다
(`FrameModifier` → `Modifier<Frame>`, `IntoFrame` → `ModifierInto<Frame>`, `Field<T>` → `ModifierField<T>`).

---

## 타입 검사 설정

`quad-roblox`는 Roblox 전역 타입(`Instance`/`Enum`/`TweenInfo`/`UDim2` …)을 쓰고, 생성자·Modifier·Spread의 타입은
**타입 함수**가 그 클래스 타입에서 계산합니다. 그래서 **새 솔버(Solver V2)**가 필요합니다. 저장소가 자기 코드를 검사할 때
쓰는 명령이 그대로 참고 형태입니다.

```sh
luau-lsp analyze --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<globalTypes.d.luau 경로> \
  <검사할 경로>
```

`LuauSolverV2=true`가 없으면 타입 함수가 "syntax not supported"로 죽습니다. 나머지 셋은 한도를 넉넉히 두는 것입니다 —
**[2026-10-20 실측]** 3.4.0 표면은 VS Code 확장의 기본값과 Studio의 기본값(override 없음)에서도 too complex 없이 검사됐습니다(두 킷
330파일, 생성자·디스크립터를 섞은 5730줄 모듈). 3.3의 생성 `Declaration`은 이 플래그 없이 무너졌습니다. 아주 큰 모듈에서 걸리는
한도는 [02-elem](/reference/roblox/02-elem/#qelem-class-props)의 "왜 파일 머리에서 꺼내 두는가"를 보세요.

`--definitions`는 `luau-analyze`가 아니라 **`luau-lsp`의 기능**입니다.

VS Code의 Luau Language Server 확장(`johnnymorganz.luau-lsp`)에서는 같은 값을 `.vscode/settings.json`의 `luau-lsp.fflags.enableNewSolver`와 `luau-lsp.fflags.override`로 넣고, Roblox 타입 정의는 확장이 알아서 받습니다 — 설정 예시는 [00. 설치](/getting-started/00-installation/)의 3단계에 있습니다.

---

**관련**

- [00. 설치](/getting-started/00-installation/) — 패키지 배치와 Rojo 매핑
- [백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/) — 주입 슬롯 전수와 포팅 계약
- [Quadnomicon Vol. 10 — 다중 백엔드 추상 기계](/quadnomicon/10-multi-backend-abstract-machine/)
