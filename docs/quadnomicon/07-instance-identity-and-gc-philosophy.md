---
title: "Vol. 7 — 인스턴스 신원, 네이티브 GC, 그리고 `Claim` 계약"
description: "userdata 신원과 네이티브 GC를 다루는 quad의 Claim 계약과 정리 모델을 설명합니다"
---
# [Quadnomicon Vol. 7] 인스턴스 신원, 네이티브 GC, 그리고 `Claim` 계약

> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-roblox/src/LifetimeHandle.luau`, `quad-base/src/Claim.luau`, `quad-base/src/Relate.luau`, `quad-base/src/Slot/Raw.luau`

> [!CAUTION]
> 이 권은 인스턴스 신원 모델과 정리(teardown) 모델을 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](../getting-started/01-first-screen.md)부터 보십시오.

---

## 1. v1에서 살아남은 것과 살아남지 못한 것

quad v1에도 "참조를 붙잡아 GC를 막는" 트릭이 있었습니다 — 어떤 시그널에든 연결해 두면
그 콜백이 캡처한 값들이 연결이 살아 있는 동안 함께 살아남는다는 것입니다. 다만 v1에서는
그 트릭이 `class.lua`·`lang.lua` 같은 여러 파일에 각자 중복 구현돼 있었고, 대칭되는
해제 경로가 없어 결국 weak 테이블 GC에만 기대는 구조였습니다.

v2가 물려받은 것은 **그 트릭 하나**이고, 물려받지 않은 것은 **그것이 흩어져 있던
구조**입니다. 지금 이 경로는 프로바이더 주입 op `nativeClaim(inst)` 한 자리에만 있고,
반대편에는 `bindLifetime`/`unbindLifetime`이라는 명시적인 짝이 서 있습니다.

---

## 2. userdata 신원 문제

Roblox의 `Instance` 값은 엔진 객체 자체가 아니라 **엔진 객체를 가리키는 Lua
userdata 포인터**입니다.

```
┌─────────────────┐             ┌─────────────────┐
│ Lua             │             │ Roblox 엔진     │
│                 │             │                 │
│  userdata A ────┼────────────>│  엔진 객체      │
│                 │             │  (물리 GUI)     │
│  userdata B ────┼────────────>│                 │
└─────────────────┘             └─────────────────┘
```

Lua 쪽에서 아무도 그 userdata를 참조하지 않으면 userdata는 회수될 수 있습니다. 엔진
객체는 트리에 살아 있는데도 그렇습니다. 나중에 `.Parent`나 `:GetChildren()`으로 같은
엔진 객체를 다시 얻으면 **다른 userdata**가 나올 수 있습니다.

quad의 내부 부기는 대부분 `inst`를 키로 하는 weak 키 릴레이션(`Relate`) 위에 있습니다(`elementOwner`는 요소가 키라 Slot도 키가 됩니다) —
디스패치 체인 `chains[inst][k]`, Slot의 `elementOwner`, Tag의 이름별 홀더 집합, Attr의
이름 claim. 키로 쓰던 userdata가 회수되고 새 userdata가 오면 그 릴레이션 항목 전체가
조용히 미아가 됩니다. 조회는 실패가 아니라 `nil`로 돌아오고, 그건 "그런 바인딩은
없었다"와 구분되지 않습니다.

---

## 3. `nativeClaim` — 신호에 걸어 신원을 고정한다

quad가 소유하는 Instance마다 정확히 한 번, 생성 직후(`New`) 또는 claim 시점에
`nativeClaim(inst)`이 돕니다. 아래는 그 본체입니다(`quad-roblox/src/LifetimeHandle.luau`
— 사용자 코드가 아니라 내부 구현 발췌):

```luau
local nop = (false or function(...) end)  -- `false or`: local 함수가 상수 접힘/인라인되는 것을 막는다(-O2)

local gchold = {}                          -- 이 inst에 매달린 값들의 강참조 홀더
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
    nop(gchold, inst)  -- 절대 발화하지 않는다. 클로저가 둘을 업밸류로 잡는 것이 전부
end)
gchold[1] = gcconn                         -- 배열 1번 자리는 gcconn 전용

InstData:SetWeak(inst, "gchold", gchold)
InstData:SetWeak(inst, "gcconn", gcconn)
```

- **`ClassName`은 바뀌지 않는 프로퍼티라 이 시그널은 발화하지 않습니다.** 엔진이
  연결된 콜백을 살려 둔다는 사실만 씁니다.
- **클로저가 `gchold`와 `inst`를 둘 다 캡처하는 것이 핵심입니다.** `inst` 캡처가 곧
  userdata 신원 고정입니다.
- **릴레이션은 `SetWeak`입니다.** `gchold`와 `gcconn`은 클로저 ↔ `gchold[1]` 상호
  참조로 이미 살아 있으므로, 여기서 강참조를 한 겹 더 걸면 상호 강참조 누수가 됩니다.
- `bindLifetime(inst, value)`은 이 `gchold`의 해시 자리에 값을 넣고 `gcconn` 참조를
  값 쪽에 복사합니다. 알려진 타입이 아니면(평범한 테이블·클로저) 그 GC 릴레이션만 하고
  끝납니다.

### 대가는 숨기지 않는다

클로저가 `inst`를 잡고, 그 클로저를 `inst` 자신의 시그널이 잡는 순환입니다. 따라서
**quad가 소유한 Instance는 참조를 놓는 것만으로는 회수되지 않습니다 — `Destroy`가
유일한 절단면입니다.**

실질적으로 새로 생긴 제약은 아닙니다. 바인딩이 하나라도 걸리면 그 옵저버 클로저가
어차피 `inst`를 캡처해 같은 순환이 생깁니다. `nativeClaim`은 "아직 아무것도 안 걸린
Instance"까지 같은 규칙으로 통일한 것입니다.

---

## 4. `Claim` — 이미 있는 트리를 quad 소유로

Studio에서 만들어 둔 GUI나 `:Clone()` 사본을 quad가 소유하게 만드는 표면이 `Claim`입니다.
둘째 인자는 props 테이블이 아니라 **매퍼 디스크립터**입니다 — 이름으로 기존 자식을
찾아 붙이는 구조 서술.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D

local template = <Studio에서 만들어 둔 템플릿 Instance>
local M = D.Mapper
local root = q.Claim(template:Clone(), M.Frame(M.Root)({
    M.TextLabel("Title")({ Text = "Hello" }),
    BackgroundTransparency = 0.25,
}))
-- root == 넣은 inst 그대로(타입도 그대로)
```

### 계약은 "그려지는 직계 자식을 전부 매핑한다"

- **부기 대상(그려지는 직계 자식)은 남김없이 매핑해야 합니다.** 매핑 안 된 자식이
  남으면 삽입 위치와 Length/Offset 부기가 어긋납니다. "일부만 매핑하고 나머지는 남의
  것으로 둔다"는 모드는 검토 뒤 기각됐습니다.
- **대신 claim 대상 자체가 좁습니다.** 배타 소유가 성립하는 요소만 claim합니다 —
  `ScreenGui`·`SurfaceGui`·`BillboardGui`·`Frame`류·`Clone()` 사본. `PlayerGui`나
  `CoreGui`처럼 엔진과 여러 스크립트가 나눠 쓰는 공동 소유 컨테이너는 애초에 claim
  대상이 아닙니다. 즉 "게임의 모든 인스턴스를 claim해야 하나"의 답은 아니오지만, 그
  이유는 직계만 느슨하게 본다는 것이 아니라 **claim한 것 안에서는 전부, claim하지
  않은 것은 아예 대상 밖**이라는 것입니다.
- **디스크립터는 1회용**입니다. 재사용하면 error. 소진 표시는 claim이 성공한 *뒤*에
  서므로, 도중에 실패하면 재시도가 진짜 원인을 다시 보고합니다.
- **같은 `inst`를 두 번 claim하는 것**(또는 `New`가 만든 inst를 claim하는 것)은
  error입니다: `nativeClaim: Instance is already claimed by quad`. 판정은 별도 레지스트리가
  아니라 §3의 셋업이 이미 있는지 하나로 합니다.
- **루트의 `.Parent`는 어느 부기에도 속하지 않습니다.** 그래서 밖에서
  `root.Parent = playerGui`로 붙이고 떼는 것은 허용이고, `Mount(root, parent)`류
  표면은 일부러 만들지 않았습니다. 금지는 여전히 "quad가 소유한 부모 *아래*"에 밖에서
  자식을 끼우거나 빼는 것입니다.

### 보장되지 않는 것

- 이름 중복·부재, 디스크립터 순서와 실제 물리 순서의 불일치는 UB입니다(debug 검사의 몫).
- **이미 `Destroy`된 inst를 claim하는 것도 UB**이며, 가드를 만들지 않습니다. `:Clone()`
  결과는 Parent가 없으므로 조상 검사류로는 "죽은 것"과 "아직 안 붙인 것"을 가를 수
  없고, 실물 Roblox에 깨끗한 destroyed 술어가 없기 때문입니다.
- claim된 트리에서 `PreRef`가 뜻하는 것은 "quad가 이 inst에 무언가 하기 전"뿐입니다.
  `New`가 주던 "아직 자식도 프로퍼티도 없다"는 보장은 여기서 성립하지 않습니다 —
  템플릿의 자식과 프로퍼티가 이미 있습니다.

---

## 5. 정리는 되감기가 아니라 섬의 붕괴다

디스패치 체인 리스트는 retractor 클로저를 담고, retractor는 (전이적으로) `inst`를
캡처합니다. 그래서 `chains`가 이 리스트를 강하게 잡으면 **weak 키를 되참조하는 값**이
되어 영원히 회수되지 않습니다(Luau에는 ephemeron이 없습니다). 실제 앵커는 `chains`가 아니라
`bindLifetime(inst, list)`이고, `chains`는 약하게만 잡습니다.

결과적으로 `Destroy`가 gcconn을 끊으면 gchold 섬 전체 — 리스트, retractor, 옵저버,
userdata — 가 한꺼번에 회수 가능해지고 **retractor는 한 번도 불리지 않습니다**. 이건
teardown이 아니라 메모리 해제입니다. 계약상 `Destroy`는 retract를 부르지 않습니다.

명시적으로 자리를 비우는 경로는 이것과 전혀 다르며, 한 줄짜리가 아닙니다.
`rawUnmount`는 그 자리의 길이 옵저버를 풀고 → 소유권을 놓고(`releaseOwner`) →
`nativeExtract`로 요소를 살린 채 트리에서 빼내고(중첩 Slot이면 unmount 트리 걷기)
→ 요소 배열·역맵·부기 splice를 정리합니다. 물리 조작은 그 여러 단계 중 하나일 뿐입니다.
