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
- `.claude/research/` — 아직 착수 전, 사용자와 상의 필요한 설계 논의.
  `tween-plan.md`/`existing-instance-bind-plan.md`/`debug-tooling-plan.md`/
  `ui-shorthand-plan.md`/`documentation-plan.md`/`documentation-content-map.md`/
  `framework-comparison-findings.md` — 전부 후순위(급한 건 `tween-plan.md`
  세부 옵션 정도). 최신 목록·우선순위는 `.claude/README.md`가 소스, 여기서
  개수 반복 안 함(과거에 "두 개뿐"이라 적어놨다가 새 문서 추가될 때마다
  안 갱신되는 패턴이 반복돼서 아예 안 세기로 함).
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
   앞당기기 검토)이 있음, 아래 최신 세션 요약 참고.
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
