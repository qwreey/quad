---
title: "14. 움직이게 하기 — Tween과 Animate"
description: "값을 Tween 래퍼로 감싸 프로퍼티에 흘려 보간을 직접 만들고, 그 위에 얹은 :Apply(q.Animate) 슈거를 씁니다"
---
# [시작하기] 14. 움직이게 하기 — `Tween`과 `Animate`

> **대상 독자**: [13. 층을 건너 값 넘기기](./13-context.md)를 끝낸 개발자
> **목표**: 색이 툭 튀지 않고 부드럽게 넘어가게 만들기

`TweenService:Create`를 직접 부를 필요는 없습니다. 프로퍼티로 흘려보내는 **값**을
살짝 감싸면 됩니다. 먼저 그 감싸는 일을 손으로 해 보고, 그다음에 같은 일을 한 줄로
줄여 주는 슈거를 봅니다.

---

## 1. 직접 해 보기 — `q.Tween { ... }` 값 래퍼

**`Tween`은 상태 노드가 아니라 값 래퍼입니다.** 반응 그래프 안에 사는 애니메이션 노드가 아니라, State가 내놓는 값을 감싸 "이 목표로 보간해 달라"고 프로퍼티 핸들러에 전달하는 불변 값입니다. 그러니 `:Compute` 안에서 그냥 만들어 돌려주면 됩니다.

`Counter` 안, 숫자 라벨의 `TextColor3` 한 줄을 이렇게 바꿉니다.

```luau
-- … (Counter.luau) 숫자 라벨의 TextColor3 한 줄을 이렇게 바꿉니다
        TextColor3 = count:Compute(function(c)
            const n = c:Get()
            const isMilestone = n > 0 and n % 10 == 0

            -- 프로퍼티 핸들러가 알아보는 불변 값 래퍼
            return q.Tween {
                Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
                Time = if isMilestone then 0.6 else 0.2,
                Style = Enum.EasingStyle.Quad,
                Override = "Cancel", -- "Cancel" 또는 "Finish"; 생략하면 소비 측이 Cancel로 처리한다
            }
        end),
```

**실행하면**(0에서 시작한 카운터 기준) 1~9회 클릭에는 아무 변화가 없다가, 10회째에 금색으로 0.6초 동안 넘어갑니다.

값마다 시간이나 스타일을 **다르게** 줄 수 있다는 것이 이 형태의 핵심입니다 — 옵션을 계산 안에서 정하기 때문입니다.

<details>
<summary><strong>왜 1~9회 클릭에는 아무 일도 안 일어나나요?</strong></summary>

- **`Value`는 plain 값이어야 합니다** — State를 넣을 수 없습니다. 반응성은 `Tween`을 감싼 State가 담당합니다.
- **처음 설정될 때는 트윈이 걸리지 않고 값이 바로 찍힙니다.** 화면에 처음 나타나는 순간 진입 애니메이션이 도는 것을 막기 위함이고, 이미 값이 있는 프로퍼티가 바뀔 때부터 엔진 트윈이 만들어집니다.
- **목표 `Value`가 이전과 같으면 새 트윈을 만들지 않습니다.** 위 예제에서 1~9회 클릭은 목표가 계속 흰색이라 엔진 트윈이 **0개**이고, 10회째에 금색으로 바뀔 때 **하나** 생깁니다. 비교 대상은 `Value`뿐이고(`Time`/`Style`은 안 봅니다) 비교는 값 동등입니다. 같은 값이어도 매번 다시 재생하고 싶으면 `Dedup = false`를 넣으세요.
- **목표가 다르면 진행 중이던 트윈을 정리하고 새로 겁니다.** `Override = "Cancel"`(기본)은 지금 보간된 값에서 이어 새 트윈을 시작하고, `"Finish"`는 이전 목표값으로 먼저 스냅한 뒤 새 트윈을 시작합니다.
- **`Tween` 팔이 있는 프로퍼티 타입은 정해져 있습니다** — `number`·`boolean`·`UDim`·`UDim2`·`Vector2`·`Vector3`·`Color3`·`CFrame`·`Rect`. 그 밖의 타입(`Enum.*`, `string`, Instance 참조 등)의 프로퍼티에 `Tween`을 넣으면 타입 에러입니다.

</details>

---

## 2. 편하게 — `:Apply(q.Animate { ... })`

옵션이 값마다 달라질 필요가 없다면, 위 §1이 한 일(값이 바뀔 때마다 그 값을 `Tween`으로 감싸는 것)은 매번 똑같습니다. 그 반복을 대신해 주는 팩토리가 `q.Animate`이고, [11장](./11-functions.md)에서 `q.Operator`를 붙일 때 쓴 그 `:Apply`로 State에 얹습니다.

**하나.** `Counter` 안, `countText` 바로 아래에 목표 색 State를 하나 만듭니다. **여기에는 `Tween`이 없습니다** — 그냥 색을 계산할 뿐입니다.

```luau
-- … (Counter.luau) countText 바로 아래에 이어집니다
    -- 짝수일 때 하늘색, 홀수일 때 흰색
    const numberColor = count:Compute(function(c)
        return if c:Get() % 2 == 0
            then Color3.fromRGB(0, 200, 255)
            else Color3.fromRGB(255, 255, 255)
    end)
```

**둘.** 라벨의 `TextColor3` 자리에 그 State를 꽂되, `:Apply`로 애니메이션을 얹습니다.

```luau
-- … (Counter.luau) 숫자 라벨의 TextColor3 자리
        TextColor3 = numberColor:Apply(q.Animate { Time = 0.3, Style = Enum.EasingStyle.Quad }),
```

**실행하면** 버튼을 누를 때마다 글자 색이 0.3초에 걸쳐 넘어갑니다. 화면에 처음 나타날 때는 §1과 마찬가지로 애니메이션 없이 그 색으로 바로 찍힙니다.

`:Apply(q.Animate{…})`가 돌려주는 것은 **State**이고, 그 State가 싣는 값이 §1에서 손으로 만들던 그 `Tween` 값입니다. 계산은 계산대로 두고 애니메이션만 얹는 모양이라 읽기 쉽습니다.

`Animate`의 옵션(`Time`/`Style`/`Direction`/`Override`/`Dedup`/`CanAnimate` …)은 리터럴이어도 State여도 됩니다. State를 넣으면 **그 옵션이 바뀐 것만으로는 재계산되지 않고**, 다음번 값 변경 때 최신 옵션이 반영됩니다. `CanAnimate`를 생략하면 항상 애니메이션하고, `false`면 보간 없이 값이 그대로 나갑니다(모션 줄이기 설정을 꽂는 자리).

---

## 3. 어느 쪽을 쓰나

- 값에 따라 시간·스타일이 달라져야 하면 **§1** — 옵션을 계산 안에서 정할 수 있습니다.
- 값마다 옵션이 같다면 **§2** — 계산과 애니메이션이 분리돼 읽기 쉽습니다.

---

## 더 알고 싶다면

- [레퍼런스: `Tween`과 `Animate`](../reference/roblox/06-tween-animate.md) — 옵션 전부, 검증 에러 문구, 프로퍼티에서의 3-상태 동작
- [05. 디자인 토큰과 테마 전환](../how-to/05-theme-and-dynamic-styling.md) — 테마 색을 토큰으로 두고 전환에 애니메이션 얹기
