# 이름 탐색 보고서: 요소 props 테이블의 배열 자리에 놓일 수 있는 것 (`X<C>`)

- **작업 브랜치**: `agy/naming-arritem` (worktree: `/code/Projects/quad-agy/naming-arritem`)
- **작성일시**: 2026-10-16
- **기준 테스트 상태**: `./scripts/test.sh` 실행 결과 exit code 0 (`ALL PASS`, 208 doc symbols, 0 type errors, 263 error codes) **[실측]**
- **문서 성격**: 결정을 내리는 것이 아닌, 라이브러리 저자(사용자)의 결정을 돕기 위한 후보군과 분석 근거의 체계적 제시 **[제안]**

---

## 1. 배경 및 문제 정의

### 1.1 현재 상태와 전환 계기
quad는 선언형 UI 라이브러리로, 요소 생성 시 props 테이블 하나를 넘깁니다. props 테이블은 문자열 키(프로퍼티, 이벤트)와 숫자 인덱스 배열 자리(자식, 수식자, 디스크립터 등)로 구성됩니다:

```luau
local Frame = Elem "Frame"            -- 값 쪽 생성자 꺼내기 (저자 기울기: Elem)
local card = Frame {
    Size = UDim2.fromScale(1, 0),      -- 문자 키: 프로퍼티
    MouseEnter = fn,                   -- 문자 키: 이벤트

    -- 아래는 전부 props 테이블의 "배열 자리"(숫자 키)에 놓이는 값
    TextLabel { Text = "hi" },          -- 1. 자식 Instance
    q.Source(maybeChild),               -- 2. 자식을 쥔 State/Source (nil이면 자식 없음)
    hoverModifier,                      -- 3. 이 클래스(또는 조상 클래스)의 Modifier
    q.Spread "GuiObject" { … },        -- 4. 상위 클래스 공통 속성 묶음 마커 (SpreadMarker)
    q.OnChange("Visible", fn),          -- 5. 프로퍼티 변화 디스크립터
    q.OnEvent "MouseEnter" (fn),        -- 6. 이벤트 디스크립터
    ref,                                -- 7. Ref 마커 (PreRef/PostRef 등 인스턴스 캡처)
}
```

- **현재 생성 D (`quad-roblox/src/Declaration/init.luau:2448`) [실측]**:
  `export type FrameElem = NewChild | FrameOnChange | StateMarker<(FrameOnChange | None)?> | { read __quadModifier: "Frame" | "GuiObject" | ... } | FrameRefMarker | StateMarker<(FrameRefMarker | None)?>`
  이처럼 31개 지원 클래스마다 개별 타입(`FrameElem`, `TextLabelElem` 등)이 복제되어 export되고 있습니다.
- **새 표면 (`.claude/audit/decl-typefn-probe-2026-10-16/src/Lib.luau:462`) [실측]**:
  타입 함수 `Build<"elem", C, Policy>`를 통해 단일 제네릭 별칭 `X<C>`로 접힙니다.
  사용자는 컴포넌트 반환값이나 children 인자 타입을 주석에 직접 적습니다:
  - 컴포넌트 반환: `local function Badge(): X<Frame>`
  - 컴포넌트 children 인자: `function(children: { X<GuiObject> })`

### 1.2 이름 변경의 필요성과 제약 조건
1. **기존 이름 `Elem`의 한계 [추정]**:
   - 저자 판단: 기존 이름 `Elem`은 *"자기서술적이지 못했다"* — 배열 자리에 놓인다는 점이 드러나야 합니다 (`.claude/research/declaration-surface-plan.md:66-68` [실측]).
   - `FrameElem`은 "Frame 요소 그 자체(생성자 또는 인스턴스)"처럼 읽혀, 실제 역할인 "Frame의 속성 테이블 배열 자리에 들어가는 부속물"임이 드러나지 않았습니다.
2. **`Elem`의 값 쪽 이동 [추정]**:
   - 저자는 값 쪽 생성자 꺼내기 함수(`Elem "Frame"`)에 `Elem`을 사용하고자 합니다.
   - 따라서 새 타입 이름은 `Elem`/`Element`와 철자 및 개념상 혼동되지 않아야 합니다.
3. **배열 자리의 복합적 실체 (자식만이 아님) [실측]**:
   - 배열 자리에는 `Instance`뿐 아니라 `Modifier<C>`, `SpreadMarker<C>`, `OnChange`/`OnEvent` 디스크립터, `Ref` 마커가 함께 배치됩니다.
   - 따라서 `Children` 계열의 명칭은 자식이 아닌 수식자/디스크립터를 포괄하는 데서 개념적 오독을 낳을 수 있습니다.

---

## 2. 후보군 분석 (6개)

### 후보 1: `Content<C>` — [추천 1순위 제안]
- **개념**: 요소 `C`의 props 테이블 배열 자리를 채우는 내부 내용물(Content).
- **장점**:
  1. **완벽한 의미 포용성 [추정]**: 자식 인스턴스뿐만 아니라 `Modifier<C>`, `SpreadMarker<C>`, `OnChange`/`OnEvent`, `Ref` 등 배열 자리에 들어오는 모든 이질적 구성물을 "요소의 내부를 구성하는 내용물(Content)"로 위화감 없이 100% 수용합니다. "Modifier는 Child가 아니다"라는 인지 부조화가 발생하지 않습니다.
  2. **`Props<C>`와의 대칭적 가족 구조 [추정]**: 요소의 두 구성면인 `Props<C>`(외곽 속성/이벤트 설정) ↔ `Content<C>`(내부 내용물)가 완벽한 쌍을 이룹니다. 웹/UI 표준(CSS/HTML 속성 vs 콘텐츠)과도 조화를 이룹니다.
  3. **단수/집합 명사의 문법적 자연스러움 [추정]**: `Content`는 불가산/집합 명사로 쓰이면서도 개별 항목으로 자연스럽게 읽힙니다. `{ Content<GuiObject> }`("GuiObject 내용물들의 배열")과 `Badge(): Content<Frame>`("Frame용 내용물 한 조각") 둘 다 매끄럽습니다.
  4. **`Elem`과의 완벽한 분리 [추정]**: 값 쪽 생성자 `Elem "Frame"`과 어원/철자가 완전히 달라 "값 생성자 `Elem` vs 내용물 타입 `Content`"로 역할이 즉시 분리됩니다.
- **약점**:
  1. **Roblox 속성과의 어휘 연상 [추정]**: Roblox의 `TextLabel.ContentText` 등 일부 속성에 `Content` 단어가 쓰이지만, 타입 파라미터 `Content<Frame>` 자리에서는 문맥상 혼동될 여지가 거의 없습니다.
  2. **자료구조 노출 없음 [추정]**: 저자가 언급한 `ArrItem`처럼 "테이블의 배열(Array)"이라는 Luau 문법 키워드가 직접 드러나지는 않습니다. "테이블의 배열 자리 = 요소의 내용물"이라는 선언형 UI 관례적 매핑을 거칩니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): Content<Frame>
  local function Card(props: { children: { Content<GuiObject> } })
  ```

---

### 후보 2: `ArrItem<C>` (또는 `ArrayItem<C>`) — [저자 예시 후보]
- **개념**: props 테이블의 배열(Array) 자리에 놓이는 아이템(Item).
- **장점**:
  1. **위치 사실성 100% [추정]**: "props 테이블의 배열 자리에 놓이는 값"이라는 문법적 팩트를 한 치의 과장 없이 직설적으로 서술합니다.
  2. **자식 편향 오독 원천 차단 [추정]**: "배열 자리에 놓이는 것이라면 Modifier든 이벤트든 무엇이든 들어간다"는 구현 규칙을 이름 자체로 정당화합니다.
- **약점**:
  1. **도메인 추상화 누수 [추정]**: 선언형 UI 컴포넌트의 개념적 설계 영역에 Luau 테이블 자료구조의 내부 구현 상세(`Arr`/`Array`)가 타입 이름으로 직접 노출됩니다. `Badge(): ArrItem<Frame>`은 UI 의미가 결여된 채 "배열 슬롯 조각"처럼 읽힙니다.
  2. **축약어 불일치 [추정]**: quad 코드베이스의 주요 타입들(`Modifier`, `SpreadMarker`, `SlotElement`, `StateMarker`)은 축약어를 쓰지 않습니다. `ArrItem`의 `Arr`은 이 규칙과 어긋납니다.
  3. **배열 주석의 중복감 [추정]**: `{ ArrItem<GuiObject> }`는 "배열 아이템의 배열(Array of ArrayItems)"이 되어 표현상 어색함이 있습니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): ArrItem<Frame>
  local function Card(props: { children: { ArrItem<GuiObject> } })
  ```

---

### 후보 3: `Child<C>` — [직관성 중심 후보 제안]
- **개념**: 요소 `C`의 자식 슬롯에 배치되는 단일 항목 (저자 예시 `ChildrenOf`의 단수 교정형).
- **장점**:
  1. **압도적인 직관성 [추정]**: 선언형 UI 개발자의 머릿속에는 "배열 자리는 children"이라는 멘탈 모델이 확고하므로 학습 비용이 전혀 없습니다.
  2. **단수형을 통한 복복수 해소 [추정]**: 저자의 `ChildrenOf` 대신 단수형 `Child<C>`를 채택함으로써 `{ Child<GuiObject> }` 형태가 매우 자연스럽습니다.
- **약점**:
  1. **"자식만"으로 좁게 읽히는 치명적 의미 왜곡 [추정]**: `Modifier<Frame>`, `SpreadMarker<Frame>`, `OnEvent`, `OnChange`, `Ref` 등 요소 자기 자신에 적용되는 속성/수식자가 "Child" 타입으로 묶이는 개념적 모순이 발생합니다.
  2. **헬퍼 함수에서의 인지 부조화 [추정]**: `local function HoverEffect(): Child<Frame>`처럼 Modifier나 리스너 조각을 반환하는 함수에 `Child` 타입을 붙이는 것이 매우 어색합니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): Child<Frame>
  local function Card(props: { children: { Child<GuiObject> } })
  ```

---

### 후보 4: `PropsItem<C>` (또는 `PropItem<C>`) — [Props 대응 후보 제안]
- **개념**: `Props<C>` 테이블의 배열 자리를 구성하는 개별 아이템.
- **장점**:
  1. **`Props<C>`와의 명시적 대응 [추정]**: `Slot<T>` ↔ `SlotElement<T>`처럼, 부모 컨테이너 타입 `Props<C>`와 1:1로 결합하여 명확한 가족 관계를 형성합니다.
  2. **`Elem`과의 완벽한 분리 [추정]**: 값 생성자 `Elem "Frame"`과 혼동될 여지가 없습니다.
- **약점**:
  1. **"Prop"의 일반적 의미와의 충돌 [추정]**: 프론트엔드 전반에서 "Prop"은 항상 "속성(Key-Value Property)"을 의미합니다. `PropsItem`이라고 하면 개발자는 "속성 하나(Size, Color)"를 떠올리지, 자식 인스턴스나 Modifier를 떠올리지 못합니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): PropsItem<Frame>
  local function Card(props: { children: { PropsItem<GuiObject> } })
  ```

---

### 후보 5: `Node<C>` — [선언형 UI 표준 모델 후보 제안]
- **개념**: 요소 `C`에 소속되는 선언형 트리 노드 (React의 `ReactNode` 모델).
- **장점**:
  1. **선언형 UI 생태계와의 친숙성 [추정]**: React에서 자식, 마커, 프래그먼트, null 등을 포괄하여 `ReactNode`로 부르는 업계 관행과 유사합니다.
  2. **간결한 4글자 명사 [추정]**: 주석 작성이 매우 짧고 간결합니다.
- **약점**:
  1. **Roblox `Instance` 멘탈 모델과의 충돌 [추정]**: Roblox 개발자에게 `Node`는 곧 `Instance`입니다. Modifier나 OnEvent가 왜 `Node`인지 납득하기 어렵습니다.
  2. **관계의 방향성 모호 [추정]**: `Node<Frame>`이 "Frame 안의 노드"인지 "Frame이라는 노드 자체"인지 구분이 모호합니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): Node<Frame>
  local function Card(props: { children: { Node<GuiObject> } })
  ```

---

### 후보 6: `DeclItem<C>` (또는 `Decl<C>`) — [기존 Declaration 유산 후보 제안]
- **개념**: 요소 `C`의 선언(Declaration)에 속하는 개별 구성 항목.
- **장점**:
  1. **quad의 역사적 맥락 보존 [추정]**: quad가 v1/v2에서 `q.Declaration`(`D`)을 사용해 온 맥락과 닿아 있으며, 자식과 수식자 모두가 "선언의 항목"이라는 점을 정확히 짚습니다.
- **약점**:
  1. **어휘의 건조함 및 축약어 [추정]**: 주석에서 일상적으로 쓰기에 다소 무겁고, `Decl` 축약어가 사용됩니다.
- **주석 자리 예시 두 줄**:
  ```luau
  local function Badge(): DeclItem<Frame>
  local function Card(props: { children: { DeclItem<GuiObject> } })
  ```

---

### 후보 종합 대조표

| 후보 | 장점 | 약점 (오독·충돌·범위) | 주석 가독성 | 추천 순위 |
|---|---|---|---|---|
| **`Content<C>`** | 자식·수식자·마커·이벤트 100% 포용, `Props<C>`와 완벽한 대칭, `Elem`과 완전 격리 | "배열" 자료구조명이 직접 노출되진 않음 | **최상** (`Badge(): Content<Frame>`, `{ Content<GuiObject> }`) | **1순위 (강력 추천)** |
| **`ArrItem<C>`** | "배열 자리"라는 기술적 위치 팩트 100% 명시, 자식 편향 오독 차단 | UI 도메인 추상화 누수, 축약 `Arr`, `{ ArrItem }` 중복감 | **중** (`Badge(): ArrItem<Frame>`, `{ ArrItem<GuiObject> }`) | 2순위 (위치 중심 대안) |
| **`Child<C>`** | 학습 비용 0, 선언형 UI에서 가장 친숙함 | Modifier·Spread·OnEvent를 포용하지 못하는 심각한 의미 왜곡 | **상** (단, Modifier 반환 시 어색함) | 3순위 (직관성 중심 대안) |
| **`PropsItem<C>`** | `Props<C>` 테이블과의 명확한 가족 관계 | "Prop"을 자식/수식자로 부르는 역직관성 | **하** (`PropsItem` = 속성으로 오독) | 4순위 |
| **`Node<C>`** | ReactNode 식 업계 표준 모델, 간결함 | Roblox Instance와의 동의어 오독, Modifier 포용 어색 | **중** | 5순위 |
| **`DeclItem<C>`** | Declaration 맥락 계승, 자식/수식자 모두 선언 항목임 | 딱딱한 어휘, 축약 `Decl` | **중/하** | 6순위 |

---

## 3. 저자 예시 `ChildrenOf`·`ArrItem`에 대한 평가

### 3.1 `ChildrenOf<C>` 평가
1. **단수 vs 복수 문법 불일치 (이중 복수 문제) [추정]**:
   - `X<C>`는 props 테이블의 배열부 인덱서 `[number]: X<C>`에 들어가는 **단일 원소(1개)**의 타입입니다.
   - 그런데 `ChildrenOf`는 복수형입니다. 컴포넌트가 자식 목록을 prop으로 받을 때 보통 `{ X<GuiObject> }` 배열 리터럴 형태로 선언합니다.
   - 이때 `children: { ChildrenOf<GuiObject> }`가 되면 영문법적으로 "자식들의 배열(Array of ChildrenOf)"이 되어 복복수(Double Plural)의 어색함이 발생합니다.
   - 만약 이 계열을 채택한다면 반드시 단수형인 `ChildOf<C>` 또는 `Child<C>`로 교정되어야 합니다.
2. **의미론적 범위의 협소함 (자식 편향 오독) [실측/추정]**:
   - 실제 배열 자리에 들어가는 멤버(`quad-roblox/src/Declaration/init.luau:2448` [실측]):
     - 자식: `NewChild` (`Instance`, `State<Instance?>`, `None`)
     - 수식자: `{ read __quadModifier: ... }` (`Modifier<Frame>`)
     - 속성 전개: `SpreadMarker<Frame>`
     - 이벤트: `OnChange`, `OnEvent` 디스크립터
     - 참조 바인딩: `FrameRefMarker` (`PreRef`, `PostRef`)
   - `Modifier`나 `Spread`, `OnEvent`는 결코 Frame의 "자식(Child)"이 아니며, Frame 자기 자신에게 적용되는 속성/수식자입니다.
   - 따라서 `ChildrenOf`라는 이름을 보면 사용자는 "여기엔 자식 인스턴스나 자식 컴포넌트만 들어갈 수 있다"고 타입을 좁게 오독하게 됩니다.
   - 결과적으로 Modifier나 이벤트 핸들러를 반환하는 헬퍼 함수를 작성할 때 `(): ChildrenOf<Frame>` 주석을 달며 개념적 거부감을 느끼게 됩니다.

### 3.2 `ArrItem<C>` 평가
1. **자기서술성의 우수함 [추정]**:
   - 저자의 의도대로 "props 테이블의 배열(Array) 자리에 놓이는 값"이라는 문법적 사실을 가장 정확하게 지칭합니다.
   - 배열 자리에 자식, Modifier, 이벤트 등 이질적인 것들이 공존하는 이유를 "배열 자리에 놓이는 아이템이기 때문"이라고 사실 기반으로 납득시킵니다.
2. **추상화 수준의 불일치 (도메인 누수) [추정]**:
   - `ArrItem`은 선언형 UI 컴포넌트의 도메인 개념이 아니라, Luau 언어의 테이블 내부 구조(`Array part` vs `Hash part`)를 타입 이름으로 직접 드러냅니다.
   - 선언형 UI를 작성하는 개발자가 컴포넌트 시그니처에 `local function Badge(): ArrItem<Frame>`을 적을 때, 고수준 UI 코드에 저수준 테이블 조작 어휘가 침투하는 이질감을 줍니다.
3. **코드베이스 명명 규칙과의 불일치 [실측/추정]**:
   - quad의 공개 타입들(`quad-types/src/init.luau` [실측]): `Modifier`, `SpreadMarker`, `SlotElement`, `StateMarker`, `ErrorNamespace` 등 모두 완전한 단어를 사용합니다.
   - `ArrItem`의 `Arr` 축약은 코드베이스 전반의 완전한 단어 지향 관행과 어긋납니다. 설령 `ArrayItem<C>`으로 풀더라도 여전히 건조합니다.

---

## 4. 이웃 타입과의 가족 일관성 분석

### 4.1 이웃 타입 패밀리 지형도 [실측]
현재 quad 시스템의 주요 타입 관계는 다음과 같습니다:
- `Props<C>`: 컴포넌트/요소에 넘기는 전체 props 테이블 (`.claude/audit/decl-typefn-probe-2026-10-16/src/Lib.luau:459` [실측])
- `Modifier<C>`: 특정 클래스에 적용되는 속성 수식자 체인 (`Lib.luau:461` [실측])
- `SpreadMarker<C>`: 상위 클래스 props 테이블을 인라인 전개하는 마커 (`Lib.luau:463` [실측])
- `Slot<T>`: 반응형 요소들의 슬롯 컨테이너 (`quad-types/src/init.luau:538` [실측])
- `SlotElement<T>`: `Slot<T>`의 배열 자리에 넣는 원소 유니언 (`quad-types/src/init.luau:528` [실측])
- `SlotItem<T>`: `Slot<T>`에서 꺼냈을 때의 언래핑 값 유니언 (`quad-types/src/init.luau:529` [실측])

### 4.2 `SlotElement<T>`가 존재함에도 `Elem`/`Element`를 피해야 하는 이유 [추정]
- `SlotElement<T>`는 quad-base 내부의 `Slot<T>` 전용 입력 타입입니다.
- 반면 props의 배열 자리 타입 `X<C>`는 사용자가 컴포넌트를 정의할 때마다 주석에 직접 작성하는 핵심 사용자 표면입니다.
- 저자는 값 쪽 생성자 꺼내기 함수를 `local Frame = Elem "Frame"`으로 확정하고자 합니다 (`.claude/research/declaration-surface-plan.md:66-68` [실측]).
- 만약 타입 쪽에 `Element<Frame>`이나 `ElemOf<Frame>` 같은 단어가 들어가면:
  - 값: `local Frame = Elem "Frame"`
  - 타입: `local function Badge(): Element<Frame>`
  - "값 `Elem`은 생성자인데, 타입 `Element`는 생성자가 아니라 배열 자리 유니언인가?"라는 치명적인 혼란이 발생합니다.
- 따라서 신규 제네릭 타입은 `Elem`/`Element` 어근을 완전히 배제해야 합니다.

### 4.3 가장 일관된 가족 선택: `Content<C>` [제안]
`Props<Frame>`과 `Content<Frame>`을 나란히 놓았을 때, 선언형 요소의 두 축이 완벽하게 성립합니다:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              Element "Frame"                           │
├───────────────────────────────────┬────────────────────────────────────┤
│           Props<Frame>            │           Content<Frame>           │
│   (문자열 키: 속성 및 이벤트 설정)  │     (숫자 키: 내부 구성물/내용물)   │
├───────────────────────────────────┼────────────────────────────────────┤
│ • Size, BackgroundColor3, ...     │ • TextLabel { ... } (자식 인스턴스) │
│ • MouseEnter, Activated, ...      │ • Modifier<Frame>   (수식자)       │
│                                   │ • SpreadMarker<GuiObject> (전개)   │
│                                   │ • OnEvent, OnChange (디스크립터)   │
│                                   │ • Ref, PreRef, PostRef (참조)      │
└───────────────────────────────────┴────────────────────────────────────┘
```

1. **상호 보완적 대칭성 [추정]**:
   - `Props<Frame>`: 요소의 외부 인터페이스(Properties)
   - `Content<Frame>`: 요소의 내부 구성물(Content)
2. **포함 관계의 명확성 [추정]**:
   - `SpreadMarker<Frame>`의 값은 `Content<Frame>` 유니언에 속합니다.
   - `Modifier<Frame>`의 값도 `Content<Frame>` 유니언에 속합니다.
   - `Instance` 또한 `Content<Frame>` 유니언에 속합니다.
   - "SpreadMarker와 Modifier는 Frame의 **Content** 중 하나다"라는 서술이 자연스럽게 성립합니다.
3. **가족 명칭의 통일성 [추정]**:
   `Props<Frame>`, `Content<Frame>`, `Modifier<Frame>`, `SpreadMarker<Frame>`이 모두 단일 명사 또는 명사+마커 조합으로 군더더기 없이 어우러집니다.

---

## 5. 최종 결론 및 권고

1. **1순위 추천 [제안]**: **`Content<C>`**
   - 자식, 수식자, 디스크립터, 마커를 모두 "요소의 내용물"로 완벽하게 포용합니다.
   - `Props<C>` ↔ `Content<C>` 대칭이 가장 우아하며, 값 생성자 `Elem`과의 혼동이 원천 차단됩니다.
   - 주석: `local function Badge(): Content<Frame>`, `function(children: { Content<GuiObject> })`.
2. **저자 예시 `ArrItem` 반영 대안 (위치 사실성 극대화) [제안]**: **`ArrayItem<C>`**
   - 만약 저자가 "내용물(Content)이라는 추상화보다, props 테이블의 배열 자리에 들어간다는 문법적 위치를 코드에 못 박는 것이 더 중요하다"고 판단한다면 이 안이 최선입니다.
   - 단, 축약 `ArrItem`보다는 코드베이스 규칙에 맞춰 완전한 단어인 `ArrayItem<C>`을 권장합니다.
3. **저자 예시 `ChildrenOf` 반영 대안 (직관성 극대화) [제안]**: **`Child<C>`**
   - 만약 저자가 "Modifier/디스크립터와의 개념적 불일치를 감수하더라도, React/선언형 UI에 익숙한 대다수 사용자의 직관을 최우선시한다"고 판단한다면 이 안이 최선입니다.
   - 단, 복수형 `ChildrenOf`는 `{ ChildrenOf<Frame> }`에서 이중 복수 어색함이 발생하므로 단수형 `Child<C>`로 교정하는 것을 강력히 권장합니다.
