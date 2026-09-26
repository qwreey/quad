# round13 E35 — debug 층(`q.debug`) 전수 대조 + how-to 10 부록 절차 실행 (2026-09-27)

HEAD `ed5adad4`, `scripts/relink.sh` 뒤 mock 하네스(`harness.luau`·`engine-globals.luau`는
`../round13-s10-snippet-recheck/`에서 **복사**)로 실행. 레포 파일 무변경. Studio 없음.

실행 파일과 출력 원문:
- `probe-debug.luau` → `probe-debug.out.txt` — 각 debug 분기를 debug=false/true 두 번 트리거(결과 동일성 + 출력)
- `probe-provider-ties.luau` → `probe-provider-ties.out.txt` — debug를 켠 새 모듈에 실제 프로바이더 설치(동률 줄 없음 확인)
- `probe-howto10.luau` → `probe-howto10.out.txt` — how-to 10 절차를 에러 다섯에 적용(blame 접두·ID·debug 무영향·`q.Traceback`·`pcall(quad함수)` 한계)
- `probe-attr-fn.luau` → `probe-attr-fn.out.txt` — Attr 값 타입 보조

## 1. 분기 표

| 파일:줄 | 조건 | 출력(원문, 실측) | 동작 영향 | 문서 |
|---|---|---|---|---|
| `quad-base/src/init.luau:170` | `module.debug` 그리고 반환 테이블의 키가 기존 필드를 **다른 값**으로 덮을 때 | `AddPlugin: plugin overwrites existing module field "Relate" — intended if the plugin extends a core part on purpose; otherwise rename the plugin's field` (같은 값 재대입은 무출력 — 실측) | 없음(읽기만, 병합은 분기 뒤 무조건) | core/01 `q:AddPlugin` 94·96(문구 verbatim 일치), core/01 `q.debug`, CHANGELOG Unreleased 26 |
| `quad-base/src/Dispatch/init.luau:416` | `module.debug`, 같은 priority이고 keyType이 겹칠 수 있는(`nil` 또는 같음) 기존 핸들러 | `Dispatch.addHandler: handler priority tie between "A" (priority 7777) and "B" (priority 7777) — ties have no defined order; offset from a HANDLER_PRIORITY_* band` (새 핸들러당 첫 상대 하나만 — `break`; string/number끼리는 무출력 실측) | 없음 | extend/02 96·383(문구 인용 없음), core/01, overview/01 295 |
| `quad-base/src/Debounce.luau:327` | `module.debug`, opts의 모르는 키(Debounce·Throttle 공용) | `Debounce: unknown option "Tme" is ignored (known: Time, Leading, Trailing, MaxTime, Handle)` / `Throttle: unknown option "Leadng" is ignored (…)` | 없음(opts 타입 게이트 뒤, 검증 앞) | core/01, CHANGELOG 27. sugar/03 페이지엔 언급 없음 |
| `quad-base/src/Slot/List.luau:245` | `module.debug` 그리고 opts가 테이블, `OwnsElements` 외 키 | `Slot:List/:Single: unknown option "Owned" is ignored (known: OwnsElements)` | 없음(`_owned` 설정은 분기 앞, 결과 `nil` 동일) | core/01, CHANGELOG 27·68. core/06 페이지엔 언급 없음 |
| `quad-roblox/src/Tween.luau:181` | `quad.debug` 그리고 opts가 테이블, 13개 밖 키 | `Tween: unknown option "Duration" is ignored (known: Value, Info, Time, Style, Direction, RepeatCount, Reverses, DelayTime, Override, Dedup, Started, Completed, Cancelled)` (+`Easing` 한 줄) | 없음(`newTween` 앞 읽기만) | core/01, CHANGELOG 27. roblox/06 페이지엔 언급 없음 |
| `quad-roblox/src/Animate.luau:71` | `quad.debug`, FIELDS+`CanAnimate` 밖 키 | `Animate: unknown option "Duration" is ignored (known: Info, Time, Style, Direction, RepeatCount, Reverses, DelayTime, Override, Dedup, Started, Completed, Cancelled, CanAnimate)` | 없음 | core/01, CHANGELOG 27. roblox/06·how-to 08 §4엔 debug 언급 없음 |
| `quad-base/src/Claim.luau:195` (`H-533`) | `module.debug` 그리고 루트 디스크립터 키 ≠ `M.Root` | `Claim: the root descriptor's key SomeName is ignored — the root takes M.Root; put a keyed descriptor in the root's props instead` | 없음(루트 자신 claim, props 적용 동일 — 실측 `true 0.5` 양쪽) | core/01, CHANGELOG 125. roblox/04엔 언급 없음 |
| `quad-base/src/Claim.luau:141` (`H-534`) | `module.debug` 그리고 자식 디스크립터 키가 문자열 아님 | `Claim: child descriptor key is a table — M.Root is only for the root descriptor; a child key is a name` / `… is a number — …` | 없음(뒤이은 `Quad0032` 동일 — mock은 nil을 주어 Quad0032, 실물은 엔진 에러) | core/01, CHANGELOG 125. roblox/04엔 언급 없음 |

debug 밖 출력: 런타임 `print`/`warn`은 **0**(`warn`은 전 코드에 한 번도 안 쓰임). 유일한 debug 밖 출력은
`quad-types/src/init.luau:489`의 타입 함수 `CheckReservedKeys` 안 `print`(`quad.Store: "{v}" is a reserved key`) —
런타임이 아니라 타입 검사 시점이고 `q.debug`와 무관, core/04 161이 문구 그대로 설명. 정적만.

실제 프로바이더를 debug=true 모듈에 설치해도 동률 줄은 0(Event/OnChange가 −1로 내려간 CHANGELOG 44와 일치).
base 자체 핸들러(1000 대역 열 개, −1000000 대역 여덟 개)는 `New()` 안에서 debug=false로 등록돼 서로의 동률이
보고되지 않는다 — 판정이 배타적이라 문제 아님.

## 2. 숫자

debug 분기 자리 8(검사 종류 7 — Debounce/Throttle 한 자리) / 트리거 8 / 정적만 0(+ debug 밖 타입 함수 print 1은 정적) /
core/01 목록과 집합 일치 8 / 집합 불일치 0 / 동작 차이(debug on vs off) 0 — 11 케이스 전부 같은 ok·값·에러.
문구 verbatim 인용이 있는 것 1(AddPlugin, 일치), 나머지 7은 문서에 문구 인용 없음.

## 3. 발견

### (a) 문서 오류
- **A1** `docs/reference/core/01-quad-module.md:189` 예시 주석 `q.debug = true -- 동률·덮어쓰기·모르는 옵션 키 진단을 켠다`가
  바로 위 목록의 넷째(`Claim` 디스크립터 검사, `Claim.luau:141`·`:195`)를 뺐다. 본문 목록은 맞다.
- **A2** `docs/how-to/08-migrating-from-v1.md:185` "모르는 키는 **에러도 타입 진단도 없이 무시됩니다**"(Animate/Tween의 v1 `Easing`)는
  debug 꺼짐에선 참이지만, 바로 그 상황을 잡으라고 만든 `q.debug`(`Animate.luau:71`·`Tween.luau:181`, 실측
  `Tween: unknown option "Easing" is ignored …`)를 언급하지 않는다. 같은 문서 429도 같다. 이관 문서가 쓰인 건 09-11,
  debug 층은 09-15 — 뒤에 생긴 도구가 안 반영된 stale(CHANGELOG 68은 `Owned`에 대해 같은 안내를 이미 한다).

### (b) 코드 결함
없음. 여덟 분기 모두 읽기 전용이고(`print`만), 분기 앞의 게이트·분기 뒤의 동작이 debug와 무관하다 — `base/architecture.md`
"debug 층" 절("경고는 동작을 안 바꾼다")과 일치. 경고가 틀린 조건에 남는 자리도 없다(같은 값 재대입 AddPlugin 무출력,
keyType이 다른 동률 무출력 실측). 이론적 잔여 하나만 기록: 옵션 루프는 `for key in opts` 일반화 반복이라 `__iter`
메타메소드가 있는 테이블을 넘기면 debug일 때만 그 메소드가 불린다 — 실제 경로가 없어 발견으로 올리지 않음.

### (c) 판단 필요
- **C1** 경고에 `QuadNNNN`이 없는 것은 `base/error-id-plan.md` 91행("`q.debug`의 `print` 경고에는 ID를 안 붙인다")의 결정대로이고
  core/01 96이 AddPlugin에 대해 명시한다. 다만 how-to 10 §1은 "번호가 없으면 quad가 아니라 엔진이 낸 에러입니다"라고
  단정한다 — debug 줄은 에러가 아니라 print라 모순은 아니지만, 콜백 안에서 사용자가 던진 에러(rethrow 자리)·quad 내부
  VM 에러도 번호가 없다. 문장을 "에러"로 한정된 채 둘지 사용자 판단.
- **C2** 대상 레퍼런스 페이지 넷(sugar/03 Debounce·Throttle, core/06 `:List`/`:Single` opts, roblox/06 Tween/Animate,
  roblox/04 Claim)이 "모르는 키/루트 키는 무시되고 `q.debug`가 알린다"를 한 줄도 안 적는다. core/01의 Claim 항목은
  roblox/04로 링크하지만 링크 끝에 해당 설명이 없다. 정본을 core/01 한 곳에 두는 것(architecture.md가 "목록의 소스는
  core/01"로 정함)과 각 페이지 포인터 한 줄 중 어느 쪽인지.
- **C3** how-to 10 부록에는 `q.debug`도 `q.Traceback`도 없다(§1 blame 읽기·ID 찾기·한계 둘, §2 함정 일곱, §3 체크리스트,
  §4 이슈 제보만). sugar/05가 how-to 10을 "에러가 어느 줄을 blame하는지 읽는 법"으로 링크하는 것과는 맞는다. debug 켜기·
  Traceback을 부록 절차에 넣을지는 사용자 판단(§4 "막히면 어디로"에 넣을 자리가 자연스러움).
- **C4** core/01 `q.debug` 절의 넷 중 AddPlugin 덮어쓰기·옵션 키·Claim 셋은 CHANGELOG `[Unreleased]`(26·27·125)이고 게시본
  3.2.0엔 동률 경고만 있다 — 사이트가 HEAD 기준이라 미게시 캐비엇이 없다(`H-759` `q.Out`과 같은 부류).
- 참고(발견 아님): `base/architecture.md` "debug 층" 절의 "2026-09-15 현재 읽는 자리"에 Claim 둘이 없지만 날짜가 붙어 있고
  목록 소스를 core/01로 넘기므로 틀린 서술은 아니다.

## 4. how-to 10 절차 × 에러 다섯

절차: (1) 메시지 첫 토큰 ID → (2) `docs/reference/errors/`에서 `### QuadNNNN` → (3) `파일:줄` 접두가 사용자 줄인가 →
(4) debug on/off 동일 → (5) 알려진 한계 1(`pcall(quad함수, …)` 접두 소실).

| 에러 | 결과 |
|---|---|
| Slot 미claim(`s:Add(foreign)`) | `probe:31: Quad0241 Slot: this element is not claimed by quad — …` — 접두=사용자 줄, errors/03-slot.md 371 문구 일치·언제/고치려면 맞음. `pcall(slot.Add, …)` 직접 호출은 접두 소실(한계 1 실측 확인) |
| 문자 키 자리 Slot(`D.Frame{Children=q.Slot()}`) | `probe:35: Quad0141 Slot: must be an array item, not the value of a string key` — 선언 줄 blame, errors/03-slot.md 18 일치 |
| Compute 재진입(fn이 자기 `:Get`) | `probe:41: Quad0184 State: Compute fn is already running …` — fn 안의 `c:Get()` 줄 blame(바깥 `:Get` 줄 42가 아님 — 한계 2의 "콜백 안은 바깥 줄"은 디스패치 계열 얘기라 모순 없음), errors/01 258 일치 |
| Tween 옵션 오류(`Time="fast"`) | `probe:48: Quad0243 Tween: Time must be a number` — errors/08 26 일치. debug=true면 오류 앞에 모르는 키 줄은 없음(키는 알려진 것) |
| Attr 타입(`q.Attr{Hp={}}`) | `probe:52: Quad0008 Attr: attribute "Hp" cannot be a table — …` — errors/05 66 일치(함수 값은 `Quad0007`) |

다섯 모두 debug on/off 동일, `q.Traceback`은 `onError(err, trace)`로 같은 문자열 + quad-error/내부 프레임을 포함한 트레이스
(7~10줄, 사용자 줄이 중간에 보임)를 받고 대체값을 돌려줌. 문서가 빠뜨린 단계는 C3(debug·Traceback 부재)뿐.

## 5. 미완
- 실물 Roblox에서 `H-534` 자식 비문자열 키가 debug 줄 뒤 엔진 `FindFirstChild` 에러로 이어지는지는 mock이 nil을 줘 정적만.
- 출력 채널: Studio Output에서 `print`가 어떻게 보이는지(정보 줄)는 실기기 몫 — mock은 stdout.
