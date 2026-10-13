# material 나머지 영역 리뷰 (finder-mat-rest-sonnet)

범위: DatePicker/, ColorPicker/, Menu, Select, Tabs, Chip/, Checkbox, Radio, Switch/, Progress/, Tooltip, Divider, Badge, Theme/Tokens, Icons/IconView, KeyNav, Interactive/StateLayer/Interaction, GlyphButton, M2/. (Overlay는 Menu·Modal의 근거로만 읽었다.)
프로브: 스크래치 mat2-s/quad-roblox-material/test/probe.{menu,date,sel,tip,keys,sw}.luau, 순수 계산은 mat2-s/probe/p1.luau. 실행은 mat2-s/run2.sh <프로브 파일명>.

## 발견 (심각도 순)

1. [실측] 닫히는 중(Overlay ExitTime 동안)에도 내용물이 눌려서 OnClick/OnConfirm/OnChange가 두 번 이상 불린다. 메뉴 항목을 누르면 handle.Close()가 불리지만, Overlay는 닫힘 시작 뒤 ExitTime(메뉴 0.1초, 날짜 모달 기본 0.2초) 동안 내용을 그대로 두고 어떤 입력도 막지 않는다. 그래서 같은 항목을 그 사이에 한 번 더 누르면(터치 더블탭이면 흔하다) Menu의 activate가 close()를 다시 부르고(멱등) item.OnClick()을 또 부른다. 프로브 probe.menu.luau에서 두 번 활성화한 결과 OnClick 2회. Select는 메뉴 항목 OnClick 안에서 value:Set과 props.OnChange를 부르므로 같은 방식으로 이중 발화한다. 더 나쁜 것은 DatePicker.Modal: OK를 한 번 누르고 닫히는 도중 OK를 또 누르면 onConfirm이 또 돌아 OnConfirm이 여러 번 불리고, 닫힌 뒤에 날짜 칸(draft)을 눌러 바꾼 값까지 OK로 Value에 커밋된다(probe.date.luau: OnConfirm count 3, 마지막 Value가 닫힌 뒤에 고른 2026-10-22). 위치: Menu.luau:131(activate), DatePicker/Modal.luau:최하단 OK의 onConfirm(open 안), Overlay.luau close()/remove() 사이. 같은 뿌리로 Select.luau:109-111(`open:Set(false)`가 닫힘 시작 OnClose에서 불려, 닫히는 100ms 안에 필드를 다시 누르면 메뉴가 하나 더 뜬다 — probe.sel.luau 2번, 메뉴 두 개가 동시에 마운트). 제안: 가장 싼 처방은 항목 활성화 자리마다 `handle.IsOpen:Get()`를 보는 것이지만, 뿌리가 Overlay라 Overlay가 closing 동안 entry 위에 투명 싱크 버튼을 얹는 쪽이 한 곳에서 닫힌다(Dialog 등 제외 영역도 같은 뿌리). 새 메커니즘이므로 증상 확정, 처방은 사용자 결정.

2. [실측] Menu/Select의 메뉴는 앵커가 파괴돼도 계속 열려 있다. Menu.open은 앵커 위치를 열 때 한 번만 읽고 앵커 수명과 엮지 않는다. Select 필드(또는 Menu.Button)가 파괴돼도(화면 전환·상위 정리) 메뉴가 투명 스크림과 함께 5초가 지나도 남아 있고(probe.sel.luau 1번: count 1 유지), 스크림 클릭 전까지 화면 전체 클릭을 삼킨다. Tooltip은 같은 상황을 Destroying으로 처리한다(probe.tip.luau: 파괴 시 Count 0). 위치: Menu.luau open()의 Anchor 사용부, Select.luau:100-111. 제안: Menu.open이 anchor.Destroying에 handle.Close를 걸고 핸들 종료 때 끊기(Tooltip과 같은 형태).

3. [실측] 날짜 선택기의 키보드 Home/End는 줄 끝 날이 비활성이면 아무 일도 안 한다. MonthView.reach는 moveFocus를 반복해 선택 가능한 날을 찾는데, home/end는 두 번째 호출이 같은 날을 돌려주므로 `equals(nxt, cur)`에서 nil을 반환한다. IsDisabled로 주말을 막은 흔한 설정(Sunday-first)에서 수요일에 Home/End를 누르면 선택이 그대로(probe.keys.luau: Home → 14, End → 14; Left는 13으로 정상). 헤더 주석은 "skipping non-selectable dates by repeating the move"라고 하지만 home/end에는 성립하지 않는다. 위치: DatePicker/MonthView.luau reach() (약 142-155행). 제안: home/end는 반복 대신 그 줄 안에서 가장 가까운 선택 가능한 날(안쪽 방향)로 가게 한다. 처방이 동작 정의라 사용자 결정 여지.

4. [실측] 드래그 도중 Disabled가 켜져도 드래그가 끝까지 값을 쓴다. Interaction.drag은 시작할 때만 Disabled를 본다. Switch에서 끌고 있다가 Disabled를 true로 하고 놓으면 값이 바뀌고 OnChange가 불린다(probe.sw.luau: value true, OnChange 1). Behavior.OnEnded가 disabled를 다시 보지 않기 때문. 같은 구조의 SVArea·HueSlider는 [추정]으로 OnMoved/apply가 계속 setSV/setHue를 부른다. 위치: Switch/Behavior.luau:100-118, Interaction.luau drag의 hook/begin, ColorPicker/Material/SVArea.luau:70-90. 제안: drag 내부에서 Disabled가 켜지면 finish(true)로 취소(한 곳에서 닫힘).

5. [추정, 낮음~중간] 날짜 칸에서 Enter가 두 번 고르기가 될 수 있다. MonthView.onKey는 Return/KeypadEnter에서 OnPick을 부르고, 헤더 주석대로 processed를 보지 않는다. 엔진이 선택된 GuiButton(칸 TextButton)에 대해 Return에도 Activated를 내면(미확인) Chip의 Activated가 OnPick을 한 번 더 부른다. Docked는 OnChange 이중 호출, RangeDocked는 첫 Enter로 Start, 바로 이어 같은 날이 End가 되어 한 번에 하루짜리 범위가 확정된다. 이 킷이 "디바이스 미검증"이라고 적은 가정에 걸려 있으므로 실기기 확인 대상. 위치: MonthView.luau onKey Return 분기 + DatePicker/Chip.luau Activated.

6. [추정, 낮음] YearView의 연도 범위가 생성 시점의 View 연도 ±100으로 굳는다(Min/Max 없을 때). Value를 바깥에서 나중에 1900년으로 쓰면 Body의 Follow가 View를 그 달로 옮기지만 연도 격자에는 그 해가 없어서 "선택된 해" 칩이 없다. 달 화살표로 범위 밖으로 걸어가도 같다. 위치: DatePicker/YearView.luau:78-80. 문서(open end: ±100)와는 일치하는 동작이므로 결함이라기보다 한계 — 생일 선택(Min 없음)에서 눈에 띈다.

7. [추정, 낮음] ColorPicker Fields의 FocusLost는 typeField가 거부해도(예: 완전히 지운 칸이나 형식 오류 입력) remember()를 부른다(Fields.luau FocusLost). 색은 안 바뀌는데 현재 색이 Recent 목록 맨 앞에 들어간다(첫 항목이 이미 같으면 pushRecent가 거른다). HexField는 setHex가 true일 때만 remember하므로 두 곳이 어긋남. 제안: typeField의 반환값을 보고 remember.

8. [실측, 사소] Calendar.parseLocalized가 "October 05,2026"(쉼표 뒤 공백 없음)을 "unrecognized date format"으로 거절한다. 패턴이 `,?%s+`라 공백이 필수. ISO·한글·숫자 구분자형은 모두 정상(probe/p1.luau).

9. [추정, 사소] Checkbox 모션: 닫는 중간에 원래 보이던 모양으로 되돌리면(target == displayed인데 closing ≠ 0) 막대가 끝까지 닫혔다 다시 열리는 한 사이클을 돈다. 시각적으로만 낭비.

## 확인했지만 문제없던 것
- 순수 계산: Calendar 월말·윤년·addMonths 클램프(1월 31일+1달=2월 말, 윤일+1년=2월 28일)·MIN/MAX 가장자리 클램프·weekday 음수 ordinal·canGoToPrev/Next·FixedWeeks false 줄 수·today 극값. ColorModel: 8비트 왕복 전수(5간격 표본) 0건 불일치, 검정/회색에서 H·S 보존(fromHexPreservingHue), parseHex 3자리·대소문자·# 유무·공백·잘못된 글자, parseChannel 경계. Tokens/Color 라이트·다크 값은 M3 기준선과 일치하고 두 스킴의 키가 같다.
- 팝업 수명: Tooltip은 대상 파괴(지연 중·표시 중), Close() 뒤 재진입 모두 타이머/오버레이 항목 0. Menu의 키보드 연결은 패널 Destroying에서 끊김. 레이어 사망은 Overlay가 일괄 정리.
- 계약: Checkbox/Radio/Switch/Chip/Tabs/Select/ColorPicker의 OnChange는 사용자 조작 경로에서만 불린다(프로그램 Set·Sync 경로는 OnChange 없음). Select의 Options State는 열 때 읽음(문서대로).
- 프레임 구동: Progress/Loop는 파괴·비가시·미마운트에서 Heartbeat를 끊는다. Radio·Checkbox 스텝은 Effect 정리로 끊긴다(호스트 배열부에 묶임).
- 테마: Theme.Color/Raw는 전부 State이고 생성 때 :Get()으로 굳힌 색은 찾지 못함(grep). 오버라이드의 오타 역할은 조용히 무시(미세).
- M3 ↔ M2: Switch는 Behavior를 공유하고 M2는 그리기만 다르다. SliderTicks 경계(step 0/음수/100 초과)는 안전.

## 못 본 것
- Progress/Wavy.luau, Progress/Circular.luau의 기하 계산, ColorPicker/HueSlider·Elevation·Text·Icons·ControlLabel·Strings 상세, RangeDocked에서 Start>End를 바깥이 쓰는 경우의 표시(읽기로는 band는 정규화되고 원 두 개는 뒤바뀌는 정도), Tabs에서 선택된 탭이 목록에서 빠졌을 때의 Selected 정합(인디케이터만 숨고 Source는 낡은 키 유지).
- 엔진 동작에 기대는 항목(5번)은 실기기 몫.
