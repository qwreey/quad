# devui 신규 추가 API 네이밍 검토 보고서 (3개 그룹)

> **안내**: 본 보고서의 모든 네이밍 안은 최종 의사결정권자인 사용자를 위한 **제안(Proposal)**입니다.  
> 각 주장의 근거는 실제 코드베이스 검증을 바탕으로 **[실측]**(코드 위치, 커맨드 실행 결과)과 **[추정]**(Roblox 툴 UI 개발자의 멘탈 모델 및 API 관례 기반 추론)으로 명시하였습니다.

---

## 1. 개요 및 검토 원칙 (사용자 관점: Roblox 도구 UI 개발자)

1. **명령형 즉시 열기(NOW) 함수와 선언형 위젯의 엄격한 분리**:
   - `Devui.OpenMenu`([`quad-roblox-devui/src/init.luau:252`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L252)), `Devui.OpenDialog`([`init.luau:255`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L255)), `Devui.OpenColorPicker`([`init.luau:262`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L262))처럼 호출 즉시 팝업을 띄우고 `{ IsOpen, Close }` 핸들을 반환하는 함수는 일관되게 `Open*` 접두사를 사용합니다. [실측]
   - 선언형 위젯 트리 안에서 마운트되는 위젯은 명사형 단독 또는 패밀리 접두사(`Combo*`, `Table`, `VirtualRows`)를 유지해야 합니다. [실측]
2. **기존 devui 표준 prop 어휘 및 타입 규약 준수**:
   - `Text`: 후행 레이블 또는 표시 텍스트 ([`init.luau:43-44`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L43-L44)). [실측]
   - `Value`: 위젯이 읽고 쓰는 양방향 상태인 `Source<T>` 전용 어휘 ([`init.luau:44-45`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L44-L45)). 단순 getter나 정적 값에 `Value`를 사용하는 것은 금지됩니다. [실측]
   - `Options`: 선택지 위젯(`Combo`)에서 후보 목록을 전달하는 표준 prop ([`Combo.luau:8`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Combo.luau#L8)). [실측]
   - `Disabled`: 위젯 비활성화 여부를 나타내는 `boolean | State<boolean>` 전용 어휘 ([`init.luau:46`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L46)). [실측]
   - `OnClick`: 버튼/메뉴 항목의 클릭 액션에 일관되게 사용되며, Roblox 엔진의 `Activated`를 감싼 형태입니다 ([`Button.luau:25`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Button.luau#L25)). [실측]
3. **Roblox 엔진 프로퍼티 및 타 모듈과의 충돌 방지**:
   - `GuiObject.Active` 및 `GuiButton.Selected`는 엔진 기본 속성이므로 모호성이나 오해를 줄 수 있는 명명(`Active`, `Selected`)은 신중해야 합니다 ([`Button.luau:14-15`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Button.luau#L14-L15)). [실측]
   - 최상위 공개 모듈인 `Devui.Selection`([`init.luau:258`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L258))이나 `Devui.Input`([`init.luau:198`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L198))과의 이름 충돌을 피해야 합니다. [실측]

---

## 2. 그룹별 네이밍 검토 및 제안

### 그룹 1: 검색 가능한 가상화 리스트 팝업 + 오픈 박스 (Searchable Virtual List Popup & Box)

수천 개의 항목(예: Instance 클래스 삽입)을 다루며, 상단 검색창(오픈 시 자동 포커스)과 가상화 리스트로 구성된 자동완성 형태의 팝업 및 이를 여는 박스 위젯.

---

#### 1.(a) 즉시 열기(NOW) 함수
점(Vector2) 또는 사각형(Rect) 아래에 팝업을 즉시 띄우고 `{ IsOpen, Close }`를 반환하는 함수. (Up/Down 행 이동, Enter 선택, Escape 닫기)
- **선정 (제안)**: `OpenPicker`
- **순위 (Ranked Shortlist)**:
  1. `OpenPicker`
  2. `OpenQuickPick`
  3. `OpenSearchList`
  4. `OpenFilterList`
  5. `OpenSearch`
- **이유**:
  1. **기존 `OpenColorPicker`와의 높은 조화 [실측]**: devui의 명령형 팝업 중 무언가를 "선택"하는 팝업은 `Devui.OpenColorPicker`([`init.luau:262`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L262))가 있습니다. 항목을 선택하는 범용 팝업으로 `OpenPicker`는 군더더기 없이 명확합니다.
  2. **사용자 행동 목적과의 직관성 [추정]**: 개발자가 이 함수를 부르는 핵심 목적은 '항목 선택(Pick)'입니다. `QuickPick`(VS Code 용어)도 훌륭하지만 IDE 종속적 어감이 있는 반면, `OpenPicker`는 표준적이고 간결합니다. 후술할 콜백 `OnPick`과도 완벽하게 대칭을 이룹니다.
- **오해를 유발하는 이름 (Flag)**:
  - `OpenSearch`: **[심각]** 텍스트/파일 검색 창이나 인라인 Find 다이얼로그를 띄우는 함수로 오인하기 쉽습니다. 항목을 "선택하여 돌려받는다"는 의미가 전혀 드러나지 않습니다. [추정]
  - `OpenFilterList`: UI 컴포넌트의 형태(검색창+리스트)나 사용자의 목표(선택)가 아닌 '필터링'이라는 내부 동작 메커니즘을 앞세워 직관성이 떨어집니다. [추정]

---

#### 1.(b) 오픈 박스 위젯
`Combo`와 동일한 props(`Value`, `Options`, `Format`, `OnChange`)를 가지며, 클릭 시 (a) 팝업을 하단에 여는 선언형 박스 위젯.
- **선정 (제안)**: `ComboSearch`
- **순위 (Ranked Shortlist)**:
  1. `ComboSearch`
  2. `SearchCombo`
  3. `FilterCombo`
  4. `ComboVirtual`
  5. `AutoComplete`
- **이유**:
  1. **`Combo` 패밀리 접두사 일관성 및 IDE 자동완성 발견성 [실측 및 추정]**: devui의 콤보 계열 위젯은 `Devui.Combo`, `Devui.ComboArray`, `Devui.ComboEnum`으로 구성되어 있습니다 ([`init.luau:245-247`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L245-L247)). `ComboSearch`를 사용하면 IDE에서 `Devui.Combo` 입력 시 즉시 함께 노출되어 API 발견성이 극대화됩니다.
  2. **인터페이스 동일성의 직관적 전달 [실측]**: `Combo`의 4대 핵심 prop(`Value`, `Options`, `Format`, `OnChange`)을 그대로 받는 변형 위젯이므로 `Combo*` 네임스페이스를 공유하는 것이 멘탈 모델상 가장 자연스럽습니다. (자연어 어순을 선호할 경우 `SearchCombo`도 2순위로 유효합니다.)
- **오해를 유발하는 이름 (Flag)**:
  - `AutoComplete`: **[심각]** 통상 `AutoComplete`는 사용자가 텍스트 박스(`InputText`)에 직접 타이핑하며 인라인 제안을 받는 입력 필드를 가리킵니다. 본 위젯은 `Combo`처럼 닫힌 박스에 선택값이 표시되고, 클릭 시 별도 팝업이 열리는 위젯이므로 `AutoComplete`라는 이름은 완전히 다른 위젯 형태를 연상시켜 심각한 혼란을 줍니다. [추정]
  - `ComboVirtual`: 가상화는 수천 개 항목을 처리하기 위한 내부 성능 기법일 뿐, 개발자와 최종 사용자가 체감하는 핵심 기능인 "검색창이 달린 콤보"라는 점을 전달하지 못합니다. [추정]

---

#### 1.(c) (a)의 항목 목록 prop
- **선정 (제안)**: `Options`
- **순위 (Ranked Shortlist)**:
  1. `Options`
  2. `Items`
- **이유**:
  1. **kit 전체 선택 계열 prop과의 통일성 [실측]**: devui에서 선택지 목록은 언제나 `Options`로 명명됩니다 (`ComboProps.Options`, `ComboArrayProps.Options`, `init.luau:44-45` "Option is what a choice widget selects").
  2. **`ComboSearch`와의 상호 호환성 [추정]**: (b) 박스 위젯이 `Options`를 받으므로, (a) 함수 역시 `Options`를 받아야 코드를 래핑하거나 이동할 때 prop 이름 불일치로 인한 실수를 방지할 수 있습니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Items`: 다른 위젯(`Combo`)의 `Options`와 무의미하게 어휘가 갈라져 사용자에게 "여기선 Options인가 Items인가?"를 혼동시킵니다. [추정]

---

#### 1.(d) 선택 불가 이유 반환 per-item 함수
항목을 선택할 수 없을 때 사유 문자열(행이 흐려지고 텍스트 뒤에 이유가 표시되며 클릭 무효화)을, 선택 가능할 때 nil을 반환하는 함수 `(item: T) -> string?`.
- **선정 (제안)**: `DisabledReason`
- **순위 (Ranked Shortlist)**:
  1. `DisabledReason`
  2. `Unavailable`
  3. `Blocked`
  4. `Disabled`
- **이유**:
  1. **반환값 타입(문자열 이유)과 비활성화 기능의 완벽한 자기설명 [추정]**: "Disabled" 상태가 되는 이유("Reason")를 반환한다는 계약이 이름 하나로 즉시 전달됩니다. 반환된 문자열이 UI에 렌더링된다는 스펙과 100% 부합합니다.
  2. **불리언 술어(Predicate)와의 명확한 구별 [추정]**: 단순히 `Unavailable`이나 `Blocked`라고 명명하면 `(item) -> boolean`을 넘겨야 하는 것으로 착각하기 쉽지만, `DisabledReason`은 사유(문자열)를 기대함을 암시합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Disabled`: **[심각]** devui 전반에서 `Disabled`는 `boolean | State<boolean>` 타입의 프로퍼티입니다 ([`init.luau:46`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L46)). 이미 존재하는 표준 불리언 prop과 이름이 겹치면 개발자는 당연히 불리언이나 불리언 반환 함수를 전달할 것이며, 사유 문자열이 렌더링된다는 사실을 알 수 없습니다. [실측 및 추정]

---

#### 1.(e) 아이콘 반환 per-item 함수
텍스트 앞에 표시할 작은 아이콘의 이미지 ID를 반환하는 함수 `(item: T) -> string?`.
- **선정 (제안)**: `Icon`
- **순위 (Ranked Shortlist)**:
  1. `Icon`
  2. `ItemIcon`
  3. `IconOf`
- **이유**:
  1. **devui의 함수형 prop 명명 규칙과의 대칭 [실측]**: `Combo`에서 각 항목의 텍스트를 변환하는 함수는 `FormatOf`가 아니라 `Format`입니다 ([`Combo.luau:9`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Combo.luau#L9)). 마찬가지로 항목별 아이콘을 반환하는 함수는 `Icon`으로 명명할 때 가장 간결하며, `Format`과 아름다운 대칭을 이룹니다 (`Format = function(c) ... end, Icon = function(c) ... end`).
  2. **간결성 [추정]**: 정적 문자열 prop인 `Button`의 `Icon`([`Button.luau:18`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Button.luau#L18))과 동일한 개념(표시할 이미지)을 함수 형태로 확장한 것이므로 직관적입니다.
- **오해를 유발하는 이름 (Flag)**:
  - `IconOf`: devui의 컴포넌트 public props에는 `*Of` 형태의 접미사가 일절 존재하지 않습니다 ([`init.luau`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L43-L80)). `*Of`는 `Style:ColorOf` 등 내부/메서드 조회 함수에서만 쓰이므로 public prop에 사용되면 규칙을 위반합니다. [실측]

---

#### 1.(f) 항목 선택 시 콜백
항목이 선택되었을 때 실행되는 콜백 `(item: T) -> ()`.
- **선정 (제안)**: `OnPick`
- **순위 (Ranked Shortlist)**:
  1. `OnPick`
  2. `OnSelect`
  3. `OnChoose`
  4. `OnChange`
- **이유**:
  1. **(a) `OpenPicker`와의 일치감 및 확정(Commit) 뉘앙스 [추정]**: 검색 창에서 Enter를 치거나 클릭하여 항목을 "집어내어 확정 짓고 팝업을 닫는" 일회성 행위를 가장 생생하게 표현합니다.
  2. **단순 포커스/선택 상태와의 구별 [추정]**: 테이블이나 리스트에서 `Select`는 단순히 행을 하이라이트하는 상태 변경을 의미하기도 하지만, `Pick`은 최종 결정을 내리는 액션임을 명확히 합니다. (`OnSelect` 역시 표준적이므로 2순위로 매우 우수합니다.)
- **오해를 유발하는 이름 (Flag)**:
  - `OnChange`: **[심각]** devui에서 `OnChange`는 `Value: Source<T>`가 바인딩된 위젯에서 "사용자가 이전 값과 다른 새로운 값으로 변경했을 때"에만 호출되는 이벤트로 규약화되어 있습니다 ([`init.luau:45-46`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L45-L46)). (a) 팝업은 이전 값을 저장하지 않는 일회성 명령형 팝업이므로, 사용자가 같은 항목을 다시 골라도 콜백이 실행되어야 합니다. 여기에 `OnChange`를 쓰면 "값이 변경될 때만 실행되는가?"라는 오해를 낳습니다. [실측 및 추정]

---

### 그룹 2: 가상화 테이블 (Virtualized Table)

`VirtualRows` 기반으로 구축된 고정 높이 가상화 테이블 (헤더 행, 텍스트 게터 컬럼, 좌/우 누적 및 fill 컬럼, 행 hover/selected 하이라이트, 행 클릭 콜백).

---

#### 2.(a) 위젯 이름
- **선정 (제안)**: `VirtualTable`
- **순위 (Ranked Shortlist)**:
  1. `VirtualTable`
  2. `DataTable`
  3. `ListTable`
  4. `VirtualRowsTable`
- **이유**:
  1. **기존 `Devui.Table`과의 직접적인 대응 관계 [실측]**: devui에는 이미 모든 행을 DOM으로 만드는 `Devui.Table`([`Table.luau:25-28`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Table.luau#L25-L28))과 고정 높이 가상화 행 풀인 `Devui.VirtualRows`([`VirtualRows.luau:3`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/VirtualRows.luau#L3))가 존재합니다. 가상화된 테이블로서 `VirtualTable`은 사용자가 기능을 즉시 파악할 수 있는 가장 명쾌한 이름입니다.
  2. **선택 가이드라인의 직관성 [추정]**: "소규모/자유 레이아웃 셀 -> `Table`", "대규모 고정 높이 텍스트 데이터 -> `VirtualTable`"이라는 명확한 멘탈 모델을 제공합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `DataTable`: 웹 UI 프레임워크에서 `DataTable`은 컬럼 정렬, 클라이언트/서버 페이징, 다중 필터링, 인라인 셀 편집 등을 갖춘 풀스펙 데이터 그리드를 의미합니다. 텍스트 게터 위주의 고정 높이 가상화 테이블에 `DataTable`을 붙이면 지원하지 않는 과도한 기능을 제공할 것이라는 오해를 부릅니다. [추정]
  - `VirtualRowsTable`: 내부 구현체인 `VirtualRows`를 불필요하게 이름에 노출하여 장황하고 어색합니다. [추정]
  - `ListTable`: 리스트인지 테이블인지 개념이 모호합니다. [추정]

---

#### 2.(b) 컬럼 정의 내 텍스트 게터 prop `(row: T) -> string`
- **선정 (제안)**: `Text`
- **순위 (Ranked Shortlist)**:
  1. `Text`
  2. `Format`
  3. `Get`
  4. `Value`
- **이유**:
  1. **컬럼 정의 구조 내의 가독성 [실측 및 추정]**: 컬럼 정의 테이블 `{ Title = "Name", Width = 100, Text = function(r) return r.Name end }`에서, 헤더 표시용인 `Title`과 셀 본문 표시용인 `Text`가 가장 자연스럽고 간결한 짝을 이룹니다. devui 전체에서 표시 문자열은 언제나 `Text`로 통일되어 있습니다 ([`init.luau:43`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L43)).
  2. **`Combo.Format`과의 차별성 [실측 및 추정]**: `Combo`의 `Format: (T) -> string`은 단일 옵션 값 `T` 자체를 문자열로 포맷팅하는 데 쓰이지만, 테이블 컬럼의 게터는 객체 `T`에서 특정 필드를 추출하고 가공하는 '필드 접근자' 역할을 함께 수행합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Value`: **[매우 심각]** devui의 최상위 명명 원칙에서 `Value`는 **"위젯이 읽고 쓰는 `Source<T>` 양방향 상태"**로 엄격히 고정되어 있습니다 ([`init.luau:44-45`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L44-L45)). 순수 추출 함수인 `(row) -> string`에 `Value`라는 이름을 붙이는 것은 devui의 핵심 규약을 정면으로 파괴하며, 개발자가 여기에 반응형 `Source`나 원시 값을 바인딩해야 한다고 착각하게 만듭니다. [실측]
  - `Get`: quad의 핵심 반응형 메서드인 `state:Get()`과 이름이 겹쳐 혼란을 줍니다. [실측]

---

#### 2.(c) 행 클릭 콜백 `(row: T, index: number)`
- **선정 (제안)**: `OnRowClick`
- **순위 (Ranked Shortlist)**:
  1. `OnRowClick`
  2. `OnClick`
  3. `OnActivate`
- **이유**:
  1. **복합 컨테이너 위젯에서의 대상 명확성 [추정]**: 테이블에는 헤더, 스크롤바, 빈 공간, 행 등 다양한 하위 영역이 존재합니다. `OnRowClick`은 클릭 이벤트가 "데이터 행"을 눌렀을 때만 발화하며 인자로 `(row, index)`가 넘어옴을 이름 자체로 명시합니다.
  2. **devui의 `OnClick` 규칙과의 결합 [실측]**: devui의 표준 클릭 콜백 이름인 `OnClick` 어휘를 유지하면서 대상인 `Row`를 결합하여 일관성을 지킵니다.
- **오해를 유발하는 이름 (Flag)**:
  - `OnActivate`: Roblox 엔진의 이벤트는 `Activated`이지만, devui는 엔진의 `Activated`를 감싸서 항상 `OnClick`으로 개발자에게 노출해 왔습니다 ([`Button.luau:25`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Button.luau#L25)). devui 어디에도 쓰이지 않는 `OnActivate`를 새로 도입하면 컨벤션이 분열됩니다. [실측]

---

#### 2.(d) 선택된 행 집합 prop (`State<{ [key]: true }>` + `Key: (row) -> any`)
- **선정 (제안)**: `SelectedKeys`
- **순위 (Ranked Shortlist)**:
  1. `SelectedKeys`
  2. `Selected`
  3. `Selection`
- **이유**:
  1. **데이터 형태 및 `Key` prop과의 완벽한 결합 [실측 및 추정]**: 이 prop은 행 인덱스나 행 데이터 객체가 아니라, `Key(row)` 함수가 반환한 '키(key)'들의 집합(`{ [key]: true }`)을 받습니다. devui의 `Selection.toSet(list)` 역시 `{ [key]: true }` 형태의 키 셋을 반환합니다 ([`Selection.luau:29`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Selection.luau#L29)). 따라서 `SelectedKeys`는 넘겨야 할 데이터의 타입과 의미를 단번에 알려줍니다.
  2. **단일/불리언 `Selected`와의 혼동 방지 [실측]**: `Selected`라는 이름은 하위 컴포넌트나 행에서 불리언(`Selected = true`) 또는 탭 바에서의 단일 선택 키(`TabBar.Selected: Source<K>`)로 쓰입니다. 테이블 단위의 다중 키 집합에는 `SelectedKeys`가 훨씬 정밀합니다.
- **오해를 유발하는 이름 (Flag)**:
  - `Selection`: **[심각]** devui 최상위 네임스페이스에 이미 선택 알고리즘 모듈인 `Devui.Selection`([`init.luau:258`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/init.luau#L258), [`Selection.luau`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Selection.luau))이 export되어 있습니다. prop 이름을 `Selection`으로 하면 모듈 이름과 shadowing 충돌을 일으키며, 상태인지 모듈인지 선택 모드인지 알 수 없습니다. [실측]

---

### 그룹 3: Overlay 입력 팝업 카운트 (Overlay Popups Taking Input)

`Devui.Overlay`의 기존 `Count: State<number>`(툴팁 포함 모든 팝업 수) 옆에, 툴팁을 제외하고 입력을 받는 팝업(메뉴, 콤보 드롭다운, 대화상자)의 개수만을 추적하는 `State<number>` 프로퍼티. 앱에서 툴팁 표시 여부와 무관하게 "현재 메뉴나 대화상자가 열려 있는가?(단축키 억제 등)"를 질의하기 위함.

- **선정 (제안)**: `InteractiveCount` (또는 `BlockingCount`)
- **순위 (Ranked Shortlist)**:
  1. `InteractiveCount`
  2. `BlockingCount`
  3. `InputCount`
  4. `ModalCount`
  5. `ActiveCount`
- **이유**:
  1. **툴팁과의 본질적 차이(상호작용성)를 정확히 반영 [실측 및 추정]**: 툴팁은 마우스 이벤트가 통과되는 비상호작용/단순 뷰 레이어(`CloseOnClickOutside = false`, 입력 불흡수)인 반면, 메뉴/콤보/대화상자는 클릭·키보드 포커스·휠을 수신하는 "인터랙티브(상호작용)" 팝업입니다. `Overlay.luau`의 주석([`Overlay.luau:68-72`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Overlay.luau#L68-L72))에서도 "A tooltip (takes no input) does not count"라고 명시하고 있습니다. `InteractiveCount`는 이를 가장 정확하고 부작용 없이 표현합니다.
  2. **`BlockingCount`의 실용성 [추정]**: 개발자가 이 카운트를 확인하는 1차 목적은 "바닥 뷰포트의 단축키나 클릭을 블로킹해야 하는가?"입니다. 따라서 2순위인 `BlockingCount` 역시 개발자의 사용 목적 관점에서 매우 직관적입니다.
- **오해를 유발하는 이름 (Flag)**:
  - `ActiveCount`: **[매우 심각]**
    1) Roblox 엔진에서 `Active`는 `GuiObject.Active: boolean` 프로퍼티로, 클릭 이벤트를 삼킬지 여부를 지정하는 핵심 프로퍼티입니다 ([`Button.luau:14-15`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Button.luau#L14-L15)에서도 엔진의 `Active`와 혼동을 피하기 위해 `Toggled`를 선택함). [실측]
    2) 일반적인 UI 영어 관점에서도 "Active"는 "현재 활성화되어 떠 있는"으로 읽히므로, "현재 떠 있는 모든 팝업의 수"인 `Count`와 구별되지 않습니다. "툴팁도 지금 떠서 active한데 왜 카운트가 0이지?"라는 의문을 유발합니다. [추정]
  - `ModalCount`: **[심각]** "Modal"은 화면 전체를 잠그는 모달 대화상자(`Dialog`, `OpenDialog`, `OpenConfirm`)만을 의미합니다. 일반적인 드롭다운 `Combo`나 우클릭 컨텍스트 `Menu`는 트랜지언트(transient) 팝업이지 모달이 아닙니다. 개발자가 `ModalCount`를 보면 콤보나 메뉴는 카운트되지 않는다고 오해하게 됩니다. [추정]
  - `InputCount`: devui에 이미 `Devui.Input`([`src/Input.luau`](file:///code/Projects/quad-agy/naming-1021e/quad-roblox-devui/src/Input.luau), UserInputService 래퍼)과 `Devui.Inputs`([`InputText`, `InputNum` 등 입력 위젯군])가 존재하여, "오버레이 내에 있는 입력 필드 위젯의 개수"로 오인될 소지가 큽니다. [실측 및 추정]

---

## 3. 종합 요약표 (Decision Matrix)

| 구분 | 항목 | 추천 선정안 (제안) | 추천 순위 (Ranked Shortlist) | 오해 유발 주의 (Flagged Names) |
|---|---|---|---|---|
| **1. 검색 팝업** | (a) 즉시 열기 함수 | `OpenPicker` | `OpenPicker` > `OpenQuickPick` > `OpenSearchList` > `OpenFilterList` > `OpenSearch` | `OpenSearch` (검색창/Find 팝업으로 오해) |
| | (b) 오픈 박스 위젯 | `ComboSearch` | `ComboSearch` > `SearchCombo` > `FilterCombo` > `ComboVirtual` > `AutoComplete` | `AutoComplete` (텍스트 입력 위젯으로 오해), `ComboVirtual` (검색 기능 은폐) |
| | (c) 목록 prop | `Options` | `Options` > `Items` | `Items` (`Combo.Options`와 불필요한 이원화) |
| | (d) 사유 반환 함수 | `DisabledReason` | `DisabledReason` > `Unavailable` > `Blocked` > `Disabled` | `Disabled` (기존 boolean prop과 충돌, 사유 문자열 은폐) |
| | (e) 아이콘 반환 함수 | `Icon` | `Icon` > `ItemIcon` > `IconOf` | `IconOf` (devui props에 `*Of` 패턴 전무) |
| | (f) 선택 시 콜백 | `OnPick` | `OnPick` > `OnSelect` > `OnChoose` > `OnChange` | `OnChange` (동일값 재선택 미발화 등 오해 유발) |
| **2. 가상 테이블** | (a) 위젯 이름 | `VirtualTable` | `VirtualTable` > `DataTable` > `ListTable` > `VirtualRowsTable` | `DataTable` (풀 그리드 기능 과장), `VirtualRowsTable` (구현 상세 누출) |
| | (b) 열 텍스트 게터 | `Text` | `Text` > `Format` > `Get` > `Value` | `Value` (`Source<T>` 양방향 규칙 위반), `Get` (`state:Get()` 충돌) |
| | (c) 행 클릭 콜백 | `OnRowClick` | `OnRowClick` > `OnClick` > `OnActivate` | `OnActivate` (devui의 `OnClick` 규칙 위반) |
| | (d) 선택 행 집합 prop | `SelectedKeys` | `SelectedKeys` > `Selected` > `Selection` | `Selection` (`Devui.Selection` 모듈명 충돌 및 모호함) |
| **3. Overlay** | 입력 팝업 카운트 | `InteractiveCount` | `InteractiveCount` > `BlockingCount` > `InputCount` > `ModalCount` > `ActiveCount` | `ActiveCount` (엔진 `Active` 충돌 및 `Count` 혼동), `ModalCount` (메뉴/콤보 배제 오해) |

---

## 4. 검증 내역 (Verification)

- **전체 테스트 스위트 검증 [실측]**:
  - 명령: `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )`
  - 결과: exit code `0`, quad-base, quad-roblox, 타입 및 닥 커버리지 100% 통과 확인.
- **devui 자체 테스트 스위트 검증 [실측]**:
  - 명령: `( ulimit -v 4000000; timeout 600 bash quad-roblox-devui/test/run.sh )`
  - 결과: exit code `0`, `spec.combo`, `spec.virtualrows`, `spec.overlay`, `spec.table`, `spec.selection`, `spec.pure.treerows` 등 전체 30개 이상의 스펙 통과 확인.
