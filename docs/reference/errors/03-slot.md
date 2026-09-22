---
title: "에러 코드 — Slot"
description: "Slot CRUD·:List·:Single·dispose가 던지는 에러"
---
# [레퍼런스] 에러 코드 — Slot

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0140

`Slot: destroyed Slot cannot be mounted` — `quad-base/src/Slot/Handler.luau`

- **언제**: 이미 파괴된 `Slot`을 부모의 숫자 키 자리에 놓아 마운트하려 할 때 — `claimOwnerAt`/`bindLifetime`이 커밋되기 전에 걸러집니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만들어 놓으세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0141

`Slot: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Slot/Handler.luau`

- **언제**: `Slot`을 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때.
- **고치려면**: `Slot`은 부모의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [Slot](../core/06-slot.md)
