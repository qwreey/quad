# E75 서브에이전트 브리프 — 에러 레퍼런스 "고치려면" 실측

레포 `/code/Projects/quad`(Luau UI 라이브러리 quad). **레포 파일은 읽기 전용** — 쓰기는 `.claude/audit/round13-e75-error-prescriptions/` 아래에만(아래 지정 파일). 커밋·`git stash`·push 금지. 스크래치 파일 이름을 `spec.*.luau`로 하지 말 것. `./scripts/relink.sh`는 메인이 이미 돌렸다 — 다시 돌리지 말 것.

## 할 일

담당 페이지 `docs/reference/errors/<페이지>.md`의 모든 `### QuadNNNN` 절에 대해:

1. 그 id를 **정확히** 내는 가장 작은 프로그램(trigger)을 mock 위에서 쓴다 — 공개 API로.
2. 같은 프로그램에 그 절의 **"고치려면"을 글자 그대로** 적용한 판(fix)을 쓴다. fix는 에러가 없어야 하고, **사용자가 원했을 동작을 실제로 해야 한다**(다른 에러로 바뀌기만 하거나, 조용히 아무 일도 안 하면 안 됨) — fix 함수 안에서 결과를 확인하고 `return true/false, "설명"`.
3. 판정: **정확**(trigger→fix 둘 다 됨) / **불충분**(fix가 그 에러는 없애지만 다른 에러가 나거나 원한 동작이 안 됨 — 두 번째 에러 원문을 적을 것) / **틀림**(fix가 그 에러를 못 없앰, 또는 없는 API·인자를 가리킴) / **미도달**(trigger 불가 — 이유).
   - "고치려면"이 여러 갈래(A 하거나 B 하세요)면 갈래마다 따로 해 본다(case id에 `Quad0123a`/`b` 접미 가능 — 러너는 첫 줄에 id 부분문자열이 있는지만 본다. 접미를 쓸 거면 `id = "Quad0123"`로 두고 `note`로 구분하거나 print로 표시).
   - "고치려면"이 "하지 마세요"류(행동 금지)면 금지한 행동을 뺀 프로그램이 원래 의도를 달성할 수 있는지를 본다(달성할 길을 안 알려주면 불충분 후보 — 단 의도가 원래 불법이면 정확).
4. 부수로 기록: (a) trigger 메시지의 blame(`파일:줄:` 접두)이 사용자 코드(케이스 파일)가 아니라 quad 내부에 떨어지는 id — 페이지가 blame에 대해 뭔가 말하면 그 주장과 비교, (b) 페이지 "언제"가 안 적은 경로로 난 경우(아래 E28 목록에 이미 있는 변형은 빼고).

## 도구 (이미 있음 — 고치지 말 것)

- `harness.luau` — mock 백엔드 + 실 quad-roblox 프로바이더. `local H = require("../harness")`로 `H.q`(quad, 프로바이더 설치됨), `H.D`(=`q.Declaration`), `H.runTask(dt)`(가상 `task` 시계 진행 — Debounce/Throttle·Tween 완료 등), `H.mock`, `H.game` 등. 반영된 클래스·프로퍼티는 파일 안 `REFLECTED` 표(Frame/TextLabel/TextButton/… — 여기 없는 프로퍼티는 mock에서 미반영 취급).
- `runner.luau` — `local R = require("../runner")`; `R.case({ id = "QuadNNNN", trigger = fn, fix = fn, note = "...", fixnote = "..." })`, 끝에 `R.done()`. trigger/fix를 생략하면 skip(`note`/`fixnote`에 이유). `R.raises(fn, id)` 헬퍼.
- 실행: 레포 루트에서 `mise exec -- luau .claude/audit/round13-e75-error-prescriptions/cases/<파일>.luau`. 출력 줄 `@@E75\tid\tTRIG=…\t메시지\tFIX=…\t설명`.
- 본보기: `cases/smoke.luau`.
- 모듈 전역 상태를 건드리는 케이스(`UseProvider` 두 번, `AddPlugin`, 모듈 설치 순서 등)는 별도 파일 `cases/<그룹>_iso_<짧은이름>.luau`로 떼서 새 프로세스에서 돌린다(require 캐시). 새 quad 인스턴스가 필요하면 `require("../../../../quad-roblox/luau_packages/quad_base")`(cases/ 안에서 — `..` 넷) 한 벌만 쓸 것(`quad-base/src`와 섞지 말 것 — 하네스가 이미 쓰는 벌).
- 트리거 착안점: 이전 탐사 E28이 id마다 트리거를 가졌다 — `.claude/audit/round13-e28-errors-xref/triggers/*.luau`와 `out/trigger-results.txt`·`out/probe-results.txt`, 그리고 spec(`quad-base/test/spec.*.luau`, `quad-roblox/test/spec.*.luau`)에서 id를 grep. 단 그 스크립트들은 패치된 사본의 `quad-base/test/` 안에서 돌던 것이라 require 경로가 다르다 — 로직만 가져올 것.
- raise 자리: `grep -rn "QuadNNNN" quad-base/src quad-roblox/src`.
- E28 README(`.claude/audit/round13-e28-errors-xref/README.md`)의 "발견 본문"에 id별 기존 발견(메시지·언제·일부 고치려면)이 있다. 그중 문서가 이미 고쳐졌을 수 있으니(원장 `.claude/qa-request/post-implementation-review-round13.md`의 `H-nnn`) **현재 페이지 문구 기준으로** 판정하고, E28이 이미 같은 고치려면 문제를 적었으면 "E28 기추적(현재 문구에 남아 있음/고쳐짐)"으로 표시.

## 규칙

- Luau 동작에 대한 주장은 실측한 것만. 새 메커니즘·API 제안 금지 — 문서 문구 대안이나 사용자 문항 후보(갈래 포함)까지만.
- 발견은 평문 한국어 문단(상황 → 무엇이 틀렸나 → 실측 근거(케이스 파일:줄, 출력 원문)).
- `Studio`/엔진 전용이라 mock에서 못 닿는 id는 미도달로 이유 적기.

## 산출물 (이 셋만)

1. `cases/<그룹>.luau`(+ 필요하면 `cases/<그룹>_iso_*.luau`)
2. `out/<그룹>.txt` — 케이스 파일 실행 출력 그대로(`… > out/<그룹>.txt 2>&1`, iso 파일은 `out/<그룹>_iso_*.txt`)
3. `out/<그룹>-notes.md` — 한국어. (i) id별 한 줄 표: `| id | 페이지:줄 | 판정 | blame(사용자/내부 파일:줄) | 한 줄 메모 |`, (ii) 불충분·틀림·미도달·blame 이상·누락 변형 각각의 평문 발견 문단(페이지 줄 번호와 코드 줄 번호), (iii) 페이지별 개수(섹션/시도/정확/불충분/틀림/미도달), (iv) 미완 목록(명시).

## 마지막 보고

SubagentHandback 한 번에: 개수 표 + 불충분/틀림/미도달/blame 이상 발견 목록(각 한두 문장, 파일:줄) + 미완. 후속 송신 약속 금지 — 미완은 "미완"으로 표시.
