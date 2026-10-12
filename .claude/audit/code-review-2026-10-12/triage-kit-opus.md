# Material 3 킷 code-review — 추림·검증 결과 (opus, 2026-10-12)

입력은 파인더 셋의 보고서(`finder-kit1-sonnet.md`, `finder-kit2-sonnet.md`, `finder-kit-gemini.md`)다. 검증은 새로 뜬 사본 `…/scratchpad/review/kit-t/`(고친 것)와 `…/review/kit-orig/`·`kit-o/`(안 고친 것)에서 했다. 레포는 건드리지 않았다. 줄 번호는 지금 레포(`/code/Projects/quad/quad-roblox-material/src`) 기준이다 — sonnet 보고서의 줄 번호는 몇 줄씩 어긋나 있어 다시 적었다.

**돌린 것 요약.** A 분류 일곱과 C1의 고침을 사본에 전부 넣은 상태에서 `quad-roblox-material/test/run.sh`가 exit 0이다(Lune 스펙 42 + pure 스펙, strict 진단 0; 로그 `…/review/kit-t-run.log`). 단, 사본에 `quad-roblox-devui`와 `consumer-kits.project.json`을 두지 않아 run.sh의 "gallery entry(@game, rojo sourcemap)" 단계는 건너뛰었다 — 그 단계는 이번 고침이 닿지 않는 파일(`gallery/*.client.luau`)만 본다. 고침마다 절 하나씩 든 스펙 `…/review/kit-t-patches/spec.reviewfix.luau`는 안 고친 소스에서 여덟 절 전부 FAIL, 고친 소스에서 전부 PASS다(둘 다 실측). diff는 `…/review/kit-t-patches/`에 발견 번호별로 있고, `Sheet/Slide.luau` 네 건은 서로 다른 자리를 고쳐 겹치지 않으며 넷을 다 넣은 것이 `A1-A4-slide-all.diff`다.

**Gemini 프로브에 대해.** 지정된 경로 `/code/Projects/quad-agy/review-kit/quad-roblox-material/test/spec.probe.luau`에는 파일이 없다(그 worktree 어디에도 `spec.probe*`가 없다). 그래서 Gemini가 [실측]이라 적은 둘(1.1, 1.2)은 그 프로브를 다시 돌린 것이 아니라 내 프로브와 코드 읽기로 따로 확인했다.

---

## A. 확정 결함, 고침이 국소적

**A1. 시트·드로어를 끄는 도중 다른 손가락이 다른 면을 누르면 첫 손가락의 끌기가 움직이고 끝난다.** 손가락 하나가 드로어(또는 시트)의 ClickSink를 잡고 끄는 동안 다른 손가락이 스크림이나 핸들을 누르면, 그 면의 `Interaction.drag`는 자기 연결을 따로 열고 Slide의 공용 `began`은 `active`라 조용히 돌아간다. 그런데 두 번째 손가락의 이동과 뗌은 그대로 공용 `movedTo`·`ended`로 들어가서, 첫 손가락의 끌기가 두 번째 손가락의 좌표로 움직이고, 두 번째 손가락을 떼는 순간 끝나 버린다(스냅 복귀, 첫 손가락은 계속 눌려 있는데 더는 반응 없음). 위치는 `Sheet/Slide.luau` 217~220행(`began`의 조용한 반환), 293~306행(`hook()`이 어느 Drag가 불렀는지 구분하지 않고 `began`/`movedTo`/`ended`를 그대로 넘김). 바텀 시트(핸들+싱크), 사이드 시트, 드로어(싱크+스크림)가 모두 같은 구조다. [실측] mock에서 터치 A로 −100까지 끈 뒤 터치 B를 스크림에 누르고 움직이자 위치가 따라 움직였고(스펙 A1 절 63행 단언 실패), B를 떼자 0으로 돌아갔다. 엔진에서 두 번째 터치의 `InputBegan`이 다른 GuiButton에 따로 배달된다는 것은 [추정]이지만 멀티터치의 기본 동작이다. 출처: sonnet-1 1번(sonnet은 "뗌이 끝낸다"만 적었고, 이동도 섞인다는 것은 이번에 확인). **고침**: `hook()` 안에서 훅마다 토큰을 하나 두고, 제스처를 실제로 시작한 훅(`began` 뒤 `active`가 참이 된 훅)만 `OnMoved`/`OnEnded`를 Slide로 넘긴다 — `Slide.luau` 293~300행의 `OnBegan = began, OnMoved = …movedTo, OnEnded = ended`를 소유 토큰 검사로 감싼 세 클로저로. 스펙 단언: `assert(d.Position.X.Offset == -100, "B's lift does not end A's drag")`. diff: `kit-t-patches/A1.diff`.

**A2. 끌리던 드로어·시트가 파괴되면, 이미 상태를 넘겨받은 새 인스턴스 몰래 상태의 Target을 바꾼다.** `Slot:Single`이 새 드로어를 먼저 만들고(같은 DrawerState를 받아 새 드라이버가 붙음) 옛 드로어를 나중에 지우는 경로에서 옛 것이 끌리는 중이면, 파괴 → `d:Cancel()` → `ended(cancelled)`가 `destroyed`인데도 `Release`로 목표를 골라 `rec.Target:Set(target)`까지 실행한다(바로 뒤 `go`만 `destroyed` 가드가 있다). 결과는 TargetValue = "Closed", CurrentValue = "Open", 화면의 새 드로어는 열린 채 — Target과 화면이 어긋난 채 남고, `TargetValue`에서 파생한 값(스크림 투명도 등)이 틀어진다. 넘겨받은 인스턴스가 없을 때도 같은 줄이 돌아서, 끌던 중에 파괴된 드로어는 그 순간의 위치로 상태 값을 바꿔 놓는다. 위치는 `Sheet/Slide.luau` 261~291행(특히 289행), 파괴는 308~319행. [실측] 프로브와 스펙 A2 절(안 고친 소스: "target Closed / current Open"). 출처: sonnet-1 2번. **고침**: `ended`에서 `dragging:Set(false)`(274행) 바로 뒤에 `if destroyed or rec.Driver ~= driver then return end` — 사라지는 면이나 상태를 넘겨준 드라이버의 끌기는 상태를 더 쓰지 않는다(`rec.Driver ~= driver` 쪽은 닫히는 모달 시트가 `Detach`한 뒤 손가락을 떼는 경우도 같이 막는다). 스펙 단언: `assert(state.TargetValue:Get() == "Open" and state.CurrentValue:Get() == "Open")`. diff: `kit-t-patches/A2.diff`.

**A3. 움직이는 도중 레이아웃이 바뀌면 화면의 모션은 처음부터 다시 도는데 CurrentValue는 원래 시각에 확정된다.** 시트가 펼쳐지거나 접히는 0.2초 사이에 내용 높이나 호스트 크기가 바뀌면 `relayout`이 새 앵커를 향해 전체 길이의 트윈을 다시 걸지만(`set(target, cfg.Motion(lastKind))`), 처음 요청 때 건 settle 타이머는 그대로라서 화면이 아직 움직이는 중에 `CurrentValue`가 목표값으로 바뀐다. 0.15초에 내용이 자라면 화면은 0.35초까지 움직이는데 Current는 0.2초에 확정된다. `CurrentValue`에 맞춰 무언가를 보이거나 치우는 소비자가 그만큼 일찍 반응한다. 위치는 `Sheet/Slide.luau` 199~201행. [실측] 스펙 A3 절(안 고친 소스: 0.21초에 이미 Expanded). 처음 열릴 때 내용의 자동 크기가 몇 프레임에 걸쳐 자리 잡는 화면에서 실제로 밟힐 수 있다는 것은 [추정]. 출처: sonnet-1 6번과 Gemini 1.5(같은 뿌리). **고침**: 그 분기에서 `scheduleSettle(rec.Target:Get(), motion.Time)`을 같이 불러 타이머를 다시 건다(두 줄). 남은 시간만큼만 도는 모션으로 바꾸는 것은 시작 시각을 따로 들어야 해서 넣지 않았다. 스펙 단언: `assert(state.CurrentValue:Get() == "PartiallyExpanded", "at 0.21 the re-aimed motion has not settled")`. diff: `kit-t-patches/A3.diff`.

**A4. 손가락이 시트를 잡고 있는 동안 코드가 상태를 요청하면, 손가락이 아직 눌린 채로 CurrentValue가 그 값으로 확정된다.** 끌고 있는 시트에 코드가 `PartialExpand()`나 `Hide()`를 부르면 `go`는 오프셋 이동만 건너뛰고 settle 타이머는 그대로 건다. 그래서 시트는 손가락 밑에 그대로 있는데 0.1~0.2초 뒤 `CurrentValue`가 요청값으로 바뀌고, 손가락을 떼면 `Release`가 위치로 다시 골라 값이 되돌아간다 — `CurrentValue`가 한 번 깜빡인다. 위치는 `Sheet/Slide.luau` 139~153행. [실측] 스펙 A4 절(안 고친 소스: 손가락이 눌린 채 Current가 PartiallyExpanded). 출처: sonnet-1 4번, 그리고 같은 자리의 5번(끌기가 끝날 때 앵커가 없으면 상태가 어정쩡하게 남는다 — 호스트 크기가 0이 되는 드문 경우라 따로 세지 않고 여기 합쳤다). **고침**: `go`에서 `dragging`이면 이동도 settle 예약도 하지 않고(뗌의 `ended`가 정착시킨다), `ended`의 "앵커 없음" 분기(280~282행)는 그냥 돌아가는 대신 `go(rec.Target:Get(), "Settle")`로 요청이 남긴 Target에 정착시킨다. **이 고침이 건드리지 않는 것**: 끌기 도중의 프로그램 요청은 지금처럼 뗌이 덮어쓴다(요청이 끌기를 이기게 할지는 동작 결정이라 손대지 않았다). 스펙 단언: `assert(state.CurrentValue:Get() == "Expanded", "finger down: Current stays")`. diff: `kit-t-patches/A4.diff`.

**A5. 넓은 내비게이션 레일이 사라진 뒤에는 그 상태의 CurrentValue가 다시는 움직이지 않는다.** `WideNavigationRail`은 만들어질 때 상태 기록의 `Driven`을 참으로 올리기만 하고 내리지 않는다. 레일이 파괴된 뒤 `Expand()`/`Collapse()`/`Toggle()`을 부르면 TargetValue만 바뀌고 CurrentValue는 옛 값에 머문다 — 상태 머리 주석의 "with no rail it settles at once"와 어긋난다. 탭 전환으로 레일이 잠시 없어지는 화면에서 `CurrentValue`를 읽는 쪽이 낡은 값을 본다. 움직이는 도중 파괴되면 Current가 목표에 영영 닿지 못하는 것도 같은 뿌리다. 위치는 `NavigationRail/init.luau` 183행, 읽는 쪽은 `NavigationRail/State.luau` 62~67행. [실측] 프로브(레일 dispose 뒤 Expand → target Expanded, current Collapsed)와 스펙 A5 절. 출처: sonnet-1 3번. **고침**: `Driven`을 살아 있는 레일 수로 바꾼다(레일 생성 때 +1, 호스트의 `q.OnDestroyed`에서 −1, 0이 되면 `rec.Current:SetIfChanged(rec.Target:Get())`). 불리언 그대로 두고 파괴 때 거짓으로만 돌리면, 같은 상태로 새 레일을 먼저 만들고 옛 레일을 지우는 재구성에서 살아 있는 레일이 "레일 없음"으로 읽힌다 — 그래서 개수다. 공개 타입은 그대로이고 바뀌는 것은 두 파일이 같이 쓰는 내부 기록 `Internal.Driven`의 타입(boolean → number)뿐이다. 스펙 단언: `assert(state.CurrentValue:Get() == "Expanded", "the last rail died mid-motion: the state settles at its target")`. diff: `kit-t-patches/A5.diff`.

**A6. 슬라이더 값 라벨의 기본 표기가 "0."·"1."을 만든다.** 값이 정수는 아닌데 소수 둘째 자리까지 0이면(0.004, 0.996 → 반올림 1.00, 1.001) `%.2f`로 찍은 "0.00"에서 끝의 0만 지워 점이 남는다. Step 없는 연속 슬라이더를 끝 근처로 끌면 라벨에 그대로 보인다. 위치는 `Slider/Behavior.luau` 149~156행(`defaultFormat`), M3·M2·Range 라벨이 모두 이 함수를 쓴다. [실측] 스펙 A6 절(안 고친 소스: 라벨 텍스트 "0."). 출처: sonnet-2 2번. **고침**: 함수 첫 줄에서 소수 둘째 자리로 먼저 반올림한다(`v = math.floor(v * 100 + 0.5) / 100`) — 그러면 정수 검사가 반올림된 값에 걸려 "0"·"1"이 되고, −0.001도 "0"이 된다("-0." 없음). 스펙 단언: `assert(text(0.004) == "0")`. diff: `kit-t-patches/A6.diff`.

**A7. 슬라이더를 끄는 도중 `Disabled`가 참이 되어도 끌기가 계속 값을 쓰고 `OnChange`를 부른다.** `Interaction.drag`의 `Disabled`는 누르는 순간(`Interaction.luau` 274행)에만 보고, 값을 쓰는 한 길목인 `commit`에는 검사가 없다. 키 입력 쪽은 `c.disabled:Get()`을 매번 보므로 포인터와 키가 비대칭이다. `OnChange`에서 저장을 시작하며 `Disabled`를 올리는 앱이면 저장 중에도 값이 계속 바뀐다. 위치는 `Slider/Behavior.luau` 305~315행(단일), 387~403행(범위). [실측] 스펙 A7 절(안 고친 소스: Disabled 뒤 이동으로 값이 0.75로 바뀜). 출처: sonnet-2 3번. **고침**: 두 `commit`의 첫 줄에 `if c.disabled:Get() then return false end`. 뗄 때의 `OnChangeEnd`는 그대로 한 번 불린다(비활성 전에 쓴 마지막 값을 보고한다 — 끌기를 아예 취소해 `OnChangeEnd`를 안 부르게 할지는 고르지 않았다). 스펙 단언: `assert(v:Get() == at, "disabled mid-drag: the value stays")`. diff: `kit-t-patches/A7.diff`.

---

## B. 확정 증상, 처방이 결정 사항

**B1. Step이 범위를 나누지 않는 슬라이더는 Max에 닿지 못하고, 그림은 Max에 닿는 것처럼 그려진다.** Min 0, Max 10, Step 3이면 값은 0·3·6·9뿐이다(맨 오른쪽을 눌러도, End 키로도 9). 그런데 오른쪽 끝 정지점은 Max 자리에 그려지고, 눈금은 0·3·6 셋만 나온다 — 실제로 닿는 9의 눈금은 "마지막 눈금 = 정지점"이라는 가정(`SkipLast`)으로 빠진다. [실측] 안 고친 소스에서 눈금 3개(0.00 / 0.30 / 0.60), 맨 오른쪽 누름 값 9, 정지점은 Max 자리에 보임. 위치는 `Slider/Behavior.luau` 203~212행(snapper), `Slider/Track.luau` 410~423행. 킷 머리 주석은 "snaps every written value to Min + n*Step"이라고만 하고 Max가 Step의 배수여야 한다는 말은 없다 — **정본 확인 필요**(MDC는 배수가 아니면 예외를 던지는 것으로 기억하지만 킷 문서에 근거가 적혀 있지 않아 단정하지 않는다). 갈래는 셋이다: 배수가 아니면 생성 때 에러를 던진다(동작 변경, 정본 확인 뒤); Max도 닿는 값으로 친다(snapper 변경 — 정본과 갈릴 수 있음); 지금 동작을 문서에 적고 눈금 건너뛰기만 `i * step == range`일 때로 좁힌다(그림만 고침). 출처: sonnet-2 1번.

**B2. 스크롤 프레임이 사라진 뒤에도 앱 바의 정착 예약이 살아서, 죽은 스크롤러 없이 바 높이만 0.2초 움직인다.** 스크롤이 멈춘 뒤 0.1초 안에 그 ScrollingFrame이 파괴되면 `Destroying`은 진행 중인 정착만 멈추고 예약된 `task.delay(IDLE, settle, version)`은 그대로 둔다. 0.1초 뒤 `settle`이 `frame == nil`로 돌아 `HeightOffset`만 애니메이션한다. 마우스 버튼이 눌려 있으면 떼어질 때까지 100ms마다 다시 예약한다. [실측] 내 프로브: 파괴 뒤 타이머 1개가 남고, +0.1초에 Heartbeat 연결 1개가 생겨 offset이 −30 → −48로 간 뒤 **연결은 스스로 끊긴다**(+0.4초에 0개, 타이머 0개). 그러므로 Gemini가 적은 "Heartbeat 연결 누수"는 틀렸다 — 0.2초 뒤 끝난다. 남는 증상은 "죽은 스크롤러의 정착이 살아 있는 상태를 움직인다"이고, 이것이 결함인지가 결정 사항이다: 바가 살아 있고 내용만 바뀌는 화면이면 반쯤 접힌 바가 한쪽으로 정착하는 편이 오히려 낫고, `Destroying`에서 `version += 1`로 예약을 무효화하면(sonnet 제안, 한 줄) 바는 반쯤 접힌 채 남는다. 셋째 갈래는 스크롤러가 죽으면 0으로 펴는 것. 위치는 `AppBar/Scroll.luau` 186행, 256~258행, 268~273행. 출처: sonnet-1 9번과 Gemini 1.1(같은 뿌리). 낮음.

**B3. 시간 선택 모달에서 틀린 시를 친 뒤 다이얼로 돌아가면, 다이얼은 멀쩡한데 OK가 꺼져 있다.** 입력 모드에서 12시간제에 "13"을 치면 `HourInput`은 13, `Value`는 그대로이고 `Valid`가 거짓이 된다. 다이얼 모드로 바꾸면 다이얼은 `Value`(유효한 마지막 값)를 보여 주는데 OK 비활성 조건은 여전히 `Valid`라서, 다이얼을 한 번 눌러 `SetTime`이 `HourInput`을 덮기 전까지 OK를 누를 수 없다. [실측] 모델만: `SetHourInput(13)` 뒤 valid false, value hour 9, hourInput 13; 모드 전환(`TimePicker/Modal.luau` 208~216행)이 입력을 건드리지 않는 것은 읽어서 확인. 킷 주석은 OK를 `Valid`로 켜는 근거로 Compose 샘플(TimePickerSamples.kt 183)을 든다 — 모드 전환 때 입력을 되돌리는지는 **정본 확인 필요**. 갈래: 다이얼로 갈 때 입력을 `Value`로 되돌린다(`model:SetTime(model.Value:Get())` 한 줄 — `SetTime`은 값이 같아도 입력 둘을 맞추고 `OnChange`는 안 부른다); OK 조건을 모드별로 나눈다; 정본과 같다면 그대로 둔다. 출처: sonnet-2 5번.

**B4. 대화 상자의 본문 최대 높이가 머리말을 한 줄로 치고, 레이어 크기를 열 때 한 번만 읽는다.** `maxBody`는 머리말 높이를 32(HeadlineSmall 한 줄)로 고정해 빼는데 머리말은 `TextWrapped`라 두 줄이 될 수 있고, 그러면 본문이 한도까지 찬 대화 상자는 레이어보다 그만큼 커진다. 레이어 크기는 `open` 때 한 번 읽으므로 열린 뒤 창 크기가 바뀌어도 따라가지 않는다(`TimePicker/Modal.luau`의 `fitFor`도 같다). 위치는 `Dialog.luau` 125행, 243~251행. [추정] 읽기만 — 레이아웃이 없는 mock으로는 확인할 수 없다. 고치려면 머리말의 실제 높이와 레이어 크기를 따라가는 State가 필요해 새 메커니즘이다. 갈래: 문서에 한계로 적는다; 따라가게 만든다. 출처: sonnet-2 6번. 낮음.

---

## C. 실기기 확인 필요

**C1. SplitButton이 처음 그려질 때 라벨과 화살표가 24px 옆에서 미끄러져 들어올 수 있다(파인더들이 못 본 파일에서 찾음).** 각 반쪽의 내용 위치는 "측정한 내용 폭"에서 계산하고 `q.Animate`(Short4, 0.2초)로 감싸져 있다. 측정 전에는 폭이 0이라 위치가 (48 − 0) / 2 = 24(뒤쪽 반쪽은 광학 보정 −2를 더해 22)로 먼저 쓰이고, 첫 레이아웃에서 폭이 들어오면 0(뒤쪽은 −2)으로 **트윈**한다. 위치는 `Button/Split.luau` 151~162행(측정), 333~340행(위치와 Animate). [실측] mock: 내용 프레임의 AbsoluteSize를 처음 넣자 두 반쪽 모두 Position 트윈이 생겼다(24 → 0, 22 → −2). 화면에서 실제로 보이는지는 엔진이 첫 AbsoluteSize를 언제 알리느냐에 달렸고 [추정]으로는 보인다(부모에 붙은 뒤의 레이아웃에서 알리므로) — Split은 "코드와 mock 스펙만, 실기기 확인 없음"으로 들어간 부품이다(`.claude/feedback/consumer-kits-studio-qa-2026-10-07.md` "10차 처리 상태"). **볼 것**: 갤러리 Buttons 탭을 열거나 SplitButton을 새로 띄우는 순간 라벨·화살표가 오른쪽에서 왼쪽으로 0.2초 미끄러지는가. 보이면 고침은 국소적이고 준비돼 있다: 첫 측정 전에는 `CanAnimate`가 거짓인 Source를 두어 첫 배치는 그냥 쓰고, 눌림·선택의 광학 이동은 지금처럼 움직인다(사본에서 run.sh exit 0, 스펙 C1 절). diff: `kit-t-patches/C1.diff`. 안 보여도 넣어서 해가 되지 않는 고침이다.

**C2. 터치로 스크롤하다 손가락을 댄 채 0.1초 멈추면 앱 바 정착이 시작돼 손가락 밑의 캔버스를 움직일 수 있다.** `settle`이 "아직 잡고 있다"를 `IsMouseButtonPressed(MouseButton1)`로만 판정한다. 터치 중에 이 함수가 거짓이면(그렇게 알고 있지만 확신은 중간 — [추정]) 손가락이 멈춘 0.1초 뒤 정착이 `CanvasPosition`을 쓰기 시작하고, 손가락이 다시 움직이면 "사용자 스크롤이 이긴다" 규칙으로 멈춘다. 위치는 `AppBar/Scroll.luau` 183~188행. **볼 것**: 터치 기기(또는 Studio 기기 에뮬레이터)에서 exitUntilCollapsed 바를 반쯤 접은 채 손가락을 떼지 않고 멈췄을 때 목록이 저절로 움직이는가. 움직이면 터치 눌림을 따로 세어야 해서(`TouchStarted`/`TouchEnded` 또는 `Input` 모듈에 눌림 추적) 처방은 결정 사항이 된다. 출처: Gemini 1.3.

**C3. 인스턴스 본문 대화 상자의 높이가 48 모자라는 건(이미 알려진 건).** sonnet-2 4번은 새 발견이 아니라 코드 읽기 근거를 보탠 것이다: 모자란 값이 정확히 단추 줄(패딩 8 + 40)이고 카드가 CanvasGroup이라 잘려 보인다는 점, 문자열 본문도 같은 ScrollingFrame 경로를 지나므로 스크롤 프레임 자체가 원인이면 문자열에서도 나야 한다는 점. 코드에서 다른 원인은 찾지 못했다([추정], 반박도 못 함). **볼 것**(sonnet 제안 그대로): 인스턴스 본문일 때 BodyScroll을 일반 Frame으로 바꿔 띄워 48이 돌아오는지.

**C4. 시스템 제스처로 터치가 취소될 때 끌기가 끝나는가.** Gemini 1.4의 주장 자체는 E로 기각했다(아래 E1 — 그런 이벤트가 없다). 남는 물음은 "홈 바 쓸기·전화 수신으로 터치가 끊길 때 엔진이 `InputEnded`나 `WindowFocusReleased`를 보내는가"이고, 보내지 않으면 `Interaction.drag`의 연결 셋과 `LockScroll`이 남는다. [추정]으로는 보낸다(취소도 끝으로 전달되는 것으로 알고 있다). **볼 것**: 실기기에서 시트를 끌다가 앱 전환 제스처를 한 뒤 돌아왔을 때 시트가 손가락 없이 끌린 상태로 남는지, 뒤 목록 스크롤이 잠겼는지. 낮음.

---

## D. 개선 제안(결함 아님) — 할 만한 것만

**D1. `hostName(name)` 캐시 함수 8줄이 네 파일에 복제돼 있다.** `AppBar/Top.luau` 68~76행, `Toolbar.luau` 69행~, `NavigationDrawer/Drawer.luau` 52행~, `NavigationDrawer/Sheet.luau` 37행~ — 앞의 둘은 글자까지 같다(해시 일치). `Util`에 하나 두면 약 24줄이 줄고, 드는 것은 `Util`의 내부 함수 하나(공개 이름 아님)다. [실측] grep. 출처: sonnet-2.

**D2. 슬라이더 핸들 Frame(포커스 링 UIStroke 블록, Short2 크기 트윈, 좁아짐·링 계산)이 `Slider/init.luau`와 `Slider/Range.luau`에 거의 같은 모양으로 두 벌 있다.** `Track`에 내부 빌더 하나(`g.handle{…}`)로 올리면 두 파일에서 합쳐 40줄 안팎이 줄고, 포커스 링 치수가 한 곳에 모인다. 드는 것은 `Track`의 반환 표에 내부 항목 하나. [추정] 읽기(`Range.luau` 180~197행, `init.luau` 416행 앞뒤). 출처: sonnet-2.

**D3. 단계 슬라이더의 눈금 — 값이 바뀔 때마다 눈금 수의 두 배만큼 Compute가 다시 돈다(수치만 붙임, 지금은 그대로 두기를 권함).** 눈금마다 Frame + UICorner와 Compute 넷(visible/active/color/transparency)이 있고, 값이 바뀌면 visible과 active가 눈금 수만큼 다시 계산된다. [실측] mock(Lune, 끌기 이동 2000회 평균): 눈금 없는 슬라이더 약 81 µs/이동, 눈금 100개(상한 `MAX_TICKS`)는 약 1,219 µs/이동, 인스턴스 21 → 221개. 즉 눈금 하나당 값 변화 한 번에 약 11 µs — 흔한 10~20눈금이면 0.1~0.2 ms다. 바뀐 눈금만 건드리게(핸들이 지나간 눈금 인덱스를 Effect 하나가 추적) 고치면 100눈금에서 1 ms 남짓을 얻지만 명령형 코드 30줄쯤이 든다. mock의 프로퍼티 쓰기 비용이 섞인 수치라 엔진에서 다시 재기 전에는 구조를 바꿀 근거가 약하다. 출처: sonnet-2 7(가), Gemini 2.1(같은 뿌리 — Gemini의 "매 프레임 50번"은 맞고, "color·transparency를 active에 합치면 1/4"은 그 둘이 값이 바뀔 때만 다시 돌므로 이동당 비용에는 거의 영향이 없다).

**D4. 작은 정리 둘.** `TextField/Field.luau` 214행의 `Style.disabledPick(disabled, OnSurface, OnSurface)`는 두 색이 같아 고르는 일이 없다 — 하는 일은 테마 전환 크로스페이드뿐이므로 `Style.animated(theme.Raw.OnSurface)`가 뜻을 그대로 말한다(Compute 하나 감소, sonnet-2는 "죽은 분기"라 했지만 애니메이션은 살아 있다). `Button/Split.luau` 머리 주석 53행의 "Every size below the host is Offset"은 233행의 Selected 오버레이(`UDim2.fromScale(1, 1)`)와 글자로는 어긋난다 — Offset 크기 부모 아래의 Scale 잎은 `Ripple.luau`의 실측 규칙상 안전하므로 코드가 아니라 주석을 고칠 일이다.

---

## E. 기각

**E1. Gemini 1.4 "`UserInputService.InputCancelled` 미처리로 끌기가 영구 고착".** 그런 이벤트가 없다 — 레포의 Roblox 타입 정의(`scripts/roblox-defs/globalTypes.d.luau` 18311행~의 UserInputService)에 `InputCancelled`가 없고 [실측], 제안대로 연결하면 strict 검사와 런타임이 모두 실패한다. 남는 물음은 C4로 옮겼다.

**E2. Gemini 1.1의 "Heartbeat 연결 누수".** 누수가 아니다 — 0.2초 뒤 스스로 끊긴다 [실측]. 남는 증상은 B2.

**E3. Gemini 1.2 "시 다이얼 연속 탭의 타이머 경쟁".** 코드는 그대로다(`TimePicker/ClockFace.luau` 288~290행, 앞 탭의 `task.delay`를 취소하지 않음). 그러나 두 탭이 100ms 안에 들어와야 하고, 결과도 "어차피 일어날 분 전환이 최대 100ms 빨라진다"뿐이라 사용자에게 틀린 값이 생기지 않는다. 정본도 탭마다 따로 기다리는 것으로 기억하지만 **정본 확인 필요**(킷 주석은 "onTap 1910-1935 … switches to minutes 100 ms later"까지만 적음). Gemini의 프로브는 남아 있지 않아 다시 돌리지 못했다.

**E4. sonnet-2 8번 "시계 다이얼 끌기가 취소로 끝나도 분으로 넘어간다".** 값은 끌기 도중 이미 `SetTime`으로 쓰였고 취소 때 되돌릴 이전 값을 들고 있지 않다. 남는 것은 분 모드 전환뿐이라 무해하다. 취소를 되돌림으로 만들지는 **정본 확인 필요**(낮음).

**E5. Gemini 4.2 "Badge Large의 주석(error container)과 코드(Error) 불일치".** 주석 10~11행은 라벨을 onError로 적고 있고 코드도 `Error` + `OnError`로 짝이 맞는다. "error container"는 "컨테이너가 error 색"으로 읽힌다 — 스펙 제목도 "large 16 high LabelSmall onError"다(`test/spec.navigationbar.luau` 51행). ErrorContainer로 바꾸면 onError 라벨과 짝이 깨진다. Gemini가 든 토큰 이름은 킷 소스 어디에도 근거가 없다 — 색 자체는 **정본 확인 필요**로만 표시.

**E6. Gemini 1.6 "`Overlay.holdDismiss` 카운터가 어긋나면 Escape가 영구 차단".** 어긋나는 경로를 대지 못한 가정이다. 쓰는 곳은 `KeyNav`(Engage)와 색 선택기 SV 영역 둘이고 둘 다 선택 상실·파괴에서 놓는다. 드문 오용 방어에 구조를 쓰지 않는다는 레포 원칙 그대로.

**E7. Gemini 1.7 "Scaffold 본문 높이가 음수".** 화면 높이가 위·아래 바의 합(최대 232px)보다 작아야 한다. `Size = (1, 0, 1, -n)`은 킷 전체가 쓰는 관용구이고 그 높이의 화면은 대상이 아니다.

**E8. sonnet-1 10번 "레이아웃 전에 `Show`를 부르면 PartiallyExpanded 대신 Expanded로 간다".** 읽은 대로다. 다만 모달 시트는 `OnLaidOut`에서 스스로 `Show`하므로 `open` 직후 손으로 `Show`를 부를 이유가 없다. 문서 한 줄 감이고 결함으로 세지 않는다.

**E9. 측정해 보니 버릴 비효율 주장들.** 시트 끌기의 이동당 새 테이블(sonnet-1 8번): [실측] mock 13 µs/이동 — 버림. 시계 다이얼의 이동당 테이블 일곱(sonnet-2 7(나)): 같은 크기 — 버림. 레일의 항목당 Compute 14개(Gemini 2.2): [실측] 항목 5개, 펼침·접힘 프레임당 약 279 µs, 그것도 0.2초(12프레임) 동안만 — 버림(`labelStart`에서 나오는 넷은 p = 1/2에서 한 번만 바뀐다). 베지에 이분 탐색 30회(Gemini 2.3): 스크롤 프레임당 곱셈 수백 번 — 버림. 스크롤마다 `task.delay`(Gemini 2.4): 동시에 살아 있는 예약은 0.1초 창 안의 몇 개 — 버림.

**E10. 구조 제안 가운데 값이 낮은 것.** 모달 바텀 시트와 모달 사이드 시트의 `open()` 공용화(sonnet-1 7번, Gemini 3.2): 실제로 겹치는 것은 dismiss·OnGo·OnClose·반환 핸들 약 30줄이고(Gemini의 "80%"는 과장 — 바텀 쪽에만 settleToDismiss·자체 스크림·OnLaidOut이 있다), 공용 래퍼는 내부 이름을 하나 늘린다. Pos → `q.Tween` Compute 세 벌도 같은 크기다. `Util.negate` → `q.Operator.Not`(Gemini 3.1): 쓰는 곳 열 곳 남짓, 얻는 것은 클로저 하나씩 — 취향. TimePicker 모달의 다이얼·입력 지연 생성(Gemini 3.3): 얻는 것 인스턴스 24개, 드는 것은 "열린 뒤에는 아무것도 만들거나 부수지 않는다"는 지금 구조를 버리고 모드 전환에 생성·파괴 경로를 새로 두는 것. 400줄 넘는 파일 분할(Gemini 4.1)과 `Slider` 함수 분할: 결함도 측정된 이득도 없는 취향.

---

## 빠진 두 파일(`Button/Split.luau` 482줄, `AppBar/Top.luau` 510줄)

둘 다 처음부터 끝까지 읽었다. **Split.luau**: 버그로 보이는 것은 C1 하나(첫 배치의 위치 트윈)다. 그 밖에 광학 보정 식(−2 / −1 / 0), 두 면의 리플 기하, 폭 반올림, 비활성 가드는 머리 주석과 맞는다. 주석 한 줄의 어긋남은 D4에 적었다. **Top.luau**: 버그로 보이는 것 없음 — 베지에 식, 한 줄·두 줄 바의 높이·투명도 계산, `fromBottom` 클램프, Scaffold에 넘기는 `measures`를 읽어서 확인했다(레이아웃 결과는 mock에 없어 읽기만).

## 검증하지 못한 것

- 엔진 동작에 기대는 것 전부: 두 번째 터치의 `InputBegan` 배달(A1의 전제), 첫 AbsoluteSize 알림 시점(C1), 터치 중 `IsMouseButtonPressed`(C2), 터치 취소 때의 신호(C4), 대화 상자 높이(C3), 긴 머리말의 줄바꿈 높이(B4). Studio를 쓸 수 없어 mock과 읽기로만 봤다.
- 정본 대조: B1(Step이 범위를 나누지 않을 때), B3(틀린 입력 뒤 모드 전환), E3(탭마다의 100ms 대기), E4(끌기 취소), E5(Badge Large 색). 킷 소스 주석과 `.claude/research/consumer-kits-plan.md`에는 이 다섯을 가르는 문장이 없다. sonnet-2가 "못 본 것"에 적은 다이얼·입력 두 벌의 키 매핑 차이(Up/Down)도 대조하지 않았다.
- Gemini의 프로브는 파일이 없어 재실행하지 못했다(위 머리말).
- run.sh의 "gallery entry" 단계는 사본에 devui 킷이 없어 돌지 않았다. 레포에 고침을 옮긴 뒤 레포에서 run.sh를 한 번 돌려야 그 단계까지 본다.
- D3·E9의 수치는 mock(Lune) 위에서 잰 것이다. 엔진의 프로퍼티 쓰기·레이아웃 비용은 들어 있지 않다.
- A4의 고침은 "끌기 중 요청은 뗌이 덮어쓴다"는 지금 동작을 그대로 뒀다. 요청이 끌기를 이겨야 하는지(정본은 끌기 우선으로 기억하지만 확인하지 않음)는 보지 않았다.
