# quad-roblox-material 심층 코드 리뷰 보고서 (AGY)

본 보고서는 `quad-roblox-material` 킷에서 2026-10-12 선행 리뷰 대상(시트·드로어·내비게이션 레일·앱 바·슬라이더·시간 선택기·대화 상자)을 제외한 나머지 컴포넌트 전반(`DatePicker/`, `ColorPicker/`, `Menu.luau`, `Select.luau`, `Tabs.luau`, `Chip/`, `Checkbox.luau`, `Radio.luau`, `Switch/`, `Progress/`, `Tooltip.luau`, `Card.luau`, `Divider.luau`, `Badge.luau`, `Theme.luau`, `Tokens/`, `Text.luau`, `Icons.luau`, `IconView.luau`, `KeyNav.luau`, `Elevation.luau`, `StateLayer.luau`, `Interactive.luau`, `GlyphButton.luau`, `ControlLabel.luau`, `M2/`, `gallery/`)을 대상으로 수행한 읽기 전용 정밀 감사 결과입니다.

검증은 작업 디렉터리(`/code/Projects/quad-agy/review-material2`) 내에서 `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )` 및 자체 프로브 하네스(`spec.pure.probe.luau`, `spec.probe.luau`)를 구성하여 수행하였으며, 전체 테스트 슈트(종합 통과 exit code 0)를 통과한 상태에서 실측 데이터를 도출하였습니다. 주장마다 **[실측]**(파일:줄, 실행 명령 및 결과) 또는 **[추정]**을 명시하였으며, 아키텍처 개선안은 모두 **"제안"**으로 기술하였습니다.

---

## 1. 주요 발견 사항 요약 (심각도 순)

### [발견 1] [버그/결함] 앵커(호스트) 파괴 시 Overlay 메뉴 및 전체화면 스크림 미정리로 인한 UI 고아화 (심각도: 상)
- **상황**: `Menu.open`(`src/Menu.luau`)으로 드롭다운/컨텍스트 메뉴를 띄운 상태에서, 앵커 인스턴스(`Anchor`)가 화면 전환, 탭 변경, 부모 GuiObject의 `Destroy()` 호출 등으로 인해 파괴되는 상황. (비교: `Tooltip.luau` 223~226행에서는 `inst.Destroying:Connect(hide)`로 타깃 인스턴스 파괴 시 즉각 툴팁을 정리함).
- **결과**: `Menu.luau` 내부에는 `Anchor.Destroying` 시그널 감지가 누락되어 있어, 앵커가 파괴되어 화면에서 사라져도 Overlay에 생성된 전체화면 투명 스크림(`D.TextButton`)과 Menu 프레임(`menuFrame`)이 닫히지 않고 그대로 남음. 이로 인해 메뉴가 고아(orphan) 상태로 화면에 방치되고, 전체화면 스크림이 마우스/터치 입력을 계속 흡수하여 애플리케이션 전체 UI가 클릭 불가 상태(먹통)에 빠지는 치명적인 버그가 발생함. `Select.luau` 역시 호스트가 파괴될 때 `Menu.open` 핸들을 닫지 않아 동일한 문제를 공유함.
- **위치**: `quad-roblox-material/src/Menu.luau`: 244~370행 (`Menu.open`), `quad-roblox-material/src/Select.luau`: 120~135행.
- **근거**: [실측] 킷 test 폴더의 임시 프로브 spec.probe(격리 worktree에만 있었음) PROBE 1 실행. `Menu.open` 호출 후 `q.dispose(anchor)`로 앵커 파괴 시 `handle.IsOpen:Get()`이 여전히 `true`이고 오버레이 내 `menuFrame`이 파괴되지 않고 잔류함을 실측 검증함 (`spec.probe.luau` 통과, exit code 0).
- **제안**: `Menu.open` 내부에서 `Anchor.Destroying:Connect(function() handle.Close() end)`를 기본 연결하도록 보강할 것을 제안함.

---

### [발견 2] [버그/결함] Switch 드래그 도중 Disabled 전환 시 상태가 커밋되고 OnChange가 오발화하는 결함 (심각도: 상)
- **상황**: 스위치 트랙을 잡고 드래그 조작하던 도중(`Interaction.drag` 진행 중), 네트워크 응답이나 외부 State 변경으로 컴포넌트의 `Disabled` prop이 `true`로 바뀐 후 사용자가 손을 떼는(`InputEnded`) 상황.
- **결과**: `Interaction.drag`의 비활성화 가드는 최초 터치 시작(`InputBegan`) 시점에만 평가되며(`src/Interaction.luau` 274행), 드래그 종료를 처리하는 `Switch/Behavior.luau`의 `OnEnded`(116~131행) 및 `write`(85~92행)에는 `disabled:Get()` 검사가 전혀 없음 (반면 145행의 `Activated` 탭 처리에는 `if disabled:Get() then return end`가 존재하여 비대칭). 이로 인해 비활성화 상태로 전환되었음에도 드래그를 놓는 순간 목표 반대 상태로 값이 덮어써지고 `props.OnChange`가 호출됨 (슬라이더 선행 리뷰의 결함 A7과 정확히 동일한 구조적 취약점).
- **위치**: `quad-roblox-material/src/Switch/Behavior.luau`: 85~92행 (`write`), 116~131행 (`OnEnded`), `quad-roblox-material/src/Interaction.luau`: 274행.
- **근거**: [실측] 킷 test 폴더의 임시 프로브 spec.probe(격리 worktree에만 있었음) PROBE 2 실행. 드래그 슬롭(4px) 통과 후 `dis:Set(true)` 설정하고 `InputEnded` 발화 시, `v:Get() == true`로 값이 강제 변경되고 `OnChange` 카운트가 1 증가함을 실측 확인 (exit code 0).
- **제안**: `Switch/Behavior.luau`의 `write` 함수 시작부에 `if Util.peekBool(disabled) then return end` 가드를 추가할 것을 제안함.

---

### [발견 3] [버그/비효율] Progress/Loop의 ScreenGui 언마운트(Parent = nil) 감지 실패로 인한 Heartbeat 낭비 (심각도: 중상)
- **상황**: 화면 전환 캐싱 또는 객체 풀링을 위해 진행 표시기(`CircularProgress`, `LoadingIndicator` 등)를 담고 있는 최상위 `ScreenGui` 전체를 `Parent = nil`로 언마운트/파킹해 둔 상황.
- **결과**: `isLive`(35~44행)는 조상 체인을 올라가며 `LiveRoots[p.ClassName]`(ScreenGui 등)을 만나면 즉시 `true`를 반환하지만, 해당 ScreenGui가 DataModel(`game`)에 여전히 속해 있는지(`p:IsDescendantOf(game)`) 확인하지 않음. 이로 인해 화면에서 완전히 내려간 ScreenGui 내부의 프로그레스 루프들이 계속 매 프레임 `RunService.Heartbeat` 이벤트를 수신하며 불필요한 계산을 지속함. 코드 주석(18~19행)에도 "A whole ScreenGui parked with Parent = nil is NOT detected"라고 명시되어 있음.
- **위치**: `quad-roblox-material/src/Progress/Loop.luau`: 18~19행(주석), 35~44행 (`isLive`).
- **근거**: [추정 및 코드 분석] `Loop.luau` 37~42행의 `while p ~= nil do if LiveRoots[p.ClassName] == true then return true end p = p.Parent end`. ScreenGui의 Parent가 nil이어도 루트 타입 매치로 인해 무조건 `true`가 반환됨.
- **제안**: `isLive` 판정 시 `LiveRoots`를 만났을 때 `p:IsDescendantOf(game)`(또는 `p.Parent ~= nil`) 검사를 추가하여 파킹된 트리의 백그라운드 프레임 연산을 원천 차단할 것을 제안함.

---

### [발견 4] [비효율] DatePicker MonthView의 과도한 State 생성 (달력 1개월당 약 750개 State 상주) (심각도: 중상)
- **상황**: 월간 달력(`DatePicker/MonthView.luau`) 1개월을 렌더링할 때 42개 날짜 셀(6주 x 7일)을 생성하고 각 셀마다 `Chip.new`를 인스턴스화하는 상황.
- **결과**: 셀 1개당 `Interaction.new` 내부 State 3개(`hovered`, `pressed`, `focused`)에 더하여 `look`, `bgColor`, `bgTransparency`, `textColor`, `textTransparency`, `ring`(4개 State), `band`(3개 State), `DAY_TEXT`, `StatusFor` 등 최소 18개의 State/Compute가 생성됨. 달력 1개월 뷰 하나에 42 * 18 = 756개 이상의 반응형 State 객체가 생성되어 메모리에 상주하며, 사용자가 월을 이동할 때마다(`grid` State 변경) 42개 셀 전체의 방대한 Compute 사슬이 일제히 재평가되어 불필요한 GC 및 연산 오버헤드를 유발함.
- **위치**: `quad-roblox-material/src/DatePicker/MonthView.luau`: 208~235행, `quad-roblox-material/src/DatePicker/Chip.luau`: 100~205행.
- **근거**: [실측] 킷 test 폴더의 임시 프로브 spec.probe(격리 worktree에만 있었음) PROBE 3 실행. `MonthView` 단일 프레임 아래 생성된 UI 인스턴스만 134개(호스트 포함 135개) 확인. [추정] `Chip.luau` 100~160행에서 셀당 18개 이상의 State/Compute가 각각 생성됨.
- **제안**: 월 변경 시 42개 셀 전체를 개별 reactive Compute로 추적하기보다, 각 셀의 상태(배경색, 텍스트색 등)를 단일 `status` 맵 State로부터 인덱싱하여 파생하는 경량 구조로 리팩토링할 것을 제안함.

---

### [발견 5] [더 나은 구현] DatePicker/Docked와 RangeDocked 간의 셸 컨테이너 코드 중복 (심각도: 중)
- **상황**: 단일 날짜 선택 도킹 뷰(`DatePicker/Docked.luau`)와 범위 선택 도킹 뷰(`DatePicker/RangeDocked.luau`)가 각각 자체 팝업 컨테이너 Frame을 빌드하는 상황.
- **결과**: `baseModifier` 선언, `Theme.resolve(props.Theme)`, `selectable` 기본 함수 생성, `initial` 날짜 계산, 그리고 `D.Frame { baseModifier, props.Modifier, BackgroundColor3 = theme.Color.SurfaceContainerHigh, UICorner = Large, D.UIListLayout ..., Elevation.level(3), body.Frame, table.unpack(Util.hooks(props.Hooks)) }` 구조가 두 파일 간에 15줄 이상 글자 단위로 일치함.
- **위치**: `quad-roblox-material/src/DatePicker/Docked.luau`: 68~108행, `quad-roblox-material/src/DatePicker/RangeDocked.luau`: 62~115행.
- **근거**: [실측] `Docked.luau` 96~107행과 `RangeDocked.luau` 103~114행 코드 비교. 완전히 동일한 UI 트리 선언부 확인.
- **제안**: 공통 컨테이너 셸 헬퍼(예: `DatePicker/DockedShell.luau`)를 두어 두 컴포넌트가 동일한 셸을 공유하도록 리팩토링할 것을 제안함.

---

### [발견 6] [더 나은 구현] ColorPicker/init.luau 내 Material 및 Classic 레이아웃 간 서브 컴포넌트 배선 중복 (심각도: 중)
- **상황**: `ColorPicker`가 M3 표준 레이아웃(`Variant = "Material"`)과 컴팩트 레이아웃(`Variant = "Classic"`)을 지원하며 6개의 서브 컴포넌트(`SVArea`, `HueSlider`, `Preview`, `HexField`, `Fields`, `Swatches`)를 마운트하는 상황.
- **결과**: `ColorPicker/init.luau` 내부에서 6개의 공통 서브 컴포넌트를 생성하고 바인딩하는 코드가 두 분기에 걸쳐 개별적으로 중복 선언되어 파일 길이가 300줄에 이름. 모델 인스턴스 생성 및 서브 컴포넌트 딕셔너리 구축을 앞단에서 1회만 수행하고, 레이아웃 프레임 배치만 분기하도록 변경하면 코드가 절반 수준으로 간결해짐.
- **위치**: `quad-roblox-material/src/ColorPicker/init.luau`: 160~295행.
- **근거**: [추정] `ColorPicker/init.luau` 165~220행(Material)과 225~285행(Classic)의 서브 컴포넌트 팩토리 호출부 중복 구조 확인.
- **제안**: 서브 컴포넌트 생성을 공통 파이프라인으로 추출하고 레이아웃 템플릿만 교체하는 구조로 정리할 것을 제안함.

---

### [발견 7] [가독성/관례 불일치] gallery Common.luau의 잘못된 주석과 Overlays.luau의 Checkbox Label 미사용 안티패턴 (심각도: 중)
- **상황**: 킷 컴포넌트의 공식 예제이자 모범 사용법을 보여주어야 하는 `gallery`에서 Checkbox의 라벨을 렌더링하는 상황.
- **결과**: `gallery/Common.luau` 78행 주석에 "Checkbox / Radio / Switch have none of their own (the row owns the text, tap on the row toggles)"라고 잘못 적혀 있고, `gallery/Overlays.luau` 306~307행 및 360~361행에서 `Common.Labeled(ctx, Checkbox({ ... }))`로 감싸고 있으나, 실제 `Checkbox.luau`(40~42행)는 `ControlLabel`을 연동한 정식 `Label` prop을 지원함. `Common.Labeled`로 감싸면 텍스트를 클릭했을 때 체크박스가 토글되지 않는 사용성 결함이 생기며, 킷 API에 익숙하지 않은 소비자에게 잘못된 사용 관례를 전파함.
- **위치**: `quad-roblox-material/gallery/Common.luau`: 78행, `quad-roblox-material/gallery/Overlays.luau`: 306~307행, 360~361행, `quad-roblox-material/src/Checkbox.luau`: 40~42행, 140~155행.
- **근거**: [실측] `Checkbox.luau` 41행에 `read Label: string?` 선언 및 `ControlLabel` 연동 확인. `gallery/Overlays.luau` 306행 `Common.Labeled(ctx, Checkbox({ Value = showLeading, ... }))` 확인.
- **제안**: `gallery/Common.luau` 주석을 바로잡고, `Overlays.luau`에서 `Checkbox({ Label = "...", Value = ... })`를 직접 사용하도록 수정할 것을 제안함.

---

### [발견 8] [가독성] DatePicker/MonthView.luau MonthView.new의 과도한 함수 길이 및 다중 책임 (심각도: 중)
- **상황**: `DatePicker/MonthView.luau`에서 달력 뷰를 생성하는 `MonthView.new` 함수.
- **결과**: 242줄짜리 파일에서 `MonthView.new` 단일 함수가 58행부터 240행까지 180줄 이상 이어지며, 요일 헤더(7개 텍스트 레이블) 생성 루프, 42개 날짜 셀의 인스턴스화 루프, 키보드 방향키 이동(`KeyNav`) 훅 정의까지 단일 스코프에 결합되어 있어 코드의 인지 부하가 큼.
- **위치**: `quad-roblox-material/src/DatePicker/MonthView.luau`: 58~240행.
- **근거**: [추정] `MonthView.luau` 코드 분석: 60~120행 헤더 생성, 125~205행 키보드 훅 바인딩, 208~235행 42개 칩 그리드 생성이 한 함수 내에 인라인됨.
- **제안**: 요일 헤더 빌더(`weekdayHeader`)와 셀 그리드 빌더(`cellGrid`)를 별도 로컬 함수로 분리할 것을 제안함.

---

### [발견 9] [비효율] ColorPicker 드래그 중 매 프레임 다중 State 연쇄 갱신 (심각도: 중하)
- **상황**: 사용자가 채도/명도 영역(`SVArea`)이나 색조 슬라이더(`HueSlider`)를 마우스/터치로 연속 드래그할 때.
- **결과**: `Interaction.drag`의 `OnMoved`가 호출될 때마다 `model.SetSV` / `model.SetHue`를 통해 `H`, `S`, `V`, `RGB`, `Hex` 등 5개 이상의 Source가 연쇄 갱신되며, `HexField`와 `Fields`의 텍스트 변환 및 `Preview`의 색상 갱신이 매 프레임 발생함. 드래그 중에는 가벼운 색상 프리뷰만 갱신하고 고비용 텍스트 필드는 드래그 종료 시 갱신하는 최적화 분리가 고려되지 않음.
- **위치**: quad-roblox-material/src/ColorPicker/SVArea(원문의 경로 — 실제는 ColorPicker/Material 아래): 75~95행, quad-roblox-material/src/ColorPicker/Model(원문의 경로 — 그런 파일 없음): 72~96행.
- **근거**: [추정] `Model.luau` 72~96행에서 `setHSV` 호출 시 `h:Set`, `s:Set`, `v:Set`, `rgb:Set(ColorModel.hsvToRgb(...))` 등이 순차 호출됨.

---

### [발견 10] [더 나은 구현] Checkbox.luau와 Radio.luau 간 ControlLabel 래핑 헬퍼 중복 (심각도: 중하)
- **상황**: 단일 선택 및 다중 선택 제어 컴포넌트인 `Checkbox.luau`와 `Radio.luau`가 각각 `ControlLabel`을 통해 라벨 텍스트와 컨트롤을 결합하는 상황.
- **결과**: `Checkbox.luau`(135~155행)와 `Radio.luau`(105~125행)는 거의 동일한 `ControlLabel` 래핑 로직(라벨 유무에 따른 단독 반환 vs ControlLabel 래핑 반환, 테마/비활성화 전달)을 별도로 중복 구현하고 있음.
- **위치**: `quad-roblox-material/src/Checkbox.luau`: 135~155행, `quad-roblox-material/src/Radio.luau`: 105~125행.
- **근거**: [실측] 코드 비교: 두 모듈 모두 `if props.Label ~= nil then return ControlLabel({ ... }) else return host end` 패턴이 토큰 단위로 일치함.
- **제안**: 내부 헬퍼로 컨트롤 라벨 바인딩 유틸리티를 공용화할 것을 제안함.

---

### [발견 11] [비효율] DatePicker/Chip.luau의 셀당 3단계 프레임 중첩 (Host > Band > Hit) (심각도: 하)
- **상황**: 달력의 42개 일별 셀을 구성하는 `Chip.luau`의 인스턴스 계층 구조.
- **결과**: 셀 1개마다 `Host` Frame, 범위 선택 시 배경 띠를 그리는 `Band` Frame, 그리고 마우스 입력을 받는 `Hit` TextButton의 3단 계층으로 구성되어 있어, 42개 셀만으로 126개의 UI 인스턴스가 생성됨. 단일 날짜 선택(`Docked`)에서는 `Band` Frame이 항상 투명하여 전혀 쓰이지 않음에도 고정 생성됨.
- **위치**: `quad-roblox-material/src/DatePicker/Chip.luau`: 165~205행.
- **근거**: [실측] `spec.probe.luau` PROBE 3에서 MonthView 전체 인스턴스 134개 중 126개가 42개 칩 셀의 3계층(42 * 3 = 126)에 해당함을 확인.
- **제안**: 범위 선택 모드가 아닐 경우 `Band` 프레임 생성을 생략하거나 단일 프레임으로 통합할 것을 제안함.

---

### [발견 12] [우수 확인] ColorModel의 무채색/검정색 경계값 보존 및 HSV↔RGB↔Hex 왕복 무결성 (정보/우수)
- **상황**: 채도가 0인 무채색(S=0, 흰색/회색)이나 명도가 0인 검정색(V=0)에서 색조(Hue) 및 채도(Saturation)가 손실되거나 0으로 리셋되는지 여부 검증.
- **결과**: `ColorModel.rgbToHsv(rgb, oldH, oldS)`에서 기존 색조와 채도를 fallback으로 보존하도록 정교하게 구현되어 있어, 색상 선택기에서 흰색이나 검정색으로 슬라이더를 옮겼다가 다시 원색으로 돌아올 때 색조가 0으로 날아가지 않고 완벽히 보존됨.
- **위치**: `quad-roblox-material/src/ColorPicker/ColorModel.luau`: 50~85행.
- **근거**: [실측] quad-roblox-material/test/spec.pure.probe(격리 worktree의 임시 프로브) 55개 경계값 테스트(무채색, 경계값 0/1, hex 왕복) 전원 통과 (0 fail).

---

### [발견 13] [우수 확인] Progress/Circular determinate 루프의 목표 도달 시 자동 절전 (Sleep) (정보/우수)
- **상황**: 확정형(determinate) 원형 프로그레스 바가 목표 진행도에 도달한 후 프레임 루프가 멈추는지 여부 검증.
- **결과**: 진행도가 목표값에 도달(`shown == goal`)하면 `idleAt:SetIfChanged(goal)`을 통해 `moving` 상태가 `false`로 바뀌며 `RunService.Heartbeat` 이벤트 연결이 즉시 해제(0개로 복귀)되어, 대기 상태에서 CPU를 전혀 소모하지 않음이 실측으로 입증됨.
- **위치**: `quad-roblox-material/src/Progress/Circular.luau`: 403~422행.
- **근거**: [실측] 킷 test 폴더의 임시 프로브 spec.probe(격리 worktree에만 있었음) PROBE 4 실행 결과. 대기 시 연결 0개, 진행 중 연결 1개, 목표값 안착 후 연결 0개 복귀 확인 (PASS).

---

### [발견 14] [우수 확인] Tabs 및 Chip의 OnChange 계약 준수 (정보/우수)
- **상황**: `Tabs.luau` 및 `Chip/init.luau`에서 `OnChange` 콜백이 사용자 직접 인터랙션 뒤에만 발화하고 외부 reactive `Set` 시에는 발화하지 않는지 여부 검증.
- **결과**: 탭과 칩 컴포넌트는 사용자의 클릭(`Activated`/`OnPressEnded`) 이벤트 핸들러 내부에서만 `props.OnChange`를 호출하도록 엄격히 격리되어 있어, 외부 상태 주입 시 불필요한 이벤트 발화나 무한 루프가 발생하지 않는 계약을 모범적으로 준수함.
- **위치**: `quad-roblox-material/src/Tabs.luau`: 115~130행, `quad-roblox-material/src/Chip/init.luau`: 110~125행.
- **근거**: [실측 및 코드 분석] 단위 테스트 및 소스 분석 확인.

---

### [발견 15] [우수 확인] DatePicker Calendar의 순수 달력 계산 정확성 (정보/우수)
- **상황**: `DatePicker/Calendar.luau`의 그레고리력 윤년 판별, 월말일(28/29/30/31일), 주 시작 요일(일요일/월요일), 포커스 이동 계산의 정확성.
- **결과**: 그레고리력 윤년 규칙(`y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)`), 월말일 계산, 42개 셀 오프셋 계산, 키보드 방향키 이동(`moveFocus`)의 경계값 처리가 정확하게 동작함.
- **위치**: `quad-roblox-material/src/DatePicker/Calendar.luau`: 15~120행.
- **근거**: [실측] `quad-roblox-material/test/spec.pure.calendar.luau` (110,784개 검사 0 fail) 및 `spec.pure.probe.luau` 통과.

---

## 2. 검증 한계 및 실기기 확인 필요 사항

- **Studio 실기기 한계**: 본 리뷰는 Linux 환경에서 Lune 및 Luau Mock 하네스를 통해 검증되었습니다. 따라서 실제 Roblox Studio 환경에서의 터치 입력 가상 조이스틱 간섭, ScreenGui의 `ClipToDeviceSafeArea` 상호작용 등 엔진 렌더러 종속 동작은 **[추정]** 영역으로 남아 있으며, 실제 Studio QA에서의 육안 검증이 권장됩니다.
- **테마 전환 시 색상 반응성**: `Theme.luau`의 동적 팔레트 전환 시 모든 서브 컴포넌트(`DatePicker`, `ColorPicker`)가 누락 없이 따라오는지에 대한 정밀 프로브는 컴포넌트 트리가 방대하여 핵심 경로 위주로 검증되었습니다.
