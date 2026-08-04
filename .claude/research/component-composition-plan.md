# 컴포넌트화 (Roblox 기본 오브젝트 이외의 사용자 정의 컴포넌트)

**상태**: research — 2026-08-04 세션 채팅 논의에서 핵심 골격 수렴, 세부
API 이름/modifier·Ref passthrough는 미정. 사용자가 "지금 quad에서 가장
문제되는 부분"으로 직접 지목한 주제. `base/bind-system-plan.md`의
Store/State/Source 온톨로지가 먼저 확정된 뒤에야 이 논의가 열림 — 그
문서가 선행 컨텍스트.

## 문제

v1의 `Class.Extend()`(Init/Render/AfterRender/Getter/Setter/UpdateTriggers,
`base/quad-v1-architecture.md` 참고)는 이미 OOP 상속 스타일이라 폐기
방향이지만, 그게 제공하던 실제 편의 기능(컴포넌트가 자기 store를 자동으로
가짐, props로 넘어온 State를 자동 흡수, `self:Default`/`self "key"`로
기본값·바인딩)까지 같이 버려도 되는지가 미결이었음. `MyComp {...}` 형태로
호출되는 사용자 정의 컴포넌트를 v2에서 어떤 모양으로 작성하게 할지가 핵심
질문.

## v1 실제 메커니즘 (조사 완료, `quad.qwreey.kr` 튜토리얼 + `initreq/quad/src/` 소스로 교차검증)

- `myStore "key"` → register(현재 State에 해당) 반환. `:Default(v)`/
  `:With(fn)`/`:Add(v)`/`:Tween(opts)` 체이닝 가능(`store.lua:433-457`).
- `Class.Extend()`의 `:Init(props)`에서 `props:Default("Size", v)`로 기본값
  설정, props 테이블 자체가 store 인스턴스로 변신(`class.lua:365-379`,
  `storeNew(prop,nil)`).
- props로 넘어온 값이 State(`quad_register`)면 `initStoreRegisterBinding`
  (`store.lua:394-431`)이 자동으로 감지해 컴포넌트 자신의 store 키에 재귀
  연결 — **자동 흡수 매직**이 실제로 존재했음.
- `self(name)` linker가 **두 가지 역할**을 겸함: (1) `self "_button"`을
  자식 자리에 넣으면 렌더링된 인스턴스를 `self._button`에 즉시 잡아둠(Ref
  역할) (2) `[Event.Prop "Text"] = self "Text"`로 인스턴스 프로퍼티 변경을
  다시 컴포넌트 store로 역방향 전파(양방향 바인딩, `EmitPropertyChangedSignal`
  자동 연결과 동일) — quad.qwreey.kr 튜토리얼 `11_extend/` 문서 원문 확인.

이 두 역할이 v2 온톨로지에서는 이미 갈라져 있음: (1)은 확정된 **Ref**가
대체, (2)는 이번 논의에서 다루는 Source 양방향 프록시가 대체.

## 수렴된 결론

### 1. 컴포넌트 = 그냥 함수, "자기 store 자동 소유" 매직은 폐기

`MyComp = function(props) return Frame {...} end`, 호출 규약은
`Frame{...}`와 동일(`MyComp{...}` → `MyComp(propsTable)`). v1의 Extend
자동-store-생성+자동-흡수 매직은 재현하지 않음 — 대신 React식으로 호출부가
State/raw/Source/콜백 중 뭘 넘길지 명시적으로 고름. 이유: 자동 흡수는
매 컴포넌트 호출마다 "이 prop이 State인가?" 타입 분기를 프레임워크가
암묵적으로 수행해야 하는 매직이고, 명시적 전달이 더 단순·예측 가능(React가
Vue/Svelte 대비 내세우는 강점과 동일 논리) — **사용자 확정**("마법 안쓴다
그것도 동의함").

### 2. State/Source 경계 규칙: 파생이면 읽기전용, 원본이면 쓰기 가능

State는 `:With`/`:Compute`로 만들어진 파생값일 수 있어 쓰기가 정의 자체가
안 됨. Source(독립이든 Store 소속 `StoreSource` 프록시든)는 파생이 아니라
항상 원본 슬롯 하나를 직접 가리키므로 쓰기가 의미 있음 — **사용자 확정**
("맞음. 확실해").

### 3. `StoreSource`: Source를 인터페이스+구현체로 두고, Store 키에서 그 인터페이스를 구현하는 얇은 프록시를 받음

- **Source = 인터페이스이자 구현체**: 독립 생성자 `Source(initial)`가 기본
  구현체, `store:GetSource("key")`(가칭)류 접근자가 반환하는 값은 같은
  인터페이스를 구현하는 별도의 얇은 프록시(`StoreSource`) — 읽기는
  `store.key`로, 쓰기는 `store.key = v`로 위임. **내부 Source 객체를 그대로
  노출하지 않음** — 그러면 "쓰기는 오직 Store의 `__newindex`뿐"이라는 기존
  확정과 새 쓰기 경로가 충돌하게 됨.
- **캐시 안 함**: State가 이미 "매번 새로 만듦, store에 캐시 안 됨"으로
  확정돼 있어 일관성 + 엔지니어링 비용 둘 다 이쪽이 쌈 — **사용자 확정**
  ("그냥 엔지니어링적으로 비용이 싼거 택해").

### 4. Source 직접 전달(양방향)은 핸들러 계약 확장 없이 타입 유니온으로 처리 — 단, 실사용 범위는 좁음

- 핸들러가 값을 받을 때 `Source<T> | State<T>` 유니온으로 받고, 내부에서
  타입 체크만 하면 됨(Source면 인스턴스 변경 이벤트에 걸어 역방향 쓰기까지
  처리, State면 읽기만) — `isHandlable`/`priority`/`process`/`retract` 4종
  계약에 5번째 항목을 추가할 필요 없음. Source 자체가 계산이 없는 원천이라
  가능한 단순화 — **사용자 확정**("그냥 타입 상 source를 받거나 state를
  받거나 하면 됨. source 자체는 원천이라 컴퓨팅 같은거 없어").
- **하지만 실사용은 좁을 것으로 예상**: `isEnabled`처럼 여러 조건에 영향
  받는(=파생된) 값은 애초에 State지 Source가 아니므로 이 경로로 못 넘김.
  즉 Source 직접 전달이 통하는 건 진짜 단순한 1:1 원본-토글 케이스뿐이고,
  일반적인 경우엔 React식 `value(State) + onChange(callback)` 패턴이 기본
  — **사용자 확정**("isenabled가 여러 조건에 영향 받으면 바로 문제가
  생기는거지. 따라서 실제 사용은 제한적일듯. callback을 쓰는게
  일반적이여 보이긴 해. 타입으로도 편하기도 하고 디버깅도 편함").

### 5. 리프(Roblox 프로퍼티) 바인딩엔 원칙적으로 State만

계산된 최종값만 실제로 인스턴스에 반영되어야 하므로, 리프 바인딩은 State가
일반 경로. Source는 리프 바인딩용 프리미티브가 아니라, 아주 단순한 구조에서
콜백 보일러플레이트를 줄이기 위한 좁은 용도의 예외 — **사용자 확정**
("리프 바인딩엔 state만 쓰이지 않을까... source는 그냥 아주 단순한
구조에서 콜백을 넣고 하는 복잡함을 줄이기 위함일 뿐임").

## 아직 열린 질문 (`.claude/question.md`에도 취합)

- **modifier/Ref가 컴포넌트 경계를 어떻게 통과하는가**: 컴포넌트가 플레인
  함수이고 반환하는 루트가 여러 개(혹은 Slot으로 갈라지는 구조)일 때, 호출부가
  넘긴 modifier/Ref가 "어느 루트로 가야 하는지" 모호해지는 케이스가 있음.
  Jetpack Compose는 언어 강제가 아니라 "컴포저블은 `modifier` 파라미터를
  받아 루트에 적용해야 한다"는 순수 관례(+린트)로 풂 — quad도 비슷한 관례
  기반으로 갈 수 있어 보이나 다중 루트 케이스는 미정. **주의: 이건 "경계를
  어떻게 통과하는가"의 문제이고, "modifier 값 자체가 어떻게 동작하는가"(정적
  merge, immutable 체이닝)는 `research/modifier-plan.md`로 이미 별도 확정됨
  — 둘을 혼동하지 말 것.**
- **정확한 API 이름**: `Component`(플레인 함수 규약이라 별도 래퍼가 필요한지
  자체도 불확실 — 아마 불필요), `GetSource` 계열 접근자 이름, `Source`
  독립 생성자 이름은 전부 가칭. `base/bind-system-plan.md`의 "남은 열린
  질문" 절(정확한 함수/생성자 이름 미정)과 같은 급의 후순위 항목.
- **`quad2-try`는 확인 불필요로 재확인** — 진행이 중단된 상태라 이 논의와
  무관.
