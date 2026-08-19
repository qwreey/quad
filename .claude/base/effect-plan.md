# Effect — 설치 + 확정 정리, `state` 있으면 Observer를 감싸 재실행도 지원

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크
대비 갭 분석)에서 갈라져 나온 확정 프리미티브. `base/blocker-plan.md`(같은
조사에서 나온 다른 확정 프리미티브)와는 서로 무관 — Store/State 작업이나
Ref/PreRef와 파생 관계는 아니라 별도 파일로 둔다(2026-08-07 문서 정리에서
한 파일로 합쳤던 걸 다시 분리). 단 `state` 인자를 받는 형태는 내부적으로
Observer를 조합해서 만들어짐(아래 참고, 2026-08-07 여섯 번째 세션 확정) —
"Observer와 무관한 완전 독립 프리미티브"였던 이전 서술은 정정됨.

**Effect와 Observer의 관계 확정(2026-08-07 여섯 번째 세션)**: 별개의
독립 프리미티브이되, `state`를 받는 형태의 Effect는 내부적으로 Observer를
**조합(compose)**해서 만들어짐 — Ref/PreRef처럼 브랜드 태그만 다른 재사용이
아니라, Observer(재실행 신호) 위에 자동 cleanup 배선을 얹은 한 단계 위
계층. **자유 함수인 이유는 여전히 유효**: `state` 없이도 성립하는
mount/unmount 전용 유스케이스가 있고, 실제 leaf 생명주기 바인딩은 (Observer와
마찬가지로) children 배열 위치에 거는 것이라 `state`가 그 바인딩을 소유하지
않음 — Roblox엔 `task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이
흔하고, Luau 테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는
순간"을 아는 유일한 방법은 `Instance.Destroying`류 명시적 신호뿐 — 이런
케이스(타이머 시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive로
합의됨.

```
Effect(fn, state?) -> EffectHandle
```

**`state` 생략 시**: `fn()`을 즉시 1회 실행, 리턴값(`nil | () -> ()`)은
이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출. 재실행 없음
(mount/unmount 전용, React `useEffect(fn, [])`와 동형).

**`state` 지정 시(2026-08-07 여섯 번째 세션 확정)**: Effect는 내부적으로
`state:Observer(...)`를 감싸는 걸로 구현 — `fn`은 포지셔널 인자로 `state`를
받고(`fn(state)`, `:Compute`의 `fn(self)` 포지셔널-self 패턴 재사용,
모듈화 목적 — 클로저 캡처 없이 `fn`을 독립적으로 정의/재사용 가능
— **[2026-08-13 13차 세션 해소] 이 `fn(state)`가 lazy `State` 핸들을
받는다는 전제는 확정 유지.** 한때 `question.md` 0-Y가 `Effect`를 영향
대상으로 지목했으나, 실측 결과 **`Effect`는 애초에 무관**했음(자유
함수라 문제의 조건인 "재귀 타입의 필드 + 로컬 제네릭"에 안 걸림) —
`base/typing-limits.md` 1번 "영향 범위" 표 참고),
Observer가 이제 등록 즉시 1회 실행되므로(아래 Observer 절 참고) 그 첫
실행이 "설치"를 겸함. 이후 `state`가 무효화될 때마다 **직전 `fn` 호출이
리턴한 cleanup을 먼저 호출한 뒤 `fn`을 재호출**, 그리고 Effect가 바인드된
leaf가 죽을 때 **마지막 cleanup을 한 번 더 호출**. 결과적으로 React
`useEffect(fn, [dep])`와 동형(설치+재실행 사이/최종 cleanup 전부 같은
반환 계약 하나로 처리).

- **다수 의존성은 `:With(...)`로 먼저 하나의 State로 묶어서 넘길 것** —
  React식 별도 deps 배열을 새로 만들지 않음, quad가 이미 가진 다중 의존성
  결합 관용구(`base/source-state-plan.md` "`:With` + `:Compute`" 절)를
  그대로 재사용해 같은 일 하는 두 번째 경로를 안 만듦. **`Effect(fn, a, b,
  c)`처럼 trailing args로 바로 받는 sugar는 의도적으로 안 만듦**(2026-08-11
  세션, `source-state-plan.md` "`:Compute(fn, ...)` — 추가 의존성을 trailing
  args로 직접 받는 sugar" 절 참고) — `Compute`와 달리 Effect/Observer는
  자기 자신이 결과를 담는 State 노드가 아니라서, 의존성이 둘 이상이면 그걸
  합칠 **새 노드**(`:With`가 만드는 것)가 실제로 필요함. 그 비용을 sugar로
  감추지 않고 `Effect(fn, state:With(a,b,c))`처럼 코드에 그대로 드러내는
  게 의도된 선택.
- **`fn`은 커링 스타일도 권장(2026-08-07 여섯 번째 세션, 사용자 제안)** —
  `Effect(makeLogger("mount"), state)`처럼 팩토리 함수가 실제 `fn(state)`를
  만들어 반환하는 패턴, `Modifier`의 `Boldify(10)` 커링 관용구(`modifier-plan.md`
  8번)와 같은 결. `state:Observer(fn)`도 동일하게 커링 스타일을 권장 대상으로
  같이 문서화(아래 Observer 절 참고) — 모듈화가 필요하면 둘 다 이 패턴을 쓸 것.
- **재실행이 필요 없는 케이스와 혼동하지 말 것**: 값 변화와 무관하게 설치+최종
  정리만 필요하면 `state` 없이 `Effect(fn)`을 씀 — `state`를 굳이 넘겨서
  재실행을 유발할 필요 없음.

children 배열에 leaf로 놓는 기존 Observer 바인딩 패턴을 그대로 재사용(그
leaf가 살아있는 동안만 유효, leaf가 죽으면 최종 정리 콜백 호출). 비용은
leaf당 실제 Destroying 바인딩 하나(공유 weak table로 되는 Observer보다
비쌈) — 필요할 때만 쓰는 걸로 충분.

### 동적 경로 가드 — `k` 무관 매치, `HANDLER_PRIORITY_FALLBACK`

(2026-08-14 열한 번째 세션, `PreRef`/`Observer`와 같은 패턴, `base/
source-state-plan.md`의 "동적 경로 가드" 절 참고.) `EffectHandle`도
children 배열 리터럴 전용이라, 해시 파트 named 자리 등으로 동적으로
흘러들어오면 명확히 에러내야 함 — `{ priority = HANDLER_PRIORITY_FALLBACK,
isHandlable = function(inst,k,v) return isEffect(v) end, process =
function(inst,k,v) error(`Effect binding should be array index item, but
got {typeof(k)}`) end }`(**[2026-08-18]** 에러 메시지에 실제 `k` 타입을
실을 것 — `base/source-state-plan.md`의 "동적 경로 가드" 절).
`FALLBACK`인 이유도 동일 — 하드 블록이 아니라 나중에
named 자리 바인드 같은 실제 기능이 확정되면 평범한 우선순위의 Handler로
값싸게 override 가능한 자리로 열어둠.

**보강 — `EffectHandle`의 내부 Observer 바인딩 세부(2026-08-09 열한 번째
세션, 재확인 후 명시화)**:

- **`EffectHandle`은 내부 Observer를 필드로 강참조** — `handle._observer =
  observer`(`state`가 주어진 경우만 존재). 이건 GC 방지가 목적이 아니라
  (그건 아래 `bindLifetime`/`gchold`가 담당) `:Unsubscribe()`/`bindLifetime`
  cascade가 이 필드를 통해 내부 Observer에 접근하기 위한 것.
- **`bindLifetime(inst, handle)`은 `state`가 있는 경우 내부 Observer도
  같은 `inst`로 `bindLifetime(inst, handle._observer)`를 cascade해야
  함** — `Dispatch/Leaf.luau`가 children 배열의 `EffectHandle`을 매치해
  `bindLifetime(inst, handle)`을 부르는 시점(leaf 부착)과, `:Subscribe()`가
  `handle`을 전역 레지스트리에 등록하는 시점(아래) 둘 다 해당. 이유:
  `canExecute(observer)`가 보는 gcconn 참조는 **그 Observer 자신이
  `bindLifetime(inst, observer)`될 때 그 Observer 쪽 릴레이션에
  복사되는 것**이라, `EffectHandle`만 바인드하고 내부 Observer는 안 하면
  그 Observer에겐 판정 근거가 아예 없어서 `canExecute`가 항상 거짓이 됨
  (=재실행이 통째로 죽음). 같은 이유로 `unbindLifetime(handle)`도 내부
  Observer까지 같이 풀어야 대칭이 맞음.
  **[정정, 2026-08-14 다섯 번째 세션]** 이 항목이 원래 근거로 든
  "`canExecute`가 `Subscribed` 필드 + `inst`의 gcconn을 함께 본다"는
  틀렸음 — `.Subscribed`는 전역 `:Subscribe()` 전용이고 leaf 경로와
  무관(`archive/canexecute-inst-arg-reversed.md`). cascade가 필요하다는
  결론은 그대로이고 오히려 근거가 더 직접적이 됨.
- **`:Subscribe()`도 마찬가지로 `state`가 있으면 내부 Observer를 같은
  전역 강참조 레지스트리에 같이 등록**(`handle` 자신 + `handle._observer`
  둘 다, 또는 `handle._observer`만으로 충분한지는 구현 세부 — 어느 쪽이든
  "`EffectHandle`은 등록됐는데 내부 Observer는 등록 안 됨" 상태가 생기면
  안 됨).

**Observer 자체에 cleanup 반환 계약을 추가하는 안은 여전히 기각** — React
`useEffect`식으로 `fn`의 반환값을 자동으로 배선해주는 안을 검토했으나,
클로저 업밸류로 이미 충분해 채택 안 함. 이 기각은 위 Effect 설계와
상충하지 않음(그때 기각한 건 "Observer 자체에 이 복잡도를 넣지 말자"였지
패턴 자체의 무용함이 아니었고, `Effect`가 opt-in 상위 계층으로 정확히
이 패턴을 제공함) — 상세 경위는 `archive/observer-cleanup-contract-rejected.md`
참고.

## `EffectHandle:Subscribe()`/`:Unsubscribe()` — leaf 없이 쓰는 독립 Effect (2026-08-07 일곱 번째 세션)

**동기**: 지금까지 Effect의 유일한 생애주기 경로는 children 배열의 leaf
부착뿐이었음 — leaf 없이 `Effect(fn)`/`Effect(fn, state)`를 호출하면
설치(1회 실행)는 되지만 반환된 `EffectHandle`엔 아무 인터페이스도 없어서
cleanup을 트리거할 방법이 없는 막다른 길이었음. `state:Observer(fn)`가
이미 `:Subscribe()`/`:Unsubscribe()`(위 bind-system-plan.md 절)로 "children
배열 밖, 모듈/스크립트 레벨에서 독립적으로 켜고 끄는" 경로를 갖고 있는데,
Effect도 모듈/스크립트 사이드 이펙트(백그라운드 시스템, non-UI 코드가
quad의 반응형 그래프/cleanup 인체공학만 재사용하는 경우)로 쓰일 수 있어서
같은 결로 필요 — `Effect`도 leaf 없이 독립적으로 켜고 끌 수 있어야 함.

**확정**: `EffectHandle`에도 `:Subscribe()`/`:Unsubscribe()` 추가, 둘 다
`self` 반환(Observer와 동일한 fluent 대칭).

- **`:Subscribe()`** — Observer가 쓰는 것과 같은 강참조 레지스트리에
  자신(또는 `state` 있는 경우 내부 Observer)을 등록 — 새 메커니즘 아님,
  기존 레지스트리 재사용. 이후 로컬 변수로 참조를 안 들고 있어도 계속
  살아있음(Observer와 동일 관용구).
  - **⚠️ 용도는 완전히 top-level(모듈/스크립트 레벨, 어떤 Instance
    생명주기에도 안 묶인) 사이드 이펙트로 한정할 것 — 특정 `inst`에
    묶인 경우엔 leaf 부착(`bindLifetime`)을 쓰지 `:Subscribe()`를 쓰지
    않는 게 정상 경로.** `:Subscribe()`를 쓰기로 했다면(top-level이든
    의도적으로 다른 경우든) **반드시 `:Unsubscribe()`로 짝을 맞춰야
    함** — 강참조 레지스트리는 quad 전역의 "정리는 기본적으로 GC에
    위임" 원칙의 **의도적 예외**라, 로컬 변수 참조를 다 놓아도(스코프를
    벗어나도) **GC되지 않고 계속 실행됨**. 이건 quad의 다른 프리미티브
    대부분이 GC-native인 것과 정반대라 혼동하기 쉬운 지점 — 사용자
    문서에 명시적으로 경고할 것(`:Subscribe()`를 부르는 순간부터 그
    핸들의 생애주기는 전적으로 수동 관리 대상이 됨).
- **⚠️ [축소, 2026-08-18 구현 전 QA] `:Unsubscribe()`는 `:Subscribe()`의
  짝이다 — leaf 바인딩된 핸들에는 적용되지 않는다.** 아래 확장된 의미는
  **`:Subscribe()`로 등록한 핸들에 대해서만** 성립한다. `:Subscribe()`를
  부른 적 없는(=leaf 바인딩된) 핸들에 `:Unsubscribe()`를 지원하면 안 되거나,
  최소한 그 경로에서 cleanup을 앞당기면 안 된다.
  **[강화, 2026-08-20 구현 전 QA 4라운드 `E-11`] "안 되거나/최소한"이 아니라
  Observer와 정확히 같은 규칙으로 통일한다 — leaf 바인딩된 핸들에는
  `:Unsubscribe()`가 아예 안 먹는다.** 사용자 지적: *"옵저버에선 leaf
  바인딩에 Unsubscribe 못 하는것 처럼, Effect 또한 리프 바인딩에 있어서는
  Unsubscribe 안 먹어야 하는거 아님?"* — 맞다. `Observer`의
  `:Unsubscribe()`가 전역 경로 전용이고 leaf 해제는 `unbindLifetime`이
  담당한다는 게 이미 확정된 규칙인데(`base/source-state-plan.md`의 "이중
  바인딩 금지" 절), `Effect`만 애매하게 열어두면 두 프리미티브의 규칙이
  갈린다. **`State<Effect>` 재-dispatch와의 상호작용도 이 통일로 같이
  닫힌다** — leaf 바인딩된 핸들엔 `:Unsubscribe()`가 아예 안 먹으므로,
  아래 dedup 시나리오(값이 안 바뀌어 retract가 no-op인데 cleanup만
  앞당겨져 Effect가 조용히 죽는 것)가 발생할 경로 자체가 없어진다. 사용자 판정: *"subscribe
  한게 아니면 unsubscribe 는 지원하면 안 되거나, 적어도 리프 바운딩에선
  그래선 안 됨 … subscribe 는 unsubscribe 의 짝이라고 생각함."*
  - **왜 위험한가**: leaf 바인딩 + `State<Effect>`/`State<Observer>`
    조합에서, 값이 실제로 안 바뀌면 **dedup 최적화 때문에 retract가 아무
    일도 안 한다**(`base/source-state-plan.md`의 "Observer/Effect Leaf
    dedup" 절의 `old ~= v`). 그런데 `:Unsubscribe()`가 cleanup을 미리
    실행해버리면 뒤이은 재-dispatch에서 **dedup 때문에 재바인딩이 안
    일어나** 그 Effect가 조용히 죽은 채로 남는다 — 의도한 동작이 아님.
  - **⚠️ 같이 확인해야 할 별건(미해결)**: 그 dedup 경로에서 **retract가
    아무것도 안 한 뒤 `process` 쪽도 정말 아무것도 안 하는지** 대칭이
    실제로 성립하는지 확인 필요(사용자가 괄호로 남긴 것).
    `ObserverEffectLeafHandler` 의사코드 기준으론 `process`의
    `if old ~= v then bindLifetime(...) end`와 클로저의
    `if nextValue ~= v then unbindLifetime(...) end`가 짝을 이루지만,
    **`EffectHandle`은 내부 Observer로 cascade까지 해야 하므로** 그
    cascade가 dedup 분기 안에 제대로 들어가 있는지는 별도 확인 대상이다.
    M3 착수 전 확인할 것.
- **`:Subscribe()`한 핸들에서는 `:Unsubscribe()`가 Observer의 것을 그냥
  위임하지 않는다 — Effect 계층에서 의미가 확장됨.** Observer의
  `:Unsubscribe()`는 "미래 재실행만
  끊는다"(Observer 자체엔 정리할 상태가 없음)로 충분하지만, Effect의
  계약은 "생애주기가 끝나는 시점에 마지막 cleanup이 정확히 1회 호출된다"
  이고 leaf 사망은 그 "끝"의 신호 중 하나일 뿐이라, `:Unsubscribe()`도
  동일하게 "지금 끝났다"는 신호로 취급해야 계약이 일관됨:
  1. `state`가 있으면 내부 Observer도 `:Unsubscribe()`해서 향후 재실행을
     끊고,
  2. **직전(또는 유일한) cleanup을 정확히 1회 호출** — leaf가 죽을 때
     하던 것과 정확히 같은 이벤트를 수동으로 앞당기는 것.
  3. **idempotent, 그리고 이후 leaf가 실제로 죽어도 cleanup이 중복
     호출되면 안 됨** — 새 메커니즘 불필요, Observer가 이미 확정해둔
     `canExecute(value)` liveness 체크가 자동(리프=gcconn 참조)/수동
     (전역=`Subscribed` 필드) 두 경로를 하나의 게이트로 OR 묶어주므로
     여기 그대로 얹힘.
- **`state` 없는 mount-only Effect엔 특별한 분기 불필요** — install은 이미
  `Effect(fn)` 호출 시점에 끝나 있으므로, `:Unsubscribe()`는 그냥 "지금
  leaf-사망 cleanup을 수동으로 트리거"하는 것과 완전히 동치.
- **leaf 부착과 `:Subscribe()`를 동시에 쓰는 건 UB — 정정(2026-08-07
  일곱 번째 세션 후속)**: 처음엔 "같은 liveness 게이트를 공유하니
  동시에 써도 안전"으로 적었으나, 애초에 한 핸들은 라이프사이클 바인딩
  경로를 하나만 가져야 한다는 게 맞는 방향이라 판단이 뒤집힘 — 상세
  규칙과 `canBound(value)` 기반 즉시-에러 메커니즘(구 가칭 `Bound`
  플래그 → 2026-08-09 세션에 `canBound`로 명명 → 2026-08-14 다섯 번째
  세션에 `canBound` 폐기, `canExecute`로 통합 → **같은 날 열한 번째
  세션에 `canBound`가 별도 진입점으로 재도입**, 판정 로직은
  `canExecute`와 공유)은 `base/source-state-plan.md`의 "이중 바인딩
  금지" 절 참고. **[정정,
  2026-08-09 여섯 번째 세션] leaf 부착 후 조기 해제는 `:Unsubscribe()`가
  아니라 `unbindLifetime(value)`** — leaf 부착 자체가 내부적으로
  `bindLifetime(inst, value)` 호출이라, 그 해제도 짝인 `unbindLifetime`
  전용(`:Unsubscribe()`는 `inst`를 몰라 대신 처리 못 함) — 금지되는 건
  여전히 `:Subscribe()`(전역 경로)와 `bindLifetime`(leaf 부착 포함,
  inst-scoped 경로)을 **같이** 쓰는 것뿐.

## 해결됨 — Effect/Observer 관계 (2026-08-07 여섯 번째 세션, 이전 미해결 절 대체)

**과거 미해결이었던 두 질문 모두 확정**:
1. Effect는 자유 함수로 확정(`state:Effect(fn)` 메소드 아님) — 위 "Effect와
   Observer의 관계 확정" 절 참고. `state` 인자가 있어도 실제 leaf 생명주기
   바인딩을 `state`가 소유하지 않아서 메소드로 만들 필연성이 없었음.
2. `state:Observer(fn)`는 등록 즉시 1회 실행되는 것으로 확정(`base/
   bind-system-plan.md`의 Observer 절 참고) — 이 덕에 Effect가 `state`를
   받을 때 Observer를 그대로 조합해 재사용할 수 있게 됨(별도 "설치 시
   1회 실행" 로직을 Effect가 따로 만들 필요 없음).

`.claude/question.md`의 관련 항목도 해소됨으로 갱신 완료(그 항목은
이후 `archive/question-resolved.md`로 이전).
