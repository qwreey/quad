# HUMAN_TODO — 사용자(사람)만 할 수 있는 일

에이전트가 못 하거나(로컬 GUI 조작, 외부 계정/기기 필요) 사용자의 결정이 필요해서
멈춰둔 것만 여기 모음. 설계 질문은 대체로 `.claude/question.md`에 따로 있고 디폴트를
잡아둔 채 진행 중이라 급하지 않음 — **단 2026-08-13부터는 예외가 생겨 아래 4번에
올렸었음**(0-Z) — **[2026-08-13 열네 번째 세션] 그 0-Z도 해소되어 지금은
사람이 결정해야 M0가 열리는 항목이 없음**(0-Y는 열세 번째 세션에 해소).

## 1. Roblox Studio에 MCP로 연결 (테스트 자동화용)

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
하거나 대기함. 이 안전 원칙은 `CLAUDE.md`에도 적어둠.

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

## 2. 자율 작업 루프/스케줄 설정

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

## 5. Studio 전용 스파이크 `10` 마저 돌리기 (사람만 가능)

`.claude/luau-test/`는 2026-08-13에 첫 실측이 돌아 **런타임 12개 전원
통과**했으나, `10-roblox-studio-checks.server.luau`만 **Studio 전용이라
`luau` CLI로 못 돌림**. A 섹션 앞부분(ClassName 신호 미발화, Destroy 시
`Connected` 즉시 전환)은 사용자가 자작 스크립트로 이미 확인
(`.claude/audit/gcconn-trick-verification.md`).

**[2026-08-14 다섯 번째 세션] 지금 바로 돌릴 수 있는 상태가 아님 — 먼저
에이전트가 A 섹션을 재작성해야 함.** `bindLifetime`/`canExecute`/
`unbindLifetime` 재정정으로 A가 폐기된 모델(`canBound`, `bindLifetime`의
`.Subscribed` 세팅, 2-인자 `canExecute`)을 검증 중이라 파일이
`.claude/luau-test/rewrite-required/`로 옮겨졌음. **남은 확인거리**는
이중 바인딩 게이트(이제 `canExecute` 하나)와 unbind/Destroy 후 재바인딩
허용, `value` 쪽에 복사된 gcconn만으로의 생존 판정, Instance userdata
동일성, 그리고 B(Attribute의 Instance 참조 타입)/C(CollectionService
태그 왕복) — 목록은 `.claude/audit/gcconn-trick-verification.md`의
"아직 확인 안 된 것"이 소스. GC 강제 트리거가 필요하면
`.claude/luau-test/not-run/gc-trigger-helper.server.luau` 참고. 위
1번(MCP 연결)이 되면 에이전트가 대신 돌릴 수도 있음.

## 6. **[2026-08-13 신설, 안 막음]** 에디터의 Luau 솔버 설정 확인

`luau-analyze` CLI는 **새 솔버가 기본값**이지만 에디터가 쓰는
`luau-lsp`는 **옛 솔버가 기본값**(`LuauSolverV2=false`)이라 **같은 코드에
다른 진단이 나옵니다** — 이번 세션에 실제로 겪은 혼선의 원인이었음
(CLI는 클린인데 에디터엔 빨간 줄).

옛 솔버는 quad의 `Compute` 시그니처 패턴 자체를 선언 시점에 거부하므로
사실상 새 솔버 외에 선택지가 없어 보이지만, **실제 사용하시는 에디터
환경에서 확인이 필요**합니다. VSCode의 "Luau Language Server" 확장이라면
워크스페이스 `.vscode/settings.json`에:

```json
{ "luau-lsp.fflags.enableNewSolver": true }
```

M0 착수 시점에 확인하면 되고 지금 막고 있진 않음. 배경은
`.claude/base/typing-limits.md` 8번, 실측은
`.claude/audit/type-recursion-issue/REPORT.md` 5절.

## 7. **[2026-08-14 신설]** 워크트리 `debounce-throttle-plan` 정리 여부

Debounce/Throttle 작업에 쓴 워크트리가 **의도적으로 남아 있습니다**(사용자
지시로 클린업 없이 나옴):

```
경로:   .claude/worktrees/debounce-throttle-plan
브랜치: worktree-debounce-throttle-plan (HEAD 5518055)
```

**필요한 변경은 전부 `main`에 이식 완료**(`623c931`)입니다 — 워크트리에만
있는 결정은 없습니다. 다만 워크트리는 **분할 이전(`10cd31b`) 구조 기준**이라
`bind-system-plan.md`에 전파 모델이 있는 등 경로가 다르니, **그 트리를 직접
참조하거나 머지하지 마세요.** 남겨둔 이유는 이식 과정을 나중에 대조해볼 수
있게 하기 위함입니다.

지우려면:

```
git worktree remove .claude/worktrees/debounce-throttle-plan
git branch -D worktree-debounce-throttle-plan
```

**언제 지워도 무방** — 지워도 `main`에서 잃는 정보는 없습니다.

## 3. `.claude/question.md`의 **나머지** 항목 검토 (급하지 않음)

디자인 결정 중 Lua/Roblox 엔진에 대한 깊은 경험이 필요한 것들은 합리적 기본값으로
진행하면서 `.claude/question.md`에 모아두는 중. 깨어있을 때 훑어보고 기본값이
마음에 안 드는 것만 답해주면 됨 — **[2026-08-13 열네 번째 세션 기준]
M0 착수를 막는 항목은 하나도 없음**(남은 건 0-W `Ref` 이중 배치, M4 구현
세부만 막음 — 0-B `dispose` 시그니처/범위는 2026-08-14 열 번째 세션에
해소돼 `archive/question-resolved.md`로 이전됨).

---
Sources (MCP 리서치): [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server), [How to Connect Claude Code to Roblox Studio — Clauder Navi](https://www.clauder-navi.com/en/claude-roblox-studio)
