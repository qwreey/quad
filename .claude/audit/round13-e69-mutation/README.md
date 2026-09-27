# E69 — 스펙 묶음의 결함 탐지력 측정(뮤테이션 테스트)

round13 자율 루프 탐사 E69. 사용자의 테스트 정책 결정(round13 묶음 11, `Q120`/`Q123`)의 입력 자료다.
측정 대상은 HEAD `e3359a4f`의 `quad-base/src`·`quad-roblox/src` 핵심 모듈이고, 판정 도구는
`./scripts/test.sh`가 도는 smoke/spec 62파일(타입 검사·게이트 스크립트는 제외 — spec 실행만)이다.
본 트리는 건드리지 않았고, 모든 변이는 별도 git worktree(스크래치패드, 작업 뒤 제거)에서 했다.
새 spec은 본 트리에 쓰지 않았다 — 아래 "spec 스케치"는 제안일 뿐이다.

## 파일

| 파일 | 내용 |
|---|---|
| `mutants.py` | 변이 243개 목록(모듈·줄·원문 조각·치환). 줄 번호는 `e3359a4f` 기준 |
| `run_mutants.py` | 드라이버 — 변이 하나 적용 → `luau-compile`로 구문 확인 → `relink.sh` → spec 62개 병렬 실행(각 30초 제한) → 원복. 사용법 `python3 run_mutants.py <worktree>` |
| `results.json` | 변이별 결과(KILLED/SURVIVED, 잡은 spec 목록, 실패 출력 꼬리, 소요 초) |
| `probe.e69.luau` | 살아남은 변이를 분류하려고 쓴 판별 프로브(P1~P19, mock 백엔드). spec이 아니다 |
| `probe_survivors.py` | 살아남은 변이 48개마다 다시 적용해 프로브를 돌리는 스크립트 |
| `probe-results.json` | 그 결과(변이별로 프로브의 어느 검사가 깨졌는지) |
| `coverage.txt` / `merge_coverage.py` | `luau --coverage`로 spec 62개를 돌려 합친 파일별 줄 커버리지 |
| `spec-timing.txt` | spec 파일별 순차 실행 시간(ms) |

재현: 워크트리에서 `pesde install`(또는 본 트리의 `luau_packages/` 복사) → `./scripts/relink.sh` →
`python3 run_mutants.py <worktree>` → `python3 probe_survivors.py <worktree>`.

## 결과 요약

변이 243개 중 195개가 죽고 48개가 살아남았다(구문 오류로 건너뛴 변이 0). 원점수는 **80.2%**다.
살아남은 48개를 프로브·추론으로 나누면 행동상 동등(equivalent)이 20개, 동등일 공산이 크지만 증명하지 못한 것이 3개,
**실제 공백이 25개**(프로브로 확인 22 + 확인 못 한 3)다. 동등 23개를 분모에서 빼면 보정 점수는 **88.6%**(195/220)다.

| 모듈 | 변이 | 죽음 | 생존 | 원점수 |
|---|---|---|---|---|
| State.luau | 17 | 14 | 3 | 82% |
| Source.luau | 6 | 5 | 1 | 83% |
| Store.luau | 6 | 6 | 0 | 100% |
| EpochMap.luau | 3 | 3 | 0 | 100% |
| Effect.luau | 21 | 16 | 5 | 76% |
| Observer.luau | 11 | 9 | 2 | 82% |
| Dispatch/init.luau | 18 | 16 | 2 | 89% |
| Slot/*(init·Raw·List·Owner·Tree) | 47 | 31 | 16 | 66% |
| Bookkeeping.luau | 16 | 7 | 9 | 44% |
| Blocker.luau | 5 | 5 | 0 | 100% |
| Context.luau | 4 | 4 | 0 | 100% |
| LifetimeHandle.luau | 6 | 5 | 1 | 83% |
| Ref/init.luau | 11 | 11 | 0 | 100% |
| Tag.luau | 8 | 6 | 2 | 75% |
| Attr/init.luau | 6 | 5 | 1 | 83% |
| Debounce.luau | 11 | 10 | 1 | 91% |
| Operator.luau | 6 | 4 | 2 | 67% |
| quad-roblox Handlers/Property.luau | 16 | 13 | 3 | 81% |
| Handlers/Event·OnChange·InstanceChild·InstanceShorthand | 15 | 15 | 0 | 100% |
| Tween.luau / Animate.luau | 10 | 10 | 0 | 100% |
| **합계** | **243** | **195** | **48** | **80.2%** |

변이를 가장 많이 잡은 spec은 `spec.slot`(54)·`spec.effect`(34)·`spec.tweenproperty`(33)·`spec.handlers`(26)·
`spec.shorthand`(25)다. 타입 전용 spec(`*types`, `rootexports`, `d`)과 `brand`·`relate`·`void`·`fallback`·
`errorcodes`·`errorutil`·`versioncheck`·smoke 둘은 이번 변이를 하나도 잡지 않았다 — 변이 대상 모듈을
보지 않거나(타입 spec) 변이를 넣지 않은 모듈(Brand·Relate·Fallback)을 보는 spec이라 이상한 일은 아니다.

## 실제 공백 — spec이 잡았어야 하는 생존 변이

아래는 프로브가 실제로 행동 차이를 드러낸 것들이다. 문단마다 변이, 깨지는 계약, 어떤 spec이 없어서 살아남았는지를 적는다.

**같은 Effect를 같은 자리에 다시 흘려보내는 경우(`EF17`, `EF18`).** `Effect.luau` 399행의 `if old ~= v then`을 항상 참으로 바꾸면
같은 Effect를 같은 인스턴스·같은 자리로 다시 `drive`할 때 `Quad0232`(이미 이 인스턴스에 묶임)가 터지고, 404행의 retractor 조건
`if nextValue ~= v then`을 항상 참으로 바꾸면 재발행마다 cleanup이 한 번 돌고 fn이 한 번 더 돈다. 원래 코드는 같은 값 재발행을
통째로 접는다(`H-266`이 "load-bearing dedup"이라 부른 자리, `docs/reference/core/05-observer-effect.md`의 Effect 배치 서술). 두 변이가 산 것은
spec 어디에도 "같은 `{ effect }`를 두 번 drive" 시나리오가 없어서다. 같은 모양의 Observer 변이 `OB10`은 retractor가
relate 칸까지 지워 process가 곧바로 다시 묶으므로 겉보기 행동이 같아 동등으로 분류했다(부작용 없는 unbind/rebind 한 바퀴).

**Effect:WeakSubscribe를 두 번 부르는 경우(`EF11`).** 236행 `canBound` 게이트를 없애도 spec이 통과한다. 두 번째
`WeakSubscribe`는 `Quad0089 Effect: already subscribed`(인스턴스에 묶인 Effect면 `Quad0230`)를 던져야 한다
(`docs/reference/errors/04-ref-observer-effect.md`). 커버리지로도 237행(에러 줄)이 한 번도 실행되지 않았다.

**Observer:Unsubscribe 뒤 표시 문자열(`OB06`).** 179행 `WeakSubscribed[self] = nil`을 지우면 `tostring(o)`이
`Observer(unsubscribed)` 대신 `Observer(weak)`를 낸다. 실행 게이트(`canExecute`)는 `Subscribed` 플래그를 보므로 동작은
안 바뀌고 진단 문자열만 틀린다 — `spec.tostring`이 Unsubscribe 뒤 상태를 보지 않는다. 가벼운 공백.

**Dispatch.process의 구멍 게이트(`DI07`).** 328행을 `index > #list + 2`로 늦추면 빈 체인에 index 2가 들어가도
`Quad0075`가 안 나고 조용히 구멍이 생긴다(`docs/reference/errors/02-dispatch-bookkeeping.md`의 Quad0075).
`Quad0075`를 기대하는 spec이 없다.

**같은 핸들러 재진입에서 process가 던질 때(`DI10`).** 354행 `slot.retractor = NOOP`(옛 retractor를 소비 표시)을 지우면,
같은 핸들러로 다시 흘린 값의 process가 던진 뒤 그 자리를 `retractFrom`할 때 옛 retractor가 **두 번** 불린다(프로브 P19:
1 → 2). 주석이 말하는 "no double call" 불변이 spec에 없다.

**Slot:IndexOf가 빠진 원소에 옛 번호를 돌려주는 경우(`SW04`, `SW07`).** `Slot/Raw.luau` 97행(vacate의
`indexOfElement[element] = nil`)이나 198행(rawReplace의 옛 원소 칸 비우기)을 지우면 `s:Remove(1)` 뒤 `s:IndexOf(a)`가 nil 대신
1을, `s:Replace(1, c)` 뒤 `s:IndexOf(b)`가 1을 낸다. `docs/reference/core/06-slot.md`의 IndexOf는 "없으면 nil"이다.
spec은 남아 있는 원소의 IndexOf만 본다(`spec.slot` 1027행 근처 permute 검사).

**떼어 둔(Detach) 원소를 nil로 버릴 때의 파괴(`SW14`).** `releaseElement`의 `wasDetached` 갈래에서 `self._owned ~= false`를
뒤집으면, 소유 리스트가 Detach로 들고 있던 원소를 updateFn이 nil로 버려도 파괴되지 않는다(프로브 P7). `Slot:List`의
Detach→nil 경로를 파괴 여부까지 보는 spec이 없다. 같은 계열로 커버리지상 `Slot/List.luau` 51·52행(`OwnsElements=false`에서
Detach), 77~79행(Detach 중인 키에 새 원소), 188~192행(리스트 슬롯이 사라질 때 Detach 보관분 정리)과 `Slot/Tree.luau`
180~183·203~206행(Detach 보관분이 있는 Slot의 파괴)은 **한 번도 실행되지 않는다** — Detach 수명 전체가 spec 밖에 있다.

**Slot:List의 중복 키 게이트(`SL04`).** 116행 게이트를 없애면 `Quad0145 duplicate key` 대신 내부에서
`table index is nil`이 터진다(에러 계약 위반). 에러 줄 117행은 커버리지 0이다.

**Slot:List의 UserData 왕복(`SL06`).** 151행 `userdata[key] = ud`를 지우면 updateFn이 둘째 반환값으로 준 UserData가
다음 조정 때 `ctx.UserData`로 돌아오지 않는다(프로브 P6: 1이어야 할 값이 nil). `docs/reference/core/06-slot.md` 367·378행이
약속하는 기능인데 spec이 왕복을 보지 않는다.

**배치 게이트가 풀리는 경우 — Length 발화 횟수(`SL10`, `BK10`).** `Slot/List.luau` 124행의 `ownsGate`를 뒤집거나
`Bookkeeping.luau` 323행 `if blocker.Blocking then return end`를 지우면 최종 배치는 같지만, 다섯 원소를 한 번에 넣는
조정에서 `Length`가 1번이 아니라 5번 발화한다(프로브 P17). `H-479`(배치 1회) 계열의 성능·발화 횟수 계약이고, spec은 최종
상태만 본다. 기능 결함이라기보다 "발화 횟수 회귀를 못 잡는다"는 공백.

**List 경로의 이중 마운트(`SN01`).** `Slot/Owner.luau` 27행 claimOwner 게이트를 없애면, updateFn이 이미 다른 Slot에 들어
있는 원소를 돌려줘도 에러가 안 난다(프로브 P11). 공개 CRUD 입구는 `prepareElements`(`Slot/init.luau` 254행)가 따로 막아서
그쪽 spec이 통과하지만, List 조정 경로는 claimOwner가 유일한 문이다(`Quad0156`).

**공개 `q.Bookkeeping.releaseOwner`의 주인 불일치(`SN03`).** 69행 게이트를 없애면 다른 주인이 좌석을 풀어도 조용히
풀린다. `Quad0163`는 Q48로 공개한 op의 에러인데 spec이 기대하지 않는다.

**중첩 Slot의 기준 오프셋(`BK16`, `SE01`) — 이번 측정에서 가장 큰 공백.** `Bookkeeping.luau` 170행에서 Slot 주인의
기준값 `ownerKey.Offset:Get()`을 0으로 바꾸면, 0이 아닌 자리에 놓인 Slot의 자손 오프셋이 전부 기준만큼 어긋난다(프로브 P1:
`inner.Offset`이 1이어야 할 때 0, 물리 삽입 위치도 같은 캐시를 쓴다). `Slot/Tree.luau` 28행(기준 Observer가 캐시를 0으로
되돌리는 줄)을 지우면 삼촌 Slot이 자라 이 Slot의 기준이 옮겨갈 때 자손 오프셋이 안 따라간다(P1c: 3이어야 할 때 2).
spec은 형제 Slot의 오프셋(`spec.slot` 4절 — 둘째 Slot 자체의 Offset)이나 0에 놓인 루트의 자식들만 보고, **"0이 아닌 기준 위의
손자"**를 보는 검사가 없다. 계약 서술은 `.claude/base/dispatch-core-plan.md`의 Length/Offset 절과
`docs/reference/core/06-slot.md`의 Offset.

**Splice 범위 게이트(`SI09`).** `Slot/init.luau` 328행을 한 칸 늦추면 `Splice(1, 2)`(원소 하나)가 `Quad0174` 대신
`Quad0161 releaseOwner: element must not be nil`로 죽는다. 에러 계약 위반.

**Tag 중첩 깊이 게이트(`TG08`).** 113행 64를 640으로 바꿔도 통과한다 — 65단 중첩이 `Quad0201`을 내야 한다(P13).

**Debounce의 State Time 음수(`DB01`).** `readTime`의 `v < 0`을 `v < -1`로 바꾸면 State로 준 `Time = -0.5`가
`Quad0039` 대신 mock의 `setTimeout` 자체 검사에서 죽는다. 실제 엔진 op(`task.delay`)는 음수를 조용히 받으므로 Roblox에서는
에러가 사라진다. spec은 리터럴 Time만 음수 검사한다(`checkTime`).

**Operator 경계(`OP03`, `OP05`).** `Clamp`의 `lo > hi`를 `>=`로 바꾸면 `Clamp(3, 3)`이 `Quad0124`로 죽는다(허용돼야 하는
경계). `Shr`의 `bit32.rshift`를 `bit32.arshift`로 바꾸면 최상위 비트가 선 값(`0x80000000 >> 4`)에서 부호 확장이 일어난다.
spec이 경계값·상위 비트를 쓰지 않는다(`docs/reference/sugar/02-operator.md`).

확인 못 한 실제 공백 셋: **`PR10`**(`Handlers/Property.luau` 278행 `and v.Reverses ~= true` 제거) — `Tween{ Time = 0,
Reverses = true }`가 엔진 트윈 대신 스냅이 된다. `docs/reference/roblox/06-tween-animate.md` 85행이 "`Reverses`가 있으면 평소대로
엔진 트윈"이라고 명시하는 조건인데 spec이 `Time = 0`과 `Reverses`를 같이 쓰지 않는다(quad-roblox 프로브는 안 썼다).
**`BK02`·`BK04`**(`getOffsetAt` 207행과 `recompute` 261행의 되감기 가드) — 두 가드가 지키는 경로(길이 State의 `Get`이
사용자 코드를 돌려 부기를 바꾸는 재진입)는 커버리지상 **한 번도 실행되지 않는다**(213~216행, 262~264행). 프로브로 그 경로를
만들지 못해 행동 차이는 확인 못 했다.

## 동등 변이 — 행동이 같은 것

`ST05`(재계산 성공 뒤 `_computing = -1` 삭제)는 세대 번호가 `bnot(-x) = x-1`로 단조 감소해 재사용되지 않으므로 순환 가드가
오발하지 않는다. `SW02`·`SW03`(splice 때 캐시 무효화를 `index-1` 대신 `index`까지)는 `offsetCache[index]`가 1..index-1의 길이
합이라 index 자리 삽입·삭제에 안 바뀌므로 원래 코드가 한 칸 보수적인 것이다. `SW16`(`rotateInPlace` 루프를 한 칸 더)은 늘어난
한 칸이 바로 뒤 `arr[to] = v`로 덮인다. `BK01`(`<=` → `<`)은 경계에서 while을 0회 돌고 같은 값을 돌려준다. `BK07`·`BK13`은
같은 값을 루프·`gatedRecompute`가 이미 쓴다. `BK06`(274행 되감기)은 293행 가드와 짝으로 중복이다 — 둘을 같이 지우면 P18과
`spec.lengthoffset`이 잡는다(따로 실측, 한쪽만 지우면 둘 다 통과). `BK11`(옛 길이 Observer 칸을 비우지 않음)은 그 Observer가
이미 풀려 있고 `unbindLifetime`이 멱등이다. `SN04`(`OWNER_POS`를 비우지 않음)는 `OWNER`가 같을 때만 읽히고 claim 때 항상 새로
쓴다. `SE02`는 blocker가 켜진 창 안의 추가 무효화 한 번, `SE03`은 파괴 본문 자체가 멱등이라 두 번 돌아도 같다. `TG04`는 같은
Tag 객체 재발행의 빠른 길(아래 루프도 `Contains`로 전부 건너뛴다). `AT01`은 `flattenArg`의 `overwrite=false` + Store/평범한
테이블 조합에 닿는 공개 호출이 없어 죽은 코드다 — `docs/reference/errors/05-tag-attr.md`가 이미 Quad0004·Quad0009를
"도달하지 않음"으로 적어 두었다. `PR12`·`PR13`은 Disconnect가 멱등이고 `rec.Cb`가 먼저 nil이 되어 두 번째 콜백이 불가능하다.
`OB10`은 위에 적었다. `EF02`(`_cleanupRunning` 보류 조건 삭제)는 cleanup이 `_running` 밖에서 도는 세 자리(Unsubscribe,
Destroying, 언바인드 retractor) 모두 그 시점에 실행 불가라 98행 재검사가 같은 보류 상태를 만든다 — `H-160`의 방어 중복층이다.
`EF16`(Effect 생성 때 epoch 의존의 `Sync` 삭제)은 첫 발화가 어차피 새 revision이라 결과가 같다. `LH06`(unbind 때
`_unbindDestroying` 삭제)은 이후의 bind/Subscribe가 모두 스스로 `_unbindDestroying`을 불러 행동은 같고, 남는 차이는 옛 인스턴스의
Destroying 연결이 그 인스턴스가 죽을 때까지 Effect를 붙잡는 **보유(GC) 차이**뿐이다.

동등일 공산이 큰 셋 — `ST04`(재계산 전 `dep:_track` 삭제), `SR05`(Source `_track` 무효화, `ST04`의 유일한 호출자),
`ST09`(Gate flush의 `emitEpochMap:Sync` 삭제). 앞의 둘은 값 맵이 `_receive`의 `Update`와 `Get`의 `Refresh`로 이미 최신으로
유지되어 재시드가 중복으로 보이고, 셋째는 Gate 위쪽 노드가 같은 revision 재전달을 이미 삼키므로 Gate의 emit 맵 `Peek`이 참이 되는
경우가 새 revision뿐으로 보인다. 다만 이 둘은 "그런 경로가 없다"를 추론으로만 보였고 퍼저로 증명하지 않았다.

## 커버리지 없는 모듈

`luau --coverage`로 spec 62개를 합쳐 보면 **spec이 전혀 실행하지 않는 소스 모듈은 없다**(`coverage.txt`). 가장 낮은 것도
`Slot/Tree.luau` 90%, `Slot/List.luau` 91%, `Bookkeeping.luau` 93%, quad-roblox `LifetimeHandle.luau` 93%다. 즉 이번 공백은
"안 도는 코드"보다 **"도는데 결과를 단언하지 않는 코드"**가 대부분이다 — 생존 변이 48개 중 커버리지 0인 줄은 `EF11`(1회
실행된 게이트 줄이지만 에러 갈래 0) 정도이고, 나머지는 수십~수백 번 실행된다(`BK16` 170회, `SE01` 71회). 실행되지 않는 줄
묶음은 위에 적은 Detach 수명(List·Tree), rawReplace의 "마운트 안 됐지만 물리 대상이 있는" 갈래(`Slot/Raw.luau` 213~220)와
마운트 상태의 Slot↔잎 교체(231·232·241·242), 두 되감기 경로, `Debounce` MaxTime 캡 해제(178·179)다.

## spec 실행 시간

spec 62개 순차 실행 합계 1.6초(가장 긴 파일 46ms — `spec.tween`·`spec.handlers` 등 quad-roblox 쪽), 8개 병렬로 돌리면 변이
하나당 평균 0.82초(relink 포함). 243개 전체가 4분 48초였다. `test.sh` 전체(타입 검사·게이트 포함)는 약 6.8초다.

## spec 스케치(제안 — 본 트리에 쓰지 않음)

프로브 `probe.e69.luau`의 P1~P19가 그대로 spec 후보다. 우선순위를 매기면 (1) P1 "0이 아닌 기준 위의 손자 Slot 오프셋과 물리
순서" — `BK16`·`SE01` 둘을 잡고 실사용 배치(목록 안의 목록)와 직결, (2) P2 "같은 Effect/Observer 재발행은 cleanup도 재실행도
없음" — `EF17`·`EF18`, (3) Detach 수명 묶음(P7 + 커버리지 0 줄들) — `SW14`, (4) P3 IndexOf 부재 — `SW04`·`SW07`, (5) P6
UserData 왕복 — `SL06`, (6) 에러 코드 묶음(Quad0075·0089·0145·0156·0163·0174·0201·0039) — `DI07`·`EF11`·`SL04`·`SN01`·
`SN03`·`SI09`·`TG08`·`DB01`, 한 파일에서 `pcall` + 코드 문자열 대조로 충분, (7) P17 배치 발화 1회 — `SL10`·`BK10`, (8) P19
process가 던질 때 옛 retractor 1회 — `DI10`, (9) Operator 경계(P15)와 quad-roblox `Tween{ Time = 0, Reverses = true }` — `OP03`·
`OP05`·`PR10`. 이것들을 넣으면 생존 25개 중 `BK02`·`BK04`를 뺀 23개가 잡힌다는 것이 프로브 실측이다(`PR10`만 미실측).

## 확인만 한 것

- 기준선: 워크트리에서 `./scripts/test.sh` exit 0(약 6.8초). 변이마다 원복 뒤 워크트리 `git status`가 깨끗했다.
- 구문 오류로 건너뛴 변이 0 — 모든 변이가 `luau-compile`을 통과했다.
- 변이 대상에서 뺀 모듈: `Brand`·`Relate`·`Claim`·`Fallback`·`LifecycleHooks`·`Dispatch/Modifier`·`Dispatch/None`·
  `Dispatch/StoreBind`·`Dispatch/Ref`·`Slot/Elements`·`Slot/Handler`·`Attr/Key`·quad-roblox `EngineOps`·`RobloxFactory`·
  `Declaration`(생성물)·`LifetimeHandle`(roblox). 이들의 점수는 이번 표에 없다(커버리지는 `coverage.txt`에 있음).
- `Quad0004`/`Quad0009`가 공개 표면에서 도달 불가라는 것은 레퍼런스 문서가 이미 적고 있었다(`AT01`).

## 미완

- `PR10`은 quad-roblox 프로브를 쓰지 않아 "실제 공백"을 문서 대조로만 판정했다(미실측).
- `BK02`·`BK04`는 되감기 경로를 만드는 프로브를 짜지 못했다 — 실제 공백인지 도달 불가 방어인지 **미판정**.
- `ST04`·`ST09`·`SR05`의 동등 판정은 추론이다 — 퍼저(E63식 차등)로 증명하지 않았다.
- 변이 연산자는 손으로 고른 계약 자리 243곳이고 무작위 표본이 아니다. 점수는 "이 자리들에서의" 탐지력이지 전 코드의 추정치가 아니다.
- 타입 spec(`*types`)의 탐지력은 이번 측정 범위 밖이다(런타임 변이만 넣었다).
