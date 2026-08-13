# 2026-08-14 여섯 번째 세션 — 생명주기 훅 `OnCreated`/`OnDestroyed` 백로그 신설, `OnRendered`는 의도적 보류

**[번호 관련 메모]** 실제 작업 순서상으로는 이 세션이 `ProcessedPreRef`
세션(파일명 `04`)보다 먼저였음 — 다른 세션과 메인에서 병행 작업하느라
병합·커밋이 뒤로 밀려 세션 로그 번호가 `06`이 됨(위 CLAUDE.md 세션
히스토리에도 같은 메모). 아래는 실제 작업 순서 그대로.

## 배경

사용자가 React/Vue류 프레임워크의 `OnCreated`/`OnRendered`/`OnDisposed`
생명주기 훅을 quad에도 두면 좋겠다고 제안. 처음엔 `Frame{[OnCreated] = fn}`처럼
싱글톤 프리미티브를 해시 파트 DI 키로 쓰는 안을 검토했으나, `:Compute`
콜백에 `State<function>`이 들어올 때의 처리가 까다로워질 것 같다는 우려로
스스로 기각 — 대신 `OnCreated(fn)`이 이미 있는 `PreRef` 인스턴스를 반환하는
순수 팩토리 함수(children 배열에 놓는 슈가)라면 그 우려 자체가 안 생긴다는
데 도달했다며, "워크트리 만들어서 조사하고 백로그 만들어줘"라고 요청.

## 조사 — 기존 설계와의 관계

먼저 메인 세션에서 `base/ref-plan.md`(PreRef pre-pass 절)/`base/effect-plan.md`/
`base/dispatch-core-plan.md`(두 패스 계약)를 직접 읽어 그라운딩:

- `base/ref-plan.md`에 이미 "v1의 `OnCreated` 특수 DI 키는 이식하지 않는다,
  `Ref():Callback(fn)`로 완전히 대체된다"는 확정 서술이 있어서 — 이번
  제안(팩토리 함수가 `PreRef`를 반환)이 그 결정을 뒤집는 게 아니라 메커니즘이
  다른 재포장이라는 걸 문서에서 명확히 대조해야 한다고 판단.
- `Effect(fn, state?)`가 `state` 생략 시 "설치 시 즉시 1회 실행 + 반환값이
  leaf 사망 시 정확히 1회 호출"이라는 계약을 이미 갖고 있어 `OnDestroyed`도
  같은 방식으로 공짜라고 판단.
- `OnRendered`는 두 패스(배열 먼저, 해시 나중) 어디에도 "해시 패스까지
  전부 끝난 뒤"를 보장하는 훅이 없다는 걸 확인 — 진짜 조사 포인트로 식별.

이 그라운딩을 바탕으로 워크트리 에이전트(Agent, isolation: worktree)에게
조사·문서화를 위임. 작업 도중 사용자가 두 차례 방향을 좁혀줌:

1. "OnCreated() -> PreRef 슈거와, OnDestroyed()->Effect 슈거가 나은듯,
   둘 다 여럿 등록 가능하다는게 특징이야. 실제론 {PreRef, Effect} 가
   남는다 (함수니까 실행되어 결과가 되어버림)" — 핵심 우선순위를
   `OnCreated`/`OnDestroyed` 둘로 좁히고, 다중 등록 가능성과 "이 함수들은
   새 타입이 아니라 호출 즉시 기존 프리미티브로 환원된다"는 논지를
   명시적으로 세우라고 지시. 에이전트에게 실시간으로 전달.
2. `OnDisposed`(가칭) 대신 `OnDestroyed`가 낫냐는 질문에, 메인 세션에서
   `question.md` 0-B(`dispose(any)`)와 `base/slot-plan.md`의 `dispose(value)`
   절을 대조 — `dispose()`는 "의도적으로 부르는 명시적 파괴 API"(거부
   시맨틱)로 설계 중인 반면, 이 훅의 실제 트리거는 `Effect`의 leaf-death
   cleanup, 즉 엔진 `Destroying` 신호라서 `dispose()`를 거치는지 여부와
   무관하게 발화함. `OnDisposed`는 "`dispose()` 호출 시에만 발화한다"는
   잘못된 인상을 줄 위험이 있어 `OnDestroyed`를 추천 — 이 판단도 에이전트에
   전달해 문서에 "열린 네이밍 질문"으로 반영.

## 워크트리 결과

에이전트가 `research/lifecycle-hooks-plan.md` 신설, `README.md`/`question.md`
인덱스 반영, `doc-check.py` 확인까지 완료(ERROR 0 — 워크트리 격리로 인한
무관한 pre-existing 에러 1건 제외). 핵심 판정:

- `OnCreated`/`OnDestroyed`: 호출 즉시 평가돼 기존 `PreRef`/`EffectHandle`
  인스턴스로 사라지는 순수 팩토리라 새 Dispatch/Brand 개념이 전혀 안 생김,
  다중 등록도 자연 지원(각 호출이 독립 인스턴스를 만들어 `PreRef`의
  "재사용 금지" 가드와 안 부딪힘).
- `OnDestroyed` 추천 — 위 dispose() 대조 근거, 단 `dispose()` 대상 범위가
  0-B로 확정되면 재검토 여지 있음.
- `OnRendered`: 프로퍼티/이벤트 세팅 완료를 보장하는 훅이 base에 없어
  `Dispatch.drive`에 실제 post-pass가 필요 — 공짜가 아님.

## 병합 — 메인이 다른 세션과 동시에 바쁨

작업이 끝난 시점에 사용자가 "워크트리에서 나가지 마, 메인에 작업
수행중임"이라 지시 — `ListAgents`로 확인해보니 실제로 이 레포에서 동시에
여러 peer 세션이 돌고 있었음. 워크트리 결과를 바로 메인에 합치지 않고
대기.

이후 사용자가 세부 스코프를 한 번 더 정리: `OnRendered`는 지금 의도적으로
구현 안 하기로 확정하되, `PreRef`의 거울상인 `PostRef`(같은 메커니즘을
후행 스캔으로 뒤집기만 하면 됨)로 나중에 구현 가능하다는 구체 스케치를
제공 — "일단 백로그 후보로만 둬, PostRef를 같이 백로그에 넣어도 괜찮긴
할듯"이라 지시. 이 스케치를 `lifecycle-hooks-plan.md`에 반영하고,
`question.md`의 `OnRendered` 항목은 제거(이미 "지금 안 함"으로 답이 나온
질문이라 활성 질문 목록에 있을 이유가 없다고 판단).

사용자가 "지금 다른 에이전트 메인 안 건들여서, [메인으로] 이동시켜도
될듯"이라 확인해줘 — `git log`/`ListAgents`로 메인이 실제로 정리됐는지
확인(다른 세션이 `component-fallback-plan.md` 관련 작업을 커밋하고 조용해짐)
후, 워크트리 내용을 파일 단위로 신중하게 메인에 반영:

- `research/lifecycle-hooks-plan.md`는 그대로 복사.
- `README.md`는 새 행(`lifecycle-hooks-plan.md`)만 추가 — 워크트리
  diff에 있던 `component-fallback-plan.md` 행은 메인이 이미 자체
  커밋했던 것과 중복이라 스킵.
- `question.md`는 순변경 없음(추가했다 뺀 게 상쇄돼 원본과 동일) —
  건드리지 않음.

`doc-check.py` ERROR 0 확인 후 커밋(`9f9a68f`), 다 쓴 워크트리와 브랜치
정리(`git worktree remove --force` + `git branch -d`) — 다른 세션이 쓰던
무관한 워크트리(`debounce-throttle-plan`/`fallback-xpcall-spike`)는 안 건드림.

## 세션 기록 요청 중 발견한 동시 편집 충돌

사용자가 "세션 기록 남겨, 메인에 남기면 돼, 커밋은 하지마"라고 요청해
CLAUDE.md 세션 히스토리 절에 압축 요약을 추가하던 중, 파일을 다시 읽어보니
**다른 세션이 그 사이 같은 CLAUDE.md에 uncommitted 내용(`ProcessedPreRef`/
`PostRef` 대칭화 세션 기록, "세 번째 세션"이라는 같은 번호로 자기 것도
기록해둠)을 넣어놓은 상태**였음 — `git status`로 실시간 동시 편집임을
확인. 내용 자체는 안 겹치지만 지금 커밋하면 다른 세션의 미완성 작업까지
내 커밋 메시지로 들어가버리는 문제라, 사용자에게 확인 요청 후 "잠시 대기
후 재확인"으로 보류.

대기 중 다른 세션이 실제로 `e0ef7ce`(ProcessedPreRef)/`c5ea3aa`(Fallback
xpcall 실측)/`af513ae`(`canExecute` 2-인자 역전) 세 커�밋을 연달아 완료 —
그 커밋들 중 하나가 내 uncommitted 문단까지 통째로 포함해 커밋해버림(내용
분실은 없었지만, 내 세션 기록이 남의 커밋 메시지 아래 들어간 것). 다른
세션이 스스로 세션 번호 충돌("세 번째"가 둘)도 이미 알아서 정리해둔 상태
확인.

사용자에게 "`session/2026-08-14-03-lifecycle-hooks-plan.md`를 만들려던
거였냐"는 확인 질문을 받아 그렇다고 답변, 이어서 "지금 만들어도 돼,
커밋 가능함, 단 세션 번호는 가장 위로 올려" 지시를 받음 — 다른 세션이
이미 `04`/`05`까지 다 쓴 상태라, 내 항목을 원래 있던 "세 번째" 자리에서
빼서 문서 맨 끝(`여섯 번째`)으로 옮기고 파일명도 `03`→`06`으로 정정,
"네 번째 세션" 항목의 "위 세 번째 세션이 신설한" 역참조도 실제 순서에
맞게 같이 고침(다른 세션 항목 본문 자체는 안 건드림 — 최소 침습).

## 교훈

- **여러 세션이 같은 저장소에서 동시에 doc을 편집할 수 있다는 걸 전제로
  작업할 것.** `ListAgents`로 peer 세션 존재를 확인하는 습관, 커밋 직전엔
  항상 `git status`/`git log`로 방금 사이 변경이 없었는지 재확인.
- **파일 내용이 안 겹쳐도 "순서/번호"는 꼬일 수 있다** — CLAUDE.md 세션
  히스토리처럼 순번이 있는 목록은 동시 편집 시 번호 충돌이 실제로 발생함
  (이번엔 다른 세션이 스스로 정리했지만, 항상 그렇게 될 거라 가정하면
  안 됨).
- 워크트리↔메인 수동 병합 시 **파일 단위로 diff를 검토해 중복 행을
  스킵**하는 게 안전 — 워크트리는 갈라진 시점 기준이라 그 사이 메인에
  이미 반영된 내용을 모르고 다시 만들어낼 수 있음.
