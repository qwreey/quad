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
코드(`src/` 등)가 없음. 핵심 아키텍처(Store 책임 분리, `process`/`retract`
디스패치 모델, Store/State/Source 온톨로지, 소스 트리 구조, Modifier 메커니즘,
컴포넌트=플레인 함수)는 전부 `.claude/base/`에 문서로 확정돼 있음 — 먼저
`.claude/base/architecture.md`를 읽을 것. **단, "핵심 설계 질문이 더 이상
없다"는 뜻은 아님** — 컴포넌트화(특히 modifier/Ref가 컴포넌트 경계를 어떻게
통과하는지)는 사용자가 직접 "지금 quad에서 가장 문제되는 부분"으로 지목한
채 아직 열려있음, 아래 "지금 할 일" 참고.

이전에 시도했다 폐기한 v2 재작성 시도(`.claude/initreq/quad2-try`)도 리서치
완료 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` copy-on-write 절충안은 확인된
죽은 접근이라 반복 조사 금지(`base/bind-system-plan.md` 참고).

## 계획 문서 구조

`.claude/README.md`가 색인. 요약:
- `.claude/base/` — 확정된 아키텍처/컨텍스트, plan/done 개념 없음. 먼저
  `.claude/base/architecture.md`를 읽을 것.
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의. 지금은
  `tween-plan.md`(세부 옵션만 남음), `existing-instance-bind-plan.md`(급하지
  않음), `component-composition-plan.md`(**사용자가 최우선으로 지목한 열린
  주제**) 세 개뿐.
- `.claude/qa-request/`, `.claude/archive/`, `.claude/feedback/` — 구현
  시작되면 쓰기 시작함, 지금은 비어있음.
- `.claude/initreq/` — 클론해둔 참고 레포(quad v1, Fusion, Vide, rbvm, tbox,
  code-docker) + PA님 실 코드(`artworks/`) + 원본 요청. **읽기 전용,
  `.gitignore`로 커밋 제외됨** — 내용을 다른 곳으로 옮기지 말고 항상 원본
  그대로 둘 것. 리서치가 더 필요하면 이 폴더를 다시 파고들 것.
- `.claude/question.md` — 사용자가 답해야 할 질문 전체 취합(우선순위순).
- 루트 `HUMAN_TODO.md` — 사람만 할 수 있는 일(로컬 GUI 조작, 스케줄/루프
  설정 등).

## 작업 방식

- **소스코드를 많이 읽어야 하는 리서치는 Agent(Explore)로 위임** — 메인
  컨텍스트 보호. 이미 완료된 v1/rbvm/tbox/Fusion/Vide 리서치 결과는
  `.claude/base/`에 정리되어 있으니 중복 조사하지 말고 먼저 그걸 볼 것.
- **병렬화 가능한 작업은 Agent 여러 개를 한 메시지에 동시 호출.** 서로 독립적인
  파일/주제를 다루는 리서치나 구현 조사, 또는 서로 다른 문서 파일을 고치는
  문서 정리 작업이 여기 해당(단, 같은 파일을 동시에 고치는 에이전트를 병렬로
  띄우지 말 것 — 충돌함).
- **크리티컬한 설계 결정은 구현으로 밀어붙이지 말고 plan을 research/에 남긴 채
  연기.** 사용자는 Lua/Roblox 엔진을 깊이 아는 사람 — 근거와 선택지를 문서에
  정리해두면 사용자가 깨어있을 때 훑어보고 답해줄 것. `.claude/question.md`에
  반드시 반영.
- **작업이 끝나면(또는 방향이 바뀌면) 항상 자기 문서화** — 완료된 걸 다시
  조사하게 되는 재작업을 막기 위함. `.claude/base/`로 승격, `.claude/qa-request/`로
  이동, 또는 문서 자체를 갱신. code-docker/webmanager의 `.claude/` 관리 방식이
  좋은 예시(`.claude/initreq/code-docker/webmanager/.claude/README.md` 참고).
- **문서가 쌓이면서 모순/중복/stale 마커가 생기기 쉬움 — 주기적으로 감사할
  것.** 2026-08-04 세션에 실제로 전체 `.claude/` 코퍼스에서 이런 문제가
  다수 발견되어 정리함(아래 "최근 세션 요약" 참고) — 여러 라운드에 걸쳐
  같은 문서를 계속 고치다 보면 "정정됨" 표시가 원래 문장에 안 반영되고
  방치되는 패턴이 반복되니, 큰 방향 전환이 있을 때마다 관련 문서 전체를
  훑어 확인할 것.
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

1. **컴포넌트화 논의 계속 — 사용자가 직접 "가장 문제되는 부분"으로 지목.**
   `research/component-composition-plan.md` 참고. 핵심 골격(컴포넌트=플레인
   함수, State/Source 읽기·쓰기 경계, `StoreSource` 프록시)과 Modifier
   메커니즘 자체(`base/modifier-plan.md`, 완전 확정)는 수렴됨 — 남은 건
   **modifier/Ref가 컴포넌트 경계(특히 다중 루트)를 어떻게 통과하는가**라는
   진짜 설계 질문(이름 문제가 아님). 다음 세션에서 이걸 이어서 파고들 것.
2. **실제 스캐폴딩.** 소스 트리 구조는 문서로 이미 확정됨(`base/
   architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절) — `quad-base/`,
   `quad-roblox/` 폴더, 각각의 `wally.toml`, 루트 `default.project.json`,
   `.luaurc`를 만들 것. 1번의 컴포넌트 경계 논의가 `DI`/`Modifier` 모듈
   설계에 영향을 주므로, 그 결론이 안 나온 상태에서도 나머지 구조(Store/
   State/Source, 디스패치 엔진, Slot)는 그대로 스캐폴딩 가능 — 막을 필요
   없음(`architecture.md`에도 명시). 이 시점부터 `qa-request/`/`archive/`
   폴더가 실제로 쓰이기 시작함.
3. **용어 정리 — 사용자가 별도로 요청, 진행 중.** "register"(v1) 같이
   부정확한 이름들을 전체적으로 재검토하자는 요청 — 1차 제안 완료(우선순위
   순: `State`가 React/Vue식 "쓸 수 있는 로컬 상태"라는 통상 의미와 반대라
   가장 위험, `DI`가 Dependency Injection 축약어와 충돌, `PerInstanceState`가
   핵심 프리미티브 `State`와 이름 충돌 — 세부는 `.claude/question.md` 참고),
   사용자와 같이 계속 논의 필요.
4. `research/existing-instance-bind-plan.md`는 급하지 않음 — 스코프 논의만
   필요, 구현 착수를 막지 않음.
5. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).

## 최근 세션 요약 (2026-08-04, 6차 라운드 이후)

**6차 라운드**: 남아있던 "급하지 않음" 질문 두 개 해소 — 태그 네임스페이싱
충돌은 컴포넌트 단위로는 Ref가 대신 해결해줘서 심각하게 안 봄(`architecture.md`
5번), Store가 Store를 담는 경우는 없음으로 확정(Store는 Source에 준하는
"시작점"이라 다른 반응형 값에 자동 연결되지 않음, `bind-system-plan.md`).

**그 이후 채팅에서 세 가지 큰 스레드가 새로 열림/정리됨**:
- **Modifier 메커니즘 전체 확정** — 런타임 pluggable 핸들러가 아니라 정적
  merge, immutable+`table.clone` 기반 체이닝, 필드가 State일 수도 있는
  경우의 setter/getter 동작까지 전부 확정(`base/modifier-plan.md`, 새로
  base 승격). 이 논의에서 "관측해야 실체화된다"는 프로젝트 전역 원칙도
  명문화(`bind-system-plan.md`).
- **컴포넌트화 논의 시작, 아직 미완** — v1의 `Class.Extend()` 자동-store
  매직은 폐기하고 React식으로 값을 명시적으로 전달하는 방향으로 수렴,
  `StoreSource`(Source를 인터페이스+구현체로 보고 Store 키에서 얇은
  프록시로 얻는 것) 아이디어까지 나왔지만 modifier/Ref의 컴포넌트 경계
  통과 방식은 미해결(`research/component-composition-plan.md`, 위 "지금
  할 일" 1번).
- **문서 전체 감사 및 정리** — `.claude/` 코퍼스 전체(약 15개 문서)를
  서브에이전트로 감사해 여러 라운드에 걸쳐 쌓인 모순/중복/stale 마커를
  대거 발견하고 수정(예: 이벤트 dot-access 확정 여부가 문서 내에서 서로
  모순, 이미 해소된 질문이 "미해결"로 방치, 존재하지 않는 문서/섹션을
  가리키는 끊긴 참조 다수, `TagService`/`CollectionService` 혼용 등).
  `research/purity-and-effects-plan.md`도 내용이 이미 확정 상태라 `base/`로
  승격. **이 CLAUDE.md 자체도 이번에 오래된 라운드별 인수인계 메모 3개를
  이 요약 하나로 통합하며 정리함** — 라운드별 상세 히스토리가 필요하면
  git log와 각 `base/`/`research/` 문서 안의 라운드 표시(예: "2026-08-04
  3차 라운드")를 참고할 것, 여기서 전부 반복하지 않음.

용어 정리 제안 진행 중인 점은 위 "지금 할 일" 3번 참고.
