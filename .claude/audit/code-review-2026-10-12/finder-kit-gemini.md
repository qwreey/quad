# Material 3 킷 최근 구현 리뷰 보고서

> **작업 및 환경 정보**
> - 검토 대상: `quad-roblox-material/src` 가운데 2026-10-08 이후 신설 또는 대규모 변경된 모듈군 (`git diff 6a728190..HEAD -- quad-roblox-material/src`, 약 1만 줄)
> - 주요 검토 대상: `Sheet/`, `BottomSheet/`, `SideSheet/`, `NavigationDrawer/`, `Navigation/`, `NavigationBar.luau`, `NavigationRail/`, `AppBar/`, `Toolbar.luau`, `Scaffold.luau`, `TimePicker/`, `Slider/`, `Button/Split.luau`, `Badge.luau`, `Interactive.luau`, `Interaction.luau`, `Input.luau`, `Ripple.luau`, `Util.luau`, `Overlay.luau`
> - 기준 및 규칙: 모든 주장은 직접 실행하여 확인한 `[실측]`과 코드를 분석하여 추론한 `[추정]`으로 명확히 구분하였으며, 제안 사항은 사용자의 의사결정을 위한 '제안'임을 밝힙니다.

---

## 1. 버그 및 자원 누수 (심각도 순)

### 1.1 `AppBar/Scroll.luau`: ScrollingFrame 파괴 후 `settle` 실행으로 인한 Heartbeat 연결 누수
- **상황**: 사용자가 ScrollingFrame을 스크롤하다 멈추면 유휴 시간(0.1초) 뒤 바 높이를 정착시키기 위해 `task.delay(0.1, settle, version)`이 스케줄링된다. 이때 0.1초가 지나기 전에 화면 전환이나 탭 이동 등으로 해당 ScrollingFrame이 파괴(`Destroy`)되는 경우, `scroller.Destroying` 핸들러가 호출되어 `stopSettle()`과 `frame = nil`이 실행되지만 이미 예약된 `task.delay` 스레드는 취소되지 않는다.
- **결과**: 0.1초 뒤 `settle()`이 호출되면 `v == version` 검사를 통과하며, `frame == nil`임에도 불구하고 `settling = RunService.Heartbeat:Connect(...)`가 실행되어 파괴된 스크롤러에 대해 새 Heartbeat 연결이 생성되고 0.2초간 고아 애니메이션 루프가 돌아 엔진 자원이 누수된다.
- **위치**: `quad-roblox-material/src/AppBar/Scroll.luau:209`, `256-258`, `268-273`.
- **근거**: [실측](quad-roblox-material/src/AppBar/Scroll.luau:209, 268-273; 검증 프로브 실행: `( ulimit -v 4000000; timeout 600 ./quad-roblox-material/test/run.sh quad-roblox-material/test/spec.probe.luau )`, 출력: `[PROBE 1] Heartbeat connections after scroller destroyed and timer fired: 1 (base: 0)`, `[PROBE 1 CONFIRMED] Heartbeat leaked! Settle animation is running on destroyed scroller!`).
- **제안**: `scroller.Destroying` 핸들러에서 예약된 `task.delay` 스레드를 보관하여 `task.cancel`을 호출하거나, `settle()` 진입 시점에 `if frame == nil or settling ~= nil then return end`와 같이 호스트 파괴 여부를 즉시 검사하여 조기 반환하도록 방어 코드를 추가하는 것을 제안한다.

### 1.2 `TimePicker/ClockFace.luau`: 시간 다이얼 연속 탭 시 `task.delay` 타이머 경쟁으로 인한 조기 분(Minute) 전환
- **상황**: 12시간 모드 시계 다이얼에서 사용자가 시(Hour) 숫자를 탭하면 `task.delay(0.1, switchToMinute)`가 예약된다. 이때 사용자가 다른 시간으로 빠르게 연속 탭(예: 0.05초 간격으로 1시 탭 후 2시 탭)하는 경우.
- **결과**: 두 번째 탭 시 첫 번째 탭에서 예약된 `task.delay` 스레드를 취소하지 않는다. 따라서 첫 번째 탭 기준 0.1초(두 번째 탭 기준 불과 0.05~0.06초 후)에 첫 번째 타이머가 만료되어 `model.Selection:Set("Minute")`로 강제 전환해버려, 두 번째 탭에 대한 정상 대기 시간 없이 의도치 않게 조기 전환되는 경쟁 상태가 발생한다.
- **위치**: `quad-roblox-material/src/TimePicker/ClockFace.luau:225-231`, `288-290`.
- **근거**: [실측](quad-roblox-material/src/TimePicker/ClockFace.luau:288-290; 검증 프로브 실행: `( ulimit -v 4000000; timeout 600 ./quad-roblox-material/test/run.sh quad-roblox-material/test/spec.probe.luau )`, 출력: `[PROBE 2] Selection after 0.06s from 2nd tap: true`).
- **제안**: `autoSwitchThread: thread?` 변수를 두고 새 탭이 발생할 때마다 기존 스레드가 있으면 `task.cancel(autoSwitchThread)`로 취소한 뒤 새로 예약하도록 변경하는 것을 제안한다.

### 1.3 `AppBar/Scroll.luau`: 모바일 터치 스크롤 중 정지 시 강제 settle 오작동
- **상황**: 모바일 기기(Touch 입력)에서 사용자가 ScrollingFrame을 터치 스와이프로 스크롤하다가 손가락을 떼지 않고 화면에 댄 채 0.1초 이상 멈추고 있는 경우.
- **결과**: `settle()` 함수는 `Input.service():IsMouseButtonPressed(Enum.UserInputType.MouseButton1)`만 검사하고 `Enum.UserInputType.Touch`는 검사하지 않는다. 모바일 환경에서는 `IsMouseButtonPressed(MouseButton1)`이 항상 `false`이므로, 사용자가 여전히 손가락을 대고 있음에도 0.1초 뒤 강제로 정착(`settle`) 애니메이션이 시작되어 사용자가 짚고 있는 화면의 `CanvasPosition`을 강제로 스크롤시켜 버린다.
- **위치**: `quad-roblox-material/src/AppBar/Scroll.luau:183-188`.
- **근거**: [추정] (`AppBar/Scroll.luau:183` 코드상 마우스 왼쪽 버튼 상태만 확인하고 터치 입력 상태 확인 부재).
- **제안**: `Input.service()` 또는 터치 상태 트래커를 통해 현재 활성화된 터치(`Touch`)가 유지 중인지 확인하는 조건을 추가하거나, 스크롤러의 터치 제스처 추적 상태와 연동하는 것을 제안한다.

### 1.4 `Interaction.luau`: 시스템 제스처/인터럽트(`InputCancelled`) 미처리로 인한 드래그 상태 영구 고착 및 스크롤 잠금
- **상황**: 슬라이더, 바텀 시트, 사이드 시트, 내비게이션 드로어 등 `Interaction.drag`를 사용하는 컨트롤을 모바일/태블릿에서 드래그하던 중 시스템 제스처(홈 바 스와이프, 제어 센터 열기, 전화 수신 등)로 인해 엔진에서 입력 취소가 발생하는 경우.
- **결과**: Roblox 엔진은 시스템 인터럽트 발생 시 `InputEnded` 대신 `UserInputService.InputCancelled` 이벤트를 발생시킨다. 그러나 `Interaction.drag`는 `InputChanged`, `InputEnded`, `WindowFocusReleased` 3개만 연결하고 `InputCancelled`는 구독하지 않는다. 이로 인해 `finish()`가 영원히 호출되지 않아 `dragging` State가 영구히 `true`로 남고, `UserInputService` 연결 3개가 해제되지 않으며, `LockScroll = true`였던 경우 상위 `ScrollingFrame.ScrollingEnabled = false`가 복구되지 않아 화면 스크롤이 영구 잠식된다.
- **위치**: `quad-roblox-material/src/Interaction.luau:244-268`.
- **근거**: [추정] (Roblox 엔진 공식 `InputCancelled` 이벤트 사양 및 코드 분석).
- **제안**: `connCancelled = Input.service().InputCancelled:Connect(function(cancelled) ... finish(true) end)`를 추가하여 시스템 취소 시에도 안전하게 드래그 세션이 종료되도록 보완하는 것을 제안한다.

### 1.5 `Sheet/Slide.luau`: 애니메이션 중 `relayout` 발생 시 기존 타이머 미취소로 인한 조기 Settled 확정 불일치
- **상황**: 바텀 시트나 사이드 시트가 펼침/접힘 애니메이션(0.2~0.3초)으로 이동하는 도중 호스트 크기 변경이나 내용물 높이 변화로 인해 `relayout()`이 호출되면, `set(target, cfg.Motion(lastKind))`를 통해 새 트윈이 시작된다.
- **결과**: `relayout()`(178-205행)은 기존에 진행 중이던 `settleThread`를 취소하지 않는다. 그 결과 최초 애니메이션 시작 시 예약되었던 타이머가 만료되면서 `rec.Current:Set(value)`가 조기 실행되어, 화면상으로는 새 트윈이 여전히 이동 중인데도 상태 객체의 `CurrentValue`가 이미 목표 지점에 도달한 것으로 잘못 보고되는 불일치가 발생한다.
- **위치**: `quad-roblox-material/src/Sheet/Slide.luau:199-204`.
- **근거**: [추정] (`relayout()` 내부에서 `cancelSettle()` 호출 및 새 `scheduleSettle` 스케줄링 누락).
- **제안**: `relayout()`에서 `settleThread ~= nil`인 경우 `cancelSettle()`을 호출하고 새 모션의 시간에 맞춰 `scheduleSettle(rec.Target:Get(), motion.Time)`을 재설정하는 것을 제안한다.

### 1.6 `Overlay.luau`: 모듈 전역 `holds` 카운터 불일치 시 앱 전역 Escape/B 키 영구 차단 위험
- **상황**: `Overlay.holdDismiss()`를 호출한 뒤, 해당 핸들을 보유한 컴포넌트가 예외 발생 또는 unmount 과정에서 `release()`를 정상 호출하지 못하고 소멸하는 경우.
- **결과**: `holds`가 모듈 스코프의 단순 정수(`local holds = 0`)이므로, 단 한 번이라도 불일치가 발생하여 0보다 큰 값으로 남으면 앱 내의 모든 `Overlay` 인스턴스에서 Escape 키와 게임패드 ButtonB 키에 의한 닫기가 영구적으로 차단된다.
- **위치**: `quad-roblox-material/src/Overlay.luau:137`, `148-150`, `213-222`.
- **근거**: [추정] (모듈 레벨 공유 상태에 대한 인스턴스 생명주기 바인딩 부재).
- **제안**: 단순 정수 카운터 대신 토큰 객체 집합(`{ [any]: true }`)을 사용하거나, `HoldDismiss` 호출 시 인스턴스의 `Destroying`에 연동되어 자동 해제되도록 안전장치를 마련하는 것을 제안한다.

### 1.7 `Scaffold.luau`: 화면 높이가 극단적으로 작은 환경에서 `Body` 높이 음수 발생
- **상황**: 모바일 가로모드나 높이가 작은 위젯 창에서 대형 상단 바(`LargeTopAppBar`, 152px)와 하단 바(`BottomAppBar`, 80px)가 함께 사용되어 두 바의 높이 합이 화면 전체 높이를 초과하는 경우.
- **결과**: `Scaffold.luau:161-163`에서 `bodySize = UDim2.new(1, 0, 1, -(top:Get() + bottom:Get()))`로 계산되므로, `Body` 프레임의 Y 크기가 음수 Offset을 갖게 되어 내부 레이아웃이나 UIPadding 배치에서 계산 왜곡이 일어날 수 있다.
- **위치**: `quad-roblox-material/src/Scaffold.luau:161-163`.
- **근거**: [추정] (`Body` 프레임의 크기 계산 시 하한 클램프 누락).
- **제안**: `UDim2.new(1, 0, 0, math.max(0, screenHeight - top - bottom))` 방식이나 `UISizeConstraint` 등을 통해 음수 크기를 방어하는 것을 제안한다.

---

## 2. 비효율 및 반응형 최적화 과제

### 2.1 `Slider/Track.luau`: 이산 눈금(`ticks`)의 눈금당 4개 `:Compute` 생성 및 드래그 중 대량 중복 재계산
- **상황**: `Step`이 지정된 이산(discrete) 슬라이더 (예: `Step = 1, Min = 0, Max = 50`, 눈금 50개).
- **문제**: 눈금 1개당 `visible`, `active`, `color`, `transparency`라는 4개의 파생 State를 `:Compute`로 생성한다 (`Slider/Track.luau:428-446`). 눈금이 50개인 슬라이더 하나만으로 **200개의 State 객체와 200개의 클로저**가 생성된다. 또한 슬라이더 핸들을 드래그할 때 매 프레임 `f1, f2`가 변경되면, 50개 눈금의 `visible` 함수 50개가 매 프레임 전부 호출되어 `math.abs(tf - a) * span > GAP` 계산을 50번씩 반복 실행한다.
- **위치**: `quad-roblox-material/src/Slider/Track.luau:421-461`.
- **근거**: [추정] (코드 분석: 반복문 내부에서 눈금마다 독립된 4개 `:Compute` 바인딩).
- **제안**:
  1. `color`와 `transparency`는 `active`라는 동일한 불리언에서 파생되므로 분리할 필요 없이 `active` 상태 하나에서 인라인 결합한다.
  2. 개별 눈금마다 핸들 거리를 매 프레임 계산하는 대신, 핸들 주변 `GAP` 범위에 해당하는 활성 구간(인덱스 범위 `[minIdx, maxIdx]`)을 단일 State로 계산하여 눈금들이 참조하도록 구조를 단순화하면 반응형 그래프 평가 비용을 1/4 이하로 줄일 수 있다.

### 2.2 `NavigationRail/init.luau`: 아이템당 14개 이상의 개별 `:Compute` 및 애니메이션 중 일괄 재계산
- **상황**: 와이드 내비게이션 레일의 각 아이템(`dest`)마다 지오메트리 및 시각적 파생 속성들을 전부 별도의 `:Compute`로 분리함 (`geo`, `position`, `size`, `indicatorSize`, `pillPosition`, `pillSize`, `indicatorTransparency`, `iconPosition`, `labelPosition`, `labelTransparency`, `labelStart`, `labelFont`, `labelSize`, `labelLine`, `labelHeight`).
- **문제**: 레일이 펼쳐지거나 접힐 때(`p`가 0에서 1로 0.2초간 매 프레임 Heartbeat로 변함), 아이템 5개 기준 매 프레임 **70개의 State 재계산**이 일어난다. 특히 `labelStart` (불리언) 하나에서 단순히 `Typography`의 토큰 상수를 반환하는 `labelFont`, `labelSize`, `labelLine`, `labelHeight` 4개의 State가 각각 독립된 `:Compute`로 분리되어 있다.
- **위치**: `quad-roblox-material/src/NavigationRail/init.luau:229-289`.
- **근거**: [추정] (코드 분석: 단일 아이템 스코프 내 14개의 세분화된 파생 State 정의).
- **제안**: `labelStart`에 의존하는 4개 속성을 `geo` 레코드 단계에서 하나로 묶어 평가하거나, 텍스트 스타일 관련 속성을 묶음 State로 통합하여 파생 State 수와 의존성 전파 오버헤드를 줄이는 것을 제안한다.

### 2.3 `AppBar/Top.luau`: 스크롤 감속 곡선 계산 시 매 프레임 30회 이분 탐색(Bisection) 고정 실행
- **상황**: 상단 앱 바 스크롤 시 타이틀 투명도(`topTitleAlpha`)와 컨테이너 색상 블렌딩(`fastOutLinearIn`)을 계산할 때 3차 베지에 곡선을 평가함.
- **문제**: `bezier` 함수가 `for _ = 1, 30 do ... end`로 고정 30회의 이분 탐색을 수행한다 (`AppBar/Top.luau:127-134`). 매 스크롤 프레임마다 두 곡선에 대해 총 60회의 루프와 다항식 계산이 수행된다.
- **위치**: `quad-roblox-material/src/AppBar/Top.luau:115-137`.
- **근거**: [추정] (수학적 구현 분석: 이분 탐색 30회 반복 루프 확인).
- **제안**: 3차 베지에 역산은 뉴턴-랩슨(Newton-Raphson) 방법을 사용하면 3~4회의 반복만으로 1e-5 이하의 정밀도에 수렴하므로, 반복 횟수를 대폭 줄여 CPU 사이클을 아끼는 것을 제안한다.

### 2.4 `AppBar/Scroll.luau`: 스크롤 중 매 프레임 `task.delay` 스레드 생성 오버헤드
- **상황**: ScrollingFrame이 스크롤될 때마다 `version += 1; task.delay(IDLE, settle, version)`을 실행.
- **문제**: 사용자가 부드럽게 스크롤을 유지하는 동안 매 초 수십 개의 `task.delay` 스레드가 예약된다. `v ~= version` 조건으로 즉시 종료되기는 하나, 기존 스레드를 취소하지 않고 계속 새 스레드를 할당하므로 Luau 런타임 스레드 풀에 불필요한 가비지가 누적된다.
- **위치**: `quad-roblox-material/src/AppBar/Scroll.luau:256-258`.
- **근거**: [추정] (코드 분석: 스크롤 이벤트마다 무조건 새 `task.delay` 생성).
- **제안**: 이전 스레드를 변수에 저장해두고 스크롤 발생 시 `task.cancel(prevThread)`를 호출하는 디바운스 패턴으로 개선하는 것을 제안한다.

---

## 3. 더 나은 구현 및 구조 개선 제안

### 3.1 Quad 프레임워크 표준 기능 활용: `Util.negate`를 `q.Operator.Not`으로 교체
- **상황**: `Util.luau:83-87`의 `negate(state)` 함수가 `state:Compute(function(self) return not self:Get() end)`로 매번 새 익명 클로저를 생성하여 불리언 반전을 수행하고 있다.
- **개선 제안**: Quad 프레임워크(`docs/skills/quad-ui-dev/SKILL.md:112`)에 이미 내장된 최적화 연산자 `q.Operator.Not`을 활용하여 `state:Apply(q.Operator.Not)`으로 작성하면 불필요한 클로저 생성을 없애고 Quad 관례에 더 잘 부합한다.

### 3.2 `BottomSheet/Modal.luau`와 `SideSheet/Modal.luau`의 모달 생명주기 관리 공용화
- **상황**: `BottomSheet/Modal.luau`와 `SideSheet/Modal.luau`는 모두 `Overlay.default():Open(...)`을 호출하고 반환 핸들 `{ Close, IsOpen, Closing, SheetState }`를 제공하며, `OnGo("Hidden") -> dismiss()`, `OnClose -> Anchored.go("Hidden"); Slide.Detach()` 등 80% 이상의 오버레이 생명주기 배선 로직이 완전히 동일하다.
- **개선 제안**: `Sheet/Anchored.luau` 또는 `Sheet/` 패키지 수준에서 모달 시트 공용 래퍼를 정의하여 Overlay 등록, 스크림 연동, 닫힘 애니메이션과 상태 Detach 순서를 통합 관리하면, 중복 코드를 줄이고 생명주기 버그 발생 위험을 원천 차단할 수 있다.

### 3.3 `TimePicker/Modal.luau`: Dial/Input 뷰의 조건부(지연) 생성 전환
- **상황**: `TimePicker/Modal.luau:146-160`은 모달이 열릴 때 `Dial.build`와 `Input.build`를 둘 다 실행하여 최대 125개에 달하는 인스턴스를 한꺼번에 생성해두고, `Visible` 속성으로만 토글한다.
- **개선 제안**: 사용자는 보통 다이얼 모드 하나만 사용하고 확인을 누르는 경우가 많으므로, Quad의 `Slot` 또는 `Slot:Single`을 활용하여 현재 `mode`("Picker" vs "Input")에 해당하는 뷰만 지연 생성(Lazy)하도록 전환하면 모달 오픈 시 인스턴스 생성 비용을 대폭 절감(다이얼 모드 시 Input 인스턴스 24개 생성 생략)할 수 있다.

---

## 4. 가독성 및 정합성 (400줄 초과 파일, 주석 불일치)

### 4.1 400줄을 초과하는 대형 파일 분할 검토
- **대상 파일 목록**:
  1. `quad-roblox-material/src/Slider/Behavior.luau` (542줄): 단일 슬라이더와 범위 슬라이더, 키보드/D-pad 네비게이션, 포인터 연산이 한 파일에 혼재.
  2. `quad-roblox-material/src/Slider/Track.luau` (530줄): 트랙 조각 기하 계산, 틱 생성(`ticks`), 비대칭 캡/바디 합성(`outerPiece`), 스톱 인디케이터(`stop`) 등이 밀집.
  3. `quad-roblox-material/src/AppBar/Top.luau` (511줄): 단일 행 바 2종과 2단 행 바 4종 전체 빌더와 베지에 이징, Roboto 폰트 메트릭 계산이 밀집.
  4. `quad-roblox-material/src/Button/Split.luau` (483줄): Leading/Trailing 두 쪽의 비대칭 클립/페이스 합성, 리플, 포커스링, 옵티컬 센터링이 밀집.
  5. `quad-roblox-material/src/Overlay.luau` (524줄): 전역 Escape 스택, 선택 트랩, 스크림, 생명주기 관리가 밀집.
- **개선 제안**: 파일당 단일 책임 원칙에 따라 `Top.luau`를 `SingleRow.luau` / `TwoRows.luau`로 나누고, `Track.luau`에서 `Ticks.luau`를 분리하는 등의 모듈 분할을 제안한다.

### 4.2 `Badge.luau`: 주석과 실제 코드의 색상 토큰 불일치
- **상황**: `Badge.luau` 머리 주석 10-11행에는 `Large: ... error container, corner full`로 명시되어 있으나, 실제 코드 68행과 81행에서는 `BackgroundColor3 = theme.Color.Error`, `TextColor3 = theme.Color.OnError`로 일반 `Error` 토큰이 적용되어 있다.
- **위치**: `quad-roblox-material/src/Badge.luau:10-11` vs `68, 81`.
- **근거**: [실측](quad-roblox-material/src/Badge.luau:10-11, 68, 81).
- **제안**: Compose M3 정본(`BadgeTokens.LargeContainerColor = ColorRole.ErrorContainer`)에 맞춰 주석 또는 코드를 일치시키도록 정리를 제안한다.

---

## 5. 요약 및 권장 우선순위

| 우선순위 | 구분 | 내용 | 검증 방식 |
| :---: | :---: | :--- | :---: |
| **P0** | 버그 | `AppBar/Scroll.luau`: 스크롤러 파괴 후 `settle` 실행에 따른 Heartbeat 연결 누수 | [실측] 확인 완료 |
| **P1** | 버그 | `TimePicker/ClockFace.luau`: 다이얼 연속 탭 시 `task.delay` 타이머 경쟁 및 조기 전환 | [실측] 확인 완료 |
| **P1** | 버그 | `Interaction.luau`: 모바일 시스템 인터럽트(`InputCancelled`) 미처리로 인한 드래그/스크롤 영구 잠금 | [추정] |
| **P1** | 버그 | `AppBar/Scroll.luau`: 모바일 터치 스크롤 중 정지 시 강제 settle 오작동 | [추정] |
| **P2** | 버그 | `Sheet/Slide.luau`: 애니메이션 중 `relayout` 발생 시 기존 타이머 미취소로 인한 조기 Settled 확정 | [추정] |
| **P2** | 버그 | `Overlay.luau`: 모듈 레벨 `holds` 카운터 불일치 시 앱 전역 Escape 키 차단 위험 | [추정] |
| **P2** | 비효율 | `Slider/Track.luau`: 이산 눈금당 4개 `:Compute` 생성 및 드래그 중 대량 중복 재계산 | [추정] |
| **P2** | 비효율 | `NavigationRail/init.luau`: 아이템당 14개 이상의 세분화된 `:Compute` 재계산 부하 | [추정] |
| **P3** | 더 나은 구현 | `Util.negate`를 Quad 표준 `q.Operator.Not`으로 교체 | [추정] 제안 |
| **P3** | 더 나은 구현 | `BottomSheet`/`SideSheet` 모달 생명주기 배선 로직 공용화 | [추정] 제안 |
| **P3** | 가독성 | `AppBar/Top.luau`, `Slider/Track.luau` 등 500줄 초과 모듈 분할 및 `Badge.luau` 주석 정합성 | [실측] |
