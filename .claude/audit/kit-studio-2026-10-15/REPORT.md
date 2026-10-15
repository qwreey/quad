# 킷 Studio 실측 2026-10-15 (`quad-test`, PlaceId 105962699098904, 커밋 전 워킹트리 싱크)

킷 빌더(opus)가 Studio MCP로 직접 쟀다(보고 본문을 메인이 저장 — 하네스가 서브에이전트의 .md 쓰기를 막음). Play(Client)에서 `ReplicatedStorage`의 킷을 require해
실험용 ScreenGui(`ZIndexBehavior = Sibling`)에 직접 올렸다. Workspace `SignalBehavior`는 Immediate(사용자 설정 그대로)이고, 입력 좌표는 `AbsolutePosition` 공간과 같았다.
실험 인스턴스는 지웠고 Edit 모드로 돌려놓았다. 배경은 `audit/kit-studio-2026-10-13/REPORT.md` 13번, 결정은 `research/consumer-kits-plan.md` 5절.

## 1. 창을 닫은 뒤 호버 — 사용자 말이 맞다 (고치기 전 코드)

창 안 버튼(호버 연결 + 1.5초 툴팁)에 마우스를 올린 채 `Open = false`로 하면 `MouseLeave`가 없고 호버 색도 그대로다. 마우스를 1~2px 움직이자 `MouseLeave`가 오고 호버 색이 풀렸다.
마우스를 그 자리에 둔 채 다시 열면 `MouseEnter`가 없고 휴지 색 그대로였다가, 1px 움직이자 왔다. 그래서 호버는 손대지 않았다.

남은 두 가지는 재현됐다. (a) 툴팁 대기 중에 창을 닫고 마우스를 가만히 두면 1.5초 뒤 닫힌 창의 툴팁이 뜬다(`a4-1-tooltip-of-closed-window-before.jpg`). 이 툴팁은 마우스를 움직이면 닫힌다.
(b) 열린 콤보 목록은 창을 닫아도 남는다(`a4-2-combo-list-after-window-close-before.jpg`).

## 2. 뒤 창 안 위젯을 누르면 창이 앞으로 (고친 뒤)

창 A와 B를 겹쳐 놓고(각각 Button·Checkbox·Combo·InputText·Selectable) 실험했다. 전역 `InputBegan`의 `Position`은 누른 자리의 AbsolutePosition과 같았다(`gameProcessedEvent = true`).
뒤 창의 Button, Selectable, TextBox(포커스도 잡힘), Combo 상자를 누를 때마다 그 창이 서열 2가 되고 제목줄이 활성색으로 바뀌었다(`a1-1-press-combo-in-back-window-raises-it.jpg`).
콤보 목록이 열린 채 다른 창 위를 누르면 목록만 닫히고 포커스는 그대로였다.

새 발견(고치지 않음): 앞 창의 빈 내용 영역을 누르면 그 아래 뒤 창의 GuiButton이 눌린다. B가 앞일 때 B의 빈 칸(A의 Selectable 위)을 누르자 A의 Selectable이 선택됐다.
B는 앞에 그대로 있었으니 관리자 판정은 맞다. 앞 창 내용 ScrollingFrame의 `Active = true`가 GuiButton 누름을 막지 못한다(`a1-2-clickthrough-top-window-empty-area-selects-back-widget.jpg`).

## 3. 포커스 승계

B(포커스, 앞)를 `Open = false`로 닫자 A가 서열 2가 되고 활성색이 됐다. B를 다시 열면 B는 A 아래로 오고 포커스는 A에 남는다(기존 규칙: 새로 열린 창은 포커스를 빼앗지 않음).

## 4. 화면 밖으로 잃지 않기

ScreenGui 1447 × 685, 창 320 × 300, FrameHeight 19 조건이다. 위로 끌면 `Position.Y`가 0에서 멈췄다. 오른쪽 아래 끝으로 끌면 (1295, 666)이 됐다 — 666 = 685 − 19이니
타이틀바 전체가 안에 남는다(`a3-1-drag-to-bottom-right-title-bar-stays.jpg`).

Frame 컨테이너(900 × 600) 안의 창 C(250 × 150, 위치 600, 350)로 컨테이너 크기 변화를 봤다: 1000 × 650으로 키움 → 위치 그대로; 500 × 300 → (481, 281); 500 × 250 → (481, 231);
이미 안에 있던 창(50, 50)은 줄여도 그대로; 프로그램이 준 (−500, 1000)은 그 자리에서는 그대로였다가 다음 축소(가로만 440)에서 (−231, 231)로 들어왔다(`a3-2-container-shrunk-window-brought-in.jpg`).

## 5. 창 닫기 정리 (고친 뒤)

1절과 같은 절차로 툴팁 대기 중 창을 닫고 1.8초를 기다렸다 — 툴팁은 뜨지 않았다(`a4-3-after-fix-no-tooltip-for-closed-window.jpg`). 콤보 목록을 연 채 창을 닫으면 목록이 함께 닫혔다
(층의 팝업 1 → 0). 킷 에러는 없었다.

## 6. material Menu — 내용에 맞춘 폭

**원형 인스턴스로 본 엔진 동작.** `AutomaticSize` X 패널·목록·행(`AutomaticSize` X + `UIFlexItem` Stretch)이면 행들이 가장 넓은 행에 맞춰 늘어난다. `UISizeConstraint.MinSize` 112는
패널을 키우지만 행은 그 폭까지 늘지 않는다(행 105, 패널 112) — 목록에 0 높이·112 폭 스페이서 Frame을 넣자 행이 112를 채웠다. 스크롤 목록(`ScrollingFrame` `AutomaticSize` X)도 같다.
붙인 직후 `AbsoluteSize`를 읽으면 레이아웃이 그 자리에서 계산되고 신호도 같은 프레임에 온다(`b0-prototype-autowidth-before-spacer.jpg`).

**발견해서 고친 문제 둘.** (1) 구분선의 가로 scale 1이 자동 폭 목록 안에서 되먹임해 패널이 레이어 폭의 절반(723.5)이 됐다 — 구분선도 offset 0 + Stretch로.
(2) UIScale 아래 글자는 정수 글자 크기로 그려진다 — 14px 라벨의 abs/scale이 배율 1.0에서 288, 0.9에서 282.2, 0.95에서 290.5, 0.976에서 282.8, 2.5에서 284. 그래서 여는 애니메이션 동안
폭이 배율에 비례하지 않고, 그 값을 따라 위치를 다시 놓다가 "Maximum event re-entrancy depth exceeded"가 한 번 열 때 7~30건 났다. 이제 읽기는 패널 배율이 1일 때만, 열 때는 같은 단계에서
배율을 1로 놓고 읽은 뒤 되돌리며, 2px 미만 변화는 무시한다. 고친 뒤 네 경우 × 3회 에러 0, 열 때 정한 위치가 애니메이션 뒤에도 그대로.

**결과.** 갤러리 Actions: "Duplicate" 전체와 "Ctrl+D"(사이 12), 패널 132(`b8-final-gallery-actions-menu.jpg`). 짧은 라벨: 112(`b2-gallery-short-labels-min-112.jpg`).
긴 라벨과 "Ctrl+Shift+L"(68px → 오른쪽 여백 96 = 16 + 68 + 12), 오른쪽 끝 앵커에서 레이어 안으로 클램프(1211 + 236 = 1447)(`b7-final-long-label-trailing-and-right-clamp.jpg`).
30항목 스크롤 목록: 가장 넓은 항목 324에 맞고 행 전부 324, 막대는 행 위에 겹침(`b4-scrolling-list-fits-widest.jpg`). 화면 아래 앵커: 위로 뒤집힘(`b5-flipped-and-right-clamped.jpg`).
Select: 필드 폭 210 유지, 긴 옵션은 "…"(`b6-select-keeps-field-width.jpg`). 중간 빌드 화면: `b1-…-fixed-64-reserve-build`(뒤 글자 64 고정), `b3-long-label-before-trailing-fix`
(긴 뒤 글자가 라벨에 겹침), `b3b-…-grow-only-build`.

## 못 본 것

Deferred 신호에서의 메뉴 폭(이 플레이스는 Immediate), UI Labs 스토리 모드에서의 창 누름 적중(리스너 좌표와 AbsolutePosition 공간이 같은지), 터치, 실제 뷰포트 축소(Frame 컨테이너로 대신 확인).

## 7. 누름 받이와 다시 열면 앞으로 (같은 날, sonnet + Studio — 사용자 결정 뒤 구현분)

창 A(SelectableOption 12) 위에 창 B를 겹치고 B의 빈 내용 영역(아래에 A의 5번 행)을 누르자 A의 선택 값은 그대로(""), B가 앞에 남음(`c-1-1-…`); B를 닫고 같은 자리를 누르면 A5가 선택됨(대조 `c-1-2-…`).
`ClickSink`가 다른 것을 막지 않음: 타이틀바 끌기 델타 (+200, +100) 정확, 내용이 긴 창에서 휠 세 번에 `CanvasPosition.Y` 0 → 191(끝), 창 안 버튼 클릭 2회, 리사이즈 그립 (+60, +40)(`c-2-1-…`, `c-2-2-…`).
다시 열기: A가 포커스·B 닫힘에서 `openB:Set(true)` → B ZIndex 2 > A 1, `Focused` = B, B 타이틀바 활성색(`c-3-1-…`).
관찰(미확정): B 위를 누르는 동안 반투명 B 아래로 A의 5번 행 일부가 선택색 비슷한 파랑으로 보였다 — 값은 안 바뀜. 아래 창 행의 호버·눌림 색이 앞 창 아래로 새는지는 구분하지 못함.
