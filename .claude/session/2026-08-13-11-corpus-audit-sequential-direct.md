# 2026-08-13 열한 번째 세션 — 서브 에이전트 없이 순차 직접 감사, 부정확성 4건 수정

## 배경

사용자가 "전체 문서 감사를 시작해. 부정확하여 문제되는 부분 있나 봐줘.
단 서브 에이전트 없이 직접 수행해. 오래 걸려도 좋아." — 열 번째 세션이
6개 병렬 Explore 에이전트로 감사했던 것과 달리, 이번엔 명시적으로
에이전트 위임 없이 메인 컨텍스트가 직접 전체 코퍼스를 순회하는 방식을
요청받음.

## 방법

1. `python3 .claude/tools/doc-check.py` 선실행 — ERROR 0, WARN 59건은
   기존과 동일(전부 절 제목 의역 인용류 허용 범위).
2. `.claude/base/` 20개 문서 전체를 처음부터 끝까지 순서대로 정독
   (architecture → store-semantics → bind-system-plan(2284줄) →
   module-lifecycle-plan → lifecycle-pattern → slot-plan(1920줄) →
   modifier-plan → purity-and-effects-plan → component-composition-plan
   → blocker-plan → effect-plan → ui-shorthand-plan → tag-plan →
   attribute-plan → onchange-plan → relate-plan → ref-plan → event-plan
   → brand-plan → tween-plan) — 특히 최근 재설계(인덱스 기반 Dispatch,
   Slot 언마운트 전환, 0-Z 배너)가 집중된 문서들의 배너 부착 여부와
   본문 정합성을 중점 확인.
3. `research/` 9개 문서 전체 정독(existing-instance-bind-plan,
   debug-tooling-plan, framework-comparison-findings,
   additional-primitives-plan, pre-implementation-audit(732줄),
   operator-sugar-plan, v1-compat-plan, documentation-plan,
   documentation-content-map, dispatch-redispatch-diff-plan).
4. `reference/` 3개 문서, `luau-test/STATUS.md`+`README.md`(폴더 구조와
   개수 대조), `audit/` 2개 문서, `archive/` 18개 파일 목록과
   `.claude/README.md` 색인 매핑을 확인.
5. `ROADMAP.md`/`HUMAN_TODO.md`/`.claude/question.md`를 다시 정독하며
   위에서 확인한 최신 상태와 대조.

## 발견 및 수정

**1~2. `question.md` 0-Z/0-A — "6개 문서" stale 카운트**: 0-Z 해소 시
옮겨야 할 문서 개수가 "6개"로 남아 있었으나, `research/
dispatch-redispatch-diff-plan.md` 6절(소스)은 이미 `ref-plan.md`를
포함한 "7개"로 확정돼 있었음 — 9차 세션 분할 때 `ref-plan.md`에 배너가
안 옮겨간 걸 10차 세션이 발견해 여러 곳을 정정했는데, `question.md`
자신의 이 두 문단(0-Z 상단, 0-A "실행 규모")은 그때 놓쳤던 것. 둘 다
"7개"+`ref-plan.md`로 정정.

**3. `HUMAN_TODO.md` 4번 항목 — 동일한 stale 카운트**: 위와 완전히 같은
"6개" 문구가 이 파일에도 독립적으로 남아있었음(10차 세션이 정정한 파일
목록엔 `HUMAN_TODO.md`가 없었음) — "7개"로 정정.

**4. `ROADMAP.md` 백로그 — 이미 해소된 항목이 여전히 할 일로 남음**:
"v1 마이그레이션 가이드 + `objectListClass.__newIndex` 오타 기능 재현
테스트"가 여전히 미체크 백로그 항목이었으나, 2026-08-13 세 번째 세션
(`session/2026-08-13-03-v1-newindex-typo-scoped-out.md`)에 이미 "v2엔
대응 개념 자체가 없어 재현 여부와 무관하게 다룰 대상 아님"으로 해소돼
있었음(`archive/question-resolved.md`/`reference/quad-v1-architecture.md`
둘 다 반영됐으나 `ROADMAP.md`만 놓침) — 해소 사실과 근거 포인터를 남기고
재현 테스트 문구는 제거.

## 문제 없음으로 확인된 것

- base/ 20개 문서 전체 — 특히 0-Z 배너가 붙어야 하는 7개
  (`bind-system-plan`/`tag-plan`/`slot-plan`/`attribute-plan`/`ref-plan`/
  `architecture`/`ROADMAP`) 전부 배너 부착 확인, 배너 밖 서술도 최신
  결정(retract 항상 호출/`State<State<T>>` 정상 지원/인덱스 기반
  `chains`/Slot 언마운트 전환/`and`·`or` 삼항 금지)과 전부 일치.
- research/ 9개 문서 — stale 정정 배너(Tag 구모델, Tween 구모델 등)
  전부 정확한 위치에 정확한 내용으로 부착됨.
- `luau-test/STATUS.md`↔`README.md`↔실제 폴더 구조 — done 15/
  review-required 1/rewrite-required 3/not-run 1(+헬퍼 1), 세 문서
  전부 같은 숫자로 일치.
- `archive/` 실제 파일 18개 ↔ `.claude/README.md` 색인 표 18행 — 완전
  매핑, 누락/초과 없음.
- `reference/` 3개 문서 — Fusion/Vide/v1 비교 자료의 stale 모델 참조는
  전부 이미 "[정정]" 배너로 최신 모델 포인터가 달려 있었음.

## 교훈

- **같은 stale 값이 여러 문서에 독립적으로 복붙된 경우, 한 문서에서
  고쳐도 나머지가 자동으로 안 따라온다** — 10차 세션이 이미 같은 종류의
  "6→7" 정정을 겪었는데도(그때는 `dispatch-redispatch-diff-plan.md`/
  `CLAUDE.md`), 그 정정 자체가 다른 두 문서(`question.md`/
  `HUMAN_TODO.md`)엔 안 퍼져 있었음 — CLAUDE.md가 이미 명문화한 "개수·
  목록·상태는 소스를 하나만 둘 것" 원칙이 지켜지지 않은 사례라기보다는,
  "소스 하나(`dispatch-redispatch-diff-plan.md`)를 인용하는 여러 자리를
  전부 grep으로 찾아 동시에 고치지 않으면 한쪽만 갱신되고 나머지는
  그대로 남는다"는 걸 재확인.
- **"해소됨" 처리가 원본 근거 문서(`archive/`, `reference/`)엔 반영돼도
  그걸 인용하던 실행 문서(`ROADMAP.md`)엔 전파 안 될 수 있다** —
  `objectListClass.__newIndex` 사례처럼, 결정이 내려진 세션 자체는
  관련 문서 2곳을 정확히 갱신했지만 원래 이 항목을 만들어낸 자리
  (`ROADMAP.md` 백로그)는 그 세션의 반영 대상 목록에 없었던 것으로 보임
  — "이 결정이 어디서 인용되는지" grep을 결정 시점에 한 번 더 돌리는
  습관이 필요.
- 10차례 감사를 거친 코퍼스라도, 카운트/포인터류의 국소적 stale은
  여전히 남을 수 있음 — 설계 자체의 모순보다 이런 종류가 훨씬 잦다는
  건 이미 여러 세션이 확인한 패턴이고 이번에도 동일했음.

## 반영 상태

`question.md`/`HUMAN_TODO.md`/`ROADMAP.md` 3개 파일 수정, `doc-check.py`
ERROR 0 유지 확인. 새로 연 설계 질문 없음(전부 기존 서술 정합성 문제),
0-Y/0-Z 상태 불변.
