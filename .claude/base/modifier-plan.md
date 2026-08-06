# Modifier 설계 (정적 merge, immutable 체이닝)

**상태**: base — 핵심 메커니즘(런타임 plug 아님/정적 merge, immutable
값+clone 기반 체이닝, 이중 setter)은 2026-08-04 세션 채팅 논의로 확정. 남은
건 getter 정확한 이름뿐(구현 단계). Modifier가 컴포넌트 경계를 어떻게
통과하는지(다중 루트, 상속 방식)는 별개 문제로
`research/component-composition-plan.md`의 열린 질문에 남음 — 이 문서는
"Modifier 값 자체가 어떻게 동작하는가"만 다룸.

## 문제

`base/architecture.md` 7번 항목("Style(Default) 시스템 폐기, modifier
지향")이 방향만 정하고, 실제 메커니즘은 미정이었음: 핸들러 레지스트리에
넣을 것인가, 여러 modifier가 같은 키를 건드리면 어떻게 되는가, 트리를
타고 내려가며 조금씩 변형되는 modifier(예: 문서 뷰어의 TextStyle 상속)를
어떻게 안전하게 다룰 것인가.

## 확정된 결론

### 1. 런타임 pluggable 핸들러 아님 — 정적 merge

Modifier는 `isHandlable`/`priority`/`process`/`retract` 핸들러 레지스트리에
안 들어감. 그냥 평범한 테이블(데이터)을 보유하는 값이고, 디스패치 들어가기
전에 한 번 평탄화(flatten)돼서 최종 props 테이블에 합쳐짐. 이유: 런타임
pluggable로 만들면 여러 modifier가 반응형으로 같은 키를 계속 다투는 CSS
cascade 문제가 그대로 오는데, 이건 이미 확정된 "Store 바인드 변경은 전체
교체, 부분 오버레이 없음"(`base/architecture.md` 3번) 원칙과 충돌함.

### 2. Merge 우선순위: 배열 순서와 인라인은 독립된 두 규칙

`Frame { modifier1, modifier2, Name = ... }` 평탄화 시:
(a) 배열에 나열된 modifier들끼리는 순서상 나중 것이 우선.
(b) 명시적 키(인라인)는 modifier가 뭘 하든 무조건 우선.
Lua 테이블 리터럴은 배열 파트/해시 파트 사이에 소스 텍스트 순서를 보존하지
않으므로 "순서상 나중이 이긴다"는 단일 규칙만으로는 구현 불가 — 반드시 두
규칙으로 쪼개야 함.

### 3. Immutable 값 + clone 기반 체이닝

컴포지션 트리를 타고 내려가며 조금씩 변형되는 modifier(문서 뷰어에서 상위
TextStyle을 상속해 타이틀만 1.2배 키우는 경우 — Jetpack Compose의
`TextStyle.merge()`/`CompositionLocal`과 동일한 use case)는 특히 위험함 —
mutable하게 구현하면 같은 modifier 레퍼런스를 공유하는 형제 서브트리가
오염되거나(한쪽이 mutate하면 다른 쪽도 영향받음), 재렌더 시 값이 누적
드리프트하는 버그가 생김(`.claude/question.md` 초기 논의의 "원본 테이블
덮어쓰기/루프 깨짐" 우려와 동일 클래스).

**해결**: 모든 변환 메소드(`:FontSize(...)`류 체이닝)는 내부에서
`table.clone(self)`로 새 테이블을 만든 뒤 필드만 덮어써 반환 — 원본은
절대 mutate하지 않음. 별도의 제네릭 clone 콤비네이터 타입
(`modifier<<Frame>>(modifier):Set` 류 아이디어)은 기각 — 그런 타입을 만들면
`base/architecture.md` 3번의 "복사 구현 지양, 필요한 곳만 팩토리 함수로
명시적 복사" 원칙을 다시 재작업하는 셈이라, 각 변환 메소드 자체가 그 원칙을
따라 알아서 최소한만 복사하면 충분.

**성능**: Luau `table.clone`은 native shallow-copy라 modifier 크기(보통
한 자리~여남은 개 필드) 기준 비용 무시 가능, 렌더/컴포지션 타임에만
발생(프레임마다 도는 게 아님). State가 이미 `:With`/`:Compute`마다 새
노드를 할당하는 것과 같은 급의 비용이라 일관되고, mutable+문서화 경고보다
오염 버그를 원천 차단하는 쪽이 라이브러리 복잡도/사용자 편의 양쪽에서
낫다고 판단 — **immutable 기본으로 확정**.

### 4. Setter는 리터럴 값과 변환 함수 둘 다 받음

`:FontSize(value)`(리터럴) / `:FontSize(function(current) return
current*1.2 end)`(변환 함수) 둘 다 지원 — 한 줄로 끝내고 싶을 때는 콜백,
여러 줄로 풀어쓰고 싶을 때는 현재 값을 getter로 꺼내 계산 후 리터럴로
다시 넣는 스타일 둘 다 인체공학상 필요하다고 판단.

변환 함수는 State의 `:Compute`처럼 lazy State 핸들을 넘길 필요가 없음(*필드가
순수 데이터인 일반적인 경우에 한해* — 필드가 State일 때의 예외는 아래 참고).
계산 비용 자체가 없는 순수 데이터라면 콜백엔 그냥 raw 현재 값을 즉시 넘기면
충분(State의 self-lazy-핸들 문제와는 다른 카테고리).

**내부 구현**: `__real` 같은 별도 래퍼는 불필요해 보임 — 데이터를 테이블에
직접 두고 메소드는 공유 메타테이블 `__index`로 붙이면, `table.clone`이
메타테이블까지 그대로 복사해주는 Luau 동작 덕분에 클론해도 체이닝이 안
끊김. flatten도 그 테이블 필드를 직접 읽으면 됨.

**Getter 정확한 모양은 미정** — `mod:Get("FontSize")` 같은 전용 메소드로
할지, 아니면 Store/DI 관습처럼 dot-access(`mod.fontSize`) 자체가 읽기
경로를 겸하게 해서 별도 `:Get()`이 아예 불필요하게 할지는 구현 단계에서
확정. **다만 getter의 동작 자체은 확정**: 필드가 State면 getter 호출이
곧 관측이라 그 순간 계산되어 확정된(더 이상 반응하지 않는) 값이 반환됨 —
`base/bind-system-plan.md`의 "관측해야 실체화된다" 전역 원칙 그대로 적용
(아래 참고).

### 4-1. 필드가 State일 수도 있음 — Setter가 State/plain 여부로 분기

`architecture.md` 7번 항목이 "함수형 modifier가 store 바인드를 받을 수도
있음"이라고 이미 언급한 대로, Modifier 필드는 plain 값뿐 아니라 State일
수도 있음(예: 상위에서 내려온 테마 색상이 Store에 바인드된 반응형 값).
이 경우 위 4번의 setter가 그대로 통하려면, **현재 저장된 필드 값이 State냐
plain이냐에 따라 setter 내부 동작이 갈려야 함** — 새 개념이 아니라 State에
이미 있는 lazy/`:Compute` 체이닝을 그대로 재사용하는 것뿐:

| 현재 필드 | 인자 | 동작 |
|---|---|---|
| plain | 리터럴 | clone 후 그 값으로 덮어씀 |
| plain | 함수 | clone 후 즉시 호출해 나온 값으로 덮어씀(현재 값이 raw로 넘어감) |
| **State** | **리터럴** | clone 후 **State를 통째로 리터럴로 덮어씀 — 의도적으로 반응성이 끊김**(Store의 "부분 오버레이 없음, 전체 교체" 원칙과 같은 결) |
| **State** | **함수** | clone 후 `field:Compute(fn)`으로 **새 파생 State**를 만들어 대입 — 반응성 유지, State의 기존 `:Compute` 메커니즘에 그대로 위임 |

즉 함수형 셋터는 필드가 State일 때 반응성을 보존하고, 리터럴 셋터(혹은
getter로 꺼내 계산 후 리터럴로 다시 넣는 멀티라인 스타일)는 그 순간 값을
확정시켜 반응성을 끊음 — 이 차이는 사용자가 인지하고 골라 쓰는 것으로
문서화.

### 4-2. Modifier는 소유권/유일성 제약이 없음

Modifier는 자식(child)을 담지 않음 — 마운트 정체성이 없는 순수 값. 그래서
어떤 컴포넌트가 특정 modifier를 실제로 적용하든 안 하든, 또 같은 modifier를
트리 여러 곳에 반복 적용하든 에러가 나지 않고 상관없음(Ref나 Slot 자식처럼
"정확히 한 곳에만 마운트돼야 한다"는 소유권 제약이 이들에게는 있지만
Modifier에는 없음).

### 5. 타입 출처는 이미 확정된 dot-access 관습 재사용

"누가 modifier에 타입을 붙여주냐"는 새 문제가 아니라, Store/인스턴스 생성에
이미 적용한 "정적으로 알려진 건 dot-access, 동적인 건 문자열 폴백" 프로젝트
전역 관습(`base/bind-system-plan.md` "타입 추론 문제" 절)을 그대로 적용하면
됨 — `Modifier.Rounded(8)`/`Modifier.FontSize(...)`처럼 DI 쪽 "제네릭
생성자 함수 하나 + 자주 쓰는 것만 정적 필드로 미리 바인딩" 패턴 재사용.
(주의: 이벤트는 이 관습의 유일한 예외라 인용 대상에서 제외 — 이벤트 바인딩은
PA님 방식인 문자열 키 + 런타임 리플렉션으로 감, `base/bind-system-plan.md`
"이벤트 바인딩 정정" 절 참고. Modifier는 이벤트가 아니라 Store/인스턴스
생성과 같은 카테고리라 dot-access 관습이 그대로 적용됨.)

`Modifier.Rounded(8)`가 실제로 어떻게 UICorner 자식을 만들어 붙이는지(v1의
`Corner` 특수 프로퍼티 선례, 핸들러 배치 소견)는
`research/ui-shorthand-plan.md` 참고 — 이 문서는 Modifier 값 자체의
동작만 다루므로 분리.

### 6. State/Pipe 쪽엔 영향 없음 — 이미 있던 결정의 재확인일 뿐

Modifier가 immutable해야 하는 이유(변환마다 clone)와 State가 이미
"`:With`/`:Compute`마다 새 노드를 만든다"(`base/bind-system-plan.md` 2차
라운드 확정)로 확정해둔 이유는 같은 클래스의 문제(공유 mutable 상태로 인한
오염 방지)임을 이번 논의에서 재확인했을 뿐 — State/Source 온톨로지 자체엔
변경 사항 없음. 파이프 분기(`:With(...):Compute(fn)`)는 이미 코드에
명시적으로 쓰는 구조라 "암묵적 분기"가 애초에 존재하지 않음 — 새로 결정할
것 없음.

### 7. State가 Modifier를 값으로 담는 것은 UB — 타입으로 막을 것 (2026-08-04, 로드맵 인수인계 라운드)

Modifier "필드"가 State일 수 있는 것(4-1번)과는 별개로, **State 자체의
value가 Modifier인 경우**(예: `someState:With(fn)`이 Modifier를 반환)는
지원 대상이 아님 — Modifier는 "flatten해서 한 번 적용"이 전제인 정적 값인데,
State에 담기면 그 값이 반응형으로 바뀔 수 있다는 뜻이 되어 매번 재-flatten이
필요해지고, 이는 "정적 merge" 확정(1번)과 정면으로 충돌함 — **사용자
확정**("state 안에 modifier가 있으면 그건 끔찍히 힘들꺼야... 타입 상 받지
못하게 만들어야 할 수도 있고"). **UB로 확정, 가능하면 타입 시스템으로
아예 못 넣게 막을 것**(`State<Modifier>` 같은 조합을 타입 정의 단계에서
거부) — 런타임 가드가 아니라 타입 차단을 우선 검토.

## 열린 질문 (`.claude/question.md`에도 취합)

- Getter 정확한 이름/모양(`:Get(key)` vs dot-access 겸용) — 후순위, 구현
  단계에서 다른 세부 API 이름들과 같이 확정 가능.
- Modifier가 컴포넌트 경계를 어떻게 통과하는지(다중 루트, 상속 방식)는
  `research/component-composition-plan.md`에서 계속 다룸 — 이 문서가 다루는
  "값 자체의 동작"과는 별개 문제.
