---
title: "Fallback / Traceback"
description: "컴포넌트 에러 격리 경계 — 시그니처, err: any 계약, 회수되지 않는 부분 트리"
---
컴포넌트 함수 하나를 감싸서, 그 안에서 던져도 호출자까지 번지지 않고 **대체 결과**를 돌려주게 합니다. `pcall` / `xpcall`+`debug.traceback` 위의 순수 함수입니다.

이 페이지의 심볼: [`q.Fallback(base, onError)`](#qfallbackbase-onerror) · [`q.Traceback(base, onError)`](#qtracebackbase-onerror)

`quad-base`에 있으므로 백엔드와 무관하게 존재합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 공통 계약

- 돌려주는 것은 **원본과 같은 인자를 받는 함수**입니다. 결과 타입은 `Ok | Err` — 성공 결과와 대체 결과의 유니언이라, 둘을 같은 타입으로 맞춰두면 호출부가 깔끔해집니다.
- **`err`는 `any`입니다.** Luau `error()`는 임의의 값을 던질 수 있고 이 층은 그걸 가공하지 않습니다 — 문자열이라고 가정하지 마십시오. 던진 값이 테이블이면 테이블 그대로 옵니다. 문자열이면 Luau가 붙인 위치 접두사도 벗기지 않습니다(`error(msg, 0)`로 던졌다면 접두사 없이 옵니다).
- **돌려주는 값은 하나입니다.** 안쪽이 여러 값을 돌려줘도 `pcall`/`xpcall` 경계에서 첫 값만 남습니다.
- `base`나 `onError`가 함수가 아니면 감싸는 그 줄에서 던집니다.

```
Fallback: base must be a function (got number)
Traceback: onError must be a function (got string)
```

:::caution
**알려진 구멍: 던지기 전에 만들어진 부분 트리는 회수되지 않습니다.**
예외가 나기 전까지 이미 생성된 인스턴스들은 자기 앵커로 스스로를 붙들고 있어서, 이 경계가 그것들을 정리해주지 않습니다. 대체 UI를 띄우더라도 그 잔재는 남습니다.
:::

---

## `q.Fallback(base, onError)`

**시그니처**

```luau
Fallback: <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any) -> Err) -> (A...) -> Ok | Err
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `base` | `(A...) -> Ok` | 감쌀 함수(보통 컴포넌트) |
| `onError` | `(err: any) -> Err` | 던졌을 때 대체 결과를 만드는 함수 |

**반환** — `base`와 같은 인자를 받고 `Ok | Err`를 돌려주는 함수.

**동작** — `pcall(base, ...)`입니다. 성공하면 결과를 그대로, 실패하면 `onError(err)`의 결과를 돌려줍니다. 트레이스백은 뜨지 않습니다 — 필요하면 `Traceback`을 쓰십시오.

## `q.Traceback(base, onError)`

**시그니처**

```luau
Traceback: <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any, trace: string) -> Err) -> (A...) -> Ok | Err
```

**인자** — `base`는 같고, `onError`가 `(err, trace)` 두 인자를 받습니다.

**동작** — `xpcall` 핸들러 안에서, 즉 **던진 자리에서** 트레이스백을 뜹니다. `trace`는 항상 문자열입니다. 정상 경로에는 아무 비용도 붙지 않습니다.

---

## 예제

```luau
local function ProfileCard(props: { Name: string }): Instance
    return D.TextLabel { Text = props.Name }
end

local SafeProfileCard = q.Traceback(ProfileCard, function(err: any, trace: string): Instance
    warn("ProfileCard 렌더링 실패:", err, "\n", trace)
    return D.Frame {
        BackgroundColor3 = Color3.fromRGB(80, 20, 20),
        D.TextLabel {
            Text = "프로필을 불러올 수 없습니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
        },
    }
end)

local card: Instance = SafeProfileCard({ Name = "q" })
```

---

## 관련

- [디버깅과 문제 해결](/how-to/09-debugging-and-troubleshooting/) — 에러가 어느 줄을 blame하는지 읽는 법
- [정적 grep 가능성과 에러 아키텍처](/quadnomicon/11-static-grepability-and-error-architecture/) — 이 경계가 왜 메시지를 가공하지 않는가
