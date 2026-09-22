---
title: "에러 코드 색인"
description: "quad가 던지는 모든 에러는 QuadNNNN 식별자로 시작합니다 — 번호로 찾는 설명 페이지의 입구"
---
quad가 던지는 모든 에러 메시지는 **`QuadNNNN`** 식별자로 시작합니다 — Luau가 붙이는 `파일:줄:` 접두 바로 뒤, 첫 토큰입니다.

```
Main.client.luau:12: Quad0042 Slot:List: duplicate key "a"
```

- **번호는 한 번 붙으면 바뀌지 않고 재사용하지 않습니다.** 문구는 바뀔 수 있으니 검색·분기는 번호로 하세요(`Fallback`의 `err`가 문자열일 때 `string.match(err, "Quad%d%d%d%d")`).
- 번호에 뜻은 없습니다 — 층은 메시지의 **주어**(`Slot:List:`·`Tween:`…)가 말해 주고, 아래 페이지는 그 층별로 묶여 있습니다.
- 엔진(Roblox)이 내는 에러에는 번호가 없습니다 — 번호가 없으면 quad 밖에서 난 것입니다.

| 페이지 | 층 |
|---|---|
| [반응형 코어](/reference/errors/01-core-reactive/) | `Source`/`State`/`Store`/`Blocker`/`Context`/`Operator`/`Debounce`·`Throttle`/`Gate` |
| [디스패치와 장부](/reference/errors/02-dispatch-bookkeeping/) | `Dispatch`/`Bookkeeping`/`Modifier`/`None`/핸들러 계약 |
| [Slot](/reference/errors/03-slot/) | `Slot` CRUD·`:List`·`:Single`·`dispose` |
| [Ref·Observer·Effect·훅](/reference/errors/04-ref-observer-effect/) | `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/생명주기 훅/`bindLifetime` |
| [Tag·Attr](/reference/errors/05-tag-attr/) | `Tag`/`Attr`/`AttrKey`/타입드 Attr |
| [모듈·백엔드 계약](/reference/errors/06-module-backend/) | `UseProvider`/플러그인/`Brand`/`ModuleIdentity`/미설치 op 스텁/`Relate`/`Claim`(base) |
| [Roblox — Declaration·Claim·핸들러](/reference/errors/07-roblox/) | `D.*`/`Mapper`/`Claim`/`Property`/`Event`/`OnChange`/`Out`/숏핸드 |
| [Roblox — Tween·Animate](/reference/errors/08-roblox-tween/) | `Tween`/`Animate` |
| [슈거](/reference/errors/09-sugar/) | `Fallback`/`Traceback`/`Version` 등 그 밖의 슈거 |

번호와 문서의 정합은 `scripts/error-codes.py`가 지킵니다(소스의 모든 번호에 절이 있어야 하고, 번호는 유일해야 합니다).
