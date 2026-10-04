# round14 탐사 A — 반응형 코어 최근 변경

> opus 탐사자 원문(2026-10-04, 읽기 전용, 공통 규칙 `round14-explore-2026-10-04/common-rules.md`). 서브에이전트가 파일을 쓰지 않아 메인이 보고 본문을 옮겼다. 결정 아님 — 메인·검증자 판정 전 원문.

round14 탐사 각도 A(반응형 코어 최근 변경) 보고. 기준 HEAD `8592751fd4a320c257b71519fc56d3050af9e306`. 실측 사본은 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-a/`이고, 프로브와 퍼저는 모두 그 안 `quad-base/test/`에 있다(레포는 고치지 않았다). 사본에서 quad-base spec 43개는 전부 ALL PASS로 HEAD와 같은 상태임을 확인했다. 결과는 새 발견 둘, 기존 문항의 연장 하나, 사소한 문서 표현 하나다. 그 밖의 축은 모두 문제없었다.

## 발견

**A-1. 부기를 거친 배달을 debug 감지기가 걸러 내지 못하는 경로가 하나 있다: Slot을 다시 앉힐 때 `setOffsetSource`가 쓰는 Offset**

- **상황**: Observer의 자기 상류 되먹임 감지기(`Observer.luau` `fedBackDirectly`)는 안쪽부터 스택을 걸으며 `Bookkeeping._recompute` 프레임을 먼저 만나면 경고하지 않는다. 그런데 부기가 Offset을 쓰는 자리는 둘이다. 하나는 `recompute` 안(`Bookkeeping.luau` 297)이고, 다른 하나는 `recompute` 밖의 `setOffsetSource`(436 `source:Set(offset)`)다. 뒤의 것은 Slot이 마운트되거나 다시 앉을 때 `materializeSlotTree`(`Slot/Tree.luau` 51)에서 불린다.
- **재현**: `probe.a1.offset.luau`와 `probe.a1b.luau`. 안쪽 Slot `I`의 `Offset`을 보는 사용자 Observer가 값이 1일 때 `S:Add(S:Extract(S:IndexOf(I)))`로 `I`를 다시 앉힌다. 출력은 다음과 같다.
  - `extract debug=false … 1,2,|,1,2,|,1,2,final=2 #warn=0`
  - `extract debug=true … 같은 값 #warn=1 Observer: a change reached this Observer while its own fn was running - the fn fed its own upstream…`
  - 같은 고리를 `Move`나 앞에 끼워 넣기로 만들면 두 모드 모두 warn=0이다. 중첩 배달의 스택은 `Source.Set ← Bookkeeping.luau:436 setOffsetSource ← Slot/Tree.luau:51 materializeSlotTree ← attachSlot ← rawAdd ← Add ← 사용자 fn`이고, 사이에 `recompute` 프레임이 없다.
  - 값과 실행 횟수는 debug를 켜든 끄든 같다. debug는 관측만 한다는 원칙은 지켜진다.
- **입력 분류**: 정의된 사용이다. core/05와 core/06에 "Offset/Length를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리는 정의된 경로"라고 적혀 있다.
- **이전 결정**: 사용자 2026-10-01 회신 *"부기 거친 배달은 debug 에서 무시하기도 동의. 부기가 묶는건 처리해준다로."*(`session/2026-09-28-01-round13-batch-reply.md` 176). core/05에도 "위 Slot 자리 계산을 거친 고리는 알리지 않습니다"라고 적혀 있다. 원장과 round14 감사 파일에서 이 경로를 다룬 기록은 찾지 못했다.
- **문서·spec**: core/05가 위 약속을 한다. `spec.observer` 14는 `recompute`를 거치는 두 장면(Length, 앞 형제 CRUD)만 고정한다.
- **판정**: (가)다. 정의된 입력에서 debug 층이 문서와 사용자 결정과 다르게 오경보를 낸다. 동작에는 영향이 없다.
- **처방 성격**: 결정 없이 고칠 수 있다. 사용자 규칙("부기 거친 배달 무시")이 이미 답을 갖고 있고, 감지기가 건너뛸 부기 프레임의 범위를 그 규칙에 맞추면 된다.
- **확신도**: 높음.

**A-2. 자손 Slot의 Offset을 보는 콜백이 조상 Slot을 다시 앉히면 `Quad0109`가 나고 그 사슬이 동결된다**

- **상황**: `S ⊃ P ⊃ I` 구조에서 `I.Offset`을 보는 콜백이 `P`를 Extract한 뒤 Add하거나, 같은 일을 Splice로 하는 경우다. 이 콜백은 `P`의 내부 `_baseObserver`(`Tree.luau` 25~29) fn 안쪽에서 돈다. 경로는 `recompute(P) → I.Offset:Set` 순서다. 다시 앉힌 `P`를 `materializeSlotTree`가 바인드하려 하면, 실행 중인 그 `_baseObserver`의 `_assertBindable`이 `_running` 때문에 거부한다.
- **재현**:
  - `probe.a1d.luau` 출력:
    - `extractAdd false Quad0109 Observer: cannot bind an Observer from inside its own fn … inS=3 children=2`
    - `spliceSame false Quad0109 …`
    - `move`·`swap`·`addBefore`·`addSlotBefore`는 정상이다.
  - `probe.a1e.luau` 출력: `P._baseObserver._running = true`(스택 `Tree.luau:29`가 바깥에 있음), 이어서 `re-seat: false … Quad0109`, `after: P in S at 3 … host children 2 P.Length 0`, 그다음 `S:Add`에서 `Quad0167 Slot: cannot mutate a Slot while it is being mounted`.
  - `probe.a1f.luau`: 사용자 핸들을 Effect로 바꿔도 같은 `Quad0109`가 난다. 지연 재실행이 있어도 내부 Observer 쪽에서 막힌다.
  - 메시지는 사용자가 하지 않은 "Observer를 자기 fn 안에서 바인드"를 말하고, blame은 바깥 `S:Move` 줄로 간다.
- **입력 분류**: 문서 문구로는 정의된 사용이다. core/06이 "`Offset`/`Length`를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리는 정의된 경로"라고만 하고, 조상 CRUD를 막는 규칙(Q52·Q74)은 마운트 walk와 attach 창 안에만 걸린다. 여기서는 그 창이 열려 있지 않았다. 반대쪽 근거도 있다. `base/slot-plan.md` 재진입성 항목의 옛 문장 "`recompute` 자체의 재진입 … UB"는 2026-10-01 Q73 결정이 Offset 고리에 한해 정의로 바꿨다. 다만 "실행 중인 자리 계산의 주인 Slot을 다시 마운트하는 것"까지 포함하는지는 결정 원문에 없다. 동결은 던진 뒤의 상태라 관측이지만, 정의된 입력에서 던진다는 점이 문제다.
- **이전 결정**: Q73 부분 역전(2026-10-01, Offset 고리 정의), Q52/Q74(창 안 조상 CRUD는 거부, 계약), Q172(Length 고리의 stack overflow — 다른 장면). 같은 장면을 다룬 기록은 찾지 못했다.
- **문서·spec**: core/05와 core/06의 정의 문장이 있다. spec은 형제 CRUD 장면만 다룬다(`spec.slot` Q73, `spec.observer` 14).
- **판정**: (가) 후보다. 정의 문구에 드는 입력에서 관계없는 오류 문구로 던진다.
- **처방 성격**: 사용자 결정이 필요하다.
  - 갈래 (a): 문서를 좁힌다. "보는 Slot의 조상(자리 계산이 도는 중인 Slot)을 콜백 안에서 떼었다 다시 앉히는 것은 정의되지 않음"으로 적는다.
  - 갈래 (b): 실행 중인 base Observer가 있어도 다시 마운트되게 한다(새 메커니즘).
- **확신도**: 재현은 높음, 정의 여부 판단은 중.

**A-3(기존 Q174의 연장). 사용자 Observer가 쓴 프로퍼티를 엔진이 정규화해 `q.Out`으로 되돌리면 debug 경고가 나고, "한 바퀴"가 두 바퀴가 된다**

- **상황**: core/05는 "Observer가 쓴 프로퍼티를 엔진이 `q.Out`/`OnChange`로 다시 올려 보내는 경로는 정상"이고 "한 바퀴에서 멈춥니다"라고 적는다. Q174와 followup 313은 이 문제를 StoreBind(`_internal`)에 한한 추정으로 다뤘다. 그런데 사용자 Observer는 `_internal`이 아니므로 지금도 감지기 대상이다.
- **재현**: `probe.a5.roundtrip.luau`(엔진을 float32 정규화 객체로 흉내 내고, 리스너가 `q.Out`과 같은 `src:SetIfChanged(inst[name])`을 함).
  - `Observer debug=true runs=3 seen=0,0.1,0.10000000149011612 warn=1`
  - debug를 끄면 같은 값에 warn=0이다. Effect로 바꾸면 warn=0이다.
  - 실제 엔진이 float 프로퍼티를 정규화한다는 점은 실기기에서 재지 않았다(추정).
- **입력 분류**: 문서상 정의된 경로다.
- **이전 결정**: 기존 Q174(StoreBind `_internal` 범위, 엔진 왕복 오경보는 Studio에서 실제로 나면 그때 예외를 정하기로 함)와 followup 313이다.
- **판정**: 기존 문항의 연장이다. 사용자 Observer 경로에서는 정규화가 실제로 있다면 지금 이미 오경보가 난다는 사실을 Q174 재료로 붙일 만하다.
- **처방 성격**: 사용자 결정이 필요하다(Q174 갈래 (a)의 "엔진 신호 프레임 건너뛰기"는 새 메커니즘). 실기기 측정 항목으로 HUMAN_TODO I 묶음에 넣을 수 있다.
- **확신도**: quad 쪽 동작은 높음, 엔진 전제는 낮음.

**A-4(사소). 재실행 한도 횟수를 core/05가 하나 크게 적는다**

- core/05 240은 "한 번의 반복이 1만 회를 넘게 다시 돌면 `Quad0263`"이라고 적는다. 실제로는 fn 실행 1만 회까지 통과하고(재실행 9999회), 10001번째 실행 직전에 던진다.
- `spec.effect` 15("9999 re-runs (10000 fn runs) passes")와 errors/04("1만 번 넘게 돌았을 때")는 코드와 맞는다. `probe.a4.limit.luau`에서 N=9999는 runs=10000으로 통과하고, N=10000은 `Quad0263`이었다.
- 판정은 (라)에 가까운 표현 문제다. 결정 없이 고칠 수 있다. 확신도 높음.

## 확인했고 문제없음

- **무작위 그래프 퍼저**(`fuzz.a.luau`): Source, Compute, Depend, 즉시 통과 Gate, 수동으로 붙드는 Gate 위에 Observer와 Effect를 놓고, 매 조작마다 모델과 대조한다. 핸들은 강하게 구독, 약하게 구독, 보류 뒤 나중에 구독(따라잡기), drive로 바인드, 호스트 Destroy, retract 뒤 다른 호스트로 재바인드를 섞는다. 실행은 1장의 메모리 규칙(`choom -n 1000`, `prlimit --data=3GiB`)을 따랐다.
  - **pure 모드**(핸들이 쓰지 않음): 시드 4만 × 조작 100(바인드 없이 2만 + 바인드·Destroy 포함 2만). 실패 0. 각 Set/Emit/SetIfChanged마다 원뿔에 든 살아 있는 핸들이 정확히 한 번 돈다(Set은 같은 값도 전파하고, 같은 값 SetIfChanged는 0회). debug를 켜고 끈 두 실행은 핸들별 실행 순서열까지 똑같았고, 경고는 0줄이었다.
  - **write 모드**(Effect가 자기 의존성의 상류 Source를 다듬어 되씀 — 조건부 Set 또는 SetIfChanged; Observer는 다른 층의 Source에 씀; 붙드는 Gate는 무작위로 전부 flush): 시드 4만 × 100. 실패 0이다. 최종 값은 살아 있는 다듬기 구간의 교집합과 같았고, Observer와 Effect가 마지막으로 본 값은 현재 값과 같았으며, `Quad0263`과 debug 경고는 0이었다. 켜고 끈 실행의 핸들별 중간 순서열은 달랐지만, 그 비율이 끄고 끈 두 실행의 해시 순서 잡음과 같았다(2500 시드당 2281 대 2305).
  - **퍼저 검증**: 변이 둘(`Effect._receive`가 늘 재실행, `State._receive` 규칙 3을 걷어 냄)을 각각 31/50, 20/50 시드에서 잡았다.
  - 덮은 축: `_seenRevision`·`_epochs` 같은 리비전 거르기, 설치 창 보류와 따라잡기(보류 핸들), Effect 직접 dep 동기화와 Gate batch, `state:Get()` 한 번 통과와 닫힌 Gate 뒤 drift(붙드는 Gate 아래 Compute Get이 매 조작 모델과 일치), Q93/Q98·설치 루프·Compute 재시작 루프를 걷어 낸 자리.
- **`SetIfChanged`**(`probe.a2.eq.luau`, 12 경우): 모두 core/02 서술과 맞는다.
  - 같은 `__eq`(메타테이블이 달라도 함수가 같으면)일 때만 부르고 무동작이며, 옛 참조를 그대로 둔다.
  - `__eq` 함수가 다르거나 한쪽에만 있으면 쓴다. 같은 참조, 0과 -0, nil과 nil은 무동작이다. NaN, None과 nil, 1과 "1"은 쓴다.
  - 던지는 `__eq`는 쓰기 전에 전파된다.
- **`SetAndDispose`**(`probe.a3.sad.luau` 10 경우 + 기존 spec): Slot:Single, Slot 안 State 원소, 즉시 Gate 경유, Compute 경유, Slot 옛 값, 놓인 적 없는 값 모두 전파가 끝난 뒤 dispose된다(하류 Observer는 파동 중에 옛 값이 살아 있는 것을 봄). nil/None과 같은 참조는 건너뛰되 쓰기는 일어난다. 숫자와 false 옛 값은 쓰기와 전파가 끝난 뒤 `Quad0180`이다.
- **재실행 한도**(`probe.a4.limit.luau`): Compute 상류, Gate 상류, 구독 뒤 시작한 반복, A/B 핑퐁(수렴하면 통과, 무한이면 바깥 루프 카운터가 `Quad0263`), 진동하는 SetIfChanged는 `Quad0263`이다. cleanup 안 Set(Q51)은 추가 반복을 만들지 않았다. 설치(force) 반복도 한도에 걸린다.
- **Observer 자가 치유**(`probe.a7.heal.luau`): Source, Compute, 즉시 Gate, 붙드는 Gate 대상 모두 던진 다음 변경에서 다시 돈다. debug를 켜고 끈 결과가 같고 경고는 0이다.
- **debug 감지기 셋의 오경보 없음**: Effect의 자기 의존성(상류 포함) Set, 다른 대상을 쓰는 Observer, Gate flush, `recompute`를 거치는 Slot 고리(Move·앞 끼워 넣기, `:List` 재정렬 — `probe.a6.list.luau`), 던진 뒤에서 오경보가 없었다. Compute 안 Set 감지기와 겹친 실행 감지기는 정의된 경로에서 `_recompute` 프레임이 스택에 남는 자리가 없음을 코드로 확인했다(Operator·Animate·`:Single` 매핑 Compute는 순수).
- **(라)로 걸러 낸 것**(근거 한 줄씩):
  - Effect가 `s`와 `s:Gate(붙듦)`을 둘 다 의존하면 flush 때 다시 돌지 않는다. 이미 최신 값을 읽었고, 키를 원천 기준으로 잡는 설계(H-151) 그대로다.
  - Effect가 자기 Ref dep을 같은 Instance로 계속 Set하면 `Quad0263`이다. Ref도 같은 값을 전파하고, 메시지가 Source 처방만 말하는 것은 D3(메시지는 API 아님)이며 입력 자체도 드물다.
  - 두 Observer가 fn 하나를 함께 쓰고 한쪽이 던져 `_running`이 남은 상태면 감지기가 오경보할 수 있다. 던진 뒤라 관측 범위다(추정, 실행 안 함).
  - `fedBackDirectly`는 부기를 거쳐 돌아오는 진짜 UB 되먹임을 놓칠 수 있다. debug는 최선 노력 층이다.
  - 파생 대상 Observer가 중첩 파동에서 두 번 도는 것은 Q158로 기록된 한계다.
- **참고(결함 판정 안 함)**: 인스턴스를 바인드하는 퍼저를 한 프로세스에서 오래 돌리면 mock 하네스 메모리가 1000 시드당 약 320MB씩 는다. 3GiB 한도에서 한 번 OOM이 났고, 2500 시드씩 나눠 다시 돌렸다(원래 계획 N도 2만 시드였다). 원인은 확인하지 않았다(mock `dataOf` 약한 키의 값 쪽이 gcconn 클로저로 inst를 잡는 것으로 의심).

## 미완

- quad-roblox 층(실제 Property 핸들러, StoreBind, `q.Out` 통합)은 퍼저에 넣지 않았다. 엔진 정규화는 Studio에서 재지 않았다.
- 퍼저에 Ref dep, Debounce/Throttle/Blocker 게이트, Effect cleanup 반환은 넣지 않았다.
- 겹친 Compute 실행 감지기의 정의된 경로 오경보 여부는 코루틴 퍼저 없이 추론으로만 봤다. 그 입력(yield)은 어차피 UB다.
- A-2와 같은 결의 다른 재마운트 경로(State 자리 교체로 조상을 바꾸는 것 등)는 시도하지 않았다.
