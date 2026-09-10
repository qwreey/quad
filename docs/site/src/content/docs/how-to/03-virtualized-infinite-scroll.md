---
title: "03. `Slot:List`로 긴 목록 다루기 — 재활용과 윈도잉"
description: "Slot List로 긴 목록을 재활용과 윈도잉으로 효율적으로 렌더링하는 법을 설명합니다"
---
> **대상 독자**: 수백~수만 개짜리 목록을 `ScrollingFrame`에 그려야 하는 개발자
> **다루는 개념**: `LayoutOrder`/`Position` 바인딩, 윈도잉, `userdata`, `Blocker`
> **먼저**: `Slot:List`의 기본(계약·재사용·`KeyGone`·`Detach`)은 [시작하기 12. 목록 만들기](/getting-started/12-lists/)에서 배웁니다. 이 문서는 그 위에서 **긴 목록**을 다루는 법만 봅니다.
> **재활용과 윈도잉은 서로 다른 행에 걸립니다**: 재활용은 **화면에 계속 남아 있는 키**에만 적용되고, 윈도우 밖으로 나가 키가 사라진 행은 재활용이 아니라 파괴(또는 `q.Detach`로 홀드)입니다(§7).

---

## 1. 해결하려는 문제

`ScrollingFrame` 안에 항목 수만큼 Instance를 만들면 생성 비용과 레이아웃
비용이 같이 늘어납니다. 해법은 둘 — **재활용**(목록이 바뀌어도 살아남은
항목은 다시 만들지 않는다)과 **윈도잉**(보이는 구간+여유분만 만든다)입니다.

둘 다의 토대는 `Slot():List`입니다. 다만 **quad는 위치를 대신 정해주지
않습니다** — `index`와 `offset`을 넘겨줄 뿐, 그것을 `LayoutOrder`에 쓸지
`Position`에 쓸지는 전적으로 `updateFn`을 쓰는 사람의 몫입니다(3절).

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 2. 긴 목록에서 특히 중요한 계약 셋

전체 계약(다섯 인자와 네 갈래 반환)은 [시작하기 12](/getting-started/12-lists/)와 [레퍼런스: `Slot`](/reference/core/07-slot/)에 있습니다. 여기서는 목록이 길어질 때 비용을 가르는 셋만 짚습니다.

```
Slot():List(data, updateFn, keyFn?, opts?)
updateFn(item, index, offset, prev, ud) -> (result, ud)
```

- **`keyFn(item, i)`가 재활용을 결정합니다.** 항목의 신원이 안정적이어야 `prev`가 넘어오고, `prev`를 그대로 돌려주는 갈래가 마운트도 파괴도 없는 **가장 싼 경로**입니다. 생략하면 배열 인덱스가 키인데, 그러면 목록이 밀릴 때마다 신원이 어긋나 전부 새로 만들어집니다.
- **항목마다 바뀌는 값은 `ud`에 `Source`로 넣어 둡니다.** 재활용 갈래에서는 인스턴스를 다시 만들 수 없으니, 라벨 텍스트나 위치는 그 `Source`만 `:Set` 합니다.
- **`opts.Owned = false`** — 이 Slot이 요소를 **파괴하지 않습니다**(목록에서 빠질 때 언마운트만). 밖에서 만들어 넘긴 Instance를 목록에 태울 때 씁니다.

`data`는 평범한 배열이거나 배열을 담은 `State`입니다. `State`면 값이 바뀔 때마다 재조정(reconcile)이 돕니다.

---

## 3. 순서와 위치는 호출자가 정한다

`Slot`은 `LayoutOrder`라는 이름을 알지 못합니다. 자동으로 넣어주는 안은
검토 후 기각됐습니다 — 컴포넌트가 스스로 지정한 `LayoutOrder`를 Slot이 조용히
덮어쓰게 되고("매직 없이 명시적"이라는 기조와 충돌), `updateFn`이 동적 요소를
전부 다룬다는 원래 설계도 깨지기 때문입니다.

`UIListLayout`으로 세로 배치를 할 때의 정본 관용구는 이렇습니다.

```luau
local function updateFn(
    item: any,
    index: number,
    offset: QuadTypes.State<number>,
    prev: any,
    ud: any
): (any, any)
    if item == q.KeyGone then
        return nil, ud -- 사라진 키 — 파괴
    end

    if not prev then
        -- 새 요소: 이전 Source를 재사용하지 말고 처음부터 올바른 값으로 만든다
        local layoutOrder = q.Source(index)
        local order: QuadTypes.State<number> = layoutOrder:With(offset):Compute(function(i)
            return i:Get() + offset:Get()
        end)
        return D.Frame {
            LayoutOrder = order,
            -- ...
        }, { layoutOrder = layoutOrder }
    end

    -- 재활용: 실제로 바뀔 때만 Set
    local layoutOrder = ud.layoutOrder
    if layoutOrder:Get() ~= index then
        layoutOrder:Set(index)
    end
    return prev, ud
end
```

> ⚠️ `:With(offset)`으로 모은 값은 `Compute` 콜백에 **포지셔널로 넘어오지
> 않습니다**. 두 번째 자리에 오는 것은 직전 계산 결과(`previous`)입니다 —
> 위처럼 클로저로 `offset:Get()`을 직접 읽으세요.
>
> `:Compute`를 props 테이블 안에 인라인으로 쓰지 않고 위처럼 타입 붙인 지역
> 변수로 빼는 이유는 에디터 타입 검사입니다 — 함수 인자로 넘기는 테이블
> 리터럴 안에서는 무주석 콜백 파라미터가 풀리지 않습니다.

---

## 4. 윈도잉 — 보이는 구간만 그리기

윈도잉을 하면 목록의 일부만 자식으로 존재하므로 `UIListLayout`이 전체 스크롤
높이를 만들어낼 수 없습니다. 그래서 **윈도우 방식에서는 `LayoutOrder`가 아니라
항목의 절대 인덱스로 `Position`을 직접 계산**하고, 스크롤 범위는
`CanvasSize`로 고정합니다. 3절의 `LayoutOrder` 관용구는 이 레시피에선 쓰이지
않습니다 — 둘 중 하나를 고르세요.

```luau
local ROW = 50
local BUFFER = 3

local function VirtualList(props: { items: { { id: string, label: string } } })
    local items = props.items
    local scrollY = q.Source(0)
    local viewportHeight = q.Source(600)

    -- 보이는 구간을 반응형으로 잘라낸다(후행 의존성: fn(self, previous, ...deps))
    local window = scrollY:Compute(function(y, _previous, height)
        local first = math.floor(y:Get() / ROW) + 1
        local count = math.ceil(height:Get() / ROW) + 1
        local startIndex = math.max(1, first - BUFFER)
        local endIndex = math.min(#items, first + count + BUFFER)
        local slice = {}
        for i = startIndex, endIndex do
            table.insert(slice, { item = items[i], absIndex = i })
        end
        return slice
    end, viewportHeight)

    local rows = q.Slot<<Instance>>():List(window, function(entry: any, _index, _offset, prev, ud): (any, any)
        if entry == q.KeyGone then
            return nil, ud
        end
        if prev then
            -- 화면에 남아 있는 행: 절대 위치만 갱신하고 Instance는 재활용
            if ud.abs:Get() ~= entry.absIndex then
                ud.abs:Set(entry.absIndex)
            end
            return prev, ud
        end
        local abs = q.Source(entry.absIndex)
        local position: QuadTypes.State<UDim2> = abs:Compute(function(a)
            return UDim2.new(0, 0, 0, (a:Get() - 1) * ROW)
        end)
        local row = D.Frame {
            Size = UDim2.new(1, 0, 0, ROW),
            Position = position,
            BackgroundTransparency = 1,

            D.TextLabel {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = entry.item.label,
            },
        }
        return row, { abs = abs }
    end, function(entry)
        return entry.item.id
    end) -- 생성자의 제네릭은 추론되지 않는다 — `q.Slot<<Instance>>()`처럼 명시 타입 인자로 준다

    return D.ScrollingFrame {
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, #items * ROW),
        ScrollBarThickness = 6,

        q.OnChange("CanvasPosition", function(pos: Vector2)
            scrollY:Set(pos.Y)
        end),
        q.OnChange("AbsoluteWindowSize", function(size: Vector2)
            viewportHeight:Set(size.Y)
        end),

        rows,
    }
end
```

`q.OnChange(name, fn)`는 **숫자 키 자리에** 놓는 디스크립터입니다(해시 키가
아닙니다). 콜백은 엔진 인자만 받습니다.

---

## 5. 스크롤 이벤트 폭주 누그러뜨리기 — `Blocker`

`CanvasPosition`은 한 프레임에도 여러 번 바뀔 수 있습니다. 여러 변경을 한 번의
전파로 접으려면 `Blocker`를 **`state:Apply(blocker)`로 붙여** 게이트된 State를
만들고, 목록은 그 게이트된 State를 구독하게 합니다.

```luau
local rawScrollY = q.Source(0)
local scrollGate = q.Blocker()
local scrollY = rawScrollY:Apply(scrollGate) -- 게이트된 노드 — 아래 계산은 이걸 본다

-- 묶어서 밀어 넣을 구간
scrollGate:On()
rawScrollY:Set(120)
rawScrollY:Set(180)
scrollGate:Off()  -- 여기서 정확히 한 번 전파된다(OffWithoutEmit이면 버려진다)
```

- `blocker`를 그냥 만들어 두기만 하면 아무것도 막히지 않습니다 — `:Apply`로
  붙인 State만 게이트됩니다.
- 같은 `Blocker`를 **중첩해서** `On` 두 번, `Off` 한 번 하는 식은 지원하지
  않습니다(`IsBlocked`는 카운터가 아니라 단순 불리언). 겹치는 배치가 필요하면
  배치마다 새 `Blocker`를 만드세요.

---

## 6. 엔진 사실: `nativeMove`/`nativeSwap`은 의도적 no-op

Roblox에서는 형제의 물리적 순서가 렌더 순서를 정하지 않습니다 — 순서는
`UIListLayout`의 `SortOrder`/`LayoutOrder`나 `ZIndex`가 정합니다. 그래서
quad-roblox 백엔드는 재정렬 op를 **일부러 아무 일도 하지 않게** 구현합니다.

```luau
-- quad-roblox/src/EngineOps.luau
local function nativeMove(_target, _fromOffset, _elements, _toOffset)
    -- no-op on purpose — order is bookkeeping, not physical, on Roblox
end
```

기본 합성 폴백을 그대로 뒀다면 `.Parent`를 두 번 쓰며 떼었다 붙이게 되고
(`AncestryChanged` 재발화), Roblox에서는 물리적으로 아무것도 바뀌지 않는
재정렬을 위해 그 비용을 치르게 됩니다. quad-base는 여전히 정확한 슬롯 인덱스
부기를 유지합니다 — DOM처럼 자식 순서가 실제 의미를 갖는 백엔드가 그 부기를
쓰기 때문입니다.

---

## 7. 확인 방법과 이 레시피가 안 해주는 것

**확인** — 개발자 콘솔(`F9`) → Memory의 `Instances` 수가 목록 길이가 아니라
윈도우 크기에 비례해 머무는지, 그리고 `updateFn`의 "새로 만드는" 갈래에
카운터를 넣어 살아남은 키가 다시 만들어지지 않는지 봅니다.

**안 해주는 것**
- **행 높이 측정이 없습니다.** 위 예제는 모든 행이 `ROW`로 같은 높이라고
  가정합니다 — 가변 높이는 직접 누적 높이를 관리해야 합니다.
- **윈도우 밖으로 나간 행은 재활용되지 않습니다.** 키가 사라지면 파괴(또는
  `q.Detach`로 홀드)이고, 재활용은 "화면에 계속 남아 있는 키"에만 적용됩니다.
- **스크롤 이벤트 자체의 스로틀링은 없습니다.** 5절의 `Blocker`는 사용자가
  직접 구간을 열고 닫는 도구이지 자동 프레임 병합기가 아닙니다.
