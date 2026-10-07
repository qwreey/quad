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

(`src/Button/init.luau` 머리와 `test/spec.button.luau`가 소스. 누르는 동안 리플이 일시적으로 4개를 더 만듭니다.) 다른
컴포넌트의 수도 각 파일 머리와 스펙에 있습니다 — 예: Checkbox 15(토글 모션 막대 틀 하나 + 막대 넷 포함), Radio 5(스프라이트 한 장), Switch 8, 필드 있는 Filled TextField 13,
Slider 14, RangeSlider 23, 한 줄 ListItem 7, LoadingIndicator 8, 색상 패널 106(8색 프리셋 포함). 갤러리 전체의 탭별 합계는 아래 "갤러리"에 있습니다.

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
| | `Icons` | 내장 아이콘 글자 표 + `Icons.override`로 이미지 교체 |
| | `GlyphButton` / `KeyNav` / `Util` | 글리프·이미지 둥근 버튼(날짜 선택기·Snackbar 닫기·Chip 제거가 공유), 키·D-pad 전달 훅(Slider·날짜 칸·색상 선택기가 공유), `asState`/`negate`/`interactable`/`visible`/`hooks` 도우미와 `Hooks` 타입 |
| 버튼 | `Button` | Filled / Tonal / Elevated / Outlined / Text 다섯 변형(한 함수, `Variant` prop), 폭은 글자에 맞춤 또는 `Width`(픽셀·UDim, 라벨 가운데) |
| | `IconButton` | Standard / Filled / Tonal / Outlined, `Selected`로 토글 |
| | `FAB` | Small / Regular / Large, 색 넷, 레이블이 있으면 Extended |
| 선택 | `Checkbox` | 체크·불확정·오류·비활성(체크 표시는 회전한 Frame 둘이라 이미지 없음, 토글은 MaterialUI식 가장자리 막대 모션), `Label`로 라벨까지 한 클릭·호버 영역 |
| | `Radio` / `RadioGroup` | 한 개 / 세로·가로 묶음(선택 모션은 MaterialUI 스프라이트 시트 이미지 한 장), `Label`로 라벨까지 한 클릭·호버 영역 |
| | `Switch` | 52x32 트랙, 핸들이 16→24→28로 자람(꺼진 채 누르면 24), 선택적 아이콘 |
| | `Slider` | 클래식 M3(4px 트랙·20px 핸들), 연속/이산(눈금), 값 라벨, 키보드·D-pad |
| | `RangeSlider` | 손잡이 둘(`Start`/`End` 두 Source) — 누른 자리에서 가까운 손잡이를 끌고 서로를 못 넘음, 키는 한 손잡이씩(Return·게임패드 X로 전환) |
| 입력·메뉴 | `TextField` | Filled / Outlined, 떠오르는 레이블, 보조·오류 문구, 글자 수, 아이콘, 접두·접미, 여러 줄 |
| | `Menu` | `Menu.open{ Anchor, Items }`와 `Menu.Button` — 앵커 아래(공간이 없으면 위)에 뜸 |
| | `Select` | 읽기 전용 TextField + Menu(노출형 드롭다운) |
| 표면 | `Card` | Elevated / Filled / Outlined, `OnClick`이 있으면 상호작용 카드 |
| | `Divider` | 1px 선, 수평·수직, 안쪽 여백 |
| | `List` / `ListItem` / `ListData` | 1~3줄 행, 정적 자식 또는 키로 재활용되는 데이터 목록 |
| 오버레이 | `Dialog` | `open` / `confirm` / `alert`, 스크림·Escape·게임패드 B·선택 가두기, 작은 화면에서 본문 스크롤 |
| | `Snackbar` | 하단 중앙, 한 번에 하나, 나머지는 큐 |
| | `Tooltip` | `Tooltip.hook`(대상마다 하나)과 `Tooltip.Plain`(시각만) |
| 칩·탭·진행 | `Chip` | Assist / Filter / Input / Suggestion + 키로 재활용되는 `ChipSet` |
| | `Tabs` | Primary / Secondary, 활성 표시기 하나가 미끄러짐 |
| | `LinearProgress` / `CircularProgress` | 확정·비확정(원형은 `UIStroke`+`UIGradient`, 이미지 없음) |
| | `LoadingIndicator` | M3 Expressive 로딩 표시 — 모양이 바뀌며 도는 것(둥근 사각형 셋을 서로 돌려 겹친 근사: 12갈래·8갈래·둥근 사각형·알약·원), `Contained` |
| | `WavyProgress` | M3 Expressive 물결 막대(확정만) — 짧은 회전 Frame들로 그린 사인파가 흐르며 차오름, `CanvasGroup`이 채운 길이로 자름 |
| 선택기 | `DatePicker` | `Docked` / `RangeDocked` / `Modal`, 순수 날짜 계산 `Calendar` |
| | `ColorPicker` | `Panel` / `Modal.open` / `ColorModel` / `Classic` |

### props 관례

모든 컴포넌트는 같은 규칙을 따릅니다(`src/init.luau` 머리의 열 항목 체크리스트가 소스).

- **평범한 함수 하나**가 호스트 인스턴스를 돌려줍니다: `Material.Button { ... }`.
- **`Theme` 폴백**: `props.Theme`가 없으면 `Theme.default`. 앱 전체에 테마 하나를 쓰면 아무것도 안 넘겨도 됩니다.
- **`T | State<T>` 입력**: 값이 바뀔 수 있는 입력(`Label`, `Disabled`, `Error`, ...)은 값 또는 State를 받습니다. State를
  넘기면 그 프로퍼티만 갱신됩니다.
- **`Source<T>` 양방향 prop(`Value`)**: 폼 컨트롤(`Checkbox`·`Switch`·`Radio`·`Slider`·`TextField`·`Select`·`DatePicker`·
  `ColorPicker`)은 `Value`로 `Source<T>`를 받습니다. 컴포넌트가 읽고, 사용자가 조작하면 `:Set`합니다. 안 넘기면 컴포넌트가
  내부 Source를 만듭니다. **`OnChange(new)`는 사용자 조작 뒤**에만 불리고 프로그램이 쓴 값에는 안 불립니다.
- **통제형 `Checked`**: `Checkbox`와 `Switch`는 `Value` 대신 `Checked: State<boolean>` + `OnChange`도 받습니다. 컴포넌트는 State를
  보여 주기만 하고 클릭하면 `OnChange(새 값)`만 부르며 **아무것도 쓰지 않습니다**(원본 상태는 호출한 쪽이 정함 — 예: 테마 스위치는
  `Checked = theme.Scheme:Compute(...)`, `OnChange = function(dark) theme:SetScheme(...) end`). `Value`와 `Checked`를 같이 주면 에러.
- **선택·표시 컴포넌트는 `Selected`**: `Chip.Filter`·`Tabs`·`ListItem`·`IconButton`(토글)·`Menu` 항목. 값 바뀜 콜백은 `Chip.Filter`/`Tabs`도 `OnChange`.
- **글자 이름**: 버튼·행동 글자는 어디서나 `Label`(`Button`, `Chip`, `Tabs`의 탭, `Menu` 항목, `Snackbar`·`Dialog`의 액션). 스낵바 메시지만 `Text`.
- **`Disabled`는 어디서나 `boolean | State<boolean>`**(메뉴·목록 항목, 라디오 옵션 포함).
- **열린 것의 핸들은 하나의 모양**: `Overlay:Open`, `Menu.open`, `Dialog.open`, `DatePicker.Modal.open`, `ColorPicker.Modal.open`,
  `Snackbar` 항목, `Tooltip.hook` 모두 **self 없는 클로저** `handle.Close(result?)`와 `handle.IsOpen: State<boolean>`을 돌려줍니다
  (`Overlay` 핸들은 `Closing`, `Dialog`는 `Result`, `Snackbar` 항목은 `Visible`/`Done`/별칭 `Dismiss`가 더 있음). `result`는 `unknown`.
- **제네릭 컴포넌트의 타입 인자**: `Tabs<<string>>({ ... })`처럼 적어야 합니다 — `Selected: Source<K>`가 불변이라 `q.Source("a")`만으로는 strict가
  K를 `string | nil`로 추론해 호출을 거부합니다(`Tabs`의 탭 목록은 인라인 리터럴도 받고, State는 `TabsState`로 따로 받음).
- **`Modifier`**: 배열 부분에서 컴포넌트의 기본 스타일 **뒤에** 적용되므로(나중 것이 이김) 크기·위치·`LayoutOrder`를
  호출한 쪽이 바꿀 수 있습니다.
- **`Hooks`**: 호스트 인스턴스가 있는 **모든** 컴포넌트는 배열 부분에 추가로 꽂을 값(예: `Tooltip.hook(...).Hook`, `q.OnChange`, ref)을 받습니다.
  타입은 하나의 별칭 `Material.Hooks = { any }`입니다. `Modifier`의 타입은 호스트 클래스의 `q.<Class>Modifier`(`q.TextButtonModifier` 등)입니다.
- 자식을 받는 컴포넌트(`Card`, `List`)는 `q.Slot<<Instance>>({ ... })`를 `Children`으로 받습니다.

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
위/아래 화살표·Return으로 항목을 탐색합니다. 아이콘은 `Icons`(텍스트 글자 기본, `Icons.override`로 이미지 교체)에서 나옵니다.

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

## 색상 선택기

```luau
local brand = q.Source(Color3.fromRGB(103, 80, 164))
Material.ColorPicker.Panel({ Value = brand, Swatches = { ... } })
Material.ColorPicker.Modal.open({ Value = brand:Get(), Title = "Brand color", OnConfirm = function(c) brand:Set(c) end, Overlay = overlay })
Material.ColorPicker.Classic({ Theme = "Dark" })
```

- **상태 모델**: 패널의 단 하나의 진실은 **`Source<HSV>`**입니다. `Value: Source<Color3>`를 넘기면 Effect 하나가 둘을
  동기화하고(바깥에서 쓴 값과 자기 되울림을 구분), 색상(H)을 손해 없이 쓰려면 `HSV: Source<HSV>`를 직접 넘깁니다. 둘 다
  넘기면 오류입니다.
- **색상 보존**: 검정·회색에는 색상이 없습니다. Color3만 상태로 두면 사용자가 검정 가장자리를 건드릴 때 색상 슬라이더가
  빨강으로 튑니다(원본 선택기의 버그). HSV를 상태로 두면 검정·회색을 지나도 H와 S가 남습니다.
- **Modal**: 임시(draft) 값을 편집하다가 OK에서만 바깥에 반영합니다. Cancel·스크림·Escape는 draft를 버립니다.
- **Classic vs Material**: `Classic`은 작성자의 원본 OOP 선택기를 거의 그대로 옮긴 것(자기 모양, 0..255 눈금, 230x418)이고,
  `Panel`/`Modal`이 M3 모양입니다. 둘의 차이와 옮기며 고친 원본 버그는 [`docs/colorpicker-comparison.md`](docs/colorpicker-comparison.md)와
  [`docs/colorpicker-original-analysis.md`](docs/colorpicker-original-analysis.md)에 있습니다.

## 갤러리

```luau
local Gallery = require("<이 폴더>/src/Gallery")
Gallery.mount()                -- PlayerGui에 ScreenGui를 만들어 갤러리 + 자기 소유 오버레이 층을 올림
Gallery.mount(someParent)      -- 부모를 직접 지정
Gallery.GalleryPanel({})       -- 페이지(Frame)만; 직접 호스트할 때. Overlay를 안 주면 자기 층을 만들어 안에 놓음
```

위쪽 `Tabs`로 여덟 구간(Buttons / Selection / Text / Surfaces / Overlays / Chips / Pickers / Theme)을 오가고, 각
컴포넌트가 실제 상태(비활성·오류·선택 변형 포함)로 동작하며 Theme 탭의 스위치가 `Theme.default`의 light/dark를 바꿉니다.
구간은 **탭을 고를 때 만들고 떠나면 부숩니다**(숨겨 두지 않음) — Pickers 하나가 수백 개이고 비확정 진행바가 Heartbeat
루프를 돌기 때문입니다. 사용자가 입력·조작한 값은 패널의 Memo(Source)에 있어 다시 돌아와도 남습니다. 갤러리를 키트 루트(`src/init.luau`)에서 내보내지 않는 이유: 내보내면 키트를 쓰는 모든 소비자가 데모 코드까지 로드하게 됩니다(갤러리가 컴포넌트를 직접 require하므로 순환 자체는 아니지만, 갤러리가 루트를 require하는 모양이 되면 순환이 됩니다). 이 폴더를 직접 require하세요.

스펙이 센 인스턴스 합계(`test/spec.gallery.luau`, 패널 뼈대 — 루트·탭·스크롤 — 포함): Buttons 363, Selection 522,
Text 268, Surfaces 327, Overlays 199, Chips 438, Pickers 748, Theme 197. 아이콘 데모는 키트가 그림을 싣지 않으므로
`Icon` prop(기본값은 장치에서 확인 못 한 자리표시 에셋 id)을 본인 에셋으로 바꿔 보세요.

## UI Labs / 입력 주입

UI Labs(Studio 플러그인)는 스토리를 플러그인 DockWidget 안에 그리는데, 거기서는 `UserInputService`가 입력을 받지 못합니다.
UI Labs가 스토리에 주는 `Environment.InputListener`(`InputBegan`/`InputChanged`/`InputEnded` + `MouseMoved`)로 갈아 끼울 수
있도록, 키트가 입력을 만지는 자리(Interaction 드래그, KeyNav, Overlay, Menu, FakeCursor)는 전부 `src/Input.luau`의
`Input.service()`를 **쓰는 순간에** 읽습니다.

```luau
local Material = require("@pkg/quad-roblox-material")
Material.Input.use(Environment.InputListener)  -- 스토리 모드: 리스너로 교체
Material.Input.use(nil)                         -- 엔진 서비스로 복원
```

- 교체 중에는 `GetMouseLocation()`이 마지막 `MouseMoved` 위치를 돌려주고, `MouseIconEnabled = false` 같은 쓰기는 엔진에
  닿지 않으며(로컬에 저장), `GetFocusedTextBox`·`GetLastInputType` 등 나머지 멤버는 엔진 서비스로 넘어갑니다.
- `GuiService`의 선택·게임패드 API(`SelectedObject`, 선택 부모 등)는 대체물이 없어 그대로입니다 — **게임패드/선택 동작은
  플레이 모드에서만 확인됩니다.**

## Studio에서 보기 — UI Labs 스토리와 플레이 테스트

레포 루트의 `consumer-kits.project.json`이 ReplicatedStorage에 quad-base·quad-roblox·두 킷을 레포 폴더 모양 그대로 올리고,
킷의 `play/` 폴더를 StarterPlayerScripts에 넣는다(킷의 `src/Quad.luau` 상대 require가 Studio에서도 같은 경로로 풀린다).

1. 터미널에서 `rojo serve consumer-kits.project.json --port 34872`, Studio의 Rojo 플러그인에서 그 포트로 연결.
2. **스토리(편집 모드)** — UI Labs 플러그인을 연다. 탐색기에 storybook **"quad · Material 3"**(`ReplicatedStorage/quad-roblox-material/stories/Material.storybook`)이
   보이고, 그 아래 `*.story` 모듈마다 항목이 하나씩 있다. 항목을 열면 오른쪽 Controls 패널이 뜬다 — 패널의 값 하나하나가
   스토리 안에서 `q.Source` 하나이고(`stories/StoryKit.luau`), 컴포넌트는 앱에서 쓰는 그대로 그 Source를 받는다. 값을 바꾸면
   다시 그리지 않고 바인딩만 갱신된다.
3. **플레이 테스트** — Play(F5). `play/` 의 LocalScript가 PlayerGui에 Gallery(탭으로 전 컴포넌트)을 띄운다. 게임패드·선택(GuiService)·
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
| 3 | CanvasGroup + UICorner 리플 클리핑 | Button·Chip·ListItem을 누름 | 리플 원이 둥근 모서리 밖으로 안 나감 |  |
| 4 | Roboto 글꼴·굵기(Medium 500) | Theme 스토리·Gallery | LabelLarge/TitleMedium이 Medium으로 보임 |  |
| 5 | 글리프(▼ ‹ › × ✓ ✎ ▦ !) | Select·DatePicker·Chip·Snackbar·TextField 에러 | 두부(□)로 안 나옴 |  |
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
| 17 | 작은 화면에서 Dialog 스크롤·모달 축소 | 플레이: 창을 작게 | 본문 스크롤, 액션 버튼 고정, 모달이 화면 안 |  |
| 18 | Deferred 시그널 파괴 순서 | 플레이: ScreenGui를 지우고 같은 프레임에 다시 만듦 | 에러 없음(Quad0219 없음), 팝업 고아 없음 |  |
| 19 | Progress 무한 애니메이션 부하 | Progress 스토리 / 플레이 | 보이는 동안만 돌고 숨기면 멈춤 |  |
| 20 | Snackbar 호버 시 타이머 멈춤 | Snackbar 스토리 | 커서를 올리면 사라지지 않음 |  |
| 21 | Radio 스프라이트(에셋 4667411351) | Radio 스토리·갤러리 Selection | 링·점이 또렷하고 테마 색으로 물듦, 선택 때 외곽이 안쪽으로 붙으며 점이 차오르는 10프레임 모션 |  |
| 22 | Checkbox 토글 모션 | Checkbox 스토리 | 체크: 가장자리 막대가 오므라들었다가 가운데부터 체크가 드러남 / 해제: 채움이 접혀 들어감 |  |
| 23 | 라벨 연동(label-for) | Checkbox 스토리 "Label"·갤러리 Selection | 라벨 위 호버가 상자 상태 레이어를 켜고, 라벨 클릭이 토글, 리플은 상자 가운데에서 |  |
| 24 | 누르는 동안 크기가 안 변함(리플이 호스트 밖으로 안 나감) | 버튼·칩(특히 칩)·DatePicker 연도 전환 버튼·가로 RadioGroup·Switch·Dialog 버튼 | 누르는 동안 폭·높이·옆 요소 위치가 그대로, 리플 모양이 둥근 사각형으로 자라다 호스트를 덮음 |  |
| 25 | Checkbox 토글 중 모양 | Checkbox 스토리 | 외곽선만 2px씩 살짝 부풀고, 오므리는 막대는 외곽선 안쪽 — 상자가 각진 네모로 보이지 않음 |  |
| 26 | TextField 아무 곳 클릭 포커스 | TextField 스토리(Filled·Outlined) | 라벨·여백·아이콘 위를 눌러도 입력이 시작됨 |  |
| 27 | 범위 날짜의 반쪽 띠 | DatePicker 스토리 Range·갤러리 Pickers | 시작·끝 원 아래 반 폭 띠가 사이 띠와 이어짐(틈 없음) |  |
| 28 | Dialog 닫힘 | Dialog 스토리 | DatePicker 모달처럼 살짝 작아지며 사라짐, 버튼·바닥 여백이 안 커짐 |  |
| 29 | LoadingIndicator·WavyProgress | Progress 스토리·갤러리 Chips | 모양이 650ms마다 바뀌며 돌고, 물결이 흐르며 막대가 참 — 끊김·이음매 틈이 거슬리지 않는지 |  |
| 30 | Classic 색상 선택기 물방울 그림자 | ClassicColorPicker 스토리 | 색조 손잡이를 끌 때 물방울 그림자가 손잡이(구) 위를 덮지 않음 |  |

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
- **외부 이미지 에셋 하나**: `Radio`는 qwreey MaterialUI의 라디오 스프라이트 시트(`rbxassetid://4667411351`)를 그대로
  참조합니다(키트가 올린 것이 아니라 원본 키트의 공개 에셋). 그 에셋을 못 불러오는 환경에서는 라디오가 비어 보입니다.
- **글리프 아이콘**: 키트가 아이콘 에셋을 싣지 않으므로 Chip의 체크·제거 "x", Select의 화살표, Snackbar의 닫기는 **텍스트
  글리프**(엔진 폰트 폴백이 그림)입니다. 정확한 그림이 필요하면 `CheckIcon`/`RemoveIcon`/`TrailingIcon` 등 에셋 id prop을
  쓰세요. 갤러리의 기본 `Icon`도 자리표시입니다.
- **`UIShadow`와 `CanvasGroup`**: `CanvasGroup` 안의 `UIShadow`는 잘리므로 Dialog와 Snackbar는 그림자가 없습니다(스크림이
  분리를 맡음). Menu는 CanvasGroup 페이드 대신 순수 스케일 애니메이션입니다. `UIShadow`는 가장 새로운 UI 클래스라 지원하지
  않는 클라이언트에서는 무효입니다(`Elevation.Backdrop`이 대안).
- **M3와 다른 점**(Roblox·인스턴스 비용 때문): Filled TextField는 위쪽 두 모서리만 둥글림(채움을 4px 더 크게 그려 부모가 자르는 방식, 인스턴스 +1),
  Outlined의 레이블 노치는 표면색 배경(어두운 배경 위에선 `NotchColor` 필요), Switch 터치 타깃은 52x32, IconButton의 48px 터치 타깃은
  선택(`TouchTarget = true`, 기본은 40px), 칩 제거·스낵바 버튼은 48px, Tabs는 스크롤되지 않고 개별 비활성이 없음, Slider·RangeSlider는 2022 클래식 형태이고 Min/Max/Step이 정적, 리플은 호스트 사각형을 넘지 않는 둥근 사각형으로 자람(원이 가장자리에 잘린 모양이 아님 — `AutomaticSize` 조상이 리플까지 재기 때문, `Ripple.luau` "BOUNDED"), LoadingIndicator는 M3의 일곱 모양(오각형·쿠키 9 등) 대신 사각형 셋의 겹침 근사, WavyProgress는 확정만(비확정 물결 없음), Menu는
  가장 긴 항목에 폭을 맞추지 못하며(`Width` 지정) 타입어헤드·서브메뉴가 없음(위/아래·Return·Escape는 있음), 원형 비확정
  진행의 가장 짧은 호가 180도, 색상 선택기에 알파가 없음. 컴포넌트별 전체 목록은 각 파일 머리에 있습니다.
- 갤러리는 좁은 화면에서 탭 글자가 잘릴 수 있습니다(Tabs는 폭을 균등 분할).

## 크레딧

Material Design 3 명세(Google), RoStrapUI(MIT), qwreey MaterialUI(MIT), 그리고 작성자 본인의 원본 색상 선택기에서 옮긴
`ColorPicker.Classic` — 자세한 출처와 라이선스는 [`NOTICE.md`](NOTICE.md). 이 키트 자체는 [`LICENSE`](LICENSE).
