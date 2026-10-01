# round13 Q135 후속 — 핸들러 `forDebug` 플래그 프로토타입·실측 (2026-10-01)

**[2026-10-01 결정·반영]** 이름은 `debugOnly`(사용자: *"debugOnly로 가자."* — sonnet 외부자·내부자 둘 다 추천)로 정식 반영됐다. 경고 문구는 아래 잡음 ①을 없애려고 중립 문구(`… a string key hands it to whichever handler takes that key …`)로 바뀌었다. 정본은 `docs/reference/extend/02-dispatch-handler-contract.md`와 `quad-base/src/DebugKeyFilter.luau`이고, 아래 본문은 결정 전 측정 기록이다.

사용자 제안(원문): *"그럼 debug 를 끄거나 켜거나 동적이게 할 수가 없음. handler 계약에 flag 하나를 두는 방향을 넣어보고싶어.
forDebug: boolean?(가칭) 만일 true면 debug 에서만 돌아. 여기서 핫패스에서 드는 비용을 줄이기 위해 debug 까지 포함하는 테이블
하나, debug 를 포함하지 않는 테이블 하나, - 그렇게 string/number 짝으로 맞춰놓는게 어떤가 싶어. 메모리 비용은 무시 가능한
수준이야. 프로덕션 비용을 줄이는 방향 나쁘지 않다고 보여."* 그 위에 메인 권고(사용자 수락 "이것도 좋아")인 "debug일 때만
NORMAL과 HIGH 사이에서 경고만 찍고 처리 안 함을 돌려 디스패치를 그대로 흘리는 필터"를 얹은 모양이다. 배경은
`../round13-q135-priority/README.md`. **결정은 하지 않는다**(프로토타입 당시 기준 — 결정은 머리 배너) — 기준 커밋 `c973d9fb`, 격리 워크트리, 커밋 없음.

## 파일

| 파일 | 내용 |
|---|---|
| `patch-fordebug.diff` | 전체 변경(`c973d9fb` 기준) — Dispatch 두 벌 버킷·`addHandler` 게이트 `Quad0266`·`Handler` 타입 필드·새 잎 `DebugKeyFilter.luau`·여섯 모듈 등록·errors/02 절 |
| `probe.luau` + `run-probe.sh` | q135 probe와 같은 케이스(A 문자 키 오용 56·A2 State/Store 경유 40·A3 Modifier 필드 9·B 정상 경로 27·C 다른 키 11·D 핸들러 목록·E NORMAL 오버라이드). `-a off`는 q135와 같은 출력 형식, `-a on`은 `q.debug = true` + 케이스마다 `>> label` 머리 |
| `out-probe-{off,on}-{HEAD,proto}.txt`, `out-probe-off-diff.txt` | 두 트리 × 두 모드 출력, debug 끔의 HEAD 대 proto diff(D 핸들러 목록뿐) |
| `analyze.py` → `out-analyze.txt` | debug 켬 출력에서 경고 줄을 케이스에 귀속, 경고 줄을 지운 동작이 HEAD와 같은지 대조 |
| `probe-toggle.luau` → `out-probe-toggle.txt` | 동적 토글·반복 억제·숫자 키 제외·`Quad0266`·debug 전용 "진짜" 핸들러·동률 줄·`listHandlers` (PASS/FAIL 열한 줄) |
| `probe-tieprint.luau` → `out-probe-tieprint-proto.txt` | `UseProvider` 전에 debug를 켜도 필터끼리 동률 줄이 나오는지 |
| `run-fuzz.sh`, `compare-fuzz.py` → `out-fuzz-*-{HEAD,proto}.txt`, `out-compare-fuzz.txt` | E64 base/prov 각 2000·E66 3000(q135와 같은 축소판), `time=` 빼고 대조 |
| `bench.luau` → `out-bench.txt` | 종단 비용: HEAD 트리와 이 트리(debug 끔/켬)를 **한 프로세스**에 올려 라운드마다 순서 교대, 9라운드 중앙값 |
| `bench-gethandler.luau` → `out-bench-gethandler.txt` | `getHandler` 단독 마이크로 벤치, HEAD / CONTROL(이 트리에서 분기만 `local set = buckets`로 바꾼 사본) / off / on, 11라운드 |

재현: 레포 루트에서 `./scripts/relink.sh` 뒤 `run-probe.sh proto`·`run-fuzz.sh proto`. HEAD 쪽은 `git archive c973d9fb`로 푼 트리에서
`pesde install`·relink 뒤 같은 스크립트를 `HEAD` 태그로. 벤치는 luau CLI가 작업 디렉터리 밖 `..`를 못 타서(`could not get parent of
component ".."`) HEAD 트리의 `quad-*` 다섯 폴더와 `round13-e66-handlers-fuzz`·`round13-e44-ref-statemachine`을 레포 루트의
임시 폴더(`.bench-head/`, CONTROL은 `.bench-control/`)에 복사해 돌렸고 끝난 뒤 지웠다:
`luau -O2 .claude/audit/round13-fordebug-proto/bench.luau -a ../../../.bench-head/.claude/audit/round13-e66-handlers-fuzz HEAD,off,on 9`.
모든 실행은 `ulimit -v 4000000` + `timeout` 아래. 벤치는 케이스마다 만든 Instance를 Destroy하고 모듈을 버린 뒤 전체 GC —
라운드마다 힙 6.5MB(종단)·2~3MB(마이크로)로 평탄.

## 모양

- **Dispatch**: `handlers`(정렬, 기존 그대로)와 별도로 `debugHandlers`(정렬)를 둔다. `rebuildBuckets`가 버킷 두 벌을 만든다 —
  `buckets`(기존 셋, debug 핸들러 없음)와 `debugBuckets`(같은 셋, `handlers`에 `debugHandlers`를 **안정 병합** — 동률이면 debug 쪽이 먼저).
  `getHandler`는 `local set = if module.debug then debugBuckets else buckets` 한 줄을 더한다(호출 시점에 읽음 → 토글 즉시 반영).
  `addHandler`: 신원 dedup을 두 배열에, `forDebug`가 boolean/nil이 아니면 `Quad0266`(새 raise 자리 → 새 ID, errors/02 절 초안 포함),
  `forDebug == true`면 `debugHandlers`에 넣는다. 동률 줄(원래 debug 전용)은 병합 목록 기준. `listHandlers`는 병합 목록(각 핸들러에
  `forDebug` 필드가 보인다).
- **왜 배열을 따로 두나 — 첫 컷에서 실측한 함정**: 처음엔 debug 핸들러를 `handlers`에 같이 넣고 버킷만 둘로 갈랐는데, debug **끔**에서
  probe C의 `[q.AttrKey("k4")] = q.Effect(…)`가 원시 `table is not a supported attribute type` → `Quad0097`로 바뀌었다. `table.sort`가
  불안정이라 핸들러 여섯이 더 들어간 것만으로 FALLBACK 동률(`EffectDynamicPathGuard` 대 `AttrKeyFallbackHandler`)의 순서가 다시
  섞인 것이다(E64 (a)가 본 "무관한 등록마다 동률이 섞인다"의 사례). 배열을 분리하면 `handlers`가 받는 삽입·정렬 열이 HEAD와 똑같아
  프로덕션 순서가 바이트 단위로 같고, 병합이 안정이라 debug를 켜도 프로덕션 핸들러끼리의 상대 순서는 그대로다(토글이 동률 승자를
  바꾸지 않음).
- **필터**: 새 잎 `quad-base/src/DebugKeyFilter.luau`의 `register(dispatch, name, kindOf)` — 브랜드 지식은 호출자(`H-278`)가 `kindOf(v)`로
  넘기고 이 파일은 핸들러 모양만 만든다. `forDebug = true`, `keyType = "string"`(숫자 키는 아예 안 물음), 우선순위 `NORMAL + 2`
  (Property NORMAL·InstanceShorthand NORMAL + 1 위의 가장 낮은 자리 — 내장 핸들러 중 NORMAL + 2 ~ HIGH − 1에 있는 것은 없다).
  `isHandlable`은 `type(v) ~= "table"`이면 바로 false, `kindOf`가 이름을 주면 `print` 한 줄(같은 (inst, key)는 한 번 — inst 약한 키 기록)
  뒤 **항상 false**. `process`는 도달 불가(`Void`). 문구: `Ref: found at string key "Name" - must be an array item (it would be assigned
  to the property as a value)` — 지시문 예시에서 관사만 뺐다(`a Attr`/`a Observer`가 나와서).
- **등록**: Ref(가족 하나 — `kindOf`가 PreRef/PostRef/Ref를 가름; 기존 가드 셋은 그대로), Observer, Effect, Slot, Tag, Attr — 여섯, 각자
  자기 Init의 기존 등록 옆. 기존 FALLBACK 가드·Tag/Attr 숫자 키 핸들러는 손대지 않았다.

## 결과

**(a) debug 끔 — 동작 바이트 동일.** probe 끔 출력은 HEAD와 D 절(핸들러 목록에 필터 여섯이 보이는 것)만 다르다(`out-probe-off-diff.txt`).
퍼저 셋 `time=`만 빼고 동일(E64 base·prov 차등 0, E66 diffSeeds 0, 오류 분포·동률 수까지 같음). `./scripts/test.sh` exit 0(스펙 62 —
첫 실행은 `table.create`가 `{unknown}`을 돌려 신 솔버 TypeError로 exit 1, `{}`로 고친 뒤 0).

비용(debug 끔). `getHandler` 단독(ns/호출, 11라운드 중앙값):

| | HEAD | CONTROL | off | on |
|---|---|---|---|---|
| 문자 키·문자열 값(Name) | 393.5 | 394.7 | 400.6 (+1.8%) | 563.6 (+43%) |
| 문자 키·테이블 값(Size) | 415.6 | 406.9 | 420.5 (+1.2%) | 1057.5 (+154%) |
| 숫자 키·Instance 자식 | 589.3 | 592.9 | 614.4 (+4.3%) | 614.5 (+4.3%) |
| 숫자 키·Tag(FALLBACK, 마지막) | 1344.4 | 1334.4 | 1366.1 (+1.6%) | 1364.8 (+1.5%) |

분기 하나의 값은 CONTROL 대비 6~30ns(1.5~4%) — 트리 사이 잡음(CONTROL/HEAD −2%~+0.6%)과 비슷한 크기라 상한으로 읽을 것.
종단(`out-bench.txt`, µs/op, 9라운드): off/HEAD가 전 케이스 0.96~1.04(마운트 5 문자 프로퍼티 1.016, 문자 키 emit 0.996~1.016,
숫자 키 emit 0.995~1.037) — 잡음 안이다. q135 갈래 F(필터 상시, +5%)·A(+55%)와 견주면 프로덕션 비용은 사실상 0.

**(b) debug 켬 — 원장 재현 전부 경고, 동작은 HEAD와 같음.** `out-analyze.txt`: 경고 줄을 지운 출력이 HEAD의 debug 켬 출력과 같다(True).
A 56칸·A2 40칸 = **오용 96칸 전부 경고**(경고 없는 칸 0). A의 숏핸드 `UICorner` 여덟은 두 줄씩 — 부모의 `"UICorner"`와, 숏핸드가 자식
`UICorner`에 위임한 `"CornerRadius"`(다른 인스턴스라 반복 억제에 안 걸림; 값이 어디로 갔는지까지 보여 오히려 유익). **정상 경로 B 27가지
경고 0**(B 절에 B 줄 말고 다른 줄 0). C 11칸 경고 0(숫자 키·AttrKey 키·boolean 키 — 필터는 문자 키만 본다). A3(Q137 ②): Modifier 필드
경유도 마운트 시점에 경고 6/6, 생성 시점 셋은 디스패치를 안 거치므로 0(Ref 필드는 원래 생성 때 에러). **E — 오탐 하나**: NORMAL에
`Observer@MyThing`을 의도적으로 받는 프로바이더 핸들러가 있어도 필터(NORMAL + 2)가 먼저 봐 경고를 찍는다(동작은 그대로 프로바이더가 받음).

비용(debug 켬): 문자 키 emit +14~17%, 테이블 값 문자 키 emit +52%(필터 여섯이 다 `kindOf`를 부름), 숫자 키 0~+3%, 마운트 −1~+7%.

**(c) 동적 토글** — `out-probe-toggle.txt` 11/11 PASS: 끔 → 경고 0·값은 그대로 대입(HEAD 동작), 켬 → 한 줄, 같은 (inst, key)에 State
51회 emit → 한 줄, 다른 키 → 따로 한 줄, 묶인 State가 emit하는 도중 끄면 0줄, 다시 켜면 다음 emit이 바로 경고, 숫자 키 다섯 종 0줄,
`forDebug = "yes"` → `Quad0266`, `forDebug = true`인 **진짜** 핸들러(true를 돌림)는 debug에서만 키를 잡고 끄면 `Quad0076`, 프로바이더가
필터와 같은 우선순위로 등록하면 debug에서 동률 줄 하나, `listHandlers`에 debug 핸들러 일곱(필터 여섯 + 프로브의 하나).
`probe-tieprint`: `UseProvider` 전에 debug를 켜도 동률 줄 0(필터는 `New()` 안에서, debug가 아직 false일 때 등록된다).

**(d)** `./scripts/test.sh` exit 0(스펙 62), `doc-check.py` ERROR 0, `error-codes.py check` 0 errors.

## 판단 재료(결정 아님)

- **이름 후보**: `forDebug`(가칭), `debugOnly`, `diagnostic`, `whenDebug`. 진짜 처리도 할 수 있는 일반 플래그라(c의 debug 전용 진짜 핸들러)
  "진단"으로 좁힌 이름(`diagnostic`)보다 조건을 말하는 이름(`debugOnly`/`forDebug`)이 실제 의미에 맞다.
- **반복 억제**: (inst, key)당 한 번, 필터별 약한 기록 — debug에서만 생기는 메모리라 비용 문제 없음. 없으면 State가 프레임마다
  emit하는 자리(스프링 등)에서 초당 수십 줄. 한계: 토글로 껐다 켜도 같은 (inst, key)는 다시 안 찍는다. 넣을지 말지는 취향 — 넣는 쪽 권고.
- **알려진 잡음 둘**: ① 모르는 키(`Foo = ref`)는 경고 뒤 곧바로 FALLBACK 가드가 `Quad0137`로 던져 두 번 알린다(괄호 속 "property에 대입된다"도
  그 자리엔 틀림). ② 위 E — NORMAL·NORMAL + 1에서 문자 키의 quad 값을 의도적으로 받는 프로바이더는 debug에서 오탐을 본다(우회: NORMAL + 3 이상에
  등록). 둘 다 필터가 "아래에서 누가 받을지"를 모르기 때문이고, 그걸 알려면 Dispatch가 스캔을 이어서 보는 깊은 검사가 필요하다(debug 층이니
  비용은 괜찮지만 새 메커니즘). 문구를 중립으로("a string key hands it to whichever handler takes that key") 바꾸는 것이 싼 대안.
- **우선순위 NORMAL + 2 대 HIGH − 1**: 내장 핸들러 기준으론 같다. NORMAL + 2는 프로바이더가 NORMAL + 3 이상으로 오버라이드하면 경고를 안 보고,
  HIGH − 1은 HIGH 밴드 아래 모든 프로바이더 오버라이드에 경고한다. 프로토는 NORMAL + 2.
- **필터 키 범위**: `keyType = "string"`만. 표 키(`[q.AttrKey("k")] = q.Ref(nil)`)·boolean 키는 안 본다 — 그 자리는 조용한 대입이 아니라
  에러(가드 ID 또는 원시 attribute 에러, FALLBACK 동률 운)라 Q135 증상 밖. 넣으려면 `keyType = nil` + `type(k) ~= "number"`(debug에서
  숫자 키 스캔마다 필터 여섯 호출이 더 붙음).
- **파일 배치**: `DebugKeyFilter.luau`를 최상위 잎으로 뒀다 — `architecture.md`의 `Dispatch/` 폴더 규칙("코어와 drive 단계만")에 안 맞아서.
  브랜드 지식은 없다(각 모듈이 `kindOf`로). 여섯 모듈에 8줄씩 인라인하는 갈래도 가능.

## 계약·문서에 미칠 영향(결정 뒤 고칠 곳)

- **quad-types `Handler`**: `forDebug: boolean?` 한 줄(프로토 반영). `Dispatch` 타입은 그대로.
- **extend/02 핸들러 계약 표**: `forDebug` 행 추가(등록 때 한 번 읽음 — 나중에 필드를 바꿔도 이동 안 함, `keyType`과 같은 성질). `isHandlable`
  행의 "순수 판별, 부작용을 넣지 마세요"에 예외 — `forDebug` 핸들러의 진단 출력. `getHandler`가 공개 "순수 스캔"인데 debug에서는 필터가
  `print`할 수 있다는 한 줄. `listHandlers`는 debug 핸들러도 돌려준다. 우선순위 밴드 절에 "NORMAL + 2에 debug 전용 필터가 있다 — 그 아래에서
  배열 전용 quad 값을 의도적으로 받는 핸들러는 debug에서 경고를 본다". 동률 절: debug 핸들러와의 동률은 debug에서만 의미가 있고 줄도 그때만.
  `addHandler` 모양 검사 블록에 `Quad0266`.
- **errors/02**: `Quad0266` 절(프로토에 초안). core/01 `q.debug` 절의 "읽는 자리" 목록에 이 경고, `architecture.md` "debug 층" 절의
  "2026-10-01 현재 읽는 자리"에도.
- **core/07·core/09·errors/04** 등 q135 README "고칠 문서"의 반영 프로퍼티 예외 문장들은 **그대로 맞다** — 이 갈래는 동작을 안 바꾸므로
  "그 문자 키가 반영 프로퍼티 이름이면 Property가 받는다"는 서술이 유지되고, "debug를 켜면 경고"만 덧붙이면 된다.
- 정본: `dispatch-core-plan.md` "핸들러 계약"·버킷(`H-484`) 서술, `architecture.md` "debug 층".
- CHANGELOG `[Unreleased]` Added(핸들러 `forDebug` 필드, debug 경고).

## 같은 수단을 다른 debug 검사에 쓸 수 있나 (의견)

`forDebug` 핸들러는 "스캔 시점에 (inst, key, value)를 보는 술어"만 표현할 수 있다. Dispatch `checkRetractorShape`(Q148)는 `h.process`가
**돌려준** retractor를 보는 검사라 스캔에 끼울 자리가 없고, 지금 모양(`if module.debug then` 한 줄)이 이번 선택 분기와 같은 비용이라 옮길
이득도 없다. 나머지 debug 분기(동률 줄·`AddPlugin`·옵션 모르는 키·`Claim` 디스크립터·Observer/Effect 루프 한도)는 등록·생성 시점의 콜드
패스거나 루프 카운터라 해당 없음. 대신 이 수단이 맞는 자리는 (1) q135 README "남는 구멍"의 같은 결 — Store·Blocker·Context·Provider를
반영 프로퍼티 키에 둔 것, 이벤트 키에 함수 아닌 값 같은 "키에 놓인 값의 모양" 경고, (2) 프로바이더가 자기 값 타입에 같은 경고를 붙이는
것(필드가 공개 계약이 되면 프로바이더도 쓸 수 있다 — 갈래 F의 비공개 목록과 다른 점), (3) `quad-debug`용 디스패치 추적 — HIGH 위에 항상
false를 돌리며 (inst, key, value)를 기록하는 debug 전용 핸들러. "두 벌 테이블을 debug로 고른다"는 일반 아이디어는 다른 핫 패스에도
쓸 수 있지만, 지금 다른 debug 분기들은 이미 분기 하나짜리라 바꿀 곳이 없다.

## 미완·미실측

- debug **켬** 상태로 퍼저를 돌리지 않았다(퍼저 인자에 debug 스위치가 없음). 필터가 항상 false라 이론상 영향은 없지만 실측은 아님.
- 실엔진(Studio)은 안 봤다 — 엔진 `print` 출력·실제 Roblox Instance 약한 키 기록. mock만.
- 문서(extend/02·core/01·architecture)·CHANGELOG·정본은 안 고쳤다(errors/02 `Quad0266` 절만 — test.sh 게이트 때문).
