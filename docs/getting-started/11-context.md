---
title: "11. 층을 건너 값 넘기기 — q.Context"
description: "값 여러 개를 가방 하나로 묶어 중간 층이 이름을 모른 채 내려보내게 합니다"
---
# [시작하기] 11. 층을 건너 값 넘기기 — `q.Context`

> **대상 독자**: [10. 목록 만들기](./10-lists.md)를 끝낸 개발자
> **목표**: 값 여러 개를 가방 하나로 묶어 깊은 층까지 넘기기

값은 props로 내리는 게 기본입니다. 다만 층이 깊어지면 중간 컴포넌트들이 자기가
쓰지도 않는 값을 계속 받아 넘겨야 합니다. `q.Context`는 그럴 때 **값 여러 개를
가방 하나로 묶어** 넘기는 도구입니다.

---

## 가방 하나 만들어 내려보내기

```luau
const ThemeProvider = q.Context.Provider("Theme")

-- 앱 진입점에서 한 번
const ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 162, 255) })

-- 컴포넌트는 가방을 파라미터로 받아 자기 키만 읽는다
return function(props)
    const theme = props.Ctx:Get(ThemeProvider)
    return D.TextButton {
        BackgroundColor3 = theme.Accent,
        Text = props.Label,
    }
end
```

```luau
Counter { Label = "왼쪽", Start = 0, Ctx = ctx }
```

**실행하면** 버튼 색이 가방에 담아 둔 값으로 칠해집니다.

여기서 중요한 것은 **가방도 손으로 넘긴다**는 점입니다. React의 Context처럼 트리를 거슬러 올라가 값을 찾아 주는 조회는 quad에 없습니다 — 줄어드는 것은 "중간 층이 알아야 할 이름의 수"이지, 넘기는 행위 자체가 아닙니다. 중간 셸 컴포넌트는 `Theme`이 뭔지 모른 채 `props.Ctx`만 그대로 아래로 넘기면 됩니다.

---

## 알아 둘 것 셋

- `q.Context.Provider(name?)`가 돌려주는 것은 **테이블 신원 키**입니다 — 모듈 사이에 문자열 충돌이 없고, 같은 이름을 두 번 줘도 서로 다른 키입니다. 이름은 에러 메시지용 선택 인자입니다.
- `:Set`은 **가방 자신을 바꾸고** 자기를 돌려줍니다(체이닝). 불변 복제 API는 없으니, 서브트리용으로 확장하려면 만드는 쪽이 먼저 복사해야 합니다.
- `:Get`은 없는 키에 에러를 내고, `:Peek`은 `nil`을 돌려줍니다.

```
Context:Get: no value for Provider(Locale) — the creator of this Context did not :Set it (use :Peek to test)
```

<details>
<summary><strong><code>ctx:Get(...)</code>의 타입은 어디서 오나요?</strong></summary>

`Provider<T>`의 `T`는 값에 없는 팬텀이라, **키를 만드는 자리에서 한 번** 적어 주면 그 뒤로는 `:Get`이 알아서 추론됩니다. 캐스트와 명시적 타입 인자 둘 다 됩니다.

```luau
type Theme = { Accent: Color3 }

const ThemeProvider = q.Context.Provider("Theme") :: q.Provider<Theme>
const UserProvider = q.Context.Provider<<{ Name: string }>>("User")
```

첫 형태를 쓰려면 [01장](./01-setup.md)의 설정 모듈에 `export type Provider<T> = QuadTypes.Provider<T>` 한 줄을 더 두면 됩니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Context` / `Provider`](../reference/sugar/01-context.md) — 타입을 붙이는 두 방법, 에러 문구, 가방의 수명
- [05. 디자인 토큰과 테마 전환](../how-to/05-theme-and-dynamic-styling.md) — 토큰을 아래로 내리는 두 방법
