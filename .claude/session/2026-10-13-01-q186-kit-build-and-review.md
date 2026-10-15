# 2026-10-13 — round14 코어 문항 닫기(Q186·Q187·Q154), 킷 빌드(Unit·NumberField·만들 것 넷), 두 킷 전체 code-review

메인 opus 5.5(high). Studio가 돌아온 날이다 — 실기기 확인은 서브에이전트(opus 빌더·sonnet QA)가 하나씩 맡고, 그동안 메인은 결정 문항을
"판단 근거와 주변 맥락을 같이 보여 주며" 대화형으로 처리했다(사용자: *"실 기기 확인 해도 돼. 서브에이전트 시켜도 좋고. 그동안 답을 해줘야할
부분에 판단이 될 근거나 주변 맥락을 같이 보고 처내고 있을까?"*). 실측 원문은 `audit/kit-studio-2026-10-13/REPORT.md`(1~13번), 킷 결정의
소스는 `research/consumer-kits-plan.md` 5절의 2026-10-13 문단들, 코어 원장은 `qa-request/post-implementation-review-round14.md` §7 끝 문단들.
이 파일은 흐름과 사용자 논거만 적는다.

## 1. 플레이스

Studio가 여럿 열린다(table-sim·rbvm-test). 사용자가 내 플레이스를 게시해 이름을 붙였다 — `quad-test`(PlaceId 105962699098904), 이름이
`Place1.rbxl`로 읽히자 명령 창에서 `game.Name = "quad-test"`도 실행해 줬다. 대상 확인은 이름이 아니라 `game.PlaceId`로 한다. `studio-sync`에
`--place`/`--studio`/`--list`가 생겼다(사용자: *"사용법이 달라졌어"*). 오후에 사용자가 Workspace `SignalBehavior`를 Immediate로 바꿨다
(*"나중에 복구해달라 하면 해줄게"*). 요령은 메모리 `reference-studio-mcp-input`.

## 2. 코어 — round14 남은 문항

- **Q186 — 원소 연산의 가드 창을 owner 사슬 전체로(`99c2d7a1`).** 사용자: *"when 이라는 경로를 터줬으니, 그 계약이 성립하려면 그렇게 되는게
  맞는것 같음 … 이미 한 walk 를 더 넣은 정도다 보니 사슬 막는 위로 올라가는것도 맞겠다 싶어. 다만 그 walk 가 자식이 풀릴 때 까지로(엔진)
  지연되는것 뿐인거지?"* — 맞다: 조상의 `WhenIdle` 요청은 자식 연산의 진입점 끝에서 돈다. 형제·무관한 Slot은 통과.
- **Q187 — 재조정 재진입 감지기는 안 넣는다.** 사용자: *"감지기를 잘 넣을 방법이 나타나면 넣을만 한데. 애매해 … 애매모호하니까 넣지 말고 보자."*
- **Q154 불명 셋.** Slot은 양의 정수 키에만(문서 + 스펙 — 사용자: *"검사가 무겁지도 않고"*), `Traceback`의 trace 문자열은 계약 아님(사용자:
  *"단순하게 있는 그대로 전해줄 뿐이고. 사람이 보고 확인해야하는거지"*). 이것으로 round14 코어 문항이 전부 닫혔다.

## 3. 킷 — 결정과 빌드

순서대로: code-review 결정 넷(Step 배수 에러·시간 모달 입력 되돌림·앱 바 정착 그대로·대화 상자 머리말 실측) → **값 단위 `Unit`**(사용자 제안 —
*"실제 값은 10000 에서 0 을 오가는데 100.00 으로 표기되는 식 … 부동 소숫점 값을 피하게 하는게 이롭다고 봐"*; 이름은 *"자기설명적이고"*) →
`ZIndexBehavior = Sibling`(사용자가 친구에게 듣고 바꿔 봄 — 메인이 "Studio 렌더링 폴백"으로 잘못 추정했던 CanvasGroup 현상의 원인은 Global이었다;
문서 + `q.debug` 알림, *"경고 debug 에만 있다면 확인"*) → 만들 것 넷(떨어진 사이드 시트·순서 바꾸는 목록·`ButtonGroup`·위쪽 스낵바 — *"넷 다
의견대로"*) → `NumberField`(별도 부품)와 노치(클립 창) → 비활성 불투명도와 Card 합성. 이름 개명 `BottomOffset` → `Offset`은 사용자: *"킷
게시 전이니까 … 안정 전까지 breaking 나오더라도 괜찮아. 외부 소비자는 없어"* — 킷에 호환 별칭을 두지 않는 근거.

정정 둘: 키 이동량 기본값을 바꾸겠다고 했다가 MDC 소스(한 번 누름 = 한 스텝)를 보고 `Step` 유지로. SplitButton 그림자의 "전체 caster 하나"
후보는 Studio 실험에서 버렸다(투명이면 틈으로 그림자 속이 비침) — 면마다 그림자로.

## 4. 두 킷 전체 code-review (밤)

사용자: *"material ui 쪽이나 devui 쪽은 코드리뷰 더 받아봄직 한것 같은데. 전부 진행 이후 해볼래? 아마 거의 안했던것 같아서."* 구성은 파인더
sonnet 셋 + Gemini 둘(격리 worktree) → opus 추림 → 메인 적용. 원문 `audit/code-review-2026-10-13/`, 판정은 킷 계획 5절 "code-review 2026-10-13" 문단.

- 반영: `405ce844`(메인이 직접 짠 `NumberField`·`Unit`의 결함 일곱 — 스펙이 "글자를 치고 떠나는 경우"만 단언해 통과하고 있었다),
  `f9c1f380`(닫히는 중 이중 발화·앵커 파괴 뒤 남는 메뉴·포커스만으로 값을 쓰던 devui 칸 외), `d89bb54d`(Gemini 보고 판정), `72c11d7c`(실기기로
  확정된 날짜 칸 Enter 이중 고르기).
- 사고 하나: `f9c1f380`에 doc-check ERROR가 섞여 들어갔다(검사와 커밋을 따로 돌림). 이후 `doc-check … | grep -q "ERROR 0건" && git commit`으로 묶는다.
- 실기기(REPORT 13번): 뒤 창의 위젯을 눌러도 창이 앞으로 안 옴(확정), 조상 `Visible = false`에 `MouseLeave` 없음(확정), Global ScreenGui의
  창 둘(확정), 메뉴 폭이 앵커 폭이라 뒤 글자가 있으면 라벨이 줄어듦(관찰). Escape·터치는 MCP로 못 봐 사람 몫.

## 5. 남은 것 (2026-10-13 끝 기준)

사용자 결정 대기는 킷 계획 5절(창 포커스·메뉴 폭·창 닫기 정리·포커스 승계·화면 밖 끌기·가장자리 뒤집기·닫히는 중 내용·`OnChangeEnd`, 아이콘 팩,
3.3.0 시기). `72c11d7c`의 Studio 싱크. 기록만 한 리뷰 항목(`Progress/Loop`의 `Parent = nil` ScreenGui, 날짜 칸당 State 수, 슬라이더 핸들 두 벌,
정본과 다른 텍스트 필드 색 둘, Filled 뜬 레이블 y)은 `audit/code-review-2026-10-13/triage-opus.md`.
