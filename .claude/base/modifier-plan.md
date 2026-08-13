# Modifier 설계 (정적 merge, immutable 체이닝)

**상태**: base — 핵심 메커니즘(런타임 plug 아님/정적 merge, immutable
값+clone 기반 체이닝, 이중 setter)은 2026-08-04 세션 채팅 논의로 확정.
**Getter는 별도로 안 만들기로 확정(2026-08-06 후속 세션)** — 아래 "4.
Setter는 리터럴 값과 변환 함수 둘 다 받음" 절 참고. **팩토리 함수 체이닝
(`:Apply`), 값 결합(`Overridden`, 구 `Merge`), 필드 읽기(`:Peek`)+판별
(`isState`)은 2026-08-07 세션들에 걸쳐 확정 — 8/9번 절 참고, 한 줄 요약은
`Apply`="변경을 수행", `Overridden`="이미 계산된 다른 mod를 합침".** Modifier가
컴포넌트 경계를 어떻게 통과하는지(named parameter로 전달, multi-root
개념 폐기)는 별개 문제로 **[정정] `research/component-composition-plan.md`는
2026-08-04 세션에 수렴 완료돼 `base/component-composition-plan.md`로
승격됨 — 이 문서는 "Modifier 값 자체가 어떻게 동작하는가"만 다룸.

## 문제

`base/architecture.md` 7번 항목("Style(Default) 시스템 폐기, modifier
지향")이 방향만 정하고, 실제 메커니즘은 미정이었음: 핸들러 레지스트리에
넣을 것인가, 여러 modifier가 같은 키를 건드리면 어떻게 되는가, 트리를
타고 내려가며 조금씩 변형되는 modifier(예: 문서 뷰어의 TextStyle 상속)를
어떻게 안전하게 다룰 것인가.

## 확정된 결론

### 1. 런타임 pluggable 핸들러 아님 — 정적 merge

Modifier는 `isHandlable`/`priority`/`process` 핸들러 레지스트리에
안 들어감. 그냥 평범한 테이블(데이터)을 보유하는 값이고, 디스패치 들어가기
전에 한 번 평탄화(flatten)돼서 최종 props 테이블에 합쳐짐. 이유: 런타임
pluggable로 만들면 여러 modifier가 반응형으로 같은 키를 계속 다투는 CSS
cascade 문제가 그대로 오는데, 이건 이미 확정된 "Store 바인드 변경은 전체
교체, 부분 오버레이 없음"(`base/architecture.md` 3번) 원칙과 충돌함.

**flatten이 배열 항목 중 뭐가 Modifier인지 판별하는 수단 — `isModifier`
(`Brand` 기반, 2026-08-07 열 번째 세션 명시).** 다른 모든 nominal 타입
판별과 같은 메커니즘(`bind-system-plan.md`의 `Brand` 절) 재사용 — flatten은
배열을 훑으며 `isModifier(v)`가 참인 항목만 필드를 뽑아 merge하고, 나머지는
전혀 안 건드리고 그대로 배열 파트에 남겨둠(그래서 `None`처럼 Modifier가
아닌 값은 flatten을 그냥 통과함 — `component-composition-plan.md`의
"필수 관용구" 절 참고).

관련: 이미 마운트된 Instance에 재바인드할 때 Default→실값 flatten을 다시
해야 하는지/clone이 필요한지는 별개 미정 문제로
`research/existing-instance-bind-plan.md`의 "Default 값과 얽히는 문제" 절
참고 — 여기서 다루는 건 컴포지션 타임의 modifier 값 자체 flatten이라 층위가
다름.

**참고 — Property(일반 프로퍼티)에 Attribute식 "이름 소유권 레지스트리"를
적용하는 안은 검토 후 기각(2026-08-12 열일곱 번째 세션).** `Attribute`
(`base/attribute-plan.md`)의 그룹 위임은 이름별 전용 키 객체가 "지금 이
이름을 누가 쓰고 있는가"를 스스로 추적해 충돌을 `error`로 잡아주는데, 이
패턴을 일반 Instance 프로퍼티(`BackgroundColor3` 등)에도 그대로 적용할 수
있을지 검토했으나 기각됨 — **Attribute 이름은 호출자가 자유롭게 짓는
네임스페이스라 자기 전용 키 객체를 새로 만들 수 있지만, Instance 프로퍼티
이름은 엔진이 이미 정해둔 유한 집합이라 호출자가 자기만의 전용 키를 새로
못 만든다.** 그래서 "이 프로퍼티를 지금 누가 소유하고 있는가"라는 질문
자체가 원천적으로 성립하지 않음 — 여러 modifier/컴포넌트가 같은 프로퍼티를
건드리는 게 오히려 흔한 정상 시나리오(테마 오버라이드 등)이기도 함. 이게
Property가 소유권 추적 대신 **덮어쓰기 우선순위(위 "2. Merge 우선순위"
절)**로 처리되는 이유 — 새로 결정한 게 아니라 이미 확정된 설계가 왜
그 모양인지를 명문화한 것.

### 2. Merge 우선순위: 배열 순서와 인라인은 독립된 두 규칙

`Frame { modifier1, modifier2, Name = ... }` 평탄화 시:
(a) 배열에 나열된 modifier들끼리는 순서상 나중 것이 우선.
(b) 명시적 키(인라인)는 modifier가 뭘 하든 무조건 우선.
Lua 테이블 리터럴은 배열 파트/해시 파트 사이에 소스 텍스트 순서를 보존하지
않으므로 "순서상 나중이 이긴다"는 단일 규칙만으로는 구현 불가 — 반드시 두
규칙으로 쪼개야 함.

### 2-1. 인라인 키로 modifier 필드를 명시적으로 "지우기" — `None` 센티널로 확정 (2026-08-07 여덟 번째 세션)

**문제**: `{ TextColor3 = nil, mod }`처럼 인라인 키로 modifier가 주는 값을
명시적으로 취소하고 싶어도, Lua 테이블 리터럴에서 `키 = nil`은 그 키
자체가 아예 존재하지 않는 것과 구별이 안 됨(`pairs`에서도 안 보임) — 그래서
위 2번 "인라인은 무조건 우선" 규칙이 실제로 작동할 근거(인라인 키가
존재한다는 사실 자체)가 사라지고, `mod`가 주는 값이 그대로 새어나옴.

**결론 — `None`은 raw 저장 계층에만 존재하는 실재값 센티널, merge/setter는
전혀 안 바뀜.** 이벤트 store-bind의 "`nil` 대신 실재하는 센티널"
(`false`로 disconnect, `base/bind-system-plan.md` "이벤트도 store-bind
가능" 절)과 같은 발상이지만, 처리 위치가 다름 — merge 단계가 아니라
**디스패치 단계**에서 풀린다:

- **`{ TextColor3 = None, mod }`도, `mod:TextColor3(None)`도 둘 다 지원.**
  Modifier setter/Overridden/인라인 props 테이블은 `None`을 그냥 평범한 raw
  값으로 저장·교체할 뿐 특별 취급이 전혀 없음 — 애초에 문제였던 건 "`nil`이
  테이블에 존재하는 값으로 표현이 안 된다"는 것뿐이라, 표현 가능한 실재
  센티널만 있으면 기존 merge 규칙("인라인 키 존재 시 무조건 우선",
  `Overridden`의 "뒤 인자가 필드 단위로 이김")이 손댈 것 없이 그대로 작동함.
  구현 비용이 사실상 0이라 인라인 키/setter 둘 다 여는 데 주저할 이유가
  없음(2026-08-07 여덟 번째 세션 확정) — setter로 받으면 "특정 필드만 지우는
  재사용 가능한 modifier 조각"(9-1번의 스타일 프리셋 opt-out 시나리오)도
  공짜로 됨.
- **`:Peek<<T>>(key)`의 반환 타입이 `T | State<T> | None | nil`로 확장됨** —
  `Peek`은 raw 저장값을 그대로 읽으므로(9번 절 "현재 저장된 그대로 넘김"
  원칙) `None`을 다른 값처럼 있는 그대로 돌려줌. "필드가 아예 안 채워짐"
  (`nil`)과 "명시적으로 지워짐"(`None`)은 raw 계층에서 계속 구별됨.
- **실제 "지우기" 동작은 디스패치 쪽 `NoneHandler`가 담당** — merge가 끝난
  뒤 최종 flatten 결과에 `None`이 남아있으면, base 드라이버가 그 키를 어떻게
  처리하는지는 새 개념이 아니라 이미 확정된 디스패치 모델 그대로다.
  상세는 `base/bind-system-plan.md`의 "`None` 센티널 — StoreBind와
  같은 재귀 재디스패치 패턴 재사용" 절 참고 — 핵심만 요약하면 `NoneHandler`도
  `StoreBind` 핸들러와 완전히 같은 모양(`isHandlable`이 `v == None`을
  잡고, `process`가 `v`를 진짜 `nil`로 바꿔 `process(inst, k, nil)`을 재귀
  호출)이라 base 드라이버 자체엔 `None`을 아는 코드가 한 줄도 안 들어감 —
  개별 프로퍼티/이벤트/UI shorthand 핸들러도 자기 시그니처에 `None`이 안
  나옴(원래도 있어야 했던 "`v`가 `nil`일 때" 처리를 재사용할 뿐). 구체 예시는
  `base/ui-shorthand-plan.md`의 UICorner 숏핸드 절(nil 받으면 만들어둔 자식
  제거, 단 `retract`가 아니라 `process` 쪽 로직).

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

**바닥 생성자 — `Modifier()`(필드 없는 빈 인스턴스, 2026-08-07 열 번째
세션 명시).** 지금까지 문서 어디에도 modifier 체이닝이 시작되는 첫
호출(`props.Modifier`처럼 이미 존재하는 modifier를 이어받지 않고 처음부터
만드는 경우)이 명시된 적이 없었던 갭 — `Source(default)`/`Ref(default)`/
`Store({defaults})`와 같은 "`Type(args)` 팩토리" 관습을 그대로 적용하면
됨, Modifier는 초기 필드가 필수가 아니므로 `args`가 비어도 되는
`Modifier()`. `mod:FontSize(20)`처럼 체이닝하는 모든 예시가 실은 이
`Modifier()`가 만든 빈 인스턴스 위에서 시작함. `base/store-semantics.md`
"독립 존재 가능한 프리미티브" 절의 예시 목록도 이걸로 갱신.

### 4. Setter는 리터럴 값과 변환 함수 둘 다 받음, 별도 Getter는 없음

`:FontSize(value)`(리터럴) / `:FontSize(function(current) return
current*1.2 end)`(변환 함수) 둘 다 지원 — 한 줄로 끝내고 싶을 때는 리터럴,
이전 값을 바탕으로 계산하고 싶을 때는 변환 함수 하나로 충분.

**Getter는 만들지 않기로 확정(2026-08-06 후속 세션).** 애초에 getter가
필요했던 유일한 이유가 "현재 값을 꺼내서 여러 줄에 걸쳐 계산한 뒤 리터럴로
다시 넣는" 멀티라인 스타일이었는데, `:FontSize(function(old) ... end)`
변환 함수 하나가 그 케이스를 인라인으로 완전히 커버함 — 별도 `:Get(key)`/
dot-access 겸용 여부를 고민할 이유 자체가 없어짐(모양을 정하는 대신
개념을 없애는 걸로 해소).

변환 함수는 State의 `:Compute`처럼 lazy State 핸들을 넘길 필요가 없음(*필드가
순수 데이터인 일반적인 경우에 한해* — 필드가 State일 때의 예외는 아래 참고).
계산 비용 자체가 없는 순수 데이터라면 콜백엔 그냥 raw 현재 값을 즉시 넘기면
충분(State의 self-lazy-핸들 문제와는 다른 카테고리).

**`old`는 항상 "현재 저장된 그대로" 넘김 — 일관된 원칙.** 필드가 plain이면
raw 값, State면 State 핸들 그 자체(아래 4-1 표의 "State + 함수" 행이
`field:Compute(fn)`으로 위임하는 것과 동일 — `:With`/`:Compute`의 self가
이미 raw 값이 아니라 State 핸들로 통일된 것과 같은 결). 별도 변환/정규화
없이 그냥 지금 들고 있는 걸 그대로 준다는 원칙 하나로 이 절과 4-1절 표가
전부 설명됨.

> **⚠️ [2026-08-13 3차 감사에서 발견]** 위 "State 핸들 그 자체"/`field:Compute(fn)`
> 위임은 `:Compute`/`:With`의 self-lazy-핸들 계약을 그대로 물려받음 —
> 그 계약 자체가 Luau 추론과 충돌한다는 게 `question.md` **0-Y**로 열려
> 있음(`base/bind-system-plan.md`의 동일 배너). 0-Y 결론에 따라 이 절의
> "State + 함수" 위임 방식도 같이 바뀔 수 있음.

**별도 `func(state) -> state` 인자 모양은 불필요(검토 후 기각).** "여러
Compute를 합치고 싶다"는 동기였는데, 이미 두 가지로 다 커버됨: (1) 여러
계산을 합치고 싶으면 변환 함수 본문 안에서 다른 함수를 그냥 호출하면
됨(평범한 함수 합성, 새 계약 불필요), (2) 필드 자체를 State로 만들고
싶으면 리터럴 자리에 State를 직접 넘기면 됨(위 4-1 표 "State" 행). 즉
"함수가 State를 반환"하는 세 번째 모양이 커버할 새 유스케이스가 없음.

**내부 구현**: `__real` 같은 별도 래퍼는 불필요해 보임 — 데이터를 테이블에
직접 두고 메소드는 공유 메타테이블 `__index`로 붙이면, `table.clone`이
메타테이블까지 그대로 복사해주는 Luau 동작 덕분에 클론해도 체이닝이 안
끊김. flatten도 그 테이블 필드를 직접 읽으면 됨.

**`table.clone`의 정확한 동작 — 확인됨(2026-08-12 열일곱 번째 세션,
`pre-implementation-audit.md` 1-11 해소).** 새 빈 테이블을 만들고 원본의
키를 네이티브 슬롯 단위로 복사(얕은 복사, 값 자체는 안 파고듦)한 뒤,
원본의 `getmetatable` 결과를 그대로 그 새 테이블에 `setmetatable` — **이
메타테이블은 복사되는 게 아니라 같은 참조를 공유**함. 그래서 위 제네릭
`__index` 함수(메타테이블에 딱 하나 있는 그 함수 자체)는 원본과 clone
사이에서 물리적으로 동일 객체이고, `mod:FontSize(14)` → `__index`가 리턴한
클로저가 `table.clone(self)`로 새 테이블을 또 만들 때도 그 새 테이블 역시
같은 메타테이블을 공유하며 체이닝이 끊기지 않음 — M7 전체 설계("클래스별
런타임 코드 없이 base에 제네릭 `__index` 하나면 충분")가 의존하던 두 Luau
동작(제네릭 `__index`가 임의 key를 잡아 클로저를 즉석 생성하는 것,
`table.clone`이 메타테이블 참조를 보존하는 것) 모두 공식 동작대로 확인됨.

**런타임은 클래스별 코드 없이 base에 딱 하나만 있으면 됨(2026-08-06 후속
세션, 핵심 통찰).** `mod:FontSize(14)`는 `mod.FontSize(mod, 14)`로 풀리는
문법 설탕이고, `mod.FontSize`는 `FontSize`가 **self의 리터럴 키로 절대 안
박히므로**(아래 ⚠️ — 이게 설계상 필수 조건이지 우연이 아님) 항상
`__index(self, key)`가 잡음 — 그러니 `__index`가 **어떤 key가 오든** 그
key를 클로저에 캡쳐한 `function(self, arg) local clone = table.clone(self)
... end`류 함수를 즉석에서 만들어 리턴하기만 하면 끝(단 그 clone은 필드를
self 최상위가 아니라 **내부 저장소**에 써야 함 — 역시 아래 ⚠️).

> **⚠️ [2026-08-13 여섯 번째 세션, 실측 중 발견] 필드 값은 `self`의 리터럴
> 키에 저장하면 안 되고, 반드시 `__index`를 거치는 내부 저장소에 둬야 함.**
> `__index`는 `rawget`이 **실패할 때만** 불리므로, `clone.FontSize = 14`처럼
> self 최상위에 값을 박아두면 다음번 `mod:FontSize(fn)` 호출에서
> `mod.FontSize`가 `__index`를 안 거치고 저장된 숫자 `14`를 그대로 돌려주고,
> `(14)(mod, fn)`이 되어 `attempt to call a number value`로 죽음. 위 4번
> 절의 "이전 값을 바탕으로 계산"(`mod:X(function(old) ... end)`)과 3번 절의
> "상위 TextStyle을 상속해 타이틀만 1.2배" 용례가 **정확히 이 재호출
> 패턴**이라 실사용에서 바로 터지는 경로임. 해법: 필드 데이터를 유일 테이블
> identity 키(`FieldsKey` 등)로 분리된 내부 테이블에 담고, `table.clone`이
> 얕은 복사라 setter 안에서 그 내부 테이블도 따로 `table.clone` 할 것.
> `luau-test/17`이 이 구조를 실측 검증함(원래 스파이크가 리터럴 키 방식으로
> 짜여 있다가 바로 이 이유로 크래시했고, 그 과정에서 이 문서의 "데이터를
> 테이블에 직접 두고"라는 표현이 두 가지로 읽힌다는 게 드러남). 즉 `:FontSize`/
`:Round`/앞으로 생길 어떤 필드 이름이든 전부 이 **하나의 제네릭 `__index`
구현**이 처리 가능 — 필드별로 미리 등록된 메소드가 하나도 없어도 됨.
**중요한 결론**: 위 "FrameModifier 타입" 문제(클래스별로 flat 타입을 생성기로
뽑아야 하는 것)는 순전히 **정적 타입 체크**를 위한 것이고, **런타임
구현에는 아무 영향 없음** — quad-roblox의 클래스별 코드 생성이 늘어나도
런타임 쪽 코드량은 절대 안 늘어남. 그리고 이 `__index` 메커니즘 자체는
Roblox API에 전혀 의존 안 하는 순수 Lua 테이블 조작이라, "base는 인터페이스만,
구현은 백엔드 팩토리가 주입"(`base/bind-system-plan.md`) 원칙과 무관하게
**Modifier의 체이닝 엔진 자체는 quad-base에 완결된 구현으로 그대로
존재해도 됨** — 주입할 엔진별 구현이 애초에 없음.

**Modifier 필드에 핸들러 계층 값(Ref/PreRef/Observer/Effect/Slot/
Modifier)이 들어오면 즉시 error — UB 아님(2026-08-09 세션, 정정).**
이전 버전("권장 사용법은 아니지만 막을 이유도 없음 — 방어 로직 없는
UB로 남겨둠")은 폐기. 재검토 근거(사용자): Modifier는 애초에 자식/Ref
같은 걸 다루는 목적이 아니고, 이런 값이 실제로 쓸모 있는 use case가
없다고 확인된 이상 조용한 UB보다 그 자리에서 막는 쪽이 낫다 — 판별
비용도 이미 있는 `Brand` 기반 predicate(`isRef`/`isPreRef`/
`isObserver`/`isEffect`/`isSlot`/`isModifier`, `bind-system-plan.md`의
`Brand` 절)를 그대로 재사용하면 되므로 거의 공짜.

- **체크 지점 — 제네릭 `__index` setter가 최종 저장 직전에 검사.** 위
  4번 절의 제네릭 setter(`clone[key] = value`, 또는 함수 인자면
  `clone[key] = fn(old)`, 4-1번 표의 State 분기 결과도 포함)가 실제로
  필드에 쓰려는 값을 확정한 직후, 그 값이 `isRef(v) or isPreRef(v) or
  isObserver(v) or isEffect(v) or isSlot(v) or isModifier(v)`를
  만족하면 `error`. 리터럴로 직접 넣은 경우든(`mod:SomeField(someRef)`류
  오용) 변환 함수가 반환한 경우든(`mod:X(function(old) return someRef
  end)`) 동일하게 걸림 — "콜백이냐 직접 실행이냐"를 구분하지 않고 최종
  저장값 하나만 보면 충분(사용자 제안).
- **State/Source는 여전히 허용** — 이 체크는 핸들러 계층 값만 잡음,
  4-1번 절의 "필드가 State일 수도 있음"과 안 부딪힘(`isState`가 참인
  값은 이 체크를 그냥 통과함).
- **한계, 명시적 UB로 남김(2026-08-09 열한 번째 세션) — `State<Ref>`류
  "State/Source가 담고 있는 값"이 핸들러 계층 값인 경우는 이 체크로
  못 잡음.** `isRef(v)` 등은 setter가 확정하는 바로 그 값(State 자체
  또는 plain 값)만 보므로, 값이 State/Source면 그 껍데기가 `isState`를
  통과해 검사를 그냥 지나가고, 그 State가 나중에 `:Get()`됐을 때 실제로
  내놓는 내용물(예: 그 State가 Ref/PreRef/Observer/Effect/Slot을 값으로
  들고 있는 경우)까지는 검사하지 않음 — 검사 시점엔 아직 실체화 안 된
  값이라 정적으로 알 수 없고, 값이 바뀔 때마다 매번 `:Get()`해서
  검사하는 건 관측 시점을 앞당기는 부작용까지 생기는 오버엔지니어링.
  **이 안쪽 케이스는 방어 로직 없는 순수 UB로 문서화만 하고 넘어감** —
  의도치 않게 자주 발생할 이유가 없는 조합이라 실사용 위험은 낮음.
- **7번 절(`State<Modifier>` UB)과의 비대칭이 이걸로 줄어듦** —
  `pre-implementation-audit.md`가 지적했던 "같은 문서 안에서 한쪽은
  방어(타입 차단 시도), 한쪽은 무방비 UB"라는 비일관성이, 이제 둘 다
  "적극적으로 막는다"는 같은 방향으로 정리됨(메커니즘은 여전히 다름 —
  하나는 타입 레벨 차단 시도+실패 시 UB 폴백, 하나는 런타임 `error` —
  이 차이 자체는 남지만 "막을 가치가 있는가"라는 판단은 통일됨).

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

즉 함수형 셋터는 필드가 State일 때 반응성을 보존하고, 리터럴 셋터는 그
순간 값을 확정시켜 반응성을 끊음 — 이 차이는 사용자가 인지하고 골라 쓰는
것으로 문서화.

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
됨 — `mod:UICorner(8)`/`mod:FontSize(...)`처럼 DI 쪽 "제네릭 생성자 함수
하나 + 자주 쓰는 것만 정적 필드로 미리 바인딩" 패턴 재사용.
(주의: 이벤트는 이 관습의 유일한 예외라 인용 대상에서 제외 — 이벤트 바인딩은
PA님 방식인 문자열 키 + 런타임 리플렉션으로 감, `base/bind-system-plan.md`
"이벤트 바인딩 정정" 절 참고. Modifier는 이벤트가 아니라 Store/인스턴스
생성과 같은 카테고리라 dot-access 관습이 그대로 적용됨.)

`mod:UICorner(8)`가 실제로 어떻게 UICorner 자식을 만들어 붙이는지(v1의
`Corner` 특수 프로퍼티 선례, 핸들러 배치 소견)는
`base/ui-shorthand-plan.md` 참고 — 이 문서는 Modifier 값 자체의
동작만 다루므로 분리.

### 6. State/Pipe 쪽엔 영향 없음 — 이미 있던 결정의 재확인일 뿐

Modifier가 immutable해야 하는 이유(변환마다 clone)와 State가 이미
"`:With`/`:Compute`마다 새 노드를 만든다"(`base/bind-system-plan.md` 2차
라운드 확정)로 확정해둔 이유는 같은 클래스의 문제(공유 mutable 상태로 인한
오염 방지)임을 이번 논의에서 재확인했을 뿐 — State/Source 온톨로지 자체엔
변경 사항 없음. 파이프 분기(`:With(...):Compute(fn)`)는 이미 코드에
명시적으로 쓰는 구조라 "암묵적 분기"가 애초에 존재하지 않음 — 새로 결정할
것 없음.

### 7. State/Source가 Modifier를 값으로 담는 것 — 명시적 error로 확정 (2026-08-04 신설, 2026-08-09 세션 정정)

Modifier "필드"가 State일 수 있는 것(4-1번)과는 별개로, **State/Source
자체의 value가 Modifier인 경우**(예: `someState:With(fn)`이 Modifier를
반환하거나 `someSource:Set(someModifier)`)는 지원 대상이 아님 — Modifier는
"flatten해서 한 번 적용"이 전제인 정적 값인데, State/Source에 담기면 그
값이 반응형으로 바뀔 수 있다는 뜻이 되어 매번 재-flatten이 필요해지고,
이는 "정적 merge" 확정(1번, "Modifier는 런타임 pluggable 핸들러가 아니라
dispatch 밖에서만 처리되는 유일한 존재")과 정면으로 충돌함 — **사용자
확정**("state 안에 modifier가 있으면 그건 끔찍히 힘들꺼야... 타입 상 받지
못하게 만들어야 할 수도 있고").

**[정정, 2026-08-09 세션] "UB, 가능하면 타입 차단"에서 "명시적
`error`로 확정"으로 전환** — 위 "핸들러 계층 값이 필드로 들어오면
즉시 error" 절(Ref/PreRef/Observer/Effect/Slot/Modifier가 Modifier
*필드*로 들어오는 걸 막은 것)과 같은 방향으로 통일: `isModifier`
predicate(`Brand` 절)를 State/Source 쪽에도 적용해 **런타임에 직접
막는다.** 타입 차단(`State<Modifier>` 같은 조합을 타입 정의 단계에서
거부)은 여전히 되면 좋은 보너스로 계속 시도해볼 수 있지만
(`research/pre-implementation-audit.md` 2-2 — Luau에서 실제로 가능한지
미검증), **더 이상 유일한 방어선이 아님** — 타입이 뚫려도 런타임
`error`가 항상 잡아준다.

- **적용 지점**: "어떤 값이 Source/State의 현재 값으로 확정되는 모든
  지점" — `Source:Set(value)` 호출 시, `Store({defaults})` 생성 시
  각 `defaults` 키를 `Source(v)`로 만드는 시점, 그리고 State의
  `:Compute(fn)` 결과를 캐시로 저장하기 직전(`fn`이 반환한 값이
  `isModifier`면 캐싱 전에 `error`). 새 체크 지점을 여러 곳에 흩는 게
  아니라, "값이 State/Source의 값으로 확정되는" 이미 존재하는 몇 안
  되는 지점에 `isModifier` 검사 한 줄씩 얹는 것뿐.
- **Slot/Tag/Attribute 등 다른 핸들러 계층 값은 여전히 아무
  문제 없이 State/Source에 담길 수 있음 — Modifier만의 예외임을
  명확히.** (사용자 확인: "slot은 당연히 가능함, retract도 되는 애고
  런타임 값이라") 이 값들은 전부 정상적으로 `process`/`retract`
  재귀 경로(store-bind 재실행 모델, "확정된 디스패치 모델" 절)를 타는
  진짜 런타임 dispatch 참가자라, State/Source 값으로 담겨 바뀌어도
  기존 재귀 재-dispatch 메커니즘이 그대로 처리해줌 — 새로 막을 이유가
  없음. Modifier만 유독 문제인 건 Modifier가 애초에 dispatch 경로를
  아예 안 타는 유일한 존재(1번 절)라서, State/Source에 담기는 순간
  "재귀 재-dispatch로 처리"할 대상 자체가 없어지기 때문 — 이 구분이
  왜 Modifier만 막고 나머지는 다 허용하는지의 핵심 근거. **[정정,
  2026-08-10 세션] `Tween`은 이 그룹에서 빠짐** — Tween이 독립 Dispatch
  핸들러(`process`/`retract`를 가진 dispatch 참가자)에서 PropertyHandler가
  소비하는 값-레벨 래퍼로 재설계되며(`base/tween-plan.md`), `Tween<T>`는
  이제 `process`/`retract`가 없는 순수 raw 데이터 값 — `None`과 같은
  분류. State/Source에 `Tween<T>`가 담기는 것 자체는 여전히 문제없이
  허용되지만(위 타입 대수 절 참고), 그 이유는 "재귀 dispatch 참가자라서"가
  아니라 "그냥 raw 값이라서"로 바뀜.
- **`Store<T>`의 `T`는 Modifier가 될 수 없음(`base/store-semantics.md`
  "따름정리" 절)도 이 결정을 그대로 물려받음** — Source가 State를
  구조적으로 만족하므로 별도로 다시 논증할 필요 없이 동일하게 적용됨.

### 8. `:Apply(factory)` — 팩토리 함수 체이닝 지원 (2026-08-07)

**동기**: 재사용 가능한 스타일 프리셋을 만들고 싶을 때(예: `Boldify(mod)
-> mod`처럼 어떤 modifier든 받아 기본값보다 더 두껍게 만들어 돌려주는
함수, 커링해서 `Boldify(10)(mod) -> mod`처럼도 씀) 이런 "modifier
팩토리"를 체이닝에 자연스럽게 끼워 넣을 방법이 없었음 — 팩토리를 직접
호출하면 `Italicify(Boldify(10)(mod:FontSize(14)))`처럼 안에서 밖으로
쌓여 읽는 순서가 실행 순서와 반대로 뒤집힘.

**결정**: `mod:Apply(factory)`를 지원 — `factory`는 그냥 `Modifier ->
Modifier` 평범한 함수(커링된 클로저 포함, 새 타입 개념 아님). 동작은
`function(self, factory) return factory(self) end`이 전부. 이걸로
`mod:FontSize(14):Apply(Boldify(10)):Apply(Italicify)`처럼 필드
setter 체이닝과 팩토리 적용을 같은 fluent 문법 하나로 섞어 쓸 수
있음 — 읽는 순서 = 적용 순서.

**왜 좋은 아이디어인가**: Jetpack Compose의 커스텀 `Modifier` 확장 함수
패턴(`fun Modifier.myStyle(): Modifier = this.then(...)`)과 동일한
효용(모듈화된 스타일 프리셋을 라이브러리로 나눠 배포/재사용, 체이닝으로
조합)을 Luau엔 확장 함수 문법이 없으니 `:Apply` 콤비네이터로 흉내낸 것.
새 개념을 추가하는 게 아니라 "펑션도 그냥 값"이라는 Lua 특성과 이미 있는
immutable clone 체이닝(3번)에 얹는 얇은 sugar라 구현/개념 비용이 거의
없음 — 팩토리 자신이 내부에서 이미 `:FontSize(...)` 같은 필드 setter를
호출해 clone된 새 Modifier를 반환하므로, `Apply` 자체는 clone할 필요조차
없음(`factory(self)`가 이미 새 값을 만들어 줌).

**구현 시 주의**: `Apply`는 제네릭 `__index`가 즉석에서 만들어주는 필드
setter 클로저(4번)와 이름이 겹치면 안 됨 — `__index`가 고정 메소드
테이블(현재는 `Apply` 하나)을 먼저 확인하고, 없을 때만 필드 setter를
합성하도록 구현. 따라서 **`Apply`는 Modifier 필드 이름으로 예약됨**(실제
스타일 프로퍼티 이름과 겹칠 일은 거의 없어 보이지만 문서화 필요).

**권장 관용구, 문서화 필요(2026-08-07 다섯 번째 세션)**: 특정 modifier를
계속 변형/보정하고 싶은 경우(스타일 프리셋, 커링된 팩토리 등)엔 항상
`Apply`를 기본 선택지로 유도할 것 — 아래 9번의 `Overridden`는 "이미 따로
만들어진 modifier 값 두 개 이상을 합쳐야 하는" 경우로만 좁혀서 문서화(용도
구분 절 참고).

**`Apply`는 `factory(self)` 그 이상도 이하도 아님 — 특별한 계약 없음,
문서화 필요.** `factory` 내부가 `Peek`으로 State를 기대했는데 없다고
`error`를 던지거나, 특정 조건에서 그냥 죽어버리는 것도 `Apply` 입장에선
아무 문제 아님 — `Apply`는 `factory`가 뭘 하든 관여하지 않는 순수 함수
호출 sugar일 뿐이라, 유효성 검사/기본값 처리/에러 핸들링은 전부 `factory`
저작자 책임. 문서에는 "`:Apply(f)`는 `f(mod)`를 체이닝 문법으로 쓴 것뿐,
Apply 자체가 뭔가를 검증하거나 보장해준다고 오해하지 말 것"을 명시.

### 9. Modifier 결합 — `Modifier.Overridden(mod1, mod2, ...)`, `:Peek`, `isState` (2026-08-07 다섯 번째 세션)

**배경**: `base/component-composition-plan.md` 3번 절이 이미 "여러
modifier를 하나로 합치는 공개 유틸이 필요하다"고 확정하며 `Modifier.Merge`
가칭을 남겨뒀었음(컴포넌트 경계는 `props.Modifier` named parameter 단일
슬롯이라, 리프 레벨 `Frame{mod1, mod2}` 배열 flatten이 거기까진 안 닿아서
생기는 진짜 필요 — `Apply`만으로는 안 풀림: `Apply`는 팩토리 함수를 받는
콤비네이터라, 이미 따로따로 만들어진 modifier *값* 두 개를 하나로 합치려면
호출부가 그 값 중 하나를 즉석에서 팩토리로 다시 쓰도록 강제하게 됨 —
`Apply`로 완전 대체/강제 통합하는 방안도 이번에 검토했으나 이 실사용
니즈를 못 풀어서 기각). 이번 세션에서 실제 동작을 확정.

**이름 변경**: `Merge` → **`Overridden`로 확정**(사용자 제안). "Merge"는
중립적 합침을 암시하지만 실제 동작은 명시적으로 나중 인자가 이기는
"덮어쓰기"라, 이름이 의미를 정직하게 반영해야 함 — `component-composition-plan.md`의
참조도 이번에 같이 갱신함.

**용도를 좁게 문서화할 것 — "진짜 합칠 필요가 있는 경우"로 한정
(2026-08-07 다섯 번째 세션, 사용자 강조).** `Overridden`는 범용 조합
도구가 아니라 `Frame{mod1, mod2}`의 컴포넌트 경계판, 그 이상도 이하도
아님 — 이게 없으면 `props.Modifier` 같은 단일 슬롯에 여러 독립 modifier
값을 넣을 방법이 아예 없어지므로 프리미티브로 남겨두는 것뿐. **"특정
modifier를 계속 바꿔나가고 싶다"는 요구는 `Overridden`가 아니라 위 8번
`Apply`로 풀도록 유도** — 간결한 커링/일급 함수 전달이 기본 관용구가
되도록, API 문서에서 `Overridden`를 "값 두 개 이상을 합쳐야 하는 특수
상황"으로만 소개하고 스타일 변형/보정의 기본 진입점으로는 절대 먼저
보여주지 않을 것.

**동작 = 기존 flatten을 함수로 노출한 것, 새 규칙 없음.**
`Modifier.Overridden(mod1, mod2, ...)`는 뒤 인자가 필드 단위로 이긴다(2번
절 "배열 순서" 규칙과 동일). 구현은 단순 필드별 덮어쓰기 — 특별한
State/함수 분기가 필요 없음: setter가 이미 호출 시점에 함수를 즉시
실행하고 State 필드는 즉시 `:Compute`로 파생시켜 저장하므로(4번/4-1번),
Modifier가 들고 있는 모든 필드는 항상 "그 시점에 이미 완전히 처리된
(baked) 값"임 — `Overridden`는 그 baked 값을 필드별로 그대로 교체할 뿐.

**경고, 반드시 문서화**: baked 값 교체는 그 필드에서 파생된 다른 필드에
소급 반영되지 않는다. 예: `Boldify`가 `Font` 필드를 읽어(`Peek`, 아래
참고) `FontWeight`를 계산해 넣어둔 modifier를, 나중에 `Font`를 바꾸는
다른 modifier와 `Overridden`로 합치면 `Font`는 새 값으로 바뀌지만
`FontWeight`는 예전 `Font` 기준으로 계산된 채 그대로 남는다 — 사용자
실수 범주지만 조용히 틀린 결과가 나오는 케이스라 API 문서(경고 박스)로
명시 필요. `A:Overridden(B)`와 `B:Overridden(A)`가 다른 결과를 낸다는 순서
의존성도 같은 경고 박스에 같이 명시.

**용도 구분 — `Apply` vs `Overridden`, 둘 다 유지, 서로 대체 안 함**:
한 줄로 요약하면 **`Apply`는 "특정 대상에 대해 변경을 수행한다", `Overridden`는
"특정 대상에 이미 계산된(baked) 다른 mod를 합친다"** — 문서화 시 이 한
문장을 그대로 핵심 구분 기준으로 앞세울 것(2026-08-07 다섯 번째 세션,
사용자 정리). 재사용 가능한 스타일 "변형"(팩토리, 파라미터화 가능)은
`Apply`, 독립적으로 이미 만들어진 modifier "값" 두 개 이상을 한 슬롯에
밀어넣어야 하는 경우(주로 컴포넌트 경계)는 `Overridden`.

**9-1. 판단 기준을 "이질적/동질적"이 아니라 "계산 의존성 유무"로 명시할 것,
`Apply`를 mutable로 바꾸는 방안은 기각 (2026-08-07 다섯 번째 세션 후속)**

**동기**: `Apply` 체이닝이 호출마다 clone을 만들기 때문에, 항목 수천 개짜리
리스트 UI처럼 무거운 Modifier를 대량으로 재생성하는 상황에서 이 clone
비용이 누적되는 게 아닌지 사용자가 우려 — 대안으로 (a) `Apply`/setter를
아예 mutable로 바꾸는 방안(과 그 절충안), (b) `Overridden`를 "여러 값을
합칠 특수 상황"이 아니라 "성능 최적화 수단"으로 승격하는 방안을 검토.

**(a) `Apply`/setter를 mutable로 바꾸는 방안(및 "`Apply` 경계에서만 clone"
절충안) — 둘 다 검토 후 기각.** 3번 절의 immutable+clone 하드 제약(형제
서브트리 오염 방지)이 clone 비용 절감보다 우선순위가 높다는 결론, 절충안도
"어디서 터지느냐만 달라질 뿐 문제 자체는 남는" 비일관적 타협이라 기각 —
전체 경위·반박 논리는 `archive/modifier-apply-mutable-rejected.md` 참고.

**(b) 판단 기준 — "동질적 vs 이질적 프로퍼티"가 아니라 "필드 간 계산
의존성 유무"로 명시.** 사용자가 처음엔 "동질적(폰트 굵기 보정처럼 연관된
속성끼리)은 `Apply`, 이질적(배경/텍스트/위치처럼 무관한 속성끼리)은
`Overridden`"로 구분을 제안했으나, 실제 기준은 주제의 이질성 자체가 아니라
**한쪽이 다른 쪽의 이미 baked된 값을 읽어야 하는가(`Peek`으로 데이터가
흘러가는가)**임 — 이질적으로 보여도 계산 의존성이 있으면 `Apply`가
맞고(예: "배경색에 맞춰 텍스트 명도를 자동 보정" — 배경/텍스트라는 이질적
주제인데도 의존성이 있어 `Peek`+`Apply`가 필요), 반대로 동질적으로 보여도
서로 완전히 독립이면(예: 여러 개의 `FontSize` 프리셋 중 하나를 통째로
갈아끼우는 경우) `Overridden`도 무방함. `Overridden`는 필드 단위 raw 교체일
뿐 `Peek`으로 값을 읽어 다른 필드에 반영하는 데이터 흐름이 아예 없으므로
(위 "동작" 절), 계산 의존성이 있는 조합엔 애초에 못 씀 — 이게 진짜 판별
기준. 문서에는 "이질적/동질적"이라는 표면적 구분 대신 이 기준으로 적을 것.

**실제 최적화 권장 패턴**: 계산 의존성이 없고 재사용 가능한 조각(예:
배경 스타일 하나, 텍스트 스타일 하나, 레이아웃 위치 하나 — 각각 서로
다른 서브시스템/모듈에서 한 번만 만들어지는 값)은 **모듈 상수/한 번만
생성한 값으로 만들어두고, 인스턴스마다 `Overridden`로 결합**하는 게
`Apply` 체인으로 매번 처음부터 다시 파생시키는 것보다 저렴함 — 조각 자체를
매번 재계산 안 해도 되고, `Overridden`는 필드별 단순 복사 한 번으로 끝나서
여러 단계 clone이 누적되는 `Apply` 체인보다 쌈. **주의**: 이건 "`Overridden`가
내부적으로 값을 캐싱해준다"는 뜻이 아님 — `Overridden` 자체엔 캐싱/메모이제이션
같은 새 메커니즘이 전혀 없고(순수 필드 복사), "캐싱"은 그냥 사용자가 조각
Modifier 값을 변수/모듈 상수로 만들어 재사용하는, 기존에도 항상 가능했던
평범한 값 재사용일 뿐 — 라이브러리에 새 캐싱 레이어를 추가하는 게 아니라는
점을 문서에서 분명히 할 것(라이브러리 차원의 자동 메모이제이션은 지금
검토 대상 아님 — 실제로 필요하다고 확인되면 그때 별도로 논의).

**문서 배치**: 초심자 문서엔 `Overridden`를 아예 안 보여주고(위 "용도를 좁게
문서화" 절), 이 "언제 `Apply` vs `Overridden`, 성능 기준" 절 전체는 api/심화
문서 전용 — `research/documentation-content-map.md`의 modifier-plan.md
분류에 반영 완료.

**미검토로 남긴 것**: `Apply` 체인이 실측으로 병목이라고 확인되면 그때
"unsafe/fast-path mutable 빌더" 같은 별도 opt-in을 검토할 수 있으나, 지금은
근거 없는 선제 최적화라 설계하지 않음 — CLAUDE.md의 "드문 오용/가상 미래
요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다" 원칙과 동일.

### 9-2. `Overridden`가 서로 다른(그러나 상하위 관계인) Modifier 타입을 섞는 경우 —
타입 시그니처 미확정, 실 Luau 테스트 필요 (2026-08-07 다섯 번째 세션 후속)

**문제**: Modifier 타입은 위 4번 절 "FrameModifier 타입" 언급대로 Roblox
클래스별로 생성기가 뽑아내는 flat 타입인데, 그 밑의 Roblox 클래스 자체엔
서브타입 관계가 있음(`Frame`이 `GuiObject`의 서브클래스) — 그럼 생성된
`FrameModifier`도 `GuiObjectModifier`의 서브타입이어야 자연스럽고, 실제로
`Modifier.Overridden(guiObjectMod, frameMod)`처럼 공통 상위 클래스 스타일
프리셋과 하위 클래스 전용 보정을 섞어 합치는 패턴이 필요해 보임(사용자
지적, 2026-08-07).

**막히는 지점**: 필드 setter 메소드(`:FontSize` 류)는 각 타입마다 반환
타입이 자기 자신(`self`, 즉 `FrameModifier`는 `FrameModifier`를,
`GuiObjectModifier`는 `GuiObjectModifier`를 리턴)이라, 같은 이름의 메소드
필드끼리 리턴 타입이 갈려서 단순 구조적 서브타이핑만으로는 안 풀릴 가능성이
있음.

**후보안(미검증)**: 같은 이름의 메소드 필드는 리턴 타입이 다르니 그냥
`any`로 뭉개고, 나머지(메소드가 아닌 순수 데이터 필드) 쪽만 `[string]: nil`류
인덱스 시그니처 조건이 성립하면 통과시키는 식으로 서브타입 호환을 흉내낼 수
있는지 — 이게 실제로 Luau 솔버에서 받아들여지는 타입 구성인지는 추론만으로
결론 낼 수 없고 실제 코드로 테스트해봐야 함(M0가 이미 검증 대상으로 삼은
"추론만으로 확정하고 실제 Luau로 부딪혀본 적 없는 것"과 같은 성격의 모호함).

**당장의 fallback**: 위 후보안이 Luau에서 실제로 안 먹히는 걸로 확인되면,
`Modifier.Overridden`의 타입 시그니처를 일단 `Overridden(...: any): any`류로
느슨하게 열어 정적 체크를 포기 — 이건 임시 처치로 명시하고, M7 실제 구현
시점에 실 테스트 결과에 따라 다시 좁히는 걸 목표로 로드맵에 남김
(`ROADMAP.md` M7).

**`:Peek<<T>>(key): T | State<T> | None | nil`** — Modifier 필드를 확정하지
않고 그대로 읽는 접근자. 이름을 `Get`이 아니라 `Peek`로 정한 이유: 이
프로젝트 전역에서 `State:Get()`은 "확정한다"(pull + recompute + 최종값
반환)는 의미로 이미 자리잡았는데, Modifier의 읽기는 정반대(들고 있는
그대로, State면 State 핸들 그대로) — 같은 동사를 반대 의미로 쓰면 안
되므로 다른 이름 필요. 반환 타입을 `T`로 확정해 돌려주지 않고
`T|State<T>|nil` raw 그대로 노출하는 이유: 4-1번 절의 함수형 setter가
받는 `old` 인자와 정확히 같은 원칙("현재 저장된 그대로 넘김") 재사용 —
자동으로 `:Get()`해서 `T`로 확정해버리면 반응성이 조용히 끊기는데
타입엔 그 사실이 안 드러나서 위험함. `.RealValue.Font` 같은 별도
인덱싱 표면은 기각 — 이미 `__index`가 필드 setter 합성용으로 예약돼
있는데(`Apply`가 첫 예약 사례) 또 다른 프록시 네임스페이스를 얹으면
setter 표면과 read 표면이 헷갈리고, 타이핑 이득도 메소드 방식과 별
차이 없음.

`:Peek`는 팩토리 함수(`Apply`에 넘기는 콤비네이터) 안에서 쓰는 게
전형적 — "이 modifier가 현재 어떤 상태인지 보고 그걸 바탕으로 값을
계산"한다는 문맥이 명확해서 오해 소지가 적음. Peek 결과가 State일 때
그걸 즉시 읽어 스냅샷으로 쓸지, State 핸들을 그대로 물고 가 `:Compute`로
새 파생 State를 만들지는 유저 선택 — 전자는 이후 원본이 바뀌어도 반영
안 되는 캐비엇이 있지만, 이건 quad가 대신 풀어줄 문제가 아니라 문서화
(경고)로 충분(이미 있는 "`Get()` 결과 캐싱 금지" 캐비엇과 같은 클래스).

**`isState(x): boolean` 필요 — `base/bind-system-plan.md`에 정의**.
`Peek`가 raw union을 돌려주므로 사용자 코드가 State/plain을 분기하려면
판별 수단이 필요함(Source가 State를 구조적으로 만족하므로 `isState`가
Source도 같이 잡아줌 — **[2026-08-07 여덟 번째 세션 정정] `isSource`도
별도로 존재함**, `:Set`/`:Emit` 같은 Source 전용 능력이 있는지 알아야
하는 코드를 위해 필요하다고 판단 정정됨). 상세 근거/구현 방식은
`bind-system-plan.md`의 `Brand`/`isState` 절 참고 — 요지만: duck-typing
대신 weak-key 레지스트리 기반(quad의 다른 branded 타입 전부와 공유하는
통합 메커니즘으로 일반화됨), 그리고 이 판별 로직 자체는 새로 만드는 게
아니라 4-1번 setter 분기가 이미 내부적으로 해야 하는 걸 public 유틸로
승격하는 것뿐.

### 10. `Tween<T>`와의 타입 합성 — `T' = T | Tween<T>` 치환만으로 해결 (2026-08-10 세션)

`base/tween-plan.md`가 값-레벨 `Tween<T>` 래퍼로 재설계되며, 프로퍼티류
Modifier 필드 setter가 트윈 값도 받을 수 있어야 하는지가 자연히 따라오는
질문이었음 — **답은 "이미 있는 `T | State<T>` 필드 타입 모양에 새 케이스를
추가할 필요가 없다"** — 위 4번 절이 확정한 필드 타입 모양(리터럴 `T` 또는
`State<T>`)에서 "이 필드의 `T`" 자체를 `T' = T | Tween<T>`로 치환하면
자동으로 `T | Tween<T> | State<T | Tween<T>>`가 나옴. 즉 `FrameModifier`류
타입 생성 스크립트가 `Position` 필드를 만들 때 그냥 `T`를 `UDim2 |
Tween<UDim2>`로 바꿔서 기존 setter 시그니처 생성 로직에 그대로 넣으면 됨 —
Modifier의 제네릭 `__index`/`table.clone` 런타임(위 "런타임은 클래스별
코드 없이" 절)에도 `Tween` 인지 로직을 전혀 추가할 필요 없음(setter는
어차피 값을 그대로 baked 저장할 뿐, 그 값이 `Tween<T>`인지는 나중에
PropertyHandler가 판단).

`Tween<T>`가 Modifier 필드로 담기는 것도, `State<Tween<T>>`처럼 State/Source
값으로 담기는 것도 둘 다 아무 문제 없음 — 7번 절의 "핸들러 계층 값 →
error" 규칙에 안 걸림(`Tween<T>`는 `process`/`retract`를 가진 dispatch
참가자가 아니라 `None`처럼 순수 raw 데이터 값, 위 7번 절 "Slot/Tag/Attribute
등" 목록에서 Tween을 뺀 정정 참고).

## 열린 질문 (`.claude/question.md`에도 취합)

- **[해소됨]** Getter 정확한 이름/모양 — 2026-08-06 후속 세션에서 getter
  자체를 안 만들기로 확정(위 "4. Setter는..." 절 참고), 더 이상 열린
  질문 아님.
- Modifier가 컴포넌트 경계를 어떻게 통과하는지는 **[정정] 이미
  `base/component-composition-plan.md`에서 해소됨**(named parameter로
  전달, "다중 루트" 개념 자체는 폐기) — 더 이상 열린 질문 아님, 이 문서가
  다루는 "값 자체의 동작"과는 별개 문제였다는 점만 참고로 남김.
- **[해소됨]** `Overridden` 이름 — 2026-08-08 세션에서 확정(`Add`/`Remove`
  →`Added`/`Removed`, `Merge`→`Merged`와 같은 분사형 네이밍 컨벤션에
  맞춰 불규칙동사 `override`의 정확한 과거분사를 씀, `Overrided`는 오기).
  `Peek`/`isState` — 동작은 위 9번 절에서 확정, 이름도 2026-08-08 다섯
  번째 세션(`.claude/question.md` 용어 정리 라운드)에서 더 나은 대안 없어
  현재 이름 그대로 최종 확정됨.
