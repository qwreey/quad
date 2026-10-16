# `qa-request/` — 구현 뒤 코드 리뷰 원장·외부 감사 진입점

> **[2026-09-08 분리 — round7 Q39 사용자 결정]** 루트 `.claude/README.md`가 폴더마다 수천~수만 자의 행을 쥐고 있어(한 셀 17,005자) 폴더별 `README.md`로 나눴다(사용자: *"README.md 를 분리해 각 폴더 내에 두어 폴더가 뭐하는지 설명하는건 괜찮은것 같아"*). **이 파일이 `qa-request/`의 기준과 파일 색인의 소스**이고 루트 README는 폴더 한 줄씩만 쥔다. `doc-check.py`의 색인 검사는 루트 + 이 파일을 함께 본다.

> **[2026-10-16 재구성 — 사용자 결정]** *"더이상 근거로 쓸 일이 없어진 오래된 qa에 대해서 archive 로 옮기는게 필요할듯"* — 회신이 끝난 round1~12와 round14 반영 순서표는 `archive/post-implementation-review/`로 옮겼고(그 폴더 `README.md`가 색인과 옛 이력 원문), 이 폴더에는 아직 자주 인용되는 최근 원장과 외부 감사 진입점만 둔다. 옛 셀(18,938바이트 — 폴더별 README로 나눴던 이유와 같은 문제가 재발)은 그 README로 옮겼다.

- `external-review-entry.md` — 외부 모델(Gemini 등)에게 감사를 시킬 때 먼저 읽힐 진입점.
- `post-implementation-review-round13.md` — **[2026-09-26 신설]** 자율 수집 루프(사용자 지시, 2026-09-26 밤 → 2026-09-27 11:05 KST 사용자 지시로 조기 종료) 발견 원장 — `H-595`~`H-865`; §0 요약표·결정 묶음이 읽는 순서, §4가 사용자 문항(`Q73`~`Q157`). 각도·회차는 `session/2026-09-26-01-autonomous-loop.md`.
- `post-implementation-review-round14.md` — **[2026-10-01 신설]** round13 남은 문항 이관(포인터 표 — 본문은 round13 §4) + 프로젝트 전체 원칙 감사(`audit/round14-principle-audit/`) 결과와 문항별 재검토. 새 문항은 `Q160`부터.
