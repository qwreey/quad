# Bind 시스템 — 인스턴스 생성·이벤트 네이밍 인체공학 + 분할 색인

> **📄 [2026-08-14 세션] 분할 3단계 완료 — 이 문서는 이제 "prop 테이블이
> 인스턴스가 되는 인체공학"과 **분할 색인**만 담습니다.** 2989줄까지 불어나
> 사람이 검토할 수 없다는 사용자 지적으로 시작된 분할이 3단계로 끝났음
> (내용/결정은 이동 자체로는 안 바뀜):
>
> | 나간 것 | 어디로 | 단계 |
> |---|---|---|
> | `Ref`/`PreRef` 전체 | `base/ref-plan.md` | 1단계(9차 세션) |
> | 이벤트 바인딩(self 미전달, `false`로 disconnect) | `base/event-plan.md` | 1단계 |
> | `Brand`(런타임 nominal 판별) | `base/brand-plan.md` | 1단계 |
> | **디스패치 코어**(핸들러 계약 / 디스패치 모델 / `chains`·`retractFrom` / 체크리스트 / Length·Offset) | **`base/dispatch-core-plan.md`** | **2단계(14차 세션)** |
> | **반응형 코어**(Source/State 온톨로지·서브타입, 전파 모델, `:With`/`:Compute`/`:Apply`/`previous`, `Observer`, 구독·생명주기 게이트) | **`base/source-state-plan.md`** | **3단계(2026-08-14)** |
> | **Store**(이름 붙은 Source 모음, `defaults`, dot-access 타이핑, `:Set()` 문법, Store가 Store를 담는가) | **`base/store-plan.md`** | **3단계(2026-08-14)** |
>
> 2단계를 9차 세션이 미뤄뒀던 이유는 "0-A/0-Z 확정 시 그 텍스트가 어차피
> 전면 재작성 대상이라 같은 패스에서 갈라야 총 변경량·위험이 작다"였고,
> 실제로 14차 세션에 재작성과 분할을 같이 처리함. 3단계는 이 문서와
> store-semantics.md가 같은 내용을 반씩 나눠 갖고 서로를 "상세는 저쪽
> 참고"로 가리키던 걸 정리한 것 — **store-semantics.md는 이 분할로
> 완전히 흡수되어 없어졌음**(내용은 `store-plan.md`/`source-state-plan.md`
> 둘로 갈라짐).

**상태**: base — 핵심 디스패치 모델(`process` + 그가 반환하는 retract
클로저, 핸들러 3종 계약 — 2026-08-13 다섯 번째 세션에 별도 `retract`
필드가 반환값으로 합쳐지기 전엔 `process`/`retract` 4종이었음,
Signal 미채택, Ref 역할)과 소스 트리 상 패키지 경계(디스패치 엔진은
`quad-base`가 인터페이스로 소유, `quad-roblox`는 실제 구현만)까지 전부
2026-08-04 세션에서 확정되어 `research/`에서 승격됨(`base/architecture.md`의
"구현 착수: 소스 트리 구조 확정" 절 참고). 원본:
`.claude/initreq/raw-userinput.md`
"key와 value에 대한 바인드 연산은 pluggable 하도록 구성하기" / "스토어는 스토어를
저장 가능한가" / "Ref는 고민중" 절. v1의 문제점은 `reference/quad-v1-architecture.md`
("ProcessQuadProperty" 하드코딩 디스패처), 참고 패턴은 `.claude/initreq/tbox`
(레지스트리)와 Fusion/Vide 비교는 `reference/comparison-fusion-vide.md` 참고.

## 분할된 문서로 가는 색인

- **디스패치 코어** — 핸들러 계약(`isHandlable`/`priority`/`process`), 확정된
  디스패치 모델, `None` 센티널, `Dispatch`가 탑레벨 싱글톤인 이유, `chains`
  인덱스 체인과 `Dispatch.retractFrom`, Handler 작성 체크리스트, Length/Offset
  (형제 순서 보장), "store 바인드는 래핑" 결론 →
  **`base/dispatch-core-plan.md`**.
- **반응형 코어** — `Source`/`State` 온톨로지와 구조적 서브타입, push-invalidate/
  pull-recompute 전파 모델, "관측해야 실체화된다", `:With`/`:Compute`(trailing
  args·`previous`·lazy 핸들 계약), `:Apply`, `state:Observer(fn)`,
  `:Subscribe()`/`:Unsubscribe()`, 이중 바인딩 금지 게이트 →
  **`base/source-state-plan.md`**.
- **Store** — 이름 붙은 Source 모음, `defaults`와 eager/lazy 생성, `store.key`
  dot-access 타이핑(+Luau `type function`), `store.key:Set(value)` 문법,
  "Store가 Store를 저장 가능한가", Store 부작용 정책 → **`base/store-plan.md`**.
- **`Ref` / `PreRef`** — 용도 재정의, `.Value`/`:Set`/`:Callback`/`:Wait` API,
  `Ref`의 retract, PreRef 호이스팅/1회용 가드 → **`base/ref-plan.md`**.
- **이벤트 바인딩** — 핸들러가 self(Instance)를 안 받는다는 확정, 이벤트도
  store-bind 가능(`false`로 disconnect) → **`base/event-plan.md`**. 단 이벤트
  *네이밍* 관례는 인스턴스 생성과 한 절에 섞여 있어 아래 "인스턴스 생성 /
  이벤트 네이밍 인체공학" 절에 그대로 있음.
- **`Brand`** — 런타임 nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`,
  `isState`를 branded 타입 전부로 일반화) → **`base/brand-plan.md`**.
- **`Tag` / `Attribute` 특수 키** → **`base/tag-plan.md`** /
  **`base/attribute-plan.md`**. 이 문서가 예전에 다루던 타입 파라미터화 문제
  (`[AttributeKey<<boolean>> "name"]`(구 `Attribute<<boolean>>`) vs
  `[BooleanAttribute "name"]`)뿐 아니라 `None`/`process`/retract 동작까지
  전부 그쪽에 확정 반영돼 있음. **[2026-08-11 아홉 번째 세션]**
  `attribute-plan.md`에 여러 Store를 한 번에 attribute로 묶는 그룹
  `Attribute(...)` 프리미티브(`Tag`와 동형)가 추가되며, 단일 키 생성자는
  이름 충돌 방지로 `AttributeKey<<T>>`로 리네임됨.

## 확정된 것 (더 이상 열린 질문 아님)

- **핸들러 계약**: `isHandlable(inst,k,v)` + `priority` +
  `process(inst,k,v,index)` **3종**으로 확정 — tbox식 6-hook 세분화는 지금은
  안 함. 실제 구현하며 부족한 지점이 보이면 그때 hook 추가(점진적 확장).
  **[정정, 2026-08-13 다섯 번째 세션]** 예전엔
  `process`(구 `bind`) + `retract`(구 `cleanup`) 4종이었으나, `retract`가
  별도 필드에서 **`process`의 반환값(retractor 클로저)** 으로 합쳐짐 —
  이름과 개념은 그대로 유효하고 자리만 옮겨온 것(`base/dispatch-core-plan.md`의
  "핸들러 계약" 절이 정본).
- **Signal 클래스**: 안 만듦, 콜백 + `Connected` 계산 속성만(`base/
  lifecycle-pattern.md`).
- **Ref**: 도입 확정(`base/ref-plan.md`), 용도는 "id 기반 조회 대체"가 아니라
  "외부 관리 instance를 점진적으로 다루기 위한 직접 참조 획득".
- **quad2-try(폐기된 이전 시도)에서 뭘 가져오고 뭘 버릴지**: 조사 완료 —
  **확인된 죽은 접근(OOP 상속 `Base:Extends`/`--&` 커스텀 파서/Slot 빈 스텁/
  `Pipe` copy-on-write 절충안)은 절대 반복 조사하지 말 것**, 상세 근거와
  "건질 만한 것"(`:With` 이름의 방증 등)은
  `archive/quad2-try-research-findings-rejected.md` 참고. 이 조사의 최종
  결론은 `base/source-state-plan.md`의 `state(state)` 조합 모델로 대체되어
  있고 Slot은 `base/slot-plan.md`의 from-scratch 설계를 그대로 쓰면 됨
  (재조사 불필요).

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
(`AnotherFactory` 등, 가상의 예)로 재호출하면 에러** — 이건
`base/module-lifecycle-plan.md`의 "Bind는 누가, 어떻게 구현하는가" 절의
원칙(이미 구현체가 있는데 또
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
어려움(`base/store-plan.md`의 "타입 추론 문제" 절이 다루는 Luau 오버로드
문제와 같은 원인). 사용자가 실제 참고 코드를
`.claude/initreq/artworks/DeclarativeProgramming/
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
타입을 좁혀주는 이득이 있어서(Store 자체가 `{key: Source<number>, ...}`류
평범한 레코드 타입으로 지어짐, `base/store-plan.md`) 그대로
유지 — 이벤트만 예외였을 뿐, "정적으로 알려진 것=필드 접근" 원칙 자체가
깨진 건 아님.

**`GetPropertyChangedSignal`은 이 문자열 키 패턴이 안 통함 — 별도 `OnChange`
DI 키로 확정(2026-08-10 세션).** 이벤트는 `inst[key]`가 이미 Signal이라
그대로 `Connect`하면 되지만, `GetPropertyChangedSignal(name)`은 프로퍼티
이름을 인자로 받아야 하고 그 이름이 "값 세팅" 키 네임스페이스와 겹쳐서
평범한 문자열 키로는 세팅과 리스닝을 구분할 수 없음 — 상세는
`base/onchange-plan.md`.

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
  (`base/source-state-plan.md`의 "PA님 코드와의 교차검증" 절 참고).

## 남은 열린 질문 (`.claude/question.md`에도 취합)

> **✅ [2026-08-13 열네 번째 세션 갱신] 여기 열려 있던 계약 질문은 전부
> 해소됐음.** `0-Z`/`0-A`(재-dispatch 모델 교체)는 확정되어
> `base/dispatch-core-plan.md`로 반영됐고 — 그 계약은 이제 이 문서 소관도
> 아님(2단계 분할로 나갔음) —, `0-Y`(콜백의 lazy 핸들 계약)도 열세 번째
> 세션에 "계약 유지, 남은 건 Luau 자체의 한계"로 해소됨
> (`base/typing-limits.md`). 아래 목록은 그래서 다시 **순수 이름 문제**만
> 남은 상태.

이 문서의 핵심 설계 질문은 2026-08-04 세 라운드(전파 모델/`:Compute`/State
쓰기 금지/Slot 생존 확인 → dot-access 타입 추론/인스턴스·이벤트 네이밍/
`RobloxFactory` 재호출 가드)를 거치며 전부 확정됨. 그 라운드들 기준으로
남았던 건 순수 API 표면 이름뿐이었음:

- **`DI`(또는 다른 이름) 등 정확한 모듈 이름** — 방향은 전부 확정, 이름만
  구현 단계에서 남음(`On` 모듈은 이벤트 바인딩이 PA님 방식으로 바뀌며 아예
  불필요해짐 — 위 "인스턴스 생성 / 이벤트 네이밍" 절 참고). Source/State
  쪽 이름 문제는 `base/source-state-plan.md`가 소스.
- **매 `process()` 호출마다 우선순위 스캔 비용** — 실제 구현/벤치마크 단계에서
  확인 필요(디자인 자체는 확정됐으므로 더 이상 사용자 확인 대상 아님, 구현
  검증 대상).
