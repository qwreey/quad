---
title: "에러 코드 — 모듈·백엔드 계약"
description: "UseProvider/플러그인/Brand/ModuleIdentity/미설치 op 스텁/Relate/Claim(base)이 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0026

`newMapperClass: className must be a non-empty string (got {typeof(className)})` — `quad-base/src/Claim.luau`

- **언제**: `q.newMapperClass(className)`에 넘긴 `className`이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 클래스 이름을 비어 있지 않은 문자열로 주세요.
- **참고**: [`q.newMapperClass(className)`](/reference/roblox/04-claim-mapper/#qnewmapperclassclassname)

### Quad0027

`Claim: mapper descriptor was already used (descriptors are one-shot)` — `quad-base/src/Claim.luau`

- **언제**: 이미 한 번 `q.Claim`에 쓰인 디스크립터(1회용)를 다시 쓰려고 할 때.
- **고치려면**: 디스크립터 값을 저장해 재사용하지 말고, 필요하면 그것을 만드는 호출을 팩토리 함수로 감싸 매번 새로 만드세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0028

`Claim: two mapper descriptors resolved to the same Instance {tostring(inst)} — each child needs exactly one descriptor` — `quad-base/src/Claim.luau`

- **언제**: 서로 다른 두 디스크립터가 해석 결과 같은 Instance를 가리켰을 때 — 한 자식에 매퍼가 두 번 걸린 경우입니다.
- **고치려면**: 자식마다 디스크립터를 하나씩만 두세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0029

`Claim: {tostring(inst)} is already claimed by quad — a Declaration-made or already-Claimed Instance cannot be claimed again (leave it out of the descriptor and drive it separately, or dispose it and rebuild)` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터가 해석한 Instance가 이미 quad에 의해 소유돼 있을 때 — `D.New`로 만들었거나 먼저 `Claim`된 것(루트도 자식도 해당)입니다.
- **고치려면**: 그 자식을 디스크립터에서 빼고 따로 다루거나, `q.dispose`한 뒤 새로 만드세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0030

`Claim: mapper props must be a table (got {typeof(desc._props)})` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터의 props가 테이블이 아닐 때.
- **고치려면**: props에 테이블을 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0031

`Claim: array keys must be positive integers (got {i})` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터 props의 숫자 키(다른 매퍼 디스크립터를 담은 자리) 중 양의 정수가 아닌 것이 있을 때.
- **고치려면**: 숫자 키는 1부터 시작하는 정수로 쓰세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0032

`Claim: no child matched key {tostring(v._key)} under {tostring(inst)} (mapper {tostring(v._className)}) — a child with that name must also be a {tostring(v._className)}` — `quad-base/src/Claim.luau`

- **언제**: 매퍼 디스크립터가 지목한 이름의 자식이 없거나, 이름은 맞는데 그 클래스(`IsA`)가 아닐 때.
- **고치려면**: 템플릿(claim 대상 Instance)에 그 이름·클래스의 자식이 실제로 있는지 확인하세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0033

`Claim: first argument must be an Instance of the installed backend (got {typeof(inst)})` — `quad-base/src/Claim.luau`

- **언제**: `q.Claim(inst, desc)`의 첫 인자가 설치된 백엔드의 Instance가 아닐 때.
- **고치려면**: 실제 Instance를 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)

### Quad0034

`Claim: second argument must be a D.Mapper descriptor` — `quad-base/src/Claim.luau`

- **언제**: `q.Claim(inst, desc)`의 둘째 인자가 `D.Mapper` 디스크립터가 아닐 때.
- **고치려면**: `D.Mapper.<Class>(key)(props)`(또는 `q.newMapperClass`)로 만든 디스크립터를 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)
