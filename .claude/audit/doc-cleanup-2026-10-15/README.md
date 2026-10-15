# 문서 정리 2026-10-15 — Gemini 탐사 둘 → opus 검증 → 메인 적용

사용자: *"`.claude` 문서 쌓여 있는것들 중에서 stale 하거나 이미 처리되었는데 위치가 잘못되었거나 한 것들 많을거야 … doc audit 못 돌린지 되었으니까"*.
Gemini 둘(`gemini-a.md` — research/·question.md·ROADMAP·HUMAN_TODO·todos.md, `gemini-b.md` — base/·reference/·feedback/·색인·project-context·CLAUDE.md)이
40건을 냈고, opus 하나가 레포에서 하나씩 재확인했다(Gemini의 줄 번호·수치 틀림 여럿 — 처리안은 검증자가 다시 적은 것으로 적용). 보관본의 "옮길 곳 제안" 경로는
없는 파일이라 백틱을 풀었다.

**적용(확정 22 + 놓친 것 8 중 7)**: research 색인·`upward-flow`·`deferred-hardening` 1절 이동·`v1-compat` 결론·`operator-sugar` 주석·`consumer-kits` Studio 항목 닫힘 표시;
`question.md` 닫힌 항목을 `archive/question-resolved.md` 끝 절로 원문 그대로 옮김(248 → 70여 줄, v1 compat 불릿은 9.4 문항 포인터로); ROADMAP 용어 정리·에러 ID·0절 참조 셋;
HUMAN_TODO J 상태·F의 공개 표면 문항; `todos.md` 00번 재작성(242 → 87줄 — 구간별 경과 서술은 git 히스토리), 2번·8번 삭제, 4번을 ROADMAP 포인터로;
`.claude/README.md`·`project-context.md`의 옛 단계 서술; base의 architecture(남은 것·API 이름·`:With` → `:Depend` 두 자리), slot-plan(Q76 채택 배너·`slot:Lazy` 절 신설),
attribute/tag(용어 정리 해소), source-state(이름 항목 닫힘), bind-system(`D` → `Declaration`), gate(남은 것 절 제목), debounce(`Quad0044`), error-id(7절 제목); question.md 4절.

**기각 9**: 배너가 이미 정정한 것, 닫힌 것을 표시해 두는 파일 관례(ROADMAP·HUMAN_TODO 하위 줄), 지금도 참인 서술(component-composition "API 이름뿐" — 경계 필드 이름 Q2 열림) 등.

**미완**: base 전체의 `:With` 잔존 일괄 판정(이력 맥락이 대부분), feedback/·reference/의 독립 재검토. **사용자 판단 대기**: research 넷의 이동(J1), HUMAN_TODO J 통째 닫기(J2),
`qa-request/README.md` 한 셀 18,938바이트 재구성(J3), ROADMAP의 "각 마일스톤 완료 시 기록" 체크박스(J4), HUMAN_TODO 3.1.0 태그 싱크·VSCode 재시작 확인 두 줄(J5).
