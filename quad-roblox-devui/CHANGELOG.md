# Changelog — quad-roblox-devui

이 킷의 소비자가 겪는 변화를 적습니다. 형식은 루트 `CHANGELOG.md`와 같습니다(Added / Changed / Deprecated / Removed / Fixed, 호환이 깨지면 **BREAKING**과 옮기는 법 한 줄).

**아직 버전이 없습니다.** 킷은 게시 전이라 버전을 매기지 않고 `[Unreleased]`에 쌓습니다 — 버전·패키지화는 따로 정합니다. 이 파일을 만든 2026-10-20 이전의 변화는 git 기록에 있습니다.

## [Unreleased]

### Added

- `Window`의 `Key: string?`(창의 신원 — 한 `WindowManager` 안에서 유일, 겹치면 `Devui.Window:` 에러)·`Kind: string?`(창의 종류, 생략하면 `Key`)·`Icon: string?`(접힌 창 아이콘의 이미지, 없으면 제목 첫 글자).
- `WindowManager:ExportLayout(): WindowLayout`·`:ImportLayout(layout, factories?)`·`:ExportWindow(key): WindowState?`·`:ImportWindow(key, state)`와 출력 `WindowManager.Layout: State<WindowLayout>`, 타입 `Devui.WindowLayout`·`Devui.WindowState` — 키 있는 창의 열림·접힘·위치·크기를 JSON으로 바꿀 수 있는 평범한 표로 내주고 받습니다(저장은 앱 몫, 창 내용은 저장하지 않음). 불러오기는 언제 불러도 되고, 아직 없는 키는 그 창이 등록될 때 적용되며, 배치에 없는 창은 그대로 둡니다. `factories`(`Kind` → `function(key)`)는 저장 때 열려 있었고 아직 등록되지 않은 키에만 불립니다. `Floating`의 차례가 키 있는 창들의 겹침 순서(아래에서 위)라서 불러온 뒤 창을 어떤 차례로 만들어도 저장된 대로 쌓입니다. 형식은 README의 "창 배치 저장" 절.
- `Window`의 `OnCloseRequest: (() -> ())?` — 주면 × 단추가 이 함수만 부르고 `Open`을 건드리지 않습니다(앱이 저장할지 묻고 닫는 경로). 주지 않으면 지금처럼 닫힙니다.
- `WindowManager:ForgetWindow(key)` — 키를 배치에서 지웁니다(앱이 창을 정말로 닫을 때). 대기 키는 바로, 살아 있는 창의 키는 그 창이 사라질 때 지우고, 같은 키로 다시 만든 창은 처음부터 시작합니다.
- `Window` 가장자리 붙이기 — 제목줄을 끌어 컨테이너의 왼쪽·오른쪽 끝에 놓으면(미리보기가 보임 — 창과 같은 컨테이너에 그려져 Overlay 층이 없어도 보입니다) 그쪽에 붙습니다. 화면 끝에 세로 전체 띠(`WindowDockStrip`)가 생기고 그 안쪽에 패널이 놓이며, 같은 컨테이너의 떠 있는 창은 띠에 들어가지 못합니다. 띠를 누르면 접힌 패널을 펼치고, 포커스 없는 패널에 포커스를 주고, 포커스 있는 패널을 접습니다. 패널 안쪽 가장자리 손잡이(`WindowDockResize`)로 너비를 바꾸고(컨테이너 너비의 절반까지), 제목줄을 끌어 떼며, 컨테이너가 상단바 밑까지 덮으면 패널이 상단바 아래에서 시작합니다. 한 가장자리에 열린 창(또는 탭 묶음) 하나 — 차 있는 끝에 놓으면 붙지 않고 그 묶음에 탭으로 합쳐집니다(아래 탭 묶음 항목), 닫았다 다시 열면 그쪽으로 돌아갑니다(그 사이 차지됐으면 떠서 열림). 붙어 있는 동안 `Position`·`Size`는 떠 있을 때의 사각형만 기억합니다. 새 prop `NoDock: boolean?`(끌어서는 붙지 않음). README의 "가장자리 붙이기" 절.
- `WindowLayout`의 `Left`·`Right`(선택, `{ Width, Collapsed, Node, Position?, Size? }` — 붙은 창, 떼면 돌아갈 사각형 포함)와 `WindowState`의 `Dock: ("Left" | "Right")?`·`DockWidth: number?`. `Version`은 1 그대로이고 필드만 더했습니다. 붙은 창의 겹침 순서는 저장하지 않으며 불러오면 떠 있는 창들 아래에서 시작합니다.
- `Window` 탭 묶음 — 제목줄을 끌어 같은 관리자·같은 컨테이너의 다른 창의 제목줄(탭 자리에 끼움)이나 가운데(맨 끝 탭)에 놓으면(미리보기가 대상 전체를 덮음) 두 창이 사각형 하나·탭 줄 하나의 묶음이 되고 고른 창의 내용만 보입니다. 탭 줄은 열린 창이 둘 이상일 때 제목줄 자리에 나오고(접기 화살표 + 탭 `WindowTab`), 탭을 누르면 고르고, 줄 안에서 끌면 순서를 바꾸고, 줄 밖으로 끌면 떼어 내 자기 크기로 띄웁니다(끌기가 이어짐). 탭을 닫으면 자리를 기억한 채 숨고 `Open:Set(true)`로 같은 자리에 돌아오며, 접기는 묶음 단위, 묶음은 한 덩이로 쌓입니다. 묶인 동안 창의 `Position`·`Size`는 합치기 전 사각형을 기억만 하고, 창이 하나만 남으면(닫힌 창·대기 키·키 없는 창도 셈) 그 창이 묶음 자리를 가져갑니다. 이미 묶음이 붙은 화면 끝에 놓으면 그 묶음에 합쳐집니다(빈 끝은 지금처럼 붙음, 접혀 띠만 남은 묶음은 대상이 아님). 판정은 포인터 아래 맨 위 창이 정합니다(합칠 수 없는 창이 위에 있으면 아무 일도 없음). 사각형 가장자리의 20% 띠는 나중의 분할 자리라 아무 일도 없습니다. 도크 너비는 묶음이 붙어 있는 동안만 공유되고, 떠 있는 묶음의 창들은 각자 기억하는 도크 너비를 지킵니다. `NoDock`은 가장자리 붙이기만 막고 탭 합치기는 막지 않습니다. README의 "탭 묶음" 절.
- `WindowLayout`의 노드가 탭 여럿(`Node.Tabs`, `Selected`는 그중 하나 — 닫힌 탭은 `Windows[key].Open = false`로 남음)을 담고, `Windows[key]`에 선택 필드 `Position`·`Size`(묶인 창의 합치기 전 사각형 — 탭이 둘 이상 실리는 노드에서 그 사각형이 있는 창에만 씀, 불러오면 창의 Source에 써 넣음)가 생겼습니다. `Version`은 1 그대로이고 필드만 더했습니다. 아직 없는 키는 그 창이 등록될 때 저장된 탭 자리로 들어갑니다. 제목줄 없는 창이나 다른 컨테이너의 창은 탭이 되지 않고 평범한 창으로 놓입니다. `ImportWindow`는 묶인 창을 먼저 묶음에서 빼고, `ExportWindow`는 묶음 소속을 싣지 않습니다.
- `InputText`·`InputNum`·`DragNum`의 `FieldSpread`, `SliderNum`의 `TrackSpread` — 안쪽 상자·트랙에 Ref·`q.OnEvent`·키 묶음을 펼쳐 넣는 자리(`q.Spread "TextBox" {…}` 등). 기본값 경로인 `FieldModifier`/`TrackModifier`는 그대로입니다.

### Changed

- `WindowManager:ImportLayout`·`ImportWindow`가 닫혀 있던 창을 열 때 그 창에 포커스를 주거나 앞으로 올리지 않습니다(지금까지는 다시 연 창처럼 포커스를 받았음) — 불러오기는 어느 창도 앞으로 데려오지 않는다는 규칙대로입니다.

- `Window` 끌기 미리보기(`WindowDockPreview`)가 `NoDock` 창에도 만들어집니다(탭 합치기 미리보기에 씀) — `NoMove`·`NoTitleBar` 창에만 없습니다. 이미 열린 창이 붙은 화면 끝으로 끌면 지금까지는 아무 일도 없었지만 이제 그 창에 탭으로 합쳐집니다. 창마다 데코레이션 부품 `WindowTab`이 하나 늘었습니다(묶이지 않은 동안 숨김).

- **BREAKING** (타입) `WindowState`의 `Position`·`Size`가 선택(`{ number }?`)이 됐습니다 — 사각형 없이 저장된 가장자리 묶음을 읽은 대기 키, 자기 사각형 없이 묶음에 든 대기 키를 위해서입니다. `ExportWindow`는 살아 있는 창이면 여전히 늘 채우고, `ImportWindow`에서 생략하면 창의 Source를 건드리지 않습니다. 옮기는 법: `state.Position[2]`처럼 바로 읽던 코드는 nil을 먼저 확인하세요(`local p = state.Position; if p then … end`).
- **BREAKING** quad 3.4.0 표면으로 옮겼습니다 — 킷은 `q.Elem`·`q.Modifier "Class"`·`q.Spread "Class"`를 쓰고 quad 3.3의 `q.Declaration`에서는 돌지 않습니다.
- **BREAKING** `Modifier`·`FieldModifier`·`TrackModifier` 같은 Modifier 자리의 타입이 `ModifierInto<Class>`(메소드 없는 마커)입니다 — 직접 만든 커스텀 클래스 Modifier는 넘기는 쪽에서 `:AsTextButton()`처럼 내려서 넘기세요.
- **BREAKING** `Window`의 인스턴스 트리가 바뀌었습니다 — 돌려받는 루트(`Name = "Window"`)는 이제 내용 표면(스크롤 영역)만이고, 창틀(배경·테두리)·제목줄·크기 손잡이는 `WindowManager`가 그 루트와 **같은 부모의 형제**(`WindowDecoration`·`WindowResizeGrip`)로 만들어 루트의 `Parent`를 따라 옮기고 루트와 함께 지웁니다. 루트는 제목줄 아래에 놓이고(`Position`·`Size`는 그대로 제목줄을 포함한 바깥 사각형), 접으면 루트가 숨으며(접힌 모양은 아래 항목), `Modifier`는 그 표면 루트에 붙습니다(그래서 `AnchorPoint`·`Position`·`Size` 같은 배치 키를 `Modifier`로 주면 표면만 창틀에서 어긋납니다 — 창의 자리는 `Position`·`Size` prop으로). 창 하나가 `ZIndex` 세 칸(창틀·표면·손잡이)을 쓰므로 Overlay 층 아래 창 상한이 999개에서 333개로 줄었습니다. 포커스 넘김은 루트의 `Visible`이 아니라 창의 `Open`을 따릅니다(접기는 닫기가 아님). 옮기는 법: 루트를 놓는 코드는 그대로 두고, 루트 안에서 `TitleBar`·`ResizeGrip`·`ClickSink`를 찾던 코드는 루트의 형제 쪽을 보세요 — `WindowManager`를 직접 흉내 낸 표(`Register`만 있는 표)는 더는 `Manager`로 넘길 수 없습니다.
- **BREAKING** (겉모습) 접힌 `Window`가 제목줄만 남지 않고 **작은 정사각 아이콘**이 됩니다 — `WindowManager`가 창의 `Position`(바깥 사각형 왼쪽 위)에 그리는 `WindowIcon`(루트의 형제)이고, `Icon` 이미지나 제목 첫 글자를 보여 줍니다. 아이콘을 누르면 펼쳐지고(`Collapsed`가 `false`), 끌면 창이 옮겨집니다(`Position`에 씀; 몇 픽셀 안의 움직임은 누름). 접힌 동안 창틀·제목줄·크기 손잡이·표면이 모두 숨습니다. 옮기는 법: 접힌 창의 제목줄을 찾던 코드는 `WindowIcon`을 보세요.
- 잘못된 prop·인자 에러가 `Devui.<컴포넌트>: <내용>` 한 형식입니다(예: `Devui.MenuToggle: give …`). 검사가 컴포넌트 몇 단계 안쪽에 있어도 에러는 그 컴포넌트를 부른 줄을 가리키고, 컴포넌트 안에서 quad가 내는 에러(잘못된 `Modifier` 등)도 이제 킷 안쪽 줄이 아니라 그 컴포넌트를 부른 줄을 가리킵니다. 에러 문구는 계약이 아니니 문구로 분기하지 마세요.

### Removed

- **BREAKING** `Style`의 `TitleBgCollapsed` 색·투명도 토큰(어두운·밝은 테마 둘 다) — 접힌 창이 제목줄 대신 아이콘이 되면서 쓰는 곳이 없어졌습니다. 옮기는 법: `Style.new`의 덮어쓰기와 `ColorOf("TitleBgCollapsed")`·`AlphaOf("TitleBgCollapsed")`에서 이 이름을 지우세요(남아 있으면 모르는 토큰 에러).
