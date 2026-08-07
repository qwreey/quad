# 구현 착수 직전 감사 — 모호성 / 지연결정 리스크 / 단순화 후보

**상태**: research — 사용자 상의 필요. 2026-08-06 세션에서 신설. `.claude/base/`
전체가 "확정"으로 표시돼 있지만, 실제 `ROADMAP.md` M0 착수를 앞두고 구현자
시점에서 다시 크리티컬하게 훑어본 결과. 방법론: `base/` + 근접
`research/`(tween-plan, ui-shorthand-plan, existing-instance-bind-plan)를
4개 클러스터로 나눠 서브에이전트로 병렬 정독시키고, 각각 세 가지 렌즈로
리뷰하게 했음 —

1. **모호성**: 실 구현 중 "이 경우엔 정확히 어떻게 동작하지?"라고 멈춰서
   다시 물어봐야 할 만한, 구체적 동작이 명시 안 된 지점.
2. **지연 결정 리스크**: 지금 "나중에 정해도 된다"고 취급되지만 사실 코어
   타입 구조/패키지 경계/데이터 모델에 깊이 얽혀 있어 나중에 바꾸면 연쇄
   파급이 클 것 같은 항목.
3. **오버엔지니어링/단순화 후보**: 확정됐다고 적혀 있지만 목적에 비해 과한
   추상화로 보이거나 더 간단한 대안이 있어 보이는 지점. (단, "이미 여러
   라운드에 걸쳐 검증됨"이라고 문서가 스스로 못박은 결정 자체를 재론하는
   건 배제 — `CLAUDE.md`의 반복 조사 금지 원칙과 같은 이유.)

이미 `.claude/question.md`에 취합된 항목(용어 재검토, M0 스파이크 항목
자체, Slot 형제 순서 보장 등)은 여기서 제외했다 — 아래는 **전부 새로 발견된
것**. 부수적으로 이 감사 과정에서 `architecture.md`의 stale한 부분 두 곳
(온톨로지 요약 절, 소스트리 `Store.luau`/`Ref.luau` 주석)을 발견해 같은
세션에서 바로 고쳤다 — 판단이 필요 없는 순수 문서 동기화라 여기 남기지
않고 해당 문서에서 직접 정정함.

## 어떻게 쓸 것

우선순위 1은 M0~M4 구현 도중 실제로 부딪힐 가능성이 높은 것 — **가능하면
M0 착수 전에 확인**. 우선순위 2는 지금 결정해두면 싼데 안 해두면 나중에
비쌀 것들 — 해당 마일스톤 착수 직전에만 확인해도 됨. 우선순위 3은 사용자
판단에 달린 단순화 제안. 문서 모순 절은 이미 고친 것과 아직 안 고친 것을
구분해뒀다.

---

## 우선순위 1 — M0~M4 착수 전 확인 권장

### 1-1. Tween이 "범용 store-bind 캐치올 핸들러"의 유일한 예시로 쓰여, 일반 반응형 프로퍼티 바인딩과 혼동될 위험

**위치**: `base/bind-system-plan.md` "확정된 디스패치 모델" 절 67-79행 —
"Tween의 store-bind 핸들러는 **`k`는 무엇이든 받고 `v`가 Store인 경우를
잡아내는, 우선순위가 매우 높은 핸들러**"; `architecture.md` 소스트리엔 이
역할을 하는 quad-roblox 파일이 `Handlers/Tween.luau` 하나뿐(별도 범용
StoreBind 핸들러 파일 없음); `ROADMAP.md` M11도 Tween을 "높은 우선순위
store-bind 핸들러"로 서술.

**문제**: 이 문서 전체에서 "v가 store인 값을 구독해 realv로 재귀 process
하는" 범용 메커니즘의 **유일한 구체 예시가 항상 "Tween"으로만 등장**한다.
그런데 Tween(실제 애니메이션, override/cancel 정책)은 `research/
tween-plan.md`라는 별개 리서치 문서와 별도 로드맵 마일스톤(M11)을 가진,
명백히 더 좁고 아직 미확정인 기능이다. `Frame { BackgroundColor3 =
store.color }`처럼 애니메이션 없이 그냥 반응형으로 값만 바뀌길 원하는
가장 흔한 케이스가 (a) 결국 이름은 "Tween"인 파일을 거쳐가며 "애니메이션
없음"으로 처리되는 건지, (b) Property/Tag/Attribute 등 각 핸들러가 각자
`Dispatch/StoreBind.luau`(quad-base, 범용) 유틸을 직접 써서 독립적으로
구현해야 하는 건지 문서가 정하지 않았다. `ROADMAP.md` M4("첫 end-to-end
반응형 업데이트")는 Tween 없이(M11보다 훨씬 전에) `Dispatch/StoreBind.luau`
만으로 "store 값 바꾸면 process가 다시 호출된다"를 검증하게 돼 있어 (a)는
아닌 것 같지만, 그럼 M11에서 Tween.luau가 실제로 추가될 때 그게 기존
경로와 **레이어링(우선순위로 얹힘)되는지 대체되는지**가 불명확하다.

**제안**: "일반 store-bind(애니메이션 없음)"와 "Tween 전용 store-bind
(애니메이션 있음)"가 같은 핸들러인지 별개 핸들러인지부터 확정. 별개라면
소스트리에 `Handlers/StoreBind.luau`(또는 유사) 항목을 명시적으로 추가하고,
`Tween.luau`는 그 위에 얹히는 "값에 tween 설정이 붙어있으면 가로채는" 더
높은 우선순위의 특수 케이스로 재정리하는 게 자연스러워 보임.

### 1-2. retract 시 "이전에 실제로 매치됐던 핸들러"를 누가 추적하는지 불명

**위치**: `base/bind-system-plan.md` "확정된 디스패치 모델" 절 90-91행 —
"store bind가 새 값으로 넘어갈 때 이전 핸들러의 `retract(inst, k, v)`를
한 번 호출해주면 됨."

**문제**: store-bind 재실행 모델에서 `realv`의 실질 타입은 매 갱신마다
바뀔 수 있다(예: 처음엔 숫자값이라 Property 핸들러가 매치, 다음번엔 다른
타입값이라 다른 핸들러가 매치). 이 경우 "이전 핸들러"가 정확히 어느
핸들러였는지는 `(inst, k)`별로 어딘가 기록돼 있어야 정확한 `retract`
대상을 찾을 수 있다. "핸들러 내부 상태 저장" 절은 "각 핸들러가 자기가
만든 것"(예: 실행 중인 Tween 객체)을 저장하는 패턴만 다루지, "이 키를
마지막으로 어느 핸들러가 담당했는가"라는 상위 레벨 라우팅 상태를 누가
(base 엔진 vs `Dispatch/StoreBind.luau` 래퍼) 관리하는지는 명시가 없다.

**제안**: `Dispatch/StoreBind.luau`가 "마지막으로 선택된 핸들러" 자체를
`(inst, k)`별 상태로 들고 있다가, 새 `realv` 처리 전에 그 핸들러의
`retract`를 호출하는 식으로 지금 결정해두는 게 좋아 보임 — M2/M4에서 바로
부딪힐 지점.

### 1-3. 우선순위 스캔의 동률 처리, 매치 실패 시 동작이 정의 안 됨

**위치**: `base/bind-system-plan.md` "핸들러 계약" 절 — "디스패치는 등록된
핸들러를 우선순위 순으로 스캔하며 `isHandlable`을 호출, 첫 매치가 처리."

**문제**: (a) 두 핸들러가 같은 `priority` 값을 가질 때 어느 쪽이 우선인지
(등록 순서? 정의 안 됨) 규칙이 없음. (b) 어떤 핸들러도 `isHandlable(k, v)`를
만족하지 않는 `(k, v)` 쌍이 들어왔을 때 — 조용히 무시? 에러? — 도 정의가
없음. 후자는 특히 사용자가 오타 키를 쓰거나 지원 안 되는 조합을 넣었을 때
디버깅 경험에 직결.

**제안**: 최소한 "매치 실패는 에러(silent 무시 금지)"만이라도 지금
결정해두면 구현 중 인터럽트를 막을 수 있음. 동률은 "등록 순서가 tiebreak"
정도로 명시만 해둬도 충분. M2(Dispatch 엔진) 착수 직전 확인.

### 1-4. provider(팩토리) 미주입 상태에서 dispatch가 호출되면 어떻게 되는지 세 번째 케이스가 빠짐

**위치**: `base/module-lifecycle-plan.md` "Bind는 누가, 어떻게 구현하는가"
절 — 재호출 가드는 "같은 팩토리=무시, 다른 팩토리=에러" 두 케이스로
확정됐지만, 이건 전부 "팩토리가 이미 한 번 실행된 이후" 얘기다.

**문제**: 원문이 처음 언급했던 세 번째 케이스 — **아직 아무 팩토리도 실행
안 된 상태에서 dispatch(`process`/`retract`)가 호출되는 경우**(예:
`InitRoblox` 호출 전에 컴포넌트를 마운트 시도)는 이후 어느 문서에서도 다시
다뤄지지 않았다. 이때 정확히 뭐가 일어나는지(명시적 에러 메시지 vs
nil-index 크래시 vs 조용한 no-op)가 안 정해져 있음.

**제안**: base dispatch 엔진이 "아직 provider 미주입" 상태를 감지해 명확한
에러를 던지도록 지금 결정해두면, 구현 중 흔한 초기화 순서 실수를 훨씬 덜
헷갈리게 만들 수 있음. 1-2번과 같은 타이밍(M2)에 같이 확정.

### 1-5. `props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴의 nil-hole 함정에 그대로 노출됨

**위치**: `base/component-composition-plan.md` "최종 결론" 1번 —
`return Frame { props.Modifier, props.Ref, ... }` 패턴.

**문제**: caller가 `props.Modifier`나 `props.Ref`를 안 넘기면 그 값은
`nil`이다. Lua 테이블 생성자에서 `{nil, refValue, child}`는 `t[1]`이
사실상 키 없는 상태가 되지만 `t[2]`, `t[3]`은 정상적으로 채워진다. 이때
디스패치 루프가 v1처럼 `ipairs`로 배열을 순회한다면 **`t[1]`이 nil이라는
이유만으로 `t[2]`(Ref)와 `t[3]`(자식)까지 통째로 무시**될 수 있다 — Ref
콜백이 조용히 안 불리고 자식도 안 그려지는, 원인 추적이 매우 어려운 버그
클래스. 이 문서가 정식으로 권장하는 forwarding 패턴 자체가 이 함정을
유발하는 전형적 모양인데 nil 처리 규칙이 전혀 언급되지 않는다.

**제안**: (a) 디스패치 루프를 `ipairs` 대신 `#t` 기반 명시적 인덱스 루프나
`table.pack`/센티널로 nil-safe하게 만들거나, (b) forwarding 관례 자체를
`Frame { Modifier = props.Modifier, Ref = props.Ref, [1] = child }`처럼
명시적 키로 넘기게 하거나, (c) 최소한 "props.Modifier/Ref가 nil일 수
있으니 배열 위치에 직접 넣지 말라"는 경고를 문서에 남길 것. **M0
스파이크가 이 패턴을 이미 검증 대상으로 잡고 있으니(`props.Modifier`/
`props.Ref` named-parameter 컴포넌트 작성), 그 스파이크 코드에 caller가
Modifier/Ref를 아예 안 넘기는 케이스를 반드시 포함시킬 것.**

### 1-6. `canExecute`/`Connected`의 실제 구현 방식이 미확정인 채로 코어 전역에 이미 재사용 확정됨

**위치**: `base/lifecycle-pattern.md` "2026-08-04 검증 라운드에서 보강된
내용" 절, 특히 "`Destroying` 훅은 생각보다 덜 중요할 수 있음" 부분.

**문제**: base는 "이 바인드가 아직 유효한가"를 묻는 인터페이스만 정의하고
quad-roblox가 구현을 채워넣는다고 되어 있는데, 후보 구현 방식들이 서로
다른 타이밍/정확도 보장을 갖는다 — `Instance.Parent == nil` 체크(단순하지만
"일시적으로 부모 없이 옮기는 중"일 때 false positive 위험), 저장해둔
`RBXScriptConnection.Connected`(정확하지만 "무엇에 Connect한 Connection을
기준 삼을지" 별도 결정 필요), `Destroying:Connect`로 세운 플래그(문서가
스스로 "덜 중요할 수 있다"고 약화시킴). 그런데 이 predicate는 이미 Slot
생존 확인·Observer 게이팅·store-bind retract 등 코어 전역에 "canExecute
하나로 통일" 원칙으로 재사용 확정돼 있다 — 즉 여러 하위 시스템이 의존하는
핵심 predicate의 실제 정확도 보장이 아직 안 정해진 채로 그 위에 여러 기능이
이미 "확정"되어 쌓인 상태.

부가적으로, `framework-comparison-findings.md`는 "Vide는 GC와
`Instance.Destroying` 발화 순서가 비결정적이라는 알려진 함정 때문에 의도적
eager cleanup을 택했다"는 구체적 위험을 지적하며 "quad는 rbvm 실물 검증
근거로 이 리스크가 완화됐다"고 적었지만, `lifecycle-pattern.md` 본문
어디에도 **"Destroying 발화 순서 비결정성"이라는 그 구체적 함정에 대한
분석이 없다** — rbvm 검증은 "GC-native 정리가 프로덕션에서 잘 돌아간다"는
것만 보여줄 뿐, "발화 순서가 신뢰 가능한가"라는 별개 질문엔 답하지 않는다.
리스크가 "완화됐다"는 문장이 실제로는 근거 문서 안에서 뒷받침되지 않음.

**제안**: M0 스파이크(또는 M0 직후, M2/M3 착수 전)에서 실제로 어떤 구현이
오탐 없이 동작하는지(특히 Reparent-but-not-Destroy 케이스, 여러 자식이
동시에 Destroy될 때 부모/자식 `Destroying` 발화 순서) 먼저 실측하고, 그
결과로 `lifecycle-pattern.md`의 애매한 서술을 확정 문장으로 교체할 것.

### 1-7. Slot의 `add`/`remove`/`clear` CRUD 의미론이 정의돼 있지 않음

**위치**: `base/slot-plan.md` "개념" 절 — "`add`/`remove`/`clear`/`get`/
`set` 등 뮤터블 연산을 지원하는 메타 배열"이라고만 서술.

**문제**: 실제 시그니처/의미론이 전혀 없다. 예: `remove`는 인덱스를
받는지 값(참조)을 받는지, 존재하지 않는 값을 remove하면 no-op인지
에러인지, `set(i, v)`가 기존 위치의 element를 retract하고 교체하는지,
`clear()` 중간에 개별 element의 retract가 실패(에러)하면 나머지는 계속
처리되는지 등. Observer 콜백이나 store-bind 재실행 안에서 `add`/`clear`가
재진입적으로 호출될 가능성도 있는데, 그 경우의 동작도 무정의.

**제안**: M6(Slot) 착수 시점에 CRUD 각 연산의 인자/반환값/에러 조건을
최소한 표로 확정해둘 것 — 이미 알려진 "여러 Slot 순서 보장" 논의와 같은
타이밍에 같이 정리하면 됨.

### 1-8. Slot "재마운트 시 throw"가 두 가지 다른 추적 대상을 혼용해서 서술됨

**위치**: `base/slot-plan.md` "핵심 제약: 소유권 귀속과 단일 마운트" +
"마운트된 Slot의 재마운트는 즉시 throw" 절.

**문제**: `isMounted`라는 용어가 두 가지 다른 대상에 쓰이는 것처럼 읽힌다
— (a) "한 인스턴스에 대한 다중 마운팅이 절대 일어나지 않도록 강제"는
**Slot에 담기는 개별 child element**가 두 곳에 동시 마운트되는 걸 막는
얘기, (b) "이미 사용된 slot을 재마운트하려 하면 즉시 error()"는 **Slot
컨테이너 자체**가 두 번째 바인드 지점에 쓰이는 걸 막는 얘기다. 둘은 서로
다른 추적 대상(개별 element vs Slot 객체)인데 문서는 하나의 "isMounted
관리"로 뭉뚱그린다. (b)의 트리거 시점도 미정 — `process(inst,k,slotValue)`
가 실제로 호출된 시점(핸들러 매칭)인지, Instance `Parent` 대입까지 끝난
시점인지에 따라 "컴포넌트가 Slot을 prop으로 받아 저장만 하고 실제로는
렌더하지 않는 경로"에서 오탐 throw가 날 수도, 반대로 진짜 이중 마운트를
놓칠 수도 있음.

**제안**: 두 추적을 명시적으로 분리(예: `Slot._mounted: boolean` vs
element별 weak-set) — throw 조건을 "Slot 핸들러의 `process`가 같은 Slot
객체에 대해 두 번째로 불렸을 때"로 명문화. M6 착수 시.

### 1-9. `LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그걸 필요로 함(로드맵 순서 역전)

**위치**: `ROADMAP.md` M8 "Ref" — `"LifetimeHandle 인터페이스 + quad-roblox
실제 구현(Instance 생존 확인)"`.

**문제**: `base/lifecycle-pattern.md`("생명 바인드 유틸"을 State-invalidate
리스너 클로저 등록에도 재사용)와 `base/slot-plan.md`(Slot의 `retract`가
같은 canExecute 패턴을 그대로 씀)는 둘 다 이 유틸을 State/Store 구독
(M3/M4 영역)과 Slot(M6)에서 이미 쓴다고 명시하는데, `LifetimeHandle`
인터페이스 자체는 M8에서야 정의된다. 즉 M4/M6이 개념적으로 필요로 하는
base 인터페이스가 그보다 늦은 M8에서 만들어지는 순서 역전.

**제안**: `LifetimeHandle.luau`(quad-base, 인터페이스만)를 M2(Dispatch
엔진) 또는 M3(Store/State)로 옮기고, M8은 "quad-roblox 실제 구현(Instance
`Connected` 기반)"만 담당하도록 분리. M1 mock에도 이 인터페이스의 트리비얼
스텁(항상 true)을 붙여두면 M4/M6 테스트가 자연스러워짐.

### 1-10. `store.key`의 레코드 필드 타이핑 검증이 M0가 아니라 M3로 밀려 있음

**위치**: `ROADMAP.md` M0 vs M3 `"store.key dot-access 타입 추론 확인"`.

**문제**: M0의 정의 자체가 "추론만으로 확정하고 실제 Luau로 부딪혀본 적
없는 것"을 검증하는 단계다. `base/store-semantics.md`가 요청한 M0 항목(
"Source가 State를 만족하는 제네릭 메소드 체이닝"의 솔버 안정성)은 이미
반영됐지만, 이건 `:Compute` 같은 제네릭 메소드 체이닝만 다루고 `{key:
Source<number>}` 같은 **레코드 필드로서의 dot-access 타이핑**(읽기/쓰기
대칭성 논거의 핵심 전제)은 별개로 M3에 남아있다. 같은 리스크 카테고리인데
M1(스캐폴딩)·M2(디스패치 엔진) 투자가 먼저 이뤄진 뒤에야 검증되는 셈이라,
여기서 걸리면 이미 만든 스캐폴딩/디스패치 타입 시그니처를 다시 손봐야 할
수 있음.

**제안**: M0 항목에 "`store.key`가 실제로 `Source<T>` 레코드 필드로
안전하게 추론되는지"도 같이 넣을 것 — 어차피 같은 스파이크 파일에서 몇 줄
추가로 검증 가능.

### 1-11. Modifier의 "제네릭 `__index` + `table.clone` 메타테이블 보존" 트릭이 검증 안 된 채 M7 전체 설계의 전제가 됨

**위치**: `base/modifier-plan.md` "런타임은 클래스별 코드 없이 base에 딱
하나만 있으면 됨" 절, `ROADMAP.md` M7.

**문제**: M7의 핵심 주장("base에 제네릭 `__index` 하나면 충분, FrameModifier
류는 순전히 정적 타입 체크용")은 `mod:FontSize(14)` → `__index(self,
"FontSize")`가 즉석 클로저를 리턴하고, `table.clone`이 메타테이블을 그대로
복사해줘서 체이닝이 안 끊긴다는 두 가지 Luau 동작에 전적으로 의존한다.
문서 자체가 "핵심 통찰"이라 부르지만 실제 Luau 코드로 확인된 적은 없다.
이게 틀리면 M7에서 "클래스별 런타임 코드 불필요"라는 설계가 무너지고
필드별 정적 등록 방식으로 되돌아가야 하는데, M7은 M0~M6 다 끝난 뒤라
되돌릴 때 비용이 큼.

**제안**: 검증 비용이 낮음(Modifier 없이도 순수 메타테이블 실험 몇 줄로
가능) — M0 스파이크 후보에 추가하거나, 최소한 "M7 착수 시점에 제일 먼저
확인"이라고 `ROADMAP.md`에 명시.

---

## 우선순위 2 — 지금 결정해두면 싼 것 (지연 결정 리스크)

### 2-1. Source가 State를 만족하는 제네릭 검증이 실패했을 때의 대안(Plan B)이 전혀 없음

**위치**: `base/store-semantics.md` "Source가 State를 만족함" 절 —
"검증 필요(확정 아님, M0 스파이크 대상)... 다만 이것도 추론이라 실제
Luau로 확인 전엔 확정 아님."

**문제**: 검증 필요성 자체는 이미 M0 항목이라 새 지적 아니지만, **검증이
실패했을 때 뭘 하는지가 문서 어디에도 없다.** 이 타입 구조(Source⊂State
서브타입)는 `store.key`의 반환 타입, `:Set()` 문법, `:Emit()`의 위치,
dot-access 타입추론, `RefSource` 폐기 결정까지 전부 이 위에 얹혀 있어서,
Luau 솔버가 막히면 되돌릴 범위가 `store-semantics.md`의 절반 이상에 걸침.

**제안**: M0 스파이크 계획에 "실패 시 폴백은 RefSource 부활 vs 다른 대안"
한 줄이라도 미리 박아두면, 실패했을 때 다시 사용자 자문을 구하느라 멈추는
걸 막을 수 있음.

### 2-2. `State<Modifier>` 타입 차단이 Luau에서 실제로 가능한지 검증 계획이 없음

**위치**: `base/modifier-plan.md` 7번.

**문제**: "가능하면 타입 시스템으로 아예 못 넣게 막을 것"이라 확정했지만,
Luau 제네릭은 "T가 특정 타입이면 거부"하는 부정 제약을 기본 지원하지
않는다. `store-semantics.md`는 이보다 단순한 `Source<T> satisfies
State<T>` 조합조차 M0 스파이크 대상(솔버가 죽을 수 있음)으로 잡아뒀는데,
이보다 어려운 문제(제네릭 타입 파라미터 배제 제약)인 `State<Modifier>`
차단은 어디에도 검증 대상으로 언급되지 않는다. 실제로 안 되면 "UB,
가능하면 타입 차단"이 조용히 "그냥 UB, 런타임 가드 없음"으로 후퇴하는데
그 fallback도 안 적혀있음.

**제안**: `ROADMAP.md` M0(또는 M7 착수 시점)에 이 케이스를 포함하거나,
최소한 `modifier-plan.md`에 "타입 차단이 Luau에서 불가능하면 순수 UB로
폴백"이라는 명시적 fallback 문장을 추가할 것.

### 2-3. Component 래퍼 필요 여부가 "이름만 남음"으로 후순위 처리됐지만 구조적 결정일 가능성

**위치**: `base/component-composition-plan.md` "남은 열린 질문" —
"`Component`(플레인 함수 규약이라 별도 래퍼가 필요한지 자체도 불확실 —
아마 불필요)".

**문제**: 다른 순수 네이밍 항목들과 동급의 후순위로 묶여 있지만, 이건 이름
문제가 아니라 **구조 문제**일 수 있다 — 래퍼가 있고 없고에 따라 (a) 정적
타입 체크 지점(`props.Modifier`/`props.Ref` 필수 필드 검증을 어디서
강제할지), (b) `quad-debug`가 요구하는 컴파일타임 소스 위치 주입(darklua)
훅 지점이 "함수 정의부"가 되는지 "매 호출부"가 되는지가 갈린다. 나중에
"역시 얇은 래퍼가 필요하다"로 뒤집히면, 이미 "그냥 함수" 규약으로 짜인
기존 컴포넌트 전체를 마이그레이션해야 하는 연쇄가 발생.

**제안**: `CLAUDE.md`가 이미 M2/M3/M5에서 quad-debug 훅 확장 지점을
고려하라고 명시해뒀으니, 그 시점에 이 질문도 같이 열어 "래퍼 없음"이
구조적으로도 최종 확정인지 한 번 더 확인할 것. M1 스캐폴딩 전에.

### 2-4. existing-instance-bind가 Slot의 "엄격한 단일 마운트 소유권" 불변식과 근본적으로 긴장

**위치**: `research/existing-instance-bind-plan.md` 전체 vs `base/
slot-plan.md` "핵심 제약: 소유권 귀속과 단일 마운트".

**문제**: 문서가 스스로 언급한 긴장(Modifier flatten의 clone 비용)과는
별개로 더 근본적인 긴장이 있다. `retract`는 "이전에 자신이 process한 것을
무른다"는 전제(quad가 자신이 만든 Instance를 생명주기 끝까지 들고 있는
소유자)로 설계됐는데, existing-instance-bind는 정의상 **quad가 한 번도
process한 적 없는 인스턴스**에 처음 바인드하는 시나리오다. 특히 Slot을 이
인스턴스의 children 제어에 쓰려는 경우 — 기존에 손으로 만들어둔 자식들이
Slot의 "own"한 대상인지 아닌지가 완전히 미정. 문서는 "핸들러 레지스트리가
이미 우선순위 스캔 후 bind 구조라 재바인드도 같은 경로를 타면 됨"이라고
낙관하지만, 이건 "새 값을 process하는 법"만 있으면 된다는 얘기고 "이
인스턴스에 대해 quad가 이전에 뭘 소유했었는지 모르는 상태에서 안전하게
재바인드하는 법"은 다른 문제다. 나중에 "기존 children을 흡수(adopt)하는
API"를 얹어야 할 때 Slot의 "own한 것만 CRUD 대상" 불변식 자체를 건드려야
할 수 있음.

**제안**: 착수 안 해도 되지만, "이 기능이 실제로 필요해지면 Slot의
소유권 모델에 '흡수(adopt)' 개념을 추가해야 할 수도 있다"는 캐비엇을
`existing-instance-bind-plan.md`에 한 줄 추가해둘 것 — 기존 "Modifier
flatten과 긴장" 캐비엇 옆에 병기.

### 2-5. `Modifier.Override`(구 `Merge`) 시 서로 다른 클래스의 Modifier가 섞이는 게 허용되는지 — **런타임은 해소, 타입 레벨은 여전히 미정**

**위치**: `base/modifier-plan.md` "2. Merge 우선순위" + 9번(`Override`) +
`base/component-composition-plan.md` 3번.

**[2026-08-07 다섯 번째 세션 갱신] 런타임 동작은 이제 명확함**: `modifier-plan.md`
9번에서 `Override`가 "필드별 raw 덮어쓰기"로 확정됐고, "Modifier는 핸들러
계층을 모름 — 순수 데이터 merge 레이어"(1번 절) 원칙도 이미 있었으므로,
**런타임 레벨에서는 대상 클래스가 다른 Modifier끼리 `Override`해도 막을
이유가 없음**(필드명만 보고 그대로 덮어쓸 뿐 — Luau 타입은 런타임에
강제되지 않는다는 점은 `store-semantics.md`에도 이미 명시된 전제).

**여전히 미정인 것 — 타입 레벨**: Modifier가 target 클래스별 제네릭
타입(`Modifier<Frame>` 등)이라면, `Modifier.Override<T>(mod1: Modifier<T>,
mod2: Modifier<T>): Modifier<T>`처럼 같은 `T`만 받도록 타입으로 강제할지,
아니면 공통 base 타입(여러 GuiObject 클래스에 걸친 공통 필드)과 클래스별
확장 사이의 계층 구조를 별도로 두고 `Override`가 그 계층을 넘나들 수
있게 할지는 아직 결정된 바 없음 — "공통 테마 Modifier + 클래스별 override
Modifier를 합친다"는 시나리오가 `Override`의 가장 그럴듯한 실사용
예시라 이 타입 설계가 실제로 막히면 바로 걸릴 문제.

**제안**: Modifier의 클래스별 typed 생성자 계층(2-8번과 같은 지점) 설계
시 `Override`의 제네릭 시그니처도 같이 확정할 것. M7 착수 시.

### 2-6. Modifier 필드에 State/Source를 인자로 넘기는 케이스가 세터 표에서 빠짐

**위치**: `base/modifier-plan.md` "4-1. 필드가 State일 수도 있음" 표.

**문제**: 표는 {필드: plain/State} × {인자: 리터럴/함수} 4칸만 다루는데,
"인자 자체가 State/Source"인 경우(예: `mod:FontSize(theme.fontSize)`처럼
이미 반응형인 값을 modifier 필드에 바인딩)가 없다. 상위에서 내려온 테마
색상을 Modifier 필드에 물리는 매우 흔한 패턴일 가능성이 높음. "리터럴"의
정의에 State 핸들도 포함되는지(포함된다면 필드가 State로 교체돼 반응형이
되는지) 불명.

**제안**: 표에 "인자=State" 행 2개(필드 plain/State 각각)를 추가해 명시할
것 — 아마 "clone 후 필드를 그 State로 교체(반응형 획득/전환)"가 자연스러운
답이지만, 함수 인자 케이스(`field:Compute(fn)`)와 어떻게 다른지 분명히 할
것.

### 2-7. 여러 Ref를 하나의 named parameter로 넘길 때 nested-array flatten 여부 불명

**위치**: `base/component-composition-plan.md` 3번(`Modifier.Override`,
구 `Merge`) vs "Ref는... 별도 결합 유틸 불필요" 문장.

**문제**: Modifier는 여러 개를 합치려면 `Modifier.Override`가 명시적으로
필요한데, 바로 다음 문장은 Ref는 "여러 Ref를 받으면 그냥 전부 실행하면
됨 — 별도 결합 유틸 불필요"라고 한다. `props.Ref = {ref1, ref2}`처럼
배열을 넘기면 리프 디스패처가 그 중첩 배열을 재귀적으로 펼쳐서 각 Ref를
인식한다는 뜻인지, 아니면 다중 Ref를 한 named parameter에 담아 넘기는
구체적 방법 자체가 여전히 안 정해진 것인지 불명확. 리프 레벨 디스패처가
배열 위치의 항목을 태그로 판별한다면, 항목 자체가 "배열"일 때 태그가
없어 인식 실패할 가능성이 있음.

**제안**: 리프 디스패처가 중첩 배열을 flatten하는지 명시적으로 확정하고,
다중 Ref를 넘기는 구체적 문법을 한 줄로 못박을 것. M8/M9 착수 시.

### 2-8. Modifier 클래스별 typed 생성자(`FrameModifier` 등)가 M5/M7 로드맵 어디에도 없음

**위치**: `base/modifier-plan.md` "5. 타입 출처는 이미 확정된 dot-access
관습 재사용" 절, `.claude/question.md` 1번.

**문제**: Modifier의 런타임 체이닝 엔진은 quad-base 소유가 맞지만, 클래스별
정적 타입 안전성(`Modifier.Rounded(8)`가 `FrameModifier` 타입으로 추론되는
것)은 "DI 쪽 '제네릭 생성자 함수 하나 + 자주 쓰는 것만 정적 필드' 패턴
재사용"이라 문서 스스로 밝히듯 quad-roblox의 DI 타입 생성 계층(M5)에 강하게
결합돼 있다. 그런데 `ROADMAP.md` M7 체크리스트(flatten-before-dispatch,
`Modifier.Override`, `State<Modifier>` 차단)엔 이 클래스별 타입 생성 작업이
전혀 없고, M5 DI 체크리스트에도 Modifier 언급이 없음.

**제안**: M5 또는 M7 체크리스트에 "quad-roblox 클래스별 typed Modifier
생성자(FrameModifier 등)" 항목을 명시적으로 추가해 누락을 막을 것.

### 2-9. 컴포넌트가 `props.Modifier`를 받아놓고 forward 안 하면 조용히 드롭됨 — 원칙 명문화 필요

**위치**: `base/component-composition-plan.md` "최종 결론" 1번, 3번.

**문제**: 저작자가 `props.Modifier`를 실수로(또는 의도적으로) 내부
`Frame{...}` 호출에 안 꽂아 넣으면 caller가 넘긴 modifier/ref는 조용히
사라진다. 타입 시그니처에 `props.Modifier: Modifier`가 선언돼 있어도
**실제로 그걸 쓰는지는 런타임/타입 어느 쪽도 강제 안 함** — "받았는데
안 쓰는" 실패 모드가 별도로 존재.

**제안**: 최소한 "무시되면 조용히 드롭된다(UB, 방어 로직 없음)"는 원칙을
명시적으로 못박을 것. 방어할 가치가 있다고 판단되면 컴파일타임 린트
(darklua) 후보로 `quad-debug`/문서화 백로그에 메모.

### 2-10. Tween 자연완료(Completed) 시 per-instance 북키핑 정리 여부가 명세 안 됨

**위치**: `research/tween-plan.md` "`retract`(구 cleanup)로 확정된
오버라이드 시맨틱" 절.

**문제**: "새 값이 들어와 갈아치울 때"의 `retract` 동작(4가지 옵션, 기본값
Cancel)은 상세히 정의했지만, **Tween이 사용자 개입 없이 스스로 끝까지
재생되어 자연 완료된 경우** per-instance weak-keyed 저장소에 남아있는
"이전 Tween 객체" 참조를 어떻게 다루는지는 언급이 없다. 남은 세 오버라이드
옵션(override-without-delete/delete-then-restart/move-to-end) 각각이
"이전 Tween이 아직 재생 중인가, 이미 끝났는가"에 따라 동작이 갈릴 수
있는데(예: "끝점으로 옮기고 새 트윈 시작"은 이미 완료된 Tween엔 의미가
이상해짐), 이 구분 로직 자체가 설계에 없음.

**제안**: Tween 핸들러가 생성한 Tween의 `Completed` 이벤트를 구독해
per-instance 저장소를 정리(또는 상태 플래그 갱신)하는지 여부를 명시.
M11 착수 시.

### 2-11. UI shorthand — 기존 UICorner 자식과의 매칭 기준(이름 vs 타입)이 불명, 사용자 실수 유발 위험 높음

**위치**: `base/ui-shorthand-plan.md` "v1 실제 메커니즘" 절.

**문제**: v1 메커니즘은 "기존 `UICorner` 자식이 있으면 재사용, 없으면
`Instance.new("UICorner", item)`(`Name = "_quad_round"`)"라고 서술되는데,
**이름으로 매칭**(quad가 이전에 만든 `_quad_round`만 재사용)인지 **타입으로
매칭**(자식 중 아무 `UICorner`나 있으면 재사용)인지 불명확. quad-v2 문서가
이 구분을 명시하지 않은 채 그대로 포팅 대상으로 재확정했다. 후자면
사용자가 직접 넣은(quad가 모르는) `UICorner`를 quad가 멋대로 바꿔버리는
부작용 경로가 생기고, 전자인데 사용자가 별도 이름으로 `UICorner`를 하나
더 넣으면 같은 GuiObject에 UICorner가 2개 존재하는 상태(Roblox에서 어느
쪽이 실제로 적용되는지 불명확)가 됨. 다른 항목들과 달리 이건 UB로 방치하기
엔 사용자가 실수하기 매우 쉬운 흔한 시나리오(디자이너가 UICorner를 수동
으로 넣어본 적 있는 프로젝트).

**제안**: "재사용 대상은 quad가 이전에 만든 고정 이름(`_quad_round`류)
자식으로 한정하고, 사용자가 별도로 만든 UICorner와는 아예 상호작용하지
않는다"는 규칙을 명시적으로 확정할 것. M10 전후 착수 시.

---

## 우선순위 3 — 단순화 후보 (사용자 판단 필요)

### 3-1. `:Compute(fn)`의 `previous` 인자 — 클로저 업밸류로 이미 되는 걸 별도 API로 만든 것일 수 있음

**위치**: `base/bind-system-plan.md` "`:Compute(fn)`의 선택적 두 번째
인자 — `previous`" 절.

**문제**: quad는 "렌더 함수가 계속 재실행되지 않고, `Compute`에 전달한
함수 자체가 한 번 등록되어 재계산마다 그 동일 클로저가 재호출된다"는
모델(문서 자체가 명시)다. 그렇다면 사용자가 `fn` 바깥에 `local prev`
업밸류를 두고 `fn` 안에서 그걸 읽고 갱신하면, 별도 `previous` 파라미터
없이도 정확히 같은 "직전 반환값 재사용" 효과를 순수 Lua 문법만으로 얻을
수 있어 보인다. 그런데 이 문서는 `previous`를 **별도 API 표면**(두 번째
인자)으로 만들었고, "능동적으로 계속 관측되지 않으면 조용히 영구
정지한다"는 상당히 위험한 캐비엇까지 별도로 문서화해야 할 만큼 무거운
기능이다. 왜 클로저 업밸류로 충분하지 않은지 근거가 안 보임.

**제안**: `previous` 인자를 유지할 근거(예: 업밸류 방식보다 타입 추론이
쉬워진다든가)가 있다면 한 줄 추가하고, 없다면 "그냥 클로저 업밸류를
쓰라"는 문서화 패턴으로 대체해 API 표면 자체를 줄이는 걸 검토.

### 3-2. Corner/PaddingAll/Scale 개별 Handler 대신 데이터 테이블 구동 단일 제네릭 Handler

**위치**: `base/ui-shorthand-plan.md` "메커니즘 — 새 아키텍처 개념
불필요" 절.

**문제**: 문서는 "Corner/PaddingAll/Scale 같은 특수 키를 인식하는
Handler"라고만 서술해, 사실상 3개의 거의 동일한 형태(리터럴 값 하나 →
고정 이름 자식 찾기/생성 → 프로퍼티 세팅)의 Handler를 각각 만드는
그림이다. 문서 자체가 "앞으로 비슷한 제안이 오면 이 선례를 따르라"고
일반화하고 있어, 향후 비슷한 shorthand가 추가될 때마다 Handler 파일이
선형으로 늘어나는 구조.

**제안**: `{key -> {ChildClassName, ChildDefaultName, Property, wrap=fn}}`
형태의 룩업 테이블 하나로 구동되는 단일 `Handlers/InstanceShorthand.luau`
로 통합하는 안을 검토. 새 shorthand 키 추가가 "테이블에 항목 하나 추가"로
끝나 M10 이후 유지보수 비용이 줄어듦. 강제 사항 아님, 구현 시점에 결정할
정도의 사소한 개선 후보.

---

## 문서 모순 — 발견 현황

### 이미 고침 (이번 세션)

- `architecture.md`의 "Store/State/Source 온톨로지 확정 요약" 절이
  `store-semantics.md`의 최신 재구성(Source가 State를 만족, `store.key`가
  Source를 직접 반환, `store.key:Set()`)을 못 따라가고 있던 것 — 이 감사
  세션 도중 발견해 직접 정정(커밋 `4b839b0`에서 별도로 이미 반영됨을 뒤늦게
  확인 — 같은 문제를 두 세션이 독립적으로 발견한 셈).
- `architecture.md` 소스트리의 `Store.luau`/`Ref.luau` 주석이 각각 옛
  `__newindex` 모델, 옛 "Ref=CreatedRef 자체" 정의를 그대로 담고 있던 것 —
  이번 세션에서 직접 정정.

### 아직 안 고침 (판단 필요해서 여기 남김)

- **`State<Modifier>` 타입 차단(엔지니어링 비용 감수) vs Ref/Slot이
  Modifier 필드에 들어가는 건 UB로 방치 — 같은 문서 안에서 정반대 원칙이
  나란히 적용됨.** `base/modifier-plan.md` "Modifier는 핸들러 계층을
  모름" 절은 "권장 사용법은 아니지만 막을 이유도 없음 — 방어 로직 없는
  UB로 남겨둠"이라 명시적으로 방어를 포기했는데, 바로 옆 7번 절은
  `State<Modifier>` 조합을 "UB로 확정, **가능하면 타입 시스템으로 아예 못
  넣게 막을 것**"이라며 정반대로 엔지니어링 비용을 들여 방어하기로 했다.
  두 결정 다 나름의 근거(후자는 "State에 담기면 재-flatten이 필요해져서
  정적 merge 전제와 정면 충돌"이라 더 위험하다는 논리로 보임)가 있어
  보이지만, 문서 어디에도 "왜 이 경우엔 원칙에서 예외로 처리하는가"를
  명시적으로 인정/정당화하지 않고 그냥 나란히 적혀 있다. 위 2-2 항목
  (Luau에서 실제 차단 가능한지)과 묶어서 같이 정리할 문제.
- **Destroying 훅 신뢰도에 대한 서술이 `lifecycle-pattern.md` 내부에서도,
  `framework-comparison-findings.md`와의 사이에서도 어긋남** — 위 1-6
  항목에 상세, 여기서는 "아직 아무도 하나의 확정 문장으로 정리 안 함"이라는
  사실만 문서모순 항목으로 남겨둠.

---

## 참고 — 감사했지만 문제없다고 확인된 것

- `component-composition-plan.md`가 예전 `StoreSource`/`RefSource`
  개념을 참조하는 채로 남아있진 않은지 확인 — 이미 "Source가 State를
  만족함" 최신 모델로 정정돼 있어 문제없음.
- `ROADMAP.md`에 `store.key = value`(구 `__newindex`) 모델을 암시하는
  잔여 표현은 없음 — M3/M4 서술 모두 문법을 명시하지 않아 최신 `:Set()`
  모델과 직접 충돌하는 곳은 없음.
- M9(컴포넌트 합성)이 M7(Modifier)·M8(Ref) 뒤에 오는 순서 — M9는 "M0
  스파이크(named-parameter 전달)를 정식 Modifier/Ref로 검증"하는 단계라고
  명시돼 있어 뒤늦은 검증이 아니라 의도된 정식화.
- `PerInstanceState` 실제 구현 시점(M8) — 이걸 필요로 하는 핸들러(Tag/
  Attribute/Tween)가 전부 M10/M11이라 순서상 문제없음.
- Slot의 store-bind 의존(M6→M4) 순서.

---

## 다음 액션 제안

- **M0 착수 전**: 1-5(props.Modifier/Ref nil-hole)를 M0 스파이크 코드에
  반영, 1-10(`store.key` 레코드 필드 타이핑)을 M0로 앞당기는 것 검토,
  1-11(Modifier `__index` 트릭)도 비용이 낮으니 M0 후보로 포함 검토.
- **M2(Dispatch) 착수 전**: 1-2, 1-3, 1-4를 한 번에 확정(전부 base
  dispatch 엔진의 에러/상태관리 규칙이라 같이 결정하는 게 효율적).
- **M2/M3 착수 전**: 1-6(canExecute 실제 구현) 실측, 1-9(LifetimeHandle
  마일스톤 재배치).
- **나머지**: 해당 마일스톤 착수 시점에 이 문서를 다시 열어 관련 항목만
  확인하면 됨 — 지금 전부 결정할 필요는 없음.
