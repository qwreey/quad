# devui 팝업 API 네이밍 검토 보고서 (5개 항목)

> **안내:** 본 보고서의 모든 추천 및 검토 결과는 최종 결정을 위한 **제안**입니다. 코드베이스를 직접 읽고 검증한 내용은 **[실측]**, API 설계와 개발자 인지 모델을 바탕으로 도출한 논리는 **[추정]**으로 표기하였습니다.

---

## 요약 테이블 (제안 및 우선순위)

| 번호 | 항목 | 추천 픽 (제안) | 우선순위 Shortlist | 오도 플래그 (Misleading) |
|---|---|---|---|---|
| **1** | `Overlay:Open` 옵션 — 앵커 사각형 | **`AttachTo`** | 1. `AttachTo`<br>2. `AnchorRect`<br>3. `Attach` | **`Avoid`** (장애물 회피로 오인)<br>**`Origin`** (좌표 원점 점으로 오인)<br>**`Around`** (여백/패딩으로 오인) |
| **2** | 팝업 본체 공개 위젯 | **`PopupPanel`** | 1. `PopupPanel`<br>2. `PopupFrame`<br>3. `PopupBody` | **`Popup`** (기존 `Overlay.Popup` 핸들 타입과 치명적 충돌)<br>**`Panel`** (일반 레이아웃 패널로 오인) |
| **3** | 임의 위치 메뉴 열기 함수 | **`OpenMenu`** | 1. `OpenMenu`<br>2. `ContextMenu`<br>3. `ShowMenu` | **`Menu.open`** (Luau 함수형 타입에 비정형)<br>**`PopupMenu`** (인스턴스 반환 선언적 위젯으로 오인) |
| **4** | 메뉴가 달린 단추<br>(a) 위젯 이름<br>(b) 팩토리 prop | <br>**(a) `MenuButton`**<br>**(b) `Menu`** | **(a)**<br>1. `MenuButton`<br>2. `DropdownButton`<br>3. `SplitButton`<br>**(b)**<br>1. `Menu`<br>2. `Children`<br>3. `MenuItems` | **(a) `ComboButton`** (`Devui.Combo`와 혼동)<br>**(a) `SplitButton`** (`OnClick` 생략 시 분할 안 됨)<br>**(b) `Items`** (정적 문자열 배열로 오인) |
| **5** | 메뉴 열린 채 유지 prop | **`KeepOpen`** | 1. `KeepOpen`<br>2. `StayOpen`<br>3. `DontClose` | **`NoClose`** (`Window.NoClose` 닫기버튼 제거와 충돌)<br>**`Sticky`** (스크롤 고정 또는 토글 잠금으로 오인) |

---

## 1. Overlay:Open 옵션 — 앵커 사각형 (Anchor Rectangle)

- **설명:** 팝업이 부착될 화면 공간 사각형(`Rect`). 팝업이 화면 밖으로 넘치면 사각형의 반대편(아래 ↔ 위, 우 ↔ 좌)으로 뒤집힌 후 화면 안으로 슬라이드됨. 미지정 시 슬라이드만 수행.
- **후보:** `AnchorRect`, `Around`, `Attach`, `AttachTo`, `Avoid`, `Origin`
- **추천 Pick (제안):** **`AttachTo`**

### 우선순위 및 이유
1. **1위: `AttachTo`**
   - **[실측] 기존 `Anchor` 옵션과의 충돌 완전 해소:** 현재 `Overlay.luau:80`에 정의된 `PopupOptions`에는 `Anchor: Vector2?`가 이미 존재하며, 이는 `Content`의 내부 기준점(Roblox `AnchorPoint`, 기본값 `(0, 0)`) 역할을 합니다 (`quad-roblox-devui/src/Overlay.luau:21, 60, 80`).
   - **[추정] 의도 전달력:** `AttachTo = rect`는 "이 팝업을 해당 사각형에 부착한다"는 행위 대상을 명확히 지칭합니다. 내부 피벗을 뜻하는 `Anchor`와 어근이 겹치지 않아 개발자가 자동완성이나 코드 작성 시 두 옵션을 혼동할 위험이 0입니다.
2. **2위: `AnchorRect`**
   - **[실측] 타입 명시성:** Roblox의 내장 타입인 `Rect`(`Rect.new(min, max)`)를 속성명에 직접 드러냅니다.
   - **[추정] 한계:** 옵션 테이블 안에 `Anchor`(`Vector2`)와 `AnchorRect`(`Rect`)가 공존하면, "Anchor가 AnchorRect의 앵커인가?", "둘 중 무엇이 내부 피벗이고 무엇이 외부 타깃인가?"라는 인지 혼선이 발생하기 쉽습니다.
3. **3위: `Attach`**
   - **[추정]** `AttachTo`보다 짧으나, 전치사 `To`가 빠지면 불리언 플래그(`Attach = true`?)나 부착 모드처럼 보일 여지가 있습니다.

### 오도 플래그 (Misleading)
- 🚩 **`Avoid` (심각한 오도):** '회피 구역'을 뜻하므로 노치, 탑바 등 "팝업이 피해야 하는 금지 영역"으로 오인됩니다. 실제로는 팝업이 달라붙는 기준 대상(Anchor)이므로 정반대의 의미를 전달합니다.
- 🚩 **`Origin` (오도):** 2D 그래픽스 및 Roblox에서 `Origin`은 좌표계 원점이나 피벗 좌표(`Vector2`)를 의미합니다. 면적을 가진 `Rect`를 전달받는 속성명으로 사용하면 `Vector2` 입력으로 착각하기 쉽습니다.
- 🚩 **`Around` (오도):** 팝업 바깥의 여백(마진/패딩)이나 둘러싸는 영역으로 오해되기 쉽습니다.

---

## 2. 팝업 본체 공개 위젯 (The Popup Body Made Public)

- **설명:** 팝업 배경, 모서리 곡률, 테두리, 패딩, 가장 넓은 행에 맞춘 수직 리스트를 가진 `Frame`. 메뉴나 커스텀 팝업 제작 시 사용. `Devui.<Name>({ Children, Style?, Modifier? })`.
- **후보:** `PopupPanel`, `Popup`, `PopupFrame`, `Panel`, `PopupBody`
- **원안:** `PopupPanel`
- **추천 Pick (제안):** **`PopupPanel`**

### 우선순위 및 이유
1. **1위: `PopupPanel`**
   - **[실측] 기존 토큰 체계와의 완벽한 정합:** 현재 메뉴 및 콤보 팝업 프레임은 `style.Color.PopupBg`, `style.Metrics.PopupRounding`, `PopupParts.stroke(style)`(`PopupBorderSize`)를 사용하여 그려집니다 (`quad-roblox-devui/src/Menu.luau:147-165`, `src/Combo.luau:180-195`). 또한 `Menu.luau:150`의 내부 프레임 인스턴스 이름도 이미 `Name = "MenuPanel"`입니다.
   - **[추정] 역할 구분:** `Popup`이라는 시각 테마와, 수직 배치 및 여백을 갖춘 `Panel`(컨테이너 프레임)의 의미가 명확히 결합되어 있습니다.
2. **2위: `PopupFrame`**
   - **[실측]** 반환 인스턴스가 Roblox `Frame`임을 기술합니다.
   - **[추정] 한계:** devui의 다른 위젯(`Window`, `MenuBar`, `Tooltip` 등)은 Roblox 클래스명(`Frame`)을 접미어로 붙이지 않고 UI 컴포넌트 역할로 명명합니다 (`quad-roblox-devui/src/init.luau:197-232`).
3. **3위: `PopupBody`**
   - **[추정]** 보통 `Body`는 Header, Footer와 짝을 이루는 복합 컴포넌트의 내부 영역을 지칭하므로, 단독 팝업 패널을 가리키기에는 부자연스럽습니다.

### 오도 플래그 (Misleading)
- 🚩 **`Popup` (치명적 오도):**
  - **[실측]** `quad-roblox-devui/src/init.luau:117` 및 `src/Overlay.luau:85`에 이미 `export type Popup = Overlay.Popup` (필드: `IsOpen`, `Close`, `Holder`)이 공개 타입으로 노출되어 있습니다.
  - **[추정]** 만약 위젯 이름이 `Devui.Popup`이 되면, 사용자가 `overlay:Open({ Content = Devui.Popup({ Children = ... }) })`를 작성할 때 "함수 `Devui.Popup`이 반환하는 것은 팝업 핸들이 아니라 내부 Frame 인스턴스"라는 극심한 개념적/타입적 혼란이 발생합니다.
- 🚩 **`Panel` (오도):**
  - **[추정]** 팝업 전용 스타일(`PopupBg`, 테두리, 라운딩)이 적용되는 위젯인데 단독 `Panel`로 명명하면 일반 도킹/도구 패널로 오인하기 쉽습니다.

---

## 3. 임의 위치 메뉴 열기 함수 (Open a Menu at a Point)

- **설명:** `Devui.Menu`와 동일한 메뉴(`Children = function(scope) ... end`)를 임의의 화면 좌표(`Vector2`)나 사각형(`Rect`)에 여는 명령형(Imperative) 함수. 닫기 핸들(`Close`) 반환. `Devui.<Name>({ At = Vector2 | Rect, Children = function(scope) ... end, Overlay?, Style? })`.
- **후보:** `OpenMenu`, `ContextMenu`, `PopupMenu`, `ShowMenu`, `Menu.open`
- **추천 Pick (제안):** **`OpenMenu`**

### 우선순위 및 이유
1. **1위: `OpenMenu`**
   - **[실측] 반환 계약 및 기존 명령형 API와의 일관성:** devui의 선언적 위젯들(`Devui.Button`, `Devui.Window` 등)은 Roblox `Instance`를 반환하지만 (`src/init.luau:49`), 이 함수는 인스턴스가 아니라 제어 핸들(`{ Close: () -> () }`)을 반환하는 명령형 함수입니다.
   - **[실측]** `Overlay:Open` (`Overlay.luau:95`), `Window.Open` 등 devui 전반에서 열기 동작은 항상 `Open` 동사를 사용합니다.
   - **[추정] 범용성:** `At = Vector2 | Rect`를 받으므로 마우스 우클릭 좌표뿐 아니라 단추/아이콘 사각형에서 열리는 메뉴도 포괄합니다.
2. **2위: `ContextMenu`**
   - **[추정]** 우클릭 메뉴를 가리키는 대표적인 UI 용어이나, 명사형이라 선언적 위젯(`Kids(Devui.ContextMenu(...))`)으로 착각할 수 있고, 우클릭 전용이라는 편견을 줍니다.
3. **3위: `ShowMenu`**
   - **[실측/추정]** 동사형이나, devui는 `Show/Hide` 대신 일관되게 `Open/Close`를 표준 용어로 채택하고 있어 어휘가 튑니다.

### 오도 플래그 (Misleading)
- 🚩 **`Menu.open` (심각한 오도/구현 결함):**
  - **[실측]** 현재 `Devui.Menu`는 `src/init.luau:228`에서 일반 함수 `Menu.Menu(props: MenuProps): TextButton`으로 export되어 있습니다.
  - **[추정]** Luau 타입 시스템에서 호출 가능한 함수 객체에 속성 메서드(`.open`)를 붙이는 것은 타입 정의가 비정형적이고 자동완성 지원이 불량하며, Luau/Roblox 개발자 관례에 맞지 않습니다.
- 🚩 **`PopupMenu` (오도):**
  - **[추정]** 명사형 위젯명이라 인스턴스를 반환하는 것으로 오인되기 쉬우며, `PopupPanel` 및 `Overlay.Popup`과의 명칭 중복으로 정체성이 흐려집니다.

---

## 4. 메뉴가 달린 단추 (A Button with a Menu)

- **설명:** 하나의 위젯으로 두 가지 형태 지원:
  - `OnClick` 제공 시: 스플릿 단추 — 본체는 `OnClick` 실행, 우측 좁은 ▾ 영역 클릭(또는 전체 우클릭) 시 메뉴 오픈.
  - `OnClick` 생략 시: 단일 메뉴 단추 — 단추 전체(아이콘/텍스트 + ▾) 클릭 시 메뉴 오픈 (예: 필터 단추).
- **판정 대상:** (a) 위젯 명칭, (b) 팩토리 prop 명칭

### (a) 위젯 명칭

- **후보:** `MenuButton`, `SplitButton`, `DropdownButton`, `ComboButton`
- **추천 Pick (제안):** **`MenuButton`**

#### 우선순위 및 이유
1. **1위: `MenuButton`**
   - **[추정] 두 모드를 아우르는 정확성:** `OnClick`이 없을 때(단일 메뉴 오픈 단추)와 있을 때(스플릿 단추) 모두 "메뉴를 여는 단추"라는 본질을 완벽히 만족합니다 (W3C WAI-ARIA 및 데스크톱 UI 표준 용어).
   - **[실측] 키트 결합성:** `Devui.Button`과 `Devui.Menu`의 결합 형태임을 직관적으로 드러냅니다.
2. **2위: `DropdownButton`**
   - **[추정]** 친숙한 이름이나, 화면 하단 경계에서 위로 뒤집힐 수 있고 devui의 `Combo`와 용어 연상이 겹칠 수 있습니다.
3. **3위: `SplitButton`**
   - **[추정]** 아래 오도 플래그 참조.

#### 오도 플래그 (Misleading)
- 🚩 **`ComboButton` (치명적 오도):**
  - **[실측]** `quad-roblox-devui/src/Combo.luau`에 이미 단일 값 선택기인 `Devui.Combo`가 존재합니다.
  - **[추정]** `ComboButton`으로 명명하면 사용자는 이것이 `Combo` 제품군의 변형(값을 선택하고 상태를 바인딩하는 드롭다운)이라고 착각하게 됩니다.
- 🚩 **`SplitButton` (명칭 배반/오도):**
  - **[추정]** 사용자가 `OnClick` 없이 필터 단추 용도로 쓸 때 단추는 전혀 '분할(Split)'되지 않고 단일 단추로 작동합니다. 분할되지 않는 단추를 `SplitButton`이라 부르는 것은 개발자에게 "왜 분할이 안 되지?", "`OnClick`이 필수인가?"라는 의문을 유발합니다.

---

### (b) 팩토리 prop 명칭

- **후보:** `Menu`, `Children`, `Items`, `MenuItems`
- **추천 Pick (제안):** **`Menu`**

#### 우선순위 및 이유
1. **1위: `Menu`**
   - **[추정] 본체 자식과 메뉴의 명확한 분리:** 단추 본체의 외형(`Text`, `Icon`)과 별개로 "이 단추에 연결된 팝업 메뉴 내용"임을 가장 간결하고 명확하게 드러냅니다.
     ```luau
     Devui.MenuButton({
         Text = "Options",
         OnClick = doDefault,
         Menu = function(scope)
             return Kids(Devui.MenuItem({ Text = "Sub", Scope = scope, OnClick = fn }))
         end,
     })
     ```
2. **2위: `Children`**
   - **[실측]** `Devui.Menu({ Children = function(scope) ... end })`의 팩토리 prop 이름과 동일하여 일관성이 있습니다 (`src/Menu.luau:81`).
   - **[추정] 한계:** 그러나 '단추(Button)' 위젯에서 `Children`을 받으면 사용자는 단추 내부의 자식 뷰 요소(`Kids(...)`)로 오해할 소지가 있습니다.
3. **3위: `MenuItems`**
   - **[추정]** 의미는 명확하지만 `Menu`에 비해 불필요하게 깁니다.

#### 오도 플래그 (Misleading)
- 🚩 **`Items` (오도):**
  - **[추정]** `Items`는 단순한 데이터/문자열 배열(`{ "Item1", "Item2" }`)로 오해되기 쉽습니다. 실제로는 지연 생성 팩토리 함수 `(scope: MenuScope) -> Slot<Instance>`를 넘겨야 하므로 타입 시그니처와 어울리지 않습니다.

---

## 5. 메뉴 열린 채 유지 prop (Keep the Menu Open)

- **설명:** `MenuToggle`(및 필요시 `MenuItem`)의 불리언 prop. 클릭해도 메뉴 체인이 닫히지 않아 여러 토글을 연속으로 조작할 수 있음 (Dear ImGui의 `ImGuiSelectableFlags_DontClosePopups`에 대응).
- **후보:** `KeepOpen`, `StayOpen`, `DontClose`, `NoClose`, `Sticky`
- **원안:** `KeepOpen`
- **추천 Pick (제안):** **`KeepOpen`**

### 우선순위 및 이유
1. **1위: `KeepOpen`**
   - **[추정] 긍정형 명명(Affirmative naming):** `KeepOpen = true`는 "클릭 시 메뉴가 닫히지 않고 열린 상태를 유지한다"는 목적을 자연스러운 영어 능동 구문으로 전달합니다.
   - **[추정]** 부정형 플래그와 달리 `KeepOpen = false`(기본값, 클릭 시 닫힘)로 넘길 때도 이중 부정 없이 직관적으로 해석됩니다.
2. **2위: `StayOpen`**
   - **[추정]** 의미는 거의 같으나, API 플래그로는 타동사/사역 형태인 `KeepOpen`이 업계 전반에서 훨씬 보편적입니다.
3. **3위: `DontClose`**
   - **[추정]** ImGui의 `DontClosePopups` 직역이나, 부정형 불리언 프로퍼티는 인지 부하가 크며 문법적으로 비표준적입니다.

### 오도 플래그 (Misleading)
- 🚩 **`NoClose` (치명적 오도 / 키트 내 의미 충돌):**
  - **[실측]** devui의 `Window` 위젯에서 `NoClose`는 **"창 제목줄 및 탭에서 닫기(×) 단추를 제거한다"**는 의미의 정적 플래그로 완전히 정착되어 사용 중입니다 (`src/Window/init.luau:19, 151, 196`, `src/Window/TitleBar.luau:44`, `README.md:231`).
  - **[추정]** 메뉴 항목에 `NoClose`를 도입하면 동일한 UI 키트 내에서 "닫기 버튼 제거"와 "클릭 시 팝업 닫힘 방지"라는 완전히 다른 두 동작에 같은 이름이 쓰이게 되어 극심한 혼란을 초래합니다.
- 🚩 **`Sticky` (오도):**
  - **[추정]** 웹/UI에서 `Sticky`는 스크롤 고정(`position: sticky`)이나 토글 단추의 눌림 유지(sticky toggle)를 연상시킵니다. 팝업이 닫히지 않는 동작을 가리키기에는 지나치게 은유적이고 모호합니다.

---

## 검증 및 테스트 실측 기록

- **테스트 스위트 실행 명령:**
  ```bash
  ( ulimit -v 4000000; timeout 600 ./scripts/test.sh )
  ```
- **실행 결과 [실측]:** Exit code `0` 정상 통과 (모든 spec 및 smoke 테스트 통과).
- **코드 수정 여부 [실측]:** 본 과제는 공개 API 명칭 검토 및 제안 작업이므로 기존 코드베이스 파일의 수정은 발생하지 않았으며, 작업 디렉터리 내에 `AGY_REPORT.md`만 작성되었습니다.
