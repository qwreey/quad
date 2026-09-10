---
title: "05. 움직이게 하기 — Animate와 Tween"
description: "State에 Animate를 얹거나 Compute 안에서 Tween 값을 만들어, 카운터 라벨의 색이 부드럽게 넘어가게 합니다"
---
# [시작하기] 05. 움직이게 하기 — `Animate`와 `Tween`

> **대상 독자**: [04. 컴포넌트로 쪼개기](./04-components.md)를 끝낸 개발자
> **목표**: 색이 툭 튀지 않고 부드럽게 넘어가게 만들기

`TweenService:Create`를 직접 부를 필요는 없습니다. 방법이 둘 있고, 둘 다 `Counter` 안의 코드 몇 줄만 고칩니다.

---

## 방법 A: `:Apply(q.Animate { ... })`

`Animate`는 State에 `:Apply`로 얹는 팩토리입니다. 원래 State의 값이 바뀔 때마다, 그 값을 `Tween` 값 래퍼로 감싼 새 State를 만들어 줍니다.

**하나.** `Counter` 안, `countText` 바로 아래에 목표 색 State를 하나 더 만듭니다.

```luau
    -- 짝수일 때 하늘색, 홀수일 때 흰색
    local numberColor = count:Compute(function(c)
        return if c:Get() % 2 == 0
            then Color3.fromRGB(0, 200, 255)
            else Color3.fromRGB(255, 255, 255)
    end)
```

**둘.** 숫자 라벨의 `TextColor3 = Color3.fromRGB(255, 255, 255),` 한 줄을 이렇게 바꿉니다.

```luau
        TextColor3 = numberColor:Apply(q.Animate { Time = 0.3, Style = Enum.EasingStyle.Quad }),
```

**실행하면** 버튼을 누를 때마다 글자 색이 0.3초에 걸쳐 넘어갑니다. 화면에 처음 나타날 때는 애니메이션 없이 그 색으로 바로 찍힙니다.

`Animate`의 옵션(`Time`/`Style`/`Direction`/`Override`/`CanAnimate` …)은 리터럴이어도 State여도 됩니다. State를 넣으면 **그 옵션이 바뀐 것만으로는 재계산되지 않고**, 다음번 값 변경 때 최신 옵션이 반영됩니다. `CanAnimate`를 생략하면 항상 애니메이션하고, `false`면 보간 없이 값이 그대로 나갑니다(모션 줄이기 설정을 꽂는 자리).

---

## 방법 B: `q.Tween { ... }` 값 래퍼

`Animate`가 만들어 주는 것이 바로 이 `Tween` 값입니다. **`Tween`은 상태 노드가 아니라 값 래퍼입니다** — 반응 그래프 안에 사는 애니메이션 노드가 아니라, State가 내놓는 값을 감싸 "이 목표로 보간해 달라"고 프로퍼티 핸들러에 전달하는 불변 값입니다. 값마다 시간이나 스타일을 다르게 주고 싶으면 `:Compute` 안에서 직접 만들면 됩니다.

```luau
        TextColor3 = count:Compute(function(c)
            local n = c:Get()
            local isMilestone = n > 0 and n % 10 == 0

            -- 프로퍼티 핸들러가 알아보는 불변 값 래퍼
            return q.Tween {
                Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
                Time = if isMilestone then 0.6 else 0.2,
                Style = Enum.EasingStyle.Quad,
                Override = "Cancel", -- "Cancel" 또는 "Finish"; 생략하면 이 필드는 비어 있고 소비 측이 Cancel로 처리한다
            }
        end),
```

**실행하면**(0에서 시작한 카운터 기준) 1~9회 클릭에는 아무 변화가 없다가, 10회째에 금색으로 0.6초 동안 넘어갑니다.

알아둘 것 넷:

- **`Value`는 plain 값이어야 합니다** — State를 넣을 수 없습니다. 반응성은 `Tween`을 감싼 State가 담당합니다.
- **처음 설정될 때는 트윈이 걸리지 않고 값이 바로 찍힙니다.** 이미 값이 있는 프로퍼티가 바뀔 때부터 엔진 트윈이 만들어집니다.
- **목표 `Value`가 이전과 같으면 새 트윈을 만들지 않습니다.** 위 예제에서 1~9회 클릭은 목표가 계속 흰색이라 트윈이 0개이고, 10회째에 금색으로 바뀔 때 하나 생깁니다. 같은 값이어도 매번 다시 재생하고 싶으면 `Dedup = false`를 넣으세요.
- **목표가 다르면 진행 중이던 트윈을 정리하고 새로 겁니다.** `Override = "Cancel"`(기본)은 지금 보간된 값에서 이어 새 트윈을 시작하고, `"Finish"`는 이전 목표값으로 먼저 스냅한 뒤 새 트윈을 시작합니다.

---

## 어느 쪽을 쓰나

- 값마다 옵션이 같다면 **방법 A** — 계산은 계산대로 두고 애니메이션만 얹으므로 읽기 쉽습니다.
- 값에 따라 시간·스타일이 달라져야 하면 **방법 B** — 옵션을 계산 안에서 정할 수 있습니다.

`Tween` 팔이 있는 프로퍼티 타입은 정해져 있습니다 — `number`·`boolean`·`UDim`·`UDim2`·`Vector2`·`Vector3`·`Color3`·`CFrame`·`Rect`. 그 밖의 타입(`Enum.*`, `string`, Instance 참조 등)의 프로퍼티에 `Tween`을 넣으면 타입 에러입니다.

---

## 더 알고 싶다면

- [레퍼런스: `Tween`과 `Animate`](../reference/roblox/06-tween-animate.md) — 옵션 전부, 검증 에러 문구, 프로퍼티에서의 3-상태 동작
- [05. 디자인 토큰과 테마 전환](../how-to/05-theme-and-dynamic-styling.md) — 테마 색을 토큰으로 두고 전환에 애니메이션 얹기

---

## 다음 단계
- [06. 정리 — 방금 겪은 것에 이름 붙이기](./06-mental-models.md)
