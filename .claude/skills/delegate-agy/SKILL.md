---
name: delegate-agy
description: quad에서 다른 모델 계열(Gemini 3.8 Flash, Antigravity CLI `agy`)에게 근본 원인 찾기·현재 틀에서 튀어오르는 창의적 검토·같은 메커니즘을 공유하는 발견 묶기·이름 짓기의 객관성 검토를 맡길 때 쓴다. 격리 worktree에서 별도 uid로 돌리고 보고서를 받아 메인이 판정한다.
---

# delegate-agy — Gemini에게 다른 시각을 맡기기

## 왜 쓰나 (사용자, 2026-10-02)

sonnet·opus는 같은 베이스 모델에서 증류된 계열이라 어휘·선택 편향을 공유한다. 깨끗한 맥락에서도 "캐비엇", "팔" 같은 어휘가 따라온다. 그래서 "외부자·내부자 시선"으로 띄워도 모델 단위 경향성은 좁혀지지 않는다. Gemini는 이 레포에서 이미 다른 시각을 증명했다.
- 다패스 검증이 못 찾던 nil 구멍 문제를 대거 찾았다. 전부 사실은 아니었지만, 제기한 문제는 진짜였다.
- Context 설계는 Gemini 제안을 거의 그대로 받았다.
- `q.Out`이 없다는 것을 짚었고, 그 메커니즘도 받아들였다.
- `SetIfChanged`로 이어진 diff-and-set 논의도 거기서 시작했다.

사용자 평가는 이렇다. Gemini는 맥락 민감도가 높고 창의적이며, 정해진 틀을 넘어 근본 원인으로 튀어오를 수 있다. 대신 추론이 틀리거나 지어낸 말이 섞일 수 있고, 조작 실수가 Anthropic 모델보다 **훨씬** 잦다. 그러니 판정은 늘 메인이 한다.

## 언제 쓰나

- **근본 원인 찾기**: 원장의 여러 문항이 같은 메커니즘에서 나온 것 같을 때, 뿌리를 위쪽에서 찾게 한다.
- **현재 시각에서 튀어오르기**: Anthropic 계열 감사가 소진돼 가는 각도에서 다른 틀로 보게 한다. "이미 닫힌 원장인가 / 정의와 맞는 행동인가"처럼 시각이 여럿인 검토에도 쓴다.
- **발견 묶기**: 따로 올라온 문항들을 합칠 수 있는지, 더 큰 문제의 사례인지 보게 한다.
- **이름·어휘의 객관성**: sonnet 외부자·내부자 검토와 함께, 또는 대신 쓴다.

쓰지 말 것이 셋이다.
- 결정을 맡기는 것.
- 메인 레포에 반영하는 것. 결과는 늘 메인이 검증하고, 메인이 직접 고친다.
- 결정 이력이 필요한 판정을 맥락 없이 맡기는 것. 필요한 이력은 프롬프트에 직접 넣는다.

## 실행

1. 과제 프롬프트를 스크래치에 쓴다. 한국어든 영어든 된다. `agy-delegate.sh`가 앞에 작업 환경 규칙을 자동으로 붙인다. 붙는 규칙은 다섯이다.
   - worktree 밖 쓰기 금지
   - git 커밋·push·stash 금지
   - `ulimit` 붙인 테스트 실행
   - `AGY_REPORT.md`에 한국어 보고, 실측/추정 표시
   - 제안은 결정이 아님

   과제 쪽에는 이렇게 쓴다.
   - 읽을 파일을 경로로 준다. agy는 이 레포의 `CLAUDE.md` 계열을 자동으로 싣지 않는다. 판정 기준이 필요하면 `.claude/audit/round14-principle-audit/PRINCIPLES.md`를 지정한다.
   - 무엇에서 튀어오르기를 원하는지 명시한다. 예: "이 다섯 문항을 개별 결함으로 보지 말고, 공통 뿌리가 무엇인지 위에서 찾아라."
   - 반증 가능한 근거(파일:줄, 실행 출력)를 요구한다.
2. 백그라운드로 돌린다. Bash `run_in_background`를 쓰고, 기본 모델은 `gemini-3.8-flash-high`다.

   ```
   .claude/tools/agy-delegate.sh run <이름> <프롬프트 파일> [--model gemini-3.8-flash-high] [--timeout 3600]
   ```

   사용자 판단으로 agy 토큰 한도는 널널하니, 쓰고 싶은 구간에 한둘 띄워도 된다. 동시 실행은 이름만 다르면 된다.
3. 끝나면 셋을 읽는다.
   - `/code/Projects/quad-agy/<이름>/AGY_REPORT.md`
   - `.agy/guard.txt`: exit code, 메인 레포 변경 여부, worktree 변경 목록
   - 필요하면 `.agy/stdout.txt`

   worktree에서 파일을 고쳤다면 `git -c safe.directory=<wt> -C <wt> diff`로 본다.
4. **모든 주장을 메인이 직접 확인한다.** 2026-10-02 연결 확인에서도 코드를 인용하며 들여쓰기를 틀리게 옮겼다. 확인된 발견만 원장에 일반 규약대로 올린다. 새 필드·이름·메커니즘이면 사용자 문항으로 올린다. 이 규약은 `conventions.md`의 "`/code-review`(그리고 메인 세션 자신)가 내놓는" 항목이다. 사용자에게 보고할 때는 Gemini의 발견이라는 것과 메인의 검증 결과를 갈라 적는다.
5. 다 읽었으면 지운다: `.claude/tools/agy-delegate.sh remove <이름>`. `list`로 남은 것을 본다.

## 격리 (2026-10-02 실측)

- `agy --sandbox`는 cwd 밖 쓰기를 막지 **않았다**. `unshare -m`은 이 컨테이너에서 권한이 없다.
- 그래서 스크립트는 agy를 uid 61000으로 `setpriv` 실행한다.
  - worktree와 `.git/worktrees/<이름>`만 그 uid 소유다.
  - 메인 작업 트리와 `.git/objects`에는 쓸 수 없다(실측: Permission denied).
  - 그래서 커밋이 안 되고, 새로 push할 것도 생기지 않는다. 덧붙여 pre-push 훅이 거부한다.
- HOME은 `/code/Projects/quad-agy/.home`이다. 실행마다 `/code/.gemini`의 OAuth를 새로 복사한다.
- 같은 uid로 worktree 안 `./scripts/test.sh`는 exit 0이다. 스크립트가 `pesde install`을 먼저 돌리고, relink는 worktree 경로를 가리킨다.
- 실행 전후 메인 레포의 HEAD와 status를 비교해 `guard.txt`에 적는다. 메인 세션이 그 사이 작업했다면 "CHANGED"가 뜨는 게 정상이다.
