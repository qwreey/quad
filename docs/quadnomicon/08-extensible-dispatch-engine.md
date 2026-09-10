---
title: "Vol. 8 — 확장 가능한 디스패치 엔진과 우선순위 파이프라인"
description: "핸들러 레지스트리로 확장 가능한 디스패치 엔진과 우선순위 파이프라인을 설명합니다"
---
# [Quadnomicon Vol. 8] 확장 가능한 디스패치 엔진과 우선순위 파이프라인

> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-base/src/Dispatch/init.luau`, `quad-base/src/Dispatch/Handler.luau`, `quad-base/src/Dispatch/StoreBind.luau`, `quad-types/src/init.luau`

> [!CAUTION]
> 이 권은 프로퍼티·자식 디스패치 엔진 내부를 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](../getting-started/01-first-screen.md)부터 보십시오.

---

## 1. 중앙 디스패처 하나가 전부를 아는 구조

선언형 UI 라이브러리에서 props를 처리하는 가장 흔한 모양은 중앙 함수 하나의
`if`/`elseif` 폭포입니다. quad v1도 그랬습니다 — `ProcessQuadProperty` 하나가 숫자 키,
`__type` 문자열 태그가 붙은 테이블, `"Event::"` 접두 문자열을 런타임 타입 스니핑으로
가르는 것이 사실상 전체 키 핸들러였습니다.

```
의사코드 — 흔한 모양(quad는 이 길을 가지 않는다)

  if type(k) == "number"  then mountChild(inst, k, v)
  elseif isState(v)       then bindState(inst, k, v)
  elseif isTag(v)         then bindTag(inst, v)
  else                         inst[k] = v
```

문제는 확장이 아니라 **소유권**입니다. 새 개념(`Slot`, `Modifier`, `Attr`, 백엔드가
따로 정의하는 프로퍼티 규칙)을 하나 더할 때마다 이 중앙 함수를 고쳐야 하고, 그
함수는 quad-base에 있으므로 **백엔드가 자기 규칙을 넣을 자리가 없습니다**. v2가 pluggable
바인드 시스템을 원한 직접적인 이유가 이것입니다.

---

## 2. 핸들러 계약과 우선순위 레지스트리

중앙 분기 대신, quad는 모듈 인스턴스마다 하나씩 **핸들러 레지스트리**를 들고 있습니다.
계약은 `quad-types`가 소유하는 타입 하나가 전부입니다.

```luau
export type Handler = {
	name: string?,                                     -- 진단 표시용(선택)
	keyType: ("number" | "string")?,                   -- 이 핸들러가 볼 수 있는 키 타입(선택)
	isHandlable: (inst: any, key: any, value: any) -> boolean,
	priority: number,
	process: (inst: any, key: any, value: any, index: number)
		-> (nextValue: any?, retracting: boolean) -> (),
}
```

읽을 점이 셋 있습니다.

- **`isHandlable`은 `(inst, key, value)` 셋을 다 봅니다.** 순수하고 빨라야 하며 부수
  효과가 없어야 합니다 — 값 검증은 선택된 *뒤* `process` 안에서 합니다.
- **`process`는 무언가를 반환합니다.** 반환값은 "이 호출이 한 일을 정확히 되돌리는"
  retractor 클로저입니다. 별도의 `retract` 메소드는 없습니다. `nil`을 반환하면 계약 위반이라
  즉시 error(`… returned no retractor at key …, index … — return Void when there is
  nothing to undo`) — 되돌릴 게 없으면 공유 no-op인 `Void`를 반환하면 됩니다.
- **retractor는 두 인자를 받습니다.** `retracting`이 참이면 단순 철거(이 자리는 다시
  처리되지 않습니다), 거짓이면 같은 핸들러의 재처리가 바로 뒤따릅니다. `nil`을 값으로
  받는 핸들러가 "철거의 nil"과 "값인 nil"을 이 플래그로 구별합니다.

### 2.1 스캔은 평평한 목록 하나가 아니다

`addHandler`는 레지스트리를 우선순위 내림차순으로 정렬해 두고, 동시에 `keyType`별
버킷 셋(`number`/`string`/`other`)을 다시 만듭니다. 각 버킷은 그 키 타입을 선언한
핸들러 ∪ 선언하지 않은 핸들러이며, 순서는 전체 목록과 같습니다.

조회는 `type(k)`에 해당하는 버킷만 훑습니다. 계기는 실측이었습니다 — 문자열 프로퍼티
10개짜리 `D.Frame` 하나가 핸들러 22개에 150번을 물었는데 그중 12개는 애초에 숫자
키만 매치할 수 있었습니다. 판정 자체는 여전히 `isHandlable`이 합니다(`keyType`은 스캔
범위만 좁힙니다).

**먼저 승낙한 하나가 그 자리를 가져갑니다.** 동률에 대한 tiebreak 규칙은 강제하지
않습니다 — 대신 밴드 상수를 두어 애초에 동률이 잘 안 나게 하고, `module.debug`일 때만
동률을 출력합니다.

### 2.2 밴드의 실제 배치

밴드 값은 `HIGH = 1000`, `NORMAL = 0`, `LOW = -1000`, `FALLBACK = -1000000`이고,
`HIGH + 1`처럼 오프셋을 얹을 수 있는 열린 숫자 공간입니다.

| 밴드 | 실제로 앉아 있는 것 |
|---|---|
| `HIGH` | 디스패치 골격 자체 — `StoreBind`, `NoneHandler`/`NilHandler`, `Processed*` 말단(Modifier·PreRef·PostRef), `SlotHandler`, `Ref`/`Observer`/`Effect` 잎 핸들러 |
| `NORMAL + 1` | `InstanceShorthand`(`UICorner` 등 특수 키) |
| `NORMAL` | 백엔드의 실제 일 — `Property`, `Event`, `InstanceChild`, `OnChange` |
| `FALLBACK` | base가 알고리즘을 소유하고 효과만 주입받는 것 — `TagFallbackHandler`, `AttrKeyFallbackHandler`, `AttrGroupFallbackHandler`(§5); 그리고 동적 경로로 온 `Ref`/`Observer`/`Effect`를 즉시 거부하는 가드 셋 |

**base 소속이라고 전부 위에 오는 게 아닙니다.** `StoreBind`는 프로퍼티 세터보다 먼저
매치돼야 반응형 값이 언랩되므로 `HIGH`고, `Tag`/`Attr`는 백엔드가 통째로 다르게
처리할 수 있어야 하므로 `FALLBACK`입니다.

목록에 **`Modifier` 핸들러가 없다는 점**도 봐 둘 만합니다. `Modifier`는 스캔에 들어오지
않습니다 — `drive`의 첫 pre-pass인 `flatten`이 배열 부분의 Modifier 슬롯을 그 자리에서
소진해 필드를 해시 부분으로 합치고, 빈 슬롯에는 `ProcessedModifier` 센티널을 남깁니다.
스캔이 보는 것은 그 센티널이고, 그 핸들러가 하는 일은 "이 자리는 길이 0"이라고
부기에 등록하는 것뿐입니다. `PreRef`/`PostRef`도 같은 모양입니다.

---

## 3. `chains[inst][k]` — 두 필드짜리 슬롯의 수직 스택

한 자리(`inst`의 키 `k`)에서 여러 겹이 동시에 살아 있을 수 있습니다. `State`가 `Tween`을
내놓고 그 `Tween`을 Property 핸들러가 먹는 식입니다. 그래서 자리마다 **인덱스 배열**이
하나 있고, 각 칸은 필드 둘뿐입니다.

```
(Frame, "Size")의 체인:
  index 1: { handler = StoreBind, retractor = <옵저버를 unbind하는 클로저> }
  index 2: { handler = Property,  retractor = <트윈/값을 되돌리는 클로저> }
```

깊이는 재귀로 만듭니다. `StoreBind.process`는 구독을 걸고, 값이 올 때마다 실제 값을
`Dispatch.process(inst, k, realv, index + 1)`로 **아래 칸에** 넘깁니다. `NoneHandler`도
같은 모양으로 `nil`을 한 칸 아래로 넘깁니다. 엔진에는 "State 안의 Tween" 같은 조합
분기가 하나도 없고, `State<State<Tween>>`도 칸이 하나 더 생길 뿐입니다.

`realv`가 다시 `State`면 `index + 1`의 별도 칸에서 같은 `StoreBind`가 잡으므로 신원
충돌이 없고, 반응형이 아니면 `isHandlable`을 실패해 다음 우선순위로 내려가므로 무한
재귀도 없습니다.

> [!NOTE]
> 이 구조가 **할당을 없애지는 않습니다.** `process`는 호출마다 새 retractor 클로저를
> 반환합니다. 얻는 것은 "엔진 안에 조합 분기가 없다"이지 "할당 0"이 아닙니다.

`chains` 자체는 weak 릴레이션입니다. 리스트를 강하게 잡으면 retractor가 캡처한 `inst`를
weak 키가 되참조하게 되어 절대 회수되지 않습니다(제7권 §5) — 실제 앵커는
`bindLifetime(inst, list)`입니다.

---

## 4. 하강 diff — (A)와 (B)

값이 새로 오면 엔진은 그 칸에 이미 앉아 있던 핸들러와 이번에 매치된 핸들러를
비교합니다.

```
              Dispatch.process(inst, k, v, index)
                                │
                   list[index].handler == 매치된 핸들러?
                 ┌──────────────┴──────────────┐
                 ▼                             ▼
        (A) 같은 핸들러                (B) 다른 핸들러(또는 빈 칸)
                 │                             │
  1. retractor(v, false)          1. 이 칸부터 꼬리까지 철거(꼬리부터)
  2. retractor := NOOP            2. { handler, NOOP }로 자리 표시
  3. h.process(...) 로 교체        3. h.process(...) 로 교체
```

**(A) 같은 핸들러**: 앉아 있던 retractor에게 새 값을 `(v, false)`로 건네 자기
전이를 하게 한 뒤, 그 칸만 새 retractor로 바꿉니다. **아래 칸은 건드리지 않습니다** —
`Tween`을 다른 `Tween`으로 바꾸는 것처럼 같은 핸들러가 이어받는 경우 그 아래에서
자란 것들이 그대로 삽니다.

**(B) 다른 핸들러**: 이 칸부터 꼬리까지 **꼬리부터(LIFO)** 철거합니다. 얕은 칸이 깊은
칸을 만들었으니 역순이어야 합니다. 철거 인자는 항상 `(nil, true)`입니다.

여기서 공개 표면과 내부 호출이 갈립니다. 공개 `Dispatch.retractFrom(inst, k, index)`는
철거 결과 **체인이 비었을 때에 한해** 리스트를 `chains`와 인스턴스의 gchold에서
놓아줍니다 — 그러지 않으면
매번 새로 생기는 키(예: `State<Attr>`가 객체마다 내는 그룹 키)가 빈 리스트를 인스턴스
수명 내내 남깁니다. 반면 (B) 분기는 같은 리스트를 곧바로 다시 채우므로 놓아주지 않습니다.

> [!WARNING]
> **`h.process`가 던지면 그 칸의 자리 표시(NOOP)가 영구히 남습니다.** 그 칸의 정리
> 수단은 사라지고 명시적 retract로도 회복되지 않습니다. 일부러 `pcall`로 감싸지
> 않았습니다 — 뜨거운 경로이고, quad는 예외가 던져진 뒤의 부기 정합성을 보장하지 않습니다.

---

## 5. `FALLBACK` 밴드 — base가 제공하고 백엔드가 이기는 자리

`Tag`와 `Attr`의 알고리즘(참조 카운트, 이름 claim)은 엔진과 무관합니다. 실제로 엔진에
닿는 부분은 주입 op 몇 개(`addTag`/`removeTag`/`setAttr`)뿐입니다. 그래서 그 핸들러들은
base가 소유하되 **최하위 밴드**에 등록됩니다.

- 어떤 백엔드가 그 값·키를 자기 방식으로 통째로 다르게 처리하고 싶으면, 그냥 평범한
  우선순위로 자기 핸들러를 하나 더 등록하면 **언제나 이깁니다.** base 쪽을
  비활성화하거나 등록 순서를 신경 쓸 필요가 없습니다.
- 등록 주체는 **quad-base 자신**입니다(모듈 인스턴스가 자기 레지스트리를 구성하는
  시점). 백엔드가 등록하게 두면 백엔드를 아예 안 붙였을 때 이 밴드가 비어 버리는데,
  그건 이 밴드가 가장 필요한 상황입니다.

백엔드가 없을 때 나는 일은 두 층으로 갈립니다.

1. **매치 자체가 안 되면** `Dispatch.process`가 즉시 error를 냅니다. 메시지는 값의
   브랜드까지 알아내서 말합니다:
   `Dispatch: no handler matched key 1 (value: table, brand: MapperDescriptor) — check
   that the provider for this value (e.g. quad-roblox) is initialized`.
   브랜드 조회는 실패 경로에서만 도는 진단입니다 — 모듈에 있는 `is<Brand>` 필드를
   훑는 규약이라, 프로바이더가 `isTween` 같은 술어를 얹어 두면 그것이 곧 등록입니다.
2. **매치는 됐는데 엔진 op이 없으면** 그 op 자리에 심어진 안내 스텁이 던집니다:
   `quad: addTag is not available — no backend has installed the tag ops (install a
   provider with quad:UseProvider — a bare Quad.New() has none)`.
   base가 "그럴듯한 기본 동작"(조용한 no-op)을 추측하지 않는 이유는 단순합니다 — 임의의
   엔진에 무엇이 맞는 기본값인지 base는 알 수 없고, 조용한 no-op은 프로바이더 설치를
   잊은 실수를 그대로 가립니다.

> [!NOTE]
> "프로바이더 미주입"과 "이 백엔드가 애초에 `Tag`를 지원하지 않음"은 이 층에서
> **구분되지 않습니다.** 둘 다 같은 빈 슬롯이기 때문입니다. 더 정확한 실패를 원하는
> 백엔드는 `FALLBACK + 1` 우선순위의 얇은 가로채기 핸들러를 얹을 수 있습니다 — 스캔에서
> 먼저 매치되므로 base 핸들러의 부기 변경이 아예 일어나지 않는, 진짜 원자적 실패가
> 됩니다. 선택적 업그레이드일 뿐 요구사항은 아닙니다.
