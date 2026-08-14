# 2026-08-14 열네 번째 세션 — 코퍼스 전체 사실관계 감사 + `doc-include.py` 백로그 신설

사용자 요청("전체 내용 감사해줘, 서브에이전트 써도 좋아")으로 `.claude/`
코퍼스 전체를 대상으로 사실관계 감사 진행.

## 1. 기계 점검 + 서브에이전트 4개 병렬 감사

`python3 .claude/tools/doc-check.py` 선실행(ERROR 0, WARN 85 — 대부분
"절 제목 의역 인용" 정상 관례). 이어서 base/, research+reference/,
luau-test+audit/, archive+root 네 영역으로 나눠 general-purpose 서브에이전트
4개를 병렬로 띄워 각자 독립적으로 감사·직접 수정하게 함(같은 파일을
동시에 건드리지 않도록 영역 분리, CLAUDE.md 자체는 제외해 어시스턴트가
직접 처리).

**결과**: 13개 파일에 걸쳐 실제 오류 20건 수정.
- 가장 큰 원인: `bind-system-plan.md` 3단계 분할(1238→203줄, 9차/14차
  세션) 이후 `research/`·`reference/` 문서 11곳이 여전히 옛 줄번호나
  이관된 내용을 옛 파일로 가리키던 것 — `source-state-plan.md`/
  `event-plan.md`/`dispatch-core-plan.md`/`archive/
  quad2-try-research-findings-rejected.md` 등 실제 위치로 정정.
- `HUMAN_TODO.md`가 이중 바인딩 게이트를 "`canExecute` 하나"로 서술
  중이었으나 열한 번째 세션의 `canBound` 재도입이 반영 안 돼 있던 것 정정.
- `architecture.md`/`blocker-plan.md`/`component-composition-plan.md`/
  `debug-tooling-plan.md`의 "남은 건 X뿐" 류 날짜 없는 완결 주장 4건에
  `[YYYY-MM-DD 기준]` 날짜 태그 추가(git log로 유추).
- `luau-test/`·`archive/`·`.claude/README.md`·`ROADMAP.md`·`question.md`·
  `HUMAN_TODO.md`·`SAFETY.md`는 감사 결과 이상 없음 확인(agent 보고).
- 어시스턴트가 CLAUDE.md 자체도 직접 대조(`bind-system-plan.md`의
  "확정된 것" 절 존재 여부, 최근 승격 파일 실존 여부 등) — 이상 없음.

`doc-check.py` ERROR 0 유지, 커밋 완료(`f829487`).

## 2. State 노드 남발 줄이는 법 — 탐색 질문

기존 확정 설계에서 이미 있는 절제 수단 세 가지를 정리해 답변: (1)
`:With(a,b,c)` 가변인자로 한 호출에 의존성 몰아넣기, (2) 이미 다른 이유로
노드를 만드는 자리면 `:Compute(fn, ...)` trailing-args로 공짜로 의존성만
얹기(단 호출문 로컬 안에서만 무료), (3) 재사용되는 파생 로직은
`:Apply(factory)`로 감싼 콤비네이터를 한 번만 만들어 재사용. 근본
원칙은 "관측해야 실체화된다"(source-state-plan.md) — 반응성이 실제로
필요 없는 값은 State로 안 감싸는 것. 새 설계 결정 아님, 기존 문서
인용 답변.

## 3. 문서 stale 감소 방안 논의 → `doc-include.py` 백로그 신설

사용자가 "요약 부분을 특정 파일에서 마커로 표시해두고, 인용하는 문서가
그 구간을 기계적으로 추출해 붙여넣는 도구를 만들면 안 되냐"고 제안(선례
있는지도 질문). 어시스턴트가 AsciiDoc tagged region include / markdown-magic
/ Obsidian block transclusion을 선례로 확인, 이 코퍼스엔 아직 없음을
확인. 사용자가 "직접 만들지 vs 기존 걸 가져다 쓸지"를 재질문 —
build-vs-buy 판단으로 **직접 제작 채택**을 권고(문제가 좁아 100줄 내외로
충분, 기존 JS 도구는 Node/npm 툴체인을 새로 들여옴 — `doc-check.py`가
Python 의존성 0이라는 관례와 어긋남, 마커 문법을 코퍼스 관례에 맞춰
직접 정하는 게 더 간단).

사용자가 동의, **오늘은 플랜만 작성**하고 세부는 내일 사용자가 직접
다듬기로 함 — 파일럿 범위는 **CLAUDE.md 세션 히스토리부터**(다른 문서가
그 문장을 인용하는 경우가 거의 없어 부작용이 가장 작다는 사용자 판단).
`research/doc-include-plan.md` 신설(마커 문법 초안, 파일럿 범위, 열린
질문 5개, 우선순위 하) — `.claude/README.md` research 표, `CLAUDE.md`
"지금 할 일" 6번에 반영. 구현 착수는 아직 안 함.
