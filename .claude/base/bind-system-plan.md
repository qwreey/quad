# Bind 시스템 — pluggable key/value 핸들러 (base로 승격됨)

**상태**: base — 핵심 디스패치 모델(`process`/`retract`, 핸들러 4종 계약,
Signal 미채택, Ref 역할)과 소스 트리 상 패키지 경계(디스패치 엔진은
`quad-base`가 인터페이스로 소유, `quad-roblox`는 실제 구현만)까지 전부
2026-08-04 세션에서 확정되어 `research/`에서 승격됨(`base/architecture.md`의
"구현 착수: 소스 트리 구조 확정" 절 참고). 남은 건 세부 시그니처(dependency
array API, `CreatedRef` 모양) 뿐 — 구현 단계에서 자연히 정리됨. 원본:
`.claude/initreq/raw-userinput.md`
"key와 value에 대한 바인드 연산은 pluggable 하도록 구성하기" / "스토어는 스토어를
저장 가능한가" / "Ref는 고민중" 절. v1의 문제점은 `base/quad-v1-architecture.md`
("ProcessQuadProperty" 하드코딩 디스패처), 참고 패턴은 `.claude/initreq/tbox`
(레지스트리)와 Fusion/Vide 비교는 `base/comparison-fusion-vide.md` 참고.

## 문제

v1의 `ProcessQuadProperty`(`.claude/initreq/quad/src/class.lua:134-214`)는
숫자 키(children/style) vs 문자열 키(prop/event) vs `__type` 태그 테이블
(register/linker/style)을 하드코딩된 if/elseif 체인으로 구분한다. 새 특수 키
(`[Attribute "X"]`, `[Tag ""]`, `PropertyChangedEvent ""` 등)를 추가하려면 이
중앙 함수 자체를 고쳐야 한다 — 라이브러리로서 확장 불가능한 구조.

## 핸들러 계약 (확정 — 아래 "확정된 디스패치 모델" 절과 통합해서 읽을 것)

핸들러는 다음 4개를 제공하는 등록 가능한 객체:

- `isHandlable(key, value): boolean` — 이 핸들러가 이 key/value 쌍을 처리할
  수 있는지 판별하는 predicate. **부작용 없이, 빠르게** — tbox의 type-check/
  constraint-check 분리 원칙(`.claude/initreq/tbox/CLAUDE.md`의 "타입 체크는
  분기 선택에 쓰이므로 순수해야 함")을 그대로 적용: `isHandlable`은 오직
  "이 핸들러가 맞는가" 판별에만 쓰이고, 실제 유효성 검사는 핸들러가
  선택된 *이후* 별도 단계에서.
- `priority: number` — 우선순위. 등록 순서(Fusion의 4단계 고정 stage, Vide의
  action() 우선순위)보다 일반화된 **열린 숫자 공간**으로.
- `process(inst, key, value)` — 실제 처리 수행(아래 "확정된 디스패치 모델"
  절 참고). v1/기존 논의에서 "bind"라 부르던 것과 동일한 역할.
- `retract(inst, key, value)` — 이전 처리를 무르는/멈추는 함수(아래 절,
  `base/lifecycle-pattern.md` 참고). 모든 핸들러가 의미 있게 구현할 필요는
  없음(예: 일반 프로퍼티 핸들러는 보통 no-op).

디스패치는 등록된 핸들러를 우선순위 순으로 스캔하며 `isHandlable`을 호출,
첫 매치가 처리(Fusion의 SpecialKey 우선순위 스캔과 유사하되 4단계 고정이 아니라
열린 레지스트리). tbox의 `TUnion` 런타임 체커가 이미 이 "순서대로 스캔, 첫 매치
반환, 실패 정보는 클로저로 지연 생성" 패턴을 구현해뒀음(`.claude/initreq/tbox/
src/schema/union.luau:48-68`) — 에러 메시지는 즉시 문자열로 만들지 말고 매치
실패 시에만 클로저 호출.

## 확정된 디스패치 모델: `process(inst, k, v)` / `retract(inst, k, v)`

**사용자가 직접 준 구체적인 모델 — 이 문서의 이전 초안보다 우선함.** 아래가
실제로 구현할 모양:

- 모든 핸들러는 대상 **Instance를 직접, 항상** 받는다. quad는 "인스턴스를 생성하고
  그 인스턴스를 처리하는" 라이브러리다 — 다른 라이브러리가 만든 값(예: Store)을
  그 인스턴스에 적용하도록 돕는 역할에 가깝다. 그래서 핸들러가 "나중에 생길
  대상"을 비동기로 기다릴 필요 자체가 없음(아래 Ref 절 참고 — Ref는 다른 이유로
  존재).
  - **보강(2026-08-04)**: `inst`가 항상 살아있는 엔진 객체(Roblox Instance)일
    필요는 없음 — 특정 백엔드에서 실제 엔진 객체 생성/바인딩 비용이 비싸면
    (예: 웹 DOM) 중간 표현으로 평범한 테이블을 만들고 나중에 그 테이블을
    렌더링하는 것도 가능. 이건 core(base)가 신경 쓸 일이 아니라 각 최종
    엔드포인트 백엔드(`quad-roblox`/`quad-web` 등)가 알아서 결정할 문제 —
    base 인터페이스는 "무언가를 inst로 받아 process/retract한다"는 계약만
    지키면 됨, 그 inst의 실체가 뭔지는 백엔드 재량.
- `process(inst, k, v)` — 우선순위 순으로 등록된 핸들러를 스캔, `isHandlable(k,v)`를
  만족하는 최상위 핸들러가 실제 처리를 담당.
- 예시: Tween의 store-bind 핸들러는 **`k`는 무엇이든 받고 `v`가 Store인 경우를
  잡아내는, 우선순위가 매우 높은 핸들러** — `v`가 store이면 그 값을 처리(구독)함.
  이 핸들러 안에서:
  1. 지금 이 처리가 실행되어도 되는지 라이프타임(`Connected`)을 확인 —
     확인 안 하면 이미 Destroy된 대상에 대해 처리가 실행되는 문제가 생김. GC가
     결국 정리하긴 하지만, GC 되기 전에도 store 값이 업데이트될 수 있으므로
     그 시점엔 그냥 `Connected`를 보고 무시(no-op).
  2. 처리해도 되면, 사용자가 넘긴 함수들을 거쳐 실제 값(`realv`)을 계산.
  3. **`realv`를 들고 다시 `process(inst, k, realv)`를 재귀 호출** — 이게 바로
     "store 바인드는 pluggable 바인드를 재실행하는 래핑"이라는 이 문서 이전
     초안의 결론과 일치. `realv`가 store가 아니라면 자연히 Tween의 store-bind
     핸들러 `isHandlable`을 통과 못 하고 우선순위상 다음 핸들러(일반 프로퍼티
     세터 등)로 흘러감 — 무한 재귀 걱정 없음.
- **`retract(inst, k, v)`** (이전 초안의 "cleanup", 이름 변경 근거는
  `base/lifecycle-pattern.md` 참고) — 이전 처리를 무르는/멈추는 함수. **오직
  "같은 key에 새 값이 들어와서 이전 처리를 갈아치우는" 시나리오에만 존재** —
  인스턴스/바인드 전체가 Destroy될 때는 `retract`가 호출되지 않음(`base/
  lifecycle-pattern.md`의 "quad는 라이프사이클 중간에 있지 않다" 원칙 참고).
  - 일반 프로퍼티는 애초에 "unset" 개념이 없음(`nil`로 셋하는 것도 그냥 셋
    동작) — 그래서 프로퍼티 핸들러는 보통 `retract`가 필요 없음.
  - `retract`가 실제로 의미 있는 곳: **Tag를 지운다, Attribute 엔트리 자체를
    지운다, 실행 중인 Tween을 멈춘다** 같은, "값을 새로 셋하는 것"과
    "이전 상태를 명시적으로 되돌리는 것"이 다른 케이스.
  - store bind가 새 값으로 넘어갈 때 이전 핸들러의 `retract(inst, k, v)`를
    한 번 호출해주면 됨.
- **핸들러 내부 상태 저장**: `retract`가 "이전에 생성한 것"(예: 실행 중이던
  Tween 객체)에 접근하려면 상태를 어딘가에 저장해야 함 — **`inst`를 키로 하는
  weak-keyed 테이블에 `k`별로 저장**(예: 생성된 Tween을 담아뒀다가 나중에
  멈추거나 끝냄). **base가 이걸 범용 유틸로 제공**(`base.perInstanceState(inst)`
  류, 정확한 이름/모양은 구현 단계에서 확정) — 모든 핸들러가 재사용, 각자
  WeakMap을 새로 만들지 않음. `base/lifecycle-pattern.md`의 "생명 바인드 유틸"과
  짝을 이루는 유틸.
- **다른 값 변경을 추적하는 것도 process 함수의 정상 범위**: 예를 들어 Slot
  핸들러는 자기가 감시하는 값(배열/스토어)이 바뀌면 그에 따라 child를
  갱신해야 함 — `retract` 시점엔 그 추적(구독)만 풀면 됨.

## Store 바인드는 특수 경우인가, 아니면 pluggable 바인드를 재실행하는 래핑인가

사용자 원 메모: "스토어 바인드는 특수 경우로 둘지, 아니면 다른 pluggable 바인드를
재실행하는 래핑으로 쓸지 생각해봐야함... 충분히 확장 가능하게 둘 수 있음."

**확정**: 래핑 쪽. 위 "확정된 디스패치 모델" 절 참고 — store 바인드 핸들러도
다른 핸들러와 동일한 `isHandlable`/`priority`/`process`/`retract` 계약을
따르되, `process`가 내부적으로 "실제 값이 바뀔 때마다 (원래 key, 새 value)로
`process(inst,k,realv)`를 재귀 호출"하는 식으로 구현됨. 이러면 store 값
자체가 어떤 타입이든(원시값, 인스턴스, 심지어 다른 store) 상관없이 동일한
재귀적 디스패치로 처리 가능 — 아래 "store가 store를 저장 가능한가"와 직결.

Slot이 store 바인드로 넘어오는 경우, pluggable 처리기에 `retract` 핸들러가
필요하다는 점(부모가 slot을 정리하고 다시 process하는 방식)도 이 래핑 방식과
자연스럽게 맞음 — `base/slot-plan.md` 참고.

## Store가 Store를 저장 가능한가

사용자 원 메모: "슬롯을 스토어처럼 생각 가능하다면 이건 가능하다고 봐야하는가?
아니면 아예 다른 값으로 둬야 하는가? table/number 같은 프리미티브 타입이나
ref 타입처럼 생각하는 게 맞는 거 같음 — 그걸 처리하는 플러그를 만드는 걸로."

**2026-08-04 6차 확정: 그런 경우는 없다고 본다.** 위에 적힌 "재실행 래핑으로
기계적으로는 커버 가능하다"는 제안은 메커니즘상 틀리지 않지만, 실제 설계
의도와 안 맞음 — Store는 Source에 준하는 존재로 모든 반응형 값의 "시작점"
역할만 함. 시작점은 다른 변화하는 무언가에 연결되는 것을 제공하고자 하지
않음(= Store가 다른 Store/State를 값으로 담아 자동으로 따라가게 하는 용도로
쓰지 않음). Store에서 값을 꺼내 State를 옵저빙하다가 콜백으로 다른 Store 값을
바꾸는 식의 수동 연결은 있을 수 있지만, 잘 짜인 UI에서 실사용 사례를 거의
보지 못했다는 게 사용자 판단 — 그래서 이 케이스를 위해 별도로 신경 쓰지 않음.

## Ref — 도입 확정, 단 용도는 재정의됨

**중요한 정정**: Ref는 Tween이 대상을 얻기 위해 필요한 게 아님(Tween 핸들러도
`process(inst,k,v)`처럼 항상 대상 Instance를 직접 받으므로 — 위 "확정된 디스패치
모델" 참고, `research/tween-plan.md`도 이에 맞춰 갱신됨). Ref의 진짜 용도는 다름:

- v1의 `Frame "id" {}` + `Store.GetObject(id)` 식 id 매핑은 폐기 확정
  (`base/architecture.md` 5번 항목) — "비현실적"이라는 게 이유.
- 하지만 **"라이브러리가 자기 자신이 만들어낸 instance를 나중에 다루기 편하게"**
  하는 용도로 Ref는 여전히 필요. 구체 시나리오: 기존에 다른 라이브러리로
  관리되던 instance를 당장 quad로 옮기지 않고, ref를 따서 그 안에 자식을
  `Parent`로 마운트한다든가, 점진적으로 마이그레이션한다든가, 래퍼를 만든다든가
  하는 다양한 용도.
- Store는 이미 바깥에서 옵저빙 가능한 존재라 별도 취급 불필요 — Ref는 그와
  달리 "원하는 객체 자체를 직접 얻어오는" 경로. **얻어진 뒤에 그 참조를 어디에
  저장하고 어떻게 쓰는지는 라이브러리 책임 범위 밖**(사용자 자유).
- **바인드 방법**: 특수 처리 없이, children을 배열 아이템으로 넣듯 `CreatedRef`
  같은 값을 숫자 키 슬롯에 넣는 방식(정확한 이름/시그니처는 미정, 예:
  `[1] = CreatedRef(function(inst) ... end)`) — child와 동일한 층위에서
  `process(inst,k,v)` 디스패치를 그대로 타게 함. 즉 Ref도 pluggable 핸들러
  레지스트리의 평범한 참가자.
- 코루틴 기반 "채워질 때까지 대기" 지원 여부는 여전히 미정(별도 확인 필요 없이
  구현 우선순위 낮음 — 필요성이 명확해지면 그때 추가).
- **콜백 호출 시점 확정**: 생성 직후(construction 시점)와 트리 마운트 후(Parent
  세팅 완료) 둘 다 지원 — 옵션으로 선택(`CreatedRef(fn, {phase="created"|
  "mounted"})`류, 정확한 API 이름은 구현 단계에서 확정).

## 여러 Store 값을 묶어 파생값 만들기 — `:With` + `:Compute`, 포지셔널 인자 지양

**사용자 확인 완료, 상세 방향 확정.** 후보로 검토했던 두 방식 모두 기각:

- **암묵적 자동 추적(Vide식 ambient stack)** 기각 — "함수 실행 중과 끝 사이를
  확인하고 부작용이 필요"한 방식이라 Lua에서 깔끔한 방법이 아니라고 판단.
- **명시적 디펜던시 배열 + 포지셔널 인자**(`Store.Combine({a,b}, function(av,bv)
  ...)`)도 기각 — 두 가지 이유: (1) 팩토리 함수로 store-bind 처리기를 쉽게 못
  만들어줌, (2) 여러 팩토리를 체이닝하면 인자 순서가 꼬일 수 있고, 타입 표기도
  어려워짐.

**채택 방향**: `:With(...)`로 필요한 의존성을 모으고, 그 뒤 `:Compute(function()
... end)`에서 **`with`한 값을 포지셔널 인자로 받지 않고 클로저로 직접 읽는다**
(정확히 어떤 방식으로 "직접 읽는지"는 2차 라운드에서 확정 — self/with 값 둘 다
lazy State 핸들로 통일, 아래 "Store/State/Source 온톨로지" 절의 "`:With`/
`:Compute`" 부분 참고).

## Unix 파이프에서 영감 받은 스트림 지향 — 원래 의도, 해소됨

**배경**: quad는 원래 이 파이프라인/스트림 개념에서 영감을 받아 만들어짐.
이상적으로는 store에서 한 값을 추적(track)하면 "State"가 나오고, 거기에
`compute`를 적용하면 또 다른 "State"가 나오는 식 — Unix의 `(cat a; cat b) | while
read ...`처럼, State끼리 자유롭게 합성/파이핑 가능한 것이 최종 목표. `:With`의
두 번째 인자(`b`)도 다른 `:Compute`의 결과물(State)을 그대로 받을 수 있어야
이상적.

**해소됨(2차 라운드) — 두 갈래 방식 중 실질적으로 옵션 2 방향으로 정리됨**:
당시엔 (1) Compute 체인이 자기 자신을 mutable하게 바꾸는 방식(엔지니어링 비용
낮지만 공유/합성이 깨짐) vs (2) 명시적 `State:fromState(state)`류 비-mutating
생성자(합성은 안전, 비용 미확정) 둘로 긴장이 있었으나, 실제 확정된 모델은
아래 "Store/State/Source 온톨로지" 절의 **`state(state)`로 기존 state의
결과를 받아 새 state를 만드는 조합**임 — 매번 새 State를 만든다는 점에서
옵션 2와 같은 축(비-mutating)이고, 별도 `fromState`/`Pipe` 콤비네이터 타입
없이도 `state(state)` 하나로 충분하다는 게 최종 결론(`Pipe` 후보는 폐기).
`base/architecture.md`의 "복사 구현 지양, 팩토리 함수로 대체" 원칙과 같은
축의 해법.

## Store/State/Source 온톨로지 — 핵심 메커니즘 확정 (2026-08-04 2차 라운드)

**상태**: 전파 모델/`:Compute` 인자 규칙/State 쓰기 금지/Slot 생존 확인/타입
추론(dot-access) 전부 `AskUserQuestion`으로 확인 완료. 남은 건 정확한 함수/
생성자 이름뿐(구현 단계). `base/store-semantics.md`의 "State 프리미티브는
실제로 필요하다" 정정에서 이어짐.

**핵심 온톨로지** (변경 없음):
- **Source** — 실제 값이 존재하고 변경될 수 있는 단일 지점(v1의 "값의 근원").
- **Store** — source들의 집합체. `store.a`처럼 키로 접근하면 그 source를
  감싼 **새 State**를 매번 만들어 반환(state가 store에 캐시되어 재사용되는
  게 아님 — source만 store에 귀속된 유일한 실체).
- **State** — source(또는 다른 state)의 결과를 캐싱만 하는 존재, 자기 고유의
  독립적 value 개념이 없음. `state(state)`로 기존 state의 결과를 받아 새
  state를 만들어 분기 가능 — 이게 사실상 Unix 파이프 영감의 "State끼리
  합성 가능"이라는 원래 목표를 구현하는 방식.

**전파 모델 확정: push-invalidate(신호만) / pull-recompute(`Get()` 시점에만) —
Fusion식 eager 노드·생성순 정렬은 안 만듦**

- `Source`는 값이 바뀌면 구독 중인 State들에게 **"무효화됐다"는 신호만
  쏜다** — 새 값 자체는 신호에 안 실림("state는 세터를 내보내기보다
  업데이트 됐다는 신호만 쏜다" — 사용자 확정 문구).
- 신호를 받은 State는 자기 `invalid` 플래그만 세우고, 이미 `invalid`였다면
  그 아래로 더 전파하지 않는다 — 다이아몬드 의존성에서 중복 워크를 막는
  장치(Vide가 저자 스스로 `todo.md`에 미해결로 남긴 문제의 해결책).
- 실제 재계산은 `Get()`(또는 `.value` 인덱싱)이 호출되는 시점에만 일어남 —
  "필요할 때 계산" 원칙(사용자 확정). Fusion의 `timeliness="eager"` 노드/
  생성순 정렬 장치는 만들지 않음 — quad엔 그런 다단계 즉시 재계산이 필요한
  소비자가 없다는 판단. 유일하게 "즉시 반응해야 하는" 소비자는 store-bind
  pluggable 핸들러(위 "확정된 디스패치 모델" 절)인데, 이건 무효화 신호를
  받는 즉시 자기가 알아서 `Get()`을 호출해 pull하는 방식으로 충분함 —
  State 스스로 "지금 나를 보는 eager 소비자가 있나" 같은 부기가 전혀
  필요 없음.
- `emit`은 이 무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함
  ("emit 필요 여부" 열린 질문은 이걸로 해소).

**전역 원칙으로 명문화: "관측해야 실체화된다" (2026-08-04 세션)**

위 pull-recompute 규칙을 State 하나의 재계산 메커니즘으로만 읽지 말고,
프로젝트 전역에 적용되는 원칙으로 명시함: **어떤 파생값도 `.value`/`Get()`로
직접 읽히기(관측) 전까지는 계산되지 않는다.** 이 원칙은 State 자체뿐 아니라,
State를 필드 값으로 담고 있는 다른 구조(예: `base/modifier-plan.md`의
Modifier)에도 그대로 적용됨 — Modifier의 getter가 State 필드를 읽으면 그
순간이 바로 관측이고, 그 순간 계산이 확정됨.

**주의 — 구조적 복사는 관측이 아님.** `table.clone`처럼 테이블 레퍼런스만
복사하는 연산은 안에 담긴 State 핸들을 그대로 옮길 뿐 `.value`/`Get()`을
호출하지 않으므로 관측이 아니고, 계산을 트리거하지 않음. Modifier 체이닝
메소드가 `table.clone` 후 필드를 덮어쓰는 것(위 "Immutable 값 + clone 기반
체이닝")과 이 원칙이 충돌하지 않는 이유가 바로 이것 — clone은 그저 참조
복사라 State 필드는 클론 이후에도 여전히 살아있는 lazy 핸들로 남음.

**`:With`/`:Compute` — self 인자도 lazy 핸들로 통일**

- 최초안(self 값은 포지셔널 raw 값, with한 값만 클로저로 읽음)에는 실제
  단점이 있었음 — self가 raw 값이면 `fn` 호출 전에 항상 self를 먼저
  `Get()`해야 하므로, `fn` 내부 로직이 with한 다른 값을 보고 "이 경우엔 self
  계산 자체가 필요 없다"고 판단해도 이미 늦음(예: `:With(noprint)`이고
  `noprint.value == true`면 앞단 계산을 통째로 생략하고 싶은 경우).
- **해결(사용자 확정)**: self도 raw 값이 아니라 **State 핸들 그 자체**를
  `fn`의 포지셔널 인자로 넘긴다 — `fn(self: State<T>)`, 내부에서
  `self.value`(또는 `self:Get()`)를 실제로 읽을 때만 계산이 트리거됨.
  with한 값과 동일한 lazy 원칙을 self에도 그대로 적용 — 별도
  `ComputeWithout` 변형은 불필요, `Compute` 하나로 일관.
- `.value`는 `Get()`을 감싼 읽기 전용 계산 속성(`base/lifecycle-pattern.md`의
  `Connected`와 동일한 "저장되는 필드가 아니라 계산된 속성" 패턴 재사용) —
  `:Get()`과 `.value` 둘 다 지원, `.value`가 관용적 표기.
- 예시 갱신: `store "key1":With(store "key2"):Compute(function(key1) return
  key1.value + store.key2.value end)` — `key1`은 이제 raw 숫자가 아니라
  State.

**State는 쓰기 대상이 아님 — 확정, Source는 독립 공개 프리미티브로 격상**

- `.value`는 항상 읽기 전용. 값을 쓰는 경로는 오직 Store의 `__newindex`
  (`store.key = value`, 이미 확정된 문법)뿐 — State에는 대응하는 쓰기 API가
  아예 없음. "State에 `.value = x`를 허용하면 다른 source에서 파생된
  state에 직접 쓰기가 가능해져 버린다"는 이전 우려는 이걸로 근본적으로
  해소(그런 API 자체가 없음).
- **`Source`는 Store의 내부 구현 디테일이 아니라 별도의 가벼운 공개
  프리미티브로 노출** — Store는 다수의 source를 등록/관리하는 무거운
  구조라, 값 하나만 반응형으로 다루고 싶을 때 Store를 통째로 만드는 건
  비효율이라는 게 사용자 판단("store가 source 수십 개 만드는건 비효율이니
  둘이 다른 구현이라 봐도 될듯"). `Source(initial)` 류의 독립 생성자
  (정확한 이름은 구현 단계에서 확정)가 Store와 나란히 존재.

**Slot 생존 확인 — 별도 메커니즘 아님, `canExecute` 재사용으로 확정**

- `base/store-semantics.md`에 있던 "`isInit=false`면 허용, `isInit=true`+
  생존확인 거짓이면 불허" 분기 초안은 폐기. state-invalidate 리스너
  클로저도 `base/lifecycle-pattern.md`의 "생명 바인드 유틸"(canExecute
  predicate)로 등록하면, 발화 시 `canExecute()` 하나만 확인하고 거짓이면
  그냥 no-op — `isInit` 분기라는 별도 개념 자체가 불필요(사용자 확정:
  "canExecute 하나로 통일").

**타입 추론 문제 — 확정(2026-08-04 3차 라운드)**

- `store "key"`(문자열 커링)로 `state<T>`를 오버로드 함수 타입으로 정확히
  추론하려는 시도는 포기하고, **`store.key`(dot-access)를 1급 경로로 확정**
  — Store 타입을 `{key: State<number>, other: State<string>}`류 평범한
  레코드 타입으로 지으면 일반 구조적 필드 타이핑으로 자동 해결되고, 문자열
  리터럴 narrowing 문제 자체가 안 생김. `store "key"` 문자열 커링은 동적
  키가 필요할 때 쓰는 미타입(`State<any>`) 폴백으로 격하.
- 이 패턴은 Store에만 국한되지 않고 **인스턴스 생성까지 관통하는 프로젝트
  전역 관습으로 확정**됨 — 단 이벤트는 이후 4차 라운드에서 이 관습의
  **유일한 예외**로 빠졌음(PA님 방식인 문자열 키+런타임 리플렉션으로 전환).
  아래 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절이 최신 확정 내용.

**`Pipe`(quad2-try 후보)는 폐기 확정** — 별도 `Pipe` 타입에 소유권/버전
가드를 넣어 재설계하는 대신, State 자체가 파이핑 결합체이고
`state(state)`로 분기하는 위 모델로 완전히 대체됨.

**PA님 코드와의 교차검증(2026-08-04 4차 라운드) — 둘 다 기존 확정 유지**

`.claude/initreq/artworks/EventDrivenProgramming/`(Connection/Event/
Observable/Observer)을 조사한 결과, 두 지점에서 기존 확정과 실제로 다른
선택이 나와 재검토했으나 결론은 변경 없음:

- **전파 모델**: PA님의 pub-sub은 push-invalidate가 아니라 **push-값**
  (`Event:fire(...)`가 인자를 그대로 콜백에 전달, `Observable`의 `__newindex`가
  새 값을 실어 즉시 `changed:fire(key, value)`, dirty-flag/`Get()` pull 단계
  자체가 없음). 한때 "leaf(source 하나→sink 하나, 파생 없음)는 PA님처럼
  push-값으로 단순화하고 push-invalidate/pull-recompute는 실제 `:Compute`
  파생이 있을 때만 쓰자"는 이원화를 검토했으나 **기각** — invalidate+`Get()`
  방식도 leaf에서 딱히 더 복잡하지 않고(불리언 플래그 하나 + `Get()`/`emit`
  둘로 나뉘는 정도), 오히려 두 메커니즘을 병행하면 "leaf State가 나중에
  `:Compute`로 감싸일 때 두 메커니즘을 어떻게 연결하는가"라는 새 경계 문제가
  생겨 이원화가 더 복잡함. **결정적으로, PA님 코드엔 애초에 `:Compute`/`:With`
  같은 파생·합성 개념 자체가 없음** — quad-v2가 lazy pull을 도입한 이유(여러
  소비자가 하나의 파생 State를 공유할 때 오염 방지, 안 쓰이는 연산 스킵)를
  PA님 시스템은 처음부터 안 풀려던 문제라, 대등한 반례가 아니었음. **결론:
  push-invalidate/pull-recompute로 통일 유지, 변경 없음.** 사용자 최종 확인
  문구: "store 전파 처리는 우리 방식이 맞음. 이건 vide 에서 없었던것과
  동일함, [PA님] 저기도 디자인 상 해결 못하는 문제가 된거거든. 비 필요
  연산과 중복 연산을 지우는건 디자인 단계에서 구성할 일임. 우린 디자인
  단계부터 해당 문제를 해결하고 싶었던거야."
- **라이프사이클**: PA님 코드는 GC-native가 아니라 **전부 수동 해제**
  (`Connection.connected`는 계산 속성이 아니라 저장된 bool, `Observer`의
  8개 `subscribeXxx` 헬퍼 전부 명시적 `:unsubscribe()` 필요, weak table은
  `Observable`의 subject↔observable 캐시 한 곳뿐). rbvm 기반으로 확정한
  "GC 위임, 명시적 dispose 없음" 원칙과 반대 선택이라 재확인 질문했으나,
  **GC-native 유지로 확정** — 지금까지 이 정도 규모(명시적 dispose가 꼭
  필요할 만큼 큰 자원)를 요구하는 실제 사례가 없었다는 게 사용자 판단. 다만
  **완전히 막다른 길은 아님**을 기록해둠: rbvm처럼 관계를 양쪽 다 weak-keyed로
  두고 모든 걸 connection 람다에 담아 "연결이 살아있는 동안만 살아있게" 하는
  방식이면, 나중에 GC만으로 정말 부족한 케이스가 생겨도 그 connection을 얻어
  `disconnect()`하는 명시적 dispose 경로를 추가로 얹는 게 가능한 디자인 —
  지금 마일스톤에서는 필요 없어서 안 함(사용자: "필요하다면 dispose 핸들러를
  만들어주는 것도 가능한 디자인, 다만 지금까지 요구가 없었음").

## quad2-try 리서치 결과 (완료) — 이전 시도에서 뭘 가져오고 뭘 버릴지

`.claude/initreq/quad2-try/out/quad-core`에 정확히 이 문제(Unix 파이프 영감의
State/스트림)를 다뤘던 이전 시도가 있었음. 조사 결과 요약:

**확인된 죽은 접근 — 절대 반복하지 말 것:**
- **OOP 상속(`Base:Extends`) 구조**가 `Source`/`State`/`Pipe`/`Store`/`Event`/
  `Action`+8개 서브타입 전체에 퍼져 있었음 — 모든 서브클래스 생성자마다
  `self._super._constructor(self, ...)`를 수동으로 호출해야 하고(빼먹기 쉬움,
  컴파일러가 검증 안 함), private/protected는 `_` 접두사 관례일 뿐 실제
  캡슐화가 전혀 없었으며, `Base:IsInstance`가 수동 유지되는 `_proto`/`_super`
  연결 리스트를 순회하는 런타임 전용 타입 체크라 Luau 정적 타입 시스템이
  전혀 못 봄. **사용자가 우려한 그대로 확인됨 — 상속 기반 설계 금지.**
- **`--&` 커스텀 파서 시도**는 완전히 죽은 코드였음 — 6개 파일에 156줄의
  주석 기반 타입/가시성 어노테이션이 있었지만, 이걸 실제로 소비할 도구
  (`quad-gen`, `quad-lang`)는 **둘 다 완전히 빈 디렉토리**였음. 오타(`@clsas`를
  `@class`로 못 고침)가 안 잡힌 채 남아있었고, 같은 주석 마커 아래 전혀 다른
  Lua5.1-호환 트랜스파일러 지시어까지 섞여 있었음 — 파서가 한 번도 제대로
  동작한 적 없다는 명백한 증거. **확인대로 반복 금지.**
- **Slot은 이 시도에서도 사실상 빈 스텁**이었음 — `Insert`의 실제 구현부가
  전부 주석 처리되어 있고, `Notify()`도 빈 함수. 심지어 구 v1(`quad-2`)의
  `DEV_CHANGELOG.txt`에도 "TODO: slot 기능 구현"이 마지막까지 미완료로 남아있었음
  — **가져올 게 전혀 없음**, `base/slot-plan.md`의 from-scratch 설계를
  그대로 진행하면 됨(재조사 불필요).
- 다른 서브패키지(`quad-roblox`/`quad-gtk`/`quad-lang`/`quad-gen`/`quad-compat`/
  `quad-debug`/`quad-docs`)는 전부 파일이 0개인 빈 디렉토리 — `quad-core` 밖엔
  참고할 게 없음.
- `Store:Pipe`/`Store:Value` 연동이 담긴 유일한 두 예제 콜사이트(`slot.luau:31-41`)조차
  존재하지 않는 `Store:Value` 메서드를 호출하는 등 실제로 동작 검증된 적이
  없는 죽은 스크래치 코드였음 — 이 프로토타입은 끝까지 실사용 검증을 통과한
  적이 없음.

**건질 만한 것 (인체공학/아이디어만, 코드는 아님):**
- **`store:Pipe(key):Compute(fn)` 같은 왼쪽에서 오른쪽으로 읽히는 파이프
  문법 자체**는 목표로 유지할 가치가 있음.
- **`Pipe`가 mutate-vs-`fromState` 긴장 관계에 제시했던 절충안** — "체이닝된
  `Compute`/`Add`/... 호출은 자신이 액션 리스트의 유일한 '끝(tip)'일 때만 공유
  배열에 그대로 append(뮤테이션), 이미 다른 코드가 그 지점 이후로 체인을
  확장해버렸다면 배열을 복사한 뒤 새 `Pipe` 객체를 반환"하는 **copy-on-write
  방식** — 한때는 이 문서의 "mutate-in-place vs `fromState`" 긴장을 풀어보려
  한 유일한 시도로서 다시 설계해볼 후보였으나, **아래 "종합"에서 최종적으로
  폐기됨** — `state(state)` 조합 모델이 소유권/버전 가드 없이도 같은 문제를
  더 간단히 풀어서 이 절충안 자체가 불필요해짐. 원본이 갖고 있던 진짜 결함
  (소유권/버전 관리 없이 경쟁 상황에 취약, 테스트/실사용 검증도 없었음)은
  기록으로만 남김.
- **`Depend(...)` 액션** — 계산값에는 관여하지 않고 오직 "이 소스가 바뀌면
  다시 계산하라"는 추가 의존성만 등록하는 값-투명(value-transparent) no-op
  액션. 작지만 깔끔한 아이디어라 이름 그대로 채택할 만함.
- **흥미로운 발견**: 스크래치 파일(`out/asdf`)에 남아있던 더 이전 버전의
  파이핑 스케치가 정확히 `Pipe(store.background):With(store.transparency,
  globalStore.test):Compute(fn)` 모양이었음 — 실제 구현으로 넘어가며
  `:Depend()`+포지셔널 인자로 바뀌었지만, **`:With(...)` 네이밍은 사용자가
  이번 라운드에서 다시 요청한 것과 정확히 일치** — 우연이 아니라 원래
  지향점이었던 것으로 보임, `:With` 이름 채택에 힘을 실어줌.

**종합**: 이 프로토타입은 사실상 죽은 시도가 맞음(확인됨) — `Depend`/`:With`
네이밍은 quad-v2 설계에 그대로 살려볼 가치가 있는 아이디어로 남지만, **Pipe의
copy-on-write 절충안은 2026-08-04 검증 라운드에서 사실상 폐기 쪽으로 재평가됨**
(위 "Store/State/Source 온톨로지" 절 참고 — State 자체가 파이핑 결합체이고
`state(state)`로 분기하는 쪽이 더 간단하다는 사용자의 최신 판단).

## 확정된 것 (더 이상 열린 질문 아님)

- **핸들러 계약**: `isHandlable(k,v)` + `priority` + `process`(구 `bind`) +
  `retract`(구 `cleanup`) 4종 조합으로 확정 — tbox식 6-hook 세분화는 지금은
  안 함. 실제 구현하며 부족한 지점이 보이면 그때 hook 추가(점진적 확장).
- **Signal 클래스**: 안 만듦, 콜백 + `Connected` 계산 속성만(`base/
  lifecycle-pattern.md`).
- **Ref**: 도입 확정(위 절 참고), 용도는 "id 기반 조회 대체"가 아니라 "외부
  관리 instance를 점진적으로 다루기 위한 직접 참조 획득".

## base 유틸은 인터페이스, 실제 구현은 백엔드 팩토리가 주입 (2026-08-04 보강)

`base/lifecycle-pattern.md`가 말하는 "범용 유틸"(per-instance 상태 저장소,
생명 바인드 유틸)은 base가 직접 구현하는 게 아니라 **인터페이스만 정의** —
`inst`는 base 입장에선 `any`일 수 있음(다른 엔진일 수도 있으므로). 실제
구현은 `RobloxFactory(BaseModule)` 같은 팩토리 함수가 `BaseModule`을
뮤테이션해서 그 안에 실 구현체(`canExecute` 등)를 채워넣는 방식 — 사용자는
`quad-base`/`quad-roblox`를 각각 import해서 `const quad =
RobloxFactory(QuadBase)` 세 줄 정도로 직접 조립하면 됨(별도 번들 `quad`
패키지로 재수출할 필요 없음, 필요하면 만들어도 됨).

**확정(2026-08-04 3차 라운드)**: `RobloxFactory`를 같은 `BaseModule`에 여러
번 호출했을 때 — **같은 팩토리로 재호출하면 무시(no-op)**, hot-reload처럼
초기화 스크립트가 다시 도는 경우를 안전하게 만듦. **다른 팩토리
(`AnotherFactory` 등, 가상의 예)로 재호출하면 에러** — 이건 `base/module-lifecycle-plan.md`의 "bind는 유일 슬롯" 원칙(이미 구현체가 있는데 또
다른 구현체로 init하려 하면 오류)이 다루던 것과 정확히 같은 케이스, 이
문서의 이전 "무시" 잠정안과 그 문서의 "오류" 잠정안이 서로 모순되는 게
아니라 **같은 팩토리 재호출(무시) vs 다른 팩토리로 유일 슬롯 충돌(에러)이라는
서로 다른 케이스를 각각 가리키고 있었음**. 구현은 모듈 테이블에 "누가
초기화했는지" 마커(`_initializedBy = "roblox"`류, 정확한 이름은 구현 단계)만
두면 됨. 모듈 스코핑(`New()`, `base/architecture.md` 13번)과의 관계도 실은
열려있던 게 아니라 자연히 풀림 — `New()`가 생기면 각 인스턴스가 별도
테이블이 되므로 이 마커도 테이블별로 독립적으로 스코핑됨, 재설계 불필요.

## 인스턴스 생성 / 이벤트 네이밍 인체공학 — 확정(2026-08-04 3~4차 라운드, PA님 실 코드로 검증됨)

`Quad "Frame"`처럼 문자열로 인스턴스 종류를 지정하는 방식은 타입 추론이
어려움(위 온톨로지 절의 Luau 오버로드 문제와 같은 원인). 사용자가 실제
참고 코드를 `.claude/initreq/artworks/DeclarativeProgramming/
DeclarativeInstance.luau`(PA님 작성, UI 포함 전반적 설계 패턴을 시범 적용한
데모 모듈)에 공유해줘서 직접 확인 — **"DI"는 Dependency Injection이 아니라
"Declarative Instance"(선언형 인스턴스 생성)**.

**인스턴스 생성 — PA님 코드 그대로 채택**: 처음 제안했던 "필드=1급 타입
경로, 문자열=폴백"이라는 2트랙(`DI.Frame` vs `DI.New<<Frame>> "Frame"`) 구상
보다 실제로는 더 단순했음(`DeclarativeInstance.luau:104-160`) —
**제네릭 생성자 함수 하나(`new<ClassName>(className): from<index<UIInstances,
ClassName>>`)가 알려진 타입과 모르는 타입을 전부 커버**하고, 그중 UI에서 자주
쓰는 클래스 ~25개(`Frame`/`TextButton`/`UICorner` 등, `UIInstances` 타입
테이블에 등록된 것들)만 모듈 로드 시점에 **즉시(eager)** `constructor.Frame =
new("Frame")`처럼 필드로 미리 채워둠 — `__index` 메타메소드 지연 생성이
아니라 그냥 정적 테이블. quad-v2도 이 모양 그대로 채택: 하나의 제네릭
생성자 + 자주 쓰는 것만 정적으로 미리 바인딩.

**이벤트 바인딩 — `On.EventName` 도트액세스 안 씀, PA님 방식(평범한 문자열
키 + 런타임 리플렉션)으로 전환**: `DeclarativeInstance.luau:13-91`의
`assign(instance, key, value)`가 `ReflectionService:GetPropertiesOfClass`/
`GetEventsOfClass`로 클래스별 프로퍼티/이벤트 타입을 캐싱해두고, 키가
`RBXScriptSignal` 타입이면 자동으로 `instance[key]:Connect(value)`로 처리함
— `Frame { MouseButton1Click = fn }`처럼 별도 네임스페이스 없이 그냥 문자열
키로 씀. 이건 타입 안전성을 어느 정도 포기하는 대가지만(콜백 시그니처까지
Luau가 검증 못 함 — `apply<T,U>(instance: T, properties: U): T & U`가 스키마
검증 없이 구조적으로만 merge), 이미 UB로 남긴 "테이블 리터럴 안 키별 값
타입 자동 검증 불가"와 같은 급의 한계라 손해가 크지 않고, `On.` 접두어 없이
문법이 더 간결해짐 — **사용자 확정**("PA 님 방식 괜찮은듯. 타이핑은 인라인이
되긴 하겠지 정도면 괜찮다"). quad-v2 구현에서는 이 "키가 이벤트인가"
판별을 `isHandlable`로 감싼 pluggable 핸들러(`quad-roblox`가 `Reflection
Service` 기반으로 구현)로 두면 됨 — 별도 `On` 모듈/필드 접근 구조 자체가
불필요해짐.

**Store 쪽 dot-access는 그대로 유지**: `store.key`(1급 타입 경로)/
`store "key"`(문자열 커링, 동적 키 폴백)는 이벤트와 달리 실질적으로 Luau가
타입을 좁혀주는 이득이 있어서(Store 자체가 `{key: State<number>, ...}`류
평범한 레코드 타입으로 지어짐) 그대로 유지 — 이벤트만 예외였을 뿐, "정적으로
알려진 것=필드 접근" 원칙 자체가 깨진 건 아님.

**PA님 코드와 대조해서 재확인한 것(변경 없음)**:
- **OOP 회피 결정은 오히려 보강됨** — PA님의 `ObjectOrientedProgramming/
  class.luau`도 `setmetatable(methods, {__index = parent})` 체이닝 상속이라
  quad-v2가 피하기로 한 quad2-try `Base:Extends`와 같은 모양이고, 제네릭을
  파일마다 중첩해서 재선언해야 하는 보일러플레이트까지 동일하게 나타남.
- **Instance 태그는 CollectionService 직접 사용 그대로 유지** — PA님의
  `EventDrivenProgramming/Observer.luau`의 `subscribeTaggedInstance`도 얇은
  `CollectionService` 래퍼일 뿐. `DataOrientedProgramming/TagService.luau`는
  이것과 무관하게 plain-table 엔티티(비-Instance 데이터)용 커스텀 태그
  인덱스라 지금 quad-v2 스코프 밖 — Instance가 아닌 데이터에 태깅이 필요해질
  미래 시나리오를 위한 참고 자료로만 기록.
- **Store/State 전파 모델, 라이프사이클 — 둘 다 재검토 후 기존 확정 유지**
  (위 "Store/State/Source 온톨로지" 절의 "PA님 코드와의 교차검증" 참고).

## 남은 열린 질문 (`.claude/question.md`에도 취합)

이 문서의 핵심 설계 질문은 2026-08-04 세 라운드(전파 모델/`:Compute`/State
쓰기 금지/Slot 생존 확인 → dot-access 타입 추론/인스턴스·이벤트 네이밍/
`RobloxFactory` 재호출 가드)를 거치며 전부 확정됨. 남은 건 순수 API 표면
이름뿐:

- **`state()`/`Source()`/`Get()`/`DI`(또는 다른 이름) 등 정확한 함수·생성자·
  모듈 이름** — 방향은 전부 확정, 이름만 구현 단계에서 남음(`On` 모듈은
  이벤트 바인딩이 PA님 방식으로 바뀌며 아예 불필요해짐 — 위 "인스턴스 생성 /
  이벤트 네이밍" 절 참고).
- **`CreatedRef`(가칭)의 정확한 함수/옵션 이름** — children 배열에 아이템으로
  넣는다는 방향과 생성/마운트 두 시점 모두 지원한다는 것은 확정, 정확한 API
  이름만 남음.
- **매 `process()` 호출마다 우선순위 스캔 비용** — 실제 구현/벤치마크 단계에서
  확인 필요(디자인 자체는 확정됐으므로 더 이상 사용자 확인 대상 아님, 구현
  검증 대상).

**해소된 것**: "Store가 Store를 담는 경우 이중 해제(double-dispose) 방지가
필요한가"는 재검토 결과 질문 자체가 성립 안 함으로 결론 — 두 가지 독립적인
이유로 이중 해소됨. (1) 애초에 그런 경우를 만들지 않기로 확정(위 "Store가
Store를 저장 가능한가" 절, 2026-08-04 6차 — Store는 Source에 준하는 "시작점"
이라 다른 반응형 값을 담아 자동 연결되는 용도로 안 씀). (2) 설령 발생해도
State/Source 그래프 구독이 전부 weak-keyed GC-native(명시적 `dispose()` 호출이
아예 없음, `base/lifecycle-pattern.md`의 GC 위임 원칙 재사용)라 "같은 걸 두 번
해제"할 행위 자체가 존재하지 않음(GC는 멱등). "`:Compute`가 with한 값을 어떻게
읽는가"/"emit 필요 여부"도 전파 모델 확정으로 해소, `RobloxFactory` 중복
호출/충돌 시나리오·인스턴스 생성/이벤트 네이밍도 위 절에서 전부 확정.
