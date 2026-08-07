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
  `framework-comparison-findings.md`/`additional-primitives-plan.md`(키 기반
  동적 컬렉션 재조정만 남음) — 전부 후순위(급한 건 `tween-plan.md`
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
  로 끝, 성긴 배열이어도 압축 불필요.
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

- **제 실수 정정 — `canExecute`와 `isHandlable`은 다른 개념.**
  `isHandlable(k,v)`는 KV 매치 predicate(핸들러 계약 4종 중 하나),
  `canExecute`는 특정 바인딩 하나가 "지금 살아있어 실행돼도 되는가"만
  보는 별개의 라이프타임 게이트(`lifecycle-pattern.md`) — `NoneHandler`가
  구현해야 하는 건 `isHandlable`이지 `canExecute`가 아님, 앞서 잘못 쓴
  문장을 고침.
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
  뒤집음.** 그땐 "State면 충분한 용도"만 봤지만 `Source`는 State보다
  진짜 더 많은 능력(`:Set`/`:Emit`)을 가진 서브타입이라 "쓰기도 되는
  원천인가"를 알아야 하는 코드엔 `isState`만으론 부족 — `isSource` 별도
  제공, `isState`는 여전히 `{State,Source}` 둘 다 통과. `component-
  composition-plan.md` 4번 절이 애초에 `isSource`가 존재한다고 가정해둔
  것과도 이걸로 정합됨(그동안 두 문서가 서로 모순돼 있었음, 이번에 발견).
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
