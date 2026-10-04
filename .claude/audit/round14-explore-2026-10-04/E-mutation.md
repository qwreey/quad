# round14 탐사 E — 이번 주 바뀐 코드의 변이 테스트

> opus 탐사자 원문(2026-10-04, 읽기 전용, 공통 규칙 `round14-explore-2026-10-04/common-rules.md`). 서브에이전트가 파일을 쓰지 않아 메인이 보고 본문을 옮겼다. 결정 아님 — 메인·검증자 판정 전 원문.

## round14 각도 E — 이번 주 바뀐 코드의 변이 테스트 (r14x-e)

**기준**: 스크래치 사본은 HEAD `8592751f`에서 떴다. 탐사 도중 HEAD가 `bdd3e0bd`로 올라갔지만 그 커밋은 세션 기록뿐이라 `quad-base/src`와 `quad-base/test`의 diff는 0이다. 레포 파일은 하나도 고치지 않았다(`git status`에 보이는 `?? .claude/audit/round14-explore-2026-10-04/`는 내가 만든 것이 아니다). 실측 자리는 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-e/`이고, 다섯 패키지와 `scripts/`를 `cp -rL`로 복사한 뒤 relink했다. 변이를 다 돌린 뒤 사본의 `src`가 원본과 같은지 `diff -r`로 확인했다.

**방법**: E69·E73과 같은 판정이다. 변이 하나를 넣고 `luau-compile`로 구문을 본 뒤, relink하고 smoke·spec 63개를 실행한다. 하나라도 실패하면 죽음, 전부 통과하면 생존이다. 타입 검사 게이트는 변이마다 돌리지 않았다(E69와 같은 조건).

메모리 규칙은 다음과 같이 지켰다.
- spec 하나마다 프로세스를 따로 띄우고 `choom -n 1000 -- prlimit --data=<min(3 GiB, 여유/2)> -- timeout 60 luau`로 감쌌다. 예산은 변이마다 cgroup을 다시 읽어 계산했다.
- 변이도 spec도 전부 순차로 돌렸다.
- 작은 실행에서 잰 Max RSS는 26 MB였다. 예산과 거리가 멀어서 N을 줄인 곳은 없다.
- 실패가 나오면 그 변이에서 바로 멈췄다. 그래서 잡은 spec 칸은 알파벳 순서상 처음 실패한 spec 하나만 기록한다.

**산출물**(스크래치):
- 변이 목록 `m14.py`·`m14b.py`·`m14c.py`, 드라이버 `run_mut.py`, 결과 `results*.json`·`run.log`
- 판별 프로브 quad-base/test/probe.r14e.luau(스크래치 사본)
- 변이를 넣고 프로브를 다시 돌리는 `probe_mut.py`, 결과 `probe-run1.txt`·`probe-run2.txt`

**대상**: `git log --since=2026-09-30`의 열두 커밋(`682e2301`~`9787b0ec`)에서 바뀐 줄이다. 아홉 파일의 설치 창 보류, `_seenRevision`, `RERUN_LIMIT`, `SetIfChanged`·`SetAndDispose`·`checkSettable`, 세대 도장·드리프트 가지·Gate `_flush`, `countRewind`과 되감기 세 자리, flatten의 `Quad0085` 조건, debugOnly 버킷·`brandNamesOf`, `raiseChain`/`restoreChain`·순환 검사가 여기 든다. Gate `_flush`와 flatten의 `Quad0068`은 이번에 바뀌지 않았지만 요청 범위라 몇 개 넣었다.

### 집계

| 파일 | 변이 | 죽음 | 생존 |
|---|---|---|---|
| Observer.luau | 20 | 17 | 3 |
| Effect.luau | 17 | 14 | 3 |
| Source.luau | 15 | 14 | 1 |
| State.luau | 18 | 13 | 5 |
| Bookkeeping.luau | 11 | 5 | 6 |
| Dispatch/Modifier/init.luau | 10 | 9 | 1 |
| Dispatch/init.luau | 26 | 19 | 7 |
| Slot/Raw.luau | 11 | 5 | 6 |
| Slot/init.luau | 4 | 3 | 1 |
| **합계** | **132** | **99** | **33** |

원점수는 75.0%다. 생존 33개를 가르면 다음과 같다.

| 분류 | 수 | 변이 |
|---|---|---|
| 동등 | 16 | O05, O15, E07, E17, S10, F04, D04, D08, D17, D18, D19, R06, R14, T06, T17, K10 |
| 추정 동등 | 2 | T12, R02 |
| 던진 뒤 전용 | 1 | T01 |
| UB 전용 | 3 | K04, K06, T14(debug이면서 UB) |
| debug 전용 | 3 | K08, D03, D21 |
| 경계 여유 — 공백 아님 | 1 | K02 |
| **정의된 입력의 실제 공백** | **7** | O03, E05, K10b, R05, R15, R08, R09 |

동등과 추정 동등을 분모에서 빼면 보정 점수는 87.6%(99/113)다. UB·던진 뒤·debug 전용까지 빼면 실제 공백 비율은 7/106이다.

- 구문 오류였던 변이 둘(E16·F06)과 줄을 잘못 짚은 K06은 고쳐서 다시 돌렸고 위 숫자에 포함돼 있다.
- K10은 변이를 잘못 만들었다. 카운터를 저장하지 않아 사실상 아무것도 바꾸지 않는 변이였다. 그래서 K10은 동등으로 세고, 제대로 만든 K10b를 따로 하나 더했다.
- 가장 많이 잡은 spec은 `spec.dispatch`(20), `spec.observer`·`spec.source`(각 11), `spec.effect`(9), `spec.slot`(8), `spec.lengthoffset`(7)이다. 처음 실패한 spec 기준이다.
- 프로브의 R02b 시나리오는 HEAD에서도 실행마다 결과가 달랐다(약한 키 `_subs`의 순회 순서). 판정에서 뺐다.

### 정의된 입력의 spec 공백 (7)

**O03 — Gate 아래 Observer의 skip 조건에서 `from == self._state`를 빼도 살아남는다.**
`Observer.luau` `_receive`의 Q109 skip은 `from == self._state and self._seenRevision == from.Revision`이다. 앞 절을 지우면, 대상이 파생 State일 때 `_seenRevision`은 nil이다. 게이트가 보내는 배치 테이블도 `.Revision`이 nil이다. nil과 nil이 같으니 Gate·Blocker·Debounce 아래의 Observer가 flush 통지를 전부 버린다.

프로브 결과는 다음과 같다(HEAD → 변이).
- O03a, Gate 바로 아래: `fires=2` → `fires=1`
- O03b, Gate 아래 Compute: `10,20,30` → `10`
- O03c, `s:Apply(q.Blocker())` 아래: `1,5,6` → `1`

입력은 정의된 사용이다. 게이트 하류에서 다른 대상을 소비하는 평범한 Observer이고 되먹임이 없다. 결정은 Q109(2026-09-30)다. 코드 주석이 "only `from == _state` (a Source) … a gate batch (an EpochSet) is never skipped"라고 스스로 적고 있는데, spec에는 이것을 단언하는 곳이 하나도 없다. `spec.gate`는 맨 구독자 probe만 쓰고, Blocker·Debounce spec도 Observer의 발화 횟수를 보지 않는다(Effect는 별도 경로라 이 변이와 무관하다).

판정은 spec 공백이다. 코드 결함은 아니다. 최소 단언: Gate(또는 Blocker) 아래 State에 Observer를 `:Subscribe`하고, 닫혔다 열리는 flush 한 번 뒤 fn이 한 번 더 돌았는지(설치 포함 2회), 그 `from`이 배치 테이블인지 본다. Compute를 한 단 끼운 모양도 같이 단언한다.

처방 성격: 결정 없이 넣을 수 있다(주석과 Q109가 답을 가짐). 확신도: 높음.

**E05 — `RERUN_LIMIT` 카운터가 루프마다 0에서 시작한다는 것을 아무것도 고정하지 않는다.**
`local count = 0`을 핸들에 누적되는 카운터로 바꿔도 전부 통과한다. 프로브 E05에서 Effect 하나의 의존성을 바깥에서 따로 10,005번 Set하면, HEAD는 `runs=10006`이고 변이는 `Quad0263`으로 죽는다. E05b(9,000회짜리 자기 의존성 루프 두 번)도 HEAD는 `val=18000`, 변이는 `Quad0263`이다.

입력은 정의된 사용이다. 바깥 Set이고, 각 루프는 한도 아래다. 문서 core/05 240행이 "한 번의 반복이 1만 회를 넘게 다시 돌면"이라고 적고, PRINCIPLES C4는 "한 루프 1만 회"라고 적는다. 정확한 경계(E01·E02)는 spec이 잡는다. 빠진 것은 "루프가 바뀌면 카운터도 새로 센다"는 쪽이다.

최소 단언: 한 Effect에 의존성 Source를 바깥에서 10,001번 이상 따로 Set해도 `Quad0263`이 나지 않고, 실행 수가 설치 1 + Set 횟수인지 본다. 처방 성격: 결정 없이. 확신도: 높음.

**K10b — 부기 되감기 카운터가 패스마다 새로 센다는 것도 고정돼 있지 않다.**
`rewinds`를 `bk`에 누적하는 변이가 살아남는다. 프로브 K10은 수렴하는 Offset 되감기 고리(`spec.lengthoffset`의 (b) 모양, 패스당 498회)를 별개의 패스 25번으로 돌린다. HEAD는 `runs=12450 off=25500`으로 정상 종료하고, 변이는 `Quad0267`이다.

입력은 정의된 사용이다. Slot의 `Offset`/`Length` 고리는 C3의 예외이고 core/06 134행이 정의된 경로라고 적는다. 같은 행과 errors/02 `Quad0267`, CHANGELOG가 "한 번의 자리 계산이 1만 번 넘게"라고 한 패스 단위로 약속한다. 기존 spec (c)는 되감기 없는 긴 패스만 본다.

최소 단언: 수렴하는 되감기 고리를 여러 패스에 걸쳐 돌려 누적 되감기가 1만을 넘어도 던지지 않는지 본다. 처방 성격: 결정 없이. 확신도: 높음.

**R05·R15 — `restoreChain`이 저장한 값을 되돌리는지를 아무것도 보지 않는다.**
R05는 `slots[k]._materializing = olds[k]`를 `false`로, R15는 `olds`에 늘 `false`를 기록하게 바꾼다. 둘 다 살아남는다. 첫 프로브 R05·R05x는 이 차이를 건드리지 못해 같게 나왔다. 그래서 R05y를 새로 짰다.
- 장면: `drive(host, { gp })`로 gp가 마운트 walk를 도는 중이다. 그 안의 :List updateFn이 이미 walk가 끝난 형제 Slot에 `Slot`을 Add한다. 이 Add의 `raiseChain`이 gp=true를 저장했다가 복원한다. 같은 updateFn이 이어서 `gp:Add`를 한다.
- HEAD: `ok=false stage=sibAdded Quad0167`
- 두 변이: `ok=true stage=gpAdded`. 복원이 gp의 플래그를 꺼 버려 조상 CRUD가 통과한다.

입력은 정의된 거부 경로다. Q74 닫힘(2026-10-01, *"1. 의견대로."*)이 조상 사슬 전체 가드를 "정상 경로 결함"의 처방으로 채택했다. `materializeSlotTree`가 플래그를 true/false로 세우기 때문에 save/restore가 load-bearing이다. spec.slot의 Q74 절은 바깥 창이 없는 단일 창만 본다.

최소 단언: 조상이 마운트 walk 중일 때 그 안에서 형제 Slot에 Slot을 넣은 뒤 그 조상을 CRUD하면 여전히 `Quad0167`이고, 조상 원소가 그대로인지 본다. 처방 성격: 결정 없이. 확신도: 높음.

**R09 — `rawReplace`의 마운트된 경로(Raw 258행)에서 `raiseChain`을 빼도 살아남는다.**
spec이 덮는 것은 `rawAdd` 자리(R07, 죽음)뿐이다. 프로브 결과는 다음과 같다(HEAD → 변이).
- R08, 마운트된 p에 `p:Replace(1, c)`를 하고 c의 첫 updateFn이 `gp:Remove(2)`를 하는 장면: `Quad0167`, gp 길이 3 유지 → `ok=true`, gp 원소가 지워짐(`x1,c`)
- R08c, Slot 안 Source 원소를 `st:Set(c)`로 바꾸는 장면: 같은 차이

입력과 결정은 R05와 같다(Q74, 정의된 거부). 최소 단언: 마운트된 Slot에 `:Replace(i, 새Slot)`(그리고 원소 Source를 Slot으로 `:Set`)했을 때 새 Slot의 첫 updateFn에서 하는 조부모 CRUD가 `Quad0167`이고 조부모 원소가 유지되는지 본다. 처방 성격: 결정 없이. 확신도: 높음.

**R08 — `rawReplace`의 "물리 대상은 있으나 아직 마운트 전" 경로(Raw 238행).**
이 줄은 spec 전체에서 한 번도 도달하지 않는다. `print`를 넣어 63개를 다 돌려 확인했다(258행은 `spec.slot`이 2회 도달). 도달하는 입력을 찾았다(R08d). `p:Splice(2, 0, first, second)`에서 second의 updateFn이 아직 마운트 전인 first에 `first:Replace(1, repl)`를 하고, repl의 updateFn이 `first:Add`를 한다.
- HEAD: `Quad0167`
- 변이: `ok=true`, `first`에 원소가 끼어든다(`p0,r,bad,s`)

입력은 정의된 거부 경로다. 형제 CRUD는 허용되고, attach 대상의 owner인 first를 CRUD하는 것은 거부돼야 한다. 다만 장면이 드물다. 최소 단언은 R08d 장면 그대로 `Quad0167`과 first의 원소 유지를 보는 것이다. 처방 성격: 결정 없이. 확신도: 높음(도달·차이 실측). 우선순위는 낮음.

### 공백이 아닌 생존 — 걸러낸 근거

- **K02**: Bookkeeping 한도를 `> REWIND_LIMIT + 1`로 바꾼 변이다. 프로브는 `runs=10001` → `10002`. spec (a)가 `runs <= 10002`로 일부러 여유를 뒀고, 문서는 "1만 번 넘게 되감으면 멈춘다"라서 변이도 이 문장을 어기지 않는다. 메시지는 API가 아니다(D3). 같은 경계를 Effect 쪽 spec은 정확히 고정한다(E02 죽음). 이 비대칭은 원하면 정리할 수 있는 사소한 차이다.
- **T01**: 세대 도장 리셋 삭제. 차이는 Modifier를 돌려준 Compute를 같은 세대에 다시 읽을 때 `Quad0185`가 `Quad0184`로 바뀌는 것뿐이다. 던진 뒤의 관측이다(Q160 닫힘 2026-10-04: Q50 세대 재실행은 "관측, 계약 아님").
- **K04·K06**: 되감기 자리 ①과 ③(Get 창)의 카운트 삭제. 여기 닿는 입력은 Compute fn 안의 Set뿐이라 UB다(C2, Q156 (b) "Get 창 검사는 UB 입력 방어·계약 아님", Q171 열림). Set 창인 자리 ②(K05)는 죽었다.
- **T14**: debug 감지기 신호 (a)의 `_computing == -1` 조기 반환 제거. 차이는 Compute 안 yield(UB)와 `q.debug`가 겹칠 때뿐이다.
- **K08·D03·D21**: debug 전용이다. K08은 부기 Length Observer의 `_internal` 표시 삭제로, 되먹임 감지기 출력만 바뀐다(Q174 계열). D03·D21은 debugOnly 핸들러의 같은 우선순위 순서와 debug 겹침 경고다. 같은 debug 층에서 O17·O18·O19·T15·D14·D15c/d·R12·R13은 spec이 잡았다.
- **동등 16**:
  - O05: `rawget`과 인덱싱이 같은 nil이다.
  - O15: 설치 run이 fn보다 먼저 덮어쓴다.
  - E07: State를 Sync하면 문자열 필드를 순회해 아무것도 쓰지 않는다.
  - E17: Sync와 Update는 쓰기가 같고 반환값을 버린다.
  - S10: 버릴 수 있는 값(Instance·Slot)에 `__eq`가 없다.
  - F04: Luau에서 키 1은 `#t` 뒤 `next` 순서에 나오지 않는다. 구성 2,400가지로 0회 확인했다.
  - D04: 빈 병합과 같다.
  - D08: 등록 술어가 전부 `is` 이름이다(프로브 같음).
  - D17: 블로커 할당이 늘 뿐 관측 차이가 없다(프로브 같음).
  - D18·D19: keyType 버킷과 anchor 기본값이 이미 같은 결과를 낸다.
  - R06: 사슬에 중복이 있는 것은 순환뿐이다(UB).
  - R14: `init.luau`가 이미 등록한다(프로브 `true`).
  - T06·T17: 정의된 입력에서 세대가 같은 재계산은 없다(프로브 같음).
  - K10: 잘못 만든 변이(위).
- **추정 동등 2**:
  - T12(Gate flush의 emit 맵 Sync 삭제): 게이트의 유일한 상류가 같은 리비전을 두 번 보내지 않아 차이가 나는 입력을 못 찾았다. 프로브 T12·T12b가 같았다.
  - R02(`maybeRecompute`의 `recomputeBlocker.Blocking` 검사 삭제): 중첩 재계산이 돌아도 최종 상태와 Offset 콜백 순서가 같았다(프로브 R02, spec lengthoffset (d)).

### 확인했고 문제 없음

- `SetIfChanged`의 비교 셋, `checkSettable` 세 자리, `SetAndDispose`의 건너뜀 규칙 셋과 dispose 순서(전파 뒤): 전부 spec이 잡았다(Source 15개 중 14개, 남은 S10은 동등).
- Effect의 `RERUN_LIMIT` 정확 경계(E01·E02), 카운터 증가 삭제, pre-fn Sync, `_receive`의 Update 조건, Ref 콜백, `_subs` 등록, 시딩 재도입(E16): 전부 죽었다.
- Observer의 설치 창 보류, `_catchUp`, `run` save/restore(O06), 설치 순서(O13): 전부 죽었다.
- flatten `Quad0085`의 각 절: 바꾼 경계 F04만 동등이고 나머지는 죽었다.
- 핫 패스 버킷 선택(D01·D02), debugOnly 분기, props 게이트 두 절, retractor nil 검사 두 자리: 전부 죽었다.

### 미완

- 변이 자리는 손으로 골랐다(132곳). 바뀐 줄을 전수로 변이하지는 않았다. 특히 `Dispatch/init.luau`의 `noMatchMessage` 안내 갈래는 메시지 전용이라(D3) 하나(D23, 죽음)만 넣었다.
- T12·R02는 판별 입력을 못 찾아 "추정 동등"으로 남겼다. 차등 퍼저는 돌리지 않았다.
- 이 탐사에서 코드 결함은 0건이다. 위 일곱은 전부 spec의 검출력 공백이고, 열린 테스트 정책 문항 Q154의 입력 자료다. 이번 라운드에서 새로 생긴 공백이라 round14 감사 파일에는 아직 없다.
