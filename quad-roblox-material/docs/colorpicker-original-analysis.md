# 원본 컬러피커 분석 (비교 문서 + 이식 사양)

대상은 사용자 소유 Roblox 컬러피커 모델(MIT)을 파싱해 얻은 LocalScript 하나다(루트의 rbxm 파일, 레포 밖
스크래치에 추출본). 인스턴스 트리는 `ScreenGui "colorPicker"`(ZIndexBehavior Global) > `Frame`(크기 1,0,1,0,
흰 배경) > `UIListLayout`(Horizontal, Padding 32px, 가운데 정렬, LayoutOrder 정렬) + 그 LocalScript 하나다.
UI 전체가 이 스크립트 한 파일(2348줄)에서 만들어지고, 하단에서 `HSVColorPicker` 창을 Light·Dark 두 개 띄운다.
이 문서의 줄 번호는 추출본(`script1_colorPicker_Frame_colorPicker.luau`) 기준이다. 숫자는 `wc`/`grep`과
Lune 위에서 생성 함수를 직접 돌려 센 값이고, "약"이 붙은 것은 구간 합이다. 에셋 id의 "무엇인지"는 사용처에서
추론한 것이지 이미지를 열어 확인한 것이 아니다.

## 1. 구조

### 1.1 클래스 셋과 줄 수

| 구역 | 줄 | 줄 수 | 비고 |
|---|---|---|---|
| 머리(서비스·로컬) | 1~8 | 8 | |
| `huePicker` | 9~449 | 약 440 | 색상 슬라이더 + 핸들 + 프리뷰 말풍선 + 가짜 커서 |
| `saturationBrightnessPicker` | 450~888 | 약 440 | SV 사각형 + 커서 + 가짜 커서 |
| `HSVColorPicker` | 889~2236 | 약 1350 | 창·제목줄·편집줄 셋·확인줄·테마·핸들러 |
| 주석 처리된 "창 이동" 죽은 코드 | 2238~2314 | 77 | 전부 `--` |
| 데모(`do` 블록 둘: Light/Dark) | 2316~2348 | 33 | `onConfirm`의 `("%d"):format(…, hue …)`는 0~1 실수를 넘긴다 |

전체 2348줄 중 빈 줄 274, 주석 줄 261(죽은 코드 77 + 클래스 머리 배너 포함).

### 1.2 책임별 줄 수 (약)

| 책임 | 줄 | 어디 |
|---|---|---|
| 인스턴스 생성 | 약 696 | hue `__initSlider` 163~269(107), SV `__initSVField`/`__initCursor` 643~718(76), HSV 제목·편집줄 셋·확인줄·창 1245~1757(513) |
| 테마 테이블 | 76 | 921~996 (Dark/Light 두 벌, 거의 같고 4개 키만 다름) |
| 입력 처리(드래그 연결 설치/해제, 좌표→비율) | 약 144 | hue 379~448(70), SV 814~887(74) |
| 가짜 커서(좌표·표시 전환·트윈) | 약 80 | hue 324~365, SV 772~812 — 거의 복붙 |
| 애니메이션(트윈) | 약 170 | hue 271~322(52), SV 720~736(17), 버튼 호버 99(2075~2173) |
| 파츠 간 상태 동기화 | 약 560 | `setColor*` 계열(25+50+35), `__updateEditBoxs` 40, 핸들러 338(1859~2196), 확인·취소·프리뷰 32 |
| 텍스트 입력 정규화 | 57 | `__processText`/`__tabkeyProcess` 1801~1857 |
| 정리(destroy) | 202 | 59 + 53 + 90 |
| `fromInstance`(복제 UI 되살리기) | 94 | 20 + 19 + 55 |
| 나머지(배너 주석, 셋터, 데모, 죽은 코드) | 약 270 | |

`ZIndex`라는 단어가 83번 나온다 — 모든 인스턴스에 손으로 +0/+1/+2/+3을 얹는다(ZIndexBehavior Global 전제).
같은 모양의 블록이 반복된다: 연결 네 개를 끊는 `if x then x:Disconnect() x = nil end` 블록이 `__inputEnded` 둘 +
`destroy` 둘로 클래스당 8줄×4 = 두 클래스에서 모두 반복, `Tween:Cancel()/:Destroy()` 쌍이 21곳, 텍스트박스
핸들러 6개(H/S/V/R/G/B)가 각 22줄씩 거의 같은 본문.

### 1.3 연결·트윈·인스턴스 장부

- `:Connect(` 호출 자리: 활성 46곳(grep 50 중 4곳은 죽은 코드 주석).
  - 창 하나가 살아 있는 동안 **상시 연결 35개**: hue·SV 마우스다운 2 + `handleConnections` 33(텍스트 변경 7
    (`GetPropertyChangedSignal("Text")`), 휠 12(박스 6 × 앞/뒤), 선택·취소 클릭 2, 취소 버튼 호버 4(Up/Enter/
    Leave/Down), 선택 버튼 호버 4, 닫기 버튼 4(MouseEnter가 **두 번 중복 등록**돼 있다)).
  - **드래그 중 추가 연결 4개씩**(hue 드래그 또는 SV 드래그): `UserInputService.InputEnded`, `InputChanged`,
    `WindowFocusReleased`, `GuiService.MenuOpened`.
  - 연결이 아닌데 새는 것: `__cursorUpAnimation`이 마우스를 뗄 때마다 `previewScaleTween.Completed:Connect`를
    걸고 끊지 않는다(트윈을 Destroy해 간접 정리되긴 하나 의도가 아니다).
- `:Disconnect()` 자리 23곳(전부 손으로 짠 장부 — `destroy`·`__inputEnded` 복붙).
- `TweenService:Create` 16곳 + `:TweenPosition`/`:TweenSize` 8곳. 같은 객체의 이전 트윈을 취소하는 `Cancel` +
  `Destroy` 쌍이 21곳, 트윈 핸들을 `self.xxxTween` 필드 열한 개로 들고 다닌다.
- `task.wait()` 7곳 — 텍스트박스 핸들러가 `Text` 변경 시그널 안에서 한 틱 양보한 뒤 처리한다(반응형 콜백 안
  yield).
- **창 하나(Instance.new 실행 횟수)**: 창 프레임 12(그림자 9조각: 본체 1 + 가장자리·모서리 8, 홀더 + `UIPadding` +
  `UIListLayout`) + `themeValue`(StringValue) 1 + SV 8(필드·덮개 이미지·`UICorner` 2·`UIPadding`·커서·커서
  미리보기·가짜 커서) + hue 11(슬라이더·`UIPadding`·`UIGradient`·핸들·둥근 색·그림자·프리뷰 말풍선·프리뷰 그림자·
  프리뷰 색·`UIScale`·가짜 커서) + 제목줄 5 + HSV 편집줄 14 + RGB 편집줄 14 + HEX 편집줄 6 + 확인줄 17(버튼 틀 3,
  취소 4·선택 4, 프리뷰 6) = **88개**. Lune에서 생성 함수를 직접 돌려 센 값과 일치한다(12/8/11/5/14/14/6/17
  + StringValue 1). 화면에는 창이 둘이므로 176개 + 바깥 프레임·ScreenGui.
  - 라운드 사각형이 전부 **9-slice 이미지**(`ScaleType.Slice`, `SliceCenter 516,516,516,516`, `SliceScale`
    0.0422 등)이고 그림자도 전부 이미지라 `UICorner`/`UIStroke`는 SV 필드에만 쓴다(`UICorner` 2개).

## 2. 상태가 흐르는 방식

### 2.1 소유권

상태의 소유자가 **없다** — 같은 값이 여섯 군데에 복사돼 산다.

- `HSVColorPicker.hue/saturation/brightness/color`(바깥 클래스)
- `huePicker.hue`
- `saturationBrightnessPicker.hue/saturation/brightness/color/X/Y`
- 6개 텍스트박스의 `.Text`와 각 박스의 `xxxLastText`, `xxxUpdateIgnore` 플래그
- GUI 프로퍼티 자체(SV 필드 `BackgroundColor3`, 핸들 `Position`, 프리뷰 `ImageColor3` …) — `fromInstance`는 이걸
  거꾸로 읽어 상태를 복원한다.
- `lastColor`(확인된 마지막 색)

### 2.2 동기화 경로(모두 손으로 연결)

- **hue 드래그** → `huePicker:update` → `onUpdate`(콜백 필드) → `HSVColorPicker`가 `__setupHandlers`에서 붙인
  함수가 `saturationBrightnessHandler:setHue`(SV 배경색·커서 색 갱신) → `self.color` 갱신 →
  `__updateEditBoxs()` → `__updatePreview()` → 외부 `onUpdate`.
- **SV 드래그** → `saturationBrightnessPicker:update` → `onUpdate` → 바깥 클래스가 값 복사 + `__updateEditBoxs` +
  `__updatePreview` + 외부 `onUpdate`. (hue 박스는 이 경로에서 갱신되지 않아도 되지만 매번 비교한다.)
- **H 박스 입력** → `hueHandler:setHue(h, true)` + `saturationBrightnessHandler:setHue` + 필드 복사 + 외부 `onUpdate`.
  (`__updateEditBoxs`·`__updatePreview`는 **부르지 않는다** — 프리뷰가 갱신되지 않는다.)
- **S/V 박스 입력** → `setColorByHSV`(애니메이션 켜서) + 복사 + 외부 `onUpdate`(프리뷰 갱신 없음).
- **R/G/B 박스 입력** → `Color3.new(…)` → `setColor`(= `Color3:ToHSV()`로 HSV 재유도) → hue 핸들러 `setHue` → 필드
  복사. **여기가 색조 손실 지점**: 무채색·검정 색이 들어오면 `ToHSV()`가 hue를 0(빨강)으로 돌려 hue 슬라이더가
  빨강으로 튄다.
- **HEX 박스** → `Color3.fromHex` → 같은 `setColor` 경로(같은 손실).
- **취소** → `self.color = self.lastColor` → `__updateEditBoxs()`(**이때 `self.hue/saturation/brightness`는 아직 옛
  값이라 박스에 옛 HSV가 쓰인다**) → 그 뒤 `setColor` 등으로 값을 갱신 → `__updatePreview` → `onCancel(lastColor,
  draftColor)`. 취소는 `onUpdate`를 쏘지 않는다.
- **확인** → `lastColor = color` → `__updatePreview`(왼쪽 반이 새 확정색이 됨) → `onConfirm(color, hue, sat, val)`.
- **프리뷰 바**: 왼쪽 절반 = `lastColor`, 오른쪽 절반 = 현재색. 반쪽 둥근 모서리를 만들려고 `ImageLabel` 둥근 이미지 둘 +
  `Frame` 둘(안쪽 10px 직사각형)로 접합한다.

### 2.3 콜백 모양

`onUpdate(color, hue, sat, val)` / `onConfirm(color, hue, sat, val)` / `onCancel(lastColor, draftColor)` — 인스턴스
필드에 함수를 덮어써서 붙인다(`function this:onUpdate(...)`). 클래스 기본값은 빈 함수(`onCancel`은 기본값 없음 → nil
검사). 값은 모두 0~1 실수(hue/sat/val)와 `Color3`.

### 2.4 텍스트박스 규칙(원본 동작)

- 박스 값 범위: **H/S/V/R/G/B 전부 0~255 정수**(`("%d"):format(hue*255)` — 색조도 0~255로 보인다). 포맷이
  `%d`라 소수는 **잘린다**(반올림 아님; 0.5*255 → 127).
- 검증은 **FocusLost가 아니라 `Text` 변경마다**(`GetPropertyChangedSignal("Text")` + `task.wait()`): 숫자가 아니면 직전
  텍스트로 되돌림, 빈칸/공백이면 `"0"`, 앞의 0 제거(`01` → `1`), 직전 텍스트가 `"0"`이면 뒤쪽 0 제거(`10` → `1`),
  공백 제거 후 `%d+`만 남김(**`-5` → `5`**), 0~255 클램프. 보정한 텍스트를 쓰면서 `xxxUpdateIgnore = true`로 자기
  재진입을 막는다(플래그 열두 개 중 일부는 박스 교차 오기입 버그가 있다: V 박스에서 Tab을 누르면 `hBoxUpdateIgnore`와
  `hBox.Text`를 건드린다).
- Tab 키: 텍스트에 `\t`가 들어오면 현재 박스 `ReleaseFocus`, 다음 박스 `CaptureFocus` + 선택 영역 설정(H→S→V→H,
  R→G→B→R). 입력 문자 `\t`를 텍스트 변경으로 감지하는 방식.
- 휠: 박스 위에서 휠 앞/뒤로 ±1(**클램프는 다음 텍스트 변경 핸들러가** 함; 박스 비어 있으면 `tonumber(nil)` 에러).
- HEX 박스: 헥사 아닌 문자가 있으면 직전 텍스트, `%x+`만 남김, 6자 초과는 자름, 6자 미만이면 현재 색의 `ToHex()`로
  되돌림. 형식은 `RRGGBB`(`#` 없음, `Color3:ToHex()` 그대로).

## 3. 이식이 재현해야 할 사양

단위: `px`는 Offset, `S`는 Scale. 모든 색은 RGB 0~255.

### 3.1 창(윈도우)과 레이아웃

- 창: 크기 **230×418 px**, 이미지 `4668069300`(흰 둥근 사각형, 9-slice 516, `SliceScale 0.0192`), `ImageColor3 =
  WindowBackgroundColor`, 배경 검정 `BackgroundTransparency 0.75`(원본의 배경 아래 깔림 — 이식에서는 의도된 보조
  그림자 레이어인지 확인 필요, 아래 4절), 테두리 없음.
- 그림자: 8조각 9-slice 이미지(좌 `6030946815`, 우 `6030947135`, 위 `6030947326`, 아래 `6030947500`, 좌상 `6030947654`,
  우상 `6030947949`, 좌하 `6030947802`, 우하 `6030948089`). 두께 테마 값: 좌 40, 우 40, 아래 50, 위 30 px.
  (이식은 `UIShadow`/`UIStroke` 등으로 1~2개 인스턴스에 압축할 것 — 시각 동일을 유지.)
- 홀더: `UIPadding` 좌 16 / 우 16 / 위 16 px, `UIListLayout` 세로, `Padding 10 px`, 정렬 `LayoutOrder`.
- 자식 순서와 높이: ① 제목줄 8 px(+`UIPadding` 아래 4) ② SV 정사각형(가로 = 창폭 − 32 = **198 px**, 정사각형
  `SizeConstraint RelativeXX`) ③ hue 슬라이더 14 px ④ HSV 편집줄 24 ⑤ RGB 편집줄 24 ⑥ HEX 편집줄 24 ⑦ 확인줄 32.
  합계 = 16 + 8 + 198 + 14 + 24×3 + 32 + 간격 6×10 = 400 → 아래 여백 18.
- 두 창을 `Frame`에 나란히(Horizontal, 간격 32 px, 가운데 정렬)(Light·Dark). `ZIndex` 기준 1(원본은 손으로 +1~+3).

### 3.2 테마(Light / Dark) — 다른 키만 표시

| 키 | Light | Dark |
|---|---|---|
| 창 배경 `WindowBackgroundColor` | 255,255,255 | 41,41,41 |
| 라벨 글자색 `EditLabelTextColor` | 0,0,0 | 255,255,255 |
| 입력 글자색 `EditBoxTextColor` | 64,64,64 | 200,200,200 |
| 제목 글자색 `TitleTextColor` | 0,0,0 | 255,255,255 |

같은 키(두 테마 공통): `EditorBoxUnderbarColor` 106,0,255 · `EditBoxSizeY` 24 · `TitleFramePaddingBottom` 4 ·
`TitleFrameSizeY` 8 · `CloseButtonBackgroundColor` 255,77,61 · 그림자 두께 40/40/50/30(좌/우/아래/위) ·
`CancelButtonColor` 234,211,255 · `CancelButtonTextColor` 0,0,0 · `CancelButtonShadowColor` 125,119,170 ·
`SelectButtonColor` 106,0,255 · `SelectButtonTextColor` 255,255,255 · `SelectButtonShadowColor` 33,0,115 ·
`PreviewShadowColor` 112,112,112 · `ButtonDimColor` 0,0,0 · 문구 `"Cancel"`/`"Select"` · 딤 투명도
`On 0.68`·`Hover 0.8`·`Off 1`.

### 3.3 부품별 치수

**제목줄**: 투명 프레임 8 px. 글자 `GothamBold` 14, 가운데(기본 정렬), 문구 `"Color Picker"`, 크기 1,1.
닫기 버튼 `ImageButton`: 이미지 `4668069300`(색 `CloseButtonBackgroundColor` 255,77,61), 14×14 px, 위치
`(-4 px, 0.5)`, 앵커 `(0, 0.5)`. 안에 × 아이콘 `2751883273`(크기 `1,-2`, `ImageTransparency 1` — **그래서 호버 때
`Visible=true`로 바꿔도 아이콘이 보이지 않는다**; 이식은 의도(호버 때 ×가 나타남)를 구현할지 결정할 것).

**SV 필드**: `TextButton`(`Text=""`, `AutoButtonColor=false`, 배경 = 현재 hue의 순색, 테두리 없음), `UICorner 10 px`,
`UIPadding` 4 px 사방. 안에 덮개 이미지 `6411042282`(하양→투명 가로 + 투명→검정 세로 그라디언트로 보임; 크기 `1,8 / 1,8`,
위치 `(-4,-4) px`, `UICorner 8 px`). 커서: `ImageLabel` 이미지 `4668069300`, 크기 **16×16 px**, 앵커 `(0.5,0.5)`,
위치 `(S, 1−V)` 비율, `ImageColor3` = 링 회색(`cursorRingGray`, 흰 모서리 근처는 검정에서 시작해 0.25 거리에서 흰색).
안쪽 미리보기 원: 같은 이미지, 크기 `1,-4 / 1,-4`, 색 = 현재 색.

**hue 슬라이더**: `ImageButton`(이미지 `4668069300` 9-slice 516, `SliceScale 0.0613`), 크기 `(1, 14 px)`, 앵커 `(0,1)`,
`UIPadding` 좌우 5 px, `UIGradient` 무지개 7키(0 빨강, 1/6 노랑, 2/6 초록, 3/6 시안, 4/6 파랑, 5/6 마젠타, 1 빨강).
핸들: `ImageLabel` 이미지 `4668069300`, 크기 `1,6 / 1,6`(`SizeConstraint RelativeYY`), 앵커 `(0.5,0.5)`, 위치
`(hue, 0.5)`. 안쪽 `colorRound`: 크기 `1,-6 / 1,-6`, 색 = `hsv(hue,1,1)`. `roundShadow`: 이미지 `2584395459`, 투명도
0.3, 위치 `(0.5, 0.5 + 1 px)`, 크기 `1,4 / 1,3`.
프리뷰 말풍선: 핸들의 자식 `ImageLabel` 이미지 `11729301118`(말풍선), **32×68 px**, 앵커 `(0.5,1)`, 위치 `(0.5,1)`(핸들
위로 솟음), `Visible=false` 시작, `UIScale 0` 시작. 안에 말풍선 그림자 `11729416602`(색 95,95,95, 투명도 0.7, 크기
`1,14 / 1,14`) 와 프리뷰 원(`4668069300`, 위치 `(5,5) px`, 크기 `1,-10 / 1,-10` `RelativeXX`, 색 = hue 순색).

**편집줄 셋**(HSV, RGB, HEX): 줄 높이 24 px, 가로 `UIListLayout` 정렬. HSV·RGB는 `라벨(16 px) + 박스(0.333 −16 px)`
세 쌍; 라벨 `GothamBold` 14, 박스 `GothamMedium` 14, `ClearTextOnFocus=false`, 박스 안에 `UIPadding` 좌 4 / 우 8 px,
밑줄 `Frame`(높이 2 px, 색 106,0,255, 앵커 `(0,1)`). HEX 줄은 `라벨 "HEX"`(36 px) + 박스(`1,-36`).

**확인줄**: 높이 32 px. 오른쪽 정렬 `UIListLayout`(간격 6 px)에 버튼 둘: 취소(`4668069300` 9-slice `SliceScale
0.0422`, 색 `CancelButtonColor`) / 선택(색 `SelectButtonColor`), 각 **63×32 px**(원본은 둘 다 `LayoutOrder 2`라 순서가
정의 안 됨 — 생성 순서 취소 → 선택). 버튼 글자 `GothamBold` 14. 버튼 그림자: 이미지 `4487986429`, 위치 `(0.5,
0.5 + 2 px)`, 크기 `1,6 / 1,8`, 투명도 0.2, 색 = 테마 `...ButtonShadowColor`. 딤 오버레이(`selectDim`/`cancelDim`):
같은 9-slice, 검정, 투명도로 상태 표현. 프리뷰 바(왼쪽 영역): 폭 52 px, 높이 100%, 둥근 원 둘 `32×32`(좌: `lastColor`,
우: 현재색) + 그 사이를 메우는 `Frame` 둘(위치 `16 px`/`-16 px`, 폭 10 px) + 그림자 `4487986429`(색 112,112,112, 투명도
0.2, 위치 `(0.5, 0.5+2 px)`, 크기 `1,6 / 1,8`).

### 3.4 에셋 id와 용도(사용처 추론)

| id | 용도 |
|---|---|
| `4668069300` | 흰 채움 둥근 사각형(9-slice 516) — 창·버튼·핸들·커서·프리뷰·딤·닫기 버튼의 색칠 바탕(14곳) |
| `2584395459` | hue 핸들 아래의 부드러운 원형 그림자 |
| `11729301118` | hue 프리뷰 말풍선(눈물방울형, 32×68) |
| `11729416602` | 말풍선 그림자 |
| `4030329127` | 가짜 마우스 커서(화살표, 16×16, 검정 틴트) |
| `2751883273` | 닫기 버튼의 × 아이콘 |
| `4487986429` | 부드러운 둥근 그림자(버튼·프리뷰 바, 틴트됨) — 3곳 |
| `6411042282` | SV 필드 덮개(채도/명도 그라디언트) — 2곳(주석 처리된 옛 버전 포함) |
| `6030946815`·`6030947135`·`6030947326`·`6030947500`·`6030947654`·`6030947949`·`6030947802`·`6030948089` | 창 그림자 8조각(좌·우·위·아래·좌상·우상·좌하·우하) |

### 3.5 애니메이션 표(전부 `Enum.EasingDirection.Out`)

| 무엇 | 대상 | 시간 | 스타일 | 값 |
|---|---|---|---|---|
| hue 마우스다운: 프리뷰 말풍선 | `UIScale.Scale` | 0.36 s | Exponential | 0 → 1 (`Visible=true` 즉시) |
| hue 마우스다운: 색 원 투명화 | `colorRound.ImageTransparency` | 0.18 s | Quad | → 1 |
| hue 마우스업: 프리뷰 축소 | `UIScale.Scale` | 0.28 s | Quad | → 0, `Completed` 정상 종료일 때만 `Visible=false` |
| hue 마우스업: 색 원 복귀 | `colorRound.ImageTransparency` | 0.42 s | Quad | → 0 |
| hue 핸들 이동(드래그·박스·끝) | `TweenPosition` `(x, 0.5)` | 0.12 s | Quad | 새 트윈이 이전 것을 덮어씀 |
| SV 마우스다운: 커서 확대 | `TweenSize` | 0.12 s | Quad | 16×16 → **26×26 px** |
| SV 마우스다운: 안쪽 원 | `TweenSize` | 0.14 s | Quad | `1,-4` → `1,-6` |
| SV 마우스업: 커서 축소 | `TweenSize` | 0.12 s | Quad | 26×26 → 16×16 |
| SV 마우스업: 안쪽 원 | `TweenSize` | 0.12 s | Quad | → `1,-4` |
| SV 커서 이동 | `TweenPosition` `(S, 1−V)` | 0.09 s | Quad | |
| 가짜 커서 위치 | `TweenPosition` | 0.07 s | Quad | |
| 가짜 커서 나타남/사라짐 | `ImageTransparency` | 나타남 0.64 s / 사라짐 0.18 s / 강제 숨김 0.09 s | Quad | 0 / 1 |
| 버튼 딤(모든 전이) | `Dim.ImageTransparency` | 0.28 s | Quad | MouseEnter·MouseUp → 0.8, MouseLeave → 1, MouseButton1Down → 0.68 |
| 색 변경 자체(핸들 색, 프리뷰 색, SV 배경, 박스 텍스트) | — | **애니메이션 없음, 즉시** | | |

"색 라운드 전이"라는 별도 색 트윈은 원본에 **없다**(색은 즉시 바뀌고 투명도만 트윈한다).

### 3.6 마우스·터치 동작

- **hue 드래그 시작**: 슬라이더 `MouseButton1Down(x)` → 상대 비율 계산(`(x − AbsolutePosition.X) / AbsoluteSize.X`, 0~1
  클램프) → `update(비율, emit, anim)` + 마우스다운 애니메이션 → `UserInputService.MouseIconEnabled = false` → 연결 4개
  설치. SV는 `MouseButton1Down(x, y)`를 받는데 **y에서 36을 뺀다**(`inputPosY-36` 하드코딩 — GUI 인셋 보정으로 보임, 이식은
  인셋 계산을 명시해야 함).
- **드래그 중**: `InputChanged`에서 `MouseMovement`/`Touch`만 처리 → 가짜 커서 갱신(`UserInputService.MouseEnabled`가 거짓이면
  항상 숨김) → 비율 갱신 → `update(…, emit = true, anim = true)`. 가짜 커서는 포인터가 영역에서 **10 px 넘게 벗어났을 때만**
  보인다(실제 커서 아이콘은 숨긴 상태이기 때문).
- **드래그 끝**: `InputEnded`(`MouseButton1` 또는 `Touch`만) → `MouseIconEnabled = true` → 마우스업 애니메이션 → 연결 4개 해제 → 가짜 커서
  숨김 → 마지막 위치로 한 번 더 `update`. `WindowFocusReleased`·`GuiService.MenuOpened`도 같은 종료 경로를 탄다
  (`__inputEnded(true)`) — **그러나 종료 경로가 끝에서 `InputObject.Position.X`를 읽는데 `true`에는 `.Position`이 없어 에러**가
  난다(정리는 이미 끝난 뒤라 상태는 멀쩡하지만 콘솔에 에러). 이식은 "포커스를 잃으면 드래그를 끝내되 마지막 위치 갱신은
  건너뜀"으로 구현할 것.
- **버튼**: 호버/눌림은 3.5의 딤. 클릭(`MouseButton1Click`)으로 확인/취소. 닫기 버튼 클릭 = 취소와 같음.
- **확인/취소 의미**: 확인 → `lastColor = 현재색`(프리뷰 왼쪽이 같아짐) + `onConfirm`. 취소/닫기 → 현재색을 `lastColor`로
  되돌림(UI 전체: SV 커서, hue 핸들, 박스, 프리뷰) + `onCancel(lastColor, draft)`; `onUpdate`는 쏘지 않는다.
  초기 `lastColor`는 인자로 받는다(데모는 222,0,222).
- **초기 색**: 데모는 `HSV(0.8, 0.4, 1)`, `lastColor` = 222,0,222(프리뷰 바 왼쪽이 보라, 오른쪽이 연한 보라로 시작).

## 4. 원본의 결함과 이식에서 달라질 것(비교 문서용)

1. **색조 손실**: R/G/B/HEX 입력이 `Color3:ToHSV()`를 거쳐 무채색·검정에서 hue가 0으로 떨어진다. 이식은 `ColorModel`의
   `fromRGBPreservingHue`로 해소한다(단일 `Source<HSV>`; 근거는 `ColorModel.luau` 머리).
2. **박스 값 범위**: H/S/V가 0~255로 표시된다. 이식은 `ColorModel.Scale.Degrees`(360/100/100) 기본, `Scale.Legacy`로 원본 재현 가능.
   (사용자 결정이 필요하면 보고서의 열린 항목.)
3. **텍스트 검증이 키 입력마다 + `task.wait()`**: 반응형 콜백 안 yield. 이식은 파싱 성공 시 라이브 반영, FocusLost에서 모델로 되쓰기.
4. **드래그 포커스 해제 경로의 에러**, 닫기 버튼 × 아이콘이 영원히 투명, `MouseEnter` 중복 등록, `fromInstance`가 hue 슬라이더를
   `saturationBrightnessPicker.fromInstance`로 복원(라인 1070), H/S 박스 이름이 서로 바뀜(`hBox.Name = "SBox"` 라인 1350 —
   `fromInstance`의 이름 조회가 틀어짐), H/S/V 박스 입력이 프리뷰 바를 갱신하지 않음, 취소가 박스를 옛 HSV로 씀, `inputPosY-36` 매직 넘버,
   휠이 빈 박스에서 에러.
5. **장부**: 연결 46곳·해제 23곳·트윈 24곳(Create 16 + Tween* 8)·창당 인스턴스 88개·`ZIndex` 83회는 전부 손으로 관리한다. quad에서는
   연결·해제·트윈 취소가 선언(`q.OnChange`/`q.Out`/`Effect` 클린업/`Tween` 필드)으로, `fromInstance`·`destroy`는 `q.dispose`로 대체된다.
