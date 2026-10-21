### 1. 복사 대화상자

**선택: `OpenCopyDialog`**  
순위: `OpenCopyDialog` > `OpenTextCopy` > `OpenCopyText` > `CopyDialog` > `OpenClipboard`

기존 `OpenDialog`와 일관되고, 호출 즉시 열리는 동작도 드러납니다. `OpenClipboard`는 실제 클립보드 API를 제공한다고 오해하게 할 수 있습니다.

### 2. 다중 선택 규칙 모듈

- **모듈: `Selection`**  
  순위: `Selection` > `MultiSelect` > `SelectRules` > `Select`  
  선택 상태를 다루는 모듈이라는 점이 분명하고, `Select`보다 명사형 API로 자연스럽습니다.
- **모드: `"Replace" | "Toggle" | "Extend"`**  
  순위: `Replace` 계열 > `Single` 계열  
  `"Single"`은 단일 선택만 지원한다고 오해할 수 있습니다. `"Replace"`는 현재 클릭으로 선택을 대체한다는 동작을 설명합니다.
- **키 헬퍼: `modeFromKeys`**  
  순위: `modeFromKeys` > `keyMode` > `currentMode` > `modeNow`  
  키 상태를 읽어 모드를 산출한다는 역할이 잘 드러납니다.

### 3. 트리 평탄화 모듈

- **모듈: `TreeRows`**  
  순위: `TreeRows` > `VisibleRows` > `FlatTree` > `Flatten` > `TreeView`  
  트리에서 보이는 행을 만든다는 역할이 명확합니다. `TreeView`는 실제 UI 위젯으로 오해할 수 있습니다.
- **추가 자식 accessor: `Extra`**  
  순위: `Extra` > `MoreCount` > `Unloaded` > `Pending`  
  목록에 아직 포함되지 않은 추가 자식 수를 반환한다는 의미로 간결합니다.
- **placeholder 행 필드: `More`**  
  순위: `More` > `Remaining` > `Hidden`  
  추가로 표시할 수 있는 자식이 있음을 간결하게 나타냅니다.

### 4. `VirtualRows` 추가 기능

- **끝 따라가기 prop: `Follow`**  
  순위: `Follow` > `FollowEnd` > `StickToEnd` > `AutoScroll` > `Tail`  
  사용자가 위로 스크롤하면 멈추고 바닥으로 돌아오면 재개되는 동작을 자연스럽게 표현합니다. `AutoScroll`은 사용자가 위에 있어도 계속 스크롤할 것처럼 들릴 수 있습니다.
- **Y 좌표에서 행 인덱스 조회: `RowIndexAt`**  
  순위: `RowIndexAt` > `VirtualRowAt` > `IndexAtY` > `RowAt`  
  반환값이 행 객체가 아니라 인덱스임을 분명히 합니다.

### 5. 색상 선택기

- **순수 색상 모듈: `ColorModel`**  
  순위: `ColorModel` > `ColorUtil` > `ColorMath` > `Colors`  
  HSV·색상 상태·변환을 묶는 모듈에 어울립니다.
- **임베드 패널 위젯: `ColorPicker`**  
  순위: `ColorPicker` > `ColorEditor` > `ColorPanel` > `ColorPicker3`  
  개발자에게 익숙하고, 이미 있는 `InputColor3`와도 구별됩니다.
- **대화상자 열기 함수: `OpenColorPicker`**  
  순위: `OpenColorPicker` > `OpenColorDialog` > `PickColor`  
  기존 `Open…` 패턴을 따르며 열기 동작이 명확합니다.
- **팝업 억제 플래그: `NoPicker`**  
  순위: `NoPicker` > `NoPopup` > `NoColorPicker`  
  짧고 의미가 분명합니다. `NoPopup`은 다른 종류의 팝업까지 끈다는 뜻으로 읽힐 수 있습니다.