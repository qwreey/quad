---
name: quad-corpus-structure
description: Layout of quad's .claude/ design-doc corpus and what's in/out of audit scope
metadata:
  type: project
---

quad는 Roblox DOMless UI 렌더러를 처음부터 재작성하는 프로젝트, 설계 단계가
길다. `.claude/` 코퍼스 레이아웃:

- 항상 로드(루트 `CLAUDE.md`가 `@import`): `.claude/conventions.md`(관례/작업
  방식), `.claude/project-context.md`(프로젝트 설명+문서 구조),
  `.claude/todos.md`(지금 할 일, 가장 자주 바뀜). **2026-08-16 세션에 루트
  `CLAUDE.md`(원래 1537줄, 세션 히스토리가 80%)를 이렇게 4분할** —
  `.claude/session-summary.md`(세션 요약 색인, 1200줄+)는 의도적으로
  import 안 됨, grep으로 온디맨드 조회.
- 감사 스코프 밖: `.claude/session/`(세션 원문, stale 여부 안 따짐),
  `.claude/initreq/`(읽기 전용 클론), `.claude/worktrees/`.
- `.claude/archive/`는 "뒤집힌 결정을 원문 그대로 보존"하는 목적이라 낡은
  서술이 있어도 정상 — 문제는 라이브 문서가 archive 항목을 유효한 것처럼
  인용할 때만.
- `.claude/luau-test/` 상태는 항상 `STATUS.md`가 소스(폴더 구조 자체가
  상태: done/rewrite-required/review-required/not-run), `.claude/audit/`
  개수는 `.claude/README.md`의 `audit/` 행이 소스. 둘 다 "직접 나열하다
  stale해지는 패턴"이 실제로 반복돼서 다른 문서에선 개수를 안 세기로
  확정된 관례.

`.claude/tools/doc-check.py`가 깨진 파일/절 참조, README 색인 누락, 날짜
없는 시한부 주장, 미반영 배너를 기계적으로 잡음 — 감사 시작 전에 항상
먼저 돌리고 그 출력을 리포트 맨 위에 포함, 같은 종류를 손으로 재탐색하지
않는다. `.claude/agents/quad-doc-auditor.md`(나 자신의 정의 파일)가 2026-08-16
세션에 신설됨. 같은 날 `.claude/workflows/quad-handover-audit.js`(다회·병렬
수렴 루프)도 신설됐다가 **같은 날 폐기·삭제됨** — 토큰 과다 + 파일별 픽스
에이전트가 부정확한 서술을 새로 생산 + 서브에이전트는 사용자에게 못 물음.
**지금 감사 절차의 소스는 `.claude/conventions.md`의 "작업 방식" 절**(메인
세션이 나를 병렬로 여러 개 띄우고, 수정은 메인이 일괄로 함, 패스 수는
최소 2에서 변경 규모에 따라 증가). 워크플로가 있다고 전제하지 말 것.
