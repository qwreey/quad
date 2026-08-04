# CLAUDE.md

## 언어/모델 관례 (기존 메모, 유지)

사용자는 한국 유저임을 유의해. 사용자가 보게 될 것은 한국어로 띄워주는 게
좋아. 너가 보는 것들(코드 주석 등)은 원하는 언어여도 되는 것(가장 성능이 좋을
영어를 쓰든 그래도 됨, 예를 들어 이 CLAUDE.md도 영어여도 무방하지만 지금은
한국어로 유지). 사용자가 검토해야 하는 것(plan, backlog 등)은 한국어로 써.
코드 안 주석은 공식성을 유지하기 위해 굳이 한국어일 필요 없음, 영어 가능.

또 토큰 맥싱에 유의해 — 아주 작은 테스크라 충분히 작은 모델이 쓸 수 있으면
haiku, 일반 작업은 sonnet. 특히 소스코드를 많이 읽어야 하는 리서치는 메인
컨텍스트를 부패시키니 Agent로 위임할 것(아래 "작업 방식" 참고).

## 이 프로젝트가 뭔지

Roblox 엔진에서 동작하는 DOMless UI 렌더러 **quad**를 처음부터 다시 짜는
프로젝트. 목표는 개별 프로덕트가 아니라 **라이브러리**로서의 코드 퀄리티와
지속 가능성 — 빠른 이터레이션보다 정확성/설계 정합성이 우선. 작업 기간은
길게 잡음.

**지금은 설계/계획 단계이고 구현은 아직 시작 전** — 저장소 루트에 실제 소스
코드(`src/` 등)가 없음. 2026-08-03에 확정됐던 핵심 아키텍처 결정들(Store
책임 분리, `process`/`retract` 디스패치 모델, Signal 미채택, Ref 역할, Store
문법 인체공학, 트윈 기본 오버라이드, Slot 재마운트 에러 처리, 순수성→이식성
재정의 등)은 2026-08-04에 `AskUserQuestion`으로 하나씩 재검증까지 마쳐서
확정 상태 — `.claude/question.md`의 "확정됨" 절 참고. 이전에 시도했다 폐기한
v2 재작성 시도(`.claude/initreq/quad2-try`)도 리서치 완료 — OOP 상속/커스텀
파서/Slot 스텁은 확인된 죽은 접근이라 반복 금지, `Pipe`의 copy-on-write
절충안은 한때 살려볼 후보였으나 **2026-08-04에 사실상 폐기로 재평가**됨(State
자체가 `state(state)`로 분기하는 쪽으로 대체).

**지금 유일하게 결론 안 난 핵심 설계 이슈는 Store/State/Source 온톨로지**
— 검증 라운드 중 "State 프리미티브는 안 만든다"던 기존 결정이 틀렸다는 게
드러나며 새로 열림. `.claude/research/bind-system-plan.md`의 "Store/State/
Source 온톨로지" 절, `.claude/question.md`의 "최우선 새 열린 질문" 절 참고 —
아래 "지금 할 일" 1번이 다음 세션이 여기서부터 시작해야 함을 명시.

## 계획 문서 구조

`.claude/README.md`가 색인. 요약:
- `.claude/base/` — 확정된 아키텍처/컨텍스트, plan/done 개념 없음. 먼저
  `.claude/base/architecture.md`를 읽을 것.
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의.
- `.claude/qa-request/`, `.claude/archive/`, `.claude/feedback/` — 구현
  시작되면 쓰기 시작함, 지금은 비어있음.
- `.claude/initreq/` — 클론해둔 참고 레포(quad v1, Fusion, Vide, rbvm, tbox,
  code-docker) + 원본 요청. **읽기 전용, `.gitignore`로 커밋 제외됨** — 내용을
  다른 곳으로 옮기지 말고 항상 원본 그대로 둘 것. 리서치가 더 필요하면 이
  폴더를 다시 파고들 것.
- `.claude/question.md` — 사용자가 답해야 할 질문 전체 취합(우선순위순).
- 루트 `HUMAN_TODO.md` — 사람만 할 수 있는 일(로컬 GUI 조작, 스케줄/루프
  설정 등).

## 작업 방식

- **소스코드를 많이 읽어야 하는 리서치는 Agent(Explore)로 위임** — 메인
  컨텍스트 보호. 이미 완료된 v1/rbvm/tbox/Fusion/Vide 리서치 결과는
  `.claude/base/`에 정리되어 있으니 중복 조사하지 말고 먼저 그걸 볼 것.
- **병렬화 가능한 작업은 Agent 여러 개를 한 메시지에 동시 호출.** 서로 독립적인
  파일/주제를 다루는 리서치나 구현 조사가 여기 해당.
- **크리티컬한 설계 결정은 구현으로 밀어붙이지 말고 plan을 research/에 남긴 채
  연기.** 사용자는 Lua/Roblox 엔진을 깊이 아는 사람 — 근거와 선택지를 문서에
  정리해두면 사용자가 깨어있을 때 훑어보고 답해줄 것. `.claude/question.md`에
  반드시 반영.
- **작업이 끝나면(또는 방향이 바뀌면) 항상 자기 문서화** — 완료된 걸 다시
  조사하게 되는 재작업을 막기 위함. `.claude/base/`로 승격, `.claude/qa-request/`로
  이동, 또는 문서 자체를 갱신. code-docker/webmanager의 `.claude/` 관리 방식이
  좋은 예시(`.claude/initreq/code-docker/webmanager/.claude/README.md` 참고).
- **Roblox Studio MCP 연결 시 주의**: Studio는 잘 죽는 편 — 죽었을 때 살리려고
  위험한 명령을 반복 시도하지 말 것. 그런 상황이면 MCP 없이 할 수 있는 작업만
  하거나 대기. 연결 방법은 `HUMAN_TODO.md` 1번 항목 참고(사용자가 Studio에서
  베타 기능을 켜줘야 함).
- **`SAFETY.md` 반드시 지킬 것** — (1) GitHub 등 외부 git 호스팅에 이 레포를
  push하지 말 것, 모델의 git 작업 공간은 사용자가 별도로 마련해줄 제한 계정
  (예: git.qwreey.moe) 전용으로 국한됨 — 그 계정/원격이 설정되기 전까지는
  **로컬 git 커밋까지만** 하고 원격 추가/푸시는 하지 말 것. (2) Roblox Studio는
  메인 계정이 아닌 별도 계정으로만 사용 — 로그인 계정 전환을 사용자가 안 해줬다면
  Studio 관련 작업(MCP 연결 등)을 진행하지 말고 대기.

## 지금 할 일 (우선순위순)

1. **[다음 세션 최우선] Store/State/Source 온톨로지 설계.** 2026-08-04 검증
   라운드 중 "State 프리미티브는 안 만든다"는 이전 결정이 틀렸다는 게
   밝혀지면서 새로 터져나온 핵심 설계 이슈 — Store=source 집합체, State=
   source를 감싸는 조합 가능한 캐시(`state(state)`로 분기), `:Compute`
   캐싱/무효화 전략, Luau 타입 시스템에서 커링 호출의 `state<T>` 추론 문제
   등이 전부 미정. `.claude/research/bind-system-plan.md`의 "Store/State/
   Source 온톨로지" 절에 지금까지 나온 내용이 정리되어 있음 — 이어서 설계를
   구체화할 것. `.claude/question.md`의 "최우선 새 열린 질문" 절도 함께 참고.
2. 위 온톨로지가 어느 정도 정리되면 `research/bind-system-plan.md`/
   `research/module-lifecycle-plan.md`를 `base/`로 승격하고,
   `base/architecture.md`에 "구현 착수" 섹션을 추가해 실제 소스 트리 구조
   (어느 서브패키지가 뭘 갖는지)를 확정 — 이 시점부터 `qa-request/`/`archive/`
   폴더가 실제로 쓰이기 시작함.
3. 남은 세부 시그니처(`CreatedRef` 정확한 이름, 인스턴스 생성/이벤트 네이밍
   인체공학, `RobloxFactory`류 팩토리 중복 호출 가드)는 온톨로지 설계와
   자연스럽게 같이 확정 가능.
4. `research/purity-and-effects-plan.md`(특히 "state 옵저빙 결과로 slot을
   조작할 때 생존 여부 확인" 열린 질문), `research/existing-instance-bind-plan.md`는
   급하지 않음 — 스코프 논의만 필요, 구현 착수를 막지 않음.
5. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).

## 인수인계 메모 (2026-08-04 세션 종료 시점)

2026-08-03에 확정됐다고 표시된 결정 전체(architecture.md 14개 + lifecycle-
pattern/store-semantics/bind-system-plan/module-lifecycle-plan/slot-plan/
tween-plan)를 `AskUserQuestion`으로 하나씩 예/아니오 검증 완료 — 상세는
`.claude/question.md`의 "2026-08-04 검증 라운드 완료" 절. 대부분 그대로
확인됐지만, 검증 과정에서 사용자가 실시간으로 설계를 더 전개하면서 **"State
프리미티브는 안 만든다"는 기존 결정이 틀렸다는 게 밝혀짐** — Store/State/
Source 온톨로지 전체가 이번 세션에서 새로 열린 가장 중요한 설계 스레드로
떠올랐고, 아직 결론이 안 났음(위 "지금 할 일" 1번). 그 외 자잘한 정정들(Slot
retract=폐기 확정, Pipe COW 후보 폐기 등)은 각 문서에 바로 반영해둠 — 재조사
불필요.

이전 세션(2026-08-03) 종료 시점 메모: `.claude/` 전체 스캐폴드 + 대부분의
핵심 아키텍처 결정을 완료, 로컬 git 저장소 초기화+첫 커밋(원격 없음,
`SAFETY.md` 참고 — 원격은 사용자가 제한 계정을 마련해줘야 추가 가능).
