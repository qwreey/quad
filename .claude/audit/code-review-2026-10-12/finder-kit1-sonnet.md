# kit1 finder (sonnet) — 움직이는 면 + 공용 입력 층

발견 (심각도 순)

1. 다중 터치에서 두 번째 손가락을 떼면 첫 번째 손가락의 끌기가 끝난다. 드로어(모달)에서 손가락 A가 시트 ClickSink를 누르고 끌고 있는 중에 손가락 B가 스크림을 눌렀다 떼면, B의 Interaction.drag는 자기 beginInput을 따로 쥐고 있어서 B가 뗄 때 finish가 돌고 Slide의 공용 `ended(x,y)`가 B의 좌표로 불린다. Slide의 `active`는 A의 제스처에 걸려 있으므로 `ended`가 A의 끌기를 B의 좌표로 끝내 버리고(`dragging` false, 스냅 복귀), A가 계속 움직여도 `active=false`라 무시된다. [실측] 프로브(Lune, 터치 A 끌기 -100 → B 스크림 누름·뗌): 위치가 -100에서 0으로 튕겨 돌아갔고 이후 A의 이동 입력은 반영되지 않았다. 위치: Sheet/Slide.luau 223-229(`began`이 `active`면 조용히 return하는데 해당 Drag의 연결은 이미 열려 있음), 258-261(`ended`가 어느 Drag가 불렀는지 모름), 같은 구조가 바텀 시트 핸들+싱크, 사이드 시트, 드로어 모두에 있다. 제안: `hook()`이 만든 Drag별로 콜백을 감싸 "지금 제스처를 쥔 Drag"가 아니면 OnMoved/OnEnded를 무시하게 하거나, 거부된 `began`의 Drag를 즉시 `Cancel`하되 그 취소가 `ended`로 새지 않게 한다.

2. 끌기 도중 인스턴스가 파괴되면 이미 상태를 넘겨받은 새 드라이버 몰래 상태의 Target을 덮어쓴다. `Slot:Single`이 새 드로어를 먼저 만들고(상태 인수 → 새 드라이버) 옛 드로어를 나중에 지우는 바로 그 경로(Anchored.attach 주석이 말하는 시나리오)에서, 옛 것이 끌기 중이면 Destroy → `trackers:Cancel` → `ended(cancelled)`가 `destroyed=true`인데도 `rec.Target:Set(target)`까지 실행한다(`go`만 destroyed 가드가 있음). [실측] 프로브: 열린 상태에서 옛 드로어를 -360 쪽으로 끌다가 같은 DrawerState로 새 드로어를 만들고 옛 것을 dispose → TargetValue = "Closed", CurrentValue = "Open", 새 드로어는 열린 채(위치 0). Target과 화면이 어긋난 채 남는다. 위치: Sheet/Slide.luau 244-278(특히 `rec.Target:Set(target)`), destroy 300-312. 제안: `ended` 맨 앞(상태 정리 뒤)에서 `if destroyed then return end`, 또는 `rec.Driver ~= driver`일 때 상태 쓰기를 건너뛴다.

3. WideNavigationRailState의 `Driven`이 한 번 true가 되면 레일이 파괴돼도 영영 false로 돌아오지 않아, 이후 Expand/Collapse/Toggle이 TargetValue만 바꾸고 CurrentValue는 안 움직인다. 상태 머리 주석("레일이 없으면 즉시 settle")과 어긋난다. [실측] 프로브: 레일 만들고 dispose 뒤 `state.Expand()` + 1초 → target Expanded, current Collapsed. 위치: NavigationRail/init.luau의 `rec.Driven = true`(상태 쪽 NavigationRail/State.luau 53-58의 `go`가 읽음). 같은 상태를 다른 레일이 다시 받으면 문제없지만 레일이 일시적으로 사라지는 화면(탭 전환으로 Slot이 레일을 폐기)에서 `IsExpanded` 같은 파생이 낡는다. 제안: 레일의 Effect 정리(또는 OnDestroyed)에서 `rec.Driven = false`로 되돌린다(새 필드 아님, 기존 필드의 수명 정정).

4. 드래그 중 프로그램 전이가 Current를 손가락이 아직 눌린 채로 확정한다. Slide.go는 `dragging`이면 오프셋 이동만 건너뛰고 `scheduleSettle`은 그대로 걸어서 motion.Time 뒤 `rec.Current:Set(value)`가 손가락이 아직 눌려 있는 동안 불린다(예: 끌고 있는 모달 시트에 코드가 `Hide`). 그러다 뗌 때 `Release`가 다른 앵커를 고르면 Current가 이미 앞선 값으로 확정됐다가 바뀌므로 IsOpen류 파생이 깜빡인다. [추정] 읽기만으로(Slide.luau 138-153). 심각도 낮음. 제안: `dragging`이면 settle 예약을 건너뛰고 뗌의 `go`에 맡긴다.

5. 앵커가 없어진 사이 끌기가 끝나면 상태가 어정쩡하게 남는다. `ended`에서 `dragging:Set(false)` 뒤에 `anchors == nil or #anchors == 0`이면 return하므로 `rec.Target/Current`에 아무것도 안 하고, 시트가 레이아웃을 잃은 상태(호스트 AbsoluteSize 0)에서 끌기가 끝나면 그 순간의 오프셋이 다음 relayout까지 남는다. [추정] Slide.luau 262-264. 낮음. 제안: 그 경우에도 `go(rec.Current:Get(), "Settle")`로 되돌린다.

6. relayout이 진행 중인 모션을 매번 처음부터 다시 쏜다. 모션 중(`settleThread ~= nil`) AbsoluteSize 변화마다 `set(target, cfg.Motion(lastKind))`로 풀 길이 트윈을 다시 걸지만 settle 타이머는 새로 예약하지 않아서, 콘텐츠 높이가 여러 프레임 변하면(Content의 AutomaticSize를 애니메이션하는 자식) 화면 모션은 계속 연장되는데 Current는 원래 시각에 확정된다. [추정] Slide.luau 178-182. 제안: re-aim 때 남은 시간만큼의 모션을 쓰거나 settle도 같이 재예약.

7. 모달 시트·모달 사이드 시트의 open()이 거의 같은 40줄을 두 벌 갖고 있다(dismiss, OnClose에서 "Hidden으로 보냄 + Detach + 사용자 OnClose", OnGo에서 Hidden이면 dismiss, 핸들 모양). 또 `q.Tween{Value=…,Time=p.Time,Style=…,Direction=…}`로 Pos를 프로퍼티에 옮기는 Compute가 Sheet.luau·Surface.luau·Drawer.luau(`tween` 헬퍼) 세 곳에 따로 있다. [추정] 더 나은 구현: Slide가 `slide.Tween(map)`을 제공하면 세 곳이 한 줄이 된다(새 이름이라 사용자 결정 필요 — 증상은 중복, 처방 미정). 위치: BottomSheet/Modal.luau 105-214, SideSheet/Modal.luau 50-145, Sheet/Slide.luau.

8. 끌기 매 이동마다 새 테이블·새 q.Tween 서술자를 만든다. 포인터 이동 한 번당 `pos:Set({...})` 새 테이블 + Pos를 구독하는 Compute가 `q.Tween{ Time=0 }`를 새로 만들고(시트는 `Position`, `shown`/scrim 등 Compute 2~3개) 프로퍼티에 다시 대입한다. 드로어는 스크림 투명도 Compute까지 별도. [추정] 마우스 1000Hz 입력에서는 부담이 될 수 있으나 측정하지 않았다. 낮음. 제안: 끌기 중에는 `Time == 0`용 상수 서술자를 재사용하거나 오프셋만 별도 Source로 분리.

9. 앱 바 스크롤 정착의 지연 호출이 프레임이 파괴된 뒤에도 남는다. `Destroying`은 `stopSettle()`과 `frame=nil`만 하고 `task.delay(IDLE, settle, v)`로 걸린 예약(와 마우스가 눌려 있는 동안 100ms마다 자기 재예약하는 루프, 186행)은 취소하지 않는다. 파괴된 뒤에도 마우스 버튼이 눌려 있으면 해제될 때까지 100ms 루프가 돌고, 해제되면 `inst==nil`로 HeightOffset만 0.2초 애니메이션한다. [추정] AppBar/Scroll.luau 186, 268-273. 낮음(자원 누수라기보다 죽은 바의 상태를 건드림). 제안: `Destroying`에서 `version += 1`로 대기 호출을 무효화한다.

10. SheetState.Show/Expand/PartialExpand/Hide와 DrawerState.Open/Close의 비대칭 검증. SheetState.Hide는 `ConfirmValueChange`에 묻는데(Compose도 그렇다) DrawerState의 `Open`/`Close`는 안 묻는다고 머리에 적혀 있다 — 이건 의도. 다만 `SheetState.Show`는 `rec.Driver`가 있으면 `HasAnchor`로, 없으면 `enabled`로 PartiallyExpanded를 판단하므로, 모달 시트가 레이아웃 전(앵커 없음)에 `Show`하면 PartiallyExpanded 앵커가 아직 없다는 이유로 Expanded로 간다(modal에서는 PartiallyExpanded가 enabled여도). OnLaidOut 이후에만 Show를 부르는 흐름 덕분에 지금은 안 드러난다. [추정] 낮음, 문서 한 줄 감이다.

확인했지만 문제없던 것
- Interaction.drag의 전역 연결(InputChanged/InputEnded/WindowFocusReleased)은 finish 한 곳으로만 닫히고 release·포커스 상실·Destroying·Cancel 네 경로 모두 거친다. LockScroll 복원도 같은 곳.
- Overlay의 Escape 스택·layer 사망 정리, close 안의 "OnClose가 던져도 제거가 먼저 예약됨" 순서.
- Navigation/Motion.progress: 중간 되돌림, snap, OnSettle 호출 시점, Effect 정리에서 Heartbeat 연결 해제.
- Ripple: 동시 개수 상한·Destroying 시 타이머/연결 정리·UIScale 보정(레이아웃 의존 부분은 읽기만).
- Scroll 정착: 사용자가 정착 중 스크롤하면 취소(`written` 비교), 짧은 리스트에서 expand로 폴백, mouse-held 재예약.
- 모달 시트의 Detach/OnClose 순서(Hide → Detach → 사용자 OnClose)에서 settle 타이머가 `rec.Driver == driver` 가드로 죽는 것.

못 본 것
- AppBar/Top.luau(510줄), AppBar/Actions·Bottom, Toolbar.luau, NavigationDrawer/Item·Sheet, Navigation/Item, SideSheet/Standard 일부는 훑지 못했거나 연결 grep만 했다(Heartbeat/task.delay/Connect는 위 세 곳과 Ripple뿐임을 grep으로 확인).
- 레이아웃에 기대는 주장(AbsoluteSize 0 처리, AutomaticSize 상호작용)은 mock에 레이아웃이 없어 전부 [추정].
- 프로브 스펙 3개는 스크래치 사본(kit-s1/quad-roblox-material/test/spec.probe1~3.luau)에만 있고 레포에는 없다.
