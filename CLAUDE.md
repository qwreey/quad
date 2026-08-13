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
  `existing-instance-bind-plan.md`/`debug-tooling-plan.md`/
  `documentation-plan.md`/`documentation-content-map.md`/
  `framework-comparison-findings.md`/`additional-primitives-plan.md`(2026-08-09
  세 번째 세션에 마지막 열린 항목까지 전부 해소, 이제 배경 자료용)/
  `pre-implementation-audit.md`/`v1-compat-plan.md`
  — 전부 후순위(`tween-plan.md`는 2026-08-12 세션에 마지막 열린 항목까지
  전부 해소돼 `base/`로 승격, 더 이상 여기 없음). 최신 목록·우선순위는
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

0. **⭐ 최우선 — `.claude/question.md` 0-Z(Attribute 이름 소유권) 결정.**
   2026-08-13 여섯 번째 세션에 `Dispatch` 재디스패치 모델이 "하강 diff"로
   다시 정리되면서(`research/dispatch-redispatch-diff-plan.md`), **그
   모델에서 유일하게 안 풀린 것이 Attribute 그룹의 이름 소유권 충돌
   감지**임. 사용자가 "이전 결정(이름별 claimant `Relate`)을 다시 가져오는
   게 맞아 보이나, 다음 세션에 직접 물리적으로 스케치하며 심층 분석"으로
   명시 이관 — 그전까지 아래 항목들보다 우선.
   **핸드오버 시 반드시 알아야 할 것**:
   - **`base/`의 현행 `hintValue` 서술은 아직 옛 모델(철거 선행)이다.**
     새 모델은 `research/dispatch-redispatch-diff-plan.md`에만 있음 —
     base만 읽고 구현하면 옛 모델로 짜게 됨. 0-Z가 정해지면 그 문서 6절의
     파일별 반영 목록대로 `bind-system-plan.md`/`tag-plan.md`/
     `slot-plan.md`/`attribute-plan.md`를 **한 번에** 옮길 것.
   - 반대로 **`base/slot-plan.md`의 "언마운트/`dispose`/해제 순서"는 이미
     확정 반영됨**(재디스패치 모델과 독립적인 결정이라 먼저 들어감).
   - 이 세션에서 같은 날 두 차례 급하게 쓴 의사코드가 각각 버그를 냈다는
     사실 자체가 교훈 — 0-Z 반영도 서두르지 말고 손 트레이싱을 거칠 것
     (`bind-system-plan.md` "Handler 작성 체크리스트" 절이 그 산물).

1. **구현 시작 — 루트 `ROADMAP.md`의 M0부터.** 설계 단계는 2026-08-04 로드맵
   인수인계 라운드로 종료. `research/pre-implementation-audit.md` 우선순위1은
   2026-08-12 열일곱 번째 세션에 마지막 넷(1-3/1-4/1-10/1-11)까지 전부
   해소되어 **11개 전원 완료** — M0 착수 전 남은 유일한 게이트는:
   - **`.claude/luau-test/`(2026-08-09 신설, 2026-08-13 기준 20개 —
     2026-08-12 열일곱 번째 세션에 16/17 추가, 2026-08-13에 세션 8~21이
     만든 커버리지 갭을 메우는 18/19/20 추가) 스파이크 결과** —
     **[2026-08-13] `10`의 A 섹션 일부(ClassName 신호 미발화, Destroy 시
     Connection.Connected 즉시 전환)가 처음으로 부분 확인됨**, 결과는
     `.claude/audit/gcconn-trick-verification.md`. 나머지 19개 전체(신규
     `18`/`19`/`20` 포함) + `10`의 남은 부분(A-1/A-2/B/C)은 여전히 사용자가
     `luau`/`luau-analyze`/`luau-lsp`/Roblox Studio로 안 돌려봄 — 결과가
     나오면 그것부터 반영할 것(`luau-test/README.md`가 파일별로 뭘 우선
     확인해야 하는지 이미 적어둠). 걸리는 게 있으면 `base/` 문서부터 고치고,
     없으면 그대로 M0 실제 코드 작성에 재사용. 설계 자체는 더 이상 막힌
     게 없음 — `.claude/question.md` 2번이 최신 상태. **[2026-08-13 다섯
     번째 세션 추가 주의]** `Dispatch`가 인덱스 기반으로 전면 재설계됨
     (`base/bind-system-plan.md` "Dispatch 체인" 절, `chains`/`retractUnder`
     대신 `retractFrom`+`process`가 반환하는 클로저) — 기존 `luau-test/04`
     (다단 체인 스트레스 테스트)는 옛 모델(핸들러 identity 기반 `chains`)
     전제로 쓰여 있어서, 돌려보기 전에 새 모델에 맞춰 먼저 다시 써야 함
     — **[2026-08-13 여섯 번째 세션에 완료]** `04-dispatch-chain-
     retractFrom.luau`로 전면 재작성됨(인덱스 기반 3단 체인 + 같은 세션
     감사가 발견한 `chains:SetStrong` 순서 버그를 재현하는 음성 대조군
     포함). 대신 `luau-test/19`의 B/C 섹션이 폐기된 설계(`rawNew`+
     `owners`, 3분기 `claimOwner`)를 검증 중인 게 새로 드러나 재작성
     대기 — 무엇을 어떻게 고쳐야 하는지는 그 파일 헤더 배너에 적어둠.
2. **용어 정리 — 1차 제안 이후 대부분 확정, 소수만 남음.** 최신 소스는
   `.claude/question.md` 1번(개수 반복 안 함, 항목 추가/해소될 때마다 여기가
   stale해지는 패턴이 반복됐어서). **[2026-08-13 정정]** `State`는
   2026-08-12 스무 번째 세션에 현재 이름 그대로 유지로 이미 확정됐음(이
   목록이 "위험도 높음, 1순위 open"으로 stale하게 남아있던 걸 발견해 수정)
   — 아직 진짜로 열려있는 것만 짚으면: `DI`→`D`(1순위), `Slot`(2순위),
   `canExecute`(3순위 — `isAlive`는 검토 후 기각, `can` 계열 접두 유지
   방향으로 기울었으나 구체 대안 미정), `Brand`(3순위), `Tag`/`Added`/
   `Removed`/`Merged`(3순위), `Attribute`/`AttributeKey`(3순위).
3. `research/existing-instance-bind-plan.md`는 급하지 않음 — 스코프 논의만
   필요, 구현 착수를 막지 않음.
4. **[백로그]** 범용 렌더 디버깅 도구 `quad-mock`(Tween mock 등 동적 동작
   지원, M0 mock 테스트 하네스와는 별개), 런타임 디버깅 플러그인
   `quad-debug`(Studio 플러그인, 실물 Instance→코드 위치 역추적 — 채널
   실현 가능성은 실측 검증 완료, 세부 API 이름만 남음), 문서 사이트 전체
   구조(초심자/api/심화/`quadnomicon` 4축 + 콘텐츠 맵), `Operator` 콤비네이터
   슈가(`Sum`/`Product`/`Not`/비트연산 등 `:Compute`/`:Apply`용 — 메커니즘은
   확정, 네임스페이스 이름만 미정, 구현은 순수 슈가라 맨 마지막) — 전부 "quad
   개발 상당 부분 끝난 뒤"로 사용자가 못박은 후순위. 상세는 `.claude/README.md`의
   `research/` 표(`debug-tooling-plan.md`/`documentation-plan.md`/
   `documentation-content-map.md`/`framework-comparison-findings.md`/
   `operator-sugar-plan.md`).
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

**2026-08-12 다섯 번째 세션 — `Operator` 콤비네이터 슈가 신설, `Animate`
호출 경로를 `:Compute`→`:Apply`로 정정** (`session/2026-08-12-05-operator-sugar-plan.md`)
기본 연산(산술/논리/비트)을 콤비네이터로 쓰는 슈가 제안(`Not`/`Sum` 등,
새 프리미티브 아님). 처음엔 0항은 `:Compute`, N항은 `:Apply`로 나눴으나
후속 논의로 **재사용 가능한 이름 붙은 콤비네이터는 전부 `:Apply`가 맞다는
쪽으로 정정** — quad가 암묵적 자동 추적을 기각했기 때문에(`base/
bind-system-plan.md`) `local addTax = Sum(a,b)`처럼 만든 값을 `:Compute`에
바로 꽂으면 캡처된 deps가 구독 목록에 안 걸려 조용히 멈추는 진짜 버그가
됨 — 스타일이 아니라 정합성 문제. 같은 근거로 `research/tween-plan.md`의
`Animate` 호출 경로도 `:Compute(Animate{...})`→`:Apply(Animate{...})`로
정정(시그니처/동작 자체는 그대로), `base/bind-system-plan.md`의 `:Apply`
절에 이 관용구를 일반 원칙으로 추가. 네임스페이스 이름(`Operator`/`Op`/`Ops`
중 미정)만 열린 질문으로 남음. 우선순위는 여전히 사용자가 맨 마지막으로
직접 지정(순수 슈가, 함수 간 의존 없음) — 구현 착수 안 함. 사용자가
`:Apply` 통일에 동의, `Sum(a,b,Sum(c,d))` 중첩 flatten 최적화(약한
`Relate`로 클로저의 operand 목록 추적) 아이디어도 나왔으나 실사용
사례 나오면 재검토로 보류. `base/architecture.md`의 stale `Animate`
2-인자 시그니처 코멘트도 이 김에 수정.

**2026-08-12 여섯 번째 세션 — Tween 자연완료 북키핑 확정, `tween-plan.md`
`base/`로 승격** (`session/2026-08-12-06-tween-completed-bookkeeping-promoted.md`)
`tween-plan.md`의 마지막 열린 질문(자연완료 시 per-instance 북키핑 정리
여부)을 사용자가 확정 — 정리 안 해도 됨(자연완료는 유저가 원한 목표값에
도달한 상태라 남은 참조가 부작용 없음, `Value`가 항상 lerp 가능한
프리미티브라 메모리 문제도 없음, 별도 Completed 이벤트 정리 장치는
오버엔지니어링). 이걸로 열린 설계 질문이 없어져 `research/tween-plan.md`를
`base/tween-plan.md`로 승격, 라이브 크로스레퍼런스 전부 갱신(session/
과거 기록은 원문 보존을 위해 그대로 둠).

**2026-08-12 일곱 번째 세션 — `PreRef`는 취소 개념 없음, 재사용은 error**
(`session/2026-08-12-07-preref-single-use-no-cancel.md`)
`documentation-content-map.md`에 미정으로 남아있던 "`PreRef` 취소 가능성"
해소: `PreRef`는 pre-pass에서 fire와 동시에 소진돼 정상 `retract` 체인에
아예 안 올라가므로 취소 개념 자체가 없음(사용자 직관과 기존 구조가
정확히 일치). 진짜 위험은 취소가 아니라 재사용(stale `.Value`로 콜백이
조용히 잘못 호출됨)이라고 판단해, 이미 fire된 `PreRef`를 다시 놓으면
pre-pass가 즉시 `error`하는 가드 확정(`_fired` 플래그, 거의 공짜 구현) —
1회용, use only once. `Slot:List`의 `updateFn`처럼 반복 호출되는 자리에선
매번 새 `PreRef()`를 만들라는 관용구도 같이 명문화.

**2026-08-12 여덟 번째 세션 — `Ref`의 retract, `TagHandler`와 같은 패턴으로
확정** (`session/2026-08-12-08-ref-retract-tagged-pattern.md`)
`State<Ref>`가 `refA→refB`로 바뀌는 경우 이전 Ref가 stale하게 남는 문제를
사용자가 지적 — 처음엔 "retract가 `Set(nil)`"로 단순 답했으나,
`Dispatch`의 일반 계약("핸들러 타입이 안 바뀌면 retract 없이 process가
diff")과 대조해 `TagHandler` 선례와 정확히 같은 메커니즘이어야 함을
발견·정정: `refA→refB`는 `process`가 `Relate`로 기억해둔 이전 값과 diff해
언바인딩(`old:Set(nil)`), `retract`는 그 자리가 아예 Ref이길 그만둘 때만.
사용자가 추가로 확정: 비-nilable `Ref<T>`도 "확정값을 부작용 없이 읽는"
정당한 용도라 계속 지원하되, Store/Modifier 자리에 놓을 땐 호출자가 직접
`Ref<<T?>>(...)`로 명시(기존 관용구 재사용, 새 규칙 아님). Ref의
언바인딩은 Instance `Destroy()`와 완전히 무관 — Destroy된 대상을 계속
들고 있는 채로 남는 건 UB로 허용, 정리가 필요하면 `Effect`를 쓰도록
문서가 유도.

**2026-08-12 아홉 번째 세션 — `Slot`의 store 재바인드도 `Ref`와 같은
`Relate` diff 패턴** (`session/2026-08-12-09-slot-retract-same-pattern.md`)
직전 세션의 `Ref` 패턴이 `Slot`에도 적용되는지 사용자가 확인 요청 —
`slot-plan.md`의 "store 바인드 핸들러가 retract하고 다시 process" 서술이
`Ref`에서 고쳤던 것과 같은 부정확한 서술이었음을 발견(실제 `Dispatch/
Slot.luau`의 `process`엔 이전 값 비교 자체가 없었고 `destroySlotTree`도
store-bind retract 경로에 연결된 적 없는 진짜 갭). `Ref`와 같은 `Relate`
기반 패턴으로 정정하되, Slot은 이미 확정된 "폐기, 옮기지 않음"(portal
없음) 정책 때문에 세밀한 diff 대신 **identity 비교**로 단순화 — 같은
바인딩이면 완전 무시, 다르면 이전 것 통째로 폐기 후 새로 마운트. 이
no-op 가드는 Tag/Ref보다 Slot에서 훨씬 중요함(가드 없으면 재귀 재emit마다
마운트된 서브트리 전체가 파괴됐다 재생성돼 자식의 스크롤/포커스/애니메이션
상태가 전부 유실됨).

**2026-08-12 열 번째 세션 — Attribute 이름 소유권, `rawNew` 전용 키로
그룹/직접 쓰기 충돌 방지** (`session/2026-08-12-10-attribute-name-ownership.md`)
`Ref`/`Slot`에 이어 `Attribute`도 확인 — 그룹 `Attribute(...)`의 위임
메커니즘이 공개 `AttributeKey(name)` 캐시(이름별 weak 캐시로 항상 같은
객체)를 그대로 쓰다 보니, 직접 리터럴 `[AttributeKey "name"]=v`와 배열파트
`Attribute(store)`(또는 서로 다른 두 그룹)가 같은 이름을 동시에 관리하면
같은 `(inst,k)` 자리로 수렴해 조용히 마지막 쓰기가 이기는 충돌이 실제로
가능함을 확인. Claude가 처음 제안한 별도 `Relate` claimant 레지스트리 대신,
사용자가 더 단순한 안을 제시해 채택: 그룹이 캐시를 우회하는 `rawNew(name)`로
이름마다 자기 전용 키 객체를 만들어 자기 릴레이션에 캐싱하면(그룹 값 교체를
넘어 유지), "이 이름에 지금 어느 키 객체가 적용돼 있는가" 조회만으로
`AttributeKeyHandler`에서 바로 소유권 판정(다르면 error) 가능 — 별도
claimant 타입 없이 AttributeKey 객체 identity 자체를 재사용하는 더 적은
부품의 설계. 기존 diff 로직(사라진 이름만 nil, 남은/새 이름은 갱신)은
그대로 맞물림, 캐시가 그룹 값 교체를 넘어 영속돼야 한다는 조건만 명시.

**2026-08-12 열한 번째 세션 — "retract는 항상 불림" 전면 정정, `Tag`
참조 카운트 재설계** (`session/2026-08-12-11-retract-always-fires-correction.md`)
`Tag`도 Attribute와 같은 참조 카운트 문제(서로 다른 위치의 `Tag(...)`가
같은 이름을 겹쳐 가질 수 있음, 웹 `className` 합집합)가 있다는 사용자
지적에서 출발 — 논의 중 사용자가 "retract가 v=Tag(nil 아님)를 받는
경우"를 전제로 설계를 제안했고, 이게 기존 `assert(v==nil)`과 모순됨을
Claude가 지적했으나, 사용자가 "덮여 쓰여지는 즉시 retract 실행, 전체
트랙을 retract하고 리빌드하는 맥락"이라고 재확인. `bind-system-plan.md`
자기 "확정된 디스패치 모델" 절(2026-08-04 원문)을 재대조하니 `StoreBind`가
재-dispatch 전에 무조건 `retractUnder`를 부른다고 이미 명시돼 있었음 —
"핸들러 타입이 안 바뀌면 retract 생략"이라는 2026-08-07 정정 서술이
자기 문서와 처음부터 모순돼 있었고, `Tag`의 `assert(v==nil)`을 액면
그대로 믿고 거꾸로 일반 규칙을 잘못 추론한 게 오류의 출처였음이 드러남.
**이 오류가 이번 대화에서 만든 `Ref`/`Slot`/`Attribute` 설계 전부에도
그대로 이어받아져 있었음** — 전부 한 세션에 정정: `retract`는 store
재발행마다 항상 불리고 `v`는 대체 값 자체일 수 있음(`nil` 가정 금지),
"이전 기여 제거는 `retract`, 새 기여 등록은 `process`"로 분업하면
`process`의 별도 diff가 필요 없어짐. `Tag`는 `kTagMap`(위치→Tag)+
`tagNameMap`(이름→Tag set) 참조 카운트로 재설계(`AddTag`는 온전히
`process`, `RemoveTag`는 온전히 `retract`, `Contains` 힌트로 flicker
방지). `Attribute`의 그룹 위임도 "남아있는 이름"에서 `retractUnder`를
생략하면 체인이 계속 쌓이는 누수를 추가로 발견·정정. 역전 사례는
`archive/retract-always-fires-reversed.md`에 원문·근거·영향 범위 보존.

**2026-08-12 열두 번째 세션 — `Slot`의 `slot→inst` 소유권 relate,
`retractUnder` 4-인자 이유** (`session/2026-08-12-12-slot-owner-relate-retractunder-args.md`)
직전 세션에서 고친 `Slot`의 의사코드를 사용자가 검토 — 위치별 relate로
"같은 값인가"를 비교하는 대신, Slot이 이미 갖고 있는 "한 element가
어디에도 중복 마운트 안 됨" 전역 불변식을 Slot 컨테이너 자신에도
그대로 적용해 `Relate<slot→inst>`로 소유권을 직접 추적하는 게 더
정확하다고 지적(위치 비교로는 같은 Slot이 동시에 다른 위치에도
마운트된 경우를 못 잡음) — `owner==inst`면 단순 emit 전파로 무시,
다른 inst면 즉시 error, 없으면 정상 바인딩으로 재작성. 별도로
`Dispatch.retractUnder(inst,k,keep,v)`가 왜 4-인자인지 질문받아 답변:
`keep`(체인 어디까지 지울지, 구조적)과 `v`(새로 들어올 값 힌트,
Tag/Ref/Slot/Attribute가 이번 대화 내내 의존해온 그 메커니즘)는 서로
다른 용도라 하나로 안 합쳐짐 — old value를 각 핸들러가 자기 `Relate`로
저장한다는 원래 결정과는 무관, `retractUnder`는 old를 옮긴 적이 없음.

**2026-08-12 열세 번째 세션 — `Slot`의 두-`Relate` 상호 GC 순환 수정**
(`session/2026-08-12-13-slot-gc-cycle-fix.md`)
사용자가 직전 세션의 `slotOwner`(slot→inst)/`kSlotMap`(inst→slot)이 둘 다
`SetStrong`이면 서로가 서로를 살려주는 순환이 생겨 GC가 안 된다고 지적 —
`bindLifetime`이 이미 쓰는 "값이 자기 키를 다시 참조"하는 단일 테이블
자기참조(`Dispatch.setLength`의 `observer` 클로저가 `inst` 캡처,
`Ref.Value=inst`)는 그 키가 테이블 바깥에서 독립 reachable한지만
판별하면 돼서 안전하지만, **서로 다른 두 `Relate`가 서로의 키를 상대방
값으로 제공하는 상호 순환**은 판별 자체가 서로에게 의존해버려 Lua
5.2+ ephemeron이 풀려던 바로 그 사례라는 걸 Claude가 재확인. `grep`으로
base/ 전체 `Relate()` 인스턴스를 감사한 결과 `inst`가 아닌 다른 값을
바깥 키로 쓰는 건 `slotOwner`가 유일했음(나머지는 담긴 값이 `inst`로
되돌아가는 back-reference가 없거나, 있어도 단일 테이블이라 안전).
`kSlotMap`/`slotOwner` 둘 다 `SetWeak`로 낮추고, 실제 GC 앵커는
`bindLifetime`/`unbindLifetime` 하나로 통일 — `attachSlot`에
`bindLifetime(physicalTarget, slot)`, `destroySlotTree`에 짝인
`unbindLifetime(slot._mountedInst, slot)` 추가(기존엔 자식 observer들의
unbindLifetime만 있고 slot 자신의 앵커/해제가 빠져 있었음).

**2026-08-12 열네 번째 세션 — Luau에 ephemeron 없음, 공식 확인·문서화**
(`session/2026-08-12-14-luau-no-ephemeron-confirmed.md`)
사용자가 직전 세션의 "Luau가 두-`Relate` 상호 순환을 올바르게 처리하는지
검증된 바 없음"이라는 방어적 서술에 공식 출처를 제시 — Luau는 복잡성
때문에 Lua 5.2의 ephemeron 테이블을 도입하지 않음
(https://luau.org/compatibility/ "Lua 5.2" 섹션 "Ephemeron tables" 항목).
`base/slot-plan.md`의 해당 문단을 "추측성 방어"에서 "공식 확인된 필수
조치"로 정정, `base/relate-plan.md`에 "위험한 패턴 — 서로 다른 두
`Relate`의 상호 강참조 순환" 절을 신설해 단일 `Relate` 자기참조(안전)와
두-`Relate` 상호 순환(위험, 실제로 GC 안 됨)을 명확히 구분하고 일반
규칙으로 명문화 — 앞으로 비슷한 설계에서 Slot 사례를 매번 재발굴하지
않도록. 열한~열네 번째 세션에 걸친 "retract는 항상 불림" 정정과 그
파생 GC 이슈 시리즈가 이걸로 마무리됨.

**2026-08-12 열다섯 번째 세션 — Slot-in-Slot relate 범위 확인, `Tag:Added`
vararg, `Slot:Splice` 신설** (`session/2026-08-12-15-slot-in-slot-relate-scope-tag-splice-additions.md`)
사용자가 최근 확정 설계 4개를 재확인 질문 — 3개(Slot-in-Slot의
`slotOwner`/`kSlotMap` relate가 최상위 마운트에만 걸림, `Animate` 반환
타입이 `State<Tween<T>|T>`, Slot retract는 전부 파괴·포탈 없음)는 문서와
일치해 확인만. 1개(`Tag:Added`/`:Removed`가 문서상 단일 `name`만 받던 것)는
불일치 발견해 정정 — 처음엔 vararg로 갔다가, `table.unpack(t)`가 인자
목록 tail 위치일 때만 완전히 펼쳐진다는 Lua 문법 한계(조건절로 조립한
여러 동적 테이블은 한 vararg 호출로 못 합침) 때문에 같은 세션 안에
`string | {string}`(내부 flatten)로 재수렴(self-return 최적화는 매번
멤버십을 먼저 읽어야 해서 기각, `tag-plan.md`). 추가로 `Slot:Splice(index,
removeCount, ...newElements)` CRUD 신설 — 구간 제거+삽입을 shift/recompute
1회로 묶는 순수 최적화. `newElements`는 `Tag:Added`와 달리 의도적으로
vararg 유지(요소 개수가 대개 소수로 고정, 동적이면 Slot-in-Slot으로 흡수
가능, `T|{T}`는 `Slot<T>`가 base 레벨에선 `T`가 뭔지 모르는 제네릭이라
바깥 `{}`가 단일 T인지 배열인지 원천적으로 판별 불가능해서 오히려
모호해짐 — `Slot`의 T에 우연히 Slot이 섞여서가 아님, `slot-plan.md`).

**2026-08-12 열여섯 번째 세션 — 코퍼스 전체 감사, Attribute retract 전면
재설계, Slot 소유권 일반화** (`session/2026-08-12-16-corpus-audit-attribute-retract-slot-owner.md`)
7개 에이전트로 `.claude/` 코퍼스 전체를 감사해 stale 서술 다수 정정
(retract-always-fires 정정 전파 누락, Tween research→base 승격 반영
누락, `Relate` API 인자 개수 버그, `pre-implementation-audit.md` 열린
항목 개수 오류 등). 이어서 사용자가 diff를 직접 검토하며 Attribute
`retract`를 다단계로 재설계 — **최종: retract는 완전 no-op(SetAttribute는
오직 `process(inst,k,nil)`), Attribute는 오직 명시적 `None`/`nil`로만
지워짐(그룹이 사라진 이름을 자동으로 안 지워줌 — Ref의 "Destroy 무관"
철학과 통일), 단 사라진 이름의 *구독*은 끊음(값은 안 지워도 리소스는
안 새게)**. 일반 규칙 2개 신설(retract의 `v` 타입 미보장 → `isX(v)`
가드 필수, retract 안에서 `process` 호출은 UB). Slot도 `slotOwner`를
`elementOwner`로 일반화해 top-level/nested 이중 마운트 gap 폐쇄,
`bindLifetime`을 top-level 전용으로 축소(nested는 `_elements` 강참조로
transitively 생존). `and`/`or` 삼항 관용구 전면 금지(기존 "항상-truthy면
예외" 조항 폐기), 코퍼스 전체 실제 코드 6곳을 `if-then-else`로 교체.
Attribute 자동 unset이 필요해지면 쓸 `:Apply` opt-in 유틸을
`research/operator-sugar-plan.md`에 백로그로 추가(착수 안 함).

**2026-08-12 열일곱 번째 세션 — 우선순위1 마지막 넷 전부 해소**
(`session/2026-08-12-17-priority1-audit-resolved.md`)
`pre-implementation-audit.md` 우선순위1 중 열려있던 마지막 넷을 사용자가
한 번에 확정: 우선순위 동률/매치실패(1-3, tiebreak 강제 대신
`HANDLER_PRIORITY_*` 상수+디버그 모드 동률 감지/핸들러 목록 함수, 매치실패는
즉시 error), provider 미주입 dispatch(1-4, 매치실패 규칙에 자연 흡수),
`store.key` 레코드 필드 타이핑(1-10, Luau `type function`으로 `Store<T>`→
`{[K]: Source<V>}` 합성 가능함을 구체 스케치로 확인), Modifier
`__index`+`table.clone` 트릭(1-11, 메타테이블이 복사 아닌 참조 공유임을
확인). 부수적으로 Property에 Attribute식 소유권 레지스트리를 적용하는 안을
검토 후 기각(엔진이 정한 유한 프로퍼티 이름 집합은 호출자가 전용 키를 못
만들어 소유권 판정 불가 — Property가 override 우선순위를 쓰는 이유).
**우선순위1 11개 전원 해소** — M0 착수 전 남은 건 `.claude/luau-test/`
스파이크 실측뿐. **핸드오버 점검 중 발견**: 1-10/1-11은 설계는 확정됐지만
이를 실제로 실측할 스파이크 파일 자체가 없었던 갭 — `16-type-store-key-
typefunction.luau`/`17-modifier-index-tableclone-chaining.luau` 신규
추가(총 17개), `ROADMAP.md` M2/M3/M7 체크리스트에도 누락됐던 항목(디버그
모드 동률 감지+`listHandlers`, `store.key`/`table.clone` 실측 링크) 보강.

**2026-08-12 열여덟 번째 세션 — `framework-comparison-findings.md` 남은
두 항목 "고칠 필요 없음"으로 최종 판단**
(`session/2026-08-12-18-framework-comparison-fixables-closed.md`)
"고칠 만한 것"으로 분류돼 있던 use-after-destroy 검증 안전망 부재,
`:With`의 동적 의존성 미지원 두 항목을 사용자가 확정 판단 — 둘 다 "의도된
트레이드오프"로 문서 3번 절로 이전. use-after-destroy 검증은 `bindLifetime`/
`Effect`로 이미 커버되는 영역에 별도 장치를 얹으면 GC-native 아키텍처와
모순(항상 명시적 Destroy를 강제하게 됨) — 완전한 UB로 남기고 문서화로만
대응. 동적 With는 State immutable 가정과 정면 모순, 실사용 사례도 거의
없음(React `useMemo` deps도 대부분 정적) — 의도적 비지원으로 확정.
`question.md`도 동기화.

**2026-08-12 열아홉 번째 세션 — `Operator` 콤비네이터 슈가 외부 리서치**
(`session/2026-08-12-19-operator-sugar-external-research.md`)
서브 에이전트로 `research/operator-sugar-plan.md`의 `Operator.*` 카탈로그를
다른 리액티브 라이브러리 실제 선례와 대조. 논리(`Not`/`And`/`Or`)/`Sum`/
`Clamp`/`Min`/`Max`는 선례 뚜렷(VueUse `@vueuse/math` 등), 비트연산·비교
연산자·`Sub`/`Div`는 리액티브 콤비네이터로서 선례 전무(드랍 후보). 업계
표준 카테고리인 Debounce/Throttle 부재를 발견했으나 `Blocker`(타이머 없는
값 기반 게이트)와는 다른 메커니즘이라 quad-roblox 쪽 별도 프리미티브
가능성으로 분리. `Filtered`를 Slot 밖에선 plain transform, Slot 안에선
별도 프리미티브로 나눈 기존 판단이 ReactiveUI/SolidJS 선례로 뒷받침됨.
네임스페이스는 Python `operator` 모듈이 `Operator`의 가장 강한 선례 —
최종 확정은 여전히 사용자 몫, `question.md` 3번 동기화.

**2026-08-12 스무 번째 세션 — `State` 이름 최종 확정, use-after-destroy
안전망 근본 재검토 후 최종 기각**
(`session/2026-08-12-20-state-name-final-usedaftedestroy-scoped-out.md`)
용어 정리 1순위였던 `State`를 현재 이름 그대로 유지로 확정
(`Computed`/`Derived` 검토 종료). use-after-destroy는 열여덟 번째
세션에서 이미 "고칠 필요 없음"으로 정리했으나 사용자가 근본부터 재검토
요청 — 일반적 검증은 Instance 가상화/추적이 필요해 rbvm 같은 전문
라이브러리의 영역(quad가 재발명하면 오버엔지니어링), quad-debug는
quad 자신이 만든 효과만 설명하는 스코프라 외부 조작은 원래 관심사
아님(`research/debug-tooling-plan.md`가 이미 명시), 실제 위험 지점은
`Ref`가 관례를 벗어나 반출되는 경우뿐(React `useRef`급 스코프 관례를
`base/bind-system-plan.md`에 이번에 명문화) — 전부 동의로 최종 기각,
근거를 `research/framework-comparison-findings.md`에 보강.

**2026-08-12 스물한 번째 세션 — 네이밍 정리 후속: `Pipe` 기각, `Compute`
vs `Computed`, `:With`/`Tag`·`Modifier` clone 대조 명문화**
(`session/2026-08-12-21-naming-clarity-pipe-compute-with-clone-contrast.md`)
`:With`가 `Tag`/`Modifier`의 clone 체이닝과 겉보기엔 같은 `:` 문법이라
혼동될 여지를 `bind-system-plan.md`에 경고 문단으로 명문화. `State` 대안으로
검토됐던 `Pipe`는 "캐시한다"는 동작이 파이프 비유와 안 맞고 노드 단위로
보기도 애매해 기각. `Compute`(현재 이름) vs `Computed`(만약이었다면) 논의—
Vue/Svelte는 lazy인데도 `computed`를 쓰지만, quad 자기 코퍼스 안에서는
`Tag.Added`/`Modifier.Overridden`이 이미 "-ed = clone 후 즉시 확정된 값"
관례를 선점해뒀어서 lazy한 State에 재사용하면 자기 관례와 충돌 — `Compute`가
더 정확하다는 데 동의, `bind-system-plan.md`에 근거 추가.

**2026-08-13 첫 번째 세션 — gcconn 트릭 부분 실측, `Relate` 상호 순환
스파이크 신규, README 동기화**
(`session/2026-08-13-01-gcconn-audit-relate-cycle-spike-readme-sync.md`)
사용자가 Studio에서 gcconn 트릭의 핵심 가정(ClassName 신호 미발화, Destroy
시 `Connected` 즉시 전환) 둘을 자작 스크립트로 실측 — 결과를
`.claude/audit/gcconn-trick-verification.md`에 정리(부분 확인, `luau-test/10`의
A-1/A-2/B/C는 미해소로 명확히 구분). GC 강제 트리거 기법을
`gc-trigger-helper.server.luau`로 문서화하면서 `07`의 "Studio에서 GC 검증
불가" stale 서술도 정정. 코퍼스를 다시 훑다가 `relate-plan.md`의 "두
`Relate` 상호 순환은 ephemeron 없이 GC 안 됨" 주장이 공식 문서 인용으로만
뒷받침돼 실측된 적 없었던 갭을 발견해 `18` 신규 작성, CLAUDE.md 자신의
"지금 할 일"이 이미 해소된 `State` 용어 논쟁을 stale하게 open으로 남겨뒀던
것도 발견·수정. 서브에이전트에 위임한 코퍼스 스윕으로 세션 8~21(마지막
전체 감사인 세션 16 이후) 변경사항이 `.claude/README.md` 요약 테이블에
안 반영돼 있던 8개 행 동기화(base/research 문서 본문 자체는 이미 최신,
색인 레이어만 밀렸던 것) + `attribute-plan.md` 행의 실제 오류(폐기된
중간 단계 서술) 수정 + 새 소유권/참조카운트 알고리즘(Tag/Attribute/Slot)과
`Slot:Splice` 산술을 커버하는 `19`/`20` 스파이크 추가(총 20개).

**2026-08-13 두 번째 세션 — Haskell Monad/Applicative 비교, `State<State<T>>`
재진입 디스패치 버그 발견·수정**
(`session/2026-08-13-02-haskell-comparison-dispatch-reentrant-bug.md`)
"커링/레이지 이벨루에이션 말고 Haskell에서 가져올 것"을 조사 — Functor/
Applicative/Semigroup은 `:Compute`/`:With`+trailing-args/`Merged`·`Overridden`로
이미 사실상 가져와 있음 확인, Monad bind/join은 `StoreBind`/`Slot:Single`/
`NoneHandler`가 각자 따로 재구현 중인 미일반화 후보로 식별(착수 안 함),
Traversable/sequence는 진짜 빈 자리로 식별(백로그), do-notation류는 Luau에
HKT가 없어 스킵 권장. 후속으로 사용자가 `Alternative`(nil 대체값)를
`Operator` 카탈로그에 넣자고 제안하며 `retractUnder`의 꼬리부터-cutoff
로직을 직접 되짚어 "같은 키에서 핸들러가 재사용되면 문제 아닌가" 제기 —
손 트레이싱으로 `State<State<T>>`(store가 emit하는 값 자체가 또
State/Source)가 같은 `(inst,k)`에 같은 핸들러를 중복 push시켜
`retractUnder`의 첫-매치 cutoff가 안쪽 자신을 잘못 retract하는 실제 체인
파손 버그(구독이 등록 직후 스스로 끊김)로 확인됨 — 코퍼스 어디에도 UB로
명시된 적 없었고 막는 가드도 전혀 없었던 진짜 갭. `Dispatch.process`에
중복 핸들러 즉시 error 가드 추가, 낙관적으로 틀렸던 "다른 store여도
상관없이 처리 가능" 서술 정정. 부수적으로 `luau-test/04`가 이미 이
시나리오를 스트레스 테스트로 갖고 있었지만 `retract`가 no-op 스텁이라
이 버그를 절대 못 잡는 사각지대였음을 발견해 3~4단계를 "가드가 실제로
걸리는지" 검증으로 재작성. `operator-sugar-plan.md`에 `Alternative` 후보
신설, `.claude/README.md`/`question.md` 동기화.

**2026-08-13 세 번째 세션 — v1 `objectListClass.__newIndex` 오타 기능,
v2 논의 대상 아님으로 확정** (`session/2026-08-13-03-v1-newindex-typo-scoped-out.md`)
`question.md`의 v1 `__newIndex` 오타(항상 미발동) 재현 테스트 필요 항목을
사용자가 정리 — 당시 실수였던 건 맞지만, v2는 오브젝트 id 주입/조회
(`GetObjects()`류) 개념 자체가 없어져 재현 여부와 무관하게 v2 마이그레이션
가이드에서 다룰 대상이 아님(있었다 해도 v1 전용 기능). `question.md`/
`reference/quad-v1-architecture.md` 둘 다 해소로 반영.

**2026-08-13 네 번째 세션 — 사각지대 손 트레이싱 라운드, `Dispatch.processAs`/
`retractSelfAndUnder` 체크포인트 핸들러 신설**
(`session/2026-08-13-04-blind-spot-audit-checkpoint-handlers.md`)
직전 세션의 `State<State<T>>` 발견 방식(합성 시나리오를 pseudocode에 손
대입)을 서브에이전트 4개로 코퍼스 전체에 반복 — 실제 버그 3건 발견:
Tag 참조 카운트가 객체 identity 기준이라 같은 Tag 객체 재사용 시 깨짐,
Attribute 그룹이 이름을 놓았다 다시 포함하면 자기 자신과 소유권 충돌,
(Slot의 이중 State 언랩은 사용자 확인 결과 버그가 아니라 기존
`State<State<T>>` UB 범위였음, 과다 보고 정정). 사용자가 Attribute
설계를 직접 재검토하며 `owners`/`rawNew` 수동 레지스트리를 통째로
버리고, `isHandlable` 없는(스캔 불가) 순수 체크포인트 핸들러를
`Dispatch.processAs`로 명시 push + `Dispatch.retractSelfAndUnder`(target
자신 포함 철거, 신설)로 통째 정리하는 설계로 전환 — 소유권 충돌 감지가
기존 재진입 가드로 공짜로 해결됨. Slot의 `releaseOwner` 불일치 무시를
error로 강화, `bindLifetime` 위치를 Handler 층위로 이동해 `unbindLifetime`과
대칭 맞춤. `Brand`/`isXX`의 nil 처리는 서브에이전트 확인 결과 안전.
`base/bind-system-plan.md`/`tag-plan.md`/`attribute-plan.md`/`slot-plan.md`
전부 반영 완료. **[정정, 같은 날 다섯 번째 세션]** 이 세션에서 신설한
`Dispatch.processAs`/`retractSelfAndUnder` 체크포인트 패턴은 바로 다음
세션에 더 근본적인 인덱스 기반 재설계로 대체되며 전부 걷어내짐 — 아래
다섯 번째 세션 항목 참고, 원문은 `archive/checkpoint-handler-pattern-reversed.md`.

**2026-08-13 다섯 번째 세션 — `Dispatch` 인덱스 기반 전면 재설계,
`State<State<T>>` UB 해제** (`session/2026-08-13-05-dispatch-index-based-redesign.md`)
사용자가 체크포인트 패턴에 "왜 최상단에서 뭔가 지우는 일을 만들었냐,
가정이 늘어나는 건 안 좋다"고 문제 제기하며 시작 — `chains`가 핸들러
**객체 identity**로 위치를 추적하는 것 자체가 `State<State<T>>`를 UB로
만든 근본 원인이라는 데까지 논의가 이어짐. 최종 설계: `chains`를
**재귀 깊이 인덱스**로 추적(같은 키 재귀는 `index+1`, 다른 키 위임은
항상 `1`부터, 0이 아니라 1인 이유는 Luau `ipairs`/`#` 관례), `Handler`
계약이 `process`/`retract` 2-메소드에서 `process`가 자기 retract
클로저(`(hintValue)->()`)를 반환하는 1-메소드로 축소, `Dispatch.process`가
핸들러를 부르기 전에 그 인덱스 점유 여부를 먼저 체크(핸들러 부작용 낭비
없음, 도메인 특화 에러 메시지가 없는 건 의도된 트레이드오프 — 에러=패닉
상태라 상세 설명 비용을 들일 이유가 없다는 데 사용자 동의),
`retractUnder`/`retractSelfAndUnder`도 `Dispatch.retractFrom(inst,k,index,v)`
하나로 통합(자기 포함/미만 여부는 호출자가 넘기는 인덱스 자체로 표현).
이 재설계로 `State<State<T>>`가 UB에서 정상 지원 대상으로 재정정되고,
전날 만든 체크포인트 패턴 전체(`AttributeGroupKeyHandler`/`processAs`/
`retractSelfAndUnder`)가 통째로 불필요해짐 — Attribute 그룹은 이제
공개 `AttributeKey(name)`으로 항상 인덱스 1에 직접 위임, 점유 체크가
소유권 충돌 감지를 대신함. 부수 효과로 여러 핸들러(StoreBind/Ref/Tag/
Slot/Attribute)의 private `Relate` 상태 저장소가 대거 줄어듦(process가
반환하는 클로저가 upvalue로 직접 캡처하므로 process→retract 사이 단발성
handoff용 저장이 불필요해짐 — `Relate`는 여러 위치/사이클을 가로지르는
누적 상태에만 남음). `bind-system-plan.md`/`tag-plan.md`/
`attribute-plan.md`/`slot-plan.md`/`architecture.md`/`store-semantics.md`/
`modifier-plan.md` 전부 반영, `archive/checkpoint-handler-pattern-reversed.md`
신설.

**2026-08-13 여섯 번째 세션 — c33ae04 커밋 전체 감사(버그 4건), Slot
언마운트 전환, 재디스패치 모델 재설계**
(`session/2026-08-13-06-commit-audit-dispatch-redesign-bugs.md`)
사용자 지시로 직전 커밋을 메인 컨텍스트에서 직접 정독 — 인덱스 재설계
**방향은 옳지만 새로 쓴 의사코드가 손 트레이싱을 안 거친 채 커밋**됐음이
드러나 실제 버그 4건 발견·수정: (1) `Dispatch.process`의 `chains:SetStrong`이
`h.process` 뒤에 있어 최초 마운트에서 하위 retractor가 통째로 유실,
(2) Attribute 그룹이 `process`에서 `retractFrom`을 선행 호출해 점유
체크(=소유권 충돌 감지)가 전혀 작동 안 함, (3) `SlotHandler`가 claim
실패에도 파괴적 클로저를 반환해 `Frame{slot,slot}`에서 이중 파괴,
(4) `Ref` retractor가 spurious 재발행에서도 `relate`를 지워 dedup 무력화.
Slot 소유권은 nested=엄격 `claimOwner`/top-level=`claimOwnerAt(inst,k)`로
분리하고 `rawRemove`의 `releaseOwner` 누락·`destroySlotTree`의 GC 타이밍
의존 오류도 수정. `ROADMAP.md`가 2026-08-08 이전 모델로 남아있던 것, base
내 "3종 vs 4종 계약" 모순, `luau-test/04`가 없어진 가드를 검증하던 것도
정리(`04`는 인덱스 모델 + 버그 (1) 재현 음성 대조군으로 재작성).
재발 방지로 `bind-system-plan.md`에 "Handler 작성 체크리스트"(7항목),
`relate-plan.md`에 "언제 `Relate`를 쓰고 언제 쓰면 안 되는가" 신설.

**이어진 사용자 설계 결정(같은 세션, 최종 상태만)**:
- **`State<Slot>` 교체 = 파괴가 아니라 언마운트**(`state<Frame>`와 동일,
  비파괴 추출은 `Splice`로 이미 지원) — **포탈이 별도 기능이 아니라 이
  결정의 귀결이 됨**. 해제는 `setOffsetSource(None)` → `setLength(0)`
  **순서 고정**(반대면 죽는 중인 서브트리의 offset `Source`에 헛된 `:Set()`이
  날아감) + `recompute`의 `nil` 관대 처리/`slot.Offset = nil` 방어.
  별도 unregister API는 불필요. `base/slot-plan.md`에 **확정 반영 완료**.
- **`dispose(value)` 신설** — "트리가 아직 살아있길 요구하면 파괴를 거부하고
  error"(엔진은 조용히 넘어가지만 quad 자료구조가 깨지므로). 시그니처/범위는
  `question.md` 0-B.
- **재디스패치를 "하강 diff"로 재설계** — 래핑 핸들러의 `retractFrom` 선행
  호출을 폐기하고 `Dispatch.process`가 **핸들러를 먼저 비교**(같으면 그 자리
  클로저에 새 값 넘기고 자기 process 재호출, 다르면 아래 전량 철거). 계기는
  힌트가 `None`/래퍼로 오염돼 깜빡임 방지가 조용히 꺼지는 결함(사용자 제기).
  이 모델이면 **힌트 타입이 구조적으로 보장되고 깊은 체인 힌트 유실까지
  사라짐**. 내가 낸 반론("StoreBind 구독 갈아타기")과 보완안(`oldValue` 전달)은
  둘 다 사용자 지적으로 철회 — 클로저가 이미 old를 캡처하고 있음.
  **아직 `research/dispatch-redispatch-diff-plan.md`에만 있음, base 미반영.**
- **평탄화**(`state:Flatten()`)는 백로그 상세화만 — 반환 노드의 **동적
  의존성**이 최대 쟁점(`research/operator-sugar-plan.md`).
- **남은 결정 하나: Attribute 이름 소유권** — 새 모델에선 양쪽 다
  `StoreBind`라 "같은 핸들러"로 판정돼 조용히 갈아탐. 사용자가 "이전
  결정(claimant `Relate`)을 다시 가져오는 게 맞아 보이나 다음 세션에 직접
  스케치하며 심층 분석"으로 이관 — `question.md` **0-Z(최우선)**.
