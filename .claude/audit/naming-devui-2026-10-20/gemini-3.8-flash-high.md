# devui 퍼블릭 API 네이밍 검토 보고서

본 보고서는 Roblox 개발자가 도구 UI를 작성하는 관점에서 devui의 퍼블릭 API 명칭을 검토한 결과입니다. 최종 결정 권한은 사용자에게 있으며, 본 문서의 모든 대안 및 수정 의견은 사용자의 판단을 돕기 위한 **제안**입니다.

---

## 1. Button on-state (`Button` / `SmallButton`)
- **verdict**: change
- **best name**: `Toggled`
  - 제안 이유: 버튼에는 체크마크가 없으므로 `Checked`는 체크 아이콘 렌더링에 대한 오해를 부르며, `Toggled`는 기존 `Disabled`와 동일한 형용사형태로 토글 버튼의 온(on) 상태를 가장 명확히 전달함 [제안].
- **alternatives**:
  - `Checked`: kit 내 `MenuToggle`의 제어형 프로퍼티(`Checked: State<boolean>`, `quad-roblox-devui/src/Menu.luau:8`) 및 WPF(`ToggleButton.IsChecked`) 선례와 일치함 [추정].
  - `Selected`: 칩/필터 UI 관례에 부합하나 Roblox 엔진의 `GuiButton.Selected`(게임패드 포커스) 프로퍼티와 직접 명칭 충돌함 [추정].
- **confusion risk**: **Medium** (기존 제안 `Checked` 유지 시) / **Low** (`Toggled` 채택 시)
  - `Checked`는 Roblox 엔진 프로퍼티 충돌은 없으나(low), 사용자가 `Checkbox`처럼 체크마크가 표시될 것으로 기대하게 됨.
  - 후보 중 `Active`는 Roblox의 핵심 입력 차단 속성인 `GuiObject.Active`와 정면 충돌하여 극히 위험함(high) [추정].

---

## 2. Tab bar without pages (`TabBar`)
- **verdict**: keep
- **best name**: `NoPages`
  - 제안 이유: `Window`의 `NoTitleBar`·`NoResize`(`quad-roblox-devui/src/Window/init.luau:82-86`)와 동일하게 내부 하위 구조체(`Pages` Frame, `quad-roblox-devui/src/Tab.luau:184`) 생성을 생략하는 `No<부위>` 네거티브 플래그 관례를 정확히 계승함 [실측/추정].
- **alternatives**:
  - `BarOnly`: 긍정형 명칭으로 "탭 버튼 바만 렌더링한다"는 컴포넌트 동작을 직관적으로 설명함 [제안].
  - `NoPageContainer`: 생략되는 대상이 탭 데이터가 아닌 페이지 컨테이너 프레임임을 구체적으로 한정함 [제안].
- **confusion risk**: **Low**
  - Roblox 엔진 프로퍼티나 ImGui 탭바 플래그와 명칭 충돌이 없으며, devui의 기존 `Window` 정적 플래그 패턴과 자연스럽게 부합함 [추정].

---

## 3. Tab corner radius token (`Style.Metrics`)
- **verdict**: keep
- **best name**: `TabRounding`
  - 제안 이유: Dear ImGui의 공식 스타일 변수(`ImGuiStyleVar_TabRounding`)와 100% 일치하며, kit 내 기존 `<Target>Rounding` 토큰 체계(`WindowRounding`, `PopupRounding`, `GrabRounding`, `FrameRounding`, `quad-roblox-devui/src/Style.luau:147-153`) 및 색상 토큰(`Tab`, `TabActive`)과 완벽히 부합함 [실측/추정].
- **alternatives**:
  - `TabBarRounding`: 위젯 공개 명칭인 `TabBar`에 맞춘 명칭이나 기존 색상 토큰(`Tab`)의 접두사 규칙과 어긋남 [제안].
  - `TabButtonRounding`: 둥글기가 적용되는 대상이 탭 바 전체가 아닌 개별 탭 버튼임을 정확히 지칭함 [제안].
- **confusion risk**: **Low**
  - Roblox 엔진에는 `UICorner`만 있어 스타일 토큰 충돌이 없고, ImGui 및 kit 자체 토큰 체계와 완벽히 정합함 [추정].

---

## 4. Per-frame drag callback (`Interaction.drag`)
- **verdict**: change
- **best name**: `OnFrame`
  - 제안 이유: `OnBegin`·`OnMove`·`OnEnd`(`quad-roblox-devui/src/Interaction.luau:64-66`)와의 `On<시점/이벤트>` 명명 일관성을 지키면서 매 프레임 호출된다는 주기를 가장 직관적으로 드러냄 [제안].
- **alternatives**:
  - `OnTick`: 범용 게임 루프 어휘를 따르나 Roblox의 폐기 예정(deprecated) 유닉스 타임 함수 `tick()` 및 고정 주기 타이머와 어휘가 겹침 [추정].
  - `OnHeartbeat`: Roblox 개발자에게 가장 익숙한 프레임 이벤트(`RunService.Heartbeat`) 어휘이나 내부 구현 바인딩에 종속된 인상을 줌 [제안].
- **confusion risk**: **Medium** (기존 제안 `OnTick` 유지 시) / **Low** (`OnFrame` 채택 시)
  - Roblox 개발자에게 `tick`은 프레임 렌더 루프가 아닌 `tick()` 시간 함수나 서버 틱으로 먼저 연상되어 혼란을 유발할 수 있음 [추정]. `WhileDragging`은 `On*` 일관성을 깨뜨림 [추정].

---

## 5. Already implemented, sanity check

### 5a. `InputText` prop `Focused: Source<boolean>?`
- **verdict**: keep
- **best name**: `Focused`
  - 제안 이유: `Disabled`, `Open`, `Selected` 등 kit 전반의 형용사형 상태 프로퍼티 관례에 정확히 부합하며, `Source<boolean>`을 통한 양방향(Two-way) 바인딩 의도가 자연스러움(`quad-roblox-devui/src/Inputs/InputText.luau:14-15, 93-124`) [실측/추정].
- **alternatives**:
  - `IsFocused`: Roblox의 `TextBox:IsFocused()` 메서드와 어휘가 일치하나 kit 내의 `Is-` 배제 관례와 어긋남 [추정].
  - `CaptureFocus`: 능동적인 포커스 획득 명령 의도는 강조되나 양방향 상태 동기화라는 실제 성격을 담지 못함 [제안].
- **confusion risk**: **Medium**
  - Roblox의 `TextBox.Focused`는 Signal(이벤트)이나 kit 내 이벤트 콜백은 `On*`(`OnChange` 등)을 쓰므로 구분 가능함. 단, `Window.Focused`는 출력 전용(Output-only)인 반면 `InputText.Focused`는 양방향(Two-way)이라는 위젯 간 의미론적 차이가 존재함 [실측/추정].

### 5b. `Window` prop `ContentSize: Source<Vector2>?`
- **verdict**: change
- **best name**: `ViewportSize`
  - 제안 이유: Roblox 엔진에서 `ContentSize`(`UIListLayout.AbsoluteContentSize`)는 예외 없이 "자식 요소들의 누적 바운딩 크기"를 의미하므로, 스크롤바와 패딩을 제외한 가시 영역(`quad-roblox-devui/src/Window/init.luau:260-270`)에 이 이름을 붙이는 것은 정반대의 의미를 주어 심각한 혼동을 야기함 [실측/추정].
- **alternatives**:
  - `AvailableSize`: ImGui의 `GetContentRegionAvail` 개념을 선언형 프로퍼티로 간결하게 축약한 명칭 [제안].
  - `ContentAreaSize`: 콘텐츠 자체가 아니라 콘텐츠가 배치될 수 있는 '영역(Area)'의 크기임을 명시하여 혼동을 줄임 [제안].
- **confusion risk**: **High**
  - Roblox 개발자의 기존 멘탈 모델(`AbsoluteContentSize` = 캔버스 크기 계산용 콘텐츠 크기)과 정면으로 충돌하므로 반드시 개명이 권장됨 [추정].

### 5c. `VirtualRows` widget (`Count`, `Row`, `RowHeight`, `Overscan`, `ScrollTo`)
- **verdict**: keep (위젯 명칭 유지, 단 `ScrollTo`는 `ScrollToIndex` 또는 `ScrollToRow`로 변경 제안)
- **best name**: `VirtualRows`
  - 제안 이유: 고정 높이 가상화 행 풀링이라는 구체적 동작 모델(`quad-roblox-devui/src/VirtualRows.luau:3-7`)을 솔직하고 정확하게 표현함 [실측/추정].
- **alternatives**:
  - `VirtualList`: 현대 웹/모바일 가상화 라이브러리(react-window 등)에서 가장 널리 통용되는 대중적 명칭 [추정].
  - `VirtualizedList`: 가상화된 리스트임을 더 격식 있게 표현하는 명칭 [제안].
- **confusion risk**: **Low ~ Medium**
  - `VirtualRows` 자체의 혼동 위험은 낮음. 단, `ScrollTo` prop은 Roblox `ScrollingFrame`의 픽셀 좌표(`CanvasPosition`)와 달리 행 인덱스를 받는 점, 그리고 위젯이 현재 위치를 역으로 써주지 않는 "단방향 명령용 Source"라는 점에서 혼동 위험이 있으므로 `ScrollToIndex` 또는 `ScrollToRow`로 명시하는 것을 제안함 [실측/추정].

---

## 6. 세트 전체의 일관성 검토 (종합 평가)
1. `Source<T>` 프로퍼티의 방향성(양방향, 출력 전용, 명령 전용)이 이름에서 전혀 드러나지 않아 위젯마다 계약이 파편화되어 있습니다 (`InputText.Focused`는 양방향, `Window.Focused`는 출력 전용, `VirtualRows.ScrollTo`는 명령 전용) [추정].
2. 활성/선택 상태를 나타내는 불리언 어휘가 위젯마다 제각각입니다 (`Button.Checked` 제안 vs `Selectable.Selected` vs `Checkbox.Value` vs `Window.Open`) [추정].
3. ImGui 개념 직역 과정에서 Roblox 엔진의 지배적 어휘와 정면 충돌하는 지점이 발생합니다 (`Window.ContentSize`는 Roblox `AbsoluteContentSize`와 반대 의미, `OnTick`은 Roblox 프레임 루프 어휘와 불일치) [추정].
