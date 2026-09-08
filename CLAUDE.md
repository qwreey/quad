# CLAUDE.md

Roblox 엔진용 DOMless UI 렌더러 **quad**를 처음부터 다시 짜는 프로젝트.
**⭐ [2026-09-07 기준] v2 초기 구현 구간(M0~M11) 전부 완료 — 열린 마일스톤 없음.**
그 구간의 규약·발견 원장(pre-implementation QA 1~5·손 트레이싱 6~10·M2~M11 brief/원장)과
옛 ROADMAP 본문은 `.claude/archive/v2-initial-implementation/`에 원문 그대로 보존됐고
(2026-09-07 사용자 결정으로 이동), 구현 뒤 코드 리뷰 원장은
`.claude/qa-request/post-implementation-review-round1.md`(§4가 사용자 문항, `H-nnn`이 발견
번호; 라운드는 1부터 새로 세고 계속 늘어난다 — round2·round4·round5는 Gemini 외부 리뷰, round6은 Gemini 코드 품질 자문(처리 완료), round7은 사용자 반입 RFC 판정, round8은 누적 변경 감사(2026-09-08 오후), round9는 슈거 구간(Debounce/훅/Fallback) 리뷰·감사(같은 날 밤), round3는 2026-09-07 마커 커밋 리뷰 + 이후 회신 절(§6~§12, 2026-09-08까지 누적), 최신 목록은 `.claude/qa-request/README.md`)다. 남은 작업(병행 항목·백로그)은 루트 `ROADMAP.md`,
지금 할 일은 `.claude/todos.md` 00번, 결정 이력은 `.claude/session-summary.md`.
**⚠️ 2026-08-24 이전에 쓰인 `session/`·`archive/`의 `M2`/`M3`는 옛 의미**(M2=디스패치,
M3=반응형 — 그날 번호·순서가 맞바뀜, 경위는 `.claude/archive/question-resolved.md`의
"마일스톤 경계" 절). 같은 상태를 `.claude/project-context.md`도 서술하니 상태가 바뀔 때
두 곳을 같이 고칠 것. 진행 상황의 소스는 항상 루트 `ROADMAP.md`.

<!-- [2026-08-16 재구조화] 이 파일은 1537줄까지 불어나 (a) 사람이 검토 불가,
     (b) 공식 권장치(파일당 200줄) 7.7배 초과로 지침 준수도 저하, (c) 에이전트가
     긴 파일을 편집할 때 실수 증가를 유발했음. 주제별로 쪼개고 @import로 다시
     합침 — import는 컨텍스트를 줄여주지 않지만(전부 그대로 로드됨) 사람 검토성과
     편집 정확도, 그리고 파일 단위 자동생성 가능성을 산다.
     ※ 이 주석은 컨텍스트 주입 전에 제거되므로 사람용 메모만 넣을 것. -->

**이 파일에 내용을 직접 쌓지 말 것** — 짧은 진입점으로 유지한다. 새
서술은 아래 import된 파일 중 맞는 곳에 넣을 것(어디에도 안 맞으면 그건
매 세션 로드될 내용이 아닐 가능성이 높음 — `.claude/` 아래 해당 문서로).

## 항상 로드되는 컨텍스트

관례와 작업 방식 @.claude/conventions.md

프로젝트 컨텍스트와 문서 구조 @.claude/project-context.md

지금 할 일 @.claude/todos.md

## 온디맨드 자료 (자동 로드 안 됨 — 필요할 때 직접 열 것)

| 무엇이 궁금할 때 | 어디를 볼 것 |
|---|---|
| **지금 유효한 설계** — 어떤 결정이 확정돼 있는가 | `.claude/base/` (먼저 `.claude/base/architecture.md`) |
| 문서 전체 색인 — 어느 파일이 뭘 다루는가 | `.claude/README.md`(폴더 한 줄씩) → 각 폴더의 `README.md`(파일 색인, **[2026-09-08 분리]**) |
| 사용자가 답해야 할 열린 질문 | `.claude/question.md` |
| **외부 모델(Gemini 등)에게 감사를 시킬 때** 먼저 읽힐 진입점 | `.claude/qa-request/external-review-entry.md` |
| 구현 순서 / 마일스톤 | 루트 `ROADMAP.md` |
| 사람만 할 수 있는 일 | 루트 `HUMAN_TODO.md` |
| **어떤 결정이 왜 그렇게 됐나 / 전에 뒤집힌 적 있나** | `.claude/session-summary.md`를 grep (세션별 2~4줄 요약 색인) |
| 그 결정의 논쟁 과정 원문 | `.claude/session/YYYY-MM-DD-NN-slug.md` |
| 뒤집히거나 기각된 설계의 원문 | `.claude/archive/` |

**주의**: `session-summary.md`는 의도적으로 `@import` 안 함 — 계속 자라는
히스토리 문서라 통째로 올릴 이유가 없음(그 문서 스스로 "항상 읽을 필요 없음,
지금 유효한 설계는 `base/`가 소스"라고 명시). 필요해지면 그때 가서 열 것.

**충돌 시 우선순위**: `.claude/base/` > 여기 요약이나 `session-summary.md`.
후자들은 과거 시점 서술이라 더 최근 결정이 안 반영돼 있을 수 있음.
