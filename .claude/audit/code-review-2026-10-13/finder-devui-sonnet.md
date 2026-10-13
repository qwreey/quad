# quad-roblox-devui 전체 code-review (파인더, sonnet)

범위: quad-roblox-devui/src 전체(Window/·Overlay·Menu·Combo·PopupParts·Tooltip·Tree·Table·Tab·Plot·Inputs/·단순 위젯·Interaction·Input·Util·Style). 스크래치 사본(devui-s)에서 Lune으로 프로브 여섯을 돌렸다(프로브 파일은 devui-mirror/quad-roblox-devui/test/probe.*.luau, 레포는 안 고침). 하네스에는 연결 수를 세는 방식(UserInputService 신호의 .connections, Heartbeat, H.pendingTimers)이 이미 있어 같은 방식으로 수명 프로브를 짰다. Studio는 쓰지 않았다(엔진 동작에 기대는 주장은 [추정]).

## 발견 (심각도 순)

1. 숫자·16진 입력칸은 글자를 고치지 않고 포커스만 넣었다 빼도 값을 덮어쓰고 OnChange를 부른다. InputNum의 값이 0.12345이고 기본 형식이 "%.3f"이면 칸에는 "0.123"이 보인다. 사용자가 칸을 눌렀다가 아무것도 안 치고 빠져나오면 FocusLost가 commit()을 부르고, commit은 칸의 글자를 다시 파싱해 0.123을 OnSet에 넘기므로 값이 0.12345에서 0.123으로 줄고 OnChange가 한 번 불린다. 같은 뿌리가 InputVector2/InputUDim2의 Edit 칸(값 0.12345가 0.123으로), 정수 형식 "%d"로 보여 주는 3.7(4로 바뀜), InputColor3의 16진 칸(Color3.new(0.5,0.5,0.5)가 #808080 → 128/255로 양자화되어 값이 바뀌고 OnChange 발화)에도 있다. OnChange는 "사용자가 바꾼 뒤에만"이라는 킷 계약인데 이 경로는 바꾸지 않은 채 발화하고 정밀도를 깎는다. 위치: src/Inputs/NumberField.luau commit()(약 106~116줄, 글자 비교 없이 OnSet), src/Inputs/InputColor3.luau hexField FocusLost(약 78~96줄). [실측] probe.commit.luau(P1a 값 0.123·OnChange 1회, P1b hex 변경됨·OnChange 1회, P1c vec2 0.123·%d 4). 드래그 칸(DragNum·RGB 칸)은 editing일 때만 commit해서 영향 없음. 제안: commit 앞에 "칸의 글자 == 지금 shown 글자면 OnSet 안 부르고 repaint만" 한 줄 검사(hex도 같은 방식).

2. 코드로 만든 ScreenGui에서 Window 겹침 순서는 ZIndexBehavior 기본값에 기대는데, 문서가 그 기본값을 Sibling이라고 적고 아무 경고도 없다. Window는 ZIndex = 서열(1..n)로 겹침을 정하고 Manager 머리 주석은 "ScreenGui.ZIndexBehavior = Sibling, the default"라 적었지만, material이 어제 Studio에서 확인했듯 코드로 만든 ScreenGui는 Global이 기본이다(commit 71822522 메시지). Global에서는 창 루트가 ZIndex 2 이상이면 ZIndex 1인 자기 자식 위젯들이 자기 배경 뒤로 숨고 창 사이 겹침도 어긋난다. src/init.luau 빠른 시작과 README 예제의 D.ScreenGui는 ZIndexBehavior를 안 주고(창이 하나라 서열 1이어서 우연히 보임), 갤러리 gallery/init.luau만 Sibling을 준다. material Overlay.open은 q.debug일 때 첫 Open에서 조상 ScreenGui의 ZIndexBehavior를 보고 한 줄 알리는데 devui Overlay에는 없다. 위치: src/Window/Manager.luau 머리 주석 5줄, src/init.luau 빠른 시작, README.md 22줄 부근, src/Overlay.luau openPopup. [추정] 엔진 동작은 읽기(material의 실측 인용)만, devui 쪽 Global 재현은 안 했다. 제안: 문서 정정 + 빠른 시작 두 곳에 ZIndexBehavior = Sibling + Overlay에 material과 같은 q.debug 한 줄(새 공개 이름 없음).

3. 터치로 SliderNum/DragNum을 끌면 바깥 Window의 ScrollingFrame이 같이 세로로 스크롤될 수 있다. Window 내용은 ScrollingDirection Y의 ScrollingFrame이고 슬라이더·드래그 칸은 그 안에 있다. material의 Interaction.drag는 같은 문제 때문에 LockScroll(끄는 동안 조상 ScrollingFrame의 ScrollingEnabled를 끔)을 갖고 있는데(src/Interaction.luau 51, 228~237줄) devui의 Interaction.drag에는 없다. 위치: src/Interaction.luau drag, src/Inputs/SliderNum.luau, src/Inputs/NumberField.luau. [추정] 터치 기기 엔진 동작이라 mock으론 못 봄. 제안: material과 같은 방식의 LockScroll 선택 옵션을 내부에 추가하고 SliderNum/DragNum만 켠다(킷 내부 옵션이라 공개 표면은 안 늘림 — 단 Interaction이 공개 export라 이름 추가는 사용자 결정).

4. 창을 프로그램으로 닫으면(Open:Set(false), 단축키 등) 마우스가 위에 있던 요소의 상태가 정리되지 않는다. 엔진이 조상 Visible 변화에는 MouseLeave를 안 준다는 것은 킷 자신의 Interaction.hover 주석이 전제하는 사실이고, 타이틀바의 두 단추만 Reset 이펙트로 구제한다. 그 밖에서 세 가지가 남는다. (a) 툴팁: 마우스가 올라간 채 창이 닫히면 대기 중이던 task.delay가 그대로 만료되어 숨은 대상 때문에 툴팁이 뜨고(Overlay 쪽이라 창과 무관하게 보임), 이미 뜬 툴팁은 닫히지 않는다. [실측] probe.life.luau P2 — 창 닫고 1초 뒤 Overlay.Count 1, tip.Visible true. (b) 콤보 목록: 목록이 열린 채 창이 프로그램으로 닫히면 목록(과 클릭 바깥 포착 버튼)이 떠 있다. 정상 경로에선 클릭 포착 버튼이 먼저 목록을 닫으므로 프로그램 닫기에서만. [실측] P3 — 창 닫은 뒤 popups 1. 창 dispose에서는 정상 정리(연결 0, popups 0). Overlay 머리 주석은 "overlay:CloseAll() (e.g. when the owning window closes)"를 권하지만 Window는 안 한다. (c) 창 안 일반 위젯(Button 등)과 리사이즈 그립의 hover 외관이 닫았다 다시 열면 그대로 남는다. [실측] probe.hover.luau — 닫았다 연 뒤 그립 투명도 0.33, 버튼 0(hover 값) 유지. 제안: Window가 Open이 false가 될 때 자기 hover.Reset(그립)과 Overlay의 팝업을 닫는 훅은 사용자 결정이 필요한 새 메커니즘에 가깝다 — 증상 확정, 처방 미정. 툴팁만은 show() 시점에 대상이 보이는지(AbsoluteSize 또는 Visible 조상 확인) 한 줄 검사로 막을 수 있다.

5. 포커스된 창을 닫아도 Manager의 Focused와 최상위 서열이 그 창에 남는다. 두 창 중 위 창(포커스)을 Open:Set(false)로 닫으면 manager.Focused가 닫힌 창 id로 그대로이고(아래 창의 타이틀바는 계속 "비활성" 색), 다시 열어도 서열은 올라가지 않는다(열린 창은 닫기 전 위치 그대로). [실측] probe.life.luau P4 — 닫은 뒤 focus id 2 유지, z 1/2 그대로. 제안: 닫힌 창은 Focused 후보에서 빼고(Open이 false가 되면 slot의 포커스 해제) 다시 열 때 Focus. 낮음.

6. 창을 화면 밖으로 끌어 완전히 잃어버릴 수 있다. 타이틀바 끌기는 Position에 dx, dy를 그대로 더할 뿐 제한이 없어, 창을 화면 밖으로 밀면 이동 손잡이가 닿지 않는다(ImGui는 타이틀바 일부가 화면에 남게 클램프). 위치: src/Window/init.luau OnMove(약 100~103줄). [추정] 읽기만. 제안: 클램프하려면 부모 크기가 필요해 새 동작이므로 사용자 결정.

7. 콤보 목록·메뉴·툴팁은 화면 가장자리에서 뒤집거나 클램프하지 않아 아래·오른쪽 끝에서 열면 화면 밖으로 나간다. Overlay 머리 주석이 "클램프는 호출자가 한다"고 선언했지만 실제 호출자(Combo/Menu/Tooltip)는 아무도 하지 않아 모바일에서 화면 아래의 콤보는 선택 불가. 위치: src/Combo.luau open(), src/Menu.luau open(), src/Tooltip.luau show(). [추정] 읽기만(콘텐츠 크기가 레이아웃 뒤에야 알려진다는 제약은 Overlay 주석대로). 제안: 낮음, 필요하면 Overlay가 첫 레이아웃 뒤 한 번 보정하는 방식은 사용자 결정.

8. Table은 윈도잉이 없는데 헤더에 그 사실과 비용이 적혀 있지 않다. Combo 머리는 "NO VIRTUALIZATION"을 밝히는데 Table 머리는 침묵한다. 행 하나가 RowBg+Borders+열 3개에서 인스턴스 20개(500행 = 10,018개, mock 구성 약 0.78초, 행당 1.5ms)이고 행마다 인덱스 파생 Compute 둘이 더 붙는다. 갱신 비용은 작다(500행 전체 갱신 14.6ms, 첫 행 삭제 12.8ms — 키 재활용이 잘 돈다). 위치: src/Table.luau 머리 주석. [실측] probe.table.luau. 제안: 머리에 "행 수천 개면 직접 페이지/필터" 한 줄(Combo와 같은 문구), 또는 RowBg의 Compute 둘을 하나로 합쳐 행당 노드 감소.

9. PlotLines는 값이 바뀔 때마다 모든 구간을 다시 계산한다. 200점 롤링 그래프 한 번 갱신에 구간 199개 × (geo Compute 1 + 투영 Compute 3) ≈ 800 노드와 프레임 속성 쓰기 600개 안팎이 돈다. mock에서 갱신당 평균 4.7ms(엔진 쓰기 비용은 별도). RuntimeInfo 같은 매 프레임 갱신 용도면 프레임 예산을 먹는다. 위치: src/Plot.luau PlotLines. [실측] probe.plot.luau. 제안: geo 테이블과 투영 3개를 구간당 Position/Size/Rotation 직접 Compute 3개로 풀면 노드 25%와 테이블 할당이 준다; 근본(값 이동 시 전부 재배치)은 롤링 윈도의 본질이라 갱신 빈도를 호출자가 제한하는 안내를 머리에 추가.

10. Combo에서 OnChange가 던지면 목록이 열린 채 남는다. 행 클릭 핸들러가 spec.OnPick(key) 다음에 close()를 부르므로 사용자 콜백이 던지면 close가 건너뛰어져 목록이 떠 있고(값은 이미 바뀜), 클릭 포착 버튼이 화면을 가린다. 콜백을 pcall로 감싸지 않는 것은 이미 결정이라 그것을 다투지 않고, 순서만 close() 먼저로 바꾸면 막힌다. 위치: src/Combo.luau 행 OnClick(약 160~164줄). [실측] probe.life2.luau — 던진 뒤 popups 1, value b. 제안: close() 후 OnPick(단 OnPick이 던져도 닫히는 쪽이 낫다).

11. 같은 코드 두 벌 이상. (a) hostName(name) 캐시 8줄이 Tree.luau, Inputs/NumberField.luau, Inputs/Choice.luau에 세 클래스(Frame/TextBox/TextButton)로 복사돼 있다 — material이 어제 같은 복사를 Util.frameName으로 합쳤다(commit d88ba193 메시지). (b) "눌림·호버·선택일 때만 Header 알파를 보이고 아니면 1" 계산이 PopupParts.row의 alpha, Selectable.row의 alpha, Common.headerLook 세 곳에 거의 같은 모양으로 있다(Selectable은 Disabled만 더함). (c) 색 Compute와 알파 Compute를 짝으로 쓰는 패턴(TitleBar bg/bgAlpha 포함)이 곳곳에 반복. 제안: (a)는 Util에 제네릭 캐시 하나, (b)는 Common.headerLook에 disabled 인자를 받게 해 두 곳이 쓰게. 가독성만의 문제라 우선순위 낮음.

12. init.luau 규칙 3("Never hard-code a colour/size")과 다른 하드코딩 값이 남아 있다: Text 라벨의 UIPadding 2px(src/Text.luau), TitleBar의 +4 간격(src/Window/TitleBar.luau leftPad/rightPad), Choice·Plot의 Size -4/-4 여백, Table·Tab의 1px 선. density(Default/Clear)를 바꿔도 이 값들은 안 따라와 Clear 밀도에서 어긋날 수 있다. [추정] 값별로 어긋나는지는 안 봄. 낮음.

13. InputText "submit" 모드는 Escape로 취소할 수 없다. Roblox TextBox는 Escape에도 FocusLost(enterPressed=false)를 내고 글자는 그대로 두므로, FocusLost에서 항상 box.Text를 커밋하는 이 모드에서는 Escape가 "취소"가 아니라 "확정"이다(ImGui는 Escape가 취소). 위치: src/Inputs/InputText.luau FocusLost. [추정] 엔진 동작이라 읽기만. 낮음 — 의도라면 머리 주석에 한 줄.

## 확인했지만 문제없던 것

- 끌기 수명: Interaction.drag는 begin 때 잡은 InputObject 하나만 추적(터치는 신원 비교, 마우스는 MouseMovement)하고 Destroying/FocusReleased/Cancel에서 연결 세 개를 모두 닫는다. 창을 끌기 도중 dispose하면 전역 연결이 기준선으로 돌아온다(probe.life2.luau — +3 → 0, 타이머 0). material이 어제 고친 "두 번째 손가락이 다른 면을 눌러 첫 끌기를 움직이거나 끝낸다" 문제는 devui에서 핸들마다 began을 따로 가져 구조상 해당 없고, 같은 핸들에서 두 번째 눌림은 `began ~= nil`로 무시된다. 파괴 중 면이 상태를 더 쓰는 문제도 finish(silent)가 OnEnd를 안 불러 해당 없음.
- 포커스 링 ZIndex(a6a7b678): devui에는 포커스 링이 없다.
- Tooltip: 대상 destroy 시 대기 타이머와 팝업이 같이 정리(probe: 타이머 0, 팝업 0), 눌림에서 hide.
- Overlay/Menu/Combo: 레이어 파괴·Slot 제거·dispose 때 팝업 닫힘과 Escape 연결 정리(probe: popups 0, 연결 0), 재진입 Slot CRUD는 WhenIdle로 우회, 서브메뉴 연쇄 닫기와 hover 재진입 중복 열기 방지(`popup` 선검사)가 맞다.
- Manager 서열: 서열은 1..n 재번호이고 Release가 정리한다(2000번 포커스 전환 스펙 존재).
- NumberFormat: 파싱의 NaN/inf 거부, snap의 부동소수 잡음 제거, 0·음수 step은 그대로 통과, 퇴화 범위(max<=min) 처리.
- Tree/Tab: 닫힌 자식을 Visible=false로 둔 설계는 문서화돼 있고 Tab 페이지도 동일.
- Table 키 재활용(행 상태 갱신 비용 작음).

## 못 본 것

- 엔진 실측이 필요한 것 전부: 터치 중 스크롤 동시 발생(3), 조상 Visible 변경 시 MouseLeave 여부(4), Escape 동작(13), Global 모드에서 창 자식이 가려지는 정도(2).
- Tooltip의 GuiInset 보정식("GetMouseLocation - GuiInset")이 IgnoreGuiInset=true인 ScreenGui에서 맞는지(머리 주석이 미확인이라 밝힘).
- Style.luau 토큰 표(약 400줄)와 갤러리/스토리 코드는 훑기만 했다(스토리 테스트 spec.stories 포함 읽지 않음).
- 접근성/게임패드 선택 이동은 범위 밖으로 보아 안 봄.
