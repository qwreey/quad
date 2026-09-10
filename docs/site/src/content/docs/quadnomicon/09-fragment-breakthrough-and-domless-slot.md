---
title: "Vol. 9 — 컴포넌트가 형제 여럿을 반환하는 문제와 DOMless Slot 트리"
description: "물리 실체가 없는 Slot으로 컴포넌트가 형제 여럿을 반환하는 문제를 푸는 설계를 설명합니다"
---
> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-base/src/Slot/init.luau`, `quad-base/src/Slot/List.luau`, `quad-base/src/Bookkeeping.luau`

:::danger
이 권은 부분합(prefix-sum) 가상 슬롯 트리를 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](/getting-started/00-installation/)부터 보십시오.
:::

---

## 1. 물리 트리밖에 없는 엔진에서의 제약

웹 프레임워크의 프래그먼트(React의 `<></>`)가 푸는 문제는 한 문장으로 요약됩니다 — **컴포넌트가
형제 여럿을 반환할 수 있어야 하는데, 그러자고 `<div>`를 하나 더 만들고 싶지는
않습니다.**

Roblox에는 가상 DOM이 없습니다. 화면에 있는 노드는 전부 실제 엔진 `Instance`이고,
"자식 목록"은 그 인스턴스들의 실제 부모 관계 그 자체입니다. 그래서 컴포넌트가 두 개를
반환하려 하면 놓을 자리가 없습니다 — 반환값 하나가 자식 하나이기 때문입니다.

가장 흔한 우회는 형제들을 `Frame` 하나로 감싸는 것입니다. 이 우회의 문제는 시각적인
것이 아니라 **구조적인 것**입니다. 래퍼 `Frame`은 그 자체가 부모의 자식 하나이므로,
부모 수준에서 도는 레이아웃(`UIListLayout` 등)에게는 항목 **하나**로 보입니다. 감싼
형제 둘이 부모의 형제 목록에 나란히 서는 것이 아니라, 래퍼가 차지한 한 칸 안에
갇힙니다. 게다가 그 래퍼는 사용자가 선언한 적 없는 인스턴스라 크기·정렬·이벤트
전파를 전부 따로 관리해야 합니다.

그래서 Roblox의 선언형 UI에서는 "컴포넌트는 루트 하나를 반환한다"가 사실상 규칙처럼
굳어 있었습니다.

---

## 2. quad의 답: 물리 실체가 없는 Slot

quad는 **`Slot`을 Instance가 아닌 것으로** 만들어 이 제약을 풉니다. `Slot`은 Roblox
데이터 모델에 존재하지 않습니다. 선언과 물리 부모 사이에 있는 **순수한 부기 노드**입니다.

```
물리 계층:
ScreenGui (실제 Instance)
 ├── Header       (Frame)
 ├── SaveButton   (TextButton)  ──┐ ButtonGroup()이 Slot 하나로 반환
 ├── CancelButton (TextButton)  ──┘
 └── Footer       (Frame)

부기 계층:
ScreenGui
 ├── 자리 1: Header            (Length = 1, Offset = 0)
 ├── 자리 2: Slot[ButtonGroup] (Length = 2, Offset = 1)
 │     ├── 요소 1: SaveButton   (Length = 1)
 │     └── 요소 2: CancelButton (Length = 1)
 └── 자리 3: Footer            (Length = 1, Offset = 3)
```

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
local Slot = q.Slot

local function ButtonGroup()
	return q.Slot<<Instance>>({
		D.TextButton { Text = "Save" },
		D.TextButton { Text = "Cancel" },
	})
end

local root = D.Frame {
	D.Frame { Name = "Header" },
	ButtonGroup(),
	D.Frame { Name = "Footer" },
}
-- root의 실제 자식은 넷: Header, SaveButton, CancelButton, Footer
```

`Slot`은 자기 요소들의 **길이 합**만 부모에게 알립니다. 물리적으로는 `SaveButton`과
`CancelButton`이 `Header`·`Footer`와 같은 층의 형제로 붙습니다. 래퍼 인스턴스는 하나도
생기지 않으므로 부모 수준의 레이아웃도 네 항목을 그대로 봅니다.

---

## 3. 형제를 가로지르는 부분합 오프셋

컴포넌트가 요소를 동적으로 늘리고 줄이면 뒤따르는 형제의 물리 위치가 바뀝니다. `Slot A`가
2개에서 5개가 되면, 그 뒤의 `Slot B`는 자기 요소를 어디에 끼워야 하는가?

quad는 자리마다 길이와 오프셋을 부기합니다.

1. 자리 `i`는 자기 길이를 `Dispatch.setLength(ownerKey, i, len)`으로 등록합니다.
   `len`은 상수일 수도, `State`일 수도 있습니다.
2. 자리 `i`는 자기 시작 위치를 `Dispatch.setOffsetSource(ownerKey, i, source)`로
   받습니다. `source`는 `Source<number>` 또는 `None`입니다.
3. 길이가 바뀌면 그 자리 뒤쪽의 오프셋만 다시 계산됩니다. 재계산은 배치 게이트
   (`Blocker`) 안에서 모여 한 번만 돕니다.

부기 함수들은 `Dispatch` 표면에 있지만 구현은 별도 부기 서브시스템에 삽니다
(`quad-base/src/Bookkeeping.luau`) — `Slot`과 `Dispatch`가 둘 다 그것을 쓰고, 부기
쪽은 둘 다 모릅니다.

### `LayoutOrder`를 자동으로 쓰지 않는 이유

자주 나오는 질문 — *"Slot이 내 인스턴스에 `LayoutOrder`를 알아서 써 주나?"* 답은
**아니오**이고, 이유는 셋입니다.

1. **암묵적 프로퍼티 쓰기를 하지 않습니다.** 컴포넌트가 이미 `LayoutOrder = 10`을
   선언했는데 엔진이 조용히 덮어쓰면 원인을 찾기 어려운 렌더 버그가 됩니다.
2. **엔진 중립.** 웹 백엔드에서 물리 순서는 삽입 위치나 CSS `order`의 몫입니다.
   `LayoutOrder`를 코어에 박으면 슬롯 트리가 Roblox에 묶입니다.
3. **재료는 줍니다.** `Slot():List(...)`의 `updateFn`은 `(item, index, offset, prev,
   ud)`를 받습니다 — `index`는 이 Slot 안에서의 물리 위치(1부터, 앞선 요소들의 실제
   길이를 반영합니다), `offset`은 이 Slot의 시작 위치를 나르는 `Source<number>`입니다. 쓸지
   말지는 컴포넌트 작성자가 정합니다.

```luau
local data = q.Source({ "a", "b", "c" })
local list = q.Slot<<Instance>>()
list:List(data, function(item, index, offset, prev, ud)
	if item == q.KeyGone then
		return nil, ud -- 키가 빠진 사이클: 파괴(nil/None) 또는 홀드(Detach)만 허용
	end
	if prev and ud then
		ud.order:Set(index) -- 재활용: 자리 값만 갱신하고 요소는 그대로
		return prev, ud
	end
	local order = q.Source(index)
	local layoutOrder = order:With(offset):Compute(function(i: QuadTypes.StateData<number>): number
		return i:Get() + offset:Get()
	end)
	return D.TextButton { Text = item :: string, LayoutOrder = layoutOrder }, { order = order }
end, function(item) return item end) -- keyFn: 문자열 자신이 키(생략하면 배열 index가 키)
```

---

## 4. 컴포넌트의 출력이 하나일 필요가 없어진다

DOMless Slot의 직접적인 귀결은 **컴포넌트의 반환 타입이 하나로 고정되지 않는다**는
것입니다. 컴포넌트는 다음 중 무엇이든 반환할 수 있습니다.

- `Instance` 하나 — `D.Frame { … }`
- 정적인 형제 묶음 — `Slot { D.TextButton { … }, D.ImageLabel { … } }`
- 동적인 목록 — `Slot():List(data, updateFn)`

배열에 들어가는 것은 **호출이 끝난 값**이어야 합니다. `Slot { D.TextButton }`처럼
호출하지 않은 생성자를 넣으면 요소 타입 화이트리스트에 걸려 즉시 error입니다:
`Slot: this backend cannot mount this value`. `Ref`/`Observer`/`Effect`/`Modifier`
같은 핸들러 층 값도 요소가 될 수 없습니다(그것들은 props 배열 부분의 자리이지 Slot 요소가
아닙니다).
