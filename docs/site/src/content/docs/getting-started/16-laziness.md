---
title: "16. 값은 언제 흐르나 — 게으름 한 번에 보기"
description: "지금까지 겪은 여섯 자리(파이프·Observer·Effect·Slot:List·Animate 옵션·Blocker)가 언제 도는지를 한자리에서 대조합니다"
---
> **대상 독자**: [15. 흐름을 잠시 막기](/getting-started/15-blocker/)까지 따라온 개발자
> **목표**: "이 코드는 언제 도나"라는 질문 하나로 앞의 열다섯 장을 다시 훑기

quad에는 관통하는 성질이 하나 있습니다. **밀어 넣지 않고, 필요할 때 당겨 온다.**
03장에서 `count:Set`이 "바뀌었다"를 알릴 뿐이라고 했던 그 이야기입니다. 여기서 그
성질이 앞의 장들에서 각각 어떤 모습이었는지 한자리에 모아 봅니다. 새로 배우는
API는 없습니다.

---

## 한눈에

| 어디서 | 언제 도나 |
|---|---|
| **`:Compute` 파이프**(03) | 끝에서 **읽는 쪽이 있을 때**. 아무도 안 읽으면 아예 안 돈다 |
| **`:Observer`**(07) | 등록하는 그 자리에서 한 번. 살아나기 전의 변경은 **보류**됐다가 살아날 때 한 번 |
| **`q.Effect`**(07) | **만드는 그 자리에서 한 번**(파이프와 반대) |
| **`Slot:List`**(12) | 마운트될 때, 그리고 데이터가 바뀔 때. 한 사이클이 **한 배치** |
| **`Animate` 옵션 State**(14) | 옵션이 바뀐 것만으로는 안 돈다. **다음 값 변경** 때 최신 옵션이 쓰인다 |
| **`Blocker`**(15) | 막는 동안 신호는 게이트에 쌓이고 값은 최신. `:Off()`에 **한 번** 통지 |

---

## 1. 파이프는 컨베이어 벨트가 아닙니다

컨베이어 벨트라면 물건을 올리는 순간 반대편으로 밀려갑니다. 파이프는 그렇지 않습니다 — **끝이 막혀 있으면(아무도 읽지 않으면) 아무것도 흐르지 않습니다.**

```luau
-- (이 장의 예제들은 앞 장들과 별개로 돌려 보는 짧은 조각입니다)
const count = q.Source(0)

const countText = count:Compute(function(c)
    print("파이프가 돌았다")
    return `카운트: {c:Get()}`
end)

count:Set(1)
count:Set(2)
```

**실행하면** 아무것도 찍히지 않습니다. `:Set`을 두 번 했는데도 파이프 함수가 돈 횟수는 **0번**입니다. `Text = countText`로 꽂아 화면이라는 출구가 생겨야 비로소 한 번 돌고, 그 뒤로 `count:Set`마다 한 번씩 돕니다.

<details>
<summary><strong>한 원천이 두 경로로 들어오면 두 번 계산되나요?</strong></summary>

아닙니다. 원천이 한 번 움직였을 때 계산은 **한 번만** 돕니다 — 신호가 몇 갈래로 도착하든, 실제 계산은 읽는 쪽이 값을 요구할 때 한 번이기 때문입니다.

```luau
const n = q.Source(1)
const doubled = n:Compute(function(s) return s:Get() * 2 end)

local calls = 0
const total = n:Compute(function(s, previous, d)
    calls += 1
    return s:Get() + d:Get()
end, doubled)                       -- n으로부터 직접 + doubled를 거쳐 두 경로

const label = D.TextLabel { Text = total:Compute(function(s) return tostring(s:Get()) end) }
print(calls, label.Text)  --> 1   "3"

n:Set(5)
print(calls, label.Text)  --> 2   "15"
```

</details>

---

## 2. `Observer`와 `Effect`는 "살아나기"를 기다린다

`:Observer(fn)`은 등록하는 그 자리에서 한 번 발화하고(초기값 반영을 따로 적을 필요가 없습니다), `q.Effect`는 아예 **만드는 그 자리에서** 한 번 돕니다. 둘 다 그 뒤로는 **살아나야** 계속 받습니다 — 숫자 키 자리에 넣어 인스턴스에 매달리거나, `:Subscribe()`를 부르거나.

살아나기 전의 변경은 버려지지 않고 **보류**됐다가, 살아나는 순간 최신값으로 재생됩니다.

<details>
<summary><strong>보류된 변경이 여러 번이면 여러 번 재생되나요?</strong></summary>

한 번입니다. 몇 번이 밀렸든 살아나는 시점에 최신값으로 정확히 한 번입니다.

```luau
local log = {}
const hp = q.Source(100)

const observer = hp:Observer(function(target)
    table.insert(log, target:Get())
end)
print(#log)          --> 1   (등록 즉시 1회)

hp:Set(80)
hp:Set(60)
print(#log)          --> 1   (아직 살아나지 않았다 — 보류)

observer:Subscribe()
print(#log, log[2])  --> 2   60   (보류분 1회 재생, 최신값)
```

</details>

`Effect`가 파이프와 정반대로 만들자마자 도는 이유는 같은 원칙의 뒷면입니다. 파이프는 **읽는 쪽**이 있어야 값이 필요해지지만, 부수 효과에는 읽는 쪽이 없습니다 — 로그를 찍거나 연결을 거는 그 일 자체가 목적이라, 미룰 기준이 아예 없습니다. 그래서 스스로 시작합니다.

---

## 3. `Slot:List`는 사이클 단위

재조정은 **마운트되는 시점**과 그 뒤로 **데이터가 바뀔 때마다** 돕니다. 12장의 목록에 `updateFn` 호출 수를 세는 카운터를 넣어 보면 이렇습니다.

```luau
-- (12장의 목록에 updateFn 호출 수를 세는 카운터를 넣었을 때)
print(updates)   --> 0   (:List를 걸어만 뒀을 때 — 아직 마운트 전)

const board = D.Frame { slot }
print(updates)   --> 2   (키 둘)

rows:Set({ { Id = "a" }, { Id = "b" }, { Id = "c" } })
print(updates)   --> 5   (a·b·c 세 번 — a·b는 prev를 돌려받는 싼 경로)
```

**실행하면** 마운트 전에는 `updateFn`이 한 번도 불리지 않습니다. 목록 역시 "데이터를 넣었다"가 아니라 "어딘가에서 그려질 때" 처음 돕니다. 한 사이클 안에서 `updateFn`은 키마다 한 번씩 불리고(사라진 키에는 `q.KeyGone`으로 한 번 더), 물리 반영과 부기 재계산은 그 사이클 **끝에 한 번**으로 묶입니다.

---

## 4. `Animate`의 옵션 State는 의존성이 아닙니다

`:Apply(q.Animate { Time = someState })`처럼 옵션 자리에 State를 넣을 수 있습니다. 그런데 **그 옵션이 바뀐 것만으로는 아무 일도 일어나지 않습니다** — 애니메이션을 다시 돌릴 이유가 없기 때문입니다. 최신 옵션은 **다음번 값 변경** 때 반영됩니다.

```luau
-- (14장의 Animate 옵션 자리에 State를 넣었을 때)
const time = q.Source(0.3)
const animated = target:Apply(q.Animate { Time = time })
const box = D.TextLabel { TextColor3 = animated }

time:Set(1.0)     -- 엔진 트윈이 새로 생기지 않는다
alpha:Set(1)      -- 여기서 비로소 트윈이 하나 생기고, Time은 1.0이 쓰인다
```

같은 결의 규칙이 하나 더 있습니다. 프로퍼티 자리에 도착한 `Tween`의 목표값이 이전과 같으면 새 트윈을 만들지 않습니다(14장의 1~9회 클릭이 그랬습니다). **필요 없는 일은 하지 않는다**가 여기서도 그대로입니다.

---

## 5. `Blocker`는 신호를 모아 뒀다가 한 번에

15장의 게이트는 같은 성질의 다른 쪽 얼굴입니다. **막는 동안 값은 이미 최신인데 통지만 쌓여 있고**, 푸는 순간 그 배치가 한 번의 통지로 나갑니다. 15장의 파이프 안에 호출 수를 세는 카운터를 넣어 보면 이렇습니다.

```luau
-- 게이트 없이 count와 unit을 같이 바꾸면
print(runs)          --> 3   (마운트 1 + :Set 두 번)

-- 같은 구간을 blocker:On()/Off()로 감싸면
print(runs)          --> 2   (마운트 1 + 푸는 순간 1)
```

읽는 쪽이 값을 요구할 때 계산한다는 원칙이 여기서도 그대로입니다 — 통지를 미뤄도 값이 낡지 않는 이유가 그것입니다. 15장의 "일시정지" 버튼에서 화면이 멈춰 있는 동안에도 게이트된 `shown`의 `:Get()`이 최신을 돌려줬던 게 그래서입니다.

---

## 왜 이렇게 만들었나

UI 프레임워크가 값을 밀어 보내면, 아무도 쓰지 않는 계산이 데이터가 움직일 때마다 전부 돕니다. quad는 반대로 **화면(과 부수 효과)이 요구한 것만** 거슬러 올라가 계산합니다. 대가도 있습니다 — **파이프 함수는 순수해야 합니다.** 언제 몇 번 돌지는 읽는 쪽이 정하므로, 계산 함수 안에서 바깥 상태를 고치면 그 시점을 예측할 수 없습니다. 바깥을 건드리는 일은 `Observer`나 `Effect` 쪽에 두세요.

그 게으름을 싸게 유지하려면 "무엇이 낡았는지"를 아주 빠르게 판정할 수 있어야 합니다. 그 판정을 위한 부기가 quad 안쪽의 상당 부분이고, 이 페이지에서 본 규칙들은 전부 그 하나의 설계에서 나온 결과입니다. **우리는 이렇게 만들었습니다** — 그 안쪽이 궁금해지면 Quadnomicon이 그 이야기입니다.

여기까지면 만들기 시작하기에 충분합니다. 손에 익힐 패턴이 필요하면 실전 레시피의 [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/)부터 읽으시면 되고, 뭔가 어긋나면 레퍼런스에서 그 타입의 페이지를, 왜 그렇게 도는지가 궁금해질 때만 Quadnomicon을 펴시면 됩니다.

---

## 더 알고 싶다면

- [레퍼런스: `State`](/reference/core/03-state/) — `:Get`의 lazy 계산과 수렴 규칙
- [레퍼런스: `Observer` / `Effect`](/reference/core/05-observer-effect/) — 살아나는 두 경로, 보류와 재생
- [Quadnomicon Vol. 1](/quadnomicon/01-revision-and-epochmap/) — 무효화가 어떤 부기 위에서 도는지
