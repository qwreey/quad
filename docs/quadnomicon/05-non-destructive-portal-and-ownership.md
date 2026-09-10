---
title: "Vol. 5 — 비파괴 언마운트와 소유권 공리: 포탈이 프리미티브 없이 나오는 이유"
description: "소유권 공리에 따라 비파괴 언마운트가 별도 포탈 프리미티브 없이 성립하는 이유를 설명합니다"
---
# [Quadnomicon Vol. 5] 비파괴 언마운트와 소유권 공리: 포탈이 프리미티브 없이 나오는 이유

> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-base/src/Slot/Raw.luau`, `quad-base/src/Slot/Owner.luau`, `quad-base/src/Slot/Handler.luau`, `quad-base/src/Bookkeeping.luau`

> [!CAUTION]
> 이 권은 재조정 엔진의 저수준 수명 동작을 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](../getting-started/01-first-screen.md)부터 보십시오.

---

## 1. 소유권 공리

컴포넌트 기반 UI에서 **부착(트리에 보이는가)**과 **수명(메모리에 존재하는가)**은 자주 한 덩어리로 취급됩니다. 조건부 컴포넌트가 언마운트되면 그 상태까지 같이 버려지고, 그래서 "트리 밖 다른 위치에 그리되 죽이지는 않는" 요구가 생기면 별도의 합성 프리미티브(포탈)가 필요해집니다.

quad는 이 둘을 분리합니다:

> **소유권 공리**: 자원을 만든 쪽이 그 수명을 정한다. 마운트 자리는 가시성만 정한다.

이건 Slot만의 규칙이 아니라 quad 전역 철학입니다 — `Ref`는 Destroy와 무관하고, `Attr`는 명시적 `None`으로만 지워집니다. **"이전 값을 지울지는 그 값을 만든 쪽이 정한다"**가 그 셋의 공통 문장입니다.

### 어디까지가 비파괴인가 — 정확한 범위

"quad는 절대 파괴하지 않는다"는 **틀린 요약**입니다. 비파괴는 두 자리에서 성립합니다:

1. **자식 배열 위치의 `State<Slot>` 교체.** 그 자리를 맡는 `SlotHandler`의 retractor는 `unmountSlotTree`를 부릅니다 — 파괴가 아니라 언마운트입니다. 맨 `State`를 Slot 요소로 넣었을 때 quad가 대신 만들어주는 래퍼 Slot도 `Owned = false`라 같은 취급입니다.
2. **`Owned = false`로 만든 Slot.** 요소를 "외부에서 빌려온 것"으로 보고, 밀려나면 언마운트만 합니다.

반대로 **`:List`/`:Single`의 기본값은 `Owned = true`이고, 이 경우 데이터에서 빠진 요소는 파괴됩니다.** 이건 실수가 아니라 기본값의 의도입니다 — 리스트가 만들어낸 것은 리스트가 치웁니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 2. 파괴 대 언마운트: 뒤집힌 결정

### 2.1 옛 모델

초기 v2에서는 `:List`/`:Single`의 재조정이 교체 시 `rawRemove`를 불렀습니다 — 제거와 **파괴**가 한 몸이었습니다.

### 2.2 그 모델이 만든 증상

- **껍데기만 남는 서브트리**: `State<Slot?>`를 `nil`로 지웠다가 같은 Slot 객체를 다시 넣으면, 그 사이에 자식 Instance들이 이미 `Destroy`된 상태라 두 번째 등장부터 조용히 빈 트리가 나왔습니다. 당시 권고가 "같은 Slot을 왕복시키지 말 것"이었을 만큼 실제로 밟는 자리였습니다.
- **포탈이 불가능**: `stateSlot:Get()`으로 Slot을 뽑아두고 다른 값을 `Set`한 뒤 그 Slot을 다른 곳에 넣는 시나리오가 원리적으로 막혔습니다 — 뽑아둔 참조는 `Set` 직후 이미 파괴된 Slot이었습니다.

### 2.3 역전 근거

결정적인 이유는 위 증상 자체가 아니라 **일관성**이었습니다:

- `State<Frame>`이 이미 그렇게 동작합니다. `child:Set(otherFrame)`을 해도 quad가 이전 `Frame`을 `Destroy`해주지 않고 그냥 트리에서 내려올 뿐인데, `State<Slot>`만 다르게 동작할 이유가 없습니다.
- "만든 쪽이 지운다"는 위 §1의 공리가 `Ref`/`Attr`에서 이미 확정돼 있었습니다.

그리고 막고 있던 건 소유권 규칙이 아니라 **"제거 = 파괴"라는 재조정의 선택 하나**였습니다. 필요한 부품(`Extract`/`Splice`의 비파괴 제거, `claimOwner`/`releaseOwner`의 소유권 이양, 재마운트를 이미 지원하던 `attachSlot`)은 전부 이미 있었고, 포탈은 그 위에 아무것도 더 얹지 않고 나왔습니다.

### 2.4 지금의 분리

- **`rawUnmount(self, index, deferPhysical?)`**: `releaseOwner`로 소유권을 놓고, (배치가 아니면) `nativeExtract`로 물리 트리에서 뗀 다음 `vacate`를 부릅니다. `vacate`는 **그 자리를 0/None으로 리셋하는 게 아니라 자리 자체를 지웁니다** — `_elements`에서 `table.remove`, 역맵 갱신, 부기 배열 한 칸 당김, 그리고 게이트를 존중하는 재계산.
- **`q.dispose(value)`**: 명시적 파괴. 그 값을 아직 어떤 Slot이나 마운트 위치가 쥐고 있으면 **거부하고 에러를 냅니다**(무엇을 먼저 해야 하는지까지 메시지에 적힙니다). 소유자가 없을 때만 `destroySlotTree` 또는 `nativeDispose`로 내려갑니다.

---

## 3. 포탈이 공짜로 나온다

언마운트가 서브트리를 그대로 두므로, **포탈에 전용 프리미티브가 필요 없습니다.**

```
마운트 자리 A (가방 창)                       마운트 자리 B (핫바 칸)
┌──────────────────────────────┐            ┌──────────────────────────┐
│  State<Slot?> a              │            │  State<Slot?> b          │
│   └── ItemView (마운트됨)     │            │   └── (비어 있음)          │
└──────────────┬───────────────┘            └─────────────▲────────────┘
               │  1. A에서 떼기:                           │  2. B에 붙이기:
               │     a:Set(nil)                           │     b:Set(itemView)
               │     → unmountSlotTree                    │     → attachSlot
               └───────────────────[ ItemView ]───────────┘
                                  (메모리에 살아 있음)
```

`a:Set(nil)`이 나가면 `SlotHandler`의 retractor가 돌아 서브트리를 물리 트리에서 떼고(`nativeExtract` — `.Parent = nil`), 옛 위치의 부기를 비우고, `unbindLifetime` + `releaseOwner`로 소유권을 놓습니다. `ItemView`의 Instance 트리·이벤트 연결·내부 `Source`는 그대로입니다. 이어서 `b:Set(itemView)`가 나가면 `claimOwnerAt`이 새 소유자를 잡고 `attachSlot`이 새 부모 아래로 flush합니다.

### 맨 State를 넣으면 quad가 래퍼를 만든다

```luau
D.Frame {
    q.Slot<<Instance>> { myInstanceState }, -- 맨 State 요소는 Slot():Single(state, nil, { Owned = false })로 감싸진다
}
```

이 래퍼는 `Owned = false`이므로 `myInstanceState`가 다른 Instance로 바뀌어도 이전 Instance는 살아 있고, 외부 변수에 붙들거나 다른 슬롯으로 옮길 수 있습니다. 최종 파괴 책임은 그걸 만든 쪽에 있습니다.

### 보장되지 않는 것

- **`Set`으로 덮어쓰기 *전에* 이전 값을 직접 `Destroy`하는 건 UB입니다.** 순서는 항상 `Set`(언마운트)이 먼저, 정리가 나중입니다. `State<Frame>`에서 먼저 `frame:Destroy()`하고 `Set`하는 것과 같은 문제입니다.
- 뽑아둔 Slot을 아무도 안 들고 있으면 그냥 GC 대상입니다 — "언젠가 다시 붙겠지"가 아니라 참조를 들고 있어야 살아 있습니다.

---

## 4. 해제 순서 불변식: `None` 먼저, `0`은 그 다음

옛 소유자에게서 위치를 반납할 때는 순서가 계약입니다. 이건 `rawUnmount`의 꼬리가 아니라 Dispatch 표면의 해제 경로(`setEmpty`)이고, 잎 핸들러들이 "마운트 안 하는 위치"를 등록할 때도 같은 본문을 씁니다:

```luau
q.Dispatch.setOffsetSource(ownerKey, position, q.None) -- 1. 발행 채널을 먼저 끊는다
q.Dispatch.setLength(ownerKey, position, 0)            -- 2. 길이를 0으로 접고 재계산
```

**순서가 뒤집히면 안 되는 이유**: `setLength`는 끝에서 재계산을 돌립니다. 먼저 부르면 아직 등록돼 있는 옛 `Source`에 헛된 `:Set`이 날아갑니다. 두 줄이 한 함수(`setEmpty`)로 묶여 있는 것도 여러 종단 지점에서 순서가 어긋나지 않게 하기 위해서입니다.

---

## 5. 요약 — quad가 실제로 보장하는 것

| 상황 | quad의 동작 |
|---|---|
| 자식 위치의 `State<Slot>` 교체 | `unmountSlotTree` — 이전 Slot은 살아 있고 다시 붙일 수 있다 |
| 맨 `State` 요소의 값 교체 | 래퍼가 `Owned = false` — 이전 Instance는 살아 있다 |
| `:List`/`:Single` 기본값(`Owned = true`)에서 키가 빠짐 | 그 요소는 파괴된다 |
| `:List`/`:Single`에 `Owned = false` | 언마운트만, 파괴 없음 |
| `q.dispose(value)` | 아직 소유돼 있으면 거부(에러), 아니면 파괴 |
| 아무도 안 들고 있는, 뗀 값 | 평범한 Lua GC |

포탈은 이 표의 첫 두 줄에서 그냥 따라 나오는 결과이지, 별도의 기능이 아닙니다.
