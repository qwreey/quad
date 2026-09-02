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
  dot-access 타이핑(**[2026-08-25]** `type function` 합성은 폐기 —
  타입 인자에 `Source<T>`를 직접 써서 **평범한 레코드**로 짓는다,
  `base/store-plan.md`), `store.key:Set(value)` 문법,
  "Store가 Store를 저장 가능한가", Store 부작용 정책 → **`base/store-plan.md`**.
- **`Ref` / `PreRef`** — 용도 재정의, `.Value`/`:Set`/`:Callback`/`:Wait` API,
  `Ref`의 retract, PreRef 호이스팅/1회용 가드 → **`base/ref-plan.md`**.
- **이벤트 바인딩** — 핸들러가 self(Instance)를 안 받는다는 확정, 이벤트도
  store-bind 가능(`None`/`nil`로 disconnect) → **`base/event-plan.md`**. 단 이벤트
  *네이밍* 관례는 인스턴스 생성과 한 절에 섞여 있어 아래 "인스턴스 생성 /
  이벤트 네이밍 인체공학" 절에 그대로 있음.
- **`Brand`** — 런타임 nominal 타입 판별 통합 메커니즘(**[2026-08-21 재작성]**
  인스턴스 브랜드 `Brand()` + `:register`/`:is`, 다중 태깅 허용,
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
두면 됨(**[2026-09-02 구현 교체 — `H-305` (d′)]** 그 문자열 마커는 사본을
구분 못 해 `UseProvider`의 fn identity 락으로 대체됐다 — 두-케이스 의미론
자체는 그대로, 소스는 `module-lifecycle-plan.md`의 UseProvider 서술). 모듈 스코핑(`New()`, `base/architecture.md` 13번)과의 관계도
실은 열려있던 게 아니라 자연히 풀림 — `New()`가 실제로 호출되면 그
호출이 만드는 인스턴스가 별도 테이블이 되므로 이 마커도 테이블별로
독립적으로 스코핑됨(**[재정정, 2026-08-19 — `architecture.md` 13번의
재정정과 맞춤]** `Quad`는 이미 만들어진 기본 인스턴스이고 `New()`는 그
안의 opt-in 필드다, "`Quad()`를 부르면 매번 새 인스턴스"가 아님. 단
"자동으로"는 아님 — module-level state를 참조하는 코드들이 모듈
인스턴스를 인자로 받도록 손을 봐야 하는 건 architecture.md 13번의 정정
그대로, 여기서 반복 안 함).

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

**[2026-08-28 `Claim`]** 그 `{ ...타입명시 }`는 생성기가 `type <Class>Param<E>`로
이름 붙여 찍고 `D.Mapper.<Class>`와 공유한다 — 필드 파트는 같고 children 배열의
원소 타입 `E`만 파라미터(`D.Frame`은 기존 유니언, 매퍼는 `| MapperDescriptor`).
사용자 확정, `base/claim-plan.md` §2·§7-12.

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

**⭐ [2026-09-02 신설, M5 단위 ② — round14 `H-298` (a) 사용자 확정] `D`가
찍는 값 유니언의 정본.** 생성기(`scripts/gen-d.py`)가 이 정의로 찍고, 여기가
소스다:

- **스칼라 프로퍼티**: `(T | State<T> | Tween<T> | None)?` — `Tween<T>`은
  PropertyHandler가 소비하는 값-레벨 래퍼(`tween-plan.md`; 타입은
  `quad-roblox/src/types.luau`, 런타임은 M11 — 탐사자가 M9 오기를 잡음). 모든 프로퍼티에 균일하게
  허용한다(트윈 가능 여부는 엔진 몫 — 타입으로 안 가른다).
- **이벤트 필드**: `((<엔진 시그널 파라미터>) -> ()) | State<...> | None`에
  optional(`?`) — `nil` disconnect는 optional이 표현한다(`event-plan.md`).
- **children 원소(`NewChild`)**: `Instance | State<Instance> | None` — **M5 시점
  유니언**이고, **이후 마일스톤이 자기 핸들러가 도착할 때 유니언을
  확장한다**(확장 규칙 — M6 Slot, M8 `Ref`/`PreRef`/`PostRef`). `H-298` (a)
  회신문의 "Ref류"는 그 예고로 해석해 M5 유니언에서 뺐다 — `Ref` leaf
  핸들러가 M8이라 지금 실으면 런타임이 없는 거짓 표면이 된다(`H-297`과
  같은 논리; 이 해석이 틀렸다면 사용자가 뒤집을 것). 정의 실물은
  `quad-roblox/src/types.luau`.
- **`None`의 타입 표현**(위 세 식의 `None` — round14 `H-300` (a), 2026-09-02 사용자
  확정 — *"300 a 확인 완료, 권고대로"*). 원래는 `None`이 신원 센티널
  (frozen **빈** 테이블)이라 구조 타입 표현이 불가능했는데(빈 테이블
  타입은 모든 테이블에 매치, 사본별 신원이라 typeof도 불가), 센티널에
  마커 필드 하나(`__quadNone = true` — `Brand.luau`의 Brand가 아님)를 부여해 `QuadTypes.None`
  (`{ read __quadNone: true }`)으로 표현한다 — **런타임 판정은 여전히
  신원(`v == None`)뿐**이고 필드는 조언층 타입 전용, frozen 유지
  (`Dispatch/None.luau`).
- **범위 판정식(round14 `H-296` (a) + `H-301` 실측 보강)**: creatable ∧
  (`GuiObject`∪`UIComponent`∪`LayerCollector` 하위) + 명시 화이트리스트
  `{Folder, Camera, WorldModel}`, **클래스 수준 제외** — `Deprecated`
  (GuiMain)·`NotBrowsable`(내부 UI)·`MemoryCategory: Internal`(AdGui)·실측
  denylist(`RelativeGui` — 태그론 안 드러나는 RobloxScript capability
  게이트, Studio 실측). 산출 클래스 목록의 소스는
  `quad-roblox/dump/api-surface.json`(개수는 여기서 안 센다), 전 클래스
  실생성 가능성은 Studio 실측으로 확인.

**⭐ [2026-08-27 신설, 9라운드 `H-139`] `New(name)(props)` 파이프라인 의사코드 —
네 문서에 흩어져 있던 순서를 한 자리에.** 사용자 지시: *"실 구현 전에
의사코드를 써보자. 그걸로 인해서 감추어졌던 설계 결함이나 폭탄이 발견된 경우가
많아서, 커지기 전에 확인해볼 필요가 있음. 중요 계층이라서"*. 각 단계의 소스는
주석의 문서이고 **여기는 순서만 확정**한다 — 단계 안의 규칙은 그 문서가 정본.
(이름 주의: 여기 `New`는 quad-roblox `D/init.luau`의 **인스턴스 생성자**이고,
`module-lifecycle-plan.md`의 `New(): Quad`는 quad-base의 **모듈 팩토리**다.
패키지가 달라 런타임 충돌은 없지만 산문에서 섞이니, 생성자는 항상
`New "Frame"` 꼴로, 팩토리는 `New()` 꼴로 쓸 것.)

```lua
-- quad-roblox/src/D/init.luau — 생성기가 찍는 커링 생성자. 아래 ①~④ 순서가 계약.
local function New(className: string)
    return function(props)
        -- ① 물리 생성 — 백엔드의 일. base는 `Instance`를 모른다
        --    (`dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op").
        local inst = Instance.new(className)

        -- ② gcconn/gchold — 생성 **직후, 무조건**(핸들러/바인딩 유무와 무관).
        --    `lifecycle-pattern.md` (0)의 코드 그대로: 클로저가 `gchold`와 `inst`를
        --    같이 캡처해 userdata 동일성을 고정하고 `InstData:SetWeak(inst, …)`.
        --    ③④보다 앞인 이유 — 거기서부터 `inst`를 키로 쓰는 `Relate`
        --    (`elementOwner`/`nameClaims`/`bk`/`chains`)가 생기는데, 키의 동일성
        --    고정이 그보다 먼저여야 한다.
        --    [2026-08-28 `Claim` §7-9] 인라인이 아니라 주입 op `nativeClaim(inst)` 호출 —
        --    (0)의 코드는 그 op 안에만 산다(`Claim`도 같은 op를 부른다, `base/claim-plan.md`).

        -- ③ flatten — Modifier 항목을 제자리에서 `ProcessedModifier`로 소진하고
        --    필드를 해시 파트로 merge. 새 테이블 없음, `inst`를 안 받는 순수 변환
        --    (`modifier-plan.md`의 "flatten의 정확한 형태"). `PreRef`/`PostRef`가
        --    Modifier 필드에 오는 건 타입으로 차단돼 있어 여기선 안 다룬다.
        local flattened = flatten(props)

        -- ④ 디스패치 — pre-pass → 본체 → `postRefList`. 전부 `Dispatch.drive`가 소유.
        Dispatch.drive(inst, flattened)

        return inst   -- `D.Frame`은 이 함수에 캐스트만 얹은 별칭(위 확정)
    end
end
```

```lua
-- quad-base: Dispatch/init.luau
function Dispatch.drive(inst, flattened)
    -- ⓪ 배치 Blocker — **진입 직후** 켜고 `drive`가 할 일을 전부 마친 뒤(post-pass
    --    포함) 끈다: `dispatch-core-plan.md`의 `H-17` 계약(*"`drive` 전체를 `inst`
    --    전용 `Blocker`로 감싼다"* / *"`PostRef` 콜백은 게이트가 켜진 채로 실행된다"*).
    --    ⚠️ 배열 파트가 비어 있으면 열지 않는다 — 안 그러면 `Frame { Size = … }`
    --    처럼 자식 없는 모든 Instance마다 Blocker + `bk`가 eager 생성된다
    --    (9라운드 Q2/Q3가 Slot 쪽에서 막은 것과 같은 부류). pre-pass는 자리를
    --    센티널로 바꿀 뿐 비우지 않으므로 이 판정은 pre-pass 앞뒤가 같다.
    local batching = flattened[1] ~= nil
    local blocker = if batching then getBlocker(inst) else nil
    if batching then blocker:On() end

    -- (a) pre-pass — 배열 파트만, index 순서(`ref-plan.md`의 "메커니즘 — pre-pass 한 스윕" 절).
    --     `PreRef`는 그 자리에서 fire(`v:Set(inst)`) + 소진,
    --     `PostRef`는 수집 + 소진. `_fired` 1회용 가드는 둘 다 **여기서** 선다.
    local postRefList = {}                          -- 이 호출에만 로컬 — Relate 아님
    for i, v in ipairs(flattened) do
        if isPreRef(v) then
            if v._fired then error("PreRef instance reused", 2) end
            v._fired = true
            v:Set(inst)                             -- 콜백 fire — 아직 자식도 프로퍼티도 없다
            flattened[i] = ProcessedPreRef
        elseif isPostRef(v) then
            if v._fired then error("PostRef instance reused", 2) end
            v._fired = true
            table.insert(postRefList, v)
            flattened[i] = ProcessedPostRef
        end
    end

    -- (b) 본체 — **단일 일반화 `for`**(`F-4-1`). 배열 → 해시 순서는 Luau 순회에
    --     기댄다. 배열 파트가 Length/Offset **배치 등록 구간**이고 해시 파트는
    --     부기를 안 만진다(`dispatch-core-plan.md`의 "해법의 핵심" 1번·4번).
    for k, v in flattened do
        Dispatch.process(inst, k, v, 1)             -- 체인 index는 항상 1부터
    end

    -- (c) `postRefList` — push 순서 = index 순서. 이 시점에 끝나 있는 것/아닌 것은
    --     `ref-plan.md`의 "`PostRef`" 절(자기 서브트리와 프로퍼티는 완성,
    --     **자기 `.Parent`는 아직**일 수 있다). **게이트가 켜진 채 돈다** — 콜백이
    --     `slot:Add(…)`로 이 `inst`에 emit을 올려도 `gatedRecompute`는 스킵되고
    --     정합성은 아래 마지막 `recompute` 한 번에 의존한다(`H-17`).
    for _, v in ipairs(postRefList) do v:Set(inst) end

    -- ⓪' 배치 닫기 — `drive`가 할 일을 전부 마친 뒤 딱 한 번.
    if batching then
        blocker:OffWithoutEmit()
        local bk = getBookkeeping(inst)             -- 배열 파트가 있었으니 이미 존재
        if not bk.recomputeBlocker:IsOn() then recompute(inst, bk) end   -- `H-119`
    end
end
```

**이 의사코드를 쓰면서 드러난 것**(결정은 `qa-request/pre-implementation-handtrace-round9-followup.md`의
`H-139` 절 — 여기선 목록만):
- **배치를 닫는 자리** — 처음엔 *"어디에도 안 적혀 있다"*고 보고 해시 파트
  앞에서 닫는 모양으로 썼는데, **틀렸다**(감사 1라운드가 잡음):
  `dispatch-core-plan.md`의 `H-17` 절이 이미 *"`drive` 전체(post-pass 포함)를
  감싼다, `PostRef` 콜백은 게이트가 켜진 채 실행된다"*로 정해뒀고 그 이유(단일
  루프에선 배열 파트의 끝이 루프 밖에서 관측되지 않는다 / `postRefList`는 해시
  파트보다 뒤다)까지 적혀 있었다. 위 의사코드는 그 계약대로 고쳤다. 실제로
  드러난 건 그 절의 아래쪽 "해법의 핵심" 4번이 옛 문구(*"배열 파트 순회
  전체"*)로 남아 있던 것 하나.
- **자식 없는 Instance에도 Blocker/`bk`가 생기는 경로** — `getBlocker(inst)`를
  무조건 부르면 그렇게 된다. `flattened[1] ~= nil` 가드로 막았다.
- **⭐ [2026-08-27 확정, 9라운드 `H-142`] props에 `Parent`는 올 수 없다 — 그건
  부모가 하는 일이다.** 의사코드를 쓰다 "해시 파트 안의 `Parent` 대입 순서가
  미정"이 드러났는데, 사용자는 순서를 정하는 대신 **키 자체를 금지**했다:
  *"Parent대입 자체가 오면 안 돼. 그건 부모에서 할 일이거든. 자신이 바로 하는
  경우는 없어. 그걸 허용해준다는것 자체가, '외부에서 직접 Parent 설정해주지
  말것' 을 해치는 요인이 되기도 해.(암묵적으고 가능하도록 둬버려서)"* —
  `slot-plan.md`가 *"동적 자식은 반드시 `Slot` 또는 `state<Frame>`류 store-bind를
  통해서만"* 이라고 세운 원칙(외부 코드가 `.Parent`로 자식을 끼우면 `Length`/
  형제 순서가 조용히 어긋난다)의 **정적 리터럴 판**이다. `.Parent` 대입은
  자식을 받는 쪽 — `InstanceChildHandler`(정적 자식, `H-134`)와 Slot의
  `native*` 주입 op — 만 한다.
  - **타입**: `D` 생성기가 각 클래스의 props 타입에서 `Parent`를 **제외**한다
    (`ROADMAP.md` M5 `D/init.luau` 체크박스) — **그리고 `FrameModifier`류
    메소드 목록에서도**(`ROADMAP.md` M7; **[2026-08-27 `/code-review`]** 두
    목록이 같은 API 덤프에서 따로 생성되는데 한쪽만 빼면
    `Modifier():Parent(x)`가 타입을 통과하고 `flatten`이 해시 파트로 merge한다 —
    `PreRef`/`PostRef`를 Modifier 타입으로 차단하는 것과 같은 자리). 범위 밖 클래스의 `New<<X>> "X"`는
    `any`라 타입으로 못 막고 아래 런타임 가드가 잡는다.
  - **런타임**: 새 메커니즘 없이 기존 계약으로 — `PropertyHandler.isHandlable`이
    `"Parent"`를 거부하면 그 키에 매치되는 핸들러가 없어 `Dispatch.process`의
    *"매치 핸들러 없음 → 즉시 error"* 계약(`ROADMAP.md` M3)에 걸린다. (이
    배선은 사용자 확정이 아니라 **규칙을 기존 계약에 얹은 제 선택**이다 —
    `H-142` 처방 후보 (a)/(b)/(c)가 전부 새 메커니즘이라 정하지 않았던 것을
    "키 금지"로 바꾸니 필요한 코드가 이 거부 한 줄뿐이다. 다른 모양이 낫다면
    갈아끼울 것.) 순서 문제는 키가 없어지면서 소멸한다. **[2026-08-28 10라운드
    `H-148` 철회]** 2026-08-27에 여기 "그 거부는 **전용 문구**를 낸다"를 붙였는데
    그건 새 메커니즘이었다(`isHandlable` 거부는 `Dispatch.process`의 일반 매치
    실패 문구로 떨어지고 그 자리에 특수 분기는 두지 않기로 확정돼 있다) —
    **철회**, 일반 문구 그대로. 오해는 사용자 문서가 맡는다.
  - **⭐ [2026-08-28 좁혀서 복원 — `base/claim-plan.md` §5] 아래 "루트는
    사용자가 밖에서 `.Parent =`" 예외는 10라운드 `H-148`에서 한때 폐기됐다가 같은 날
    `Claim` 갈래 확정에서 복원됐다** — 루트의 `Parent`는 만든 방법(`New`/`Claim`)과
    무관하게 어느 부기에도 속하지 않으므로 밖에서 대입해도 된다(사용자: *"밖에서
    .Parent 설정하는건 괜찮아. 루트도 quad 소유이긴 한데 … 정확히는 ScreenGUI 가
    이미 존재해도 똑같음"*). 여러 스크립트가 한 `PlayerGui`를 쓰는 흔한 경우가 이
    경로다. 이미 있는 트리를 quad 소유로 만드는 것은 별개 표면 `Claim`(`base/claim-plan.md`,
    **M5 스코프** — `H-161`). 아래 원 서술과 그 안의 "만들지 않는다"는 그대로 유효하다.
    **[당시 폐기 논거 — 지금은 유효하지 않음]** `H-148`은 사용자의 *"slot 은 물리
    장치에 mount 할 방법이 거의 존재하지 않음 … PlayerGui 가 상위에 있고 거기에 GUI 를
    여럿 바운딩 해야해서 `Slot { Shop{} … }` 하는게 안 될것 같은 느낌이 듦. 이건
    Parent 이상의 문제인것 같아."*에서 출발해 "루트도 `Claim`으로만 소유하고 `.Parent =`를
    사용자가 쓸 자리 자체가 없어진다"로 갔었다 — 그 뒤 `Claim`이 1회·전체 소유라
    여러 스크립트의 PlayerGui를 못 담는다는 게 드러나 위처럼 복원됐다. 아래 원 서술:
    **[2026-08-27 확정, 9라운드 `H-146`] 루트는 이 금지의 범위 밖이다 —
    quad 트리의 최상위를 quad 밖 부모에 붙이는 건 사용자가 밖에서 `.Parent =`로
    한다.** 위 인용문의 *"외부에서 직접 Parent 설정해주지 말것"*이 막는 것은
    **quad가 관리하는 자식 자리**(Slot 요소·정적 자식)에 밖에서 끼우는 것이고
    (`slot-plan.md`의 "동적 자식은 반드시" 절), 루트는 어느 `Length`/형제 순서
    부기에도 속하지 않아 어긋날 부기가 없다(`gcconn`/`gchold`는 `Destroying`
    기반이라 `Parent`와 무관). **`Mount(root, parent)`류 표면은 만들지 않는다**
    — 사용자 확정: *"React 에서도 최상위 경로는 … root 를 돔 api 로 가져오고
    거기에 바운딩 하는 처리를 해야하거든. … Quad 가 제공하는 마운트는 완전히
    다른 성격이라서(부기에 대한 처리가 들어가는데 PlayerGUI 등 Quad 가 제공하지
    않은 부기가 없는 객체에 대해서 Quad 의 객체를 주입하는 성격의 API 는
    아니거든) 해당 부분을 해결하기 위해서 다른 API 를 제공 할 이유가 없기도 해.
    해당 부분은 각 엔진을 사용하는 최종 사용자의 몫."* 즉 루트 부착은 엔진마다
    다를 수 있는 최종 사용자 코드고, quad의 마운트(Slot)는 *부기가 있는* 자리에
    넣는 별개 개념이다. 루트 전용 props 키(`H-142` 취지와 충돌)도 기각. 사용자
    문서에 "루트는 직접 `.Parent =`, 그 아래는 절대 직접 하지 말 것"을 같이
    적을 것(`research/documentation-content-map.md` 대상).

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
**[2026-08-25]** 그 레코드를 **타입 함수로 합성하던 것만** 폐기됐다 —
지금은 타입 인자에 `Source<T>`를 직접 쓴다.
**[정정, 2026-08-18] `store "key"` 문자열 커링은 기각됐다** — 여기 폴백으로
같이 적혀 있었으나 폐기됨(`"a"`가 그냥 `string`으로 들어가 `Source<T>`의
`T`를 알 수 없고, dot-access + `type function` 타이핑이 자리잡아 더 이상
필요 없어짐). 동적 키는 명시적 `store:Of<<T>>(name)`으로 간다(**[2026-08-25]** 옛 이름 `GetDynamic`) —
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
