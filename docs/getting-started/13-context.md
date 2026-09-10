---
title: "11. 층을 건너 값 넘기기 — q.Context"
description: "값 여러 개를 가방 하나로 묶어, 중간 컴포넌트가 안에 뭐가 들었는지 모른 채 아래로 넘기게 합니다"
---
# [시작하기] 11. 층을 건너 값 넘기기 — `q.Context`

> **대상 독자**: [10. 목록 만들기](./10-lists.md)를 끝낸 개발자
> **목표**: 진입점에서 만든 값을 중간 층이 모르는 채로 말단 컴포넌트까지 내려보내기

값은 props로 내리는 게 기본입니다. 다만 층이 깊어지면 중간 컴포넌트들이 자기가
쓰지도 않는 값을 계속 받아 넘겨야 합니다. 지금 우리 화면이 딱 그 모양입니다 —
진입점 → `CounterBoard` → `Counter`. 강조 색을 `Counter`가 쓰게 하려고
`CounterBoard`에 `Accent`를 받게 하고 싶지는 않습니다.

`q.Context`는 **값 여러 개를 가방 하나로 묶어** 넘기는 도구입니다. 중간 층은
가방만 넘기고, 안에 뭐가 들었는지는 몰라도 됩니다.

---

## 1. 열쇠 하나와 가방 하나

`Provider`는 가방 안에서 값을 찾을 **열쇠**입니다. 담는 쪽과 꺼내는 쪽이 **같은 열쇠**를 봐야 하니, 열쇠는 둘 다 require할 수 있는 모듈에 둡니다.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/Theme
const q = require("./Quad")

return {
    Provider = q.Context.Provider("Theme"),
}
```

진입점에서 가방을 만들어 값을 담고, 화면에 같이 넘깁니다.

```luau
-- (Main.client.luau 계속)
const Theme = require("@game/ReplicatedStorage/Client/UI/Theme")

const ctx = q.Context():Set(Theme.Provider, {
    Accent = Color3.fromRGB(0, 162, 255),
})

const board = CounterBoard { Rows = rows, Ctx = ctx }   -- ← 가방을 같이 넘긴다
board.Parent = screen
```

---

## 2. 중간 층은 모른 채 넘긴다

`CounterBoard`가 바꿀 곳은 **한 줄**입니다. `props.Ctx`를 읽지도, 열지도 않고 `Counter`에 그대로 건네기만 합니다.

```luau
-- … (CounterBoard.luau) updateFn의 마지막 갈래를 이렇게 고칩니다
        return Counter {
            Label = item.Label,
            Start = item.Start,
            Ctx = props.Ctx,          -- ← 이 한 줄만 추가. 안에 뭐가 들었는지는 모른다
        }, ud
```

`CounterBoard`는 `Theme`을 require하지도, 그 열쇠 이름을 알지도 **못합니다.** 강조 색이 하나 더 늘든 폰트가 들어오든 이 파일은 그대로입니다 — 그것이 이 도구가 줄여 주는 비용입니다.

---

## 3. 말단이 자기 열쇠로 연다

`Counter`에서 색을 꺼내 씁니다. 여기서 바뀌는 것은 세 줄입니다 — 열쇠를 가져오는 `require` 한 줄, 가방을 여는 한 줄, 그리고 색을 쓰는 한 줄.

```luau
-- … (Counter.luau) 파일 머리에 한 줄
const Theme = require("./Theme")

return function(props)
    const theme = props.Ctx:Get(Theme.Provider)   -- ← 내 열쇠로 내 값만 꺼낸다
    const count = q.Source(props.Start or 0)

    -- …중간 생략…

        D.TextButton {
            BackgroundColor3 = theme.Accent,      -- ← 리터럴 대신 가방에서 온 색
            Text = "+ 1",
            -- …나머지 생략…
        },
    -- …생략…
end
```

**실행하면** 목록의 카운터 전부가 가방에 담아 둔 강조 색으로 칠해집니다. 진입점에서 `Accent` 하나만 바꾸면 전부 따라 바뀌고, 그 사이의 `CounterBoard`는 아무것도 하지 않았습니다.

여기서 중요한 것은 **가방도 손으로 넘긴다**는 점입니다. React의 Context처럼 트리를 거슬러 올라가 값을 찾아 주는 조회는 quad에 없습니다 — 줄어드는 것은 "중간 층이 알아야 할 **이름**의 수"이지, 넘기는 행위 자체가 아닙니다.

그래서 넘기는 걸 빠뜨리면 그 자리에서 드러납니다. `props.Ctx`가 아예 `nil`이면 `nil:Get(...)`이 되어 quad의 에러가 아니라 평범한 Lua 에러(`attempt to index nil with 'Get'`)가 납니다.

---

## 4. 알아 둘 것 셋

- `q.Context.Provider(name?)`가 돌려주는 것은 **테이블 신원 키**입니다 — 모듈 사이에 문자열 충돌이 없고, 같은 이름을 두 번 줘도 서로 다른 키입니다. 이름은 에러 메시지용 선택 인자입니다.
- `:Set`은 **가방 자신을 바꾸고** 자기를 돌려줍니다(체이닝). 불변 복제 API는 없으니, 서브트리용으로 확장하려면 만드는 쪽이 먼저 복사해야 합니다.
- `:Get`은 없는 키에 에러를 내고, `:Peek`은 `nil`을 돌려줍니다.

```
Context:Get: no value for Provider(Locale) — the creator of this Context did not :Set it (use :Peek to test)
```

<details>
<summary><strong><code>ctx:Get(...)</code>의 타입은 어디서 오나요?</strong></summary>

`Provider<T>`의 `T`는 값에 없는 팬텀이라, **키를 만드는 자리에서 한 번** 적어 주면 그 뒤로는 `:Get`이 알아서 추론됩니다. 위 `Theme` 모듈에 타입까지 같이 두면 됩니다.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/Theme (--!strict)
const q = require("./Quad")

export type Theme = { Accent: Color3 }

return {
    Provider = q.Context.Provider("Theme") :: q.Provider<Theme>,
    -- 캐스트 대신 명시적 타입 인자도 됩니다
    -- Provider = q.Context.Provider<<Theme>>("Theme"),
}
```

`q.Provider<Theme>`는 [01장](./01-setup.md) 설정 모듈의 `export type Provider<T> = QuadTypes.Provider<T>` 줄에서 옵니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Context` / `Provider`](../reference/sugar/01-context.md) — 타입을 붙이는 두 방법, 에러 문구, 가방의 수명
- [05. 디자인 토큰과 테마 전환](../how-to/05-theme-and-dynamic-styling.md) — 토큰을 아래로 내리는 두 방법
