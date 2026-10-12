# finder-kit2 (값을 다루는 부품) 보고

## 발견 (심각도 순)

1. [실측] Step이 범위를 나누지 않으면 Max에 영원히 닿지 못한다. Min=0, Max=10, Step=3인 Slider에서 포인터를 맨 오른쪽(f=1.0)에 눌러도 값은 9, End 키(target = Max)도 snap을 거쳐 9다. 그런데 오른쪽 끝에는 정지점(stop dot)이 Max 위치에 그려지고, 눈금은 0·3·6만 그려진다(실제로 닿는 9의 눈금은 SkipLast가 "마지막 눈금 = 정지점"이라 가정하고 건너뜀). 눈금 개수는 `floor(range/step)`인데 SkipLast/SkipFirst는 i == count가 Max라고 가정한다. Slider/Behavior.luau:203-212(snapper), Slider/Track.luau:410-423(ticks), 같은 가정이 Range·Centered에도 있다. 제안: Behavior config에서 (Max-Min)이 Step의 정수배가 아니면 MDC처럼 에러를 던지거나(사용자 결정), 최소한 doc에 "Max는 Step의 배수여야 한다"를 적고 ticks의 Skip 조건을 `i*step == range`로 바꾼다.

2. [실측] 기본 Format이 "0."/"1."을 만든다. 값이 0.004나 1.001처럼 정수는 아닌데 소수 둘째 자리까지 0이면 `%.2f` → "0.00" → 끝의 0 제거 `0+$`가 "0."를 남긴다(-0.001은 "-0."). Luau로 직접 돌려 `0. 1. 0.5 -0. 0.3` 확인. Slider/Behavior.luau:149-156(defaultFormat), M3·M2·Range 라벨 전부가 이를 씀. 제안: 정규식 하나로 `%.?0*$`처럼 점까지 지우거나, 반올림 뒤 `v == math.floor(v)`를 다시 검사.

3. [실측] 끌기 도중 `Disabled`가 true가 되어도 끌기가 계속 값을 쓰고 OnChange/OnChangeEnd를 부른다. Interaction.drag의 Disabled는 시작 시점(Interaction.luau:274)에서만 검사하고, commit(Slider/Behavior.luau:305, 387)에는 검사가 없다. 프로브: 누른 뒤 Disabled:Set(true) → 이동하자 value가 0.75로 바뀜(키 쪽은 `c.disabled:Get()`을 검사하므로 비대칭). 제안: commit 첫 줄에 `if c.disabled:Get() then return false end`(입구 한 줄 검사 — 설계 원칙 보정 항목의 비용 기준 충족), 또는 Disabled 전환 시 drag:Cancel().

4. [추정] Dialog 높이 부족(알려진 건)에 대한 코드 읽기 근거. (가) 모자란 값이 정확히 단추 줄(8 패딩+40=48)이고 카드가 CanvasGroup이라 자식을 잘라 낸다 — 즉 "본문이 덜 커진" 것이 아니라 Content의 자동 크기가 맨 끝 자식(Actions)을 빼고 잡힌 모양과 일치한다. 본문 높이가 한 프레임 낡았다면 모자란 양은 본문 변화량이지 우연히 48일 이유가 없다. (나) 문자열 본문도 똑같이 ScrollingFrame(AutomaticSize Y + AutomaticCanvasSize Y + UISizeConstraint)을 지나므로(Dialog.luau:234-271) 스크롤 프레임 자체가 원인이면 문자열에서도 나야 한다. 차이는 인스턴스 본문의 내부(대개 자체 AutomaticSize/레이아웃)뿐이라 "AutomaticSize 사슬이 CanvasGroup > Content > ScrollingFrame > Body > 사용자 본문으로 5단"이라는 기존 추정과 일치한다. (다) 코드에서 다른 원인은 안 보임(ClickSink가 Scale(1,1)로 자동 크기 CanvasGroup 아래에 있지만 크기에 기여하지 않을 것으로 [추정]). 반박은 못 함. 확인법 제안: 인스턴스 본문일 때 ScrollingFrame을 빼고 일반 Frame으로 한 번 띄워 48이 돌아오는지 Studio에서 보기 — 돌아오면 "넘칠 때만 스크롤"로 바꿈(본문 높이를 알 수 없으니 `Fit` 같은 후처리가 필요해 새 메커니즘이면 사용자 결정).

5. [추정, 구성상 확실] TimePicker 모달에서 Input 모드로 잘못된 시(12시간제 "13")를 친 뒤 Picker로 되돌리면, 다이얼은 마지막 유효값을 보이는데 `model.Valid`(= HourInput 기준)는 false로 남아 OK가 비활성이다. setMode가 Input → Picker 때 입력을 되돌리지 않고(TimePicker/Modal.luau:216-224), 다이얼을 한 번 눌러야(SetTime이 HourInput을 덮어씀) 풀린다. Compose도 비슷할 수 있어 정본 확인 필요. 제안: Picker로 갈 때 `input` 을 Value로 되돌리는 한 줄(`model:SetTime(Value)`) 또는 OK 활성 조건을 모드별로.

6. [추정] Dialog의 `maxBody` 계산이 머리말을 한 줄(32)로 고정하고(Dialog.luau:243-246), 레이어 크기를 열 때 한 번만 읽는다(125행). 긴 머리말이 줄바꿈되면 카드가 레이어보다 커지고, 열린 뒤 창 크기가 바뀌어도 반영되지 않는다. TimePicker/Modal의 fitFor도 같다. 제안: 문서화(UB)로 충분할 수 있음.

7. [추정] 비효율 둘. (가) 단계 슬라이더의 눈금은 눈금당 Frame+UICorner 2개와 Compute 4개(visible/active/color/transparency)를 만들고(Track.luau:421-460), 최대 100개 — 끌 때마다 눈금 수만큼 visible/active가 다시 계산된다. 지나간 눈금 개수 하나(핸들 index)에서 파생하면 O(1) 상태로 줄일 수 있다. (나) ClockFace는 끌기 이동 하나마다 Hand 테이블 + q.Tween 테이블 여섯을 새로 만든다(ClockFace.luau:127-170, 끌기 중 `hand:Set`). 값이 같을 때는 Compute 비교로 걸러지겠지만 각도는 매번 달라 걸러지지 않는다.

8. [추정, 낮음] ClockFace 끌기가 `cancelled`(창 포커스 상실 등)로 끝나도 moved면 분 모드로 넘어가고 hand를 값에 맞춘다(ClockFace.luau:216-230). 취소는 되돌리는 게 자연스러울 수 있음. 정본(Compose)은 onDragCancel이 없을 수 있어 낮음.

## 중복·가독성 (구현 개선 후보)

- Slider/init.luau ↔ Slider/Range.luau(↔ M2): 색 4줄(activeColor/inactiveColor/…T), 핸들 Frame(FocusRing UIStroke 블록 22줄, Short2 크기 트윈, narrow/ringOn 계산)이 거의 글자 그대로 두 벌. Track 쪽에 `g.handle({Position, Narrow, RingOn, ZIndex, Label})` 하나 두면 각 파일이 60줄 가량 줄 것(새 메커니즘이 아니라 내부 함수 추출).
- `hostName(name)` 캐시 함수가 AppBar/Top, NavigationDrawer/Drawer, NavigationDrawer/Sheet, Toolbar 네 곳에 같은 8줄로 복제됨(90dd7579). `Util.hostName`으로 한 곳이면 충분.
- TimePicker `Dial()`과 `Input()` 래퍼(15줄)가 호스트 이름 상수와 build 함수만 다르다. 읽기 쉬움 문제는 아님.
- TextField/Field.luau:178 `Style.disabledPick(disabled, OnSurface, OnSurface)` — 두 색이 같아 호출이 아무 일도 안 한다(투명도가 비활성을 처리). 죽은 분기.
- Slider/init.luau의 `Slider` 함수가 ~300줄에서 표준·가운데 두 모양 + 아이콘을 한 함수에서 만든다. 표준/가운데를 각각 `buildStandard`/`buildCentered`로 가르면 읽기 쉬움(취향 경계, 약함).

## 확인했지만 문제없던 것

- 호스트 `Name` 상수 56자리: Name 상수가 항상 `props.Modifier`보다 앞 — 순서가 틀려 소비자 `:Name`이 지는 자리는 못 찾음(host 앞 6줄 안에 인라인 `Name =` 없음, 상수 위치를 전수 grep). 같은 상수를 다른 클래스 호스트에 쓴 자리 없음(Card/ListItem/Divider/Badge/IconButton은 Frame·TextButton 상수를 따로 둠). 이름이 인자인 `hostName` 캐시 네 곳은 인자가 모두 모듈 내부 리터럴(Toolbar/AppBar/Drawer/Sheet)이라 캐시는 유한(자라지 않음). 이름으로 호스트를 찾는 내부 조회도 0건(FindFirstChild 사용처는 Ripple UIScale뿐). Select의 호스트 이름은 "TextField"라는 점만 참고.
- Clock 순수 계산: dialAngle/nearestHourIndex/nearestMinute 경계, hourForDisplay(0/12/23), stepDial(분 58 → 0, 12시간제 순환), withPeriod, format, editField(세 번째 숫자가 가운데/앞에 들어올 때, 붙여넣기 "123", 비숫자), hourFromTyped(12 AM/PM) — 읽어서 맞음.
- Model.SetPeriod는 hourValid일 때만 이동, SetTime은 OnChange를 바뀐 때만 부름, 프로그램 쓰기는 OnChange 안 부름(Sync 이펙트) — 계약 일치.
- Slider: min == max는 에러(Max must be greater), Step <= 0 에러, 범위 슬라이더 핸들 겹침(5,5 끌기: 첫 이동으로 핸들 결정, 반대편은 멈춤)은 문서대로 동작(프로브 확인), OnChange는 사용자 조작 뒤에만.
- TextField MaxLength: utf8 자르기(잘못된 utf8은 바이트 폴백), ShowCounter=false는 입력 자르기 유지·표시만 제거, OnChange는 자르기만 일어난 경우 안 불림 — 일관.
- 연결 해제: Behavior의 AbsoluteSize 연결은 호스트 자체 신호라 호스트와 함께 죽음, KeyNav/drag의 전역 연결은 기존 스펙이 개수를 단언.

## 못 본 것

- 레이아웃이 필요한 모든 것(AutomaticSize·UIListLayout 동작, Dialog 높이의 실제 원인, 스크롤바, UICorner 반경 잘림)은 mock에 엔진이 없어 읽기만 했다.
- Tabs/Menu/List/Chip/Checkbox/Radio/Switch/Progress는 Name 변경분만 확인(동작 변경은 이번 범위에 거의 없음), DatePicker Docked/Modal/Chip의 snap 로직은 diff만 읽고 프로브 안 함(Chip `snaps`는 이전 상태→현재 상태 규칙이 문서와 일치하는 것까지만), Split.luau 482줄은 헤더와 Name 변경만, Gallery 삭제분·Icons 확장분은 보지 않음.
- Dial↔Input 두 벌의 키보드 처리 차이(Compose는 Up/Left가 이전·Down/Right가 다음인데 구현은 Left/Right만 매핑하고 Up/Down은 선택 이동) — 의도로 보이나 정본과 대조는 못 함.
