---
title: "에러 코드 — Roblox: Tween·Animate"
description: "Tween/Animate가 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0214

`Animate: expected an options table (Animate{ Time = ... })` — `quad-roblox/src/Animate.luau`

- **언제**: `q.Animate(info)`의 `info`가 테이블이 아닐 때. 리터럴 옵션은 `Animate(info)` 호출 시점에 즉시 검증되고, `State`로 준 옵션은 실행할 때마다 풀려서 그때 검증됩니다.
- **고치려면**: `q.Animate{ Time = ... }` 모양으로 테이블을 넘기세요.
- **참고**: [`q.Animate(info)`](/reference/roblox/06-tween-animate/#qanimateinfo)

### Quad0227

`Tween:Mapped: fn must be a function (got {typeof(fn)})` — `quad-roblox/src/Tween.luau`

- **언제**: `tween:Mapped(fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 목표 값을 받아 새 목표 값을 돌려주는 함수를 넘기세요.
- **참고**: [`tween:Mapped(fn)`](/reference/roblox/06-tween-animate/#tweenmappedfn)
