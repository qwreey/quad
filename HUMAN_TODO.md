# HUMAN_TODO — 사용자(사람)만 할 수 있는 일

에이전트가 못 하거나(로컬 GUI 조작, 외부 계정/기기 필요) 사용자의 결정이 필요해서
멈춰둔 것만 여기 모음. 설계 질문은 대체로 `.claude/question.md`에 따로 있고 디폴트를
잡아둔 채 진행 중이라 급하지 않음 — **단 2026-08-13부터는 예외가 생겨 아래 4번에
올렸었음**(0-Z) — **[2026-08-13 열네 번째 세션] 그 0-Z도 해소되어 지금은
사람이 결정해야 M0가 열리는 항목이 없음**(0-Y는 열세 번째 세션에 해소).

## ✅ 11. **[2026-08-22 신설 → 2026-08-24 해소] 마일스톤 순서 결정**

사용자가 **(a) 순서 교체**를 선택해 닫혔다 — 반응형이 M2, 디스패치가 M3다.
결정과 근거는 `.claude/archive/question-resolved.md`의 "마일스톤 경계" 절,
새 마일스톤 구성은 `ROADMAP.md`의 M2 배너가 소스.

**✅ [2026-08-25 해소] 그 교체로 한때 `question.md` 최우선 절에 항목 둘이
올라왔었다** — 중간 State GC 실측과 동적 키 표면(옛 `store:GetDynamic`) 위치.
**둘 다 닫혔다**(GC는 `_hold` 불변식으로, 표면 위치는 콜론 유지 + 예약 키
진단 타입 함수로) — 7라운드 손 트레이싱 후속이 소스이고, 2026-08-26 8라운드도
"M2 착수를 막는 항목이 하나도 없다"로 재확인했다. **`question.md` 최우선
절은 지금 비어 있다.**

---

## ✅ 1. ~~Roblox Studio에 MCP로 연결~~ **[2026-09-01 해소 — 연결 실측 완료]**

**사용자가 본 계정과 무관한 별도 계정(`qwreey_selene`)을 별도 컨테이너에
준비**했고(다른 사용자 미사용 — `SAFETY.md`의 별도 계정 게이트 충족), MCP
프록시가 `http://studio:8787/mcp`에 떠 있다. 인증 토큰은 **레포가 아니라
전역 Claude 설정(`~/.claude.json`의 `mcpServers.roblox-studio` 헤더)에만**
들어 있음 — 레포 문서에 토큰을 적지 말 것. 연결 실측(2026-09-01):
`list_roblox_studios` → 인스턴스 1개("Place1"), Edit 모드,
`execute_luau`로 Instance 생성·`GetPropertyChangedSignal("ClassName")`
(gcconn 트릭 재료)까지 정상 동작 확인(version 0.736). **이로써 아래 5번
(스파이크 `10` 잔여)을 에이전트가 대신 돌릴 수 있게 됐다** — 단 A 섹션
재작성이 선행. 아래는 해소 전 원문:

## (구 1번 원문) Roblox Studio에 MCP로 연결 (테스트 자동화용)

Roblox가 2026-02부터 Studio에 **MCP 서버를 내장**했음 — 예전처럼 Rust로 직접
`studio-rust-mcp-server`를 빌드할 필요 없이 Studio 자체 베타 기능으로 켜면 됨.

**설정 방법** (사용자가 로컬에서 직접):
1. Roblox Studio → File → Studio Settings → Beta Features → **MCP Server** 활성화
2. 기본적으로 `localhost:3004`에서 리슨 시작함
3. Claude Code의 MCP 클라이언트 설정(`.mcp.json` 등)에 이 로컬 서버를 추가 —
   이 설정 파일 자체는 내가 대신 만들어줄 수 있으니, Studio에서 베타 기능만 켜고
   "여기 프로젝트에 연결해줘"라고 말해주면 이어서 진행함.
4. 노출되는 툴: `create_object`, `set_property`, `set_script_source`,
   `execute_luau` 등 — Undo 히스토리를 존중해서 Ctrl+Z로 되돌릴 수 있음(안전망 있음).

**주의(사용자가 이미 말한 것)**: Roblox Studio는 잘 죽는 편 — 죽었을 때 살리려고
위험한 명령을 반복 시도하지 않을 것이고, 그런 날엔 MCP 없이 할 수 있는 작업만
하거나 대기함. 이 안전 원칙은 `.claude/conventions.md`에도 적어둠.

**해야 할 일**: 테스트용 place 파일(빈 place 하나, 또는 `quad/test.project.json`
기반 rojo 싱크 대상)을 열어서 베타 기능만 켜주면 됨. 이후 MCP 서버 설정 파일
작성/연결 확인은 내가 진행 가능.

**`SAFETY.md` 제약**: Studio는 메인 계정이 아닌 별도 계정으로만 사용하기로
되어 있음 — 계정 전환 여부를 알려주기 전까지는 MCP 연결을 진행하지 않고 대기함.

## 0. (SAFETY.md) Git 원격 저장소 계정 마련

`SAFETY.md`에 따라 이 레포는 GitHub 등 외부 호스팅에 올리지 않기로 되어 있음 —
모델(나)의 git 작업 공간은 사용자가 마련해줄 제한 계정 전용이어야 함(예:
git.qwreey.moe에 제한된 계정 생성). 로컬 git 저장소는 이미 초기화 + 초기
커밋까지 해뒀음(원격 없음) — 원격을 추가하고 싶으면 그 계정 정보를 알려줄 것,
그 전까지는 로컬 커밋만 계속 쌓아둠.

## 2. ~~자율 작업 루프/스케줄 설정~~ **[해소됨, 2026-08-28]**

**사용자가 M2를 세션 안 자율 구현 구간으로 확정**했다 — 규약은
`.claude/qa-request/m2-implementation-round11-brief.md`, 요지는
`.claude/conventions.md`의 "M2 자율 구현 규약" 항목. cron/`/schedule`은 안 쓴다
(사용자 개입 지점은 단위가 끝날 때 `-round11.md` §4 표를 배치로 회신하는 것뿐).
아래는 해소 전 원문.

사용자가 잠들어 있는 동안에도 계획된 TODO를 이어서 진행하길 원한다는 요청이 있었음
(`req.md` 참고). 이건 세션을 넘어 지속되는 자동 실행이라 다음 중 하나를 사용자가
직접 트리거해야 함(에이전트가 임의로 크론/무인 실행을 켜는 건 파급力이 커서 먼저
확인받는 게 맞다고 판단해 보류함):

- `/loop` — 지금 세션 안에서 일정 주기로 스스로 다음 작업을 이어가게 함(사용자
  대화 종료 전까지). 간단한 자율 반복엔 이걸로 충분.
- `/schedule` — 진짜 cron 스케줄로 별도 클라우드 에이전트를 반복 실행(예: 매일
  새벽에 큐에 있는 다음 plan 문서 하나씩 처리). 무인 상태로 더 오래/여러 날에
  걸쳐 진행하고 싶다면 이쪽.

원하는 주기/범위를 알려주면 그에 맞춰 설정해줄 수 있음. 어떤 걸 골라도, 진행한
내용은 항상 `.claude/`에 자기 문서화(완료 표시, 다음 TODO 갱신)해서 다음 세션이나
사람이 바로 이어받을 수 있게 할 것.

## 4. ~~`question.md` 0-Z 결정~~ **[해소됨, 2026-08-13 열네 번째 세션]**

**더 이상 사람이 막고 있는 결정이 아님.** 사용자가 같은 세션에 직접
`Attribute:GetKey(name)` 방향을 제시했고, 트레이싱으로 검증한 뒤
**그룹 전용 키(비공개 `GetKey`) + `AttributeKeyHandler`의 이름 claim**으로
확정 → `base/attribute-plan.md` "이름 소유권" 절에 반영. 같이 묶여 있던
재디스패치 모델(0-A)도 같은 패스에서 `base/dispatch-core-plan.md`(신설)로
전면 반영됐고, ⚠️ 배너를 달고 있던 7개 문서 전부 갱신 완료.

**같은 세션에 사용자가 추가로 결정한 것** — `Tag`/`Attribute`의 알고리즘을
통째로 quad-base로 옮기고 백엔드는 `addTag`/`removeTag`/`setAttribute` 세
op만 주입(웹의 `className`/`data-*` 대응 때문). 상세는
`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op" 절.

> **[2026-08-13 열세 번째 세션] 여기 같이 있던 `0-Y`도 해소됨** — 44개
> 스파이크 재실측으로 원인이 콜백 계약이 아니라 **Luau 자체의 한계**임이
> 확정됐고, 대응은 "파생 State를 만드는 자리마다 결과 타입 명시 주석
> 바인딩" 관례 하나. 규약은 `.claude/base/typing-limits.md`, 근거는
> `.claude/audit/type-recursion-issue/`. 거기서 파생된 작은 확인거리
> 하나(에디터의 Luau 솔버 설정)만 아래 6번에 남아 있음 — M0 착수 때
> 확인하면 되고 지금 막고 있진 않음.

## 5. ✅ [2026-09-01 해소 — 에이전트가 MCP로 완주] Studio 전용 스파이크 `10` 마저 돌리기

**1번(MCP 연결) 해소 직후 같은 날, 에이전트가 A 섹션을 현행 모델로
재작성하고 `execute_luau`로 전 구간 완주했다** — "사람만 가능"이라는 제목
전제 자체가 MCP로 사라진 것. 전 항목 PASS, 아래 "남은 확인거리"는 전량
해소(결과 전문은 `.claude/audit/spike10-full-run-2026-09-01.md`, 파일은
`.claude/luau-test/done/`). 아래는 해소 전 원문:

`.claude/luau-test/`는 2026-08-13에 첫 실측이 돌아 **런타임 12개 전원
통과**했으나, `10-roblox-studio-checks.server.luau`만 **Studio 전용이라
`luau` CLI로 못 돌림**. A 섹션 앞부분(ClassName 신호 미발화, Destroy 시
`Connected` 즉시 전환)은 사용자가 자작 스크립트로 이미 확인
(`.claude/audit/gcconn-trick-verification.md`).

**[2026-08-14 다섯 번째 세션] 지금 바로 돌릴 수 있는 상태가 아님 — 먼저
에이전트가 A 섹션을 재작성해야 함.** `bindLifetime`/`canExecute`/
`unbindLifetime` 재정정으로 A가 폐기된 모델(`canBound`, `bindLifetime`의
`.Subscribed` 세팅, 2-인자 `canExecute`)을 검증 중이라 파일이
`.claude/luau-test/rewrite-required/`로 옮겨졌음. **[2026-08-14 열한
번째 세션 재정정]** 이중 바인딩 게이트는 `canExecute` 하나가 아니라
**`canBound`**로 별도 진입점 재도입됨(`canExecute`는 emit 게이팅 전용,
판정 로직은 비공개 헬퍼 하나를 공유 — `base/lifecycle-pattern.md`의
"`canBound` vs `canExecute`" 절). **남은 확인거리**는 이중 바인딩
게이트(`canBound`)와 unbind/Destroy 후 재바인딩 허용, `value` 쪽에
복사된 gcconn만으로의 생존 판정, Instance userdata 동일성, 그리고
B(Attribute의 Instance 참조 타입)/C(CollectionService 태그 왕복) —
목록은 `.claude/audit/gcconn-trick-verification.md`의 "아직 확인 안
된 것"이 소스. GC 강제 트리거가 필요하면
`.claude/luau-test/not-run/gc-trigger-helper.server.luau` 참고. 위
1번(MCP 연결)이 되면 에이전트가 대신 돌릴 수도 있음.

## 8. **[2026-08-16 신설, 안 막음]** `const` 바인딩 — 툴링이 언제 지원하는지 사용자만 알 수 있음

`base/architecture.md`의 "코드 스타일" 절이 `const` 바인딩을 **[2026-08-12
기준] 채택 안 함**으로 두고 있음. 사유가 "주변 툴링 미성숙"인데, **이건
에이전트가 확인할 수 없는 정보**라 사용자가 알려주는 게 맞다고 사용자
본인이 정리함(2026-08-16).

**사용자가 설명한 구체적 사정**: 예를 들어 **pesde**의 타입 추출 —
`d.ts`처럼 types를 emit하는 류의 툴링이 있는데, 아직 미성숙해서 `const`를
제공하지 못하는 상황. **언제 다시 사용 가능해지는지가 명확하지 않음.**

**사람이 할 일 — 둘 중 하나**:
1. `const`를 쓸 수 있게 되는 시점을 파악해 알려주거나,
2. 사용 가능해지는 순간 에이전트에 알려줄 것.

둘 중 어느 쪽이든 **에이전트는 스스로 판단하지 않고 대기**한다 — 알려주기
전까지는 `architecture.md`의 "`const` 바인딩도 Luau 공식 문법" 절이 정한
"새로 짜는 코드는 일단 `local`로" 원칙을 그대로 따름. 알려주면 그때
`architecture.md`의 해당 절을 갱신하고 기존 코드의
`const` 전환 범위를 같이 상의할 것.

## 6. ~~에디터의 Luau 솔버 설정 확인~~ **[2026-08-19 설정 완료 — VSCode 재시작만 확인해주면 됨]**

`luau-analyze` CLI는 새 솔버가 기본값이지만 에디터가 쓰는 `luau-lsp`는
**옛 솔버가 기본값**(`LuauSolverV2=false`)이라 같은 코드에 다른 진단이
나옴 — 예전엔 "실제 에디터 환경에서 확인 필요"로 사람에게 넘겨뒀던
항목.

**[2026-08-19] `luau-lsp` 바이너리(1.69.0, `luau-lsp analyze` CLI 모드)를
`/code/.local/bin`에 직접 설치해 `--flag:LuauSolverV2=true/false`
양쪽으로 실측 — 새 솔버가 필요하다는 결론을 재확인**하고
`quad/.vscode/settings.json`을 만들어 `{ "luau-lsp.fflags.enableNewSolver":
true }`를 이미 커밋해뒀음(팀/에디터 전체에 공유됨, 사용자가 손댈 것
없음). `tbox`(다른 참고 레포)도 동일 설정을 이미 쓰고 있어 교차 확인됨.
같이 검토했던 `LuauDoNotExportBrokenTypeFunction` override(tbox가 씀)는
quad의 현재 `type function` 스파이크(`16`/`21`)에서 유무 차이가 없어
**채택 안 함**(불필요한 설정 추가 지양).

**사람이 확인해줄 것 하나만 남음**: 이건 CLI로 시뮬레이션한 것이지
VSCode를 실제로 띄운 게 아님 — 다음에 VSCode를 열면 워크스페이스
설정이 잘 먹었는지(같은 `.luau` 파일에서 CLI 결과와 에디터의 빨간 줄이
일치하는지) 한 번만 눈으로 확인해주면 이 항목은 완전히 닫힘. 배경은
`.claude/base/typing-limits.md` 8번, 실측은
`.claude/audit/type-recursion-issue/REPORT.md` 5절.

## 7. ~~워크트리 `debounce-throttle-plan` 정리~~ **[2026-08-14 완료 — 할 일 없음]**

Debounce/Throttle 작업에 쓴 워크트리는 **사용자 확인 후 정리 완료**입니다
(`git worktree remove` + `git branch -D worktree-debounce-throttle-plan`,
당시 HEAD `5518055`). 지금 `git worktree list`엔 메인 하나만 남아 있고
`.claude/worktrees/`도 비었습니다.

**잃은 정보 없음** — 필요한 변경은 전부 `main`에 이식돼 있습니다
(`623c931` 백로그 신설 + emit 전파 정정, `6dbce6c` 핸드오버 노트).
지우기 전에 (1) 두 커밋이 `main` 조상인지, (2) 워크트리에 미커밋 변경이
없는지, (3) `git worktree list`에 다른 에이전트 워크트리가 없는지를
확인했습니다. 이 항목은 기록용으로만 남겨둡니다.

## 9. **[2026-08-19 신설, 안 막음]** `type-version-check` 독립 저장소로 분리

`type-version-check/`(컴파일 타임 버전 패턴 매칭 — 글롭/캐럿, `quad-types`의
`CheckedQuad<T, Pattern>`이 이 위에 얹힘)는 quad에 종속되지 않은 범용
유틸이라 **사용자가 직접 독립 저장소로 분리할 예정**("우선 이 프로젝트
안에 넣어둬줘. 나중에 내가 다른 프로젝트로 분리해줄게.", 2026-08-19).
지금은 quad 워크스페이스의 네 번째 멤버(`workspace_members`)로만 있음 —
에이전트가 먼저 나서서 분리하지 말고 사용자가 하라고 할 때까지 대기.
설계/구현 상세는 `.claude/base/quad-types-plan.md`의
"`type-version-check`" 절.

## 10. **[2026-08-20 신설, 안 막음]** Tween 초기 진입 애니메이션(`initValue`) — 에이전트 작업 범위 밖

`base/tween-plan.md`가 **"필요해지면 사용자가 직접 코드베이스+문서를 만진다,
에이전트는 임의로 착수하지 말 것"**으로 확정해둔 항목인데, **여기 HUMAN_TODO에는
그 언급이 없어서 사람 쪽 할 일 목록에서 빠져 있었다**(2026-08-20 구현 전 QA
4라운드 `TW-16`에서 사용자가 지적 — *"틀리진 않았는데, Human todo 에 언급이
없음"*). 지금 보강.

- **무엇인가**: 다이얼로그가 아래에서 위로 슬라이드-인하는 것처럼 **첫 마운트에도
  애니메이션을 원하는 경우**. 지금은 "첫 세팅은 무조건 애니메이션 없이 즉시
  스냅"(3-상태 릴레이션 슬롯의 `prev == nil` 분기)이 기본이라 이게 안 된다 —
  그 기본값은 "엔진 기본값에서 목표값으로 날아오는 진입 애니메이션 버그"를
  막으려고 일부러 넣은 것이라, 우회하려면 그 억제 동작과의 상충을 같이 설계해야
  한다.
- **왜 에이전트가 안 하는가**(그 문서의 근거 그대로): Tween 정보가 부족한
  에이전트가 다루기엔 `hasBeenSet` 억제 동작과의 상충 판단이 미묘하고, 반대로
  Tween 자체가 다른 base 요소와 깊게 안 얽혀 있어(거의 전부
  `Handlers/Property.luau` 한 파일 + 릴레이션 슬롯) 사용자가 직접 처리하는 데
  범위상 문제가 없다.
- **지금 상태**: 미확정("필요성 낮은 쪽으로 기움", 완전 폐기는 아님). **M0/M2(**[2026-08-29]** 둘 다 완료)를
  막지 않으므로 급하지 않고**, 실제로 진입 애니메이션이 필요해지는 시점에
  사용자가 착수하면 된다. 설계 맥락은 `base/tween-plan.md`의 "초기 진입
  애니메이션(`initValue`)" 절.

## 3. `.claude/question.md`의 **나머지** 항목 검토 (급하지 않음)

디자인 결정 중 Lua/Roblox 엔진에 대한 깊은 경험이 필요한 것들은 합리적 기본값으로
진행하면서 `.claude/question.md`에 모아두는 중. 깨어있을 때 훑어보고 기본값이
마음에 안 드는 것만 답해주면 됨 — **[2026-08-24 갱신] 순수 설계 결정
대기는 여전히 0건**이고 2026-08-22에 열렸던 마일스톤 순서 결정도
**해소됐다**(위 11번 항목). **✅ [2026-08-26 갱신] 그 해소의 부작용으로
한때 올라왔던 항목 둘**(중간 State GC 실측, 동적 키 표면 위치)**도 2026-08-25에
닫혔고, 2026-08-26 8라운드 손 트레이싱까지 처리한 지금 `question.md` 최우선
절은 비어 있다.** 아래는 그 전 서술: **[2026-08-14 열한 번째 세션 기준]
`question.md`엔 이제 "결정 대기" 절 자체가 없음**(비어서 헤딩째로 삭제 —
마지막 남았던 0-W
`Ref` 이중 배치도 이 세션에 해소 — `base/ref-plan.md` "이중 배치 방지"
절, `archive/question-resolved.md`로 이전됨).

---
Sources (MCP 리서치): [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server), [How to Connect Claude Code to Roblox Studio — Clauder Navi](https://www.clauder-navi.com/en/claude-roblox-studio)
