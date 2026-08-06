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
- **일반적인 무한루프 방어(사이클 감지 등)는 하지 않기로 확정(2026-08-04,
  로드맵 인수인계 라운드)**: 우선순위 스캔+재귀 `process` 구조 자체는 핸들러가
  규율을 안 지키면(예: 값을 좁히지/변형하지 않고 같은 값을 그대로 다시
  `process`에 넘김) 무한루프에 빠질 수 있음 — 하지만 이건 base가 방어 로직을
  둬야 할 문제가 아니라 오작동하는 handler/provider(`quad-roblox` 등) 쪽
  버그로 간주 — **사용자 확정**("입력된 값이 다시 입력되면 무한루프
  빠지겠지만, 그건 막기 힘들고 유저가 내기도 힘들어. 아예 quad-roblox나
  프로바이더가 잘못 짠 코드일테니까"). Tween의 store-bind 재귀 케이스(위
  78-79행)처럼 자연히 좁혀지는 경우가 일반적이고, 일반 사용자가 만들어낼 수
  있는 상황이 아니라고 판단해 별도 가드 없이 진행.

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
- **왜 값이 아니라 콜백인가**: quad는 React처럼 렌더 함수가 계속
  재실행되지 않음(플레인 함수를 한 번 호출해 트리를 만들고 끝) — 그래서
  "채워졌는지 매 렌더마다 다시 확인"하는 모델 자체가 없고, `useEffect`
  의존성 배열 같은 것도 없음. 즉 값이 채워지는 시점을 외부에서 알아낼
  방법이 콜백(또는 폴링, 채택 안 함 — `lifecycle-pattern.md`에서 폴링
  방식은 이미 기각된 패턴) 말고 없음. 값 자체를 나중에 다루고 싶으면
  콜백 안에서 원하는 곳(외부 변수, `self._button` 같은 필드, Store 등)에
  직접 대입해 캡쳐하면 됨 — `component-composition-plan.md` 31행 예제
  참고. 즉 "값으로도 얻어진다"는 요구는 별도 API가 아니라 콜백이 이미
  충족함.

### Ref 일반화 — 엔진 instance 전용이 아니라 범용 값 박스 (2026-08-06 후속 세션)

**결정**: Ref는 "quad가 만든 instance를 얻는 통로"로 좁게 남지 않고,
**아무 사용자 값이나 담을 수 있는 범용 "채워지길 기다리는 값 박스"**로
확장한다. 위 "코루틴 기반 대기 지원 여부는 미정"이었던 항목은 이걸로
해소됨(더 이상 열린 질문 아님).

- **object-ref/function-ref로 나누지 않음.** React의 `useRef`가 DOM
  노드든 임의의 사용자 값이든(함수 포함, `ref.current?.()`로 호출하는
  imperative-handle 패턴 포함) 같은 API로 다루는 것과 동일한 선례 —
  두 개념으로 쪼개면 사용자가 "이번엔 어느 쪽을 써야 하나" 매번
  판단해야 해서 나쁨. 엔진 instance도 그냥 "사용자 값의 한 종류"일 뿐.
- **구체 유스케이스**: 자식 컴포넌트가 비싸고 온디맨드로만 필요한 계산
  (예: 클릭 위치 기준 컨텍스트 메뉴를 그리기 위한 clip bounds 계산)을
  부모에 노출하고 싶을 때, 매 변경마다 push하는 대신 부모가 필요할 때만
  `ref.Value?.()`처럼 호출하는 함수를 Ref에 담아 넘기는 패턴 — React의
  imperative handle과 동일한 이유(비싼 연산이라 온디맨드가 맞음, 값이
  최신인지 아닌지도 애매해짐).
- **API 모양**: `.Value`(get/set) + `:Wait()`(coroutine 컨텍스트에서
  사용 — 렌더 함수 바디 안에서 `return` 위에 바로 못 씀, 그래서 콜백도
  같이 필요) + 콜백 등록(복수 허용, 이미 채워져 있으면 등록 즉시 그
  값으로 1회 호출 — nil/미설정 상태여도 그 상태 그대로 호출. React의
  `useEffect`가 매번 `.current` 존재 여부부터 체크하는 것과 같은 이유,
  Ref가 자식으로 전달되는 경우 채워지는 시점이 더 늦어질 수 있어서
  "이미 채워졌는지" 확인이 항상 필요함). `:Wait()`의 대기자 리스트와
  콜백 리스트는 같은 구조 재사용 가능(발화 후 해당 인덱스만 nil 처리,
  Luau의 일반화 for는 성긴 배열도 잘 순회함).
- **`CreatedRef`와의 관계**: 둘은 상충하지 않음 — 이 절의 Ref가 범용
  프리미티브, `CreatedRef(fn, {phase=...})`는 그 위에 얹힌 "children
  배열에 넣으면 dispatch가 자동으로 채워주는" 특수 편의 패턴(quad가
  만든 instance에 한정된 경우).
- **해소됨 — 반복 재설정 가능(one-shot 아님), 사용자 확정.** React에서도
  자식이 재생성되는 경우 같은 방식(ref가 다시 채워짐)을 씀 — 예: 마우스
  호버/무브 시 `current` 확인 후 라벨 위치를 결정하는 라벨 컨테이너
  하나를 두고 라벨 내용만 스왑해가며 Ref를 재사용하는 패턴. 이런 고급
  패턴은 조심할 게 많지만 그건 라이브러리가 아니라 사용자가 신경 쓸
  몫. **따라서 콜백은 "발화 후 소진"이 아니라 매 `:Set()`마다 다시
  불림** — 소진되는 건 `:Wait()`가 만드는 개별 대기자(coroutine 재개는
  본질적으로 1회성)뿐, 콜백 리스트 자체는 유지됨.
- **⚠️ Ref는 의도적으로 lazy가 아니고 `:Compute` 파생을 지원하지 않음
  — State와의 이 차이가 중요함.** (예전엔 Store가 Ref와 비슷한 것도
  겸해서 지원한 적이 있었는데, State의 lazy 재계산 모델과 Ref의 즉시
  get/set 모델이 섞여서 좋지 않았음 — 그 경험에서 나온 의도적 분리.)
  Ref는 그냥 "지금 뭐가 들어있나/누가 채워주길 기다리나"만 다루는 즉시
  값 박스이고, 파생값이 필요하면 Store/State(`:With`+`:Compute`)를 쓸 것
  — 둘을 섞으려 하지 말 것.
- **용어 정리 합류 대상**: Ref의 정의 자체가 "instance를 얻는 것"에서
  "범용 값 박스"로 넓어졌으므로, 진행 중인 용어 정리(`question.md` 1번)
  때 이름이 여전히 맞는지 같이 재검토할 것.

## 이벤트 핸들러는 self(Instance)를 받지 않는다 — 확정 (2026-08-06)

**결정**: v1의 `function(self, ...)` 관습(`self`/`this`로 이벤트 대상
Instance를 넘겨주는 것, `.claude/base/quad-v1-architecture.md` 참고 —
실제로 `event.lua`의 `Bind`가 `func(self or this, ...)`로 넘겨줌)은
**채택하지 않는다.** quad-roblox의 이벤트 핸들러는 엔진이 네이티브로
주는 이벤트 인자만 받는다(React의 `onXxx`가 DOM 노드가 아니라
SyntheticEvent만 주는 것과 같은 모양).

**근거**:
1. **Ref가 이미 이 자리를 채움.** "생성 직후/마운트 후 ref 채우기"가 되는
   순간 Instance 접근이 필요하면 클로저 캡처로 해결됨(위 Ref 절) — self는
   그와 중복되는 두 번째 채널일 뿐이고, 두 채널이 있으면 "어느 쪽이
   authoritative냐"는 질문이 항상 따라붙음.
2. **thin wrapper를 제공하면 엔지니어링 구조 자체가 바뀜.** self로 얻는
   값이 mutable한 재바인드 가능 wrapper라면, 그건 Modifier의 정적
   flatten(`base/modifier-plan.md`)과 항상 경쟁하는 두 번째 쓰기 경로가
   생긴다는 뜻 — flatten된 뒤엔 wrapper 쪽에서 "이전 modifier가 뭐였는지"
   재구성할 방법이 없음. Modifier 핸들러가 KV 매치 기반이라는 걸 감안하면,
   wrapper 값을 처리하려면 핸들러가 "이게 flatten된 정적 값이냐, 아니면
   언제든 바뀔 수 있는 wrapper냐"를 매번 분기해야 함 — 오버엔지니어링이고
   hot path(매 `process` 호출)에 분기 비용이 붙음. 반대로 raw Instance를
   그대로 주는 선택지도 있지만, 그러면 quad가 스스로 지양하는 "quad가
   모르는 직접 mutate 경로"를 공식 API로 만들어주는 셈이라 (3)과 충돌.
3. **디버깅 관점에서 더 결정적.** quad-debug의 가치 제안이 "무엇이
   무엇에 연결됐는가"를 선언된 반응형 그래프로 추적하는 것인데
   (`research/debug-tooling-plan.md`), self로 얻은 Instance를 이벤트
   핸들러 안에서 직접 mutate하는 경로는 그 그래프 밖 — `base/
   purity-and-effects-plan.md`의 "재사용 가능한 컴포넌트는 store만
   파라미터로 받아야 한다"는 이식성 원칙과도 같은 결.
4. **성능/GC**: self를 넘겨주려면 원본 콜백을 클로저로 한 번 더 감싸야
   함(`event:Connect(function(...) func(self, ...) end)`) — Connect마다
   불필요한 클로저 할당 비용이 들고, 최적화에도 GC 흐름에도 좋을 게
   없음. self가 없으면 사용자가 준 함수를 그대로 `:Connect`에 넘기면
   충분함. quad는 어차피 라이프사이클 끝까지 바인딩을 들고 있으므로
   (`base/lifecycle-pattern.md`, rbvm 선례 — GC-native), Destroy되면
   해당 Connection도 자연히 같이 정리됨 — 별도 Disconnect 관리가 애초에
   불필요. **[정정, 2026-08-06 후속 세션] 동적으로 Connect/Disconnect를
   반복하고 싶은 케이스는 Ref로 수동 처리하는 대신 store-bind로 네이티브
   지원하기로 확정** — 아래 "이벤트도 store-bind 가능 — `false`로
   disconnect" 절 참고. 엔지니어링 비용이 예상보다 훨씬 낮다는 게 나중에
   확인됨(기존 store-bind 재실행 래핑을 그대로 재사용, 새 디스패치
   메커니즘 불필요).

**일반화**: 이 논거의 핵심은 Roblox에 국한되지 않는 원칙으로 정리됨 —
"엔진이 네이티브로 콜백에 뭘 주든, quad는 그걸 감싸지 않고 그대로
호출해줘도 무방하다"는 것. 다만 이벤트 등록 자체가 quad-roblox에만
있는 개념이라(다른 백엔드는 이벤트 모델이 다를 수 있음) 이건 base
문서가 아니라 quad-roblox 로컬 결정 — 다른 백엔드 구현체를 만들 때
참고할 만한 템플릿 정도로만 취급.

## 이벤트도 store-bind 가능 — `false`로 disconnect (2026-08-06 후속 세션)

**결정**: 이벤트 핸들러 값으로 State를 넘기는 것(reactive하게 콜백을
바꿔치기/해제하는 것)을 지원한다. quad-roblox 로컬 결정, base 변경 없음.

**엔지니어링 비용이 낮은 이유**: 이미 확정된 "Store 바인드는 pluggable
바인드를 재실행하는 래핑"(위 절, `process`가 값이 바뀔 때마다
`process(inst,k,realv)`를 재귀 호출) + "재실행 래핑이 `retract`도 같이
호출한다"(Slot이 이미 이 조합을 씀, 같은 절)는 두 메커니즘이 이미 있음.
이벤트 핸들러가 할 일은 딱 하나: `process`에서 `:Connect()`한 Connection을
per-instance 저장소에 기억해두고, `retract`에서 그걸 `:Disconnect()`하는
것 — 새 디스패치 메커니즘 발명 필요 없이 기존 4종 계약(`isHandlable`/
`priority`/`process`/`retract`)만 제대로 구현하면 됨.

**`false`로 disconnect, `nil` 아님.** `nil`은 Lua 테이블에서 "키가 아예
없음"과 구별이 안 됨(`pairs`에서도 안 보임) — "명시적으로 꺼짐"이라는
신호를 값으로 전달하기엔 부적합. 대신 `false`(Luau에서 실재하는 싱글톤
타입)를 "연결 없음" 센티널로 씀: `process(inst,k,false)`가 들어오면
`retract`가 하던 일(기존 Connection 해제)만 하고 새로 Connect 안 함.
이벤트인지 여부는 값이 아니라 키(리플렉션으로 판별)로 결정되므로, 다른
boolean 프로퍼티 핸들러와 `(k, false)` 매칭이 겹칠 위험 없음.

**quad가 미는 기본 패턴은 아님 — 부차적 옵션.** 저빈도 UI 이벤트(클릭류)를
조건부로 켜고 끄고 싶은 흔한 케이스는 사실 이 메커니즘 없이도 됨 — 핸들러
하나를 계속 연결해두고 안에서 분기하면 끝:

```lua
MouseButton1Click = function()
    if not store.enabled:Get() then return end
    ...
end
```

이 "핸들러 하나 + 내부 분기" 패턴이 Connect/Disconnect 자체가 없어서 더
싸고, Roblox/React 어디서든 이미 익숙한 관용구라 **기본 권장 패턴**.
store-bind 방식이 실제로 값어치 있는 지점은 고빈도 신호(Heartbeat/
RenderStepped/마우스 무브처럼 안 쓸 때 Connection을 살려두는 것 자체가
낭비인 경우)나, 단순 on/off가 아니라 로직 자체가 바뀌는 드문 케이스.
자주 재계산되는 State에 이벤트를 직접 물리면 매 재계산마다 Disconnect+
Connect가 도는 숨은 churn 비용도 있음(Store Set은 dedup 안 함,
`store-semantics.md`) — 그래서 남용하지 말라는 캐비엇.

**그래도 일관성 있게 지원은 해둠.** "저빈도엔 필요 없다"가 "그러니 예외로
빼고 못 하게 막자"로 이어질 이유는 없음 — 프로퍼티/태그/어트리뷰트가
전부 store-bind되는데 이벤트만 특별 취급해서 뺄 근거가 약하고, 구현
비용도 낮으니(위 "엔지니어링 비용이 낮은 이유" 참고) 일관되게 지원해두는
쪽을 택함. 그냥 "이런 것도 가능하다" 정도로 존재하고, quad가 이 패턴을
적극 권장하진 않는다는 톤으로 문서화(`research/documentation-plan.md`
3번 "권장 이벤트 핸들링 패턴" 문서에 이 대조까지 반영 예정).

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

### `:Compute(fn)`의 선택적 두 번째 인자 — `previous` (무거운 파생 객체 재사용, 2026-08-06)

**배경**: `:Compute`의 결과가 그 자체로 무겁고 재생성 비용이 큰 엔진
객체일 수 있음(예: 큰 로케일 테이블을 Roblox `LocalizationTable`
Instance로 변환하는 경우 — `LocalizationTable`은 `Set`/`Get`/`List`로
부분 갱신 가능한 userdata). 매번 새로 만들지 않고 이전 결과를 그대로
재사용해 필드만 patch하고 싶을 때를 위해, `fn(value, previous)` 형태로
**직전에 이 Compute 함수가 반환했던 값**을 두 번째 인자로 받을 수 있게
한다.

- **opt-in**: 안 쓰는 Compute 함수는 두 번째 인자를 그냥 무시하면 됨 —
  비용 0. 대부분의 Compute는 이걸 쓸 필요 없음.
- **`previous`는 "바로 직전 버전"이 보장되지 않음.** lazy pull 모델이라
  중간에 여러 번 무효화됐어도 실제로 관측(`Get()`) 안 됐으면 재계산
  자체가 안 일어남 — 그래서 `previous`는 몇 세대 전 값인지 알 수 없음.
  **따라서 `previous`를 다루는 로직은 반드시 "현재 입력 전체 대 이전
  결과 전체"의 full diff여야 하고, "정확히 한 단계 전"이라고 가정하는
  incremental delta 로직을 짜면 안 됨.** 이건 React 자체의 reconciler가
  하는 것과 같은 모양(old tree/new tree 전체 비교 후 실제 host 객체에
  패치 적용)이라 새로 발명하는 패턴은 아님.
- 최종 소비처가 patch된 값을 다시 한번 Set/Parent하게 되는 경우가
  있어도(레퍼런스는 같은데 다시 대입) 대체로 치명적이지 않음(Roblox
  프로퍼티 재대입은 저렴/멱등인 경우가 대부분) — 문서화만 해두면 충분.

**⚠️ 이 패턴을 쓸 때 반드시 같이 지켜야 하는 것 — "확정(관측)되기 전엔
연산이 없다".** `previous`를 mutate하는 로직은 Compute 함수 **본문
안**에 있으므로, 그 함수가 재실행되지 않으면(=아무도 다시 `Get()`하지
않으면) mutation 코드 자체가 아예 실행되지 않는다 — 단순히 "가끔
stale하다" 수준이 아니라 **영영 갱신이 안 일어날 수 있음**. 이 패턴으로
만든 State는 반드시 다음 중 하나로 계속 능동적으로 관측되어야 함:
1. quad의 정상적인 선언적 prop 바인딩 경로(`[Property "X"] = someState`
   류)에 실제로 물려있어서, dispatch 엔진이 무효화 시 자동으로
   재`Get()`하게 되어 있거나,
2. 아래 "Observer" 절의 `state:Observer(fn)` + 콜백 안에서 명시적
   `Get()` 호출 + 그 결과를 children 배열에 넣어 라이프사이클에
   묶어두기.
"Ref로 한 번 얻어서 수동으로 Parent만 하고 끝"처럼 능동적 관측 경로가
안 남아있으면, 이 최적화는 그냥 조용히 작동을 멈춘다.

### `state:Observer(fn)` — 값을 안 실어주는 구독, children 배열에 직접 놓는 leaf 값

**결정(2026-08-06 후속 세션, 사용자 확정)**: 별도 `ObserverHolder`
래퍼 타입은 안 만듦 — `state:Observer(fn)`가 반환하는 값 자체가 이미
"children 배열에 바로 놓을 수 있는 leaf 값"이라 감쌀 필요가 없음.
`CreatedRef`와 완전히 같은 층위. **자유 함수 `Observer(state, fn)`가
아니라 메소드 `state:Observer(fn)`로 확정** — `state`가 항상 필요한
필수 인자라 `:` 리시버 자리에 자연스럽게 들어가고(다른 형태면 인자
두 개짜리 자유 함수가 되어 읽는 순서가 어색해짐), `architecture.md`의
"함수지향 디폴트, `:` 체이닝은 예외적으로만(체이닝이 정말 편한 경우만)"
원칙이 정확히 이 경우를 가리킴 — Store 값 변경 체이닝과 같은 예외
카테고리. **더 근본적인 이유**: `base/store-semantics.md`의 "독립 존재
가능한 프리미티브 vs 원천에 종속된 파생 데이터" 원칙 참고 — Observer는
State처럼 원천 없이는 존재할 수 없는 파생 데이터라, 애초에 "타입
이름을 부르는 자유 함수 생성자" 카테고리에 안 속함(Source/Ref/Store/
Modifier와는 다른 부류).

```lua
local observer = state:Observer(function()
    state.value
end)

Frame {
    observer,
}
```

이러면 `observer`는 `Frame`이 살아있는 동안만 유지되고, `Frame`이
retract/Destroy되면 자동으로 정리됨.

- **값을 안 실어줌 — 반드시 `Get()`을 다시 해야 함.** 기존 "emit은
  무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함" 원칙(아래
  "Store/State/Source 온톨로지" 절)이 그대로 적용됨: `fn`은 "뭔가
  바뀌었으니 다시 확인하라"는 신호만 받고 새 값 자체는 안 받음 —
  위 예시처럼 `fn` 본문에서 `state.value`/`Get()`을 명시적으로 다시
  읽어야 함. 자동으로 안 해주는 이유: 재계산이 진짜 필요한지가 다른
  `:With`한 값에 따라 갈리는 경우가 있어서(위 "포지셔널 인자 지양" 절의
  `noprint` 예시처럼 계산 자체를 통째로 생략하고 싶을 수 있음) — `Get()`
  호출 여부를 작성자가 직접 결정하게 열어둔 것.
- **base가 제공하는 것은 `isObserver`류 타입 판별자 하나** — children
  배열 dispatch가 숫자 슬롯 값을 훑을 때 "이게 Observer인가"를 판별해
  `CreatedRef`와 같은 방식으로 라이프사이클에 묶어주는 것 말고는 base가
  더 해줄 일이 없음. 새 dispatch 메커니즘이 아니라 기존 children-array
  참가자 패턴의 반복.
- **콜백 실행은 기존 `canExecute` predicate로 게이팅**(Slot 생존 확인과
  동일한 재사용 — "canExecute 하나로 통일" 원칙, 새 메커니즘 발명 아님)
  — 발화 시점과 처리 시점 사이에 owning leaf가 이미 죽었으면 no-op.
- **구현 노트(사용자 제안, 확정된 아키텍처는 아니고 구현 시 참고)**:
  살아있는 Observer 집합을 Observer 값 내부 필드로 안 두고, 외부에
  weak table(`{[observer] = true}`, `__mode = "k"`)로 인덱싱하는 방식을
  선호 — 포인터 해싱 비용만 들고 값 자체엔 부작용 없음. rbvm의
  `getNamespaceOf`류가 비슷한 외부 weak-table 인덱싱을 씀
  (`base/lifecycle-pattern.md` 참고).
- **인자 없는 `state:Observer()` — "항상 관측" 유틸.** `fn`을 생략하면
  내부적으로 no-op 콜백을 쓰는 것으로 취급해, 그냥 "이 State를 계속
  능동적으로 관측 상태로 유지"하는 용도로만 씀. 위 "`previous` 인자"
  절의 캐비엇("능동적 관측 경로가 안 남아있으면 mutate 로직이 조용히
  멈춘다")을 만족시키는 가장 단순한 도구 — 별도 콜백 로직 없이 그냥
  이 State가 계속 재계산되게만 강제하고 싶을 때 씀. 문서화만 확실히
  하면 별문제 없음(사용자 판단).

### `:Subscribe()`/`:Unsubscribe()` — 리프에 안 붙는 "전역/독립" Observer용 (2026-08-06 후속 세션)

**문제**: children 배열에 넣는 자동 라이프사이클 바인딩은 Observer가
"어딘가 leaf에 붙어있다"는 걸 전제함. 근데 흔한 실사용 패턴 하나가 이
전제를 깨뜨림 — 개발자가 디버깅용으로 `RunService:IsStudio()` 가드
안에서 Store에 직접 Observer를 걸어 `print`하는 패턴(원하면 BooleanValue
로 부분부분 켰다 껐다 하기도 함). 이건 다크패턴이 아니라 오히려 방어적인
엔지니어링이고, 붙일 leaf 자체가 없는 "전역/독립" 사용이라 위 weak-table
기반 자동 추적이 적용 안 됨.

**해결**: 명시적 `:Subscribe()`/`:Unsubscribe()`를 추가로 지원. 이건 새
설계가 아니라 `bind-system-plan.md`의 PA님 코드 교차검증(라이프사이클
절)에서 이미 예고해둔 확장 지점을 실제로 채우는 것 — "나중에 GC만으로
정말 부족한 케이스가 생기면 명시적 dispose 경로를 추가로 얹는 게 가능한
디자인"이라고 그때 이미 못박아뒀음.

- **`local` 변수로 참조만 들고 있는 것으로는 부족한 이유**: 토글(BooleanValue로
  로깅 껐다 켰다) 케이스에서, 참조를 끊어도 실제 GC는 결정론적으로 즉시
  일어나지 않음 — "껐다"고 생각한 뒤에도 한동안 계속 발화할 수 있음.
  `:Unsubscribe()`는 즉시/결정론적으로 끊는 경로라 이 문제가 없음.
- **liveness 체크는 필드 우선, weak table은 폴백**(사용자 제안): 외부
  weak table 조회보다 리터럴 필드 접근이 더 쌈(Luau가 문자열 키 접근을
  미리 해시해둠) —
  ```lua
  if self.Subscribed then return true end
  if self.Connection then return self.Connection.Connected end
  ```
  자동(리프 부착)/수동(구독) 두 라이프사이클 경로를 하나의 `canExecute`류
  predicate로 OR 묶는 자연스러운 형태. 실측은 구현 단계에서 확인.
- **내부 강참조 레지스트리**: `SubscribedObservers: {[observer]: true}`류를
  **weak 아닌 강참조**로 둠 — 여기서 weak면 "구독해서 살려둔다"는 목적
  자체가 무의미해짐. 위 자동 케이스의 weak table과 역할이 명확히 갈림
  (weak table=자동/리프 전용, 강참조 레지스트리=수동 구독 전용).
  **`:Unsubscribe()`는 이 레지스트리에서 반드시 `SubscribedObservers[observer]
  = nil`까지 해야 함** — `Subscribed` 플래그만 내리고 강참조를 안 끊으면
  GC 대상이 안 되는 반쪽짜리 해제가 됨, 둘은 항상 같이 일어나는 한 세트.
- **`:Subscribe()`/`:Unsubscribe()` 둘 다 idempotent** — 이미 구독 중인데
  또 Subscribe해도, 구독 안 했는데 Unsubscribe해도 에러 안 나고 그냥
  no-op. 토글 로직 짤 때 상태 추적 부담을 줄여줌.
- **`:Unsubscribe()`는 자동(리프) 케이스에도 동일하게 씀** — Instance가
  파괴되기 전에 수동으로 조기 해제하고 싶을 때도 같은 메소드 하나로
  충분, 별도 API 안 만듦.
- **`state:Observer(fn):Subscribe()`처럼 참조를 아무 데도 안 담아도 정상**
  — 강참조 레지스트리 자체가 생존을 보장하는 유일한 근거라, 로컬 변수에
  담아둘 필요가 없음. 예외 없이 그냥 계속 돎(그게 이 메커니즘의 핵심
  포인트).
- **`:Subscribe()`/`:Unsubscribe()` 둘 다 `self`를 리턴(대칭)** —
  `local obs = state:Observer(fn):Subscribe()`처럼 "구독 시작 + 나중에
  끊을 핸들 확보"가 한 줄로 되고, `table.insert(subs, state:Observer(fn)
  :Subscribe())`처럼 리스트에 담을 때도 줄바꿈 없이 됨. Observer가
  immutable 값이 아니라 원래 mutable한 구독 핸들이라 fluent 체이닝이
  자연스러움 — Modifier의 clone-then-return 체이닝과는 다른 이유(같은
  객체를 mutate하고 그대로 돌려주는 것)지만 표면 문법은 비슷하게
  체이닝 가능.

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
- **생성자 스타일 확정(2026-08-06 후속 세션): Kotlin Compose식 "타입
  이름 자체를 팩토리 함수로" — `Source(default)`, `Ref(default)`,
  `Store({defaults})`.** Ref도 예외 없이 이 스타일을 따름 — Ref가
  `Ref()`로 안 만들어질 특별한 이유는 없었고(이전 절에서 API 모양만
  다루고 생성자를 명시 안 해서 생긴 공백), `architecture.md`의 "복사
  구현 지양, 팩토리 함수로 대체" 원칙과도 정확히 일치. `Store({defaults})`도
  같은 스타일로 지원(안 하고 `Store()`만 있어도 되지만, 구현이 쉬우면
  지원) — 내부적으로 입력 테이블을 그대로 들고 있지 않고 `__real`/
  metatable 저장 + `__newindex`/`__index` 프록시로 감싸면 됨. 이후
  사용자가 그 defaults 테이블 원본을 직접 mutate하는 건 UB로 둠(방어
  로직 불필요 — 오늘 세션에서 반복 확인된 "드문 오용 케이스를 위해
  구조를 복잡하게 만들지 않는다"는 태도와 일치).

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
선택이 나와 재검토했으나 결론은 변경 없음. **이름 주의**: 아래에서 말하는
`Observer`는 PA님 코드의 클래스 이름(pub-sub, 8개 `subscribeXxx` 헬퍼)이고,
위 "`state:Observer(fn)`" 절에서 확정한 quad의 `Observer`와는 이름만
같을 뿐 무관한 별개 개념 — 이 절은 순수 역사적 교차검증 기록으로만 읽을 것.

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
  만들어주는 것도 가능한 디자인, 다만 지금까지 요구가 없었음"). (rbvm의
  GC-native 패턴이 실물에서 검증됐다는 근거는 `base/lifecycle-pattern.md` 상단
  참고 메모 참고.)

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

## Attribute 특수 키 — 타입 파라미터화 (2026-08-06, 신규 논의)

**상태**: 미확정, 사용자가 이번에 새로 제기 — 이전에 기록된 적 없음
(`architecture.md` 4번 항목의 `[Attribute "Name"]`은 특수 DI 키의 존재만
확정했을 뿐, 타입을 어떻게 표현할지는 다룬 적 없었음).

**문제**: Roblox Attribute는 Instance/Tag와 달리 실제로 **타입이 있는
값**(string/boolean/number/Color3/UDim/UDim2/Vector2/Vector3/CFrame/
Instance 참조 등 제한된 프리미티브 집합, 테이블 등 복합 타입은 지원 안
함)이라, 그냥 `[Attribute "name"] = value`로 두면 `value`의 타입을 Luau가
좁혀줄 방법이 없음. 커스텀/복합 데이터(테이블 등)는 애초에 Attribute가
지원을 안 하므로 Ref(직접 참조 획득) 쪽으로 빠지는 게 맞고, Attribute는
프리미티브 전용으로 남기면 된다는 게 사용자 판단 — Value 오브젝트가
역사적으로 Attribute의 대안(테이블/참조를 담는 용도)으로 나온 배경이지만,
지금은 Roblox Attribute가 Instance 참조 타입도 지원해서 `ObjectValue`
없이도 Ref 용도로 Attribute를 그대로 쓸 수 있다는 점을 사용자가 짚음
(`research/debug-tooling-plan.md`의 "Value 오브젝트 기각, Attribute로
확정" 결정과 같은 방향 — Instance 타입 지원까지 감안하면 그 결정의 근거가
한층 더 탄탄해짐).

**후보 두 가지**:
- `[Attribute<<boolean>> "name"] = true` (리터럴 또는 store-bind 값) —
  제네릭 파라미터로 타입을 명시하는 제네릭 생성자 스타일.
- `[BooleanAttribute "name"] = true` — 타입별로 이름이 다른 정적 생성자
  패밀리(`StringAttribute`/`NumberAttribute`/`Color3Attribute`/
  `InstanceAttribute` 등).

**소견(확정 아님, 검토 필요)**: 이 선택은 이미 확정된 DI 인스턴스 생성
패턴(위 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절)과 구조적으로 똑같은
문제 — 그때도 "제네릭 하나로 다 커버할지 vs 타입별 정적 필드로 나눌지"
고민이 있었고, 결론은 **둘 다**(`new<ClassName>(className)` 제네릭
생성자 + 자주 쓰는 ~25개는 정적 필드로 미리 바인딩)였음. Attribute도 같은
모양을 재사용하면 자연스러울 가능성 — `Attribute<T>("name")` 제네릭을
기본으로 두고, 실사용 빈도가 압도적으로 높을 `Boolean`/`Number`/`String`/
`Instance` 정도만 `BooleanAttribute`/`NumberAttribute`/`StringAttribute`/
`InstanceAttribute` 같은 지름길로 정적 바인딩하는 절충. 단 이건 사용자
확인 전 소견일 뿐 — `.claude/question.md`에 반영, 다음 세션에서 사용자
판단 필요.

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
