---
title: "13. 흐름을 잠시 막기 — Blocker"
description: "값 여럿을 한 번에 바꿀 때 중간 상태가 새지 않도록 전파를 붙잡아 뒀다가 한 번만 통지합니다"
---
> **대상 독자**: [12. 움직이게 하기](/getting-started/12-animation/)를 끝낸 개발자
> **목표**: 값 여럿을 한 번에 바꿀 때 중간 상태가 화면에 새지 않게 막기

지금까지는 값을 하나씩 바꿨습니다. **둘을 같이 바꿔야 할 때** 무슨 일이 생기는지부터 봅니다.

---

## 1. 값 둘을 같이 바꾸면 화면이 두 번 바뀝니다

카운터에 단위를 붙입니다. 03장에서 `suffix`를 의존으로 넘겼던 그 모양 그대로입니다.

```luau
-- … (Counter.luau) 상태 두 개와 파이프 하나
    const count = q.Source(10)
    const unit = q.Source("점")

    const countText = count:Compute(function(c, prev, u)
        return `{c:Get()} {u:Get()}`
    end, unit)
```

단위를 바꾸는 버튼을 답니다. 10점은 100포인트라 **값과 단위를 같이** 바꿔야 합니다.

```luau
-- … (Counter.luau) 카드의 숫자 키 자리에 이어집니다
        D.TextButton {
            Text = "단위 바꾸기",
            Activated = function()
                const toPoint = unit:Get() == "점"
                count:Set(if toPoint then count:Get() * 10 else count:Get() // 10)
                unit:Set(if toPoint then "포인트" else "점")
            end,
        },
```

**실행하면** 버튼 한 번에 라벨이 `10 점` → `100 포인트`로 갑니다. 그런데 `:Set` 사이를 끊어 보면 이렇습니다.

```
마운트 직후        Text = "10 점"
count:Set(100) 뒤  Text = "100 점"     ← 어느 시점에도 진실이 아닌 중간 상태
unit:Set 뒤        Text = "100 포인트"
```

두 `:Set`이 각각 통지를 냈기 때문입니다. 파이프 함수가 돈 횟수도 마운트 1회 + 버튼 2회 = **3회**입니다.

---

## 2. 통지를 붙잡아 뒀다가 한 번에 — `q.Blocker()`

`Blocker`는 **전파를 잠시 붙잡아 두는 스위치**입니다. 원천과 파이프 사이에 게이트를 끼워 두고 그 스위치로 여닫습니다.

```luau
-- … (Counter.luau) 위 §1의 세 줄을 이렇게 고칩니다
    const blocker = q.Blocker()

    const gatedCount = count:Apply(blocker)
    const gatedUnit = unit:Apply(blocker)

    const countText = gatedCount:Compute(function(c, prev, u)
        return `{c:Get()} {u:Get()}`
    end, gatedUnit)
```

**마지막 줄이 핵심입니다** — 파이프를 `count`가 아니라 `gatedCount`/`gatedUnit` 위에 다시 세워야 합니다. `Blocker`를 만들어 두기만 하거나 `:Apply`의 반환을 버리면 아무것도 막히지 않습니다.

<details>
<summary><strong><code>Blocker</code> 아래에는 뭐가 있나요?</strong></summary>

`state:Gate(setup)`입니다. 게이트는 상류에서 온 통지를 자기 안에 모아 두고, 언제 한 번에 내려보낼지를 `setup`이 돌려준 정책 함수에 맡기는 노드입니다.

`Blocker`는 그 위에 얹힌 **정책 하나**입니다 — "켜져 있으면 모으고, 끄면 흘려보낸다". `state:Apply(blocker)`는 `state:Gate(function(emit) return blocker:Policy(emit) end)`와 정확히 같고, 게이트를 직접 배선하면 다른 정책도 만들 수 있습니다([레퍼런스: `state:Gate(setup)`](/reference/core/03-state/#stategatesetup)).

</details>

버튼은 바꾸는 구간을 `:On()`과 `:Off()`로 감쌉니다.

```luau
-- … (Counter.luau) 단위 바꾸기 버튼의 Activated
            Activated = function()
                blocker:On()
                -- …§1의 본문 세 줄 그대로…
                blocker:Off() -- 여기서 한 번만 통지된다
            end,
```

**실행하면** 라벨은 `10 점`에서 `100 포인트`로 곧바로 넘어가고 `100 점`은 나타나지 않습니다. 파이프 함수가 돈 횟수는 마운트 1회 + 버튼 1회 = **2회**입니다(§1은 3회였습니다).

---

## 3. 화면만 멈추는 "일시정지" 버튼

같은 스위치를 켜 둔 채로 둘 수도 있습니다. 단위는 잠시 잊고 `count` 하나만 보는 라벨로 두겠습니다 — 게이트를 하나 끼우고(`const shown = count:Apply(blocker)` — 라벨은 `shown`을 봅니다) 버튼이 스위치를 토글하게 합니다.

```luau
-- … (Counter.luau) 카드의 숫자 키 자리에 버튼 하나 더
        D.TextButton {
            Text = "일시정지",
            Activated = function()
                if blocker:IsOn() then blocker:Off() else blocker:On() end
            end,
        },
```

**실행하면** 일시정지를 누른 뒤로는 `+ 1`을 아무리 눌러도 라벨이 `카운트: 0`에서 멈춰 있습니다. 다시 누르면 밀린 것이 **한 번에** 최신값으로 반영됩니다 — 세 번 눌렀다면 `카운트: 1`, `2`를 거치지 않고 곧장 `카운트: 3`입니다.

**막는 것은 통지지 값이 아닙니다.** 멈춰 있는 동안에도 값은 최신입니다.

```luau
-- (일시정지를 켜 두고 + 1을 세 번 누른 뒤)
print(label.Text)    --> "카운트: 0"   (화면은 멈춰 있고)
print(shown:Get())   --> 3            (값은 이미 최신이다)
```

<details>
<summary><strong>시간으로 막고 싶으면요?</strong></summary>

"신호가 멎고 0.2초 뒤에 한 번만 통과" 같은 시간 정책은 손으로 여닫는 대신 `q.Debounce` / `q.Throttle`을 쓰면 됩니다. 같은 게이트 위에 얹힌 시간 버전이라 붙이는 방법도 `state:Apply(...)`로 같고, 옵션과 제어 핸들은 [레퍼런스: `Debounce` / `Throttle`](/reference/sugar/03-debounce-throttle/)에 있습니다.

</details>

---

## 4. 알아 둘 것 셋

- **`:OffWithoutEmit()`은 쌓인 것을 버리고 풉니다** — 통지 없이 조용히 끝내고 싶을 때. 버려도 그래프는 망가지지 않습니다(값은 어차피 읽는 시점에 최신입니다).
- **하나의 `Blocker`를 여러 노드에 붙일 수 있습니다.** 위에서도 `count`와 `unit` 두 곳에 같은 스위치를 붙였고, `:Off()` **한 번**이 붙어 있는 게이트 전부를 풉니다.
- **`IsBlocked`는 카운터가 아니라 평범한 불리언입니다.** `:On()`을 두 번 해도 `:Off()` 한 번이면 풀리니, 겹치는 구간이 필요하면 구간마다 `Blocker`를 따로 만드세요.

---

## 더 알고 싶다면

- [레퍼런스: `Blocker`](/reference/core/06-blocker-gate/) — `On`/`Off`/`OffWithoutEmit`/`Policy`, 푸는 도중 다시 잠갔을 때의 동작
- [레퍼런스: `state:Gate(setup)`](/reference/core/03-state/#stategatesetup) — 게이트 계약과 직접 배선
- [레퍼런스: `Debounce` / `Throttle`](/reference/sugar/03-debounce-throttle/) — 같은 게이트 위의 시간 정책
- [03. 긴 목록을 가볍게 그리기](/how-to/03-virtualized-infinite-scroll/) — 스크롤 이벤트 폭주를 `Blocker`로 접는 실전 예
