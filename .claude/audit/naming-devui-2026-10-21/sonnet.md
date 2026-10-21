(sonnet 서브에이전트 답 — 메인이 받은 원문 요지 그대로)

1. 슬롯: `Header` > `TopBar` > `Toolbar` > `MenuBar` > `HeaderBar` > `Bar`. `MenuBar`는 위젯 이름과 같아 `Window({ MenuBar = Devui.MenuBar(...) })`가 중복처럼 읽히고 메뉴바만 받는 인상 — 툴바 줄도 넣는 쓰임과 어긋남. `Header`는 위치 이름이라 무엇을 넣어도 어색하지 않음(단 "제목줄이 헤더 아닌가" 혼동 조금). 위젯은 `Devui.MenuBar` 그대로 범용으로 — `WindowMenuBar`는 창 밖에서 못 쓰는 위젯처럼 보임, ImGui·Iris 모두 `MenuBar`. 문서에 "Window의 `Header` 슬롯에 넣도록 설계됨" 한 줄.
2. Button 이미지: `Icon` > `Image` > `IconImage`. `Style.Icons`와 같은 어휘, Window `Icon`과 같은 이름이지만 둘 다 "이 위젯을 나타내는 작은 이미지 id"라 호환되는 뜻. `Image`는 큰 그림처럼 읽힘, `IconImage`는 군더더기.
