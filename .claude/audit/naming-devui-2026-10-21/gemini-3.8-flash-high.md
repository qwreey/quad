# devui 퍼블릭 API 네이밍 검토 보고서 (2개 명칭)

> **안내**: 본 보고서의 제안 사항은 최종 결정이 아니며, 도구 UI를 개발하는 Roblox 개발자 관점에서의 **"제안"**입니다. 최종 결정은 프로젝트 오너(사용자)가 수행합니다.
> 모든 항목의 주장은 코드베이스 실측(파일 및 줄 번호) 및 테스트 실행 결과에 근거하며, 경험적 판단 및 인지 모델 평가는 "추정"으로 명시하였습니다.

---

## 1. Window's menu-bar slot

### 1.1. 요약 및 선정 결과
- **선정 (Pick)**: `MenuBar`
- **우선순위 순위 (Ranked Shortlist)**:
  1. `MenuBar` (최선의 선택)
  2. `Header`
  3. `Toolbar`
  4. `Bar`
  5. `HeaderBar`
  6. `TopBar` ⚠️ **[Misleading 플래그]**

### 1.2. 선정 이유 (2가지)
1. **주 유스케이스와의 직관적 1:1 매칭 및 디스커버러빌리티 (실측 & 추정)**:
   - 실측: `quad-roblox-devui/src/Menu.luau:3-8`에 이미 `Devui.MenuBar` 위젯이 정의되어 있으며, 기존에는 `Children`의 첫 자식으로 넣어 수동 오프셋 계산을 해야 했던 문제를 해결하기 위해 이 슬롯이 도입되었습니다.
   - 추정: Roblox 도구 개발자에게 `Devui.Window({ MenuBar = Devui.MenuBar({ ... }) })` 구문은 모던 GUI 프레임워크(Flutter `Scaffold(appBar: ...)`, MUI/Chakra `<Modal header={<ModalHeader />} />`)에서 표준적으로 쓰이는 idiomatic 패턴으로 인식됩니다. 슬롯명과 기본 위젯명이 일치할 때 자동완성 탐색과 코드 가독성이 극대화됩니다.
2. **범용성의 수용력 (추정)**:
   - 툴바(아이콘 버튼 행 등)를 넣을 수 있다는 범용 슬롯 요구가 있으나, 슬롯명을 `Header`나 `Toolbar`로 일반화하면 정작 90% 이상의 주 사용례인 메뉴바를 넣을 때 `Toolbar = Devui.MenuBar(...)`처럼 심각한 인지적 위화감이 발생합니다.
   - 반면 `MenuBar` 슬롯에 툴바를 넣는 것은 ImGui(`BeginMenuBar()` 내부에 Button을 넣어 도구 모음처럼 구성) 개발자들에게 이미 널리 통용되는 관용적 패턴이며, 문서/타입 설명(`Slot<Instance>?`) 한 줄로 충분히 안내 가능합니다.

### 1.3. 오해를 부르는 이름 플래그 (Misleading Flag)
- ⚠️ **`TopBar`**:
  - **심각한 오해 소지**: Roblox 플랫폼 환경에서 `TopBar`/`Topbar`는 Roblox 엔진 공식 CoreGui 최상단 시스템 바(`TopbarEnabled`, 높이 36px/58px 영역)를 지칭하는 확고한 고유명사입니다.
  - 실측: `quad-roblox-devui/src/Window/init.luau:49-50`의 주석에서도 이미 `(below the Roblox top bar when the container reaches under it)`와 같이 엔진의 시스템 TopBar를 지칭하고 있습니다.
  - 또한 Window 컴포넌트 관점에서도 최상단은 `TitleBar`(`Title`)이며, 그 아래에 위치하는 슬롯을 `TopBar`라 부르는 것은 위치적으로도 부정확하여 Roblox 개발자에게 이중 혼란을 초래합니다.
- (참고) `Header` 역시 Window에 이미 `Title`과 `NoTitleBar` 플래그(`quad-roblox-devui/src/Window/init.luau:6, 18`)가 존재하는 구조상, "타이틀바 영역 전체를 커스텀하는 prop인가?"라는 오해를 부를 여지가 있습니다.

### 1.4. 위젯(`Devui.MenuBar`) 이름 변경/별칭 여부 판단
- **판단: Generic(`Devui.MenuBar`) 유지 제안 (Rename/Alias 반대)**
- **근거**:
  1. `Devui.MenuBar`는 Window 슬롯 전용이 아니라, 전체 화면 앱의 글로벌 메뉴바, 독(dock) 스트립, 커스텀 패널 등 어디서나 배치 가능한 독립 위젯입니다(`quad-roblox-devui/src/Menu.luau:6`의 `Slot<Instance>?` 지원).
  2. `WindowMenuBar`로 이름을 바꾸면 "Window 내부에서만 사용 가능한 위젯"이라는 인위적 제약 멘탈 모델을 사용자에게 강제하며, `Devui.` 네임스페이스 아래에서 불필요하게 이름이 길어집니다.
  3. ImGui(`BeginMenuBar`), Iris(`MenuBar`) 등 영감을 준 라이브러리들과의 어휘 일관성을 유지하는 것이 개발자 온보딩에 유리합니다(추정).

---

## 2. Button image

### 2.1. 요약 및 선정 결과
- **선정 (Pick)**: `Icon`
- **우선순위 순위 (Ranked Shortlist)**:
  1. `Icon` (최선의 선택)
  2. `IconImage`
  3. `Image` ⚠️ **[Misleading 플래그]**

### 2.2. 선정 이유 (2가지)
1. **디자인 시스템 및 스타일 토큰과의 완벽한 일치 (실측 & 추정)**:
   - 실측: `quad-roblox-devui/src/Style.luau:160-170, 441-450`에 내장 아이콘 이미지 맵이 `Icons` 타입(`Style.Icons.Close`, `Style.Icons.RightTriangle` 등)으로 정의되어 있습니다.
   - 추정: `Devui.Button({ Icon = style.Icons.Close, Text = "Close" })` 또는 `Devui.Button({ Icon = "rbxassetid://..." })`와 같이 호출할 때 어휘가 완벽히 일치합니다. 모던 UI 키트(Material, Chakra, Tailwind 등)에서도 버튼 내부의 장식/심볼 이미지는 예외 없이 `Icon`으로 명명됩니다.
2. **Window의 `Icon` prop과의 시너지 (실측 & 추정)**:
   - 실측: `quad-roblox-devui/src/Window/init.luau:24`에 `Icon: string?, -- the collapsed icon's image`가 이미 존재합니다.
   - 추정: Window의 `Icon`과 Button의 `Icon`은 "해당 요소를 시각적으로 대표하는 아이콘 이미지 ID"라는 본질적 개념을 공유합니다. 서로 다른 위젯의 prop이므로 네임 충돌이 없으며, 오히려 devui 전반에서 "작은 심볼 이미지 = `Icon`"이라는 일관된 prop 컨벤션을 형성합니다.

### 2.3. 오해를 부르는 이름 플래그 (Misleading Flag)
- ⚠️ **`Image`**:
  - **오해 소지**: Roblox 엔진에서 `ImageButton.Image`나 `ImageLabel.Image`는 컴포넌트 전체를 채우는 텍스처/배경 스킨 프로퍼티입니다.
  - 실측: `quad-roblox-devui/src/Button.luau:19, 26`을 보면 `Devui.Button`은 엔진의 `TextButton`을 기반으로 만들어지며 자체 배경/테두리 스타일링을 처리합니다.
  - 만약 Button prop에 `Image`가 있다면, Roblox 개발자는 "버튼의 배경 텍스처를 덮어쓰는 기능"으로 오인할 가능성이 매우 높습니다(추정). 실제 기능은 패딩 내부의 텍스트 옆(또는 단독 사각 버튼)에 들어가는 "아이콘 심볼"이므로 `Image`라는 이름은 기능의 본질을 흐립니다.
- (참고) `IconImage`는 misleading은 아니지만, 이미 `Icon`이 string(이미지 ID)을 받는 시점에서 불필요하게 합성되어 장황하며(redundant) 관례상 잘 쓰이지 않습니다.

---

## 3. 검증 환경 실측 기록

- **테스트 실행 명령**:
  ```bash
  ( ulimit -v 4000000; timeout 600 ./scripts/test.sh )
  ```
- **실측 결과**:
  - 전체 테스트 스위트 정상 통과 (Exit Code: 0)
  - Doc-coverage: 212/212 통과
  - Surface-gate: NEG 27/27 통과
  - Error-codes: 272 IDs 통과
