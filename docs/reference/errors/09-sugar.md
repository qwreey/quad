---
title: "에러 코드 — 슈거"
description: "Fallback/Traceback/Version 등 슈거가 던지는 에러"
---
# [레퍼런스] 에러 코드 — 슈거

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0099

`{name}: base must be a function (got {typeof(base)})` — `quad-base/src/Fallback.luau`

- **언제**: `q.Fallback(base, onError)`/`q.Traceback(base, onError)`을 만들 때 첫 인자 `base`가 함수가 아닐 때. `{name}`은 실제로 부른 쪽 이름(`Fallback`/`Traceback`)입니다.
- **고치려면**: 감쌀 함수(보통 컴포넌트)를 그대로 넘기세요.
- **참고**: [공통 계약](../sugar/05-fallback-traceback.md#공통-계약)

### Quad0100

`{name}: onError must be a function (got {typeof(onError)})` — `quad-base/src/Fallback.luau`

- **언제**: 두 번째 인자 `onError`가 함수가 아닐 때.
- **고치려면**: 던졌을 때 대체 결과를 만드는 함수를 넘기세요.
- **참고**: [공통 계약](../sugar/05-fallback-traceback.md#공통-계약)
