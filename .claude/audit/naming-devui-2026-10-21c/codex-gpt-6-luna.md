1. **다이얼로그 열기**
   - **추천 순위:** `OpenDialog` > `ShowDialog` > `OpenModal` > `Dialog` > `Modal`
   - `OpenMenu`처럼 호출 즉시 열고 핸들을 반환하므로 `OpenDialog`가 동작을 가장 잘 드러냅니다. `Dialog`는 위젯을 선언하는 함수처럼 보일 수 있습니다.
   - **오해 소지:** `Modal`은 이름만으로 항상 전체 화면을 막는 다이얼로그처럼 읽혀, 차단 범위를 따로 지정하는 API와 충돌할 수 있습니다.

2. **차단 범위**
   - **추천 조합:** `Modality = "None" | "Window" | "Global"` > `Blocks` + 같은 값 > `Modal` + 같은 값
   - `Modality`는 다이얼로그가 입력을 얼마나 차단하는지 표현하고, `Blocks`도 의미를 비교적 바로 전달합니다. `Scope`는 기존 `MenuScope`와 겹치고, `Dim`은 입력 차단까지 뜻하지 않습니다.
   - 값은 `"None" | "Window" | "Global"`을 추천합니다. `"Screen"`과 `"All"`은 각각 차단 대상을 화면이나 요소 전체로 오해할 수 있고, `"Parent" | "App"`은 실제 대상인 창과 앱 전체를 덜 직접적으로 표현합니다.
   - `Modal`은 다이얼로그 이름으로도 후보에 있어, prop 이름으로 쓰면 혼동을 더합니다.

3. **확인 헬퍼**
   - **함수명:** `ConfirmDialog` > `AskConfirm` > `OpenConfirm` > `Confirm`
   - `ConfirmDialog`는 다이얼로그를 띄워 확인을 받는 헬퍼임을 분명히 합니다. `Confirm`은 즉시 `true/false`를 반환하는 함수처럼 오해될 수 있습니다.
   - **버튼 라벨:** `ConfirmLabel` / `CancelLabel` > `OkText` / `CancelText` > `ConfirmText` / `CancelText`. `Label`이 버튼의 표시 문구를 잘 나타냅니다.
   - **콜백:** `OnResult`를 추천합니다. 결과가 `boolean`이라는 점을 드러냅니다. `OnAnswer`는 다소 모호하고, `OnConfirm` + `OnCancel`은 결과별 콜백을 둘로 나누어 사용 방식이 달라집니다.