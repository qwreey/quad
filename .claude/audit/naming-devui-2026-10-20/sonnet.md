## devui 이름 검토 (sonnet, 2026-10-20 — 서브에이전트 최종 보고 그대로)

**1. Button on-state 프롭**
- verdict: change
- best: `Toggled`
  - 토글 버튼(필터 칩 등)의 "켜짐" 상태를 가장 직접 말해 주고, Roblox에 같은 이름이 없다.
- 대안 1: `On`
  - 짧고 명확하다. 다만 `On`은 `OnClick` 같은 이벤트 접두사와 시각적으로 섞이기 쉽다. (추정)
- 대안 2: `Checked`
  - `MenuToggle.Checked`와 일관된다. 하지만 버튼에서 "체크됨"은 체크박스를 떠올리게 한다. 그리고 `Checked`는 읽기 전용 `State<boolean>`(controlled)을 뜻하는데, 버튼에서도 같은 의미로 이해될지 불분명하다.
- 혼동 위험: `Active`와 `Selected`는 high, `Checked`는 medium, `Toggled`는 low.
  - `Active`는 `GuiObject.Active`(입력을 막는지 여부)와 충돌한다. 게다가 `ButtonActive` 색(눌리는 순간의 색)과도 의미가 겹친다.
  - `Selected`는 `GuiButton.Selected`(게임패드 선택)와 충돌한다.
  - `Pressed`는 누르는 순간과 구분되지 않는다.
  - `Highlighted`는 hover와 헷갈린다.
- 참고: "켜짐" 색 토큰이 `ButtonActive`인데 프롭 이름은 `Toggled`이면 이름이 어긋난다. 다만 프롭은 Roblox 충돌을 피하는 쪽이 더 중요하다고 본다. (추정)

**2. TabBar 페이지 없음 플래그**
- verdict: keep
- best: `NoPages`
  - Window의 `No*` 플래그 관례와 맞는다.
- 대안 1: `BarOnly`
  - 긍정형이라 의도가 바로 읽힌다. 하지만 `No*` 관례에서 벗어난다.
- 대안 2: `HeadersOnly`
  - 설명적이지만 길다.
- 혼동 위험: low
  - `Window.NoTitleBar` 등과 같은 계열이라 학습 비용이 거의 없다. 다만 `No*`가 "기능을 끈다"는 뜻이어서 "페이지 컨테이너를 만들지 않는다"는 구조 차이를 충분히 전하는지는 약간 의문이다. (추정)

**3. 탭 모서리 반경 토큰**
- verdict: keep
- best: `TabRounding`
  - ImGui에 같은 이름의 style var가 있고, `FrameRounding`, `PopupRounding`과 패턴이 같다.
- 대안 1: `TabButtonRounding`
  - 더 정확하지만 길다. 위 패턴에서 벗어날 이유가 없다.
- 대안 2: 없음
- 혼동 위험: low
  - Roblox와 겹치는 이름이 없고, 기존 색 토큰 `Tab`, `TabActive`와도 접두사가 일관된다.

**4. 드래그 중 매 프레임 콜백**
- verdict: change
- best: `OnFrame`
  - 이 키트의 콜백은 `OnBegin`, `OnMove`, `OnEnd` 순서로 쓰는 이벤트 계열이다. `OnFrame`은 "프레임마다"라는 뜻이 가장 직관적이다.
- 대안 1: `OnTick`
  - 짧고 일반적이다. 하지만 Roblox에서 `tick()`은 deprecated된 시간 함수라서 이름이 약간 혼란스럽다. (추정)
- 대안 2: `WhileDragging`
  - 호출 조건을 정확히 말해 준다. 하지만 `On*` 계열이 아니어서 이름 규칙에서 벗어난다.
- 혼동 위험:
  - `OnTick`은 medium. `tick()`과 겹치고, "고정 간격"으로 오해될 수 있다.
  - `OnFrame`은 low.
  - `OnStep`은 `RunService.Stepped`와, `OnHeartbeat`는 `RunService.Heartbeat`와 엮여 medium이다. 특히 `OnHeartbeat`는 실제로는 Heartbeat에 묶였다고 약속하는 것처럼 읽힌다.
  - `OnHold`는 "누르고 있음"으로 읽혀 포인터가 안 움직일 때만 호출한다는 오해를 준다.
- 참고: 시그니처 `(dt, x, y)`에 `dt`가 들어 있어서 프레임 단위라는 점은 이름과 잘 맞는다.

**5a. `InputText.Focused` (양방향 Source)**
- verdict: change (충돌 자체보다 방향 혼재가 문제)
- best: `Focused` 유지 또는 `Focus`로 변경
  - 양방향이라는 점이 핵심이므로 `Window.Focused`(출력 전용)와 이름이 같은데 의미가 다르다는 것이 위험하다.
- 대안 1: 둘 다 `Focused`로 통일하고 문서에서 방향을 명시한다. `Source<boolean>`이므로 양방향이 기본 가정이다. (추정)
- 대안 2: `Window` 쪽을 `IsFocused`나 `FocusedOut` 같은 이름으로 바꿔 출력 전용임을 드러낸다.
- 혼동 위험: medium
  - `Window.Focused`(출력 전용)와 같은 이름이라 방향이 헷갈린다.
  - Roblox `TextBox.Focused`는 이벤트인데 여기서는 값이라 혼동될 수 있다. 다만 프롭과 이벤트는 쓰는 위치가 달라 영향은 작다.
  - `Source`는 쓰기 가능이라 양방향 쪽이 오히려 자연스럽다.

**5b. `Window.ContentSize` (출력)**
- verdict: keep
- best: `ContentSize`
  - 이름이 "내용이 쓸 수 있는 크기"를 잘 말해 준다.
- 대안 1: `ContentArea`
  - 크기 외에 영역이라는 뉘앙스가 있다. 하지만 값이 `Vector2`이므로 `Size`가 더 정확하다.
- 대안 2: `InnerSize`
  - 간결하다. 그러나 padding을 뺀 크기인지 모호하다.
- 혼동 위험: low
  - Roblox의 `AbsoluteSize`/`CanvasSize`와는 다르지만, `Content`가 ImGui의 content region과 대응해 익숙하다.
  - 다만 `Source`가 출력 전용이라는 점은 문서에서 명시해야 한다. (추정)

**5c. `VirtualRows`와 프롭들**
- verdict: keep (프롭은 일부 확인 필요)
- best: `VirtualRows`
  - 가상화된 행이라는 의미가 직접 드러난다.
- 대안 1: `VirtualList`
  - 일반적인 용어다. 하지만 "고정 높이 행"이라는 제약이 이름에서 빠진다.
- 대안 2: `RowList`
  - 단순하지만 가상화라는 핵심 정보가 없다.
- 프롭별 메모:
  - `Count`, `Row`, `RowHeight`, `Overscan`는 모두 업계 관용어라 괜찮다.
  - `Row: (index: State<number?>) -> Instance`에서 `State<number?>`는 풀링으로 슬롯이 재사용된다는 뜻이다. 이건 이름보다 문서에서 설명해야 할 부분이다.
  - `ScrollTo: Source<number?>`는 "값을 쓰면 스크롤한다"는 트리거형 Source다. 쓰는 쪽이 값을 직접 정하므로 `ScrollToRow`처럼 인덱스임을 드러내는 편이 낫다. (추정)
- 혼동 위험: low
  - Roblox에 같은 이름이 없다. `ScrollTo`는 `ScrollingFrame`의 동작과 겹치는 이름은 아니다.

**전체 일관성 (최대 세 줄)**
- 불리언 상태 이름이 `Checked`(MenuToggle), `Toggled`/`On`(Button), `Focused`(양방향/출력 전용)로 갈라질 수 있다. "입력 상태인지 출력인지"를 이름이 아니라 타입(`State` vs `Source`)과 문서로 구분하는 규칙을 하나 정해 두는 것이 낫다. (추정)
- 콜백 접두사 `On*`와 `No*` 플래그는 일관되지만, `OnTick`이 선택되면 `Tick`/`Frame` 같은 시간 어휘가 키트 안에서 하나로 통일돼야 한다.
- `Checked`를 Button에 쓰면 "컨트롤 가능한 읽기 전용 State" 의미가 퍼질 위험이 있다. `Toggled`로 가면 이런 확산은 막힌다.
