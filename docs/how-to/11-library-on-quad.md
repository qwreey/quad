---
title: "11. quad 위에 라이브러리 얹기"
description: "UI 킷처럼 quad에 기대는 라이브러리가 설정 모듈 하나로 quad를 받고, 소비자 앱과 같은 quad 인스턴스를 쓰는지 확인하고, 타입을 다시 내보내고, 에러가 소비자의 줄을 짚게 하는 법을 다룹니다"
---
# [실전 레시피] 11. quad 위에 라이브러리 얹기

> **대상 독자**: 컴포넌트 묶음(UI 킷)이나 위젯 라이브러리를 만들어 다른 프로젝트가 가져다 쓰게 하려는 개발자
> **다루는 개념**: 라이브러리의 설정 모듈, `UseProvider`의 멱등성, 설치 사본이 둘일 때 생기는 일과 `q.moduleIdentity`로 확인하기, 타입 다시 내보내기, `q.errorNamespace`로 공개 함수 태깅

[시작하기 01](../getting-started/01-setup.md)은 **게임**이 quad를 조립하는 설정 모듈을 다룹니다. 이 문서는 그 게임이 가져다 쓰는 **라이브러리** 쪽입니다. 본보기는 이 저장소의 소비자 킷 둘(`quad-roblox-devui`, `quad-roblox-material`)이 실제로 택한 모양입니다.

---

## 1. 해결하려는 문제

라이브러리도 quad를 require해야 합니다. 그런데 게임과 달리 세 가지를 모릅니다.

1. **소비자의 `q`와 같은 것을 쓰고 있는가** — 소비자는 자기 `Source`를 라이브러리 컴포넌트에 넘기고, 라이브러리가 돌려준 Frame을 자기 `Slot`에 넣습니다. 둘이 다른 quad 인스턴스면 이 값들이 섞이지 않습니다.
2. **quad가 어디 설치될지** — 라이브러리를 짤 때는 소비자의 패키지 경로를 알 수 없습니다.
3. **잘못 설치됐을 때 소비자가 무엇을 보게 되는가** — 사본이 둘이면 원인과 무관한 에러가 나기 쉽습니다.

---

## 2. 라이브러리의 설정 모듈 — require 세 줄을 한 파일에

라이브러리 안에도 게임과 **같은 모양의 설정 모듈**을 하나 둡니다. quad가 어디 있는지 아는 파일은 이것 하나뿐이고, 라이브러리의 나머지 파일은 전부 이 모듈을 상대 경로로 봅니다.

```luau
--!strict
-- 라이브러리의 설정 모듈: MyKit/src/Quad — quad가 어디 있는지 아는 유일한 파일
-- 소비자는 자기 프로젝트에 설치된 패키지 경로로 이 세 줄만 바꾼다
const Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
const RobloxModule = require("@game/ReplicatedStorage/roblox_packages/quad_roblox")
const QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types")

-- 라이브러리가 쓰는 quad 타입을 여기서 다시 내보낸다(§4)
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type Slot<T> = QuadTypes.Slot<T>
export type Ref<T> = QuadTypes.Ref<T>
export type Effect = QuadTypes.Effect
export type Context = QuadTypes.Context
export type Provider<T> = QuadTypes.Provider<T>
export type Modifier<C> = RobloxModule.Modifier<C>
export type ModifierInto<C> = RobloxModule.ModifierInto<C>
export type Props<C> = RobloxModule.Props<C>

return Quad:UseProvider(RobloxModule.QuadRoblox)
```

```luau
-- 라이브러리의 다른 파일: MyKit/src/Button
const q = require("./Quad") -- 경로를 아는 건 설정 모듈뿐이다
```

**라이브러리가 `UseProvider`를 또 걸어도 되는 이유.** `quad_base`를 require하면 그 설치 사본의 **이미 만들어진 모듈 인스턴스**가 옵니다([Quad 모듈](../reference/core/01-quad-module.md)). 그리고 [`UseProvider`](../reference/core/01-quad-module.md#quseproviderproviderfn)는 같은 프로바이더 함수로 다시 부르면 아무것도 하지 않고 같은 모듈을 돌려줍니다. 그래서 게임의 설정 모듈이 먼저 돌았든 라이브러리의 것이 먼저 돌았든, 같은 사본을 가리키는 한 둘이 돌려주는 `q`는 **같은 값**입니다([2026-10-20 mock 실측] — 두 번째 `UseProvider`의 결과가 첫 번째와 `==`). 라이브러리는 소비자가 설정을 끝냈는지 몰라도 되고, 소비자는 라이브러리의 설정 모듈을 자기 `q`로 그대로 써도 됩니다(devui의 README가 그렇게 안내합니다).

**경로를 바깥에 맡기는 법.** [2026-10-20 기준] 두 킷은 아직 패키지로 게시되지 않아, 이 저장소 안에서는 작업 공간의 사본을 가리키고 소비자 프로젝트에서는 **설정 모듈의 세 줄만** 자기 패키지 경로로 바꾸라고 안내합니다. 경로를 아는 자리가 한 파일이라 바꿀 곳도 한 곳입니다. 라이브러리의 다른 파일에서 `quad_base`를 직접 require하지 마세요 — 그 줄이 하나라도 있으면 소비자가 바꿀 곳이 늘고, 하나를 빠뜨리는 순간 아래 §3의 "사본 둘" 상황이 라이브러리 안에서 생깁니다.

---

## 3. 소비자와 같은 quad를 쓰는가

설정 모듈의 경로가 소비자의 설치본과 **다른 사본**을 가리키면 무슨 일이 나는지는 어느 사본이 갈렸느냐에 따라 다릅니다.

- **`quad_base`는 하나인데 `quad_roblox` 사본이 둘** — 같은 모듈에 다른 프로바이더 함수로 `UseProvider`를 부르게 되므로, 나중에 부른 쪽이 그 자리에서 던집니다. 시끄러워서 차라리 낫습니다.

  ```
  Quad0213 UseProvider: this Quad module already has a provider - a module cannot serve two backends
  ```

- **`quad_base` 사본이 둘** — 모듈 인스턴스가 둘 생기고, 각자 자기 백엔드를 설치하므로 설치는 조용히 성공합니다. 문제는 값을 넘길 때 납니다. 브랜드 집합이 사본마다 따로라 한쪽이 만든 `State`를 다른 쪽은 `State`로 알아보지 못하고, 원인과 무관해 보이는 `Quad0076`·`Quad0240`·`Quad0151`·`Quad0198`류가 나거나, 프로퍼티 자리에서는 그 테이블이 날값으로 엔진까지 갑니다([Quad 모듈 레퍼런스](../reference/core/01-quad-module.md#qnewmodule)의 "인스턴스끼리 값을 섞지 마세요"). 같은 사본 안에서 `Quad.NewModule()`로 만든 인스턴스끼리라면 `Quad0106 Slot: this value was made by another quad module instance …`처럼 원인을 바로 말해 주지만([2026-10-20 mock 실측]), 사본이 다르면 그 가드까지 오지도 못합니다.

그래서 라이브러리 쪽에서 **같은 인스턴스인지 물어볼 길**을 하나 열어 두면 소비자가 원인을 바로 압니다. [`q.moduleIdentity`](../reference/core/01-quad-module.md#qmoduleidentity)는 모듈 인스턴스마다 하나씩 있는 빈 테이블이고, 계약은 "인스턴스마다 하나, 서로 다름"뿐입니다 — 사본이 다르면 인스턴스도 다르므로 이것 하나로 둘 다 가려집니다.

```luau
--!strict
-- 라이브러리 진입점: MyKit/src/init
const q = require("./Quad")

local MyKit = {}

-- 소비자가 자기 설정 모듈의 q를 한 번 넘겨 확인한다
function MyKit.checkQuad(appQ: { read moduleIdentity: {} })
    if appQ.moduleIdentity ~= q.moduleIdentity then
        error("MyKit.checkQuad: the app and MyKit run on different quad instances - point MyKit's Quad module at the app's quad_base install", 2)
    end
end

return MyKit
```

```luau
-- 소비자의 진입점 — 설정이 끝난 뒤 한 번
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const MyKit = require("@game/ReplicatedStorage/Packages/MyKit")
MyKit.checkQuad(q)
```

<!-- mock 실측 2026-10-20: 같은 사본에 같은 프로바이더로 UseProvider를 두 번 부르면 같은 q(==)이고 moduleIdentity도 같음; Quad.NewModule()의 moduleIdentity는 다름; NewModule의 Slot을 다른 인스턴스의 q.Elem 자리에 놓으면 Quad0106 -->

[2026-10-20 기준] 두 킷에는 이런 확인 함수가 없습니다 — 위는 레시피입니다. 사본이 둘인 상황을 이 저장소에서 직접 만들어 보지는 않았고, "다른 사본이면 `moduleIdentity`도 다르다"는 위 계약에서 나온 결론입니다.

---

## 4. 타입 다시 내보내기

설정 모듈이 `export type` 줄로 quad 타입을 다시 내보내는 것은 게임과 같은 이유입니다 — `const q = require("./Quad")` 한 줄로 값(`q.Source(…)`)과 타입(`q.State<number>`)이 같은 이름 아래 옵니다. 라이브러리에서는 이유가 하나 더 있습니다. 라이브러리가 공개하는 props 타입(`read Value: q.State<number>`)이 이 이름을 쓰므로, 소비자도 같은 모듈에서 같은 이름을 얻는 편이 헷갈리지 않습니다.

- **값의 타입**(`State`·`Source`·`Slot`·`Ref`·`Effect`·`Context` 등)은 `quad_types`에서, **클래스를 인자로 받는 타입**(`Modifier<C>`·`ModifierInto<C>`·`Spread<C>`·`SpreadInto<C>`·`Props<C>`·`ElemCtor<C>` 등)은 `quad_roblox` 패키지 루트에서 옵니다(전체 목록은 [레퍼런스: 설치](../reference/roblox/01-install.md)). 두 킷의 `src/Quad.luau`도 이 두 문에서 받아 다시 내보냅니다.
- **quad 타입의 문은 하나로** — devui는 quad 타입을 킷의 루트(`init`)에서 다시 내보내지 않고, 소비자가 킷의 설정 모듈(`require(<키트>/src/Quad)`)에서 얻게 합니다. 킷 자기 타입(`Devui.Style` 등)만 루트에서 나갑니다. 같은 타입이 두 문으로 나가면 어느 쪽을 써야 하는지 소비자가 매번 고민하게 됩니다.
- **제네릭 컴포넌트**(`Combo<T>`처럼 값의 타입을 제네릭으로 받는 것)를 만든다면 State props를 받는 법에 함정이 있습니다 — [실전 레시피 01](./01-component-conventions.md#제네릭-컴포넌트의-타입--라이브러리-저자를-위한-레시피--strict)의 "제네릭 컴포넌트의 타입" 절을 보세요. 거기서 설정 모듈에 한 줄(`StateMarker<T>`)을 더 내보내라고 합니다.

---

## 5. 에러가 소비자의 줄을 짚게 — `q.errorNamespace`

quad 에러는 스택을 훑어 "quad 기계"와 "사용자 코드"의 경계를 찾고 **사용자의 줄**을 짚습니다. 경계는 공개 표면 함수에 붙여 둔 태그로 찾습니다([Quadnomicon 11](../quadnomicon/11-static-grepability-and-error-architecture.md)). 라이브러리가 아무것도 하지 않으면 라이브러리의 함수는 "사용자 코드"로 보이므로, 라이브러리 안에서 부른 `q.Elem`이 던진 디스패치 에러 같은 것은 **라이브러리 소스의 줄**을 짚습니다. 소비자는 자기가 무엇을 잘못 넘겼는지 찾으러 라이브러리 소스를 열어야 합니다.

원칙은 둘입니다.

1. **quad의 네임스페이스를 받아 쓴다.** 태그는 [`q.errorNamespace`](../reference/core/01-quad-module.md#qerrornamespace) 하나에 붙입니다 — 라이브러리가 자기 `quad_error` 사본으로 새 네임스페이스를 만들면 태그 맵이 갈려 경계 탐색이 끊깁니다.
2. **공개 함수를 표면으로 태그한다.** 소비자가 부르는 함수들을 `setFuncLevel`로 한 번 등록합니다. 층 번호는 `quad_types`의 `ERROR_LEVEL_SURFACE`(값 `1`)입니다 — quad-roblox도 자기 프로바이더 함수를 이렇게 등록합니다. 함수를 손으로 나열하지 말고 **다 지은 내보내기 테이블을 한 번 순회**하세요 — 새로 더한 함수가 빠지는 일이 없습니다. 내보내기 순회 뒤에 생기는 함수(생성자가 만들어 돌려주는 객체의 메소드)는 그 생성자가 만들 때 태깅합니다.

```luau
-- MyKit/src/init — 내보내기 테이블을 다 지은 뒤 한 번
-- quad_types의 ERROR_LEVEL_SURFACE와 같은 값. quad 경로를 아는 파일(§2의 설정 모듈)을 늘리지 않으려고
-- 여기서는 값을 옮겨 적고, 라이브러리 테스트가 둘이 같은지 고정한다
local SURFACE = 1
-- MyKitError.fail: 라이브러리가 자기 에러를 던지는 헬퍼(아래 "자기 에러" 항목) — 이 순회에 걸리지 않게 뺀다
local seen: { [any]: boolean } = {}
local function tagSurface(t: { [any]: any })
    seen[t] = true
    for _, v in t do
        if type(v) == "function" then
            if v ~= MyKitError.fail then -- 던지는 헬퍼는 빼기(아래 주의)
                q.errorNamespace.setFuncLevel(SURFACE, v)
            end
        elseif type(v) == "table" and getmetatable(v) == nil and not seen[v] then -- 모듈 테이블만, 한 번씩
            tagSurface(v)
        end
    end
end
tagSurface(MyKit)
```

태그를 붙이면 "가장 바깥 표면의 호출자"를 짚는 에러가 라이브러리 함수를 부른 **소비자의 줄**로 올라갑니다. 예를 들어 라이브러리 함수가 받은 자식을 `q.Elem "Frame" { child }`에 넣는데 그 자식이 이미 파괴된 Instance였다면, 태그 전에는 `Quad0219`가 라이브러리 안의 `q.Elem` 줄을, 태그 뒤에는 소비자가 `MyKit.Wrap(…)`을 부른 줄을 짚습니다 — [2026-10-20 mock 실측].

알아 둘 한계가 있습니다([Quadnomicon 11](../quadnomicon/11-static-grepability-and-error-architecture.md)의 "보장되지 않는 것" 절).

- **모든 에러가 바깥으로 올라가지는 않습니다.** "가장 가까운 표면의 호출자"를 짚는 에러(인자 검증, 콜백 안에서 부른 표면)는 여전히 라이브러리 안의 줄을 짚습니다 — 그 자리를 짚어야 맞는 에러들입니다.
- **테이블 필드로 불리는 함수만 태그할 수 있습니다.** 로컬 함수를 직접 부르면 최적화 단계에서 인라인돼 태그가 스택에서 사라집니다. 공개 함수는 `MyKit.Button(…)`처럼 테이블 필드로 불리니 이 조건에 맞습니다.
- 라이브러리가 **자기 에러**를 던질 때도 같은 네임스페이스의 `errorBefore`/`errorBeforeNearest`(층 번호는 같은 `ERROR_LEVEL_SURFACE`)를 쓰면 소비자의 줄을 짚습니다 — 검사가 공개 함수 몇 단계 안쪽에 있어도 `errorBeforeNearest`는 그 공개 함수를 부른 줄을 짚으므로 `error(msg, n)`의 레벨을 손으로 셀 필요가 없습니다(§3의 `checkQuad`처럼 공개 함수 자신이 바로 던지는 한 단계짜리 검사는 `error(msg, 2)`로도 같습니다). 던지는 헬퍼를 따로 두면 그 헬퍼는 태깅하지 마세요 — 태깅하면 그것이 "가장 가까운 표면"이 되어 blame이 헬퍼를 부른 라이브러리 줄로 갑니다([레퍼런스: 백엔드 프로바이더 계약](../reference/extend/01-backend-provider-contract.md)). 시그니처는 [`q.errorNamespace`](../reference/core/01-quad-module.md#qerrornamespace), 넷의 차이는 Quadnomicon 11의 표에 있습니다. 메시지는 quad와 같은 모양(`주어: 이유`)으로 쓰면 소비자가 읽기 쉽습니다 — [10. 부록](./10-debugging-and-troubleshooting.md).

---

## 6. 라이브러리가 하지 말 것

- **모듈을 require하는 순간 Instance를 만들어 모듈 변수에 쥐지 마세요.** 기본 오버레이 레이어처럼 "아무것도 안 넘겨도 쓰이는" 값이 대표적인데, 처음 붙은 화면과 함께 죽습니다. 처음 달라고 할 때 만들고, 줄 때마다 살아 있는지 보는 모양은 [실전 레시피 09 §6](./09-overlays-modal-toast.md#6-화면을-다시-지어도-죽지-않는-기본-레이어)에 있습니다.
- **`q.debug`를 라이브러리 코드에서 켜지 마세요.** 소비자와 같은 모듈 인스턴스를 쓰므로 그 필드는 소비자의 것이기도 합니다 — 라이브러리가 켜면 소비자 앱 전체의 진단 줄이 켜집니다. 라이브러리의 테스트에서만 켜세요(두 킷의 spec이 그렇게 합니다).
- **라이브러리 안에서 `Quad.NewModule()`로 자기 인스턴스를 만들지 마세요.** 그 인스턴스의 값은 소비자의 `q`와 섞이지 않습니다(§3). 격리된 인스턴스는 테스트 하네스의 몫입니다.

---

## 7. 체크리스트

- [ ] quad를 require하는 줄이 라이브러리의 설정 모듈 한 파일에만 있고, 나머지 파일은 그 모듈을 상대 경로로 보는가?
- [ ] 설정 모듈이 게임의 설정 모듈과 같은 모양(`Quad:UseProvider(QuadRoblox)`)이라, 같은 사본이면 소비자와 같은 `q`를 받는가?
- [ ] 소비자가 같은 인스턴스인지 확인할 길(`moduleIdentity` 비교)이 있는가?
- [ ] 쓰는 quad 타입을 설정 모듈에서 다시 내보내고, quad 타입이 나가는 문이 하나인가?
- [ ] 공개 함수를 `q.errorNamespace`로 표면 태깅했는가?
- [ ] require 시점에 Instance를 만들지 않고, `q.debug`를 켜지 않으며, 자기 모듈 인스턴스를 따로 만들지 않는가?

---

## 이해 점검

```quiz
# 라이브러리도 UseProvider를 거는 이유

게임의 설정 모듈이 이미 `Quad:UseProvider(QuadRoblox)`를 불렀는데, 라이브러리의 설정 모듈이 같은 줄을 또 불러도 되는 이유는 무엇인가요?

- [x] 같은 프로바이더 함수로 다시 부르면 아무것도 하지 않고 같은 모듈을 돌려주므로, 같은 사본이면 둘의 `q`는 같은 값이기 때문입니다
- [ ] 두 번째 호출이 첫 번째 설치를 덮어써서 라이브러리 전용 quad가 생기기 때문입니다
- [ ] quad가 라이브러리마다 모듈 인스턴스를 따로 만들어 주기 때문입니다

`UseProvider`는 프로바이더 함수의 identity로 잠깁니다. 같은 함수면 멱등 no-op이고, 다른 함수(다른 사본·버전)면 `Quad0213`으로 던집니다.
```

```quiz
# 사본이 둘인지 확인하기

라이브러리가 소비자 앱과 같은 quad 인스턴스 위에서 도는지 확인하려면 무엇을 비교하나요?

- [x] 양쪽 `q`의 `moduleIdentity`
- [ ] 양쪽 `q`의 `Version` 문자열
- [ ] `q.debug` 값

`moduleIdentity`는 인스턴스마다 하나이고 서로 다릅니다. 버전 문자열은 같은 버전의 사본이 둘이어도 같으므로 사본이 갈린 것을 잡지 못합니다.
```

---

## 관련

- [시작하기 01. 프레임워크 설정하기](../getting-started/01-setup.md) — 게임의 설정 모듈, 문자열 `require`
- [레퍼런스: Quad 모듈](../reference/core/01-quad-module.md) — `UseProvider`의 멱등성, `moduleIdentity`, `errorNamespace`, 인스턴스끼리 값을 섞을 때
- [레퍼런스: 설치](../reference/roblox/01-install.md) — `quad_roblox` 패키지 루트가 내보내는 타입
- [실전 레시피 01. 컴포넌트 경계 규약과 스타일 합성](./01-component-conventions.md) — 라이브러리 컴포넌트의 props 규약, 제네릭 컴포넌트의 타입
- [실전 레시피 09. 떠 있는 것 열고 닫기](./09-overlays-modal-toast.md) — 죽지 않는 기본 레이어, 바깥 클릭·Escape
- [Quadnomicon 11](../quadnomicon/11-static-grepability-and-error-architecture.md) — 표면 태그와 blame의 원리
