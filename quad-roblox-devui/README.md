# quad-roblox-devui

> 패키지 이름은 **가칭**입니다(작업명 `quad-roblox-devui`). 도그푸딩을 거친 뒤 정식 이름을 정합니다. 소스 코드 안에는
> 이 이름이 없고(require는 전부 폴더 상대 경로) 이 문서, 폴더 이름, 테스트 파일의 주석에만 나옵니다. 이 키트에는 매니페스트가 아직 없습니다.

[quad](../README.md) 위에서 만든 **개발자·디버그용 UI 키트**입니다. [Iris](https://github.com/SirMallard/Iris)
(Dear ImGui 계열)와 같은 **위젯 세트**와 같은 **겉모양**(작은 글씨, 납작한 프레임, 파란 강조색)을 가지지만,
API 모양은 Iris를 따르지 않고 quad의 방식 — **retained(유지형)이고 반응형** — 으로 짰습니다.

```luau
local Devui = require("<이 폴더>/src")
local q = require("<이 폴더>/src/Quad")
local Kids = Devui.Kids

local count = q.Source(0)
local label: q.State<string> = count:Compute(function(self)
	return `Clicked {self:Get()} times`
end)

local overlay = Devui.Overlay.new() -- ScreenGui마다 하나: 팝업(Combo / Menu / Tooltip)이 그려지는 층
local screen = q.Elem "ScreenGui" {
	ResetOnSpawn = false, -- 층은 quad가 만든 인스턴스라 리스폰으로 다시 만들어지면 안 됨
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, -- 필수(아래)
	Devui.Window {
		Title = "Debug",
		Children = Kids(
			Devui.Button {
				Text = "Count up",
				OnClick = function() count:Set(count:Get() + 1) end,
				Hooks = { Devui.Tooltip({ Text = "누르면 +1", Overlay = overlay }).Hook },
			},
			Devui.Text { Text = label }
		),
	},
	overlay.Layer,
}
screen.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
```

**`ScreenGui`는 `ZIndexBehavior = Sibling`이어야 합니다.** 코드로 만든 `ScreenGui`(`q.Elem "ScreenGui"`·`Instance.new`)의 기본값은
`Global`이고, 이 키트는 창의 겹침 순서(서열 r인 창의 창틀·표면·손잡이가 `ZIndex` 3r−2..3r 세 칸)와 팝업 층(`ZIndex` 1000)을 형제 사이의 `ZIndex`로
정합니다. `Global`에서는 `ZIndex`가 `ScreenGui` 전체에서 비교되어, 서열 2 이상인 창의 창틀이 자기 내용(`ZIndex` 1)과 팝업
위에 그려집니다. `q.debug`가 켜져 있으면 팝업이 처음 열릴 때 한 줄로 알립니다. Studio에서 손으로 넣은 `ScreenGui`는 기본이
Sibling입니다.

전체 위젯을 한 번에 보려면 데모 창을 띄우세요(아래 "데모").

## 앱 코드를 짤 때 먼저 볼 것

이 README와 위젯 머리 주석은 **키트**만 설명합니다. quad 자체의 관용구는 quad 저장소의 에이전트 스킬
[`docs/skills/quad-ui-dev/SKILL.md`](../docs/skills/quad-ui-dev/SKILL.md)와 [how-to](../docs/how-to/)에 있습니다 — 키트로 앱을 짜다가
"quad로는 안 되나" 싶은 것은 대부분 거기 이미 있습니다(2026-10-20 devplorer 보고: 한계로 보였던 것이 전부 이미 있었고, 소비자가 이 README에서
거기로 가는 길을 못 찾았음). 자주 찾는 것:

- **인스턴스 없이 도는 구독**(데이터 모듈의 Observer): `:Subscribe()`/`:WeakSubscribe()` — Observer는 요소에 매달거나 구독해야 돕니다.
  [core/05](../docs/reference/core/05-observer-effect.md), 스킬의 `rules-and-invariants.md`. Observer는 등록할 때 한 번 부릅니다.
- **코드와 사용자가 같이 쓰는 입력 상자**: `Text = src` + `q.Out "TextBox" "Text" (src)` — 메아리를 손으로 거르지 마세요. `Devui.InputText`가 이 모양입니다.
  [roblox/05](../docs/reference/roblox/05-onchange.md), [시작하기 06](../docs/getting-started/06-flowing-back.md).
- **검색창 디바운스·갱신 합치기**: [`q.Debounce`/`q.Throttle`](../docs/reference/sugar/03-debounce-throttle.md). 여러 원천을 한 번에 갱신하려면 Effect 하나로 모은 뒤 붙입니다.
- **바깥 신호(`UserInputService` 등)의 수명**: [`q.OnDestroyed`](../docs/reference/sugar/04-lifecycle-hooks.md)나 Effect cleanup에 묶습니다 — `Destroying:Connect`나 표지용 Folder가 필요 없습니다.
  [how-to/04](../docs/how-to/04-network-and-input-bridge.md).
- **quad가 만든 인스턴스의 변화**: 선언 밖에서 `:Connect`하지 말고 같은 선언 안의 `q.OnChange`·이벤트 prop으로(파괴와 함께 풀림). 읽기 전용 프로퍼티(`AbsoluteSize`·`CanvasPosition`)도 됩니다.
- **긴 목록**: Table·Combo·Tree는 가상화가 없습니다. 수천~수만 행은 `VirtualRows`를 쓰세요 — 행 높이가 고정이고, 화면에 걸친 만큼의 슬롯만 만들어 스크롤할 땐 행 번호만 다시 묶습니다(만들기·파괴 0). 키로 재활용하는 quad 레시피는 [how-to/03](../docs/how-to/03-long-lists-and-windowing.md).
  배치 전(크기 0)에는 행이 0개인 것이 정상입니다.
- **파생 값의 타입**: `:Compute` 결과는 만드는 줄에서 주석합니다(`local shown: q.State<boolean> = n:Compute(...)`) — 인라인으로 prop에 넣으면 오류 문구가 길어집니다.
  `Source`와 `State`를 한 변수에 받을 땐 주석 붙인 if-식(`local h: q.State<number> = if s then s else q.Source(1)`)이나 값을 돌려주는 함수로 — 분기마다 대입하면 유니언이 되어 `:Compute`를 못 부릅니다.
- **Slot**: 요소의 배열부에 빈 Slot을 놓을 땐 `q.Slot<<Instance>>()`. `Kids(...)`(= Slot)의 원소는 `nil`·`q.None`이 될 수 없습니다(요소의 배열부와 다름).
  `{ table.unpack(list) }`로 자식을 펴는 대신 `q.Slot<<Instance>>(list)`를 배열부 아무 자리에나 놓습니다.
- **이벤트 prop에 미리 만든 함수**: `local f: () -> () = ...`처럼 주석한 무인자 함수는 `Activated` 같은 자리에 안 들어갑니다(Luau 새 솔버 규칙) —
  `local function f() end`나 인라인 함수를 넘기세요.
- **배치 속성**: `LayoutOrder`·`Position` 같은 루트 꾸밈은 Modifier로(`q.Modifier "Frame" ():LayoutOrder(2)`). Button은 `Size`를 받으면 자동 크기가 꺼집니다.

## Iris와 무엇이 다른가

이 키트는 Dear ImGui·Iris에서 **영감을 받았을 뿐 정본으로 따르지 않습니다**. 목적은 개발자가 도구 UI를 다시 짜는 수고를 줄이는 것이라, 정본에 없는 위젯·동작도 들이고 정본과 다르게 정하기도 합니다(예: 가려진 요소는 hover되지 않음, 바깥 클릭이 막히는 팝업).

| | Iris (immediate mode) | 이 키트 (retained, 반응형) |
|---|---|---|
| 상태 | 위젯이 내부에 들고 있고, 호출 쪽이 `widget.state.value`로 접근 | 호출 쪽이 `Source`를 만들어 위젯에 넘김. 안 넘기면 위젯이 내부 `Source`를 만듦 |
| 갱신 방법 | 매 프레임 UI 함수를 다시 호출해 "이번 프레임에 있는 위젯"을 선언 | UI는 한 번 만들고, 값이 바뀌면 `Source:Set` — 그 값에 묶인 프로퍼티만 갱신됨 |
| 생명주기 | 프레임에 호출이 없으면 사라짐 (ID로 재사용) | 인스턴스가 곧 생명 — 만든 쪽이 `q.dispose` 하거나 부모가 파괴될 때 정리됨 |
| 동적 목록 | 반복문으로 매 프레임 다시 선언 | `Slot`(수동 CRUD) 또는 `Table`처럼 키로 재활용되는 목록 |
| 프레임당 비용 | UI 크기에 비례해 매 프레임 | 변화가 없으면 0 (데모에서 매 프레임 도는 건 플롯 샘플러 하나뿐, 10Hz) |
| 팝업 | 같은 호출 흐름 안에서 그림 | `Overlay`(화면 루트의 한 층)에 열고 닫음 |

한 줄 요약: Iris는 "매 프레임 UI를 다시 말한다", 이 키트는 "UI를 한 번 만들고 값만 흘린다".

## 설치와 설정

이 레포 안에서는 그대로 `require("quad-roblox-devui/src")`로 쓰면 됩니다. 키트가 quad가 어디 있는지 아는 곳은
**`src/Quad.luau` 하나**입니다 — quad 문서가 권하는 "설정 모듈"과 같은 모양입니다(quad_base 싱글턴에 Roblox 프로바이더를
한 번 설치하고, 키트가 쓰는 타입을 다시 내보냄). 세 줄이 전부입니다.

```luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
```

다른 프로젝트에서 쓸 때는 **이 세 줄만** 그 프로젝트의 패키지 경로로 바꿉니다(예:
`@game/ReplicatedStorage/Packages/quad_base`). 나머지 키트 코드는 전부 `require("./Quad")` 꼴로 이 모듈만 봅니다.
`UseProvider`는 같은 프로바이더에 대해 멱등이므로, 게임이 같은 설치 사본에서 자기 설정 모듈을 이미 돌렸다면 같은
quad 인스턴스를 공유합니다(게임의 `State`와 키트의 `State`가 그대로 섞입니다).

**타입은 두 문에서 옵니다.** quad의 타입(`State`·`Source`·`Ref`·`Slot` 등)은 키트의 `Quad` 모듈에서(`local Quad = require(<키트>/src/Quad)`
→ `Quad.State<T>` — 값을 만들 `q.Source`도 어차피 여기서 옵니다), devui 자기 타입은 `Devui`에서(`Devui.Style`, `Devui.HoverHandle`,
`Devui.InputTextProps` …) 얻습니다. devui는 quad 타입을 다시 내보내지 않습니다 — quad 타입의 문을 하나로 두려는 것입니다(2026-10-20 결정).

## 데모

```luau
local Demo = require("<이 폴더>/gallery")
Demo.mount()                -- PlayerGui에 ScreenGui를 만들어 데모 창 + Style Editor + Runtime Info + 팝업 층을 올림
Demo.mount(someParent)      -- 부모를 직접 지정
Demo.DemoWindow({ Overlay = o })   -- 메인 창만 (o = Devui.Overlay.new(); 직접 ScreenGui에 놓고 o.Layer도 같이 놓을 것)
```

`gallery/`(데모)는 Iris의 `ShowDemoWindow`에 해당하고, 위젯 그룹마다 파일이 하나씩입니다(`Basic`/`Inputs`/`Trees`/
`Tables`/`Popups`/`Plots`, 도구 창 `StyleEditor`/`RuntimeInfo`). 새 위젯을 쓰는 법은 이 파일들이 가장 좋은 예제입니다.
Heartbeat는 `gallery/Clock.luau`의 `ticker`만 건드리고, 그 연결은 그것을 놓은 요소가 죽을 때 끊깁니다.

데모는 키트의 일부가 아니라 **키트를 쓰는 소비자**라서 `src` 밖 `gallery/`에 둡니다 — `src` 안에 있으면 키트와 함께 게시돼 보통의 사용 경로에선 아무도 부르지 않는 코드가 모든 설치본에 실립니다. 그래서 데모는 게임이 키트를 쓰는 방식 그대로, 루트 내보내기 표 하나(`require("<이 폴더>/src")` → `Devui.Window` 같은 값, `Devui.Style`·`Devui.Overlay` 같은 다시 내보낸 타입)와 자기 설정 모듈(`gallery/Quad.luau`)만 씁니다. Studio 진입 스크립트 `gallery/DevuiDemo.client.luau`도 같은 폴더에 있습니다(아래 "Studio에서 보기").

## 위젯

모든 위젯은 **평범한 함수**이고 인스턴스 하나(또는 형제를 만드는 경우 `Slot`)를 돌려줍니다. 이름은 Iris와 같습니다.

| 그룹 | 위젯 | 한 줄 설명 |
|---|---|---|
| 창 | `Window`, `WindowManager` | 드래그·크기 조절·아이콘으로 접기·닫기 되는 창, 클릭하면 맨 앞으로(`ZIndex` 관리), 배치 내보내기·불러오기 |
| 레이아웃 | `SameLine`, `Group`, `Indent`, `Separator`, `SeparatorText` | 가로 줄 / 세로 묶음 / 들여쓰기 / 구분선 |
| 글 | `Text`, `TextWrapped`, `TextColored`, `TextDisabled`, `LabelText` | 한 줄·줄바꿈·색·흐림·`값 라벨` 한 줄 |
| 버튼 | `Button`, `SmallButton` | 클릭 가능한 버튼(작은 쪽은 세로 패딩 없음), `Toggled`로 켜짐 모양(토글 단추·필터 칩), `Icon`(이미지 id — 글과 함께면 아이콘이 앞, 혼자면 정사각 아이콘 단추; 글 색을 따름) |
| 선택 | `Checkbox`, `RadioButton`, `Selectable`, `SelectableOption` | 체크 / 라디오(같은 `Source` 공유) / 한 줄 선택 행 |
| 입력 | `InputText`, `InputNum`, `DragNum`, `SliderNum`, `InputVector2`, `InputUDim2`, `InputColor3`, `ColorPicker3` | 글·숫자(±버튼)·드래그 숫자·슬라이더·벡터·UDim2·색(견본을 누르면 피커), 색 편집 패널 |
| 구조 | `Tree`, `CollapsingHeader`, `TabBar` / `Tab`, `Table`, `VirtualRows` | 접히는 노드·헤더, 탭(`NoPages`면 단추 줄만 — 세그먼트 고르기), 키로 재활용되는 표, 가상화된 고정 높이 행 목록(`Follow`면 끝 따라가기, `RowIndexAt(list, y)`로 화면 Y의 행 번호) |
| 규칙(위젯 아님) | `Selection`, `TreeRows`, `ColorModel` | 다중 선택 규칙 — 클릭·Ctrl/Cmd·Shift 결과와 기준점, 사라진 키 빼기, 지금 눌린 키로 모드; 색 계산(HSV, 색조 보존, hex); 트리 평탄화 — 펼친 노드만 보이는 행으로(지연 자식·페이징), `VirtualRows`와 짝지어 가상 트리 |
| 표시 | `ProgressBar`, `PlotLines`, `PlotHistogram` | 진행 막대, 선 그래프, 막대 그래프 |
| 팝업 | `Combo`, `ComboArray`, `ComboEnum`, `MenuBar` / `Menu` / `MenuItem` / `MenuToggle`, `OpenMenu`, `MenuButton`, `PopupPanel`, `OpenDialog`, `OpenConfirm`, `OpenCopyDialog`, `OpenColorPicker`, `Tooltip` | 드롭다운, 메뉴(중첩 가능 — 막대의 메뉴가 열린 동안 다른 제목에 마우스를 올리거나 누르면 그 메뉴로 바뀜, 항목은 `Hooks`로 툴팁, `KeepOpen`이면 눌러도 메뉴가 열려 있음), `OpenMenu`(아무 좌표·사각형에서 지금 여는 메뉴 — 우클릭 메뉴), `MenuButton`(`OnClick`이 있으면 본체 + ▾ 분할 단추, 없으면 단추 전체가 메뉴; 우클릭도 메뉴), `PopupPanel`(메뉴가 쓰는 팝업 몸통 — 직접 여는 팝업용). 대화상자 `OpenDialog`(여는 창이나 화면 가운데에 지금 열림, 바깥을 눌러도 안 닫힘; `Modal`로 막는 범위 — `"Window"`(기본, 그 창 내용을 덮어 입력을 막음), `"Global"`(화면 전체), `"None"`)와 확인 도우미 `OpenConfirm`(`OnResult(ok)`가 한 번 — 확인 단추만 true, 취소·Escape·닫기는 false). 복사 대화상자 `OpenCopyDialog`(클립보드 API가 없는 게임에서 글을 전체 선택해 두고 Ctrl+C로 가져가게 함). 팝업은 화면 안에 머뭅니다(넘치면 붙은 사각형 반대쪽으로 뒤집고 안으로 밈), 호버 툴팁 |
| 기반 | `Style`, `Interaction`, `Overlay`, `WindowManager`, `NumberFormat` | 테마·입력 훅·팝업 층·창 z-순서·숫자/색 문자열 도우미 |

`Kids(a, b)`는 위젯이 아니라 **함수**입니다 — `q.Slot({ a, b })`(수동 CRUD `Slot<Instance>`)를 돌려주는 도우미로, 컨테이너의
`Children`에 넘깁니다. `Util`과 `Types`도 루트에서 접근은 되지만 **키트 내부용**입니다(안정 약속 없음; props 타입은
`Devui.ButtonProps`처럼 루트에서 바로 꺼내 쓰세요 — 모든 위젯의 `…Props`, `Manager`, `Popup`, `MenuScope`, `TableColumn`, `TabDef`).

위젯마다 헤더 주석에 props 전체가 있습니다. 모든 위젯이 따르는 표준 규칙은 `src/init.luau` 머리의 "HOW TO WRITE A
DEVUI WIDGET"입니다.

### 값 규약: 제어 / 비제어 `Source`

- **표시만 하는 값**(`Text`, `Value` of `ProgressBar` …)은 `T | State<T>`입니다. 상태를 넘기면 따라 움직입니다.
- **위젯이 쓰는 값**(`Checkbox.Value`, `InputNum.Value`, `Window.Open` …)은 `Source<T>` props입니다.
  - **제어**: `Source`를 넘기면 위젯이 그 `Source`에 씁니다(사용자 조작 때). 바깥에서 `:Set`하면 UI가 따라옵니다 — 양방향.
  - **비제어**: 안 넘기면 위젯이 내부 `Source`를 만들어 혼자 동작합니다.
- **필수인 `Source`**(비제어가 말이 안 되는 것): `RadioButton.Value`, `SelectableOption.Value`(그룹이 한 `Source`를 공유), `Combo.Value`,
  `ComboArray.Index`, `ComboEnum.Value`(고른 값이 곧 위젯의 결과). 나머지 `Source` props는 전부 선택입니다 —
  `Checkbox.Value`, `Selectable.Selected`, `InputText`/`InputNum`/`DragNum`/`SliderNum`/`InputVector2`/`InputUDim2`/`InputColor3`의 `Value`,
  `Window`의 `Open`/`Collapsed`/`Position`/`Size`, `Tree`/`CollapsingHeader`의 `Open`, `TabBar.Selected`(기본: 첫 탭), `MenuToggle`의
  `Value`(없으면 `Checked`/`OnToggle`의 제어 형태, 둘 다 없으면 내부 `Source`).
- 여러 위젯이 한 `Source`를 공유할 수 있습니다(`RadioButton` 그룹이 그 예: 같은 `Value`, 서로 다른 `Option`).
- `OnChange` 같은 콜백은 **사용자가 바꾼 경우에만** 불립니다(바깥 `:Set`에는 안 불림) — `Checkbox`/`RadioButton`/입력 위젯/`Combo*`/
  `Tree`/`CollapsingHeader`/`TabBar` 모두 같은 약속입니다.
- 위젯은 자기 `Source`에 쓸 때 이벤트 핸들러에서 `:Set`/`:SetIfChanged`를 부르고, `Compute`에서는 절대 쓰지 않습니다.
- **[2026-10-20] `Source` prop의 방향은 셋입니다** — 이름이 아니라 이 규약과 위젯 머리 주석이 방향을 말합니다(세 모델 이름 검토가 함께 짚은 점).
  - **양방향**(위 제어 `Source`): 위젯이 쓰고, 밖에서 쓰면 위젯이 따릅니다 — `Value`류, `Open`, `Window.Focused`·`InputText.Focused`(써서 포커스를 요청).
  - **출력**: 위젯만 씁니다. 밖에서 써도 아무 일도 없습니다 — `Window.AvailableSize`.
  - **명령**: 주인만 씁니다. 쓸 때마다 위젯이 동작합니다(같은 값도 — quad의 `Set`은 늘 전파) — `VirtualRows.ScrollToRow`.

### 이름 규약 (키트 전체)

- **입력·콤보·체크 계열의 뒤따르는 라벨은 `Text`**입니다(`InputNum { Text = "speed", Value = … }`, Iris 관례) — `LabelText`만 값이 `Text`,
  라벨이 `Label`입니다(Dear ImGui의 `LabelText` 순서).
- `Value` = 위젯이 읽고 쓰는 `Source`, `Option` = 선택 위젯이 고르는 값(`RadioButton`/`SelectableOption`: `Value: Source<T>` + `Option: T`),
  `Disabled` = 회색 처리(`boolean | State<boolean>`), `Modifier` = 그 위젯 루트 요소의 Modifier(`LabelText`는 가로 줄 Frame).
- **호스트 `Name`은 소비자가 `Modifier`로 바꿀 수 있습니다** — `Devui.Button { Modifier = q.Modifier "TextButton" ():Name("Save") }`. 킷은 기본 이름(`Button` 등)을 기본 Modifier에 두므로 소비자의 `:Name(...)`이 이깁니다(`InputText`의 `FieldModifier` 필드·`SliderNum`의 `TrackModifier` 트랙도 같음). 안쪽 상자에 Ref·OnEvent·키 묶음을 넘기는 자리는 짝인 `FieldSpread`·`TrackSpread`(`q.Spread "TextBox" {…}` 등)입니다. 안쪽 자식 이름(`Track`·`Arrow` 등)은 고정입니다.
- **`Hooks: { any }?`** — 리프 위젯(`Button`/`SmallButton`/`Selectable`/`SelectableOption`/`Checkbox`/`RadioButton`/`Text` 계열)이 가진 탈출구입니다.
  리스트의 훅 값(`Tooltip` 핸들의 `.Hook`, `Interaction.pointerDown(fn)`, `q.OnRendered(...)` …)이 요소 배열 부분의 **끝**에 붙습니다:
  `Devui.Button { Text = "Save", Hooks = { tip.Hook } }`.
- **타입 인자 `<<T>>`가 필수인 호출**: `RadioButton<<T>>{…}`, `Combo<<T>>{…}`, `ComboArray<<T>>{…}`, `SelectableOption<<T>>{…}` — 해석기가 `Source<T>`
  인자에서 `T`를 추론하지 못합니다(`No valid instantiation could be inferred`). `Table`은 `Key`의 매개변수에 타입을 달면 추론되고,
  `TabBar<<K>>`는 `Selected`를 쓸 때만 필요합니다.

## Style과 Overlay

**Style** — 토큰(`State<Color3>`, `State<number>` …)의 모음입니다. 위젯은 `props.Style or Style.default`를 읽고 토큰을 프로퍼티에
그대로 묶으므로 값이 바뀌면 위젯이 즉시 다시 칠해집니다.

```luau
Devui.Style.default:SetScheme("Light")   -- "Dark" | "Light"
Devui.Style.default:SetDensity("Clear")  -- "Default"(13px 납작) | "Clear"(15px 둥근)
local mine = Devui.Style.new({ Scheme = "Dark", Dark = { ButtonColor = Color3.new(1, 0, 0) }, Metrics = { FrameRounding = 6 } })
Devui.Button { Text = "red", Style = mine }
```

토큰 이름은 Iris 설정 이름에서 `Color` 접미사를 뗀 것입니다(`Style.Color.Button`, `Style.Metrics.TextSize` …). 오버라이드는
`Style.new{...}` 시점에 정해집니다 — **토큰 하나만 실시간으로 바꾸는 setter는 없습니다**(Style Editor 창이 미리보기 Style을
다시 만들어 보여주는 이유). 창·팝업 배경은 기본으로 살짝 투명합니다(0.06, Iris와 같음 — 2026-10-20 유지 결정). 불투명하게 쓰려면
`Devui.Style.new({ Dark = { WindowBgTransparency = 0, PopupBgTransparency = 0 } })`처럼 만들어 넘기세요. 탭 단추 모서리는
`TabRounding` 지표가 정합니다(기본은 `FrameRounding`과 같음).

**Overlay** — 팝업이 그려지는 화면 루트의 한 층입니다. 두 가지 쓰는 법이 있습니다.

- **명시형(권장)**: ScreenGui마다 `local overlay = Devui.Overlay.new()`를 만들어 `overlay.Layer`를 ScreenGui에 한 번 놓고, 팝업을 여는 위젯
  (`Combo`/`Menu`/`Tooltip`)에 `Overlay = overlay`를 넘깁니다. 층은 ScreenGui와 같이 죽고, **죽는 순간 열려 있던 팝업은 전부 닫힙니다**
  (`OnClose`가 한 번씩 불리고 `Count`는 0, Escape 리스너 같은 소유자 정리도 그때 풀립니다). `overlay.Alive`(`State<boolean>`)로 층이 살았는지
  볼 수 있고, 죽은 overlay에 `Open`하면 에러, 위젯은 조용히 아무것도 안 합니다.
- **기본형**: `Overlay` prop을 안 주면 위젯은 **팝업을 열 때** `Devui.Overlay.getDefault()`를 씁니다. 첫 호출에 만들어지고, 그 층이 파괴되면
  다음 호출이 새것을 돌려줍니다(죽은 층을 다시 주지 않으므로 ScreenGui를 다시 만들어도 파괴된 인스턴스를 재부모화하는 `Quad0219`가 나지 않습니다).
  기본 층은 **ScreenGui 하나**에만 놓을 수 있습니다(층은 인스턴스 하나라 살아 있는 ScreenGui 둘이 동시에 가질 수 없고, 두 번째는 `Quad0160`입니다) —
  ScreenGui를 다시 지을 때마다 `Devui.Overlay.getDefault().Layer`를 그 하나에 놓으세요. 층이 아무 ScreenGui에도 안 붙어 있으면 `q.debug`가 켜진 때
  팝업을 열 때 한 줄을 출력합니다. (옛 `Overlay.default` 값은 없어졌습니다 — require 시점에 인스턴스를
  만들어 첫 ScreenGui와 함께 죽던 싱글턴이었습니다.)

ScreenGui는 **`ResetOnSpawn = false`**로 만드세요 — 층은 quad가 만든 인스턴스라 리스폰이 뒤에서 파괴하면 안 됩니다. 층은 투명하고 `Active`가
아니라 팝업이 없는 곳의 클릭은 그대로 통과합니다. `Window`의 `ZIndex`는 `WindowManager`가 **순위**로 관리하므로 포커스를 몇 번 옮겨도
층(ZIndex 1000)을 넘지 않습니다 — 창 하나가 순위 덩어리 세 칸(창틀·표면·크기 손잡이)을 쓰므로 살아 있는 창 333개까지입니다.

**창의 구조 — 표면과 장식.** `WindowManager`는 컴포지터입니다(Wayland의 서버 쪽 장식과 같은 자리). `Window`가 돌려주는 루트(`Name = "Window"`)는
내용 표면(스크롤 영역)뿐이고, 창틀(배경·테두리)과 제목줄을 담은 `WindowDecoration`, 크기 손잡이 `WindowResizeGrip`은 관리자가 만들어 **루트와 같은
부모에 형제로** 놓습니다. 루트는 앱이 놓은 자리에 그대로 두고, 장식이 루트의 `Parent`를 따라가며(부모가 없으면 장식도 없음) 루트가 지워질 때 같이
지워집니다 — 장식을 직접 옮기지 마세요. `Position`·`Size`는 제목줄을 포함한 바깥 사각형이고 루트는 제목줄 아래 나머지 자리에 놓입니다.
`Title`·`No*` 플래그·`MinSize`·`Icon`은 표면이 관리자에게 주는 힌트입니다.

**접기 — 아이콘.** 접힌 창은 제목줄만 남지 않고 작은 정사각 아이콘(`WindowIcon`, 한 변 = `FrameHeight` 두 배, 루트의 형제)이 됩니다.
아이콘은 창의 `Position`(바깥 사각형 왼쪽 위)에 놓이므로 펼치면 그 자리에서 열립니다. 그림은 `Icon = "rbxassetid://…"`, 없으면 제목 첫 글자를
둥근 사각형에 그립니다(이미지 업로드 필요 없음). 아이콘을 **누르면** 펼쳐지고(`Collapsed:Set(false)`), **끌면** 창이 옮겨집니다(`Position`에 씀,
제목줄 끌기처럼 화면 안에 남음 — 아이콘 자체가 창). 둘은 6픽셀(Dear ImGui `MouseDragThreshold`) 문턱으로 가릅니다. 게임패드·키보드로
고른 아이콘을 누르면(`Activated`) 펼쳐집니다. 접힌 동안 창틀·제목줄·크기 손잡이·표면은 숨고, 아이콘을 눌러도 그 창이 앞으로 옵니다.
접기는 닫기가 아니라 포커스 넘김에 걸리지 않습니다.

**닫기 요청 — `OnCloseRequest: (() -> ())?`.** 주면 제목줄의 × 단추는 이 함수만 부르고 `Open`을 건드리지 않습니다 — 닫을지는 앱이 정합니다
(저장할지 묻고 `Open:Set(false)`, 또는 창을 부수고 `manager:ForgetWindow(key)`). 주지 않으면 × 단추가 `Open`을 `false`로 씁니다(지금까지와 같음). `NoClose`면 × 단추가 없어 불리지 않습니다.

창 안의 **어떤 위젯을 눌러도**(버튼·체크박스·입력 칸 포함) 그 창이 앞으로 옵니다 — 누름은 포인터 아래 첫 버튼·입력 칸에서 멈춰 창 프레임에
오지 않으므로, `WindowManager`가 전역 누름(`UserInputService.InputBegan`, 마우스 왼쪽·터치) 하나를 듣고 그 누름이 간 창을 앞으로 올립니다(창이
하나라도 있는 동안만 연결). 판정은 엔진이 누름을 주는 곳과 같습니다: `PlayerGui:GetGuiObjectsAtPosition`의 목록을 위에서부터 보아, 창 밖에서
누름을 받는 것(버튼·입력 칸·`Active`인 요소 — 열린 팝업의 행이나 바깥 클릭 막이, 다른 ScreenGui의 HUD 버튼)이 먼저 나오면 포커스를 바꾸지 않고,
입력을 받지 않는 것(툴팁, 투명한 틀)은 지나쳐 그 아래 창을 올립니다. 숨은 창이나 트리에서 뗀 창은 맞지 않습니다. PlayerGui가 없는 곳(UI Labs
같은 스토리 호스트의 플러그인 위젯)에서는 창 사각형으로 판정하고, 입력을 받는 열린 팝업 위의 누름만 거릅니다. 직접 만든 창 모양에
`manager:Register()`를 쓰면 `slot.Hook`을 그 루트의 배열부에 넣어야 이 동작이 붙습니다. 포커스된 창을 닫거나 파괴하면 남은 열린 창 가운데 맨 위
창이 포커스를 받고, 닫았던 창을 다시 열면 맨 앞으로 오며 포커스를 받습니다(배치 불러오기가 연 창은 제외 — 불러오기는 아무것도 앞으로 올리지 않음). **남은 높이 채우기**: 창 안 자식 하나에
`q.Elem "UIFlexItem" { FlexMode = Enum.UIFlexMode.Fill }`을 주면 다른 자식이 남긴 높이를 차지하고 창 크기를 따라갑니다(Studio 확인 2026-10-20 —
창보다 자식이 크면 스크롤 대신 그 자식이 줄어듭니다). 숫자가 필요하면 `AvailableSize = Source<Vector2>`를 넘기세요 — 자식이 쓸 수 있는
크기(보이는 내용 영역에서 스크롤바와 창 안쪽 여백을 뺀 값)를 창이 거기 씁니다. **메뉴바 자리**(**[2026-10-21]**): `MenuBar = Devui.MenuBar({ ... })`(아무 GuiObject나 —
아이콘 단추 줄도 됨)를 넘기면 제목줄 바로 아래, 창 안쪽 여백 **밖**에 가로로 꽉 차게 놓이고 스크롤되지 않습니다. 내용은 그 아래에서 시작하고 창이
메뉴바의 높이를 따라가므로 `AvailableSize`에서도 그 높이가 저절로 빠집니다(앱이 높이를 빼지 않음). 탭으로 묶이면 고른 창의 메뉴바가 보입니다.
`Devui.MenuBar`는 이 자리를 위해 만들었지만 어디에 놓아도 됩니다. 밖에서 창을 다루는 길은 주인이 쥔 Source입니다 — 넘긴 `Open`에 `:Set(true)`를 하면 이미 열린 창도 맨 앞으로 올라오고(quad의 `Set`은 같은 값도 전파합니다; 상태만 맞추고 올리지 않으려면 `:SetIfChanged(true)`), `Focused = Source<boolean>`은 양방향입니다 — 창이 포커스 여부를 거기 쓰고, 밖에서 `true`를 쓰면 그 창을 앞으로 올려 포커스를 주고 `false`를 쓰면 포커스를 놓습니다(어느 창도 포커스 없음; 닫힌 창은 `true`를 무시하니 `Open:Set(true)`로 여세요; 핸들 객체는 없습니다)(Dear ImGui와 같음 — 처음부터 열린 창은 포커스를 빼앗지 않음. 다만 처음부터 `true`인 `Focused`를 넘기면 그것은 요청으로 봅니다). 창의 빈 곳을 누른
것은 창틀(`WindowDecoration`) 전체를 덮는 투명 버튼 `ClickSink`(ZIndex 0)에서 멈춰 아래 창의 위젯으로 새지 않습니다(표면의 빈 곳을 누른 것도 바로
아래의 이 버튼에 닿습니다). 포커스 넘김은 창의 `Open`을 따르므로 접기(루트가 숨음)는 닫기로 치지 않습니다. 타이틀바로 끌 때 창은 컨테이너 안에 타이틀바가 남도록 잘리고(Dear ImGui와 같은 규칙 — 가로로 `FrameHeight`(기본 19)
픽셀, 세로로 타이틀바 전체), 컨테이너가 **줄어들면** 바깥으로 나간 창을 안으로 데려옵니다(`Position` Source에 씀). 프로그램이 준 위치는 그 밖에는
건드리지 않습니다.

창 안 깊은 곳(창을 직접 받지 않은 컴포넌트)에서 창을 다뤄야 하면, 창의 Source들을 [`q.Store`](../docs/reference/core/04-store.md)나
[`q.Context`](../docs/reference/sugar/01-context.md) 가방에 담아 내려 주고, 다루는 일은 그 가방을 받는 **평범한 함수**에 두세요.
devui는 이 키나 함수를 따로 제공하지 않습니다(**[2026-10-15 기준]** 그것을 읽는 devui 위젯이 없어서) — 어떤 값을 담을지는 창을 만든 쪽이 정합니다.

```luau
local WindowP = q.Context.Provider("Window")           -- 이 게임의 키
local win = q.Store({ Open = q.Source(true), Focused = q.Source(false) })
local ctx = q.Context():Set(WindowP, win)

local function focusWindow(c: q.Context)               -- 다루는 일은 밖의 함수로
	c:Get(WindowP).Open:Set(true)                         -- 지을 때 부르면 아직 없어 Quad0038 — 이벤트에서 부른다
end

Devui.Window({ Title = "Tools", Open = win.Open, Focused = win.Focused, Children = q.Slot({
	SomePanel({ Context = ctx }),                          -- 그 안 어딘가의 버튼: OnClick = function() focusWindow(ctx) end
}) })
```

### 가장자리 붙이기

창의 제목줄을 끌어 포인터를 컨테이너(창 루트의 부모)의 **왼쪽이나 오른쪽 끝**에 가져가면 붙을 자리가 미리보기로 보이고, 그 자리에서 놓으면 창이
그쪽 가장자리에 붙습니다. 미리보기(`WindowDockPreview`)는 띠처럼 관리자가 창과 같은 컨테이너에 그리는 입력 없는 사각형이고, 끌고 있는 창을
포함한 모든 창 위에 놓입니다 — Overlay 층을 어디에 놓았는지(또는 놓지 않았는지)와 무관하게 보입니다.

- **모양**: 붙은 쪽 화면 끝에 컨테이너 세로 전체를 차지하는 **띠**(`WindowDockStrip`, 너비 = `FrameHeight`)가 생기고, 그 바로 안쪽에 패널(창틀·제목줄·
  내용)이 놓입니다 — 왼쪽이면 `|띠|패널|`, 오른쪽은 거울상. 패널 높이는 컨테이너를 따라가고(`AvailableSize`도 따라감), 컨테이너가 Roblox 상단바
  밑까지 덮으면(`IgnoreGuiInset`을 켠 ScreenGui 등) 패널은 상단바 높이(`GuiService.TopbarInset`)만큼 아래에서 시작합니다 — 띠는 그대로 세로 전체입니다.
  위·아래 가장자리에는 붙지 않습니다(기본 UI·터치 UI와 겹침).
- **띠는 벽입니다**: 같은 컨테이너의 떠 있는 창은 띠 영역에 들어가지 못합니다 — 끌 때 그쪽 가장자리가 띠에서 멈추고, 띠가 새로 생기면 이미 걸쳐 있던
  창도 밀려 들어옵니다. 펼친 패널은 벽이 아니라 떠 있는 창을 **덮습니다**(밀어내지 않음).
- **겹침·포커스는 다른 창과 같습니다**: 붙은 창도 같은 관리자의 창 하나라 펼치면 맨 위로 오고 포커스를 받으며, 누르면 앞으로 오고, 다른 창을 누르면
  그 창이 올라옵니다.
- **띠 누르기**(누르기 **직전**의 포커스로 정함): 접혀 있으면 펼치고 올려 포커스를 줍니다. 펼쳐져 있는데 포커스가 없으면 올려 포커스만 줍니다.
  펼쳐져 있고 포커스가 있으면 접습니다. 게임패드·키보드로 고른 띠는 지금 포커스로 정합니다. 화살표는 패널이 갈 쪽을 가리킵니다(왼쪽 도크가 접혀
  있으면 `>`, 펼쳐져 있으면 `<`).
- **접기**: 붙은 창의 `Collapsed`는 패널을 숨기고 띠만 남깁니다(떠 있는 창처럼 아이콘이 되지 않음). 접힌 동안 띠의 평소 색은 `TitleBgCollapsed`(기본은 반투명 — 뒤의 게임이 비침)입니다. 제목줄의 접기 단추도 같은 `Collapsed`입니다.
  나뉜 덩어리가 붙어 있으면 다릅니다 — 창의 `Collapsed`와 접기 화살표는 그 창 **칸**의 접힘이고, 패널 전체는 띠를 눌러 접습니다(아래 "분할" 절).
- **너비**: 패널 안쪽 가장자리의 얇은 손잡이(`WindowDockResize`)로 바꿉니다. 범위는 `MinSize.X`(없으면 `FrameHeight` 두 배)에서 컨테이너 너비의
  절반까지이고, 컨테이너가 줄어도 절반으로 맞춰집니다(큰 화면에서 저장한 너비를 작은 컨테이너에 불러오면 맞춘 값이 저장되므로, 저장 → 불러오기 → 저장의 `Width`가 처음과 다를 수 있습니다). 처음 붙을 때 너비는 창의 `Size.X`를 이 범위에 맞춘 값이고, 떼었다 다시 붙이면 기억한 너비를 씁니다. `NoResize`면 손잡이가 없습니다.
- **떼기**: 붙은 창의 제목줄을 6픽셀 넘게 끌면 떠 있는 창이 됩니다 — 기억한 `Size`로, 포인터가 제목줄의 같은 자리에 오도록 놓이고 끌기가 이어집니다.
- **`Position`·`Size`는 떠 있을 때의 사각형만 기억합니다.** 붙어 있는 동안 앱이 이 Source에 써도 패널은 움직이지 않고, 떼면 그 값으로 돌아갑니다.
  붙은 창의 실제 크기는 `AvailableSize`(또는 루트의 `AbsoluteSize`)로 읽으세요 — `Size`에서 제목줄 높이를 빼 내용 크기를 구하는 코드는 붙어 있는 동안 맞지 않습니다.
- **한쪽에 하나**: 한 관리자에서 한 가장자리에는 열린 창 하나(또는 탭 묶음이나 나뉜 덩어리 하나)만 붙습니다. 이미 차 있는 쪽 끝 띠로 끌어 놓으면
  붙지 않고 그쪽 패널에 **탭으로 합쳐집니다**(미리보기가 그 패널을 덮음 — 아래 "탭 묶음" 절; 그 패널이 접혀 있으면 아무 일도 없음). 그쪽이 나뉜
  덩어리면 포커스가 마지막으로 있던 칸(없으면 첫 칸)에 합쳐지고 미리보기는 그 칸을 덮습니다(아래 "분할" 절).
- **닫기와 다시 열기**: 붙은 창을 닫으면(`Open = false`) 패널과 띠가 모두 숨고 그쪽이 비지만, 창은 붙어 있던 쪽과 너비를 기억합니다. `Open:Set(true)`로
  다시 열면 그쪽으로 돌아가고, 그 사이 다른 창이 그쪽을 차지했으면 떠 있는 창(기억한 `Position`·`Size`)으로 열립니다.
- **`NoDock = true`**: 끌어서는 가장자리에 붙지 않습니다(배치 불러오기로는 붙을 수 있음). 탭 합치기는 막지 않습니다 — 다른 창에 합쳐지고, 다른 창이
  합쳐 들어올 수도 있습니다(그 묶음은 끌어서는 가장자리에 붙지 않음). **`NoMove`**면 끌어 붙이기도 끌어 떼기도 없습니다. 접힌 아이콘을 끌어서는 붙지 않습니다.
- 키 없는 창도 똑같이 붙고, 배치 저장에서만 빠집니다.

### 탭 묶음

창의 제목줄을 끌어 **같은 관리자·같은 컨테이너**의 다른 창 위에 놓으면 두 창이 **탭 묶음** 하나가 됩니다 — 사각형 하나, 데코레이션 하나에 창 여럿이
들어가고 고른 창의 내용만 보입니다. 창 요소를 옮겨 담지 않습니다(관리자가 각 창의 자리와 보임만 정함).

- **놓는 자리**(포인터로 판정, 수정 키 없음): 대상 창(또는 묶음)의 **제목줄(탭 줄) 위** → 포인터가 있는 탭 자리에 끼워 넣음, 그 밖의 **가운데**(가로·세로
  모두 사각형의 20%~80%) → 맨 끝 탭으로. 사각형 가장자리의 네 띠(위·아래·왼쪽·오른쪽 20%)에 놓으면 대상을 그쪽으로 **반으로 나눕니다**(아래
  "분할" 절 — 3단계까지는 아무 일도 없던 자리). 제목줄은 위 띠보다 앞섭니다. 탭으로 합칠 때는 미리보기(`WindowDockPreview`)가 대상의 바깥 사각형 전체(나뉜 덩어리 안에서는 그 칸의 사각형)를 덮습니다. 이미 다른 묶음이 붙은 화면
  끝 띠에 놓으면 그 묶음에 합쳐지고(그 묶음이 접혀 띠만 남았으면 대상이 아니라 아무 일도 없음 — 나뉜 덩어리면 포커스가 마지막으로 있던 칸에),
  붙은 패널 위에서도 같은 판정입니다(나뉜 패널이면 아래 "분할" 절의 칸·바깥 띠 판정). 판정은 포인터 아래 **맨 위 창**이 정합니다 — 그 창이 합칠 수 없는 창(제목줄
  없는 창, 접힌 아이콘 등)이면 그 아래 창이 가려진 것으로 보고 아무 일도 없습니다.
- **합칠 수 있는 것**: 둘 다 제목줄이 있고(`NoTitleBar` 창은 합치지도 합쳐지지도 않음), 대상이 열려 있고 펼쳐져 있으며(접힌 아이콘은 대상이 아님 —
  아이콘을 끌어서도 합쳐지지 않음), 끄는 창이 `NoMove`가 아닐 때. 묶음 전체를 끌어(탭 줄의 빈 곳) 다른 창에 놓으면 탭이 차례 그대로 모두 들어갑니다.
  합쳐 들어간 창이 골라지고 묶음이 맨 위로 올라와 포커스를 받습니다.
- **탭 줄**: 열린 창이 **둘 이상**일 때만 제목줄 자리에 탭 줄이 보입니다(하나면 평범한 창과 같은 모양 — 나뉜 덩어리 안의 칸은 창이 하나여도 늘 보임, 아래 "분할"). 왼쪽에 접기 화살표, 그 뒤로 탭(`WindowTab`,
  제목 — 길면 잘림(잘린 동안 마우스를 올리면 전체 이름이 툴팁으로 뜸, 제목줄도 같음 — 기본 Overlay 층이 마운트돼 있을 때만), 넘치면 고르게 줄어듦; **[2026-10-21 기준]** 탭 너비는 글자 길이를 재지 않고 `FrameHeight`의 8배를 넘지 않으며, 2배까지 줄고도
  탭 줄 끝 안에 들어가지 않는 탭은 그리지 않습니다 — 창을 탭보다 좁게 줄여도 탭이 옆 창 위로 삐져나오지 않음). 탭 줄 오른쪽 끝 `FrameHeight` 두 배는 탭이 차지하지 않는 빈 곳으로 남아 묶음을 끄는 자리가 됩니다. 탭 줄 배경은 제목줄 색(포커스에 따라 `TitleBg`/`TitleBgActive`), 탭은 `Tab`·`TabHovered`, 고른 탭은
  `TabActive`입니다. **×**는 고른 탭과 포인터가 올라간 탭에 보이고, 그 창의 `NoClose`면 없으며 그 창의 `OnCloseRequest`를 따릅니다(제목줄 × 단추와 같음).
- **탭 다루기**: 탭을 누르면 그 창이 골라지고 묶음이 앞으로 옵니다. 탭 줄 안에서 끌면 순서가 바뀌고, 탭 줄 밖으로(위·아래, 또는 묶음 옆으로) 끌면
  그 창이 **떨어져 나옵니다** — 자기가 기억하는 크기로, 포인터가 제목줄의 같은 자리를 잡은 채로 뜨고 끌기가 이어집니다(그대로 다른 창에 합치거나
  가장자리에 붙일 수 있음). `NoMove` 창의 탭은 순서만 바뀝니다.
- **사각형은 묶음의 것**: 합칠 때 대상의 사각형이 묶음의 사각형이 되고, 그 뒤로 묶음 안 창들의 `Position`·`Size` Source는 **합치기 전 값을 그대로
  기억**합니다(묶음을 옮기거나 크기를 바꿔도 쓰지 않음 — 붙은 창과 같은 규칙). 묶음에 창이 **하나만** 남으면(열린 창·닫힌 창, 대기 키·키 없는 창 모두 셈 —
  파괴된 키 있는 탭 창은 대기 키로 남으므로 묶음이 풀리지 않음; 탭 줄이 보이는 기준인 "열린 창 둘 이상"과는 다름) 그 창이 묶음의
  사각형을 자기 `Position`·`Size`로 가져가 그 자리에 평범한 창으로 남습니다.
- **닫기**: 탭을 닫으면(`Open = false`) 그 탭과 내용이 숨지만 창은 **묶음에 남습니다**(자리 기억). `Open:Set(true)`로 다시 열면 같은 묶음의 같은 탭
  자리로 돌아와 골라지고 묶음이 올라와 포커스를 받습니다. 고른 탭을 닫으면 다음 탭이(없으면 이전 탭이) 골라지고, 모든 창이 닫히면 묶음 전체가
  숨습니다. 숨은 열린 탭에 `Focused:Set(true)`를 써도 그 탭이 골라집니다.
- **접기는 묶음 단위**입니다(나뉜 덩어리 안에서는 칸 단위 — 아래 "분할"): 접기 화살표가 모든 창의 `Collapsed`를 같은 값으로 쓰고, 앱이 창 하나의 `Collapsed`를 바꿔도 묶음 전체가 접히거나 펼쳐집니다.
  떠 있는 묶음은 고른 창의 아이콘(`Icon`, 없으면 첫 글자) 하나가 되고, 붙은 묶음은 띠만 남습니다.
- **플래그**: 창 하나라도 `NoMove`면 묶음을 끌 수 없고, 열린 창 하나라도 `NoResize`면 크기 손잡이가, `NoCollapse`면 접기 화살표가 없습니다. 최소
  크기는 창들의 `MinSize` 중 축마다 큰 쪽입니다.
- **겹침**: 묶음은 한 덩이로 쌓입니다 — 다른 창이 묶음 사이에 끼지 않고, 어느 부분을 눌러도(숨은 창의 탭 포함) 묶음 전체가 올라오며, 묶음의 포커스
  창(`Focused`)은 고른 창입니다. 창 하나가 여전히 ZIndex 세 칸을 쓰므로 Overlay 층 아래 창 상한 333개는 그대로입니다.
- **파괴**: 키 있는 탭 창을 파괴하면 그 키가 묶음의 탭 자리에 대기로 남아, UI를 다시 지으면 같은 자리로 돌아옵니다. 키 없는 창(또는 `ForgetWindow`한
  키)은 묶음에서 빠집니다.
- **가장자리**: 붙은 묶음의 쪽과 너비는 묶음의 것입니다. 탭 줄의 빈 곳을 끌어 가장자리에서 떼면 묶음 전체가 묶음의 떠 있는 사각형으로 포인터 아래에
  뜹니다. 도크 너비는 묶음이 **붙어 있는 동안만** 공유됩니다 — 떠 있는 묶음에 합쳐도 각 창은 자기가 기억하는 도크 너비를 그대로 갖고(다시 붙일 때
  그 너비), 떠 있는 묶음을 끌어 붙이면 고른 창의 너비로 붙은 뒤 모든 창이 따라가며, 붙은 묶음에서 떨어져 나온 창은 그때의 묶음 너비를 기억합니다.
- 키 없는 창도 똑같이 묶이고, 배치 저장에서만 빠집니다.

### 분할

창을 끌어 다른 창(또는 탭 묶음)의 **가장자리 20% 띠**에 놓으면 그 창을 그쪽으로 **반으로 나눠** 놓은 창이 그 절반을 차지합니다(Dear ImGui의
도킹과 같은 모양). 나뉜 덩어리도 사각형 하나·한 덩이 겹침이고, 칸(잎)마다 탭 묶음입니다. 나눈 칸을 다시 나눌 수 있습니다(몇 겹이든).

- **놓는 자리**(포인터 아래 **맨 위** 창이 판정 — 탭 묶음과 같음): 칸의 **탭 줄 위** → 그 칸에 탭으로(포인터 자리), 나뉜 덩어리의 **바깥 가장자리에서
  `FrameHeight` 두 배 안쪽 띠** → 덩어리 **전체**를 그쪽으로 나눔(미리보기가 덩어리 전체 길이로 그쪽 절반 — "긴" 미리보기), 그 안쪽에서는 포인터 아래
  **칸**의 판정 — 가운데(20%~80%) → 그 칸의 맨 끝 탭, 20% 띠 → **그 칸**을 반으로(미리보기는 그 칸의 절반). 앞섬은 탭 줄 > 바깥 띠 > 칸의 띠·가운데이고,
  닿는 단계는 두 단계뿐입니다 — 덩어리 전체(바깥 띠)와 포인터 아래 칸 하나(그 사이의 분할 단계는 없음). 모서리(두 띠가 겹치는 곳)는 띠 폭에 견주어 가장자리에 더 가까운 쪽으로 정합니다. 나뉘지 않은 창·묶음은 전체가 곧 칸이라 네 띠가
  그 창을 나눕니다. 예: 탐색기 창 아래 띠에 속성 창을 놓아 위아래로 나누고, 출력 창을 그 덩어리의 오른쪽 바깥 띠에 놓으면 왼쪽에 탐색기/속성, 오른쪽에 출력.
- **덩어리째 끌어 놓기**: 나뉜 덩어리를 탭 줄 빈 곳으로 끌어 다른 창에 놓을 때, **탭 자리**(탭 줄·가운데)면 덩어리의 창들이 모두 그 칸의 탭으로
  평평하게 들어가고(나뉜 모양은 없어짐, 칸 차례·탭 차례대로), **띠**(칸의 20% 띠·바깥 띠)면 덩어리의 나뉜 모양이 통째로 나뉜 한쪽이 됩니다.
- **놓았을 때 크기**: 대상은 자기 사각형을 그대로 두고 반으로 나뉩니다(비율 0.5). 미리보기가 놓을 창이 차지할 절반을 그대로 덮습니다. 놓은 창의
  `Position`·`Size` Source는 탭 묶음처럼 합치기 전 값을 기억만 합니다.
- **탭 줄**: 나뉜 덩어리 안의 칸은 창이 **하나여도** 탭 줄을 보입니다. 탭을 끌면 그 창이 떨어져 나오고(자기 크기로, 끌기가 이어짐), 탭 줄의
  **빈 곳**을 끌면 **덩어리 전체**가 옮겨집니다(붙은 덩어리면 전체가 떠 있는 사각형으로 떨어져 나옵니다 — 포인터는 가로로는 덩어리 너비에서의
  같은 비율 자리에, 세로로는 누른 칸의 탭 줄 안 같은 높이에 오도록, 그 칸이 떠 있는 사각형 안에서 놓일 자리를 기준으로 놓임).
- **분할선**(`WindowSplitter`): 두 칸 사이를 끌면 경계가 움직이고, 양쪽이 자기 최소 크기(칸 안 창들의 `MinSize` 중 큰 쪽, 기본은 `FrameHeight` 두 배
  정사각)보다 작아지지 않습니다. 덩어리 크기 손잡이의 최소 크기는 나뉜 모양 전체의 것입니다(나뉜 방향으로는 양쪽의 합, 가로지르는 방향으로는 큰 쪽).
  **양쪽 최소 크기가 함께 들어가지 않으면 최소 크기가 양보합니다** — 그 분할에서는 양쪽이 `FrameHeight` 두 배까지 줄 수 있어 분할선이 늘 움직이고,
  붙은 분할 패널의 최소 크기 합이 컨테이너 절반을 넘으면 너비 손잡이도 같은 작은 하한까지 움직입니다(창이 `MinSize`보다 좁아지는 것은 그때 고른 결과).
  한쪽이 접혀 있거나 덩어리의 열린 창 하나라도 `NoResize`면 분할선이 없습니다. 붙은 패널의 위아래 분할은 화면 높이를 따라 비율로 놓이고, 화면이
  낮아져 한쪽이 최소 크기보다 작아지면 경계가 그 최소 크기에서 멈춥니다(저장된 `Ratio`는 그대로라 화면이 다시 커지면 원래 비율로 돌아감).
- **작은 쪽**(**[2026-10-21]**): 분할선을 한쪽 최소 크기 너머로 `FrameHeight` 절반 이상 밀면 그쪽이 **작은 쪽**이 됩니다 — `FrameHeight` 네 배(최소
  크기가 그보다 작으면 최소 크기)로 줄고, 그 칸들의 내용이 덮개(`WindowDim`, 색은 `NavWindowingDimBg`)로 어두워집니다. 덮개는 누름을 먹어 안 보이는
  단추가 눌리지 않고, 작은 쪽의 창(덮개·탭·탭 줄)을 누르면 두 쪽이 자리를 바꿉니다(누른 쪽이 커지고 반대쪽이 작은 쪽) — 앱의 `Focused:Set(true)`도
  같습니다. 분할선·크기 손잡이·도크 너비 손잡이·화면 끝 띠를 누르는 것은 바꾸지 않으며, 분할선을 다시 최소 크기 안쪽으로 끌면 보통 경계로 돌아옵니다
  (저장된 `Ratio`는 작은 쪽인 동안 그대로). 작은 쪽 안의 분할선은 쓰이지 않습니다. 탭이 한 칸 안에서 창 사이를 오간다면, 이것은 창이 뭉친 두 영역
  사이를 오가는 것입니다(모바일처럼 높이가 모자랄 때). 칸 접기와는 함께 쓰이지 않습니다 — 분할의 한쪽 칸을 접으면 그 분할의 작은 쪽이 풀립니다.
  저장은 분할 노드의 `Small = 1 | 2`.
- **접기**: 칸의 접기 화살표는 **그 칸만** 접고 옆 칸이 자리를 차지합니다 — 위아래로 나뉜 칸은 탭 줄 한 줄만 남고(화살표가 오른쪽을 가리킴),
  좌우로 나뉜 칸은 화살표 든 세로 띠(`WindowFoldBar`, 너비 `FrameHeight`)가 되며 띠를 누르면 펼쳐집니다. **접기 규칙**: 칸은 **같은 분할의 반대쪽
  서브트리**(그 칸에서 위로 올라가며 처음 만나는, 반대쪽이 아직 보이는 분할의 반대쪽 전체)에 펼쳐진 채 보이는 칸이 있을 때만 접힙니다 — 그렇지 않으면
  화살표가 없고 앱이 `true`를 써도 `false`로 되돌려지며, 반대쪽이 닫히거나 떼어져 이 조건이 깨지면 접힘이 풀립니다(그 창들의 `Collapsed`가 `false`로).
  그래서 한 분할의 양쪽이 모두 접히는 일은 없고, 그렇게 저장된 배치를 불러오면 둘째 쪽이 펼쳐집니다. 아직 등록되지 않은 대기 키는 **저장 때 열려
  있었으면** "보이는 칸"으로 셉니다(불러온 뒤 창이 하나씩 등록되는 동안 접힘이 풀리지 않음 — 다만 그동안 반대쪽 창이 아직 화면에 없으면 접힌 칸이
  잠깐 펼쳐진 모양으로 그려지고, 나머지가 등록되면 접힌 모양이 됩니다). 저장 때 닫혀 있던 대기 키는 세지 않습니다. 떠 있는 나뉜 덩어리는 **아이콘으로 접히지 않고**, 붙은 덩어리는 지금처럼 화면 끝 띠를 눌러 패널 전체를 접습니다.
  창의 `Collapsed`는 **그 창 칸의 접힘, 또는 (붙었을 때) 패널의 접힘**입니다 — 패널을 접어도 칸마다의 접힘은 따로 기억해서 펼치면 그대로 돌아옵니다(패널이 접힌 동안 앱이 창에 `true`를 써도 그 칸의 접힘으로 기억됨).
  앱이 나뉜 덩어리 안 창의 `Collapsed`에 `true`를 쓰면 그 칸이 접히고, `false`를 쓰면 그 칸이 펼쳐지며 패널이 접혀 있었으면 패널도 펼쳐집니다. 한 칸의
  창들은 칸의 접힘을 같이 씁니다.
- **닫기와 떼기**: 칸의 창이 모두 닫히면 그 칸이 숨고 옆 칸이 자리를 차지하며, 다시 열면(`Open:Set(true)`) 그 칸 자리로 돌아옵니다(모든 칸이 닫히면
  덩어리 전체가 숨음). 칸의 마지막 창을 떼어 내면 그 칸이 없어지고, 칸이 하나만 남으면 나뉘지 않은 탭 묶음(창이 하나면 평범한 창 — 덩어리 사각형을
  자기 `Position`·`Size`로 가져감)으로 돌아갑니다. 나뉜 덩어리에서 나온 창은 펼쳐진 채로 나옵니다.
- **가장자리**: 붙은 패널도 네 방향으로 나뉩니다(위아래 분할 = 한쪽 가장자리에 위아래로 쌓기). 덩어리가 붙은 화면 끝 띠에 놓으면 그 덩어리에서 포커스가
  마지막으로 있던 칸(없으면 첫 칸)에 탭으로 합쳐집니다. 덩어리를 끌어 빈 화면 끝에 놓으면 덩어리 전체가 붙습니다.
- **포커스와 겹침**: 누른 칸의 고른 창이 포커스 창이 되고 그 칸의 탭 줄만 활성 색입니다. 덩어리는 한 덩이로 쌓이고, 탭과 분할선은 덩어리 맨 위 칸에
  그려집니다(창 하나가 ZIndex 세 칸을 쓰는 것은 그대로라 창 상한 333개도 그대로). 덩어리의 크기 손잡이와 붙은 패널의 띠·너비 손잡이는 오른쪽 아래 칸의
  창이 그립니다.
- 키 없는 창도 똑같이 나뉘고, 배치 저장에서만 빠집니다.

### 창 배치 저장

devui는 **저장하지 않습니다** — 창 배치를 JSON으로 바꿀 수 있는 평범한 표(문자열·수·참거짓·배열·문자열 키 표)로 내주고 받기만 하고,
어디에 둘지(플러그인 설정, DataStore, 속성)는 앱이 정합니다. **창 내용은 저장하지 않습니다.**

- **`Key: string?`** — 창의 **신원**. 한 `WindowManager`의 살아 있는 창 사이에서 유일해야 하고, 겹치면 `Devui.Window: Key "…" is already used`
  에러입니다. **`Kind: string?`** — 창의 **종류**(생략하면 `Key`와 같음). 같은 종류의 창 둘(메모장 둘)은 `Kind`가 같고 `Key`가 다릅니다.
  `Kind`는 `Key`가 있을 때만 쓰입니다. 키 없는 창도 똑같이 동작하고 **배치에서만 빠집니다**(`q.debug`가 켜져 있으면 앱이 배치 API를 처음 쓴 뒤
  관리자마다 한 번 알림).
- 창 하나에 싣는 것: 열림(`Open`), 접힘(`Collapsed`), `Position`(UDim2), `Size` — 떠 있을 때의 **바깥** 사각형(제목줄 포함, 붙은 창도 이 값),
  붙은 가장자리와 그 너비(`Dock`·`DockWidth`), **탭 묶음과 분할**(아래 형식 — 노드 트리: 칸마다 탭·고른 탭·접힘, 분할마다 방향·비율, 덩어리의 사각형,
  그리고 창마다 합치기 전 자기 사각형).
  배치 전체에는 키 있는 **떠 있는** 묶음들의 **겹침 순서**도 실립니다(`Floating`의 차례, 아래 규칙). 제목·내용·포커스, 붙은 묶음들의 겹침 순서는 싣지 않습니다.

```luau
local manager = Devui.WindowManager.new()          -- (Devui.WindowManager.default도 같은 메소드를 가짐)
manager:ExportLayout(): WindowLayout                -- 지금 배치(아는 키 전부)
manager:ImportLayout(layout, factories?)            -- 배치 불러오기(아래 규칙)
manager:ExportWindow(key): WindowState?             -- 창 하나(모르는 키면 nil; 묶음 소속은 싣지 않음 — 다른 키가 얽힘)
manager:ImportWindow(key, state)                    -- 창 하나 불러오기(팩토리·겹침 순서 없음, 나머지 규칙은 같음; 묶인 창은 먼저 묶음에서 빠짐)
manager:ForgetWindow(key)                           -- 키를 배치에서 지우기(아래 규칙)
manager.Layout: State<WindowLayout>                 -- 배치가 바뀔 때마다 새 값(얼린 표) — 자동 저장은 여기에 Observer
```

**불러오기 규칙**(한 API — 언제 불러도 됩니다):

- 이미 등록된 키의 창은 그 자리로 옮깁니다 — 창의 `Position`·`Size`·`Open`·`Collapsed` Source에 값을 써 넣으므로 **앱이 쥔 Source가 그대로
  바뀝니다**. 저장된 `Kind`가 달라도 살아 있는 창의 `Kind`가 이깁니다.
- 아직 등록되지 않은 키는 **대기**로 두었다가 그 키의 창이 등록되는 순간 적용합니다(= 초기값 — 창을 만들기 전에 불러도 됩니다).
- **배치에 없는 창은 그대로 둡니다.** 대기 키는 다시 내보낼 때 그대로 실립니다(모르는 키를 지우지 않음 — 서버 없이 연 세션에서 저장해도
  서버 창 자리가 남음).
- 키 있는 창이 파괴되면 마지막 상태가 대기로 남습니다(UI를 부수고 다시 지으면 창이 제자리로 돌아오고, `Layout`도 바뀌지 않음).
- **`ForgetWindow(key)`**: 앱이 창을 정말로 닫을 때(File > Exit 같은 메뉴) 그 키를 배치에서 지웁니다. 대기 키는 바로 지우고, 살아 있는 창의
  키는 **그 창이 사라질 때** 지웁니다 — 그래서 "잊고 파괴"와 "파괴하고 잊기"가 같습니다. 지운 뒤 같은 키로 다시 만든 창은 저장된 상태 없이
  처음부터 시작합니다. 창이 사라지기 전에 그 키를 다시 불러오면 잊기가 취소되고, 모르는 키는 아무 일도 하지 않습니다.
- **겹침 순서**: `Floating`은 아래에서 위 차례입니다. 키 있는 창을 앞으로 올리면 그 키가 맨 위로 가고, 키 있는 창이 등록되면 저장된 차례대로
  다른 키 있는 창들 사이에 들어갑니다 — 배치를 먼저 불러 두고 창을 어떤 차례로 만들어도 저장된 대로 쌓입니다. 키 없는 창은 제 자리를 지킵니다.
  화면에 있는 창들에 배치를 불러오면 배치가 이름 댄 창들이 배치의 차례로 다시 쌓이고, 이름 대지 않은 키는 바로 아래의 이름 댄 창을 따라갑니다(그런
  창이 없으면 맨 아래에 남음). 포커스는 저장하지 않으므로 불러오기가 어느 창도 앞으로 데려오지 않습니다. **붙은 창의 겹침 순서는 저장하지 않습니다** —
  불러오면 붙은 창들이 떠 있는 창들 **아래**에서 시작합니다(띠가 늘 보이므로 묻히지 않음). 실행 중에 붙은 창을 올리면 다른 창처럼 맨 위로 옵니다.
- **가장자리**: 배치에 `Left`/`Right`가 있으면 그 키의 창이 그쪽에 붙고, 아직 없는 키면 그 창이 등록될 때 붙습니다. 그쪽을 이미 다른 열린 창이 쓰고
  있으면 떠 있는 창으로 시작합니다. 내보낼 때 한 가장자리에는 지금 그쪽에 열려 있는 창이, 없으면 그쪽을 기억하는 닫힌(또는 대기) 키 하나가 실리고,
  같은 쪽을 기억하는 나머지 키는 `Floating`에 실립니다 — 저장된 배치에 한쪽에 둘이 실리는 일은 없습니다.
- **탭 묶음**: 노드의 `Tabs`가 둘 이상이면 이름 댄 창들이 그 차례로 한 묶음이 됩니다(이름 댄 창은 먼저 지금 묶음에서 빠짐). 묶음의 사각형은 그 묶음의
  `Position`·`Size`이고, 창마다 `Windows[key].Position`·`Size`가 있으면 그것이 그 창의 자기 사각형(떼면 돌아갈 사각형 — 창의 Source에 써 넣음)이며,
  없으면 창의 Source를 건드리지 않고 떼어 낼 때 묶음의 크기로 뜹니다. 아직 없는 키는 그 창이 등록될 때 저장된 탭 자리로 들어갑니다. 내보낼 때
  묶음 노드에는 키 있는 창만 탭 차례로 실리고(`Selected`는 고른 창, 키가 없으면 첫 키 있는 열린 창), 키 있는 창이 하나도 없는 묶음은 실리지 않으며,
  `Windows[key].Position`·`Size`는 탭이 둘 이상 실리는 노드(키 있는 창 둘 이상 — 열린 창·닫힌 창·대기 키 합쳐)의 창 가운데 자기 사각형이 있는 창에만
  실립니다(키 없는 창이 빠져 탭 하나만 남은 노드는 평범한 창으로 저장되고 불러옵니다). 불러오기에서도 합칠 수
  있는 창만 탭이 됩니다 — 제목줄 없는 창이나 다른 컨테이너에 있는(나중에 그리로 놓인) 창은 그 노드에 혼자 있는 것처럼 평범한 창으로 놓이고(자기 사각형,
  없으면 노드의 사각형), 남은 창이 둘보다 적으면 묶음이 생기지 않습니다. 열린 창이 이미 다른 창·묶음이 붙은 가장자리로 묶음을 데려가려 하면 묶음은
  떠 있는 채로 열립니다(창 하나와 같은 규칙). 불러오기로 열린 창은 골라지지도 포커스를 받지도 않습니다.
- **분할**: 노드가 분할(`Split`)이면 이름 댄 창들이 그 트리 그대로 나뉜 덩어리가 됩니다 — 칸마다 위 탭 묶음 규칙, `Ratio`는 분할마다 첫째(왼쪽·위)
  칸의 몫, 칸의 `Collapsed = true`는 그 칸의 접힘입니다. 자기 사각형(`Windows[key].Position`·`Size`)은 트리 전체에 키가 둘 이상일 때 싣습니다. 탭이
  될 수 없는 창(제목줄 없음·다른 컨테이너)은 평범한 창으로 놓이고 나머지 트리는 그대로 만들어지며, 칸이 비면 그 칸이 빠지고 한쪽만 남은 분할은 그
  쪽이 됩니다. 아직 없는 키는 등록될 때 저장된 칸의 저장된 탭 자리로 들어갑니다. 떠 있는 나뉜 덩어리의 `Collapsed`는 거짓으로 읽고(아이콘이 되지
  않음), 붙은 덩어리의 `Collapsed`는 패널의 접힘입니다.
- **`factories`**: `{ [Kind] = function(key) }`. "이 신원의 창을 있게 하라" — 앱이 창을 만들고 부모를 정합니다(devui는 루트를 놓지 않음).
  **저장 때 열려 있던 키**에만, **아직 등록되지 않은 키**에만, 불러오기 한 번에 키마다 한 번 부릅니다(같은 종류 둘이면 두 키로 한 번씩 — 팩토리가 창을 만들기 전에 다시 불러오면 다시 불립니다). 맵에 없는 종류는
  대기로 남습니다. 팩토리가 그 키로 창을 만들면 대기 상태가 그 창에 적용됩니다.
- 모르는 `Version`이나 모양이 틀린 표는 `Devui.WindowManager:ImportLayout: …` 에러입니다(앱이 `pcall`로 감싸 옛 저장을 버릴 수 있음). 한 키가
  `Floating`과 가장자리 양쪽에, 또는 `Left`와 `Right` 양쪽에(또는 두 노드에) 있으면 "placed twice" 에러이고, `Windows`의 모든 키는 이 셋 중 한 곳에 자리가 있어야 합니다.
  노드의 `Tabs`는 비지 않은 문자열 키 배열(같은 키 두 번은 — 트리 어디에서든 — 에러), `Selected`는 그중 하나, 칸의 `Collapsed`는 참거짓이나 nil이어야
  하고, 분할 노드는 `Split`이 `"LeftRight"`·`"TopBottom"` 중 하나, `Ratio`가 0과 1 사이(양 끝 제외)의 수, `Children`이 노드 정확히 둘이어야 합니다
  (`Tabs`와 `Split`을 같이 가진 노드도 에러). `Dock`은 `"Left"`·`"Right"`·nil만, `Width`·`DockWidth`는 양수만 받고, 떠 있는 상태(`Dock` nil)에 `DockWidth`를 주거나 `Position`·`Size`의 수 개수가 틀려도 에러입니다(`ImportWindow`도 같은 검사).

`Layout`은 위치·크기·열림·접힘·겹침 순서·붙기·떼기·도크 너비가 바뀌거나 키 있는 창이 등록되거나 잊힐 때 새 값을 냅니다 — 내용이 같으면 내지 않고(포커스만 바뀜,
같은 배치 다시 불러오기), 불러오기 한 번은 한 번만 냅니다. 창을 끄는 동안에는 움직일 때마다 내므로 저장은 `q.Debounce`로 늦추세요.

**형식**(Version 1). 처음부터 트리 모양입니다 — 노드는 탭 셋(칸) 또는 이진 분할이고, 떠 있는 창 하나는 "탭 하나짜리 노드"를 가진 떠 있는
묶음입니다. 탭이 여럿인 노드가 탭 묶음입니다(닫힌 탭도 `Windows[key].Open = false`로 노드에 남음). 분할 노드는
`{ Split = "LeftRight" | "TopBottom", Ratio = 0.5, Children = { <노드>, <노드> }, Small = 1 | 2? }`(왼쪽|오른쪽, 위/아래 — `Ratio`는 첫째의 몫, `Small`은 작은 쪽인 자식)이고, 분할 안의 칸은
접혔을 때만 `Collapsed = true`를 가집니다. 노드 타입이 탭 셋과 분할의 합집합이라 `Node.Tabs`를 읽는 코드는 `Node.Split == nil`을 먼저 확인하세요. 아래 예제는 `test/spec.windowsplit.luau`가 그대로 읽어 불러오기를 검사합니다(첫 줄 모양을 바꾸면 스펙도 같이 고칠 것).

```luau
{
	Version = 1,
	Windows = {                                    -- 창마다(키로): 종류와 열림
		outline = { Kind = "outline", Open = true },
		["note-1"] = { Kind = "notepad", Open = false,
		               Position = { 0, 80, 0, 90 }, Size = { 240, 160 } },  -- 선택: 묶인 창의 자기 사각형(아래)
		explorer = { Kind = "explorer", Open = true },
		props = { Kind = "props", Open = true },
		output = { Kind = "output", Open = true },
	},
	Floating = {                                   -- 떠 있는 묶음, 아래에서 위 차례(겹침 순서)
		{
			Position = { 0, 60, 0, 60 },           -- UDim2: X.Scale, X.Offset, Y.Scale, Y.Offset (바깥 왼쪽 위)
			Size = { 300, 200 },                   -- 픽셀: 너비, 높이 (바깥, 제목줄 포함)
			Collapsed = false,
			Node = { Tabs = { "outline", "note-1" }, Selected = "outline" },   -- 탭 묶음(탭 하나면 평범한 창)
		},
		-- …
	},
	Left = {                                       -- 왼쪽에 붙은 창(선택; Right도 같은 모양)
		Width = 280,                               -- 도크 너비(픽셀)
		Collapsed = false,
		Node = {                                   -- 분할: 왼쪽에 탐색기 / 속성(위아래), 오른쪽에 출력
			Split = "LeftRight", Ratio = 0.6,
			Children = {
				{ Split = "TopBottom", Ratio = 0.5, Children = {
					{ Tabs = { "explorer" }, Selected = "explorer" },
					{ Tabs = { "props" }, Selected = "props", Collapsed = true },  -- 접힌 칸
				} },
				{ Tabs = { "output" }, Selected = "output" },
			},
		},
		Position = { 0, 60, 0, 60 },               -- 떼면 돌아갈 떠 있는 사각형(살아 있는 창이면 늘 채움, 사각형
		Size = { 300, 200 },                       --   없는 옛 저장도 읽음 — 그 대기 키는 비어 있을 수 있음)
	},
}
-- WindowState (창 하나):
{ Kind = "outline", Open = true, Collapsed = false, Position = { 0, 60, 0, 60 }, Size = { 300, 200 },
  Dock = "Left", DockWidth = 280 }               -- Dock: "Left" | "Right" | nil(떠 있음, 그때 DockWidth도 nil)
```

`WindowState`의 `Position`·`Size`는 선택(`{ number }?`)입니다 — `ExportWindow`는 살아 있는 창이면 늘 채우지만, 사각형 없이 읽은 가장자리의 대기 키와
자기 사각형 없이 묶인 대기 키는 비어 있을 수 있습니다. `ImportWindow`에 넘길 때 생략하면 창의 `Position`·`Size` Source를 건드리지 않습니다.

```luau
-- 자동 저장과 시작 때 불러오기 (plugin:SetSetting 예)
local HttpService = game:GetService("HttpService")
local saved = plugin:GetSetting("layout")
if saved then
	pcall(manager.ImportLayout, manager, HttpService:JSONDecode(saved), {
		notepad = function(key) openNotepad(key) end,   -- 열려 있던 메모장마다 한 번
	})
end
manager.Layout:Apply(q.Debounce { Time = 1 })            -- 끄는 동안은 한 번에 모아서
	:Observer(function(self) plugin:SetSetting("layout", HttpService:JSONEncode(self:Get())) end)
	:Subscribe()
```

## UI Labs / 입력 주입

UI Labs(Studio 플러그인)는 스토리를 플러그인 DockWidget 안에 그리는데, 거기서는 `UserInputService`가 입력을 받지 못한다.
대신 UI Labs가 `Environment.InputListener`(`InputBegan`/`InputChanged`/`InputEnded` + 위젯 좌표계의 `MouseMoved`)를 준다.
그래서 이 키트에서 `UserInputService`와 `GuiService:GetGuiInset()`을 만지는 곳은 전부 `src/Input.luau` 하나를 거친다
(드래그, Combo/Menu의 Escape, Tooltip 위치). 기본값은 엔진 서비스이고, 스토리에서만 바꾼다.

```luau
local Devui = require("<이 폴더>")
Devui.Input.use(Environment.InputListener)   -- 스토리 모드: 드래그·Escape가 리스너로 흐른다
-- ... 스토리가 끝날 때
Devui.Input.use(nil)                          -- 엔진 서비스로 복원
```

**앱 코드도 이 문을 쓰면 좋은 경우.** 스토리 호스트나 스펙에서도 돌릴 화면이라면 앱 코드도 `UserInputService`·`GetGuiInset()`
대신 `Devui.Input.service()`·`Devui.Input.guiInset()`을 쓰세요. 그러면 `Devui.Input.use(listener)` 한 번으로 그 화면 전체에 가짜
입력을 넣을 수 있습니다 — 스펙이나 에이전트가 `InputBegan`/`InputChanged`/`InputEnded` 신호를 가진 테이블을 만들어 `InputObject`
모양의 값(마우스·터치·키)을 쏘면 실제 장치 없이 터치 같은 경로도 시험됩니다. 게임 안에서만 도는 코드는 엔진 서비스를 직접 써도
됩니다. 키트가 오래 쥐는 연결(창 올리기, hover 추적)은 `use`가 새 서비스로 다시 잇지만, 앱이 직접 연 연결은 따라가지 않으니
`use` 뒤에 다시 연결하세요(2026-10-20 결정).

`Input.service()`는 사용 시점에 현재 서비스를 돌려주므로 require 뒤에 바꿔도 된다. 덮어쓰는 동안 `GetMouseLocation()`은
마지막 `MouseMoved` 위치, `GuiInset`은 `Vector2.zero`, `MouseIconEnabled = false` 같은 쓰기는 엔진에 닿지 않고 로컬에만 남는다.
나머지 멤버(`GetFocusedTextBox` 등)는 엔진 서비스로 폴백한다.

**`GuiService`의 게임패드/선택(Selection) 동작은 대체물이 없다 — 플레이 테스트에서만 확인된다.**

## Studio에서 보기 — UI Labs 스토리와 플레이 테스트

레포 루트의 `consumer-kits.project.json`이 ReplicatedStorage에 quad-base·quad-roblox·두 킷을 레포 폴더 모양 그대로 올리고,
킷의 `gallery/*.client.luau` 진입 스크립트 하나만 StarterPlayerScripts에 넣는다(`src`와 `gallery`가 레포와 같은 상대 위치에 있어 상대 require가 Studio에서도 같은 경로로 풀린다; ReplicatedStorage의 `gallery` 사본에서는 `globIgnorePaths`로 진입 스크립트를 뺀다).

1. 터미널에서 `rojo serve consumer-kits.project.json --port 34872`, Studio의 Rojo 플러그인에서 그 포트로 연결.
2. **스토리(편집 모드)** — UI Labs 플러그인을 연다. 탐색기에 storybook **"quad · devui (Iris-style debug UI)"**(`ReplicatedStorage/quad-roblox-devui/stories/Devui.storybook`)이
   보이고, 그 아래 `*.story` 모듈마다 항목이 하나씩 있다. 항목을 열면 오른쪽 Controls 패널이 뜬다 — 패널의 값 하나하나가
   스토리 안에서 `q.Source` 하나이고(`stories/StoryKit.luau`), 컴포넌트는 앱에서 쓰는 그대로 그 Source를 받는다. 값을 바꾸면
   다시 그리지 않고 바인딩만 갱신된다.
3. **플레이 테스트** — Play(F5). StarterPlayerScripts의 `DevuiDemo` LocalScript(`gallery/DevuiDemo.client.luau`)가 PlayerGui에 Demo 창(Iris ShowDemoWindow 대응)을 띄운다. 게임패드·선택(GuiService)·
   Escape·GUI inset처럼 플러그인 위젯에서 재현되지 않는 것은 여기서 본다 — 아래 체크리스트.

UI Labs 안에서는 `UserInputService`가 입력을 받지 못한다. StoryKit이 UI Labs가 주입하는 환경(`InputListener`)을 킷의
`Input.use`로 끼워 넣고 정리 때 되돌린다(위 "UI Labs / 입력 주입"). 제3자 코드(ui-labs-utils)는 들이지 않았다 — 같은 원시
전역(`__hotreload_env_global_injection__`)을 StoryKit이 직접 읽는다. 고급 컨트롤(`StoryKit.Slider`/`Choose`)도 ui-labs-utils가
만드는 데이터 모양을 그대로 만든 평범한 테이블이다(문서화된 API가 아니라 UI Labs 업데이트 때 깨질 수 있는 유일한 자리).

### 실기기 체크리스트 (관측 칸은 비워 둠 — Studio에서 채울 것)

Lune mock은 레이아웃·렌더·엔진 입력 순서를 흉내 내지 못한다. 아래는 스펙으로는 확인할 수 없어 Studio에서 봐야 하는 것들이다.

| # | 볼 것 | 어디서 | 기대 | 관측 |
|---|---|---|---|---|
| 1 | 창 드래그·크기조절·접기·닫기 | Window 스토리 / 플레이 | 타이틀바 드래그로 이동, 우하단 그립으로 크기 조절, 접으면 아이콘(누르면 펼침·끌면 이동) |  |
| 2 | z-순서 — 클릭한 창이 위로, 팝업은 항상 창 위 | 플레이: 데모의 창 셋 | 클릭한 창이 맨 위, Combo/Menu 목록은 창 위 |  |
| 3 | UIFlexItem Fill(SeparatorText·입력 필드 폭) | Layout·Inputs 스토리 | 선이 남은 폭을 채우고 필드가 행을 채움 |  |
| 4 | Iris 아이콘 에셋(화살표·체크·닫기) | Tree·Checkbox·Window | 아이콘이 보임 |  |
| 5 | Table 구분선(Borders) | Table 스토리 | 행·열 선이 끊기지 않음 |  |
| 6 | PlotLines 선분 기하 | Plot 스토리 | 점들이 끊김 없이 이어짐 |  |
| 7 | DragNum·SliderNum 드래그(UI Labs InputListener 경유) | Inputs 스토리 | 드래그로 값이 바뀜(위젯 안 입력 주입 확인) |  |
| 8 | Tooltip 위치(GUI inset 보정) | Tooltip 스토리 / 플레이 | 커서 근처(위아래로 36px 어긋나지 않음) |  |
| 9 | Combo 목록 화면 가장자리 | 플레이: 창을 화면 아래로 | 목록이 화면 밖으로 나감(한계 — 뒤집기·클램프 없음) |  |
| 10 | Escape로 Combo/Menu 닫기 | 플레이 | 열린 목록만 닫힘 |  |
| 11 | 숨긴 창의 hover 잔상 | 플레이: 닫기 버튼 위에서 닫고 다시 열기 | Active 색이 남지 않음 |  |
| 12 | Deferred 시그널 파괴 순서 | 플레이: ScreenGui를 지우고 같은 프레임에 다시 만듦 | 에러 없음, 팝업 고아 없음 |  |
| 13 | 데모 런타임 정보·플롯 Heartbeat | Demo 스토리 / 플레이 | 창을 닫거나 접으면 멈춤 |  |

## 테스트

```bash
quad-roblox-devui/test/run.sh                                    # 전부
quad-roblox-devui/test/run.sh quad-roblox-devui/test/spec.demo.luau   # 하나만
```

(레포 루트에서, 무거운 실행은 `( ulimit -v 4000000; timeout 900 … )`로 감쌀 것.) `run.sh`는 세 단계입니다. (1) 키트 전체를
luau-lsp 신 솔버로 strict 검사, (2) 엔진이 필요 없는 순수 스펙(`spec.pure.*`)을 `luau` CLI로, (3) 컴포넌트 스펙(`spec.*`)을
Lune으로. 종료 코드가 판정입니다.

**왜 Lune인가** — quad 자신의 스펙이 쓰는 `luau` CLI는 모듈마다 읽기 전용 샌드박스 환경을 줘서, 모듈 스코프에서 엔진 전역
(`Color3.new(...)` 같은 테마 상수)을 쓰는 UI 키트를 돌릴 수 없습니다. Lune은 전역 테이블을 공유하고 진짜 Roblox 데이터
타입(`Color3`, `UDim2`, `Enum` …)을 제공해 키트 코드를 그대로 돌립니다. 다만 Lune 0.10.5는 `const`와 `f<<T>>(x)`를 파싱하지
못해서, `run.sh`가 줄 번호를 보존하는 재작성 사본(`test/support/mirror.py`)에서 스펙을 돌립니다 — 원본에 Lune을 직접 쓰지 마세요.

**하네스** — `test/support/harness.luau`가 quad mock 인스턴스(`Instance.new`), 가짜 서비스(`UserInputService`/`RunService`/
`TextService`/`Players` …), 가상 시계 `task`(`H.advance(dt)`가 타이머와 Heartbeat를 돌림)와 `print` 캡처를 설치합니다.
스펙은 `H.fire`로 이벤트를, `H.input`으로 입력을 흉내 내고, `H.assertNoDebugOutput`으로 `q.debug = true`에서 진단 출력이 0인지
확인하며, 끝에 `q.dispose(root)` 뒤 연결 개수가 기준선으로 돌아오는지 봅니다. mock에는 레이아웃 엔진이 없으므로
`AbsolutePosition`/`AbsoluteSize`는 `H.setAbs`로 직접 넣습니다.

## 알려진 한계

- **[미검증] 실기기 확인은 아직 안 했습니다.** 모든 스펙은 mock 위에서만 돌았습니다. 레이아웃(AutomaticSize·UIFlexItem 조합),
  아이콘 에셋, 폰트, 터치 입력은 Studio/실기기 확인이 필요합니다.
- **화면 가장자리 보정 없음.** `Overlay`는 팝업을 요청한 위치에 그대로 둡니다(내용의 크기는 레이아웃 뒤에야 알 수 있음).
  화면 밖으로 나갈 위치면 호출하는 쪽이 `Anchor`로 방향을 정해야 합니다.
- **Menu**: Dear ImGui의 "열린 메뉴 위에서 다른 최상위 메뉴로 호버 전환"은 없습니다(열린 동안 바깥 클릭 포획 층이 막대를
  덮음). 메뉴 항목은 열 때마다 만들어지고 닫으면 파괴됩니다.
- **Tooltip**은 보일 때의 마우스 위치에 뜨고 따라다니지 않습니다. 리프 위젯에는 `Hooks = { tip.Hook }`로, 그 밖의 요소에는 배열 부분에
  `tip.Hook`을 놓습니다. 위치는 `GetMouseLocation() - GuiService:GetGuiInset()`(`GetMouseLocation`은 상단바 인셋을 반영하지 않고 `AbsolutePosition`은 반영한 공간)을
  `Overlay`에 넘기고 `Overlay`가 층의 `AbsolutePosition`을 빼는 방식입니다 — **기기 미검증**이라 세로로 어긋나면 이 읽기가 틀린 것입니다.
  `Enabled = boolean | State<boolean>`(기본 `true`)가 `false`면 뜨지 않습니다 — 마우스가 들어올 때와 지연 뒤 뜨려 할 때 읽고, 떠 있는 동안
  `false`가 되어도 닫지 않습니다(마우스가 나가면 닫힘).
- **Tree / Tab**: 닫힌 트리의 자식은 `Visible = false`로 **계속 마운트**됩니다(위젯 상태가 보존되는 대신 인스턴스는 유지).
  노드가 수천 개면 직접 지연 생성하세요. 탭 목록은 생성 시점에 고정이고 닫기/숨기기 탭은 없습니다.
- **Table**: `Cell`은 (행 키, 열)당 한 번만 불리고 값이 바뀌면 `row` State가 다시 발행됩니다 — 행은 제자리 수정이 아니라
  새 테이블로 교체하세요. 열 너비는 픽셀 또는 균등 분할만 지원합니다.
- **PlotLines**는 위젯의 픽셀 크기를 알아야 해서 레이아웃이 한 번 돈 뒤에야 선이 보입니다. 마지막 200점만 그립니다.
- **Style**: 토큰 단위 실시간 setter 없음(위 참고). **Window**는 닫아도 인스턴스(표면 루트와 장식)가 남고 `Visible = false`가 됩니다.
- **Combo·Menu·Tooltip은 화면 가장자리에서 뒤집히거나 밀려 들어오지 않습니다** — 화면 아래쪽의 콤보 목록, 오른쪽 끝의 메뉴, 커서 옆 툴팁은
  화면 밖으로 나갈 수 있습니다.
- **Combo**: 옵션 값은 서로 달라야 합니다(리스트 키). 중복이 필요하면 `ComboArray`. **가상화가 없습니다** — 열 때마다 옵션 수만큼 행을
  만들므로(`MaxHeight`로 높이만 자르는 스크롤 목록) 수십~수백 개까지가 현실적입니다. 수천 개면 `Options` State를 검색어로 거르거나 직접
  쪼개세요. `Disabled`면 열리지 않고(열려 있는 동안 비활성이 되어도 목록은 남습니다), 사용자가 고른 경우에만 `OnChange`가 불립니다.
  열린 목록(그리고 Menu의 열린 메뉴)은 콤보가 든 창을 닫으면(조상이 숨으면) 같이 닫힙니다.
- **Hover/Pressed 초기화**는 요소 **자신의** `Visible`이 꺼질 때와 `AncestryChanged`(부모 변경·제거)에서 합니다. 조상이 `Visible = false`가
  되면 요소에는 아무 신호도 오지 않으므로, 그런 소유자가 직접 `hover.Reset()`을 불러야 합니다 — `Window`는 `Open`이 꺼질 때 제목줄 버튼에 그렇게 합니다.
  그 밖의 위젯이 든 창을 닫을 때의 호버 잔상은 처리하지 않습니다 — 마우스를 조금이라도 움직이면 엔진이 호버를 다시 계산해 `MouseLeave`를
  주므로 남지 않습니다(Studio 확인 2026-10-15; 다시 열 때도 마우스가 움직여야 `MouseEnter`가 옵니다). Tooltip은 대기 타이머가 끝날 때 대상이 아직
  보이는지(자신·조상의 `Visible`, ScreenGui의 `Enabled`) 보고, 숨었으면 띄우지 않습니다.
- **가려진 요소는 hover되지 않습니다.** 엔진은 다른 창·열린 팝업의 바깥 클릭 막이·버튼에 가린 요소에도 `MouseEnter`를 줍니다(Studio 확인
  2026-10-20 — 위에 TextButton이나 `Active` 프레임이 있어도 막히지 않고, 막히는 것은 클릭뿐). 그래서 위젯의 hover 모양과 Tooltip은 그 요소가
  포인터 아래 **맨 위**일 때만 켜집니다 — 위 창 올리기와 같은 규칙(클릭이 갈 곳)입니다. 마우스가 그대로인데 위가 바뀌면(팝업이 열리고 닫힘, 창을
  올리거나 숨김) 다음 렌더 뒤에 다시 판정합니다. 가린 것이 사라져도 이미 그 위에 있던 마우스에 Tooltip이 새로 뜨지는 않습니다(다시 들어오면 뜸).
  PlayerGui가 없는 스토리 호스트에서는 예전처럼 `MouseEnter`만 봅니다.
- `Demo`는 인스턴스를 많이 씁니다(전체 약 860개, 닫힌 도구 창 포함) — 데모일 뿐 위젯 하나의 비용이 아닙니다.

### 게임 안에서 만나는 엔진 함정

키트가 고칠 수 없는 엔진 동작이지만, 각각 디버깅 한 라운드를 쓰게 만듭니다(2026-10-19~20 devplorer가 Studio Play에서 관측).

- **Escape로 팝업을 닫으면 Roblox 메뉴도 열립니다**(`GuiService.MenuIsOpen`). 열린 동안 클릭이 먹통이 되고, 게임 스크립트로는 막을 수 없습니다 — 게임 안 대화 상자는 바깥 클릭과 단추로 닫게 하세요.
- **Shift+P는 Roblox 내장 개발자 Freecam입니다** — 그것을 포함한 단축키(예: Ctrl+Shift+P)는 모든 ScreenGui를 숨깁니다.
- **사용자가 다른 TextBox에 포커스를 둔 상태에서 포커스 없는 TextBox의 `CursorPosition`을 쓰면 포커스가 그 상자로 넘어갑니다.** 커서는 그 상자에 포커스가 있을 때만 옮기세요. 코드로 `CaptureFocus`한 상자끼리 흉내 내면 재현되지 않으니 실제 입력으로 확인하세요.
- **RichText 라벨에 남이 정한 이름을 넣을 땐 이스케이프하세요** — 이름 안의 태그가 화면을 꾸며 다른 글처럼 보이게 할 수 있습니다.

## 라이선스와 출처

MIT (`LICENSE`). 이 키트는 Iris(MIT, © 2024 Michael_48)에서 **영감을 받았고** 위젯 세트와 기본 색·크기 숫자를 따랐지만 Iris
소스 코드는 가져오지 않았습니다. 자세한 고지는 `NOTICE.md`를 보세요.
