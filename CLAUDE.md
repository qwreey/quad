# CLAUDE.md

Roblox 엔진용 DOMless UI 렌더러 **quad**를 처음부터 다시 짜는 프로젝트.
**[2026-08-24 기준] M0(스파이크 검증)/M1(스캐폴딩)까지 완료, 다음은
M2(반응형 코어 — Source/State/Store)**. **⚠️ [2026-08-24] M2와 M3의
번호·순서가 맞바뀌었다** — 예전엔 M2=디스패치, M3=반응형이었는데 의존이
한 방향(디스패치 → 반응형)이라 반응형을 먼저 짓기로 확정했다. 그래서
**2026-08-24 이전에 쓰인 `session/`·`archive/`·`qa-request/` 문서의
`M2`/`M3`는 옛 의미로 읽을 것**(라이브 문서는 전부 새 번호로 맞춰뒀음).
경위는 `.claude/archive/question-resolved.md`의 "마일스톤 경계" 절,
새 구성은 `ROADMAP.md`의 M2 배너. **⭐ [2026-08-26] 8라운드 손 트레이싱까지
처리 완료 — M2 착수를 막는 항목이 하나도 없다.**
결정의 소스는
`.claude/qa-request/pre-implementation-handtrace-round8-followup.md`
(7라운드 몫은 `-round7-followup.md`; **[2026-08-27] 9라운드 몫은
`-round9-followup.md` — Q1~Q10·`H-138`·`H-139`·`H-142`, 그리고 `/code-review`가
낸 `H-143`~`H-146`까지 전량 반영 완료**; **[2026-08-28] 10라운드 몫은
`-round10-followup.md`** — 광범위 탐사 `H-150`~`H-157`까지 전량 결정·반영, 그중
`H-143`과 `H-146` 루트 예외는 하루 만에 뒤집힘)이고, `.claude/question.md` 최우선
절엔 `Claim` 갈래(`research/existing-mount-plan.md` §5, 특히 다중 스크립트)만
남아 있다(M2 착수 게이트는 아님). 같은 상태를 `.claude/project-context.md`도
서술하니 마일스톤이 넘어갈 때 두 곳을 같이 고칠 것. 진행 상황의 소스는
항상 루트 `ROADMAP.md`.

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
| 문서 전체 색인 — 어느 파일이 뭘 다루는가 | `.claude/README.md` |
| 사용자가 답해야 할 열린 질문 | `.claude/question.md` |
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
