# devplorer 상향 보고서의 quad 쪽 판정 — 2026-10-20

devui의 세 번째 소비자 `devplorer`(사용자 프로젝트, `/code/Projects/devplorer` — Dex 재구현, 레포 밖)가 낸 보고서를 quad 쪽에서 판정한 것이다.
- **원문**: devplorer `.claude/feedback/quad-upstream-2026-10-20.md`. devplorer HEAD `f50d8c9`, vendor quad `57053866`. 프롬프트는 메인이 써서 사용자가 넣었다(`session/2026-10-19-01-decl-3-4-decisions.md` 6절).
- **번호**: 원문 번호를 그대로 쓴다. T는 타입, U는 devui 결핍, D는 상향 후보, S는 문서다.
- **판정의 갈래**: 고친다(메인 자율 — 문서·주석), 문서에 이미 있다, 사용자 결정(새 이름·메커니즘·동작 변경), 조사 필요.
- **확인 범위**: 메인이 원문 전체를 읽었다. 소스로 직접 확인한 것은 묶음 가(누름·hover 판정)의 두 자리뿐이고, 나머지는 원문의 확인에 기댄다.

## 먼저 볼 것 — 전체 그림

**quad 코어(quad-base)의 한계는 0건이다.** 처음에 한계로 보였던 넷은 모두 이미 있었다.
- 인스턴스와 무관한 구독(`:Subscribe()`)
- 디바운스(`q.Debounce`·`Throttle`)
- 파괴 시 정리(`q.OnDestroyed`·Effect cleanup)
- 메아리 없는 되쓰기(`q.Out`)

그런데 devplorer의 이 넷 사용은 0건이었다. 소비자가 그 문서에 닿지 못했다는 뜻이다. table-sim(`feedback/table-sim-2026-10-16.md`)과 같은 결론이고, 이번에는 원인이 더 분명하다. 소비자는 devui `README.md`·`src/init.luau`의 위젯 작성 규약·위젯 머리 주석을 먼저 읽는데, 거기서 quad 스킬(`docs/skills/quad-ui-dev/`)과 how-to로 가는 길이 없다. 그래서 문서 공백 S1~S21 중 13개가 "있는데 못 찾았다"였다.

진짜 결핍은 devui에 몰려 있다. "막힘" 등급 셋(U2·U3·U7)이 전부 devui다.

## 묶음 — devui 결핍과 상향 후보를 장치별로

보고서의 U(결핍)와 D(상향 후보)는 서로 얽혀 있다. 그래서 같은 장치를 고치면 같이 닫히는 것끼리 묶었다. 묶음마다 새 공개 이름·동작이 걸리므로 **전부 사용자 결정**이다(이름·모양은 quad 쪽이 정한다고 원문도 적었다).

**가. 포인터 아래 맨 위 판정 — U2(막힘)·D10·U15 (b)와 10-16 코드 리뷰 5·6·8.**
- **현황(메인이 소스로 확인).** devui에서 "이 점에 무엇이 맨 위에 있나"를 묻는 곳은 창 관리자의 누름 판정 하나다(`quad-roblox-devui/src/Window/Manager.luau` 126행 `PopupHits.covers`). hover(`Interaction.luau` 105~108행)는 `MouseEnter`/`MouseLeave`만 본다. 그래서 다른 창이나 팝업에 가린 행이 hover되고 툴팁이 뜬다. devplorer가 Studio Play에서 실측했다.
- **같은 장치의 반대편.** 10-16 코드 리뷰(`audit/code-review-2026-10-16/README.md` 5·6·8)는 누름 판정이 창 사각형만 대조해 겹친 다른 GUI를 무시한다는 것을 짚었다. 5번은 그때 "관측된 문제가 아니라 원칙상 미룰 수도"였다. 이제 U2가 실제 관측이므로 그 단서가 풀렸다.
- **[2026-10-20 메인 Studio 실측 — 사용자 질문 "TextButton 같은거로 가리면 아래로 MouseEnter 안 내려가지 않나"]** 내려간다. quad-test Play(Client)에서 같은 ScreenGui 안 형제 둘(아래 TextButton, 위 덮개, ZIndex 2 대 1, Sibling)을 놓고 실제 마우스(`user_mouse_input`)로 덮인 자리에 들어갔다. 덮개가 Frame(`Active` 거짓·참), TextButton(`Active` 참·거짓), TextLabel, ScrollingFrame 여섯 가지 모두에서 아래 요소의 `MouseEnter`가 덮개와 같은 횟수로 왔다. 깨끗하게 한 번만 지나간 재측정(TextButton 덮개)도 아래 1·덮개 1이었다. 즉 엔진의 `MouseEnter`/`MouseLeave`는 가림을 모르고, 덮개를 입력 받는 요소로 바꾸는 것으로는 U2가 풀리지 않는다. 같은 자리에서 `PlayerGui:GetGuiObjectsAtPosition`은 **위에 그려진 것부터** 돌려줬다(덮개 → 아래 → DisplayOrder가 낮은 다른 ScreenGui). 좌표는 `AbsolutePosition` 공간(상단바 인셋 58을 뺀 값)이다.
- **같이 정할 것.** 툴팁이 PopupHits에 등록돼 뒤 창이 안 올라오는 문제(8번)와 D10(팝업이 열리면 툴팁 숨김)도 같은 질문이다. 질문은 "툴팁은 가림막인가"다.
- **갈래.**
  - (가) devui 안에 판정 장치 하나를 두고 hover·누름·툴팁·영역 단축키(U15 (b))가 모두 그것을 쓴다. 판정 순서는 팝업(PopupHits) → 창 순서(Manager) → 그 밖 GUI(`GetGuiObjectsAtPosition`)다.
  - (나) Tooltip에만 "가려졌으면 띄우지 않기"를 둔다.
- 메인 의견은 (가)다. 같은 질문을 지금 세 군데가 다르게 답하고 있다.

**나. 입력 상자 — U3(막힘)·T3·U11·U4·D7·D18.**
- **현황.** `InputText`는 안쪽 TextBox의 Ref·포커스를 내주지 않는다. 그래서 포커스·커서·고정 배치가 필요한 자리 열 곳 남짓이 원시 `D.TextBox`가 됐다. 포커스는 마운트 뒤 `task.defer`로 준다(T3, 아홉 곳).
- **함께 나온 요청.** Tab 가로채기(U11·D18), 고를 수 있는 읽기 전용 글(U4), 클립보드 없는 복사 대화상자(D7)도 같은 상자 위에 선다.
- **갈래.**
  - (가) `InputText`에 Ref와 포커스 요청을 준다.
  - (나) 껍데기 없는 키트 모양 상자를 따로 둔다.
  - T3의 quad-roblox 쪽 포커스 훅(가칭 `q.Focus`)은 코어 쪽 새 메커니즘이다. devui 쪽으로 닫히면 필요 없을 수 있다.

**다. 팝업 — U7(막힘)·U5·U6·U8·D4·D5·D6.**
- **현황.** 다음 넷이 비어 있다.
  - Menu를 임의 좌표에서 여는 길이 없다(U7). devplorer는 Overlay 프록시로 키트 내부 호출을 가로챘다.
  - 팝업 몸통과 Escape 듣기가 비공개(`PopupParts` "Not part of the public surface")라 네 번 복사했다(U5).
  - 화면 안 고정·가운데 정렬·이동 API가 없다(U6).
  - 메뉴 구분선(U8)이 없다.
- **갈래.** 원문의 의존 순서(D5가 먼저면 D4·D6·D7이 복사 없이 선다)대로 셋을 차례로 연다.
  - `PopupParts.panel`·`onEscape` 공개
  - `overlay:Open`의 화면 안 유지·정렬 옵션
  - 임의 좌표에서 여는 메뉴 — D4를 그대로 올릴 수 있다
- **새 공개 표면이 늘어나는 묶음이다.** round15 Q189(두 킷의 Overlay·Interaction 공통 층은 세 번째 소비자가 같은 모양을 원할 때 다시 본다)의 조건이 이번에 일부 충족된다. 다만 devplorer가 원한 것은 devui 안의 공개지, material과의 공통 층은 아니다.

**라. 목록 가상화 — D1·D2·D3·D8·D13·D17, S7.**
- **현황.** quad 문서에는 윈도잉 레시피가 있다(`docs/how-to/03-long-lists-and-windowing.md`, 키 기반 `Slot:List`). devui의 `Table`·`Combo`·`Tree`는 가상화가 없다고만 적는다.
- **D1 VirtualRows의 차이.** 고정 슬롯 풀과 `index: State<number?>` 재바인딩으로 스크롤해도 만들기·파괴가 0이다. 레시피가 남긴 한계(창 밖 행 파괴)를 넘는다. 순수 계산과 스펙이 있고 devplorer 의존이 없다. 일반화 비용은 낮다.
- **갈래.** D1을 먼저 올리면 D8·D13·D17이 그 위에 선다. D2(Flatten)·D3(Select)은 순수 모듈이라 함께 올리기 쉽다.

**마. 창 배치와 크기 — U1·U16·D12.**
- Window 내용이 남은 높이를 채우지 못한다. 그래서 네 창이 "제목줄 근사 58"을 빼고 연쇄 계산을 한다(U1).
- `SameLine`에 Wraps 옵션이 없다(U16).
- 겹치지 않는 새 창 자리를 고르는 기능(D12)이 없다.
- 갈래: Window에 채우기 옵션 또는 내용 높이 State 노출(U1)이 가장 아프다.

**바. 위젯 prop·Style — U9·U10·U12·U13·U14·U17·U18·D9·D11·D14·D15·D16.**
- **작은 결핍들.**
  - 파생 Style(U9)
  - 라벨 없는 compact 변형(U10)
  - drag의 틱·정규화 좌표(U12)
  - Button 켜짐 상태(U13)
  - 단추만 있는 탭(U14·D14)
  - 불투명 Style 프리셋, 또는 기본 투명도 0.06을 바꾸는 사용자 결정(U18·D11)
- **위젯 후보.** ColorPanel(D9)은 `InputColor3`의 "No popup picker" 자리를 채운다. 그 밖에 시계열 차트(D15, 일반화 비용 높음)와 키보드 제안 목록(D16)이 있다.
- **U17 조사 결과 [2026-10-20 메인] — 재현 안 됨.**
  - 모의 하네스(Lune)에서 표본 2·3·4·5개, 빈 값에서 하나씩 늘리기, Min/Max를 준 경우 모두 선분 좌표·길이·회전이 정확했다. 예: `{0, 5}`는 중심 (100, 50), 길이 223, −26.6°.
  - quad-test Studio(Edit, StarterGui의 ScreenGui, 최신 킷 싱크)에서도 세 경우 모두 정상으로 그려졌다: 처음부터 2·3·4개, 하나씩 늘리기, 레이아웃 전에 값을 바꾼 뒤 붙이기(속성값과 캡처 둘 다 확인).
  - 곁가지로 본 것 하나: 값이 모두 같으면(범위 0) 선이 칸 아래 경계(y = 높이)에 놓여 `ClipsDescendants`에 반쯤 잘려 거의 안 보인다. 결함인지는 사용자 판단 거리다(가운데로 둘지).
  - X 모양을 재현하려면 devplorer가 본 정확한 조건이 필요하다: 넘긴 `Values`와 `Min`/`Max`, 같은 칸에 PlotLines를 둘 겹쳤는지(평균·최대 두 계열이면 서로 엇갈려 X처럼 보일 수 있다 — 추정).
- **(옛 서술) 조사 필요 — U17.** `PlotLines`에 표본 2~3개를 주면 X 모양으로 그려진다. Studio 실측은 있는데 소스(`Plot.luau` 184~262행)에서 원인을 못 찾았다. 결함 의심이라 사용자 결정 전에 원인부터 찾는다(`Values = {0, 5}`, `{0, 5, 3}` Studio 재현).

## 타입(T) — quad 쪽

- **T1. `Source<T>`와 `State<T>`가 섞인 유니언에서 제네릭 메소드 호출이 실패한다.**
  - 재현은 원문에 있다. 갈래 둘(모든 갈래가 같은 타입이면 통과, 주석 붙인 if-식이면 통과)도 원문 실측이다.
  - **고친다(문서).** SKILL 타입 절에 "Source와 State를 한 변수에 받을 때는 주석 붙인 if-식 또는 값을 돌려주는 함수로"를 한 줄 넣는다.
  - 타입 쪽 수정((a) 유니언 접기)은 `base/typing-limits.md` 대조가 먼저다. 3.4.0과 무관한 솔버 문제로 보인다.
- **T2. `:Compute` 주석 부담.** 문서에 있다(rules-and-invariants·core/03). 3.4.0에서 생성 D의 prop 타입이 바뀌므로, 인라인 `:Compute` 오류 문구는 그때 다시 본다. devui README에 흔한 세 모양의 주석 예시를 넣는 것(b)은 고친다.
- **T3. 마운트 뒤 포커스.** 묶음 나. 문서에 `task.defer` + 부모 확인 관용구를 한 줄 넣는 것은 고친다. 다만 정답 관용구인지(Effect·Ref로 더 낫게 되는지) 메인이 확인한 뒤에 넣는다.
- **T4. `Source<{Instance}>`를 `Source<{any}>` 자리에.** 문서에 있다. 읽기만 하는 prop은 공변 마커 `StateMarker<T>`로 받는 것이 quad-types 정본이다(quadnomicon 04). 쓰기까지 하는 prop이면 불변이 맞다. SKILL에 "읽기만 하는 State prop은 마커로" 예시가 있는지 확인하고, 없으면 넣는다.

## 문서(S) — 대부분 메인이 고칠 수 있는 것

**공통 처방 하나가 S1~S14의 대부분을 닫는다.** devui `README.md` 머리와 `src/init.luau`의 "HOW TO WRITE A DEVUI WIDGET" 머리에 "quad 관용구는 `docs/skills/quad-ui-dev/SKILL.md`와 how-to를 먼저"를 두고, 아래 항목별 링크를 단다.

**링크와 한 줄 문장을 넣을 자리.**
- 두 수명 경로(S1)
- 바깥에서도 쓰는 입력 상자(S3) — `q.Out`. devplorer 사용 0건, 손수 구현이 버그를 하나 낳았다.
- Debounce·Throttle(S4)
- `q.OnDestroyed`·Effect cleanup(S5)
- 선언 밖 `:Connect` 대신 OnChange·이벤트 prop과 Ref(S6)
- 윈도잉 레시피 — Table·Tree·Combo 머리 주석과 README(S7)
- `q.Slot<<Instance>>()`(S8)
- 이벤트 prop의 `() -> ()` 규칙(S9)
- `Kids`는 None 불가(S10, `Layout.luau` 머리)
- `table.unpack` 위치(S11)
- Button `Size`(S13)
- 배치 속성은 Modifier로(S14)
- drag 좌표 공간(S15)
- PlotLines 폭(S16)
- 게임 안 함정 셋(S20 — Escape가 Roblox 메뉴를 엶, Shift+P Freecam, 포커스 없는 상자의 `CursorPosition`이 포커스를 가져감)
- 루프·중간 호출 뒤 좁히기(S21, 선택)

이 줄들은 3.4.0의 표기 변경(`D.Frame` → `Elem "Frame"`)과 섞이지 않는 관용구라 지금 넣어도 다시 고칠 일이 적다.

**사용자 결정으로 따로 둘 것.**
- **S12.** Overlay 층이 아무 ScreenGui에도 안 붙었을 때 debug와 무관하게 첫 Open에서 경고할지(a), 또는 Window가 기본 층을 자기 ScreenGui에 붙일지(b). 지금 그 경고는 `q.debug`에서만 나는 설계라 동작 변경이다.
- **S17.** devui `init.luau`가 `State`·`Source`·`Ref`·`Slot` 타입도 다시 내보낼지. 3.4.0 재수출 정리와 함께 본다.
- **S18.** 소비자에게 `Devui.Input.service()`를 권할지(README 한 줄 — 권장 수준 결정).

## 다음

- 메인 자율: S 묶음 문서 고침, T1·T2 (b)·T4 문서 한 줄, U17 원인 조사. 원인 조사는 Studio quad-test에서 한다.
- 사용자 결정: 묶음 가~바와 S12·S17·S18. 묶음 가는 10-16 코드 리뷰 5·6·8과 한 번에 정하는 것이 좋다.
- devplorer 탐사 메모(루트 `ROADMAP.md` 백로그 2026-10-19)의 "devui에 없어서 만든 부품 찾기"는 이 보고서의 D1~D18이 사실상 해냈다. 남는 것은 위 묶음의 결정이다.
