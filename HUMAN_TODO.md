# HUMAN_TODO — 사용자(사람)만 할 수 있는 일

에이전트가 못 하거나(로컬 GUI 조작, 외부 계정/기기 필요) 사용자의 결정이 필요해서
멈춰둔 것만 여기 모음. 설계 질문(디폴트 이미 잡아두고 진행 중, 급하지 않음)은
`.claude/question.md`에 따로 있음 — 그건 안 봐도 진행에 지장 없고, 이 문서는 실제로
사람이 뭔가 눌러/타이핑해야 풀리는 것만 담음.

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

## 3. `.claude/question.md` 검토 (급하지 않음)

디자인 결정 중 Lua/Roblox 엔진에 대한 깊은 경험이 필요한 것들은 합리적 기본값으로
진행하면서 `.claude/question.md`에 모아두는 중. 깨어있을 때 훑어보고 기본값이
마음에 안 드는 것만 답해주면 됨 — 막고 있는 항목은 없음.

---
Sources (MCP 리서치): [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server), [How to Connect Claude Code to Roblox Studio — Clauder Navi](https://www.clauder-navi.com/en/claude-roblox-studio)
