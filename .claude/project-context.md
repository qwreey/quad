# 프로젝트 컨텍스트

루트 `CLAUDE.md`가 `@import` 하는 파일. 폴더별 **상세** 색인은
`.claude/README.md`가 소스 — 여기선 중복 서술하지 말고 가리키기만 할 것.

## 이 프로젝트가 뭔지

Roblox 엔진에서 동작하는 DOMless UI 렌더러 **quad**를 처음부터 다시 짜는
프로젝트. 목표는 개별 프로덕트가 아니라 **라이브러리**로서의 코드 퀄리티와
지속 가능성 — 빠른 이터레이션보다 정확성/설계 정합성이 우선. 작업 기간은
길게 잡음.

**[2026-08-16 기준] 지금은 설계/계획 단계이고 구현은 아직 시작 전**(M0에
착수하면 루트 `CLAUDE.md` 머리말도 같이 고칠 것 — 같은 상태를 두 곳이
서술하고 있음) — 저장소 루트에 실제 소스
코드(`src/` 등)가 없음. 핵심 아키텍처(Store 책임 분리, `process`/`retract`
디스패치 모델, Store/State/Source 온톨로지, 소스 트리 구조, Modifier 메커니즘,
컴포넌트=플레인 함수, 컴포넌트 경계 modifier/Ref 전달)는 전부 `.claude/base/`에
문서로 확정돼 있음 — 먼저 `.claude/base/architecture.md`를 읽을 것. 사용자가
직접 "지금 quad에서 가장 문제되는 부분"으로 지목했던 컴포넌트화(특히
modifier/Ref의 컴포넌트 경계 통과 방식) 논의도 2026-08-04 세션에서 수렴
완료(`base/component-composition-plan.md`) — 남은 핵심 설계 질문은 없고,
용어 정리(진행 중)와 실제 스캐폴딩만 남음, `.claude/todos.md` 참고.

이전에 시도했다 폐기한 v2 재작성 시도(`.claude/initreq/quad2-try`)도 리서치
완료 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` copy-on-write 절충안은 확인된
죽은 접근이라 반복 조사 금지(`base/bind-system-plan.md` "확정된 것" 절 참고).

## 계획 문서 구조

`.claude/README.md`가 색인. 요약:
- **[2026-08-16]** 루트 `CLAUDE.md`는 짧은 진입점일 뿐이고, 실제 내용은
  `.claude/conventions.md`(관례·작업 방식) / 이 문서 / `.claude/todos.md`
  (지금 할 일)로 쪼개져 `@import`로 다시 합쳐짐. `.claude/session-summary.md`
  (세션 요약 색인)만 **import 안 됨** — 필요할 때 직접 열 것.
- `.claude/base/` — 확정된 아키텍처/컨텍스트, plan/done 개념 없음. 먼저
  `.claude/base/architecture.md`를 읽을 것.
- `.claude/reference/` — **[2026-08-07 신설]** base처럼 확정된 건 아니지만
  base 문서가 근거로 인용하는 온디맨드 참고 자료(v1 내부 동작 스냅샷,
  Fusion/Vide 비교 리서치) — 항상 읽을 필요는 없고 인용될 때만 열어볼 것.
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의. 전부
  후순위. **어떤 문서가 있는지·우선순위가 뭔지는 여기서 세지도 나열하지도
  않고 `.claude/README.md`의 `research/` 표로 미룸**(개수뿐 아니라 파일명
  나열 자체가 새 문서가 추가될 때마다 stale해지는 패턴이 실제로 반복됐음 —
  과거엔 "두 개뿐"이라 적어놨다가, 2026-08-16엔 7개짜리 나열이 실제 11개와
  어긋난 걸 감사가 발견. 아래 luau-test/audit 문단과 같은 처리로 통일).
  `research/`를 떠난 것만 짚으면: `tween-plan.md`는 2026-08-12 세션에 마지막
  열린 항목까지 전부 해소돼 `base/`로 승격, 이미 생성된 인스턴스 재바인드는
  2026-08-14 세션에 기각돼 `archive/existing-instance-bind-rejected.md`로
  이전 — 둘 다 더 이상 여기 없음.
- `.claude/luau-test/` — **[2026-08-09 신설]** "추론만으로 확정하고 실제
  Luau로 부딪혀본 적 없는 것"을 미리 검증하는 독립 실행 스파이크 모음
  (`luau <파일>` / `luau-analyze <파일>`). **상태의 소스는 항상 `STATUS.md`**
  (pass / 사람 결정 필요 / 스파이크 깨짐 / 미실행, 폴더 구조 자체가 상태),
  각 파일이 뭘 왜 검증하는지는 `README.md`. 2026-08-13에 첫 실측 완료(당시
  런타임 12개 전원 통과) — 이후 여러 세션에 걸쳐 재설계로 몇 건이 추가로
  `rewrite-required/`에 합류했으니 **총 몇 개인지도, 지금 몇 개가 어디
  있는지도 여기서 세지 않고 `STATUS.md`로 미룸**(세거나 나열하다 stale해지는
  패턴이 실제로 반복됐음, `.claude/todos.md`의 luau-test 스파이크 항목 참고).
- `.claude/audit/` — **[2026-08-13 신설]** 스파이크를 실제로 돌린 **실측
  결과** 기록(계획 아님). 부분 확인도 있는 그대로 남김 — **지금 몇 개가
  있는지·각각 뭘 확인했는지는 여기서 나열 안 하고 `.claude/README.md`의
  `audit/` 행으로 미룸**(luau-test와 같은 이유 — 나열하다 새 폴더가
  추가될 때마다 stale해지는 패턴이 실제로 반복됐음, 가장 최근엔
  2026-08-15에 이 목록이 3개에서 멈춰 있는 걸 `/code-review`가 발견).
  `type-recursion-issue/`만 참고로 짚으면: **[13차 세션]** 0-Y 재실측
  전체 — `REPORT.md` + `spikes/`(개수는 폴더가 소스), **스크립트를 같이 두는** 예외적
  구성(판정이 "여러 formulation 대조"라 개별 파일을 직접 돌려야 재현됨),
  결론은 `base/typing-limits.md`로 승격 — 이후 신설된 폴더들도 같은
  구성 관례를 따름(`type-recursive-issue-with-typeof/`,
  `type-recursive-issue-try-callback/` 등).
- `.claude/qa-request/` — 원래는 "구현이 끝나고 사용자 실기기 QA만 남은 것"을
  담는 폴더였으나, **[2026-08-18]** 구현 전 사용자 심사 라운드의 산출물도
  여기 둠(`pre-implementation-qa-round1.md`, 2라운드 예정 — 라운드마다 새
  파일). `.claude/feedback/` — 구현 시작되면 쓰기 시작함,
  **[2026-08-18 기준] 폴더 자체가 아직 없음**.
  `.claude/archive/`는 원래 같은 취급이었으나
  2026-08-06 세 번째 세션부터 **완전히 뒤집힌 설계 결정을 원문+역전
  이유+diff와 함께 보존하는 용도로도 사용 시작**(구현 완료 대상만이
  아님) — `archive/store-source-proxy-reversed.md`가 첫 사례, 나중
  `quadnomicon` 콘텐츠 소재로 재사용 예정.
- `.claude/session/` — **[2026-08-11 신설]** 세션별 상세 로그 원문(시행착오·
  정정 전 서술 포함, `quadnomicon` 개발로그 소재용) — 루트 `CLAUDE.md`가 3000줄
  넘게 불어나 성능 저하를 유발해서 분리함. `.claude/session-summary.md`의 각
  항목이 여기로 링크. **항상 읽을 필요 없음** — 특정 결정의 논의 과정/시행착오가
  궁금할 때만 열어볼 것, 지금 유효한 설계는 항상 `base/`가 소스.
- `.claude/initreq/` — 클론해둔 참고 레포(quad v1, Fusion, Vide, rbvm, tbox,
  code-docker) + PA님 실 코드(`artworks/`) + 원본 요청. **읽기 전용,
  `.gitignore`로 커밋 제외됨** — 내용을 다른 곳으로 옮기지 말고 항상 원본
  그대로 둘 것. 리서치가 더 필요하면 이 폴더를 다시 파고들 것.
- `.claude/question.md` — 사용자가 답해야 할 질문 전체 취합(우선순위순).
- 루트 `ROADMAP.md` — 설계 단계 종료 후 실제 구현 순서(M0, M1, ... 마일스톤 +
  todo 체크박스). "무엇을 확정했는가"는 `.claude/base/`가 소스, "어떤 순서로
  만드는가"는 이 문서가 소스 — 헷갈리지 말 것.
- 루트 `HUMAN_TODO.md` — 사람만 할 수 있는 일(로컬 GUI 조작, 스케줄/루프
  설정 등).

