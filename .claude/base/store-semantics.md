# Store 의미론 — 부작용 허용, State는 Store 위의 조합 가능한 캐시 레이어

**상태**: base — 전부 확정. State/Source 온톨로지는 2026-08-04 검증
라운드에서 새로 열려 같은 세션 2~4차 라운드에 걸쳐 확정까지 마침 — 최신
상세는 `base/bind-system-plan.md` 참고. 원본: `.claude/initreq/raw-userinput.md`
"store는 부작용을 허용함" / "state는 어떻게 구현하는가" 절.

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
`canExecute()` 하나만 확인, 거짓이면 no-op. 한때 검토했던 `isInit=false`면
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
- **store에서 state를 얻는 연산(예: `store "key"`)은 항상 새 state 인스턴스를
  반환한다** — state 자체가 캐시되어 재사용되는 게 아니라, source만 store에
  귀속된 유일한 실체이고 그 위의 state는 매번 새로 생성됨.
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
  `Ref(default)`/`Store({defaults})`/`Modifier.Rounded(8)`, 위 "생성자
  스타일 확정" 참고).
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

과거 "미해결로 남은 것"으로 적었던 두 항목도 모두 해소됨: `:Compute`의
캐싱/무효화 전략은 push-invalidate(신호만)/pull-recompute(`Get()` 시점)로
확정(`base/bind-system-plan.md` "전파 모델" 절), `store "key"` 커링의 타입
추론 문제는 `store.key`(dot-access)를 1급 경로로 확정하며 해소(같은 문서
"타입 추론 문제" 절, 3차 라운드).

## Store 값 설정 문법 — v1 인체공학 유지 (확정)

**사용자 확인 완료**: Store 값 설정은 `__newindex` 기반(`myStore.key = value`)을
그대로 유지 — ProfileService 등 Roblox 생태계에서 이미 익숙한 관용구라 바꿀
이유 없음. 마찬가지로 다음 두 인체공학도 유지:

- **괄호 생략(paren-less) 구조** — 필요 시 커링(`myStore "key"`처럼 문자열
  하나로 register를 얻는 v1 스타일)을 계속 허용.
- **`:` 체이닝** — 값을 바꾸는 연산에 한해 체이닝 문법 허용(`base/
  architecture.md`의 "함수지향 디폴트, `:`는 예외적으로만" 원칙과 일치 — 체이닝이
  자연스러운 곳 중 하나가 바로 이 store 값 변경).

`base/architecture.md`의 "복사 구현 지양, 팩토리 함수로 대체" 원칙과 함께 읽을
것 — v1의 문제는 metatable 체이닝으로 매번 새 테이블을 할당하며 "불변 빌더"를
흉내낸 것이었지, `:` 체이닝 문법 자체나 커링 문법 자체가 아니었음. v2는 문법
인체공학(사용자가 좋아하는 부분)은 유지하되 내부 구현(체이닝이 아니라 팩토리
함수)만 바꾼다.

## Store 값을 직접 mutate한 뒤 전파 — `:Emit(key)` (2026-08-06 후속 세션)

**결정**: Source가 들고 있는 값을 새 값으로 교체하지 않고 제자리에서
mutate한 뒤, `Store:Emit(key)`로 그 key의 무효화 신호만 별도로 쏘는
것을 **Source 원천(store가 직접 들고 있는 값)에 한해 허용**한다.

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
(`base/modifier-plan.md`), `State<Modifier>`가 UB로 확정된 것도 같은
이유(`modifier-plan.md` 7번) — Store/State/dispatch 경로엔 애초에
Modifier용 processor가 없음. 위 "하드 경계"와 같은 이유로, `Emit`이
Modifier의 정적 flatten과 충돌할 걱정 자체가 성립하지 않음(둘이 만날
지점이 없음).

## 여러 스토어 값을 묶어 처리하는 것 (dependency array) — 확정

`useEffect`처럼 여러 store 값을 디펜던시로 묶어 파생값을 계산하고 싶다는
요구가 있었음(v1의 `myStore "a,b"` 콤마-조인 문자열 방식은 폐기 대상 —
`base/quad-v1-architecture.md`의 "문자열 DSL" 문제점 참고). **v1의
`:Add`/`:With`/`:Tween`처럼 값을 직접 가공하는 이름 붙은(named) 체이닝 연산은
만들지 않음** — 대신 일반 함수를 받아 처리. (주의: 아래의 v2 `:With(...)`는
이름만 같을 뿐 v1의 `:With`와는 다른 연산임 — v1은 "함수/테이블에서 값을
가져오는" 가공 연산이었고, v2는 그냥 "여러 State를 의존성으로 모으는" 수집
연산.) 최종 형태는 `:With(...)`로 의존성을 모으고
`:Compute(fn)`으로 파생 State를 만드는 것으로 확정 — `Store.Combine({a,b},
fn)`류 포지셔널 인자 방식은 기각됨. 정확한 lazy 인자 규칙(self/with 값 둘 다
State 핸들로 넘기고 `.value`를 실제로 읽을 때만 계산)은 `base/bind-system-plan.md`의 "Store/State/Source 온톨로지" 절 참고.
