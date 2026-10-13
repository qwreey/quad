# 소비자 킷 code-review — 추림·검증 결과 (opus, 2026-10-13)

대상: `quad-roblox-material`·`quad-roblox-devui`(HEAD `405ce844`). 입력은 sonnet 파인더 셋(devui 전체 / material 나머지 / material 오늘 새 코드 — 뒤의 것은 8번만)과 Gemini devui 보고(`/code/Projects/quad-agy/review-devui/AGY_REPORT.md`). **Gemini material 보고는 끝까지 없었다 — 메인이 따로 본다**(시작할 때, 검증 중간, 보고서 쓰기 직전 세 번 확인: `review-material2/AGY_REPORT.md` 없음).

사본: `…/scratchpad/review2/tri/base`(안 고친 대조 — 레포와 `diff -rq` 일치 확인)와 `tri/fix`(고친 것). 한 파일만 도는 실행기는 `tri/one.sh <base|fix> <킷> <test 아래 파일>`. 고침은 `…/scratchpad/review2/patches/`에 번호별 diff(`a/quad-roblox-…` 경로, `patch -p1`), 전부 합친 `all.diff`, 적용 순서 `ORDER.txt`, 스펙 파일 둘(`material.spec.reviewfix.luau`, `devui.spec.reviewfix.luau`). 번호별 diff를 순서대로, 그리고 `all.diff`를 한 번에, 레포 킷의 새 사본에 적용해 `tri/fix`와 같아지는 것을 확인했다. 레포는 건드리지 않았다(`git status` 비어 있음).

번호 규칙: material은 `M-`, devui는 `V-`, 뒤는 분류 글자와 순번. 스펙 절 이름은 material `R1`~`R5`(이미 있던 `A1`~`C1` 뒤에 붙임), devui `R1`~`R4`.

---

## material

### A. 확정 결함, 고침이 국소적

**M-A1. 닫히는 중(ExitTime)에도 내용이 눌려서 콜백이 두 번 이상 불린다 — 메뉴 항목, Select 옵션, 날짜·시간 모달의 OK, 대화 상자 액션, 스낵바 액션.** Overlay는 `Close()`가 불린 뒤 ExitTime(메뉴 0.1초, 그 밖 0.2초) 동안 내용을 그대로 두고 입력을 막지 않는다. 그 사이에 같은 자리를 한 번 더 누르면(더블 탭) 닫기는 멱등이라 조용히 지나가지만 사용자 콜백은 또 돈다. 결과는 부품마다 다르다: 메뉴 항목 `OnClick` 2회, Select는 `OnChange` 2회이고 둘째 탭이 다른 옵션이면 값도 그쪽으로 바뀐다(A → B), 날짜 모달은 OK 한 번 뒤 OK·날짜 칸·OK를 누르면 `OnConfirm` 3회에 닫힌 뒤 고른 날이 `Value`에 들어가고, Cancel 뒤 OK를 누르면 `OnCancel`과 `OnConfirm`이 둘 다 불리고 값이 써진다. 시간 모달도 같다(더블 OK 2회, Cancel 뒤 OK 커밋). 대화 상자는 액션의 `OnClick`이 두 번(머리 주석 예제의 `discard`가 두 번), Cancel 뒤 Discard도 실행된다. 스낵바는 액션 `OnClick`이 두 번("Undo" 두 번). 위치는 `Menu.luau` 133~141행(`activate`), `DatePicker/Modal.luau` 317~325행, `TimePicker/Modal.luau` 326~334행, `Dialog.luau` 389~394행, `Snackbar/View.luau` 85~88행. [실측] 스펙 R1 세 절이 안 고친 사본에서 전부 실패(하위 단언까지 따로 돌려 확인: 메뉴 2회, "Select: value B, OnChange 2", "OnConfirm ran 3 times", "cancelled: OnCancel 1, OnConfirm 1", "time OnConfirm ran 2 times", "Discard ran 2 times", "Undo ran 2 times"). 엔진에서 0.1~0.2초 안에 둘째 `Activated`가 실제로 오는지는 [추정]이지만 더블 탭·더블 클릭 간격이 그 안이다. 출처: mat-rest 1번(메뉴·Select·날짜 모달); 시간 모달·대화 상자·스낵바는 같은 뿌리를 따라가며 이번에 확인. **고침**(자리마다 한 줄 검사 — 새 이름 없음): 메뉴는 행에 넘기는 `close`가 "이미 닫혔으면 false"를 돌려주고 `activate`가 그때 돌아간다(스크림으로 닫은 뒤의 항목 탭도 같이 무시된다); 두 모달은 `onConfirm` 첫 줄에 `if not h.IsOpen:Get() then return end`; 대화 상자 액션은 `ovHandle.IsOpen`을 먼저 본다; 스낵바 액션은 `o.Closing:Get()`이면 돌아간다. 스낵바 쪽은 "타임아웃으로 사라지는 중에 누른 Undo"도 무시하게 되는데 정본과 같다 — Compose `SnackbarHost.kt`의 `performAction()`은 `if (continuation.isActive) continuation.resume(ActionPerformed)`라서 한 번 결정된 뒤에는 아무것도 하지 않는다(WebFetch로 확인, 153~161행 부근). Overlay 머리 주석 ExitTime 항목에 "내용은 그 시간 동안 눌린다, 자기 핸들러에서 `handle.IsOpen`을 볼 것" 세 줄을 넣었다. **이 고침이 닫지 못하는 것**은 M-B1(사용자가 넣은 내용). diff: `patches/M-A1.diff`.

**M-A2. 메뉴·Select의 메뉴가 앵커가 파괴된 뒤에도 열려 있다.** `Menu.open`은 앵커 위치를 열 때 한 번 읽을 뿐 앵커의 수명과 엮지 않는다. Select 필드나 `Menu.Button`이 화면 전환으로 파괴되면 메뉴와 투명 스크림이 그대로 남아, 다음 클릭 한 번을 스크림이 삼킬 때까지 화면 전체가 막힌다. 툴팁은 같은 상황을 `Destroying`으로 처리한다. 위치는 `Menu.luau` 244~411행(`open`), `Select.luau` 121~131행. [실측] 스펙 R2 절(안 고친 사본: "the menu closes with its anchor" 실패, 0.5초 뒤에도 스크림 있음; 파인더 프로브는 5초 뒤에도 Count 1). 출처: mat-rest 2번. **고침**: `open`이 핸들을 받은 뒤 `anchor.Destroying`에 `handle.Close`를 걸고, `OnClose`(닫힘 시작 — 어떤 경로든 한 번)에서 그 연결을 끊는다. 공개 표면은 그대로이고 머리 주석 `Anchor` 줄에 한 구절. diff: `patches/M-A2.diff`(같은 파일이라 M-A1 다음에 적용).

**M-A3. 끄는 도중 `Disabled`가 켜져도 스위치는 놓는 순간 값을 바꾸고, 색 선택기의 SV 영역·색상 막대는 계속 색을 쓴다.** `Interaction.drag`는 누르는 순간에만 `Disabled`를 본다. 스위치를 절반 넘게 끈 상태에서 `Disabled`가 참이 되고 손을 떼면 값이 바뀌고 `OnChange`가 불린다. 색 선택기는 `Disabled` 뒤의 이동·뗌이 `setSV`/`setHue`로 색을 계속 바꾸고 `OnChange`를 부른다. 어제 슬라이더에서 같은 것을 고쳤는데(`Slider/Behavior.luau` 331행의 `commit` 첫 줄) 이 셋이 빠져 있었다. 위치는 `Switch/Behavior.luau` 116~131행, `ColorPicker/Material/SVArea.luau` 61~75행, `ColorPicker/Material/HueSlider.luau` 61~72행. [실측] 스펙 R3 절(안 고친 사본: "switch: value true, OnChange 1", SV·색상 막대 단언도 따로 돌려 둘 다 실패 — 파인더는 색 선택기를 [추정]으로 적었고 이번에 실측). 출처: mat-rest 4번. **고침**: 스위치는 뗄 때 `Disabled`면 취소된 끌기처럼 원래 상태로 돌아간다(`if not cancelled and not disabled:Get()`); 두 색 영역은 값을 쓰는 한 길목(`apply`/`setFromX`) 첫 줄에서 `Disabled`면 돌아간다 — 슬라이더와 같은 방식. 끝 콜백을 부를지는 M-B2. diff: `patches/M-A3.diff`.

**M-A4. 색 선택기의 RGB/HSV 칸 — 정상적으로 친 값은 '최근 색'에 들어가지 않고, 거절된 글자를 남기고 떠날 때만 (바뀌지 않은) 현재 색이 들어간다.** 칸은 치는 동안 글자가 숫자로 읽히면 바로 커밋한다. 그래서 정상 편집 뒤에는 떠나는 순간 버퍼와 모델 글자가 이미 같고, `FocusLost`의 `if b ~= modelText:Get() then … model.remember() end`는 건너뛴다 — 기억은 버퍼가 모델과 다를 때, 곧 글자가 거절됐거나("abc", 빈 칸) 잘렸을 때("999" → 255)만 일어난다. 머리 주석의 "FocusLost -> final commit of an edited buffer, `model.remember()`"와 반대다. 위치는 `ColorPicker/Material/Fields.luau` 174~181행. [실측] 내 프로브(`tri/probes/material/probe.fields.luau`): "10"을 치고 떠남 → 최근 0개, "abc"를 치고 떠남 → 최근 1개(안 바뀐 색), 스펙 R4 절. 출처: mat-rest 7번이 "거절돼도 remember한다"까지만 적었고(파인더 제안대로 `typeField` 반환값만 보면 치는 동안 커밋된 색이 여전히 안 들어간다), 반대쪽은 이번에 찾았다. **고침**: 칸마다 "이 포커스 동안 커밋한 적이 있나" 플래그 하나 — 치는 중의 커밋이나 떠날 때의 커밋이 성공하면 참, 떠날 때 참이면 `remember()` 한 번. 포커스만 넣었다 뺀 경우와 거절된 글자만 친 경우는 기억하지 않는다. diff: `patches/M-A4.diff`.

**M-A5. 날짜 선택기의 Home/End는 줄 끝 날이 비활성이면 아무 일도 하지 않는다.** `reach`는 같은 이동을 반복해 선택 가능한 날을 찾는데, home/end는 두 번째 호출이 같은 날을 돌려주므로 바로 nil이 된다. 주말을 막은 설정(일요일 시작)에서 수요일에 Home을 누르면 선택이 그대로다. 머리 주석은 "skipping non-selectable dates by repeating the move"라고 적었지만 home/end에는 성립하지 않는다. 위치는 `DatePicker/MonthView.luau` 134~148행. [실측] 스펙 R5 절(안 고친 사본: "Home … -> Mon 12 (got 14)"). 정본: Compose `DatePicker.kt`에는 Home/End 처리가 없다(WebFetch로 앞 10만 자를 확인 — 날 칸은 방향키와 Tab만 다룬다; 끝 1만 8천 자는 못 읽음). 그러므로 이 키는 킷 자신의 규약이고, 고침은 그 머리 주석이 이미 말하는 것("비활성 날은 건너뛴다")을 home/end에서도 참으로 만드는 것이다. 출처: mat-rest 3번. **고침**: home/end는 줄 끝에서 시작해 포커스된 날 쪽으로 한 칸씩 돌아오며 처음 만나는 선택 가능한 날로 간다(최대 6칸, 없으면 그대로). Min/Max로 잘린 줄 끝도 같은 길로 처리된다. 머리 주석 한 구절. diff: `patches/M-A5.diff`.

### B. 확정 증상, 처방이 결정 사항

**M-B1. 닫히는 동안 '사용자가 넣은 내용'은 여전히 눌린다.** M-A1은 킷 자신의 활성화 자리만 막는다. `Overlay:Open`에 직접 넣은 내용, 모달 바텀·사이드 시트의 `Children`, 대화 상자의 인스턴스 본문 안 버튼은 ExitTime 동안 그대로 눌린다(시트의 손잡이·스크림은 이미 `IsOpen`/`Detach`로 막혀 있다 — 읽어서 확인). 갈래는 셋이다. 첫째, 지금처럼 두고 문서로 안내한다(M-A1에 넣은 Overlay 머리 주석 세 줄이 그것) — 비용 없음, 사용자 핸들러마다 검사가 필요하다. 둘째, Overlay가 닫힘이 시작되면 그 항목 맨 위에 투명 GuiButton 한 장을 얹는다("누름은 첫 GuiButton에서 멈춘다" 규칙으로 포인터 입력이 한 곳에서 막힘) — 닫히는 항목당 인스턴스 1개, 새 메커니즘이고, 게임패드·키보드 활성화는 덮개로 막히지 않아 M-A1의 검사는 그래도 필요하다. 셋째, 항목 Frame의 `Interactable = false` — 엔진 문서상 CanvasGroup만 자손에 전파하고 Frame은 아니어서 [추정] 통하지 않는다(미실측). **추천은 첫째**: 킷 부품은 M-A1로 닫혔고, 사용자 내용의 이중 발화가 실제로 보고되면 그때 둘째를 넣는다. 출처: mat-rest 1번의 제안 부분.

**M-B2. 끄는 도중 `Disabled`가 된 뒤 손을 떼면 끝 콜백은 그대로 불린다 — Slider `OnChangeEnd`, 색 선택기 `OnGestureEnd`와 '최근 색' 기억.** 값은 더 쓰이지 않지만(어제 A7, 오늘 M-A3) 뗄 때 `OnChangeEnd(value)`는 한 번 불린다. 위치는 `Slider/Behavior.luau` 362~369행, `SVArea.luau` 90~95행, `HueSlider.luau` 87~92행. [읽기] 어제 추림이 "고르지 않았다"고 남긴 그 물음이다. 갈래: 그대로 둔다 — `OnChangeEnd`는 값이 안 바뀐 끌기(같은 자리 누름·뗌)에도 지금 불리므로 계약이 "제스처가 끝났다"이고, 비활성 전에 바뀐 값의 '끝' 통지가 없어지면 "끝에서 저장"하는 앱이 그 값을 놓친다; 끝 시점에 `Disabled`면 건너뛴다 — 두 줄씩, 위 경우를 놓친다; `Interaction.drag`가 `Disabled`가 켜지는 순간 끌기를 취소한다 — 한 곳에서 닫히지만 drag가 `Disabled` State를 구독하는 새 메커니즘이고 킷의 모든 끌기(시트·목록 순서 바꾸기 포함) 동작이 바뀐다. **추천은 그대로 두고** 머리 주석에 한 문장: "`OnChangeEnd` fires when a drag ends, also when `Disabled` was set meanwhile (it then reports the last value written before that)". 출처: mat-new 8번.

### C. 실기기 확인 필요

**M-C1. 날짜 칸에서 Enter가 두 번 고르기가 될 수 있다.** `MonthView.onKey`는 Return/KeypadEnter에서 `OnPick`을 부르고 `processed`를 보지 않는다(176행). 엔진이 선택된 GuiButton에 Return으로도 `Activated`를 내면 칩의 `Activated`(`DatePicker/Chip.luau` 233~238행)가 `OnPick`을 한 번 더 부른다 — Docked는 `OnChange` 2회, RangeDocked는 Enter 한 번에 시작·끝이 같은 날로 확정된다. [추정] 코드는 읽은 그대로이고 엔진 쪽이 미확인이다. **볼 것**: Studio에서 날짜 칸을 키보드 선택한 채 Enter 한 번 — Docked의 `OnChange`가 몇 번 불리는가, RangeDocked가 하루짜리 범위로 닫히는가. 두 번이면 고침은 국소적이다(`onKey`의 Enter 분기를 지우고 엔진의 `Activated`에 맡기거나, 칩 쪽에서 같은 프레임의 둘째를 무시). 출처: mat-rest 5번.

### D. 개선 제안(결함 아님)

**M-D1. 영어 긴 날짜 입력이 쉼표 뒤 공백을 요구한다.** `parseLocalized`의 패턴이 `,?%s+`라 "October 05,2026"이 "unrecognized date format"이 된다. 문서가 약속한 형식("October 5, 2026")은 정상이므로 결함이 아니라 너그러움의 문제다. 얻는 것: 입력 모드에서 흔한 오타 하나를 받는다; 드는 것: 패턴 한 줄(`%s*[,%s]%s*` — 날과 해 사이에 쉼표나 공백이 하나는 있어야 하므로 "October 52026"은 여전히 거절). [실측] 순수 스펙에 좋은 예 둘·나쁜 예 둘을 더했고 안 고친 사본에서 2건 실패. diff: `patches/M-D1.diff`(소스 + `spec.pure.calendar.luau`). 출처: mat-rest 8번.

### E. 기각

- **Select "닫히는 100ms 안에 필드를 다시 누르면 메뉴가 하나 더 뜬다"(mat-rest 1번의 끝부분)**: 닫히는 동안에도 메뉴의 전체 화면 스크림이 필드 위에 있어 포인터 누름은 필드에 닿지 않는다(프로브는 mock에서 필드에 직접 신호를 쐈다). 게임패드로는 닿지만 그건 "닫고 바로 다시 열기"라 정상이다.
- **mat-rest 7번의 처방("`typeField`가 거절하면 remember하지 않는다")**: 증상은 맞지만 그 처방만으로는 정상 편집이 여전히 기억되지 않는다 — M-A4로 대체.
- **mat-rest 6번(YearView 연도 범위가 생성 시점 ±100)**: 머리 주석이 밝힌 한계와 같은 동작. 파인더도 결함이 아니라고 적었다.
- **mat-rest 9번(Checkbox 모션이 한 사이클 더 돈다)**: 시각만, [추정]이고 재지 않았다 — 버림.
- **mat-new 1~7·9번**: `405ce844`에서 이미 고쳐 커밋됨 — 다루지 않았다.

---

## devui

### A. 확정 결함, 고침이 국소적

**V-A1. 숫자 칸·16진 칸은 글자를 고치지 않고 포커스만 넣었다 빼도 값을 다시 쓰고 `OnChange`를 부른다.** `FocusLost`가 칸의 글자를 그대로 다시 읽어 값으로 쓴다. 값 0.12345가 "%.3f"로 "0.123"으로 보이는 InputNum은 눌렀다 떠나기만 해도 0.123이 되고 `OnChange`가 한 번 불린다. 같은 뿌리로 "%d"로 보이는 3.7은 4가 되고, InputVector2의 성분, 그리고 InputColor3에서 8비트 격자에 없는 색(0.5 → #808080 → 128/255)이 16진 칸이나 R/G/B 칸에서 바뀐다. 파인더는 "끌기 칸은 영향 없다"고 했지만 DragNum과 R/G/B 칸도 **클릭해서 편집기를 연 뒤 그냥 떠나면** 같은 길을 탄다. 위치는 `Inputs/NumberField.luau` 96~105행(`commit`), `Inputs/InputColor3.luau` 75~91행. [실측] 스펙 R1 절(안 고친 사본: "InputNum: value 0.123, OnChange 1"; 하위 단언 따로: "%d": 4, 벡터 성분, "DragNum click + leave: value 0.123", 16진 칸, R 칸 전부 실패). 출처: devui 파인더 1번. **고침**: 칸의 글자가 지금 보여 주는 글자(`shown:Get()`)와 같으면 아무것도 쓰지 않고 다시 그리기만 한다 — 두 파일에 조건 하나씩. material `NumberField`(오늘 `405ce844`)는 "편집했나" 플래그를 쓰지만 여기서는 프로그램 `Set`이 포커스 중에도 칸 글자를 덮어쓰므로 글자 비교 하나로 같은 뜻이 된다(material 색 선택기 칸도 이 방식이다). 편집해서 다른 글자가 되면 지금처럼 커밋하고, 틀린 글자는 지금처럼 되돌린다. diff: `patches/V-A1.diff`.

**V-A2. 콤보에서 `OnChange`가 던지면 목록이 열린 채 남는다.** 행 클릭이 `spec.OnPick(key)` 다음에 `close()`를 부르므로 사용자 콜백이 던지면 닫기가 건너뛰어진다 — 값은 이미 바뀌었고 목록과 전체 화면 클릭 포착 버튼이 떠 있다. 같은 킷의 메뉴는 닫고 나서 콜백을 부른다(`Menu.luau`의 `closeThen`). 위치는 `Combo.luau` 161~164행. [실측] 스펙 R2 절(안 고친 사본: "the list closed (1 popups left)"). 출처: devui 파인더 10번. **고침**: 두 줄의 순서를 바꾼다. diff: `patches/V-A2.diff`.

**V-A3. 문서가 `ZIndexBehavior = Sibling`을 "기본값"이라고 적었고, 빠른 시작 예제 둘은 그것을 주지 않는다.** `Window/Manager.luau` 5행은 "ScreenGui.ZIndexBehavior = Sibling, the default"라 적었지만 코드로 만든 ScreenGui의 기본은 Global이다(material 쪽 Studio 실측 `71822522`). 이 킷은 창의 겹침을 창 루트의 ZIndex(서열 1..n)로, 팝업 층을 ZIndex 1000으로 정하므로 Sibling이 전제다 — Global에서는 ZIndex가 ScreenGui 전체에서 비교되어 서열 2 이상인 창의 배경이 자기 내용(ZIndex 1)과 팝업 위에 그려진다. 이 마지막 문장은 [추정]이다(Global의 정의에서 나오는 결과이고 devui에서 직접 본 적은 없다 — V-C5). `src/init.luau` 빠른 시작과 `README.md` 예제는 창이 하나라 우연히 보인다; 갤러리만 Sibling을 준다. 출처: devui 파인더 2번. **고침**(material과 같은 모양, 새 공개 이름 없음): Manager 머리 주석 정정, `init.luau`·README·Overlay 머리의 예제에 `ZIndexBehavior = Enum.ZIndexBehavior.Sibling`과 이유, README에 한 문단, 그리고 `Overlay.Open`이 `q.debug`일 때 조상 ScreenGui가 Sibling이 아니면 한 줄(오버레이당 한 번, 층이 ScreenGui 아래 들어온 뒤에만 기회를 씀). mock은 프로퍼티 기본값이 없어 안 준 ScreenGui가 nil로 읽히므로 nil은 조용히 지나가게 했다(기존 스펙이 그런 ScreenGui를 쓴다). 스펙 R3 절. **한계**: 알림은 팝업이 처음 열릴 때만 나온다 — 창만 둘 띄우고 팝업을 한 번도 안 여는 사용자는 못 본다(창 쪽에서 알리려면 창이 "붙었다"를 아는 훅이 필요해 넣지 않았다). diff: `patches/V-A3.diff`.

**V-A4. DragNum을 끄는 도중 `Disabled`가 켜져도 끌기가 계속 값을 쓴다.** material M-A3과 같은 뿌리다. `Interaction.drag`의 `Enabled`는 누르는 순간에만 보고, 끌기 칸의 `OnMove`는 `tracking`만 본다. SliderNum은 `setFromX`가 매번 `enabled`를 봐서 해당 없다(읽어서 확인). 위치는 `Inputs/NumberField.luau` 130~141행. [실측] 스펙 R4 절(안 고친 사본: "disabled mid-drag: value 40, OnChange 2"). 출처: 파인더들에 없음 — (나) 뿌리를 devui에서 확인하다 찾았다. **고침**: `OnMove` 첫 조건에 `or not enabled:Get()`. diff: `patches/V-A4.diff`(같은 파일이라 V-A1 다음에 적용).

### B. 확정 증상, 처방이 결정 사항

**V-B1. 창을 프로그램으로 닫으면(`Open:Set(false)`) 그 안에서 떠 있던 것들이 정리되지 않는다.** 창은 닫을 때 루트를 `Visible = false`로만 한다. 세 가지가 남는다: 마우스가 올라가 있던 대상의 툴팁 대기 타이머가 그대로 만료되어 숨은 대상의 툴팁이 뜨고 닫히지 않는다; 콤보 목록(과 클릭 포착 버튼)이 열린 채 남는다; 창 안 버튼과 크기 조절 그립의 hover 외관이 다시 열어도 그대로다. [실측] 파인더 프로브를 다시 돌림(`tri/probes/devui/probe.life.luau`, `probe.hover.luau`): 창을 닫고 1초 뒤 툴팁 Count 1, 콤보 popups 1, 그립 투명도 0.33 유지. 전제는 "조상의 `Visible` 변화는 자손에 `MouseLeave`를 보내지 않는다"인데, 킷이 이미 사실로 취급하지만(`Interaction.luau` 54·96~98행, 타이틀바 두 버튼만 `Reset`으로 구제) 기록된 실측은 찾지 못했다(V-C3). 콤보 목록은 엔진과 무관하게 남는다. 갈래: 창이 닫힐 때 자기 Overlay의 팝업을 닫는다 — 그런데 Overlay는 여러 창이 같이 쓰므로 `CloseAll`은 남의 창 팝업까지 닫고, 창별로 닫으려면 팝업에 소유 창을 달아야 한다; 창이 자기 `Open` State를 Context로 내려 주고 `Interaction.hover`·Tooltip·Combo·Menu가 그것을 보고 스스로 정리한다 — 한 가지 장치로 셋이 다 닫히지만 새 내부 메커니즘이고 창 밖에서 만든 위젯에는 안 닿는다; 툴팁만 `show()` 시점에 대상이 보이는지 확인한다 — mock에 클래스 계층이 없어 조상을 따라가며 `Visible`을 읽는 검사가 한 줄로 안 된다. **추천은 둘째**(Context)이고, 그 전에 V-C3을 본다. 출처: devui 파인더 4번, Gemini 1·2번.

**V-B2. 포커스된 창이 닫히거나 파괴되면 포커스가 넘어가지 않는다.** 닫으면(`Open:Set(false)`) `manager.Focused`와 최상위 서열이 닫힌 창에 그대로 남아 남은 창의 타이틀바가 계속 "비활성" 색이고, 파괴하면 `Focused`가 0이 되어 어느 창도 활성이 아니다. 둘 다 사용자가 남은 창을 한 번 눌러야 풀린다. [실측] 파인더 프로브(닫은 뒤 focus id 2 유지, z 1/2 그대로); 파괴 쪽은 `Window/Manager.luau` 95~99행을 읽어 확인. 무엇이 맞는지가 동작 정의다(ImGui는 닫히면 그 아래 창으로 포커스가 간다). 갈래: 그대로 둔다; 닫히거나 파괴되면 남은 창 가운데 맨 위로 포커스를 넘기고 다시 열면 그 창이 포커스를 받는다(창이 `Open`을 관측해 Manager에 알리는 길 하나, Manager의 `Release`에 승계 세 줄). **추천은 둘째**, 낮음. 출처: devui 파인더 5번, Gemini 3·4번.

**V-B3. 창을 화면 밖으로 끌어 잃어버릴 수 있다.** 타이틀바 끌기는 Position에 이동량을 그대로 더한다(`Window/init.luau` 115~117행). 타이틀바가 화면 밖으로 나가면 다시 잡을 수 없다. [추정] 읽기만. 막으려면 부모 크기를 읽어 타이틀바 일부가 남도록 자르는 새 동작이 필요하다. 갈래: 그대로(코드로 `Position`을 되돌릴 수 있다); 끌기에서만 자른다. 낮음. 출처: devui 파인더 6번.

**V-B4. 콤보 목록·메뉴·툴팁이 화면 가장자리에서 뒤집히거나 잘리지 않는다.** Overlay 머리 주석은 "자르기는 여는 쪽이 한다"고 했는데 여는 쪽 셋이 아무도 하지 않아, 화면 아래 끝의 콤보는 목록이 화면 밖으로 나간다. [추정] 읽기만(내용 크기가 레이아웃 뒤에야 알려진다는 제약은 주석대로). 갈래: 문서에 한계로 적는다; Overlay가 첫 레이아웃 뒤 한 번 보정한다(새 메커니즘); 콤보만 `MaxHeight`로 아래 공간을 미리 계산해 위로 연다(높이 상한을 아는 콤보에서만 가능). 낮음. 출처: devui 파인더 7번.

### C. 실기기 확인 필요

**V-C1. 뒤에 있는 창 안의 버튼을 누르면 그 창이 앞으로 오지 않을 수 있다(Gemini가 찾음 — 이번 묶음에서 가장 큰 것).** 창의 "누르면 앞으로"는 루트 Frame과 내용 ScrollingFrame의 `InputBegan`에 걸려 있다(`Window/init.luau` 145·200행). 그런데 Studio에서 잰 엔진 규칙이 "누름은 포인터 아래 GuiObject들에 위에서부터 전해지고 첫 GuiButton에서 멈춘다"이다(`.claude/feedback/consumer-kits-studio-qa-2026-10-07.md` 405행). 그러면 뒤 창의 Button·Checkbox·콤보 상자·Selectable·트리 머리·탭을 누를 때 그 버튼에서 누름이 멈춰 창 루트는 신호를 받지 못하고, 위젯은 동작하는데 창은 다른 창 뒤에 그대로다. [추정] 규칙에서 나오는 결과이고 mock은 전달을 흉내 내지 않아 확인할 수 없다(킷 스펙은 루트·내용에 직접 신호를 쏜다). **볼 것**: 갤러리에서 창 둘을 겹쳐 놓고 뒤 창의 버튼을 눌렀을 때 그 창이 앞으로 오는가. 안 오면 처방은 결정 사항이다: Manager가 전역 누름 하나를 듣고 서열이 높은 창부터 영역으로 판정해 포커스를 준다(연결 하나, 모든 위젯에 통함 — 추천); 창이 자기 `slot`을 Context로 내려 주고 위젯들이 누름에서 부른다(위젯마다 한 줄); 그대로 두고 문서에 적는다. 출처: Gemini 6번.

**V-C2. 터치로 SliderNum·DragNum을 끌면 창의 ScrollingFrame이 같이 스크롤될 수 있다.** 창 내용은 세로 ScrollingFrame이고 끌기 칸은 그 안에 있다. material은 같은 이유로 `Interaction.drag`에 `LockScroll`을 두었다(`quad-roblox-material/src/Interaction.luau` 51행). [추정] 터치 기기 동작. **볼 것**: 기기(또는 에뮬레이터)에서 창 내용이 스크롤될 만큼 길 때 슬라이더를 비스듬히 끌면 창이 같이 움직이는가. 움직이면 처방은 devui `Interaction.drag`에 같은 옵션을 두는 것인데 `Interaction`이 공개 export라 옵션 이름이 공개 표면에 더해진다 — 결정 사항. 출처: devui 파인더 3번, Gemini 17번.

**V-C3. 조상이 `Visible = false`가 될 때 자손에 `MouseLeave`가 오는가.** V-B1의 전제다. **볼 것**: 창 안 버튼에 마우스를 올린 채 단축키로 창을 닫았다 열었을 때 버튼이 hover 색으로 남아 있는가, 닫은 직후 0.5초 뒤 툴팁이 뜨는가.

**V-C4. InputText "submit" 모드에서 Escape가 취소가 아니라 확정이다.** `FocusLost`가 항상 칸의 글자를 커밋한다(`Inputs/InputText.luau` 108~118행). 엔진이 Escape에도 `FocusLost(enterPressed = false)`를 내고 글자를 그대로 두면 Escape가 확정이 된다(ImGui는 취소). [추정] 엔진 동작. **볼 것**: submit 모드 칸에 글자를 치고 Escape — 값이 바뀌는가. 바뀌면 `FocusLost`의 둘째 인자가 Escape일 때 되돌리는 것이 동작 정의라 결정 사항이다. 낮음. 출처: devui 파인더 13번.

**V-C5. Global인 ScreenGui에서 둘째 창의 내용이 실제로 가려지는가.** V-A3의 [추정] 부분. **볼 것**: `ZIndexBehavior`를 안 준 `D.ScreenGui`에 창 둘 — 둘째 창의 내용과 콤보 목록이 보이는가. V-A3의 문서·알림은 어느 쪽이어도 넣어서 해가 없다(문서의 "기본값" 서술은 어차피 틀렸다).

### D. 개선 제안(결함 아님) — 할 만한 것만

**V-D1. Table과 Plot의 머리 주석에 비용 한 문단씩.** Combo 머리는 "NO VIRTUALIZATION"을 밝히는데 Table은 침묵한다. [실측] 행당 인스턴스는 3 + 열당 4~6(라벨 하나짜리 칸 기준 — 열 수·고정 폭·Borders를 바꿔 가며 잼), 3열 Borders에서 약 20개, 500행이면 10,018개에 mock 구성 0.6~0.7초; 갱신은 싸다(500행 전체 갱신 14ms, 첫 행 삭제 11ms). PlotLines는 값이 바뀔 때마다 모든 구간을 다시 계산한다 — 200점에서 Compute 약 800개, mock 갱신당 4.1ms(다시 잼). 갤러리는 10Hz로 넣으므로 지금 쓰임에서는 문제가 아니고, 매 프레임 넣으면 프레임 예산의 4분의 1이다. 얻는 것: 사용자가 큰 표·매 프레임 그래프를 만들기 전에 안다; 드는 것: 주석 8줄. 구조를 바꾸는 제안(구간당 geo 테이블을 Compute 셋으로 풀기)은 이득을 재지 못해 넣지 않았다. diff: `patches/V-D1.diff`. 출처: devui 파인더 8·9번, Gemini 13번.

**V-D2. Table의 열 구분선마다 같은 Compute 둘을 새로 만든다.** `hairline(true, …)`이 칸마다 위치·크기 Compute를 만드는데 둘 다 스타일 토큰(`CellPadding`)에만 의존해 표 전체에서 값이 같다. 표당 한 쌍으로 올리면 500행 × 3열에서 Compute 2,000개가 줄고 [실측] mock 구성 시간이 약 7% 준다(632 → 589ms, 670 → 625ms, 번갈아 두 번씩, 5회 중 최선). 드는 것: 순증 10줄, 동작 변화 없음(기존 `spec.table` 통과). 위치는 `Table.luau` 90~104행. diff: `patches/V-D2.diff`(V-D1 다음에 적용). 출처: Gemini 12번(지적은 맞고, 보고서가 든 이름 `theme.cellPadX`·`q.Compute`는 소스에 없다).

**V-D3. Manager의 `focusedId:Set(id) -- no-op when unchanged`는 주석이 사실과 다르다.** quad의 `:Set`은 같은 값도 전파한다(`docs/skills/quad-ui-dev/SKILL.md` 102행). 이 줄에 같은 id로 닿는 경우는 "포커스는 있는데 새 창에 덮인 창을 눌렀을 때"뿐이고 그때 모든 창의 `isFocused`가 한 번 더 계산된다. `SetIfChanged`로 바꾸면 주석의 뜻대로 된다(한 줄). 위치는 `Window/Manager.luau` 86행. diff: `patches/V-D3.diff`(V-A3 다음에 적용). 출처: Gemini 18번.

### E. 기각

- **Gemini 5번 "`NoMove` 창은 타이틀바를 눌러도 포커스가 안 온다"**: 타이틀바는 Frame이고, 잰 엔진 규칙상 Frame은 누름을 받고 아래로 넘기므로 루트의 `pointerDown`이 받는다. Gemini의 프로브는 mock에서 타이틀바에만 신호를 쐈다(mock은 전달을 흉내 내지 않는다). 타이틀바의 두 버튼 위 누름은 V-C1에 포함.
- **Gemini 7번 "`PopupParts.onEscape`가 `processed`와 TextBox 포커스를 안 본다"**: 읽은 대로지만 닿는 해가 없다 — 콤보·루트 메뉴가 열려 있는 동안은 클릭 포착 버튼이 화면을 덮어 TextBox가 포커스를 얻을 수 없고, 게임 메뉴가 열릴 때 팝업이 닫히는 것은 해가 아니다.
- **Gemini 8번 "Escape 한 번에 메뉴 사슬 전체가 닫힌다"**: 문서화된 설계다(`Menu.luau` 머리 "Escape closes the whole chain"). ImGui처럼 한 단계씩 닫을지는 요청이 있을 때의 동작 결정.
- **Gemini 9·10·11번(음수 `Step`에서 +/-가 뒤집힘, `Min > Max` 슬라이더가 0에 고정, `%d`에 NaN)**: 전부 잘못 준 인자의 결과이고 에러 없이 퇴화한다 — 드문 오용 방어에 구조를 쓰지 않는다는 레포 원칙 그대로.
- **Gemini 14·15·16·20번(`Common.enabled(nil)`이 매번 Source를 만듦, `Common.look`의 Compute 둘, `Util.pxX`가 위젯마다 Compute를 만듦, 상수 재사용의 불일치)**: 위젯당 객체 한두 개 수준이고 재지 않은 주장이다("8~12개 노드"는 코드와 다르다 — `Common.look`은 `Style.interactive` 위에 Compute 둘). 버림.
- **devui 파인더 11번·Gemini 19번(`hostName` 캐시 세 벌 등 중복)**: 세 벌은 클래스가 달라(Frame/TextBox/TextButton) 타입이 다른 함수 셋이 된다 — 줄어드는 것 약 16줄, 드는 것 `Util` 함수 셋. 헤더 알파 계산 세 벌도 같은 크기. 값이 낮아 준비하지 않았다.
- **devui 파인더 12번(하드코딩된 2px·4px·1px)**: 어긋나는 밀도를 보이지 못한 [추정].
- **(가) 뿌리의 devui 쪽**: 해당 없음 — devui 팝업은 닫는 즉시 Slot에서 빠진다(닫히는 구간이 없다; 스펙 R2에서 닫은 직후 Count 0).

---

## 돌린 것 요약

- **안 고친 사본**: `quad-roblox-material/test/run.sh` exit 0(PASS 498줄), `quad-roblox-devui/test/run.sh` exit 0(PASS 164줄).
- **고친 사본**(A 전부 + D 전부 적용): material run.sh **exit 0**(PASS 505줄 — strict 포함), devui run.sh **exit 0**(PASS 168줄 — strict 포함).
- **새 스펙 절이 안 고친 사본에서 실패하는가**: material `spec.reviewfix.luau`의 R1 세 절·R2·R3·R4·R5 = 7절 전부 실패(기존 8절은 통과), 묶인 하위 단언도 `assert`를 소프트 검사로 바꾼 사본으로 하나씩 실패를 확인했다. `spec.pure.calendar.luau`는 2건 실패. devui `spec.reviewfix.luau`의 R1~R4 = 4절 전부 실패. 고친 사본에서는 전부 통과.
- **diff 적용**: 번호별 diff를 `ORDER.txt` 순서로, 그리고 `all.diff`를 따로, 레포 킷의 새 사본에 `patch -p1`로 적용해 고친 사본과 `diff -rq` 일치.
- 고침 중 한 번 strict에 걸린 것: M-A5에서 `action == "home"`으로 좁히면 신 솔버가 뒤의 `moveFocus(from, action, …)` 호출을 거부해 문자열로 받아 비교하게 했다(diff에 주석).

## 검증하지 못한 것

- **Gemini material 보고**: 없었다 — 메인이 따로 본다.
- **엔진 동작 전부**(Studio 금지): 닫히는 0.1~0.2초 안의 둘째 `Activated`(M-A1의 전제 — 간격상 그럴 법함), Enter의 `Activated`(M-C1), 누름 전달(V-C1), 터치 스크롤(V-C2), 조상 `Visible`과 `MouseLeave`(V-C3), Escape의 `FocusLost`(V-C4), Global에서의 겹침(V-C5), Frame의 `Interactable` 전파(M-B1 셋째 갈래).
- **정본**: Compose `DatePicker.kt`는 앞 10만 자만 읽었다(Home/End 없음); MDC 쪽 날짜 키보드는 보지 않았다. `SnackbarHost.kt`는 `performAction` 부분만.
- **재지 않은 것**: Gemini의 미세 비효율 주장 넷(E로 버림), mat-rest 9번 체크박스 모션, PlotLines 구조 변경의 이득.
- **범위 밖으로 둔 것**: material `ListReorder`·`TimePicker/ClockFace`의 "끄는 도중 Disabled"(파인더 발견이 없었고 따로 프로브하지 않았다 — `Interaction.drag`를 쓰므로 같은 뿌리일 수 있다), `Calendar.parseLocalized`의 trim 패턴이 오늘 `Unit`에서 고친 이차 시간 패턴과 같다는 것(긴 공백 붙여넣기에서만, 재지 않음), 파인더가 "못 본 것"에 적은 Tabs의 선택 키 정합.
