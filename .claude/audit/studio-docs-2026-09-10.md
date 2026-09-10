# 문서 구간 Studio 실측 — OnChange 초기 발화·문자열 require·Tag/Attr·QueryDescendants (2026-09-10 밤)

**무엇을**: 문서 다듬기 구간에서 실기기 확인이 남아 있던 것들 — `HUMAN_TODO` 13(기본값과 같은 props의
`OnChange` 초기 발화), `HUMAN_TODO` 16 / `question.md` 3절 D9(문자열 `require("@game/…")`의 복제 전 동작),
그리고 새 튜토리얼 페이지에 쓸 Tag/Attr·`Instance:QueryDescendants` 사실 확인. Studio 0.738.0.7381393,
rojo serve + 플러그인 Connect(사용자), MCP `execute_luau`(Edit) + `start_stop_play`(B만).

**절차 메모 — require 캐시**: `audit/sugar-studio-2026-09-08.md`의 관용구 그대로. rojo가 새 파일을 트리에
넣어도 이미 `require`된 모듈은 옛 본문을 돌려주므로, `ReplicatedStorage`의 `quad-base`·`quad-roblox` 폴더를
`:Clone()`해 임시 폴더(`ReplicatedStorage.QuadTmp20260910`)에 두고 그 사본을 `require`했다. 패키지 링크가
`./.pesde/…` 상대 경로라 폴더째 복제하면 require 그래프가 그대로 산다. **복제 전에 `#src:GetChildren()`이
디스크와 맞는지 확인할 것** — rojo가 스트리밍 중이면 부분 트리가 들어와 require 에러를 quad 결함으로
오독하게 된다(이번엔 27개 = 디스크 28개 − `init.luau` 확인 뒤 진행).

---

## A. `HUMAN_TODO` 13 — 기본값과 같은 값을 쓸 때 `OnChange` 초기 발화

### A-0. 엔진 층 프로브 (quad 없이)

```lua
local f = Instance.new("Frame")
local n = 0
f:GetPropertyChangedSignal("Visible"):Connect(function() n += 1 end)
f.Visible = true   -- 기본값과 같은 값
task.wait()        -- Deferred 신호라 프레임을 넘겨야 센다
local afterSame = n
f.Visible = false
task.wait()
```

| 프로브 | 결과 |
|---|---|
| `Frame`의 기본 `Visible` | `true` |
| 신호 전달 모드(경험적) — 대입 직후 핸들러가 돌았는가 | `false` → **Deferred**(`task.wait()` 뒤 `true`) |
| `Visible = true`(현재값과 같음) | **0회** |
| 이어서 `Visible = false` | 1회 |
| 다시 `Visible = false`(또 같은 값) | 여전히 1회(추가 0) |
| `Changed` 이벤트로도 같은 실험 | 같은 값 0회 / 실제 변경 1회 |
| `TextLabel.Text` 기본값 | `"Label"` |
| `Text = "Label"`(기본값과 같음) / `Text = "a"`(다름) | 0회 / 1회 |

`workspace.SignalBehavior`은 이 버전에서 스크립트로 못 읽는다(`SignalBehavior is not a valid member of
Workspace "Workspace"`; `ReflectionService`엔 `SignalBehavior`·`SignalBehavior2`가 있으나 `Permits.Read`가
`nil`). 그래서 위처럼 경험적으로 판정했다.

### A-1. quad 층 (clone-require, `q.OnChange`)

```lua
local n1 = 0
local f1 = D.Frame({ Visible = true, q.OnChange("Visible", function(v) n1 += 1 end) })
task.wait()                     -- n1 을 읽는다
f1.Visible = false; task.wait() -- 다시 읽는다
```

| 케이스 | 생성 시 발화 | 그 뒤 |
|---|---|---|
| A1 `Visible = true`(기본값과 **같음**) | **0회** | 엔진 쓰기 `Visible = false` 뒤 누적 1회 |
| A2 `Visible = false`(기본값과 **다름**) | 1회 | — |
| A3 `Visible = q.Source(true)` → `:Set(false)` | **0회** | `:Set(false)` 뒤 누적 1회 |
| A4 `TextLabel { Text = "a" }`(기본 `"Label"`) — 레퍼런스 문서의 예제 | 1회 | — |
| A5 `TextLabel { Text = "Label" }`(기본값과 같음) | **0회** | — |

### 판정

**엔진 0회 / mock(CLI) 1회로 갈린다** — `HUMAN_TODO` 13이 예상한 대로다.

정본 `base/onchange-plan.md`가 걸어 둔 헤지 원문(`H-429`, 그대로 인용):

> **[2026-09-07 7순회 `H-429` 셋째 헤지]** props의 값이 엔진 기본값과 같으면(`Frame { Visible = true }`)
> 엔진이 동일값 대입에 시그널을 안 쏘므로 발화 없음이 정상(mock은 무조건 쏘므로 CLI와 갈린다 —
> `HUMAN_TODO.md` 13번 실측으로 확정할 것).

**이 문장은 글자 그대로 참이다** — 예시로 든 `Frame { Visible = true }`까지 포함해 A1이 그대로 재현했고,
mock이 갈린다는 뒷절도 아래대로 맞다. 즉 이 헤지는 **삭제가 아니라 확정** 대상이다(문서 수정은 이
작업 범위 밖 — 사실만 남긴다).

- 원인은 quad 쪽이 아니라 엔진의 프로퍼티 쓰기다. 같은 값을 대입하면 `GetPropertyChangedSignal`도
  `Changed`도 아예 안 쏜다(A-0). quad는 배열부에서 먼저 `Connect`하고 해시부에서 쓸 뿐이라 그 쓰기가
  신호를 안 내면 콜백도 안 닿는다.
- **mock 쪽 수치는 1회**다. 근거 둘을 다 확인했다 — (1) `quad-roblox/src/Handlers/Property.luau`의
  `process`에 **같은 값 스킵 가드가 없다**: 평문 값은 `inst[k] = if tweenIn then v.Value else v`로
  무조건 쓰고, 존재하는 유일한 dedup은 Tween 자리의 `prev.Value == v.Value`(Q25 `H-391`)뿐이라
  평문 경로엔 안 걸린다(`Q33 (a)`의 "NO nil skip" 주석도 같은 자리). 그러니 mock에서도 쓰기는 실제로
  일어난다. (2) `quad-base/test/mock.luau`의 `fireChanged`가 값 비교 없이
  `data.properties[key] = value` 뒤 무조건 `sig:Fire()`를 부르고(동기 Immediate), 같은 값 dedup이 없다.
  → 쓰기가 일어나고 mock이 무조건 쏘므로 mock 카운트는 1.
  `quad-roblox/test/spec.events.luau` §4가 단언하는 초기 발화 케이스는 `TextLabel { Text = "a" }`,
  즉 **기본값과 다른 값**이라 이 갈림을 밟지 않는다 — 기본값과 같은 값을 쓰는 스펙 단언은 없다.
  (mock 1회는 이 두 코드 독해로 판정한 것이고 CLI를 새로 돌려 세지는 않았다 — 아래 "아직 안 본 것".)
- 그래서 `docs/reference/roblox/05-onchange.md`의 "**초기값도 콜백에 닿습니다**"는 **쓰는 값이
  현재값(대개 기본값)과 다를 때만** 참이다. 문서 예제(`Text = "a"`)는 그 조건을 만족해서 맞다.
  (문서 수정은 이 작업 범위 밖 — 사실만 남긴다.)

---

## C. 새 튜토리얼 페이지용 Tag / Attr / QueryDescendants 사실

셋업은 clone-require + `Quad:UseProvider(QuadRoblox)`, `StarterGui` 아래 `ScreenGui`를 Edit 모드로 마운트.

### C-1. `q.Tag("Card")` → `CollectionService`

```lua
local card = D.Frame({ Name = "Card", Size = UDim2.fromOffset(240, 160), q.Tag("Card"), … })
```

| 프로브 | 결과 |
|---|---|
| `CollectionService:GetTags(card)` | `{Card, Even}` (아래 C-2의 State 태그가 같이 붙어 있음) |
| `CollectionService:GetTagged("Card")`가 그 인스턴스를 담는가 | **`true`** (n=1) |

배열부의 `q.Tag`는 실물 `CollectionService` 태그로 그대로 나간다.

### C-2. `State<Tag>` — `:Compute`가 돌려주는 태그를 배열부에 놓기

레퍼런스 `docs/reference/core/09-tag-attr.md`의 `TagNames`가 `TagMarker`를 포함하고,
`quad-base/test/spec.tag.luau` §3이 `q.Source(q.Tag(…))`를 배열부에 놓는다. 실기기에서
`:Compute` 형태도 그대로 선다 — **캐스트 없이** 배열부에 놓였다.

```lua
local count = q.Source(0)
local parityTag = count:Compute(function(c)
	return q.Tag(if c:Get() % 2 == 0 then "Even" else "Odd")
end)
local card = D.Frame({ q.Tag("Card"), parityTag, … })
```

| 시점 | `HasTag(card,"Even")` / `HasTag(card,"Odd")` | 전체 태그 |
|---|---|---|
| 생성 직후(`count = 0`) | `true` / `false` | `{Card, Even}` |
| `count:Set(1)` | `false` / `true` | `{Card, Odd}` |
| `count:Set(2)` | `true` / `false` | `{Card, Even}` |

정적 `q.Tag("Card")`는 교체 내내 살아남는다(자리별 참조 계수 그대로). **타입 층은 여기서 안 봤다** —
런타임만 확인했고, `--!strict`에서 `:Compute`의 반환이 배열부 팔에 맞는지는 미실측.

### C-3. `q.Attr` / `q.BooleanAttr` → `GetAttributes`

```lua
local kind, active = q.Source("counter"), q.Source(true)
D.Frame({ q.Attr({ Kind = kind, Step = 1 }), q.BooleanAttr("Active", active), … })
```

| 시점 | `inst:GetAttributes()` |
|---|---|
| 생성 직후 | `{Active=true(boolean), Kind=counter(string), Step=1(number)}` |
| `kind:Set("card")`, `active:Set(false)` | `{Active=false(boolean), Kind=card(string), Step=1(number)}` |
| `active:Set(q.None)` | `{Kind=card(string), Step=1(number)}` — **속성이 삭제됨** |

문서의 "`None`만이 지운다" 규칙과 값 타입 보존(문자열/숫자/불리언 그대로)이 실물에서 성립한다.

### C-4. `Instance:QueryDescendants` — 셀렉터 문법(실측)

공식 문서 페이지(`create.roblox.com/.../Instance#QueryDescendants`)는 **시그니처만 있고 문법도 예제도
없다**(`QueryDescendants(selector: string): Instances`). 그래서 전수 프로브로 문법을 알아냈다.
0.738에 메소드는 존재하고(`typeof == "function"`), `QueryChildren`/`QuerySelector`/`MatchesQuery` 같은
형제 메소드는 **없다**.

트리: `ScreenGui` > `Card`(Frame, 태그 `Card`·`Even`, `Kind="counter"`·`Step=1`·`Active=true`) >
`Inner`(TextLabel, `Kind="counter"`), 그리고 형제 `Other`(Frame, `Kind="other"`).

**되는 것**

| 셀렉터 | 결과 | 뜻 |
|---|---|---|
| `Frame` / `TextLabel` / `GuiObject` / `Instance` / `GuiBase2d` | `Card,Other` / `Inner` / 셋 / 셋 / 셋 | 클래스 필터는 **`IsA` 기준**(상위 클래스도 매치) |
| `.Card` / `.Even` / `.Odd` / `.Nope` | `Card` / `Card` / 0 / 0 | `.`은 **태그** |
| `#Card` / `#Other` / `#Inner` | 각 1개 | `#`은 **Name** |
| `[$Kind=counter]` | `Card,Inner` | `[$…]`은 **어트리뷰트** |
| `[$Kind = counter]` (공백) / `[$Kind="counter"]` | 같음 | 공백 허용, 큰따옴표 허용 |
| `[$Kind]` / `[$Missing]` | 셋 / 0 | 값 없이 쓰면 **존재 검사**(어트리뷰트 한정) |
| `[$Step=1]` / `[$Active=true]` / `[$Active=false]` | `Card` / `Card` / 0 | 숫자·불리언 리터럴 OK |
| `[$Label="two words"]` | `Card` | 공백 든 값은 큰따옴표로 |
| `[Name=Card]` / `[Name="Card"]` / `[Visible=true]` / `[ClassName=Frame]` | `Card` / `Card` / 셋 / `Card,Other` | `$` 없는 `[…]`은 **프로퍼티** |
| `[Kind=counter]` | **0** | 어트리뷰트를 `$` 없이 쓰면 조용히 0(프로퍼티로 찾으므로) |
| `.Card.Even` / `.Card TextLabel` / `GuiObject TextLabel` / `Frame Frame` | `Card` / 0 / `Inner` / `Card,Other` | **공백·나열은 AND**(같은 노드에 걸리는 필터의 논리곱) — CSS의 자손 결합자가 **아니다** |
| `.Card[$Kind=counter]` / `[$Kind=counter][$Step=1]` / `Frame[$Kind=counter]` | 각 `Card` | 같은 AND |
| `A > B` — `.Card > TextLabel` / `GuiObject > TextLabel` / `#Card > #Inner` / `Frame > Frame` | `Inner` / `Inner` / `Inner` / 0 | `>`는 **직계 자식** |
| `A >> B` — `Frame >> TextLabel` / `.Card >> TextLabel` | `Inner` / `Inner` | `>>`가 **자손** 결합자 |
| `Frame, TextLabel` | 셋 | `,`는 **합집합** |
| `""`(빈 문자열) | 0개, 에러 없음 | |

**에러 나는 것**(문구 그대로)

| 셀렉터 | 에러 |
|---|---|
| `*` , `$Kind` | `Expected at least one filter` |
| `[$Kind='counter']`(작은따옴표) | `Expected identifier for a property value` |
| `[$Kind!=counter]` | `Expected ']' to complete a property filter` |
| `[$Step=1.0]` | `Expected ']' to complete a property filter` — 소수점 리터럴 불가(`1`은 됨) |
| `[Visible]`(값 없는 **프로퍼티** 검사) | `'=' expected after property name` — 존재 검사는 어트리뷰트에만 |

**튜토리얼에 쓸 때 주의 둘**: (1) 공백이 자손이 아니라 AND라서 CSS 습관대로 `.Card TextLabel`이라고
쓰면 조용히 0개가 온다 — 자손은 `>>`. (2) 어트리뷰트에 `$`를 빠뜨려도 에러가 아니라 조용한 0개다.

### C-5. 튜토리얼 카드 렌더 확인 (`screen_capture`)

`docs/getting-started/04-reacting.md`의 "지금까지의 코드" + 1절 버튼 + 2절 `:Observer`를 그대로 붙여
Edit 모드 `StarterGui`에 마운트했다(배치 프로퍼티는 02장 그대로 — `AnchorPoint 0.5,0.5` /
`Position fromScale(0.5,0.5)`).

| 프로브 | 결과 |
|---|---|
| 라벨 초기 `Text` | `"카운트: 0"` — `:Compute`가 생성 시점에 이미 반영 |
| `:Observer` 발화 | 등록 즉시 1회, `count:Set` 마다 +1 (0→1→2에서 누적 3) |
| `card.AbsoluteSize` / `AbsolutePosition` | `240, 160` / `254, 90`(뷰포트 중앙) |
| `card`의 `UICorner.CornerRadius` | `0, 12` — 숏핸드 `UICorner = 12`가 자식 인스턴스로 |
| 버튼 `AbsoluteSize` / `AbsolutePosition` / 색 / 코너 | `200, 42` / `274, 188` / `0, 0.635, 1` / `0, 8` |
| `count:Set` 뒤 라벨 | `"카운트: 1"` → `"카운트: 2"` |

스크린샷으로 본 것: **뷰포트 한가운데에 모서리가 둥근 어두운 카드**(문서의 `RGB(35,35,42)`)가 있고,
그 위쪽에 흰색 큰 글씨로 `카운트: 2`(`TextScaled`라 라벨 높이 48을 꽉 채움), 아래쪽에 모서리 둥근
**파란 `+ 1` 버튼**(`RGB(0,162,255)`)이 좌우 20씩 여백을 두고 놓여 있다 — 큰 틀은 문서 서술 그대로다.

**다만 라벨이 16px 왼쪽으로 치우쳐 있다 — 문서 예제의 실제 결함.** 라벨은
`Size = UDim2.new(1, -32, 0, 48)`인데 `Position`이 없어 `x = 0..208`을 차지한다(왼쪽 여백 0, 오른쪽 32).
`TextScaled`가 그 폭 안에서 가운데 정렬하므로 글자 중심이 카드 기준 104px — 카드 중심 120px보다
**16px 왼쪽**이다. 스크린샷에서도 글자 중심이 카드 중심보다 왼쪽에 있다(글자 중심 ≈360 대 카드 중심 ≈375).
`-32`는 좌우 16px씩 여백을 의도한 값이므로 `Position = UDim2.fromOffset(16, 0)`(또는 `AnchorPoint`)이
같이 있어야 의도대로 선다. 버튼 쪽은 `Position = UDim2.new(0, 20, 1, -62)`가 있어서 정확히 중앙이다
(폭 200 = 240−40, 좌우 20씩). 즉 **버튼에는 있는 짝 프로퍼티가 라벨에만 빠진 것**으로 보인다.
문서 수정은 이 작업 범위 밖 — 사실만 남긴다(`docs/getting-started/04-reacting.md`의 "지금까지의 코드",
같은 라벨이 02·03장에서 이어져 온다).

---

## B. `HUMAN_TODO` 16 / `question.md` D9 — 문자열 `require("@game/…")`의 복제 전 동작

`StarterPlayer.StarterPlayerScripts`에 `LocalScript` 하나(`QuadStrReqProbe`)를 Edit 모드로 만들고
Play(클라이언트)를 **두 번** 돌렸다. 스크립트 **첫 줄**에서 재고 requiring 한다.

### 1회차

```lua
local t0 = os.clock()
local okStr, resStr = pcall(function()
	return require("@game/ReplicatedStorage/quad-base/src")
end)
local t1 = os.clock()
local loadedAtStr = game:IsLoaded()
…
local okIdx, resIdx = pcall(function() return require(rs["quad-base"].src) end) -- WaitForChild 없이 인덱싱
local okBogus  = pcall(function() return require("@nonsense/Foo") end)
local okBadPath = pcall(function() return require("@game/ReplicatedStorage/NoSuchThing") end)
```

출력(그대로):

```
STRREQ|str  ok=true res=MODULE:table dt=0.0170 IsLoaded=true RSchildren=3
STRREQ|idx  ok=true res=MODULE:table dt=0.0000
STRREQ|bogus-alias ok=false res=error requiring "@nonsense/Foo": @nonsense is not a valid alias
STRREQ|bad-path    ok=false res=error requiring "@game/ReplicatedStorage/NoSuchThing": could not resolve child component "NoSuchThing"
STRREQ|env  IsLoadedNow=true totalDt=0.0173
```

### 2회차 (첫 줄에서 `IsLoaded`를 먼저 재도록 고쳐서)

```
STRREQ2|pre  IsLoaded=true RSchildren=3 hasQuadBase=true
STRREQ2|str  ok=true res=MODULE:table dt=0.0105
STRREQ2|late ok=false res=error requiring "@game/ReplicatedStorage/LateModule": could not resolve child component "LateModule" (LateModule does not exist)
STRREQ2|env  IsLoadedNow=true runService.IsClient=true
```

### 판정

| 물음 | 답 |
|---|---|
| 이 Studio 버전(0.738)에서 `require("@game/…")`가 **되는가** | **된다.** 두 번 다 성공(`MODULE:table`) |
| 1회차에 바로 성공했는가 | 그렇다. 두 번 다 첫 시도 성공 — 흔들림(flakiness) **관측 안 됨** |
| 그 시점 `game:IsLoaded()` | **두 번 다 `true`** — 스크립트 첫 줄 이전에 이미 복제가 끝나 있었다 |
| **기다리는가(yield)** | **아니다.** 없는 대상은 즉시 실패한다 — `could not resolve child component "LateModule"`. 되는 경우의 `dt`(10~17ms)는 대기가 아니라 모듈 컴파일·실행 시간이다 |
| 인스턴스 경로 인덱싱(`rs["quad-base"].src`, `WaitForChild` 없이) | 같이 성공(`dt=0.0000` — 문자열 require가 이미 캐시에 올려둔 뒤라 즉시) |
| 별칭·경로 에러 문구 | `@nonsense is not a valid alias` / `could not resolve child component "…"` — **종류가 다르다**. 즉 `@game`은 실재하는 별칭으로 해석된다 |

**즉 에이전트 웹 리서치 쪽(“기다리지 않고 즉시 실패”)이 메커니즘으로는 맞고, 사용자 전제(“async”)는
대기 의미로는 틀리다.** 다만 이번 실측에서 실패가 안 난 이유는 **첫 줄 시점에 이미 `IsLoaded == true`**
였기 때문이다.

⚠️ **이 실측으로 D9를 닫을 수는 없다.** Studio의 Play Solo는 서버·클라이언트가 한 프로세스에 있어
복제가 사실상 즉시 끝난다 — DevForum이 말하는 위험은 **실서버에 접속하는 진짜 클라이언트**의 이야기다.
여기서 얻은 확정 사실은 둘뿐: (1) 문자열 require는 이 버전에서 동작하고 별칭 해석도 된다, (2) 대상이
없으면 **기다리지 않고 던진다**. "실제 접속에서 첫 줄이 복제보다 앞설 수 있는가"는 여전히 **미실측**이다
(Studio에서 낼 수 없는 조건 — 실기기 접속 테스트가 필요). 보수적으로 가려면 진입점에
`game.Loaded:Wait()`(또는 `if not game:IsLoaded() then game.Loaded:Wait() end`) 한 줄을 두는 쪽이
안전하다는 근거는 (2)로 충분하다.

---

## D. `HUMAN_TODO` 14.2 — `roblox_sync_config_generator` 없는 Studio 싱크

**미실측.** 이 항목은 **소비자 프로젝트에서 `pesde install` 뒤 rojo 프로젝트를 새로 만들어 Studio에
붙여 보는 것**이라, 지금 붙어 있는 rojo 세션(이 레포의 `default.project.json` — A·C가 그 위에서 돌았다)을
끊고 다른 project 파일로 갈아타야 한다. 그러면 이번 배치의 다른 항목을 잃고, 플러그인 Connect는 사람
손이 필요해(`HUMAN_TODO` 12) 되돌리는 것도 자율로 못 한다. 게다가 `pesde install`은 이번 작업 지시에서
금지됐다. 다음 Studio 세션에서 **단독으로** 잡을 것.

---

## 아직 안 본 것

- **A**: mock/CLI 쪽 1회는 `mock.luau` 코드 독해(값 비교 없는 `fireChanged`)로 판정했고 CLI를 새로
  돌려 세지는 않았다(`scripts/relink.sh`가 트리를 건드려서 이번 지시 범위 밖).
- **C-2**: `State<Tag>`를 `--!strict`로 타입 검사해 보지 않았다(런타임만). 또 잰 것은 Even↔Odd 교체,
  즉 **그 자리가 늘 태그 하나를 내는** 경우뿐이다 — 튜토리얼이 실제로 쓸 "태그를 켰다 껐다"
  (`q.Tag({})` 빈 집합이나 `q.None`을 발행해 그 자리가 아무 태그도 안 내는 상태)는 안 밟았다.
- **C-4**: 셀렉터 문법은 공식 문서에 없어 전수 프로브로 역설계한 것이다 — 여기 적힌 표는 0.738에서
  관측된 동작이지 계약이 아니다. 부정 결합자(`!=`), 와일드카드, 의사 클래스는 전부 에러였고 대안 철자는
  더 찾지 않았다.
- **B**: 실서버 접속(진짜 클라이언트)에서의 복제 순서. Studio Play Solo로는 낼 수 없는 조건.
- **D**: 위 그대로.

**Studio 안정성**: 이번 배치에서 크래시·무응답 없음. Play 두 번 모두 정상 시작/정지.
정리: `ReplicatedStorage.QuadTmp20260910`, `StarterGui.QuadTagTest`/`QuadDocCard`,
`StarterPlayerScripts.QuadStrReqProbe`를 전부 삭제했다.
