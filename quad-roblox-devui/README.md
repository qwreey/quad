# quad-roblox-devui

> 패키지 이름은 **가칭**입니다(작업명 `quad-roblox-devui`). 도그푸딩을 거친 뒤 정식 이름을 정합니다. 소스 코드 안에는
> 이 이름이 없고(require는 전부 폴더 상대 경로) 이 문서, 폴더 이름, 테스트 파일의 주석에만 나옵니다. 이 키트에는 매니페스트가 아직 없습니다.

[quad](../README.md) 위에서 만든 **개발자·디버그용 UI 키트**입니다. [Iris](https://github.com/SirMallard/Iris)
(Dear ImGui 계열)와 같은 **위젯 세트**와 같은 **겉모양**(작은 글씨, 납작한 프레임, 파란 강조색)을 가지지만,
API 모양은 Iris를 따르지 않고 quad의 방식 — **retained(유지형)이고 반응형** — 으로 짰습니다.

```luau
local Devui = require("<이 폴더>/src")
local q = require("<이 폴더>/src/Quad")
local D = q.Declaration
local Kids = Devui.Kids

local count = q.Source(0)
local label: q.State<string> = count:Compute(function(self)
	return `Clicked {self:Get()} times`
end)

local overlay = Devui.Overlay.new() -- ScreenGui마다 하나: 팝업(Combo / Menu / Tooltip)이 그려지는 층
local screen = D.ScreenGui {
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

**`ScreenGui`는 `ZIndexBehavior = Sibling`이어야 합니다.** 코드로 만든 `ScreenGui`(`D.ScreenGui`·`Instance.new`)의 기본값은
`Global`이고, 이 키트는 창의 겹침 순서(창 루트의 `ZIndex` = 서열 1..n)와 팝업 층(`ZIndex` 1000)을 형제 사이의 `ZIndex`로
정합니다. `Global`에서는 `ZIndex`가 `ScreenGui` 전체에서 비교되어, 서열 2 이상인 창의 배경이 자기 내용(`ZIndex` 1)과 팝업
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
- **코드와 사용자가 같이 쓰는 입력 상자**: `Text = src` + `q.Out("Text", src)` — 메아리를 손으로 거르지 마세요. `Devui.InputText`가 이 모양입니다.
  [roblox/05](../docs/reference/roblox/05-onchange.md), [시작하기 06](../docs/getting-started/06-flowing-back.md).
- **검색창 디바운스·갱신 합치기**: [`q.Debounce`/`q.Throttle`](../docs/reference/sugar/03-debounce-throttle.md). 여러 원천을 한 번에 갱신하려면 Effect 하나로 모은 뒤 붙입니다.
- **바깥 신호(`UserInputService` 등)의 수명**: [`q.OnDestroyed`](../docs/reference/sugar/04-lifecycle-hooks.md)나 Effect cleanup에 묶습니다 — `Destroying:Connect`나 표지용 Folder가 필요 없습니다.
  [how-to/04](../docs/how-to/04-network-and-input-bridge.md).
- **quad가 만든 인스턴스의 변화**: 선언 밖에서 `:Connect`하지 말고 같은 선언 안의 `q.OnChange`·이벤트 prop으로(파괴와 함께 풀림). 읽기 전용 프로퍼티(`AbsoluteSize`·`CanvasPosition`)도 됩니다.
- **긴 목록**: Table·Combo·Tree는 가상화가 없습니다. 화면에 보이는 행만 만드는 레시피는 [how-to/03](../docs/how-to/03-long-lists-and-windowing.md).
  배치 전(크기 0)에는 행이 0개인 것이 정상입니다.
- **파생 값의 타입**: `:Compute` 결과는 만드는 줄에서 주석합니다(`local shown: q.State<boolean> = n:Compute(...)`) — 인라인으로 prop에 넣으면 오류 문구가 길어집니다.
  `Source`와 `State`를 한 변수에 받을 땐 주석 붙인 if-식(`local h: q.State<number> = if s then s else q.Source(1)`)이나 값을 돌려주는 함수로 — 분기마다 대입하면 유니언이 되어 `:Compute`를 못 부릅니다.
- **Slot**: 요소의 배열부에 빈 Slot을 놓을 땐 `q.Slot<<Instance>>()`. `Kids(...)`(= Slot)의 원소는 `nil`·`q.None`이 될 수 없습니다(요소의 배열부와 다름).
  `{ table.unpack(list) }`로 자식을 펴는 대신 `q.Slot<<Instance>>(list)`를 배열부 아무 자리에나 놓습니다.
- **이벤트 prop에 미리 만든 함수**: `local f: () -> () = ...`처럼 주석한 무인자 함수는 `Activated` 같은 자리에 안 들어갑니다(Luau 새 솔버 규칙) —
  `local function f() end`나 인라인 함수를 넘기세요.
- **배치 속성**: `LayoutOrder`·`Position` 같은 루트 꾸밈은 Modifier로(`D.Modifier.Frame():LayoutOrder(2)`). Button은 `Size`를 받으면 자동 크기가 꺼집니다.

## Iris와 무엇이 다른가

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
| 창 | `Window`, `WindowManager` | 드래그·크기 조절·접기·닫기 되는 창, 클릭하면 맨 앞으로(`ZIndex` 관리) |
| 레이아웃 | `SameLine`, `Group`, `Indent`, `Separator`, `SeparatorText` | 가로 줄 / 세로 묶음 / 들여쓰기 / 구분선 |
| 글 | `Text`, `TextWrapped`, `TextColored`, `TextDisabled`, `LabelText` | 한 줄·줄바꿈·색·흐림·`값 라벨` 한 줄 |
| 버튼 | `Button`, `SmallButton` | 클릭 가능한 버튼(작은 쪽은 세로 패딩 없음) |
| 선택 | `Checkbox`, `RadioButton`, `Selectable`, `SelectableOption` | 체크 / 라디오(같은 `Source` 공유) / 한 줄 선택 행 |
| 입력 | `InputText`, `InputNum`, `DragNum`, `SliderNum`, `InputVector2`, `InputUDim2`, `InputColor3` | 글·숫자(±버튼)·드래그 숫자·슬라이더·벡터·UDim2·색 |
| 구조 | `Tree`, `CollapsingHeader`, `TabBar` / `Tab`, `Table` | 접히는 노드·헤더, 탭, 키로 재활용되는 표 |
| 표시 | `ProgressBar`, `PlotLines`, `PlotHistogram` | 진행 막대, 선 그래프, 막대 그래프 |
| 팝업 | `Combo`, `ComboArray`, `ComboEnum`, `MenuBar` / `Menu` / `MenuItem` / `MenuToggle`, `Tooltip` | 드롭다운, 메뉴(중첩 가능), 호버 툴팁 |
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

### 이름 규약 (키트 전체)

- **입력·콤보·체크 계열의 뒤따르는 라벨은 `Text`**입니다(`InputNum { Text = "speed", Value = … }`, Iris 관례) — `LabelText`만 값이 `Text`,
  라벨이 `Label`입니다(Dear ImGui의 `LabelText` 순서).
- `Value` = 위젯이 읽고 쓰는 `Source`, `Option` = 선택 위젯이 고르는 값(`RadioButton`/`SelectableOption`: `Value: Source<T>` + `Option: T`),
  `Disabled` = 회색 처리(`boolean | State<boolean>`), `Modifier` = 그 위젯 루트 요소의 Modifier(`LabelText`는 가로 줄 Frame).
- **호스트 `Name`은 소비자가 `Modifier`로 바꿀 수 있습니다** — `Devui.Button { Modifier = D.Modifier.TextButton():Name("Save") }`. 킷은 기본 이름(`Button` 등)을 기본 Modifier에 두므로 소비자의 `:Name(...)`이 이깁니다(`InputText`의 `FieldModifier` 필드·`SliderNum`의 `TrackModifier` 트랙도 같음). 안쪽 자식 이름(`Track`·`Arrow` 등)은 고정입니다.
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
다시 만들어 보여주는 이유).

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
아니라 팝업이 없는 곳의 클릭은 그대로 통과합니다. `Window`의 `ZIndex`는 `WindowManager`가 **순위(1..n)**로 관리하므로 포커스를 몇 번 옮겨도
층(ZIndex 1000)을 넘지 않습니다(살아 있는 창 999개까지).

창 안의 **어떤 위젯을 눌러도**(버튼·체크박스·입력 칸 포함) 그 창이 앞으로 옵니다 — 누름은 포인터 아래 첫 버튼·입력 칸에서 멈춰 창 프레임에
오지 않으므로, `WindowManager`가 전역 누름(`UserInputService.InputBegan`, 마우스 왼쪽·터치) 하나를 듣고 그 누름이 간 창을 앞으로 올립니다(창이
하나라도 있는 동안만 연결). 판정은 엔진이 누름을 주는 곳과 같습니다: `PlayerGui:GetGuiObjectsAtPosition`의 목록을 위에서부터 보아, 창 밖에서
누름을 받는 것(버튼·입력 칸·`Active`인 요소 — 열린 팝업의 행이나 바깥 클릭 막이, 다른 ScreenGui의 HUD 버튼)이 먼저 나오면 포커스를 바꾸지 않고,
입력을 받지 않는 것(툴팁, 투명한 틀)은 지나쳐 그 아래 창을 올립니다. 숨은 창이나 트리에서 뗀 창은 맞지 않습니다. PlayerGui가 없는 곳(UI Labs
같은 스토리 호스트의 플러그인 위젯)에서는 창 사각형으로 판정하고, 입력을 받는 열린 팝업 위의 누름만 거릅니다. 직접 만든 창 모양에
`manager:Register()`를 쓰면 `slot.Hook`을 그 루트의 배열부에 넣어야 이 동작이 붙습니다. 포커스된 창을 닫거나 파괴하면 남은 열린 창 가운데 맨 위
창이 포커스를 받고, 닫았던 창을 다시 열면 맨 앞으로 오며 포커스를 받습니다. 밖에서 창을 다루는 길은 주인이 쥔 Source입니다 — 넘긴 `Open`에 `:Set(true)`를 하면 이미 열린 창도 맨 앞으로 올라오고(quad의 `Set`은 같은 값도 전파합니다; 상태만 맞추고 올리지 않으려면 `:SetIfChanged(true)`), `Focused = Source<boolean>`을 넘기면 창이 포커스 여부를 거기 씁니다(핸들 객체는 없습니다)(Dear ImGui와 같음 — 처음부터 열린 창은 포커스를 빼앗지 않음). 창의 빈 곳을 누른
것은 창 전체를 덮는 투명 버튼 `ClickSink`(ZIndex 0)에서 멈춰 아래 창의 위젯으로 새지 않습니다. 타이틀바로 끌 때 창은 컨테이너 안에 타이틀바가 남도록 잘리고(Dear ImGui와 같은 규칙 — 가로로 `FrameHeight`(기본 19)
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
| 1 | 창 드래그·크기조절·접기·닫기 | Window 스토리 / 플레이 | 타이틀바 드래그로 이동, 우하단 그립으로 크기 조절 |  |
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
- **Tree / Tab**: 닫힌 트리의 자식은 `Visible = false`로 **계속 마운트**됩니다(위젯 상태가 보존되는 대신 인스턴스는 유지).
  노드가 수천 개면 직접 지연 생성하세요. 탭 목록은 생성 시점에 고정이고 닫기/숨기기 탭은 없습니다.
- **Table**: `Cell`은 (행 키, 열)당 한 번만 불리고 값이 바뀌면 `row` State가 다시 발행됩니다 — 행은 제자리 수정이 아니라
  새 테이블로 교체하세요. 열 너비는 픽셀 또는 균등 분할만 지원합니다.
- **PlotLines**는 위젯의 픽셀 크기를 알아야 해서 레이아웃이 한 번 돈 뒤에야 선이 보입니다. 마지막 200점만 그립니다.
- **Style**: 토큰 단위 실시간 setter 없음(위 참고). **Window**는 닫아도 인스턴스가 남고 `Visible = false`가 됩니다.
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
