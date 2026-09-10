---
title: "Vol. 10 — 다중 백엔드 추상 기계"
description: "엔진 비의존 코어와 주입되는 op로 다중 렌더 백엔드를 지원하는 추상 기계 설계를 설명합니다"
---
> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-roblox/src/EngineOps.luau`, `quad-base/src/init.luau`, `quad-base/src/LifetimeHandle.luau`, `quad-base/src/NotInstalled.luau`

> [!CAUTION]
> 이 권은 프로바이더 인터페이스와 엔진 경계를 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](/getting-started/01-core-mental-model/)부터 보십시오.

---

## 1. 엔진 비의존은 설계 제약이다

Roblox용 UI 라이브러리는 대개 엔진과 반응형 코어가 뒤엉킵니다 — 세터가 곧
`inst[k] = v`이고, 생명주기가 `inst.Destroying`에 직접 걸리고, 프로퍼티 비교가
`UDim2`/`Color3` 같은 엔진 타입을 압니다. 그러면 vanilla Luau CLI에서 테스트하려면
무거운 Roblox 목이 필요하고, 다른 렌더 타깃은 아예 불가능해집니다.

`quad-base`는 반대 방향으로 못 박혀 있습니다.

> [!IMPORTANT]
> **코어 순수성**
> `quad-base/src`는 Roblox 전역(`game`, `Instance`, `task` …)을 하나도 참조하지
> 않고 Roblox 타입도 쓰지 않습니다. 검증 가능한 진술은 이것입니다 — *호출*이 없습니다.
> ("Instance"라는 **단어**는 에러 메시지 문자열과 주석에 나옵니다. 사용자에게 그
> 개념을 말해야 하는 자리이기 때문이고, 코드가 그 타입을 만지는 것과는 다릅니다.)

엔진에 실제로 닿는 모든 조작은 **런타임에 주입되는 op**로 들어옵니다.

---

## 2. 주입되는 엔진 op

주입 op 목록의 단일 소스는 `quad-roblox/src/EngineOps.luau`의 헤더입니다(그 파일이
Roblox 백엔드의 구현이기도 합니다). 여기서는 개수를 세지 않고 **묶음과 시그니처의
모양**만 봅니다.

**물리 트리 계층 (`native*`)** — 요소를 **배열로** 받고, 0-based 절대 `offset`을
같이 받습니다.

```
nativeInsert (target, offset, elements)
nativeExtract(target, offset, elements, newElements?)   -- 살린 채 트리에서 빼기
nativeRemove (target, offset, elements, newElements?)   -- 파괴
nativeMove   (target, fromOffset, elements, toOffset)
nativeSwap   (target, offsetA, elementsA, offsetB, elementsB)
nativeDispose(element)
```

**판정·훅 op** — 조작이 아니라 질문이라 조합으로 만들 수 없습니다.
`isInst(value)` / `onDestroying(inst, fn)` / `nativeFindChild(inst, key)` /
`nativeClaim(inst)`.

**Tag·Attr op** — `addTag(inst, {string})` / `removeTag(inst, {string})` /
`setAttr(inst, name, v)`. 태그가 배열인 것이 계약입니다(웹 백엔드는 `className`을 한
번에 다시 씁니다). Roblox에는 배치 API가 없어서 그 루프가 백엔드 쪽에 있습니다.

**시간 op** — `setTimeout(func, delay) -> Timeout` / `clearTimeout(timeout)`.
Roblox 배선은 `task.delay`/`task.cancel`인데 **인자 순서가 반대**라 그 자리에서
뒤집습니다.

### 엔진마다 같은 op가 다른 뜻이 된다

Roblox에서는 자식 순서가 물리적 성질이 아닙니다. 그래서 이 백엔드는 `offset`을 무시하고
요소 배열만 쓰며, `nativeMove`와 `nativeSwap`은 **의도적인 no-op 오버라이드**입니다.
detach 후 재부착으로 "순서를 바꾸는" 조합 구현을 두면 `.Parent` 쓰기가 두 번 일어나
`AncestryChanged`가 다시 발화하고 깜빡임이 생기는데, Roblox에서 그 대가로 얻는
물리적 변화는 없습니다. DOM 백엔드에서는 같은 두 op가 실제 일을 합니다.

빠진 것도 봐 둘 만합니다. `nativeDiff`도, `nativeReconcile`도, `nativeUpdateTree`도
없습니다. 하강 diff, 부분합 계산, 우선순위 스캔, 반응형 무효화는 전부 `quad-base`
안에서만 돕니다.

---

## 3. 생명주기 프리미티브 넷

`quad-base`는 이 넷의 **자리**만 소유하고, 기본값으로는 명확히 에러를 내는 안내
스텁을 심어 둡니다. 백엔드가 그것을 덮어씁니다.

```
bindLifetime(inst, value)   -- value의 수명을 inst의 바인드 수명에 묶는다
unbindLifetime(value)       -- 대칭 해제. cleanup을 부르지 않고, 내부 구독을 떼지 않는다
canBound(value): boolean    -- 지금 묶을 수 있는가(= 아직 안 묶여 있는가)
canExecute(value): boolean  -- 지금 실행해도 되는가(= 살아 있는 바인딩이 있는가)
```

`canBound`와 `canExecute`는 비공개 술어 하나(`isBoundAlive`)를 공유하는 얇은
진입점이고, 그 술어 자체는 **백엔드 내부에만 있습니다** — 계약 표면이 아닙니다.

> [!WARNING]
> `canBound(nil)`은 **참**입니다. `isBoundAlive(nil)`이 거짓이므로 그 부정이 참이 됩니다.
> `nil` 거부는 술어가 아니라 `bindLifetime`의 자기 게이트가 합니다
> (`bindLifetime: value must not be nil`). 술어를 "인자 검증"으로 쓰지 말 것.

`bindLifetime`은 알려진 타입이면 뒤처리를 더 합니다(`Observer`는 밀린 emit을 한 번
따라잡고, `Effect`는 `onDestroying`에 걸립니다). 어떤 알려진 타입도 아니면 — 평범한
테이블이나 클로저면 — **순수 GC 릴레이션만** 합니다. 디스패치 체인 리스트가 그 계약의
첫 소비자입니다(제8권 §3).

---

## 4. `UseProvider` — 모듈당 1슬롯, 함수 신원 락

모듈 하나에 백엔드가 둘 붙으면 조용히 상태가 깨집니다. 같은 패키지의 **사본 둘**이
붙는 경우도 마찬가지입니다. 예전에는 `_initializedBy = "roblox"` 같은 문자열 마커로
막았는데, 문자열은 사본 둘을 구분하지 못해서 그 상황을 그냥 통과시켰습니다.

지금은 프로바이더 **함수 신원**이 락입니다(`quad-base/src/init.luau` 발췌).

```luau
function module.UseProvider(self, providerFn)
	local current = providerRelate:GetStrong(self, "provider")
	if current == providerFn then
		return self :: any -- 같은 프로바이더 재호출 — 멱등 no-op
	end
	if current ~= nil then
		Err.errorBeforeNearest(
			"UseProvider: this Quad module already has a provider — a module cannot serve two backends",
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	local extension = providerFn(self)
	mergeExtension(self, extension)
	providerRelate:SetStrong(self, "provider", providerFn)
	return self :: any
end
```

읽을 점 셋:

1. **멱등.** 여러 모듈이 같은 프로바이더를 require하면 require 캐시가 같은 함수
   신원을 주므로 자연히 통과합니다.
2. **다른 신원이면 즉시 error.** 점유자를 이름으로 짚지는 않습니다 — 신원 락에는
   이름이 없고, 소스 경로를 메시지에 싣는 것은 이 프로젝트의 에러 규약이 금지합니다.
   메시지는 계약만 말합니다.
3. **마킹은 성공한 *뒤*에 섭니다.** 실행 전에 슬롯을 잡아 두면 `providerFn`이 도중에
   던졌을 때 슬롯만 점유된 채 확장은 영영 병합되지 않는 좀비가 되고, 재시도는
   "같은 프로바이더"로 판정돼 멱등 no-op에 삼켜집니다.

락이 백엔드가 아니라 base에 사는 이유도 같습니다 — 프로바이더 작성자가 가드를 빠뜨리는
실수를 구조적으로 막습니다. 다른 백엔드로 테스트하려면 `Quad.New()`로 격리된 모듈
사본을 만듭니다.

---

## 5. 경계는 어디인가

백엔드는 "시키는 대로 op만 실행하는 얇은 다리"가 아닙니다. **핸들러를 실제로
소유합니다.** `quad-roblox`는 `Property`(그 안의 `Tween` 분기 포함), `Event`(리플렉션
기반 자동 판별), `InstanceChild`, `OnChange`, `InstanceShorthand`를 등록하고,
`Tween` 값 타입과 그 override 정책도 백엔드 것입니다(어휘 자체가 엔진 것이므로).

`quad-base`가 지키는 것은 그 핸들러들이 **언제 어떤 순서로 불리는지**입니다.

| 관심사 | `quad-base` | 프로바이더(예: `quad-roblox`) |
|---|---|---|
| 반응형 무효화 | revision, epoch 맵, `Blocker` | — |
| 부분합 부기 | `Slot`, 길이·오프셋 | — |
| 디스패치 골격 | `chains`, 우선순위 스캔, 하강 diff | 자기 핸들러 등록(`Property`/`Event`/…) |
| 값·디스크립터 | `State`/`Source`/`Slot`/`Ref`/`Tag`/`Attr`/`Modifier` | `Tween`, `Animate`, `OnChange` |
| 물리 노드 | 불투명한 값(무엇인지 모른다) | Roblox `Instance`(또는 DOM 요소) |
| 정리 | weak 키 릴레이션 + gchold 앵커 | `Destroy` / 시그널 해제 |
| 에러 진단 | 브랜드 이름 조회, `SURFACE` 워커 | 클래스 리플렉션, 프로퍼티 검증 |

`Tag`/`Attr`처럼 **알고리즘은 엔진 무관이고 효과만 주입받는** 것들은 base에 있되
최하위 밴드에 등록돼, 백엔드가 원하면 평범한 우선순위로 이길 수 있습니다(제8권 §5).
