# Bind 시스템 — pluggable key/value 핸들러 (핵심 모델 확정, 세부 사항만 남음)

**상태**: research — 핵심 디스패치 모델(`process`/`retract`, 핸들러 4종 계약,
Signal 미채택, Ref 역할)은 사용자 확인 완료로 사실상 확정. 남은 건 세부
시그니처(dependency array API, `CreatedRef` 모양) 뿐 — 이것들이 정리되면
`base/`로 승격 예정. 원본: `.claude/initreq/raw-userinput.md`
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
자연스럽게 맞음 — `research/slot-plan.md` 참고.

## Store가 Store를 저장 가능한가

사용자 원 메모: "슬롯을 스토어처럼 생각 가능하다면 이건 가능하다고 봐야하는가?
아니면 아예 다른 값으로 둬야 하는가? table/number 같은 프리미티브 타입이나
ref 타입처럼 생각하는 게 맞는 거 같음 — 그걸 처리하는 플러그를 만드는 걸로."

이 문서의 제안: "Store 안의 값이 Store"인 경우도 그냥 하나의 (key,value) 쌍일
뿐이고, 그 값 타입(Store)을 인식하는 핸들러가 pluggable 레지스트리에 등록되어
있으면 됨 — 위 "재실행 래핑" 방식과 동일한 메커니즘으로 커버됨. 별도 특수
케이스 코드 불필요.

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
(정확히 어떤 방식으로 "직접 읽는지"는 아래 열린 질문 — `:fromState` 후보 참고).

## Unix 파이프에서 영감 받은 스트림 지향 — 원래 의도, 기술적 난이도 미확정

**중요한 배경**: quad는 원래 이 파이프라인/스트림 개념에서 영감을 받아 만들어짐.
이상적으로는 store에서 한 값을 추적(track)하면 "State"가 나오고, 거기에
`compute`를 적용하면 또 다른 "State"가 나오는 식 — Unix의 `(cat a; cat b) | while
read ...`처럼, State끼리 자유롭게 합성/파이핑 가능한 것이 최종 목표. `:With`의
두 번째 인자(`b`)도 다른 `:Compute`의 결과물(State)을 그대로 받을 수 있어야
이상적.

**미해결 긴장 관계**: 이걸 구현하는 두 갈래 방식이 있고 어느 쪽이 맞는지 아직
결정 안 됨:
1. **Compute 체인이 항상 자기 자신을 mutable하게 바꾼다** — 엔지니어링 비용은
   낮지만, 다른 코드가 나중에 그 체인 뒤에 새 compute를 붙이는(다른 소비자가
   동일 State에 독립적으로 파생값을 추가하는) 것이 불가능해짐 — 공유/합성이
   깨짐.
2. **명시적 `State:fromState(state)`류의 비-mutating 생성자** — 합성은
   안전해지지만 엔지니어링 비용이 더 큼(정확히 얼마나 큰지 미확정).

이건 `base/architecture.md`의 "복사 구현 지양, 팩토리 함수로 대체" 원칙과
같은 축의 문제 — 옵션 2가 그 원칙과 더 잘 맞아 보이지만, 실현 가능성 자체가
아직 검증 안 됨.

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
  — **가져올 게 전혀 없음**, `research/slot-plan.md`의 from-scratch 설계를
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
- **`Pipe`가 mutate-vs-`fromState` 긴장 관계에 제시한 절충안** — "체이닝된
  `Compute`/`Add`/... 호출은 자신이 액션 리스트의 유일한 '끝(tip)'일 때만 공유
  배열에 그대로 append(뮤테이션), 이미 다른 코드가 그 지점 이후로 체인을
  확장해버렸다면 배열을 복사한 뒤 새 `Pipe` 객체를 반환"하는 **copy-on-write
  방식** — 이건 이 문서의 "mutate-in-place vs `fromState`" 긴장을 실제로
  풀어보려 한 유일한 시도라 **quad-v2에서 제대로 다시 설계해볼 만한 후보**.
  단, 원본은 "내가 지금 유일한 tip인가" 체크에 소유권/버전 관리가 전혀 없어서
  경쟁 상황에 취약했고 테스트/실사용 검증도 없었음 — **그대로 베끼지 말고,
  같은 아이디어를 소유권 가드를 제대로 넣어 재설계할 것.**
- **`Depend(...)` 액션** — 계산값에는 관여하지 않고 오직 "이 소스가 바뀌면
  다시 계산하라"는 추가 의존성만 등록하는 값-투명(value-transparent) no-op
  액션. 작지만 깔끔한 아이디어라 이름 그대로 채택할 만함.
- **흥미로운 발견**: 스크래치 파일(`out/asdf`)에 남아있던 더 이전 버전의
  파이핑 스케치가 정확히 `Pipe(store.background):With(store.transparency,
  globalStore.test):Compute(fn)` 모양이었음 — 실제 구현으로 넘어가며
  `:Depend()`+포지셔널 인자로 바뀌었지만, **`:With(...)` 네이밍은 사용자가
  이번 라운드에서 다시 요청한 것과 정확히 일치** — 우연이 아니라 원래
  지향점이었던 것으로 보임, `:With` 이름 채택에 힘을 실어줌.

**종합**: 이 프로토타입은 사실상 죽은 시도가 맞음(확인됨) — 다만 Pipe의
copy-on-write 절충안과 `Depend`/`:With` 네이밍은 quad-v2 설계에 그대로
살려볼 가치가 있는 아이디어로 남김.

## 확정된 것 (더 이상 열린 질문 아님)

- **핸들러 계약**: `isHandlable(k,v)` + `priority` + `process`(구 `bind`) +
  `retract`(구 `cleanup`) 4종 조합으로 확정 — tbox식 6-hook 세분화는 지금은
  안 함. 실제 구현하며 부족한 지점이 보이면 그때 hook 추가(점진적 확장).
- **Signal 클래스**: 안 만듦, 콜백 + `Connected` 계산 속성만(`base/
  lifecycle-pattern.md`).
- **Ref**: 도입 확정(위 절 참고), 용도는 "id 기반 조회 대체"가 아니라 "외부
  관리 instance를 점진적으로 다루기 위한 직접 참조 획득".

## 남은 열린 질문 (`.claude/question.md`에도 취합)

- **`:Compute`가 `with`한 값을 정확히 어떻게 읽는가** — 클로저로 원본 store/
  register를 직접 캡처하는 것인지, `:Compute`가 특수한 접근자를 몸체 함수에
  넘겨주는 것인지 구체 시그니처 미정.
- **mutate-in-place vs `fromState` 긴장 관계** — quad2-try의 copy-on-write
  절충안(위 절)이 유력한 후보로 좁혀짐. 실제 구현 시 "내가 유일한 tip인가"
  판단에 제대로 된 소유권/버전 가드를 설계하는 게 핵심 과제 — 원본처럼
  가드 없이 가면 안 됨.
- **`CreatedRef`(가칭)의 정확한 함수/옵션 이름** — children 배열에 아이템으로
  넣는다는 방향과 생성/마운트 두 시점 모두 지원한다는 것은 확정, 정확한 API
  이름만 남음.
- **매 `process()` 호출마다 우선순위 스캔 비용** — 실제 구현/벤치마크 단계에서
  확인 필요(디자인 자체는 확정됐으므로 더 이상 사용자 확인 대상 아님, 구현
  검증 대상).
- Store가 Store를 담는 경우의 실제 소유권(누가 내부 Store를 destroy하는가) —
  이 문서의 "재실행 래핑" 제안이 맞다면 자연히 바깥 Store bind가 내부 Store의
  라이프타임도 감싸게 될 텐데, 이중 해제(double-dispose) 방지가 필요한지 확인.
  단, `base/lifecycle-pattern.md`의 "destroy 시점엔 아무것도 안 함" 원칙상 이중
  해제 자체가 걱정할 필요 없는 개념일 수도 있음 — 재검토 필요.
