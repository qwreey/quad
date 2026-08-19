# 구현 전 QA **4라운드** — 확정 전수 재심사 문항지

**상태**: **작성 중 / 사용자 회신 대기**(2026-08-19 세션에서 생성).

**왜 이 라운드가 있는가**: 사용자 요청 — *"요즘 변경이 엄청 많고, 틀려서
정정한게 엄청 많아서, 모든 부분에 있어서 내 심사를 좀 받아야할듯. 예 가
되어야하는 질문들을 계속, 모든 확정 부분에 있어서 해줘. 표면적 타입계약부터,
실제 내부 구현 계획과 동작 원리 등, 모든 부분에 있어서 내가 검토해줄게."*
1~3라운드가 각각 "base 전수 재심사 / 의사코드 손 트레이싱 / RC-1 해법
재트레이싱"이었던 것과 달리, 이번엔 **`base/`에 확정으로 적혀 있는 모든
주장을 "예가 나와야 정상인 문장"으로 다시 뽑아** 사용자 판정을 받는 것이
목적이다.

**작성 방식**: 서브에이전트를 쓰지 않고 한 맥락에서 `base/` 전체를 의존성
순서로 읽으며 작성했다(사용자 지시: *"서브에이전트는 쓰지 말아줘. 한 맥락에서
자연스럽게 흐르는 전체 구조를 보는게 필요해보여."*).

**회신 방법**: 각 문항은 `예/아니오`로 답할 수 있게 썼다. **`아니오`인 것만**
알려주면 되고(어디가·어떻게·왜 틀렸는지 + 원래 뭐가 맞는지), 그 회신을 받은
뒤에 이 문서를 1라운드처럼 "아니오가 나온 항목만 남긴 근거 기록"으로 재편하고
`base/`에 반영한다. **이 세션은 정정을 먼저 하지 않는다** — 사용자 지시:
*"우선 틀린게 있으면, 기록만 해둬."*

**표기**: `X-N`의 `X`는 문서 코드, `N`은 그 문서 안 문항 순번. 1라운드와 같은
코드 체계를 쓰되 문항 번호는 이 문서 안에서 새로 매긴다(1라운드의 `S-1`과 이
문서의 `S-1`은 다른 문항).

| 코드 | 대상 문서 |
|---|---|
| `A` | `base/architecture.md` |
| `S` | `base/source-state-plan.md` |
| `ST` | `base/store-plan.md` |
| `BS` | `base/bind-system-plan.md` |
| `D` | `base/dispatch-core-plan.md` |
| `LP` | `base/lifecycle-pattern.md` |
| `RE` | `base/relate-plan.md` |
| `BR` | `base/brand-plan.md` |
| `M` | `base/modifier-plan.md` |
| `SL` | `base/slot-plan.md` |
| `BK` | `base/blocker-plan.md` |
| `E` | `base/effect-plan.md` |
| `EV` | `base/event-plan.md` |
| `OC` | `base/onchange-plan.md` |
| `R` | `base/ref-plan.md` |
| `T` | `base/tag-plan.md` |
| `AT` | `base/attribute-plan.md` |
| `TW` | `base/tween-plan.md` |
| `CC` | `base/component-composition-plan.md` |
| `UI` | `base/ui-shorthand-plan.md` |
| `ML` | `base/module-lifecycle-plan.md` |
| `DT` | `base/debounce-throttle-plan.md` |
| `LH` | `base/lifecycle-hooks-plan.md` |
| `FB` | `base/fallback-plan.md` |
| `PE` | `base/purity-and-effects-plan.md` |
| `TL` | `base/typing-limits.md` |


## 문항 수와 읽는 순서

**총 510문항**(이 문서가 그 수의 소스 — 다른 곳에 적지 않음). 문서별 분포는
`grep -c '^### '`로 언제든 다시 셀 수 있으니 여기 표로 박아두지 않는다.

전부 한 번에 보기 부담스러우면 아래 순서를 권한다. 이건 **작성한 에이전트의
추정이지 확정이 아니다** — 우선순위가 다르면 그대로 알려주면 된다.

1. **최근에 가장 많이 뒤집힌 영역** — `SL`(Slot: `Detach`/파괴·언마운트/
   `attachSlot` 순서), `D`(Dispatch: 하강 diff·Length/Offset·Blocker 게이팅),
   `S`(Source/State: `canBound` 방향·전파 모델). 2026-08-18~19에 실제로 정정이
   집중된 자리라 stale이 남아 있을 확률이 가장 높다.
2. **이미 ⚠️로 열려 있다고 적은 항목** — 이건 "확정이 맞나"가 아니라 **"아직 열려
   있다는 인식이 맞나"**를 묻는 문항이다: `S-38`(중간 State 생존), `ST-3`/`ST-8`
   (Store 미선언 키 실측·`GetDynamic` 위치), `E-10`(dedup 대칭), `SL-45`
   (`Detach` 홀드 중 키 소멸), `SL-74`(`SetAndDispose`), `AT-3`/`AT-11`
   (제네릭 키 narrowing 실측·`Frame{a,a}` 위치별 claim), `UI-5`(숏핸드 자식의
   gcconn 셋업), `ML-9`(`Quad.debug` 인스턴스별 여부).
3. **표면 타입계약** — `BS`(D/New/이벤트 타입), `R`(Ref API), `TL`(타입 한계).
4. **나머지** — 순서 무관.

---

## A. `base/architecture.md`

### A-1 — 패키지 경계의 판정 기준
`quad-base`/`quad-roblox` 분할의 기준은 "값이 엔진 개념인가"가 아니라
**"그 핸들러가 하는 부기(bookkeeping)가 엔진 지식을 요구하는가"**이고, 그래서
`Tag`의 참조 카운트와 `Attribute`의 이름 claim은 **핸들러째로 quad-base**에
있고 백엔드는 `addTag`/`removeTag`/`setAttribute` 세 op만 주입한다. 반대로
`Property`/`Event`/`OnChange`는 Reflection·시그널 자체가 로직이라 백엔드 소속이다.
→ **예/아니오**

### A-2 — 모놀리식 패키징
지금은 여러 wally 패키지로 안 쪼개고 **모놀리식 모노레포**(RbxUtil 선례)로 가며,
`.luaurc` alias는 **런타임 require가 아니라 편집기 자동완성/타입체크용으로만**
쓰고 실제 크로스패키지 require는 상대경로다. → **예/아니오**

### A-3 — `Quad`와 `New()`의 관계
`require(quad)`의 반환값 `Quad`는 **모듈이 스스로 `New()`를 한 번 불러 만든 기본
인스턴스 그 자체**이고, `Quad.New()`는 그 안의 명시적 opt-in 필드로서 **호출하면
완전히 별도의 새 Quad 네임스페이스**를 만든다. 지금 단계에선 `New` 필드 자체가
아직 노출되지 않는다(싱글톤). → **예/아니오**

### A-4 — 다중 인스턴스화 시 필요한 손질
`New()`가 실제로 붙는 시점엔 module-level state를 참조하는 코드들이
`InitXxx(module)`처럼 **모듈 인스턴스를 인자로 받도록 손을 봐야** 하고, 이건
"자동으로 스코핑됨"이 아니다. 다만 M1 스캐폴딩부터 그 형태로 짜므로 나중에 바꿀
일 자체가 없다. → **예/아니오**

### A-5 — 케이싱 규칙
PascalCase는 (1) 프리미티브 생성자 `Type(args)`, (2) 그 인스턴스의 콜론 메서드,
(3) 그 타입 네임스페이스의 정적 결합 함수(`Modifier.Overridden` 등), (4) `D`
네임스페이스와 그 필드 및 `New`. camelCase는 여러 타입을 넘나드는 범용
유틸(`isState`/`bindLifetime`/`canExecute`)과 프리미티브가 아닌 내부 엔진의
멤버(`Dispatch.process`/`Brand.set`) 및 Handler 계약 필드(`isHandlable`/
`priority`/`process`). → **예/아니오**

### A-6 — `Overridden`의 이중 표면
`Modifier.Overridden(a, b)`(닷)과 `a:Overridden(b)`(콜론)는 **둘 다 제공**되고,
분류 3번(정적 결합 함수)과 2번(콜론 메서드)이 배타적이지 않다. → **예/아니오**

### A-7 — `A and B or C` 전면 금지
`cond and x or y` 3항 관용구는 **가운데 값이 항상 truthy임이 보장돼도 예외 없이
금지**이고 `if-then-else` 표현식만 쓴다. 근거는 안전성이 아니라 분기 수(`and`/`or`는
최대 2번 테스트, `if-then-else`는 1번). 단순 2항 fallback(`x or y`)은 금지 대상이
아니다. → **예/아니오**

### A-8 — `const` 바인딩 보류
Luau `const` 바인딩은 문법을 몰라서가 아니라 **주변 툴링(pesde의 타입 추출 등)이
아직 못 따라와서** 지금 안 쓰는 것이고, 새 코드는 일단 `local`로 짠다. 언제
다시 가능해지는지는 **사용자가 확인해 알려주기 전까지 에이전트가 스스로 판단하지
않는다**. → **예/아니오**

### A-9 — 테스트 mock의 스코프
quad-base 테스트 mock은 Vide 선례(약 300줄)를 따라 parent/children 트리 +
타입 검증 없는 property bag + property별 변경 시그널까지만 만들고,
`IsA()`/클래스별 스키마/`WaitForChild`/`DataModel`은 안 만든다. 스코프는
**정적 스냅샷 디버깅으로 한정**(Tween 등 시간 기반 동작 흉내 안 냄), 그리고
"quad-roblox로 짠 컴포넌트가 mock에서 그대로 돌아야 한다"는 요구는 **없다**.
→ **예/아니오**

### A-10 — Tracker/lang/Signal 미구현
v1의 Tracker(hot-reload watcher), `lang` 모듈, 커스텀 Signal 클래스는 셋 다
**만들지 않는다**(각각 스토리북 대체 / 별도 라이브러리 / 콜백으로 충분).
→ **예/아니오**

### A-11 — id 기반 조회 폐지와 Ref의 용도
`Store.GetObject(id)`/`Frame "id" {}`류 전역 조회는 폐지됐고 `CollectionService`
태그를 그대로 쓴다. **Ref는 그 대체가 아니다** — Ref의 용도는 "외부에서 이미
관리 중인 instance를 quad로 점진적으로 마이그레이션/래핑하기 위해 직접 참조를
얻는 것"이다. → **예/아니오**

---

## S. `base/source-state-plan.md`

### S-1 — Source가 State를 만족하는 방향
`Source<T>`가 구조적으로 `State<T>`를 만족하는 **단방향** 관계이고(State 자리에
Source를 넣을 수 있지만 역은 아님), 구현은 metatable `__index` 델리게이션이며,
타입은 상호 재귀를 피하려고 **`State<T>`가 `Source`를 전혀 참조하지 않도록** 먼저
독립 정의한다. → **예/아니오**

### S-2 — `:With`/`:Compute`의 반환 타입
Source에서 불러도 `:With`/`:Compute`는 항상 `State<U>`를 반환한다(Source 자신을
변형하는 게 아님). → **예/아니오**

### S-3 — 전파 모델
`Source`가 바뀌면 **값이 아니라 무효화 신호만** 쏘고, 실제 재계산은 `:Get()`
시점에만 일어난다. Fusion식 eager 노드/생성순 정렬은 안 만든다. → **예/아니오**

### S-4 — emit은 항상 전파된다
emit은 **자기 `invalid` 상태와 무관하게 항상 아래로 전파**되고, `invalid`
플래그는 "내 캐시가 낡았다"는 표시 하나뿐이다. 전파를 늦추거나 흡수하는 건
`Blocker`(및 그 위에 얹히는 Debounce/Throttle) 같은 명시적 게이트뿐이고 평범한
State는 절대 신호를 삼키지 않는다. → **예/아니오**

### S-5 — 다이아몬드를 푸는 주체
`a→b`, `a→c`, `(b,c)→d`에서 `d`는 신호를 **두 번 받지만** 중복 재계산은 안
일어난다. 막는 주체는 **pull-recompute + 노드별 캐시**이지 전파를 끊는 게 아니고,
`d` 아래의 Observer가 한 사이클에 두 번 우는 것은 **의도된 동작**이다.
→ **예/아니오**

### S-6 — "관측해야 실체화된다"의 범위
이 원칙은 State뿐 아니라 State를 필드로 담는 다른 구조(Modifier 등)에도 그대로
적용되고, **`table.clone`처럼 참조만 복사하는 연산은 관측이 아니다**.
→ **예/아니오**

### S-7 — State 체인 플래튼 기각
State 체인을 Modifier처럼 "Compute 함수 목록을 clone+append로 누적"하는 방식으로
바꾸는 안은 **기각**이다 — 다이아몬드에서 공유 캐시가 사라져 소비자 수만큼 중복
실행되기 때문. Modifier가 그 패턴을 쓸 수 있는 건 캐싱이 필요 없는 정적
데이터라서다. → **예/아니오**

### S-8 — `:With`는 진짜 새 노드
`:With(...)`는 호출마다 **새 State 노드**(계산 함수 없이 self를 pass-through하되
구독 목록만 넓힌 얇은 노드)를 만든다. clone 빌더 대안은 (1) 디버그 그래프가 꼬임,
(2) 공유 캐시를 못 탐, (3) Compute 노드 위에서 캐시 슬롯까지 복사돼 실제로 깨짐 —
세 이유로 기각. → **예/아니오**

### S-9 — 가변인자 권장
`key:With(a, b, c)`(노드 1개)와 `key:With(a):With(b):With(c)`(노드 3개)는 둘 다
유효하지만 **가변인자 스타일이 권장 관례**다(그래프가 단순해서). → **예/아니오**

### S-10 — 콜백 인자는 전부 lazy 핸들
`:Compute(fn, ...deps)`의 `fn`은 `fn(self: State<T>, previous?, ...deps: State<U>)`
형태로 **raw 값이 아니라 State 핸들**을 받고, 안에서 `:Get()`을 실제로 부를 때만
계산이 트리거된다. 그래서 콜백 안에서 인자를 비교/연산/저장하기 전에 항상
`:Get()`을 거쳐야 한다. → **예/아니오**

### S-11 — `previous`의 위치와 트레이드오프
`previous`는 `self` **바로 다음, deps 팩 앞**(`fn(self, previous?, ...deps)`)에
온다 — 타입 레벨 제네릭 팩이 시그니처 맨 끝에만 올 수 있다는 Luau 제약 때문.
그래서 deps만 쓰고 싶어도 `function(self, _, dep1)`처럼 2번째 자리를 비워야 하고,
이 불편은 감수한다. → **예/아니오**

### S-12 — `previous`의 계약
`previous`는 "바로 직전 버전"이 **보장되지 않으므로**(lazy pull), 이를 다루는
로직은 반드시 "현재 입력 전체 대 이전 결과 전체"의 **full diff**여야 하고
incremental delta를 가정하면 안 된다. 또 `previous`는 `self`가 아니라 **그
`:Compute` 호출이 만든 결과 노드 자신**에 귀속된다(팬아웃해도 안 섞임).
→ **예/아니오**

### S-13 — `previous` 패턴의 능동 관측 요구
`previous`를 mutate하는 로직은 Compute 본문 안에 있으므로, 그 State가 계속
능동적으로 관측되지 않으면(정상 prop 바인딩 경로에 물려있거나 `Observer`로
Get되지 않으면) **영영 갱신이 안 일어난다**. → **예/아니오**

### S-14 — 읽기 표기 통일
State/Source의 값 읽기는 **`:Get()` 하나뿐**이고 프로퍼티 읽기 표기는 없다.
프로퍼티 표기는 **Ref의 `.Value` 전용**으로 좁혀졌다(대문자 `.Value`).
→ **예/아니오**

### S-15 — trailing args sugar의 일반 원칙
`:Compute(fn, ...)`는 이미 만들어지는 노드에 엣지만 얹으므로 sugar로 채택하고,
`Effect(fn, ...)`/`state:Observer(fn, ...)`는 **없던 노드를 새로 만들어야
하므로 기각**한다(다중 의존성은 `Effect(fn, state:With(a,b,c))`처럼 `:With`를
코드에 그대로 노출). 원칙: "trailing args sugar는 그게 정말 무료일 때만".
→ **예/아니오**

### S-16 — State에는 쓰기 API가 없다
State에는 쓰기 API가 아예 없고, 값 쓰기 경로는 `source:Set(value)` 하나다.
`store.key = value`(`__newindex`)는 폐기됐다. → **예/아니오**

### S-17 — `Source(default)`의 `default` 생략 조건
`Source()`/`Ref()`처럼 `default`를 생략해도 되는 건 **`T`가 nilable일 때뿐**이고,
non-nilable `T`에 생략하는 건 사용자 실수다(타입으로 막을 수 있으면 막고 안 되면
UB로 문서 경고). 특히 `Ref()`는 `:Callback(fn)`이 등록 즉시 1회 호출되므로 그
자리에서 이미 타입 위반이 드러난다. → **예/아니오**

### S-18 — `:Emit()`의 범위
`:Emit()`은 **Source 원천에만** 있고 `:With`/`:Compute`로 만들어진 파생 State엔
개념 자체가 없다. 존재 이유 1순위는 "clone이 아예 불가능한 값(userdata/Instance)"
이고, verbose한 불변 업데이트를 줄이는 건 부차적 이득이다. → **예/아니오**

### S-19 — `Get()`은 라이브 레퍼런스
`Get()`은 라이브 테이블 레퍼런스를 돌려주므로, 그 결과를 나중 비교(`==`)나 diff
캐시 용도로 들고 있으면 안 되고 **항상 다시 `Get()`해야 한다**. → **예/아니오**

### S-20 — `State<Modifier>`는 런타임 error
`Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없고, 이건 UB가 아니라 **명시적
`error`**다 — `isModifier` predicate를 `Source:Set()`/Store 생성 시 eager
`Source(default)`/`:Compute` 결과 캐싱 지점에서 확인해 런타임에 막는다. 타입
차단은 보너스일 뿐 유일한 방어선이 아니다. → **예/아니오**

### S-21 — `state:Apply(factory)`의 정의
`state:Apply(factory)`는 정확히 `function(self, factory) return factory(self) end`
이고 그 이상의 계약이 없다. 타입은 `(factory: (State<T>) -> U): U`로 완전히 열려
있어(Modifier의 `(M) -> M`과 달리) 반응형 그래프를 벗어나는 탈출구로 써도 된다.
→ **예/아니오**

### S-22 — 이름 붙인 콤비네이터는 항상 `:Apply`
한 번 쓰고 마는 인라인 람다는 `:Compute(fn, ...deps)`를 직접 쓰고, 이름 붙여
재사용할 콤비네이터는 인자 개수와 무관하게 전부 `factory(self) -> State`를
반환해 `:Apply`로 붙인다. 이건 스타일 선호가 아니라 **정합성 문제**다(팩토리가
캡처한 deps를 `:Compute`에 직접 꽂으면 구독 목록에 안 걸려 조용히 멈춤).
→ **예/아니오**

### S-23 — `state:Observer(fn)`의 표면
Observer는 별도 홀더 래퍼 없이 그 반환값 자체가 children 배열에 놓을 수 있는
leaf 값이고, 자유 함수 `Observer(state, fn)`가 아니라 **메소드**다(State/Observer는
"원천에 종속된 파생 데이터" 카테고리라 자유 함수 생성자가 없음). → **예/아니오**

### S-24 — Observer의 즉시 1회 실행
`fn`은 등록 시점에 **즉시 1회 실행**되고, 이 덕분에 "초기값 적용"과 "이후 변경
반영"이 같은 코드 경로로 통일된다. 인자 없는 `state:Observer()`도 같은 규칙을
따른다. → **예/아니오**

### S-25 — Observer는 값을 안 받는다
`fn`은 새 값을 안 받고 신호만 받으므로 본문에서 `state:Get()`을 명시적으로 다시
읽어야 한다. 자동으로 안 해주는 이유는 "다른 `:With`한 값에 따라 계산 자체를
통째로 생략하고 싶을 수 있어서"다. → **예/아니오**

### S-26 — Observer 동적 경로 가드
`Observer`가 해시 파트 named 자리로 흘러들어오면 `HANDLER_PRIORITY_FALLBACK`에
등록된 전용 Handler가 **에러**를 내고, 그 에러 메시지에는 **실제 `k`의 타입**이
실린다. 같은 규칙이 `PreRef`/`PostRef`/`Effect` 가드에도 적용된다.
→ **예/아니오**

### S-27 — 전파 루프의 게이팅 위치
`canExecute` 게이팅이 일어나는 자리는 **State의 전파 루프**이고, State는 구독자를
weak로 담으며 발화 시 각 구독자마다 `canExecute(observer)`를 확인해 거짓이면 그
구독자만 건너뛴다. 여기에 `inst`가 없다는 사실이 `canExecute`가 `value` 하나만
받는 이유다. → **예/아니오**

### S-28 — `:Subscribe()`/`:Unsubscribe()`의 역할 분리
`:Subscribe()`는 **전역 강참조 레지스트리** 경로 전용이고, leaf 부착/`bindLifetime`
경로의 해제는 `unbindLifetime(value)`가 담당한다. 둘은 지우는 대상이 달라서
합칠 수 없다. 둘 다 idempotent이고 `:Subscribe()`/`:Unsubscribe()`는 `self`를
리턴한다. → **예/아니오**

### S-29 — `:Subscribe()`는 GC 원칙의 의도적 예외
`:Subscribe()`로 등록한 Observer는 로컬 참조를 전부 놓아도 **GC되지 않고 영원히
계속 실행**되며 오직 명시적 `:Unsubscribe()`로만 끊긴다. 용도는 "어떤 Instance
생명주기에도 안 묶인 top-level 사이드 이펙트"로 좁게 문서화한다. → **예/아니오**

### S-30 — 이중 바인딩 게이트의 방향
`canBound(v) == not canExecute(v)`이고, 게이트는 항상 `if not canBound(v) then
error(...)` 모양이다(`canBound` 참 = 아직 안 묶여 있음 = 지금 묶어도 됨). 두
진입점(`:Subscribe()`, `bindLifetime`)이 똑같이 `canBound`를 확인하므로 순서와
무관하게 대칭적으로 막힌다. → **예/아니오**

### S-31 — leaf 부착은 별도 메커니즘이 아니다
children 배열에 Observer/Effect를 놓는 "leaf 부착"은 `Dispatch/Leaf.luau`가
`bindLifetime(inst, v)`를 부르는 것 **그 자체**이고, 실제 상호 배타는
"전역(`:Subscribe()`) vs 특정 inst(`bindLifetime`)"라는 2-way다. → **예/아니오**

### S-32 — 게이트는 값 타입을 안 가린다
공유 헬퍼 `isBoundAlive`가 gcconn 경로를 먼저 보므로 `canBound`는 **어떤 값이든**
이미 살아있는 바인딩이 있으면 걸러낸다(Observer/Effect 전용이 아님). 덕분에 Slot
이중 마운트 같은 실수도 이 층위에서 공짜로 잡힌다. → **예/아니오**

### S-33 — 죽은 바인딩 재사용 허용
`inst`가 Destroy됐거나 `unbindLifetime`된 값은 `canBound`가 참이라 다른 `inst`에
다시 걸 수 있다 — 게이트가 막는 건 **살아있는** 이중 바인딩뿐이다. → **예/아니오**

### S-34 — `.Subscribed`의 소유권
`.Subscribed`는 **전역 `:Subscribe()`/`:Unsubscribe()` 전용 필드**이고
`bindLifetime`/`unbindLifetime`은 이 필드를 읽지도 쓰지도 않는다. 에러 메시지에서
경로를 가를 때만 이 필드를 본다. → **예/아니오**

### S-35 — Observer/Effect Leaf dedup
`ObserverEffectLeafHandler`의 `old ~= v` dedup은 **correctness가 아니라 순수 성능
최적화**다(안 넣어도 안 깨짐 — `bindLifetime`/`unbindLifetime`은 weak 테이블 쓰기
몇 개뿐이고 사용자에게 보이는 재통지도 없음). `==` 비교가 항상 더 싸서 넣는다.
→ **예/아니오**

### S-36 — Leaf Handler의 `k` 체크
`ObserverEffectLeafHandler.isHandlable`은 `type(k) == "number"`까지 **반드시**
체크해야 한다 — 안 그러면 FALLBACK 동적 경로 가드가 죽은 코드가 된다.
→ **예/아니오**

### S-37 — dedup relate 정리 위치
retractor 안에서 `relate` 기록을 지우는 것은 반드시 `nextValue ~= v` 분기
**안에서만** 해야 한다 — 밖에 두면 spurious 재발행에서도 기록이 지워져 dedup이
무력화된다. → **예/아니오**

### S-38 — ⚠️ 미해결 항목 확인: 중간 State 생존
`A → B → C → Observer` 체인에서 중간 노드 `B`/`C`를 붙잡는 주체가 지금 문서에
명시돼 있지 않고, 해법 방향은 **구독 엣지를 하류로 weak, 상류로 strong**으로
못박는 것이다(특히 `:With`는 계산 함수가 없어 우연한 클로저 캡처가 없으므로
"우연"에 기댈 수 없음). 이 방향을 불변식으로 명문화하고 `luau-test` 스파이크를
추가하는 것이 **M3 착수 전 필요**하다. → **예/아니오**

---

## ST. `base/store-plan.md`

### ST-1 — Store의 정의
Store는 "이름 붙은 Source 모음, 그 이상 아님"이고, 값 하나만 반응형으로 다루고
싶으면 Store를 통째로 만들지 말고 독립 `Source(default)`를 쓴다. → **예/아니오**

### ST-2 — eager + lazy 둘 다 필요
`defaults` 키마다 Store 생성 시점에 **eager 생성**하고, 선언 안 된 키를
`store.key`로 접근하면 그 자리에서 **lazy 생성 후 저장**한다 — Luau 타입이
런타임에 강제되지 않아 `defaults` 없이 만든 키에 `:Set()`을 부르면 크래시나기
때문에 둘 다 필요하다. → **예/아니오**

### ST-3 — 오타 키 방어선은 타입
lazy 생성이 오타/동적 키로 Source를 무한정 누적하는 트레이드오프는 그대로
수용하고, 방어선은 런타임이 아니라 **타입**(`type function`이 합성한 레코드에
없는 프로퍼티 → 타입 에러)에 둔다. 이게 실제로 그런지는 **M0에서 실측 확인**할
항목이다. → **예/아니오**

### ST-4 — `defaults` 원본 mutate는 UB 아님
`defaults` 테이블은 라이브 백킹 스토리지가 아니라 초기값 템플릿으로만 참조되므로,
원본을 나중에 mutate해도 UB가 아니다. → **예/아니오**

### ST-5 — eager 생성 구현 스케치
eager 생성은 빈 테이블에 키를 하나씩 넣는 게 아니라 **`table.clone(defaults)` 후
각 슬롯을 `Source(v)`로 교체**하는 모양이어야 한다(해시/배열 슬롯 구조 재사용이
더 쌈). → **예/아니오**

### ST-6 — `:Set()` 전환의 근거
`store.key = value` 폐기의 근거는 (1) 레코드 필드 읽기/쓰기 타입 대칭성,
(2) `=`가 암시하는 "즉시 커밋"이 실제 lazy 동작과 안 맞는 의미론적 정직성 —
둘 다다. → **예/아니오**

### ST-7 — 문자열 커링 기각
`store "key"` 문자열 커링은 **기각**됐다(동적 키 폴백으로도 남지 않음). 근거는
`"a"`가 그냥 `string`으로 들어가 `Source<T>`의 `T`를 알 수 없다는 것과,
dot-access + `type function` 타이핑이 자리잡아 더 이상 필요 없어졌다는 것.
→ **예/아니오**

### ST-8 — `GetDynamic`의 위치(⚠️ 미결)
동적 키 창구는 `store:GetDynamic<T>(name): Source<T>`이고, 콜론 메소드로 두면
`__index`가 **고정 메소드 테이블을 먼저 확인하고 없을 때만 lazy Source 생성으로
폴백**해야 하며 그 결과 `GetDynamic`이 Store의 **예약 키**가 된다. 탑레벨
`getDynamic(store, name)` 대안이 열려 있고 **M3/M4 착수 전 확인**이 필요하다.
→ **예/아니오**

### ST-9 — `type function`으로 `Store<T>` 합성
`Store<T>` 레코드 타입 합성은 Luau `type function`으로 풀리고, 결과가 이름 붙은
`Source<string>`이 아니라 flatten된 익명 타입이어도 **Luau가 구조적으로 검사**하므로
문제없다. 이건 실측 완료된 항목이다(`luau-test/done/16-*`). → **예/아니오**

### ST-10 — Store 필드가 Store/State를 담는 경우
"Store 필드가 다른 Store/State를 담아 자동으로 따라가게 하는" 용도는 **안 만든다**
(Store는 반응형 값의 시작점 역할만). 반면 `State<State<T>>`(State가 emit하는 값이
State인 것)는 **정상 지원 대상**이다 — 둘은 다른 축이다. → **예/아니오**

---

## BS. `base/bind-system-plan.md`

### BS-1 — 핸들러 계약 3종
핸들러 계약은 `isHandlable(inst,k,v)` + `priority` + `process(inst,k,v,index)`
**3종**이고, 옛 `retract` 필드는 `process`의 반환값(retractor 클로저)으로
합쳐졌다. tbox식 6-hook 세분화는 지금 안 한다. → **예/아니오**

### BS-2 — 팩토리 재호출 가드
`RobloxFactory`를 같은 `BaseModule`에 **같은 팩토리로** 재호출하면 no-op(hot-reload
안전), **다른 팩토리로** 재호출하면 에러다. 구현은 `_initializedBy` 마커 하나면
된다. → **예/아니오**

### BS-3 — `D`(Declarative) 이름 확정
네임스페이스 이름은 `D`(Declarative)로 확정이고, 근거는 (1) `DI`가 Dependency
Injection과 겹쳐 실제 오해가 있었음, (2) Instance 전용이 아니라 quad-* 전반의
declare 요소로 확장 가능, (3) 엔진 종속 없음, (4) `D.FrameModifier`류 타입
프리픽스가 짧아야 함. 문서에서 처음 나오는 자리마다 `D`(Declarative)로 풀어쓴다.
→ **예/아니오**

### BS-4 — `D`는 전량 코드 생성
`D`는 타입뿐 아니라 `New` 호출문까지 **생성기가 찍어내는 전량 코드 생성
산출물**이고 손으로 쓰지 않는다. PA님 코드의 타입 레벨 인덱싱
(`from<index<UIInstances, ClassName>>`)은 채택하지 않는다 — (1) 이벤트 필드가
`RBXScriptSignal`로 나와 콜백 시그니처가 안 나옴, (2) LSP마다 다룸이 다를 수
있음, (3) `T | State<T> | Tween<T> | None` 유니온까지 조립할 바엔 생성이 단순함.
→ **예/아니오**

### BS-5 — `New`는 커링
`New "Frame" { ... }`은 `New("Frame")({ ... })`이고, `D.Frame`은 그 결과에
캐스트만 얹은 순수 별칭이다. 이름은 대문자 `New`로 통일한다. 이건 기각된
"2트랙"(필드=1급 경로 / 문자열=폴백이라는 **능력 차이**)과 다르고, 오히려 두
형태가 완전히 같은 것임을 못박는 것이다. → **예/아니오**

### BS-6 — 생성 범위
`D` 생성 범위는 "GUI에 쓰이는 모든 인스턴스"이고(전량도 25개도 아님), 범위 밖
클래스는 `New<X> "X" {...}`로 쓰면 props 타입이 **`any`**이며 필요하면 사용자가
`::` 캐스트로 좁힌다. 따라서 "제네릭 생성자 하나가 알려진/모르는 타입을 전부
커버"는 **런타임에 대해서만** 참이다. → **예/아니오**

### BS-7 — 이벤트는 문자열 키 + 런타임 리플렉션
`On.EventName` 도트액세스는 안 쓰고, `Frame { MouseButton1Click = fn }`처럼
평범한 문자열 키를 쓰며 `ReflectionService` 기반 pluggable 핸들러가 "키가
이벤트인가"를 판별한다. → **예/아니오**

### BS-8 — 이벤트 콜백 타입은 검증된다
"콜백 시그니처까지 Luau가 검증 못 한다"는 옛 서술은 **거짓**이다 — props 테이블
타입에 필드로 선언돼 있으면 콜백 파라미터가 그대로 추론된다. 런타임 판별을
리플렉션으로 하는 것과 타입을 생성기가 주는 것은 **완전히 별개 축**이고, 따라서
이벤트는 "타입을 포기하는 예외"가 아니라 **이름 지정 방식만 문자열 키인 예외**다.
→ **예/아니오**

### BS-9 — `GetPropertyChangedSignal`은 별도 특수 키
`GetPropertyChangedSignal`은 프로퍼티 이름 네임스페이스와 겹쳐 평범한 문자열
키로는 세팅과 리스닝을 구분할 수 없으므로 별도 `OnChange` 특수 키로 간다.
→ **예/아니오**

---

## D. `base/dispatch-core-plan.md`

### D-1 — `isHandlable`의 계약
`isHandlable`은 **부작용 없이 빠르게** "이 핸들러가 맞는가"만 판별하고 실제
유효성 검사는 선택된 이후 별도 단계에서 한다. `inst`도 받으며(지금 당장 쓰는
케이스는 없지만 나중에 계약을 깨지 않기 위해), **생략 불가**다. → **예/아니오**

### D-2 — retractor 반환 생략 불가
정리할 게 없어도 `function() end`을 반환해야 하고, `nil`을 반환하면
`Dispatch.process`가 즉시 error를 낸다. 생략 시 실제로 벌어지는 일은 "슬롯이
완성되지 못해 `#list`가 정의되지 않고 체인 추적이 통째로 깨짐"이다.
→ **예/아니오**

### D-3 — retractor는 자기 자원만 정리
retractor는 자기 하위 위임까지 쫓아가 정리할 필요가 없다 —
`Dispatch.retractFrom`이 **항상 깊은 인덱스부터 얕은 쪽으로** 정리하므로 이
클로저가 불릴 시점엔 자기 아래는 이미 정리된 뒤다. → **예/아니오**

### D-4 — 동률 tiebreak 미강제
같은 `priority`에 대한 tiebreak 규칙은 **강제하지 않고**, 대신 이름 붙은 우선순위
상수(`HANDLER_PRIORITY_HIGH/NORMAL/LOW`, 오프셋 연산 가능)로 애초에 동률이 잘 안
나오게 유도한다. 동률이 나면 대개 핸들러 설계 실수라 디버그 가시성으로 대응한다.
→ **예/아니오**

### D-5 — `HANDLER_PRIORITY_FALLBACK`의 의미
FALLBACK은 "base가 제공하되 백엔드가 덮어쓸 수 있는" 최하위 밴드이고,
**base 소속 핸들러가 전부 여기 오는 게 아니다** — `StoreBind`/`NoneHandler`/`Leaf`
처럼 디스패치 골격 자체인 것은 여전히 높은 우선순위다. → **예/아니오**

### D-6 — 매치 실패는 즉시 error
매치 실패는 조용한 무시 없이 즉시 `error`이고, 메시지엔 `Brand`(있으면)와
`typeof(v)` + "provider가 초기화됐는지 확인하라" 안내가 들어간다. → **예/아니오**

### D-7 — provider 미주입과 매치 실패의 관계
"provider 미주입 = 매치 실패와 같은 경로"라는 일반화는 **backend가 직접 소유하는
핸들러(`Property`/`Event`/`Slot`류)에만** 해당한다. `Tag`/`Attribute`는 base가
Fallback Handler를 스스로 등록하므로 **매치는 되고**, 실패는 주입 op 스텁의
명시적 에러로 난다. → **예/아니오**

### D-8 — `Quad.debug` 플래그
동률 경고 print는 모듈 표면의 불리언 `Quad.debug`(기본 `false`)가 참일 때만
찍는다. `Quad.debug`는 새 공개 API 표면이라 `module-lifecycle-plan.md`에도
반영이 필요하고, 다중 인스턴스화 시 인스턴스별인지 전역인지는 그때 정한다.
`Dispatch.listHandlers()`가 이 플래그와 무관하게 항상 호출 가능한지도 구현 시
정한다. → **예/아니오**

### D-9 — 무한루프 방어 안 함
우선순위 스캔 + 재귀 `process` 구조의 무한루프는 base가 방어하지 않고
**오작동하는 handler/provider 쪽 버그로 간주**한다. → **예/아니오**

### D-10 — 두 패스 순회 계약
`Dispatch.drive`는 Lua 테이블의 우연한 순회 순서에 기대지 않고 **명시적으로 두
패스**(배열 파트 먼저, 해시 파트 나중)로 돈다. 이유는 (1) 다른 백엔드의
이식성, (2) 어차피 구분 비용이 드니 순서 고정이 거의 공짜. **M0 스파이크에서
실제 Luau로 순회 동작을 검증**할 항목이다. → **예/아니오**

### D-11 — `PreRef`/`PostRef`는 두 패스보다 위
`PreRef`/`PostRef`는 배열 파트 우선 규칙 **위에서 성립하는 게 아니라**, 두 패스
순회보다 더 위의 **별도 pre-pass for 문**에서 처리되고 `flattened`엔 소진
마커만 남는다. 두 보장은 서로 독립이다. → **예/아니오**

### D-12 — `Dispatch.drive`는 `None`을 안 거른다
`drive`에 `None` 특수 분기는 없고 배열이든 해시든 모든 `(k,v)`가
`Dispatch.process(inst,k,v,1)`을 탄다 — `Frame{ State<Slot|None> }`처럼 반응형
값이 `None`을 내놓으면 그게 `StoreBind` 재귀를 타고 `process`에 도착하기 때문.
→ **예/아니오**

### D-13 — `NoneHandler`의 역할
`NoneHandler`는 `v == None`을 매치해 `Dispatch.process(inst,k,nil,index+1)`로
내려보내는 **재귀 하나만** 하고, 배열/해시 구분도 하지 않으며 retractor는
no-op이다. 이전 기여의 실제 철거는 하강 diff의 (B) 분기가 해준다.
→ **예/아니오**

### D-14 — `NilHandler`의 역할과 순서
`NilHandler`는 `type(k)=="number" and v==nil`을 매치하는 **말단** 핸들러로,
`setOffsetSource(inst,k,None)` → `setLength(inst,k,0)` **순서로** 등록하고
재귀하지 않는다. 순서가 반대면 `setLength` 끝의 `gatedRecompute`가 죽는 중인
서브트리의 Source에 `:Set()`을 날린다. → **예/아니오**

### D-15 — `State<Slot|nil>`도 동작
사용자에게 `None`을 강제하지 않는다 — `State<Slot|None>`도 `State<Slot|nil>`도
둘 다 정상 동작해야 한다. → **예/아니오**

### D-16 — 해시 자리의 `nil`
해시 자리의 `nil`은 `NilHandler`가 아니라 그 키를 원래 담당하던
핸들러(프로퍼티/이벤트)의 몫이고, 이벤트 키에서 `nil`이 disconnect를 뜻한다는
규정은 `event-plan.md`가 소스다. → **예/아니오**

### D-17 — `Dispatch`는 탑레벨 싱글톤
`Dispatch`를 `Dispatch()`로 인스턴스화 가능한 프리미티브로 만드는 안은 기각이고,
지금의 flat 탑레벨 함수 형태를 유지한다. 근거는 재귀 재-dispatch가 안정된
전역을 요구한다는 것과, `Handler.luau`(타입 계약) ← `Dispatch/init.luau` ←
`StoreBind.luau`로 의존이 **단방향**이라 순환이 없다는 것. → **예/아니오**

### D-18 — Fallback Handler의 등록 주체
`TagFallbackHandler`/`AttributeKeyFallbackHandler`/`AttributeGroupFallbackHandler`는
**quad-base 자신이** 자기 로드 시점에 등록한다(백엔드 팩토리가 아님) — 그러지
않으면 quad-roblox를 로드하지 않은 상태에서 "provider가 초기화됐는지 확인하라"
안내 경로 자체가 동작하지 않기 때문. 이건 `InitNamespace` 거부 원칙과 충돌하지
않는다(외부 init 표면이 안 늘고, 순서 의존도 없고, 사용자가 할 일도 없음).
→ **예/아니오**

### D-19 — 알고리즘 구현체와 Fallback 엔티티의 이름 구분
레지스트리에 실제로 꽂히는 건 알고리즘 구현체(`TagHandler` 등)가 아니라 그걸
감싼 **별도 이름의 `*FallbackHandler`**이고, 이름 자체로 "자동 설치되는 기본
안전망"임을 구분한다. → **예/아니오**

### D-20 — 주입 op의 시그니처와 기본 스텁
주입 op은 `addTag(inst, {string})` / `removeTag(inst, {string})` /
`setAttribute(inst, name, v?)` 셋이고, vararg가 아니라 `{string}`인 이유는
`table.unpack`이 tail 위치에서만 완전히 펼쳐진다는 Lua 제약 + 대량 이름 unpack
한계다. 아직 안 채워진 슬롯의 기본값은 조용한 no-op이 아니라 **명시적으로
에러내는 스텁**이다. → **예/아니오**

### D-21 — 원자적 실패는 opt-in
"부기 mutation 0회"의 진짜 원자적 실패를 원하는 백엔드는
`HANDLER_PRIORITY_FALLBACK + 1`짜리 얇은 가로채기 Handler를 추가로 등록하면
되지만, 이건 **선택적 업그레이드**이고 기본 요구사항이 아니다. → **예/아니오**

### D-22 — 타입 패밀리의 경계
`AttributeKey<T>` 제네릭 생성자 + 스칼라 편의 패밀리(`String`/`Number`/
`BooleanAttribute`)까지가 base이고, `Color3Attribute`류 **엔진 고유 타입** 패밀리는
백엔드(`D` 층)가 자기 것으로 추가한다. "이 값이 이 백엔드에서 표현 가능한가"
검증도 주입된 `setAttribute`의 몫이다. → **예/아니오**

### D-23 — `chains`의 구조
`chains`는 `Relate()` 기반으로 `{[inst(weak)] = {[k] = {[index] = {handler,
retractor}}(strong)}}` 모양이고, 하강 diff가 추가로 저장하는 건 **비교용
`handler` 하나뿐**이다("이전 값"은 클로저가 이미 upvalue로 안다). → **예/아니오**

### D-24 — `list` 확보 순서
`list` 확보 + `chains` 등록은 반드시 `h.process` 호출 **전에** 끝나야 한다 —
안 그러면 재귀 호출이 `or {}`로 자기만의 새 테이블을 만들어 저장한 뒤 바깥이
그걸 덮어써서 하위 위임 retractor가 통째로 유실된다(최초 마운트에서 항상 발생).
→ **예/아니오**

### D-25 — (A) 분기의 순서
같은 핸들러일 때는 `slot.retractor(v)` → `slot.retractor = NOOP` →
`h.process(...)` → 새 retractor 저장 순서이고, 중간에 `NOOP`을 끼우는 이유는
`h.process`가 재귀하는 동안 이미 소비된 클로저가 두 번 불릴 여지를 없애기
위해서다. → **예/아니오**

### D-26 — (B) 분기의 점유 마커
다른 핸들러일 때는 `retractFrom(inst,k,index)` 후 **점유 마커를 먼저 박고**
`h.process`를 부른다 — `h.process`가 재귀하는 동안 list가 구멍 없는 시퀀스로
유지돼야 `#list`가 정의되기 때문. → **예/아니오**

### D-27 — 래핑 핸들러는 선행 철거를 안 한다
`StoreBind`/`NoneHandler`가 하는 일은 `Dispatch.process(inst,k,realv,index+1)`
한 줄이고, 전이 판정은 그 안에서 `Dispatch.process`가 스스로 한다. "누가 무엇을
언제 철거하는가"가 래핑 핸들러에서 Dispatch 한 곳으로 옮겨갔다. → **예/아니오**

### D-28 — retractor 인자의 타입 보장 범위
값이 넘어오는 건 오직 (A) 분기뿐이고 그 값은 정의상 그 핸들러의 `isHandlable`을
만족한다. **다만 보장 범위는 "같은 핸들러"까지지 "같은 값 모양"까지가 아니다** —
한 핸들러가 여러 모양을 받으면(예: `PropertyHandler`의 `isTween(realv)`) 그
판별은 여전히 그 핸들러의 몫이다. 없어진 건 타입 미보장을 메우려던 방어
가드뿐이다. → **예/아니오**

### D-29 — 깊은 체인에서도 힌트 유지
힌트를 위에서 아래로 실어보내는 게 아니라 **각 레벨이 자기 재프로세스에서 자기
힌트를 받으므로**, `State<State<Tag>>`에서도 인덱스 3의 TagHandler가 진짜 `Tag`
객체를 받아 `Contains` skip이 정상 동작한다. → **예/아니오**

### D-30 — `retractFrom`은 3-인자
`Dispatch.retractFrom(inst, k, index)`는 3-인자이고 힌트는 항상 `nil`이다 —
값을 넘기는 경로가 (A) 분기 하나로 통일되면서 외부에서 힌트를 만들어 넣을 자리
자체가 없어졌다. → **예/아니오**

### D-31 — 중간 노드는 `inst`에 손대지 않는다
중간(래핑) 노드는 `inst`에 부작용을 가하지 않고 순수 언랩만 한다 — (A) 분기가
아래를 안 건드린 채 중간 노드만 갈아치우므로 흔적을 지울 주체가 없어지기 때문.
`NilHandler`는 말단이고 `setLength`/`setOffsetSource`는 `inst` 프로퍼티가 아니라
Dispatch 자신의 부기라 이 계약과 충돌하지 않는다. → **예/아니오**

### D-32 — 재위임 핸들러의 (A) 분기 의무
재위임하는 핸들러는 (A) 분기에서도 **반드시 다시 재위임**해야 한다. 조건부로만
재위임하는 핸들러를 만들면 건너뛰는 자리에서 `Dispatch.retractFrom(inst,k,index+1)`을
직접 불러야 한다. → **예/아니오**

### D-33 — 인덱스의 의미
`index`는 "같은 키 안의 재귀 깊이"이고, 다른 키(또는 다른 `inst`)로 위임하면
**항상 1부터** 시작한다. 시작 인덱스가 0이 아니라 1인 이유는 `ipairs`/`#`가
1부터 연속된 정수 키를 전제하기 때문이다. → **예/아니오**

### D-34 — 다른 `inst`로의 위임
`(inst,k1)` 핸들러가 `(child,k2)`로 위임하는 것은 Dispatch 입장에서 `(inst,k2)`
위임과 구조적으로 같은 일이라 정상이고, 이게 UI 숏핸드가 Tween을 공짜로 얻는
방식이다. 다만 **그 자식의 수명은 위임한 핸들러가 책임진다**. → **예/아니오**

### D-35 — 직접 호출 금지
`handler.process(...)`를 `Dispatch.process`를 거치지 않고 직접 부르는 것은 UB다.
retractor 클로저 안에서 `Dispatch.process` 호출도 금지이고, **같은 `(inst,k)`에
대한 `retractFrom`도 금지**(진행 중인 루프가 `#list`를 이미 캡처) — 다른 키에
대한 `retractFrom`만 허용된다. → **예/아니오**

### D-36 — 소유권 충돌 감지는 Dispatch 일이 아니다
하강 diff에선 슬롯 점유가 정상 상태라 "이미 점유돼 있으면 error" 체크가 성립하지
않는다. Attribute 이름 충돌은 자기 도메인 안의 이름별 claim으로 해결하고,
Dispatch에 claimant 개념을 일반화하는 안은 **명시적으로 기각**됐다. → **예/아니오**

### D-37 — `State<State<T>>`는 정상 지원
임의 깊이의 `State<State<...>>`도 인덱스가 늘어날 뿐 정상 동작하고 깜빡임 방지
최적화까지 유효하다. 남는 UB는 순환뿐이다. → **예/아니오**

### D-38 — 체크리스트 1: 클로저는 early-return해도 소비된다
"이번엔 실제로 한 일이 없으니 no-op을 돌려주자"는 거의 항상 버그다 — 매 `process`
호출은 그 자리를 무르는 책임을 온전히 새로 짊어진 클로저를 반환해야 한다.
→ **예/아니오**

### D-39 — 체크리스트 2: 다른 키를 미리 비우지 않는다
다른 키로 위임하면서 그 키를 미리 `retractFrom`으로 비우는 것은 버그다(다른
소유자의 바인딩을 조용히 파괴). 다른 키의 정리는 **그 키를 등록했던 클로저가**
자기 철거 시점에 한다. → **예/아니오**

### D-40 — 체크리스트 3: `nil` 가정 금지
retractor 인자를 `nil`이라고 가정하는 것(`assert(v == nil)`류)은 여전히 금지다.
→ **예/아니오**

### D-41 — 체크리스트 4: 클로저 캡처 vs `Relate`
단발성 handoff는 upvalue 캡처로 끝이고, `Relate`는 **자기 클로저 수명 밖의 정보**
(`tagNameMap`/`nameClaims`/`Ref` dedup)에만 쓴다. `Relate`에 쓴 걸 지울 땐 "내가
실제로 물러날 때만" 지운다. → **예/아니오**

### D-42 — 체크리스트 9: 코루틴 yield 금지
`process`(또는 그가 부르는 컴포넌트 함수/`updateFn`) 안에서 코루틴 yield는
금지다 — 배치 게이팅이 "position이 순서대로, 끼어들 틈 없이 동기로 처리된다"는
전제 위에 있기 때문. 새 방어 로직을 넣는 게 아니라 어기면 UB라고 못박는 것이다.
→ **예/아니오**

### D-43 — Length/Offset의 핵심 전환
절대 위치를 계산해 전파하는 게 아니라, 각 구조적 위치가 **자기 앞 형제들의 누적
길이 합만** 알면 되고, 그걸 `LayoutOrder`/`ZIndex`처럼 물리적 순서와 분리된 정수
프로퍼티에 반응형으로 바인딩한다. → **예/아니오**

### D-44 — `setLength` 호출 책임자
`setLength`/`setOffsetSource`를 부르는 건 그 위치를 **처음** 매치한 Handler가
아니라 재귀가 끝나 실제 값을 받은 **말단 Handler**다(`State<Slot>`이면 재귀 끝의
`Dispatch/Slot.luau`, 빈 자리면 `NilHandler`, pre-pass 소진 자리면 각 nop
Handler). "모든 핸들러가 `k=number`일 때 처리"하는 안은 채택 안 했다.
→ **예/아니오**

### D-45 — `Offset`은 자동으로 `LayoutOrder`가 되지 않는다
Slot이 마운트한 원소의 `LayoutOrder`를 자동으로 덮어쓰지 않는다 — (a) 사용자
지정이 조용히 씹히는 매직이 되고, (b) `LayoutOrder`는 Roblox 전용이라 엔진 무관
층위로 지식이 새기 때문. `Slot.Offset`은 공개 노출만 되고 실제 계산·세팅은
`updateFn`이나 수동 사용자의 몫이며, 아무것도 안 하면 그냥 `LayoutOrder`가 안
바뀔 뿐이다. → **예/아니오**

### D-46 — 해제 순서
해제는 별도 API 없이 `0`/`None` 재등록이고 순서는 **`setOffsetSource(None)` →
`setLength(0)`**다. 반대로 하면 `recompute`가 죽는 중인 서브트리의 Source에
`:Set()`을 날린다(값이 틀려지는 문제는 아니지만 invalid한 Source가 순회 대상에
남는 것 자체가 위험). → **예/아니오**

### D-47 — 두 등록은 모든 number 인덱스에 필수
`setLength`/`setOffsetSource`는 array part의 **모든** number 인덱스에 대해 반드시
호출해야 하고 생략은 UB다. 다만 이건 **Handler 구현체 작성자만 지키는 계약**이고
일반 컴포넌트 작성자는 존재 자체를 몰라도 된다. → **예/아니오**

### D-48 — `bk.N`의 수명주기
`bk.N`은 "그때그때 실제 개수"이고 두 owner 타입(물리 `inst`, Slot 자신)에 같은
규칙이 적용된다 — `setLength`가 더 큰 position을 등록할 때 증가,
`spliceArraysDown`이 압축할 때 감소. **`setOffsetSource`는 `bk.N`을 건드리지
않는다**(호출 순서가 항상 offset→length라서, length에서만 올려야 `lengthList[i]`가
빈 채로 `N`만 커지는 창이 안 생김). → **예/아니오**

### D-49 — Blocker 게이팅의 현재 근거
배치 게이팅이 지금 필요한 이유는 **크래시 방지가 아니라 비용**이다(게이팅 없으면
등록마다 recompute가 돌아 O(N²), 있으면 배치 끝에 한 번 O(N)). `RC-1`의 원래
크래시는 "`bk.N`이 배치 전에 최종 크기로 고정"이라는 옛 전제의 부산물이었고 그
전제는 이제 없다. → **예/아니오**

### D-50 — `setOffsetSource`의 즉시 계산
`setOffsetSource`는 등록되는 그 자리에서 `bk.lengthList[1..i-1]`을 합산해 곧바로
`:Set`한다(`source == None`이면 스킵). 배치가 항상 position을 순서대로 처리하므로
이 합산은 항상 정확하고, 이게 "recompute를 미루면 초기 레이아웃이 이상해진다"는
우려를 없앤다. 이건 `recompute`를 대체하는 게 아니라 **보완**이다.
→ **예/아니오**

### D-51 — 배치 게이팅의 적용 지점
Blocker 게이팅이 필요한 자리는 정확히 둘 — (a) `Dispatch.drive`가 최상위 `inst`의
배열 파트를 순회할 때, (b) `attachSlot`이 **자기 자신의** `_elements`를 flush할
때. 중첩 Slot마다 자기 owner 키로 **별도** Blocker를 만들고 부모 것을 재사용하지
않는다. 이미 마운트된 Slot에 하나씩 `:Add()`하는 흔한 패턴은 이 게이팅이 필요
없다. → **예/아니오**

### D-52 — `recompute`의 `Get` 가드
`recompute`는 매번 전체를 순회하되 `offset:Get() ~= sum`일 때만 `:Set`한다 —
진짜 비싼 건 순회가 아니라 `Set`이 트리거하는 다운스트림 캐스케이드이기 때문.
`offset`이 `nil`이거나 `None`이면 건너뛴다(`None`은 truthy라 `if offset then`만으론
안 걸러짐). → **예/아니오**

### D-53 — `offset`/`sum`은 0-based 개수
`offset`/`sum`은 "그 앞에 몇 개가 있는가"라는 카디널 수라 0에서 시작하고,
`updateFn`의 `index`(1-based Lua 관례)와 `index + offset`으로 섞이는 게 의도된
것이다. → **예/아니오**

### D-54 — recompute 재진입 가드 없음
각 Slot이 `Relate(자기 자신)`으로 독립된 `bk`를 가지므로 중첩만으로는 같은
`(ownerKey,bk)` 재진입 경로가 없다 — 재진입 가드는 **불필요**하고 넣지 않는다.
진짜 재진입(사용자 코드가 recompute 도중 같은 Slot에 Add/Remove)은 UB로 둔다.
→ **예/아니오**

### D-55 — recompute 도중 upstream 쓰기는 UB
"recompute 도중 발생한 부작용이 같은 Slot의 length에 다시 쓰기를 가하는 것"은
`State`가 자기 Source에 `Set`을 가하는 것과 **같은 카테고리의 단방향 흐름 위반**
이라 UB이고, 그래서 별도 방어 로직도 없다. → **예/아니오**

### D-56 — `setLength`의 생명주기 경로
`setLength`가 만드는 Observer는 `:Subscribe()`가 아니라 `bindLifetime(ownerKey,
observer)`로 묶인다 — `ownerKey`가 죽을 때 같이 죽어야 하는 내부 배관이기 때문.
`setLength` 자신은 `recompute`를 직접 부르지 않고 항상 `gatedRecompute`를
경유하며, Observer의 "등록 즉시 1회 실행"으로 촉발되는 최초 호출도 예외 없이 이
게이트를 통과한다. → **예/아니오**

### D-57 — `sourceList`에 `None`을 쓰는 이유
`sourceList`에 `nil` 대신 `None`을 쓰는 이유는 (1) "안 채워짐"과 구별이 안 되고
(2) 배열에 구멍이 나면 해시 파트로 밀려 접근 비용이 올라가기 때문이다(순회 순서
보존 때문이 아님 — `recompute`는 `1..N` 고정 범위 인덱스 `for`라 성긴 키 순회
문제 자체가 없음). → **예/아니오**

### D-58 — 마운트보다 offset 갱신이 먼저
`rawAdd`는 `self.Length:Set(newCount)`(다운스트림 offset/LayoutOrder 갱신이 여기서
동기적으로 끝남) → `element.Parent = target` 순서로 호출해야 한다 — 안 그러면
Roblox의 실시간 `UIListLayout` reflow에서 한 프레임 순서가 깨진 채 노출된다.
→ **예/아니오**

### D-59 — 웹 백엔드에서의 재사용
`lengthList`/`sourceList`/`recompute`는 웹 백엔드에서도 그대로 재사용되고,
다른 건 "offset 변경 시 무엇을 하는가"뿐이다(DOM은 `insertBefore`가 자연히
밀어내므로 quad-web의 해당 Handler는 no-op이고, `offset` 숫자는 다음 insert/remove
때의 물리 인덱스용으로만 부기된다). → **예/아니오**

### D-60 — `Slot.Length`와 `Slot.Offset`은 별개
`Length`는 Slot이 스스로 노출하는 출력값(지금 실제 마운트된 개수, "n개 검색됨"
UI에 그대로 써도 됨)이고 `Offset`은 Dispatch가 등록받아 `recompute`가 채우는
입력값이다 — 서로 다른 두 `Source<number>`다. `Offset`은 마운트 전엔 `nil`이다.
→ **예/아니오**

### D-61 — 동적 자식의 유일한 정당 경로
동적 자식 추가/제거의 정당 경로는 `Slot` 또는 `state<Frame>`류 store-bind
**둘뿐**이고, 사용자 코드가 `newInst.Parent = parentInst`로 몰래 끼워 넣는 건
방어 로직 없는 UB다. → **예/아니오**

### D-62 — store-bind 구독 메커니즘
"값이 바뀔 때마다"의 구독은 새 프리미티브가 아니라 `state:Observer(fn)` 재사용이고,
`StoreBind.process`가 반환하는 클로저가 할 일은 `unbindLifetime(observer)` 하나다
(observer는 upvalue 캡처라 별도 `Relate` 저장/조회 불필요). → **예/아니오**

### D-63 — 핸들러는 liveness를 재구현하지 않는다
State의 전파 루프가 발화 때마다 `canExecute(observer)`로 게이팅하고 그 판정
근거는 `bindLifetime`이 `observer` 쪽에 복사해둔 gcconn 참조가 제공하므로,
핸들러가 따로 liveness를 짤 필요가 없다. → **예/아니오**

---

## LP. `base/lifecycle-pattern.md`

### LP-1 — `Connected`는 계산 속성
`Connected`는 저장되는 bool이 아니라 "내가 아직 살아있게 하는 뒷받침 참조가
nil인지"를 확인하는 **계산된 속성**이고, 해제는 그 참조를 `nil`로 만드는
것뿐이다(자료구조를 즉시 재구성하지 않음). → **예/아니오**

### LP-2 — Instance 파괴 관측 지점
Instance 파괴 관측 지점은 `Destroying` **하나로 통일**하고 `AncestryChanged`나
폴링은 안 쓴다. 다만 실제로는 이 훅을 쓰는 지점이 예상보다 적을 가능성이 크다.
→ **예/아니오**

### LP-3 — quad는 라이프사이클 "중간"에 없다
quad는 자기가 만든 Instance를 끝까지 들고 있는 소유자라 중간 계층이 없고,
그래서 **Instance/바인드 전체가 Destroy될 때 실행할 teardown 로직은 없다 —
오히려 있으면 안 된다**(죽은 대상을 다시 건드리면 에러). 해야 할 일은 "생명주기가
끝난 뒤 그 대상을 다시 건드리는 시도를 막는 것" 하나뿐이다. → **예/아니오**

### LP-4 — 엔진 레벨 보강
Roblox 엔진 자체가 Destroy 시 Tag/Attribute/실행 중인 Tween을 정리해주므로
라이브러리가 따로 처리할 필요가 없고, 커스텀 Destroy-time 처리가 필요한
사용자는 `[Event "Destroying"]`을 직접 바인드하면 된다. → **예/아니오**

### LP-5 — 탑레벨 평평한 함수
`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`는 `LifetimeHandle.bind(...)`
류로 감싸지 않고 **탑레벨 평평한 함수**로 export한다 — 핸들러 작성자가 직접
호출하는 1급 프리미티브 연산이라서. → **예/아니오**

### LP-6 — `inst`를 받는 건 `bindLifetime` 하나뿐
`unbindLifetime(value)`/`canBound(value)`/`canExecute(value)`는 전부 `value`
하나만 받고, `inst`가 필요한 건 "어느 홀더에 넣을 것인가"를 정해야 하는
`bindLifetime` 하나뿐이다. 이게 구조적으로 중요한 이유는 `canExecute`의 실제
호출부(State 전파 루프)에 **`inst`가 없고 있어서도 안 되기** 때문이다.
→ **예/아니오**

### LP-7 — `unbindLifetime`의 실질 이득
`unbindLifetime`이 `inst`를 안 받으면 호출부가 "이 값을 어느 inst에 걸었더라"를
기억할 필요가 없어지고, "`_mountedInst`가 이미 갈아치워졌거나 `nil`이면 해제가
조용히 빗나간다"는 잠재 버그 클래스가 원천 소멸한다. 안 걸려있던 값에 불러도
안전한 no-op이다. → **예/아니오**

### LP-8 — gcconn/gchold는 Instance 생성 시점에
gcconn/gchold는 `bindLifetime` 첫 호출에서 lazy 생성하는 게 아니라 **Instance를
만든 직후 무조건**(핸들러/바인딩 유무와 무관하게) 만든다. 이유는 Roblox
`Instance` 값이 엔진 객체가 아니라 **userdata 포인터**라, Lua 쪽 참조가 없으면
회수되고 나중에 같은 엔진 객체가 **다른 userdata**로 나와 `inst`-키 `Relate`
항목 전체가 조용히 미아가 되기 때문이다. → **예/아니오**

### LP-9 — gcconn 클로저가 `inst`까지 캡처
gcconn 클로저는 `gchold`뿐 아니라 **`inst`도 업밸류로 캡처**해야 하고, 그게 위
userdata 동일성 보장의 핵심이다. `gchold[1]`은 gcconn 전용 자리이고 실제 값들은
해시 자리에 들어간다. → **예/아니오**

### LP-10 — `ClassName` 시그널 선택
`GetPropertyChangedSignal("ClassName")`을 쓰는 이유는 그 프로퍼티가 절대 안
바뀌어 신호가 **절대 발화하지 않기** 때문이고, 이건 2026-08-13에 부분 실측으로
확인됐다(미발화 + Destroy 시 `Connected` 즉시 전환). → **예/아니오**

### LP-11 — 감수하는 대가
이 트릭의 대가는 "quad가 만든 Instance는 참조를 놓는 것만으로는 회수되지 않고
반드시 `Destroy`로 회수된다"는 것이고, 이건 **실질적으로 새 제약이 아니다**
(바인딩이 하나라도 걸리면 어차피 같은 순환이 생기므로, 아무것도 안 걸린
Instance까지 같은 규칙으로 통일한 것뿐). → **예/아니오**

### LP-12 — `InstData`/`BindData`는 `SetWeak`
gchold/gcconn을 담는 `InstData`/`BindData` 릴레이션은 전부 **`SetWeak`**이다 —
생존은 gcconn 클로저의 upvalue와 `gchold[1]`이 이미 보장하고, strong으로 잡으면
두-`Relate` 상호 강참조 순환(Luau에 ephemeron이 없어 실제 누수)에 걸린다.
→ **예/아니오**

### LP-13 — `bindLifetime`의 계약은 정확히 둘
(1) 바인딩이 유효한 동안 `value`는 최소한 `inst`만큼은 산다(`gchold[value]`
강참조), (2) `value`는 `inst`가 살아있는지 스스로 확인할 방법을 갖는다
(`BindData`에 복사된 gcconn 참조) — 이 둘이 구현의 전부다. → **예/아니오**

### LP-14 — 에러 메시지에서 `.Subscribed`를 무조건 인덱싱하면 안 됨
게이트가 값 타입을 안 가리므로 `value`가 평범한 클로저일 수도 있고, 그 경우
`.Subscribed` 필드 접근 자체가 에러다 — 그래서 `isObserver(value) or
isEffect(value)`를 먼저 확인한 뒤에만 그 필드를 읽는다. → **예/아니오**

### LP-15 — `.Subscribed` 필드와 `Subscribed` 테이블이 둘 다 있는 이유
테이블은 강참조 루트(생존 보장), 필드는 `canBound`/`canExecute`가 매번 읽는
O(1) 경로 + 에러 메시지에서 "전역이냐 leaf냐"를 가르는 판별자다. 둘은 항상 같이
쓰고 같이 지우는 한 세트다. → **예/아니오**

### LP-16 — 이름을 둘로 나눈 명분
`canBound`/`canExecute`가 서로의 **부정**이라는 사실은 이름 분리의 명분을
약화시키는 게 아니라 **강화한다**(같은 값을 두 이름으로 부르는 게 아니라 서로
다른 방향을 묻는 두 predicate라서). 또 `Ref`처럼 발화 개념 자체가 없는 값에게
`canExecute`를 묻는 건 개념이 안 맞고, 나중에 "구조적으로 묶여 있지만 발화만
멈춘" 상태가 생기면 단순 부정 관계가 더 벌어질 여지도 있다. → **예/아니오**

### LP-17 — "등록 즉시 1회 실행"은 게이팅과 무관
`state:Observer(fn)`의 "등록 즉시 1회 실행"은 Observer 생성자 자체의 계약이라
`bindLifetime` **이전에** 동기적으로 일어나고(그 시점엔 `canExecute`가 당연히
거짓), 게이팅 대상은 **그 이후의 재실행**뿐이다. → **예/아니오**

### LP-18 — Instance당 gcconn/gchold는 하나
같은 `inst`에 `bindLifetime`을 여러 번 불러도 gcconn/gchold는 하나를 재사용한다
(Instance 생성 시 한 번만 만들고 이후는 `InstData:GetWeak`으로 조회).
→ **예/아니오**

### LP-19 — `canExecute` 비용은 실측 대상
`canExecute`가 매 발화마다 weak table 2단 조회를 하는 비용이 실사용에서
문제되는지는 M0/M2 실측 대상이고, 문제가 되면 gcconn을 `value`의 직접 필드로
내리는 선택지가 있다. 지금 `Relate` 쪽에 둔 건 "Observer 값 자체에 부작용을 안
남긴다"는 방침 때문이고, 성능 근거가 나오면 뒤집어도 되는 순수 구현 세부다.
→ **예/아니오**

### LP-20 — `cleanup`과 `retract`는 다른 층위
`retract`는 Handler 계약의 것(quad 내부 배관이 이전 처리를 무름)이고,
`cleanup`은 `Effect(fn)`에서 **사용자가 작성한 `fn`이 반환하는 콜백**(React
`useEffect`와 동형)이다. 후자는 사용자 API 표면 어휘라 `retract`로 통일할 대상이
**아니다**. → **예/아니오**

### LP-21 — `retract`는 필드가 아니라 역할 이름
코드에서 `handler.retract(...)`를 찾으면 안 된다 — `local retractor =
handler.process(...)`로 받아 `Dispatch`가 `chains`에 보관했다가 부른다.
→ **예/아니오**

---

## RE. `base/relate-plan.md`

### RE-1 — 왜 `SetWeak`/`SetStrong`을 나눴나
바깥 키(`inst`)는 항상 weak여야 하지만 안에 담기는 값은 강하게 붙잡아야 하는
것과 약하게만 참조해도 되는 것이 둘 다 있고, Lua 테이블의 `__mode`는 테이블
전체 단위라 하나로 표현할 수 없다. → **예/아니오**

### RE-2 — Relate는 자동으로 홀드하지 않는다
`Relate` 자신은 `inst`도 `value`도 자동으로 홀드하지 않고, 어느 쪽을 얼마나
강하게 들지는 호출부(주로 quad-roblox)가 매번 명시한다 — 엔진 객체의 실제
생명주기를 아는 쪽만이 "strong으로 둬도 안전하다"를 판단할 수 있기 때문.
→ **예/아니오**

### RE-3 — `inst` 자리는 항상 weak
첫 인자(`inst`)의 강/약 자유도는 **아예 안 열어둔다** — `Weak`/`Strong`은 오직
`value`의 보관 방식을 가리킨다. → **예/아니오**

### RE-4 — 비싱글톤, 모듈별 하나씩
`Relate()`는 생성자이고, 각 핸들러 모듈이 자기 톱레벨에 `local relate =
Relate()`를 하나씩 두고 재사용한다 — 서로 다른 인스턴스라 `key` 네이밍이 모듈
간에 겹칠 걱정이 없다. → **예/아니오**

### RE-5 — quad 바깥 Instance를 키로 쓰는 건 UB
quad가 만들지 않은 Instance는 gcconn 셋업을 안 거쳤을 수 있으므로 `Relate` 키로
쓰는 건 UB이고, 그런 스코프를 여는 설계를 한다면 "키로 쓰기 전에 gcconn 셋업을
먼저 건다"를 같이 설계해야 한다. → **예/아니오**

### RE-6 — 항상 `SetWeak` 규칙의 근거
"다른 곳에서 안전하게 유지되는 것은 항상 `SetWeak`"의 이유는 성능이 아니라
**디버깅 가능성**이다 — 같은 값을 강참조로 두 번 잡으면 "이 값의 실제 수명이
어디서 끝나는가"의 답이 둘이 되어 조용한 누수가 생긴다. → **예/아니오**

### RE-7 — 두-`Relate` 상호 강참조 순환은 실제 누수
Luau는 ephemeron 테이블이 없다고 공식 문서에 명시돼 있으므로,
`RelateA[inst]=value`(강)와 `RelateB[value]=inst`(강)가 동시에 존재하면
**둘 다 GC가 안 되는 실제 메모리 누수**다 — "혹시 몰라 피한다"가 아니라 확정된
필수 규칙이다. 단일 `Relate` 안에서의 자기참조는 안전하다. → **예/아니오**

### RE-8 — `Relate`를 쓰지 말아야 할 경우
이 `process` 호출이 만든 것을 그 호출이 반환한 클로저가 정리하는 단발성
handoff는 **클로저 캡처로 충분**하고 `Relate` 왕복이 통째로 불필요하다.
`kSlotMap`/`kTagMap`/Attribute의 `groupState`가 전부 이 이유로 삭제됐다.
→ **예/아니오**

### RE-9 — `Relate`를 써야 할 경우
(a) 여러 위치가 하나의 자원을 공유할 때의 참조 카운트(`tagNameMap`),
(b) 여러 `process` 호출을 가로지르는 dedup 기록(`Ref` — 클로저가 받는 인자는
*다음* 값이지 *이전* 값이 아니라 캡처로 대체 불가), (c) 소유권/멤버십 전역
판정(`elementOwner`), (d) "언제까지 실행돼도 되는가", (e) 인스턴스별 멱등 가드.
→ **예/아니오**

### RE-10 — weak라도 명시적으로 지울 것
`SetWeak`이어도 **언제 사라지는지는 GC 타이밍**이라 그 전에 같은 키를 다시
쓰려는 코드가 비결정적으로 실패한다 — 명시적으로 만든 기록은 명시적으로
지운다. → **예/아니오**

### RE-11 — lazy 생성 전략
`Relate()` 호출 시점엔 아무것도 미리 안 만들고, `inst`당 서브테이블도 그 안의
`StrongMap`/`WeakMap`도 `Set`이 처음 불릴 때 생성한다. `WeakMap`의 메타테이블은
모듈 로드 시 하나 만들어 모든 `WeakMap`이 공유한다. `Get`은 서브맵이 없으면 그냥
`nil`을 반환한다(읽기가 쓰기를 유발하면 안 됨). → **예/아니오**

---

## BR. `base/brand-plan.md`

### BR-1 — 태그는 문자열이 아니라 테이블 아이덴티티
브랜드 태그로 테이블 레퍼런스를 쓰는 이유는 성능이 아니라 **오타 안전성**이다
(오타난 문자열 리터럴은 등록/조회가 조용히 어긋나지만, 잘못된 변수 참조는 즉시
드러남). → **예/아니오**

### BR-2 — `isX`는 얇은 wrapper
`Brand`를 직접 노출하지 않고 각 `isX`가 얇게 감싸며, 상위 관계가 있는 것은
**더 구체적인 predicate를 먼저 정의하고 그 위에 OR로 얹는** 합성 방식으로 짠다
(플랫한 집합 멤버십이 아니라) — 포함 관계의 방향이 코드 모양에 드러나게 하려고.
→ **예/아니오**

### BR-3 — `isRef`는 상위 개념
`isRef(x)`는 `{Ref, PreRef, PostRef}` 셋을 전부 통과시키는 상위 개념이고,
`isRef(preRefInstance)`는 **`true`**다. `PreRef`/`PostRef` 사이엔 포함 관계가
없다(배타적 형제). → **예/아니오**

### BR-4 — Leaf 매치의 명시적 제외
`Dispatch/Leaf.luau`의 일반 `Ref` 매치는 `isRef(v) and not isPreRef(v) and not
isPostRef(v)`로 **호출부가 명시적으로** 좁혀야 한다. → **예/아니오**

### BR-5 — `isSource`는 별도로 필요
`Source`는 State보다 진짜로 더 많은 능력(`:Set`/`:Emit`)을 가진 서브타입이라
"쓰기도 되는 원천인가"를 묻는 코드엔 `isState`만으론 부족하다. `isState`는
`{State, Source}` 둘 다 통과시킨다. → **예/아니오**

### BR-6 — `Brand`는 의존성이 없다
`Brand.get`이 `x == None`을 먼저 확인하는 특수 분기를 두지 않는다 — 가장 밑바닥
유틸이 다른 프리미티브를 참조하게 되기 때문. `isNone`은 그냥 `v == None`이면
되고, `None`을 레지스트리에 **평범하게 태깅**하는 건 무방하다. → **예/아니오**

### BR-7 — duck-typing 기각 근거
duck-typing을 안 쓰는 이유는 (a) 우연히 비슷한 모양의 값에 false positive,
(b) 일부 Roblox userdata는 정의 안 된 키 인덱싱 자체에서 에러를 던져 `pcall`로
감싸야 하거나 최악의 경우 엔진이 죽는 상황까지 생김 — 둘 다다. → **예/아니오**

### BR-8 — 자동 narrowing은 없다
`isX(v)`가 참이어도 Luau가 정적 타입을 알아서 좁혀주지 않으므로(사용자 정의
타입 가드 미지원), `local s = v :: State<any>`처럼 명시적 `::` 캐스팅을 붙이는
게 실제 패턴이다. → **예/아니오**

### BR-9 — 이름은 가칭
`Brand`/`ObserverTag`류 이름 자체는 여전히 용어 정리 대상이다. → **예/아니오**

---

## M. `base/modifier-plan.md`

### M-1 — Modifier는 핸들러 레지스트리에 없다
Modifier는 `isHandlable`/`priority`/`process` 레지스트리에 안 들어가고, 디스패치
들어가기 전에 한 번 flatten돼 최종 props에 합쳐지는 **정적 값**이다. 런타임
pluggable로 만들면 CSS cascade 문제가 그대로 오고, 그건 "Store 바인드 변경은
전체 교체"라는 확정 원칙과 충돌한다. → **예/아니오**

### M-2 — flatten의 판별 수단
flatten은 배열을 훑으며 `isModifier(v)`가 참인 항목만 필드를 뽑아 merge하고
나머지는 전혀 안 건드리고 배열 파트에 그대로 남긴다(그래서 `None`은 flatten을
그냥 통과한다). → **예/아니오**

### M-3 — Property에 소유권 레지스트리를 안 쓰는 이유
Attribute 이름은 호출자가 자유롭게 짓는 네임스페이스라 전용 키 객체를 만들 수
있지만, Instance 프로퍼티 이름은 엔진이 정해둔 유한 집합이라 호출자가 자기만의
전용 키를 못 만든다 — 그래서 "이 프로퍼티를 지금 누가 소유하는가"라는 질문
자체가 성립하지 않고, Property는 소유권 추적 대신 **덮어쓰기 우선순위**로
처리된다. 여러 컴포넌트가 같은 프로퍼티를 건드리는 건 오히려 정상 시나리오다.
→ **예/아니오**

### M-4 — Merge 우선순위는 독립된 두 규칙
(a) 배열에 나열된 modifier끼리는 나중 것이 우선, (b) 인라인 키는 modifier가 뭘
하든 무조건 우선 — Lua 테이블 리터럴이 배열/해시 파트 간 소스 순서를 보존하지
않으므로 단일 규칙으로 합칠 수 **없다**. → **예/아니오**

### M-5 — `None`은 raw 저장 계층에만 있는 실재 센티널
`{ TextColor3 = None, mod }`도 `mod:TextColor3(None)`도 둘 다 지원되고, Modifier
setter/`Overridden`/인라인 props는 `None`을 그냥 평범한 raw 값으로 저장·교체할
뿐 특별 취급이 전혀 없다. 실제 "지우기"는 디스패치 단계의 `NoneHandler`가
담당한다. → **예/아니오**

### M-6 — `Peek`의 반환 타입
`:Peek<T>(key)`는 raw 저장값을 그대로 읽으므로 반환 타입이
`T | State<T> | None | nil`이고, "필드가 아예 안 채워짐"(`nil`)과 "명시적으로
지워짐"(`None`)이 raw 계층에서 계속 구별된다. → **예/아니오**

### M-7 — immutable clone 체이닝
모든 변환 메소드는 `table.clone(self)` 후 필드만 덮어써 반환하고 원본은 절대
mutate하지 않는다. 별도 제네릭 clone 콤비네이터 타입은 기각이다. 비용은
`table.clone`이 native shallow-copy라 무시 가능하고 렌더/컴포지션 타임에만
발생한다. → **예/아니오**

### M-8 — 바닥 생성자
체이닝의 시작은 `Modifier()`(필드 없는 빈 인스턴스)이고, `mod:FontSize(20)`류
예시는 전부 이 빈 인스턴스 위에서 시작한다. → **예/아니오**

### M-9 — Setter는 리터럴과 변환 함수 둘 다
`:FontSize(value)`와 `:FontSize(function(current) ... end)` 둘 다 지원하고,
**Getter는 안 만든다**(변환 함수 하나가 getter가 필요했던 유일한 케이스를
인라인으로 커버). `old`는 항상 "현재 저장된 그대로" 넘어간다(plain이면 raw 값,
State면 State 핸들 그 자체). → **예/아니오**

### M-10 — `func(state) -> state` 인자 모양 기각
"여러 Compute를 합치고 싶다"는 동기는 (1) 변환 함수 본문에서 다른 함수를 그냥
호출, (2) 필드 자체를 State로 만들고 싶으면 리터럴 자리에 State를 직접 넘김 —
둘로 이미 커버되므로 세 번째 모양은 불필요하다. → **예/아니오**

### M-11 — 필드는 `self` 리터럴 키에 저장하면 안 된다
`__index`는 `rawget`이 실패할 때만 불리므로 `clone.FontSize = 14`처럼 self
최상위에 박으면 다음 `mod:FontSize(fn)` 호출이 `(14)(mod, fn)`이 되어
`attempt to call a number value`로 죽는다. 필드 데이터는 유일 테이블 identity
키로 분리된 내부 테이블에 담고, setter 안에서 그 내부 테이블도 따로
`table.clone` 해야 한다(`luau-test/done/17`이 실측 검증). → **예/아니오**

### M-12 — 제네릭 `__index` 하나면 충분
`__index`가 어떤 key가 오든 그 key를 캡처한 클로저를 즉석 생성하므로 필드별로
미리 등록된 메소드가 하나도 없어도 된다. 클래스별 flat 타입 생성은 순전히
**정적 타입 체크**용이고 런타임 코드량은 절대 안 늘어난다. 이 메커니즘은
Roblox API에 전혀 의존 안 하므로 Modifier 체이닝 엔진은 **quad-base에 완결된
구현으로 존재**한다(주입할 엔진별 구현이 애초에 없음). → **예/아니오**

### M-13 — `table.clone`의 메타테이블 동작
`table.clone`은 얕은 복사 후 원본의 메타테이블을 **같은 참조로 공유**시키므로,
제네릭 `__index` 함수가 원본과 clone 사이에서 물리적으로 동일 객체이고 체이닝이
안 끊긴다 — M7 설계가 의존하던 두 Luau 동작 모두 확인됐다. → **예/아니오**

### M-14 — 핸들러 계층 값은 필드에 못 들어온다
Modifier 필드에 `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier`가
들어오면 UB가 아니라 **즉시 error**이고, 체크 지점은 제네릭 setter가 최종 저장
직전에 확정한 값 하나다(리터럴이든 변환 함수 반환이든 동일하게 걸림).
State/Source는 여전히 허용된다. → **예/아니오**

### M-15 — `State<Ref>`류는 UB로 남김
State/Source가 담고 있는 **안쪽** 값이 핸들러 계층 값인 경우는 이 체크로 못
잡고(검사 시점엔 아직 실체화 안 됨), 매번 `:Get()`해서 검사하는 건 관측 시점을
앞당기는 오버엔지니어링이라 **방어 로직 없는 순수 UB로 문서화만** 한다.
→ **예/아니오**

### M-16 — 필드가 State일 때의 setter 분기
현재 필드가 State인데 **리터럴**을 주면 State를 통째로 덮어써 **의도적으로
반응성이 끊기고**, **함수**를 주면 `field:Compute(fn)`으로 새 파생 State를 만들어
반응성이 유지된다. 이 차이는 사용자가 인지하고 골라 쓰는 것으로 문서화한다.
→ **예/아니오**

### M-17 — Modifier는 소유권/유일성 제약이 없다
Modifier는 자식을 담지 않는 마운트 정체성 없는 순수 값이라, 같은 modifier를
트리 여러 곳에 반복 적용해도 에러가 안 난다(Ref/Slot 자식의 "정확히 한 곳"
제약과 다름). → **예/아니오**

### M-18 — `State<Modifier>`는 런타임 error
State/Source의 **value**가 Modifier인 경우는 명시적 `error`이고, 적용 지점은
`Source:Set(value)` / `Store({defaults})`의 각 `Source(v)` 생성 시점 /
`:Compute(fn)` 결과 캐싱 직전 셋이다. → **예/아니오**

### M-19 — Modifier만 막고 나머지는 허용하는 근거
Slot/Tag/Attribute 등은 정상적으로 재귀 재-dispatch 경로를 타는 진짜 dispatch
참가자라 State/Source에 담겨도 기존 메커니즘이 처리해준다. Modifier만 유독
문제인 건 **dispatch 경로를 아예 안 타는 유일한 존재**라서다. `Tween<T>`는 이
그룹에서 빠졌고, 담기는 게 허용되는 이유가 "재귀 dispatch 참가자라서"가 아니라
"그냥 raw 값이라서"로 바뀌었다. → **예/아니오**

### M-20 — `:Apply(factory)`의 정의
`mod:Apply(factory)`는 `function(self, factory) return factory(self) end`가
전부이고, `Apply` 자체는 clone할 필요조차 없다(factory가 이미 새 값을 만들어
줌). `factory`가 뭘 하든(에러를 던지든) `Apply`는 관여하지 않는 순수 sugar이고,
"Apply 자체가 뭔가를 검증/보장해준다고 오해하지 말 것"을 문서에 명시한다.
→ **예/아니오**

### M-21 — 고정 메소드 셋
고정 메소드는 `Apply` / `Peek` / `Overridden` **셋**이고 셋 다 Modifier 필드
이름으로 예약된다. `__index`는 고정 메소드 테이블을 먼저 확인하고 없을 때만 필드
setter를 합성해야 하며, **`FrameModifier`류 타입 생성 스크립트의 제외 목록에
셋 다** 들어가야 한다(M7). → **예/아니오**

### M-22 — `Merge` → `Overridden` 이름 변경 근거
"Merge"는 중립적 합침을 암시하지만 실제 동작은 나중 인자가 이기는 덮어쓰기라
이름이 의미를 정직하게 반영해야 한다. 분사형(`Added`/`Removed`/`Merged`)
컨벤션에 맞춘 불규칙동사 과거분사이고 `Overrided`는 오기다. → **예/아니오**

### M-23 — `Overridden`의 용도는 좁다
`Overridden`는 범용 조합 도구가 아니라 `Frame{mod1, mod2}`의 **컴포넌트
경계판**이다(단일 슬롯 `props.Modifier`에 독립 modifier 값 여러 개를 넣을 유일한
방법). 초심자 문서엔 아예 안 보여주고, "특정 modifier를 계속 바꿔나가고 싶다"는
요구는 `Apply`로 유도한다. → **예/아니오**

### M-24 — baked 값 교체의 경고
`Overridden`의 필드 교체는 그 필드에서 파생된 다른 필드에 **소급 반영되지
않는다**(`Font`를 바꿔도 이미 계산된 `FontWeight`는 그대로) — 조용히 틀린 결과가
나오는 케이스라 API 문서의 경고 박스로 명시하고, `A:Overridden(B)`와
`B:Overridden(A)`의 순서 의존성도 같이 명시한다. → **예/아니오**

### M-25 — `Apply` vs `Overridden`의 판별 기준
한 줄 구분은 "`Apply`는 변경을 수행, `Overridden`는 이미 baked된 다른 mod를
합침"이고, 실제 판별 기준은 "동질적/이질적 주제"가 아니라 **한쪽이 다른 쪽의
baked 값을 읽어야 하는가(`Peek`으로 데이터가 흘러가는가)**다. → **예/아니오**

### M-26 — mutable `Apply` 기각
`Apply`/setter를 mutable로 바꾸는 방안과 "`Apply` 경계에서만 clone"이라는
절충안은 **둘 다 기각**이다(immutable 하드 제약이 clone 비용 절감보다 우선,
절충안은 문제가 어디서 터지느냐만 바뀜). 실측으로 병목이 확인되면 그때 opt-in
fast-path를 검토하되 지금은 근거 없는 선제 최적화라 설계하지 않는다.
→ **예/아니오**

### M-27 — `Overridden`는 캐싱이 아니다
"재사용 조각을 모듈 상수로 만들어 `Overridden`로 결합"하는 최적화 권장 패턴은
`Overridden`가 내부적으로 캐싱해준다는 뜻이 **아니다** — 순수 필드 복사일 뿐이고,
"캐싱"은 사용자가 값을 변수로 재사용하는 평범한 일이다. → **예/아니오**

### M-28 — `Overridden`의 타입 시그니처는 느슨하게
서브타입 관계(FrameModifier vs GuiObjectModifier)를 섞는 경우 setter 반환 타입이
갈려 구조적 서브타이핑이 깨진다는 게 **실측으로 확인**됐으므로,
`Overridden(...: any): any`류로 느슨하게 열고 정적 체크를 포기한다 — 이건 임시
처치이고 M7에서 다시 좁히는 걸 목표로 둔다. → **예/아니오**

### M-29 — `Peek` 이름의 근거
`Get`이 아니라 `Peek`인 이유는 프로젝트 전역에서 `State:Get()`이 "확정한다"는
의미로 자리잡았는데 Modifier의 읽기는 정반대(들고 있는 그대로)이기 때문이다.
`.RealValue.Font` 같은 별도 인덱싱 표면은 기각됐다. → **예/아니오**

### M-30 — `Tween<T>` 타입 합성
프로퍼티류 Modifier 필드는 `T`를 `T' = T | Tween<T>`로 치환하기만 하면
`T | Tween<T> | State<T | Tween<T>>`가 자동으로 나오므로, 런타임에 `Tween` 인지
로직을 전혀 추가할 필요가 없다. → **예/아니오**

---

## BK. `base/blocker-plan.md`

### BK-1 — Blocker가 Batch 대신인 이유
lexical `Batch(fn)`은 코루틴 yield 위에서 구조적으로 위험해 기각됐고, Blocker는
그 문제를 **콜스택/코루틴이 아니라 사용자가 들고 있는 "값"으로 표현**해서 이
위험을 구조적으로 우회한다. → **예/아니오**

### BK-2 — Blocker는 유일한 게이트
`Blocker`는 quad에서 emit 전파를 지연시킬 수 있는 **유일한 요소**이고,
Debounce/Throttle의 시간 기반 게이트가 나중에 같은 자리에 들어온다. 평범한
State는 절대 신호를 삼키지 않는다. → **예/아니오**

### BK-3 — `state:Block(blocker)`의 등록 시점
`state:Block(blocker)`는 **호출되는 즉시**(나중에 처음 블록될 때가 아니라)
onunblock 핸들을 blocker의 **weak 배열**에 등록하고 새 gated state를 반환한다.
→ **예/아니오**

### BK-4 — `Off()`와 `OffWithoutEmit()`의 차이
둘 다 `IsBlocked = false`로 **먼저** 설정한 뒤 등록된 onunblock 핸들을 전부
실행하고, 차이는 넘기는 `emit` 플래그 하나뿐이다 — `Off()`는 "밀린 전파를
흘려보내며 끈다", `OffWithoutEmit()`은 "밀린 전파를 버리며 끈다". 어느 쪽이든
`HasBlockedEmit`은 깨끗하게 리셋되고 idempotent다. → **예/아니오**

### BK-5 — `:Get()`엔 영향 없음
블록은 emit **전파**만 지연시키고, 블록 중이라도 `:Get()`하면 그 순간의 실제
값을 정상 계산해 준다. → **예/아니오**

### BK-6 — Block은 최종 연산 지점에
Block은 **파이프라인의 최종 연산 지점**(실제로 무거운 계산이 일어나는 derived
state)에 거는 게 원칙이고, 소스 쪽에 각각 거는 게 아니다. → **예/아니오**

### BK-7 — 두 번째 용례에서 `OffWithoutEmit`을 쓰는 이유
base 내부 부기 게이팅(Length/Offset 배치)은 `state:Block()`을 전혀 호출하지
않으므로 gated state도 onunblock 핸들도 없고, `Off()`와 `OffWithoutEmit()`이
사실상 동일하게 동작한다 — 그래도 **의도를 코드에 남기기 위해**
`OffWithoutEmit()`을 쓴다. → **예/아니오**

### BK-8 — 토글 이름이 `On()`/`Off()`인 이유
`state:Block(blocker)`가 이미 "배선" 동사로 Block을 쓰므로, Blocker 자신의
토글까지 같은 단어를 쓰면 `blocker:Block()`과 `state:Block(blocker)`가 같은
단어로 다른 두 동작을 가리키게 된다. → **예/아니오**

### BK-9 — `HasBlocked` 신설 안 함
`IsBlocked`/`HasBlockedEmit` 필드는 그대로 유지하고 Blocker 자신의 새 최상위
플래그(`HasBlocked`)는 **신설하지 않는다** — `OffWithoutEmit()`이 각 gated
state의 기존 `HasBlockedEmit`을 리셋해주는 것으로 충분하다. → **예/아니오**

### BK-10 — 재진입 의도적 미지원
`IsBlocked`는 카운터가 아니라 단순 불리언이고 **의도적으로 그렇다** —
레퍼런스 카운팅은 "`On()` 여러 번, `Off()` 실수로 적게"가 **영구 블록으로
조용히 새는** 더 위험한 실패 모드를 만든다. 겹치는 배치가 필요하면 각자 새
Blocker를 만들고, 이 제약은 API 레퍼런스 수준에서 강조한다. → **예/아니오**

---

## E. `base/effect-plan.md`

### E-1 — Effect는 Observer의 브랜드 재사용이 아니라 조합
`state`를 받는 Effect는 Observer를 **조합(compose)**해서 만들어진다 —
`Ref`/`PreRef`처럼 브랜드 태그만 다른 재사용이 아니라 Observer 위에 자동
cleanup 배선을 얹은 한 단계 위 계층이다. → **예/아니오**

### E-2 — Effect가 자유 함수인 이유
`state` 없이도 성립하는 mount/unmount 전용 유스케이스가 있고, 실제 leaf
생명주기 바인딩을 `state`가 소유하지 않기 때문이다. Luau 테이블엔 `__gc`가
없어서 "진짜 사라지는 순간"을 아는 유일한 방법이 `Instance.Destroying`류
명시적 신호뿐이라는 게 이 프리미티브가 따로 필요한 근거다. → **예/아니오**

### E-3 — `state` 유무별 동작
`state` 생략 시 `fn()`을 즉시 1회 실행하고 리턴한 cleanup을 leaf 사망 시 정확히
1회 호출하며 재실행은 없다. `state` 지정 시 `state:Observer(...)`를 감싸
"등록 즉시 1회 실행"이 설치를 겸하고, 무효화마다 직전 cleanup → `fn` 재호출,
leaf 사망 시 마지막 cleanup을 한 번 더 호출한다. → **예/아니오**

### E-4 — `fn(state)`의 인자
`fn`은 포지셔널로 `state`를 받고 그건 lazy `State` 핸들이다. `Effect`는
`base/typing-limits.md` 1번 한계의 영향 범위 **밖**이다(자유 함수라 "재귀 타입의
필드 + 로컬 제네릭" 조건에 안 걸림). → **예/아니오**

### E-5 — leaf 비용
Effect의 leaf 바인딩 비용은 leaf당 실제 Destroying 바인딩 하나로, 공유 weak
table로 되는 Observer보다 비싸다 — 필요할 때만 쓰는 걸로 충분하다.
→ **예/아니오**

### E-6 — `EffectHandle._observer`의 목적
`handle._observer` 강참조는 GC 방지가 목적이 **아니고**(그건 `gchold`가 담당),
`:Unsubscribe()`/`bindLifetime` cascade가 내부 Observer에 접근하기 위한 것이다.
→ **예/아니오**

### E-7 — cascade가 필요한 이유
`bindLifetime(inst, handle)`은 내부 Observer에도 cascade해야 한다 —
`canExecute(observer)`가 보는 gcconn 참조는 **그 Observer 자신이
`bindLifetime`될 때** 복사되는 것이라, 안 하면 그 Observer에겐 판정 근거가 아예
없어 `canExecute`가 항상 거짓이 되고 재실행이 통째로 죽는다.
`unbindLifetime(handle)`도 대칭으로 같이 풀어야 한다. → **예/아니오**

### E-8 — Observer 자체에 cleanup 계약 추가는 기각
Observer 자체에 React식 반환값 자동 배선을 넣는 안은 기각이고(클로저 업밸류로
충분), 그건 "패턴 자체가 무용하다"가 아니라 "Observer에 이 복잡도를 넣지
말자"였으므로 `Effect`가 opt-in 상위 계층으로 제공하는 것과 충돌하지 않는다.
→ **예/아니오**

### E-9 — `:Unsubscribe()`는 `:Subscribe()`의 짝
`:Unsubscribe()`는 `:Subscribe()`로 등록한 핸들에만 적용되고, **leaf 바인딩된
핸들에는 지원하면 안 되거나 최소한 그 경로에서 cleanup을 앞당기면 안 된다**.
위험한 이유는 leaf + `State<Effect>` 조합에서 값이 안 바뀌면 dedup 때문에
retract가 아무 일도 안 하는데, `:Unsubscribe()`가 cleanup을 미리 실행하면 뒤이은
재-dispatch에서 재바인딩이 안 일어나 그 Effect가 조용히 죽은 채로 남기 때문이다.
→ **예/아니오**

### E-10 — ⚠️ 미해결 항목 확인: dedup 경로의 대칭
그 dedup 경로에서 retract가 아무것도 안 한 뒤 `process` 쪽도 정말 아무것도 안
하는지 대칭이 실제로 성립하는지는 **아직 확인 안 된 항목**이고, 특히
`EffectHandle`의 내부 Observer cascade가 dedup 분기 안에 제대로 들어가 있는지는
별도 확인 대상이다(M3 착수 전). → **예/아니오**

### E-11 — `:Subscribe()`한 핸들의 `:Unsubscribe()` 의미 확장
Observer의 `:Unsubscribe()`는 "미래 재실행만 끊는다"로 충분하지만, Effect의
계약은 "생애주기가 끝나는 시점에 마지막 cleanup이 정확히 1회"이므로
`:Unsubscribe()`도 "지금 끝났다"는 신호로 취급해 (1) 내부 Observer 구독을 끊고
(2) 직전 cleanup을 정확히 1회 호출하며 (3) 이후 leaf가 실제로 죽어도 중복
호출되지 않는다. → **예/아니오**

---

## EV. `base/event-plan.md`

### EV-1 — 이벤트 핸들러는 self를 안 받는다
v1의 `function(self, ...)` 관습은 채택하지 않고, 엔진이 네이티브로 주는 이벤트
인자만 받는다. 근거는 (1) Ref가 이미 그 자리를 채움, (2) thin wrapper를 주면
Modifier 정적 flatten과 경쟁하는 두 번째 쓰기 경로가 생김, (3) quad-debug의
그래프 밖 경로를 공식 API로 만드는 셈, (4) self 전달을 위해 Connect마다 클로저를
한 번 더 할당해야 함 — 넷 다다. → **예/아니오**

### EV-2 — 일반화의 범위
"엔진이 네이티브로 콜백에 뭘 주든 감싸지 않고 그대로 호출한다"는 원칙 자체는
일반적이지만, 이벤트 등록이 quad-roblox에만 있는 개념이라 이건 **base 문서가
아니라 quad-roblox 로컬 결정**이다. → **예/아니오**

### EV-3 — disconnect 센티널은 `None`/`nil`
disconnect 센티널은 `false`가 아니라 `None`(그리고 그 재귀가 만드는 `nil`)이다 —
`None`이 정확히 그 역할로 이미 도입돼 있어 같은 문제를 푸는 센티널이 둘이 될
이유가 없다. → **예/아니오**

### EV-4 — `EventHandler.isHandlable`의 계약
`NoneHandler`가 먼저 매치해 재귀하므로 `EventHandler`가 실제로 받는 값은
`nil`이고, 따라서 **`isHandlable`은 `v == nil`인 경우에도 매치돼야 한다**
("`nil`이면 매치 안 함" 가드를 넣으면 안 된다는 게 명시적 계약). 매치 판정은
값이 아니라 키(리플렉션)로 한다. → **예/아니오**

### EV-5 — `NilHandler`와 안 겹침
`NilHandler`는 `type(k) == "number"` 전용이고 이벤트 키는 문자열이라 겹치지
않는다. → **예/아니오**

### EV-6 — 값 타입 유니온
이벤트 값 타입은 `((...) -> ())? | false`가 아니라
`((...) -> ()) | None | nil`(그리고 `State<...>`)이고, `D` 생성기가 이 유니온을
포함해야 한다. → **예/아니오**

### EV-7 — 기본 권장 패턴은 store-bind가 아니다
저빈도 UI 이벤트를 조건부로 켜고 끄는 흔한 케이스는 "핸들러 하나를 계속
연결해두고 안에서 분기"가 더 싸고 익숙해서 **기본 권장 패턴**이고, store-bind가
값어치 있는 지점은 고빈도 신호나 로직 자체가 바뀌는 드문 케이스다. 자주
재계산되는 State에 이벤트를 물리면 매 재계산마다 Disconnect+Connect가 도는 숨은
churn 비용이 있다(Store Set은 dedup 안 함). → **예/아니오**

### EV-8 — 그래도 일관성 있게 지원
"저빈도엔 필요 없다"가 "예외로 빼자"로 이어질 이유는 없고, 프로퍼티/태그/
어트리뷰트가 전부 store-bind되는데 이벤트만 특별 취급할 근거가 약해 일관되게
지원하되 적극 권장하지는 않는 톤으로 문서화한다. → **예/아니오**

---

## OC. `base/onchange-plan.md`

### OC-1 — 별도 특수 키가 필요한 이유
`GetPropertyChangedSignal(name)`은 프로퍼티 이름을 인자로 받는 별도 메소드
호출이고 그 이름이 "값 세팅" 키 네임스페이스와 겹쳐서, 값 타입만으론 세팅과
리스닝을 구분할 수 없다. → **예/아니오**

### OC-2 — 제네릭 타입 파라미터 없음
`OnChange<T>` 같은 파라미터화는 안 하고 콜백 타입은 호출부가 인라인으로 직접
명시한다. 진짜 이유는 "이벤트도 타입 검증이 안 되니까"가 **아니라**
(그 전제는 거짓), `OnChange(name)`이 이름을 인자로 받는 **팩토리라 생성기가
타입을 찍어둘 필드 자리가 없다**는 것이다. → **예/아니오**

### OC-3 — 패키지는 quad-roblox
`AttributeKey`는 부기가 엔진 지식을 요구하지 않아 quad-base로 갔지만, `OnChange`는
`GetPropertyChangedSignal` **자체가 로직**이라 "한 줄 op 주입"으로 줄어들지 않아
quad-roblox에 남는다. → **예/아니오**

### OC-4 — 이름별 weak 캐시
`OnChange(name)`도 `AttributeKey`와 같은 이름별 weak 캐시를 써서
`OnChange "a" == OnChange "a"`가 성립하고, 그게 외부에서 관찰 가능해지는 것도
의도적으로 허용한다. 캐시는 키 객체 identity만 다루므로 `State<function>`이어도
문제없다. → **예/아니오**

### OC-5 — `State<function>` 지원에 전용 분기 없음
`v`가 State면 범용 `StoreBind`가 언랩+재귀 재-dispatch해주므로 `OnChange` 전용
분기가 필요 없다. → **예/아니오**

---

## PE. `base/purity-and-effects-plan.md`

### PE-1 — 문제의 재정의
quad는 vdom이 없어 컴포넌트 함수가 **딱 한 번만 실행**되므로, 실제 문제는
"순수함수냐"가 아니라 **"재사용을 의도한 컴포넌트가 자기 입력 밖의 것에 은밀히
의존하는가"라는 이식성**이었다. → **예/아니오**

### PE-2 — 기술적 강제 안 함
"전역 참조 금지"를 런타임/타입/린트로 강제하지 않고 UB로 두고 문서로만 경고한다
(과도한 엔지니어링 + 정당한 유스케이스까지 막을 위험). 한 번만 쓰이는 페이지
컴포넌트가 전역을 참조하는 건 오히려 자연스럽다. → **예/아니오**

---

## R. `base/ref-plan.md`

### R-1 — Ref의 용도
Ref는 Tween이 대상을 얻기 위해 필요한 게 아니고(핸들러는 항상 `inst`를 직접
받음), id 조회의 대체도 아니다 — "라이브러리가 자기가 만든 instance를 나중에
다루기 편하게" 하는 용도이고, 얻어진 뒤 어디에 저장하고 어떻게 쓰는지는
사용자 자유다. → **예/아니오**

### R-2 — Ref 반출 권장 관례
Ref는 만든 컴포넌트 자신이 쓰거나 자식에게 넘겨 쓰는 게 관례이고(React
`useRef`와 같은 스코프 감각), 컴포넌트 경계를 넘어 위로 반출하거나 전역에 장기
보관하는 건 권장하지 않는다 — Ref가 Destroy와 완전히 무관하게 동작하므로 그게
use-after-destroy가 발생할 사실상 유일한 자리다. quad는 여기에 런타임 안전망을
두지 않으며 위반 시 완전한 UB다. → **예/아니오**

### R-3 — 별도 `CreatedRef` 래퍼 없음
`Ref(default)` 인스턴스 자체를 숫자 키 슬롯에 그대로 넣는 게 바인드 관용구이고,
별도 래퍼 함수는 없다. → **예/아니오**

### R-4 — 왜 값이 아니라 콜백인가
quad는 렌더 함수가 재실행되지 않으므로 "매 렌더마다 다시 확인"하는 모델 자체가
없고, 값이 채워지는 시점을 외부에서 알아낼 방법이 콜백(폴링은 기각)뿐이다.
값으로 얻고 싶으면 콜백 안에서 원하는 곳에 대입해 캡처하면 되므로 별도 API가
필요 없다. → **예/아니오**

### R-5 — 범용 값 박스
Ref는 엔진 instance 전용이 아니라 아무 사용자 값이나 담는 범용 값 박스이고,
object-ref/function-ref로 나누지 않는다(React `useRef` 선례 — 쪼개면 사용자가
매번 어느 쪽인지 판단해야 함). → **예/아니오**

### R-6 — API 세 메소드
API는 `.Value`(읽기 전용 필드) + `:Set(value)` + `:Callback(fn)`(복수 허용) +
`:Wait(thread?)`이고, 세 메소드 전부 mutation 패턴이라 **자기 자신을 반환**한다.
→ **예/아니오**

### R-7 — 콜백은 등록 즉시 1회
콜백은 이미 채워져 있으면 등록 즉시 그 값으로 1회 호출되고, nil/미설정
상태여도 그 상태 그대로 호출된다. → **예/아니오**

### R-8 — `.Callbacks` 분리
콜백/대기자는 별도 필드 `.Callbacks` 테이블에 담고 `.Value`는 그냥 평범한 hash
필드다 — 순회 대상이 `self`가 아니게 되므로 hash 파트 충돌이 안 생기고 `.Value`를
`__index` 메타메소드로 구현할 이유가 사라진다. 대가는 Ref당 테이블 하나 추가뿐이다.
→ **예/아니오**

### R-9 — `:Wait(thread?)`의 두 모드
`thread`를 생략하면 `coroutine.running()`으로 자신을 등록하고 그 자리에서
`coroutine.yield()`로 **자기 자신을 정지**시킨다. 명시적으로 다른 thread를
넘기면 **등록만 하고 정지 없이 즉시 `self`를 반환**한다 — `coroutine.yield()`는
지금 실행 중인 코루틴만 정지시킬 수 있기 때문이다. → **예/아니오**

### R-10 — resume payload는 `self`
`:Set()` 시 대기자 thread를 재개할 때 넘기는 건 값이 아니라 **Ref 자기 자신**
이다 — 그래야 `ref:Wait().Value` 관용구가 성립한다. 반면 일반 콜백은 여전히
원래 값을 직접 받는다(`v(value)`). → **예/아니오**

### R-11 — 분기와 소진
`type(v) == "thread"`면 대기자로 보고 resume 후 `[i] = nil`로 소진,
`"function"`이면 콜백으로 보고 호출만 하고 소진 안 함, `nil`이면 빈 슬롯이라
스킵한다. 새 등록은 `table.insert`가 아니라 **빈 슬롯을 선형 탐색해 재사용**한다.
→ **예/아니오**

### R-12 — 왜 `None`이 아니라 `nil`인가
Ref의 콜백/대기자 배열은 **순서가 중요하지 않고**(전부 fire되기만 하면 됨) 일반화
`for i,v in tbl do`가 구멍이 있어도 모든 엔트리를 방문하므로 `None`이 필요 없다.
오히려 `None`을 쓰면 소진된 슬롯이 영원히 남아 배열이 끝없이 길어진다. 결론:
**순서가 안 중요하고 슬롯 재사용이 필요한 배열은 `nil` 소진, 순서가 중요한
배열은 실재하는 센티널로 소진**. → **예/아니오**

### R-13 — 단일 타입 파라미터
`Ref<T>(T) -> Ref<T>` 단일 파라미터이고, React식 2파라미터(초기값 타입/최종 타입
분리)는 Luau 솔버에서 미해소 제네릭 변수가 남는 게 확인돼 기각됐다. `Ref(nil)`이
`Ref<nil>`로 좁혀지는 문제는 `Ref<Obj?>(nil)`처럼 명시적 제네릭 적용으로 푼다.
→ **예/아니오**

### R-14 — 반복 재설정 가능
Ref는 one-shot이 아니라 반복 재설정 가능하고, **콜백은 매 `:Set()`마다 다시
불린다**. 소진되는 건 `:Wait()`가 만드는 개별 대기자뿐이다. → **예/아니오**

### R-15 — Ref는 의도적으로 lazy가 아니다
Ref는 `:Compute` 파생을 지원하지 않고 즉시 get/set 값 박스로 남는다 — 과거 Store가
둘을 겸했을 때 lazy 재계산 모델과 즉시 모델이 섞여 좋지 않았던 경험에서 나온
의도적 분리다. → **예/아니오**

### R-16 — retract/process의 분업
`RefLeafHandler`의 retractor가 언바인딩 전담, `process`가 바인딩 전담이라 겹치는
diff 로직이 없다. `nextValue == v`(spurious 재발행)만 둘 다 스킵해 콜백이
`nil`→`inst`로 헛되이 두 번 안 불리게 한다. → **예/아니오**

### R-17 — `process` 쪽엔 `Relate`가 여전히 필요
"spurious 재발행이면 재통지 skip"이라는 dedup은 `process`가 **이전 값**을 알아야
하는데 클로저가 받는 건 *다음* 값이라, 여러 호출을 가로지르는 저장소로만 알 수
있다. → **예/아니오**

### R-18 — `RefLeafHandler.isHandlable`의 `k` 체크
`type(k) == "number" and isRef(v) and not isPreRef(v) and not isPostRef(v)` —
`k` 체크가 빠지면 named 자리로 흘러온 Ref를 잡으려는 FALLBACK 가드가 죽은
코드가 된다. → **예/아니오**

### R-19 — 왜 leaf 바인딩이 배열 전용인가
`Ref`끼리는 **배열 index 순서가 통하므로** "다른 `Ref` 처리를 먼저 해야 하는 순서
의존"을 표현할 수 있게 하려는 것이다(`PreRef`/`PostRef`의 계열 안 순서 보장과 같은
결). 컴포넌트 함수에 `Ref`를 named 파라미터로 넘기는 건 이와 무관하게 얼마든지
가능하다(그건 leaf 바인딩이 아님). → **예/아니오**

### R-20 — 비-nilable `Ref<T>`도 정당
Ref는 "이미 확정된 값을 부작용 없이 읽는" 용도로도 쓰이므로 non-nilable `T`를
계속 지원하고, 언바인딩(`:Set(nil)`)이 실제로 일어나는 Store/Modifier 자리에
놓을 Ref는 **호출자가 직접 `Ref<T?>`로 명시**해야 한다(프레임워크가 자동으로
넓혀주지 않음, 어기면 caller 책임 UB). → **예/아니오**

### R-21 — Destroy와 무관
Ref는 Destroy를 감지하지도 반응하지도 않고, 이미 Destroy된 Frame을 계속 들고
있는 게 정상적으로 가능하며 그 이후 읽고 쓰는 건 UB다. Destroy 시점 정리가
필요하면 `Effect`나 이벤트를 쓰도록 문서가 유도한다 — Ref에 Destroy-awareness를
얹는 건 오버엔지니어링이다. → **예/아니오**

### R-22 — 이중 배치 방지 메커니즘
같은 `Ref`를 두 자리에 놓는 걸 즉시 error로 막고, 메커니즘은 새 `Relate`가 아니라
`bindLifetime`/`unbindLifetime`의 기존 `canBound` 게이트 재사용이다. dedup용
`relate`와는 별개 관심사라 둘 다 계속 필요하다. → **예/아니오**

### R-23 — `phase` 옵션 폐기
`{phase="created"|"mounted"}` 옵션은 없애고, 일반 `Ref`는 배열 안 **위치**가
"그 형제가 마운트되기 전/후"를 그대로 결정한다(각 자식이 자기 서브트리까지 동기
마운트를 끝내야 다음 형제로 넘어가므로 "마지막에 놓기"만으로 "모든 자식 마운트
후"가 공짜로 나옴). → **예/아니오**

### R-24 — `PreRef`가 필요한 진짜 이유
"프로퍼티/이벤트보다도 먼저"는 위치만으론 못 푼다 — Roblox 이벤트 중 일부
(`ChildAdded`/`Changed`류)가 setup 도중 프로퍼티 대입/Parent 세팅의 부작용으로
**동기 발화**할 수 있고, 그때 아직 안 채워진 self-ref를 읽으면 터지기 때문이다.
→ **예/아니오**

### R-25 — `PreRef`는 배열 리터럴 전용
`PreRef`는 Modifier 필드로도 Source/Store 값으로도 들어갈 수 없게 타입으로
차단한다 — 전자는 flatten 후 해시 파트가 되어 보장을 벗어나고 재사용 값에
"이 인스턴스 하나의 construction 훅"을 넣을 이유가 없으며, 후자는 도착 시점이
정의상 최초 스캔보다 나중이라 구조적으로 만족 불가능하기 때문이다.
→ **예/아니오**

### R-26 — 호이스팅의 실제 의미
"호이스팅"은 PreRef를 배열 맨 앞으로 물리적으로 옮기는 게 아니라 **PreRef 전용
선행 루프가 통째로 먼저 끝난 뒤에야 나머지 처리가 시작된다**는 뜻이다.
→ **예/아니오**

### R-27 — 계열 안 순서는 보장
`PreRef`끼리, `PostRef`끼리의 fire 순서는 **배열 index 순서 그대로 보장**한다.
한 번 미보장으로 뒤집었다가 철회했고, 결정적 반례는 `FastQuery(...) -> PreRef`류
조합(앞의 것이 뒤의 것의 전제를 만들어주는 정당한 합성)이었다. 비용도 0이다
(이미 index 순서가 명시적 계약). → **예/아니오**

### R-28 — 소진 센티널은 전용 값
pre-pass가 소진시킨 자리는 `None`이 아니라 전용 센티널
`ProcessedPreRef`/`ProcessedPostRef`(단일 `{}`)로 채운다 — "원래부터 빈
자리(`None`)"와 구별돼야 등록 책임 소재가 분명해지기 때문이다. → **예/아니오**

### R-29 — 소진이 정확성 요건인 이유
pre-pass가 슬롯을 안 지우면 두 번째 패스가 이미 처리된 PreRef를 다시 넘기고
동적 경로 가드 Handler가 엉뚱하게 매치돼 **정상적인 PreRef 사용에도 에러가
터진다** — 소진은 최적화가 아니라 정확성 요건이다. → **예/아니오**

### R-30 — sparse 테이블 위험
사용자가 REPL로 실측한 결과 키가 듬성듬성한 테이블은 순회 순서가 index
오름차순이 전혀 아니었고(해시 버킷 순서), 구멍이 하나만 생겨도 **테이블 전체**가
그 취급으로 넘어가 배열 파트 전체의 순서 보장을 잃을 수 있다. 그래서 pre-pass는
실재하는 센티널로 소진해 구멍을 원천 회피한다. → **예/아니오**

### R-31 — M0에서 검증할 nil-hole
`props.Modifier`/`props.Ref`를 caller가 안 넘겨 생기는 리터럴 nil-hole
(`{nil, ref, child}`)은 caller가 직접 쓰는 raw 리터럴이라 프레임워크가 대신 못
채운다 — M0 스파이크에서 실측하고, 심각하면 "`props.Modifier or Modifier()`처럼
non-nil을 보장하라"는 컨벤션 문서화까지 검토한다. → **예/아니오**

### R-32 — pre-pass의 위치
pre-pass는 `Dispatch.drive` 자신 안에 얹고 새 함수를 만들지 않는다. `flatten`에
얹는 방안은 기각인데, flatten이 `inst`를 모르는 순수 변환이라 fire 지점으로
부적절하기 때문이다. → **예/아니오**

### R-33 — 1회용 재사용 가드
이미 fire된 `PreRef`/`PostRef`를 다시 놓으면 `_fired` 플래그로 즉시 error다.
방치하면 `:Callback`의 "이미 채워져 있으면 즉시 1회 호출" 규칙 때문에 **stale
`.Value`로 조용히 호출**되는 디버깅하기 아주 어려운 버그가 된다. 관용구는
"호출마다 새 `PreRef()`를 만들 것"이다. → **예/아니오**

### R-34 — 취소 개념이 없는 이유
`PreRef`/`PostRef`에 취소 개념이 없는 이유는 "체인에 안 올라가서"가 **아니라**
(지금은 `Processed*Handler`를 통해 올라감), **그 자리 retract가 하드코딩된
no-op이기 때문**이다 — fire는 실제 실행된 부작용이라 되돌릴 상태가 없다.
→ **예/아니오**

### R-35 — v1 `OnCreated` 특수 키 미이식
v1의 `OnCreated` 특수 키는 이식하지 않고 `Ref():Callback(fn)`을 children 배열에
넣는 것으로 완전히 대체된다(여러 개 등록도 자연히 지원). → **예/아니오**

### R-36 — `:Wait()`는 PreRef에도 유효
PreRef의 fire가 항상 동기적이어도 `:Wait()`를 특수화하면 안 된다 — 순수
`coroutine` 컨텍스트에서 호출하면 아직 안 채워져 있어 실제로 yield-resume이
필요한 경우가 생긴다. → **예/아니오**

### R-37 — 두 패스 순서는 안 고친다
"프로퍼티/이벤트가 항상 children/Ref보다 나중"이라는 사실 자체는 고치지 않는다
(그게 필요하면 PreRef를 쓰면 됨). `PostRef`는 두 패스의 순서를 건드리는 게
아니라 그 뒤에 얹히는 것이라 이 결정과 상충하지 않는다. → **예/아니오**

### R-38 — `PostRef`가 보장하는 것과 안 하는 것
`PostRef` fire 시점에 **끝나 있는 것**은 이 인스턴스의 모든 자식과 그 서브트리
전체 + 이 인스턴스의 모든 프로퍼티/이벤트다. **끝나 있지 않은 것**은 이 인스턴스
자신이 부모에 붙는 것(`.Parent`) — 즉 `PostRef`는 자기 **아래**의 완성만 보장하고
자기 **위**(조상 체인)는 아직 없을 수 있으며, "화면에 올라간 시점"이 아니다.
`OnRendered`라는 이름이 `componentDidMount`처럼 읽힐 수 있으므로 이 차이를 명시한다.
→ **예/아니오**

### R-39 — `postRefList`는 로컬 테이블
`postRefList`는 `Relate` 같은 별도 저장소가 아니라 `Dispatch.drive` 호출 하나에만
로컬인 평범한 배열이고, 소진과 `_fired` 세팅은 pre-pass 시점에 `PreRef`와 동일하게
일어나며 실제 콜백 fire 시점만 뒤로 미뤄진다. → **예/아니오**

### R-40 — `PostRef` 대표 유스케이스
`ChildAdded` 같은 이벤트에서 **나중에 들어오는 것만** 처리하고 싶을 때 `PostRef`
콜백이 `mounted = true` 플래그를 세워두고 핸들러가 그걸 먼저 보게 하는 패턴이
대표 유스케이스이고, `PreRef`만으론 표현이 안 되던 자리다. → **예/아니오**

---

## SL. `base/slot-plan.md`

### SL-1 — 패키지 경계와 세 훅
Slot의 재조정 로직(추상 자식 참조 기준)은 `quad-base/Dispatch/Slot.luau`,
실제 트리 조작은 `quad-roblox/Handlers/Slot.luau`다. 이 경계가 담당하는 훅은
mount/unmount 둘이 아니라 **reposition(`Move`/`Swap`)까지 셋**이고, reposition은
**Parent를 건드리지 않는다는 계약만 base가 강제**하며 백엔드가 그걸
`SetSiblingIndex`로 구현할지 no-op으로 둘지는 구현 선택이다. → **예/아니오**

### SL-2 — `InstanceChild` 핸들러가 따로 있는 이유
`k`가 number이고 `v`가 이미 만들어진 Instance인 경우(`Frame { Frame {} }`)는
Slot("뮤터블 배열")과 달리 "정적으로 하나 박아넣는" 더 단순한 경우라 별개
핸들러로 둔다. → **예/아니오**

### SL-3 — `nil`/`None` 요소 금지
Slot의 raw 요소는 오직 실제 마운트 가능한 `T` 값만이고 `nil`도 `None`도 즉시
`error`다 — `updateFn`이 "이번엔 렌더 안 함"을 표현하는 건 `:List` 내부 로직이
해석하고 그 경우 `rawAdd` 자체가 안 불리므로, raw `Add`가 `None`을 허용할 이유가
없다. → **예/아니오**

### SL-4 — 핸들러 계층 값 금지의 근거
`Dispatch/Leaf.luau`가 처리하는 leaf 케이스는 **그 컴포넌트가 지금 만들고 있는
Instance 자기 자신을 가리키는 self-ref 캡처**라 `inst`가 고정돼야 의미가
성립하는데, **Slot은 이미 존재하는 부모에 나중에 독립적으로 붙는 동적 리스트라
그 전제 자체가 없다** — Slot 안의 Ref가 무엇을 가리켜야 하는지 정의가 안 된다.
대체 경로(`slot:Add(Frame { Ref = myRef })`, 여기서 `Frame`은 `Ref`라는 named
파라미터를 받는 **컴포넌트 함수**)가 있어 능력 손실도 없다. → **예/아니오**

### SL-5 — `isMounted` 이중 추적 분리
Slot 컨테이너 자신은 `self._mounted` 필드 하나로, 개별 element는 전역 멤버십
(`elementOwner`)으로 추적한다. `self._mounted`의 트리거 시점은 **Instance
`Parent` 대입 완료가 아니라 `Dispatch.process`가 이 Slot에 대해 실제로 호출된
순간**이다 — 다른 모든 "마운트됨" 판정이 dispatch-process 시점 기준이라 여기만
post-effect 기준이면 일관성이 깨진다. → **예/아니오**

### SL-6 — 재마운트 throw의 범위
"마운트된 Slot의 재마운트는 즉시 throw"는 **다른 `inst`로** 마운트하려 할 때만
해당하고, **같은 `inst`로** 재-emit되는 경우는 no-op이지 throw가 아니다.
→ **예/아니오**

### SL-7 — Named Slot 개념 없음
별도 "Named Slot" 개념 없이 슬롯 바인드 테이블을 store나 파라미터로 그냥 넘기면
ref처럼 바인드된다. → **예/아니오**

### SL-8 — 두-`Relate` 상호 순환 회피
`kSlotMap`(강)과 `slotOwner`(강)를 동시에 두면 Luau에 ephemeron이 없어 실제
누수가 나므로, **실제 GC 앵커는 `bindLifetime`/`unbindLifetime` 하나로만 두고
소유권 레지스트리는 전부 `SetWeak`**(순수 조회용, 아무것도 안 붙잡음)이다.
→ **예/아니오**

### SL-9 — `elementOwner` 통합
top-level Dispatch 경로(`SlotHandler`)와 nested CRUD 경로(`rawAdd` 등)가 **같은**
레지스트리·같은 함수를 쓴다 — 예전엔 별도라 `slot1`을 top-level 바인드한 뒤
`otherSlot:Add(slot1)`이 조용히 통과하는 gap이 있었다. → **예/아니오**

### SL-10 — nested `claimOwner`는 무조건 엄격
nested 경로엔 "재클레임"이 정당한 경우가 하나도 없으므로(reconcile은 항상
`rawUnmount`→`rawAdd` 순서, `rawMove`/`rawSwap`은 클레임 미접촉)
`claimOwner`는 반환값 없이 **성공 아니면 error**다. top-level만
`claimOwnerAt`으로 `(inst, k)`까지 봐서 spurious 재발행을 구분한다.
→ **예/아니오**

### SL-11 — `OWNER_POS`가 top-level 전용인 이유
top-level의 `k`는 props 배열 리터럴 위치라 저작 시점에 고정이고 nested Slot의
`Length`가 변해도 안 바뀐다(물리 배치 변동은 전부 `offset`이 흡수). nested는
`Move`/`Swap`/`Splice`가 인덱스를 실제로 밀지만 엄격 `claimOwner`라 위치를 아예
안 쓰므로 무관하다. → **예/아니오**

### SL-12 — `releaseOwner` 불일치는 error
소유권 불일치가 관측되는 것 자체가 호출측 bookkeeping이 깨졌다는 뜻이므로
조용히 무시하지 않고 즉시 error다. → **예/아니오**

### SL-13 — spurious 사이클에서 no-op 클로저를 심으면 안 됨
체인은 클로저가 early-return하든 말든 **항상 소비**하므로, spurious 사이클에서
no-op을 반환하면 다음 진짜 교체 때 이전 서브트리를 정리할 주체가 사라진다 —
`Frame { slot, slot }` 문제는 클로저를 두 갈래로 쪼개는 방식으로는 못 고치고
`claimOwnerAt`이 그 자리에서 error를 내야 한다. → **예/아니오**

### SL-14 — 소유권 반납을 GC에 맡기면 안 됨
`elementOwner`가 전부 weak여도 **언제 사라지는지가 GC 타이밍**이라 그 전에 같은
element를 다른 곳에 넣으면 "이미 마운트돼 있음" error가 비결정적으로 터진다 —
그래서 `destroySlotTree`도 자기 자식들의 `releaseOwner`를 명시적으로 부른다.
→ **예/아니오**

### SL-15 — CRUD는 인덱스 기준
`Add`만 element를 직접 받고 나머지 CRUD는 전부 **인덱스 기준**이다(호출부가
`slot:Add(Frame{...})`처럼 리턴값을 안 담는 경우가 흔해서). 레퍼런스만 있으면
`IndexOf`로 인덱스를 구한다. → **예/아니오**

### SL-16 — `Add`가 인덱스를 반환하는 이유
`index` 생략 시 호출부가 실제 위치를 모르는데 `Add`는 그 값을 삽입 과정에서 이미
계산하므로 반환은 공짜다. `Move`/`Swap`이 void인 것과 모순이 아닌 이유는
"반환값은 실제로 새로 알게 되는 정보만"이라는 같은 원칙 때문이다. → **예/아니오**

### SL-17 — `Extract(index, newElement?)`
`newElement`를 같이 넘기면 시프트 없이 그 자리만 갈아끼우므로 `Extract` 후 `Add`
(O(n) 시프트 두 번)보다 훨씬 싸다. 별도 `Set`이라는 이름 대신 `Extract`의 확장인
이유는 반환값 의미가 "이전 element"로 정확히 같아서다. → **예/아니오**

### SL-18 — `Splice`는 순수 최적화
`Splice`는 새 능력이 아니라 shift+`recompute`를 1회로 묶는 최적화이고
**비파괴**다. 물리적 detach/reattach를 언제 어떻게 할지는 base가 정하지 않고
백엔드 Handler가 처리한다. → **예/아니오**

### SL-19 — `Splice`가 vararg를 유지하는 이유
`T | {T}`가 여기선 틀린 이유는 "`Slot`의 `T`가 우연히 테이블이라서"가 **아니라**
`Slot<T>`가 base 레벨에선 `T`가 뭔지 전혀 모르는 제네릭이기 때문이다 —
`{item1, item2}`가 "하나의 `T` 값"인지 "펼칠 `{T}` 배열"인지 원천적으로 판별
불가능하다(`Tag`는 `T=string` 고정이라 가능했던 것). → **예/아니오**

### SL-20 — 에러는 전부 fail-fast, clamp 없음
범위 밖 index는 조용히 보정하지 않고 error다(clamp하면 "의도한 위치가 아닌데
성공한" 조용한 버그). `Swap(i, i)`만 no-op이다. `Splice`의 검증은 실제 mutate
전에 전부 먼저 통과해야 한다(반쪽 상태 방지). → **예/아니오**

### SL-21 — 공개 CRUD는 얇은 wrapper
공개 mutate CRUD는 `self._listed` 가드 확인 + `raw*` 위임뿐이고 실제 로직은
`raw*`에 있다(그게 `:List`의 reconcile이 가드 없이 부르는 바로 그 함수).
`Get`/`IndexOf`는 순수 읽기라 가드 대상이 아니다. → **예/아니오**

### SL-22 — `_crudUsed` ↔ `_listed` 대칭
"수동 CRUD를 이미 썼으면 나중에 `:List` 설치 금지"라는 역방향 가드가 있어야
한다 — 없으면 reconcile이 기존 요소의 존재를 모른 채 시작해 Length 이중 계산/
index 꼬임이 난다. 한 Slot은 평생 둘 중 하나로만 고정된다. → **예/아니오**

### SL-23 — `Slot(initial)`은 순수 sugar
`Slot{a,b,c}`는 정확히 `Slot():Add(a):Add(b):Add(c)`이고, `initial ~= nil`이면
**빈 테이블이어도** 즉시 `_crudUsed = true`다(`Slot({})`은 "수동 CRUD를 썼다"는
의도가 이미 커밋된 것). `ipairs`가 첫 nil에서 멈추므로 "중간 nil은 UB, 그 뒤
무시"가 공짜로 성립한다. → **예/아니오**

### SL-24 — `Move`/`Swap`을 추가한 이유
"원시 최소화"보다 실사용 공백이 우선이라 뒤집었다 — (1) `Extract`+`Add`는
실제 Parent 조작이 두 번 일어나 리오더치고 너무 무겁고, (2) `:List` 없이 수동
구성하는 사용자에겐 리오더 수단이 아예 없었다. → **예/아니오**

### SL-25 — `:List`의 파라미터 순서
`(data, updateFn, keyFn?)`이고 `keyFn`이 선택인 이유는 실사용 대부분이 순번을
key로 써도 충분해서다. 생략 시 인덱스를 key로 쓰는 트레이드오프(중간 삽입/삭제
시 캐스케이드 갱신)는 React `key` 생략과 같은 업계 관행이다. → **예/아니오**

### SL-26 — key 제약
`key`의 타입 제약은 없고 (1) 안정성, (2) 유일성만 있으면 된다. 같은 사이클에서
중복 key가 나오면 즉시 `error`다(조용히 넘어가면 두 item이 같은 슬롯을 다툼).
→ **예/아니오**

### SL-27 — 세 가지 "index"를 혼동하지 말 것
`keyFn(item, index)`의 `index`는 **원본 배열 raw 위치**,
`updateFn(item, index, ...)`의 `index`는 **압축된 마운트 위치**(filter로 당겨짐,
순서/레이아웃 계산 전용이지 식별 목적이 아님), `key`는 정체성 값 — 셋 다 다르다.
→ **예/아니오**

### SL-28 — `updateFn`의 시그니처와 파라미터 순서
`updateFn<UD>(item, index, offset, prev, userdata): (T | nil, UD?)`이고, 파라미터
순서를 반환값 순서(`T`류 먼저, `UD`류 나중)와 맞춘 이유는 "값이 안 바뀌면 그대로
반환"이 `return prev, ud`로 자연스럽게 읽히게 하기 위해서다. → **예/아니오**

### SL-29 — 반환값 두 개는 완전히 독립
`result`가 `nil`이라고 `userdata`를 자동으로 지우지 않는다 — 그러면 "인스턴스는
버리되 다시 나타날 때 재사용할 캐시는 남기고 싶다"는 정당한 패턴이 원천
봉쇄되기 때문이다. → **예/아니오**

### SL-30 — 세 갈래를 `updateFn`이 직접 고르는 이유
어느 갈래인지 `updateFn` 자신만 정확히 알기 때문에, 이 판단을 `:List` 내부로
빼면 낭비가 생긴다(재사용 예정인 Source에 미리 `:Set`해뒀다가 결국 다시
그리게 되는 식). 특히 "다시 그림" 갈래에서 이전 `ud`의 Source를 재사용하며
`:Set()`하는 건 아무도 안 구독하는 상태라 무의미한 연산이다. → **예/아니오**

### SL-31 — `LayoutOrder`를 Slot이 대신 안 해주는 이유
(1) 컴포넌트가 자기 프로퍼티로 지정한 `LayoutOrder`를 조용히 덮어쓰는 매직이
되고, (2) `updateFn`이 동적 요소를 전부 다루는 게 원래 설계 의도라 Slot이 일부만
떼어 관리하면 그 원칙이 깨진다 — 둘 다다. Slot 쪽엔 `LayoutOrder`라는 이름 자체가
전혀 등장하지 않는다. → **예/아니오**

### SL-32 — `index`가 raw number인 이유
`:List`가 `indexState`를 대신 관리하면 새 원소가 항상 `Source(0)`으로 시작했다가
다시 `:Set(index)`으로 고쳐 써야 해서 **프로퍼티가 두 번 써진다** — `updateFn`이
`userdata`로 직접 관리하면 처음부터 `Source(index)`로 올바른 값으로 생성돼 이
낭비가 없다. → **예/아니오**

### SL-33 — `candidateIndex`는 look-ahead가 아니다
`candidateIndex = pos + 1`은 직전까지의 생존 개수만으로 계산되므로 이 item 자신의
생존 여부와 무관하게 `updateFn` 호출 **전에** 정확히 알 수 있고, 여전히 단일
forward pass다. `nil` 반환이면 그 값은 버려지고 다음 생존자가 같은 값을 받는다.
→ **예/아니오**

### SL-34 — `pos`와 raw `i`를 분리한 이유
raw `i`를 그대로 `rawAdd` 위치로 쓰면 앞쪽 item이 filter로 빠졌을 때 실제 마운트
개수보다 커져 "범위 밖 index는 clamp 없이 error"에 걸려 그냥 터진다. → **예/아니오**

### SL-35 — 매 사이클 호출로 바꾼 이유
`Visible = false` 토글은 **lazy하지 않다** — 필터링된 항목도 완전히 살아있는
Instance라 애니메이션/이벤트/재계산이 계속 돈다. 200개 중 20개만 보이는데 200개가
전부 도는 게 실제 비용이다. → **예/아니오**

### SL-36 — `:List`가 `Source`를 안 만드는 이유
반응형 바인딩이 필요 없는 단순한 행까지 전부 `Source` 생성 비용을 억지로 지게
되기 때문이고, `userdata`로 권한을 넘기면 원하는 item만 자기 `Source`를 만들 수
있다 — 어느 쪽이 나은지는 케이스별이라 `:List`가 미리 정할 이유가 없다.
→ **예/아니오**

### SL-37 — `item`을 `T?`로 바꿔 정리 훅을 주는 안은 기각
그 훅은 `data`에서 key가 빠지는 정상 경로에서만 발화하고 **부모 Instance 자체가
Destroy되는 가장 흔한 소멸 경로**에선 전혀 안 불린다 — 절반만 동작하는 정리
메커니즘은 없는 것보다 나쁘다(사용자가 "정리가 보장된다"고 오해하고 `Subscribe`류를
넣었다가 조용히 새는 게 더 위험). → **예/아니오**

### SL-38 — `userdata` 제약
`userdata`에는 **GC만으로 자연히 정리되는 값만** 담아야 하고,
`:Subscribe()`한 Observer/Effect처럼 명시적 `:Unsubscribe()`가 필요한 값을 담는
건 UB다. → **예/아니오**

### SL-39 — 구독 시점은 마운트 시점
`:List()`는 설정만 저장하고, 실제 `data:Observer(fn)` 구독과 최초 `reconcile`은
Slot이 마운트되는 순간 `activateList`가 수행한다(그 시점에야 `inst`를 알아
`bindLifetime`을 걸 수 있으므로). `:List()`가 마운트보다 늦게 불리면
`self._mounted`를 확인해 즉시 활성화한다. → **예/아니오**

### SL-40 — 소멸 루프가 `keyIndex`를 순회하는 이유
`userdata`가 `result == nil`이어도 살아남을 수 있어서, 필터 탈락 상태인 key가
`data`에서 사라지면 `pairs(mounted)`로는 안 잡혀 `userdata`가 샌다 — 직전 사이클에
실제로 존재했던 **전체** key 집합을 순회해야 한다. → **예/아니오**

### SL-41 — `mounted`/`userdata`/`keyIndex`는 클로저 업밸류
별도 전역 weak table이 필요 없고, `inst`/`self`가 죽으면 클로저도 같이 GC된다.
→ **예/아니오**

### SL-42 — reconcile이 공개 `Extract` 대신 `rawUnmount`를 쓰는 이유
파괴 여부가 아니라, reconcile이 이미 `mounted` 맵으로 element를 추적 중이라
"제거한 element를 호출자에게 반환"하는 계약이 불필요하고 공개 CRUD의 가드/에러
체크도 중복이기 때문이다. → **예/아니오**

### SL-43 — `nil` 리턴은 파괴가 기본
`updateFn`이 새 값을 반환하면 밀려난 `prev`는 **언마운트만**, `nil`/`None`이면
**파괴**, `Detach`면 **언마운트 + 재사용 대기**, 키가 데이터에서 사라지면
**파괴**다. "자동 경로는 언마운트, 명시적으로 지우라고 한 것만 파괴"라는 일반
규칙에서 **`:List`의 `nil` 반환 자체가 "지우라고 한 것"으로 센다**.
→ **예/아니오**

### SL-44 — `Detach`의 보존 주체
`Detach`로 홀드되는 요소를 붙잡아 GC를 막는 건 reconcile이 아니라 **`userdata`
안에 사용자가 담은 참조**(`{ old = prev }`)이고, 다음 사이클에 그 `userdata`를
다시 받아 `old`를 꺼내 반환하면 재마운트된다. "언제 진짜 버릴지"는 `updateFn`이
결정한다. → **예/아니오**

### SL-45 — ⚠️ 미해결 항목 확인: `Detach` 홀드 중 키 소멸
키가 데이터에서 사라지면 소멸 루프가 `mounted[key]`/`userdata[key]`를 둘 다
지우는데 `Detach` 홀드 중이던 요소는 `mounted[key]`가 이미 `nil`이라 파괴 대상이
아니라서 **파괴도 반환도 안 되고 참조만 끊긴다** — 이건 같은 절의 표("키가
사라지면 파괴")와 어긋나므로 (a) 소멸 루프가 `userdata.old`도 확인해 파괴 /
(b) 지금처럼 GC에 맡기되 문서를 고침 / (c) `updateFn`을 한 번 더 불러 처분을 물음
중 하나를 **M6 착수 전에 정해야 하고, 결정 전이므로 구현 금지**다. → **예/아니오**

### SL-46 — `Detach` 이름과 위치
이름이 `Detach`인 근거는 (1) `Extract`(호출자가 직접 부르는 명령형 추출, 소유권을
통째로 넘김)와 자연스럽게 구분됨, (2) `nil`(파괴)과의 대비가 직접적임 — 둘 다다.
공개 표면은 `Slot.Detach`가 아니라 **`None`과 같은 패키지 최상위 export**이고
(sentinel 하나 때문에 callable-table 구조를 들이는 건 과함), 정의는 Slot 관련
파일 옆에 두고 `init.luau`에서 재노출한다. → **예/아니오**

### SL-47 — 초기 실행은 게이팅과 무관
`data:Observer(fn)`의 "등록 즉시 1회 실행"은 `bindLifetime` **이전**에
일어나므로 그 시점 `canExecute`는 거짓이지만, 애초에 최초 실행은 게이팅 대상이
아니라 상관없다. `bindLifetime`은 그 직후에 걸려 **이후의** 재실행만 게이팅한다.
→ **예/아니오**

### SL-48 — Destroy 이후가 공짜로 해결되는 이유
`inst`가 Destroy되면 gcconn이 죽어 `canExecute`가 거짓이 되고, `gchold`가
`Relate(inst)` 아래 있어 그 안에 붙잡힌 Observer/클로저(`mounted`/`userdata`/
`keyIndex` 포함)가 전부 GC 대상이 된다 — 명시적으로 구독을 끊는 새 코드가 필요
없다. → **예/아니오**

### SL-49 — `:List`가 자유 함수도 새 타입도 아닌 이유
자유 함수는 "`Type(args)` 팩토리 이름 = 반환 타입" 컨벤션을 깨고, 새 서브타입은
Slot 위에 **새 공개 메소드를 하나도 안 얹으므로** 별도 타입일 이유가 없다.
Fusion의 `ForPairs`/`ForKeys`/`ForValues` 3분할도 이 재구성으로 단일 `:List`로
통합 확정됐다. → **예/아니오**

### SL-50 — `Slot.Length`의 정의
`Length`는 CRUD/`:List` 여부와 무관하게 항상 노출되고, Slot-in-Slot 이후로는
정확히 **"요소별 기여도의 합"**(plain=1, nested Slot=그 `.Length`)이다. 두
용도(사용자 관측 + `Dispatch.setLength`가 읽는 값)를 하나의 State가 겸한다.
→ **예/아니오**

### SL-51 — `:Single`은 `:List` 위의 순수 sugar
`:Single`은 `:List`를 0/1개짜리 배열로 감싸는 sugar이고, **key를 고정값으로
두는 게 핵심**이다(값 자체를 key로 쓰면 매번 다른 item 취급돼 파괴+재생성이
강제됨). `index`를 안 넘기는 이유는 형제가 자기 하나뿐이라 항상 상수라서다.
→ **예/아니오**

### SL-52 — Slot-in-Slot의 진짜 동기
카테고리 헤더+아이템 그룹은 구체적 동기일 뿐이고, 더 근본적인 이유는
**컴포넌트 결합의 균일성** — `SomeComponent(props)`가 Instance를 리턴하든
Slot(멀티루트)을 리턴하든 호출부가 `outerSlot:Add(result)`를 분기 없이 부를 수
있어야 한다는 것이다. → **예/아니오**

### SL-53 — `attachSlot`의 호출 순서
올바른 순서는 **`setOffsetSource`(즉시 계산) → (Slot이면) `activateList` →
`setLength` → 물리 마운트(flush 루프)**다. `setOffsetSource`가 먼저여야 하는
이유는 length를 알게 되는 시점이 각 요소 생성 이후라, offset이 먼저 안 돼 있으면
offset 전파가 한 번 더 일어나기 때문이다. → **예/아니오**

### SL-54 — `setLength`에 넘기는 건 State 객체 자신
`Dispatch.setLength(ownerKey, position, slot.Length)`가 넘기는 건 값이 아니라
**State 객체 자신**이라, 등록 시점에 값이 아직 안 굳어 있어도 무해하다(부모가
구독해뒀다가 나중에 반응). → **예/아니오**

### SL-55 — `_mounted`를 `activateList` 뒤로 미루는 이유
`_mounted`가 먼저 세팅돼 있으면 reconcile의 `rawAdd`가 매 항목마다 즉시 물리
마운트 + `setLength`를 태워 (a) 아직 Blocker가 없어 매 항목마다 `recompute`가
돌고(`RC-3`), (b) nested Slot 항목은 `attachSlot`이 두 번 불린다(`RC-4`).
미루면 실제 마운트 지점이 **flush 루프 단 하나로 통일**되어 `:List`든 수동
CRUD든 구분할 필요가 없어진다. → **예/아니오**

### SL-56 — 중첩마다 별도 Blocker
`attachSlot`의 flush 루프는 그 Slot 자신의 owner 키로 **새 Blocker**를 만들고
부모 Blocker를 절대 공유하지 않는다 — 공유하면 자식의 `OffWithoutEmit()`이
부모가 아직 배치 중인데 꺼버려 부모의 나머지 등록이 게이팅을 잃는다.
→ **예/아니오**

### SL-57 — 런타임 단건 `Add`는 게이팅 불필요
이미 마운트된 Slot에 하나씩 `Add`하는 경로는 그 Slot의 Blocker가 이미 꺼져
있고, 새 position보다 앞선 모든 position이 안정적으로 채워져 있어 `nil` 자리가
생길 여지가 없다. → **예/아니오**

### SL-58 — 배치 밖 단독 재마운트의 엣지 케이스
`state<Slot>` 값이 steady state에서 교체될 때는 부모 Blocker가 이미 꺼져 있어
부모의 `gatedRecompute`가 아직 flush 안 끝난 `slot.Length`로 한 번 계산할 수
있지만, flush가 끝나면 자기 교정된다 — 크래시도 영구 오류도 아닌 한 프레임짜리
낭비라 **손대지 않기로** 했다. → **예/아니오**

### SL-59 — 재귀적 `Clear()` 금지
죽는 서브트리 내부에서 요소 수만큼 shift+recompute가 반복되므로, 순수 파괴 walk만
하고 outer 쪽 recompute는 자기 위치 하나에 대해 한 번만 돈다. → **예/아니오**

### SL-60 — `unmountSlotTree`와 `destroySlotTree`의 차이
`unmountSlotTree`는 `destroySlotTree`와 **딱 하나만 다르다: 실제로 안 죽인다** —
물리 트리에서만 떼어내고 `_elements`/자식 소유권은 통째로 보존한다(그래서 나중에
다른 곳에 다시 마운트 가능 = 포탈). 자식들의 `releaseOwner`를 **안 부르는** 게
핵심 차이다. → **예/아니오**

### SL-61 — `spliceArraysDown`이 밀어야 하는 배열
`_elements`/`lengthList`/`sourceList`뿐 아니라 **`bk.observers`도 같이 당겨야
하고, `bk.N`도 하나 줄여야 한다** — `bk.observers[i]`도 position-indexed 배열이라
안 당기면 이후 그 position이 옛 이웃의 observer를 가리킨다. → **예/아니오**

### SL-62 — nested Slot의 `unbindLifetime`이 필요한 이유
죽는 건 nested Slot 하나고 물리 target(공유 부모)은 계속 살아있으니 GC가 자동으로
안 치워준다 — 명시적으로 안 풀면 카테고리가 자주 추가/삭제되는 UI에서 조용히
새는 옵저버가 쌓인다. → **예/아니오**

### SL-63 — Length 변경은 offset 변경으로만 전파
`recompute`가 `:Set()`하는 대상은 (a) 뒤 형제들의 offset, (b) owner가 Slot이면 그
`.Length` 둘뿐이고, Length 값 자체는 읽히기만 한다 — 새 전파 채널이 아니다.
→ **예/아니오**

### SL-64 — "위치 이전 기억"은 base 책임 아님
Slot-in-Slot은 순수 숫자 계산만 재귀하고 backend 종속적 위치 정보는 전혀 안
다룬다 — 필요한 backend가 자기 `Relate`로 저장할 몫이다. → **예/아니오**

### SL-65 — nested Slot을 `<div>` 중첩으로 매핑하는 안 기각
React Fragment와 정확히 같은 이유로 Slot은 **의도적으로 wrapper 없는** 그룹핑
도구이고, 논리 중첩을 물리 중첩으로 매핑하면 flexbox/grid에서 직계 형제를
기대하는 CSS가 깨진다 — 어느 backend든 nested Slot의 리프는 항상 flat하게 같은
물리 부모의 자식이어야 한다. → **예/아니오**

### SL-66 — 반응형 raw 요소는 순수 `:Single` sugar
`isState(element)`면 그 자리에 내부적으로 `Slot():Single(element)`를 대신
삽입한다. 최초안(position-keyed StoreBind 구독)이 기각된 이유는 (1) `State<T?>`를
지원하려면 `_elements`에 `None`을 다시 끌어들이게 되고, (2) Length 계산이 예외를
갖게 되며, (3) `Move`/`Swap`이 인덱스-구독 동기화 부담을 새로 만들기 때문이다.
→ **예/아니오**

### SL-67 — raw nil/None 금지의 범위 축소
"요소 타입 제약"의 nil/None 금지는 **State/Source로 감싸지 않은 raw 값에만**
적용된다 — `:Single`이 이미 `nil`을 "빈 리스트"로 흡수하므로 `State<T?>`는 특별
취급 없이 그냥 된다. → **예/아니오**

### SL-68 — coarse swap은 별도 메커니즘이 아님
`updateFn = identity`가 `prev`/`userdata`를 무시해 "다시 그림" 갈래만 계속 타는
특수 케이스일 뿐, 코드 레벨의 별도 경로가 아니다. → **예/아니오**

### SL-69 — `State<Slot>` 교체가 언마운트인 근거
(1) `state<Frame>`가 이미 그렇게 동작하고(quad가 이전 Frame을 Destroy해주지
않음), (2) 비파괴 추출은 `Extract`/`Splice`로 이미 지원되는 개념이며, (3) 뽑아낸
뒤엔 소유권이 반납돼 더 이상 leaf의 소유가 아니다 — 셋 다다. → **예/아니오**

### SL-70 — `Set` 전에 직접 `Destroy()`는 UB
순서는 항상 **`Set`(언마운트) → 그 다음 정리**이고, 먼저 `Destroy()`하면 quad가
그 값이 죽은 줄 모른 채 언마운트 경로를 탄다. → **예/아니오**

### SL-71 — `dispose`는 떼어내주지 않는다
`dispose(value)`는 대상이 아직 어느 트리에 살아있길 요구되고 있으면 **파괴를
거부하고 즉시 error**다(떼어내는 건 `Set`의 몫). 근거는 "엔진은 조용히 넘어가도
quad의 `_elements`/`lengthList`/`elementOwner`는 그 순간 어긋난다"는 것이고,
판정에 필요한 정보(`elementOwner`)는 이미 있어 새 부기가 필요 없다.
→ **예/아니오**

### SL-72 — `dispose` 범위에서 Observer/Effect 제외
Observer/Effect는 생존이 gcconn만으로 판정되고 "죽는 순간 트리 부기가 어긋나는"
문제가 원천적으로 없어 dispose 대상이 아니다 — 조기에 끊으려면
`unbindLifetime`으로 충분하다. → **예/아니오**

### SL-73 — `disposeInst`는 주입 op
`dispose`가 `isSlot`이 아닌 값을 받으면 base가 시그니처만 소유하는
`disposeInst(inst)`로 위임하고, quad-roblox가 `inst:Destroy()`로 구현한다.
`free()`는 GC-native 맥락과 안 맞아, `Destroy`는 엔진 메소드와 동명이라 각각
기각됐다. → **예/아니오**

### SL-74 — ⚠️ 미해결 항목 확인: `SetAndDispose`
`Get()` → `Set(new)` → 옛 값 `dispose`라는 3단계가 불편하다는 지적에서 나온
`source:Apply(SetAndDispose(new))` 또는 `source:SetAndDispose(new)` 후보가 열려
있고, 전자는 `Apply`가 `State`가 아니라 **`Source`를 넘겨주는 함수**여야 하므로
`state:Apply` 시그니처에 영향이 갈 수 있어 **M3 착수 전 방향만이라도** 정해야
한다. → **예/아니오**

### SL-75 — 해제 = 0/`None` 재등록
별도 unregister API는 필요 없고 `setOffsetSource(None)` → `setLength(0)` 재등록이
곧 해제다. 순서가 중요한 이유는 값이 틀려져서가 아니라 **죽는 중인 Source에
쓰기가 날아가기 때문**이고, 해제 시 `slot.Offset = nil`도 같이 해야 stale한
Offset을 공개하지 않는다. → **예/아니오**

### SL-76 — `recompute`는 `nil`도 관대하게 skip
정상 상태에선 항상 `None`이 계약이지만 해제/재마운트 전이 구간에서 `nil`이
관측돼도 크래시 대신 skip이어야 한다 — 계약 완화가 아니라 순수 방어이고 등록
쪽은 여전히 `None`을 쓸 의무가 있다. → **예/아니오**

### SL-77 — 포탈은 기본 동작
포탈은 opt-in 표식도 새 API도 없는 **언마운트 결정의 자연스러운 귀결**이다.
→ **예/아니오**

### SL-78 — nested-Slot 결과의 Length만큼 건너뛰기
`updateFn`이 nested Slot을 반환하면 그 아이템은 물리적으로 `result.Length`개를
차지하므로 `pos`가 그만큼 건너뛴다. 남는 캐비엇은 `index`가 raw 스냅샷이라 nested
Slot의 Length가 outer reconcile 없이 나중에 바뀌면 이후 형제들의 `index`가 갱신
안 된다는 것이고, 이건 "`index`는 raw number" 설계의 당연한 연장이라 실시간
정확성이 필요하면 `updateFn`이 직접 처리해야 한다. → **예/아니오**

---

## T. `base/tag-plan.md`

### T-1 — 구 모델 폐기 근거
`[Tag "Name"] = boolean`(태그 하나당 해시 키 하나)은 상호배타 스타일 상태를
표현하려면 이름 개수만큼 키를 각각 갱신해야 하고 스타일 조합도 구조적으로 안
돼서 array-part 값 객체로 재설계됐다. → **예/아니오**

### T-2 — 값 모양
`Tag(name1, ...)` 생성자는 vararg이고 `:Added`/`:Removed`는 **`string | {string}`**
이다. 후자가 vararg가 아닌 이유는 `table.unpack(t)`가 인자 목록 **tail 위치일
때만** 펼쳐져서 여러 동적 이름 테이블을 한 호출로 합치는 게 vararg로는 애초에
표현 불가능하기 때문이다. 생성자가 vararg를 유지하는 건 정적 리터럴 호출
자리라 동적 조립 문제가 없어서다. → **예/아니오**

### T-3 — `-ed` 어미의 이유
`Add`/`Remove`로 쓰면 뮤테이션 API처럼 보이는데 실제로는 항상 clone 후
반환이기 때문이다. → **예/아니오**

### T-4 — `Merged`와 `Overridden`의 구분
`Tag.Merged`는 무손실 합집합이고 `Modifier.Overridden`은 필드 단위 덮어쓰기
(손실 있음)라 서로 다른 연산이므로 이름도 다르다. `Tag`엔 `Overridden`이
필요 없다(합집합이라 애초에 "충돌" 개념이 없음). → **예/아니오**

### T-5 — 여러 Tag를 나란히 놓아도 됨
`Frame { Tag("a"), Tag("b") }`처럼 정적으로 여러 개 놓아도 각자 독립적으로
자기 태그만 추가하므로 `Merged` 없이도 된다 — `Merged`/`Added`/`Removed`는
"하나의 Tag 값을 프로그래밍적으로 조립"하는 용도다. → **예/아니오**

### T-6 — 동적 토글엔 `None` 불필요
함수 리턴값으로 흘러가는 동적 토글은 그냥 `nil`을 리턴하면 되고, `None`이
필요한 건 **정적 리터럴**에서 조건부로 넣고 빼는 nil-hole 케이스뿐이다(그건
Tag만의 특수 규칙이 아니라 일반 array-part 관용구). → **예/아니오**

### T-7 — holders는 위치(`k`) 기준
`tagNameMap`의 holders를 `Tag` 객체 identity가 아니라 **위치(`k`)**로 키잉하는
이유는, Tag가 immutable이라 `local SELECTED = Tag("selected")`를 모듈 상수로
재사용하는 게 자연스러운 관례인데 객체 identity로 추적하면 두 위치가 단일
엔트리를 공유해 한쪽만 retract돼도 `removeTag`가 잘못 불리기 때문이다.
→ **예/아니오**

### T-8 — `kTagMap`은 불필요해짐
"이 위치에 걸려 있던 Tag가 뭐였는가"는 `process`가 반환하는 클로저가 `v`를
upvalue로 직접 캡처하므로 별도 저장소가 필요 없다. `tagNameMap`은 여러 위치를
가로지르는 누적 상태라 여전히 `Relate`가 맞다. → **예/아니오**

### T-9 — `addTag`는 process, `removeTag`는 클로저
서로 겹치는 diff 계산이 없고, 클로저는 이전 Tag가 걸었던 이름 중 **새 값이 더
이상 안 거는 것만** 소유 목록에서 빼고 그 결과 빈 이름들을 모아 `removeTag`를
**한 번** 호출한다. → **예/아니오**

### T-10 — 생존 이름은 홀더 등록을 유지
생존 이름은 홀더를 일단 빼고 `removeTag`만 skip하는 게 **아니라 등록 자체를
유지**해야 한다 — 빼면 곧 이어지는 `process`가 빈 holders를 보고 `addTag`를
다시 부른다(엔진이 멱등이라 안 보였을 뿐 설계 목표와 어긋남). → **예/아니오**

### T-11 — `v == nextValue`면 즉시 return
Tag는 immutable이라 객체가 안 바뀌면 이름 집합도 절대 안 바뀌므로 holders 순회
자체가 불필요한 순수 최적화다. → **예/아니오**

### T-12 — 깜빡임 방지가 깊은 체인에서도 성립
하강 diff에서는 각 레벨이 자기 재프로세스에서 자기 값을 받으므로 인덱스가 얼마나
깊든 TagHandler는 진짜 `Tag` 객체를 받는다(옛 모델에선 `State<State<Tag>>`의
바깥이 재발행하면 `nil`을 받아 전량 제거 후 재추가했음). → **예/아니오**

### T-13 — 겹치는 이름의 합집합 시맨틱
`Frame { Tag("a"), Tag("a","b") }`에서 `tagNameMap["a"]`는 양쪽 위치를 모두 담는
공유 집합이라 한쪽이 놓아도 다른 쪽이 남아있으면 `removeTag`가 안 불린다 —
웹 `className`처럼 손실 없는 합집합이다. → **예/아니오**

### T-14 — 등록되는 건 `TagFallbackHandler`
`TagHandler`는 참조 카운트 알고리즘 구현일 뿐 `.priority`가 없고, 실제로
`HANDLER_PRIORITY_FALLBACK`에 꽂히는 건 그걸 감싸는 얇은 래퍼
`TagFallbackHandler`이며 **등록 주체는 quad-base 자신**이다. → **예/아니오**

### T-15 — 알고리즘은 base, op만 주입
`TagHandler`가 quad-base로 옮겨간 이유는 엔진 종속이 `AddTag`/`RemoveTag` 두
줄뿐이고 참조 카운트는 순수 부기라, 그대로 두면 같은 알고리즘을 백엔드마다
재구현하게 되기 때문이다. → **예/아니오**

---

## AT. `base/attribute-plan.md`

### AT-1 — Attribute는 프리미티브 전용
Roblox Attribute는 제한된 프리미티브 집합만 지원하므로 커스텀/복합 데이터는
Ref 쪽으로 빠지는 게 맞고, Attribute는 프리미티브 전용으로 남긴다. 지금은
Instance 참조 타입도 지원해서 `ObjectValue` 없이도 Ref 용도로 쓸 수 있다.
→ **예/아니오**

### AT-2 — 두 표기 다 채택
`AttributeKey<T>(name)`(제네릭, 기본/범용 경로)과 `BooleanAttribute(name)`류
정적 패밀리(빈도 높은 몇 개만 지름길) **둘 다** 채택하고, 내부 구현은 완전히
동일해 런타임 동작 차이가 없다. → **예/아니오**

### AT-3 — ⚠️ 실측 필요 항목 확인
`[AttributeKey<boolean> "name"] = value`처럼 특수 키 제네릭으로 `=` 뒤 값의
타입까지 실제로 좁혀지는지는 **미검증**이고, 안 되더라도 런타임엔 영향이 없으며
그 경우 정적 패밀리 쪽이 유일하게 믿을 수 있는 정적 체크 경로가 된다.
→ **예/아니오**

### AT-4 — 이름별 weak 캐시
`AttributeKey(name)`은 이름별 weak 캐시(값만 weak)를 거쳐 같은 객체를 반환하고,
**캐시 키는 순수 문자열 `name`뿐이라 제네릭 파라미터 `T`는 안 쓴다** —
`AttributeKey<boolean>("X")`와 `BooleanAttribute("X")`가 실제로 완전히 같은
런타임 객체다. → **예/아니오**

### AT-5 — `Tag`엔 이 기법이 안 맞는 이유
`Tag(...)`는 내부 이름 목록 자체가 매번 달라지는 게 핵심이라 "캐시할 안정적인
키"가 애초에 없다. → **예/아니오**

### AT-6 — `process`는 무조건 `setAttribute`
`v`가 뭐든(실제 값이든 `nil`이든) 무조건 그대로 호출하고, Attribute는 주입 op의
계약 자체가 `nil` = "지운다"라서 **`None`의 가장 깔끔한 사례**다(UICorner처럼
만들어둔 자식을 수동으로 지우는 로직조차 필요 없음). → **예/아니오**

### AT-7 — 클로저는 `setAttribute`를 절대 안 부름
attribute를 지우는 유일한 경로는 `process(inst,k,nil,index)`뿐이고, 클로저는
이름 claim 반납만 한다(엔진 부작용 0). 옛 안("이름이 사라질 때만 클로저가
지움")이 기각된 이유는 (1) 클로저에 관측 가능한 부작용이 생겨 일반 규칙과
어긋나고, (2) 그룹이 survivor에 재위임할 때 `a→nil→b` 깜빡임이 생길 수 있어서다.
→ **예/아니오**

### AT-8 — Dispatch가 대신 못 잡는 이유
하강 diff에선 그룹 A가 등록한 인덱스 1의 핸들러도 `StoreBind`, 그룹 B가 넘기는
값도 `StoreBind`라 "같은 핸들러"로 판정돼 조용히 갈아타고, 나중에 A의 클로저가
B의 바인딩을 대신 철거하는 교차 오염까지 난다. → **예/아니오**

### AT-9 — 해법은 두 조각
(1) 그룹은 이름마다 **자기 전용 키**(비공개 `GetKey`)로 위임해 서로 다른 체인을
갖게 하고, (2) 이름 자체의 소유권은 `AttributeKeyHandler`의 **이름 claim**이
판정해 다른 키 객체가 들어오면 즉시 error다. → **예/아니오**

### AT-10 — 대안 (a)가 부족한 이유
"그룹 안에 이름별 claimant `Relate`"는 그룹↔그룹은 잡지만 **그룹↔직접 쓰기를
못 잡는다** — 직접 쓰기는 그룹 코드를 아예 안 지나가고, 두 경로가 만나는 유일한
지점인 `AttributeKeyHandler`에선 공개 키를 쓰는 한 `k`가 같은 객체라 소유자를
구분할 방법이 원천적으로 없기 때문이다. → **예/아니오**

### AT-11 — ⚠️ 열린 항목 확인: `Frame { a, a }`
같은 그룹 객체를 두 위치에 놓으면 `groupKey(v, name)`이 그룹 객체별·이름별
메모이즈라 **완전히 같은 키**가 나와 claim 체크를 통과하고, 두 위치가 하나의
체인을 공유하다가 `k=1` retract가 `k=2`의 바인딩까지 철거한다. `Ref`처럼
`bindLifetime`으로 막을 수 **없는** 이유는 그룹 Attribute 값은 여러 곳에서 쓸 수
있어야 하기 때문이고, 그래서 **위치별 claim 레지스트리를 하나 더** 두기로 방향은
확정됐으나 **키를 무엇으로 할지와 `nameClaims`와의 공존은 미정**이다.
→ **예/아니오**

### AT-12 — `Tag`가 다른 이유
`Tag`는 자원이 "이름 집합"이라 겹쳐도 합집합이면 되지만, 그룹 `Attribute`는
자원이 **값 하나**라 겹침이 곧 충돌이다. → **예/아니오**

### AT-13 — 해제→재클레임 순서는 Dispatch가 보장
같은 핸들러 재프로세스는 `retractor(v)` → `process`, 핸들러가 바뀌면
`retractFrom` → `process`라 어느 경로든 옛 claim 반납이 먼저다. → **예/아니오**

### AT-14 — `GetKey`는 공개 API가 아님
반출하면 사용자가 그 키를 다른 자리에 놓아 같은 키가 두 자리에서 수렴할 수 있고
그건 claim으로도 안 잡힌다. 비공개면 이 경로 자체가 없고, base의 공개 표면에
아무것도 안 늘어난다. → **예/아니오**

### AT-15 — 기각된 두 대안
`[Attribute] = Store {...}`(해시파트 단일 슬롯)는 인스턴스당 슬롯이 하나뿐이라
Store 여러 개를 동시에 반영할 방법이 없어서, `Attribute`를 Store의
서브타입으로 두는 안은 "Store 안에 Store"를 실제로 만들어내서 각각 기각됐다.
→ **예/아니오**

### AT-16 — `Merged`/`Overridden` 둘 다 제공
이름 겹침 정책은 둘 중 하나를 고르는 문제가 아니었고, `Merged`는 즉시 error,
`Overridden`은 조용히 뒤가 이긴다. **이 이름 쌍의 의미가 코퍼스 전체에서
재정렬된다** — 다른 곳에선 "연산의 종류"를 가르지만 `Attribute`에선 "충돌 시
정책"을 가른다. → **예/아니오**

### AT-17 — 그룹은 단일 키 경로에 재귀 위임
그룹 Handler는 자기만의 set/구독 로직을 새로 만들지 않고 각 필드를 기존
`AttributeKey` 경로에 재귀 위임한다(`None`/store-bind를 100% 재사용).
`Dispatch.process(inst, key, source, 1)` — 다른 키로 위임이라 항상 인덱스 1이다.
→ **예/아니오**

### AT-18 — 배열 위치 `k`와 재귀 깊이 `index`는 다른 것
그룹의 `process`도 다른 핸들러와 똑같은 4-인자 계약이고, `k`는 그룹 값이 놓인
array-part 위치, `index`는 그 체인 안 재귀 깊이다(예전에 배열 위치를 `index`로
부르며 3-인자로 적혀 있던 게 코퍼스에서 유일하게 계약과 안 맞는 핸들러였다).
→ **예/아니오**

### AT-19 — 부분 실패는 롤백하지 않음
순회 도중 충돌 error가 나면 이미 등록된 이름들은 즉시 회수되지 않지만, 피해가
그 인스턴스 수명으로 한정되고(weak) 같은 자리가 다시 프로세스되면 같은 error로
다시 멈추는 **반복 재현되는 시끄러운 실패**라 별도 롤백 장치를 넣지 않는다.
→ **예/아니오**

### AT-20 — 생존 이름도 매 사이클 철거→재등록
클로저는 인자(새 값)를 안 보고 자기가 등록한 키 전부를 균일하게 철거하며, 비용은
`StoreBind` 재구독과 같은 값 `setAttribute` 한 번뿐이다. 그룹 전용 체인이 된
지금은 최적화도 가능하지만 옛 이름 집합을 또 들고 있어야 해 부품이 늘어나므로
**기본은 균일 철거 유지**다. → **예/아니오**

### AT-21 — 값 비교를 안 하는 이유
`:Get()`으로 old/new를 비교하는 건 State 계약("캐시 비교 금지")과 어긋나고,
`source`가 State면 `StoreBind`가 언랩+구독까지 다 해주므로 비교할 이유가 없다.
→ **예/아니오**

### AT-22 — 자동 unset 안 함
그룹에서 이름이 조용히 빠지든 바인딩이 통째로 사라지든 프레임워크가
`setAttribute(nil)`을 대신 불러주지 않고 값이 그대로 남는 게 정상이다. 근거는
(1) 두 경우가 서로 다른 규칙이 되면 오히려 모호해지고, (2) 이름 소유 코드가
명확히 갈리는 설계라 그 코드가 지우는 게 맞으며, (3) 정말 필요하면 `:Apply`
opt-in 유틸로 나중에 추가하면 된다 — 셋 다다. → **예/아니오**

### AT-23 — 값은 안 지워도 구독은 반드시 끊음
그룹이 더 이상 관리 안 하는 이름의 체인을 두면 `StoreBind` 구독이 영원히 남아
원본 Source가 바뀔 때마다 계속 `setAttribute`를 쏘는 실제 누수가 된다 —
그래서 클로저가 `retractFrom`은 부르되 `Dispatch.process`는 절대 안 부른다.
→ **예/아니오**

### AT-24 — 필드 하나만 바뀌면 그룹 로직이 안 돔
`storeA.foo:Set(v)`는 이미 걸린 단일 키의 store-bind 구독이 바로 처리하므로 그룹
재진입이 없고, 키 집합이 안 바뀌는 한 그룹 로직 자체가 안 돈다. → **예/아니오**

### AT-25 — 레이어드 Store 기각과 안 부딪힘
기각된 건 **읽는 시점의 암묵적 부모 체인 폴백**이고, `Attribute.Merged`는 작성
시점에 명시적으로 한 번 평탄한 자기 맵으로 모으는 것이라 런타임 폴백 체인이
없다. → **예/아니오**

### AT-26 — 타입 패밀리만 갈리는 이유
string/number/boolean은 어느 백엔드에나 있어 base, `Color3`/`UDim2`/`Instance`류는
엔진 고유 어휘라 백엔드다. "이 값이 표현 가능한가" 검증도 base가 아니라 주입된
`setAttribute`의 몫이고 base는 값을 그대로 흘려보낸다. → **예/아니오**

---

## TW. `base/tween-plan.md`

### TW-1 — 트윈을 반응 그래프 밖에 두는 근거
Fusion은 Tween을 1급 반응 노드로 만든 대가로 (1) 매 프레임 틱하는 외부 클럭을
그래프에 통합해야 했고, (2) eager 노드가 무효화/전파 로직과 경쟁하게 됐고,
(3) 트윈-입력 간 별도 교차 lifetime 체크가 필요해졌다 — quad는 값-레벨 래퍼로
빼서 이 셋을 전부 피하고, 대가로 트윈된 값이 Computed의 추가 입력으로 합성되지
못하는 것만 감수한다. → **예/아니오**

### TW-2 — 구 모델이 답 못한 것
"`v`가 Store인 아무 `k`나 잡는 최상위 핸들러" 모델은 "애니메이션 없는 일반
반응형 바인딩도 결국 이름이 Tween인 파일을 거쳐가는가"에 답을 못 했고, 새
모델은 State 언랩(`StoreBind`)과 "이 값이 트윈 대상인가"(PropertyHandler 내부
분기)를 완전히 분리해 이를 해소한다. → **예/아니오**

### TW-3 — `Tween{...}`의 모든 필드는 plain
`Value`뿐 아니라 `Time`/`Style`/`Override` 등 **모든 필드가 plain 값만** 받는다 —
바깥 `:Compute`가 이미 `Tween{...}` 테이블을 통째로 재생성하므로 내부에 또 다른
반응 경로를 만들 이유가 없다("같은 일 하는 두 번째 경로를 만들지 않는다").
→ **예/아니오**

### TW-4 — 3-상태 릴레이션 슬롯
슬롯은 `nil`(한 번도 process 안 됨) / `true`(세팅된 적 있음, 활성 트윈 없음) /
`{Tween, Value}`(진행 중) 셋이고, `Value`까지 저장하는 이유는 Roblox `TweenBase`가
자기 목표 PropertyTable을 역으로 노출하는 API가 없어 `Tween.Finish`를 구현할 수
없기 때문이다. → **예/아니오**

### TW-5 — 첫 세팅은 무조건 즉시
`prev == nil`이면 `realv`가 Tween이든 plain이든 **애니메이션 없이 즉시 세팅**한다 —
엔진 기본값에서 목표값으로 날아오는 "첫 마운트 진입 애니메이션" 버그 방지다.
→ **예/아니오**

### TW-6 — 정리가 세팅보다 먼저
활성 트윈이 있으면 override 정책에 따라 **정리가 끝난 뒤에** 새 값을 세팅해야
한다 — 순서가 뒤바뀌면 이전 트윈의 다음 인터폴레이션 프레임이 방금 세팅한 값을
덮어쓴다. → **예/아니오**

### TW-7 — override 두 값으로 압축한 근거
Roblox `TweenBase`엔 진행 중인 트윈의 목표를 바꿔치기할 API가 없어
"오버라이드"와 "삭제 후 재시작"이 관찰 결과상 `Cancel`과 완전히 동일하다 —
실질적으로 구별되는 건 `Tween.Cancel`(현재 보간값에서 이어감, 기본)과
`Tween.Finish`(목표값으로 스냅 후 재시작) 둘뿐이다. Tween→plain 전환도 두 옵션
모두 "정리 후 즉시 덮어쓰기"로 수렴한다. → **예/아니오**

### TW-8 — `Info` 우선, 없으면 편의 필드
`Info: TweenInfo?`가 있으면 그대로 쓰고 나머지 편의 필드는 전부 무시하며, 없으면
편의 필드로 조립한다. 편의 필드의 기본값은 별도 상수를 정의하지 않고 Roblox
`TweenInfo.new()` 자신의 기본값을 그대로 물려받는다. → **예/아니오**

### TW-9 — 핸들러 타입이 안 바뀐다
새 모델에선 매치되는 Dispatch 핸들러가 항상 PropertyHandler 하나뿐이라 "핸들러
타입이 바뀌는" 시나리오 자체가 Dispatch 레벨에서 사라졌고, 트윈 취소/전환은
PropertyHandler 내부 로직이다. 그래도 retractor 반환 자체는 여전히 내놔야 하고
몸체가 no-op일 뿐이다. → **예/아니오**

### TW-10 — 타입 대수
`T' = T | Tween<T>` 치환만으로 `T | Tween<T> | State<T | Tween<T>>`가 자동으로
나오므로 Modifier/State/Source/StoreBind에 `Tween` 인지 로직이 전혀 안 들어간다.
`Tween<T>`는 dispatch 참가자가 아니라 `None`/`Tag`처럼 순수 raw 데이터 값이라
"핸들러 계층 값" 규칙에도 안 걸린다(옛 분류가 부정확했음). → **예/아니오**

### TW-11 — `Animate`의 필드는 State를 받는다
`Animate(info)`의 각 필드는 `T | State<T>`를 받되 반환 함수 안에서 `:Get()`으로
풀어 plain으로 만든 뒤에만 `Tween{...}`에 넘기므로, `Tween`의 plain-only
불변식과 모순이 아니다. → **예/아니오**

### TW-12 — `CanAnimate`
생략하면 기본 `true`이고, `false`로 resolve되면 `Tween`으로 안 감싸고
`self:Get()`을 그대로 반환한다 — reduceMotion류 접근성 우회가 이 필드 하나로
표현된다. 케이싱은 나머지 필드와 맞춰 `CanAnimate`(PascalCase)다. → **예/아니오**

### TW-13 — `resolve`가 `if-then-else`인 이유
`Override`/`CanAnimate`처럼 `false`일 수 있는 필드에서 `isState(v) and v:Get() or v`
식은 `v:Get()`이 falsy일 때 조용히 State 객체 자신으로 새는 버그가 된다.
→ **예/아니오**

### TW-14 — `:Apply`로 정정된 근거
`Animate`만은 `:Compute` 직결이 실제로 안 깨졌지만, 같은 패밀리인 `Sum(a,b,c)`류는
이름 붙여 재사용하는 순간 캡처한 deps가 구독에 안 걸려 깨진다 — "이 라이브러리가
제공하는 이름 붙은 콤비네이터는 항상 `:Apply`"라는 단일 규칙이 예외를 두는 것보다
낫다. → **예/아니오**

### TW-15 — 옵션 State가 재애니메이션을 트리거하지 않음
`info.Style`이 State여도 내부 `:Compute`의 trailing deps로 안 넘어가므로 구독에
안 걸리고, 다음에 `Value`가 실제로 바뀔 때 최신 값이 자연히 반영된다 — "style이
바뀐다고 다시 애니메이션하는 경우는 없다"는 실사용 요구와 일치하는 **의도된
동작**이다. → **예/아니오**

### TW-16 — `initValue`는 에이전트 범위 밖
초기 진입 애니메이션은 필요해지면 **사용자가 직접 코드베이스+문서를 만지기로**
확정됐고, 에이전트는 임의로 착수하지 않는다. → **예/아니오**

### TW-17 — 자연 완료 시 북키핑 정리 안 함
Completed를 구독해 슬롯을 되돌리는 로직은 만들지 않는다 — 그 정리를 하고 싶어지는
동기는 이미 "첫 세팅 즉시 스냅" 분기가 처리하는 문제이고, 자연완료 상태는 반대로
목표값에 정확히 도달한 상태이며, `Value`는 lerp 가능한 프리미티브라 참조를 들고
있어도 문제가 없다. → **예/아니오**

---

## UI. `base/ui-shorthand-plan.md`

### UI-1 — 숏핸드가 여전히 필요한 이유
`UICorner`가 네이티브 Instance가 됐어도 "별도 Instance를 만들어 부모에 Parent해야
한다"는 구조적 번거로움 자체는 없어지지 않았다. → **예/아니오**

### UI-2 — `UI` 접두어를 붙인 이유
v1의 `Corner`/`Scale`을 그대로 쓰면 Modifier 체이닝 메소드가 "진짜 UICorner를
만드는 숏핸드"인지 그냥 비슷한 이름의 부가 필드인지 구분이 안 되고, 접두어를
붙이면 실제 Roblox 클래스 이름과 1:1로 읽혀 모호함이 사라진다. → **예/아니오**

### UI-3 — 기존 자식 매칭 기준
재사용 대상은 quad가 이전에 만든 **고정 이름**(`_quad_corner`류) 자식으로
한정하고, 타입만 보고(`UICorner`이기만 하면) 재사용하지 않는다 — 사용자가 직접
만든 것을 quad가 건드리지 않기 위해서다. → **예/아니오**

### UI-4 — 조회는 `Relate`, 이름은 표시·판정용
`FindFirstChild`가 ref 저장보다 비싸므로 `(inst, 숏핸드키) → child`를 `Relate`에
저장해 조회한다. 고정 이름 규약을 없애자는 뜻이 아니라 **이름은 표시·판정용,
`Relate`는 조회용**으로 역할이 갈린다. → **예/아니오**

### UI-5 — ⚠️ 확인 필요 항목
숏핸드가 만드는 **자식**도 quad가 만든 Instance이므로 gcconn/gchold 셋업을
거치는지 구현 시 확인해야 하고, 안 거치면 여기서만 조용히 미아가 된다.
→ **예/아니오**

### UI-6 — 자식 프로퍼티 세팅은 Dispatch에 위임
숏핸드 Handler가 자식 프로퍼티를 직접 쓰지 않고
`Dispatch.process(child, prop, v, 1)`로 넘기면 `State`/`Tween` 래핑이 공짜로
따라온다. `(inst, k)` → `(child, prop)` 위임은 Dispatch 입장에서 다른 키로
위임하는 것과 구조적으로 동일하고 새 체인이라 인덱스는 1부터다. → **예/아니오**

### UI-7 — `v == nil`은 `process`의 로직
`v`가 `nil`이면 만들어둔 자식을 지우는 것이고, 이건 반환 클로저가 아니라
`process` 자신의 로직이다(`process`가 `nil`이든 숫자든 완결적으로 처리하므로
클로저는 no-op이면 충분). 잦은 토글은 매번 Instance 생성/제거 비용이 그대로
드는 게 캐비엇이다. → **예/아니오**

### UI-8 — `mapTweenValue`가 필요한 이유
`v`가 `Tween<number>`면 `wrap` 변환을 **`Tween`을 벗기지 않고 `.Value`에만**
적용해야 하므로, `table.clone` 후 `Value`만 교체해 `Tween(opts)`로 다시 만든다.
`wrap`이 항등인 키도 분기 없이 이 헬퍼를 거친다. → **예/아니오**

### UI-9 — `UIPadding`은 프로퍼티마다 따로 위임
자식 프로퍼티 4개에 같은 값을 쓰는 키는 각 프로퍼티마다 `Dispatch.process`를
따로 부르고, 각자 독립 체인이라 트윈 슬롯도 프로퍼티별로 잡혀 4개가 같이
애니메이션된다. → **예/아니오**

### UI-10 — 자식 재생성 사이클에선 트윈이 안 걸림
`prev == nil` 규칙이 `(child, prop)` 기준이라 `nil`↔숫자를 오가며 자식이
재생성되면 그 직후 첫 값은 스냅되는데, 이건 버그가 아니라 그 규칙이 막으려는
것과 정확히 같은 상황이다 — 계속 애니메이션되길 원하면 `nil`로 내리지 말고 값만
바꿔야 한다. → **예/아니오**

### UI-11 — 자식 파괴 시 `retractFrom` 호출
자식을 파괴할 때 실행 중인 엔진 Tween이 남아있을 수 있으므로
`Dispatch.retractFrom(child, prop, 1)`을 같이 부르는 게 정석이고, retractor 안에서
**다른 키**에 대한 `retractFrom`은 허용된 경로다. → **예/아니오**

### UI-12 — 패키지 배치 원칙
"작고 항상 켜져 있어도 비용이 무시할 만한 편의 기능은 별도 opt-out 패키지로
쪼개지 말고 `quad-roblox` 코어에 직접 포함한다"는 원칙으로 확정됐고, 앞으로
비슷한 제안에도 이 선례를 따른다. → **예/아니오**

### UI-13 — 타입 생성 체크리스트
`mod:UICorner(8)`류가 타입체크되려면 생성 스크립트가 실제 Roblox 프로퍼티뿐
아니라 이 3개 숏핸드 키도 각 Modifier 타입의 메소드 목록에 끼워 넣어야 한다.
→ **예/아니오**

---

## CC. `base/component-composition-plan.md`

### CC-1 — 컴포넌트는 그냥 함수
`MyComp = function(props) return Frame{...} end`이고, v1의 자동 store 생성 +
자동 흡수 매직은 재현하지 않는다 — 자동 흡수는 매 호출마다 "이 prop이
State인가?" 분기를 프레임워크가 암묵적으로 하는 매직이라 명시적 전달이 더
단순·예측 가능하다. → **예/아니오**

### CC-2 — v1 linker의 두 역할은 이미 갈라짐
`self(name)`이 겸하던 (1) Ref 역할과 (2) 인스턴스 프로퍼티 → store 역방향
전파(양방향 바인딩)는 v2에서 각각 `Ref`와 "Source 직접 전달"이 대체한다.
→ **예/아니오**

### CC-3 — State/Source 경계 규칙
State는 파생값일 수 있어 쓰기가 정의 자체가 안 되고, Source는 항상 원본 슬롯
하나를 직접 가리키므로 쓰기가 의미 있다. → **예/아니오**

### CC-4 — 핸들러는 `State<T>` 하나만 받아도 됨
Source는 서브타입 호환으로 자동 통과하므로 `Source<T> | State<T>` 유니온이
불필요하고, "이게 Source면 역방향 쓰기까지"처럼 구분이 필요하면 `isSource`로
런타임 판별한다. → **예/아니오**

### CC-5 — Source 직접 전달의 실사용 범위
`isEnabled`처럼 여러 조건에 영향받는(파생된) 값은 애초에 State지 Source가 아니라
이 경로로 못 넘기므로, Source 직접 전달이 통하는 건 진짜 단순한 1:1 원본-토글
케이스뿐이고 일반적으론 `value(State) + onChange(callback)`이 기본이다.
→ **예/아니오**

### CC-6 — 리프에 Source 직접 바인딩은 정상 경로
`local a = Source(true); Frame { Visible = a }`는 막힐 이유가 전혀 없는 흔한
정상 패턴이고, "State가 일반 경로"라는 말은 **결과의 통계적 경향에 대한 서술**일
뿐이다(파생 결과는 State일 수밖에 없으므로 State가 더 자주 보임). → **예/아니오**

### CC-7 — Compose를 벤치마킹한 게 아님
Compose `Modifier`는 순서 의존적 wrapper 체인(`.then()`은 덮어쓰기가 아니라 순수
연결)이라, quad의 "필드명 기준 last-wins" 모델은 **독자 설계**이고 유사성은
"관례로 경계를 넘긴다"는 아이디어 수준에서만 성립한다. → **예/아니오**

### CC-8 — 조사한 선례 중 아무도 안 풀었음
"multi-root + 외부 ref/modifier 전달"은 Compose(회피), Fusion(미해결로 방치),
Vide/v1(애초에 안 함) 어디도 풀지 않았다 — 즉 quad가 진짜 새로 설계해야 하는
부분이지 어딘가 있는 답을 못 찾은 게 아니다. → **예/아니오**

### CC-9 — named parameter로 경계를 넘김
컴포넌트 함수는 배열 아이템 + 런타임 타입 스니핑으로 modifier/Ref를 받지
않는다(함수 호출로 경계를 넘는 순간 타입을 스니핑해줄 디스패처가 없으므로).
caller가 `props.Modifier`/`props.Ref`로 넘기고 저작자가 자기 코드에서 명시적으로
내부 `Frame{...}`의 배열 자리에 꽂는다. → **예/아니오**

### CC-10 — `or None` 필수 관용구
`{nil, props.Ref, child}`처럼 리터럴에 `nil`이 들어가면 배열 파트 전체가 순회
순서 보장을 잃을 위험이 있으므로 항상 `props.Modifier or None`으로 감싸야 한다.
`Modifier()`가 아니라 `None`인 이유는 별도 할당이 필요 없고 기존 메커니즘을 그대로
재사용하기 때문이다. 이건 base가 강제로 검증해줄 방법이 없어 **저작자가 직접
챙겨야 하는 규율**이다. → **예/아니오**

### CC-11 — 다중 루트 반환 폐기
"정적으로 고정된 여러 형제를 한 함수 호출이 그대로 반환"은 폐기다 — (1) Luau가
tail position 밖 다중 리턴을 지원 안 해 배열 중간에 놓이면 첫 값만 살아남고,
(2) 호출부에서 여러 컴포넌트를 나란히 쓰면 되며, (3) 프레임워크 조사에서도
진짜 수요가 있어 제대로 지원된 사례가 없다 — 셋 다다. → **예/아니오**

### CC-12 — Slot 반환은 별개 메커니즘
컴포넌트가 Slot을 반환하는 건 이미 있는 메커니즘이고 새 설계가 불필요하다 —
그런 컴포넌트는 애초에 `Modifier`/`Ref` 파라미터를 선언하지 않으면 그만이라
타입 시그니처 자체가 "적용할 단일 대상이 없다"를 표현한다. → **예/아니오**

### CC-13 — forwarding은 반환 전에 일어남
"반환값에 사후적으로 뭔가를 꽂아넣는다"는 그림 자체가 틀렸고, forwarding은 항상
컴포넌트가 반환하기 **전에** 저작자 코드 안에서 일어나므로 어느 root로 갈지는
저작자가 자기 코드에 뭐라고 쓰느냐로 완전히 결정된다. → **예/아니오**

### CC-14 — Ref엔 결합 유틸이 불필요
Ref는 필드 충돌 개념이 없고 콜백 리스트가 애초에 여러 등록을 누적하도록 설계돼
있어 여러 Ref를 받으면 그냥 전부 실행하면 된다. → **예/아니오**

---

## ML. `base/module-lifecycle-plan.md`

### ML-1 — Handler로 Roblox를 주입받는 방향
base가 "누가 실제로 그려주는지" 모르는 채로 있다가 Roblox Handler를 주입받는
모양이 자연스럽다(반대로 "Handler로 base를 받는" 게 아니라) — 가상돔이 없기
때문이다. → **예/아니오**

### ML-2 — 유일 슬롯 vs 우선순위 경쟁
**핸들러 레지스트리 자체(그 배후의 실제 bind 구현/백엔드)는 유일해야 하고, 그
안에 등록되는 개별 핸들러들은 여럿 + 우선순위 경쟁**이 맞는 모양이다 — 두 층위를
혼동하지 않는다. → **예/아니오**

### ML-3 — `New()`의 내부 구성
각 서브시스템 파일이 `Init(module)`을 export하고 `module.Dispatch = ...`로
채우며, 최상위 `New()`가 `InitXxx(module)`을 순서대로 쌓아 `module`을 반환한다.
`module = {New = New}` 자기참조는 이미 확정된 것과 같은 형태다. → **예/아니오**

### ML-4 — 타입 재익스포트는 실측 확인됨
`type Dispatch = InitDispatch.Dispatch` 형태의 재노출은 Luau에서 문제없이
동작하고, `typing-limits.md`가 우려하는 "명시 바인딩 필요" 케이스와는 다른
자리다(거긴 재귀 제네릭 문제, 여긴 단순 alias). → **예/아니오**

### ML-5 — 멱등 가드는 `module`을 키로 하는 `Relate`
각 `InitXxx`가 파일 스코프에 `Relate()` 하나를 두고 `module`을 키로 "이 인스턴스에
이미 Init됐는지"를 기록한다. `require` 캐시로는 부족한 이유는 그게 **파일**
단위인데 `New()`는 여러 `module` 테이블을 만들 수 있어서다. → **예/아니오**

### ML-6 — 플래그를 실제 작업 전에 세우는 이유
나중에 상호 의존이 생기면 먼저 표시해두지 않으면 무한 재귀에 빠지므로,
`require`가 순환 시 미완성 exports를 돌려주는 것과 같은 이유로 작업 시작 전에
"완료"로 표시한다. → **예/아니오**

### ML-7 — `value`는 `SetStrong`
`Relate`의 첫 인자는 항상 weak라 GC 결과엔 차이가 없지만, "다른 곳에서 안전하게
유지되는 것은 `SetWeak`" 규칙 기준으로 이 `true` 플래그를 다른 어디도 붙잡고
있지 않으므로 `SetStrong`이 맞는 선택이다. → **예/아니오**

### ML-8 — `_initializedBy`와는 다른 층위
`_initializedBy`는 backend 팩토리가 유일 슬롯을 **누가** 채웠는지까지 구분하는
공개 계약(같은 팩토리=no-op, 다른 팩토리=에러)이고, Init 멱등 가드는 quad-base
내부 서브시스템이 **한 번만** 도는지만 보는 사적 구현 디테일이라 "다른 호출자면
에러" 분기 자체가 없다. → **예/아니오**

### ML-9 — `Quad.debug`
`Quad.debug: boolean`(기본 `false`)은 라이브러리 자체의 디버그 스위치이고 지금
게이팅하는 건 핸들러 우선순위 동률 경고 print다. 기본이 `false`인 이유는
라이브러리가 사용자 콘솔에 아무것도 안 찍는 게 기본이어야 하기 때문이고,
다중 인스턴스화 시 인스턴스별인지 전역인지와 `listHandlers()`가 이 표면에
속하는지는 **미정**이다. → **예/아니오**

### ML-10 — `Handler` 이름 확정 근거
`Processor`는 계약 메소드가 `process`라 단어가 겹치고, `Provider`는 "공급한다"는
늬앙스인데 실제론 처리/반응하는 쪽이라 의미가 안 맞고 React Context와도
헷갈리며, `Plug`는 "값을 처리한다"는 의미가 빠져 있다 — 셋 다 기각 근거가 이렇다.
→ **예/아니오**

### ML-11 — Fallback Handler 등록이 명시적 예외
"등록/구현은 팩토리 뮤테이션 시점"이라는 이 문서의 일반 원칙에 대해
`*FallbackHandler`의 quad-base 자체 등록은 **명시적 예외**이고, 예외인 이유는
이 핸들러들이 "아무도 자리를 안 가져갔을 때"를 위한 것이라 누군가 자리를
가져가는 시점에 등록되면 자기 목적을 못 이루기 때문이다. → **예/아니오**

---

## LH. `base/lifecycle-hooks-plan.md`

### LH-1 — 세 훅은 새 개념이 아니다
`OnCreated`/`OnRendered`/`OnDestroyed`는 호출되는 즉시 평가되어 **이미 존재하는
프리미티브의 인스턴스로 사라지는** 순수 팩토리라, Dispatch/Brand/타입 시스템이
알아야 하는 새 개념이 하나도 없다(새 브랜드 태그조차 불필요). → **예/아니오**

### LH-2 — `State<function>` 우려가 안 생기는 이유
그 우려는 `[OnCreated] = fn`처럼 **해시 파트 특수 키**였다면 실제로 생겼을
문제다 — 팩토리 함수 호출은 Store/Dispatch 경로를 아예 안 타고 즉시 평가되어
확정된 객체가 children 배열에 얹히므로 디스패치될 "값"이 애초에 안 만들어진다.
→ **예/아니오**

### LH-3 — v1 `OnCreated`와 모순이 아닌 이유
v1식 거부는 **"특수 키" 메커니즘**에 대한 것이지, "팩토리가 기존 `PreRef`를
반환해서 children 배열에 놓는 것"과는 층위가 다르다 — 오히려 그 문단이 이미
권장한 관용구를 이름 하나로 감싼 것이다. → **예/아니오**

### LH-4 — `OnDestroyed`의 트릭
`Effect(function() return fn end)`에서 설치 단계에 실행되는 건 `fn` 자신이
아니라 **래퍼**이고, 그 래퍼의 즉시 1회 실행은 `fn`을 감싸 리턴할 뿐이라 부작용이
없으며 `fn`은 leaf가 죽을 때(cleanup 시점)에만 호출된다. → **예/아니오**

### LH-5 — 다중 등록이 공짜인 이유
호출마다 생성자가 새로 불려 독립 인스턴스가 만들어지고 서로 다른 숫자 슬롯에
놓이므로, v1처럼 "이 키엔 콜백 하나만" 같은 제약이 성립할 자리가 애초에 없다.
→ **예/아니오**

### LH-6 — `_fired` 가드와 안 충돌
그 가드가 막는 건 **같은 `PreRef` 객체를 두 번째 construction에 재사용**하는
것이지 "서로 다른 `PreRef` 여러 개를 나란히 쓰는 것"이 아니다. → **예/아니오**

### LH-7 — `OnRendered`가 공짜가 아니었던 이유와 채택 근거
`OnCreated`/`OnDestroyed`와 달리 디스패치 코어에 실제 post-pass가 필요해
"공짜가 아니다"라는 판단 자체는 지금도 맞고, 뒤집힌 건 **그 비용을 지불할지**다
(구현 난이도가 아주 낮고 Pre-Post 둘을 지원 안 할 이유가 없다는 판단).
→ **예/아니오**

### LH-8 — 스코프 판단이 틀렸던 것
"(a) 자기 프로퍼티만 / (b) 서브트리 전체" 중 "(a) 메커니즘은 (b)를 못 준다"는
판단이 틀렸음이 드러났다 — 배열 파트 루프가 각 자식의 마운트를 동기적으로
끝내므로 (a) 메커니즘이 사실상 (b) 스코프를 공짜로 준다. 진짜 경계는
(a)/(b)가 아니라 **"자기 아래 vs 자기 위"**였다. → **예/아니오**

### LH-9 — `OnDisposed`를 안 쓰는 이유
`dispose(value)`는 사용자가 의도적으로 부르는 능동적 API인 반면 이 훅의 실제
트리거는 **물리 Instance가 죽는 시점**(엔진 `Destroying`)이고 그 죽음이
`dispose()`를 거쳤는지는 훅 입장에서 구분도 안 되고 상관도 없다 — 그래서
`OnDisposed`는 잘못된 인상을 준다. 재검토 조건이던 "`dispose()`가 모든 것의
유일한 파괴 경로가 되면"도 범위가 `Slot`+`Instance`로 좁혀지며 발동 없이
종결됐다. → **예/아니오**

### LH-10 — `OnRendered` 이름은 문서로 대응
"렌더"가 quad엔 없는 개념이고 "부모에 붙기 전에 불린다"는 캐비엇까지 겹치지만,
이름의 친숙함이 주는 이득이 더 크다고 판단해 **이름을 바꾸는 대신 문서로**
대응한다. → **예/아니오**

### LH-11 — 두 층위의 우선순위
**`PostRef` 프리미티브 자신**은 디스패치 코어의 일부라 M8에서 `PreRef`와 같이
구현되고(뒤로 미루는 대상 아님), **훅 슈가 셋**만 형제 백로그들과 동급으로 맨
뒤다. → **예/아니오**

---

## FB. `base/fallback-plan.md`

### FB-1 — 왜 새 프리미티브가 아닌가
"Error Boundary는 빈 자리 아님 — `pcall(MyComp, props)`만으로 같은 격리 효과를
얻는다"는 기존 결론을 뒤집는 게 아니라 그 위에 얹는 **순수 슈가**이고,
디스패치/Store/Handler 계층에 아무것도 새로 안 만든다. → **예/아니오**

### FB-2 — 왜 플래그 하나로 안 합쳤나
항상 `xpcall`+`debug.traceback` 비용을 물지 않아도 되는 가벼운 경로를 분리해 둘
수 있고, `onError`의 시그니처 자체가 달라(trace 유무) 타입으로도 구분하는 게
정확하다 — `Ref`/`PreRef`가 같은 예다. → **예/아니오**

### FB-3 — `OkComp`/`ErrComp` 독립 제네릭
원래 컴포넌트와 에러 플레이스홀더가 다른 타입일 수 있고 래핑된 함수의 실제
반환 타입이 정확히 `OkComp | ErrComp` 유니온이라 하나로 합치지 않는다.
→ **예/아니오**

### FB-4 — `err: any`가 최우선 경고
Lua `error()`는 임의의 값을 던질 수 있고 quad는 아무 가공도 안 한다. `error(msg)`를
레벨 없이 부르면 Luau가 자동으로 `"파일:줄: "` 접두를 붙이므로 순수 메시지를
원하면 `error(msg, 0)`이어야 한다. **`err`를 `string`으로 가정하는 게 제일 흔한
실수라 문서화에서 최우선으로 경고**하고, 가공까지 대신해주면 그게 또 다른
매직이라 `onError` 구현 몫으로 완전히 열어둔다. → **예/아니오**

### FB-5 — `debug.traceback(nil, 2)` 배선은 실측됨
클로저 업밸류가 `xpcall` 리턴 이후에도 정상적으로 보이는지, 중첩 호출에서도
실패 지점까지 스택을 담는지, 테이블 에러도 손실 없이 통과하는지가 스파이크로
확인됐다. → **예/아니오**

### FB-6 — 이름은 대기열에 안 올림
낱개 함수 둘뿐이라 충돌 표면이 작다고 판단해 용어 정리 대기열에 안 올리고 바로
점유했다. → **예/아니오**

---

## TL. `base/typing-limits.md`

### TL-1 — 0번 대전제
Luau의 한계를 우회하려고 타입/API를 비틀지 않는다 — 이유는 "게을러서"가 아니라
(a) 비튼 만큼 복잡도와 인체공학 손해가 영구히 남고 (b) Luau가 고쳐졌을 때 자동
수혜가 아니라 되돌리는 마이그레이션이 필요해져서 **더 비싸기** 때문이다.
대신 한계 명시 + 관례 명시 + 추적 링크는 반드시 한다. → **예/아니오**

### TL-2 — 1번 한계의 정확한 경계
문제는 **"자기 이름을 다른 타입 인자로 감싸 반환"**(`State<T>` → `State<U>`)
하나뿐이고, 같은 인자 재귀·재귀 아닌 컨테이너·감싸지 않은 반환·콜백 파라미터
추론·콜백 안 로직·명시 주석 이후 다운스트림은 전부 정상이다. "제네릭을 감싸서
반환하는 것 자체"가 문제인 게 아니다. → **예/아니오**

### TL-3 — "조용히"가 핵심
컴파일 에러로 막히는 게 아니라 진단 0건으로 통과한 뒤 그 결과에 대한 타입 체크만
사라지고, `luau-analyze`/`--annotate`/`luau-lsp` 세 경로 전부 동일하다(도구 문제가
아니라 Luau 자체 한계). → **예/아니오**

### TL-4 — ① 명시 바인딩 강제
파생 State를 만드는 자리마다 결과 타입을 `:` 주석으로 명시한다. 주석이 그 한 줄의
RHS를 검증해주진 않지만 **다운스트림엔 정확히 바인딩**되므로 "한 줄만 못 믿고
나머지 코드베이스 전체는 안전"한 상태가 된다. 이건 API 문서/튜토리얼에도 반영해야
하는 관례다. → **예/아니오**

### TL-5 — ② 데이터부/메소드부 쪼개기
`StateData<T>`(자기만 재참조) / `State<T>`(그 위에 `Compute` 얹기)로 쪼개면 콜백
파라미터가 무주석으로 통과하고 타입 체크도 살아있다. **코드 생성이 필요 없고**
타입 선언 하나가 늘 뿐이다. 캐비엇은 콜백이 받는 `s`에 `Compute`/`With`가
없다는 것이고, `:Apply`의 factory처럼 콜백 안에서 다시 부르는 자리는 파라미터
주석이 필요하다. → **예/아니오**

### TL-6 — ③ `typeof(named function)` 선언 스타일
재귀 메소드를 인라인 제네릭 시그니처 대신 이름 붙은 top-level 함수 + `typeof`로
참조하면 **LHS 명시 주석 없이도 다운스트림이 정확히 타이핑**된다(체이닝 깊이 50,
타입이 바뀌는 체이닝, 중첩까지 실측). 비용도 없다. → **예/아니오**

### TL-7 — ③이 ①을 대체하지 않음
③을 채택해도 (a) 콜백 파라미터는 여전히 명시 주석이 필요하고, (b) **명시 LHS
오타입은 그 줄 자체를 여전히 못 잡으며**, (c) 옛 솔버는 ③의 선언 자체를 거부한다 —
"명시 바인딩 관례를 완화할 수 있다"는 뜻이 **절대 아니다**. → **예/아니오**

### TL-8 — 콜백 추론 실패의 진짜 원인
이 실패는 "재귀 자기참조 특유의 문제"가 아니라 **"제네릭이 관여하는 함수 호출의
인자로 넘긴 함수 리터럴엔 Luau가 컨텍스트 타입을 전파하지 않는다"**는 더 일반적인
한계이고(재귀 없는 `Map<T,U>`류도 동일), 재귀는 그 위에 얹혀 실패 양상을
"구조적 duck-typing 오염"으로 악화시키는 부가 요인이다. → **예/아니오**

### TL-9 — 우회안 둘 다 기각
monomorphize 헬퍼(추론이 실제로 살아남)와 이중 꺾쇠 명시 인스턴스화(leaf 호출에
한해 sound함이 확인됨) 둘 다 **채택 안 함** — 전자는 `state:Compute(fn)` 단일
호출을 2단계 체인으로 바꿔야 하고(0번 대전제 위반), 후자는 매 호출 `T`·`U`를
중복 명시해야 하며 `:Apply` 중첩엔 여전히 안 통해 규칙이 둘로 늘어난다.
→ **예/아니오**

### TL-10 — `setmetatable` 경로는 솔버 버그
`setmetatable<{...}, {__index: typeof(...)}>` 확장은 quad의 실제 계약에서 올바른
대입에도 모순 진단 두 개가 남는 Luau 0.733 솔버 버그를 만났고, 순수 `typeof`만
쓰면 같은 시나리오가 깨끗이 통과하므로 `setmetatable` 경로 특정 문제로 좁혀졌다.
→ **예/아니오**

### TL-11 — `Effect`/`Observer`는 무관
한때 "같은 lazy 핸들 계약을 공유하니 같이 걸린다"고 서술했으나 실측 결과
아니었다(각각 자유 함수라서, 그리고 로컬 제네릭 반환이 없어서). → **예/아니오**

### TL-12 — 지금 그대로 두면 자동으로 풀림
RFC가 드는 "지금은 거부되는" 예시가 `Promise<T>.andThen`으로 **우리 `Compute`와
글자 그대로 같은 모양**이고, 완화 메커니즘이 순수 내부 변경(사용자 문법 변경
없음)이라 코드 변경 없이 수혜를 받는다 — 그래서 "미래에 자연히 등록되도록
플레이스홀더를 심어두는" 작업은 **필요 없고, 오히려 0번 대전제 위반**이다.
→ **예/아니오**

### TL-13 — 옛 솔버 vs 새 솔버
옛 솔버는 이 패턴을 선언 시점에 거부하고, 새 솔버는 선언은 받아주지만 조용히
새는 중간 상태다 — RFC의 완화가 선언 검사까지는 들어왔고 인스턴스화까지는 아직인
것으로 보인다. `luau-lsp`는 **옛 솔버가 기본값**이라 M0 실착수 때 실제 에디터
환경에서 확정해야 한다. → **예/아니오**

### TL-14 — `type function`이 도와주는 범위
`type function`은 **레코드 필드 합성**(5번)엔 도움이 되지만 1번 문제 우회엔
막다른 길이다 — 제네릭 인자가 구체화되지 않은 채 자기를 재귀 호출하면
`stack overflow`로 즉시 크래시한다(구체 타입에 대해서만 도는 실행 모델이라
RFC의 lazy expansion과 다르고, `types` 라이브러리에 지연 적용 API가 없음).
→ **예/아니오**

### TL-15 — 진단 0건은 안전의 증거가 아님
`luau-analyze`가 진단 0건이어도 타입이 제대로 해소됐다는 뜻이 아니므로
`--annotate`로 실제 추론 타입을 눈으로 확인하고 **음성 대조군**을 같이 둬야
한다 — 이 문서의 여러 항목이 "된다고 믿었다가 실측에서 뒤집힌" 것들이다.
→ **예/아니오**

---

## DT. `base/debounce-throttle-plan.md`

### DT-1 — Blocker의 옆자리
Debounce/Throttle은 `Blocker`와 같은 자리(무효화 전파 게이트)이고 다른 건 "언제
열리는가"뿐이다 — 새 전파 메커니즘이 아니라 **게이트 노드의 릴리스 트리거
교체**다. `Blocker`는 "코드로 구간을 안다", 이쪽은 "구간을 코드가 모른다"라
겹치는 게 아니라 상보적이다. → **예/아니오**

### DT-2 — 차이는 한 비트
두 도구의 차이는 **"신호가 창 타이머를 리셋하는가"** 하나뿐이고
leading/trailing/통과 후 창 재개방은 완전히 동일하다. lodash식
`maxWait`로 Throttle을 흉내내던 초안은 **trailing 통과 직후 타이머를 전부
회수해 바로 뒤 신호가 또 즉시 발화하는(1초 안에 두 번) 실제 버그**가 있어
폐기됐다. → **예/아니오**

### DT-3 — "영원히 발화 안 함"은 정의 그 자체
디바운스에서 신호가 끊이지 않으면 영원히 발화 안 하는 건 버그가 아니라 정의이고,
그래서 `MaxTime`은 **디바운스 전용 안전장치**로 역할이 좁아진다(스로틀은 원래
주기적으로 발화하므로 무의미). → **예/아니오**

### DT-4 — 공개 `Blocker` API 위엔 못 얹음
공개 `Blocker` API엔 "상류 신호가 지금 도착했다"는 통지가 없어 타이머를 (재)시작할
순간을 알 방법이 없다 — 그래서 `Blocker`의 게이티드 노드를 내부 공용 `Gate`
노드로 한 겹 일반화하고 셋이 서로 다른 정책으로 얹히는 형태를 권한다.
→ **예/아니오**

### DT-5 — laziness는 안 깨짐
게이트는 무효화 신호만 받고 무효화 신호만 내려보내며 `:Get()`을 스스로 호출하는
지점이 한 군데도 없어 eager 노드가 아니다. **단
distinct-until-changed를 게이트에 섞으면 `:Get()`이 필요해져 상류 체인 전체가
eager가 되므로 넣지 말아야 한다.** → **예/아니오**

### DT-6 — (B) value-hold 철회 근거
직전 커밋에서 `invalid=true`인 채 아무도 안 읽고 있다가 새 창이 열리면 "창
안에선 invalid 세팅 안 함" 규칙이 이미 세팅된 플래그를 못 되돌려 held value
계약이 조용히 깨지고, 이걸 고치려면 창이 열리는 순간 upstream을 강제 pull해야
하는데 **그건 정확히 Throttle이 막으려던 비싼 연산을 매 창마다 강제로 도는 것**
이다. 업계 선례(VueUse/RxJS)도 push/eager 모델이라 pull-lazy가 원칙인 quad엔
그대로 안 맞았다. → **예/아니오**

### DT-7 — 재사용해도 상태 공유 안 함
`:Apply`가 호출될 때마다 팩토리가 새 게이트 노드(자기 타이머/자기 pending)를
만들어서 재사용이 원천적으로 안전하다 — `Blocker`가 네스팅을 막은 것과 다르다.
→ **예/아니오**

### DT-8 — `Time`/`MaxTime`만 State 허용
`Leading`/`Trailing`은 정적 정책값이라 plain만 받고, `Time`/`MaxTime`은
`number | State<number>`다. `tween-plan.md`의 "옵션 값 모양" 절이 세운 근거와
안 부딪히는 이유는 **구독하지 않고 `setTimeout` 호출 순간에만 `:Get()`으로 읽는
폴링**이라서다. **이미 스케줄된 타이머엔 반영 안 되고 다음
창부터** 적용된다. → **예/아니오**

### DT-9 — `Leading`/`Trailing` 둘 다 false는 error
아무 일도 안 하는 설정이므로 즉시 error가 권장이다(범위 밖 인덱스를 clamp 대신
error로 한 선례와 같은 결). → **예/아니오**

### DT-10 — `Reset`은 공개 옵션이 아님
노출하면 `Debounce{Reset=false}`처럼 "이름과 동작이 어긋난 물건"을 만들 수 있게
되므로 내부 파라미터로만 둔다. → **예/아니오**

### DT-11 — State 자신에 메소드를 안 붙이는 이유
붙이면 "디바운스로 만들어진 State"와 "일반 State"가 메소드 유무로 타입이 갈려
State 계층에 조용히 서브타입 분기가 생긴다 — quad가 피해온 OOP식 확장과 같은
종류의 문제다. → **예/아니오**

### DT-12 — `Blocker`식 공유 외부 객체도 아닌 이유
Debounce/Throttle은 **이전 실행이 다음 실행에 영향을 주는 상태 기계**라 여러
파이프라인에 공유하면 "누구의 신호가 창을 리셋하고 누구의 값이 커밋되는가"가
불명확해지고, 5-1절의 "재사용해도 상태 공유 안 함" 확정과도 정면으로 어긋난다.
→ **예/아니오**

### DT-13 — 개별은 `Ref`, 전체는 팩토리
개별 제어는 `Handle = Ref()` 아웃파라미터로 특정 `:Apply()` 하나만 겨냥하고,
전체 브로드캐스트는 팩토리 자신에 `:Flush()`/`:Cancel()`을 붙인다. 팩토리는
자기가 만든 게이트를 **weak 레지스트리로만** 추적해야 하고(strong이면 다운스트림이
다 죽어도 GC가 안 됨), `Flush`/`Cancel`은 이미 있는 내부 함수를 그대로 호출하는
노출 방식 차이일 뿐이다. → **예/아니오**

### DT-14 — `Flush`/`Cancel`의 의미
`Flush()`는 `pending`이면 창 끝을 안 기다리고 즉시 커밋(+창 재개방), 없으면
idempotent no-op이다. `Cancel()`은 타이머를 정리하고 `pending`을 되돌리되
**전파는 안 한다**(버림). → **예/아니오**

### DT-15 — `Tween`처럼 quad-roblox에 두지 않는 이유
`Tween`은 TweenService라는 **엔진 기계 자체**에 의존하지만 Debounce/Throttle이
엔진에서 필요로 하는 건 **시계 하나**뿐이고 나머지는 전부 순수 로직이다 —
`Tag`/`Attribute`와 같은 상황이다. 순수 Luau엔 `task`도 이벤트 루프도 없어
base가 "동작하는 기본 스케줄러"를 제공할 수조차 없고, `Throttle`도 trailing
때문에 이 배선이 똑같이 필요하다. → **예/아니오**

### DT-16 — `setTimeout`/`clearTimeout` 어휘 선택
`task.delay`/`task.cancel`을 안 따라간 이유는 **`task`가 표준도 아니고 Luau의
것도 아닌 한 엔진의 것**이라 base 층에 특정 백엔드 어휘를 새기면 그 엔진만
특별대우하는 셈이기 때문이고, 대신 가장 대중적이고 중립적인 JS 어휘를 썼다.
대가로 Roblox `task.delay(duration, fn)`는 **인자 순서가 반대**라 래퍼에서 한 번
뒤집어야 하는 조용히 틀리기 좋은 자리가 생긴다. → **예/아니오**

### DT-17 — vararg를 일부러 안 받음
게이트의 콜백은 게이트당 하나씩 만들어져 재사용되는 안정된 클로저라 호출마다 새로
만들 필요가 없고, 따라서 varargs로 아낄 할당이 애초에 없어 표면만 넓히는 셈이다.
→ **예/아니오**

### DT-18 — `Timeout` 전용 타입
`type Timeout = { __type_timeout: true, _native: any }`이고 마커는 런타임에도
실제로 넣는다. `bindLifetime`이 `any`인 건 거기 진짜로 아무거나 오기 때문이고
`setTimeout`/`clearTimeout`은 **자기가 만든 것만 주고받는 닫힌 루프**라 성격이
정반대다. 마커가 필요한 이유는 `type Timeout = {}`가 구조적으로 모든 테이블과
호환이라서이고, `_native`를 타입에 미리 선언해두면 `any` 탈출이 **필드 하나에
갇혀 경계가 문서화**된다. → **예/아니오**

### DT-19 — 취소 없는 엔진도 구현 가능
프로바이더가 함수를 래핑하고 유효 플래그를 뒤집으면 되므로 `clearTimeout`은
base가 요구해도 되는 계약이다. 다만 그 방식은 타이머가 실제로는 깨어나서 아무
일도 안 하는 형태라 "대기 타이머가 게이트를 붙잡는다"는 성질은 그대로 남는다.
→ **예/아니오**

### DT-20 — `os.clock()`은 주입 대상이 아님
Luau 표준 라이브러리이고 일관되게 고정밀 값을 준다. **단 "현재 시각"이 아니라
기준점이 정해지지 않은 카운터라 차이(diff) 계산 전용**이고, 이 설계는 전부 차이
계산뿐이라 제약을 안 건드린다(부수로 벽시계 보정에 영향받지 않는 장점도 있음).
→ **예/아니오**

### DT-21 — 타이머를 1개로 줄이는 최적화
`maxDeadline = os.clock() + MaxTime`을 잡아두고 매 신호마다
`min(Time, maxDeadline - os.clock())`으로 스케줄하면 타이머 하나가 "조용해짐"과
"더 못 기다림" 둘 다를 표현한다. `MaxTime`이 없으면 `maxDeadline`이 무한대라
분기 없이 흡수된다. 의사코드를 타이머 2개로 남겨둔 건 검토 편의 때문이고 실제
구현은 이 형태를 권한다. → **예/아니오**

### DT-22 — 대기 타이머는 유계 지연 GC
대기 중인 타이머가 게이트 노드를 강하게 붙잡아 다운스트림이 다 죽어도 최대
`Time`초 동안 살아있지만, 이건 누수가 아니라 **유계이고 자가 치유되는 지연 GC**다.
위험해지는 조합은 **긴 `Time` + 빠른 생성/파괴**이고 문서 경고 + `:Cancel()`로
대응한다. → **예/아니오**

### DT-23 — Dispatch 변경 불필요
타이머 콜백이 하는 건 플래그 세팅과 무효화 전파뿐이고 실제로 뭔가 하는 소비자는
이미 `canExecute` 게이트를 통과해야 하므로 기존 장치가 그대로 커버한다. 게이트
노드는 `inst`에 안 묶인 순수 값 계층이라 `bindLifetime` 배선도, `Relate`도 안
쓴다. → **예/아니오**

### DT-24 — 이름 유지 근거
Roblox 커뮤니티의 "debounce"(재진입 방지 불리언)와 충돌하지만, 업계 표준 이름을
버리면 검색·이주 비용이 더 크다는 판단으로 유지하고 **사용자 문서 첫 줄에 다르다는
걸 못박는다**. `-ed`를 안 붙이는 이유는 게이트가 반환하는 게 lazy State 노드라
코퍼스 규칙(`Compute`가 `Computed`가 아닌 이유)이 그대로 적용되기 때문이다.
→ **예/아니오**

### DT-25 — 결국 순수 슈가
제어 핸들 설계까지 확정하고 나니 새로 필요한 quad-base 코어 표면은 **주입 op
2개뿐**이고 게이트는 `Blocker`가 확정한 개념 위에, 제어 핸들은 `Ref` 위에 얹히는
것으로 드러나 **순수 슈가**로 귀결됐다 — 구현 우선순위만 맨 뒤로 밀리고 승격
자체는 유효하다. **단 `Blocker` 구현 시점(M3)에 게이트 노드를 공용으로 빼두는
것만은 그때 해야 한다**(따로 하면 같은 설계를 두 번 함). → **예/아니오**

### DT-26 — 테스트가 공짜로 결정론적이 됨
주입 op 2개 덕분에 가상 시계로 결정론적 테스트가 공짜로 되고, 이게 quad-base
배치를 미는 또 하나의 근거다(quad-roblox에 `task.delay`를 직접 박으면 base 테스트
하네스에서 이 프리미티브를 테스트할 방법이 없어짐). → **예/아니오**

---

## 회신 안내

- **`예`인 항목은 아무것도 안 해도 됩니다** — `아니오`(또는 "부분적으로 틀림")인
  항목만 번호와 함께 알려주세요.
- 각 항목에 대해 **(1) 어디가, (2) 어떻게 왜 틀렸는지, (3) 원래 뭐가 맞는지**를
  적어주시면 그대로 `base/`에 반영합니다.
- 문항이 **질문 자체를 잘못 이해하고 있는 경우**(제가 문서를 오독해서 문항을
  틀리게 쓴 경우)도 `아니오`로 잡아주시면 됩니다 — 그 경우 문서가 아니라 이
  문서의 문항만 고칩니다.
- 회신을 받으면 이 문서를 1라운드처럼 **"아니오가 나온 항목만 남긴 근거 기록"**
  으로 재편하고, `base/`(+`ROADMAP.md`/`question.md`/`archive/`)에 반영합니다.
