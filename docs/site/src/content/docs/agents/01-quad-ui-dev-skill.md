---
title: "01. 에이전트 스킬 quad-ui-dev 설치와 사용"
description: "AI 코딩 에이전트(Claude Code 등)가 quad 코드를 정확하게 생성하도록 돕는 스킬 — 무엇이 들었고, 어떻게 설치하고, 어떻게 쓰나"
---
> **대상 독자**: Claude Code 같은 AI 코딩 에이전트에게 quad UI 코드를 맡기려는 개발자
> **다루는 것**: 레포의 `docs/skills/quad-ui-dev/` 폴더 — 설치(Claude Code), 호출, 다른 에이전트에 붙이는 법, 갱신
> **범위**: 스킬 본문은 영문이고 이 사이트에 싣지 않습니다. 에이전트가 읽는 파일이라 레포에서 그대로 가져다 씁니다.

---

## 1. 무엇이 들어 있나

quad 레포의 `docs/skills/quad-ui-dev/`는 Claude Code의 스킬 형식(`SKILL.md` + 참고 파일)을 따르는 폴더입니다. 파일 넷이 전부이고, 전부 영문입니다(에이전트가 읽는 텍스트라 토큰을 아끼기 위한 선택입니다).

| 파일 | 내용 |
|---|---|
| `SKILL.md` | 진입점. `Source`/`State` 온톨로지, `Slot` 목록, `Modifier` 우선순위, `Claim`, `Tween`/`Animate`, nil 구멍 방어 같은 **규칙을 압축한 요약**과, 막히면 이 사이트의 실제 페이지를 먼저 가져오라는 지시 |
| `references/code-recipes.md` | mock 백엔드에서 실행을 확인한 코드 레시피 |
| `references/rules-and-invariants.md` | 소스 그대로의 에러 문자열 → 원인과 처방 |
| `references/v1-migration.md` | quad v1 코드 이관 — 대응표, 없어진 기능, strict 블로커 |

스킬은 **압축 요약**이고 정본은 이 사이트입니다. 스킬 자체가 "이 파일에 없는 것은 문서 페이지를 가져와 확인하고, 없는 심볼은 지어내지 말고 소스를 grep하라"고 에이전트에게 지시합니다. 그러니 에이전트가 웹 페이지를 가져올 수 있는 환경일수록 정확해집니다.

---

## 2. Claude Code에 설치하기

Claude Code는 프로젝트의 `.claude/skills/<이름>/SKILL.md`를 스킬로 읽습니다. 폴더를 **통째로** 복사하면 됩니다 — `SKILL.md`가 `references/…`를 상대 경로로 가리키므로 파일 하나만 옮기면 참고 파일을 못 찾습니다.

```sh
# 쓰고 있는 quad 버전의 태그로 받습니다(예: 3.2.0). 태그는 릴리즈마다 붙습니다.
git clone --depth 1 --branch 3.2.0 https://github.com/qwreey/quad /tmp/quad
mkdir -p .claude/skills
cp -r /tmp/quad/docs/skills/quad-ui-dev .claude/skills/quad-ui-dev
rm -rf /tmp/quad
```

프로젝트가 아니라 내 계정 전체에 두고 싶으면 `.claude/skills/` 대신 `~/.claude/skills/`에 같은 폴더를 놓습니다. 결과는 어느 쪽이든 아래 모양입니다.

```text
.claude/skills/quad-ui-dev/
├── SKILL.md
└── references/
    ├── code-recipes.md
    ├── rules-and-invariants.md
    └── v1-migration.md
```

복사한 폴더는 프로젝트 저장소에 커밋해 두는 편이 좋습니다. 팀원과 CI의 에이전트가 같은 규칙을 봅니다.

---

## 3. 쓰기

Claude Code는 `SKILL.md` 머리의 `description`을 보고 요청이 맞을 때 스킬을 **스스로** 불러옵니다 — "이 화면을 quad로 짜 줘"처럼 quad UI 코드를 요구하면 따로 시키지 않아도 됩니다. 직접 지정하려면 프롬프트에 `/quad-ui-dev`를 적습니다.

에이전트가 낸 코드는 두 가지로 확인합니다. 첫째, [시작하기 00](/getting-started/00-installation/) §2의 타입 검사 플래그 넷을 켠 `--!strict` 검사. 스킬이 strict를 전제로 코드를 내므로 여기서 걸리는 것은 대개 스킬이 모르는 최신 표면입니다. 둘째, 실제 실행 — 특히 [실전 레시피 09](/how-to/09-debugging-and-troubleshooting/)의 함정 여섯은 에이전트도 그대로 밟습니다. 에러 문구가 나오면 그 문구를 에이전트에게 그대로 돌려주면 됩니다. `references/rules-and-invariants.md`가 문구 단위로 처방을 갖고 있습니다.

---

## 4. 다른 에이전트에 붙이기

Cursor, Codex, Gemini CLI처럼 스킬 폴더 형식을 모르는 도구에서는 네 파일을 **규칙 파일이나 시스템 프롬프트에 그대로** 넣으면 됩니다. `SKILL.md`부터 넣고, 참고 파일 셋은 필요한 것만 이어 붙입니다(v1 코드를 옮기는 게 아니면 `v1-migration.md`는 빼도 됩니다). 내용은 평범한 마크다운이라 형식을 고칠 것이 없고, 유일하게 손볼 곳은 `references/…` 상대 경로 언급을 붙여 넣은 위치에 맞게 바꾸는 것뿐입니다.

---

## 5. 갱신하기

스킬 파일은 quad 레포와 같이 버전 관리됩니다. quad 패키지 버전을 올리면 같은 태그에서 스킬 폴더를 다시 복사하세요 — 2절의 명령에서 태그만 바꾸면 됩니다. 어떤 표면이 바뀌었는지는 [변경 이력](/changelog/)이 소스입니다.
