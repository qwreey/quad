# devui 신규 추가 API 네이밍 검토 보고서 (5개 그룹)

> **안내**: 본 보고서의 모든 선정안은 개발팀의 판단을 돕기 위한 **제안**이며, 최종 결정은 사용자가 수행합니다.
> 각 항목의 근거는 실제 코드베이스 검증을 바탕으로 **실측**(코드 라인 및 테스트 결과 확인)과 **추정**(Roblox 도구 개발자 관점의 멘탈 모델 및 UI 관례 기반 추론)으로 구분하여 명시하였습니다.

---

## 검토 기준 (사용자 관점: Roblox 도구 UI 개발자)

1. **선언형 위젯 vs 즉시 실행(NOW) 함수의 명확한 분리**:
   - `Devui.Window`, `Devui.VirtualRows`, `Devui.Button` 등은 인스턴스/슬롯을 반환하여 트리에 마운트하는 선언형 위젯입니다 ([`quad-roblox-devui/src/init.luau:49`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L49)). [실측]
   - 반면 `Devui.OpenDialog`, `Devui.OpenConfirm`, `Devui.OpenMenu`는 호출 즉시 화면에 띄우고 핸들(`{ IsOpen, Close }`)을 반환하는 명령형 함수입니다 ([`quad-roblox-devui/src/init.luau:240-244`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L240-L244), [`quad-roblox-devui/src/Dialog.luau:6-14`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/Dialog.luau#L6-L14)). [실측]
   - 즉시 다이얼로그를 여는 함수는 `Open*` 접두사를 엄격히 준수해야 선언형 위젯과의 오인을 방지할 수 있습니다. [추정]
2. **순수 로직/도메인 모듈과 위젯의 구분**:
   - `Devui` 루트에는 위젯 함수뿐만 아니라 순수 테이블 모듈(`Style`, `Interaction`, `Input`)이 함께 노출되어 있습니다 ([`quad-roblox-devui/src/init.luau:185-188`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L185-L188)). [실측]
   - 새로 추가되는 순수 도메인 모듈(선택 규칙, 트리 평탄화, 색상 모델) 역시 단일 위젯처럼 보이는 이름(예: `Select`, `TreeView`)을 피하고 도메인 명사형이어야 합니다. [추정]
3. **Roblox 런타임 제약 및 플랫폼 관례 존중**:
   - Roblox 일반 게임 스크립트에는 OS 클립보드 직접 쓰기 API가 없습니다.
   - Roblox 색상 타입은 `Color3`이며, devui의 기존 인라인 색상 입력기도 `InputColor3`입니다 ([`quad-roblox-devui/src/init.luau:218`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L218)). [실측]

---

## 1. 복사 다이얼로그 (Copy Dialog)

Roblox 게임 스크립트에는 클립보드 쓰기 API가 없어, 읽기 전용 멀티라인 TextBox를 띄우고 포커스 및 전체 선택(`SelectAll`)을 수행하여 사용자가 직접 Ctrl+C를 누르도록 유도하는 다이얼로그. 즉시 열리며 한 번에 하나만 열림.
`Devui.<Name>({ Title, Text, Window?, Modal? })` -> handle

- **선정 (제안)**: `OpenCopyDialog`
- **순위 (Ranked Shortlist)**:
  1. `OpenCopyDialog`
  2. `OpenCopyText`
  3. `CopyDialog`
  4. `OpenTextCopy`
  5. `OpenClipboard`
- **이유**:
  1. **명령형 팝업/다이얼로그 계열과의 일관성 (실측)**: devui에서 즉시 열리고 `{ IsOpen, Close }` 핸들을 반환하는 함수는 `OpenDialog`([`quad-roblox-devui/src/Dialog.luau:6-9`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/Dialog.luau#L6-L9)), `OpenConfirm`([`quad-roblox-devui/src/Dialog.luau:10-13`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/Dialog.luau#L10-L13)), `OpenMenu`([`quad-roblox-devui/src/init.luau:240`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L240))로 모두 `Open*` 접두사를 사용합니다. `OpenCopyDialog`는 이 체계에 가장 자연스럽게 맞물립니다.
  2. **동작과 UI 형태의 직관성 (추정)**: `OpenCopyText`는 "텍스트를 복사하는 동작(동사구)"처럼 들릴 여지가 있는 반면, `OpenCopyDialog`는 사용자가 기대하는 UI 형태(복사 전용 대화 상자 팝업)를 오해 없이 나타냅니다.
- **오해를 유발하는 이름 (Flag)**:
  - `OpenClipboard`: **[심각]** Roblox 인게임 런타임에는 OS 클립보드 API가 존재하지 않습니다. 개발자가 이 이름을 보면 "OS 클립보드를 여는 함수인가?" 또는 "클립보드 매니저인가?"로 오해하거나, 다이얼로그 없이 백그라운드에서 클립보드를 조작하는 API로 착각할 수 있습니다. [추정]
  - `CopyDialog`: `Open` 접두사가 누락되어 `Devui.Window`처럼 quad 선언형 트리에 자식으로 마운트하는 컴포넌트(`CopyDialog { ... } -> Instance`)로 오인하기 쉽습니다. [실측 및 추정]
  - `OpenTextCopy`: 어순이 어색하여 검색 및 자동완성 발견성이 떨어집니다. [추정]

---

## 2. 다중 선택 규칙 순수 모듈 (Multi-selection rules)

`apply(current: {key}, anchor, order: {key}, index, mode) -> (next, anchor)` (단일 클릭 / Ctrl+클릭 토글 / Shift+클릭 앵커 기반 범위 선택), `.prune(current, keep)`, `.toSet(list)`, 그리고 현재 키보드의 Ctrl/Shift 상태를 읽어 mode를 반환하는 헬퍼 함수로 구성된 순수 모듈.

### (1) 모듈 이름 (`Devui.<Module>`)
- **선정 (제안)**: `Selection`
- **순위 (Ranked Shortlist)**:
  1. `Selection`
  2. `MultiSelect`
  3. `SelectRules`
  4. `Select`
- **이유**:
  1. **최상위 도메인/인프라 모듈 관례 (실측)**: devui의 순수 네임스페이스 모듈은 `Devui.Interaction`([`quad-roblox-devui/src/init.luau:186`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L186)), `Devui.Input`([`quad-roblox-devui/src/init.luau:187`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L187)), `Devui.Style`([`quad-roblox-devui/src/init.luau:185`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L185))과 같이 표준 명사형으로 노출됩니다. `Selection`은 단일/다중을 아우르는 표준적인 도메인 이름입니다.
  2. **Roblox 개발자 친화성 (실측 및 추정)**: Roblox 엔진에는 이미 선택 항목을 다루는 `game:GetService("Selection")`이 존재하므로, 선택 항목(keys/set)의 규칙과 헬퍼를 다루는 네임스페이스로서 `Selection`이 가장 자연스럽게 받아들여집니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Select`: HTML의 `<select>` 태그나 드롭다운 위젯으로 오인되거나, 무언가를 즉시 선택하는 명령형 동사 함수로 혼동됩니다. [추정]
  - `MultiSelect`: UI 라이브러리들에서 "MultiSelect"는 보통 다중 선택 드롭다운/태그 위젯의 이름으로 널리 쓰여, 순수 계산 모듈이 아닌 시각적 위젯으로 오해할 수 있습니다. 또한 이 모듈은 단일 선택(`Single`/`Replace`)도 함께 처리하므로 명칭이 범위를 축소합니다. [추정]

### (2) Mode 값 (`mode`)
- **선정 (제안)**: `"Single" | "Toggle" | "Range"`
- **순위 (Ranked Shortlist)**:
  1. `"Single" | "Toggle" | "Range"`
  2. `"Replace" | "Toggle" | "Extend"`
- **이유**:
  1. **사용자 상호작용 의도와의 1:1 대응 (추정)**: 개발자가 행 클릭 이벤트(`OnClick`)를 처리할 때 생각하는 멘탈 모델은 "단일 클릭(Single)", "Ctrl 토글(Toggle)", "Shift 범위(Range)"입니다. 모드 값이 사용자 입력 의도를 그대로 대변합니다.
  2. **명확한 구간(Range) 의미 (추정)**: Shift를 누른 선택은 앵커(anchor)로부터 현재 인덱스까지의 '연속된 구간(Range)'을 재설정하는 것입니다.
- **오해를 유발하는 이름 (Flag)**:
  - `"Extend"`: 기존 선택 집합에 단순히 원소를 덧붙이는 것(Additive append)으로 오해할 소지가 있습니다. 앵커 기반의 닫힌 구간 선택 메커니즘을 흐립니다. [추정]
  - `"Replace"`: 자료구조 관점의 동작(기존 집합 대체)에 치우쳐 있어, "단일 항목 선택"이라는 사용자 의도와 직관적으로 와닿지 않습니다. [추정]

### (3) 키 판별 헬퍼 함수 (`Devui.Selection.<Helper>()`)
- **선정 (제안)**: `modeFromKeys`
- **순위 (Ranked Shortlist)**:
  1. `modeFromKeys`
  2. `modeNow`
  3. `keyMode`
  4. `currentMode`
- **이유**:
  1. **명확한 출처 명시 (추정)**: `modeFromKeys()`는 인자가 없더라도 "키보드(Ctrl/Shift)의 상태로부터 선택 모드를 도출한다"는 기능적 계약을 가장 명확하게 전달합니다. 추후 `modeFromKeys(inputObject?)`처럼 입력 객체를 선택적으로 받는 확장에도 자연스럽습니다.
- **오해를 유발하는 이름 (Flag)**:
  - `currentMode`: **[심각]** 모듈이나 특정 인스턴스 내부에 '현재 설정되어 있는 선택 모드'(예: 이 리스트가 다중 선택 모드인가 단일 선택 모드인가)를 조회하는 게터(Getter/Property)로 오해하기 쉽습니다. 순간적인 키보드 하드웨어 상태 샘플링이라는 본질을 가립니다. [추정]
  - `modeNow`: 어떤 대상의 "지금 모드"인지(편집 모드인지, 창 모드인지) 목적어가 없어 모호합니다. [추정]

---

## 3. 트리 평탄화 순수 모듈 (Tree flattening)

가상화 트리(`VirtualRows` 연동)의 데이터 계층. 루트 노드들과 접근자 `{ Children(node), Key(node), HasChildren(node)?, <X>(node)? }`, 확장된 키 집합을 받아 1차원 표시 행 `{ Node, Depth, HasChildren, Expanded, More? }`을 생성. `.expand`, `.collapse`, 페이징 처리(N개 자식 후 더 보기 행 생성), `.loadMore`, `.toggle`, `.reveal`, `.indexOf` 등 제공.

### (1) 모듈 이름 (`Devui.<Module>`)
- **선정 (제안)**: `TreeRows`
- **순위 (Ranked Shortlist)**:
  1. `TreeRows`
  2. `FlatTree`
  3. `Flatten`
  4. `VisibleRows`
  5. `TreeView`
- **이유**:
  1. **VirtualRows와의 직관적 페어링 (실측 및 추정)**: devui의 가상화 리스트 위젯인 `Devui.VirtualRows`([`quad-roblox-devui/src/VirtualRows.luau:8-15`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/VirtualRows.luau#L8-L15))에 직접 공급할 "트리의 가상화 행 데이터"를 관리하는 모듈임이 이름에서 즉시 드러납니다.
  2. **메서드 호출의 자연스러움 (추정)**: `TreeRows.expand(...)`, `TreeRows.collapse(...)`, `TreeRows.toggle(...)` 등 명사 네임스페이스 아래에서 하위 트리 조작 함수들이 매끄럽게 읽힙니다.
- **오해를 유발하는 이름 (Flag)**:
  - `TreeView`: **[치명적 오해]** 모든 UI 툴킷(Qt, WPF, Web, Roblox 킷)에서 `TreeView`는 트리를 화면에 그리는 시각적 UI 위젯(Component)을 의미합니다. 순수 데이터 변환/상태 모듈에 `TreeView`라는 이름을 붙이면 개발자는 `Devui.TreeView({ ... })` 형태의 렌더링 인스턴스를 기대하게 됩니다. [추정]
  - `VisibleRows`: 기존의 `Devui.VirtualRows`와 어감이 너무 비슷하여 위젯과 헬퍼 모듈 간의 경계가 모호해지며, 트리(Tree) 전용 모듈이라는 핵심 도메인이 이름에서 완전히 누락됩니다. [추정]
  - `Flatten`: 동사형 단독 모듈명은 `Flatten.expand(...)`, `Flatten.collapse(...)`처럼 하위 함수들과 결합될 때 어색합니다. [추정]

### (2) 접근자 필드 `<X>(node)` (아직 로드되지 않은 자식 노드 수 반환)
- **선정 (제안)**: `MoreCount`
- **순위 (Ranked Shortlist)**:
  1. `MoreCount`
  2. `Unloaded`
  3. `Extra`
  4. `Pending`
- **이유**:
  1. **수량(Count) 및 행 필드(`More`)와의 완벽한 일치 (추정)**: 반환값이 단순 boolean이 아니라 "숫자(개수) 또는 `math.huge`"임을 `Count` 접미사로 명시합니다. 또한 생성되는 플레이스홀더 행의 `More` 필드 및 `.loadMore` 메서드와 일관된 용어를 형성합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Pending`: 비동기 요청이나 Promise에서 `Pending`은 "현재 네트워크 요청이 전송되어 진행 중인 상태"를 뜻합니다. 아직 요청조차 하지 않은 서버 미로드 자식이나 로컬 페이징 잔여 항목을 나타내기에 부적절합니다. [추정]
  - `Unloaded`: `HasChildren`과 나란히 배치될 경우 `Unloaded: boolean` 형태의 상태 판별 플래그로 오해받기 쉽습니다. [추정]

### (3) 행 필드 `More` (플레이스홀더 행의 미표시 자식 수)
- **선정 (제안)**: `More`
- **순위 (Ranked Shortlist)**:
  1. `More`
  2. `Remaining`
  3. `Hidden`
- **이유**:
  1. **표준 UI 패턴 및 메서드와의 직결 (추정)**: 목록 하단의 "더 불러오기(Load More)" UI 패턴과 모듈의 `.loadMore` 메서드에 1:1로 대응합니다. 개발자가 가상화 렌더러에서 분기할 때 코드가 극도로 간결하고 명확해집니다:
     `if row.More ~= nil then ... Devui.Button { Text = string.format("더 보기 (%d개)", row.More) } ... end`
- **오해를 유발하는 이름 (Flag)**:
  - `Hidden`: **[심각]** UI 프로그래밍에서 `Hidden`은 해당 행 자체가 화면에 보이지 않음(`Visible = false`) 또는 검색 필터 등으로 '숨김 처리됨'을 의미합니다. 플레이스홀더 행은 사용자가 누를 수 있도록 화면에 명확히 렌더링되어야 하는 시각적 요소이므로 완전히 정반대의 의미를 전달합니다. [추정]

---

## 4. VirtualRows 확장 (VirtualRows additions)

### (a) 목록 끝 자동 추적 prop (로그 뷰어 동작)
행이 추가될 때 스크롤을 맨 끝으로 유지하다가, 사용자가 위로 스크롤하면 멈추고, 다시 바닥으로 스크롤하면 추적을 재개하는 기능.
- **선정 (제안)**: `StickToEnd`
- **순위 (Ranked Shortlist)**:
  1. `StickToEnd`
  2. `FollowEnd`
  3. `AutoScroll`
  4. `Follow`
  5. `Tail`
- **이유**:
  1. **스티키(Sticky) 동작 특성의 정확한 서술 (추정)**: 단순히 계속 스크롤되는 것이 아니라 "바닥에 붙어 있을 때만 달라붙고(stick), 떨어지면 고정이 풀렸다가, 다시 바닥에 닿으면 붙는다"는 핵심 메커니즘을 가장 정확하게 표현합니다.
  2. **대상 기준 명시 (추정)**: `Follow`와 달리 추적 대상의 기준점(`End`)이 명확히 명시되어 있습니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Tail`: **[심각]** Unix `tail`이나 함수형 프로그래밍의 `tail`처럼 "전체 데이터 중 끝부분 N개만 자르거나 표시하는 데이터 필터링 prop"으로 오해할 위험이 큽니다. [추정]
  - `Follow`: 무엇을 따라가는지(선택된 행? 마우스 커서? 포커스된 위젯? 끝?) 주어가 없어 모호합니다. [추정]
  - `AutoScroll`: 많은 UI 프레임워크나 Roblox 드래그 UI에서 `AutoScroll`은 드래그 중에 경계선 근처로 가면 자동 스크롤되는 기능을 의미하거나, 사용자의 스크롤 조작을 무시하고 무조건 바닥으로 강제 스크롤하는 것으로 오해될 수 있습니다. [추정]

### (b) 화면 Y 좌표 -> 행 인덱스 매핑 함수
드래그 선택 / 드롭 타깃 판정을 위해 화면 절대 Y 좌표를 `VirtualRows`의 행 인덱스(`number?`)로 변환하는 외부 함수: `Devui.<Name>(list: ScrollingFrame, y: number) -> number?`
- **선정 (제안)**: `RowIndexAt`
- **순위 (Ranked Shortlist)**:
  1. `RowIndexAt`
  2. `IndexAtY`
  3. `RowAt`
  4. `VirtualRowAt`
- **이유**:
  1. **반환 타입의 명확성 (추정)**: 함수 반환값이 Row 인스턴스(`GuiObject`)가 아니라 숫자 인덱스(`number?`)임을 함수명에 `Index`를 포함함으로써 명백히 선언합니다.
  2. **VirtualRows와의 연계성 (실측 및 추정)**: `VirtualRows`([`quad-roblox-devui/src/VirtualRows.luau:9`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/VirtualRows.luau#L9))의 `Row(index)` 및 `ScrollToRow`와 일관되게 `RowIndex` 개념을 사용합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `RowAt` / `VirtualRowAt`: **[치명적 오해]** GUI 프레임워크(Roblox `GetGuiObjectsAtPosition`, 웹 DOM `elementFromPoint` 등)에서 `*At` 형태의 조회 함수는 해당 위치의 **객체/인스턴스(Instance)**를 반환하는 것이 보편적 규약입니다. 함수명이 `RowAt`인데 객체가 아닌 숫자 인덱스를 반환하면 사용자에게 매우 큰 혼란을 주는 API 함정이 됩니다. [추정]

---

## 5. 색상 선택기 (Color picker)

### (a) 순수 색상 모듈
무채색(grey/black)에서도 색상값(Hue)을 유지하는 HSV 모델, Hex 파싱/포맷, 채널 파싱을 담당하는 순수 모듈.
- **선정 (제안)**: `ColorModel`
- **순위 (Ranked Shortlist)**:
  1. `ColorModel`
  2. `ColorUtil`
  3. `ColorMath`
  4. `Colors`
- **이유**:
  1. **색상 상태/표현 모델의 정확한 표현 (추정)**: 단순 유틸리티 함수 모음이 아니라, HSV ↔ RGB 변환 시 채도/명도가 0일 때 Hue가 유실되는 문제를 방지하는 '색상 상태 모델(Color Model)'을 다루는 모듈의 정체성에 가장 부합합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Colors`: `Devui.Colors.White`, `Devui.Colors.Blue`와 같은 정적 색상 상수 팔레트 테이블로 오인하기 쉽습니다. [추정]
  - `ColorMath`: 단순 벡터 연산이나 보간(Lerp) 모듈처럼 보여 Hex 문자열 파싱/포맷팅 등의 책임이 가려집니다. [추정]

### (b) 임베드 가능한 패널 위젯
SV 사각형, Hue 바, R/G/B 및 #Hex 필드, 미리보기로 구성되어 `Source<Color3>`에 바인딩되는 컴포넌트.
- **선정 (제안)**: `ColorPicker3`
- **순위 (Ranked Shortlist)**:
  1. `ColorPicker3`
  2. `ColorPicker`
  3. `ColorPanel`
  4. `ColorEditor`
- **이유**:
  1. **기존 devui 색상 입력 위젯과의 완벽한 대칭 (실측)**: devui의 기존 한 줄 인라인 색상 위젯은 `Devui.InputColor3`([`quad-roblox-devui/src/init.luau:218`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L218), [`quad-roblox-devui/src/Inputs/InputColor3.luau:3`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/Inputs/InputColor3.luau#L3))입니다. Roblox의 표준 색상 타입인 `Color3`를 다루는 위젯으로서 `ColorPicker3`는 완벽한 일관성을 가집니다.
  2. **Dear ImGui 원본 위젯 체계와의 일치 (추정)**: Dear ImGui의 인라인 편집기 `ColorEdit3` ↔ 확장 패널 `ColorPicker3`의 관계가 devui의 `InputColor3` ↔ `ColorPicker3`로 정확히 대응됩니다.
- **오해를 유발하는 이름 (Flag)**:
  - `ColorEditor`: Dear ImGui에서 `ColorEdit`은 인라인 필드(devui의 `InputColor3`)를 가리키므로, 이미 존재하는 `InputColor3`와 역할이 모호해집니다. [추정]

### (c) 즉시 열리는 다이얼로그 함수
드래그 중 라이브 반영, Cancel 시 오픈 당시 색상 복원, OK 시 확정하는 다이얼로그 즉시 열기 함수.
- **선정 (제안)**: `OpenColorPicker`
- **순위 (Ranked Shortlist)**:
  1. `OpenColorPicker`
  2. `OpenColorDialog`
  3. `PickColor`
- **이유**:
  1. **명령형 다이얼로그 체계 준수 (실측)**: `Devui.OpenDialog`([`quad-roblox-devui/src/init.luau:243`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L243)), `Devui.OpenConfirm`([`quad-roblox-devui/src/init.luau:244`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L244)), `Devui.OpenMenu`([`quad-roblox-devui/src/init.luau:240`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/init.luau#L240))와 동일하게 `Open*` 접두사를 사용하여 즉시 다이얼로그를 띄우고 핸들을 반환함을 명시합니다.
  2. **위젯-오프너 페어링 (추정)**: `Menu` 위젯을 띄우는 함수가 `OpenMenu`이듯, `ColorPicker`(또는 `ColorPicker3`) 패널을 다이얼로그로 띄우는 함수로서 `OpenColorPicker`가 직관적으로 짝을 이룹니다.
- **오해를 유발하는 이름 (Flag)**:
  - `PickColor`: **[치명적 오해]** `Open*` 규칙을 깨뜨릴 뿐만 아니라, 화면 스포이트 도구를 실행하거나 색상이 선택될 때까지 코루틴을 양보(yield)하고 `Color3` 값을 직접 반환하는 동기적 유틸리티 함수로 오인하기 쉽습니다. [추정]

### (d) InputColor3 스와치 클릭 시 다이얼로그 오픈 비활성화 플래그
`InputColor3`의 스와치를 클릭했을 때 (c) 다이얼로그가 열리지 않도록 차단하는 속성.
- **선정 (제안)**: `NoPicker`
- **순위 (Ranked Shortlist)**:
  1. `NoPicker`
  2. `NoColorPicker`
  3. `NoPopup`
- **이유**:
  1. **기존 플래그 명명 규칙 일치 (실측)**: devui의 `Window` 플래그는 `NoClose`, `NoResize`, `NoTitleBar`, `NoMove`, `NoCollapse` 등 간결한 `No<기능>` 형태를 사용합니다 ([`quad-roblox-devui/src/Window/init.luau:19`](file:///code/Projects/quad-agy/naming-1021d/quad-roblox-devui/src/Window/init.luau#L19)).
  2. **ImGui 관례 부합 및 간결성 (추정)**: Dear ImGui의 `ImGuiColorEditFlags_NoPicker`와 일치하며, 이미 `InputColor3`의 prop이므로 불필요하게 `Color`를 중복한 `NoColorPicker`보다 간결합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `NoPopup`: 일반적인 UI에서 팝업(Popup)은 우클릭 컨텍스트 메뉴나 드롭다운을 뜻하므로, 색상 피커 다이얼로그 차단이라는 특수한 목적을 명확히 설명하지 못합니다. [추정]

---

## 6. 제안 종합 요약표

| 그룹 | 세부 항목 | 선정안 (제안) | 2순위 | 주요 플래그 (오해 유발 이름) |
|---|---|---|---|---|
| **1. Copy dialog** | 다이얼로그 열기 함수 | `OpenCopyDialog` | `OpenCopyText` | `OpenClipboard` (클립보드 API 없음), `CopyDialog` (선언형 위젯으로 오인) |
| **2. Selection rules** | (1) 모듈 이름 | `Selection` | `MultiSelect` | `Select` (드롭다운 위젯/동사로 오인) |
| | (2) 모드 값 | `"Single" \| "Toggle" \| "Range"` | `"Replace" \| "Toggle" \| "Extend"` | `"Extend"` (단순 추가로 오해) |
| | (3) 키 판별 헬퍼 | `modeFromKeys` | `modeNow` | `currentMode` (상태 속성 게터로 오해) |
| **3. Tree flattening** | (1) 모듈 이름 | `TreeRows` | `FlatTree` | `TreeView` (시각적 GUI 위젯으로 오인), `VisibleRows` (`VirtualRows`와 혼선) |
| | (2) 접근자 `<X>` | `MoreCount` | `Unloaded` | `Pending` (네트워크 진행 중으로 오인) |
| | (3) 행 필드 | `More` | `Remaining` | `Hidden` (`Visible = false` 숨김 행으로 오인) |
| **4. VirtualRows** | (a) 바닥 추적 prop | `StickToEnd` | `FollowEnd` | `Tail` (데이터 슬라이스 필터링으로 오인), `Follow` (목적어 모호) |
| | (b) Y 좌표 매핑 | `RowIndexAt` | `IndexAtY` | `RowAt` / `VirtualRowAt` (행 인스턴스를 반환한다고 착각) |
| **5. Color picker** | (a) 순수 색상 모듈 | `ColorModel` | `ColorUtil` | `Colors` (정적 색상 팔레트로 오인) |
| | (b) 패널 위젯 | `ColorPicker3` | `ColorPicker` | `ColorEditor` (`InputColor3`와 혼선) |
| | (c) 다이얼로그 함수 | `OpenColorPicker` | `OpenColorDialog` | `PickColor` (`Open*` 규칙 위반, yield 스포이트 함수로 오인) |
| | (d) 비활성화 플래그 | `NoPicker` | `NoColorPicker` | `NoPopup` (컨텍스트 메뉴 차단으로 오해) |

---

## 검증 내역

- **작업 환경 검증 (실측)**:
  - 작업 경로: `/code/Projects/quad-agy/naming-1021d` (worktree 브랜치 `agy/naming-1021d`)
  - Git 명령 제한 준수: 브랜치 변경, 커밋, 리셋, 체크아웃 등 일체 미수행
- **테스트 스크립트 실행 (실측)**:
  - 실행 명령: `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )`
  - 실행 결과: Exit code 0 통과 (luau-analyze, luau-lsp, smoke/spec, doc-coverage 212/212, type-surface-check, error-codes 272/268 전체 PASS)
