# round13 E29 — mock 충실도 정적 대조 (2026-09-27)

`quad-base/test/mock.luau`(HEAD `bcea9840`)가 실제 Roblox 엔진과 **다르게 허용·거부하는 것**을 API dump
(`quad-roblox/dump/api-surface.json`, `version-268c7d941ba34c1a`)·`scripts/roblox-defs/globalTypes.d.luau`·
`scripts/gen-d.py` 규칙과, 레포에 이미 있는 Studio 실측 원장에 대조했다. 엔진 실측은 안 했다(Studio/MCP 금지).

근거 표기 — **[dump]** dump가 직접 말함 · **[실측 …]** 레포 안 Studio 실측 원장 · **[문서]** Roblox 공식 문서로
널리 알려진 동작(이 레포에서 실측한 적 없음) · **[추정]** 근거 없는 추정.

## 방법

1. mock 정독 → 아래 표.
2. **계측 mock**: 스크래치 사본(레포 밖)에 `mock-variants.py instr`로 계측 훅을 넣고(dump 표면은 `gen-e29dump.py`),
   spec·smoke 전부(62파일)와 문서 스니펫 러너(`round13-s10-snippet-recheck/run-*.luau`, `round13-e27-gs-chain/chain-*.luau`)를
   돌려 "mock이 엔진과 다르게 받아 준 자리"를 파일:줄로 모았다 — `instr-specs.out.txt`, `instr-docsnippets.out.txt`.
   훅은 경고만 찍고 동작은 그대로(전부 통과).
3. **엔진 쪽으로 맞춘 변형 mock**으로 spec 전부를 다시 돌려 "그 느슨함에 기대는 spec이 있는가"를 쟀다:

| 변형 | 바꾼 것 | 실패 spec |
|---|---|---|
| `forward` | 리스너 발화 순서 역순 → 등록순 | 0 |
| `samevalue` | 같은 값 대입이면 쓰기·신호 생략(엔진 [실측 2026-09-10]) | 0 |
| `parentlock` | Destroy 뒤 Parent 대입 에러, 순환 Parent 에러, 같은 부모 재대입 no-op | 0 |
| tie(수동) | 가상 시계에서 같은 시각 타이머를 나중 등록 먼저 | 0 |
| `nilreject` | nil을 받지 못하는 프로퍼티(dump 타입이 객체 참조가 아닌 것)에 nil 대입 시 에러 | 2 — `spec.handlers.luau` §9, `spec.tweenproperty.luau` §6 (둘 다 "mock은 nil을 받아 준다"를 주석으로 알고 쓴 절) |

재현: 레포 루트에서 `./scripts/relink.sh` 뒤, 다섯 패키지 폴더를 스크래치로 `cp -rL` → `python3 <이 폴더>/gen-e29dump.py <사본>/quad-base/test/e29dump.luau`
→ `python3 <이 폴더>/mock-variants.py <변형> <사본>/quad-base/test/mock.luau`(스크립트는 레포 원본 mock을 읽어 사본에 쓴다) → 사본에서 spec 실행.
`probe-mock-surface.luau`·`probe-setattr-op.luau`·`probe-nil-write.luau`는 **원본 mock** 위에서 레포 루트에서 바로 돈다(`luau <경로>`).

## 1. 대조표 (행 39 — 느슨 16 · 엄격 5 · 상이 10 · 일치 8; g4는 느슨으로 셈, 그 안의 `Cancel` 동기 발화만 엄격)

느슨 = mock 통과·엔진 거부 / 엄격 = mock 거부·엔진 통과 / 상이 = 둘 다 통과하지만 결과가 다름.

| # | 축 | mock | 엔진은? | 판정 | 기대는 자리 |
|---|---|---|---|---|---|
| a1 | `Instance.new` 없는·생성 불가 클래스 | 아무 이름이나 만든다 | `Unable to create an Instance of type …` [문서]; gen-d가 `NotCreatable`/`Service`를 빼는 근거가 이것 [dump 태그] | 느슨 | 없음 — spec은 Frame/Folder/TextLabel/Part만(`spec.d.luau:126` Part는 실재 클래스) |
| a2 | `Instance.new(class, parent)` 둘째 인자 | 무시 | 부모 지정 [정의 파일 18860행] | 느슨 | 없음 — quad는 한 인자만 씀(`Declaration/init.luau:4961`) |
| a3 | quad 소유 판정 | `Instance.new` = 태어날 때 claim, `Instance.foreign` = 미claim | 엔진 개념 아님(quad-roblox는 `New`가 `nativeClaim`) | 일치(설계) | — |
| b1 | 없는 멤버에 쓰기 | 프로퍼티 백에 저장 | `X is not a valid member of Y` [문서]; dump에 없음 [dump] | 느슨 | `spec.storebind.luau:42`(Frame.Label/Title), `spec.integration.luau:26`(Frame.Text/Value) — quad-base spec 로컬 핸들러가 쓰는 하네스라 엔진 무관 설계 |
| b2 | ReadOnly 쓰기(`AbsoluteSize`·`ClassName`·`AbsoluteWindowSize`) | 저장(`ClassName`은 읽기엔 안 보이지만 그 변경 신호=gcconn 신호를 쏜다) | 거부 [dump readProps] + [문서] | 느슨 | spec 없음(`spec.handlers.luau:37`의 `AbsoluteSize`는 `Permits = {}`로 엔진대로). 감사 하네스 5곳이 Reflection 심에 `AbsoluteWindowSize`를 **쓰기 가능**으로 올림(`round13-e27-gs-chain/harness.luau:33`, `round13-s10-snippet-recheck/harness.luau:31`, `round13-e15-probe-setup.luau:31`, `round13-e17-probe-setup.luau:32`, `round13-gates2-proto/probe-setup.luau:31`) — props로 쓰는 스니펫은 없어 현재 무해 |
| b3 | NotScriptable·보안 프로퍼티 | 저장 | 거부 [dump dropped 태그] | 느슨 | 없음 |
| b4 | Deprecated 프로퍼티(`Draggable` 등) | 저장 | 쓰기 가능(Deprecated는 막지 않음) [dump 태그 + 문서] | 일치 | 하네스 COMMON의 `Draggable` |
| b5 | 타입 불일치(`Size = 42`) | 저장 | `Unable to assign property Size. UDim2 expected, got number` [문서]; 타입은 [dump] | 느슨 | spec 75회(최다 `Frame.Size<-number` 43; `spec.handlers.luau:64`, `spec.tweenproperty.luau:49,99,215,221,251,261,321,325,392` 등), 스니펫 러너는 UDim2/Color3를 테이블 대역으로(`engine-globals.luau`) — CLI에 userdata가 없어 불가피 |
| b6 | nil을 못 받는 프로퍼티에 nil(`Visible = nil`, `Size = nil`) | 저장, 읽으면 nil | 에러 [문서] — Property 핸들러 헤더도 "엔진이 던진다"를 전제(Q33) | 느슨 | `spec.handlers.luau:222-226`, `spec.tweenproperty.luau:136,152-155,227` — 주석으로 자각("mock의 프로퍼티 백은 nil 대입을 받아주므로") |
| b7 | 레거시 별칭(`Font`↔`FontFace`, `Transparency`↔`BackgroundTransparency` …) | 별개 키 — 한쪽 쓰기가 다른 쪽 값·신호를 안 바꿈 | 연동 [추정 — 별칭의 정의상] | 상이 | `docs/reference/roblox/02-d.md:222-227`(이미 "엔진 쪽 별칭 동작은 실기기 미실측") |
| b8 | `Name = 5` | `Name must be a string`으로 던짐 | 숫자→문자열 변환 [추정] | 엄격(추정) | 없음 |
| b9 | 이벤트 멤버에 대입 | 선언된 이벤트면 던짐 | 던짐 [문서] | 일치 | `mock.luau` M10 주석 |
| c1 | 안 쓴 프로퍼티 읽기 | `nil` | 클래스 기본값(dump엔 기본값이 없다 — `Frame.Visible` true, `TextLabel.Text` "Label" [실측 2026-09-10 `studio-docs-2026-09-10.md` A-0]) | 상이 | spec은 b6 절의 nil 쓰기 뒤 읽기뿐(5회), 스니펫 러너 0 |
| c2 | 없는 멤버 읽기 | `nil` | 던짐 [실측 — `workspace.SignalBehavior` "not a valid member", `m5-unit1-studio-smoke-2026-09-02.md`] | 느슨 | `spec.storebind.luau:82,90,108,113,130…232`, `spec.integration.luau:54,110` — b1과 같은 하네스 |
| c3 | 엔진 이벤트 읽기(`Changed`·`AncestryChanged`·`ChildAdded`…) | 선언 안 했으면 `nil`(`:Connect`가 nil 호출로 죽음) | RBXScriptSignal [dump events] | 엄격 | 없음 — spec은 쓰는 이벤트를 `declareEvents`로 선언 |
| c4 | `tostring(inst)` | Name | Name [문서] | 일치 | 에러 메시지들 |
| d1 | 같은 값 대입 | 매번 쏜다 | 안 쏜다 [실측 2026-09-10 A-0, `Changed`도] | 상이 | `spec.events.luau:171-173`(주석으로 자각), `round13-e27-gs-chain/chain-a-ch01-10.luau:214`(`q.Out` 값 비교가 가림 — E27 README 119행이 미완으로 적음). `samevalue` 변형 0 실패 |
| d2 | 배달 시점 | 동기(Immediate) | 이 플레이스는 Deferred [실측 `H-291` 2026-09-02, `m10-events-studio-2026-09-03.md`, round11 REPORT] | 상이 | 사실상 모든 "대입 직후 단언". 문서는 `reference/extend/01-backend-provider-contract.md:103`, `reference/roblox/05-onchange.md:74`가 명시 |
| d3 | 리스너 순서 | 등록 역순 | 문서화 안 됨 [추정] | 상이 | `forward` 변형 0 실패; `reference/sugar/04-lifecycle-hooks.md:30`이 "mock은 역순, Roblox 미실측"으로 정확히 표시 |
| d4 | Parent 변경 시 신호 | 그 인스턴스의 `Parent` 변경 신호만 | + `AncestryChanged`(자손 포함)·`ChildAdded/Removed`·`DescendantAdded/Removing` [dump events + 문서] | 엄격 | 없음(quad가 안 씀) |
| d5 | 없는 이름의 `GetPropertyChangedSignal` | 새 시그널을 돌려준다 | 던짐 [문서] — `Handlers/OnChange.luau` 헤더가 이것에 기댄다("an unknown name raises the engine's own error inside process") | 느슨 | spec 0회 |
| d6 | Disconnect된 연결의 대기 배달 | 해당 없음(동기) | 취소 [실측 `m10-events-studio-2026-09-03.md` #3] | 상이 | — |
| d7 | 파괴 뒤 `Connect` | 새 연결이 `Connected=true`로 영원히 | 같음 [실측 `H-293`] | 일치 | — |
| e1 | Destroy 뒤 `Parent` 대입 | 받아 준다 | Parent 잠김 에러 [문서] | 느슨 | `parentlock` 변형 0 실패(quad 게이트가 먼저 막음) |
| e2 | Destroy 순서·Destroying 핸들러가 보는 상태 | `Destroying` 동기 발화(부모·자식 살아 있음) → Parent nil → 자손 Destroy → 연결 끊기 | Destroy는 즉시 Parent nil·잠금·연결 끊기·자손 파괴, `Destroying` 배달은 Deferred라 핸들러는 파괴 **뒤** 상태를 본다 [실측 `H-291` — 큐잉된 배달 1회] | 상이 | 없음(`H-707` Deferred 창 결함은 이미 고쳐짐) |
| e3 | 두 번째 Destroy | no-op | no-op [문서] | 일치 | — |
| e4 | gcconn `.Connected` 전환 | 동기 | 동기 [실측 `H-291`] | 일치 | 생존 게이트 전부 |
| f1 | `inst:SetAttribute` 값 타입 | 테이블·함수·스레드만 거부 | 지원 목록 밖 전부 거부(`Array is not a supported attribute type` [실측 round8]; Instance 등도 목록 밖 [문서]) | 느슨(부분) | — |
| f2 | **mock 백엔드의 `setAttr` op**(`installTagAttrOps`, `mock.luau:531`) | **아무 값이나 저장** | 위 f1 | 느슨 | 발견 (b)1 |
| f3 | 속성 이름 규칙(공백·100자·`RBX` 접두) | 검사 없음 | 거부 [문서, 미실측] | 느슨 | 없음 — 이미 실기기 초안에 있음 |
| f4 | 태그 이름 | 검사 없음 | 제한 있음 [추정] | 느슨 | 이미 실기기 초안에 있음 |
| f5 | `AttributeChanged`·`GetAttributeChangedSignal` | 없음 | 있음 [dump events] | 엄격 | 없음 |
| g1 | `task.delay(0)`류 | `advanceTime(0)` 안에서 발화 | 다음 재개점 [문서] | 상이 | `reference/sugar/03-debounce-throttle.md:89`가 명시 |
| g2 | 같은 시각 타이머 | 등록순 | 보장 없음 [추정] | 상이 | tie 변형 0 실패 |
| g3 | 끝난 타이머 `task.cancel` | no-op | no-op [실측 2026-09-08] | 일치 | — |
| g4 | TweenService 심 | `Create`가 어떤 프로퍼티·타입도 받고 보간 없음, `Cancel`이 `Completed`를 **동기**로 쏨, `TweenInfo` 심이 명시적 nil도 받음 | 보간 불가 타입·없는 프로퍼티는 `Create`가 거부 [문서; gen-d `TWEENABLE`이 같은 목록]; `Completed`는 Deferred [실측 2026-09-21]; `TweenInfo.new`는 명시 nil 거부 [실측 `H-333`] | 느슨(Create·TweenInfo)/엄격(Cancel 동기 — mock 주석이 의도로 밝힘) | 계측: 문자열·nil 트윈 0회, TweenInfo 명시 nil 0회 |
| h1 | 순환 Parent·자기 자신 | 받아 준다 | 순환 참조 에러 [문서] | 느슨 | 0회(quad의 Slot 순환 가드 `H-500`이 먼저) |
| h2 | 같은 부모 재대입 | 자식 배열 끝으로 옮기고 신호도 쏜다 | 변화 없음 [추정 — 같은 값 무발화 실측의 연장] | 상이 | `spec.claim.luau` 15회(Claim이 템플릿 자식을 제자리에 다시 `nativeInsert`) — `parentlock` 변형(no-op) 0 실패 |
| h3 | `IsA` | `ClassName ==` | 상속 계층 [dump chain] | 엄격 | `spec.claim.luau:235`(엄격해도 결과 같음); 이미 실기기 초안에 있음 |

## 2. mock이 느슨한 행과 거기 기대는 자리 — 요약

기대는 자리는 표의 마지막 열이 전부다. 정리하면 **엔진에서 결과가 뒤집힐 spec 단언은 b6(nil 쓰기) 두 절뿐이고, 둘 다
mock 전용임을 주석으로 밝혀 둔 절**이다. 나머지 느슨함(b1·c2 하네스, b5 대역 값, h2 Claim 재대입)은 "엔진 무관 하네스"거나
변형 실행에서 결과가 같았다. 문서 쪽 "mock 확인/[mock 관측]" 문장 중 엔진 동작에 기대는 것은 아래 실기기 후보 1·2·3으로 따로 뺐다.

## 3. mock이 엄격한 행

b8(`Name`에 숫자 — 추정), c3(선언 안 한 엔진 이벤트 읽기), d4(Parent 변경 부수 신호 없음), f5(속성 변경 신호 없음),
g4의 `Cancel` 동기 `Completed`(의도), h3(`IsA` 상속 없음). 계측 실행에서 엄격함 때문에 spec이 엔진에선 안 나는 에러를
전제한 자리는 **없었다**(`spec.claim.luau:235`의 `IsA` 거짓은 엔진에서도 거짓 — ImageLabel/TextLabel).

## 4. 발견

### (a) 문서 오류

**a-1. 백엔드 계약 문서의 "mock은 테이블·함수·스레드만 거부" 문장은 mock 백엔드 자신의 `setAttr` op에는 틀리다.**
`docs/reference/extend/01-backend-provider-contract.md:163`은 "mock은 테이블·함수·스레드만 거부하고 이름은 검사하지 않습니다"라고
적고, 같은 문서 42행은 "mock이 같은 계약을 전부 구현하고 … 가장 정확한 참고 구현"이라고 한다. 그런데 계약의 `setAttr` 슬롯에
mock이 심는 함수(`quad-base/test/mock.luau:531-536`, `installTagAttrOps`)는 값을 검사하지 않는다 — 거부하는 것은 인스턴스
메소드 `inst:SetAttribute`(`mock.luau:331`)뿐이고, 그건 quad-roblox의 EngineOps가 mock 인스턴스 위에서 돌 때만 지난다.
`probe-setattr-op.luau`: `mock.newQuad()`로 `[q.AttrKey("T")] = {}` → ACCEPTED(저장된 값 table), State가 테이블을 emit → ACCEPTED,
같은 인스턴스의 `inst:SetAttribute("U", {})` → rejected. 문장은 "mock 인스턴스의 `SetAttribute`는"으로 좁혀야 사실이다.

### (b) mock/코드 결함

**b-1. round13 `H-659`의 mock 수정이 quad-base 경로를 덮지 않았다.** `H-659`(원장 round13 135행)는 "`[q.AttrKey("T")] = {}`,
State가 나중에 테이블을 emit 하는 경로가 spec을 통과했다"를 고치려고 mock `SetAttribute`에 게이트를 넣었지만, quad-base spec과
`mock.newQuad()` 위에서 도는 헤드리스 스니펫은 mock 프로바이더의 `setAttr` op를 타고 그 op는 여전히 무엇이든 저장한다
(위 a-1 재현). 계측 실행에서 지금 이 구멍에 기대는 spec은 0회였으므로 현재 거짓 통과는 없지만, 원장이 막았다고 적은 경로가 quad-base
쪽엔 열려 있다. 이름 규칙 쪽도 op에선 검사가 없다(엔진 규칙 자체가 미실측이라 `H-659`가 의도적으로 안 한 것과 같은 상태).

**b-2. (재현 안 됨 — 기록용) nil 쓰기가 엔진에서 던진 뒤의 트윈 슬롯 상태.** Property 핸들러는 활성 트윈을 먼저 취소하고(`stopRunning`)
그다음 `inst[k] = nil`을 쓰므로(`quad-roblox/src/Handlers/Property.luau:286-336`), 엔진에선 취소는 일어나고 대입이 던진다. 그 뒤 같은
목표값으로 다시 `Set`하면 옛 기록과 Dedup 되어 애니메이션이 안 걸릴 수 있다고 의심해 `nilreject` 변형으로 재현해 봤으나
(`probe-nil-write.luau`의 변형 실행), 두 mock 모두 두 번째 트윈을 새로 만들었다(원본: 대입 성공·크기 nil / 변형: 던지고 크기 0 유지 — 이후 동작은 같음).
결함 아님. 다만 이 "취소 뒤 던짐" 경로를 단언하는 spec은 없다(spec의 nil 쓰기 절은 mock이 받아 준다는 전제로만 단언).

**b-3. 변형 실행으로 확인한 "기대는 spec 없음" 넷.** 같은 값 무발화·등록순 발화·Parent 잠금/순환 거부/같은 부모 no-op·같은 시각 타이머
역순으로 mock을 엔진 쪽에 맞춰도 spec·smoke 62파일이 전부 통과했다. 이 넷에 대해 지금의 spec 통과는 mock의 느슨함에 기대지 않는다.

### (c) 판단 필요

**c-1. mock을 엔진에 맞출 것인가, 문서에 "mock만"으로 둘 것인가 — 같은 값 무발화·Parent 잠금·순환 거부·같은 부모 no-op.** 넷 다
맞춰도 spec이 안 깨진다(b-3)는 것이 판단 재료다. 맞추면 앞으로의 "mock 확인"이 이 축에서 엔진과 갈릴 일이 줄고, 안 맞추면 지금처럼
문서가 개별 헤지(`05-onchange.md:74` 등)를 달아야 한다.

**c-2. mock 프로바이더 `setAttr` op에 `inst:SetAttribute`와 같은 값 게이트를 둘 것인가.** 새 메커니즘이 아니라 이미 있는 게이트를
다른 입구에도 거는 일이다(b-1). 안 하면 a-1 문장을 좁히는 것으로 끝난다.

**c-3. nil 쓰기·타입 불일치 절을 "mock 전용"으로 계속 둘 것인가.** `spec.handlers.luau` §9와 `spec.tweenproperty.luau` §6·§7은 엔진에서
나올 수 없는 상태(`Visible == nil`, `Size == nil`)를 단언한다. 주석이 자각하고 있어 오독 위험은 낮지만, 실제 엔진에선 이 경로가
"취소 뒤 던짐"(b-2)이고 그 경로는 어디서도 단언되지 않는다. CLI엔 UDim2 같은 값이 없어 b5 대역 값은 피할 수 없다.

**c-4. 감사 하네스의 Reflection 심이 ReadOnly `AbsoluteWindowSize`를 쓰기 가능으로 올린 것**(표 b2의 다섯 파일). 지금은 그걸 props로
쓰는 스니펫이 없어 무해하지만, 쓰는 스니펫이 생기면 mock은 통과하고 엔진(Reflection에 `Permits.Write` 없음)에선 "매치 핸들러 없음"
에러가 난다. 하네스 전용이라 레포 코드 결함은 아니다.

**c-5. mock 백엔드 op의 에러 문구에 `QuadNNNN` 식별자가 없다.** `mock.luau:608,611,621`(setTimeout/clearTimeout)·`702,709,734,749`의
문구는 quad-roblox 원본(`EngineOps.luau` `Quad0215~0217`, `LifetimeHandle.luau` `Quad0225/0226`)과 달리 식별자가 없다. mock 위에서
에러 문구를 인용하는 문서·spec이 생기면 실제 문구와 다르다. 지금 docs는 전부 원본에서 인용했다(`docs/reference/errors/07-roblox.md`).

## 5. 실기기 후보 (이 탐사에서 새로 나온 것; 이미 `round13-drafts-2026-09-27/human-todo-realdevice-draft.md`에 있는 IsA 상속·속성/태그 이름 규칙·`task.delay(0)`·`Destroying` 리스너 순서·별칭 우선순위는 뺐다)

1. **파괴된 인스턴스 아래로 부모 지정** — `docs/reference/core/06-slot.md:613`의 "새 원소는 죽은 인스턴스에 붙으며"([mock 관측]). 확인: `p:Destroy()` 뒤 `Instance.new("Frame").Parent = p`를 pcall, 성공 여부와 `c.Parent == p`.
2. **없는 이름의 `GetPropertyChangedSignal`** — `docs/reference/roblox/05-onchange.md:113-114`, `Handlers/OnChange.luau` 헤더. 확인: `D.Frame { q.OnChange("Text", fn) }`(타입 우회)를 pcall해 에러 문구와 blame 줄(사용자 줄인가 `OnChange.luau`인가).
3. **보간 불가 타입의 `TweenService:Create`** — `docs/reference/roblox/02-d.md:119`의 "둘째 값부터 엔진이 거부". 확인: `TextLabel { Text = src:Apply(q.Animate{…}) }`에 값 둘을 `Set`, 둘째에서 에러 문구·그 뒤 `Text` 값.
4. **nil을 못 받는 프로퍼티에 `q.None`** — `02-d.md:121`. 확인: `Frame { Size = src:Apply(q.Animate{Time=1}) }`에서 `Set(UDim2…)` 두 번 뒤 `Set(q.None)`을 pcall — 문구, blame 줄(`Property.luau`인가), 활성 트윈이 취소됐는가, 그 뒤 같은 목표 `Set`이 다시 애니메이션하는가(b-2).
5. **같은 부모 재대입** — Claim 재삽입 경로(h2). 확인: `a.Parent = p; b.Parent = p; a.Parent = p` 뒤 `p:GetChildren()` 순서와 `task.wait()` 뒤 `a`의 Parent 변경 신호 횟수.
6. **레거시 별칭의 변경 신호 교차** — 기존 별칭 행의 연장. 확인: `GetPropertyChangedSignal("FontFace")`에 연결한 뒤 `Font = Enum.Font.Arial`, `task.wait()` 뒤 발화 횟수(반대 방향도).
7. **`Destroying` 핸들러 안에서 보이는 상태**(e2) — 확인: 자식 하나 있는 Frame의 `Destroying`에서 `inst.Parent`, `#inst:GetChildren()`, 자식의 `Parent`를 기록.
8. **`Name = 5`** — 확인: pcall 뒤 `Name`이 `"5"`인가(b8, mock은 던짐).

## 6. 미완

- **Deferred 변형 mock은 만들지 않았다** — spec 대부분이 대입 직후 동기 단언이라 전부 깨지는 것이 예상돼 정보가 적다. Deferred 쪽 구체 창은 `H-291`·`H-707`·실측 원장들이 이미 다룬다.
- 문서 스니펫 계측은 `round13-s10-snippet-recheck/run-*`·`round13-e27-gs-chain/chain-*` 러너만 돌렸다(다른 감사 프로브는 안 돌림).
- [문서] 표시 행은 Roblox 공식 문서의 알려진 동작을 기억으로 적은 것이다(이 탐사에서 웹 조회·실측 안 함). dump는 기본값·에러 문구를 담지 않는다.
