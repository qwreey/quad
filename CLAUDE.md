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
컴포넌트=플레인 함수, 컴포넌트 경계 modifier/Ref 전달)는 전부 `.claude/base/`에
문서로 확정돼 있음 — 먼저 `.claude/base/architecture.md`를 읽을 것. 사용자가
직접 "지금 quad에서 가장 문제되는 부분"으로 지목했던 컴포넌트화(특히
modifier/Ref의 컴포넌트 경계 통과 방식) 논의도 2026-08-04 세션에서 수렴
완료(`base/component-composition-plan.md`) — 남은 핵심 설계 질문은 없고,
용어 정리(진행 중)와 실제 스캐폴딩만 남음, 아래 "지금 할 일" 참고.

이전에 시도했다 폐기한 v2 재작성 시도(`.claude/initreq/quad2-try`)도 리서치
완료 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` copy-on-write 절충안은 확인된
죽은 접근이라 반복 조사 금지(`base/bind-system-plan.md` 참고).

## 계획 문서 구조

`.claude/README.md`가 색인. 요약:
- `.claude/base/` — 확정된 아키텍처/컨텍스트, plan/done 개념 없음. 먼저
  `.claude/base/architecture.md`를 읽을 것.
- `.claude/reference/` — **[2026-08-07 신설]** base처럼 확정된 건 아니지만
  base 문서가 근거로 인용하는 온디맨드 참고 자료(v1 내부 동작 스냅샷,
  Fusion/Vide 비교 리서치) — 항상 읽을 필요는 없고 인용될 때만 열어볼 것.
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의.
  `tween-plan.md`/`existing-instance-bind-plan.md`/`debug-tooling-plan.md`/
  `documentation-plan.md`/`documentation-content-map.md`/
  `framework-comparison-findings.md`/`additional-primitives-plan.md`(2026-08-09
  세 번째 세션에 마지막 열린 항목까지 전부 해소, 이제 배경 자료용)/
  `pre-implementation-audit.md`/`v1-compat-plan.md`
  — 전부 후순위(급한 건 `tween-plan.md` 세부 옵션 정도). 최신 목록·우선순위는
  `.claude/README.md`가 소스, 여기서 개수 반복 안 함(과거에 "두 개뿐"이라
  적어놨다가 새 문서 추가될 때마다 안 갱신되는 패턴이 반복돼서 아예 안
  세기로 함).
- `.claude/qa-request/`, `.claude/feedback/` — 구현 시작되면 쓰기 시작함,
  지금은 비어있음. `.claude/archive/`는 원래 같은 취급이었으나
  2026-08-06 세 번째 세션부터 **완전히 뒤집힌 설계 결정을 원문+역전
  이유+diff와 함께 보존하는 용도로도 사용 시작**(구현 완료 대상만이
  아님) — `archive/store-source-proxy-reversed.md`가 첫 사례, 나중
  `quadnomicon` 콘텐츠 소재로 재사용 예정.
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

1. **구현 시작 — 루트 `ROADMAP.md`의 M0부터.** 설계 단계는 2026-08-04
   로드맵 인수인계 라운드로 종료, 다음 세션은 바로 `ROADMAP.md` M0(스켈레톤+
   기술검증 스파이크)부터 시작. M0는 "진짜" 마일스톤이 아니라, 지금까지
   추론만으로 확정하고 실제 Luau로 부딪혀본 적 없는 세 가지(Store/State
   propagation, 재귀 process/retract 디스패치, 컴포넌트 경계 named-parameter
   전달)를 던지는 코드로 검증하는 단계 — 여기서 걸리면 `base/` 문서를 그
   자리에서 고치는 게 정상. M0 통과 후 M1(실제 스캐폴딩: `quad-base/`,
   `quad-roblox/` 폴더 + `wally.toml`/`default.project.json`/`.luaurc` +
   quad-base용 최소 mock 테스트 하네스)으로 진행 — 소스 트리 자체는 이미
   확정됨(`base/architecture.md` "구현 착수" 절). 이 단계부터
   `qa-request/`/`archive/` 폴더가 실제로 쓰이기 시작함. **세부 순서/todo는
   `ROADMAP.md`가 소스** — 여기서 반복 안 함. **M0 착수 직전에 `research/
   pre-implementation-audit.md`(2026-08-06 신설)의 우선순위1 항목부터 먼저
   확인할 것** — 특히 M0 스파이크 코드 자체에 반영해야 할 항목(props.Modifier/
   Ref를 안 넘기는 케이스 포함, `store.key` 레코드 필드 타이핑도 M0로
   앞당기기 검토)이 있음, 아래 최신 세션 요약 참고. **M0 실제 착수 전,
   `.claude/luau-test/`(2026-08-09 신설)의 사전 검증 스파이크 결과부터
   확인할 것** — M0가 공식 짜야 할 스파이크와 겹치는 항목들을 미리
   독립 스크립트로 만들어 사용자가 `luau`/`luau-analyze`/`luau-lsp`/
   Roblox Studio로 직접 돌려보기로 한 상태, 아직 결과 미확인. 걸리는
   게 있으면 `base/` 문서부터 고치고, 없으면 그대로 M0 실제 코드 작성에
   재사용하면 됨(README 참고).
2. **용어 정리 — 사용자가 별도로 요청, 진행 중.** "register"(v1) 같이
   부정확한 이름들을 전체적으로 재검토하자는 요청 — 1차 제안 완료(우선순위
   순: `State`가 React/Vue식 "쓸 수 있는 로컬 상태"라는 통상 의미와 반대라
   가장 위험, `DI`가 Dependency Injection 축약어와 충돌, `PerInstanceState`가
   핵심 프리미티브 `State`와 이름 충돌 — 세부는 `.claude/question.md` 참고),
   사용자와 같이 계속 논의 필요. 컴포넌트 경계용 `props.Modifier`/`props.Ref`/
   `Modifier.Merge` 같은 새 가칭들도 이 정리에 합류 대상.
3. `research/existing-instance-bind-plan.md`는 급하지 않음 — 스코프 논의만
   필요, 구현 착수를 막지 않음.
4. **[백로그] 범용 렌더 디버깅 도구로서의 quad-mock.** 1번의 quad-base 테스트용
   mock과는 별개 — 정적 스냅샷을 넘어 Tween mock 같은 동적 동작까지 지원하는
   더 큰 스코프의 디버깅 도구(`architecture.md` "테스트 전략" 절 백로그 참고).
   효용성 봐가며 나중에 검토, 지금 당장 설계할 필요 없음. **[백로그, 별개]**
   런타임 디버깅 플러그인 `quad-debug`(실물 Instance→코드 위치 역추적,
   `research/debug-tooling-plan.md`)도 2026-08-06 세션에서 설계 수렴 —
   채널 실현 가능성(Studio 플러그인↔Play 중 게임 간 BindableEvent/Function
   통신)까지 실측 검증 완료, 세부 API 이름만 남음. 착수 시점은 여전히
   "quad 개발 상당 부분 끝난 뒤"로 사용자가 못박음. 같은 날 파생된 문서화
   전략(`research/documentation-plan.md` — UI 네이밍 컨벤션, Store 부작용
   게임 시스템 활용 패턴, 권장 이벤트 핸들링 패턴 3종)도 후순위 백로그로
   같이 남김. **[2026-08-06 세 번째 세션에서 크게 확장됨]** 문서 사이트
   전체 구조(초심자/api/심화/`quadnomicon` 4축)와 실제 콘텐츠 분류맵
   (`research/documentation-content-map.md`), quad vs Fusion/Vide/react-lua
   정직 비교(`research/framework-comparison-findings.md`)까지 늘어남 —
   착수 우선순위 자체는 안 바뀜(여전히 후순위), 아래 최신 세션 요약 참고.
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
- **컴포넌트화 논의, 같은 날 후속 세션에서 완결** — v1의 `Class.Extend()`
  자동-store 매직은 폐기하고 React식으로 값을 명시적으로 전달하는 방향으로
  수렴, `StoreSource`(Source를 인터페이스+구현체로 보고 Store 키에서 얇은
  프록시로 얻는 것) 아이디어 확정. 마지막 미결이던 "modifier/Ref의 컴포넌트
  경계 통과"도 후속 세션에서 풀림: Compose/Fusion/Vide/v1 4개 선례를
  서브에이전트로 병렬 조사한 결과 전부 named parameter로 경계를 넘기는
  패턴에 수렴한다는 게 확인됐고, "컴포넌트가 여러 루트를 반환한다"는
  프레이밍 자체가 (a) Luau가 tail position 밖 다중 리턴을 지원 안 해서
  불필요한 개념과 (b) 이미 있는 Slot 메커니즘을 섞은 것이었음이 드러나
  정리됨 — 결론: 경계는 named parameter(`props.Modifier`/`props.Ref`
  가칭), "다중 루트"라는 별도 개념은 폐기, 여러 modifier를 하나로 합치는
  `Modifier.Merge`(가칭) 유틸 추가. `research/component-composition-plan.md`
  → `base/component-composition-plan.md`로 승격 완료.
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

**같은 날 로드맵 인수인계 라운드 — 설계 단계 마무리, 구현 준비 완료**:
- **quad-base 테스트 mock 방향 확정**: Vide 선례(`test/mock.luau`, ~300줄,
  순수 `luau` CLI, Studio 불필요) 그대로 채택, 스코프는 정적 디버깅 한정(Tween
  같은 동적 동작 제외), quad-roblox로 작성한 컴포넌트가 mock에서도 그대로
  돌아가야 한다는 요구 없음(단순하게 감) — `architecture.md` "테스트 전략"
  절. 범용 렌더 디버깅 도구(Tween mock 포함)는 별개로 백로그.
- **구현 전 리스크 감사**: `.claude/base/` 전체 + 남은 `research/`를
  서브에이전트로 감사해 "실제 Luau 접촉 없이 추론만으로 확정된 것" 3개
  (Store/State 반응형 코어, 디스패치 엔진, 컴포넌트 경계 modifier/Ref)를
  식별 — 이것들은 M0 스파이크로 검증하기로 함(아래). 감사 중 `slot-plan.md`가
  스스로 "정식 확정 안 됨"이라 표시해뒀던 "클래스가 슬롯을 받는 방법"(Named
  Slot 없음)도 이번에 정식 확정, 대신 "여러 Slot이 형제로 섞일 때 순서 보장"
  이라는 새 하위 질문이 열림(다중 백엔드 관점, Roblox만이면 급하지 않음).
  `State<Modifier>` 조합은 UB로 확정해 타입으로 막기로 함(`modifier-plan.md`
  7번), 디스패치 엔진의 일반적 무한루프는 방어 로직 없이 provider 버그로
  간주하기로 확정(`bind-system-plan.md`).
- **루트 `ROADMAP.md` 신설** — M0(스켈레톤+기술검증 스파이크, "진짜"
  마일스톤 아님)부터 M11(Tween)까지 + 병행 가능 항목 + 백로그로 구성된 실행
  계획, todo 체크박스 포함. 오늘은 문서 준비만 — **다음 세션이 M0부터 실제
  시작**.

용어 정리 제안 진행 중인 점은 위 "지금 할 일" 2번 참고.

## 2026-08-06 세션 — quad-debug(런타임 디버깅 플러그인) 설계, 실측 검증까지 완료

팀원이 "실물 Frame에서 그걸 만든 코드 위치를 역추적하는 Studio 플러그인이
있으면 좋겠다"는 피드백을 줬고, 사용자가 이걸 `quad-debug`/
`quad-debug-roblox-plugin`으로 후순위 설계해두자고 판단해 시작된 세션.
착수는 여전히 "quad 개발이 상당 부분 끝난 뒤"로 못박혀 있음(구현 우선순위는
안 바뀜) — 대신 base 설계(디스패치/Source/DI 생성자) 시점에 훅 확장
지점만 고려해두면 나중이 훨씬 싸진다는 문제의식으로 지금 미리 설계만
해둠. 전체 내용은 `research/debug-tooling-plan.md`, 요지만 요약:

- **설계를 막던 유일한 기술적 불확실성이 실측으로 해소됨**: Roblox Studio
  플러그인과 Play 중인 게임(LocalScript)이 별도 Luau VM/스크립트
  컨텍스트라 `BindableEvent`/`BindableFunction`이 그 경계를 실제로
  넘는지가 문서만으로는 안 갈렸음(공식 문서는 언급 없음, DevForum엔
  실패 사례도 있었음) — 사용자가 테스트용 플러그인/스크립트
  (`plugin-ignoreme.luau`/`game-ignoreme.luau`, 레포 루트, `*-ignoreme*`
  패턴이라 자동 gitignore)를 직접 Studio에서 돌려 **Fire/Connect,
  Invoke/OnInvoke 왕복 둘 다 안정적으로 작동함을 확인**. 원리는 "Play
  진입 시 DataModel이 복제되는 게 아니라 script identity/보안 컨텍스트만
  분리되고, Instance 자체(C++ userdata)는 어느 컨텍스트에서든 같은
  참조를 가리킨다"는 것 — 사용자가 실측 도중 직접 정리한 설명.
- **채널은 확인됐지만 처음 구상(quad-debug-roblox가 `ReplicatedStorage`에
  Bindable을 자동 생성)은 기각** — 개발자가 의도 안 한 Instance를 게임
  트리에 주입하는 부작용이 크다는 사용자 지적. 대신 quad 모듈 자신의
  Instance 트리 안에 두고 `CollectionService` 태그로 노출, 플러그인은
  `GetTagged`로 찾음(`GetDescendants` 전체 순회 불필요).
- Roblox Luau의 `debug` 라이브러리엔 `sethook`류가 없어(확인됨) 엔진이
  공짜로 주는 동적 트레이싱 방법이 없음 — 대신 Fusion `src/External.luau`에
  이미 있던 "no-op 업밸류를 나중에 실제 구현으로 통째로 교체" 패턴을
  재사용하기로 함(quad가 이미 쓰는 "base는 인터페이스, 구현은 팩토리가
  주입" 원칙과 같은 모양이라 새로 발명할 필요 없음).
- React DevTools 아키텍처도 서브에이전트로 조사 — 그대로 못 베끼는 것도
  있지만(전역 훅 주입은 프로세스 경계 문제로 안 됨), **컴파일타임 소스
  위치 주입**(Babel처럼 darklua로 흉내낼 후보)과 **얇은 스트림+on-demand
  상세조회** 원칙은 그대로 채택.
- UX 방향은 사용자가 여러 번 직접 정정: "존재하는 State 목록"이 아니라
  "무엇이 무엇에 연결됐는가" 그래프 중심, flash-on-update는 전체 상시
  적용이 아니라 마운트/언마운트만 상시+개별 프로퍼티 변경은 현재 열어본
  Instance 한정, PropertyChangedSignal 기반 "외부 변경 감지"는 핵심
  채널이 아니라 보조 신호일 뿐(어디서/왜 바뀌었는지가 quad-debug의 진짜
  가치라 순수 관찰만으론 부족). **Element Inspector**(화면 클릭으로 UI
  요소 피킹)가 사용자가 실제로 가장 크게 느낀 pain point로 새로 부상 —
  Roblox가 Play 중 라이브 UI 편집 도구를 꺼버려서 Explorer만으로 요소
  찾기가 힘들다는 실사용 불만.
- 부수적으로 파생된 두 가지(quad-debug 범위 밖) 문서화 아이디어 —
  UI 네이밍 컨벤션 문서, 스킬/쿨타임/재화 같은 게임 시스템에서 Store의
  부작용 허용을 깔끔한 패턴으로 쓰는 법 문서 — 를 `research/
  documentation-plan.md`에 뼈대만 분리해서 남김(위 "지금 할 일" 4번).
- **이벤트 self 관습 확인 필요했던 항목 — 같은 날 후속 세션에서 해소됨.**
  아래 "2026-08-06 후속 세션" 절 참고.

**같은 세션 후반, 별개 주제 두 개 추가**(quad-debug와 무관, 사용자가
"적어는 뒀는데 안 줬는건가" 하며 새로 떠올린 것들):
- **Attribute 특수 키 타입 파라미터화** — `[Attribute<<boolean>> "name"]`
  제네릭 스타일 vs `[BooleanAttribute "name"]` 타입별 정적 생성자 패밀리.
  기존 문서 어디에도 없던 신규 논의로 확인(`bind-system-plan.md`
  "Attribute 특수 키" 절에 새로 추가) — 소견은 DI 인스턴스 생성 때 이미
  쓴 "제네릭 하나 + 자주 쓰는 타입만 정적 지름길" 패턴 재사용, 확정은 아님.
  Roblox Attribute가 이제 Instance 참조 타입도 지원해서 `ObjectValue`
  없이 Ref 용도로도 쓸 수 있다는 점도 확인 — quad-debug 논의의 "Value
  오브젝트 기각, Attribute 우선" 결정을 보강함.
- **UICorner/UIPadding/UIScale 인라인 편의 키** — 사용자가 v1에서 "Frame
  안에 인라인으로 넣기만 해도 CSS처럼 적용됐다"고 기억한 기능, 서브에이전트로
  v1 소스(`class.lua`) 조사해 실체 확인: `Corner`/`PaddingAll(Offset)`/
  `Scale` 3종(+ 별개 메커니즘인 `RoundSize`)이 실제로 있었음(리터럴 값 하나
  → 이름 붙은 UICorner/UIPadding/UIScale 자식을 찾거나 생성). `UIListLayout`/
  Grid/Flex 전용 숏핸드는 없었음 — 그건 이미 quad-v2에 있는 범용
  children-array 메커니즘으로 충분히 커버되므로 새로 설계할 것 없음.
  **한 차례 "지금은 UICorner가 네이티브라 포팅 불필요"로 잘못 정리했다가
  사용자가 재정정**: `RoundSize`(이미지 9-slice 라운드 트릭)만 UICorner
  없던 시절의 워크어라운드라 포팅 불필요고, `Corner`/`PaddingAll`/`Scale`
  자체는 "UIScale 등이 여전히 별도 Instance라 부모에 붙여야 하는 구조는
  안 바뀌었다"는 이유로 **여전히 필요한 기능으로 재확정**. `research/
  ui-shorthand-plan.md`에 최종 정리 — 메커니즘은 기존 pluggable Handler로
  그대로 커버(새 아키텍처 개념 불필요), 패키지 배치는 `quad-roblox` 코어에
  직접 포함으로 확정(별도 `quad-roblox-util` 불필요 — "트윈도 하나로 묶어
  코어에 넣은 선례처럼, 작고 opt-in 아닌 건 분리 안 한다"는 사용자 판단).
- **quad-debug 플러그인 UI 구조 확정** — Explorer에서 quad 내부 자동
  생성물(예: 위 UICorner 숏핸드가 만든 것)을 직접 선택했을 때 플러그인
  트리에 대응 노드가 없으면 부모로 대신 선택, 있으면(사용자가 직접
  bind한 경우 등, UB 아님) 정확히 그 노드 선택. 내부 자동 생성물은
  `_`/`QUAD_` 접두어로 네이밍(v1 `_quad_round`류 재사용,
  `documentation-plan.md` 네이밍 컨벤션과 연결). 플러그인 UI는 세
  상호작용면(자기 트리 뷰/리프 클릭→상세 패널/실제 Explorer 선택과 연동,
  Explorer와 플러그인 트리는 별도 도킹 위젯)으로 구성된다는 것도 사용자
  질문에 확인 응답 — `debug-tooling-plan.md` "핵심 설계 방향" 9번.

## 2026-08-06 후속 세션 — 이벤트 self 관습 결정, rbvm GC 참고, 문서 코퍼스 정리

같은 날 이어진 세션에서 세 가지를 처리함. **다음 세션이 새로 알아야 할 것은
없음** — 아래 전부 `base/`/`research/`/`question.md`에 실제로 반영 완료.

**1. 이벤트 핸들러 self(Instance) 관습 — 채택하지 않기로 확정.** 위 절에서
"확인 필요"로 남겨뒀던 것의 결론: v1의 `func(self or this, ...)` 관습은
실존함을 확인했지만(`.claude/initreq/quad/src/event.lua` 82행, 튜토리얼
문서화까지 있음), quad 재설계에서는 채택하지 않음. 근거 네 가지 —
(1) Ref가 이미 "생성 직후/마운트 후 Instance 접근"을 콜백으로 커버해서
중복 채널이 됨, (2) self로 재바인드 가능한 thin wrapper를 준다면 Modifier의
정적 flatten과 경쟁하는 두 번째 쓰기 경로가 생겨 KV 핸들러가 매번
"flatten된 값이냐 wrapper냐"를 분기해야 하는 오버엔지니어링, (3)
quad-debug가 추적하는 반응형 그래프 밖의 mutate 경로가 공식 API로
생기는 셈이라 `purity-and-effects-plan.md`의 이식성 원칙과 충돌, (4)
self를 넘기려면 원본 콜백을 클로저로 한 번 더 감싸야 해서 불필요한 할당
비용 — quad는 어차피 라이프사이클 끝까지 바인딩을 들고 있어 Destroy 시
Connection도 자연히 정리되므로(`lifecycle-pattern.md`, GC-native) 감쌀
이유가 없음. 상세 결정문은 `base/bind-system-plan.md`의 "이벤트 핸들러는
self(Instance)를 받지 않는다" 절. `research/debug-tooling-plan.md`/
`.claude/question.md`의 관련 항목은 "해소됨"으로 갱신 완료, 이 결정을
설명하는 문서화 숙제("왜 thin wrapper를 안 주는가", "권장 이벤트 핸들링
패턴")는 `research/documentation-plan.md` 3번으로 신설(다른 두 항목과
동일하게 아직 백로그 뼈대만).

**2. rbvm GC 패턴 — "실물 검증됨" 근거 보강.** 사용자가 "GC 처리를 봐야
한다면 rbvm을 확인하라, 실제 프로덕션에서 잘 돌아가는 걸 직접 확인한
모듈"이라고 언급 — 실제로 rbvm의 GC 패턴(weak table 4종, `Instance.
Destroying` 기반 gcHold 클로저, 네임스페이스 Dispose 훅 등)은 이미
`base/lifecycle-pattern.md`에 파일:라인까지 인용하며 상세 반영돼 있었지만
"사용자가 직접 실행해서 확인했다"는 신뢰도 근거는 빠져있어서 그 문단을
추가함(사람이 짠 코드라 100% 무결 보장은 아님 — 이미 발견된 버그 2건도
근거로 같이 인용, 규범이 아니라 참고용 비교 대상이라는 톤 유지).

**3. `.claude/` 코퍼스 전체 정리 패스.** 이전 세션들에서 쌓인 stale
참조/모순을 서브에이전트로 전수 감사 후 수정 — `modifier-plan.md`/
`architecture.md`의 `research/component-composition-plan.md` 참조를
승격된 `base/` 경로로 갱신, `comparison-fusion-vide.md`의 낡은 "Vide식
암묵적 추적 vs Fusion식 명시적 축, quad는 미정" 서술을 실제 확정 사실
(`bind-system-plan.md`의 `:With`+`:Compute` 명시적 모델 채택)로 정정,
`tween-plan.md`의 끊긴 절 참조 수정, `documentation-plan.md`의 인용
오류 정정. `module-lifecycle-plan.md`가 스스로 "question.md에도 취합"
표시해뒀지만 누락돼 있던 "프로바이더" 이름(provider/processor/plug)
미정 항목도 `question.md`에 추가함. 여러 문서에 흩어져 있던 진짜 열린
설계 질문들(Slot 형제 순서 보장, Attribute 타입 파라미터화, UI shorthand
이름 등)은 전부 `.claude/question.md`에 이미 반영되어 있음을 재확인만
하고 임의로 결정하지 않음 — **이 파일이 여전히 "지금 열려있는 것"의
단일 소스.**

**4. Store `:Emit`, `:Compute`의 `previous` 인자, `state:Observer(fn)`,
Ref 일반화 — 네 가지 다 확정, 실제 base 문서에 반영 완료.** 같은 세션에서
더 이어진 Store/Ref 설계 논의, 전부 `base/store-semantics.md`와
`base/bind-system-plan.md`에 반영됨:
- **`Store:Emit(key)`** — Source 원천에 한해서만 허용(중간/파생 State엔
  없음). 존재 이유는 clone 불가능한 userdata/엔진 객체가 우선(편의성은
  부차적). `Get()`이 라이브 레퍼런스를 주므로 캐시해서 비교/diff하면
  안 된다는 캐비엇 명시. Modifier는 정적 flatten이라 Store/State 경로에
  아예 안 걸치므로 Emit과 충돌할 지점 자체가 없음(따름정리:
  `Store<T>`의 `T`는 Modifier가 될 수 없음) — `store-semantics.md`.
- **`:Compute(fn)`의 선택적 두 번째 인자 `previous`** — Compute 결과
  자체가 무거운 userdata인 경우(예: 큰 locale 테이블 → Roblox
  `LocalizationTable` 변환) 재생성 대신 이전 결과를 재사용/patch하는
  용도, opt-in. `previous`는 "정확히 한 단계 전"이 보장 안 되므로 반드시
  full diff로 다뤄야 함(React reconciler와 같은 모양). **핵심 캐비엇**:
  이 패턴은 결과 State가 계속 능동적으로 관측(정상 prop 바인딩 또는
  `state:Observer(fn)`+명시적 `Get()`)되지 않으면 mutate 로직 자체가
  다시 실행 안 되어 조용히 영구 정지함 — `bind-system-plan.md`.
- **`state:Observer(fn)`** — 무효화 신호만 주고 값은 안 줌, `fn` 안에서
  명시적으로 `Get()` 해야 실제 값을 얻음(기존 "emit은 저렴한 무효화
  신호" 원칙 재사용). 반환값 자체가 `CreatedRef`처럼 children 배열에
  바로 놓는 leaf 값(별도 `ObserverHolder` 래퍼 불필요, 사용자가 직접
  단순화) — 그 leaf가 살아있는 동안만 구독 유지, `canExecute`로 게이팅.
  `fn` 생략 시 "이 State를 그냥 계속 능동 관측 상태로 유지"하는 유틸로
  씀(위 `previous` 캐비엇의 해결 도구). 구현은 값 내부가 아니라 외부
  weak table로 살아있는 Observer를 추적하는 방식 권장(rbvm
  `getNamespaceOf`류 선례) — `bind-system-plan.md`.
- **Ref 일반화** — "quad가 만든 instance 전용"에서 "아무 사용자 값이나
  담는 범용 값 박스"로 확장(object-ref/function-ref 안 나눔, React
  `useRef`가 선례). `.Value` + `:Wait()`(coroutine 컨텍스트용) + 콜백
  등록(복수 허용, 이미 채워져 있으면 즉시 1회 호출) — 이걸로 "코루틴
  기반 대기 지원 미정"이던 항목 해소. `CreatedRef`는 이 위에 얹힌 특수
  편의 패턴으로 재정리, 상충 없음. **one-shot 여부도 해소됨 — 반복
  재설정 가능으로 확정**(React의 자식 재생성 시 ref 재사용 패턴이 선례,
  라벨 컨테이너 재사용 예시로 확인). 콜백은 발화 후에도 안 소진되고
  매 `:Set()`마다 다시 불림 — 소진되는 건 `:Wait()`의 개별 대기자뿐.
  **Ref는 의도적으로 lazy가 아니고 `:Compute` 파생도 지원 안 함** —
  State와의 이 차이가 중요(예전에 Store가 Ref 역할도 겸했다가 lazy
  모델과 섞여서 안 좋았던 경험에서 나온 의도적 분리). Ref 정의 자체가
  넓어졌으니 용어 정리 때 이름도 같이 재검토 대상. `question.md`의
  관련 항목은 해소됨으로 갱신.

**5. Observer 이름 확정, Ref/Source/Store 생성자 스타일, "독립 프리미티브 vs
파생 데이터" 원칙, Modifier 세부 마무리 — 전부 확정, base 문서 반영 완료.**
- `Observer`로 확정(`ObserverHandle` 아님) — `:Connect()`→`Connection`과
  같은 기존 명명 관례. PA님 코드의 동명 클래스와는 무관, 각주로 구분.
- **생성자 스타일**: `Source(default)`/`Ref(default)`/`Store({defaults})`
  — Kotlin Compose식 "타입 이름 자체가 팩토리 함수". Ref만 예외였던 이유
  없었음(단순 명세 공백).
- **일반 원칙 신설**: 독립 존재 가능한 프리미티브(Source/Ref/Store/
  Modifier, `Type(args)` 자유 함수 생성자) vs 원천에 종속된 파생 데이터
  (State/Observer, 원천에 대한 메소드로만 얻어짐) — `state:Observer(fn)`가
  메소드고 자유 함수가 없는 더 근본적인 이유로 연결(`store-semantics.md`).
- **Modifier 마무리**: (a) Getter를 아예 안 만들기로 확정 —
  `:FontSize(function(old)->new)`가 유일했던 use case를 인라인으로 커버.
  (b) `old`는 항상 "현재 저장된 그대로"(plain이면 raw, State면 State
  핸들) 넘김 — `:Compute`의 self와 같은 결. (c) `func(state)->state`라는
  세 번째 인자 모양은 불필요(함수 합성 + State 직접 대입으로 이미 커버).
  (d) Modifier는 핸들러 계층(Ref/Slot 등)을 몰라도 됨 — 순수 데이터
  merge 레이어라 UB로 흘려보내도 문제없음. (e) **런타임 구현은 base에
  제네릭 `__index` 하나면 충분** — `mod:FontSize(...)`가 `__index(self,
  "FontSize")`로 잡히므로 클래스별 런타임 코드 불필요, FrameModifier류
  타입 생성기는 순전히 정적 타입 체크만을 위한 것. (f) 이벤트도
  store-bind 가능하도록 확정 — 기존 재실행 래핑 재사용, `false`를
  disconnect 센티널로 씀(`nil`은 테이블에서 사라져서 부적합) —
  `bind-system-plan.md`. Modifier가 이벤트 키를 담아도 되는지는 (d)로
  자동 해소(Modifier가 애초에 키 종류를 구분 안 하므로).

**6. 이벤트 store-bind는 부차적 옵션으로 재조정, Observer의 `:Subscribe`/
`:Unsubscribe` 추가 — 둘 다 확정, 반영 완료.**
- 이벤트 store-bind(5번 (f))를 다시 검토 — "구현이 쉽다"가 "구현할
  가치가 있다"를 보장 안 함을 재확인. 저빈도 UI 이벤트의 조건부 처리는
  "핸들러 하나 계속 연결 + 내부에서 `store.enabled:Get()` 분기"가 이미
  Connect/Disconnect 없이 더 싸고 표준적이라 **이걸 기본 권장 패턴으로
  확정**. store-bind는 고빈도 신호(Heartbeat 등)나 로직 자체가 바뀌는
  드문 케이스를 위한 부차적 옵션으로 격하(메커니즘 자체는 유지 — 일관성
  위해 예외로 뺄 근거는 약함). 자주 재계산되는 State에 물리면 Connect/
  Disconnect churn이 숨은 비용이 된다는 캐비엇도 추가.
- **Observer의 `:Subscribe()`/`:Unsubscribe()`** — children 배열에 안
  붙는 "전역/독립" Observer(디버깅용으로 Store에 직접 걸어 print하는
  흔한 패턴, `RunService:IsStudio()` 가드 + BooleanValue 토글)를 위한
  명시적 라이프사이클 경로. 이건 새 설계가 아니라 PA님 코드 교차검증
  때 이미 예고해둔 확장 지점("GC만으로 부족하면 명시적 dispose 경로
  추가 가능")을 실제로 채운 것. liveness 체크는 `self.Subscribed` 필드
  우선, `self.Connection.Connected` 폴백(필드 접근이 weak table 조회보다
  쌈). 내부 레지스트리는 자동 케이스의 weak table과 별개로 강참조
  (weak면 "살려둔다"는 목적이 무의미해짐). 둘 다 idempotent, `:Unsubscribe()`는
  자동 케이스 조기 해제에도 재사용.

## 2026-08-06 세 번째 세션 — 문서 사이트 구조, 프레임워크 정직 비교, Source가 State를 만족하는 서브타입 재구성

같은 날 이어진 세 번째 세션. 셋으로 갈리는 주제라 순서대로 요약 — **다음
세션이 새로 알아야 할 건 4번(Source/State 재구성)뿐**, 1~3번은 배경/참고용.

**1. 문서 사이트 구조 확정 — 초심자/api/심화 3축 + `quadnomicon` 4번째 축.**
`research/documentation-plan.md` 0번 항목에 전부 반영. 초심자는 "core loop
완주에 필요한 최소 집합만, 백엔드 구체적(quad-roblox), quad-base/roblox
분리 노출 안 함, 다른 백엔드 생기면 그때 별도 트랙 추가"로 스코프 확정.
api는 간략 설명 + 심화로 "더 알아보기" 링크 패턴. `quadnomicon`(Rustonomicon
패러디, 사용자 확정 이름)은 quad 사용자가 아니라 "비슷한 프레임워크를
설계/포크하려는 엔지니어"용 4번째 축 — Fusion/Vide 내부 비교 같은 콘텐츠가
여기 해당, 세션 정정 이력 같은 순수 내부 리서치 원자료는 이 축에도 안
들어가고 그냥 `.claude/` 내부에만 영구히 남음(RFC 저장소 성격). GC처럼
quad 밖 배경지식이 깊은 주제는 새 티어 없이 "quad 활용법만 심화에, 일반
개념은 외부 링크"로 처리. 실제 콘텐츠 분류(초심자 core loop 목차 초안,
파일별 분류, 심화 에세이 후보 15개)는 `research/documentation-content-map.md`.

**2. quad vs Fusion/Vide/react-lua 정직 비교 — 3개 에이전트가 실제
소스/웹 리서치로 검증.** `research/framework-comparison-findings.md`.
요지: quad의 Slot 단일 마운트 가드·열린 우선순위 축·명시적 의존성·다이아몬드
dedup은 실 소스 근거로 확인된 진짜 강점(Fusion `Children.luau`의 TODO
주석, Vide `mount.luau`의 중복 체크 부재, Vide 자신이 `todo.md`에 미해결로
남긴 diamond 문제 등). 반대로 use-after-destroy 검증 안전망 부재·`:With`
정적 의존성·Store dot-access 할당 비용 3가지는 고칠 만한 약점으로 식별(3번은
이후 4번 논의로 이미 해소됨). GC-native 리스크·암묵 추적 대비 보일러플레이트·
Tween 비합성성·"지금 트리 상태" 파악 어려움은 의도된 트레이드오프로 "고친다"
개념 자체가 안 맞음. 성숙도 격차(quad 구현 0줄)는 정직하게 명시.

**3. 위 1·2번에서 파생된 실행 항목**: 아직 결정 아님, `research/
documentation-plan.md`/`framework-comparison-findings.md`의 "다음 단계"에
남겨둔 사용자 판단 대기 항목들(문서화 착수 시점, 프레임워크 비교에서 나온
개선안 반영 여부/시점) 그대로 참고.

**4. Source가 State를 구조적으로 만족 — Store/State/Source 핵심 메커니즘
재구성, base 문서 전부 반영 완료.** `store.key`의 타입 문제(레코드 타입
`{key: State<number>}`가 읽기/쓰기 비대칭이라 Luau 타이핑이 안 맞음)를
풀다가 나온 더 근본적인 재구성:
- **`Source<T>`가 구조적으로 `State<T>`를 만족**(단방향 호환, Svelte
  `Writable<T> extends Readable<T>`와 같은 모양) — `.value`/`:Get()`/
  `:With`/`:Compute` 전부 지원 위에 `:Set(value)`/`:Emit()` 추가. `:With`/
  `:Compute`는 Source에서도 항상 `State<U>` 반환(구현은 metatable `__index`
  델리게이션, `Modifier`의 제네릭 `__index` 트릭과 같은 패턴이라 로직
  중복 없음). 이 서브타입 관계는 `quad2-try`에서 기각한 컴포넌트/클래스
  OOP 상속과 다른 층위(프리미티브 타입 간 구조적 서브타이핑일 뿐, 사용자가
  짜는 클래스 계층 구조가 아님)라 그 금지와 안 부딪힘.
- **`RefSource`(store 슬롯 전용 타입 중간안)와 그 전신인 `StoreSource`
  프록시(2026-08-04 세션에서 confirmed였던 것)는 전부 폐기.** Store는
  이제 "이름 붙은 Source 모음, 그 이상 아님" — `store.key`는 Store 생성
  시 이미 만들어둔 진짜 Source 객체를 그대로 반환(별도 wrapper 생성/캐싱
  단계 자체가 사라짐, 이전에 검토한 "State를 weak table로 캐싱"보다도
  쌈). v1이 타입 없던 시절 습관으로 모든 값을 Store에 몰아넣은 건 "당시엔
  편해서"였지 지금 그대로 가져올 이유가 아니라는 게 사용자의 회고적
  재평가 — 그 재검토가 이번 단순화로 이어짐.
- **`store.key = value`(`__newindex`) 폐기, `store.key:Set(value)`로
  전환** — 이유 둘: (a) 레코드 타입 `{key: Source<number>}`가 읽기/쓰기
  둘 다 같은 타입이어야 Luau 타이핑이 깨끗한데 대입 문법을 유지하면
  비대칭이 남음, (b) `=`는 관례상 "즉시 커밋되는 부작용 없는 쓰기"를
  암시하는데 quad는 실제로 lazy(무효화 신호만 쏘고 재계산은 관측 시점에)라
  대입 문법이 실제 동작과 정서적으로 안 맞음(사용자 논거). `Store:Emit(key)`도
  같은 이유로 `source:Emit()`(key 인자 불필요)로 이동 — 같은 일 하는
  두 번째 경로를 안 남긴다는 원칙과 일치.
- **검증 필요, M0 스파이크에 항목 추가됨(`ROADMAP.md`)**: Source의
  `:Compute` 시그니처가 자기 자신과 `State<U>`를 동시 참조하는 제네릭
  메소드라 Luau 솔버가 재귀 타입 조합에서 안 막히는지 확인 필요. 자기
  참조 self 타이핑 자체는 흔하고 안전하나, `State<T>`가 거꾸로 `Source`를
  참조하는 **상호 재귀**는 Luau의 알려진 취약 패턴이라 피해야 함 —
  `State<T>`를 `Source` 참조 없이 독립적으로 먼저 정의하고 `Source<T>`만
  단방향으로 `State<T>`를 참조하게 두면 이 위험을 피할 수 있어 보이나
  확정 아님. 타입은 `&`(교차) 조합 대신 손으로 펼쳐 쓰는 쪽으로(사용자
  선호, 솔버 안정성 우선) — 이건 런타임 구현 델리게이션과 다른 축이라
  서로 안 부딪힘(타입은 펼치고 구현은 공유 가능).
- **반영된 파일**: `base/store-semantics.md`(신규 "Source가 State를
  만족함" 절이 최종 소스), `base/bind-system-plan.md`(온톨로지·타입 추론
  절 정정), `base/component-composition-plan.md`(`StoreSource`/타입
  유니온 절 재작성), `ROADMAP.md`(M0 항목 추가), `research/
  documentation-content-map.md`/`.claude/README.md`(참조 갱신). 이름
  자체(`Source`/`State`)는 여느 때처럼 "지금 할 일" 2번 용어 정리
  라운드까지 가칭.

## 2026-08-06 네 번째 세션 — M0 착수 직전 크리티컬 감사, `research/pre-implementation-audit.md` 신설

사용자 요청: "실 개발 시 모호하여 인터럽트될 수 있는 부분, 나중에 결정되면
치명적일 것 같은 것, 지금 구조가 오버엔지니어링일 수 있어 보이며 더 나은
대안이 있는 것"을 찾아 정리해달라는 요청. `.claude/base/` 전체(architecture/
bind-system/store-semantics/module-lifecycle/component-composition/
modifier/purity-and-effects/slot/lifecycle-pattern/quad-v1-architecture)와
근접 `research/`(existing-instance-bind/tween/ui-shorthand) + `ROADMAP.md`를
4개 클러스터로 나눠 서브에이전트 4개를 병렬로 돌려 "모호성/지연결정리스크/
단순화후보" 세 렌즈로 재감사, 결과를 `research/pre-implementation-audit.md`
로 종합. `.claude/question.md`엔 이미 취합된 것(용어 재검토, M0 스파이크
항목 자체 등)과 겹치지 않는 새 발견만 반영.

**작업 도중 발견한 부수 이슈**: 워크트리 생성 시점과 main 체크아웃의
미커밋 변경사항(세 번째 세션 결과물)이 어긋나 있었음 — 워크트리는 커밋
시점 기준으로 fork되므로 아직 커밋 안 된 변경은 안 딸려옴. 사용자가 중간에
main에 커밋을 완료해줘서(`4b839b0`) 워크트리를 새로 만들어 재동기화함 —
**앞으로 워크트리에서 최신 설계를 감사/참조해야 하는 작업을 시작하기 전엔,
main에 미커밋 변경이 있는지(`git status`) 먼저 확인하고 필요하면 커밋을
요청하거나 파일을 직접 동기화할 것.**

**핵심 발견 요약** (전체 25개 항목은 `pre-implementation-audit.md` 참고,
우선순위1만 발췌):

- **Tween.luau가 문서 전체에서 "범용 store-bind 캐치올 핸들러"의 유일한
  구체 예시로 서술됨** — 애니메이션 없는 일반 반응형 프로퍼티 바인딩이
  실제로 Tween 파일을 거쳐가는지, 별도 범용 핸들러가 필요한지 확정 안 됨.
  가장 구조적인 발견 — 직접 `bind-system-plan.md` 67-79행을 재확인해
  agent 발견을 검증함.
- `props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴의
  nil-hole 함정(caller가 안 넘기면 `{nil, ref, child}`에서 뒤 항목까지
  무시될 수 있음)에 그대로 노출 — M0 스파이크 코드에 이 케이스를 반드시
  포함시켜야 함.
- `canExecute`/`Connected`의 실제 구현 방식이 미확정인 채 코어 전역
  (Slot/Observer/store-bind retract)에 이미 재사용 확정돼 있음.
- `LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그 인터
  페이스를 전제로 서술돼 있음 — 로드맵 순서 역전, `ROADMAP.md` 조정 필요.
- retract 시 "이전에 실제로 매치됐던 핸들러" 추적 책임, 우선순위 스캔
  동률/매치실패 처리, provider 미주입 상태 dispatch 호출 시 동작 —
  전부 M2(Dispatch 엔진) 착수 전 한 번에 결정하면 효율적인 것들.
- Slot의 `add`/`remove`/`clear` CRUD 의미론 자체가 정의 안 돼 있음,
  "재마운트 시 throw"도 추적 대상(개별 element vs Slot 컨테이너)이
  뭉뚱그려 서술됨 — 둘 다 M6 착수 전 확정 필요.

**단순화 후보로 지적된 것 중 사용자 판단 필요**: `:Compute(fn)`의
`previous` 두 번째 인자 — quad의 "함수 자체가 재호출되는" 모델상 클로저
업밸류로 이미 되는 걸 별도 API 표면으로 만든 것일 수 있음(근거 불명).

**문서모순으로 남겨둔 것**: `State<Modifier>`는 "UB, 가능하면 타입으로
차단"인데 Ref/Slot이 Modifier 필드에 들어가는 건 "UB, 방어 로직 없음" —
같은 문서(`modifier-plan.md`) 안에서 정반대 원칙이 근거 설명 없이 나란히
적용됨. 판단이 필요해 고치지 않고 감사 문서에만 남김.

**부수적으로 직접 고친 stale 문서(판단 불필요한 순수 동기화)**: `base/
architecture.md` 소스트리 주석 두 곳 — `Store.luau`가 여전히 옛 `__newindex`
모델을 언급, `Ref.luau`가 여전히 "CreatedRef 메커니즘 자체"로만 서술(Ref
일반화 결정 반영 안 됨). 온톨로지 요약 절 stale은 같은 세션 도중 커밋
`4b839b0`에서 이미 독립적으로 고쳐져 있었음을 확인 — 재작업 없이 스킵.

**다음 세션이 할 일**: M0 착수 전에 `pre-implementation-audit.md` 우선순위1
항목(특히 위 6개)부터 확인 — "지금 할 일" 1번 참고. `.claude/question.md`
2번에 사용자 판단이 필요한 항목 요약이 반영돼 있음.

## 2026-08-07 세션 — `:With`도 새 State 노드로 확정

사용자 질문에서 시작: `:With(...)`가 문서상 가변인자 표기이긴 한데, 체이닝
(`:With(a):With(b):With(c)`)할 때마다 실제로 새 State 노드를 만드는 게
맞는지, 아니면 값 없이 의존성 목록만 clone-then-append로 누적하는 가벼운
빌더로 만들어 "노드가 With 호출마다 하나씩 증가하는" 낭비를 피해야 하는지가
불명확했음. 처음엔 "빌더" 대안(진짜 State가 아닌 clone 기반 누적 객체)을
검토했으나, 사용자가 두 가지 반례를 직접 제시하며 기각함:

1. **디버그 그래프가 꼬임** — `quad-debug`의 핵심 UX가 "무엇이 무엇에
   연결됐는가" 그래프인데, With/Compute가 전부 실제 노드면 코드 호출
   체인이 그래프 엣지와 1:1 대응되지만, 빌더로 만들면 그래프 툴이 가상의
   분기 지점을 따로 합성해야 함.
2. **clone 기반 구현이 Compute 노드 위에서 실제로 깨짐** — `c =
   a:Compute(f)` 뒤에 `w = c:With(b)`를 clone으로 구현하면 `c`의 캐시
   슬롯까지 그대로 복사되어 `w`가 `c`와 별개의 독립 캐시를 갖게 되고,
   `c`/`w`가 각자 관측되면 `f`가 두 번 따로 실행됨 — `bind-system-plan.md`가
   이미 기각해둔 "State 체인 플래튼"과 정확히 같은 실패 모드.

**결정**: `:With`는 호출마다 self+인자들을 레퍼런스로 구독하는 새 State
노드를 만든다(clone 아님, 계산 없는 pass-through 노드). 원래 문제 제기
(노드 남발)는 노드를 없애는 대신 `:With(...)`를 진짜 가변인자로 만들어
해소 — `:With(a, b, c)` 한 번으로 노드 1개(구독 3개)를 만들 수 있고,
디버그 그래프도 이쪽이 더 단순해 권장 관례로 삼음. 체이닝 스타일도 여전히
가능하나 그건 저렴한 노드가 늘어나는 것뿐이라 문제 삼을 비용이 아님.
`base/bind-system-plan.md`의 "왜 State 체인을 Modifier처럼 플래튼하지
않는가" 절 바로 뒤에 새 소절로 반영 완료. 다른 문서(`question.md`/
`ROADMAP.md`/`modifier-plan.md`)엔 이 결정과 모순되거나 갱신이 필요한
서술 없음을 확인함(감사 완료) — `modifier-plan.md`가 이미 "State가
`:With`/`:Compute`마다 새 노드를 할당"이라고 서술해뒀던 것과도 정합적.

다음 세션이 할 일은 안 바뀜(위 2026-08-06 네 번째 세션 절 참고) — 이
결정은 M0 스파이크(Store/State propagation 검증)가 실제로 짜볼 때
참고할 구체 스펙이 하나 더 생긴 것뿐.

## 2026-08-07 두 번째 세션 — Modifier `:Apply(factory)` 팩토리 체이닝 추가

사용자 제안: `Boldify(mod) -> mod`처럼 어떤 modifier든 받아 적절히 변형해
돌려주는 재사용 가능한 "팩토리 함수"(커링 지원, `Boldify(10)(mod) -> mod`)를
`mod:Apply(Boldify(10)):Apply(Italicify)`처럼 기존 필드 setter 체이닝과
같은 fluent 문법으로 끼워 넣을 수 있게 하자는 것 — Jetpack Compose의 커스텀
`Modifier` 확장 함수 패턴과 같은 효용(모듈화된 스타일 프리셋 재사용)을
Luau엔 확장 함수 문법이 없으니 콤비네이터로 흉내낸 아이디어. 채택 확정,
`base/modifier-plan.md` 8번 절에 반영 — `:Apply`는 `function(self, factory)
return factory(self) end`이 전부인 얇은 sugar(팩토리 자신이 이미 clone된
새 Modifier를 반환하므로 Apply 자체는 clone 불필요), 기존 3번(immutable
clone 체이닝)/4번(제네릭 `__index`) 결정 위에 그대로 얹힘. 구현 시 주의점
하나만 새로 생김: `Apply`는 제네릭 `__index`가 필드 setter를 즉석 합성하기
전에 먼저 확인해야 하는 고정 메소드 이름이라, **Modifier 필드 이름으로는
예약됨**(실 스타일 프로퍼티와 겹칠 일은 거의 없어 보이나 문서화 필요).
`ROADMAP.md` M7에 체크박스 추가 완료. 다음 세션이 새로 알아야 할 건 없음 —
M7 착수 시 `modifier-plan.md` 8번 참고하면 됨.

## 2026-08-07 세 번째 세션 — Ref의 KV 핸들러 처리 vs phase 타이밍, `PreRef` 신설

**출발점**: Ref가 Modifier처럼 밖에서 처리되는 게 아니라 KV 핸들러
(`process(inst,k,v)`)로 처리된다면, "생성 직후"/"자식 마운트 후" 두
콜백 타이밍(특히 self(Instance)를 안 주는 이벤트가 Ref로 self를 얻는
경우)을 단순 for-loop 디스패치만으로 어떻게 표현하는지가 출발 질문 —
길게 이어진 단일 스레드라 아래 요약만 읽으면 됨, 상세 근거는 각 base
문서에 이미 반영됨.

**핵심 결론(전부 `base/bind-system-plan.md`에 반영 완료)**:
- **base 디스패치 드라이버는 props 순회를 "배열 파트(children/Ref) 먼저,
  해시 파트(프로퍼티/이벤트) 나중"으로 명시적으로 두 패스 계약화**한다
  — Luau 테이블이 실제로 이렇게 순회되는 걸 사용자가 직접 확인했지만,
  그 우연한 동작에 기대지 않고 base가 스스로 이 순서를 보장(다른
  백엔드가 다른 자료구조를 쓸 수 있어서). M0 스파이크 검증 항목에 추가.
- **`CreatedRef`의 `{phase="created"|"mounted"}` 옵션은 폐기.** 두 패스
  계약 덕에 "자식 마운트 전/후"는 그냥 배열 안에서 Ref를 다른 children
  보다 앞/뒤에 놓는 것만으로 공짜로 표현됨 — 옵션 문법 자체가 불필요.
- **`PreRef` 신설** — "프로퍼티/이벤트 세팅보다도 먼저"(Roblox의
  `ChildAdded`/`DescendantAdded`/`Changed`류가 setup 도중 동기 발화할
  수 있어서 self-ref가 이벤트보다 먼저 채워져야 하는 케이스)만 담당하는
  별도 nominal 타입. `Ref`를 그대로 재사용(런타임 중복 없음)하되
  Modifier 필드 값·Source/Store 값으로는 타입으로 아예 못 들어가게
  막고, children 배열 안에서도 위치 무관하게 항상 최우선(호이스팅) —
  base 드라이버가 두 패스 루프 앞에 `PreRef`만 골라 fire하는 좁은
  pre-pass를 하나 더 둠.
- **일반 `Ref`는 Modifier/Store 어디든 계속 자유롭게 들어감** — Store를
  통해 나중에 도착하는 Ref는 그냥 도착한 순간 처리, 별도 phase 개념 불필요.
- **`:Wait()`는 PreRef에도 그대로 유효** — fire 자체는 동기적이지만
  호출부가 `task.spawn`이 아니라 순수 `coroutine`일 수 있어 실제
  yield-resume이 필요한 경우가 있음. "채워졌는지 먼저 확인, 없으면
  `:Wait()`" 방어 관용구를 문서화 대상으로 명시.
- **콜백/대기자 실행 구현 디테일 추가**: 같은 배열 하나를 한 번의
  일반화 `for`로 순회하며 `type(v)=="thread"`면 `coroutine.resume`+
  슬롯 nil 처리(1회성), 함수면 그냥 호출(유지) — 새 등록은 `table.insert`
  로 끝, 성긴 배열이어도 압축 불필요. **[정정, 2026-08-07 열 번째 세션]**
  "슬롯 nil 처리"는 틀림 — 사용자가 Luau REPL로 반례 제시, 실제로는
  `None`으로 소진해야 함(`#t`/`table.insert` 안전성 문제). `base/
  bind-system-plan.md` "왜 `nil`이 아니라 `None`인가" 절이 최신.
- v1의 `OnCreated` 특수 DI 키는 이식 안 함 — `Ref():Callback(fn)`으로
  완전 대체.

**역전된 이전 서술은 archive로 이동**: `CreatedRef`의 `phase` 옵션과
"Ref는 특수 처리 없는 평범한 참가자"라는 원래 서술은
`archive/ref-phase-option-reversed.md`로 옮기고 원 위치엔 짧은 포인터만
남김(컨텍스트 비대화 방지 목적, `archive/store-source-proxy-reversed.md`와
같은 패턴). `architecture.md` 소스트리 주석/`question.md`(PreRef를
용어 재검토 대상에 추가)/`research/documentation-content-map.md`(stale
`{phase=...}` 예시 갱신)도 같이 동기화함.

**아직 미해결, 다음 세션 주제로 예고됨**: `{ Override = nil, mod }`처럼
인라인 키로 modifier가 주는 값을 명시적으로 "지우고" 싶어도 Lua
테이블 리터럴의 `키 = nil`은 키가 아예 없는 것과 구별이 안 돼서 안
풀리는 문제 — `false`를 이벤트 disconnect 센티널로 쓴 선례처럼 `None`
(가칭) 프리미티브를 도입하는 방향만 `base/modifier-plan.md` "2-1"절에
짧게 메모해두고 상세 설계는 다음 세션으로 미룸.

## 2026-08-07 네 번째 세션 — `.claude/` 코퍼스 전반 정리(폴더 재편, 승격, 기각 분리)

사용자가 코퍼스 전체를 훑고 "실제 코딩에 필요한가"를 기준으로 남길 것과
분리할 것을 판단해 달라고 요청 — 여러 문서에 쌓인 역전 이력/quad
자체와 무관한 배경자료/이미 기각된 후보가 뒤섞여 있어 컨텍스트 크기와
가독성 둘 다 해치고 있다는 문제의식. 아래 6가지를 처리, 전부 반영 완료:

1. **`reference/` 폴더 신설** — `quad-v1-architecture.md`,
   `comparison-fusion-vide.md`를 `base/`에서 이동. 항상 읽어야 하는
   결정사항(`base/`)과, 다른 문서가 근거로 인용할 때만 열어보면 되는
   온디맨드 스냅샷/비교자료(`reference/`)를 분리 — 전자는 "결정 완료",
   후자는 "결정이 아니라 결정의 근거"라는 차이. 전체 문서의 상호참조
   경로도 전부 갱신함.
2. **`component-composition-plan.md`의 누적 역전 이력 트리밍** —
   `StoreSource` 프록시 폐기 이력이 "원래 이랬다 → 이렇게 뒤집혔다"를
   본문에서 장황하게 반복 서술하고 있었는데, 이미 `archive/
   store-source-proxy-reversed.md`에 원문·이유·비교표가 전부 보존돼
   있으므로 본문은 최종 확정만 남기고 포인터로 압축.
3. **`ui-shorthand-plan.md`를 `research/`→`base/`로 승격, 재작성** —
   (a) 이미지 라운드 트릭 `RoundSize`는 완전히 드롭, 근거는
   `archive/ui-shorthand-roundsize-dropped.md`로 분리(이 판단이 한 차례
   "Corner/PaddingAll/Scale 전체가 불필요하다"로 잘못 일반화됐다가
   정정된 이력도 같이 보존). (b) 이름을 v1 그대로(`Corner`/`PaddingAll`/
   `Scale`)가 아니라 실제 Roblox Instance 이름과 맞춘 `UICorner`/
   `UIPadding`/`UIScale`로 확정 — v1식 짧은 이름은 Modifier 체이닝
   메소드와 겹쳐 "진짜 UICorner 숏핸드인지 그냥 비슷한 이름의 부가
   Modifier인지" 구분이 안 된다는 사용자 지적 반영. (c) store-bind
   가능성 명시 — v1에서도 가능했던 기능이고, Tween처럼 무거운 API
   표면 없이 기존 per-instance weak-table 유틸(`base.perInstanceState`)
   재사용만으로 충분하다는 점을 추가.
4. **`additional-primitives-plan.md`를 4갈래로 분리**: 확정된 `Blocker`/
   `Effect`는 각각 새 `base/blocker-plan.md`/`base/effect-plan.md`로
   승격(Blocker는 State와 같은 마일스톤에서 개발하기로 해서
   `store-semantics.md`에 교차 참조 추가, `ROADMAP.md` M3에도 체크박스
   반영). 기각된 `Batch`(lexical block)와 `Context`(+대안이던 레이어드
   Store)는 각각 `archive/batch-rejected.md`/`archive/context-rejected.md`로
   분리. `research/additional-primitives-plan.md`엔 아직 실제로 열려있는
   것(키 기반 동적 컬렉션 재조정) 하나만 남김. **[같은 날 바로 정정]**
   처음엔 Blocker/Effect를 `base/additional-primitives.md` 한 파일로
   합쳐 승격했으나, 사용자가 "State 볼 때 Effect까지 볼 필요는 없다,
   기존 프리미티브당 1파일 컨벤션(`modifier-plan.md`/`slot-plan.md`류)에
   맞지 않는다"고 지적해 바로 두 파일로 재분리함 — Blocker는
   Store/State와 밀접해 교차 참조가 필요하지만 Effect는 완전히 독립된
   요소라 애초에 같은 파일일 이유가 없었음.
5. **archive 제목 컨벤션을 둘로 분화** — 기존 `[역전됨]`(한 번 확정했다가
   뒤집힌 것, `store-source-proxy-reversed.md`/`ref-phase-option-reversed.md`)과
   새로 생긴 `[기각됨]`(확정한 적 없이 후보였다가 채택 안 된 것,
   `batch-rejected.md`/`context-rejected.md`/`ui-shorthand-roundsize-dropped.md`)을
   구분 — `README.md`의 `archive/` 폴더 기준 설명에 두 컨벤션 차이를
   명시.
6. **`tween-plan.md` 보강** — `retract`가 Destroy 시엔 호출 안 된다는
   사실을 상단 상태 요약에서도 짚도록 가시성 강화, `canExecute`(Destroy
   시 처리)와 `retract`(값 교체 시 처리)가 서로 다른 문제를 다룬다는
   점을 quadnomicon급 문서화 숙제로 메모(지금은 상세 설명 안 하고
   메모만). 트윈 옵션 값 모양(raw `TweenInfo` vs 이름 붙은 편의
   필드+기본값) 논의를 새로 열어둠 — Luau가 named call을 지원 안 해서
   `TweenInfo.new(...)` 포지셔널 생성자가 읽기 어렵다는 문제의식,
   소견은 편의 필드 쪽이지만 확정 아님, 나중 논의 대상으로만 남김.

## 2026-08-07 다섯 번째 세션 — Modifier 결합(`Override`)/읽기 접근자(`Peek`)/`isState` 확정, FuncSource 기각 사유 문서화

**출발점**: `:Apply`(4번째 세션 신설)처럼 Modifier에 더 있으면 좋을 게
있는지 사용자가 제기 — `Merge`류 결합 유틸의 우선순위 문제, 그리고
Modifier 자신이 자기 필드 값을 못 읽는 게 애매하다는 지적(예:
`Boldify`가 폰트별 굵기 보정을 하려면 현재 `Font` 필드를 읽어야 함).
같은 스레드에서 "Source가 항상 정해진 값만 담아야 하는 이유가 확정된
건지, FuncSource(람다로 계산+self-emit하는 Source) 같은 건 왜 없는지"도
같이 물어옴.

**핵심 결론(전부 base 문서에 반영 완료)**:
- **`Modifier.Override(mod1, mod2, ...)`** — `component-composition-plan.md`
  3번 절에 2026-08-04부터 가칭 `Merge`로 이미 확정돼 있던 결합 유틸의
  실제 동작을 확정하고 이름을 `Override`로 개명(중립적 "합침"이 아니라
  명시적 "덮어쓰기"라 이름이 의미를 정직하게 반영해야 함). 뒤 인자가
  필드 단위로 이김(기존 배열 flatten 규칙 재사용), 구현은 단순 필드별
  raw 교체 — setter가 이미 호출 시점에 함수/State를 즉시 처리해 저장하므로
  Modifier 필드는 항상 baked 값이라 특별한 분기 불필요. "baked 값 교체는
  거기서 파생된 다른 필드에 소급 반영 안 됨"(Boldify가 FontWeight를 계산해
  둔 뒤 Font가 Override로 바뀌어도 FontWeight는 예전 값 그대로)과 순서
  의존성(`A:Override(B)` ≠ `B:Override(A)`) 둘 다 문서 경고 대상으로 확정.
  **`Apply`로 전부 대체해 `Override`를 없애는 방안도 검토했으나 기각** —
  컴포넌트 경계(`props.Modifier`는 단일 named parameter라 배열 flatten이
  안 닿음)라는 이미 확정된 실사용 니즈를 `Apply`만으로는 못 풀어서.
  `base/modifier-plan.md` 9번 절.
- **`:Peek<<T>>(key): T|State<T>|nil`** — Modifier 필드를 확정(pull+recompute)
  하지 않고 raw 그대로 읽는 접근자. `Get`이 아니라 `Peek`인 이유는 이
  프로젝트에서 `State:Get()`이 이미 "확정한다"는 의미로 굳어져 있어서 —
  Modifier의 읽기는 정반대(State면 State 핸들 그대로) 동작이라 같은
  동사를 못 씀. 반환 타입을 `T`로 자동 확정하지 않고 union 그대로
  노출하는 이유는 4-1번 절 함수형 setter의 `old` 인자와 같은 원칙("현재
  저장된 그대로 넘김") 재사용 — 자동 확정하면 타입에 안 드러나는 채로
  반응성이 조용히 끊김. `.RealValue` 같은 별도 인덱싱 표면은 기각(이미
  `__index`가 setter 합성용으로 예약돼 있어 표면이 겹침).
- **`isState(x): boolean`** — `Peek`의 raw union을 분기하려면 필요.
  Source가 State를 구조적으로 만족하므로 이거 하나로 Source도 같이
  잡힘(`isSource` 불필요). duck-typing 대신 weak-key 레지스트리로 구현
  (rbvm 네임스페이스 추적과 같은 패턴 재사용) — `Peek`가 돌려주는 `T`가
  임의의 테이블/userdata일 수 있어 duck-typing은 false positive나 일부
  Roblox userdata의 인덱싱 에러(pcall 필요)로 이어질 위험이 있음. 이
  판별 로직 자체는 새 개념이 아니라 4-1번 setter가 이미 내부적으로
  해야 했던 "필드가 State냐 plain이냐" 판별을 public 유틸로 승격한 것.
  `base/bind-system-plan.md`의 `isState` 절.
- **FuncSource(값이 람다로 계산되고 self-emit하는 Source) 기각** — 사용자가
  스스로 기각 논리를 제시했고("이미 Compute가 커버함"), 검증 결과 이미
  확정된 두 원칙에서 그대로 연역됨: (1) Source는 "시작점"이라 다른
  반응형 값에 자동 연결 안 됨(2026-08-04 6차 라운드, "Store가 Store를
  담지 않는다" 확정 때 나온 원칙) — FuncSource는 다른 반응형 값에 종속된
  계산이면서 겉으로는 origin인 척하는 것이라 이 원칙과 직접 충돌.
  (2) `:With`가 clone 빌더가 아니라 진짜 노드여야 하는 이유(2026-08-07
  세 번째 세션)가 "의존성이 구조적으로 안 보이면 디버그 그래프가
  깨진다"였는데, FuncSource의 람다가 클로저로 캡쳐한 의존성은 정확히
  그 문제를 재현함. 실제로 커버 안 되는 유스케이스도 없음 — "다른
  반응형 값에서 계산"은 `Compute`, "clone 불가능한 값을 밖에서 바꾸고
  알림"은 원천 Source+`Emit`으로 이미 전부 커버됨. 새 결정이 아니라
  기존 확정 사항의 논리적 귀결이라 별도 base 절 신설 없이 여기 세션
  요약으로만 기록(quadnomicon 소재로 재사용 가능하도록).

**같은 세션 바로 후속 — 문서화 톤 보강(사용자 강조)**: `Override`는 범용
조합 도구가 아니라 `Frame{mod1, mod2}`의 컴포넌트 경계판(단일 named
parameter 슬롯에 독립적으로 만들어진 값 두 개 이상을 넣어야 하는 특수
상황)으로 좁게 문서화할 것 — "특정 modifier를 계속 바꿔나간다"는 요구는
항상 `Apply` + 커링/일급 함수 전달을 기본 관용구로 유도. `Apply` 자체도
`factory(self)` 호출 sugar 그 이상이 아니라는 걸 명시 — `factory`가
`Peek`한 값이 기대와 다르면 `error`를 던지든 뭘 하든 전부 `factory`
저작자 책임, `Apply`가 검증/보장을 대신 해준다고 오해하면 안 됨. 둘 다
`base/modifier-plan.md` 8/9번 절에 반영 완료.

**같은 세션 두 번째 후속 — `Apply` vs `Override` 성능 기준 확정.**
"무거운 Modifier를 대량 생성할 때 `Apply`의 clone 비용이 누적되지
않냐"는 우려에서 두 방안 검토 후 결론: **`Apply`를 mutable로 바꾸는
방안은 기각**(3번 절 immutable 확정 이유 — 형제 서브트리 오염 방지 —
가 clone 비용 절감보다 우선순위 높음, 재확인). 대신 **판단 기준을
"이질적/동질적 프로퍼티"가 아니라 "필드 간 계산 의존성 유무"로
명확화** — 한쪽이 `Peek`으로 다른 쪽의 baked 값을 읽어 반영해야 하면
이질적으로 보여도 `Apply`, 서로 완전히 독립이면 동질적으로 보여도
`Override` 가능. 계산 의존성 없는 재사용 조각(배경/텍스트/레이아웃처럼
서로 다른 서브시스템이 한 번만 만드는 값)은 모듈 상수로 만들어두고
인스턴스마다 `Override`로 결합하는 게 실제 최적화 패턴 — 단 이건
"`Override`가 내부적으로 캐싱해준다"가 아니라 사용자가 값을 재사용하는
평범한 패턴일 뿐, 라이브러리에 새 캐싱 레이어가 생기는 게 아님을
문서에 명시하기로 함. `base/modifier-plan.md` 9-1번 절.

**같은 세션 세 번째 후속 — "`Apply` 경계에서만 clone, 안쪽은 mutable"
절충안도 검토 후 기각.** clone 횟수를 체인 길이가 아니라 `Apply` 호출당
1번으로 줄이는 절충을 사용자가 직접 제시했으나, `Apply`를 거치지 않고
setter를 단발로 직접 호출하는 흔한 경로는 여전히 mutable이라 공유
레퍼런스가 그대로 오염될 수 있음(서브트리에서 폰트 두께만 바꿔도 터짐)
— "어디서 터지느냐만 달라지는" 비일관적 절충이라 실익 없다고 판단해
기각. 전부 clone하는 현재 방식 유지 확정. `base/modifier-plan.md`
9-1번 (a-1) 절.

**같은 세션 네 번째 후속(당시 CLAUDE.md에 미기록 — 2026-08-07 여섯 번째
세션에서 뒤늦게 발견/보강) — `Override`가 서브타입 관계인 Modifier끼리
섞일 때의 타입 시그니처는 미검증으로 열어둠.** `FrameModifier`가
`GuiObjectModifier`의 서브타입이어야 자연스러운데, 필드 setter 메소드의
리턴 타입이 각자 자기 자신이라(`self`) 단순 구조적 서브타이핑만으로
`Modifier.Override(guiObjectMod, frameMod)`류가 통과하는지 추론만으로는
결론 못 냄 — 후보안(메소드 필드는 `any`로 뭉개고 데이터 필드만 구조적
체크)을 실 Luau로 검증 필요, 안 되면 `Override(...: any): any`로
느슨하게 열고 이 항목으로 되돌아오는 걸 fallback으로 남김.
`base/modifier-plan.md` 9-2번, `ROADMAP.md` M7에 체크박스 반영 완료.

**다음 세션이 할 일**: 안 바뀜(위 2026-08-06 네 번째 세션 절 참고,
`ROADMAP.md` M0부터) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위
자체는 그대로.

**미해결로 남긴 것 — 임의로 결론내지 않음**: Effect가 `state:Effect()`
형태로 Observer를 확장하는 변형인지, 완전히 독립된 free function인지가
불명확함(사용자가 "확인 필요, 아니라면 논의해야 할 상태로 남겨두라"고
명시). 관련 하위 질문으로 `state:Observer(fn)`가 생성 시 `fn`을 즉시
1회 실행하는지도 문서 어디에도 명시돼 있지 않음이 이번에 드러남(Effect는
"즉시 1회 실행"이 스펙에 명시돼 있어 이 부분만 보면 둘이 겹쳐 보임).
`base/effect-plan.md`의 "미해결" 절과 `.claude/question.md`
0번에 반영 — 구현 착수(M3~M4 전후) 전에 반드시 재확인할 것.

**다음 세션이 할 일**: 안 바뀜(위 2026-08-06 네 번째 세션 절 "다음 세션이
할 일" 참고, `ROADMAP.md` M0부터). 이번 세션은 순수 문서 정리라 설계
결정 자체는 늘지 않았음 — 단, M3 체크리스트에 `Blocker.luau` 항목이
하나 추가된 것과, 위 Effect/Observer 미해결 항목은 M3~M4 착수 전에
확인해야 함.

## 2026-08-07 여섯 번째 세션 — Ref/PreRef 메소드 API 확정, 파일 분리, Tween GC 저장 구조 확인, Effect/Observer 관계 해소

사용자가 메모 형태로 두 가지를 던짐: (1) Tween 인스턴스를 per-instance
저장소에 담는 구조가 실제로 GC-안전한지, (2) Ref가 이제 충분히 완결된
프리미티브이니 PreRef와 파일을 분리하고, `:Set`/`:Callback`/`:Wait`
세 메소드로 API를 굳히자는 제안(전부 mutation 패턴이라 자기 자신을
반환). 둘 다 검증 후 반영 완료:

- **Tween per-instance 저장소는 이미 확정된 구조 그대로 GC-안전함** —
  `inst`로 weak-keyed된 바깥 릴레이션 안에 `k`별 안쪽 릴레이션이 중첩된
  모양이라(`base.perInstanceState(inst)`), `inst`가 죽으면 중첩된 Tween
  인스턴스 릴레이션도 별도 정리 없이 같이 GC됨 — 새 결정 아니라 기존
  설계(`bind-system-plan.md` "핸들러 내부 상태 저장" 절)의 확인, "왜
  GC-안전한가" 설명만 명시적으로 추가.
- **Ref API가 `.Value`(읽기 전용) + `:Set(value)`/`:Callback(fn)`/
  `:Wait(thread?)`(전부 self 반환)로 확정.** self-반환 덕에
  `if ref.Value then ref.Value else ref:Wait().Value` 관용구가 성립 —
  이걸 성립시키려고 `:Set()`이 `coroutine.resume`할 때 넘기는 인자를
  기존 문서(세 번째 세션 원안)의 `value`에서 **`self`**로 정정함(안
  그러면 `:Wait()`의 yield 리턴값에 `.Value`를 체이닝할 방법이 없었음).
  `:Wait(thread?)`의 `thread` 인자는 생략 시 `coroutine.running()`을
  캡처해 진짜로 yield하고, 명시적으로 넘기면 그 thread를 등록만 하고
  yield 없이 즉시 `self` 반환(코루틴 역학상 남의 thread를 여기서 대신
  정지시킬 수 없어서) — 사용자가 직접 관리하는 스케줄러가 이미 어딘가서
  정지시켜 둔 thread를 등록만 해두고 호출부는 안 블록되고 싶은 유스케이스.
  콜백은 여전히 raw 값을 받음(Ref 자신이 아니라).
- **파일 분리**: `Ref`는 그 자체로 완결된 프리미티브, `PreRef`도 "children
  배열 전용, 위치 무관 호이스팅"이라는 특이한 제약을 가진 별개
  프리미티브라 기존 1프리미티브-1파일 컨벤션(Blocker/Effect 분리와
  같은 이유)을 따라 `Ref.luau`/`PreRef.luau`로 쪼갬 — 런타임은 여전히
  공유(`PreRef`가 `Ref`를 재사용, 브랜드 태그만 다름), `base/architecture.md`
  소스트리에 반영 완료.
- 전부 `base/bind-system-plan.md`(Ref/PreRef 절)와 `research/tween-plan.md`에
  반영 완료. `.claude/question.md`엔 이미 반영돼 있던 "Ref 이름 자체는
  용어 정리 대상" 항목과 모순 없음(이번 세션은 메소드 이름만 확정, Ref라는
  타입 이름 자체는 여전히 가칭).

**같은 세션 후반 — `.claude/question.md` 0번의 마지막 미해결 항목(Effect가
`state:Effect()`인지 자유 함수인지) 해소.** 사용자가 직접 "정해볼까" 하고
제기해 라이브로 논의, 다음으로 확정(전부 `base/effect-plan.md`/
`base/bind-system-plan.md`에 반영):

- **`state:Observer(fn)`는 등록 즉시 1회 실행되는 것으로 확정** — 근거:
  (1) 이미 채워진 State를 나중에 구독하면 반영 연산이 아예 한 번도 안
  일어나는 초기화-순서 디버깅 문제, (2) 초회 실행을 안 해야 할 구체적
  근거가 약함, (3) 이러면 Observer 하나로 "초기값 적용"과 "이후 변경
  반영"이 같은 코드 경로로 통일됨(store-bind 프로퍼티 핸들러가 최초
  적용용 코드를 별도로 안 짜도 됨).
- **`Effect(fn, state?) -> EffectHandle`로 확정** — `state` 생략 시 기존
  스펙 그대로(설치 1회 + leaf 죽을 때 확정 정리, 재실행 없음). `state`
  지정 시 **내부적으로 `state:Observer(...)`를 조합** — Observer가 이제
  즉시 1회 실행되므로 그 첫 실행이 설치를 겸하고, 이후 무효화마다
  직전 cleanup 호출 후 `fn` 재호출, leaf 사망 시 마지막 cleanup 1회 —
  React `useEffect(fn, [dep])`와 동형. 다수 의존성은 `:With(...)`로 먼저
  하나의 State로 묶어서 넘기는 쪽으로 확정(React식 별도 deps 배열
  안 만듦 — 같은 일 하는 두 번째 경로 방지 원칙). Effect는 여전히
  자유 함수(메소드 아님) — `state` 없이도 성립하는 유스케이스가 있고,
  있어도 leaf 생명주기 바인딩을 `state`가 소유하지 않아서.
- **예전에 기각했던 "Observer에 cleanup 반환 계약 추가"와 안 부딪힘** —
  그때 기각한 건 "Observer 자체에 이 복잡도를 넣지 말자"였지 패턴 자체가
  무용하다는 게 아니었음. Effect가 opt-in 상위 계층으로 이 패턴을 제공하는
  지금 구조가 그 기각과 정확히 양립함.
- **`fn`을 커링 스타일(팩토리가 실제 fn을 만들어 반환)로 짜는 것도 Effect/
  Observer 둘 다 모듈화 관용구로 권장** — `Modifier`의 `Boldify(10)` 커링과
  같은 결.
- **백로그로만 기록, 결정 안 함**: `state:Apply(...)`처럼 여러 개를 커링으로
  받아 `:With`/`:Compute` 등록을 자동화하는 조합기 아이디어(사용자 제안,
  `Modifier:Apply`의 State판 대응물) — `base/bind-system-plan.md`에 백로그
  절로만 남김, 시그니처/필요성 미검증. **(2026-08-07 일곱 번째 세션에서
  이 방향 자체가 기각되고 훨씬 단순한 형태로 확정됨 — 아래 참고.)**
- 이걸로 `question.md` 0번(추가 프리미티브 논의)의 열린 항목은 "키 기반
  동적 컬렉션 재조정" 하나만 남음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 이미
설계된 것의 세부 마무리라 M0 착수 우선순위 자체는 그대로.

## 2026-08-07 일곱 번째 세션 — `:Compute` 커링, `state:Apply` 확정(백로그안 기각), Effect `:Subscribe`/`:Unsubscribe` 신설, 이중 바인딩 금지

짧은 대화형 세션, 네 가지를 순서대로 처리 — 전부 `base/bind-system-plan.md`/
`base/effect-plan.md`/`ROADMAP.md`/`question.md`에 반영 완료:

1. **`:Compute(fn)`에도 커링 권장 노트 추가.** 여섯 번째 세션에서 Observer/
   Effect의 `fn`에만 문서화됐던 "팩토리가 실제 `fn`을 만들어 반환하는
   커링 스타일 권장"이 `:Compute`엔 빠져 있었음 — 같은 결이라 자연스럽게
   확장, `bind-system-plan.md` "`:With`+`:Compute`" 절에 추가.
2. **`state:Apply(factory)` 확정 — 원래 백로그였던 "`:With`/`:Compute`
   등록을 커링으로 자동화하는 조합기" 방향은 기각.** 사용자가 재확인한
   실제 의도는 훨씬 단순함: `Modifier:Apply`와 똑같이 `factory(self)`를
   체이닝 문법으로 부르는 순수 설탕(`function(self, factory) return
   factory(self) end`) — `fnb(c,d)(fn(a,b)(state))`처럼 팩토리를 안에서
   밖으로 겹쳐 읽어야 하는 중첩을 `state:With(a,b):Compute(fn(a,b))
   :Apply(fnb(c,d))`로 펴는 게 유일한 목적. 구현 비용 거의 0(State는
   Modifier와 달리 제네릭 `__index` 필드 setter 합성이 없어 이름 예약
   충돌도 없음), 타입은 `factory: (State<T>) -> U): U`로 Modifier보다
   더 열어둠(팩토리가 State 밖 plain 값을 반환해 반응형 그래프를 벗어나는
   것도 허용). Source는 기존 `:With`/`:Compute` 델리게이션에 얹혀 자동
   포함. `bind-system-plan.md` "`state:Apply(factory)`" 절, 구체 전/후
   코드 예시까지 반영. 부수적으로 같은 헤더 아래 잘못 걸려 있던 Observer
   `:Subscribe`/`:Unsubscribe` 내용(무관한 주제)을 별도 절로 분리하는
   문서 버그도 수정.
3. **`EffectHandle:Subscribe()`/`:Unsubscribe()` 신설.** 지금까지 Effect의
   유일한 생애주기 경로는 children 배열 leaf 부착뿐이라, leaf 없이 쓰는
   모듈/스크립트 레벨 사이드 이펙트(백그라운드 시스템 등)엔 반환된
   `EffectHandle`이 막다른 길이었음 — Observer가 이미 가진 `:Subscribe`/
   `:Unsubscribe`와 같은 결로 확정. **핵심 주의점**: Effect의
   `:Unsubscribe()`는 Observer의 것을 그냥 위임하면 안 됨 — Observer의
   계약은 "미래 재실행만 끊는다"로 충분하지만, Effect의 계약은 "생애주기가
   끝나는 시점에 마지막 cleanup이 정확히 1회 호출된다"이고 leaf 사망은
   그 "끝"의 신호 중 하나일 뿐이라, `:Unsubscribe()`도 동일하게 "지금
   끝났다"는 신호로 취급해 마지막 cleanup을 트리거해야 계약이 일관됨(leaf
   가 살아있어도 마찬가지). idempotent 보장은 기존 `Subscribed` 필드
   liveness 체크 재사용으로 공짜. `base/effect-plan.md` 신규 절.
4. **Observer/Effect 이중 바인딩 금지 — `Bound`(가칭) 플래그로 즉시
   `error`.** 처음엔 "leaf 부착과 `:Subscribe()`를 동시에 써도 같은
   liveness 게이트를 공유하니 안전"이라고 적었으나, 사용자가 애초에 한
   핸들은 라이프사이클 바인딩 경로를 하나만 가져야 한다고 정정 — 동시
   바인딩은 UB로 확정하되, 판별 비용이 사실상 0(불리언 필드 하나)이라
   조용한 오동작 대신 그 자리에서 `error`를 던지는 쪽으로 결정
   (엔지니어링 비용 대비 디버깅 이득이 명확). 두 진입점(`:Subscribe()`
   호출부, children 배열 leaf 부착부)이 똑같이 확인/설정하는 대칭적 게이트
   — 순서 무관. `bind-system-plan.md` "이중 바인딩 금지" 절 신설,
   `effect-plan.md`의 3번 항목 서술은 이 규칙으로 대체(정정 표시 남김).

**부수 정리**: `ROADMAP.md` M3에 `state:Apply`/Effect `:Subscribe`·
`:Unsubscribe`/이중 바인딩 금지 체크박스 추가. `question.md`에 `Bound`
이름을 용어 정리 대상(3순위)으로 추가.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

## 2026-08-07 여덟 번째 세션 — `None` 센티널 확정(인라인 필드 지우기), `NoneHandler`가 Tween store-bind와 같은 재귀 재디스패치임을 확인

세 번째 세션에서 "미확정"으로 메모만 남겨뒀던 `None` 센티널
(`{ Override = nil, mod }`처럼 인라인 키로 modifier 값을 명시적으로
지우고 싶어도 Lua 테이블의 `키 = nil`이 "키 없음"과 구별 안 되는 문제)을
사용자가 "이거 결정할 게 진짜 있냐"고 다시 제기해 라이브로 짧게 논의,
확정까지 감. 전부 `base/modifier-plan.md`(2-1번)/`base/bind-system-plan.md`
(신규 절)/`base/ui-shorthand-plan.md`(신규 절)에 반영 완료:

- **merge/setter 쪽은 아무것도 안 바뀜** — `None`은 raw 저장 계층의 그냥
  평범한 실재값이라, 기존 merge 규칙("인라인 키 존재 시 무조건 우선",
  `Override`의 "뒤 인자가 필드 단위로 이김")이 손댈 것 없이 그대로 작동함.
  처음엔 "merge 시점에 키를 지운다"는 새 분기가 필요하다고 잘못 생각했다가,
  "값을 표현만 할 수 있으면 기존 규칙이 이미 다 해줌"이라는 걸로 정정.
  인라인 props 테이블 키(`{ TextColor3 = None, mod }`)와 Modifier setter
  인자(`mod:TextColor3(None)`) 둘 다 지원 — 메커니즘이 완전히 같아 구현
  비용 거의 0("어차피 무료로 얻어지는거 아님?" — 사용자), 후자 덕에
  "특정 필드만 지우는 재사용 가능한 modifier 조각" 패턴도 공짜로 됨.
  `:Peek()` 반환 타입도 `T | State<T> | None | nil`로 확장(raw 계층에서
  `None`을 있는 그대로 돌려줌 — Peek은 확정 안 하고 그대로 넘긴다는 기존
  9번 절 원칙 그대로).
- **실제 "지우기"는 디스패치 단계에서, 새 메커니즘 없이 풀림 — 핵심
  발견.** 처음엔 "우선순위 최상단에서 값을 그냥 nop 처리"로 생각했다가,
  사용자가 "그럼 process에 특수 로직이 들어간다"고 지적하며 더 나은 안을
  직접 제시: `NoneHandler`라는 평범한 pluggable 핸들러 하나를 추가 —
  `isHandlable`이 `v == None`을 잡고, `process`가 `v`를 진짜 `nil`로 바꿔
  **`process(inst, k, nil)`을 재귀 호출**. 이게 바로 이미 확정돼 있던 Tween
  store-bind 핸들러(`bind-system-plan.md` "확정된 디스패치 모델" 절,
  `v`가 Store면 `realv`를 계산해 `process(inst,k,realv)`로 재귀)와
  **완전히 같은 패턴**이라는 걸 확인 — 새 아키텍처 개념이 하나도 안 늘어남.
  base 드라이버 자체(`process(inst,k,v) -> getHandler(inst,k,v).process(...)`)는
  `None`을 전혀 모르는 순수 제네릭 그대로 유지, 개별 프로퍼티/이벤트/UI
  shorthand 핸들러 시그니처도 `None`이 안 나옴(원래 있어야 했던 "`v`가
  `nil`인 경우" 처리를 재사용할 뿐).
- **`None`의 의미는 "리셋"이 아니라 "이 조합 단계에서 이 필드를 세팅
  안 함"** — 실제로 `v=nil`을 받은 핸들러가 뭘 할지는 핸들러마다 다름(일반
  프로퍼티는 사실상 그대로 두는 것과 다름없고, UICorner 숏핸드처럼 실제
  Instance를 만들어 붙이는 핸들러는 그 자식을 지움). 구체 사례로
  `ui-shorthand-plan.md`에 UICorner 절 신설 — `process(inst,k,nil)`이
  만들어둔 `_quad_corner`류 자식을 직접 지움(이건 `retract`가 아니라
  `process` 자신의 로직 — `retract`는 "다른 핸들러가 키를 넘겨받는" 별개
  시나리오 전용, 이미 확정돼 있던 원칙 재확인), 값이 자주 `nil`↔숫자로
  토글되면 생성/제거 비용이 매번 든다는 캐비엇도 명시.
- **M2(디스패치 엔진) 착수 시 확인할 것 하나 새로 생김** — "이 키를 지금
  누가 담당 중인가" bookkeeping이 바깥 순회 루프가 아니라 `process` 호출
  자체 내부에서 갱신돼야 함. 안 그러면 값이 계속 `None`으로 유지되는 매
  사이클마다 "1차 매치는 `NoneHandler`, 재귀 호출 뒤 실제 담당은 다른
  핸들러"로 바깥 루프가 오판해 불필요한 `retract`가 반복 호출될 위험 —
  `ROADMAP.md` M2에 반영, `pre-implementation-audit.md`의 "이전 매치
  핸들러 추적" 항목과 같은 부류라 새 우선순위 등급 없이 거기 흡수.

**부수 정리**: `question.md`에서 "미확정"이던 `None` 항목을 해소로
제거하고, 이름 자체(`None`/`NoneHandler`)만 다른 가칭들과 같이 용어
정리 대상(3순위)으로 새로 추가. `ROADMAP.md` M7 체크박스를 "확정 완료"로
갱신.

**같은 세션 후속 — `Dispatch` 함수 네이밍 정리, `canExecute` 시그니처 정정,
Tag/Attribute 전용 문서 신설.** None 논의를 파고들다 디스패치 엔진 자체의
용어가 여러 군데서 흔들리고 있다는 게 드러나 바로 이어서 정리함. 전부
`base/bind-system-plan.md`/`base/lifecycle-pattern.md`/`base/tag-plan.md`
(신규)/`base/attribute-plan.md`(신규)/`ROADMAP.md`에 반영 완료:

- **제 실수 정정 — `canExecute`와 `isHandlable`은 다른 개념** (전체 경위는
  `archive/agent-mistake.md` 1번으로 옮김) — 결론만: `NoneHandler`가
  구현해야 하는 건 `isHandlable`이지 `canExecute`가 아님.
- **`Dispatch.getHandler`/`Dispatch.process`/`Dispatch.addHandler`/
  `Dispatch.drive`로 이름 공식화.** 원래 "확정된 디스패치 모델" 절은
  "스캔+실행"과 "매치된 핸들러 자신의 처리"를 둘 다 그냥 `process`라고
  불러 이름이 겹쳤던 게 혼동의 원인이었음 — `Dispatch.getHandler(inst,k,v):
  Handler?`(순수 스캔)와 `Dispatch.process(inst,k,v)`(오케스트레이터:
  getHandler → 이전 담당자 다르면 그 `retract` → 새 핸들러의 `.process`)로
  분리, Handler 자신의 필드는 계속 `process`/`retract`(이미 확정된 이름,
  재검토 대상 아님) — 겹침은 소유자 표기(`Dispatch.process` vs
  `handler.process`)로 해소, 새 이름 발명 안 함. **`Dispatch.addHandler(handler)`**
  도 신설 — concrete Handler를 우선순위 레지스트리에 등록하는 것도
  결국 quad-roblox가 `BaseModule`을 뮤테이션하는 시점에 해줘야 하는
  일이라(기존 "base 유틸은 인터페이스, 백엔드가 주입" 패턴과 같은 모양).
  **배열→해시 두 패스 순회 드라이버 자신은 `Dispatch.drive(inst,
  flattened)`로 확정** — 문서가 이미 이걸 비공식적으로 "base 디스패치
  드라이버"라 불러왔던 걸 그대로 동사화(`apply`는 기각 — "Dispatch를
  뮤테이션해서 결과를 낸다"는 어감이라 안 맞는다는 사용자 판단).
- **`canExecute` 시그니처 정정: `(handle) -> boolean`, zero-arg 아님.**
  `lifecycle-pattern.md`가 원래 `canExecute: () -> boolean`(바인딩마다
  클로즈오버된 람다)으로 적어뒀던 걸 정정 — 그러면 등록마다 클로저를
  새로 만들어야 해서 "base는 인터페이스만, quad-roblox가 `BaseModule`
  뮤테이션으로 실 구현 주입"이라는 이미 확정된 패턴과 안 맞음. 공유
  함수 하나가 되려면 "어떤 등록을 볼지" 가리키는 인자가 필요 —
  `canExecute(handle: LifetimeHandle): boolean`으로 확정. **quad-roblox
  구현 스케치(참고용, base 결정 아님)**: rbvm 패턴 재사용 — Instance당
  weak-keyed per-instance 저장소에 "gchold" 배열을 두고, 절대 발화 안
  하는 신호에 연결한 Connection의 콜백 클로저 안에 살려두고 싶은
  Observer를 업밸류로 캡쳐(콜백은 안 불려도 클로저의 업밸류는 안 죽음,
  `inst`가 GC되면 gchold 배열째로 같이 죽음). `canExecute(handle)`은 이
  Connection(류)의 `.Connected`를 확인. **미확인 세부사항으로 남긴 것**:
  Observer→Connection 역참조를 별도 weak 릴레이션으로 둘지 그냥 Observer
  테이블 안 평범한 필드로 넣을지(정적 해싱 필드 접근이 더 쌀 수 있음) —
  quad-roblox 구현 단계에서 실측 필요.
- **`Tag`/`Attribute`도 UICorner/Tween처럼 전용 문서가 있어야 한다는
  지적 — 맞아서 `base/tag-plan.md`/`base/attribute-plan.md` 신설.**
  둘 다 이미 `architecture.md`/`ROADMAP.md` M10에 파일로는 계획돼
  있었지만 "1 프리미티브 1 파일" 관례(Blocker/Effect/Ref/PreRef 분리
  선례)를 따르는 전용 설계 문서가 없었음 — 흩어져 있던 내용(Attribute의
  타입 파라미터화 논의 등)을 모으고, 오늘 확정된 `None`/`process`/
  `retract` 동작을 반영. **핵심 발견**: Tag/Attribute 둘 다 UICorner
  숏핸드와 같은 패턴(값이 뭐든 항상 같은 핸들러가 계속 담당, 추가/제거를
  `process` 자신이 처리)이라 **retract가 필요 없음** — "확정된 디스패치
  모델" 절이 원래 Tag/Attribute를 retract 필요 예시로 들었던 게 잘못이었음,
  바로잡고 "retract가 의미 있는 유일한 패턴은 매치되는 핸들러 *타입*
  자체가 사이클마다 바뀌는 경우(Tween↔일반 프로퍼티가 실사례)"로 좁힘.
  Attribute는 특히 깔끔한 사례 — Roblox `SetAttribute(name, nil)` 자체가
  네이티브하게 "지움"이라 `None→nil` 재디스패치가 특별 처리 없이 그대로
  맞아떨어짐.
- `.claude/README.md`에 두 신규 문서 반영, `ROADMAP.md` M2/M10 체크박스
  갱신(`Dispatch` 4개 함수, `canExecute` 시그니처, Tag/Attribute 문서
  참조).

**같은 세션 세 번째 후속 — `canExecute` 옵션 하나 더 검토 후 확정 유지,
`Brand` 통합 판별 메커니즘 신설(`isState`를 10종으로 일반화), `isHandlable`도
`inst`를 받도록 정정.** 전부 `base/bind-system-plan.md`(`Brand` 절, 핸들러
계약 절)/`base/modifier-plan.md`/`ROADMAP.md`/`question.md`에 반영 완료:

- **`canExecute`를 "각 핸들 타입이 직접 구현"(`Observer.canExecute`)할지
  "공유 함수"(`canExecute(any)->boolean`)로 할지 재확인 — 공유 함수 유지,
  솔직한 이유까지 명시.** `Observer` 자체는 quad-base 레벨(엔진 무관)
  타입인데 liveness 체크(Connection 기반)는 본질적으로 엔진 종속적이라,
  `Observer.canExecute`가 직접 구현하면 base/roblox 분리 원칙이 깨지거나
  결국 내부적으로 공유 함수를 다시 호출하는 얇은 래퍼가 될 뿐 — 어느
  쪽이든 공유 함수 쪽이 낫다는 결론 재확인(추가 논의 없이 유지).
- **`Brand` 신설 — `isState`(다섯 번째 세션)를 quad의 다른 branded 타입
  전부(`Observer`/`Effect`/`Tag`/`Attribute`/`Tween`/`Blocker`/`Store`/
  `Source`/`Slot`)로 일반화.** 공유 weak-key 레지스트리 하나(`Brand.set`/
  `Brand.get`) + **문자열이 아니라 테이블 아이덴티티를 태그로 사용**
  (사용자 제안 — Luau 인터닝 문자열도 이미 O(1) 포인터 비교라 성능 차는
  없지만, 오타 안전성이 실질 이득: 잘못된 변수 참조는 즉시 드러나지만
  오타난 문자열 리터럴은 조용히 어긋남). `isX`는 `Brand`를 감싼 얇은
  wrapper — 단순 항등(`isObserver`)과 집합 멤버십이 필요한 경우(`isState`
  = `{State,Source}`)로 갈림. **`None`만 예외 — 싱글턴이라 레지스트리
  없이 `x == None` 항등 비교가 더 싸고 정확**, 대신 `Brand.get`이 범용
  introspection 창구(quad-debug 용도) 역할까지 겸하도록 `None`을 특수
  분기로 앞단에서 걸러줌 — `isNone`이 그 분기의 실제 구현체.
- **정정 — `isSource`는 별도로 필요함, 다섯 번째 세션의 "불필요" 서술을
  뒤집음** (전체 경위는 `archive/agent-mistake.md` 2번으로 옮김) — 결론만:
  `isSource`를 별도 제공, `isState`는 여전히 `{State,Source}` 둘 다 통과.
- **Luau 타입 narrowing은 자동으로 안 됨 — 사용자가 직접 확인, 명시적
  `::` 캐스팅 필요.** `isX(v)`가 참이어도 Luau가 TypeScript의 `x is T`
  같은 사용자 정의 타입 가드를 지원 안 해서 `v`의 정적 타입을 자동으로
  안 좁혀줌 — `if isState(v) then local s = v :: State<any> ... end`처럼
  런타임 검증 뒤 명시적 캐스팅이 실제 패턴. 여전히 duck-typing보다 훨씬
  안전하니 가치는 있지만 자동 narrowing을 기대하면 안 됨.
- **`isHandlable`도 `inst`를 받도록 확정 — `(inst,key,value): boolean`,
  원래 `(key,value)`였던 걸 정정.** `process`/`retract`는 처음부터
  `inst`를 항상 받았는데(핸들러 계약 원 원칙) `isHandlable`만 예외였던
  게 애초에 약간의 불일치 — 지금 당장 `inst`로 매치가 갈리는 케이스는
  없지만, 나중에 필요해지면 핸들러 계약 자체를 깨는 breaking change가
  되므로 지금 넣어두는 게 훨씬 쌈. `Dispatch.getHandler`가 스캔 중
  `handler.isHandlable(inst,k,v)`로 호출하도록 갱신.
- `ROADMAP.md` M2에 `Brand.luau` 체크박스 신설, `Handler.luau`/M7의
  `isState` 항목 갱신. `question.md`에 `Brand` 이름(용어 정리 대상,
  "OOP 클래스명을 얻는 느낌"에 맞는 더 나은 이름 필요 — `Tag`는 이미
  quad-roblox에서 다른 뜻으로 쓰여서 충돌) 반영.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

## 2026-08-07 아홉 번째 세션 — 코퍼스 전체 정합성 감사·수정, `agent-mistake.md`
신설, `CreatedRef` 이름 완전 폐기

여러 세션에 걸쳐 쌓인 stale 참조/자기모순을 서브에이전트 5개 병렬 감사로
찾아내 전부 수정하고(커밋 `98bd46a`), 이어서 사용자가 직접 발견한 남은
문제(`CreatedRef` 이름 자체가 더 이상 존재할 이유가 없다는 지적)까지 처리한
세션. 세 부분으로 나눠 요약:

**1. 코퍼스 정합성 감사·수정 (커밋 `98bd46a`)**: `CreatedRef`의 `phase`
옵션 폐기가 `bind-system-plan.md` 안에서 세 곳 중 두 곳에 방치돼 있던 것,
`question.md`의 `Ref` 재검토 대상 여부 자기모순, UICorner 숏핸드 개명이
5개 문서에 전파 안 된 것, `canExecute(handle)` 시그니처 정정이 막 확정된
직후라 두 곳에 전파 안 된 것, `architecture.md`/`ROADMAP.md`/`CLAUDE.md`의
stale 문구·누락 참조 등 12개 항목을 수정. `store-semantics.md` 제목도
"State는 **Store** 위의 캐시 레이어"에서 "State는 **Source** 위의 캐시
레이어"로 정정(사용자 확인: Source 단독 존재 가능 + Store는 Source들의
집합이라는 온톨로지가 맞음). `slot-plan.md`의 CRUD 의미론 갭 하나만
사용자가 다음 세션에서 직접 다루기로 보류.

**2. `archive/agent-mistake.md` 신설** — 설계 반전(`*-reversed.md`)/기각
후보(`*-rejected.md`)와 구분되는 세 번째 archive 카테고리: 에이전트가
문서 작성 중 스스로 낸 개념 혼동을 같은 세션 안에서 정정한 사례 전용
(`canExecute`/`isHandlable` 혼동, `isSource` 불필요 오판 2건). CLAUDE.md
세션 로그에 전체 경위가 장황하게 남아있던 것 중 최종 결론이 이미 `base/`
문서에 반영돼 중복이던 걸 옮기고 포인터만 남김 — 앞으로도 비슷한 사례가
생기면 여기로 옮길 것(사용자 확인).

**3. `CreatedRef` 이름 완전 폐기 — 사용자가 직접 발견.** "Ref가 이미 다
정해진 것 같은데 `CreatedRef`는 이제 없는 말 아니냐"는 지적: `Source(default)`/
`Ref(default)`/`Store({defaults})`가 이미 Kotlin Compose식 "타입 이름
자체가 팩토리 함수" 생성자 스타일로 확정돼 있었는데(2026-08-06 네 번째
세션), `CreatedRef(fn)`라는 별도 래퍼 이름만 그 확정 이전(2026-08-04,
Ref가 아직 "instance 얻는 통로"로 좁게 정의됐던 시절)의 잔재로 계속
남아있었던 것 — 실제로는 `Ref(default)`(또는 `PreRef(default)`)
인스턴스 자체를 children 배열 숫자 슬롯에 그대로 놓으면 `(v=Ref)` 매치
핸들러가 처리하므로, 별도 래퍼 함수가 있을 이유 자체가 없었음. `base/
bind-system-plan.md`(바인드 방법 절 재작성, "CreatedRef와의 관계" 절
삭제, "phase 옵션 폐기" 절/열린질문 절 정리) · `ROADMAP.md`(M0/M8 체크
박스) · `question.md`(용어 재검토 목록에서 제거, 해소로 표시) ·
`architecture.md`(소스트리 주석) · `research/documentation-content-map.md`
전부 동기화 완료. `archive/ref-phase-option-reversed.md`(phase 옵션
자체의 역전 이력)와 CLAUDE.md 이전 세션 로그의 `CreatedRef` 언급은
당시 기록으로서 정확하므로 그대로 둠 — 역사적 서술과 현재 유효한 설계를
헷갈리지 않도록 "phase 옵션 폐기" 절 제목에 "이 절이 당시 쓰던 이름
자체도 이후 폐기됨" 포인터만 추가.

**부수 작업 — `PreRef`/`Modifier`의 "pre-hook" 태깅 요청 처리.** 같은
세션 앞부분에서 사용자가 "PreRef와 Modifier는 문서화 시 pre-hook 태그가
필요해 보인다, hook과 pre-hook의 차이(취소 가능/순서 등록 가능)도 적어
두면 좋겠다"고 제안 — 이건 런타임 설계가 아니라 문서 사이트 콘텐츠
분류 아이디어라 base/에 "확정"으로 못박지 않고 `research/
documentation-content-map.md`(심화 콘텐츠 후보 6번 + "문서화 아직 보류"
목록)에 사용자 원문 프레이밍 그대로 미확정 표시로 남겨둠 — `PreRef`가
"인스턴스에 뭐가 일어나기 전에 채워진다"는 사실 자체는 이미 확정
서술돼 있었지만(재확인 후 "메모에서 지워도 됨"으로 답변), "hook"/
"pre-hook" 용어 채택 여부·`PreRef`의 취소 가능성·복수 `PreRef` 간 순서는
다음에 사용자가 직접 정해야 base/로 승격 가능. **[정정, 2026-08-07 열
번째 세션]** 같은 대화에서 "Ref 콜백/대기자 배열은 압축 없이 `self[i]
= nil`로만 지워도 된다"는 설계가 이미 정확히 반영돼 있다고 여기 적었던
건 틀림 — 실제로는 `nil`이 아니라 `None`으로 지워야 함(아래 열 번째
세션 절 참고), 이때는 아직 발견 전이었음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). `slot-plan.md` CRUD
의미론과 "hook/pre-hook" 프레이밍 확정만 사용자가 직접 다룰 후보로 남음.

**같은 세션 후속 — `PreRef` pre-pass 구현 위치·복수 `PreRef` 순서·동적
경로 가드 확정.** 사용자가 구체적인 구현 방안 세 개를 직접 제시:

1. **복수 `PreRef` 간 순서는 배열 index 순서 그대로** — 별도 규칙 발명
   불필요, 위 "props 순회 순서" 절이 이미 확정한 "배열 파트는 index
   순서대로" 계약을 그냥 재사용하면 됨. 호이스팅은 "PreRef 대 나머지"
   에만 적용되는 규칙이지 "PreRef끼리"엔 적용될 게 없음.
2. **pre-pass가 사는 곳 — 새 `Dispatch.*` 함수 대신 이미 확정된
   `Dispatch.drive(inst, flattened)` 자신.** 사용자가 두 대안을 직접
   제시(`Dispatch.process(inst, flatten, prerefs)`류 신설 함수 vs
   `flatten(inst, nonFlatten)` 함수 자체에 얹기) — 검토 결과 둘 다
   불필요/위험함이 드러남. 전자는 이미 `Handler.process`/`Dispatch.process`
   이름이 다른 뜻으로 확정돼 있어 겹침. 후자(flatten에 얹기)는 사용자가
   "가장 간단해 보인다"고 제안했지만, `research/existing-instance-bind-plan.md`가
   다루는 "이미 마운트된 Instance 재바인드 시 flatten을 다시 해야
   하는가"라는 열린 질문이 실제로 flatten이 한 인스턴스 생애주기 동안
   여러 번 재호출될 가능성을 열어두고 있어서, 거기 PreRef fire를 얹으면
   재바인드마다 PreRef가 또 fire되어 "이 인스턴스 하나의 construction
   훅"이라는 정의 자체가 깨짐 — 기각. `Dispatch.drive`는 최초 마운트
   시 한 번만 불리는 게 이미 전제라 이 위험이 없어서 그대로 거기 좁은
   pre-pass 한 줄만 얹으면 충분.
3. **동적 경로로 도착한 `PreRef`는 런타임에도 명시적으로 error —
   지금까지 타입 차단만 문서화돼 있던 빈틈을 채움.** 사용자 제안
   그대로 채택: `{isHandlable = v is PreRef, process = error(...)}`
   전용 Handler를 정상 우선순위 레지스트리에 등록(`NoneHandler`와 같은
   "한 값 종류 전담" 패턴, 새 메커니즘 아님). 리터럴 배열의 `PreRef`는
   pre-pass가 fire와 동시에 슬롯을 소진시켜 정상 두 패스에 다시
   노출되지 않으므로, 이 Handler가 실제로 매치되는 경우는 타입 차단을
   어떻게든 우회한 버그 케이스뿐 — no-op이 아니라 즉시 `error`가 맞음.

전부 `base/bind-system-plan.md` "PreRef" 절에 반영, `ROADMAP.md` M8
체크박스 갱신, `research/documentation-content-map.md`의 "복수 PreRef
순서" 미정 표시 제거(해소됨, "취소 가능성"만 계속 미정으로 남김).

**같은 세션 두 번째 후속 — "호이스팅이 물리적 재배치가 아니라 별도
선행 스캔"이라는 것과 소진 방식을 명시화(뒤이은 세 번째 후속에서
`nil`→`None`으로 다시 정정됨, 아래 참고).** 사용자가 "drive에서도
결국 PreRef를 목록에서 뽑아내야 하는데, 호이스팅 안 되면 PreRef
의미가 사라지는 거 아니냐"고 재질문 — 이전 답변이 `Dispatch.drive`가
pre-pass를 갖는다고만 하고 정확한 알고리즘을 안 써서 나온 질문.
`Dispatch.drive`가 같은 `flattened` 테이블을 **두 번** 순회한다는
것으로 답변: (1) pre-pass가 배열 전체를 index 순으로 훑어 `PreRef`를
fire하며 그 자리에서 슬롯을 소진, (2) 그 다음 평소 두 패스가 같은
테이블을 다시 순회하되 소진된 슬롯은 자연히 건너뜀. "호이스팅"은
PreRef를 배열 앞으로 물리적으로 옮기는 게 아니라 "PreRef 전용 선행
루프가 통째로 먼저 끝난 뒤에야 나머지가 시작된다"는 뜻이라 소스 위치와
무관하게 항상 먼저 fire됨. **소진이 최적화가 아니라 정확성 요건인 이유도
명시**: 안 지우면 두 번째 패스가 이미 처리된 PreRef를 `Dispatch.process`로
다시 넘겨서, 바로 위에서 신설한 "동적 경로 가드" Handler(`(v=PreRef)`→
`error`)가 정상 사용에도 오탐 에러를 던지게 됨.

## 2026-08-07 열 번째 세션 — 소진 슬롯을 `nil`이 아니라 `None`으로,
사용자가 Luau REPL 반례로 직접 발견

같은 날 이어진 세션. 사용자가 Luau REPL에서 직접
`for i,v in {[1]=1,[2222]=2222,[211]=211,[131]=131,[3]=3,[6]=6,
[122]=122,[11]=11,[312]=312,[821]=821,[991]=991} do print(i,v) end`을
돌려 순회 순서가 `1, 6, 122, 11, 991, 2222, 131, 312, 3, 821, 211`로
나온다는 걸 보여줌 — index 오름차순이 전혀 아님. 이건 위 아홉 번째
세션에서 "PreRef pre-pass가 fire된 슬롯을 `nil`로 지우면 된다"고 적은
것과 여섯 번째 세션에서 "Ref 콜백/대기자 배열도 `[i]=nil`로 소진하면
된다"고 적었던 것 둘 다를 뒤집는 반례 — 키가 촘촘한 저범위 정수에서
벗어나면(구멍이든 원래 듬성듬성이든) Luau/Lua 테이블이 해시 파트
취급으로 넘어가 순회가 해시 버킷 순서가 됨.

**해결 — 소진에 `nil` 대신 `None` 센티널 사용, 전 코퍼스에 전파.**
`None`은 `nil`이 아닌 실재하는 값이라 그 슬롯을 "차 있다"로 유지시켜서
테이블이 "구멍 없는 시퀀스"라는 불변식이 안 깨짐 — 두 가지를 동시에
해결: (1) 순서가 실제로 중요한 배열(PreRef pre-pass)의 순서 보장 유지,
(2) `table.insert`가 내부적으로 쓰는 `#t`가 Lua 명세상 구멍 있는
테이블에서 정의되지 않은 동작이라는 문제(Ref 콜백/대기자 배열이 새
등록 때 `table.insert`를 씀 — 순서 자체는 원래도 안 중요했지만 이
`#t` 안전성 문제는 진짜 버그였음). **배열 파트의 `None`은 해시 파트의
`None`(Modifier 필드 명시적 지우기, `NoneHandler` 경유)과 의미가
다름** — 배열 파트 `None`은 처리할 핸들러가 없는 순수 빈 슬롯 표시라
`Dispatch.process`/`NoneHandler`를 안 거치고 두 패스 루프 자신이 직접
`if v == None then continue end`로 스킵.

`base/bind-system-plan.md`의 "왜 `nil`이 아니라 `None`인가"(Ref
콜백/대기자 절)와 PreRef pre-pass 절에 반영, `ROADMAP.md` M0/M8
체크박스 갱신, 위 아홉/여섯 번째 세션 문단에 정정 표시 추가(원문은
유지, 틀렸던 부분만 짧게 정정 포인터).

**부수 발견 — `props.Modifier`/`props.Ref` nil-hole 위험도가 이전
서술보다 큼.** `pre-implementation-audit.md` 1-5가 이미 이 위험을
"뒤 항목까지 무시될 수 있음"으로 국소적 피해처럼 서술해뒀는데, 이번
REPL 실측으로 실제로는 구멍이 하나만 생겨도 **그 테이블 전체**가 순서
보장을 잃을 수 있다는 게 드러남 — M0 스파이크에서 반드시 실측하고,
심각하면 "raw 리터럴 대신 `props.Modifier or Modifier()`로 non-nil
보장" 컨벤션 문서화까지 검토하기로 `ROADMAP.md` M0에 메모 추가. 이
케이스는 caller가 직접 쓰는 raw Lua 리터럴이라 `None`으로 프레임워크가
대신 채워줄 수 없어서 별도 해법이 필요함 — `None` 소진 전략과 혼동하지
말 것.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M0 착수 시 위
nil-hole 위험도 실측이 우선순위 높아짐.

**같은 세션 세 번째 후속 — `props.Modifier`/`props.Ref` nil-hole
해법을 실제로 확정, 세션 clear 전 문서 완결성 점검하며 발견한 갭
3개도 같이 보강.** 사용자가 "컴포넌트에서는 꼭 `or None`이나
`Modifier()` 같은 걸로 nil 못하게 강제하는 걸 문서화하자"고 요청, 그
자리에서 결정하고 clear 전 세션 전체를 다시 훑어 새로 알게 됐지만
아직 문서에 없던 것들을 마저 채움:

1. **`props.Modifier or None`/`props.Ref or None`을 필수 관용구로
   확정** — `Modifier()`(빈 modifier 새로 생성)가 아니라 `None`을 쓰는
   이유는 이미 있는 array-part `None`-스킵 메커니즘(PreRef 논의에서
   확정)을 그대로 재사용해 새 코드/할당이 하나도 안 늘어나기 때문 —
   `flatten`이 `isModifier(None) == false`라 그냥 통과시키고, 이어지는
   두 패스 루프가 `None`을 만나면 스킵. `base/component-composition-plan.md`
   "필수 관용구" 절 신설, `ROADMAP.md` M0/`pre-implementation-audit.md`
   1-5/`question.md`에 반영(1-5는 해소로 표시).
2. **`Modifier()` 바닥 생성자가 문서 어디에도 없었던 갭 발견·보강** —
   `Source(default)`/`Ref(default)`/`Store({defaults})`와 나란히 있어야
   할 "`Type(args)` 팩토리" 4번째 예시가 원래 없었음(이전 아홉 번째
   세션에 `Modifier.Rounded(8)` stale 참조를 고치면서 실수로 체이닝
   예시인 `mod:UICorner(8)`로 잘못 채워 넣었던 것도 같이 바로잡음).
   `modifier-plan.md` 3번 절에 명시, `store-semantics.md` 예시 목록
   정정, `ROADMAP.md` M7 체크박스 추가.
3. **`Brand` 태그 목록에 `RefTag`/`PreRefTag`/`ModifierTag`가 빠져있던
   갭 발견·보강** — 이번 세션 내내 `isPreRef(v)`/`isModifier(v)`를
   이미 존재하는 predicate처럼 써왔는데 정작 여덟 번째 세션의 `Brand`
   태그 목록엔 없었음. 추가하면서 **`isRef`/`isPreRef`가 `isState`와
   달리 집합 멤버십이 아니라 단순 항등이라는 것도 명시** —
   `isRef(preRefInstance)`가 참이면 일반 `(v=Ref)` 핸들러가 `PreRef`도
   집어삼켜 PreRef 전용 pre-pass/가드 Handler 설계 전체가 무너지므로
   반드시 배타적이어야 함. `bind-system-plan.md`의 `Brand` 절,
   `ROADMAP.md` M2 체크박스에 반영.
4. **배열 파트 `None`과 해시 파트 `None`(`NoneHandler`)이 같은 센티널인데
   처리 경로가 다르다는 걸 `None` 센티널 절 자체에 명시적으로
   교차 참조 추가** — 이전엔 PreRef 절에만 있고 `None` 센티널 원래
   정의 절엔 이 예외가 안 적혀 있어서, 그 절만 읽으면 모든 `None`이
   `NoneHandler`를 탄다고 오해할 수 있었음.

전부 커밋 `98bd46a` 이후 아직 커밋 안 된 이번 대화 전체 변경사항에
포함 — 다음 세션이 새로 알아야 할 건 없음, `ROADMAP.md` M0부터 그대로
시작.

## 2026-08-08 세션 — `Relate` 신규 프리미티브, `bindLifetime`/`canExecute`
탑레벨 함수로 확정, store-bind 재실행=Observer 재사용 명문화, `retract`
필드 생략 불가 확정

사용자가 store-bind/라이프사이클 관련 문서 갭 두 개를 질문하며 시작된 세션
— 답을 찾는 과정에서 지금까지 이름만 있던 placeholder(`base.perInstanceState`)가
실제로는 제대로 설계된 적 없는 프리미티브였다는 게 드러나 그 자리에서
설계까지 확정까지 감. 네 가지로 정리:

**1. store-bind의 "값이 바뀔 때마다 재귀 process" 구독 메커니즘 =
`state:Observer(fn):Subscribe()` 재사용으로 확정.** 기존 "확정된 디스패치
모델"/"재실행 래핑" 절이 구독을 추상적으로만 서술해서 마치 새 구독
프리미티브가 필요한 것처럼 읽혔는데, 실제로는 이미 확정된 Observer(등록
즉시 1회 실행이라 "최초 적용"과 "이후 갱신"이 공짜로 통일됨, 자기 `Subscribed`
liveness도 이미 있음)를 그대로 쓰면 됨 — `retract`는 `observer:Unsubscribe()`
호출 하나로 끝. 새 구독 메커니즘 발명 없음. `base/bind-system-plan.md`
"Store 바인드는 특수 경우인가" 절 반영.

**2. `retract` 필드는 no-op이라도 항상 정의해야 함 — 생략 불가로 확정.**
"모든 핸들러가 의미 있게 구현할 필요는 없음(보통 no-op)"이라는 기존 서술이
"필드 자체를 생략해도 된다"로 오독될 수 있는 갭이었음 — `Dispatch.process`는
담당 핸들러 타입이 바뀔 때 이전 핸들러의 `retract`를 nil 체크 없이 무조건
호출하므로, 필드를 생략한 핸들러가 실제로 교체되는 드문 순간(Tween↔프로퍼티
등)에 `attempt to call a nil value`로 크래시함. `base/bind-system-plan.md`
"핸들러 계약" 절에 명시, M2 체크리스트에 린트 대상으로 추가.

**3. `Relate` 신규 프리미티브 — `bindLifetime`/`canExecute`(가 의존하는
per-inst weak 저장소)를 제대로 설계.** 사용자 질문 경위: `Frame { observer }`처럼
children 배열에 직접 놓는 leaf 케이스와, property store-bind 핸들러가
**내부에서** 만드는 Observer(배열에 안 들어가므로 그 leaf 부착 경로를 안 탐)를
처음에 잘못 섞어서 답했다가 사용자가 "state 바인딩은 결국 k,inner v를
호출하니 i=number,v=observer로 다시 실행 안 된다"고 정정 — 후자는
`bindLifetime(inst, observer)` 같은 별도 배관이 필요하다는 걸로 이어짐.
이게 `base/lifecycle-pattern.md`가 이미 원 사용자 메모(2026-08-04)로
갖고 있던 "함수 안에서 만든 옵저버도 GC 대상 되어야 함" 절과 정확히
같은 문제였음이 드러남 — 그 절이 "범용 유틸이 있어야 한다"까지만 말하고
실제 인터페이스/이름이 없던 것.

- **탑레벨 평범한 함수로 확정, 네임스페이스 뒤에 안 숨김** — `bindLifetime(inst,value)`/
  `canExecute(inst,value)`. `Dispatch.process`류는 "시스템 배관"이라
  네임스페이스가 맞지만 이 둘은 `isState`/`isObserver`처럼 핸들러 작성자가
  직접 부르는 1급 프리미티브 연산이라 `LifetimeHandle.bind(...)`식으로
  감싸면 안 된다는 사용자 지적(정확함, 처음 제 제안이 틀렸었음).
- **`canExecute` 시그니처를 `(handle)` 단일 인자에서 `(inst, value)`
  2-인자로 재정정** — Observer 자신의 바인딩 생존(`Subscribed`)과 `inst`
  자체 생존(gcconn)이 독립된 두 조건이라 opaque `handle` 하나로 못 뭉침.
  구현은 `value`가 Observer/Effect면 자기 `Subscribed`부터 확인, 그 다음
  `inst`의 공유 gcconn `.Connected`를 봄.
- **`Relate` — `inst`를 weak 키로 하는 범용 릴레이션, 신규 프리미티브로
  독립 승격**(`base/relate-plan.md`, 1프리미티브-1파일 컨벤션). `Relate()`
  비싱글톤 생성자 + `:SetWeak`/`:GetWeak`/`:SetStrong`/`:GetStrong`. 핵심
  결정 세 개, 전부 사용자가 직접 제시:
  1. **자동으로 아무것도 홀드 안 함** — `inst`도 `value`도 Relate 자신은
     안 붙잡음, weak/strong 여부는 호출부(엔진을 아는 quad-roblox)가
     매번 명시. 자동으로 정하면 weak 키가 참조하는 값이 그 키로 되돌아
     강참조하는 사이클이 너무 쉽게 생김.
  2. **`inst`(키) 축은 항상 weak로 고정, 자유도를 안 열어둠** — 강한 키가
     필요한 유스케이스가 지금까지 하나도 없어서, 그 자유도 자체가 사고
     가능성만 늘림. `Weak`/`Strong`은 오직 `value` 보관 방식.
  3. **실 구조는 `{ [inst(weak)]: { StrongMap: {[k]:v}?, WeakMap: {[k]:v(weak)}? }? }`,
     둘 다 lazy 생성**(첫 `Set` 호출 시에만 만듦) — Luau가 정적 분석으로
     포인터 해싱을 캐싱해 반복 인덱싱은 이미 싸지지만 테이블 생성(array+hash
     part 초기화) 자체는 비교적 비싸다는 게 이유. `WeakMap`의 메타테이블은
     매번 새로 안 만들고 공유 객체 하나를 재사용.
  - **비싱글톤인 이유**: 각 핸들러 모듈이 자기 톱레벨에 `local relate =
    Relate()`를 하나씩 두면 key 네이밍이 모듈 간에 겹칠 걱정이 원천적으로
    없음(`Ref`/`Store`류와 같은 "생성 가능한 값" 컨벤션).
- **`base.perInstanceState(inst)` 이름/placeholder는 완전히 폐기** —
  `Relate`가 그 자리를 정식으로 대체. `bind-system-plan.md`(핸들러 내부
  상태 저장 절)/`ui-shorthand-plan.md`/`architecture.md`(소스트리,
  `Relate.luau`는 quad-base 전체가 순수 Lua라 quad-roblox 재구현 없음)/
  `question.md`(용어 정리 목록에서 `PerInstanceState` 항목 삭제, 이름
  갈등 자체가 해소됨)/`ROADMAP.md`(M2/M8/병행가능 세 곳) 전부 동기화.

**4. 아직 안 풀린 것 — `(i:number, v=Ref/Observer/PreRef)` children-array
leaf Handler가 quad-base/quad-roblox 중 어디 사는지.** 3번을 풀다가
갈라져 나온 별개 질문(`Frame { ref }` 자체를 매칭하는 Handler, store-bind
내부 Observer와는 무관) — 제 제안(엔진 특정 API가 필요 없으니 quad-base,
`Dispatch/StoreBind.luau`와 같은 층위)은 사용자 확인을 못 받은 채 대화가
3번으로 넘어감. `question.md` 2번에 미확인으로 남김, base에는 반영 안 함
— 다음에 확인 필요. **[해소됨, 같은 날 두 번째 세션]** 아래 절 참고 —
제 원래 제안 그대로 quad-base로 확정.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M0/M2 스파이크 코드가
검증해야 할 것 목록에 `Relate`의 lazy 서브테이블 생성/공유 메타테이블
전략, `bindLifetime`/`canExecute`의 실제 gcconn 트릭이 새로 추가됨 —
`base/lifecycle-pattern.md`/`base/relate-plan.md`의 "실측 필요" 캐비엇
참고.

## 2026-08-08 두 번째 세션 — Dispatch는 프리미티브가 아니라 탑레벨 싱글톤 확정,
네이밍 케이싱 컨벤션 신설, Handler를 세 번째 카테고리로 명문화

같은 날 이어진 세션. 사용자가 위 4번 미결 항목("Ref/Observer/PreRef leaf
Handler가 어디 사는지")을 다시 짚으며 시작 — "Handler도 실제 런타임 값이
생기는 요소인데 왜 프리미티브로 안 다루나", "Dispatch는 어떻게 되는 거냐,
State 핸들러 안에서 `getHandler`를 부르려면 Dispatch가 이미 존재해야
하는데" 하는 질문으로 확장돼 Dispatch 자체의 정체성(싱글톤 top-level
함수 모음 vs 인스턴스화 가능한 프리미티브) 논의로 이어짐. 네 가지로 정리,
전부 `base/bind-system-plan.md`/`base/store-semantics.md`/
`base/architecture.md`/`question.md`/`ROADMAP.md`에 반영 완료:

**1. Dispatch는 프리미티브가 아니라 탑레벨 싱글톤 — 확정, 지금 형태 유지.**
`Dispatch.process`/`getHandler`/`addHandler`/`drive`를 `Source`/`Ref`처럼
생성자 있는 프리미티브로 바꿀지 검토했으나 기각. 근거: (a) Tween/
`NoneHandler`/`StoreBind`가 자기 `process` 안에서 다시 `Dispatch.process`를
재귀 호출해야 해서, `canExecute`/`bindLifetime`처럼 require 한 번으로 바로
닿는 안정된 전역이어야 함 — 프리미티브화하면 모든 Handler 호출 경로에
Dispatch 핸들을 실어날라야 하는 스레딩 비용이 생기는데 지금은 그 비용이
없음. (b) 사용자가 우려한 "Handler가 Dispatch 원하고 Dispatch가 Handler
원해서 순환참조" 문제는 착시로 확인됨 — "Handler"가 (i) `Handler.luau`의
순수 타입 계약(leaf, Dispatch를 몰라도 됨)과 (ii) 그 계약을 구현하는
concrete 값 모듈(`StoreBind.luau`류, 재귀호출 위해 Dispatch를 참조)
두 가지를 가리켜서 헷갈렸던 것 — 의존 방향은 `Handler.luau` ←
`Dispatch/init.luau` ← `StoreBind.luau`로 항상 한쪽으로만 흐름, 사이클
없음. (c) 모듈 재생성(`New()`)과의 관계도 새 설계가 필요 없음 — 이미
확정된 "팩토리가 `BaseModule`을 뮤테이션" 패턴을 그대로 따르면
`_initializedBy` 마커에 대해 이미 나왔던 결론("`New()`가 생기면 각
인스턴스가 별도 테이블이 되므로 자연히 스코핑됨")이 Dispatch의 handler
레지스트리에도 그대로 적용됨. v1처럼 `require`를 감싸는 `Init(QuadId?)`
방식은 채택 안 함(id 기반 조회 자체가 Ref로 대체되며 이미 기각된 패턴).
`base/bind-system-plan.md`의 "Dispatch는 프리미티브가 아니다" 절,
`base/architecture.md` 13번 항목에 반영.

**2. quad-base 기본 핸들러도 전부 같은 `Dispatch.addHandler` 레지스트리를
공유 — Ref/Observer/PreRef leaf Handler 위치 확정.** `NoneHandler`/
`Dispatch/StoreBind.luau`뿐 아니라, children 배열 숫자 슬롯에 `Ref`/
`Observer`/`PreRef`를 직접 놓는 leaf 값을 매칭하는 Handler도 같은 부류 —
`inst`를 `any`로 취급하고 엔진 특정 API가 필요 없으니 quad-base,
`Dispatch/Leaf.luau`로 확정(위 4번 미결 항목 해소). quad-roblox의
Property/Event/Tween 핸들러도 **같은** 레지스트리에 등록되므로, base
기본 핸들러와 backend 핸들러가 별도 경로로 안 갈리고 하나의 우선순위
스캔을 공유한다는 것도 명시적으로 확인됨. `architecture.md` 소스트리에
`Dispatch/Leaf.luau` 반영, `question.md`/`ROADMAP.md` M2 동기화.

**3. Handler는 "독립 프리미티브 vs 파생 데이터" 분류의 세 번째, 별개
카테고리 — 명문화.** 2026-08-06 후속 세션이 확정한 분류(Source/Ref/Store/
Modifier=독립 프리미티브, State/Observer=파생 데이터)에 Handler가 왜
안 끼는지 사용자가 재확인 요청 — 이유: Handler는 그 자체로 구현체가
없는 **순수 타입 계약**이라 quad 사용자가 다루는 리액티브 값이 아님,
계약을 만족하는 값(`PropertyHandler`류)은 항상 **구현하는 쪽**(base
자신의 기본 핸들러 또는 quad-roblox 백엔드)이 채워 넣는 것이지 `Type(args)`
자유 함수로 사용자가 만드는 게 아니고, State/Observer처럼 어떤 원천에
종속된 파생물도 아님. `base/store-semantics.md`의 "일반 원칙" 절 뒤에
"세 번째 카테고리 — Handler" 절로 반영.

**4. 네이밍 케이싱 컨벤션 신설 — 지금까지 나온 모든 이름이 이미 따르고
있던 규칙을 문서화만 함, 리네임 없음.** 사용자 관찰: "탑레벨 함수는
변수처럼 소문자 시작, 프리미티브 타입의 메서드는 대문자 시작(파스칼
케이싱)이 맞아 보인다"는 규칙 제안 — 검증 결과 기존 이름 전체(생성자
`Source`/`Ref`/`Store`/`Modifier`/`Relate`/`Effect`, 콜론 메서드
`:Get`/`:With`/`:Set`/`:Apply`/`:Subscribe`류는 전부 대문자, `canExecute`/
`bindLifetime`/`isState`류/`Dispatch.process`류/`Brand.set`류는 전부
소문자)가 이미 예외 없이 이 규칙을 따르고 있었음이 확인됨. 유일하게
애매해 보였던 `Modifier.Override(mod1, mod2, ...)`(콜론 아니고 dot-access
인데 대문자)도 규칙 위반이 아니라 세 번째 하위 규칙으로 설명됨 — 콜론
메서드는 아니지만 **`Modifier` 타입 자신의 네임스페이스에 달린 정적
결합 함수**라 "그 프리미티브 타입 고유의 공개 어휘"라는 점에서 생성자/
메서드와 같은 부류. 반대로 `Dispatch.process`/`Brand.set`이 소문자인
이유는 `Dispatch`/`Brand`가 애초에 `Type(args)` 생성자가 없는 프리미티브가
**아닌** 내부 엔진/레지스트리라서. 최종 판단 기준: "이 이름이 특정
프리미티브 타입 하나의 전용 소유물인가?" — 그렇다면 대문자, 아니면(여러
타입에 걸친 범용 유틸이거나 비-프리미티브 엔진 소속) 소문자. `base/
architecture.md`의 "코드 스타일 — 네이밍 케이싱" 절 신설.

**같은 세션 후속 — `module-lifecycle-plan.md`의 "열린 질문" 절이 stale로
방치돼 있던 것을 사용자가 직접 발견.** 문서 상단 "상태" 줄은 이미
"확정되어 승격됨"이라고 말하는데 그 아래 "열린 질문" 절은 2026-08-04
당시 그대로 남아있었음 — 그중 "프로바이더 인터페이스 시그니처 미정"/
"네이밍 미정(provider/processor/plug)" 두 항목이 사실 그 뒤 `Handler`
계약 확정으로 이미 풀려 있었는데 이 문서에 반영이 안 됐던 것. 원문은
남기고 각 항목에 해소 표시+포인터 추가, 절 제목도 "열린 질문이었던 것 —
전부 해소됨"으로 정정. 새 결정 아니라 순수 동기화.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계/문서 정리라 M0 착수 우선순위 자체는 그대로. 위 2026-08-08 첫 세션이
남긴 "M0/M2 스파이크 검증 목록"에 새로 추가되는 항목 없음.

## 2026-08-08 세 번째 세션 — Tag를 array-part 값 객체로 재설계, Dispatch
체인+`retractUnder`로 재귀 재-dispatch의 retract 전파 문제 해결

같은 날 이어진 세션. 사용자가 "Tag를 해시 파트 boolean 키 대신 array-part
값 객체로 바꾸는 게 낫지 않냐"는 질문으로 시작 — 상호배타 스타일 상태
(`btn1`/`btn2`/`btn3`류, 20개까지도 가능)를 표현하려면 구 모델은 태그
개수만큼 키를 갱신해야 해서 끔찍하다는 실사용 근거. 이 논의가 "retract가
새 값의 타입에 따라 이전 핸들러를 정확히 찾아 부를 수 있는가"라는 훨씬
근본적인 구멍(`pre-implementation-audit.md` 1-2번이 이미 지적해뒀던 것)을
직접 건드리게 됐고, 몇 차례 시행착오 끝에 사용자가 제시한 "체인+
`retractUnder`" 설계로 수렴. 세 갈래로 정리:

**1. Tag 재설계 — array-part 값 객체, `Modifier`와 같은 immutable clone
체이닝.** `Tag(name1, name2, ...)`(가변인자 생성자, 빈 `Tag()`도 유효),
`:Added`/`:Removed`(뮤테이션처럼 안 보이게 `-ed` 어미 — 실제로는 항상
clone 후 반환), `:Contains(name):boolean`, `:Apply(factory)`(Modifier와
동일한 순수 체이닝 설탕), `Tag.Merged(tag1,tag2,...)`(집합 합집합, 무손실
— Modifier의 `Override`는 필드 단위 덮어쓰기라 손실 있음, 그래서 이름도
다름). `None` 센티널은 불필요로 확인 — 동적 토글은 `Source`/`State`가
계산 결과로 `nil`을 리턴하면 되는 함수 인자 전달이라 테이블 리터럴의
nil-hole 문제 자체가 없음(정적 리터럴에서 조건부로 Tag를 넣고 뺄 때는
다른 array-part 값과 마찬가지로 기존 `None` 관용구가 그대로 유효, Tag
전용 규칙 아님). 구 모델(해시 파트 boolean, "핸들러 타입이 안 바뀌니
retract 불필요"가 결론이었음)은 `archive/tag-hash-key-model-reversed.md`로
역전 보존, `base/tag-plan.md` 전면 재작성. 값 타입+API(`Tag.luau`)는
quad-base, `CollectionService` 글루(`Handlers/Tag.luau`)만 quad-roblox —
이미 확정된 "base는 인터페이스/값, backend는 process·retract 글루"
패턴(`LifetimeHandle`)을 값 타입 수준까지 그대로 확장한 것으로 확인,
새 아키텍처 개념 아님.

**2. Tag 재설계가 "retract가 실제로 필요해지는" 첫 array-part store-bind
사례가 되며, 기존 "이전 핸들러 추적" 설계 공백이 정면으로 드러남.**
`pre-implementation-audit.md` 1-2번이 이미 "store-bind 재실행 모델에서
realv 타입이 매 갱신마다 바뀔 수 있는데 '이전 핸들러'를 누가 추적하는지
불명"이라고 짚어뒀던 것 — Tag가 `Tag(...)`↔`nil` 사이를 오가며 실제로
핸들러 타입이 바뀌는 구체 사례가 되어 더 이상 미룰 수 없어짐. 시행착오
과정:
- **1차 제안(제가 냄, 기각됨)**: Dispatch가 `(inst,k)`별로 "지금 누가
  담당 중인가"를 슬롯 하나로 추적. **재귀/래핑 핸들러(StoreBind 등)
  에서 깨짐** — 사용자가 직접 "A→B 구조에서 A가 바뀌면 B의 retract가
  실행되고, 재귀로 B로 다시 내려오면 retract가 없는 거 아니냐"고 반례를
  제시 — A 자신의 생명주기(예: Observer 구독)와 A가 재귀로 위임한 B의
  생명주기가 슬롯 하나를 두고 서로 덮어써서, A가 스스로 재-dispatch할
  때 자길 엉뚱하게 retract하거나 반대로 안 해야 할 때 안 하는 오작동이
  생김이 실제 트레이스로 확인됨.
- **2차 제안(제가 냄, 부분 기각)**: 각 래핑 핸들러가 자기 전용 `Relate`에
  위임 대상을 비공개로 저장(A→B→C면 A.retract가 수동으로 B.retract를
  부르고 B.retract가 수동으로 C.retract를 부르는 linked 구조). 동작은
  하지만 사용자가 두 가지 지적: (a) 나중에 재바인드(`existing-instance-
  bind-plan.md`) 지원을 생각하면 위임 정보가 핸들러별로 비공개 분산돼
  있어 외부에서 못 들여다봄, (b) 각 핸들러 작성자가 "내 retract에서
  위임 대상도 cascade해야 한다"는 걸 매번 기억해야 하는 규율 의존적
  설계.
- **최종 채택(사용자 제안) — Dispatch가 `(inst,k)`별 핸들러 체인(순서
  있는 배열)을 직접 소유, `Dispatch.retractUnder(inst,k,keep,v)`가
  꼬리부터 `keep` 앞까지 훑으며 정리.** `Dispatch.process`가 매치될
  때마다 체인에 push, 재귀/래핑 핸들러는 재-dispatch 전에
  `retractUnder(inst,k,self,newV)`를 먼저 불러 자기 밑을 정리 — 이
  한 번의 루프가 다단 체인(A→B→C) 전체를 순서대로 정리해주므로 개별
  핸들러의 `retract`는 더 이상 자기 위임 대상을 수동으로 안 쫓아가도
  됨(2차 제안의 (b) 해소), 체인이 Dispatch에 중앙화돼 있어 미래
  재바인드도 `retractUnder(inst,k,nil,newV);process(inst,k,newV)`
  두 줄로 자연스럽게 됨((a) 해소) — quad-debug의 "무엇이 무엇에
  연결됐는가" 그래프도 이 구조를 그대로 읽으면 됨. 배열이 항상 꼬리에서만
  추가/삭제되는 스택 모양이라 `None` 소진 이슈(구멍 있는 정수 키 순회
  문제)도 애초에 안 생김. **`retract`는 여전히 `(inst,k,v)` 3-인자
  유지** — 한 차례 제가 "v 제거"를 제안했다가 틀렸음(사용자가 Tag의
  전체삭제 vs diff 분기를 근거로 정정) — 다만 최종 설계에서 diff는
  `process`(같은 핸들러 유지 시)의 몫이고 `retract`는 항상 "더 이상
  매치 안 될 때만" 불리므로 Tag 한정으로는 `v`를 안 봐도 항상 전체
  삭제가 맞다는 것도 확인. 순환은 기존 "일반적 무한루프 방어 안 함"
  원칙(2026-08-04) 그대로 UB.

**3. 전부 `base/bind-system-plan.md`(신규 "Dispatch 체인" 절 + "확정된
디스패치 모델"/"None 센티널"/"Store 바인드는 특수 경우인가" 절 갱신)/
`base/tag-plan.md`(전면 재작성)/`archive/tag-hash-key-model-reversed.md`
(신규)/`base/architecture.md`(소스트리 `Tag.luau` 추가, 4번 항목 정정)/
`ROADMAP.md`(M2/M4/M10)/`research/pre-implementation-audit.md`(1-2번
해소 표시)에 반영 완료.**

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M2/M4 스파이크
검증 목록에 `chains`/`retractUnder`가 다단 체인에서 실제로 정확히
동작하는지가 새로 추가됨(추론만으로 확정된 것, `pre-implementation-audit.md`
류 "실제 Luau로 부딪혀본 적 없는 것" 범주). `pre-implementation-audit.md`
1-1번(Tween이 유일한 store-bind 예시라 "일반 store-bind와 Tween이 같은
핸들러인지"가 불명확한 문제)은 Tag가 두 번째 구체 사례가 되면서 정황상
"별개 핸들러, 둘 다 `Dispatch/StoreBind.luau` 재사용"쪽에 힘이 실리지만
**아직 명시적으로 확정된 건 아님** — M2/M4 착수 전 마저 확인할 것.

## 2026-08-08 네 번째 세션 — `Modifier.Override` → `Overridden`으로 이름 확정

사용자가 IDE에서 `tag-plan.md`를 보다가 "Tag가 `Added`/`Removed`처럼
`-ed` 어미를 의도적으로 쓰는데, Modifier의 `Override`도 그냥
`Overrided`로 하면 어떤가"라고 질문 — `-ed`/분사 어미가 "즉시 커밋되는
뮤테이션이 아니라 이미 계산되어 반환되는 새 값"을 신호한다는 기존 관례
(`Add`/`Remove`가 `-ed` 없이 쓰이면 뮤테이션처럼 오독될 위험이 있어
`Added`/`Removed`로 확정했던 것과 같은 문제가 `Override`에도 그대로
있음)에 정확히 들어맞는 좋은 관찰이었음. 다만 `Overrided`는 오기 —
`override`는 불규칙동사라 과거분사가 `overrided`가 아니라 `overridden`.
`Add`/`Remove`/`Merge`가 전부 규칙동사라 우연히 단순 `-ed` 접미만으로
맞았던 것뿐, `Override`엔 그 규칙이 그대로 안 통함. 사용자가 이 정정에
동의하고 확정 요청 — `Modifier.Overridden(mod1, mod2, ...)`으로 이름
자체를 확정(더 이상 가칭 아님, 용어 정리 라운드 대상에서도 제외).

`base/modifier-plan.md`/`base/component-composition-plan.md`/
`base/bind-system-plan.md`/`base/tag-plan.md`(비교 문구)/
`base/architecture.md`/`ROADMAP.md`/`research/pre-implementation-audit.md`/
`research/documentation-content-map.md`/`.claude/README.md`/
`.claude/question.md` 전부에서 `Override` → `Overridden`으로 기계적
치환 + 각 문서의 "가칭"/"이름만 잠정" 표시를 "이름 확정"으로 갱신
(`question.md`의 3순위 용어 재검토 목록에선 완전히 제거, `Peek`/
`isState`만 그 목록에 남음). CLAUDE.md 세션 히스토리(과거 `Override`
서술)와 `archive/`는 당시 기록이라 그대로 둠 — 역사적 서술과 현재
유효한 이름을 헷갈리지 않도록 여기 새 절로만 반영.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 순수 네이밍
확정이라 M0 착수 우선순위나 설계 자체엔 영향 없음.

## 2026-08-08 다섯 번째 세션 — 용어 정리 라운드 정리: `Handler`/`None`·
`NoneHandler`/`Ref`/`PreRef`/`Peek`/`isState` 이름 확정, `DI`→`D`/
`canExecute`→`isAlive`는 계속 미정으로 재확인

사용자가 `.claude/question.md`의 3순위(사소함) 용어 재검토 목록을 훑으며
한 번에 여러 개를 정리 — 전부 `.claude/question.md` "1. 용어 정리" 절과
`base/module-lifecycle-plan.md`에 반영 완료:

- **`Ref`/`PreRef`/`Peek`/`isState` — 전부 현재 이름 그대로 확정(더 나은
  대안 없음).** `Ref`는 "지연 없는 확정된 값 박스"라는 정의를 재확인 —
  leaf 노드를 담는 용도로도, leaf 노드에 바인딩하는 용도로도 쓰인다는 게
  넓어진 정의에도 여전히 맞다는 근거.
- **`None`/`NoneHandler` — 확정.** `Undefined`/`Null`/`Nothing`도 검토했으나
  `Null`은 보통 "포인터가 비어있음"(0)을 뜻해 "값이 없음"이라는 의도와
  미묘하게 안 맞는다는 이유로 기각, `None`이 나음.
- **"프로바이더" → `Handler`로 확정, 기각 이유 보강.** 이미
  `module-lifecycle-plan.md`에 [해소됨]으로 반영은 돼 있었으나
  `question.md` 목록에 stale로 남아있던 걸 정리. `Processor`는 계약
  메소드 자체가 `process`라 이름이 겹쳐 거슬림, `Provider`는
  `canProvide`처럼 "공급한다"는 늬앙스인데 실제로는 처리/반응하는
  쪽이라 안 맞고 React `Context.Provider`류와도 헷갈릴 수 있음, `Plug`는
  "꽂힌다"는 어감은 맞지만 "처리한다"는 의미가 빠져있음 — `Handler`가
  계약(`isHandlable`/`priority`/`process`/`retract`) 전체를 가장 정확히
  담는다는 결론.
- **`DI` → `D`는 아직 미확정.** 사용자가 "Declarative만 남기고 D로
  줄이자"는 안을 제안 — Instance 전용이 아니라 quad-* 전반의 declare
  요소로 확장 가능하고, 엔진 종속 없이 재사용 가능하며, `D.FrameModifier`
  류 타입 프리픽스가 짧아야 한다는 실용적 이유까지 근거로 나쁘지 않은
  제안이나, 한 글자 식별자의 검색성/자기설명력 트레이드오프를 문서에서
  어떻게 보완할지가 남아 다음에 마저 결정하기로 함.
- **`canExecute` → `isAlive`도 계속 미정, 방향만 정리.** `isAlive`가 의미는
  더 정확하지만 top-level `isX` 타입 판별자 계열(`isState`/`isRef`/
  `isPreRef`/`isModifier`/`isObserver`)과 접두어가 겹쳐 "이것도 타입
  체크인가" 오해를 유발할 위험이 지적됨 — `canExecute`는 타입이 아니라
  liveness를 묻는 질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽으로
  사용자가 기욺, 구체 대안(`canRun` 등)은 다음에.
- `Brand`는 이번에도 다시 짚었지만 여전히 미정으로 재확인만 함.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). `DI`/`D`와
`canExecute`/`isAlive` 두 개만 용어 정리 라운드에 계속 남음 —
`question.md` 1순위/3순위 목록 참고.

## 2026-08-09 세션 — `canBound` 이름 확정, `:Compute`의 `previous` 방어/스코핑
명확화, Modifier 핸들러 계층 값 UB→error 전환, Tween `initValue`/`useTween`
논의 신설

사용자가 `.claude/question.md`를 훑다 나온 여러 짧은 질문/제안을 한 번에
처리. 전부 `base/`/`research/`에 반영 완료:

1. **`Bound` → `canBound(handle): boolean` 탑레벨 함수로 확정** — 사용자
   제안("canExecute 같은 게 있으니 canBound로 넣어도 되지 않나"), raw
   불리언 필드를 직접 노출하는 대신 `canExecute`와 같은 결의 predicate
   함수로 감쌈. 동작 자체(leaf 부착과 `:Subscribe()`는 상호 배타, 위반
   시 즉시 에러)는 안 바뀜 — `base/bind-system-plan.md` "이중 바인딩
   금지" 절, `base/effect-plan.md`, `.claude/question.md` 반영.
2. **`:Compute(fn)`의 `previous` 인자 — 오버엔지니어링 의심 기각, 현재
   설계 유지.** `pre-implementation-audit.md` 3-1이 "클로저 업밸류로
   이미 되는 걸 별도 API로 만든 것 아니냐"고 의심했던 데 대해 사용자가
   직접 반박 — 클로저 업밸류 대안은 IIFE로 감싸는 준비 비용이 오히려
   `previous`라는 인자 하나보다 무겁고 번거로움. **부수적으로 스코핑도
   명확화**: 처음엔 `self.Cache`처럼 `previous`를 `self`(입력) 쪽에
   얹는 모양이 제안됐으나, `self`는 `:Compute`의 입력(receiver)이라
   같은 `self`에서 여러 `:Compute`가 갈라지는 팬아웃(`w:Compute(g1)`,
   `w:Compute(g2)`)이 있으면 `self.Cache` 슬롯이 충돌한다는 문제를
   검토 중 발견 — `previous`는 그 대신 "이 `:Compute` 호출 하나가 만든
   결과 State 노드" 자신에 귀속되는 것으로 정리(State가 호출마다 새
   노드를 만든다는 기존 온톨로지의 당연한 귀결이라 새 결정은 아님).
   `base/bind-system-plan.md`의 "previous" 절, `pre-implementation-audit.md`
   3-1 반영.
3. **Modifier 필드에 핸들러 계층 값(Ref/PreRef/Observer/Effect/Slot/
   Modifier)이 들어오면 UB 대신 즉시 `error`로 확정.** 기존
   "권장 사용법은 아니지만 막을 이유도 없음 — 방어 로직 없는 UB"였던
   것을, 이런 값의 실사용 case가 없다는 게 확인된 이상 조용한 UB보다
   그 자리에서 막는 쪽이 낫다는 사용자 판단으로 전환 — 이미 있는
   `Brand` 기반 predicate(`isRef`/`isPreRef`/`isObserver`/`isEffect`/
   `isSlot`/`isModifier`)를 제네릭 `__index` setter가 최종 저장 직전에
   확인하기만 하면 되므로 구현 비용 거의 0. `isSlot`/`isEffect`
   predicate가 `Brand` 절에 명시적으로 없던 갭도 같이 보강.
   `pre-implementation-audit.md`가 지적했던 "`State<Modifier>`는 방어,
   Ref/Slot은 무방비"라는 비일관성이 이걸로 절반 해소(메커니즘 차이는
   남지만 "막을 가치가 있다"는 판단은 통일) — `base/modifier-plan.md`
   "핸들러 계층을 모름" 절, `base/bind-system-plan.md`의 `Brand` 절,
   `pre-implementation-audit.md` 문서모순 절 반영.
4. **UI shorthand(UICorner/UIPadding/UIScale)가 Modifier 체이닝에서도
   되는지 — 이미 확정돼 있던 것 재확인, 새 결정 없음.** `mod:UICorner(8)`은
   그냥 제네릭 `__index` setter가 `UICorner` 필드를 채우는 것뿐이고,
   그 필드가 Modifier flatten을 거쳐 최종 props 테이블에 얹히든
   `Frame { UICorner = 8 }`처럼 순수 인라인으로 들어가든 UICorner
   Handler 입장에선 구분이 없음 — `base/ui-shorthand-plan.md`에 이미
   명시돼 있던 내용이라 문서 변경 없음.
5. **Tween `initValue`/`useTween` — 새 열린 논의 신설, 확정 아님.**
   사용자가 두 실사용 시나리오(다이얼로그 진입 애니메이션, 트윈 우회)를
   제기 — `initValue`(첫 마운트 시 시작값을 세팅 후 목표값으로 트윈)는
   재검토 끝에 필요성이 낮은 쪽으로 기움(재process 시 "최초 1회" 판별
   문제가 있어 보임), `useTween = state<boolean>`(트윈을 끄고 즉시
   스냅)은 필요성은 확인됐으나 정확한 모양/문서화 방식이 전혀 안
   정해짐 — `research/tween-plan.md`에 신규 절로 반영, M11 착수 전
   나중 세션에서 마저 정리하기로 함.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정/보강이라 M0 착수 우선순위 자체는 그대로.

**같은 세션 후속 — `State<Modifier>`도 UB 대신 명시적 `error`로 확정,
"핸들러 계층 값 → error" 원칙을 State/Source 쪽까지 완전히 통일.**
사용자 질문: "Modifier 필드"뿐 아니라 "State/Source 자체의 값이
Modifier인 경우"(`State<Modifier>`, `modifier-plan.md` 7번)도 같은
방식으로 막아도 되는지 — 확정. `isModifier` predicate를
`Source:Set()`/Store 생성 시 eager `Source(default)`/State의
`:Compute` 결과 캐싱 지점에서 확인해 런타임 `error`, 타입 차단(Luau
가능 여부 미검증)은 필수 방어선이 아니라 되면 좋은 보너스로 격하.
**Slot은 대조적으로 계속 허용** — 사용자 확인("slot은 당연히 가능함,
retract도 되는 애고 런타임 값이라"): Slot/Tag/Attribute/Tween 등은
정상적으로 process/retract 재귀 경로를 타는 진짜 dispatch 참가자라
State/Source 값으로 담겨도 기존 재귀 재-dispatch가 그대로 처리해줌 —
Modifier만 예외인 건 Modifier가 애초에 dispatch 경로 자체를 안 타는
유일한 존재라서. `base/modifier-plan.md` 7번, `base/store-semantics.md`
"따름정리" 절, `research/pre-implementation-audit.md` 2-2/문서모순 절
(완전 해소로 갱신), `.claude/question.md`, `ROADMAP.md` M7 반영 완료 —
이걸로 `pre-implementation-audit.md`가 지적했던 "State<Modifier>는
방어, Ref/Slot은 무방비"라는 비일관성이 완전히 해소됨.

**핸드오버 준비 완료** — 이번 대화(2026-08-08~09에 걸친 세션)에서 나온
결정은 전부 `base/`/`research/`/`question.md`/`ROADMAP.md`에 반영,
문서 간 참조도 동기화 완료. **다음 세션 예고(사용자 지정)**: Slot과
"State에서 Slot을 뽑아내는" 키 기반 동적 컬렉션 재조정(가칭 `Keyed`는
탈락, 최종 이름 미정) — `.claude/question.md` 0번 "키 기반 동적
컬렉션 재조정"이 이미 최우선 항목으로 잡혀있으니 그걸 이어서 보면 됨.

## 2026-08-09 두 번째 세션 — `.claude/` 코퍼스 전체 stale 마커 감사·수정,
무효화된 인라인 서사 archive 이전

새 설계 결정 없음, 순수 문서 정리 세션. 서브에이전트 4개를 병렬로 띄워
`.claude/` 전체(30여 개 문서 + `ROADMAP.md`/`HUMAN_TODO.md`/`SAFETY.md`/
`archive/`)를 클러스터별로 감사, "이미 해소됐는데 미해결로 표시된 것"과
"문서 간 모순"을 찾아 전부 직접 수정(커밋 전 상태 기준). 이어서 사용자
요청으로 두 번째 라운드 — 뒤집혔거나 무효화된 설계가 정정 표시만 붙은 채
본문에 전체 서술로 남아있는 곳을 찾아 기존 `archive/*-reversed.md`/
`*-rejected.md` 컨벤션대로 이전(본문엔 결론+포인터만 남김), 컨텍스트
낭비 방지 목적. 이것도 서브에이전트 3개 병렬 감사로 후보를 찾은 뒤 직접
판단해 적용.

**1차 라운드 — stale 마커/모순 수정 (7개 파일)**:
- `bind-system-plan.md`: `Ref` 이름이 "용어 정리 재검토 대상"으로 남아있던
  것 — 2026-08-08 다섯 번째 세션에서 이미 확정됐는데 반영 안 됨 → 해소
  표시로 정정. `component-composition-plan.md` §4-2 인용 오류(그 절은
  실제로 다른 내용을 다룸 — Ref 필드 충돌 없음의 근거를 잘못 인용)와
  폐기된 `StoreSource` 프록시와 혼동될 수 있는 "Source 양방향 프록시"
  표현도 정정.
- `documentation-content-map.md`: 폐기된 `myStore.key = value` 대입
  문법이 예시로 남아있던 것(같은 파일 바로 다음 줄은 `:Set()`으로 옳게
  써서 자기모순) → 정정.
- `ROADMAP.md`: 세션 인용 오류 2건(`git blame`으로 실제 커밋 시점 확인해
  정정 — M0의 Source/State 서브타입 항목은 "세 번째 세션", M2의
  `LifetimeHandle` 순서 역전 항목은 "네 번째 세션"이 맞음), `Bound`/
  `None` "가칭" 표기가 이미 이름 확정됐는데 안 지워진 것 2건 정정, M6에
  Slot CRUD 의미론 확정 체크박스 누락돼 있던 것 추가(`pre-implementation-audit.md`
  우선순위1이 이미 지적했던 갭).
- `question.md`: `Tag`/`Added`/`Removed`/`Merged`가 `tag-plan.md`에서
  "여기서 추적 중"이라 주장했지만 실제로 빠져있던 것 추가.
- `archive/context-rejected.md`: 다른 archive 문서와 달리 base/ 포인터가
  없던 것 보강.
- `additional-primitives-plan.md`: State/Observer를 "독립 프리미티브"로
  잘못 묶은 표현 정정(확정된 분류는 Source/Store/Ref/Modifier/Slot/DI=
  독립 프리미티브, State/Observer=파생 데이터, 2026-08-08 두 번째 세션
  "Handler는 세 번째 카테고리" 절 참고).

**2차 라운드 — 무효화된 인라인 서사를 archive로 이전 (신규 archive 4개)**:
- `archive/quad2-try-research-findings-rejected.md` — `bind-system-plan.md`에
  60줄 넘게 남아있던 quad2-try(폐기된 이전 재작성 시도) 리서치 전문(OOP
  상속/커스텀 파서/Slot 빈 스텁/`Pipe` copy-on-write 4가지 확인된 죽은
  접근 + Unix 파이프 영감이라는 원래 동기 서사)을 통째로 이전 — "반복
  조사 금지" 결론과 `state(state)` 조합 모델 포인터만 본문에 남김.
- `archive/observer-cleanup-contract-rejected.md` — `effect-plan.md`의
  "Observer 자체에 React `useEffect`식 cleanup 반환 계약을 추가하는 안"
  기각 서술(코드 예시 포함) 이전.
- `archive/keyed-collection-state-method-rejected.md` — `additional-primitives-plan.md`의
  "키 기반 동적 컬렉션 재조정을 `state:Keyed(...)` State 메소드로 두려던"
  초안 기각 서술 이전(이 프리미티브 자체는 여전히 열린 질문 — 폼 팩터
  결정 부분만 이전됨).
- `archive/debug-channel-replicatedstorage-rejected.md` — `debug-tooling-plan.md`의
  "`ReplicatedStorage` 자동 생성" 초안 기각 서술 이전.

각 archive 파일은 기존 컨벤션(`[기각됨]` 제목, "현재 유효한 설계" 포인터,
`quadnomicon` 소재 메모)을 그대로 따름, `README.md`의 archive 인덱스도
4개 항목 추가로 동기화 완료.

**의도적으로 손 안 댄 것들**: `bind-system-plan.md`의 PreRef pre-pass
위치 관련 기각 서술, `lifecycle-pattern.md`의 `canExecute` 시그니처
재정정 단락, `modifier-plan.md` 9-1(b)의 "동질적/이질적" 초안 — 전부
현재 설계를 정당화하는 근거로 너무 밀착돼 있어서, 분리하면 "왜 이렇게
안 했는지"가 같이 잘려나가 다음 에이전트가 같은 대안을 또 검토할
위험이 있다고 판단해 그대로 둠. `documentation-content-map.md`가 최근
추가된 5개 base 문서(`relate`/`blocker`/`effect`/`tag`/`attribute`-plan.md)의
초심자/api/심화 분류를 아직 안 갖고 있는 것도 실제 설계 판단(콘텐츠
분류)이 필요해 손 안 댐 — 문서 자신도 이미 "지금 당장 안 급함"이라고
인정하고 있음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, 위 "다음 세션 예고"
Slot/키 기반 컬렉션 재조정도 그대로) — 이번 세션은 순수 문서 위생
작업이라 설계 우선순위엔 영향 없음.

## 2026-08-09 세 번째 세션 — Slot CRUD 완전 확정, 키 기반 동적 컬렉션
재조정이 `Slot:List(...)` 메소드로 통합·승격

위에서 예고된 "다음 세션 주제"(Slot과 키 기반 동적 컬렉션 재조정)를
실제로 다룬 세션. `pre-implementation-audit.md` 1-7/1-8과
`research/additional-primitives-plan.md`의 마지막 열린 항목이 전부
`base/slot-plan.md`에 흡수·확정됐음 — 상세는 그 문서 본문이 소스,
여기는 요지만:

- **Slot CRUD 최종 확정**: `Add(element, index?)`/`Remove(element)`(제거+파괴)/
  `Extract(element)`(제거, 파괴 안 함)/`Clear()`(전체 `Remove`) — `get`/`set`은
  드롭(YAGNI). 식별은 항상 element 레퍼런스 기준(인덱스 아님). 에러 조건
  전부 즉시 `error()`(이미 다른 곳에 마운트된 element를 `Add`, 멤버 아닌
  element를 `Remove`/`Extract`) — fail-fast 톤 유지. 재진입성은 별도 가드
  불필요(기존 "무한루프 방어 안 함" 원칙 재사용). `Slot()`은 인자 없는
  빈 생성자로 확정.
- **`isMounted` 이중 추적 분리(1-8 해소)**: Slot 컨테이너 자신은
  `self._mounted`(트리거는 `Dispatch.process`가 이 Slot 객체에 실제로
  호출된 시점 — 다른 모든 "마운트됨" 판정과 동일하게 dispatch-process
  기준), 개별 element는 전역 weak-set(라이브러리 전역 다중 마운트 금지
  불변식이라 특정 Slot에 안 묶임).
- **`Extract` 후 portal 범위 — 임의의 다른 Slot으로 자유 이동 확정.**
  기존 "retract되는 slot은 폐기되지 옮겨지지 않는다"는 확정은 **프레임워크가
  store-bind 재실행으로 값을 통째로 갈아치우는 시나리오**에만 해당하고,
  사용자가 명시적으로 `Extract`→`Add` 두 번 호출해서 옮기는 것과는 다른
  얘기라는 걸 명확히 구분(사용자 확인).
- **키 기반 동적 컬렉션 재조정 — `Slot:List(data, keyFn, renderFn) -> Slot`로
  확정, 자유 함수/새 타입 둘 다 기각.** 처음엔 `List(...) -> Slot` 자유
  함수를 검토했으나, "타입 이름=반환 타입"이라는 `Source(default)`류
  팩토리 컨벤션이 깨진다는 문제를 사용자가 직접 지적 — Source⊇State식
  구조적 서브타입도 검토했으나 List가 Slot 위에 새 공개 메소드를 안
  얹으므로(그냥 "자동으로 채워지는 Slot") 별도 타입일 근거가 약해 기각.
  최종적으로 "원천에 종속된 파생 데이터는 메소드로만 얻어진다"(State/
  Observer와 같은 원칙, 여기 원천은 Slot 자신)로 수렴 — `Ref():Callback(fn)`
  체이닝과 같은 패턴. Fusion `ForPairs`/`ForKeys`/`ForValues` 3분할도
  단일 `:List`로 통합 확정.
- **구현 메커니즘은 전부 기존 프리미티브 재사용, 새 개념 없음** — 사용자가
  "너무 마법같다"고 지적해 의사코드까지 구체화해서 검증: `data:Observer(fn)`
  (2026-08-07 확정된 "등록 즉시 1회 실행"), `Source(item)`, 방금 확정한
  Slot CRUD의 비공개(가드 안 거치는) 버전 세 개의 조합일 뿐. `itemSources`/
  `elements`/`order`는 Slot 인스턴스의 평범한 클로저 업밸류(별도 전역
  저장소 불필요). 리오더는 `Extract`+`Add(index)` 조합, 최소-이동
  알고리즘 자체는 구현 시점 최적화로 미룸.
- **`renderFn(key, itemState)`의 `itemState`는 내부 `Source`를 그냥
  `State`로 다운캐스트해서 넘김 — 별도 `ReadOnlySource` 타입 안 만듦**
  (사용자 확인: "그걸 위해 ReadOnlySource 같은 걸 만들 이유가 있냐 하면
  아니다, 이미 그게 State다"). 타입 레벨 힌트만, 런타임 강제 없음(`Peek`/
  Modifier UB와 같은 "규율 위반은 방어 안 함" 기조) — 나중에 진짜
  런타임 강제가 필요해지면 `src:Compute(function(v) return v end)`(항등
  함수 Compute)로 `:Set` 없는 State를 만드는 가벼운 대안이 있다는 것만
  메모.
- **백로그, 착수 안 함(연구만) — reconcile의 무조건 `:Set()` 재전파.**
  `data`가 테이블 뮤테이션+`:Emit()`으로 오는 경로도 지원해야 해서 이전
  값과 동등성 비교를 할 방법이 없고, 그래서 값이 실제로 안 바뀐 item도
  매 재계산마다 재전파됨 — 사용자 판단: "이 재계산 비용은 우리가 핸들해야
  할 부분은 아닌 것 같다", `Blocker`류 값-동등성 기반 전파 억제도 검토했으나
  "확정 안 하면 이전 값 자체가 없어서 비교가 안 된다"는 근본적 어려움이
  있어 기술적으로 더 논의해볼 만한 주제로만 `research/
  additional-primitives-plan.md`에 백로깅.
- **`research/additional-primitives-plan.md` 사실상 전부 해소** — 마지막
  열린 항목(키 기반 컬렉션)까지 없어져서, 이 문서엔 이제 새로 열린 설계
  질문이 없음(배경 자료로만 유지). `question.md`/`ROADMAP.md`(M6 체크박스)/
  `README.md` 전부 동기화 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — Slot/키 기반 컬렉션
재조정이 이번 세션에서 완결됐으므로 더 이상 "다음 세션 예고" 대상 아님.
남은 열린 것은 여전히 `question.md`의 `DI`→`D`/`canExecute`→`isAlive`/
`Brand` 이름, `pre-implementation-audit.md` 1-3(우선순위 스캔 동률 처리),
"여러 Slot이 형제로 섞일 때 순서 보장"(Roblox 단일 백엔드론 급하지 않음)
정도.

**같은 세션 후속 — quad-roblox 구현 관점에서 재검토, `Move`/`Swap` 공개
CRUD로 추가(원시 최소화 원칙 뒤집음), `renderFn`에 `indexState` 추가.**
사용자가 "Slot 값 변경을 quad-roblox가 실제로 어떻게 따라가나"를 구체적으로
캐물으며 세 가지가 드러남:
- **`renderFn(key, itemState) -> element`에 위치 정보가 빠져있었음** —
  Roblox는 순서를 `LayoutOrder`로 표현하므로 `renderFn`이 그걸 반응형으로
  바인딩하려면 위치도 State로 받아야 함. `itemState`와 독립된
  `indexState: State<number>`를 추가(`renderFn(key, itemState,
  indexState)`) — 값 변경/위치 변경은 서로 독립 신호라는 게 근거, Slot이
  `LayoutOrder`를 대신 관리해주는 마법은 안 둠.
- **`Extract`+`Add(index)`로 리오더를 구현하면 백엔드에서 진짜 Parent
  조작이 두 번(detach+reattach) 일어난다는 게 드러남** — Roblox
  `AncestryChanged` 발화, 잠재적 깜빡임, 불필요한 재바인딩 비용까지
  딸려올 수 있어 매 `:List` 재계산마다 흔한 케이스치고 과함.
  **`Move`(O(n), 배열 splice 의미)/`Swap`(O(1), 순수 페어 교환)을 공개
  CRUD로 추가** — 둘 다 Parent를 안 건드림. `:List` 없이 수동으로 Slot을
  구성하는 사용자에게 애초에 리오더 수단이 아예 없었다는 것도 같이
  드러난 공백 — "원시 연산 최소화" 원칙보다 이 두 실사용 공백이 우선한다고
  판단해 뒤집음(같은 세션 내 정정이라 별도 archive 없이 `slot-plan.md`
  본문에 "원시 최소화 원칙 정정" 절로 직접 반영).
- **base/roblox 패키지 경계에 mount/unmount 둘로는 부족, reposition
  훅이 세 번째로 필요함** — `Dispatch/Slot.luau`/`Handlers/Slot.luau`가
  이제 "Parent 조작(mount/unmount)"뿐 아니라 "Parent 안 건드리는 재배치
  (reposition, `Move`/`Swap`)"까지 계약해야 함. quad-roblox가 이걸
  `SetSiblingIndex`로 구현할지, `LayoutOrder` 기반 정렬이라 사실상 no-op
  으로 둘지는 구현 선택으로 열어둠.
- **item 값 전파(무조건, 백로그)와 index 전파(실제 변경시만)가 비대칭인
  이유도 명확해짐** — item 값은 외부 뮤테이션+`Emit()` 경로 때문에 "이전
  값"을 비교할 방법이 없지만, `:List`가 전적으로 소유하는 `keyIndex`는
  "실제로 위치가 바뀌었는지"를 정확히 알 수 있어 index 쪽엔 같은 문제가
  없음 — 그래서 index 전파는 처음부터 조건부로 구현.

전부 `base/slot-plan.md`(CRUD 표, "원시 최소화 원칙 정정" 신규 절, `:List`
구현 스케치·설명 갱신)/`ROADMAP.md`(M6)/`README.md` 반영 완료. `question.md`엔
새로 열린 항목 없음 — 이번 후속도 순수 확정/구현 세부 명확화.

**같은 세션 두 번째 후속 — `Swap`을 element 레퍼런스가 아니라 인덱스
기준으로 정정, "공개 CRUD는 가드+`raw*` 위임" 구조 명문화.** 사용자가
`Swap(elementA, elementB)`를 바로 잡음 — element 레퍼런스로 받으면 Slot이
element→index 역방향 맵을 안 갖고 있는 이상 두 element의 현재 위치를 각각
찾는 데 O(n)씩(총 2n) 들어서, `Swap`이 약속한 O(1)이 그 자리에서 깨짐.
`Move`는 시프트 자체가 O(n)이라 조회 비용이 묻히지만 `Swap`은 조회 비용이
곧 전체 비용이라 이 차이가 그대로 드러남 — `Slot:Swap(indexA, indexB)`로
정정(호출부가 이미 "몇 번째와 몇 번째를 바꿀지"를 아는 상황, 예: 드래그
리오더 UI, 이라는 것도 자연스러움의 근거). 이어서 사용자가 "`Slot:Move`
구현은 결국 락(`_listed`) 확인만 하고 실제 로직은 `rawMove`류에 다 있는
구조 아니냐"고 확인 요청 — 맞다고 답하며 이걸 여섯 CRUD 전체에 적용되는
일반 구조로 명문화: `Add`/`Remove`/`Extract`/`Clear`/`Move`/`Swap` 전부
"`self._listed` 확인 + `raw*` 위임"뿐인 얇은 wrapper, 실제 로직은 전부
`raw*` 함수 세트 하나에 있고 `:List`의 reconcile도 그 세트를 가드 없이
직접 호출. 전부 `base/slot-plan.md`/`ROADMAP.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 세 번째 후속 — Slot 요소 타입 제약 신설: `nil` 금지/`None`
허용/핸들러 계층 값(Ref/PreRef/Observer/Effect/Modifier) 금지, `Slot<T>()`
제네릭화.** 사용자가 "Slot 안에 뭐가 들어갈 수 있는지 정해진 바 없다"고
지적하며 시작 — 처음엔 제가 "Ref/Observer/PreRef도 Slot 요소로 허용,
`D.InstSlot = Slot<<Instance>>`류 백엔드 별칭으로 좁히자"고 제안했으나,
사용자가 바로 반박: Slot이 동적으로 다뤄지는데 그 안에 Ref/Observer가
들어가면 quad-roblox가 그걸 처리할 방법이 없고(특수 대응을 새로 만들어야
해서 오버엔지니어링),애초에 왜 필요한지도 불명확하다는 지적 — 검증해보니
정확히 맞았음:
- `Dispatch/Leaf.luau`가 처리하는 "children 배열에 Ref/Observer/PreRef가
  직접 놓이는" 케이스는 **그 컴포넌트가 지금 만들고 있는 Instance 자기
  자신을 가리키는 self-ref 캡처**라(`Frame { PreRef():Callback(fn) }`가
  그 Frame 자신을 잡음), `inst`가 "지금 생성 중인 바로 그 하나의 Instance"로
  고정돼 있어야 의미가 성립함. Slot은 특정 컴포넌트 호출 하나에 안 묶이고
  이미 존재하는 부모에 나중에 독립적으로 붙는 동적 리스트라 이 전제
  자체가 없음 — Slot 안의 Ref가 "무엇"을 가리켜야 하는지 정의가 안 됨.
- 대체 경로가 이미 있어 능력 손실도 없음 — 특정 child에 ref가 필요하면
  그 child를 만드는 컴포넌트 호출 자체에 Ref를 넘기면 됨
  (`slot:Add(Frame { Ref = myRef })`).
- 사용자가 직접 대비시킨 반례도 정확함: `State<Slot>`(Slot 자체가 State의
  값)은 retract 시 통째로 버려지고 다시 채워지는 굵은 단위 교체라 이미
  확정된 모델(폐기, 재구성)과 맞지만, Slot **요소 하나하나**로
  Ref/Observer가 들어가는 건 그런 굵은 단위 교체가 아니라 세밀한 CRUD
  대상이라 성격이 다름.
- **결론**: `Modifier` 필드가 핸들러 계층 값을 담으면 즉시 `error`로
  확정했던 것과 같은 판별 메커니즘(`isRef`/`isPreRef`/`isObserver`/
  `isEffect`/`isModifier` Brand predicate)을 Slot에도 재사용 — 새
  메커니즘 없이 그대로 막음. 덕분에 `Slot<T>`의 `T`도 "실제로 마운트
  가능한 최종 값의 타입"으로 단순해짐 — quad-roblox엔 사실상 `T =
  Instance` 하나뿐이라 `D.InstSlot = Slot<<Instance>>`가 사실상 "그"
  Slot 타입. `nil`은 기존 배열 파트 `None` 원칙을 그대로 적용해 금지,
  `None`은 `:List`의 `renderFn`이 "이 item은 이번엔 스킵"을 표현하는
  용도로 허용 — `renderFn`의 반환 타입도 `T | None`으로 갱신.
- `Slot<T>()`가 무인자 생성자라 `T` 추론이 안 되므로 tbox 명시적 제네릭
  적용(`Slot<<Instance>>()`)이 필요하다는 것도 같이 반영 — 정확한 문법은
  "자식으로 넘기는 클래스 스토어" 절의 기존 tbox 참고 미결과 같은 갈래로
  묶어 열어둠.

전부 `base/slot-plan.md`(신규 "요소 타입 제약" 절, CRUD 에러 조건,
`renderFn` 반환 타입) 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 네 번째 후속 — `Slot:List`의 `renderFn`을 "1회 호출"에서
"매 사이클 호출 + `before` 재사용"으로 재설계, filter/toggle 문제 해결.**
사용자가 두 가지를 연달아 제기: (1) `renderFn`이 `None`을 반환해 "지연
렌더"를 표현하는 아이디어는 좋지만, State 변경으로 이미 렌더된 필드를
나중에 다시 지워야 하는 경우(filter)는 기존 "1회만 호출" 모델로 안 풀림.
(2) filter/sort를 Slot에서 어떻게 구현할지가 문제 — 흔한 회피책인
"`Visible`만 토글"은 필터링된 item도 여전히 완전히 살아있는 Instance로
남겨서(애니메이션/이벤트 연결 계속 돎) 200개+ 리스트에서 lazy하지 않다는
실질적 비용이 됨.

**해법 — 사용자가 직접 제시**: `renderFn(itemState, before: inst?): inst?`
모양으로 바꿔 **매 reconcile 사이클마다 호출**하되, 이전에 마운트된
element(`before`, 없으면 `nil`)를 받아서 `if before then return before
end`(바꿀 거 없으면 그대로 반환, 값 갱신은 이미 물려있는 반응형 바인딩이
자동으로 함)로 저비용 재사용 경로를 만듦 — filter 탈락 시엔 `nil` 반환으로
**진짜 파괴**(Visible 토글 아님). 편의상 `renderFn`이 raw `nil`을
던지는 게(Lua에서 자연스러운 관용구) `None`보다 편하다는 것도 사용자가
지적 — 검토 결과 `renderFn`의 반환값은 raw Slot 요소로 직접 들어가는
게 아니라 `:List`의 reconcile이 해석만 하는 것이라, `nil`을 받아도 위
"요소 타입 제약"(raw Slot 요소는 `nil` 금지)과 전혀 안 부딪힘 — `nil`/
`None` 둘 다 "스킵" 신호로 동일하게 받아들이기로 정리.

**부수적으로 드러난 것 — "이전 상태를 다음 렌더에 어떻게 넘기냐" 문제는
이미 해소돼 있었음.** 사용자가 "item이 보통 plain table이라 매 렌더마다
Source/Store를 새로 안 만들려면 이전 상태를 어딘가 저장해야 하는데 그게
어렵다"고 우려했으나, 확인해보니 `itemSources[key]`/`indexSources[key]`가
`renderFn` 호출 여부와 무관하게 **처음부터 `:List` 자신이 계속 소유**하고
있어서(원래 설계 그대로) — `renderFn`이 매 사이클 불려도 이 부분은 전혀
안 바뀜, item이 filter 탈락 후 재등장해 Instance가 파괴됐다 새로 만들어져도
반응형 Source는 안 끊기고 그대로 이어짐. 이 부분은 재설계가 아니라 기존
설계가 이미 답이었다는 걸 확인한 것.

**sort는 이번 재설계와 무관** — 호출부가 `data` 순서를 바꾸면 기존
`keyIndex`/`Move` 메커니즘이 이미 처리, 새로 손댈 것 없음(사용자가 filter와
같이 물었던 것 중 이건 원래도 문제 없었음).

전부 `base/slot-plan.md`(요소 타입 제약 절 "None 허용" → "nil/None 둘 다
금지"로 정정, `:List`의 `renderFn` 시그니처·구현 스케치·"왜 매 사이클
호출로 바뀌었는가" 신규 절)/`ROADMAP.md`(M6)/`README.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 다섯 번째 후속 — `renderFn` → `updateFn` 개명, `:List`가
`Source` 생성을 그만두고 `userdata`로 그 권한을 통째로 넘김.** 사용자가
"`renderFn`이 아니라 `updateFn`이 맞고, `itemState`도 `:List`가 강제로
만들지 말고 원문 item + `userdata: UD?` + `prev: T?`를 주는 게 낫다"고
제안 — 검토 후 채택, 근거:
- **`itemState`/`indexState`를 `:List`가 강제로 만드는 건 불필요한 강요였음**
  — 반응형이 필요 없는 단순한 행까지 전부 `Source` 생성 비용을 지게
  했음. `userdata`로 권한을 넘기면 필요한 item만 자기 `Source`를 만들어
  `userdata`에 담고, 나머지는 매번 raw `item`에서 다시 계산해도 됨 —
  `:List`가 미리 정할 이유가 없는 선택.
- **"이전 상태를 다음 호출에 넘기는" 문제, 원래 걱정했던 것과 달리
  `userdata`라는 명시적 채널로 완전히 해소됨** — item이 plain table이라
  매번 `Source`를 새로 안 만들려면 어딘가 저장해야 한다는 우려가 있었는데,
  `userdata`가 정확히 그 저장소.
- **`prev`(구 `before`)와 `userdata`가 원래 비일관적이었음** — 사용자가
  직접 지적: 하나(`prev`)는 `:List`가 자동 관리하는데 다른
  하나(`userdata`)만 수동 반환을 요구했음. 해법은 **둘 사이 커플링을
  완전히 제거** — `result`가 `nil`이라고 `:List`가 `userdata`를 자동으로
  안 지움, 그대로 기록만 함. 흔한 경우(둘 다 리셋)는 `return nil` 하나로
  Lua가 나머지 반환 슬롯을 알아서 `nil`로 채워주고, "파괴하되 캐시는
  남기고 싶다"는 정당한 패턴은 `return nil, ud`로 명시적으로 표현
  가능해짐 — 이전 설계(result nil이면 userdata 자동 삭제)로는 이 패턴이
  원천 봉쇄돼 있었음.
- **제가 놓칠 뻔한 버그를 사용자와의 논의 과정에서 직접 잡음**: `userdata`가
  이제 `mounted`(실제 element)보다 오래 살 수 있게 되므로, 정리 루프가
  `pairs(mounted)`만 순회하면 "필터 탈락 상태(mounted=nil)로 `userdata`만
  살아있던 key가 `data`에서 완전히 사라지는" 케이스를 못 잡고 새서
  — 직전 사이클의 전체 key 집합(`keyIndex`, 매 사이클 모든 key에 대해
  채워짐)을 순회하도록 정정.
- **부수 효과 — "item 값 무조건 재전파" 백로그가 사라짐**: `:List`가
  더 이상 `Source`를 안 만드므로 그 문제 자체가 `:List` 소관이 아니게
  됨, `updateFn` 작성자의 선택으로 넘어감.
- `userdata = userdata or {}`류 lazy-init 관용구가 `UD`가 자유 제네릭인
  채로 Luau 타입 시스템에서 잘 좁혀지는지는 실측 필요 항목으로 명시적으로
  남김(사용자가 직접 이 불확실성을 짚음) — M0/M6 착수 시 확인.

전부 `base/slot-plan.md`(`:List` 절 전면 재작성 — `updateFn` 시그니처/구현/
"왜 `Source`를 `:List`가 안 만드는가" 신규 절)/`ROADMAP.md`(M6)/
`README.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

**같은 세션 여섯 번째 후속 — `keyFn` 선택 인자화(파라미터 순서 정정),
`userdata` cleanup 훅 검토 후 기각·GC-native 제약 명문화, 문서화 순서
질문은 백로그로 이관.** 사용자가 세 가지를 짧게 제기:

1. **`Slot:List(data, keyFn, updateFn)` → `Slot:List(data, updateFn,
   keyFn?)`로 파라미터 순서 정정, `keyFn` 선택 인자화.** 실사용 대부분
   (사용자 추정 80%)이 item identity 추적 없이 순번을 key로 써도 충분한
   단순 목록이라 매번 `keyFn`을 명시하게 하는 게 불필요한 보일러플레이트 —
   생략 시 `function(item, index) return index end` 기본값. tradeoff(중간
   삽입/삭제 시 그 뒤 항목들이 "다른 item인데 같은 key"로 오인돼 캐스케이드
   갱신 — identity 보존 없음, 파괴/재생성 자체는 없음)는 React `key` 생략
   시 index 기본값 등 업계 흔한 관행과 같은 결이라 새로 설명할 개념 아님.
2. **`updateFn(item?, ...)`로 바꿔 최종 제거 시 "정리용 1회 추가 호출"을
   주는 안 — 검토 후 기각, 사용자가 직접 반례를 찾음.** 이 훅은 `data`에서
   key가 빠져 `reconcile`이 다시 도는 정상 경로에서만 발화하는데, **Slot을
   담은 부모 Instance 자체가 `Destroy`되는(가장 흔한) 경로는
   `reconcile`이 다시 안 돌아서 이 훅이 전혀 안 불림** — 절반만 동작하는
   정리 메커니즘은 없는 것보다 위험(사용자가 "정리가 보장된다"고 오해하고
   `Subscribe`류를 `userdata`에 넣었다가 Destroy 경로에서 조용히 샘).
   `retract`가 Destroy 시 절대 안 불린다는 기존 원칙(`lifecycle-pattern.md`
   "quad는 라이프사이클 중간에 있지 않다")과 정확히 같은 이유로 기각.
   **대신 `userdata`엔 GC-native 값만 담고, `:Subscribe()`한 Observer류처럼
   명시적 cleanup이 필요한 값을 담는 건 UB로 명문화** — quad 전역
   GC-native 원칙을 `:List`라는 구체 지점에 그대로 적용한 것뿐, 새 원칙
   아님.
3. **문서화 순서(getting-started에서 단순 버전만 가르치고 나중에
   `prev`/`userdata` 최적화를 알려줄지, 아니면 Slot이 학습 순서상 후반부라
   처음부터 완전한 형태로 가르칠지)는 결정 안 함** — `research/
   documentation-content-map.md`의 modifier/slot 절에 백로그로 추가,
   제 의견(후자 쪽으로 기욺)만 메모, 실제 콘텐츠 작성 시점 결정 사항이라
   지금 확정 안 함.

전부 `base/slot-plan.md`(`:List` 시그니처/코드 재정렬, `keyFn` 기본값
설명, "`userdata`의 생명주기 제약" 신규 절)/`ROADMAP.md`(M6)/`README.md`/
`research/documentation-content-map.md` 반영 완료.

**다음 세션이 할 일**: 여전히 안 바뀜(`ROADMAP.md` M0부터).

## 2026-08-09 여섯 번째 세션 — 여러 Slot이 형제로 섞일 때 순서 보장 완전
해소(Length/Offset), `unbindLifetime` 신설

**출발점**: 사용자가 미래의 `quad-web`을 가정하며 `{ Slot, Element, Slot }`처럼
Slot이 여럿 형제로 섞일 때 최종 순서를 어떻게 보장하는지 물음 —
2026-08-04부터 "Roblox 단일 백엔드로는 급하지 않음"으로 후순위 열려있던
질문(`slot-plan.md` "여러 Slot이 섞일 때 순서 보장" 절)을 실제로 라이브
설계해서 완전히 풀어낸 긴 단일 스레드. 시행착오를 거쳐 최종 수렴한 결론만
정리(중간 대안들 — "구간 예약"/`:With`+`:Compute` 체인 — 은 채택 안 됨,
사용자가 제시한 "정확한 누적합 + 플랫 재계산 루프"가 최종안):

- **핵심 전환**: "각 원소가 절대 위치를 계산해서 전파"가 아니라 "각
  구조적 위치가 자기 앞 형제들의 개수 누적합(`offset`)만 알면 됨" —
  Roblox `LayoutOrder`가 이미 `Instance.Parent` 물리 순서와 분리된
  정수 프로퍼티라는 사실이 이 전환을 공짜로 성립시킴.
- **`Dispatch.setLength(inst,i,len:number|State<number>)`/
  `Dispatch.setOffsetSource(inst,i,offset:Source<number>|None)`** —
  둘 다 Handler→Dispatch 등록(push) 방향, array part의 **모든** number
  인덱스에 대해 반드시 호출(생략 UB — Handler 구현체 작성자만의 계약,
  일반 사용자 영향 없음). `recompute`는 매번 `1..N` 전체를 도는 단순
  루프(N은 저작 시점에 고정된 배열 리터럴 길이라 무시 가능)로, 각
  `offset:Set()` 호출 앞에서만 `Get() ~= sum` 가드를 걸어 실제로 안
  바뀐 위치의 캐스케이드(다운스트림 `LayoutOrder` 재적용)를 막음 —
  전체 순회 비용과 `Set` 캐스케이드 비용을 분리해서 후자만 최적화.
- **각 원소의 `LayoutOrder`는 `localIndex+offset`의 State를 기존
  store-bind 프로퍼티 바인딩에 그냥 얹는 것** — 이게 이 설계의 가장
  큰 단순화 지점: "offset 변경 시 이미 마운트된 원소를 다시 써야 한다"는
  요구가 새 push/observer 메커니즘 없이 **이미 있는** store-bind
  재실행 모델(`state:Observer(fn):Subscribe()`) 재사용만으로 공짜로
  풀림.
- **`setLength`의 내부 Observer는 leaf-lifetime 경로(`bindLifetime`)를
  씀, `:Subscribe()` 아님** — 이 Observer는 특정 leaf가 아니라 `inst`
  자신에 종속된 내부 배관이라, `inst` Destroy 시 자동으로 안 죽는
  `:Subscribe()` 경로는 안 맞음. `State<Slot>` 교체처럼 `inst` 전체가
  죽기 전에 특정 위치 하나만 조기 재등록해야 하는 경우를 위해
  **`unbindLifetime(inst,value)`을 `bindLifetime`/`canExecute`의
  세 번째 짝으로 신설** — `Dispatch.setLength`가 gchold 내부 저장
  구조(배열/키드 테이블)를 몰라도 이전 등록을 블랙박스로 해제할 수
  있게 캡슐화. quad-roblox 구현 스케치도 gchold를 배열 대신 `value`를
  키로 쓰는 테이블로 바꿔 `unbindLifetime`을 O(1)로(`gchold[value] =
  nil`) — base 결정은 아니고 참고용 스케치.
- **동기 순서 요구사항**: Slot의 `rawAdd`는 `Length:Set(newCount)`
  (다운스트림 offset/LayoutOrder 캐스케이드가 여기서 동기적으로 끝남)
  다음에 `element.Parent = target`을 호출 — Source:Set()이 옵저버
  체인을 동기적으로 끝까지 도는 기존 모델 덕에 별도 배리어 없이 순서만
  지키면 자동 성립. 안 지키면 Roblox의 실시간 `UIListLayout` reflow가
  한 프레임 잘못된 순서를 노출할 위험.
- **`Slot.Length: State<number>`가 CRUD/`:List` 여부와 무관하게 항상
  노출되는 프리미티브 필드로 확정** — 사용자가 직접 "n개 검색됨" UI에도
  쓸 수 있다고 지적, `setLength`가 내부적으로 읽는 값과 완전히 동일(두
  용도를 겸함, 별도 State 아님). `:List`의 filter=진짜 Remove 확정
  덕에 "Visible 토글은 안 잡힘"이 자연히 성립(새 캐비엇 아님).
- **웹 백엔드(quad-web) 일반화 — base 로직 100% 재사용, backend
  Handler의 "offset 변경 시 할 일"만 달라짐**: DOM `insertBefore`는
  물리적 삽입 시 뒤 형제를 자동으로 밀어주므로, offset이 바뀌어도
  이미 마운트된 노드를 실제로 옮길 필요가 없음 — quad-web Handler는
  offset 변경 관측 시 no-op, 숫자는 그 위치가 **다음** insert/remove
  때 쓸 물리 인덱스로만 부기됨. 처음 검토했던 "구간 예약"(고정 gap)이나
  "앵커 기반 상대 삽입" 안보다 이 방식이 dense global rank라 두 종류
  백엔드(순서-분리 프로퍼티형/물리-순서형) 모두에 더 직접적으로 맞음.
- **백로그로만 남김**: `Slot():Single(state, updateFn?)` — `:List`의
  key-map 없이 "0 또는 1"만 다루는 가벼운 편의 메소드, 상세 설계 미착수.

**같은 세션 후속 — `bindLifetime`/`unbindLifetime`이 실제로 뭘 하는지,
`canBound`(이중 바인딩 금지)와의 관계를 여러 차례 시행착오 끝에 정확히
확정.** `Dispatch.setLength`가 이전 Observer 등록을 정리할 때 뭘 불러야
하는지를 두고 제가 세 번 틀렸다가 사용자가 매번 정정 — 경위와 최종
결론을 구분해서 기록:

1. **1차 시도(틀림)**: `unbindLifetime`이 `canExecute`를 즉시 `false`로
   만들어준다고 서술 — 틀림. `gchold`(순수 GC 방지용 강참조 테이블)는
   `canExecute`가 보는 값(Observer/Effect의 `.Subscribed`, 또는 `inst`의
   공유 `gcconn.Connected`) 어디에도 안 들어감, 완전히 무관한 테이블.
2. **2차 시도(틀림)**: 그래서 "`unbindLifetime`은 필요 없고 `:Unsubscribe()`
   만 쓰면 된다"로 후퇴 — 이것도 틀림. 사용자 정정: `:Subscribe()`/
   `:Unsubscribe()`는 **`inst`와 아예 무관한 전역/독립** Observer(모듈
   최상위 디버그 print 등, leaf도 없고 특정 Instance에도 안 묶인 경우)를
   GC로부터 지키기 위한 **전역** 강참조 테이블(`SubscribedObservers[observer]
   = true/nil`)일 뿐 — `Dispatch.setLength`의 Observer처럼 처음부터
   `inst` 하나에 종속된 내부 배관에는 원래부터 안 맞는 도구. "`inst`
   연관은 전부 `bindLifetime`/`unbindLifetime`으로"가 맞는 원칙.
3. **최종 확정**: 진짜 독립된 라이프사이클 경로는 **`:Subscribe()`(전역)
   와 `bindLifetime`(inst-scoped) 둘뿐** — "children 배열 leaf 부착"은
   세 번째 경로가 아니라 **`bindLifetime` 호출 그 자체**(`Dispatch/
   Leaf.luau`가 Observer/Effect leaf를 매치하면 그 자리에서
   `bindLifetime(inst, v)`를 호출), 이걸 제가 처음에 "leaf 부착/
   `:Subscribe()`/`bindLifetime` 셋 다 상호 배타"로 잘못 일반화했다가
   사용자가 "leaf 부착 자체가 bindLifetime을 호출하는 거라 동일 동작,
   상호배타는 아니다"로 정정. `canBound`의 내부 플래그도 새 필드가
   아니라 **`canExecute`가 이미 보는 `.Subscribed` 그 자체** —
   `bindLifetime`/`unbindLifetime`도(Observer/Effect 값에 한해) 이
   필드를 세팅/해제해야 `bindLifetime`으로 등록된 Observer가
   `canExecute`에서 정상적으로 "살아있음"으로 인식됨. Effect는 내부적으로
   Observer를 조합하므로 이 확장을 몰라도 자동으로 커버(사용자 확인).
4. **부수 정리**: 이미 확정돼 있던 StoreBind의 자기 재실행 Observer
   예제(`observer:Subscribe()`)도 같은 이유로 틀렸던 것이었음 확인 —
   `bindLifetime`/`unbindLifetime`으로 교체. "`:Unsubscribe()`는 자동
   (리프) 케이스에도 동일하게 씀"이라던 기존 서술도 같은 이유로 정정
   (리프/`bindLifetime` 경로의 조기 해제는 `unbindLifetime` 전용,
   `:Unsubscribe()`는 `inst`를 몰라 대신 처리 못 함).

전부 `base/bind-system-plan.md`(신규 "Length/Offset" 절, "이중 바인딩
금지" 절 정정 — 2-way로 재확정, StoreBind 예제 교체)/`base/slot-plan.md`
(열린 질문 해소, `Slot.Length` 절, `:Single` 백로그 절)/`base/
lifecycle-pattern.md`(`unbindLifetime` 추가 + `canBound`/`.Subscribed`
연동 반영)/`ROADMAP.md`(M2/M3/M6)/`.claude/question.md` 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

## 2026-08-09 일곱 번째 세션 — `Slot:List`의 `data:Observer(fn)` 구독도
마운트 시점 lazy `bindLifetime`으로 확정 (Destroy 후 재실행 gap 해소)

사용자가 "Slot이 마운트된 대상이 Destroy로 죽으면 `updateFn` 재실행이
`canExecute`로 막히고 있는 게 맞냐"고 질문하며 시작 — 확인 결과 **두 메커니즘이
다른 상태였음**: `Dispatch.setLength`(Length/Offset, 여섯 번째 세션 확정)는
이미 정확히 그렇게 돼 있었지만(Slot 마운트 시점에 `bindLifetime(inst,observer)`),
`Slot:List`의 `data:Observer(fn)` 구독은 `:List()` 호출 그 자리에서 즉시
만들어져(`inst`를 모르는 시점) `bindLifetime`이 전혀 안 걸려있던 실제 gap —
사용자가 정확히 캐치함. 사용자가 이어서 "실제로 Instance에 바인드되려 시도될
때(=마운트 시점)로 구독 자체를 lazy하게 미루면 되지 않냐"고 제안, 검증 후
확정. `base/slot-plan.md`(`:List`의 "구현"/"구독 시점" 절 재작성 +
"base/roblox 패키지 경계" 절 보강)/`ROADMAP.md`(M6)에 반영 완료:

- **`Dispatch.setLength`가 이미 쓰던 패턴을 그대로 재사용, 새 메커니즘
  없음.** `:List(data,updateFn,keyFn)`는 이제 설정만 저장하고 반환 —
  실제 `data:Observer(fn)` 구독과 최초 `reconcile`은 Slot 컨테이너 자신이
  마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self)`, `self._mounted`를
  세팅하는 바로 그 자리)에 `activateList(self,inst)`가 수행.
- **`:List()`가 마운트 이후에 불리는 경우 — `self._mounted`면 즉시 활성화로
  확정(사용자 확인, 세 가지 대안 중 1번).** 마운트는 1회성 이벤트라 순서가
  뒤바뀌면 그 이벤트를 못 기다리므로, `:List()`가 `self._mounted`를 직접
  확인해서 이미 참이면 그 자리에서 즉시 `activateList` — 호출 순서 제약을
  새로 추가하지 않음.
- **canExecute와 "등록 즉시 1회 실행"의 관계를 사용자가 직접 짚어 확정**:
  `data:Observer(fn)` 등록 시점(=`bindLifetime` 호출 *이전*)의 최초 1회
  실행은 `canExecute`/`Subscribed` 게이팅과 무관하게 무조건 일어남 — 이
  시점엔 아직 `Subscribed`가 안 세팅돼 `canExecute`를 물으면 거짓이겠지만,
  애초에 최초 실행은 게이팅 대상이 아니라서 상관없음(`Dispatch.setLength`가
  이미 "등록 즉시 1회와 겹쳐도 무해"로 같은 구조를 갖고 있었음). `bindLifetime`은
  등록 직후에 걸려 **이후** 재실행만 게이팅.
- **Destroy 이후 "재실행 막기"+"관측 자체를 관두기"가 새 코드 없이 한 번에
  해결됨** — `inst` Destroy 시 `gcconn`이 죽어 `canExecute`가 거짓이 되고
  향후 재실행이 no-op되는 동시에, `gchold`가 `Relate(inst)`(weak-keyed)
  아래 있어서 `inst`가 죽으면 그 안에 강참조로 잡혀있던 Observer/클로저
  (`mounted`/`userdata`/`keyIndex` 포함)가 전부 GC 대상이 됨 — 명시적
  구독 해제 코드가 안 필요함, `lifecycle-pattern.md`의 "정리는 기본적으로
  GC에 위임" 원칙 그대로.
- **부수 관찰(메모만, 설계 아님)**: 사용자가 "`Relate`로 마운트된 대상을
  weak하게 구할 수도 있겠다"고 언급 — `bindLifetime`이 `Relate(inst)` 기반이라
  나중에 "이 `inst`에 지금 뭐가 붙어있는가" 역조회가 같은 저장소로 가능해
  보임, quad-debug 그래프 UX와 맞닿을 수 있음. 지금 설계 안 함, 필요성
  확인되면 그때.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

## 2026-08-09 여덟 번째 세션 — `.claude/base/` 전체 중간검토(질문 모드),
실제 설계 결함 다수 발견·수정

사용자가 "이 프로젝트의 계획을 중간검토합니다. 각 요소들에 대해서 함수나
클래스 등의 동작을 제가 확인 가능하게 리스팅해요... 질문 모드를 쓰면
좋겠습니다"라고 요청 — 2026-08-04 6차 라운드 때 예고해뒀던 "다음 세션
검증 패스"를 실제로 실행한 세션. 서브에이전트 6개를 병렬로 띄워
`.claude/base/` 전체(15개 파일, 5296줄)를 클러스터별로 정독시켜 확정된
API/동작을 file:line 인용과 함께 그라운딩된 리스팅으로 뽑아낸 뒤, 6개
배치(Store/State/Source+Dispatch, Ref/PreRef+Brand+Length-Offset+생명주기,
Modifier, Slot, Tag/Attribute/UI shorthand+Blocker/Effect, 컴포넌트
경계+아키텍처)로 나눠 각 배치를 텍스트로 보여주고 바로 `AskUserQuestion`
(문제없음/문제있음)으로 확인받는 방식으로 진행 — 문제 제기된 건 그
자리에서 바로 문서에 반영(끝까지 미루지 않음). 총 24개 확인 질문 중
약 1/3에서 실제 설계 결함이 나옴 — 전부 사용자가 구체적인 반례/Luau
시맨틱스를 근거로 지적한 것이라 전부 그대로 수용, 방어하지 않고 수정.

**발견·수정된 것 (파일별)**:

- **`base/bind-system-plan.md`** (가장 많이 고침):
  - `Source(default)`/`Ref(default)`의 `default` 생략이 "선택"이라는
    서술에 "`T`가 nilable일 때만 안전하다"는 캐비엇 누락 — 추가.
    `Ref`는 `:Callback`이 등록 즉시 발화해서 이 문제가 더 잘 드러남.
  - Dispatch 체인 절에 "`handler.process`를 `Dispatch.process` 없이
    직접 호출하면 UB(체인 bookkeeping이 깨져 `retract`가 영영 안
    불리거나 정합성이 무너짐)"라는 불변식이 안 적혀 있었음 — 추가.
  - **Ref 콜백/대기자 배열의 소진 슬롯을 `None`에서 `nil`로 되돌림** —
    2026-08-07 열 번째 세션에 "구멍 있는 정수 키는 순회 순서가 깨진다"는
    이유로 `None`으로 바꿨던 게 이 배열엔 안 맞는 처방이었음(사용자
    지적): 이 배열은 순서가 안 중요해서 일반화 `for`가 구멍이 있어도
    전부 방문하고, 오히려 `None`을 쓰면 슬롯이 영원히 안 비어서
    `:Wait()`마다 배열이 끝없이 길어지는 새 문제가 생김 — `nil`로
    지우고 빈 슬롯을 재사용하는 등록 함수로 바꿈. PreRef pre-pass/
    Length-Offset의 `sourceList`는 순서가 실제로 중요해서 계속 `None`이
    맞음 — 두 사례를 헷갈리지 않게 교차 참조로 명확히 구분.
  - `.Value`가 평범한 hash 필드가 아니라 `__index`로 구현돼야 하는
    이유(콜백 배열과 같은 테이블에 있으면 `T`가 함수/스레드일 때 콜백
    처리 루프에 오분류될 위험) 추가.
  - **`isRef`/`isPreRef`를 `isState`/`isSource`와 같은 상위-하위 합성
    패턴으로 재정정** — 원래 "서로 배타적인 형제 브랜드"였는데, `Source`가
    `State`를 만족하듯 `PreRef`도 `Ref` 런타임을 재사용하는 관계라
    같은 방향(하위=PreRef가 상위=Ref에 포함)으로 다뤄야 일관적이라는
    지적 — `isPreRef`가 가장 구체적인 항등, `isRef`는 그 위에 얹힌
    상위 개념. `(v=Ref)` children leaf 매치 핸들러는 이제
    `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 함.
  - `NoneHandler`가 `k` 타입을 안 가리는데 왜 배열 파트 `None`(숫자
    키)에 실제로 안 걸리는지 명확화(배열 파트 `None`은 애초에
    `Dispatch.process`를 안 타서 `NoneHandler`가 볼 기회 자체가 없음).
  - `setLength`/`setOffsetSource`의 `None` 페어링 대상을 "Ref/PreRef
    등" 예시 목록에서 "그 배열 위치의 값 자체가 `None`인 모든 경우"로
    명시적으로 확장, 둘이 항상 짝을 맞춰야 한다는 점도 재강조.
  - `:Subscribe()`가 quad 전역 GC-native 원칙의 의도적 예외(참조를
    다 놓아도 GC 안 되고 계속 실행됨)라는 경고가 없었음 — 추가, 용도도
    "완전히 top-level" 케이스로 좁혀 문서화.
- **`base/modifier-plan.md`**: 핸들러 계층 값 → error 체크가 `State<Ref>`류
  "State/Source가 감싼 내부 값"까지는 못 잡는다는 한계 — 명시적 UB로
  문서화(오버엔지니어링 방지, 실사용 위험 낮음).
- **`base/slot-plan.md`** (가장 큰 변경): **CRUD 식별 기준을 element
  레퍼런스에서 인덱스 기준으로 전환** — `Remove(index)`/
  `Extract(index, newElement?)`/`Move(oldIndex, newIndex)`. 원래
  "인덱스는 stale해진다"는 이유로 레퍼런스 기준을 택했는데, 실제로는
  반대(호출부가 `Add` 리턴값을 안 담고 흘려버리는 경우가 흔함)가 더
  큰 문제였음. **`ExtractAll()`/`Get(index)`/`IndexOf(element)` 신설**
  (`Get`은 "YAGNI"로 드롭했던 걸 재추가). **`Extract(index, newElement?)`
  신설** — 교체가 필요하면 기존엔 Extract+Add 이중 O(n) 시프트가
  필요했는데, 이제 O(1) 제자리 교체 가능(이전 element 반환).
- **`base/tag-plan.md`**: `TagHandler.retract`의 전체 삭제 동작이
  정확히 `v == nil`일 때만 맞다는 전제를 `assert`로 명시(기존엔 "v를
  안 봐도 됨"이라고만 서술돼 있어 조건이 암묵적이었음).
- **`base/attribute-plan.md`**, **`.claude/question.md`**: 타입
  파라미터화(`Attribute<<T>>` 제네릭 vs `BooleanAttribute`류 정적
  패밀리) — "미확정"에서 **"둘 다 채택"으로 확정**(내부 구현 동일,
  호출부 표기만 다름). `=` 뒤 값 타입까지 narrowing되는지는 M0/M10
  실측 필요(안 돼도 런타임 무관)로 명시.
- **`base/ui-shorthand-plan.md`**: `UICorner`/`UIPadding`/`UIScale`이
  타입 생성 스크립트가 만드는 `FrameModifier`류 타입의 메소드 목록에도
  포함돼야 한다는 체크리스트 항목 추가(런타임과 무관한 순수 타입
  생성 디테일).
- **`base/effect-plan.md`**: `EffectHandle`이 내부 Observer를 필드로
  강참조한다는 것, `bindLifetime`/`:Subscribe()` 둘 다 `state`가 있으면
  내부 Observer까지 cascade해야 한다는 것(안 그러면 내부 Observer의
  `canExecute` 게이팅이 올바른 `inst`를 못 봄) — 재확인 후 명시화.
- **`base/component-composition-plan.md`** (Length/Offset 다음으로 많이
  고침):
  - **"리프 바인딩엔 Source가 좁은 예외"라는 서술이 틀림 — 정정.**
    `local a = Source(true); Frame { Visible = a }; a:Set(false)`처럼
    Source를 리프에 직접 물리는 건 이미 확정된 "Source가 State를
    구조적으로 만족" 원칙이 그대로 커버하는 정상 경로였음 — "State가
    일반적"이라는 서술은 Source를 못 쓴다는 뜻이 아니라 "여러 값에서
    파생된 계산 결과는 State일 수밖에 없다"는 통계적 경향 서술일
    뿐이라고 재정정.
  - `props.Modifier or None` 관용구의 `None` 근거 포인터가 Ref 콜백
    배열 정정으로 깨질 뻔한 걸 교차 참조로 바로잡음(그 배열은 순서가
    중요한 별개 케이스라 `None`이 계속 맞음).
  - `Frame { Comp{} }`에서 `Comp`가 `Slot`을 반환하는 다중 루트 우회
    경로가 새 배선 없이 그대로 작동함을 재확인(값이 컴포넌트 호출로
    왔든 리터럴이든 디스패치 입장에선 구분 없음).
- **`ROADMAP.md`**: 위 `Ref` `None`→`nil`/`isRef`·`isPreRef` 변경사항
  체크박스 동기화.

**변경 없이 확인만 된 것**: `:With`/`:Compute` 체이닝, `None` 센티널
기본 메커니즘, Length/Offset 전체, 이중 바인딩 금지/`Relate`/생명주기,
Modifier setter/Apply/Overridden 판단 기준, `Peek`/`isState`/`None`
setter 인자, Slot 요소 타입 제약/Extract portal/`Length`, `Slot:List`
시그니처(단, 캐스케이드 성능 이슈는 `keyFn` 명시 유도로 이미 문서화돼
있어 추가 조치 불필요), List 구독 lazy 시점, Tag 값 모양/패키지 배치,
Blocker 전체, 소스트리/네이밍 컨벤션/Handler 3분류/테스트 전략/이식성
원칙.

**부수 기록**: `.claude/memory`(세션 간 영속 기억)의 협업 스타일 메모에
이번 리뷰 진행 방식(에이전트 병렬 추출 → 배치별 텍스트+AskUserQuestion
즉시 확인 → 그 자리에서 바로 문서 반영)을 다음에 재사용할 패턴으로
기록 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션은 설계
확정이 아니라 기존 확정 사항의 결함 수정이었지만, 결과적으로 M0 착수
전 상태가 더 탄탄해졌을 뿐 우선순위 자체는 그대로. 이 중간검토가
마지막 배치(6단계)까지 끝났는지, 사용자가 이어서 더 볼 부분이 있는지는
다음 세션 시작 시 확인.

## 2026-08-09 열두 번째 세션 — `.claude/luau-test/` 신설: M0 사전 검증
스파이크 작성, 결과는 아직 미확인

M0가 공식적으로 짜야 할 스파이크(위 "지금 할 일" 1번, `ROADMAP.md` M0
체크박스)와 지금까지 세션 로그 곳곳에 흩어져 있던 "실제 Luau로 부딪혀본
적 없는 것"/"M0/M2 스파이크 검증 목록에 추가됨" 표시들을 한 곳에 모아,
사용자가 직접 `luau`/`luau-analyze`/`luau-lsp`/Roblox Studio로 돌려볼
수 있는 독립 실행 스크립트 14개 + `README.md` 색인으로 만듦. 세 라운드에
걸쳐 진행됨:

1. **1차 작성** — 레포 루트 `luau-ignoreme/`(당시엔 git 자동 제외 폴더로
   시작)에 M0 체크리스트 5개 항목(Store/State 다이아몬드 전파, Source가
   State를 구조적으로 만족하는 제네릭 타입, process/retract 재귀 디스패치,
   배열/해시 두 패스 순회, `props.Modifier or None` nil-hole 관용구) +
   `Dispatch` 체인/`retractUnder` 다단 검증, `Relate`의 weak-table GC
   실측, `Modifier.Overridden` 서브타입 타입체크, Roblox 전용
   `bindLifetime`/`canExecute`/Attribute Instance 참조/`CollectionService`
   태그 확인까지 10개 파일 작성(01~10).
2. **2차 — 커밋 `f198fd9`("중간검토에서 발견된 설계 결함 다수 수정") 반영.**
   그 사이 사용자가 직접 `.claude/base/` 전체를 훑으며 여러 결함을
   정정(위 절 참고) — 그 중 `02`(Ref 콜백/대기자 배열의 소진 센티널이
   `None`→`nil`로 되돌아간 것, 실제로 `None`을 쓰면 배열이 무한정
   자라는 버그였음이 드러남)이 luau-test 내용과 정면으로 어긋나 전면
   재작성(순서가 중요한 배열은 계속 `None`, 순서 무관+슬롯 재사용
   필요한 배열은 `nil`이라는 최종 구분 + 무한 성장 버그의 정량적
   재현까지 포함). `Modifier` UB→error 전환(11 신규)도 이 라운드에
   같이 반영. 나머지 파일은 대조 결과 영향 없음을 서브에이전트+직접
   문서 대조로 확인.
3. **3차 — 사용자 요청으로 "타입 관련 실측 필요, 특히 `luau-lsp`로
   확인해야 할 것" 3개 추가(12~14).** base 문서 자신이 "실측 필요"라고
   명시적으로 못박아둔 지점(`attribute-plan.md`의 `[Attribute<<T>>
   "name"] = value` 제네릭 DI 키가 실제로 값 타입을 좁혀주는지, 12번)과
   f198fd9에서 뒤집힌 결정(`isRef`/`isPreRef`가 이제 `Source`/`State`와
   같은 포함 관계 — `PreRef`가 `Ref`의 하위 개념이 됨, `PreRef<T>`가
   `Ref<T>`를 구조적으로 만족하는지 타입체크까지 포함, 13번), 그리고
   같은 세션에 새로 명시된 캐비엇(`Source(default)`/`Ref(default)`의
   `default` 생략은 `T`가 nilable일 때만 안전하다는 것을 함수 오버로드로
   타입 레벨에서 실제로 막을 수 있는지, 14번)을 찾아 작성.
4. **폴더 이동 — `luau-ignoreme/` → `.claude/luau-test/`.** 사용자가
   "커밋해서 레포에 남기자"고 판단 — `*-ignoreme*` gitignore 패턴을
   벗어나 일반 추적 대상으로 전환, `.claude/README.md`에 새 폴더 행
   추가. 내용/역할은 안 바뀜, 경로 참조 문구만 동기화.

**아직 아무것도 실행 안 됨 — 에이전트도 로컬에 `luau`/`luau-analyze`가
없어서 직접 못 돌려봤고, 사용자가 다음에 `luau`/`luau-analyze`/
`luau-lsp`/Roblox Studio로 직접 돌려보고 결과를 알려주기로 함.** 결과에
따라 할 일:
- 전부 통과 → M0 실제 착수 시 이 스크립트들의 로직을 그대로 재사용하며
  진행.
- 하나라도 걸림(특히 12/14의 타입 narrowing 실패, 07의 GC 신호 이상,
  10의 `warn` 발생, 13의 런타임 assert 실패) → 해당 `base/` 문서를
  그 자리에서 정정.
- `.claude/luau-test/README.md`의 "결과 확인 후 할 일" 절에 파일별로
  뭘 우선 확인해야 하는지 이미 적어둠 — 다음 세션은 그 응답을
  대조하는 것부터 시작하면 됨.

**다음 세션이 할 일**: 사용자가 luau-test 실행 결과를 갖고 오면 그것부터
반영. 아직 없으면 `ROADMAP.md` M0 착수 우선순위는 그대로(위 "지금 할 일"
1번 참고) — 단, 이 폴더 결과를 먼저 확인하고 진행하는 게 순서.

## 2026-08-10 세션 — `Slot:Add`가 삽입 인덱스를 반환하도록 확정, 범위 밖
`index`는 clamp 대신 error

짧은 세션. 사용자가 "`Slot:Add`/`Remove`가 어차피 void인데 삽입된 인덱스를
반환해줘도 되지 않냐"고 제기 — 검토 후 채택, `base/slot-plan.md`의 CRUD
표/에러 조건 절에 반영 완료:

- **`Slot:Add(element, index?): number`로 확정** — `index` 생략(끝에 추가)
  시 호출부가 실제 위치를 모르는 문제를 `Add`가 이미 계산해서 아는 값을
  그냥 반환하는 것으로 공짜 해결(기존엔 `IndexOf`로 O(n) 역조회해야 했음).
  `Move`/`Swap`이 void인 것과 안 부딪힘 — 그 둘은 호출부가 이미 위치를
  알고 부르는 연산이라 새 정보가 없어 void인 거고, `Add`는 반대로 새
  정보(계산된 위치)가 생기는 경우라 "반환값은 실제로 새로 알게 되는
  정보만"이라는 같은 원칙의 연장.
- **`Add`의 `index`가 범위 밖(1..현재 개수+1)이면 즉시 `error()`, clamp
  안 함 — 사용자가 직접 근거 제시.** clamp는 "의도한 위치가 아닌데 조용히
  성공하는" 찾기 힘든 버그 유형을 새로 만들 뿐이고, 이미 `Remove`/
  `Extract`/`Move`/`Swap` 전부가 범위 밖에서 즉시 에러인 fail-fast 톤과도
  맞아야 함.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인이
여전히 먼저) — 이번 세션은 이미 확정된 CRUD 표의 작은 갭 하나만 메운
것이라 우선순위엔 영향 없음.

## 2026-08-10 세션 — 동적 자식 추가/제거는 `Slot`/`state<Frame>`만 정당,
그 외는 UB로 명문화(문서 갭 보강)

사용자 질문에서 시작: Slot이 마운트한 객체 수를 `Length`/`Offset`
누적합으로 세는 방식(2026-08-09 여섯 번째 세션 확정)이 되면서, 이 카운팅을
안 거치고 quad가 관리하는 부모 Instance에 외부에서 직접 `.Parent = inst`로
자식을 끼워 넣는 게 UB로 문서화돼 있는지 확인 요청 — 검토 결과 **문서
어디에도 명시돼 있지 않은 진짜 갭**이었음(기존 UB 목록엔 Handler 순환/
이중 바인딩/`Dispatch.process` 우회 직접 호출/`setLength`·`setOffsetSource`
생략 등은 있었지만 이 케이스는 빠져있었음, 인접했던 "수동 Visible 토글은
Length가 못 잡는 게 맞다"는 캐비엇은 이미 마운트된 element를 나중에
숨기는 별개 시나리오라 이것과 다름).

**확정**: 동적 자식 추가/제거의 유일한 정당 경로는 `Slot` 또는
`state<Frame>`류 store-bind 뿐 — 둘 다 그 위치의 Handler가
`Dispatch.setLength`/`Dispatch.setOffsetSource`를 정확히 호출하는 것으로
이미 보장돼 있음. 이 두 경로를 거치지 않고 quad가 마운트해둔 부모
Instance에 직접 `.Parent =` 대입으로 자식을 넣거나 빼면 `lengthList`/
`sourceList`가 그 변화를 전혀 몰라 `Length` 카운트와 형제 순서(offset)
계산이 조용히 어긋남 — 새 방어 로직 없이 UB로 문서화만 함(다른 UB
케이스들과 같은 톤). `base/bind-system-plan.md`("Length/Offset" 절
말미)/`base/slot-plan.md`("Slot.Length" 절 말미)에 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션은 순수 문서 갭 보강이라 우선순위엔 영향 없음.

## 2026-08-10 두 번째 세션 — Tween 구조 전면 재설계: 독립 Dispatch 핸들러 →
값-레벨 `Tween<T>` 래퍼, `pre-implementation-audit.md` 1-1 완전 해소

사용자가 "트윈도 타입 문제가 있다 — 키 타입을 어떻게 하냐, Property
setter가 더 분발해서 `V`가 `isTween`이면 트윈 넣는 게 낫지 않냐"고
제기하며 시작된 긴 단일 스레드. 기존 확정 모델(`[Tween(key,
tweenData...)] = storeValue`, `v`가 Store인 아무 `k`나 잡는 우선순위
최상위 Dispatch 핸들러, 2026-08-04부터 확정)이 실은
`research/pre-implementation-audit.md` 우선순위1-1이 이미 지적해뒀던
구조적 모호함("애니메이션 없는 일반 반응형 프로퍼티 바인딩도 결국
이름이 Tween인 파일을 거쳐가는가")을 안고 있었다는 걸 사용자 제안이
정확히 겨냥한 것으로 드러나, 세션 내내 살을 붙여 완전히 재설계까지
감. 구 모델은 `archive/tween-special-bind-key-reversed.md`로 이전,
`research/tween-plan.md`는 전면 재작성됨 — 상세 근거는 그 두 문서가
최종 소스, 여기는 결정 흐름만 요약.

**핵심 재설계**: State/Source 언랩(범용 `Dispatch/StoreBind.luau`, `k`/`v`
타입 무관)과 "이 값이 트윈 대상인가" 판단을 완전히 분리 — 후자는 별도
Dispatch 핸들러/우선순위 경쟁이 아니라, **PropertyHandler가 `realv`를
다 풀어낸 뒤 직접 하는 값-레벨 분기**(`isTween(realv)`)로 옮김. `Tween(opts:
{Value: T, ease...}) -> Tween<T>`는 `Store({...})`와 같은 `Type(args)`
테이블 팩토리. 이 전환 하나로 우선순위1-1이 구조적으로 성립 불가능해짐
— 범용 반응형 바인딩과 Tween이 애초에 같은 핸들러를 놓고 경쟁할 지점
자체가 없어짐.

**세션 중 순서대로 다듬어진 세부 결정들**(전부 최종적으로 `research/
tween-plan.md`에 반영):

1. **`Tween.Value`는 plain `T`만, 자체 반응 경로 없음** — 처음엔 `Value`도
   `T|State<T>`를 받아 내부에 별도 Observer를 걸어야 하나 검토했으나,
   바깥 `:Compute`가 소스 변경마다 `Tween{Value=v,...}`를 통째로 재생성해
   StoreBind 재귀를 타므로 불필요함을 확인 — "같은 일 하는 두 번째 경로를
   안 만든다" 원칙 재적용, `Tween<T> = {Value: T, ease...}`로 확정.
2. **3-상태 릴레이션 슬롯으로 `hasBeenSet`과 활성 엔진 트윈 저장을 통합** —
   `relate:GetStrong(inst,k)`가 `RobloxTween | true | nil` 중 하나:
   `nil`=이 키 첫 세팅(애니메이션 없이 즉시 스냅, 기본값→목표값으로
   날아오는 진입 애니메이션 버그 방지), `true`=세팅된 적 있음/활성 트윈
   없음(정상 애니메이션 시작 가능), 엔진 객체=활성 트윈 있음(override
   정책대로 정리 먼저). 사용자가 직접 "hasBeenSet은 어차피 트윈에만
   쓰이니 트윈 저장 슬롯 하나로 합치자"고 제안해 확정.
3. **활성 트윈이 있는데 plain 값이 들어오는 경우의 순서 규칙 신설** —
   먼저 override 정책대로 이전 트윈을 정리(멈추거나 끝냄)하고, **그
   정리가 끝난 뒤에만** 새 값을 세팅. 순서가 뒤바뀌면 이전 트윈의 다음
   인터폴레이션 프레임이 방금 세팅한 값을 덮어쓸 위험이 있어서 — 사용자가
   직접 짚은 시퀀싱 버그.
4. **타입 대수: `T' = T | Tween<T>` 치환만으로 해결, 새 타입 기계 불필요** —
   지금 프로퍼티류 필드가 전부 `T | State<T>` 모양으로 통일돼 있는데,
   여기서 "이 필드의 `T`" 자체를 `T' = T | Tween<T>`로 치환하면 자동으로
   `T | Tween<T> | State<T | Tween<T>>`가 나옴 — Modifier/State/Source/
   StoreBind 코드엔 `Tween` 인지 로직이 전혀 안 들어감(StoreBind는 원래도
   페이로드 타입에 무관하게 `isState`만 봄), 타입 생성 스크립트가 필드
   타입 문자열만 바꾸면 끝. 사용자가 직접 대수적으로 도출.
5. **`useTween` 우회 — 새 옵션 필드 없이 해소.** 이전엔
   `Tween{useTween=state<boolean>}`처럼 별도 필드가 필요하다고 열어뒀으나,
   2026-08-07 일곱 번째 세션에 확정된 `state:Apply(factory)` sugar 위에
   `someState:Apply(Animate(reduceMotion, opts))`처럼 조건부로 `Tween{...}`를
   씌우거나 안 씌우는 `:Compute` 팩토리 하나로 공짜로 풀림 — 새 base
   메커니즘 불필요.
6. **`Animate` 콤비네이터는 quad-roblox 유틸, base 프리미티브 아님** —
   `Tween<T>` 값 타입/`isTween`만 base(`quad-base/Tween.luau`)에 있고,
   `Animate`는 이미 있는 `:Apply`/`:Compute`/`Tween{...}`를 조합한 편의
   함수라 나중에 이름/모양을 자유롭게 바꿔도 base 계약에 영향 없음 —
   사용자 표현으로 "저비용 고효율 엔지니어링".
7. **패키지 경계는 Tag가 이미 밟은 분리를 그대로 재사용** — quad-base:
   `Tween.luau`(값 타입만). quad-roblox: `Handlers/Property.luau`(isTween
   분기+3-상태 저장+override 정책 흡수, 기존 독립 `Handlers/Tween.luau`
   폐기) + `Animate.luau`(신규).
8. **부수 발견 — `retract`가 Tween 경로에서 사실상 필요 없어짐.** 기존
   모델에서 "Tween↔프로퍼티 핸들러 타입 교체"가 `retract`가 실제로
   의미를 갖는 유일한 대표 예시였는데, 새 모델에선 매치되는 Dispatch
   핸들러가 항상 PropertyHandler 하나뿐이라 이 케이스 자체가 사라짐 —
   트윈 취소/전환은 PropertyHandler 내부의 3-상태 슬롯 로직으로 대체(Tag가
   이미 하는 "diff는 process 자신이 담당" 패턴과 같은 모양). `retract`
   필드 자체는 "생략 불가" 일반 규칙이라 여전히 정의는 해두되, 실제
   호출은 거의 없어짐. Tag(핸들러 타입이 실제로 바뀌게 재설계되어
   `retract`가 필요해진 사례)와 Tween(핸들러 타입이 안 바뀌게 재설계되어
   `retract` 필요성이 사라진 사례)을 서로 반대 방향 사례로 archive 문서에
   대비해둠 — quadnomicon 소재.
9. **`Tween<T>`의 핸들러 계층 분류 정정** — `base/modifier-plan.md`가
   원래 Tween을 Slot/Tag/Attribute와 같은 "dispatch 참가자"(State/Source에
   담겨도 재귀 재-dispatch가 그대로 처리해주는 부류)로 묶어뒀는데, 이제
   `Tween<T>`는 `process`/`retract`가 없는 순수 raw 데이터 값이라 `None`과
   같은 분류로 정정 — Modifier 필드/`State<Modifier>`가 막는 "핸들러
   계층 값 → error" 규칙에 안 걸린다는 결론은 안 바뀜(그냥 raw 값이라서로
   근거가 바뀜).
10. **`initValue`(진입 애니메이션)와 hasBeenSet의 긴장 관계를 기록만
    해둠** — hasBeenSet이 "첫 세팅은 무조건 스냅"을 기본 동작으로
    확정했으므로, 나중에 `initValue`(다이얼로그 슬라이드-인 등)가 실제로
    필요해지면 이 억제 동작을 명시적으로 우회하는 방법까지 같이 설계해야
    함 — 새 결정 없이 상충 관계만 `research/tween-plan.md`에 남김.

**여전히 열려있는 것**(M11 착수 시 확정): override 정책 4가지 중 기본값
Cancel 외 세 옵션의 정확한 키 이름/시그니처, Tween→plain 전환에 5번째
옵션이 필요한지, 트윈 옵션 값 모양(`TweenInfo` 그대로 vs 편의 필드 — 소견은
후자), `Animate`의 정확한 시그니처(조건/옵션 분리 vs 통합).

**반영된 파일**: `research/tween-plan.md`(전면 재작성, 최종 소스),
`archive/tween-special-bind-key-reversed.md`(신규, 구 모델 원문+역전
사유), `base/bind-system-plan.md`(9곳 — "확정된 디스패치 모델"의 대표
예시를 Tween에서 StoreBind로, `retract` 필요 패턴 예시를 Tag로 교체,
"Dispatch는 프리미티브가 아니다"/"Dispatch 체인" 절의 핸들러 목록에서
Tween 제거, `None` 센티널 절 예시 갱신, Ref/Brand 절 문구 정정),
`base/architecture.md`(소스트리 — `quad-base/Tween.luau` 신설,
`quad-roblox/Handlers/Tween.luau` 삭제하고 `Handlers/Property.luau`
설명에 흡수, `Animate.luau` 신설), `base/modifier-plan.md`(핸들러 계층
분류에서 Tween 제외 + 신규 "10. `Tween<T>`와의 타입 합성" 절),
`research/pre-implementation-audit.md`(우선순위1-1 해소 표시),
`ROADMAP.md`(M11 전면 재작성, M2/M7 체크박스 갱신), `.claude/question.md`/
`.claude/README.md`(참조 동기화).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정/문서 정리라 M0 착수 우선순위 자체는
그대로. M11 착수 시점이 오면 위 "여전히 열려있는 것" 목록부터 확인.

## 2026-08-10 세 번째 세션 — `OnChange` 특수 키 신설: `GetPropertyChangedSignal`
바인딩, 제네릭 없이 확정

사용자가 `GetPropertyChangedSignal`을 어떻게 다뤄야 할지 물으며 시작 —
이벤트는 이미 평범한 문자열 키(`inst[key]`가 곧 Signal)로 확정돼 있는데,
`GetPropertyChangedSignal(name)`은 프로퍼티 이름을 인자로 받아야 하고 그
이름이 "값 세팅" 키 네임스페이스와 겹쳐서 같은 패턴을 못 씀 — 사용자가
`[OnChange "PropertyName"] = function(v) ... end` 형태(타입은 콜백에 직접
명시)와 "`OnChange.PropertyName`을 전부 코드 생성"하는 대안 두 가지를
제시하며 의견을 물음.

**확정**: `OnChange(name)` DI 키 팩토리, **제네릭 타입 파라미터 없음** —
`Attribute<<T>>`와 달리 콜백 파라미터 타입은 호출부가 직접 명시. 이미
확정된 "이벤트 바인딩은 콜백 시그니처를 Luau가 검증 못 하는 대가를
받아들인다"는 결정과 같은 급의 트레이드오프라 새로 정당화할 것 없다는 게
근거 — 오히려 `Attribute`처럼 제네릭으로 정확히 맞추려 들면 이벤트 키보다
더 엄격한 걸 요구하는 셈이라 일관성이 깨짐. 프로퍼티별 정적 코드 생성 안은
기각(`archive/onchange-per-property-codegen-rejected.md`) — Attribute의
정적 지름길은 타입 파라미터가 좁고 고정된 프리미티브 집합(~10종)에서만
와서 지름길 후보가 유한한데, 프로퍼티는 클래스마다 이름/타입 집합이 전부
달라 (클래스 수 × 프로퍼티 수) 규모로 폭발함 — 겉보기엔 비슷한 절충
같지만 실제로는 규모가 다른 문제.

패키지 경계는 **전부 quad-roblox**(`Handlers/OnChange.luau`, `Attribute`와
같은 배치 — `GetPropertyChangedSignal` 자체가 Roblox 엔진 API라 base에 둘
값 타입/API 레이어가 없음). `process`는 `GetPropertyChangedSignal(name):Connect`,
`retract`는 `:Disconnect` — 일반 `Handlers/Event.luau`와 같은 결. **`State<function>`
지원도 새 메커니즘 없이 해소** — 이미 확정된 "이벤트도 store-bind 가능
(`false`로 disconnect)" 메커니즘이 그대로 적용됨, `OnChangeHandler`는
`process`/`retract`만 구현하면 범용 `Dispatch/StoreBind.luau`가 State/Source
언랩+재귀 재-dispatch를 알아서 해줌.

`base/onchange-plan.md`(신규)/`base/bind-system-plan.md`(이벤트 네이밍 절
교차 참조)/`base/architecture.md`(소스트리 `Handlers/OnChange.luau`)/
`ROADMAP.md`(M10 제목·체크박스)/`.claude/README.md`(base/archive 인덱스)
전부 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.

## 2026-08-11 세션 — `:Compute(fn, ...)` trailing-args sugar 확정,
`Effect`/`Observer`는 의도적으로 제외

사용자가 Vide의 암묵적 추적과 React 훅 규칙의 차이를 짚는 질문에서 출발해,
"React의 `useMemo(fn, deps)`처럼 `:With(...)` 없이 `:Compute(fn, a, b, c)`로
바로 추가 의존성을 선언하면 더 편하지 않냐"는 제안으로 이어진 짧은 세션.
검토 끝에 확정, `base/bind-system-plan.md`(`:Compute` 절 신규 소절)/
`base/effect-plan.md`/`ROADMAP.md`(M3)/`research/documentation-content-map.md`
(quadnomicon 후보 7번)에 반영 완료:

- **`:Compute(fn, ...)`는 채택 — 진짜 공짜 sugar라는 게 사용자가 직접 밝힌
  핵심 근거.** `:Compute` 호출은 원래도 결과를 담을 새 State 노드를 만들어야
  하므로, 그 노드에 `self` 말고 `a,b,c`까지 구독(무효화 엣지)을 추가로 거는
  건 이미 생기는 노드에 엣지만 얹는 것 — `:With(a,b,c):Compute(fn)`(노드
  2개)보다 싼 노드 1개로 끝남. 이전에 기각됐던 `Store.Combine({a,b},
  function(av,bv)...)`(포지셔널 값 언랩이라 타입 표기가 꼬였던 안)과는
  달리 `fn(self)` lazy 핸들 시그니처를 그대로 유지하는 제안이라 그 기각
  사유가 안 걸림.
- **`Effect(fn, ...)`/`state:Observer(fn, ...)`류 동일 sugar는 기각 —
  사용자가 직접 구분.** Effect/Observer는 Compute와 달리 자기 자신이
  결과를 담는 State 노드가 아닌 순수 leaf 소비자라, 의존성이 둘 이상이면
  그걸 하나로 합칠 **새 노드**(`:With`가 만드는 것)가 실제로 필요함 —
  이건 진짜 비용이 드는 지점이라, trailing args로 감추면 "이 줄이 새
  노드/구독을 만든다"는 걸 코드만 보고 알 수 없게 됨. `:With`가 clone
  빌더가 아니라 진짜 노드로 확정됐던 이유(2026-08-07 세 번째 세션,
  "코드상의 호출 체인이 그래프 엣지와 1:1 대응돼야 quad-debug 그래프가
  안 꼬임")와 정확히 같은 원칙 — 다중 의존성 Effect/Observer는
  `Effect(fn, state:With(a,b,c))`처럼 `:With` 호출을 코드에 그대로 노출.
- **일반 원칙**: "trailing args sugar는 그게 정말 무료일 때만 붙인다" —
  호출부가 이미 만들어야 하는 노드에 엣지만 얹는 경우(Compute)엔 sugar,
  없던 노드를 새로 만들어야 하는 경우(Effect/Observer의 다중 의존성
  병합)엔 sugar 없이 `:With`를 명시적으로 남긴다. `Compute`만 편해지고
  `Effect`/`Observer`는 안 그런 게 겉보기엔 비일관적으로 보이지만 실은
  이 하나의 원칙에서 나온 것이라는 게 quadnomicon 에세이 소재로 채택
  (사용자 제안).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.
