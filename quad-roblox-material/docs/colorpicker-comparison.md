# 컬러피커 비교: 순수 OOP 원본 대 quad (Classic 이식 / Material 재설계)

목적은 하나다 — 같은 컬러피커를 평범한 OOP LocalScript로 짠 것(사용자 원본, MIT, 2348줄)과 quad로 다시 짠 것(Classic 이식,
Material 재설계)을 나란히 놓고 **코드 품질이 얼마나 달라지는지**를 숫자와 줄 번호로 보이는 것이다. 숫자는 전부 `wc`·grep·
주석을 제외한 정적 집계(스크립트는 스크래치에 있고 규칙은 아래 "집계 방법")와 Lune 위 스펙 실행에서 얻은 값이다. 원본의 줄 번호는
레포 밖 스크래치에 추출해 둔 `script1_colorPicker_Frame_colorPicker.luau` 기준이고(레포에 없는 파일이라 경로를 백틱 없이 적는다),
`원본 L123`은 그 파일의 123번째 줄이다. 이식 쪽 인용은 이 레포 안의 파일이다. 원본 분석(치수·애니메이션·결함 목록)은
`docs/colorpicker-original-analysis.md`가 소스다.

**집계 방법.** 줄은 빈 줄 / 주석(`--` 한 줄과 `--[[ ]]` 블록, 죽은 코드 주석 포함) / 코드로 나눴다. 호출 횟수(`:Connect(` 등)는 주석을
뺀 코드 줄에서 센 발생 횟수다 — 그래서 분석 문서가 주석까지 센 `:Disconnect(` 23곳은 여기서 **19곳**이다. "인스턴스 수"는
`H.countDescendants`(+ 호스트 1)이고 원본의 88은 분석 문서가 Lune에서 생성 함수를 직접 돌려 센 값이다.

## 한눈에 보는 요약 (측정값)

| 항목 | 원본(OOP) | Classic 이식(quad) | Material(quad) |
|---|---|---|---|
| 파일 수 | 1 | 10 + `ColorModel` + `Demo` | 8 + `init` (+ `ColorModel`) |
| 전체 줄(데모·죽은 코드 포함 파일 전체) | 2348 | 코어 1313 (+Demo 59, +ColorModel 351 = 1723) | 1682 (+ColorModel 351 = 2033) |
| **코드 줄**(빈 줄·주석 제외) | **1813** | **1050** (Demo·ColorModel 포함 1317) | **1312** (ColorModel 포함 1537) |
| 테스트 | 없음 | 스펙 380줄(10 섹션) + 순수 스펙 | 스펙 676줄(18 섹션) + 순수 스펙(공유) |
| `:Connect(` 호출 자리 | 46 | 0 | 5 (`KeyNav`·`HueSlider` 호스트 훅) |
| `:Disconnect(` | 19 | 0 | 1 (`KeyNav` 닫기 한 곳) |
| `TweenService:Create` / `:TweenPosition`·`:TweenSize` | 16 / 8 | 0 / 0 | 0 / 0 |
| 트윈 취소 `:Cancel()` + `:Destroy()` | 21 + 28 | 0 | 0 |
| `task.wait` (반응형 콜백 안) | 7 | 0 | 0 |
| `ZIndex` 쓰인 줄 | 83 | 4 (가짜 커서 1 + 색상 슬라이더의 그림자를 손잡이 아래 두기 3) | 0 |
| 상태 복사본(같은 색이 사는 곳) | 6 | 1 (`Source<HSV>`) | 1 (`Source<HSV>`) |
| 창 하나의 인스턴스 | 88 | 81 | 107 (패널) / 136 (모달 전체, 오버레이·스크림 포함) |
| 외부 이미지 에셋 id(고유) | 16종 | 6종(`ImageLabel` 6개) | 0 |

읽는 법 두 가지를 먼저 적어 둔다. 첫째, Material은 원본과 **같은 기능이 아니다** — hex 필드(떠오르는 라벨 포함 kit `TextField`), RGB/HSV
토글, 프리셋·최근 색 줄, 키보드/게임패드 조작, 다크/라이트 테마 전환, 모달(OK/Cancel 초안 모델)이 더 들어 있다. 그래서 줄 수·인스턴스
수는 "같은 것을 더 적게"가 아니라 "더 많은 것을 비슷한 규모로"로 읽어야 한다. 둘째, 가장 공정한 줄 수 비교는 **Classic 대 원본**이다
(같은 모양·같은 동작을 일부러 이식했다): 코드 줄이 1813 → 1050으로 **42 % 적고**, 순수 색 수학(`ColorModel`, 독립 테스트 90개)까지 더해도
1317로 27 % 적다. 연결·해제·트윈 취소 장부는 코드에서 사라졌다.

## (a) 줄 수

원본(`원본 L1~L2348`)은 클래스 셋과 죽은 코드와 데모가 한 파일이다.

| 구역 | 줄 | 전체 | 코드 | 주석 | 빈 줄 |
|---|---|---|---|---|---|
| 머리(서비스·로컬) | L1~8 | 8 | 5 | 1 | 2 |
| `huePicker` | L9~449 | 441 | 344 | 45 | 52 |
| `saturationBrightnessPicker` | L450~888 | 439 | 317 | 59 | 63 |
| `HSVColorPicker` | L889~2236 | 1348 | 1120 | 84 | 144 |
| 죽은 코드("창 이동" 주석) | L2238~2314 | 77 | 0 | 67 | 10 |
| 데모 | L2316~2348 | 33 | 27 | 5 | 1 |
| **합계** | | **2348** | **1813** | **261** | **274** |

Classic 이식(`src/ColorPicker/Classic/`) — 부품 하나에 파일 하나:

| 파일 | 전체 | 코드 | 주석 | 빈 줄 | 맡은 일 |
|---|---|---|---|---|---|
| `Model.luau` | 222 | 183 | 21 | 18 | 상태 전부(`Source<HSV>`, 파생, 쓰기 함수) |
| `HueSlider.luau` | 219 | 178 | 26 | 15 | 무지개 슬라이더 + 말풍선 |
| `SVField.luau` | 130 | 106 | 13 | 11 | 채도/명도 사각형 + 커서 |
| `EditRow.luau` | 203 | 167 | 23 | 13 | 박스 7개(HSV·RGB·HEX 줄) |
| `ConfirmBar.luau` | 139 | 114 | 16 | 9 | 미리보기 + 취소/선택 |
| `Window.luau` | 90 | 70 | 12 | 8 | 제목줄 + 창 그림자 |
| `FakeCursor.luau` | 98 | 71 | 20 | 7 | 가짜 커서(두 컨트롤이 공유) |
| `Themes.luau` | 91 | 77 | 7 | 7 | 라이트/다크 팔레트 |
| `Anim.luau` | 29 | 17 | 8 | 4 | 트윈 어휘 두 함수 |
| `init.luau` | 111 | 67 | 35 | 9 | 조립 |
| 코어 합계 | 1332 | 1050 | 181 | 101 | |
| `Demo.luau` | 59 | 42 | 11 | 6 | 원본 데모 |
| `../ColorModel.luau` | 351 | 225 | 87 | 39 | 순수 색 수학(엔진 비의존, `luau` CLI로 테스트) |

Material 재설계(`src/ColorPicker/`):

| 파일 | 전체 | 코드 | 주석 | 빈 줄 | 맡은 일 |
|---|---|---|---|---|---|
| `Material/Model.luau` | 313 | 248 | 41 | 24 | 상태·쓰기 함수·`Value` 양방향 동기화 |
| `Material/SVArea.luau` | 195 | 162 | 22 | 11 | SV 영역 + 썸 |
| `Material/HueSlider.luau` | 183 | 155 | 18 | 10 | 색조 슬라이더(kit Slider 모양) |
| `Material/Fields.luau` | 233 | 197 | 25 | 11 | RGB/HSV 토글 + 숫자 박스 셋 |
| `Material/Swatches.luau` | 207 | 169 | 24 | 14 | 프리셋 + 최근 색 |
| `Material/HexField.luau` | 70 | 44 | 20 | 6 | kit `TextField` 바인딩 |
| `Material/Preview.luau` | 54 | 39 | 10 | 5 | 현재/초기 미리보기 |
| `../KeyNav.luau`(키트 공용, 2026-10-05에 `Material/`에서 옮김) | 170 | 120 | 43 | 7 | 키보드/게임패드 훅(핀 모드 넷·Engage) |
| `init.luau` | 257 | 178 | 69 | 10 | `Panel`·`Modal`·재수출 |
| 합계 | 1682 | 1312 | 272 | 98 | |

Material은 kit의 공유 부품을 쓴다(한 번 써서 모든 컴포넌트가 나눠 쓰는 것이라 위 합계에 넣지 않았다): `Interaction.luau`(290줄, 코드 209),
`Interactive`·`StateLayer`·`Util`·`Theme`·`Tokens`, hex 필드의 `TextField`(7개 파일 합 약 910줄), 모달의 `Dialog`(379줄)와 `Overlay`(493줄).
원본은 이 모든 것을 컬러피커 안에 직접 짠다 — 그림자 8조각 이미지, 버튼 딤 오버레이, 입력 정규화가 그 예다.

**정직한 해석.** Material 코드 줄(1312)은 Classic 코어(1050)보다 많다 — 기능이 많아서다(위 요약의 첫째 읽는 법). 원본 대비 "줄이 줄었다"는
주장은 Classic에 대해서만 한다.

## (b) 책임 분리

원본의 세 클래스는 각각 같은 다섯 가지를 한 클래스에 섞어 쥔다 — **생성 · 입력 · 애니메이션 · 상태 동기화 · 정리**. 분석 문서의 책임별
집계(`docs/colorpicker-original-analysis.md` 1.2절)로 2348줄이 이렇게 갈린다:

| 책임 | 원본 줄(약) | 원본 위치 | 이식에서 |
|---|---|---|---|
| 인스턴스 생성 | 696 | `huePicker.__initSlider` L163~269, SV `__initSVField`·`__initCursor` L643~718, HSV 창·편집줄·확인줄 L1245~1757 | 선언(`D.Frame { … }`)이 곧 생성 — 파일당 한 부품의 반환식 |
| 입력 처리(드래그 연결 설치/해제, 좌표→비율) | 144 | hue L379~448, SV L814~887 | `Interaction.drag`(kit 공유, 한 번) + 부품당 `apply` 함수 하나 |
| 가짜 커서 | 80 | hue L324~365, SV L772~812 — 거의 복붙 | `FakeCursor.luau` 한 파일을 두 컨트롤이 공유(Classic) / Material은 필요 없음(썸이 포인터를 가리지 않는 모양) |
| 애니메이션 | 170 | hue L271~322, SV L720~736, 버튼 L2075~2173 | 값이 바뀌면 `:Apply(q.Animate{…})` — 취소·파기는 quad가 한다 |
| 파츠 간 상태 동기화 | 560 | `setColor*` L1208~1230 외, `__updateEditBoxs` L1761~1800, 핸들러 L1860~2196 | **0줄** — 파생은 `:Compute`다(c절) |
| 텍스트 입력 정규화 | 57 | `__processText`/`__tabkeyProcess` L1801~1857 | `ColorModel.parseChannel`/`parseHex`(순수, 단위 테스트) |
| 정리(destroy) | 202 | 59 + 53 + 90 | `q.dispose(root)` |
| `fromInstance`(복제 UI 되살리기) | 94 | L54, L515, L1060 | 없음(필요 없다) |

이식 쪽의 분할은 위 두 표의 파일 목록 그대로다 — **시각 부품 하나당 파일 하나, 상태는 `Model` 하나, 모션은 `Anim`(Classic)**. 의존은 한 방향이다:
부품 파일은 `Model`의 쓰기 함수(`setHue`, `setSV`, …)를 부르고 `Model`의 State를 읽을 뿐 서로를 모른다(`SVField`와 `HueSlider`는 서로 import하지
않는다). 원본에서는 `HSVColorPicker.__setupHandlers`가 두 하위 클래스의 `onUpdate` 필드에 함수를 덮어써 붙이므로(원본 L1862, L1874) 부모가 자식의
내부 순서를 알아야 한다.

## (c) 상태 흐름

### 원본: 손으로 연결한 동기화 경로

같은 색이 여섯 군데에 복사돼 산다(분석 문서 2.1절): `HSVColorPicker.hue/saturation/brightness/color`, `huePicker.hue`,
`saturationBrightnessPicker.hue/saturation/brightness/color/X/Y`, 박스 일곱 개의 `.Text`와 각 `xxxLastText`(7개)·`xxxUpdateIgnore`(7개 이름,
코드에 41번 등장), GUI 프로퍼티 자체(`fromInstance`가 거꾸로 읽는다), `lastColor`.

```
 hue 드래그 ─► huePicker:update (L147) ─► onUpdate 필드 (L153)
                  │                        └► [HSVColorPicker L1862]
                  │                            saturationBrightnessHandler:setHue
                  │                            self.color = ...  self.hue = ...
                  │                            __updateEditBoxs()   (L1761: 박스 7개를 비교·쓰기, UpdateIgnore 플래그 7개 설정)
                  │                            __updatePreview()    (L2231)
                  │                            self:onUpdate(...)   (외부)
 SV 드래그 ─► saturationBrightnessPicker:update (L592) ─► onUpdate (L607) ─► [L1874] 위와 같은 꼬리
 H 박스 입력 ─► GetPropertyChangedSignal("Text") ─► task.wait() ─► UpdateIgnore 검사 ─► __processText
                  ─► hueHandler:setHue ─► sbHandler:setHue ─► self.hue/self.color 복사 ─► 외부 onUpdate (L1908)
                  [__updateEditBoxs·__updatePreview를 부르지 않는다 → 미리보기가 갱신 안 됨]
 S/V 박스 ─► setColorByHSV + 복사 + onUpdate  [미리보기 갱신 없음]
 R/G/B 박스 ─► Color3.new ─► setColor ─► Color3:ToHSV()  ◄── 색조 손실 지점 (L621, L1209, L2045)
 HEX 박스 ─► Color3.fromHex ─► 같은 setColor 경로
 취소 ─► self.color = lastColor ─► __updateEditBoxs()  ◄── 이때 self.hue/saturation/brightness는 아직 옛 값 (L2216~2224)
                                   └► 그 뒤에야 setColor 계열이 hue/saturation/brightness를 갱신
```

`__update*` 16곳, `setColor*` 16곳, `UpdateIgnore` 41곳이 이 그림의 화살표다. 화살표마다 "누가 누구를 부르고 무엇을 갱신하는가"가 호출 지점의
기억에 달려 있다 — 그래서 빠뜨린 화살표가 실제로 있다(H/S/V 박스가 미리보기를 안 바꿈, 취소가 박스에 옛 HSV를 씀).

### quad: 하나의 `Source<HSV>`에서 갈라지는 `:Compute` 그래프

```
                    ┌───────────────────────────── 쓰기는 commit 한 곳 (Material/Model.luau:151, equalsHSV 가드)
 hue 슬라이더 setHue ┤
 SV 영역    setSV  ─┤
 키 nudge*          ├─► hsv : Source<HSV>  ──┬─► color : State<Color3> ─┬─► 썸 채움·미리보기 오른쪽 절반
 hex 필드   setHex ─┤   (유일한 진실)        │                          ├─► hex : State<string> ─► (Effect) hexText ─► TextField
 숫자 박스  typeField┤                        │                          └─► (Value 있으면) Sync Effect ⇄ Source<Color3>
 스와치     setColor┘                        ├─► hue : State<number> ─► hueColor ─► SV 배경, 핸들 채움
                                             ├─► ringGray ─► 썸 링
                                             ├─► thumbPos = (S, 1−V) ; haloPos = (H, 0.5)
                                             └─► fieldText[i] / fieldLabel[i]  (mode : Source 도 의존)
 initial : State<Color3> ─► Preview 왼쪽 절반
```

쓰기는 한 곳(`commit`)이고 읽기는 전부 `:Compute`다. 새 화면 요소를 더해도 "다른 부품을 부르는" 줄을 쓰지 않는다 — 그 요소가 State를 읽으면 끝이다.
순서 문제(취소가 박스를 옛 값으로 씀)나 빠뜨린 갱신(미리보기)이 **구조상 생길 자리가 없다**: 박스의 표시 텍스트는
`shown = focused ? buffer : modelText`(`Material/Fields.luau:107`)이고 `modelText`는 `hsv`의 파생이라, 박스를 직접 쓰는 코드가 없다.
`UpdateIgnore` 7개가 하던 "자기 쓰기가 되돌아와 다시 처리되는 것"의 차단은, 모델 텍스트와 다를 때만 커밋하는 비교 한 줄
(`v ~= modelText:Get()`, `Fields.luau:159`)이 맡는다.

**밖과의 동기화(Material의 `Value: Source<Color3>`)**는 그래프의 유일한 순환 후보다. 옵저버 대신 `Effect` 하나(`Material/Model.luau:258`)가
`hsv`(그 파생 `color`와 마름모를 이룬다)와 바깥 Source를 같이 의존하고 — 같으면 끝, 바깥이 마지막으로 본 값과 달라졌으면 `fromColor3(c, 이전HSV)`로 끌어오고
(회색은 색조 유지, 검정은 색조·채도 유지), 아니면 우리 쪽 변경이므로 `:SetIfChanged`로 밀어낸다. 자기 직접 의존(`hsv`·바깥 Source)을 쓰는 `Effect`의 정의된 재실행 한 번으로
수렴한다(헤더에 이유 정리).

## (d) 수명·정리

| 호출 | 원본 | Classic | Material |
|---|---|---|---|
| `:Connect(` (코드 줄) | 46 | 0 | 5 |
| `:Disconnect(` | 19 | 0 | 1 |
| `TweenService:Create` | 16 | 0 | 0 |
| `:TweenPosition` / `:TweenSize` | 4 / 4 | 0 | 0 |
| `:Cancel()` | 21 | 0 | 0 |
| `:Destroy()` | 28 | 0 | 0 |
| `task.wait` | 7 | 0 | 0 |
| `GetPropertyChangedSignal` | 7 | 0 | 0 |

**어디에 연결이 사는가.** 원본은 창 하나에 상시 연결 35개(박스 텍스트 7 + 휠 12 + 버튼 호버 등)를 `handleConnections` 배열에 손으로 모으고
(원본 L1860 이하), 드래그 한 번마다 `InputEnded`/`InputChanged`/`WindowFocusReleased`/`MenuOpened` 네 개를 추가로 걸어 끊는다
(`huePicker:__inputEnded` L381~415, SV는 L816~852 — 연결 네 개를 끊는 8줄짜리 블록이 클래스마다 둘씩 복붙돼 있다).
quad 쪽은 둘로 갈린다. (1) **전역 신호**(`UserInputService`)에 거는 연결은 kit의 `Interaction.drag` 한 곳이 소유하고, 드래그 중에만 세 개를
열며 끝/포커스 상실/요소 파괴 세 경로가 **같은 `finish` 한 곳**으로 나간다(`src/Interaction.luau:198~212`, 파괴는 `:271`). 컬러피커 코드는 그 연결을 보지도
못한다. (2) **요소 신호**(`MouseEnter`, `Activated` 등)는 그 요소의 수명에 묶여 요소가 죽을 때 같이 간다 — 코드에 해제가 없다.
유일한 직접 연결은 키트 공용 `KeyNav`(`src/KeyNav.luau`, Slider·날짜 칸·색상 선택기가 같이 씀)(키보드 선택 중에만 `InputBegan` 하나)인데, 이것도 `SelectionLost`와 `Destroying`에서 같은 `close`로 닫힌다
(`src/KeyNav.luau`).

**정리 방법.** 원본은 `destroy(removeInstances)`가 클래스마다 있고(59 + 53 + 90줄, 원본 L75, L536, L1116) 연결 끊기 → 트윈 취소·파기 → 필드 nil 대입 →
인스턴스 `Destroy`를 손으로 한다. quad는 `q.dispose(root)` 한 줄이고, 스펙이 그것을 직접 검증한다: 드래그 도중·키보드 선택 도중에 파괴해도
`UserInputService`의 연결 수가 기준선으로 돌아오고(`test/spec.colorpicker.luau`의 "dispose mid-drag" 섹션, Classic은 "focus loss and destroy mid-drag"),
가상 시계의 대기 타이머가 0이다.

**측정 한 가지(좋지 않은 쪽).** 요소에 묶인 엔진 이벤트 연결(이벤트 + `Destroying`, 프로퍼티 변경 신호 제외)을 Lune에서 창 하나에 대해 센 값은
**Classic 55개, Material 118개**다(2026-10-05 재측정 — reflection의 이벤트 목록을 인스턴스마다 훑어 `Changed`류를 뺀 연결 수를 셌다. 원본의 상시 연결 35 + 텍스트 변경 7보다 많다). Material이 많은 이유는 스와치마다 `Interaction.new`(6개 연결)를 쓰기 때문이다
(8 스와치 × 6 = 48). 누수 위험은 아니다(요소와 함께 죽는다) — 다만 "연결 개수가 줄었다"고 말할 수는 없다. 줄어든 것은 **내가 손으로 관리해야 하는 연결**이다.

## (e) 인스턴스 수 (창 하나)

| | 원본 | Classic | Material 패널 | Material 모달(전체) |
|---|---|---|---|---|
| 인스턴스(호스트 포함) | 88 (+ `StringValue` 1) | 81 | 107 | 136 |
| `UICorner` | 2 (SV만) | 13 | 23 | |
| `UIStroke` / `UIShadow` | 0 / 0 | 0 / 4 | 18 / 0 | |
| 이미지로 그린 것 | 라운드 사각형 전부(같은 9-slice id가 14곳) + 그림자 전부 | `ImageLabel` 6 | 0 | |
| `TextBox` | 7 | 7 | 4 | |
| `TextButton` | (SV 필드·취소·선택 등) | 3 | 10(토글 2 + 스와치 8) | |

(원본의 클래스별 세부는 분석 문서 1.3절: 창 프레임 12 중 그림자 9조각, SV 8, hue 11, 제목줄 5, 편집줄 14+14+6, 확인줄 17.)

Classic이 7개 적은 이유는 그림자 9조각을 `UIShadow` 하나로, 둥근 사각형 9-slice 이미지를 `UICorner`로, 버튼 딤 오버레이를 배경색 보간으로 바꿨기 때문이다(2026-10-07 색조 미리보기 물방울을 그림자와 형제로 두는 투명 틀 1개가 늘어 10 → 9 — 그림자가 물방울 위에 그려지던 Z 순서 수정; 같은 날 2차로 그 그림자를 손잡이 아래 층의 자기 틀(+`UIScale`)로 옮겨 9 → 7 — 손잡이의 자손이면 손잡이 원판 위에 그려져 구를 덮었다).
**Material이 Classic보다 28개 많은 것은 기능이다**: hex `TextField` 13(오류 표시 포함), 스와치 32(프리셋 8 × 3 + 줄 틀), RGB/HSV 토글 + 박스 29(Classic의 편집줄 셋은 합쳐 이만큼은 아니다),
`Interactive` 계층이 붙은 색조 슬라이더 11. 부품별: SV 영역 12, 색조 슬라이더 11, 미리보기 4, hex 13, 채널 29, 스와치 32, 접착 6(호스트·컨텐츠+리스트·값 줄+리스트·비활성 베일) —
`test/spec.colorpicker.luau` 첫 섹션이 합계를 단언한다. 최근 색은 스와치당 3개가 더 붙고 비어 있으면 0이다(`Slot:List`).

이 숫자가 보여 주는 것은 "인스턴스가 훨씬 적다"가 **아니다**. 보여 주는 것은 (1) 라운드 처리와 그림자가 한 줄 선언(`UICorner`/`UIShadow`)이 됐다는 것,
(2) 이미지 에셋 의존이 0이 됐다는 것, (3) 기능이 늘어도 개수가 같은 자릿수에 머문다는 것이다.

## (f) 원본의 결함: 구조상 불가능해진 것 대 그냥 고친 것

### quad의 구조가 **만들 수 없게 한** 것

1. **상태 복사본 불일치.** H/S/V 박스 입력이 미리보기를 갱신하지 않는 것(원본 L1885~1960의 핸들러는 `__updatePreview`를 부르지 않는다), 취소가 박스를 옛 HSV로
   쓰는 것(L2216 `__updateEditBoxs()`가 `hue/saturation/brightness` 갱신보다 먼저). 이식에서는 박스·미리보기·핸들·커서가 전부 `hsv`의 `:Compute`라
   "갱신을 부르는 줄"이 존재하지 않는다. (스펙: Classic "confirm / cancel / close", Material "preview".)
2. **`UpdateIgnore` 류 재진입 플래그와 박스 교차 오기입.** 7개 이름·41번의 사용 중 일부는 박스를 서로 바꿔 쓴다(분석 문서 2.4절: V 박스에서 Tab을 누르면 H 박스를 건드린다).
   이식은 박스 하나가 같은 함수(`NumberBox`/`EditBox`)의 인스턴스라 박스별 복붙 변형이 없고, 플래그 대신 `focused ? buffer : modelText` 한 식이다.
3. **반응형 콜백 안 yield(`task.wait` 7곳, 원본 L1893~2023).** quad의 `:Compute`·`Effect`·`q.OnChange` 콜백은 yield하지 않는다는 규약이라 그 우회(`task.wait`로 한 틱 미루기)를 쓰지 않는다.
   텍스트 정규화는 순수 함수(`parseChannel`)이고 즉시 반영·FocusLost 되쓰기로 대체됐다.
4. **드래그 종료 경로가 `true.Position`을 읽는 에러(원본 L414).** `__inputEnded(true)`가 마지막에 `InputObject.Position.X`를 읽는다 — 포커스 상실 경로(`true`)에는 `.Position`이 없다.
   `Interaction.drag`의 `finish(cancelled)`는 마지막 위치를 지역 변수(`lastX/lastY`)에 들고 있고 취소 경로는 위치 갱신을 하지 않는다(`src/Interaction.luau:198~212`). 에러가 날 코드 줄이 없다.
5. **연결 중복 등록.** 원본 L2177·L2187은 같은 `closeButton.MouseEnter`를 두 번 연결한다. 이식의 호버는 요소당 `Interaction.new` 훅 하나이고 훅은 일회용 `PreRef`라
   같은 훅 *값*을 두 번 놓으면 quad가 거부한다(`Quad0069`) — 같은 훅을 복붙해 두 번 놓는 실수는 막힌다(훅을 두 개 만들어 놓는 것까지 막는 건 아니다).
6. **`fromInstance` 혼동(원본 L1070: hue 슬라이더를 `saturationBrightnessPicker.fromInstance`로 복원, L1350: H 박스를 `"SBox"`로 이름 붙임).** `fromInstance`는 "GUI에서 상태를 거꾸로 읽는" 경로인데,
   quad에서는 GUI가 상태의 파생이라 거꾸로 읽을 일이 없다.
7. **트윈 취소 누락·핸들 필드.** 같은 프로퍼티에 새 값이 오면 이전 트윈을 취소하는 것은 quad가 한다 — 원본의 `Cancel`+`Destroy` 쌍 21곳과 `self.xxxTween` 필드가 코드에 없다.
8. **색조 손실(`Color3:ToHSV()` 재유도, 원본 L621·L1209·L2045 등 5곳).** 이것은 **구조라기보다 데이터 모델 결정**이다 — OOP에서도 `Source<HSV>` 같은 단일 진실을 둘 수 있다.
   다만 원본은 상태가 여섯 군데 복사돼 있어 고치려면 여섯 군데를 고쳐야 하고, 이식은 한 곳(`ColorModel.fromRGBPreservingHue`)이다. "단일 진실이 자연스러운 구조"가 이 수정을 쌌다고 말하는 것이 정확하다.
   스펙은 검정/회색/흰색을 거쳐도 색조가 유지되는지 직접 단언한다(Classic "hue drag", Material "hue drag + hue preservation", 외부 `Value` 쓰기 포함).

### 그냥 **고친** 것 (quad와 무관하게 OOP에서도 같은 수정이 가능)

- 매직 넘버 `inputPosY-36`(원본 L508, L529) → 드래그 추적기가 `AbsolutePosition` 좌표계로 계산(Material은 `Ripple.Config.PointerInset`으로 인셋 한 곳 설정).
- 닫기 버튼 × 아이콘이 `ImageTransparency = 1`로 영원히 투명(원본 L1274) → 호버에서 실제로 보이게(Classic). Material엔 닫기 버튼이 없다.
- H/S/V를 0~255로 표시 → Material 기본은 도/퍼센트(360/100/100), Classic은 원본 재현(`Scale.Legacy`).
- `%d` 절단(0.5 → 127) → 반올림(`ColorModel.toByte`).
- 휠이 빈 박스에서 에러(`tonumber(nil)`) → 파싱 실패는 커밋하지 않을 뿐.
- 드래그 끝에서 포인터와 핸들이 5 px까지 어긋남(패딩 무시 나눗셈) → 패딩을 뺀 영역에 매핑.
- `-5` → `5`로 바뀌던 입력 정규화 → 파싱 거부 + FocusLost 되쓰기.

## (g) quad 버전의 정직한 비용과 한계

- **학습 곡선.** 이식하는 동안 실제로 규칙을 밟을 뻔한 자리가 여럿이다 — `:Compute` 안의 쓰기 금지, Observer가 자기 상류를 쓰지 않기, 정적 자식은 호스트 수명에 묶임,
  `props.X or q.None`, 같은 훅은 한 요소에만. 규칙을 알면 코드가 짧아지지만 모르면 런타임 에러(`Quad0069` 등)나 `q.debug` 경고로 알게 된다. 외부 `Value: Source<Color3>` 동기화는
  특히 미묘하다: 자기 의존을 쓰는 `Effect` 하나로 수렴시키는 설계(`Material/Model.luau` 머리)는 "정의된 예외"에 기대므로 읽는 사람이 이유를 알아야 한다.
- **타입 마찰.** 이번 구현에서 만난 것은 (1) 컴포넌트가 `Frame`을 돌려주기 때문에 **Effect/훅을 호출자가 직접 배열부에 놓아야** 한다 — hex 필드가 `{ Field, Sync }` 쌍을 돌려주고
  패널이 `Sync`를 자기 호스트에 놓는 모양이 됐다(래퍼 인스턴스를 늘리지 않으려는 선택). (2) hex를 **글자 입력마다 반영하지 않는다**(blur/Enter에만 커밋). kit `TextField`에는 `OnChange`(사용자 편집 뒤)가 있지만, 거기서 모델에 쓰면 "f80"이 파싱되는 순간
  `model.hex`가 바뀌고 동기화 `Effect`가 `hexText`를 "#FF8800"으로 다시 써서 **입력 중인 글자를 덮어쓴다** — 선택이지 한계가 아니다. Observer로 모델에 쓰면 "자기 상류에 쓰기"가 되는 것도 같은 이유다. (3) `UIListLayout`은 동률 `LayoutOrder`의 순서를 믿을 수 없어 부품마다 `LayoutOrder` 프롭을 달아야 했다.
  (4) 프롭의 `Modifier` 타입은 kit `src/Quad.luau`가 재수출하는 `q.FrameModifier` 등으로 적으면 되고(`typeof(D.Modifier.Frame())` 재선언은 더 이상 없다), 남는 마찰은
  재수출이 없는 클래스의 `<Class>Modifier`를 kit이 하나씩 추가해야 한다는 것이다.
- **검증이 mock뿐이다.** 모든 스펙은 Lune의 mock 백엔드에서 돈다. 레이아웃 엔진이 없어 `AbsolutePosition/Size`를 손으로 넣고(`H.setAbs`) 트윈은 보간 없이 목표값만 쓴다.
  원본은 Studio에서 직접 눌러 본 코드이고 이식은 눌러 본 적이 없다 — 이 비대칭은 정직하게 불리한 쪽이다.
- **연결·인스턴스는 줄지 않았다**(d, e절). Material은 인스턴스 107, 요소 연결 118로 원본보다 많다. 개수가 아니라 **장부의 소유자**가 달라진 것이다.
- **quad가 더 어려운 것.** (1) 즉석 디버깅: 원본은 `print(self.color)`가 어디서든 통하지만, quad는 값이 `State` 핸들이라 `:Get()`을 써야 하고 `#handle`·`{handle}`은 조용히 쓰레기를 만든다.
  (2) 컴포넌트 밖에서 부품을 직접 만지는 지름길이 없다(`self.hBox.Text = ...` 같은 한 줄이 없다) — 의도지만 급할 때 답답하다. (3) 기존 인스턴스 트리를 읽어 상태를
  복원하는 `fromInstance` 류 접근이 설계상 없다.
- **파일이 많다.** 원본은 파일 하나를 위에서 아래로 읽으면 된다. 이식은 파일 9~12개를 건너뛰며 읽어야 하고, 한 부품의 모습을 알려면 `Model`과 `Interaction`과 `Style`을 같이 열어야 한다.

## (h) 아직 기기에서 확인할 것 (미완)

mock이 증명하지 못하는 것만 적는다. 전부 **Studio/실기기에서 눌러 봐야 한다**:

1. **포인터 좌표.** `Ripple.Config.PointerInset`(GUI 인셋) 설정이 필요한 ScreenGui 구성에서 SV 영역·색조 슬라이더의 눌림 위치가 맞는지, 터치에서도 같은지.
2. **UIGradient 두 겹 SV 영역**이 `UICorner` 12 px 모서리 안에서 깔끔히 잘리는지(두 오버레이가 각자 `UICorner`를 갖는다), 흰/검정 그라디언트의 `Transparency` 시퀀스 방향
   (`Rotation = 90`이 위→아래인지).
3. **썸 링**(`UIStroke`, Border 모드)이 원형 `UICorner` 위에서 둥글게 그려지는지, 링 회색 대비.
4. **키보드/게임패드.** `Selectable` + `SelectionGained` 동안만 연결되는 `InputBegan`(`KeyNav`)이 실제 게임패드 D-패드·방향키에서 값을 움직이는지 — 특히
   "엔진이 nav 키를 `processed`로 표시한다"는 전제(`KeyNav`는 기본으로 `processed`를 보지 않는다)가 기기에서 맞는지. 색조 슬라이더는 Left/Right만 `NextSelection*`로 자기에게 묶고(Up/Down은 이웃으로 이동),
   SV 영역은 A/Return으로 **Engage**해야 네 방향을 묶는다(그 전엔 선택이 자유롭게 빠져나간다). 날짜 격자는 `Pin = "None"`(D-패드는 엔진의 기하 선택에 맡겨 격자를 빠져나갈 수 있고, ButtonL1/R1이 이전/다음 달, 바깥 달 칸은 `Selectable = false`)이라 이 셋이 기기에서 그렇게 동작하는지 같이 본다. 모두 미검증.
5. **텍스트 박스.** Tab 문자(`\t`) 처리와 `CaptureFocus`/`ReleaseFocus` 포커스 이동, 포커스 중 hex 필드 되쓰기가 커서를 건드리지 않는지.
6. **스와치 줄 줄바꿈**(`UIListLayout.Wraps` + `AutomaticSize.Y`)과 다이얼로그 본문 안에서 패널의 자동 높이.
7. **`Dialog`(CanvasGroup) 안의 `UIStroke` 포커스 링 잘림**, 모달 진입/퇴장 모션과 패널 내부 트윈의 상호작용.
8. **색 일치.** 같은 `Color3`가 외부 Source ↔ 패널 ↔ hex 사이에서 8비트 반올림으로 한 단계 어긋나는 일이 없는지(스펙은 `1e-9` 허용 오차의 동일성과 hex 왕복을 확인했다).
9. **성능.** 드래그 중 `Source<HSV>`가 이벤트마다 3필드 테이블을 새로 만든다(`ColorModel` 머리에 적힌 비용) — 저사양 모바일에서의 체감은 실측 안 했다.

## 부록: 이 비교가 쓴 근거 파일

- 원본: 스크래치의 `script1_colorPicker_Frame_colorPicker.luau`(2348줄), 분석 `docs/colorpicker-original-analysis.md`.
- Classic: `src/ColorPicker/Classic/*`, `test/spec.colorpicker.classic.luau`.
- Material: `src/ColorPicker/init.luau`, `src/ColorPicker/Material/*`, `test/spec.colorpicker.luau`.
- 공유: `src/ColorPicker/ColorModel.luau`(+ `test/spec.pure.colormodel.luau`), `src/Interaction.luau`, `src/Dialog.luau`.
