# quad-roblox-material

> 패키지 이름은 **가칭**입니다(작업명 `quad-roblox-material`). 도그푸딩을 거친 뒤 정식 이름을 정합니다. 코드 안에는
> 이 이름이 어디에도 없고(require는 전부 폴더 상대 경로), 이 문서와 매니페스트에만 나옵니다.

[quad](../README.md) 위에서 만든 **Material Design 3 컴포넌트 키트**입니다. 토큰(색 역할·타입 스케일·모양·
엘리베이션·모션·상태 레이어)부터 버튼, 입력, 메뉴, 다이얼로그, 날짜 선택기, 색상 선택기까지 한 세트이고, 전부
quad의 방식 — **한 번 만들고 값만 흘려 보내는 retained, 반응형** — 으로 짰습니다.

```luau
local Material = require("<이 폴더>/src")
local q = require("<이 폴더>/src/Quad")
local D = q.Declaration

local agreed = q.Source(false)
local screen = D.ScreenGui {
	ResetOnSpawn = false,
	D.Frame {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Material.Theme.default.Color.Surface,
		Material.Button { Label = "Save", OnClick = function() print("saved") end },
		Material.Checkbox { Value = agreed },
	},
}
screen.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
```

전체를 한 번에 보려면 갤러리를 띄우세요(아래 "갤러리").

## 왜 만들었나

예전 키트들(RoStrapUI, qwreey MaterialUI)은 둥근 모서리와 리플 클리핑을 이미지·프레임 겹치기로 풀어서 버튼 하나가
수십~백 개의 인스턴스였습니다. 이 키트는 엔진이 이제 직접 주는 것 — `UICorner`, `UIStroke`, `CanvasGroup`,
`ClipsDescendants`, `UIShadow`, `UIGradient`, `UIListLayout`/`UIFlexItem`/`UIPadding` — 으로 풉니다. 실측(스펙이 세는
값)으로 쉬는 상태의 인스턴스 수는 다음과 같습니다.

| | 이 키트 | RoStrap RippleButton | qwreey MaterialUI 둥근 버튼 |
|---|---|---|---|
| Filled 버튼(아이콘 없음) | **8** | 40 | 70 |

(`src/Button/init.luau` 머리와 `test/spec.button.luau`가 소스. 누르는 동안 리플이 일시적으로 3개를 더 만듭니다.) 다른
컴포넌트의 수도 각 파일 머리와 스펙에 있습니다 — 예: Checkbox 15(토글 모션 막대 틀 하나 + 막대 넷 포함), Radio 5(스프라이트 한 장), Switch 8(M2 9), 필드 있는 Filled TextField 13,
Slider 20(M2 14), RangeSlider 30(M2 23), 한 줄 ListItem 7, LoadingIndicator 8, 색상 패널 106(8색 프리셋 포함). 갤러리 전체의 탭별 합계는 아래 "갤러리"에 있습니다.

## 설치와 설정

이 레포 안에서는 그대로 `require("quad-roblox-material/src")`로 쓰면 됩니다. 키트가 quad가 어디 있는지 아는 곳은
**`src/Quad.luau` 하나**입니다 — quad 문서가 권하는 "설정 모듈"과 같은 모양(quad_base 싱글턴에 Roblox 프로바이더를
한 번 설치하고, 키트가 쓰는 타입을 다시 내보냄)이고, 세 줄이 전부입니다.

```luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
```

다른 프로젝트에서 쓸 때는 **이 세 줄만** 그 프로젝트의 패키지 경로로 바꿉니다(예:
`@game/ReplicatedStorage/Packages/quad_base`). 나머지 키트 코드는 전부 `require("./Quad")` 꼴로 이 모듈만 봅니다.
`UseProvider`는 같은 프로바이더에 대해 멱등이므로, 게임이 같은 설치 사본에서 자기 설정 모듈을 이미 돌렸다면 같은 quad
인스턴스를 공유합니다(게임의 `State`와 키트의 `State`가 그대로 섞입니다).

### 킷을 고치지 않고 쓰는 배치

키트에는 패키지 매니페스트가 없어 설치할 수 없습니다. 대신 `src/Quad.luau`의 상대 경로 셋을 그대로 두고, **소비자의 DataModel 쪽을
그 모양에 맞추면** 키트 소스를 한 줄도 고치지 않고 돕니다. 필요한 모양은 `<부모>` 폴더 아래 형제 둘입니다.

```
<부모>/quad-roblox/src                  -- Roblox 프로바이더
<부모>/quad-roblox/luau_packages        -- quad_base · quad_types · type_version_check (pesde 산출물)
<부모>/quad-roblox-material/src         -- 이 키트
```

rojo 프로젝트 조각 예(이 레포 루트의 `consumer-kits.project.json`에서 필요한 부분만 — `<경로>`는 소비자 쪽 사본 위치):

```json
"ReplicatedStorage": {
	"$className": "ReplicatedStorage",
	"quad-roblox": {
		"$className": "Folder",
		"src": { "$path": "<경로>/quad-roblox/src" },
		"luau_packages": { "$path": "<경로>/quad-roblox/luau_packages" }
	},
	"quad-roblox-material": {
		"$className": "Folder",
		"src": { "$path": "<경로>/quad-roblox-material/src" }
	}
}
```

갤러리(`gallery/`)와 스토리(`stories/`)는 소비자에게 필요 없습니다 — `src`는 둘 다 `require`하지 않습니다(레포 루트의 프로젝트 파일이
둘을 싣는 건 갤러리 실행용입니다). 상대 경로 덕에 같은 플레이스에 다른 quad 사본이 따로 있어도 서로 섞이지 않습니다.

**게임 쪽 설정 모듈도 같은 경로를 물어야 합니다.** 키트가 쓰는 quad 싱글턴은 `quad-roblox/luau_packages/quad_base`입니다
(그 파일은 같은 폴더의 `.pesde/…/quad_base/src`로 위임하는 링커이고, `quad-roblox/src`는 quad_base를 직접 `require`하지 않고
`UseProvider`로 주입받습니다). 게임의 설정 모듈이 `quad-base/src`를 직접 물면 **다른 모듈 인스턴스**라 `State`가 키트와 섞이지 않습니다.
그래서 게임의 설정 모듈은 키트의 `src/Quad.luau`와 같은 세 곳을 물어야 합니다.

```luau
local Quad = require("<…>/quad-roblox/luau_packages/quad_base")
local RobloxModule = require("<…>/quad-roblox/src")
local QuadTypes = require("<…>/quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
```

(첫 소비자가 `rawequal(게임의 q, 키트의 q) == true`를 Studio Play에서 확인했습니다.)

**미게시 작업 트리를 커밋 해시로 고정해 받기.** `quad-roblox/luau_packages`는 `.gitignore`된 pesde 산출물이라 복제본에는
없습니다. 복제하고 해시로 체크아웃한 뒤, 복제본의 워크스페이스 루트에서 `pesde install`을 한 번 돌리면 생깁니다(이 레포는 pesde를
`mise`로 핀하므로 `mise exec -- pesde install`). 첫 소비자는 이 두 단계만으로 rojo `$path`가 돌았다고 보고했고, 오프라인에서도 됐습니다.
`scripts/relink.sh`는 이 레포를 고치며 `luau` CLI로 테스트할 때 필요한 절차이고(`CONTRIBUTING.md`), 이 배치에서 필요했다는 보고는 없습니다.

## 컴포넌트

`require("<이 폴더>/src")`가 돌려주는 표의 항목입니다.

| 그룹 | 항목 | 한 줄 설명 |
|---|---|---|
| 토대 | `Tokens` | M3 정적 토큰: `Color`(기본 light/dark)·`Typography`·`Shape`·`Elevation`·`Motion`·`State` |
| | `Theme` | `Theme.new{ Scheme, Overrides }` / `Theme.default` — 색 역할이 애니메이션되는 반응형 State |
| | `Text` | 타입 스케일 텍스트 Modifier(`Text.Label("BodyLarge")`) |
| | `Interaction` / `StateLayer` / `Ripple` / `Interactive` | hover·pressed·focus State, 상태 레이어 프레임, `CanvasGroup` 리플, 이 셋을 한 번에 묶은 것 |
| | `Elevation` | `UIShadow` 한 개로 엘리베이션 0~5(`Elevation.Backdrop`은 9-slice 이미지 대안) |
| | `Overlay` | 메뉴·다이얼로그·스낵바·툴팁이 뜨는 층 (`Overlay.default()` 자가 치유, Escape/B·선택 가두기) |
| | `Icons` | 내장 아이콘 — Material Design Icons 이미지(기본) + 이름마다 텍스트 글리프 폴백, `Icons.override`로 교체·제거; 아이콘 prop(Button·SplitButton `Icon`, Slider `TrackIcon*`) 값은 `Icons.resolve`로 — 이름이면 그 이미지(지운 이름은 글리프), 에셋 URL이면 그 이미지, 그 밖의 글자는 글리프로 그림 |
| | `GlyphButton` / `KeyNav` / `Util` | 글리프·이미지 둥근 버튼(날짜 선택기·Snackbar 닫기·Chip 제거가 공유), 키·D-pad 전달 훅(Slider·날짜 칸·색상 선택기가 공유), `asState`/`negate`/`interactable`/`visible`/`hooks` 도우미와 `Hooks` 타입 |
| 버튼 | `Button` | Filled / Tonal / Elevated / Outlined / Text 다섯 변형(한 함수, `Variant` prop), 폭은 글자에 맞춤 또는 `Width`(픽셀·UDim, 라벨 가운데); `Icon`(18 px, 라벨과 8 px)과 `IconPosition = "Leading" \| "Trailing"` — 여백은 material-web 토큰(아이콘 없음 24/24, 앞 아이콘 16/24, 뒤 아이콘 24/16; Text는 12/12·12/16·16/12) |
| | `SplitButton` | M3 Expressive 분할 버튼(작은 크기, 높이 40): 앞 버튼(행동 — `Label`·`Icon` 20 px·`OnClick`)과 뒤 버튼(메뉴 — 아래 화살표 22 px·`OnTrailingClick`) 사이 2 px, 바깥 모서리 20·안쪽 모서리 4(누르는 동안 12), `Selected`면 뒤 버튼이 양 끝 반원 알약 + 화살표 180° + 내용색 10 % 덮개; Filled / Tonal / Elevated / Outlined |
| | `IconButton` | Standard / Filled / Tonal / Outlined, `Selected`로 토글 |
| | `FAB` | Small / Regular / Large, 색 넷, 레이블이 있으면 Extended |
| 선택 | `Checkbox` | 체크·불확정·오류·비활성(체크 표시는 회전한 Frame 둘이라 이미지 없음, 토글은 MaterialUI식 가장자리 막대 모션), `Label`로 라벨까지 한 클릭·호버 영역 |
| | `Radio` / `RadioGroup` | 한 개 / 세로·가로 묶음(선택 모션은 MaterialUI 스프라이트 시트 이미지 한 장), `Label`로 라벨까지 한 클릭·호버 영역 |
| | `Switch` | M3: 52x32 트랙, 핸들이 16→24→28로 자람(꺼진 채 누르면 24), 선택적 아이콘; 핸들을 끌어 절반을 넘기면 반대 상태(탭은 토글) |
| | `Slider` | M3(현행 Compose 형태): 트랙을 핸들 양옆 6px 틈으로 두 조각, 바깥 끝 완전 둥글림·핸들 쪽 반경 2, 4 px 막대 핸들, 끝 점(stop indicator, 트랙 끝에서 중심 6 px 안쪽 — 크기와 무관, m3.material.io 스펙), 연속/이산(4px 점 눈금), 값 라벨 알약, 키보드·D-pad. M3 변형: `Size` XS/S/M/L/XL(트랙 16/24/40/56/96, 바깥 반경 8/8/12/16/28, 핸들 높이 44/44/44/68/108 — MDC `Widget.Material3Expressive.Slider.*`), `Orientation = "Vertical"`(기본 아래가 Min, `TopToBottom`으로 위가 Min; 핸들은 44 x 4로 눕고 라벨은 왼쪽, 위/아래 키), `Centered`(활성 트랙이 범위 한가운데에서 핸들까지), 안쪽 아이콘 `TrackIconActiveStart/End`·`TrackIconInactiveStart/End`(M 이상·표준만, 24/24/32 px, 조각 끝에서 10 px, 조각이 아이콘 + 20보다 짧으면 숨음) |
| | `RangeSlider` | M3 손잡이 둘(`Start`/`End` 두 Source) — 트랙 세 조각(가운데는 양 끝 반경 2), 누른 자리에서 가까운 손잡이를 끌고 서로를 못 넘음, 키는 한 손잡이씩(Return·게임패드 X로 전환); `Size`·`Orientation`·`TopToBottom`은 Slider와 같음(세로 범위는 MDC `RangeSlider`가 `BaseSlider`의 orientation을 물려받아 정본 — Compose엔 없음), `Centered`·안쪽 아이콘은 없음 |
| | `M2.Slider` / `M2.RangeSlider` / `M2.Switch` | Material 2 모양 — 같은 props·같은 동작(공용 동작 모듈), 그림만 다름: 4px 얇은 트랙 + 20px 원형 손잡이·40px halo, 얇은 36x14 트랙 + 트랙보다 큰 20px 원형 썸(그림자). 아래 "M2 모양" |
| 입력·메뉴 | `TextField` | Filled / Outlined, 떠오르는 레이블, 보조·오류 문구, 글자 수(`MaxLength`; `ShowCounter = false`면 길이 제한만 걸고 표시는 끔), 아이콘, 접두·접미, 여러 줄 |
| | `Menu` | `Menu.open{ Anchor, Items }`와 `Menu.Button` — 앵커 아래(공간이 없으면 위)에 뜸 |
| | `Select` | 읽기 전용 TextField + Menu(노출형 드롭다운) |
| 표면 | `Card` | Elevated / Filled / Outlined, `OnClick`이 있으면 상호작용 카드 |
| | `Divider` | 1px 선, 수평·수직, 안쪽 여백 |
| | `List` / `ListItem` / `ListData` | 1~3줄 행, 정적 자식 또는 키로 재활용되는 데이터 목록 |
| 오버레이 | `Dialog` | `open` / `confirm` / `alert`, 스크림·Escape·게임패드 B·선택 가두기, 작은 화면에서 본문 스크롤(또는 `Fit` — 카드째 축소) |
| | `Snackbar` | 하단 중앙, 한 번에 하나, 나머지는 큐 |
| | `Tooltip` | `Tooltip.hook`(대상마다 하나)과 `Tooltip.Plain`(시각만) |
| 칩·탭·진행 | `Chip` | Assist / Filter / Input / Suggestion + 키로 재활용되는 `ChipSet` |
| | `Tabs` | Primary / Secondary, 활성 표시기 하나가 미끄러짐 |
| | `LinearProgress` / `CircularProgress` | 확정·비확정. 원형은 원호 조각 스프라이트 시트(1·2·4…256° 조각, 두께 넷)를 2진으로 합쳐 `Rotation`으로 돌려 놓고 양 끝에 둥근 캡 — M3처럼 표시와 트랙 사이 간격·둥근 끝, 비확정은 10 %↔87 % 호가 늘었다 줄며 돎(트랙 없음). `Thickness`는 지름 대비 0.05/0.10/0.15/0.20 중 가장 가까운 것으로 맞춰짐. 인스턴스 확정 25·비확정 13(지름 ≳130 px에선 1° 조각이 더해져 27·14); 확정은 값이 바뀌어 0.3 s 트윈하는 동안만 Heartbeat(바뀐 조각만 써서 2° 한 칸에 평균 약 8 쓰기), 비확정은 매 프레임 보이는 조각 ≤ 7 `Rotation` + 캡 2 `Position` |
| | `LoadingIndicator` | M3 Expressive 로딩 표시 — 모양이 바뀌며 도는 것(둥근 사각형 셋을 서로 돌려 겹친 근사: 12갈래·8갈래·둥근 사각형·알약·원), `Contained` |
| | `WavyProgress` | M3 Expressive 물결 막대(확정만) — 진폭 스프라이트 시트의 한 칸(한 파장)을 파장마다 Stretch ImageLabel로 깔아 흐르며 차오름, `ClipsDescendants` 프레임이 채운 길이로 자르고 양 끝에 사인 곡선을 따라 움직이는 둥근 캡; 100 %이거나 `Wavy = false`이면 물결이 잦아들어 평평해짐(0.5 s), 평평하면 루프가 쉼(인스턴스 12 + 폭/파장 올림 + 1 — 300 px에서 21, 폭에 비례, 시트는 아래 "외부 이미지 에셋") |
| 선택기 | `DatePicker` | `Docked` / `RangeDocked` / `Modal`, 순수 날짜 계산 `Calendar` |
| | `ColorPicker` | `Panel` / `Modal.open` / `ColorModel` |
| | `TimePicker` | `Dial`(시계 문자판) / `Input`(두 칸 입력) / `Modal.open`(다이얼 ↔ 입력 전환), 순수 시간 계산 `Clock` — Compose `TimePicker`·`TimeInput`·`TimePickerDialog` 그대로 |
| 시트 | `SheetState` | 시트 상태 — Compose `SheetState`: `Hidden` / `PartiallyExpanded` / `Expanded`, `CurrentValue`(멈춘 값)·`TargetValue`, `Expand`/`PartialExpand`/`Show`/`Hide`, `ConfirmValueChange` 거부권 |
| | `BottomSheetScaffold` | 표준 하단 시트 — 화면(호스트) 아래에 붙어 56 px 엿보기·펼침(스크림 없음), 끌기·손잡이 클릭 |
| | `ModalBottomSheet` | `ModalBottomSheet.open{ Children }` — 스크림 위로 올라오는 모달 하단 시트(Overlay), 끌어 내리기·스크림·Escape/B(펼침이면 절반으로 먼저) |
| | `SideSheet` / `ModalSideSheet` | MDC 측면 시트 — 표준(부모 가장자리에 붙음, surface)과 `ModalSideSheet.open`(스크림, 안쪽 모서리 16, 그림자 1); 폭 256, 오른쪽(End)/왼쪽(Start), 머리(제목 + 닫기) 선택, 옆으로 끌어 숨기기 |
| 내비게이션 | `DrawerState` | 드로어 상태 — Compose `DrawerState`: `Closed` / `Open`, `Open`/`Close`/`SnapTo`, `IsOpen` |
| | `ModalNavigationDrawer` / `DismissibleNavigationDrawer` / `PermanentNavigationDrawer` | 트리 안 레이아웃(Compose 그대로): 스크림 위로 미끄러지는 모달, 내용을 밀어내는 dismissible, 늘 옆에 있는 permanent |
| | `ModalDrawerSheet` / `DismissibleDrawerSheet` / `PermanentDrawerSheet` | 드로어 면 — 폭 360(240~360), 모달은 surfaceContainerLow + 끝 모서리 16, 목록은 스크롤 |
| | `NavigationDrawerItem` / `NavigationDrawerItems` / `NavigationDrawerHeadline` / `NavigationDrawerDivider` | 56 px 알약 행(아이콘 24·LabelLarge·배지), 데이터 목록(`Selected: Source<K>` 하나 — Tabs 규칙), 구획 제목(TitleSmall)·구분선(MDC) |
| | `ShortNavigationBar` | 내비게이션 바(M3 Expressive, 64 높이 surfaceContainer) — 같은 목적지 모델·Tabs 선택 규칙, 아이콘 위(56 x 32 알약) / 아이콘 앞(40 높이 알약), `EqualWeight` / `Centered` 배치, 선택하면 알약이 가운데서 자람 |
| | `WideNavigationRail` / `WideNavigationRailState` | 내비게이션 레일 — 접힘 96 폭(아이콘 위 알약), 펼침은 가장 넓은 항목 + 20(220~360, 아이콘 앞 56 높이 알약), `Collapsed` / `Expanded` 상태 객체, 머리(메뉴 버튼·FAB) |
| | `Badge` | M3 배지 — 작은 점 6 px, 글자 있는 16 px(LabelSmall, error) — 바·레일 아이콘 위에 |
| 앱 바·툴바 | `TopAppBar` / `CenterAlignedTopAppBar` / `MediumTopAppBar` / `MediumFlexibleTopAppBar` / `LargeTopAppBar` / `LargeFlexibleTopAppBar` | 위 앱 바 여섯(Compose 그대로): 내비게이션 아이콘·제목(·부제목)·액션(데이터 → 48 px 아이콘 버튼, 툴팁, `MaxItemCount` 넘으면 오버플로 메뉴) |
| | `TopAppBarState` / `TopAppBarDefaults` | 스크롤 동작 `pinnedScrollBehavior` / `enterAlwaysScrollBehavior` / `exitUntilCollapsedScrollBehavior` — `Hook`을 ScrollingFrame에 꽂으면 그 스크롤을 따라 색이 바뀌고(scrolledContainerColor) 접힘 |
| | `BottomAppBar` / `FlexibleBottomAppBar` | 하단 앱 바(80, 액션 + FAB)와 유연한 하단 앱 바(64 — MDC의 docked toolbar) |
| | `HorizontalFloatingToolbar` / `VerticalFloatingToolbar` | M3 Expressive 떠 있는 툴바 — 64 두께 알약, Standard / Vibrant 색, 앞·뒤 내용은 펼쳤을 때만, FAB 형(펼침 56 FAB + 툴바, 접힘 80 FAB만) |
| 화면 틀 | `Scaffold` | Compose `Scaffold` — 위 앱 바·아래 바·FAB(`FabPosition` Start / Center / End / EndOverlay)·스낵바 자리를 내용 둘레에 배치; 내용은 두 바 사이 영역(스크롤바가 바에 안 가림), 접히는 앱 바만큼의 위 여백은 `innerPadding.Top`(`PaddingValues`)으로 |

### props 관례

모든 컴포넌트는 같은 규칙을 따릅니다(`src/init.luau` 머리의 열 항목 체크리스트가 소스).

- **평범한 함수 하나**가 호스트 인스턴스를 돌려줍니다: `Material.Button { ... }`.
- **호스트 `Name`은 `Modifier`로 바꿀 수 있습니다**: 컴포넌트는 호스트 이름(`Button`, `Card`, ...)을 기본 Modifier에 두므로 `Modifier = D.Modifier.TextButton():Name("SaveButton")`처럼 주면 그 이름이 됩니다(안 주면 기본 이름 그대로). 안쪽 자식의 이름은 바꿀 수 없습니다.
- **`Theme` 폴백**: `props.Theme`가 없으면 `Theme.default`. 앱 전체에 테마 하나를 쓰면 아무것도 안 넘겨도 됩니다.
- **`T | State<T>` 입력**: 값이 바뀔 수 있는 입력(`Label`, `Disabled`, `Error`, ...)은 값 또는 State를 받습니다. State를
  넘기면 그 프로퍼티만 갱신됩니다.
- **`Source<T>` 양방향 prop(`Value`)**: 폼 컨트롤(`Checkbox`·`Switch`·`Radio`·`Slider`·`TextField`·`Select`·`DatePicker`·
  `ColorPicker`)은 `Value`로 `Source<T>`를 받습니다. 컴포넌트가 읽고, 사용자가 조작하면 `:Set`합니다. `Checkbox`·`Switch`·`Slider`·`TextField`·
  `ColorPicker`는 안 넘기면 컴포넌트가 내부 Source를 만들고, `Select`·`Radio`·`DatePicker`는 필수입니다. **`OnChange(new)`는 사용자 조작 뒤**에만 불리고 프로그램이 쓴 값에는 안 불립니다.
- **서버가 진실인 값에는 되쓰기 패턴**: `Select`·`Radio`·`Slider`·`TextField`·`Chip.Filter` 같은 나머지 폼 부품은 지금 `Value`(칩은 `Selected`)의
  `Source`만 받고, 조작하면 **스스로 그 `Source`에 먼저 쓴 뒤** `OnChange`를 부릅니다. 요청을 보내고 서버가 승인하면 새 상태가 오는 값이라면
  `OnChange`에서 요청만 보내고, **서버 상태가 올 때마다 그 `Source`에 다시 `:Set`**하세요. 프로그램이 쓴 값에는 `OnChange`가 불리지 않으므로
  되돌이가 없고, 서버가 거절하면 서버가 보낸 이전 상태가 화면의 값을 되돌립니다.

  ```luau
  local level = q.Source<<string?>>("everyone")                   -- 화면의 값(Select의 Value는 Source<T?>)
  Material.Select<<string>>({ Label = "Who can edit", Options = { "everyone", "host" }, Value = level,
      OnChange = function(option) Bridge.send("setLevel", option) end })      -- 요청만
  Bridge.onState(function(state) level:Set(state.level) end)       -- 서버 상태가 올 때마다 덮어씀(OnChange 안 불림)
  ```

  (`Chip.Filter`의 `Selected`도 필수 `Source`입니다.) 예의 `Bridge`는 가상 이름입니다.
  `Checkbox`·`Switch`만은 아래의 통제형이 따로 있어 쓰지 않아도 됩니다.
- **통제형 `Checked`**: `Checkbox`와 `Switch`는 `Value` 대신 `Checked: State<boolean>` + `OnChange`도 받습니다. 컴포넌트는 State를
  보여 주기만 하고 클릭하면 `OnChange(새 값)`만 부르며 **아무것도 쓰지 않습니다**(원본 상태는 호출한 쪽이 정함 — 예: 테마 스위치는
  `Checked = theme.Scheme:Compute(...)`, `OnChange = function(dark) theme:SetScheme(...) end`). `Value`와 `Checked`를 같이 주면 에러.
- **선택·표시 컴포넌트는 `Selected`**: `Chip.Filter`·`Tabs`·`ListItem`·`IconButton`(토글)·`Menu` 항목. 값 바뀜 콜백은 `Chip.Filter`/`Tabs`도 `OnChange`.
- **글자 이름**: 버튼·행동 글자는 어디서나 `Label`(`Button`, `Chip`, `Tabs`의 탭, `Menu` 항목, `Snackbar`·`Dialog`의 액션). 스낵바 메시지만 `Text`.
- **`Disabled`는 어디서나 `boolean | State<boolean>`**(메뉴·목록 항목, 라디오 옵션 포함).
- **열린 것의 핸들은 하나의 모양**: `Overlay:Open`, `Menu.open`, `Dialog.open`, `DatePicker.Modal.open`, `ColorPicker.Modal.open`,
  `ModalBottomSheet.open`, `ModalSideSheet.open`, `Snackbar` 항목, `Tooltip.hook` 모두 **self 없는 클로저** `handle.Close(result?)`와 `handle.IsOpen: State<boolean>`을 돌려줍니다
  (`Overlay` 핸들은 `Closing`, `Dialog`는 `Result`, 모달 시트는 `SheetState`, `Snackbar` 항목은 `Visible`/`Done`/별칭 `Dismiss`가 더 있음). `result`는 `unknown`.
- **시트·드로어는 상태 객체로**: Compose처럼 `SheetState`·`DrawerState`가 움직임을 맡습니다(`CurrentValue`/`TargetValue` State와
  `Expand`·`Hide`·`Open`·`Close` 같은 self 없는 클로저). 폼 값이 아니므로 `Value`/`OnChange`가 없습니다. 상태 하나는 컴포넌트
  하나가 몰고, 나중에 만든 컴포넌트가 넘겨받습니다(다시 만든 시트, 같은 상태로 다시 연 모달).
- **내비게이션 목적지**: `NavigationDrawerItems`는 `{ Key, Label, Icon, Badge }` 목록과 **`Selected: Source<K>` 하나**를 받습니다(`Tabs`와
  같은 규칙 — 클릭이 `SetIfChanged(key)`, 바뀌었으면 `OnChange`, 매번 `OnClick`). 행 하나(`NavigationDrawerItem`)는 다른 표시
  컴포넌트처럼 `Selected: boolean | State<boolean>`. 목적지 타입 `Material.NavigationDestination<K>`는 `ShortNavigationBar`·`WideNavigationRail`과 공유합니다
  (바·레일은 `Badge = ""`를 작은 점, 다른 글자를 큰 배지로 아이콘 위에 그림).
- **앱 바·툴바의 아이콘 버튼은 데이터로**: `Material.AppBarAction = { Icon, Label, OnClick?, Checked?, OnCheckedChange?, Disabled? }` —
  Compose `AppBarRow`의 항목처럼 Label이 툴팁이자 오버플로 메뉴 글자, `Checked`가 있으면 토글(새 값으로 `OnCheckedChange`, 아무것도
  쓰지 않음). 인스턴스를 그대로 넣어도 됩니다(메뉴로 안 넘어감). 아이콘 색은 그 바의 색(`IconButton`의 새 `ContentColor` prop).
- **제네릭 컴포넌트의 타입 인자**: `Tabs<<string>>({ ... })`처럼 적어야 합니다 — `Selected: Source<K>`가 불변이라 `q.Source("a")`만으로는 strict가
  K를 `string | nil`로 추론해 호출을 거부합니다(`Tabs`의 탭 목록은 인라인 리터럴도 받고, State는 `TabsState`로 따로 받음).
- **`Modifier`**: 배열 부분에서 컴포넌트의 기본 스타일 **뒤에** 적용되므로(나중 것이 이김) 크기·위치·`LayoutOrder`를
  호출한 쪽이 바꿀 수 있습니다.
- **`Hooks`**: 호스트 인스턴스가 있는 **모든** 컴포넌트는 배열 부분에 추가로 꽂을 값(예: `Tooltip.hook(...).Hook`, `q.OnChange`, ref)을 받습니다.
  타입은 하나의 별칭 `Material.Hooks = { any }`입니다. `Modifier`의 타입은 호스트 클래스의 `q.<Class>Modifier`(`q.TextButtonModifier` 등)입니다.
- **`ListData`의 줄은 키마다 한 번 만들고 `item` State만 갈아 끼웁니다.** 그래서 줄 안의 `OnClick` 같은 콜백은 값을 **불릴 때** 읽어야 합니다(`item:Get()`) — 줄을 만들 때 읽어 둔 값은 같은 키에 다른 항목이 들어오면 낡습니다(키를 목록 안의 자리로 준 경우가 그렇습니다).
- 자식을 받는 컴포넌트(`Card`, `List`, 시트·드로어 면)는 `q.Slot<<Instance>>({ ... })`를 `Children`으로 받습니다(`BottomSheetScaffold`는
  `SheetContent`·`Content`, 드로어 레이아웃은 `Content` Slot + `DrawerContent` 인스턴스 하나 — Compose의 이름).

### 타입 이름 규칙

모듈 표의 값(`Material.X`)과 같은 이름의 타입이 필요할 때 어떤 이름으로 내보내는지는 일관된 규칙이 없고, `src/init.luau`의 `export type` 블록이
소스입니다. 실제로 쓰이는 꼴은 이렇습니다.

| 꼴 | 예 |
|---|---|
| 값과 타입이 같은 이름 | `Material.Theme`(값이자 타입) |
| 컴포넌트 props는 `<이름>Props` | `Material.ButtonProps`, `Material.TabsProps<K>`(제네릭 컴포넌트는 `<K>`/`<T>`) |
| 열기 옵션은 `<이름>Options`/`<이름>OpenOptions` | `Material.MenuOpenOptions`, `Material.ModalSideSheetOptions` |
| 열린 것의 핸들은 `<이름>Handle` | `Material.DialogHandle`, `Material.ModalBottomSheetHandle`, `Material.OverlayHandle` |
| 값 모듈과 겹치는 타입 | `Material.Overlay.new()`가 돌려주는 타입은 **`Material.OverlayType`**(`Material.Overlay`는 타입 이름이 아님 — `Unknown type`) |
| 상태 객체 | `Material.SheetState`·`Material.DrawerState`는 값과 타입이 같은 이름 |

`Material.Handle`은 `Material.OverlayHandle`의 별칭입니다. 이름이 겹치는데 타입이 필요하면 `Material.<이름>Type`이 있는지 `init.luau`의
`export type`을 먼저 찾아보세요(현재 그런 것은 `OverlayType` 하나입니다).

## 테마

```luau
local dark = Material.Theme.new({ Scheme = "dark" })
local brand = Material.Theme.new({
	Scheme = "light",
	Overrides = {
		Light = { Primary = Color3.fromRGB(0, 122, 108) },
		Dark = { Primary = Color3.fromRGB(80, 218, 198) },
	},
})

Material.Button { Theme = brand, Label = "Save" }
brand:SetScheme("dark")   -- 바인딩된 모든 프로퍼티가 300ms에 걸쳐 새 역할 색으로 바뀜
brand:Toggle()
```

`theme.Color.<Role>`는 **애니메이션되는** `State<Color3>`라 프로퍼티에 그대로 꽂습니다(`BackgroundColor3 =
theme.Color.Surface`). 색 계산이 필요하면 애니메이션 없는 `theme.Raw.<Role>`을 `:Compute`에서 읽고 결과에 한 번만
`:Apply(q.Animate(...))`합니다. `Overrides`는 만들 때 한 번 합쳐지며(정적) 안 덮은 역할은 기본값을 유지합니다 — 다른
시드가 필요하면 테마를 하나 더 만드세요.

## 오버레이

메뉴·다이얼로그·스낵바·툴팁·Select는 직접 부모를 잡지 않고 **`Overlay`**에 엽니다. **ScreenGui마다 `Overlay.new()`를
하나 만들어 그 층을 ScreenGui의 마지막 자식으로 놓고, 오버레이를 여는 컴포넌트에 명시적으로 넘기세요.**

```luau
local overlay = Material.Overlay.new()
local gui = D.ScreenGui {
	ResetOnSpawn = false,
	DisplayOrder = 10,
	App(overlay),
	overlay.Layer,                       -- 마지막 자식
}

Material.Dialog.confirm({ Headline = "Delete?", Body = "This cannot be undone.", Overlay = overlay })
Material.Menu.Button({ Label = "Actions", Items = items, Overlay = overlay })
local snackbars = Material.Snackbar.new({ Overlay = overlay })   -- 호스트 하나, :Show로 큐에 넣음
```

**`Overlay.default()`**: 오버레이를 안 넘기면 컴포넌트는 `Overlay.default()`로 폴백합니다. 모듈이 로드될 때 만들어지는 전역
인스턴스가 **아니라** 처음 부를 때 만들어지는 **자가 치유 접근자**입니다 — 그 층(`Frame`)이 죽었으면(마운트된 ScreenGui가
파괴됨, `ResetOnSpawn = true`는 리스폰마다) 다음 호출이 새 오버레이를 만들어 주므로 오래 사는 싱글턴이 낡을 수 없습니다.
앱 루트에서 `Overlay.default().Layer`를 한 번 마운트하세요(ScreenGui를 다시 만들면 새 층을 다시 마운트). 죽은 오버레이에
`Open`하면 **조용히 무시되지 않고 에러**가 납니다. 여러 ScreenGui가 있으면 화면마다 `Overlay.new()`를 가지고 명시적으로
넘기는 쪽이 층의 수명을 화면과 같게 해 줍니다(갤러리는 `default`를 쓰지 않고 자기 층을 가집니다). 층이 죽으면 열려 있던
모든 핸들이 한꺼번에 마감됩니다(`IsOpen`/`Closing` false, `Count` 0, `OnClose` 한 번 — 사유 `"Destroyed"`).

**접근성(Overlay가 맡는 것)**: `Open{ DismissOnEscape, TrapSelection, InitialSelection }` — Escape·게임패드 B는 맨 위의 해당
항목만 닫고(키 하나당 공유 연결 하나, 엔진이 이미 처리했거나 TextBox가 포커스면 Escape는 무시), 스크림은 `Selectable = false`,
열려 있는 동안 게임패드 선택은 그 항목 안에 갇히고(항목 Frame이 `SelectionGroup`이고 `SelectionBehaviorUp/Down/Left/Right = Stop` —
`GuiService:AddSelectionParent`는 폐기 예정이라 안 씀) 닫히기 시작하면 풀리면서 이전 선택으로 돌아옵니다. Menu는
위/아래 화살표·Return으로 항목을 탐색합니다. 아이콘은 `Icons`(Material Design Icons 이미지 기본, 이름마다 텍스트 글리프 폴백 — `Icons.override`로 교체·제거)에서 나옵니다.

## 날짜 선택기

```luau
local Calendar = Material.DatePicker.Calendar
local day = q.Source(Calendar.date(2026, 10, 5))

Material.DatePicker.Docked({ Value = day, FirstDayOfWeek = 1, Locale = "ko" })
Material.DatePicker.RangeDocked({ Start = s, End = e })
Material.DatePicker.Modal.open({ Value = day, UtcOffset = 9 * 3600, Overlay = overlay })
```

- **`Calendar`**: 윤년·요일·월 격자·클램핑·파싱·포맷이 전부 이 순수 모듈에 있고(`test/spec.pure.calendar.luau`) UI는
  날짜를 직접 계산하지 않습니다. 날짜는 얼어 있는 `{ Year, Month, Day }` 테이블이라 `Calendar.equals`로 비교합니다.
- **시간대**: UI에는 시간대가 없습니다. "오늘"은 `Calendar.today(nil, UtcOffset)`(UTC + 넘긴 초 단위 오프셋) 또는 `Today`
  prop이고, **기계의 시간대를 읽지 않습니다**(한국이면 `UtcOffset = 9 * 3600`).
- **로케일**: `"en"` / `"ko"`(`Locale` prop) — 머리글·요일 글자·패턴. 입력 모드는 ISO `YYYY-MM-DD`를 먼저 보이고
  `2026/10/5`, `2026.10.5`, `2026년 10월 5일`, 영어 월 이름도 받습니다.
- **`FirstDayOfWeek`**: 0 = 일요일(기본), 1 = 월요일, ...
- `Min`/`Max`/`IsDisabled`로 선택 가능한 날을 제한하고, 달력 키보드 이동을 지원합니다.

## 시간 선택기

```luau
local Clock = Material.TimePicker.Clock
local alarm = q.Source(Clock.time(7, 30))                    -- Source<Time>, Time = { Hour (0-23), Minute }

Material.TimePicker.Dial({ Value = alarm })                    -- 12 h, Vertical (272 x 396)
Material.TimePicker.Dial({ Value = alarm, Is24Hour = true, LayoutType = "Horizontal" })
Material.TimePicker.Input({ Value = alarm, Locale = "ko" })    -- 두 칸 입력(272 x 111)
Material.TimePicker.Modal.open({ Value = alarm, Overlay = overlay, OnConfirm = function(t) end })
```

- **정본**: Compose material3(`androidx/androidx@40ff481`의 `TimePicker.kt`·`TimePickerDialog.kt`·`tokens/TimePickerTokens.kt`·
  `tokens/TimeInputTokens.kt`)를 그대로 옮겼고, MDC와 다른 곳은 Compose를 따랐습니다(각 파일 머리에 줄 번호까지 인용).
  치수: 시/분 상자 96 x 80(DisplayLarge), 문자판 256(바깥 고리 101·안쪽 고리 69, 숫자 칸 48), 선택 원 48·선 2·가운데 점 8,
  AM/PM 토글은 Compose 현행(`isUpdatedTimepickerToggleEnabled` 기본 켬) — 4 px 떨어진 두 버튼, 쉴 때 알약·선택·누름은
  반경 12, 선택은 primaryContainer + 굵은 글자. 입력 칸 96 x 72(DisplayMedium), 아래 보조 문구 "Hour"/"Minute"(오류면 오류 문구).
- **값**: `Time`은 얼어 있는 `{ Hour, Minute }`(`Clock.equals`로 비교), Compose `TimePickerState.hour`/`minute`입니다.
  `Value`는 양방향 Source, `OnChange`는 사용자 조작(탭·끌기·키·AM/PM·입력)으로 바뀐 뒤에만. 바깥에서 쓰면 바늘이 바로 그 자리로.
- **문자판**: 탭은 시는 정시로, 분은 5분 단위로 맞추고 시를 고르면 0.1초 뒤 분으로 넘어갑니다. 끌면 바늘이 손가락을 그대로
  따라오고(분은 1분 단위), 놓으면 분으로 넘어가 값 자리로 미끄러집니다. 24시간은 안쪽 고리(12~23, 중심에서 74 px 안쪽을 누름).
  키보드·D-패드: 문자판을 선택한 채 ←/→가 이전/다음 숫자(Compose의 숫자 포커스 순서), ↑/↓는 옆 컨트롤로.
- **입력**: 숫자만, 두 자리까지(가득 찬 칸에 세 번째 숫자를 치면 그 숫자로 바뀜). 12시간은 AM/PM 토글의 오전/오후 안에서
  해석(12 → 0/12)하고 13은 오류("Hour must be 1–12"), 두 자리(또는 12시간에서 2~9 한 자리)가 유효하면 분 칸으로 넘어갑니다.
  오류 동안 값은 마지막 유효 값 그대로이고 모달의 OK가 꺼집니다.
- **모달**: 제목 "Select Time"/"Enter Time", 왼쪽 아래 전환 버튼(키보드 ↔ 시계 아이콘), Cancel/OK. 초안을 편집하다 OK에서만
  `Value`에 씁니다. `LayoutType`을 안 주면 Compose 규칙대로 오버레이 층이 가로로 길면 Horizontal(556 x 332), 아니면
  Vertical(320 x 528); 층 높이가 300 이하면 다이얼 없이 입력만. `DisplayMode = "Input"`이면 입력부터 열고 칸에 포커스를 줍니다.
- **시간대**: 모달의 기본값은 `Clock.now(nil, UtcOffset)`(UTC + 넘긴 초) — 기계의 시간대를 읽지 않습니다.

## 시트와 내비게이션 드로어

```luau
-- 표준 하단 시트: 화면 아래에 붙어 엿보고(56 px) 끌면 펼쳐짐
local sheet = Material.SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
Material.BottomSheetScaffold({ SheetState = sheet, SheetContent = q.Slot<<Instance>>({ ... }), Content = q.Slot<<Instance>>({ page }) })

-- 모달 하단 시트: Overlay에 열림
local handle = Material.ModalBottomSheet.open({ Children = q.Slot<<Instance>>({ ... }), Overlay = overlay, OnClose = function(r) end })

-- 측면 시트(MDC): 표준은 부모(ClipsDescendants) 가장자리에, 모달은 Overlay에
Material.SideSheet({ Headline = "Filters", Children = slot })
Material.ModalSideSheet.open({ Headline = "Details", Children = slot, Overlay = overlay })

-- 내비게이션 드로어: 화면을 감싸는 트리 안 레이아웃
local drawer = Material.DrawerState({ InitialValue = "Closed" })
local page = q.Source("inbox")
Material.ModalNavigationDrawer({
	DrawerState = drawer,
	DrawerContent = Material.ModalDrawerSheet({ Children = q.Slot<<Instance>>({
		Material.NavigationDrawerItems<<string>>({ Selected = page, Items = {
			{ Headline = "Mail" },
			{ Key = "inbox", Label = "Inbox", Icon = "rbxassetid://6035067831", Badge = "24" },
			"divider",
			{ Key = "trash", Label = "Trash" },
		} }),
	}) }),
	Content = q.Slot<<Instance>>({ screen }),           -- 그 안의 메뉴 버튼이 drawer.Open()
})
```

- **모달 시트의 `Children`은 간격 없이 세로로만 쌓입니다.** 시트 몸통은 `UIListLayout`(세로, `LayoutOrder`)이고 `Padding`을 주지 않습니다
  (`ModalSideSheet`·`SideSheet`는 몸통 바깥에 16 px 안쪽 여백만 있고, 하단 시트는 그것도 없음) — Compose의 시트 content가 간격 없는
  Column인 것과 같습니다. 자식 사이 간격이 필요하면 자식들을 `UIListLayout`(`Padding`)을 가진 자기 `D.Frame` 하나로 싸서 `Children`에 넣으세요.
- **시트는 내용을 스크롤하지 않습니다.** 내용이 시트보다 길면 `ScrollingFrame`으로 싸서 `Children`에 넣으세요. 측면 시트의 내용 영역은 시트 안쪽 16 px 여백 안이고, `Headline`을 주면 그 위에 머리글 줄(제목 + 닫기 버튼)과 24 px 간격이 먼저 놓입니다 — 안쪽에 좌우 여백을 한 번 더 주지 마세요.
- **연 시트는 그것을 연 화면의 수명과 묶이지 않습니다.** `ModalBottomSheet.open`·`ModalSideSheet.open`은 `Overlay`에 걸리므로, 연 화면을
  숨기거나 바꿔도 시트는 남습니다. 화면을 떠날 때 돌려받은 핸들의 `handle.Close()`를 부르세요.
- **정본**: 하단 시트·드로어는 Compose material3(androidx/androidx@40ff481 — `ModalBottomSheet.kt`·`BottomSheet.kt`·`BottomSheetScaffold.kt`·
  `SheetDefaults.kt`·`NavigationDrawer.kt`, 토큰 `SheetBottomTokens`·`NavigationDrawerTokens`), 측면 시트는 Compose에 없어 MDC
  (material-components/material-components-android@60ff094 `sidesheet/`), 드로어의 구획 제목·구분선도 MDC `NavigationView`. 줄 번호는 각 파일 머리.
- **하단 시트 기하**: 폭은 호스트 폭, 최대 640(가운데), 높이는 내용 + 손잡이 상자 48(32 x 4 막대), 최대 호스트 높이. 위 모서리 28(아래는
  같은 색 사각형으로 덮음 — UICorner는 반경 하나), surfaceContainerLow; 표준만 그림자(Level1). 멈출 자리: Hidden(호스트 아래),
  Expanded(시트 높이), PartiallyExpanded — 모달은 호스트 높이의 절반(짧은 시트면 Expanded와 같은 자리), 표준은 엿보기 높이.
  내용이 처음 배치되기 전에는 아무 자리도 없고, 첫 배치가 목표 자리로 바로 놓입니다(모달은 그 뒤 `Show` — 아래에서 올라옴).
- **끌기**: 시트 어디든, 손잡이에서도 — 단 시트 안의 버튼(목록 행 등) 위에서 누르면 그 버튼만 누름을 받아 끌기는 시작되지 않습니다
  (Roblox는 누름을 위에서부터 첫 GuiButton까지만 전합니다 — 2026-10-08 Studio 실측; Compose는 행에서도 끌림). 그래서 끌기는 면의
  투명 `ClickSink`(모든 하단 시트·모달 측면 시트·모달 드로어 홀더 — M3 Surface처럼 아래로 누름이 새지도 않음)와 손잡이·스크림이 받습니다.
  손잡이는 Compose처럼 리플·호버 층이 있고(정본 `Modifier.clickable`의 기본 표시), 끌기가 시작되면 누름이 취소됩니다. 놓으면 Compose `computeTarget` — 움직임 방향으로 속도가 125 px/s 이상이면 다음 자리, 아니면 시작
  자리에서 56 px(하단 시트) 이상 멀어졌을 때만 다음 자리. 드로어는 거리의 절반·400 px/s, 측면 시트는 MDC 규칙(바깥쪽으로 움직이면 펼침,
  500 px/s 넘는 가로 스와이프나 절반 넘게 밀었으면 숨김). 터치 슬롭 8 px 안의 누름은 클릭으로 남습니다. 끄는 동안 바깥
  ScrollingFrame은 멈춥니다.
- **움직임**: Compose는 스프링(DefaultSpatial / FastEffects)인데 키트는 트윈이라 1 % 수렴 시간에 가까운 토큰으로 — 보이기·끌고 놓기 0.2 s,
  숨기기 0.1 s(Standard), dismissible 드로어의 끌고 놓기 0.256 s, 측면 시트는 MDC 애니메이션 275 ms Emphasized. 스크림 페이드는 Short4.
- **모달 하단 시트**: 스크림은 시트 자신의 것(목표가 Hidden이 아니면 0.32, 끌어 내리다 Hidden으로 향하면 바로 옅어짐); Overlay 항목이
  게임패드 선택 가두기와 Escape 배관을 맡고 Escape/B는 Compose `settleToDismiss`(Expanded면 PartiallyExpanded로 한 단계, 아니면 숨기고 닫음).
  손잡이 클릭: Expanded → 숨기고 닫음, PartiallyExpanded → 펼침, Hidden → 보임. `ConfirmValueChange`가 Hidden을 거부하면 스크림·손잡이·끌기는
  닫지 않습니다(`handle.Close()`는 닫음).
- **드로어**: 레이아웃이라 Overlay 항목이 아닙니다 — 호스트가 부모를 채우고 자릅니다(닫힌 드로어는 왼쪽 가장자리 밖). 모달 스크림
  투명도는 드로어 위치를 따라가고(열림 비율 x 0.32), 열려 있을 때만 탭으로 닫힘(제스처가 켜져 있을 때). Escape/B는 Overlay의 공용 스택
  (`Overlay.onEscape`)에 올라가 위에 뜬 다이얼로그가 먼저 받습니다. 닫혀 멈춰 있는 동안 드로어·스크림은 아예 안 보입니다(게임패드
  선택이 들어가지 않음). Compose는 내용 위 어디서나 끌어 열 수 있지만, 키트는 내용에서 끌기를 시작하지 않습니다 — 버튼(앱 바의 메뉴
  아이콘 `Icons` "menu")으로 여세요.
- **측면 시트**: 표준은 부모 끝(오른쪽, `SheetEdge = "Start"`면 왼쪽)에 붙고 숨으면 폭만큼 밖으로 — 부모가 `ClipsDescendants`여야 합니다.
  `SheetState`의 값은 `Hidden`/`Expanded` 둘(MDC STATE_HIDDEN / STATE_EXPANDED) — PartiallyExpanded를 켠 상태를 주면 에러.

## 내비게이션 바·레일·앱 바·툴바

```luau
local page = q.Source("home")
local items = {
	{ Key = "home", Label = "Home", Icon = "rbxassetid://6026568195" },
	{ Key = "saved", Label = "Saved", Icon = "rbxassetid://6022852108", Badge = "3" },
}
-- 세로로 긴 화면: 아래 내비게이션 바
Material.ShortNavigationBar<<string>>({ Selected = page, Items = items })
-- 넓은 화면: 레일(머리의 메뉴 버튼으로 펼치고 접기)
local rail = Material.WideNavigationRailState()
Material.WideNavigationRail<<string>>({ State = rail, Selected = page, Items = items,
	Header = Material.IconButton({ Icon = Material.Icons.asset("menu") or "", TouchTarget = true, OnClick = rail.Toggle,
		Modifier = q.Declaration.Modifier.TextButton():Position(UDim2.fromOffset(24, 0)) }) })

-- 앱 바 + 스크롤: Scaffold에 바를 주고, 목록은 내용 영역(바의 지금 아래 끝부터)을 채우며 innerPadding.Top을 위 여백으로
local scroll = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
Material.Scaffold({
	TopBar = Material.MediumFlexibleTopAppBar({ Title = "Inbox", Subtitle = "3 unread", ScrollBehavior = scroll,
		NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = drawer.Open },
		Actions = { { Icon = "rbxassetid://6031154871", Label = "Search", OnClick = search } } }),
	Content = function(innerPadding)
		return q.Declaration.ScrollingFrame { Size = UDim2.fromScale(1, 1), scroll.Hook,
			q.Declaration.UIPadding { PaddingTop = innerPadding.Top }, … }
	end,
})

-- 떠 있는 툴바
Material.HorizontalFloatingToolbar({ Expanded = expanded, Content = { … }, FloatingActionButton = { Icon = "…", OnClick = add } })
```

- **정본**: Compose material3(androidx/androidx@40ff481 — `ShortNavigationBar.kt`·`WideNavigationRail.kt`·`WideNavigationRailState.kt`·
  `NavigationItem.kt`·`Badge.kt`·`AppBar.kt`·`AppBarRow.kt`·`AppBarDsl.kt`·`FloatingToolbar.kt`, 토큰 `NavigationBar*Tokens`·
  `NavigationRail*Tokens`·`BadgeTokens`·`AppBar*Tokens`·`BottomAppBarTokens`·`DockedToolbarTokens`·`FloatingToolbarTokens`), MDC 문서
  (material-components/material-components-android@60ff094 `docs/components/` — 어느 쪽이 지금 정본인지). 줄 번호는 각 파일 머리.
- **어느 모양인가**: 바·레일은 M3 Expressive 판(MDC 문서가 지금 것으로 적은 쪽 — 바 80 → 64, 레일은 접힘 96 / 펼침이 드로어를 대신함)만
  넣었습니다. Compose의 옛 `NavigationBar`(80)·`NavigationRail`(80)은 없습니다. 위 앱 바는 Compose가 여섯 다 내보내므로 여섯 다(MDC는
  medium·large를 flexible로 대체 예정이라고 적음), 하단은 `BottomAppBar`와 `FlexibleBottomAppBar`(= MDC docked toolbar).
- **선택 표시**: 바·레일 항목의 아이콘·글자 색은 애니메이션하지 않고(Compose `animateColor = false`) 알약만 움직입니다 — 폭이 0에서 제
  폭까지(바: 가운데에서, 레일: 왼쪽 끝 20에서) 알파와 함께 0.2 s. 레일 항목 글자 색만 Compose처럼 애니메이션. 상태 레이어·리플은 알약
  전체(항목 전체가 아님), 클릭은 항목 전체.
- **레일 펼치고 접기**: 하나의 진행값이 폭·항목 높이(64 → 56)·간격(4 → 0)·알약 크기(56 x 32 → 56 높이 가로 알약)·아이콘 위치를 함께
  움직이고, 글자는 절반에서 자리·크기(LabelMedium → LabelLarge)를 바꾸며 사라졌다 나타납니다(Compose `placeAnimatedLabelAndIcon`).
  펼친 폭은 재어 둔 글자 폭으로 정합니다(가장 넓은 항목 + 20, 220~360).
- **앱 바 스크롤**: Roblox ScrollingFrame은 스크롤을 부모에게 넘길 수 없어서(중첩 스크롤 없음) 바가 스크롤을 "먹지" 않고 같이
  접힙니다. 행은 Compose Scaffold처럼 움직여야 하고(첫 행이 접히는 바의 아래 끝에 붙어 감) ScrollingFrame은 바 뒤에 두면 안 됩니다
  (Roblox 스크롤바가 프레임 전체 높이에 걸려 바에 가려짐 — 두 줄 바의 목록 맨 위에선 통째로). **이 배치는 `Material.Scaffold`가
  합니다**(아래 "스캐폴드" 절): 바를 `TopBar`로 주고, `Hook`을 꽂은 목록에 `innerPadding.Top`을 위 여백으로 주면 끝입니다. 갤러리의
  세 화면과 AppBar·Scaffold 스토리가 이 모양. Scaffold 없이 직접 짤 때만: ScrollingFrame을 바의 지금 아래 끝(`top` = 펼친 높이 +
  `State.HeightOffset`, 반올림)에서 시작시키고 높이는 화면 − `top`, 위 여백은 펼친 높이 − `top`(캔버스가 프레임과 같은 만큼 늘고 줄어
  최대 스크롤이 그대로라 CanvasPosition이 튀지 않음 — Studio 실측 2026-10-08). 어느 쪽이든 바 위에서 굴린 휠은 목록에 닿지 않습니다
  (목록이 바 아래에 없음). 스크롤이 0.1 s 멈추면(왼쪽 마우스 버튼이 떼어진 뒤 — 스크롤바 엄지를 잡은 채
  멈춘 것은 아직 스크롤 중) 중간에 걸린 바는 가까운 쪽 끝으로 0.2 s(Compose `settleAppBar`). 이때 **CanvasPosition도 같은 만큼 같이
  움직입니다** — Compose에선 바가 스크롤을 먹어 목록 자체 스크롤이 그대로이고 여백이 바를 따라가 정착한 바가 틈을 남기지 않는데,
  여기선 행이 바를 따라가지 않으므로 캔버스 + `HeightOffset`을 그대로 두도록 캔버스를 옮깁니다(exitUntilCollapsed는 맨 위 근처에서 0
  또는 접힘 범위로, enterAlways는 첫 행이 바 아래 끝에 붙은 채). 목록이 접힘 범위만큼 스크롤되지 못하면(짧은 목록) 접는 대신
  펼칩니다. 정착 도중의 휠·끌기·스크롤바는 정착을 바로 멈춥니다. 바를 직접 끌어 접기·플링 감속은 없습니다.
- **두 줄 바의 큰 제목**은 마지막 기준선이 아래에서 24(medium)/28(large) — 기준선은 Roboto 지표(ascender 0.928 em, descender
  0.244 em)로 근사했습니다(Roblox는 글꼴 기준선을 알려 주지 않음).
- **오버플로**: 액션이 `MaxItemCount`보다 많으면 `MaxItemCount - 1`개 + 더보기(⋮, `Icons` "moreVert") 버튼, 나머지는 Menu로. Compose는
  폭을 재서도 넘기지만 키트는 개수만 셉니다.
- **툴바**: 64 두께·모서리 완전 둥글게·안쪽 여백 8, 그림자 없음(FAB 형만 펼쳤을 때 Level1). 펼침 0.15 s(Compose FastSpatial 스프링의
  근사). FAB 형은 툴바와 FAB 사이 8, 펼침 FAB 56 / 접힘 80, 툴바는 FAB 쪽으로 줄어듭니다.

## 스캐폴드(Scaffold)

```luau
local snackbarLayer = Material.Overlay.new()                          -- Compose: snackbarHost = { SnackbarHost(state) }
local snackbars = Material.Snackbar.new({ Overlay = snackbarLayer })  -- Compose: SnackbarHostState
local scroll = Material.TopAppBarDefaults.enterAlwaysScrollBehavior()
Material.Scaffold({
	TopBar = Material.TopAppBar({ Title = "Inbox", ScrollBehavior = scroll }),
	BottomBar = Material.ShortNavigationBar<<string>>({ Items = items, Selected = page }),
	FloatingActionButton = Material.FAB({ Icon = "rbxassetid://6035047377", OnClick = function()
		snackbars:Show({ Text = "Draft saved" })
	end }),
	FloatingActionButtonPosition = "End",                              -- "Start" | "Center" | "End" | "EndOverlay"
	SnackbarHost = snackbarLayer.Layer,
	Content = function(innerPadding)                                   -- 또는 GuiObject 하나(여백이 필요 없을 때)
		return q.Declaration.ScrollingFrame { Size = UDim2.fromScale(1, 1), scroll.Hook,
			q.Declaration.UIPadding { PaddingTop = innerPadding.Top }, … }
	end,
})
```

- **정본**: Compose material3 `Scaffold.kt`(androidx/androidx@40ff481 — 86-119 함수, 133-306 `ScaffoldLayout`: 178 `topBarHeight`,
  195-225 FAB 가로 자리, 234-244 `fabOffsetFromBottom`, 246-254 `snackbarOffsetFromBottom`, 256-269 내용 `PaddingValues`,
  276-304 배치·373-377 z 순서; 316-356 `FabPosition`, 369-370 `FabSpacing` 16). 줄 번호는 `src/Scaffold.luau` 머리에도.
- **props**: `Content`(필수 — `GuiObject` 또는 `(innerPadding: PaddingValues) -> GuiObject`, 내용 영역 안에 놓이니 Size 1, 1로),
  `TopBar`·`BottomBar`·`SnackbarHost`·`FloatingActionButton`(전부 `GuiObject?`), `FloatingActionButtonPosition`(`FabPosition?`, 기본
  End), `ContainerColor`(기본 background), `Theme`·`Modifier`(Frame)·`Hooks`. 호스트 Frame은 부모의 100 %.
- **내용 자리 — Compose와 다른 곳**: Compose는 내용을 바 **뒤** (0, 0)에 두고 `PaddingValues(top = 위 바 높이, bottom = 아래 바
  높이)`를 넘깁니다. Roblox 스크롤바는 프레임 전체에 걸리고 위·아래 끝을 띄울 수 없어서, 키트는 내용을 **위 바의 지금 아래 끝부터
  아래 바의 위 끝까지의 영역**(`Body`)에 놓습니다 — 스크롤바가 어느 바에도 가리지 않음. 그래서 `innerPadding`은 `Top` 하나뿐이고 그
  값은 **키트 위 앱 바가 접힌 만큼**(펼친 높이 − 지금 높이; 고정 바·키트 밖의 바·바 없음은 0)입니다 — 스크롤 동작의 `Hook`을 꽂은
  목록이 이걸 위 여백으로 받으면 행이 Compose의 바-뒤 배치와 같은 자리에 오고 캔버스가 영역이 준 만큼 늘어 CanvasPosition이 튀지
  않습니다. `Hook`은 Compose처럼 호출자가 꽂습니다(`Modifier.nestedScroll(...)` 자리 — Scaffold는 스크롤 동작을 받지 않음).
- **바 높이**: 키트 위 앱 바는 자기 펼친 높이와 지금 높이(크기가 따르는 같은 State)를 Scaffold에 알려 줘서 영역이 접히는 바와 같은
  프레임에 움직입니다. 그 밖의 바(키트 아래 바 포함)는 `Size.Y.Offset`으로 읽고 Size 변경 신호로 따라갑니다 — AutomaticSize나 Scale
  높이 바는 offset만 읽히니 픽셀 높이를 주세요. Scaffold가 위 바를 (0, 0)에, 아래 바를 AnchorPoint (0, 1)·Position (0, 0, 1, 0)에
  한 번 써서 놓습니다.
- **FAB**: 가장자리에서 16(`FabSpacing`, Start / End) 또는 가운데(Center), 아래 끝이 아래 바 위 끝에서 16 위 — `EndOverlay`(그리고
  아래 바가 없을 때)는 Scaffold 아래 끝에서 16 위, 아래 바 위에 겹침.
- **스낵바**: `SnackbarHost`는 `Overlay.new()`의 `Layer`를 받아 FAB이 있으면 FAB 위 끝까지, 없으면 아래 바 위 끝(또는 바닥)까지의
  영역에 놓고, 그 Overlay에 묶인 `Snackbar.new` 호스트가 그 안 가운데 아래(호스트 `BottomOffset` 기본 16 — Compose Snackbar는 자기
  여백 12)에 띄웁니다.
- **z 순서**: 내용·바는 기본 ZIndex(겹치지 않음), FAB·스낵바 층은 그 위 한 프레임(ZIndex 2). Compose는 스낵바가 아래 바 밑이라
  아래 바 위로 미끄러져 들어올 때만 다르게 보일 수 있음.
- **없는 것**: `contentColor`(Roblox엔 물려받는 내용 색이 없음 — 컴포넌트마다 자기 역할), `contentWindowInsets`(안전 영역은
  ScreenGui의 `ScreenInsets`가 맡음), 오른쪽→왼쪽 배치, 아래 바 스크롤 숨김(`BottomAppBarScrollBehavior`).
- **인스턴스**: Scaffold + Body = 2, FAB이나 스낵바 자리가 있으면 + Floating 1, FAB이 + UIPadding·UIListLayout 2, FAB 옆 스낵바 자리가
  + SnackbarHost Frame·UIFlexItem 2 — 자기 것 최대 7. 키트 위 앱 바엔 연결 0, 다른 바마다 Size 신호 1, 매 프레임 일 없음.

## 색상 선택기

```luau
local brand = q.Source(Color3.fromRGB(103, 80, 164))
Material.ColorPicker.Panel({ Value = brand, Swatches = { ... } })
Material.ColorPicker.Modal.open({ Value = brand:Get(), Title = "Brand color", OnConfirm = function(c) brand:Set(c) end, Overlay = overlay })
```

- **상태 모델**: 패널의 단 하나의 진실은 **`Source<HSV>`**입니다. `Value: Source<Color3>`를 넘기면 Effect 하나가 둘을
  동기화하고(바깥에서 쓴 값과 자기 되울림을 구분), 색상(H)을 손해 없이 쓰려면 `HSV: Source<HSV>`를 직접 넘깁니다. 둘 다
  넘기면 오류입니다.
- **색상 보존**: 검정·회색에는 색상이 없습니다. Color3만 상태로 두면 사용자가 검정 가장자리를 건드릴 때 색상 슬라이더가
  빨강으로 튑니다(원본 선택기의 버그). HSV를 상태로 두면 검정·회색을 지나도 H와 S가 남습니다.
- **Modal**: 임시(draft) 값을 편집하다가 OK에서만 바깥에 반영합니다. Cancel·스크림·Escape는 draft를 버립니다.
- **원본 선택기**: 이 선택기의 출발점이 된 작성자의 원본 OOP 선택기 분석(구조·에셋·결함)은
  [`docs/colorpicker-original-analysis.md`](docs/colorpicker-original-analysis.md)에 있습니다.

## M2 모양

`Slider`·`RangeSlider`·`Switch`의 기본은 M3 모양이고, Material 2 모양은 `Style` prop이 아니라 별도 이름으로 씁니다 —
`Material.M2.Slider`·`Material.M2.RangeSlider`·`Material.M2.Switch`(`src/M2/`). props와 동작(값·드래그·키보드·게임패드·
눈금·`OnChange`/`OnChangeEnd`, Switch의 `Value`/`Checked`·탭·드래그)은 공용 동작 모듈(`src/Slider/Behavior.luau`,
`src/Switch/Behavior.luau`)이 한 벌로 갖고, 모양 파일은 그림(트랙·핸들·치수)만 가집니다 — M3 컴포넌트 안에 M2 분기가
없습니다. 그래서 같은 입력(같은 레일 위치의 누름·이동, 같은 키)은 두 모양에서 같은 값과 콜백을 냅니다(`test/spec.slider.luau`·
`test/spec.rangeslider.luau`의 "shared behaviour" 절). 다른 점은 그림과 그에 딸린 치수뿐입니다: 슬라이더 기본 높이(M3 44, M2 40),
핸들 중심이 끝에서 떨어진 거리(M3 8, M2 10 — 포인터 → 값 변환이 이 값을 씀), M2 Switch는 호스트가 56x40(halo까지 안에
들어가게)이고 썸에 아이콘이 없습니다(`IconOn`/`IconOff`는 받지만 무시).
M3 슬라이더의 변형(`Size`·`Orientation`/`TopToBottom`·`Centered`·안쪽 아이콘 — 2026-10-08)은 M2 쪽에 없습니다: MDC 문서가 이것들을
"M3 Expressive" 구성(Orientation·inset icon·Sizes XS~XL, centered는 그 문서의 세 갈래 중 하나)으로 소개하고 M2 슬라이더(MDC
`Widget.MaterialComponents.Slider`)에는 그 스타일·토큰이 없습니다. 동작 모듈은 축(가로/세로)·뒤집기·중점 시작값을 받게 됐지만
M2 모양은 넘기지 않으므로 M2의 동작은 그대로입니다.

```luau
local Material = require("<이 폴더>/src")
Material.Slider({ Value = volume, Min = 0, Max = 100 })        -- M3
Material.M2.Slider({ Value = volume, Min = 0, Max = 100 })     -- M2, 같은 Source를 나눠 써도 됨
Material.M2.Switch({ Value = wifi })
```

## 갤러리

```luau
local Gallery = require("<이 폴더>/gallery")
Gallery.mount()                -- PlayerGui에 ScreenGui를 만들어 갤러리 + 자기 소유 오버레이 층을 올림
Gallery.mount(someParent)      -- 부모를 직접 지정
Gallery.GalleryPanel({})       -- 페이지(Frame)만; 직접 호스트할 때. Overlay를 안 주면 자기 층을 만들어 안에 놓음
```

위쪽 `Tabs`로 아홉 구간(Buttons / Selection / Text / Surfaces / Overlays / Navigation / Chips / Pickers / Theme)을 오가고, 각
컴포넌트가 실제 상태(비활성·오류·선택 변형 포함)로 동작하며 Theme 탭의 스위치가 `Theme.default`의 light/dark를 바꿉니다.
구간은 **탭을 고를 때 만들고 떠나면 부숩니다**(숨겨 두지 않음) — Pickers 하나가 수백 개이고 비확정 진행바가 Heartbeat
루프를 돌기 때문입니다. 사용자가 입력·조작한 값은 패널의 Memo(Source)에 있어 다시 돌아와도 남습니다. 갤러리는 키트의 일부가 아니라 **키트를 쓰는 소비자**라서 `src` 밖 `gallery/`에 둡니다 — `src` 안에 있으면 키트와 함께 게시돼 보통의 사용 경로에선 아무도 부르지 않는 코드가 모든 설치본에 실립니다. 그래서 갤러리는 게임이 키트를 쓰는 방식 그대로, 루트 내보내기 표 하나(`require("<이 폴더>/src")` → `Material.Button` 같은 값, `Material.Theme`·`Material.Tab<K>`·`Material.ButtonVariant` 같은 다시 내보낸 타입)와 자기 설정 모듈(`gallery/Quad.luau`)만 씁니다. Studio 진입 스크립트 `gallery/MaterialGallery.client.luau`도 같은 폴더에 있습니다(아래 "Studio에서 보기").

스펙이 센 인스턴스 합계(`test/spec.gallery.luau`, 패널 뼈대 — 루트·탭·스크롤 — 포함; 2026-10-08 시트·드로어 처리에서 Navigation 탭이
더해져 모든 탭이 탭 버튼 하나(8)만큼 늘었다 — 아래 숫자는 그 앞의 값, 지금 값은 Buttons 657 · Selection 1355 · Text 276 · Surfaces 335 ·
Overlays 335(하단·측면 시트 묶음 둘: 모달 버튼과 흉내 화면 속 표준 시트) · Navigation 1221(드로어 셋 + 2026-10-08 바 둘·레일·스크롤
하는 앱 바 셋·쉬는 앱 바 넷·하단 앱 바 둘·툴바 셋 — 흉내 화면 열셋 더; 드로어만일 때 498; 같은 날 Scaffold로 옮긴 뒤 1221(이 줄의 앞 기재는 1190) —
바 화면·앱 바 화면마다 Scaffold + Body, 폰 바 화면의 FAB·스낵바 층, 하단 앱 바 둘이 화면 하나씩으로 갈라짐) · Chips 521 ·
Pickers 950(2026-10-08 Classic 색상 선택기 묶음을 빼며 1037 → 950; 같은 날 다시 센 Selection·Overlays는 앞 기재 1345·334에서 1355·335) · Theme 205): Buttons 649(10차에 "Button: icons —
leading / trailing"·"SplitButton" 묶음 추가 — 분할 버튼 하나가 쉴 때 40), Selection 1337(맨 위 "Slider / Switch — M3 vs M2" 비교
묶음 옆에 10차 "Slider variants (M3)" 묶음 — 크기 다섯·가운데 정렬·안쪽 아이콘·세로 넷),
Text 268, Surfaces 327, Overlays 199, Chips 513, Pickers 1029, Theme 197(Chips·Pickers는 2026-10-08 9차에 내장 아이콘이
글리프에서 이미지로 바뀌며 늘었다 — `GlyphButton` 이미지 경로가 글리프보다 둘 많음; Pickers는 10차에 날짜 선택기 머리의
▼▲가 버튼의 뒤 아이콘 이미지가 되며 머리마다 둘(이미지 + UIListLayout) 늘었고, 시간 선택기 묶음 셋(문자판 12 h 90 + 24 h 101,
입력 12 h 24 + 24 h 11, 모달 버튼 셋)이 더해져 756 → 1029). 아이콘 데모는
`Icon` prop(기본값은 장치에서 확인 못 한 자리표시 에셋 id)을 본인 에셋으로 바꿔 보세요.

## UI Labs / 입력 주입

UI Labs(Studio 플러그인)는 스토리를 플러그인 DockWidget 안에 그리는데, 거기서는 `UserInputService`가 입력을 받지 못합니다.
UI Labs가 스토리에 주는 `Environment.InputListener`(`InputBegan`/`InputChanged`/`InputEnded` + `MouseMoved`)로 갈아 끼울 수
있도록, 키트가 입력을 만지는 자리(Interaction 드래그, KeyNav, Overlay, Menu, 앱 바 정착의 버튼 누름 확인)는 전부 `src/Input.luau`의
`Input.service()`를 **쓰는 순간에** 읽습니다. 스토리는 `stories/StoryKit.luau`가 렌더 때 자동으로 설치합니다.

```luau
local Material = require("@pkg/quad-roblox-material")
Material.Input.use(Environment.InputListener)  -- 스토리 모드: 리스너로 교체
Material.Input.use(nil)                         -- 엔진 서비스로 복원
```

- 교체 중에는 `GetMouseLocation()`이 마지막 `MouseMoved` 위치를, `IsMouseButtonPressed`가 리스너가 본 `InputBegan`/`InputEnded`로
  센 버튼 상태를 돌려주고(위젯 안에선 엔진이 늘 "안 누름"이라 답함), `MouseIconEnabled = false` 같은 쓰기는 엔진에
  닿지 않으며(로컬에 저장), `GetFocusedTextBox`·`GetLastInputType` 등 나머지 멤버는 엔진 서비스로 넘어갑니다.
- `GuiService`의 선택·게임패드 API(`SelectedObject`, 선택 부모 등)는 대체물이 없어 그대로입니다 — **게임패드/선택 동작은
  플레이 모드에서만 확인됩니다.**
- 주입 전역을 찾을 때는 자기 함수 환경을 읽는 `getfenv()`를 써야 합니다. `pcall(getfenv, 1)`은 레벨 1이 pcall(C 함수)이라
  스레드의 전역(UI Labs 플러그인 자신의 것)을 돌려줘서 주입을 못 찾습니다 — 2026-10-08까지 StoryKit이 이 실수로 리스너를
  설치하지 못해 스토리 안 드래그가 전부 안 됐습니다.

## Studio에서 보기 — UI Labs 스토리와 플레이 테스트

레포 루트의 `consumer-kits.project.json`이 ReplicatedStorage에 quad-base·quad-roblox·두 킷을 레포 폴더 모양 그대로 올리고,
킷의 `gallery/*.client.luau` 진입 스크립트 하나만 StarterPlayerScripts에 넣는다(`src`와 `gallery`가 레포와 같은 상대 위치에 있어 상대 require가 Studio에서도 같은 경로로 풀린다; ReplicatedStorage의 `gallery` 사본에서는 `globIgnorePaths`로 진입 스크립트를 뺀다).

1. 터미널에서 `rojo serve consumer-kits.project.json --port 34872`, Studio의 Rojo 플러그인에서 그 포트로 연결.
2. **스토리(편집 모드)** — UI Labs 플러그인을 연다. 탐색기에 storybook **"quad · Material 3"**(`ReplicatedStorage/quad-roblox-material/stories/Material.storybook`)이
   보이고, 그 아래 `*.story` 모듈마다 항목이 하나씩 있다. 항목을 열면 오른쪽 Controls 패널이 뜬다 — 패널의 값 하나하나가
   스토리 안에서 `q.Source` 하나이고(`stories/StoryKit.luau`), 컴포넌트는 앱에서 쓰는 그대로 그 Source를 받는다. 값을 바꾸면
   다시 그리지 않고 바인딩만 갱신된다.
3. **플레이 테스트** — Play(F5). StarterPlayerScripts의 `MaterialGallery` LocalScript(`gallery/MaterialGallery.client.luau`)가 PlayerGui에 Gallery(탭으로 전 컴포넌트)을 띄운다. 게임패드·선택(GuiService)·
   Escape·GUI inset처럼 플러그인 위젯에서 재현되지 않는 것은 여기서 본다 — 아래 체크리스트.

UI Labs 안에서는 `UserInputService`가 입력을 받지 못한다. StoryKit이 UI Labs가 주입하는 환경(`InputListener`)을 킷의
`Input.use`로 끼워 넣고 정리 때 되돌린다(위 "UI Labs / 입력 주입"). 제3자 코드(ui-labs-utils)는 들이지 않았다 — 같은 원시
전역(`__hotreload_env_global_injection__`)을 StoryKit이 직접 읽는다. 고급 컨트롤(`StoryKit.Slider`/`Choose`)도 ui-labs-utils가
만드는 데이터 모양을 그대로 만든 평범한 테이블이다(문서화된 API가 아니라 UI Labs 업데이트 때 깨질 수 있는 유일한 자리).

### 실기기 체크리스트 (관측 칸은 비워 둠 — Studio에서 채울 것)

Lune mock은 레이아웃·렌더·엔진 입력 순서를 흉내 내지 못한다. 아래는 스펙으로는 확인할 수 없어 Studio에서 봐야 하는 것들이다.

| # | 볼 것 | 어디서 | 기대 | 관측 |
|---|---|---|---|---|
| 1 | UIShadow 렌더(엘리베이션 0~5) | 스토리 Card·Button(Elevated)·Menu / 플레이 | 레벨별로 그림자가 보이고 UICorner를 따라 둥글다 |  |
| 2 | UIShadow가 CanvasGroup 안에서 잘리는지 | Dialog·Snackbar·DatePicker 모달 | 그림자 없음(의도) — 다른 곳은 보임 |  |
| 4 | Roboto 글꼴·굵기(Medium 500) | Theme 스토리·Gallery | LabelLarge/TitleMedium이 Medium으로 보임 |  |
| 5 | 내장 아이콘 이미지(Material Design Icons — `Icons.luau` 머리의 id 열둘)와 남은 글리프(TextField 에러 !) | Select 화살표·DatePicker ‹ ›·머리의 연도 메뉴 화살표(▼/▲ 이미지)·모달 모드 전환(연필 ↔ 달력)·시간 선택기 모달 전환(키보드 ↔ 시계)·Chip 체크·제거·Snackbar 닫기·색상 선택기 스와치 체크·분할 버튼 화살표 | 이미지가 뜨고(물음표 상자·빈칸 아님) 테마 색으로 물듦, 크기가 글자 자리와 어울림; !는 두부(□)로 안 나옴 |  |
| 6 | UICorner 0.5 스케일 = 완전한 알약 | Button·Chip·Switch | 양 끝이 반원 |  |
| 7 | Filled TextField 위쪽만 둥근 모서리 | TextField(Filled) | 아래 모서리는 각지고 표시선이 안 삐져나옴 |  |
| 8 | 버튼 폭 — 기본(글자에 맞춤)은 처음부터 맞는 폭이고 호버·클릭에 폭이 안 바뀜, `Width` 지정은 라벨이 가운데 | Button 스토리·갤러리 Buttons(고정 폭 묶음)·Theme(Brand outlined) | 글자가 안 삐져나오고 상호작용 뒤에도 폭 그대로 |  |
| 9 | Card 고정폭에서 자식 폭 | Card 스토리 | Content가 카드 폭을 따라감(알려진 위험) |  |
| 10 | 리플 시작점 = 누른 위치(GUI inset) | Button을 가장자리에서 누름 | 원이 손가락/커서 위치에서 시작 |  |
| 11 | 게임패드 선택 링(포커스 표시) | 플레이: 게임패드로 이동 | 3px Secondary 링, 엔진 기본 상자 없음 |  |
| 12 | 오버레이 선택 가두기(SelectionGroup) | 플레이: Dialog/Menu 열고 D-패드 | 선택이 오버레이 밖으로 안 나가고 닫으면 원래 자리로 |  |
| 13 | Escape / B 닫기 | 플레이: Dialog·Menu·DatePicker 모달 | 맨 위 하나만 닫힘, TextBox 입력 중 Escape는 무시(코어 메뉴와 겹침 확인) |  |
| 14 | Slider·색 SV·hue 키 조작 | 플레이: 선택 후 화살표/D-패드 | 값이 바뀌고 SV는 A로 잠금/해제 |  |
| 15 | 날짜 격자 D-패드 이동과 L1/R1 | 플레이: DatePicker | 격자 밖으로 나갈 수 있고 L1/R1이 달을 넘김, 숨은 칸에 안 감 |  |
| 16 | Tooltip 위치 | Tooltip 스토리 / 플레이 | 커서 근처(위아래로 36px 어긋나지 않음) |  |
| 17 | 작은 화면에서 Dialog 스크롤·모달 축소 | 플레이: 창을 작게 | 본문 스크롤, 액션 버튼 고정, 모달이 화면 안; 색상 선택기 모달은 스크롤 대신 카드째 작아져 화면 안(Dialog `Fit`) |  |
| 18 | Deferred 시그널 파괴 순서 | 플레이: ScreenGui를 지우고 같은 프레임에 다시 만듦 | 에러 없음(Quad0219 없음), 팝업 고아 없음 |  |
| 19 | Progress 무한 애니메이션 부하 | Progress 스토리 / 플레이 | 보이는 동안만 돌고 숨기면 멈춤 |  |
| 20 | Snackbar 호버 시 타이머 멈춤 | Snackbar 스토리 | 커서를 올리면 사라지지 않음 |  |
| 21 | Radio 스프라이트(에셋 4667411351) | Radio 스토리·갤러리 Selection | 링·점이 또렷하고 테마 색으로 물듦, 선택 때 외곽이 안쪽으로 붙으며 점이 차오르는 10프레임 모션 |  |
| 22 | Checkbox 토글 모션 | Checkbox 스토리 | 체크: 가장자리 막대가 오므라들었다가 가운데부터 체크가 드러남 / 해제: 채움이 접혀 들어감 |  |
| 23 | 라벨 연동(label-for) | Checkbox 스토리 "Label"·갤러리 Selection | 라벨 위 호버가 상자 상태 레이어를 켜고, 라벨 클릭이 토글, 리플은 상자 가운데에서 |  |
| 24 | 누르는 동안 크기가 안 변함(리플이 호스트 밖으로 안 나감) | 버튼·칩(특히 칩)·DatePicker 연도 전환 버튼·가로 RadioGroup·Switch·Dialog 버튼 | 누르는 동안 폭·높이·옆 요소 위치가 그대로, 리플이 원으로 시작해 칩 위아래에 잘린 원 모양으로 자라다 호스트를 덮음(알약·타원이 아님) |  |
| 25 | Checkbox 토글 중 모양 | Checkbox 스토리 | 외곽선만 2px씩 살짝 부풀고, 오므리는 막대는 외곽선 안쪽 — 상자가 각진 네모로 보이지 않음 |  |
| 26 | TextField 아무 곳 클릭 포커스 | TextField 스토리(Filled·Outlined) | 라벨·여백·아이콘 위를 눌러도 입력이 시작됨 |  |
| 27 | 범위 날짜의 반쪽 띠 | DatePicker 스토리 Range·갤러리 Pickers | 시작·끝 원 아래 반 폭 띠가 사이 띠와 이어짐(틈 없음) |  |
| 28 | Dialog 닫힘 | Dialog 스토리 | DatePicker 모달처럼 살짝 작아지며 사라짐, 버튼·바닥 여백이 안 커짐 |  |
| 29 | LoadingIndicator·WavyProgress | Progress 스토리·갤러리 Chips | 모양이 650ms마다 바뀌며 돌고, 물결이 흐르며 막대가 참 — 물결 선이 또렷한지(시트 칸 Stretch), 파장 이음매·흐름 끊김이 안 보이는지; 양 끝 둥근 캡이 선 위에 붙어 함께 오르내리는지(채움이 바뀌는 동안에도), 0 % 근처에서 점 하나로 줄었다 사라지는지; 100 %·`Wavy = false`에서 물결이 부드럽게 잦아들어 직선이 되고 다시 켜면 부풀어 오르는지(시트 칸 경계에서 이웃 칸이 번져 보이지 않는지) |  |
| 30 | (삭제됨 2026-10-08 — Classic 색상 선택기를 키트에서 뺐다) | | | |
| 31 | CircularProgress 원호 조각(시트 `rbxassetid://97823357785454`) | Progress 스토리(두께 넷 한 줄)·갤러리 Chips | 조각 이음매에 머리카락 틈·겹친 진한 줄이 없음, 양 끝이 둥글고 캡이 선 굵기와 같음(삐져나온 모서리 없음), 표시와 트랙 사이 간격이 양쪽 같음, 0 %에서 트랙만 닫힌 고리·100 %에서 표시만 닫힌 고리(12시 이음매 없음), 값을 바꾸면 0.3 s에 걸쳐 끝이 미끄러지고 트랙이 점으로 줄었다 사라짐, 비확정이 짧은 호(10 %)↔긴 호(87 %)로 늘었다 줄며 1.5 s마다 90° 툭 건너뛰며 돎, 작은 지름(24)에서 선이 뭉개지지 않음 |  |
| 32 | M3 Slider·RangeSlider 트랙 조각 둥글림 | 갤러리 Selection "Slider / Switch — M3 vs M2"·Slider·RangeSlider 스토리 | 조각의 바깥 끝은 반원(반경 8), 핸들 쪽 끝은 살짝만 둥근(반경 2) 모서리, 캡과 몸통이 만나는 x = 8에 이음매·틈·진한 줄 없음(비활성 반투명일 때도), 핸들 양옆 틈이 6 px로 같음, 끝에 닿은 조각은 모서리 곡선이 그대로인 채 창이 좁아져 사라짐(툭 사라지지 않음), 끝 점이 트랙 끝에서 중심 6 px 안쪽에 |  |
| 33 | M3 슬라이더 핸들·라벨 | 같은 곳 | 4x44 막대가 누르는 동안·포커스 동안 2 px로 가늘어지고 게임패드 포커스에 링이 막대를 감쌈, 값 라벨(32 px 알약, 좌우 여백 10, LabelLarge 크기·Regular 굵기)이 핸들 위 12 px에 뜸 — 위 행과 겹쳐 보이는지 |  |
| 34 | Switch 드래그(M3·M2) | 같은 곳 "Drag or tap"·Switch·M2Switch 스토리 / 플레이(터치) | 4 px 넘게 끌면 손잡이가 그 자리에서 튀지 않고(넘긴 순간의 포인터가 원점) 손가락을 1:1로 따라오고, 절반을 넘겨 놓으면 반대 상태로·못 넘기면 제자리로 미끄러짐, 놓은 순간 한 번 더 뒤집히지 않음(클릭 억제), 그냥 탭은 토글, 트랙 밖에서 놓아도 판정됨 |  |
| 35 | M2 Switch 썸 | 같은 곳 | 20 px 썸이 14 px 트랙 위아래로 삐져나오고 그림자가 보임, light에선 흰 썸·dark에선 밝은 회색, 누르는 동안 갤러리 행 높이가 안 변함(halo가 호스트 56x40 안) |  |
| 36 | 축소된 카드 안 버튼의 리플(UIScale) | 플레이·스토리: 작은 창에서 DatePicker 모달을 열고 오른쪽 위 둥근 모드 전환 버튼·‹ ›·Cancel/OK를 가장자리 가까이 누름 | 리플이 누른 자리에서 시작해 버튼 전체(오른쪽·아래 끝까지)를 덮음 — 왼쪽 위에만 그려지거나 곧은 선으로 잘리지 않음 |  |
| 37 | 둥근 글리프 버튼의 글리프 | DatePicker 모달 모드 전환(✎/▦)·‹ › | 글리프 가장자리가 원에 잘리지 않고 버튼 가운데에 놓임(폴백 글리프 모양 자체는 별도 — 아이콘 에셋 계획) |  |
| 38 | 누르는 동안 자동 폭 버튼·칩이 안 늘어남(9차 회귀·10차 후속) | 갤러리 Buttons·Chips 행, Dialog·DatePicker 모달 버튼, DatePicker(도킹·모달) 머리의 월·연 버튼 | 리플이 버튼을 가득 채울 때까지(0.5초 넘게) 누르고 있어도 버튼이 행 폭을 다 채우거나(서서히든 한 번에든) 줄바꿈되지 않고, 가득 찬 순간 리플 색이 끊기거나 깜빡이지 않으며 오른쪽 끝에 얇은 틈이 안 보임 — 리플 그룹 아래엔 Scale이 하나도 없음(`Ripple.luau` "NOT SCALE", "FULL COVER") |  |
| 39 | 드롭다운 메뉴 스크롤바·리플 | Select 스토리(Options 컨트롤을 6 이상으로 — 메뉴 높이 240 px를 넘으면 스크롤)·Menu 스토리 | 스크롤 막대가 흰색이 아니라 onSurface 50 %로 보이고, 항목을 누르면 리플이 누른 자리에서 퍼져 행 오른쪽 끝(막대 아래까지)을 덮음 |  |
| 40 | 작은 화면의 색상 선택기 모달 | 갤러리 Pickers "ColorPicker: modal" — 창을 작게 | 카드 전체가 화면 안으로 작아짐(잘리지 않음), 그 안 버튼 리플이 버튼 전체를 덮음 |  |
| 41 | M3 슬라이더 크기 다섯 | 갤러리 Selection "Slider variants (M3)" 크기 행·Slider 스토리 `Size` | XS 16·S 24·M 40·L 56·XL 96 트랙, 바깥 끝 반경 8/8/12/16/28이 반원·둥근 끝으로 보이고 캡·몸통 이음매 없음, L·XL 핸들이 68·108로 길어지고 호스트 안에 들어감, 끝 점이 크기와 무관하게 트랙 끝에서 6 px 안쪽(핸들 0 %·100 %가 그 점 위) |  |
| 42 | 세로 슬라이더 | 같은 곳 세로 넷·Slider·RangeSlider 스토리 `Vertical` | 아래가 Min(TopToBottom이면 위), 44 x 4 눕힌 핸들이 포인터를 세로로 따라옴, 값 라벨이 핸들 왼쪽 12 px, 위/아래 키·D-패드가 값을 움직이고 좌/우는 옆 컨트롤로 선택이 넘어감 |  |
| 43 | 가운데 정렬(Centered) 슬라이더 | 같은 곳 "Centered"·Slider 스토리 `Centered` | 활성 트랙이 한가운데에서 핸들 쪽으로(양방향), 한가운데에 점·표시 없음, 한가운데 반대편 비활성 조각이 6 px 떨어져 끝남, 양 끝 점 둘 |  |
| 44 | 안쪽 아이콘 | 같은 곳 L(✓·×)·M(♪, 비활성)·Slider 스토리 `InsetIcons`(M 이상) | 아이콘이 조각 끝에서 10 px 안쪽 트랙 위에 활성 SecondaryContainer·비활성 Primary 색, 조각이 아이콘 + 20보다 짧아지면 사라지고, 끝 아이콘이 있는 동안 끝 점이 안 보임 |  |
| 45 | 버튼 뒤 아이콘 | 갤러리 Buttons "Button: icons — leading / trailing"·Button 스토리 `TrailingIcon` | 18 px 아이콘이 라벨 뒤 8 px, 여백 24/16(Text 16/12), 누르는 동안 폭 그대로(9차 회귀 아님), ♪ 글리프가 잘리지 않음 |  |
| 46 | 분할 버튼 모양과 리플 | 갤러리 Buttons "SplitButton"·SplitButton 스토리 | 두 반쪽 사이 2 px, 바깥 끝 반원·안쪽 모서리 작게(4) 둥글고 누르는 동안 12로 부드럽게 커짐, 두 면(겉·안)이 만나는 반쪽 한가운데에 이음매·진한 줄 없음(비활성 반투명·Outlined 외곽선 포함), 리플이 반쪽 전체를 이음매 없이 덮음(두 원판이 한가운데에서 맞물림), Elevated 그림자가 보임, 뒤 버튼을 누르면 메뉴가 열리고 그동안 뒤 버튼이 양 끝 반원 알약 + 화살표 위로 + 살짝 어두움, 메뉴를 닫으면 되돌아옴, 포커스 링(바깥 반경으로 둥근 사각형) |  |
| 47 | 날짜 선택기 머리의 연도 메뉴 화살표 | DatePicker 스토리·갤러리 Pickers | 월-년 글자 뒤 ▼ 이미지(연도 격자가 열리면 ▲), 물듦·크기가 글자와 어울림, 글자 시작 위치가 이전보다 4 px 오른쪽(뒤 아이콘 여백 16) |  |
| 48 | 시간 선택기 선택 원 안의 숫자(가장 위험) | TimePicker 스토리·갤러리 Pickers "TimePicker: dial" | 선택 원(48 px, primary)에 걸친 숫자의 겹친 부분만 onPrimary로 보이고 나머지는 onSurface — 원이 두 숫자 사이(분 끌기)에 있어도 글자가 원 경계에서 정확히 두 색으로 갈림, 원 안 글자가 돌거나 밀리지 않음(회전한 `Hand` 안 `CanvasGroup` 안의 반대로 회전한 사본), 바늘이 돌아가는 동안에도 어긋나지 않음, 원 안 글자가 흐리지 않음 |  |
| 49 | 시간 선택기 바늘 동작 | 같은 곳 | 탭: 정시/5분으로 맞춰 미끄러지고 시는 0.1 s 뒤 분으로 넘어감(바늘도 분 자리로); 끌기: 손가락을 그대로 따라오고 놓으면 분으로; 12시를 지날 때 짧은 쪽으로 돎; 24 h에서 안쪽 고리(12~23) 숫자를 누르면 바늘이 짧아짐; 시↔분 숫자 면이 겹쳐 사라지고 나타남; 바깥에서 값을 바꾸면 바늘이 바로 그 자리 |  |
| 50 | 시간 선택기 머리·AM/PM | 같은 곳·Horizontal 스토리 | 시/분 상자 96 x 80 DisplayLarge "09" 가운데, ":" 위치(4 px 위), AM/PM 두 버튼 4 px 간격 — 선택은 반경 12 둥근 사각 + 굵은 글자, 아닌 쪽은 알약, 누르는 동안 12로 부드럽게, 리플이 버튼 밖으로 안 나감, Horizontal(508 x 256)에서 왼쪽 열이 문자판과 세로 가운데 |  |
| 51 | 시간 입력 | 갤러리 "TimePicker: input"·모달 "Start in text input" | 칸을 누르면 그 칸이 primaryContainer + 2 px 외곽선, 다른 칸은 surfaceContainerHighest + "09" 표시; 문자 입력이 되돌려짐, 13(12 h)·24(24 h)·75분이 오류 색·오류 문구, 두 자리(12 h는 2~9 한 자리)면 분 칸으로 포커스가 넘어감, Enter로도 넘어감; 모바일 키보드가 숫자 입력에 불편하지 않은지 |  |
| 52 | 시간 선택기 모달 | 갤러리 "TimePicker: modal" / 창 비율 바꾸기 | 가로로 긴 창에서 Horizontal 카드(556 x 332), 세로로 긴 창에서 Vertical(320 x 528), 전환 버튼(키보드 ↔ 시계 이미지)으로 카드 크기가 바뀜, 입력 모드로 열면 시 칸에 바로 포커스(그 상태에서 Escape/B가 칸 포커스만 풀고 모달은 안 닫히는지), 높이 300 이하 창에서 입력만·전환 버튼 없음, OK가 오류 동안 꺼짐 |  |
| 53 | 문자판 키보드·게임패드 | 플레이: 문자판을 게임패드로 선택 | 선택 동안 문자판 둘레 3 px 링, ←/→(D-패드 좌우)가 숫자를 한 칸씩(24 h 시는 11 → 12 안쪽 고리로), ↑/↓로 시/분 상자·AM/PM으로 빠져나감 |  |
| 54 | 하단 시트 끌기(가장 위험) | 갤러리 Overlays "Bottom sheet" 흉내 화면·모달 버튼, BottomSheet 스토리 | 시트 안의 목록 행·버튼을 눌러도 시트 끌기가 함께 시작되는지(엔진이 자식 버튼 위 누름을 시트 Frame의 InputBegan에도 주는지), 손잡이에서 끌기가 되는지, 끄는 동안 손가락을 그대로 따라오고 놓으면 가까운 자리로 0.2 s, 짧게 튕기면(125 px/s) 다음 자리, 끈 뒤 손잡이 클릭이 같이 일어나지 않음, 갤러리 페이지가 같이 스크롤되지 않음 |  |
| 55 | 하단 시트 모양 | 같은 곳 | 위 두 모서리만 28로 둥글고 아래 모서리는 각짐(덮개 사각형과 이음매 없음), 폭 640 넘는 창에서 가운데, 손잡이 32 x 4 막대가 48 상자 가운데, 표준 시트 그림자(Level1)가 위로 보임, 모달은 그림자 없음 |  |
| 56 | 모달 하단 시트 열고 닫기 | 갤러리 "Modal bottom sheet"·"Tall" | 아래에서 올라오며 스크림이 0.32로, 키 큰 내용은 화면 절반에서 멈추고 손잡이 클릭·끌기로 끝까지, Escape/B가 펼침 → 절반 → 닫힘 순, 스크림 탭으로 닫힘, 닫힐 때 스크림·시트가 함께 사라짐(튀지 않음), 행 클릭이 "Last sheet pick"에 남음 |  |
| 57 | 측면 시트 | 갤러리 Overlays "Side sheet"·SideSheet 스토리 | 모달: 오른쪽에서 275 ms로 미끄러져 들어오고 안쪽 두 모서리만 16, 그림자, 닫기 아이콘·Escape·스크림·오른쪽으로 밀기로 닫힘; 표준: 흉내 화면 오른쪽에 붙어 토글로 밖으로 빠졌다 들어옴, 머리 제목(TitleLarge)과 닫기 버튼이 한 줄 |  |
| 58 | 모달 내비게이션 드로어 | 갤러리 Navigation "Modal navigation drawer"·NavigationDrawer 스토리 | 메뉴 버튼으로 왼쪽에서 0.2 s, 스크림이 드로어 위치를 따라 0~0.32, 오른쪽 두 모서리 16, 항목이 많으면 드로어 안에서 스크롤, 목적지 클릭이 선택(알약 secondaryContainer) + 닫힘, 스크림 탭·왼쪽으로 끌기·Escape/B로 닫힘, 닫히면 게임패드 선택이 드로어로 들어가지 않음 |  |
| 59 | 드로어 항목 | 같은 곳·Permanent 화면 | 56 px 알약이 드로어 폭에서 양옆 12 px, 아이콘 24·글자 LabelLarge·배지가 오른쪽 끝, 선택 행 글자·아이콘 onSecondaryContainer, 구획 제목 TitleSmall이 28 px 들여씀, 구분선이 양옆 28 px·위아래 8 px, 리플이 알약 안에만 |  |
| 60 | dismissible·permanent 드로어 | 갤러리 Navigation 둘째·셋째 화면 | dismissible: 열리면 내용이 드로어 폭만큼 오른쪽으로 밀리고 메뉴 버튼으로 토글; permanent: 240 폭 드로어 옆을 내용이 채움 |  |
| 61 | 모달 면 안쪽 클릭 | 갤러리의 대화상자·메뉴·날짜/시간 선택 모달·모달 하단/측면 시트·모달 드로어 | 면 안 어디를 눌러도(빈 여백·머리·시계판 끌기·시트 손잡이 조작 뒤 포함) 닫히지 않음; 면 밖 스크림을 누르면 닫힘. 면마다 투명 TextButton `ClickSink`가 눌림을 먹는다(일반 Frame은 누름을 아래 스크림 버튼으로 흘려보낸다 — `Active`는 3D 입력만 막음) |  |
| 62 | 범위 날짜 완성·해제 때 깜빡임 | DatePicker 스토리 Range·갤러리 Pickers(밝은 테마) | 두 번째 날짜를 누르는 순간 사이 날짜의 띠와 끝 원이 바로 나타나고, 그 전에 반투명한 어두운 모양이 한 프레임도 덮지 않음; 세 번째 누름으로 범위가 풀릴 때도 띠·두 원이 바로 사라짐(어두워지지 않음); 첫 날짜(시작 원)만 0.1 s로 부드럽게 나타나고, 범위 밖 날짜의 호버 표시는 여전히 부드럽게 바뀜 |  |
| 63 | 슬라이더 끝에서 조각이 사라질 때 | 갤러리 Selection·Slider·RangeSlider 스토리, 특히 XL(트랙 96)과 L, Centered 포함, 값을 천천히 끝으로 끌기 | 핸들이 끝 점(트랙 끝에서 6 px)에 가까워지면 핸들 바깥쪽 조각이 툭 사라지지 않고 모서리 곡선은 그대로인 채 안쪽부터 좁아져 0이 됨(곡선이 바뀌지 않음), 0 %·100 %에서 핸들 중심이 끝 점 위, 끝 점은 조각이 덮을 때만 보임, 이산 슬라이더는 예전처럼 한 번에 사라짐 |  |
| 64 | 내비게이션 바 알약·배지(가장 먼저) | 갤러리 Navigation "Navigation bar" 두 화면·NavigationBar 스토리 | 누르면 알약(56 x 32, secondaryContainer)이 가운데서 0.2 s에 자라고 이전 것은 줄어듦, 글자·아이콘 색은 바로 바뀜; 아이콘 위 배지 — 작은 점은 아이콘 오른쪽 위 모서리, 큰 배지 "3"은 아이콘 오른쪽으로 삐져나옴; Start 아이콘(넓은 화면)은 40 높이 알약 안에 아이콘·글자 한 줄, 세 항목이 바 가운데 70 %; 리플·호버가 알약 안에만 |  |
| 65 | 레일 펼치고 접기 | 갤러리 "Navigation rail"·스토리 RailExpanded | 머리 메뉴 버튼(레일 96 가운데)을 누르면 0.2 s에 폭이 220 이상으로, 항목이 56 높이 가로 알약으로, 글자가 사라졌다가 아이콘 오른쪽 8에 다시 나타남(튀거나 잘리지 않음); 다시 누르면 접힘; 오른쪽 내용이 레일 폭을 따라 밀림 |  |
| 66 | 앱 바 스크롤(가장 위험) | 갤러리 "Top app bars that scroll" 세 화면·AppBar 스토리 | pinned: 목록을 조금만 내려도 바가 surfaceContainer로(0.2 s), 맨 위로 오면 surface; enterAlways: 내리면 바가 위로 사라지고 조금만 올려도 다시 나타남; exitUntilCollapsed: 136 → 64로 접히며 큰 제목이 옅어지고 작은 제목이 나타남, 맨 위로 와야 다시 펼쳐짐; 스크롤을 중간에 멈추면 0.1 s 뒤 가까운 끝으로 붙음; 첫 행이 바 아래 끝에 붙어 다님(겹치거나 벌어지지 않음); 터치 관성 스크롤 도중에 바가 떨지 않음 |  |
| 67 | 앱 바 모양·액션 | 같은 곳·"Top app bars at rest" | 내비게이션 아이콘 왼쪽 4, 제목 56에서 시작(TitleLarge), 가운데 정렬 제목이 바 가운데, 두 줄 바 큰 제목의 기준선이 아래에서 24/28 근처(글자 아래가 잘리지 않음), 액션 아이콘 onSurfaceVariant·내비게이션 아이콘 onSurface, 마우스를 올리면 툴팁, ⋮이 남은 액션을 메뉴로 열고 다시 누르면 닫힘, Favorite 토글이 primary로 |  |
| 68 | 하단 앱 바 | 갤러리 "Bottom app bars" | FlexibleBottomAppBar(64) 다섯 아이콘이 양 끝 16 안에서 고르게 벌어짐; BottomAppBar(80) 아이콘이 왼쪽 4부터, FAB(secondaryContainer)가 위 12·오른쪽 16 |  |
| 69 | 떠 있는 툴바 | 갤러리 "Floating toolbars"·Toolbar 스토리 | Expanded 스위치로 앞·뒤 내용이 0.15 s에 줄었다 펼쳐짐(앞은 왼쪽부터, 뒤는 오른쪽부터 드러남), 알약 모양 유지; FAB 형은 접으면 툴바가 FAB 쪽으로 사라지고 FAB이 56 → 80, 펼치면 툴바 그림자; Vibrant는 primaryContainer 위 onPrimaryContainer 아이콘 |  |
| 3 | CanvasGroup + UICorner 리플 클리핑 | Button·Chip·ListItem을 누름 | 리플 원이 둥근 모서리 밖으로 안 나감 |  |
| 70 | 앱 바 스크롤 — 스크롤바 | 갤러리 "Top app bars that scroll" 세 화면·AppBar 스토리 | 세 화면 모두 스크롤바가 바 아래 끝에서 시작해 바에 가리지 않음(오른쪽 exitUntilCollapsed는 맨 위에서도 136 바로 아래에 보임); 바가 접히고 펼쳐지는 동안 스크롤바 위 끝이 바 아래 끝을 따라감; 행 움직임은 66과 같음(튀거나 두 배로 움직이지 않음) | Studio 2026-10-08 확인(휠) |
| 71 | 앱 바 스크롤 — 정착 틈 | 갤러리 "Top app bars that scroll" 세 화면 | 스크롤바 엄지를 잡고 애매한 곳(enterAlways 0~64, exitUntilCollapsed 0~72)까지 끌어 잡은 채로 두면 바가 붙지 않고, 놓으면 0.2 s에 바와 목록이 함께 가까운 끝으로 움직여 첫 행이 바 아래 끝에 붙음(바와 1행 사이 빈 띠 없음); 목록 깊은 곳에서 enterAlways 바가 반쯤 돌아온 채 멈춰도 바와 목록이 같이 움직임; 정착 도중 휠·끌기를 하면 정착이 바로 멈추고 휠을 따름(되돌아가며 싸우지 않음); pinned는 그대로 | Studio 2026-10-08 확인(엄지 끌기·놓기, 정착 도중 휠) |
| 72 | Scaffold — 내용 영역·FAB·스낵바 | 갤러리 "Top app bars that scroll" 세 화면·"Navigation bar" 폰 화면·"Bottom app bars"·Scaffold 스토리 | 세 앱 바 화면의 스크롤바가 바 아래 끝 밑에 온전히 보이고 바가 접히고 펼치는 동안 따라감(70·71과 같은 움직임, 휠·엄지 끌기·정착 뒤 틈 없음); 폰 화면 FAB이 오른쪽 16·내비게이션 바 위 16, FAB을 누르면 스낵바가 FAB 위 16에 가운데로; 하단 앱 바 화면의 내용이 바 위 끝에서 끝남; 스토리에서 FabPosition Start / Center / EndOverlay(바 위에 겹침)와 아래 바 없음 | Studio 2026-10-08 확인(갤러리 — 휠·엄지 끌기 정착·FAB 클릭 스낵바; 스토리는 미확인) |

## 테스트

```
./quad-roblox-material/test/run.sh                                  # 전체: strict 타입 검사 + 순수 스펙 + Lune 스펙
./quad-roblox-material/test/run.sh quad-roblox-material/test/spec.gallery.luau   # 스펙 하나만 (레포 루트에서)
```

- 판정은 **exit code**입니다(출력의 PASS 개수를 세지 마세요).
- **Lune을 쓰는 이유**: `luau` CLI는 required 모듈마다 읽기 전용 환경을 주어 모듈 범위에서 엔진 전역을 쓰는 코드
  (`local WHITE = Color3.new(...)`)를 못 돌립니다. UI 키트는 늘 그렇게 쓰므로 모듈들이 전역 하나를 공유하고 진짜 Roblox 데이터
  타입을 주는 Lune(`@lune/roblox`)을 씁니다. Lune 0.10.5는 `const`와 `f<<T>>(x)`를 파싱하지 못하므로 `run.sh`가
  `test/support/mirror.py`로 줄 번호를 보존한 사본을 만들어 그 위에서 스펙을 돌립니다(오류 줄 번호는 원본과 같습니다).
- **하네스**(`test/support/harness.luau`): quad 목(mock) 인스턴스, 가상 시계 `H.advance`, `H.finishTweens`(트윈은 보간 없이
  목표값을 씀), `H.fire`/`H.input`/`H.setAbs`(목에는 레이아웃 엔진이 없음), `H.assertNoDebugOutput`(`q.debug = true`에서
  출력 0 보장), 가짜 `UserInputService`/`RunService`. 스펙마다 마운트·상호작용·Source 왕복·dispose(연결 수가 기준선으로
  복귀)·디버그 출력 0을 검사합니다.
- 순수 로직은 `spec.pure.*.luau`(`luau`로 직접).

## 알려진 한계

- **장치 미검증**: 이 키트는 목 백엔드에서만 검증됐습니다. 실제 `AbsolutePosition`/`AbsoluteSize` 위의 포인터 지오메트리
  (Slider 드래그, 색상 SV 영역, Menu·Tooltip 위치 보정과 GUI inset), 모양, `UIShadow` 렌더링은 실기기에서 보지 못했습니다.
  `TextField`는 편집 가능한 TextBox 위에서 엔진이 `MouseEnter`를 유지하는지(hover 표시) 확인하지 못했습니다.
- **외부 이미지 에셋 넷**: `Radio`는 qwreey MaterialUI의 라디오 스프라이트 시트(`rbxassetid://4667411351`)를 그대로
  참조합니다(키트가 올린 것이 아니라 원본 키트의 공개 에셋). 그 에셋을 못 불러오는 환경에서는 라디오가 비어 보입니다.
  `WavyProgress`의 물결은 이 키트의 진폭 스프라이트 시트 `assets/wavy-progress-sheet-1024.png`(1024×1024, 한 파장 480×64 24칸에 이웃 번짐 방지 여백, 최대 진폭 →
  평평, 흰 선·투명 배경; 생성기 `assets/gen-wave.py`)를 키트 작성자가 올린 공개 에셋(`rbxassetid://96568777229073`,
  `src/Progress/Wavy.luau`의 `SHEET_IMAGE`)으로 그립니다 — 데칼 id가 아니라 데칼이 가리키는 **이미지** id입니다(데칼·클래식
  티셔츠는 상위 에셋이라 `Image`에 넣으면 안 보임). 못 불러오는 환경에서는 물결이 안 보이고 양 끝 캡·트랙·끝 점만 보입니다.
  처음 올린 단일 텍스처 `assets/wavy-progress-512x128.png`(`rbxassetid://78445787165309`)는 더 쓰지 않습니다.
  `CircularProgress`는 이 키트의 원호 조각 시트 `assets/circular-arc-sheet-1024.png`(1024×1024, 160 px 칸 36개(170 px 간격·여백 5 px) = 두께 넷 × 1·2·4…256°,
  흰 선·투명 배경; 생성기 `assets/gen-arc.py`)를 키트 작성자가 올린 공개 에셋(`rbxassetid://97823357785454`,
  `src/Progress/Circular.luau`의 `SHEET_IMAGE`)으로 그립니다 — 이것도 데칼(92434906460089)이 아니라 **이미지** id입니다. 못
  불러오는 환경에서는 둥근 캡만 보입니다. 여백 없는 옛 시트 둘은 이음매 티끌이 나서 교체했습니다(2026-10-07).
  누름 리플은 원판 텍스처 `assets/ripple-disc-1024.png`(1024×1024, 반지름 511.5 흰 원판; 생성기 `assets/gen-disc.py`)를 키트 작성자가
  올린 공개 에셋(`rbxassetid://89858938964426` — 이것도 **이미지** id)의 부분 사각형(`ImageRectOffset`/`ImageRectSize`)으로 그립니다 —
  호스트에 잘린 원을 정확히 그리면서 호스트 사각형 밖으로 안 나갑니다. 못 불러오는 환경에서는 리플이 안 보입니다(상태 레이어는 그대로).
- **내장 아이콘**: Chip의 체크·제거, Select의 화살표, Snackbar의 닫기, DatePicker의 ‹ ›와 모달 모드 전환, 색상 선택기
  스와치 체크는 Google Material Design Icons(Apache 2.0, "baseline")를 작성자의 아이콘 계정이 Roblox에 올린 **이미지**
  에셋입니다(id 목록·출처는 `src/Icons.luau` 머리, 고지는 `NOTICE.md`). 2026-10-08에 economy API로 모두
  이미지(AssetTypeId 1)인 것을 확인했고(아홉째 chevronDown은 10차 분할 버튼용, keyboard·schedule은 시간 선택기용, menu는 내비게이션 드로어용, moreVert는 앱 바 오버플로용) 썸네일 렌더로 넷을 확인했지만, Studio 안에서는 아직 못 봤습니다. 이미지를 못 쓰는
  곳에서는 `Icons.override({ edit = false, ... })`로 이름별 텍스트 글리프로 돌릴 수 있습니다(✎ ▦은 Roboto에 없어 폰트 폴백에
  따라 물음표 상자가 됨 — 9차 관측). DatePicker 머리의 연도 메뉴 화살표는 10차부터 월-년 버튼의 뒤 아이콘 이미지(arrowDown/arrowUp —
  둘 중 하나를 지우면 예전처럼 라벨 안 ▼▲ 글리프); TextField 에러 "!"는 글리프 그대로입니다.
  장기 계획(Material Symbols 아틀라스)은 `.claude/research/icon-pack-plan.md`. 갤러리의 기본 `Icon` prop은 여전히 자리표시입니다.
- **`UIShadow`와 `CanvasGroup`**: `CanvasGroup` 안의 `UIShadow`는 잘리므로 Dialog와 Snackbar는 그림자가 없습니다(스크림이
  분리를 맡음). Menu는 CanvasGroup 페이드 대신 순수 스케일 애니메이션입니다. `UIShadow`는 가장 새로운 UI 클래스라 지원하지
  않는 클라이언트에서는 무효입니다(`Elevation.Backdrop`이 대안).
- **M3와 다른 점**(Roblox·인스턴스 비용 때문): Filled TextField는 위쪽 두 모서리만 둥글림(채움을 4px 더 크게 그려 부모가 자르는 방식, 인스턴스 +1),
  Outlined의 레이블 노치는 표면색 배경(어두운 배경 위에선 `NotchColor` 필요), Switch 터치 타깃은 52x32(M2 Switch는 56x40), IconButton의 48px 터치 타깃은
  선택(`TouchTarget = true`, 기본은 40px), 칩 제거·스낵바 버튼은 48px, Tabs는 스크롤되지 않고 개별 비활성이 없음, Slider·RangeSlider(M3)는 Min/Max/Step이 정적이고 핸들 양옆 틈이 6 px로 고정(Compose는 눌러서 2 px로 가늘어진 핸들에 맞춰 1 px 좁힘)·호버 표시 없음(M3 그대로 — M2 모양은 halo), 값 라벨 알약의 높이 32 px·좌우 여백 10 px는 토큰이 아니라 Google의 Android 구현(material-components-android `Widget.Material3.Slider.Label` — 그 스타일의 위아래 여백 12dp는 Android에서도 그려지지 않아 안 따름)에서 온 값, 리플은 호스트 사각형을 넘지 않음(`AutomaticSize` 조상이 리플까지 재기 때문, `Ripple.luau` "BOUNDED") — 잘린 원은 원판 텍스처의 부분 사각형으로 정확히 그림(2026-10-07 전엔 모서리 반경 하나로 흉내 내 넓은 호스트에서 둥근 사각형으로 보였음), 리플 상자는 조상 `UIScale`들의 곱으로 나눈 로컬 단위 정수 Offset이라 확장 도중 마지막 1 로컬 픽셀 미만은 끝 프레임(호스트 전체 덮기)에서야 채워짐, Menu 스크롤 막대는 M3 토큰이 없어 onSurface 50 %(Compose Desktop 기본 스크롤바의 호버 값), LoadingIndicator는 M3의 일곱 모양(오각형·쿠키 9 등) 대신 사각형 셋의 겹침 근사, WavyProgress는 확정만(비확정 물결 없음)·둥근 끝은 직각으로 자른 끝 위에 원을 얹은 근사(모서리 삐져나옴 1 px 미만)·진폭이 0 % 바로 위부터 100 % 바로 아래까지 최대(Compose 기본은 10 % 이하·95 % 이상 평평)·진폭과 선 두께가 높이에 고정 비율, Menu는
  가장 긴 항목에 폭을 맞추지 못하며(`Width` 지정) 타입어헤드·서브메뉴가 없음(위/아래·Return·Escape는 있음), CircularProgress는
  두께가 시트의 네 비율로 맞춰지고 끝·간격이 2° 단위(큰 지름 1°)로 움직이며 원형 물결(M3 Expressive)이 없음, 색상 선택기에 알파가 없음, 슬라이더 핸들 이동 범위의 끝 여백은 크기와 무관한 6 px(m3.material.io 스펙 우선 — Compose·MDC 코드는 바깥 반경만큼 안쪽)·이산(Step) 슬라이더는 바깥 반경보다 짧은 조각을 숨김(연속은 창이 좁아지며 사라짐)·끝 안쪽 아이콘이 보이는 동안 끝 점을 숨김(MDC는 같은 자리에 둘 다 그림), 분할 버튼은 작은 크기(40)만·포커스 링이 바깥 반경 하나의 둥근 사각형(안쪽 모서리가 모양보다 둥긂)·Elevated 그림자의 안쪽 모서리도 반경 20·두 반쪽이 `Disabled` 하나를 나눠 씀, 날짜 선택기 머리 화살표는 키트 Button의 뒤 아이콘(18 px, 여백 16/12 — Compose `YearPickerMenuButton`은 24 dp 아이콘에 12/12). 컴포넌트별 전체 목록은 각 파일 머리에 있습니다.
- **시트·드로어**(2026-10-08): 움직임이 스프링이 아니라 트윈(Compose는 스프링 — 놓을 때의 속도를 이어받지 않음, 넘침 없음),
  예측형 뒤로 가기(predictive back) 스케일 없음, 하단 시트의 중첩 스크롤(안의 목록을 다 올린 뒤 시트가 이어서 끌림) 없음, 드로어를
  내용 위에서 끌어 여는 제스처 없음, 측면 시트의 coplanar·detached 모양 없음, 손잡이 툴팁("Drag handle") 없음, 드로어 항목에 비활성 없음
  (Compose `NavigationDrawerItem`에도 없음). 시트 안 버튼을 누른 채 끌 때 시트가 같이 끌리는지는 엔진에 달림(실기기 체크리스트 54).
- **바·레일·앱 바·툴바**(2026-10-08): 움직임이 스프링이 아니라 트윈(DefaultSpatial → 0.2 s, FastSpatial → 0.15 s, 넘침 없음); 바·레일의
  옛(baseline) 판·`ModalWideNavigationRail`·항목 비활성·배지 룰러(긴 배지를 알약 안에 가둠) 없음; Centered 바 항목의 최대 폭(바 폭 / n)
  제한 없음; 앱 바는 바를 끌어 접기·플링·폭으로 넘치는 오버플로·`BottomAppBarScrollBehavior` 없음, 가운데 제목은 넓은 쪽에 맞춘
  대칭 공간 안에서 가운데(Compose는 겹칠 때 옮김); 툴바는 스크롤 동작·균형 최소 여백(minimumInteractiveBalancedPadding) 없음,
  FAB 그림자는 키트 FAB 그대로(Compose 툴바 FAB 2/3, 하단 앱 바 샘플 0); 바·레일의 선택 색은 테마 전환 때 교차 페이드 없이 바뀜.
- 갤러리는 좁은 화면에서 탭 글자가 잘릴 수 있습니다(Tabs는 폭을 균등 분할).

## 크레딧

Material Design 3 명세(Google), RoStrapUI(MIT), qwreey MaterialUI(MIT) — 자세한 출처와 라이선스는 [`NOTICE.md`](NOTICE.md). 이 키트 자체는 [`LICENSE`](LICENSE).
