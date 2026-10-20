# Changelog — quad-roblox-devui

이 킷의 소비자가 겪는 변화를 적습니다. 형식은 루트 `CHANGELOG.md`와 같습니다(Added / Changed / Deprecated / Removed / Fixed, 호환이 깨지면 **BREAKING**과 옮기는 법 한 줄).

**아직 버전이 없습니다.** 킷은 게시 전이라 버전을 매기지 않고 `[Unreleased]`에 쌓습니다 — 버전·패키지화는 따로 정합니다. 이 파일을 만든 2026-10-20 이전의 변화는 git 기록에 있습니다.

## [Unreleased]

### Added

- `Window`의 `Key: string?`(창의 신원 — 한 `WindowManager` 안에서 유일, 겹치면 `Devui.Window:` 에러)·`Kind: string?`(창의 종류, 생략하면 `Key`)·`Icon: string?`(접힌 창 아이콘의 이미지, 없으면 제목 첫 글자).
- `WindowManager:ExportLayout(): WindowLayout`·`:ImportLayout(layout, factories?)`·`:ExportWindow(key): WindowState?`·`:ImportWindow(key, state)`와 출력 `WindowManager.Layout: State<WindowLayout>`, 타입 `Devui.WindowLayout`·`Devui.WindowState` — 키 있는 창의 열림·접힘·위치·크기를 JSON으로 바꿀 수 있는 평범한 표로 내주고 받습니다(저장은 앱 몫, 창 내용은 저장하지 않음). 불러오기는 언제 불러도 되고, 아직 없는 키는 그 창이 등록될 때 적용되며, 배치에 없는 창은 그대로 둡니다. `factories`(`Kind` → `function(key)`)는 저장 때 열려 있었고 아직 등록되지 않은 키에만 불립니다. `Floating`의 차례가 키 있는 창들의 겹침 순서(아래에서 위)라서 불러온 뒤 창을 어떤 차례로 만들어도 저장된 대로 쌓입니다. 형식은 README의 "창 배치 저장" 절.
- `Window`의 `OnCloseRequest: (() -> ())?` — 주면 × 단추가 이 함수만 부르고 `Open`을 건드리지 않습니다(앱이 저장할지 묻고 닫는 경로). 주지 않으면 지금처럼 닫힙니다.
- `WindowManager:ForgetWindow(key)` — 키를 배치에서 지웁니다(앱이 창을 정말로 닫을 때). 대기 키는 바로, 살아 있는 창의 키는 그 창이 사라질 때 지우고, 같은 키로 다시 만든 창은 처음부터 시작합니다.
- `InputText`·`InputNum`·`DragNum`의 `FieldSpread`, `SliderNum`의 `TrackSpread` — 안쪽 상자·트랙에 Ref·`q.OnEvent`·키 묶음을 펼쳐 넣는 자리(`q.Spread "TextBox" {…}` 등). 기본값 경로인 `FieldModifier`/`TrackModifier`는 그대로입니다.

### Changed

- **BREAKING** quad 3.4.0 표면으로 옮겼습니다 — 킷은 `q.Elem`·`q.Modifier "Class"`·`q.Spread "Class"`를 쓰고 quad 3.3의 `q.Declaration`에서는 돌지 않습니다.
- **BREAKING** `Modifier`·`FieldModifier`·`TrackModifier` 같은 Modifier 자리의 타입이 `ModifierInto<Class>`(메소드 없는 마커)입니다 — 직접 만든 커스텀 클래스 Modifier는 넘기는 쪽에서 `:AsTextButton()`처럼 내려서 넘기세요.
- **BREAKING** `Window`의 인스턴스 트리가 바뀌었습니다 — 돌려받는 루트(`Name = "Window"`)는 이제 내용 표면(스크롤 영역)만이고, 창틀(배경·테두리)·제목줄·크기 손잡이는 `WindowManager`가 그 루트와 **같은 부모의 형제**(`WindowDecoration`·`WindowResizeGrip`)로 만들어 루트의 `Parent`를 따라 옮기고 루트와 함께 지웁니다. 루트는 제목줄 아래에 놓이고(`Position`·`Size`는 그대로 제목줄을 포함한 바깥 사각형), 접으면 루트가 숨으며(접힌 모양은 아래 항목), `Modifier`는 그 표면 루트에 붙습니다(그래서 `AnchorPoint`·`Position`·`Size` 같은 배치 키를 `Modifier`로 주면 표면만 창틀에서 어긋납니다 — 창의 자리는 `Position`·`Size` prop으로). 창 하나가 `ZIndex` 세 칸(창틀·표면·손잡이)을 쓰므로 Overlay 층 아래 창 상한이 999개에서 333개로 줄었습니다. 포커스 넘김은 루트의 `Visible`이 아니라 창의 `Open`을 따릅니다(접기는 닫기가 아님). 옮기는 법: 루트를 놓는 코드는 그대로 두고, 루트 안에서 `TitleBar`·`ResizeGrip`·`ClickSink`를 찾던 코드는 루트의 형제 쪽을 보세요 — `WindowManager`를 직접 흉내 낸 표(`Register`만 있는 표)는 더는 `Manager`로 넘길 수 없습니다.
- **BREAKING** (겉모습) 접힌 `Window`가 제목줄만 남지 않고 **작은 정사각 아이콘**이 됩니다 — `WindowManager`가 창의 `Position`(바깥 사각형 왼쪽 위)에 그리는 `WindowIcon`(루트의 형제)이고, `Icon` 이미지나 제목 첫 글자를 보여 줍니다. 아이콘을 누르면 펼쳐지고(`Collapsed`가 `false`), 끌면 창이 옮겨집니다(`Position`에 씀; 몇 픽셀 안의 움직임은 누름). 접힌 동안 창틀·제목줄·크기 손잡이·표면이 모두 숨습니다. 옮기는 법: 접힌 창의 제목줄을 찾던 코드는 `WindowIcon`을 보세요.
- 잘못된 prop·인자 에러가 `Devui.<컴포넌트>: <내용>` 한 형식입니다(예: `Devui.MenuToggle: give …`). 검사가 컴포넌트 몇 단계 안쪽에 있어도 에러는 그 컴포넌트를 부른 줄을 가리키고, 컴포넌트 안에서 quad가 내는 에러(잘못된 `Modifier` 등)도 이제 킷 안쪽 줄이 아니라 그 컴포넌트를 부른 줄을 가리킵니다. 에러 문구는 계약이 아니니 문구로 분기하지 마세요.

### Removed

- **BREAKING** `Style`의 `TitleBgCollapsed` 색·투명도 토큰(어두운·밝은 테마 둘 다) — 접힌 창이 제목줄 대신 아이콘이 되면서 쓰는 곳이 없어졌습니다. 옮기는 법: `Style.new`의 덮어쓰기와 `ColorOf("TitleBgCollapsed")`·`AlphaOf("TitleBgCollapsed")`에서 이 이름을 지우세요(남아 있으면 모르는 토큰 에러).
