# Source / State — 반응형 코어 (값의 원천과 그 위의 캐시 레이어)

> **📄 [2026-08-14 신설] `bind-system-plan.md` 3단계 분할 + store-semantics.md
> 흡수.** `bind-system-plan.md`(반응형 코어)와 store-semantics.md(온톨로지
> 배경)에 같은 내용이 반씩 흩어져 서로를 "상세는 저쪽 참고"로 가리키고 있던
> 걸 한 군데로 합쳤음 — **내용/결정은 이동·병합 자체로는 안 바뀜**. Store
> 고유의 것(이름 붙은 Source 모음, `defaults`, dot-access 타이핑, 값 설정
> 문법)은 짝 문서 **`base/store-plan.md`**로 갈라졌음.
>
> | 갈라진 곳 | 담는 것 |
> |---|---|
> | **이 문서** | `Source`/`State` 온톨로지·서브타입, 전파 모델, `:With`/`:Compute`/`:Apply`, `previous`, `:Emit`, `Observer`, 구독/생명주기 게이트 |
> | `base/store-plan.md` | Store = 이름 붙은 Source 모음 — `defaults`, **명시적 초기화**(2026-08-25, 옛 eager/lazy 이중 모델 폐기), `store.key` 타이핑, `:Set()` 문법 |
> | `base/dispatch-core-plan.md` | 디스패치 코어(핸들러 계약, `chains`, 하강 diff) |
> | `base/bind-system-plan.md` | 인스턴스 생성/이벤트 네이밍 인체공학 + 분할 색인 |

**상태**: base — 전파 모델/`:Compute` 인자 규칙/State 쓰기 금지/Slot 생존
확인/타입 추론(dot-access) 전부 2026-08-04 세 라운드에서 `AskUserQuestion`으로
확인 완료, 이후 세션들에서 `:With` 새 노드화·trailing args·`Observer`/
`:Subscribe`·이중 바인딩 게이트까지 확정. 남은 건 정확한 함수/생성자
이름뿐(구현 단계). 원본: `.claude/initreq/raw-userinput.md`
"state는 어떻게 구현하는가" / "스토어는 스토어를 저장 가능한가" 절.

> **[2026-08-13 열세 번째 세션, 해소]** self/deps를 lazy `State` 핸들로
> 넘기는 `:Compute`/`:With` 콜백 계약은 한때 미해결(구 `question.md`
> 0-Y)이었으나 **그대로 유지로 확정**됨. 남은 것은 quad 설계 문제가
> 아니라 Luau의 현 한계(파생 State의 반환 타입이 정적으로 검증되지
> 않아 사용처에서 명시 주석 바인딩이 필요) — 전역 규약은
> **`base/typing-limits.md`**, 실측 근거는 `audit/type-recursion-issue/`.

## 핵심 온톨로지

- **Source** — 실제 값이 존재하고 변경될 수 있는 단일 지점(v1의 "값의 근원").
  **구조적으로 State를 만족(단방향 호환)** — `:Get()`/`:With`/`:Compute`
  전부 지원 위에 `:Set(value)`/`:Emit()` 추가.
- **Store** — Source들의 이름 붙은 모음, 그 이상 아님(상세는 짝 문서
  `base/store-plan.md`).
- **State** — source(또는 다른 state)의 결과를 캐싱만 하는 존재, 자기 고유의
  독립적 value 개념이 없음. `state(state)`로 기존 state의 결과를 받아 새
  state를 만들어 분기 가능 — 이게 사실상 Unix 파이프 영감의 "State끼리
  합성 가능"이라는 원래 목표를 구현하는 방식.

### 정정(2026-08-04 검증 라운드): `State` 프리미티브는 실제로 필요하다

**이전 버전("State 프리미티브는 만들지 않는다")은 틀렸음 — 사용자가
검증 라운드에서 직접 정정.** 정확한 모델은 위 온톨로지 그대로이고, 그
중에서도 다음 두 가지가 핵심:

- 단일 값에 대한 state 생성은 store가 자동으로 해주지만, 그 결과를 다시
  분기하고 싶으면(하나의 파생 스트림에서 여러 소비자가 각자 다른 추가
  compute를 얹고 싶은 경우) `state(state)`처럼 기존 state의 결과를 받아
  새 state를 만드는 조합이 필요.
- **[정정, 2026-08-06 후속 세션] store에서 값을 얻는 연산(`store.key`)은
  Source를 직접 반환한다 — 더 이상 별도 State 인스턴스를 감싸서 반환하지
  않음.** 이 항목의 원래 버전("항상 새 state 인스턴스를 반환")은 틀림 —
  Store가 별도 wrapper 없이 자기 안에 만들어둔 Source를 그대로 돌려주는
  쪽으로 재정리됨(아래 "Source가 State를 만족함" 절).

**`Pipe`(quad2-try 후보)는 폐기 확정** — 별도 `Pipe` 타입에 소유권/버전
가드를 넣어 재설계하는 대신, State 자체가 파이핑 결합체이고
`state(state)`로 분기하는 위 모델로 완전히 대체됨. quad의 Unix 파이프
영감(원래 동기)과 `Pipe`/`fromState` 후보 검토 경위는
`archive/quad2-try-research-findings-rejected.md`로 이전됨 —
**확인된 죽은 접근(OOP 상속 `Base:Extends`/`--&` 커스텀 파서/Slot 빈 스텁/
`Pipe` copy-on-write 절충안)은 절대 반복 조사하지 말 것.**

## Source가 State를 만족함 — 구조적 서브타입, RefSource 개념 폐기 (2026-08-06 후속 세션)

**배경**: `store.key`가 매번 새 State를 감싸 반환하던 이전 모델의 타입
문제(레코드 타입 `{key: State<number>}`가 읽기/쓰기 비대칭이라 Luau
타이핑이 안 맞음)를 풀다가 사용자가 제안한 더 근본적인 재구성.
`RefSource<T>`(store 슬롯을 가리키는 전용 타입)를 따로 만드는 중간안도
검토했으나, 최종적으로 **Source 자체가 State를 만족하도록 만들고,
RefSource라는 별도 타입은 폐기**하는 쪽으로 수렴.

**확정 방향**:
- **`Source<T>`가 구조적으로 `State<T>`를 만족(단방향 호환)** — State
  자리엔 Source를 넣을 수 있지만 역은 안 됨(Svelte의 `Writable<T> extends
  Readable<T>`와 같은 모양). Source는 State가 주는 모든 것(`:Get()`,
  `:With(...)`, `:Compute(fn)`) 위에 `:Set(value)`/`:Emit()`을
  추가로 가짐([정정, 2026-08-07] 프로퍼티 읽기 표기는 State/Source에서 제외되고
  `Get()`으로 통일됨, 그 표기는 Ref의 `.Value` 전용으로 좁혀짐 — 아래
  "`:With`/`:Compute` — self 인자도 lazy 핸들로 통일" 절 참고).
- **`:With`/`:Compute`는 Source에서도 항상 `State<U>`를 반환** — Source
  자신을 변형하는 게 아니라, "Source의 State 뷰를 뽑아 그 위에 파이핑"하는
  것과 동치. 구현은 metatable `__index` 델리게이션(Source의 메소드
  테이블이 State의 메소드 테이블로 폴백)으로 충분 — `Modifier`의 제네릭
  `__index` 트릭(`base/modifier-plan.md`)과 같은 패턴이라 로직 중복이
  생기지 않음.
- **`RefSource<T>` 같은 별도 타입은 불필요, `Store({defaults})`가
  내부적으로 `{[key] = Source(default), ...}`나 다름없게 됨** — Store
  쪽 상세(**[2026-08-25]** 명시적 초기화 — 옛 eager/lazy 이중 모델 폐기,
  `defaults`의 성격, 구현 스케치)는
  `base/store-plan.md`가 소스. 별도 `__values`류 그림자 실값 저장소도
  불필요 — Source 객체 자체가 저장소 역할을 함. 이 모델은 이전에
  검토했던 "State를 weak table로 캐싱" 절충안보다 더 싸다(래퍼 생성/
  캐싱 단계 자체가 사라짐).
- **⭐ [2026-08-21 확정] `Source`는 `Epoch` 인터페이스도 같은 방식으로
  구조적으로 만족한다** — `type Epoch = { Revision: number }`이고, `:Set()`/
  `:Emit()`이 그 `Revision`을 **갱신한다**(직전과 다른 값으로 — `Epoch`
  계약이 요구하는 건 "다르다"뿐이라 방향은 계약이 아니고, 확정된 연산
  `bit32.bnot(-rev)`는 실제로 **감소**한다). **`Revision`은 공개 필드여야
  한다** — 비공개면 구조적 만족이 타입 레벨에서 성립하지 않는다(사용자:
  *"그래야 타입 상 `Source` 가 `Epoch`를 만족해요."*). `Store`와 달리
  `Source`는 키가 사용자 것이 아니라 예약 이름이 늘어도 충돌하지 않는다.
  런타임 판별은 `SourceBrand`와 **동시에** `EpochBrand`에 등록하는 것으로
  하고(다중 태깅, `base/brand-plan.md`), `State`를 만족하는 관계와 달리 이건
  포함 관계가 아니라 **다른 축의 계약**이라 predicate 합성으로는 표현되지
  않는다. 계약 전량은 `base/state-epoch-plan.md` §2가 소스.
- **이 서브타입 관계는 `quad2-try`에서 기각한 컴포넌트/클래스 OOP 상속과는
  다른 층위.** 그때 금지한 건 사용자가 짜는 컴포넌트 계층 구조(`Class:Extend()`류
  매직)였고, 지금은 두 프리미티브 타입 사이의 구조적 서브타이핑(런타임
  구현 델리게이션 포함)이라 그 금지와 충돌하지 않음.
- **동적 키 경로도 `State`가 아니라 `Source`를 반환**하는 것으로 자연히
  갱신됨 — **[정정, 2026-08-18]** 그 경로는 `store "key"` 문자열 커링이
  아니라 `store:Of<<T>>(name): Source<T>`다(**[2026-08-25]** 옛 이름
  `GetDynamic` — 문자열 커링은 기각,
  `base/store-plan.md`의 "타입 추론 문제" 절).

**[해소됨, 2026-08-13 첫 실측 라운드]** 핵심 질문(Source가 State를 구조적으로
만족하는 제네릭 메소드 체이닝)은 `08-type-source-satisfies-state.luau`로
실측 통과 확인됨 — 아래 우려대로 "두 제네릭 타입 별칭이 서로를 참조하는
상호 재귀"는 실제로 위험했지만, 그 아래 제안한 단방향 의존(`State`가
`Source`를 참조 안 함) 회피책이 그대로 맞아떨어짐. **다만 좁은 잔여
케이스 하나는 남음**: `State<T>`가 **자기 자신**을 다른 타입 인자로
재귀 참조하면(`Recursive type being used with different parameters`)
막힘 — 이건 아래 논의 대상이던 "두 타입 간 상호 재귀"와는 다른 문제로,
**[2026-08-13 열세 번째 세션 결론] Luau의 현 한계로 확정**되어
`base/typing-limits.md` 1번이 담당함(구 `question.md` 0-Y는 해소).
당시 검토됐던 "구울 때 인라이닝"(T별 코드 생성) 방향은 **채택 안 함** —
제네릭 자체를 없애버려 나중에 Luau가 고쳐져도 수혜를 못 받기 때문.
아래는 그 판단에 이른 원래 추론 과정(구분 기준 등)이라 계속
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

**이름 주의 — [해소됨, 2026-08-12 스무 번째 세션]**: `Source`/`State`라는
이름이 한때 용어 정리 대상(특히 `State`)이었으나, **`State`는 현재 이름
그대로 유지로 최종 확정됨**(`Computed`/`Derived`/`Pipe` 전부 기각 — 근거는
아래 "네이밍 — `Compute`가 `-ed`가 아닌 이유" 절과 `question.md` 1번).
더 이상 가칭이 아님.

## 일반 원칙 — 독립 존재 가능한 프리미티브 vs 원천에 종속된 파생 데이터 (2026-08-06 후속 세션)

위 "State는 자기 고유의 독립적 value 개념이 없다"는 관찰을 일반 원칙으로
확장(사용자 관찰): quad의 개념들은 두 부류로 갈린다.

- **독립 존재 가능한 프리미티브** — Source, Ref, Store, Modifier. 다른
  무언가 없이 그 자체로 `Type(args)` 팩토리 함수로 만들어짐(`Source(default)`/
  `Ref(default)`/`Store({defaults})`/`Modifier()`, 아래 "생성자
  스타일 확정" 참고 — `Modifier()`는 빈 인스턴스, 실제 필드는
  `mod:UICorner(8)`류 체이닝으로 그 위에 얹음).
- **원천에 종속된 파생 데이터** — State, Observer. 자기 혼자 존재할 수
  없고 항상 특정 원천(Source/다른 State)에 의존 — 그래서 이 둘은 자유
  함수 생성자가 없고, 항상 원천에 대한 메소드 호출로만 얻어진다
  (`store.key`/`state:Compute(fn)`/`state:With(...)` → State,
  `state:Observer(fn)` → Observer). "클래스 같은 독립 타입"이라기보다
  "State를 관측·핸들링하는 데이터"에 가까움.

이게 아래 `state:Observer(fn)`가 메소드고 `Observer(state, fn)`라는 자유
함수가 없는 더 근본적인 이유 — 단순히 "읽기 편해서"가 아니라 Observer
자체가 State처럼 원천 없인 존재할 수 없는 카테고리라서. 앞으로 새 개념을
추가할 때도 이 두 부류 중 어디에 속하는지가 생성자 모양(자유 함수 팩토리
vs 원천에 대한 메소드)을 결정하는 기준으로 쓸 수 있음.

**세 번째 카테고리 — Handler는 둘 중 어디에도 안 낌(2026-08-08 두 번째
세션, 명시화).** `Handler`(`isHandlable`/`priority`/`process` 3종 계약 —
`process`가 자기 retract 클로저를 반환, 2026-08-13 다섯 번째 세션 정정,
`base/dispatch-core-plan.md` "핸들러 계약" 절)는 위 분류가 다루는
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
왜 프리미티브가 아니라 탑레벨 싱글톤인지는 `base/dispatch-core-plan.md`의
"Dispatch는 프리미티브가 아니다" 절 참고.

## 전파 모델 확정: push-invalidate(신호만) / pull-recompute(`Get()` 시점에만)

**Fusion식 eager 노드·생성순 정렬은 안 만듦.**

- `Source`는 값이 바뀌면 구독 중인 State들에게 **"무효화됐다"는 신호만
  쏜다** — 새 값 자체는 신호에 안 실림("state는 세터를 내보내기보다
  업데이트 됐다는 신호만 쏜다" — 사용자 확정 문구).
- **⭐ [2026-08-21 재확정 — 판정 주체가 `invalid`에서 `Epoch` 리비전으로 바뀜]
  emit은 자기 `invalid` 상태와 **무관하게** 전파되고, 접히는 것은 오직
  **같은 `Epoch`의 같은 리비전이 두 번째로 도착했을 때**뿐이다.** 판정 규칙
  전량은 **`base/state-epoch-plan.md`가 소스** — 여기선 이 절의 다른 서술과
  어긋나지 않게 요지만 적는다. 여기 있던 "emit은 *항상* 전파된다"는 무조건
  서술의 역전 원문은 `archive/always-propagate-no-dedup-superseded.md`.
  - **"내 캐시가 낡았다"는 표시의 역할은 그것 하나뿐**(**[2026-08-25 정정]**
    한때 *"구현 이름 `rawInvalid`"*라 적었는데 그 필드는 **폐기**됐다 —
    지금은 `cacheTargetCount`/`cacheCurrCount` 카운터 쌍이고, 재계산 도중
    도착한 무효화와 `fn` 예외를 같이 덮는다. `base/state-epoch-plan.md`) — 전파를 제어하는 장치가 **아님**. `:Get()`이 호출되면
    상류로 올라가 재계산하고, 그 결과를 캐시에 넣고, 플래그를 끈다.
  - **⚠️ `invalid`로 전파를 접는 것은 지금도 금지다.** 2026-08-14에 그
    방식이 폐기된 이유는 `:Get()`을 호출하지 않는 `Observer`(아래
    "`state:Observer(fn)`" 절이 명시적으로 허용하는 사용법)가 **한 번 울고
    영구히 침묵**하기 때문이고, 그 실패 모드는 지금도 유효하다(원문은
    `archive/invalidate-dedup-propagation-reversed.md`). 리비전 비교엔 그
    모드가 없다 — 매 `Set`이 **새 리비전**이라 항상 통과하고, 접히는 건
    **다이아몬드에서 같은 리비전이 두 경로로 도착한 두 번째**뿐이다.
  - **emit 전파를 늦추거나 흡수할 수 있는 건 위 dedup 외엔 명시적인 게이트
    요소뿐** — `state:Gate(setup)`(`base/gate-plan.md`)와 그 위에 얹히는
    `Blocker`(`base/blocker-plan.md`), `base/debounce-throttle-plan.md`의 시간
    기반 정책. **평범한 State는 그 외의 이유로 신호를 삼키지 않는다.**
- 실제 재계산은 `:Get()`이 호출되는 시점에만 일어남 —
  "필요할 때 계산" 원칙(사용자 확정). Fusion의 `timeliness="eager"` 노드/
  생성순 정렬 장치는 만들지 않음 — quad엔 그런 다단계 즉시 재계산이 필요한
  소비자가 없다는 판단. 유일하게 "즉시 반응해야 하는" 소비자는 store-bind
  pluggable 핸들러(`base/dispatch-core-plan.md`의 "확정된 디스패치 모델" 절)인데, 이건 무효화 신호를
  받는 즉시 자기가 알아서 `Get()`을 호출해 pull하는 방식으로 충분함 —
  State 스스로 "지금 나를 보는 eager 소비자가 있나" 같은 부기가 전혀
  필요 없음.
- `emit`은 이 무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함
  ("emit 필요 여부" 열린 질문은 이걸로 해소). 전파가 잦아도 부담이 작은
  이유이기도 함 — 신호 하나가 트리를 훑는 비용이지 재계산 비용이 아님.

### ⭐⭐ 전파 루프 — 확정 의사코드 (2026-08-25 신설, 7라운드 `H-56`)

지금까지 이 루프는 **산문으로만** 있었고, 그 공백에서 실제 결함이 나왔다 —
`base/lifecycle-pattern.md`의 *"발화 시 각 구독자에 대해 `canExecute(observer)`를
확인하고, 거짓이면 그 구독자만 조용히 건너뜀"*을 글자 그대로 짜면
**자식 State 노드가 전부 걸러진다**(자식은 `bindLifetime`된 적도
`:Subscribe()`된 적도 없어 `canExecute`가 항상 거짓이다). 그러면
`A:Set()`이 `A:With(...)`/`A:Compute(...)` 노드에 **한 번도 안 닿고**
파생 State 아래의 모든 Observer가 침묵한다.

```lua
function State:_emitDown(from)
    -- H-23 확정: pairs 순회 중 새 키 추가는 미정의라 먼저 배열로 스냅샷
    local snap = {}
    for sub in self._subs do snap[#snap + 1] = sub end
    for _, sub in ipairs(snap) do
        sub:_receive(from)            -- ⭐ [2026-08-28 확정, `H-163` 대화] 구독자는 전부 **`EmitReceive`**
    end                               --   (`:_receive(from)` 하나짜리 인터페이스 — `Epoch`과 같은 급).
                                      --   State 노드(`ComputeNode`/`GateNode`)는 §4 규칙, Observer는 아래
                                      --   `Observer:_receive`. 한때 여기서 `isState`/`canExecute`로 갈라
                                      --   Observer의 `fn`을 직접 부르고 `_rerunRequired`까지 세웠는데
                                      --   **계층 간 지식이 섞여** 있었다 — 사용자: *"State:_emitDown 에
                                      --   … 계층간 확인 구조가 있거든? 그냥 Epoch 처럼 EmitReceive 를
                                      --   만들고, 각 state 나 observer 측에서 해당 emit 을 처리하는 함수를
                                      --   만들어주는게 맞는듯. _rerunRequired 를 여기서 설정하는게
                                      --   문제가 되어보여(계층간 지식이 분리 안되어있음)."*
end

-- Observer 쪽 `EmitReceive` 구현(`Observer.luau`). 판정과 홀드가 **여기** 산다.
function Observer:_receive(from)
    if canExecute(self) then
        self.fn(self._state, self, from)   -- ⭐ (리시버 State, Observer 자신, 출처)
    else
        self._rerunRequired = true         -- [2026-08-28 `H-159`] 묶이기 전의 변경은 홀드 — 묶일 때 1회
    end                                    --   (Effect의 내부 Observer도 이 경로 — `fire`가 `fn`이다)
end

-- ⭐ [2026-08-28 확정] 캐치업 — 묶이거나 구독될 때 홀드가 있었으면 1회. 출처 없음(`nil`)이라
--   `_receive`가 아니라 별도 내부 메소드(사용자: *"observer 계열의 rerun 느낌이네. 외부적으로
--   쓸 일은 안 보여서"* — 공개 표면 아님). `bindLifetime`·`Subscribe`·`WeakSubscribe`가
--   부르는 유일한 자리 — 네 곳이 각자 세 줄을 반복하던 것을 여기로(감사 4라운드 지적).
function Observer:_catchUp()
    if self._rerunRequired then
        self._rerunRequired = false
        self.fn(self._state, self, nil)
    end
end

-- `EmitReceive` — 구독자 집합 `_subs`의 원소가 만족하는 인터페이스(`Epoch`처럼 구조적).
type EmitReceive = { _receive: (self: any, from: Epoch | EpochSet) -> () }
-- 구현: `ComputeNode`/`GateNode`(state-epoch-plan.md §4 규칙 1~3 / gate-plan.md 조립 절), `Observer`(위).

-- `state:Observer(fn)` 생성자 — 순서가 계약이다(**[2026-08-28 `H-159`/`H-164`]**).
function State:Observer(fn)
    local o = setmetatable({ fn = fn, _state = self, _rerunRequired = true }, Observer)
    ObserverBrand:register(o)
    o.fn(self, o, nil)                 -- (1) 등록 시점 즉시 1회 — 출처 없음(`nil`)
    o._rerunRequired = false           -- (2) 설치 발화가 플래그를 내린다(사용자 확인)
    self._subs[o] = true               -- (3) 그다음 구독자 집합에 — 순서를 뒤집으면 (1)이 자기
    return o                           --     State를 Set할 때 그 emit이 자신의 _receive에 와 플래그가 선다
end
```

- **⭐⭐ [2026-08-26 확정, 8라운드 `H-109`/`H-110`] Observer `fn`의 시그니처는
  `fn(targetState, self, emitFrom)` 세 자리다.** 여기 한때
  `sub.fn(sub, from)`이라고 적혀 있었는데(2026-08-25 `H-56` 반영 시점),
  그건 같은 문서의 *"`self`는 이 Observer가 붙은 State의 **lazy 핸들**"*
  계약과 정면으로 충돌했다 — 그대로 짜면 `H-61`이 확정한 무인자
  `state:Observer()`의 내부 콜백(`self:Get()`)이 "attempt to call missing
  method Get"으로 즉사한다(Observer엔 `:Get()`이 없다). 확정된 자리 배치:
  | 자리 | 무엇 | 왜 |
  |---|---|---|
  | 1 | `targetState` — 이 Observer가 붙은 State의 lazy 핸들 | 기존 계약 그대로. `:Compute`의 `fn(self, ...)`와 같은 모양 |
  | 2 | `self` — Observer 값 자신 | 핸들 조작(`:Unsubscribe()` 등) |
  | 3 | `emitFrom: Epoch \| EpochSet` | `EpochMap:Update(from)`에 그대로 넘어간다 |
  - **왜 값이 앞인가(사용자 확정)** — `Ref` 콜백 `fn(value, ref)`와 같은
    원칙이다: 실제로 쓰이는 값이 앞자리에 온다.
  - **⭐ 그래서 Observer는 리시버를 강하게 든다 — `observer._state = state`**
    (생성 시점). 루프가 그 필드를 읽어 넘기므로 **이게 곧 Observer의
    `_hold` 상당**이고, `H-110`(Observer→상류 강참조가 어디에도 없어
    `:Subscribe()`의 *"GC되지 않고 영원히 계속 실행됨"* 계약이 다시 열림)이
    같은 결정으로 닫힌다. 그 전엔 `fn` 클로저가 리시버를 **우연히 캡처**하는
    것 말고 근거가 없었고, 캡처가 없는 확정 사례가 이미 둘이었다
    (`H-61`의 내부 콜백, `Effect`의 dep 콜백).
  - **⚠️ `Ref` 콜백과 통합하지 않는다(사용자 확정)** — 두 콜백은 이질적
    개념이다: *"observer 에는 epoch 란게 존재하지 않음. emit 으로 온 epoch 를
    넘겨줄 뿐, 그러나 ref 는 그 자체로 epoch임"*. 그래서 `Effect`는 dep
    종류별로 클로저를 **따로** 단다(`base/effect-plan.md`).
- **⚠️ [2026-08-26 주석 정정, `/code-review high`] 위 `elseif` 가지의 주석이
  한때 "Observer / Effect"였는데, `_state`는 **Observer에만** 있다** —
  `Effect` 핸들의 강한 상류는 `_deps`이고 `_state` 필드가 없다. `Effect`는
  `_subs`에 직접 들어가지 않고 **자기 내부 Observer를 통해** 이 루프에
  닿는다(생성자가 dep마다 `d:Observer(onStateFire)` + `WeakSubscribe`).
  주석대로 `Effect`를 `_subs`에 직접 넣으면 사용자 `fn`이 리시버 자리에
  `nil`을 받는다.
- **구독자 집합은 하나**(`self._subs`, weak-키)이고 **원소는 Observer
  값**이다 — emit 클로저가 아니다. `bindLifetime(inst, observer)`가 Observer
  **값**을 키로 `BindData`에 gcconn을 복사하므로, 집합에 클로저를 담으면
  `canExecute(클로저)`가 identity가 달라 **항상 거짓**이 된다.
  `base/lifecycle-pattern.md` (4)의 *"Observer의 emit 클로저"* 표현은 이
  결정에 맞춰 고쳤다.
- **자식 State는 `canExecute`를 안 본다** — 그건 "이 값이 어떤 Instance에
  묶여 살아 있는가"를 묻는 판정이고, 자식 노드의 생존은 위
  "해소됨 — 중간 State는 `_hold`로 살아남는다" 절의 `_hold` 불변식이
  책임진다.
- **두 집합으로 나누는 안은 기각** — emit마다 스냅샷이 두 번이 되고
  (아래 비용 참고) 등록/해제 경로도 둘로 갈린다.
- **비용**(7라운드 `H-92`): 이 스냅샷은 **파동이 지나는 노드 수만큼** 배열을
  할당한다. `base/state-epoch-plan.md` §2가 테이블 리비전을 기각한 근거가
  *"`Set` 한 번마다 테이블 하나를 할당"*이었으므로, 그 문서 §7의 비용
  서술은 이 할당을 셈에 넣어 실제와 맞춰야 한다. **정확성 문제는
  아니다** — 순회 중 등록이 미정의인 이상 스냅샷은 필요하다.
- **예외 안전성**: 구독자 콜백이 던지면 **그 파동의 나머지 구독자는 그
  변경에 대해 영구 침묵**한다(값만 자가치유). `pcall`로 감싸지 않는다 —
  `base/architecture.md`의 예외 계약 절이 소스.

### 다이아몬드 의존성은 무엇이 푸는가 (2026-08-14 명확화)

`a → b`, `a → c`, `(b, c) → d` 형태에서 `a`가 한 번 바뀌면 `d`는 두 경로로
신호를 **두 번 받는다**(위 규칙대로 전파는 안 멈추므로). 그래도 **중복
재계산은 일어나지 않는다** — 계산은 `:Get()` 시점에만, 캐시를 통해서만
일어나기 때문:

1. `a:Set()` → `b`,`c`가 `invalid` 세팅 후 각각 `d`로 전파 → `d`는
   `invalid` 세팅(두 번째 신호는 이미 세워진 플래그를 다시 세울 뿐).
2. 누군가 `d:Get()` → `d`가 `invalid`이므로 상류(`b`,`c`)를 `:Get()` →
   각자 재계산·캐시·`invalid` 해제 → `d`도 계산·캐시·해제.
3. 이후 같은 사이클에서 또 `d:Get()`이 와도 `d`는 이미 valid라 **캐시를
   그대로 반환**.

즉 **중복 재계산을 막는 주체는 pull-recompute + 캐시**이지, 전파를
`invalid`로 끊는 게 아니다(`base/architecture.md`의 전파 모델 요약과 같은
이야기). Vide가 `todo.md`에 미해결로 남긴 "다이아몬드 중복 **재평가**"는
이 캐시 구조로 풀린다.

**⭐ [2026-08-21 역전] 중복 *통지*도 이제 접힌다.** 여기엔 원래 "quad가 추가로
접지 않는 것은 중복 통지뿐이고, `d` 아래 `Observer`가 한 사이클에 두 번 우는
것은 의도된 동작"이라고 적혀 있었으나, `base/state-epoch-plan.md` 채택으로
**두 번째 신호는 삼켜진다** — 그 신호가 나르는 리비전을 `d`가 이미 봤기
때문이다. 그래서 위 1단계는 "`d`가 두 번 받는다"가 아니라 **"두 번째는
`d`에서 멈춘다"**가 된다. 역전 원문과 이게 2026-08-14 역전을 되돌린 게 아닌
이유는 `archive/always-propagate-no-dedup-superseded.md`.

**부수로 같이 고쳐진 것 — 섞인 값(glitch).** 옛 모델에선 전파가 DFS라
`b` 가지가 먼저 끝까지 내려가고, 그 아래 Observer가 `d:Get()`을 부르면 `c`는
아직 신호를 못 받아 **옛 캐시를 반환**해 `d`가 `(b_new, c_old)`를 캐시했다.
리비전 비교는 `c`가 신호 없이도 스스로 낡음을 알아채므로 이 창이 없다 —
상세와 재현 시나리오는 `base/state-epoch-plan.md` §1.

**전역 원칙으로 명문화: "관측해야 실체화된다" (2026-08-04 세션)**

위 pull-recompute 규칙을 State 하나의 재계산 메커니즘으로만 읽지 말고,
프로젝트 전역에 적용되는 원칙으로 명시함: **어떤 파생값도 `:Get()`으로
직접 읽히기(관측) 전까지는 계산되지 않는다.** 이 원칙은 State 자체뿐 아니라,
State를 필드 값으로 담고 있는 다른 구조(예: `base/modifier-plan.md`의
Modifier)에도 그대로 적용됨 — Modifier의 getter가 State 필드를 읽으면 그
순간이 바로 관측이고, 그 순간 계산이 확정됨.

**주의 — 구조적 복사는 관측이 아님.** `table.clone`처럼 테이블 레퍼런스만
복사하는 연산은 안에 담긴 State 핸들을 그대로 옮길 뿐 `:Get()`을
호출하지 않으므로 관측이 아니고, 계산을 트리거하지 않음. Modifier 체이닝
메소드가 `table.clone` 후 필드를 덮어쓰는 것(`base/modifier-plan.md`의
"Immutable 값 + clone 기반 체이닝")과 이 원칙이 충돌하지 않는 이유가 바로
이것 — clone은 그저 참조 복사라 State 필드는 클론 이후에도 여전히 살아있는
lazy 핸들로 남음.

### 왜 State 체인을 Modifier처럼 플래튼하지 않는가 (2026-08-06 후속 세션)

**문제 제기(사용자)**: State가 `a → b → c`처럼 계속 연결되는 구조면, 이전
노드가 다음 노드에 대한 emit 연결/값 연결을 항상 들고 있어야 함(weak
table로 GC는 되지만 별도 데이터스트럭처 관리 부담). 대안으로, 각 State가
자기 Compute 함수 목록을 통째로 누적해서 갖고(Modifier의 clone-then-return
체이닝처럼) 매번 클론+append하면 링크드 그래프 자체가 필요 없어지지
않는가?

**기각 이유 — State의 정의 자체가 "캐싱하는 존재"임.** 위 온톨로지에
"State — source(또는 다른 state)의 결과를 **캐싱만 하는** 존재"라고
확정돼 있고, `previous` 두 번째 인자 메커니즘(무거운 파생 엔진 객체
재생성 비용 절감)도 이 캐싱 전제 위에서만 의미가 있음. 만약 Compute
체인을 매번 통째로 클론해 각 leaf가 독립된 함수 목록을 갖게 하면, 중간
State를 여러 갈래가 공유하는 다이아몬드 형태(`b`에서 `c1 = b:Compute(g1)`,
`c2 = b:Compute(g2)`로 분기)에서 `b`까지의 계산이 캐시 공유 없이 소비자
수만큼 중복 실행됨 — `previous` 메커니즘이 막으려던 문제를 반대로 다시
만들어내는 셈이라 방향이 안 맞음.

**"별도 데이터스트럭처 관리" 부담은 실제로는 작음.**
**⭐⭐ [2026-08-25 정정, 7라운드 `H-62`] 여기 한때 *"실제로 관측되는(`Get()`되는)
State뿐 — 중간에 만들어놓고 아무도 안 보는 State는 구독 등록 자체가 안
일어남"*이라 적혀 있었는데 **틀렸다. 구독 엣지는 생성 즉시(eager) 등록된다.**
**사용자 확정**: *"생성 즉시 밖에 없다. 옵져버가 실행 안 된다면 get 자체가
안 되므로, lazy 하면 아에 등록 될 기회가 없다."* — lazy가 성립하려면 "먼저
`Get()`이 일어난다"가 전제인데 `Get()`을 부르는 주체가 바로 그 등록되지
못한 Observer라 순환이다. `Get()`을 안 하는 Observer가 *"매 변경마다 정확히
한 번 운다"*는 확정과도 양립하지 않았다. 나머지 코퍼스는 이미 eager였다 —
`base/state-epoch-plan.md` §4의 생성 시점 시딩, `base/blocker-plan.md`의
*"호출되는 즉시"* 등록, 아래 ":With도 새 State 노드로 확정" 절.
관리 부담이 작다는 **결론 자체는 유지된다** — 근거가 "엣지가 적다"에서
**"엣지가 노드당 자기 상류 수만큼으로 유계이고 전부 weak-키"**로 바뀔 뿐이다.
다이아몬드에서 중복 재계산을 막는
것도 **노드별 캐시**(위 "다이아몬드 의존성은 무엇이 푸는가" 절)라 체인
전체가 링크드일 것을 요구하지 않고 각 노드가 자기 구독자 목록 + 자기
캐시만 가지면 되는 것이라, 이 결정과 무관하게 그대로 유지됨. 구현은
Observer와 동일한 패턴(외부 weak table, `{[child] = true}` 류)으로 충분 —
새 메커니즘 발명 아님. **[2026-08-14 정정]** 원래 이 자리는 "`invalid`
플래그 dedup 장치"를 근거로 들었으나, 그 장치 자체가 폐기됨(위 전파
모델 절) — 다만 **플래튼 기각이라는 결론은 안 바뀜**. 오히려 캐시가
유일한 중복 방지 수단이 되면서 "State는 캐싱하는 존재"라는 근거가 더
강해짐.

### ⭐ 해소됨 — 중간 State는 `_hold`로 살아남는다(구독 엣지의 방향성) (2026-08-18 제기, **2026-08-25 확정**)

**사용자가 지목한 미검증 항목**: *"확인해봐야 하는게 State -> State ->
State -> Observer Leaf Bind 에서 중간 State 는 참조되지 않아도 사라지지
않음이 명확해야함. 물론 compute 등의 callback 상 가져서 안전할 수 있지만,
With 등이 있는 경우 parent 와 연결된 상대를 자기 자신에 가지고 있어야
할것임. 이게 되는지는 더 알아봐야할 필요가 있음."*

확정된 두 서술을 겹치면 체인이 끊길 수 있다:

- State는 자기 **구독자(하류)를 weak로** 담는다(위 문단, 그리고
  `base/lifecycle-pattern.md`의 "(4) 실제 호출부" 절).
- Observer는 `gchold`(leaf) 또는 전역 레지스트리가 살려준다.
- 그러면 `A → B → C → Observer` 체인에서 **중간 노드 `B`/`C`를 강하게
  붙잡는 주체가 지금 문서 어디에도 명시돼 있지 않다.** 체이닝을 한 줄로
  쓰는 흔한 형태에선 아무도 `B`/`C`를 로컬 변수로 안 들고 있고, 하류 weak
  링크만으로는 생존이 보장되지 않아 **중간 State가 수거되고 전파가 조용히
  끊길** 수 있다.

**사용자가 지목한 해법 방향 — 구독 엣지는 하류로 weak, 상류로 strong.**
각 노드가 자기 parent(상류)를 강참조로 들고 있으면 leaf에서 root까지가
한 줄로 살아있게 된다. `:Compute`는 콜백 클로저가 상류를 캡처해 **우연히**
안전할 수 있지만, **`:With`가 만드는 pass-through 노드는 계산 함수가
없어서** 그런 우연한 캡처가 없다 — 그래서 "우연"에 기대면 안 되고 방향성을
불변식으로 못박아야 한다.

**⭐⭐ [2026-08-25 확정] `_hold` 불변식으로 닫혔다.** **사용자 확정**:
*"단순히, 각 state 들이 상위 State|Source 를 홀드하는 `_hold` 를 놓는것으로
바로 해결된다. 당연히 후행은 선행 요소들이 있어야하기 때문. 선행 state 가
후행 state 를 얻으려 하는건 UB이므로 가능한 일이다.(이건 릴레이션도 아니라
gc되긴 하지만.)"*

| 방향 | 강도 |
|---|---|
| 하류 State → 상류 State/Source (`_hold`) | **강함** |
| 상류 → 하류 (구독자 집합) | weak-키 |

- **모든 파생 노드**(`:With`/`:Compute`/`:Gate` — `state:Apply(blocker)`도 `:Gate`다, **[2026-08-29]** 옛 `:Block` 표기 정리)가 자기 상류를
  `_hold`에 강하게 담는다 — `:Compute`처럼 클로저가 **우연히** 캡처하는
  것에 기대지 않는다(`:With`의 pass-through 노드엔 그 우연이 없다).
- **⭐ [2026-08-26 보강, 8라운드 `H-110`] 말단 핸들도 마찬가지다.**
  파생 노드만 적어두면 **Observer가 우연에 남는다** — 이 절이 바로 위에서
  금지한 그 우연이다. 확정 결정의 소스인
  `qa-request/pre-implementation-handtrace-round7-followup.md` 🅚 절도
  *"핸들이 `_hold`로 상류를 잡는다"*라고 핸들까지 포함해 적었는데 반영이
  파생 노드로 좁혀졌었다. 실제 자리:
  - **Observer** → `observer._state`(생성 시 강참조). 전파 루프가 이 필드를
    `fn`의 1번 인자로 읽으므로 부기가 따로 늘지 않는다(위 전파 루프 절).
  - **Effect** → `_deps` 강한 맵이 이미 그 역할을 한다.
- 체인은 **말단(Observer/Effect/leaf)이 살아 있는 동안** 통째로 살아 있고,
  말단이 죽으면 통째로 수거된다. `Relate`가 아니므로 순환도 안 만든다.
- **상류가 하류를 얻으려는 것은 UB**라 반대 방향 강참조가 필요 없다.
- **따름정리 둘**(7라운드 `H-93`/`H-98`): 루트 `Epoch`(Source)가 하류보다
  먼저 수거될 수 없으므로 *"`:Refresh()`가 `false`를 줘 낡은 값을 최신이라고
  확신한다"*는 경로가 생기지 않고, `:Subscribe()`의 공개 계약 두 문장
  (*"참조를 아무 데도 안 담아도 정상"* / *"GC되지 않고 영원히 계속 실행됨"*)이
  서로 모순 없이 성립한다.
- **[2026-08-28 닫힘] 실측은 `quad-base/test/spec.state.luau` 11번이 한다** — 양성(말단을
  들고 있으면 루트·중간 노드가 GC를 넘긴다)과 음성(말단을 놓으면 하류가 수거되고 상류의
  구독자 집합에서 사라진다) 둘 다. 한때 여기 *"남은 것은 실측 스파이크 하나 —
  `luau-test`에 … 파일을 추가한다"*로 열려 있었고 **M2 착수 게이트는 아니었다**
  (`luau-test/STATUS.md`의 그 행도 같은 날 닫혔다).

**결론**: 노드별 캐시 유지(현재 모델) 유지, 플래튼 기각. Modifier가
플래튼+클론을 쓰는 건 애초에 캐싱이 필요 없는 정적 데이터라 성립하는
것이고, State는 존재 이유 자체(캐싱)가 달라 같은 패턴을 적용할 수 없음.
`research/documentation-plan.md`의 심화 문서 후보로 남겨둠 — "왜 State는
Modifier처럼 플래튼하지 않는가"는 설계 근거를 알고 싶은 사용자를 위한
좋은 심화 콘텐츠 소재.

## 여러 값을 묶어 파생값 만들기 — `:With` + `:Compute`, 포지셔널 인자 지양

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
lazy State 핸들로 통일, 아래 "`:With`/`:Compute` — self 인자도 lazy 핸들로
통일" 절 참고).

**v1과의 이름 충돌 주의**: **v1의 `:Add`/`:With`/`:Tween`처럼 값을 직접
가공하는 이름 붙은(named) 체이닝 연산은 만들지 않음** — 대신 일반 함수를
받아 처리. 아래의 v2 `:With(...)`는 이름만 같을 뿐 v1의 `:With`와는 다른
연산임 — v1은 "함수/테이블에서 값을 가져오는" 가공 연산이었고, v2는 그냥
"여러 State를 의존성으로 모으는" 수집 연산(v1의 `myStore "a,b"` 콤마-조인
문자열 방식은 폐기 대상 — `reference/quad-v1-architecture.md`의 "문자열 DSL"
문제점 참고).

**`fn`을 커링 스타일로 짜는 것도 권장(2026-08-07 일곱 번째 세션)** —
`key:Compute(makeFormatter("ko-KR"))`처럼 팩토리가 실제 `fn`을 만들어
반환하는 패턴, Observer/Effect의 동일 관용구(아래 "`fn`을 커링 스타일로
짜는 것도 모듈화 관용구로 권장" 절, `base/effect-plan.md`)와 같은 결 —
`:Compute`가 원래부터 이 셋 중 제일 먼저 있던 자리라 뒤늦게 문서화된
것뿐, 새 결정이라기보다 이미 있던 패턴을 명문화한 것.

**여러 소스를 한 번에 바꿔도 파생값 재계산/재대입이 한 번만 되게 하려면
`Blocker` 참고.** 위 `:With`+`:Compute`만으로는 "state1, state2를 연달아
Set하면 결합된 파생값이 두 번 재계산/재대입된다"는 문제(즉시 pull하는
store-bind 소비자 기준)는 안 풀림 — 이건 별도 확정 프리미티브
`base/blocker-plan.md`가 다룸(**[2026-08-24 재확정]** "State 개발과 같은
마일스톤, `ROADMAP.md` M2에서 함께 구현"이 맞다 — 2026-08-22엔 `Blocker.luau`가
디스패치 쪽으로 앞당겨져 갈라져 있었으나 마일스톤 순서 교체로 되돌아왔다.
다만 바닥부터 짜는 게 아니라 공용 `GateNode`(`base/gate-plan.md`) 위의
정책이라는 점은 그대로 — 마일스톤 소속의 소스는 `blocker-plan.md`의 정정
배너와 `ROADMAP.md` M2). lexical `Batch(fn)`으로 풀려던
초기 시도는 코루틴 yield 위에서 구조적으로 위험해 기각됨 —
`archive/batch-rejected.md` 참고.

### 네이밍 — `Compute`가 `-ed`가 아닌 이유 (2026-08-12, `State` 용어 정리 라운드 후속)

`Tag`의 `Added`/`Removed`, `Modifier`의 `Overridden`은 전부 `-ed`(과거분사)
어미를 의도적으로 씀 — `tag-plan.md`가 밝힌 이유는 "`Add`/`Remove`로 쓰면
뮤테이션 API처럼 보이기 때문"(실제로는 항상 clone 후 즉시 확정된 새 값을
반환). **`:Compute`/`:With`는 정반대 이유로 이 관례를 의도적으로 안 따름.**
Tag/Modifier의 클론은 호출 즉시 결과가 확정되는 값이라 "-ed"(이미 끝난
일)가 정확한 묘사지만, `:Compute(fn)`이 만드는 State 노드는 **호출 시점엔
`fn`을 등록만 해둔 것뿐이고 실제 계산은 나중에 `:Get()`이 pull할 때
일어남**(push-invalidate/pull-recompute 모델, 위 "전파 모델 확정" 절) —
즉 호출 시점에 "computed"(이미 계산됨)라고 부르면 거짓.
`State`를 `Computed`로 리네임하는 안이 최종 기각된 것(`question.md` 1번)도
같은 이유의 연장 — Vue `computed()`/Svelte `$derived`가 lazy인데도 그
이름을 쓰는 건 그쪽 생태계에서 문제없지만, quad 자신의 코퍼스 안에서는
"-ed 어미 = 이미 즉시 확정된 값"이라는 관례가 Tag/Modifier로 이미 자리
잡아서, 같은 어미를 lazy한 것에 재사용하면 quad 자기 관례와 충돌해 오히려
더 헷갈림. 그래서 `Compute`(동사 원형, "계산을 등록/설정한다"는 뜻)가
`Computed`보다 quad의 명명 체계 안에서 정확함.

### `:With`도 새 State 노드로 확정, 가변인자로 체인 남발 방지 (2026-08-07)

**문제 제기(사용자)**: `:With(...)`가 문서상 가변인자 표기이긴 한데, 실제로
호출마다(`:With(a):With(b):With(c)`처럼 체이닝할 때) 매번 새 State 노드를
만드는 게 맞는지, 아니면 값 없이 의존성 목록만 clone-then-append로 누적하는
가벼운 빌더로 만들어 노드 증식을 피해야 하는지가 불명확했음.

**"빌더" 대안은 기각.** 세 가지 이유:

1. **디버그 그래프가 꼬임.** `quad-debug`의 핵심 UX는 "무엇이 무엇에
   연결됐는가" 그래프(`research/debug-tooling-plan.md`). With/Compute를
   전부 실제 노드로 두면 코드상의 호출 체인이 그래프 엣지와 1:1로 그대로
   대응됨. 빌더로 만들면 그래프 툴이 "이건 노드가 아니라 나중에 갈라지는
   지점"이라는 가상의 분기 모양을 따로 합성해야 함 — 그럴 이유가 없음.
2. **엣지 수와 에포크 부기가 늘어남. [2026-08-25 근거 재작성, 7라운드 `H-82`]**
   **여기 한때 "공유 캐시를 못 타고 중복 계산이 생김"이라 적혀 있었는데
   `:With`엔 성립하지 않는다** — 같은 절이 `:With`를 *"계산 함수는 없고 값은
   `self`를 그대로 통과(pass-through)"*로 확정하므로 **공유될 계산 자체가
   없다**. 2026-08-14 재작성이 "근거가 더 강해졌다"면서 실제로는 정확도를
   낮춘 자리다. 유효한 근거는 이것이다 — 빌더로 누적하면 최종 소비자마다
   **자기 몫의 엣지 집합과 `EpochMap` 부기를 따로** 들게 되어, 실노드
   하나가 그걸 공유하는 것보다 등록/판정 비용이 소비자 수만큼 늘어난다.
   **결론(빌더 기각)은 안 바뀐다** — 근거 1·3이 그대로 유효하다.
   아래 옛 서술은 `:Compute`에 대해서는 여전히 맞는 이야기다:

   [옛 근거 — `:Compute`엔 유효, `:With`엔 무효]
   원래 이 항목은 "invalid 플래그로 다이아몬드 중복 워크 방지" 장치를
   근거로 들었으나 **그 장치는 폐기됨**(위 "전파 모델 확정" 절 정정) —
   근거를 실제로 유효한 것으로 바꿔 적음. With가 진짜 노드면
   `w = key1:With(key2)`에서 갈라지는 `c1 = w:Compute(g1)`,
   `c2 = w:Compute(g2)` 같은 흔한 fan-out에서 **`w`의 캐시를 c1/c2가
   공유**함(위 "다이아몬드 의존성은 무엇이 푸는가" 절의 그 캐시). 빌더면
   `w`라는 노드가 아예 없어서 c1/c2가 key1/key2에 각자 직접 구독을 걸고
   각자 계산하므로, 공유 지점이 사라짐 — 바로 위 "왜 State 체인을
   Modifier처럼 플래튼하지 않는가" 절이 기각한 것과 **같은 문제**임.
   (근거의 강도는 이 재작성으로 오히려 올라감: 예전 근거는 순회 비용
   최적화였지만, 지금 근거는 실제 중복 **계산**임.)
3. **clone 기반 구현은 Compute 노드 위에서 실제로 깨짐(사용자 지적,
   검증 완료).** `c = a:Compute(f)` 뒤에 `w = c:With(b)`를 clone으로
   구현하면, `table.clone`이 `c`의 캐시 슬롯(계산된 값 + `invalid`
   플래그)까지 그대로 복사해 `w`가 `c`와 별개의 독립 캐시를 갖는 사실상
   다른 노드가 됨. `c`와 `w`가 각자 관측되면 `f`가 두 번 따로
   실행/캐싱됨 — 바로 위 "왜 State 체인을 Modifier처럼 플래튼하지
   않는가" 절에서 이미 기각한 것과 정확히 같은 실패 모드(공유돼야 할
   계산이 소비자 수만큼 중복 실행). Modifier의 clone-then-append 패턴을
   State 쪽에 그대로 가져오면 안 되는 이유가 바로 이것.

**결정**: `:With(...)`는 호출마다 self+주어진 인자들을 구독하는 **새 State
노드**를 만든다(레퍼런스 기반 구독, clone 아님) — 계산 함수는 없고 값은
`self`를 그대로 통과(pass-through)시키되 구독 목록만 넓힌 얇은 노드. 이
노드는 Observer와 같은 패턴(외부 weak table)으로 상위 노드의 구독자 목록에
등록됨.

**⚠️ 문서 읽을 때 혼동 주의(2026-08-12 추가, 코퍼스 전체에 같은 패턴으로
적용): `Tag`(`:Added`/`:Removed`)와 `Modifier`(`:Apply` 등)는 겉보기엔
같은 `:` 체이닝 문법이지만 실제로는 clone-then-return이고, State의
`:With`/`:Compute`는 이름은 비슷해 보여도 정반대(clone이 아니라 진짜 새
노드)임.** 하나가 clone 계열, 다른 하나가 새-노드 계열이라는 걸 헷갈리기
쉬우니(둘 다 "값을 안 바꾸고 새 걸 반환하는 메소드 체이닝"으로 보이기
때문) 각 API 문서를 볼 때 이 문단을 기준으로 확인할 것 — clone 계열은
`Tag`/`Modifier`(값 객체, 확정 상태), 새-노드 계열은 `State`의
`:With`/`:Compute`(반응형, lazy)로 완전히 분리되어 있고 섞이지 않음.

**노드 증식 걱정은 가변인자로 해소.** 처음 문제 제기("With 하나마다 노드가
하나씩 늘어나는 게 낭비 아니냐")는 노드 자체를 없애는 대신, `:With(...)`가
여러 의존성을 한 번에 받을 수 있게 해서 해소함:

- `key1:With(a, b, c):Compute(fn)` — 노드 1개(구독 3개)로 끝남.
- `key1:With(a):With(b):With(c):Compute(fn)` — 여전히 가능하지만 노드
  3개가 만들어짐. 이건 나쁜 게 아니라 각 노드가 dedup/디버그 그래프에서
  실제 역할(구독 fan-in 지점)을 하는 저렴한 노드(계산 없음, Modifier
  clone과 같은 급의 비용)라 걱정할 비용이 아님.
- 그래도 **가변인자 스타일을 권장 관례로 삼음** — 그래프로 그릴 때도
  `:With(a, b, c)`가 `:With(a):With(b):With(c)`보다 단순(노드 1개에 들어오는
  엣지 3개 vs 노드 3개가 순서대로 이어지는 모양)해서 디버그하기 쉬움
  (사용자 확인).

### `:With`/`:Compute` — self 인자도 lazy 핸들로 통일

> **[2026-08-13 열세 번째 세션, 해소 — 아래 계약은 그대로 확정]**
> 한때 이 계약이 Luau 추론과 충돌한다며 `question.md` 0-Y로 열려 있었고,
> "콜백이 raw 값을 받으면 완전히 클린"이라는 1차 판정까지 붙어 있었음.
> **스파이크 재실측 결과 그 1차 판정이 뒤집혔음**(스파이크 개수·구성은
> 여기서 세지 않음 — 소스는 아래 `audit/type-recursion-issue/` 폴더) —
> raw 값 계약도 똑같이 불안전했고, 진짜 문제는 콜백 계약이 아니라 **`Compute`가
> `State<U>`(자기 이름을 다른 타입 인자로 감싼 타입)를 반환한다는 것
> 자체**였음(Luau의 현 한계, RFC가 `Promise<T>.andThen`으로 예시 든 바로
> 그 패턴). **따라서 아래 lazy 핸들 계약은 바꿀 이유가 없고 그대로
> 확정**이며, 콜백 파라미터 추론은 타입 선언을 "데이터부/메소드부"로
> 쪼개면 해결됨. 반환 타입만 사용처에서 명시 주석으로 바인딩하면 됨 —
> 규약 전문은 **`base/typing-limits.md`**, 실측 근거는
> `audit/type-recursion-issue/`.

- 최초안(self 값은 포지셔널 raw 값, with한 값만 클로저로 읽음)에는 실제
  단점이 있었음 — self가 raw 값이면 `fn` 호출 전에 항상 self를 먼저
  `Get()`해야 하므로, `fn` 내부 로직이 with한 다른 값을 보고 "이 경우엔 self
  계산 자체가 필요 없다"고 판단해도 이미 늦음(예: `:With(noprint)`이고
  `noprint:Get() == true`면 앞단 계산을 통째로 생략하고 싶은 경우).
- **해결(사용자 확정)**: self도 raw 값이 아니라 **State 핸들 그 자체**를
  `fn`의 포지셔널 인자로 넘긴다 — `fn(self: State<T>)`, 내부에서
  `self:Get()`을 실제로 읽을 때만 계산이 트리거됨. with한 값과 동일한
  lazy 원칙을 self에도 그대로 적용 — 별도 `ComputeWithout` 변형은
  불필요, `Compute` 하나로 일관.
- **[정정, 2026-08-07] 프로퍼티 읽기 표기는 State/Source에서 제외, `:Get()`만 지원.**
  이전엔 `Get()`을 감싼 읽기 전용 계산 속성(`base/lifecycle-pattern.md`의
  `Connected`와 동일한 "저장되는 필드가 아니라 계산된 속성" 패턴)으로
  `.value`/`:Get()` 둘 다 지원하고 프로퍼티 읽기를 관용적 표기로 앞세웠으나,
  "관측해야 실체화된다"는 원칙이 가장 날카롭게 느껴져야 할 지점에서
  프로퍼티 문법이 그 느낌을 무디게 한다는 재검토 끝에 함수 호출
  `:Get()` 하나로 좁힘 — `:Set()`과의 동사 짝도 자연스러움. 프로퍼티
  표기 자체는 폐기하지 않고 **Ref의 `.Value` 전용으로 좁힘**(**[표기 정정,
  2026-08-18]** 이 문단이 소문자 `.value`로 쓰고 있었음 — 실제 필드는
  대문자 `.Value`. Ref는 lazy가 아니라
  값을 읽어도 계산이 트리거되지 않으므로 프로퍼티 문법이 정직함 —
  `base/ref-plan.md`의 `.Value`가 그대로 유일한 존재가 됨, 이름
  충돌 자체가 사라져 별도 표기 정리 불필요).
- 예시 갱신: `store.key1:With(store.key2):Compute(function(key1) return
  key1:Get() + store.key2:Get() end)` — `key1`은 이제 raw 숫자가 아니라
  State. (**[2026-08-18]** 예시가 기각된 `store "key1"` 문자열 커링 문법으로
  쓰여 있던 걸 dot-access로 고침.)

**[2026-08-12 세션 감사에서 확인] `:Compute` 콜백 인자에 `:Get()`을 빠뜨리는
실수가 반복되기 쉬움 — 실제로 `.claude/` 문서 예시 코드 4곳(`tag-plan.md`,
`slot-plan.md` 2곳, `base/tween-plan.md`)에서 발견·수정됨.** `fn(self,
...)`의 모든 인자가 raw 값이 아니라 lazy State 핸들이라는 원칙(바로 위 절)을
사람도 에이전트도 코드 작성 중에 잊기 쉬운 지점 — `:Compute`/`:With` 콜백
안에서 인자를 비교(`==`)/연산(`+`)/테이블에 담기 전에 항상 `:Get()`부터
거쳤는지 확인할 것. 예: `function(name) return name == "x" end`(버그) vs
`function(name) return name:Get() == "x" end`(올바름).

### `:Compute(fn, ...)` — 추가 의존성을 trailing args로 직접 받는 sugar (2026-08-11)

**문제 제기(사용자)**: React의 `useMemo(fn, deps)`처럼 `:With(...)` 없이
`:Compute(fn, a, b, c)`로 바로 추가 의존성을 선언할 수 있으면 더 편하지
않은가 — `self`가 이미 lazy 핸들로 `fn`에 넘어가는 구조라 값 언랩 방식이
아니므로, 예전에 기각된 `Store.Combine({a,b}, function(av,bv)...)`(포지셔널
값 언랩이라 타입 표기가 꼬였던 안)과는 다른 제안.

**확정 — `Compute`엔 채택, `Observer`/`Effect`엔 채택 안 함. 근거는 "새
노드가 실제로 생기는가"의 차이(사용자가 직접 구분).**

- **`:Compute(fn, ...)`는 진짜 공짜 sugar.** `:Compute` 호출은 원래도
  결과를 담을 새 State 노드(자기 자신의 계산 캐시 슬롯)를 만들어야
  하므로, 그 노드가 `self` 말고 `a,b,c`에도 구독(무효화 엣지)을 추가로
  거는 건 **이미 만들어지는 노드에 엣지만 더 얹는 것** — `:With(a,b,c):Compute(fn)`
  체인(노드 2개: pass-through With 노드 + Compute 노드)과 달리 노드가
  안 늘어남(노드 1개). 구현은 `:With(...)`가 이미 하는 "구독 목록 확장"
  로직을 Compute 노드 생성 시점에 그대로 적용하는 것뿐 — 새 메커니즘
  아님.
- **⭐⭐ [부분 역전, 2026-08-24 반영 — 근거는 5라운드 `C-6`, 발견은 6라운드
  손 트레이싱 `H-13`] `Effect(fn, ...deps)`는 이제 **허용**된다. `Observer`만
  기각으로 남는다.** 아래 문단은 그 역전 **이전** 서술이고, `base/effect-plan.md`가
  이미 2026-08-21에 뒤집어둔 것을 이 문서가 반영하지 않아 **두 base 문서가
  정반대를 말하고 있었다.** 이 문서가 반응형 코어의 정본이라 구현자가
  `Effect` 표면을 짜기 전에 반드시 읽는 자리이고, 그대로 두면 5라운드가 닫은
  갭(**`Ref`는 `:With`로 못 합치므로 `Effect`의 의존성이 될 방법이 아예 없다**)이
  되돌아온다.
  - **역전 근거**(`effect-plan.md`): *"각 의존성에 구독을 따로 걸면 **합치는
    노드 자체가 안 생긴다** — 감출 비용이 애초에 없다."* 즉 아래 문단의 전제
    ("의존성이 둘 이상이면 합칠 별도 노드가 필요하다")가 `Effect`에 대해서는
    성립하지 않는다. `Effect`는 파생값을 안 만드는 leaf라 각 dep에 독립
    구독을 걸면 그만이다.
  - **`state:Observer(fn, ...)`는 기각을 유지한다. 다만 근거를 새로 쓴다**
    (옛 근거는 `Effect`와 공유하던 것이라 지금은 비어 있다, 사용자 확정
    2026-08-24): **`Observer`는 리시버 State 하나에 붙는 구독이고, 여럿을
    엮는 건 `Effect`가 대신한다.** 즉 역할 분담이지 비용 은폐 회피가 아니다.
  - **아래 "일반 원칙" 항목도 `:Compute` 한정으로 좁힌다** — 그 항목 자신의
    정정 문단이 소스.
- **(역전 전 원문) `Effect(fn, ...)`/`state:Observer(fn, ...)`류 trailing-args 확장은
  기각 — 여기선 진짜 새 노드가 생기기 때문.** Effect/Observer는 Compute와
  달리 **자기 자신이 결과를 담는 State 노드가 아님**(파생값을 안 만드는
  순수 leaf 소비자, 위 "독립 프리미티브 vs 파생 데이터" 분류에서도
  확인되는 차이) — `state`(receiver) 하나만
  구독 가능하므로, 의존성이 둘 이상이면 그걸 하나로 합칠 별도 노드가
  필요하고 그게 바로 `:With(...)`가 만드는 새 노드임. 이건 절대 공짜가
  아니라 **정말 비용이 드는 지점**이라, trailing args로 감춰버리면 "이
  줄이 실제로 새 노드/구독을 만든다"는 걸 코드만 보고 알 수 없게 됨 —
  `:With`가 clone 빌더가 아니라 진짜 노드로 확정됐던 이유(2026-08-07 세
  번째 세션, "코드상의 호출 체인이 그래프 엣지와 1:1로 대응돼야 quad-debug
  그래프가 안 꼬임")와 정확히 같은 원칙. 그래서 다중 의존성 Effect/Observer는
  **`Effect(fn, state:With(a,b,c))`처럼 `:With` 호출을 코드에 그대로
  노출**하도록 유지 — 새 노드가 생기는 지점을 sugar로 숨기지 않는다는
  게 핵심.
- **일반 원칙으로 정리**: "trailing args sugar는 그게 정말 무료일 때만
  붙인다 — 호출부가 이미 만들어야 하는 노드에 엣지만 얹는 경우(Compute)엔
  sugar, 없던 노드를 새로 만들어야 하는 경우(Effect/Observer의 다중
  의존성 병합)엔 sugar 없이 `:With`를 명시적으로 남긴다."
  **⚠️ [범위 축소, 2026-08-24 `H-13`] 이 원칙의 적용 범위는 `:Compute` 계열과
  "정말 새 노드가 생기는" 자리로 좁힌다.** 괄호 안의 `Effect` 예시는 틀린
  것으로 드러났다 — `Effect`의 다중 의존성은 각 dep에 독립 구독을 걸 뿐
  **합치는 노드를 안 만들므로** 이 원칙의 대상이 아니다(위 역전 배너).
  원칙 자체("숨겨지는 비용이 있는가")는 그대로 유효하고, 바뀐 건 *어디에
  비용이 있는가*에 대한 사실 판단이다. `quadnomicon`
  에세이 후보로 좋음(`research/documentation-content-map.md` 6번 항목
  다음에 추가) — "왜 Compute만 여러 deps를 편하게 받고 Effect/Observer는
  안 그런가"가 겉보기엔 비일관적으로 보이지만 실제로는 "숨겨지는 비용이
  있는가"라는 하나의 원칙에서 나온 것이라는 게 소재.

### trailing deps를 `fn`에 lazy positional 인자로도 노출 — 방향+순서(`fn(self, previous?, ...deps)`) 확정, 이형 다중 deps 표현 가능 여부만 실측 필요 (2026-08-11 후속)

> **[2026-08-13 열세 번째 세션, 해소]** 이 절이 얹혀 있던 "self도 lazy
> 핸들로 통일" 계약(구 `question.md` 0-Y)이 **그대로 유지로 확정**됨 —
> 전제가 안 흔들리므로 이 절의 결론도 유효. 다만 이 절이 남겨둔 실측
> 항목(이형 다중 deps를 제네릭 팩으로 표현 가능한지)은 **[2026-08-28 해소,
> 아래 `H-176` 문단 — 안 된다, deps 자리는 `...any`]** 이 배너 시점(2026-08-13)엔
> 미검증이었다: 그 스파이크(`15`)가 파싱 실패 상태라 재작성이 필요했고,
> 재작성해도 반환 타입 쪽은 `base/typing-limits.md` 1번 한계에 똑같이
> 걸림(명시 주석 바인딩으로 대응).

**문제 제기(사용자)**: `:Compute(fn, a, b, c)`가 이미 `a,b,c`를 trailing
args로 받아 구독을 건다면, 그 값을 `fn(self, a, b, c)`처럼 위치 인자로도
그대로 넘겨줘도 되지 않는가 — `:With`가 값을 포지셔널로 안 주는 이유는
`:With(a):With(b):With(c)`처럼 체인이 여러 호출에 걸쳐 길어지면 최종
합쳐진 노드가 몇 번째 인자로 뭘 받는지 추적하기 복잡해지기 때문인데,
`:Compute(fn, a, b, c)`의 trailing args는 그 호출문 **하나 안에 로컬하게**
다 드러나 있어서 같은 문제가 없다는 지적.

**방향 확정 — 채택.** 지적이 정확함:

- **`:With`가 회피하는 문제 자체가 여기엔 없음.** `:With` 체인의 위험은
  의존성 목록이 여러 호출/여러 스코프에 걸쳐 누적될 수 있어("체인이
  길어지면 순서 지키기가 복잡") 최종 위치 매핑을 코드 한 줄만 보고
  못 읽는다는 것 — `:Compute(fn, a, b, c)`는 그 반대로 한 호출문의
  인자 목록 자체가 곧 최종 순서라 누적/추적 문제가 원천적으로 없음.
- **실질적 이득 — 커링 패턴에서의 중복/드리프트 위험 제거.** 지금
  설계(trailing args는 구독 등록 전용, 값은 closure로 재획득)로
  `:Compute`를 커링 스타일(위 "`fn`을 커링 스타일로 짜는 것도 권장" 절)과
  같이 쓰면 `a, b`를 **두 번** 써야 함 — 한 번은 `makeComputer(f, a, b)`의
  클로저 캡처용, 한 번은 `:Compute(fn, a, b)`의 trailing args(구독
  등록용). 리팩터링 중 한쪽만 바뀌면 "구독은 `a`에 걸려있는데 실제로
  읽는 값은 `a'`"인 조용한 버그가 생길 수 있음. 값을 `fn`의 위치
  인자로 노출하면 `makeComputer(f)`가 `a,b`를 아예 몰라도 되고
  (`function(self, a, b) return f(self:Get(), a:Get(), b:Get()) end`),
  `:Compute`의 trailing args 목록 하나가 "무엇을 구독하는가"와 "`fn`이
  몇 번째 인자로 뭘 받는가" 둘 다의 유일한 소스가 됨 — 중복 자체가 사라짐.
- **`self`가 이미 raw 값이 아니라 lazy 핸들로 넘어가는 원칙을 trailing
  deps에도 그대로 적용** — `fn(self: State<T>, dep1: State<U1>, dep2:
  State<U2>, ...)`, 각 `depN:Get()`을 실제로 호출할 때만 그 값의 계산이
  트리거됨. self에 대해 이미 확정된 "조건부로 특정 값을 아예 안 읽고
  건너뛸 수 있음"이라는 이점이 trailing deps에도 똑같이 적용됨.

**`previous`(아래 절, 2026-08-06)와의 위치 충돌 — 사용자 정정으로 확정,
`fn(self, previous?, ...deps)`.** 처음엔 "`previous`를 dep 개수와 무관하게
항상 마지막 인자로 고정"(`fn(self, dep1, ..., depN, previous?)`)을
제안했으나 **틀림 — 사용자가 정정**: Luau 값 레벨 `...`(vararg)가
파라미터 리스트 맨 끝에만 올 수 있는 것과 똑같이, 타입 레벨 제네릭 팩
(`...U`)도 함수 타입 시그니처에서 **항상 맨 끝**이어야 함(팩이 나머지
자리를 전부 채우는 개념이라 그 뒤에 고정 타입이 하나 더 오는 건 Luau
타입 문법 자체가 원천적으로 허용 안 할 가능성이 매우 높음 — 이건 "안
될 수도 있는 불확실성"이 아니라 "거의 확실히 안 되는 문법 제약"에 가까움).
반대로 **`previous`를 `self` 바로 다음, deps 팩 앞에 두면**(`fn(self,
previous?, dep1, dep2, ..., depN)`) 고정 인자 다음에 팩이 오는 정상적인
모양이 되어 이 제약과 안 부딪힘 — **이게 유일하게 구조적으로 안전한
순서라 이걸로 확정**. `N=0`이면 기존 `fn(self, previous?)`로 그대로
축약되므로 하위 호환도 유지됨. **트레이드오프**: `previous`를 안 쓰고
deps만 받고 싶어도 `previous`가 2번째 자리를 차지하므로, 그 경우 호출부는
`function(self, _, dep1, dep2) ... end`처럼 안 쓰는 자리를 이름으로라도
비워둬야 함 — deps만 쓰는 흔한 케이스가 약간 불편해지지만, Luau 문법
제약상 다른 선택지가 없음(대안은 애초에 이 확장 자체를 안 하는 것뿐).

**⭐ [2026-08-28 실측, M2 단위 2 `H-176`] (B)는 안 된다** — `Compute: <U, D...>(self, fn:
(self, U?, D...) -> U, D...) -> State<U>`로 선언하면 `luau-analyze --!strict`가 trailing dep의
콜백 파라미터를 `{ read Get: (t1) -> (number, ...unknown) }`로 뒤틀어 **정상 호출까지**
`Expected … but got …`로 막는다(`quad-base/test/spec.state.luau` 3·7·9에서 재현 뒤 철회).
확정 선언은 **deps 자리 `...any`**, 콜백 안에서 dep 파라미터에 `dep: StateData<U>` 주석 —
런타임 계약(위치·순서·lazy)은 그대로다. 스파이크 `15`는 이 결과로 닫힌다
(`luau-test/STATUS.md`). 아래는 실측 전 서술:
**실측 필요 — `luau-test`의 `15-type-compute-trailing-deps-typepack.luau`
신규(ROADMAP.md M2 반영).** 순서 문제 자체는 위 정정으로 구조적으로
풀렸으므로, 스파이크가 실제로 확인할 진짜 불확실성은 (B) 하나로 좁혀짐 —
나머지는 그 결론을 뒷받침하는 대조군: (A) 균일 타입 dep 1개를 고정
인자로 좁히는 대조군(실패하면 B/C/D를 볼 것도 없이 기반 자체가 문제),
(B) 이형(heterogeneous) 타입 dep 여러 개를 제네릭 팩 하나로 정확히
좁혀 받을 수 있는지(안 되면 위치 인자 노출 자체를 동종 타입 dep 1개로
한정), (C) 처음 제안했던(틀린) "팩 뒤에 `previous?`" 순서가 실제로
막히는지 보여주는 음성 대조군(막혀야 정상), (D) 정정된 "`previous?` 뒤에
팩" 순서가 통과하는지 보여주는 양성 대조군(통과해야 정상 — 예상과
다르게 C가 통과하거나 D가 막히면 이 순서 결정 자체를 재검토).

### `:Compute(fn)`의 선택적 두 번째 인자 — `previous` (무거운 파생 객체 재사용, 2026-08-06)

**배경**: `:Compute`의 결과가 그 자체로 무겁고 재생성 비용이 큰 엔진
객체일 수 있음(예: 큰 로케일 테이블을 Roblox `LocalizationTable`
Instance로 변환하는 경우 — `LocalizationTable`은 `Set`/`Get`/`List`로
부분 갱신 가능한 userdata). 매번 새로 만들지 않고 이전 결과를 그대로
재사용해 필드만 patch하고 싶을 때를 위해, **직전에 이 Compute 함수가
반환했던 값**을 두 번째 인자로 받을 수 있게 한다.
**[표기 정정, 2026-08-18 구현 전 QA]** 이 절만 옛 표기 `fn(value,
previous)`로 남아 있었는데, 최종 시그니처는 **`fn(self, previous?,
...deps)`** 다 — 첫 인자는 raw 값이 아니라 **lazy 핸들**이라 안에서
`self:Get()`을 불러야 한다(위 "`:With`/`:Compute` — self 인자도 lazy
핸들로 통일" 절이 소스, `:Get()` 누락이 반복되는 실수라 별도 절까지 있음).

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

**[2026-08-09 세션] 오버엔지니어링 의심 재검토 — 기각, 현재 설계
유지.** `research/pre-implementation-audit.md` 3-1이 "클로저 업밸류로
이미 되는 걸 별도 API로 만든 것 아니냐"고 의심했던 것에 대한 사용자
반박: 클로저 업밸류 대안은 실제로 다음처럼 즉시실행함수(IIFE)로 감싸
업밸류를 준비해야 함 —

```lua
local computeFn = (function()
  local prev
  return function(self)
    -- prev를 읽고 새 값을 계산, prev 갱신
    prev = ...
    return prev
  end
end)()
someSource:Compute(computeFn)
```

이 준비 코드 자체가 이미 별도 `previous` 인자 하나보다 무겁고 번거로움
— "재사용하고 싶으면 그냥 캐시된 값을 바로 넘겨주면 되는" 게 더
단순하다는 게 사용자 논거. 반대로 `previous`가 없으면 `fn`은 매 호출마다
새 인스턴스를 만들어야 해서(예: `LocalizationTable.new()`) lazy든
아니든 재계산이 일어날 때마다 항상 비싼 재생성이 발생 — `previous`가
막으려는 문제는 실재함. **`pre-implementation-audit.md` 3-1 해소 —
현재 `fn(self, previous)` 설계 그대로 유지, API 표면을 줄이지 않음.**

**스코핑 명확화(2026-08-09 세션에 확인, 새 결정 아님) — `previous`는 `self`
(입력)가 아니라 "이 `:Compute` 호출 하나가 만들어낸 결과 State 노드"
자신에 귀속된다.** State가 `:With`/`:Compute` 호출마다 새 노드를
만든다는 건 이미 확정된 온톨로지(위 "왜 State 체인을 Modifier처럼
플래튼하지 않는가" 절)라, `previous`도 그 새 노드의 내부 캐시 슬롯일
뿐 `self`에 얹히는 게 아님 — 같은 `self`에서 여러 `:Compute`가 갈라지는
팬아웃(`c1 = w:Compute(g1)`, `c2 = w:Compute(g2)`)이 있어도 `g1`/`g2`
각자의 `previous`는 각자의 결과 노드에 독립적으로 저장되므로 서로 안
섞임 — 새로 결정할 것 없이 기존 "노드별 캐시" 원칙의 당연한 귀결.
(참고: `self.Cache`처럼 `self` — 즉 입력 — 에 캐시를 얹는 모양은 이
스코핑과 안 맞아 채택하지 않음 — 팬아웃 시 여러 소비자가 같은
`self.Cache` 슬롯을 공유해 덮어쓰는 충돌이 생기기 때문.)

## State는 쓰기 대상이 아님 — 확정, Source는 독립 공개 프리미티브로 격상

- `state:Get()`은 항상 읽기 전용. State에는 쓰기 API가 아예 없음. "State에
  직접 쓰기 API를 허용하면 다른 source에서 파생된 state에 직접 쓰기가
  가능해져 버린다"는 이전 우려는 이걸로 근본적으로 해소(그런 API 자체가
  없음).
- **[정정, 2026-08-06 후속 세션] 값을 쓰는 경로는 `store.key = value`
  (`__newindex`)가 아니라 `store.key:Set(value)`로 전환됨** — **[2026-08-25]**
  같은 날 오전에 대입 문법을 되살렸다가 **철회**했다
  (`archive/store-value-field-redesign-withdrawn.md`). 이유와
  상세는 `base/store-plan.md`의 "Store 값 설정 문법" 절 참고(요지:
  Source가 State를 만족하는 구조로 바뀌며 레코드 타입 읽기/쓰기 대칭을
  맞추려면 대입 문법을 포기해야 함 + `=`가 암시하는 "즉시 커밋"이 실제
  lazy 동작과 정서적으로 안 맞는다는 논거).
- **`Source`는 Store의 내부 구현 디테일이 아니라 별도의 가벼운 공개
  프리미티브로 노출** — Store는 다수의 source를 등록/관리하는 무거운
  구조라, 값 하나만 반응형으로 다루고 싶을 때 Store를 통째로 만드는 건
  비효율이라는 게 사용자 판단("store가 source 수십 개 만드는건 비효율이니
  둘이 다른 구현이라 봐도 될듯"). `Source(default)` 독립 생성자가
  Store와 나란히 존재(**[2026-08-28]** 이름은 아래 항목대로 `Source(default)`로 확정됐고
  M2 단위 2 `quad-base/src/Source.luau`가 그 이름이다 — 한때 여기 "구현 단계에서
  확정"이라 열려 있었다).
- **생성자 스타일 확정(2026-08-06 후속 세션): Kotlin Compose식 "타입
  이름 자체를 팩토리 함수로" — `Source(default)`, `Ref(default)`,
  `Store({defaults})`.** Ref도 예외 없이 이 스타일을 따름 — Ref가
  `Ref()`로 안 만들어질 특별한 이유는 없었고(이전 절에서 API 모양만
  다루고 생성자를 명시 안 해서 생긴 공백), `architecture.md`의 "복사(clone)
  구현 지양, 팩토리 함수로 대체" 원칙과도 정확히 일치. `Store({defaults})`도
  같은 스타일로 지원. **[2026-08-25 정정]** `defaults`는 더 이상 "선택 —
  순수 편의용 초기값 템플릿"이 아니다 — **명시적 초기화**가 확정되며
  `defaults`가 곧 **선언 키 집합**이 됐다(옛 lazy `__index` 폐기). 무인자
  `Store<<{}>>()`는 빈 타입일 때만 유효하다(`base/store-plan.md`).
- **[보강, 2026-08-09 열한 번째 세션] `Source(default)`/`Ref(default)`의
  `default` 인자가 "선택"이라는 서술은 정확히는 `T`가 `nil`을 포함할 때만
  성립함 — 생략하면 실제로 `nil`이 그 자리를 채우기 때문.** `Source()`
  (무인자)는 `Source(nil)`과 동치라고 이미 명시돼 있으나, 이게 타입
  레벨에서 뭘 뜻하는지(`T`가 nilable이 아니면 타입과 실제 저장값이
  어긋난다는 것)는 지금까지 명시적으로 안 적혀 있었음. `Ref`도 마찬가지
  캐비엇이 있고 오히려 더 눈에 띄게 드러남 — `:Callback(fn)`은 등록
  즉시 그 시점 값으로 무조건 1회 호출되므로(미설정 상태여도 그 상태
  그대로 호출, `base/ref-plan.md`의 "바인드 방법" 절 참고),
  `default`를 생략한 `Ref()`에 콜백을 걸면 그 콜백이 즉시 `nil`로 한 번
  불림 — `T`가 non-nilable이면 이 시점에 이미 타입 위반. 따라서
  `default`를 생략해도 되는 건 오직 `T`가 nilable(`T?`)로 선언된
  경우뿐이라는 걸 문서 차원에서 명시할 것(non-nilable `T`에 `default`
  없이 생성하는 건 사용자 실수, 타입으로 막을 수 있으면 막고 안 되면
  UB로 문서 경고).

### ⭐ `Source:Set(v)`는 동일값이어도 항상 갱신하고 emit한다 (2026-08-25 확정, 7라운드 `H-68`)

지금까지 코퍼스 어디에도 이 경우가 안 적혀 있었다. **확정**: `v`가 현재
값과 `==`여도 `Revision`을 갱신하고 정상적으로 emit한다.

- 판정이 **값 동등성이 아니라 리비전**이라는 `Epoch` 모델
  (`base/state-epoch-plan.md` §2)과 일관된다.
- 더 중요한 건 **테이블 값**이다 — mutate한 뒤 같은 테이블을 다시
  `Set`하는 것이 `==`로 dedup되면 **변경이 조용히 증발**한다. 아래
  `:Emit()` 절이 다루는 것과 정확히 같은 상황인데, `Set`이 dedup하면
  사용자가 그 구분을 항상 의식해야 한다.
- 불필요한 파동을 접는 일은 이미 **하류**가 한다 — `EpochMap` 판정과
  게이트(`base/gate-plan.md`).

## Source 값을 직접 mutate한 뒤 전파 — `:Emit()` (2026-08-06 후속 세션, 호출부 정정)

**결정**: Source가 들고 있는 값을 새 값으로 교체하지 않고 제자리에서
mutate한 뒤, `:Emit()`으로 무효화 신호만 별도로 쏘는 것을 **Source
원천(store가 직접 들고 있는 값)에 한해 허용**한다.

**[정정, 같은 세션 후반]** 원래 `Store:Emit(key)`(Store에 key를 넘겨
호출)로 적혀있었으나, 위 "Source가 State를 만족함" 절에서 `store.key`
자체가 Source를 직접 반환하는 것으로 바뀌면서 `Emit`도 Source의 평범한
메소드로 이동 — `store.key:Emit()`(key 인자 불필요, 이미 손에 든 Source
핸들에 바로 호출). `Store:Emit(key)`라는 별도 경로는 유지할 이유가
없어져 폐기(같은 걸 하는 두 번째 경로를 남기지 않는다는 그 세션 전반의
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

**남는 캐비엇(문서에 반드시 명시) — `Get()`은 라이브 레퍼런스를 준다**:
`Get()`으로 이전에 그 테이블을 읽어서 어딘가(로컬 변수, 다른 코드가 들고
있는 참조)에 캐시해둔 게 있다면, mutation 순간 그것도 같이 바뀐다 — 새
테이블이 아니라 같은 레퍼런스라서. **`Get()` 결과를 나중 비교(`==`)나
diff 캐시 용도로 들고 있으면 안 됨 — 항상 다시 `Get()`할 것.**

**하드 경계 — Source 원천에만 허용, 중간/파생 State에는 없음.** `:With`/
`:Compute`로 만들어진 파생 State에는 `Emit`이라는 개념 자체가 없다 —
허용하면 "이 State의 현재 값이 뭘 근거로 계산됐는가"를 아무도 설명할 수
없게 되어(quad-debug가 추적하려는 "무엇이 무엇을 계산했는가" 그래프가
깨짐) 디버깅이 사실상 불가능해짐. State의 값은 항상 "선언된 Compute
함수를 실제로 실행한 결과"여야 한다는 불변식이 깨지면 안 됨. 무거운
파생 객체를 재사용하고 싶은 경우(Compute의 결과 자체가 무거운 userdata인
경우)를 위한 별도 메커니즘은 위 "`:Compute(fn)`의 선택적 두 번째 인자 —
`previous`" 절 참고 — 이건 `Emit`과 다른 메커니즘.

### 따름정리 — `Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없음

Modifier는 정적 flatten으로 dispatch와 완전히 별개인 단계에서 처리되고
(`base/modifier-plan.md`) — Store/State/dispatch 경로엔 애초에
Modifier용 processor가 없음. **[정정, 2026-08-09 세션]** `State<Modifier>`
조합은 "UB, 가능하면 타입 차단"이 아니라 **명시적 `error`로 확정**
(`modifier-plan.md` 7번) — `isModifier` predicate를 `Source(...)` 생성자/
`Source:Set()`/State의 `:Compute` 결과 캐싱
지점에서 확인해 런타임에 직접 막음(**⭐ [2026-08-26 정정, 8라운드 `H-122`]**
여기 한때 *"Store 생성 시 eager `Source(default)`"*라고 적혀 있었으나
**명시적 초기화 확정(2026-08-25) 이후 그 지점은 코드상 존재하지 않는다** (**⚠️ [2026-08-26 정밀화, `/code-review high`]** 정확히는 **`defaults` 경로에서** 안 만든다는 뜻이다 — 동적 키 창구 `store:Of(name)`은 여전히 그 자리에서 `Source`를 만든다(`base/store-plan.md`). 결론은 그대로다: 가드를 `Source` 생성자에 두면 `Of` 경로까지 **한 번에 커버**된다.) —
`defaults`엔 사용자가 만든 `Source(v)`가 그대로 들어오고 생성자는
`table.clone`뿐이라 그 지점이 코드상 존재하지 않는다. 가드를 `Source`
생성자로 옮기면 defaults 경로가 **자동으로 커버**되어 목록이 오히려
짧아진다 — 사용자 확정), 타입 차단은 되면 좋은 보너스일
뿐 유일한 방어선이 아님. **[2026-08-06 후속 세션 추가]** Source가
State를 구조적으로 만족하게 되면서 이 제약은 `Source<Modifier>`(Store를
거치지 않는 독립 `Source(someModifier)`)에도 동일하게 적용됨을 명시 —
Source가 State 계약을 만족하는 이상 같은 이유(Modifier용 processor
부재)가 그대로 적용되고, 별도로 다시 논증할 필요 없음. 위 "하드 경계"와
같은 이유로, `Emit`이 Modifier의 정적 flatten과 충돌할 걱정 자체가
성립하지 않음(둘이 만날 지점이 없음).

## `state:Apply(factory)` — Modifier와 동일한 순수 체이닝 설탕으로 확정 (2026-08-07 일곱 번째 세션)

**처음 제안됐던 "`:With`/`:Compute` 등록을 커링으로 자동화하는 조합기"
방향은 기각됨 — 사용자가 재확인한 실제 의도는 그보다 훨씬 단순함.**
`Modifier:Apply(factory)`도 매번 새 값을 만들어내는 체이닝 설탕일 뿐이듯,
State/Source도 `:With`/`:Compute`마다 새 노드가 나오는 같은 모양이라 —
`state:Apply(factory)`는 그냥 `factory(state)`를 메소드 체이닝 문법으로
쓴 것뿐이고 그 이상의 계약은 없음(`Modifier:Apply`와 완전히 동일한
정의: `function(self, factory) return factory(self) end`). **[2026-08-28 `H-158`
호출 규약 — `/code-review` 지적으로 명시, 에이전트 배선]** 애플리커티브 팩토리는
**메소드형** `__apply`다: `function(self, factory) if type(factory) == "function"
then return factory(self) else return factory:__apply(self) end end` — 즉
`Blocker`/`Debounce`는 `function Blocker:__apply(state) … end`로 정의하고 `self`는
그 인스턴스다(클래스 테이블의 `__apply`를 `self` 없이 부르면 첫 emit에서 `nil`
인덱스로 죽는다). 세 소비자(`Blocker`·`Debounce`·`Throttle`)가 같은 자리 수.

- **동기**: 커링 팩토리 두 개 이상을 이미 있는 문법만으로 이으면 바깥에서
  안으로 겹쳐 읽어야 하는 중첩 호출이 됨 — 실제 형태로 예를 들면,
  ```lua
  -- Apply 없이: 안쪽(가장 최근에 만든 것)부터 거꾸로 읽어야 함
  local capped = capAt(100)(withLocale(localeStore.locale)(rawScore))

  -- state:Apply로: 왼쪽에서 오른쪽, 만든 순서 그대로 읽힘
  local capped = rawScore
    :Apply(withLocale(localeStore.locale))
    :Apply(capAt(100))
  ```
  팩토리가 세 개, 네 개로 늘어날수록 앞쪽 버전은 괄호 깊이와 읽는 방향이
  코드 작성 순서와 반대로 꼬여 diff/리뷰에서 특히 안 좋음 — `:Apply`
  버전은 각 줄이 "그다음 뭘 했는지"를 순서대로 나열하므로 Modifier
  체이닝(`mod:FontSize(14):Apply(Boldify(10)):Apply(Italicify)`)과 읽는
  방식이 완전히 통일됨. `:With`/`:Compute` 자체를 대신 호출해주는
  자동화가 아니므로, 여전히 팩토리 본문 안에서 `:With`/`:Compute`를
  직접 호출하는 건 팩토리 작성자 몫.
- **⭐⭐ [2026-08-25 확정, 7라운드 `H-94`] 팩토리는 함수이거나 "지정된
  필드를 가진 객체"다 — `__call` 테이블은 안 받는다.** `Debounce{...}` /
  `Throttle{...}`가 `__call` 테이블을 돌려주면
  `state:Apply(Debounce{...})`가 **타입에러**다(`luau-analyze` 실측 —
  `__call` 테이블은 함수 타입 자리에 안 들어간다. 런타임은 멀쩡하고
  타입만 막히므로 `--!nocheck` 스파이크에선 안 드러난다). 같은 실측이
  타입 레벨 `__call`의 다른 한계도 보였다 — `self`를 못 받고,
  `typeof(f<<T>>)`로 타입 인자를 넘기는 것도 실패한다.
  - **확정**: 애플리커티브 팩토리는 **`__call`이 아니라 지정된 필드**로
    자기를 노출한다. **사용자 판단**: *"아에 어플리커티브 펑터로써,
    `__call` 이 아닌 다른 필드로 들어가는게 맞아보여요. 외부에서 직접
    `()` 호출하는건 의미 없게 둬야해요."*
  - **부수 효과**: `Blocker`를 슈가로 못 두던 이유도 같이 풀린다 —
    `Debounce`/`Throttle`/`Blocker`가 전부 같은 계약을 만족하게 된다.
  - **함수와 콜러블의 유니온으로 여는 안은 기각** — 필드로 받으면
    유니온도 캐스트도 필요 없다. 필드 이름은 **`__apply`**(**[2026-08-28 10라운드
    `H-158` 사용자 확정]** *"키는 __apply 로 하기로 했던거로 기억중임"* —
    `base/blocker-plan.md` 배너), 시그니처는 **[2026-08-28 M2 단위 2 확정]** 메소드형
    `__apply: (self: any, state: State<T>) -> U` — `quad-types/src/init.luau`의 `State<T>.Apply`
    파라미터 타입과 `State.luau`의 `(factory :: any):__apply(self)` 호출이 소스.
- **구현 비용 거의 0**: Modifier와 달리 State/Source는 제네릭 `__index`로
  필드 setter를 즉석 합성하는 메커니즘이 없어서(고정된 메소드 표면만
  존재), Modifier의 `Apply`처럼 "필드 이름으로 예약해야 하는" 충돌
  자체가 없음 — 그냥 고정 메소드 하나 추가하는 것.
- **타입은 반환 쪽을 완전히 열어둠** — **⚠️ [2026-08-25 정정, `H-94`]**
  여기 한때 `factory: (State<T>) -> U): U`라 적혀 있었는데, 그 시그니처는
  **함수만** 받으므로 위 `H-94` 항목이 확정한 "지정된 필드를 가진 객체"
  형태를 **거부한다** — `state:Apply(Debounce{...})`가 그대로 타입에러다.
  파라미터는 **함수 또는 그 필드를 가진 객체**를 받고 반환 `U`만 열어둔다
  (필드 이름은 `__apply` — **[2026-08-28 `H-158`]**; 시그니처는 위 항목대로 M2 단위 2에서 확정). 아래 논거는 **반환 쪽**에
  대한 것이라 그대로 유효하다 — Modifier의
  `Apply`는 `factory: (M) -> M`으로 같은 타입을 유지해야 체이닝이
  이어지지만, State의 `:Apply`는 팩토리가 State가 아닌 값(예: 최종
  요약된 plain 값)을 반환해 반응형 그래프를 벗어나는 탈출구로 쓰는 것도
  막을 이유가 없음 — Modifier보다 오히려 더 자유로운 시그니처.
- **Source도 자동 포함**: Source가 State를 구조적으로 만족하는 기존
  델리게이션(`__index`로 `:With`/`:Compute` 위임)에 `:Apply`도 그대로
  얹히므로 별도 구현 불필요.
- **Effect/Observer/Compute의 `fn` 커링 권장(위 절들)과 같은 스레드지만
  별개 기능** — 커링은 "`fn` 자체를 팩토리로 짜는 관용구" 권장이고,
  `:Apply`는 그렇게 만든 팩토리를 체이닝 문법으로 적용하는 수단. 둘이
  합쳐지면 `state:Apply(makeFormatter("ko-KR"))`처럼 자연스럽게 이어짐.
- **관용구 — 이름 붙여 재사용하는 콤비네이터는 항상 `:Apply`로 붙인다
  (2026-08-12 세션, `research/operator-sugar-plan.md`/`base/tween-plan.md`의
  `Animate` 정정에서 도출)**: 그 자리에서 한 번 쓰고
  마는 인라인 람다(deps도 그 호출문에 바로 나열)는 `:Compute(fn,
  ...deps)`를 직접 쓰고, `local addTax = Sum(tax, shipping)`처럼 이름
  붙여 여러 곳에서 재사용할 콤비네이터는 인자 개수(0항/N항)와 무관하게
  전부 `factory(self) -> State`를 반환해 `:Apply`로 붙임 — 스타일
  선호가 아니라 정합성 문제: quad는 암묵적 자동 추적을 기각했으므로
  (위 "암묵적 자동 추적 기각" 부분) 재사용 팩토리가 캡처한 deps를
  `:Compute`에 직접 꽂으면 그 deps가 구독 목록에 안 걸려 조용히
  멈추는 버그가 됨 — `:Apply`는 factory 내부에서 `self:Compute(fn,
  ...deps)`를 스스로 다시 전달하므로 이 문제가 없음.

## `state:Observer(fn)` — 값을 안 실어주는 구독, children 배열에 직접 놓는 leaf 값

**결정(2026-08-06 후속 세션, 사용자 확정)**: 별도 `ObserverHolder`
래퍼 타입은 안 만듦 — `state:Observer(fn)`가 반환하는 값 자체가 이미
"children 배열에 바로 놓을 수 있는 leaf 값"이라 감쌀 필요가 없음.
`Ref`와 완전히 같은 층위. **자유 함수 `Observer(state, fn)`가
아니라 메소드 `state:Observer(fn)`로 확정** — `state`가 항상 필요한
필수 인자라 `:` 리시버 자리에 자연스럽게 들어가고(다른 형태면 인자
두 개짜리 자유 함수가 되어 읽는 순서가 어색해짐), `architecture.md`의
"함수지향 디폴트, `:` 체이닝은 예외적으로만"
원칙이 정확히 이 경우를 가리킴 — Store 값 변경 체이닝과 같은 예외
카테고리. **더 근본적인 이유**: 위 "독립 존재 가능한 프리미티브 vs
원천에 종속된 파생 데이터" 원칙 참고 — Observer는 State처럼 원천 없이는
존재할 수 없는 파생 데이터라, 애초에 "타입 이름을 부르는 자유 함수
생성자" 카테고리에 안 속함(Source/Ref/Store/Modifier와는 다른 부류).

```lua
local observer = state:Observer(function()
    state:Get()
end)

Frame {
    observer,
}
```

이러면 `observer`는 `Frame`이 살아있는 동안만 유지되고, `Frame`이
retract/Destroy되면 자동으로 정리됨.

- **`fn`은 등록 시점에 즉시 1회 실행된다(2026-08-07 여섯 번째 세션,
  사용자 확정 — 이전까지 미명시였던 항목).** (**[2026-08-28 `H-159`]** 이 1회는
  `state:Observer(fn)` 생성자가 무조건 하는 것(Effect 생성자와 같은 모양 —
  `_rerunRequired = true`로 시작해 이 1회가 내린다)이고, 같은 날 신설된 홀드는
  그 **뒤** ~ 묶이기 전 사이의 변경만 다룬다. **생성자 순서는 `fn` 1회 실행 →
  `_subs` 삽입**(`/code-review` 지적으로 고정): 반대면 설치 발화가 자기 State를
  `Set`할 때 그 emit이 아직 안 묶인 자신의 `_receive`에 와 플래그가 서고 첫
  바인드에서 `fn`이 한 번 더 돈다. Effect의 내부
  Observer가 이 설치 발화를 `from == nil`로 거르는 이유이기도 하다.) 근거: (1) 이미 채워진
  State를 나중에 구독하면 그 값을 반영하는 연산이 아예 한 번도 안
  일어나는 문제가 생겨 초기화 순서에 디버깅 부담이 생김. (2) 초회
  실행을 하지 말아야 할 구체적 근거가 약함. (3) **이 결정 덕에
  Observer 하나로 "초기값 적용"과 "이후 변경 반영"을 같은 코드 경로로
  통일할 수 있음** — 예: State→프로퍼티 store-bind 핸들러가 그냥
  `state:Observer(function() inst.SomeProp = state:Get() end)`를 걸어
  두는 것만으로 최초 적용까지 공짜로 됨(별도의 "설치 시 1회 적용" 코드를
  따로 안 짜도 됨). `state:Observer()`(인자 없는 "항상 관측" 유틸)도
  이 규칙을 그대로 따름 — 호출 즉시 한 번 관측이 트리거됨.
- **⭐ [2026-08-21 확정, 2026-08-26 자리 하나 추가] `fn`의 시그니처는
  `fn(targetState, self, emitFrom: (Epoch | EpochSet)?)`이다.** 사용자:
  *"Compute 와 유사하게 나올 수
  있다 봐요. self 를 넘겨주고, 그 뒤에 epoch|{epoch} 를 주는게 맞아보입니다."*
  위 "`:With`/`:Compute` — self 인자도 lazy 핸들로 통일" 절과 같은 결이다.
  **[2026-08-26 확정, 8라운드 `H-109`]** 여기 한때 2-인자
  (`fn(self, from)`)로 적혀 있었는데, 그때의 `self`는 **리시버 State의 lazy
  핸들**을 뜻했고 전파 루프 의사코드는 같은 자리에 **Observer 값**을 넘기고
  있었다 — 두 확정이 정면으로 충돌해 있었다. 사용자 확정으로 **Observer
  핸들이 가운데 자리로 들어와 세 자리**가 됐다(*"실 값이 앞에 놓이도록"* —
  `Ref` 콜백 `fn(value, ref)`와 같은 원칙). 자리 배치와 근거는 위
  "전파 루프 — 확정 의사코드" 절이 소스.
  - `targetState`는 이 Observer가 붙은 State의 **lazy 핸들**(값이 아님).
  - `self`는 **Observer 값 자신**이다 — 핸들 조작용.
  - `emitFrom`은 **이 통지의 출처**다 — `Epoch` 하나이거나 `Epoch`들의 **집합**
    (`{[Epoch]: true}`, 게이트가 유보를 풀며 떼어낸 스냅샷). 값도 리비전도
    안 실린다. 분기는 `isEpoch`로. 계약은 `base/state-epoch-plan.md` §5가 소스.
  - **⚠️ [2026-08-22 신설] 등록 시점의 즉시 1회 실행에는 `emitFrom`이 없다** —
    그건 통지가 아니라 설치라 출처가 존재하지 않는다. 그래서 `emitFrom`은
    **옵셔널**이고, 이때만 `nil`이다(2026-08-21 커밋 전 `/code-review high`
    발견 — 한때 non-optional로 적혀 있었다). `fn`이 `emitFrom`을 실제로 쓰는
    소비자라면 `nil`을 **"출처 없음 — 값을 읽어라"**로 다뤄야 한다. **[2026-08-28
    `H-164` 확정]** `nil`은 설치 발화 **또는** 묶일 때의 캐치업(`H-159` 홀드 발화)
    둘 다다 — 둘 다 "특정 출처의 통지"가 아니라 "지금 값을 반영하라"라 같은 종류.
    홀드된 출처를 보관해 넘기는 안은 기각(사용자: *"_rerunRequired 를 from 으로
    저장하면 여러 홀드 변경이 오면 from 이 날아가지 않아? 애초에 from 을 저장할
    이유가 왜 있어?"*). `nil`을 "초기화 전용"으로 분기하는 소비자 패턴은 계약이
    아니다.
  - **이건 "값을 안 실어주는 구독" 계약을 안 깬다** — 넘기는 건 값이 아니라
    **핸들과 메타데이터**뿐이다.
  - 인자 없는 `state:Observer()`(항상 관측 유틸)도 그대로 성립한다 — 넘겨줄
    `fn`이 없으니 인자 얘기가 아예 안 나온다.
  - **`from`을 실제로 쓰는 첫 소비자는 `Effect`다** — 자기 `EpochMap`을
    들고 각 내부 Observer가 그걸 `Update`해서 다중 의존성 중복 발화를
    접는다(`base/effect-plan.md`의 "`Effect(fn, ...deps)`" 절).
- **값을 안 실어줌 — 반드시 `Get()`을 다시 해야 함.** 기존 "emit은
  무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함" 원칙(위
  "전파 모델 확정" 절)이 그대로 적용됨: `fn`은 "뭔가
  바뀌었으니 다시 확인하라"는 신호만 받고 새 값 자체는 안 받음 —
  위 예시처럼 `fn` 본문에서 `state:Get()`을 명시적으로 다시
  읽어야 함. 자동으로 안 해주는 이유: 재계산이 진짜 필요한지가 다른
  `:With`한 값에 따라 갈리는 경우가 있어서(위 "포지셔널 인자 지양" 절의
  `noprint` 예시처럼 계산 자체를 통째로 생략하고 싶을 수 있음) — `Get()`
  호출 여부를 작성자가 직접 결정하게 열어둔 것.
  - **⚠️ 이 허용이 전파 규칙에 의존한다(2026-08-14 명시, 2026-08-21 갱신).**
    의존하는 명제는 **"`Set` 한 번은 새 리비전이라 항상 통과한다"** 하나다 —
    dedup이 접는 건 *같은* `Epoch`의 *같은* 리비전이 두 번째로 도착한
    것뿐이라, 이 Observer는 매 변경마다 정확히 한 번 운다
    (`base/state-epoch-plan.md` §4). **`invalid`로 전파를 접는 최적화는
    지금도 금지**다 — `fn`이 `:Get()`을 안 하면 상류 State는 계속
    `invalid`로 남으므로, 그런 규칙이 있으면 **이 Observer는 두 번째
    변경부터 영원히 안 울린다**(2026-08-14 이전에 실제로 그 문장이 위
    "전파 모델 확정" 절에 있었고 이 계약과 충돌한 채 방치됐었다 —
    `archive/invalidate-dedup-propagation-reversed.md`). **두 서술은 같이
    움직여야 함** — 전파를 접는 최적화를 다시 넣고 싶어지면 반드시 이
    항목부터 확인할 것.
- **`fn`을 커링 스타일로 짜는 것도 모듈화 관용구로 권장(2026-08-07 여섯
  번째 세션)** — `state:Observer(makeLogger("x"))`처럼 팩토리가 실제
  `fn`을 만들어 반환하는 패턴, `Modifier`의 `Boldify(10)` 커링(`modifier-plan.md`
  8번)과 같은 결. `base/effect-plan.md`의 Effect도 동일하게 권장.
- **base가 제공하는 것은 `isObserver`류 타입 판별자 하나** — children
  배열 dispatch가 숫자 슬롯 값을 훑을 때 "이게 Observer인가"를 판별해
  `Ref`와 같은 방식으로 라이프사이클에 묶어주는 것 말고는 base가
  더 해줄 일이 없음. 새 dispatch 메커니즘이 아니라 기존 children-array
  참가자 패턴의 반복.

### 동적 경로 가드 — `k` 무관 매치, `HANDLER_PRIORITY_FALLBACK`

(2026-08-14 열한 번째 세션, `PreRef`의 동적 경로 가드와 같은 패턴.)
**⚠️ [2026-08-24] 이 가드를 실제로 `Dispatch.addHandler`로 등록하는 것은
M3(디스패치)다.** `HANDLER_PRIORITY_FALLBACK` 상수도 `Dispatch.addHandler`도
M3에서 처음 생기므로, M2(반응형 코어)에서 본체를 짤 때는 **핸들러 정의만
준비해두고 등록 호출은 미룬다** — `ROADMAP.md` M3의 "Observer/Effect 동적
경로 가드 등록" 체크박스가 그 자리다(2026-08-24 마일스톤 순서 교체의 산물,
M2가 M3에 개념상 지던 유일한 의존이라 이쪽으로 미뤄졌다).

`Observer`도 children 배열 리터럴 전용이라, 해시 파트 named 자리
등으로 동적으로 흘러들어오면(타입 우회 버그) 명확히 에러내야 함 —
전용 `Handler` 등록: `{ priority = HANDLER_PRIORITY_FALLBACK,
isHandlable = function(inst,k,v) return isObserver(v) end, process =
function(inst,k,v) error(`Ref/Observer binding should be array index item,
but got {typeof(k)}`) end }`.
**[요구 추가, 2026-08-18 구현 전 QA] 에러 메시지에 실제 `k`의 타입을
실을 것.** 사용자 요구: *"Priority Fallback 이 type(k) == "string" 인
상황에서는 가장 위에 Ref/Observer binding should be array index item, but
got typeof k 처럼 알려줄 필요는 있는듯"*. 근거는 **메시지에 `k` 타입이
없으면 최종 사용자가 두 원인을 구분할 수 없다는 것** — (a) 핸들러가
등록이 안 된 것인지, (b) `MyRef = Ref(...)`처럼 named 자리에 잘못 쓴
것인지. 같은 규칙이 `base/ref-plan.md`의 `PreRef`/`PostRef` 동적 경로
가드와 `base/effect-plan.md`의 `Effect` 가드에도 그대로 적용된다.
`HANDLER_PRIORITY_FALLBACK`인 이유는 이게 무조건 막는
하드 블록이 아니라 `Tag`/`Attribute`/`PreRef`와 같은 "base가 소유하되
평범한 우선순위로 등록된 다른 Handler가 있으면 그쪽이 이기는" 자리이기
때문(`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는
엔진 op" 절) —
지금은 아무도 그 자리를 안 가져가서 항상 이 가드가 에러를 내지만, 이
Handler를 만드는 게 목적이 아니라 "지금은 확정된 기능이 없다"는 default를
base가 값싸게 제공하는 것뿐. (**이 가드가 없던 이전엔** 확정된 "매치
실패는 즉시 error" 규칙에 의해 결과적으로 똑같이 에러가 났었음 — 이
가드는 동작을 바꾸는 게 아니라 에러 메시지를 명확하게 하고, 미래에
override할 자리를 구조적으로 열어두는 것.)

이어서, base가 제공하는 나머지 항목:

- **콜백 실행은 기존 `canExecute` predicate로 게이팅**(Slot 생존 확인과
  동일한 재사용 — "canExecute 하나로 통일" 원칙, 새 메커니즘 발명 아님)
  — 발화 시점과 처리 시점 사이에 owning leaf가 이미 죽었으면 no-op.
  **[명시화, 2026-08-14 다섯 번째 세션] 이 게이팅이 일어나는 자리는 State의
  전파 루프**다 — State는 구독자를 **weak로** 담고 `sub:_receive(from)`을 부르며, 발화
  시 Observer 자신의 `_receive`가 `canExecute(observer)`를 확인해 거짓이면 홀드
  (**[2026-08-28 `EmitReceive`]**). 여기에
  `inst`가 없다는 사실이 `canExecute`가 `value` 하나만 받아야 하는
  이유(`base/lifecycle-pattern.md`의 "실제 호출부" 절, 옛 2-인자
  시그니처의 역전 경위는 `archive/canexecute-inst-arg-reversed.md`).
  구독자를 weak로 담아도 되는 이유는 살려두는 책임이 State가 아니라
  `gchold`(leaf) 또는 전역 `Subscribed` 레지스트리에 있기 때문 — 어디에도
  안 묶인 Observer는 GC되어 구독 목록에서 자연히 빠짐.
- **구현 노트(사용자 제안, 확정된 아키텍처는 아니고 구현 시 참고)**:
  살아있는 Observer 집합을 Observer 값 내부 필드로 안 두고, 외부에
  weak table(`{[observer] = true}`, `__mode = "k"`)로 인덱싱하는 방식을
  선호 — 포인터 해싱 비용만 들고 값 자체엔 부작용 없음. rbvm의
  `getNamespaceOf`류가 비슷한 외부 weak-table 인덱싱을 씀
  (`base/lifecycle-pattern.md` 참고).
- **⭐⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-23` — 실측] 전파 루프는
  구독자 집합을 **스냅샷으로 복사한 뒤** 돈다.** Lua/Luau에서 순회 중
  **기존 키의 값 변경은 안전하지만 새 키 추가는 미정의**인데, **그 순회 도중
  같은 테이블에 새 키가 추가되는 정상 경로가 있다.**
  - **실측(로컬 `luau` 0.734)**: 구독자 8개짜리 집합을 순회하며 첫 콜백에서
    새 구독자 1개를 등록했더니 `obs8 fired=2` / `obs4 fired=2` /
    `obs1 fired=2, obs2 fired=0`처럼 **실행마다 결과가 달랐다**(어떤 실행은
    깨끗했다). `pairs()`로 명시해도 같았고 **크래시는 안 났다** — 즉 터져서
    금방 잡히는 종류가 아니라 **간헐적으로 한 Observer가 통째로 누락되는**
    종류다.
  - **가상의 오용이 아니라 문서가 권장하는 조합에서 나온다**:
    `slot:List(store.items, function(...) return Row { Text = store.items:Compute(...) } end)`
    — `store.items:Set(...)` → 전파 루프 시작 → 그중 `_listObserver`가
    `reconcile` → `updateFn` → `Dispatch.drive` → `store.items:Compute(...)`가
    **같은 집합에 새 키를 삽입**한다. 재진입 자체는 이미 정상 경로로
    인정돼 있다(`Dispatch.process`의 (A)/(B) 분기).
  - **`Epoch` 규칙으로는 못 막는다** — dedup은 "같은 emit이 두 번 도착했을 때
    접는" 것이라 **이중 발화는 접히지만 누락은 안 접힌다.**
  - **확정된 계약**: 순회 전에 배열로 스냅샷을 뜨고 그 배열을 돈다.
    **이번 파동 중에 붙은 구독자는 다음 파동부터 참여한다.** 스냅샷과 실제
    발화 사이에 죽은 구독자는 기존 `canExecute` 게이트가 걸러준다(그래서
    스냅샷이 stale해도 안전하다). 비용은 파동마다 배열 하나.
  - **같은 처방이 `Ref.Callbacks`에도 적용된다**(`base/ref-plan.md`) — 그쪽도
    같은 모양의 순회이고, 같은 날 해시맵 셋으로 바뀌면서 더 분명해졌다.
- **인자 없는 `state:Observer()` — "항상 관측" 유틸.** `fn`을 생략하면
  내부적으로 no-op 콜백을 쓰는 것으로 취급해, 그냥 "이 State를 계속
  능동적으로 관측 상태로 유지"하는 용도로만 씀. 위 "`previous` 인자"
  절의 캐비엇("능동적 관측 경로가 안 남아있으면 mutate 로직이 조용히
  멈춘다")을 만족시키는 가장 단순한 도구 — 별도 콜백 로직 없이 그냥
  이 State가 계속 재계산되게만 강제하고 싶을 때 씀. 문서화만 확실히
  하면 별문제 없음(사용자 판단).
  - **⭐ [2026-08-25 정정, 7라운드 `H-61`] 내부 콜백은 no-op가 아니라
    `function(targetState) targetState:Get() end`이다**(**[2026-08-26
    표기 정정, `H-109`]** — 파라미터 이름이 `self`였는데 확정된 전파 루프
    시그니처에서 1번 자리는 Observer가 아니라 **리시버 State**다. 값은
    처음부터 그걸 뜻했다). 전파가 push-invalidate /
    pull-recompute라 `Get()`을 안 부르면 재계산이 아예 안 일어난다 —
    같은 절이 바로 위에서 *"값을 안 실어줌 — 반드시 `Get()`을 다시 해야
    함"*이라 못박고 있으므로, no-op 콜백이었다면 이 유틸은 자기 용도
    (`previous` 패턴의 mutate 로직을 계속 돌게 하기)를 **하나도 못
    한다**. 이름("항상 관측")과도 이쪽이 맞는다.

### Slot 생존 확인 — 별도 메커니즘 아님, `canExecute` 재사용으로 확정

state를 옵저빙해서 나온 결과로 slot에 `clear`/`add` 같은 연산을 할 때,
그 시점에 대상 slot이 이미 죽어있으면 어떻게 되는가 — 별도 메커니즘을
새로 만들 필요 없이, `base/lifecycle-pattern.md`의 "생명 바인드
유틸"(canExecute predicate)을 state-invalidate 리스너 클로저 등록에도
그대로 재사용하면 됨: 발화 시 `canExecute(value)`(2026-08-14 다섯 번째
세션 최종 시그니처, `inst`를 안 받음) 하나만 확인하고 거짓이면 그냥
no-op. 한때 검토했던 "`isInit=false`면 허용, `isInit=true`+생존확인
거짓이면 불허" 분기 초안은 폐기 — `isInit` 분기라는 별도 개념 자체가
불필요(사용자 확정: "canExecute 하나로 통일").

## Observer의 `:Subscribe()`/`:Unsubscribe()` — children 배열 밖 독립 구독 (2026-08-06 후속 세션)

**문제**: children 배열에 넣는 자동 라이프사이클 바인딩은 Observer가
"어딘가 leaf에 붙어있다"는 걸 전제함. 근데 흔한 실사용 패턴 하나가 이
전제를 깨뜨림 — 개발자가 디버깅용으로 `RunService:IsStudio()` 가드
안에서 Store에 직접 Observer를 걸어 `print`하는 패턴(원하면 BooleanValue
로 부분부분 켰다 껐다 하기도 함). 이건 다크패턴이 아니라 오히려 방어적인
엔지니어링이고, 붙일 leaf 자체가 없는 "전역/독립" 사용이라 위 weak-table
기반 자동 추적이 적용 안 됨. **[용어 정정, 2026-08-09 여섯 번째 세션]**
여기서 "weak-table 기반 자동 추적"이라 부른 것이 나중에 정식으로
`bindLifetime`(`base/lifecycle-pattern.md`)으로 명명됨 — 별도 메커니즘
두 개가 아니라 같은 것의 명명 전/후 표현.

**⭐⭐ [2026-08-25 신설, 7라운드 `H-58`/`H-59`] `:WeakSubscribe()` /
`:WeakUnsubscribe()` — 약하게 등록하는 짝.** `Weak` 쪽이 **프리미티브**이고
평범한 `:Subscribe()`는 그 위에 "GC 안 되도록 킵" 하나를 더 얹은 것이다
(**사용자 확정**: *"동작 자체는 Weak 아닌것과 동일하게 가고, 가드도 동일하나
단순히 gc 안 되도록 킵 해주는 부분만 제거된 함수가 됩니다"*). 즉
`Subscribe() = WeakSubscribe() + 강한 레지스트리에 킵`이다(**[2026-08-28 `H-149`]**
"구현이 한 벌"은 이제 **의미**가 한 벌이라는 뜻이지 위임이 아니다 — `Subscribe`가
`self:WeakSubscribe()`를 부르면 `error(…, 2)`가 quad 내부 줄을 가리키고 콜론
위임이 서브 테이블 오버라이드를 타므로 인라인했다, `lifecycle-pattern.md` (2)).

- **⭐⭐ [2026-08-26 확정, 8라운드 `H-111`] `WeakSubscribe`도 `.Subscribed = true`를
  세운다.** 즉 갈라지는 지점은 **레지스트리를 강하게 잡느냐뿐**이고,
  `.Subscribed` 플래그는 **강·약 구독 경로 공용**이다. 이게 정해져 있지
  않아서 두 해석이 각자 다른 확정 문장에 뿌리를 두고 있었고, 안 세우는
  쪽으로 읽으면 `Observer:_receive`의 `canExecute(sub)` 게이트(**[2026-08-28 `EmitReceive`]** 옛 표현 "전파 루프의")가 항상 거짓이 되어
  **`Effect`의 State dep 전량이 조용히 침묵**한다(`Effect`의 내부 Observer는
  `WeakSubscribe`로만 등록되고, gcconn 경로는 핸들에만 있으므로 남는 판정
  근거가 `.Subscribed`뿐이다). 사용자 원문 *"구현이 한 벌"*과도 이쪽이
  정합하다. 따라서:
  - `WeakSubscribe()` = 가드 + `.Subscribed = true` + 약한 레지스트리 등록
  - `Subscribe()` = 그 위에 **강한 킵 하나만** 추가
  - `Unsubscribe()`/`WeakUnsubscribe()`는 대칭으로 `.Subscribed`를 내린다
  - **⭐ [2026-08-26 신설, `/code-review high` 5차] 해제는 *건 경로로* 푼다** —
    강하게 구독된 값에 `WeakUnsubscribe`, 약하게만 구독된 값에 `Unsubscribe`는
    **둘 다 error**다(양방향 fail-fast, 사용자 확정). 후자를 안 막으면 조용히
    성공해서 범용 정리 코드가 `Effect`의 내부 Observer(오직 `WeakSubscribe`로만
    등록된다)를 죽이고 **State dep 전량이 침묵**한다. 의사코드는
    `base/lifecycle-pattern.md`의 "(2) 전역 경로" 절이 소스.
  - `base/lifecycle-pattern.md`의 `isBoundAlive` (b) 경로 주석이 이에 맞춰
    "전역 경로: `:Subscribe()`가 세운 것"에서 "구독 경로(강/약)가 세운 것"
    으로 정정됐다. **기각된 대안**: `canExecute`의 전역 경로 판정을 필드
    대신 레지스트리 멤버십으로 바꾸는 안 — 동작은 같지만 해제가 양쪽
    테이블을 지워야 하는 대칭 요구가 새로 생긴다.
- **자료구조**: 전역 레지스트리에 **약하게** 들어간다. 살려두는 책임은
  **잡고 있는 쪽**에 있다 — `Effect`가 자기 내부 Observer를 `_deps`에
  강하게 들고 있는 게 그 예다(`base/effect-plan.md`의
  "확정 구조 — 강한 주인은 항상 `Effect`" 절).
- **왜 필요한가**: `Effect`가 dep마다 Observer를 만들 때 평범한
  `:Subscribe()`를 쓰면 전역 레지스트리가 그 Observer를(따라서 `Effect`를)
  영원히 붙든다. 그렇다고 바인드/언바인드마다 등록·해제하면
  *"등록 시점에 즉시 1회 실행"*에 걸려 **바인드마다 `Rerun`이 dep 수만큼
  돈다**. `WeakSubscribe`면 둘 다 사라진다.
- `Ref` 쪽의 짝은 `ref:WeakCallback(fn)`이다(`base/ref-plan.md`).

**해결**: 명시적 `:Subscribe()`/`:Unsubscribe()`를 추가로 지원. 이건 새
설계가 아니라 PA님 코드 교차검증(아래 라이프사이클 절)에서 이미 예고해둔
확장 지점을 실제로 채우는 것 — "나중에 GC만으로 정말 부족한 케이스가
생기면 명시적 dispose 경로를 추가로 얹는 게 가능한 디자인"이라고 그때
이미 못박아뒀음.

- **`local` 변수로 참조만 들고 있는 것으로는 부족한 이유**: 토글(BooleanValue로
  로깅 껐다 켰다) 케이스에서, 참조를 끊어도 실제 GC는 결정론적으로 즉시
  일어나지 않음 — "껐다"고 생각한 뒤에도 한동안 계속 발화할 수 있음.
  `:Unsubscribe()`는 즉시/결정론적으로 끊는 경로라 이 문제가 없음.
- **liveness 체크는 두 경로를 하나의 predicate로 OR 묶음**(사용자 제안) —
  자동(리프 부착=`bindLifetime`)/수동(전역 `:Subscribe()`) 두 라이프사이클
  경로를 `canExecute(value)` 하나가 답함:
  ```lua
  -- 개념 스케치. 확정 구현은 base/lifecycle-pattern.md가 소스
  local gcconn = BindData:GetWeak(self, "gcconn")   -- leaf 경로(bindLifetime이 복사해둠)
  if gcconn ~= nil and gcconn.Connected then return true end
  return self.Subscribed == true                    -- 구독 경로(강/약 공용, H-111)
  ```
  **[정정, 2026-08-14 다섯 번째 세션]** 이 절의 옛 스케치는 `self.Subscribed`를
  먼저 보고 `self.Connection`을 폴백으로 두는 모양이었는데, `.Subscribed`는
  **전역 경로 전용 필드라 리프 경로와 무관**하므로 우선순위 자체가 의미
  없음(두 경로는 상호 배타라 OR 순서는 성능 취향일 뿐). "필드 접근이 weak
  table 조회보다 싸다"는 관찰은 유효하지만, 그건 `.Subscribed`를 리프
  경로에도 겸용하라는 근거가 못 됨 — 실제로 2026-08-08 세션이 그렇게
  겸용했다가 `canExecute` 시그니처까지 오염됐음
  (`archive/canexecute-inst-arg-reversed.md`). 실측은 구현 단계에서 확인.
- **내부 강참조 레지스트리**: `SubscribedObservers: {[observer]: true}`류를
  **weak 아닌 강참조**로 둠 — 여기서 weak면 "구독해서 살려둔다"는 목적
  자체가 무의미해짐. 위 자동 케이스의 weak table과 역할이 명확히 갈림
  (weak table=자동/리프 전용, 강참조 레지스트리=수동 구독 전용).
  **`:Unsubscribe()`는 이 레지스트리에서 반드시 `SubscribedObservers[observer]
  = nil`까지 해야 함** — `Subscribed` 플래그만 내리고 강참조를 안 끊으면
  GC 대상이 안 되는 반쪽짜리 해제가 됨.
  **⭐ [2026-08-26 정정, 8라운드 `H-111`]** 여기 한때 *"둘은 항상 같이
  일어나는 한 세트"*라고 적혀 있었는데, `:WeakSubscribe()`가 생기면서
  거짓이 됐다 — **약한 구독은 `.Subscribed`는 세우고 이 강한 레지스트리는
  안 건드린다**(약한 레지스트리만 채운다). 그 문장 그대로면 `WeakSubscribe`의
  정상 동작이 반쪽짜리 해제로 오독된다. 네 진입점의 짝 표는
  `base/lifecycle-pattern.md`의 "(2) 전역 경로" 절이 소스. **여전히 참인
  것**: `:Unsubscribe()`는 자기 짝(강한 레지스트리 + 필드)을 다 지워야 한다.
- **⛔ [2026-08-26 폐기, `/code-review high`] "둘 다 idempotent"는 틀렸다.**
  여기 한때 *"이미 구독 중인데 또 Subscribe해도, 구독 안 했는데
  Unsubscribe해도 에러 안 나고 그냥 no-op. 토글 로직 짤 때 상태 추적 부담을
  줄여줌"*이라고 적혀 있었는데, **2026-08-18에 `canBound` 게이트가 들어오면서
  `:Subscribe()`는 error가 됐고** 그 모순이 그대로 방치돼 있었다(`H-111`로
  `WeakSubscribe`도 같은 게이트를 타면서 표면이 더 넓어졌다). **사용자 확정:
  확정 의사코드가 정본**이다.
  - **`:Subscribe()`는 idempotent가 아니다** — 이미 구독됐거나 leaf에
    바인드된 값에 다시 부르면 **error**(`base/lifecycle-pattern.md`의
    "(2) 전역 경로" 절). 이중 바인딩 금지가 `canBound` 하나로 통일돼 있고
    (`bindLifetime`도 같은 게이트), 조용한 no-op보다 fail-fast가 이 코퍼스의
    기조다.
  - **⚠️ [2026-08-26 재정정, `/code-review high` 6차] `:Unsubscribe()`도
    idempotent가 아니다.** 여기 한때 *"게이트가 없어 … 비대칭이 의도된 것"*
    이라고 적혀 있었는데, 같은 날 **대칭 가드**가 들어오며 거짓이 됐다(위 항목).
    지금 계약은 **해제는 건 경로로 푼다** 하나다. **[2026-08-27 9라운드
    `H-133`]** 그 대칭 가드는 *경로 교차*(강↔약)만 막는다 — 구독한 적 없는
    값·이미 약하게 풀린 값에 `WeakUnsubscribe`는 **조용히 통과**(의도된 관대함,
    사용자 논거와 함께 `base/lifecycle-pattern.md` (2)가 소스), 같은 값에
    `Unsubscribe`는 error.
- **[정정, 2026-08-09 여섯 번째 세션] "`:Unsubscribe()`는 자동(리프)
  케이스에도 동일하게 씀"은 틀림 — 리프/`bindLifetime` 경로의 조기
  해제는 `unbindLifetime(value)`가 담당, `:Unsubscribe()`는
  전역 강참조 레지스트리 경로 전용으로 남음.** 둘이 지우는 대상이 서로
  다르기 때문 — `:Unsubscribe()`는 전역 레지스트리와 `.Subscribed` 필드를,
  `unbindLifetime`은 `inst`의 gchold 항목과 `value`가 들고 있던 gcconn
  참조를 지움. 아래 "이중 바인딩 금지" 절의 정정 참고.
  **[정정, 2026-08-14 다섯 번째 세션]** 이 항목이 원래 들었던 이유(*"`inst`를
  모르는 `:Unsubscribe()`가 어느 `inst`에 등록했는지 찾아낼 방법이 없다"*)는
  이제 성립 안 함 — `unbindLifetime`도 `inst`를 안 받고 `value` 하나로
  해제함(`value`가 자기 홀더를 알고 있음). 결론(두 함수를 안 합침)은
  그대로지만 근거가 "찾을 수 없어서"가 아니라 "지우는 대상이 달라서"로
  바뀜.
- **`state:Observer(fn):Subscribe()`처럼 참조를 아무 데도 안 담아도 정상**
  — 강참조 레지스트리 자체가 생존을 보장하는 유일한 근거라, 로컬 변수에
  담아둘 필요가 없음. 예외 없이 그냥 계속 돎(그게 이 메커니즘의 핵심
  포인트).
- **⚠️ 이건 quad 전역의 "정리는 기본적으로 GC에 위임" 원칙의 의도적
  예외 — 문서에 명시적으로 경고할 것(2026-08-09 열한 번째 세션).**
  `:Subscribe()`로 등록한 뒤 로컬 변수 참조를 전부 놓아도(스코프 이탈,
  변수 재할당 등) **GC되지 않고 영원히 계속 실행됨** — 강참조
  레지스트리가 그 자체로 생존을 보장하기 때문. `bindLifetime`(leaf
  부착 포함) 경로는 `inst`가 죽으면 자동으로 정리되는 GC-native 그대로지만,
  `:Subscribe()` 경로는 오직 명시적 `:Unsubscribe()` 호출로만 끊김 — 이
  차이를 모르고 "quad는 다 GC-native니까 참조만 버리면 되겠지"라고
  가정하면 조용한 누수(메모리뿐 아니라 계속 재실행되는 콜백까지)로
  이어짐. 용도도 "완전히 top-level(어떤 Instance 생명주기에도 안 묶인)
  사이드 이펙트"로 좁게 문서화할 것 — 특정 `inst`에 묶인 경우는
  `:Subscribe()`가 아니라 leaf 부착(`bindLifetime`)이 정상 경로.
- **`:Subscribe()`/`:Unsubscribe()` 둘 다 `self`를 리턴(대칭)** —
  `local obs = state:Observer(fn):Subscribe()`처럼 "구독 시작 + 나중에
  끊을 핸들 확보"가 한 줄로 되고, `table.insert(subs, state:Observer(fn)
  :Subscribe())`처럼 리스트에 담을 때도 줄바꿈 없이 됨. Observer가
  immutable 값이 아니라 원래 mutable한 구독 핸들이라 fluent 체이닝이
  자연스러움 — Modifier의 clone-then-return 체이닝과는 다른 이유(같은
  객체를 mutate하고 그대로 돌려주는 것)지만 표면 문법은 비슷하게
  체이닝 가능.

## 이중 바인딩 금지 — 진짜 독립된 경로는 `:Subscribe()`(전역)와 `bindLifetime`(inst-scoped) 둘뿐, `canBound(value)`로 즉시 에러 (2026-08-07 일곱 번째 세션, 2026-08-09 세션에서 `canBound`로 이름 확정, 같은 날 여섯 번째 세션에서 "leaf 부착=bindLifetime 호출"로 정정, 2026-08-14 다섯 번째 세션에 `canBound` 폐기·`canExecute`로 통합됐다가 **같은 날 열한 번째 세션에 `canBound`가 별도 진입점으로 재도입되어 다시 갈라짐** — 판정 로직은 공유, `base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절이 소스)

**규칙**: 같은 Observer/Effect 핸들 하나는 라이프사이클 바인딩 경로를
딱 하나만 가질 수 있음 — `:Subscribe()`로 전역 강참조 레지스트리에
등록되거나(위 절), `bindLifetime(inst, value)`로 특정 `inst`에 종속되거나
(아래 "`bindLifetime`이 이 게이트의 두 번째 진입점" 절) — **이 둘 중 하나만**.

**[정정, 2026-08-09 여섯 번째 세션] "leaf 부착"은 세 번째 독립 경로가
아니라 `bindLifetime`을 호출하는 것 그 자체다.** `Frame { observer }`처럼
children 배열에 Observer를 직접 놓으면, `Dispatch/Leaf.luau`가 이걸
매치해 내부적으로 `bindLifetime(inst, observer)`를 호출 — "children
배열에 놓여 leaf에 자동 부착"과 "`bindLifetime`으로 특정 `inst`에
종속"은 **같은 동작**이라 서로 배타적일 수 없음(둘 다 하는 게 아니라
leaf 부착이 곧 `bindLifetime` 호출 방식 중 하나일 뿐). 그래서 실제
상호 배타는 "전역 소유(`:Subscribe()`)" vs "특정 `inst` 소유
(`bindLifetime`, 직접 호출이든 leaf 부착을 통한 호출이든)"라는
**2-way**로 정정 — 위 "Observer의 `:Subscribe()`/`:Unsubscribe()`" 절이
leaf 부착을 "weak table 기반 자동 추적"이라 불렀던 건 `bindLifetime`이
정식 이름을 얻기 전(2026-08-06 후속 세션) 표현이라 지금은 같은 것을
가리킴 — 별도 메커니즘 두 개가 있던 게 아니었음.

**둘 이상 동시에 걸리는 건 UB로 확정** — 이미 한 경로로 바인딩된 핸들을
다른 경로로 또 바인딩하는 건 금지(leaf로 이미 부착된 걸 `:Subscribe()`
하는 것, 또는 그 반대). 같은 값을 `bindLifetime`으로 두 번(leaf 부착
한 번 + 직접 호출 한 번, 또는 leaf로 두 Instance에 부착) 등록하려는
것도 걸림 — 이건 "leaf vs bindLifetime 충돌"이 아니라 "같은 단일
메커니즘을 중복 호출"하는 것이라 자연히 같은 게이트가 잡아줌.

**UB를 조용한 오동작이 아니라 즉시 에러로 만든다** — 판별 비용이 사실상
0(불리언 필드 하나 확인)이라, 조용히 이상하게 동작하게 두는 것보다
바로 에러를 던져 버그를 그 자리에서 잡는 게 엔지니어링상 훨씬 쌈.

**[2026-08-14 다섯 번째 세션에 별도 predicate `canBound(handle)`을 폐기하고
`canExecute(value)` 하나로 통합했다가, 같은 날 열한 번째 세션에
`canBound`가 다시 별도 진입점으로 도입됨]** — `Ref`가 emit 전파에 참여도
안 하면서 "발화해도 되는가"(`canExecute`)를 묻는 게 개념적으로 안 맞다는
지적(`question.md` 0-W)에서 나온 재분리. 게이트는 이 모양:

```lua
-- :Subscribe() 진입부, bindLifetime 진입부(leaf 부착도 내부적으로 이걸 거침)
-- — 둘 다 진입 전 동일하게 확인. [정정, 2026-08-18 구현 전 QA] canBound는
-- "지금 묶어도 되는가"(참 = 아직 안 묶임)라 게이트는 `not`이 붙는다.
if not canBound(self) then
  error(if self.Subscribed
    then "이미 구독된 값"        -- [2026-08-26 H-111] 강/약 어느 쪽이든 이 분기
    else "이미 다른 Instance에 바인딩된 값")
end
```

> **⚠️ [2026-08-26 정정, 8라운드 `H-111`] 아래 세 항목과 이 절 끝의 정정
> 문단이 `.Subscribed`를 "전역 `:Subscribe()` 전용"이라고 부르는데, 그건
> `:WeakSubscribe()`가 생기기 전 서술이다.** 지금은 **구독 경로(강/약) 공용**
> 이다 — 약한 쪽도 이 필드를 세우고, 갈라지는 건 레지스트리를 강하게
> 잡느냐뿐이다(위 `:WeakSubscribe()` 절, `base/lifecycle-pattern.md`의
> 네 진입점 의사코드가 소스). **`bindLifetime`/`unbindLifetime`이 이 필드를
> 읽지도 쓰지도 않는다는 요지는 그대로 유효하다** — 바뀐 건 "구독 쪽에서
> 누가 세우는가"뿐이다. 옛 에러 문구 *"이미 `:Subscribe()`로 전역 바인딩된
> 값"*은 `WeakSubscribe`로만 등록된 값(예: `Effect`의 내부 Observer)까지
> 가리키므로 **틀린 원인을 지목한다** — 위 스니펫처럼 넓혔다(실제 문구는
> 영어, `base/architecture.md`의 error 계약).

- **[정정, 2026-08-18 구현 전 QA] `canBound`와 `canExecute`는 값이 같은 게
  아니라 서로의 부정이다** — `canBound(v) == not canExecute(v)`. 둘이
  공유하는 건 판정 **로직**(비공개 헬퍼 `isBoundAlive`,
  `base/lifecycle-pattern.md`)이지 판정 **값**이 아니다. 옛 서술("판정
  로직이 같아서 값도 항상 같지만 호출부의 질문만 다르다")은 `canBound`를
  "이미 묶여 있는가"로 잘못 읽은 것이었음. 이 절(이중 바인딩 금지)은
  `canBound`를 쓰고, State emit 전파 루프만 `canExecute`를 씀.
- **에러 메시지에서 어느 경로인지는 `.Subscribed`로 가름** — 이 필드는
  **구독 경로에서만 세팅되므로**(위 ⚠️: 강·약 공용, `H-111`) 참이면 구독,
  거짓인데 `canBound`가 **거짓**이면 leaf 경로.
- 이 predicate는 어느 경로가 먼저 왔는지와 무관하게 "지금 묶어도 되는가"만
  답함 — 두 진입점이 똑같이 `canBound`를 확인하므로 순서와 무관하게
  대칭적으로 막힘.
- **죽은 바인딩의 재사용은 허용** — `inst`가 Destroy됐거나
  `unbindLifetime`된 값은 `canBound`가 **참**이라 게이트를 통과함(다른
  `inst`에 다시 걸 수 있음). 게이트가 막는 건 **살아있는** 이중 바인딩뿐.

**[정정, 2026-08-14 다섯 번째 세션] 옛 서술 — "`canBound`의 내부 플래그는
`canExecute`가 이미 보는 `.Subscribed` 필드 그 자체이고, `bindLifetime`도
그 필드를 세팅한다"(2026-08-09 여섯 번째 세션)는 틀렸음.**
`.Subscribed`는 **구독 경로 전용 필드로,
`bindLifetime`/`unbindLifetime`과는 일절 이해관계가 없다**(**[2026-08-26
`H-111`]** 여기 "전역 `:Subscribe()`/`:Unsubscribe()` 전용"이라 적혀 있었으나
`:WeakSubscribe()`/`:WeakUnsubscribe()`도 같은 필드를 쓴다 — 위 ⚠️) — 이 둘은
그 필드를 읽지도 쓰지도 않음. leaf 경로의 생존은 `bindLifetime`이
`value` 쪽 릴레이션에 복사해둔 gcconn 참조로 판정됨(`base/lifecycle-pattern.md`).
옛 서술이 걱정했던 "필드를 둘로 나누면 `bindLifetime`으로만 등록된
Observer가 **안 묶인 것으로 오판**됨"은 실제로는 안 일어남 —
`canBound`/`canExecute`가 공유하는 `isBoundAlive`가 gcconn 경로를
**먼저** 보므로, 그런 Observer는 `canBound`가 제대로 거짓이 된다. 역전 원문·오염 경로·교훈은
`archive/canexecute-inst-arg-reversed.md`(그 문서 하단에 이 재분리
경위도 추가돼 있음).
- **`:Unsubscribe()`는 `:Subscribe()` 경로의 해제만 담당, `bindLifetime`
  (leaf 부착 포함) 경로는 `unbindLifetime(value)`로 해제** —
  둘은 서로 다른 함수로 남음(호출자가 `bindLifetime`을 부른 쪽이
  `unbindLifetime`도 대칭적으로 부르는 책임을 짐). 지우는 대상이
  서로 다르므로 하나로 합칠 수 없음 — 위 `:Subscribe()` 절의 같은
  정정(2026-08-14 다섯 번째 세션) 참고. leaf 부착으로
  세워진 바인딩의 실제 해제도(예: Instance 파괴 전 조기 해제하고 싶을
  때) 결국 `unbindLifetime`이 담당 — 위 "`:Unsubscribe()`는 자동(리프)
  케이스에도 동일하게 씀" 절의 서술은 leaf 부착이 별도 메커니즘이라고
  전제했던 것이라 **이 정정으로 대체**(`:Unsubscribe()`가 아니라
  `unbindLifetime`이 leaf 해제의 실제 통로).
- **Effect도 동일 규칙 적용(사용자 확인)** — Effect가 `state` 인자로
  내부적으로 Observer를 조합하는 경우든, `state` 없는 경우든 같은
  `canBound` 게이트를 그대로 재사용(`base/effect-plan.md`) — **[2026-08-28
  정정]** 여기 한때 "Effect 자신이 아니라 내부 Observer가 게이트를 갖고 있어서
  자동으로 커버됨"이라 적혀 있었는데 틀렸다: 내부 Observer는 생성자에서
  `Weak*`로만 걸리고 발화는 `canExecute(handle)`이 막으므로(`H-58`/`H-59`) 그
  게이트는 핸들의 이중 바인드를 막지 못한다. `EffectHandle`이 **자기 네
  진입점에서 `canBound(self)`를 직접 돈다**(`H-144` (b)). 이전에 그 문서에 적어뒀던 "leaf
  부착과 `:Subscribe()`를 동시에 쓰는 것도 안전"이라는 서술은 **이
  규칙으로 대체(정정)** — 안전하게 지원하는 게 아니라 애초에 막아야
  하는 조합이었음.
- **문서화 경고 대상(api/심화)**: "한 Effect/Observer 핸들을 children
  배열에 놓았다면(=`bindLifetime`으로 등록된 것) 그걸 다시
  `:Subscribe()`하거나 다른 Instance에 또 leaf로 놓지 말 것, 반대도
  마찬가지 — 여러 경로를 동시에 쓰고 싶으면 각각 독립된 새
  `Effect(...)`/`state:Observer(...)` 호출로 따로 만들 것"을 명시할 것.

### `bindLifetime`이 이 게이트의 두 번째(이자 leaf 부착이 실제로 쓰는) 진입점이다 (2026-08-09 여섯 번째 세션)

`Dispatch.setLength`처럼 특정 `inst`에 종속된 내부 Observer를 등록할 때
쓰는 `bindLifetime(inst, value)`(`base/lifecycle-pattern.md`)도 **같은
`canBound` 게이트를 확인** — 진입 전 `canBound(value)`를 확인하고,
참이면(=아직 안 묶여 있으면) gchold 등록 + gcconn 참조 복사를 수행.
**children 배열 leaf 부착도 바로 이 `bindLifetime` 호출** —
`Dispatch/Leaf.luau`가 `(i:number, v=Observer/Effect)`를 매치하면
그 자리에서 `bindLifetime(inst, v)`를 호출하는 것뿐, 별도 "leaf 전용"
바인딩 로직이 따로 있는 게 아님. 그래서 **실제 상호 배타는 `:Subscribe()`
(전역 강참조 레지스트리)와 `bindLifetime`(inst별 gchold, 직접 호출이든
leaf 부착을 통한 간접 호출이든) 둘뿐** — 새 규칙을 따로 만들 이유가
없음, 기존 게이트에 진입점 하나(`bindLifetime`, leaf 부착이 그 특수
사례)만 추가.

```lua
function bindLifetime(inst, value)
    if not canBound(value) then -- [정정, 2026-08-14 열두 번째 세션] 이 절이 확정한 대로
                              -- bindLifetime의 게이트는 canBound, canExecute 아님
                              -- [정정, 2026-08-18 구현 전 QA] 방향이 뒤집혀 있었음 —
                              -- canBound 참 = 묶어도 됨이라 에러는 not 쪽
        error("이미 바인딩된 값")   -- 메시지 분기는 위 게이트 스케치 참고
    end
    ... -- gchold 등록 + gcconn 참조 복사(base/lifecycle-pattern.md)
end

function unbindLifetime(value)
    ... -- gchold 항목 제거 + gcconn 참조 해제
end
```

- **[정정, 2026-08-14 다섯 번째 세션] 게이트는 값 타입을 안 가린다** —
  옛 서술은 "`canBound`는 `.Subscribed` 필드가 있는 Observer/Effect 전용
  predicate라 그 외 값(예: Tween 내부 클로저, Slot)은 그냥 통과"였는데,
  공유 헬퍼 `isBoundAlive`는 gcconn 경로를 먼저 보므로 **어떤 값이든** 이미
  살아있는 바인딩이 있으면 걸러짐. 이게 더 맞음 — Slot을 두 `inst`에 이중
  마운트하는 것도 원래 금지(`base/slot-plan.md`의 `elementOwner`)라, 같은
  실수를 `bindLifetime` 층위에서도 공짜로 잡아줌.
- 값이 `bindLifetime`으로 바인딩된 뒤엔 `canBound`가 **거짓**이 되므로, 그
  뒤에 같은 값을 leaf로 놓거나 `:Subscribe()`하면 기존 두 진입점의 기존
  체크가 그대로 걸러줌 — 이 방향은 별도 코드 추가 없이 이미 성립.

### Observer/Effect Leaf dedup — `RefLeafHandler`와 같은 패턴, 순수 성능 최적화(2026-08-14 세션)

**correctness 문제는 아님 — `old ~= v`를 안 넣어도 안 깨짐.** `State<Observer>`/
`State<Effect>`가 재-dispatch될 때 안쪽 값이 그대로여도(같은 객체가 다시 옴)
Dispatch의 (A) 분기(`base/dispatch-core-plan.md` "Dispatch 체인" 절)는 무조건
`retractor(v)`→`process(inst,k,v,index)`를 다시 부름 — 이걸 그냥 둬도
`bindLifetime`/`unbindLifetime`이 `Relate` weak 테이블 쓰기 몇 개뿐이라(위
"(1)" 코드 블록, `base/lifecycle-pattern.md`) 실제 Roblox 커넥션을 만들거나
끊지 않고, 사용자에게 보이는 재통지도 없음(`fn` 재실행은 이 leaf 바인딩이
아니라 자기 내부 구독이 따로 트리거함).

**그래도 dedup을 넣기로 함(사용자 판단)** — `==` 비교 하나(바이트코드 1개
+ 분기)가 매번 여러 weak 테이블 읽기/쓰기(해싱 비용)를 도는 것보다 항상 더
싸서, 이득이 공짜에 가까운데 안 넣을 이유가 없음. `RefLeafHandler`(`base/
ref-plan.md` "`Ref`의 retract" 절)와 완전히 같은 모양을 그대로 재사용:

```lua
local relate = Relate()  -- Observer/Effect-leaf 전용, (inst,k)별 마지막으로 바인딩한 값 기억 —
                          -- process 재실행 시 identical-value dedup(순수 성능 최적화,
                          -- Ref처럼 재통지 부작용이 있어서가 아님)

ObserverEffectLeafHandler.isHandlable(inst, k, v) =
    type(k) == "number" and (isObserver(v) or isEffect(v))
    -- k 타입까지 반드시 체크 — 안 그러면 바로 위 "동적 경로 가드" FALLBACK
    -- Handler(named 자리로 흘러온 값을 에러내려는 것)가 이 자리에 먼저
    -- 매치돼버려 죽은 코드가 됨(2026-08-14 열두 번째 세션 수정)

function ObserverEffectLeafHandler.process(inst, k, v, index)
    -- [2026-08-24 6라운드 `H-39`] **말단 핸들러의 배열 자리 부기** — 빠져
    -- 있었다. 이 자리는 물리 리프를 하나도 기여하지 않으므로 짝을 맞춰 `0`.
    -- 없으면 `Frame { someObserver, Frame{} }`처럼 leaf가 앞에 오는 배치가
    -- 첫 `recompute`에서 `sourceList[k]가 nil`로 죽는다
    -- (`base/dispatch-core-plan.md`가 확정한, 값이 없는 자리도 짝을 맞춰 `0`을
    -- 등록한다는 규칙).
    Dispatch.setOffsetSource(inst, k, None)
    Dispatch.setLength(inst, k, 0, inst)

    local old = relate:GetWeak(inst, k)   -- ⭐ [2026-08-25 `H-71`] 쓰기가 SetWeak이므로 읽기도 Weak
                                          --   (안 맞추면 old가 항상 nil이라 dedup이 통째로 죽는다)
    if old ~= v then  -- 이미 같은 값이 이 자리를 차지 중이면 재바인딩 skip
        bindLifetime(inst, v)  -- [2026-08-25 정정] Effect도 **핸들 하나만** 바인드된다 —
                               -- dep은 생성자에서 `Weak*`로 걸려 있고 발화는
                               -- `canExecute(handle)`이 게이팅(`base/effect-plan.md`)
    end
    relate:SetWeak(inst, k, v)   -- ⭐ [2026-08-25, 7라운드 `H-71`] Strong 아님 — 아래 참고
    return function(nextValue)
        if nextValue ~= v then
            unbindLifetime(v)
            -- ⭐ [2026-08-25, 7라운드 `H-57`] 값 교체는 파괴에 준한다 — 그 Effect는
            -- 다시 오지 않으므로 cleanup을 여기서 소진 호출한다.
            if isEffect(v) then v:_consumeCleanup() end
            -- [`RefLeafHandler`와 같은 주의] relate 정리는 반드시 이 분기 *안*에서만 —
            -- 밖에 두면 spurious 재발행(nextValue == v)에서도 기록이 지워져 곧바로
            -- 이어지는 process가 `old ~= v`를 항상 참으로 보고 dedup이 무력화됨.
            if relate:GetWeak(inst, k) == v then relate:SetWeak(inst, k, nil) end
        end
    end
end
```

**⭐ [2026-08-25 신설, 7라운드 `H-71`] dedup 기록은 `SetWeak`이다.**
`SetStrong`으로 두면 **값이 `inst`를 되참조할 때 100% 샌다** — 커밋된
`Relate.luau`로 50/50 누수가 실측됐다(`base/relate-plan.md`의 슬롯별 강약
표). dedup은 이 절이 스스로 밝히듯 **순수 성능 최적화**라, weak로 낮춰
엔트리가 조기 소실돼도 "dedup을 한 번 놓친다"까지가 최대 손해다. `v`는
`gchold`가 이미 강하게 잡고 있고, `relate-plan.md`의 **"다른 곳에서
안전하게 유지되는 것은 항상 `SetWeak`"** 규칙에도 그대로 맞는다.
`RefLeafHandler`도 같은 정정을 받는다(`base/ref-plan.md`).

**⭐ [2026-08-25 신설, 7라운드 `H-57`] 값 교체 retract는 cleanup을 부른다.**
`base/effect-plan.md`가 확정한 *"`unbindLifetime`은 cleanup을 부르지
않는다"*는 **포탈 언마운트**를 보고 정한 것인데, `unbindLifetime`의 호출부는
셋이다 — 포탈 언마운트 / 파괴 직전 / **값 교체 retract**. 앞의 둘은
cleanup을 안 불러도 되지만 셋째는 **파괴에 준한다**(그 `Effect`는 다시 안
온다). 안 부르면 `Frame { effectState }`에서 `effectState:Set(E2)` 뒤에도
`E1`의 타이머가 영원히 돈다 — React로 치면 `useEffect` 클로저가 바뀌었는데
이전 cleanup을 안 부르는 것. `_consumeCleanup()`이 **읽고 → 지우고 →
실행**이라 파괴 경로와 이중 호출이 없고, `unbindLifetime`의 계약 자체는
안 건드린다.

## PA님 코드와의 교차검증(2026-08-04 4차 라운드) — 둘 다 기존 확정 유지

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

## 남은 열린 질문

- **`state()`/`Source()`/`Get()` 등 정확한 함수·생성자 이름** — 방향은
  전부 확정, 이름만 구현 단계에서 남음. `State`/`Source`/`Compute` 자체는
  이미 최종 확정(위 "이름 주의"/"네이밍 — `Compute`가 `-ed`가 아닌 이유").
- **이형 다중 trailing deps를 제네릭 팩 하나로 좁힐 수 있는지** — 위
  "trailing deps를 `fn`에 lazy positional 인자로도 노출" 절의 실측 항목
  (`luau-test`의 `15-...`, 현재 스파이크 재작성 필요 상태).
