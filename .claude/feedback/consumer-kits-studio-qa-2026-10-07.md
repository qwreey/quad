# 소비자 킷 Studio 눈 확인 QA — material 킷 (2026-10-07)

> **[2026-10-07 신설]** 사용자가 Studio(UI Labs/플레이)에서 material 킷을 직접 보고 준 관측 원문 정리. 처리 규칙(사용자): *"당장은 원인이 파악 되는건 고치고, 아닌건 qa목록으로 두자. 소비자 킷은 서브에이전트로 작업하자"* — Studio 샌드박스·MCP는 아직 개선 중이라 에이전트 실기기 확인 불가. 항목마다 상태(고침/원인 미상 — QA 대기)는 이 파일이 소스. 킷 이름은 가칭(`research/consumer-kits-plan.md`).

## 관측(사용자 원문 요지)

1. **RadioGroup 애니메이션 다운그레이드** — 사용자 옛 MaterialUI(`qwreey/qwreey.roblox.plugins` libs/MaterialUI)는 라디오 선택 모션을 **스프라이트 시트 이미지**로 싸서, 기본 방식으론 못 내는 "외곽이 중간에 살짝 붙으려 하는" 모션이 있었는데 이식에서 빠짐.
2. **Checkbox 애니메이션 다운그레이드** — 옛 것은 체크가 중간에서 시작되거나 오므려지는 모션이 있었는데 없음.
3. **label-for 연동 없음** — 체크박스의 라벨에 마우스를 올려도 체크박스 호버가 안 뜨고, 라벨을 눌러도 반응 없음.
4. **Switch 데모** — 스위치를 누르면 y축 공간이 늘었다(margin?) 줄어듦.
5. **Switch 눌림 모양** — 꺼진 상태에서 누르고 있으면 안쪽 동그라미가 너무 커져 아웃라인과 거의 닿음(같은 색이라 어색). 켜진(보라) 상태는 채워져 있어 괜찮음.
6. **Button 크기** — 버튼 크기들이 이상하고, 호버나 클릭 뒤 "정상처럼 보이는" 크기로 트윈됐다가 다시 돌아옴. **Theme 쪽 "Brand …" Outlined 버튼이 가장 심함** — 글자가 튀어나가고, 클릭하면 정상 크기가 됨. 사용자: 크기가 글자에 따라 바뀌는 게 기본이면 안 됨 — flex/list 레이아웃에선 편하겠지만 **사용자 정의 width**가 있어야(이미 있으면 괜찮음).
7. **Chip** — 텍스트에 fit된 느낌으로 너무 작아 글자가 거의 삐져나가 보임(버튼과 같은 부류일 수 있음).
8. **DatePicker** — (a) 선택된 날짜의 파란 부분이 왼쪽으로 튀어나옴, (b) V 모양 드롭다운 부분이 조금 이상, (c) 요일 헤더는 멀쩡한데 각 날짜 칸이 왼쪽으로 치우침(컨테이너 패딩 의심). 시간 피커는 아직 없음(범위 밖 — 기록만).
9. **ColorPicker Classic(사용자 원본 이식)** — 애니메이션으로 나오는 물방울 모양 요소보다 그림자가 더 위에 그려짐(Z 순서).
10. **TextField(filled)** — 플레이스홀더(라벨)가 세로 가운데가 아니라 약간 위. 클릭해 올라가는 위치는 괜찮음. Outlined도 같음. y축을 늘린 데모에선 자연스럽지만 기본 높이에선 비대칭.
11. **Select** — 열릴 때 앵커 위치가 이상해 왼쪽에 붙은 채 스케일링됨. 세모(드롭다운 화살표)가 너무 큼.

## 처리 상태

**[2026-10-07 처리 — 서브에이전트, 코드 읽기만(실기기 확인 없음)]** (킷 소스 경로는 doc-check 색인 밖이라 백틱 없이 적음.) 아래 "고침"도 Studio에서 다시 볼 때까지는 추정이 섞여 있다 — 각 항목의
"확인할 것"이 다음 눈 확인의 체크리스트다(킷 README 실기기 체크리스트 8·21·22·23에도 반영). 검증: `quad-roblox-material/test/run.sh` exit 0,
`doc-check.py` ERROR 0.

1. **고침(이식)** — 옛 MaterialUI `RadioButton_New`(`qwreey/qwreey.roblox.plugins@7b6552a:libs/MaterialUI/init.lua` 4733~4778행, 자원
   `resource.rbxmx`의 `RadioIcon`)는 이미지 `rbxassetid://4667411351` 한 장(40x40 프레임 10개를 가로로 붙인 시트, 20x20로 표시)의
   `ImageRectOffset`을 IntValue 트윈으로 0→9 프레임(0.2 s, Linear) 넘기고 색은 0.15 s 보간했다. 그대로 옮김: quad-roblox-material/src/Radio.luau의 Ring·Dot
   (5개)을 `Sprite` ImageLabel 하나로 바꾸고, 프레임은 선택이 바뀔 때만 Heartbeat 하나로 정수 프레임씩 넘긴다(되돌리면 지금 프레임에서 거꾸로).
   Radio 9 → 5 인스턴스. 확인할 것: 시트가 링 두께·점 크기를 M3와 같은 비율로 그리는지, 테마 색 물들임, 에셋이 로드 안 되는 환경(그때는 빈칸).
2. **고침(이식)** — 옛 `CheckBox_New`(같은 파일 2329~2420행)는 이미지가 아니라 **가장자리 막대 넷**(`Side.L/R/T/B`)을 0.15 s 동안 상자 안쪽
   40 %까지 키웠다가(옛 색, 테두리 이미지 +4 px), 중간에 상태·색을 바꾸고 0.15 s 동안 되돌리는 모션이었다 — 체크가 가운데부터 드러나고 해제는
   채움이 오므라든다. quad-roblox-material/src/Checkbox.luau에 같은 모션을 Frame 넷(`BarLeft/Right/Top/Bottom`, ZIndex 2)과 "보이는 모양"(`displayed`) 지연으로
   옮김(변화 중에만 Heartbeat 하나, 끼어든 변화는 지금 막대 폭에서 이어감). 체크 다리는 상자 가운데 기준 위치로 바꿔 부풀 때도 안 움직인다.
   Checkbox 10 → 14 인스턴스. 확인할 것: 막대가 체크 다리 위로 그려지는지(ZIndex), 0.3 s 리듬이 원본 느낌인지.
3. **고침** — 원인: Checkbox엔 라벨이 없었고 갤러리가 `Common.Labeled`(별도 TextLabel)로 옆에 붙여, 라벨은 컨트롤의 Interaction 훅이 걸린 호스트
   밖이었다(RadioGroup 라벨은 클릭만 따로 배선, 호버는 없음). 새 `Label` prop(Checkbox·Radio, 공유 quad-roblox-material/src/ControlLabel.luau): 라벨 TextLabel을
   컨트롤 호스트 버튼의 **자식**으로 두고 호스트를 AutomaticSize X로 키워, 라벨 위 호버·클릭이 곧 호스트의 호버·클릭이다. RadioGroup 행도 이걸로
   바꿈(행당 호스트 하나). 라벨에서 시작한 누름은 리플이 레이어 가운데서(quad-roblox-material/src/Ripple.luau press — 레이어 밖 좌표면 중심). 갤러리 Selection·
   Checkbox 스토리가 `Label`을 씀. **Switch는 아직 `Label` 없음**(호스트가 곧 트랙이라 구조 변경 필요 — 라벨 쪽(왼/오) 결정과 함께 후속).
4. **원인 미상 — QA 대기.** 코드상 스위치 호스트(52x32)와 스토리 홀더의 크기를 바꾸는 것은 없다. 가설: 누를 때 보이는 것은 M3 상태 레이어 —
   핸들을 따라가는 40 px 원(`Halo`, quad-roblox-material/src/Switch.luau 202~210행)이 32 px 트랙 위아래로 4 px씩 넘치고, 누르면 리플(CanvasGroup)까지 그 원 안에
   생겼다가 놓으면 페이드 — 이게 "y축이 늘었다 줄어듦"으로 보였을 수 있다(M3 설계대로라 버그가 아님 — 원을 트랙 높이로 줄일지는 사용자 판단).
   확인할 것: 늘어나는 것이 반투명 원(레이어)인지, 옆 요소가 실제로 밀리는지(레이아웃 이동이면 다른 원인).
5. **고침** — 원인: 눌림 핸들이 켜짐·꺼짐 모두 28 px인데, 꺼진 트랙은 2 px **안쪽** 테두리라 내부가 정확히 28 px — 핸들이 테두리에 닿았다(색도
   Outline 대 OnSurfaceVariant로 거의 같음). quad-roblox-material/src/Switch.luau `handleSize`: 꺼진 채 누르면 24 px(아이콘 있으면 26), 켜진 채는 28 그대로
   (M3와 다른 점으로 파일 머리에 기록).
6. **고침(원인 추정 포함)** — 원인: Button 호스트는 AutomaticSize X인데 그 안의 Content 프레임을 AnchorPoint/Position 0.5(스케일)로 가운데 두어,
   엔진이 계산 중인 바로 그 폭에 Content 위치가 기대는 순환이 있었다(quad-roblox-material/src/Button/init.luau 옛 191~196행). 여러 레이아웃 패스에 걸쳐 맞는 폭으로
   수렴하니 처음엔 글자가 삐져나오고 호버·클릭(재배치)마다 "트윈처럼" 폭이 바뀌는 관측과 맞는다. 고침: 자동 폭에선 Content를 (0,0)에 오프셋으로,
   아이콘 레이아웃도 Left 정렬(가운데 정렬도 같은 순환). 같은 모양이던 Extended FAB(quad-roblox-material/src/Button/FAB.luau)도. **사용자 정의 폭**: 새 `Width` prop
   (`number` = 픽셀, `UDim` = 부모 기준) — 고정 폭에선 Content가 채우고 UIListLayout이 라벨을 가운데. README·파일 머리·갤러리 Buttons("fixed
   width" 묶음)·Button 스토리에 반영. (Theme 스토리가 Button에 넘기던 무효 `LayoutOrder`도 `Modifier`로 고침.) 남은 가설: FontFace 비동기 로드 뒤
   AutomaticSize가 다시 안 도는 엔진 동작이 겹칠 수 있음 — 확인할 것: Brand outlined가 처음부터 맞는 폭인지, 호버·클릭 뒤 폭이 그대로인지.
7. **고침(원인 추정)** — 6과 같은 부류: Chip의 Content(AutomaticSize X)에 든 UIListLayout이 `HorizontalAlignment.Center`라, 레이아웃이 자식을 프레임
   폭 기준으로 놓고 그 폭을 AutomaticSize가 자식에서 다시 재는 순환 — 덜 수렴하면 패딩이 먹혀 글자에 딱 붙어 보인다. 고침: Left 정렬(quad-roblox-material/src/Chip/init.luau
   Content의 UIListLayout; 자동 폭이라 보이는 결과는 같다). 남은 것: Input 칩의 제거 버튼은 아직 호스트 폭 스케일(Position X = 1)로 놓인다(같은 부류,
   관측 안 됨). 확인할 것: 칩 좌우 16 px(아이콘 쪽 8 px) 패딩이 보이는지 — 여전히 붙으면 폰트 로드 가설.
8. (a)(c) **고침** — 원인: 요일 머리글은 x = 12(PAD)부터 놓는데 날짜 격자(`Days` 프레임)는 x = 0에 있어 모든 날짜 칸이 12 px 왼쪽으로 치우쳤다
   (quad-roblox-material/src/DatePicker/MonthView.luau 옛 225~229행). 격자를 PAD에 두고 폭을 7×48로 — 선택 날짜의 파란 원이 왼쪽으로 튀어나와 보인 것도 이 어긋남으로
   추정(Docked·Range·Modal 공통). (b) **원인 미상 — QA 대기**: V(▼) 드롭다운은 머리글 버튼(Text 변형 `Button`)의 라벨 글자 `" ▼"`라, 6의 버튼 폭
   순환 수정으로 같이 나아졌을 수 있다; 남으면 글리프 크기(LabelLarge 14 px의 ▼가 M3 화살표보다 큼)나 폰트 폴백 모양 — 확인할 것: 무엇이 "이상"한지
   (크기·위치·모양). 시간 피커는 범위 밖(기록만).
9. **고침** — 원인: 미리보기 물방울의 그림자(`BubbleShadow`)가 물방울 이미지의 **자식**이었다 — ZIndexBehavior Sibling에선 자식이 늘 부모 위에 그려진다
   (원본은 Global + 손 ZIndex로 아래에 뒀음). quad-roblox-material/src/ColorPicker/Classic/HueSlider.luau: 투명 틀(`PreviewBubble`, Visible·UIScale) 안에 그림자(ZIndex 1)와
   물방울 이미지(`BubbleImage`, ZIndex 2)를 형제로. 핸들 그림자도 핸들 아래로 명시(ZIndex 1/2 — 물방울은 핸들의 자손). 인스턴스 +1(창 78 → 79,
   `quad-roblox-material/docs/colorpicker-comparison.md` 갱신).
10. **고침(원인 추정)** — 원인: 쉬는 라벨을 y = 16에 두었는데 이는 BodyLarge의 24 px 줄 높이 상자를 가정한 값이고, 라벨은 AutomaticSize라 한 줄이면
    상자가 글자 크기(16 px)에 가까워 중심이 24(컨테이너 중심 28보다 4 px 위)에 왔다(quad-roblox-material/src/TextField/Container.luau `labelPos`). 고침: 라벨 `LineHeight = 1`로
    상자 = 글자 크기를 확정하고, 쉬는 위치를 한 줄 필드는 `Height/2 − 8`(기본 56 → 20), 여러 줄은 첫 줄(16) 그대로. 떠오른 위치는 사용자가 괜찮다고 해 그대로.
    확인할 것: Filled·Outlined 둘 다 쉬는 라벨이 세로 가운데인지, 떠오를 때 흔들림이 없는지.
11. **고침** — 앵커: 메뉴 패널이 AnchorPoint X 0(왼쪽 위 피벗)이라 UIScale 열림 애니메이션이 왼쪽에 붙은 채 커졌다(quad-roblox-material/src/Menu.luau 패널 프레임).
    위-가운데(뒤집히면 아래-가운데) 피벗으로. 또 Select가 메뉴에 폭을 안 넘겨 280 px 넘는 필드에선 메뉴가 좁아 왼쪽에 붙던 것도 필드 폭을 넘기게
    (quad-roblox-material/src/Select.luau). 화살표: `TrailingGlyph` TextSize 20 → 12(▼는 em 상자를 꽉 채워 20 px이면 M3 arrow_drop_down의 두 배; quad-roblox-material/src/TextField/Slots.luau).

## 2차 관측 (2026-10-07 오후 — 1차 처리 `f7e3d3f6` 뒤 사용자 Studio 확인, 원문 그대로)

**material 킷:**

> 체크박스가 체크가 진행될 때 네모모양이 되어버림. 약간 아웃라인이 뒤로 튀는건 맞는데, 사각으로 튀는건 아니여야함. 아마 옛날에 나는 아웃라인을 색 바꿔서 살짝만 키우는 방식으로 해결했고, 중간으로 오므리는 프레임을 여유롭게 잡아서 해결했던것 같아.
>
> 텍스트필드 아무곳을 누른다고 진행이 되진 않아버림. 채워진 텍스트, 아웃라인 필드면 아무런 곳에 누르면 포커스 될  것 같은데, 텍스트 부분 눌러야했음
>
> 다이얼로그 사라질 때 크기가 이상해지며 사라짐. 버튼 크기가 늘어?나는듯하게, 텍스트는 작아지는데 버튼이 여유롭게 사라지고, 바닥 페딩같은게 조금 이상하게 보이기도 하고, date picker 와 다르게 애매하게 사라지더라.
>
> range date selector 가 조금 이상함. 진한 선택부(시작 끝) 과 그 사이를 이어주는 애가 띄워져있음. 보통 그 연결부가 시작 끝 부분에서, 라운드 아래에 반 width 그린 프레임으로 색상을 연결해주던가 하는데, 비슷하게 필요할듯.
>
> 그리고 버튼들이 클릭 중에 크기가 커져. 리플 때문인가? date picker 부분의 연도 선택 전환 버튼 누르면 그렇게 되더라. 칩쪽도 그렇고 심해. width 가 들썩이는 느낌
>
> 그리고 가로로 있는 radio button 을 전환하고 누르면 y축으로 위치가 움직이더라. 그러고선 다시 돌아와
> 또 M3 정본엔 있지만 여기는 없는 슬라이더 ranged picker 가 없더라.
> 구글 M3 https://m3.material.io
> 보고 와도 돼
> List: static rows 쪽에서 y축으로 긴 선택지 있는데 그거 padding 없이 텍스트가 박스 경계와 딱 붙어있더라
>
> 그리고 roblox ui 요소엔 페이지네이션을 해주는게 있는데 안 쓴 이유가 있는가 궁금함. 모든걸 거쳐가고 모든게 UI로 보여서 최적화에 나빠서 이게 더 물론 좋아보이긴해.
>
> 그리고 로딩 서클은 옛 것도 남겨둘만도 한데, 최신 것, m3 의 모양이 바뀌며 돌아가는것이나 좀더 생동감 있게 웨이브 치며 차는 바도 존재는함

**devui 킷:** 사용자 *"dev ui 는 거의 퍼팩트 하더라. plot 쪽에 노란 영역이였나? 그게 width 를 다 안 채우긴 하던데, 원래 그런건지(의도인지) 만 보면 될듯. 라이트 모드에서 흰 텍스트인것도 있고 한 자잘한 문제가 보이고, 정적으로도 알 수 있겠는게 좀 있더라. 사소해."*

**엔진 관련 문항**(Q184·Q185 등): 사용자 *"엔진 관련 답은 나도 확실히 확답 못하겠는게 있어서. rojo/ 새로운 mcp 준비되면 줄게."* — 실기기 도구 대기.

## 2차 처리 상태

**[2026-10-07 오후 처리 — 서브에이전트, 코드 읽기와 목(mock) 스펙만(실기기 확인 없음)]** 킷 소스 경로는 doc-check 색인 밖이라 백틱 없이 적는다. 검증: quad-roblox-material/test/run.sh exit 0, `doc-check.py` ERROR 0. 킷 README 실기기 체크리스트 24~30이 아래 "Studio에서 볼 점"의 표 형태다. 2차 관측의 다섯(체크박스 제외 1·3·5·6과 1차 4번 Switch)은 **같은 원인 하나**로 묶였다 — 아래 5번.

1. **고침(옛 소스 재확인)** — 체크박스가 토글 중 각진 네모로 보이던 것. 원인: 1차 이식이 오므리는 막대 넷을 상자 **가장자리부터**(둥근 모서리와 2 px 외곽선 위) 키워, 막대의 직각 모서리가 둥근 모서리를 덮었다. 옛 MaterialUI(`qwreey/qwreey.roblox.plugins@7b6552a:libs/MaterialUI/resource.rbxmx`의 `Class_CheckBox`)를 다시 보니 막대 틀 `Side`는 24 px 아이콘에서 사방 3 px 안쪽(외곽선 이미지 아래 층)에 있고, 부푸는 건 외곽선 이미지(`Box`, +4 px)뿐이었다 — 사용자 기억("아웃라인만 살짝 키우고, 오므리는 프레임을 여유롭게")과 같다. 고침: quad-roblox-material/src/Checkbox.luau — 막대 넷을 외곽선 **안쪽 가장자리**에 고정된 14 px 틀(`Bars`)에 넣었다. 외곽선 안쪽 모서리는 반경 2 − 두께 2 = 0이라 막대가 둥근 모서리에 닿지 않고, 상자가 2 px씩 부풀 때 틀은 그대로라 외곽선과 막대 사이에 틈이 벌어진다. 인스턴스 14 → 15. Studio에서 볼 점: 토글 중 상자가 네모로 튀지 않고 외곽선만 살짝 부푸는지, 막대와 외곽선 사이 틈이 원본 느낌인지.
2. **고침** — TextField를 텍스트 부분만 눌러야 포커스되던 것. 원인: 편집 TextBox는 행의 패딩 안쪽 상자(라벨 있는 Filled에서 높이 24 px)만 덮고, 엔진은 자기 경계 안을 누를 때만 TextBox에 포커스를 준다 — 컨테이너의 누름 훅은 Select용 `OnClick`만 불렀다. 고침: quad-roblox-material/src/TextField/Field.luau — 컨테이너 누름이 끝나면(취소·비활성·읽기 전용 아님) `CaptureFocus()`(이미 포커스면 안 함). 스펙: Filled·Outlined 둘 다 컨테이너 클릭 포커스, 취소된 누름·비활성은 안 함. Studio에서 볼 점: 라벨·여백·아이콘 위 클릭이 입력을 시작하는지, TextBox 직접 클릭 때 커서 위치가 그대로인지(이중 포커스 없음).
3. **고침(주원인) + 정렬** — Dialog 닫힘에서 버튼이 커지는 듯하고 바닥 여백이 이상하던 것. DatePicker 모달과의 차이 둘: (a) 모달 카드는 고정 크기 360x569, Dialog 카드는 `AutomaticSize Y`라 안의 무엇이든 커지면 카드가 따라 커진다 — 액션 버튼을 누르면 그 버튼의 리플이 버튼 밖으로 자라(5번 원인) 버튼 폭·액션 줄 높이·카드 높이가 닫히는 동안 늘었다(바닥 여백이 늘어 보인 것). (b) 모달은 닫힐 때 .92로 작아지며 페이드, Dialog는 페이드만. 고침: 5번(리플 경계) + quad-roblox-material/src/Dialog.luau 닫힘에 .92 축소(모달과 같은 모양). "텍스트는 작아지는데"는 코드로 확정 못 했다 — 리플이 고쳐진 뒤에도 남으면 **원인 미상 — QA 대기**(CanvasGroup 텍스처 재할당이 의심 후보). Studio에서 볼 점: 버튼을 눌러 닫을 때 카드 크기·바닥 여백이 그대로인지, 글자 크기 변화가 남는지.
4. **고침** — 범위 날짜에서 시작·끝 원과 사이 띠가 떨어져 있던 것. 원인: 사이 날짜는 칸 폭 48 px로 넓혀 띠를 이루지만 시작·끝은 40 px 원이라 칸 여백 4 px만큼 띠와 떨어졌다(1차 파일 머리에 M3 편차로 적혀 있던 것). 고침: 상태 `RangeStart`/`RangeEnd`(모양은 Selected와 같음, quad-roblox-material/src/DatePicker/Status.luau의 `rangeEnds`가 보이는 달에서 시작·끝 칸을 찾음) + 월 격자마다 반쪽 띠 Frame 둘(`BandStart` 원 중심 → 칸 오른쪽 끝, `BandEnd` 칸 왼쪽 끝 → 원 중심, 칩 아래 층 — 범위 모드 칩 ZIndex 2). 하루짜리·미완성 범위에선 숨김. 인스턴스 +2(범위 선택기만). Studio에서 볼 점: 원 아래 반 폭 띠가 사이 띠와 틈 없이 이어지는지, 주의 끝(토요일 시작·일요일 끝)에서 모양.
5. **고침(원인 확정 — 엔진 동작)** — 누르는 동안 버튼·칩 폭이 들썩이던 것. 원인: 리플 원이 호스트 밖으로 자란다(누른 점에서 가장 먼 모서리까지의 반지름 — 40 px 높이 버튼이면 위아래로 30 px 넘게). CanvasGroup이 그림은 잘라 주지만 **`AutomaticSize`는 잘린 자손까지 크기에 넣는다**(엔진 동작, DevForum "AutomaticSize does not consider ClipDescendants in calculations"). 그래서 폭이 자동인 버튼·칩은 누르는 동안 넓어졌다(좁은 칩일수록 넘치는 비율이 커서 심함; DatePicker의 연도 전환은 Text 변형 Button). 1차의 자동 폭 고리 수정과는 별개의 원인이다. 고침: quad-roblox-material/src/Ripple.luau — 원을 매 프레임 **호스트 사각형에 자른 상자**로 그린다(작을 땐 원 그대로, 가장자리에 닿으면 자른 상자 + 반폭 둥글림, 가까운 모서리 → 먼 모서리 사이에 둥글림이 0으로 — 그 뒤는 그룹의 UICorner가 호스트 모양). 확장 0.45 s 동안만 Heartbeat 하나(리플마다), 인스턴스 수는 그대로 4. M3 편차: 가장자리에 잘린 원의 완만한 호 대신 반원 끝(확장 0.45 s 동안만 보임). 스펙: 매 프레임 호스트 안에 있음. **같은 원인으로 함께 풀릴 것**: 6번, 3번 (a), 1차 4번 Switch 눌림 시 y 공간 늘어남(헤일로 안 리플). Studio에서 볼 점: 칩·버튼·연도 전환 버튼을 누르고 있어도 폭이 그대로인지, 리플 모양이 거슬리지 않는지.
6. **고침(5번과 같은 원인)** — 가로 RadioGroup에서 누르면 y로 움직였다 돌아오던 것. 라디오 상태 레이어는 48 px 호스트 안 40 px인데 리플 원(지름 약 57 px)이 호스트 아래로 넘쳐, `AutomaticSize XY`인 그룹 줄이 누르는 동안 높아졌다. 1차의 `Label` 도입은 원인이 아니다(라벨 호스트는 X만 자동). 5번 고침으로 같이 풀림. (덧붙여 quad-roblox-material/src/Radio.luau 머리의 낡은 Ring/Dot 서술을 스프라이트 구조로 고쳤다.) Studio에서 볼 점: 가로 그룹 전환 중 옆 항목이 안 움직이는지.
7. **추가함** — `RangeSlider`(quad-roblox-material/src/Slider/Range.luau, 키트 루트 `Material.RangeSlider`, 타입 `RangeSliderProps`). Slider와 같은 클래식 모양에 손잡이 둘: `Start`/`End` Source(없으면 Min/Max), 누른 자리에서 가까운 손잡이를 끌고 서로를 못 넘음(겹친 상태에서 시작한 드래그는 첫 움직임 방향으로 손잡이를 고름), 이산이면 눈금이 손잡이 사이만 켜짐(Ticks에 `FracLow`), 호버는 포인터에 가까운 손잡이만, 값 라벨은 끄는 손잡이만. 키보드·게임패드는 선택 정지 하나(Slider와 같은 가로 고정) — 화살표 등은 "키 손잡이"를 움직이고 Return·KeypadEnter·게임패드 X가 다른 손잡이로 전환. `OnChange(start, end)`/`OnChangeEnd(start, end)`. 인스턴스 23. 스펙 spec.rangeslider(6절)·api 탐침·갤러리 Selection "Range slider" 묶음·스토리 RangeSlider·README. M3 편차: 손잡이 최소 간격 없음, 손잡이마다 따로 포커스하지 않음. Studio에서 볼 점: 드래그·겹친 손잡이 다시 벌리기·키 전환.
8. **고침** — List 정적 행 갤러리의 세로로 긴(세 줄) 항목에서 글자가 상자 경계에 붙던 것. 원인: 세 줄 행(88 px, 위아래 패딩 12)의 내용 칸은 64 px인데, 오버라인 16 + 헤드라인 24 + 두 줄 보조 40 = 80 px라 아래로 16 px 넘쳐 행 바닥에 닿았다. M3도 오버라인이 있으면 보조는 한 줄이다. 고침: quad-roblox-material/src/List.luau — 보조 두 줄은 오버라인이 없을 때만. 갤러리에 "오버라인 없는 세 줄"(두 줄 보조) 예를 추가, Drafts 문구 정정. 스펙: 세 줄 내용 합 ≤ 64. Studio에서 볼 점: Drafts·Archive 행의 위아래 여백.
9. **답** — 아래 "9번 답" 절.
10. **추가함(근사)** — 옛 `CircularProgress`는 그대로 두고 둘을 더했다. (a) `LoadingIndicator`(quad-roblox-material/src/Progress/LoadingIndicator.luau): M3 Expressive 로딩 표시. Roblox엔 경로 렌더가 없어 M3의 일곱 다각형 대신 **둥근 사각형 셋을 서로 돌려 겹친 합집합**으로 근사 — 0/30/60도면 12갈래 버스트·써니, 0/45도면 8갈래 쿠키, 정렬하면 둥근 사각형·알약·원. 오각형·쿠키 9처럼 홀수 갈래는 대응 없음. 타이밍은 M3 그대로(650 ms마다 모양 전환, 감쇠비 0.6 스프링 — 살짝 넘쳤다 자리 잡음, 전환마다 +90도, 4.666 s에 한 바퀴 상시 회전). `Size`(기본 48, 모양은 38/48), `Contained`(PrimaryContainer 원 위 OnPrimaryContainer). 인스턴스 8, 보이는 동안만 Heartbeat 하나. (b) `WavyProgress`(quad-roblox-material/src/Progress/Wavy.luau): M3 Expressive 물결 막대(확정만). 파장당 짧은 회전 Frame 8개로 사인파를 그리고, 한 파장 묶음들이 얹힌 띠를 매 프레임 위상만큼 밀어(쓰기 한 번) 물결이 흐른다. 채운 길이는 CanvasGroup으로 자른다(`ClipsDescendants`는 회전한 자손을 못 자름). 300 px 막대에 약 87 인스턴스, 보이는 동안 Heartbeat 하나. **무리라서 안 한 것**: 비확정 물결(창이 매 프레임 바뀌면 CanvasGroup 텍스처를 매 프레임 다시 잡아야 함 — 비확정은 `LinearProgress({})`), 물결 끝의 둥근 마감(CanvasGroup이 직각으로 자름). 스펙: 각 2절·api 탐침 둘·갤러리 Chips(진행 묶음에 Wavy·LoadingIndicator 둘)·Progress 스토리(`Contained` 컨트롤)·README. Studio에서 볼 점: 모양 전환이 M3 느낌에 가까운지, 사각형 겹침의 이음이 보이는지, 물결 선분 이음매에 틈·각이 보이는지, 부하.
11. **고침** — Classic 색상 선택기에서 위쪽 물방울의 그림자가 아래 원 손잡이(구) 위에 그려지던 것(조정자 추가 항목). 원인: 1차가 그림자를 물방울 이미지와 형제로 옮겼지만 둘 다 여전히 **손잡이(Handle)의 자손**이었다 — ZIndexBehavior Sibling에선 자손이 늘 부모 위에 그려지므로 그림자가 손잡이 흰 원판을 덮었다. 원본(Global)은 물방울 그림자를 슬라이더와 같은 ZIndex(손잡이보다 한 층 아래)에 두었다. 고침: quad-roblox-material/src/ColorPicker/Classic/HueSlider.luau — 그림자를 손잡이 밖, 슬라이더 층의 자기 틀(`PreviewShadow`, 같은 32x68 상자·같은 Visible·UIScale, ZIndex 1 < 손잡이 2)로 옮겼다. 물방울 이미지는 손잡이 안(위)에 그대로. 인스턴스 79 → 81(quad-roblox-material/docs/colorpicker-comparison.md 숫자·줄 수 갱신). Studio에서 볼 점: 끄는 동안 그림자가 구를 덮지 않고, 물방울과 그림자가 같이 커지고 같이 따라가는지.

**9번 답 — 왜 UIPageLayout(페이지 넘김 레이아웃)을 안 썼나.** 킷에서 "페이지"에 해당하는 자리는 넷이다. 사실부터: (1) DatePicker의 달 넘김 — 날짜 칸 42개(칸당 3, 월 격자 합 135)를 **한 번만** 만들고 달이 바뀌면 같은 칸의 글자·상태만 바꾼다(spec.datepicker "navigation keeps the same cell instances"). 이전·다음 달은 존재하지 않는다. (2) DatePicker 연도 목록 — ScrollingFrame에 보이는 줄 + 2줄만 만드는 창(window) 방식, 연도 범위와 무관하게 칩 27개(약 80 인스턴스). (3) 갤러리 탭 — 고른 구간만 만들고 떠나면 부순다(숨겨 두지 않음; 탭별 합계는 README "갤러리"). (4) List/ListData — 페이지 없이 전부 만든다(긴 목록은 how-to 03 창 방식 권장). Carousel 컴포넌트는 없다. 그러니 "모든 게 UI로 다 만들어져 있다"는 지금 구조엔 해당하지 않고, 오히려 반대다 — UIPageLayout은 **모든 페이지가 자식으로 동시에 있어야** 페이지를 배치하고 넘기므로, 달력에 쓰면 최소 이전·현재·다음 세 격자(405)를 상주시키거나 순환 재배치 꼼수가 필요하다. UIPageLayout을 쓰면 **얻는 것**: 엔진이 하는 넘김 트윈(TweenTime·EasingStyle), 터치 스와이프·게임패드·휠 넘김(TouchInputEnabled 등), 스냅, JumpTo/Next/Previous, Circular. **잃는 것**: 상주 인스턴스(위), 페이지 크기·위치를 레이아웃이 잡으므로 quad Slot/LayoutOrder 순서와 이중 관리, 그 레이아웃이 게임패드·터치 입력을 가져가 날짜 칸 D-패드 이동(KeyNav, L1/R1 달 넘김)과 충돌 가능, 열린 범위(1..9999년)엔 페이지를 다 만들 수 없음. 지금 구조가 잃은 것은 **달 넘김 슬라이드 애니메이션과 스와이프 제스처**다(M3는 달이 옆으로 밀림) — 필요하면 UIPageLayout 없이 격자 두 장(현재·들어오는 달)을 잠깐 겹쳐 밀어 넣는 방식이 인스턴스 135개 추가로 끝난다. 근거가 분명하지 않아 이번엔 구현하지 않았다(사용자 결정 몫).

**quad 쪽 의심**: 없음. 5번은 엔진(`AutomaticSize`) 동작이고 quad 패키지 소스는 건드리지 않았다.

## devui 처리 상태 (2026-10-07 오후 — 서브에이전트, 코드 읽기만, 커밋 `8998bcc3`)

- **Plot 노란 영역 — 의도 아님, 고침.** PlotHistogram 막대가 `UDim2.new(1/n, -1, …)`이라 n개 합이 플롯 폭보다 n px 짧았다(최대 60점 → 약 60 px 빔; 주석 의도 "막대 사이 1px 간격"이 누적 오차로 나옴). 오프셋 0으로 — 막대 사이 간격은 사라짐(Iris도 붙어 있음). Studio: 막대가 오른쪽 끝까지 차는지.
- **라이트 모드 흰 텍스트 — 고침.** 위젯 텍스트·아이콘은 전부 테마 토큰이었고, 원인은 Demo의 Style Editor 미리보기가 Scheme 없이 `Style.new`해 늘 Dark였던 것 — 라이브 Scheme·Density를 따르게. Studio: Light에서 미리보기 글씨가 검정인지, Density 변경을 따르는지.
- **툴팁 데모 노란 글씨 — 고침**(라이트 흰 팝업 위 대비) → 토큰 `PlotLinesHovered`.
- **판단 필요(안 고침)**: Light `TextDisabled`·파란 버튼 위 검정 글씨는 Dear ImGui 원본 Light 값, 스토리의 주황·Demo `TextColored` 연한 빨강은 예시 값이라 대비가 약해도 둠.

## 3차 처리 상태(진행 막대)

**[2026-10-07 저녁 처리 — 서브에이전트, 코드 읽기와 목(mock) 스펙만(실기기 확인 없음, Studio 확인은 메인이 따로)]** 사용자 원문: *"디터메이티브 프로그래시브바 좀 이상하더라 끝부분에 진한색 뭔가가 있음. 바 높이랑 같은데. 위쪽은 라운드 안지키고, 아래쪽 웨이브는 지키는 느낌. 그리고 웨이브 그림 뭐로 만들었는지 모르겠는데 해상도가 낮아"*, 같은 날 추가 *"ChipInput chipset 부분에서 뭔가 문제가 보여. 이거 리플이 약간 타원형으로 시작해서 커지더라."* 킷 소스 경로는 백틱 없이 적는다. 검증: quad-roblox-material/test/run.sh exit 0, `doc-check.py` ERROR 0.

1. **판정(안 고침 — M3 정본 그대로) + 원인 미상 일부** — "끝부분의 진한 것, 바 높이와 같음". 배치: Progress 스토리(세로 목록)와 갤러리 Chips "Progress: determinate" 둘 다 **위가 평평한 LinearProgress, 아래가 WavyProgress**다. 그 진한 것은 두 막대 모두 트랙 오른쪽 끝의 **stop indicator**(Primary 4x4 원, UICorner 반폭)다. M3 정본과 같다 — Compose 토큰(androidx `LinearProgressIndicatorTokens`): `StopSize 4.0.dp` = `TrackThickness 4.0.dp`, `StopTrailingSpace 0.0.dp`, `TrackActiveSpace 4.0.dp`; `drawStopIndicator`는 지름 min(stopSize, 트랙 높이)의 원을 트랙 끝 반폭 안쪽 중심에 그린다. 그래서 4 px 트랙에선 점이 트랙의 둥근 끝을 통째로 덮어 "바 높이만 한 진한 끝"으로 보인다(의도). **"위는 둥글지 않고 아래 웨이브 쪽은 둥글다"는 코드로 갈리지 않는다** — 두 위젯의 트랙·점은 같은 크기(4 px)·같은 UICorner·같은 앵커·같은 픽셀 정렬이다. 웨이브 쪽은 10 px 물결 옆이라 4 px 점이 상대적으로 작은 "점"으로 읽히고, 평평한 막대에선 점=막대 높이라 끝이 진하게 잘린 덩어리로 읽힐 가능성이 크다(4 px 원은 래스터에서 둥근 사각형에 가깝다) — **원인 미상 — QA 대기**. 끄거나(예: `StopIndicator = false` — Compose도 `drawStopIndicator` 람다를 받으므로 비울 수 있다; M3 지침이 점을 언제 빼도 되는지는 m3.material.io가 JS 페이지라 이번에 원문 확인 못 함) 더 작게 하려면 M3 편차라 사용자 결정 몫이다.
2. **고침(재구현)** — 웨이브 해상도가 낮던 것. 원인 후보 둘(실측으로 가르지 않음): (a) Roblox는 회전한 GuiObject 가장자리에 안티에일리어싱을 하지 않는다(DevForum "GUI Anti-Aliasing for Rotation", "Rotation causes frames' edges to be pixelated") — 옛 구현은 파장당 회전 Frame 8개 폴리라인이었다(분절 자체의 각은 처짐 0.23 px로 작아 주원인이 아님); (b) CanvasGroup은 오프스크린 텍스처로 그려지고 엔진이 그래픽 품질·메모리에 따라 해상도를 낮춘다(DevForum "CanvasGroups content is blurred!", "Is there anyway to get a consistent quality on Canvas Groups?"). 사용자 결정(이미지 에셋 직접 업로드)대로 **타일 이미지**로 바꿨다: 메인이 만든 텍스처 quad-roblox-material/assets/wavy-progress-512x128.png(한 파장, 안티에일리어싱된 흰 사인 선, 선 두께 = 높이 4/10, 진폭 3/10, 이음매 없이 반복)를 사용자가 올린 `rbxassetid://78445787165309`로 ImageLabel 하나(`Strip`, ScaleType Tile, TileSize = 파장 x 높이, ImageColor3 = Primary)가 그리고, 띠를 한 파장 넓게 깔아 매 프레임 Position만 밀어 흐른다(프레임당 쓰기 하나 그대로). 회전 자손이 없으니 채움 길이 클립은 CanvasGroup 대신 `ClipsDescendants` Frame(`Wave`) — 흐림 후보 (b)도 같이 사라진다. 비용: **300 px 막대 87 → 7 인스턴스, 폭과 무관**(옛 구현은 폭이 늘면 파장 묶음을 추가). 표면 변경: `Amplitude` prop 제거, 높이 = 2.5 x `Thickness`(기본 10)·진폭 = 0.75 x `Thickness`로 고정 비율(텍스처가 높이와 같이 늘어나므로), `Wavelength`는 타일을 가로로 늘인다(4 x 높이에서 벗어나면 경사가 바뀌고 가파른 선이 조금 가늘어 보임). 바꾼 파일: quad-roblox-material/src/Progress/Wavy.luau(머리 주석 HOW·Cost·Deviations), quad-roblox-material/test/spec.progress.luau(Wavy 절 — 타일·클립·7 인스턴스·흐름·Thickness/Wavelength), README(컴포넌트 표·체크리스트 29·M3 편차·외부 에셋 "둘"), NOTICE(텍스처는 이 키트용 생성물). M3 편차(그대로): 물결 끝이 클립에 직각으로 잘림, 0/100 % 근처 진폭 램프 없음.
3. **고침(원인 확정 — 코드)** — Input 칩(ChipSet)에서 리플이 살짝 타원으로 시작해 커지던 것. 원인 둘, 둘 다 quad-roblox-material/src/Ripple.luau의 2차 BOUNDED 계산: (a) **알약 모양** — 원이 호스트 가장자리에 잘리면 모서리 반경을 "잘린 상자의 반폭"으로 두었다. 32 px 칩을 가운데쯤 누르면 반경이 16 px를 넘는 순간(Quart Out은 0.45 s의 첫 8 %에 반경의 30 %를 가므로 약 2프레임) 위아래가 잘려 상자 높이 32·반경 16 = **알약**이 되고, 반경 둥글림이 0으로 줄기 시작하는 건 가장 가까운 모서리가 덮인 뒤(넓은 칩이면 반경 50 px 넘어서)라 확장 거의 전부가 알약(타원처럼 보임)이었다. (b) **픽셀 반올림** — 상자를 floor/ceil로 잡아 누른 점의 x·y 소수부가 다르면(ChipSet의 줄바꿈 UIListLayout처럼 레이아웃이 칩을 소수 위치에 두면) 잘리기 전 상자도 1~2 px 직사각형 = 첫 프레임부터 살짝 타원. Input 칩에서 두드러진 이유: 제거 버튼 자리(24 px)만큼 폭이 넓어 최종 반경이 크고 알약 구간이 길며, ChipSet 안 위치가 소수일 수 있다. 다른 칩도 높이 32라 (a)는 같이 있었고(짧은 칩일수록 알약이 짧아 덜 보임), 버튼(40 px)은 잘리는 시점이 한 프레임 늦다. 고침: 누른 점을 정수 픽셀로 스냅(잘리기 전 상자는 정사각 → UICorner 반폭 = 원), 모서리 반경은 상자 모서리마다 "원 호가 상자 변과 만나는 지점까지의 안쪽 거리"(`cutCorner`)의 최댓값 — 잘리지 않으면 원 반경, 위아래가 다 잘리면 잘린 현 끝까지의 작은 값(칩에 위아래가 잘린 원으로 보임), 가장 먼 모서리가 덮이면 0. 별도의 "가까운 모서리 → 먼 모서리" 감쇠는 이 식에 흡수돼 지웠다. 인스턴스 수 그대로(누름당 4). 스펙(quad-roblox-material/test/spec.ripple.luau): 소수 위치 100x32 호스트에서 잘리기 전 매 프레임 Size X == Y·반경 = 반폭, 위아래가 잘린 구간(반경 22~40)에서 반경이 `cutCorner` 범위 안·12 미만(알약이면 16), 끝은 호스트를 덮고 반경 0; `cutCorner` 순수 단언 셋. 남은 M3 편차(머리 주석): UICorner는 네 모서리 반경이 하나라 한쪽만 잘린 원(큰 호스트 위쪽을 누름)은 잘린 쪽 모서리도 둥글고(안 잘린 쪽이 이겨 원에 가깝게 유지), 큰 원의 잘린 변은 얕은 호 대신 직선 + 둥근 모서리.
4. **고침(추가) — 물결 양 끝 둥근 마감 + 100 %·`Wavy` 평탄화(진폭 스프라이트 시트)** — 사용자 원문(2026-10-07): *"그런데 아쉽게도 저 이미지에서는 끝 부분이 라운딩이 없어. 원형 프레임을 위에 올려서 그려낸 사인각과 유사하도록 높이를 조절해나가고, 앞쪽과 끝쪽에 놓는다면 어떨지 모르겠어."* 같은 날 범위 확장(메인 경유 사용자 제안): M3처럼 100 %에서 물결이 잦아들어 평평해지고, 물결을 켜고 끄는 boolean prop, 그 사이 전환은 메인이 만든 진폭 스프라이트 시트(quad-roblox-material/assets/wavy-progress-sheet-1024x960.png, 24칸 512x80, 열 우선 2열x12행, 생성기 quad-roblox-material/assets/gen-wave.py — 사용자가 `rbxassetid://111246664282863`으로 올림, 데칼이 아니라 이미지 id). **둥근 끝**: 지름 = `Thickness`인 원 Frame(UICorner 0.5) 둘(`Start`·`End`)을 클립 양 끝에 올려 매 프레임 사인 곡선 높이에 맞춘다 — 위상이 흐르므로 시작 캡도 오르내린다. 배치는 지시의 "x=0과 x=L에 캡 중심" 대신 **양 끝을 반지름 r만큼 안으로 들인 쪽**을 골랐다: `Wave`(채움 길이, 고정 높이, 트윈)가 클립 `Clip`(x = r … L − r)과 캡 둘(중심 x = r, `End`는 `Wave`의 (1, −r)이라 채움 트윈을 레이아웃으로 따라감 — 루프가 꺼져 있어도 x가 맞음)을 품는다. 근거: 선+캡이 정확히 [0, L]을 차지해 평평한 LinearProgress의 알약과 같고, 4 px 간격이 그대로이며, 호스트 왼쪽 밖으로 r만큼 삐져나가지 않는다. 곡선은 텍스처 규칙(PNG 실측으로 확인 — 선 두께는 곡선에 수직 0.4H, 가장 가파른 x=0에서 세로 폭 56.6/128 = 0.4H/cos 25.2°) 그대로 y(x) = 높이/2 − A·sin(2π((x − r)/파장 + slide/파장)), slide = 띠의 정수 픽셀 Position(UDim Offset은 정수라 캡도 실제로 그려진 위상을 씀), A = 0.75·Thickness·(1 − 화면의 시트 칸/23). 캡 y는 `Wave` 고정 높이의 Scale로 둔다(Offset이면 정수로 잘림 — 목에서 실제로 6.76 → 6). **클립 끝 = 캡 중심 판단**: 세로로 자른 띠의 모서리는 중심에서 r/cos(경사)만큼 위아래라 원 밖으로 최대 0.105r(기본 파장·최대 진폭의 경사 25.2°; 가로로 늘여도 세로 폭은 같아 어떤 `Wavelength`에서도 같은 상한) = Thickness 4에서 0.21 px, 6에서 0.32 px — 안티에일리어싱 안이라 그대로 둠; 반지름만큼 앞당기면 원의 왼쪽 끝이 한 점이라 홈이 생기고, 뒤로 미루면 모서리가 더 드러난다. 짧은 채움: L < 2r이면 클립을 숨기고 두 캡을 x = r에 겹쳐 점 하나(Thickness > 4면 간격을 최대 Thickness − 4 − L px 침범), L = 0이면 캡도 숨김(평평한 막대의 폭 0 알약과 같이 0 %에 아무것도 없음); 루프가 매 프레임 트윈 중인 L을 읽으므로 0으로 줄어드는 트윈 동안에도 둥근 끝 유지. **평탄화**: prop `Wavy`(boolean | State, 기본 true), 진폭 목표 = `Wavy`이고 Value < 1이면 최대, 아니면 평평. 전환은 Long2(0.5 s) × 남은 거리, 부풀 때 Standard(Quart Out)·잦아들 때 EmphasizedAccelerate(Quint In) — Compose `IncreasingAmplitudeAnimationSpec`/`DecreasingAmplitudeAnimationSpec`(androidx WavyProgressIndicator.kt, 둘 다 `MotionTokens.DurationLong2`)을 키트 이징 매핑에 얹음; 레벨을 시트 24칸으로 양자화하고 시트 칸은 State 하나가 모든 파장 ImageLabel의 ImageRectOffset에 묶임. 평평하고 채움 트윈이 끝나면 루프를 끊는다(보이지 않는 흐름을 돌릴 이유가 없음 — `Wavy = false` 막대는 Heartbeat 0); Value 변화·`Wavy` 켜짐·호스트 크기 변화가 깨운다. 위상 시계는 루프 재시작(Value가 바뀔 때마다 Effect가 다시 돎)을 넘어 이어져 물결이 튀지 않는다. **엔진 사실**: `ScaleType.Tile`은 ImageRect 부분 사각형을 반복하지 않는다(Roblox 스태프 답변, DevForum "ImageRectOffset/Size does not work with Tile ScaleType" t/3409510, 2025-02-06 — "as designed", UV wrapping) — 그래서 직전 단일 타일 ImageLabel을 버리고 파장마다 Stretch ImageLabel(`Period`, 폭이 늘면 ceil(폭/파장)+1까지 추가, 옛 폴리라인 구현의 증설 방식)을 띠(`Strip` Frame) 위에 깐다(사용자 결정: 한때 Tile로 시도 지시 → 스태프 답변 확인 뒤 Stretch 확정). 비용: 인스턴스 **7 → 12 + ceil(폭/파장) + 1(300 px에서 21, 폭에 비례)**; 프레임당 쓰기 **1 → 3**(띠·캡 둘 Position, 물결일 때), 전환 중 시트 칸이 바뀔 때마다 파장 수만큼 ImageRectOffset(전환당 최대 23번), 캡·클립 Visible은 0·2r를 넘을 때만; 평평하면 0. 바꾼 파일: quad-roblox-material/src/Progress/Wavy.luau(머리 주석 HOW·ROUND ENDS·AMPLITUDE·Cost·Deviations 재작성, `Wavy` prop, `frameRect`·`LAST` 내보냄), quad-roblox-material/test/spec.progress.luau(Wavy 두 절 — 구조·자손 수(레이아웃 전 파장 하나 12, 300 px 20 — 호스트 제외), 여러 프레임 동안 시작·끝 캡 y = 같은 위상의 사인 식, 채움 0.8에서 끝 캡, 짧은 채움 점·0 % 숨김, 숨김 중 정지; 시트 칸 매핑, `Wavy` 끄기·켜기 전환이 0→23·23→0으로 단조롭게 0.5 s 안에 끝남, Value 1 평탄화, 매 프레임 캡 y = 현재 칸의 A, 평평하면 루프가 잠들고 Value·`Wavy`·크기 변화로 깸, float32로 정확히 안 담기는 Value에서도 잠듦), README(컴포넌트 표·체크리스트 29·외부 에셋·M3 편차), NOTICE(시트도 이 키트용 생성물). 남은 M3 편차: 둥근 끝은 직각 자름 위에 원을 얹은 근사(1 px 미만), 진폭이 0 % 바로 위~100 % 바로 아래 내내 최대(Compose 기본 `indicatorAmplitude`는 10 % 이하·95 % 이상에서 평평 — 따를지는 사용자 결정), `Wavelength`가 4×높이에서 멀면 선의 수직 굵기가 `Thickness`에서 벗어나 캡이 약간 굵거나 가늘어 보임.

**Studio에서 볼 점**: (1) 평평한 막대·물결 막대의 끝 점이 같은 모양으로 보이는지, 평평한 쪽 끝이 여전히 "둥글지 않은 진한 덩어리"로 거슬리는지(거슬리면 점 끄기·축소는 사용자 결정). (2) 물결 선이 또렷하고 매끈한지, 파장 이음매에 틈·턱이 없는지, 흐름이 끊기지 않는지, `Thickness`를 바꿨을 때 비율(4번 뒤로 채움 끝은 직각이 아니라 둥근 캡). (3) Input 칩·짧은 칩·버튼을 가운데·가장자리에서 눌러 리플이 원으로 시작해 "위아래가 잘린 원"으로 자라는지(알약·타원이 아닌지), 누르는 동안 칩 폭이 그대로인지(2차 5번 회귀 없음). (4) 물결 양 끝 캡이 선 끝에 붙어 함께 오르내리는지(어긋남·틈·덧그림 없이; 캡 y는 Scale이라 서브픽셀 — 엔진이 정수로 붙이면 0.5 px 어긋날 수 있음), 채움 트윈 중 끝 캡이 클립 끝을 따라가는지(x는 레이아웃이라 정확, y는 그 프레임 Heartbeat에서 읽은 L 기준이라 트윈이 Heartbeat 뒤에 갱신되면 한 프레임 늦을 수 있음), 0 % 근처 점 하나 → 사라짐, 100 %·`Wavy = false`에서 0.5 s에 걸쳐 잦아들어 직선이 되고 다시 부풀어 오르는지, 시트 칸 경계에서 위아래 이웃 칸이 번져 보이지 않는지(마루·골이 칸 위아래 끝에 닿음 — 80 px 칸이 10 px로 줄어 1/8 px 정도라 안 보일 것으로 봄), 파장 ImageLabel 사이 이음매.

## 4차 처리 상태(원형 진행)

**[2026-10-07 밤 처리 — 서브에이전트, 코드와 목(mock) 스펙만(실기기 확인 없음, Studio는 사용자가 rojo로)]** 사용자 설계(원문 요지): *"1, 2, 4, 8, 16 … 도 짜리를 만들고 2진으로 조합해, 여러 사진을 올려 그림. 몇 px 단위는 일부러 오버래핑해서 비어 보이는 걸 막고. 두께는 얇은 것·중간·두꺼운 것·더 두꺼운 것 네 바리에이션. 반투명한 영역과 채운 영역은 M3에선 떨어져 있고 끝 부분이 라운드 — 라운드 프레임 4개를 섞어 넣는 식."* 킷 소스 경로는 백틱 없이 적는다.

1. **재구현** — CircularProgress를 UIStroke + UIGradient 반평면(끝이 각지고, 간격 없고, 비확정 최소 호 180°)에서 원호 조각 시트(이미지 id rbxassetid://107858841263712, 원본 quad-roblox-material/assets/circular-arc-sheet-960.png, 생성기 quad-roblox-material/assets/gen-arc.py)로 바꿨다. 새 파일 quad-roblox-material/src/Progress/Circular.luau(머리 주석이 규칙 소스), quad-roblox-material/src/Progress/init.luau에서 옛 반평면 코드를 지우고 다시 내보냄. 호 하나 = 시작각 a·길이 s를 s − 2(겹침)의 2진 조각으로 쪼개 a부터 이어 붙인다 — 각 조각은 앞 조각의 명목 끝에서 시작하므로 +2° 덧그림은 다음 조각 밑에 숨고, 마지막 조각의 덧그림이 정확히 a + s에서 끝난다(생성기 docstring은 "넘침은 캡이 덮는다"였지만, 캡은 중심에서 2° 지난 평평한 절단의 모서리를 못 덮어 200 px 얇은 고리에서 1 px 삐져나오므로 s − 2를 쪼개는 쪽으로 바꿈 — docstring에 한 줄 추가). 닫힌 고리(0 %의 트랙, 100 %의 표시)는 360을 쪼개 시작을 덮어 12시 이음매가 없고 캡이 없다. 둥근 캡 Frame은 호마다 둘(표시 양 끝·트랙 양 끝 = 넷), 지름 = 실제 그려진 두께(두께비 × 지름), 위치는 Scale로 (0.5 + ρ sin θ, 0.5 − ρ cos θ), ρ = (79 − 80 × 두께비) / 160. 조각 순서는 움직이지 않는 끝에서 큰 것부터(표시는 12시에서, 트랙은 고정된 끝 360 − 간격에서 거꾸로) — 값이 조금 바뀌면 작은 조각만 돈다. 비트마다 ImageLabel 하나를 늘 두고 안 쓰면 Visible = false, Rotation·Visible·캡 Position은 Lua에 캐시해 바뀔 때만 쓴다.
2. **M3 근거(androidx Compose material3 ProgressIndicator.kt·tokens, androidx-main)** — 확정: 12시 시작, 트랙 시작 = sweep + min(sweep, gapSweep), 트랙 길이 = 360 − sweep − 2 min(sweep, gapSweep), gapSweep = (gapSize 4 dp + strokeWidth) / (π × 지름) × 360(둥근 끝이 반 획씩 나가므로 획 두께를 더함), 트랙 색 SecondaryContainer, 원형엔 stop indicator 없음. 그대로 따르되 획은 실제 그려진 두께, 각도는 단계로 반올림(기본 40 / 4에서 22°, Compose 22.9°). 0 %: 표시 없음·트랙 닫힌 고리; 아주 작을 때: 표시는 점(캡만), 간격이 sweep으로 줄어 트랙 끝이 점에 닿음(Compose와 같음, 표시가 ZIndex 2로 위); 100 % 근처: 트랙이 점으로 줄었다가 360 − sweep − 2 간격 ≤ 0에서 사라짐(Compose는 음수 sweep을 그대로 drawArc에 넘김 — 여기선 0으로 자름, 편차); 100 %: 표시만 닫힌 고리. 비확정: 트랙 없음(circularIndeterminateTrackColor = Transparent), 6 s 주기에 꼬리 = 전역 회전 1080°(180°/s 선형) + 0·1.5·3·4.5 s에 0.3 s 동안 90° 건너뛰기, 호 길이 = 0.1 → 0.87 선형(0~3 s), 0.87 → 0.1 Standard(3~6 s). 건너뛰기는 **선형**으로 따랐다 — Compose의 `90f at 300 using EmphasizedDecelerate`는 KeyframesSpecConfig.using 정의상 300 ms에서 **시작하는** 구간(정지 구간)에 걸리고 키프레임 기본은 LinearEasing이라서(의도와 다를 수 있으나 적힌 대로).
3. **양자화·두께** — 각도 단계는 기본 2°, 중심선에서 2°가 2 px보다 길면 1°(두께비 0.05/0.10/0.15/0.20에서 지름 122/129/137/145 px 초과) — 한 단계가 끝을 1 px 넘게 옮기지 않게. 1° 조각은 단계 1에서만 만든다. 반올림은 끝 위치를 단계의 반까지 옮길 뿐 이음매를 만들지 않는다(캡이 조각과 같은 반올림 각에 놓이고 간격은 상수 한 각). `Thickness / Size`에서 가장 가까운 시트 두께를 고르고(같으면 얇은 쪽 — 24 / 3 = 0.125 → 0.10, 그려지는 획 2.4 px), 캡·간격은 그려진 두께 기준. 160 px 넘는 지름은 칸이 확대돼 가장자리가 무를 수 있다.
4. **값 변화** — 이전과 같은 Medium2(0.3 s)·Standard(키트 매핑 Quart Out)를 Lua가 Heartbeat에서 직접 보간(조각 배치를 매 프레임 다시 계산), 마운트·Visible·움직이는 중에만 루프(quad-roblox-material/src/Progress/Loop.luau), 도착하면 끊김. 도중 역전은 현재 위치에서 이어감. 마운트 안 됐거나 숨은 동안의 값 변화는 보일 때 이어서 그린다.
5. **비용** — 인스턴스: 확정 25(옛 14), 비확정 13(옛 12), 1° 단계에선 27·14. 프레임당 쓰기: 확정은 쉴 때 0(Heartbeat 없음), 트윈 중 2° 한 칸 움직일 때 평균 7.75·최대 19(올림이 모든 비트를 지날 때; 0~360 시뮬레이션), 비확정은 매 프레임 보이는 조각 ≤ 7 Rotation + 캡 2 Position + 호 길이가 비트를 넘을 때 Visible(옛 2). 부모 Frame 하나의 Rotation으로 줄이는 길은 부모 회전이 자식에 전해지는 것에 기대므로(실측 안 함) 쓰지 않았다.
6. **안 한 것** — 원형 물결(M3 Expressive): 사용자 "멀리 보고 있자" — 2진 조각으로는 호를 따라 위상이 이어지는 물결을 못 만들어 생성기부터 다시 생각해야 함. 머리 주석 Deviations에 한 줄.
7. 바꾼 파일: quad-roblox-material/src/Progress/Circular.luau(신규), quad-roblox-material/src/Progress/init.luau, quad-roblox-material/test/spec.progress.luau(원형 절 넷 — 순수 규칙(칸 매핑·두께 고르기·단계·간격·배치·비확정 자세), 0~360 모든 2° 단계에서 조각이 목표 각도를 정확히 덮고 ≤ 9개·캡이 끝 각도·간격 양쪽 같음·0/100 %, 큰 지름 1° 단계, 트윈 도중·도착 뒤 루프 정지·역전·숨김 중 정지·고정 끝의 256 조각 불변, 두께 넷, 비확정 200프레임 동안 호 36~314°·트랙 없음·숨김 정지·재개), quad-roblox-material/src/Gallery/ChipsTabsProgress.luau(두께 넷 줄), quad-roblox-material/stories/Progress.story.luau(두께 넷 줄, Thickness 슬라이더 제거), quad-roblox-material/README.md(컴포넌트 표·체크리스트 31·외부 에셋 셋·M3 편차), quad-roblox-material/NOTICE.md, quad-roblox-material/assets/gen-arc.py(docstring 한 줄).

**Studio에서 볼 점**: (1) 조각 이음매에 머리카락 틈이나 겹친 진한 줄이 없는지(겹침 2°의 반투명 가장자리가 두 번 칠해져 아주 살짝 진할 수 있음), 12시 닫힌 고리 이음매. (2) 끝 캡이 선 굵기와 같고 선 위에 붙어 있는지(삐져나온 모서리·턱 없음), 간격이 양쪽 같아 보이는지. (3) 160 px 칸이 40 px로 줄 때 선이 매끈한지(엔진의 이미지 축소 필터에 기댐 — 24 px에서 특히), 회전한 ImageLabel의 가장자리. (4) 값을 바꿀 때 끝이 0.3 s에 걸쳐 2° 단위로 미끄러지는 게 끊겨 보이지 않는지, 트랙이 점으로 줄었다가 사라지는 모양. (5) 비확정이 10 % ↔ 87 %로 늘었다 줄며 1.5 s마다 90° 건너뛰는 리듬(건너뛰기가 선형이라 딱딱해 보이면 감속 곡선으로 바꾸는 건 사용자 결정). (6) 두께 넷이 갤러리·스토리에서 구분되는지.

## 5차 처리 상태(시트 여백)

**[2026-10-07 처리 — 서브에이전트, 코드와 목(mock) 스펙만]** 사용자 Studio 관측: 칸을 빈틈없이 붙이면 텍스처 필터링이 이웃 칸을 섞어 끝부분에 티끌이 보임 → 여백을 넣은 새 시트 둘로 교체. 킷 소스 경로는 백틱 없이 적는다.

1. 물결 — quad-roblox-material/src/Progress/Wavy.luau: 시트 이미지 id rbxassetid://98909031866905(파일 quad-roblox-material/assets/wavy-progress-sheet-1024.png), 프레임 480×64, 칸 i → ImageRectOffset (512·(i // 12) + 16, 85·(i % 12) + 10). 높이·진폭·선 두께 식은 모두 표시 높이 대비 비율(2.5·Thickness, 0.3H, 0.4H)이라 텍스처 비율이 4:1에서 7.5:1로 바뀐 것은 Stretch가 흡수 — 식 변경 없음(기본 40×10 표시에서 가로 압축이 조금 더 커져 선 기울기가 가팔라 보일 수 있음, Studio에서 볼 점).
2. 원호 — quad-roblox-material/src/Progress/Circular.luau: 이미지 id rbxassetid://97823357785454(파일 quad-roblox-material/assets/circular-arc-sheet-1024.png), 칸 i → (170·(i // 6) + 5, 170·(i % 6) + 5), 160×160. 고리 기하 그대로.
3. 옛 시트 파일 둘 삭제, README·NOTICE·주석·스펙(quad-roblox-material/test/spec.progress.luau의 칸·프레임 매핑 단언)을 새 식·id로. 실기기 확인은 사용자 몫: 프레임 끝·조각 끝 티끌이 사라졌는지, 물결 선이 7.5:1 프레임에서 또렷한지.

- **[2026-10-07 후속]** 물결 시트를 4:1 표시 비율 기준 스트로크로 다시 그려 재업로드 — `rbxassetid://96568777229073`(이미지 id, 50.2 KiB; 직전 `98909031866905`는 같은 배치에 보정 전 스트로크라 경사에서 선이 최대 약 10 % 가늘었다).
