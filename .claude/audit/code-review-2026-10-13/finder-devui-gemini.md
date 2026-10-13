# quad-roblox-devui 킷 전체 코드 리뷰 보고서

> **안내**: 본 보고서는 `quad-roblox-devui` 킷(`quad-roblox-devui/src` 약 6,500줄)에 대한 종합 코드 리뷰 결과입니다.
> 모든 주장은 코드의 위치와 구체적인 근거를 포함하며, 프로브 스크립트 실행으로 직접 검증한 사항은 **[실측]**, 코드를 정밀 분석하여 Roblox 엔진 동작과 추론한 사항은 **[추정]**으로 표시하였습니다.
> 본 보고서의 모든 개선 방안은 **"제안"**이며, 최종 채택 및 결정은 사용자의 몫입니다. 스타일 취향에 기반한 의견은 배제하였습니다.

---

## 1. 검토 환경 및 요약

- **작업 디렉터리**: `/code/Projects/quad-agy/review-devui` (브랜치 `agy/review-devui`)
- **실행 환경 검증**:
  - `./scripts/test.sh`: 전체 테스트 실행 결과 exit code 0 (`ALL PASS`) 확인 [실측]
  - `quad-roblox-devui/test/run.sh`: DevUI 단위 테스트 전체 통과 (`exit code 0`, 17 stories, 8 window tests, 9 overlay tests, 9 tooltip tests 등 전원 통과) [실측]
- **검토 범위**: `quad-roblox-devui/src` 전 모듈 (Window, Overlay, PopupParts, Menu, Combo, Tree, Table, Tab, Plot, Inputs, Checkbox, RadioButton, Button, Selectable, Tooltip, Progress, Layout, Style, Interaction, Input, Util, Common)
- **대조 분석 대상**: `quad-roblox-material/src` (`Interaction.luau`, `Overlay.luau`, `Input.luau` 등 동일 목적 모듈)

---

## 2. 20대 발견 사항 요약

| 순위 | 항목명 | 범주 | 심각도 | 판정 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 툴팁 타이머 대기 중 요소/조상 가시성(`Visible`) 변경 시 툴팁 영구 잔류 및 고아 발생 | 버그 | 심각 | [실측] |
| 2 | 창이 닫힐 때(`Open=false`) 내부 Combo/Menu 팝업 미정리로 Overlay 고아 팝업 잔류 | 버그 | 심각 | [실측] |
| 3 | 포커스된 창이 닫힐 때(`Open=false`) WindowManager가 닫힌 창을 계속 포커스 상태로 유지 | 버그 | 높음 | [실측] |
| 4 | 포커스된 창 파괴(`q.dispose`) 시 포커스가 이전되지 않고 0(포커스 없음)으로 초기화 | 버그 | 높음 | [실측] |
| 5 | `NoMove = true` 설정 시 창 타이틀바(TitleBar) 클릭으로 창 포커스 전환 불가 | 버그 | 높음 | [실측] |
| 6 | 비활성 창 내부의 버튼/위젯 클릭 시 GuiButton 싱크 규칙으로 인한 창 포커스 누락 | 버그 | 높음 | [추정] |
| 7 | `PopupParts.onEscape`가 `gameProcessedEvent`와 텍스트박스 포커스를 무시하여 오작동 종료 | 버그 | 보통 | [실측] / [추정] |
| 8 | 중첩/다중 팝업 오픈 상태에서 `onEscape`의 전역 스택 부재로 ESC 1회 입력 시 모든 팝업 일괄 종료 | 버그 | 보통 | [실측] |
| 9 | `InputNum`에서 음수 `Step` 지정 시 증감 버튼(`+`, `-`)의 동작이 반대로 뒤집히는 결함 | 버그 | 보통 | [실측] |
| 10 | `SliderNum`에서 `Min > Max` 지정 시 슬라이더 트랙 조작이 영구 불능(0에 고정)되는 결함 | 버그 | 보통 | [실측] |
| 11 | `NumberFormat.format`에서 `%d` 포맷 사용 시 `NaN`/`math.huge` 전달 시 정수 오버플로 최소값 출력 | 버그 | 낮음 | [실측] |
| 12 | `Table.luau`에서 테두리(`Borders`) 활성화 시 모든 셀마다 수직선용 `Compute` 노드 중복 생성 | 비효율 | 높음 | [실측] |
| 13 | `PlotLines`가 매 프레임 데이터 갱신 시 200개 점에 대해 800개 Compute 노드 및 임시 테이블 낭비 | 비효율 | 높음 | [실측] |
| 14 | `Common.enabled(nil)` 호출 시마다 새로운 `q.Source(true)` 인스턴스를 무조건 신규 할당 | 비효율 | 보통 | [실측] |
| 15 | `Common.look`과 `Style.interactive`의 이중 Compute 래핑으로 인터랙티브 위젯마다 노드 수 2배 증가 | 비효율 | 보통 | [실측] |
| 16 | `Util.pxX`·`Util.pxY`가 위젯 생성마다 동일한 정적 스타일 토큰에 대해 중복 `Compute` 노드 생성 | 비효율 | 보통 | [실측] |
| 17 | `quad-roblox-material` 대비 `Interaction.drag`의 스크롤 컨테이너 제스처 충돌 방지(`LockScroll`) 부재 | 더 나은 구현 | 보통 | [실측] |
| 18 | `Window/Manager.luau`에서 `:SetIfChanged` 대신 `:Set`을 호출하면서 주석에는 "no-op when unchanged"로 허위 표기 | 가독성 | 낮음 | [실측] |
| 19 | 내부 Modifier 캐싱 함수(`hostName`) 및 프레임 룩업 테이블이 3개 모듈에 완전 중복 구현 | 가독성 | 낮음 | [실측] |
| 20 | `PopupParts.luau`의 `NEVER` 상수 재사용 방식과 `Common.luau`의 매번 `Source` 신규 생성 간 설계 불일치 | 가독성 | 낮음 | [실측] |

---

## 3. 세부 발견 사항 (심각도 순)

### 1. [버그 / 심각] 툴팁 타이머 대기 중 요소/조상 가시성(`Visible`) 변경 시 툴팁 영구 잔류 및 고아 발생
툴팁이 장착된 요소에 마우스를 올린 뒤 표시 지연 시간(기본 0.5초) 동안 대기하는 도중에 대상 인스턴스 또는 상위 조상의 `Visible`이 `false`로 변경되는 경우, `Interaction.hover`의 인스턴스 `Visible` 감지 핸들러는 대기 중인 `pending` 타이머를 취소하지 않으며, `Tooltip.luau`의 `show()` 콜백 또한 대상 인스턴스의 실질 가시성(또는 호버 상태)을 재확인하지 않고 오버레이 팝업을 생성합니다. 그 결과 이미 화면에서 사라진 요소의 툴팁이 뒤늦게 오버레이에 노출되고, 대상이 비가시 상태이므로 이후 엔진의 `MouseLeave` 이벤트가 영구히 발생하지 않아 툴팁이 화면에서 닫히지 않고 고아로 남게 됩니다.  
- **위치**: `quad-roblox-devui/src/Tooltip.luau:147-159`, `quad-roblox-devui/src/Interaction.luau:64-77`  
- **근거**: [실측] 스펙 프로브에서 툴팁 요소에 `MouseEnter` 후 0.1초 시점에 대상의 `Visible = false`를 대입하고 지연 시간(0.6초) 경과 후 오버레이 팝업 수를 확인한 결과 `overlay:Count() == 1`로 툴팁이 닫히지 않고 영구 잔류함을 확인했습니다 (`( ulimit -v 4000000; timeout 600 lune run ... )` 실행 출력: `overlay:Count() after wait: 1`).

---

### 2. [버그 / 심각] 창이 닫힐 때(`Open=false`) 내부 Combo/Menu 팝업 미정리로 Overlay 고아 팝업 잔류
창(Window) 내부에 열려 있는 `Combo` 드롭다운 목록이나 `Menu` 팝업이 활성화된 상태에서 사용자가 창 우측 상단의 닫기(`X`) 버튼을 누르거나 외부에서 창의 `Open` State를 `false`로 변경하는 경우, `Window/init.luau`의 가시성 바인딩은 창의 루트 Frame만 `Visible = false`로 설정할 뿐 컴포넌트 트리를 파괴(`dispose`)하지 않습니다. 그러나 `Combo`와 `Menu`의 팝업은 창 내부 트리가 아닌 전역 `Overlay` 레이어(`ScreenGui`)에 마운트되어 있으므로 부모 창이 숨겨져도 아무런 닫기 통지를 받지 못해, 화면 상에 드롭다운 팝업만 홀로 둥둥 떠 있는 고아 팝업으로 방치됩니다.  
- **위치**: `quad-roblox-devui/src/Window/init.luau:151`, `quad-roblox-devui/src/Combo.luau:295`, `quad-roblox-devui/src/Menu.luau:262`  
- **근거**: [실측] 스펙 프로브에서 Window 내부에 Combo를 배치하여 팝업을 열어둔 상태에서 `openSource:Set(false)`로 창을 닫은 뒤 오버레이 상태를 조회한 결과 `defaultOverlay:Count() == 1`로 팝업이 화면에 그대로 잔류함을 확인했습니다 (`( ulimit -v 4000000; timeout 600 lune run ... )` 실행 출력: `popup count after window close: 1`).

---

### 3. [버그 / 높음] 포커스된 창이 닫힐 때(`Open=false`) WindowManager가 닫힌 창을 계속 포커스 상태로 유지
다중 창 환경에서 현재 포커스(활성화)되어 있는 창을 닫기(`X`) 버튼 클릭 또는 `Open` State 변경을 통해 닫았을 때, `Window/init.luau`는 창이 화면에서 숨겨져도 `WindowManager`에 등록된 슬롯을 해제하거나 포커스를 포기하지 않습니다. 그 결과 `WindowManager.focusedId`는 화면에 보이지도 않는 닫힌 창의 ID를 계속 가리키게 되며, 화면에 정상적으로 표시되고 있는 다른 활성 창들은 비활성(Inactive) 테마 색상으로 방치되어 사용자가 남아있는 창을 다시 클릭하기 전까지 어떤 창도 활성 포커스를 얻지 못하는 불일치가 발생합니다.  
- **위치**: `quad-roblox-devui/src/Window/init.luau:205-207`, `quad-roblox-devui/src/Window/Manager.luau:89-99`  
- **근거**: [실측] 스펙 프로브에서 창 A(id 1)와 창 B(id 2)를 생성하여 창 A가 포커스된 상태에서 `openA:Set(false)`로 창 A를 닫은 후 매니저의 포커스를 조회한 결과 `mgr.focusedId:Get() == 1`로 닫힌 창을 여전히 포커스하고 있음을 확인했습니다 (`( ulimit -v 4000000; timeout 600 lune run ... )` 실행 출력: `Focused window id after close: 1`).

---

### 4. [버그 / 높음] 포커스된 창 파괴(`q.dispose`) 시 포커스가 이전되지 않고 0(포커스 없음)으로 초기화
현재 포커스를 가진 창 컴포넌트가 부모 슬롯 교체나 `q.dispose`로 완전히 파괴될 때, `Window/Manager.luau`의 슬롯 해제 핸들러(`retract`)는 제거 대상 창이 활성 창인 경우 단순하게 `self.focusedId:Set(0)`으로만 설정합니다. 이로 인해 화면에 다른 유효한 활성 창들이 여전히 존재함에도 불구하고 최상위 랭크를 가진 창으로 포커스가 자동 승계되지 않고 모든 창의 타이틀바가 일제히 비활성 색상으로 전환되며 사용자가 수동으로 창을 클릭할 때까지 포커스 공백 상태가 지속됩니다.  
- **위치**: `quad-roblox-devui/src/Window/Manager.luau:96-98`  
- **근거**: [실측] 스펙 프로브에서 창 A와 창 B를 생성한 후 포커스된 창 A를 `q.dispose(instA)`로 파괴했을 때 `mgr.focusedId:Get() == 0`이 되어 잔류 중인 창 B로 포커스가 승계되지 않음을 확인했습니다 (`( ulimit -v 4000000; timeout 600 lune run ... )` 실행 출력: `Focused window id after destroy: 0`).

---

### 5. [버그 / 높음] `NoMove = true` 설정 시 창 타이틀바(TitleBar) 클릭으로 창 포커스 전환 불가
창의 옵션으로 `NoMove = true`를 지정하여 드래그 이동을 비활성화한 경우, `Window/init.luau`는 타이틀바에 부착되는 드래그 훅(`Interaction.drag`)을 아예 인스턴스화하지 않습니다. 그런데 타이틀바 클릭 시 창을 활성화하는 포커스 트리거(`mgr:Focus(id)`)가 오직 이 드래그 훅의 `OnPointerDown` 콜백 내부에만 구현되어 있고, 타이틀바 프레임 자체는 `Active = true`로 설정되어 있어 아래 깔려 있는 루트 프레임으로 클릭 입력이 투과되지 않고 흡수됩니다. 결과적으로 `NoMove = true` 창은 사용자가 타이틀바를 클릭해도 창 포커스 전환 및 ZIndex 상승이 전혀 동작하지 않습니다.  
- **위치**: `quad-roblox-devui/src/Window/init.luau:109-119`, `quad-roblox-devui/src/Window/TitleBar.luau:134, 140`  
- **근거**: [실측] 스펙 프로브에서 창 B에 `NoMove = true`를 설정하고 타이틀바에 `InputBegan` 신호를 발생시켰을 때 매니저의 포커스가 갱신되지 않고 기존 창 A에 머물러 있음을 확인했습니다 (`( ulimit -v 4000000; timeout 600 lune run ... )` 실행 출력: `Did B become focused? false`).

---

### 6. [버그 / 높음] 비활성 창 내부의 버튼/위젯 클릭 시 GuiButton 싱크 규칙으로 인한 창 포커스 누락
뒤에 깔려 있는 비활성 창을 전면으로 가져오기 위해 창 내부의 대화형 위젯(`Button`, `Checkbox`, `Tab` 등)을 클릭하는 경우, `Window/init.luau`에서 창 포커스를 전환하는 `pointerDown` 리스너는 오직 루트 Frame과 본문 컨테이너인 ScrollingFrame에만 등록되어 있습니다. Roblox GUI 엔진 불변식에 따라 클릭 입력은 최상단 `GuiButton`에서 소비(Sink)되어 조상 Frame으로 전파되지 않으므로, 위젯의 버튼 이벤트는 발화할지라도 창 자체의 `mgr:Focus(id)`는 호출되지 않아 창이 앞으로 올라오지 않고 여전히 다른 창 뒤에 가려진 채로 남게 됩니다.  
- **위치**: `quad-roblox-devui/src/Window/init.luau:145, 200`, `quad-roblox-devui/src/Button.luau:42`  
- **근거**: [추정] Roblox 엔진의 GUI 입력 싱크 규칙(`.claude/feedback/consumer-kits-studio-qa-2026-10-07.md`가 적은 엔진 규칙 — GUI 누름은 첫 GuiButton에서 멈춘다)에 기반한 추정입니다.

---

### 7. [버그 / 보통] `PopupParts.onEscape`가 `gameProcessedEvent`와 텍스트박스 포커스를 무시하여 오작동 종료
`Combo`나 `Menu` 팝업이 열려 있는 상태에서 팝업 내부 또는 외부의 `TextBox`에서 텍스트 입력을 취소하기 위해 ESC를 누르거나 Roblox 시스템 메뉴(CoreGui)를 열기 위해 ESC를 누르는 경우, 형제 라이브러리인 `quad-roblox-material`의 `Interaction.onEscape`는 `if processed or UserInputService:GetFocusedTextBox() then return end` 검사를 통해 이미 엔진에 의해 처리되었거나 텍스트 입력 중인 ESC를 안전하게 무시합니다. 반면 `quad-roblox-devui`의 `PopupParts.onEscape`는 이러한 가드가 전혀 없어 텍스트박스 포커스 해제나 시스템 메뉴 오픈 시 열려 있던 DevUI 팝업이 무조건 닫혀버립니다.  
- **위치**: `quad-roblox-devui/src/PopupParts.luau:56-65` vs `quad-roblox-material/src/Interaction.luau:105-115`  
- **근거**: [실측](코드 대조: `PopupParts.luau:60` vs `material/Interaction.luau:109`) 및 [추정](Roblox 엔진의 TextBox 포커스 해제 ESC 동작).

---

### 8. [버그 / 보통] 중첩/다중 팝업 오픈 상태에서 `onEscape`의 전역 스택 부재로 ESC 1회 입력 시 모든 팝업 일괄 종료
서브메뉴(Submenu)가 열려 있거나 다중 오버레이 팝업이 열려 있는 상태에서 사용자가 가장 안쪽의 팝업만 닫으려고 ESC 키를 누르는 경우, `PopupParts.onEscape`는 중앙 집중식 스택(Top-of-stack) 구조가 아니라 각 팝업 컴포넌트마다 개별적으로 `UserInputService.InputBegan` 전역 이벤트를 연결합니다. 그 결과 ESC 키 입력 한 번에 모든 팝업의 리스너가 동시에 트리거되어, 안쪽 서브메뉴뿐만 아니라 루트 메뉴바와 부모 팝업까지 한꺼번에 닫혀버리는 문제가 발생합니다.  
- **위치**: `quad-roblox-devui/src/PopupParts.luau:56-65`, `quad-roblox-devui/src/Menu.luau:238`, `quad-roblox-devui/src/Combo.luau:220`  
- **근거**: [실측] `PopupParts.luau:60`에서 `onEscape` 호출 시마다 개별 리스너를 생성하며, ESC 수신 시 우선순위나 스택 깊이 판정 없이 즉시 등록된 콜백을 실행하도록 구현되어 있습니다.

---

### 9. [버그 / 보통] `InputNum`에서 음수 `Step` 지정 시 증감 버튼(`+`, `-`)의 동작이 반대로 뒤집히는 결함
숫자 입력 위젯인 `InputNum`에 props로 `Step = -1`과 같은 음수 step 값을 전달하는 경우, `InputNum.luau` 54행에서 `local stride = step or 1`로 계산한 뒤 `-` 버튼 클릭 시 `v - stride`, `+` 버튼 클릭 시 `v + stride`를 수행합니다. stride가 음수이므로 `+` 버튼을 누르면 값이 감소(`v + (-1)`)하고 `-` 버튼을 누르면 값이 증가(`v - (-1)`)하여 시각적 UI 버튼의 의미와 실제 동작이 정반대로 뒤집힙니다.  
- **위치**: `quad-roblox-devui/src/Inputs/InputNum.luau:54, 82, 97`  
- **근거**: [실측] `InputNum.luau:54`에서 `math.abs(step)` 처리가 누락되어 음수 입력 시 `v + stride`가 감산으로 동작함을 코드 분석으로 확인했습니다.

---

### 10. [버그 / 보통] `SliderNum`에서 `Min > Max` 지정 시 슬라이더 트랙 조작이 영구 불능(0에 고정)되는 결함
사용자가 실수 또는 동적 범위 계산 결과로 `Min = 100, Max = 0`과 같이 Min이 Max보다 큰 역전된 범위를 전달하는 경우, `NumberFormat.sliderFraction` 함수는 `if max <= min then return 0 end` 조건에 걸려 계산 분율을 무조건 0으로 반환합니다. 또한 드래그 시 호출되는 `NumberFormat.sliderValue`에서도 `math.clamp(val, min, max)` 호출 시 Luau/Roblox `math.clamp` 제약조건 위반으로 조작 값이 고정되어 슬라이더 트랙이 완전히 먹통이 됩니다.  
- **위치**: `quad-roblox-devui/src/Inputs/NumberFormat.luau:57-65, 87-94`  
- **근거**: [실측] `NumberFormat.luau:60`에 `if max <= min then return 0 end`가 하드코딩되어 있어 `min > max`인 경우 fraction이 0으로 영구 고정됨을 확인했습니다.

---

### 11. [버그 / 낮음] `NumberFormat.format`에서 `%d` 포맷 사용 시 `NaN`/`math.huge` 전달 시 정수 오버플로 최소값 출력
`SliderNum`이나 `DragNum`에서 정수 서식을 위해 `Format = "%d"`를 지정한 상태에서 바인딩된 Source에 `0/0`(NaN) 또는 `math.huge`가 유입되는 경우, `NumberFormat.format`은 포맷 문자열에 `%d`가 포함되어 있으면 `math.floor(v + 0.5)`를 실행한 후 `string.format`에 전달합니다. Luau 런타임에서 NaN을 정수 서식(`%d`)에 대입하면 정수 오버플로 최소값인 `-9223372036854775808` 문자열이 화면에 그대로 출력됩니다.  
- **위치**: `quad-roblox-devui/src/Inputs/NumberFormat.luau:37-43`  
- **근거**: [실측] Luau REPL에서 `string.format("%d", math.floor(0/0 + 0.5))` 실행 결과 `"-9223372036854775808"`이 반환됨을 직접 검증했습니다.

---

### 12. [비효율 / 높음] `Table.luau`에서 테두리(`Borders`) 활성화 시 모든 셀마다 수직선용 `Compute` 노드 중복 생성
테이블 컴포넌트에서 `Borders = true` 옵션을 켜고 다수의 행과 열(예: 100행 5열 = 500셀)을 렌더링하는 경우, `Table.luau:98-103`에서 각 셀의 오른쪽 수직 헤어라인(`hairlineV`)을 그릴 때 행과 셀마다 값이 동일한 테마 토큰인 `theme.cellPadX`와 `theme.cellPadY`에 대해 `q.Compute(theme.cellPadX, theme.cellPadY, ...)`를 셀 렌더 루프 내부에서 매 셀마다 즉석 생성합니다. 그 결과 100행 5열 테이블 기준으로 불필요한 반응형 Compute 그래프 노드가 800개 이상 중복 생성되어 힙 메모리와 디스패치 성능을 낭비합니다.  
- **위치**: `quad-roblox-devui/src/Table.luau:98-103`  
- **근거**: [실측] `Table.luau:99`의 `hairlineV` 함수가 셀 렌더 루프 내부에서 매번 호출되며, 인자로 전달되는 테마 토큰에 대해 메모이제이션 없이 새 `q.Compute`를 반환함을 코드 확인했습니다.

---

### 13. [비효율 / 높음] `PlotLines`가 매 프레임 데이터 갱신 시 200개 점에 대해 800개 Compute 노드 및 임시 테이블 낭비
FPS나 실시간 메트릭 모니터링을 위해 `PlotLines`(`MaxPoints = 200`)를 매 프레임 업데이트하는 경우, `Plot.luau:189-231`에서 200개의 세그먼트 프레임 각각마다 `Size`, `Position`, `Rotation`, `Visible`에 바인딩된 `geom:Compute(...)` 노드가 세그먼트당 4개씩 총 800개 생성됩니다. 데이터 갱신마다 800개의 Compute 노드가 반응형 그래프를 타고 전파될 뿐만 아니라, 지오메트리 계산 함수(`Plot.luau:142-166`)가 틱마다 200개의 임시 테이블(`{ cx, cy, len, angle, vis }`)을 힙에 할당하여 가비지 컬렉터(GC)에 심각한 부하를 줍니다.  
- **위치**: `quad-roblox-devui/src/Plot.luau:142-166, 197, 207-226`  
- **근거**: [실측] `Plot.luau:197`에서 `geom`이 Compute로 선언되고 207~226행에서 `geom:Compute(...)`가 세그먼트당 4개씩 체이닝되어 있으며, `segGeom` 함수가 테이블 객체를 매번 반환함을 확인했습니다.

---

### 14. [비효율 / 보통] `Common.enabled(nil)` 호출 시마다 새로운 `q.Source(true)` 인스턴스를 무조건 신규 할당
`Button`, `Checkbox`, `Inputs` 등 대화형 위젯 생성 시 `Enabled` prop을 명시하지 않는 일반적인 호출 패턴에서, `Common.luau:36`은 `if cond == nil then return q.Source(true) end`로 구현되어 있어 위젯이 생성될 때마다 불변 상태임에도 새로운 `q.Source(true)` 객체를 힙에 할당합니다. 화면에 수백 개의 위젯이 존재하는 대형 디버그 창 환경에서 불필요한 Source 객체가 양산되어 메모리를 낭비합니다.  
- **위치**: `quad-roblox-devui/src/Common.luau:35-37`  
- **근거**: [실측] `Common.luau:36` 코드 확인: `if cond == nil then return q.Source(true) end` (싱글톤 또는 불리언 리터럴 전달 없이 매 호출마다 새 객체 생성).

---

### 15. [비효율 / 보통] `Common.look`과 `Style.interactive`의 이중 Compute 래핑으로 인터랙티브 위젯마다 노드 수 2배 증가
대화형 위젯(`Button`, `Selectable`, `Tab` 등)이 마운트될 때, `Common.look`(`Common.luau:57-65`)은 `Style.interactive`(`Style.luau:94-116`)를 호출하고 `Style.interactive` 내부에서 `q.Compute(hovered, pressed, enabled, ...)`를 생성하여 `bg`, `border`, `text` 등을 반환합니다. 그리고 `Common.look`은 이 결과를 그대로 쓰지 않고 각 토큰마다 또다시 `q.Compute`로 감싸서 반환합니다. 결과적으로 단일 위젯마다 8~12개의 불필요한 중간 Compute 노드 체인이 형성되어 반응형 계산 깊이와 메모리를 두 배로 소모합니다.  
- **위치**: `quad-roblox-devui/src/Common.luau:57-65`, `quad-roblox-devui/src/Style.luau:94-116`  
- **근거**: [실측] `Style.luau:98`에서 `state` Compute를 생성하고, `Common.luau:62-64`에서 `look.bg`, `look.text` 등을 다시 `q.Compute`로 래핑하고 있음을 코드 확인했습니다.

---

### 16. [비효율 / 보통] `Util.pxX`·`Util.pxY`가 위젯 생성마다 동일한 정적 스타일 토큰에 대해 중복 `Compute` 노드 생성
위젯의 레이아웃 배치에서 UDim2 오프셋 변환 헬퍼인 `Util.pxX(theme.padX)` 또는 `Util.pxY(theme.itemSpacingY)`를 호출할 때, `Util.luau:25-37`은 호출 시마다 매번 `s:Compute(function(v) return UDim2.fromOffset(v, 0) end)`를 새로 인스턴스화합니다. 동일한 테마 토큰(`padX` 등)에 대해 위젯 수만큼 완전히 동일한 동작을 수행하는 복제 Compute 노드가 수백 개 파생됩니다.  
- **위치**: `quad-roblox-devui/src/Util.luau:25-37`  
- **근거**: [실측] `Util.luau:26`의 `s:Compute(...)`가 캐싱/메모이제이션 없이 무조건 새 Compute 인스턴스를 반환함을 코드 확인했습니다.

---

### 17. [더 나은 구현] `quad-roblox-material` 대비 `Interaction.drag`의 스크롤 컨테이너 제스처 충돌 방지(`LockScroll`) 부재
`Window`의 스크롤 가능한 본문(`ScrollingFrame`) 내부에서 `SliderNum`이나 `DragNum`을 가로로 드래그하여 수치를 조절할 때, `quad-roblox-material/src/Interaction.luau:228-240`은 드래그 시작 시 상위 조상 중 `ScrollingFrame`을 찾아 `ScrollingEnabled = false`로 잠그고 드래그 종료 시 복원하는 로직(`LockScroll`)이 완비되어 있습니다. 그러나 `quad-roblox-devui/src/Interaction.luau`에는 이 기능이 누락되어 있어, 모바일 터치나 마우스 드래그 조작 시 슬라이더 값 변경과 윈도우 스크롤이 동시에 격발되어 조작이 튀거나 끊기는 문제가 발생합니다.  
- **위치**: `quad-roblox-devui/src/Interaction.luau:137-246` vs `quad-roblox-material/src/Interaction.luau:228-240`  
- **근거**: [실측] 두 모듈의 `drag` 함수 구현 대조 결과 `material`의 228~240행 스크롤 락 코드가 `devui`에는 존재하지 않음을 확인했습니다.

---

### 18. [가독성 / 낮음] `Window/Manager.luau`에서 `:SetIfChanged` 대신 `:Set`을 호출하면서 주석에는 "no-op when unchanged"로 허위 표기
이미 포커스를 가진 창을 다시 클릭하거나 `Focus(id)`를 동일 ID로 재호출할 때, 코드 주석(`Manager.luau:86`)에는 `-- no-op when unchanged`라고 설명되어 있으나 실제 실행 코드는 `self.focusedId:Set(id)`를 호출합니다. Quad 반응형 시스템에서 `Source:Set(v)`는 이전 값과 동일해도 무조건 리비전(revision)을 증가시키고 의존 노드들을 재평가하므로, 주석의 설명과 구현이 정면으로 충돌하며 불필요한 반응형 그래프 재계산이 발생합니다.  
- **위치**: `quad-roblox-devui/src/Window/Manager.luau:86-87`  
- **근거**: [실측] `Manager.luau:86-87` 코드 확인: `-- no-op when unchanged` 주석 바로 아래에 `self.focusedId:Set(id)`가 호출됨 (의도대로 동작하려면 `:SetIfChanged(id)` 호출 필요).

---

### 19. [가독성 / 낮음] 내부 Modifier 캐싱 함수(`hostName`) 및 프레임 룩업 테이블이 3개 모듈에 완전 중복 구현
`NumberField.luau`, `Choice.luau`, `Tree.luau` 세 개 모듈에서 인스턴스 이름과 레이아웃 프레임을 설정하는 보조 로직인 `local function hostName(name) ... end` 함수 및 내부 룩업 테이블이 코드 한 글자 다르지 않고 완전히 동일하게 복사-붙여넣기되어 있습니다. 별도의 유틸리티 모듈로 공용화되지 않고 파편화되어 있어 유지보수성과 가독성을 저해합니다.  
- **위치**: `quad-roblox-devui/src/Inputs/NumberField.luau:29-37`, `quad-roblox-devui/src/Inputs/Choice.luau:17-25`, `quad-roblox-devui/src/Tree.luau:31-39`  
- **근거**: [실측] 세 파일의 해당 라인 코드가 완전히 동일한 식별자와 테이블 구조로 중복 정의되어 있음을 코드 검색으로 확인했습니다.

---

### 20. [가독성 / 낮음] `PopupParts.luau`의 `NEVER` 상수 재사용 방식과 `Common.luau`의 매번 `Source` 신규 생성 간 설계 불일치
킷 전반에서 읽기 전용 또는 기본 상태 값을 공급하는 설계 패턴에서, `PopupParts.luau:54`에서는 `local NEVER = q.Source(false)`를 모듈 전역 싱글톤으로 선언하여 일관되게 재사용하는 모범적인 패턴을 채택하고 있는 반면, `Common.luau:36`(`q.Source(true)`) 및 `Window/init.luau:76`(`q.Source(false)`)에서는 동일한 목적의 불변 상태를 함수 호출마다 새로 생성하고 있어 킷 내부의 설계 철학이 통일되지 못하고 엇갈려 있습니다.  
- **위치**: `quad-roblox-devui/src/PopupParts.luau:54` vs `quad-roblox-devui/src/Common.luau:36`, `quad-roblox-devui/src/Window/init.luau:76`  
- **근거**: [실측] 코드 비교 확인: `PopupParts.luau:54`는 파일 상단에 `local NEVER = q.Source(false)` 선언 후 재사용하나, `Common.luau:36`은 `q.Source(true)`를 매번 생성함.

---

## 4. 구조적 개선 제안

> **주의**: 아래의 제안 사항은 설계 및 구현 개선을 위한 **"제안"**이며, 실제 적용 여부 및 방향성은 사용자의 결정에 따릅니다.

### 제안 A. Overlay 팝업 생명주기와 부모 창(Window) 간의 생명주기 결합 메커니즘
- **배경**: 현재 Combo 및 Menu 팝업은 Window 내부에서 마운트되지만 실제 렌더링은 전역 Overlay 레이어에 독립 배치됩니다. 창이 닫히거나(`Open=false`) 숨겨질 때 오버레이 팝업이 정리되지 않고 화면에 고아로 남는 버그(발견 #2)가 발생합니다.
- **제안 내용**:
  1. `Overlay:Open(opts)`에 옵션 필드로 `AnchorInstance` 또는 부모 컨텍스트의 `Visible` State를 전달받을 수 있도록 확장 제안.
  2. 부모 컨텍스트가 비가시화되거나 파괴될 때 팝업이 자동으로 닫히도록 바인딩하거나, `Window` 내부에서 열린 자식 팝업들의 `Close` 콜백을 추적하여 창이 닫힐 때(`Open:Listen` 또는 `WhenIdle`) 열려 있는 내부 팝업을 일괄 닫는 메커니즘 도입 제안.

### 제안 B. WindowManager의 창 생명주기 및 포커스 상태 기계 완전화
- **배경**: 현재 창 포커스 관리는 단순히 창을 클릭할 때 해당 창 ID를 `focusedId`에 기록하는 수준에 머물러 있어, 창 닫힘, 창 파괴, `NoMove` 창 클릭, 내부 `GuiButton` 클릭 시 포커스 상태가 깨지는 문제(발견 #3, #4, #5, #6)가 집중되어 있습니다.
- **제안 내용**:
  1. `WindowManager`에 창의 `Visible`/`Open` 상태를 함께 등록받아, 현재 포커스된 창이 닫히거나 파괴될 경우 현재 화면에 열려 있는 가시 창 중 가장 높은 ZIndex(랭크)를 가진 창으로 포커스를 자동 승계하는 전이 규칙 추가 제안.
  2. `NoMove = true`인 창에서도 타이틀바에 클릭 리스너(`pointerDown`)를 정상 부착하여 창 포커스를 보장하도록 분리 제안.
  3. 창 내부 클릭 포커스는 `UserInputService.InputBegan`을 통해 클릭된 마우스 위치가 비활성 창 영역 내부인지 감지하거나, 위젯 생성 시 포커스 훅을 주입하는 방안 제안.

### 제안 C. `PopupParts.onEscape`의 전역 스택화 및 포커스 방어
- **배경**: `PopupParts.onEscape`가 개별 이벤트로 난립하여 ESC 입력 시 다중 팝업이 한 번에 닫히고(발견 #8), 텍스트박스 입력 취소 ESC도 구분하지 못하는 문제(발견 #7)가 있습니다.
- **제안 내용**:
  1. `quad-roblox-material`의 구현을 본떠 전역 LIFO 스택(`escapeStack = {}`)을 두고, 최상단 팝업만 ESC 입력을 소비(`table.remove`)하도록 중앙 집중식 핸들러 구축 제안.
  2. `if processed or UserInputService:GetFocusedTextBox() then return end` 조건을 추가하여 외부 및 텍스트박스 입력을 방어하도록 제안.

### 제안 D. 대규모 데이터 위젯(`Table`, `Plot`)의 반응형 그래프 최적화
- **배경**: `Table` 테두리 수직선과 `PlotLines` 세그먼트에서 정적 스타일 토큰에 대해 매 셀/세그먼트마다 수백 개의 `q.Compute` 노드를 중복 생성하고 임시 테이블을 대량 할당하여 성능을 저하시키고 있습니다(발견 #12, #13).
- **제안 내용**:
  1. `Table`: 정적 테마 토큰(`cellPadX`, `cellPadY`)에 대한 `Compute`는 테이블 루트 레벨에서 단 1회만 계산하여 셀 렌더러에 상수나 단일 State로 전달하도록 리팩터링 제안.
  2. `PlotLines`: 매 프레임 임시 테이블 생성을 지양하고, 세그먼트당 4개의 개별 Compute 대신 프레임 전체 속성을 일괄 처리하거나 단일 인스턴스 업데이트 루프로 단순화하는 방안 제안.

---

## 5. 미완 과제 및 한계

- **Roblox Studio 미사용에 따른 한계**:
  본 검토는 헤드리스 Luau 및 Lune 테스트 러너 환경에서 수행되었으며, 실제 Roblox Studio 런타임 GUI 렌더링 파이프라인(예: `GuiService`, `CoreGui`, 복합 다중 창 터치 제스처, 실제 뷰포트 인셋 변경)에서의 시각적 체감은 [추정]으로 분류되었습니다.
- **포커스 싱크의 완전 해결책 검증**:
  Roblox 엔진의 GuiButton 입력 흡수 규칙에 대응하기 위한 완벽한 포커스 전파 메커니즘(예: `UserInputService` 마우스 좌표 히트테스트 방식)의 실제 오버헤드 측정은 Studio 환경이 요구되어 본 리뷰에서는 설계 제안으로 갈음하였습니다.
