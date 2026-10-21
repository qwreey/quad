### 1. 검색 가능한 가상 목록 팝업

- **(a) `OpenQuickPick`** — 1순위 `OpenQuickPick`, 2순위 `OpenSearchList`, 3순위 `OpenPicker`. 검색과 키보드 선택이 가능한 팝업이라는 인상을 줍니다. `OpenSearch`는 검색 동작만 열리는 것처럼 모호합니다.
- **(b) `SearchCombo`** — 1순위 `SearchCombo`, 2순위 `AutoComplete`, 3순위 `FilterCombo`. Combo 계열임을 유지하면서 검색 가능한 변형임을 바로 드러냅니다. `AutoComplete`는 입력 중 자동 완성이 일어나는 위젯으로 오해될 수 있습니다.
- **(c) `Items`** — `Options`보다 일반적이고, 검색 팝업의 목록을 가리키기 쉽습니다.
- **(d) `DisabledReason`** — 불가 사유를 반환한다는 뜻이 분명합니다. `Disabled`는 기존 boolean/State<boolean> prop과 충돌합니다.
- **(e) `ItemIcon`** — 항목별 아이콘임을 잘 드러냅니다. `Icon`은 기존 버튼 prop과 의미가 겹칩니다.
- **(f) `OnPick`** — 목록에서 항목을 골랐을 때 호출된다는 뜻이 간결합니다. `OnChange`는 선택 동작보다 값 변경 전반으로 읽힙니다.

### 2. 가상화 테이블

- **(a) `VirtualTable`** — 1순위 `VirtualTable`, 2순위 `DataTable`, 3순위 `VirtualRowsTable`. 짧고 가상화된 테이블임을 직접 설명합니다.
- **(b) `Text`** — 1순위 `Text`, 2순위 `Get`, 3순위 `Format`. 결과가 문자열이라는 점이 가장 명확합니다. `Value`는 반환 형식을 드러내지 않습니다.
- **(c) `OnRowClick`** — 행 클릭 콜백이라는 점이 구체적입니다. `OnClick`은 테이블 전체 클릭으로 오해될 수 있습니다.
- **(d) `SelectedKeys`** — 실제 값이 선택 상태의 key 맵이므로 가장 정확합니다. `Selected`는 선택된 행 목록 자체처럼 읽힐 수 있습니다.

### 3. 입력을 받는 팝업 수

- **`InputCount`** — 1순위 `InputCount`, 2순위 `InteractiveCount`, 3순위 `BlockingCount`. 메뉴·콤보·다이얼로그가 입력을 받는 상태를 가리킵니다. `ModalCount`는 비모달 팝업도 포함한다는 점에서 오해를 부를 수 있습니다.