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
