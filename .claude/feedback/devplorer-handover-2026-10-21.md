# devplorer에 넘길 것 — devui 갱신분과 갈아타기 (2026-10-21)

devplorer(사용자 프로젝트, 레포 밖 `/code/Projects/devplorer`, 이 세션에선 읽기 전용)가 vendor를 올린 뒤 바꿔 쓸 것과, 그 과정에서 조심할 것을 모았다. 사용자: *"devplorer 에 넣어줄 것으로 좀 적어줘야할듯 … sonnet 하나 물려서 devplorer 쪽에서 잘못 적용한게 있나도 보고, 추후 완료된것 넘겨주는 쪽에 같이 담아 주면 될듯"*. 근거는 sonnet 감사 한 번(읽기 전용, devplorer는 vendor 고정 커밋 `81426c5b` 기준)이고, 줄 번호는 그 시점 devplorer 기준이다. 사용자 계획: devplorer에서 다시 적용하고 거기서 QA를 어느 정도 한 뒤 돌아온다 — 개발 설계 결정이 아닌 "써 보니 이게 맞나" 류는 거기서 판단한다.

**목록의 소스.** devui 쪽 변경 목록은 `quad-roblox-devui/CHANGELOG.md`의 `[Unreleased]`가 소스이고, 여기는 devplorer 자리와의 대응만 적는다. 아직 만드는 중인 것은 맨 끝 절.

## 바꿔 쓸 것 (지금 upstream에 있음)

- **우클릭 메뉴 → `OpenMenu`.** `App/ContextMenu.luau`(194줄)를 걷어낸다 — 가짜 Overlay 프록시, 손 clamp, 손 Esc, 손으로 그린 구분선. 호출처는 Explorer·PropertiesView·BookmarksWindow·SplitButton·MenuButton의 `ContextMenu.show`. 표 모양(`Item`/`Submenu`/`Separator`) 선언을 쓰던 곳은 얇은 어댑터로 `MenuItem`·`Menu`·`Separator`를 만들면 된다. **⚠️ vendor를 올리는 순간 프록시가 새 `AnchorRect`를 버리고, 손 clamp와 Overlay의 화면 안 배치가 서로 싸운다** — 올릴 때 ContextMenu를 먼저 바꾸거나 적어도 프록시가 옵션을 통째로 넘기게 할 것. 막힌 이유를 글에 붙이던 `Disabled: string`은 devui가 `Disabled: boolean`뿐이라 `Hooks`(툴팁)나 글에 붙이는 어댑터로.
- **분할·메뉴 단추 → `MenuButton`.** `App/MenuButton.luau`·`App/SplitButton.luau`를 걷어낸다(`OnClick`이 있으면 분할). 아이콘은 `Icon` — **devui 아이콘은 글 크기 정사각(19px 단추)이라 devplorer의 24px 단추보다 작아진다**, 화면에서 확인할 것. 툴팁은 `Hooks`.
- **팝업 몸통 → `PopupPanel`.** 손으로 만든 몸통 다섯(`Popups.luau` panel, CopyDialog, CommandPalette, ContextMenu, NamePrompt). 패딩 값이 devplorer 것(8/6)과 다를 수 있다.
- **화면 안 배치 → Overlay 기본 동작(`AnchorRect`).** `Popups.luau`의 손 clamp, `centerOf`, CommandPalette의 위치 계산에서 화면 안으로 당기는 부분.
- **빈 곳 클릭 → Overlay `ClickSink`.** `PopupShield.sink`와 그 호출처 여섯을 지운다(남겨도 해롭진 않다 — 단추가 둘일 뿐).
- **휠 새기 → Overlay 기본 동작.** 입력을 받는 팝업 위에서는 같은 ScreenGui의 다른 ScrollingFrame 스크롤이 꺼진다(devplorer `PopupShield.start`와 같은 방식). `PopupShield.start`를 지우고 Play에서 휠로 확인할 것 — MCP의 가상 휠은 엔진 스크롤을 일으키지 않아 quad 쪽에선 켜고 끄는 것까지만 쟀다.
- **확인 모달 → `OpenConfirm`.** `Popups.Confirm`(Explorer 삭제, InspectRemotes). **동작 차이 둘**: devplorer는 Enter = 확인이었으나 devui에는 없다(아래 "정할 것"), 바깥 클릭 = 취소였으나 devui 대화상자는 바깥 클릭으로 닫히지 않는다(사용자 결정 — 답을 받아야 하므로). `Popups.AgentStart`·`NamePrompt`는 `OpenDialog` + 내용으로.
- **창 메뉴바 → `Window.MenuBar`.** `init.luau`의 `MenuBarHost`, `toolbarExtra` 되먹임, `WindowBody.MenuRow`. 메뉴바 높이는 `AvailableSize`에서 저절로 빠진다. `WindowBody`는 그 뒤 시드 값 계산만 남는지 보고 판단.
- **아이콘 단추 → `Button.Icon`.** `App/IconButton.luau` 대부분(크기 차이는 위와 같음).
- **툴팁 → `Devui.Tooltip`.** `App/Tip.luau`(약 25곳). 빈 `Text`는 이제 안 뜬다. **동작 차이**: `Tip`은 팝업이 하나라도 열리면 모든 툴팁을 막았고, devui는 팝업 *아래* 행만 막는다(팝업 옆 행엔 뜸). 최대 폭 440·지연 같은 값은 옮겨 줄 것. `OutputView`의 `RowTip`도 정리.
- **Combo 높이 → 고쳐짐.** `ActionFields.luau`의 `dropdownMaxHeight`/`suggestionRoom`/`withPlaceholder` 자르기와 `SuggestMore`는 `MaxHeight`가 이제 지켜지므로 걷어낼 대상(Studio에서 확인 뒤). 위로 열기도 devui가 한다.
- **긴 메뉴 스크롤, 글 상자 자르기, 스크롤바 자리** — devui 위젯을 쓰면 저절로. 손으로 만든 `TextBox`(ActionFields, Insert의 검색 상자, CommandPalette 입력)는 `ClipsDescendants`를 이미 넣었거나 `InputText`로 바꿀 수 있다.
- **가상 목록 → `Devui.VirtualRows`.** `App/VirtualRows.luau`와 `App/Rows/RowWindow.luau`(스펙 포함)를 지우고 아홉 곳의 `require`를 바꾼다. 이름 `ScrollTo` → `ScrollToRow`. **기본 Style이 `DevStyle`이 아니라 `Style.default`** — 호출마다 `Style = style`을 줄 것. 스크롤바 자리(U30)는 이것으로 앱 쪽도 풀린다.
- **켜짐 단추 → `Button.Toggled`, 단추만 탭 → `TabBar { NoPages = true }`.** 단 종류별 색으로 채우는 Output 칩(`KindColors`)은 `Toggled`가 단일 색이라 남긴다. `tabButton`은 고정 폭 84였고 devui 탭은 글 폭이라 모양이 바뀐다. TabBar 탭에는 아직 `Hooks`(툴팁)가 없다.

## 그대로 남는 것

CommandPalette(위쪽에 놓이고 입력 포커스 — `PopupPanel` + `AnchorRect`로만), `DragRows`의 끌기 유령, 색 편집기 `PropPanels`(devui 피커가 나오면 바꿈 — 아래), 앱 의미에 묶인 것(클래스 아이콘, 값 편집기, Exec 등).

## devplorer 쪽에서 본 것 (devui와 무관하거나 앱이 고칠 것)

- **툴팁이 떠 있는 동안 Explorer 단축키가 죽는다(읽기로 판정, 실측 전).** `Explorer.luau`의 `hovered()`가 `Overlay.getDefault().Count:Get() > 0`이면 거짓인데, 툴팁도 `Overlay:Open`이라 Count에 들어간다 — 행 위에 툴팁이 뜬 동안 Ctrl+C·Delete·Ctrl+F 등이 무시되고 `+` 단추도 꺼진다. devui 쪽 처방(Count에서 툴팁 빼기, 또는 "입력을 받는 팝업" 수를 따로 공개)은 새 표면이라 사용자 결정 — 아래 "정할 것".
- **Esc가 겹친 팝업을 한 번에 닫는다** — 팝업마다 `InputBegan`에 따로 연결해서. devui 대화상자·메뉴도 같은 방식이라 갈아타도 같다. 게임 안 Esc는 Roblox 메뉴도 연다(알려진 것).
- **Insert 팝업의 기준이 둘이다.** 클라이언트 목록과 `Ops.IsCreatable`은 `Permits.New`가 있기만 보고, 서버 `Reflect.creatable`은 특권 능력이 필요한 `New`를 거른다 — 특권이 필요한 클래스가 목록에 나와 누르면 실패할 수 있다(그런 클래스가 실제로 있는지는 미확인). 그리고 `CreatableClasses`는 `GetClasses` pcall이 실패하면 빈 목록을 영구 캐시한다(재시도 없음). `Allowed`가 행 바인딩마다 `GetClass` 체인을 캐시 없이 거슬러 올라간다(병목인지는 미측정). 폐기 예정 클래스 필터가 없다. `Ops.Create`가 `Parent` 실패 시 만든 인스턴스를 Destroy하지 않는다(낮음).
- **오류색이 여섯 곳에 따로**(`(245,95,95)`, `(240,130,130)` 계열) — devui Style에 Error/Warning 토큰이 없어서. 토큰은 `research/design-token-plan.md` 후보.
- **마우스 좌표 손 계산**(`GetMouseLocation() - GetGuiInset()` 다섯 곳) — `Devui.Input.service()`/`guiInset()`으로 맞추면 일관적(동작 문제 아님).
- 행 높이 규약이 둘(CommandPalette 18, InspectHistory 24 대 `FrameHeight`), `CommandPalette`의 `Gui.Destroying` 방어는 Overlay가 층이 죽을 때 OnClose를 보장하므로 중복이고 그 주석이 사실과 어긋난다.

## 정할 것 (사용자)

- `OpenConfirm`에 Enter = 확인을 넣을지(devplorer가 쓰던 것; 위험한 동작이 기본 키에 묶이는 문제와 저울질).
- 앱이 "입력을 받는 팝업이 열렸나"를 물을 길 — 지금 `Overlay.Count`는 툴팁까지 센다.
- TabBar 탭의 `Hooks`(툴팁).

## 같은 날 더 들어간 것 (devplorer 쪽 걷어낼 자리)

- **`OpenCopyDialog({ Title?, Text, Window?, Modal? })`** → `App/CopyDialog.luau`(211줄)와 `Popups.CopyText`. 동작은 devplorer 것 그대로(전체 선택 포커스, 안에서 포커스를 잃으면 선택째 되잡기, 글 되돌리기, Select All·Close, 하나만). 차이: 바깥 클릭으로 닫히지 않고 Escape로 닫힌다(대화상자 규칙), 배경은 `Style` 기본(불투명이 필요하면 `Style`을 넘길 것).
- **`Selection`** → `App/Rows/Select.luau`. 모드 이름이 바뀌었다: `"Single"` → `"Replace"`, `"Range"` → `"Extend"`(`"Toggle"` 그대로). 세 곳(Explorer·BookmarksWindow·OutputView)의 Shift/Ctrl 판정은 `Selection.modeFromKeys()`로(Cmd도 Toggle). `LogSelection.range`도 흡수 대상.
- **`TreeRows`** → `App/Rows/Flatten.luau`. 접근자 `Extra` → `MoreCount`, 나머지(`flatten`·`expand`·`collapse`·`toggle`·`reveal`·`indexOf`·`indexByKey`·`newPaging`·`loadMore`·`signatures`·`sameRows`, 행의 `More`)는 이름 그대로. 스펙 21개도 같이 옮겨졌다.
- **`VirtualRows`의 `Follow = true`** → `InspectUi.follower()`(Modifier·ScrollTo·Update 세 조각이 prop 하나로). **`Devui.RowIndexAt(list, y)`** → `Explorer` `rowIndexAt`·`LogSelection.indexAtY`(y는 AbsolutePosition 공간, `GetMouseLocation() - inset`).
- **휠 막기**는 Overlay 기본이 됐다(위 "바꿔 쓸 것"에도 적음) → `PopupShield.start`.
- **`ColorPicker3` / `OpenColorPicker` / `ColorModel`**, `InputColor3` 견본이 피커를 연다 → `PropPanels.ColorPanel` 전체와 `Editors`의 색 파싱 중복. 적용은 끄는 동안 바로(devplorer의 0.1초 적용은 소비자 쪽 `q.Throttle`로), 취소는 연 때 색을 다시 쓴다(devplorer `audit/2026-10-20-color-cancel.md`와 같은 규칙). **차이**: devplorer 패널은 Properties 목록 틀 안의 Frame(창 밖으로 안 나감)이었고 devui 피커는 Overlay 대화상자(그 창을 막음)다.

## 만드는 중 (2026-10-21, 순서대로)

~~복사 대화상자 → 선택 규칙·트리 평탄화·`VirtualRows` 끝 따라가기와 y→행 번호 → 색 편집기~~(위 절, 같은 날 들어감) → 검색되는 가상 Combo(키보드 고르기 포함 — Insert 팝업의 일반 부분: 항목 목록, 행 앞 아이콘 칸, 막힌 이유, 고르면 닫기) → 가상 표. 미룬 것: 창 자리 자동 정하기, 불투명 Style 프리셋, 차트. 끝나면 이 문서에 이어 적는다.
