# material 오늘 새 코드 리뷰 (finder-mat-new-sonnet)

범위: d88ba193..HEAD 의 quad-roblox-material/src. 프로브는 스크래치 사본 mat1-s/quad-roblox-material/test/probe.*.luau 에서 Lune 0.10.5로 돌렸다
(probe.unit / probe.nf / probe.list / probe.trim). 레포 파일은 건드리지 않았다.

## 발견 (심각도 순)

1. NumberField: 글자를 고치지 않고 포커스만 줬다 놓아도 값이 다시 쓰이고 OnChange가 불린다 [실측 probe.nf.luau A~D].
   commit()이 FocusLost마다 text를 무조건 Unit.parse해서 settle한 뒤 value와 다르면 Set + OnChange를 한다. 그래서
   (a) 포커스 중에 프로그램이 value:Set(500)을 하면 text는 안 바뀌어 있고(follow가 focused일 땐 건너뜀) 아무것도 안 쳤어도 blur 때 옛 글자 "19.99"가 읽혀
   value가 1999로 되돌아가고 OnChange(1999)가 사용자 조작처럼 불린다(A: value 1999, OnChange 1회). 머리 주석 "then at the next commit, if still in force"는 이 동작이 아니다.
   (b) 표시 정밀도로 표현 안 되는 값은 포커스만으로 바뀐다. Scale 0.01인데 값이 3725.5이면 "37.26"을 보여 주고 blur에서 3726으로 바뀐다(B);
   Unit도 Step도 없이 value 1/3이면 "0.333333"이 읽혀 0.333333으로 바뀐다(C);
   **Unit 없이 Step = 0.5만 준 가장 흔한 형태**는 PLAIN(Decimals 0)으로 show해서 2.5를 "2"로 보여 주고 blur 때 2로 쓴다(D: 값 2, OnChange 1회) - 소수 Step이 있는 NumberField가 사실상 못 쓰인다.
   위치 NumberField.luau:96-103(show: step 분기가 PLAIN을 씀), 130-153(commit), 124-128(follow). 제안: 포커스 중 글자가 한 번도 편집되지 않았으면(OnChange 플래그) commit을 건너뛰고
   follow가 막아 둔 값을 blur에서 text에 반영만 한다; step만 있을 땐 step의 소수 자릿수로 show한다.

2. NumberField: Step이 없으면 입력이 표시 정밀도로 반올림되지 않아 값과 글자가 어긋난다 [실측 probe.nf E].
   Scale 0.01, Step 없음에서 "37.255"를 치면 value는 3725.5로 저장되고 글자는 "37.26"으로 정돈된다. 다음 blur에서 3726으로 한 번 더 바뀌고 OnChange가 둘째로 불린다(ch = 3725.5, 3726).
   정수로 값을 두는 Unit의 취지("스냅과 == 이 정확")와 어긋난다. NumberField.luau:143-148. 제안: Step이 없고 Unit이 있으면 settle에서 표시 자릿수에 맞춰 반올림(value = parse(show(settled))).

3. NumberField: 외부 Error가 켜져 있어도 InvalidText가 있으면 그 문구가 ErrorText 자리에 뜬다 [읽기, 코드가 명백].
   NumberField.luau:175 ErrorText = if InvalidText ~= nil then InvalidText else ErrorText. 머리 주석은 InvalidText가 "글자가 숫자가 아닐 때"의 문구라 하는데, Error=true(예: "너무 낮음")일 땐 ErrorText여야 한다.
   두 문구를 둘 다 준 소비자가 외부 오류에서 "Numbers only"를 본다. 제안: invalid와 외부 Error를 구분해 Compute로 고른다(invalid면 InvalidText, 아니면 ErrorText).

4. Unit.parse: 아주 작은 Scale에서 inf를 돌려주고 NumberField가 그걸 Value에 쓴다 [실측 probe.unit, probe.nf H].
   shown은 유한이지만 shown / Scale이 오버플로한다(Scale 1e-7, "1e303" -> inf). parse는 shown만 거르고 결과는 안 거른다. NumberField에 Max가 없으면 value = inf가 Source에 들어가고 글자도 "inf"가 된다.
   Unit.luau:100-109. 제안: 결과가 유한한지도 검사해 nil.

5. Unit.parse: 정수 맞춤 허용오차가 값에 비례(1e-9 x |값|)라 큰 값에서 소수가 조용히 사라진다 [실측].
   Scale 1, Decimals 2에서 "1000000000.25"는 1000000000이 된다(100000000.25는 보존). 허용오차의 목적은 37.25/0.01 같은 부동소수 잡음 제거라 상대 오차 1e-9는 큰 값에서 너무 넓다.
   Unit.luau:105-108. 제안: 오차를 Decimals 기준(0.5 x 10^-Decimals / Scale 같은 값)이나 ulp 몇 개로 좁힌다. 실사용 영향은 작음(1e9 규모) - 확신 낮음.

6. Unit.parse: 접두/접미가 글자 일부와 겹치면 숫자를 깎는다 [실측, 낮음].
   Suffix "2"에서 "52" -> 5, Prefix "-"에서 "-5" -> 5(부호가 접두로 먹힘). NumberField는 접두/접미가 이미 필드 바깥이라 글자가 맨 숫자인데도 parse에 전체 unit을 넘겨 이 경로를 탄다(NumberField.luau:137).
   제안: NumberField는 prefix/suffix를 뺀 bare unit으로 parse하되, 사용자가 붙여 넣은 "$5"를 받으려면 수동 정리(접두는 숫자나 부호가 아닐 때만 벗김)로.

7. Unit.parse(trim): 가운데에 공백이 아주 긴 글자에서 이차 시간 [실측 probe.trim].
   "1" .. 공백 20000개 .. "1" 에 1.5초(10000개 0.39초, 5000개 0.10초). trim의 "^%s*(.-)%s*$"가 각 확장마다 뒤 공백을 다시 훑는다.
   NumberField엔 MaxLength가 없어 붙여넣기로 닿는다. Unit.luau:85-87. 제안: 앞뒤를 각각 find("^%s*")/find("%s*$")로 따로 자른다. 현실성 낮음.

8. Slider: 끄는 중 Disabled가 되면 값은 안 쓰지만 놓는 순간 OnChangeEnd(value)는 그대로 불린다 [읽기, 낮음].
   Behavior.luau:365-371 OnEnded가 cancelled=false면 commitFrom(막힘) 뒤 OnChangeEnd를 무조건 호출 -> "저장" 용도의 콜백이 바뀐 게 없는데 돈다. 제안: 끝 시점 disabled면 OnChangeEnd를 건너뜀(사용자 결정 - 계약 문제).

9. Overlay debug 알림: 첫 Open 때 layer가 아직 LayerCollector 아래가 아니면 검사 기회를 소비하고 영영 말하지 않는다 [읽기, 낮음].
   Overlay.luau:296-306 zIndexChecked=true를 gui 탐색 전에 건다. layer를 ScreenGui에 달기 전에 Open하는 경로에선 gui==nil로 조용히 지나감. 제안: gui를 찾은 뒤에만 true로.
   (그리고 print라 Output의 일반 줄이다 - warn이면 눈에 띈다. 취향이라 약함.)

## 확인했지만 문제없던 것 (probe로)
- ListReorder 상태 기계: 단계별(끄는 중/대기(타이머)/대기(Reordering true, 타이머 없음)/정착/키 대기) 목록 파괴 -> 드래그 연결·Escape 리스너·타이머·Heartbeat 전부 기저로 복귀 (probe.list P1, P6).
  끄는 중 행 삭제·목록 비움·다른 행 삭제·행 추가 -> 세션이 깨끗이 끝나고 새 끌기가 다시 시작됨(P2). OnReorder가 던져도 HOLD 뒤 행이 돌아오고 해제됨(P3). 정착 중 새 끌기(P4), 끄는 중 같은 키의 새 항목 테이블로 교체(P5)도 안전.
  ScrollingFrame 아래 Heartbeat 연결은 모든 종료 경로(삭제·비움·dispose·Destroy·놓기)에서 닫히고 ScrollingEnabled가 복구됨(P6).
  읽기로 본 것: 타이머 자기 취소 없음(after가 timer==th로 해제), OnReorder 안 Items 설정 시 lookAtReordering이 Pending 아니라 무해, Reordering/Items 두 관측의 순서가 어느 쪽이든 re-seat가 정착 중에도 받음.
- Segment/Group/Split: 클립 기하(clipSpan의 Start/Split 경계, reach=15가 토큰과 일치), 면별 그림자, ZIndex 포커스, Split과의 공유(Optical, InnerSelected, Overlay)는 읽기에서 모순 없음. 고정 Width에서 라벨이 칸보다 넓으면 넘치는 것은 문서에 있음.
- TextField 노치: 창 셋이 서로 겹치지 않음(Start/End는 y<Band, Bottom은 y>=Band), 빈 라벨/라벨 Width 0/라벨이 필드보다 넓을 때(UISizeConstraint)/Measured 초기값, 읽기에서 문제없음. 정확한 분수 UIScale에서의 솔기와 TextSize 트윈 중 측정은 엔진 몫 [추정 불가].
- Dialog 측정 고리: 본문 높이는 폭에만 의존하고 래퍼 높이에 의존하지 않아 고리가 없음; 카드 폭 대 `width` 비율이 UIScale을 상쇄 - 읽기로 맞음.
- TimePicker 모달: SetTime(Value)는 입력 둘만 다시 쓰고 OnChange를 안 부름 (Model.luau:90-100 확인).
- Card 비활성 합성, SideSheet Detached(offset·half·hidden 계산), Snackbar Position, Slider Step 약수 검사(float 허용오차)는 diff 읽기에서 문제 못 찾음.

## 못 본 것
- 실제 엔진에서의 ListReorder(UIScale != 1, 터치, Deferred 시그널), 분수 UIScale에서 Container 노치 솔기, Dialog 실제 레이아웃 - 모두 mock으로 불가.
- 스펙 단언의 느슨함은 numberfield 한 곳만 확인: spec.numberfield.luau 3번 절은 "프로그램 Set 중 포커스 + 글자를 친 뒤 blur"만 단언하고, 글자를 안 친 경우와 Step 소수(발견 1)를 단언하지 않아 그 버그가 통과한다.
  spec.pure.unit.luau는 inf 결과·큰 값·접두/접미 겹침·긴 공백을 보지 않는다. 나머지 스펙(buttongroup, list, card, dialog, textfield)은 구조·값을 구체적으로 단언하는 것으로 훑었고 느슨한 절은 찾지 못했다.
- Group/Split 쪽은 프로브 스펙을 돌리지 않았다(읽기만).
