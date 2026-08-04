# Store 의미론 — 부작용 허용, State는 Store 위의 조합 가능한 캐시 레이어

**상태**: base — 부작용 허용/Store 문법 부분은 확정. State/Source 온톨로지는
2026-08-04 검증 라운드에서 새로 열린 진행 중인 설계 스레드(`research/
bind-system-plan.md` 참고). 원본: `.claude/initreq/raw-userinput.md`
"store는 부작용을 허용함" / "state는 어떻게 구현하는가" 절.

## Store는 부작용을 허용하는 게 기본 디자인

부작용 없이(파라메터 패싱만으로) 쓰는 것도 물론 가능하지만, 라이브러리 차원에서
막지 않는다. 부작용 유무는 **사용자가 직접 문서화**하는 관례로 둔다 — 라이브러리가
순수성을 강제하지 않음.

다만 한 가지는 명확히 구분: **렌더 리턴 위에서 무언가를 observe하는 것은 그냥
부작용**이다 (`useEffect`와 유사한 것으로 문서화). 이건 "허용되는 부작용"이 아니라
"당연히 부작용"이라는 뜻 — 문서화 시 이 경계를 분명히 할 것 (`research/
purity-and-effects-plan.md`와 연결됨).

**보강(2026-08-04 검증 라운드): 부작용은 심각도가 다른 두 갈래로 나뉜다.**

1. **국소적 부작용** — 입력으로 받았거나 자신이 만들어 소유한 대상에 대한
   부작용(예: 렌더 리턴 아래에서 옵저빙해서 자기 slot을 갱신). 이건 편의성이
   커서 적극 환영하는 영역.
2. **경계를 넘는 부작용** — globalStore처럼 컴포넌트 바깥의 전역 상태를
   다루는 경우. 게임 UI 특성상(스킬/주변 환경에 영향받는 UI 등) 완전히
   막을 수는 없지만, 라이브러리로 재사용하려는 컴포넌트가 이런 부작용을
   가지면 이식성이 떨어짐(`research/purity-and-effects-plan.md`와 연결).

**미해결 열린 질문**: state를 옵저빙해서 나온 결과로 slot에 `clear`/`add` 같은
연산을 할 때, 그 시점에 대상 slot이 이미 죽어있으면 어떻게 되는가 — state가
생성되는 지점과 slot이 적용되는 지점이 서로 다른 스코프라, "state 변경이
발생했을 때 그 slot이 아직 살아있는지"를 어떻게 연관지어 확인할지 아직 명확한
설계가 없음(`isInit=false`일 때는 허용, `isInit=true`이고 생존 확인 함수가
거짓이면 불허 정도의 방향은 있으나 미완성). 사용자 본인도 "더 리서치가 필요"
하다고 명시적으로 표시 — `research/bind-system-plan.md`의 "Store/State/Source
온톨로지" 스레드와 함께 다룰 것.

## 정정(2026-08-04 검증 라운드): `State` 프리미티브는 실제로 필요하다

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
  (`Pipe` 후보는 사실상 폐기 쪽으로 기움). 상세는 `research/bind-system-plan.md`의
  "Store/State/Source 온톨로지" 절 참고 — **아직 완전히 결론난 설계는 아니고,
  구현 단계에서 더 다뤄야 할 진행 중인 스레드.**

미해결로 남은 것: `:Compute`의 캐싱/무효화 전략(값이 바뀌었는데 듣는 소비자가
없으면 연산을 미루는 dirty-flag 방식 등), Luau 타입 시스템에서 `store "key"`
같은 커링 호출이 오버로드 함수 타입으로 `state<T>`를 정확히 추론하기 어려운
문제(문자열 리터럴이 as-const로 좁혀지지 않는 문제) — 둘 다 열린 채로
`research/bind-system-plan.md`에서 계속 다룰 것.

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

## 여러 스토어 값을 묶어 처리하는 것 (dependency array) — 연구 필요

`useEffect`처럼 여러 store 값을 디펜던시로 묶어 파생값을 계산하고 싶다는
요구가 있음(v1의 `myStore "a,b"` 콤마-조인 문자열 방식은 폐기 대상 —
`base/quad-v1-architecture.md`의 "문자열 DSL" 문제점 참고). 단, **v1의
`:Add`/`:With`/`:Tween` 같은 이름 붙은(named) 체이닝 연산은 만들지 않기로
확정** — 대신 일반 함수를 받아 처리하는 쪽이 일관적이라는 판단. 구체적인 API
모양(`Store.Combine({a,b}, function(a,b) ... end)`류)은 아직 미정 —
`research/bind-system-plan.md` 참고.
