# fable 탐사 — M2~M8·M10 구현 vs 정본 (2026-09-06, HEAD `a716eb4`→`455ef53`)

**무엇**: 밤샘 자율 구간에서 사용자 요청(*"한번 fable 탐사자 던져서 지금까지 해온
작업이 문제 없었는지"*)으로 돌린 신선한 맥락의 fable 탐사자 1개(서브에이전트
0 — 전부 직접 실행, 지시문은 세션 원문 `session/2026-09-06-01-*.md`). 감사
스윕 6라운드(문서 stale)를 먼저 끝내 탐사자가 **코드 실행으로 증명되는 큰
문제**에만 집중하게 했다. 재현 스크립트·출력은 이 폴더
`fable-exploration-2026-09-06/`(스크래치 그대로 — `quad-base/test/`·
`quad-roblox/test/`에 복사해 `luau <file>`, 퍼저는 `-a <seed>`; 색인은 그 안
`README.md`).

## 판정

**치명 0 / 중대 2 / 경미 2.** 코어 의미론(전파·에포크 dedup·게이트·Effect·디스패치
하강 diff·Length/Offset 부기·Slot CRUD/List/Detach/포탈)은 **랜덤 퍼즈 3종(seed
8개, 3~4천 op)에서 모델과 전부 일치** — 정본 의사코드 손 트레이싱에서도 어긋난
자리 없음. 발견은 전부 누수·blame 계열이고 값·순서·크래시류는 없다.

## 발견 (원장 `archive/v2-initial-implementation/m11-implementation-round19.md` §5에 `H-329`~`H-332`로 등재)

| 탐사 ID | 원장 | 심각도 | 요지 | 처리 |
|---|---|---|---|---|
| X-1 | `H-329` | 🟡 | `retractFrom`이 비운 체인 리스트·키가 inst 수명 동안 `chains`(강한 키)·gchold에 남는다 — `State<Attribute>` 재발행마다 새 그룹 키 + 새 리스트가 누적(C1 478 B/iter, C3 554 B/iter; 문자열 키 재사용 C2는 0). `process` (B) 분기가 `retractFrom` 뒤 같은 리스트에 재설치하므로 단순 삭제는 체인을 끊는다 | ② **사용자 문항**(해제 시점 메커니즘) — §4 |
| X-2 | `H-330` | 🟡 | 디스패치·발행 깊이의 `errorBeforeNearest`가 quad 내부 줄을 blame — Slot 8곳(`Dispatch/init.luau:224`)과 `Source:Set → Impl.Emit`(태그된 꼬리라 파동 안 모든 Nearest raise가 `Source.luau:73`) | ① 반영 — Slot 8곳 `errorBefore`(`H-272` 선례), `Source` 꼬리를 태그 없는 로컬 `bumpAndEmit`으로; spec.slot 7b·spec.observer 9a |
| X-3 | `H-331` | 🟢 | `TagFallbackHandler` 이름별 holders 테이블이 비어도 안 지워져 동적 이름마다 누적(195 B/이름) | ① 반영 — retractor가 빈 집합을 `SetStrong(inst, name, nil)` |
| X-4 | `H-332` | 🟢 | Observer `_running` 가드가 재진입 파동(fn 안 자기 Set)에서 `false`로 내려가 바깥 fn 꼬리가 무방비 | ① 반영 — save/restore(`_receive`·`_catchUp`), spec.observer 9a |

## 깨끗함을 확인한 것 (재조사 방지)

- 반응형: 랜덤 DAG 퍼즈(Source 4 + Compute/Gate 14 + 전 노드 Observer + Effect 8) —
  모든 Set/flush 뒤 `Get()` == 모델, 노드/Effect당 파동 1회 이하; 다이아몬드
  glitch-free, 게이트 너머 `Get` 최신값, 게이트 중첩, Effect 홀드/재구독 캐치업,
  중간 State·Observer GC.
- 디스패치·부기: 중첩 Slot CRUD 퍼즈·List/Detach/State 요소/포탈 퍼즈에서
  `Length`/`Offset`/`getOffsetAt`/`bk.N`/물리 자식 집합 전부 일치; Destroy 뒤
  그래프 회수; Effect/Ref leaf의 Destroy 넘김 재배치; 같은 값 재발행 dedup.
- M7/M8/M10 교차: flatten 우선순위·`None` 언셋, PreRef 호이스팅·PostRef 후발화,
  Claim DFS+이중 claim, Event `State<fn|None>` 재연결, StoreBind 자식 churn은
  `dispose`하면 유계.
- 에러 계약: src에 `pcall`/`xpcall` 0곳. 드라이브 안 throw → 배치 Blocker 영구
  On(문서화된 UB).
- 타입(M11 ① 교차): 주석 붙인 `State<Tween<T>>`·형제 클래스 Ref/Modifier·OnChange
  콜백 오타입 전부 거부, 조상 박스·정상 Tween 통과; 새는 건 무주석 파생 State뿐
  (typing-limits §1①). `H-300` 마커 필드는 전 센티널·값의 런타임에 실재.
- Studio 실측이 필요한 의심: 없음.
