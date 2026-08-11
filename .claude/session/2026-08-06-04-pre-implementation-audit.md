<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-06 네 번째 세션 — M0 착수 직전 크리티컬 감사, `research/pre-implementation-audit.md` 신설

사용자 요청: "실 개발 시 모호하여 인터럽트될 수 있는 부분, 나중에 결정되면
치명적일 것 같은 것, 지금 구조가 오버엔지니어링일 수 있어 보이며 더 나은
대안이 있는 것"을 찾아 정리해달라는 요청. `.claude/base/` 전체(architecture/
bind-system/store-semantics/module-lifecycle/component-composition/
modifier/purity-and-effects/slot/lifecycle-pattern/quad-v1-architecture)와
근접 `research/`(existing-instance-bind/tween/ui-shorthand) + `ROADMAP.md`를
4개 클러스터로 나눠 서브에이전트 4개를 병렬로 돌려 "모호성/지연결정리스크/
단순화후보" 세 렌즈로 재감사, 결과를 `research/pre-implementation-audit.md`
로 종합. `.claude/question.md`엔 이미 취합된 것(용어 재검토, M0 스파이크
항목 자체 등)과 겹치지 않는 새 발견만 반영.

**작업 도중 발견한 부수 이슈**: 워크트리 생성 시점과 main 체크아웃의
미커밋 변경사항(세 번째 세션 결과물)이 어긋나 있었음 — 워크트리는 커밋
시점 기준으로 fork되므로 아직 커밋 안 된 변경은 안 딸려옴. 사용자가 중간에
main에 커밋을 완료해줘서(`4b839b0`) 워크트리를 새로 만들어 재동기화함 —
**앞으로 워크트리에서 최신 설계를 감사/참조해야 하는 작업을 시작하기 전엔,
main에 미커밋 변경이 있는지(`git status`) 먼저 확인하고 필요하면 커밋을
요청하거나 파일을 직접 동기화할 것.**

**핵심 발견 요약** (전체 25개 항목은 `pre-implementation-audit.md` 참고,
우선순위1만 발췌):

- **Tween.luau가 문서 전체에서 "범용 store-bind 캐치올 핸들러"의 유일한
  구체 예시로 서술됨** — 애니메이션 없는 일반 반응형 프로퍼티 바인딩이
  실제로 Tween 파일을 거쳐가는지, 별도 범용 핸들러가 필요한지 확정 안 됨.
  가장 구조적인 발견 — 직접 `bind-system-plan.md` 67-79행을 재확인해
  agent 발견을 검증함.
- `props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴의
  nil-hole 함정(caller가 안 넘기면 `{nil, ref, child}`에서 뒤 항목까지
  무시될 수 있음)에 그대로 노출 — M0 스파이크 코드에 이 케이스를 반드시
  포함시켜야 함.
- `canExecute`/`Connected`의 실제 구현 방식이 미확정인 채 코어 전역
  (Slot/Observer/store-bind retract)에 이미 재사용 확정돼 있음.
- `LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그 인터
  페이스를 전제로 서술돼 있음 — 로드맵 순서 역전, `ROADMAP.md` 조정 필요.
- retract 시 "이전에 실제로 매치됐던 핸들러" 추적 책임, 우선순위 스캔
  동률/매치실패 처리, provider 미주입 상태 dispatch 호출 시 동작 —
  전부 M2(Dispatch 엔진) 착수 전 한 번에 결정하면 효율적인 것들.
- Slot의 `add`/`remove`/`clear` CRUD 의미론 자체가 정의 안 돼 있음,
  "재마운트 시 throw"도 추적 대상(개별 element vs Slot 컨테이너)이
  뭉뚱그려 서술됨 — 둘 다 M6 착수 전 확정 필요.

**단순화 후보로 지적된 것 중 사용자 판단 필요**: `:Compute(fn)`의
`previous` 두 번째 인자 — quad의 "함수 자체가 재호출되는" 모델상 클로저
업밸류로 이미 되는 걸 별도 API 표면으로 만든 것일 수 있음(근거 불명).

**문서모순으로 남겨둔 것**: `State<Modifier>`는 "UB, 가능하면 타입으로
차단"인데 Ref/Slot이 Modifier 필드에 들어가는 건 "UB, 방어 로직 없음" —
같은 문서(`modifier-plan.md`) 안에서 정반대 원칙이 근거 설명 없이 나란히
적용됨. 판단이 필요해 고치지 않고 감사 문서에만 남김.

**부수적으로 직접 고친 stale 문서(판단 불필요한 순수 동기화)**: `base/
architecture.md` 소스트리 주석 두 곳 — `Store.luau`가 여전히 옛 `__newindex`
모델을 언급, `Ref.luau`가 여전히 "CreatedRef 메커니즘 자체"로만 서술(Ref
일반화 결정 반영 안 됨). 온톨로지 요약 절 stale은 같은 세션 도중 커밋
`4b839b0`에서 이미 독립적으로 고쳐져 있었음을 확인 — 재작업 없이 스킵.

**다음 세션이 할 일**: M0 착수 전에 `pre-implementation-audit.md` 우선순위1
항목(특히 위 6개)부터 확인 — "지금 할 일" 1번 참고. `.claude/question.md`
2번에 사용자 판단이 필요한 항목 요약이 반영돼 있음.

