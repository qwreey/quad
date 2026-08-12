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
  — 전부 후순위(`tween-plan.md`는 2026-08-12 세션에서 사실상 다 닫힘, 남은
  건 자연완료 북키핑 정도로 더 이상 급하지 않음). 최신 목록·우선순위는
  `.claude/README.md`가 소스, 여기서 개수 반복 안 함(과거에 "두 개뿐"이라
  적어놨다가 새 문서 추가될 때마다 안 갱신되는 패턴이 반복돼서 아예 안
  세기로 함).
- `.claude/qa-request/`, `.claude/feedback/` — 구현 시작되면 쓰기 시작함,
  지금은 비어있음. `.claude/archive/`는 원래 같은 취급이었으나
  2026-08-06 세 번째 세션부터 **완전히 뒤집힌 설계 결정을 원문+역전
  이유+diff와 함께 보존하는 용도로도 사용 시작**(구현 완료 대상만이
  아님) — `archive/store-source-proxy-reversed.md`가 첫 사례, 나중
  `quadnomicon` 콘텐츠 소재로 재사용 예정.
- `.claude/session/` — **[2026-08-11 신설]** 세션별 상세 로그 원문(시행착오·
  정정 전 서술 포함, `quadnomicon` 개발로그 소재용) — 이 CLAUDE.md가 3000줄
  넘게 불어나 성능 저하를 유발해서 분리함. 아래 "세션 히스토리"의 각 항목이
  여기로 링크. **항상 읽을 필요 없음** — 특정 결정의 논의 과정/시행착오가
  궁금할 때만 열어볼 것, 지금 유효한 설계는 항상 `base/`가 소스.
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
  다수 발견되어 정리함(아래 "세션 히스토리" 참고) — 여러 라운드에 걸쳐
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

1. **구현 시작 — 루트 `ROADMAP.md`의 M0부터.** 설계 단계는 2026-08-04 로드맵
   인수인계 라운드로 종료. M0 착수 직전 확인할 것 둘:
   - **`.claude/luau-test/`(2026-08-09 신설) 스파이크 결과** — 아직 사용자가
     `luau`/`luau-analyze`/`luau-lsp`/Roblox Studio로 안 돌려봄, 결과가
     나오면 그것부터 반영할 것(`luau-test/README.md`가 파일별로 뭘 우선
     확인해야 하는지 이미 적어둠). 걸리는 게 있으면 `base/` 문서부터 고치고,
     없으면 그대로 M0 실제 코드 작성에 재사용.
   - **`research/pre-implementation-audit.md` 우선순위1** — 신설 당시
     11개였으나 대부분 이후 세션에서 해소됨(Tween/Tag 재설계, Slot CRUD,
     `canExecute` 시그니처, `LifetimeHandle` 로드맵 순서 등). 실제로 아직
     열려있는 건 "우선순위 스캔 동률/매치실패 처리"(1-3) 하나뿐 —
     `.claude/question.md` 2번이 최신 상태.
2. **용어 정리 — 1차 제안 이후 대부분 확정, 소수만 남음.** 최신 소스는
   `.claude/question.md` 1번(개수 반복 안 함, 항목 추가/해소될 때마다 여기가
   stale해지는 패턴이 반복됐어서). 아직 열려있는 것만 짚으면: `State`(1순위,
   위험도 높음 — 업계 통념("쓸 수 있는 로컬 상태")과 반대 의미라 오해 위험),
   `DI`→`D`, `Slot`, `canExecute`→`isAlive`, `Brand`.
3. `research/existing-instance-bind-plan.md`는 급하지 않음 — 스코프 논의만
   필요, 구현 착수를 막지 않음.
4. **[백로그]** 범용 렌더 디버깅 도구 `quad-mock`(Tween mock 등 동적 동작
   지원, M0 mock 테스트 하네스와는 별개), 런타임 디버깅 플러그인
   `quad-debug`(Studio 플러그인, 실물 Instance→코드 위치 역추적 — 채널
   실현 가능성은 실측 검증 완료, 세부 API 이름만 남음), 문서 사이트 전체
   구조(초심자/api/심화/`quadnomicon` 4축 + 콘텐츠 맵) — 전부 "quad 개발
   상당 부분 끝난 뒤"로 사용자가 못박은 후순위. 상세는 `.claude/README.md`의
   `research/` 표(`debug-tooling-plan.md`/`documentation-plan.md`/
   `documentation-content-map.md`/`framework-comparison-findings.md`).
5. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).

## 세션 히스토리

전체 설계는 여러 세션에 걸쳐 대화로 확정됐음. **아래는 탐색용 압축 요약이고,
지금 유효한 설계의 소스는 항상 `.claude/base/`** — 여기 요약이나 세션 원문과
`base/`가 어긋나면 `base/`가 맞음(더 최근 결정이 반영돼 있음). 각 항목의
원문(시행착오·정정 전 서술 포함, `quadnomicon` 개발로그 소재용)은
`.claude/session/`에 그대로 보존돼 있음 — 결정의 배경/논쟁 과정이 궁금할
때만 열어볼 것.

**이 절을 갱신하는 방법(중요, 반복 방지용)**: 세션이 끝나면 (1) 전체
서술은 `.claude/session/YYYY-MM-DD-NN-slug.md`로 새로 저장하고, (2) 여기엔
2~4줄 압축 요약 + 그 파일로의 링크만 추가할 것. **절대 여기에 전체 논의
과정을 그대로 쌓지 말 것** — 그게 바로 이 CLAUDE.md가 3000줄 넘게 불어나
성능 저하를 유발했던 원인(2026-08-11 정리 세션에서 발견, 상세는
`.claude/session/2026-08-11-08-claude-md-restructure.md` 참고). base/
research/archive 반영이 그 세션 안에서 끝났는지 먼저 확인 후에 이 절에
추가할 것 — 반영 안 된 게 있으면 archive/session 이전보다 그 반영이 항상
먼저.

**2026-08-04 — 로드맵 인수인계** (`session/2026-08-04-01-roadmap-handoff.md`)
Modifier 메커니즘 전체 확정(immutable clone 체이닝), 컴포넌트화 논의 완결
(modifier/Ref는 named parameter로 컴포넌트 경계 통과, "멀티루트" 개념 폐기),
`.claude/` 코퍼스 전체 감사·정리, quad-base 테스트 mock 방향 확정,
`ROADMAP.md` 신설 — 설계 단계 종료, 다음 세션부터 M0 착수 예정.

**2026-08-06 세션 — quad-debug 설계** (`session/2026-08-06-01-quad-debug-design.md`)
런타임 디버깅 플러그인 `quad-debug` 설계(백로그, "quad 개발 상당 부분 끝난
뒤" 착수). Studio 플러그인↔Play 중 게임 간 BindableEvent 채널이 실제로
작동함을 사용자가 직접 실측 검증. UICorner/UIPadding/UIScale 인라인 숏핸드,
Attribute 타입 파라미터화 논의 신설.

**2026-08-06 후속 세션 — 이벤트 self 관습, rbvm GC, 코퍼스 정리**
(`session/2026-08-06-02-event-self-rbvm-corpus.md`)
이벤트 핸들러가 v1처럼 self(Instance)를 받는 관습은 채택 안 하기로 확정
(Ref가 이미 커버, 이중 쓰기 경로 방지). `Store:Emit`/`:Compute`의 `previous`
인자/`state:Observer(fn)`/Ref 일반화(범용 값 박스로 확장) 확정. Observer
이름 확정, 생성자 스타일(`Type(args)`) 통일, "독립 프리미티브 vs 파생
데이터" 원칙 신설.

**2026-08-06 세 번째 세션 — 문서 사이트 구조, 프레임워크 비교, Source⊇State**
(`session/2026-08-06-03-docsite-source-state.md`)
문서 사이트 4축(초심자/api/심화/`quadnomicon`) 구조 확정. quad vs
Fusion/Vide/react-lua 정직 비교 완료. **핵심**: `Source<T>`가 구조적으로
`State<T>`를 만족하는 서브타입 재구성 — `StoreSource` 프록시 폐기,
`store.key = value` 대입 문법 폐기하고 `:Set()`으로 전환.

**2026-08-06 네 번째 세션 — M0 착수 직전 크리티컬 감사**
(`session/2026-08-06-04-pre-implementation-audit.md`)
`.claude/base/` 전체를 모호성/지연결정리스크/단순화후보 세 렌즈로 재감사,
`research/pre-implementation-audit.md` 신설(우선순위1 11개 등). 대부분은
이후 세션에서 해소됨 — 현재 상태는 `.claude/question.md` 2번 참고.

**2026-08-07 세션 — `:With`도 새 State 노드** (`session/2026-08-07-01-with-new-node.md`)
`:With(...)`는 clone 빌더가 아니라 매번 새 State 노드를 만드는 것으로 확정
— 디버그 그래프가 코드 호출 체인과 1:1 대응해야 함, `:With(a,b,c)` 가변인자로
노드 남발 문제는 해소.

**2026-08-07 두 번째 세션 — `Modifier:Apply`** (`session/2026-08-07-02-modifier-apply.md`)
Jetpack Compose류 커스텀 확장 함수 패턴을 콤비네이터로 흉내낸
`mod:Apply(factory)` sugar 채택 — `function(self,factory) return factory(self) end`.

**2026-08-07 세 번째 세션 — `PreRef` 신설** (`session/2026-08-07-03-preref.md`)
base 디스패치 드라이버가 "배열(children/Ref) 먼저, 해시(프로퍼티/이벤트)
나중" 두 패스를 명시적으로 계약. `CreatedRef`의 `phase` 옵션 폐기(배열
위치로 공짜 표현). 이벤트보다도 먼저 채워져야 하는 self-ref 전용으로
`PreRef` 신설(호이스팅, 동적 경로 도착 시 error).

**2026-08-07 네 번째 세션 — 코퍼스 전반 재편** (`session/2026-08-07-04-corpus-reorg.md`)
`reference/` 폴더 신설(v1 스냅샷/Fusion·Vide 비교를 온디맨드 자료로 분리),
`ui-shorthand-plan.md`를 `base/`로 승격, `Blocker`/`Effect` 확정 승격(`Batch`/
`Context`는 기각→archive), archive 제목 컨벤션을 `[역전됨]`/`[기각됨]`으로 분화.

**2026-08-07 다섯 번째 세션 — `Overridden`/`Peek`/`isState`, FuncSource 기각**
(`session/2026-08-07-05-override-peek-isstate.md`)
`Modifier.Override(mod1,mod2,...)`(뒤 인자가 필드 단위로 이김) 확정,
`:Peek(key)`(raw union 그대로 반환)/`isState` 신설. FuncSource(람다로
계산+self-emit하는 Source) 기각 — 이미 확정된 원칙들의 논리적 귀결.

**2026-08-07 여섯 번째 세션 — Ref/PreRef API, Tween GC 구조**
(`session/2026-08-07-06-ref-preref-api.md`)
Ref API를 `.Value`+`:Set`/`:Callback`/`:Wait`(전부 self 반환)로 확정,
Ref/PreRef 파일 분리. Tween per-instance 저장소가 GC-안전함을 확인.
Effect/Observer 관계 해소 시작(`state:Observer(fn)`는 등록 즉시 1회 실행).

**2026-08-07 일곱 번째 세션 — `:Compute` 커링, `state:Apply`, 이중 바인딩 금지**
(`session/2026-08-07-07-state-apply-effect-subscribe.md`)
`:Compute`/Effect/Observer의 `fn`은 커링 스타일 권장. `state:Apply(factory)`
sugar 확정(`Modifier:Apply`와 동형). `EffectHandle:Subscribe`/`:Unsubscribe`
신설. Observer/Effect 이중 바인딩은 `Bound` 플래그로 즉시 error.

**2026-08-07 여덟 번째 세션 — `None` 센티널, Dispatch 네이밍, `Brand`**
(`session/2026-08-07-08-none-sentinel-dispatch-brand.md`)
인라인 필드를 명시적으로 지우는 `None` 센티널 확정 — `NoneHandler`가
`process(inst,k,nil)`로 재귀 재디스패치(Tween store-bind와 같은 패턴, 새
메커니즘 아님). `Dispatch.getHandler`/`.process`/`.addHandler`/`.drive` 이름
공식화. `Tag`/`Attribute` 전용 문서 신설. `Brand` 통합 판별 메커니즘(`isState`를
10종으로 일반화) 신설.

**2026-08-07 아홉 번째 세션 — 코퍼스 정합성 감사, `CreatedRef` 폐기**
(`session/2026-08-07-09-corpus-audit-createdref.md`)
stale 참조 12개 수정, `archive/agent-mistake.md` 신설(에이전트 자체 개념
혼동 정정 이력 전용 카테고리). `CreatedRef` 이름 완전 폐기 — `Ref(default)`/
`PreRef(default)` 인스턴스를 children 배열에 직접 놓으면 되므로 별도 래퍼
불필요했음이 드러남. `PreRef` pre-pass 위치/순서/동적 경로 가드 확정.

**2026-08-07 열 번째 세션 — 소진 슬롯은 `None`, Ref 콜백 배열은 별개**
(`session/2026-08-07-10-none-vs-nil-order.md`)
사용자가 Luau REPL로 "정수 키가 촘촘하지 않으면 순회 순서가 안 보장됨"을
직접 실증 — 순서가 중요한 배열(PreRef pre-pass)은 `None`으로 소진.
`props.Modifier or None`/`props.Ref or None` 필수 관용구 확정.

**2026-08-08 세션 — `Relate` 신규 프리미티브** (`session/2026-08-08-01-relate-bindlifetime.md`)
`bindLifetime`/`canExecute`(inst,value) 탑레벨 함수로 확정, 그 저장소로
`inst`를 weak 키로 하는 범용 릴레이션 `Relate` 신설(구 `perInstanceState`
placeholder 대체). `retract` 필드는 no-op이어도 생략 불가로 확정.

**2026-08-08 두 번째 세션 — Dispatch는 싱글톤, 네이밍 케이싱 컨벤션**
(`session/2026-08-08-02-dispatch-singleton-naming.md`)
Dispatch는 프리미티브가 아니라 탑레벨 싱글톤으로 확정(재귀 호출 배관
비용 때문). children 배열의 Ref/Observer/PreRef leaf Handler는
`Dispatch/Leaf.luau`(quad-base)로 확정. Handler는 "독립 프리미티브 vs
파생 데이터" 분류의 세 번째 카테고리로 명문화. 네이밍 케이싱 컨벤션
(생성자/메소드=대문자, 탑레벨 유틸=소문자) 문서화.

**2026-08-08 세 번째 세션 — Tag 재설계, Dispatch 체인+`retractUnder`**
(`session/2026-08-08-03-tag-redesign-dispatch-chain.md`)
`Tag`를 해시 파트 boolean 키에서 array-part 값 객체(`Tag(...)`, `:Added`/
`:Removed`/`:Contains`/`:Apply`/`Merged`)로 재설계 — 상호배타 스타일
상태 표현이 쉬워짐. 이 재설계로 "retract가 실제로 필요한 첫 사례"가
드러나, Dispatch가 `(inst,k)`별 핸들러 체인을 직접 소유하고
`Dispatch.retractUnder`가 꼬리부터 정리하는 모델로 확정(다단 재귀
위임의 retract 전파 문제 해결).

**2026-08-08 네 번째 세션 — `Overridden` 이름 확정** (`session/2026-08-08-04-overridden-naming.md`)
`Override`→`Overridden`(불규칙 과거분사)으로 이름 확정 — `-ed`/분사 어미가
"즉시 커밋 뮤테이션이 아니라 계산되어 반환되는 새 값"을 신호한다는
`Tag`의 `Added`/`Removed` 관례와 통일.

**2026-08-08 다섯 번째 세션 — 용어 정리 라운드** (`session/2026-08-08-05-terminology-round.md`)
`Ref`/`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/"프로바이더"→`Handler`
전부 이름 확정. `DI`→`D`, `canExecute`→`isAlive`는 계속 미정으로 재확인.

**2026-08-09 세션 — `canBound`, Modifier 핸들러 값 UB→error**
(`session/2026-08-09-01-canbound-modifier-error.md`)
`Bound`→`canBound(handle)` 탑레벨 함수로 확정. `:Compute`의 `previous`
인자는 오버엔지니어링 의심 기각(현재 설계 유지), 스코핑을 결과 State
노드 자신에 귀속으로 명확화. Modifier 필드/`State<Modifier>`에 핸들러
계층 값(Ref/PreRef/Observer/Effect/Slot/Modifier)이 들어오면 UB 대신
즉시 error로 전환(Slot만 예외 — 정상 dispatch 참가자라 계속 허용).
Tween `initValue`/`useTween` 논의 신설(미확정).

**2026-08-09 두 번째 세션 — 코퍼스 stale 감사, 무효화 서사 archive 이전**
(`session/2026-08-09-02-corpus-audit-archive-move.md`)
`.claude/` 전체 stale 마커/모순 7개 파일 수정. 뒤집힌 설계가 정정 표시만
붙은 채 본문에 전체 서술로 남아있던 4곳을 `archive/*-rejected.md`로 이전
(quad2-try 리서치 전문, Observer cleanup 계약 기각, 키드 컬렉션 State
메소드 기각, quad-debug ReplicatedStorage 채널 기각).

**2026-08-09 세 번째 세션 — Slot CRUD 완전 확정, `Slot:List`**
(`session/2026-08-09-03-slot-crud-list.md`)
`Add`/`Remove`/`Extract`/`Clear` CRUD 확정(당시엔 element 레퍼런스 기준 —
이후 열한 번째 세션에서 인덱스 기준으로 재정정됨). 키 기반 동적 컬렉션
재조정이 `Slot:List(data, updateFn, keyFn?) -> Slot` 메소드로 통합·승격
(Fusion `ForPairs`/`ForKeys`/`ForValues` 3분할을 하나로). `Move`/`Swap`
CRUD 추가, Slot 요소 타입 제약(`nil`/핸들러 계층 값 금지) 확정.
`renderFn`→`updateFn` 개명, `Source` 생성 권한을 `:List`가 아니라
`userdata`로 이전.

**2026-08-09 여섯 번째 세션 — Length/Offset, `unbindLifetime`**
(`session/2026-08-09-06-length-offset-unbindlifetime.md`)
여러 Slot이 형제로 섞일 때 순서 보장을 "각 위치가 앞 형제 개수 누적합만
알면 됨" 모델로 완전히 풂 — `Dispatch.setLength`/`Dispatch.setOffsetSource`
신설, 각 원소 `LayoutOrder`는 기존 store-bind 재실행 모델에 얹힘(새
메커니즘 없음). `bindLifetime`의 조기 해제를 위한 `unbindLifetime` 신설.

**2026-08-09 일곱 번째 세션 — `Slot:List` 구독도 lazy `bindLifetime`**
(`session/2026-08-09-07-list-observer-lazy.md`)
`data:Observer(fn)` 구독이 `:List()` 호출 즉시 만들어져 `inst`를 몰라
`bindLifetime`이 안 걸려있던 gap 발견·수정 — Slot 컨테이너 마운트 시점에
lazy하게 구독하도록 변경, Destroy 후 재실행 gap 해소.

**2026-08-09 여덟 번째 세션 — `base/` 전체 중간검토(질문 모드)**
(`session/2026-08-09-08-midreview-defects.md`)
서브에이전트로 `base/` 전체를 그라운딩된 리스팅으로 뽑아 6배치로 나눠
사용자가 직접 확인 — 24개 질문 중 1/3에서 실제 설계 결함 발견·즉시 수정
(Ref 콜백 배열 소진을 `None`→`nil`로 되돌림, Slot CRUD를 인덱스 기준으로
재정정, `isRef`/`isPreRef` 포함관계 재정정 등). 상세는 파일 참고.

**2026-08-09 열두 번째 세션 — `.claude/luau-test/` 신설**
(`session/2026-08-09-12-luau-test-spikes.md`)
M0가 검증해야 할 스파이크 항목을 독립 실행 스크립트 15개로 미리 작성 —
사용자가 `luau`/`luau-analyze`/`luau-lsp`/Studio로 직접 돌려보기로 함.
**아직 결과 미확인** — M0 착수 전 최우선 확인 대상.

**2026-08-10 세션 — `Slot:Add`가 삽입 인덱스 반환**
(`session/2026-08-10-01-slot-add-return-index.md`)
`Slot:Add(element, index?): number`로 확정(계산된 위치를 공짜로 반환).
범위 밖 `index`는 clamp 대신 즉시 error.

**2026-08-10 세션 — 동적 자식 추가/제거는 `Slot`/`state<Frame>`만 정당**
(`session/2026-08-10-02-dynamic-children-ub.md`)
quad가 마운트한 부모 Instance에 `Slot`/store-bind 경로를 안 거치고 직접
`.Parent =` 대입하는 것은 `Length`/`offset` 계산을 조용히 깨뜨리는 UB —
기존 문서에 빠져있던 갭을 명문화만 함(새 방어 로직 없음).

**2026-08-10 두 번째 세션 — Tween 전면 재설계** (`session/2026-08-10-03-tween-redesign.md`)
독립 Dispatch 핸들러(우선순위 경쟁하는 특수 bind key) 모델을 폐기하고,
`Tween(opts) -> Tween<T>` 값-레벨 래퍼로 전환 — PropertyHandler가
`realv`를 다 풀어낸 뒤 `isTween(realv)`로 직접 분기. 이걸로
"일반 반응형 바인딩도 Tween 파일을 거쳐가는가"라는 오래된 구조적 모호함
(`pre-implementation-audit.md` 1-1)이 구조적으로 해소됨. 3-상태 릴레이션
슬롯으로 진입 애니메이션 버그 방지, `T'=T|Tween<T>` 타입 치환만으로 해결.

**2026-08-10 세 번째 세션 — `OnChange` 특수 키** (`session/2026-08-10-04-onchange-key.md`)
`GetPropertyChangedSignal` 바인딩용 `OnChange(name)` DI 키 신설 — `Attribute`와
달리 제네릭 타입 파라미터 없음(콜백 타입은 인라인 명시). 전부 quad-roblox.

**2026-08-11 세션 — `:Compute(fn, ...)` trailing-args sugar**
(`session/2026-08-11-01-compute-trailing-args.md`)
`:Compute`가 trailing args로 추가 의존성을 바로 구독하는 sugar 채택(이미
만들 노드에 엣지만 얹는 진짜 공짜 최적화). `Effect`/`Observer`는 의도적으로
제외 — 다중 의존성 병합은 실제 새 노드가 필요해 `:With`를 명시적으로
남겨야 함.

**2026-08-11 두 번째 세션 — trailing deps를 `fn`에 위치 인자로 노출**
(`session/2026-08-11-02-trailing-deps-positional.md`)
trailing args `a,b,c`를 `fn(self,a,b,c)`처럼 값 자체로도 노출하는 안 채택
— 커링 시 중복/드리프트 위험 해소. `previous`와의 타입 팩 순서 충돌 발견,
`.claude/luau-test/15` 실측 항목 신규.

**2026-08-11 세 번째 세션 — `previous`는 팩 앞** (`session/2026-08-11-03-previous-before-pack.md`)
직전 세션의 "`previous`는 팩 뒤" 순서가 Luau 문법 제약(제네릭 팩은 맨 끝만
가능)과 부딪힐 가능성이 높다는 걸 발견 — `fn(self, previous?, ...deps)`로
정정(구조적으로 유일하게 안전한 순서).

**2026-08-11 네 번째 세션 — `Slot:List`는 `LayoutOrder`를 자동 세팅 안 함**
(`session/2026-08-11-04-slot-list-layoutorder-index.md`)
"Handler가 마운트 시점에 `LayoutOrder`를 자동 바인딩해준다"는 원 서술이
매직이라는 지적으로 정정 — `Slot.Offset`/`index`(raw number)만 `updateFn`에
전달하고 실제 반영은 전부 `updateFn` 몫. `candidateIndex` 트릭으로
"버림/다시 그림/source만 갱신" 세 갈래를 단일 forward pass로 정리, 이중
write 제거.

**2026-08-11 다섯 번째 세션 — Slot 문서화 프레이밍** (`session/2026-08-11-05-slot-doc-framing.md`)
Slot을 "동적 렌더링을 가능하게 하는 도구"로 문서화하기로 확정(순수 톤 결정,
새 런타임 설계 없음).

**2026-08-11 여섯 번째 세션 — `Slot:Single`, Slot-in-Slot 중첩**
(`session/2026-08-11-06-slot-single-nesting.md`)
`Slot():Single(state, updateFn?)`을 `:List` 위의 sugar로 확정. Slot을 다른
Slot 안에 넣을 수 있는 Slot-in-Slot 중첩 확정 — `Dispatch.setLength`/
`setOffsetSource`를 Slot 자신을 owner 키로 재귀 호출하는 것만으로 풀림(새
프리미티브 불필요). `Dispatch.drive`의 `recompute` off-by-one 버그(offset이
자기 자신을 포함해 누적되던 것)를 실측 시뮬레이션 중 발견·수정.

**2026-08-11 일곱 번째 세션 — 반응형 raw 요소** (`session/2026-08-11-07-reactive-raw-elements.md`)
`Slot:Add`가 `State<T>`/`Source<T>`도 요소로 받도록 확장 — 내부적으로
`Slot():Single(element)`를 대신 삽입하는 순수 sugar(최초 검토한 별도
position-keyed 구독 안은 `None`/Length/Move-Swap 문제로 기각). nested
Slot을 반환하는 `:List` 아이템은 `.Length`만큼 다음 형제 `index`를
건너뛰도록 `reconcile`의 `pos` 커밋 공식도 같이 수정.

**2026-08-11 여덟 번째 세션 — CLAUDE.md 재구조화(3000줄+ → 세션 로그 분리)**
(`session/2026-08-11-08-claude-md-restructure.md`)
CLAUDE.md가 세션 로그 누적으로 3196줄까지 불어나 컨텍스트 성능 저하를
유발한다는 사용자 지적 — 세션별 전체 원문을 `.claude/session/`(38개
파일)으로 이전하고, CLAUDE.md엔 세션당 2~4줄 요약+링크만 남기는 구조로
재편. `base/`/`research/`/`question.md`가 이미 매 세션 반영을 성실히
해왔음을 `README.md`/`question.md` 대조로 확인(반영 누락 없음 — archive
이전 전 처리 불필요). 새 서사가 CLAUDE.md에 다시 쌓이지 않도록 "이 절을
갱신하는 방법" 절을 세션 히스토리 맨 위에 명문화.

**2026-08-11 아홉 번째 세션 — 그룹 `Attribute(...)` 프리미티브, 단일 키 `AttributeKey`로 리네임, 이름별 weak 캐시**
(`session/2026-08-11-09-attribute-group-primitive.md`)
여러 Store를 한 번에 attribute로 묶는 `Attribute(store1, store2, ...)`를
`Tag`와 동형인 array-part 값 객체로 신설(`Merged`로 헤테로지니어스 합성,
retract는 Tag처럼 확실히 청소). 이름 충돌 방지로 기존 단일 키
`Attribute<<T>>`를 `AttributeKey<<T>>`로 즉시 리네임(용어정리 대기열이
아니라 지금 바로 적용, 최종 이름만 대기열에 남김). **후속**: `AttributeKey(name)`이
이름별 weak 캐시로 동등성(`AttributeKey(a) == AttributeKey(a)`)을 보장하도록
확정되며, 최초안이던 "그룹 Handler 자기 완결형(Dispatch 재진입 없음)"을
뒤집고 메모이즈된 키로 기존 단일 키 경로에 재귀 위임하는 걸로 재개정
(중복 구현 제거) — `base/attribute-plan.md` 등 관련 문서 전체 반영 완료.

**2026-08-12 세션 — Tween 옵션 값 모양+override 정책 확정, `tween-plan.md` 마감**
(`session/2026-08-12-01-tween-shape-finalized.md`)
사용자가 5개 결정을 한 번에 제안해 전부 확정: 옵션 값은 `Info: TweenInfo?`
우선+편의 필드(`Time`/`Style`/...) 폴백(기본값이 로블록스 `TweenInfo.new()`
자체 기본값과 일치), 옵션 필드는 전부 plain만(State 불가, Blocker의
`:Get()`은 블록 중에도 항상 최신값이라는 기존 원칙 재확인), 릴레이션 슬롯
3번째 상태를 `{Tween, Value}`로 확장(Finish가 목표값을 알아야 함), override
정책을 `Tween.Cancel`(기본)/`Tween.Finish` 2값으로 압축(로블록스
`TweenBase` API 현실상 나머지 옵션들이 관찰상 Cancel과 동일했음), `initValue`는
에이전트 범위 제외하고 사용자가 직접 처리하기로 확정. `Animate` 시그니처와
자연완료 북키핑만 다음 세션으로 연기.

**2026-08-12 두 번째 세션 — `Animate` 콤비네이터 확정, `.claude/` and/or 삼항 관용구 감사**
(`session/2026-08-12-02-animate-confirmed-and-or-audit.md`)
"다음 세션"으로 미뤘던 `Animate`를 사용자가 곧바로 간단한 구체안으로
확정: `Tween` opts(`Value` 제외)를 `T|State<T>`로 받아 각 필드를 resolve한
뒤 `Tween{...}`을 반환하는 `function(self)...end` — `:Compute(fn)`의
`self`-lazy-핸들 계약과 정확히 일치해 `state:Compute(Animate{...})`로
바로 연결(구 `useTween` 2-인자 스케치 대체). 옵션이 State여도 값 변경이
재애니메이션을 트리거하지 않는 게 의도된 동작임을 확정. 별도로 사용자가
Luau `if-then-else` 표현식을 언급하며 `.claude/base` 전역 and/or 삼항
관용구를 감사 — `bind-system-plan.md`의 `Dispatch.retractUnder`에서 실제
falsy-값 버그(`v`가 `false`일 때 `nil`로 새는 문제) 발견·수정, 나머지
히트는 가운데 값이 테이블/숫자라 안전 확인. `research/tween-plan.md`는
이걸로 자연완료 북키핑 하나만 남기고 사실상 마감.

**2026-08-12 세 번째 세션 — `Animate`에 `CanAnimate` 필드 추가, Luau 문법 공식성 문서화**
(`session/2026-08-12-03-cananimate-luau-syntax-note.md`)
`Animate(info)`에 빠져있던 `CanAnimate: State<boolean>|boolean|nil` 필드
추가(`nil`=기본 `true`, `false`면 `Tween`로 안 감싸고 plain 값 그대로 —
reduceMotion류 우회가 이걸로 표현됨). `base/architecture.md`에 "코드
스타일 — Luau 문법 관례" 절 신설 — `if-then-else`(2021년 정식 도입)와
`const` 바인딩 둘 다 공식 Luau 문법임을 명문화(에이전트가 모르고
`and`/`or`로 되돌리는 회귀 방지), `const`는 툴링 미성숙으로 지금은 보류.

**2026-08-12 네 번째 세션 — `:Compute` 콜백 인자 `:Get()` 누락 버그 전역 감사**
(`session/2026-08-12-04-compute-self-get-audit.md`)
사용자가 `Animate`의 `CanAnimate` 예시(`not r`)가 `r:Get()`이어야
한다고 지적 — `:Compute`의 `fn(self, ...)` 인자가 raw 값이 아니라 lazy
State 핸들이라는 기존 확정 계약을 놓친 버그. 같은 클래스의 실수를
`.claude/` 전역에서 찾아 `base/slot-plan.md` 2곳(`LayoutOrder` 예시,
`Slot:Single`)과 `base/tag-plan.md` 1곳에서 추가로 발견·수정.
`bind-system-plan.md`에 "이 실수가 반복되기 쉬움" 주의 노트 추가.
