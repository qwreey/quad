---
title: "Fallback / Traceback"
description: "컴포넌트 에러 격리 경계 — 시그니처, err: any 계약, 회수되지 않는 부분 트리"
---
컴포넌트 함수 하나를 감싸서, 그 안에서 던져도 호출자까지 번지지 않고 **대체 결과**를 돌려주게 합니다. `pcall` / `xpcall`+`debug.traceback` 위의 순수 함수입니다.

이 페이지의 심볼: [`q.Fallback(base, onError)`](#qfallbackbase-onerror) · [`q.Traceback(base, onError)`](#qtracebackbase-onerror)

`quad-base`에 있으므로 백엔드와 무관하게 존재합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

---

## 공통 계약

- 돌려주는 것은 **원본과 같은 인자를 받는 함수**입니다. 결과 타입은 `Ok | Err` — 성공 결과와 대체 결과의 유니언이라, 둘을 같은 타입으로 맞춰두면 호출부가 깔끔해집니다.
- **`err`는 `any`입니다.** Luau `error()`는 임의의 값을 던질 수 있고 이 층은 그걸 가공하지 않습니다 — 문자열이라고 가정하지 마십시오. 던진 값이 테이블이면 테이블 그대로 옵니다. 문자열이면 Luau가 붙인 위치 접두사도 벗기지 않습니다(`error(msg, 0)`로 던졌다면 접두사 없이 옵니다).
- **돌려주는 값은 하나입니다.** 안쪽이 여러 값을 돌려줘도 `pcall`/`xpcall` 경계에서 첫 값만 남습니다.
- `base`나 `onError`가 함수가 아니면 감싸는 그 줄에서 던집니다.

```
Quad0099 Fallback: base must be a function (got number)
Quad0100 Traceback: onError must be a function (got string)
```

:::caution
**알려진 구멍: 던지기 전에 만들어진 부분 트리는 회수되지 않습니다.**
예외가 나기 전까지 이미 생성된 인스턴스들은 자기 앵커로 스스로를 붙들고 있어서, 이 경계가 그것들을 정리해주지 않습니다. 대체 UI를 띄우더라도 그 잔재는 남습니다.

**삼킨 예외가 남기는 상태도 그대로입니다.** quad는 사용자 콜백을 감싸지 않으므로, 예외가 지나간 자리의 부기는 복구되지 않은 채입니다 — `Declaration`이 중간에 던지면 그 인스턴스의 배치 게이트가 켜진 채 남고(이후 Slot 자식이 옛 오프셋에 앉음), `:List`의 `updateFn`이나 `slot.Offset` 구독이 던지면 그 Slot·부모의 부기가 멈추며, 정적 자식은 반쯤 지어진 인스턴스에 앉은 채 남습니다([Slot 레퍼런스](/reference/core/06-slot/)의 캐비엇들). 이 경계 안에서 던진 인스턴스·Slot을 **계속 쓰지 마세요** — 대체 UI는 새 인스턴스로 만드세요.

경계 **밖**에서 만들어 안에 넘긴 `Ref`·`PreRef`·`PostRef`도 마찬가지입니다: 던지기 전에 처리된 자리에 놓였다면 반쯤 지어진 인스턴스에 이미 묶여(`Quad0233 bindLifetime: value is already bound to another Instance`) 그대로는 다시 쓸 수 없고, `PostRef`는 pre-pass가 닿은 뒤 던졌으면(던진 항목 뒤 자리도) 발화 없이 소진됩니다(`Quad0069`; 앞 자리 `PreRef` 콜백이 pre-pass 안에서 던진 경우만 뒤 `PostRef`가 살아남습니다). `Ref`는 그 고아 인스턴스(`ref.Value`로 잡힙니다)를 `q.dispose`하면 묶임이 풀려 같은 `Ref`로 다시 부를 수 있습니다(mock 확인, [2026-09-27 기준]); `PreRef`/`PostRef`는 일회용이라 dispose 뒤에도 소진된 채이니 새로 만드세요.
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

- [디버깅과 문제 해결](/how-to/10-debugging-and-troubleshooting/) — 에러가 어느 줄을 blame하는지 읽는 법
- [정적 grep 가능성과 에러 아키텍처](/quadnomicon/11-static-grepability-and-error-architecture/) — 이 경계가 왜 메시지를 가공하지 않는가
