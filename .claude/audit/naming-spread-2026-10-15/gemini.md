# quad "펴 넣는 묶음" 도구 이름 탐색 보고서

본 보고서는 Roblox Luau 선언형 UI 렌더러 quad에서 재사용 행동(hover, drag, focus 등)을 요소 선언 시 펴 넣기 위한 새 도구(이하 가칭 `q.X`)의 이름 후보를 탐색하고 장단점을 비교·분석한 결과입니다.

> **안내 및 규칙 준수 표기:**
> - 본 보고서의 최종 결정 권한은 사용자에게 있으며, 제시된 이름 및 인터페이스는 모두 **[제안]**입니다.
> - 직접 코드 실행을 통해 검증한 사실은 **[실측]**, 코드를 읽고 분석하거나 타 생태계 명세를 바탕으로 추론한 내용은 **[추정]**, 아직 미해결이거나 추후 결정이 필요한 부분은 **[미완]**으로 표기합니다.

---

## 1. 배경 및 문제 정의

### 1.1 현재 상황과 제약 [실측]
quad의 요소 선언(Declaration)은 단일 테이블 리터럴로 구성됩니다.
```luau
D.Frame {
    Size = UDim2.fromScale(1, 1),
    MouseEnter = function() ... end,
    q.PreRef(...),
    props.Modifier or q.None,
    D.TextLabel { ... },
}
```
- **문자 키**: 프로퍼티, 이벤트 핸들러 등
- **숫자 키 (배열부)**: 자식 요소, 훅 값(`Ref`, `PreRef`, `PostRef`, `Observer`, `Tag`, `Attr` 등), `Modifier`

**기존 `Modifier`의 제약:**
- `Modifier`는 불변 프로퍼티 가방이자 "정적 기본값" 전용입니다.
- 이벤트 핸들러(함수) 및 핸들러 계층 값(`Ref`, `Observer`, `Slot` 등)을 필드로 받는 것을 엄격히 거부합니다.
  - 근거 [`quad-base/src/Dispatch/Modifier/init.luau:98`](file:///code/Projects/quad-agy/naming-spread/quad-base/src/Dispatch/Modifier/init.luau#L98): `Quad0063 Modifier: field "{k}" in an initial-field table cannot be a function - a transform goes through mod:{k}(fn); an event handler does not belong in a Modifier...` [실측]
  - 근거 [`quad-base/src/Dispatch/Modifier/init.luau:99`](file:///code/Projects/quad-agy/naming-spread/quad-base/src/Dispatch/Modifier/init.luau#L99): `Quad0064 Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier/mapper descriptor)` [실측]
  - 근거 [`docs/reference/core/08-modifier.md:88-99`](file:///code/Projects/quad-agy/naming-spread/docs/reference/core/08-modifier.md#L88-L99) [실측]

### 1.2 새 도구의 요구사항 [추정/제안]
hover, drag, focus 같은 재사용 행동(Behavior)을 팩토리 함수로 제공하려면, **문자 키(이벤트 핸들러, 프로퍼티)와 배열부 값(Ref, Observer 등)을 한 번에 묶어서 반환**하고, 이 묶음이 요소 선언 테이블의 배열부에 놓였을 때 요소 본문으로 **"펴져 들어가는(spread/flatten)"** 메커니즘이 필요합니다.

```luau
local function Hoverable(onEnter, onLeave)
    return q.X {
        MouseEnter = onEnter,
        MouseLeave = onLeave,
        q.PostRef(...),
    }
end

D.Frame {
    Size = UDim2.fromScale(1, 1),
    Hoverable(enter, leave), -- 배열부에 놓으면 내부 키와 훅이 Frame에 직접 쓴 것처럼 펴진다
    MouseLeave = myLeave,   -- 직접 쓴 키가 우선(이긴다)
}
```

**우선순위 규약 [제안]:**
- `직접 쓴 키(인라인 키) > 펴진 묶음 > Modifier`
  - (참고: 현재 `flatten` 루프 [`quad-base/src/Dispatch/Modifier/init.luau:555-559`](file:///code/Projects/quad-agy/naming-spread/quad-base/src/Dispatch/Modifier/init.luau#L555-L559)에서는 인라인 키가 이미 존재하면(`input[key] ~= nil`) `Modifier`의 값을 덮어쓰지 않습니다. 새 묶음은 인라인 키 다음, `Modifier` 이전 단계로 삽입됩니다.) [추정]
- 묶음 내부에 `Modifier`가 포함될 수 있고(그것은 최종 Modifier 단계로 흡수), 묶음 안에 또 다른 묶음이 중첩될 수 있습니다.

---

## 2. 네이밍 판단 기준

1. **직관성 및 타 생태계 오해 방지**:
   처음 보는 Roblox/Luau 개발자가 `q.X { ... }`를 보았을 때 "이 테이블의 키와 배열 항목이 부모 요소에 펴져 들어간다"를 바르게 인지하는가?
   다른 생태계(React `Fragment`/`spread`, Vue `mixin`, Svelte `action`, Compose `Modifier`, Flutter `mixin`)의 고유 개념과 충돌하여 엉뚱한 멘탈 모델(예: 자식 전용 가상 노드, 마운트 후 명령형 훅 등)을 부르지 않는가?
2. **기존 quad 심볼, 특히 `Modifier`와의 구별성**:
   `Modifier`(정적 기본값·스타일 가방, 이벤트 불가, 우선순위 최하위)와 나란히 놓였을 때 둘의 성격 차이가 이름에서 자연스럽게 드러나는가?
   기존 quad 네임스페이스(`Declaration`, `Ref`, `Tag`, `Attr`, `Slot`, `Operator`, `Blocker`, `Gate`, `Claim` 등 208개 공개 심볼)와 어휘적/기능적 충돌이 없는가? [실측: `scripts/test.sh` 실행 시 `doc-coverage: 208/208 symbols` 확인]
3. **가독성 및 간결성**:
   배열부에 놓였을 때 짧고 자연스러운가? 팩토리 함수 반환문 `return q.X { ... }`에서 읽기 좋은가?

---

## 3. 후보군 비교 분석 (6종)

### 후보 1: `Spread` (`q.Spread`) — [추천 1위 제안]
- **어원 및 배경**:
  JavaScript / TypeScript의 객체 스프레드 문법 `{ ...props }` 및 JSX 속성 스프레드 `<Frame {...props} />`.
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **직관성 [추정]**: "스프레드(펼치다)"라는 단어 뜻 그대로 "이 테이블의 내용물을 현재 요소에 그대로 펼쳐 넣는다"는 동작 메커니즘을 1:1로 가장 정확하게 전달합니다. Luau에는 문법적 스프레드 연산자(`...`는 가변인자 전용)가 없기 때문에, `q.Spread { ... }`는 "Luau에서 테이블 스프레드를 선언적으로 표현하는 도구"로 즉시 받아들여집니다.
  - **오해 방지 [추정]**: React Fragment(자식 전용), Svelte Action(명령형 노드 조작) 같은 특정 프레임워크의 편향된 멘탈 모델을 유발하지 않습니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - `Modifier`: 프로퍼티를 변경(modify)하는 설정 가방(Bag) — 정적 기본값, 함수 거부, 우선순위 3위.
  - `Spread`: 테이블 전체를 인라인으로 전개(spread)하는 구조적 도구 — 이벤트/훅 허용, 우선순위 2위.
  - '값의 정책(Modifier)'과 '테이블의 구조적 펼침(Spread)'으로 책임이 명확히 분리됩니다.
- **기준 (3) 가독성 [추정]**:
  - 6글자로 짧고 군더더기 없음.
  - `return q.Spread { MouseEnter = ..., q.PostRef(...) }` 형태가 매우 자연스러움.

---

### 후보 2: `Bundle` (`q.Bundle`) — [차선 2위 제안]
- **어원 및 배경**:
  일반 명사 "묶음", "다발". (과제 설명의 "펴 넣는 묶음"과 일치).
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **직관성 [추정]**: 문자 키(이벤트)와 숫자 키(훅)를 "하나의 다발로 패키징했다"는 데이터 그릇으로서의 직관성이 매우 우수합니다.
  - **오해 방지 [추정]**: 특정 프레임워크에 선점된 용어가 아니므로 외부 생태계 유래의 오해가 전혀 없습니다.
  - **단점/한계 [추정]**: "묶음(Bundle)"은 묶어둔 **상태**를 뜻할 뿐, 요소에 놓였을 때 "인라인으로 풀려서 **펴져 들어간다(spread)**"는 동사적 메커니즘은 단어에 직접 드러나지 않아 "quad의 Bundle은 요소에 놓이면 풀린다"는 규약 학습이 수반됩니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - `Modifier`(수정자)와 `Bundle`(다발)은 철자나 어감이 완전히 달라 혼동 여지가 전혀 없습니다.
- **기준 (3) 가독성 [추정]**:
  - 6글자로 짧고 배열부에 잘 어울림 (`q.Bundle { ... }`).

---

### 후보 3: `Unpack` (`q.Unpack`)
- **어원 및 배경**:
  Lua / Luau 표준 라이브러리 `table.unpack` (`unpack`).
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **직관성 [추정]**: Lua 개발자에게 "테이블을 푼다"는 개념으로 가장 친숙한 단어입니다.
  - **치명적 오해의 함정 [추정]**:
    - **Lua의 `table.unpack`은 오직 정수 인덱스(배열부)만 풉니다.** 해시 키(문자열 키)는 풀지 못하고 완전히 무시합니다.
    - 그러나 `q.X`의 가장 핵심적인 목적은 **문자 키(이벤트 핸들러, 프로퍼티)를 요소의 키로 펴 넣는 것**입니다.
    - Lua 개발자가 `q.Unpack { MouseEnter = ... }`를 보면 "Lua의 unpack은 딕셔너리를 못 푸는데 왜 이게 풀리지?"라는 인지 부조화를 겪거나, 반대로 "자식 배열만 풀어주는 도구인가?" 하고 오해할 위험이 큽니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - 단어는 다르지만, Lua 표준 동작과의 불일치로 인한 오해가 큽니다.
- **기준 (3) 가독성 [추정]**:
  - 6글자.

---

### 후보 4: `Mixin` (`q.Mixin`)
- **어원 및 배경**:
  OOP, Vue (`mixins: [...]`), Flutter (`with Mixin`).
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **직관성 [추정]**: `Hoverable`, `Draggable`처럼 "재사용 가능한 행동 단위를 요소에 혼합(mix-in)한다"는 사용 목적 관점에서는 설명력이 높습니다.
  - **오해 방지 [추정]**: 모던 웹 생태계에서 Mixin은 "암묵적 네임스페이스 오염", "키 충돌 추적 불가" 등으로 인해 Vue 3(Composition API) 등에서 기피/레거시로 여겨진 역사적 거부감이 있습니다. 또한 단순한 프로퍼티/Ref 분할 묶음으로 쓸 때 `Mixin`이라는 이름은 너무 거창합니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - **가장 큰 취약점**: `Modifier`와 `Mixin` 둘 다 `M`으로 시작하며 "수정자 / 혼합자"로 느껴집니다.
  - 초심자 입장에서 "둘 다 요소에 꽂는 부가 설정 같은데 `Modifier`와 `Mixin`의 차이가 뭐지?"라는 구분의 모호함을 유발하기 쉽습니다.
- **기준 (3) 가독성 [추정]**:
  - 5글자로 매우 짧음.

---

### 후보 5: `Fragment` (`q.Fragment`)
- **어원 및 배경**:
  React의 `React.Fragment` (`<></>`), Vue의 Multiple root nodes.
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **치명적 오해 유발 (부적합) [추정]**:
    - React/Roact 생태계에서 Fragment의 정의는 **"별도 인스턴스를 만들지 않고 자식 노드들(Children)만 그룹화하는 가상 노드"**입니다.
    - Fragment는 부모의 props나 이벤트를 대신 받아 부모에게 병합해주는 기능이 전혀 없습니다.
    - React/Roact 경험자가 `q.Fragment { MouseEnter = ..., q.PostRef(...) }`를 보면 "Fragment인데 왜 이벤트 리스너가 들어있고, 왜 부모 요소의 프로퍼티로 펴지는가?"라며 극심한 혼란을 겪습니다.
    - 추후 quad가 실제로 인스턴스 없는 가상 자식 묶음(진짜 Fragment)을 도입하려 할 때 네임스페이스 오염이 발생합니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - `Modifier`와는 구분되나 타 생태계의 고착된 정의와 심각하게 충돌합니다.
- **기준 (3) 가독성 [추정]**:
  - 8글자.

---

### 후보 6: `Action` (`q.Action`)
- **어원 및 배경**:
  Svelte의 `use:action` (`<div use:hoverable />`).
- **기준 (1) 직관성과 타 생태계 오해 방지**:
  - **패러다임 불일치 [추정]**: Svelte의 `action`은 DOM 노드가 마운트된 직후 호출되는 `(node, params) -> { update, destroy }` 형태의 **명령형 런타임 훅**입니다. 반면 quad의 `q.X`는 노드 생성 전에 선언 테이블을 정규화하는 **선언적 테이블 스프레드**이므로 동작 시점과 패러다임이 다릅니다.
  - **기존 심볼과의 혼란 [실측]**: quad에는 이미 `q.Operator` 심볼이 존재합니다. `Action`과 `Operator`는 "동작/연산자"라는 유사한 어감을 주어 혼동을 일으킬 수 있습니다.
- **기준 (2) `Modifier`와의 구별성 [추정]**:
  - 스타일 vs 행동으로 대비는 되나 위 패러다임 차이와 `Operator` 혼동이 단점입니다.
- **기준 (3) 가독성 [추정]**:
  - 6글자.

---

### 기타 검토 후보 요약 [추정]
- **`Inline` (`q.Inline`)**: 인라인으로 풀린다는 뜻은 맞으나, UI 레이아웃의 `display: inline` 또는 컴파일러의 inline 함수와 혼동 가능.
- **`Splice` (`q.Splice`)**: 프로그래밍에서 splice는 배열의 원소를 제자리에서 삭제/교체하는 명령형 연산의 뉘앙스가 강함.
- **`Flat` / `Flatten` (`q.Flatten`)**: quad 내부 구현 함수 이름([`quad-base/src/Dispatch/Modifier/init.luau:511`](file:///code/Projects/quad-agy/naming-spread/quad-base/src/Dispatch/Modifier/init.luau#L511))과 겹치며, 표면 API로는 형용사/동사로서 다소 어색함.

---

## 4. 후보 비교 매트릭스

| 후보 | (1) 직관성 & 타 생태계 오해 여부 | (2) `Modifier`와의 차이 명확성 | (3) 간결성 & 가독성 | 종합 평가 |
|---|---|---|---|---|
| **`q.Spread`** | **최상** (메커니즘 1:1 일치, JS/TS spread 연상, 오해 없음) | **최상** (스타일 가방 vs 테이블 펴기) | **최상** (6자, 깔끔) | **추천 (1위)** |
| **`q.Bundle`** | **우수** (묶음 직관성 우수, 단 펴짐 동작은 규약 학습 필요) | **우수** (수정자 vs 묶음 다발) | **최상** (6자, 깔끔) | **차선 (2위)** |
| `q.Unpack` | **주의** (Lua unpack은 배열만 풂, 딕셔너리 펴기와 불일치) | 보통 (unpack 대상이 모호함) | 우수 (6자) | 비추천 |
| `q.Mixin` | 보통 (Vue 레거시 뉘앙스, 단순 props 묶음엔 과함) | **미흡** (`Modifier`와 둘 다 'M', 수정/혼합 혼동) | 최상 (5자) | 비추천 |
| `q.Fragment` | **위험** (React Fragment는 오직 자식 전용 가상 노드) | 보통 (타 생태계 왜곡이 큼) | 보통 (8자) | **강력 비추천** |
| `q.Action` | **미흡** (Svelte action은 명령형 런타임 훅, `Operator` 혼동) | 보통 (스타일 vs 행동) | 우수 (6자) | 비추천 |

---

## 5. 추천 및 차선 선정 이유

### 추천 (1위): `q.Spread` [제안]
1. **메커니즘의 정확성**:
   새 도구의 본질은 "테이블의 문자 키(이벤트/프로퍼티)와 배열 항목(훅/자식)을 부모 요소에 **펼쳐 넣는 것(spread)**"입니다.
   `Spread`는 도구의 동작 원리를 가감 없이 가장 정확하게 설명합니다.
2. **목적의 중립성**:
   `Hoverable`, `Draggable` 같은 인터랙션 행동뿐 아니라, 복합 컴포넌트의 props 조각 분할, 훅 묶음 등 다양한 목적에 사용해도 이름이 어색하지 않습니다.
3. **`Modifier`와의 선명한 대비**:
   - `Modifier`: 대상의 속성값을 제어/수정하는 불변 프로퍼티 가방 (우선순위 3위, 함수 거부).
   - `Spread`: 테이블 내용을 요소에 그대로 전개하는 구조적 도구 (우선순위 2위, 함수/훅 허용).
   두 도구의 역할이 '설정 정책' vs '테이블 전개'로 명확히 분리됩니다.
4. **학습 용이성**:
   현대 Luau/Roblox 개발자 중 상당수가 React/Roact 또는 웹 프론트엔드 경험을 갖고 있어, "Luau에는 `{...t}` 스프레드 문법이 없어서 `q.Spread`를 쓰는구나"라고 즉각적으로 이해할 수 있습니다.

### 차선 (2위): `q.Bundle` [제안]
1. **오염되지 않은 순수 어휘**:
   다른 프레임워크의 특정 메커니즘에 얽매이지 않고, "키와 훅을 하나로 묶어둔 다발(Bundle)"이라는 개념을 일상어로 전달합니다.
2. **`Modifier`와의 어휘적 독립성**:
   철자나 발음에서 `Modifier`와 완전히 구별되어 초심자가 두 개념을 헷갈릴 위험이 없습니다.
3. **차선으로 둔 이유**:
   "묶는다(Bundle)"는 패키징 **상태**를 뜻할 뿐, 부모 요소에 "인라인으로 풀려 들어간다(spread)"는 **동작**이 단어 자체에서 즉시 연상되지는 않기 때문입니다.

---

## 6. 열린 질문 및 향후 검토 과제 [미완]

1. **중복 키 병합 정책 [미완/제안]**:
   서로 다른 두 개의 `q.Spread`가 동일한 이벤트 키(예: 둘 다 `MouseEnter`)를 갖고 있을 때:
   - 나중 것이 덮어쓰는가 (first-writer-wins 또는 last-writer-wins)?
   - 아니면 두 이벤트 핸들러를 순차 실행하는 체인으로 합성할 것인가, 혹은 에러를 낼 것인가?
2. **우선순위 3단계 구현 방식 [미완/추정]**:
   현재 `flatten` 루프([`quad-base/src/Dispatch/Modifier/init.luau:548`](file:///code/Projects/quad-agy/naming-spread/quad-base/src/Dispatch/Modifier/init.luau#L548))는 배열 역순 순회로 `Modifier`를 처리하고 있습니다. 새 도구(`Spread`)가 추가될 경우:
   - 1단계: 인라인 키 보존
   - 2단계: `Spread` 전개 (인라인 키가 없을 때만 기록)
   - 3단계: `Modifier` 적용 (인라인 키 및 `Spread` 키가 없을 때만 기록)
   순서로 `Dispatch.drive`의 전처리 루프를 재구성해야 할 것으로 추정됩니다.
3. **타입 표면 정의 [미완]**:
   Luau 타입 체커(신 솔버/구 솔버)에서 `q.Spread({ ... })`가 반환하는 값의 마커 타입과, `Declaration`의 props 타입 유니언에 이를 어떻게 포함할지에 대한 타입 엔지니어링 검토가 필요합니다.

---

*본 보고서의 모든 추천과 분석은 사용자의 최종 검토와 결정을 위해 작성된 제안서입니다.*
