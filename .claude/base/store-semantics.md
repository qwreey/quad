# Store 의미론 — 부작용 허용, State는 Source 위의 조합 가능한 캐시 레이어

**상태**: base — Store가 부작용을 허용한다는 핵심 결정과 State/Source
온톨로지 구조 자체는 확정(2026-08-04 검증 라운드에서 새로 열려 같은 세션
2~4차 라운드에 걸쳐 확정까지 마침 — 최신 상세는 `base/bind-system-plan.md`
참고). 원본: `.claude/initreq/raw-userinput.md` "store는 부작용을 허용함" /
"state는 어떻게 구현하는가" 절.

> **⚠️ [2026-08-13 첫 실측에서 발견, `question.md` 0-Y] 단, 온톨로지 중
> 하나 — self/deps를 lazy `State` 핸들로 넘기는 `:Compute`/`:With` 콜백
> 계약 — 는 "확정"이 아니라 미해결.** Luau 양방향 추론과 충돌함이
> 실측으로 확인됨 — 상세는 `base/bind-system-plan.md`의 동일 배너,
> M0 착수 전 사용자가 확정해야 할 사안.

## Store는 부작용을 허용하는 게 기본 디자인

부작용 없이(파라메터 패싱만으로) 쓰는 것도 물론 가능하지만, 라이브러리 차원에서
막지 않는다. 부작용 유무는 **사용자가 직접 문서화**하는 관례로 둔다 — 라이브러리가
순수성을 강제하지 않음.

다만 한 가지는 명확히 구분: **렌더 리턴 위에서 무언가를 observe하는 것은 그냥
부작용**이다 (`useEffect`와 유사한 것으로 문서화). 이건 "허용되는 부작용"이 아니라
"당연히 부작용"이라는 뜻 — 문서화 시 이 경계를 분명히 할 것 (`base/
purity-and-effects-plan.md`와 연결됨).

**보강(2026-08-04 검증 라운드): 부작용은 심각도가 다른 두 갈래로 나뉜다.**

1. **국소적 부작용** — 입력으로 받았거나 자신이 만들어 소유한 대상에 대한
   부작용(예: 렌더 리턴 아래에서 옵저빙해서 자기 slot을 갱신). 이건 편의성이
   커서 적극 환영하는 영역.
2. **경계를 넘는 부작용** — globalStore처럼 컴포넌트 바깥의 전역 상태를
   다루는 경우. 게임 UI 특성상(스킬/주변 환경에 영향받는 UI 등) 완전히
   막을 수는 없지만, 라이브러리로 재사용하려는 컴포넌트가 이런 부작용을
   가지면 이식성이 떨어짐(`base/purity-and-effects-plan.md`와 연결).

**해소됨(2026-08-04 2차 라운드)**: state를 옵저빙해서 나온 결과로 slot에
`clear`/`add` 같은 연산을 할 때, 그 시점에 대상 slot이 이미 죽어있으면
어떻게 되는가 — 별도 메커니즘을 새로 만들 필요 없이, `base/
lifecycle-pattern.md`의 "생명 바인드 유틸"(canExecute predicate)을 state-
invalidate 리스너 클로저 등록에도 그대로 재사용하면 됨: 발화 시
`canExecute(inst, value)`(2026-08-08 세션 최종 시그니처 — `base/
lifecycle-pattern.md` 참고) 하나만 확인, 거짓이면 no-op. 한때 검토했던 `isInit=false`면
허용/`isInit=true`+생존확인 거짓이면 불허 분기 초안은 폐기 — `canExecute`
하나로 통일(사용자 확정). 상세는 `base/bind-system-plan.md`의
"Store/State/Source 온톨로지" 절 참고.

## 정정(2026-08-04 검증 라운드): `State` 프리미티브는 실제로 필요하다

**후속(2026-08-04 2차 라운드)**: 아래 온톨로지의 전파 모델(push-invalidate/
pull-recompute)·`:Compute` 인자 규칙·State 쓰기 금지·`Source` 독립
프리미티브화·Slot 생존 확인까지 전부 확정됨 — 최신 상세는 `base/bind-system-plan.md`의 "Store/State/Source 온톨로지 — 핵심 메커니즘 확정"
절이 최종 소스, 이 절은 배경/온톨로지 명칭 정의로만 유지.

**이전 버전의 이 절("State 프리미티브는 만들지 않는다")은 틀렸음 — 사용자가
검증 라운드에서 직접 정정.** 정확한 모델:

- **Store는 "source 집합체"이자 state를 만들어주는 존재.** 실제 값이 존재하고
  변경될 수 있는 단일 지점은 source(v1의 "값의 근원"에 해당) — store는 이런
  source들의 모음.
- **State는 source(또는 다른 state)를 받아 캐싱만 하는 존재, 자기 고유의
  독립적 value 개념이 없다.** 단일 값에 대한 state 생성은 store가 자동으로
  해주지만, 그 결과를 다시 분기하고 싶으면(하나의 파생 스트림에서 여러
  소비자가 각자 다른 추가 compute를 얹고 싶은 경우) `state(state)`처럼 기존
  state의 결과를 받아 새 state를 만드는 조합이 필요.
- **[정정, 2026-08-06 후속 세션] store에서 값을 얻는 연산(`store.key`)은
  Source를 직접 반환한다 — 더 이상 별도 State 인스턴스를 감싸서 반환하지
  않음.** 상세는 아래 "Source가 State를 만족함" 절 참고. 이 항목의 원래
  버전("항상 새 state 인스턴스를 반환")은 틀림 — Store가 별도 wrapper
  없이 자기 안에 만들어둔 Source를 그대로 돌려주는 쪽으로 재정리됨.
- 이건 quad2-try(폐기된 이전 시도)의 `Pipe` copy-on-write 절충안을 대체하는
  방향으로 좁혀짐 — 별도 `Pipe` 타입을 만들어 소유권/버전 가드를 넣는 대신
  State 자체가 "파이핑 결합체"이고 `state(state)`로 분기하면 될 걸로 보임
  (`Pipe` 후보는 사실상 폐기 쪽으로 기움). 상세는 `base/bind-system-plan.md`의
  "Store/State/Source 온톨로지" 절 참고 — **이 절 이후 2~4차 라운드에 걸쳐
  전부 확정됨, 더 이상 진행 중인 스레드 아님.**

## 일반 원칙 — 독립 존재 가능한 프리미티브 vs 원천에 종속된 파생 데이터 (2026-08-06 후속 세션)

위 "State는 자기 고유의 독립적 value 개념이 없다"는 관찰을 일반 원칙으로
확장(사용자 관찰): quad의 개념들은 두 부류로 갈린다.

- **독립 존재 가능한 프리미티브** — Source, Ref, Store, Modifier. 다른
  무언가 없이 그 자체로 `Type(args)` 팩토리 함수로 만들어짐(`Source(default)`/
  `Ref(default)`/`Store({defaults})`/`Modifier()`, 위 "생성자
  스타일 확정" 참고 — `Modifier()`는 빈 인스턴스, 실제 필드는
  `mod:UICorner(8)`류 체이닝으로 그 위에 얹음).
- **원천에 종속된 파생 데이터** — State, Observer. 자기 혼자 존재할 수
  없고 항상 특정 원천(Source/다른 State)에 의존 — 그래서 이 둘은 자유
  함수 생성자가 없고, 항상 원천에 대한 메소드 호출로만 얻어진다
  (`store.key`/`state:Compute(fn)`/`state:With(...)` → State,
  `state:Observer(fn)` → Observer). "클래스 같은 독립 타입"이라기보다
  "State를 관측·핸들링하는 데이터"에 가까움.

이게 `base/bind-system-plan.md`의 `state:Observer(fn)`가 메소드고
`Observer(state, fn)`라는 자유 함수가 없는 더 근본적인 이유 — 단순히
"읽기 편해서"가 아니라 Observer 자체가 State처럼 원천 없인 존재할 수
없는 카테고리라서. 앞으로 새 개념을 추가할 때도 이 두 부류 중 어디에
속하는지가 생성자 모양(자유 함수 팩토리 vs 원천에 대한 메소드)을
결정하는 기준으로 쓸 수 있음.

**세 번째 카테고리 — Handler는 둘 중 어디에도 안 낌(2026-08-08 두 번째
세션, 명시화).** `Handler`(`isHandlable`/`priority`/`process` 3종 계약 —
`process`가 자기 retract 클로저를 반환, 2026-08-13 다섯 번째 세션 정정,
`base/bind-system-plan.md` "핸들러 계약" 절)는 위 분류가 다루는
"quad 사용자가 직접 다루는 리액티브 값"이 아니라 **그 자체로는 구현체가
없는 순수 타입 계약**이라 애초에 이 분류표의 대상이 아님 — Source/Ref처럼
`Type(args)` 자유 함수로 인스턴스를 만들 수도 없고(계약을 만족하는 값은
`PropertyHandler`/`TagHandler`/`Dispatch/StoreBind.luau`의 `NoneHandler`처럼
**구현하는 쪽**이 리터럴 테이블로 직접 채워 넣는 것), State/Observer처럼
어떤 원천에 종속된 파생물도 아님(애초에 "원천"이라는 개념 자체가 안 맞음).
Handler는 quad 사용자가 아니라 **백엔드/핸들러 구현자가 채우는 확장
지점**이라는 완전히 다른 축의 개념이라, 여기 분류를 "왜 Handler가
빠졌는지" 궁금해할 필요 없음 — 프리미티브 분류가 불완전한 게 아니라
Handler가 애초에 다른 층위. 관련해서 Handler를 담는 엔진(`Dispatch`) 자체가
왜 프리미티브가 아니라 탑레벨 싱글톤인지는 `base/bind-system-plan.md`의
"Dispatch는 프리미티브가 아니다" 절 참고.

과거 "미해결로 남은 것"으로 적었던 두 항목도 모두 해소됨: `:Compute`의
캐싱/무효화 전략은 push-invalidate(신호만)/pull-recompute(`Get()` 시점)로
확정(`base/bind-system-plan.md` "전파 모델" 절), `store "key"` 커링의 타입
추론 문제는 `store.key`(dot-access)를 1급 경로로 확정하며 해소(같은 문서
"타입 추론 문제" 절, 3차 라운드).

## Source가 State를 만족함 — 구조적 서브타입, RefSource 개념 폐기 (2026-08-06 후속 세션)

**배경**: `store.key`가 매번 새 State를 감싸 반환하던 이전 모델의 타입
문제(레코드 타입 `{key: State<number>}`가 읽기/쓰기 비대칭이라 Luau
타이핑이 안 맞음, 위 "Source가 State를 만족함" 논의에서 도출)를 풀다가
사용자가 제안한 더 근본적인 재구성. `RefSource<T>`(store 슬롯을 가리키는
전용 타입)를 따로 만드는 중간안도 검토했으나, 최종적으로 **Source 자체가
State를 만족하도록 만들고, RefSource라는 별도 타입은 폐기**하는 쪽으로
수렴.

**확정 방향**:
- **`Source<T>`가 구조적으로 `State<T>`를 만족(단방향 호환)** — State
  자리엔 Source를 넣을 수 있지만 역은 안 됨(Svelte의 `Writable<T> extends
  Readable<T>`와 같은 모양). Source는 State가 주는 모든 것(`:Get()`,
  `:With(...)`, `:Compute(fn)`) 위에 `:Set(value)`/`:Emit()`을
  추가로 가짐([정정, 2026-08-07] `.value`는 State/Source에서 제외되고
  `Get()`으로 통일됨, `.value` 표기는 Ref 전용으로 좁혀짐 — `base/
  bind-system-plan.md` "`:With`/`:Compute` — self 인자도 lazy 핸들로
  통일" 절 참고).
- **`:With`/`:Compute`는 Source에서도 항상 `State<U>`를 반환** — Source
  자신을 변형하는 게 아니라, "Source의 State 뷰를 뽑아 그 위에 파이핑"하는
  것과 동치. 구현은 metatable `__index` 델리게이션(Source의 메소드
  테이블이 State의 메소드 테이블로 폴백)으로 충분 — `Modifier`의 제네릭
  `__index` 트릭(`base/modifier-plan.md`)과 같은 패턴이라 로직 중복이
  생기지 않음.
- **`RefSource<T>` 같은 별도 타입은 불필요, `Store({defaults})`가
  내부적으로 `{[key] = Source(default), ...}`나 다름없게 됨.**
  `defaults`는 **선택**(안 줘도 됨, 순수 편의용) — `store.key`는 이미
  만들어져 있는 키면 그 Source를 그대로 돌려주지만, **아직 안 만들어진
  키면 그 자리에서 `Source(defaults의 해당 값 또는 nil)`을 만들어 저장한
  뒤 돌려줌**([정정, 2026-08-07] eager 생성만으로 충분하다고 서술했던
  이전 버전은 부정확 — Luau 타입은 런타임에 강제되지 않으므로
  `Store<<SomeType>>()`처럼 defaults 없이 만든 뒤 `.Key:Set(v)`를 부르는
  경우, `__index`가 "없으면 그 자리에서 만들어 저장"까지 해주지 않으면
  `.Key`가 `nil`이라 크래시남 — 그래서 Store 생성 시점의 eager 생성(각
  `defaults` 키마다 미리 만들어둠, 이건 여전히 필요)과 `store.key` 접근
  시점의 lazy 생성(아직 없는 키를 그 자리에서 만들어 저장, 이후 재접근은
  재생성 없이 그대로 반환)이 **둘 다** 필요함). `defaults` 테이블 자체는
  라이브 백킹 스토리지로 쓰이지 않고 "아직 안 만들어진 Source를 만들 때
  참고하는 초기값 템플릿"으로 반복 참조될 뿐이라, Store 생성 후 원본
  `defaults` 테이블을 밖에서 바꿔도 문제없음(UB 아님 — 이 항목도
  `bind-system-plan.md`에 남아있던 "defaults 테이블 직접 mutate는 UB"라는
  옛 서술과 충돌해 2026-08-07에 같이 정정함, 아래 참고). 별도 `__values`류
  그림자 실값 저장소도 불필요 — Source 객체 자체가 저장소 역할을 함. 이
  모델은 이전에 검토했던 "State를 weak table로 캐싱" 절충안보다 더 싸다
  (래퍼 생성/캐싱 단계 자체가 사라짐). v1이 모든 값을 Store 하나에
  몰아넣던 습관은 "당시 정적 타입이 없어 단순하게 쓰는 게 편해서"였다는
  게 사용자의 회고적 재평가 — 지금은 타입이 핵심 제약이라 그 전제 자체가
  더 이상 안 맞고, 이번 정리로 Store는 "이름 붙은 Source 모음, 그 이상
  아님"으로 더 단순해짐.
- **구현 스케치(2026-08-07, 성능 근거): eager 생성은 `table.clone(defaults)`
  후 그 결과를 순회하며 각 슬롯을 `Source(v)`로 교체하는 모양이어야 함**
  (`local sources = table.clone(defaults); for k, v in sources do
  sources[k] = Source(v) end` 류) — 빈 테이블을 새로 만들어 키를 하나씩
  넣는 것보다, `table.clone`으로 원본의 해시/배열 슬롯 구조를 그대로
  재사용하는 쪽이 Luau VM 입장에서 더 쌈(직접 해시 슬롯을 처음부터
  구성하는 것보다 기존 슬롯을 복제하는 게 저렴). `Source()`(인자 없이
  호출)는 `Source(nil)`과 동치 — `defaults`에 값이 없는 키를 `store.key`
  접근 시점에 lazy 생성할 때 이 무인자 형태를 씀.
- **이 서브타입 관계는 `quad2-try`에서 기각한 컴포넌트/클래스 OOP 상속과는
  다른 층위.** 그때 금지한 건 사용자가 짜는 컴포넌트 계층 구조(`Class:Extend()`류
  매직)였고, 지금은 두 프리미티브 타입 사이의 구조적 서브타이핑(런타임
  구현 델리게이션 포함)이라 그 금지와 충돌하지 않음.
- **동적 키 폴백(`store "key"`)은 이제 `State<any>`가 아니라 `Source<any>`를
  반환**하는 것으로 자연히 갱신됨(위 "타입 추론 문제" 절과 연동).

**[해소됨, 2026-08-13 첫 실측 라운드]** 핵심 질문(Source가 State를 구조적으로
만족하는 제네릭 메소드 체이닝)은 `08-type-source-satisfies-state.luau`(`luau-test/review-required/`)로
실측 통과 확인됨 — 아래 우려대로 "두 제네릭 타입 별칭이 서로를 참조하는
상호 재귀"는 실제로 위험했지만, 그 아래 제안한 단방향 의존(`State`가
`Source`를 참조 안 함) 회피책이 그대로 맞아떨어짐. **다만 좁은 잔여
케이스 하나는 남음**: `State<T>`가 **자기 자신**을 다른 타입 인자로
재귀 참조하면(`Recursive type being used with different parameters`)
막힘 — 이건 아래 논의 대상이던 "두 타입 간 상호 재귀"와는 다른 문제라
별도로 `question.md` **0-Y** 하단에 추적 중(사용자 방향: 구울 때
인라이닝). 아래는 그 판단에 이른 원래 추론 과정(구분 기준 등)이라 계속
유효한 배경 — `Source<T>`의 `:Compute` 시그니처가 자기 자신(`Source<T>`)과
`State<U>`를 동시에 참조하는 제네릭 메소드라, Luau 솔버가 재귀 타입
조합에서 막히지 않는지가 원래 질문이었음. 구분해서 볼 것:
- **자기 자신을 가리키는 self 타이핑**(`{ Compute: <U>(self: Source<T>, ...) -> State<U> }`
  같은 패턴)은 Luau에서 극히 흔하고 대체로 안전 — 모든 메소드 테이블
  클래스가 쓰는 패턴이라 이것 자체가 위험 신호는 아님.
- **진짜 위험한 건 두 제네릭 타입 별칭이 서로를 참조하는 상호 재귀**
  (`Source<T>` 정의가 `State<T>`를 참조하고, `State<T>`도 거꾸로
  `Source<T>`를 참조하는 경우) — 이게 Luau 솔버가 알려진 대로 취약한
  패턴. **`State<T>`가 `Source`를 전혀 참조하지 않도록 먼저 독립적으로
  정의하고, `Source<T>`만 `State<T>`를 참조하는 단방향 의존으로 두면**
  이 위험한 패턴 자체를 피할 수 있어 보임 — 다만 이것도 추론이라 실제
  Luau로 확인 전엔 확정 아님.
- 사용자는 `&`(교차 타입) 조합보다 **타입을 손으로 펼쳐 쓰는(flatten)
  쪽을 선호**(엔지니어링 비용을 감수하더라도 솔버 안정성 우선) — 이건
  런타임 구현의 델리게이션(위 항목)과는 별개 축이라 서로 충돌 안 함:
  타입은 펼쳐 쓰고 구현은 공유하는 조합이 가능함.
- `ROADMAP.md` M0의 "Store/State propagation" 스파이크 항목에 이 구체적
  케이스(Source가 State를 만족하는 제네릭 메소드 체이닝)를 포함해서
  검증할 것.

**이름 주의 — [해소됨, 2026-08-12 스무 번째 세션]**: `Source`/`State`라는
이름이 한때 용어 정리 대상(특히 `State`)이었으나, **`State`는 현재 이름
그대로 유지로 최종 확정됨**(`Computed`/`Derived`/`Pipe` 전부 기각 — 근거는
`bind-system-plan.md` "네이밍 — `Compute`가 `-ed`가 아닌 이유" 절과
`question.md` 1번). 더 이상 가칭이 아님.

## Store 값 설정 문법 — `myStore.key = value` 폐기, `source:Set(value)`로 전환 (2026-08-06 후속 세션, 정정)

**이전 버전("v1 인체공학 유지, `__newindex` 기반 `myStore.key = value`
그대로")은 폐기됨.** 아래 "Source가 State를 만족함" 절의 타입 설계와
맞물려 재검토된 결과:

1. **타입 대칭성**: `store.key`가 이제 `Source<T>`를 직접 반환하는
   평범한 레코드 필드(`{key: Source<number>}`)로 타이핑되는데, 레코드
   필드는 읽기/쓰기 타입이 같아야 Luau 구조적 타이핑이 깨끗하게 성립함.
   `store.key = value`(raw `T` 대입)를 유지하면 읽기(`Source<T>`)/쓰기(`T`)
   타입이 갈려 mismatch가 남음 — `store.key:Set(value)`로 통일하면 필드
   타입이 항상 `Source<T>`로 대칭적이라 문제 자체가 안 생김(사용자 지적).
2. **의미론적 정직성**: `=` 대입 문법은 관례상 "그 자리에서 즉시 확정되는
   부작용 없는 값 쓰기"를 암시하는데, quad의 실제 동작은 **lazy** —
   `Set`은 무효화 신호만 쏘고, 실제 재계산은 나중에 누군가 관측(`Get()`)할
   때만 일어남("Emit으로 필요한 사람 있어? 하고 물어보고, 있어야 진짜
   계산 시작"). 이건 `=`가 암시하는 "즉시 커밋"과 정서가 안 맞고, 메소드
   호출(`:Set()`)이 "이건 프로세스를 트리거하는 연산"이라는 걸 더 정직하게
   신호함(사용자 확정 논거).
3. `:Set()`은 이미 확정된 "값을 바꾸는 연산엔 `:` 체이닝 허용" 원칙(`base/
   architecture.md`)에도 자연스럽게 들어맞음 — 문법 자체가 새로 생기는 게
   아니라 기존 원칙의 정상적인 적용.

**남는 것**: `myStore "key"`(문자열 커링)는 이미 3차 라운드에서 동적 키
전용 미타입 폴백으로 격하돼 있었으므로 이번 정정과 무관하게 그대로 유지.
`:` 체이닝 원칙도 `:Set()` 자체가 그 사례라 유지.

`base/architecture.md`의 "복사 구현 지양, 팩토리 함수로 대체" 원칙과 함께
읽을 것 — v1의 문제는 metatable 체이닝으로 매번 새 테이블을 할당하며
"불변 빌더"를 흉내낸 것이었지, `:` 체이닝 문법 자체나 커링 문법 자체가
아니었음.

## Source 값을 직접 mutate한 뒤 전파 — `:Emit()` (2026-08-06 후속 세션, 호출부 정정)

**결정**: Source가 들고 있는 값을 새 값으로 교체하지 않고 제자리에서
mutate한 뒤, `:Emit()`으로 무효화 신호만 별도로 쏘는 것을 **Source
원천(store가 직접 들고 있는 값)에 한해 허용**한다.

**[정정, 같은 세션 후반]** 원래 `Store:Emit(key)`(Store에 key를 넘겨
호출)로 적혀있었으나, 아래 "Source가 State를 만족함" 절에서 `store.key`
자체가 Source를 직접 반환하는 것으로 바뀌면서 `Emit`도 Source의 평범한
메소드로 이동 — `store.key:Emit()`(key 인자 불필요, 이미 손에 든 Source
핸들에 바로 호출). `Store:Emit(key)`라는 별도 경로는 유지할 이유가
없어져 폐기(같은 걸 하는 두 번째 경로를 남기지 않는다는 이번 세션 전반의
원칙과 일치 — `store.key = value` → `store.key:Set(value)` 정리와 같은 결).

**존재 이유(우선순위순)**:
1. **clone이 아예 불가능한 값이 있음.** userdata나 외부 라이브러리
   객체(엔진 Instance 등)는 `table.clone`으로 새 값을 만들 수 없음 —
   이런 값은 "새 값을 만들어 Set"이라는 대안 자체가 없으므로, in-place
   mutation + `Emit`이 변경을 전파하는 유일한 수단.
2. Lua의 불변 업데이트가 verbose함(JS의 `{...t, x=1}` 같은 문법이 없어
   `table.clone` 후 필드 덮어쓰기 + 재대입 필요) — 이걸 줄여주는 부차적
   이득도 있지만, 이게 주된 이유는 아님(1번이 진짜 이유).

**왜 새 구멍이 아닌가**: `Get()`은 원래도 라이브 테이블 레퍼런스를
돌려주므로, 그 레퍼런스를 mutate하는 것 자체는 `Emit` 유무와 무관하게
Lua에서 항상 가능한 일. `Emit`이 없으면 그 mutation은 "조용히 반영 안
되는"(dependent가 재계산 안 됨, UI가 stale한 채 멈춤) 상태로 남을 뿐이라
오히려 `Emit` 없는 쪽이 더 나쁜 버그 클래스 — `Emit`은 이미 가능한
mutation에 정식 신호를 붙여주는 것뿐.

**남는 캐비엇(문서에 반드시 명시)**: `Get()`으로 이전에 그 테이블을
읽어서 어딘가(로컬 변수, 다른 코드가 들고 있는 참조)에 캐시해둔 게
있다면, mutation 순간 그것도 같이 바뀐다 — 새 테이블이 아니라 같은
레퍼런스라서. **`Get()` 결과를 나중 비교(`==`)나 diff 캐시 용도로 들고
있으면 안 됨 — 항상 다시 `Get()`할 것.**

**하드 경계 — Source 원천에만 허용, 중간/파생 State에는 없음.** `:With`/
`:Compute`로 만들어진 파생 State에는 `Emit`이라는 개념 자체가 없다 —
허용하면 "이 State의 현재 값이 뭘 근거로 계산됐는가"를 아무도 설명할 수
없게 되어(quad-debug가 추적하려는 "무엇이 무엇을 계산했는가" 그래프가
깨짐) 디버깅이 사실상 불가능해짐. State의 값은 항상 "선언된 Compute
함수를 실제로 실행한 결과"여야 한다는 불변식이 깨지면 안 됨. 무거운
파생 객체를 재사용하고 싶은 경우(Compute의 결과 자체가 무거운 userdata인
경우)를 위한 별도 메커니즘은 `base/bind-system-plan.md`의 "`:Compute(fn)`의
선택적 두 번째 인자 — `previous`" 절 참고 — 이건 `Emit`과 다른 메커니즘.

**따름정리 — `Store<T>`의 `T`는 Modifier가 될 수 없음.** Modifier는
정적 flatten으로 dispatch와 완전히 별개인 단계에서 처리되고
(`base/modifier-plan.md`) — Store/State/dispatch 경로엔 애초에
Modifier용 processor가 없음. **[정정, 2026-08-09 세션]** `State<Modifier>`
조합은 "UB, 가능하면 타입 차단"이 아니라 **명시적 `error`로 확정**
(`modifier-plan.md` 7번) — `isModifier` predicate를 `Source:Set()`/
Store 생성 시 eager `Source(default)`/State의 `:Compute` 결과 캐싱
지점에서 확인해 런타임에 직접 막음, 타입 차단은 되면 좋은 보너스일
뿐 유일한 방어선이 아님. **[2026-08-06 후속 세션 추가]** Source가
State를 구조적으로 만족하게 되면서 이 제약은 `Source<Modifier>`(Store를
거치지 않는 독립 `Source(someModifier)`)에도 동일하게 적용됨을 명시 —
Source가 State 계약을 만족하는 이상 같은 이유(Modifier용 processor
부재)가 그대로 적용되고, 별도로 다시 논증할 필요 없음. 위 "하드 경계"와
같은 이유로, `Emit`이 Modifier의 정적 flatten과 충돌할 걱정 자체가
성립하지 않음(둘이 만날 지점이 없음).

## 여러 스토어 값을 묶어 처리하는 것 (dependency array) — 확정

`useEffect`처럼 여러 store 값을 디펜던시로 묶어 파생값을 계산하고 싶다는
요구가 있었음(v1의 `myStore "a,b"` 콤마-조인 문자열 방식은 폐기 대상 —
`reference/quad-v1-architecture.md`의 "문자열 DSL" 문제점 참고). **v1의
`:Add`/`:With`/`:Tween`처럼 값을 직접 가공하는 이름 붙은(named) 체이닝 연산은
만들지 않음** — 대신 일반 함수를 받아 처리. (주의: 아래의 v2 `:With(...)`는
이름만 같을 뿐 v1의 `:With`와는 다른 연산임 — v1은 "함수/테이블에서 값을
가져오는" 가공 연산이었고, v2는 그냥 "여러 State를 의존성으로 모으는" 수집
연산.) 최종 형태는 `:With(...)`로 의존성을 모으고
`:Compute(fn)`으로 파생 State를 만드는 것으로 확정 — `Store.Combine({a,b},
fn)`류 포지셔널 인자 방식은 기각됨. 정확한 lazy 인자 규칙(self/with 값 둘 다
State 핸들로 넘기고 `:Get()`을 실제로 읽을 때만 계산)은 `base/bind-system-plan.md`의 "Store/State/Source 온톨로지" 절 참고.

**여러 소스를 한 번에 바꿔도 파생값 재계산/재대입이 한 번만 되게 하려면
`Blocker` 참고.** 위 `:With`+`:Compute`만으로는 "state1, state2를 연달아
Set하면 결합된 파생값이 두 번 재계산/재대입된다"는 문제(즉시 pull하는
store-bind 소비자 기준)는 안 풀림 — 이건 별도 확정 프리미티브
`base/blocker-plan.md`가 다룸(State 개발과 같은
마일스톤, `ROADMAP.md` M3에서 함께 구현). lexical `Batch(fn)`으로 풀려던
초기 시도는 코루틴 yield 위에서 구조적으로 위험해 기각됨 —
`archive/batch-rejected.md` 참고.
