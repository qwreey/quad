# 2026-08-13 열 번째 세션 — 병렬 에이전트 코퍼스 감사, 실제 부정확성 7건 발견·수정

## 배경

사용자가 "세션 기록들을 전부 읽어보며 문서 전체에 문제가 되는 부분이
있는지" 요청 — 단, 미확정 항목(0-Y/0-Z 등)은 문제로 세지 말고 **문서가
실제로 부정확한 것만** 짚어달라는 조건. 직전 세션(아홉 번째)이 `luau-test/`
상태별 폴더 재편, `bind-system-plan.md` 1단계 분할, `question.md` 트림,
`doc-check.py` 신설을 한 번에 처리한 큰 구조 변경 세션이었기 때문에, 그
변경들의 반영 누락이 남아있을 가능성이 가장 높은 지점으로 판단.

## 방법

1. 먼저 `python3 .claude/tools/doc-check.py`로 기계가 잡는 것부터 확인 —
   ERROR 0, WARN 60건은 전부 기존에 허용 범위로 확인된 것(패러프레이즈
   인용, 이미 날짜/범위가 명시된 완결 주장)이라 새 이슈 없음.
2. 기계가 못 잡는 의미론적 문제를 6개 병렬 Explore 에이전트로 분담
   (CLAUDE.md "작업 방식"의 병렬 Agent 원칙 그대로):
   - A: `bind-system-plan.md` 분할(9차 세션) 정합성
   - B: `luau-test/` 폴더 재편(9차 세션) 정합성
   - C: `question.md` 트림(9차 세션) 정합성
   - D: 배너 달린 base 4종(`bind-system-plan`/`tag`/`slot`/`attribute`)
     정밀 감사 — 배너 범위 밖 서술이 다른 최근 결정과 모순되는지
   - E: 나머지 base 16개 문서 전수 — retract-always-fires/
     `State<State<T>>`/인덱스 기반 chains/Slot 언마운트 전환/and·or
     금지 등 최근 결정 위반 여부
   - F: 루트 문서(`ROADMAP.md`/`HUMAN_TODO.md`/`.claude/README.md`)와
     `archive/` 정합성, 0-Y/0-Z 게이트 표시 여부
3. 각 결과를 실시간으로 검토하며 발견 즉시 직접 수정(에이전트에 위임
   안 함 — CLAUDE.md "중대 변경 핸드오버 체크리스트"의 "그 자리에서
   닫을 것" 원칙).

## 발견 및 수정

**1. `luau-test/` 재편 후 깨진 flat 경로 참조** — `research/
pre-implementation-audit.md`, `base/store-semantics.md`,
`base/modifier-plan.md`(2곳), `base/lifecycle-pattern.md`,
`.claude/README.md`, `audit/gcconn-trick-verification.md`(4곳)가 옛
`luau-test/08-...`/`/09-...`/`/10`/`/17`/`/gc-trigger-helper...` 경로를
그대로 참조 — 실제 파일은 `done`/`review-required`/`not-run` 하위로
이동해 전부 깨진 링크였음. 파일명+실제 소속 폴더 표기로 정정(경로
대신 파일명 참조라는 9차 세션 원칙 준수).

**2. `bind-system-plan.md` 분할 후 참조 정합성 깨짐**:
- 분할된 문서 **자기 자신** 안의 "아래 Ref 절"/"위 PreRef 절"/"위
  이벤트 절" 같은 위치 참조 4곳(167/332/863/1102줄)이 실제로 이동된
  절을 못 따라감 — "순수 이동"이 텍스트 상호참조까지는 보장 못 한다는
  사례.
- 외부 문서(`architecture.md`/`relate-plan.md`/
  `component-composition-plan.md`/`question.md`)와 luau-test 파일 2개가
  여전히 `bind-system-plan.md`의 Ref/Brand 절을 가리킴 — 전부
  `ref-plan.md`/`event-plan.md`/`brand-plan.md`로 정정.
- **가장 중요한 발견**: `ref-plan.md`의 "`Ref`의 retract" 절이 옛
  재디스패치 모델(선행 `retractFrom` 호출)을 그대로 서술하는데, 분할
  때 다른 4개 base 문서가 이미 달고 있던 0-Z ⚠️ 배너가 안 옮겨와 있었음
  — 이 상태로 구현하면 옛 모델로 짜일 위험. `research/
  dispatch-redispatch-diff-plan.md` 6절 검토로 실제 대상 메커니즘이
  맞는지 교차검증 후(단순 키워드 매치가 아니라 "선행 호출 후 process"
  패턴이 정확히 일치함을 확인) 같은 형식의 배너 추가, 반영 대상을
  6개→**7개**로 `dispatch-redispatch-diff-plan.md`/`CLAUDE.md` 양쪽 갱신.

**3. 세션 번호 오기(8차→9차) 대량 발견** — `bind-system-plan.md` 분할/
`luau-test/` 재편/`question.md` 트림/`tools/` 신설이 실제로는 전부
**9차 세션**(`session/2026-08-13-09-structure-and-guardrails.md`) 작업인데,
git 커밋 타임스탬프로 교차검증한 결과 총 17곳(`.claude/README.md` 4곳,
`question.md`, `archive/question-resolved.md`, `luau-test/STATUS.md`,
`luau-test/README.md`, `base/ref-plan.md`/`event-plan.md`/
`brand-plan.md`/`bind-system-plan.md`의 분할 배너 6곳, `doc-check.py`
자기 설명 2곳)가 "8차 세션"으로 잘못 표기돼 있었음(같은 날 2026-08-07의
진짜 8차 세션과 혼동된 것으로 추정) — 전부 정정.

**4. `question.md` 트림 중 열린 질문 하나 누락** — `State<State<T>>`
평탄화(`state:Flatten()`) 백로그 항목이 `research/
operator-sugar-plan.md`엔 있는데 트림된 `question.md`에서 빠져 있었음 —
3번 절(낮은 우선순위)에 복원.

**5. 트림 후 깨진 참조** — `research/v1-compat-plan.md`가 이미
`archive/question-resolved.md`로 옮겨진 "여러 Slot이 형제로 섞일 때
순서 보장" 항목을 옛 `question.md:110` 경로로 가리키고 있었음(그
줄번호도 트림 후 빈 줄이 됨) — 2곳 정정.

**6. `ROADMAP.md`의 M0 섹션에 0-Y/0-Z 게이트 표시 누락** — M2/M4/M6/M10엔
"0-Z 먼저 해소할 것" 배너가 있는데, 정작 M0 자체가 두 결정에 막혀
있다는 사실이 서두/M0 섹션 어디에도 안 적혀 있었음(`HUMAN_TODO.md`/
`CLAUDE.md`/`question.md`는 이미 정확히 서술 중이었음 — `ROADMAP.md`만
누락) — M0 섹션 시작 부분에 게이트 배너 추가.

## 문제 없음으로 확인된 것

배너 달린 4개 base 문서의 배너 **범위 자체**는 정확 — 배너 밖 서술
(retract 항상 호출, `State<State<T>>` 정상 지원, 인덱스 기반 `chains`,
Slot 언마운트 전환, `and`/`or` 금지)은 전부 최신 결정과 일치, 모호해서
독자를 오도할 소지 없음. 나머지 base 16개 문서, `HUMAN_TODO.md`,
`luau-test/STATUS.md`의 상태 표는 실측과 정합. `question.md`/
`question-resolved.md` 사이 항목 재분류 오류나 번호 충돌 없음.

## 교훈

- **"순수 이동"이라고 선언해도 상호참조 검증은 별도로 필요** —
  bind-system-plan.md 분할이 "내용은 안 바꿈"을 지켰어도, 그 내용이
  참조하던 방향(위/아래, 같은 파일 안 절 이름)과 그 내용을 참조하던
  외부 문서 양쪽 다 별도로 grep 전수 스윕이 필요했음. 이번엔 doc-check.py가
  없던 시절 방식(agent가 직접 정독)으로 잡았지만, doc-check.py의 절
  참조 검사가 왜 이 6곳을 못 잡았는지도 짚어둘 것 — "Ref 절"처럼 헤딩
  전체가 아니라 **파일명이 함께 안 적힌** 참조는 정규식이 "그 파일
  안에 있다"고 가정하고 검사하므로, 파일명 없는 방향 참조(아래/위)
  자체가 애초에 이 검사의 사각지대. 파일을 쪼갤 땐 grep으로 "아래/위
  OO 절"류 방향 참조부터 훑는 걸 체크리스트에 추가할 가치 있음.
- **배너가 파일 단위로 붙어있으면, 그 파일에서 분할된 새 파일에
  배너 대상 내용이 섞여 있는지 별도 확인이 필요** — `ref-plan.md`
  사례처럼, 분할 시점에 배너 자체를 "옮길지 말지"를 판단할 근거
  문서(`dispatch-redispatch-diff-plan.md`)가 그 새 파일을 아직 몰랐던
  경우 특히 위험.
- **날짜/세션 번호는 한 번 잘못 적히면 복붙되며 퍼진다** — 이번
  17곳도 대부분 서로를 참고하며 같은 오기를 반복한 것으로 보임(README
  색인이 base 파일 배너를 그대로 요약하는 식). 세션 번호는 가능하면
  파일명(`session/YYYY-MM-DD-NN-slug.md`)에서 기계적으로 뽑아 쓰는 게
  안전.

## 반영 상태

base/README/question.md/archive/ROADMAP/CLAUDE.md/tools/ 전부 이 세션
안에서 즉시 반영 완료 — 24개 파일 수정, `doc-check.py` ERROR 0 유지
확인. 새로 연 설계 질문 없음(전부 기존 서술 정합성 문제), 0-Y/0-Z 상태
불변.
