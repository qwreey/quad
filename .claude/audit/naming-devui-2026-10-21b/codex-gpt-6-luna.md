1. **Anchor rectangle — `AnchorRect`**  
   순위: `AnchorRect` > `AttachTo` > `Origin` > `Attach` > `Around` > `Avoid`  
   기존 `Anchor`가 AnchorPoint이므로 `AnchorRect`가 구분하기 쉽고, 화면 좌표의 사각형이라는 점도 드러납니다. `Avoid`는 팝업이 그 사각형을 피한다는 뜻으로 오해될 수 있습니다.

2. **팝업 본문 — `PopupPanel`**  
   순위: `PopupPanel` > `PopupFrame` > `PopupBody` > `Panel` > `Popup`  
   패널 형태의 시각 요소라는 뜻이 자연스럽고, 다른 종류의 팝업 전체를 가리키는 `Popup`보다 범위가 분명합니다.

3. **지점에서 메뉴 열기 — `OpenMenu`**  
   순위: `OpenMenu` > `Menu.open` > `ShowMenu` > `ContextMenu` > `PopupMenu`  
   명령형 함수이고 핸들을 반환한다는 사용법에 잘 맞습니다. `ContextMenu`는 보통 우클릭 전용 위젯으로 읽힐 수 있고, `PopupMenu`는 메뉴 위젯 타입처럼 보일 수 있습니다.

4. **메뉴가 달린 버튼**  
   - 이름 순위: `MenuButton` > `SplitButton` > `DropdownButton` > `ComboButton`  
   - 팩토리 prop 순위: `Children` > `Menu` > `MenuItems` > `Items`  
   `MenuButton`은 두 동작 모드를 모두 포괄합니다. `SplitButton`은 `OnClick`이 있을 때만 정확하고, `DropdownButton`은 전체 버튼이 메뉴를 여는 모드와 맞지 않을 수 있습니다. 팩토리가 임의의 메뉴 구성을 만들므로 `Items`보다 `Children`이 기존 API와도 일관됩니다.

5. **메뉴 닫힘 유지 — `KeepOpen`**  
   순위: `KeepOpen` > `StayOpen` > `DontClose` > `Sticky` > `NoClose`  
   클릭 후에도 메뉴를 열어 둔다는 의미가 간결합니다. `NoClose`는 Window의 `NoClose`처럼 닫기 기능 자체가 없다는 뜻으로 오해될 수 있습니다.