# Bind 시스템 — 인스턴스 생성·이벤트 네이밍 인체공학 + 분할 색인

> **📄 [2026-08-14 세션] 분할 3단계 완료 — 이 문서는 이제 "prop 테이블이
> 인스턴스가 되는 인체공학"과 **분할 색인**만 담습니다.** 2989줄까지 불어나
> 사람이 검토할 수 없다는 사용자 지적으로 시작된 분할이 3단계로 끝났음
> (내용/결정은 이동 자체로는 안 바뀜):
>
> | 나간 것 | 어디로 | 단계 |
> |---|---|---|
> | `Ref`/`PreRef` 전체 | `base/ref-plan.md` | 1단계(9차 세션) |
> | 이벤트 바인딩(self 미전달, `None`/`nil`로 disconnect) | `base/event-plan.md` | 1단계 |
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
  store-bind 가능(`None`/`nil`로 disconnect) → **`base/event-plan.md`**. 단 이벤트
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
데모 모듈)에 공유해줘서 직접 확인 — 원래 가칭 `DI`는 Dependency Injection이
아니라 "Declarative Instance"(선언형 인스턴스 생성)의 약자였음.
**[2026-08-18 확정] 네임스페이스 이름은 `D`(Declarative)** — `DI`는 Dependency
Injection과 완전히 겹쳐 실제로 오해가 있었던 전례가 있고, `D`는 (1)
"Instance" 전용 개념이 아니라 quad-* 전반의 declare 요소로 확장 가능하며,
(2) 엔진 종속 없이 다른 백엔드에서도 재사용 가능하고, (3) `D.FrameModifier`류
타입 프리픽스가 짧아야 한다는 실용적 제약을 만족한다. 한 글자 식별자라
grep이 어렵고 이름만으로 뜻이 안 드러나는 게 유일한 단점이었으므로,
**문서에서 `D`가 처음 나오는 자리에서는 항상 `D`(Declarative)로 풀어쓴다**
(표기 규약은 `base/architecture.md`의 "코드 스타일 — 네이밍 케이싱" 절).

**인스턴스 생성 — 호출 모양은 PA님 코드 그대로, 타입은 생성기가 만든다
([2026-08-18 구현 전 QA에서 후자를 정정])**: 처음 제안했던 "필드=1급 타입
경로, 문자열=폴백"이라는 2트랙 구상보다 실제 호출 모양은 더 단순했음
(`DeclarativeInstance.luau:104-160`) — **제네릭 생성자 함수 하나 +
자주 쓰는 클래스를 필드로 미리 채운 정적 테이블**(`constructor.Frame =
new("Frame")`, `__index` 지연 생성이 아니라 eager). quad-v2도 이 모양을
그대로 채택한다. **다만 PA님 코드가 그 필드 타입을 뽑는 방식**
(`new<ClassName>(className): from<index<UIInstances, ClassName>>` — 타입
레벨 인덱싱)**은 채택하지 않는다**:

1. **이벤트 필드가 콜백 타입이 안 나온다.** Roblox 타입 정의에서
   `MouseButton1Click`은 시그널 계열 타입이라, 인덱싱으로 뽑으면
   `RBXScriptSignal`이 그대로 나오고 quad가 원하는 `((...) -> ())?` 콜백
   시그니처가 안 나옴.
2. **LSP마다 `Frame` 타입을 다루는 방식이 다를 수 있어** 타입 함수/인덱싱에
   의존하는 게 위험하다.
3. **`T | State<T>`(그리고 `T | Tween<T>`, `None`/`nil` 등)까지 타입 함수로
   조립해야 하는데**, 그럴 바엔 `D` 파일을 통째로 생성하는 쪽이 단순하다.

**따라서 `D`는 전량 코드 생성 산출물이다** — 타입뿐 아니라 `New` 호출문까지
생성기가 찍어낸다(사용자: *"전부 코드 생성이나, New 같은것도 생성기에서
같이 적어주어야할 부분"*). 손으로 쓰지 않는다.

**`New`는 커링, `D`는 처리 없는 별칭 테이블 (2026-08-18 확정)**:

```luau
-- New(name)이 생성자 함수를 반환하고, 그걸 props 테이블로 다시 호출
New "Frame" { ... }          -- == New("Frame")({ ... })
New<<Frame>> "Frame" { ... } -- 직접 사용도 같은 모양

-- D는 그 결과에 캐스트만 얹은 순수 별칭 테이블 (생성기 산출물)
D.Frame = New<<Frame>> "Frame" :: (({ ...타입명시 }) -> Frame)
```

- **이름은 대문자 `New`로 통일**(사용자 확정: *"2. New입니다."*) — PA님 코드
  인용의 소문자 `new`와 섞여 있던 것을 정리.
- **뒤집는 게 아니라 명시화**다 — PA님 패턴의 `constructor.Frame =
  new("Frame")`이 이미 사실상 커링이었고, 다만 (a) "커링이다", (b) 2단계 호출
  계약, (c) `New "Name" {...}`라는 직접 호출 형태가 문서에 적힌 적이 없었다.
- **기각된 "2트랙"과 혼동하지 말 것** — 기각된 건 *"필드=1급 타입 경로,
  문자열=폴백"* 이라는 **능력 차이**였지 `New`라는 이름이나 문자열 호출
  자체가 아니다. 이 확정은 오히려 두 형태가 **완전히 같은 것**(하나가 다른
  하나의 미리 적용된 결과)임을 못박는다.
- **생성 범위는 "GUI에 쓰이는 모든 인스턴스"**(사용자 확정) — 예전 서술의
  "자주 쓰는 ~25개"도 아니고 Roblox 전체 클래스도 아님. 전량 생성하면 `D`
  파일이 너무 커진다는 게 이유. "GUI에 쓰이는"의 정확한 판정 기준(API
  덤프에서 `GuiObject` 하위 + `UIComponent` 하위 + `LayerCollector`류 등)은
  생성기 구현 시점에 정한다.
- **범위 밖 클래스는 느슨하게 `any`**(사용자 확정: *"느슨하게 any 로 하고,
  필요하면 이를 직접 구현 가능하게 둡니다. cast 를 하든, 유저의 자유"*) —
  `New<<X>> "X" {...}`를 직접 쓰면 props 타입은 `any`이고, 필요하면 사용자가
  `::` 캐스트로 좁힌다. 새 확장 지점을 만드는 게 아니라 `D.Frame` 자신이
  이미 캐스트 한 줄이므로 **같은 한 줄을 사용자가 직접 쓰면 되는 것**.
  따라서 **"제네릭 생성자 함수 하나가 알려진 타입과 모르는 타입을 전부
  커버"라는 옛 서술은 런타임에 대해서만 맞다** — 타입은 `D` 범위 안만
  정확하고 밖은 `any`다.

**이벤트 바인딩 — `On.EventName` 도트액세스 안 씀, PA님 방식(평범한 문자열
키 + 런타임 리플렉션)으로 전환**: `DeclarativeInstance.luau:13-91`의
`assign(instance, key, value)`가 `ReflectionService:GetPropertiesOfClass`/
`GetEventsOfClass`로 클래스별 프로퍼티/이벤트 타입을 캐싱해두고, 키가
`RBXScriptSignal` 타입이면 자동으로 `instance[key]:Connect(value)`로 처리함
— `Frame { MouseButton1Click = fn }`처럼 별도 네임스페이스 없이 그냥 문자열
키로 씀. `On.` 접두어 없이 문법이 더 간결해짐 — **사용자 확정**("PA 님
방식 괜찮은듯. 타이핑은 인라인이 되긴 하겠지 정도면 괜찮다").

**[정정, 2026-08-18 구현 전 QA] "콜백 시그니처까지 Luau가 검증 못 한다"는
서술은 거짓이었음.** 옛 문장은 이 방식이 *"타입 안전성을 어느 정도 포기하는
대가"* 이고 *"콜백 시그니처까지 Luau가 검증 못 함"* 이라고 적었는데, 사용자가
직접 반례를 작성해 보여줬다:

```luau
function Frame (prop: {MouseButton1Click: ((a: number)->())?})
end

Frame{
    MouseButton1Click = function(a) -- a: number 로 추론됨
    end
}
```

props 테이블 **타입에 필드로 선언돼 있으면 콜백 파라미터가 그대로
추론된다.** 런타임 판별을 `ReflectionService`로 하는 것과 **타입을 생성기가
제공하는 것은 완전히 별개 축**인데 옛 서술이 둘을 묶어버린 것.
따라서 이건 "감수하는 대가"가 아니라 **`D` 생성기가 챙겨야 하는 구현
체크리스트 항목**이다 — 생성기는 클래스별 props 타입에 **이벤트 필드까지
정확한 콜백 타입으로** 포함시켜야 하고, 값 타입은 콜백뿐 아니라
`State<...>`와 disconnect 센티널(`None`/`nil`, `base/event-plan.md`)까지
포함하는 유니온이어야 한다. 이건 위 "타입은 생성기가 만든다"의 직접적
근거이기도 하다(인덱싱으로는 시그널 타입이 그대로 나와서 안 됨) — 두 항목은
같은 문제의 양면이므로 같이 볼 것. quad-v2 구현에서는 이 "키가 이벤트인가"
판별을 `isHandlable`로 감싼 pluggable 핸들러(`quad-roblox`가 `Reflection
Service` 기반으로 구현)로 두면 됨 — 별도 `On` 모듈/필드 접근 구조 자체가
불필요해짐.

**Store 쪽 dot-access는 그대로 유지**: `store.key`는 실질적으로 Luau가
타입을 좁혀주는 이득이 있어서(Store 자체가 `{key: Source<number>, ...}`류
평범한 레코드 타입으로 지어짐, `base/store-plan.md`) 그대로 유지.
**[정정, 2026-08-18] `store "key"` 문자열 커링은 기각됐다** — 여기 폴백으로
같이 적혀 있었으나 폐기됨(`"a"`가 그냥 `string`으로 들어가 `Source<T>`의
`T`를 알 수 없고, dot-access + `type function` 타이핑이 자리잡아 더 이상
필요 없어짐). 동적 키는 명시적 `store:GetDynamic<<T>>(name)`으로 간다 —
`base/store-plan.md`가 소스.
**이벤트가 이 관습의 예외인 성격도 바뀜** — "타입을 포기하는 예외"가 아니라
**이름 지정 방식만 문자열 키인 예외**다(타입은 위 정정대로 생성기가 준다).

**`GetPropertyChangedSignal`은 이 문자열 키 패턴이 안 통함 — 별도 `OnChange`
특수 키로 확정(2026-08-10 세션).** 이벤트는 `inst[key]`가 이미 Signal이라
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

- **[해소, 2026-08-18] 모듈 이름은 `D`로 확정** — 옛 항목("`DI`(또는 다른
  이름) 등 정확한 모듈 이름")은 닫혔다. 근거는 위 "인스턴스 생성 / 이벤트
  네이밍 인체공학" 절. Source/State 쪽 이름 문제는
  `base/source-state-plan.md`가 소스.
- **매 `process()` 호출마다 우선순위 스캔 비용** — 실제 구현/벤치마크 단계에서
  확인 필요(디자인 자체는 확정됐으므로 더 이상 사용자 확인 대상 아님, 구현
  검증 대상).
