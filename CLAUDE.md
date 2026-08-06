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
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의. 지금은
  `tween-plan.md`(세부 옵션만 남음), `existing-instance-bind-plan.md`(급하지
  않음) 두 개뿐 — `component-composition-plan.md`는 2026-08-04 세션에 수렴
  완료돼 `base/`로 승격됨.
- `.claude/qa-request/`, `.claude/archive/`, `.claude/feedback/` — 구현
  시작되면 쓰기 시작함, 지금은 비어있음.
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
   `ROADMAP.md`가 소스** — 여기서 반복 안 함.
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
   "quad 개발 상당 부분 끝난 뒤"로 사용자가 못박음. 같은 세션에서 파생된
   문서화 전략 뼈대(`research/documentation-plan.md`, UI 네이밍 컨벤션 +
   Store 부작용 게임 시스템 활용 패턴)도 후순위 백로그로 같이 남김.
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
- **아직 확인 안 된 것 하나**: 사용자가 "이벤트 함수들이 실제 instance를
  읽을 수 있게 self를 건네받는 게 quad의 관습"이라고 언급했으나 본인도
  "문서화됐는지 모르겠다"고 함 — 어떤 함수(이벤트 핸들러? Compute?
  `describe` 훅?)에 정확히 어떤 시그니처로 적용되는지 다음 세션에서 확인
  필요(`debug-tooling-plan.md` "열린 질문" 참고), 추측성 반영은 안 해둠.

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
