# 킷·코어 Studio 실측 2026-10-13 (`Place1.rbxl`, PlaceId 0, 레포 `0d8fd79c` 싱크)

sonnet 서브에이전트가 Studio MCP로 측정(Play Client에서 `ReplicatedStorage`의 킷을 require해 별도 ScreenGui에 직접 마운트). 전부 [실측]이고,
아래는 그 보고를 메인이 옮겨 적은 것이다(에이전트는 파일을 쓰지 못했다). 항목 번호는 `research/consumer-kits-plan.md` 5절의 "Studio가 돌아오면 먼저 볼 것".
**이 플레이스의 신호 설정은 Deferred다** — `workspace.SignalBehavior`는 MCP로 읽지도 쓰지도 못해 동작으로 판정했다(`Parent` 대입 다음 줄에서는 콜백이
아직 안 불렸고 `task.wait()` 뒤에 불림). 그래서 Immediate 전용 관측은 전부 미완이다 — 사람이 Workspace 속성에서 Immediate로 바꿔야 한다.

## 1. `Dialog` 인스턴스 본문의 높이 — 재현됨

`Dialog.open({ Headline = "제목", Body = …, Width = 460, Actions = { Cancel, OK } })`, 레이어 1325×659, 1.5초 뒤 값, UIScale 1.

| 경우 | 카드 H | 본문 H | Actions 위~아래 | 카드 아랫변 | 기대 H |
|---|---|---|---|---|---|
| (가) 자동 높이 Frame(5줄, 합 272) | 376 | 272 | 494~542 | 518 | 424 |
| (나) 고정 278 Frame | 382 | 278 | 496~544 | 520 | 430 |
| (다) 문자열 | 152 | 14 | 348~396 | 406 | 166 |
| (라) `Fit = true`(자동 높이 Frame) | 424 | 272(스크롤 래퍼 없음) | 470~518 | 542 | 424 |

기대 H = 24 + 머리말 24 + 16 + 본문 + 16 + Actions 48 + 24. (가)(나)는 정확히 48 모자라고 Actions 아랫줄이 카드 밖으로 24 나온다(`item1-dialog-auto-body.jpg`).
**(다) 문자열 본문도 14 모자란다**(본문 높이와 같은 값 — 원인 미상). (라)는 맞다. 한 프레임·0.5초·1.2초 뒤에도 그대로다(늦게 맞춰지지 않음).

원인 좁히기((가)에서 띄운 뒤 런타임에 본문 `ScrollingFrame`의 속성을 바꿈, 값은 카드 H): `AutomaticCanvasSize` 끄기 376 / `UISizeConstraint` 제거 376 /
둘 다 376 / `AutomaticSize` Y→None→Y 토글 376 / `AutomaticSize = None`만 376 / **`AutomaticSize = None` + `Size = (1,0,0,272)` → 424** / 그 뒤 다시 `AutomaticSize = Y` → 424 유지 /
**`AutomaticSize = Y` 그대로 + `Size = (1,0,0,272)` → 424** / `Size = (1,0,0,1)` 376 / 같은 값 재대입 376 / `Content`·카드의 `AutomaticSize` 토글 376 / `ScrollBarThickness = 0` 376.
즉 이 조합들에서는 본문 스크롤 프레임의 Size Y 오프셋에 본문 높이를 직접 써넣을 때만 48이 돌아왔다. "본문을 일반 Frame으로 옮겨 붙이기"는 미완.

**[같은 날 오후 — 원인 확인과 고침, opus + Studio]** 모자란 48은 단추 줄이 아니라 `Content`의 세로 패딩 24 + 24였다: 자동 높이 `ScrollingFrame`이 `UIPadding`과
`UIListLayout`을 둘 다 가진 자동 높이 부모의 직접 자식이면 부모의 자동 높이가 `min(세로 패딩 합, 스크롤 프레임 높이)`만큼 모자란다(문자열 본문의 14 = `min(48, 14)`).
같이 드러난 별개 결함 둘: `AutomaticSize`가 `UISizeConstraint.MaxSize`를 무시해 **한도가 걸린 적이 없었고**(30줄 본문의 스크롤 프레임이 1672), 긴 문자열 본문은 스크롤되지 않고
294에서 잘렸다. 고침은 스크롤 래퍼의 높이·캔버스를 킷이 직접 쓰는 것(`Dialog.luau` 머리 주석 "BODY HEIGHT", 엔진 규칙 넷은 `feedback/consumer-kits-studio-qa-2026-10-07.md` 끝 절).
고친 뒤 측정: (가) 424 / (나) 430 / (다) 166 / (라) 424, 긴 본문 30줄과 긴 문자열 모두 카드 629(층 685 안)·창 477에서 스크롤, 띄운 뒤 줄을 넣고 빼면 카드가 따라감(272 → 328 → 한도 → 104 →
빈 본문 153 → 48), table-sim 장면(1325×715, 본문 262·278) 414·430, ScreenGui UIScale 1.25·0.75에서도 모자람 0. 스크린샷 `dialog-fix-*.jpg`. 같은 구조를 쓰는 다른 면(메뉴·드로어 시트·
시간/날짜/색 선택 모달)은 원인이 달라 잘림 없음.

**[같은 날 — 한도가 머리말 실측을 따르게, opus + Studio]** 층 높이 685, 폭 312. 전(`71026a1b`) → 후, 카드 H / 층과의 여백 / 스크롤 창: 한 줄 머리말 + 30줄 본문 629/28/477 → 637/24/485,
두 줄 661/12/477 → 637/24/453, 세 줄 693/−4/477 → 637/24/421, 층 300×400에 네 줄 440/−20/192 → 352/24/104. 짧은 본문 경우들은 그대로. 띄운 뒤 머리말 글을 바꿔도(한 줄 → 세 줄 → 한 줄)
창이 485 → 421 → 485로 따라가고 카드는 637. 한계 확인: ScreenGui UIScale 1.25에서 카드가 층을 위아래 55.6씩 넘음(README에 적은 한계). 머리말 한 줄 24, 줄마다 +32. 스크린샷 `dialog-headline-*.jpg`.

## 2. 코어 GUI 인셋

갤러리 `ScreenGui`: `ScreenInsets = CoreUISafeInsets`, `IgnoreGuiInset = false`, AbsolutePosition (0,0), AbsoluteSize 1325×659(화면 높이 717, 위 58이 Roblox 상단 바).
갤러리의 탭 줄은 그 아래에서 시작해 가려지지 않는다(`item2-gallery-inset.jpg`). 대화 상자를 띄운 화면에서 스크림은 인셋 안쪽(659)만 덮고 위 58 띠는 덮지 않는다.
`Overlay.default()`는 ScreenGui를 만들지 않고 호스트의 ScreenGui에 레이어를 붙인다 — 호스트가 기본값이면 위와 같다.

## 3. 코어의 재진입 가드 — Deferred에서

(a) 원소의 `Parent` 변경 콜백에서 `slot:Add(other)` — 콜백이 바깥 `Add` 뒤에 불려 `Quad0167` 없이 통과, `Length` 2·자식 2. (b) 콜백의 `slot:WhenIdle(fn)` — 이미 연산 뒤라 즉시 실행.
(c) 콜백의 `error("boom")`은 `inst.Parent = x`의 호출자에게 전파되지 않음(Deferred에서는 당연 — Immediate는 미완). (d) 엔진이 값을 바꿔 돌려주는 프로퍼티:
`ScrollingFrame.CanvasPosition = (0,1000)`(캔버스 300, 창 100)은 **쓰기 직후 읽기가 이미 (0,200)**(동기 클램프), 콜백은 한 프레임 뒤 1회 (0,200); `TextBox.Text = "a\nb"`(`MultiLine = false`)는
그대로 유지. (e) Q186 장면(자식 `{x,r}`, 조상 `{inner, tail}`) — Deferred라 콜백이 연산 뒤에 불려 통과, 최종 `P.Length` 5·`inner.Length` 3. 호스트 `GetChildren` 순서는
`x,r,tail,y,pz`(삽입 순서, `LayoutOrder`는 전부 0 — quad-roblox는 물리 순서를 관리하지 않고 순서는 `Offset`을 `LayoutOrder`에 묶는 사용자 몫이다).

## 4. 조상의 클립과 `UIStroke`

창 50×30, 안의 상자(위치 −15,−12, 크기 55×50, `UICorner` 8, `UIStroke` 두께 1·2)가 위·왼·아래로 삐져나감, UIScale 2.3으로 확대(`item4-uistroke-clip.jpg`).
**`ClipsDescendants = true`인 Frame 창은 창 밖의 선을 전부 자르고, 경계에 걸친 선도 경계에서 깨끗이 잘린다**(창에 둥근 모서리가 있든 없든). **`CanvasGroup` 창은 자르지 않는다** —
상자 테두리 전체가 창 밖까지 보였다. **⚠️ [같은 날 정정 — 사용자 확인] 이것은 실측용 ScreenGui가 `ZIndexBehavior = Global`(코드로 만든 ScreenGui의 기본값)이었기 때문이다. Sibling에서는 `CanvasGroup`도 자식과 테두리를 창(둥근 모서리 포함)으로 자르고 `GroupTransparency`가 자식에 먹는다 — 일곱 조합 비교로 확인. 항목 1의 "단추가 카드 밖으로 보인다"도 같은 귀결이다(높이 수치는 무관).** 선이 창의 모서리 곡선 근처에 닿는 경우는 미완.

## 5. 목록 행의 `Trailing` 버튼

`ListItem({ Headline, Trailing = IconButton({ OnClick }), OnClick })`. 버튼 중심 클릭 → 버튼의 `OnClick`만(행의 것은 안 불림), 행 왼쪽 클릭 → 행의 `OnClick`. 마우스.

## 6. SplitButton의 첫 배치

`Content`의 `Position.X` 오프셋을 RenderStepped로 0.6초 기록. 고친 소스(`d88ba193`): 첫 샘플 24/22, 다음 샘플부터 0/−2(중간값 없음).
고치기 전 줄로 되돌린 사본: 24 → 22 → 17 → 12 → 8 → 5 → 3 → 2 → 1 → 0, 약 0.14초에 걸쳐 미끄러짐. 고침이 효과 있다.

## 7. 터치 — MCP로 불가

입력 도구는 마우스뿐, `TouchEnabled = false`, `VirtualInputManager:SendTouchEvent`는 capability 부족으로 거부. 터치 중 앱 바 정착·멀티터치 끌기·앱 전환 뒤 끌기는 사람 손이 필요하다.

## 8. Immediate 신호에서 (같은 날 오후 — 사용자가 Workspace `SignalBehavior`를 Immediate로 바꿈, 레포 `e1440c10`)

`Parent` 대입 다음 줄에서 콜백이 이미 불려 있음을 Edit·Play 둘 다에서 확인한 뒤 측정. 기대와 다른 것은 없었다.

**코어의 재진입 가드**(`D.Frame { slot }`, 원소의 `Parent` 변경 콜백, 콜백 안 호출만 `pcall`):

| 장면 | 관측 |
|---|---|
| `slot:Add(b)`의 창에서 `slot:Add(c)` | 콜백이 바깥 `Add` 안에서 불림, `Quad0167`. 바깥은 정상 반환, `Length` 1 |
| `slot:Remove(1)`의 창에서 `slot:Add(c)` | `Quad0167`, `Length` 0 |
| 같은 콜백에서 `slot:WhenIdle(Add c)` | 바깥 `Add` 반환 직후 이미 실행돼 있음, 자식 b·c, `Length` 2 |
| (Q186) `inner:Add(y)`의 창에서 조상 `outer:Add(pz, 2)` | `Quad0167` |
| 같은 창에서 `outer:WhenIdle(Add pz, 2)` | `inner:Add` 반환 뒤 실행돼 있음, `outer.Length` 5·`inner.Length` 3, 부기 순서 x, r, y, pz, tail |
| 같은 창에서 형제 Slot의 `Add` | 통과 |
| 신호 콜백의 `error("boom")` | `inst.Parent = x`의 호출자에게 **전파되지 않음**(다음 줄 실행, 에러는 출력 창에만) — quad의 전제 확인 |
| 원소의 콜백이 던질 때 `slot:Add(b)` | 정상 반환, 이어지는 `slot:Add(c)`도 통과(플래그가 남지 않음) |
| `:List` 행의 콜백에서 `slot:WhenIdle(rows:Set(…))` | 에러 없이 끝, 최종 자식 a·b·c |

**Property의 왕복**: `CanvasPosition = pos` + `q.OnChange("CanvasPosition", v → pos:Set(v))`에서 `pos:Set((0, 99999))` → `OnChange`가 쓰기 **안에서** 한 번 불려 (0, 200)을 읽고, 되써도
에러·반복 없이 끝(콜백 1회), 최종 인스턴스와 State 모두 (0, 200). `TextBox.Text`의 같은 왕복도 콜백 1회.

**킷 연기 검사**: 갤러리 탭 아홉을 마우스로 넘기는 동안 출력 창의 에러·`Quad%d+` 0건. `Dialog`(문자열 166 / 고정 278 본문 430 / 긴 본문 637 — Deferred 때와 같음), `Menu`, `Snackbar` 둘,
`ModalBottomSheet`(스크림 닫기), `Select`, `DatePicker`·`TimePicker` 모달, `Slider` 끌기 전부 에러 0. SplitButton의 `Content` 위치는 첫 프레임 24/22, 둘째 프레임부터 0/−2(중간값 없음 — Deferred와 같음).
미완: devui 창 안의 팝업을 연 채 창을 닫는 장면(마우스 클릭이 devui 창에 반응하지 않음 — 원인 미확인), `q.Out` 형태의 왕복.

## 9. Elevated SplitButton의 그림자 (같은 날 저녁 — 사용자가 화면에서 봄, opus + Studio)

사용자: *"그림자 있는 애 좀 이상함. 잘린 부분에서도 동그랗게 그림자 들어가서 중간 쯤에서 그림자가 사라짐."* 반쪽마다 네 모서리 반경 20인 caster가 그림자를 내서 가운데에서 말려 올라갔다
(`split-shadow-before-*.jpg`). 실험(Sibling ScreenGui, 손으로 만든 인스턴스): `UIShadow`는 부모가 투명해도 그려지지만 부모 모양 전체가 채워진 그림자라 전체 크기의 투명 caster는 2 px 틈으로
진한 줄이 비치고, 불투명 caster는 틈을 메운다; 조상의 `ClipsDescendants`는 자식의 `UIShadow`를 경계에서 깨끗이 자른다; `UIShadow`는 부모 `UICorner`의 트윈을 따라간다.
고침: caster를 없애고 면(바깥 반경 20 / 안쪽 4·눌림 12·선택 20)마다 `UIShadow`를 달고, Elevated 반쪽의 클립만 바깥 세 변을 그림자가 닿는 거리(15)만큼, 안쪽은 틈 2 px만큼 연다 —
반쪽마다 제 모양의 그림자(Compose와 같은 결과). Elevated 인스턴스 45 → 43, 다른 변형은 그대로. `split-shadow-after-*.jpg`(평상·호버·눌림·선택·뒤 반쪽 눌림·비활성·배율 다섯).
`Content`의 첫 프레임 24/22는 첫 레이아웃 패스 안에서 최종값으로 수렴한다(Immediate에서 신호 순서로 확인 — 화면에 그려지지 않는 것으로 판단; Deferred는 미확인).

## 10. 위쪽 스낵바와 떨어진 사이드 시트 (같은 날 밤 — opus 빌더 + Studio, 갤러리 Overlays 탭, 뷰포트 1447×743)

**위쪽 스낵바**(`Snackbar.new({ Position = "Top" })`): 층은 인셋 안쪽 1447×685, 스낵바는 층 기준 (551.5, 16) 344×42 — 화면에서는 상단 58 px 띠 아래라 가리지 않는다. y가 −8 → 16으로
내려오며 약 0.2초에 불투명, 2초 뒤 −8로 올라가며 사라짐. 둘을 연달아 넣으면 한 번에 하나(큐). 아래 호스트와 함께면 위 16·아래 16으로 하나씩 동시에. `snackbar-top-*.jpg`.

**떨어진 표준 시트**(`SideSheet({ Detached = true })`, 흉내 화면 460×300): 시트 256×268, 위·아래·붙은 쪽 16, `UICorner` 16 네 모서리, 그림자·모서리 패치 없음(정본: MDC `Widget.Material3.SideSheet.Detached`는
여백과 모양만 더하고 표준 시트는 surface·level0 그대로). 숨김은 폭 + 16만큼 나가 여백까지 완전히 밖. 끌기(End): 120 끌고 놓으면 펼침으로(120 < 반환점 136), 150이면 숨김; Start는 140에서 숨김(> 128).
**떨어진 모달 시트**(`ModalSideSheet.open({ Detached = true })`): 층 기준 (1175, 16) 256×653, 세 변 16, 스크림 위, level1 그림자(스크림 위에서 옅어 캡처로는 뚜렷하지 않음 — 수치로 확인). 끌어 닫기·스크림 닫기·Start 쪽 동작.
붙은(기본) 모달은 그대로 (1191, 0) 256×685. `sidesheet-detached-*.jpg`. 한계: 클립이 사각형이라 안쪽 여백을 넘는 내용은 모서리 자리에 각지게 보인다(`-8-clip-probe-tall-content.jpg`).
부수 관측: 한 줄 스낵바의 실측 높이가 42(머리 주석은 48).

## 11. 버튼 그룹과 순서 바꾸는 목록 (같은 날 밤 — opus 빌더 + Studio; 플레이스는 이때부터 `quad-test`, PlaceId 105962699098904)

**`ButtonGroup`**(별도 Sibling ScreenGui, 2.5~5배): 끝 칸의 두 면 이음매 없음(배율 1·1.25·1.5·1.7에서 분할선 둘레 화소 차 최대 2/255), 칸 사이 2·높이 40, 안쪽 모서리 8 / 누름 4 / 선택 알약,
가운데 칸(면 하나) 정상, Elevated 그림자가 칸마다 제 모양·이웃 위에 안 겹침, Outlined 외곽선이 겹쳐 두꺼워지지 않고 선택되면 사라짐, 누름·선택 전환 중 칸 폭 불변·첫 프레임부터 제자리,
`Width = 360`은 119/119/118, 마우스로 단일·다중 선택과 `Required`, 어두운 테마. 찾아 고친 결함: 포커스 링이 2 px 옆의 뒤 형제 칸에 가려짐(SplitButton 앞 반쪽도) → 포커스된 칸 `ZIndex` 2.
`buttongroup-*.jpg`.

**순서 바꾸는 목록**(`ListData`의 `OnReorder`, 갤러리 Surfaces, Immediate 신호, UIScale 1; 줄마다 `AbsolutePosition.Y`를 렌더 프레임마다 기록): **놓는 순간의 튐 없음** — 즉시 반영(끌린 줄 233 → 233,
이웃 163 → 163), 응답 0.1초·0.4초·2초 뒤, 가장자리 스크롤로 캔버스 끝까지 간 뒤 놓음(열 줄 모두 0 px), 정착 뒤 자동 높이 복귀 0 px. 끄는 동안 오프셋이 포인터 변위와 같은 프레임에 같은 값, 72짜리 줄을
56짜리 아래로 끌면 이웃이 −72를 약 0.17초에. 뜬 줄: 배경 #FFD8E4(TertiaryContainer)·모서리 16·그림자 레벨 4·`ZIndex` 2, 내용 색 #633B48(onTertiaryContainer — `Dragged`). 가장자리 스크롤:
`ScrollingEnabled`가 꺼진 채로도 `CanvasPosition` 쓰기가 먹고, 프레임당 1 px에서 약 2초에 걸쳐 가속, 캔버스 끝에서 멈춤, 굴러가는 내내 줄 중심과 포인터의 차 0.0. 손잡이 클릭은 줄의 `OnClick`을 부르지 않음.
키(Enter로 잡고 위·아래)는 `OnReorder(7, 8)` 등을 바로 부르고 선택이 손잡이에 남음. `Reordering`: 2초 지연에서 1초를 넘겨도 새 자리에 머물고 응답 때 0 px; 거짓이 됐는데 `Items`가 그대로면 약 0.17초에 복귀.
찾아 고친 결함 셋: 키로 옮긴 줄이 스크롤 창 밖으로 나감(새 순서가 올 때 그 줄이 보이게 캔버스를 옮김), 키로 잡은 줄의 `ZIndex`, 갤러리 설명 글이 두 줄로 접히며 목록이 16 밀리던 것. 낮은 `ScrollingFrame`의
가장자리에서는 뜬 줄의 그림자가 잘린다(엔진 규칙 — 한계). 측정 도구의 가짜 신호 하나: MCP 마우스가 누른 채 한 프레임 포인터를 y = −18로 보냄. `reorder-*.jpg`. 미완: 터치, 1이 아닌 UIScale, Deferred.

## 12. Outlined TextField의 레이블 노치와 비활성 Card (같은 날 밤 — opus 빌더 + Studio, `quad-test`, Play Client, Immediate 신호, 뷰포트 1447×565)

**노치**(외곽선을 덧칠하지 않고 끊음 — 외곽선 사본 셋을 클립 창 셋에; 구조는 `quad-roblox-material/src/TextField/Container.luau` 머리). 실험용 ScreenGui(Sibling)에 그라디언트·SurfaceContainerHigh·Primary 세 배경을 깔고
조상 `UIScale`로 확대해 캡처. 고치기 전(`notch-0`)은 표면색 조각이 세 배경 모두에서 보이고 뜬 레이블이 선보다 3 px 위(상자 −9..3)였다. 고친 뒤: 쉼·뜸·비활성(`notch-1`), 포커스 2 px·오류(`notch-2`), 긴 레이블·레이블
없음(`notch-3`), 트윈 도중(`notch-4`·`notch-5` — 포커스를 0.11초마다 뒤집으며 찍음), 앞 아이콘·접두/접미·여러 줄(`notch-6`), 어두운 테마의 Select·NumberField·포커스(`notch-7`), 조상 UIScale 1.25·1.5 원본 픽셀과 그
9배 확대(`notch-8*`·`notch-9*`), 7배 모서리(`notch-10`), 갤러리 묶음·색상 선택기 모달의 헥스 필드(`notch-11`~`13`). **프레임 기록**(쉬는 필드를 `CaptureFocus` → 0.5초 → `ReleaseFocus`, 렌더 프레임 62개, UIScale 2.5):
외곽선 사본 셋의 `AbsolutePosition`·`AbsoluteSize` 열두 숫자의 최대 변화 0 px(끝 창의 상자 −9792.5, −18 / 10240×80, 시작 창의 상자 35, −18 / 80×80, 아래 창의 상자 35, −18 / 412.5×140), 끝 창의 오른쪽 끝 452.50 고정.
끊긴 끝(필드 x, 지역 단위)은 포커스 뒤 34 ms부터 프레임마다 23 → 31 → 36 → 40 → 43 → 44 → 45 → 46(158 ms), 내릴 때 35 → 27 → 22 → 17 → 15 → 13 → 12. 값이 있는 채로 만든 필드: 만든 직후 끝 창 `Visible = false`,
부모에 붙인 뒤 첫 렌더 프레임에 이미 보임 + 끊긴 자리(87 = 16 + 67 + 4) — 선이 레이블을 가로지르는 프레임 없음.
엔진 사실 넷: (1) **`UDim`의 Offset은 정수다** — 소수 Offset은 버려진다(−43.6 → −43; 그래서 레이블 폭을 올림해 쓴다). 트윈도 지역 단위 정수로 움직인다. (2) **음수 크기의 클립 창은 반대쪽으로 뒤집혀 그린다** —
`AnchorPoint` (1, 0)인 창의 폭이 −162.5가 되자 필드 오른쪽 밖에 선이 그려졌다. (3) **`UISizeConstraint`(기본 MinSize 0)는 음수 크기를 0으로 잡는다**(`AbsoluteSize` 0). (4) 클립 창 둘이 만나는 이음매(위에서 8)는
UIScale 1.25·1.5(창 경계가 소수 픽셀)에서도 반투명 선(비활성 12 %)에 겹친 진한 점·틈이 없다. 덧붙여 **MCP `execute_luau`에서 `require`한 킷은 게임 스크립트가 쓰는 것과 다른 모듈 인스턴스였다**
(거기서 부른 `Theme.default:SetScheme`이 갤러리에 닿지 않아 Theme 탭의 스위치를 마우스로 눌렀다). 미완: 터치·게임패드 포커스, Deferred 신호에서 태어날 때 뜬 필드의 첫 프레임.

**비활성 Card**(갤러리 Surfaces의 비활성 카드 셋, `card-disabled-1`(밝은)·`card-disabled-2`(어두운)): 인스턴스의 색이 정본 식(Compose `Card.kt`)의 값과 채널 차 0 — 밝은 테마 Elevated `#FEF7FF`(Surface)·그림자 레벨 1 유지,
Filled `#E6E0EA`(SurfaceVariant 38 % over SurfaceContainerHighest), Outlined 컨테이너 `#FEF7FF`·외곽선 `#E8E3EB`(Outline 12 % over SurfaceContainerLow, 투명도 0); 어두운 테마 `#141218` / `#3D3A43` / `#141218`·`#2B292F`.
어두운 테마에서 비활성 Filled는 활성(`#36343B`)보다 **밝다**(SurfaceVariant가 더 밝은 역할 — 정본 그대로).

## 13. code-review가 남긴 실기기 항목 (같은 날 밤 — sonnet + Studio, `quad-test`, 레포 `d89bb54d`)

**devui — 뒤에 있는 창 안의 위젯을 누르면 창이 앞으로 오지 않는다(확정).** 창 둘(각자 버튼·체크박스·콤보·Selectable·트리·탭·입력 칸·슬라이더), A를 앞으로 가져온 뒤 B의 위젯을 누름:
Button·Checkbox·Combo 상자·Selectable·Tree 머리·Tab·TextBox는 위젯은 동작하는데 창 루트와 내용 프레임의 `InputBegan`이 발화하지 않아 B의 `ZIndex`가 1 그대로다. 슬라이더(Frame)·빈 내용 영역·타이틀바는
`InputBegan`이 오고 B가 앞으로 온다. 누름이 포인터 아래의 첫 GuiButton·TextBox에서 멈추는 것과 맞는다. `review-c-1-*.jpg`.

**devui — 조상이 `Visible = false`가 돼도 자손에 `MouseLeave`가 오지 않는다(확정).** 창 안 버튼에 마우스를 올린 채 `Open`을 false로: `MouseLeave` 없음, 호버 색 유지, 떠 있던 툴팁 그대로; 툴팁이 뜨기 전에
닫으면 1.5초 뒤 툴팁이 새로 뜬다. 다시 열면(마우스 그 자리) 호버 색 그대로이고, 마우스를 움직여 나간 뒤에야 풀린다. 열린 콤보 목록도 창을 닫아도 남는다. `review-c-2-*.jpg`.

**material — 날짜 칸에서 Enter 한 번이 두 번 고르기가 된다(확정 → 고침).** 엔진은 선택된 GuiButton에 Return으로 `Activated`를 낸다(맨 TextButton으로 확인, `gameProcessed = true`). 날짜 칸은 키 처리기의 Return
분기와 칩의 `Activated`가 둘 다 골라 Docked는 `OnChange` 2회, 범위 선택은 시작 = 끝 = 같은 날로 확정됐다 → 키 처리기의 Return 분기를 없앰. `review-c-3-datepickers.jpg`.

**devui — `ZIndexBehavior`가 Global인 ScreenGui의 창 둘(확정).** 앞(서열 2) 창의 내용이 자기 루트에 가려져 흐린 윤곽만 보이고 콤보 목록도 흐리다. 서열이 바뀌면 가려지는 창도 바뀐다. `q.debug`에서 콤보를 처음 열 때
알림 한 줄이 나온다. `review-c-5-global-*.jpg`.

**연기 검사**: 갤러리 탭 아홉에서 에러·`Quad%d+` 0건; 버튼 그룹 클릭, Outlined 필드의 노치, 순서 바꾸는 목록 끌기(`OnReorder(1, 3)`), 위쪽 스낵바 정상. 메뉴 항목 더블 클릭(60 ms 간격)에 `OnClick` 1회,
`Dialog.confirm`의 OK 더블 클릭에 결과 1회(그날 고침 확인). devui 숫자 칸은 클릭했다 떠나도 값 그대로. 관찰 하나: 갤러리 Actions 메뉴의 "Duplicate" 라벨이 "…"로 줄어 보인다 — 메뉴 폭이 앵커 폭(최소 112)으로
정해지고 항목을 재지 않아(머리 주석이 밝힌 한계), 뒤 글자 64가 있으면 라벨 자리가 16 px 남는다; `Menu.Button`에는 폭을 줄 길이 없다.

**못 본 것**: submit 모드 `InputText`의 Escape(MCP가 Escape 키를 거부 — 사람 손), 터치.

## 미완

Immediate 전용 관측(항목 3 전부 — 가드의 거부, `WhenIdle`의 지연 실행, 신호 콜백 에러의 전파, Q186 장면), 항목 1의 "일반 Frame으로 옮겨 붙이기"와 문자열 본문 14의 원인,
항목 4의 모서리 곡선 근처, 항목 7 전부. Studio 설정은 바꾸지 않았고 실험용 ScreenGui는 지웠으며 Edit 모드로 돌려놓았다.
