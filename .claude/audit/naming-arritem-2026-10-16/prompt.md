# 이름 탐색 — "요소 props 테이블의 배열 자리에 놓일 수 있는 것" 타입의 이름

결정을 내리는 게 아니라 후보와 근거를 내는 과제다. 결정은 라이브러리 저자(사용자)가 한다.

## 배경

quad는 Roblox Luau용 선언형 UI 라이브러리다(Fusion·Vide 계열; v2 3.x 안정화 구간이라 BREAKING 허용). 요소는 props 테이블 하나로 만든다:

```luau
local Frame = Elem "Frame"            -- (값 쪽 생성자 꺼내기 — 저자가 이 자리에 `Elem`을 쓰고 싶어 한다)
local card = Frame {
	Size = UDim2.fromScale(1, 0),      -- 문자 키 자리 = 프로퍼티·이벤트
	-- 아래는 전부 "배열 자리"(숫자 키)에 놓이는 값
	TextLabel { Text = "hi" },          -- 자식 Instance
	q.Source(maybeChild),               -- 자식을 쥔 State(nil이면 자식 없음)
	hoverModifier,                      -- 이 클래스(또는 조상 클래스)의 Modifier
	q.Spread "GuiObject" { … },        -- 상위 클래스 공통 속성 묶음 마커
	q.OnChange("Visible", fn),          -- 프로퍼티 변화 디스크립터
	q.OnEvent "MouseEnter" (fn),        -- 이벤트 디스크립터
	ref,                                -- Ref 마커(만들어진 인스턴스를 받아 갈 자리)
}
```

지금은 클래스마다 생성된 타입 `FrameElem`, `TextLabelElem`, … 이 "Frame의 배열 자리에 놓일 수 있는 값 전체의 유니언"이다(공개 재수출됨).
새 표면에서는 이것이 클래스 타입을 받는 제네릭 하나 `X<Frame>`으로 접힌다. 사용자는 이 타입을 주석에 쓴다 — 예: 컴포넌트가 "Frame에 넣을 것들"을 돌려주거나 받을 때
`local function Badge(): X<Frame>`, `function(children: { X<GuiObject> })`.

저자 판단: 지금 이름 `Elem`은 *"자기서술적이지 못했다"* — **배열 자리에 놓인다는 점이 드러나는 이름**이어야 한다(저자 예시 `ChildrenOf`, `ArrItem`). 그리고 `Elem`이라는 단어는
값 쪽 생성자 꺼내기(`Elem "Frame"`)로 옮기고 싶어 한다 — 그러니 후보는 `Elem`/`Element`와 혼동되지 않아야 한다.

이웃 타입 이름(같은 라이브러리, 같은 가족으로 읽혀야 함): `Props<Frame>`(props 테이블 전체), `Modifier<Frame>`, `SpreadMarker<Frame>`, `Into<Frame>`, `Ref<T>`, `Slot<T>`,
`SlotElement<T>`(Slot에 넣을 원소 — `T | State<T?> | 하위 Slot`), `State<T>`, `Source<T>`. 주의: 배열 자리의 값은 **자식만이 아니다**(Modifier·디스크립터·마커도 놓인다) —
`Children`류는 그 점에서 넓거나 좁게 읽힐 수 있다.

## 낼 것

1. 후보 4~7개, 각각: 장점, 약점(오독·이웃 이름과의 충돌·"자식만"으로 좁게 읽히는지), `X<Frame>`이 주석 자리에서 어떻게 읽히는지 예 두 줄. 1순위 하나.
2. 저자 예시 `ChildrenOf`·`ArrItem`에 대한 평가.
3. `Props<Frame>`·`SpreadMarker<Frame>`·`SlotElement<T>`와 나란히 놓았을 때 가족으로 가장 일관된 선택.

평문 한국어로, 마지막 메시지 하나에 전부.
