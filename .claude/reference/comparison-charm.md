# charm(littensy/charm) 비교 — quad-v2 설계 근거

**상태**: reference — 온디맨드 참고 자료, "완료" 개념 없음. quad에 관한 결정
자체가 아니라 charm 리서치 스냅샷(2026-08-09, `.claude/initreq/charm`에
새로 클론)이라 항상 읽어야 하는 base 컨텍스트는 아님 — Fusion/Vide 비교와
같은 성격, `quadnomicon` 소재 후보이기도 함. quad-v2의 Blocker/Effect/
Slot:List/(미래) 네트워크 동기화 설계에 근거로 인용될 때만 열어볼 것,
실제 확정 사항은 인용하는 쪽 `base/` 문서가 소스.

**charm이 뭔지**: Roblox용 Zustand류 상태관리 라이브러리 —
`atom`/`computed`/`subscribe`/`effect`/`batch` 핵심(`packages/charm/src/
init.luau`, ~1000줄) + `charm-sync`(클라/서버 상태 복제 diff 레이어) +
`react-charm`/`vide-charm`(얇은 어댑터). 코어는 실제로 절반쯤이 alien-signals
포크(`system.luau`, dirty/pending 비트플래그 전파 엔진, 237줄 — 가장 큰
테스트 파일이 이걸 검증하는 `topology.test.luau` 484줄)라 순수 서핏보다
알고리즘 실체가 있지만, quad는 노드/의존성 재사용 모델 자체를 안 쓰기로
이미 갈라섰으므로 이 부분은 이식 대상이 아님.

## 반면교사 — quad가 이미 기각/확정한 것과 충돌하는 부분

- **`batch(fn, ...)`가 quad가 이미 기각한 `Batch` 렉시컬 블록과 구조적으로
  동일.** `init.luau:768-778`이 `startBatch`/`endBatch`(`init.luau:285-296`)로
  콜백을 감싸 effect flush를 지연시키는 모듈 전역 `batchDepth` 카운터
  방식(`init.luau:66`) — `archive/batch-rejected.md`가 "코루틴 yield에
  안전하지 않다"는 이유로 기각한 것과 정확히 같은 모양. **charm 자신도 이
  위험을 인정하는 증거를 갖고 있음**: `wrapUserSpace()`(`init.luau:100-129`)가
  signal/effect/batch 콜백을 `coroutine.create`/`resume`으로 감싸서 콜백 도중
  yield를 시도하면 에러내는 가드(`flags.strict`, Studio 기본 on,
  `init.luau:71-81`)를 따로 둠 — 위험을 런타임 가드로 땜질한 것이지 없앤 게
  아님. quad는 원시 자체를 제거하는 쪽을 택했으니(`Blocker`가 그 자리를
  대신함, `base/blocker-plan.md:25-44`) 이 모양을 참고할 이유 없음.
- **`atom()`의 getter/setter 겸용 콜러블이 quad가 `Store`에서 이미 기각한
  대입 문법과 같은 트레이드오프.** `atom<T>(initialValue, equals?)`
  (`init.luau:519-527`)가 인자 개수로 read/write를 분기하는 방식 —
  `store.key = value`를 버리고 `store.key:Set(value)`로 간 이유
  (`base/store-plan.md` "Store 값 설정 문법" 절, 읽기/쓰기 타입 비대칭)와 같은 문제.
  charm 스스로도 README(185-196행)에서 `atom()`을 `signal()`(진짜 get/set
  쌍) 위에 얹은 편의 sugar로 취급 — charm 안에서도 "진짜 1급 형태는 아니다"로
  다뤄지는 걸 참고.
- **Effect가 전혀 GC-native가 아님 — 전부 수동 dispose 필요.** `effect`/
  `effectScope`/`listen`/`subscribe` 전부 호출자가 직접 불러야 하는
  `Cleanup` 함수를 반환(`init.luau:607-641`, `652-676`, `800-835`) — Roblox
  Instance 라이프타임에 자동으로 묶이는 경로가 코어에 아예 없음. `base/
  lifecycle-pattern.md`의 GC-native 원칙과 정반대 축. 오히려 `gc.test.
  luau:19-33`의 코멘트가 "스코프 밖에서 `computed()`를 그냥 부르면 의존성에
  대한 영구 강참조가 생겨서 `effectScope`로 감싸 명시적으로 풀어줘야
  한다"는 걸 테스트 자체가 우회 헬퍼(`unlink()`, 29-33행)로 증명함 —
  이건 quad의 GC-native 가정을 **뒷받침하는** 증거가 아니라, "레퍼런스/
  클로저 기반 반응 그래프가 자동으로 안 치워질 수 있다"는 **반례**로
  인용할 것(rbvm이 "실물 검증된 근거"로 인용되는 것과 반대 방향 — 나중에
  quad의 GC-native 가정을 스트레스테스트할 때 이 케이스를 참고).
- **`computed()`의 값-동등성 억제가 기본값이자 암묵적, opt-in이 아님.**
  `updateComputed`가 `oldValue ~= newValue`(`init.luau:302-321`, 특히
  317행)를 리턴하고 signal setter도 `equals`가 없으면 `node.pendingValue ~=
  value`로 기본 비교(`init.luau:489`) — charm의 모든 atom/computed가 기본으로
  값 비교 억제를 함. quad가 나중에 Blocker에 인접한 "값 안 바뀌면 자동
  스킵" 기본값을 도입하고 싶어질 때, charm처럼 **모든 노드에 암묵적으로**
  거는 방식은 `Blocker`가 이미 명시한 "특정 게이트 지점에서만 opt-in"
  원칙(`base/blocker-plan.md:65-68`)과 "Source는 스스로를 자동 변형하지
  않는다"는 `base/source-state-plan.md` 기조에 둘 다 어긋남 — 반면교사로 남겨둘 것.

## 참고할만한 부분

- **charm의 `None` 센티널이 quad 자신의 것을 독립적으로 재확인해줌.**
  `patch.luau:10,19-30`이 diff 페이로드에서 "안 바뀜"과 "명시적으로
  지움"을 `nil`로는 구분 못 해서 `None = {__none="__none"}`을 따로
  둔 이유 — quad의 배열/해시 파트 `None` 센티널 정당화(`base/
  bind-system-plan.md:180-266`)와 동기 없이 같은 결론에 수렴한 사례.
  새 아이디어는 아니고 인용 근거로만 가치 있음.
- **charm의 `previous` 유사 메커니즘 두 가지 — quad가 이미 확정한
  `:Compute(fn)`의 `previous` 인자(`base/source-state-plan.md` "previous"
  절, `fn(self, previous?, ...deps)`)에 대한 독립 실동작 증거.** (1)
  `signal(initialValue, equals?)`(`init.luau:432`, `Equals<T>` 타입은
  23행)는 생성 시점에 `initialValue`를 항상 요구해서 "비교할 이전 값이
  아직 없다"는 애매한 첫 상태 자체를 구조적으로 없앰. (2) `computed(getter)`가
  getter에 **이전 계산 결과**를 인자로 넘겨줌(`init.luau:538`,
  `(previousValue: T?) -> T`, README 276-287행, `computed.test.
  luau:84-104`가 홀수 업데이트를 스킵하는 걸로 실제 검증) — quad가
  `base/source-state-plan.md`에서 이미 확정한 `previous` 안과 거의 동일한
  모양. 새로 수입할 아이디어가 아니라 **이미 확정된 안이 실제로 동작한다는
  정황 증거**로 인용 가치 있음(더 이상 열린 질문 아님).
- **charm-sync의 diff/patch 메커니즘 — quad가 아직 전혀 안 다뤄본 영역이라
  가장 새로운 참고자료.** `patch.luau:59-89`(`diff`)가 재귀적 구조적
  diff로 중첩 patch 테이블을 만들고, `apply`/`applyMutable`
  (`patch.luau:91-131`)이 immutable 재구축(레벨마다 `table.clone`, 순수
  signal용)과 in-place mutate+`:Emit()`류 변형(반응형 프록시용) 둘 다
  제공 — quad가 이미 다른 이유로 갖고 있는 clone-vs-mutate+`Emit` 분리
  (`base/source-state-plan.md`의 `:Emit()` 절)와 우연히 같은 모양. `patch.
  luau:32-57`(`stringifySparseArray`)는 실전에서 놓치기 쉬운 페이로드
  함정을 문서화함 — RemoteEvent/JSON 직렬화가 성긴 배열의 trailing hole을
  조용히 드롭해서, 보낼 땐 문자열 키로 재인코딩하고 받을 땐 숫자 키로
  복원해야 함(`patch.luau:101-107`). `server.luau`는 클라이언트별 관심사
  필터링을 하나의 전역 diff 위에 구현(`clients` 테이블의
  `PENDING_INITIAL_STATE`/`LISTENING_FOR_CHANGES` 상태, 27-32행,
  `selectFromGlobalPatch` 209-250행) + 모든 중간 변경을 보존하는 opt-in
  모드(`config.preserveHistory`, `diffGlobalUpdateBuffer`, 124-133행) vs
  기본값인 flush당 diff 하나로 합치는 모드(`diffGlobalState`,
  192-207행) — `Blocker`가 일반화하는 coalescing 트레이드오프의 손으로 짠
  sync 전용 구현체. 지금 스코프 밖이지만 나중에 quad가 네트워크 복제
  설계를 시작하면 첫 참고 지점으로 쓸 것.
- **`observe()`의 엣지케이스 테스트 스위트가 `Slot:List` 테스트 체크리스트로
  재사용할 만함.** `observe.test.luau`가 마운트 콜백 도중의 재귀적
  add/remove(92-113행), 자기 마운트 도중 자기 자신 제거(115-132행), add/remove
  도중 dispose(134-168행), 재귀적 업데이트 중 에러가 reconciler를 안 멈추게
  하는지(170-196행)를 검증 — `observe()` 자신의 메커니즘(키별
  `effectScope`, `init.luau:851-898`)은 quad가 채택한 방식이 아니지만,
  테스트 항목 목록 자체는 `base/slot-plan.md`의 키 기반 재조정을 실제
  구현할 때 대조 체크리스트로 쓸 가치가 있음.

## 종합

코어(atom/computed/effect/subscribe/batch, `init.luau`의 절반쯤)는 평범한
시그널 라이브러리라 quad가 이미 확정한 것을 대체로 재진술할 뿐이고, 세
군데(`batch()`, `atom()`, 수동 dispose Effect)는 오히려 quad가 이미 능동
기각한 패턴을 그대로 구현하고 있음 — 사용자가 애초에 예상한 "짧은
라이브러리라 새로운 게 없을 것"이 이 레이어에는 대체로 맞음. 진짜 참고
가치는 코어 밖에 있음: charm-sync의 diff/patch(현재 quad 스코프 밖이지만
새 영역), 그리고 quad가 이미 확정한 `:Compute`의 `previous` 인자가 실제로
동작한다는 두 가지 실동작 사례(`signal`의 필수 initialValue, `computed`의
previous-in-getter). 지금 당장 base 문서를 고칠 만한 발견은 없음 — 순수
참고자료로 등록.

**인용 위치**: `packages/charm/src/init.luau:66,71-93,100-129,285-296,
302-321,432,489,519-527,538,607-641,652-676,768-778,800-835,851-898` ·
`packages/charm/src/system.luau`(전체, alien-signals 포크) ·
`packages/charm/test/gc.test.luau:9-33` · `packages/charm/test/
computed.test.luau:84-104` · `packages/charm/test/observe.test.luau:92-196` ·
`packages/charm-sync/src/patch.luau:10,19-30,32-57,59-89,91-131` ·
`packages/charm-sync/src/server.luau:27-32,124-133,192-207,209-250` ·
`README.md:185-196,262-287` · `base/store-plan.md` · `base/source-state-plan.md` ·
`base/blocker-plan.md:25-44,65-68` · `base/lifecycle-pattern.md`(GC-native
원칙) · `archive/batch-rejected.md` · `base/bind-system-plan.md:180-266`
(None 센티널) · `research/additional-primitives-plan.md`(Blocker/키 기반
컬렉션 미결 상태).
