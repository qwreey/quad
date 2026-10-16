# 이름 탐색 2026-10-16 — 요소 props 배열 자리에 놓이는 값의 타입(지금 `<Class>Elem`, 새 표면 `X<Frame>`)

사용자 판단: 지금 `Elem`은 *"자기서술적이지 못했다"*, 배열 자리에 놓인다는 점이 드러나야 하고(예시 `ChildrenOf`·`ArrItem`), `Elem`이라는 단어는 값 쪽 생성자 꺼내기(`Elem "Frame"`)로 옮기고 싶다.
과제문 `prompt.md`를 sonnet(외부자, 채팅 보고 — 아래 요약)과 Gemini(`gemini.md`)에 맡겼다. 결정이 아니라 재료다.

**sonnet**: 1순위 `Entry<Frame>` — "배열의 한 항목", 자식으로 좁아지지 않음, 한 단어 명사로 `Props`·`Ref`·`Slot`과 같은 가족, `Elem`과 안 겹침(약점: 딕셔너리 항목으로도 읽힘).
`Content`는 Roblox `Content` 타입과 충돌해 탈락급, `Child`는 Modifier를 가리고 `Child<Frame>`이 "Frame이라는 자식"으로 방향이 뒤집힘, `Part`는 BasePart 충돌, `Applicable`은 형용사.
`ChildrenOf`는 방향은 맞지만 복수라 `{ ChildrenOf<GuiObject> }`가 이중 복수, `ArrItem`은 위치에 정직하지만 약어·메커니즘 노출(`ArrayEntry`가 합성어 대안).
덧붙임: X를 `Elem`으로 가져가면 `SlotElement<T>`의 `Element`와 단어가 겹친다 — `SlotEntry`로 맞추면 `Entry<Frame>`과 짝(의미가 완전히 같지는 않음).

**Gemini**: 1순위 `Content<C>` — 자식·수식자·마커를 "내용물"로 포용, `Props<C>`(바깥 설정) ↔ `Content<C>`(안쪽 내용물) 대칭. 대안 `ArrayItem<C>`(위치 사실성, 약어 대신 완어), `Child<C>`(직관성).
`PropsItem`·`Node`·`DeclItem`은 하위. `ChildrenOf`는 이중 복수, `ArrItem`은 도메인 누수·약어. `Elem`/`Element` 어근은 타입 쪽에서 완전히 뺄 것.

**메인 검증**: Roblox 정의(`scripts/roblox-defs/globalTypes.d.luau`)에 `declare extern type Content`(7845행)와 전역 `declare Content`(19014행)가 실제로 있다 — Gemini는
`ContentText` 속성만 보고 충돌을 작게 봤다. `Entry`·`Child`·`Node`·`Item` 이름의 선언은 없다. 생성 `FrameElem` 정의(`quad-roblox/src/Declaration/init.luau` 2448행)와
`SlotElement<T>`(quad-types)의 존재는 사실.
