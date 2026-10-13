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
상자 테두리 전체가 창 밖까지 보였다. 선이 창의 모서리 곡선 근처에 닿는 경우는 미완.

## 5. 목록 행의 `Trailing` 버튼

`ListItem({ Headline, Trailing = IconButton({ OnClick }), OnClick })`. 버튼 중심 클릭 → 버튼의 `OnClick`만(행의 것은 안 불림), 행 왼쪽 클릭 → 행의 `OnClick`. 마우스.

## 6. SplitButton의 첫 배치

`Content`의 `Position.X` 오프셋을 RenderStepped로 0.6초 기록. 고친 소스(`d88ba193`): 첫 샘플 24/22, 다음 샘플부터 0/−2(중간값 없음).
고치기 전 줄로 되돌린 사본: 24 → 22 → 17 → 12 → 8 → 5 → 3 → 2 → 1 → 0, 약 0.14초에 걸쳐 미끄러짐. 고침이 효과 있다.

## 7. 터치 — MCP로 불가

입력 도구는 마우스뿐, `TouchEnabled = false`, `VirtualInputManager:SendTouchEvent`는 capability 부족으로 거부. 터치 중 앱 바 정착·멀티터치 끌기·앱 전환 뒤 끌기는 사람 손이 필요하다.

## 미완

Immediate 전용 관측(항목 3 전부 — 가드의 거부, `WhenIdle`의 지연 실행, 신호 콜백 에러의 전파, Q186 장면), 항목 1의 "일반 Frame으로 옮겨 붙이기"와 문자열 본문 14의 원인,
항목 4의 모서리 곡선 근처, 항목 7 전부. Studio 설정은 바꾸지 않았고 실험용 ScreenGui는 지웠으며 Edit 모드로 돌려놓았다.
