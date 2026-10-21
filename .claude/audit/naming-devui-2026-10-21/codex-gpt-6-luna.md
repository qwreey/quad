### 1. Window의 메뉴 바 슬롯

**선택: `MenuBar`**

순위: `MenuBar` > `Toolbar` > `TopBar` > `HeaderBar` > `Header` > `Bar`

`MenuBar`는 이미 있는 위젯을 받는 슬롯이라 사용법이 자연스럽고, 창 상단의 메뉴 영역이라는 뜻도 분명합니다. 다른 요소도 받을 수 있다는 점은 타입과 문서에서 밝히면 됩니다. `Toolbar`는 아이콘 버튼 줄에는 잘 맞지만 File/Edit 같은 메뉴를 담는 슬롯이라는 점이 덜 드러납니다.

위젯은 `Devui.MenuBar`로 유지하세요. 어디든 배치할 수 있는 일반 위젯으로 두는 편이 유용하며, 이름을 `WindowMenuBar`로 바꾸면 창 전용이라는 인상을 줍니다.

### 2. Button 이미지

**선택: `IconImage`**

순위: `IconImage` > `Image` > `Icon`

`Icon`은 버튼 안의 이미지라는 점은 간결하게 전달하지만, `Window.Icon`과 역할이 달라 혼동될 수 있습니다. `IconImage`는 조금 길어도 그 구분을 분명히 합니다. `Image`는 범용적이지만 아이콘 용도라는 점이 덜 명확합니다.