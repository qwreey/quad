# devplorer 상향 보고서 2차의 quad 쪽 판정 — 2026-10-21

원문은 devplorer 레포의 `.claude/feedback/quad-upstream-2026-10-21.md`(U21~U28)와 그 문서가 묶은 `devui-upstream-candidates-2026-10-21.md`(직접 구현 전수 목록, 1차 보고서 D·U 번호 재사용)다. 둘 다 레포 밖(사용자 프로젝트, 읽기 전용)이라 경로만 적는다. 1차 판정은 `feedback/devplorer-2026-10-20.md`.

**[2026-10-21 기준] 판정 요약.** 결함으로 메인이 바로 볼 수 있는 것은 둘(U28 메뉴 안 구분선, 후보 목록 4번 Combo `MaxHeight`)이고, 나머지는 새 공개 이름·동작이라 사용자 결정이다. 1차 판정의 묶음 다(팝업 — 사용자가 "devplorer가 다듬는 중이라 보류"로 둠)가 후보 목록에서 "우선순위 높음"으로 올라와, 보류를 풀지가 이번 판정의 중심 질문이다.

## 결함 — 메인 자율

- **U28 메뉴 안 `Separator`가 판을 화면 너비로 늘림.** 소스로 확인: 메뉴 판(`Menu.luau` `panel`)은 `AutomaticSize = XY`, `Separator`(`Layout.luau`)는 `Size = UDim2.new(1, 0, 0, 1)` — 자동 크기 부모 안의 비율 자식이라 엔진이 판을 부모의 부모 너비로 키운다. 메뉴 행은 이미 `PopupParts.row`의 `Width = "Stretch"`(크기 0 + `UIFlexItem` `ItemLineAlignment = Stretch`)로 이 함정을 피한다. 고치는 길이 둘이라 사용자에게 묻는다: `Separator` 자체를 Stretch 방식으로 바꾸기(목록 레이아웃이 없는 부모에서는 너비 0이 되는 동작 변화), 또는 메뉴 전용 구분선(1차 U8, 새 이름).
- **후보 4번(1차 U20) Combo 목록 `MaxHeight`가 Studio에서 지켜지지 않음.** devplorer 실측. 원인 조사부터(메인, quad-test Studio).

## 사용자 결정

- **U21 창 메뉴바 자리.** 제목줄 바로 아래·창 여백 밖에 가로 꽉 차게 그리고, 높이를 창이 내용 영역과 `AvailableSize`에서 뺀다. 메인 의견: 받는다 — 소비자가 높이 계산을 들고 있다가 한 번 어긋나 모든 창이 같이 틀렸다(실측). 표면 루트 안에서 Content 위에 두면 탭 묶음에서도 고른 창의 것이 보이고, `AvailableSize`는 Content의 보이는 크기라 저절로 맞는다. 새 prop 이름(가칭 `MenuBar`)이 결정 거리.
- **U25·U26·U27 메뉴의 작은 결핍.** U25 `MenuItem`·`MenuToggle`의 `Hooks`(Button과 같은 이름 — 툴팁용), U26 토글이 메뉴를 닫지 않는 옵션(가칭 `KeepOpen`), U27 열린 메뉴 사이 호버 이동(지금은 의도적으로 안 함, `Menu.luau` 머리). 메인 의견: 셋 다 받는다. U25는 기존 규약 재사용이라 가장 싸다.
- **U22 이미지 단추와 아이콘 표.** Button의 아이콘 자리(아이콘만 / 아이콘 + 글, 아이콘은 안쪽 ImageLabel로 둘레 여백 — devplorer 실측의 함정). 아이콘 표는 `research/icon-pack-plan.md`(사용자 결정 대기)와 같은 질문이라 거기서 같이 정한다.
- **U23 분할 단추·U24 메뉴 단추.** 둘 다 임의 좌표에서 여는 메뉴(1차 U7, 후보 2번 `ContextMenu`) 위에 선다. 그래서 묶음 다(팝업 몸통 공개 → 화면 안 고정 옵션 → 임의 좌표 메뉴)의 보류를 먼저 풀어야 한다.
- **묶음 다의 보류 해제.** 후보 목록 1~3번(팝업 몸통 복사 다섯, ContextMenu, PopupShield — 마지막은 부품이 아니라 Overlay 수정)이 "높음"이다. 메인 의견: 풀 때가 됐다 — U23·U24가 그 위에 서고, 복사가 다섯으로 늘었다.

## 참고

- 보고서 4절(칩 폭과 자동 크기, `TextBounds` 순환)은 요청이 아니라 함정 기록 — devui가 칩을 만들 때 볼 것. 이 판정 세션에 메인이 잘린 제목 툴팁을 `TextFits`로 판정했다(Studio 실측: 잘리면 false, 패딩 반영) — 글 폭을 재는 다른 길.
- 후보 목록의 "그 사이 devui가 이미 가져간 것"(VirtualRows, NoPages/Toggled 등)은 devplorer 쪽 걷어내기 몫.
