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

**Store/State/Source 온톨로지 및 관련 인체공학 질문은 2026-08-04 네 라운드에
걸쳐 전부 확정됨**(사용자가 공유해준 실제 참고 코드 `.claude/initreq/
artworks/`, PA님 작성, 로 4차 교차검증까지 마침) — push-invalidate/
pull-recompute 전파 모델, `:Compute` self/with 인자를 둘 다 lazy State
핸들로 통일, State는 쓰기 불가(값 쓰기는 항상 Store의 `__newindex`),
`Source`는 Store와 별개인 독립 프리미티브로 격상, Slot 생존 확인은 기존
canExecute 유틸 재사용으로 해소, `store.key` dot-access를 타입 추론 1급
경로로(인스턴스 생성도 같은 관습, 단 이벤트는 PA님 방식인 평범한 문자열
키+런타임 리플렉션으로 예외), `RobloxFactory` 재호출 가드(같은 팩토리=무시,
다른 팩토리=에러)까지 확정. 남은 건 정확한 API 표면 이름뿐 —
`.claude/base/bind-system-plan.md` 전체, `.claude/question.md`의
"2026-08-04" 절들 참고.

**소스 트리 구조도 확정됨(2026-08-04 5차 라운드)**: `bind-system-plan.md`/
`module-lifecycle-plan.md`/`slot-plan.md` 모두 `research/`에서 `base/`로
승격 완료. 모노레포(`quad-base`/`quad-roblox` 서브폴더, RbxUtil 패턴)로
당장은 모놀리식 진행, 패키지 경계(디스패치 엔진까지 base가 인터페이스로
소유)까지 확정 — `base/architecture.md`의 "구현 착수: 소스 트리 구조 확정"
절 참고. 아래 "지금 할 일" 1번이 다음 단계(실제 스캐폴딩)를 명시.

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

1. **[다음 세션 최우선] 실제 스캐폴딩.** 소스 트리 구조는 문서로 이미 확정됨
   (`base/architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절) — 다음
   세션에서 실제로 `quad-base/`, `quad-roblox/` 폴더, 각각의 `wally.toml`,
   루트 `default.project.json`, `.luaurc`를 만들 것. 이 시점부터 `qa-request/`/
   `archive/` 폴더가 실제로 쓰이기 시작함.
2. 남은 세부 시그니처(`CreatedRef`/`state()`/`Source()`/`DI`류 정확한
   이름)는 위 항목과 자연스럽게 같이 확정 가능 — PA님 실 코드(`.claude/
   initreq/artworks/`)를 이미 받아서 교차검증 완료(아래 인수인계 메모
   참고), `On` 모듈은 이벤트 바인딩 방식이 바뀌며 아예 불필요해짐.
3. `research/existing-instance-bind-plan.md`는 급하지 않음 — 스코프 논의만
   필요, 구현 착수를 막지 않음.
4. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).

## 인수인계 메모 (2026-08-04 세션 종료 시점, 5차 라운드까지 반영)

**5차 라운드(소스 구조 확정)**: 4차 라운드 종료 시점에 서브에이전트로 먼저
계획 문서 전체의 정합성을 점검(차질 없음 확인) 후 진행. 패키징 방식은
서브에이전트 웹 리서치로 확인(`.luaurc` alias 런타임 미지원, wally 심볼릭
링크/타입 문제, `Sleitnick/RbxUtil`의 모노레포+개별 wally.toml 선례,
`pesde`는 아직 이름) — 모노레포로 당장 진행, 나중에 실제 분리 결정.
패키지 경계는 사용자가 "base=인터페이스, roblox=구현"이라는 원칙을 명확히
해서 확정 — Store/State/Source 온톨로지뿐 아니라 `process`/`retract`
디스패치 엔진, `LifetimeHandle`/`PerInstanceState` 인터페이스, Ref, Slot
코어 재조정 로직까지 전부 `quad-base`가 소유(다른 엔진에서도 재사용
가능해야 한다는 전제, 엔진마다 큰 구현 중복 방지가 목적). Slot도 같은
원칙 적용 확정, 그 과정에서 `k:number,v:Instance` 중첩 인스턴스 자식용
`InstanceChild` 핸들러가 추가로 필요하다는 게 밝혀짐. `bind-system-plan.md`/
`module-lifecycle-plan.md`/`slot-plan.md` 세 문서 모두 `research/`에서
`base/`로 승격 완료, `base/architecture.md`에 전체 소스 트리가 문서화됨 —
실제 폴더/파일 스캐폴딩은 다음 세션(위 "지금 할 일" 1번).

## 인수인계 메모 (2026-08-04 세션 종료 시점, 4차 라운드까지 반영)

2026-08-03에 확정됐다고 표시된 결정 전체(architecture.md 14개 + lifecycle-
pattern/store-semantics/bind-system-plan/module-lifecycle-plan/slot-plan/
tween-plan)를 `AskUserQuestion`으로 하나씩 예/아니오 검증 완료 — 상세는
`.claude/question.md`의 "2026-08-04 검증 라운드 완료" 절. 검증 과정에서
사용자가 실시간으로 설계를 더 전개하면서 **"State 프리미티브는 안 만든다"는
기존 결정이 틀렸다는 게 밝혀짐** — Store/State/Source 온톨로지 전체가 이
세션에서 새로 열린 가장 중요한 설계 스레드로 떠올랐음.

**같은 날 이어진 2차/3차 라운드에서 그 온톨로지와 인체공학 질문 전부를
확정함**: push-invalidate/pull-recompute 전파 모델(Fusion식 eager 노드/생성순
정렬 불필요), `:Compute`의 self/with 인자를 둘 다 lazy State 핸들로 통일
(별도 `ComputeWithout` 불필요), State는 쓰기 불가(값 쓰기는 Store의
`__newindex`로만) 확정, `Source`는 Store 내부 디테일이 아니라 값 하나만
다룰 때 쓰는 독립 공개 프리미티브로 격상, Slot 생존 확인 문제는 새 메커니즘
없이 기존 canExecute 유틸 재사용으로 해소(부수 효과로 "Store가 Store를 담을
때 이중 해제 방지 필요한가" 백로그 항목도 "명시적 dispose가 없어 질문 자체가
성립 안 함"으로 닫힘), `store.key` dot-access를 타입 추론 1급 경로로 삼는
관습을 인스턴스 생성까지 프로젝트 전역으로 확정, `RobloxFactory` 재호출
가드(같은 팩토리=무시, 다른 팩토리=에러, `New()`와는 인스턴스별 테이블
분리로 자연히 공존)까지 확정.

**4차 라운드에서 사용자가 실제 참고 코드(`.claude/initreq/artworks/`, PA님
작성 — UI 포함 전반적 설계 패턴을 시범 적용한 데모 모듈)를 공유해줘서
교차검증**: "DI"는 Dependency Injection이 아니라 Declarative Instance였음
(정정). 인스턴스 생성은 2트랙 구상보다 단순한 "제네릭 생성자 함수 하나 +
자주 쓰는 클래스만 정적 필드로 미리 바인딩" 모양으로 정정. **이벤트
바인딩은 `On.EventName` 도트액세스를 접고 PA님 방식(평범한 문자열 키 +
`ReflectionService` 기반 자동 판별)으로 전환** — Store의 dot-access는 실질적
타입 이득이 있어 그대로 유지, 이벤트만 예외. 전파 모델(push-invalidate/
pull-recompute)과 라이프사이클(GC-native)은 PA님 코드가 반례처럼 보였으나
(각각 파생 개념이 없는 단순 pub-sub, 전부 수동 해제) 재검토 후 **기존
확정 유지** — 라이프사이클은 나중에 하이브리드로 확장 가능한 여지만 기록.
OOP 회피 결정은 PA님의 `class.luau`도 같은 체이닝 상속 문제를 보여 오히려
보강됨. **더 이상 열려있는 핵심 설계 질문은 없음** — 남은 건 API 표면 이름뿐
(위 "지금 할 일" 참고). 그 외 자잘한 정정들(Slot retract=폐기 확정, Pipe COW
후보 폐기 등)은 각 문서에 바로 반영해둠 — 재조사 불필요.

이전 세션(2026-08-03) 종료 시점 메모: `.claude/` 전체 스캐폴드 + 대부분의
핵심 아키텍처 결정을 완료, 로컬 git 저장소 초기화+첫 커밋(원격 없음,
`SAFETY.md` 참고 — 원격은 사용자가 제한 계정을 마련해줘야 추가 가능).
