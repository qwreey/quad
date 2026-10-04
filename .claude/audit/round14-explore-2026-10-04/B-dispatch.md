# round14 탐사 B — 디스패치·Slot·부기 최근 변경

> opus 탐사자 원문(2026-10-04, 읽기 전용, 공통 규칙 `round14-explore-2026-10-04/common-rules.md`). 서브에이전트가 파일을 쓰지 않아 메인이 보고 본문을 옮겼다. 결정 아님 — 메인·검증자 판정 전 원문.

## round14 탐사 각도 B — 디스패치·Slot·부기 최근 변경 (기준 HEAD `8592751fd4a320c257b71519fc56d3050af9e306`)

실측은 레포 밖 사본 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-b/`에서 했다(다섯 패키지와 scripts를 `cp -rL`로 복사하고 relink, 사본의 quad-base/src는 HEAD와 diff 없음). 프로브는 그 사본의 quad-roblox/test/fuzz.dispatch.luau(스크래치 사본)(퍼저), quad-roblox/test/probe.brandhint.luau(스크래치 사본), quad-base/test/probe.q85q68.luau(스크래치 사본), quad-base/test/probe.loops.luau(스크래치 사본), quad-base/test/probe.rootslot.luau(스크래치 사본), `probes/nextskip{,2,3}.luau`다. 레포는 고치지 않았다. 무거운 실행은 `choom -n 1000 -- prlimit --data=3221225472`로 돌렸다(예산 3 GiB, 최대 RSS 628 MB). 새 결함은 0건이다. 아래 다섯 항목은 기존 문항에 붙일 재료, 확인 기록, (라) 판정이다.

### 발견 1 — `Quad0076` 꼬리 힌트가 Tween에는 틀린 처방이고 Blocker·AttrKey에는 돌고 도는 처방이다 (기존 Q161의 새 사례 + 이전 결정과 대조 누락)

**상황.** 2026-10-01 `4860221b`가 브랜드 진단을 등록 술어 하나로 바꿨다. 이때 힌트 규칙이 "등록된 술어에 하나라도 걸리면 quad 값 힌트, 안 걸리면 오타·프로바이더 미설치 힌트"가 됐다. 그 결과 프로바이더 브랜드 Tween을 오타 키나 읽기 전용 키에 두면 "숫자(배열) 자리로 옮기라"는 안내를 받는다. Tween이 원래 놓일 자리는 문자 키(프로퍼티)다.

**재현** (`probe.brandhint.luau`, debug 끔·켬 출력 동일):
- `{ Sise = q.Tween{Value=1} }` → `Quad0076 Dispatch: no handler matched key Sise (value: table, brand: Tween) - a quad value at a string key: it belongs in a numeric (array) slot`
- `AbsoluteSize = Tween`과 `Sise = q.Source(Tween)`도 같은 꼬리를 받는다.
- 안내대로 `{ q.Tween{…} }`로 옮기면 `… brand: Tween) - this quad value has no handler at an array position`가 나온다.
- Blocker와 AttrKey는 어느 키에 둬도 같은 순환이 생긴다. 문자 키에서는 "숫자 자리로", 숫자 자리에서는 "핸들러 없음"이다.

**입력 분류.** 오타 키에 놓인 값은 사용자 실수다. 진단 경로 자체는 정의된 사용이다.

**이전 결정.**
- `4860221b` 직전 코드는 round13 Q90 ⑩을 따랐다. 사용자 원문은 *"두개의 방식으로 에러가 날 수 있을 때 보통 그 두 경우를 알려주는데 그게 나을수도"*이고, 원장에는 "문자 키에 브랜드 없는 값·**프로바이더 브랜드 값**이면 두 원인"으로 적혀 있다. 그래서 그때는 Tween이 오타 키에 놓이면 "this key may not be a field … (a typo, a read-only field …)"를 받았다. 이건 맞는 안내였다.
- 2026-10-01 메인 제안(위 힌트 규칙)에 사용자는 *"그렇게 진행하면 될 것 같아"*로 답했다. 하지만 그 제안은 Q90 ⑩의 프로바이더 브랜드 팔을 인용하지 않았다. 원칙 A3에 해당하는 대조 누락이다.
- Blocker·AttrKey의 순환은 `H-567` 때부터 있었다. Context·Provider의 같은 증상은 `H-861`이 이름별 꼬리로 고쳤다.
- 열린 Q161(각 브랜드가 자기 안내를 등록하는 자리)이 정확히 이 부류를 푸는 방향이다.

**문서·spec.** errors/02 `Quad0076`은 지금 규칙을 그대로 적는다("프로바이더 브랜드(`Tween` 등)가 같은 힌트를 받습니다 … 그 밖의 브랜드가 문자 키일 때 '…belongs in a numeric (array) slot'"). 코드와 문서는 일치하고, 메시지는 API가 아니다(D3).

**판정과 처방.** (가)는 아니다. 사용자 결정 둘(Q90 ⑩ 프로바이더 팔, 10-01 규칙)이 Tween 사례에서 충돌한 채 대조 없이 굳은 것이다. 처방은 사용자 결정이 필요하다. Q161 갈래에 "자리가 문자 키인 브랜드(Tween)"와 "어느 키에도 안 놓이는 브랜드(Blocker·AttrKey)"를 사례로 붙이면 된다. Q90 ⑩ 팔을 따로 되살리려면 base/프로바이더 브랜드를 다시 구분해야 하는데, 이건 `4860221b`가 지운 목록을 되살리는 일이라 결정 역전이다. 확신도: 사실 높음.

### 발견 2 — 부기 되감기 한도는 한 패스 안의 모든 구독자 되감기를 합쳐 센다 ((라), 정보)

**상황.** `Quad0267`은 정의된 수렴 고리라도 한 패스에서 서로 독립인 반응이 1만 개를 넘으면 끊는다.

**재현** (`probe.loops.luau`). Offset Observer를 단 섹션 K개를 두고, 각 섹션은 처음 한 번만 자기 spacer에 하나를 넣는다(각자 1회에 수렴). `head:Add(big)` 한 줄로 시작한 한 패스에서:
- K=9000: `noerr acts=9000`
- K=10050: `Quad0267 @…probe.loops.luau:298 acts=10001`. 298행이 `head:Add(big)`이라 blame은 정확하다.

반면 반응이 돌기만 하고 되감기를 일으키지 않으면 걸리지 않는다. gridInsert K=10500(한 패스에 Observer 실행 10501회, 되감기 1회)도, 마운트 때 반응 31498회(gridAlign 10500)도 통과했다.

**비교.** Effect의 `Quad0263`은 Effect 하나의 재실행 루프를 센다. 이건 패스 단위라 단위가 다르다.

**문서.** errors/02 `Quad0267`("1만 번 전까지의 되감기는 정의된 동작"), core/06, CHANGELOG 모두 "되감기 수"로 정확히 적었다.

**판정.** (라). 문서와 일치하고, 한 부모에 Offset 반응 구독자 1만 개 이상은 현실적이지 않다(B1). 사용자가 "Effect와 동일하게"를 고를 때 이 단위 차이가 제시됐는지는 기록에 없다. 참고로만 남긴다. 확신도: 사실 높음, 영향 낮음.

### 발견 3 — 두 Slot이 서로의 `Length`를 보고 상대를 뒤집는 고리도 stack overflow로 끝난다 (기존 Q172의 다른 모양)

**재현** (`probe.loops.luau` `mutualLength_observers`): `NOID ./quad-base/src/Brand.luau:83: stack overflow`. 대조군인 Q172 모양(자기 Length)은 `Brand.luau:104: stack overflow`다.

**메커니즘.** Q172와 같다. 되감기가 아니라 `Length:Set` → CRUD → 중첩 재계산이다.

**같은 모양의 Effect판** (`effect_ownLength`)은 `Quad0263 runs=10000`이다. C4(Effect 자기 의존성 Set의 정의된 경로)와 맞는다.

**판정.** 기존(Q172). Q172 문구가 "자기 Slot"이라 이 상호 모양은 덮지 못한다. 갈래 (a)를 고르면 문구를 "수렴하지 않는 `Length` 고리"로 쓰면 함께 닫힌다. 처방은 Q172 결정에 따른다. 확신도: 높음.

### 발견 4 — `Quad0085`와 `Quad0068`이 한 표에 같이 있으면 어느 ID가 나올지가 해시 순회 순서에 달렸다 ((라))

**재현** (`probe.q85q68.luau`): `{ [1.5]=1, Bar=M, Baz=M }`은 `Quad0068`, `{ [0]=1, Foo=M }`은 `Quad0085`. 동적 여섯 변형은 ID가 섞여 나왔고 blame 줄은 모두 같은 사용자 줄이다. 옛 코드는 따로 돌던 `pairs` 패스가 먼저 돌아 늘 `Quad0085`였다.

**판정.** (라). 두 입력 오류가 모두 실제로 있고, 어느 쪽이든 정확하다. 문서와 spec 어디에도 둘 사이 순서 약속은 없다.

### 발견 5 — 엔진형 에러의 blame ((라) / 기존)

퍼저에서 번호 없는 에러가 quad-roblox 줄을 가리킨 경우가 있었다. `Name = <비문자열>`은 `Handlers/Property.luau:301`의 `Name must be a string`, `[AttrKey] = 테이블/함수`는 `EngineOps.luau:138`의 attribute type 에러다. 이건 mock이 엔진의 대입 에러를 흉내 낸 것이고, core/07 62행과 errors/04 262행이 "mock 관측"으로 이미 적었다 → (라).

희소 구멍 props의 `Quad0023`이 `Bookkeeping.luau:276`(level 1)을 가리키는 것은 기존(Q117 "blame 둘 0023/0024")이다. 입력도 문서상 UB다.

### 확인했고 문제 없음

**(1) debug 끔/켬 동작 동일성** — drive 12,000회(넓은 모드 6,000 + 유효 키 모드 6,000), 시드 고정.
- 입력: 키는 0·-1·1.5·-0.5·2.25·inf, 희소 양수, 실제·오타·읽기 전용·`Parent` 문자 키, AttrKey 키를 섞었다. 값은 29종이다(State·None·nil 구멍·State 안의 State·Slot·Ref 가족·Observer·Effect·Tag·Attr·정상/잘못된 Modifier·Store·Context·Tween·State 안의 Tween 등).
- 마운트가 성공하면 원천마다 무작위 `:Set`을 최대 넷 더 했다.
- 비교한 것: 인스턴스 스냅샷(프로퍼티·자식 순서·태그·속성), 콜백 로그, blame 줄을 포함한 에러 전문.
- 결과: **불일치 0**. debug 경고 줄은 1,086회 나왔고 debug를 끈 쪽에서는 0줄이었다.
- 나온 ID는 `Quad0002·0022·0023·0068·0076·0085·0097·0116·0136·0137·0229`이고 모두 문서에 절이 있다. blame은 위 발견 5의 경우를 빼면 전부 사용자 줄이다.
- 코드로도 확인했다. `debugOnly` 핸들러는 늘 false를 돌려주고 `kindOf`는 순수한 브랜드 조회다. `merged()`는 안정 병합이라 실제 핸들러끼리의 상대 순서가 그대로다.

**(2) `Quad0085`가 잡는 키 집합.** `next(t, #t)`부터의 순회가 옛 `pairs` 패스와 같은 비배열 키를 모두 방문하는지 무작위 표 30만 개로 대조했다(문자 키를 먼저 채워 해시 쪽을 크게 만든 적대적 삽입 순서 10만 개 포함). 놓친 키는 0개다. ±inf도 잡힌다. 희소 양의 정수 키는 예전처럼 잡지 않는다.

**(3) 부기 되감기 한도.**
- spec `lengthoffset` round14 절 네 개의 의도대로 동작한다.
- 수렴 고리는 끊지 않는다: 그리드 정렬 K=100/3000/10500, 삽입 뒤 재정렬 K=100/10500.
- 발산하는 Offset 고리는 모두 `Quad0267`로 멈추고 CRUD 줄을 가리킨다: 중첩 Slot, 다른 호스트 사이, Slot 안쪽, 마운트되지 않은 루트 Slot(마운트할 때 걸림 — 마운트 전 Length 0은 core/06 104행대로), Effect가 Offset을 보는 경우(`runs=10001`).
- Q172와 다른 메커니즘의 비수렴 고리는 찾지 못했다. Length 계열은 모두 중첩 재계산이다(발견 3).

**(4) 매치 실패 메시지의 브랜드 이름.** 등록 술어만으로 정확한 이름이 나온다: Tween(프로바이더), `Epoch, Ref`, Slot, Blocker, AttrKey, MapperDescriptor, Store, Context. debug 상태와 무관하게 같다.

**debug 문자 키 필터.** 같은 (인스턴스, 키)에서는 한 번만 출력한다. `Parent`나 읽기 전용 키처럼 Property가 받지 않는 자리에서도 출력하는데, 그 경우 문구 "usually the property of that name"이 조금 어긋난다. 출력일 뿐이라 (라)다.

### 미완

- `Dispatch.process`를 직접 부르는 경로(잘못된 index 인자)는 따로 퍼징하지 않았다. drive를 거친 process만 봤다.
- Claim 1패스 순수 매핑(`8062702b`), Slot Q74 `raiseChain`·Q113 순환 검사·`Quad0143` debug 층 경로는 diff와 코드만 읽고 실측하지 않았다.
