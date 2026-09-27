# E73 — 뮤테이션 테스트 2라운드(E69가 뺀 모듈 + E69 미완 셋)

round13 자율 루프 탐사 E73. E69(`.claude/audit/round13-e69-mutation/`)의 속편이고, 사용자의 테스트 정책 결정(round13
`Q154`)의 입력 자료다. 측정 대상은 HEAD `0f923432`에서 E69가 변이를 넣지 않은 모듈이고, 판정 도구와 분류는 E69와 같다 — 변이
하나를 넣고 `luau-compile`로 구문을 확인한 뒤 `relink.sh` → smoke/spec 62파일 실행, 하나라도 실패하면 KILLED, 전부 통과하면
SURVIVED, 구문 오류면 UNCOMPILABLE. 모든 변이는 스크래치패드의 별도 git worktree에서 했고(기준선 `./scripts/test.sh` exit 0,
약 7초), 작업 뒤 worktree는 지웠다. 본 트리엔 이 폴더 말고 아무것도 쓰지 않았고, 새 spec도 쓰지 않았다 — 아래 프로브는 spec이
아니라 살아남은 변이를 가르는 판별 도구다.

## 파일

| 파일 | 내용 |
|---|---|
| `mutants.py` | 변이 180개(모듈·줄·원문 조각·치환). 줄 번호는 `0f923432` 기준 |
| `run_mutants.py` | E69 드라이버 그대로(주석 한 줄만 다름). `python3 run_mutants.py <worktree> [id...]` |
| `run.log` / `results.json` | 전체 실행 로그와 변이별 결과(잡은 spec 목록, 실패 출력 꼬리, 소요 초) |
| `probe.e73.luau` | quad-base 판별 프로브(mock 백엔드) — 되감기 가드(`PBK`), Slot 핸들러·원소, Traceback, `PST04`·`PST09` |
| `probe.e73r.luau` | quad-roblox 판별 프로브(실물 `LifetimeHandle`·`EngineOps`·Property 핸들러를 mock 인스턴스 위에서) — `PR10`, 보유 op 계약, Claim 게이트, 생성 DefineSubtype 간선 |
| `probe_survivors.py` / `probe-results.json` | 살아남은 변이 31개 + E69 미완 변이(`PR10`·`BK02`·`BK04`·`BK06`·`ST04`·`SR05`·`ST09`, 짝 둘)를 하나씩 다시 넣고 두 프로브를 돌린 결과 |
| `fuzz.e73.luau` / `fuzz_diff.py` / `fuzz-results.json` | E69 `ST04`·`SR05`·`ST09`의 차등 퍼저(2000 시드)와 결과 |
| `e69-open-items-recheck.json` | E69 미완 변이 일곱을 HEAD `0f923432`의 spec으로 다시 돌린 결과(전부 여전히 SURVIVED) |

재현: worktree에서 `mise exec -- pesde install` → `./scripts/relink.sh` → `python3 run_mutants.py <wt>` →
`python3 probe_survivors.py <wt>` → `python3 fuzz_diff.py <wt>`.

## 결과 요약

변이 180개 중 149개가 죽고 31개가 살아남았다(UNCOMPILABLE 0). 원점수 **82.8%**. 살아남은 31개는 동등 9, 실제 공백 21(전부 프로브로
확인), 미판정 1이다. 동등 9를 분모에서 빼면 보정 점수는 **87.1%**(149/171)다. 변이 수가 요청 범위(80~120)보다 많은 것은 대상
파일 수가 많아서다 — 계약 자리만 골랐고 무작위 표본이 아니다.

| 모듈 | 변이 | 죽음 | 생존 | 원점수 |
|---|---|---|---|---|
| Brand.luau | 8 | 8 | 0 | 100% |
| Relate.luau | 9 | 9 | 0 | 100% |
| Claim.luau | 18 | 12 | 6 | 67% |
| Fallback.luau | 8 | 7 | 1 | 88% |
| LifecycleHooks.luau | 6 | 6 | 0 | 100% |
| Dispatch/None.luau | 7 | 6 | 1 | 86% |
| Dispatch/StoreBind.luau | 7 | 7 | 0 | 100% |
| Dispatch/Ref.luau + Ref/PreRef + Ref/PostRef | 11 | 11 | 0 | 100% |
| Dispatch/Modifier/Handler.luau | 1 | 1 | 0 | 100% |
| Dispatch/Modifier/init.luau | 35 | 32 | 3 | 91% |
| Slot/Elements.luau | 13 | 11 | 2 | 85% |
| Slot/Handler.luau | 11 | 5 | 6 | 45% |
| Attr/Key.luau | 10 | 8 | 2 | 80% |
| quad-roblox EngineOps.luau | 16 | 15 | 1 | 94% |
| quad-roblox RobloxFactory.luau | 3 | 3 | 0 | 100% |
| quad-roblox LifetimeHandle.luau | 14 | 6 | 8 | 43% |
| quad-roblox Declaration/init.luau(손으로 쓴 런타임 부분 3자리) | 3 | 2 | 1 | 67% |
| **합계** | **180** | **149** | **31** | **82.8%** |

변이를 가장 많이 잡은 spec은 `spec.modifier`(29)·`spec.claim`(27)·`spec.hooks`(24)·`spec.handlers`(24)·`spec.refhandlers`(20)·
`spec.slot`(20)이다.

**E69와 합친 숫자.** 이번에 E69 미완 셋을 닫으면서 E69의 분류가 바뀌었다 — `ST04`·`ST09`는 동등이 아니라 실제 공백으로(아래),
`SR05`는 동등으로 확정, `BK02`·`BK04`·`PR10`은 실제 공백으로 확인. 그래서 E69는 동등 21·실제 공백 27·미판정 0이 되고 보정
점수는 87.8%(195/222)다. 두 라운드를 합치면 변이 423개, 죽음 344, 생존 79 — 원점수 **81.3%**, 동등 30을 뺀 보정 점수
**87.5%**(344/393), 실제 공백 48, 미판정 1(`LR02`).

## 살아남은 변이 — 실제 공백(21)

**`q.Backend` 보유 op의 계약(`LR03`·`LR06`·`LR08`·`LR10`·`LR12`·`LR13`) — 이번 측정에서 가장 큰 공백.** quad-roblox
`LifetimeHandle.luau`는 spec이 실물로 돌리는데도 14개 중 8개가 살았다. `LR03`(83행 `if inst == nil then`)과 `LR06`(105행
`if value == nil then`)을 없애면 `isClaimed(nil)`·`isHeld(nil)`이 `false` 대신 Relate의 `Quad0138`로 죽는다 — 105행 주석이
직접 인용하는 round3 `H-444`(G-14)의 회귀인데 spec이 nil을 넣어 보지 않는다. `LR08`(118행 `held ~= nil and ` 제거)은 한 번도
묶이지 않은 값과 claim되지 않은 인스턴스에 대해 `isHeldBy`가 `nil == nil`로 **참**을 낸다. `LR10`(137행 `gchold[value] = true`
삭제)은 "값은 적어도 인스턴스만큼 산다"(주석의 contract 1)를 깨 — `bindLifetime`만으로 붙잡힌 Observer가 GC 뒤 사라져 발화하지
않는다(프로브: 0회). `LR12`(148행 `gchold[value] = nil` 삭제)는 `unbindLifetime` 뒤에도 값이 인스턴스가 죽을 때까지 붙잡힌다(조기
해제 계약, 누수). `LR13`(150행 삭제)은 풀어 준 값에 `isHeldBy(value, inst)`가 계속 참이다. 여섯 모두 spec에 GC 단언이나 해제
뒤 술어 단언이 없어서 살았다(E69 LH 계열과 같은 모양 — 계약이 "도는 코드"는 있고 "결과를 단언하는 코드"가 없다).

**Claim의 검증 패스(`CL06`·`CL07`·`CL15`·`CL16`·`CL17`).** `CL07`(133행에서 `i % 1 ~= 0` 제거)은 `[1.5] = 디스크립터`가 1패스에서
`Quad0031`로 막히지 않고 루트를 claim한 **뒤** drive에서 `Quad0085`로 죽는다 — 에러 코드뿐 아니라 `H-560`이 막으려던 "실패 뒤
루트가 claim된 채 남음"이 되살아난다(프로브 `CL07b`). `CL06`(129행 `type(i) == "number" and ` 제거)은 해시 키에 둔 디스크립터가
`attempt to compare string < number`라는 VM 에러로 죽는다. `CL15`(190행 게이트 삭제)는 디스크립터가 아닌 테이블을 둘째 인자로 줘도
에러가 없고, `CL16`(62행 `or className == ""` 제거)은 `newMapperClass("")`가 통과한다(`Quad0034`·`Quad0026`을 기대하는 spec이
없다). `CL17`(154행 plan 삽입을 앞쪽으로)은 drive 순서를 top-down으로 뒤집는데, 부모의 `OnRendered`가 자식 것보다 먼저 분다
(claim-plan §4의 bottom-up drive — spec은 최종 상태만 본다).

**Slot을 숫자 키 자리에 다시 흘리기(`SH05`·`SH06`).** `Slot/Handler.luau` 40행 `if claimOwnerAt(...)`를 항상 참으로 만들면 같은
Slot을 같은 자리에 다시 `drive`할 때 `Quad0232`(이미 묶임)가 터지고, 46행 `if slotValue == nextValue then return end`를 지우면
같은 재발행에서 원소가 빠졌다가 다시 들어간다(프로브: `nativeInsert` 2회 추가). E69 `EF17`·`EF18`(같은 Effect 재발행)과 같은
빈칸 — "같은 값 재발행은 no-op" 시나리오가 SlotHandler에도 없다.

**에러 코드만 달라지는 게이트(`SH03`·`EL02`·`EL04`·`SH01`·`SH02`·`EO12`).** `SH03`(36행 파괴 게이트 삭제)은 파괴된 Slot 마운트가
`Quad0140` 대신 뒤쪽 `Quad0164`(같은 문구)로 죽는다. `EL02`(Modifier 원소)·`EL04`(None 원소)는 `Quad0238`·`Quad0239` 대신 뭉뚱그린
`Quad0240 cannot mount`가 난다. `SH01`·`SH02`(29행 `k >= 1`·`k % 1 == 0` 제거)는 `drive`가 키 도메인을 먼저 막으므로(`H-495`)
사용자 표면에선 차이가 없고, 핸들러 작성자용 `Dispatch.process(inst, 0 또는 1.5, slot, 1)`에서만 `Quad0141` 대신 `Quad0019`가
난다 — 가장 약한 공백. `EO12`(148행 `or delay ~= delay` 제거)는 `setTimeout(fn, NaN)`이 `Quad0216` 없이 통과한다(spec은 음수만
본다). 여섯 모두 에러 코드 문서(`docs/reference/errors/`)의 약속인데 spec이 그 코드를 기대하지 않는다.

**Traceback의 trace 시작점(`FB05`).** `Fallback.luau` 53행 `debug.traceback(nil, 2)`를 `1`로 바꾸면 trace 첫 줄이 던진 자리가 아니라
`Fallback.luau:53`(에러 핸들러 자신)이 된다. 헤더가 "trace는 던진 자리에서"라고 적는데 spec은 trace가 문자열인지만 본다. 가벼운 공백.

**생성 DefineSubtype 간선(`DC02`).** `Declaration/init.luau` 5107행 `DefineSubtype("GuiObject", "ScrollingFrame")`을 지우면
`D.Modifier.GuiObject():AsScrollingFrame()`이 `Quad0056`으로 거부된다. spec은 생성 간선 중 TextLabel 하나만 표본으로 본다. 생성물
표 전체를 대조하는 검사(생성기 `check`와 같은 층)가 있어야 잡히는 종류라, spec 한 줄보다 생성기 쪽 게이트가 맞는 자리일 수 있다.

## 살아남은 변이 — 동등(9)과 미판정(1)

`CL11`(162행 claim 순서를 bottom-up으로)은 1패스가 이제 모든 인스턴스에 `isClaimed`를 묻기 때문에(round11 Q64 (b)) `nativeClaim`이
커밋 도중 실패하는 경로가 UB뿐이고, claim은 전부 drive 전에 끝나므로 순서가 관측되지 않는다. `NO05`(NilHandler의
`type(k) == "number" and ` 제거)는 `keyType = "number"`라 getHandler가 숫자 키 버킷에서만 이 핸들러를 묻는다(`H-484`). `MD04`
(`isAncestorOrSelf`의 자기 자신 즉답 삭제)와 `MD27`(DefineSubtype의 `parent == subtype or ` 제거)은 서로의 중복이다 — 호출자
둘(`castClosure`·`DefineSubtype`)이 같음을 먼저 걸러 내거나, 남은 쪽이 같은 경우를 잡는다(둘을 같이 지우면 달라진다). `MD34`
(DFS의 `seen` 생략)는 부모 그래프가 사이클 없는 DAG(사이클은 `Quad0067`로 거부)라 종료가 보장되고 다이아몬드에서 일만 늘어난다.
`SH08`(SlotHandler retractor의 `setEmpty` 삭제)은 숫자 키 자리의 철거 뒤엔 반드시 다음 핸들러(NilHandler 또는 새 값의 핸들러)가
그 자리를 다시 등록하거나 인스턴스째 죽으므로 관측되지 않는다(프로브 `PSH08`: State<Slot|nil>을 None으로, 다른 Slot으로 바꿔도 뒤
Slot의 오프셋이 같다). `AK04`·`AK07`(AttrKey 이름 좌석의 "같은 키" 예외와 해제 때 주인 확인)은 같은 핸들러 재처리가 항상 retractor를
먼저 돌려 좌석을 비우고, 다른 키가 좌석을 가진 상태에서 retractor가 도는 경로가 없어서(다른 키의 claim은 `Quad0002`로 막힌다)
같다 — drive 두 번·State 재발행·None 왕복을 임시 스크립트로 돌려 확인했다. `LR05`(`isClaimed`의 `gchold ~= nil and ` 제거)는
gchold와 gcconn이 서로를 붙잡는 한 쌍이라(gchold[1] = gcconn, gcconn의 클로저가 gchold를 캡처) 하나만 사라지는 상태가 없다.

미판정 `LR02`(74행 `gchold[1] = gcconn` 삭제)는 CLI mock에선 죽일 수 없다 — mock 시그널이 연결 객체를 배열로 강하게 들고 있어서
GC가 gcconn을 거두지 않는다. 실물 Roblox에서 `RBXScriptConnection` 래퍼가 약한 참조만 남았을 때 거둬지는지는 엔진 동작이라 Studio
실측 몫이다(거둬진다면 `isClaimed`가 GC 한 번에 거짓이 되는 실제 결함).

## E69 미완 셋의 판정

**(a) `PR10` — 실제 공백, 확인.** `Handlers/Property.luau` 278행 `and v.Reverses ~= true`를 지우면 `Tween{ Value = 5, Time = 0,
Reverses = true }`가 엔진 트윈 대신 즉시 스냅된다(mock 트윈 로그 1 → 0, 프로퍼티 0 → 5). `docs/reference/roblox/06-tween-animate.md`
85행 "그 셋 중 하나라도 있으면 평소대로 엔진 트윈"과 어긋난다. HEAD의 spec 62개 어느 것도 잡지 않는다 — `spec.tweenproperty`는
`Time = 0` 단독(스냅)과 `Time = 0, DelayTime = 1`(엔진)만 보고 `Reverses`·`RepeatCount` 조합은 보지 않는다. 프로브 `PR10a~c`가
잡는다.

**(b) `BK02`·`BK04` — 입력으로 도달 가능, 실제 공백.** 되감기 경로를 여는 열쇠는 **닫힌 Gate 뒤의 길이 Compute**다. 길이
State의 Observer는 값이 바뀌면 곧바로 `len:Get()`을 해서 fn을 미리 돌려 버리므로(`H-445`) 보통은 `contribution`의 `Get`이 사용자
코드를 돌릴 일이 없다. 그런데 Gate가 통지를 막으면 Observer는 울리지 않고 값만 낡아, 다음 `Get`(= `getOffsetAt`의 채우기)이 처음으로
fn을 돌린다(`H-540`의 drift 경로). 프로브 `PBK`는 위치 셋에 길이를 `S1`(Source)·`L2`·`L`(각자 닫힌 Gate 뒤의 Compute), 넷째에
발행 Source를 두고, `L`의 fn이 `L2`의 상류를 조용히 바꾸고 `L2`의 fn이 `S1`을 바꾸게 한다. 그러면 recompute가 넷째 자리의
`getOffsetAt` 안에서 `L2`를 처음 읽고, 그 fn의 `S1:Set`이 두 커서를 1로 내린다 — 207행 가드(`BK02`)가 채우기를 다시 시작하고
261행 가드(`BK04`)가 recompute를 1번부터 되감는다. `BK02`를 지우면 낡은 합이 캐시에 박혀 넷째 오프셋이 218이 아니라 213,
`getOffsetAt(inst, 2)`가 7이 아니라 2로 **영구히** 남는다(배치 블로커로 공개 `getOffsetAt`만 부르는 `PBKb`도 같은 결함을 낸다).
`BK04`를 지우면 둘째 자리의 발행 Source가 되감기 없이 낡은 값 2로 남는다. 두 변이 모두 HEAD spec을 통과한다. 이 입력은
fn 안에서 다른 Source를 `Set`하는 비순수 Compute라 권장 사용은 아니지만, 길이 State의 fn이 사용자 코드라는 `H-240`의 전제 그대로다.
같은 프로브로도 `BK06`(274행) 단독은 산다 — E69의 "293행 가드와 짝인 중복" 판정과 어긋나지 않는다.

**(c) `ST04`·`SR05`·`ST09` — 둘은 반박, 하나는 확정.** 퍼저는 Source 1~5개 위에 Compute(단일·이중 의존, 일부는 fn 안에서
Source를 `Set`)와 Gate(보류·통과·격번 통과 정책)를 무작위로 쌓고, Set(같은 값 포함)·Get·게이트 `emit(true/false/nil)` 60개를
돌리며 매 단계 Observer 발화 수와 Get 값을 기록한다. 구독자 순회가 해시 순서라 프로세스마다 달라지므로 기준선을 다섯 번 돌려 흔들리지
않는 시드(1998/2000)만 비교했고, 변이 쪽은 세 번 모두 다른 경우만 셌다. **`ST04`는 48시드에서 달라** 동등이 아니다 — 최소화하면
"격번 통과 Gate 뒤의 Compute가 첫 실행에서 자기 상류를 한 번 `Set`"하는 `H-198` 경우에서, fn 전 스탬프가 없으면 다음 세대의 `Get`이
fn을 한 번 더 돈다(3회 → 4회, 프로브 `PST04`; fn에 부작용이 계속 있으면 값까지 갈린다). 순수 fn에선 차이가 없었다. **`ST09`는
4시드에서 달라** 역시 동등이 아니다 — Gate 위의 Gate에서 아래 Gate가 이미 흘려보낸 revision을 위 Gate가 다시 넘길 때, flush의
`Sync(batch)`가 없으면 아래 Gate가 그것을 삼키지 못해 `emit()`이 `true`를 돌려주고 구독자가 **같은 값으로 한 번 더** 울린다(프로브
`PST09`: 1/2/1 → 1/2/1/1). **`SR05`는 0시드**로 달라지지 않았고, Source를 직접 의존하는 Compute에서 fn 안 재진입 Set 네 변형을
따로 돌려도 같았다 — Source 의존은 `_receive`의 `Update`가 늘 최신으로 유지해 fn 전 `Sync`가 중복이다. 동등으로 확정(퍼저 근거).

## 확인만 한 것

- 기준선: worktree에서 `./scripts/test.sh` exit 0. 변이·프로브 뒤마다 worktree `git status`가 깨끗했다.
- 두 프로브는 원본 코드에서 `PROBE ALL OK`. 실제 공백 21 + `PR10`·`BK02`·`BK04`·`ST04`·`ST09`는 전부 프로브의 어느 검사가 깨는
  것을 `probe-results.json`에서 확인했다.
- E69 미완 변이 일곱은 HEAD `0f923432`의 spec으로 다시 돌려도 전부 SURVIVED(`e69-open-items-recheck.json`) — E69 뒤 spec 변경
  (`8e44e1ab` 등)이 이들을 잡지 않는다.
- Brand·Relate·LifecycleHooks·StoreBind·Dispatch/Ref·PreRef/PostRef·RobloxFactory는 넣은 변이를 전부 spec이 잡았다.

## 미완

- `LR02`는 미판정이다 — 엔진 GC가 연결 래퍼를 거두는지는 Studio 실측이 필요하고, 이번엔 하지 않았다.
- `Declaration/`은 생성물이라 손으로 쓴 런타임 부분 세 자리만 변이했다. 생성 표(프로퍼티 유니언·DefineSubtype 간선 수십 개)의
  탐지력은 측정하지 않았다(`DC02` 하나가 그 공백의 표본이다).
- 퍼저의 Observer는 발화 수만 세고 콜백 안에서 `Get`·`Set`을 하지 않는다(해시 순회 순서가 기록을 흔들지 않게). 그 때문에 Observer
  콜백 안의 재진입 조합은 `SR05`의 동등 근거에 들어 있지 않다.
- 변이 연산자는 손으로 고른 계약 자리이고 무작위 표본이 아니다. 점수는 "이 자리들에서의" 탐지력이다.
- 타입 spec의 탐지력은 범위 밖이다(런타임 변이만 넣었다).
